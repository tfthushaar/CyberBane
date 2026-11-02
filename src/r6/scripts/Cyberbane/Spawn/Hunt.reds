// Cyberbane - Being hunted (spec §9.11)
//
// A player put the problem better than any note in this file had: "I don't feel like I'm being
// hunted, I just feel like an arbitrary timer spawns hard to kill mobs on me." They were right
// about how it worked. Everyone Cyberbane sent was placed a short way behind V and handed V's live
// position, refreshed every few seconds for the whole encounter, so a hunt was an ambush with a
// target lock. Nobody ever had to find V, so nobody could ever fail to.
//
// The police in this game are the model players already know. They are told roughly where you
// are, they search, they converge when they see you, they search where they last saw you when you
// break contact, and if you stay gone they give up. This file is that, for the people Cyberbane
// sends:
//
//   Dispatched   the gang or the Rival tells you they are coming, and you get lead time.
//   Searching    they arrive further out and sweep the area around where they think you are.
//                That starts as a rough tip and tightens the longer they look.
//   Located      one of them has seen you, or heard you: gunfire and bodies carry. Now they get
//                your position, and only while somebody can actually see you.
//   Lost         nobody has seen you for a while: they go back to searching where you were last
//                seen, and if that comes to nothing for long enough, they give up.
//
// What "seen" means is deliberately the game's own idea of it: a hunter who is in combat with V,
// or one close enough to see V with nothing in the way, by the same visibility test the witness
// system uses (StimReactionComponent.IsTargetVisible). Noise is a kill or a firefight within
// earshot of a hunter.
//
// The state is session only and global: there is one answer to "do the people after you know
// where you are", whichever lane sent them, which is also how the police work.

public func CBHuntNone() -> Int32 = 0
public func CBHuntSearching() -> Int32 = 1
public func CBHuntLocated() -> Int32 = 2

// Somebody has been sent. They have a tip about where V is, not V's position: within
// HuntTipError of where V was standing when they set off.
public func CBHuntBegin(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) {
    return;
  }
  let p = player.GetWorldPosition();
  let err = CBConfig.HuntTipError();
  let ang = RandRangeF(0.0, 6.2831);
  let tip = new Vector4(p.X + CosF(ang) * RandRangeF(err * 0.3, err), p.Y + SinF(ang) * RandRangeF(err * 0.3, err), p.Z, 1.0);
  // A hunt already under way keeps what it knows; a new one starts from the tip.
  if sys.GetHuntState() == CBHuntNone() || !CBHuntersOut(sys, game) {
    sys.SetHuntState(CBHuntSearching());
    sys.SetHuntLkp(tip);
    sys.SetHuntLastSeenTick(sys.GetTickCount());
    sys.SetHuntSearchStartTick(sys.GetTickCount());
    CBHuntStartSearch(sys);
  }
  sys.SetHuntFaction(faction);
}

// A search starts: how long they will give it, varied every time, and where V was when it began.
func CBHuntStartSearch(sys: ref<CyberbaneSystem>) -> Void {
  let j = CBConfig.HuntGiveUpJitter();
  sys.SetHuntGiveUpTicks(Max(30, CBConfig.HuntGiveUpTicks() + RandRange(-j, j + 1)));
  sys.SetSearchDistrict(sys.GetCurrentDistrict());
  sys.SetSpotTicks(0);
}

// Is anybody of ours alive and out there, or on their way?
public func CBHuntersOut(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  return CBLiveTaggedPresent(game, n"CB_Rival") || CBLiveTaggedPresent(game, n"CB_Apex")
      || CBLiveTaggedPresent(game, n"CB_Squad") || CBLiveTaggedPresent(game, n"CB_Escort")
      || CBLiveTaggedPresent(game, n"CB_Scout");
}

public func CBHuntPending(sys: ref<CyberbaneSystem>) -> Bool {
  let rivalComing = sys.GetRivalWarned() > 0 && sys.GetLaneRivalId(CBLaneRival()) == sys.GetRivalWarned();
  // A car on its way counts too: its crew are in the world only once the car has arrived.
  return NotEquals(sys.GetScoutFaction(), n"")
      || NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetPendingApexFaction(), n"")
      || sys.HasPendingArrival() || sys.GetRivalCarPending() > 0
      || rivalComing;
}

// Send one hunter where the hunt says they should go: at V while V is located, otherwise to a
// point near where V was last known. Used by spawn setup, the car watch and the hunt tick, so a
// hunter is never handed V's position by some other door.
public func CBOrderPursue(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) {
    return;
  }
  if !IsDefined(sys) || sys.GetHuntState() != CBHuntSearching() {
    CBOrderHunt(game, puppet);
    return;
  }
  CBOrderSearch(game, puppet, CBHuntSearchPoint(sys));
}

// Somewhere near the last known position. The circle starts wide and tightens the longer they
// have been looking, the way a search does.
public func CBHuntSearchPoint(sys: ref<CyberbaneSystem>) -> Vector4 {
  let lkp = sys.GetHuntLkp();
  let looked = Cast<Float>(sys.GetTickCount() - sys.GetHuntSearchStartTick());
  let t = ClampF(looked / Cast<Float>(CBConfig.HuntNarrowTicks()), 0.0, 1.0);
  let r = CBConfig.HuntSearchRadiusStart() + (CBConfig.HuntSearchRadiusMin() - CBConfig.HuntSearchRadiusStart()) * t;
  let ang = RandRangeF(0.0, 6.2831);
  let d = RandRangeF(r * 0.25, r);
  return new Vector4(lkp.X + CosF(ang) * d, lkp.Y + SinF(ang) * d, lkp.Z, 1.0);
}

// Walk somewhere and look around. A position rather than V, at a run rather than a sprint, and
// released when they get there or the moment combat starts.
public func CBOrderSearch(game: GameInstance, puppet: ref<ScriptedPuppet>, point: Vector4) -> Void {
  if !IsDefined(puppet) {
    return;
  }
  let ai = puppet.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  let cmd = new AIMoveToCommand();
  let dest: AIPositionSpec;
  let wp: WorldPosition;
  WorldPosition.SetVector4(wp, point);
  AIPositionSpec.SetWorldPosition(dest, wp);
  cmd.movementTarget = dest;
  // Run to the area, then walk it the way a guard would.
  let nearPoint = Vector4.Distance(puppet.GetWorldPosition(), point) <= CBConfig.HuntWalkDistance();
  cmd.movementType = nearPoint ? moveMovementType.Walk : moveMovementType.Run;
  cmd.ignoreInCombat = true;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  cmd.desiredDistanceFromTarget = 2.0;
  CBIssueMove(puppet, ai, cmd);
}

// Once per fast tick, on a settled tick. Works out whether anyone can see or hear V, moves the
// hunt between its states, keeps everybody doing the right thing, and gives up when it is over.
public func CBHuntTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !CBWorldStable(game) {
    return;
  }
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(player) || !IsDefined(des) {
    return;
  }
  CBScoutTick(sys, game, player);
  let out = CBHuntersOut(sys, game);
  if !out {
    // Nobody in the world. If nobody is on the way either, for long enough to be sure (a crew
    // that has just been sent takes a moment to appear), the hunt is over.
    if !CBHuntPending(sys) && sys.GetHuntState() != CBHuntNone() {
      if sys.BumpHuntIdleTicks() >= CBConfig.HuntIdleEndTicks() {
        sys.SetHuntState(CBHuntNone());
        sys.SetHuntFaction(n"");
        sys.SetHuntGrade("");
        sys.SetSpotTicks(0);
        sys.SetHuntIdleTicks(0);
        sys.SetHuntEnd("THREAT ENDED", CBConfig.HuntEndLineTicks());
      }
    } else {
      sys.SetHuntIdleTicks(0);
    }
    sys.SetChaseAwayTicks(0);
    return;
  }
  sys.SetHuntIdleTicks(0);
  if sys.GetHuntState() == CBHuntNone() {
    // People are out with no hunt on record: an older arrival, or one placed by another path.
    // They start knowing roughly where V is.
    CBHuntBegin(sys, game, sys.GetHuntFaction());
  }
  let ppos = player.GetWorldPosition();
  let now = sys.GetTickCount();

  // Can anybody see or hear V? 2 is certain (already fighting V, or heard it), 1 is a sighting.
  // A sighting has to hold for a moment before the hunt counts V as found: a glimpse is not a
  // fix, and breaking line of sight in that moment sends them back to searching. This only
  // changes what Cyberbane does with them; the game's own perception still runs as it always does.
  let contact = CBHuntAnyoneSeesPlayer(sys, game, des, player, ppos);
  let confirmed = contact >= 2 || sys.GetHuntState() == CBHuntLocated() && contact >= 1;
  if !confirmed && contact == 1 {
    sys.SetSpotTicks(sys.GetSpotTicks() + 1);
    confirmed = sys.GetSpotTicks() >= CBConfig.SpotConfirmTicks();
  }
  if contact == 0 {
    sys.SetSpotTicks(0);
  }
  if confirmed {
    let was = sys.GetHuntState();
    sys.SetHuntLkp(ppos);
    sys.SetHuntLastSeenTick(now);
    sys.SetHuntState(CBHuntLocated());
    sys.SetSpotTicks(0);
    if was != CBHuntLocated() {
      CBHuntOnLocated(sys, game);
    }
  } else {
    if sys.GetHuntState() == CBHuntLocated()
       && (now - sys.GetHuntLastSeenTick()) >= CBConfig.HuntLostTicks() {
      // Contact broken. Back to searching, starting tight around where V was last seen.
      sys.SetHuntState(CBHuntSearching());
      sys.SetHuntSearchStartTick(now - CBConfig.HuntNarrowTicks() / 2);
      CBHuntStartSearch(sys);
      CBLog.Info(n"Spawn", "Hunters lost sight of you; searching where you were last seen.");
    }
  }

  // Over? Either V has been gone a long time while they searched, or V has simply put a lot of
  // distance between them and every hunter and stayed out of sight.
  if sys.GetHuntState() == CBHuntSearching() {
    // Ways to make them lose interest faster: get somewhere safe, or drive out of the district
    // they are searching. Either counts every unseen second twice.
    let driving = IsDefined(player.GetMountedVehicle());
    let leftArea = driving && NotEquals(sys.GetSearchDistrict(), n"")
                   && NotEquals(sys.GetCurrentDistrict(), sys.GetSearchDistrict());
    if sys.IsInSafeZone() || leftArea {
      sys.SetHuntLastSeenTick(sys.GetHuntLastSeenTick() - 1);
    }
    let unseen = now - sys.GetHuntLastSeenTick();
    let nearest = CBNearestHunterDistance(sys, game, des, ppos);
    if unseen >= sys.GetHuntGiveUpTicks()
       || (nearest >= CBConfig.ChaseLoseDistance() && sys.BumpChaseAwayTicks() >= CBConfig.ChaseLoseTicks()) {
      CBChaseGiveUp(sys, game, des);
      sys.SetHuntState(CBHuntNone());
      sys.SetHuntFaction(n"");
      sys.SetHuntGrade("");
      return;
    }
    if nearest < CBConfig.ChaseLoseDistance() {
      sys.SetChaseAwayTicks(0);
    }
  } else {
    sys.SetChaseAwayTicks(0);
  }

  // Orders, a few at a time. Searching hunters get a fresh point every so often; located hunters
  // are kept coming while they are not already on V.
  let every = sys.GetHuntState() == CBHuntLocated() ? CBConfig.ChaseRefreshEveryTicks() : CBConfig.HuntSearchOrderTicks();
  if now % every == 0 {
    let done = 0;
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Rival", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Apex", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Squad", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Escort", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Scout", done);
  }
}

func CBHuntOrderTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                    ppos: Vector4, tag: CName, out done: Int32) -> Void {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) && done < CBConfig.ChaseRefreshPerPass() {
    let puppet = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    // Somebody broken and running is left to run; somebody still in a car is the car's.
    if CBStillStanding(puppet) && CBNpcSafe(sys, puppet) && !puppet.cbMoraleBroken
       && !VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) && !CBNpcInCombat(puppet) {
      let away = Vector4.Distance(puppet.GetWorldPosition(), ppos);
      if sys.GetHuntState() != CBHuntLocated() || away >= CBConfig.ChaseRefreshMinDistance() {
        CBOrderPursue(sys, game, puppet);
        done += 1;
      }
    }
  }
}

// How well hunters can find V right now, as a multiplier on how far they see and hear. Crouching,
// the dark, wearing the hunting gang's own colours and the game's harder difficulties all make V
// harder to find. Never below a fifth, so a hunt can always end in a fight.
public func CBHuntSenseScale(sys: ref<CyberbaneSystem>, game: GameInstance) -> Float {
  let scale = 1.0;
  let psm = CBPlayerPSM(game);
  if IsDefined(psm)
     && psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion) == EnumInt(gamePSMLocomotionStates.Crouch) {
    scale *= CBConfig.CrouchSenseMult();
  }
  if CBIsNight(game) {
    scale *= CBConfig.NightSenseMult();
  }
  if IsDefined(sys) && NotEquals(sys.GetHuntFaction(), n"")
     && Equals(sys.GetDisguiseFaction(), sys.GetHuntFaction()) {
    scale *= CBConfig.DisguiseSenseMult();
  }
  scale *= 1.0 - CBConfig.DifficultySenseStep() * Cast<Float>(CBDifficultyLevel());
  return MaxF(scale, 0.2);
}

// Does any hunter know where V is? 2 for certain, 1 for a sighting, 0 for nothing.
func CBHuntAnyoneSeesPlayer(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                            player: ref<PlayerPuppet>, ppos: Vector4) -> Int32 {
  // Noise: a kill or a firefight carries a long way, and a hunter within earshot comes to look.
  let loud = sys.GetRecentKills() > 0 || player.IsInCombat();
  let sense = CBHuntSenseScale(sys, game);
  let best = CBHuntTagSees(sys, game, des, n"CB_Rival", player, ppos, loud, sense);
  if best < 2 {
    best = Max(best, CBHuntTagSees(sys, game, des, n"CB_Apex", player, ppos, loud, sense));
  }
  if best < 2 {
    best = Max(best, CBHuntTagSees(sys, game, des, n"CB_Squad", player, ppos, loud, sense));
  }
  if best < 2 {
    best = Max(best, CBHuntTagSees(sys, game, des, n"CB_Escort", player, ppos, loud, sense));
  }
  if best < 2 {
    best = Max(best, CBHuntTagSees(sys, game, des, n"CB_Scout", player, ppos, loud, sense));
  }
  return best;
}

func CBHuntTagSees(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, tag: CName,
                   player: ref<PlayerPuppet>, ppos: Vector4, loud: Bool, sense: Float) -> Int32 {
  let ids = des.GetTaggedIDs(tag);
  let best = 0;
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      let d = Vector4.Distance(p.GetWorldPosition(), ppos);
      // Already fighting V: they know exactly where V is.
      if CBNpcInCombat(p) && d <= CBConfig.HuntCombatKnowsDistance() {
        return 2;
      }
      // Heard it.
      if loud && d <= CBConfig.HuntHearDistance() * sense {
        return 2;
      }
      // Close, and nothing in the way.
      if best < 1 && d <= CBConfig.HuntSpotDistance() * sense && CBWitnessCanSee(p, player) {
        best = 1;
      }
    }
  }
  return best;
}

// The moment they find V. A Rival says so, once per arrival: the text that used to arrive with
// them, when there was nothing to find.
func CBHuntOnLocated(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  CBLog.Info(n"Spawn", "Hunters have found you.");
  let r = sys.FindRivalById(sys.GetActiveRivalId());
  if IsDefined(r) && sys.GetRivalSpottedTexted() != r.id && CBLiveRivalPresent(sys, game) {
    sys.SetRivalSpottedTexted(r.id);
    let content = CBContent(game);
    if IsDefined(content) {
      CBPhoneSendTinted(game, CBRivalDisplayName(content, r), CBRivalArrivalLine(r), CBHudRed());
    }
  }
}

// One line for the HUD while a hunt is on, the way the game shows that the police are after you.
// Empty when nobody is.
public func CBHuntStatusLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let mode = CBHudLineMode();
  if !IsDefined(sys) || Equals(mode, ECBHudLine.Off) {
    return "";
  }
  let huntsOnly = Equals(mode, ECBHudLine.HuntsOnly);
  // One short line, never more. Longest first is the name, so the name is what gets clipped.
  let who = CBClip(CBBarFactionLabel(sys.GetHuntFaction()), CBConfig.HudNameMaxChars());
  let head = StrLen(who) > 0 ? "HUNTED: " + who : "HUNTED";
  // On the way: the nearest countdown that is running.
  let eta = -1;
  if NotEquals(sys.GetPendingSquadFaction(), n"") && sys.GetPendingSquadTicks() > 0 {
    eta = sys.GetPendingSquadTicks();
    who = CBBarFactionLabel(sys.GetPendingSquadFaction());
  }
  if NotEquals(sys.GetPendingApexFaction(), n"") && sys.GetPendingApexTicks() > 0 && !sys.IsPendingApexDriving() {
    if eta < 0 || sys.GetPendingApexTicks() < eta {
      eta = sys.GetPendingApexTicks();
      who = CBBarFactionLabel(sys.GetPendingApexFaction());
    }
  }
  if sys.GetRivalWarned() > 0 && sys.GetLaneRivalId(CBLaneRival()) == sys.GetRivalWarned()
     && sys.GetLaneTicks(CBLaneRival()) > 0 {
    if eta < 0 || sys.GetLaneTicks(CBLaneRival()) < eta {
      eta = sys.GetLaneTicks(CBLaneRival());
      let r = sys.FindRivalById(sys.GetRivalWarned());
      who = IsDefined(r) ? StrUpper(CBRivalDisplayName(sys.GetContent(), r)) : who;
    }
  }
  who = CBClip(who, CBConfig.HudNameMaxChars());
  let out = CBHuntersOut(sys, game);
  if !out {
    if eta > 0 {
      let grade = sys.GetHuntGrade();
      let named = StrLen(who) > 0 ? who : "SOMEBODY";
      let what = StrLen(grade) > 0 ? named + " " + grade : named;
      return "HUNTED: " + what + "   -   ON THEIR WAY " + StrUpper(CBTimeText(eta));
    }
    if huntsOnly {
      return "";   // only while somebody is on their way or out looking
    }
    // Nobody on the way yet, but somebody is asking around about V.
    let tracker = CBTrackedBy(sys);
    if StrLen(tracker) > 0 {
      return "TRACKED: " + CBClip(tracker, CBConfig.HudNameMaxChars());
    }
    // How the last hunt ended, for a few seconds.
    return sys.GetHuntEndLine();
  }
  if sys.GetHuntState() == CBHuntLocated() {
    return head + "   -   THEY HAVE YOU";
  }
  if sys.GetSpotTicks() > 0 {
    return head + "   -   SPOTTED";
  }
  let unseen = sys.GetTickCount() - sys.GetHuntLastSeenTick();
  if unseen >= sys.GetHuntGiveUpTicks() * 2 / 3 {
    return head + "   -   LOSING YOUR TRAIL";
  }
  return head + "   -   SEARCHING FOR YOU";
}

// Who is asking around about V right now: a crew or apex squad queued and not yet warned, or a
// Rival on the clock who has not yet said they are coming. Empty when nobody is.
//
// Only once departure is close (TrackedShowTicks), so the line means "soon" and is not on screen
// for the whole time somebody is merely queued.
func CBTrackedBy(sys: ref<CyberbaneSystem>) -> String {
  if CBArrivalsHeld(sys, sys.GetGameInstance()) {
    return "";   // nobody is counting down while V cannot be reached
  }
  let near = CBConfig.TrackedShowTicks();
  let apex = sys.GetLaneTarget(CBLaneApex());
  let apexTicks = sys.GetLaneTicks(CBLaneApex());
  if NotEquals(apex, n"") && apexTicks > 0 && apexTicks <= near {
    return CBBarFactionLabel(apex);
  }
  let crew = sys.GetLaneTarget(CBLaneSquad());
  let crewTicks = sys.GetLaneTicks(CBLaneSquad());
  if NotEquals(crew, n"") && crewTicks > 0 && crewTicks <= near {
    return CBBarFactionLabel(crew);
  }
  if NotEquals(sys.GetScoutFaction(), n"") {
    return CBBarFactionLabel(sys.GetScoutFaction());
  }
  let rid = sys.GetLaneRivalId(CBLaneRival());
  let rivalTicks = sys.GetLaneTicks(CBLaneRival());
  if rid > 0 && sys.GetRivalWarned() != rid && rivalTicks > 0 && rivalTicks <= near {
    let r = sys.FindRivalById(rid);
    if IsDefined(r) {
      return StrUpper(CBRivalDisplayName(sys.GetContent(), r));
    }
  }
  return "";
}

// At most `n` characters, with an ellipsis of three dots when cut.
public func CBClip(s: String, n: Int32) -> String {
  if n <= 3 || StrLen(s) <= n {
    return s;
  }
  return StrLeft(s, n - 3) + "...";
}

// ---- Provocation -----------------------------------------------------------
//
// A hunt should start because of something V did, not because a clock said so. Killing a hostile
// gang's people where somebody sees it provokes that gang: their next crew comes now rather than
// at the next slot on the day's timetable. The day's allowance and the rest between encounters
// still apply, so provocation decides when, never how many.
public func CBProvoke(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") || !CBFactionFieldsSquads(faction) {
    return;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  let posture = score.GetPosture(faction);
  if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
    sys.SetProvoked(faction, sys.GetTickCount() + CBConfig.ProvokeTicks());
  }
}

// ---- Being told ------------------------------------------------------------

func CBHuntWhereLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let where = CBDistrictLabel(CBEventDistrict(sys, game));
  return StrLen(where) > 0 ? where : "around here";
}

// The gang tells V a crew is coming, and roughly how much they know.
public func CBCrewWarning(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  if CBToastsOn() {
    let score = sys.GetScore();
    let vendetta = IsDefined(score) && Equals(score.GetPosture(faction), ECBPosture.Vendetta);
    let where = CBHuntWhereLine(sys, game);
    // On their own streets, somebody of theirs saw V there; anywhere else they heard about it.
    let turf = CBTurfGangsHere(sys);
    let onTheirTurf = ArrayContains(turf, faction);
    // How many, in their own words, from the same number the spawn uses.
    let fs = sys.FindFaction(faction);
    let count = CBNumberWord(CBCrewSizeFor(sys, fs, CBCrewIsInfamous(sys)));
    if vendetta {
      CBPhoneFromGang(game, faction, s"Everybody we have is coming for you. Somebody saw you in \(where).");
    } else {
      if onTheirTurf {
        CBPhoneFromGang(game, faction, s"You are on our streets in \(where). \(count) of ours are on their way.");
      } else {
        CBPhoneFromGang(game, faction, s"\(count) of ours are on their way. We hear you are in \(where).");
      }
    }
  }
  CBAllyTipOff(sys, game, faction);
}

// The gang tells V its apex squad is on the road.
public func CBApexOnTheWay(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  let fs = sys.FindFaction(faction);
  if CBToastsOn() && IsDefined(fs) {
    let name = CBApexName(CBContent(game), faction, fs.apexAtKills);
    CBPhoneFromGang(game, faction, s"\(name) and three of ours are on the road. Last we heard you were in \(CBHuntWhereLine(sys, game)).");
  }
  CBAllyTipOff(sys, game, faction);
}

// A Rival tells V they are coming. Chosen by how they came to be one.
public func CBRivalWarning(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  if !CBToastsOn() || !IsDefined(r) {
    return;
  }
  let content = CBContent(game);
  if !IsDefined(content) {
    return;
  }
  let where = CBHuntWhereLine(sys, game);
  let line = s"Heard you are in \(where). I am coming.";
  if r.killedV > 0 {
    line = s"I put you down once. Heard you are in \(where). Let's do it again.";
  } else {
    if r.sparedByV > 0 {
      line = s"You let me live. Bad call. I know you are in \(where).";
    } else {
      if r.escapes > 0 {
        line = s"Still breathing, both of us. Not for long. You are in \(where), right?";
      }
    }
  }
  CBPhoneSendTinted(game, CBRivalDisplayName(content, r), line, CBHudRed());
}

// ---- Scouts --------------------------------------------------------------------
//
// A gang that does not know where V is does not send six people to wander around. It sends one.
// The scout spawns out of sight, starts from the same rough tip any hunt starts from, and
// searches. If the scout keeps eyes on V for a few seconds they call it in: the crew sets off,
// starting from where the scout saw V. If V deals with the scout, or stays out of sight until they
// give up, the crew never comes and that gang leaves V alone for a while.
//
// The scout is tagged CB_Scout. It is hunted, ordered, swept and looted like any of Cyberbane's
// people, but it is not a crew: killing it does not count as beating that gang's crew, and it
// never holds a crew's place in the lane beyond the scouting itself.

public func CBScoutsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().scouts;
}

// Send a scout instead of a crew, if this is a gang that would. True when one was sent.
public func CBTrySendScout(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Bool {
  if !IsDefined(sys) || !CBScoutsOn() || NotEquals(sys.GetScoutFaction(), n"") {
    return false;
  }
  let fs = sys.FindFaction(faction);
  let score = sys.GetScore();
  if !IsDefined(fs) || !IsDefined(score) || !TDBID.IsValid(fs.sampleRecord) {
    return false;
  }
  // A vendetta sends everybody; a gang whose streets V is on, or that V just hurt, already knows
  // where V is. Only a gang working from rumour sends somebody to look.
  if Equals(score.GetPosture(faction), ECBPosture.Vendetta) {
    return false;
  }
  let turf = CBTurfGangsHere(sys);
  if ArrayContains(turf, faction) {
    return false;
  }
  let now = CBGameSeconds(game);
  let fresh = CBConfig.ScoutFreshHours() * CBConfig.SecondsPerHour();
  if fs.lastIncidentAt > 0.0 && (now - fs.lastIncidentAt) < fresh {
    return false;
  }
  if RandF() >= CBConfig.ScoutChance() {
    return false;
  }
  let body: EntityID;
  if CBSpawnGroup(game, fs.sampleRecord, n"", 1, n"CB_Scout", CBConfig.HitSquadMinSpawnDistance(), body) <= 0 {
    return false;   // could not be placed; the crew comes the usual way
  }
  sys.SetScout(faction, body);
  sys.SetHuntGrade("SCOUT");
  if CBToastsOn() {
    let district = sys.GetCurrentDistrict();
    let line = "Somebody is walking your block asking questions. Just one, for now.";
    if NotEquals(district, n"") {
      CBPhoneFromDistrict(game, district, line);
    } else {
      CBPhoneFromStreet(game, line);
    }
  }
  CBLog.Info(n"Spawn", s"\(NameToString(faction)) sent a scout ahead of their crew.");
  return true;
}

// Once per fast tick, from the hunt tick.
func CBScoutTick(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
  let faction = sys.GetScoutFaction();
  if Equals(faction, n"") {
    return;
  }
  let scout = GameInstance.FindEntityByID(game, sys.GetScoutId()) as ScriptedPuppet;
  let age = sys.GetTickCount() - sys.GetScoutSentTick();
  if !IsDefined(scout) {
    // Not in the world. Give a new spawn time to appear; after that the crew comes the usual way.
    if age >= CBConfig.ScoutSpawnGraceTicks() {
      sys.ClearScout();
      CBScoutCallIn(sys, game, faction, false);
    }
    return;
  }
  if !CBStillStanding(scout) {
    // Put down before they could call it in. The crew never hears, and the gang cools off.
    sys.ClearScout();
    let fs = sys.FindFaction(faction);
    if IsDefined(fs) {
      fs.lastHitSquadAt = CBGameSeconds(game);
    }
    if CBToastsOn() {
      CBPhoneFromGangFinal(game, faction, "Our guy stopped answering. We will find you another way.");
    }
    CBLog.Info(n"Spawn", s"The \(NameToString(faction)) scout went down before calling it in.");
    return;
  }
  if !CBNpcSafe(sys, scout) {
    return;
  }
  // Eyes on V: in a fight with V, or close with nothing in the way.
  let d = Vector4.Distance(scout.GetWorldPosition(), player.GetWorldPosition());
  let sees = CBNpcInCombat(scout) && d <= CBConfig.HuntCombatKnowsDistance()
          || d <= CBConfig.HuntSpotDistance() * CBHuntSenseScale(sys, game) && CBWitnessCanSee(scout, player);
  if !sees {
    sys.SetScoutSeenTicks(0);
    return;
  }
  sys.SetScoutSeenTicks(sys.GetScoutSeenTicks() + 1);
  if sys.GetScoutSeenTicks() >= CBConfig.ScoutCallTicks() {
    sys.ClearScout();
    sys.SetHuntLkp(player.GetWorldPosition());
    sys.SetHuntLastSeenTick(sys.GetTickCount());
    CBScoutCallIn(sys, game, faction, true);
  }
}

// The crew sets off: because the scout found V, or because no scout could be placed.
func CBScoutCallIn(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, spotted: Bool) -> Void {
  if NotEquals(sys.GetPendingSquadFaction(), n"") {
    return;
  }
  sys.SetPendingSquad(faction, CBWarningTicks(CBConfig.CrewWarningTicks()));
  sys.SetHuntGrade(CBCrewGrade(sys, faction));
  if spotted && CBToastsOn() {
    let fs = sys.FindFaction(faction);
    let count = CBNumberWord(CBCrewSizeFor(sys, fs, CBCrewIsInfamous(sys)));
    CBPhoneFromGang(game, faction, s"Our scout has eyes on you. \(count) of ours are on their way.");
    CBAllyTipOff(sys, game, faction);
    CBLog.Info(n"Spawn", s"The \(NameToString(faction)) scout found you and called in the crew.");
    return;
  }
  CBCrewWarning(sys, game, faction);
}

public func CBHudLineMode() -> ECBHudLine {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return ECBHudLine.Everything;
  }
  return rt.GetSettings().hudLine;
}

// ---- Letting go of a fight that is over -----------------------------------------
//
// "After the people hunting me find me and get killed, I stay stuck in combat for a long time."
// The game keeps V in combat for as long as any NPC is in combat with V. Once the ones who found V
// are dead, the ones keeping it going are Cyberbane's people who are still in combat but nowhere
// near: one who broke and ran, one stuck behind geometry, one still sitting in a car. They will
// never reach V, and the combat never ends. Anyone of ours who has been in combat with V for
// CombatReleaseTicks while farther than CombatReleaseDistance and unable to see V is let go:
// removed out of sight through the safe path, or ordered out of the car first.
public func CBCombatReleaseTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(des) || !player.IsInCombat() || !CBWorldStable(game) {
    return;
  }
  CBReleaseTag(sys, game, des, player, n"CB_Rival");
  CBReleaseTag(sys, game, des, player, n"CB_Apex");
  CBReleaseTag(sys, game, des, player, n"CB_Squad");
  CBReleaseTag(sys, game, des, player, n"CB_Escort");
  CBReleaseTag(sys, game, des, player, n"CB_Scout");
}

func CBReleaseTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                  player: ref<PlayerPuppet>, tag: CName) -> Void {
  let ppos = player.GetWorldPosition();
  let crewSeated = CBAnyCrewSeated(game, des);
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      let far = Vector4.Distance(p.GetWorldPosition(), ppos) > CBConfig.CombatReleaseDistance();
      if CBNpcInCombat(p) && far && !CBWitnessCanSee(p, player) {
        p.cbOutOfFightTicks += 2;
        if p.cbOutOfFightTicks >= CBConfig.CombatReleaseTicks() {
          CBLog.Info(n"Spawn", "One of ours was keeping you in combat from too far away; letting them go.");
          if !CBRemoveOne(game, des, p.GetEntityID(), crewSeated) {
            des.UnassignTag(p.GetEntityID(), tag);
            des.AssignTag(p.GetEntityID(), n"CB_Orphan");
          }
        }
      } else {
        p.cbOutOfFightTicks = 0;
      }
    }
  }
}

@addField(ScriptedPuppet)
public let cbOutOfFightTicks: Int32;
