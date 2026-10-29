// Cyberbane - Arriving by car (spec §9.9)
//
// A gang that wants you dead does not materialise behind a dumpster. They drive over.
//
// This is the arrival path for the encounters that are supposed to feel deliberate: a hit
// squad sent after a vendetta, an apex coming to settle it. A car is spawned out of sight,
// filled with the gang, and told to run V down; the crew gets out and fights when it stops.
//
// The sequence is spread over three attach events because each step needs the previous one to
// exist in the world first:
//
//   1. CBSpawnVehicleArrival queues the car, tagged CB_Car.
//   2. The car attaches. Only then can its seat count be read, so that is where the crew is
//      queued, tagged CB_Crew, standing at the car's own position.
//   3. Each crew member attaches and is mounted into the next seat. When the last seat is
//      filled the car is handed its chase order.
//
// Crash safety: nothing here dereferences a handle it has not checked, the whole path sits
// behind CBWorldStable and the ordinary safe area gate, and every step is allowed to fail
// quietly. A car that never attaches simply means no encounter this cycle, and the hunt timer
// comes round again - which is strictly better than forcing a spawn into a world that was not
// ready for one.

// Gang cars.
//
// These are the game's own savable vehicle records. There is no way to sample a vehicle from
// the world the way Cyberbane samples NPC records, so this is a fixed list, kept to records
// that are known to spawn correctly on this patch. A faction always draws from the same pair,
// so the same gang keeps turning up in the same kind of car.
// The car to ask the city's own chase for.
//
// This cannot be one of the `cs_savable_*` records below. Those are ordinary traffic and carry
// no `minVehiclePassengersCount` or `maxVehiclePassengersCount`, and the game's chase seats its
// crew by exactly those two fields - vanilla reads them right before the call:
//
//     passengersCount = RandRange( vehicleRecord.MinVehiclePassengersCount(),
//                                  vehicleRecord.MaxVehiclePassengersCount() + 1 );
//     TryGetUnitDataFromVehicleRecord( vehicleRecord, passengersCount, passengerIDs );
//
// A record with no capacity seats nobody, which is the likeliest reason a car was dispatched
// every time and never once seen. So the record has to be one the prevention system is built
// around. These are the ones in the base game that are not liveried as police: plain nomad
// bodies for a couple of people, and the Militech Emperor when a full squad has to fit.
func CBChaseVehicle(factionId: CName, seats: Int32) -> TweakDBID {
  let pool: array<TweakDBID>;
  if seats > 2 {
    ArrayPush(pool, t"Vehicle.wasteland_chevalier_emperor_militech_heat_2");
    ArrayPush(pool, t"Vehicle.wasteland_chevalier_emperor_militech_heat_3");
  } else {
    ArrayPush(pool, t"Vehicle.aldecado_thorton_galena_heat_2");
    ArrayPush(pool, t"Vehicle.aldecado_archer_quartz_heat_3");
    ArrayPush(pool, t"Vehicle.aldecado_thorton_colby_heat_3");
  }
  // Deterministic per faction, so a gang has a look.
  let idx = (StrLen(NameToString(factionId)) * 3) % ArraySize(pool);
  if idx < 0 {
    idx = 0;
  }
  return pool[idx];
}

// How many the game will actually seat in this one. Zero means it will seat nobody, which is
// the caller's cue to stop and use the convoy it builds itself.
func CBChaseVehicleSeats(record: TweakDBID) -> Int32 {
  let rec = TweakDBInterface.GetVehicleRecord(record);
  if !IsDefined(rec) {
    return 0;
  }
  return rec.MaxVehiclePassengersCount();
}

func CBArrivalVehicle(factionId: CName, roll: Int32) -> TweakDBID {
  let pool: array<TweakDBID>;
  ArrayPush(pool, t"Vehicle.cs_savable_thorton_galena");
  ArrayPush(pool, t"Vehicle.cs_savable_chevalier_thrax");
  ArrayPush(pool, t"Vehicle.cs_savable_archer_quartz");
  ArrayPush(pool, t"Vehicle.cs_savable_villefort_columbus");
  ArrayPush(pool, t"Vehicle.cs_savable_quadra_turbo");
  ArrayPush(pool, t"Vehicle.cs_savable_mizutani_shion");
  ArrayPush(pool, t"Vehicle.cs_savable_archer_hella");
  ArrayPush(pool, t"Vehicle.cs_savable_thorton_colby");
  ArrayPush(pool, t"Vehicle.cs_savable_thorton_mackinaw");
  ArrayPush(pool, t"Vehicle.cs_savable_villefort_alvarado");
  let size = ArraySize(pool);
  if size <= 0 {
    return TDBID.None();
  }
  // Deterministic per faction, so a gang has a look, with a little variation inside it.
  let seed = StrLen(NameToString(factionId)) * 3 + roll;
  let idx = seed % size;
  if idx < 0 {
    idx = 0;
  }
  return pool[idx];
}

// Is a car the right way to do this arrival at all?
public func CBVehicleArrivalAllowed(game: GameInstance) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() || !rt.HasSettings() {
    return false;
  }
  if !rt.GetSettings().vehicleArrivals {
    return false;
  }
  // A car cannot reach V up a stairwell or inside a mall, and trying is how you get a car
  // wedged in a doorway. Indoors, they come on foot.
  if CBPlayerIndoors(game) {
    return false;
  }
  return true;
}

// Find somewhere a car can actually sit: on the navmesh, out of V's view, with room for it.
//
// The navmesh is a pedestrian surface rather than a road, so this is not a guarantee of
// tarmac. It is a guarantee of open, outdoor, connected ground far enough away not to be seen
// appearing, which is what the complaint about spawns was really about. The box overlap is
// what stops a car being dropped into a wall or on top of another vehicle.
func CBCarSpawnPoint(game: GameInstance, dist: Float, out pos: Vector4, out ori: Quaternion) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  let anchor: Vector4;
  if !CBNavAnchor(game, dist, anchor) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  // Point it at V, which is both the direction it will drive and a sensible resting angle.
  let toPlayer = new Vector4(ppos.X - anchor.X, ppos.Y - anchor.Y, 0.0, 0.0);
  if Vector4.Length(toPlayer) < 1.0 {
    return false;
  }
  let facing = Vector4.Normalize(toPlayer);
  let quat = Quaternion.BuildFromDirectionVector(facing);

  let sqs = GameInstance.GetSpatialQueriesSystem(game);
  if !IsDefined(sqs) {
    return false;
  }
  let dims = new Vector4(CBConfig.CarFitWidth(), CBConfig.CarFitLength(), CBConfig.CarFitHeight(), 0.0);
  let at = new Vector4(anchor.X, anchor.Y, anchor.Z + CBConfig.CarFitHeight() + 0.2, 1.0);
  let angles = Quaternion.ToEulerAngles(quat);
  let hit: TraceResult;
  if sqs.Overlap(dims, at, angles, n"Static", hit) {
    return false;   // something solid is already there
  }
  if sqs.Overlap(dims, at, angles, n"Vehicle", hit) {
    return false;   // so is somebody's parked car
  }
  pos = new Vector4(anchor.X, anchor.Y, anchor.Z + CBConfig.GroundSpawnLift(), 1.0);
  ori = quat;
  return true;
}

// Step 1: queue the car. Returns false if no car could be placed, and the caller sends the
// encounter in on foot instead.
// `leadRecord` / `leadTag` are for an arrival that has somebody in particular in it - an apex
// riding in with its escort. The first seat gets that record and that tag, the rest get the
// ordinary crew. Pass TDBID.None() for a plain squad where everyone is the same.
public func CBSpawnVehicleArrival(sys: ref<CyberbaneSystem>, game: GameInstance, factionId: CName,
                                  crewRecord: TweakDBID, crew: Int32, squadTag: CName,
                                  leadRecord: TweakDBID, leadTag: CName) -> Bool {
  if !IsDefined(sys) || !TDBID.IsValid(crewRecord) || crew <= 0 {
    return false;
  }
  if !CBVehicleArrivalAllowed(game) {
    return false;
  }
  if !CBWorldStable(game) {
    return false;
  }
  // One convoy at a time. A second car while the first is still loading its crew would take
  // the seats meant for the first one.
  if sys.HasPendingArrival() {
    return false;
  }
  // Ask the city first. Its own chase puts the car on the road network, fills it and drives it
  // at you properly, which is the thing this mod kept failing to do by hand.
  if CBRequestVanillaChase(sys, game, factionId, crewRecord, crew, squadTag) {
    return true;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let pos: Vector4;
  let ori: Quaternion;
  if !CBCarSpawnPoint(game, CBConfig.VehicleArrivalDistance(), pos, ori) {
    return false;
  }
  if CBSafeAreaBlocksSpawn(game, pos) {
    return false;
  }
  let record = CBArrivalVehicle(factionId, RandRange(0, 4));
  if !TDBID.IsValid(record) {
    return false;
  }
  let spec = new DynamicEntitySpec();
  spec.recordID = record;
  spec.position = pos;
  spec.orientation = ori;
  spec.persistState = false;
  spec.persistSpawn = false;
  spec.alwaysSpawned = false;
  spec.spawnInView = false;   // the player asked not to watch it appear
  spec.active = true;
  let tags: array<CName>;
  ArrayPush(tags, n"Cyberbane");
  ArrayPush(tags, n"CB_Car");
  spec.tags = tags;
  let carId = des.CreateEntity(spec);
  if !EntityID.IsDefined(carId) {
    return false;
  }
  // Remember what to put in it once it exists.
  sys.SetPendingArrival(crewRecord, crew, squadTag, leadRecord, leadTag);
  CBLog.Info(n"Spawn", "A car is on its way.");
  return true;
}

// Step 2: the car is in the world. Read its seats and queue the crew beside it.
public func CBOnArrivalCarAttached(sys: ref<CyberbaneSystem>, game: GameInstance, car: ref<VehicleObject>) -> Void {
  if !IsDefined(sys) || !IsDefined(car) {
    return;
  }
  if !sys.HasPendingArrival() {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  // A bike carries its rider and nobody else; everything else goes by its own seat count.
  let seats = 1;
  if !IsDefined(car as BikeObject) {
    let rec: ref<Vehicle_Record>;
    VehicleComponent.GetVehicleRecord(car, rec);
    if IsDefined(rec) {
      seats = rec.MaxVehiclePassengersCount();
    }
  }
  if seats > CBConfig.CarMaxSeats() {
    seats = CBConfig.CarMaxSeats();
  }
  let wanted = sys.GetPendingArrivalCrew();
  if wanted < seats {
    seats = wanted;
  }
  if seats <= 0 {
    sys.ClearPendingArrival();
    return;
  }
  sys.BeginArrivalBoarding(car.GetEntityID(), seats);

  let record = sys.GetPendingArrivalRecord();
  let squadTag = sys.GetPendingArrivalTag();
  let leadRecord = sys.GetPendingArrivalLeadRecord();
  let leadTag = sys.GetPendingArrivalLeadTag();
  let at = car.GetWorldPosition();
  let ori = car.GetWorldOrientation();
  let i = 0;
  while i < seats {
    // Seat zero is whoever this arrival is actually about, when it is about somebody.
    let isLead = i == 0 && TDBID.IsValid(leadRecord);
    let seatRecord = isLead ? leadRecord : record;
    // An apex squad fills its seats by role instead: a heavy, a shooter, a blade and a
    // netrunner, each from a real record of that kind belonging to this gang.
    if sys.IsArrivalRoleSquad() {
      let fsRole = sys.FindFaction(sys.GetPendingArrivalFaction());
      seatRecord = CBApexRoleRecord(fsRole, i, seatRecord);
    }
    let spec = new DynamicEntitySpec();
    spec.recordID = seatRecord;
    spec.position = at;
    spec.orientation = ori;
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = false;
    spec.spawnInView = false;
    spec.active = true;
    let tags: array<CName>;
    ArrayPush(tags, n"Cyberbane");
    ArrayPush(tags, n"CB_Crew");
    ArrayPush(tags, isLead ? leadTag : squadTag);
    spec.tags = tags;
    des.CreateEntity(spec);
    i += 1;
  }
}

// Step 3: a crew member exists. Put them in the next seat; start the car once it is full.
public func CBOnArrivalCrewAttached(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(puppet) {
    return;
  }
  let carId = sys.GetArrivalCarId();
  if !EntityID.IsDefined(carId) {
    return;
  }
  let car = GameInstance.FindEntityByID(game, carId) as VehicleObject;
  if !IsDefined(car) {
    sys.ClearPendingArrival();
    return;
  }
  let slot = sys.TakeArrivalSeat();
  if slot < 0 {
    return;   // the car is already full; this one walks
  }
  let seatNames: array<CName>;
  ArrayPush(seatNames, n"seat_front_left");    // the driver
  ArrayPush(seatNames, n"seat_front_right");
  ArrayPush(seatNames, n"seat_back_left");
  ArrayPush(seatNames, n"seat_back_right");
  if slot >= ArraySize(seatNames) {
    return;
  }
  let data = new MountEventData();
  data.slotName = seatNames[slot];
  data.mountParentEntityId = carId;
  data.isInstant = true;
  data.ignoreHLS = true;
  let evt = new MountAIEvent();
  evt.name = n"Mount";
  evt.data = data;
  puppet.QueueEvent(evt);

  if sys.IsArrivalFull() {
    // One tick for the mounts to settle before the car is given its orders; issuing the
    // command while the driver is still being seated loses it.
    let cb = new CBArrivalDriveCallback();
    cb.carId = carId;
    GameInstance.GetDelaySystem(game).DelayCallback(cb, CBConfig.CarStartDelay(), false);
    // And start watching for the car to get there, so somebody actually gets out of it.
    let watch = new CBArrivalDismountCallback();
    watch.carId = carId;
    watch.tries = 0;
    GameInstance.GetDelaySystem(game).DelayCallback(watch, CBConfig.ArrivalDismountPoll(), false);
    sys.ClearPendingArrival();
  }
}

// Wait for the car to arrive, then put the crew on the pavement.
//
// This is the step that makes a car arrival an encounter rather than a traffic event. Nothing
// in the game guarantees that a crew Cyberbane mounted will choose to get out again: the
// disembark behaviour belongs to the prevention system's own squads, not to an arbitrary
// vehicle, so left alone the car pulls up and everybody sits in it.
//
// Polls rather than trusting one timer, because how long the drive takes depends entirely on
// the traffic and the route. It gives up after a fixed number of tries and unloads them
// anyway - a crew standing in the road a little early is a far better failure than a car
// circling Night City forever with four gangers in it.
public class CBArrivalDismountCallback extends DelayCallback {
  public let carId: EntityID;
  public let tries: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let car = GameInstance.FindEntityByID(game, this.carId) as VehicleObject;
    // A car that is gone (shot up, despawned) still means the crew should be let out.
    let arrived = true;
    if IsDefined(car) {
      arrived = Vector4.Distance(car.GetWorldPosition(), player.GetWorldPosition())
                <= CBConfig.ArrivalDismountDistance();
    }
    if !arrived && this.tries < CBConfig.ArrivalDismountMaxTries() {
      let next = new CBArrivalDismountCallback();
      next.carId = this.carId;
      next.tries = this.tries + 1;
      GameInstance.GetDelaySystem(game).DelayCallback(next, CBConfig.ArrivalDismountPoll(), false);
      return;
    }
    CBLog.Info(n"Spawn", s"Car arrived (or was given up on) after \(this.tries) checks; crew getting out.");
    CBDismountArrivalCrew(game);
  }
}

// Order everybody Cyberbane put in a car to get out and come for V.
public func CBDismountArrivalCrew(game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let ids = des.GetTaggedIDs(n"CB_Crew");
  let i = 0;
  while i < ArraySize(ids) {
    let puppet = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if IsDefined(puppet) && !puppet.IsDead() {
      // Only somebody actually sitting in a car gets told to get out of one.
      //
      // This used to go to everyone wearing the crew tag, and that tag is never taken off, so
      // it also reached people who had already got out and people whose mount never took in
      // the first place. Handing an unmount order to somebody standing on the pavement leaves
      // them in a broken state: face down on the ground, no AI, not fighting - which is
      // exactly what was reported. The poll repeats, so it was reaching them more than once.
      if VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) {
        let ai = puppet.GetAIControllerComponent();
        if IsDefined(ai) {
          ai.SendCommand(new AIUnmountCommand());
        }
      }
      // Out of the car and straight at V.
      CBOrderHunt(game, puppet);
    }
  }
}

// Set the car moving once its crew is aboard.
public class CBArrivalDriveCallback extends DelayCallback {
  public let carId: EntityID;

  public func Call() -> Void {
    let game = GetGameInstance();
    let car = GameInstance.FindEntityByID(game, this.carId) as VehicleObject;
    let player = GetPlayer(game);
    if !IsDefined(car) || !IsDefined(player) {
      return;
    }
    CBDriveAtPlayer(game, car, player);
  }
}

// Hand a crewed car its chase order.
//
// Two different commands, because they are two different situations. If V is driving, this is
// a car chase and the game has a command built for exactly that. If V is on foot, a chase
// command has nothing to pursue at road speed, so the car is told to drive to where V is and
// stop - which is what arriving looks like.
public func CBDriveAtPlayer(game: GameInstance, car: ref<VehicleObject>, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(car) || !IsDefined(player) {
    return;
  }
  let ai = car.GetAIComponent();
  if !IsDefined(ai) {
    return;
  }
  let evt = new AICommandEvent();
  if IsDefined(player.GetMountedVehicle() as VehicleObject) {
    let chase = new AIVehicleChaseCommand();
    chase.needDriver = true;
    chase.target = player;
    chase.distanceMin = CBConfig.ChaseDistanceMin();
    chase.distanceMax = CBConfig.ChaseDistanceMax();
    chase.forcedStartSpeed = CBConfig.ChaseStartSpeed();
    chase.ignoreChaseVehiclesLimit = true;
    chase.boostDrivingStats = true;
    evt.command = chase;
    CBLog.Info(n"Spawn", "Car is giving chase.");
    car.SetPoliceStrategyDestination(player.GetWorldPosition());
    car.QueueEvent(evt);
    ai.SetInitCmd(chase);
    return;
  }
  CBLog.Info(n"Spawn", "Car has its crew and is driving to you.");
  let drive = new AIVehicleDriveToPointAutonomousCommand();
  drive.maxSpeed = CBConfig.ArrivalDriveMaxSpeed();
  drive.minSpeed = CBConfig.ArrivalDriveMinSpeed();
  drive.clearTrafficOnPath = true;
  drive.minimumDistanceToTarget = CBConfig.ArrivalStopDistance();
  drive.targetPosition = Vector4.Vector4To3(player.GetWorldPosition());
  drive.driveDownTheRoadIndefinitely = false;
  evt.command = drive;
  car.QueueEvent(evt);
  ai.SetInitCmd(drive);
}
