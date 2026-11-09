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
//   Searching    they arrive further out and run a closing ring around where they think you are.
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
  let tip = CBHuntTipNear(p);
  // A hunt already under way keeps what it knows; a new one starts from the tip.
  if sys.GetHuntState() == CBHuntNone() || !CBHuntersOut(sys, game) {
    sys.SetHuntState(CBHuntSearching());
    sys.SetHuntLkp(tip);
    sys.SetHuntLastSeenTick(sys.GetTickCount());
    sys.SetHuntSearchStartTick(sys.GetTickCount());
    // Nobody has laid eyes on V yet: they are working from a tip, and the tip firms up the
    // longer they ask around (CBHuntSearchCenter).
    sys.SetHuntFromTip(true);
    sys.SetHuntTipWord(p, sys.GetTickCount());
    CBHuntStartSearch(sys);
  }
  sys.SetHuntFaction(faction);
}

// Word on where V is: somewhere within HuntTipError of this spot.
func CBHuntTipNear(p: Vector4) -> Vector4 {
  let err = CBConfig.HuntTipError();
  let ang = RandRangeF(0.0, 6.2831);
  return new Vector4(p.X + CosF(ang) * RandRangeF(err * 0.3, err), p.Y + SinF(ang) * RandRangeF(err * 0.3, err), p.Z, 1.0);
}

// A search starts: how long they will give it, varied every time, and where V was when it began.
func CBHuntStartSearch(sys: ref<CyberbaneSystem>) -> Void {
  let j = CBConfig.HuntGiveUpJitter();
  sys.SetHuntGiveUpTicks(Max(30, CBConfig.HuntGiveUpTicks() + RandRange(-j, j + 1)));
  sys.SetSearchDistrict(sys.GetCurrentDistrict());
  sys.SetSpotTicks(0);
  // Every searcher is given a fresh point for this search, rather than finishing the walk to
  // one picked for the last.
  sys.BumpHuntSearchGen();
}

// Is anybody of ours still registered but not in the world: not attached, not on their way in,
// and not a body we already know about? Those are people V has left behind.
func CBHuntersLeftBehind(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>) -> Bool {
  return CBTagLeftBehind(sys, game, des, n"CB_Rival") || CBTagLeftBehind(sys, game, des, n"CB_Apex")
      || CBTagLeftBehind(sys, game, des, n"CB_Squad") || CBTagLeftBehind(sys, game, des, n"CB_Escort")
      || CBTagLeftBehind(sys, game, des, n"CB_Scout");
}

func CBTagLeftBehind(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, tag: CName) -> Bool {
  let dead = sys.GetDeadOurs();
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    if !des.IsSpawning(id) && !IsDefined(GameInstance.FindEntityByID(game, id)) && !ArrayContains(dead, id) {
      return true;
    }
  }
  return false;
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
  // So does an apex squad still being brought up to four (Spawn/FactionApex.reds): the chairs it
  // is still walking in are on their way, and the hunt is not over before they get here.
  return NotEquals(sys.GetScoutFaction(), n"")
      || NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetPendingApexFaction(), n"")
      || sys.HasPendingArrival() || sys.HasConvoyLegs() || sys.GetRivalCarPending() > 0
      || NotEquals(sys.GetApexMusterFaction(), n"")
      || rivalComing;
}

// Send one hunter where the hunt says they should go: at V while V is located, otherwise to a
// point near where V is thought to be. Used by spawn setup, the car watch and the hunt tick, so a
// hunter is never handed V's position by some other door.
public func CBOrderPursue(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || puppet.cbMoraleBroken {
    return;
  }
  // Every order on foot comes through here. While V is safe there is nowhere to send anybody
  // (Spawn/Sanctuary.reds), and they are asked again once V is not.
  if IsDefined(sys) && sys.IsInSanctuary() {
    CBCancelMove(puppet);
    puppet.cbSearchGen = 0;
    return;
  }
  if !IsDefined(sys) || sys.GetHuntState() != CBHuntSearching() {
    puppet.cbSearchGen = 0;   // whatever they were searching for is no longer the question
    CBOrderHunt(game, puppet);
    return;
  }
  let point: Vector4;
  if !CBHuntPickSearchPoint(sys, game, puppet, point) {
    // Nowhere near the search this person can walk to. They are given no order rather than an
    // impossible one, and asked again on the next pass (CBHuntNeedsNewPoint).
    puppet.cbSearchGen = 0;
    return;
  }
  puppet.cbSearchPoint = point;
  puppet.cbSearchTick = sys.GetTickCount();
  puppet.cbSearchGen = sys.GetHuntSearchGen();
  CBOrderSearch(game, puppet, point);
}

// The point a searcher is walking to, and when and for which search it was given. Session only.
@addField(ScriptedPuppet)
public let cbSearchPoint: Vector4;

@addField(ScriptedPuppet)
public let cbSearchTick: Int32;

@addField(ScriptedPuppet)
public let cbSearchGen: Int32;

// Does this searcher need somewhere new to look? Only once they have got where they were sent,
// or the walk has gone on too long, or a new search has started since.
//
// Every searcher used to be handed a brand new point every eight seconds whether or not they had
// got anywhere near the last one. Together with points that nobody could walk to (see
// CBHuntPickSearchPoint), that is the "they teleport around every few seconds" report: the
// order was replaced before it could ever be walked.
func CBHuntNeedsNewPoint(sys: ref<CyberbaneSystem>, puppet: ref<ScriptedPuppet>) -> Bool {
  if puppet.cbSearchGen == 0 || puppet.cbSearchGen != sys.GetHuntSearchGen() {
    return true;
  }
  if sys.GetTickCount() - puppet.cbSearchTick >= CBConfig.HuntSearchPointMaxTicks() {
    return true;
  }
  // The ring has closed past where they were sent, or the word has moved on from it.
  if Vector4.Distance(puppet.cbSearchPoint, CBHuntSearchCenter(sys)) > CBHuntRadius(sys) + CBConfig.HuntRingSlack() {
    return true;
  }
  return Vector4.Distance(puppet.GetWorldPosition(), puppet.cbSearchPoint) <= CBConfig.HuntSearchArrivedDistance();
}

// How far into narrowing the search is, 0 when it starts and 1 once it is as tight as it gets.
func CBHuntNarrowing(sys: ref<CyberbaneSystem>) -> Float {
  let looked = Cast<Float>(sys.GetTickCount() - sys.GetHuntSearchStartTick());
  return ClampF(looked / Cast<Float>(CBConfig.HuntNarrowTicks()), 0.0, 1.0);
}

// The middle of the search.
//
// After contact is lost it is where V was last seen, and stays there: V broke away, and they only
// know where that happened. Before anybody has found V at all it is the tip they set off with,
// which could be up to HuntTipError out - and it stayed that far out for the whole search. The
// circle narrowed round the wrong spot, so somebody standing still where the warning found them
// was searched for thirty or sixty metres away until the hunters gave up, never seen and never
// seen coming: "the countdown ends and they never show up", with the health bar on screen. The
// tip now firms up as they ask around, towards the street's latest word on where V is, which is
// only refreshed every so often (HuntTipWordTicks). It is still not V's position: they still
// have to see V, crouching and the dark still hide V, and moving on still leaves them behind.
public func CBHuntSearchCenter(sys: ref<CyberbaneSystem>) -> Vector4 {
  let lkp = sys.GetHuntLkp();
  if !sys.IsHuntFromTip() {
    return lkp;
  }
  let word = sys.GetHuntTipWord();
  let k = CBHuntNarrowing(sys) * CBConfig.HuntTipFirmUp();
  return new Vector4(lkp.X + (word.X - lkp.X) * k, lkp.Y + (word.Y - lkp.Y) * k,
                     lkp.Z + (word.Z - lkp.Z) * k, 1.0);
}

// How wide the ring is right now: it starts wide and closes the longer they have been looking.
func CBHuntRadius(sys: ref<CyberbaneSystem>) -> Float {
  let start = CBConfig.HuntSearchRadiusStart();
  return start + (CBConfig.HuntSearchRadiusMin() - start) * CBHuntNarrowing(sys);
}

// Somewhere on the closing ring that this hunter can actually walk to.
//
// "They don't actively search for me, they just walk around and hit me if they find me." That is
// what this asked of them. Each searcher drew a random point anywhere in a circle fifty metres
// wide, walked the last twenty metres of it, drew another, and nothing about any of it depended on
// where anybody else was or brought them closer together, so a crew was a handful of people
// strolling about a neighbourhood for a minute and a half. Now the circle is a ring that closes:
// each searcher runs in on their own side of it, so a crew arrives from several directions, and a
// searcher already inside it cuts across. The middle is the street's latest word on V
// (CBHuntSearchCenter), so standing still gets V found in well under a minute and moving on still
// leaves them behind.
//
// The point used to be any spot in the circle, at V's height, checked against nothing but job
// sites - and when every try was near a job site (V had just finished one) the last try was used
// anyway. So hunters were sent into walls, onto roofs, into the middle of the air over a drop and
// into sealed lots. The game cannot walk an NPC to a place like that, and what it does instead,
// out of the player's sight, is put them there: the searchers who jumped from spot to spot on the
// minimap and vanished from the scanner after a couple of seconds. Every point is now a floor
// with navmesh on it that this hunter has a path to, the same tests a spawn point has to pass.
// False when there is none; the hunter is then left where they are and asked again shortly.
public func CBHuntPickSearchPoint(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>,
                                  out point: Vector4) -> Bool {
  let center = CBHuntSearchCenter(sys);
  let r = CBHuntRadius(sys);
  let from = puppet.GetWorldPosition();
  // Their own side of the ring: the way they are already coming from.
  let dx = from.X - center.X;
  let dy = from.Y - center.Y;
  let away = SqrtF(dx * dx + dy * dy);
  let ux = away > 1.0 ? dx / away : 1.0;
  let uy = away > 1.0 ? dy / away : 0.0;
  let inside = away <= r;
  let tries = 0;
  while tries < CBConfig.HuntSearchPointTries() {
    // Close to their own line at first, wider with each try that finds no floor. Somebody already
    // inside the ring goes anywhere across it.
    let spread = inside ? 3.14159 : 0.45 + 0.35 * Cast<Float>(tries);
    let turn = RandRangeF(-spread, spread);
    let vx = ux * CosF(turn) - uy * SinF(turn);
    let vy = ux * SinF(turn) + uy * CosF(turn);
    let d = inside ? RandRangeF(r * 0.3, r) : RandRangeF(r * 0.7, r);
    let at: Vector4;
    // Searchers are never sent into a job site.
    if CBHuntStandAt(game, center.X + vx * d, center.Y + vy * d, center.Z, at)
       && !sys.NearQuestPins(at, CBConfig.QuestSpawnClearance())
       && CBPointReachable(game, from, at) {
      point = at;
      return true;
    }
    tries += 1;
  }
  // The middle of the search itself. Orders are not given at all while V is on a job
  // (CBHuntTick), so this is never a walk into one.
  let mid: Vector4;
  if CBHuntStandAt(game, center.X, center.Y, center.Z, mid) && CBPointReachable(game, from, mid) {
    point = mid;
    return true;
  }
  // A long way off, with nothing in the ring that can be routed to from here: a hop towards it,
  // at their own height. Standing still until the ring came to them was the other half of "they
  // just walk around".
  let hop = CBConfig.HuntHopDistance();
  if away > hop {
    let step: Vector4;
    if CBHuntStandAt(game, from.X - ux * hop, from.Y - uy * hop, from.Z, step)
       && !sys.NearQuestPins(step, CBConfig.QuestSpawnClearance())
       && CBPointReachable(game, from, step) {
      point = step;
      return true;
    }
  }
  return false;
}

// A floor at this spot, near this height, with navmesh on it, and not inside anywhere the game
// protects. Every point anybody is sent to search comes through here, and a ring around V in the
// corridor outside their apartment has the apartment in it.
func CBHuntStandAt(game: GameInstance, x: Float, y: Float, zHint: Float, out at: Vector4) -> Bool {
  let gz: Float;
  return CBGroundAt(game, x, y, zHint, gz) && AbsF(gz - zHint) <= CBConfig.HuntSearchMaxDrop()
      && CBStandOnNavmesh(game, x, y, gz, at) && !CBPointIsSafeArea(game, at);
}

// Get somewhere and look around. A position rather than V, and released when they get there or the
// moment combat starts. Nobody on a hunt walks: walking the last of every leg is what made a crew
// look like people out for a stroll. A sprint across the ground, a run once they are close.
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
  let far = Vector4.Distance(puppet.GetWorldPosition(), point) > CBConfig.HuntSprintDistance();
  cmd.movementType = far ? moveMovementType.Sprint : moveMovementType.Run;
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
        // Nobody of ours is in the world, but that is not the same as nobody being left. V can
        // simply have gone far enough for them to stream out, and they stay registered: the
        // hunt used to end here with them still on the books, so they came back into the world
        // as hostile hunters whenever V next passed that way (starting a hunt from nowhere), and
        // a Rival among them stayed "hunting" with a body nobody could reach. V got away from
        // them, so it ends the way getting away does.
        if !sys.CarRecentlyOnTheWay() && CBHuntersLeftBehind(sys, game, des) {
          let r = sys.FindRivalById(sys.GetActiveRivalId());
          if IsDefined(r) && r.state == EnumInt(ECBRivalState.Hunting) && EntityID.IsDefined(r.spawnedEntityId)
             && !IsDefined(GameInstance.FindEntityByID(game, r.spawnedEntityId)) && !sys.IsLairActive() {
            CBRivalEscapedByPlayer(sys, game);
            CBCloseRivalEncounter(sys, game, r, null);
          }
          CBChaseGiveUp(sys, game, des);
          sys.SetHuntState(CBHuntNone());
          sys.SetHuntFaction(n"");
          sys.SetHuntGrade("");
          sys.SetSpotTicks(0);
          sys.SetHuntIdleTicks(0);
          return;
        }
        sys.SetHuntState(CBHuntNone());
        sys.SetHuntFaction(n"");
        sys.SetHuntGrade("");
        sys.SetSpotTicks(0);
        sys.SetHuntIdleTicks(0);
        sys.SetHuntEnd("THREAT ENDED", CBConfig.HuntEndLineTicks());
      }
    } else {
      sys.SetHuntIdleTicks(0);
      // Nobody has arrived yet, so nobody has started looking.
      //
      // The hunt is opened when the warning goes out, a minute or two before anybody is in the
      // world, and every clock on it ran from that moment. So they turned up with most of their
      // patience already spent and the ring already closed tight around wherever V stood when the
      // text arrived, gave it a few seconds and left. All of it starts now: from word on where V
      // is today, when they get here.
      if sys.GetHuntState() == CBHuntSearching() && sys.IsHuntFromTip() {
        let waiting = sys.GetTickCount();
        let vAt = player.GetWorldPosition();
        sys.SetHuntLastSeenTick(waiting);
        sys.SetHuntSearchStartTick(waiting);
        sys.SetHuntLkp(CBHuntTipNear(vAt));
        sys.SetHuntTipWord(vAt, waiting);
      }
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

  // V got somewhere safe: orders taken back, and nobody who has lost sight of V goes on after them.
  // First, so the question below is asked of people who have already stopped.
  if sys.IsInSanctuary() {
    CBSanctuaryHold(sys, game, des, player);
    if now % 30 == 0 {
      CBLog.Info(n"Spawn", "You are somewhere safe: they will not follow you in.");
    }
  }

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
    sys.SetHuntFromTip(false);   // from here on they search where they last saw V
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

  // Found: everybody of ours close enough is told where V is, and the fight is on. This is the
  // only place a hunter is handed V as a target (Spawn/Spawner.reds, CBEngageV), so until somebody
  // has actually found V nobody is tracking V and V is not in combat - the phone, saving and fast
  // travel all work while they are still looking. Not while the story has the stage.
  if sys.GetHuntState() == CBHuntLocated() && sys.GetStoryHold() == CBStoryNone() && !sys.IsInSanctuary() {
    CBHuntEngage(sys, game, des, ppos);
  }

  // The street's word on where V is, while they are still working from the tip. Refreshed only
  // every so often, so it is a rumour that firms up, not a fix (CBHuntSearchCenter).
  if sys.IsHuntFromTip() && now - sys.GetHuntTipWordTick() >= CBConfig.HuntTipWordTicks() {
    sys.SetHuntTipWord(ppos, now);
  }

  // Over? Either V has been gone a long time while they searched, or V has simply put a lot of
  // distance between them and every hunter and stayed out of sight.
  if sys.GetHuntState() == CBHuntSearching() {
    // Ways to make them lose interest faster: get somewhere safe, or drive out of the district
    // they are searching. Either counts every unseen second twice.
    let driving = IsDefined(player.GetMountedVehicle());
    let leftArea = driving && NotEquals(sys.GetSearchDistrict(), n"")
                   && NotEquals(sys.GetCurrentDistrict(), sys.GetSearchDistrict());
    // A job counts as somewhere safe for this: they lose interest faster, and they do not follow.
    if sys.IsInSafeZone() || sys.IsInSanctuary() || sys.IsInQuestArea() || leftArea {
      sys.SetHuntLastSeenTick(sys.GetHuntLastSeenTick() - 1);
    }
    let unseen = now - sys.GetHuntLastSeenTick();
    let nearest = CBNearestHunterDistance(sys, game, des, ppos);
    // A car on its way has not lost V: it is further off than the lose distance by design, and its
    // crew count as hunters from the moment they are seated. Without this a car on its way to V
    // was called off and its crew deleted after twenty-two seconds, before it could arrive.
    let carComing = sys.CarRecentlyOnTheWay() || sys.HasPendingArrival() || sys.HasConvoyLegs();
    if carComing {
      sys.SetChaseAwayTicks(0);
      sys.SetHuntLastSeenTick(now);
    }
    // Said in the log every half minute: a search that finds nobody looks exactly like a search
    // that is not happening, and only this can tell the two apart.
    if now % 30 == 0 {
      let carNote = carComing ? ", a car on its way" : "";
      CBLog.Info(n"Spawn", s"Searching: \(unseen)s unseen of \(sys.GetHuntGiveUpTicks()), ring \(RoundF(CBHuntRadius(sys)))m, nearest of ours \(RoundF(nearest))m\(carNote).");
    }
    if !carComing && (unseen >= sys.GetHuntGiveUpTicks()
       || (nearest >= CBConfig.ChaseLoseDistance() && sys.BumpChaseAwayTicks() >= CBConfig.ChaseLoseTicks())) {
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
  // No search orders while V is on a job: they hold where they are rather than walk into it. And
  // no orders at all while the story has the stage, whether or not they had found V: anybody still
  // out is somebody V can see, left alone until they are not (Core/StoryHold.reds).
  if now % every == 0 && !(sys.IsInQuestArea() && sys.GetHuntState() != CBHuntLocated())
     && sys.GetStoryHold() == CBStoryNone() && !sys.IsInSanctuary() {
    let done = 0;
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Rival", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Apex", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Squad", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Escort", done);
    CBHuntOrderTag(sys, game, des, ppos, n"CB_Scout", done);
  }
}

// Tell everybody of ours close to V where V is. Somebody already fighting V needs nothing, and
// somebody broken and running is left to run.
func CBHuntEngage(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                  ppos: Vector4) -> Void {
  CBHuntEngageTag(sys, game, des, ppos, n"CB_Rival");
  CBHuntEngageTag(sys, game, des, ppos, n"CB_Apex");
  CBHuntEngageTag(sys, game, des, ppos, n"CB_Squad");
  CBHuntEngageTag(sys, game, des, ppos, n"CB_Escort");
  CBHuntEngageTag(sys, game, des, ppos, n"CB_Scout");
}

func CBHuntEngageTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                     ppos: Vector4, tag: CName) -> Void {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    // Somebody still in a car gets out first: a fight started from a seat, in a moving car, is
    // one of the things 1.5.0 found taking the game down. The car watch lets them out.
    if CBStillStanding(p) && CBNpcSafe(sys, p) && !p.cbMoraleBroken && !CBNpcInCombat(p)
       && !VehicleComponent.IsMountedToVehicle(game, p.GetEntityID())
       && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.HuntEngageDistance() {
      CBEngageV(game, p);
    }
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
      let searching = sys.GetHuntState() != CBHuntLocated();
      if (searching && CBHuntNeedsNewPoint(sys, puppet)) || (!searching && away >= CBConfig.ChaseRefreshMinDistance()) {
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

// A car has parked beside V with a crew that was sent to V. Waiting for one of them to spot V all over
// again is what "they drove up and did nothing" looks like, so they know where V is as they get out,
// and the hunt tick hands V to each of them once they are on their feet. Not where nobody may follow,
// on a job, or while the story has the stage. Their own eyes keep it going from there.
public func CBHuntCrewPulledUp(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) || sys.IsInSanctuary() || sys.IsInQuestArea()
     || sys.GetStoryHold() != CBStoryNone() {
    return;
  }
  let was = sys.GetHuntState();
  sys.SetHuntLkp(player.GetWorldPosition());
  sys.SetHuntLastSeenTick(sys.GetTickCount());
  sys.SetHuntState(CBHuntLocated());
  sys.SetHuntFromTip(false);
  sys.SetSpotTicks(0);
  if was != CBHuntLocated() {
    CBHuntOnLocated(sys, game);
  }
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

// One word for how well known V is in a district. Lifted out of the line below so that the line
// and the slow sample that decides when the line has something new to say (Core/CyberbaneSystem
// .reds) cannot drift to different thresholds - the third time that class of bug has turned up
// here. FindDistrict rather than EnsureDistrict: neither caller may create state, and a district
// V has done nothing in has no record yet, which is itself the answer.
public func CBDistrictRenownWord(sys: ref<CyberbaneSystem>, id: CName) -> String {
  if !IsDefined(sys) || Equals(id, n"") {
    return "";
  }
  let ds = sys.FindDistrict(id);
  let renown = IsDefined(ds) ? ds.renown : 0.0;
  if renown >= 75.0 {
    return "A NAME HERE";
  }
  if renown >= 40.0 {
    return "KNOWN HERE";
  }
  if renown >= 15.0 {
    return "TALKED ABOUT HERE";
  }
  return "UNKNOWN HERE";
}

// Where V stands in the district they are standing in, for the HUD.
//
// This goes in the hunt line's own widget rather than next to it. The hunt line is empty most of
// the time - nobody is hunting V for most of a session - so the space is already there, already
// positioned, already length-limited, and already respects the one setting that governs it. A
// second widget would have been one more thing on screen to read, which is the opposite of what
// was asked for.
//
// It reads as the street would put it rather than as a number first: the district, then how well
// known V is there, with the figure in brackets for anybody who wants it.
public func CBDistrictStatusLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  // Only on Everything. HuntsOnly means what it says, and Off means nothing at all.
  if !IsDefined(sys) || !Equals(CBHudLineMode(), ECBHudLine.Everything) {
    return "";
  }
  let id = sys.GetCurrentDistrict();
  if Equals(id, n"") {
    return "";
  }
  // Its own switch, under the one above. Off never draws it; Briefly draws it only while the
  // slow sample says it still has news (Core/CyberbaneSystem.reds).
  let mode = CBDistrictLineMode();
  if Equals(mode, ECBDistrictLine.Off) {
    return "";
  }
  if Equals(mode, ECBDistrictLine.Briefly) && !sys.DistrictLineFresh(CBDistrictLineSeconds()) {
    return "";
  }
  let label = CBDistrictLabel(id);
  if StrLen(label) == 0 {
    label = NameToString(id);
  }
  let ds = sys.FindDistrict(id);
  let renown = IsDefined(ds) ? ds.renown : 0.0;
  let word = CBTurfHudWord(sys, game, id) + CBDistrictRenownWord(sys, id);
  if renown < 1.0 {
    return StrUpper(CBClip(label, CBConfig.HudNameMaxChars())) + "   -   " + word;
  }
  return StrUpper(CBClip(label, CBConfig.HudNameMaxChars())) + "   -   " + word
       + s"  (\(RoundF(renown)))";
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
    // How many, in their own words, from the same numbers the spawn uses - and who leads them.
    let fs = sys.FindFaction(faction);
    let coming = CBCrewComingLine(sys, game, fs);
    if vendetta {
      CBPhoneFromGang(game, faction, s"Everybody we have is coming for you. Somebody saw you in \(where). \(coming)");
    } else {
      if onTheirTurf {
        CBPhoneFromGang(game, faction, s"You are on our streets in \(where). \(coming)");
      } else {
        CBPhoneFromGang(game, faction, s"\(coming) We hear you are in \(where).");
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
      CBHearsayFromGangFinal(game, faction, "Our guy stopped answering. We will find you another way.", n"");
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
    CBPhoneFromGang(game, faction, s"Our scout has eyes on you. \(CBCrewComingLine(sys, game, fs))");
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

public func CBDistrictLineMode() -> ECBDistrictLine {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return ECBDistrictLine.Briefly;
  }
  return rt.GetSettings().districtLine;
}

public func CBDistrictLineSeconds() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return 10;
  }
  let n = rt.GetSettings().districtLineSeconds;
  if n < 1 {
    return 1;
  }
  return n;
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
  // Only once the fight near V is over. While anybody of ours is still close to V, or has eyes
  // on V, the people further out are part of that fight - a flanker working round behind a wall,
  // somebody hanging back in cover - and letting them go was another way for a crew to vanish in
  // the middle of a firefight. The report this exists for is the other case: everybody close is
  // down and somebody far off is still holding V in combat, and that is exactly when nobody is
  // engaged.
  let engaged = CBOursEngagedNear(sys, game, des, player);
  CBReleaseTag(sys, game, des, player, n"CB_Rival", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Apex", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Squad", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Escort", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Scout", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Patrol", engaged);
  // Anyone handed to the orphan sweep because they were still in view when their encounter
  // ended is still alive and may still be in combat with V, and the sweep only runs on the slow
  // tick. Without this they could hold V in combat in the meantime, which is the 1.5.3 report
  // arriving by a new road. Their encounter is over, so a fight still going on near V is not
  // theirs and does not hold them.
  CBReleaseTag(sys, game, des, player, n"CB_Orphan", false);
}

// Is anybody of ours still in the fight with V: close, or able to see V?
func CBOursEngagedNear(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                       player: ref<PlayerPuppet>) -> Bool {
  return CBTagEngagedNear(sys, game, des, player, n"CB_Rival")
      || CBTagEngagedNear(sys, game, des, player, n"CB_Apex")
      || CBTagEngagedNear(sys, game, des, player, n"CB_Squad")
      || CBTagEngagedNear(sys, game, des, player, n"CB_Escort")
      || CBTagEngagedNear(sys, game, des, player, n"CB_Scout");
}

func CBTagEngagedNear(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                      player: ref<PlayerPuppet>, tag: CName) -> Bool {
  let ppos = player.GetWorldPosition();
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      // Close only counts for somebody who can get here. Somebody stuck under V's feet was close
      // for ever, which held every release in the mod off for the whole of a fight nobody could
      // finish, themselves included.
      let close = Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.CombatReleaseDistance()
                  && p.cbCutOffTicks < CBConfig.CutOffQuietTicks();
      if close || CBWitnessCanSee(p, player) {
        return true;
      }
    }
  }
  return false;
}

func CBReleaseTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                  player: ref<PlayerPuppet>, tag: CName, engaged: Bool) -> Void {
  let ppos = player.GetWorldPosition();
  let crewSeated = CBAnyCrewSeated(game, des);
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      let away = Vector4.Distance(p.GetWorldPosition(), ppos);
      let far = away > CBConfig.CombatReleaseDistance();
      // Somebody getting closer is on their way back into the fight, not stuck out of it. Without
      // this, running forty-five metres was enough to have hunters deleted while they chased: the
      // clock was already nearly full, and they went a second after losing sight of V.
      let closing = p.cbReleaseAway > 0.0 && away < p.cbReleaseAway - CBConfig.CombatReleaseClosing();
      p.cbReleaseAway = away;
      if !engaged && !closing && CBNpcInCombat(p) && far && !CBWitnessCanSee(p, player) && CBOutOfView(game, p.GetWorldPosition()) {
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

// ---- Cut off ------------------------------------------------------------------------------------
//
// Somebody of ours who cannot get to V and whom V cannot get to. Placement is held to a high standard
// (CBPointArrivable), but it can only speak for the moment it happens: V moves, a door is locked, a car
// stops somewhere bad, a body lands in something. And the combat release could not help, because it
// only looked past 45 m, and "cannot be killed" is exactly somebody below or behind V, close by.
//
// So this asks about the person rather than about how they got there. Nobody who can see V, or
// whom V can see, is ever counted. Everybody else is counted if they are not getting anywhere: still
// in one small patch of ground, or moving around with no route to V from where they are. Counted
// long enough, they are taken out, out of V's sight, through the same removal as everybody else.
// The route is the costly question, so it is asked only of somebody who has moved, a few a pass.

@addField(ScriptedPuppet)
public let cbCutOffTicks: Int32;

@addField(ScriptedPuppet)
public let cbCutOffAnchor: Vector4;

@addField(ScriptedPuppet)
public let cbCutOffAnchored: Bool;

public func CBCutOffTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(des) || !des.IsPopulated(n"Cyberbane")
     || !CBWorldStable(game) {
    return;
  }
  // Waiting outside V's door because they were told to is not being stuck.
  if sys.IsInSanctuary() {
    return;
  }
  let budget = CBConfig.CutOffPathsPerPass();
  budget = CBCutOffTag(sys, game, des, player, n"CB_Rival", budget);
  budget = CBCutOffTag(sys, game, des, player, n"CB_Apex", budget);
  budget = CBCutOffTag(sys, game, des, player, n"CB_Squad", budget);
  budget = CBCutOffTag(sys, game, des, player, n"CB_Escort", budget);
  CBCutOffTag(sys, game, des, player, n"CB_Scout", budget);
}

func CBCutOffTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                 player: ref<PlayerPuppet>, tag: CName, budget: Int32) -> Int32 {
  let left = budget;
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      left = CBCutOffOne(sys, game, des, player, p, tag, left);
    }
  }
  return left;
}

func CBCutOffOne(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                 player: ref<PlayerPuppet>, p: ref<ScriptedPuppet>, tag: CName, budget: Int32) -> Int32 {
  let id = p.GetEntityID();
  let at = p.GetWorldPosition();
  // In a seat is the car's business (CBArrivalDismountCallback). Seeing V or seen by V is a fight.
  if VehicleComponent.IsMountedToVehicle(game, id) || CBWitnessCanSee(p, player)
     || !CBOutOfView(game, at) {
    p.cbCutOffTicks = 0;
    p.cbCutOffAnchored = false;
    return budget;
  }
  // Left behind is the chase's to judge, and it has a say this does not: a Rival V really has shaken
  // counts it as an escape (CBChaseGiveUp).
  if Vector4.Distance(at, player.GetWorldPosition()) > CBConfig.ChaseLoseDistance() {
    p.cbCutOffTicks = 0;
    p.cbCutOffAnchored = false;
    return budget;
  }
  let left = budget;
  if !p.cbCutOffAnchored || Vector4.Distance(at, p.cbCutOffAnchor) > CBConfig.CutOffRoam() {
    p.cbCutOffAnchor = at;
    p.cbCutOffAnchored = true;
    if left <= 0 {
      return left;   // nobody left to ask about this pass; nothing learned either way
    }
    left -= 1;
    if CBPointReachable(game, at, player.GetWorldPosition()) {
      p.cbCutOffTicks = 0;
      return left;
    }
  }
  p.cbCutOffTicks += CBConfig.CutOffPassTicks();
  if p.cbCutOffTicks >= CBConfig.CutOffTicks() {
    CBLog.Info(n"Spawn", "One of ours could not get to you and you could not get to them; taking them out.");
    // A Rival's encounter ends with them. They come back, and it does not count as an escape: V
    // did nothing to shake them.
    if Equals(tag, n"CB_Rival") {
      let r = CBFindRivalByBody(sys, id);
      if IsDefined(r) {
        CBCloseRivalEncounter(sys, game, r, p);
      }
    }
    CBRemoveOne(game, des, id, false, true);
  }
  return left;
}

@addField(ScriptedPuppet)
public let cbOutOfFightTicks: Int32;

// How far off they were last pass, to tell somebody coming back from somebody stuck.
@addField(ScriptedPuppet)
public let cbReleaseAway: Float;
