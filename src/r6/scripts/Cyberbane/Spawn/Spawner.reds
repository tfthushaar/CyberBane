// Cyberbane - Dynamic spawning (spec §9.9, §10; spike S-08)
//
// A thin wrapper over DynamicEntitySystem to drop tagged, non-persistent NPCs into the
// world near V. Spawn points are computed behind V and out of the forward view; navmesh
// snapping is left to the game (tuned in-game). Everything is tagged n"Cyberbane" so the
// session-start sweep (DeleteTagged) and the kill switch can always clear it, and nothing
// is written to the save (persistState / persistSpawn / alwaysSpawned all false).

// Spawn `count` copies of `record` in a short row behind V. Returns how many were queued.
public func CBSpawnGroup(game: GameInstance, record: TweakDBID, appearance: CName, count: Int32, squadTag: CName) -> Int32 {
  if !TDBID.IsValid(record) || count <= 0 {
    return 0;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(des) || !IsDefined(player) {
    return 0;
  }
  let ppos = player.GetWorldPosition();
  let fwd = player.GetWorldForward();
  let dist = CBConfig.HitSquadMinSpawnDistance() + 12.0;

  // Base point behind V (outside the forward view cone).
  let bx = ppos.X - fwd.X * dist;
  let by = ppos.Y - fwd.Y * dist;
  // Flat right vector, to spread the row sideways.
  let rx = -fwd.Y;
  let ry = fwd.X;
  let orient = Quaternion.BuildFromDirectionVector(new Vector4(fwd.X, fwd.Y, 0.0, 0.0));

  let spawned = 0;
  let i = 0;
  while i < count {
    let lane = Cast<Float>(i) - Cast<Float>(count - 1) * 0.5;   // centre the row on the base point
    let pos = new Vector4(bx + rx * lane * 2.5, by + ry * lane * 2.5, ppos.Z, 1.0);

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

    if EntityID.IsDefined(des.CreateEntity(spec)) {
      spawned += 1;
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
