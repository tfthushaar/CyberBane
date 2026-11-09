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
  // When a mod like Much Better AI owns morale, a squad watching one of its own go down is
  // its call to make, not ours. Stand down rather than break the same crew twice over
  // (Core/Compat.reds).
  if CBExternalMoraleOwner() {
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
    maxBreak = s.maxFleeFraction;
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

  let brutal = CBIsBrutalKill(info.mFinisher, info.mBlade, info.mFists);

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
  // At least one, unless the setting says none: rounding down meant a pair could never break.
  let breakCap = maxBreak > 0.0 ? Max(1, RoundF(maxBreak * Cast<Float>(total))) : 0;

  let j = 0;
  while j < ArraySize(nearby) {
    let npc = nearby[j];
    j += 1;
    if npc.cbMorale <= 0.0 {
      npc.cbMorale = 1.0;   // initialise once per spawn
    }
    npc.cbMorale = MaxF(0.001, npc.cbMorale - shock);

    if !npc.cbMoraleBroken && brokenCount < breakCap {
      let allies = ArraySize(nearby) - 1 - brokenCount;
      let chance = CBBreakChance(sys, npc, info.faction, 1.0 - npc.cbMorale, allies,
                                 bossOrOfficer, brutal, intensity);
      if RandF() < chance && CBMoraleBreak(sys, game, npc, info.faction, chance) {
        brokenCount += 1;
      }
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
  // Nor anybody lying on the ground: an unconscious body cannot break, or be counted as one of a
  // group that might.
  if !CBStillStanding(npc) {
    return false;
  }
  if npc.IsBoss() || npc.IsCrowd() {
    return false;
  }
  // An apex squad holds its ground the way MaxTac does; that is what it is for. A Rival who is
  // Hard to Scare does too.
  if CBHoldsGround(npc) {
    return false;
  }
  if Equals(CBClassifyFaction(npc), n"MaxTac") {
    return false;
  }
  return true;
}

// How likely this person is to run, right now. Nothing here is a coin flip on its own: a veteran with
// friends around them can watch a lot go wrong, and a hurt ganger on their own will not need much.
public func CBBreakChance(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>, faction: CName, shaken: Float,
                          allies: Int32, leaderDown: Bool, brutal: Bool, intensity: Float) -> Float {
  if !IsDefined(sys) || !IsDefined(npc) || shaken < CBConfig.MoraleBreakMinShock() {
    return 0.0;
  }
  let nerve = CBNerve(npc);
  if nerve >= 1.0 {
    return 0.0;
  }
  let score = sys.GetScore();
  let fear = 0.0;
  let sworn = false;
  if IsDefined(score) && NotEquals(faction, n"") {
    fear = ClampF(score.GetFactionFear(faction) / 100.0, 0.0, 1.0);
    sworn = Equals(score.GetPosture(faction), ECBPosture.Vendetta);
  }
  let chance = ClampF(shaken, 0.0, 1.0) * CBConfig.MoraleBreakShockWeight() * (0.5 + 0.5 * fear);

  let sps = GameInstance.GetStatPoolsSystem(npc.GetGame());
  if IsDefined(sps) {
    let hp = sps.GetStatPoolValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health, true);
    if hp < CBConfig.MoraleHurtBelow() {
      chance += (1.0 - hp / CBConfig.MoraleHurtBelow()) * CBConfig.MoraleHurtWeight();
    }
  }
  if allies <= 0 {
    chance += CBConfig.MoraleAloneBonus();
  } else {
    if allies >= CBConfig.MoraleBackedUpAllies() {
      chance *= CBConfig.MoraleBackedUpMult();
    }
  }
  if leaderDown {
    chance += CBConfig.MoraleLeaderDownBonus();
  }
  if brutal {
    chance += CBConfig.MoraleBrutalBonus();
  }
  // Rank and file are 0.5, so they take this as it stands; an elite takes half of it.
  chance *= (1.0 - nerve) * 2.0;
  if sworn {
    chance *= CBConfig.MoraleSwornMult();
  }
  if CBTurfLostGround(sys, faction) {
    chance *= CBConfig.MoraleLostGroundMult();
  }
  // The ceiling goes last, over the slider and the title too: applied before them, Morale intensity
  // at 2.0 turned a 40% ceiling into 80%.
  return ClampF(chance * intensity * sys.WornPerk().breakMult, 0.0, CBConfig.MoraleBreakMaxChance());
}

// May one more of this group run? The kill path counts this as it goes; somebody hit down to a quarter
// of their health arrives here on their own, and without asking, a grenade through a whole crew could
// send past the "Most of a group" setting.
public func CBRoomToBreak(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> Bool {
  let reg = IsDefined(sys) ? sys.GetRegistry() : null;
  if !IsDefined(reg) || !IsDefined(npc) {
    return false;
  }
  let share = CBConfig.MoraleMaxBreakFraction();
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    share = rt.GetSettings().maxFleeFraction;
  }
  if share <= 0.0 {
    return false;
  }
  let here = npc.GetWorldPosition();
  let id = npc.GetEntityID();
  let total = 1;
  let broken = 0;
  let all = reg.GetAll();
  let i = 0;
  while i < ArraySize(all) {
    let other = all[i];
    i += 1;
    if CBNpcSafe(sys, other) && NotEquals(other.GetEntityID(), id)
       && Vector4.Distance(here, other.GetWorldPosition()) <= CBConfig.MoraleShockRadius()
       && CBMoraleEligible(other) {
      total += 1;
      if other.cbMoraleBroken {
        broken += 1;
      }
    }
  }
  return broken < Max(1, RoundF(share * Cast<Float>(total)));
}

// How many others who could break are standing near this one.
public func CBAlliesNear(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> Int32 {
  let count = 0;
  let reg = IsDefined(sys) ? sys.GetRegistry() : null;
  if !IsDefined(reg) || !IsDefined(npc) {
    return 0;
  }
  let here = npc.GetWorldPosition();
  let id = npc.GetEntityID();
  let all = reg.GetAll();
  let i = 0;
  while i < ArraySize(all) && count < CBConfig.MoraleBackedUpAllies() {
    let other = all[i];
    i += 1;
    if CBNpcSafe(sys, other) && NotEquals(other.GetEntityID(), id) && !other.cbMoraleBroken
       && Vector4.Distance(here, other.GetWorldPosition()) <= CBConfig.MoraleShockRadius()
       && CBMoraleEligible(other) {
      count += 1;
    }
  }
  return count;
}

// Somewhere to run to: away from V, a real walk from here. None means they have nowhere to go.
func CBFleeSpot(game: GameInstance, npc: wref<ScriptedPuppet>, player: ref<GameObject>, out spot: Vector4) -> Bool {
  let npos = npc.GetWorldPosition();
  let ppos = player.GetWorldPosition();
  let toV = Vector4.Normalize2D(new Vector4(ppos.X - npos.X, ppos.Y - npos.Y, 0.0, 0.0));
  let pts: array<Vector4>;
  // CBPursuitPoints searches behind the direction it is given, which is away from V here.
  if !CBPursuitPoints(game, npos, toV, CBConfig.FleeSpotCandidates(), CBConfig.FleeRunMin(),
                      CBConfig.FleeRunMax(), pts) {
    return false;
  }
  let here = Vector4.Distance(npos, ppos);
  let i = 0;
  while i < ArraySize(pts) {
    let p = pts[i];
    i += 1;
    if Vector4.Distance(p, ppos) >= here + CBConfig.FleeMinGain()
       && AbsF(p.Z - npos.Z) <= CBConfig.GroundMaxDrop()
       && CBPointReachable(game, npos, p) {
      spot = p;
      return true;
    }
  }
  return false;
}

// Run. A stim cannot do this: the game drops one whose source is its own target, and one from V
// tells a ganger to panic at V, which is not leaving. A move order can, because with `ignoreInCombat`
// left false the game keeps it running during a fight (tweakAIConditionChecks, IsCommandActive).
// They stay hostile on purpose: made neutral, shooting one in the back would be an assault to the
// police. True when they have somewhere to go and have been told to go there.
public func CBOrderFlee(game: GameInstance, npc: wref<ScriptedPuppet>) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(npc) || !IsDefined(player) || !npc.IsAttached() {
    return false;
  }
  // Somebody in a seat belongs to the car, and the car lets them out when it stops.
  if VehicleComponent.IsMountedToVehicle(game, npc.GetEntityID()) {
    return false;
  }
  let ai = npc.GetAIControllerComponent();
  let spot: Vector4;
  if !IsDefined(ai) || !CBFleeSpot(game, npc, player, spot) {
    return false;
  }
  let cmd = new AIMoveToCommand();
  let dest: AIPositionSpec;
  let wp: WorldPosition;
  WorldPosition.SetVector4(wp, spot);
  AIPositionSpec.SetWorldPosition(dest, wp);
  cmd.movementTarget = dest;
  cmd.movementType = moveMovementType.Sprint;
  cmd.ignoreInCombat = false;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  cmd.desiredDistanceFromTarget = 1.0;
  CBIssueMove(npc, ai, cmd);
  return true;
}

// True when they really ran. Nowhere to go is a reason to keep fighting.
func CBMoraleBreak(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>, faction: CName, chance: Float) -> Bool {
  if !CBOrderFlee(game, npc) {
    CBLog.Verbose(n"Reactions", "An enemy would have broken, but had nowhere to run.");
    return false;
  }
  npc.cbMoraleBroken = true;
  let b = npc.GetStimBroadcasterComponent();
  if IsDefined(b) {
    // With a radius, for the same reason the crowd stims needed one: the argument is optional
    // and leaving it out broadcasts to nobody. This reaches the people around them.
    b.TriggerSingleBroadcast(npc, gamedataStimType.Terror, CBConfig.FearStimRadius());
  }
  CBLog.Info(n"Reactions", s"An enemy broke and ran (\(RoundF(chance * 100.0))% chance).");
  // Made a Rival here, on the spot, they were a survivor even if V shot them in the back a second
  // later. Same road as anybody else who runs, which also keeps them from counting twice.
  if NotEquals(faction, n"") && !npc.cbLowHealthFled {
    npc.cbLowHealthFled = true;
    CBAddEscapee(sys, game, npc, faction);
  }
  sys.MarkEscapeeFleeing(npc.GetEntityID());
  return true;
}

// Never breaks, never runs: an apex squad member, or a Rival with Hard to Scare.
public func CBHoldsGround(npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let id = npc.GetEntityID();
  if des.IsTagged(id, n"CB_Apex") {
    return true;
  }
  if des.IsTagged(id, n"CB_Rival") {
    let sys = CyberbaneSystem.Get(npc.GetGame());
    if IsDefined(sys) {
      let r = CBFindRivalByBody(sys, id);
      return IsDefined(r) && CBRivalHasTrait(r, n"HardToScare");
    }
  }
  return false;
}
