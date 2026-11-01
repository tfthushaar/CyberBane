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
  }
  sys.SetHuntFaction(faction);
}

// Is anybody of ours alive and out there, or on their way?
public func CBHuntersOut(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  return CBLiveTaggedPresent(game, n"CB_Rival") || CBLiveTaggedPresent(game, n"CB_Apex")
      || CBLiveTaggedPresent(game, n"CB_Squad") || CBLiveTaggedPresent(game, n"CB_Escort");
}

public func CBHuntPending(sys: ref<CyberbaneSystem>) -> Bool {
  let rivalComing = sys.GetRivalWarned() > 0 && sys.GetLaneRivalId(CBLaneRival()) == sys.GetRivalWarned();
  return NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetPendingApexFaction(), n"")
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
  cmd.movementType = moveMovementType.Run;
  cmd.ignoreInCombat = true;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  cmd.desiredDistanceFromTarget = 2.0;
  let evt = new AICommandEvent();
  evt.command = cmd;
  puppet.QueueEvent(evt);
  ai.SendCommand(cmd);
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
  let out = CBHuntersOut(sys, game);
  if !out {
    // Nobody in the world. If nobody is on the way either, the hunt is over.
    if !CBHuntPending(sys) && sys.GetHuntState() != CBHuntNone() {
      sys.SetHuntState(CBHuntNone());
      sys.SetHuntFaction(n"");
    }
    sys.SetChaseAwayTicks(0);
    return;
  }
  if sys.GetHuntState() == CBHuntNone() {
    // People are out with no hunt on record: an older arrival, or one placed by another path.
    // They start knowing roughly where V is.
    CBHuntBegin(sys, game, sys.GetHuntFaction());
  }
  let ppos = player.GetWorldPosition();
  let now = sys.GetTickCount();

  // Can anybody see or hear V?
  let seen = CBHuntAnyoneSeesPlayer(sys, game, des, player, ppos);
  if seen {
    let was = sys.GetHuntState();
    sys.SetHuntLkp(ppos);
    sys.SetHuntLastSeenTick(now);
    sys.SetHuntState(CBHuntLocated());
    if was != CBHuntLocated() {
      CBHuntOnLocated(sys, game);
    }
  } else {
    if sys.GetHuntState() == CBHuntLocated()
       && (now - sys.GetHuntLastSeenTick()) >= CBConfig.HuntLostTicks() {
      // Contact broken. Back to searching, starting tight around where V was last seen.
      sys.SetHuntState(CBHuntSearching());
      sys.SetHuntSearchStartTick(now - CBConfig.HuntNarrowTicks() / 2);
      CBLog.Info(n"Spawn", "Hunters lost sight of you; searching where you were last seen.");
    }
  }

  // Over? Either V has been gone a long time while they searched, or V has simply put a lot of
  // distance between them and every hunter and stayed out of sight.
  if sys.GetHuntState() == CBHuntSearching() {
    let unseen = now - sys.GetHuntLastSeenTick();
    let nearest = CBNearestHunterDistance(sys, game, des, ppos);
    if unseen >= CBConfig.HuntGiveUpTicks()
       || (nearest >= CBConfig.ChaseLoseDistance() && sys.BumpChaseAwayTicks() >= CBConfig.ChaseLoseTicks()) {
      CBChaseGiveUp(sys, game, des);
      sys.SetHuntState(CBHuntNone());
      sys.SetHuntFaction(n"");
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

// Does any hunter see V, or hear V?
func CBHuntAnyoneSeesPlayer(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                            player: ref<PlayerPuppet>, ppos: Vector4) -> Bool {
  // Noise: a kill or a firefight carries a long way, and a hunter within earshot comes to look.
  let loud = sys.GetRecentKills() > 0 || player.IsInCombat();
  return CBHuntTagSees(sys, game, des, n"CB_Rival", player, ppos, loud)
      || CBHuntTagSees(sys, game, des, n"CB_Apex", player, ppos, loud)
      || CBHuntTagSees(sys, game, des, n"CB_Squad", player, ppos, loud)
      || CBHuntTagSees(sys, game, des, n"CB_Escort", player, ppos, loud);
}

func CBHuntTagSees(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, tag: CName,
                   player: ref<PlayerPuppet>, ppos: Vector4, loud: Bool) -> Bool {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      let d = Vector4.Distance(p.GetWorldPosition(), ppos);
      // Already fighting V: they know exactly where V is.
      if CBNpcInCombat(p) && d <= CBConfig.HuntCombatKnowsDistance() {
        return true;
      }
      // Close, and nothing in the way.
      if d <= CBConfig.HuntSpotDistance() && CBWitnessCanSee(p, player) {
        return true;
      }
      // Heard it.
      if loud && d <= CBConfig.HuntHearDistance() {
        return true;
      }
    }
  }
  return false;
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
  if !IsDefined(sys) {
    return "";
  }
  let who = CBBarFactionLabel(sys.GetHuntFaction());
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
  let out = CBHuntersOut(sys, game);
  if !out {
    if eta > 0 {
      return (StrLen(who) > 0 ? "HUNTED: " + who : "HUNTED") + "   -   ON THEIR WAY " + CBHudCountdown(eta);
    }
    return "";
  }
  if sys.GetHuntState() == CBHuntLocated() {
    return head + "   -   THEY HAVE YOU";
  }
  let unseen = sys.GetTickCount() - sys.GetHuntLastSeenTick();
  if unseen >= CBConfig.HuntGiveUpTicks() * 2 / 3 {
    return head + "   -   LOSING YOUR TRAIL";
  }
  return head + "   -   SEARCHING FOR YOU";
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
    if vendetta {
      CBPhoneFromGang(game, faction, s"Everybody we have is coming for you. Somebody saw you in \(where).");
    } else {
      if onTheirTurf {
        CBPhoneFromGang(game, faction, s"You are on our streets in \(where). Some of ours are on their way.");
      } else {
        CBPhoneFromGang(game, faction, s"Some of ours are on their way. We hear you are in \(where).");
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
