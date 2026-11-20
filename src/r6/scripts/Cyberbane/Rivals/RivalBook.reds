// Cyberbane - The Rival book (2.4.4)
//
// What the Rivals' lives keep that a Rival's own record has no room for, kept per Rival id in a save book of its own
// (a new class changes nothing already saved, and starts empty on a save that has never had it): a bond with another
// Rival [58], how a Rival's story ended and when [56] [61], a trophy taken [60], a return from the dead [56], a
// humiliation [55], the chrome the street has already heard about [U9], the place that matters to them [62], and one
// feud V set going between two Rivals [57]. Parallel lists, cut to the shortest on the first read after a load,
// bounds-checked on every read; cleared with the Rival (CBRivalBookForget) and on Start over.

public func CBBondNone() -> Int32 = 0
public func CBBondMentor() -> Int32 = 1
public func CBBondProtege() -> Int32 = 2
public func CBBondLover() -> Int32 = 3
public func CBBondPartner() -> Int32 = 4

public func CBEndingNone() -> Int32 = 0
public func CBEndingByV() -> Int32 = 1
public func CBEndingFinisher() -> Int32 = 2
public func CBEndingFlaw() -> Int32 = 3
public func CBEndingNotByV() -> Int32 = 4
public func CBEndingRetired() -> Int32 = 5

public func CBRivalFlagTrophy() -> Int32 = 0
public func CBRivalFlagReturned() -> Int32 = 1
public func CBRivalFlagEndedUp() -> Int32 = 2
public func CBRivalFlagHumiliated() -> Int32 = 3
public func CBRivalFlagBondSettled() -> Int32 = 4
public func CBRivalFlagPlace() -> Int32 = 5
public func CBRivalFlagBondTried() -> Int32 = 6

public class CBRivalBook extends ScriptableSystem {
  private persistent let m_id: array<Int32>;
  private persistent let m_bondWith: array<Int32>;
  private persistent let m_bondKind: array<Int32>;
  private persistent let m_ending: array<Int32>;
  private persistent let m_endedAt: array<Float>;
  private persistent let m_flags: array<Int32>;
  private persistent let m_chrome: array<Int32>;      // implants the street has heard about (CBRivalImplants bits)
  private persistent let m_placeX: array<Float>;      // where it happened: where V first beat them, or where they fell
  private persistent let m_placeY: array<Float>;
  private persistent let m_placeZ: array<Float>;
  private persistent let m_placeDistrict: array<CName>;
  private persistent let m_feudA: Int32;              // a feud V set going: A goes after B, settled by m_feudAt
  private persistent let m_feudB: Int32;
  private persistent let m_feudAt: Float;
  private let m_trimmed: Bool;

  // Session only: the facedown at the announcement ([53] [54], Rivals/RivalMoments.reds).
  public let fdRival: Int32;
  public let fdBody: EntityID;
  public let fdState: Int32;        // 0 none, 1 open, 2 one-on-one
  public let fdTick: Int32;
  public let fdDoneKey: Int32;      // rival id * 64 + encounters, so once an encounter
  public let fdEscorts: array<EntityID>;
  public let tauntTick: Int32;
  public let fdHinted: Bool;        // the hint about talking to them has been shown this session
  // A lookout at a Rival's place who has seen V (Rivals/Whereabouts.reds, [U10], 2.5.0): how long V has been in view,
  // and the one who ran to warn them, since when.
  public let lairSeen: Int32;
  public let lairWarnBody: EntityID;
  public let lairWarnTick: Int32;

  public func ResetLairAlarm() -> Void {
    let none: EntityID;
    this.lairSeen = 0;
    this.lairWarnBody = none;
    this.lairWarnTick = 0;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_trimmed = false;
    this.fdRival = 0;
    this.fdState = 0;
    ArrayClear(this.fdEscorts);
    this.ResetLairAlarm();
    // Stamped in the session's tick count, which starts again with a load: a stamp from before it would read as the
    // future and hold the next taunt or facedown back for as long as the last session had run.
    let none: EntityID;
    this.fdBody = none;
    this.fdTick = 0;
    this.tauntTick = 0;
    this.fdHinted = false;
  }

  public static func Get(game: GameInstance) -> ref<CBRivalBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBRivalBook") as CBRivalBook;
  }

  private func Trim() -> Void {
    if this.m_trimmed {
      return;
    }
    this.m_trimmed = true;
    let n = Min(Min(Min(ArraySize(this.m_id), ArraySize(this.m_bondWith)), Min(ArraySize(this.m_bondKind), ArraySize(this.m_ending))),
                Min(Min(ArraySize(this.m_endedAt), ArraySize(this.m_flags)), Min(ArraySize(this.m_chrome), ArraySize(this.m_placeX))));
    n = Min(n, Min(Min(ArraySize(this.m_placeY), ArraySize(this.m_placeZ)), ArraySize(this.m_placeDistrict)));
    ArrayResize(this.m_id, n);
    ArrayResize(this.m_bondWith, n);
    ArrayResize(this.m_bondKind, n);
    ArrayResize(this.m_ending, n);
    ArrayResize(this.m_endedAt, n);
    ArrayResize(this.m_flags, n);
    ArrayResize(this.m_chrome, n);
    ArrayResize(this.m_placeX, n);
    ArrayResize(this.m_placeY, n);
    ArrayResize(this.m_placeZ, n);
    ArrayResize(this.m_placeDistrict, n);
  }

  private func Find(id: Int32, add: Bool) -> Int32 {
    this.Trim();
    let i = 0;
    while i < ArraySize(this.m_id) {
      if this.m_id[i] == id {
        return i;
      }
      i += 1;
    }
    if !add || id <= 0 {
      return -1;
    }
    ArrayPush(this.m_id, id);
    ArrayPush(this.m_bondWith, 0);
    ArrayPush(this.m_bondKind, 0);
    ArrayPush(this.m_ending, 0);
    ArrayPush(this.m_endedAt, 0.0);
    ArrayPush(this.m_flags, 0);
    ArrayPush(this.m_chrome, 0);
    ArrayPush(this.m_placeX, 0.0);
    ArrayPush(this.m_placeY, 0.0);
    ArrayPush(this.m_placeZ, 0.0);
    ArrayPush(this.m_placeDistrict, n"");
    return ArraySize(this.m_id) - 1;
  }

  public func BondWith(id: Int32) -> Int32 {
    let i = this.Find(id, false);
    return i >= 0 ? this.m_bondWith[i] : 0;
  }

  public func BondKind(id: Int32) -> Int32 {
    let i = this.Find(id, false);
    return i >= 0 ? this.m_bondKind[i] : 0;
  }

  // Both sides at once: a mentor's other end is a protégé; the rest are the same both ways.
  public func SetBond(a: Int32, b: Int32, kind: Int32) -> Void {
    let i = this.Find(a, true);
    let j = this.Find(b, true);
    if i < 0 || j < 0 {
      return;
    }
    this.m_bondWith[i] = b;
    this.m_bondKind[i] = kind;
    this.m_bondWith[j] = a;
    this.m_bondKind[j] = kind == CBBondMentor() ? CBBondProtege() : (kind == CBBondProtege() ? CBBondMentor() : kind);
  }

  public func Ending(id: Int32) -> Int32 {
    let i = this.Find(id, false);
    return i >= 0 ? this.m_ending[i] : 0;
  }

  public func EndedAt(id: Int32) -> Float {
    let i = this.Find(id, false);
    return i >= 0 ? this.m_endedAt[i] : 0.0;
  }

  public func SetEnding(id: Int32, how: Int32, at: Float) -> Void {
    let i = this.Find(id, true);
    if i >= 0 {
      this.m_ending[i] = how;
      this.m_endedAt[i] = at;
    }
  }

  public func HasFlag(id: Int32, bit: Int32) -> Bool {
    let i = this.Find(id, false);
    return i >= 0 && CBMaskHas(this.m_flags[i], bit);
  }

  public func SetFlag(id: Int32, bit: Int32) -> Void {
    let i = this.Find(id, true);
    if i >= 0 {
      this.m_flags[i] = CBMaskSet(this.m_flags[i], bit);
    }
  }

  public func Chrome(id: Int32) -> Int32 {
    let i = this.Find(id, false);
    return i >= 0 ? this.m_chrome[i] : 0;
  }

  public func SetChrome(id: Int32, mask: Int32) -> Void {
    let i = this.Find(id, true);
    if i >= 0 {
      this.m_chrome[i] = mask;
    }
  }

  public func HasPlace(id: Int32) -> Bool {
    return this.HasFlag(id, CBRivalFlagPlace());
  }

  public func Place(id: Int32) -> Vector4 {
    let i = this.Find(id, false);
    return i >= 0 ? new Vector4(this.m_placeX[i], this.m_placeY[i], this.m_placeZ[i], 1.0) : new Vector4(0.0, 0.0, 0.0, 1.0);
  }

  public func PlaceDistrict(id: Int32) -> CName {
    let i = this.Find(id, false);
    return i >= 0 ? this.m_placeDistrict[i] : n"";
  }

  // The first one that matters is kept: where V first beat them, or where they fell.
  public func KeepPlace(id: Int32, at: Vector4, district: CName) -> Void {
    let i = this.Find(id, true);
    if i < 0 || CBMaskHas(this.m_flags[i], CBRivalFlagPlace()) {
      return;
    }
    this.m_placeX[i] = at.X;
    this.m_placeY[i] = at.Y;
    this.m_placeZ[i] = at.Z;
    this.m_placeDistrict[i] = district;
    this.m_flags[i] = CBMaskSet(this.m_flags[i], CBRivalFlagPlace());
  }

  public func FeudA() -> Int32 { return this.m_feudA; }
  public func FeudB() -> Int32 { return this.m_feudB; }
  public func FeudAt() -> Float { return this.m_feudAt; }
  public func SetFeud(a: Int32, b: Int32, at: Float) -> Void {
    this.m_feudA = a;
    this.m_feudB = b;
    this.m_feudAt = at;
  }

  // A Rival forgotten: their row goes, and anybody bonded to them is free again.
  public func Forget(id: Int32) -> Void {
    let i = this.Find(id, false);
    if i >= 0 {
      ArrayErase(this.m_id, i);
      ArrayErase(this.m_bondWith, i);
      ArrayErase(this.m_bondKind, i);
      ArrayErase(this.m_ending, i);
      ArrayErase(this.m_endedAt, i);
      ArrayErase(this.m_flags, i);
      ArrayErase(this.m_chrome, i);
      ArrayErase(this.m_placeX, i);
      ArrayErase(this.m_placeY, i);
      ArrayErase(this.m_placeZ, i);
      ArrayErase(this.m_placeDistrict, i);
    }
    let k = 0;
    while k < ArraySize(this.m_bondWith) {
      if this.m_bondWith[k] == id {
        this.m_bondWith[k] = 0;
        this.m_bondKind[k] = 0;
      }
      k += 1;
    }
    if this.m_feudA == id || this.m_feudB == id {
      this.SetFeud(0, 0, 0.0);
    }
  }

  public func Clear() -> Void {
    let none: array<Int32>;
    this.ClearExcept(none);
  }

  // Everybody forgotten but `keep` (Rivals/RivalSystem.reds, CBPurgeRivals): one of V's crew who was a Rival keeps
  // their row, and any bond they had to somebody forgotten is let go as Forget does it (2.5.0).
  public func ClearExcept(keep: array<Int32>) -> Void {
    if ArraySize(keep) == 0 {
      ArrayClear(this.m_id);
      ArrayClear(this.m_bondWith);
      ArrayClear(this.m_bondKind);
      ArrayClear(this.m_ending);
      ArrayClear(this.m_endedAt);
      ArrayClear(this.m_flags);
      ArrayClear(this.m_chrome);
      ArrayClear(this.m_placeX);
      ArrayClear(this.m_placeY);
      ArrayClear(this.m_placeZ);
      ArrayClear(this.m_placeDistrict);
    } else {
      let ids = this.m_id;
      for id in ids {
        if !ArrayContains(keep, id) {
          this.Forget(id);
        }
      }
    }
    this.SetFeud(0, 0, 0.0);
    this.m_trimmed = false;
    this.fdRival = 0;
    this.fdState = 0;
    ArrayClear(this.fdEscorts);
    this.ResetLairAlarm();
  }
}

public func CBRivalBookForget(game: GameInstance, id: Int32) -> Void {
  let book = CBRivalBook.Get(game);
  if IsDefined(book) {
    book.Forget(id);
  }
}
