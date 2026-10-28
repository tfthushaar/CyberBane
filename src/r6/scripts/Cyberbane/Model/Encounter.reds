// Cyberbane - Encounter tracker (spec §7.1.3)
//
// Groups kills into combat episodes and, on resolve, awards the encounter-level
// flags and bonuses (spec §8.1/§8.2). An episode starts on V's first kill, and
// resolves once V has been out of combat for EncounterEndTimeout ticks (~seconds).
// Runtime object; not persisted. Tick timing uses the system's ~1 Hz tick counter.
//
// Flawless needs V's HP-loss fraction (player-damage tracking, S-01) and is held
// until that lands; Massacre and BossDown are active now.

public class CBEncounter {
  public let active: Bool;
  public let startTick: Int32;
  public let kills: Int32;
  public let civilianKills: Int32;
  public let bossDown: Bool;
  public let outOfCombatTicks: Int32;
  public let killTicks: array<Int32>;
  // Lowest health V dropped to during this fight, as a stat-pool percentage. -1.0 means
  // nothing has been sampled yet.
  public let playerHpMin: Float;
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
  return sps.GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, false);
}

public func CBEncounterRecordKill(sys: ref<CyberbaneSystem>, info: ref<CBKillInfo>) -> Void {
  if !IsDefined(sys) || !IsDefined(info) {
    return;
  }
  let enc = sys.EnsureEncounter();
  if !enc.active {
    enc.active = true;
    enc.startTick = sys.GetTickCount();
    enc.kills = 0;
    enc.civilianKills = 0;
    enc.bossDown = false;
    enc.playerHpMin = -1.0;
    ArrayClear(enc.killTicks);
  }
  enc.kills += 1;
  if info.victimClass == EnumInt(ECBVictimClass.Civilian) {
    enc.civilianKills += 1;
  }
  if info.victimClass == EnumInt(ECBVictimClass.Boss) {
    enc.bossDown = true;
  }
  ArrayPush(enc.killTicks, sys.GetTickCount());
  // The massacre test only looks at a 30-tick window, so older entries can never change
  // the answer. Keeping the list bounded matters because a fight V never breaks off would
  // otherwise grow it for the whole session, and the window scan is quadratic.
  while ArraySize(enc.killTicks) > CBConfig.CapEncounterKillTicks() {
    ArrayErase(enc.killTicks, 0);
  }
  enc.outOfCombatTicks = 0;
}

public func CBEncounterTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let enc = sys.GetEncounter();
  if !IsDefined(enc) || !enc.active {
    return;
  }
  let player = GetPlayer(game);
  // Flawless needs to know whether V was ever hurt. Sampling the health pool on the tick
  // gives that without hooking the player's damage path, which is the hottest path in the
  // game and the last place this mod should be adding a wrapper.
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
    toasts = rt.GetSettings().toasts;
  }

  // Came through a real fight without being hurt (spec §8.1). Needs at least a couple of
  // bodies so that one stray kill does not count as a flawless encounter.
  if IsDefined(stats) && enc.kills >= 2 && enc.playerHpMin >= CBFlawlessFloor() {
    stats.flawless += 1;
  }

  let massacre = enc.kills >= CBConfig.MassacreTotalKills()
    || CBMaxKillsInWindow(enc.killTicks, RoundF(CBConfig.MassacreWindowSeconds())) >= CBConfig.MassacreWindowKills();

  if massacre {
    if IsDefined(stats) {
      stats.massacres += 1;
    }
    sys.AddRenownPoints(10.0 * renownMult);
    sys.AddKillDreadPoints(10.0 * dreadMult);
    if toasts {
      CBShowMessage(game, "Cyberbane: Massacre. The streets will talk about this.", 4.0);
    }
    CBCreateRumor(sys, game, n"Massacre", 8.0, CBEventDistrict(sys, game), n"", true);
    CBLog.Info(n"Model", s"Massacre resolved (\(enc.kills) kills).");
  }

  if enc.bossDown {
    sys.AddRenownPoints(10.0 * renownMult);
  }

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
