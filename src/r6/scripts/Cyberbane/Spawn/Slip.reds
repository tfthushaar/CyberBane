// Cyberbane - Slipping a gang's countdown (2.7.1)
//
// "Is there a way to hide from the ambush? I know gangs sometimes send a scout first, but half of it, the ambush just spawns
// nearby after the countdown reaches 0. Will covering V's face make V unrecognisable? I disabled They Will Remember."
//
// It was so. Lie low [41] (Spawn/Hunted.reds) let a changed look or a new district make a trail go cold, but only once
// somebody was out searching. Before that, while the warning's countdown ran with nobody in the world, the hunt moved its
// word on where V is to V every tick (CBHuntTick: "All of it starts now: from word on where V is today, when they get
// here"), so whatever V did they arrived round V. A mask already slowed a grudge (GrudgeMaskMult) and a gang's colours
// already dulled its hunters (DisguiseSenseMult); none of it touched a crew already on its way.
//
// Now the countdown can be slipped. From the moment a gang's crew or apex squad is sent, what V does counts against it:
//   a changed look (the same measure lie low uses, TrailLookChange), a mask put on, another district, a ride (the metro, a
//   cab: the story's restricted hold), and home ground (Spawn/HomeGround.reds), which counts twice.
// The word on V stops following V at the first of them. When the countdown runs out:
//   nothing changed      they come as before;
//   one change           they come in looking where V was, not where V is, a little slower to pick V out (SlipSenseMult),
//                        and the trail's ordinary going cold can then lose them;
//   two or more          a roll that they lose V before setting off (SlipLoseTwo, SlipLoseMore): the appointment is
//                        dropped, the street says so, and the gang's grudge clock starts again from now.
// A gang at Vendetta, one with a tracker on V ([49]) and one whose streets V is on know where V is, the rule scouts already
// follow (CBTrySendScout): none of this counts for them. Under the Lie low switch. Session only: nothing is saved.

public func CBSlipLook() -> Int32 = 1
public func CBSlipMask() -> Int32 = 2
public func CBSlipDistrict() -> Int32 = 4
public func CBSlipRide() -> Int32 = 8
public func CBSlipHome() -> Int32 = 16

public class CBSlipState extends ScriptableSystem {
  public let faction: CName;
  public let active: Bool;
  public let look0: Float;
  public let masked0: Bool;
  public let district0: CName;
  public let bits: Int32;
  // The crew that came in looking in the wrong place, for as long as their hunt lasts.
  public let slipped: Bool;
  public let slippedFaction: CName;
  public let hintDay: Int32;   // stored one up

  public static func Get(game: GameInstance) -> ref<CBSlipState> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBSlipState") as CBSlipState : null;
  }
}

// They know where V is: none of it counts.
func CBSlipExempt(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Bool {
  if !CBLieLowOn() || Equals(faction, n"") {
    return true;
  }
  let score = sys.GetScore();
  if IsDefined(score) && Equals(score.GetPosture(faction), ECBPosture.Vendetta) {
    return true;
  }
  if Equals(faction, CBTrackerGang(game)) {
    return true;
  }
  // V has just hurt them: they know where V is, as for their scouts (CBTrySendScout).
  let fs = sys.FindFaction(faction);
  let fresh = CBConfig.ScoutFreshHours() * CBConfig.SecondsPerHour();
  if IsDefined(fs) && fs.lastIncidentAt > 0.0 && (CBGameSeconds(game) - fs.lastIncidentAt) < fresh {
    return true;
  }
  let turf = CBTurfGangsHere(sys);
  return ArrayContains(turf, faction);
}

// A gang has just sent its people after V from rumour (Spawn/Queue.reds, CBLaneFire).
public func CBSlipBegin(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  let st = CBSlipState.Get(game);
  if !IsDefined(st) || !IsDefined(sys) {
    return;
  }
  st.active = false;
  st.bits = 0;
  st.slipped = false;
  st.slippedFaction = n"";
  if CBSlipExempt(sys, game, faction) {
    return;
  }
  st.faction = faction;
  st.active = true;
  let score = sys.GetScore();
  st.look0 = IsDefined(score) ? score.GetLook() : 0.0;
  st.masked0 = CBPlayerMasked(game);
  st.district0 = sys.GetCurrentDistrict();
  // What helps, once a game day: the rest of the time the player knows.
  let day = CBGameDay(game);
  if st.hintDay != day + 1 {
    st.hintDay = day + 1;
    let where = CBDistrictLabel(st.district0);
    CBSystemNote(game, StrLen(where) > 0 ? CBTf(n"Cyberbane-Slip-Hint", [where]) : CBT(n"Cyberbane-Slip-HintNoDistrict"), 7.0);
  }
}

// Every tick (Spawn/Hunted.reds, CBHuntedTick): what V has done since the word went out.
public func CBSlipTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let st = CBSlipState.Get(game);
  if !IsDefined(st) || !IsDefined(sys) {
    return;
  }
  if st.slipped && sys.GetHuntState() == CBHuntNone() {
    st.slipped = false;
    st.slippedFaction = n"";
  }
  if !st.active {
    return;
  }
  // Still on their way? Anything else ending the appointment (called off, paid off, V's crew, the story) ends this too.
  if !Equals(sys.GetPendingSquadFaction(), st.faction) && !Equals(sys.GetPendingApexFaction(), st.faction) {
    st.active = false;
    return;
  }
  let score = sys.GetScore();
  let look = IsDefined(score) ? score.GetLook() : st.look0;
  if AbsF(look - st.look0) >= CBConfig.TrailLookChange() {
    st.bits = st.bits | CBSlipLook();
  }
  if !st.masked0 && CBPlayerMasked(game) {
    st.bits = st.bits | CBSlipMask();
  }
  let here = sys.GetCurrentDistrict();
  if NotEquals(here, n"") && NotEquals(st.district0, n"") && NotEquals(here, st.district0) {
    st.bits = st.bits | CBSlipDistrict();
  }
  if sys.GetStoryHold() == CBStoryRestricted() {
    st.bits = st.bits | CBSlipRide();
  }
  if CBOnHomeGround(game) && !Equals(CBHomeGroundMode(), ECBHomeGround.Open) {
    st.bits = st.bits | CBSlipHome();
  }
}

// Has V broken the trail since the word went out? Then the word stops following V (Spawn/Hunt.reds).
public func CBSlipBroken(game: GameInstance) -> Bool {
  let st = CBSlipState.Get(game);
  return IsDefined(st) && st.active && st.bits != 0;
}

// Did this hunt come in looking where V was?
public func CBSlipSlipped(game: GameInstance, faction: CName) -> Bool {
  let st = CBSlipState.Get(game);
  return IsDefined(st) && st.slipped && NotEquals(faction, n"") && Equals(st.slippedFaction, faction);
}

func CBSlipCount(bits: Int32) -> Int32 {
  let n = 0;
  if (bits & CBSlipLook()) != 0 { n += 1; }
  if (bits & CBSlipMask()) != 0 { n += 1; }
  if (bits & CBSlipDistrict()) != 0 { n += 1; }
  if (bits & CBSlipRide()) != 0 { n += 1; }
  if (bits & CBSlipHome()) != 0 { n += 2; }
  return n;
}

// The countdown has run out (Spawn/HitSquad.reds, Spawn/FactionApex.reds). True when they lost V and nobody comes.
public func CBSlipResolve(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Bool {
  let st = CBSlipState.Get(game);
  if !IsDefined(st) || !IsDefined(sys) || !st.active || !Equals(st.faction, faction) {
    return false;
  }
  st.active = false;
  // Asked again now: a vendetta sworn, a tracker put on V, or V walking onto their streets since the word went out.
  if CBSlipExempt(sys, game, faction) {
    return false;
  }
  let count = CBSlipCount(st.bits);
  if count <= 0 {
    return false;
  }
  if count >= 2 {
    let chance = count == 2 ? CBConfig.SlipLoseTwo() : CBConfig.SlipLoseMore();
    if RandF() < chance {
      CBSlipLost(sys, game, faction, count);
      return true;
    }
  }
  st.slipped = true;
  st.slippedFaction = faction;
  CBLog.Info(n"Spawn", s"\(NameToString(faction)) come in looking where you were (\(count) change(s) since they set out).");
  return false;
}

func CBSlipLost(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, count: Int32) -> Void {
  if Equals(sys.GetPendingSquadFaction(), faction) {
    sys.ClearPendingSquad();
  }
  if Equals(sys.GetPendingApexFaction(), faction) {
    sys.SetPendingApex(n"", 0);
    if Equals(sys.GetApexMusterFaction(), faction) {
      sys.ClearApexMuster();
    }
  }
  // Their grudge starts its clock again from now (Spawn/Grudge.reds, CBGangLastMove).
  let fs = sys.FindFaction(faction);
  if IsDefined(fs) {
    fs.lastHitSquadAt = CBGameSeconds(game);
  }
  if Equals(sys.GetHuntFaction(), faction) && !CBHuntersOut(sys, game) {
    sys.SetHuntState(CBHuntNone());
    sys.SetHuntFaction(n"");
    sys.SetHuntGrade("");
  }
  CBLog.Info(n"Spawn", s"\(NameToString(faction)) lost you before they set off (\(count) change(s) since they set out).");
  if CBToastsOn() {
    CBPhoneFromStreet(game, CBTf(n"Cyberbane-Slip-Lost", [CBCapFirst(CBFactionLabel(faction))]));
  }
}
