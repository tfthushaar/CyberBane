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
  let sqs = GameInstance.GetSpatialQueriesSystem(game);
  if !IsDefined(sqs) {
    return false;
  }
  let from = new Vector4(x, y, zHint + CBConfig.GroundProbeUp(), 1.0);
  let to = new Vector4(x, y, zHint - CBConfig.GroundProbeDown(), 1.0);
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
        let toPoint = new Vector4(found.X - ppos.X, found.Y - ppos.Y, 0.0, 0.0);
        let flatFwd = new Vector4(fwd.X, fwd.Y, 0.0, 0.0);
        let angle = Vector4.GetAngleBetween(flatFwd, toPoint);
        let away = Vector4.Length(toPoint);
        if angle >= CBConfig.SpawnMinViewAngle() && away >= CBConfig.SpawnMinDistance() {
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
                   pos: Vector4, orient: Quaternion, squadTag: CName, out created: EntityID) -> Bool {
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
  spec.tags = tags;
  created = des.CreateEntity(spec);
  return EntityID.IsDefined(created);
}

// Spawn `count` copies of `record` in a short row behind V. Returns how many were queued.
// `lastSpawned` comes back as the entity of the last one placed, so a caller that cares about
// a single arrival (a Rival) can hold onto it and attribute the kill later without relying on
// the tag still being there.
public func CBSpawnGroup(game: GameInstance, record: TweakDBID, appearance: CName, count: Int32, squadTag: CName, dist: Float, out lastSpawned: EntityID) -> Int32 {
  if !TDBID.IsValid(record) || count <= 0 {
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
  let i = 0;
  while i < count {
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
      if CBNavSnap(game, ax, ay, baseZ, snapped) && !CBSafeAreaBlocksSpawn(game, snapped) {
        if CBCreateSpawn(des, record, appearance, snapped, orient, squadTag, lastSpawned) {
          spawned += 1;
        }
        placed = true;
      }
    }
    let attempt = 0;
    while attempt < 3 && !placed {
      let d = dist * CBSpawnDistanceScale(attempt) + rankBack;
      let px = ppos.X - fwd.X * d + rx * lane * 2.5;
      let py = ppos.Y - fwd.Y * d + ry * lane * 2.5;
      let gz: Float;
      // An apartment, a bar, a clinic. The game forces V's hands empty in there, so an
      // arrival is a fight the player cannot have (spec §16). Off unless they ask for it.
      // Nested rather than skipped with a continue, which redscript does not have.
      if !CBSafeAreaBlocksSpawn(game, new Vector4(px, py, ppos.Z, 1.0)) {
        // A floor far above or below V is another level entirely - a roof, the bottom of a
        // shaft - so it is refused and the point moves in rather than dropping someone there.
        if CBGroundAt(game, px, py, ppos.Z, gz) && AbsF(gz - ppos.Z) <= CBConfig.GroundMaxDrop() {
          if CBCreateSpawn(des, record, appearance,
                           new Vector4(px, py, gz + CBConfig.GroundSpawnLift(), 1.0), orient, squadTag, lastSpawned) {
            spawned += 1;
          }
          placed = true;
          break;   // this lane is placed, or the engine refused it; either way stop retrying
        }
      }
      attempt += 1;
    }
    // Last resort: put them in close, at V's own height. This is the pre-0.1.15 behaviour and
    // it can look wrong on a ledge, but a trace that finds nothing must not mean nobody ever
    // arrives - that silently disables Rivals, hit squads and apex hunters all at once, which
    // is a far worse bug than an awkward entrance.
    if !placed {
      let fx = ppos.X - fwd.X * (dist * 0.4 + rankBack) + rx * lane * 2.5;
      let fy = ppos.Y - fwd.Y * (dist * 0.4 + rankBack) + ry * lane * 2.5;
      let fallback = new Vector4(fx, fy, ppos.Z, 1.0);
      // The fallback is close in, so it is the likeliest of the lot to land indoors.
      if !CBSafeAreaBlocksSpawn(game, fallback)
         && CBCreateSpawn(des, record, appearance, fallback, orient, squadTag, lastSpawned) {
        spawned += 1;
      }
    }
    i += 1;
  }
  return spawned;
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
  let evt = new AICommandEvent();
  evt.command = cmd;
  puppet.QueueEvent(evt);
  ai.SendCommand(cmd);
}

// Make a spawned NPC hostile toward V. Called when a CB_Squad / CB_Rival puppet attaches.
public func CBMakeHostileToPlayer(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !IsDefined(puppet) {
    return;
  }
  let agent = puppet.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) {
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
  }
}
