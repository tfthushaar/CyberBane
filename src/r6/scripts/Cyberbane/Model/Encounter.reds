// Cyberbane — Encounter tracker (spec §7.1.3)
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
  enc.outOfCombatTicks = 0;
}

public func CBEncounterTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let enc = sys.GetEncounter();
  if !IsDefined(enc) || !enc.active {
    return;
  }
  let player = GetPlayer(game);
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
    CBCreateRumor(sys, game, n"Massacre", 8.0, CBCurrentDistrict(game), n"", true);
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
