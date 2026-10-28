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
                   pos: Vector4, orient: Quaternion, squadTag: CName) -> Bool {
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
  return EntityID.IsDefined(des.CreateEntity(spec));
}

// Spawn `count` copies of `record` in a short row behind V. Returns how many were queued.
public func CBSpawnGroup(game: GameInstance, record: TweakDBID, appearance: CName, count: Int32, squadTag: CName, dist: Float) -> Int32 {
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

  // Flat right vector, to spread the row sideways.
  let rx = -fwd.Y;
  let ry = fwd.X;
  let orient = Quaternion.BuildFromDirectionVector(new Vector4(fwd.X, fwd.Y, 0.0, 0.0));

  let spawned = 0;
  let i = 0;
  while i < count {
    let lane = Cast<Float>(i) - Cast<Float>(count - 1) * 0.5;   // centre the row on the base point
    let placed = false;
    let attempt = 0;
    while attempt < 3 {
      let d = dist * CBSpawnDistanceScale(attempt);
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
                           new Vector4(px, py, gz + CBConfig.GroundSpawnLift(), 1.0), orient, squadTag) {
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
      let fx = ppos.X - fwd.X * dist * 0.4 + rx * lane * 2.5;
      let fy = ppos.Y - fwd.Y * dist * 0.4 + ry * lane * 2.5;
      let fallback = new Vector4(fx, fy, ppos.Z, 1.0);
      // The fallback is close in, so it is the likeliest of the lot to land indoors.
      if !CBSafeAreaBlocksSpawn(game, fallback)
         && CBCreateSpawn(des, record, appearance, fallback, orient, squadTag) {
        spawned += 1;
      }
    }
    i += 1;
  }
  return spawned;
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
