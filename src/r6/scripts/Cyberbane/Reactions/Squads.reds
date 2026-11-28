// Cyberbane - Squads: each leader's own people
//
// From Lieutenant up, a member gathers people of their own: a squad of up to 4, 8 at Enforcer, 12 at Legend, each with a
// job: fighters, lookouts, hitters, hustlers, guards or medics. A few of a squad's people come to V's own war fights as
// V's followers (Reactions/GangWarFight.reds); everything else a squad does is numbers, reaching the world through what
// already places, marks and pays: the war's fights, the street tax, the warnings and the kitty.

public func CBSquadGuns() -> Int32 = 1
public func CBSquadEyes() -> Int32 = 2
public func CBSquadKnives() -> Int32 = 3
public func CBSquadRunners() -> Int32 = 4
public func CBSquadWatch() -> Int32 = 5
public func CBSquadCutters() -> Int32 = 6

public class CBSquad {
  public persistent let leader: Int32;
  public persistent let kind: Int32;
  public persistent let heads: Int32;
  public persistent let skill: Float;           // 0..100
  public persistent let morale: Float;          // 0..100
  public persistent let formedAt: Float;
  public persistent let jobs: Int32;
  public persistent let lost: Int32;
  public persistent let wars: Int32;
  public persistent let standing: Int32;        // 0..2: the job it does between wars
  public persistent let noRecruit: Bool;
  public persistent let leaderlessUntil: Float; // its leader gone: it holds under its own second until then
  public persistent let unpaidWeeks: Int32;
  public persistent let paidAt: Float;
  public persistent let letters: array<Int32>;  // a name of V's choosing, as places in CBCrewNameAlphabet, one up
}

public class CBSquadBook extends ScriptableSystem {
  private persistent let m_squads: array<ref<CBSquad>>;
  // Session only: what the day's report will say.
  public let reportHeads: Int32;
  public let reportWork: array<String>;

  public static func Get(game: GameInstance) -> ref<CBSquadBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBSquadBook") as CBSquadBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.reportHeads = 0;
    ArrayClear(this.reportWork);
  }

  public func Clear() -> Void {
    ArrayClear(this.m_squads);
    this.reportHeads = 0;
    ArrayClear(this.reportWork);
  }

  public func Count() -> Int32 { return ArraySize(this.m_squads); }
  public func At(i: Int32) -> ref<CBSquad> { return i >= 0 && i < ArraySize(this.m_squads) ? this.m_squads[i] : null; }

  public func Of(leader: Int32) -> ref<CBSquad> {
    for s in this.m_squads {
      if IsDefined(s) && s.leader == leader {
        return s;
      }
    }
    return null;
  }

  public func Add(s: ref<CBSquad>) -> Void { ArrayPush(this.m_squads, s); }
  public func Drop(s: ref<CBSquad>) -> Void { ArrayRemove(this.m_squads, s); }
}

// ---- Who leads, and how big it can be (S1) ---------------------------------------------------------------------------

public func CBSquadMaxHeads(rank: Int32) -> Int32 {
  if rank >= 6 { return CBConfig.SquadHeadsLegend(); }
  if rank == 5 { return CBConfig.SquadHeadsEnforcer(); }
  if rank == 4 { return CBConfig.SquadHeadsLieutenant(); }
  return 0;
}

public func CBSquadMax(game: GameInstance, s: ref<CBSquad>) -> Int32 {
  let book = CBCrewBook.Get(game);
  let m = IsDefined(book) && IsDefined(s) ? book.Find(s.leader) : null;
  if !IsDefined(m) {
    return IsDefined(s) ? s.heads : 0;   // leaderless: it keeps what it has
  }
  return CBSquadMaxHeads(CBCrewRankOf(game, m));
}

public func CBSquadCount(game: GameInstance) -> Int32 {
  let sb = CBSquadBook.Get(game);
  return IsDefined(sb) && CBMyCrewOn() ? sb.Count() : 0;
}

// A squad of this kind at work: heads enough to do anything, its leader there or holding under its second.
public func CBSquadKindOn(game: GameInstance, kind: Int32) -> Bool {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || !CBMyCrewOn() {
    return false;
  }
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    if IsDefined(s) && s.kind == kind && s.heads >= 2 {
      return true;
    }
    i += 1;
  }
  return false;
}

// A squad can carry an order without a Lieutenant along: fighters or hitters of six heads or more.
public func CBSquadsCanLead(game: GameInstance) -> Bool {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) {
    return false;
  }
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    if IsDefined(s) && (s.kind == CBSquadGuns() || s.kind == CBSquadKnives()) && s.heads >= 6 {
      return true;
    }
    i += 1;
  }
  return false;
}

// The kind a new squad's leader suggests by the way they fight: a money temper runs goods, a careful one keeps people
// alive, a netrunner watches, a blade cuts, a heavy hits, a shooter holds.
public func CBSquadSuggest(m: ref<CBCrewMember>) -> Int32 {
  if !IsDefined(m) {
    return CBSquadGuns();
  }
  let t = CBCrewTemper(m);
  if t == CBTemperMoney() { return CBSquadRunners(); }
  if m.seat == 3 { return CBSquadEyes(); }
  if m.seat == 2 { return CBSquadKnives(); }
  if m.seat == 0 { return CBSquadGuns(); }
  return t == CBTemperCareful() ? CBSquadCutters() : CBSquadWatch();
}

public func CBSquadKindWord(kind: Int32) -> String {
  if kind == CBSquadGuns() { return CBT(n"Cyberbane-GangWar-SquadGuns"); }
  if kind == CBSquadEyes() { return CBT(n"Cyberbane-GangWar-SquadEyes"); }
  if kind == CBSquadKnives() { return CBT(n"Cyberbane-GangWar-SquadKnives"); }
  if kind == CBSquadRunners() { return CBT(n"Cyberbane-GangWar-SquadRunners"); }
  if kind == CBSquadWatch() { return CBT(n"Cyberbane-GangWar-SquadWatch"); }
  return CBT(n"Cyberbane-GangWar-SquadCutters");
}

public func CBSquadKindHelp(kind: Int32) -> String {
  if kind == CBSquadGuns() { return CBT(n"Cyberbane-GangWar-SquadGunsHelp"); }
  if kind == CBSquadEyes() { return CBT(n"Cyberbane-GangWar-SquadEyesHelp"); }
  if kind == CBSquadKnives() { return CBT(n"Cyberbane-GangWar-SquadKnivesHelp"); }
  if kind == CBSquadRunners() { return CBT(n"Cyberbane-GangWar-SquadRunnersHelp"); }
  if kind == CBSquadWatch() { return CBT(n"Cyberbane-GangWar-SquadWatchHelp"); }
  return CBT(n"Cyberbane-GangWar-SquadCuttersHelp");
}

// "Mina's Medics", or the name V gave it. The leader as the crew's texts call them (CBCrewFirst), so two leaders who share
// a first name never lead two squads of one name.
public func CBSquadName(sys: ref<CyberbaneSystem>, game: GameInstance, s: ref<CBSquad>) -> String {
  if !IsDefined(s) {
    return "";
  }
  let a = CBCrewNameAlphabet();
  let given = "";
  for c in s.letters {
    if c > 0 && c <= StrLen(a) {
      given += StrMid(a, c - 1, 1);
    }
  }
  if StrLen(given) > 0 {
    return given;
  }
  let book = CBCrewBook.Get(game);
  let m = IsDefined(book) ? book.Find(s.leader) : null;
  let who = IsDefined(m) ? CBCrewFirst(sys, m) : CBT(n"Cyberbane-GangWar-NoLeader");
  return CBTf(n"Cyberbane-GangWar-SquadName", [who, CBSquadKindWord(s.kind)]);
}

public func CBSquadSetName(s: ref<CBSquad>, text: String) -> Void {
  if !IsDefined(s) {
    return;
  }
  ArrayClear(s.letters);
  let a = CBCrewNameAlphabet();
  let trimmed = CBCrewNameTrim(text);
  let i = 0;
  while i < StrLen(trimmed) && ArraySize(s.letters) < CBConfig.CrewNameMaxLength() {
    let at = StrFindFirst(a, StrMid(trimmed, i, 1));
    if at >= 0 {
      ArrayPush(s.letters, at + 1);
    }
    i += 1;
  }
}

// ---- What a squad is worth (S4) --------------------------------------------------------------------------------------

// Heads by skill by morale, a quarter more with its leader on the job, and less than half off its own work.
public func CBSquadStrength(game: GameInstance, s: ref<CBSquad>, ownWork: Bool) -> Float {
  if !IsDefined(s) || s.heads <= 0 {
    return 0.0;
  }
  let v = Cast<Float>(s.heads) * (0.4 + 0.6 * ClampF(s.skill, 0.0, 100.0) / 100.0) * (0.5 + 0.5 * ClampF(s.morale, 0.0, 100.0) / 100.0);
  let book = CBCrewBook.Get(game);
  let leader = IsDefined(book) ? book.Find(s.leader) : null;
  if IsDefined(leader) && !CBCrewHurt(leader, CBGameSeconds(game)) {
    v *= 1.25;
  }
  return ownWork ? v : v * CBConfig.SquadOffWork();
}

// What every squad adds to the crew's power, for its tier (C5): no ceiling.
public func CBSquadsPower(game: GameInstance) -> Float {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || !CBMyCrewOn() {
    return 0.0;
  }
  let p = 0.0;
  let i = 0;
  while i < sb.Count() {
    p += CBSquadStrength(game, sb.At(i), true) * CBConfig.SquadPowerPerStrength();
    i += 1;
  }
  return p;
}

// ---- In a war (S3, S5) -----------------------------------------------------------------------------------------------

// Whose own work an order is: the fighters take their corners and storm their boss, the hitters go after a name, the hustlers
// raid a stash.
func CBSquadOrderWork(kind: Int32, order: Int32) -> Bool {
  if order == CBWarOrderCorners() { return kind == CBSquadGuns(); }
  if order == CBWarOrderStash() { return kind == CBSquadRunners(); }
  if order == CBWarOrderLieutenant() { return kind == CBSquadKnives(); }
  if order == CBWarOrderStorm() { return kind == CBSquadGuns() || kind == CBSquadKnives(); }
  return false;
}

// What the squads add to an order: whose work it is at full weight, the fighters at less than half on anybody else's.
public func CBSquadsWarWeight(game: GameInstance, f: ref<CBWarFront>, order: Int32) -> Float {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || !CBMyCrewOn() || !CBWarOrderFights(order) {
    return 0.0;
  }
  let w = 0.0;
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) {
      if CBSquadOrderWork(s.kind, order) {
        w += CBSquadStrength(game, s, true) * CBConfig.SquadWarPerStrength();
      } else {
        if s.kind == CBSquadGuns() {
          w += CBSquadStrength(game, s, false) * CBConfig.SquadWarPerStrength();
        }
      }
    }
  }
  return w;
}

// The squads working together (S5): eyes on them first, and a plan done in the right order worth more than its parts.
public func CBSquadsPlanMult(game: GameInstance, f: ref<CBWarFront>) -> Float {
  let m = 1.0;
  let eyes = CBSquadKindOn(game, CBSquadEyes());
  if eyes {
    m *= CBConfig.WarScoutedMult();
  }
  if eyes && CBSquadKindOn(game, CBSquadKnives()) && CBSquadKindOn(game, CBSquadGuns()) && CBSquadKindOn(game, CBSquadWatch()) {
    m *= CBConfig.SquadFullPlanMult();
  }
  return m;
}

// What meets their move: the guards at full, the fighters at half.
public func CBSquadsDefence(game: GameInstance, f: ref<CBWarFront>) -> Float {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || !CBMyCrewOn() {
    return 0.0;
  }
  let d = 0.0;
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) {
      if s.kind == CBSquadWatch() { d += CBSquadStrength(game, s, true) * CBConfig.SquadWarPerStrength(); }
      if s.kind == CBSquadGuns() { d += CBSquadStrength(game, s, true) * CBConfig.SquadWarPerStrength() * 0.5; }
    }
  }
  return d;
}

// After a fight: every squad that worked learns from it; a lost one costs heads, a rout costs more and the skill they
// had. The medics bring the wounded back.
public func CBSquadsDidJob(game: GameInstance, f: ref<CBWarFront>, won: Bool) -> Void {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || !IsDefined(f) {
    return;
  }
  let cutters = CBSquadKindOn(game, CBSquadCutters());
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) && s.heads > 0 {
      s.jobs += 1;
      if won {
        s.skill = MinF(100.0, s.skill + (CBSquadOrderWork(s.kind, f.order) ? 3.0 : 1.0));
        s.morale = MinF(100.0, s.morale + 4.0);
      } else {
        let lose = CBSquadOrderWork(s.kind, f.order) || s.kind == CBSquadGuns() ? 1 : 0;
        if CBSquadStanding(game, CBSquadCutters(), 1) || (cutters && RandF() < 0.5) {
          lose = 0;
        }
        s.heads = Max(0, s.heads - lose);
        s.lost += lose;
        s.morale = MaxF(0.0, s.morale - 6.0);
        // Veterans dead and recruits in their place.
        s.skill = MaxF(0.0, s.skill - Cast<Float>(lose) * 2.0);
      }
    }
  }
}

// New people for whichever squads have room, a few at a time (S2): defectors, prisoners who turn, a beaten gang's soldiers.
public func CBSquadsGainHeads(game: GameInstance, n: Int32) -> Void {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || n <= 0 {
    return;
  }
  let left = n;
  let pass = 0;
  while left > 0 && pass < 3 {
    let i = 0;
    while i < sb.Count() && left > 0 {
      let s = sb.At(i);
      i += 1;
      if IsDefined(s) && !s.noRecruit && s.heads < CBSquadMax(game, s) {
        s.heads += 1;
        left -= 1;
        sb.reportHeads += 1;
      }
    }
    pass += 1;
  }
}

// "Lookouts: on them. Hitters: after Kai Tanaka. Fighters: their corners." and what is missing, for the war screen.
public func CBSquadsPlanLine(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> String {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || sb.Count() == 0 || !IsDefined(f) {
    return "";
  }
  let out = "";
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) && s.heads > 0 {
      let job = CBSquadNightJob(s.kind, f.order);
      out += (StrLen(out) > 0 ? "\n" : "") + CBTf(n"Cyberbane-GangWar-SquadTonight", [CBSquadName(sys, game, s), job]);
    }
  }
  let missing = "";
  if !CBSquadKindOn(game, CBSquadEyes()) && CBGameSeconds(game) >= f.scoutUntil { missing += CBT(n"Cyberbane-GangWar-MissingEyes") + " "; }
  if !CBSquadKindOn(game, CBSquadWatch()) { missing += CBT(n"Cyberbane-GangWar-MissingWatch") + " "; }
  if !CBSquadKindOn(game, CBSquadCutters()) { missing += CBT(n"Cyberbane-GangWar-MissingCutters"); }
  return StrLen(missing) > 0 ? out + "\n" + missing : out;
}

func CBSquadNightJob(kind: Int32, order: Int32) -> String {
  if CBSquadOrderWork(kind, order) { return CBT(n"Cyberbane-GangWar-JobTheOrder"); }
  if kind == CBSquadEyes() { return CBT(n"Cyberbane-GangWar-JobEyes"); }
  if kind == CBSquadKnives() { return CBT(n"Cyberbane-GangWar-JobKnives"); }
  if kind == CBSquadRunners() { return CBT(n"Cyberbane-GangWar-JobRunners"); }
  if kind == CBSquadWatch() { return CBT(n"Cyberbane-GangWar-JobWatch"); }
  if kind == CBSquadCutters() { return CBT(n"Cyberbane-GangWar-JobCutters"); }
  return CBT(n"Cyberbane-GangWar-JobGuns");
}

// ---- Between wars (S8) -----------------------------------------------------------------------------------------------

// The three standing jobs a kind can be given.
public func CBSquadStandingWord(kind: Int32, choice: Int32) -> String {
  return CBT(StringToName("Cyberbane-GangWar-Standing" + IntToString(kind) + "-" + IntToString(Clamp(choice, 0, 2))));
}

public func CBSquadStanding(game: GameInstance, kind: Int32, choice: Int32) -> Bool {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) || !CBMyCrewOn() {
    return false;
  }
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    if IsDefined(s) && s.kind == kind && s.standing == choice && s.heads >= 2 {
      return true;
    }
    i += 1;
  }
  return false;
}

// What each squad's standing job does in a day, when no war needs it. Returns a line for the day's report, or "".
func CBSquadStandingDay(sys: ref<CyberbaneSystem>, game: GameInstance, s: ref<CBSquad>) -> String {
  if !IsDefined(s) || s.heads < 2 {
    return "";
  }
  let str = CBSquadStrength(game, s, true);
  let jb = CBCrewJobBook.Get(game);
  let held = CBCrewHeldDistricts(sys, game);
  if s.kind == CBSquadGuns() && s.standing == 0 {
    for d in held {
      CBCrewTurfRaise(sys, game, d, CBConfig.SquadGuardFoot());
    }
    return ArraySize(held) > 0 ? CBT(n"Cyberbane-GangWar-ReportGuarded") : "";
  }
  if s.kind == CBSquadEyes() && s.standing == 1 && RandF() < 0.3 {
    let content = sys.GetContent();
    for fs in sys.GetFactionStates() {
      if IsDefined(fs) && CBCrewStandingWith(game, fs.id) < 0 && IsDefined(content) {
        CBWarLooseTongue(sys, game, fs.id);
        return CBT(n"Cyberbane-GangWar-ReportLead");
      }
    }
  }
  if s.kind == CBSquadEyes() && s.standing == 2 {
    let book = CBCrewBook.Get(game);
    let i = 0;
    while IsDefined(book) && i < book.Count() {
      let m = book.At(i);
      i += 1;
      if IsDefined(m) && m.loyalty < 60 {
        m.loyalty += 1;
      }
    }
    return "";
  }
  if s.kind == CBSquadKnives() && s.standing == 0 && IsDefined(jb) {
    let pay = CBReward(RoundF(CBConfig.SquadContractPay() * str / 6.0));
    if RandF() < 0.35 && pay > 0 {
      jb.AddKitty(pay);
      return CBTf(n"Cyberbane-GangWar-ReportContract", [s"\(pay)"]);
    }
  }
  if s.kind == CBSquadKnives() && s.standing == 1 {
    let worst = CBMostHostileGang(sys, game);
    if IsNameValid(worst) {
      CBWeakenGang(sys, game, worst, CBConfig.SquadKnivesWeaken(), CBGangHomeDistrict(sys, game, worst));
      return CBTf(n"Cyberbane-GangWar-ReportKnives", [CBFactionLabel(worst)]);
    }
  }
  if s.kind == CBSquadRunners() && s.standing == 0 && IsDefined(jb) {
    let earned = CBReward(RoundF(CBConfig.SquadRunnerIncome() * str));
    jb.AddKitty(earned);
    return CBTf(n"Cyberbane-GangWar-ReportRunners", [s"\(earned)"]);
  }
  if s.kind == CBSquadRunners() && s.standing == 1 && IsDefined(jb) {
    let book2 = CBCrewBook.Get(game);
    if IsDefined(book2) && book2.CutOwed() > 0 && jb.Kitty() >= book2.CutOwed() {
      let paid = CBCrewPayCut(sys, game);
      return StrLen(paid) > 0 ? CBT(n"Cyberbane-GangWar-ReportCutPaid") : "";
    }
  }
  if s.kind == CBSquadWatch() && s.standing == 1 {
    for d2 in held {
      CBEsteemEarn(sys, d2, CBConfig.SquadWatchEsteem());
    }
    return "";
  }
  return "";
}

// Lookouts set to warn V (standing job 0) watch every street the crew holds, as a paid lookout watches one. True when
// they told V.
public func CBSquadEyesTipOff(sys: ref<CyberbaneSystem>, game: GameInstance, who: String) -> Bool {
  if !CBSquadStanding(game, CBSquadEyes(), 0) || !CBCrewHoldsHere(sys, game) {
    return false;
  }
  let coming = StrLen(who) > 0 ? who : CBT(n"Cyberbane-StreetPay-Trouble");
  CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-EyesWarn", [coming]), true, true);
  return true;
}

// Hitters set to answer hunters (standing job 2) catch one on the way now and then. True when they did.
public func CBSquadKnivesStopHunter(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !CBSquadStanding(game, CBSquadKnives(), 2) || RandF() >= CBConfig.SquadStopHunterChance() {
    return false;
  }
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBT(n"Cyberbane-GangWar-KnivesStoppedHunter"), true);
  }
  return true;
}

// The gang with the worst blood with V and the crew, for the hitters between wars.
func CBMostHostileGang(sys: ref<CyberbaneSystem>, game: GameInstance) -> CName {
  let worst = n"";
  let low = 0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) {
      let st = CBCrewStandingWith(game, fs.id);
      if st < low {
        low = st;
        worst = fs.id;
      }
    }
  }
  return worst;
}

// ---- Every day (S2, S7, S8) -----------------------------------------------------------------------------------------

public func CBSquadsDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let sb = CBSquadBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(sb) || !IsDefined(book) || !CBMyCrewOn() {
    return;
  }
  let now = CBGameSeconds(game);
  CBSquadsForm(sys, game, sb, book, now);
  ArrayClear(sb.reportWork);
  // Heads from the streets the crew holds: no turf, no army.
  let held = CBCrewHeldDistricts(sys, game);
  let feed = Cast<Float>(ArraySize(held)) * CBConfig.SquadHeadsPerDistrictWeek() / 7.0 * CBSquadTierMult(game);
  let i = 0;
  let broke: ref<CBSquad>;
  while i < sb.Count() {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) {
      let leader = book.Find(s.leader);
      // Holding under its own second; a squad nobody takes over breaks up.
      if !IsDefined(leader) && s.leaderlessUntil > 0.0 && now > s.leaderlessUntil && !IsDefined(broke) {
        broke = s;
      }
      // Recruits come by the leader's temper, and only as fast as the wages are paid for the money ones.
      if IsDefined(leader) && !s.noRecruit && s.heads < CBSquadMax(game, s) && sb.Count() > 0 {
        let t = CBCrewTemper(leader);
        let rate = feed / Cast<Float>(sb.Count());
        if t == CBTemperHothead() { rate *= 1.5; }
        if t == CBTemperCareful() { rate *= 0.6; }
        if t == CBTemperOldGang() && CBWarIsClient(game, leader.faction) { rate += 0.3; }
        if t == CBTemperMoney() && s.unpaidWeeks > 0 { rate = 0.0; }
        let whole = FloorF(rate);
        let add = whole + (RandF() < rate - Cast<Float>(whole) ? 1 : 0);
        add = Min(add, CBSquadMax(game, s) - s.heads);
        if add > 0 {
          s.heads += add;
          sb.reportHeads += add;
          // Raw recruits: a hothead's are rough, a careful one's are good.
          let quality = t == CBTemperCareful() ? 0.0 : (t == CBTemperHothead() ? -2.0 : -1.0);
          s.skill = ClampF(s.skill + quality * Cast<Float>(add), 0.0, 100.0);
        }
      }
      // Their own work, a little better every day it is done.
      s.skill = MinF(100.0, s.skill + CBConfig.SquadSkillPerDay());
      // Morale follows the leader's loyalty.
      if IsDefined(leader) {
        s.morale = ClampF(s.morale + (Cast<Float>(leader.loyalty) - s.morale) * 0.1, 0.0, 100.0);
      }
      // Between wars, the standing job.
      if !CBCrewAnyWar(game) {
        let line = CBSquadStandingDay(sys, game, s);
        if StrLen(line) > 0 {
          ArrayPush(sb.reportWork, CBSquadName(sys, game, s) + ": " + line);
        }
      }
    }
  }
  if IsDefined(broke) {
    CBSquadBreakUp(sys, game, sb, broke);
  }
  CBSquadsWages(sys, game, sb, now);
  CBSquadsReport(sys, game, sb);
}

// A squad for every leader who has none: Lieutenant and up, its kind by their own way of fighting.
// One new squad a day at most, from a Lieutenant or better who has none: of the kind they would pick, unless the crew
// has that kind already, then the first it is missing, so the squads cover the crew's needs before they double up. All
// five of a crew's Lieutenants formed theirs on one tick, three of them hustlers.
func CBSquadsForm(sys: ref<CyberbaneSystem>, game: GameInstance, sb: ref<CBSquadBook>, book: ref<CBCrewBook>, now: Float) -> Void {
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && CBSquadMaxHeads(CBCrewRankOf(game, m)) > 0 && !IsDefined(sb.Of(m.id)) {
      let s = new CBSquad();
      s.leader = m.id;
      s.kind = CBSquadKindFor(sb, CBSquadSuggest(m));
      s.heads = 2;   // a couple of their own people to start with
      s.skill = CBConfig.SquadSkillStart();
      s.morale = Cast<Float>(m.loyalty);
      s.formedAt = now;
      s.paidAt = now;
      sb.Add(s);
      if CBMessagesOn() {
        CBCrewText(sys, game, m, CBSquadFormedLine(s.kind));
      }
      CBLog.Info(n"Crew", s"Member \(m.id) started a squad (kind \(s.kind)).");
      return;
    }
  }
}

// The kind wanted, unless a squad of it is already out there: then the first the crew lacks, the fighting first.
func CBSquadKindFor(sb: ref<CBSquadBook>, wanted: Int32) -> Int32 {
  if !CBSquadKindTaken(sb, wanted) {
    return wanted;
  }
  let order = [CBSquadGuns(), CBSquadEyes(), CBSquadWatch(), CBSquadCutters(), CBSquadKnives(), CBSquadRunners()];
  for k in order {
    if !CBSquadKindTaken(sb, k) {
      return k;
    }
  }
  return wanted;
}

func CBSquadKindTaken(sb: ref<CBSquadBook>, kind: Int32) -> Bool {
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) && s.kind == kind {
      return true;
    }
  }
  return false;
}

// What a new squad's leader says, one whole line a kind.
public func CBSquadFormedLine(kind: Int32) -> String {
  if kind == CBSquadGuns() { return CBT(n"Cyberbane-GangWar-SquadFormedGuns"); }
  if kind == CBSquadEyes() { return CBT(n"Cyberbane-GangWar-SquadFormedEyes"); }
  if kind == CBSquadKnives() { return CBT(n"Cyberbane-GangWar-SquadFormedKnives"); }
  if kind == CBSquadRunners() { return CBT(n"Cyberbane-GangWar-SquadFormedRunners"); }
  if kind == CBSquadWatch() { return CBT(n"Cyberbane-GangWar-SquadFormedWatch"); }
  return CBT(n"Cyberbane-GangWar-SquadFormedCutters");
}

// Wages once a week from the kitty, by heads; the hustlers pay their own way. Unpaid, morale falls and heads walk.
func CBSquadsWages(sys: ref<CyberbaneSystem>, game: GameInstance, sb: ref<CBSquadBook>, now: Float) -> Void {
  let jb = CBCrewJobBook.Get(game);
  if !IsDefined(jb) {
    return;
  }
  let i = 0;
  while i < sb.Count() {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) && now - s.paidAt >= 7.0 * CBConfig.SecondsPerDay() {
      s.paidAt = now;
      let wage = CBSquadWage(s);
      if wage <= 0 || jb.Kitty() >= wage {
        if wage > 0 {
          jb.AddKitty(-wage);
        }
        s.unpaidWeeks = 0;
        s.morale = MinF(100.0, s.morale + 3.0);
      } else {
        s.unpaidWeeks += 1;
        s.morale = MaxF(0.0, s.morale - 15.0);
        let walk = Min(s.heads, 1 + s.unpaidWeeks);
        s.heads -= walk;
        ArrayPush(sb.reportWork, CBTf(n"Cyberbane-GangWar-ReportUnpaid", [CBSquadName(sys, game, s), s"\(walk)"]));
      }
    }
  }
}

public func CBSquadWage(s: ref<CBSquad>) -> Int32 {
  if !IsDefined(s) || s.kind == CBSquadRunners() {
    return 0;
  }
  return CBReward(CBConfig.SquadWagePerHead() * s.heads);
}

// What the squads cost a week, for the kitty's line and the upgrades.
public func CBSquadWagesWeek(game: GameInstance) -> Int32 {
  let sb = CBSquadBook.Get(game);
  if !IsDefined(sb) {
    return 0;
  }
  let w = 0;
  let i = 0;
  while i < sb.Count() {
    w += CBSquadWage(sb.At(i));
    i += 1;
  }
  return w;
}

// One report a day from the second, for every squad: five squads never mean five texts.
func CBSquadsReport(sys: ref<CyberbaneSystem>, game: GameInstance, sb: ref<CBSquadBook>) -> Void {
  if sb.Count() == 0 || !CBMessagesOn() || (sb.reportHeads == 0 && ArraySize(sb.reportWork) == 0) {
    sb.reportHeads = 0;
    return;
  }
  let line = sb.reportHeads > 0 ? CBTf(n"Cyberbane-GangWar-ReportHeads", [s"\(sb.reportHeads)"]) : "";
  for w in sb.reportWork {
    line += (StrLen(line) > 0 ? " " : "") + w + ".";
  }
  sb.reportHeads = 0;
  CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-Report", [line]), true);
}

// The leader gone (from CBCrewBook.Remove): it holds a few days under its own second; a leader who turned on the crew
// takes it with them.
public func CBSquadLeaderLeft(game: GameInstance, id: Int32, end: Int32) -> Void {
  let sb = CBSquadBook.Get(game);
  let s = IsDefined(sb) ? sb.Of(id) : null;
  if !IsDefined(s) {
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if end == CBCrewEndTurned() {
    sb.Drop(s);
    if CBMessagesOn() && IsDefined(sys) {
      CBCrewText(sys, game, null, CBTf(n"Cyberbane-GangWar-SquadTurned", [s"\(s.heads)"]), true);
    }
    return;
  }
  s.leaderlessUntil = CBGameSeconds(game) + CBConfig.SquadLeaderlessDays() * CBConfig.SecondsPerDay();
}

// Handed to another Lieutenant on the Hub.
public func CBSquadHandTo(game: GameInstance, s: ref<CBSquad>, id: Int32) -> Bool {
  let sb = CBSquadBook.Get(game);
  let book = CBCrewBook.Get(game);
  let m = IsDefined(book) ? book.Find(id) : null;
  if !IsDefined(sb) || !IsDefined(s) || !IsDefined(m) || IsDefined(sb.Of(id)) || CBSquadMaxHeads(CBCrewRankOf(game, m)) == 0 {
    return false;
  }
  s.leader = id;
  s.leaderlessUntil = 0.0;
  s.heads = Min(s.heads, CBSquadMaxHeads(CBCrewRankOf(game, m)));
  return true;
}

// Broken up: its heads go where there is room.
func CBSquadBreakUp(sys: ref<CyberbaneSystem>, game: GameInstance, sb: ref<CBSquadBook>, s: ref<CBSquad>) -> Void {
  let heads = s.heads;
  let name = CBSquadName(sys, game, s);
  sb.Drop(s);
  CBSquadsGainHeads(game, heads);
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-GangWar-SquadBrokeUp", [name]), true);
  }
}

// Changed while it is small, at the cost of the heads who leave over it (S3).
public func CBSquadChangeKind(game: GameInstance, s: ref<CBSquad>, kind: Int32) -> Bool {
  if !IsDefined(s) || s.kind == kind || s.heads > CBConfig.SquadChangeMaxHeads() {
    return false;
  }
  s.kind = kind;
  s.heads = s.heads / 2;
  s.skill = MaxF(0.0, s.skill * 0.5);
  return true;
}

func CBSquadTierMult(game: GameInstance) -> Float {
  return 1.0 + 0.25 * Cast<Float>(CBCrewTier(game));
}

public func CBCrewAnyWar(game: GameInstance) -> Bool {
  let fb = CBWarFrontBook.Get(game);
  return IsDefined(fb) && fb.Count() > 0;
}

// "4/8 heads, skill good, morale steady", for the squads screen.
public func CBSquadLine(sys: ref<CyberbaneSystem>, game: GameInstance, s: ref<CBSquad>) -> String {
  if !IsDefined(s) {
    return "";
  }
  return CBTf(n"Cyberbane-GangWar-SquadLine", [s"\(s.heads)", s"\(CBSquadMax(game, s))", CBSquadSkillWord(s.skill), CBSquadMoraleWord(s.morale)]);
}

public func CBSquadSkillWord(v: Float) -> String {
  if v >= 75.0 { return CBT(n"Cyberbane-GangWar-SkillSharp"); }
  if v >= 45.0 { return CBT(n"Cyberbane-GangWar-SkillGood"); }
  return CBT(n"Cyberbane-GangWar-SkillGreen");
}

public func CBSquadMoraleWord(v: Float) -> String {
  if v >= 70.0 { return CBT(n"Cyberbane-GangWar-MoraleHigh"); }
  if v >= 40.0 { return CBT(n"Cyberbane-GangWar-MoraleSteady"); }
  return CBT(n"Cyberbane-GangWar-MoraleLow");
}
