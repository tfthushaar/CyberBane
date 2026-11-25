// Cyberbane - Combat morale (spec §9.4)
//
// When V kills an NPC, nearby surviving squad-mates take a morale hit. If a survivor's morale falls below the break
// threshold it panics: a Terror stim broadcast from that NPC drives the game's flee behaviour (and the game cowers it
// in place when it has nowhere to run).

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
  if !IsDefined(reg) || Equals(info.faction, n"") {
    return;   // nobody's side to shake
  }
  if sys.IsInSafeZone() {
    return;   // not in a safe area (spec §16)
  }

  // Losing the group's officer or boss is a far harder blow than a rank-and-file death.
  let bossOrOfficer = info.victimClass == EnumInt(ECBVictimClass.Boss)
    || info.victimClass == EnumInt(ECBVictimClass.Officer)
    || info.sergeant;   // a crew's sergeant ([U2])
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
    // Cheap distance gate before the heavier eligibility check (Safety Gate workspot query); CBNpcSafe keeps us off
    // streaming-out / not-yet-ready NPCs (crash safety). Their own side only.
    if CBNpcSafe(sys, npc) && Vector4.Distance(deadPos, npc.GetWorldPosition()) <= CBConfig.MoraleShockRadius() {
      if Equals(CBClassifyFaction(npc), info.faction) && CBMoraleEligible(npc) {
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
  // A gang V has broken does not hold together for a vendetta. Sworn people stand firmer, until there are hardly any of
  // them left: then the oath is what they break first.
  let broken = CBGangBroken(sys, faction);
  if sworn && !broken {
    chance *= CBConfig.MoraleSwornMult();
  }
  if broken {
    chance *= CBConfig.MoraleBrokenGangMult();
  } else {
    if CBTurfLostGround(sys, faction) {
      chance *= CBConfig.MoraleLostGroundMult();
    }
  }
  // On streets V's crew holds (Model/CrewTurf.reds), any gang's people are on borrowed ground, and know whose.
  if NotEquals(faction, n"") && CBCrewHoldsHere(sys, npc.GetGame()) {
    chance += CBConfig.CrewHeldBreakBonus();
  }
  // The ceiling goes last, over the slider and the title too: applied before them, Morale intensity
  // at 2.0 turned a 40% ceiling into 80%.
  return ClampF(chance * intensity * sys.WornPerk().breakMult * CBCodeNerve(faction), 0.0, CBConfig.MoraleBreakMaxChance());
}

// May one more of this group run?
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

// Run. A stim cannot do this: the game drops one whose source is its own target, and one from V tells a ganger to panic
// at V, which is not leaving.
public func CBOrderFlee(game: GameInstance, npc: wref<ScriptedPuppet>, opt walk: Bool) -> Bool {
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
  cmd.movementType = walk ? moveMovementType.Walk : moveMovementType.Sprint;
  cmd.ignoreInCombat = false;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  cmd.desiredDistanceFromTarget = 1.0;
  CBIssueMove(npc, ai, cmd);
  return true;
}

// Nobody breaks at a job: "the surgeon in Big in Japan came out of his box", "Haze doesn't work".
func CBMoraleHeldAtJob(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(sys) || !IsDefined(npc) || !npc.IsAttached() {
    return true;
  }
  if CBPlayerInScene(game) || sys.IsInQuestArea() || sys.GetStoryHold() != CBStoryNone() {
    return true;
  }
  return sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.QuestSpawnClearance());
}

// True when they really ran. Nowhere to go is a reason to keep fighting.
func CBMoraleBreak(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>, faction: CName, chance: Float) -> Bool {
  if CBMoraleHeldAtJob(sys, game, npc) {
    CBLog.Verbose(n"Reactions", "An enemy would have broken, but it is a job's ground: they hold.");
    return false;
  }
  // Some give up instead (Spawn/LivingStreet.reds, experimental).
  let life = CBStreetLifeFor(game);
  if IsDefined(life) && life.TrySurrender(sys, game, npc) {
    npc.cbMoraleBroken = true;
    return true;
  }
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
  // A gang's best at a sit-down is built like its apex squad, and stands like it (Spawn/LivingStreet.reds).
  if des.IsTagged(id, n"CB_Apex") || CBIsMeetApex(des, id) {
    return true;
  }
  // Nobody of Arasaka runs with Adam Smasher in the fight (Compat/SmasherEncounters.reds).
  if npc.IsAttached() && CBSmasherEventOn(npc.GetGame()) && Equals(CBClassifyFaction(npc), n"Arasaka") {
    return true;
  }
  if des.IsTagged(id, n"CB_Rival") {
    let sys = CyberbaneSystem.Get(npc.GetGame());
    if IsDefined(sys) {
      let r = CBFindRivalByBody(sys, id);
      // A cyberpsycho does not run either.
      return IsDefined(r) && (CBRivalHasTrait(r, n"HardToScare") || CBRivalHasTrait(r, n"Broken"));
    }
  }
  return false;
}

// ---- Holding back on the street ---------------------------------------------------------------
//
// Fear and hatred are two different things, and a gang V has been killing has plenty of both.

public func CBHoldBackChance(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>, faction: CName) -> Float {
  if !IsDefined(sys) || !IsDefined(npc) || Equals(faction, n"") || npc.IsBoss() || CBHoldsGround(npc) {
    return 0.0;
  }
  let backers = CBSameGangNear(sys, npc, faction, CBConfig.HoldBackBackerRadius(), CBConfig.HoldBackMaxBackers());
  return CBHoldBackOdds(sys, faction, CBNerve(npc), backers);
}

// The sum itself, for one nerve and so many friends: the roll above, and the Hub's estimate for a
// ganger of theirs standing with one friend (CBHoldBackTypical).
public func CBHoldBackOdds(sys: ref<CyberbaneSystem>, faction: CName, nerve: Float, backers: Int32) -> Float {
  let score = IsDefined(sys) ? sys.GetScore() : null;
  if !IsDefined(score) || nerve >= 1.0 {
    return 0.0;
  }
  let fear = ClampF(score.GetFactionFear(faction) / 100.0, 0.0, 1.0);
  if CBGangBroken(sys, faction) {
    fear += CBConfig.BrokenGangFear();
  } else {
    if CBTurfLostGround(sys, faction) {
      fear += CBConfig.LostGroundFear();
    }
  }
  // Where their people died, they are jumpier (Model/StreetBook.reds).
  let atGame = IsDefined(sys) ? sys.GetGameInstance() : GetGameInstance();
  let vNow = GetPlayer(atGame);
  if IsDefined(vNow) && CBGangLostHere(atGame, faction, vNow.GetWorldPosition()) {
    fear += CBConfig.PlaceFear();
  }
  // V bleeding is a chance, to somebody who was afraid of V (Model/Moment.reds).
  if IsDefined(sys) && CBVWounded(sys.GetGameInstance()) {
    fear -= CBConfig.WoundedEmbolden();
  }
  let chance = (fear - nerve * CBConfig.HoldBackNerveWeight()) * CBConfig.HoldBackScale()
             - Cast<Float>(backers) * CBConfig.HoldBackPerBacker();
  return ClampF(chance * sys.WornPerk().breakMult * CBCodeNerve(faction), 0.0, CBConfig.HoldBackMax());
}

// What the Hub says: the odds for one of their rank and file standing with one friend.
public func CBHoldBackTypical(sys: ref<CyberbaneSystem>, faction: CName) -> Float {
  let nerve = 1.0 - CBConfig.FleeChance();
  let content = IsDefined(sys) ? sys.GetContent() : null;
  if IsDefined(content) {
    let prof = content.GetFaction(faction);
    if IsDefined(prof) {
      nerve += prof.courageMod;
    }
  }
  return CBHoldBackOdds(sys, faction, ClampF(nerve, 0.0, 1.0), 1);
}

// Rolled once per person and kept, so the same ganger does not hold back one second and draw the next.
public func CBHoldsBackFromV(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>, faction: CName) -> Bool {
  if !IsDefined(npc) {
    return false;
  }
  if npc.cbHoldState == 0 {
    npc.cbHoldState = RandF() < CBHoldBackChance(sys, npc, faction) ? 1 : 2;
    if npc.cbHoldState == 1 {
      CBLog.Verbose(n"Reactions", s"One of \(NameToString(faction)) holds back from V out of fear.");
    }
  }
  return npc.cbHoldState == 1;
}

// How many of this gang are standing within `radius` of this one, up to `cap`. Out of a fight, so the
// test is who they are with, not who could break.
public func CBSameGangNear(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>, faction: CName,
                           radius: Float, cap: Int32) -> Int32 {
  let reg = IsDefined(sys) ? sys.GetRegistry() : null;
  if !IsDefined(reg) || !IsDefined(npc) {
    return 0;
  }
  let here = npc.GetWorldPosition();
  let id = npc.GetEntityID();
  let count = 0;
  let all = reg.GetAll();
  let i = 0;
  while i < ArraySize(all) && count < cap {
    let other = all[i];
    i += 1;
    if CBNpcSafe(sys, other) && NotEquals(other.GetEntityID(), id) && !other.IsDead()
       && Vector4.Distance(here, other.GetWorldPosition()) <= radius
       && Equals(CBClassifyFaction(other), faction) {
      count += 1;
    }
  }
  return count;
}
