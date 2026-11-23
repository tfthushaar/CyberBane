// Cyberbane - what an add-on may ask for (extension API level 1, 2.7.4)
//
// People, pins, texts and standing, each through the same gates Cyberbane's own go through, so an add-on can never push
// the world past the 18-spawn ceiling, place somebody during a scene, text past "Where messages go" or move a standing the
// player has frozen. The add-on asks; Cyberbane decides and does it.
//
// People (RequestGroup): placed with Cyberbane's own spawning (near V out of sight, or round a point), tagged CB_Api so the
// sanctuary hold, the combat release and every sweep reach them, set up by Cyberbane (the killable clamp, a crew's or an
// apex's build, hostile or on V's side) and removed only the safe way (ReleaseGroup). A handle names the group; 0 means no
// group, and GroupWhyNot says why.

public func CBApiPlaceNearV() -> Int32 = 0
public func CBApiPlaceAt() -> Int32 = 1
public func CBApiGradeCrew() -> Int32 = 0
public func CBApiGradeApex() -> Int32 = 1

public class CBSpawnSpec {
  public let faction: CName;
  // People only (CBRecordIsPerson); the last one stands in for the rest when there are fewer records than people.
  public let records: array<TweakDBID>;
  public let count: Int32;
  public let place: Int32;      // CBApiPlaceNearV, CBApiPlaceAt
  public let at: Vector4;       // for CBApiPlaceAt
  public let onVsSide: Bool;    // the crew's gate (a fight V chose) instead of the arrivals gate; friendly to V
  public let grade: Int32;      // CBApiGradeCrew, CBApiGradeApex: built and measured against V the way those are
}

public class CBApiRequests extends ScriptableSystem {
  private let m_next: Int32;
  private let m_handles: array<Int32>;
  private let m_side: array<Bool>;
  private let m_grade: array<Int32>;
  private let m_lastWhy: String;
  private let m_pinIds: array<Int32>;
  private let m_pins: array<NewMappinID>;
  private let m_pinUntil: array<Float>;
  private let m_pinNext: Int32;
  private let m_senderIds: array<CName>;
  private let m_senderKeys: array<CName>;

  public static func Get(game: GameInstance) -> ref<CBApiRequests> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiRequests") as CBApiRequests : null;
  }

  public func LastWhy() -> String { return this.m_lastWhy; }
  public func SetWhy(why: String) -> Void { this.m_lastWhy = why; }

  public func NewHandle(side: Bool, grade: Int32) -> Int32 {
    this.m_next += 1;
    ArrayPush(this.m_handles, this.m_next);
    ArrayPush(this.m_side, side);
    ArrayPush(this.m_grade, grade);
    while ArraySize(this.m_handles) > 64 {
      ArrayErase(this.m_handles, 0);
      ArrayErase(this.m_side, 0);
      ArrayErase(this.m_grade, 0);
    }
    return this.m_next;
  }

  public func Drop(handle: Int32) -> Void {
    let i = ArrayFindFirst(this.m_handles, handle);
    if i >= 0 && i < ArraySize(this.m_side) && i < ArraySize(this.m_grade) {
      ArrayErase(this.m_handles, i);
      ArrayErase(this.m_side, i);
      ArrayErase(this.m_grade, i);
    }
  }

  // The group a body belongs to, by its group tag; 0 for none.
  public func HandleOf(des: ref<DynamicEntitySystem>, id: EntityID) -> Int32 {
    for h in this.m_handles {
      if des.IsTagged(id, CBApiGroupTag(h)) {
        return h;
      }
    }
    return 0;
  }

  public func SideOf(handle: Int32) -> Bool {
    let i = ArrayFindFirst(this.m_handles, handle);
    return i >= 0 && i < ArraySize(this.m_side) && this.m_side[i];
  }

  public func GradeOf(handle: Int32) -> Int32 {
    let i = ArrayFindFirst(this.m_handles, handle);
    return i >= 0 && i < ArraySize(this.m_grade) ? this.m_grade[i] : CBApiGradeCrew();
  }

  // ---- Pins
  public func AddPin(pin: NewMappinID, until: Float) -> Int32 {
    this.m_pinNext += 1;
    ArrayPush(this.m_pinIds, this.m_pinNext);
    ArrayPush(this.m_pins, pin);
    ArrayPush(this.m_pinUntil, until);
    return this.m_pinNext;
  }

  public func RemovePin(game: GameInstance, id: Int32) -> Bool {
    let i = ArrayFindFirst(this.m_pinIds, id);
    if i < 0 || i >= ArraySize(this.m_pins) || i >= ArraySize(this.m_pinUntil) {
      return false;
    }
    let ms = GameInstance.GetMappinSystem(game);
    if IsDefined(ms) {
      ms.UnregisterMappin(this.m_pins[i]);
    }
    ArrayErase(this.m_pinIds, i);
    ArrayErase(this.m_pins, i);
    ArrayErase(this.m_pinUntil, i);
    return true;
  }

  public func ExpirePins(game: GameInstance) -> Void {
    let now = CBGameSeconds(game);
    let i = Min(Min(ArraySize(this.m_pinIds), ArraySize(this.m_pins)), ArraySize(this.m_pinUntil)) - 1;
    while i >= 0 {
      if this.m_pinUntil[i] > 0.0 && now >= this.m_pinUntil[i] {
        this.RemovePin(game, this.m_pinIds[i]);
      }
      i -= 1;
    }
  }

  // ---- Senders
  public func AddSender(id: CName, nameKey: CName) -> Void {
    let i = ArrayFindFirst(this.m_senderIds, id);
    if i >= 0 && i < ArraySize(this.m_senderKeys) {
      this.m_senderKeys[i] = nameKey;
      return;
    }
    ArrayPush(this.m_senderIds, id);
    ArrayPush(this.m_senderKeys, nameKey);
  }

  public func SenderKey(id: CName) -> CName {
    let i = ArrayFindFirst(this.m_senderIds, id);
    return i >= 0 && i < ArraySize(this.m_senderKeys) ? this.m_senderKeys[i] : n"";
  }
}

public func CBApiGroupTag(handle: Int32) -> CName {
  return StringToName("CB_ApiGroup" + IntToString(handle));
}

// The request itself: gates, room, placement, and the new bodies tagged with their group.
public func CBApiRequestGroup(game: GameInstance, spec: ref<CBSpawnSpec>) -> Int32 {
  let reg = CBApiRequests.Get(game);
  let sys = CyberbaneSystem.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(reg) || !IsDefined(sys) || !IsDefined(des) || !IsDefined(spec) {
    return 0;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    reg.SetWhy("Cyberbane is switched off");
    return 0;
  }
  if NotEquals(spec.faction, n"") && !CBFactionOn(spec.faction) {
    reg.SetWhy("that faction is switched off under Factions");
    return 0;
  }
  if !CBWorldStable(game) {
    reg.SetWhy("the world has not settled");
    return 0;
  }
  let held = spec.onVsSide ? CBArrivalsHeldBase(sys, game) : CBArrivalsHeld(sys, game);
  if held {
    let why = CBArrivalsHeldWhy(sys, game);
    reg.SetWhy(StrLen(why) > 0 ? why : "arrivals are held here");
    return 0;
  }
  let room = CBSpawnRoom(game);
  let want = Min(Max(spec.count, 0), room);
  if want <= 0 {
    reg.SetWhy("no room: Cyberbane already has as many people out as it allows");
    return 0;
  }
  let records: array<TweakDBID>;
  for r in spec.records {
    if TDBID.IsValid(r) && CBRecordIsPerson(r) {
      ArrayPush(records, r);
    }
  }
  if ArraySize(records) == 0 {
    reg.SetWhy("no record that is a person");
    return 0;
  }
  let handle = reg.NewHandle(spec.onVsSide, spec.grade);
  let tag = CBApiGroupTag(handle);
  let before = des.GetTaggedIDs(n"CB_Api");
  let placed = 0;
  let k = 0;
  while k < want {
    let rec = records[Min(k, ArraySize(records) - 1)];
    let last: EntityID;
    let got = 0;
    if spec.place == CBApiPlaceAt() {
      got = CBPlaceAround(sys, game, rec, spec.at, 1, n"CB_Api");
    } else {
      got = CBSpawnGroup(game, rec, n"", 1, n"CB_Api", CBConfig.MyCrewSpawnDistance() * 2.0, last);
    }
    placed += got;
    k += 1;
  }
  let after = des.GetTaggedIDs(n"CB_Api");
  for id in after {
    if !ArrayContains(before, id) {
      des.AssignTag(id, tag);
    }
  }
  if placed == 0 {
    reg.Drop(handle);
    reg.SetWhy("nowhere to put them out of V's sight");
    return 0;
  }
  CBLog.Info(n"Spawn", s"An add-on's group placed: \(placed) of \(want) (handle \(handle)).");
  return handle;
}

// Set-up for an add-on's body (Spawn/Spawner.reds): on V's side, or hostile and built like a crew or an apex.
public func CBApiSetUpBody(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let reg = CBApiRequests.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(reg) || !IsDefined(des) || !CBStillStanding(puppet) {
    return;
  }
  let handle = reg.HandleOf(des, puppet.GetEntityID());
  if reg.SideOf(handle) {
    CBDisarmGodMode(game, puppet);
    CBCrewFriendlyToV(game, puppet);
    return;
  }
  CBSetUpStreet(sys, game, puppet, true);
  if reg.GradeOf(handle) == CBApiGradeApex() {
    CBKitApexMember(puppet);
    CBApplyApexBuild(sys, game, puppet, 1.0, CBApexStrengthFraction(), 1.0);
  } else {
    CBKitSquadMember(puppet);
    CBApplyCrewBuild(sys, game, puppet);
  }
}

public func CBApiGroupAlive(game: GameInstance, handle: Int32) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || handle <= 0 {
    return 0;
  }
  let n = 0;
  let ids = des.GetTaggedIDs(CBApiGroupTag(handle));
  for id in ids {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if des.IsSpawning(id) || CBStillStanding(p) {
      n += 1;
    }
  }
  return n;
}

public func CBApiGroupBodies(game: GameInstance, handle: Int32, out bodies: array<EntityID>) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  ArrayClear(bodies);
  if !IsDefined(des) || handle <= 0 {
    return 0;
  }
  let ids = des.GetTaggedIDs(CBApiGroupTag(handle));
  for id in ids {
    ArrayPush(bodies, id);
  }
  return ArraySize(bodies);
}

public func CBApiReleaseGroup(game: GameInstance, handle: Int32) -> Void {
  let reg = CBApiRequests.Get(game);
  if handle <= 0 {
    return;
  }
  CBDeleteTaggedSafe(game, CBApiGroupTag(handle), true, true);
  if IsDefined(reg) {
    reg.Drop(handle);
  }
}

// ---- Pins: drawn by Cyberbane's pin system, in the CYBERBANE filter box; until 0 keeps it until Unpin.
public func CBApiPinPlace(game: GameInstance, captionKey: CName, pos: Vector4, until: Float) -> Int32 {
  let reg = CBApiRequests.Get(game);
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(reg) || !IsDefined(ms) || !CBMapMarkersOn() {
    return 0;
  }
  let pin = ms.RegisterMappin(CBPlacePinData(CBT(captionKey)), pos);
  return reg.AddPin(pin, until);
}

// ---- Texts: the add-on's own contact, through the hearsay queue, Where messages go and How much you hear.
public func CBApiSendAside(game: GameInstance, sender: CName, text: String) -> Bool {
  let reg = CBApiRequests.Get(game);
  let key = IsDefined(reg) ? reg.SenderKey(sender) : n"";
  if !IsNameValid(key) || StrLen(text) == 0 || !CBMessagesOn() {
    return false;
  }
  CBHearsayTinted(game, CBT(key), text, CBHudCyan(), n"", n"");
  return true;
}

// ---- Standing, with the reason in the History (an add-on's key, shown as its text).
public func CBApiAdjustStanding(game: GameInstance, faction: CName, delta: Float, reasonKey: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) || Equals(faction, n"") || CBReputationFrozen() || !CBFactionOn(faction) {
    return false;
  }
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(fs) {
    return false;
  }
  fs.standing = ClampF(fs.standing + delta, -100.0, 100.0);
  if IsNameValid(reasonKey) {
    CBFileLog(sys, reasonKey, CBGameSeconds(game), CBEventDistrict(sys, game), faction, delta);
  }
  return true;
}

public func CBApiRequestsTick(game: GameInstance) -> Void {
  let reg = CBApiRequests.Get(game);
  if IsDefined(reg) {
    reg.ExpirePins(game);
  }
}

// ---- Questions by text (AskPriced): an add-on's contact asks, V answers in the thread like any of Cyberbane's own.
//
// While a question is waiting, that contact's thread offers the add-on's answers. The first answer may carry a price,
// which Cyberbane takes from V when it is chosen (when V cannot pay it, V says so and the question stays open). The
// add-on hears the answer on its listener: the token it asked with, the answer's place in the list, and whether V paid.

public abstract class CBApiAnswerListener extends IScriptable {
  public func OnAnswer(game: GameInstance, token: Int32, choice: Int32, paid: Bool) -> Void {}
}

public func CBPhoneAnswerApi() -> Int32 = -2

public class CBApiAskOptions {
  public let texts: array<String>;
}

public class CBApiAsks extends ScriptableSystem {
  private let m_names: array<String>;
  private let m_options: array<ref<CBApiAskOptions>>;
  private let m_prices: array<Int32>;
  private let m_tokens: array<Int32>;
  private let m_listeners: array<ref<CBApiAnswerListener>>;

  public static func Get(game: GameInstance) -> ref<CBApiAsks> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiAsks") as CBApiAsks : null;
  }

  private func IndexOf(name: String) -> Int32 {
    let n = Min(Min(ArraySize(this.m_names), ArraySize(this.m_options)), Min(Min(ArraySize(this.m_prices), ArraySize(this.m_tokens)), ArraySize(this.m_listeners)));
    let i = 0;
    while i < n {
      if Equals(this.m_names[i], name) {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func Pending(name: String) -> Bool { return StrLen(name) > 0 && this.IndexOf(name) >= 0; }

  public func Ask(name: String, options: array<String>, price: Int32, token: Int32, listener: ref<CBApiAnswerListener>) -> Void {
    this.Forget(name);
    let o = new CBApiAskOptions();
    o.texts = options;
    ArrayPush(this.m_names, name);
    ArrayPush(this.m_options, o);
    ArrayPush(this.m_prices, Max(price, 0));
    ArrayPush(this.m_tokens, token);
    ArrayPush(this.m_listeners, listener);
  }

  public func Options(name: String) -> array<String> {
    let none: array<String>;
    let i = this.IndexOf(name);
    return i >= 0 && IsDefined(this.m_options[i]) ? this.m_options[i].texts : none;
  }

  public func Price(name: String) -> Int32 {
    let i = this.IndexOf(name);
    return i >= 0 ? this.m_prices[i] : 0;
  }

  public func Token(name: String) -> Int32 {
    let i = this.IndexOf(name);
    return i >= 0 ? this.m_tokens[i] : 0;
  }

  public func Listener(name: String) -> ref<CBApiAnswerListener> {
    let i = this.IndexOf(name);
    return i >= 0 ? this.m_listeners[i] : null;
  }

  public func Forget(name: String) -> Void {
    let i = this.IndexOf(name);
    if i >= 0 {
      ArrayErase(this.m_names, i);
      ArrayErase(this.m_options, i);
      ArrayErase(this.m_prices, i);
      ArrayErase(this.m_tokens, i);
      ArrayErase(this.m_listeners, i);
    }
  }
}

// Posted straight to the thread (a question is not hearsay), when messages go to the phone.
public func CBApiAskPriced(game: GameInstance, sender: CName, text: String, options: array<String>, price: Int32, token: Int32,
                           listener: ref<CBApiAnswerListener>) -> Bool {
  let reg = CBApiRequests.Get(game);
  let asks = CBApiAsks.Get(game);
  let key = IsDefined(reg) ? reg.SenderKey(sender) : n"";
  if !IsNameValid(key) || !IsDefined(asks) || ArraySize(options) == 0 || StrLen(text) == 0 || !CBMessagesOn()
     || NotEquals(CBMessageDelivery(), ECBMessageDelivery.Phone) {
    return false;
  }
  let name = CBT(key);
  asks.Ask(name, options, price, token, listener);
  CBPhoneSendTinted(game, name, text, CBHudCyan());
  return true;
}

// The thread's answers, the price with the first.
public func CBApiAskChoices(game: GameInstance, name: String) -> array<String> {
  let out: array<String>;
  let asks = CBApiAsks.Get(game);
  if !IsDefined(asks) {
    return out;
  }
  let price = asks.Price(name);
  let options = asks.Options(name);
  let i = 0;
  for o in options {
    ArrayPush(out, i == 0 && price > 0 ? o + "  (" + IntToString(price) + "eb)" : o);
    i += 1;
  }
  return out;
}

// V answered: V's line into the thread, the price taken for the first answer, then the add-on told.
public func CBApiAskReply(game: GameInstance, store: ref<CBPhone>, thread: Int32, name: String, choice: Int32) -> Void {
  let asks = CBApiAsks.Get(game);
  if !IsDefined(asks) || !asks.Pending(name) {
    return;
  }
  let options = asks.Options(name);
  if choice < 0 || choice >= ArraySize(options) {
    return;
  }
  let price = asks.Price(name);
  let paid = false;
  if choice == 0 && price > 0 {
    let player = GetPlayer(game);
    let ts = GameInstance.GetTransactionSystem(game);
    if !IsDefined(player) || !IsDefined(ts) || ts.GetItemQuantity(player, ItemID.FromTDBID(t"Items.money")) < price {
      store.Reply(game, thread, CBT(n"Cyberbane-Api-CannotPay"));
      return;
    }
    ts.RemoveItem(player, ItemID.FromTDBID(t"Items.money"), price);
    paid = true;
  }
  store.Reply(game, thread, options[choice]);
  let token = asks.Token(name);
  let listener = asks.Listener(name);
  asks.Forget(name);
  if IsDefined(listener) {
    listener.OnAnswer(game, token, choice, paid);
  }
}
