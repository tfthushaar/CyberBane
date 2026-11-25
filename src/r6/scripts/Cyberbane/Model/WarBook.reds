// Cyberbane - The war book
//
// What the turf war runs on: each gang's war chest and manpower, a peace haggled down, a truce between two gangs
// against V, and V's side of it: the gang V backs, the districts that are V's own, a lie V told to set two gangs on
// each other, a protection demand, a favour owed for peace.

public class CBWarBook extends ScriptableSystem {
  // Per gang.
  private persistent let m_gang: array<CName>;
  private persistent let m_chest: array<Float>;        // eddies
  private persistent let m_men: array<Float>;          // manpower, 0..100
  private persistent let m_peaceCut: array<Float>;     // a share off their price, haggled by text, 0..0.3
  private persistent let m_haggledAt: array<Float>;
  private persistent let m_truceWith: array<CName>;    // a gang they have stopped fighting, to come for V together
  private persistent let m_truceUntil: array<Float>;
  // V's side of the war.
  private persistent let m_backed: CName;
  private persistent let m_backedSince: Float;
  private persistent let m_cutPaidAt: Float;
  private persistent let m_ownMask: Int32;             // districts that are V's own (CBDistrictIndex bits)
  private persistent let m_ownPaidAt: Float;
  private persistent let m_inciteA: CName;
  private persistent let m_inciteB: CName;
  private persistent let m_inciteUntil: Float;
  private persistent let m_protectDue: Float;          // the Claws want paying by then (0: nothing asked)
  private persistent let m_protectAmount: Int32;
  private persistent let m_protectAskedAt: Float;
  private persistent let m_protectSeen: Float;         // game seconds V has spent in Westbrook since the last demand
  private persistent let m_favourFor: CName;           // a gang that will call it off for a favour, and until when
  private persistent let m_favourUntil: Float;
  // For later releases: open season and one of theirs.
  private persistent let m_openGang: CName;
  private persistent let m_openUntil: Float;
  private persistent let m_oneOfTheirs: CName;

  private let m_trimmed: Bool;

  // Session only: rival gangers clashing on a contested street ([N1], Spawn/Clashes.reds). The two gangs at war where V
  // is, worked out now and then; a few of each the Director's walk has seen lately; and the clash itself.
  public let clashA: CName;
  public let clashB: CName;
  public let clashPairTick: Int32;
  public let candA: array<EntityID>;
  public let candB: array<EntityID>;
  public let fightA: array<EntityID>;      // side A, and side B pair by pair: fightA[k] against fightB[k]
  public let fightB: array<EntityID>;
  public let fightWas: array<Int32>;       // what fightA[k] thought of fightB[k] before (EAIAttitude), to put back
  public let fightGangA: CName;
  public let fightGangB: CName;
  public let fightAt: Vector4;
  public let fightTick: Int32;
  public let clashNextTick: Int32;
  public let lastClashA: CName;            // the last one, for the Hub's web of gangs ([H1])
  public let lastClashB: CName;
  public let lastClashAt: Float;
  // Session only: talk and allies (Reactions/Allies.reds).
  public let crewIds: array<EntityID>;
  public let crewGang: CName;
  public let crewUntil: Float;
  public let crewAway: Int32;
  public let crewLeaving: Bool;
  public let crewDay: Int32;               // the game day + 1 a crew was lent; 0 never
  public let joinOffer: CName;             // a gang that has offered to make V one of theirs
  public let ransomNpc: wref<ScriptedPuppet>;
  public let ransomGang: CName;
  public let ransomAmount: Int32;
  public let ransomTick: Int32;
  // Where the ransom is paid (Spawn/StreetStories.reds): the drop in the gang's own district, by when, how much,
  // whether it is a trap, and its pin. Session only, as the ransom itself is.
  public let dropAt: Vector4;
  public let dropGang: CName;
  public let dropAmount: Int32;
  public let dropUntil: Float;
  public let dropBetray: Bool;
  public let dropPin: NewMappinID;
  public let dropPinned: Bool;
  public let lieGang: CName;
  public let lieUntil: Float;
  public let parleyOpen: Bool;
  public let parleyBody: EntityID;
  public let parleyGang: CName;
  public let parleyTick: Int32;
  public let parleyDoneTick: Int32;
  public let parleyCrew: array<EntityID>;
  public let greetTick: Int32;
  public let phoneStalled: CName;          // a gang V stalled by text, for the crew already counting down
  public let phoneThreatDay: Int32;        // the game day + 1 V last threatened anybody by text

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_trimmed = false;
    // A clash, a borrowed crew, a ransom and a parley went with the world the save threw away.
    this.ResetSession();
  }

  // Everything below the saved fields.
  public func ResetSession() -> Void {
    let none: EntityID;
    let nowhere: Vector4;
    this.clashA = n"";
    this.clashB = n"";
    this.clashPairTick = 0;
    ArrayClear(this.candA);
    ArrayClear(this.candB);
    ArrayClear(this.fightA);
    ArrayClear(this.fightB);
    ArrayClear(this.fightWas);
    this.fightGangA = n"";
    this.fightGangB = n"";
    this.fightAt = nowhere;
    this.fightTick = 0;
    this.clashNextTick = 0;
    this.lastClashA = n"";
    this.lastClashB = n"";
    this.lastClashAt = 0.0;
    ArrayClear(this.crewIds);
    this.crewGang = n"";
    this.crewUntil = 0.0;
    this.crewAway = 0;
    this.crewLeaving = false;
    this.crewDay = 0;
    this.joinOffer = n"";
    this.ransomNpc = null;
    this.ransomGang = n"";
    this.ransomAmount = 0;
    this.ransomTick = 0;
    // The ransom's drop: its pin is the mappin system's and is unregistered where it is registered (CBRansomDropEnd);
    // here only what is ours, so a reset cannot leave a drop waiting for a playthrough that is gone.
    this.dropGang = n"";
    this.dropAmount = 0;
    this.dropBetray = false;
    this.dropPinned = false;
    this.lieGang = n"";
    this.lieUntil = 0.0;
    this.parleyOpen = false;
    this.parleyBody = none;
    this.parleyGang = n"";
    this.parleyTick = 0;
    this.parleyDoneTick = 0;
    ArrayClear(this.parleyCrew);
    this.greetTick = 0;
    this.phoneStalled = n"";
    this.phoneThreatDay = 0;
  }

  public func OneOfTheirs() -> CName { return this.m_oneOfTheirs; }
  public func SetOneOfTheirs(gang: CName) -> Void { this.m_oneOfTheirs = gang; }

  // One of the two sides of a clash, seen by the Director: kept, the oldest dropped past a handful.
  public func KeepClashCandidate(sideA: Bool, id: EntityID) -> Void {
    if sideA {
      if !ArrayContains(this.candA, id) {
        if ArraySize(this.candA) >= CBConfig.ClashKeep() {
          ArrayErase(this.candA, 0);
        }
        ArrayPush(this.candA, id);
      }
      return;
    }
    if !ArrayContains(this.candB, id) {
      if ArraySize(this.candB) >= CBConfig.ClashKeep() {
        ArrayErase(this.candB, 0);
      }
      ArrayPush(this.candB, id);
    }
  }

  public static func Get(game: GameInstance) -> ref<CBWarBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBWarBook") as CBWarBook;
  }

  private func Trim() -> Void {
    if this.m_trimmed {
      return;
    }
    this.m_trimmed = true;
    let n = Min(Min(ArraySize(this.m_gang), ArraySize(this.m_chest)), Min(Min(ArraySize(this.m_men), ArraySize(this.m_peaceCut)),
                Min(Min(ArraySize(this.m_haggledAt), ArraySize(this.m_truceWith)), ArraySize(this.m_truceUntil))));
    ArrayResize(this.m_gang, n);
    ArrayResize(this.m_chest, n);
    ArrayResize(this.m_men, n);
    ArrayResize(this.m_peaceCut, n);
    ArrayResize(this.m_haggledAt, n);
    ArrayResize(this.m_truceWith, n);
    ArrayResize(this.m_truceUntil, n);
  }

  private func Find(gang: CName, add: Bool) -> Int32 {
    this.Trim();
    let i = 0;
    while i < ArraySize(this.m_gang) {
      if Equals(this.m_gang[i], gang) {
        return i;
      }
      i += 1;
    }
    if !add || Equals(gang, n"") {
      return -1;
    }
    ArrayPush(this.m_gang, gang);
    ArrayPush(this.m_chest, CBConfig.WarChestStart());
    ArrayPush(this.m_men, 100.0);
    ArrayPush(this.m_peaceCut, 0.0);
    ArrayPush(this.m_haggledAt, 0.0);
    ArrayPush(this.m_truceWith, n"");
    ArrayPush(this.m_truceUntil, 0.0);
    return ArraySize(this.m_gang) - 1;
  }

  public func Chest(gang: CName) -> Float {
    let i = this.Find(gang, false);
    return i >= 0 ? this.m_chest[i] : CBConfig.WarChestStart();
  }

  public func AddChest(gang: CName, amount: Float) -> Void {
    let i = this.Find(gang, true);
    if i >= 0 {
      this.m_chest[i] = ClampF(this.m_chest[i] + amount, 0.0, CBConfig.WarChestMax());
    }
  }

  public func Men(gang: CName) -> Float {
    let i = this.Find(gang, false);
    return i >= 0 ? this.m_men[i] : 100.0;
  }

  public func AddMen(gang: CName, amount: Float) -> Void {
    let i = this.Find(gang, true);
    if i >= 0 {
      this.m_men[i] = ClampF(this.m_men[i] + amount, 0.0, 100.0);
    }
  }

  public func PeaceCut(gang: CName) -> Float {
    let i = this.Find(gang, false);
    return i >= 0 ? this.m_peaceCut[i] : 0.0;
  }

  public func HaggledAt(gang: CName) -> Float {
    let i = this.Find(gang, false);
    return i >= 0 ? this.m_haggledAt[i] : 0.0;
  }

  public func SetPeaceCut(gang: CName, cut: Float, at: Float) -> Void {
    let i = this.Find(gang, true);
    if i >= 0 {
      this.m_peaceCut[i] = ClampF(cut, 0.0, 0.5);
      this.m_haggledAt[i] = at;
    }
  }

  public func TruceWith(gang: CName, now: Float) -> CName {
    let i = this.Find(gang, false);
    return i >= 0 && now < this.m_truceUntil[i] ? this.m_truceWith[i] : n"";
  }

  // When a's truce with b runs out, or 0 (the Hub's web of gangs).
  public func TruceUntilFor(a: CName, b: CName, now: Float) -> Float {
    let i = this.Find(a, false);
    return i >= 0 && Equals(this.m_truceWith[i], b) && now < this.m_truceUntil[i] ? this.m_truceUntil[i] : 0.0;
  }

  public func SetTruce(a: CName, b: CName, until: Float) -> Void {
    let i = this.Find(a, true);
    let j = this.Find(b, true);
    if i >= 0 && j >= 0 {
      this.m_truceWith[i] = b;
      this.m_truceUntil[i] = until;
      this.m_truceWith[j] = a;
      this.m_truceUntil[j] = until;
    }
  }

  public func AnyTruce(now: Float) -> Bool {
    this.Trim();
    let i = 0;
    while i < ArraySize(this.m_gang) {
      if now < this.m_truceUntil[i] && NotEquals(this.m_truceWith[i], n"") {
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func Gangs() -> array<CName> {
    this.Trim();
    return this.m_gang;
  }

  public func Backed() -> CName { return this.m_backed; }
  public func BackedSince() -> Float { return this.m_backedSince; }
  public func CutPaidAt() -> Float { return this.m_cutPaidAt; }
  public func SetCutPaidAt(at: Float) -> Void { this.m_cutPaidAt = at; }

  public func SetBacked(gang: CName, at: Float) -> Void {
    this.m_backed = gang;
    this.m_backedSince = at;
    this.m_cutPaidAt = at;
  }

  public func OwnMask() -> Int32 { return this.m_ownMask; }
  public func SetOwnMask(mask: Int32) -> Void { this.m_ownMask = mask; }
  public func OwnPaidAt() -> Float { return this.m_ownPaidAt; }
  public func SetOwnPaidAt(at: Float) -> Void { this.m_ownPaidAt = at; }

  public func InciteA() -> CName { return this.m_inciteA; }
  public func InciteB() -> CName { return this.m_inciteB; }
  public func InciteUntil() -> Float { return this.m_inciteUntil; }

  public func SetIncite(a: CName, b: CName, until: Float) -> Void {
    this.m_inciteA = a;
    this.m_inciteB = b;
    this.m_inciteUntil = until;
  }

  public func ProtectDue() -> Float { return this.m_protectDue; }
  public func ProtectAmount() -> Int32 { return this.m_protectAmount; }
  public func ProtectAskedAt() -> Float { return this.m_protectAskedAt; }
  public func ProtectSeen() -> Float { return this.m_protectSeen; }
  public func AddProtectSeen(s: Float) -> Void { this.m_protectSeen += s; }

  public func SetProtect(due: Float, amount: Int32, askedAt: Float) -> Void {
    this.m_protectDue = due;
    this.m_protectAmount = amount;
    this.m_protectAskedAt = askedAt;
    this.m_protectSeen = 0.0;
  }

  public func OpenGang() -> CName { return this.m_openGang; }
  public func OpenUntil() -> Float { return this.m_openUntil; }

  public func SetOpen(gang: CName, until: Float) -> Void {
    this.m_openGang = gang;
    this.m_openUntil = until;
  }

  public func FavourFor() -> CName { return this.m_favourFor; }
  public func FavourUntil() -> Float { return this.m_favourUntil; }

  public func SetFavour(gang: CName, until: Float) -> Void {
    this.m_favourFor = gang;
    this.m_favourUntil = until;
  }

  public func Clear() -> Void {
    ArrayClear(this.m_gang);
    ArrayClear(this.m_chest);
    ArrayClear(this.m_men);
    ArrayClear(this.m_peaceCut);
    ArrayClear(this.m_haggledAt);
    ArrayClear(this.m_truceWith);
    ArrayClear(this.m_truceUntil);
    this.m_backed = n"";
    this.m_backedSince = 0.0;
    this.m_cutPaidAt = 0.0;
    this.m_ownMask = 0;
    this.m_ownPaidAt = 0.0;
    this.m_inciteA = n"";
    this.m_inciteB = n"";
    this.m_inciteUntil = 0.0;
    this.m_protectDue = 0.0;
    this.m_protectAmount = 0;
    this.m_protectAskedAt = 0.0;
    this.m_protectSeen = 0.0;
    this.m_favourFor = n"";
    this.m_favourUntil = 0.0;
    this.m_openGang = n"";
    this.m_openUntil = 0.0;
    this.m_oneOfTheirs = n"";
    this.m_trimmed = true;
    this.ResetSession();
  }
}
