// Cyberbane - Combat morale (spec §9.4)
//
// When V kills an NPC, nearby surviving squad-mates take a morale hit. If a survivor's
// morale falls below the break threshold it panics: a Terror stim broadcast from that
// NPC drives the game's own flee behaviour (and the game cowers it in place when it has
// nowhere to run). At most a configurable fraction of any knot of enemies breaks, so
// someone always stands and fights. A broken enemy that gets away can resurface later
// as a Survivor Rival (spec §10.2).
//
// This only reads positions and broadcasts a stock game stimulus, so it is fully
// reversible and adds no state the game does not already clean up on despawn.

// Per-puppet morale, per spawn. 0.0 is the "not yet initialised" sentinel.
@addField(ScriptedPuppet)
public let cbMorale: Float;

@addField(ScriptedPuppet)
public let cbMoraleBroken: Bool;

public func CBMoraleOnKill(sys: ref<CyberbaneSystem>, game: GameInstance, info: ref<CBKillInfo>) -> Void {
  if !IsDefined(sys) || !IsDefined(info) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  let intensity = 1.0;
  let maxBreak = CBConfig.MoraleMaxBreakFraction();
  if IsDefined(rt) && rt.HasSettings() {
    let s = rt.GetSettings();
    if !s.morale {
      return;
    }
    intensity = s.moraleIntensity;
    maxBreak = s.maxBreakFraction;
  }
  if intensity <= 0.0 {
    return;
  }

  let reg = sys.GetRegistry();
  if !IsDefined(reg) {
    return;
  }
  if sys.IsInSafeZone() {
    return;   // not in a safe area (spec §16)
  }

  // Losing the group's officer or boss is a far harder blow than a rank-and-file death.
  let bossOrOfficer = info.victimClass == EnumInt(ECBVictimClass.Boss)
    || info.victimClass == EnumInt(ECBVictimClass.Officer);
  let shock = bossOrOfficer ? 0.35 : 0.10;

  // Vendetta crews are already rattled; their own dropping hits harder.
  let vendetta = NotEquals(info.faction, n"")
    && Equals(sys.GetScore().GetPosture(info.faction), ECBPosture.Vendetta);

  let deadPos = info.position;
  let npcs = reg.GetAll();

  // Gather nearby combatants and count how many already broke, so the group break
  // cap is honoured across repeated kills in the same fight.
  let nearby: array<wref<ScriptedPuppet>>;
  let brokenCount = 0;
  let i = 0;
  while i < ArraySize(npcs) {
    let npc = npcs[i];
    i += 1;
    // Cheap distance gate before the heavier eligibility check (Safety Gate workspot query);
    // CBNpcSafe keeps us off streaming-out / not-yet-ready NPCs (crash safety).
    if CBNpcSafe(sys, npc) && Vector4.Distance(deadPos, npc.GetWorldPosition()) <= CBConfig.MoraleShockRadius() {
      if CBMoraleEligible(npc) {
        ArrayPush(nearby, npc);
        if npc.cbMoraleBroken {
          brokenCount += 1;
        }
      }
    }
  }

  // +1 for the member that just died: a lone survivor of a pair can still break.
  let total = ArraySize(nearby) + 1;
  let breakCap = FloorF(maxBreak * Cast<Float>(total));

  let j = 0;
  while j < ArraySize(nearby) {
    let npc = nearby[j];
    j += 1;
    if npc.cbMorale <= 0.0 {
      npc.cbMorale = 1.0;   // initialise once per spawn
    }
    let delta = shock * intensity;
    if vendetta {
      delta += 0.10 * intensity;
    }
    npc.cbMorale -= delta;

    if !npc.cbMoraleBroken
       && npc.cbMorale < CBConfig.MoraleBreakThreshold()
       && brokenCount < breakCap {
      CBMoraleBreak(sys, game, npc, info.faction, info.district);
      brokenCount += 1;
    }
  }
}

// Who can break: a live, non-quest NPC that is not a boss and not a civilian or MaxTac
// (spec §9.4 immune list). Already-broken NPCs stay in the scan so the cap counts them.
func CBMoraleEligible(npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) {
    return false;
  }
  if !CBSafetyGate.CanAffect(npc) {
    return false;   // excludes the player, the dead, and quest NPCs
  }
  if npc.IsBoss() || npc.IsCrowd() {
    return false;
  }
  if Equals(CBClassifyFaction(npc), n"MaxTac") {
    return false;
  }
  return true;
}

func CBMoraleBreak(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>, faction: CName, district: CName) -> Void {
  npc.cbMoraleBroken = true;
  let b = npc.GetStimBroadcasterComponent();
  if IsDefined(b) {
    b.TriggerSingleBroadcast(npc, gamedataStimType.Terror);
  }
  CBLog.Info(n"Reactions", "An enemy broke and ran.");
  if NotEquals(faction, n"") && RandF() < CBConfig.RivalChanceSurvivor() {
    CBCreateRival(sys, game, faction, npc.GetRecordID(), n"", ECBRivalSource.Survivor, district, CBGameSeconds(game));
  }
}
