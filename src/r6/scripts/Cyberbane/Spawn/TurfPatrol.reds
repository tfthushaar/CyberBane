// Cyberbane - The new owners, out on their streets (experimental, off by default)
//
// The gangs on the street are placed by the game's world data and a script cannot swap them, so a
// gang that has taken a district shows up alongside the old one, which reads as streets in dispute.
// A few of the holders, on foot, out of V's sight and walking the block while V is around.
//
// Built from what already exists: placement is CBSpawnGroup, orders go through CBIssueMove so nobody
// has more than one, and removal is CBDeleteTaggedSafe, never where V can see. They are not hunters,
// so nothing that counts hunters, sends crews or draws markers knows they are there.

public func CBTurfPatrolsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && rt.HasSettings()
      && rt.GetSettings().turfPatrols && rt.GetSettings().turfWars;
}

// Every few fast ticks.
public func CBTurfPatrolTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  let book = CBTurfBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(des) || !IsDefined(book) || !IsDefined(player) || !CBWorldStable(game) {
    return;
  }
  let out = CBLiveTaggedPresent(game, n"CB_Patrol");
  if !CBTurfPatrolsOn() {
    if out {
      CBDeleteTaggedSafe(game, n"CB_Patrol", true, true);
    }
    return;
  }
  let now = sys.GetTickCount();
  let here = sys.GetCurrentDistrict();
  let busy = sys.GetStoryHold() != CBStoryNone() || sys.IsInQuestArea() || sys.IsInSanctuary()
          || sys.IsInSafeZone() || CBStealthEncounterNearby(sys, game);
  if sys.IsInSanctuary() {
    CBSanctuaryHoldTag(sys, game, des, player, n"CB_Patrol");
  }
  if out {
    if busy || NotEquals(here, book.patrolDistrict)
       || (now - book.patrolTick) >= CBConfig.TurfPatrolLifeTicks()
       || CBHuntersOut(sys, game) || CBHuntPending(sys)
       || !CBPatrolNear(game, des, player.GetWorldPosition()) {
      CBDeleteTaggedSafe(game, n"CB_Patrol", true, true);
      CBLog.Info(n"Spawn", "A turf patrol has moved on.");
      return;
    }
    if (now - book.patrolTick) % CBConfig.TurfPatrolWalkTicks() == CBConfig.TurfPatrolFirstWalkTick() {
      CBPatrolWalk(sys, game, des, player);
    }
    return;
  }
  if busy || now < book.patrolNext || player.IsInCombat() || IsDefined(player.GetMountedVehicle())
     || CBPlayerIndoors(game) || CBHuntersOut(sys, game) || CBHuntPending(sys) {
    return;
  }
  let index = CBDistrictIndex(here);
  if index < 0 || Equals(book.From(index), n"") {
    return;   // only a district that has really changed hands has new people in it
  }
  let holder = book.Holder(index);
  let fs = sys.FindFaction(holder);
  if !IsDefined(fs) || !CBFactionFieldsSquads(holder) {
    return;
  }
  let record = TDBID.IsValid(fs.sampleRecord) ? fs.sampleRecord : CBApexRosterRecord(holder, 1);
  let size = RandRange(CBConfig.TurfPatrolMin(), CBConfig.TurfPatrolMax() + 1);
  // Somebody V has actually provoked always comes before scenery.
  if !TDBID.IsValid(record) || CBSpawnRoom(game) < size + CBConfig.TurfPatrolKeepRoom() {
    return;
  }
  book.patrolNext = now + CBJitter(CBConfig.TurfPatrolGapTicks(), CBConfig.QueueJitterFraction());
  let body: EntityID;
  if CBSpawnGroup(game, record, n"", size, n"CB_Patrol", CBConfig.TurfPatrolDistance(), body) > 0 {
    book.patrolDistrict = here;
    book.patrolTick = now;
    CBLog.Info(n"Spawn", s"\(NameToString(holder)) have a patrol out in \(NameToString(here)).");
  }
}

func CBPatrolNear(game: GameInstance, des: ref<DynamicEntitySystem>, ppos: Vector4) -> Bool {
  let ids = des.GetTaggedIDs(n"CB_Patrol");
  let i = 0;
  while i < ArraySize(ids) {
    if des.IsSpawning(ids[i]) {
      return true;
    }
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.TurfPatrolLeaveDistance() {
      return true;
    }
  }
  return false;
}

// Set up a moment after attaching, like everybody else of ours (CBApplySpawnSetup). What the street
// makes of V decides what they make of V: at war means hostile, anything else means they leave V be.
public func CBSetUpPatrol(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  let score = sys.GetScore();
  let faction = CBClassifyFaction(puppet);
  let posture = IsDefined(score) ? score.GetPosture(faction) : ECBPosture.Neutral;
  if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
    // The flag the game's own attitude change checks for; a ganger made from a crowd record has none.
    CBGrantAbility(puppet as NPCPuppet, t"Ability.IsAggressive");
    CBMakeHostileToPlayer(game, puppet);
    return;
  }
  let agent = puppet.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) {
    CBTrace("attitude: a turf patrol leaves V be");
    if !IsNameValid(agent.GetAttitudeGroup()) {
      let group = CBRecordAttitudeGroup(puppet.GetRecordID());
      if IsNameValid(group) {
        agent.SetAttitudeGroupUnsavable(group);
      }
    }
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
  }
}

// Somewhere on the block, at a walk. The same spot for the group, so it reads as a group.
func CBPatrolWalk(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>) -> Void {
  let ppos = player.GetWorldPosition();
  let pts: array<Vector4>;
  if !CBPursuitPoints(game, ppos, player.GetWorldForward(), CBConfig.TurfPatrolWalkCandidates(),
                      CBConfig.TurfPatrolWalkMin(), CBConfig.TurfPatrolWalkMax(), pts) {
    return;
  }
  let spot = pts[RandRange(0, ArraySize(pts))];
  // Rules 16 and 18: not into a safe area, and not onto somebody else's job.
  if CBPointIsSafeArea(game, spot) || sys.NearQuestPins(spot, CBConfig.QuestSpawnClearance()) {
    return;
  }
  let ids = des.GetTaggedIDs(n"CB_Patrol");
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) && !p.cbMoraleBroken && !CBNpcInCombat(p)
       && !VehicleComponent.IsMountedToVehicle(game, p.GetEntityID())
       && CBPointReachable(game, p.GetWorldPosition(), spot) {
      let ai = p.GetAIControllerComponent();
      if IsDefined(ai) {
        let cmd = new AIMoveToCommand();
        let dest: AIPositionSpec;
        let wp: WorldPosition;
        WorldPosition.SetVector4(wp, spot);
        AIPositionSpec.SetWorldPosition(dest, wp);
        cmd.movementTarget = dest;
        cmd.movementType = moveMovementType.Walk;
        cmd.ignoreInCombat = true;
        cmd.alwaysUseStealth = false;
        cmd.ignoreNavigation = false;
        cmd.finishWhenDestinationReached = true;
        cmd.desiredDistanceFromTarget = 2.0 + RandF() * 3.0;
        CBIssueMove(p, ai, cmd);
      }
    }
  }
}
