// Cyberbane - Borrowing the police chase (spec §9.9)
//
// The game already has a working vehicle chase. It is what the NCPD do to you: a car is placed
// somewhere sensible on the road network, filled with the right people, and driven at you with
// proper pathing, and it keeps coming across junctions and districts. Cyberbane spent several
// versions hand-rolling a worse version of that - pick a point, drop a car on it, mount a crew,
// issue a drive command - and the result was a car the player never actually saw arrive.
//
// So this asks the game to do it instead:
//
//   PreventionSpawnSystem.RequestChaseVehicle(vehicleRecord, crewRecords, strategyRequest)
//
// with `GetToPlayerFromAnywhereStrategyRequest`, which is the strategy meaning "wherever this
// car is, get it to the player". The other strategies the game uses are there too, including
// intercepting at the next junction and driving away, if this is ever worth extending.
//
// One wrinkle, and the reason this file exists at all rather than being three lines. The system
// hands back a ticket number and offers no way to ask what it spawned, so everything Cyberbane
// does downstream - the lanes knowing an encounter is live, the buffs, the role kits, the boss
// bar, the despawn sweep, the giving-up-when-you-escape - would be blind to them. They would be
// somebody else's NPCs that happened to be chasing you.
//
// The fix is to adopt them. For a few seconds after asking, any entity that attaches matching
// what was asked for gets Cyberbane's tags put on it, and from that point it is treated exactly
// like one of ours. The window is short and counts down as it adopts, so an unrelated ganger
// of the same kind streaming in at that exact moment is the worst case, and the worst case is
// one extra enemy in a fight that was already happening.

// Ask the game to send a car, the way it sends police.
//
// Returns false when the prevention system is not available, which is the caller's cue to fall
// back to Cyberbane's own spawner.
public func CBRequestVanillaChase(sys: ref<CyberbaneSystem>, game: GameInstance, factionId: CName,
                                  crewRecord: TweakDBID, crewCount: Int32, squadTag: CName) -> Bool {
  if !IsDefined(sys) || !TDBID.IsValid(crewRecord) || crewCount <= 0 {
    return false;
  }
  // Straight off the game instance.
  //
  // This went through the scriptable systems container, which cannot work, and the compiler
  // said so on every build: "this cast cannot succeed, because 'PreventionSpawnSystem' is not
  // related to 'ScriptableSystem'". It is an IGameSystem, not a ScriptableSystem. So the cast
  // returned null, this function returned false, and every crew that should have pulled up in
  // a car walked in instead - which is why a car has never once been seen arriving, standing
  // in the middle of an empty street or anywhere else. GameInstance has a typed accessor for
  // it, which SafeAreas.reds was already using correctly two files away.
  let prevention = GameInstance.GetPreventionSpawnSystem(game);
  if !IsDefined(prevention) {
    return false;
  }
  let vehicle = CBChaseVehicle(factionId, crewCount);
  if !TDBID.IsValid(vehicle) {
    return false;
  }
  // Never ask for more people than the record will seat. Vanilla sizes the crew from the
  // record and not from the caller, so the surplus is simply dropped, and a record with no
  // capacity at all drops everybody.
  let seats = CBChaseVehicleSeats(vehicle);
  if seats <= 0 {
    CBLog.Info(n"Spawn", "Chase car record seats nobody; falling back to our own convoy.");
    return false;
  }
  let seated = crewCount < seats ? crewCount : seats;
  // Fill the seats by role where the gang has them, so handing the chase to the city does not
  // cost the apex squad its shape - a heavy, a shooter, a blade and a netrunner rather than
  // four copies of one record.
  let fs = sys.FindFaction(factionId);
  let crew: array<TweakDBID>;
  let i = 0;
  while i < seated {
    let seat = Equals(squadTag, n"CB_Apex") ? CBApexRoleRecord(fs, i, crewRecord) : crewRecord;
    ArrayPush(crew, seat);
    i += 1;
  }
  // Is there anywhere for a car to come from at all?
  //
  // This is the guard vanilla opens with and Cyberbane did not have. `SpawnPoliceVehicle`
  // bails before it asks for anything if `IsAnyStrategyAvailable()` is false
  // (`core/systems/preventionSystem.script:3081`), and it picks its strategy by asking which
  // ones are available rather than naming one. Availability is about the road network around
  // the player: on a pedestrian street, a rooftop, inside a parking structure, nothing is.
  if !prevention.IsAnyStrategyAvailable() {
    CBLog.Info(n"Spawn", "No chase strategy is available here; falling back to our own convoy.");
    return false;
  }
  let request = CBChaseStrategyRequest(game, prevention);
  if !IsDefined(request) {
    CBLog.Info(n"Spawn", "No usable chase strategy here; falling back to our own convoy.");
    return false;
  }
  // Roles are carried in the crew list above, so the flag the hand-rolled convoy uses to pick
  // them per seat has no job here. Clearing it keeps it from being left set and quietly
  // changing how a later fallback convoy fills itself.
  sys.ClearPendingArrival();
  // Open the adoption window before asking, because the spawn can attach immediately.
  sys.OpenAdoption(factionId, crewRecord, vehicle, squadTag, seated);
  let ticket = prevention.RequestChaseVehicle(vehicle, crew, request);
  // Zero is the ticket the system hands back when it did not take the request: vanilla
  // initialises `ticketID` to 0 and returns it unchanged on every early exit, then only
  // registers the ticket with its agent registry when the call produced one. Treating a
  // refusal as an acceptance is how a car could be "sent" and never exist.
  if ticket == 0u {
    sys.CloseAdoption();
    CBLog.Info(n"Spawn", "The city refused the chase request; falling back to our own convoy.");
    return false;
  }
  CBLog.Info(n"Spawn", s"Asked the city to send a car from \(NameToString(factionId)) with \(seated) aboard (ticket \(ticket)).");
  return true;
}

// Build the strategy request, with the game's own numbers in it.
//
// This is the bug that kept vehicle arrivals from ever being seen, and it is a one-line bug
// hiding behind a working-looking call. Cyberbane passed `new GetToPlayerFromAnywhereStrategyRequest()`:
// a bare instance, with `distanceRange` left at (0, 0) and `minDirectDistance` at 0. Vanilla
// never constructs one that way. `PreventionSystem.CreateStrategyRequest`
// (`core/systems/preventionSystem.script:3031`) always goes through the static `Create`, and
// always feeds it the range off the heat table:
//
//     GetToPlayerFromAnywhereStrategyRequest.Create(
//         m_preventionDataTable.Strategy5().VehicleSpawnDistanceRange(),
//         m_preventionDataTable.Strategy5().MinDirectDistance() )
//
// A request asking for a road point between zero and zero metres from the player has nothing
// to satisfy it, so the system accepted the request and found nowhere to put a car - which is
// exactly the symptom: dispatched every time, never once arriving. The heat table is reachable
// through `PreventionSystem.GetPreventionHeatTableRecord`, so these are the game's figures and
// not a guess at what they ought to be.
//
// Strategy choice follows vanilla too: ask which ones are available and take one, rather than
// naming the hardest one and hoping. GetToPlayerFromAnywhere is preferred because it is the
// one that means "wherever this car is, bring it to the player", and it is what an arrival
// wants; DriveTowardsPlayer and InterceptAtNextIntersection are the fallbacks, and both still
// end up with a car converging on V.
func CBChaseStrategyRequest(game: GameInstance, prevention: ref<PreventionSpawnSystem>) -> ref<BaseStrategyRequest> {
  let table = PreventionSystem.GetPreventionHeatTableRecord(game);
  if !IsDefined(table) {
    return null;
  }
  if prevention.IsStrategyAvailable(vehiclePoliceStrategy.GetToPlayerFromAnywhere) {
    let s5 = table.Strategy5();
    if IsDefined(s5) {
      return GetToPlayerFromAnywhereStrategyRequest.Create(s5.VehicleSpawnDistanceRange(),
                                                           s5.MinDirectDistance());
    }
  }
  if prevention.IsStrategyAvailable(vehiclePoliceStrategy.DriveTowardsPlayer) {
    let s1 = table.Strategy1();
    if IsDefined(s1) {
      return DriveTowardsPlayerStrategyRequest.Create(s1.VehicleSpawnDistanceRange(),
                                                      s1.MinDirectDistance());
    }
  }
  if prevention.IsStrategyAvailable(vehiclePoliceStrategy.InterceptAtNextIntersection) {
    let s4 = table.Strategy4();
    if IsDefined(s4) {
      return InterceptAtNextIntersectionStrategyRequest.Create(s4.VehicleSpawnDistanceRange(),
                                                               s4.MinDirectDistance());
    }
  }
  return null;
}

// Does this freshly attached entity look like something we just asked for?
//
// Deliberately strict: the window has to be open, the record has to be exactly the one that was
// requested, and there has to be an unclaimed seat left. Anything else is left alone.
public func CBTryAdoptChaseEntity(sys: ref<CyberbaneSystem>, game: GameInstance, entity: ref<Entity>) -> Bool {
  if !IsDefined(sys) || !IsDefined(entity) || !sys.IsAdoptionOpen() {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let id = entity.GetEntityID();

  // The car itself: tagged only so the session sweep can clear it. The game is driving it and
  // nothing of ours should interfere with that.
  let car = entity as VehicleObject;
  if IsDefined(car) {
    let rec: ref<Vehicle_Record>;
    VehicleComponent.GetVehicleRecord(car, rec);
    if IsDefined(rec) && Equals(rec.GetID(), sys.GetAdoptVehicle()) {
      des.AssignTag(id, n"Cyberbane");
      CBLog.Info(n"Spawn", "Adopted the car the city sent.");
      return true;
    }
    return false;
  }

  let puppet = entity as ScriptedPuppet;
  if !IsDefined(puppet) {
    return false;
  }
  // Any record this gang is known to field, since the seats are filled by role and are not
  // all the same record.
  if !CBAdoptableRecord(sys, puppet.GetRecordID()) {
    return false;
  }
  if sys.TakeAdoptionSlot() < 0 {
    return false;
  }
  des.AssignTag(id, n"Cyberbane");
  des.AssignTag(id, sys.GetAdoptTag());
  // From here they are one of ours: the lanes see them, they get their buffs and kit, they
  // chase properly, and they give up when you lose them.
  CBScheduleSpawnSetup(game, id, true);
  CBLog.Info(n"Spawn", "Adopted one of the crew the city sent.");
  return true;
}

// Is this one of the records the gang we just asked for would have sent?
func CBAdoptableRecord(sys: ref<CyberbaneSystem>, record: TweakDBID) -> Bool {
  if !TDBID.IsValid(record) {
    return false;
  }
  if Equals(record, sys.GetAdoptRecord()) {
    return true;
  }
  let fs = sys.FindFaction(sys.GetAdoptFaction());
  if !IsDefined(fs) {
    return false;
  }
  return Equals(record, fs.sampleRecord)
      || Equals(record, fs.eliteRecord)
      || Equals(record, fs.roleTankRecord)
      || Equals(record, fs.roleAssaultRecord)
      || Equals(record, fs.roleBladeRecord)
      || Equals(record, fs.roleNetrunnerRecord);
}
