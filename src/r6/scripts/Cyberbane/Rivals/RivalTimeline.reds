// Cyberbane - A Rival's history with V, their calling cards, and the ones who turn
//
// Every time V and a Rival cross (they are made, they get away, V lets them go, they put V down, they climb, they hurt
// one of V's crew, they die) is written in their timeline, for the Rivals page: where it was and how it went.

public func CBTlMade() -> Int32 = 1
public func CBTlEscaped() -> Int32 = 2
public func CBTlSpared() -> Int32 = 3
public func CBTlKilledV() -> Int32 = 4
public func CBTlClimbed() -> Int32 = 5
public func CBTlSlain() -> Int32 = 6
public func CBTlScarredCrew() -> Int32 = 7
public func CBTlLostThem() -> Int32 = 8
public func CBTlCard() -> Int32 = 9
public func CBTlTurned() -> Int32 = 10

public class CBRivalTimelineBook extends ScriptableSystem {
  private persistent let m_rival: array<Int32>;
  private persistent let m_kind: array<Int32>;
  private persistent let m_at: array<Float>;
  private persistent let m_place: array<CName>;
  // A calling card waiting at a place: whose, where, until when.
  private persistent let m_cardRival: Int32;
  private persistent let m_cardX: Float;
  private persistent let m_cardY: Float;
  private persistent let m_cardZ: Float;
  private persistent let m_cardUntil: Float;
  private persistent let m_cardDistrict: CName;
  private persistent let m_turnDay: Int32;   // the last game day a Rival's turning was asked about, one up
  public let cardPin: NewMappinID;           // session: pins do not outlive a load, and come back from the place
  public let cardPinned: Bool;

  public static func Get(game: GameInstance) -> ref<CBRivalTimelineBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBRivalTimelineBook") as CBRivalTimelineBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.cardPinned = false;
  }

  public func Count() -> Int32 {
    return Min(Min(ArraySize(this.m_rival), ArraySize(this.m_kind)), Min(ArraySize(this.m_at), ArraySize(this.m_place)));
  }

  public func RivalAt(i: Int32) -> Int32 { return this.m_rival[i]; }
  public func KindAt(i: Int32) -> Int32 { return this.m_kind[i]; }
  public func AtAt(i: Int32) -> Float { return this.m_at[i]; }
  public func PlaceAt(i: Int32) -> CName { return this.m_place[i]; }

  public func Note(rival: Int32, kind: Int32, at: Float, place: CName) -> Void {
    let n = this.Count();
    while ArraySize(this.m_rival) > n { ArrayPop(this.m_rival); }
    while ArraySize(this.m_kind) > n { ArrayPop(this.m_kind); }
    while ArraySize(this.m_at) > n { ArrayPop(this.m_at); }
    while ArraySize(this.m_place) > n { ArrayPop(this.m_place); }
    ArrayPush(this.m_rival, rival);
    ArrayPush(this.m_kind, kind);
    ArrayPush(this.m_at, at);
    ArrayPush(this.m_place, place);
    while this.Count() > CBConfig.RivalTimelineCap() {
      ArrayErase(this.m_rival, 0);
      ArrayErase(this.m_kind, 0);
      ArrayErase(this.m_at, 0);
      ArrayErase(this.m_place, 0);
    }
  }

  // A Start over: nothing of the old board is kept.
  public func Clear() -> Void {
    ArrayClear(this.m_rival);
    ArrayClear(this.m_kind);
    ArrayClear(this.m_at);
    ArrayClear(this.m_place);
    this.m_cardRival = 0;
    this.m_cardUntil = 0.0;
    this.cardPinned = false;
  }

  public func CardRival() -> Int32 { return this.m_cardRival; }
  public func CardAt() -> Vector4 { return new Vector4(this.m_cardX, this.m_cardY, this.m_cardZ, 1.0); }
  public func CardUntil() -> Float { return this.m_cardUntil; }
  public func CardDistrict() -> CName { return this.m_cardDistrict; }

  public func SetCard(rival: Int32, at: Vector4, until: Float, district: CName) -> Void {
    this.m_cardRival = rival;
    this.m_cardX = at.X;
    this.m_cardY = at.Y;
    this.m_cardZ = at.Z;
    this.m_cardUntil = until;
    this.m_cardDistrict = district;
  }

  public func ClearCard() -> Void {
    this.m_cardRival = 0;
    this.m_cardUntil = 0.0;
  }

  public func TurnDay() -> Int32 { return this.m_turnDay; }
  public func SetTurnDay(d: Int32) -> Void { this.m_turnDay = d; }
}

// The kind of moment each Rival event is (CBApiRivalEvent's names).
func CBTlKindOf(event: CName) -> Int32 {
  if Equals(event, n"Made") { return CBTlMade(); }
  if Equals(event, n"Escaped") { return CBTlEscaped(); }
  if Equals(event, n"Spared") { return CBTlSpared(); }
  if Equals(event, n"KilledV") { return CBTlKilledV(); }
  if Equals(event, n"Climbed") { return CBTlClimbed(); }
  if Equals(event, n"Slain") { return CBTlSlain(); }
  return 0;
}

// From CBApiRivalEvent: written where V is when it happens.
public func CBRivalTimelineEvent(r: ref<CBRival>, event: CName) -> Void {
  let kind = CBTlKindOf(event);
  if kind > 0 && IsDefined(r) {
    let game = GetGameInstance();
    CBRivalTimelineNote(game, r.id, kind);
    // Got away from V: they leave V a calling card.
    if kind == CBTlEscaped() {
      CBRivalCallingCard(CyberbaneSystem.Get(game), game, r);
    }
  }
}

public func CBRivalTimelineNote(game: GameInstance, rivalId: Int32, kind: Int32) -> Void {
  let book = CBRivalTimelineBook.Get(game);
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(book) || rivalId <= 0 {
    return;
  }
  book.Note(rivalId, kind, CBGameSeconds(game), IsDefined(sys) ? sys.GetCurrentDistrict() : n"");
}

func CBTlWord(kind: Int32) -> String {
  if kind == CBTlMade() { return CBT(n"Cyberbane-RivalTimeline-Made"); }
  if kind == CBTlEscaped() { return CBT(n"Cyberbane-RivalTimeline-Escaped"); }
  if kind == CBTlSpared() { return CBT(n"Cyberbane-RivalTimeline-Spared"); }
  if kind == CBTlKilledV() { return CBT(n"Cyberbane-RivalTimeline-KilledV"); }
  if kind == CBTlClimbed() { return CBT(n"Cyberbane-RivalTimeline-Climbed"); }
  if kind == CBTlSlain() { return CBT(n"Cyberbane-RivalTimeline-Slain"); }
  if kind == CBTlScarredCrew() { return CBT(n"Cyberbane-RivalTimeline-ScarredCrew"); }
  if kind == CBTlLostThem() { return CBT(n"Cyberbane-RivalTimeline-LostThem"); }
  if kind == CBTlCard() { return CBT(n"Cyberbane-RivalTimeline-Card"); }
  if kind == CBTlTurned() { return CBT(n"Cyberbane-RivalTimeline-Turned"); }
  return "";
}

// Their history with V, oldest first, on one line for the Rivals page: "Heywood: made. Westbrook: got away....". The
// climbs are left out when there are more than a few moments, as they follow every escape anyway.
public func CBRivalTimelineLine(game: GameInstance, r: ref<CBRival>) -> String {
  let book = CBRivalTimelineBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) {
    return "";
  }
  let parts: array<String>;
  let n = book.Count();
  let i = 0;
  while i < n {
    if book.RivalAt(i) == r.id && book.KindAt(i) != CBTlClimbed() {
      let place = CBDistrictLabel(book.PlaceAt(i));
      let word = CBTlWord(book.KindAt(i));
      if StrLen(word) > 0 {
        ArrayPush(parts, StrLen(place) > 0 ? CBTf(n"Cyberbane-RivalTimeline-PlaceWord", [place, word]) : CBCapFirst(word) + ".");
      }
    }
    i += 1;
  }
  if ArraySize(parts) == 0 {
    return "";
  }
  let out = "";
  let from = Max(0, ArraySize(parts) - CBConfig.RivalTimelineShown());
  let k = from;
  while k < ArraySize(parts) {
    out += (StrLen(out) > 0 ? " " : "") + parts[k];
    k += 1;
  }
  return CBTf(n"Cyberbane-RivalTimeline-Line", [out]);
}

// ---- Calling cards -------------------------------------------------------------------------------------------------

// A Rival hurt one of V's crew, or got away from V: they leave V something at a place of theirs, and say where.
public func CBRivalCallingCard(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  let book = CBRivalTimelineBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(book) || !IsDefined(r) || !IsDefined(player) || !CBRivalsOn() || book.CardRival() > 0
     || r.state == EnumInt(ECBRivalState.Slain) || RandF() >= CBConfig.RivalCardChance() {
    return;
  }
  let at: Vector4;
  let district: CName;
  if !CBGangDropPlace(sys, game, player, r.faction, CBConfig.RivalCardMin(), CBConfig.RivalCardMax(), at, district) {
    return;
  }
  book.SetCard(r.id, at, CBGameSeconds(game) + CBConfig.RivalCardDays() * CBConfig.SecondsPerDay(), district);
  CBRivalTimelineNote(game, r.id, CBTlCard());
  book.cardPinned = CBPinPlace(game, at, CBTf(n"Cyberbane-RivalTimeline-CardPin", [CBRivalDisplayName(sys.GetContent(), r)]), book.cardPin);
  if CBMessagesOn() {
    CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), CBTf(n"Cyberbane-RivalTimeline-CardText", [CBDistrictLabel(district)]), CBHudRed());
  }
  CBLog.Info(n"Rivals", s"Rival \(r.id) left V a calling card in \(NameToString(district)).");
}

// The card's place, every few ticks: pinned again after a load, found when V is there, gone when its time is up.
public func CBRivalTimelineTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBRivalTimelineBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(book) || !IsDefined(player) || book.CardRival() <= 0 || sys.GetTickCount() % 3 != 1 {
    CBRivalTurnDaily(sys, game);
    return;
  }
  CBRivalTurnDaily(sys, game);
  let r = sys.FindRivalById(book.CardRival());
  let now = CBGameSeconds(game);
  if !IsDefined(r) || now > book.CardUntil() {
    CBRivalCardDone(game, book);
    return;
  }
  if !book.cardPinned && CBWorldStable(game) {
    book.cardPinned = CBPinPlace(game, book.CardAt(), CBTf(n"Cyberbane-RivalTimeline-CardPin", [CBRivalDisplayName(sys.GetContent(), r)]), book.cardPin);
  }
  if Vector4.Distance(player.GetWorldPosition(), book.CardAt()) > CBConfig.RivalCardFindRange() || player.IsInCombat() {
    return;
  }
  // Found: their mark, and what they left.
  let pay = CBConfig.RivalCardEddies() * Max(1, r.rank);
  CBStreetGiveMoney(game, pay);
  CBSystemNote(game, CBTf(n"Cyberbane-RivalTimeline-CardFound", [CBRivalNickname(sys, r), s"\(pay)"]), 8.0);
  if CBMessagesOn() {
    CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), CBRivalTaunt(r), CBHudRed());
  }
  CBLog.Info(n"Rivals", "V found a Rival's calling card.");
  CBRivalCardDone(game, book);
}

func CBRivalCardDone(game: GameInstance, book: ref<CBRivalTimelineBook>) -> Void {
  if book.cardPinned {
    CBUnpinPlace(game, book.cardPin);
  }
  book.cardPinned = false;
  book.ClearCard();
}

// What the street calls them, for their mark: their epithet when they have one, else their name.
func CBRivalNickname(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> String {
  return CBRivalDisplayName(sys.GetContent(), r);
}

// ---- Rivals who turn -----------------------------------------------------------------------------------------------

// Once a game day: a Rival V humiliated, thrown away by their own gang, may turn. They owe V now (a Debtor), so their
// own thread can take them onto V's crew, the way any Rival who owes V can (CBCrewRecruitDebtor).
func CBRivalTurnDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBRivalTimelineBook.Get(game);
  if !IsDefined(book) || !CBRivalsOn() {
    return;
  }
  let day = CBGameDay(game) + 1;
  if book.TurnDay() == day {
    return;
  }
  let first = book.TurnDay() == 0;
  book.SetTurnDay(day);
  if first || RandF() >= CBConfig.RivalTurnChance() {
    return;
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Active) && CBRivalWasHumiliated(r) && r.sparedByV >= 1 {
      r.state = EnumInt(ECBRivalState.Debtor);
      CBHierarchyFill(sys, r.faction);
      CBRivalTimelineNote(game, r.id, CBTlTurned());
      if CBMessagesOn() {
        CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), CBTf(n"Cyberbane-RivalTimeline-TurnText", [CBFactionLabel(r.faction)]), CBHudCyan());
      }
      CBLog.Info(n"Rivals", s"Rival \(r.id), thrown away by their gang, turned to V.");
      return;
    }
  }
}

// ---- Rivals who hunt the crew --------------------------------------------------------------------------------------

// A job this member is on may meet the Rival who put them on the ground before (CBCrewJobsTick): worse odds, and the member
// says so. The new odds.
public func CBRivalHuntsCrewOnJob(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, odds: Float) -> Float {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) || !IsDefined(m) || !CBRivalsOn() {
    return odds;
  }
  let rid = CBCrewScarRival(sys, game, lb, m);
  if rid <= 0 || RandF() >= CBConfig.RivalHuntsCrewChance() {
    return odds;
  }
  let r = sys.FindRivalById(rid);
  if !IsDefined(r) {
    return odds;
  }
  CBRivalTimelineNote(game, rid, CBTlScarredCrew());
  if CBMessagesOn() {
    CBCrewText(sys, game, m, CBTf(n"Cyberbane-RivalTimeline-HuntsCrew", [CBRivalDisplayName(sys.GetContent(), r)]));
  }
  CBLog.Info(n"Rivals", s"Rival \(rid) went after one of V's crew on a job.");
  return MaxF(0.05, odds - CBConfig.RivalHuntsCrewOdds());
}
