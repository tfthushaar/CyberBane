// Cyberbane - Dynamic spawning (spec §9.9, §10; spike S-08)
//
// A thin wrapper over DynamicEntitySystem to drop tagged, non-persistent NPCs into the
// world near V. Spawn points are computed behind V and out of the forward view, and each
// one is put on the floor that is actually under it (see CBGroundAt). Everything is tagged
// n"Cyberbane" so the session-start sweep (DeleteTagged) and the kill switch can always
// clear it, and nothing is written to the save (persistState / persistSpawn /
// alwaysSpawned all false).

// Find the floor under a candidate spawn point.
//
// The spawn offset is flat (X/Y behind V), so the ground under it is frequently not at V's
// own height: a motel walkway, a stairwell, a raised lot, the lip of an overpass. Taking V's
// Z verbatim is what left Rivals and hit squads standing in mid-air until something knocked
// them loose. Trace straight down from just above the guess and take the first solid floor.
//
// Crash safety: this is only reached from CBSpawnGroup, which already stands behind
// CBWorldStable, and it dereferences no entity handles - the query system is checked before
// use, and TraceResult is a value the engine fills in. A miss returns false and the caller
// moves the point rather than placing an NPC blind.
func CBGroundAt(game: GameInstance, x: Float, y: Float, zHint: Float, out ground: Float) -> Bool {
  return CBGroundRay(game, x, y, zHint + CBConfig.GroundProbeUp(), zHint - CBConfig.GroundProbeDown(), ground);
}

// The floor under a point that is already known to be standing room - a navmesh point.
//
// CBGroundAt starts its ray three metres above the guess, which is right for a flat offset
// behind V whose height is only V's own, and wrong for a navmesh point, whose height is the
// answer already. From three metres up the first thing the ray meets can be an awning, a
// ledge, a stair flight or a hoarding above the point, and the old settle step then moved the
// spawn up onto that. This starts just above the point, so it only ever finds what is under it.
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
//
// The question the navmesh alone does not answer. `FindPursuitPointsRange` hands back points
// an agent fits on, and fitting is not the same as being connected to where the player is
// standing: the navmesh runs through the inside of locked buildings and across geometry the
// player has no route to. Points there pass every test this file had, so Rivals turned up
// inside terrain and behind locked doors, which is exactly what was reported.
//
// `CBNavAnchor` has asked this question since it was written, with the same call. The
// pursuit-point path added later never did, which is how the gap opened.
func CBPointReachable(game: GameInstance, from: Vector4, to: Vector4) -> Bool {
  let nav = GameInstance.GetNavigationSystem(game);
  if !IsDefined(nav) {
    return true;   // cannot tell; do not silently refuse every spawn in the game
  }
  let path = nav.CalculatePathOnlyHumanNavmesh(from, to, NavGenAgentSize.Human, 5.0);
  return IsDefined(path) && path.CalculateLength() > 0.0;
}

// Has somebody already been put here?
//
// Belt and braces against the same failure the car seats produced: several entities created at
// one point do not share it, they interpenetrate and the engine stacks them vertically. Three
// sources here can hand back the same place and none of them is wrong to - the fallback list
// from FindPursuitPointsRange when the strict pass finds nothing, a nav snap in an interior
// where every requested offset resolves to the same island, and the bearing sweep when only
// one bearing has floor under it. Checking at the point of use covers all three at once.
// Is this point somewhere the player would watch somebody appear?
//
// "They just pop out of nowhere, like the old police spawns" is the most repeated complaint
// about this mod, and `spawnInView = false` on the entity spec is not the answer to it: that
// flag is advisory and the engine honours it by delaying, not by refusing, so a point directly
// in front of V still ends up occupied a moment later.
//
// Two tests, cheap first. The bearing: anything inside the forward cone is in view unless it
// is far enough away to be a dot on the street. Then line of sight: a point behind a wall is
// fine however close it is, which is what makes tight streets workable at all - most of what
// is within thirty metres of V in Night City is behind something.
//
// The facing threshold is CBNavAnchor's, deliberately. That function has had this test since
// 1.1.5, with the note explaining why it is a cosine rather than an angle; what it never had
// was company. CBPursuitPoints became the primary placement path and never tested facing at
// all, and FindPursuitPointsRange hands back points all round the player, so the common case
// was a body created wherever the navmesh happened to offer one - including directly in front.
// That is the "they pop out of nowhere like the old police spawns" report, and the fix is to
// ask the same question everywhere a point is accepted rather than only at the anchor.
func CBPointOutOfSight(game: GameInstance, ppos: Vector4, fwd: Vector4, at: Vector4) -> Bool {
  let toPoint = new Vector4(at.X - ppos.X, at.Y - ppos.Y, 0.0, 0.0);
  let dist = Vector4.Length(toPoint);
  if dist < 0.5 {
    return false;   // on top of the player
  }
  let flatLen = SqrtF(fwd.X * fwd.X + fwd.Y * fwd.Y);
  if flatLen <= 0.01 {
    // No usable facing, so this test has no opinion. Allowing rather than refusing, because
    // the two failures do not cost the same: a visible arrival is a thing the player can see
    // and report, while a gate that refuses on an unknown answer is how this mod went silent
    // for three releases running.
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

// Could V see a body standing here, whichever way V turns in the next few seconds? (1.7.1)
//
// CBPointOutOfSight is the question for somebody who is about to walk at V, and both of its
// allowances only make sense for them: a point behind V passes with nothing in the way, and so
// does one far off in front, because either way what the player sees is a person walking into
// frame. Somebody who will stand still is different. They are placed at the very spot V is
// heading for, and the body appears a few seconds after the point is chosen, so "behind V" is
// exactly where a player who is looking for them turns next, and "far in front" is the spot they
// are walking towards. That is "he wasn't there, then he spawned in front of me".
//
// So this asks about walls, not about facing. A body is hidden only when V's line of sight to
// it is blocked at the shins, the waist and the top of the head: one ray let a lamp post or a
// railing count as cover. Turning on the spot changes nothing a wall decides. The one
// allowance kept is the distant one, out of frame and far enough to be a dot on the street.
//
// No spatial queries at all is no opinion, as everywhere in this file, and falls back to the
// bearing test rather than refusing every placement for good.
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

func CBPointIsFree(used: array<Vector4>, p: Vector4) -> Bool {
  let i = 0;
  while i < ArraySize(used) {
    if Vector4.Distance(used[i], p) < CBConfig.SpawnMinSeparation() {
      return false;
    }
    i += 1;
  }
  return true;
}

// Stand a candidate navmesh point on the floor under it, or refuse it.
//
// A navmesh point is meant to be standing room, and nearly always is. Nearly is not good
// enough. FindPursuitPointsRange also returns a fallback list for when the strict pass finds
// nothing, and in the vertical parts of the city - the walkways and decks around City Center,
// overpasses, the lip of a ramp - a point can sit well above whatever is actually underneath
// it. So every point is checked for a floor beneath it, and one over a drop is refused.
//
// What this no longer does is move the point. It used to re-seat every spawn at the raycast
// floor plus 0.35 m, and that was the floating Rival. A spawned NPC is not dropped by physics
// on arrival: it stands at the height it was created at until its movement puts it on the
// navmesh or a hit reaction ragdolls it. One that never needs to walk anywhere - a Rival that
// spawns close and opens fire where it stands - hovers there until enough damage knocks it
// over, which is exactly the report. The game's own pursuers (PreventionSystem, which takes
// its points from the same FindPursuitPointsRange) are created on the navmesh point as given,
// and that is what is done here: the navmesh height, or the floor if the floor is a hair
// higher, so nobody starts inside the surface either.
func CBSettleOnGround(game: GameInstance, p: Vector4, out at: Vector4) -> Bool {
  let ground = 0.0;
  if !CBFloorUnder(game, p, ground) {
    return false;
  }
  // A floor a long way below the point is not this point's floor.
  if p.Z - ground > CBConfig.SpawnGroundSettle() {
    return false;
  }
  at = new Vector4(p.X, p.Y, MaxF(p.Z, ground) + CBConfig.NavSpawnClearance(), 1.0);
  return true;
}

// Put a point found by raycast alone onto the navmesh under it, or refuse it.
//
// The bearing sweep and the last-resort fallback find a floor by raycast and nothing else, and
// used to create the NPC at that floor plus a lift. A body made off the navmesh hovers at that
// lift for the reason given above, and cannot path toward V either, so it stands there in the
// air. The point is now snapped to the navmesh directly under it; one with no navmesh close
// underneath is refused like any other bad point, and the lane tries again shortly.
//
// Only when the navigation system cannot be asked at all is the old placement kept, so a world
// state this cannot read still gets its arrival rather than going silent.
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
//
// The raycast above answers "is there a floor here". That is not the same question as "can a
// person stand here and then reach V", and the gap between the two is where the bad arrivals
// came from: a spawn on the far side of a wall, on a balcony across the street, inside a
// sealed lot. The navmesh answers the real question, because it is the same data the NPC's own
// pathfinder uses - if a point is on it, somebody can stand there and walk off it.
//
// Three tests, in order: find a point on the navmesh the requested distance away from V,
// confirm a walkable path from it back to V, and prefer it behind V so the arrival is not
// conjured in full view. Returns false if the area has no navmesh at all, which happens
// indoors and in some interiors, and the caller falls back to the raycast.
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
        // The navmesh call honours the distance but not the direction, so the point can come
        // back in front of V. That matters because the spawn itself is queued with
        // spawnInView = false: a point in view is not refused loudly, it is quietly never
        // placed, and the caller is told an entity was created. So the view test has to
        // happen here, before anything is queued.
        //
        // Compared as a dot product rather than through GetAngleBetween, because that returns
        // either degrees or radians and I have not verified which. A threshold of 70 against
        // the wrong unit is never satisfied, which would silently disable this whole test and
        // drop every spawn back to the raycast fallback - the failure would look like nothing
        // at all. The cosine has no units to get wrong: cos(70 degrees) is about 0.342, and a
        // point off to the side or behind V gives a value at or below it.
        let toPoint = new Vector4(found.X - ppos.X, found.Y - ppos.Y, 0.0, 0.0);
        let away = Vector4.Length(toPoint);
        let facing = 1.0;
        if away > 0.01 {
          let flatLen = SqrtF(fwd.X * fwd.X + fwd.Y * fwd.Y);
          if flatLen > 0.01 {
            facing = (fwd.X * toPoint.X + fwd.Y * toPoint.Y) / (flatLen * away);
          }
        }
        if facing <= CBConfig.SpawnMaxFacingCosine() && away >= CBConfig.SpawnMinDistance()
           && AbsF(found.Z - ppos.Z) <= CBConfig.GroundMaxDrop() {
          // A point they cannot walk from is a point they will stand on forever.
          let path = nav.CalculatePathOnlyHumanNavmesh(found, ppos, NavGenAgentSize.Human, 5.0);
          if IsDefined(path) && path.CalculateLength() > 0.0 {
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
//
// Used for the individual ranks once the group's anchor is settled, so a squad stays together
// instead of each member going looking for its own corner of the district. A snap that lands
// far from where it was asked for is refused: that means the nearest navmesh is somewhere else
// entirely, and taking it would scatter the squad.
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

// How far out to try, as a fraction of the requested distance. A spot with no floor under it
// (a drop behind V, the far side of a wall) walks the point back toward V, where the ground is
// the ground V is standing on, instead of silently cancelling the encounter.
func CBSpawnDistanceScale(attempt: Int32) -> Float {
  if attempt <= 0 {
    return 1.0;
  }
  if attempt == 1 {
    return 0.66;
  }
  return 0.4;
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
  return EntityID.IsDefined(created);
}

// Spawn `count` copies of `record` in a short row behind V. Returns how many were queued.
// `lastSpawned` comes back as the entity of the last one placed, so a caller that cares about
// a single arrival (a Rival) can hold onto it and attribute the kill later without relying on
// the tag still being there.
// Ask the game where a pursuer could stand.
//
// This is what the police use. `PreventionSystem.SpawnFallbackUnits` gets its positions from
// `FindPursuitPointsRangeAsync`, and the synchronous form of the same thing lives on the
// NavigationSystem, so there is no callback to plumb. It walks the navmesh around the player
// and hands back points an agent of a given size can actually stand on, plus a fallback list
// for when the strict pass finds nothing.
//
// Everything this mod did before was an approximation of this: probe the ground behind V, snap
// to navmesh, retry at a few distances, sweep some bearings. All of it was reinventing, badly,
// a function the game already exports - which is why an encounter could be refused for minutes
// while the NCPD put a squad on the same street without difficulty.
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
  // The strict pass can come back empty in tight streets and interiors. The fallback list is
  // the game's own second answer rather than ours, so it is still a place the navmesh says a
  // person fits.
  if ArraySize(pts) == 0 {
    pts = fallback;
  }
  return ArraySize(pts) > 0;
}

// Which way to look on this attempt, in radians from directly behind V.
//
// Behind, then a quarter turn each way, then wider, then in front as a last resort. Ordered so
// the common case still puts them at V's back and the player is not spawned in front of unless
// there is nowhere else at all.
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

public func CBSpawnGroup(game: GameInstance, record: TweakDBID, appearance: CName, wanted: Int32, squadTag: CName, baseDist: Float, out lastSpawned: EntityID, opt extraTag: CName) -> Int32 {
  // Further out on harder difficulties, so there is more time between a warning and a fight.
  let dist = baseDist + CBConfig.DifficultySpawnExtra() * Cast<Float>(CBDifficultyLevel());
  // Never more of ours alive at once than the ceiling. A vendetta crew of twenty on top of an
  // apex squad, escorts and a Rival is a lot of fully simulated NPCs for the game to stream in
  // at one spot, and nothing about the fight needs every one of them at the same moment.
  // Counting anybody still spawning as well, so groups asked for in the same tick share it.
  let room = CBSpawnRoom(game);
  let count = wanted < room ? wanted : room;
  if room <= 0 {
    CBLog.Info(n"Spawn", s"Already \(CBConfig.MaxLiveSpawns()) of ours in the world; nobody else is sent until some are gone.");
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
  // Assume the worst and clear it on success, so a silent refusal cannot look like a success.
  CBNoteSpawnBlock(CBBlockNoGround());

  // The game's own answer first. If the navmesh offers places to stand, use them and skip the
  // hand-rolled probing entirely; it is only there for when this comes back with nothing.
  let navPts: array<Vector4>;
  if CBPursuitPoints(game, ppos, fwd, count, dist * 0.6, dist * 1.6, navPts) {
    let n = 0;
    while n < ArraySize(navPts) && spawned < count {
      let p = navPts[n];
      n += 1;
      let at: Vector4;
      // The first body of a group is path-checked against V. The rest only have to form up
      // near it, which is both cheaper than a path calculation each and better behaviour:
      // a squad that arrives together reads as a squad. If the first point is connected to
      // the player and the others are within sight of it, so are they.
      let ok = CBSettleOnGround(game, p, at) && CBPointIsFree(used, at)
               && !CBSafeAreaBlocksSpawn(game, at);
      // Nobody appears where the player is looking. Only the first body of a group is tested:
      // the rest form up within SpawnGroupRadius of it, so if the lead is out of frame so are
      // they, and a squad that arrives together is the point of forming up at all.
      if ok && ArraySize(used) == 0 {
        ok = CBPointOutOfSight(game, ppos, fwd, at);
      }
      if ok {
        if ArraySize(used) == 0 {
          ok = CBPointReachable(game, at, ppos);
        } else {
          ok = Vector4.Distance(at, used[0]) <= CBConfig.SpawnGroupRadius();
        }
      }
      if ok {
        let facing = Quaternion.BuildFromDirectionVector(
          Vector4.Normalize2D(new Vector4(ppos.X - at.X, ppos.Y - at.Y, 0.0, 0.0)));
        if CBCreateSpawn(des, record, appearance, at, facing, squadTag, lastSpawned, extraTag) {
          spawned += 1;
          ArrayPush(used, at);
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
         && CBPointIsFree(used, standing) && !CBSafeAreaBlocksSpawn(game, standing)
         && (ArraySize(used) > 0 || (CBPointReachable(game, standing, ppos)
                                     && CBPointOutOfSight(game, ppos, fwd, standing))) {
        if CBCreateSpawn(des, record, appearance, standing, orient, squadTag, lastSpawned, extraTag) {
          spawned += 1;
          ArrayPush(used, standing);
        }
        placed = true;
      }
    }
    // Sweep around V rather than staring at one spot.
    //
    // Behind the player first, because that is where an arrival should come from, then wider
    // and wider to either side and finally in front. Only the direction changes; the ground,
    // safe area and drop checks are exactly as strict as before, so this finds more places to
    // stand without lowering the bar for what counts as one.
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
      // An apartment, a bar, a clinic. The game forces V's hands empty in there, so an
      // arrival is a fight the player cannot have (spec §16). Off unless they ask for it.
      // Nested rather than skipped with a continue, which redscript does not have.
      if !CBSafeAreaBlocksSpawn(game, new Vector4(px, py, ppos.Z, 1.0)) {
        // A floor far above or below V is another level entirely - a roof, the bottom of a
        // shaft - so it is refused and the point moves in rather than dropping someone there.
        let stand: Vector4;
        if CBGroundAt(game, px, py, ppos.Z, gz) && AbsF(gz - ppos.Z) <= CBConfig.GroundMaxDrop()
           && CBStandOnNavmesh(game, px, py, gz, stand) {
          if CBPointIsFree(used, stand)
             && (ArraySize(used) > 0 || (CBPointReachable(game, stand, ppos)
                                         && CBPointOutOfSight(game, ppos, fwd, stand)))
             && CBCreateSpawn(des, record, appearance, stand, orient, squadTag, lastSpawned, extraTag) {
            spawned += 1;
            ArrayPush(used, stand);
          } else {
            CBNoteSpawnBlock(CBBlockEngineRefused());
          }
          placed = true;
          break;   // this lane is placed, or the engine refused it; either way stop retrying
        }
      }
      attempt += 1;
    }
    // Last resort: close in, and still on a floor.
    //
    // This used to take V's own height and place somebody there with no check at all. On flat
    // ground that is fine; standing on a walkway, a bridge, a ramp or anywhere with a drop
    // behind you, it puts an enemy in the air over the gap - which is the mid-air spawn that
    // kept being reported after the other causes were fixed.
    //
    // It refuses now instead of guessing. The reason it was allowed to guess was that a
    // refusal used to mean the encounter was silently lost; it no longer does - the lane keeps
    // its turn and tries again shortly - so there is nothing left to buy by placing blind.
    if !placed {
      let fx = ppos.X - fwd.X * (dist * 0.4 + rankBack) + rx * lane * 2.5;
      let fy = ppos.Y - fwd.Y * (dist * 0.4 + rankBack) + ry * lane * 2.5;
      let fz: Float;
      let fallback: Vector4;
      if CBGroundAt(game, fx, fy, ppos.Z, fz) && AbsF(fz - ppos.Z) <= CBConfig.GroundMaxDrop()
         && CBStandOnNavmesh(game, fx, fy, fz, fallback) {
        // The fallback is close in, so it is the likeliest of the lot to land indoors and the
        // likeliest to land in frame. It refuses rather than guessing on both counts now; the
        // lane keeps its turn and tries again shortly, so there is nothing to buy by placing
        // somebody where the player watches them appear.
        //
        // It also has to be a free spot and, for the first body, one V can walk to. Neither was
        // checked here, so two bodies could be dropped on one point (the engine then stacks them
        // vertically) or the first could land somewhere sealed off from V.
        if !CBSafeAreaBlocksSpawn(game, fallback)
           && CBPointOutOfSight(game, ppos, fwd, fallback)
           && CBPointIsFree(used, fallback)
           && (ArraySize(used) > 0 || CBPointReachable(game, fallback, ppos))
           && CBCreateSpawn(des, record, appearance, fallback, orient, squadTag, lastSpawned, extraTag) {
          spawned += 1;
          ArrayPush(used, fallback);
        } else {
          CBNoteSpawnBlock(CBBlockInView());
        }
      } else {
        CBNoteSpawnBlock(CBBlockNoGround());
      }
    }
    i += 1;
  }
  if spawned > 0 {
    CBNoteSpawnBlock(CBBlockNone());
  } else {
    CBLog.Info(n"Spawn", s"Nothing could be placed: \(CBBlockLabel(CBLastSpawnBlock())).");
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
//
// Without this they are hostile but idle: the game only hands a spawned NPC a reason to move
// if something gives it one, so Cyberbane's arrivals would stand where they were put until V
// happened to walk into their line of sight. That is the single biggest reason the mod could
// feel like nothing was happening - the encounter had spawned, forty metres back, behind a
// wall, waiting. A sprint order at V turns an arrival into an encounter.
//
// `ignoreInCombat` and `finishWhenDestinationReached` are what keep this from fighting the
// game's own combat AI: the command runs until they reach V and then releases, and normal
// combat behaviour takes over from there.
public func CBOrderHunt(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !IsDefined(puppet) {
    return;
  }
  let ai = puppet.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  let cmd = new AIMoveToCommand();
  let dest: AIPositionSpec;
  let wp: WorldPosition;
  WorldPosition.SetVector4(wp, player.GetWorldPosition());
  AIPositionSpec.SetWorldPosition(dest, wp);
  // Following the entity rather than the position means they keep coming if V moves off.
  AIPositionSpec.SetEntity(dest, player);
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
// The game sends a script order to an NPC once, through the AI component
// (AIComponent.SendCommand, core/components/aiComponent.script). Cyberbane sent every move order
// twice, once as an AICommandEvent and once through SendCommand, and the hunt re-issues orders
// every few seconds without ever cancelling the last one, so an NPC that could not reach its
// target collected a growing queue of the same command object entered twice. Each NPC now has
// at most one Cyberbane move order outstanding: the previous one is cancelled before the next
// is sent, and it is sent once.
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
  let ai = puppet.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  CBCancelMove(puppet);
  puppet.cbUnmountSent = true;
  CBTrace("vehicle: ordering an NPC out of a car");
  ai.SendCommand(new AIUnmountCommand());
}

// ---- Taking things out of the world ---------------------------------------------
//
// Every removal goes through here. DeleteTagged removed whatever carried the tag at that moment,
// including an NPC sitting in a car seat and one the engine was still in the middle of
// spawning. Neither is a state the game removes its own NPCs from. Those are skipped: they lose
// the tag they were being removed for, so the lane that was waiting on them is free at once, and
// they are marked CB_Orphan, which the slow tick clears once they are out of the car and fully
// spawned (CBSweepOrphans). A car is only removed when none of Cyberbane's crew is still seated.
// Map markers come off before anything is removed.
//
// `livingOnly` leaves bodies where they are. A body that has just fallen may still be ragdolling
// in front of V; bodies are cleared by CBSweepRemains once V is well away from them.
// `unseenOnly` is for the endings a player is watching: somebody who broke off and ran, or who
// was let go. Those used to be deleted the instant the escape resolved, which is the "he just
// vanished in front of my eyes" report - the enemy really did run, and then the mod took the
// body away while it was still on screen. With it set, anybody V can still see is handed to the
// CB_Orphan sweep instead, which already removes only what is out of view (CBSweepOrphans), so
// they finish running off and go once nobody is watching.
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
  } else {
    let p = ent as ScriptedPuppet;
    if IsDefined(p) {
      if VehicleComponent.IsMountedToVehicle(game, id) {
        CBUnmountOnce(game, p);
        return false;
      }
      CBUntrackOnMap(game, p);
      CBCancelMove(p);
    }
  }
  CBTrace("remove: one of ours");
  des.DeleteEntity(id);
  return true;
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
    if !IsDefined(ent) || CBOutOfView(game, ent.GetWorldPosition()) {
      CBRemoveOne(game, des, ids[i], crewSeated);
    }
    i += 1;
  }
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
//
// Scheduled from the attach callback instead of running there. See the note at the call site:
// at attach time the puppet has no attitude agent and no AI controller, so every call below
// would fail silently and leave a spawned enemy standing around as whatever record it came
// from. Retries a few times, because how long the components take is not fixed.
public class CBSpawnSetupCallback extends DelayCallback {
  public let entityId: EntityID;
  public let riding: Bool;
  public let tries: Int32;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    // Not while the world is loading or streaming: everything below writes attitude, stats and
    // orders on a native puppet, which is the crash this whole mod's tick is gated against.
    // Waiting for a settled moment does not use up the tries meant for slow components.
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let ds = GameInstance.GetDelaySystem(game);
        if IsDefined(ds) {
          let again = new CBSpawnSetupCallback();
          again.entityId = this.entityId;
          again.riding = this.riding;
          again.tries = this.tries;
          again.waits = this.waits + 1;
          ds.DelayCallback(again, CBConfig.SpawnSetupRetrySeconds(), false);
        }
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
        CBLog.Info(n"Spawn", "A spawned enemy never finished initialising; it will behave as its own kind.");
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
//
// That event stands down when the world is not stable, which is right for the event and wrong for
// the NPC: nothing asks again, so anybody of ours who attached while V had a menu open, took a call
// or sat through a scene was never made hostile, never marked, never ordered anywhere and never
// kitted. They stood there as whatever they were spawned as, counted as a hunter, for the rest of
// the encounter. The setup has its own wait for a settled world, so this only has to start it.
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
    if IsDefined(p) && p.IsAttached() && !p.cbSetupQueued && !p.IsDead() {
      p.cbSetupQueued = true;
      let riding = des.IsTagged(id, n"CB_Crew");
      if riding {
        CBScheduleConvoyMount(game, id);
      }
      CBScheduleSpawnSetup(game, id, riding);
      CBLog.Info(n"Spawn", "One of ours attached while the world was busy; setting them up now.");
    }
  }
}

// Everything that makes one of ours behave like one of ours.
public func CBApplySpawnSetup(sys: ref<CyberbaneSystem>, game: GameInstance,
                              puppet: ref<ScriptedPuppet>, riding: Bool) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !IsDefined(puppet) {
    return;
  }
  let id = puppet.GetEntityID();
  // An apex escort fights as rank and file, so it takes the squad's kit.
  let isSquad = des.IsTagged(id, n"CB_Squad") || des.IsTagged(id, n"CB_Escort") || des.IsTagged(id, n"CB_Scout");
  let isRival = des.IsTagged(id, n"CB_Rival");
  let isApex = des.IsTagged(id, n"CB_Apex");
  // A Rival waiting at their own place for V to come to them (Rivals/Whereabouts.reds). Set up
  // like any Rival, except that nobody tells them to go anywhere.
  let isLair = des.IsTagged(id, n"CB_Lair");
  if !isSquad && !isRival && !isApex && !isLair {
    return;
  }
  // Aggressive first, because the rest of it depends on being aggressive.
  //
  // This is the piece that was missing, and it comes from how the game marks its own pursuers
  // rather than from anything invented here. `prevention_unit_base` is the record every NCPD
  // chase unit descends from, and its android variant carries `abilities += [
  // "Ability.IsAggressive" ]`; the gang faction records (Arasaka, Scavengers, Tyger Claws,
  // Wraiths) carry the same thing. That ability is backed by an `IsAggressive` stat flag, and
  // `AIActionHelper.TryChangingAttitudeToHostile` checks exactly that flag before it will
  // change anybody's attitude - it returns false and does nothing otherwise.
  //
  // An ordinary ganger plucked out of a crowd record does not have it, so everything downstream
  // was being asked of an NPC the game still considered passive. Granted here through the same
  // RPGManager path the role kits already use, rather than by copying the record, because the
  // records we spawn from are sampled at runtime and cannot be edited.
  CBGrantAbility(puppet as NPCPuppet, t"Ability.IsAggressive");
  CBMakeHostileToPlayer(game, puppet);
  // Hostile is not the same as coming for you. Anybody in a car is excepted: the car travels.
  // Where they go is the hunt's business: toward where V was last known, until somebody finds V
  // (Spawn/Hunt.reds).
  // Not one waiting at their place: hostile, so they fight when they see V, and otherwise left
  // exactly where they were put. No order at all is the whole of the waiting.
  if !riding && !isLair {
    CBOrderPursue(sys, game, puppet);
  }
  if isApex {
    CBApplyApexBuff(sys, game, puppet);
    // Which chair: the one this body was spawned for, when it carries the tag that says so,
    // otherwise the next one round. Only taken once, so a body that attaches twice does not
    // spend a second chair and push everyone after it out of step.
    if !puppet.cbKitted {
      let seat = CBTaggedApexSeat(des, id);
      if seat < 0 {
        seat = sys.NextApexRole();
      }
      CBKitApexSeat(puppet, seat);
    }
    CBShowBossBar(puppet);
  }
  // A marker on everyone the mod sends.
  //
  // This was Rivals and apex squad members only, on the reasoning that a crew arrives together
  // and is obvious the moment it opens fire. It is not obvious. A player hunting for whoever
  // the mod had just announced found nothing on the minimap, because the one standing there
  // was crew and crew carried no marker, and there is no way to tell from outside that the
  // marker is missing by design rather than broken. If Cyberbane sent them, the player can see
  // where they are; the setting turns the lot off for anyone who would rather hunt.
  CBTrackOnMap(game, puppet);
  if isSquad {
    CBKitSquadMember(puppet);
  }
  if isApex || isSquad {
    CBJoinSquadWith(sys, puppet);
  }
  if isRival || isLair {
    // Whose body this is. The body recorded at spawn is the exact answer, and the only one for a
    // Rival waiting at their place, who is nobody's active encounter. For one sent after V the
    // active Rival is the same person and stays the fallback for a body that was not recorded.
    let who = CBFindRivalByBody(sys, id);
    if !IsDefined(who) && !isLair {
      who = sys.FindRivalById(sys.GetActiveRivalId());
    }
    // Their name in the scanner (UI/ScannerName.reds).
    CBMarkRivalBody(puppet, who);
    // A named enemy that never uses cover or chrome is a ganger with a nameplate. A cyberpsycho
    // takes the lighter kit, which adds no armour on top of what they already have.
    if IsDefined(who) && CBRecordIsSightingCyberpsycho(who.recordID) {
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
      if !isLair && CBRivalGrade(who) >= CBConfig.RivalBossBarGrade() {
        CBShowBossBar(puppet);
      }
    }
  }
  CBLog.Info(n"Spawn", "One of ours is up and coming for you.");
}

// The chase used to be kept going here by handing every hunter V's position every few seconds,
// which is why nobody could ever lose them. Spawn/Hunt.reds owns that now: hunters search, find V
// by sight or sound, and give up when V stays gone. The helpers below are shared with it.

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
func CBChaseGiveUp(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>) -> Void {
  sys.SetChaseAwayTicks(0);
  // A Rival you shook takes it personally and comes back harder; the rest simply lose you.
  if CBLiveRivalPresent(sys, game) {
    CBRivalEscapedByPlayer(sys, game);
  }
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
  sys.SetHuntEnd("LOST THEM", CBConfig.HuntEndLineTicks());
  if crewLost && NotEquals(ranFrom, n"") {
    let fs = sys.FindFaction(ranFrom);
    if IsDefined(fs) {
      fs.renown = ClampF(fs.renown - CBConfig.RunRenownLoss(), 0.0, 100.0);
      fs.lastHitSquadAt = CBGameSeconds(game);
    }
    if CBToastsOn() && CBFactionFieldsSquads(ranFrom) {
      CBPhoneFromGangFinal(game, ranFrom, "Ran, did you. Everybody is going to hear about that.");
    }
  }
  // Take the bars down with them, rather than leaving them up for the tick it would take the
  // stack to notice its targets had stopped existing.
  sys.GetThreatBar().Hide();
  sys.SetActiveRivalId(0);
  sys.SetActiveSquadFaction(n"");
  if CBToastsOn() && !crewLost {
    CBPhoneFromStreet(game, "They lost you. Do not go back the way you came.");
  }
  CBLog.Info(n"Spawn", "Player outran the encounter; hunters gave up.");
}

// One of a crew V gave the slip comes back with a name (spec §9.9 / §10.2).
//
// This used to live in the hit squad's timed sweep, which fired on the in-game clock whether or
// not V had escaped anybody - usually in the middle of the fight - and made the Rival out of the
// gang's sample record rather than out of anybody who had been there. It happens now at the one
// moment the promise in the readme describes: the hunt has given up because V lost them. The
// survivor is a real member of the crew that was standing when it did, so the Rival who comes
// back is somebody V met, and the spot they were standing on is where the street saw them last
// (Rivals/Whereabouts.reds).
func CBCrewSurvivorTakesItPersonally(sys: ref<CyberbaneSystem>, game: GameInstance,
                                     des: ref<DynamicEntitySystem>, faction: CName) -> Void {
  if !IsDefined(sys) || !IsDefined(des) || Equals(faction, n"") || !CBRivalsOn() {
    return;
  }
  if RandF() >= CBConfig.RivalChanceHunter() {
    return;
  }
  let ids = des.GetTaggedIDs(n"CB_Squad");
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
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
//
// `Character_Record.BaseAttitudeGroup` is the group the engine would have assigned had the NPC
// come out of a world encounter rather than out of DynamicEntitySystem, so this is the game's
// own answer and not a list of group names typed out from memory - which could not be verified
// offline anyway, since the attitude groups live in a binary resource rather than in the
// shipped tweak text.
//
// Explicitly NOT 'HostileToEveryone', which is the group `AIActionHelper.TargetAllSquadMembers`
// assigns and the obvious-looking thing to reach for. That action exists to turn an NPC on its
// own squad: everyone means everyone, so a Cyberbane crew of six would have opened fire on each
// other on arrival.
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
    //
    // A player reported Valentinos opening fire inside an Animals nest while every Animal in
    // the room ignored it, which reads as the mod spawning ghosts. The cause is that an NPC
    // created with DynamicEntitySystem gets no attitude group unless the record gives it one,
    // and an agent with no group has no relationship with anybody: the game's own gang-versus-
    // gang attitudes are defined between groups, so with one side ungrouped there is nothing
    // to look up and the answer is neutral both ways.
    //
    // Keeping the record's own group when it has one, and falling back to the faction's name,
    // hands the lookup back to the game. Unsavable because these are throwaway NPCs and their
    // group has no business being written into anybody's save.
    if !IsNameValid(agent.GetAttitudeGroup()) {
      let group = CBRecordAttitudeGroup(puppet.GetRecordID());
      if IsNameValid(group) {
        agent.SetAttitudeGroupUnsavable(group);
      }
    }
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
  }
  // Hostile, and nothing more. They are not handed V as a target here.
  //
  // This used to inject V into their target tracker the moment they were set up, so that a
  // spawned enemy had somebody to fight before its own perception had picked V up. The game
  // counts V as in combat whenever any hostile is tracking V (playerCombatController.script,
  // m_isTracked), wherever that hostile is - so from the instant a crew was placed, ninety metres
  // off and out of sight, V was in combat: the phone refused to open ("you can't do that right
  // now"), saving and fast travel were locked, and the hunt's own "searching for you" was a fight
  // in all but name, because everybody already knew exactly where V was. A Rival waiting at their
  // place knew V was coming the moment they were placed, which is not an ambush.
  //
  // What gives them V now is the hunt finding V (Spawn/Hunt.reds, CBHuntEngage): the moment one
  // of them has eyes on V, or hears V fighting, everybody close is told where V is. Until then they
  // search, and if they walk into V's line of sight the game's own perception starts the fight,
  // because they are hostile and aggressive.
}

// One of ours is told exactly where V is, which starts the fight. Only ever from the hunt, once V
// has actually been found (CBHuntEngage). The game's own call for it (targetTrackingComponent
// .script), which does nothing if V is already on their tracker.
public func CBEngageV(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !CBStillStanding(puppet) || !puppet.IsAttached() {
    return;
  }
  CBTrace("combat: one of ours is told where V is");
  TargetTrackingExtension.InjectThreat(puppet, player);
}

// ---- Clearing up after ourselves --------------------------------------------------
//
// Everything Cyberbane spawns is a managed entity that stays registered until it is removed, and
// before 1.5.2 two kinds never were for the rest of the session: the bodies of anyone killed, and
// the car every convoy arrived in. Over a long session that is dozens of registered bodies and
// cars across the city, each one spawned back in whenever V passes. This clears them on the slow
// tick, through the same safe removal as everything else, once V is far enough away that nothing
// can be seen to vanish: a body V might still loot, or a car somebody is still sitting in, stays.
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
              || Vector4.Distance(ent.GetWorldPosition(), ppos) > reach && CBOutOfView(game, ent.GetWorldPosition());
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

  // Ours who were put down alive and left there: knocked out, a non-lethal takedown. They never
  // reach the death handler, so they are not in the list above, and until 1.6.3 the only thing
  // that ever cleared them was the crew's timed despawn - which is gone because it was also
  // deleting crews in the middle of fights. Same rule as a body: only once V is well away and
  // cannot see them. Rivals are left to their own endings (the mercy path closes those), and a
  // waiting Rival's place has its own sweep (Rivals/Whereabouts.reds).
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Squad");
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Apex");
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Escort");
  CBSweepDownedTag(sys, game, des, ppos, reach, n"CB_Scout");

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
      if Vector4.Distance(at, ppos) > reach && CBOutOfView(game, at) {
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
