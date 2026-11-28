// Cyberbane - Dynamic spawning (spec §9.9, §10; spike S-08)
//
// A thin wrapper over DynamicEntitySystem to drop tagged, non-persistent NPCs into the world near V. Spawn points are
// computed behind V and out of the forward view, and each one is put on the floor that is actually under it (see
// CBGroundAt).

// Find the floor under a candidate spawn point.
func CBGroundAt(game: GameInstance, x: Float, y: Float, zHint: Float, out ground: Float) -> Bool {
  return CBGroundRay(game, x, y, zHint + CBConfig.GroundProbeUp(), zHint - CBConfig.GroundProbeDown(), ground);
}

// The floor under a point that is already known to be standing room - a navmesh point.
func CBFloorUnder(game: GameInstance, p: Vector4, out ground: Float) -> Bool {
  return CBGroundRay(game, p.X, p.Y, p.Z + CBConfig.NavFloorProbeUp(), p.Z - CBConfig.GroundProbeDown(), ground);
}

func CBGroundRay(game: GameInstance, x: Float, y: Float, fromZ: Float, toZ: Float, out ground: Float) -> Bool {
  let sqs = GameInstance.GetSpatialQueriesSystem(game);
  if !IsDefined(sqs) {
    return false;
  }
  let from = new Vector4(x, y, fromZ, 1.0);
  let to = new Vector4(x, y, toZ, 1.0);
  let res: TraceResult;
  let hit = sqs.SyncRaycastByCollisionGroup(from, to, n"Static", res);
  if !hit {
    // Open ground outside a building is terrain, not static geometry.
    hit = sqs.SyncRaycastByCollisionGroup(from, to, n"Terrain", res);
  }
  if !hit {
    return false;
  }
  // A floor, not a wall face, a railing or the underside of a ramp: it has to point mostly up.
  if res.normal.Z < CBConfig.GroundMinNormalZ() {
    return false;
  }
  ground = res.position.Z;
  return true;
}

// Can a person actually walk from here to V?
func CBPointReachable(game: GameInstance, from: Vector4, to: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) {
    return true;   // cannot tell; do not silently refuse every spawn in the game
  }
  let path = nav.CalculatePathOnlyHumanNavmesh(from, to, NavGenAgentSize.Human, CBConfig.PathEndTolerance());
  if !IsDefined(path) {
    return false;
  }
  // A route has to be a real one, as well as existing.
  let walk = path.CalculateLength();
  return walk > 0.0
      && walk <= Vector4.Distance(from, to) * CBConfig.PathDetourMax() + CBConfig.PathDetourSlack();
}

// Does somebody put here stand with the spot they belong to? On its level, within `rise` metres, and joined to it by a
// real walk.
public func CBStandsWith(game: GameInstance, at: Vector4, anchor: Vector4, rise: Float) -> Bool {
  if AbsF(at.Z - anchor.Z) > rise {
    return false;
  }
  let onMesh: Vector4;
  if CBNavPointUnder(game, anchor, onMesh) {
    return CBWalkJoins(game, at, onMesh);
  }
  return CBPointReachable(game, at, anchor);
}

// The navmesh right under a point, where a person standing on it would be: within WalkJoinTolerance across and
// NavFloorSnapHeight down. False where there is none that close.
public func CBNavPointUnder(game: GameInstance, p: Vector4, out onMesh: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) {
    return false;
  }
  let found = nav.GetNearestNavmeshPointBelowOnlyHumanNavmesh(new Vector4(p.X, p.Y, p.Z + 1.0, 1.0), 0.5, 6);
  if Vector4.Length(found) < 1.0 {
    return false;
  }
  let dx = found.X - p.X;
  let dy = found.Y - p.Y;
  if SqrtF(dx * dx + dy * dy) > CBConfig.WalkJoinTolerance() || AbsF(found.Z - p.Z) > CBConfig.NavFloorSnapHeight() {
    return false;
  }
  onMesh = found;
  return true;
}

// A short walk on the navmesh between two near points, each end found on the navmesh within WalkJoinTolerance of where
// it is and never further.
public func CBWalkJoins(game: GameInstance, from: Vector4, to: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) {
    return true;   // cannot tell; do not silently refuse every spot
  }
  let straight = Vector4.Distance(from, to);
  if straight <= 0.5 {
    return true;   // the spot itself
  }
  let path = nav.CalculatePathOnlyHumanNavmesh(from, to, NavGenAgentSize.Human, CBConfig.WalkJoinTolerance());
  if !IsDefined(path) {
    return false;
  }
  let walk = path.CalculateLength();
  return walk > 0.0 && walk <= straight * CBConfig.PathDetourMax() + CBConfig.WalkJoinSlack();
}

// Is there a ceiling over this point?
public func CBPointCovered(game: GameInstance, at: Vector4) -> Bool {
  let sqs = GameInstance.GetSpatialQueriesSystem(game);
  if !IsDefined(sqs) {
    return false;
  }
  let s = CBConfig.CeilingRaySpread();
  let dx: array<Float>;
  let dy: array<Float>;
  ArrayPush(dx, 0.0);
  ArrayPush(dy, 0.0);
  ArrayPush(dx, s);
  ArrayPush(dy, 0.0);
  ArrayPush(dx, -s);
  ArrayPush(dy, 0.0);
  ArrayPush(dx, 0.0);
  ArrayPush(dy, s);
  ArrayPush(dx, 0.0);
  ArrayPush(dy, -s);
  let hits = 0;
  let i = 0;
  while i < ArraySize(dx) {
    let low = new Vector4(at.X + dx[i], at.Y + dy[i], at.Z + CBConfig.CeilingRayStart(), 1.0);
    let high = new Vector4(at.X + dx[i], at.Y + dy[i], at.Z + CBConfig.CeilingRayEnd(), 1.0);
    let res: TraceResult;
    if sqs.SyncRaycastByCollisionGroup(low, high, n"Static", res)
       || sqs.SyncRaycastByCollisionGroup(low, high, n"Terrain", res) {
      hits += 1;
    }
    i += 1;
  }
  return hits >= CBConfig.CeilingRaysNeeded();
}

// Does this arrival have to come from under the open sky? When V is, yes. V indoors, or under a
// roof of some other kind, and the people coming are under one too.
func CBArrivalOpenAir(game: GameInstance, ppos: Vector4) -> Bool {
  return !CBPlayerIndoors(game) && !CBPointCovered(game, ppos);
}

// May somebody be put here? Every body of every group, on every placement route, comes through this.
func CBPointArrivable(game: GameInstance, at: Vector4, used: array<Vector4>, ppos: Vector4,
                      openAir: Bool) -> Bool {
  if openAir && CBPointCovered(game, at) {
    return false;
  }
  if ArraySize(used) == 0 {
    return CBPointReachable(game, at, ppos);
  }
  return CBPointReachable(game, at, used[0]);
}

// Has somebody already been put here?
func CBPointOutOfSight(game: GameInstance, ppos: Vector4, fwd: Vector4, at: Vector4) -> Bool {
  let toPoint = new Vector4(at.X - ppos.X, at.Y - ppos.Y, 0.0, 0.0);
  let dist = Vector4.Length(toPoint);
  if dist < 0.5 {
    return false;   // on top of the player
  }
  let flatLen = SqrtF(fwd.X * fwd.X + fwd.Y * fwd.Y);
  if flatLen <= 0.01 {
    // No usable facing, so this test has no opinion.
    return true;
  }
  let facing = (fwd.X * toPoint.X + fwd.Y * toPoint.Y) / (flatLen * dist);
  if facing <= CBConfig.SpawnMaxFacingCosine() {
    return true;    // behind V, or far enough round the side not to be in frame
  }
  if dist >= CBConfig.SpawnInViewFarDistance() {
    return true;    // in front, but far enough that walking into frame is all anybody sees
  }
  // In front and close. Only allowed if something solid is between it and the player.
  let sqs = GameInstance.GetSpatialQueriesSystem(game);
  if !IsDefined(sqs) {
    return true;    // same reasoning as above: no opinion is not a refusal
  }
  let eye = new Vector4(ppos.X, ppos.Y, ppos.Z + CBConfig.SpawnEyeHeight(), 1.0);
  let head = new Vector4(at.X, at.Y, at.Z + CBConfig.SpawnEyeHeight(), 1.0);
  let res: TraceResult;
  return sqs.SyncRaycastByCollisionGroup(eye, head, n"Static", res);
}

// Could V see a body standing here, whichever way V turns in the next few seconds?
public func CBPointHiddenFrom(game: GameInstance, ppos: Vector4, fwd: Vector4, at: Vector4) -> Bool {
  let sqs = GameInstance.GetSpatialQueriesSystem(game);
  if !IsDefined(sqs) {
    return CBPointOutOfSight(game, ppos, fwd, at);
  }
  let eye = new Vector4(ppos.X, ppos.Y, ppos.Z + CBConfig.SpawnEyeHeight(), 1.0);
  let heights: array<Float>;
  ArrayPush(heights, CBConfig.HiddenRayLow());
  ArrayPush(heights, CBConfig.HiddenRayMid());
  ArrayPush(heights, CBConfig.HiddenRayHigh());
  let blocked = true;
  let i = 0;
  while i < ArraySize(heights) && blocked {
    let part = new Vector4(at.X, at.Y, at.Z + heights[i], 1.0);
    let res: TraceResult;
    blocked = sqs.SyncRaycastByCollisionGroup(eye, part, n"Static", res);
    i += 1;
  }
  if blocked {
    return true;
  }
  // In plain view of V's position. Only the far allowance is left: out of frame, and far.
  let toPoint = new Vector4(at.X - ppos.X, at.Y - ppos.Y, 0.0, 0.0);
  let dist = Vector4.Length(toPoint);
  let flatLen = SqrtF(fwd.X * fwd.X + fwd.Y * fwd.Y);
  if dist < CBConfig.SpawnInViewFarDistance() || flatLen <= 0.01 {
    return false;
  }
  let facing = (fwd.X * toPoint.X + fwd.Y * toPoint.Y) / (flatLen * dist);
  return facing <= CBConfig.SpawnMaxFacingCosine();
}

// Free of anybody this group has put down, and of anybody any other group put down in the last few seconds.
func CBPointIsFree(used: array<Vector4>, p: Vector4) -> Bool {
  let i = 0;
  while i < ArraySize(used) {
    if Vector4.Distance(used[i], p) < CBConfig.SpawnMinSeparation() {
      return false;
    }
    i += 1;
  }
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.SpawnPointTaken(p, CBSimNow(GetGameInstance()), CBConfig.SpawnMinSeparation());
}

// The engine's own clock in seconds, which runs on through menus and starts again with a session.
public func CBSimNow(game: GameInstance) -> Float {
  let ts = GameInstance.GetTimeSystem(game);
  return IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
}

// The nearest anybody sent from `dist` may be put down. A wall between them and V is not distance: the engine holds a
// spawn while its spot is in front of the camera, and V can walk most of the way to it in that time.
public func CBArrivalMinAway(dist: Float) -> Float {
  return MaxF(CBConfig.SpawnMinDistance(), dist * CBConfig.SpawnNearestShare());
}

// May somebody arriving be put here, as far as V's eyes go? `minAway` is CBArrivalMinAway of the distance they were sent
// from.
func CBArrivalUnseen(game: GameInstance, ppos: Vector4, fwd: Vector4, at: Vector4, side: Bool, inSightOk: Bool,
                     minAway: Float) -> Bool {
  if inSightOk {
    return true;
  }
  if side {
    return CBPointOutOfSight(game, ppos, fwd, at);
  }
  if Vector4.Distance(ppos, at) < minAway {
    return false;
  }
  return CBPointHiddenFrom(game, ppos, fwd, at);
}

// Stand a candidate navmesh point on the floor under it, or refuse it.
func CBSettleOnGround(game: GameInstance, p: Vector4, out at: Vector4) -> Bool {
  let ground = 0.0;
  if !CBFloorUnder(game, p, ground) {
    return false;
  }
  // A floor a long way below the point is not this point's floor.
  if p.Z - ground > CBConfig.SpawnGroundSettle() {
    return false;
  }
  // Nor one above it: the ray from just over the point hit something standing on the floor, a couch or a bench, and a
  // person put there stood on the seat.
  if ground - p.Z > CBConfig.SpawnFurnitureRise() {
    return false;
  }
  at = new Vector4(p.X, p.Y, MaxF(p.Z, ground) + CBConfig.NavSpawnClearance(), 1.0);
  return true;
}

// Put a point found by raycast alone onto the navmesh under it, or refuse it.
func CBStandOnNavmesh(game: GameInstance, x: Float, y: Float, groundZ: Float, out at: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) {
    at = new Vector4(x, y, groundZ + CBConfig.GroundSpawnLift(), 1.0);
    return true;
  }
  let cand = new Vector4(x, y, groundZ + CBConfig.NavFloorProbeUp(), 1.0);
  let snapped = nav.GetNearestNavmeshPointBelowOnlyHumanNavmesh(cand, 0.5, 6);
  if Vector4.Length(snapped) < 1.0 {
    return false;   // no navmesh here
  }
  let dx = snapped.X - x;
  let dy = snapped.Y - y;
  if SqrtF(dx * dx + dy * dy) > CBConfig.NavFloorSnapRadius()
     || AbsF(snapped.Z - groundZ) > CBConfig.NavFloorSnapHeight() {
    return false;   // the nearest navmesh is somewhere else, not under this floor
  }
  at = new Vector4(snapped.X, snapped.Y, MaxF(snapped.Z, groundZ) + CBConfig.NavSpawnClearance(), 1.0);
  return true;
}

// Find a place behind V that somebody could actually have walked from.
func CBNavAnchor(game: GameInstance, dist: Float, out anchor: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  let player = GetPlayer(game);
  if !IsDefined(nav) || !IsDefined(player) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let fwd = player.GetWorldForward();
  let attempt = 0;
  while attempt < 2 {
    // Behind V first; if that corner has no navmesh, try the other side rather than give up.
    let sign = attempt == 0 ? -1.0 : 1.0;
    let seedGuess = new Vector4(ppos.X + sign * fwd.X * 2.0, ppos.Y + sign * fwd.Y * 2.0,
                                ppos.Z + 1.0, 1.0);
    let seed = nav.GetNearestNavmeshPointBelowOnlyHumanNavmesh(seedGuess, 0.5, 6);
    if Vector4.Length(seed) >= 1.0 {
      let found: Vector4;
      if nav.FindNavmeshPointAwayFromReferencePoint(seed, ppos, dist, NavGenAgentSize.Human,
                                                    found, 10.0, 60.0) {
        // The navmesh call honours the distance but not the direction, so the point can come back in front of V.
        let toPoint = new Vector4(found.X - ppos.X, found.Y - ppos.Y, 0.0, 0.0);
        let away = Vector4.Length(toPoint);
        let facing = 1.0;
        if away > 0.01 {
          let flatLen = SqrtF(fwd.X * fwd.X + fwd.Y * fwd.Y);
          if flatLen > 0.01 {
            facing = (fwd.X * toPoint.X + fwd.Y * toPoint.Y) / (flatLen * away);
          }
        }
        // The call moves the point `dist` from the seed and promises nothing about V, so the distance is checked here,
        // the way the game checks it after the same call.
        if facing <= CBConfig.SpawnMaxFacingCosine() && away >= CBArrivalMinAway(dist)
           && AbsF(found.Z - ppos.Z) <= CBConfig.GroundMaxDrop() {
          // A point they cannot walk from is a point they will stand on forever.
          if CBPointReachable(game, found, ppos) {
            anchor = found;
            return true;
          }
        }
      }
    }
    attempt += 1;
  }
  return false;
}

// Put one body on the navmesh near a candidate point.
func CBNavSnap(game: GameInstance, x: Float, y: Float, zHint: Float, out pos: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) {
    return false;
  }
  let cand = new Vector4(x, y, zHint + 1.0, 1.0);
  let snapped = nav.GetNearestNavmeshPointBelowOnlyHumanNavmesh(cand, 0.5, 6);
  if Vector4.Length(snapped) < 1.0 {
    return false;
  }
  if Vector4.Distance(snapped, cand) > CBConfig.NavSnapTolerance() {
    return false;
  }
  // And on the same level. The distance test above is a sphere, so a walkway one storey up sits
  // comfortably inside it; without a separate vertical limit the navmesh will happily hand back
  // a balcony over the street.
  if AbsF(snapped.Z - zHint) > CBConfig.GroundMaxDrop() {
    return false;
  }
  pos = snapped;
  return true;
}

// How far out to try, as a fraction of the requested distance.
func CBSpawnDistanceScale(attempt: Int32) -> Float {
  if attempt <= 0 {
    return 1.0;
  }
  if attempt == 1 {
    return 0.66;
  }
  return CBConfig.SpawnNearestShare();
}

// Queue one NPC. Split out so the placement loop stays readable.
func CBCreateSpawn(des: ref<DynamicEntitySystem>, record: TweakDBID, appearance: CName,
                   pos: Vector4, orient: Quaternion, squadTag: CName, out created: EntityID,
                   opt extraTag: CName) -> Bool {
  let spec = new DynamicEntitySpec();
  spec.recordID = record;
  spec.appearanceName = appearance;
  spec.position = pos;
  spec.orientation = orient;
  spec.persistState = false;
  spec.persistSpawn = false;
  spec.alwaysSpawned = false;
  spec.spawnInView = false;
  spec.active = true;
  let tags: array<CName>;
  ArrayPush(tags, n"Cyberbane");
  ArrayPush(tags, squadTag);
  // A second tag for the one thing a spawn cannot otherwise carry: which chair of an apex squad
  // this body is (CBApexRoleTag). Read back in CBApplySpawnSetup.
  if IsNameValid(extraTag) {
    ArrayPush(tags, extraTag);
  }
  spec.tags = tags;
  CBTrace("spawn: creating an NPC");
  created = des.CreateEntity(spec);
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && EntityID.IsDefined(created) {
    rt.lastSpawnAt = pos;
    rt.NoteSpawnPoint(pos, CBSimNow(GetGameInstance()));   // nobody else is put here for a few seconds (CBPointIsFree)
    let player = GetPlayer(GetGameInstance());
    if IsDefined(player) {
      rt.NotePlaced(created, Vector4.Distance(pos, player.GetWorldPosition()));
    }
  }
  return EntityID.IsDefined(created);
}

// Spawn `count` copies of `record` in a short row behind V.
public func CBNavmeshReady(game: GameInstance, at: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  return IsDefined(nav) && nav.IsNavmeshStreamedInLocation(at, CBConfig.NavReadyTolerance());
}

// Standing points round a place rather than round V, out of V's sight by the navmesh's own visibility: the same
// question the game asks for a pursuit, with the place as its origin.
public func CBPursuitPointsAround(game: GameInstance, ppos: Vector4, around: Vector4, count: Int32, minR: Float, maxR: Float,
                                  out pts: array<Vector4>) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) || count <= 0 {
    return false;
  }
  let results: array<Vector4>;
  let fallback: array<Vector4>;
  let away = new Vector4(around.X - ppos.X, around.Y - ppos.Y, 0.0, 0.0);
  let dir = Vector4.Length(away) > 0.1 ? Vector4.Normalize(away) : new Vector4(1.0, 0.0, 0.0, 0.0);
  nav.FindPursuitPointsRange(ppos, around, dir, minR, maxR, count, true, NavGenAgentSize.Human, results, fallback);
  pts = results;
  return ArraySize(pts) > 0;
}

public func CBPursuitPoints(game: GameInstance, ppos: Vector4, fwd: Vector4, count: Int32,
                            minR: Float, maxR: Float, out pts: array<Vector4>) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) {
    return false;
  }
  let results: array<Vector4>;
  let fallback: array<Vector4>;
  // Behind V, which is where an arrival should come from; the search spreads out from there.
  let dir = new Vector4(-fwd.X, -fwd.Y, 0.0, 0.0);
  nav.FindPursuitPointsRange(ppos, ppos, dir, minR, maxR, count, true,
                             NavGenAgentSize.Human, results, fallback);
  pts = results;
  // The strict pass can come back empty in tight streets and interiors. The fallback list is the game's second answer
  // rather than ours, so it is still a place the navmesh says a person fits.
  if ArraySize(pts) == 0 {
    pts = fallback;
  }
  return ArraySize(pts) > 0;
}

// Which way to look on this attempt, in radians from directly behind V.
func CBSpawnBearing(attempt: Int32) -> Float {
  if attempt <= 0 { return 0.0; }
  if attempt == 1 { return 0.52; }
  if attempt == 2 { return -0.52; }
  if attempt == 3 { return 1.05; }
  if attempt == 4 { return -1.05; }
  if attempt == 5 { return 1.57; }
  if attempt == 6 { return -1.57; }
  if attempt == 7 { return 2.36; }
  return -2.36;
}

// One person on V's side, brought to V: V's crew answering a call, one called out to spar, a gang's people lent to V.
public func CBSpawnOnSide(game: GameInstance, record: TweakDBID, appearance: CName, squadTag: CName, nearDist: Float,
                          out body: EntityID, out ring: Int32, opt extraTag: CName) -> Int32 {
  ring = 0;
  if !TDBID.IsValid(record) {
    return 0;
  }
  if CBSpawnGroup(game, record, appearance, 1, squadTag, nearDist, body, extraTag) > 0 {
    ring = 1;
    return 1;
  }
  // Nothing more to try when the reason is not the place: no room, the world busy, the story.
  if CBSpawnRoom(game) <= 0 || !CBWorldStable(game) || CBStoryHoldNow(game) {
    return 0;
  }
  if CBSpawnGroup(game, record, appearance, 1, squadTag, MaxF(nearDist, CBConfig.MyCrewMidSpawnDistance()), body, extraTag) > 0 {
    ring = 2;
    return 1;
  }
  if CBSpawnGroup(game, record, appearance, 1, squadTag, nearDist, body, extraTag, true) > 0 {
    ring = 3;
    return 1;
  }
  if CBSpawnGroup(game, record, appearance, 1, squadTag, MaxF(nearDist, CBConfig.MyCrewFarSpawnDistance()), body, extraTag) > 0 {
    ring = 4;
    return 1;
  }
  return 0;
}

public func CBSpawnRingWords(ring: Int32) -> String {
  switch ring {
    case 1: return "close by, out of sight";
    case 2: return "the middle ring, out of sight";
    case 3: return "close by, where V may see them walk up";
    case 4: return "the hunters' distance, walking in";
    default: return "nowhere";
  }
}

// `inSightOk`: V's own crew only, on a second try when nowhere out of V's sight would take them. The engine still waits
// for V to look away before they appear (spawnInView), so it is the walk up that V may see, never the appearing.
public func CBSpawnGroup(game: GameInstance, record: TweakDBID, appearance: CName, wanted: Int32, squadTag: CName, baseDist: Float, out lastSpawned: EntityID, opt extraTag: CName, opt inSightOk: Bool) -> Int32 {
  // Further out on harder difficulties, so there is more time between a warning and a fight.
  let dist = baseDist + CBConfig.DifficultySpawnExtra() * Cast<Float>(CBDifficultyLevel());
  // Never more of ours alive at once than the ceiling.
  let room = CBSpawnRoom(game) - (Equals(squadTag, n"CB_Own") ? 0 : CBCrewRoomKept(game));
  let count = wanted < room ? wanted : room;
  if room <= 0 {
    CBLog.Info(n"Spawn", s"No room: \(CBMaxLiveSpawns(game) - CBSpawnRoom(game)) of ours in the world, \(Equals(squadTag, n"CB_Own") ? 0 : CBCrewRoomKept(game)) places kept for V's crew; nobody else is sent until some are gone.");
    return 0;
  }
  if !TDBID.IsValid(record) || count <= 0 || !CBRecordIsPerson(record) {
    CBNoteSpawnBlock(CBBlockNoRecord());
    return 0;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(des) || !IsDefined(player) {
    return 0;
  }
  // Never spawn into a world that is still streaming in (right after fast travel / a load, or
  // during a scene): the spawn point may not be ready and queuing one mid-stream can crash.
  if !CBWorldStable(game) {
    CBNoteSpawnBlock(CBBlockWorldBusy());
    return 0;
  }
  // Nor while the story has the stage. Every point is checked for this as well (CBSafeAreaBlocksSpawn),
  // but asking once here means a refused arrival is refused as a whole, before any point is probed.
  if CBStoryHoldNow(game) {
    CBNoteSpawnBlock(CBBlockStory());
    return 0;
  }
  let ppos = player.GetWorldPosition();
  let fwd = player.GetWorldForward();
  let openAir = CBArrivalOpenAir(game, ppos);
  // On V's side (CBSafeAreaBlocksSpawn): V's crew and people lent to V go where their own gate lets them.
  let side = Equals(squadTag, n"CB_Own") || Equals(squadTag, n"CB_Ally");
  let minAway = CBArrivalMinAway(dist);

  // Where the group forms up. The navmesh anchor is the good answer; the flat offset behind V
  // is the old one, kept because interiors and some streamed-in areas have no navmesh and a
  // missing anchor must not mean nobody ever arrives.
  let anchor: Vector4;
  let haveAnchor = CBNavAnchor(game, dist, anchor);
  let baseX = haveAnchor ? anchor.X : ppos.X;
  let baseY = haveAnchor ? anchor.Y : ppos.Y;
  let baseZ = haveAnchor ? anchor.Z : ppos.Z;

  // Flat right vector, to spread the row sideways.
  let rx = -fwd.Y;
  let ry = fwd.X;
  let orient = Quaternion.BuildFromDirectionVector(new Vector4(fwd.X, fwd.Y, 0.0, 0.0));

  let spawned = 0;
  let used: array<Vector4>;   // where bodies have already gone, so nobody lands on top of one
  // Assume the worst and clear it on success, so a silent refusal cannot look like a success. Each spot refused from
  // here is counted under its own reason, and the one that refused the most is what the log and the Hub name.
  let rtTally = CyberbaneRuntime.Get();
  if IsDefined(rtTally) {
    rtTally.ResetSpawnBlockTally();
  }
  CBAssumeSpawnBlock(CBBlockNoGround());

  // The game's answer first. If the navmesh offers places to stand, use them and skip the hand-rolled probing entirely;
  // it is only there for when this comes back with nothing.
  let navPts: array<Vector4>;
  // V driving: people on foot are looked for ahead of the car, further ahead the faster it goes, the way the game's
  // police pick where to look for theirs. Behind a moving car they were left standing in the road.
  let car = player.GetMountedVehicle() as VehicleObject;
  let speed = IsDefined(car) ? AbsF(car.GetCurrentSpeed()) : 0.0;
  let foundPts = false;
  if speed > CBConfig.SpawnAheadMinSpeed() {
    let cf = car.GetWorldForward();
    let lead = CBConfig.SpawnAheadNear() + (CBConfig.SpawnAheadFar() - CBConfig.SpawnAheadNear()) * ClampF(speed / 30.0, 0.0, 1.0);
    // The car is closing on the spot while the engine builds them, so the circle starts past the nearest they may be put.
    if !side {
      lead = MaxF(lead, minAway + 15.0);
    }
    let ahead = new Vector4(ppos.X + cf.X * lead, ppos.Y + cf.Y * lead, ppos.Z, 1.0);
    foundPts = CBPursuitPointsAround(game, ppos, ahead, count, 4.0, 30.0, navPts);
  }
  if !foundPts {
    foundPts = CBPursuitPoints(game, ppos, fwd, count, dist * 0.6, dist * 1.6, navPts);
  }
  if foundPts {
    let n = 0;
    while n < ArraySize(navPts) && spawned < count {
      let p = navPts[n];
      n += 1;
      let at: Vector4;
      // The rest of a group form up near the first, because a squad that arrives together reads as a squad, and every
      // one of them has to be joined to the group (CBPointArrivable).
      let ok = CBSettleOnGround(game, p, at) && CBPointIsFree(used, at);
      // On V's floor, unless V is out under the open sky.
      if ok && !openAir && AbsF(at.Z - ppos.Z) > CBConfig.GroundMaxDrop() {
        ok = false;
      }
      if !ok {
        CBNoteSpawnBlock(CBBlockNoGround());
      }
      if ok {
        ok = !CBSafeAreaBlocksSpawn(game, at, side);
      }
      // Nobody appears where the player is looking (CBArrivalUnseen). V's own side asks it of the first body only, and
      // the rest form up within SpawnGroupRadius; everybody else asks it of every body.
      if ok && (ArraySize(used) == 0 || !side) {
        ok = CBArrivalUnseen(game, ppos, fwd, at, side, inSightOk, minAway);
        if !ok {
          CBNoteSpawnBlock(CBBlockInView());
        }
      }
      if ok && ArraySize(used) > 0 {
        ok = Vector4.Distance(at, used[0]) <= CBConfig.SpawnGroupRadius();
        if !ok {
          CBNoteSpawnBlock(CBBlockNoGround());
        }
      }
      if ok {
        ok = CBPointArrivable(game, at, used, ppos, openAir);
        if !ok {
          CBNoteSpawnBlock(CBBlockNoPath());
        }
      }
      if ok {
        let facing = Quaternion.BuildFromDirectionVector(
          Vector4.Normalize2D(new Vector4(ppos.X - at.X, ppos.Y - at.Y, 0.0, 0.0)));
        if CBCreateSpawn(des, record, appearance, at, facing, squadTag, lastSpawned, extraTag) {
          spawned += 1;
          ArrayPush(used, at);
        } else {
          CBNoteSpawnBlock(CBBlockEngineRefused());
        }
      }
    }
    if spawned >= count {
      CBNoteSpawnBlock(CBBlockNone());
      return spawned;
    }
  }

  let i = 0;
  // `spawned` already counts anyone the navmesh placed above, so this caps the total rather
  // than placing a second full group on top of a partial one.
  while i < count && spawned < count {
    // Lay them out in ranks rather than one long line. At 2.5 m apart a squad of twenty would
    // otherwise stretch fifty metres across, with most of the lanes failing the ground and
    // safe area checks and the survivors looking like a parade.
    let perRank = CBConfig.SpawnPerRank();
    let rank = i / perRank;
    let inRank = i % perRank;
    let wide = count < perRank ? count : perRank;
    let lane = Cast<Float>(inRank) - Cast<Float>(wide - 1) * 0.5;
    let rankBack = Cast<Float>(rank) * CBConfig.SpawnRankSpacing();
    let placed = false;
    // With an anchor the group forms up around it, so the ranks only spread sideways and back
    // from there; without one each body is measured from V as before.
    if haveAnchor {
      let ax = baseX - fwd.X * rankBack + rx * lane * 2.5;
      let ay = baseY - fwd.Y * rankBack + ry * lane * 2.5;
      let snapped: Vector4;
      let standing: Vector4;
      if CBNavSnap(game, ax, ay, baseZ, snapped) && CBSettleOnGround(game, snapped, standing)
         && CBPointIsFree(used, standing) && !CBSafeAreaBlocksSpawn(game, standing, side)
         && ((side && ArraySize(used) > 0) || CBArrivalUnseen(game, ppos, fwd, standing, side, inSightOk, minAway))
         && CBPointArrivable(game, standing, used, ppos, openAir) {
        if CBCreateSpawn(des, record, appearance, standing, orient, squadTag, lastSpawned, extraTag) {
          spawned += 1;
          ArrayPush(used, standing);
        }
        placed = true;
      }
    }
    // Sweep around V rather than staring at one spot.
    let attempt = 0;
    while attempt < CBConfig.SpawnBearingTries() && !placed {
      let ang = CBSpawnBearing(attempt);
      let ca = CosF(ang);
      let sa = SinF(ang);
      // Behind V, rotated by the bearing, with the lane offset rotated to match.
      let bx = -fwd.X * ca - (-fwd.Y) * sa;
      let by = -fwd.X * sa + (-fwd.Y) * ca;
      let lx = rx * ca - ry * sa;
      let ly = rx * sa + ry * ca;
      let d = dist * CBSpawnDistanceScale(attempt % 3) + rankBack;
      let px = ppos.X + bx * d + lx * lane * 2.5;
      let py = ppos.Y + by * d + ly * lane * 2.5;
      let gz: Float;
      // An apartment, a bar, a clinic. The game forces V's hands empty in there, so an arrival is a fight the player
      // cannot have (spec §16). Off unless they ask for it.
      if !CBSafeAreaBlocksSpawn(game, new Vector4(px, py, ppos.Z, 1.0), side) {
        // A floor far above or below V is another level entirely - a roof, the bottom of a
        // shaft - so it is refused and the point moves in rather than dropping someone there.
        let stand: Vector4;
        if CBGroundAt(game, px, py, ppos.Z, gz) && AbsF(gz - ppos.Z) <= CBConfig.GroundMaxDrop()
           && CBStandOnNavmesh(game, px, py, gz, stand) {
          // Only a usable point ends this lane: placed, or the engine itself turned it down. A point taken, in V's
          // sight or with no way to V is the wrong point, not a refusal, so the next bearing is tried.
          if (ArraySize(used) == 0 || !side) && !CBArrivalUnseen(game, ppos, fwd, stand, side, inSightOk, minAway) {
            CBNoteSpawnBlock(CBBlockInView());
          } else {
            if !CBPointIsFree(used, stand) || !CBPointArrivable(game, stand, used, ppos, openAir) {
              CBNoteSpawnBlock(!CBPointIsFree(used, stand) ? CBBlockNoGround() : CBBlockNoPath());
            } else {
              if CBCreateSpawn(des, record, appearance, stand, orient, squadTag, lastSpawned, extraTag) {
                spawned += 1;
                ArrayPush(used, stand);
              } else {
                CBNoteSpawnBlock(CBBlockEngineRefused());
              }
              placed = true;
            }
          }
        }
      }
      attempt += 1;
    }
    // Last resort: close in, and still on a floor.
    if !placed {
      let fx = ppos.X - fwd.X * (dist * CBConfig.SpawnNearestShare() + rankBack) + rx * lane * 2.5;
      let fy = ppos.Y - fwd.Y * (dist * CBConfig.SpawnNearestShare() + rankBack) + ry * lane * 2.5;
      let fz: Float;
      let fallback: Vector4;
      if CBGroundAt(game, fx, fy, ppos.Z, fz) && AbsF(fz - ppos.Z) <= CBConfig.GroundMaxDrop()
         && CBStandOnNavmesh(game, fx, fy, fz, fallback) {
        // The fallback is close in, so it is the likeliest of the lot to land indoors and the likeliest to land in
        // frame.
        if CBSafeAreaBlocksSpawn(game, fallback, side) {
          // noted by the gate itself
        } else {
          if !CBArrivalUnseen(game, ppos, fwd, fallback, side, inSightOk, minAway) {
            CBNoteSpawnBlock(CBBlockInView());
          } else {
            if !CBPointIsFree(used, fallback) {
              CBNoteSpawnBlock(CBBlockNoGround());
            } else {
              if !CBPointArrivable(game, fallback, used, ppos, false) {
                CBNoteSpawnBlock(CBBlockNoPath());
              } else {
                if CBCreateSpawn(des, record, appearance, fallback, orient, squadTag, lastSpawned, extraTag) {
                  spawned += 1;
                  ArrayPush(used, fallback);
                } else {
                  CBNoteSpawnBlock(CBBlockEngineRefused());
                }
              }
            }
          }
        }
      } else {
        CBNoteSpawnBlock(CBBlockNoGround());
      }
    }
    i += 1;
  }
  if spawned > 0 {
    CBAssumeSpawnBlock(CBBlockNone());
  } else {
    // The reason that turned down the most spots, with the whole count beside it.
    let tallyLine = "";
    if IsDefined(rtTally) {
      rtTally.AssumeSpawnBlock(rtTally.MostSpawnBlock());
      tallyLine = rtTally.SpawnBlockTallyLine();
    }
    CBLog.Info(n"Spawn", s"Nothing could be placed: \(CBBlockLabel(CBLastSpawnBlock())) (spots refused: \(tallyLine)).");
  }
  return spawned;
}

// The gate that last refused an arrival, for the Hub and the log.
public func CBLastSpawnBlock() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return CBBlockNone();
  }
  return rt.GetLastSpawnBlock();
}

// Tell a freshly arrived hostile to come and find V.
public func CBOrderHunt(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !IsDefined(puppet) || puppet.cbMoraleBroken {
    return;
  }
  let ai = puppet.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  let cmd = new AIMoveToCommand();
  let dest: AIPositionSpec;
  let wp: WorldPosition;
  // Where V was last seen, not where V is.
  let sysHunt = CyberbaneSystem.Get(game);
  let target = player.GetWorldPosition();
  if IsDefined(sysHunt) && sysHunt.GetHuntState() != CBHuntNone() {
    let lkp = sysHunt.GetHuntLkp();
    if lkp.X != 0.0 || lkp.Y != 0.0 || lkp.Z != 0.0 {
      target = lkp;
    }
  }
  WorldPosition.SetVector4(wp, target);
  AIPositionSpec.SetWorldPosition(dest, wp);
  cmd.movementTarget = dest;
  cmd.movementType = moveMovementType.Sprint;
  cmd.ignoreInCombat = true;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  // Spread where they stop so a squad surrounds V instead of stacking on one spot.
  cmd.desiredDistanceFromTarget = CBConfig.HuntStopDistance() + RandF() * CBConfig.HuntStopSpread();
  CBIssueMove(puppet, ai, cmd);
}

// ---- Orders, one at a time ------------------------------------------------------
//
// The game sends a script order to an NPC once, through the AI component (AIComponent.SendCommand,
// core/components/aiComponent.script).
@addField(ScriptedPuppet)
public let cbMoveCmd: ref<AIMoveToCommand>;

@addField(ScriptedPuppet)
public let cbUnmountSent: Bool;

public func CBIssueMove(puppet: ref<ScriptedPuppet>, ai: ref<AIHumanComponent>, cmd: ref<AIMoveToCommand>) -> Void {
  if !IsDefined(puppet) || !IsDefined(ai) || !IsDefined(cmd) || !puppet.IsAttached() {
    return;
  }
  if IsDefined(puppet.cbMoveCmd) {
    ai.CancelCommand(puppet.cbMoveCmd);
  }
  // A conversation's hold-position order goes first (Reactions/StreetTalk.reds): one order at a time.
  if IsDefined(puppet.cbTalkHold) {
    CBEndHold(puppet, puppet.cbTalkHold);
    puppet.cbTalkHold = null;
  }
  puppet.cbMoveCmd = cmd;
  CBTrace("ai: move order");
  ai.SendCommand(cmd);
}

// Drop whatever move order Cyberbane last gave this NPC.
public func CBCancelMove(puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || !IsDefined(puppet.cbMoveCmd) {
    return;
  }
  let ai = puppet.GetAIControllerComponent();
  if IsDefined(ai) && puppet.IsAttached() {
    ai.CancelCommand(puppet.cbMoveCmd);
  }
  puppet.cbMoveCmd = null;
}

// Tell one NPC to get out of the car it is in. Once per NPC.
public func CBUnmountOnce(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || puppet.cbUnmountSent || !puppet.IsAttached() || puppet.IsDead()
     || !VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) {
    return;
  }
  puppet.cbUnmountSent = true;
  puppet.cbUnmountAt = CBSimNow(game);   // a seat still taken a few seconds on is lifted out (CBUnmountStuck)
  CBAskOutOfCar(puppet);
}

// When this one was first asked out of a car, in engine seconds.
@addField(ScriptedPuppet)
public let cbUnmountAt: Float;

// Again, for somebody already asked who is still sitting there. Only those: the slot tags stay on
// people for good, and somebody who has never been asked is in a different car, and may be moving.
public func CBUnmountAgain(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(puppet) || !puppet.cbUnmountSent || !puppet.IsAttached() || puppet.IsDead()
     || !VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) {
    return false;
  }
  CBAskOutOfCar(puppet);
  return true;
}

func CBAskOutOfCar(puppet: ref<ScriptedPuppet>) -> Void {
  CBCancelMove(puppet);
  CBTrace("vehicle: asking an NPC out of a car");
  puppet.QueueEvent(AIEvents.ExitVehicleEvent());
}

// ---- Taking things out of the world ---------------------------------------------
//
// Every removal goes through here. DeleteTagged removed whatever carried the tag at that moment, including an NPC
// sitting in a car seat and one the engine was still in the middle of spawning.
public func CBDeleteTaggedSafe(game: GameInstance, tag: CName, opt livingOnly: Bool,
                               opt unseenOnly: Bool) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return 0;
  }
  let crewSeated = CBAnyCrewSeated(game, des);
  let ids = des.GetTaggedIDs(tag);
  let kept = 0;
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    let dead = false;
    if livingOnly {
      let body = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      dead = IsDefined(body) && body.IsDead();
    }
    if !dead && !CBRemoveOne(game, des, id, crewSeated, unseenOnly) {
      kept += 1;
      if NotEquals(tag, n"Cyberbane") && NotEquals(tag, n"CB_Orphan") {
        des.UnassignTag(id, tag);
      }
      des.AssignTag(id, n"CB_Orphan");
    }
  }
  if kept > 0 {
    CBLog.Info(n"Spawn", s"\(kept) of ours were seated or still spawning; they go once they are out.");
  }
  return kept;
}

// Remove one entity if it is safe to; false if it was left for later.
func CBRemoveOne(game: GameInstance, des: ref<DynamicEntitySystem>, id: EntityID, crewSeated: Bool,
                 opt unseenOnly: Bool) -> Bool {
  if !EntityID.IsDefined(id) {
    return true;
  }
  if des.IsSpawning(id) {
    return false;
  }
  let ent = GameInstance.FindEntityByID(game, id);
  // Asked to be discreet and V can still see them: leave them to the sweep.
  if unseenOnly && IsDefined(ent) && !CBOutOfView(game, ent.GetWorldPosition()) {
    return false;
  }
  if IsDefined(ent as VehicleObject) {
    if crewSeated {
      return false;
    }
    // Never the car V is sitting in: a gang's car V took after its crew went down still carries Cyberbane's tags, and
    // whatever ended the thing it came with (a convoy released, Start over, an event over) deleted it from under V.
    let player = GetPlayer(game);
    let vCar = IsDefined(player) ? player.GetMountedVehicle() : null;
    if IsDefined(vCar) && Equals(vCar.GetEntityID(), id) {
      return false;
    }
  } else {
    let p = ent as ScriptedPuppet;
    if IsDefined(p) {
      if VehicleComponent.IsMountedToVehicle(game, id) {
        CBUnmountOnce(game, p);
        CBUnmountStuck(game, p);   // still sitting there after being asked: lifted out once the car stands still
        return false;
      }
      // Lying there, dead or down and breathing, where V can still come back to them: not now, whoever asked. They wait
      // as an orphan and go once V has left them behind (CBSweepOrphans asks this again).
      if CBIsDown(p) && CBRemainsInReach(game, p.GetWorldPosition()) {
        return false;
      }
      CBUntrackOnMap(game, p);
      CBCancelMove(p);
    }
  }
  CBTrace("remove: one of ours");
  let deleted = des.DeleteEntity(id);
  // Not in the world: an apex squad still in its car far off, somebody streamed out.
  if !IsDefined(ent) && des.IsManaged(id) {
    CBOrphanOffLists(des, id);
    return true;
  }
  return deleted || !des.IsManaged(id);
}

// Every tag of ours but the mod's own taken off, and the orphan's put on (CBRemoveOne): no encounter, sweep or count
// finds them again.
func CBOrphanOffLists(des: ref<DynamicEntitySystem>, id: EntityID) -> Void {
  let tags = des.GetTags(id);
  for t in tags {
    if NotEquals(t, n"Cyberbane") && NotEquals(t, n"CB_Orphan") {
      des.UnassignTag(id, t);
    }
  }
  if !des.IsTagged(id, n"CB_Orphan") {
    des.AssignTag(id, n"CB_Orphan");
  }
}

// Is any of Cyberbane's car crew still in a seat?
func CBAnyCrewSeated(game: GameInstance, des: ref<DynamicEntitySystem>) -> Bool {
  let ids = des.GetTaggedIDs(n"CB_Crew");
  let i = 0;
  while i < ArraySize(ids) {
    if VehicleComponent.IsMountedToVehicle(game, ids[i]) {
      return true;
    }
    i += 1;
  }
  return false;
}

// Slow tick: clear whatever was left behind once it can be removed safely, out of V's sight.
public func CBSweepOrphans(game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !des.IsPopulated(n"CB_Orphan") || !CBWorldStable(game) {
    return;
  }
  let crewSeated = CBAnyCrewSeated(game, des);
  let ids = des.GetTaggedIDs(n"CB_Orphan");
  let i = 0;
  while i < ArraySize(ids) {
    let ent = GameInstance.FindEntityByID(game, ids[i]);
    let seated = ent as ScriptedPuppet;
    if IsDefined(seated) && VehicleComponent.IsMountedToVehicle(game, ids[i]) {
      // Out of the car first, seen or not: getting out is nothing to hide, and one sitting beside V in V's car was
      // never out of view, so they were never even asked again and sat there for good.
      CBUnmountOnce(game, seated);
      CBUnmountStuck(game, seated);
    } else {
      if !IsDefined(ent) || CBOutOfView(game, ent.GetWorldPosition()) {
        CBRemoveOne(game, des, ids[i], crewSeated);
      }
    }
    i += 1;
  }
}

// Is somebody lying at `at` still V's to come back to? Within RemainsSweepDistance of V, or, while V is still in a
// fight, within RemainsFightDistance; whether V can see the spot or not.
public func CBRemainsInReach(game: GameInstance, at: Vector4) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  let d = Vector4.Distance(player.GetWorldPosition(), at);
  return d <= CBConfig.RemainsSweepDistance() || (player.IsInCombat() && d <= CBConfig.RemainsFightDistance());
}

// Could V see something vanish here? Out of view means behind V, round the side, blocked by a
// wall, or simply a long way off. Every removal that can happen near V checks this, so nobody and
// nothing disappears in front of the player.
public func CBOutOfView(game: GameInstance, at: Vector4) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return true;
  }
  let ppos = player.GetWorldPosition();
  if Vector4.Distance(ppos, at) >= CBConfig.VanishSafeDistance() {
    return true;
  }
  return CBPointOutOfSight(game, ppos, player.GetWorldForward(), at);
}

// Finish setting up one of our own, once the engine has actually built it.
public class CBSpawnSetupCallback extends DelayCallback {
  public let entityId: EntityID;
  public let riding: Bool;
  public let tries: Int32;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    // Not while the world is loading or streaming: everything below writes attitude, stats and orders on a native
    // puppet, which is the crash this whole mod's tick is gated against.
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let ds = GameInstance.GetDelaySystem(game);
        if IsDefined(ds) {
          let again = new CBSpawnSetupCallback();
          again.entityId = this.entityId;
          again.riding = this.riding;
          again.tries = this.tries;
          again.waits = this.waits + (CBWaitCounts(game) ? 1 : 0);
          ds.DelayCallback(again, CBConfig.SpawnSetupRetrySeconds(), false);
        }
      } else {
        CBSetupGiveBack(game, this.entityId);
      }
      return;
    }
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) {
      return;
    }
    let puppet = GameInstance.FindEntityByID(game, this.entityId) as ScriptedPuppet;
    // Gone already: shot on the way in, or streamed out. Nothing to do and nothing to retry.
    if !IsDefined(puppet) || !puppet.IsAttached() {
      if this.tries < CBConfig.SpawnSetupMaxTries() {
        CBRetrySpawnSetup(game, this);
      }
      return;
    }
    // The components we need, specifically. Checking these rather than a timer is the honest
    // test: when they exist, the orders below will land.
    if !IsDefined(puppet.GetAttitudeAgent()) || !IsDefined(puppet.GetAIControllerComponent()) {
      if this.tries < CBConfig.SpawnSetupMaxTries() {
        CBRetrySpawnSetup(game, this);
      } else {
        // Back to the sweep, which asks again on a later settled tick: left marked as queued, it was never set up at
        // all and stood there as whatever it was spawned as.
        CBSetupGiveBack(game, this.entityId);
        CBLog.Info(n"Spawn", "A spawned enemy was not ready to set up; trying again shortly.");
      }
      return;
    }
    // Killed before it was ever set up: nothing to build, kit or show a bar for.
    if puppet.IsDead() || !CBStillStanding(puppet) {
      return;
    }
    CBApplySpawnSetup(sys, game, puppet, this.riding);
  }
}

// A setup that could not finish hands its body back to the missed-setup sweep (CBRescueMissedSetup).
func CBSetupGiveBack(game: GameInstance, id: EntityID) -> Void {
  let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
  if IsDefined(p) {
    p.cbSetupQueued = false;
  }
}

func CBRetrySpawnSetup(game: GameInstance, from: ref<CBSpawnSetupCallback>) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) {
    return;
  }
  let next = new CBSpawnSetupCallback();
  next.entityId = from.entityId;
  next.riding = from.riding;
  next.tries = from.tries + 1;
  next.waits = from.waits;
  ds.DelayCallback(next, CBConfig.SpawnSetupRetrySeconds(), false);
}

public func CBScheduleSpawnSetup(game: GameInstance, id: EntityID, riding: Bool) -> Void {
  if !EntityID.IsDefined(id) {
    return;
  }
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) {
    return;
  }
  let cb = new CBSpawnSetupCallback();
  cb.entityId = id;
  cb.riding = riding;
  cb.tries = 0;
  ds.DelayCallback(cb, CBConfig.SpawnSetupRetrySeconds(), false);
}

// Handed to the setup above, so the sweep below does not do it twice.
@addField(ScriptedPuppet)
public let cbSetupQueued: Bool;

// The second chance the attach event cannot give.
public func CBRescueMissedSetup(game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !des.IsPopulated(n"Cyberbane") {
    return;
  }
  let ids = des.GetTaggedIDs(n"Cyberbane");
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.IsAttached() && CBQueueSpawnSetup(game, des, p) {
      CBLog.Info(n"Spawn", "One of ours attached while the world was busy; setting them up now.");
    }
  }
}

// Hand one of ours to the setup above, once: from the attach event (CyberbaneSystem), or from the sweep above when the
// event stood down.
public func CBQueueSpawnSetup(game: GameInstance, des: ref<DynamicEntitySystem>, p: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(des) || !IsDefined(p) || p.cbSetupQueued || p.IsDead() {
    return false;
  }
  let id = p.GetEntityID();
  if !des.IsTagged(id, n"Cyberbane") {
    return false;
  }
  p.cbSetupQueued = true;
  // Crew first: they belong in a seat, not running at V on foot from where the car is.
  let riding = des.IsTagged(id, n"CB_Crew");
  if riding {
    CBScheduleConvoyMount(game, id);   // a moment later
  }
  CBScheduleSpawnSetup(game, id, riding);
  return true;
}

// Everything that makes one of ours behave like one of ours.
public func CBApplySpawnSetup(sys: ref<CyberbaneSystem>, game: GameInstance,
                              puppet: ref<ScriptedPuppet>, riding: Bool) -> Void {
  CBSpawnSetupBody(sys, game, puppet, riding);
  // A build is recorded by the body's health when it is built, and what the set-up puts on after it (a Rival's traits,
  // the kit V gave them, the ceiling in Spawn/Killable.reds) changes that health.
  if IsDefined(sys) && IsDefined(puppet) && CBStillStanding(puppet) {
    let stats = GameInstance.GetStatsSystem(game);
    if IsDefined(stats) {
      sys.NoteRebuilt(puppet.GetEntityID(), stats.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatType.Health));
    }
  }
}

func CBSpawnSetupBody(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, riding: Bool) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !IsDefined(puppet) {
    return;
  }
  let id = puppet.GetEntityID();
  // Never one the game will not let die, whoever they are and however they came back into the world.
  CBDisarmGodMode(game, puppet);
  // And nothing brings them back from V's damage (Spawn/Killable.reds): every body Cyberbane puts in the world is
  // watched while V lands hits. One that gets built takes its ceiling again then; this one only keeps what it came
  // with.
  CBSetKillLimit(game, puppet, CBConfig.KillableCrewSeconds());
  // Knocked out and streamed back in. Made hostile, told to chase V and marked, they used to be:
  // a body on the ground with an order it could not carry out and a pin that stayed until it died.
  if !CBStillStanding(puppet) {
    return;
  }
  // An ended encounter's body (CB_Orphan) is nobody's to set up: it keeps whatever tag it was left
  // with when it could not be removed, and setting it up again made it hostile and sent it after V.
  if des.IsTagged(id, n"CB_Orphan") {
    return;
  }
  // An apex escort fights as rank and file, so it takes the squad's kit.
  if des.IsTagged(id, n"CB_Patrol") {
    CBSetUpPatrol(sys, game, puppet);
    return;
  }
  // The street's own people (Spawn/LivingStreet.reds): no hunting orders for any of them.
  if des.IsTagged(id, n"CB_Bagman") || des.IsTagged(id, n"CB_Meet") {
    CBSetUpStreet(sys, game, puppet, false);
    // A gang's best at a sit-down: built like its apex squad (Spawn/LivingStreet.reds).
    if CBIsMeetApex(des, id) {
      CBSetUpMeetApex(sys, game, puppet, CBTaggedApexSeat(des, id));
    }
    return;
  }
  if des.IsTagged(id, n"CB_Favour") {
    CBSetUpStreet(sys, game, puppet, true);
    return;
  }
  // A gang's people hanging out on their own streets (Spawn/Hangouts.reds): neutral, there to be talked to.
  if des.IsTagged(id, n"CB_Hangout") {
    CBSetUpStreet(sys, game, puppet, false);
    return;
  }
  // A crew waiting on V's road (Spawn/HuntGrows.reds): hostile from the start, kitted and built as a crew.
  if des.IsTagged(id, n"CB_Ambush") {
    CBSetUpStreet(sys, game, puppet, true);
    CBKitSquadMember(puppet);
    CBApplyCrewBuild(sys, game, puppet);
    return;
  }
  // Gang life's people (Spawn/StreetEvents.reds): street people, and a deal's guard built like the gang's best.
  if des.IsTagged(id, n"CB_Event") {
    CBSetUpStreet(sys, game, puppet, false);
    let eventSeat = CBTaggedApexSeat(des, id);
    if eventSeat >= 0 {
      CBSetUpMeetApex(sys, game, puppet, eventSeat);
    }
    return;
  }
  // The one who owes a gang money (Spawn/LivingStreet.reds): minding their own business until V leans on them.
  if des.IsTagged(id, n"CB_Debtor") || des.IsTagged(id, n"CB_Witness") || des.IsTagged(id, n"CB_Mark") {
    CBSetUpStreet(sys, game, puppet, false);
    return;
  }
  // A wannabe walks up first and only turns on V when they get there (Spawn/Wannabe.reds).
  if des.IsTagged(id, n"CB_Wannabe") {
    CBSetUpStreet(sys, game, puppet, false);
    return;
  }
  // One of V's own crew (Reactions/Crew.reds): kitted for their seat, on the game's follower role. A stronghold's
  // garrison (Rivals/Strongholds.reds).
  if des.IsTagged(id, n"CB_Hold") {
    CBSetUpHold(sys, game, puppet);
    return;
  }

  // An add-on's convoy crew (API/Convoy.reds): set up, then seated in their car.
  if des.IsTagged(id, n"CB_Convoy") {
    CBApiConvoySetUp(sys, game, puppet);
    return;
  }

  // An add-on's group (API/Requests.reds).
  if des.IsTagged(id, n"CB_Api") {
    CBApiSetUpBody(sys, game, puppet);
    return;
  }

  // One of V's crew at a post at home (Reactions/CrewHome.reds).
  if des.IsTagged(id, n"CB_Loiter") {
    CBSetUpLoiter(sys, game, puppet);   // V's crew on a corner (Reactions/CrewLoiter.reds)
    return;
  }
  if des.IsTagged(id, n"CB_Guard") {
    CBSetUpGuard(sys, game, puppet);
    return;
  }

  if des.IsTagged(id, n"CB_Own") {
    CBSetUpCrewMember(sys, game, puppet);
    return;
  }
  // One who turned on V is set up by the turn itself, never again here.
  if des.IsTagged(id, n"CB_Turned") {
    return;
  }
  // One of a friendly gang's people riding with V (Reactions/Allies.reds): the game's follower role.
  if des.IsTagged(id, n"CB_Follower") {
    CBSetUpFollower(sys, game, puppet);
    return;
  }
  if des.IsTagged(id, n"CB_Ally") {
    CBSetUpAlly(sys, game, puppet);
    return;
  }
  // One of the hunters' ladder (Spawn/Bounty.reds): CB_Squad too, so every crew list reaches them, but a solo with
  // their own build, never a sergeant, a grenadier or one of a squad.
  if des.IsTagged(id, n"CB_Bounty") {
    CBSetUpBountyHunter(sys, game, puppet, riding);
    return;
  }
  // A scout looks without drawing, until they have called it in (Spawn/Hunted.reds).
  if des.IsTagged(id, n"CB_Scout") {
    CBSetUpScout(sys, game, puppet);
    CBKitSquadMember(puppet);
    CBApplyCrewBuild(sys, game, puppet);
    return;
  }
  let isSquad = des.IsTagged(id, n"CB_Squad") || des.IsTagged(id, n"CB_Escort");
  let isRival = des.IsTagged(id, n"CB_Rival");
  let isApex = des.IsTagged(id, n"CB_Apex");
  // A Rival waiting at their own place for V to come to them (Rivals/Whereabouts.reds). Set up
  // like any Rival, except that nobody tells them to go anywhere.
  let isLair = des.IsTagged(id, n"CB_Lair");
  if !isSquad && !isRival && !isApex && !isLair {
    return;
  }
  // Aggressive first, because the rest of it depends on being aggressive.
  CBGrantAbility(puppet as NPCPuppet, t"Ability.IsAggressive");
  // A Rival owed a facedown, and the people with them, walk up calm (Rivals/RivalMoments.reds, [53]). Sent in hostile,
  // they saw V from forty metres and the fight was on before the facedown's twenty-four, so it all but never opened.
  let lairCalm = isLair && CBFacedownAwaitsFor(sys, game, sys.FindRivalById(sys.GetLairRivalId()));
  if ((isRival || des.IsTagged(id, n"CB_Escort")) && !isLair && CBFacedownAwaits(sys, game)) || lairCalm {
    puppet.cbFacedownWait = true;
    puppet.cbFacedownWaitTick = Max(sys.GetTickCount(), 1);
  } else {
    CBMakeHostileToPlayer(game, puppet);
  }
  CBDisarmGodMode(game, puppet);
  // Hostile is not the same as coming for you. Anybody in a car is excepted: the car travels. Where they go is the
  // hunt's business: toward where V was last known, until somebody finds V (Spawn/Hunt.reds).
  if !riding && !isLair {
    CBOrderPursue(sys, game, puppet);
  }
  // Waiting at their place: one step where they stand (CBWakeStep), or nothing ever asked anything of them and they
  // could stand in the default pose until hit.
  if isLair && !riding {
    CBWakeStep(puppet);
  }
  if isApex {
    CBApplyApexBuff(sys, game, puppet);
    // Which chair: the one this body was spawned for, when it carries the tag that says so, otherwise the next one
    // round.
    if !puppet.cbKitted {
      let seat = CBTaggedApexSeat(des, id);
      if seat < 0 {
        seat = sys.NextApexRole();
      }
      CBKitApexSeat(puppet, seat);
      // Their name, for the scanner (UI/ScannerName.reds).
      puppet.cbApexName = CBApexMemberName(game, CBClassifyFaction(puppet), seat);
      puppet.SetScannerDirty(true);
    }
    CBShowBossBar(puppet);
  }
  // A marker on everyone the mod sends.
  CBTrackOnMap(game, puppet);
  if isSquad {
    // One of a crew leads it ([U2]): the first of them to arrive, never an escort or a scout, never one who came with
    // an apex squad (the squad leads then). The scanner names them, and their fall shakes the rest.
    if des.IsTagged(id, n"CB_Squad") && !sys.ActiveSquadHasApex() && !puppet.cbSergeant && sys.TakeCrewSergeant() {
      puppet.cbSergeant = true;   // a field, not a tag: they are CB_Squad, which every list already covers
      puppet.SetScannerDirty(true);
    }
    CBKitSquadMember(puppet);
    CBApplyCrewBuild(sys, game, puppet);   // their code and what they have prepared for V
  }
  if isApex || isSquad {
    CBJoinSquadWith(sys, puppet);
  }
  // The first of a crew who can carry them carries the grenades (Spawn/Tactics.reds). The apex squad's shooter already
  // does, so a crew that came with its apex has its grenadier there.
  if des.IsTagged(id, n"CB_Squad") && !isApex && !CBAiKitOwner() && !sys.ActiveSquadHasApex()
     && CBCanBeGrenadier(puppet as NPCPuppet) && sys.TakeCrewGrenadier() {
    CBMakeGrenadier(puppet as NPCPuppet);
  }
  if isRival || isLair {
    // Whose body this is. The body recorded at spawn is the exact answer, and the only one for a Rival waiting at their
    // place, who is nobody's active encounter.
    let who = CBFindRivalByBody(sys, id);
    if !IsDefined(who) && !isLair {
      who = sys.FindRivalById(sys.GetActiveRivalId());
    }
    // Their name in the scanner (UI/ScannerName.reds).
    CBMarkRivalBody(puppet, who);
    CBRivalNoteBody(game, who, puppet);   // the body's sex, for a signature record (Rivals/Signature.reds)
    // A named enemy that never uses cover or chrome is a ganger with a nameplate. A cyberpsycho takes the lighter kit,
    // which adds no armour on top of what they already have. A Rival after a cyberpsychotic break fights like one.
    if IsDefined(who) && (CBRecordIsSightingCyberpsycho(who.recordID) || CBRivalHasTrait(who, n"Broken")) {
      CBKitCyberpsycho(puppet as NPCPuppet);
    } else {
      CBKitApexMember(puppet);
      CBKitRivalTraits(puppet as NPCPuppet, who);
    }
    if IsDefined(who) {
      // One call, one build. The crew-rank bonus is a parameter now rather than a second
      // multiplier applied a line later; see the note in Rivals/Hierarchy.reds.
      CBApplyRivalApexBuff(sys, game, puppet, who, CBRivalRole(sys, who));
      // The bar says somebody is on you. One waiting at their place gets it when the fight
      // starts (CBLairPromote), not before.
      if !isLair && (CBRivalGrade(who) >= CBConfig.RivalBossBarGrade() || CBRivalSignatureKind(who) > 0) {
        CBShowBossBar(puppet);
      }
    }
  }
  CBLog.Info(n"Spawn", s"One of ours is up and coming for you\(CBArrivedLine(game, puppet, riding)).");
}

// Where they turned up against where they were put down. A body that appears far nearer than it was placed means V
// walked or drove onto the spot while the engine was still building it.
func CBArrivedLine(game: GameInstance, puppet: ref<ScriptedPuppet>, riding: Bool) -> String {
  let player = GetPlayer(game);
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(player) || !IsDefined(rt) {
    return "";
  }
  let now = RoundF(Vector4.Distance(puppet.GetWorldPosition(), player.GetWorldPosition()));
  let placed = rt.TakePlaced(puppet.GetEntityID());
  let how = riding ? ", in a car" : "";
  if placed < 0.0 {
    return s": appeared \(now)m from V\(how)";
  }
  let driving = IsDefined(player.GetMountedVehicle()) ? ", V driving" : "";
  return s": appeared \(now)m from V, put down \(RoundF(placed))m out\(how)\(driving)";
}

// The chase used to be kept going here by handing every hunter V's position every few seconds, which is why nobody
// could ever lose them.

// How far away the closest living hunter is, or -1 when there is nobody.
func CBNearestHunterDistance(sys: ref<CyberbaneSystem>, game: GameInstance,
                             des: ref<DynamicEntitySystem>, ppos: Vector4) -> Float {
  let best = -1.0;
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Rival", best);
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Apex", best);
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Squad", best);
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Escort", best);
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Scout", best);
  return best;
}

func CBNearestForTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                     ppos: Vector4, tag: CName, best: Float) -> Float {
  let out = best;
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) {
      let d = Vector4.Distance(p.GetWorldPosition(), ppos);
      if out < 0.0 || d < out {
        out = d;
      }
    }
  }
  return out;
}

// You lost them. Clear the encounter out and let it count.
func CBChaseGiveUp(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, opt cold: Bool) -> Void {
  sys.SetChaseAwayTicks(0);
  // A Rival you shook takes it personally and comes back harder; the rest simply lose you.
  CBRivalsShakenOff(sys, game, false);
  sys.ClearPack();
  // A gang crew or apex squad V ran from. Running costs a little standing with them, and lying
  // low works: they leave V alone for a while (the same cooldown a crew starts when it is sent).
  let ranFrom = sys.GetHuntFaction();
  let crewLost = CBLiveTaggedPresent(game, n"CB_Squad") || CBLiveTaggedPresent(game, n"CB_Apex");
  // Give a hit squad the slip and one of them can take it personally (spec §9.9 / §10.2). Read
  // before anybody is removed: it is one of the people V actually lost, and where they stood is
  // where the street will say they were seen.
  CBCrewSurvivorTakesItPersonally(sys, game, des, sys.GetActiveSquadFaction());
  sys.ClearScout();
  sys.ClearApexMuster();   // nobody else of theirs walks in after the hunt is over
  // V lost them, so they are allowed to be seen leaving rather than blinking out.
  CBDeleteTaggedSafe(game, n"CB_Rival", false, true);
  CBDeleteTaggedSafe(game, n"CB_Squad", false, true);
  CBDeleteTaggedSafe(game, n"CB_Apex", false, true);
  CBDeleteTaggedSafe(game, n"CB_Escort", false, true);
  CBDeleteTaggedSafe(game, n"CB_Scout", false, true);
  sys.SetHuntEnd(CBT(n"Cyberbane-Spawner-LOSTTHEM"), CBConfig.HuntEndLineTicks());
  // A trail gone cold (Spawn/Hunted.reds) is V lying low, not V running: no cost, and the street says it.
  if crewLost && NotEquals(ranFrom, n"") && !cold {
    let fs = sys.FindFaction(ranFrom);
    if IsDefined(fs) {
      // Not with reputation frozen: every other change to how a gang sees V already stopped there.
      if !CBReputationFrozen() {
        fs.renown = ClampF(fs.renown - CBConfig.RunRenownLoss(), 0.0, 100.0);
      }
      fs.lastHitSquadAt = CBGameSeconds(game);
    }
    if CBToastsOn() && CBFactionFieldsSquads(ranFrom) {
      CBGangAnswerLater(game, ranFrom, CBT(n"Cyberbane-Spawner-RanDidYouEverybodyIsGoing"));
    }
  }
  // Take the bars down with them, rather than leaving them up for the tick it would take the
  // stack to notice its targets had stopped existing.
  sys.GetThreatBar().Hide();
  sys.SetActiveRivalId(0);
  sys.SetActiveSquadFaction(n"");
  if CBToastsOn() && !crewLost && !cold {
    CBPhoneFromStreet(game, CBLineOf([CBT(n"Cyberbane-Spawner-TheyLostYouDoNotGo"), CBT(n"Cyberbane-Spawner-TheyLostYou2"),
                                      CBT(n"Cyberbane-Spawner-TheyLostYou3")]));
  }
  CBLog.Info(n"Spawn", "Player outran the encounter; hunters gave up.");
}

// One of a crew V gave the slip comes back with a name (spec §9.9 / §10.2).
func CBCrewSurvivorTakesItPersonally(sys: ref<CyberbaneSystem>, game: GameInstance,
                                     des: ref<DynamicEntitySystem>, faction: CName) -> Void {
  if !IsDefined(sys) || !IsDefined(des) || Equals(faction, n"") || !CBRivalsOn() {
    return;
  }
  // Somebody who killed one of V's own is the one who comes back (Reactions/Crew.reds).
  if CBCrewKillerGotAway(sys, game, des, faction) {
    return;
  }
  let ids = des.GetTaggedIDs(n"CB_Squad");
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    // A bounty hunter is no crew's survivor: one beaten comes back by their own road (Spawn/Bounty.reds).
    let hunter = des.IsTagged(ids[i], n"CB_Bounty");
    i += 1;
    if !hunter && CBStillStanding(p) && CBNpcSafe(sys, p) {
      // The first one standing is the one asked, weighed like every other roll (CBRivalOdds).
      if !CBRivalRoll(sys, "lost a crew", CBConfig.RivalChanceHunter(), p.GetRecordID(), true, faction) {
        return;
      }
      let nr = CBCreateRival(sys, game, faction, p.GetRecordID(), n"", ECBRivalSource.Hunter,
                             CBEventDistrict(sys, game), CBGameSeconds(game));
      if IsDefined(nr) {
        CBNoteRivalSeen(sys, game, nr, p);
      }
      return;   // one is enough; CBCreateRival refusing (caps, a story record) is final too
    }
  }
}

// The attitude group the game itself gives this kind of NPC.
public func CBRecordAttitudeGroup(record: TweakDBID) -> CName {
  if !TDBID.IsValid(record) {
    return n"";
  }
  let rec = TweakDBInterface.GetCharacterRecord(record);
  if !IsDefined(rec) {
    return n"";
  }
  return rec.BaseAttitudeGroup();
}

// Make a spawned NPC hostile toward V. Called when a CB_Squad / CB_Rival puppet attaches.
public func CBMakeHostileToPlayer(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  CBTrace("attitude: spawned enemy hostile to V");
  let agent = puppet.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) {
    // Hostile to V, and hostile to whoever else is hostile to them.
    if !IsNameValid(agent.GetAttitudeGroup()) {
      let group = CBRecordAttitudeGroup(puppet.GetRecordID());
      if IsNameValid(group) {
        agent.SetAttitudeGroupUnsavable(group);
      }
    }
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
  }
  // Watched for a while in case it slips (CBRearmTick).
  let sysArm = CyberbaneSystem.Get(game);
  puppet.cbArmTick = IsDefined(sysArm) ? Max(sysArm.GetTickCount(), 1) : 1;
  // And V's companions, who were never told.
  CBMakeHostileToCompanions(CyberbaneSystem.Get(game), puppet);
  // Hostile, and nothing more. They are not handed V as a target here.
}

// ---- Re-armed if they come up neutral --------------------------------------------------------
//
// Another mod (Stay Dead) measured its spawned squads alive but neutral to V: hostility was set once, at spawn, and had
// slipped by the time they mattered, for reasons it could not pin down.
@addField(ScriptedPuppet)
public let cbArmTick: Int32;

@addField(ScriptedPuppet)
public let cbArmLogged: Bool;

public func CBRearmTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(des) || !IsDefined(player) || !CBWorldStable(game) {
    return;
  }
  let pagent = player.GetAttitudeAgent();
  if !IsDefined(pagent) {
    return;
  }
  let tick = sys.GetTickCount();
  // The street's own people too: only the ones set hostile on purpose carry cbArmTick (a favour's lookout, a gang at
  // war with V), so the rest are left as they are.
  let tags: array<CName> = [n"CB_Squad", n"CB_Escort", n"CB_Apex", n"CB_Rival", n"CB_Scout", n"CB_Lair"];
  for streetTag in CBStreetTags() {
    ArrayPush(tags, streetTag);
  }
  for tag in tags {
    let ids = des.GetTaggedIDs(tag);
    for id in ids {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if IsDefined(p) && p.cbArmTick > 0 && tick - p.cbArmTick <= CBConfig.RearmWatchTicks()
         && p.IsAttached() && CBStillStanding(p) && !p.cbMoraleBroken && !p.cbSurrendered && !p.cbGaveUp && !p.cbFacedownHeld
         && !p.cbFacedownWait && !p.cbTruceHeld {
        let agent = p.GetAttitudeAgent();
        if IsDefined(agent) && NotEquals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
          CBTrace("attitude: one of ours came up neutral; hostile again");
          agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
          if !p.cbArmLogged {
            p.cbArmLogged = true;
            CBLog.Info(n"Spawn", "One of ours came up neutral to you after being set up; set hostile again.");
          }
        }
      }
    }
  }
}

// One of ours is told exactly where V is, which starts the fight. Only ever from the hunt, once V has actually been
// found (CBHuntEngage).
public func CBEngageV(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !CBStillStanding(puppet) || !puppet.IsAttached() {
    return;
  }
  CBTrace("combat: one of ours is told where V is");
  TargetTrackingExtension.InjectThreat(puppet, player);
  CBFairVolley(game, puppet);   // their aim is off for a moment (Spawn/Hunted.reds, [44])
}

// ---- Clearing up after ourselves --------------------------------------------------
//
// Over a long session that is dozens of registered bodies and cars across the city, each one spawned back in whenever V
// passes.
public func CBSweepRemains(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(des) || !IsDefined(player) || !CBWorldStable(game) {
    return;
  }
  let ppos = player.GetWorldPosition();
  let reach = CBConfig.RemainsSweepDistance();

  let dead = sys.GetDeadOurs();
  let i = 0;
  while i < ArraySize(dead) {
    let id = dead[i];
    i += 1;
    let ent = GameInstance.FindEntityByID(game, id);
    let far = !IsDefined(ent)
              || !CBRemainsInReach(game, ent.GetWorldPosition()) && CBOutOfView(game, ent.GetWorldPosition());
    if far && !des.IsSpawning(id) && !VehicleComponent.IsMountedToVehicle(game, id) {
      let p = ent as ScriptedPuppet;
      if IsDefined(p) {
        CBUntrackOnMap(game, p);
      }
      CBTrace("remove: a body of ours");
      des.DeleteEntity(id);
      sys.ForgetDeadOurs(id);
    }
  }

  // Ours who were put down alive and left there: knocked out, a non-lethal takedown. Same rule as a body: only once V
  // is well away and cannot see them.
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Squad");
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Apex");
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Escort");
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Scout");
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Patrol");
  // Not the street's own people (CBStreetTags): each of those is cleared, down or standing, by whatever
  // they were part of when it ends (Spawn/LivingStreet.reds), and one knocked out early has to stay
  // counted until then: a sit-down is crashed by how many of its people are down.

  // Cars: only when no car is on its way or being boarded and nobody of ours is in a seat.
  if sys.HasPendingArrival() || sys.HasConvoyLegs() || CBAnyCrewSeated(game, des) {
    return;   // a convoy still sending cars is a car on its way too
  }
  let cars = des.GetTaggedIDs(n"CB_Car");
  let c = 0;
  while c < ArraySize(cars) {
    let carId = cars[c];
    c += 1;
    let car = GameInstance.FindEntityByID(game, carId);
    let farCar = !IsDefined(car)
                 || Vector4.Distance(car.GetWorldPosition(), ppos) > reach && CBOutOfView(game, car.GetWorldPosition());
    if farCar && !des.IsSpawning(carId) && !Equals(carId, sys.GetArrivalCarId()) {
      CBTrace("remove: a spent car of ours");
      des.DeleteEntity(carId);
    }
  }
}

// Remove anybody wearing this tag who is down but breathing, far from V and out of V's sight.
// Through CBRemoveOne, so a seated or still-spawning body is left for a later pass.
func CBSweepDownedTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                      ppos: Vector4, reach: Float, tag: CName) -> Void {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && CBNpcSafe(sys, p) && !p.IsDead() && !CBStillStanding(p) {
      let at = p.GetWorldPosition();
      if !CBRemainsInReach(game, at) && CBOutOfView(game, at) {
        CBRemoveOne(game, des, id, false, true);
      }
    }
  }
}

// A breadcrumb before each call into the engine that has ever been part of a crash. Written only
// at the Verbose log level, so the last lines before a crash say what Cyberbane was doing.
public func CBTrace(what: String) -> Void {
  CBLog.Verbose(n"Trace", what);
}

// V's companions, by the game's test (ScriptedPuppet.IsPlayerCompanion), among the NPCs Cyberbane already tracks (every
// attached NPC, Reactions/NpcRegistry.reds). Settled ones only.
public func CBPlayerCompanions(sys: ref<CyberbaneSystem>) -> array<wref<ScriptedPuppet>> {
  let out: array<wref<ScriptedPuppet>>;
  let reg = IsDefined(sys) ? sys.GetRegistry() : null;
  if !IsDefined(reg) {
    return out;
  }
  for p in reg.GetAll() {
    if CBNpcSafe(sys, p) && !p.IsDead() && ScriptedPuppet.IsPlayerCompanion(p) {
      ArrayPush(out, p);
    }
  }
  return out;
}

// One of ours and each companion of V's, hostile to each other.
public func CBMakeHostileToCompanions(sys: ref<CyberbaneSystem>, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) {
    return;
  }
  CBMakeHostileToTheseCompanions(sys, puppet, CBPlayerCompanions(sys));
}

// The same, against a list the caller already has (the tick asks once for everybody).
public func CBMakeHostileToTheseCompanions(sys: ref<CyberbaneSystem>, puppet: ref<ScriptedPuppet>,
                                           companions: array<wref<ScriptedPuppet>>) -> Void {
  if !IsDefined(sys) || !CBStillStanding(puppet) || !puppet.IsAttached() {
    return;
  }
  let agent = puppet.GetAttitudeAgent();
  if !IsDefined(agent) {
    return;
  }
  for c in companions {
    if IsDefined(c) && c.IsAttached() {
      let cagent = c.GetAttitudeAgent();
      if IsDefined(cagent) && NotEquals(c.GetEntityID(), puppet.GetEntityID())
         && NotEquals(agent.GetAttitudeTowards(cagent), EAIAttitude.AIA_Hostile) {
        CBTrace("attitude: one of ours and V's companion");
        agent.SetAttitudeTowards(cagent, EAIAttitude.AIA_Hostile);
        cagent.SetAttitudeTowards(agent, EAIAttitude.AIA_Hostile);
      }
    }
  }
}

// The other way: one of ours standing down, and V's companions, neutral to each other both ways.
public func CBCalmTowardCompanions(sys: ref<CyberbaneSystem>, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(puppet) || !puppet.IsAttached() {
    return;
  }
  let agent = puppet.GetAttitudeAgent();
  if !IsDefined(agent) {
    return;
  }
  for c in CBPlayerCompanions(sys) {
    if IsDefined(c) && c.IsAttached() && NotEquals(c.GetEntityID(), puppet.GetEntityID()) {
      let cagent = c.GetAttitudeAgent();
      if IsDefined(cagent) {
        CBTrace("attitude: one of ours and V's companion, standing down");
        agent.SetAttitudeTowards(cagent, EAIAttitude.AIA_Neutral);
        cagent.SetAttitudeTowards(agent, EAIAttitude.AIA_Neutral);
      }
    }
  }
}

// A companion recruited, or streamed in, after ours were set up. Every few settled ticks while any of ours who is
// hostile to V is standing: pairs not yet set are set. Nothing at all without a companion.
public func CBCompanionHostilityTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(des) || !IsDefined(player) || !des.IsPopulated(n"Cyberbane") {
    return;
  }
  let companions = CBPlayerCompanions(sys);
  if ArraySize(companions) == 0 {
    return;
  }
  let pagent = player.GetAttitudeAgent();
  if !IsDefined(pagent) {
    return;
  }
  let ids = des.GetTaggedIDs(n"Cyberbane");
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) && IsDefined(p.GetAttitudeAgent())
       && Equals(p.GetAttitudeAgent().GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
      CBMakeHostileToTheseCompanions(sys, p, companions);
    }
  }
}

// Nobody Cyberbane sends is unkillable.
func CBDisarmGodMode(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let gms = GameInstance.GetGodModeSystem(game);
  if !IsDefined(gms) || !IsDefined(puppet) {
    return;
  }
  let id = puppet.GetEntityID();
  let removed = CBDropGodMode(gms, id, gameGodModeType.Invulnerable) + CBDropGodMode(gms, id, gameGodModeType.Immortal);
  if removed > 0 {
    CBLog.Info(n"Spawn", s"One of ours came from a record the game will not let die; took that off (\(removed)).");
  }
}

func CBDropGodMode(gms: ref<GodModeSystem>, id: EntityID, kind: gameGodModeType) -> Int32 {
  if !gms.HasGodMode(id, kind) {
    return 0;
  }
  let n = 0;
  let sources = gms.GetGodModeSources(id, kind);
  let i = 0;
  while i < ArraySize(sources) {
    CBTrace("stats: god mode off one of ours");
    if gms.RemoveGodMode(id, kind, sources[i]) {
      n += 1;
    }
    i += 1;
  }
  return n;
}
