// Cyberbane - Chippin' In
//
// In an apex squad fight, a crew member at home or working may drop what they're doing and get V back up when a hit
// would kill V. One roll per fight, after Second Heart, and off when Fenix Rebirth is installed.

// Session state on V (a load builds a new V, so all of it starts clear).
@addField(PlayerPuppet)
public let cbChipRolled: Bool;     // this apex fight has had its roll

@addField(PlayerPuppet)
public let cbChipArmed: Int32;     // the member listening in, 0 none

@addField(PlayerPuppet)
public let cbChipDown: Bool;       // caught: down, and covered until they come

@addField(PlayerPuppet)
public let cbChipDownAt: Float;    // engine seconds

@addField(PlayerPuppet)
public let cbChipMember: Int32;

@addField(PlayerPuppet)
public let cbChipBody: EntityID;

public func CBChippinInChance() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() || !rt.IsEnabled() || !rt.GetSettings().myCrew {
    return 0;
  }
  return Clamp(rt.GetSettings().chippinInChance, 0, 100);
}

// Could this one drop what they are doing and come right now?
func CBChipInCanCome(game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>, now: Float) -> Bool {
  return IsDefined(book) && IsDefined(m) && !CBCrewHurt(m, now) && !book.IsOut(m.id) && !CBCrewAway(game, m.id, now)
      && !CBCrewSparring(game, m.id) && m.loyalty >= CBConfig.MyCrewRestless();
}

// The most loyal of those who could.
func CBChipInPick(game: GameInstance, book: ref<CBCrewBook>) -> ref<CBCrewMember> {
  let now = CBGameSeconds(game);
  let best: ref<CBCrewMember>;
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if CBChipInCanCome(game, book, m, now) && (!IsDefined(best) || m.loyalty > best.loyalty) {
      best = m;
    }
  }
  return best;
}

// Once a settled fast tick (Core/CyberbaneSystem.reds, beside the crew's own tick).
public func CBChippinInTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) {
    return;
  }
  if player.cbChipDown {
    CBChipInWatchDown(sys, game, player);
    return;
  }
  let book = CBCrewBook.Get(game);
  if !CBLiveTaggedPresent(game, n"CB_Apex") {
    // The fight is over: the next one rolls again, and nobody is listening in on nothing.
    player.cbChipRolled = false;
    player.cbChipArmed = 0;
    return;
  }
  if player.cbChipRolled {
    // Whoever was listening can no longer come (called, hurt, sent off, the call on its way home): nobody is.
    if player.cbChipArmed > 0
       && (!IsDefined(book) || book.leaving || CBSpawnRoom(game) <= 0 || CBFenixInstalled() || StrLen(CBCrewHeldWhy(sys, game)) > 0
           || !CBChipInCanCome(game, book, book.Find(player.cbChipArmed), CBGameSeconds(game))) {
      player.cbChipArmed = 0;
    }
    return;
  }
  player.cbChipRolled = true;
  let chance = CBChippinInChance();
  if chance <= 0 || !IsDefined(book) || book.leaving || CBFenixInstalled() || StrLen(CBCrewHeldWhy(sys, game)) > 0 {
    return;
  }
  let m = CBChipInPick(game, book);
  if !IsDefined(m) {
    return;
  }
  if RandRange(0, 100) >= chance {
    CBLog.Info(n"Crew", "Chippin' In: nobody of V's crew is listening in on this apex fight.");
    return;
  }
  player.cbChipArmed = m.id;
  CBLog.Info(n"Crew", s"Chippin' In: one of V's crew (\(m.id)) is listening in on this apex fight.");
}

// From the damage hook, for a hit on V (Spawn/FactionApex.reds). True when the hit is caught and must not land: the
// blow that would have killed V, or anything at all while V is down and covered.
public func CBChipInCatch(pv: ref<PlayerPuppet>, hitEvent: ref<gameHitEvent>) -> Bool {
  if !IsDefined(pv) {
    return false;
  }
  if pv.cbChipDown {
    return true;
  }
  if pv.cbChipArmed <= 0 || !IsDefined(hitEvent) || !IsDefined(hitEvent.attackComputed) {
    return false;
  }
  let game = pv.GetGame();
  let pools = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(pools) {
    return false;
  }
  let id = Cast<StatsObjectID>(pv.GetEntityID());
  let hp = pools.GetStatPoolValue(id, gamedataStatPoolType.Health, false);
  let incoming = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
  if hp > 1.0 && incoming < hp - 1.0 {
    return false;   // not a killing blow
  }
  // A Second Heart that is ready brings V back the game's way, first.
  if RPGManager.HasStatFlag(pv, gamedataStatType.HasSecondHeart)
     && !StatusEffectSystem.ObjectHasStatusEffect(pv, t"BaseStatusEffect.SecondHeartCooldown") {
    return false;
  }
  if CBFenixInstalled() || CBVDown(game) || VehicleComponent.IsMountedToVehicle(game, pv) || !CBPlayerIsVHere(pv) {
    return false;
  }
  pv.cbChipDown = true;
  pv.cbChipMember = pv.cbChipArmed;
  pv.cbChipArmed = 0;
  pv.cbChipDownAt = CBSimNow(game);
  let none: EntityID;
  pv.cbChipBody = none;
  pools.RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, CBConfig.ChipInDownHealth(), null, true);
  StatusEffectHelper.ApplyStatusEffect(pv, t"BaseStatusEffect.VehicleKnockdown");
  let ds = GameInstance.GetDelaySystem(game);
  if IsDefined(ds) {
    let cb = new CBChipInCallback();
    cb.member = pv.cbChipMember;
    ds.DelayCallbackNextFrame(cb);
  }
  return true;
}

// The frame after: they drop their job and come.
public class CBChipInCallback extends DelayCallback {
  public let member: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    let sys = CyberbaneSystem.Get(game);
    let player = GetPlayer(game);
    let book = CBCrewBook.Get(game);
    let m = IsDefined(book) ? book.Find(this.member) : null;
    if !IsDefined(sys) || !IsDefined(player) || !IsDefined(m) {
      return;   // V still gets up, on their own (CBChipInWatchDown)
    }
    CBLog.Info(n"Crew", "Chippin' In: a blow that would have killed V was caught; one of the crew is coming.");
    // Off the house watch: the job is dropped.
    if CBGuardPosted(game, m.id) {
      CBGuardStandDown(game, m.id);
    }
    let record = m.record;
    if (!TDBID.IsValid(record) || !CBRecordIsPerson(record)) && NotEquals(m.faction, n"") {
      record = CBGangTemplate(sys, m.faction);
    }
    let body: EntityID;
    let ring = 0;
    if CBSpawnOnSide(game, record, m.look, n"CB_Own", CBConfig.MyCrewSpawnDistance(), body, ring) > 0 {
      let first = book.OutCount() == 0;
      book.AddOut(body, m.id, sys.GetTickCount());
      book.leaving = false;
      book.quiet = 0;
      book.driving = 0;
      if first {
        book.escort = false;
        book.fought = true;
      }
      player.cbChipBody = body;
      CBMenuNote(game, CBTf(n"Cyberbane-ChippinIn-HoldOnComing", [CBCrewFirst(sys, m)]), 5.0);
      CBCrewText(sys, game, m, CBLineOf([CBT(n"Cyberbane-ChippinIn-DroppedItComing"), CBT(n"Cyberbane-ChippinIn-StayDownOnMyWay"),
                                         CBT(n"Cyberbane-ChippinIn-HeardItAllOnTheLine")]));
      CBCrewText(sys, game, m, CBT(n"Cyberbane-ChippinIn-GroupWentToGetV"), true);
      CBFileLog(sys, n"CrewCalled", CBGameSeconds(game), CBEventDistrict(sys, game), n"", 1.0);
    } else {
      CBLog.Info(n"Crew", s"Chippin' In: nowhere to put them round V (\(CBSpawnRoomNote(game))); V gets up alone.");
      CBCrewText(sys, game, m, CBT(n"Cyberbane-ChippinIn-CouldntGetThrough"));
    }
  }
}

// V down and covered: up when they reach V, or on V's own once the wait runs out.
func CBChipInWatchDown(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
  let now = CBSimNow(game);
  let since = now - player.cbChipDownAt;
  if since < 0.0 {
    since = CBConfig.ChipInMaxDownSeconds();   // a stamp from another session's clock: nothing to wait for
  }
  let arrived = false;
  let book = CBCrewBook.Get(game);
  let m = IsDefined(book) ? book.Find(player.cbChipMember) : null;
  if EntityID.IsDefined(player.cbChipBody) {
    let p = GameInstance.FindEntityByID(game, player.cbChipBody) as ScriptedPuppet;
    arrived = CBNpcSafe(sys, p) && CBStillStanding(p)
           && Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition()) <= CBConfig.ChipInReachDistance();
  }
  if since < CBConfig.ChipInMinDownSeconds() || (!arrived && since < CBConfig.ChipInMaxDownSeconds()) {
    return;
  }
  player.cbChipDown = false;
  let pools = GameInstance.GetStatPoolsSystem(game);
  if IsDefined(pools) {
    pools.RequestSettingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health,
                                      arrived ? CBConfig.ChipInUpHealth() : CBConfig.ChipInAloneHealth(), null, true);
  }
  let none: EntityID;
  player.cbChipBody = none;
  if IsDefined(m) {
    if arrived {
      CBCrewText(sys, game, m, CBLineOf([CBT(n"Cyberbane-ChippinIn-GotYouUp"), CBT(n"Cyberbane-ChippinIn-NotTodayUp"),
                                         CBT(n"Cyberbane-ChippinIn-OnYourFeet")]));
    } else {
      CBCrewText(sys, game, m, CBT(n"Cyberbane-ChippinIn-GetUpImClose"));
    }
  }
  CBLog.Info(n"Crew", arrived ? "Chippin' In: they reached V; V is back up." : "Chippin' In: V got up before anybody reached them.");
}
