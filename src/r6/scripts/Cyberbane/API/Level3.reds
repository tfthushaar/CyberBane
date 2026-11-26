// Cyberbane - extension API level 3
//
// For add-ons: signals between them, clocks that stop with Cyberbane's, places by the game's own districts, a fair turn
// at the event slot, titles they unlock, standing layers and price factors, a corporation's hunting handed over, prices
// on V, groups that wait for V to pick a side, and convoys on V's side. The statics are on CyberbaneAPI; guard each call
// with `@if(ModuleExists("Cyberbane.Api3"))`.

// ---- Signals (Emit, OnSignal) ------------------------------------------------------------------------------------------
// Prefixed by the sender ("Madmax/ConvoyBroken"). Cyberbane's own ("Cyberbane/RivalSlain") are sent by Cyberbane alone,
// through CBEmit, which tells listeners too.
public func CBApiEmit(game: GameInstance, name: CName, faction: CName, value: Int32) -> Bool {
  let s = NameToString(name);
  if !StrContains(s, "/") || StrBeginsWith(s, "Cyberbane/") {
    return false;
  }
  CBApiNote(CBApiQSignal(), name, value, 0, faction);
  return true;
}

// ---- Clocks (ClockHeld) ------------------------------------------------------------------------------------------------
// While this is true Cyberbane's own clocks stand still: the world streaming or in a menu, the story on stage, V down.
public func CBApiClockHeld(game: GameInstance) -> Bool {
  return !CBWorldStable(game) || CBStoryHoldNow(game) || CBVDown(game);
}

// ---- Places by the game's districts (PlaceId, FindPlacesIn) ------------------------------------------------------------
public func CBApiPlaceId(game: GameInstance) -> CName {
  let name = CBSubDistrictName(game);
  return StrLen(name) > 0 ? StringToName(name) : n"";
}

public func CBApiFindPlacesIn(game: GameInstance, placeId: CName, minDistance: Float, maxDistance: Float,
                              out positions: array<Vector4>, out names: array<String>) -> Int32 {
  ArrayClear(positions);
  ArrayClear(names);
  let sys = CyberbaneSystem.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) || !IsNameValid(placeId) {
    return 0;
  }
  return CBFastTravelPlaces(sys, game, n"", player.GetWorldPosition(), MaxF(minDistance, 0.0),
                            MaxF(maxDistance, minDistance), positions, names, placeId);
}

// ---- The event slot's fair turn ----------------------------------------------------------------------------------------
//
// One event at a time for Cyberbane and every add-on. An event already set always runs: nothing takes the slot from it.
// Beyond that: whoever was refused because the slot was taken waits, and when the slot comes free the one that has waited
// longest gets it first, for a short grace; and no add-on sets two events less than ApiEventGapSeconds apart. Real
// seconds (the engine's clock), so a time skip neither starts nor spends a turn.

// Whose event kind this is: Cyberbane's own, or an add-on's by its name up to the second capital (MadmaxCampRaid: Madmax).
public func CBEventOwner(kind: CName) -> CName {
  if CBEventKindIsOwn(kind) {
    return n"Cyberbane";
  }
  let s = NameToString(kind);
  let n = StrLen(s);
  let i = 1;
  while i < n {
    let c = StrMid(s, i, 1);
    if NotEquals(c, StrLower(c)) {
      return StringToName(StrLeft(s, i));
    }
    i += 1;
  }
  return kind;
}

public class CBApiTurns extends ScriptableSystem {
  private let m_owners: array<CName>;
  private let m_lastSet: array<Float>;
  private let m_waiting: array<Float>;   // since when this owner has wanted the slot; 0 not waiting
  private let m_freedAt: Float;
  private let m_wasBusy: Bool;

  public static func Get(game: GameInstance) -> ref<CBApiTurns> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiTurns") as CBApiTurns : null;
  }

  private func Index(owner: CName) -> Int32 {
    let n = Min(Min(ArraySize(this.m_owners), ArraySize(this.m_lastSet)), ArraySize(this.m_waiting));
    let i = 0;
    while i < n {
      if Equals(this.m_owners[i], owner) {
        return i;
      }
      i += 1;
    }
    ArrayPush(this.m_owners, owner);
    ArrayPush(this.m_lastSet, 0.0);
    ArrayPush(this.m_waiting, 0.0);
    return ArraySize(this.m_owners) - 1;
  }

  // Once a tick, from the street's events: when the slot came free.
  public func Watch(busy: Bool, now: Float) -> Void {
    if this.m_wasBusy && !busy {
      this.m_freedAt = now;
    }
    this.m_wasBusy = busy;
  }

  public func NoteWaiting(owner: CName, now: Float) -> Void {
    let i = this.Index(owner);
    if this.m_waiting[i] <= 0.0 || now - this.m_waiting[i] > CBConfig.ApiWaitStaleSeconds() {
      this.m_waiting[i] = MaxF(now, 0.01);
    }
  }

  public func NoteSet(owner: CName, now: Float) -> Void {
    let i = this.Index(owner);
    this.m_lastSet[i] = MaxF(now, 0.01);
    this.m_waiting[i] = 0.0;
  }

  // Why this owner may not set an event now, "" when it may.
  public func WhyNot(owner: CName, now: Float) -> String {
    let i = this.Index(owner);
    if NotEquals(owner, n"Cyberbane") && this.m_lastSet[i] > 0.0 && now >= this.m_lastSet[i]
       && now - this.m_lastSet[i] < CBConfig.ApiEventGapSeconds() {
      return "too soon after its last event";
    }
    if this.m_freedAt > 0.0 && now >= this.m_freedAt && now - this.m_freedAt < CBConfig.ApiTurnGraceSeconds() {
      let longest = -1;
      let k = 0;
      while k < ArraySize(this.m_owners) {
        let since = this.m_waiting[k];
        if since > 0.0 && now - since <= CBConfig.ApiWaitStaleSeconds() && (longest < 0 || since < this.m_waiting[longest]) {
          longest = k;
        }
        k += 1;
      }
      if longest >= 0 && longest != i {
        return "another has waited longer for the slot";
      }
    }
    return "";
  }
}

public func CBApiTurnWatch(game: GameInstance, busy: Bool) -> Void {
  let turns = CBApiTurns.Get(game);
  if IsDefined(turns) {
    turns.Watch(busy, CBSimNow(game));
  }
}

public func CBApiTurnWaiting(game: GameInstance, owner: CName) -> Void {
  let turns = CBApiTurns.Get(game);
  if IsDefined(turns) {
    turns.NoteWaiting(owner, CBSimNow(game));
  }
}

public func CBApiTurnWhyNot(game: GameInstance, owner: CName) -> String {
  let turns = CBApiTurns.Get(game);
  return IsDefined(turns) ? turns.WhyNot(owner, CBSimNow(game)) : "";
}

public func CBApiTurnSet(game: GameInstance, owner: CName) -> Void {
  let turns = CBApiTurns.Get(game);
  if IsDefined(turns) {
    turns.NoteSet(owner, CBSimNow(game));
  }
}

public func CBApiEventSlotBusy(game: GameInstance) -> Bool {
  let life = CBStreetLifeFor(game);
  return IsDefined(life) && IsDefined(life.Events().Live());
}

public func CBApiEndEvent(game: GameInstance, kind: CName) -> Bool {
  let life = CBStreetLifeFor(game);
  return IsDefined(life) && life.Events().EndApi(game, kind);
}

// ---- Titles (UnlockTitle) ----------------------------------------------------------------------------------------------
// Cyberbane's own titles are all T_ ids and unlock by their own conditions only.
public func CBApiUnlockTitle(game: GameInstance, id: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let content = CBContent(game);
  let def = IsDefined(content) && IsNameValid(id) ? content.GetTitle(id) : null;
  if !IsDefined(sys) || !IsDefined(def) || sys.HasTitle(id) || StrBeginsWith(NameToString(id), "T_") {
    return false;
  }
  sys.UnlockTitle(id);
  sys.AddRenownPoints(25.0);
  if CBMessagesOn() {
    CBHearsayFromContact(game, CBTf(n"Cyberbane-TitleEngine-PeopleAreCallingYouNow", [CBTitleDisplay(sys, def)]), n"");
  }
  CBLog.Info(n"Model", s"An add-on's title unlocked: \(NameToString(id)).");
  return true;
}

public func CBApiFactionRegistered(id: CName) -> Bool {
  let content = CyberbaneContent.Get();
  return IsDefined(content) && IsNameValid(id) && IsDefined(content.GetFaction(id));
}

// ---- A corporation's hunting, handed to an add-on (ClaimFaction) -------------------------------------------------------
// Session only: an add-on claims again after a load (OnSettled), so uninstalling it can never leave a faction claimed.
public class CBApiClaims extends ScriptableSystem {
  private let m_claimed: array<CName>;

  public static func Get(game: GameInstance) -> ref<CBApiClaims> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiClaims") as CBApiClaims : null;
  }

  public func Claim(faction: CName) -> Void {
    if !ArrayContains(this.m_claimed, faction) {
      ArrayPush(this.m_claimed, faction);
    }
  }

  public func Release(faction: CName) -> Void {
    ArrayRemove(this.m_claimed, faction);
  }

  public func Has(faction: CName) -> Bool {
    return ArrayContains(this.m_claimed, faction);
  }
}

public func CBFactionClaimed(faction: CName) -> Bool {
  let claims = CBApiClaims.Get(GetGameInstance());
  return IsDefined(claims) && claims.Has(faction);
}

// A faction whose crews and apex squads Cyberbane never sends: a corporation hiring the hunters instead, or one an add-on
// has claimed. Asked wherever a crew or an apex squad is decided. Bounties are not asked this: they stay Cyberbane's.
public func CBSendsNoneOfItsOwn(faction: CName) -> Bool {
  return CBCorpHiresKillers(faction) || CBFactionClaimed(faction);
}

public func CBApiClaimFaction(game: GameInstance, faction: CName) -> Bool {
  let claims = CBApiClaims.Get(game);
  if !IsDefined(claims) || !CBApiFactionRegistered(faction) {
    return false;
  }
  if !claims.Has(faction) {
    claims.Claim(faction);
    CBLog.Info(n"Api", s"An add-on has taken over \(NameToString(faction))'s hunting: Cyberbane sends none of their crews or apex squads.");
  }
  return true;
}

public func CBApiReleaseFaction(game: GameInstance, faction: CName) -> Void {
  let claims = CBApiClaims.Get(game);
  if IsDefined(claims) && claims.Has(faction) {
    claims.Release(faction);
    CBLog.Info(n"Api", s"An add-on let go of \(NameToString(faction))'s hunting.");
  }
}

// ---- Prices on V (PostBounty, CancelBounty, BountyOn) ------------------------------------------------------------------
// The price itself is Cyberbane's one price (Spawn/Bounty.reds). This book only says an add-on put it up, so it stands
// until the add-on takes it down or its term runs out, whatever the payer's standing does meanwhile.
public class CBApiBountyBook extends ScriptableSystem {
  private persistent let m_payer: CName;
  private persistent let m_since: Float;

  public static func Get(game: GameInstance) -> ref<CBApiBountyBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiBountyBook") as CBApiBountyBook : null;
  }

  public func Payer() -> CName { return this.m_payer; }
  public func Since() -> Float { return this.m_since; }

  public func Set(payer: CName, since: Float) -> Void {
    this.m_payer = payer;
    this.m_since = since;
  }
}

// Posted by an add-on and still within its term: true when the price `by` put up is one of theirs.
public func CBApiBountyHeld(game: GameInstance, by: CName) -> Bool {
  let book = CBApiBountyBook.Get(game);
  if !IsDefined(book) || !IsNameValid(by) || NotEquals(book.Payer(), by) {
    return false;
  }
  return CBFactionOn(by) && CBGameSeconds(game) - book.Since() < CBConfig.BountyCorpDays() * CBConfig.SecondsPerDay();
}

public func CBApiBountyForget(game: GameInstance) -> Void {
  let book = CBApiBountyBook.Get(game);
  if IsDefined(book) && IsNameValid(book.Payer()) {
    book.Set(n"", 0.0);
  }
}

public func CBApiPostBounty(game: GameInstance, payer: CName, amount: Int32, reasonKey: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let hunt = CBHuntBook.Get(game);
  let book = CBApiBountyBook.Get(game);
  if !IsDefined(sys) || !IsDefined(hunt) || !IsDefined(book) || !CBPriceOnHeadOn() || amount <= 0
     || !CBApiFactionRegistered(payer) || !CBFactionOn(payer) {
    return false;
  }
  // One price at a time; the same payer may raise or lower its own.
  if NotEquals(hunt.BountyBy(), n"") && NotEquals(hunt.BountyBy(), payer) {
    return false;
  }
  let now = CBGameSeconds(game);
  CBBountyPost(sys, game, hunt, payer, CBBountyRound(Cast<Float>(amount)), now);
  book.Set(payer, MaxF(now, 1.0));
  if CBApiReasonKeyOk(reasonKey) {
    CBFileLog(sys, reasonKey, now, CBEventDistrict(sys, game), payer, Cast<Float>(amount));
  }
  return true;
}

public func CBApiCancelBounty(game: GameInstance, payer: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let hunt = CBHuntBook.Get(game);
  if !IsDefined(sys) || !IsDefined(hunt) || !IsNameValid(payer) || NotEquals(hunt.BountyBy(), payer) {
    return false;
  }
  CBBountyEnd(sys, game, hunt, n"lifted");
  return true;
}

public func CBApiBountyOn(game: GameInstance, out payers: array<CName>, out amounts: array<Int32>) -> Int32 {
  ArrayClear(payers);
  ArrayClear(amounts);
  let sys = CyberbaneSystem.Get(game);
  let hunt = CBHuntBook.Get(game);
  let up = CBBountyUp(game);
  if !IsDefined(sys) || !IsDefined(hunt) || up <= 0 {
    return 0;
  }
  ArrayPush(payers, CBBountyGang(sys, hunt.BountyBy()));
  ArrayPush(amounts, up);
  return 1;
}

// ---- Posture layers (AddPostureLayer) ----------------------------------------------------------------------------------
// A layer moves how a faction treats V without touching what V earned with them, until it runs out or is taken off. Read
// in CBActingStanding, the one place every posture is worked out, and only while the player has not set that faction's
// view by hand. Every layer has an end (ApiLayerMaxDays at most), so one left by an uninstalled add-on runs out.
public class CBApiLayers extends ScriptableSystem {
  private persistent let m_next: Int32;
  private persistent let m_handle: array<Int32>;
  private persistent let m_faction: array<CName>;
  private persistent let m_delta: array<Float>;
  private persistent let m_until: array<Float>;
  private persistent let m_reason: array<CName>;

  public static func Get(game: GameInstance) -> ref<CBApiLayers> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiLayers") as CBApiLayers : null;
  }

  public func Count() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_handle), ArraySize(this.m_faction)), Min(ArraySize(this.m_delta),
               ArraySize(this.m_until))), ArraySize(this.m_reason));
  }

  public func Add(faction: CName, delta: Float, until: Float, reason: CName) -> Int32 {
    if this.Count() >= 32 {
      return 0;
    }
    this.m_next += 1;
    ArrayPush(this.m_handle, this.m_next);
    ArrayPush(this.m_faction, faction);
    ArrayPush(this.m_delta, delta);
    ArrayPush(this.m_until, until);
    ArrayPush(this.m_reason, reason);
    return this.m_next;
  }

  public func Remove(handle: Int32) -> Void {
    let i = this.Count() - 1;
    while i >= 0 {
      if this.m_handle[i] == handle {
        this.EraseAt(i);
      }
      i -= 1;
    }
  }

  private func EraseAt(i: Int32) -> Void {
    ArrayErase(this.m_handle, i);
    ArrayErase(this.m_faction, i);
    ArrayErase(this.m_delta, i);
    ArrayErase(this.m_until, i);
    ArrayErase(this.m_reason, i);
  }

  public func Sum(faction: CName, now: Float) -> Float {
    let total = 0.0;
    let n = this.Count();
    let i = 0;
    while i < n {
      if Equals(this.m_faction[i], faction) && now < this.m_until[i] {
        total += this.m_delta[i];
      }
      i += 1;
    }
    return total;
  }

  public func Prune(now: Float) -> Void {
    let i = this.Count() - 1;
    while i >= 0 {
      if now >= this.m_until[i] {
        this.EraseAt(i);
      }
      i -= 1;
    }
  }
}

public func CBApiPostureLayers(faction: CName) -> Float {
  let game = GetGameInstance();
  let layers = CBApiLayers.Get(game);
  if !IsDefined(layers) || layers.Count() == 0 {
    return 0.0;
  }
  return layers.Sum(faction, CBGameSeconds(game));
}

public func CBApiAddPostureLayer(game: GameInstance, faction: CName, delta: Float, untilGameSeconds: Float, reasonKey: CName) -> Int32 {
  let layers = CBApiLayers.Get(game);
  let now = CBGameSeconds(game);
  if !IsDefined(layers) || !CBApiFactionRegistered(faction) || untilGameSeconds <= now || AbsF(delta) < 0.01 {
    return 0;
  }
  let until = MinF(untilGameSeconds, now + CBConfig.ApiLayerMaxDays() * CBConfig.SecondsPerDay());
  return layers.Add(faction, ClampF(delta, -100.0, 100.0), until, reasonKey);
}

public func CBApiRemovePostureLayer(game: GameInstance, handle: Int32) -> Void {
  let layers = CBApiLayers.Get(game);
  if IsDefined(layers) && handle > 0 {
    layers.Remove(handle);
  }
}

// ---- Price factors (AddPriceFactor) ------------------------------------------------------------------------------------
// Keyed by one of Cyberbane's district ids (n"CityCenter": the shops there), or by a faction (the shops on streets it
// holds). Read in CBVendorBuyModifier, inside its clamp.
public class CBApiPrices extends ScriptableSystem {
  private persistent let m_next: Int32;
  private persistent let m_handle: array<Int32>;
  private persistent let m_key: array<CName>;
  private persistent let m_factor: array<Float>;
  private persistent let m_until: array<Float>;

  public static func Get(game: GameInstance) -> ref<CBApiPrices> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiPrices") as CBApiPrices : null;
  }

  public func Count() -> Int32 {
    return Min(Min(ArraySize(this.m_handle), ArraySize(this.m_key)), Min(ArraySize(this.m_factor), ArraySize(this.m_until)));
  }

  public func Add(key: CName, factor: Float, until: Float) -> Int32 {
    if this.Count() >= 32 {
      return 0;
    }
    this.m_next += 1;
    ArrayPush(this.m_handle, this.m_next);
    ArrayPush(this.m_key, key);
    ArrayPush(this.m_factor, factor);
    ArrayPush(this.m_until, until);
    return this.m_next;
  }

  public func Remove(handle: Int32) -> Void {
    let i = this.Count() - 1;
    while i >= 0 {
      if this.m_handle[i] == handle {
        ArrayErase(this.m_handle, i);
        ArrayErase(this.m_key, i);
        ArrayErase(this.m_factor, i);
        ArrayErase(this.m_until, i);
      }
      i -= 1;
    }
  }

  public func Prune(now: Float) -> Void {
    let i = this.Count() - 1;
    while i >= 0 {
      if now >= this.m_until[i] {
        ArrayErase(this.m_handle, i);
        ArrayErase(this.m_key, i);
        ArrayErase(this.m_factor, i);
        ArrayErase(this.m_until, i);
      }
      i -= 1;
    }
  }

  public func Mod(district: CName, holders: array<CName>, now: Float) -> Float {
    let m = 0.0;
    let n = this.Count();
    let i = 0;
    while i < n {
      let key = this.m_key[i];
      if now < this.m_until[i] && (Equals(key, district) || ArrayContains(holders, key)) {
        m += this.m_factor[i] - 1.0;
      }
      i += 1;
    }
    return m;
  }
}

public func CBApiPriceMod(sys: ref<CyberbaneSystem>) -> Float {
  let game = sys.GetGameInstance();
  let prices = CBApiPrices.Get(game);
  if !IsDefined(prices) || prices.Count() == 0 {
    return 0.0;
  }
  let holders = CBTurfGangsHere(sys);
  return prices.Mod(sys.GetCurrentDistrict(), holders, CBGameSeconds(game));
}

public func CBApiAddPriceFactor(game: GameInstance, key: CName, factor: Float, untilGameSeconds: Float) -> Int32 {
  let prices = CBApiPrices.Get(game);
  let now = CBGameSeconds(game);
  if !IsDefined(prices) || !IsNameValid(key) || untilGameSeconds <= now
     || (CBDistrictIndex(key) < 0 && !CBApiFactionRegistered(key)) {
    return 0;
  }
  let until = MinF(untilGameSeconds, now + CBConfig.ApiLayerMaxDays() * CBConfig.SecondsPerDay());
  return prices.Add(key, ClampF(factor, 0.5, 2.0), until);
}

public func CBApiRemovePriceFactor(game: GameInstance, handle: Int32) -> Void {
  let prices = CBApiPrices.Get(game);
  if IsDefined(prices) && handle > 0 {
    prices.Remove(handle);
  }
}

// Start over: whatever add-ons set for the old playthrough goes with it.
public func CBApiLevel3Clear(game: GameInstance) -> Void {
  CBApiBountyForget(game);
  let layers = CBApiLayers.Get(game);
  if IsDefined(layers) {
    layers.Prune(1000000000000.0);
  }
  let prices = CBApiPrices.Get(game);
  if IsDefined(prices) {
    prices.Prune(1000000000000.0);
  }
}

// From the slow tick: layers and factors whose time has run out are dropped.
public func CBApiLevel3SlowTick(game: GameInstance) -> Void {
  let now = CBGameSeconds(game);
  let layers = CBApiLayers.Get(game);
  if IsDefined(layers) {
    layers.Prune(now);
  }
  let prices = CBApiPrices.Get(game);
  if IsDefined(prices) {
    prices.Prune(now);
  }
}

// ---- Weather and time of day -------------------------------------------------------------------------------------------
// A sandstorm read the way MADMAX reads it: the game's own Sandstorm effect on V, off V only.
public func CBApiIsSandstorm(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  return IsDefined(player) && StatusEffectHelper.HasStatusEffectWithTagConst(player, n"Sandstorm");
}

// ---- Standing, read --------------------------------------------------------------------------------------------------
public func CBApiPostureOf(game: GameInstance, faction: CName) -> Int32 {
  let sys = CyberbaneSystem.Get(game);
  let score = IsDefined(sys) ? sys.GetScore() : null;
  return IsDefined(score) ? EnumInt(score.GetPosture(faction)) : EnumInt(ECBPosture.Neutral);
}

// ---- Corporate work on request (OfferCorpWork) -------------------------------------------------------------------------
public func CBApiOfferCorpWork(game: GameInstance, faction: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let life = CBStreetLifeFor(game);
  return IsDefined(sys) && IsDefined(life) && CBWorldStable(game) && life.OfferContractFrom(sys, game, faction);
}

// ---- Groups that wait for V to pick a side (neutralToV, GroupSideTaken) ------------------------------------------------
//
// Neutral to V when placed. Once V hurts one of them, the whole group turns on V (2). Once V hurts anybody of a group or
// convoy they are set hostile to (SetGroupsHostile), they stand with V (1). Either way it is decided once, on the tick.

func CBApiGroupHurtByV(game: GameInstance, kind: Int32, handle: Int32) -> Bool {
  let bodies: array<EntityID>;
  if kind == CBApiSideConvoy() {
    CBApiConvoyBodies(game, handle, bodies);
  } else {
    CBApiGroupBodies(game, handle, bodies);
  }
  for id in bodies {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.cbDamagedByPlayer {
      return true;
    }
  }
  return false;
}

func CBApiGroupTakesSide(sys: ref<CyberbaneSystem>, game: GameInstance, handle: Int32, side: Int32) -> Void {
  let bodies: array<EntityID>;
  CBApiGroupBodies(game, handle, bodies);
  for id in bodies {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBStillStanding(p) && CBNpcSafe(sys, p) {
      if side == 2 {
        CBMakeHostileToPlayer(game, p);
      } else {
        CBCrewFriendlyToV(game, p);
      }
    }
  }
  CBLog.Info(n"Api", side == 2 ? s"V fought an add-on's group (handle \(handle)): it turns on V."
                               : s"V stood with an add-on's group (handle \(handle)): it stays on V's side.");
}

public func CBApiNeutralTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let reg = CBApiRequests.Get(game);
  if !IsDefined(reg) || !CBWorldStable(game) {
    return;
  }
  let handles = reg.UndecidedNeutral();
  if ArraySize(handles) == 0 {
    return;
  }
  let pairs = CBApiPairs.Get(game);
  for h in handles {
    let side = 0;
    if CBApiGroupHurtByV(game, CBApiSideGroup(), h) {
      side = 2;
    } else {
      if IsDefined(pairs) {
        let i = 0;
        while i < pairs.Count() && side == 0 {
          if pairs.Hostile(i) && pairs.Involves(i, CBApiSideGroup(), h) {
            let otherKind = pairs.AKind(i) == CBApiSideGroup() && pairs.A(i) == h ? pairs.BKind(i) : pairs.AKind(i);
            let other = pairs.AKind(i) == CBApiSideGroup() && pairs.A(i) == h ? pairs.B(i) : pairs.A(i);
            if CBApiGroupHurtByV(game, otherKind, other) {
              side = 1;
            }
          }
          i += 1;
        }
      }
    }
    if side > 0 {
      reg.SetTaken(h, side);
      CBApiGroupTakesSide(sys, game, h, side);
    }
  }
}
