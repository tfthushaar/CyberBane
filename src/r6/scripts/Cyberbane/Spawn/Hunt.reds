// Cyberbane - Being hunted (spec §9.11)
//
// Hunters search from where V was last seen instead of being handed V's position, so V can get away.

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
  // Where V spends time, they know where to start (Spawn/Hunted.reds, [U8]).
  let rough = CBHuntTipNear(p);
  let near = Equals(faction, CBTrackerGang(game)) || CBBetrayerKnowsHaunts(sys, faction) ? CBConfig.TrackedTipMult()
                                                                                          : CBHauntTipMult(sys, game);
  let tip = new Vector4(p.X + (rough.X - p.X) * near, p.Y + (rough.Y - p.Y) * near, rough.Z, 1.0);
  // A lie V had the street carry (Reactions/Allies.reds, [69]): they start looking somewhere else entirely.
  if CBTakeLie(game, faction) {
    tip = new Vector4(p.X + (rough.X - p.X) * CBConfig.LieTipMult(), p.Y + (rough.Y - p.Y) * CBConfig.LieTipMult(), rough.Z, 1.0);
  }
  // A hunt already under way keeps what it knows; a new one starts from the tip.
  if sys.GetHuntState() == CBHuntNone() || !CBHuntersOut(sys, game) {
    sys.SetHuntState(CBHuntSearching());
    sys.SetHuntLkp(tip);
    sys.SetHuntLastSeenTick(sys.GetTickCount());
    sys.SetHuntSearchStartTick(sys.GetTickCount());
    // Nobody has laid eyes on V yet: they are working from a tip, and the tip firms up the
    // longer they ask around (CBHuntSearchCenter).
    sys.SetHuntFromTip(true);
    sys.SetHuntTipWord(CBHuntWordNear(p), sys.GetTickCount());
    CBHuntStartSearch(sys);
    // A new hunt: nobody has been picked off unseen yet, and other mods can hear it started.
    let huntBook = CBHuntBook.Get(game);
    if IsDefined(huntBook) {
      huntBook.darkKills = 0;
    }
    CBEmit(n"Cyberbane/HuntStarted", faction, 0.0);
  }
  sys.SetHuntFaction(faction);
}

// Word on where V is: somewhere within HuntTipError of this spot.
func CBHuntTipNear(p: Vector4) -> Vector4 {
  let err = CBConfig.HuntTipError();
  let ang = RandRangeF(0.0, 6.2831);
  return new Vector4(p.X + CosF(ang) * RandRangeF(err * 0.3, err), p.Y + SinF(ang) * RandRangeF(err * 0.3, err), p.Z, 1.0);
}

// The street's later word: closer than the first tip, but still a rumour. V's own spot here would walk every search
// onto V within a minute, seen or not.
func CBHuntWordNear(p: Vector4) -> Vector4 {
  let ang = RandRangeF(0.0, 6.2831);
  let d = RandRangeF(CBConfig.HuntWordErrorMin(), CBConfig.HuntWordErrorMax());
  return new Vector4(p.X + CosF(ang) * d, p.Y + SinF(ang) * d, p.Z, 1.0);
}

// Searching on word alone, a point this close to V would be V's position under another name.
func CBHuntTooCloseToV(sys: ref<CyberbaneSystem>, game: GameInstance, at: Vector4) -> Bool {
  if !sys.IsHuntFromTip() {
    return false;   // searching where they last saw V: going back there is fair
  }
  let player = GetPlayer(game);
  return IsDefined(player) && Vector4.Distance2D(at, player.GetWorldPosition()) < CBConfig.HuntKeepOffV();
}

// A search starts: how long they will give it, varied every time, and where V was when it began.
func CBHuntStartSearch(sys: ref<CyberbaneSystem>) -> Void {
  let j = CBConfig.HuntGiveUpJitter();
  let giveUp = Cast<Float>(CBConfig.HuntGiveUpTicks() + RandRange(-j, j + 1)) * sys.WornPerk().giveUpMult;
  sys.SetHuntGiveUpTicks(Max(30, RoundF(giveUp)));
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
  return NotEquals(sys.GetScoutFaction(), n"")
      || NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetPendingApexFaction(), n"")
      || sys.HasPendingArrival() || sys.HasConvoyLegs() || sys.GetRivalCarPending() > 0
      || NotEquals(sys.GetApexMusterFaction(), n"")
      || rivalComing || CBBountyComing(sys.GetGameInstance());
}

// Send one hunter where the hunt says they should go: at V while V is located, otherwise to a point near where V is
// thought to be.
public func CBOrderPursue(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || puppet.cbMoraleBroken || puppet.cbFacedownHeld {
    return;
  }
  // Nor anybody whose encounter is over (CB_Orphan): called off, let go, or kept back from a removal. The
  // car watch orders whoever came in a car by the car's own tag, which an orphan still wears.
  let des = GameInstance.GetDynamicEntitySystem();
  if IsDefined(des) && des.IsTagged(puppet.GetEntityID(), n"CB_Orphan") {
    return;
  }
  // Every order on foot comes through here. While V is safe there is nowhere to send anybody (Spawn/Sanctuary.reds),
  // and they are asked again once V is not. Nor onto a job, even once they have found V.
  if IsDefined(sys) && (sys.IsInSanctuary() || sys.IsOnJob() || CBHomeHolds(sys, sys.GetHuntFaction())) {
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
public func CBHuntPickSearchPoint(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>,
                                  out point: Vector4) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  let apex = IsDefined(des) && IsDefined(puppet) && des.IsTagged(puppet.GetEntityID(), n"CB_Apex");
  if apex {
    let since = sys.GetTickCount() - sys.GetApexSearchTick();
    if sys.GetApexSearchTick() > 0 && since >= 0 && since < CBConfig.ApexSearchShareTicks() {
      let shared = sys.GetApexSearchPoint();
      let near: Vector4;
      let spread = CBConfig.ApexSearchSpread();
      if CBHuntStandAt(game, shared.X + RandRangeF(-spread, spread), shared.Y + RandRangeF(-spread, spread), shared.Z, near)
         && !CBHuntTooCloseToV(sys, game, near) && CBPointReachable(game, puppet.GetWorldPosition(), near) {
        point = near;
        return true;
      }
    }
  }
  if !CBHuntPickOwnPoint(sys, game, puppet, point) {
    return false;
  }
  if apex {
    sys.SetApexSearch(point, Max(sys.GetTickCount(), 1));
  }
  return true;
}

func CBHuntPickOwnPoint(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>,
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
       && !CBHuntTooCloseToV(sys, game, at)
       && CBPointReachable(game, from, at) {
      point = at;
      return true;
    }
    tries += 1;
  }
  // The middle of the search itself. Orders are not given at all while V is on a job
  // (CBHuntTick), so this is never a walk into one.
  let mid: Vector4;
  if CBHuntStandAt(game, center.X, center.Y, center.Z, mid) && !CBHuntTooCloseToV(sys, game, mid)
     && CBPointReachable(game, from, mid) {
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
       && !CBHuntTooCloseToV(sys, game, step)
       && CBPointReachable(game, from, step) {
      point = step;
      return true;
    }
  }
  return false;
}

// A floor at this spot, near this height, with navmesh on it, and not inside anywhere the game protects.
func CBHuntStandAt(game: GameInstance, x: Float, y: Float, zHint: Float, out at: Vector4) -> Bool {
  let gz: Float;
  return CBGroundAt(game, x, y, zHint, gz) && AbsF(gz - zHint) <= CBConfig.HuntSearchMaxDrop()
      && CBStandOnNavmesh(game, x, y, gz, at) && !CBPointIsSafeArea(game, at);
}

// Get somewhere and look around. A position rather than V, and released when they get there or the moment combat
// starts. Nobody on a hunt walks: walking the last of every leg is what made a crew look like people out for a stroll.
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
        // Nobody of ours is in the world, but that is not the same as nobody being left.
        if !sys.CarRecentlyOnTheWay() && CBHuntersLeftBehind(sys, game, des) {
          // Every Rival of the encounter whose body has left the world, the one leading and anyone
          // who came with them (Spawn/RivalEncounter.reds).
          if !sys.IsLairActive() {
            CBRivalsShakenOff(sys, game, true);
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
        sys.SetHuntEnd(CBT(n"Cyberbane-Hunt-THREATENDED"), CBConfig.HuntEndLineTicks());
      }
    } else {
      sys.SetHuntIdleTicks(0);
      // Nobody has arrived yet, so nobody has started looking.
      if sys.GetHuntState() == CBHuntSearching() && sys.IsHuntFromTip() && !CBSlipBroken(game) {
        let waiting = sys.GetTickCount();
        let vAt = player.GetWorldPosition();
        sys.SetHuntLastSeenTick(waiting);
        sys.SetHuntSearchStartTick(waiting);
        sys.SetHuntLkp(CBHuntTipNear(vAt));
        sys.SetHuntTipWord(CBHuntWordNear(vAt), waiting);
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

  // Home ground (Spawn/HomeGround.reds) holds them the way a job does: nobody is sent looking, nobody is handed V, and
  // somebody already fighting V close by goes on fighting.
  let jobLike = sys.IsOnJob() || CBHomeHolds(sys, sys.GetHuntFaction());
  // V got somewhere safe: orders taken back, and nobody who has lost sight of V goes on after them.
  // First, so the question below is asked of people who have already stopped.
  if sys.IsInSanctuary() {
    CBSanctuaryHold(sys, game, des, player);
    if now % 30 == 0 {
      CBLog.Info(n"Spawn", "You are somewhere safe: they will not follow you in.");
    }
  } else {
    // On a job, the same. Search orders already stopped here, but only until somebody had found V: from then on they
    // chased V into the job, which is how a Valentino hunting V walked into a Maelstrom building in the middle of a
    // gig.
    if jobLike {
      CBSanctuaryHold(sys, game, des, player, true);
      if now % 30 == 0 {
        CBLog.Info(n"Spawn", sys.IsOnJob() ? "You are on a job: they hold back until you leave it."
                                           : "You are on home ground: they hold back until you leave it.");
      }
    }
  }

  // Can anybody see or hear V? 2 is certain (already fighting V, or heard it), 1 is a sighting.
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
      let how = contact >= 2 ? "fighting or heard you" : "saw you";
      CBHuntOnLocated(sys, game, s"\(how), nearest of ours \(RoundF(CBNearestHunterDistance(sys, game, des, ppos)))m");
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

  // Found: everybody of ours close enough is told where V is, and the fight is on.
  if sys.GetHuntState() == CBHuntLocated() && sys.GetStoryHold() == CBStoryNone() && !sys.IsInSanctuary()
     && !jobLike {
    CBHuntEngage(sys, game, des, ppos);
  }

  // The street's word on where V is, while they are still working from the tip. Refreshed only every so often, so it is
  // a rumour that firms up, not a fix (CBHuntSearchCenter).
  if sys.IsHuntFromTip() && now - sys.GetHuntTipWordTick() >= CBConfig.HuntTipWordTicks() && !CBSlipSlipped(game, sys.GetHuntFaction()) {
    sys.SetHuntTipWord(CBHuntWordNear(ppos), now);
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
    if sys.IsInSafeZone() || sys.IsInSanctuary() || sys.IsInQuestArea() || jobLike || leftArea {
      sys.SetHuntLastSeenTick(sys.GetHuntLastSeenTick() - 1);
    }
    let unseen = now - sys.GetHuntLastSeenTick();
    let nearest = CBNearestHunterDistance(sys, game, des, ppos);
    // A car on its way has not lost V: it is further off than the lose distance by design, and its crew count as
    // hunters from the moment they are seated.
    let carComing = sys.CarRecentlyOnTheWay() || sys.HasPendingArrival() || sys.HasConvoyLegs();
    if carComing {
      sys.SetChaseAwayTicks(0);
      sys.SetHuntLastSeenTick(now);
    }
    // Said in the log every half minute: a search that finds nobody looks exactly like a search
    // that is not happening, and only this can tell the two apart.
    if now % 30 == 0 {
      let carNote = carComing ? CBT(n"Cyberbane-Hunt-ACarOnItsWay") : "";
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
  // No search orders while V is on a job: they hold where they are rather than walk into it.
  if now % every == 0 && !(sys.IsInQuestArea() && sys.GetHuntState() != CBHuntLocated())
     && sys.GetStoryHold() == CBStoryNone() && !sys.IsInSanctuary() && !jobLike {
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
  if Equals(sys.GetScoutFaction(), n"") {
    CBHuntEngageTag(sys, game, des, ppos, n"CB_Scout");   // only once they have called it in
  }
}

func CBHuntEngageTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                     ppos: Vector4, tag: CName) -> Void {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    // The car watch lets them out. Nor anybody held for a facedown, or standing back from a fight one on one
    // (Rivals/RivalMoments.reds).
    if CBStillStanding(p) && CBNpcSafe(sys, p) && !p.cbMoraleBroken && !CBNpcInCombat(p) && !p.cbFacedownHeld
       && !p.cbFacedownWait   // nor anybody walking up calm for one
       && !p.cbTruceHeld      // nor anybody holding while V talks to one of theirs
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
    if CBStillStanding(puppet) && CBNpcSafe(sys, puppet) && !puppet.cbMoraleBroken && !puppet.cbTruceHeld
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

// How well hunters can find V right now, as a multiplier on how far they see and hear. Crouching, the dark, wearing the
// hunting gang's own colours and the game's harder difficulties all make V harder to find.
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
  // And the rain (Model/Moment.reds).
  scale *= CBRainSightMult(game);
  // V by the car they know, or with the gun (Model/StreetBook.reds): easier to pick out ([U8]).
  if IsDefined(sys) && CBVGivenAway(sys, game) > 0 {
    scale *= CBConfig.KnownSense();
  }
  // A gang that has learnt V works unseen keeps its eyes open (Model/Ledger.reds).
  if IsDefined(sys) {
    scale *= CBAdaptSense(game, sys.GetHuntFaction());
  }
  if IsDefined(sys) && NotEquals(sys.GetHuntFaction(), n"")
     && Equals(sys.GetDisguiseFaction(), sys.GetHuntFaction()) {
    scale *= CBConfig.DisguiseSenseMult();
  }
  // A crew that came in looking where V was, not where V is (Spawn/Slip.reds).
  if IsDefined(sys) && CBSlipSlipped(game, sys.GetHuntFaction()) {
    scale *= CBConfig.SlipSenseMult();
  }
  scale *= 1.0 - CBConfig.DifficultySenseStep() * Cast<Float>(CBDifficultyLevel());
  if IsDefined(sys) {
    scale *= sys.WornPerk().senseMult;
  }
  return MaxF(scale, 0.2);
}

// Does any hunter know where V is? 2 for certain, 1 for a sighting, 0 for nothing.
func CBHuntAnyoneSeesPlayer(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                            player: ref<PlayerPuppet>, ppos: Vector4) -> Int32 {
  // Noise: a kill carries a long way, and a hunter within earshot comes to look.
  let loud = sys.GetRecentKills() > 0;
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
  // A scout still looking reports through calling it in (CBScoutTick), never by finding V for the hunt.
  if best < 2 && Equals(sys.GetScoutFaction(), n"") {
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
      // Fighting V, and V in sight or close: they know exactly where V is.
      if CBNpcInCombat(p) && d <= CBConfig.HuntCombatKnowsDistance()
         && (d <= CBConfig.HuntSpotDistance() || CBWitnessCanSee(p, player)) {
        return 2;
      }
      // Heard it.
      if loud && d <= CBConfig.HuntHearDistance() * sense {
        return 2;
      }
      // An apex squad's netrunner reaches further, and tells the rest exactly where V is ([U4]).
      let role: ECBApexRole;
      if Equals(tag, n"CB_Apex") && CBApexSeatRole(p, role) && Equals(role, ECBApexRole.Netrunner)
         && d <= CBConfig.HuntSpotDistance() * sense * CBConfig.ApexNetrunnerReach() && CBWitnessCanSee(p, player) {
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

// A car has parked beside V with a crew that was sent to V.
public func CBHuntCrewPulledUp(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) || sys.IsInSanctuary() || sys.IsInQuestArea() || sys.IsOnJob()
     || CBHomeHolds(sys, sys.GetHuntFaction()) || sys.GetStoryHold() != CBStoryNone() {
    return;
  }
  let was = sys.GetHuntState();
  sys.SetHuntLkp(player.GetWorldPosition());
  sys.SetHuntLastSeenTick(sys.GetTickCount());
  sys.SetHuntState(CBHuntLocated());
  sys.SetHuntFromTip(false);
  sys.SetSpotTicks(0);
  if was != CBHuntLocated() {
    CBHuntOnLocated(sys, game, "their car pulled up beside you");
  }
}

// The moment they find V. A Rival says so, once per arrival: the text that used to arrive with
// them, when there was nothing to find.
func CBHuntOnLocated(sys: ref<CyberbaneSystem>, game: GameInstance, how: String) -> Void {
  CBLog.Info(n"Spawn", s"Hunters have found you: \(how).");
  let r = sys.FindRivalById(sys.GetActiveRivalId());
  if IsDefined(r) && sys.GetRivalSpottedTexted() != r.id && CBLiveRivalPresent(sys, game) {
    sys.SetRivalSpottedTexted(r.id);
    let content = CBContent(game);
    if IsDefined(content) {
      // What they remember of V goes with it (Rivals/RivalMoments.reds, [L4]).
      let remembers = CBRivalRemembers(game, r);
      CBPhoneSendUrgent(game, CBRivalDisplayName(content, r), CBRivalArrivalLine(r) + " " + (StrLen(remembers) > 0 ? remembers + " " : "")
                        + CBRivalCatchphrase(r), CBHudRed());
    }
    // And their people say who they are (Rivals/RivalLife.reds).
    CBRivalAnnounce(sys, game, r);
  }
}

// One word for how well known V is in a district.
public func CBDistrictRenownWord(sys: ref<CyberbaneSystem>, id: CName) -> String {
  if !IsDefined(sys) || Equals(id, n"") {
    return "";
  }
  let ds = sys.FindDistrict(id);
  let renown = IsDefined(ds) ? ds.renown : 0.0;
  if renown >= 75.0 {
    return CBT(n"Cyberbane-Hunt-ANAMEHERE");
  }
  if renown >= 40.0 {
    return CBT(n"Cyberbane-Hunt-KNOWNHERE");
  }
  if renown >= 15.0 {
    return CBT(n"Cyberbane-Hunt-TALKEDABOUTHERE");
  }
  return CBT(n"Cyberbane-Hunt-UNKNOWNHERE");
}

// Where V stands in the district they are standing in, for the HUD.
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
  // Open season, and a tracker (Spawn/HuntGrows.reds), while nobody is on V right now.
  if !CBHuntersOut(sys, game) && Equals(sys.GetHuntFaction(), n"") {
    let open = CBOpenSeasonGang(game);
    let war = CBWarBook.Get(game);
    if NotEquals(open, n"") && IsDefined(war) {
      let left = RoundF((war.OpenUntil() - CBGameSeconds(game)) / 3600.0);
      return CBTf(n"Cyberbane-Hunt-OPENSEASONHLEFT", [CBClip(CBBarFactionLabel(open), CBConfig.HudNameMaxChars()), s"\(Max(left, 1))"]);
    }
    let tracker = CBTrackerGang(game);
    if NotEquals(tracker, n"") {
      return CBTf(n"Cyberbane-Hunt-ATRACKERONYOU", [CBClip(CBBarFactionLabel(tracker), CBConfig.HudNameMaxChars())]);
    }
  }
  // A scout with eyes on V, calling it in (Spawn/Hunted.reds): the moment V can still stop it.
  if NotEquals(sys.GetScoutFaction(), n"") && sys.GetScoutSeenTicks() > 0 {
    let left = Max(1, CBConfig.ScoutCallTicks() - sys.GetScoutSeenTicks());
    return CBTf(n"Cyberbane-Hunt-ASCOUTHASSEENYOUCALLING", [StrUpper(CBTimeText(left))]);
  }
  // A witness on their way to a gang (Reactions/Witnesses.reds), while nobody is hunting V yet.
  let witness = CBWitnessHudLine(sys, game);
  if StrLen(witness) > 0 && Equals(sys.GetHuntFaction(), n"") && !CBHuntersOut(sys, game) {
    return witness;
  }
  // A bounty hunter on the clock, or out after V, by their handle (Spawn/Bounty.reds).
  let hunterWho = CBClip(CBBountyHudWho(game), CBConfig.HudNameMaxChars());
  let hunterEta = CBBountyComingTicks(game);
  if StrLen(hunterWho) > 0 && hunterEta > 0 && !CBHuntersOut(sys, game) {
    return CBTf(n"Cyberbane-Hunt-APRICEONYOURHEADON", [hunterWho, StrUpper(CBTimeText(hunterEta))]);
  }
  // One short line, never more. Longest first is the name, so the name is what gets clipped.
  let who = CBClip(CBBarFactionLabel(sys.GetHuntFaction()), CBConfig.HudNameMaxChars());
  let head = StrLen(who) > 0 ? CBTf(n"Cyberbane-Hunt-HUNTED", [who]) : CBT(n"Cyberbane-Hunt-HUNTED-2");
  if StrLen(hunterWho) > 0 && CBLiveTaggedPresent(game, n"CB_Bounty") {
    head = CBTf(n"Cyberbane-Hunt-HUNTED", [hunterWho]);
  }
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
      let named = StrLen(who) > 0 ? who : CBT(n"Cyberbane-Hunt-SOMEBODY");
      let what = StrLen(grade) > 0 ? named + " " + grade : named;
      return CBTf(n"Cyberbane-Hunt-HUNTEDONTHEIRWAY", [what, StrUpper(CBTimeText(eta))]);
    }
    if huntsOnly {
      return "";   // only while somebody is on their way or out looking
    }
    // Nobody on the way yet, but somebody is asking around about V.
    let tracker = CBTrackedBy(sys);
    if StrLen(tracker) > 0 {
      return CBTf(n"Cyberbane-Hunt-TRACKED", [CBClip(tracker, CBConfig.HudNameMaxChars())]);
    }
    // How the last hunt ended, for a few seconds.
    return sys.GetHuntEndLine();
  }
  if sys.GetHuntState() == CBHuntLocated() {
    return CBTf(n"Cyberbane-Hunt-THEYHAVEYOU", [head]);
  }
  if sys.GetSpotTicks() > 0 {
    return CBTf(n"Cyberbane-Hunt-SPOTTED", [head]);
  }
  let unseen = sys.GetTickCount() - sys.GetHuntLastSeenTick();
  if unseen >= sys.GetHuntGiveUpTicks() * 2 / 3 {
    return CBTf(n"Cyberbane-Hunt-LOSINGYOURTRAIL", [head]);
  }
  return CBTf(n"Cyberbane-Hunt-SEARCHINGFORYOU", [head]);
}

// Who is asking around about V right now: a crew or apex squad queued and not yet warned, or a
// Rival on the clock who has not yet said they are coming. Empty when nobody is.
func CBTrackedBy(sys: ref<CyberbaneSystem>) -> String {
  if CBArrivalsHeld(sys, sys.GetGameInstance()) {
    return "";   // nobody is counting down while V cannot be reached
  }
  let near = CBConfig.TrackedShowTicks();
  let apex = sys.GetLaneTarget(CBLaneApex());
  let apexTicks = sys.GetLaneTicks(CBLaneApex());
  // A lane waiting out everybody's rest is not counting down either (CBLaneRestLeft).
  let resting = CBRestTogether();
  if NotEquals(apex, n"") && apexTicks > 0 && apexTicks <= near && !(resting && CBLaneRestLeft(sys, CBLaneApex()) > 0) {
    return CBBarFactionLabel(apex);
  }
  let crew = sys.GetLaneTarget(CBLaneSquad());
  let crewTicks = sys.GetLaneTicks(CBLaneSquad());
  if NotEquals(crew, n"") && crewTicks > 0 && crewTicks <= near && !(resting && CBLaneRestLeft(sys, CBLaneSquad()) > 0) {
    return CBBarFactionLabel(crew);
  }
  if NotEquals(sys.GetScoutFaction(), n"") {
    return CBBarFactionLabel(sys.GetScoutFaction());
  }
  let rid = sys.GetLaneRivalId(CBLaneRival());
  let rivalTicks = sys.GetLaneTicks(CBLaneRival());
  if rid > 0 && sys.GetRivalWarned() != rid && rivalTicks > 0 && rivalTicks <= near
     && !(resting && CBLaneRestLeft(sys, CBLaneRival()) > 0) {
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
// A hunt should start because of something V did, not because a clock said so. Killing a hostile gang's people where
// somebody sees it provokes that gang: their next crew comes now rather than at the next slot on the day's timetable.
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

// A place name every caller puts after "in" or "to": "around here" there read "Heard you are in around here".
func CBHuntWhereLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let where = CBDistrictLabel(CBEventDistrict(sys, game));
  return StrLen(where) > 0 ? where : CBT(n"Cyberbane-GangVoice-NightCity");
}

// The gang tells V a crew is coming, and roughly how much they know.
public func CBCrewWarning(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  // One voice per arrival: V's own lookout first, a friendly gang next, the gang itself when nobody else tells V. All
  // three used to text about the same crew in the same second.
  let told = CBWatcherTipOff(sys, game, CBCapFirst(CBFactionLabel(faction))) || CBAllyTipOff(sys, game, faction);
  if CBToastsOn() && !told {
    let score = sys.GetScore();
    let vendetta = IsDefined(score) && Equals(score.GetPosture(faction), ECBPosture.Vendetta);
    let where = CBHuntWhereLine(sys, game);
    // On their own streets, somebody of theirs saw V there; anywhere else they heard about it.
    let turf = CBTurfGangsHere(sys);
    let onTheirTurf = ArrayContains(turf, faction);
    // How many, in their own words, from the same numbers the spawn uses - and who leads them.
    let fs = sys.FindFaction(faction);
    let coming = CBCrewComingLine(sys, game, fs);
    // In their own voice (Narrative/GangVoice.reds); the plain words when a gang has none.
    let own = CBGangCrewText(faction, where, coming, vendetta, onTheirTurf);
    // The Voodoo Boys come through the Net before anybody walks over (Data/GangCodes.reds).
    if Equals(faction, n"VoodooBoys") && CBGangCodesOn() {
      CBSystemNote(game, CBT(n"Cyberbane-Hunt-YourOpticsFlickerSomebodyIsTracing"), 4.0);
    }
    if StrLen(own) > 0 {
      CBPhoneDemandFromGang(game, faction, own);
    } else {
      if vendetta {
        CBPhoneDemandFromGang(game, faction, CBTf(n"Cyberbane-Hunt-EverybodyWeHaveIsComingFor", [s"\(where)", s"\(coming)"]));
      } else {
        if onTheirTurf {
          CBPhoneDemandFromGang(game, faction, CBTf(n"Cyberbane-Hunt-YouAreOnOurStreetsIn", [s"\(where)", s"\(coming)"]));
        } else {
          CBPhoneDemandFromGang(game, faction, CBTf(n"Cyberbane-Hunt-WeHearYouAreIn", [s"\(coming)", s"\(where)"]));
        }
      }
    }
  }
}

// The gang tells V its apex squad is on the road.
public func CBApexOnTheWay(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  let fs = sys.FindFaction(faction);
  // One voice per arrival (CBCrewWarning).
  let told = CBWatcherTipOff(sys, game, CBTf(n"Cyberbane-Hunt-FourOfSBest", [CBFactionLabel(faction)])) || CBAllyTipOff(sys, game, faction);
  if CBToastsOn() && IsDefined(fs) && !told {
    let name = CBApexName(CBContent(game), faction, fs.apexAtKills);
    // Their best remember how it went last time ([U4]).
    let beaten = CBApexTimesBeaten(sys, faction);
    let record = beaten == 1 ? CBT(n"Cyberbane-Hunt-YouBeatOurBestOnceThat") : (beaten > 1 ? CBTf(n"Cyberbane-Hunt-YouVeBeatenOurBestTimes", [s"\(beaten)"]) : "");
    CBPhoneDemandFromGang(game, faction, CBTf(n"Cyberbane-Hunt-AndThreeOfOursAreOn", [s"\(name)", s"\(CBHuntWhereLine(sys, game))", s"\(record)"]));
  }
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
  let line = CBLineOf([CBTf(n"Cyberbane-Hunt-HeardYouAreInIAm", [where]), CBTf(n"Cyberbane-Hunt-HeardYouAreIn2", [where]),
                        CBTf(n"Cyberbane-Hunt-HeardYouAreIn3", [CBCapFirst(where)])]);
  if r.killedV > 0 {
    line = CBTf(n"Cyberbane-Hunt-IPutYouDownOnceHeard", [s"\(where)"]);
  } else {
    if r.sparedByV > 0 {
      line = CBTf(n"Cyberbane-Hunt-YouLetMeLiveBadCall", [s"\(where)"]);
    } else {
      if r.escapes > 0 {
        line = CBTf(n"Cyberbane-Hunt-StillBreathingBothOfUsNot", [s"\(where)"]);
      }
    }
  }
  // One voice per arrival: V's lookout saw them first; the Rival's own text otherwise. Both came in the same second,
  // saying the same thing.
  if !CBWatcherTipOff(sys, game, CBRivalDisplayName(content, r)) {
    CBPhoneSendUrgent(game, CBRivalDisplayName(content, r), line, CBHudRed());   // on V now
  }
}

// ---- Scouts --------------------------------------------------------------------
//
// A gang that does not know where V is does not send six people to wander around. It sends one. The scout spawns out of
// sight, starts from the same rough tip any hunt starts from, and searches.

public func CBScoutsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().scouts;
}

// Send a scout instead of a crew, if this is a gang that would. True when one was sent.
public func CBTrySendScout(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Bool {
  if !IsDefined(sys) || !CBScoutsOn() || NotEquals(sys.GetScoutFaction(), n"") {
    return false;
  }
  // A gang with a tracker on V needs nobody to look (Spawn/HuntGrows.reds, [49]).
  if Equals(faction, CBTrackerGang(game)) {
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
  if CBSpawnGroup(game, CBScoutRecord(fs), n"", 1, n"CB_Scout", CBConfig.HitSquadMinSpawnDistance(), body) <= 0 {
    return false;   // could not be placed; the crew comes the usual way
  }
  sys.SetScout(faction, body);
  sys.SetHuntGrade(CBT(n"Cyberbane-Hunt-SCOUT"));
  if CBToastsOn() {
    let district = sys.GetCurrentDistrict();
    let line = CBT(n"Cyberbane-Hunt-SomebodyIsWalkingYourBlockAsking");
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
    // Out of the world again after they had appeared: V got far enough away that the game let them go, so they lost V.
    let des = GameInstance.GetDynamicEntitySystem();
    if sys.GetScoutInWorld() && !(IsDefined(des) && des.IsSpawning(sys.GetScoutId())) {
      CBScoutLostYou(sys, game, faction);
      return;
    }
    // Not in the world. Give a new spawn time to appear; after that the crew comes the usual way.
    if age >= CBConfig.ScoutSpawnGraceTicks() {
      sys.ClearScout();
      CBScoutCallIn(sys, game, faction, false);
    }
    return;
  }
  sys.SetScoutInWorld();
  // Down, not merely on their way out of the world: one streaming out was counted as put down, and the gang went quiet
  // over a scout nobody had touched.
  if CBIsDown(scout) {
    CBScoutSilenced(sys, game, faction);
    CBLog.Info(n"Spawn", s"The \(NameToString(faction)) scout went down before calling it in.");
    return;
  }
  if !CBNpcSafe(sys, scout) {
    return;
  }
  // Eyes on V: in a fight with V, or close with nothing in the way.
  let d = Vector4.Distance(scout.GetWorldPosition(), player.GetWorldPosition());
  let sees = CBNpcInCombat(scout) && d <= CBConfig.HuntCombatKnowsDistance()
          || d <= CBConfig.HuntSpotDistance() * CBHuntSenseScale(sys, game) * CBScoutReach(faction) && CBWitnessCanSee(scout, player);
  if !sees {
    sys.SetScoutSeenTicks(0);
    return;
  }
  // V walking up to talk, or talking, to the scout (the bribe, [68]) holds the call: it went in six seconds after the
  // scout saw V, whatever V was saying to them.
  if CBTalkEngaged(sys, scout) {
    return;
  }
  sys.SetScoutSeenTicks(sys.GetScoutSeenTicks() + 1);
  if sys.GetScoutSeenTicks() >= CBConfig.ScoutCallTicks() {
    let scoutId = sys.GetScoutId();
    sys.ClearScout();
    CBScoutDraws(game, scoutId);   // called in: now they fight (Spawn/Hunted.reds)
    sys.SetHuntLkp(player.GetWorldPosition());
    sys.SetHuntLastSeenTick(sys.GetTickCount());
    CBScoutCallIn(sys, game, faction, true);
  }
}

// The scout is out of it before they could call it in: put down, or gave up (Spawn/LivingStreet.reds). The
// crew never hears, and the gang cools off.
func CBScoutSilenced(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  sys.ClearScout();
  let fs = sys.FindFaction(faction);
  if IsDefined(fs) {
    fs.lastHitSquadAt = CBGameSeconds(game);
  }
  if CBToastsOn() {
    let lost = CBGangScoutLostLine(faction);
    CBHearsayFromGangFinal(game, faction, StrLen(lost) > 0 ? lost : CBT(n"Cyberbane-Hunt-OurGuyStoppedAnsweringWeWill"), n"");
  }
}

// The scout lost V before they could call it in: V left them behind. As for a silenced scout, the crew never hears and
// the gang cools off, but said as what happened: nobody touched this one.
func CBScoutLostYou(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  sys.ClearScout();
  CBDeleteTaggedSafe(game, n"CB_Scout", false, true);
  let fs = sys.FindFaction(faction);
  if IsDefined(fs) {
    fs.lastHitSquadAt = CBGameSeconds(game);
  }
  if CBToastsOn() {
    CBHearsayFromGangFinal(game, faction, CBLineOf([CBT(n"Cyberbane-Hunt-OurScoutLostYouYouWon"),
                                                    CBT(n"Cyberbane-Hunt-OurEyesLostYouInThe")]), n"");
  }
  CBLog.Info(n"Spawn", s"V left the \(NameToString(faction)) scout behind before they could call it in.");
}

// The crew sets off: because the scout found V, or because no scout could be placed.
func CBScoutCallIn(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, spotted: Bool) -> Void {
  if NotEquals(sys.GetPendingSquadFaction(), n"") {
    return;
  }
  sys.SetPendingSquad(faction, CBArrivalTicks(sys, game, faction, CBConfig.CrewWarningTicks()));
  sys.SetHuntGrade(CBCrewGrade(sys, faction));
  if spotted && CBToastsOn() {
    let fs = sys.FindFaction(faction);
    // One voice per arrival (CBCrewWarning).
    if !CBWatcherTipOff(sys, game, CBCapFirst(CBFactionLabel(faction))) && !CBAllyTipOff(sys, game, faction) {
      CBPhoneDemandFromGang(game, faction, CBTf(n"Cyberbane-Hunt-OurScoutHasEyesOnYou", [s"\(CBCrewComingLine(sys, game, fs))"]));
    }
    CBLog.Info(n"Spawn", s"The \(NameToString(faction)) scout found you and called in the crew.");
    CBVoiceNearest(sys, game, n"CB_Scout", 60.0, n"stlh_call", n"ScoutCalls", 30.0);   // heard calling it in
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
// The game keeps V in combat for as long as any NPC is in combat with V.
public func CBCombatReleaseTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(des) || !player.IsInCombat() || !CBWorldStable(game) {
    return;
  }
  // Only once the fight near V is over.
  let engaged = CBOursEngagedNear(sys, game, des, player);
  CBReleaseTag(sys, game, des, player, n"CB_Rival", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Apex", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Squad", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Escort", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Scout", engaged);
  CBReleaseTag(sys, game, des, player, n"CB_Patrol", engaged);
  // The street's own people hold V in combat the same way once V has fought them and left. Only the ones fighting V:
  // the two sides of a sit-down can be fighting each other, which holds nobody in combat but themselves.
  for tag in CBStreetTags() {
    CBReleaseTag(sys, game, des, player, tag, engaged, true);
  }
  // Anyone handed to the orphan sweep because they were still in view when their encounter ended is still alive and may
  // still be in combat with V, and the sweep only runs on the slow tick.
  CBReleaseTag(sys, game, des, player, n"CB_Orphan", false);
}

// The street's own people (Spawn/LivingStreet.reds): a bagman and their lookout, a favour's lookout, the people at a
// sit-down. The downed sweep leaves them to whatever they belong to, which clears them when it ends.
public func CBStreetTags() -> array<CName> {
  return [n"CB_Bagman", n"CB_Favour", n"CB_Meet", n"CB_Wannabe", n"CB_Event", n"CB_Ambush", n"CB_Hangout", n"CB_Debtor", n"CB_Witness", n"CB_Api", n"CB_Convoy", n"CB_Mark"];
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
                  player: ref<PlayerPuppet>, tag: CName, engaged: Bool, opt againstVOnly: Bool) -> Void {
  let ppos = player.GetWorldPosition();
  let pagent = player.GetAttitudeAgent();
  let crewSeated = CBAnyCrewSeated(game, des);
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      let away = Vector4.Distance(p.GetWorldPosition(), ppos);
      let far = away > CBConfig.CombatReleaseDistance();
      // Somebody getting closer is on their way back into the fight, not stuck out of it.
      let closing = p.cbReleaseAway > 0.0 && away < p.cbReleaseAway - CBConfig.CombatReleaseClosing();
      p.cbReleaseAway = away;
      let againstV = !againstVOnly || (IsDefined(pagent) && IsDefined(p.GetAttitudeAgent())
                     && Equals(p.GetAttitudeAgent().GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile));
      if !engaged && !closing && againstV && CBNpcInCombat(p) && far && !CBWitnessCanSee(p, player) && CBOutOfView(game, p.GetWorldPosition()) {
        p.cbOutOfFightTicks += 2;
        if p.cbOutOfFightTicks >= CBConfig.CombatReleaseTicks() {
          CBLog.Info(n"Spawn", "One of ours was keeping you in combat from too far away; letting them go.");
          // A Rival's encounter ends with them, as the cut-off ends it (CBCutOffOne): not an escape, V did nothing to
          // shake them.
          if Equals(tag, n"CB_Rival") {
            let r = CBFindRivalByBody(sys, p.GetEntityID());
            if IsDefined(r) {
              CBCloseRivalEncounter(sys, game, r, p);
            }
          }
          if !CBRemoveOne(game, des, p.GetEntityID(), crewSeated) {
            if des.IsTagged(p.GetEntityID(), tag) {
              des.UnassignTag(p.GetEntityID(), tag);
            }
            if !des.IsTagged(p.GetEntityID(), n"CB_Orphan") {
              des.AssignTag(p.GetEntityID(), n"CB_Orphan");
            }
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
// Somebody of ours who cannot get to V and whom V cannot get to.

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
  // Waiting outside V's door, V's job or V's home ground, because they were told to is not being stuck.
  if sys.IsInSanctuary() || sys.IsOnJob() || CBHomeHolds(sys, sys.GetHuntFaction()) {
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
      // Nothing learned either way, so nothing is remembered either.
      p.cbCutOffAnchored = false;
      return left;
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

// How many of this gang's apex squads V has beaten, from the History ([U4]). Counted from what is kept, so a very long
// playthrough may count only the recent ones.
public func CBApexTimesBeaten(sys: ref<CyberbaneSystem>, faction: CName) -> Int32 {
  if !IsDefined(sys) || Equals(faction, n"") {
    return 0;
  }
  let n = 0;
  for e in sys.GetLog() {
    if IsDefined(e) && Equals(e.kind, n"ApexBeaten") && Equals(e.faction, faction) {
      n += 1;
    }
  }
  return n;
}
