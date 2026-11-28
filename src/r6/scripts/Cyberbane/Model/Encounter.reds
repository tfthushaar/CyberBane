// Cyberbane - Encounter tracker (spec §7.1.3)
//
// Groups kills into combat episodes and, on resolve, awards the encounter-level
// flags and bonuses (spec §8.1/§8.2). An episode starts on V's first kill, and
// resolves once V has been out of combat for EncounterEndTimeout ticks (~seconds).
// Runtime object; not persisted. Tick timing uses the system's ~1 Hz tick counter.

public class CBEncounter {
  public let active: Bool;
  public let startTick: Int32;
  public let kills: Int32;
  // Bodies only: what the massacre test counts. `kills` counts everybody put down, alive or not,
  // which is right for a flawless fight and wrong for a massacre.
  public let bodies: Int32;
  public let civilianKills: Int32;
  public let bossDown: Bool;
  public let outOfCombatTicks: Int32;
  public let killTicks: array<Int32>;
  // Lowest health V dropped to during this fight, as a stat-pool percentage. -1.0 means
  // nothing has been sampled yet.
  public let playerHpMin: Float;
  // The same, for the part of a fight before V's first kill, when no encounter is open yet. The fight starts when V is
  // in combat, not when somebody first goes down, so this is carried into the encounter when it opens.
  public let preHpMin: Float;
  public let preSampled: Bool;
  // Where the last of them went down, and whose they were: a massacre is remembered there (Model/StreetBook.reds).
  public let lastBodyAt: Vector4;
  public let lastBodyGang: CName;
  public let lastGangBodies: Int32;     // how many of lastBodyGang V has killed in this fight (Spawn/ClearedStreets.reds)
}

// How much health V may lose and still call a fight flawless.
func CBFlawlessFloor() -> Float = 95.0

// Sample V's health. Reads the same stat pool CBCombatFleeCheck already reads for enemies,
// so this adds no engine surface that is not already on the tick path, and it is only ever
// called while an encounter is live.
func CBSamplePlayerHp(game: GameInstance, player: ref<PlayerPuppet>) -> Float {
  let sps = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(sps) || !IsDefined(player) {
    return -1.0;
  }
  // true for a percentage, which is what CBFlawlessFloor is. Read as hit points, V was "flawless"
  // at anything over 95 of them, so a fight that took half V's health still counted.
  return sps.GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, true);
}

// `alreadyDown`: this one was counted in the encounter when they went down alive, and has now been finished.
public func CBEncounterRecordKill(sys: ref<CyberbaneSystem>, info: ref<CBKillInfo>, opt alreadyDown: Bool) -> Void {
  if !IsDefined(sys) || !IsDefined(info) {
    return;
  }
  let enc = sys.EnsureEncounter();
  let recount = !(alreadyDown && enc.active);
  if !enc.active {
    enc.active = true;
    enc.startTick = sys.GetTickCount();
    enc.kills = 0;
    enc.bodies = 0;
    enc.civilianKills = 0;
    enc.bossDown = false;
    // Whatever V took before this first kill counts: a fight V was shot to half health in and
    // healed back up before anybody went down was being called flawless.
    enc.playerHpMin = enc.preSampled ? enc.preHpMin : -1.0;
    enc.preSampled = false;
    ArrayClear(enc.killTicks);
    enc.lastBodyGang = n"";
    enc.lastGangBodies = 0;
  }
  if recount {
    enc.kills += 1;
  }
  // Only a body counts here. This feeds the massacre test, and a street full of unconscious
  // civilians is not a massacre however many of them there are.
  if info.lethal && info.victimClass == EnumInt(ECBVictimClass.Civilian) {
    enc.civilianKills += 1;
  }
  if info.victimClass == EnumInt(ECBVictimClass.Boss) {
    enc.bossDown = true;
  }
  if info.lethal {
    enc.lastBodyAt = info.position;
    if NotEquals(info.faction, n"") {
      enc.lastGangBodies = Equals(info.faction, enc.lastBodyGang) ? enc.lastGangBodies + 1 : 1;
      enc.lastBodyGang = info.faction;
    }
  }
  // The massacre window too: a room of people knocked out in thirty seconds is not a massacre.
  if info.lethal {
    enc.bodies += 1;
    ArrayPush(enc.killTicks, sys.GetTickCount());
  }
  // The massacre test only looks at a 30-tick window, so older entries can never change the answer.
  while ArraySize(enc.killTicks) > CBConfig.CapEncounterKillTicks() {
    ArrayErase(enc.killTicks, 0);
  }
  enc.outOfCombatTicks = 0;
}

public func CBEncounterTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let enc = sys.GetEncounter();
  let player = GetPlayer(game);
  if !IsDefined(enc) || !enc.active {
    // No encounter yet: V may still be in the fight that opens one. Its health is watched from
    // the moment V is in combat, and forgotten again once V is out of it with nobody down.
    if IsDefined(player) && player.IsInCombat() {
      let pre = sys.EnsureEncounter();
      let hpPre = CBSamplePlayerHp(game, player);
      if hpPre >= 0.0 && (!pre.preSampled || hpPre < pre.preHpMin) {
        pre.preHpMin = hpPre;
        pre.preSampled = true;
      }
    } else {
      if IsDefined(enc) {
        enc.preSampled = false;
      }
    }
    return;
  }
  // Flawless needs to know whether V was ever hurt.
  let hp = CBSamplePlayerHp(game, player);
  if hp >= 0.0 {
    if enc.playerHpMin < 0.0 || hp < enc.playerHpMin {
      enc.playerHpMin = hp;
    }
  }
  if IsDefined(player) && player.IsInCombat() {
    enc.outOfCombatTicks = 0;
  } else {
    enc.outOfCombatTicks += 1;
    if enc.outOfCombatTicks >= RoundF(CBConfig.EncounterEndTimeout()) {
      CBEncounterResolve(sys, game, enc);
    }
  }
}

func CBEncounterResolve(sys: ref<CyberbaneSystem>, game: GameInstance, enc: ref<CBEncounter>) -> Void {
  enc.active = false;
  let stats = sys.GetStats();
  if IsDefined(stats) {
    stats.encounters += 1;
  }

  let renownMult = 1.0;
  let dreadMult = 1.0;
  let toasts = false;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    renownMult = rt.GetSettings().renownGainMult;
    dreadMult = rt.GetSettings().dreadGainMult;
    toasts = CBMessagesOn();
  }

  // Came through a real fight without being hurt (spec §8.1). Needs at least a couple of
  // bodies so that one stray kill does not count as a flawless encounter.
  if IsDefined(stats) && enc.kills >= 2 && enc.playerHpMin >= CBFlawlessFloor() {
    stats.flawless += 1;
  }

  let massacre = enc.bodies >= CBConfig.MassacreTotalKills()
    || CBMaxKillsInWindow(enc.killTicks, RoundF(CBConfig.MassacreWindowSeconds())) >= CBConfig.MassacreWindowKills();

  if massacre {
    if IsDefined(stats) {
      stats.massacres += 1;
    }
    sys.AddRenownPoints(10.0 * renownMult);
    sys.AddKillDreadPoints(10.0 * dreadMult);
    CBTerrorDeed(sys, CBConfig.TerrorMassacre());
    if toasts {
      CBHearsayFromStreet(game, CBLineOf([CBT(n"Cyberbane-Encounter-HeardWhatYouLeftBehindPeople"), CBT(n"Cyberbane-Encounter-LeftBehind2"),
                                          CBT(n"Cyberbane-Encounter-LeftBehind3"), CBT(n"Cyberbane-Encounter-LeftBehind4")]), n"Massacre");
    }
    CBCreateRumor(sys, game, n"Massacre", 8.0, CBEventDistrict(sys, game), n"", true);
    if enc.bodies > 0 {
      CBRememberPlace(sys, game, n"Massacre", enc.lastBodyGang, CBEventDistrict(sys, game), enc.lastBodyAt);
      CBWarLoseMen(game, enc.lastBodyGang, CBConfig.WarMenMassacre());   // their ranks empty for a while
    }
    CBFileLog(sys, n"Massacre", CBGameSeconds(game), CBEventDistrict(sys, game), n"", Cast<Float>(enc.bodies));
    CBLog.Info(n"Model", s"Massacre resolved (\(enc.bodies) bodies).");
  }

  if enc.bossDown {
    sys.AddRenownPoints(10.0 * renownMult);
  }
  // A gang wiped off a spot stays off it for a while (Spawn/ClearedStreets.reds, off by default).
  CBNoteWipedOut(sys, game, enc.lastBodyGang, enc.lastBodyAt, enc.lastGangBodies);

  CBEvaluateTitles(sys, game);
}

// Largest number of kills within any `window`-tick span (spec §7.1.3 massacre rule).
func CBMaxKillsInWindow(ticks: array<Int32>, window: Int32) -> Int32 {
  let best = 0;
  let n = ArraySize(ticks);
  let i = 0;
  while i < n {
    let count = 0;
    let j = 0;
    while j < n {
      if ticks[j] >= ticks[i] && ticks[j] < ticks[i] + window {
        count += 1;
      }
      j += 1;
    }
    if count > best {
      best = count;
    }
    i += 1;
  }
  return best;
}

// Something people will be frightened by for a while: a massacre, a boss, MaxTac, a gang's best, a Rival put in the
// ground.
public func CBTerrorDeed(sys: ref<CyberbaneSystem>, points: Float) -> Void {
  if !IsDefined(sys) || points <= 0.0 {
    return;
  }
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().dreadGainMult;
  }
  sys.AddDeedDreadPoints(points * mult);
}
