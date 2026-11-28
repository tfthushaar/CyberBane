// Cyberbane - Your crew on your corners
//
// In a district V's crew holds, a member or two who are free hang out on a corner near V when the crew is not out with
// V: on V's side, standing where they were put, there to talk to the way the watch at home is
// (Reactions/CrewHome.reds). They go when V leaves the district, calls the crew, a fight starts, or the story needs the
// street.

public class CBLoiterBook extends ScriptableSystem {
  public let bodies: array<EntityID>;
  public let members: array<Int32>;
  public let district: CName;
  public let nextAt: Float;   // game seconds: no new loiterers before then

  public static func Get(game: GameInstance) -> ref<CBLoiterBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBLoiterBook") as CBLoiterBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.Forget();
    this.nextAt = 0.0;
  }

  public func Forget() -> Void {
    ArrayClear(this.bodies);
    ArrayClear(this.members);
    this.district = n"";
  }

  public func MemberOfBody(body: EntityID) -> Int32 {
    let i = 0;
    while i < Min(ArraySize(this.bodies), ArraySize(this.members)) {
      if Equals(this.bodies[i], body) {
        return this.members[i];
      }
      i += 1;
    }
    return 0;
  }

  public func HasMember(id: Int32) -> Bool {
    return ArrayContains(this.members, id);
  }
}

public func CBCrewLoitersOn() -> Bool {
  return CBMyCrewOn() && CBCrewTurfOn();
}

// Every few ticks (CBCrewLifeTick): one placed when it can be, all sent off when they should go.
public func CBCrewLoiterTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let lb = CBLoiterBook.Get(game);
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(lb) || !IsDefined(book) || !IsDefined(player) || !IsDefined(des) {
    return;
  }
  let now = CBGameSeconds(game);
  // Bodies the world no longer has.
  let b = ArraySize(lb.bodies) - 1;
  while b >= 0 {
    let p = GameInstance.FindEntityByID(game, lb.bodies[b]) as ScriptedPuppet;
    if !des.IsSpawning(lb.bodies[b]) && (!IsDefined(p) || p.IsDead()) {
      ArrayErase(lb.bodies, b);
      if b < ArraySize(lb.members) {
        ArrayErase(lb.members, b);
      }
    }
    b -= 1;
  }
  let here = sys.GetCurrentDistrict();
  let leave = !CBCrewLoitersOn() || book.OutCount() > 0 || player.IsInCombat() || sys.GetStoryHold() != CBStoryNone()
           || CBPlayerInScene(game) || !Equals(here, lb.district) || !CBCrewHoldsHere(sys, game);
  if ArraySize(lb.bodies) > 0 {
    if leave {
      CBDeleteTaggedSafe(game, n"CB_Loiter", false, true);   // out of V's sight, as every going home
      lb.Forget();
      lb.nextAt = now + CBConfig.CrewLoiterGapHours() * CBConfig.SecondsPerHour();
    }
    return;
  }
  // A war lost leaves the crew's corners empty a while (Reactions/GangWar.reds).
  if !CBCrewLoitersOn() || CBCrewCornersEmpty(game) || now < lb.nextAt || book.OutCount() > 0 || player.IsInCombat() || !CBWorldStable(game)
     || sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game) || IsDefined(player.GetMountedVehicle())
     || CBArrivalsHeldBase(sys, game) || !CBCrewHoldsHere(sys, game) || CBSpawnRoom(game) < 3 {
    return;
  }
  // Up to two who are free: whoever runs this district first (Reactions/CrewGang.reds), then the most loyal.
  let ready = CBCrewReadyOrder(book, now, 0);
  let order: array<ref<CBCrewMember>>;
  let runner = CBRunnerOf(game, here);
  if IsDefined(runner) && ArrayContains(ready, runner) {
    ArrayPush(order, runner);
  }
  for r in ready {
    if r != runner {
      ArrayPush(order, r);
    }
  }
  let n = ArraySize(order);
  if n == 0 {
    return;
  }
  lb.nextAt = now + CBConfig.CrewLoiterGapHours() * CBConfig.SecondsPerHour();   // tried, placed or not
  lb.district = here;
  let placed = 0;
  let i = 0;
  while i < n && placed < CBConfig.CrewLoiterMax() {
    let m = order[i];
    i += 1;
    let record = m.record;
    if (!TDBID.IsValid(record) || !CBRecordIsPerson(record)) && NotEquals(m.faction, n"") {
      record = CBGangTemplate(sys, m.faction);
    }
    let body: EntityID;
    let ring = 0;
    if TDBID.IsValid(record) && CBSpawnOnSide(game, record, m.look, n"CB_Loiter", CBConfig.CrewLoiterDistance(), body, ring) > 0 {
      ArrayPush(lb.bodies, body);
      ArrayPush(lb.members, m.id);
      placed += 1;
    }
  }
  if placed > 0 {
    let first = book.Find(lb.members[0]);
    if IsDefined(first) && CBMessagesOn() {
      CBCrewText(sys, game, first, CBLineOf([CBT(n"Cyberbane-CrewLoiter-OnTheCorner1"), CBT(n"Cyberbane-CrewLoiter-OnTheCorner2")]));
    }
    CBLog.Info(n"Crew", s"\(placed) of V's crew are hanging out on a corner of a district the crew holds.");
  }
}

// As they come into the world (Spawn/Spawner.reds): their kit, on V's side, standing where they were put.
public func CBSetUpLoiter(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let lb = CBLoiterBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(puppet) || !IsDefined(lb) || !IsDefined(book) || !CBStillStanding(puppet) {
    return;
  }
  let m = book.Find(lb.MemberOfBody(puppet.GetEntityID()));
  CBDisarmGodMode(game, puppet);
  CBCrewKeepLook(sys, m, puppet);
  if IsDefined(m) {
    CBKitApexSeat(puppet, m.seat);
    CBCrewApplyKit(sys, game, puppet, m);
  }
  CBCrewFriendlyToV(game, puppet);
  CBWakeStep(puppet);
}

// Down while hanging out: hurt, not lost (from the death handler).
public func CBLoiterBodyDied(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Bool {
  let lb = CBLoiterBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(lb) || !IsDefined(book) || !IsDefined(puppet) {
    return false;
  }
  let m = book.Find(lb.MemberOfBody(puppet.GetEntityID()));
  if !IsDefined(m) {
    return false;
  }
  m.hurtUntil = CBGameSeconds(game) + CBConfig.MyCrewHurtDays() * CBCrewHomeHealFactor(game) * CBConfig.SecondsPerDay();
  CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewLoiter-JumpedOnTheCorner"));
  CBLog.Info(n"Crew", "One of the crew went down on a corner: hurt, not lost.");
  return true;
}

// The member a body hanging out stands for, for talk (Reactions/CrewHome.reds, CBCrewOfTalk).
public func CBLoiterMemberOfBody(game: GameInstance, body: EntityID) -> Int32 {
  let lb = CBLoiterBook.Get(game);
  return IsDefined(lb) ? lb.MemberOfBody(body) : 0;
}

// Hanging out, so not to be called on their own until they have gone (CBCrewReady asks this through CBGuardPosted's way).
public func CBCrewLoitering(game: GameInstance, id: Int32) -> Bool {
  let lb = CBLoiterBook.Get(game);
  return IsDefined(lb) && lb.HasMember(id);
}
