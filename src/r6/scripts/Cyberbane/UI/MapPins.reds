// Cyberbane - Its own box on the map, and the map remembering ([85], 2.5.0)
//
//   Its own box   with TweakXL, Cyberbane's place pins (where a Rival was last seen, a gathering on the way, and the
//                 places remembered below) use a pin definition and a filter group of their own
//                 (r6/tweaks/Cyberbane/map.yaml), and the map's custom filters gain a CYBERBANE box that shows and
//                 hides them all, by the game's own rules. It is ticked the first time the map is opened in a
//                 playthrough. Without TweakXL the pins sit under Your Property, as before 2.5.0.
//   Remembering   for a day after something big, a pin marks where it happened: a Rival who fell, a gathering V
//                 crashed, a district that changed hands, one of V's crew lost. Hovered, it says who and when.
//
// The technique (a group of one's own on a filter type nobody uses, a pin variant nothing draws, the controllers
// told what it looks like) is the one Gang Retaliation uses for its strongholds; credit to its author for showing
// it. Nothing of theirs is used here, and the two can be installed together: different filter type, different
// variant.
//
// Crash rules: no widget is made or removed; pins are registered and unregistered through the MappinSystem from the
// tick, never from a UI callback; the map's hooks call the game's code first and change only what is ours.

public func CBMapRemembersOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBMapMarkersOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().mapRemembers);
}

// Has TweakXL put Cyberbane's records in? Asked whenever a pin is made, so a game without TweakXL simply never
// uses them.
public func CBMapFilterReady() -> Bool {
  return IsDefined(TweakDBInterface.GetMappinUIFilterGroupRecord(t"WorldMap.CBFilterGroup"));
}

// The filter type our box is kept under (see map.yaml for why this one).
public func CBMapFilterType() -> gamedataWorldMapFilter = gamedataWorldMapFilter.Courier

// Every place pin Cyberbane puts down: our own definition and variant with TweakXL, the variant the game files under
// Your Property without. Both can be tracked for a route (worldMap.script, CanPlayerTrackMappin: neither is a quest's).
public func CBPlacePinData(caption: String) -> MappinData {
  let data: MappinData;
  if CBMapFilterReady() {
    data.mappinType = t"Mappins.CBPinDefinition";
    data.variant = gamedataMappinVariant.CPO_PingLootVariant;
  } else {
    data.mappinType = t"Mappins.DefaultStaticMappin";
    data.variant = gamedataMappinVariant.ApartmentVariant;
  }
  data.active = true;
  data.visibleThroughWalls = true;
  data.debugCaption = caption;
  return data;
}

// Our variant has no profile of its own for the pin in the world: it borrows the one the game gives an apartment,
// which is what our pins wore before.
@wrapMethod(WorldMappinsContainerController)
public func CreateMappinUIProfile(mappin: wref<IMappin>, mappinVariant: gamedataMappinVariant,
                                  customData: ref<MappinControllerCustomData>) -> MappinUIProfile {
  if Equals(mappinVariant, gamedataMappinVariant.CPO_PingLootVariant) && CBIsRivalPin(mappin) {
    return wrappedMethod(mappin, gamedataMappinVariant.ApartmentVariant, customData);
  }
  return wrappedMethod(mappin, mappinVariant, customData);
}

// The box ticked once, the first time this playthrough's map is opened, so the pins are there without the player
// having to find the box first. Never on the fast travel map, which keeps its own filters.
@wrapMethod(WorldMapMenuGameController)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();
  let book = CBMapBook.Get(GetGameInstance());
  if IsDefined(book) && !book.FilterSeeded() && CBMapFilterReady() && !this.IsFastTravelEnabled() {
    this.SetCustomFilter(CBMapFilterType());
    book.MarkFilterSeeded();
    CBLog.Info(n"UI", "The map's CYBERBANE box was ticked for this playthrough.");
  }
  return result;
}

// ---- The map remembering ([85]) -------------------------------------------------------------------------------------

public func CBMemRivalFell() -> Int32 = 0
public func CBMemEventCrashed() -> Int32 = 1
public func CBMemTakeover() -> Int32 = 2
public func CBMemCrewFell() -> Int32 = 3

public class CBMapMemory {
  public persistent let id: Int32;
  public persistent let kind: Int32;
  public persistent let x: Float;
  public persistent let y: Float;
  public persistent let z: Float;
  public persistent let at: Float;
  public persistent let subject: Int32;   // the Rival, or the crew member
  public persistent let a: CName;         // the event's first side, or the gang that took a district
  public persistent let b: CName;         // the event's second side, or the gang that lost it
  public persistent let what: CName;      // the event's kind
  public persistent let district: CName;
  public persistent let byV: Bool;
}

public class CBMapBook extends ScriptableSystem {
  private persistent let m_memories: array<ref<CBMapMemory>>;
  private persistent let m_nextId: Int32;
  private persistent let m_filterSeeded: Bool;
  private let m_checked: Bool;
  // Session only: the pin on each memory. Pins are not kept in a save; they are put back as the session starts.
  private let m_pinFor: array<Int32>;
  private let m_pinId: array<NewMappinID>;

  public static func Get(game: GameInstance) -> ref<CBMapBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBMapBook") as CBMapBook;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_checked = false;
    ArrayClear(this.m_pinFor);
    ArrayClear(this.m_pinId);
  }

  private func Check() -> Void {
    if this.m_checked {
      return;
    }
    this.m_checked = true;
    let i = ArraySize(this.m_memories) - 1;
    while i >= 0 {
      let m = this.m_memories[i];
      if !IsDefined(m) || m.id <= 0 {
        ArrayErase(this.m_memories, i);
      } else {
        if m.id >= this.m_nextId {
          this.m_nextId = m.id + 1;
        }
      }
      i -= 1;
    }
  }

  public func FilterSeeded() -> Bool { return this.m_filterSeeded; }
  public func MarkFilterSeeded() -> Void { this.m_filterSeeded = true; }

  public func Count() -> Int32 {
    this.Check();
    return ArraySize(this.m_memories);
  }

  public func At(i: Int32) -> ref<CBMapMemory> {
    this.Check();
    return i >= 0 && i < ArraySize(this.m_memories) ? this.m_memories[i] : null;
  }

  public func Find(id: Int32) -> ref<CBMapMemory> {
    this.Check();
    for m in this.m_memories {
      if IsDefined(m) && m.id == id {
        return m;
      }
    }
    return null;
  }

  // A new memory, the oldest let go past the cap. A memory close to one already kept, of the same kind, replaces it.
  public func Add(kind: Int32, at: Vector4, now: Float, subject: Int32, a: CName, b: CName, what: CName,
                  district: CName, byV: Bool) -> Void {
    this.Check();
    let i = ArraySize(this.m_memories) - 1;
    while i >= 0 {
      let old = this.m_memories[i];
      if IsDefined(old) && old.kind == kind && Vector4.Distance(at, new Vector4(old.x, old.y, old.z, 1.0)) < CBConfig.MapMemoryMerge() {
        this.Forget(old);
      }
      i -= 1;
    }
    while ArraySize(this.m_memories) >= CBConfig.MapMemoryKept() {
      this.Forget(this.m_memories[0]);
    }
    if this.m_nextId <= 0 {
      this.m_nextId = 1;
    }
    let m = new CBMapMemory();
    m.id = this.m_nextId;
    this.m_nextId += 1;
    m.kind = kind;
    m.x = at.X;
    m.y = at.Y;
    m.z = at.Z;
    m.at = now;
    m.subject = subject;
    m.a = a;
    m.b = b;
    m.what = what;
    m.district = district;
    m.byV = byV;
    ArrayPush(this.m_memories, m);
  }

  // Out of the book; its pin, if any, is left for the tick to take down (Unpinned below).
  public func Forget(m: ref<CBMapMemory>) -> Void {
    if IsDefined(m) {
      ArrayRemove(this.m_memories, m);
    }
  }

  public func PinIndex(id: Int32) -> Int32 {
    let i = 0;
    while i < Min(ArraySize(this.m_pinFor), ArraySize(this.m_pinId)) {
      if this.m_pinFor[i] == id {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func IsPinned(id: Int32) -> Bool {
    return this.PinIndex(id) >= 0;
  }

  public func SetPin(id: Int32, pin: NewMappinID) -> Void {
    ArrayPush(this.m_pinFor, id);
    ArrayPush(this.m_pinId, pin);
  }

  public func Unpin(ms: ref<MappinSystem>, id: Int32) -> Void {
    let k = this.PinIndex(id);
    if k < 0 {
      return;
    }
    if IsDefined(ms) {
      ms.UnregisterMappin(this.m_pinId[k]);
    }
    ArrayErase(this.m_pinFor, k);
    ArrayErase(this.m_pinId, k);
  }

  // Pins whose memory is no longer in the book, taken down.
  public func DropStrays(ms: ref<MappinSystem>) -> Void {
    let k = Min(ArraySize(this.m_pinFor), ArraySize(this.m_pinId)) - 1;
    while k >= 0 {
      if !IsDefined(this.Find(this.m_pinFor[k])) {
        if IsDefined(ms) {
          ms.UnregisterMappin(this.m_pinId[k]);
        }
        ArrayErase(this.m_pinFor, k);
        ArrayErase(this.m_pinId, k);
      }
      k -= 1;
    }
  }

  public func UnpinAll(ms: ref<MappinSystem>) -> Void {
    let k = Min(ArraySize(this.m_pinFor), ArraySize(this.m_pinId)) - 1;
    while k >= 0 {
      if IsDefined(ms) {
        ms.UnregisterMappin(this.m_pinId[k]);
      }
      k -= 1;
    }
    ArrayClear(this.m_pinFor);
    ArrayClear(this.m_pinId);
  }

  public func PinnedCount() -> Int32 {
    return Min(ArraySize(this.m_pinFor), ArraySize(this.m_pinId));
  }

  // Start over (Core/CyberbaneSystem.reds, HardReset). The tick takes the pins down.
  // Start over (Core/CyberbaneSystem.reds, HardReset, from the settled tick). The pins go with the memories, here:
  // left for the tick, a new memory numbered 1 found the old pin for 1 and was shown where the old one had been (2.5.0).
  public func Clear() -> Void {
    this.UnpinAll(GameInstance.GetMappinSystem(this.GetGameInstance()));
    ArrayClear(this.m_memories);
    this.m_nextId = 1;
  }
}

// Something big happened here: remembered for a day.
public func CBMapRemember(sys: ref<CyberbaneSystem>, game: GameInstance, kind: Int32, at: Vector4, subject: Int32, a: CName,
                          b: CName, what: CName, byV: Bool) -> Void {
  let book = CBMapBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || !CBMapRemembersOn() || (at.X == 0.0 && at.Y == 0.0) {
    return;
  }
  book.Add(kind, at, CBGameSeconds(game), subject, a, b, what, CBEventDistrict(sys, game), byV);
  CBLog.Info(n"UI", s"The map remembers something here (kind \(kind)).");
}

// Where a district changing hands is pinned: the newest place the street remembers there, or V, standing in it.
public func CBMapTakeoverSpot(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, out at: Vector4) -> Bool {
  let street = CBStreetBook.Get(game);
  let best = -1.0;
  if IsDefined(street) {
    let i = 0;
    while i < street.PlaceCount() {
      if Equals(street.PlaceDistrict(i), district) && street.PlaceAt(i) > best {
        best = street.PlaceAt(i);
        at = street.PlacePos(i);
      }
      i += 1;
    }
  }
  if best >= 0.0 {
    return true;
  }
  let player = GetPlayer(game);
  if IsDefined(player) && Equals(sys.GetCurrentDistrict(), district) {
    at = player.GetWorldPosition();
    return true;
  }
  return false;
}

// Every few settled ticks: pins up for what is remembered, down for what is forgotten or a day old, all down with the
// setting off.
public func CBMapMemoryTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBMapBook.Get(game);
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(book) || !IsDefined(ms) {
    return;
  }
  if !CBMapRemembersOn() {
    if book.PinnedCount() > 0 {
      book.UnpinAll(ms);
    }
    return;
  }
  let now = CBGameSeconds(game);
  let life = CBConfig.MapMemoryHours() * CBConfig.SecondsPerHour();
  let i = book.Count() - 1;
  while i >= 0 {
    let m = book.At(i);
    i -= 1;
    if IsDefined(m) && now - m.at > life {
      book.Unpin(ms, m.id);
      book.Forget(m);
    }
  }
  book.DropStrays(ms);
  if !CBWorldStable(game) {
    return;
  }
  i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && !book.IsPinned(m.id) {
      CBTrace("map: a pin where something happened");
      book.SetPin(m.id, ms.RegisterMappin(CBPlacePinData(CBMemoryPinCaption(m.id)), new Vector4(m.x, m.y, m.z, 1.0)));
    }
  }
}

// ---- What a remembered place says, worked out when it is hovered ----------------------------------------------------

public func CBMemoryPinCaption(id: Int32) -> String {
  return CBRivalPinTag() + CBMemoryPinMark() + IntToString(id);
}

public func CBMemoryPinMark() -> String = "@"

func CBMapAgo(game: GameInstance, at: Float) -> String {
  let ago = CBHudSince(CBGameSeconds(game), at);
  return StrLen(ago) > 0 ? ago + " ago" : "just now";
}

public func CBMapMemoryTitle(sys: ref<CyberbaneSystem>, id: Int32) -> String {
  let book = IsDefined(sys) ? CBMapBook.Get(sys.GetGameInstance()) : null;
  let m = IsDefined(book) ? book.Find(id) : null;
  if !IsDefined(m) {
    return "Cyberbane";
  }
  if m.kind == CBMemRivalFell() {
    let r = sys.FindRivalById(m.subject);
    return IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "A Rival";
  }
  if m.kind == CBMemEventCrashed() {
    return CBEventCaptionOf(m.what, m.a, m.b);
  }
  if m.kind == CBMemTakeover() {
    return s"\(CBCapFirst(CBFactionLabel(m.a))) took \(CBDistrictLabel(m.district))";
  }
  let crew = CBCrewBook.Get(sys.GetGameInstance());
  let past = IsDefined(crew) ? crew.FindPast(m.subject) : null;
  return IsDefined(past) ? CBCrewPastName(sys, past) : "One of your crew";
}

public func CBMapMemoryDesc(sys: ref<CyberbaneSystem>, id: Int32) -> String {
  let game = sys.GetGameInstance();
  let book = CBMapBook.Get(game);
  let m = IsDefined(book) ? book.Find(id) : null;
  if !IsDefined(m) {
    return "";
  }
  let ago = CBMapAgo(game, m.at);
  if m.kind == CBMemRivalFell() {
    return m.byV ? s"Fell here by your hand, \(ago)." : s"Killed here \(ago), and not by you.";
  }
  if m.kind == CBMemEventCrashed() {
    return s"You broke it up here, \(ago). They have not forgotten.";
  }
  if m.kind == CBMemTakeover() {
    return StrLen(CBFactionLabel(m.b)) > 0 ? s"Taken from \(CBFactionLabel(m.b)), \(ago)." : s"Changed hands \(ago).";
  }
  let crew = CBCrewBook.Get(game);
  let past = IsDefined(crew) ? crew.FindPast(m.subject) : null;
  if IsDefined(past) && past.by > 0 {
    let killer = sys.FindRivalById(past.by);
    if IsDefined(killer) {
      return s"Died here fighting for you, \(ago). \(CBRivalDisplayName(sys.GetContent(), killer)) did it.";
    }
  }
  return s"Died here fighting for you, \(ago).";
}

// What a remembered place is drawn with: a part of the game's own map atlas, and a colour.
// n"" for a Rival or one of the crew, who keep Cyberbane's own mark (map_bounty, the obvious part, is the game's NCPD
// hustle).
public func CBMapMemoryPart(sys: ref<CyberbaneSystem>, id: Int32) -> CName {
  let book = IsDefined(sys) ? CBMapBook.Get(sys.GetGameInstance()) : null;
  let m = IsDefined(book) ? book.Find(id) : null;
  if IsDefined(m) && m.kind == CBMemEventCrashed() { return n"dynamic_event"; }
  if IsDefined(m) && m.kind == CBMemTakeover() { return n"outpost"; }
  return n"";
}


public func CBMapMemoryTint(sys: ref<CyberbaneSystem>, id: Int32) -> HDRColor {
  let book = IsDefined(sys) ? CBMapBook.Get(sys.GetGameInstance()) : null;
  let m = IsDefined(book) ? book.Find(id) : null;
  if IsDefined(m) && m.kind == CBMemEventCrashed() { return CBHudAmber(); }
  if IsDefined(m) && m.kind == CBMemTakeover() { return CBHudCyan(); }
  if IsDefined(m) && m.kind == CBMemCrewFell() { return CBHudGreen(); }
  return CBHudRed();
}
