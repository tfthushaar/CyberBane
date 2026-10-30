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

public func CBSpawnGroup(game: GameInstance, record: TweakDBID, appearance: CName, count: Int32, squadTag: CName, dist: Float, out lastSpawned: EntityID) -> Int32 {
  if !TDBID.IsValid(record) || count <= 0 {
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
      if !CBSafeAreaBlocksSpawn(game, p) {
        let facing = Quaternion.BuildFromDirectionVector(
          Vector4.Normalize2D(new Vector4(ppos.X - p.X, ppos.Y - p.Y, 0.0, 0.0)));
        if CBCreateSpawn(des, record, appearance,
                         new Vector4(p.X, p.Y, p.Z + CBConfig.GroundSpawnLift(), 1.0),
                         facing, squadTag, lastSpawned) {
          spawned += 1;
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
      if CBNavSnap(game, ax, ay, baseZ, snapped) && !CBSafeAreaBlocksSpawn(game, snapped) {
        if CBCreateSpawn(des, record, appearance, snapped, orient, squadTag, lastSpawned) {
          spawned += 1;
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
        if CBGroundAt(game, px, py, ppos.Z, gz) && AbsF(gz - ppos.Z) <= CBConfig.GroundMaxDrop() {
          if CBCreateSpawn(des, record, appearance,
                           new Vector4(px, py, gz + CBConfig.GroundSpawnLift(), 1.0), orient, squadTag, lastSpawned) {
            spawned += 1;
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
      if CBGroundAt(game, fx, fy, ppos.Z, fz) && AbsF(fz - ppos.Z) <= CBConfig.GroundMaxDrop() {
        let fallback = new Vector4(fx, fy, fz + CBConfig.GroundSpawnLift(), 1.0);
        // The fallback is close in, so it is the likeliest of the lot to land indoors.
        if !CBSafeAreaBlocksSpawn(game, fallback)
           && CBCreateSpawn(des, record, appearance, fallback, orient, squadTag, lastSpawned) {
          spawned += 1;
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
  let evt = new AICommandEvent();
  evt.command = cmd;
  puppet.QueueEvent(evt);
  ai.SendCommand(cmd);
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

  public func Call() -> Void {
    let game = GetGameInstance();
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

// Everything that makes one of ours behave like one of ours.
public func CBApplySpawnSetup(sys: ref<CyberbaneSystem>, game: GameInstance,
                              puppet: ref<ScriptedPuppet>, riding: Bool) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !IsDefined(puppet) {
    return;
  }
  let id = puppet.GetEntityID();
  // An apex escort fights as rank and file, so it takes the squad's kit.
  let isSquad = des.IsTagged(id, n"CB_Squad") || des.IsTagged(id, n"CB_Escort");
  let isRival = des.IsTagged(id, n"CB_Rival");
  let isApex = des.IsTagged(id, n"CB_Apex");
  if !isSquad && !isRival && !isApex {
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
  if !riding {
    CBOrderHunt(game, puppet);
  }
  if isApex {
    CBApplyApexBuff(sys, game, puppet);
    CBKitApexMember(puppet);
    CBShowBossBar(puppet);
  }
  // A marker on the ones the player is meant to find. Escorts wear CB_Escort and are left
  // unmarked on purpose: the point is to pick the dangerous one out of a crowd.
  if isApex || isRival || des.IsTagged(id, n"CB_Squad") {
    CBTrackOnMap(game, puppet);
  }
  if isSquad {
    CBKitSquadMember(puppet);
  }
  if isApex || isSquad {
    CBJoinSquadWith(sys, puppet);
  }
  if isRival {
    // A named enemy that never uses cover or chrome is a ganger with a nameplate.
    CBKitApexMember(puppet);
    let who = sys.FindRivalById(sys.GetActiveRivalId());
    if IsDefined(who) {
      CBApplyRivalApexBuff(sys, game, puppet, who);
      CBApplyRivalRoleBuff(sys, game, puppet, CBRivalRole(sys, who));
      if CBRivalGrade(who) >= CBConfig.RivalBossBarGrade() {
        CBShowBossBar(puppet);
      }
    }
  }
  CBLog.Info(n"Spawn", "One of ours is up and coming for you.");
}

// Keep the people who were sent after you actually coming after you.
//
// The order issued at spawn finishes once they reach V, by design - it has to, or it would
// fight the game's own combat AI for the whole encounter. But that means the moment you break
// away they are back on ordinary behaviour and will happily lose track of you, which reads as
// them giving up rather than you escaping.
//
// So anybody of ours who is still alive and has fallen behind gets told again. The distance
// floor is what keeps this from interfering during the fight itself: somebody standing next to
// you is already doing the right thing and must not be interrupted.
//
// Escaping is still entirely possible, and is meant to be: they run, you can drive, and the
// retire timer ends the encounter if you stay away. This stops them wandering off; it does not
// glue them to you, and nothing here moves anybody.
public func CBChaseRefreshTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !CBWorldStable(game) {
    return;
  }
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(player) || !IsDefined(des) {
    return;
  }
  let ppos = player.GetWorldPosition();

  // Can they still see a reason to keep coming?
  //
  // Re-issuing the order every few seconds made them impossible to shake: however far you got,
  // they were handed your position again. That is not a chase, it is a tether. The police in
  // this game give up once you have been far enough away for long enough, and these should
  // work the same way - you should be able to drive off and lose them.
  let nearest = CBNearestHunterDistance(sys, game, des, ppos);
  if nearest < 0.0 {
    sys.SetChaseAwayTicks(0);   // nobody is after you
    return;
  }
  if nearest >= CBConfig.ChaseLoseDistance() {
    if sys.BumpChaseAwayTicks() >= CBConfig.ChaseLoseTicks() {
      CBChaseGiveUp(sys, game, des);
      return;
    }
    // Far enough that they are losing you: stop handing them your position.
    return;
  }
  sys.SetChaseAwayTicks(0);

  let done = 0;
  CBChaseRefreshTag(sys, game, des, ppos, n"CB_Rival", done);
  CBChaseRefreshTag(sys, game, des, ppos, n"CB_Apex", done);
  CBChaseRefreshTag(sys, game, des, ppos, n"CB_Squad", done);
  CBChaseRefreshTag(sys, game, des, ppos, n"CB_Escort", done);
}

// How far away the closest living hunter is, or -1 when there is nobody.
func CBNearestHunterDistance(sys: ref<CyberbaneSystem>, game: GameInstance,
                             des: ref<DynamicEntitySystem>, ppos: Vector4) -> Float {
  let best = -1.0;
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Rival", best);
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Apex", best);
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Squad", best);
  best = CBNearestForTag(sys, game, des, ppos, n"CB_Escort", best);
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
  CBUntrackTagged(game, n"CB_Rival");
  CBUntrackTagged(game, n"CB_Squad");
  CBUntrackTagged(game, n"CB_Apex");
  des.DeleteTagged(n"CB_Rival");
  des.DeleteTagged(n"CB_Squad");
  des.DeleteTagged(n"CB_Apex");
  des.DeleteTagged(n"CB_Escort");
  // Take the bars down with them, rather than leaving them up for the tick it would take the
  // stack to notice its targets had stopped existing.
  sys.GetThreatBar().Hide();
  sys.SetActiveRivalId(0);
  sys.SetActiveSquadFaction(n"");
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    CBShowMessage(game, "Cyberbane: you lost them.", 4.0);
  }
  CBLog.Info(n"Spawn", "Player outran the encounter; hunters gave up.");
}

func CBChaseRefreshTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                       ppos: Vector4, tag: CName, out done: Int32) -> Void {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) && done < CBConfig.ChaseRefreshPerPass() {
    let puppet = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    // CBNpcSafe covers attachment and the settling window, so nothing half-built is touched.
    // Somebody we broke and sent running is skipped. Re-issuing a hunt order to them cancels
    // the panic we just caused, so the two systems were quietly undoing each other.
    if CBStillStanding(puppet) && CBNpcSafe(sys, puppet) && !puppet.cbMoraleBroken {
      // Anyone still riding is the car's problem, not theirs.
      if !VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) {
        let away = Vector4.Distance(puppet.GetWorldPosition(), ppos);
        if away >= CBConfig.ChaseRefreshMinDistance() && away <= CBConfig.ChaseLoseDistance() {
          CBOrderHunt(game, puppet);
          done += 1;
        }
      }
    }
  }
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
  // And hand them V as something to track.
  //
  // Attitude only decides how they feel about V; it does not put V on their target tracker, so
  // until their own perception happened to pick V up they had nobody to fight. This is the
  // second half of what the game does in AIActionHelper.TryStartCombatWithTarget, and it was
  // missing. The first half of that helper is no use to us directly: it changes nothing and
  // returns false unless the NPC is already aggressive, which a freshly spawned ganger is not,
  // and it only injects the threat when that succeeded. Setting the attitude ourselves and
  // injecting the threat ourselves gets both halves regardless.
  TargetTrackingExtension.InjectThreat(puppet, player);
}
