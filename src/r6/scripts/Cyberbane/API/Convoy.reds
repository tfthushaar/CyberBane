// Cyberbane - a convoy that travels (extension API level 1, 2.7.4)
//
// Cyberbane's own cars only ever drive at V (Spawn/Arrival.reds, CBDriveAtPlayer). A convoy drives a route as a group,
// with the game's own vehicle orders, given the way Cyberbane already gives them (an AICommandEvent and the AI component's
// first order): the lead on AIVehicleDriveToPointAutonomousCommand from one route point to the next, the escorts on
// AIVehicleFollowCommand on the lead, six to eighteen metres back. On contact (one of its people fighting V) the escorts
// turn on V with AIVehicleChaseCommand, ramming if asked, and the lead carries on to its destination or runs for it
// (AIVehiclePanicCommand). A car that stops lets its people out to fight on foot, as Cyberbane's arrivals do. The numbers
// follow the game's own chase set-up (dynamicSpawnSystem.script: 3 to 10 metres, a start speed of 10), read, not called.
//
// Until V is within reach it is only on paper: a position along its route, by time and speed. Then its cars are put on
// the ground near that position out of V's sight, its crews seated (MountAIEvent, the way an arrival's crew boards), and
// it drives. Everything goes through Cyberbane's gates and room, and comes out the safe way: crews unseated first, nobody
// removed from a seat or in V's sight.
//
// For add-ons (CyberbaneAPI.RequestConvoy); Cyberbane's own arrivals are unchanged. Formation at speed on Badlands roads is
// the nomad expansion's spike S-2: the log says what each convoy did.

public func CBConvoyPaper() -> Int32 = 0
public func CBConvoyBoarding() -> Int32 = 1
public func CBConvoyDriving() -> Int32 = 2
public func CBConvoyContact() -> Int32 = 3
public func CBConvoyDone() -> Int32 = 4

// How it ended (2.7.5, API level 2, ConvoyOutcome): kept a while after it is off the road.
public func CBConvoyOutcomeRunning() -> Int32 = 0
public func CBConvoyOutcomeArrived() -> Int32 = 1
public func CBConvoyOutcomeBroken() -> Int32 = 2
public func CBConvoyOutcomeGotAway() -> Int32 = 3
public func CBConvoyOutcomeReleased() -> Int32 = 4
public func CBConvoyOutcomeUnknown() -> Int32 = -1

public class CBConvoySpec {
  public let faction: CName;
  public let vehicles: array<TweakDBID>;   // lead first; empty: the faction's own cars (CBArrivalVehicle)
  public let cars: Int32;                  // how many, when vehicles is empty (1 to 4)
  public let crew: array<TweakDBID>;       // people only, cycled over the seats
  public let route: array<Vector4>;        // 2 to 4 points in order; the last is where it is going
  public let startsIn: Float;              // game seconds before it sets off from the first point
  public let speed: Float;                 // metres a second on paper (0: 14)
  public let hostile: Bool;                // its people are hostile to V
  public let rams: Bool;                   // its escorts ram once it comes to a fight
  public let leadFlees: Bool;              // its lead runs for it once it comes to a fight, rather than carry on
}

public class CBConvoyRun {
  public let handle: Int32;
  public let spec: ref<CBConvoySpec>;
  public let state: Int32;
  public let setOff: Float;
  public let leg: Int32;
  public let placedTick: Int32;
  public let cars: array<EntityID>;
  public let carSeats: array<Int32>;       // seats used, per car
  public let crewIds: array<EntityID>;
  public let crewCar: array<Int32>;
  public let crewSeat: array<CName>;
  public let releasing: Bool;
  public let outcome: Int32;
  // Ticks V has been out of reach of it while it was in a fight (R4).
  public let awayTicks: Int32;

  public func Tag() -> CName {
    return StringToName("CB_Convoy" + IntToString(this.handle));
  }
}

public class CBApiConvoys extends ScriptableSystem {
  private let m_runs: array<ref<CBConvoyRun>>;
  private let m_next: Int32;
  private let m_lastWhy: String;
  private let m_doneHandles: array<Int32>;
  private let m_doneOutcomes: array<Int32>;

  public static func Get(game: GameInstance) -> ref<CBApiConvoys> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiConvoys") as CBApiConvoys : null;
  }

  public func LastWhy() -> String { return this.m_lastWhy; }
  public func SetWhy(why: String) -> Void { this.m_lastWhy = why; }

  public func Add(spec: ref<CBConvoySpec>, setOff: Float) -> Int32 {
    this.m_next += 1;
    let run = new CBConvoyRun();
    run.handle = this.m_next;
    run.spec = spec;
    run.state = CBConvoyPaper();
    run.setOff = setOff;
    ArrayPush(this.m_runs, run);
    return run.handle;
  }

  public func Find(handle: Int32) -> ref<CBConvoyRun> {
    for r in this.m_runs {
      if IsDefined(r) && r.handle == handle {
        return r;
      }
    }
    return null;
  }

  public func Runs() -> array<ref<CBConvoyRun>> { return this.m_runs; }

  public func Remove(run: ref<CBConvoyRun>) -> Void {
    ArrayRemove(this.m_runs, run);
    if IsDefined(run) {
      ArrayPush(this.m_doneHandles, run.handle);
      ArrayPush(this.m_doneOutcomes, run.outcome);
      while ArraySize(this.m_doneHandles) > 32 {
        ArrayErase(this.m_doneHandles, 0);
        ArrayErase(this.m_doneOutcomes, 0);
      }
    }
  }

  // Running, how it ended, or unknown (a handle from before a load, or never given).
  public func Outcome(handle: Int32) -> Int32 {
    let run = this.Find(handle);
    if IsDefined(run) {
      return run.outcome;
    }
    let i = ArrayFindFirst(this.m_doneHandles, handle);
    return i >= 0 && i < ArraySize(this.m_doneOutcomes) ? this.m_doneOutcomes[i] : CBConvoyOutcomeUnknown();
  }

  // The one a body belongs to, by its convoy tag.
  public func RunOf(des: ref<DynamicEntitySystem>, id: EntityID) -> ref<CBConvoyRun> {
    for r in this.m_runs {
      if IsDefined(r) && des.IsTagged(id, r.Tag()) {
        return r;
      }
    }
    return null;
  }
}

// Where a convoy is on paper: its route walked at its speed since it set off; false once it is past the end.
public func CBConvoyPaperPos(run: ref<CBConvoyRun>, now: Float, out pos: Vector4, out leg: Int32) -> Bool {
  let route = run.spec.route;
  let n = ArraySize(route);
  if n == 0 {
    return false;
  }
  let speed = run.spec.speed > 0.0 ? run.spec.speed : 14.0;
  let travelled = MaxF(now - run.setOff, 0.0) * speed;
  let i = 0;
  pos = route[0];
  leg = 1;
  while i < n - 1 {
    let seg = Vector4.Distance(route[i], route[i + 1]);
    if travelled <= seg {
      let f = seg > 0.1 ? travelled / seg : 1.0;
      pos = new Vector4(route[i].X + (route[i + 1].X - route[i].X) * f, route[i].Y + (route[i + 1].Y - route[i].Y) * f,
                        route[i].Z + (route[i + 1].Z - route[i].Z) * f, 1.0);
      leg = i + 1;
      return true;
    }
    travelled -= seg;
    i += 1;
  }
  return false;
}

public func CBApiRequestConvoy(game: GameInstance, spec: ref<CBConvoySpec>) -> Int32 {
  let reg = CBApiConvoys.Get(game);
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(reg) || !IsDefined(spec) {
    return 0;
  }
  if !IsDefined(rt) || !rt.IsEnabled() {
    reg.SetWhy("Cyberbane is switched off");
    return 0;
  }
  if ArraySize(spec.route) < 2 || ArraySize(spec.crew) == 0 {
    reg.SetWhy("a convoy needs a route of two points or more, and a crew");
    return 0;
  }
  if NotEquals(spec.faction, n"") && !CBFactionOn(spec.faction) {
    reg.SetWhy("that faction is switched off under Factions");
    return 0;
  }
  let handle = reg.Add(spec, CBGameSeconds(game) + MaxF(spec.startsIn, 0.0));
  CBLog.Info(n"Spawn", s"An add-on's convoy is on its way on paper (handle \(handle)).");
  return handle;
}

// Its cars and crews on the ground near where it is on paper, out of V's sight. False to try again later.
func CBConvoyPlace(sys: ref<CyberbaneSystem>, game: GameInstance, run: ref<CBConvoyRun>, at: Vector4, ahead: Vector4) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(des) || !IsDefined(player) {
    return false;
  }
  let records: array<TweakDBID>;
  for v in run.spec.vehicles {
    if TDBID.IsValid(v) {
      ArrayPush(records, v);
    }
  }
  if ArraySize(records) == 0 {
    let k = 0;
    while k < Clamp(run.spec.cars, 1, 4) {
      let seats = 0;
      let rec = CBArrivalVehicle(run.spec.faction, CBConfig.CarMaxSeats(), RandRange(0, 4) + k, seats);
      if TDBID.IsValid(rec) && seats > 0 {
        ArrayPush(records, rec);
      }
      k += 1;
    }
  }
  if ArraySize(records) == 0 {
    return false;
  }
  let crewRecs: array<TweakDBID>;
  for c in run.spec.crew {
    if TDBID.IsValid(c) && CBRecordIsPerson(c) {
      ArrayPush(crewRecs, c);
    }
  }
  let seatsWanted = 0;
  for r in records {
    let names = CBVehicleSeatNames(r);
    seatsWanted += Min(ArraySize(names), CBConfig.CarMaxSeats());
  }
  if ArraySize(crewRecs) == 0 || CBSpawnRoom(game) < seatsWanted {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let fwd = player.GetWorldForward();
  let dir = new Vector4(ahead.X - at.X, ahead.Y - at.Y, 0.0, 0.0);
  let facing = Quaternion.BuildFromDirectionVector(Vector4.Length(dir) > 0.1 ? Vector4.Normalize(dir) : new Vector4(1.0, 0.0, 0.0, 0.0));
  let spots: array<Vector4>;
  if !CBPursuitPointsAround(game, ppos, at, ArraySize(records) * 2, 4.0, 60.0, spots) {
    return false;
  }
  let usable: array<Vector4>;
  for s in spots {
    if CBPointHiddenFrom(game, ppos, fwd, s) && !CBSafeAreaBlocksSpawn(game, s) {
      ArrayPush(usable, s);
    }
  }
  if ArraySize(usable) < ArraySize(records) {
    return false;
  }
  let tag = run.Tag();
  let ci = 0;
  let i = 0;
  while i < ArraySize(records) {
    let spec = new DynamicEntitySpec();
    spec.recordID = records[i];
    spec.position = usable[i];
    spec.orientation = facing;
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = false;
    spec.spawnInView = false;
    spec.active = true;
    spec.tags = [n"Cyberbane", n"CB_Convoy", tag];
    CBTrace("vehicle: creating a convoy car");
    let carId = des.CreateEntity(spec);
    if EntityID.IsDefined(carId) {
      ArrayPush(run.cars, carId);
      ArrayPush(run.carSeats, 0);
      let carIndex = ArraySize(run.cars) - 1;
      let names = CBVehicleSeatNames(records[i]);
      let s = 0;
      while s < Min(ArraySize(names), CBConfig.CarMaxSeats()) {
        let body: EntityID;
        if CBCreateSpawn(des, crewRecs[ci % ArraySize(crewRecs)], n"", usable[i], facing, n"CB_Convoy", body, tag) {
          ArrayPush(run.crewIds, body);
          ArrayPush(run.crewCar, carIndex);
          ArrayPush(run.crewSeat, names[s]);
        }
        ci += 1;
        s += 1;
      }
    }
    i += 1;
  }
  return ArraySize(run.cars) > 0 && ArraySize(run.crewIds) > 0;
}

// A crew member's body is in the world (Spawn/Spawner.reds): set up as a crew, then seated in their car.
public func CBApiConvoySetUp(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let reg = CBApiConvoys.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(reg) || !IsDefined(des) || !CBStillStanding(puppet) {
    return;
  }
  let run = reg.RunOf(des, puppet.GetEntityID());
  if !IsDefined(run) {
    return;
  }
  CBSetUpStreet(sys, game, puppet, run.spec.hostile);
  CBKitSquadMember(puppet);
  CBApplyCrewBuild(sys, game, puppet);
  let k = ArrayFindFirst(run.crewIds, puppet.GetEntityID());
  if k < 0 || k >= ArraySize(run.crewCar) || k >= ArraySize(run.crewSeat) || run.crewCar[k] >= ArraySize(run.cars) {
    return;
  }
  let car = GameInstance.FindEntityByID(game, run.cars[run.crewCar[k]]) as VehicleObject;
  if !IsDefined(car) || !car.IsAttached() || VehicleComponent.IsMountedToVehicle(game, puppet.GetEntityID()) {
    return;
  }
  let data = new MountEventData();
  data.slotName = run.crewSeat[k];
  data.mountParentEntityId = run.cars[run.crewCar[k]];
  data.isInstant = true;
  data.ignoreHLS = true;
  CBTrace("vehicle: seating a convoy crew member");
  let evt = new MountAIEvent();
  evt.name = n"Mount";
  evt.data = data;
  puppet.QueueEvent(evt);
}

// One order to one car: the game's way, the event and the first order together (as CBDriveAtPlayer gives them).
func CBConvoyOrder(car: ref<VehicleObject>, cmd: ref<AIVehicleCommand>) -> Void {
  let ai = IsDefined(car) ? car.GetAIComponent() : null;
  if !IsDefined(ai) {
    return;
  }
  let evt = new AICommandEvent();
  evt.command = cmd;
  car.QueueEvent(evt);
  ai.SetInitCmd(cmd);
}

func CBConvoyDriveLead(game: GameInstance, run: ref<CBConvoyRun>) -> Void {
  let lead = ArraySize(run.cars) > 0 ? GameInstance.FindEntityByID(game, run.cars[0]) as VehicleObject : null;
  if !IsDefined(lead) || run.leg >= ArraySize(run.spec.route) {
    return;
  }
  let drive = new AIVehicleDriveToPointAutonomousCommand();
  drive.needDriver = true;
  drive.targetPosition = Vector4.Vector4To3(run.spec.route[run.leg]);
  drive.maxSpeed = run.spec.speed > 0.0 ? run.spec.speed * 1.4 : 20.0;
  drive.minSpeed = 4.0;
  drive.clearTrafficOnPath = true;
  drive.minimumDistanceToTarget = CBConfig.ConvoyPointReach();
  drive.forcedStartSpeed = 6.0;
  drive.driveDownTheRoadIndefinitely = false;
  CBTrace("vehicle: convoy lead order");
  CBConvoyOrder(lead, drive);
}

func CBConvoyEscortsFollow(game: GameInstance, run: ref<CBConvoyRun>) -> Void {
  let lead = ArraySize(run.cars) > 0 ? GameInstance.FindEntityByID(game, run.cars[0]) as VehicleObject : null;
  if !IsDefined(lead) {
    return;
  }
  let i = 1;
  while i < ArraySize(run.cars) {
    let car = GameInstance.FindEntityByID(game, run.cars[i]) as VehicleObject;
    if IsDefined(car) && car.IsAttached() {
      let follow = new AIVehicleFollowCommand();
      follow.needDriver = true;
      follow.target = lead;
      follow.distanceMin = CBConfig.ConvoyGapMin() + Cast<Float>(i - 1) * 4.0;
      follow.distanceMax = CBConfig.ConvoyGapMax() + Cast<Float>(i - 1) * 4.0;
      follow.stopWhenTargetReached = false;
      follow.useTraffic = false;
      CBTrace("vehicle: convoy escort order");
      CBConvoyOrder(car, follow);
    }
    i += 1;
  }
}

// It came to a fight: escorts on V, the lead on to its end or away.
func CBConvoyContact(game: GameInstance, run: ref<CBConvoyRun>, player: ref<PlayerPuppet>) -> Void {
  let i = 0;
  while i < ArraySize(run.cars) {
    let car = GameInstance.FindEntityByID(game, run.cars[i]) as VehicleObject;
    if IsDefined(car) && car.IsAttached() {
      if i == 0 {
        if run.spec.leadFlees {
          let panic = new AIVehiclePanicCommand();
          panic.needDriver = true;
          panic.allowSimplifiedMovement = false;
          panic.ignoreTickets = true;
          panic.useSpeedBasedLookupRange = true;
          panic.tryDriveAwayFromPlayer = true;
          CBTrace("vehicle: convoy lead runs");
          CBConvoyOrder(car, panic);
        }
      } else {
        let chase = new AIVehicleChaseCommand();
        chase.needDriver = true;
        chase.target = player;
        chase.distanceMin = CBConfig.ChaseDistanceMin();
        chase.distanceMax = CBConfig.ChaseDistanceMax();
        chase.forcedStartSpeed = CBConfig.ChaseStartSpeed();
        chase.aggressiveRamming = run.spec.rams;
        chase.ignoreChaseVehiclesLimit = true;
        chase.boostDrivingStats = true;
        CBTrace("vehicle: convoy escort chase");
        CBConvoyOrder(car, chase);
      }
    }
    i += 1;
  }
  CBLog.Info(n"Spawn", s"An add-on's convoy came to a fight (handle \(run.handle)).");
}

func CBConvoyCrewAlive(game: GameInstance, run: ref<CBConvoyRun>) -> Int32 {
  let n = 0;
  for id in run.crewIds {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBStillStanding(p) {
      n += 1;
    }
  }
  return n;
}

// Each tick, every convoy.
public func CBApiConvoyTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let reg = CBApiConvoys.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(reg) || !IsDefined(player) {
    return;
  }
  let now = CBGameSeconds(game);
  let runs = reg.Runs();
  for run in runs {
    if IsDefined(run) {
      CBConvoyStep(sys, game, reg, run, player, now);
    }
  }
}

func CBConvoyStep(sys: ref<CyberbaneSystem>, game: GameInstance, reg: ref<CBApiConvoys>, run: ref<CBConvoyRun>,
                  player: ref<PlayerPuppet>, now: Float) -> Void {
  let ppos = player.GetWorldPosition();
  if run.releasing {
    CBConvoyRelease(game, reg, run);
    return;
  }
  if run.state == CBConvoyPaper() {
    let pos: Vector4;
    let leg = 1;
    if !CBConvoyPaperPos(run, now, pos, leg) {
      CBConvoyFinish(run, CBConvoyOutcomeArrived());
      CBLog.Info(n"Spawn", s"An add-on's convoy got where it was going on paper; V never came near (handle \(run.handle)).");
      reg.Remove(run);
      return;
    }
    if now >= run.setOff && Vector4.Distance(ppos, pos) <= CBConfig.ConvoyReach() && CBWorldStable(game)
       && !CBArrivalsHeld(sys, game) && sys.GetTickCount() % 3 == 0 {
      if CBConvoyPlace(sys, game, run, pos, run.spec.route[Min(leg, ArraySize(run.spec.route) - 1)]) {
        run.state = CBConvoyBoarding();
        run.leg = leg;
        run.placedTick = sys.GetTickCount();
        CBLog.Info(n"Spawn", s"An add-on's convoy is on the road: \(ArraySize(run.cars)) cars, \(ArraySize(run.crewIds)) people (handle \(run.handle)).");
      }
    }
    return;
  }
  // Boarded (everybody seated, or long enough): the lead drives, the escorts follow.
  if run.state == CBConvoyBoarding() {
    let seated = 0;
    for id in run.crewIds {
      if VehicleComponent.IsMountedToVehicle(game, id) {
        seated += 1;
      }
    }
    if seated >= ArraySize(run.crewIds) || sys.GetTickCount() - run.placedTick >= CBConfig.ConvoyBoardTicks() {
      run.state = CBConvoyDriving();
      CBConvoyDriveLead(game, run);
      CBConvoyEscortsFollow(game, run);
    }
    return;
  }
  // Somebody of theirs is fighting: contact, once. Everybody down before any of them fought (one rocket from range) is
  // the end of it too (2.7.5, R3): it stayed "driving" behind a lead that would never get anywhere.
  if run.state == CBConvoyDriving() && CBConvoyCrewAlive(game, run) == 0 {
    CBConvoyFinish(run, CBConvoyOutcomeBroken());
    CBLog.Info(n"Spawn", s"An add-on's convoy lost everybody on board while it drove (handle \(run.handle)).");
  }
  if run.state == CBConvoyDriving() {
    for id in run.crewIds {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if CBNpcSafe(sys, p) && CBNpcInCombat(p) {
        run.state = CBConvoyContact();
      }
    }
    if run.state == CBConvoyContact() {
      CBConvoyContact(game, run, player);
      return;
    }
    let lead = ArraySize(run.cars) > 0 ? GameInstance.FindEntityByID(game, run.cars[0]) as VehicleObject : null;
    if IsDefined(lead) && run.leg < ArraySize(run.spec.route)
       && Vector4.Distance(lead.GetWorldPosition(), run.spec.route[run.leg]) <= CBConfig.ConvoyPointReach() {
      run.leg += 1;
      if run.leg >= ArraySize(run.spec.route) {
        CBLog.Info(n"Spawn", s"An add-on's convoy reached its end (handle \(run.handle)).");
        CBConvoyFinish(run, CBConvoyOutcomeArrived());
      } else {
        CBConvoyDriveLead(game, run);
      }
    }
  }
  // A car that has stopped in a fight lets its people out.
  if run.state == CBConvoyContact() {
    let i = 0;
    while i < ArraySize(run.cars) {
      let car = GameInstance.FindEntityByID(game, run.cars[i]) as VehicleObject;
      if IsDefined(car) && car.IsAttached() && AbsF(car.GetCurrentSpeed()) < 1.0 {
        let k = 0;
        while k < Min(ArraySize(run.crewIds), ArraySize(run.crewCar)) {
          if run.crewCar[k] == i {
            let p = GameInstance.FindEntityByID(game, run.crewIds[k]) as ScriptedPuppet;
            if CBStillStanding(p) && VehicleComponent.IsMountedToVehicle(game, run.crewIds[k]) {
              CBUnmountOnce(game, p);
            }
          }
          k += 1;
        }
      }
      i += 1;
    }
    if CBConvoyCrewAlive(game, run) == 0 {
      CBConvoyFinish(run, CBConvoyOutcomeBroken());
    } else {
      // The two other ways a fight ends (2.7.5, R4): the lead got to its end, or V left it behind.
      let leadC = ArraySize(run.cars) > 0 ? GameInstance.FindEntityByID(game, run.cars[0]) as VehicleObject : null;
      let last = ArraySize(run.spec.route) - 1;
      if IsDefined(leadC) && last >= 0 && Vector4.Distance(leadC.GetWorldPosition(), run.spec.route[last]) <= CBConfig.ConvoyPointReach() {
        CBConvoyFinish(run, CBConvoyOutcomeArrived());
        CBLog.Info(n"Spawn", s"An add-on's convoy got through its fight to its end (handle \(run.handle)).");
      } else {
        run.awayTicks = Vector4.Distance(ppos, CBConvoyWhere(game, run)) > CBConfig.ConvoyReach() ? run.awayTicks + 1 : 0;
        if run.awayTicks >= CBConfig.ConvoyGotAwayTicks() {
          CBConvoyFinish(run, CBConvoyOutcomeGotAway());
          CBLog.Info(n"Spawn", s"An add-on's convoy got away from V (handle \(run.handle)).");
        }
      }
    }
  }
  // Over, and V well away: gone the safe way.
  if run.state == CBConvoyDone() && Vector4.Distance(ppos, CBConvoyWhere(game, run)) > CBConfig.ConvoyReach() {
    run.releasing = true;
  }
}

func CBConvoyFinish(run: ref<CBConvoyRun>, outcome: Int32) -> Void {
  run.state = CBConvoyDone();
  if run.outcome == CBConvoyOutcomeRunning() {
    run.outcome = outcome;
  }
}

public func CBConvoyWhere(game: GameInstance, run: ref<CBConvoyRun>) -> Vector4 {
  if ArraySize(run.cars) > 0 {
    let lead = GameInstance.FindEntityByID(game, run.cars[0]);
    if IsDefined(lead) {
      return lead.GetWorldPosition();
    }
  }
  let pos: Vector4;
  let leg = 1;
  CBConvoyPaperPos(run, CBGameSeconds(game), pos, leg);
  return pos;
}

// Crews out of their seats first (crash rule: nobody removed from a seat), then everybody, never in V's sight.
func CBConvoyRelease(game: GameInstance, reg: ref<CBApiConvoys>, run: ref<CBConvoyRun>) -> Void {
  if run.outcome == CBConvoyOutcomeRunning() {
    run.outcome = CBConvoyOutcomeReleased();
  }
  // Set against a group (SetGroupConvoyHostile): taken back before anybody of it goes.
  CBApiPairsRelease(game, CBApiSideConvoy(), run.handle);
  let seated = 0;
  for id in run.crewIds {
    if VehicleComponent.IsMountedToVehicle(game, id) {
      seated += 1;
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if CBStillStanding(p) {
        CBUnmountOnce(game, p);
      }
    }
  }
  if seated > 0 {
    return;
  }
  CBDeleteTaggedSafe(game, run.Tag(), true, true);
  reg.Remove(run);
  CBLog.Info(n"Spawn", s"An add-on's convoy was taken off the road (handle \(run.handle)).");
}

// Its people still standing, and their bodies (2.7.5, API level 2: ConvoyAlive, ConvoyBodies).
public func CBApiConvoyAlive(game: GameInstance, handle: Int32) -> Int32 {
  let reg = CBApiConvoys.Get(game);
  let run = IsDefined(reg) ? reg.Find(handle) : null;
  return IsDefined(run) ? CBConvoyCrewAlive(game, run) : 0;
}

public func CBApiConvoyBodies(game: GameInstance, handle: Int32, out bodies: array<EntityID>) -> Int32 {
  ArrayClear(bodies);
  let reg = CBApiConvoys.Get(game);
  let run = IsDefined(reg) ? reg.Find(handle) : null;
  if IsDefined(run) {
    for id in run.crewIds {
      ArrayPush(bodies, id);
    }
  }
  return ArraySize(bodies);
}
