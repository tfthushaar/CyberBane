// Cyberbane - The crew in a car of their own
//
// V drives off with more of the crew than V's car can seat: the ones left over get a car and follow V in it. When V
// gets out they get out too and walk with V again; the car waits for the next drive, and is taken away once nobody is in
// it, V can't see it and V has gone on without it.

public func CBCrewOwnCarsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().crewOwnCars;
}

public func CBCrewCarNone() -> Int32 = 0
public func CBCrewCarComing() -> Int32 = 1
public func CBCrewCarBoarding() -> Int32 = 2
public func CBCrewCarFollowing() -> Int32 = 3
public func CBCrewCarParked() -> Int32 = 4

// Riding in the crew's car: off the follower role while they do, so the role never pulls them out to walk after V's car.
// Per body, reset when they stream back in (the tick puts it right again).
@addField(ScriptedPuppet)
public let cbCrewCarRider: Bool;

// Asked out of the crew's car since they last got in, and when (engine seconds).
@addField(ScriptedPuppet)
public let cbCrewCarOutAsked: Bool;

@addField(ScriptedPuppet)
public let cbCrewCarOutAt: Float;

// Session only: the car, who rides in it, and the cars from before still to be taken away.
public class CBCrewDriveBook extends ScriptableSystem {
  public let car: EntityID;
  public let record: TweakDBID;
  public let phase: Int32;
  public let since: Int32;
  public let riders: array<EntityID>;
  public let seats: array<CName>;
  public let target: EntityID;
  public let spent: array<EntityID>;
  public let made: Int32;
  public let lastAsk: Int32;
  public let vMounted: Int32;
  public let leftSince: Int32;
  public let boardFails: Int32;   // times nobody got into this car in time; twice and the car is given up
  public let gaveUp: Bool;        // no car could be had this drive: the ones left standing go home, nobody waits on one
  public let toldOff: Bool;       // said in the log that crew cars are off, this drive
  public let orderTick: Int32;

  public static func Get(game: GameInstance) -> ref<CBCrewDriveBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewDriveBook") as CBCrewDriveBook : null;
  }

  public func SetPhase(phase: Int32, tick: Int32) -> Void {
    this.phase = phase;
    this.since = tick;
  }

  // The current car joins the ones to be taken away.
  public func Retire() -> Void {
    if EntityID.IsDefined(this.car) && !ArrayContains(this.spent, this.car) {
      ArrayPush(this.spent, this.car);
    }
    let none: EntityID;
    this.car = none;
    this.target = none;
    ArrayClear(this.riders);
    ArrayClear(this.seats);
    this.phase = CBCrewCarNone();
    this.boardFails = 0;
  }
}

// One of the crew who is out with V, standing, and not in any car.
func CBCrewOnFoot(sys: ref<CyberbaneSystem>, game: GameInstance, p: ref<ScriptedPuppet>) -> Bool {
  return CBStillStanding(p) && CBNpcSafe(sys, p) && !p.cbCrewDying && !VehicleComponent.IsMountedToVehicle(game, p.GetEntityID());
}

// Is anybody of the crew coming along with V: in V's car, on their way to a seat in it, or in (or about to be in) the
// crew's own car? Asked before a drive ends the call.
public func CBCrewRidesWithV(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, player: ref<PlayerPuppet>) -> Bool {
  let vcar = player.GetMountedVehicle() as VehicleObject;
  if !IsDefined(vcar) {
    return false;
  }
  let onFoot = false;
  let k = 0;
  while k < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[k]) as ScriptedPuppet;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      if VehicleComponent.IsMountedToProvidedVehicle(game, p.GetEntityID(), vcar) || p.cbCrewCarRider || CBWalkingToSeat(game, p, vcar) {
        return true;
      }
      if !book.outDown[k] && CBCrewOnFoot(sys, game, p) {
        onFoot = true;
      }
    }
    k += 1;
  }
  let drive = CBCrewDriveBook.Get(game);
  if !IsDefined(drive) {
    return false;
  }
  if drive.phase == CBCrewCarComing() || drive.phase == CBCrewCarBoarding() {
    return true;
  }
  // Left standing a moment ago, with a car still to be asked for: the crew's own tick runs first, and the drive tick
  // asks for the car right after it (CBCrewDriveTick).
  return onFoot && CBCrewOwnCarsOn() && !drive.gaveUp && drive.made < CBConfig.CrewCarMaxPerCall();
}

// The crew left standing while V drives: not in V's car and not walking to a seat in it. Once V's car is moving that is
// everybody on foot, a seat given a moment ago or not.
func CBCrewLeftOver(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, vcar: ref<VehicleObject>) -> array<EntityID> {
  let out: array<EntityID>;
  let k = 0;
  while k < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[k]) as ScriptedPuppet;
    if !book.outDown[k] && CBCrewOnFoot(sys, game, p) && !CBWalkingToSeat(game, p, vcar) {
      ArrayPush(out, book.outBody[k]);
    }
    k += 1;
  }
  return out;
}

// Left standing and waiting on the crew's car: the car is asked for or on its way to them.
public func CBCrewCarWaitingFor(game: GameInstance, body: EntityID) -> Bool {
  let drive = CBCrewDriveBook.Get(game);
  if !IsDefined(drive) || (drive.phase != CBCrewCarComing() && drive.phase != CBCrewCarBoarding()) {
    return false;
  }
  return ArrayContains(drive.riders, body);
}

// Who is where as V drives off: in V's car, on the way to a seat, in the crew's car, or on foot.
func CBCrewDriveReport(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, drive: ref<CBCrewDriveBook>, vcar: ref<VehicleObject>) -> Void {
  let inV = 0;
  let walking = 0;
  let riding = 0;
  let onFoot = 0;
  let k = 0;
  while k < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[k]) as ScriptedPuppet;
    if CBStillStanding(p) {
      if VehicleComponent.IsMountedToProvidedVehicle(game, p.GetEntityID(), vcar) {
        inV += 1;
      } else {
        if p.cbCrewCarRider {
          riding += 1;
        } else {
          if CBWalkingToSeat(game, p, vcar) {
            walking += 1;
          } else {
            onFoot += 1;
          }
        }
      }
    }
    k += 1;
  }
  CBLog.Info(n"Crew", s"V drives off with \(book.OutCount()) of the crew out: \(inV) in V's car, \(walking) on the way to a seat, \(riding) in the crew's car, \(onFoot) on foot; V's car at \(RoundF(AbsF(vcar.GetCurrentSpeed()))) m/s, crew car phase \(drive.phase).");
}

// Somewhere near the ones left over for a car to stand: on the ground, room for a car, out of V's sight by the navmesh's
// own visibility, and a walk from them.
func CBCrewCarSpot(game: GameInstance, around: Vector4, out pos: Vector4, out ori: Quaternion) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let openAir = CBArrivalOpenAir(game, around);
  let pts: array<Vector4>;
  if CBPursuitPointsAround(game, ppos, around, CBConfig.CarPointCandidates(), CBConfig.CrewCarSpotMin(), CBConfig.CrewCarSpotMax(), pts) {
    let i = 0;
    while i < ArraySize(pts) {
      let ground: Vector4;
      let p = pts[i];
      i += 1;
      if CBSettleOnGround(game, p, ground) && AbsF(ground.Z - around.Z) <= CBConfig.GroundMaxDrop()
         && Vector4.Distance(ground, ppos) >= CBConfig.CrewCarSpotMin() && !CBSafeAreaBlocksSpawn(game, ground, true)
         && CBCarCanSitAt(game, ground, around, openAir, pos, ori) && CBPointReachable(game, around, ground) {
        return true;
      }
    }
  }
  return false;
}

// Asked for: the car, from the first rider's gang when it has cars of its own.
func CBCrewCarRequest(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, drive: ref<CBCrewDriveBook>,
                      left: array<EntityID>) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  let first: ref<ScriptedPuppet>;
  if ArraySize(left) > 0 {
    first = GameInstance.FindEntityByID(game, left[0]) as ScriptedPuppet;
  }
  if !IsDefined(des) || !IsDefined(first) {
    return false;
  }
  if CBStoryHoldNow(game) {
    CBLog.Info(n"Crew", "No car for the crew while the story has V.");
    return false;
  }
  let pos: Vector4;
  let ori: Quaternion;
  if !CBCrewCarSpot(game, first.GetWorldPosition(), pos, ori) {
    CBLog.Info(n"Crew", "No room for the crew's car near the ones left over.");
    return false;
  }
  let m = book.MemberOfBody(left[0]);
  let faction = IsDefined(m) ? m.faction : n"";
  let seats = 0;
  let record = CBArrivalVehicle(faction, ArraySize(left), RandRange(0, 4), seats);
  if !TDBID.IsValid(record) || seats <= 0 {
    CBLog.Info(n"Crew", s"No car to be had for the crew (\(NameToString(faction))).");
    return false;
  }
  let spec = new DynamicEntitySpec();
  spec.recordID = record;
  spec.position = pos;
  spec.orientation = ori;
  spec.persistState = false;
  spec.persistSpawn = false;
  spec.alwaysSpawned = false;
  spec.spawnInView = false;
  spec.active = true;
  let tags: array<CName>;
  ArrayPush(tags, n"Cyberbane");
  ArrayPush(tags, n"CB_CrewCar");
  spec.tags = tags;
  CBTrace("vehicle: a car for V's crew");
  let carId = des.CreateEntity(spec);
  if !EntityID.IsDefined(carId) {
    return false;
  }
  drive.Retire();
  drive.car = carId;
  drive.record = record;
  drive.seats = CBVehicleSeatNames(record);
  drive.riders = left;
  drive.made += 1;
  drive.SetPhase(CBCrewCarComing(), sys.GetTickCount());
  CBLog.Info(n"Crew", s"A car for \(ArraySize(left)) of V's crew with no seat in V's car.");
  return true;
}

// Into the car, driver first, each to a seat of their own; off the follower role while they ride.
func CBCrewCarBoard(sys: ref<CyberbaneSystem>, game: GameInstance, drive: ref<CBCrewDriveBook>, car: ref<VehicleObject>) -> Int32 {
  let player = GetPlayer(game);
  let vcar: ref<VehicleObject>;
  if IsDefined(player) {
    vcar = player.GetMountedVehicle() as VehicleObject;
  }
  let carPos = car.GetWorldPosition();
  let sent = 0;
  let kept: array<EntityID>;
  // Seats in order among the ones who really get in, so the first of them always takes the wheel.
  let seat = 0;
  let i = 0;
  while i < ArraySize(drive.riders) && seat < ArraySize(drive.seats) {
    let p = GameInstance.FindEntityByID(game, drive.riders[i]) as ScriptedPuppet;
    while seat < ArraySize(drive.seats) && !VehicleComponent.IsSlotAvailable(game, car, drive.seats[seat]) && seat > 0 {
      seat += 1;
    }
    if CBCrewOnFoot(sys, game, p) && seat < ArraySize(drive.seats) && VehicleComponent.IsSlotAvailable(game, car, drive.seats[seat]) {
      // A seat they still held in V's car goes back to it, or nobody else could take it while they ride in their own.
      CBGiveSeatBack(p, vcar);
      AIHumanComponent.SetCurrentRole(p, new AINoRole());
      CBCrewFriendlyToV(game, p);
      CBCancelMove(p);
      p.cbCrewCarRider = true;
      p.cbCrewCarOutAsked = false;
      p.cbCrewCarOutAt = 0.0;
      let data = new MountEventData();
      data.slotName = drive.seats[seat];
      data.mountParentEntityId = car.GetEntityID();
      // Seen walking to the car when V is watching; otherwise straight into the seat.
      let at = p.GetWorldPosition();
      data.isInstant = CBOutOfView(game, at) || Vector4.Distance(at, carPos) > CBConfig.CrewCarWalkDistance();
      data.ignoreHLS = true;
      let evt = new MountAIEvent();
      evt.name = n"Mount";
      evt.data = data;
      CBTrace("vehicle: one of V's crew into the crew's car");
      p.QueueEvent(evt);
      ArrayPush(kept, drive.riders[i]);
      sent += 1;
      seat += 1;
    }
    i += 1;
  }
  drive.riders = kept;
  if IsDefined(player) && sent == 0 {
    CBLog.Info(n"Crew", "Nobody could get into the crew's car.");
  }
  return sent;
}

// Behind V's car, at a distance that leaves room to brake.
func CBCrewCarFollow(game: GameInstance, drive: ref<CBCrewDriveBook>, car: ref<VehicleObject>, vcar: ref<VehicleObject>) -> Void {
  let follow = new AIVehicleFollowCommand();
  follow.needDriver = true;
  follow.target = vcar;
  follow.distanceMin = CBConfig.CrewCarFollowMin();
  follow.distanceMax = CBConfig.CrewCarFollowMax();
  follow.stopWhenTargetReached = false;
  follow.useTraffic = false;
  CBTrace("vehicle: the crew's car follows V");
  CBConvoyOrder(car, follow);
  drive.target = vcar.GetEntityID();
  let sys = CyberbaneSystem.Get(game);
  drive.orderTick = IsDefined(sys) ? sys.GetTickCount() : 0;
}

func CBCrewCarDriverIn(game: GameInstance, drive: ref<CBCrewDriveBook>, car: ref<VehicleObject>) -> Bool {
  if ArraySize(drive.riders) == 0 {
    return false;
  }
  let driver = GameInstance.FindEntityByID(game, drive.riders[0]) as ScriptedPuppet;
  return CBStillStanding(driver) && VehicleComponent.IsMountedToProvidedVehicle(game, drive.riders[0], car);
}

// Out of the crew's car once it has stopped, once a stop, and back on the follower role once they are out. True when
// nobody of them is still in it.
func CBCrewCarUnload(sys: ref<CyberbaneSystem>, game: GameInstance, drive: ref<CBCrewDriveBook>, car: ref<VehicleObject>,
                     player: ref<PlayerPuppet>, force: Bool) -> Bool {
  let speed = IsDefined(car) ? AbsF(car.GetCurrentSpeed()) : 0.0;
  let still = speed < CBConfig.CrewCarOutSpeed();
  // Made to wait long enough, they still never get out of a car going any faster than a crawl.
  let slowEnough = speed < CBConfig.CrewCarOutSpeed() * 3.0;
  let inside = 0;
  for id in drive.riders {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.IsAttached() && !p.IsDead() {
      if VehicleComponent.IsMountedToVehicle(game, id) {
        inside += 1;
        if (still || (force && slowEnough)) && !p.cbCrewCarOutAsked && CBNpcSafe(sys, p) {
          p.cbCrewCarOutAsked = true;
          p.cbCrewCarOutAt = CBSimNow(game);
          CBAskOutOfCar(p);
        } else {
          // Asked and still sitting there a while later, in a car standing still: lifted out, as every other rider is.
          let now = CBSimNow(game);
          if p.cbCrewCarOutAsked && still && now >= p.cbCrewCarOutAt && now - p.cbCrewCarOutAt > CBConfig.UnmountStuckSeconds()
             && CBNpcSafe(sys, p) {
            p.cbCrewCarOutAt = now;
            let lift = new AIEvent();
            lift.name = n"InstantUnmount";
            CBTrace("vehicle: lifting one of V's crew out of their car");
            p.QueueEvent(lift);
          }
        }
      } else {
        if p.cbCrewCarRider && CBStillStanding(p) && CBNpcSafe(sys, p) {
          p.cbCrewCarRider = false;
          CBMakeFollower(p, player);
        }
      }
    }
  }
  return inside == 0;
}

// The call is over, or the feature is off: the ones still riding get out, and the car goes once it is empty. With the
// call still on (the switch turned off mid-drive) they go back to following V.
func CBCrewCarLetGo(sys: ref<CyberbaneSystem>, game: GameInstance, drive: ref<CBCrewDriveBook>, restore: Bool) -> Void {
  let player = GetPlayer(game);
  for id in drive.riders {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.IsAttached() && CBNpcSafe(sys, p) {
      if restore && p.cbCrewCarRider && CBStillStanding(p) && IsDefined(player) {
        CBMakeFollower(p, player);
      }
      p.cbCrewCarRider = false;
      if VehicleComponent.IsMountedToVehicle(game, id) && !p.cbCrewCarOutAsked {
        p.cbCrewCarOutAsked = true;
        CBAskOutOfCar(p);
      }
    }
  }
  drive.Retire();
  drive.made = 0;
  drive.gaveUp = false;
}

// Spent cars: gone once nobody of ours sits in one, V isn't in it, and V can't see it go.
func CBCrewCarSweep(game: GameInstance, drive: ref<CBCrewDriveBook>, des: ref<DynamicEntitySystem>) -> Void {
  if ArraySize(drive.spent) == 0 {
    return;
  }
  let player = GetPlayer(game);
  let ppos = IsDefined(player) ? player.GetWorldPosition() : new Vector4(0.0, 0.0, 0.0, 1.0);
  let riders = des.GetTaggedIDs(n"CB_Own");
  let keep: array<EntityID>;
  for id in drive.spent {
    let car = GameInstance.FindEntityByID(game, id) as VehicleObject;
    if des.IsSpawning(id) {
      ArrayPush(keep, id);
    } else {
      if IsDefined(car) {
        let occupied = false;
        for r in riders {
          if VehicleComponent.IsMountedToProvidedVehicle(game, r, car) {
            occupied = true;
          }
        }
        let away = Vector4.Distance(car.GetWorldPosition(), ppos) > CBConfig.CrewCarGoneDistance();
        if occupied || !away || !CBRemoveOne(game, des, id, false, true) {
          ArrayPush(keep, id);
        }
      } else {
        // Streamed out: nobody is in it, and nobody can see it.
        if des.IsManaged(id) && !CBRemoveOne(game, des, id, false, false) {
          ArrayPush(keep, id);
        }
      }
    }
  }
  drive.spent = keep;
}

// Every fast tick, after the crew's own (Reactions/Crew.reds, CBMyCrewTick).
public func CBCrewDriveTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let drive = CBCrewDriveBook.Get(game);
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(drive) || !IsDefined(book) || !IsDefined(player) || !IsDefined(des) {
    return;
  }
  CBCrewCarSweep(game, drive, des);
  let tick = sys.GetTickCount();
  let callOn = book.OutCount() > 0 && !book.leaving && CBMyCrewOn() && CBCrewOwnCarsOn();
  if !callOn && book.OutCount() > 0 && !book.leaving && !CBCrewOwnCarsOn() && IsDefined(player.GetMountedVehicle()) && !drive.toldOff {
    drive.toldOff = true;
    CBLog.Info(n"Crew", "V drives off with the crew out and Your crew drive after you off: the ones with no seat in V's car walk.");
  }
  if !IsDefined(player.GetMountedVehicle()) {
    drive.toldOff = false;
  }
  if !callOn {
    if drive.phase != CBCrewCarNone() || EntityID.IsDefined(drive.car) || drive.made > 0 {
      CBCrewCarLetGo(sys, game, drive, book.OutCount() > 0 && !book.leaving);
    }
    return;
  }
  if !CBWorldStable(game) {
    return;
  }
  let vcar = player.GetMountedVehicle() as VehicleObject;
  let car = EntityID.IsDefined(drive.car) ? GameInstance.FindEntityByID(game, drive.car) as VehicleObject : null;
  drive.vMounted = IsDefined(vcar) ? drive.vMounted + 1 : 0;
  // V took the crew's car: it is V's car now, and the ones in it ride with V the ordinary way.
  if IsDefined(vcar) && Equals(vcar.GetEntityID(), drive.car) {
    for id in drive.riders {
      let rp = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if IsDefined(rp) && rp.cbCrewCarRider && CBStillStanding(rp) && CBNpcSafe(sys, rp) {
        rp.cbCrewCarRider = false;
        CBMakeFollower(rp, player);
      }
    }
    drive.Retire();
    return;
  }
  let usable = IsDefined(car) && car.IsAttached() && !car.IsDestroyed();
  // Once a drive, where everybody is, so a drive that went wrong says how in the log.
  if IsDefined(vcar) && drive.vMounted == CBConfig.CrewCarWaitTicks() {
    CBCrewDriveReport(sys, game, book, drive, vcar);
  }
  if drive.phase == CBCrewCarComing() {
    if usable {
      if CBCrewCarBoard(sys, game, drive, car) > 0 {
        drive.SetPhase(CBCrewCarBoarding(), tick);
      } else {
        drive.Retire();
      }
    } else {
      if tick - drive.since > CBConfig.CrewCarComeTicks() {
        CBLog.Info(n"Crew", "The crew's car never came.");
        drive.Retire();
      }
    }
    return;
  }
  if drive.phase == CBCrewCarBoarding() {
    if !usable {
      CBCrewCarLetGo(sys, game, drive, true);
      return;
    }
    if CBCrewCarDriverIn(game, drive, car) {
      if IsDefined(vcar) {
        CBCrewCarFollow(game, drive, car, vcar);
        drive.SetPhase(CBCrewCarFollowing(), tick);
      } else {
        drive.SetPhase(CBCrewCarParked(), tick);
      }
      return;
    }
    if tick - drive.since > CBConfig.CrewCarBoardTicks() {
      CBLog.Info(n"Crew", "The crew could not get into their car; they walk.");
      CBCrewCarUnload(sys, game, drive, car, player, true);
      drive.SetPhase(CBCrewCarParked(), tick);
      drive.boardFails += 1;
    }
    return;
  }
  if drive.phase == CBCrewCarFollowing() {
    if !usable || !CBCrewCarDriverIn(game, drive, car) {
      // The car is wrecked or its driver is gone: everybody out, and the car is done.
      CBCrewCarUnload(sys, game, drive, car, player, true);
      drive.SetPhase(CBCrewCarParked(), tick);
      if !usable {
        drive.Retire();
      }
      return;
    }
    if !IsDefined(vcar) {
      drive.SetPhase(CBCrewCarParked(), tick);
      return;
    }
    // Back on the role after streaming back in: off it again while they ride.
    for id in drive.riders {
      let fp = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if IsDefined(fp) && !fp.cbCrewCarRider && VehicleComponent.IsMountedToProvidedVehicle(game, id, car) && CBNpcSafe(sys, fp) {
        AIHumanComponent.SetCurrentRole(fp, new AINoRole());
        fp.cbCrewCarRider = true;
      }
    }
    // A new car of V's, or the order lost: standing still well behind V while V moves.
    let stalled = AbsF(car.GetCurrentSpeed()) < 1.0 && AbsF(vcar.GetCurrentSpeed()) > 3.0
                  && Vector4.Distance(car.GetWorldPosition(), vcar.GetWorldPosition()) > CBConfig.CrewCarFollowMax() * 3.0
                  && tick - drive.orderTick >= CBConfig.CrewCarRetryTicks();
    if NotEquals(vcar.GetEntityID(), drive.target) || stalled {
      CBCrewCarFollow(game, drive, car, vcar);
    }
    return;
  }
  if drive.phase == CBCrewCarParked() {
    // V drove off again before they were out: the ones still in it follow again.
    if IsDefined(vcar) && usable && CBCrewCarDriverIn(game, drive, car) {
      CBCrewCarFollow(game, drive, car, vcar);
      drive.SetPhase(CBCrewCarFollowing(), tick);
      return;
    }
    let force = tick - drive.since > CBConfig.CrewCarOutWaitTicks();
    if CBCrewCarUnload(sys, game, drive, car, player, force) {
      ArrayClear(drive.riders);
      drive.SetPhase(CBCrewCarNone(), tick);
      // Nobody could get in it twice over: this car is done, and the next drive asks for another.
      if drive.boardFails >= 2 {
        drive.Retire();
      }
    }
    return;
  }
  // Nobody riding: a car stood far behind is done with.
  if usable && Vector4.Distance(car.GetWorldPosition(), player.GetWorldPosition()) > CBConfig.CrewCarGoneDistance() {
    drive.Retire();
    usable = false;
  }
  if !IsDefined(vcar) {
    drive.gaveUp = false;   // a new drive, a new try
  }
  if !IsDefined(vcar) || drive.vMounted < CBConfig.CrewCarWaitTicks() || drive.gaveUp {
    drive.leftSince = 0;
    return;
  }
  let left = CBCrewLeftOver(sys, game, book, vcar);
  if ArraySize(left) == 0 {
    drive.leftSince = 0;
    return;
  }
  if drive.leftSince <= 0 {
    drive.leftSince = tick;
    CBLog.Info(n"Crew", s"\(ArraySize(left)) of V's crew left standing as V drives off.");
  }
  // The car from before, still near them: back in it.
  let first = GameInstance.FindEntityByID(game, left[0]) as ScriptedPuppet;
  if usable && IsDefined(first) && Vector4.Distance(car.GetWorldPosition(), first.GetWorldPosition()) <= CBConfig.CrewCarReuseDistance() {
    drive.riders = left;
    if CBCrewCarBoard(sys, game, drive, car) > 0 {
      drive.SetPhase(CBCrewCarBoarding(), tick);
      drive.leftSince = 0;
      return;
    }
  }
  if drive.made < CBConfig.CrewCarMaxPerCall() && tick - drive.lastAsk >= CBConfig.CrewCarRetryTicks() {
    drive.lastAsk = tick;
    if CBCrewCarRequest(sys, game, book, drive, left) {
      drive.leftSince = 0;
      return;
    }
  }
  // No car for them: they head home on their own rather than trail after V's car on foot.
  if tick - drive.leftSince >= CBConfig.CrewCarGiveUpTicks() {
    drive.leftSince = 0;
    drive.gaveUp = true;
    CBLog.Info(n"Crew", "No car could be had for the ones left standing; they head home.");
    for id in left {
      let mid = CBCrewMemberOfBody(book, id);
      if mid > 0 && book.OutCount() > 1 && CBCrewRidesWithV(sys, game, book, player) {
        CBCrewSendOneHome(sys, game, book, mid);
      }
    }
  }
}
