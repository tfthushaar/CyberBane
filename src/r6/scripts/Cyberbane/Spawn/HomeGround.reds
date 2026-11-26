// Cyberbane - Home ground, and a night at home
//
// Nobody is placed in or sent into the building around V's apartments, lobby and car park included, and a night in V's
// own bed buys some hours of quiet.

public func CBHomeGroundMode() -> ECBHomeGround {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().homeGround : ECBHomeGround.Quiet;
}

public func CBRestTogether() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().restTogether;
}

public func CBSleepPeaceHours() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? Max(0, rt.GetSettings().sleepPeaceHours) : 6;
}

// Which of V's apartments a district of the game's is, by its enum name: 0 for none.
public func CBHomeKindOf(districtName: String) -> Int32 {
  let n = StrLower(districtName);
  if Equals(n, "littlechina_vapartment") { return 1; }
  if Equals(n, "japantown_apartment") { return 2; }
  if Equals(n, "northside_apartment") { return 3; }
  if Equals(n, "glen_apartment") { return 4; }
  if Equals(n, "corpoplaza_apartment") { return 5; }
  return 0;
}

// The district of the game's V is standing in, by its enum name, unfolded: "" when the game has not said. The game's
// name for the part of a district V stands in ("Rocky Ridge"), in the player's language; "" when none.
public func CBSubDistrictLabel(game: GameInstance) -> String {
  let prev = CBGetSystem(game, n"PreventionSystem") as PreventionSystem;
  let district = IsDefined(prev) ? prev.GetCurrentDistrict() : null;
  let rec = IsDefined(district) ? district.GetDistrictRecord() : null;
  return IsDefined(rec) ? GetLocalizedText(rec.LocalizedName()) : "";
}

public func CBSubDistrictName(game: GameInstance) -> String {
  let prev = CBGetSystem(game, n"PreventionSystem") as PreventionSystem;
  if !IsDefined(prev) {
    return "";
  }
  let district = prev.GetCurrentDistrict();
  if !IsDefined(district) {
    return "";
  }
  let rec = district.GetDistrictRecord();
  return IsDefined(rec) ? rec.EnumName() : "";
}

public class CBHomeBook extends ScriptableSystem {
  // Parallel lists, counted by the shortest (Count), so a save in which one came back short reads short.
  private persistent let m_kind: array<Int32>;     // CBHomeKindOf; 0 for a home known only from its bed
  private persistent let m_x: array<Float>;
  private persistent let m_y: array<Float>;
  private persistent let m_z: array<Float>;
  // The crew's posts: the door into the building and the car park. All zero is not learned yet.
  private persistent let m_doorX: array<Float>;
  private persistent let m_doorY: array<Float>;
  private persistent let m_doorZ: array<Float>;
  private persistent let m_parkX: array<Float>;
  private persistent let m_parkY: array<Float>;
  private persistent let m_parkZ: array<Float>;
  private persistent let m_peaceUntil: Float;       // game seconds: quiet after a night at home until then

  // Session only.
  private let m_here: Int32;          // the home V is on the ground of, one up (0 for none)
  private let m_inFlat: Int32;        // the home whose flat V was inside at the last read, one up
  private let m_inCar: Bool;
  private let m_restedRead: Bool;     // the first read of a session only remembers
  private let m_rested: Bool;
  // V just stepped out of a flat: which home, one up (0 for none), where, and on which tick (DoorWatch).
  private let m_stepHome: Int32;
  private let m_stepFrom: Vector4;
  private let m_stepTick: Int32;
  // A flat forgotten while V stood in it, by kind: not learned again until V has left it.
  private let m_forgotKind: Int32;

  public static func Get(game: GameInstance) -> ref<CBHomeBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBHomeBook") as CBHomeBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_here = 0;
    this.m_inFlat = 0;
    this.m_inCar = false;
    this.m_restedRead = false;
    this.m_rested = false;
    this.m_stepHome = 0;
    this.m_forgotKind = 0;
  }

  public func Count() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_kind), ArraySize(this.m_x)), Min(ArraySize(this.m_y), ArraySize(this.m_z))),
               Min(Min(Min(ArraySize(this.m_doorX), ArraySize(this.m_doorY)), ArraySize(this.m_doorZ)),
                   Min(Min(ArraySize(this.m_parkX), ArraySize(this.m_parkY)), ArraySize(this.m_parkZ))));
  }

  public func At(i: Int32) -> Vector4 {
    return new Vector4(this.m_x[i], this.m_y[i], this.m_z[i], 1.0);
  }

  public func HereIndex() -> Int32 {
    return this.m_here - 1;
  }

  public func PeaceUntil() -> Float {
    return this.m_peaceUntil;
  }

  // The home whose building this point is in, or -1.
  public func HomeAt(at: Vector4) -> Int32 {
    let r = CBConfig.HomeRadius();
    let n = this.Count();
    let i = 0;
    while i < n {
      let dx = at.X - this.m_x[i];
      let dy = at.Y - this.m_y[i];
      if dx * dx + dy * dy <= r * r {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  // The home of this kind, or -1. Kind 0 is never matched: those are told apart by where they are.
  public func HomeOfKind(kind: Int32) -> Int32 {
    if kind <= 0 {
      return -1;
    }
    let n = this.Count();
    let i = 0;
    while i < n {
      if this.m_kind[i] == kind {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  // A home is kept, or the bed's home is named once its flat's district is known. -1 when the book is full.
  public func Learn(kind: Int32, at: Vector4) -> Int32 {
    let n = this.Count();
    // The same building, already known from its bed: give it its name.
    let near = -1;
    let i = 0;
    while i < n {
      if Vector4.Distance(at, this.At(i)) <= CBConfig.HomeMergeDistance() {
        near = i;
      }
      i += 1;
    }
    if near >= 0 {
      if kind > 0 && this.m_kind[near] == 0 {
        this.m_kind[near] = kind;
      }
      return near;
    }
    if n >= CBConfig.HomeMax() {
      return -1;
    }
    // Trimmed to the shortest first, so the new home lines up in every list.
    this.TrimTo(n);
    ArrayPush(this.m_kind, kind);
    ArrayPush(this.m_x, at.X);
    ArrayPush(this.m_y, at.Y);
    ArrayPush(this.m_z, at.Z);
    ArrayPush(this.m_doorX, 0.0);
    ArrayPush(this.m_doorY, 0.0);
    ArrayPush(this.m_doorZ, 0.0);
    ArrayPush(this.m_parkX, 0.0);
    ArrayPush(this.m_parkY, 0.0);
    ArrayPush(this.m_parkZ, 0.0);
    return n;
  }

  private func TrimTo(n: Int32) -> Void {
    ArrayResize(this.m_kind, n);
    ArrayResize(this.m_x, n);
    ArrayResize(this.m_y, n);
    ArrayResize(this.m_z, n);
    ArrayResize(this.m_doorX, n);
    ArrayResize(this.m_doorY, n);
    ArrayResize(this.m_doorZ, n);
    ArrayResize(this.m_parkX, n);
    ArrayResize(this.m_parkY, n);
    ArrayResize(this.m_parkZ, n);
  }

  // A home out of the book, from every list. The watch posted there goes on its next tick, as when V walks off home ground.
  private func Forget(i: Int32) -> Void {
    let n = this.Count();
    if i < 0 || i >= n {
      return;
    }
    this.TrimTo(n);
    ArrayErase(this.m_kind, i);
    ArrayErase(this.m_x, i);
    ArrayErase(this.m_y, i);
    ArrayErase(this.m_z, i);
    ArrayErase(this.m_doorX, i);
    ArrayErase(this.m_doorY, i);
    ArrayErase(this.m_doorZ, i);
    ArrayErase(this.m_parkX, i);
    ArrayErase(this.m_parkY, i);
    ArrayErase(this.m_parkZ, i);
    this.m_here = 0;
    this.m_inFlat = 0;
    this.m_stepHome = 0;
  }

  // Make where I stand a home (Mod Settings): a house the street can't tell is V's, like one from another mod.
  public func MarkHere(game: GameInstance) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let at = player.GetWorldPosition();
    if this.HomeAt(at) >= 0 {
      CBMenuNote(game, CBT(n"Cyberbane-Home-AlreadyHome"), 5.0);
      return;
    }
    let kind = CBHomeKindOf(CBSubDistrictName(game));
    let made = this.Learn(kind, at);
    if made < 0 {
      CBMenuNote(game, CBT(n"Cyberbane-Home-BookFull"), 6.0);
      return;
    }
    this.m_forgotKind = 0;
    this.m_here = made + 1;
    CBLog.Info(n"Spawn", s"A home marked where V stands (kind \(kind)): \(this.Count()) known.");
    CBMenuNote(game, CBT(n"Cyberbane-Home-Marked"), 6.0);
  }

  // Forget the home I stand in (Mod Settings): every home whose ground V is on, so V is off home ground after it.
  public func ForgetHere(game: GameInstance) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let at = player.GetWorldPosition();
    let flat = CBHomeKindOf(CBSubDistrictName(game));
    let gone = 0;
    let i = this.HomeAt(at);
    while i >= 0 && gone < CBConfig.HomeMax() {
      if flat > 0 && this.m_kind[i] == flat {
        this.m_forgotKind = flat;
      }
      this.Forget(i);
      gone += 1;
      i = this.HomeAt(at);
    }
    if gone == 0 {
      CBMenuNote(game, CBT(n"Cyberbane-Home-NotAHome"), 5.0);
      return;
    }
    CBLog.Info(n"Spawn", s"V forgot the home they stand in: \(this.Count()) known.");
    CBMenuNote(game, CBT(n"Cyberbane-Home-Forgotten"), 6.0);
  }

  // The crew's posts at a home (Reactions/CrewHome.reds); all zero is not learned yet.
  public func DoorAt(i: Int32) -> Vector4 {
    return i >= 0 && i < this.Count() ? new Vector4(this.m_doorX[i], this.m_doorY[i], this.m_doorZ[i], 1.0)
                                      : new Vector4(0.0, 0.0, 0.0, 0.0);
  }

  public func ParkAt(i: Int32) -> Vector4 {
    return i >= 0 && i < this.Count() ? new Vector4(this.m_parkX[i], this.m_parkY[i], this.m_parkZ[i], 1.0)
                                      : new Vector4(0.0, 0.0, 0.0, 0.0);
  }

  public func SetDoor(i: Int32, at: Vector4) -> Void {
    if i >= 0 && i < this.Count() {
      this.m_doorX[i] = at.X;
      this.m_doorY[i] = at.Y;
      this.m_doorZ[i] = at.Z;
    }
  }

  public func SetPark(i: Int32, at: Vector4) -> Void {
    if i >= 0 && i < this.Count() {
      this.m_parkX[i] = at.X;
      this.m_parkY[i] = at.Y;
      this.m_parkZ[i] = at.Z;
    }
  }

  // Once a tick (CyberbaneSystem), from the main tick's settled part.
  public func Tick(sys: ref<CyberbaneSystem>, game: GameInstance, heavyStreaming: Bool) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let at = player.GetWorldPosition();
    this.m_here = this.HomeAt(at) + 1;
    let tick = sys.GetTickCount();
    // The flat V is in: every ten ticks, every other one while V is inside a flat, so the spot V steps out of it is close
    // to its door.
    if !heavyStreaming && (tick % 10 == 4 || (this.m_inFlat > 0 && tick % 2 == 0)) {
      let kind = CBHomeKindOf(CBSubDistrictName(game));
      if kind != this.m_forgotKind {
        this.m_forgotKind = 0;
      }
      if kind > 0 && kind != this.m_forgotKind {
        let known = this.HomeOfKind(kind);
        if known < 0 {
          known = this.Learn(kind, at);
          if known >= 0 {
            this.Noticed(game, kind);
          }
        }
        this.m_inFlat = known + 1;
      } else {
        if this.m_inFlat > 0 {
          let was = this.m_inFlat - 1;
          // Out of the flat and still in its building: the door is looked for from here (DoorWatch).
          if was < this.Count() && this.HomeAt(at) == was {
            this.m_stepHome = was + 1;
            this.m_stepFrom = at;
            this.m_stepTick = tick;
          }
        }
        this.m_inFlat = 0;
      }
    }
    if this.m_stepHome > 0 {
      this.DoorWatch(game, at, tick, IsDefined(player.GetMountedVehicle()));
    }
    // Where V leaves the car at home.
    let inCar = IsDefined(player.GetMountedVehicle());
    if this.m_inCar && !inCar && this.m_here > 0 {
      // On the navmesh beside the car when there is some, where the watch can stand.
      let parked: Vector4;
      this.SetPark(this.m_here - 1, CBNavPointUnder(game, at, parked) ? parked : at);
    }
    this.m_inCar = inCar;
    // A night in V's own bed.
    if tick % 5 == 1 {
      let ses = GameInstance.GetStatusEffectSystem(game);
      let rested = IsDefined(ses) && ses.HasStatusEffect(player.GetEntityID(), t"HousingStatusEffect.Rested");
      if this.m_restedRead && rested && !this.m_rested {
        this.Slept(sys, game, at);
      }
      this.m_rested = rested;
      this.m_restedRead = true;
    }
  }

  // The door, where the crew stand watch: a spot V's own feet stood on, the way the story puts a visitor at a spot made
  // for them.
  private func DoorWatch(game: GameInstance, at: Vector4, tick: Int32, inCar: Bool) -> Void {
    let home = this.m_stepHome - 1;
    if this.m_inFlat > 0 || inCar || home >= this.Count() || tick - this.m_stepTick > CBConfig.HomeDoorWatchTicks()
       || this.HomeAt(at) != home {
      this.m_stepHome = 0;
      return;
    }
    let dx = at.X - this.m_stepFrom.X;
    let dy = at.Y - this.m_stepFrom.Y;
    let step = CBConfig.HomeDoorStepOut();
    if dx * dx + dy * dy < step * step {
      return;
    }
    let standing: Vector4;
    if CBNavPointUnder(game, at, standing) {
      this.SetDoor(home, standing);
      this.m_stepHome = 0;
      CBLog.Info(n"Spawn", s"A home's door learned where V walked out (home \(home + 1)).");
    }
  }

  private func Slept(sys: ref<CyberbaneSystem>, game: GameInstance, at: Vector4) -> Void {
    if this.HomeAt(at) < 0 {
      let made = this.Learn(0, at);
      if made >= 0 {
        this.Noticed(game, 0);
        this.m_here = made + 1;
      }
    }
    let hours = CBSleepPeaceHours();
    if hours <= 0 {
      return;
    }
    this.m_peaceUntil = CBGameSeconds(game) + Cast<Float>(hours) * CBConfig.SecondsPerHour();
    CBLog.Info(n"Spawn", s"V slept at home: nobody new is sent for \(hours) game hours.");
    CBSystemNote(game, CBTf(n"Cyberbane-Home-Rested", [IntToString(hours)]), 6.0);
  }

  private func Noticed(game: GameInstance, kind: Int32) -> Void {
    CBLog.Info(n"Spawn", s"A home learned (kind \(kind)): \(this.Count()) known.");
    if !Equals(CBHomeGroundMode(), ECBHomeGround.Open) {
      CBSystemNote(game, CBT(n"Cyberbane-Home-Learned"), 6.0);
    }
  }
}

// Is V standing on home ground? The setting aside.
public func CBOnHomeGround(game: GameInstance) -> Bool {
  let book = CBHomeBook.Get(game);
  return IsDefined(book) && book.HereIndex() >= 0;
}

// Home ground keeps the street's own life, and anybody Cyberbane would start something with, off it: either Quiet setting.
public func CBHomeKeepsOut(sys: ref<CyberbaneSystem>) -> Bool {
  return IsDefined(sys) && !Equals(CBHomeGroundMode(), ECBHomeGround.Open) && CBOnHomeGround(sys.GetGameInstance());
}

// Nobody at all is picked or placed there: Quiet.
public func CBHomeHoldsAll(sys: ref<CyberbaneSystem>) -> Bool {
  return IsDefined(sys) && Equals(CBHomeGroundMode(), ECBHomeGround.Quiet) && CBOnHomeGround(sys.GetGameInstance());
}

// Does home ground hold this gang's people back? Everybody under Quiet; under Quiet except a vendetta, everybody but a gang
// at Vendetta.
public func CBHomeHolds(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  if !IsDefined(sys) || !CBOnHomeGround(sys.GetGameInstance()) {
    return false;
  }
  let mode = CBHomeGroundMode();
  if Equals(mode, ECBHomeGround.Open) {
    return false;
  }
  if Equals(mode, ECBHomeGround.Quiet) {
    return true;
  }
  // A Rival of no gang is a Rival, held like the rest.
  if Equals(faction, n"") {
    return true;
  }
  let score = sys.GetScore();
  return !IsDefined(score) || !Equals(score.GetPosture(faction), ECBPosture.Vendetta);
}

// Is this point inside home ground, where nobody of Cyberbane's against V is put (Quiet only)?
public func CBHomePointQuiet(game: GameInstance, at: Vector4) -> Bool {
  if !Equals(CBHomeGroundMode(), ECBHomeGround.Quiet) {
    return false;
  }
  let book = CBHomeBook.Get(game);
  return IsDefined(book) && book.HomeAt(at) >= 0;
}

// Is this point inside home ground under either Quiet setting? For the places the street remembers and names (a Rival's
// hideout, a gathering's place): never V's own building.
public func CBHomePointKept(game: GameInstance, at: Vector4) -> Bool {
  if Equals(CBHomeGroundMode(), ECBHomeGround.Open) {
    return false;
  }
  let book = CBHomeBook.Get(game);
  return IsDefined(book) && book.HomeAt(at) >= 0;
}

// The quiet a night at home bought: true until it runs out.
public func CBSleepPeace(game: GameInstance) -> Bool {
  let book = CBHomeBook.Get(game);
  return IsDefined(book) && CBSleepPeaceHours() > 0 && CBGameSeconds(game) < book.PeaceUntil();
}
