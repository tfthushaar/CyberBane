// Cyberbane - What the street remembers (2.3.1)
//
// Two things the street keeps that nothing else did:
//
//   Places that remember ([7]). Where something big happened (a room full of bodies, a boss put down, a
//   MaxTac operative dropped, a gang's apex squad wiped out) is kept for a few in-game days, as long as
//   the district's temper remembers (Data/Districts.reds). People near it talk about it, the gang that
//   lost people there is jumpier (Reactions/Morale.reds), and it waits before sending anybody back there
//   (Spawn/Queue.reds).
//
//   What V is known by ([73], [74]). The car V keeps turning up to fights in, and the gun V keeps using,
//   counted each time somebody saw V fight with them. Once either is known, a mask does not hide V while
//   in that car or with that gun out (CBRecognizes, Reactions/Director.reds), and the Hub says so.
//
// Its own system for the reason CBTurfBook is: a new persistent field on a class a save already holds would
// change that class's saved shape, and a new class starts empty on a save that never had it. Parallel lists,
// trimmed to the shortest on the first read after a load, bounds-checked on every read.

public class CBStreetBook extends ScriptableSystem {
  // Places, oldest first.
  private persistent let m_placeKind: array<CName>;
  private persistent let m_placeGang: array<CName>;
  private persistent let m_placeDistrict: array<CName>;
  private persistent let m_placeX: array<Float>;
  private persistent let m_placeY: array<Float>;
  private persistent let m_placeZ: array<Float>;
  private persistent let m_placeAt: array<Float>;
  // Cars and guns V fought with where somebody could see: which (0 car, 1 gun), the record, how many times,
  // and when last.
  private persistent let m_knownKind: array<Int32>;
  private persistent let m_knownRecord: array<TweakDBID>;
  private persistent let m_knownSeen: array<Int32>;
  private persistent let m_knownAt: array<Float>;

  // Somebody V paid to keep watch ([8], Reactions/StreetPay.reds): where, until when, and what they sign with.
  private persistent let m_watchDistrict: CName;
  private persistent let m_watchUntil: Float;
  private persistent let m_watchName: CName;   // a name, kept as one: free text cannot be saved

  // The session's own: the car V last drove, and the witness on their way to a gang (Reactions/Witnesses.reds).
  public let lastCar: EntityID;
  public let lastCarRecord: TweakDBID;
  public let lastCarNoteAt: Float;     // a car counts once a fight, not once a body
  public let tellerId: EntityID;
  public let tellerFaction: CName;
  public let tellerTick: Int32;
  public let tellerDistrict: CName;
  // A wannabe out to make a name off V (Spawn/Wannabe.reds).
  public let wannabeId: EntityID;
  public let wannabeTick: Int32;
  public let wannabeStage: Int32;
  public let wannabeStageTick: Int32;
  public let wannabeNext: Float;
  public let wannabeDistrict: CName;
  // Whether V is given away by car or gun right now, worked out once a tick (CBVGivenAway).
  public let givenAwayTick: Int32;
  public let givenAway: Int32;         // 0 no, 1 by car, 2 by gun

  private let m_trimmed: Bool;

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_trimmed = false;
  }

  public static func Get(game: GameInstance) -> ref<CBStreetBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBStreetBook") as CBStreetBook;
  }

  // Every list of a kind cut to the shortest, so one that came back from a save short is never read past.
  private func Trim() -> Void {
    if this.m_trimmed {
      return;
    }
    this.m_trimmed = true;
    let n = Min(Min(ArraySize(this.m_placeKind), ArraySize(this.m_placeGang)),
                Min(Min(ArraySize(this.m_placeDistrict), ArraySize(this.m_placeX)),
                    Min(Min(ArraySize(this.m_placeY), ArraySize(this.m_placeZ)), ArraySize(this.m_placeAt))));
    ArrayResize(this.m_placeKind, n);
    ArrayResize(this.m_placeGang, n);
    ArrayResize(this.m_placeDistrict, n);
    ArrayResize(this.m_placeX, n);
    ArrayResize(this.m_placeY, n);
    ArrayResize(this.m_placeZ, n);
    ArrayResize(this.m_placeAt, n);
    let k = Min(Min(ArraySize(this.m_knownKind), ArraySize(this.m_knownRecord)),
                Min(ArraySize(this.m_knownSeen), ArraySize(this.m_knownAt)));
    ArrayResize(this.m_knownKind, k);
    ArrayResize(this.m_knownRecord, k);
    ArrayResize(this.m_knownSeen, k);
    ArrayResize(this.m_knownAt, k);
  }

  // ---- Places ----------------------------------------------------------------------------------------

  public func PlaceCount() -> Int32 {
    this.Trim();
    return ArraySize(this.m_placeKind);
  }

  public func PlaceKind(i: Int32) -> CName {
    return i >= 0 && i < this.PlaceCount() ? this.m_placeKind[i] : n"";
  }

  public func PlaceGang(i: Int32) -> CName {
    return i >= 0 && i < this.PlaceCount() ? this.m_placeGang[i] : n"";
  }

  public func PlaceAt(i: Int32) -> Float {
    return i >= 0 && i < this.PlaceCount() ? this.m_placeAt[i] : 0.0;
  }

  public func PlacePos(i: Int32) -> Vector4 {
    if i < 0 || i >= this.PlaceCount() {
      return new Vector4(0.0, 0.0, 0.0, 1.0);
    }
    return new Vector4(this.m_placeX[i], this.m_placeY[i], this.m_placeZ[i], 1.0);
  }

  // Something big happened here. A place already remembered close by takes the newer deed instead of a
  // second entry, so one street corner is one memory.
  public func Remember(kind: CName, gang: CName, district: CName, at: Vector4, now: Float) -> Void {
    this.Trim();
    let i = 0;
    while i < ArraySize(this.m_placeKind) {
      let d = Vector4.Distance(at, new Vector4(this.m_placeX[i], this.m_placeY[i], this.m_placeZ[i], 1.0));
      if d <= CBConfig.PlaceMergeDistance() {
        this.m_placeKind[i] = kind;
        this.m_placeGang[i] = gang;
        this.m_placeDistrict[i] = district;
        this.m_placeAt[i] = now;
        return;
      }
      i += 1;
    }
    if ArraySize(this.m_placeKind) >= CBConfig.PlaceCap() {
      this.ForgetPlace(0);
    }
    ArrayPush(this.m_placeKind, kind);
    ArrayPush(this.m_placeGang, gang);
    ArrayPush(this.m_placeDistrict, district);
    ArrayPush(this.m_placeX, at.X);
    ArrayPush(this.m_placeY, at.Y);
    ArrayPush(this.m_placeZ, at.Z);
    ArrayPush(this.m_placeAt, now);
  }

  public func ForgetPlace(i: Int32) -> Void {
    if i < 0 || i >= this.PlaceCount() {
      return;
    }
    ArrayErase(this.m_placeKind, i);
    ArrayErase(this.m_placeGang, i);
    ArrayErase(this.m_placeDistrict, i);
    ArrayErase(this.m_placeX, i);
    ArrayErase(this.m_placeY, i);
    ArrayErase(this.m_placeZ, i);
    ArrayErase(this.m_placeAt, i);
  }

  // Places whose district has forgotten them. From the slow tick.
  public func Age(now: Float) -> Void {
    let i = this.PlaceCount() - 1;
    while i >= 0 {
      let keep = CBTemperMemoryDays(this.m_placeDistrict[i]) * CBConfig.SecondsPerDay();
      if now < this.m_placeAt[i] || now - this.m_placeAt[i] > keep {
        this.ForgetPlace(i);
      }
      i -= 1;
    }
  }

  // ---- Cars and guns ----------------------------------------------------------------------------------

  // One more sighting of this car (kind 0) or gun (1): counted up, or added, the least seen of its kind making
  // room. One not seen for KnownForDays starts again from one, the way the street forgets a car V stopped
  // driving. Returns the count.
  public func Note(kind: Int32, record: TweakDBID, now: Float) -> Int32 {
    this.Trim();
    if !TDBID.IsValid(record) {
      return 0;
    }
    let keep = CBConfig.KnownForDays() * CBConfig.SecondsPerDay();
    let i = 0;
    let mine = 0;
    let least = -1;
    while i < ArraySize(this.m_knownKind) {
      if this.m_knownKind[i] == kind {
        if this.m_knownRecord[i] == record {
          let stale = now < this.m_knownAt[i] || now - this.m_knownAt[i] > keep;
          this.m_knownSeen[i] = stale ? 1 : this.m_knownSeen[i] + 1;
          this.m_knownAt[i] = now;
          return this.m_knownSeen[i];
        }
        mine += 1;
        if least < 0 || this.m_knownSeen[i] < this.m_knownSeen[least] {
          least = i;
        }
      }
      i += 1;
    }
    if mine >= CBConfig.KnownCap() && least >= 0 {
      ArrayErase(this.m_knownKind, least);
      ArrayErase(this.m_knownRecord, least);
      ArrayErase(this.m_knownSeen, least);
      ArrayErase(this.m_knownAt, least);
    }
    ArrayPush(this.m_knownKind, kind);
    ArrayPush(this.m_knownRecord, record);
    ArrayPush(this.m_knownSeen, 1);
    ArrayPush(this.m_knownAt, now);
    return 1;
  }

  // How many times it has been seen, while the street still remembers it.
  public func Seen(kind: Int32, record: TweakDBID, now: Float) -> Int32 {
    this.Trim();
    if !TDBID.IsValid(record) {
      return 0;
    }
    let keep = CBConfig.KnownForDays() * CBConfig.SecondsPerDay();
    let i = 0;
    while i < ArraySize(this.m_knownKind) {
      if this.m_knownKind[i] == kind && this.m_knownRecord[i] == record {
        return now < this.m_knownAt[i] || now - this.m_knownAt[i] > keep ? 0 : this.m_knownSeen[i];
      }
      i += 1;
    }
    return 0;
  }

  // The best known of a kind, for the Hub, or none when nothing is known yet.
  public func Known(kind: Int32, now: Float) -> TweakDBID {
    this.Trim();
    let need = kind == 0 ? CBConfig.CarKnownAfter() : CBConfig.GunKnownAfter();
    let keep = CBConfig.KnownForDays() * CBConfig.SecondsPerDay();
    let best = -1;
    let i = 0;
    while i < ArraySize(this.m_knownKind) {
      let fresh = now >= this.m_knownAt[i] && now - this.m_knownAt[i] <= keep;
      if this.m_knownKind[i] == kind && fresh && this.m_knownSeen[i] >= need
         && (best < 0 || this.m_knownSeen[i] > this.m_knownSeen[best]) {
        best = i;
      }
      i += 1;
    }
    return best >= 0 ? this.m_knownRecord[best] : TDBID.None();
  }

  public func SetWatch(district: CName, until: Float, name: String) -> Void {
    this.m_watchDistrict = district;
    this.m_watchUntil = until;
    this.m_watchName = StringToName(name);
  }

  public func WatchDistrict() -> CName {
    return this.m_watchDistrict;
  }

  public func WatchUntil() -> Float {
    return this.m_watchUntil;
  }

  public func WatchName() -> String {
    return NameToString(this.m_watchName);
  }

  public func Clear() -> Void {
    this.m_watchDistrict = n"";
    this.m_watchUntil = 0.0;
    this.m_watchName = n"";
    ArrayClear(this.m_placeKind);
    ArrayClear(this.m_placeGang);
    ArrayClear(this.m_placeDistrict);
    ArrayClear(this.m_placeX);
    ArrayClear(this.m_placeY);
    ArrayClear(this.m_placeZ);
    ArrayClear(this.m_placeAt);
    ArrayClear(this.m_knownKind);
    ArrayClear(this.m_knownRecord);
    ArrayClear(this.m_knownSeen);
    ArrayClear(this.m_knownAt);
    let none: EntityID;
    this.tellerId = none;
    this.tellerFaction = n"";
    this.tellerTick = 0;
    this.givenAwayTick = 0;
    this.givenAway = 0;
    this.wannabeId = none;
    this.wannabeStage = 0;
    this.wannabeTick = 0;
    this.wannabeNext = 0.0;
    this.m_trimmed = true;
  }
}

// ---- The switches ------------------------------------------------------------------------------------

public func CBPlacesRememberOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().placesRemember;
}

public func CBKnownByCarAndGunOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().knownByCarAndGun;
}

// ---- Places, read ------------------------------------------------------------------------------------

// A deed big enough to be remembered where it happened. From the kill handler and the deed paths, which
// already decide what is big.
public func CBRememberPlace(sys: ref<CyberbaneSystem>, game: GameInstance, kind: CName, gang: CName,
                            district: CName, at: Vector4) -> Void {
  if !CBPlacesRememberOn() || !IsDefined(sys) || Equals(district, n"") {
    return;
  }
  let book = CBStreetBook.Get(game);
  if IsDefined(book) {
    book.Remember(kind, gang, district, at, CBGameSeconds(game));
  }
}

// The place remembered nearest to here, within reach, or -1.
public func CBPlaceNear(game: GameInstance, at: Vector4, reach: Float) -> Int32 {
  if !CBPlacesRememberOn() {
    return -1;
  }
  let book = CBStreetBook.Get(game);
  if !IsDefined(book) {
    return -1;
  }
  let best = -1;
  let bestD = reach;
  let i = 0;
  while i < book.PlaceCount() {
    let d = Vector4.Distance(at, book.PlacePos(i));
    if d <= bestD {
      best = i;
      bestD = d;
    }
    i += 1;
  }
  return best;
}

// Is V standing where this gang lost people, and recently enough that they would rather not come back yet?
public func CBGangAvoidsHere(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) || Equals(faction, n"") {
    return false;
  }
  let i = CBPlaceNear(game, player.GetWorldPosition(), CBConfig.PlaceAvoidReach());
  if i < 0 {
    return false;
  }
  let book = CBStreetBook.Get(game);
  let now = CBGameSeconds(game);
  return Equals(book.PlaceGang(i), faction) && now >= book.PlaceAt(i)
      && now - book.PlaceAt(i) < CBConfig.PlaceAvoidHours() * CBConfig.SecondsPerHour();
}

// Is this ganger standing where their gang lost people? Read by their nerve (CBHoldBackOdds).
public func CBGangLostHere(game: GameInstance, faction: CName, at: Vector4) -> Bool {
  if Equals(faction, n"") {
    return false;
  }
  let i = CBPlaceNear(game, at, CBConfig.PlaceReach());
  if i < 0 {
    return false;
  }
  return Equals(CBStreetBook.Get(game).PlaceGang(i), faction);
}

// ---- Cars and guns, read -----------------------------------------------------------------------------

// The car V drives, kept for the session so a fight just after getting out still counts as in it.
public func CBNoteDriving(game: GameInstance) -> Void {
  let book = CBStreetBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(book) || !IsDefined(player) {
    return;
  }
  let car = player.GetMountedVehicle();
  if IsDefined(car) && car.IsAttached() {
    book.lastCar = car.GetEntityID();
    book.lastCarRecord = car.GetRecordID();
  }
}

// The car V is in or standing by right now, or none.
public func CBCarHere(game: GameInstance) -> TweakDBID {
  let book = CBStreetBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(book) || !IsDefined(player) {
    return TDBID.None();
  }
  let mounted = player.GetMountedVehicle();
  if IsDefined(mounted) && mounted.IsAttached() {
    return mounted.GetRecordID();
  }
  if !EntityID.IsDefined(book.lastCar) {
    return TDBID.None();
  }
  let car = GameInstance.FindEntityByID(game, book.lastCar) as VehicleObject;
  if IsDefined(car) && car.IsAttached()
     && Vector4.Distance(car.GetWorldPosition(), player.GetWorldPosition()) <= CBConfig.CarByReach() {
    return book.lastCarRecord;
  }
  return TDBID.None();
}

// The gun in V's hands, or none. Only a weapon the game calls a ranged one counts: a blade is not a gun the
// street would know.
public func CBGunHere(game: GameInstance) -> TweakDBID {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return TDBID.None();
  }
  let weapon = GameObject.GetActiveWeapon(player);
  if !IsDefined(weapon) || !weapon.IsRanged() {
    return TDBID.None();
  }
  return ItemID.GetTDBID(weapon.GetItemID());
}

// Somebody saw V fight with this car and this gun. From the kill handler, a witnessed kill only.
public func CBNoteKnownBy(game: GameInstance, info: ref<CBKillInfo>) -> Void {
  if !CBKnownByCarAndGunOn() || !IsDefined(info) || !info.witnessed || Equals(info.faction, n"") {
    return;
  }
  let book = CBStreetBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  let now = CBGameSeconds(game);
  let car = CBCarHere(game);
  let newFight = book.lastCarNoteAt <= 0.0 || now < book.lastCarNoteAt || now - book.lastCarNoteAt >= CBConfig.CarNoteGapSeconds();
  if TDBID.IsValid(car) && newFight {
    book.lastCarNoteAt = now;
    if book.Note(0, car, now) == CBConfig.CarKnownAfter() && CBToastsOn() {
      CBHearsayFromStreet(game, "People have started noticing what you drive. Turn up in it again and a mask won't help.", n"");
    }
  }
  if info.mFirearm && TDBID.IsValid(info.weaponRecord)
     && book.Note(1, info.weaponRecord, now) == CBConfig.GunKnownAfter() && CBToastsOn() {
    CBHearsayFromStreet(game, "That gun of yours has a reputation now. Use it with your face covered and they'll still know it's you.", n"");
  }
}

// V given away by car (1) or gun (2), or not (0). Worked out once a tick and kept, because CBRecognizes asks
// it for everybody the Director looks at.
public func CBVGivenAway(sys: ref<CyberbaneSystem>, game: GameInstance) -> Int32 {
  if !CBKnownByCarAndGunOn() || !IsDefined(sys) {
    return 0;
  }
  let book = CBStreetBook.Get(game);
  if !IsDefined(book) {
    return 0;
  }
  let tick = sys.GetTickCount();
  if book.givenAwayTick == tick {
    return book.givenAway;
  }
  book.givenAwayTick = tick;
  book.givenAway = 0;
  let now = CBGameSeconds(game);
  if book.Seen(0, CBCarHere(game), now) >= CBConfig.CarKnownAfter() {
    book.givenAway = 1;
  } else {
    if book.Seen(1, CBGunHere(game), now) >= CBConfig.GunKnownAfter() {
      book.givenAway = 2;
    }
  }
  return book.givenAway;
}

// What the street knows V by, for the Hub's gang page. "" when nothing.
public func CBKnownByLine(game: GameInstance) -> String {
  if !CBKnownByCarAndGunOn() {
    return "";
  }
  let book = CBStreetBook.Get(game);
  if !IsDefined(book) {
    return "";
  }
  let now = CBGameSeconds(game);
  let car = book.Known(0, now);
  let gun = book.Known(1, now);
  let carName = CBVehicleName(car);
  let gunName = CBItemName(gun);
  if StrLen(carName) > 0 && StrLen(gunName) > 0 {
    return s"They know your \(carName) and your \(gunName). A mask won't hide you with either.";
  }
  if StrLen(carName) > 0 {
    return s"They know your \(carName). A mask won't hide you in it.";
  }
  if StrLen(gunName) > 0 {
    return s"They know your \(gunName). A mask won't hide you with it in your hands.";
  }
  if TDBID.IsValid(car) {
    return "They know the car you drive. A mask won't hide you in it.";
  }
  if TDBID.IsValid(gun) {
    return "They know your gun. A mask won't hide you with it in your hands.";
  }
  return "";
}

// What the game calls a car or an item, from its record, the way the game's own screens do (the scanner's
// vehicle line, the backpack's item names). "" when the record has no name.
public func CBVehicleName(id: TweakDBID) -> String {
  if !TDBID.IsValid(id) {
    return "";
  }
  let rec = TweakDBInterface.GetVehicleRecord(id);
  return IsDefined(rec) ? GetLocalizedText(LocKeyToString(rec.DisplayName())) : "";
}

public func CBItemName(id: TweakDBID) -> String {
  if !TDBID.IsValid(id) {
    return "";
  }
  let rec = TweakDBInterface.GetItemRecord(id);
  return IsDefined(rec) ? GetLocalizedItemNameByCName(rec.DisplayName()) : "";
}
