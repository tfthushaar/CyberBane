// Cyberbane - The crew's wars
//
// A war on a gang lasts until terms or ruin. It has a front, from -100 (they are winning) to +100, and weariness on
// both sides that grows each day and faster with losses. It runs at any hour: V gives the crew an order whenever it has
// regrouped, and leads it or sends them, and the gang strikes back every few hours. Each has a place and a deadline: V
// there before it makes it a fight on screen, otherwise it is a text and a result.

// What the crew can be sent to do.
public func CBWarOrderNone() -> Int32 = 0
public func CBWarOrderCorners() -> Int32 = 1
public func CBWarOrderStash() -> Int32 = 2
public func CBWarOrderLieutenant() -> Int32 = 3
public func CBWarOrderScout() -> Int32 = 4
public func CBWarOrderHold() -> Int32 = 5
public func CBWarOrderStorm() -> Int32 = 6

// What the gang can do back.
public func CBWarMoveNone() -> Int32 = 0
public func CBWarMoveCorner() -> Int32 = 1
public func CBWarMoveAmbush() -> Int32 = 2
public func CBWarMoveRaid() -> Int32 = 3
public func CBWarMovePrice() -> Int32 = 4
public func CBWarMoveLean() -> Int32 = 5
public func CBWarMoveCoalition() -> Int32 = 6

// Where a war stands: fighting, they ask for terms, they demand terms of the crew, or to the end (terms refused).
public func CBWarStateOn() -> Int32 = 0
public func CBWarStateTheyAsk() -> Int32 = 1
public func CBWarStateTheyDemand() -> Int32 = 2
public func CBWarStateToTheEnd() -> Int32 = 3

// Terms. The first four are what the crew can take from a gang that asks; the last three what a winning gang asks of
// the crew.
public func CBTermsTribute() -> Int32 = 1
public func CBTermsGround() -> Int32 = 2
public func CBTermsHandOver() -> Int32 = 3
public func CBTermsClient() -> Int32 = 4
public func CBTermsPay() -> Int32 = 5
public func CBTermsGiveGround() -> Int32 = 6
public func CBTermsGiveSomebody() -> Int32 = 7

// How a finished war ended, for its page in History.
public func CBWarEndTerms() -> Int32 = 1
public func CBWarEndBroken() -> Int32 = 2
public func CBWarEndLostTerms() -> Int32 = 3
public func CBWarEndRouted() -> Int32 = 4
public func CBWarEndCalledOff() -> Int32 = 5

public class CBWarFront {
  public persistent let gang: CName;
  public persistent let since: Float;
  public persistent let place: CName;          // where it started: "the Arroyo war"
  public persistent let front: Float;          // -100 they are winning .. +100
  public persistent let ourWeary: Float;       // 0..100
  public persistent let theirWeary: Float;
  public persistent let nights: Int32;         // days the war has lasted
  public persistent let byThem: Bool;
  public persistent let state: Int32;
  public persistent let night: Int32;          // the last war day counted (noon to noon)
  public persistent let order: Int32;
  public persistent let orderAt: Float;        // an order's deadline; with none on, when the crew is ready for one
  public persistent let orderX: Float;
  public persistent let orderY: Float;
  public persistent let orderZ: Float;
  public persistent let orderTarget: Int32;    // a Rival, for a lieutenant
  public persistent let orderBySecond: Bool;
  public persistent let orderDone: Bool;
  public persistent let move: Int32;
  public persistent let moveAt: Float;         // their move's deadline; with none on, when they pick the next
  public persistent let moveX: Float;
  public persistent let moveY: Float;
  public persistent let moveZ: Float;
  public persistent let moveTarget: Int32;     // a member, or a district index
  public persistent let moveTold: Bool;        // the crew knows of it
  public persistent let moveDone: Bool;
  public persistent let scoutUntil: Float;
  public persistent let chestCut: Bool;
  public persistent let ltGone: Bool;          // a lieutenant of theirs gone today, before the fighters went in
  public persistent let ourLost: Int32;
  public persistent let theirLost: Int32;
  public persistent let vNights: Int32;        // fights V was in
  public persistent let terms: Int32;
  public persistent let termsUntil: Float;
  public persistent let ally: CName;           // a gang fighting on the crew's side
  public persistent let theirAlly: CName;      // and one on theirs
  public persistent let carried: Int32;        // the member who carried it, by fights won
  public persistent let carriedScore: Int32;
  public persistent let heldBehind: Bool;      // the guards held what was taken
  public persistent let sold: Bool;            // a loose tongue sold the order

  public func OrderPlace() -> Vector4 { return new Vector4(this.orderX, this.orderY, this.orderZ, 1.0); }
  public func MovePlace() -> Vector4 { return new Vector4(this.moveX, this.moveY, this.moveZ, 1.0); }
  public func SetOrderPlace(at: Vector4) -> Void { this.orderX = at.X; this.orderY = at.Y; this.orderZ = at.Z; }
  public func SetMovePlace(at: Vector4) -> Void { this.moveX = at.X; this.moveY = at.Y; this.moveZ = at.Z; }
}

// A war that is over.
public class CBWarPast {
  public persistent let gang: CName;
  public persistent let place: CName;
  public persistent let since: Float;
  public persistent let ended: Float;
  public persistent let how: Int32;
  public persistent let nights: Int32;
  public persistent let ourLost: Int32;
  public persistent let theirLost: Int32;
  public persistent let carried: Int32;
}

// A gang the crew beat that pays and fights for it now.
public class CBWarClient {
  public persistent let gang: CName;
  public persistent let since: Float;
  public persistent let tribute: Int32;        // a week
  public persistent let paidAt: Float;
  public persistent let full: Bool;            // a client in full: friendly to V and fighting in the crew's wars, not only paying
}

// One of the crew taken alive, and what the gang wants for them.
public class CBWarCaptive {
  public persistent let member: Int32;
  public persistent let gang: CName;
  public persistent let since: Float;
  public persistent let price: Int32;
  public persistent let x: Float;
  public persistent let y: Float;
  public persistent let z: Float;
  public persistent let rescue: Bool;          // V said they are coming for them

  public func Place() -> Vector4 { return new Vector4(this.x, this.y, this.z, 1.0); }
}

public class CBWarFrontBook extends ScriptableSystem {
  private persistent let m_fronts: array<ref<CBWarFront>>;
  private persistent let m_past: array<ref<CBWarPast>>;
  private persistent let m_clients: array<ref<CBWarClient>>;
  private persistent let m_captives: array<ref<CBWarCaptive>>;
  private persistent let m_prisonRival: array<Int32>;     // their lieutenants the crew holds
  private persistent let m_prisonGang: array<CName>;
  private persistent let m_grudgeGang: array<CName>;      // beaten gangs, and until when they hold it against the crew
  private persistent let m_grudgeUntil: array<Float>;
  private persistent let m_winsAt: array<Float>;          // when the crew won its wars lately: the city answers a winner
  private persistent let m_brokenGang: array<CName>;      // gangs the crew broke, kept broken until then
  private persistent let m_brokenUntil: array<Float>;
  // Session only: the Hub's pick while it plans an order.
  public let pickGang: CName;
  public let pickOrder: Int32;
  public let pickTarget: Int32;
  public let pickParty: array<Int32>;
  // Session only: orders given while the game was paused (the Hub), placed and told on the first settled tick, and the
  // wars whose crew has said V joined in.
  public let placeDue: array<CName>;
  public let placeLead: array<Bool>;
  public let vJoinedSaid: array<CName>;

  public static func Get(game: GameInstance) -> ref<CBWarFrontBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBWarFrontBook") as CBWarFrontBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.pickGang = n"";
    this.pickOrder = 0;
    this.pickTarget = 0;
    ArrayClear(this.pickParty);
    ArrayClear(this.placeDue);
    ArrayClear(this.placeLead);
    ArrayClear(this.vJoinedSaid);
    this.Trim();
  }

  public func DuePlace(gang: CName, lead: Bool) -> Void {
    this.TakeDuePlace(gang);
    ArrayPush(this.placeDue, gang);
    ArrayPush(this.placeLead, lead);
  }

  public func PlaceIsDue(gang: CName) -> Bool { return ArrayContains(this.placeDue, gang); }

  // Taken off the list: whether V leads it.
  public func TakeDuePlace(gang: CName) -> Bool {
    let lead = false;
    let i = Min(ArraySize(this.placeDue), ArraySize(this.placeLead)) - 1;
    while i >= 0 {
      if Equals(this.placeDue[i], gang) {
        lead = this.placeLead[i];
        ArrayErase(this.placeDue, i);
        ArrayErase(this.placeLead, i);
      }
      i -= 1;
    }
    ArrayResize(this.placeLead, ArraySize(this.placeDue));
    return lead;
  }

  private func Trim() -> Void {
    let n = Min(ArraySize(this.m_prisonRival), ArraySize(this.m_prisonGang));
    ArrayResize(this.m_prisonRival, n);
    ArrayResize(this.m_prisonGang, n);
    let g = Min(ArraySize(this.m_grudgeGang), ArraySize(this.m_grudgeUntil));
    ArrayResize(this.m_grudgeGang, g);
    ArrayResize(this.m_grudgeUntil, g);
    let b = Min(ArraySize(this.m_brokenGang), ArraySize(this.m_brokenUntil));
    ArrayResize(this.m_brokenGang, b);
    ArrayResize(this.m_brokenUntil, b);
  }

  public func BrokenUntil(gang: CName) -> Float {
    let i = 0;
    while i < Min(ArraySize(this.m_brokenGang), ArraySize(this.m_brokenUntil)) {
      if Equals(this.m_brokenGang[i], gang) {
        return this.m_brokenUntil[i];
      }
      i += 1;
    }
    return 0.0;
  }

  public func SetBroken(gang: CName, until: Float) -> Void {
    let i = 0;
    while i < Min(ArraySize(this.m_brokenGang), ArraySize(this.m_brokenUntil)) {
      if Equals(this.m_brokenGang[i], gang) {
        this.m_brokenUntil[i] = until;
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_brokenGang, gang);
    ArrayPush(this.m_brokenUntil, until);
  }

  public func Clear() -> Void {
    ArrayClear(this.m_fronts);
    ArrayClear(this.m_past);
    ArrayClear(this.m_clients);
    ArrayClear(this.m_captives);
    ArrayClear(this.m_prisonRival);
    ArrayClear(this.m_prisonGang);
    ArrayClear(this.m_grudgeGang);
    ArrayClear(this.m_grudgeUntil);
    ArrayClear(this.m_winsAt);
    ArrayClear(this.m_brokenGang);
    ArrayClear(this.m_brokenUntil);
    this.pickGang = n"";
    this.pickOrder = 0;
    this.pickTarget = 0;
    ArrayClear(this.pickParty);
    ArrayClear(this.placeDue);
    ArrayClear(this.placeLead);
    ArrayClear(this.vJoinedSaid);
  }

  // ---- Wars ----
  public func Count() -> Int32 { return ArraySize(this.m_fronts); }
  public func At(i: Int32) -> ref<CBWarFront> { return i >= 0 && i < ArraySize(this.m_fronts) ? this.m_fronts[i] : null; }

  public func Find(gang: CName) -> ref<CBWarFront> {
    for f in this.m_fronts {
      if IsDefined(f) && Equals(f.gang, gang) {
        return f;
      }
    }
    return null;
  }

  public func Add(f: ref<CBWarFront>) -> Void { ArrayPush(this.m_fronts, f); }

  public func End(f: ref<CBWarFront>, how: Int32, now: Float) -> Void {
    if !IsDefined(f) {
      return;
    }
    let p = new CBWarPast();
    p.gang = f.gang;
    p.place = f.place;
    p.since = f.since;
    p.ended = now;
    p.how = how;
    p.nights = f.nights;
    p.ourLost = f.ourLost;
    p.theirLost = f.theirLost;
    p.carried = f.carried;
    ArrayPush(this.m_past, p);
    while ArraySize(this.m_past) > CBConfig.WarPastKept() {
      ArrayErase(this.m_past, 0);
    }
    ArrayRemove(this.m_fronts, f);
  }

  public func PastCount() -> Int32 { return ArraySize(this.m_past); }
  public func PastAt(i: Int32) -> ref<CBWarPast> { return i >= 0 && i < ArraySize(this.m_past) ? this.m_past[i] : null; }

  // ---- Clients ----
  public func ClientCount() -> Int32 { return ArraySize(this.m_clients); }
  public func ClientAt(i: Int32) -> ref<CBWarClient> { return i >= 0 && i < ArraySize(this.m_clients) ? this.m_clients[i] : null; }
  public func FindClient(gang: CName) -> ref<CBWarClient> {
    for c in this.m_clients {
      if IsDefined(c) && Equals(c.gang, gang) {
        return c;
      }
    }
    return null;
  }
  public func AddClient(c: ref<CBWarClient>) -> Void { ArrayPush(this.m_clients, c); }
  public func DropClient(c: ref<CBWarClient>) -> Void { ArrayRemove(this.m_clients, c); }

  // ---- Captives ----
  public func CaptiveCount() -> Int32 { return ArraySize(this.m_captives); }
  public func CaptiveAt(i: Int32) -> ref<CBWarCaptive> { return i >= 0 && i < ArraySize(this.m_captives) ? this.m_captives[i] : null; }
  public func FindCaptive(member: Int32) -> ref<CBWarCaptive> {
    for c in this.m_captives {
      if IsDefined(c) && c.member == member {
        return c;
      }
    }
    return null;
  }
  public func AddCaptive(c: ref<CBWarCaptive>) -> Void { ArrayPush(this.m_captives, c); }
  public func DropCaptive(c: ref<CBWarCaptive>) -> Void { ArrayRemove(this.m_captives, c); }

  // ---- Their people the crew holds ----
  public func PrisonCount() -> Int32 { return Min(ArraySize(this.m_prisonRival), ArraySize(this.m_prisonGang)); }
  public func PrisonRival(i: Int32) -> Int32 { return i >= 0 && i < this.PrisonCount() ? this.m_prisonRival[i] : 0; }
  public func PrisonGang(i: Int32) -> CName { return i >= 0 && i < this.PrisonCount() ? this.m_prisonGang[i] : n""; }
  public func AddPrisoner(rival: Int32, gang: CName) -> Void {
    ArrayPush(this.m_prisonRival, rival);
    ArrayPush(this.m_prisonGang, gang);
  }
  public func DropPrisoner(i: Int32) -> Void {
    if i >= 0 && i < this.PrisonCount() {
      ArrayErase(this.m_prisonRival, i);
      ArrayErase(this.m_prisonGang, i);
    }
  }
  public func PrisonerOf(gang: CName) -> Int32 {
    let i = 0;
    while i < this.PrisonCount() {
      if Equals(this.m_prisonGang[i], gang) {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  // ---- Grudges and the city's answer ----
  public func Grudge(gang: CName, now: Float) -> Bool {
    let i = 0;
    while i < Min(ArraySize(this.m_grudgeGang), ArraySize(this.m_grudgeUntil)) {
      if Equals(this.m_grudgeGang[i], gang) && now < this.m_grudgeUntil[i] {
        return true;
      }
      i += 1;
    }
    return false;
  }
  public func SetGrudge(gang: CName, until: Float) -> Void {
    let i = 0;
    while i < Min(ArraySize(this.m_grudgeGang), ArraySize(this.m_grudgeUntil)) {
      if Equals(this.m_grudgeGang[i], gang) {
        this.m_grudgeUntil[i] = until;
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_grudgeGang, gang);
    ArrayPush(this.m_grudgeUntil, until);
  }
  public func NoteWin(now: Float) -> Void {
    ArrayPush(this.m_winsAt, now);
    while ArraySize(this.m_winsAt) > 8 {
      ArrayErase(this.m_winsAt, 0);
    }
  }
  public func WinsSince(at: Float) -> Int32 {
    let n = 0;
    for w in this.m_winsAt {
      if w >= at {
        n += 1;
      }
    }
    return n;
  }
}

// ---- On or off -------------------------------------------------------------------------------------------------------

public func CBGangWarFront(game: GameInstance, gang: CName) -> ref<CBWarFront> {
  let fb = CBWarFrontBook.Get(game);
  return IsDefined(fb) && IsNameValid(gang) ? fb.Find(gang) : null;
}

// The war day: noon to noon, so a night and the morning after are one day of the war.
public func CBWarDayAt(seconds: Float) -> Int32 {
  return FloorF((seconds - 12.0 * 3600.0) / 86400.0);
}

// How many wars the crew can fight at once, by how big it has grown (C5).
public func CBCrewWarsAtOnce(game: GameInstance) -> Int32 {
  let tier = CBCrewTier(game);
  if tier >= 3 { return 3; }
  if tier >= 2 { return 2; }
  return 1;
}

// ---- What the gang really has (F1) ----------------------------------------------------------------------------------

// The gang's weight in a war: its people and its money, its living Rivals by rank, the strongholds and districts it
// holds, any gang in a truce with it, and the hired guns a crew that keeps winning draws. `bare` leaves the truce
// partner out (so two partners never count each other twice).
public func CBGangWarWeight(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, opt bare: Bool) -> Float {
  if !IsDefined(sys) || !IsNameValid(gang) {
    return 0.0;
  }
  let home = CBGangHomeDistrict(sys, game, gang);
  let core = CBConfig.GangWarBase() + CBConfig.GangWarPerStrength() * CBGangStrengthIn(sys, gang, home);
  let book = CBWarBook.Get(game);
  let men = IsDefined(book) ? book.Men(gang) : 100.0;
  let chest = IsDefined(book) ? book.Chest(gang) : CBConfig.WarChestStart();
  core *= 0.35 + 0.65 * ClampF(men / 100.0, 0.0, 1.0);
  core += CBConfig.GangWarChestWeight() * ClampF(chest / CBConfig.WarChestMax(), 0.0, 1.0);
  // Their names: a boss with lieutenants is worth far more than their numbers alone.
  let names = 0.0;
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, gang)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      names += CBConfig.GangWarPerRival() + CBConfig.GangWarPerRivalRank() * Cast<Float>(r.rank);
    }
  }
  core += MinF(names, CBConfig.GangWarRivalCeiling());
  let bases = CBBaseBook.Get(game);
  if IsDefined(bases) {
    let h = 0;
    while h < bases.HoldCount() {
      if Equals(bases.HoldGangAt(h), gang) {
        core += CBConfig.GangWarPerStronghold();
      }
      h += 1;
    }
  }
  let d = 0;
  while d < CBDistrictCount() {
    if Equals(CBTurfHolder(sys, game, CBDistrictAt(d)), gang) {
      core += CBConfig.GangWarPerDistrict();
    }
    d += 1;
  }
  // Ready for a crew it hates, caught out by one it respects; afraid of V.
  core *= 1.0 - CBConfig.GangWarStandWeight() * Cast<Float>(CBCrewStandingWith(game, gang)) / 100.0;
  let score = sys.GetScore();
  if IsDefined(score) {
    core *= 1.0 - CBConfig.GangWarFearWeight() * ClampF(score.GetFactionFear(gang) / 100.0, 0.0, 1.0);
  }
  if !bare {
    let partner = CBTrucePartner(game, gang);
    let f = CBGangWarFront(game, gang);
    if IsDefined(f) && IsNameValid(f.theirAlly) {
      partner = f.theirAlly;
    }
    if IsNameValid(partner) && NotEquals(partner, gang) {
      core += CBConfig.GangWarFriendShare() * CBGangWarWeight(sys, game, partner, true);
    }
    // The city answers a crew that keeps winning: hired guns for whoever it fights next.
    let fb = CBWarFrontBook.Get(game);
    if IsDefined(fb) {
      let recent = fb.WinsSince(CBGameSeconds(game) - CBConfig.WarCityAnswerDays() * CBConfig.SecondsPerDay());
      core += CBConfig.WarCityAnswerPerWin() * Cast<Float>(recent);
    }
  }
  return MaxF(core, 20.0) * CBConfig.GangWarScale() * CBCrewPaceWarFactor();
}

// How much of their weight an order meets: their corners are a part of them, a stash a few guards, a lieutenant and their
// people, their boss everything they have left.
public func CBWarOrderMeets(order: Int32) -> Float {
  if order == CBWarOrderCorners() { return CBConfig.WarMeetCorners(); }
  if order == CBWarOrderStash() { return CBConfig.WarMeetStash(); }
  if order == CBWarOrderLieutenant() { return CBConfig.WarMeetLieutenant(); }
  if order == CBWarOrderStorm() { return 1.0; }
  return 0.0;
}

// A fight's swing: a good plan can still go wrong.
public func CBWarSwing() -> Float {
  return RandRangeF(CBConfig.WarSwingLow(), CBConfig.WarSwingHigh());
}

// ---- Declaring it ---------------------------------------------------------------------------------------------------

// The crew goes to war on a gang (byThem: the gang on the crew). Only words and books: the war's own tick carries it. The
// crew is ready for an order at once, and the gang's first move comes soon.
public func CBGangWarDeclare(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, byThem: Bool) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(sys) || !IsDefined(fb) || !IsDefined(book) || !IsNameValid(gang) || IsDefined(fb.Find(gang)) || book.Count() == 0 {
    return false;
  }
  if fb.Count() >= CBCrewWarsAtOnce(game) {
    return false;
  }
  let now = CBGameSeconds(game);
  let f = new CBWarFront();
  f.gang = gang;
  f.since = now;
  f.place = CBWarTargetDistrict(sys, game, gang);
  f.byThem = byThem;
  f.state = CBWarStateOn();
  f.night = CBWarDayAt(now);
  f.orderAt = now;
  f.moveAt = now + CBConfig.WarFirstMoveHours() * CBConfig.SecondsPerHour();
  fb.Add(f);
  // Their client no more: a client the crew goes to war on is a war of broken terms.
  let client = fb.FindClient(gang);
  if IsDefined(client) {
    fb.DropClient(client);
  }
  // A gang at war with V's crew is at war with V.
  CBTalkSlight(sys, game, gang, CBConfig.WarDeclareStanding());
  CBCrewStandingShift(game, gang, -CBConfig.CrewStandWarLost());
  CBFileLog(sys, n"WarBegan", now, f.place, gang, byThem ? 1.0 : 0.0);
  let label = CBCapFirst(CBFactionLabel(gang));
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), byThem ? CBTf(n"Cyberbane-GangWar-TheyDeclared", [label, CBWarName(f)])
                                                      : CBTf(n"Cyberbane-GangWar-WeDeclared", [CBFactionLabel(gang), CBWarName(f)]), true);
  }
  CBLog.Info(n"War", s"The crew is at war with \(NameToString(gang)) (\(byThem ? "they started it" : "V started it")), fought in \(NameToString(f.place)).");
  return true;
}

// "the Arroyo war": the place it started.
public func CBWarName(f: ref<CBWarFront>) -> String {
  return IsDefined(f) ? CBTf(n"Cyberbane-GangWar-WarName", [CBDistrictLabel(f.place)]) : "";
}

public func CBWarPastName(p: ref<CBWarPast>) -> String {
  return IsDefined(p) ? CBTf(n"Cyberbane-GangWar-WarName", [CBDistrictLabel(p.place)]) : "";
}

// ---- The crew's orders (W2) -----------------------------------------------------------------------------------------

// The orders V can give, three at most and Hold, by what the war needs: the boss once it is to the end; a
// lieutenant when one is known; their stash while their chest is full; their corners always; a scout while they are
// unscouted.
public func CBWarOrdersOffered(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> array<Int32> {
  let out: array<Int32>;
  if !IsDefined(f) {
    return out;
  }
  let now = CBGameSeconds(game);
  if f.state == CBWarStateToTheEnd() || f.front >= CBConfig.WarStormFront() {
    ArrayPush(out, CBWarOrderStorm());
  }
  if CBWarLieutenantTarget(sys, game, f.gang) > 0 && ArraySize(out) < 3 {
    ArrayPush(out, CBWarOrderLieutenant());
  }
  if ArraySize(out) < 3 {
    ArrayPush(out, CBWarOrderCorners());
  }
  let book = CBWarBook.Get(game);
  if ArraySize(out) < 3 && (!IsDefined(book) || book.Chest(f.gang) > CBConfig.WarChestBroke()) && !f.chestCut {
    ArrayPush(out, CBWarOrderStash());
  }
  if ArraySize(out) < 3 && now >= f.scoutUntil {
    ArrayPush(out, CBWarOrderScout());
  }
  ArrayPush(out, CBWarOrderHold());
  return out;
}

public func CBWarOrderWord(order: Int32) -> String {
  if order == CBWarOrderCorners() { return CBT(n"Cyberbane-GangWar-OrderCorners"); }
  if order == CBWarOrderStash() { return CBT(n"Cyberbane-GangWar-OrderStash"); }
  if order == CBWarOrderLieutenant() { return CBT(n"Cyberbane-GangWar-OrderLieutenant"); }
  if order == CBWarOrderScout() { return CBT(n"Cyberbane-GangWar-OrderScout"); }
  if order == CBWarOrderHold() { return CBT(n"Cyberbane-GangWar-OrderHold"); }
  if order == CBWarOrderStorm() { return CBT(n"Cyberbane-GangWar-OrderStorm"); }
  return CBT(n"Cyberbane-GangWar-OrderNone");
}

public func CBWarOrderHelp(order: Int32) -> String {
  if order == CBWarOrderCorners() { return CBT(n"Cyberbane-GangWar-HelpCorners"); }
  if order == CBWarOrderStash() { return CBT(n"Cyberbane-GangWar-HelpStash"); }
  if order == CBWarOrderLieutenant() { return CBT(n"Cyberbane-GangWar-HelpLieutenant"); }
  if order == CBWarOrderScout() { return CBT(n"Cyberbane-GangWar-HelpScout"); }
  if order == CBWarOrderHold() { return CBT(n"Cyberbane-GangWar-HelpHold"); }
  if order == CBWarOrderStorm() { return CBT(n"Cyberbane-GangWar-HelpStorm"); }
  return "";
}

// An order that sends people: everything but a scout and a hold.
public func CBWarOrderFights(order: Int32) -> Bool {
  return order == CBWarOrderCorners() || order == CBWarOrderStash() || order == CBWarOrderLieutenant() || order == CBWarOrderStorm();
}

// Their best-known lieutenant: a Rival of theirs at lieutenant rank or more, out there and not the boss while the war is
// young. 0 for none.
public func CBWarLieutenantTarget(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Int32 {
  let best: ref<CBRival>;
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, gang) && r.rank >= CBConfig.LieutenantMinRank()
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting))
       && r.id != sys.GetActiveRivalId() && (!IsDefined(best) || r.rank < best.rank) {
      best = r;
    }
  }
  return IsDefined(best) ? best.id : 0;
}

// ---- Where the war is fought ----------------------------------------------------------------------------------------

// The gang's side of the war: the district where it is strongest that the crew does not hold, else where it is strongest
// at all, else its home. A gang holding no district of its own went to its profile's home, which was the crew's own
// streets for Maelstrom in Watson.
public func CBWarTargetDistrict(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> CName {
  let held = CBCrewHeldDistricts(sys, game);
  let best = n"";
  let bestShare = 0.0;
  let any = n"";
  let anyShare = 0.0;
  let i = 0;
  while i < CBDistrictCount() {
    let d = CBDistrictAt(i);
    i += 1;
    let ids: array<CName>;
    let shares: array<Float>;
    CBTurfShares(sys, game, d, ids, shares);
    let share = CBTurfShareOf(ids, shares, gang);
    if share > anyShare {
      any = d;
      anyShare = share;
    }
    if share > bestShare && !ArrayContains(held, d) {
      best = d;
      bestShare = share;
    }
  }
  if IsNameValid(best) && bestShare >= CBConfig.WarTargetMinShare() {
    return best;
  }
  return IsNameValid(any) ? any : CBGangHomeDistrict(sys, game, gang);
}

// A place in this district close to V, far enough off for their people to come in unseen: one of the nearer fast travel
// points, at random so a war is not fought on one corner, else a place the street knows there.
public func CBWarPlaceNear(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, out at: Vector4) -> Bool {
  let player = GetPlayer(game);
  if IsDefined(player) && CBWorldStable(game) {
    let picks: array<Vector4>;
    let names: array<String>;
    let from = player.GetWorldPosition();
    if CBFastTravelPlaces(sys, game, district, from, CBConfig.WarPlaceMinAway(), 100000.0, picks, names) > 0 && ArraySize(picks) > 0 {
      let nearest = -1.0;
      for p in picks {
        let d = Vector4.Distance(from, p);
        if nearest < 0.0 || d < nearest {
          nearest = d;
        }
      }
      let close: array<Vector4>;
      for p in picks {
        if Vector4.Distance(from, p) <= nearest + 400.0 {
          ArrayPush(close, p);
        }
      }
      at = close[RandRange(0, ArraySize(close))];
      return true;
    }
  }
  return CBPlaceInDistrict(game, district, at);
}

// Where an order happens, by what it is: a lieutenant where they were last seen, a stash at one of their places, their
// corners and their boss on their own streets, near V. False when nowhere is known (the order runs off screen only).
func CBWarOrderSpot(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, order: Int32, target: Int32, out at: Vector4) -> Bool {
  if order == CBWarOrderLieutenant() {
    let r = sys.FindRivalById(target);
    let s = IsDefined(r) ? CBSightingFor(sys, r) : null;
    if IsDefined(s) {
      at = CBSightingPos(s);
      return true;
    }
  }
  let district = CBWarTargetDistrict(sys, game, f.gang);
  if order == CBWarOrderStash() || order == CBWarOrderStorm() {
    if CBWarBaseIn(game, district, at) {
      return true;
    }
  }
  return CBWarPlaceNear(sys, game, district, at);
}

// One of the gig places cleared in this district (Rivals/Strongholds.reds), at random.
public func CBWarBaseIn(game: GameInstance, district: CName, out at: Vector4) -> Bool {
  let bases = CBBaseBook.Get(game);
  if !IsDefined(bases) || !IsNameValid(district) {
    return false;
  }
  let picks: array<Int32>;
  let i = 0;
  while i < bases.BaseCount() {
    if Equals(bases.BaseDistrictAt(i), district) {
      ArrayPush(picks, i);
    }
    i += 1;
  }
  if ArraySize(picks) == 0 {
    return false;
  }
  at = bases.BaseAt(picks[RandRange(0, ArraySize(picks))]);
  return true;
}

// A fast travel point, or a place the street knows, in this district.
public func CBWarPlaceIn(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, out at: Vector4) -> Bool {
  let player = GetPlayer(game);
  if IsDefined(player) && CBWorldStable(game) {
    let picks: array<Vector4>;
    let names: array<String>;
    if CBFastTravelPlaces(sys, game, district, player.GetWorldPosition(), 0.0, 100000.0, picks, names) > 0 && ArraySize(picks) > 0 {
      at = picks[RandRange(0, ArraySize(picks))];
      return true;
    }
  }
  return CBPlaceInDistrict(game, district, at);
}

// Can V give this war an order now: none on and the crew regrouped, or one on whose fight has not started (it can still
// be changed).
public func CBWarCanOrder(game: GameInstance, f: ref<CBWarFront>) -> Bool {
  if !IsDefined(f) {
    return false;
  }
  if f.order == CBWarOrderNone() {
    return CBGameSeconds(game) >= f.orderAt;
  }
  return !f.orderDone && !CBWarFightOnFor(game, f.gang, true);
}

// V gives an order from the Hub, at any hour: who goes, and against what. `lead`: V leads it, and the crew waits at the
// place for hours; otherwise they go in within the hour, and V can still join them there before then. Their boss is
// only ever stormed with V, so a storm is always led. Only words and books, carried out at once (the texts wait for the
// game, CBCrewText). True when it was given.
public func CBGangWarGiveOrder(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, order: Int32, party: array<Int32>,
                               target: Int32, bySecond: Bool, lead: Bool) -> Bool {
  let f = CBGangWarFront(game, gang);
  let book = CBCrewBook.Get(game);
  let kb = CBCrewKitBook.Get(game);
  if !IsDefined(sys) || !IsDefined(f) || !IsDefined(book) || !IsDefined(kb) || order == CBWarOrderNone() || !CBWarCanOrder(game, f) {
    return false;
  }
  let now = CBGameSeconds(game);
  let waits = lead || order == CBWarOrderStorm();
  // An order changed before its fight: the last party is free again, and can be picked again.
  let before = CBWarParty(game, gang);
  CBWarReleaseParty(game, kb, gang);
  // Who goes: eligible; sent without V, led by a Lieutenant unless the squads can carry it. V leads a led order, so
  // anybody may go with V, or nobody: the crew V calls comes anyway.
  let going: array<Int32>;
  if CBWarOrderFights(order) {
    for id in party {
      let m = book.Find(id);
      if CBCrewWarEligible(game, book, m, now) && !ArrayContains(going, id) && ArraySize(going) < CBConfig.CrewWarPartyMax() {
        ArrayPush(going, id);
      }
    }
    if !waits && (ArraySize(going) == 0 || !CBCrewWarPartyLed(game, book, going)) && !CBSquadsCanLead(game) {
      for id in before {
        let kept = kb.Kit(id);
        kept.warOn = gang;
        kept.warUntil = f.orderAt + CBConfig.WarFightHours() * CBConfig.SecondsPerHour();
      }
      return false;
    }
  }
  f.order = order;
  f.orderDone = false;
  f.sold = false;
  f.orderTarget = order == CBWarOrderLieutenant() ? (target > 0 ? target : CBWarLieutenantTarget(sys, game, gang)) : 0;
  f.orderBySecond = bySecond;
  let hours = CBWarOrderFights(order) ? (waits ? CBConfig.WarLeadHours() : CBConfig.WarSendHours())
                                      : (order == CBWarOrderHold() ? CBConfig.WarHoldHours() : CBConfig.WarSendHours());
  f.orderAt = CBQuarterUp(now + hours * CBConfig.SecondsPerHour());
  // Its place: from the world's own fast travel points, which are not read while the game is paused. An order given on
  // the Hub is placed, pinned and told on the first settled tick; it went out as "around town" with no pin at all.
  f.SetOrderPlace(new Vector4(0.0, 0.0, 0.0, 1.0));
  let fb = CBWarFrontBook.Get(game);
  let placeNow = !CBWarOrderFights(order) || CBWorldStable(game) || !IsDefined(fb);
  if CBWarOrderFights(order) && placeNow {
    let at: Vector4;
    if CBWarOrderSpot(sys, game, f, order, f.orderTarget, at) {
      f.SetOrderPlace(at);
    }
  }
  for id in going {
    let k = kb.Kit(id);
    k.warOn = gang;
    k.warUntil = f.orderAt + CBConfig.WarFightHours() * CBConfig.SecondsPerHour();
    if CBGuardPosted(game, id) {
      CBGuardStandDown(game, id);
    }
  }
  if placeNow {
    CBWarOrderPlaced(sys, game, f, waits);
  } else {
    fb.DuePlace(gang, waits);
  }
  CBLog.Info(n"War", s"Order on \(NameToString(gang)): \(order) by \(CBClockWord(f.orderAt)) (\(waits ? "led" : "sent")), \(ArraySize(going)) of the crew going\(placeNow ? "" : ", placed once the game is back").");
  return true;
}

// The order has its place: their boss or their lieutenant waiting there, and the crew's text saying where and by when.
func CBWarOrderPlaced(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, waits: Bool) -> Void {
  let now = CBGameSeconds(game);
  let order = f.order;
  let gang = f.gang;
  // Their boss, when the gang has a Rival at the top: waiting at the place being stormed.
  if order == CBWarOrderStorm() && CBWarSpotKnown(f.OrderPlace()) {
    let boss = CBGangBossRival(sys, gang);
    if IsDefined(boss) && CBTipEligible(sys, game, boss) {
      CBNoteRivalSeenAt(sys, game, boss, f.OrderPlace());
      let bs = CBSightingFor(sys, boss);
      if IsDefined(bs) {
        CBMarkLeadTold(sys, bs, n"", now);
      }
    }
  }
  // A lieutenant is found where V can follow: the lead is theirs to see, as a tip is.
  if order == CBWarOrderLieutenant() && f.orderTarget > 0 {
    let r = sys.FindRivalById(f.orderTarget);
    let s = IsDefined(r) ? CBSightingFor(sys, r) : null;
    if IsDefined(s) {
      CBMarkLeadTold(sys, s, n"", now);
    }
  }
  if !CBMessagesOn() {
    return;
  }
  let book = CBCrewBook.Get(game);
  let going = CBWarParty(game, gang);
  let who = CBCrewWarPartyWords(sys, game, book, going);
  let line = "";
  if CBWarOrderFights(order) {
    let alone = ArraySize(going) == 0 && CBSquadCount(game) == 0;
    if waits {
      line = alone ? CBTf(n"Cyberbane-GangWar-PlanLeadCall", [CBWarOrderWord(order), CBWarWhere(sys, game, f), CBClockWord(f.orderAt)])
                   : CBTf(n"Cyberbane-GangWar-PlanLead", [CBWarOrderWord(order), CBWarWhere(sys, game, f), CBClockWord(f.orderAt), who]);
    } else {
      line = CBTf(n"Cyberbane-GangWar-PlanSend", [CBWarOrderWord(order), CBWarWhere(sys, game, f), CBClockWord(f.orderAt), who]);
    }
  } else {
    line = order == CBWarOrderScout() ? CBTf(n"Cyberbane-GangWar-PlanScout", [CBFactionLabel(gang), CBClockWord(f.orderAt)])
                                      : CBTf(n"Cyberbane-GangWar-PlanHold", [CBFactionLabel(gang), CBClockWord(f.orderAt)]);
  }
  CBCrewText(sys, game, f.orderBySecond ? CBCrewSecond(game) : null, line, true, waits && CBWarOrderFights(order));
  if CBWarOrderFights(order) {
    CBLog.Info(n"War", s"The order on \(NameToString(gang)) has its place: \(CBWarSpotKnown(f.OrderPlace()) ? RoundF(CBWarDistToV(game, f.OrderPlace())) : -1) m from V.");
  }
}

// How far a place is from V, for the log; -1 when there is no V.
func CBWarDistToV(game: GameInstance, at: Vector4) -> Float {
  let player = GetPlayer(game);
  return IsDefined(player) ? Vector4.Distance(player.GetWorldPosition(), at) : -1.0;
}

// The order is over: the crew free again, and ready for the next once it has regrouped.
func CBWarOrderFinished(game: GameInstance, f: ref<CBWarFront>, now: Float, regroup: Bool) -> Void {
  CBWarReleaseParty(game, CBCrewKitBook.Get(game), f.gang);
  f.order = CBWarOrderNone();
  f.orderDone = false;
  f.orderTarget = 0;
  f.orderBySecond = false;
  f.SetOrderPlace(new Vector4(0.0, 0.0, 0.0, 1.0));
  f.orderAt = regroup ? now + CBConfig.WarRegroupHours() * CBConfig.SecondsPerHour() : now;
}

// "Ryo, Kai and the squads", "the squads", for the plan's text: one list, so it never reads "Kai and Mina and the squads".
func CBCrewWarPartyWords(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, ids: array<Int32>) -> String {
  let words: array<String>;
  for id in ids {
    let m = IsDefined(book) ? book.Find(id) : null;
    ArrayPush(words, IsDefined(m) ? CBCrewFirst(sys, m) : CBT(n"Cyberbane-Telling-Somebody"));
  }
  if CBSquadCount(game) > 0 {
    ArrayPush(words, CBT(n"Cyberbane-GangWar-TheSquads"));
  }
  return ArraySize(words) == 0 ? CBT(n"Cyberbane-GangWar-Nobody") : CBListWords(words);
}

// "A", "A and B", "A, B and C".
public func CBListWords(words: array<String>) -> String {
  let out = "";
  let n = ArraySize(words);
  let i = 0;
  while i < n {
    out = i == 0 ? words[i] : out + (i == n - 1 ? CBT(n"Cyberbane-CrewWar-And") : ", ") + words[i];
    i += 1;
  }
  return out;
}

// Where it happens, in a few words: "in Heywood", or out past a named part of the Badlands.
public func CBWarWhere(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> String {
  return CBPlacePhrase(CBWarOrderDistrict(sys, game, f), f.OrderPlace());
}

// The district an order is in: where their lieutenant was seen, else the place's own (read only while the world can
// answer, never on the paused Hub), else the district the war is fought in.
public func CBWarOrderDistrict(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> CName {
  if f.order == CBWarOrderLieutenant() && f.orderTarget > 0 {
    let r = sys.FindRivalById(f.orderTarget);
    let s = IsDefined(r) ? CBSightingFor(sys, r) : null;
    if IsDefined(s) && IsNameValid(s.district) {
      return s.district;
    }
  }
  if CBWarSpotKnown(f.OrderPlace()) && CBWorldStable(game) {
    let d = CBDistrictNear(sys, game, f.OrderPlace());
    if IsNameValid(d) {
      return d;
    }
  }
  return CBWarTargetDistrict(sys, game, f.gang);
}

// Where their move lands, in a few words: a corner's district, the crew's place or V's home.
public func CBWarMoveWhere(f: ref<CBWarFront>) -> String {
  if f.move == CBWarMoveCorner() {
    return CBPlacePhrase(CBDistrictAt(f.moveTarget), f.MovePlace());
  }
  if f.move == CBWarMoveRaid() {
    return CBT(n"Cyberbane-GangWar-AtTheHouse");
  }
  return "";
}

// Everybody on this war's order, free again.
func CBWarReleaseParty(game: GameInstance, kb: ref<CBCrewKitBook>, gang: CName) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(kb) || !IsDefined(book) {
    return;
  }
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    let k = IsDefined(m) ? kb.Find(m.id) : null;
    if IsDefined(k) && Equals(k.warOn, gang) {
      k.warOn = n"";
      k.warUntil = 0.0;
    }
  }
}

// Who is on this war's order.
public func CBWarParty(game: GameInstance, gang: CName) -> array<Int32> {
  let out: array<Int32>;
  let book = CBCrewBook.Get(game);
  let kb = CBCrewKitBook.Get(game);
  if !IsDefined(book) || !IsDefined(kb) {
    return out;
  }
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    let k = IsDefined(m) ? kb.Find(m.id) : null;
    if IsDefined(k) && Equals(k.warOn, gang) && k.warUntil > 0.0 {
      ArrayPush(out, m.id);
    }
  }
  return out;
}

// ---- The crew's weight in a fight ------------------------------------------------------------------------------------

// The party and the squads on an order, with what makes them better: V's second leading, V's own kills of theirs, a friend
// gang on the crew's side, and the plan done in order.
public func CBWarOurWeight(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, order: Int32, party: array<Int32>) -> Float {
  let ours = ArraySize(party) > 0 ? CBCrewPartyWarPower(sys, game, party, f.gang) : CBConfig.WarFootPower() * CBCrewFoothold(game, CBWarTargetDistrict(sys, game, f.gang));
  if ArrayContains(party, CBCrewSecondId(game)) {
    ours *= 1.0 + CBConfig.CrewSecondWarBonus();
  }
  // Run by the second while V was away: slightly worse.
  if f.orderBySecond {
    ours *= CBConfig.WarSecondRunsMult();
  }
  ours += CBSquadsWarWeight(game, f, order);
  ours *= 1.0 + CBCrewWarVHelp(game, f.gang, false);
  if IsNameValid(f.ally) {
    ours += CBConfig.WarAllyShare() * CBGangWarWeight(sys, game, f.ally, true);
  }
  let fb = CBWarFrontBook.Get(game);
  if IsDefined(fb) {
    let c = 0;
    while c < fb.ClientCount() {
      let client = fb.ClientAt(c);
      c += 1;
      if IsDefined(client) && client.full && NotEquals(client.gang, f.gang) && NotEquals(client.gang, f.ally) {
        ours += CBConfig.WarAllyShare() * 0.5 * CBGangWarWeight(sys, game, client.gang, true);
      }
    }
  }
  ours *= CBSquadsPlanMult(game, f);
  return MaxF(ours, 1.0);
}

// ---- Every few ticks ------------------------------------------------------------------------------------------------

public func CBGangWarTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(sys) || !IsDefined(fb) || !CBMyCrewOn() {
    return;
  }
  let now = CBGameSeconds(game);
  let day = CBWarDayAt(now);
  // A list first: a war that ends changes the book.
  let gangs: array<CName>;
  let i = 0;
  while i < fb.Count() {
    let f = fb.At(i);
    if IsDefined(f) {
      ArrayPush(gangs, f.gang);
    }
    i += 1;
  }
  for g in gangs {
    let f = fb.Find(g);
    if IsDefined(f) && f.night < day {
      CBWarNewDay(sys, game, fb, f, day, now);
    }
    f = fb.Find(g);
    if IsDefined(f) {
      CBWarFrontTick(sys, game, fb, f, now);
    }
  }
  CBWarCaptivesTick(sys, game, fb, now);
}

// A new day of the war (noon to noon): both sides wearier, ground the crew's guards are not holding drifts back, and terms.
func CBWarNewDay(sys: ref<CyberbaneSystem>, game: GameInstance, fb: ref<CBWarFrontBook>, f: ref<CBWarFront>, day: Int32, now: Float) -> Void {
  f.night = day;
  f.nights += 1;
  f.ourWeary = ClampF(f.ourWeary + CBConfig.WarWearyPerDay(), 0.0, 100.0);
  f.theirWeary = ClampF(f.theirWeary + CBConfig.WarWearyPerDay(), 0.0, 100.0);
  if f.front > 0.0 && !f.heldBehind {
    f.front = MaxF(0.0, f.front - CBConfig.WarFrontDrift());
  }
  f.heldBehind = false;
  f.ltGone = false;
  CBWarTermsCheck(sys, game, fb, f, now);
}

// Every few ticks: the order and their move, each a fight on screen the moment V reaches its place, otherwise settled
// at its deadline without V; the second's order after a while without one; their next move picked every few hours.
func CBWarFrontTick(sys: ref<CyberbaneSystem>, game: GameInstance, fb: ref<CBWarFrontBook>, f: ref<CBWarFront>, now: Float) -> Void {
  // An order given on the paused Hub: its place, pin and text now the world can answer.
  if fb.PlaceIsDue(f.gang) && CBWorldStable(game) {
    let lead = fb.TakeDuePlace(f.gang);
    if CBWarOrderFights(f.order) {
      let at: Vector4;
      if CBWarOrderSpot(sys, game, f, f.order, f.orderTarget, at) {
        f.SetOrderPlace(at);
      }
      CBWarOrderPlaced(sys, game, f, lead);
    }
  }
  // A friend on either side that cannot fight a gang's war (a corporation, a gang with no streets): let go.
  if IsNameValid(f.ally) && (CBIsCorpFaction(f.ally) || !CBGangHoldsTurf(sys, f.ally)) {
    f.ally = n"";
  }
  if IsNameValid(f.theirAlly) && (CBIsCorpFaction(f.theirAlly) || !CBGangHoldsTurf(sys, f.theirAlly)) {
    f.theirAlly = n"";
  }
  // Left done for the night by an older book: the next is due now.
  if f.orderDone {
    CBWarOrderFinished(game, f, now, false);
  }
  if f.moveDone {
    CBWarMoveScheduled(f, now);
  }
  // No order for a while: the second sends one (C6).
  if f.order == CBWarOrderNone() && now >= f.orderAt + CBConfig.WarSecondIdleHours() * CBConfig.SecondsPerHour() {
    CBWarSecondOrders(sys, game, f, now);
  }
  let orderHeld = false;
  if f.order != CBWarOrderNone() {
    orderHeld = CBWarOrderFights(f.order) && CBWarFightNear(sys, game, f, true, now);
    if fb.Find(f.gang) != f {
      return;
    }
    if !orderHeld && now >= f.orderAt {
      if f.order == CBWarOrderStorm() {
        // Their boss is only ever stormed with V there: the crew stands down until V gives the order again.
        CBWarOrderFinished(game, f, now, false);
        if CBMessagesOn() {
          CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-StormWaits", [CBCapFirst(CBFactionLabel(f.gang))]), true);
        }
      } else {
        CBWarResolveOrder(sys, game, f, 0);
      }
    }
  }
  if fb.Find(f.gang) != f {
    return;
  }
  if f.move == CBWarMoveNone() {
    if now >= f.moveAt {
      CBWarPickMove(sys, game, f, now);
    }
    return;
  }
  // One fight on screen at a time: while the order's fight is V's, their move happens without V.
  if !orderHeld && CBWarFightNear(sys, game, f, false, now) {
    return;
  }
  if now >= f.moveAt {
    CBWarResolveMove(sys, game, f, false);
  }
}

// The second sends an order when V has given none for a while (C6): their corners if the crew is strong enough, else a
// scout, else the crew holds. Without the second running the wars, nothing: the crew waits for V.
func CBWarSecondOrders(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, now: Float) -> Void {
  let book = CBCrewBook.Get(game);
  let second = CBCrewSecond(game);
  f.orderAt = now;   // asked again after another while, whatever comes of it
  if !IsDefined(book) || !IsDefined(second) || !CBSecondRunsWars() {
    return;
  }
  let party: array<Int32>;
  let i = 0;
  while i < book.Count() && ArraySize(party) < CBConfig.CrewWarPartyMax() {
    let m = book.At(i);
    i += 1;
    if CBCrewWarEligible(game, book, m, now) {
      ArrayPush(party, m.id);
    }
  }
  let order = CBWarOrderHold();
  let theirs = CBGangWarWeight(sys, game, f.gang) * CBWarOrderMeets(CBWarOrderCorners());
  if ArraySize(party) > 0 && CBCrewWarPartyLed(game, book, party) && CBWarOurWeight(sys, game, f, CBWarOrderCorners(), party) >= theirs * 0.9 {
    order = CBWarOrderCorners();
  } else {
    if now >= f.scoutUntil {
      order = CBWarOrderScout();
    }
  }
  CBGangWarGiveOrder(sys, game, f.gang, order, party, 0, true, false);
}

// ---- An order resolved -----------------------------------------------------------------------------------------------

// `vResult`: 0 off screen; otherwise the outcome of the fight V was in (CBWarOutcome*), plus 10 so it is never 0. Terms
// are looked at straight after, so a war can turn on one fight.
public func CBWarResolveOrder(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, vResult: Int32) -> Void {
  if !IsDefined(f) || f.orderDone || f.order == CBWarOrderNone() {
    return;
  }
  f.orderDone = true;
  let now = CBGameSeconds(game);
  let order = f.order;
  let party = CBWarParty(game, f.gang);
  if order == CBWarOrderScout() {
    CBWarScouted(sys, game, f, now);
  }
  if CBWarOrderFights(order) {
    let vThere = vResult > 0;
    let outcome = vThere ? vResult - 10 : CBWarOffScreenOutcome(sys, game, f, order, party);
    CBWarApplyOrder(sys, game, f, order, party, outcome, vThere, now);
  }
  let fb = CBWarFrontBook.Get(game);
  if IsDefined(fb) && fb.Find(f.gang) == f {
    CBWarOrderFinished(game, f, now, order != CBWarOrderHold());
    CBWarTermsCheck(sys, game, fb, f, now);
  }
}

func CBWarOffScreenOutcome(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, order: Int32, party: array<Int32>) -> Int32 {
  let ours = CBWarOurWeight(sys, game, f, order, party);
  let theirs = CBGangWarWeight(sys, game, f.gang) * CBWarOrderMeets(order);
  let now = CBGameSeconds(game);
  // Eyes on them first: the squad that goes in knows what it walks into. Blind, it may walk into an ambush.
  if now < f.scoutUntil {
    ours *= CBConfig.WarScoutedMult();
  } else {
    if RandF() < CBConfig.WarAmbushChance() {
      ours *= CBConfig.WarAmbushMult();
      CBLog.Info(n"War", "The order went in blind and walked into an ambush.");
    }
  }
  // A loose tongue sold the order (C6): they were waiting.
  if CBWarOrderSold(sys, game, f, party) {
    theirs *= CBConfig.WarSoldMult();
    f.sold = true;
  }
  let score = ours / MaxF(theirs, 1.0) * CBWarSwing();
  CBLog.Info(n"War", s"Order \(order) on \(NameToString(f.gang)): ours \(RoundF(ours)) against \(RoundF(theirs)), swung \(RoundF(score * 100.0))%.");
  return CBWarOutcomeOf(score);
}

public func CBWarOutcomeOf(score: Float) -> Int32 {
  if score >= 1.5 { return CBWarOutcomeDecisive(); }
  if score >= 1.0 { return CBWarOutcomeWon(); }
  if score >= 0.75 { return CBWarOutcomeStalemate(); }
  if score >= 0.45 { return CBWarOutcomeLost(); }
  return CBWarOutcomeRouted();
}

// Somebody of low loyalty on the order may have sold it to them.
func CBWarOrderSold(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, party: array<Int32>) -> Bool {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || CBSquadKindOn(game, CBSquadEyes()) {
    return false;   // lookouts catch their informants
  }
  for id in party {
    let m = book.Find(id);
    if IsDefined(m) && m.loyalty < CBConfig.MyCrewRestless() && RandF() < CBConfig.WarSellChance() {
      return true;
    }
  }
  return false;
}

func CBWarApplyOrder(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, order: Int32, party: array<Int32>,
                     outcome: Int32, vThere: Bool, now: Float) -> Void {
  let book = CBCrewBook.Get(game);
  let wb = CBWarBook.Get(game);
  let label = CBCapFirst(CBFactionLabel(f.gang));
  let won = outcome >= CBWarOutcomeWon();
  let decisive = outcome == CBWarOutcomeDecisive();
  let mult = vThere ? CBConfig.WarVThereMult() : 1.0;
  // The hitters opened the door: a lieutenant gone before the fighters hit their corner.
  if f.ltGone && order == CBWarOrderCorners() {
    mult *= 2.0;
    f.ltGone = false;
  }
  let push = 0.0;
  let theirMen = 0.0;
  let spoils = 0;
  let ltName = "";
  let ltFell = 0;
  if order == CBWarOrderCorners() {
    push = CBWarPush(outcome, 25.0, 15.0, 4.0, -8.0, -15.0);
    theirMen = won ? (decisive ? 10.0 : 6.0) : (outcome == CBWarOutcomeStalemate() ? 2.0 : 0.0);
    spoils = won ? CBReward(RoundF(CBConfig.WarCornerSpoils() * (decisive ? 1.5 : 1.0))) : 0;
  }
  if order == CBWarOrderStash() {
    push = CBWarPush(outcome, 10.0, 6.0, 1.0, -5.0, -10.0);
    theirMen = won ? 4.0 : 0.0;
    if won && IsDefined(wb) {
      let take = MinF(wb.Chest(f.gang), decisive ? CBConfig.WarStashTakeDecisive() : CBConfig.WarStashTake());
      wb.AddChest(f.gang, -take);
      spoils = CBReward(RoundF(take * CBConfig.WarStashKittyShare()));
      f.chestCut = true;
    }
  }
  if order == CBWarOrderLieutenant() {
    push = CBWarPush(outcome, 18.0, 12.0, 2.0, -8.0, -14.0);
    theirMen = won ? 3.0 : 0.0;
    // Won: they are dead or taken, unless V already put them down in person (then there is nothing left to fall).
    if won {
      let r = sys.FindRivalById(f.orderTarget);
      ltName = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "";
      ltFell = CBWarLieutenantFalls(sys, game, f, f.orderTarget, decisive);
    }
  }
  if order == CBWarOrderStorm() {
    if won {
      CBWarBreakGang(sys, game, f, now);
      return;
    }
    CBWarStormFailed(sys, game, f, now);
    return;
  }
  f.front = ClampF(f.front + push * mult, -100.0, 100.0);
  if theirMen > 0.0 {
    CBWarLoseMen(game, f.gang, theirMen);
    f.theirLost += RoundF(theirMen);
    f.theirWeary = ClampF(f.theirWeary + theirMen * 0.6, 0.0, 100.0);
    CBWeakenGang(sys, game, f.gang, theirMen * CBConfig.WarMenToStrength(), CBWarTargetDistrict(sys, game, f.gang));
  }
  if won {
    f.heldBehind = CBSquadKindOn(game, CBSquadWatch());
    CBWarGround(sys, game, f, decisive ? CBConfig.WarFootDecisive() * 0.5 : CBConfig.WarFootWon() * 0.5);
    CBSquadsDidJob(game, f, true);
  } else {
    CBSquadsDidJob(game, f, false);
  }
  if spoils > 0 {
    let jb = CBCrewJobBook.Get(game);
    if IsDefined(jb) {
      jb.AddKitty(IsNameValid(f.ally) ? RoundF(Cast<Float>(spoils) * (1.0 - CBConfig.WarAllySpoilsShare())) : spoils);
    }
  }
  // The crew's side of it: wins and loyalty, the hurt, the dead, the taken.
  let hurt: array<Int32>;
  let fallen: array<ref<CBCrewMember>>;
  CBWarPartyCost(sys, game, f, party, outcome, hurt, fallen, now);
  CBWarNoteCarried(game, f, party, won);
  if vThere {
    f.vNights += 1;
  }
  CBFileLog(sys, n"WarNight", now, CBDistrictNear(sys, game, f.OrderPlace()), f.gang, Cast<Float>(order * 10 + outcome + 1));
  // One text for it: what was done, how it went, and what it cost.
  if CBMessagesOn() {
    let line = CBWarResultLine(f, order, outcome, spoils, label);
    if ltFell == 1 {
      line = CBTf(n"Cyberbane-GangWar-LieutenantKilled", [ltName, label]);
    }
    if ltFell == 2 {
      line = CBTf(n"Cyberbane-GangWar-TookRival", [ltName]);
    }
    if f.sold {
      line = CBT(n"Cyberbane-GangWar-TheyWereWaiting") + " " + line;
    }
    if ArraySize(hurt) > 0 && IsDefined(book) {
      line += " " + CBTf(n"Cyberbane-GangWar-HurtTonight", [CBCrewNamesList(sys, book, hurt)]);
    }
    CBCrewText(sys, game, CBCrewSecond(game), line, true);
  }
  CBUiSound(game, won ? n"ui_phone_incoming_call_positive" : n"ui_phone_incoming_call_negative", n"WarResult", 5.0);
  CBCrewWarVHelp(game, f.gang, true);
  CBWarBury(sys, game, f, fallen, now);
}

func CBWarPush(outcome: Int32, decisive: Float, won: Float, stalemate: Float, lost: Float, routed: Float) -> Float {
  if outcome == CBWarOutcomeDecisive() { return decisive; }
  if outcome == CBWarOutcomeWon() { return won; }
  if outcome == CBWarOutcomeStalemate() { return stalemate; }
  if outcome == CBWarOutcomeLost() { return lost; }
  return routed;
}

public func CBWarResultLine(f: ref<CBWarFront>, order: Int32, outcome: Int32, spoils: Int32, label: String) -> String {
  let won = outcome >= CBWarOutcomeWon();
  if order == CBWarOrderCorners() {
    if won { return spoils > 0 ? CBTf(n"Cyberbane-GangWar-CornersWonPaid", [label, s"\(spoils)"]) : CBTf(n"Cyberbane-GangWar-CornersWon", [label]); }
    if outcome == CBWarOutcomeStalemate() { return CBTf(n"Cyberbane-GangWar-CornersEven", [label]); }
    return CBTf(n"Cyberbane-GangWar-CornersLost", [label]);
  }
  if order == CBWarOrderStash() {
    if won { return CBTf(n"Cyberbane-GangWar-StashWon", [label, s"\(spoils)"]); }
    return CBTf(n"Cyberbane-GangWar-StashLost", [label]);
  }
  if order == CBWarOrderLieutenant() {
    if won { return CBTf(n"Cyberbane-GangWar-LieutenantWon", [label]); }
    return CBTf(n"Cyberbane-GangWar-LieutenantLost", [label]);
  }
  return "";
}

// The crew's losses in a fight: hurt by how it went, the weakest first; a bad fight can kill, or leave one taken alive.
// The medics halve deaths and time out; somebody loyal may take a hit meant for another (C6).
func CBWarPartyCost(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, party: array<Int32>, outcome: Int32,
                    out hurt: array<Int32>, out fallen: array<ref<CBCrewMember>>, now: Float) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || ArraySize(party) == 0 {
    return;
  }
  let cutters = CBSquadKindOn(game, CBSquadCutters());
  let hurtHours = CBConfig.CrewWarHurtHours() * (cutters ? 0.5 : 1.0) * CBCrewHealFactorNow(game);
  let deathMult = cutters ? 0.5 : 1.0;
  let weakest: ref<CBCrewMember>;
  for id in party {
    let m = book.Find(id);
    if IsDefined(m) && (!IsDefined(weakest) || CBCrewMemberWarPower(game, m) < CBCrewMemberWarPower(game, weakest)) {
      weakest = m;
    }
  }
  let won = outcome >= CBWarOutcomeWon();
  for id in party {
    let m = book.Find(id);
    if IsDefined(m) {
      if won {
        m.wins += outcome == CBWarOutcomeDecisive() ? 2 : 1;
        m.loyalty = Min(100, m.loyalty + 2);
        if m == weakest && outcome == CBWarOutcomeWon() && RandF() < CBConfig.WarWonHurtChance() * 0.5 {
          m.hurtUntil = now + 0.4 * hurtHours * CBConfig.SecondsPerHour();
          ArrayPush(hurt, m.id);
        }
      } else {
        let die = 0.0;
        let take = 0.0;
        if outcome == CBWarOutcomeRouted() {
          die = (CBConfig.WarRoutDeathBase() + (m == weakest ? CBConfig.WarRoutDeathSpread() : 0.0)) * deathMult;
          take = CBConfig.WarTakenChance();
        } else {
          if outcome == CBWarOutcomeLost() && m == weakest {
            die = CBConfig.CrewWarDeathShare() * 0.4 * deathMult;
            take = CBConfig.WarTakenChance() * 0.5;
          }
        }
        let roll = RandF();
        if roll < die {
          let saved = CBWarSomebodyTakesTheHit(game, book, party, m);
          if IsDefined(saved) {
            saved.hurtUntil = now + hurtHours * CBConfig.SecondsPerHour();
            ArrayPush(hurt, saved.id);
            m.hurtUntil = now + 0.5 * hurtHours * CBConfig.SecondsPerHour();
            ArrayPush(hurt, m.id);
          } else {
            ArrayPush(fallen, m);
            f.ourLost += 1;
          }
        } else {
          if roll < die + take && CBWarTakeCaptive(sys, game, f, m, now) {
            f.ourLost += 1;
          } else {
            if outcome != CBWarOutcomeStalemate() || RandF() < 0.5 {
              let share = outcome == CBWarOutcomeRouted() ? 1.0 : (outcome == CBWarOutcomeLost() ? 0.6 : 0.4);
              m.hurtUntil = now + share * hurtHours * CBConfig.SecondsPerHour();
              m.loyalty = Max(0, m.loyalty - (outcome == CBWarOutcomeRouted() ? 5 : 2));
              ArrayPush(hurt, m.id);
              CBCrewMaybeScar(sys, game, m, outcome == CBWarOutcomeRouted());
            }
          }
        }
      }
    }
  }
  f.ourWeary = ClampF(f.ourWeary + Cast<Float>(ArraySize(fallen)) * 12.0 + Cast<Float>(ArraySize(hurt)) * 3.0, 0.0, 100.0);
  // After a rout, somebody who has had enough walks (C6).
  if outcome == CBWarOutcomeRouted() {
    CBWarRoutWalkout(sys, game, book, party);
  }
}

// Somebody loyal on the same order steps in front of it: hurt instead of a friend dead.
func CBWarSomebodyTakesTheHit(game: GameInstance, book: ref<CBCrewBook>, party: array<Int32>, doomed: ref<CBCrewMember>) -> ref<CBCrewMember> {
  for id in party {
    let m = book.Find(id);
    if IsDefined(m) && m != doomed && m.loyalty >= CBConfig.WarTakeHitLoyalty() && !CBCrewHurt(m, CBGameSeconds(game))
       && RandF() < CBConfig.WarTakeHitChance() {
      return m;
    }
  }
  return null;
}

func CBWarRoutWalkout(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, party: array<Int32>) -> Void {
  for id in party {
    let m = book.Find(id);
    if IsDefined(m) && m.loyalty < CBConfig.MyCrewBetrayLine() + 10 && RandF() < CBConfig.WarWalkoutChance() {
      let name = CBCrewFirst(sys, m);
      book.Remove(m, CBCrewEndWalked(), 0, CBEventDistrict(sys, game), CBGameSeconds(game));
      if CBMessagesOn() {
        CBCrewText(sys, game, null, CBTf(n"Cyberbane-GangWar-WalkedAfterRout", [name]), true);
      }
      return;   // one at most, and the roster changed
    }
  }
}

func CBWarNoteCarried(game: GameInstance, f: ref<CBWarFront>, party: array<Int32>, won: Bool) -> Void {
  if !won || ArraySize(party) == 0 {
    return;
  }
  let book = CBCrewBook.Get(game);
  let best: ref<CBCrewMember>;
  for id in party {
    let m = IsDefined(book) ? book.Find(id) : null;
    if IsDefined(m) && (!IsDefined(best) || CBCrewMemberWarPower(game, m) > CBCrewMemberWarPower(game, best)) {
      best = m;
    }
  }
  if !IsDefined(best) {
    return;
  }
  if best.id == f.carried {
    f.carriedScore += 1;
  } else {
    if f.carriedScore <= 1 {
      f.carried = best.id;
      f.carriedScore = 1;
    } else {
      f.carriedScore -= 1;
    }
  }
}

// The fallen, last: taking them off the roster changes the book.
func CBWarBury(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, fallen: array<ref<CBCrewMember>>, now: Float) -> Void {
  let book = CBCrewBook.Get(game);
  let bb = CBCrewBannerBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  let where = CBGangHomeDistrict(sys, game, f.gang);
  for m in fallen {
    let name = CBCrewName(sys, m);
    if IsDefined(bb) {
      bb.fallCause = CBCrewFellAtWar();
      bb.fallGang = f.gang;
    }
    book.Remove(m, CBCrewEndFell(), 0, where, now);
    if CBMessagesOn() {
      CBPhoneSendTinted(game, CBPhoneGangSender(f.gang), CBTf(n"Cyberbane-CrewKit-CameForUsIsnTComing", [s"\(name)", s"\(name)"]), CBHudRed());
    }
  }
  if ArraySize(fallen) > 0 {
    CBCrewGroupReplies(sys, game, 3, 0);
  }
}

// A won fight's ground, against the gang fought only (F2): its own streets where it holds them, never a third gang's.
public func CBWarGround(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, amount: Float) -> Void {
  let held = CBGangHeldDistricts(sys, game, f.gang);
  if ArraySize(held) == 0 {
    return;   // nothing of theirs to take: the win weakened them and paid, and that is all
  }
  let home = CBGangHomeDistrict(sys, game, f.gang);
  let target = ArrayContains(held, home) ? home : held[0];
  CBCrewTurfRaise(sys, game, target, amount);
  CBHoodsWarGain(sys, game, f.gang, target, amount);
}

// Districts this gang holds right now.
public func CBGangHeldDistricts(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> array<CName> {
  let out: array<CName>;
  let i = 0;
  while i < CBDistrictCount() {
    let d = CBDistrictAt(i);
    if Equals(CBTurfHolder(sys, game, d), gang) {
      ArrayPush(out, d);
    }
    i += 1;
  }
  return out;
}

// ---- A scout, a lieutenant, their boss -------------------------------------------------------------------------------

func CBWarScouted(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, now: Float) -> Void {
  // Without eyes of their own, scouts are sometimes seen.
  if !CBSquadKindOn(game, CBSquadEyes()) && RandF() < CBConfig.WarScoutCaughtChance() {
    if CBMessagesOn() {
      CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-ScoutCaught", [CBCapFirst(CBFactionLabel(f.gang))]), true);
    }
    return;
  }
  f.scoutUntil = now + CBConfig.WarScoutDays() * CBConfig.SecondsPerDay();
  // Their next move, known now.
  if f.move != CBWarMoveNone() && !f.moveDone && !f.moveTold {
    f.moveTold = true;
    CBWarTellMove(sys, game, f, true);
  }
  CBWarLooseTongue(sys, game, f.gang);   // where one of their Rivals sleeps
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-Scouted", [CBFactionLabel(f.gang), s"\(RoundF(CBGangWarWeight(sys, game, f.gang)))"]), true);
  }
}

// One of their lieutenants, gone off screen: dead (1), or taken alive to bargain with (2); 0 when there was nobody left
// to fall. The order's own text says which.
func CBWarLieutenantFalls(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, id: Int32, decisive: Bool) -> Int32 {
  let r = sys.FindRivalById(id);
  if !IsDefined(r) || (r.state != EnumInt(ECBRivalState.Active) && r.state != EnumInt(ECBRivalState.Hunting)) {
    return 0;
  }
  f.ltGone = true;
  f.theirWeary = ClampF(f.theirWeary + 10.0, 0.0, 100.0);
  let fb = CBWarFrontBook.Get(game);
  if IsDefined(fb) && RandF() < (decisive ? 0.6 : 0.4) {
    r.state = EnumInt(ECBRivalState.Retired);
    fb.AddPrisoner(r.id, f.gang);
    CBFileLog(sys, n"WarTookRival", CBGameSeconds(game), f.place, f.gang, Cast<Float>(r.id));
    return 2;
  }
  CBRivalSlain(sys, game, r, CBGameSeconds(game), f.place, false);
  return 1;
}

// Their boss stormed and beaten with V there (W7): the gang is broken for weeks, its streets open, and the war is over for good.
public func CBWarBreakGang(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, now: Float) -> Void {
  let wb = CBWarBook.Get(game);
  if IsDefined(wb) {
    wb.AddMen(f.gang, -100.0);
    wb.AddChest(f.gang, -wb.Chest(f.gang));
  }
  CBWeakenGang(sys, game, f.gang, 100.0, CBGangHomeDistrict(sys, game, f.gang));
  let fbB = CBWarFrontBook.Get(game);
  if IsDefined(fbB) {
    fbB.SetBroken(f.gang, now + CBConfig.WarBrokenDays() * CBConfig.SecondsPerDay());
  }
  let held = CBGangHeldDistricts(sys, game, f.gang);
  for d in held {
    CBCrewTurfRaise(sys, game, d, CBConfig.WarFootDecisive());
    CBHoodsWarGain(sys, game, f.gang, d, CBConfig.WarFootDecisive());
  }
  let jb = CBCrewJobBook.Get(game);
  if IsDefined(jb) {
    jb.AddKitty(CBReward(CBConfig.WarBreakSpoils()));
  }
  CBWarDefector(sys, game, CBCrewBook.Get(game), f.gang);
  CBSquadsGainHeads(game, CBConfig.WarBrokenHeads());
  CBWarEnd(sys, game, f, CBWarEndBroken(), now);
}

func CBWarStormFailed(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, now: Float) -> Void {
  let party = CBWarParty(game, f.gang);
  let hurt: array<Int32>;
  let fallen: array<ref<CBCrewMember>>;
  CBWarPartyCost(sys, game, f, party, CBWarOutcomeRouted(), hurt, fallen, now);
  CBWarBury(sys, game, f, fallen, now);
  f.front = -50.0;
  f.ourWeary = ClampF(f.ourWeary + 30.0, 0.0, 100.0);
  f.state = CBWarStateOn();
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-StormFailed", [CBCapFirst(CBFactionLabel(f.gang))]), true);
  }
}

// ---- Their move (W4) ------------------------------------------------------------------------------------------------

// Their next move (W4), every few hours: what, and where, close to V when it has a place. Known ahead when the crew has
// eyes on them or an informant in their ranks; otherwise the crew hears of it only as it starts, with little time to get
// there. A move with no place lands as news.
func CBWarPickMove(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, now: Float) -> Void {
  let kinds: array<Int32>;
  let held = CBCrewHeldDistricts(sys, game);
  if ArraySize(held) > 0 { ArrayPush(kinds, CBWarMoveCorner()); ArrayPush(kinds, CBWarMoveCorner()); }
  if CBWarAmbushTarget(game) > 0 { ArrayPush(kinds, CBWarMoveAmbush()); }
  let gb = CBGuardBook.Get(game);
  if (IsDefined(gb) && gb.Count() > 0) || CBCrewPlaceSet(game) { ArrayPush(kinds, CBWarMoveRaid()); ArrayPush(kinds, CBWarMoveRaid()); }
  if CBCrewSecondId(game) > 0 { ArrayPush(kinds, CBWarMovePrice()); }
  if IsNameValid(f.ally) || IsNameValid(CBWarFriendOfV(sys, game, f.gang)) { ArrayPush(kinds, CBWarMoveLean()); }
  if !IsNameValid(f.theirAlly) && IsNameValid(CBWarCoalitionPartner(sys, game, f.gang)) { ArrayPush(kinds, CBWarMoveCoalition()); }
  // A broken gang licks its wounds.
  let wb = CBWarBook.Get(game);
  let men = IsDefined(wb) ? wb.Men(f.gang) : 100.0;
  if ArraySize(kinds) == 0 || men < CBConfig.WarMenFloor() || RandF() < CBConfig.WarQuietMoveChance() {
    CBWarMoveScheduled(f, now);
    return;
  }
  f.move = kinds[RandRange(0, ArraySize(kinds))];
  f.moveDone = false;
  f.moveTarget = 0;
  let at: Vector4;
  let placed = false;
  if f.move == CBWarMoveCorner() {
    let d = held[RandRange(0, ArraySize(held))];
    f.moveTarget = CBDistrictIndex(d);
    placed = CBWarPlaceNear(sys, game, d, at);
  }
  if f.move == CBWarMoveAmbush() {
    f.moveTarget = CBWarAmbushTarget(game);
  }
  if f.move == CBWarMoveRaid() {
    placed = CBWarRaidSpot(game, at);
  }
  f.SetMovePlace(placed ? at : new Vector4(0.0, 0.0, 0.0, 1.0));
  let ahead = now < f.scoutUntil || (CBSquadKindOn(game, CBSquadEyes()) && RandF() < CBConfig.WarEyesWarnChance()) || CBHasInformantIn(sys, f.gang);
  f.moveAt = now + (ahead ? CBConfig.WarMoveToldHours() : CBConfig.WarMoveRushHours()) * CBConfig.SecondsPerHour();
  f.moveTold = ahead || placed;
  if f.moveTold {
    CBWarTellMove(sys, game, f, ahead);
  }
  CBLog.Info(n"War", s"\(NameToString(f.gang))'s move: \(f.move) by \(CBClockWord(f.moveAt)) (told ahead: \(ahead), placed: \(placed)).");
}

// Their next move picked in a few hours: after a quiet stretch, or after the last one landed.
func CBWarMoveScheduled(f: ref<CBWarFront>, now: Float) -> Void {
  f.move = CBWarMoveNone();
  f.moveDone = false;
  f.moveTold = false;
  f.moveTarget = 0;
  f.SetMovePlace(new Vector4(0.0, 0.0, 0.0, 1.0));
  f.moveAt = now + RandRangeF(CBConfig.WarMoveGapMinHours(), CBConfig.WarMoveGapMaxHours()) * CBConfig.SecondsPerHour();
}

// The crew hears of it: ahead, with the place and the hour so V can be there; or as it starts, with the place, now.
func CBWarTellMove(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, ahead: Bool) -> Void {
  if !CBMessagesOn() {
    return;
  }
  let label = CBCapFirst(CBFactionLabel(f.gang));
  let line = "";
  if f.move == CBWarMoveCorner() {
    let d = CBDistrictLabel(CBDistrictAt(f.moveTarget));
    line = ahead ? CBTf(n"Cyberbane-GangWar-MoveCornerTold", [label, d, CBClockWord(f.moveAt)]) : CBTf(n"Cyberbane-GangWar-MoveCornerNow", [label, d]);
  }
  if f.move == CBWarMoveAmbush() {
    let book = CBCrewBook.Get(game);
    let m = IsDefined(book) ? book.Find(f.moveTarget) : null;
    line = CBTf(n"Cyberbane-GangWar-MoveAmbushTold", [label, CBCrewFirst(sys, m)]);
  }
  if f.move == CBWarMoveRaid() {
    line = ahead ? CBTf(n"Cyberbane-GangWar-MoveRaidTold", [label, CBClockWord(f.moveAt)]) : CBTf(n"Cyberbane-GangWar-MoveRaidNow", [label]);
  }
  if f.move == CBWarMovePrice() { line = CBTf(n"Cyberbane-GangWar-MovePriceTold", [label, CBCrewFirst(sys, CBCrewSecond(game))]); }
  if f.move == CBWarMoveLean() { line = CBTf(n"Cyberbane-GangWar-MoveLeanTold", [label]); }
  if f.move == CBWarMoveCoalition() { line = CBTf(n"Cyberbane-GangWar-MoveCoalitionTold", [label, CBFactionLabel(CBWarCoalitionPartner(sys, game, f.gang))]); }
  CBCrewText(sys, game, CBCrewSecond(game), line, true, !ahead && CBWarSpotKnown(f.MovePlace()));
}

// Their move happens. `vHeld`: V and the crew met it on screen and held. Their next is picked in a few hours, and terms
// are looked at straight after.
public func CBWarResolveMove(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, vHeld: Bool) -> Void {
  if !IsDefined(f) || f.moveDone || f.move == CBWarMoveNone() {
    return;
  }
  CBWarMoveLands(sys, game, f, vHeld);
  let fb = CBWarFrontBook.Get(game);
  let now = CBGameSeconds(game);
  if IsDefined(fb) && fb.Find(f.gang) == f {
    CBWarMoveScheduled(f, now);
    CBWarTermsCheck(sys, game, fb, f, now);
  }
}

func CBWarMoveLands(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, vHeld: Bool) -> Void {
  f.moveDone = true;
  let now = CBGameSeconds(game);
  let label = CBCapFirst(CBFactionLabel(f.gang));
  // The hitters got to whoever was to lead it: called off.
  if f.ltGone && CBSquadKindOn(game, CBSquadKnives()) {
    f.ltGone = false;
    if CBMessagesOn() && f.moveTold {
      CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-MoveCalledOff", [label]), true);
    }
    return;
  }
  let strike = CBGangWarWeight(sys, game, f.gang) * CBConfig.WarMoveMeets();
  let defence = CBWarDefenceWeight(sys, game, f);
  let met = vHeld ? 100.0 : defence / MaxF(strike, 1.0) * CBWarSwing();
  let held = vHeld || met >= 1.0;
  let line = "";
  if f.move == CBWarMoveCorner() {
    let d = CBDistrictAt(f.moveTarget);
    if held {
      CBCrewTurfRaise(sys, game, d, CBConfig.WarCornerHeldFoot());
      line = CBTf(n"Cyberbane-GangWar-MoveCornerHeld", [label, CBDistrictLabel(d)]);
      f.front = ClampF(f.front + (vHeld ? 10.0 : 4.0), -100.0, 100.0);
    } else {
      CBCrewTurfRaise(sys, game, d, -CBConfig.WarCornerLostFoot());
      line = CBTf(n"Cyberbane-GangWar-MoveCornerLost", [label, CBDistrictLabel(d)]);
      f.front = ClampF(f.front - 8.0, -100.0, 100.0);
    }
  }
  if f.move == CBWarMoveAmbush() {
    let book = CBCrewBook.Get(game);
    let m = IsDefined(book) ? book.Find(f.moveTarget) : null;
    if IsDefined(m) {
      if held || CBSquadKindOn(game, CBSquadWatch()) {
        line = CBTf(n"Cyberbane-GangWar-MoveAmbushFailed", [label, CBCrewFirst(sys, m)]);
      } else {
        if RandF() < CBConfig.WarTakenChance() && CBWarTakeCaptive(sys, game, f, m, now) {
          line = "";   // the gang texts its price itself
        } else {
          m.hurtUntil = now + CBConfig.CrewWarHurtHours() * 0.6 * CBCrewHealFactorNow(game) * CBConfig.SecondsPerHour();
          line = CBTf(n"Cyberbane-GangWar-MoveAmbushHurt", [label, CBCrewFirst(sys, m)]);
          f.front = ClampF(f.front - 5.0, -100.0, 100.0);
        }
      }
    }
  }
  if f.move == CBWarMoveRaid() {
    if held {
      line = CBTf(n"Cyberbane-GangWar-MoveRaidHeld", [label]);
    } else {
      let jb = CBCrewJobBook.Get(game);
      let took = IsDefined(jb) ? RoundF(Cast<Float>(jb.Kitty()) * CBConfig.WarRaidKittyShare()) : 0;
      if took > 0 {
        jb.AddKitty(-took);
      }
      CBGuardsHurt(game, now);
      line = CBTf(n"Cyberbane-GangWar-MoveRaidLost", [label, s"\(took)"]);
      f.front = ClampF(f.front - 6.0, -100.0, 100.0);
    }
  }
  if f.move == CBWarMovePrice() {
    let second = CBCrewSecond(game);
    let book2 = CBCrewBook.Get(game);
    if IsDefined(second) && IsDefined(book2) {
      if held || book2.IsOut(second.id) || CBSquadKindOn(game, CBSquadWatch()) || CBSquadKindOn(game, CBSquadKnives()) {
        line = CBTf(n"Cyberbane-GangWar-MovePriceFailed", [label, CBCrewFirst(sys, second)]);
      } else {
        second.hurtUntil = now + CBConfig.CrewWarHurtHours() * CBCrewHealFactorNow(game) * CBConfig.SecondsPerHour();
        line = CBTf(n"Cyberbane-GangWar-MovePriceHit", [label, CBCrewFirst(sys, second)]);
        f.ourWeary = ClampF(f.ourWeary + 8.0, 0.0, 100.0);
      }
    }
  }
  if f.move == CBWarMoveLean() {
    let friend = IsNameValid(f.ally) ? f.ally : CBWarFriendOfV(sys, game, f.gang);
    if IsNameValid(friend) {
      if Equals(friend, f.ally) {
        f.ally = n"";
      }
      CBTalkSlight(sys, game, friend, CBConfig.WarLeanStanding());
      line = CBTf(n"Cyberbane-GangWar-MoveLeanDone", [label, CBFactionLabel(friend)]);
    }
  }
  if f.move == CBWarMoveCoalition() {
    let partner = CBWarCoalitionPartner(sys, game, f.gang);
    if IsNameValid(partner) {
      f.theirAlly = partner;
      line = CBTf(n"Cyberbane-GangWar-MoveCoalitionDone", [label, CBFactionLabel(partner)]);
    }
  }
  CBFileLog(sys, n"WarMove", now, f.place, f.gang, Cast<Float>(f.move * 10 + (held ? 1 : 0)));
  if StrLen(line) > 0 && CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), line, true);
  }
}

// What meets their move: the crew's hold on its streets, the guards at home, the guard squads and the fighters, the one
// who runs the place, and everybody at full weight while the crew holds.
func CBWarDefenceWeight(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> Float {
  let d = CBConfig.WarDefenceBase() + CBConfig.WarDefencePerWeight() * CBCrewWeight(game);
  let gb = CBGuardBook.Get(game);
  if IsDefined(gb) {
    d += CBConfig.WarDefencePerGuard() * Cast<Float>(gb.Count());
  }
  d += CBSquadsDefence(game, f);
  if f.move == CBWarMoveCorner() {
    d += CBRunnerDefence(game, CBDistrictAt(f.moveTarget));
    if CBSquadStanding(game, CBSquadGuns(), 1) {
      d *= CBConfig.SquadMeetMult();   // fighters set to meet counterattacks
    }
  }
  if f.move == CBWarMoveRaid() && CBSquadStanding(game, CBSquadWatch(), 2) {
    d *= CBConfig.SquadMeetMult();     // guards set to guard V's home
  }
  if f.order == CBWarOrderHold() {
    d *= CBConfig.WarHoldMult();
  }
  if IsNameValid(f.ally) {
    d += CBConfig.WarAllyShare() * 0.5 * CBGangWarWeight(sys, game, f.ally, true);
  }
  return d;
}

// A member out on a job or away, for an ambush. 0 when none.
func CBWarAmbushTarget(game: GameInstance) -> Int32 {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) {
    return 0;
  }
  let now = CBGameSeconds(game);
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && CBCrewJobAway(game, m.id, now) {
      return m.id;
    }
  }
  return 0;
}

// The crew's place, or V's home door.
func CBWarRaidSpot(game: GameInstance, out at: Vector4) -> Bool {
  if CBCrewPlaceAt(game, at) {
    return true;
  }
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) && lb.HomeSet() {
    at = lb.HomeAt();
    return true;
  }
  return false;
}

// A gang friendly or allied with V that they can lean on to stay out, or that V can ask in: a gang with streets, never
// a corporation (Militech was asked into a war on Maelstrom). n"" for none.
func CBWarFriendOfV(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> CName {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return n"";
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && NotEquals(fs.id, gang) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) && CBGangHoldsTurf(sys, fs.id) {
      let p = score.GetPosture(fs.id);
      if Equals(p, ECBPosture.Friendly) || Equals(p, ECBPosture.Allied) {
        return fs.id;
      }
    }
  }
  return n"";
}

// A gang that would join them against the crew: their truce partner, or one that hates the crew too.
func CBWarCoalitionPartner(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> CName {
  let truce = CBTrucePartner(game, gang);
  if IsNameValid(truce) {
    return truce;
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && NotEquals(fs.id, gang) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id)
       && CBCrewStandingWith(game, fs.id) <= -CBConfig.WarCoalitionHate() && !IsDefined(CBGangWarFront(game, fs.id)) {
      return fs.id;
    }
  }
  return n"";
}

func CBHasInformantIn(sys: ref<CyberbaneSystem>, gang: CName) -> Bool {
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, gang) && r.state == EnumInt(ECBRivalState.Debtor) {
      return true;
    }
  }
  return false;
}

// ---- Friends in the war (W5) ----------------------------------------------------------------------------------------

// A gang friendly or allied with V that could be asked in: n"" when none, or when one is already in.
public func CBWarAskableFriend(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> CName {
  if !IsDefined(f) || IsNameValid(f.ally) {
    return n"";
  }
  let friend = CBWarFriendOfV(sys, game, f.gang);
  return NotEquals(friend, f.theirAlly) ? friend : n"";
}

// Asked in: their weight on the crew's side for the rest of the war, a share of the spoils, a favour owed, and the
// enemy's hate.
public func CBWarAskFriendIn(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> Bool {
  let friend = CBWarAskableFriend(sys, game, f);
  if !IsNameValid(friend) {
    return false;
  }
  f.ally = friend;
  CBTalkSlight(sys, game, friend, CBConfig.WarAllyFavourCost());
  CBCrewStandingShift(game, friend, CBConfig.CrewStandWarEnemy());
  if CBMessagesOn() {
    CBAllyAnswerLater(game, friend, CBTf(n"Cyberbane-GangWar-AllyIn", [CBCapFirst(CBFactionLabel(f.gang))]));
  }
  CBFileLog(sys, n"WarAlly", CBGameSeconds(game), f.place, friend, 0.0);
  return true;
}

// ---- Terms and the end (W7) -----------------------------------------------------------------------------------------

func CBWarTermsCheck(sys: ref<CyberbaneSystem>, game: GameInstance, fb: ref<CBWarFrontBook>, f: ref<CBWarFront>, now: Float) -> Void {
  // An offer left too long is withdrawn.
  if (f.state == CBWarStateTheyAsk() || f.state == CBWarStateTheyDemand()) && now > f.termsUntil {
    f.state = CBWarStateOn();
    f.terms = 0;
  }
  if f.state != CBWarStateOn() {
    return;
  }
  if f.theirWeary >= CBConfig.WarTermsWeary() || f.front >= CBConfig.WarTermsFront() {
    f.state = CBWarStateTheyAsk();
    f.termsUntil = now + CBConfig.WarTermsDays() * CBConfig.SecondsPerDay();
    if CBMessagesOn() {
      CBPhoneFromGang(game, f.gang, CBGangBossSigned(sys, game, f.gang, CBT(n"Cyberbane-GangWar-TheyAskTerms")));
    }
    CBLog.Info(n"War", s"\(NameToString(f.gang)) ask for terms.");
    return;
  }
  if f.ourWeary >= CBConfig.WarTermsWeary() || f.front <= -CBConfig.WarTermsFront() {
    f.state = CBWarStateTheyDemand();
    f.terms = CBWarDemandFor(game, f);
    f.termsUntil = now + CBConfig.WarTermsDays() * CBConfig.SecondsPerDay();
    if CBMessagesOn() {
      CBPhoneFromGang(game, f.gang, CBGangBossSigned(sys, game, f.gang, CBTf(n"Cyberbane-GangWar-TheyDemandTerms", [CBWarTermsWord(sys, game, f, f.terms)])));
    }
    CBLog.Info(n"War", s"\(NameToString(f.gang)) demand terms of the crew.");
  }
}

// What a winning gang asks: money when the crew has a kitty, the ground back when it holds theirs, else somebody.
func CBWarDemandFor(game: GameInstance, f: ref<CBWarFront>) -> Int32 {
  let jb = CBCrewJobBook.Get(game);
  if IsDefined(jb) && jb.Kitty() >= CBWarDemandPrice(game, f) {
    return CBTermsPay();
  }
  if CBCrewFoothold(game, f.place) > 0.1 {
    return CBTermsGiveGround();
  }
  return CBTermsPay();
}

public func CBWarDemandPrice(game: GameInstance, f: ref<CBWarFront>) -> Int32 {
  return CBReward(CBConfig.WarDemandBase() + RoundF(CBConfig.WarDemandPerWeary() * f.ourWeary));
}

// The terms the crew can take from a gang that asks, as offered (the Hub's terms screen): tribute, a district's ground, a
// lieutenant handed over, or the gang as a client.
public func CBWarTermsOffered(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> array<Int32> {
  let out: array<Int32>;
  if !IsDefined(f) || f.state != CBWarStateTheyAsk() {
    return out;
  }
  ArrayPush(out, CBTermsTribute());
  let theirStreets = CBGangHeldDistricts(sys, game, f.gang);   // a named list, never a call's result straight into ArraySize
  if ArraySize(theirStreets) > 0 {
    ArrayPush(out, CBTermsGround());
  }
  if CBWarLieutenantTarget(sys, game, f.gang) > 0 {
    ArrayPush(out, CBTermsHandOver());
  }
  if f.front >= CBConfig.WarClientFront() {
    ArrayPush(out, CBTermsClient());
  }
  return out;
}

public func CBWarTribute(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Int32 {
  return CBReward(CBConfig.WarTributeBase() + RoundF(CBConfig.WarTributePerStrength() * CBGangStrength(sys, gang)));
}

public func CBWarTermsWord(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, terms: Int32) -> String {
  if terms == CBTermsTribute() { return CBTf(n"Cyberbane-GangWar-TermsTribute", [s"\(CBWarTribute(sys, game, f.gang))"]); }
  if terms == CBTermsGround() { return CBT(n"Cyberbane-GangWar-TermsGround"); }
  if terms == CBTermsHandOver() {
    let r = sys.FindRivalById(CBWarLieutenantTarget(sys, game, f.gang));
    return CBTf(n"Cyberbane-GangWar-TermsHandOver", [IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : CBT(n"Cyberbane-GangWar-ALieutenant")]);
  }
  if terms == CBTermsClient() { return CBT(n"Cyberbane-GangWar-TermsClient"); }
  if terms == CBTermsPay() { return CBTf(n"Cyberbane-GangWar-TermsPay", [s"\(CBWarDemandPrice(game, f))"]); }
  if terms == CBTermsGiveGround() { return CBT(n"Cyberbane-GangWar-TermsGiveGround"); }
  if terms == CBTermsGiveSomebody() { return CBT(n"Cyberbane-GangWar-TermsGiveSomebody"); }
  return "";
}

// The crew takes terms from a gang that asked. Only words and books.
public func CBWarTakeTerms(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, terms: Int32) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(f) || !IsDefined(fb) || f.state != CBWarStateTheyAsk() {
    return false;
  }
  let now = CBGameSeconds(game);
  if terms == CBTermsTribute() || terms == CBTermsClient() {
    let c = new CBWarClient();
    c.gang = f.gang;
    c.since = now;
    c.tribute = CBWarTribute(sys, game, f.gang);
    c.paidAt = now;
    c.full = terms == CBTermsClient();
    fb.AddClient(c);
    if terms == CBTermsClient() {
      CBTalkWarm(sys, game, f.gang, CBConfig.WarClientWarmth(), CBConfig.PostureAllied() + 1.0);
      CBCrewStandingShift(game, f.gang, CBConfig.CrewStandWarWon());
      CBSquadsGainHeads(game, CBConfig.WarClientHeads());
    }
  }
  if terms == CBTermsGround() {
    CBWarGround(sys, game, f, CBConfig.WarFootDecisive());
  }
  if terms == CBTermsHandOver() {
    let r = sys.FindRivalById(CBWarLieutenantTarget(sys, game, f.gang));
    if IsDefined(r) {
      r.state = EnumInt(ECBRivalState.Retired);
      fb.AddPrisoner(r.id, f.gang);
    }
  }
  CBWarEnd(sys, game, f, CBWarEndTerms(), now);
  return true;
}

// Terms refused: to the end. Their boss is the last move, stormed with V there.
public func CBWarRefuseTerms(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> Void {
  if !IsDefined(f) || f.state != CBWarStateTheyAsk() {
    return;
  }
  f.state = CBWarStateToTheEnd();
  f.terms = 0;
  if CBMessagesOn() {
    CBPhoneFromGangFinal(game, f.gang, CBGangBossSigned(sys, game, f.gang, CBT(n"Cyberbane-GangWar-ToTheEnd")));
  }
}

// The crew gives in to what a winning gang demands.
public func CBWarGiveIn(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> String {
  if !IsDefined(f) || f.state != CBWarStateTheyDemand() {
    return "";
  }
  let now = CBGameSeconds(game);
  if f.terms == CBTermsPay() {
    let price = CBWarDemandPrice(game, f);
    let jb = CBCrewJobBook.Get(game);
    let fromKitty = IsDefined(jb) ? Min(jb.Kitty(), price) : 0;
    let rest = price - fromKitty;
    if rest > 0 && !CBTalkTakeMoney(game, GetPlayer(game), rest) {
      return CBTf(n"Cyberbane-GangWar-CantPayDemand", [s"\(price)"]);
    }
    if fromKitty > 0 {
      jb.AddKitty(-fromKitty);
    }
  }
  if f.terms == CBTermsGiveGround() {
    CBCrewTurfRaise(sys, game, f.place, -CBConfig.WarFootDecisive());
  }
  CBWarEnd(sys, game, f, CBWarEndLostTerms(), now);
  return "";
}

// Refusing a winning gang's demand: the war goes on, and it costs.
public func CBWarRefuseDemand(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> Void {
  if !IsDefined(f) || f.state != CBWarStateTheyDemand() {
    return;
  }
  f.state = CBWarStateOn();
  f.terms = 0;
  f.ourWeary = MaxF(0.0, f.ourWeary - 15.0);   // the crew digs in
  if CBMessagesOn() {
    CBPhoneFromGangFinal(game, f.gang, CBT(n"Cyberbane-GangWar-DemandRefused"));
  }
}

// Called off from the Hub with nothing settled: it stops, and they remember.
public func CBWarCallOff(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> Void {
  if IsDefined(f) {
    CBWarEnd(sys, game, f, CBWarEndCalledOff(), CBGameSeconds(game));
  }
}

// Every way a war ends comes here: the page in History, the grudge, the street's word, the crew's party freed.
public func CBWarEnd(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, how: Int32, now: Float) -> Void {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(fb) || !IsDefined(f) {
    return;
  }
  CBWarReleaseParty(game, CBCrewKitBook.Get(game), f.gang);
  let won = how == CBWarEndTerms() || how == CBWarEndBroken();
  let label = CBCapFirst(CBFactionLabel(f.gang));
  let name = CBWarName(f);
  if won {
    fb.NoteWin(now);
    let kb = CBCrewKitBook.Get(game);
    if IsDefined(kb) {
      kb.NoteWarWon();
    }
    fb.SetGrudge(f.gang, now + CBConfig.WarGrudgeDays() * CBConfig.SecondsPerDay());
    CBCrewStandingShift(game, f.gang, -CBConfig.CrewStandWarWon());
    let content = sys.GetContent();
    let enemy = IsDefined(content) ? CBTopEnemyOf(sys, content, f.gang) : n"";
    CBCrewStandingShift(game, enemy, CBConfig.CrewStandWarEnemy());
    CBWarStreetsShow(sys, game, f, true);
    CBWarRivalSwears(sys, game, f.gang);
  } else {
    CBWarStreetsShow(sys, game, f, false);
  }
  fb.End(f, how, now);
  CBFileLog(sys, n"WarEnded", now, f.place, f.gang, Cast<Float>(how));
  if CBMessagesOn() {
    let line = "";
    if how == CBWarEndTerms() { line = CBTf(n"Cyberbane-GangWar-EndTerms", [name, label]); }
    if how == CBWarEndBroken() { line = CBTf(n"Cyberbane-GangWar-EndBroken", [name, label]); }
    if how == CBWarEndLostTerms() { line = CBTf(n"Cyberbane-GangWar-EndLostTerms", [name, label]); }
    if how == CBWarEndRouted() { line = CBTf(n"Cyberbane-GangWar-EndRouted", [name, label]); }
    if how == CBWarEndCalledOff() { line = CBTf(n"Cyberbane-GangWar-EndCalledOff", [name, label]); }
    CBCrewText(sys, game, CBCrewSecond(game), line, true);
    CBHearsayFromDistrict(game, f.place, won ? CBTf(n"Cyberbane-GangWar-StreetSaysWon", [CBCapFirst(CBCrewTurfLabel()), CBFactionLabel(f.gang), name])
                                             : CBTf(n"Cyberbane-GangWar-StreetSaysLost", [label, CBCrewTurfLabel(), name]), n"");
  }
  CBCrewGroupReplies(sys, game, won ? 1 : 2, 0);
  CBLog.Info(n"War", s"The war on \(NameToString(f.gang)) is over (\(how)).");
}

// The streets show who won (W8): the people on them think better of V, the shops pay the crew in person; a loss empties
// the crew's corners for a while.
func CBWarStreetsShow(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, won: Bool) -> Void {
  if won {
    CBEsteemEarn(sys, f.place, CBConfig.WarWonEsteem());
    if CBCrewHoldsDistrict(sys, game, f.place) {
      CBCrewTaxOwe(game, f.place, CBReward(CBConfig.WarWonShopTax()));
    }
    return;
  }
  let gb = CBCrewGangBook.Get(game);
  if IsDefined(gb) {
    gb.SetCornersEmptyUntil(CBGameSeconds(game) + CBConfig.WarLostCornersDays() * CBConfig.SecondsPerDay());
  }
}

// A Rival of the beaten gang swears revenge: the street hears it, and they hunt the crew a while.
func CBWarRivalSwears(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Void {
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, gang) && r.state == EnumInt(ECBRivalState.Active) {
      if CBMessagesOn() {
        CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), CBT(n"Cyberbane-GangWar-RivalSwears"), CBHudRed());
      }
      return;
    }
  }
}

// ---- Clients and their tribute --------------------------------------------------------------------------------------

// Once a game day (from the slow tick): tribute from every client gang a week, and a client that has rebuilt and holds a
// grudge may break its terms (W7).
public func CBWarClientsDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(fb) || !CBMyCrewOn() {
    return;
  }
  let now = CBGameSeconds(game);
  let jb = CBCrewJobBook.Get(game);
  let broke: CName;
  let i = 0;
  while i < fb.ClientCount() {
    let c = fb.ClientAt(i);
    i += 1;
    if IsDefined(c) {
      if now - c.paidAt >= 7.0 * CBConfig.SecondsPerDay() {
        c.paidAt = now;
        if IsDefined(jb) {
          jb.AddKitty(c.tribute);
        }
        if CBMessagesOn() {
          CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-TributeIn", [CBCapFirst(CBFactionLabel(c.gang)), s"\(c.tribute)"]), true);
        }
      }
      let wb = CBWarBook.Get(game);
      if !IsNameValid(broke) && IsDefined(wb) && wb.Men(c.gang) >= 80.0 && CBGangStrength(sys, c.gang) >= 70.0
         && now - c.since > 14.0 * CBConfig.SecondsPerDay() && RandF() < CBConfig.WarClientBreakChance() {
        broke = c.gang;
      }
    }
  }
  if IsNameValid(broke) {
    let client = fb.FindClient(broke);
    fb.DropClient(client);
    if CBMessagesOn() {
      CBPhoneFromGang(game, broke, CBGangBossSigned(sys, game, broke, CBT(n"Cyberbane-GangWar-BrokeTerms")));
    }
    CBGangWarDeclare(sys, game, broke, true);
  }
}

// How much of a gang is out on the street after the crew beat it (W8): a broken gang keeps its head down, a beaten one
// with a grudge somewhat; 1 for anybody else. Street life scales its chances by it.
public func CBGangStreetShare(game: GameInstance, gang: CName) -> Float {
  if CBGangBrokenByCrew(game, gang) {
    return CBConfig.WarBrokenStreetShare();
  }
  let fb = CBWarFrontBook.Get(game);
  if IsDefined(fb) && fb.Grudge(gang, CBGameSeconds(game)) {
    return CBConfig.WarBeatenStreetShare();
  }
  return 1.0;
}

// A gang the crew broke: held under the broken line, its ranks not refilled, until then.
public func CBGangBrokenByCrew(game: GameInstance, gang: CName) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  return IsDefined(fb) && IsNameValid(gang) && CBGameSeconds(game) < fb.BrokenUntil(gang);
}

// A gang whose losses stay lost: broken by the crew, or at war with it with its war chest cut.
public func CBGangCantRefill(game: GameInstance, gang: CName) -> Bool {
  if CBGangBrokenByCrew(game, gang) {
    return true;
  }
  let f = CBGangWarFront(game, gang);
  return IsDefined(f) && f.chestCut;
}

// Now and then a gang goes to war on the crew (W1): one that holds a grudge or bad blood, with the people to do it.
public func CBWarTheyDeclareDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let fb = CBWarFrontBook.Get(game);
  let wb = CBWarBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(fb) || !IsDefined(wb) || !IsDefined(book) || book.Count() == 0 || fb.Count() >= CBCrewWarsAtOnce(game)
     || RandF() >= CBConfig.WarTheyDeclareChance() {
    return;
  }
  let now = CBGameSeconds(game);
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) && !CBCrewWarOn(game, fs.id) && !CBWarIsClient(game, fs.id)
       && !CBGangBrokenByCrew(game, fs.id) && wb.Men(fs.id) >= CBConfig.WarTheyDeclareMen()
       && (fb.Grudge(fs.id, now) || CBCrewStandingWith(game, fs.id) <= -CBConfig.WarTheyDeclareHate()) {
      CBGangWarDeclare(sys, game, fs.id, true);
      return;
    }
  }
}

// One of a gang's Rivals the crew holds: kept on the roster whatever the Hub's forgetting does.
public func CBWarHoldsRival(game: GameInstance, id: Int32) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(fb) || id <= 0 {
    return false;
  }
  let i = 0;
  while i < fb.PrisonCount() {
    if fb.PrisonRival(i) == id {
      return true;
    }
    i += 1;
  }
  return false;
}

// A gang the crew holds as a client: friendly to V, paying, lending people.
public func CBWarIsClient(game: GameInstance, gang: CName) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  return IsDefined(fb) && IsDefined(fb.FindClient(gang));
}

// ---- Taken alive (W6) -----------------------------------------------------------------------------------------------

// One of the crew taken: off the roster's call while they are held, and the gang names its price.
func CBWarTakeCaptive(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, m: ref<CBCrewMember>, now: Float) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(fb) || !IsDefined(m) || IsDefined(fb.FindCaptive(m.id)) {
    return false;
  }
  let c = new CBWarCaptive();
  c.member = m.id;
  c.gang = f.gang;
  c.since = now;
  c.price = CBReward(CBConfig.WarRansomBase() + CBConfig.WarRansomPerRank() * CBCrewRankOf(game, m));
  let at: Vector4;
  let theirs = CBWarTargetDistrict(sys, game, f.gang);
  if CBWarBaseIn(game, theirs, at) || CBWarPlaceIn(sys, game, theirs, at) {
    c.x = at.X;
    c.y = at.Y;
    c.z = at.Z;
  }
  fb.AddCaptive(c);
  m.hurtUntil = now + 365.0 * CBConfig.SecondsPerDay();   // held: never ready while they are
  CBFileLog(sys, n"WarTaken", now, f.place, f.gang, Cast<Float>(m.id));
  if CBMessagesOn() {
    CBPhoneFromGang(game, f.gang, CBTf(n"Cyberbane-GangWar-CaptivePrice", [CBCrewFirst(sys, m), s"\(c.price)"]));
  }
  CBLog.Info(n"War", s"\(NameToString(f.gang)) took one of the crew alive (member \(m.id)).");
  return true;
}

public func CBWarCaptiveName(sys: ref<CyberbaneSystem>, game: GameInstance, c: ref<CBWarCaptive>) -> String {
  let book = CBCrewBook.Get(game);
  let m = IsDefined(book) && IsDefined(c) ? book.Find(c.member) : null;
  return CBCrewFirst(sys, m);
}

// Paid for, traded for one of theirs, or freed: back home, hurt.
public func CBWarFreeCaptive(sys: ref<CyberbaneSystem>, game: GameInstance, c: ref<CBWarCaptive>, how: Int32) -> Void {
  let fb = CBWarFrontBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(fb) || !IsDefined(c) {
    return;
  }
  let m = IsDefined(book) ? book.Find(c.member) : null;
  let now = CBGameSeconds(game);
  fb.DropCaptive(c);
  if !IsDefined(m) {
    return;
  }
  m.hurtUntil = now + CBConfig.CrewWarHurtHours() * 0.5 * CBConfig.SecondsPerHour();
  m.loyalty = Min(100, m.loyalty + (how == 3 ? 15 : 8));
  CBUnpinCaptive(game, c);
  if CBMessagesOn() {
    CBCrewText(sys, game, m, how == 3 ? CBT(n"Cyberbane-GangWar-RescuedThanks") : CBT(n"Cyberbane-GangWar-FreedThanks"));
  }
}

// The price paid from V's pocket.
public func CBWarPayRansom(sys: ref<CyberbaneSystem>, game: GameInstance, c: ref<CBWarCaptive>) -> Bool {
  if !IsDefined(c) || !CBTalkTakeMoney(game, GetPlayer(game), c.price) {
    return false;
  }
  CBWarEarn(game, c.gang, Cast<Float>(c.price));
  CBWarFreeCaptive(sys, game, c, 1);
  return true;
}

// Traded for one of theirs the crew holds.
public func CBWarTradeCaptive(sys: ref<CyberbaneSystem>, game: GameInstance, c: ref<CBWarCaptive>) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(fb) || !IsDefined(c) {
    return false;
  }
  let p = fb.PrisonerOf(c.gang);
  if p < 0 {
    return false;
  }
  let r = sys.FindRivalById(fb.PrisonRival(p));
  if IsDefined(r) {
    r.state = EnumInt(ECBRivalState.Active);
  }
  fb.DropPrisoner(p);
  CBWarFreeCaptive(sys, game, c, 2);
  return true;
}

// "We're coming for them": the place pinned, and the guards there when V arrives (Reactions/GangWarFight.reds).
public func CBWarGoRescue(sys: ref<CyberbaneSystem>, game: GameInstance, c: ref<CBWarCaptive>) -> Void {
  if IsDefined(c) {
    c.rescue = true;
  }
}

// When a gang stops waiting for its price: a few days, longer with medics set to keep the taken alive. The Hub's
// countdown and the tick both read it.
public func CBWarCaptiveDeadline(game: GameInstance, c: ref<CBWarCaptive>) -> Float {
  let days = CBConfig.WarCaptiveDays() + (CBSquadStanding(game, CBSquadCutters(), 2) ? CBConfig.SquadCaptiveExtraDays() : 0.0);
  return IsDefined(c) ? c.since + days * CBConfig.SecondsPerDay() : 0.0;
}

// Held too long: killed, or they talk and the gang knows the crew's next order.
func CBWarCaptivesTick(sys: ref<CyberbaneSystem>, game: GameInstance, fb: ref<CBWarFrontBook>, now: Float) -> Void {
  let i = 0;
  while i < fb.CaptiveCount() {
    let c = fb.CaptiveAt(i);
    i += 1;
    if IsDefined(c) && now > CBWarCaptiveDeadline(game, c) {
      let book = CBCrewBook.Get(game);
      let m = IsDefined(book) ? book.Find(c.member) : null;
      let f = CBGangWarFront(game, c.gang);
      fb.DropCaptive(c);
      CBUnpinCaptive(game, c);
      if IsDefined(m) {
        if RandF() < CBConfig.WarCaptiveTalkChance() && IsDefined(f) {
          f.sold = true;
          m.hurtUntil = now + CBConfig.CrewWarHurtHours() * CBConfig.SecondsPerHour();
          m.loyalty = Max(0, m.loyalty - 20);
          if CBMessagesOn() {
            CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-CaptiveTalked", [CBCrewFirst(sys, m)]), true);
          }
        } else {
          let bb = CBCrewBannerBook.Get(game);
          if IsDefined(bb) {
            bb.fallCause = CBCrewFellAtWar();
            bb.fallGang = c.gang;
          }
          let name = CBCrewName(sys, m);
          book.Remove(m, CBCrewEndFell(), 0, CBGangHomeDistrict(sys, game, c.gang), now);
          if CBMessagesOn() {
            CBPhoneSendTinted(game, CBPhoneGangSender(c.gang), CBTf(n"Cyberbane-GangWar-CaptiveKilled", [name]), CBHudRed());
          }
        }
      }
      return;   // the lists changed
    }
  }
}

// ---- Their people the crew holds ------------------------------------------------------------------------------------

// Sold back to their gang for money.
public func CBWarRansomPrisoner(sys: ref<CyberbaneSystem>, game: GameInstance, i: Int32) -> Int32 {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(fb) || i < 0 || i >= fb.PrisonCount() {
    return 0;
  }
  let r = sys.FindRivalById(fb.PrisonRival(i));
  let gang = fb.PrisonGang(i);
  let pay = CBReward(CBConfig.WarRansomBase() * 2 + (IsDefined(r) ? CBConfig.WarRansomPerRank() * r.rank : 0));
  if IsDefined(r) {
    r.state = EnumInt(ECBRivalState.Active);
  }
  fb.DropPrisoner(i);
  CBWarSpend(game, gang, Cast<Float>(pay));
  CBStreetGiveMoney(game, pay);
  return pay;
}

// Turned: they join the crew's squads, or are offered a place in the crew itself (C8).
public func CBWarTurnPrisoner(sys: ref<CyberbaneSystem>, game: GameInstance, i: Int32) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  if !IsDefined(fb) || i < 0 || i >= fb.PrisonCount() {
    return false;
  }
  let r = sys.FindRivalById(fb.PrisonRival(i));
  fb.DropPrisoner(i);
  if !IsDefined(r) {
    return false;
  }
  r.state = EnumInt(ECBRivalState.Retired);
  if r.rank >= CBConfig.LieutenantMinRank() && CBWarOfferTurned(sys, game, r) {
    return true;
  }
  CBSquadsGainHeads(game, 2 + r.rank);
  return true;
}

// The best of them get a place on the crew: a broker's offer, cheap, with fights behind them.
func CBWarOfferTurned(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  let book = CBCrewBook.Get(game);
  let now = CBGameSeconds(game);
  if !IsDefined(book) || !book.HasRoom() || book.offerUntil > now {
    return false;
  }
  CBWarDefector(sys, game, book, r.faction);
  return book.offerUntil > now;
}

// ---- For the Hub and the rest of the mod ----------------------------------------------------------------------------

// The front as a word: "winning", "ahead", "even", "behind", "losing".
public func CBWarFrontWord(front: Float) -> String {
  if front >= 50.0 { return CBT(n"Cyberbane-GangWar-FrontWinning"); }
  if front >= 15.0 { return CBT(n"Cyberbane-GangWar-FrontAhead"); }
  if front > -15.0 { return CBT(n"Cyberbane-GangWar-FrontEven"); }
  if front > -50.0 { return CBT(n"Cyberbane-GangWar-FrontBehind"); }
  return CBT(n"Cyberbane-GangWar-FrontLosing");
}

public func CBWarWearyWord(w: Float) -> String {
  if w >= 70.0 { return CBT(n"Cyberbane-GangWar-WearyDone"); }
  if w >= 40.0 { return CBT(n"Cyberbane-GangWar-WearyTired"); }
  return CBT(n"Cyberbane-GangWar-WearyFresh");
}

// Is the crew at war with this gang (either kind: a war, or an old party still out)?
public func CBCrewWarOn(game: GameInstance, gang: CName) -> Bool {
  return IsDefined(CBGangWarFront(game, gang));
}

// Hard reset (Start over).
public func CBWarFrontsClear(game: GameInstance) -> Void {
  let fb = CBWarFrontBook.Get(game);
  if IsDefined(fb) {
    fb.Clear();
  }
}

// The rescue pin is drawn by the fronts' pins tick from the captive list (CBCrewFrontPinsTick): gone from the list, gone
// from the map on the next pass. Kept as the one place a captive leaves the map, should that ever need more.
func CBUnpinCaptive(game: GameInstance, c: ref<CBWarCaptive>) -> Void {
  if IsDefined(c) {
    c.rescue = false;
  }
}

// A member gone from the roster while a gang held them: nobody left to buy back (from CBCrewBook.Remove).
public func CBWarMemberLeaves(game: GameInstance, id: Int32) -> Void {
  let fb = CBWarFrontBook.Get(game);
  let c = IsDefined(fb) ? fb.FindCaptive(id) : null;
  if IsDefined(c) {
    fb.DropCaptive(c);
  }
}

// The second runs the crew's wars while V is away: an order after a while without one from V.
public func CBSecondRunsWars() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().secondRunsWars;
}

// A raid on V's home that the guards could not stop: they are hurt for a while.
func CBGuardsHurt(game: GameInstance, now: Float) -> Void {
  let gb = CBGuardBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(gb) || !IsDefined(book) {
    return;
  }
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && CBGuardPosted(game, m.id) && RandF() < 0.5 {
      m.hurtUntil = MaxF(m.hurtUntil, now + CBConfig.CrewWarHurtHours() * 0.5 * CBConfig.SecondsPerHour());
    }
  }
}
