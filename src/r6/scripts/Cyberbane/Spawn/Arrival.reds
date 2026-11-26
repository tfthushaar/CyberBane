// Cyberbane - Arriving by car (spec §9.9)
//
// A gang that wants you dead does not materialise behind a dumpster. They drive over.

// Gang cars.

// The seats a vehicle record really has, driver first.
public func CBVehicleSeatNames(record: TweakDBID) -> array<CName> {
  let names: array<CName>;
  let rec = TweakDBInterface.GetVehicleRecord(record);
  if !IsDefined(rec) {
    return names;
  }
  let pkg = rec.VehDataPackage();
  if !IsDefined(pkg) {
    return names;
  }
  let seatSet = pkg.VehSeatSet();
  if !IsDefined(seatSet) {
    return names;
  }
  let seats: array<wref<VehicleSeat_Record>>;
  seatSet.VehSeats(seats);
  let driver = n"seat_front_left";
  let haveDriver = false;
  let others: array<CName>;
  let i = 0;
  while i < ArraySize(seats) {
    let seat = seats[i];
    i += 1;
    if IsDefined(seat) {
      let n = seat.SeatName();
      if Equals(n, driver) {
        haveDriver = true;
      } else {
        if IsNameValid(n) && !ArrayContains(others, n) {
          ArrayPush(others, n);
        }
      }
    }
  }
  // Nobody drives a car with no driver's seat, so a seat set without one seats nobody.
  if !haveDriver {
    return names;
  }
  ArrayPush(names, driver);
  let k = 0;
  while k < ArraySize(others) {
    ArrayPush(names, others[k]);
    k += 1;
  }
  return names;
}

// The car a gang sends, chosen by how many it has to carry.
public func CBArrivalVehicle(factionId: CName, needed: Int32, roll: Int32, out seatsOut: Int32) -> TweakDBID {
  seatsOut = 0;
  let galena = t"Vehicle.cs_savable_thorton_galena";
  let thrax = t"Vehicle.cs_savable_chevalier_thrax";
  let quartz = t"Vehicle.cs_savable_archer_quartz";
  let columbus = t"Vehicle.cs_savable_villefort_columbus";
  let turbo = t"Vehicle.cs_savable_quadra_turbo";
  let shion = t"Vehicle.cs_savable_mizutani_shion";
  let hella = t"Vehicle.cs_savable_archer_hella";
  let colby = t"Vehicle.cs_savable_thorton_colby";
  let mackinaw = t"Vehicle.cs_savable_thorton_mackinaw";
  let alvarado = t"Vehicle.cs_savable_villefort_alvarado";

  // Their own first, in an order that varies a little from one arrival to the next, then their colours: the game has
  // gang-painted versions of these cars, and a lone Tyger Claw comes on a Claws Kusanagi.
  let content = CyberbaneContent.Get();
  let profile = IsDefined(content) ? content.GetFaction(factionId) : null;
  let own: array<TweakDBID>;
  let painted: array<TweakDBID>;
  if IsDefined(profile) {
    own = profile.cars;
    if needed <= 1 && TDBID.IsValid(profile.loneRide) {
      ArrayPush(painted, profile.loneRide);
    }
    for pcar in profile.paintedCars {
      ArrayPush(painted, pcar);
    }
  }
  if ArraySize(own) == 0 {
    ArrayPush(own, quartz);
    ArrayPush(own, thrax);
    ArrayPush(own, hella);
  }
  let pool: array<TweakDBID>;
  let pc = 0;
  while pc < ArraySize(painted) {
    ArrayPush(pool, painted[(pc + Max(roll, 0)) % ArraySize(painted)]);
    pc += 1;
  }
  let n = ArraySize(own);
  let j = 0;
  while j < n {
    ArrayPush(pool, own[(j + Max(roll, 0)) % n]);
    j += 1;
  }
  let rest: array<TweakDBID>;
  ArrayPush(rest, quartz);
  ArrayPush(rest, thrax);
  ArrayPush(rest, columbus);
  ArrayPush(rest, hella);
  ArrayPush(rest, colby);
  ArrayPush(rest, galena);
  ArrayPush(rest, mackinaw);
  ArrayPush(rest, alvarado);
  ArrayPush(rest, turbo);
  ArrayPush(rest, shion);
  let r = 0;
  while r < ArraySize(rest) {
    if !ArrayContains(pool, rest[r]) {
      ArrayPush(pool, rest[r]);
    }
    r += 1;
  }

  let want = Max(1, Min(needed, CBConfig.CarMaxSeats()));
  let best = TDBID.None();
  let bestSeats = 0;
  let i = 0;
  while i < ArraySize(pool) {
    let seatNames = CBVehicleSeatNames(pool[i]);
    let seats = Min(ArraySize(seatNames), CBConfig.CarMaxSeats());
    if seats >= want {
      seatsOut = seats;
      return pool[i];
    }
    if seats > bestSeats {
      best = pool[i];
      bestSeats = seats;
    }
    i += 1;
  }
  seatsOut = bestSeats;
  return best;
}

// Is a car the right way to do this arrival at all?
public func CBCarRefusal(game: GameInstance) -> String {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() || !rt.HasSettings() {
    return "the mod is off";
  }
  if !rt.GetSettings().vehicleArrivals {
    return "the arrivals by car setting is off";
  }
  // A car cannot reach V up a stairwell or inside a mall, and trying is how you get a car
  // wedged in a doorway. Indoors, they come on foot.
  if CBPlayerIndoors(game) {
    return "V is indoors";
  }
  let driver = GetPlayer(game);
  if !IsDefined(driver) {
    return "there is no player";
  }
  // Delicate, so it has a switch of its own, on by default (crash rule 12).
  if !VehicleComponent.IsDriver(game, driver) && !rt.GetSettings().carsWhileOnFoot {
    return "the cars while on foot setting is off";
  }
  // There used to be one more test here: "is there a road near enough", answered by
  // PreventionSpawnSystem.GetNearestRoadFromPlayerInfo. It was also a call into the prevention system, which crash rule
  // 1 forbids.
  return "";
}

public func CBVehicleArrivalAllowed(game: GameInstance) -> Bool {
  return StrLen(CBCarRefusal(game)) == 0;
}

// An arrival that wanted a car and will not get one. Says why, once, in the log.
public func CBCarRefused(why: String) -> Void {
  CBLog.Info(n"Spawn", s"No car this time: \(why). They come on foot.");
}

// Find somewhere a car can actually sit: on the navmesh, out of V's view, with room for it.
func CBCarSpawnPoint(game: GameInstance, dist: Float, out pos: Vector4, out ori: Quaternion) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  // V is outdoors here (CBCarRefusal). Under a bridge or in a road tunnel, a car may come from under
  // cover as well, because that is where the road is.
  let openAir = CBArrivalOpenAir(game, ppos);
  // The navmesh anchor first: behind V, connected to V, the right distance away. Nearer, then
  // further, before giving up on it: one parked van at exactly that distance used to cost the car.
  let reach: array<Float>;
  ArrayPush(reach, dist);
  ArrayPush(reach, dist * 0.8);
  ArrayPush(reach, dist * 1.3);
  let r = 0;
  while r < ArraySize(reach) {
    let anchor: Vector4;
    if CBNavAnchor(game, reach[r], anchor) && CBCarCanSitAt(game, anchor, ppos, openAir, pos, ori) {
      return true;
    }
    r += 1;
  }
  // Then the places the game itself would put a pursuer.
  let pts: array<Vector4>;
  if !CBPursuitPoints(game, ppos, player.GetWorldForward(), CBConfig.CarPointCandidates(),
                      dist * 0.6, dist * 1.4, pts) {
    return false;
  }
  let fwd = player.GetWorldForward();
  let i = 0;
  while i < ArraySize(pts) {
    let p = pts[i];
    i += 1;
    let ground: Vector4;
    // The game's fallback points ignore the range asked for, so the distance is checked again here.
    if Vector4.Distance(p, ppos) >= CBArrivalMinAway(dist)
       && AbsF(p.Z - ppos.Z) <= CBConfig.GroundMaxDrop()
       && CBSettleOnGround(game, p, ground)
       && CBPointOutOfSight(game, ppos, fwd, ground)
       && CBCarCanSitAt(game, ground, ppos, openAir, pos, ori)
       && CBPointReachable(game, ground, ppos) {
      return true;
    }
  }
  return false;
}

// Open sky and room for a car.
func CBCarCanSitAt(game: GameInstance, anchor: Vector4, ppos: Vector4, openAir: Bool,
                   out pos: Vector4, out ori: Quaternion) -> Bool {
  if openAir && CBPointCovered(game, anchor) {
    return false;
  }
  return CBCarFitsAt(game, anchor, ppos, pos, ori);
}

// Is there room for a car here? Fills `pos` and `ori` when there is.
func CBCarFitsAt(game: GameInstance, anchor: Vector4, ppos: Vector4, out pos: Vector4,
                 out ori: Quaternion) -> Bool {
  let toPlayer = new Vector4(ppos.X - anchor.X, ppos.Y - anchor.Y, 0.0, 0.0);
  if Vector4.Length(toPlayer) < 1.0 {
    return false;
  }
  let sqs = GameInstance.GetSpatialQueriesSystem(game);
  if !IsDefined(sqs) {
    return false;
  }
  let dims = new Vector4(CBConfig.CarFitWidth(), CBConfig.CarFitLength(), CBConfig.CarFitHeight(), 0.0);
  let at = new Vector4(anchor.X, anchor.Y, anchor.Z + CBConfig.CarFitClearance() + CBConfig.CarFitHeight(), 1.0);
  let ahead = Vector4.Normalize(toPlayer);
  let k = 0;
  while k < 3 {
    let facing = ahead;
    if k == 1 {
      facing = new Vector4(-ahead.Y, ahead.X, 0.0, 0.0);
    }
    if k == 2 {
      facing = new Vector4(ahead.Y, -ahead.X, 0.0, 0.0);
    }
    k += 1;
    let quat = Quaternion.BuildFromDirectionVector(facing);
    let angles = Quaternion.ToEulerAngles(quat);
    let hit: TraceResult;
    // Nothing solid there, and nobody's parked car.
    if !sqs.Overlap(dims, at, angles, n"Static", hit) && !sqs.Overlap(dims, at, angles, n"Vehicle", hit) {
      pos = new Vector4(anchor.X, anchor.Y, anchor.Z + CBConfig.GroundSpawnLift(), 1.0);
      ori = quat;
      return true;
    }
  }
  return false;
}

// Step 1: queue the car.
public func CBSpawnVehicleArrival(sys: ref<CyberbaneSystem>, game: GameInstance, factionId: CName,
                                  crewRecord: TweakDBID, crew: Int32, squadTag: CName,
                                  leadRecord: TweakDBID, leadTag: CName, opt chairBase: Int32,
                                  opt nextCar: Bool) -> Bool {
  if !IsDefined(sys) || !TDBID.IsValid(crewRecord) || crew <= 0 {
    return false;
  }
  let refused = CBCarRefusal(game);
  if StrLen(refused) > 0 {
    CBCarRefused(refused);
    return false;
  }
  if !CBWorldStable(game) {
    CBCarRefused("the world is still loading");
    return false;
  }
  // One car boarding at a time, whichever way it is coming. A second car while the first is still loading its crew
  // would take the seats meant for the first one.
  if sys.HasPendingArrival() {
    if !nextCar {
      CBCarRefused("another car is still boarding");
    }
    return false;
  }
  if !nextCar && (sys.GetTopUpWanted() > 0 || sys.HasConvoyLegs()) {
    CBCarRefused("the last convoy has not finished");
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let pos: Vector4;
  let ori: Quaternion;
  // Up the road from V, if this crew means to wait there and there is somewhere to do it. Anything
  // else that goes wrong with that is just an ordinary car from behind.
  let lyingInWait = !nextCar && sys.IsAmbushWanted() && CBAmbushSpot(game, pos, ori);
  if !lyingInWait && !CBCarSpawnPoint(game, CBConfig.VehicleArrivalDistance(), pos, ori) {
    CBCarRefused("nowhere out of sight with room for a car");
    return false;
  }
  if CBSafeAreaBlocksSpawn(game, pos) {
    CBCarRefused(CBSpawnBlockWhy());
    return false;
  }
  let carSeats = 0;
  let record = CBArrivalVehicle(factionId, crew, RandRange(0, 4), carSeats);
  if !TDBID.IsValid(record) || carSeats <= 0 {
    CBCarRefused("no car on the list has a seat");
    return false;   // nothing that would seat anybody; they walk in
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
  CBTrace("vehicle: creating a car");
  let carId = des.CreateEntity(spec);
  if !EntityID.IsDefined(carId) {
    return false;
  }
  // Remember what to put in it once it exists.
  // A car that is not part of a convoy ends whatever convoy came before it, so nothing can join
  // one that is over - least of all a Rival's car (CBSendByCar starts its own, after this).
  if !nextCar {
    sys.ClearConvoy();
  }
  sys.SetPendingArrival(crewRecord, crew, squadTag, leadRecord, leadTag);
  sys.SetArrivalWantedCar(carId);
  sys.SetArrivalChairBase(chairBase);
  sys.SetArrivalAmbush(lyingInWait);
  // Which car of its convoy this is: the cars already sent. Its crew carry that car's tag, so
  // the car that pulls up lets out its own people and nobody else's (CBDismountArrivalCrew).
  sys.SetArrivalCarSlot(nextCar ? sys.GetConvoyCars() : 0);
  // What this car can really carry, so whoever it cannot seat walks in now (CBSendByCar)
  // instead of after the top-up has waited for seats that were never there.
  sys.NoteCarPath(Min(crew, carSeats), nextCar);
  CBLog.Info(n"Spawn", "A car is on its way.");
  return true;
}

// Send a group by car, and make sure the whole group turns up.
public func CBSendByCar(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>,
                        record: TweakDBID, wanted: Int32, tag: CName) -> Int32 {
  if !IsDefined(sys) || !IsDefined(fs) || !TDBID.IsValid(record) || wanted <= 0 {
    return 0;
  }
  let isApex = Equals(tag, n"CB_Apex");
  // Joining a convoy already on the road for this gang.
  if sys.HasPendingArrival() || sys.HasConvoyLegs() {
    if !Equals(sys.GetConvoyFaction(), fs.id) || !CBVehicleArrivalAllowed(game)
       || sys.GetConvoyCars() >= CBCarsPerArrival() {
      return 0;
    }
    if isApex && NotEquals(sys.GetApexMusterFaction(), fs.id) {
      sys.BeginApexMuster(fs.id, record);
    }
    sys.QueueConvoyLeg(fs.id, record, tag, wanted, wanted, isApex ? 0 : -1);
    return wanted;
  }
  if isApex {
    sys.ResetApexRoles();   // the car's seats are the first chairs, from the heavy
    if NotEquals(sys.GetApexMusterFaction(), fs.id) {
      sys.BeginApexMuster(fs.id, record);
    }
  }
  let lead = isApex ? record : TDBID.None();
  let leadTag = isApex ? n"CB_Apex" : n"";
  if !CBSpawnVehicleArrival(sys, game, fs.id, record, wanted, tag, lead, leadTag) {
    return 0;
  }
  if isApex {
    sys.MarkArrivalRoleSquad(fs.id);
  }
  sys.BeginConvoy(fs.id);
  let carrying = Min(sys.GetLastCarSeats(), wanted);
  if carrying < wanted {
    // The rest wait for the next car. An apex leg remembers which chair comes next; a crew leg
    // arms its top-up once its last car has gone (CBConvoyTick).
    sys.QueueConvoyLeg(fs.id, record, tag, wanted - carrying, wanted, isApex ? carrying : -1);
    CBLog.Info(n"Spawn", s"The first car seats \(carrying) of \(wanted); the rest follow in more cars.");
    return wanted;
  }
  if !isApex {
    CBArmCrewTopUp(sys, fs.id, record, tag, wanted);
  }
  return wanted;
}

// The whole crew has been sent, by car or on foot: give the cars their chance to deliver, then walk in whoever they did
// not (CBProcessCarTopUp).
func CBArmCrewTopUp(sys: ref<CyberbaneSystem>, faction: CName, record: TweakDBID, tag: CName,
                    wanted: Int32) -> Void {
  let wait = CBConfig.ArrivalStaleTicks() + 3;
  sys.ArmCarTopUp(faction, record, tag, wanted, wait);
}

// How many cars one arrival may bring, from the setting.
public func CBCarsPerArrival() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    return Max(1, rt.GetSettings().carsPerArrival);
  }
  return CBConfig.CarsPerArrivalDefault();
}

// Once per fast tick: the next car of a convoy, once the one before it has its crew aboard.
public func CBConvoyTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !sys.HasConvoyLegs() {
    return;
  }
  if sys.HasPendingArrival() {
    return;   // the car before is still boarding
  }
  // A load, a fast travel, the world still streaming: not a missed car, just not now.
  if !CBWorldStable(game) {
    return;
  }
  let faction = sys.LegFaction();
  let record = sys.LegRecord();
  let tag = sys.LegTag();
  let left = sys.LegLeft();
  let chair = sys.LegChair();
  let isApex = Equals(tag, n"CB_Apex");
  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) || !TDBID.IsValid(record) || left <= 0 {
    sys.DropLeg();
    return;
  }
  if sys.GetConvoyCars() < CBCarsPerArrival()
     && CBSpawnVehicleArrival(sys, game, faction, record, left, tag, TDBID.None(), n"",
                              Max(chair, 0), true) {
    sys.NoteConvoyCar();
    if isApex {
      sys.MarkArrivalRoleSquad(faction);
    }
    let carried = Min(sys.GetLastCarSeats(), left);
    sys.LegCarried(carried);
    CBLog.Info(n"Spawn", s"Another car for \(NameToString(faction)): \(carried) more aboard, car \(sys.GetConvoyCars()).");
    if sys.LegLeft() <= 0 {
      if !isApex {
        CBArmCrewTopUp(sys, faction, record, tag, sys.LegTotal());
      }
      sys.DropLeg();
    }
    return;
  }
  // No car this tick. Give it a few, then walk them in rather than keep them waiting.
  let atLimit = sys.GetConvoyCars() >= CBCarsPerArrival();
  if !atLimit && sys.LegMissed() < CBConfig.ConvoyCarTries() {
    return;
  }
  let walked = CBWalkInRest(sys, game, fs, record, tag, Max(chair, 0), left);
  CBLog.Info(n"Spawn", s"No more cars for \(NameToString(faction)); \(walked) of \(left) walking in.");
  if !isApex {
    // Walked in counts as put in the world, so the top-up only covers whoever even that missed.
    sys.NoteConvoyCreated(walked);
    CBArmCrewTopUp(sys, faction, record, tag, sys.LegTotal());
  }
  sys.DropLeg();
}

// Walk `count` of a group in on foot, starting at chair `firstSeat` for an apex squad so the
// chairs the car filled are not filled twice.
public func CBWalkInRest(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>,
                         record: TweakDBID, tag: CName, firstSeat: Int32, count: Int32) -> Int32 {
  if count <= 0 {
    return 0;
  }
  if Equals(tag, n"CB_Apex") {
    // A chair the muster for this gang's squad already has filled is skipped, so a walk-in that
    // follows a car, or a retry, can never put a second heavy in the world.
    let mustering = IsDefined(sys) && IsDefined(fs) && Equals(sys.GetApexMusterFaction(), fs.id);
    let placed = 0;
    let k = 0;
    while k < count {
      let seat = (firstSeat + k) % CBConfig.ApexStrikeTeamSize();
      if !mustering || !sys.ApexChairFilled(seat) {
        let one: EntityID;
        if CBSpawnGroup(game, CBApexRoleRecord(fs, seat, record), n"", 1, n"CB_Apex",
                        CBConfig.ApexSpawnDistance(), one, CBApexRoleTag(seat)) > 0 {
          placed += 1;
          if mustering {
            sys.NoteApexChair(seat);
          }
        }
      }
      k += 1;
    }
    return placed;
  }
  let ent: EntityID;
  return CBSpawnGroup(game, record, n"", count, tag, CBConfig.HitSquadMinSpawnDistance() + 12.0, ent);
}

// Once per fast tick: the car has had its chance to deliver, so anybody it did not walks in.
public func CBProcessCarTopUp(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || sys.GetTopUpWanted() <= 0 {
    return;
  }
  if sys.TickTopUp() > 0 {
    return;
  }
  let tag = sys.GetTopUpTag();
  let wanted = sys.GetTopUpWanted();
  let delivered = sys.GetConvoyCreated();
  let fs = sys.FindFaction(sys.GetTopUpFaction());
  let record = sys.GetTopUpRecord();
  sys.ClearTopUp();
  // An apex squad is made whole by its chairs, not by a head count (CBApexMusterTick).
  if Equals(tag, n"CB_Apex") {
    return;
  }
  let missing = wanted - delivered;
  if missing <= 0 || !IsDefined(fs) {
    return;
  }
  let placed = CBWalkInRest(sys, game, fs, record, tag, delivered, missing);
  CBLog.Info(n"Spawn", s"The car brought \(delivered) of \(wanted); \(placed) walked in to make up the rest.");
}

// Step 2: the car is in the world. Read its seats and queue the crew beside it.
public func CBOnArrivalCarAttached(sys: ref<CyberbaneSystem>, game: GameInstance, car: ref<VehicleObject>) -> Void {
  if !IsDefined(sys) || !IsDefined(car) {
    return;
  }
  if !sys.HasPendingArrival() {
    return;
  }
  // Only the car this arrival asked for, and only the first time it attaches.
  if !Equals(car.GetEntityID(), sys.GetArrivalWantedCar()) || EntityID.IsDefined(sys.GetArrivalCarId()) {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  // The game's word on where this car ended up, which it can only give about something that exists.
  if IsEntityInInteriorArea(car) {
    CBCarRefused("the spot turned out to be indoors");
    sys.ClearPendingArrival();
    CBRemoveOne(game, des, car.GetEntityID(), false, true);
    return;
  }
  // The seats this car really has, from its own record (CBVehicleSeatNames).
  let seatNames: array<CName>;
  let rec: ref<Vehicle_Record>;
  VehicleComponent.GetVehicleRecord(car, rec);
  if IsDefined(rec) {
    seatNames = CBVehicleSeatNames(rec.GetID());
  }
  let seats = ArraySize(seatNames);
  if seats > CBConfig.CarMaxSeats() {
    seats = CBConfig.CarMaxSeats();
  }
  let wanted = sys.GetPendingArrivalCrew();
  if wanted < seats {
    seats = wanted;
  }
  // An apex squad's seats are chairs, and only chairs still empty are filled.
  let chairs: array<Int32>;
  if sys.IsArrivalRoleSquad() {
    let mustering = Equals(sys.GetApexMusterFaction(), sys.GetPendingArrivalFaction());
    let c = sys.GetArrivalChairBase();
    while ArraySize(chairs) < seats && c < CBConfig.ApexStrikeTeamSize() {
      if !mustering || !sys.ApexChairFilled(c) {
        ArrayPush(chairs, c);
      }
      c += 1;
    }
    seats = ArraySize(chairs);
  }
  if seats <= 0 {
    sys.ClearPendingArrival();
    return;
  }
  sys.BeginArrivalBoarding(car.GetEntityID(), seats, seatNames);
  // Counted for the crew top-up, which only ever covers a crew: an apex squad is made whole by
  // its chairs (CBApexMusterTick), and counting its seats here would leave the crew short.
  if !sys.IsArrivalRoleSquad() && !Equals(sys.GetPendingArrivalTag(), n"CB_Apex") {
    sys.NoteConvoyCreated(seats);
  }

  let record = sys.GetPendingArrivalRecord();
  let squadTag = sys.GetPendingArrivalTag();
  let leadRecord = sys.GetPendingArrivalLeadRecord();
  let leadTag = sys.GetPendingArrivalLeadTag();
  let at = car.GetWorldPosition();
  let ori = car.GetWorldOrientation();
  // Spread them around the car instead of stacking them on it.
  let side = Vector4.Normalize2D(Quaternion.GetRight(ori));
  let fwdV = Vector4.Normalize2D(Quaternion.GetForward(ori));
  let i = 0;
  while i < seats {
    let row = Cast<Float>(i / 2) - 0.5;
    let col = (i % 2) == 0 ? -1.0 : 1.0;
    let spot = new Vector4(
      at.X + side.X * col * CBConfig.ArrivalSeatSpread() + fwdV.X * row * CBConfig.ArrivalSeatSpread(),
      at.Y + side.Y * col * CBConfig.ArrivalSeatSpread() + fwdV.Y * row * CBConfig.ArrivalSeatSpread(),
      at.Z, 1.0);
    // On the ground beside the car, and no further than that was ever tested.
    let snapped: Vector4;
    let standing: Vector4;
    if CBNavSnap(game, spot.X, spot.Y, at.Z, snapped) && CBSettleOnGround(game, snapped, standing)
       && Vector4.Distance(standing, spot) <= CBConfig.ArrivalSeatSnap() {
      spot = standing;
    } else {
      if CBNavSnap(game, at.X, at.Y, at.Z, snapped) && CBSettleOnGround(game, snapped, standing) {
        spot = standing;
      }
    }
    // Seat zero is whoever this arrival is actually about, when it is about somebody.
    let isLead = i == 0 && TDBID.IsValid(leadRecord);
    let seatRecord = isLead ? leadRecord : record;
    // An apex squad fills its seats by role instead: a heavy, a shooter, a blade and a
    // netrunner, each from a real record of that kind belonging to this gang.
    if sys.IsArrivalRoleSquad() {
      let fsRole = sys.FindFaction(sys.GetPendingArrivalFaction());
      seatRecord = CBApexRoleRecord(fsRole, chairs[i], seatRecord);
    }
    let spec = new DynamicEntitySpec();
    spec.recordID = seatRecord;
    spec.position = spot;
    spec.orientation = ori;
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = false;
    spec.spawnInView = false;
    spec.active = true;
    // A Rival driving in wears their own face from the moment they spawn, set on the spec the way the walk-in spawner
    // sets it, so nothing has to change their appearance afterwards.
    let rider: ref<CBRival>;
    if (isLead && Equals(leadTag, n"CB_Rival")) || (!isLead && Equals(squadTag, n"CB_Rival")) {
      rider = sys.FindRivalById(sys.GetRivalCarPending());
    }
    if IsDefined(rider) && IsNameValid(rider.appearance) {
      spec.appearanceName = rider.appearance;
    }
    let tags: array<CName>;
    ArrayPush(tags, n"Cyberbane");
    ArrayPush(tags, n"CB_Crew");
    ArrayPush(tags, CBCarSlotTag(sys.GetArrivalCarSlot()));
    ArrayPush(tags, isLead ? leadTag : squadTag);
    // An apex seat carries the chair it was filled for, the same tag a walk-in carries, so the kit and the bar given at
    // setup are the chair this body's record was picked for.
    if sys.IsArrivalRoleSquad() {
      ArrayPush(tags, CBApexRoleTag(chairs[i]));
    }
    spec.tags = tags;
    CBTrace("vehicle: creating a car's crew member");
    let made = des.CreateEntity(spec);
    sys.NoteArrivalBoarder(made);   // only these are given this car's seats
    // The body is the Rival's from the moment it exists, so their death and escape count.
    if IsDefined(rider) && EntityID.IsDefined(made) {
      rider.spawnedEntityId = made;
    }
    // That chair of the apex squad is filled; the muster brings whoever the car could not seat.
    if sys.IsArrivalRoleSquad() && EntityID.IsDefined(made) {
      sys.NoteApexChair(chairs[i]);
    }
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
  if !IsDefined(car) || !car.IsAttached() {
    sys.ClearPendingArrival();
    return;
  }
  // Only somebody created for this car, once. Anybody else with the crew tag came in an earlier
  // car and has merely streamed back in.
  if !sys.TakeArrivalBoarder(puppet.GetEntityID())
     || VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) {
    return;
  }
  let slot = sys.TakeArrivalSeat();
  if slot < 0 {
    return;   // the car is already full; this one walks
  }
  // The car's own slot for this seat, driver first. Never a name the car does not have.
  let seatName = sys.GetArrivalSeatName(slot);
  if !IsNameValid(seatName) {
    return;
  }
  let data = new MountEventData();
  data.slotName = seatName;
  data.mountParentEntityId = carId;
  data.isInstant = true;
  data.ignoreHLS = true;
  CBTrace("vehicle: seating a crew member");
  let evt = new MountAIEvent();
  evt.name = n"Mount";
  evt.data = data;
  puppet.QueueEvent(evt);

  if sys.IsArrivalFull() {
    CBSendCarOff(sys, game, carId, sys.GetArrivalCarSlot());
    sys.ClearPendingArrival();
  }
}

// Set a crewed car off and start watching for it to arrive.
public func CBLaunchArrivalCar(game: GameInstance, carId: EntityID, slot: Int32) -> Void {
  if !EntityID.IsDefined(carId) {
    return;
  }
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) {
    return;
  }
  let cb = new CBArrivalDriveCallback();
  cb.carId = carId;
  ds.DelayCallback(cb, CBConfig.CarStartDelay(), false);
  let watch = new CBArrivalDismountCallback();
  watch.carId = carId;
  watch.slot = slot;
  watch.tries = 0;
  let player = GetPlayer(game);
  if IsDefined(player) {
    watch.target = player.GetWorldPosition();   // where the drive order is sending them
    watch.chasing = IsDefined(player.GetMountedVehicle());
  }
  ds.DelayCallback(watch, CBConfig.ArrivalDismountPoll(), false);
}

// A vendetta crew's alternative to chasing: a parked car somewhere up the road from a V who is driving, pulling out as
// V comes past.
func CBCrewLiesInWait(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>, withApex: Bool) -> Bool {
  if !CBLieInWaitOn() {
    return false;
  }
  if !IsDefined(sys) || !IsDefined(fs) || withApex || !CBVehicleArrivalAllowed(game) {
    return false;
  }
  let score = sys.GetScore();
  let player = GetPlayer(game);
  if !IsDefined(score) || !IsDefined(player) || !VehicleComponent.IsDriver(game, player) {
    return false;
  }
  // Sworn against V, or the Wraiths on their own road whatever their grudge (Spawn/HuntGrows.reds); likelier where V is
  // known to go. A watcher V paid sees them park.
  let wraithRoad = CBGangCodesOn() && Equals(fs.id, n"Wraiths") && Equals(sys.GetCurrentDistrict(), n"Badlands")
                   && Equals(score.GetPosture(fs.id), ECBPosture.Hostile);
  if !Equals(score.GetPosture(fs.id), ECBPosture.Vendetta) && !wraithRoad {
    return false;
  }
  if RandF() > ClampF(CBConfig.AmbushChance() * CBLieInWaitMult(sys, game, fs.id), 0.0, 0.9) {
    return false;
  }
  CBWarnOfWaiting(sys, game, fs.id);
  return true;
}

// Somewhere ahead of a moving V with room for a car, held to the same tests as any other car spot.
func CBAmbushSpot(game: GameInstance, out pos: Vector4, out ori: Quaternion) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  let vehicle = player.GetMountedVehicle() as VehicleObject;
  if !IsDefined(vehicle) || AbsF(vehicle.GetCurrentSpeed()) < CBConfig.AmbushMinSpeed() {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let fwd = vehicle.GetWorldForward();
  let openAir = CBArrivalOpenAir(game, ppos);
  let reach: array<Float>;
  ArrayPush(reach, CBConfig.AmbushDistance());
  ArrayPush(reach, CBConfig.AmbushDistance() * 0.75);
  ArrayPush(reach, CBConfig.AmbushDistance() * 1.3);
  let r = 0;
  while r < ArraySize(reach) {
    let centre = new Vector4(ppos.X + fwd.X * reach[r], ppos.Y + fwd.Y * reach[r], ppos.Z, 1.0);
    let minAway = CBArrivalMinAway(reach[r]);
    r += 1;
    let pts: array<Vector4>;
    if CBPursuitPoints(game, centre, fwd, CBConfig.CarPointCandidates(), 8.0, 40.0, pts) {
      let i = 0;
      while i < ArraySize(pts) {
        let p = pts[i];
        i += 1;
        let ground: Vector4;
        let toSpot = Vector4.Normalize2D(new Vector4(p.X - ppos.X, p.Y - ppos.Y, 0.0, 0.0));
        if Vector4.Dot2D(toSpot, Vector4.Normalize2D(fwd)) >= CBConfig.AmbushAheadCosine()
           && Vector4.Distance(p, ppos) >= minAway
           && AbsF(p.Z - ppos.Z) <= CBConfig.GroundMaxDrop()
           && CBSettleOnGround(game, p, ground)
           && CBPointOutOfSight(game, ppos, fwd, ground)
           && CBCarCanSitAt(game, ground, ppos, openAir, pos, ori)
           && CBPointReachable(game, ground, ppos) {
          CBLog.Info(n"Spawn", "A crew is waiting up the road.");
          return true;
        }
      }
    }
  }
  return false;
}

// Every full car goes through here: straight off, or into hiding first.
public func CBSendCarOff(sys: ref<CyberbaneSystem>, game: GameInstance, carId: EntityID, slot: Int32) -> Void {
  if IsDefined(sys) && sys.TakeArrivalAmbush() {
    let ds = GameInstance.GetDelaySystem(game);
    if IsDefined(ds) {
      let watch = new CBAmbushWatchCallback();
      watch.carId = carId;
      watch.slot = slot;
      ds.DelayCallback(watch, CBConfig.AmbushPoll(), false);
      return;
    }
  }
  CBLaunchArrivalCar(game, carId, slot);
}

public class CBAmbushWatchCallback extends DelayCallback {
  public let carId: EntityID;
  public let slot: Int32;
  public let polls: Int32;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        this.Again(game, this.polls, this.waits + (CBWaitCounts(game) ? 1 : 0));
      }
      return;
    }
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let car = GameInstance.FindEntityByID(game, this.carId) as VehicleObject;
    let spring = true;
    if IsDefined(car) && car.IsAttached() {
      let dist = Vector4.Distance(car.GetWorldPosition(), player.GetWorldPosition());
      spring = dist <= CBConfig.AmbushSpringDistance() || dist >= CBConfig.AmbushGiveUpDistance()
               || this.polls >= CBConfig.AmbushMaxPolls();
    }
    if spring {
      CBLog.Info(n"Spawn", s"The crew in the parked car moves after \(this.polls) checks.");
      CBLaunchArrivalCar(game, this.carId, this.slot);
      return;
    }
    // Sitting in a parked car is not the same as having been left behind (CBHuntersLeftBehind).
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      sys.NoteCarOnTheWay();
    }
    this.Again(game, this.polls + 1, 0);
  }

  private func Again(game: GameInstance, polls: Int32, waits: Int32) -> Void {
    let next = new CBAmbushWatchCallback();
    next.carId = this.carId;
    next.slot = this.slot;
    next.polls = polls;
    next.waits = waits;
    let ds = GameInstance.GetDelaySystem(game);
    if IsDefined(ds) {
      ds.DelayCallback(next, CBConfig.AmbushPoll(), false);
    }
  }
}

// Wait for the car to arrive, then put the crew on the pavement.
public class CBArrivalDismountCallback extends DelayCallback {
  public let carId: EntityID;
  public let tries: Int32;
  public let waits: Int32;
  // Where the car was last told to drive, and how many times it has been sent somewhere new.
  public let target: Vector4;
  public let retargets: Int32;
  // Which car of its convoy this is; only that car's crew get out when it arrives.
  public let slot: Int32;
  // Polls in a row it has sat still short of V, and whether its order is the chase one.
  public let stuck: Int32;
  public let chasing: Bool;
  public let braked: Bool;

  public func Call() -> Void {
    let game = GetGameInstance();
    // A delayed callback can land in the middle of a load or a fast travel, which is exactly when
    // native entity queries crash (see the note in Core/WorldState.reds). Wait it out instead.
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let again = new CBArrivalDismountCallback();
        again.carId = this.carId;
        again.tries = this.tries;
        again.waits = this.waits + (CBWaitCounts(game) ? 1 : 0);
        again.target = this.target;
        again.retargets = this.retargets;
        again.slot = this.slot;
        again.stuck = this.stuck;
        again.braked = this.braked;
        again.chasing = this.chasing;
        let dsW = GameInstance.GetDelaySystem(game);
        if IsDefined(dsW) {
          dsW.DelayCallback(again, CBConfig.ArrivalDismountPoll(), false);
        }
      }
      return;
    }
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let car = GameInstance.FindEntityByID(game, this.carId) as VehicleObject;
    // A car that is gone (shot up, despawned) still means the crew should be let out.
    let arrived = true;
    // Nobody gets out of a car that is still moving, and nobody gets out while V is driving:
    // then it is a car chase and they stay in it. Both waits are bounded, so a car that never
    // stops still lets its crew out in the end.
    let moving = false;
    if IsDefined(car) && car.IsAttached() {
      arrived = Vector4.Distance(car.GetWorldPosition(), player.GetWorldPosition())
                <= CBConfig.ArrivalDismountDistance();
      moving = AbsF(car.GetCurrentSpeed()) > CBConfig.ArrivalDismountMaxSpeed();
    }
    let vDriving = IsDefined(player.GetMountedVehicle());
    let vReallyDriving = vDriving;
    // Nobody gets out at a job, or into the story: while V is on one, or the story has the stage,
    // they stay in the car (bounded, like the rest).
    let sysD = CyberbaneSystem.Get(game);
    if IsDefined(sysD) && (sysD.IsInQuestArea() || sysD.IsOnJob() || sysD.GetStoryHold() != CBStoryNone()) {
      vDriving = true;
    }
    // There, and still rolling: the order was to where V stood when it was given, and V has moved or the car would be
    // slowing already. Left alone it drives on past V to that spot.
    let braked = this.braked;
    if IsDefined(car) && car.IsAttached() && arrived && moving && !vDriving && !braked {
      car.ForceBrakesUntilStoppedOrFor(CBConfig.ArrivalBrakeSeconds());
      braked = true;
    }
    let holdOn = !arrived && this.tries < CBConfig.ArrivalDismountMaxTries();
    if !holdOn && (moving || vDriving) && this.tries < CBConfig.ArrivalDismountMaxTries() * 3 {
      holdOn = true;
    }
    // Sitting still short of V, with nothing to wait for: it cannot get through. Told once more, in case it only lost
    // its order, and then the crew get out and come on foot.
    let carHere = IsDefined(car) && car.IsAttached();
    let stalled = carHere && !arrived && this.tries > 1 && AbsF(car.GetCurrentSpeed()) < CBConfig.CarStuckSpeed();
    let stuck = stalled ? this.stuck + 1 : 0;
    if stuck == CBConfig.CarStuckRetryPolls() && !vDriving {
      CBDriveAtPlayer(game, car, player);
    }
    if stuck >= CBConfig.CarStuckGiveUpPolls() && !vDriving {
      CBLog.Info(n"Spawn", s"The car could not get through after \(this.tries) checks; its crew come on foot.");
      CBDismountArrivalCrew(game, this.slot);
      CBWatchCrewOut(game, this.slot);
      return;
    }
    // V got into a car or out of one: a different chase, so a different order (CBDriveAtPlayer).
    let chasing = this.chasing;
    if holdOn && carHere && NotEquals(vReallyDriving, chasing) {
      CBDriveAtPlayer(game, car, player);
      chasing = vReallyDriving;
      this.target = player.GetWorldPosition();
    }
    // V on foot has moved well away from where the car was sent: send it on to where V is now.
    if holdOn && !arrived && !vDriving && IsDefined(car) && car.IsAttached()
       && this.retargets < CBConfig.ArrivalMaxRetargets()
       && this.tries > 0 && this.tries % CBConfig.ArrivalRetargetEvery() == 0
       && Vector4.Distance(player.GetWorldPosition(), this.target) > CBConfig.ArrivalRetargetDistance() {
      CBDriveAtPlayer(game, car, player);
      this.target = player.GetWorldPosition();
      this.retargets += 1;
    }
    if holdOn {
      if IsDefined(sysD) {
        sysD.NoteCarOnTheWay();
      }
      let next = new CBArrivalDismountCallback();
      next.carId = this.carId;
      next.tries = this.tries + 1;
      next.target = this.target;
      next.retargets = this.retargets;
      next.slot = this.slot;
      next.stuck = stuck;
      next.braked = braked;
      next.chasing = chasing;
      let dsN = GameInstance.GetDelaySystem(game);
      if IsDefined(dsN) {
        dsN.DelayCallback(next, CBConfig.ArrivalDismountPoll(), false);
      }
      return;
    }
    CBLog.Info(n"Spawn", s"Car arrived (or was given up on) after \(this.tries) checks; crew getting out.");
    // Parked next to V, having been sent to V: there is nothing left for them to search for.
    if carHere && arrived && !vDriving {
      CBHuntCrewPulledUp(sysD, game);
      // Heard before they are seen: the car's horn as it pulls up, and the first of them out shouting.
      CBCarHorn(game, car, n"CarArrives", 10.0);
      if IsDefined(sysD) {
        CBArrivalVoices(sysD, game, CBLiveTaggedPresent(game, n"CB_Apex") ? n"CB_Apex" : n"CB_Squad");
      }
    }
    CBDismountArrivalCrew(game, this.slot);
    CBWatchCrewOut(game, this.slot);
  }
}

// Getting out is asked for, and the event can land while somebody is busy.
public class CBArrivalCrewOutCallback extends DelayCallback {
  public let slot: Int32;
  public let tries: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    let seated = 1;
    if CBWorldStable(game) {
      seated = CBAskSeatedCrewOut(game, this.slot);
    }
    if seated == 0 {
      return;
    }
    if this.tries >= CBConfig.ArrivalCrewOutTries() {
      CBLog.Info(n"Spawn", s"\(seated) of a car's crew would not get out.");
      return;
    }
    let ds = GameInstance.GetDelaySystem(game);
    if IsDefined(ds) {
      let next = new CBArrivalCrewOutCallback();
      next.slot = this.slot;
      next.tries = this.tries + 1;
      ds.DelayCallback(next, CBConfig.ArrivalDismountPoll(), false);
    }
  }
}

public func CBWatchCrewOut(game: GameInstance, slot: Int32) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) {
    return;
  }
  let watch = new CBArrivalCrewOutCallback();
  watch.slot = slot;
  ds.DelayCallback(watch, CBConfig.ArrivalDismountPoll(), false);
}

// Ask anybody of this car still in a seat to get out, and say how many that was.
func CBAskSeatedCrewOut(game: GameInstance, slot: Int32) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return 0;
  }
  let seated = 0;
  let ids = des.GetTaggedIDs(CBCarSlotTag(slot));
  let i = 0;
  while i < ArraySize(ids) {
    let puppet = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBUnmountAgain(game, puppet) {
      seated += 1;
    }
  }
  return seated;
}

// Which car of a convoy a crew member came in, as a tag (0 is the first car).
public func CBCarSlotTag(slot: Int32) -> CName {
  switch slot {
    case 0: return n"CB_Car0";
    case 1: return n"CB_Car1";
    case 2: return n"CB_Car2";
    case 3: return n"CB_Car3";
    default: return n"CB_Car4";
  }
}

// Order everybody who came in this car to get out and come for V.
public func CBDismountArrivalCrew(game: GameInstance, slot: Int32) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let ids = des.GetTaggedIDs(CBCarSlotTag(slot));
  let i = 0;
  while i < ArraySize(ids) {
    let puppet = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if IsDefined(puppet) && !puppet.IsDead() && puppet.IsAttached() {
      // Only somebody actually sitting in a car gets told to get out of one, and only once (CBUnmountOnce). The hunt
      // orders them on once they are on their feet: a move order given to somebody still in a seat is not one the game
      // expects.
      if VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) {
        CBUnmountOnce(game, puppet);
      } else {
        CBOrderPursue(CyberbaneSystem.Get(game), game, puppet);
      }
    }
  }
}

// Set the car moving once its crew is aboard.
public class CBArrivalDriveCallback extends DelayCallback {
  public let carId: EntityID;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let again = new CBArrivalDriveCallback();
        again.carId = this.carId;
        again.waits = this.waits + (CBWaitCounts(game) ? 1 : 0);
        let dsW = GameInstance.GetDelaySystem(game);
        if IsDefined(dsW) {
          dsW.DelayCallback(again, CBConfig.CarStartDelay(), false);
        }
      }
      return;
    }
    let car = GameInstance.FindEntityByID(game, this.carId) as VehicleObject;
    let player = GetPlayer(game);
    if !IsDefined(car) || !IsDefined(player) || !car.IsAttached() {
      return;
    }
    CBDriveAtPlayer(game, car, player);
  }
}

// Hand a crewed car its chase order.
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
    CBTrace("vehicle: chase order");
    car.QueueEvent(evt);
    ai.SetInitCmd(chase);
    return;
  }
  CBLog.Info(n"Spawn", "Car has its crew and is driving to you.");
  CBTrace("vehicle: drive order");
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

// ---- Out of the attach event ---------------------------------------------------
//
// The car's crew used to be created, and each of them seated, from inside the engine's own attach notification for the
// car and for them.

public class CBConvoyBoardCallback extends DelayCallback {
  public let carId: EntityID;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) {
      return;
    }
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let again = new CBConvoyBoardCallback();
        again.carId = this.carId;
        again.waits = this.waits + (CBWaitCounts(game) ? 1 : 0);
        let ds = GameInstance.GetDelaySystem(game);
        if IsDefined(ds) {
          ds.DelayCallback(again, CBConfig.ConvoyStepDelay(), false);
          return;
        }
      }
      sys.ClearPendingArrival();
      return;
    }
    let car = GameInstance.FindEntityByID(game, this.carId) as VehicleObject;
    if !IsDefined(car) || !car.IsAttached() {
      sys.ClearPendingArrival();
      return;
    }
    CBOnArrivalCarAttached(sys, game, car);
  }
}

public class CBConvoyMountCallback extends DelayCallback {
  public let puppetId: EntityID;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) {
      return;
    }
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let again = new CBConvoyMountCallback();
        again.puppetId = this.puppetId;
        again.waits = this.waits + (CBWaitCounts(game) ? 1 : 0);
        let ds = GameInstance.GetDelaySystem(game);
        if IsDefined(ds) {
          ds.DelayCallback(again, CBConfig.ConvoyStepDelay(), false);
        }
      }
      return;   // never seated; the top-up or the hunt brings them in on foot
    }
    let puppet = GameInstance.FindEntityByID(game, this.puppetId) as ScriptedPuppet;
    if !CBStillStanding(puppet) || !puppet.IsAttached() {
      return;
    }
    CBOnArrivalCrewAttached(sys, game, puppet);
  }
}

public func CBScheduleConvoyBoard(game: GameInstance, carId: EntityID) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) || !EntityID.IsDefined(carId) {
    return;
  }
  let cb = new CBConvoyBoardCallback();
  cb.carId = carId;
  ds.DelayCallback(cb, CBConfig.ConvoyStepDelay(), false);
}

public func CBScheduleConvoyMount(game: GameInstance, puppetId: EntityID) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) || !EntityID.IsDefined(puppetId) {
    return;
  }
  let cb = new CBConvoyMountCallback();
  cb.puppetId = puppetId;
  ds.DelayCallback(cb, CBConfig.ConvoyStepDelay(), false);
}
