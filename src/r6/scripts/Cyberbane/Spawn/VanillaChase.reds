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
  //
  // It is also only ever true if somebody asked the road network the question first, which is
  // what CBChasePrimeTick below is for. Without it this was false every time outside a police
  // chase, and every car request fell back.
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
  sys.NoteCarPath(true, seated);
  CBLog.Info(n"Spawn", s"Asked the city to send a car from \(NameToString(factionId)) with \(seated) aboard (ticket \(ticket)).");
  return true;
}

// ---- Letting the city find a road ----------------------------------------
//
// Why no car ever turned up, found by reading the prevention system rather than the request.
// `IsAnyStrategyAvailable` and `IsStrategyAvailable` do not look at the road network when they
// are called. They report the results of "pre-check" requests the system has been given in
// advance and evaluates in the background. The police set those up in
// `PreventionSystem.UpdateStrategyPreCheckRequests` (core/systems/preventionSystem.script:2986),
// and outside a police chase that function clears them and sets nothing. So with no heat,
// nothing was ever available, and every car Cyberbane asked for fell back before it was asked.
//
// So Cyberbane hands the system the same three questions its own chase uses, a little before a
// car could be needed, and keeps them current while one might be. It never touches them while
// the police are chasing, because then the police's own, larger set is in place and covers ours;
// and when Cyberbane is done it clears only what it set, again only when the police are not
// chasing. The police set theirs afresh every time their heat changes, so nothing here can
// leave them without what they need.

func CBChaseRequests(game: GameInstance, prevention: ref<PreventionSpawnSystem>) -> array<ref<BaseStrategyRequest>> {
  let out: array<ref<BaseStrategyRequest>>;
  let table = PreventionSystem.GetPreventionHeatTableRecord(game);
  if !IsDefined(table) {
    return out;
  }
  let s5 = table.Strategy5();
  if IsDefined(s5) {
    ArrayPush(out, GetToPlayerFromAnywhereStrategyRequest.Create(CBChaseRange(s5.VehicleSpawnDistanceRange()),
                                                                 s5.MinDirectDistance()));
  }
  let s1 = table.Strategy1();
  if IsDefined(s1) {
    ArrayPush(out, DriveTowardsPlayerStrategyRequest.Create(CBChaseRange(s1.VehicleSpawnDistanceRange()),
                                                            s1.MinDirectDistance()));
  }
  let s4 = table.Strategy4();
  if IsDefined(s4) {
    ArrayPush(out, InterceptAtNextIntersectionStrategyRequest.Create(CBChaseRange(s4.VehicleSpawnDistanceRange()),
                                                                     s4.MinDirectDistance()));
  }
  return out;
}

// The heat table's spawn range, unless it is empty, in which case Cyberbane's own. The table
// in use outside a chase is the Heat_0 one, and a range of nothing there would be the old
// zero-to-zero bug by another route.
func CBChaseRange(r: Vector2) -> Vector2 {
  if r.Y <= 0.0 || r.Y < r.X {
    return new Vector2(CBConfig.ChaseSpawnRangeMin(), CBConfig.ChaseSpawnRangeMax());
  }
  return r;
}

public func CBPrimeChaseStrategies(game: GameInstance) -> Bool {
  if PreventionSystem.IsChasingPlayer(game) {
    return false;   // the police's own set is in place and covers ours
  }
  let prevention = GameInstance.GetPreventionSpawnSystem(game);
  if !IsDefined(prevention) {
    return false;
  }
  let reqs = CBChaseRequests(game, prevention);
  if ArraySize(reqs) == 0 {
    return false;
  }
  prevention.SetStrategyPreCheckRequests(reqs);
  return true;
}

public func CBReleaseChaseStrategies(game: GameInstance) -> Void {
  if PreventionSystem.IsChasingPlayer(game) {
    return;   // theirs now; leave them alone
  }
  let prevention = GameInstance.GetPreventionSpawnSystem(game);
  if IsDefined(prevention) {
    prevention.ClearStrategyPreCheckRequests();
  }
}

// Once per fast tick. Primes while a car could be needed soon, refreshes every few seconds so a
// police chase that came and went cannot leave it cleared, and lets go when nothing is coming.
public func CBChasePrimeTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let want = CBVehicleArrivalsOn() && CBCarCouldBeNeeded(sys);
  if want {
    if !sys.IsChasePrimed() || sys.GetTickCount() % CBConfig.ChasePrimeRefreshTicks() == 0 {
      sys.SetChasePrimed(CBPrimeChaseStrategies(game));
    }
    return;
  }
  if sys.IsChasePrimed() {
    CBReleaseChaseStrategies(game);
    sys.SetChasePrimed(false);
  }
}

func CBVehicleArrivalsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && rt.HasSettings() && rt.GetSettings().vehicleArrivals;
}

// Is any lane about to send somebody, or is an arrival already under way?
func CBCarCouldBeNeeded(sys: ref<CyberbaneSystem>) -> Bool {
  if sys.IsAdoptionOpen() || NotEquals(sys.GetPendingApexFaction(), n"")
     || NotEquals(sys.GetPendingSquadFaction(), n"") {
    return true;
  }
  let lead = CBConfig.ChasePrimeLeadTicks();
  return CBLaneSoon(sys, CBLaneRival(), lead) || CBLaneSoon(sys, CBLaneSquad(), lead)
      || CBLaneSoon(sys, CBLaneApex(), lead);
}

func CBLaneSoon(sys: ref<CyberbaneSystem>, lane: Int32, lead: Int32) -> Bool {
  let queued = NotEquals(sys.GetLaneTarget(lane), n"") || sys.GetLaneRivalId(lane) > 0;
  return queued && sys.GetLaneTicks(lane) <= lead;
}

// ---- Getting out of the car ------------------------------------------------
//
// The city drives its chase car at V, but getting out is something the police do because the
// prevention system registers them and runs them; a gang crew it carried for Cyberbane is not
// registered (`PreventionSystem.OnPreventionUnitSpawnedRequest` drops a ticket it did not
// issue), so nothing would ever tell them to get out. Each one Cyberbane adopts is watched: once
// their car is close to V and V is on foot, they get out and come for V. While V is driving
// they stay in and the car keeps chasing, and the chase gives up the usual way if V gets clear.
public class CBMountedCrewWatch extends DelayCallback {
  public let entityId: EntityID;
  public let tries: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    // Never in the middle of a load or a fast travel: that is when native entity queries from a
    // delayed callback crash. Waiting costs one try.
    if !CBWorldStable(game) {
      if this.tries < CBConfig.ArrivalDismountMaxTries() * 3 {
        this.Again(game);
      }
      return;
    }
    let player = GetPlayer(game);
    let puppet = GameInstance.FindEntityByID(game, this.entityId) as ScriptedPuppet;
    if !IsDefined(player) || !CBStillStanding(puppet) || !puppet.IsAttached() {
      return;
    }
    let mounted = VehicleComponent.IsMountedToVehicle(game, this.entityId);
    if !mounted {
      // Out already, or never seated. Either way they should be coming for V.
      if this.tries >= CBConfig.CrewWatchSettleTries() {
        CBOrderPursue(CyberbaneSystem.Get(game), game, puppet);
        return;
      }
      this.Again(game);
      return;
    }
    let playerDriving = IsDefined(player.GetMountedVehicle());
    let car: wref<VehicleObject>;
    VehicleComponent.GetVehicle(game, this.entityId, car);
    let close = !IsDefined(car)
             || Vector4.Distance(car.GetWorldPosition(), player.GetWorldPosition())
                <= CBConfig.ArrivalDismountDistance();
    let waitedLong = this.tries >= CBConfig.ArrivalDismountMaxTries();
    if !playerDriving && (close || waitedLong) {
      let ai = puppet.GetAIControllerComponent();
      if IsDefined(ai) {
        ai.SendCommand(new AIUnmountCommand());
      }
      CBOrderPursue(CyberbaneSystem.Get(game), game, puppet);
      return;
    }
    // Riding along on a car chase. Bounded, so a crew stuck in traffic for ever stops being
    // polled; the chase's own give-up clears them if V has got away.
    if this.tries < CBConfig.ArrivalDismountMaxTries() * 3 {
      this.Again(game);
    }
  }

  private func Again(game: GameInstance) -> Void {
    let ds = GameInstance.GetDelaySystem(game);
    if !IsDefined(ds) {
      return;
    }
    let next = new CBMountedCrewWatch();
    next.entityId = this.entityId;
    next.tries = this.tries + 1;
    ds.DelayCallback(next, CBConfig.ArrivalDismountPoll(), false);
  }
}

func CBWatchMountedCrew(game: GameInstance, id: EntityID) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) || !EntityID.IsDefined(id) {
    return;
  }
  let watch = new CBMountedCrewWatch();
  watch.entityId = id;
  watch.tries = 0;
  ds.DelayCallback(watch, CBConfig.ArrivalDismountPoll(), false);
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
      return GetToPlayerFromAnywhereStrategyRequest.Create(CBChaseRange(s5.VehicleSpawnDistanceRange()),
                                                           s5.MinDirectDistance());
    }
  }
  if prevention.IsStrategyAvailable(vehiclePoliceStrategy.DriveTowardsPlayer) {
    let s1 = table.Strategy1();
    if IsDefined(s1) {
      return DriveTowardsPlayerStrategyRequest.Create(CBChaseRange(s1.VehicleSpawnDistanceRange()),
                                                      s1.MinDirectDistance());
    }
  }
  if prevention.IsStrategyAvailable(vehiclePoliceStrategy.InterceptAtNextIntersection) {
    let s4 = table.Strategy4();
    if IsDefined(s4) {
      return InterceptAtNextIntersectionStrategyRequest.Create(CBChaseRange(s4.VehicleSpawnDistanceRange()),
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
  // A Rival riding in: this body is theirs, which is what makes their death count and their
  // escape count. The look they carry is put back on once the puppet has finished building
  // (CBApplySpawnSetup), because the city's chase cannot be told which appearance to use.
  if Equals(sys.GetAdoptTag(), n"CB_Rival") {
    let who = sys.FindRivalById(sys.GetActiveRivalId());
    if IsDefined(who) && !EntityID.IsDefined(who.spawnedEntityId) {
      who.spawnedEntityId = id;
    }
  }
  // From here they are one of ours: the lanes see them, they get their buffs and kit, they
  // chase properly, they get out of the car when it reaches V, and they give up when you lose
  // them.
  CBScheduleSpawnSetup(game, id, true);
  CBWatchMountedCrew(game, id);
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
