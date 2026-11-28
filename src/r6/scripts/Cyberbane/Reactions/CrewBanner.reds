// Cyberbane - The crew as a crew
//
// The crew's colours, its own standing with each gang and its name, apart from any one member.

// One of the crew who died, as the memorial keeps them: everything their name and story need, so a memorial outlives
// the roster's own past (CBCrewBook keeps MyCrewPastKept).
public class CBCrewFallen {
  public persistent let id: Int32;
  public persistent let kind: Int32;
  public persistent let faction: CName;
  public persistent let rival: Int32;
  public persistent let seed: Int32;
  public persistent let seat: Int32;
  public persistent let wins: Int32;
  public persistent let rank: Int32;
  public persistent let hadWeapon: Bool;
  public persistent let weapon: TweakDBID;
  public persistent let weaponTier: Int32;
  // What chrome they had, four scalars for the reason CBCrewKit keeps them so: saved inside the book's list.
  public persistent let chrome0: TweakDBID;
  public persistent let chrome1: TweakDBID;
  public persistent let chrome2: TweakDBID;
  public persistent let chrome3: TweakDBID;
  public persistent let trained: Int32;
  public persistent let spars: Int32;
  public persistent let cause: Int32;        // CBCrewFellBeside, CBCrewFellAtWar
  public persistent let gang: CName;         // whose people did it, n"" when nobody knows
  public persistent let by: Int32;           // the Rival who did it, 0 for none
  public persistent let district: CName;
  public persistent let joinedAt: Float;
  public persistent let at: Float;

  public func ChromeAt(i: Int32) -> TweakDBID {
    if i == 0 { return this.chrome0; }
    if i == 1 { return this.chrome1; }
    if i == 2 { return this.chrome2; }
    if i == 3 { return this.chrome3; }
    return TDBID.None();
  }

  // Their chrome, named, "" for none.
  public func ChromeNames() -> String {
    let parts = "";
    let i = 0;
    while i < 4 {
      let c = this.ChromeAt(i);
      i += 1;
      if TDBID.IsValid(c) {
        parts += (StrLen(parts) > 0 ? ", " : "") + CBCrewItemName(c);
      }
    }
    return parts;
  }
}

public func CBCrewFellBeside() -> Int32 = 0
public func CBCrewFellAtWar() -> Int32 = 1

public class CBCrewBannerBook extends ScriptableSystem {
  private persistent let m_colour: Int32;              // a place in the colours, one up; 0 for the default
  private persistent let m_standGang: array<CName>;
  private persistent let m_standValue: array<Int32>;   // -100..100, beside m_standGang
  private persistent let m_standDay: Int32;            // the last game day standing eased, stored one up
  private persistent let m_fallen: array<ref<CBCrewFallen>>;
  private persistent let m_recruiter: Int32;           // the member put to recruiting, 0 for nobody
  // How the next one taken off the roster as fallen died (set just before CBCrewBook.Remove; session only).
  public let fallCause: Int32;
  public let fallGang: CName;
  // The solo on offer came through the recruiter, with this many fights behind them (session, like the offer).
  public let offerWins: Int32;
  // Asked for on the Hub, carried out on the next tick.
  public let reqColour: Int32;     // the colour asked for, one up; 0 for none

  public static func Get(game: GameInstance) -> ref<CBCrewBannerBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewBannerBook") as CBCrewBannerBook : null;
  }

  // A load starts the session over: nothing asked or on offer carries into another save.
  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.fallCause = 0;
    this.fallGang = n"";
    this.offerWins = 0;
    this.reqColour = 0;
  }

  public func Clear() -> Void {
    this.m_colour = 0;
    ArrayClear(this.m_standGang);
    ArrayClear(this.m_standValue);
    this.m_standDay = 0;
    ArrayClear(this.m_fallen);
    this.m_recruiter = 0;
    this.fallCause = 0;
    this.fallGang = n"";
    this.offerWins = 0;
    this.reqColour = 0;
  }

  // ---- Colours ----

  public func Colour() -> Int32 {
    let c = this.m_colour > 0 ? this.m_colour - 1 : CBConfig.CrewColourDefault();
    return Clamp(c, 0, CBCrewColourCount() - 1);
  }

  public func SetColour(c: Int32) -> Void {
    this.m_colour = Clamp(c, 0, CBCrewColourCount() - 1) + 1;
  }

  // ---- Standing ----

  public func Standing(gang: CName) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_standGang) && i < ArraySize(this.m_standValue) {
      if Equals(this.m_standGang[i], gang) {
        return this.m_standValue[i];
      }
      i += 1;
    }
    return 0;
  }

  public func Shift(gang: CName, delta: Int32) -> Void {
    if !IsNameValid(gang) || delta == 0 {
      return;
    }
    let i = 0;
    while i < ArraySize(this.m_standGang) && i < ArraySize(this.m_standValue) {
      if Equals(this.m_standGang[i], gang) {
        this.m_standValue[i] = Clamp(this.m_standValue[i] + delta, -100, 100);
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_standGang, gang);
    ArrayPush(this.m_standValue, Clamp(delta, -100, 100));
  }

  public func StandCount() -> Int32 {
    return Min(ArraySize(this.m_standGang), ArraySize(this.m_standValue));
  }

  public func StandGangAt(i: Int32) -> CName {
    return i >= 0 && i < this.StandCount() ? this.m_standGang[i] : n"";
  }

  public func StandValueAt(i: Int32) -> Int32 {
    return i >= 0 && i < this.StandCount() ? this.m_standValue[i] : 0;
  }

  // Once a game day, every standing a step back towards nothing; the ones at nothing forgotten.
  public func Ease(day: Int32) -> Void {
    if this.m_standDay == day {
      return;
    }
    let first = this.m_standDay == 0;
    this.m_standDay = day;
    if first {
      return;
    }
    let step = CBConfig.CrewStandEase();
    let i = this.StandCount() - 1;
    while i >= 0 {
      let v = this.m_standValue[i];
      v = v > 0 ? Max(0, v - step) : Min(0, v + step);
      if v == 0 {
        ArrayErase(this.m_standGang, i);
        ArrayErase(this.m_standValue, i);
      } else {
        this.m_standValue[i] = v;
      }
      i -= 1;
    }
  }

  // ---- The fallen ----

  public func Remember(f: ref<CBCrewFallen>) -> Void {
    if !IsDefined(f) {
      return;
    }
    ArrayPush(this.m_fallen, f);
    while ArraySize(this.m_fallen) > CBConfig.CrewFallenKept() {
      ArrayErase(this.m_fallen, 0);
    }
  }

  public func FallenCount() -> Int32 {
    return ArraySize(this.m_fallen);
  }

  public func FallenAt(i: Int32) -> ref<CBCrewFallen> {
    return i >= 0 && i < ArraySize(this.m_fallen) ? this.m_fallen[i] : null;
  }

  // A Rival the memorial names: kept like the roster's own past keeps them (CBCrewBook.Keeps).
  public func RemembersRival(rivalId: Int32) -> Bool {
    if rivalId <= 0 {
      return false;
    }
    for f in this.m_fallen {
      if IsDefined(f) && f.rival == rivalId {
        return true;
      }
    }
    return false;
  }

  // ---- The recruiter ----

  public func Recruiter() -> Int32 {
    return this.m_recruiter;
  }

  public func SetRecruiter(id: Int32) -> Void {
    this.m_recruiter = Max(0, id);
  }
}

// ---- Colours --------------------------------------------------------------------------------------------------------

public func CBCrewColourCount() -> Int32 = 8

public func CBCrewColourWord(c: Int32) -> String {
  switch c {
    case 0: return CBT(n"Cyberbane-CrewBanner-Red");
    case 1: return CBT(n"Cyberbane-CrewBanner-Orange");
    case 2: return CBT(n"Cyberbane-CrewBanner-Gold");
    case 3: return CBT(n"Cyberbane-CrewBanner-Green");
    case 4: return CBT(n"Cyberbane-CrewBanner-Cyan");
    case 5: return CBT(n"Cyberbane-CrewBanner-Blue");
    case 6: return CBT(n"Cyberbane-CrewBanner-Violet");
    default: return CBT(n"Cyberbane-CrewBanner-White");
  }
}

public func CBCrewColourTint(c: Int32) -> HDRColor {
  switch c {
    case 0: return new HDRColor(0.90, 0.22, 0.24, 1.0);
    case 1: return new HDRColor(0.95, 0.50, 0.16, 1.0);
    case 2: return new HDRColor(0.92, 0.76, 0.24, 1.0);
    case 3: return new HDRColor(0.26, 0.78, 0.50, 1.0);
    case 4: return new HDRColor(0.16, 0.78, 0.88, 1.0);
    case 5: return new HDRColor(0.30, 0.48, 0.95, 1.0);
    case 6: return new HDRColor(0.68, 0.40, 0.92, 1.0);
    default: return new HDRColor(0.92, 0.92, 0.92, 1.0);
  }
}

// The colour the crew wears, or the one asked for on the Hub and not yet carried out, so the Hub shows the pick.
public func CBCrewColourIndex(game: GameInstance) -> Int32 {
  let bb = CBCrewBannerBook.Get(game);
  if !IsDefined(bb) {
    return CBConfig.CrewColourDefault();
  }
  return bb.reqColour > 0 ? Clamp(bb.reqColour - 1, 0, CBCrewColourCount() - 1) : bb.Colour();
}

public func CBCrewColour(game: GameInstance) -> HDRColor {
  return CBCrewColourTint(CBCrewColourIndex(game));
}

// ---- Standing -------------------------------------------------------------------------------------------------------

public func CBCrewStandingWith(game: GameInstance, gang: CName) -> Int32 {
  let bb = CBCrewBannerBook.Get(game);
  return IsDefined(bb) ? bb.Standing(gang) : 0;
}

// A gang's standing with the crew moves, for what the crew did. Gangs only: the corporations and the police are not
// kept, and nor is a gang switched off.
public func CBCrewStandingShift(game: GameInstance, gang: CName, delta: Int32) -> Void {
  let bb = CBCrewBannerBook.Get(game);
  if !IsDefined(bb) || !IsNameValid(gang) || !CBFactionFieldsSquads(gang) || CBIsCorpFaction(gang) || !CBFactionOn(gang) {
    return;
  }
  bb.Shift(gang, delta);
}

public func CBCrewStandWord(v: Int32) -> String {
  if v >= 60 { return CBT(n"Cyberbane-CrewBanner-Allied"); }
  if v >= 25 { return CBT(n"Cyberbane-CrewBanner-Respected"); }
  if v > -25 { return CBT(n"Cyberbane-CrewBanner-Neutral"); }
  if v > -60 { return CBT(n"Cyberbane-CrewBanner-Hostile"); }
  return CBT(n"Cyberbane-CrewBanner-Hated");
}

public func CBCrewStandTint(v: Int32) -> HDRColor {
  if v >= 25 { return CBHudGreen(); }
  if v > -25 { return CBHudGrey(); }
  if v > -60 { return CBHudAmber(); }
  return CBHudRed();
}

// The gang that thinks least of the crew, n"" when none thinks ill of it.
public func CBCrewWorstGang(game: GameInstance) -> CName {
  let bb = CBCrewBannerBook.Get(game);
  let worst = n"";
  let low = 0;
  if !IsDefined(bb) {
    return worst;
  }
  let i = 0;
  while i < bb.StandCount() {
    if bb.StandValueAt(i) < low && CBFactionOn(bb.StandGangAt(i)) {
      low = bb.StandValueAt(i);
      worst = bb.StandGangAt(i);
    }
    i += 1;
  }
  return worst;
}

// One line for a gang's page: how they see V's crew. "" while there is no crew and no standing.
public func CBCrewStandingLine(game: GameInstance, gang: CName) -> String {
  let book = CBCrewBook.Get(game);
  let v = CBCrewStandingWith(game, gang);
  if v == 0 && (!IsDefined(book) || book.Count() == 0) {
    return "";
  }
  let who = StrLen(CBCrewNameOf(game)) > 0 ? CBCrewNameOf(game) : CBT(n"Cyberbane-CrewBanner-YourCrew");
  return CBTf(n"Cyberbane-CrewBanner-ToThem", [s"\(who)", s"\(CBCrewStandWord(v))", s"\(v)"]);
}

// ---- The fallen -----------------------------------------------------------------------------------------------------

// Taken off the roster as fallen (CBCrewBook.Remove, before their kit is forgotten): written into the memorial, with
// what they carried and how they died (fallCause and fallGang, set by whoever saw it).
public func CBCrewRememberFallen(game: GameInstance, m: ref<CBCrewMember>, by: Int32, district: CName, now: Float) -> Void {
  let bb = CBCrewBannerBook.Get(game);
  if !IsDefined(bb) || !IsDefined(m) {
    return;
  }
  let f = new CBCrewFallen();
  f.id = m.id;
  f.kind = m.kind;
  f.faction = m.faction;
  f.rival = m.rival;
  f.seed = m.seed;
  f.seat = m.seat;
  f.wins = m.wins;
  f.rank = CBCrewRankOf(game, m);
  f.by = by;
  f.district = district;
  f.joinedAt = m.joinedAt;
  f.at = now;
  f.cause = bb.fallCause;
  f.gang = bb.fallGang;
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  if IsDefined(k) {
    f.hadWeapon = k.hasWeapon;
    if k.hasWeapon {
      f.weapon = ItemID.GetTDBID(k.weapon);
      f.weaponTier = k.weaponTier;
    }
    f.chrome0 = k.ChromeAt(0);
    f.chrome1 = k.ChromeAt(1);
    f.chrome2 = k.ChromeAt(2);
    f.chrome3 = k.ChromeAt(3);
    f.trained = k.trained;
    f.spars = k.spars;
  }
  bb.Remember(f);
  bb.fallCause = CBCrewFellBeside();
  bb.fallGang = n"";
  CBLog.Info(n"Crew", s"One of the crew went into the memorial (cause \(f.cause), rank \(f.rank)).");
}

public func CBCrewFallenName(sys: ref<CyberbaneSystem>, f: ref<CBCrewFallen>) -> String {
  // Nicknamed as they were when they fell: their rank then counted their training (CBCrewRankOf), kept as f.rank.
  return IsDefined(f) ? CBCrewFullNameNicked(sys, f.kind, f.faction, f.rival, f.seed, f.rank >= 3, f.seat) : CBT(n"Cyberbane-Telling-Somebody");
}

// How they died, short enough for a row: "beside you", "at war, Maelstrom", "killed by Maelstrom".
public func CBCrewFallenShort(sys: ref<CyberbaneSystem>, f: ref<CBCrewFallen>) -> String {
  if !IsDefined(f) {
    return "";
  }
  let gang = IsNameValid(f.gang) ? CBPhoneGangSender(f.gang) : "";
  if f.cause == CBCrewFellAtWar() {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-CrewBanner-AtWar", [s"\(gang)"]) : CBT(n"Cyberbane-CrewBanner-AtWar-2");
  }
  if f.by > 0 && IsDefined(sys) && IsDefined(sys.FindRivalById(f.by)) {
    return CBT(n"Cyberbane-CrewBanner-KilledByARival");
  }
  return StrLen(gang) > 0 ? CBTf(n"Cyberbane-CrewBanner-KilledBy", [s"\(gang)"]) : CBT(n"Cyberbane-CrewBanner-BesideYou");
}

// When: "today", "yesterday", "5 days ago" (the game shows no day numbers, so none are used here).
public func CBCrewFallenAgo(game: GameInstance, f: ref<CBCrewFallen>) -> String {
  if !IsDefined(f) {
    return "";
  }
  let days = FloorF((CBGameSeconds(game) - f.at) / CBConfig.SecondsPerDay());
  if days <= 0 { return CBT(n"Cyberbane-CrewBanner-Today"); }
  if days == 1 { return CBT(n"Cyberbane-CrewBanner-Yesterday"); }
  return CBTf(n"Cyberbane-CrewBanner-DaysAgo", [s"\(days)"]);
}

// The memorial's words for one of them.
public func CBCrewEpitaph(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBCrewFallen>) -> String {
  if !IsDefined(f) {
    return "";
  }
  let out = StrUpper(CBCrewFallenName(sys, f)) + "\n";
  let gang = IsNameValid(f.faction) ? CBFactionLabel(f.faction) : "";
  let origin = CBT(n"Cyberbane-CrewBanner-ASoloYouPaid");
  if f.kind == CBCrewOwed() { origin = StrLen(gang) > 0 ? CBTf(n"Cyberbane-CrewBanner-OnceOfWhoOwedYouA", [s"\(gang)"]) : CBT(n"Cyberbane-CrewBanner-WhoOwedYouALife"); }
  if f.kind == CBCrewFrightened() { origin = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-OnceOfScaredIntoWorkingFor", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-ScaredIntoWorkingForYou"); }
  if f.kind == CBCrewLent() { origin = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-OnLoanFrom", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-OnLoan"); }
  if f.kind == CBCrewAlly() { origin = CBT(n"Cyberbane-CrewDoor-AFriendWhoThrewInWithYou"); }
  out += CBTf(n"Cyberbane-CrewBanner-A", [s"\(CBCrewRankWord(f.rank))", s"\(CBCrewSeatWord(f.seat))", s"\(origin)"]);
  let how = CBT(n"Cyberbane-CrewBanner-DiedFightingBesideYou");
  let killers = IsNameValid(f.gang) ? CBFactionLabel(f.gang) : "";
  if f.cause == CBCrewFellAtWar() {
    how = StrLen(killers) > 0 ? CBTf(n"Cyberbane-CrewBanner-DiedInTheWarTheyStarted", [s"\(killers)"]) : CBT(n"Cyberbane-CrewBanner-DiedInAWarTheyStarted");
  } else {
    let r = f.by > 0 && IsDefined(sys) ? sys.FindRivalById(f.by) : null;
    if IsDefined(r) {
      how = CBTf(n"Cyberbane-CrewBanner-KilledBy-2", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]);
    } else {
      if StrLen(killers) > 0 {
        how = CBTf(n"Cyberbane-CrewBanner-KilledBy-2", [s"\(killers)"]);
      }
    }
  }
  let place = IsNameValid(f.district) ? CBTf(n"Cyberbane-CrewBanner-In", [s"\(CBDistrictLabel(f.district))"]) : "";
  let days = f.joinedAt > 0.0 ? FloorF((f.at - f.joinedAt) / CBConfig.SecondsPerDay()) : 0;
  let tenure = days >= 1 ? CBTf(n"Cyberbane-CrewBanner-AfterWithYourCrew", [s"\(days)", days == 1 ? CBT(n"Cyberbane-CrewBanner-Day") : CBT(n"Cyberbane-CrewBanner-Days")]) : CBT(n"Cyberbane-CrewBanner-OnTheirFirstDayWithYour");
  out += s"\(how),\(place) \(CBCrewFallenAgo(game, f)),\(tenure)";
  if f.wins > 0 {
    out += CBTf(n"Cyberbane-CrewBanner-WonBesideYou", [s"\(f.wins)", f.wins == 1 ? CBT(n"Cyberbane-CrewBanner-Fight") : CBT(n"Cyberbane-CrewBanner-Fights")]);
  }
  out += "\n";
  if f.hadWeapon && TDBID.IsValid(f.weapon) {
    out += CBTf(n"Cyberbane-CrewBanner-TheyCarriedYourItCameBack", [s"\(CBCrewItemName(f.weapon))", s"\(CBCrewTierWord(f.weaponTier))"]);
  } else {
    out += CBT(n"Cyberbane-CrewBanner-TheyCarriedNothingOfYours");
  }
  let parts = f.ChromeNames();
  if StrLen(parts) > 0 {
    out += CBTf(n"Cyberbane-CrewBanner-ChromeYouGaveThem", [s"\(parts)"]);
  }
  if f.trained > 0 || f.spars > 0 {
    out += CBTf(n"Cyberbane-CrewBanner-TrainedSparredWithYou", [s"\(f.trained)", f.trained == 1 ? CBT(n"Cyberbane-CrewBanner-Time") : CBT(n"Cyberbane-CrewBanner-Times"), s"\(f.spars)", f.spars == 1 ? CBT(n"Cyberbane-CrewBanner-Time") : CBT(n"Cyberbane-CrewBanner-Times")]);
  }
  return out;
}

// ---- The recruiter --------------------------------------------------------------------------------------------------

// The member recruiting, while they can: on the roster, here, and not hurt.
public func CBCrewRecruiterReady(game: GameInstance, book: ref<CBCrewBook>, now: Float) -> ref<CBCrewMember> {
  let bb = CBCrewBannerBook.Get(game);
  let m = IsDefined(bb) && IsDefined(book) && bb.Recruiter() > 0 ? book.Find(bb.Recruiter()) : null;
  if !IsDefined(m) || CBCrewHurt(m, now) || CBCrewAway(game, m.id, now) {
    return null;
  }
  return m;
}

public func CBCrewIsRecruiter(game: GameInstance, id: Int32) -> Bool {
  let bb = CBCrewBannerBook.Get(game);
  return IsDefined(bb) && id > 0 && bb.Recruiter() == id;
}

// What a member's work is: 0 none, 1 earning, 2 recruiting, 3 watching the house.
public func CBCrewWorkOf(game: GameInstance, id: Int32) -> Int32 {
  let gb = CBGuardBook.Get(game);
  if IsDefined(gb) && gb.IsGuard(id) {
    return CBCrewWorkGuard();
  }
  let jb = CBCrewJobBook.Get(game);
  if IsDefined(jb) && jb.IsRunner(id) {
    return CBCrewWorkRunner();
  }
  if CBCrewIsRecruiter(game, id) {
    return 2;
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(id) : null;
  return IsDefined(k) && k.earning ? 1 : 0;
}

// The next work, as the Hub's Work row asks for it: none, then earning, then recruiting (when nobody else is), then
// watching the house (while the watch has room), then none.
public func CBCrewNextWork(game: GameInstance, id: Int32) -> Int32 {
  let now = CBCrewWorkOf(game, id);
  if now == 0 {
    return 1;
  }
  if now == 1 {
    let bb = CBCrewBannerBook.Get(game);
    if !IsDefined(bb) || bb.Recruiter() <= 0 || bb.Recruiter() == id {
      return 2;
    }
  }
  if now == 1 || now == 2 {
    let gb = CBGuardBook.Get(game);
    if CBGuardsOn() && IsDefined(gb) && gb.Count() < CBGuardsMax() {
      return CBCrewWorkGuard();
    }
  }
  // Then running the money to V.
  if now != CBCrewWorkRunner() && CBCrewJobsOn() {
    return CBCrewWorkRunner();
  }
  return 0;
}

public func CBCrewWorkWord(work: Int32) -> String {
  if work == 1 { return CBT(n"Cyberbane-CrewBanner-Earning"); }
  if work == 2 { return CBT(n"Cyberbane-CrewBanner-Recruiting"); }
  if work == 3 { return CBT(n"Cyberbane-CrewHome-WatchingTheHouse"); }
  if work == 4 { return CBT(n"Cyberbane-CrewJobs-RunningTheMoney"); }
  return CBT(n"Cyberbane-CrewBanner-None");
}

// Carried out on the tick, for the Hub's Work row (CBCrewKitService, CBCrewAskWork).
public func CBCrewSetWork(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> Void {
  let kb = CBCrewKitBook.Get(game);
  let bb = CBCrewBannerBook.Get(game);
  if !IsDefined(kb) || !IsDefined(bb) || !IsDefined(m) {
    return;
  }
  let next = CBCrewNextWork(game, m.id);
  let k = kb.Kit(m.id);
  k.earning = next == 1;
  if next == 2 {
    bb.SetRecruiter(m.id);
  } else {
    if bb.Recruiter() == m.id {
      bb.SetRecruiter(0);
    }
  }
  let gb = CBGuardBook.Get(game);
  if next == CBCrewWorkGuard() && IsDefined(gb) {
    gb.Add(m.id);
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewHome-IllKeepAnEyeOnTheHouse"), false, false, n"Work");
  } else {
    CBGuardStandDown(game, m.id);
  }
  let jb = CBCrewJobBook.Get(game);
  if IsDefined(jb) {
    if next == CBCrewWorkRunner() {
      jb.AddRunner(m.id);
      CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewJobs-IllRunTheMoney"), false, false, n"Work");
    } else {
      jb.RemoveRunner(m.id);
    }
  }
  if next == 1 {
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewBanner-ILlWorkTheStreetFor"), false, false, n"Work");
  }
  if next == 2 {
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewBanner-ILlAskAroundForPeople"), false, false, n"Work");
  }
  if next == 0 {
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewBanner-DoneWorkingIMHereWhen"), false, false, n"Work");
  }
  CBLog.Info(n"Crew", s"One of the crew was put to work: \(CBCrewWorkWord(next)).");
}

// Off the roster: no longer recruiting, nor watching the house.
public func CBCrewBannerLeaves(game: GameInstance, id: Int32) -> Void {
  let bb = CBCrewBannerBook.Get(game);
  if IsDefined(bb) && bb.Recruiter() == id {
    bb.SetRecruiter(0);
  }
  CBGuardStandDown(game, id);
  let jb = CBCrewJobBook.Get(game);
  if IsDefined(jb) {
    jb.Forget(id);
  }
}

// ---- On the tick ----------------------------------------------------------------------------------------------------

public func CBCrewBannerTick(sys: ref<CyberbaneSystem>, game: GameInstance, now: Float) -> Void {
  let bb = CBCrewBannerBook.Get(game);
  if !IsDefined(bb) {
    return;
  }
  if bb.reqColour > 0 {
    bb.SetColour(bb.reqColour - 1);
    bb.reqColour = 0;
    CBLog.Info(n"Crew", s"V gave the crew its colours: \(CBCrewColourWord(bb.Colour())).");
  }
  bb.Ease(CBCrewSparDayOf(now));
}
