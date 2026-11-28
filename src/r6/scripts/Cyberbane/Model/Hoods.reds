// Cyberbane - Turf by neighbourhood
//
// The game's smaller districts (Arroyo, Rancho Coronado, Kabuki, Northside, the Glen and the rest), each learned the first
// time V stands in it, with the district it lies in. Each starts as its district's holder's and learns who is really
// there from the gangers V passes. A war takes a neighbourhood from the gang fought, not the whole district, and a
// district counts for the crew by how many of its neighbourhoods the crew holds.

public class CBHoodBook extends ScriptableSystem {
  private persistent let m_hood: array<TweakDBID>;
  private persistent let m_parent: array<CName>;
  private persistent let m_crew: array<Float>;     // the crew's hold, 0..1
  private persistent let m_holder: array<CName>;   // n"" while it is its district's holder's; a gang, or the crew
  private persistent let m_seen: array<CName>;     // the last gang seen on its streets
  private persistent let m_seenAt: array<Float>;
  // Session only: where V stands, worked out every few ticks.
  public let here: Int32;

  public static func Get(game: GameInstance) -> ref<CBHoodBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBHoodBook") as CBHoodBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    let n = this.Count();
    ArrayResize(this.m_hood, n);
    ArrayResize(this.m_parent, n);
    ArrayResize(this.m_crew, n);
    ArrayResize(this.m_holder, n);
    ArrayResize(this.m_seen, n);
    ArrayResize(this.m_seenAt, n);
    this.here = -1;
  }

  public func Count() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_hood), ArraySize(this.m_parent)), Min(ArraySize(this.m_crew), ArraySize(this.m_holder))),
               Min(ArraySize(this.m_seen), ArraySize(this.m_seenAt)));
  }

  public func Clear() -> Void {
    ArrayClear(this.m_hood);
    ArrayClear(this.m_parent);
    ArrayClear(this.m_crew);
    ArrayClear(this.m_holder);
    ArrayClear(this.m_seen);
    ArrayClear(this.m_seenAt);
    this.here = -1;
  }

  public func Index(hood: TweakDBID) -> Int32 {
    let i = 0;
    while i < this.Count() {
      if this.m_hood[i] == hood {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func Learn(hood: TweakDBID, parent: CName) -> Int32 {
    let i = this.Index(hood);
    if i >= 0 {
      return i;
    }
    ArrayPush(this.m_hood, hood);
    ArrayPush(this.m_parent, parent);
    ArrayPush(this.m_crew, 0.0);
    ArrayPush(this.m_holder, n"");
    ArrayPush(this.m_seen, n"");
    ArrayPush(this.m_seenAt, 0.0);
    return this.Count() - 1;
  }

  public func Hood(i: Int32) -> TweakDBID { return i >= 0 && i < this.Count() ? this.m_hood[i] : TDBID.None(); }
  public func Parent(i: Int32) -> CName { return i >= 0 && i < this.Count() ? this.m_parent[i] : n""; }
  public func Crew(i: Int32) -> Float { return i >= 0 && i < this.Count() ? this.m_crew[i] : 0.0; }
  public func Holder(i: Int32) -> CName { return i >= 0 && i < this.Count() ? this.m_holder[i] : n""; }
  public func Seen(i: Int32) -> CName { return i >= 0 && i < this.Count() ? this.m_seen[i] : n""; }
  public func SeenAt(i: Int32) -> Float { return i >= 0 && i < this.Count() ? this.m_seenAt[i] : 0.0; }
  public func SetCrew(i: Int32, v: Float) -> Void { if i >= 0 && i < this.Count() { this.m_crew[i] = ClampF(v, 0.0, 1.0); } }
  public func SetHolder(i: Int32, g: CName) -> Void { if i >= 0 && i < this.Count() { this.m_holder[i] = g; } }
  public func NoteSeen(i: Int32, g: CName, at: Float) -> Void {
    if i >= 0 && i < this.Count() {
      this.m_seen[i] = g;
      this.m_seenAt[i] = at;
    }
  }
}

public func CBHoodsOn() -> Bool {
  return CBTurfWarsOn();
}

// A neighbourhood is a district of the game's that lies inside another (it has a parent); a whole district is not one.
func CBHoodHasParent(id: TweakDBID) -> Bool {
  let up = id;
  TDBID.Append(up, t".parentDistrict");
  return TDBID.IsValid(TweakDBInterface.GetForeignKey(up, TDBID.None()));
}

public func CBHoodLabel(id: TweakDBID) -> String {
  let rec = TDBID.IsValid(id) ? TweakDBInterface.GetDistrictRecord(id) : null;
  return IsDefined(rec) ? GetLocalizedText(rec.LocalizedName()) : "";
}

// Who holds a neighbourhood: its own holder once one took it, otherwise its district's.
public func CBHoodHolderAt(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHoodBook>, i: Int32) -> CName {
  let own = book.Holder(i);
  return IsNameValid(own) ? own : CBTurfHolder(sys, game, book.Parent(i));
}

// Every few ticks: the neighbourhood V stands in, learned with its district.
public func CBHoodTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBHoodBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || !CBHoodsOn() || sys.GetTickCount() % 10 != 3 || !CBWorldStable(game) {
    return;
  }
  let id = CBSubDistrictId(game);
  let parent = sys.GetCurrentDistrict();
  if !TDBID.IsValid(id) || !IsNameValid(parent) || !CBHoodHasParent(id) {
    book.here = -1;
    return;
  }
  book.here = book.Learn(id, parent);
}

// A ganger V passed on these streets (from the Director, through CBClashNote): the neighbourhood learns who is really there.
public func CBHoodNoteSeen(sys: ref<CyberbaneSystem>, faction: CName) -> Void {
  let game = sys.GetGameInstance();
  let book = CBHoodBook.Get(game);
  if IsDefined(book) && book.here >= 0 && IsNameValid(faction) && CBGangHoldsTurf(sys, faction) {
    book.NoteSeen(book.here, faction, CBGameSeconds(game));
  }
}

// A won night against `gang` in `district`: the crew's hold grows in a neighbourhood of theirs there, the one their people
// were last seen in first; past the line it is the crew's.
public func CBHoodsWarGain(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, district: CName, amount: Float) -> Void {
  let book = CBHoodBook.Get(game);
  if !IsDefined(book) || !CBHoodsOn() || amount <= 0.0 {
    return;
  }
  let pick = -1;
  let i = 0;
  while i < book.Count() {
    if Equals(book.Parent(i), district) && !CBIsCrewTurf(book.Holder(i)) && Equals(CBHoodHolderAt(sys, game, book, i), gang) {
      if pick < 0 || (Equals(book.Seen(i), gang) && book.SeenAt(i) > book.SeenAt(pick)) {
        pick = i;
      }
    }
    i += 1;
  }
  if pick < 0 {
    return;   // no neighbourhood of theirs known there yet: V has to have walked it
  }
  book.SetCrew(pick, book.Crew(pick) + amount);
  if book.Crew(pick) >= CBConfig.HoodTakeLine() {
    book.SetHolder(pick, CBCrewTurfId());
    CBFileLog(sys, n"HoodTaken", CBGameSeconds(game), district, gang, 0.0);
    if CBMessagesOn() {
      CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-HoodTaken", [CBHoodLabel(book.Hood(pick)), CBCapFirst(CBFactionLabel(gang))]), true);
    }
  }
}

// The crew's hold slips in a district (a corner lost): its weakest neighbourhood there first; under the line it goes back.
public func CBHoodsLoss(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, amount: Float, to: CName) -> Void {
  let book = CBHoodBook.Get(game);
  if !IsDefined(book) || amount <= 0.0 {
    return;
  }
  let pick = -1;
  let i = 0;
  while i < book.Count() {
    if Equals(book.Parent(i), district) && book.Crew(i) > 0.0 && (pick < 0 || book.Crew(i) < book.Crew(pick)) {
      pick = i;
    }
    i += 1;
  }
  if pick < 0 {
    return;
  }
  book.SetCrew(pick, book.Crew(pick) - amount);
  if CBIsCrewTurf(book.Holder(pick)) && book.Crew(pick) < CBConfig.HoodLoseLine() {
    book.SetHolder(pick, to);
    if CBMessagesOn() {
      CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-HoodLost", [CBHoodLabel(book.Hood(pick)), CBCapFirst(CBFactionLabel(to))]), true);
    }
  }
}

// How much of a district's known neighbourhoods the crew holds, 0..1.
public func CBHoodsCrewShare(game: GameInstance, district: CName) -> Float {
  let book = CBHoodBook.Get(game);
  if !IsDefined(book) {
    return 0.0;
  }
  let known = 0;
  let ours = 0;
  let i = 0;
  while i < book.Count() {
    if Equals(book.Parent(i), district) {
      known += 1;
      if CBIsCrewTurf(book.Holder(i)) {
        ours += 1;
      }
    }
    i += 1;
  }
  return known > 0 ? Cast<Float>(ours) / Cast<Float>(known) : 0.0;
}

// "Arroyo, Kabuki", the neighbourhoods the crew holds, for the crew page and the turf map; "" with none.
public func CBHoodsCrewLine(game: GameInstance) -> String {
  let book = CBHoodBook.Get(game);
  if !IsDefined(book) {
    return "";
  }
  let out = "";
  let i = 0;
  while i < book.Count() {
    if CBIsCrewTurf(book.Holder(i)) {
      let name = CBHoodLabel(book.Hood(i));
      out = StrLen(out) > 0 ? out + ", " + name : name;
    }
    i += 1;
  }
  return out;
}

// The neighbourhood V stands in, and who holds it, for the HUD and the turf page: "" when V is not in one.
public func CBHoodHereLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBHoodBook.Get(game);
  if !IsDefined(book) || book.here < 0 {
    return "";
  }
  let holder = CBHoodHolderAt(sys, game, book, book.here);
  let who = CBIsCrewTurf(holder) ? CBCrewTurfLabel() : CBFactionLabel(holder);
  return StrLen(who) > 0 ? CBTf(n"Cyberbane-GangWar-HoodHere", [CBHoodLabel(book.Hood(book.here)), who]) : "";
}
