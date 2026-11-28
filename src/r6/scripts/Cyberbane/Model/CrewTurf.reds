// Cyberbane - The crew as a power on the street
//
// Crew weight (0-100, from members' ranks and wars won), footholds in districts, the districts the crew holds and the
// street tax they pay.

public func CBCrewTurfId() -> CName = n"CB_Crew"

public func CBIsCrewTurf(id: CName) -> Bool {
  return Equals(id, CBCrewTurfId());
}

// The crew takes part in the turf war: the setting, the turf war itself, and a crew to do it.
public func CBCrewTurfOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() || !CBTurfWarsOn() {
    return false;
  }
  return !rt.HasSettings() || (rt.GetSettings().myCrew && rt.GetSettings().crewTurf);
}

// The crew's name in a sentence ("your crew", or the name V gave it), and on its own (a map card, a phone contact).
public func CBCrewTurfLabel() -> String {
  let name = CBCrewNameOf(GetGameInstance());
  return StrLen(name) > 0 ? name : CBT(n"Cyberbane-CrewTurf-YourCrew");
}

public func CBCrewTurfName() -> String {
  let name = CBCrewNameOf(GetGameInstance());
  return StrLen(name) > 0 ? name : CBT(n"Cyberbane-CrewTurf-YourCrewName");
}

// How much the crew counts for on the street, 0..100.
public func CBCrewWeight(game: GameInstance) -> Float {
  let book = CBCrewBook.Get(game);
  if !CBMyCrewOn() || !IsDefined(book) {
    return 0.0;
  }
  let w = 0.0;
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) {
      w += CBConfig.CrewWeightPerMember() + CBConfig.CrewWeightPerRank() * Cast<Float>(CBCrewRankOf(game, m));
    }
  }
  let kb = CBCrewKitBook.Get(game);
  if IsDefined(kb) {
    w += CBConfig.CrewWeightPerWar() * Cast<Float>(Min(kb.WarsWon(), CBConfig.CrewWeightWarsCounted()));
  }
  return ClampF(w, 0.0, 100.0);
}

// A word for it, for the Crew page.
public func CBCrewWeightWord(w: Float) -> String {
  if w >= 75.0 { return CBT(n"Cyberbane-CrewTurf-WeightFeared"); }
  if w >= 50.0 { return CBT(n"Cyberbane-CrewTurf-WeightKnown"); }
  if w >= 25.0 { return CBT(n"Cyberbane-CrewTurf-WeightNoticed"); }
  return CBT(n"Cyberbane-CrewTurf-WeightNobody");
}

public class CBCrewTurfBook extends ScriptableSystem {
  // One entry per district, in CBDistrictAt order.
  private persistent let m_foot: array<Float>;
  private persistent let m_footAt: array<Float>;   // game seconds it was last firmed up
  private persistent let m_day: Int32;             // the last game day the street tax and the daily firming ran, one up
  private persistent let m_home: CName;            // the district V's home ground is in, learned while V is there
  private let m_padded: Bool;

  public static func Get(game: GameInstance) -> ref<CBCrewTurfBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewTurfBook") as CBCrewTurfBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_padded = false;
  }

  private func Pad() -> Void {
    if this.m_padded {
      return;
    }
    this.m_padded = true;
    while ArraySize(this.m_foot) < CBDistrictCount() { ArrayPush(this.m_foot, 0.0); }
    while ArraySize(this.m_footAt) < CBDistrictCount() { ArrayPush(this.m_footAt, 0.0); }
  }

  private func InRange(i: Int32) -> Bool {
    this.Pad();
    return i >= 0 && i < Min(ArraySize(this.m_foot), ArraySize(this.m_footAt));
  }

  // The hold on a district's streets now, faded for the days nobody has firmed it up past the grace.
  public func Foothold(i: Int32, now: Float) -> Float {
    if !this.InRange(i) {
      return 0.0;
    }
    let idle = MaxF(0.0, now - this.m_footAt[i]) / CBConfig.SecondsPerDay() - CBConfig.CrewFootGraceDays();
    return ClampF(this.m_foot[i] - MaxF(0.0, idle) * CBConfig.CrewFootFadePerDay(), 0.0, 1.0);
  }

  public func Raise(i: Int32, amount: Float, now: Float) -> Void {
    if !this.InRange(i) {
      return;
    }
    this.m_foot[i] = ClampF(this.Foothold(i, now) + amount, 0.0, 1.0);
    this.m_footAt[i] = now;
  }

  public func Home() -> CName {
    return this.m_home;
  }

  public func SetHome(d: CName) -> Void {
    this.m_home = d;
  }

  public func Day() -> Int32 {
    return this.m_day;
  }

  public func SetDay(day: Int32) -> Void {
    this.m_day = day;
  }

  public func Clear() -> Void {
    this.m_padded = false;
    ArrayClear(this.m_foot);
    ArrayClear(this.m_footAt);
    this.m_day = 0;
    this.m_home = n"";
  }
}

public func CBCrewFoothold(game: GameInstance, district: CName) -> Float {
  let book = CBCrewTurfBook.Get(game);
  return IsDefined(book) ? book.Foothold(CBDistrictIndex(district), CBGameSeconds(game)) : 0.0;
}

// More (or, negative, less) hold on a district's streets. Only where some gang has streets: the crew takes ground from
// gangs, not from the corps' plazas.
public func CBCrewTurfRaise(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, amount: Float) -> Void {
  let book = CBCrewTurfBook.Get(game);
  let i = CBDistrictIndex(district);
  if !IsDefined(book) || i < 0 || !CBCrewTurfOn() || !CBDistrictHasGangs(sys, district) {
    return;
  }
  book.Raise(i, amount, CBGameSeconds(game));
  CBLog.Info(n"Model", s"V's crew's hold on \(NameToString(district)) is \(RoundF(book.Foothold(i, CBGameSeconds(game)) * 100.0))% now.");
}

public func CBDistrictHasGangs(sys: ref<CyberbaneSystem>, district: CName) -> Bool {
  let content = IsDefined(sys) ? sys.GetContent() : null;
  if !IsDefined(content) {
    return false;
  }
  let def = content.GetDistrict(district);
  if IsDefined(def) && def.sealed {
    return false;
  }
  for f in content.GetFactions() {
    if IsDefined(f) && f.isGang && ArrayContains(f.turf, district) {
      return true;
    }
  }
  return false;
}

// The crew's push for a district in the turf model, 0 when it has no foothold there (Model/Territory.reds).
public func CBCrewTurfWeight(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, dIdx: Int32) -> Float {
  if !CBCrewTurfOn() {
    return 0.0;
  }
  let f = CBCrewFoothold(game, district);
  if f <= 0.0 {
    return 0.0;
  }
  let s = CBGangStrengthIn(sys, CBCrewTurfId(), district) * f;
  // Each neighbourhood the crew holds there pushes too (Model/Hoods.reds).
  let hoods = 1.0 + CBConfig.HoodDistrictPush() * CBHoodsCrewShare(game, district);
  return s * s * CBConfig.CrewTurfPush() * hoods * CBTurfWobble(game, dIdx, 97);
}

// Districts the crew holds right now.
public func CBCrewHeldDistricts(sys: ref<CyberbaneSystem>, game: GameInstance) -> array<CName> {
  let out: array<CName>;
  let book = CBTurfBook.Get(game);
  if !IsDefined(book) || !CBCrewTurfOn() {
    return out;
  }
  let i = 0;
  while i < CBDistrictCount() {
    if CBIsCrewTurf(book.Holder(i)) {
      ArrayPush(out, CBDistrictAt(i));
    }
    i += 1;
  }
  return out;
}

public func CBCrewHoldsHere(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) || !CBCrewTurfOn() {
    return false;
  }
  let book = CBTurfBook.Get(game);
  let i = CBDistrictIndex(sys.GetCurrentDistrict());
  return IsDefined(book) && i >= 0 && CBIsCrewTurf(book.Holder(i));
}

// Once a slow tick: the day's firming up and the street tax, once a game day.
public func CBCrewTurfTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBCrewTurfBook.Get(game);
  let crew = CBCrewBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(crew) || !CBCrewTurfOn() {
    return;
  }
  // Where V's home is, learned whenever V is on home ground (Spawn/HomeGround.reds): the guards keep watch there.
  if CBOnHomeGround(game) && NotEquals(sys.GetCurrentDistrict(), n"") {
    book.SetHome(sys.GetCurrentDistrict());
  }
  let day = CBGameDay(game) + 1;
  if book.Day() == day {
    return;
  }
  let first = book.Day() == 0;
  book.SetDay(day);
  if first {
    return;   // the first look of a playthrough only learns the day
  }
  let now = CBGameSeconds(game);
  // Where they live, and where they keep watch on V's home.
  let i = 0;
  while i < crew.Count() {
    let m = crew.At(i);
    i += 1;
    if IsDefined(m) && NotEquals(m.home, n"") && !CBCrewAway(game, m.id, now) {
      CBCrewTurfRaise(sys, game, m.home, CBConfig.CrewFootLivesHere());
    }
  }
  let gb = CBGuardBook.Get(game);
  let homeDistrict = book.Home();
  if IsDefined(gb) && gb.Count() > 0 && NotEquals(homeDistrict, n"") {
    CBCrewTurfRaise(sys, game, homeDistrict, CBConfig.CrewFootGuard() * Cast<Float>(gb.Count()));
  }
  // The street tax from every district they hold, scaled by how much the crew counts for.
  let held = CBCrewHeldDistricts(sys, game);
  let jb = CBCrewJobBook.Get(game);
  if ArraySize(held) > 0 && IsDefined(jb) {
    let per = CBReward(RoundF(CBConfig.CrewTurfTaxPerDistrict() * (0.5 + CBCrewWeight(game) / 200.0)));
    // The watch collects more of it in person (Reactions/Squads.reds).
    if CBSquadStanding(game, CBSquadWatch(), 0) {
      per = RoundF(Cast<Float>(per) * CBConfig.SquadWatchTaxMult());
    }
    // Half through the crew, half kept by the shops for V to collect in person (CBCrewTaxCollectTick), each district's
    // by whoever runs it (Reactions/CrewGang.reds).
    let total = 0;
    for dOwe in held {
      let here = RoundF(Cast<Float>(per) * CBRunnerTaxMult(game, dOwe));
      let inPerson = here / 2;
      CBCrewTaxOwe(game, dOwe, inPerson);
      total += here - inPerson;
    }
    jb.AddKitty(total);
    CBFileLog(sys, n"CrewTax", now, sys.GetCurrentDistrict(), n"", Cast<Float>(total));
    if CBMessagesOn() {
      let places = "";
      for d in held {
        places = StrLen(places) > 0 ? places + ", " + CBDistrictLabel(d) : CBDistrictLabel(d);
      }
      CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewTurf-TaxIsIn", [s"\(total)", places]));
    }
    CBLog.Info(n"Model", s"Street tax from \(ArraySize(held)) districts the crew holds: \(total)eb into the kitty.");
  }
}

// What the crew counts for and the streets it holds, a line for the Crew page; "" with no crew.
public func CBCrewPowerLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBCrewBook.Get(game);
  if !CBMyCrewOn() || !IsDefined(book) || book.Count() == 0 {
    return "";
  }
  let w = CBCrewWeight(game);
  let line = CBTf(n"Cyberbane-CrewTurf-PowerLine", [CBCrewWeightWord(w), s"\(RoundF(w))"]);
  let held = CBCrewHeldDistricts(sys, game);
  if ArraySize(held) > 0 {
    let places = "";
    for d in held {
      places = StrLen(places) > 0 ? places + ", " + CBDistrictLabel(d) : CBDistrictLabel(d);
    }
    line += CBTf(n"Cyberbane-CrewTurf-HoldsLine", [places]);
  }
  return line;
}

// What the street says in a district V's crew holds, for anybody who talks about who runs it.
public func CBCrewTurfLine() -> String {
  let label = CBCapFirst(CBCrewTurfLabel());
  return CBLineOf([CBTf(n"Cyberbane-CrewTurf-RunItNowYours", [label]), CBTf(n"Cyberbane-CrewTurf-YourPeopleRunIt", [label]),
                   CBT(n"Cyberbane-CrewTurf-YouDoYouKnowThat")]);
}
