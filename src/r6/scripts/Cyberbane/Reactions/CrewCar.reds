// Cyberbane - V's people in V's car (2.7.6)
//
// "I'm getting in a ride with four seats and four doors, but the two I got with me are both sitting in the same seat right
// next to me, clipping into each other." "One of them would never leave the car, and they'd be permanently with you even
// after you sent them home; only a quicksave and a reload fixed it."
//
// V's crew and a friendly gang's people ride with V on the game's own follower role, and the role's way into a car is the
// game's own (FollowerActions.EnterVehicle, tweaks ai/actions/library/followeractions.tweak). That action names no seat.
// With no seat named, AISubActionMountVehicle_Record_Implementation.MountVehicle takes the first seat nobody is sitting in
// (VehicleComponent.GetFirstAvailableSlot) and reserves nothing; only its 'first_available' path reserves one, through the
// car's own AI (TryReserveSeatOrFirstAvailable, core/ai/actions/tweakAISubActions.script). So two followers getting in
// together were both handed the same empty seat and both sat in it. The game's own companions never meet this: a quest
// seats each of them by name.
//
// So for V's own people the seat is taken the way the reserving path takes one: a seat nobody sits in and nobody has
// reserved, reserved for them on the car's AI, then the game's own mount into exactly that seat. The back seats first, so
// the seat beside V stays free for whoever the game or another mod puts there (Johnny, with The Passenger). Nobody is put
// in a car with no free seat: they stay out, and a drive long enough ends the call as it always has (CBMyCrewTick).
//
// And out again. Ending the call took their follower role away (CBEndFollower) while they sat in V's car, and the way out
// of a car is the role's too (FollowerActions.ExitVehicle), so nothing ever asked them out; the walk home is refused to
// anybody in a seat (CBOrderFlee), and the sweep that takes them away waits for V to look away, which V sitting beside them
// never does. They are asked out before the role goes (CBRiderLeaves), the seat is given back, and anybody still in a seat
// a few seconds after being asked is lifted out with the game's own InstantUnmount once the car is standing still
// (CBUnmountStuck), the event it uses itself for a body in a trunk.

// The seat this one was given, in which car, and when (engine seconds). Session only.
@addField(ScriptedPuppet)
public let cbSeatName: CName;

@addField(ScriptedPuppet)
public let cbSeatCar: EntityID;

@addField(ScriptedPuppet)
public let cbSeatAt: Float;

@wrapMethod(AISubActionMountVehicle_Record_Implementation)
public static func MountVehicle(context: ScriptExecutionContext, record: wref<AISubActionMountVehicle_Record>) -> Bool {
  let owner = ScriptExecutionContext.GetOwner(context) as ScriptedPuppet;
  let vehicle: wref<VehicleObject>;
  if !CBRidesWithV(owner) || !IsDefined(record) || !AIActionTarget.GetVehicleObject(context, record.Vehicle(), vehicle)
     || !CBSeatsByName(vehicle) {
    return wrappedMethod(context, record);
  }
  return CBBoardWithV(owner, vehicle, record.MountInstantly());
}

// One of V's own crew (never one who turned), or one of a friendly gang's people riding with V.
public func CBRidesWithV(p: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let id = p.GetEntityID();
  return (des.IsTagged(id, n"CB_Own") && !des.IsTagged(id, n"CB_Turned")) || des.IsTagged(id, n"CB_Follower");
}

// A car whose seats can be handed out by name. A bike, a wreck, a car V is driving by hack or one falling apart is left to
// the game, which turns all but the bike down anyway.
//
// With or without a seat AI of its own (2.7.8). "Both of them still get into the passenger seat." This handed any car with
// no AI component back to the game, and the game seats followers the old way there, both in the first empty seat; the
// game's own reserving path asks for the component before it reserves (tweakAISubActions.script, 'first_available'), and so
// does its seat count (VehicleComponent.GetFirstAvailableSlot), so cars without one are not rare. Seats are now also kept by
// Cyberbane for V's own people (CBSeatClaimed), so two of them are never sent to one seat, whatever the car can reserve.
func CBSeatsByName(vehicle: wref<VehicleObject>) -> Bool {
  if !IsDefined(vehicle) || vehicle.IsDestroyed() || IsDefined(vehicle as BikeObject) {
    return false;
  }
  if vehicle.IsVehicleRemoteControlled() {
    return false;
  }
  let vc = vehicle.GetVehicleComponent();
  return !IsDefined(vc) || !vc.IsVehicleInDecay();
}

// A seat of their own in this car, reserved, and the game's own mount into it. False when there is none.
func CBBoardWithV(owner: ref<ScriptedPuppet>, vehicle: wref<VehicleObject>, instant: Bool) -> Bool {
  let game = owner.GetGame();
  let id = owner.GetEntityID();
  let carId = vehicle.GetEntityID();
  if VehicleComponent.IsMountedToProvidedVehicle(game, id, vehicle) {
    return true;
  }
  let ai = vehicle.GetAIComponent();
  let now = CBSimNow(game);
  // Given a seat in this car a moment ago and still walking to it: it is theirs, and nothing new is sent.
  if Equals(owner.cbSeatCar, carId) && IsNameValid(owner.cbSeatName) && now >= owner.cbSeatAt
     && now - owner.cbSeatAt < CBConfig.SeatWalkSeconds() && VehicleComponent.IsSlotAvailable(game, vehicle, owner.cbSeatName) {
    return true;
  }
  if IsDefined(ai) {
    ai.ReleaseSeatReservedBy(id);   // whatever they held in this car before is asked for again below
  }
  owner.cbSeatName = n"";         // nor is their own claim on a seat of this car in the way of the next one
  let want = CBFreeSeat(game, vehicle, id);
  if !IsNameValid(want) {
    return false;
  }
  let seat = want;
  if IsDefined(ai) {
    seat = ai.TryReserveSeatOrFirstAvailable(id, want);
    if !IsNameValid(seat) || !VehicleComponent.IsSlotAvailable(game, vehicle, seat) || CBSeatClaimed(game, vehicle, seat, id) {
      ai.ReleaseSeatReservedBy(id);
      return false;
    }
    let human = owner.GetAIControllerComponent();
    if IsDefined(human) {
      human.OnSeatReserved(carId);   // the game's own note of which car holds their reservation, released on death or detach
    }
  }
  owner.cbSeatCar = carId;
  owner.cbSeatName = seat;
  owner.cbSeatAt = now;
  let data = new MountEventData();
  data.slotName = seat;
  data.mountParentEntityId = carId;
  data.isInstant = instant;
  data.ignoreHLS = true;
  if Equals(owner.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat) {
    data.entrySlotName = n"combat";
  }
  let evt = new MountAIEvent();
  evt.name = n"Mount";
  evt.data = data;
  CBTrace("vehicle: one of V's people takes a seat of their own");
  owner.QueueEvent(evt);
  return true;
}

// The first seat that nobody sits in, nobody has reserved and none of V's other people is on their way to: the back first,
// the seat beside V last. The game's cars name their seats with these four and no others (tweaks, seatName).
func CBFreeSeat(game: GameInstance, vehicle: wref<VehicleObject>, forWhom: EntityID) -> CName {
  let ai = vehicle.GetAIComponent();
  let order: array<CName>;
  ArrayPush(order, n"seat_back_left");
  ArrayPush(order, n"seat_back_right");
  ArrayPush(order, n"seat_front_right");
  let i = 0;
  while i < ArraySize(order) {
    if VehicleComponent.IsSlotAvailable(game, vehicle, order[i]) && !(IsDefined(ai) && ai.IsSeatReserved(order[i]))
       && !CBSeatClaimed(game, vehicle, order[i], forWhom) {
      return order[i];
    }
    i += 1;
  }
  return n"";
}

// Is this seat of this car one that another of V's people was given and is still walking to (2.7.8)? Read off their own
// seat notes, so it holds for a car with no seat AI to reserve it. V's crew and a friendly gang's people riding with V:
// a handful of people, one look each.
func CBSeatClaimed(game: GameInstance, vehicle: wref<VehicleObject>, seat: CName, except: EntityID) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !IsDefined(vehicle) {
    return false;
  }
  let carId = vehicle.GetEntityID();
  let now = CBSimNow(game);
  let tags: array<CName> = [n"CB_Own", n"CB_Follower"];
  for tag in tags {
    let ids = des.GetTaggedIDs(tag);
    for id in ids {
      if NotEquals(id, except) {
        let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
        if IsDefined(p) && Equals(p.cbSeatCar, carId) && Equals(p.cbSeatName, seat) && now >= p.cbSeatAt
           && now - p.cbSeatAt < CBConfig.SeatWalkSeconds() {
          return true;
        }
      }
    }
  }
  return false;
}

// Done riding with V: their seat given back, and asked out of the car they are in. Before their follower role goes, which
// is the only thing that would otherwise ever get them out.
public func CBRiderLeaves(game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(p) || !p.IsAttached() {
    return;
  }
  let human = p.GetAIControllerComponent();
  if IsDefined(human) {
    human.ReleaseReservedSeat();
  }
  p.cbSeatName = n"";
  CBUnmountOnce(game, p);
}

// Asked out of a car and still in it a few seconds later: lifted out with the game's own InstantUnmount, once the car is
// standing still. The game sends the same event for a body in a trunk and for its own police. Asked again every few
// seconds while they sit there.
public func CBUnmountStuck(game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(p) || !p.cbUnmountSent || !p.IsAttached() || p.IsDead() || !VehicleComponent.IsMountedToVehicle(game, p.GetEntityID()) {
    return;
  }
  let now = CBSimNow(game);
  if now >= p.cbUnmountAt && now - p.cbUnmountAt < CBConfig.UnmountStuckSeconds() {
    return;
  }
  let car: wref<VehicleObject>;
  if VehicleComponent.GetVehicle(game, p, car) && IsDefined(car) && AbsF(car.GetCurrentSpeed()) > CBConfig.UnmountStillSpeed() {
    return;   // never out of a moving car; asked again once it stops
  }
  p.cbUnmountAt = now;
  let lift = new AIEvent();
  lift.name = n"InstantUnmount";
  CBTrace("vehicle: lifting a stuck passenger out of a car");
  p.QueueEvent(lift);
  CBLog.Info(n"Crew", "Somebody asked out of a car was still in their seat; lifted out.");
}
