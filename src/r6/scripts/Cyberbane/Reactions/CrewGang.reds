// Cyberbane - The crew as a gang
//
// Who runs each district the crew holds, the crew's own place, what the kitty buys, how big the crew has grown, the
// marks a war leaves on a member, and members who retire alive.

// What the kitty can buy, one bit each.
public func CBUpgradeTraining() -> Int32 = 1
public func CBUpgradeArmoury() -> Int32 = 2
public func CBUpgradeCar() -> Int32 = 4
public func CBUpgradeSafehouse() -> Int32 = 8

// The marks a war leaves.
public func CBMarkLeg() -> Int32 = 1
public func CBMarkNerves() -> Int32 = 2
public func CBMarkArm() -> Int32 = 3

public func CBCrewEndRetired() -> Int32 = 5

public class CBCrewGangBook extends ScriptableSystem {
  private persistent let m_runDistrict: array<CName>;
  private persistent let m_runMember: array<Int32>;
  private persistent let m_placeSet: Bool;
  private persistent let m_placeX: Float;
  private persistent let m_placeY: Float;
  private persistent let m_placeZ: Float;
  private persistent let m_placeDistrict: CName;
  private persistent let m_upgrades: Int32;
  private persistent let m_safehouse: CName;
  private persistent let m_markId: array<Int32>;
  private persistent let m_markKind: array<Int32>;
  private persistent let m_cornersEmptyUntil: Float;
  private persistent let m_retiredTextAt: Float;
  private persistent let m_reportDay: Int32;
  private persistent let m_runnerLostAt: array<Float>;   // per district, in step with m_runDistrict: 0 while one runs it

  public static func Get(game: GameInstance) -> ref<CBCrewGangBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewGangBook") as CBCrewGangBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    let n = Min(Min(ArraySize(this.m_runDistrict), ArraySize(this.m_runMember)), ArraySize(this.m_runnerLostAt));
    ArrayResize(this.m_runDistrict, n);
    ArrayResize(this.m_runMember, n);
    ArrayResize(this.m_runnerLostAt, n);
    let k = Min(ArraySize(this.m_markId), ArraySize(this.m_markKind));
    ArrayResize(this.m_markId, k);
    ArrayResize(this.m_markKind, k);
  }

  public func Clear() -> Void {
    ArrayClear(this.m_runDistrict);
    ArrayClear(this.m_runMember);
    ArrayClear(this.m_runnerLostAt);
    this.m_placeSet = false;
    this.m_placeDistrict = n"";
    this.m_upgrades = 0;
    this.m_safehouse = n"";
    ArrayClear(this.m_markId);
    ArrayClear(this.m_markKind);
    this.m_cornersEmptyUntil = 0.0;
    this.m_retiredTextAt = 0.0;
    this.m_reportDay = 0;
  }

  // ---- Who runs a district ----
  private func RunIndex(d: CName) -> Int32 {
    let i = 0;
    while i < Min(ArraySize(this.m_runDistrict), ArraySize(this.m_runMember)) {
      if Equals(this.m_runDistrict[i], d) {
        return i;
      }
      i += 1;
    }
    return -1;
  }
  public func Runner(d: CName) -> Int32 {
    let i = this.RunIndex(d);
    return i >= 0 ? this.m_runMember[i] : 0;
  }
  public func RunnerLostAt(d: CName) -> Float {
    let i = this.RunIndex(d);
    return i >= 0 && i < ArraySize(this.m_runnerLostAt) ? this.m_runnerLostAt[i] : 0.0;
  }
  public func SetRunner(d: CName, id: Int32) -> Void {
    // Nobody runs two places.
    let j = 0;
    while j < ArraySize(this.m_runMember) {
      if this.m_runMember[j] == id && id > 0 && NotEquals(this.m_runDistrict[j], d) {
        this.m_runMember[j] = 0;
        this.m_runnerLostAt[j] = CBGameSeconds(GetGameInstance());
      }
      j += 1;
    }
    let i = this.RunIndex(d);
    if i < 0 {
      ArrayPush(this.m_runDistrict, d);
      ArrayPush(this.m_runMember, id);
      ArrayPush(this.m_runnerLostAt, 0.0);
      return;
    }
    this.m_runMember[i] = id;
    this.m_runnerLostAt[i] = 0.0;
  }
  public func RunsWhere(id: Int32) -> CName {
    let i = 0;
    while i < Min(ArraySize(this.m_runDistrict), ArraySize(this.m_runMember)) {
      if this.m_runMember[i] == id && id > 0 {
        return this.m_runDistrict[i];
      }
      i += 1;
    }
    return n"";
  }
  // A runner gone from the roster: the place has nobody, and the hold weakens until somebody takes over.
  public func RunnerGone(id: Int32, now: Float) -> CName {
    let i = 0;
    while i < Min(ArraySize(this.m_runDistrict), ArraySize(this.m_runMember)) {
      if this.m_runMember[i] == id && id > 0 {
        this.m_runMember[i] = 0;
        this.m_runnerLostAt[i] = now;
        return this.m_runDistrict[i];
      }
      i += 1;
    }
    return n"";
  }

  // ---- The crew's place ----
  public func PlaceSet() -> Bool { return this.m_placeSet; }
  public func PlaceAt() -> Vector4 { return new Vector4(this.m_placeX, this.m_placeY, this.m_placeZ, 1.0); }
  public func PlaceDistrict() -> CName { return this.m_placeDistrict; }
  public func SetPlace(at: Vector4, d: CName) -> Void {
    this.m_placeSet = true;
    this.m_placeX = at.X;
    this.m_placeY = at.Y;
    this.m_placeZ = at.Z;
    this.m_placeDistrict = d;
  }
  public func ClearPlace() -> Void { this.m_placeSet = false; }

  // ---- Upgrades ----
  public func Has(bit: Int32) -> Bool { return (this.m_upgrades & bit) != 0; }
  public func Buy(bit: Int32) -> Void { this.m_upgrades = this.m_upgrades | bit; }
  public func Safehouse() -> CName { return this.m_safehouse; }
  public func SetSafehouse(d: CName) -> Void { this.m_safehouse = d; }

  // ---- Marks ----
  public func HasMark(id: Int32, kind: Int32) -> Bool {
    let i = 0;
    while i < Min(ArraySize(this.m_markId), ArraySize(this.m_markKind)) {
      if this.m_markId[i] == id && this.m_markKind[i] == kind {
        return true;
      }
      i += 1;
    }
    return false;
  }
  public func AddMark(id: Int32, kind: Int32) -> Void {
    if !this.HasMark(id, kind) {
      ArrayPush(this.m_markId, id);
      ArrayPush(this.m_markKind, kind);
    }
  }
  public func DropMark(id: Int32, kind: Int32) -> Void {
    let i = Min(ArraySize(this.m_markId), ArraySize(this.m_markKind)) - 1;
    while i >= 0 {
      if this.m_markId[i] == id && (kind == 0 || this.m_markKind[i] == kind) {
        ArrayErase(this.m_markId, i);
        ArrayErase(this.m_markKind, i);
      }
      i -= 1;
    }
  }
  public func MarksOf(id: Int32) -> array<Int32> {
    let out: array<Int32>;
    let i = 0;
    while i < Min(ArraySize(this.m_markId), ArraySize(this.m_markKind)) {
      if this.m_markId[i] == id {
        ArrayPush(out, this.m_markKind[i]);
      }
      i += 1;
    }
    return out;
  }

  // ---- The rest ----
  public func CornersEmptyUntil() -> Float { return this.m_cornersEmptyUntil; }
  public func SetCornersEmptyUntil(at: Float) -> Void { this.m_cornersEmptyUntil = at; }
  public func RetiredTextAt() -> Float { return this.m_retiredTextAt; }
  public func SetRetiredTextAt(at: Float) -> Void { this.m_retiredTextAt = at; }
  public func ReportDay() -> Int32 { return this.m_reportDay; }
  public func SetReportDay(d: Int32) -> Void { this.m_reportDay = d; }
}

// ---- Who runs a district (C1) ---------------------------------------------------------------------------------------

// Somebody who can run a place: Lieutenant and up, on the roster, not held by a gang.
public func CBCrewCanRun(game: GameInstance, m: ref<CBCrewMember>) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  return IsDefined(m) && CBCrewRankOf(game, m) >= CBConfig.CrewWarMinRank() && !(IsDefined(fb) && IsDefined(fb.FindCaptive(m.id)));
}

public func CBRunnerOf(game: GameInstance, d: CName) -> ref<CBCrewMember> {
  let gb = CBCrewGangBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(gb) || !IsDefined(book) {
    return null;
  }
  let id = gb.Runner(d);
  return id > 0 ? book.Find(id) : null;
}

// What the one who runs it adds when a district is hit: their rank, and the hold itself until somebody takes over.
public func CBRunnerDefence(game: GameInstance, d: CName) -> Float {
  let m = CBRunnerOf(game, d);
  return IsDefined(m) ? CBConfig.RunnerDefencePerRank() * Cast<Float>(CBCrewRankOf(game, m)) : 0.0;
}

// The street tax from a district, by who runs it: a steady hand brings in more, a greedy one keeps some, nobody there
// brings in half.
public func CBRunnerTaxMult(game: GameInstance, d: CName) -> Float {
  let m = CBRunnerOf(game, d);
  if !IsDefined(m) {
    let gb = CBCrewGangBook.Get(game);
    return IsDefined(gb) && gb.RunnerLostAt(d) > 0.0 ? 0.5 : 1.0;
  }
  let t = CBCrewTemper(m);
  if t == CBTemperCareful() { return CBConfig.RunnerTaxSteady(); }
  if t == CBTemperMoney() { return CBConfig.RunnerTaxGreedy(); }
  return 1.0;
}

// A member leaving the roster: whatever they ran has nobody now, their marks are forgotten (from CBCrewBook.Remove).
public func CBCrewGangMemberLeaves(game: GameInstance, id: Int32) -> Void {
  let gb = CBCrewGangBook.Get(game);
  if !IsDefined(gb) {
    return;
  }
  let now = CBGameSeconds(game);
  let d = gb.RunnerGone(id, now);
  if IsNameValid(d) {
    let sys = CyberbaneSystem.Get(game);
    CBCrewTurfRaise(sys, game, d, -CBConfig.RunnerLostFoot());
  }
  gb.DropMark(id, 0);
}

// "Ryo runs Arroyo", for the turf map and the crew page; "" when nobody does.
public func CBRunnerLine(sys: ref<CyberbaneSystem>, game: GameInstance, d: CName) -> String {
  let m = CBRunnerOf(game, d);
  return IsDefined(m) ? CBTf(n"Cyberbane-GangWar-RunsIt", [CBCrewFirst(sys, m), CBDistrictLabel(d)]) : "";
}

// ---- The crew's place (C3) -------------------------------------------------------------------------------------------

public func CBCrewPlaceSet(game: GameInstance) -> Bool {
  let gb = CBCrewGangBook.Get(game);
  return IsDefined(gb) && gb.PlaceSet();
}

public func CBCrewPlaceAt(game: GameInstance, out at: Vector4) -> Bool {
  let gb = CBCrewGangBook.Get(game);
  if !IsDefined(gb) || !gb.PlaceSet() {
    return false;
  }
  at = gb.PlaceAt();
  return true;
}

// The cleared gig places in districts the crew holds, which could be the crew's place: indexes into the base book.
public func CBCrewPlaceChoices(sys: ref<CyberbaneSystem>, game: GameInstance) -> array<Int32> {
  let out: array<Int32>;
  let bases = CBBaseBook.Get(game);
  if !IsDefined(bases) {
    return out;
  }
  let held = CBCrewHeldDistricts(sys, game);
  let i = 0;
  while i < bases.BaseCount() {
    if ArrayContains(held, bases.BaseDistrictAt(i)) {
      ArrayPush(out, i);
    }
    i += 1;
  }
  return out;
}

public func CBCrewMakePlace(sys: ref<CyberbaneSystem>, game: GameInstance, baseIndex: Int32) -> Bool {
  let bases = CBBaseBook.Get(game);
  let gb = CBCrewGangBook.Get(game);
  if !IsDefined(bases) || !IsDefined(gb) || baseIndex < 0 || baseIndex >= bases.BaseCount() {
    return false;
  }
  gb.SetPlace(bases.BaseAt(baseIndex), bases.BaseDistrictAt(baseIndex));
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-PlaceMade", [CBBaseName(game, bases.BaseHashAt(baseIndex))]), true);
  }
  return true;
}

// V at the crew's place.
public func CBAtCrewPlace(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  let at: Vector4;
  return IsDefined(player) && CBCrewPlaceAt(game, at) && Vector4.Distance(player.GetWorldPosition(), at) <= CBConfig.CrewPlaceReach();
}

// ---- What the kitty buys (C4) ---------------------------------------------------------------------------------------

public func CBUpgradePrice(bit: Int32) -> Int32 {
  if bit == CBUpgradeTraining() { return CBReward(CBConfig.UpgradeTrainingPrice()); }
  if bit == CBUpgradeArmoury() { return CBReward(CBConfig.UpgradeArmouryPrice()); }
  if bit == CBUpgradeCar() { return CBReward(CBConfig.UpgradeCarPrice()); }
  return CBReward(CBConfig.UpgradeSafehousePrice());
}

public func CBUpgradeWord(bit: Int32) -> String {
  if bit == CBUpgradeTraining() { return CBT(n"Cyberbane-GangWar-UpgradeTraining"); }
  if bit == CBUpgradeArmoury() { return CBT(n"Cyberbane-GangWar-UpgradeArmoury"); }
  if bit == CBUpgradeCar() { return CBT(n"Cyberbane-GangWar-UpgradeCar"); }
  return CBT(n"Cyberbane-GangWar-UpgradeSafehouse");
}

public func CBUpgradeHelp(bit: Int32) -> String {
  if bit == CBUpgradeTraining() { return CBT(n"Cyberbane-GangWar-UpgradeTrainingHelp"); }
  if bit == CBUpgradeArmoury() { return CBT(n"Cyberbane-GangWar-UpgradeArmouryHelp"); }
  if bit == CBUpgradeCar() { return CBT(n"Cyberbane-GangWar-UpgradeCarHelp"); }
  return CBT(n"Cyberbane-GangWar-UpgradeSafehouseHelp");
}

public func CBCrewHas(game: GameInstance, bit: Int32) -> Bool {
  let gb = CBCrewGangBook.Get(game);
  return IsDefined(gb) && gb.Has(bit);
}

// Bought from the kitty, once the squads' wages are covered. "" when bought, otherwise why not.
public func CBCrewBuyUpgrade(sys: ref<CyberbaneSystem>, game: GameInstance, bit: Int32) -> String {
  let gb = CBCrewGangBook.Get(game);
  let jb = CBCrewJobBook.Get(game);
  if !IsDefined(gb) || !IsDefined(jb) {
    return CBT(n"Cyberbane-GangWar-NoKitty");
  }
  if gb.Has(bit) {
    return CBT(n"Cyberbane-GangWar-AlreadyBought");
  }
  let price = CBUpgradePrice(bit);
  if jb.Kitty() - CBSquadWagesWeek(game) < price {
    return CBTf(n"Cyberbane-GangWar-KittyShort", [s"\(price)", s"\(CBSquadWagesWeek(game))"]);
  }
  if bit == CBUpgradeSafehouse() {
    let held = CBCrewHeldDistricts(sys, game);
    if ArraySize(held) == 0 {
      return CBT(n"Cyberbane-GangWar-SafehouseNeedsGround");
    }
    gb.SetSafehouse(held[0]);
  }
  jb.AddKitty(-price);
  gb.Buy(bit);
  CBFileLog(sys, n"CrewBought", CBGameSeconds(game), sys.GetCurrentDistrict(), n"", Cast<Float>(bit));
  return "";
}

// How fast the hurt heal now: a bed at the crew's home, and a safehouse.
public func CBCrewHealFactorNow(game: GameInstance) -> Float {
  return CBCrewHomeHealFactor(game);
}

// The crew's own car (the second car the kitty buys): ready at once, waited for longer, and one more a call.
// The second car, or hustlers set to run the crew's cars (Reactions/Squads.reds).
func CBCrewCarsReady(game: GameInstance) -> Bool {
  return CBCrewHas(game, CBUpgradeCar()) || CBSquadStanding(game, CBSquadRunners(), 2);
}

public func CBCrewCarWaitTicks(game: GameInstance) -> Int32 {
  return CBCrewCarsReady(game) ? 1 : CBConfig.CrewCarWaitTicks();
}

public func CBCrewCarGiveUpTicks(game: GameInstance) -> Int32 {
  return CBCrewCarsReady(game) ? CBConfig.CrewCarGiveUpTicks() * 2 : CBConfig.CrewCarGiveUpTicks();
}

public func CBCrewCarMaxPerCall(game: GameInstance) -> Int32 {
  return CBCrewCarsReady(game) ? CBConfig.CrewCarMaxPerCall() + 1 : CBConfig.CrewCarMaxPerCall();
}

// ---- How big the crew has grown (C5) --------------------------------------------------------------------------------

// The crew's power with no ceiling: its members, their ranks, the wars it has won, and its squads.
public func CBCrewPower(game: GameInstance) -> Float {
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
    w += CBConfig.CrewWeightPerWar() * Cast<Float>(kb.WarsWon());
  }
  w += CBSquadsPower(game);
  return w;
}

// A few friends, a crew, a gang, a power in the city.
public func CBCrewTier(game: GameInstance) -> Int32 {
  let p = CBCrewPower(game);
  if p >= CBConfig.CrewTierPower() { return 3; }
  if p >= CBConfig.CrewTierGang() { return 2; }
  if p >= CBConfig.CrewTierCrew() { return 1; }
  return 0;
}

public func CBCrewSizeWord(tier: Int32) -> String {
  if tier >= 3 { return CBT(n"Cyberbane-GangWar-TierPower"); }
  if tier == 2 { return CBT(n"Cyberbane-GangWar-TierGang"); }
  if tier == 1 { return CBT(n"Cyberbane-GangWar-TierCrew"); }
  return CBT(n"Cyberbane-GangWar-TierFriends");
}

// What the tier changes in how gangs treat the crew, once a day: respect drifts up with a gang that has not been fought, and a
// big crew is asked to sit-downs and called on for help.
public func CBCrewTierDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let tier = CBCrewTier(game);
  if tier < 2 || !CBMyCrewOn() {
    return;
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) && !CBCrewWarOn(game, fs.id)
       && CBCrewStandingWith(game, fs.id) >= 0 {
      CBCrewStandingShift(game, fs.id, tier - 1);
    }
  }
  // A power in the city: a friendly boss calls now and then to ask the crew's help against their enemy (W5 the other way).
  if tier >= 3 && RandF() < CBConfig.TierBossCallChance() {
    CBCrewBossAsksHelp(sys, game);
  }
}

func CBCrewBossAsksHelp(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let score = sys.GetScore();
  let content = sys.GetContent();
  if !IsDefined(score) || !IsDefined(content) {
    return;
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && Equals(score.GetPosture(fs.id), ECBPosture.Allied) {
      let enemy = CBTopEnemyOf(sys, content, fs.id);
      if IsNameValid(enemy) && !CBCrewWarOn(game, enemy) && CBMessagesOn() {
        CBPhoneFromAlly(game, fs.id, CBGangBossSigned(sys, game, fs.id, CBTf(n"Cyberbane-GangWar-BossAsksHelp", [CBFactionLabel(enemy)])));
        return;
      }
    }
  }
}

// ---- Marks and leaving alive (C7) -----------------------------------------------------------------------------------

// A bad fight may leave a mark that stays: a bad leg, nerves, a lost arm that wants chrome.
public func CBCrewMaybeScar(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, bad: Bool) -> Void {
  let gb = CBCrewGangBook.Get(game);
  if !IsDefined(gb) || !IsDefined(m) || RandF() >= (bad ? CBConfig.MarkChanceBad() : CBConfig.MarkChance()) {
    return;
  }
  let kind = RandRange(1, 4);
  if gb.HasMark(m.id, kind) {
    return;
  }
  gb.AddMark(m.id, kind);
  m.scars += 1;
  CBCrewLifeNote(game, m.id, CBLifeScar(), CBEventDistrict(sys, game), 0);
  if CBMessagesOn() {
    CBCrewText(sys, game, m, CBMarkLine(kind));
  }
}

public func CBMarkWord(kind: Int32) -> String {
  if kind == CBMarkLeg() { return CBT(n"Cyberbane-GangWar-MarkLeg"); }
  if kind == CBMarkNerves() { return CBT(n"Cyberbane-GangWar-MarkNerves"); }
  return CBT(n"Cyberbane-GangWar-MarkArm");
}

func CBMarkLine(kind: Int32) -> String {
  if kind == CBMarkLeg() { return CBT(n"Cyberbane-GangWar-MarkLegLine"); }
  if kind == CBMarkNerves() { return CBT(n"Cyberbane-GangWar-MarkNervesLine"); }
  return CBT(n"Cyberbane-GangWar-MarkArmLine");
}

// What their marks cost them in a war: a leg slows them, an arm lost weighs most.
public func CBCrewMarkMult(game: GameInstance, id: Int32) -> Float {
  let gb = CBCrewGangBook.Get(game);
  if !IsDefined(gb) {
    return 1.0;
  }
  let f = 1.0;
  if gb.HasMark(id, CBMarkLeg()) { f *= CBConfig.MarkLegMult(); }
  if gb.HasMark(id, CBMarkArm()) { f *= CBConfig.MarkArmMult(); }
  return f;
}

// "bad leg, nerves", for the member view; "" with none.
public func CBCrewMarksLine(game: GameInstance, id: Int32) -> String {
  let gb = CBCrewGangBook.Get(game);
  if !IsDefined(gb) {
    return "";
  }
  let out = "";
  let marks = gb.MarksOf(id);
  for k in marks {
    out = StrLen(out) > 0 ? out + ", " + CBMarkWord(k) : CBMarkWord(k);
  }
  return out;
}

// Chrome went in: an arm lost is an arm replaced.
public func CBCrewChromeHealsMark(game: GameInstance, id: Int32) -> Void {
  let gb = CBCrewGangBook.Get(game);
  if IsDefined(gb) {
    gb.DropMark(id, CBMarkArm());
  }
}

// Retired alive (from the Hub): off the roster, a friendly face, with a text now and then.
public func CBCrewRetire(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(m) || book.IsOut(m.id) {
    return;
  }
  let name = CBCrewFirst(sys, m);
  book.Remove(m, CBCrewEndRetired(), 0, IsNameValid(m.home) ? m.home : CBEventDistrict(sys, game), CBGameSeconds(game));
  if CBMessagesOn() {
    CBCrewText(sys, game, null, CBTf(n"Cyberbane-GangWar-Retired", [name]), true);
  }
}

// Once a game day: now and then one who retired sends word.
public func CBCrewRetiredDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let gb = CBCrewGangBook.Get(game);
  let book = CBCrewBook.Get(game);
  let now = CBGameSeconds(game);
  if !IsDefined(gb) || !IsDefined(book) || now < gb.RetiredTextAt() || RandF() >= CBConfig.RetiredTextChance() {
    return;
  }
  let i = book.PastCount() - 1;
  while i >= 0 {
    let p = book.PastAt(i);
    if IsDefined(p) && p.end == CBCrewEndRetired() {
      gb.SetRetiredTextAt(now + 3.0 * CBConfig.SecondsPerDay());
      if CBMessagesOn() {
        CBPhoneSendAside(game, CBCrewFirstName(sys, p.kind, p.faction, p.rival, p.seed),
                         CBLineOf([CBT(n"Cyberbane-GangWar-RetiredText1"), CBT(n"Cyberbane-GangWar-RetiredText2"), CBT(n"Cyberbane-GangWar-RetiredText3")]),
                         CBCrewColour(game));
      }
      return;
    }
    i -= 1;
  }
}

// ---- The street after a lost war (W8) -------------------------------------------------------------------------------

public func CBCrewCornersEmpty(game: GameInstance) -> Bool {
  let gb = CBCrewGangBook.Get(game);
  return IsDefined(gb) && CBGameSeconds(game) < gb.CornersEmptyUntil();
}

public func CBCrewHoldsDistrict(sys: ref<CyberbaneSystem>, game: GameInstance, d: CName) -> Bool {
  let held = CBCrewHeldDistricts(sys, game);
  return ArrayContains(held, d);
}

// ---- Daily, from the slow tick --------------------------------------------------------------------------------------

public func CBCrewGangDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let gb = CBCrewGangBook.Get(game);
  if !IsDefined(gb) || !CBMyCrewOn() {
    return;
  }
  let day = CBGameDay(game) + 1;
  if gb.ReportDay() == day {
    return;
  }
  let first = gb.ReportDay() == 0;
  gb.SetReportDay(day);
  if first {
    return;
  }
  CBSquadsDaily(sys, game);       // heads, wages, morale, the day's report (Reactions/Squads.reds)
  CBWarClientsDaily(sys, game);   // tribute, and terms broken
  CBWarTheyDeclareDaily(sys, game);
  CBCrewTierDaily(sys, game);
  CBCrewRetiredDaily(sys, game);
  // The crew's place stops being theirs if the district is lost.
  if gb.PlaceSet() && !CBCrewHoldsDistrict(sys, game, gb.PlaceDistrict()) {
    gb.ClearPlace();
    if CBMessagesOn() {
      CBCrewText(sys, game, CBCrewSecond(game), CBT(n"Cyberbane-GangWar-PlaceLost"), true);
    }
  }
}
