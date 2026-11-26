// Cyberbane - V's crew
//
// Recruiting (spared Rivals, frightened gangers, hired solos, members lent by a friendly gang), calling them, whose
// side they're on, loyalty and betrayal, the weekly cut and the crew page.

public func CBMyCrewOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().myCrew;
}

public func CBCrewComeOnOwnOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().myCrew && rt.GetSettings().crewComeOnOwn;
}

public func CBCrewBetrayalOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || (rt.GetSettings().myCrew && rt.GetSettings().crewBetrayal);
}

public func CBCrewFrightJoin() -> Float {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().crewFrightJoin : 0.5;
}

public func CBCrewCutMult() -> Float {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().crewCutMult : 1.0;
}

// How somebody came to V.
public func CBCrewOwed() -> Int32 = 0
public func CBCrewFrightened() -> Int32 = 1
public func CBCrewPaid() -> Int32 = 2
public func CBCrewLent() -> Int32 = 3

// How somebody left.
public func CBCrewEndFell() -> Int32 = 0
public func CBCrewEndLetGo() -> Int32 = 1
public func CBCrewEndWalked() -> Int32 = 2
public func CBCrewEndSold() -> Int32 = 3
public func CBCrewEndTurned() -> Int32 = 4

// What last cost a member loyalty, for what they say about it.
public func CBCrewWhyNone() -> Int32 = 0
public func CBCrewWhyUnpaid() -> Int32 = 1
public func CBCrewWhyLeftLying() -> Int32 = 2
public func CBCrewWhyLost() -> Int32 = 3
public func CBCrewWhyOldGang() -> Int32 = 4
public func CBCrewWhyFear() -> Int32 = 5
// Reasons for a gain, so a temperament can weigh it (Reactions/CrewLife.reds CBCrewTemperScale). Never stored as the
// last grievance.
public func CBCrewWhyWin() -> Int32 = 6
public func CBCrewWhyStayed() -> Int32 = 7
public func CBCrewWhyPaid() -> Int32 = 8
public func CBCrewWhyMourned() -> Int32 = 9
public func CBCrewWhyAsked() -> Int32 = 10

public func CBTalkActRecruit() -> Int32 = 58
public func CBTalkActLendOne() -> Int32 = 59

public func CBCrewSender() -> String = CBT(n"Cyberbane-Crew-MyCrew")

// ---- The book -----------------------------------------------------------------------------------------------------

public class CBCrewMember {
  public persistent let id: Int32;
  public persistent let kind: Int32;          // CBCrewOwed .. CBCrewLent
  public persistent let record: TweakDBID;
  public persistent let look: CName;          // appearance
  public persistent let faction: CName;       // the gang they came from; n"" for a solo of no gang
  public persistent let rival: Int32;         // the Rival they were, for the ones who owed V
  public persistent let seed: Int32;          // their name and nickname
  public persistent let loyalty: Int32;       // 0..100
  public persistent let wins: Int32;
  public persistent let scars: Int32;
  public persistent let seat: Int32;          // 0 heavy, 1 shooter, 2 blade, 3 netrunner (CBApexRoleForSeat)
  public persistent let home: CName;          // the district they live in
  public persistent let hurtUntil: Float;
  public persistent let calledAt: Float;
  public persistent let joinedAt: Float;
  public persistent let killsSeen: Int32;     // V's kills of their old gang when last counted
  public persistent let warnedDay: Int32;     // stored one up
  public persistent let lastWhy: Int32;
}

public class CBCrewPast {
  public persistent let id: Int32;
  public persistent let kind: Int32;
  public persistent let faction: CName;
  public persistent let rival: Int32;
  public persistent let seed: Int32;
  public persistent let end: Int32;           // CBCrewEndFell .. CBCrewEndTurned
  public persistent let at: Float;
  public persistent let by: Int32;            // the Rival who killed them, or the Betrayer they became
  public persistent let district: CName;
}

public class CBCrewBook extends ScriptableSystem {
  private persistent let m_members: array<ref<CBCrewMember>>;
  private persistent let m_past: array<ref<CBCrewPast>>;
  private persistent let m_nextId: Int32;
  private persistent let m_cutDueAt: Float;
  private persistent let m_cutOwed: Int32;
  private persistent let m_dayDone: Int32;    // the last game day the daily ran, stored one up
  private let m_checked: Bool;

  // Session only: who is out with V now, and the rest of a call.
  public let outBody: array<EntityID>;
  public let outMember: array<Int32>;
  public let outDown: array<Bool>;
  // Seen standing at least once this call, and the tick they were asked for: a member counts as having come, and their
  // wait between calls starts, only once the game has put them in the world.
  public let outSeen: array<Bool>;
  public let outTick: array<Int32>;
  // Called with nothing to fight: they walk with V until sent home, a car, or a place that holds them, and a fight on
  // the way does not send them home once it is over.
  public let escort: Bool;
  public let fought: Bool;
  // The fight this call is in (CBCrewBattleTick): one really happened with them there, whether the hunt's people were
  // in it, how many ticks it has been over, and whether this call has counted a win. Session only, like the rest.
  public let battle: Bool;
  public let battleHunt: Bool;
  public let overTicks: Int32;
  public let wonCall: Bool;
  // Whether the crew was really in it: enemies near them for a few seconds, a hit taken or landed by one of them, or an
  // enemy down while they stood there.
  public let engaged: Bool;
  public let engageTicks: Int32;
  public let enemyNear: Bool;
  public let battleDowned: Int32;   // enemies down near them this fight, for the line when it is won
  public let leaving: Bool;
  public let quiet: Int32;
  public let driving: Int32;
  public let turnMember: Int32;     // one set to turn in this fight
  public let turnTicks: Int32;
  public let turnedBody: EntityID;  // one who turned, still in the world
  public let turnedRival: Int32;
  public let turnedTicks: Int32;
  public let turnedFled: Bool;
  public let ambushAnswered: Bool;
  // A solo on offer by text (session: an offer does not outlive the evening).
  public let offerSeed: Int32;
  public let offerPrice: Int32;
  public let offerSender: String;
  public let offerHaggled: Bool;
  public let offerUntil: Float;
  // Asked for on the Hub, which is a paused menu: carried out on the first tick back in the game (CBCrewServiceHub),
  // the way every other Hub action is. Asked again before then, taken back.
  public let reqCall: Bool;
  public let reqHome: Bool;   // sent home from the Hub, the phone or the key
  public let reqPay: Bool;
  public let reqHire: Bool;
  public let reqLetGo: Int32;
  // One of them called on their own, or sent home on their own, from their orders on the Hub: a member's id.
  public let reqCallOne: Int32;
  public let reqHomeOne: Int32;

  public static func Get(game: GameInstance) -> ref<CBCrewBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBCrewBook") as CBCrewBook;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_checked = false;
    this.ResetSession();
  }

  public func ResetSession() -> Void {
    ArrayClear(this.outBody);
    ArrayClear(this.outMember);
    ArrayClear(this.outDown);
    ArrayClear(this.outSeen);
    ArrayClear(this.outTick);
    this.escort = false;
    this.fought = false;
    this.battle = false;
    this.battleHunt = false;
    this.overTicks = 0;
    this.wonCall = false;
    this.engaged = false;
    this.engageTicks = 0;
    this.enemyNear = false;
    this.battleDowned = 0;
    this.leaving = false;
    this.quiet = 0;
    this.driving = 0;
    this.turnMember = 0;
    this.turnTicks = 0;
    let none: EntityID;
    this.turnedBody = none;
    this.turnedRival = 0;
    this.turnedTicks = 0;
    this.turnedFled = false;
    this.ambushAnswered = false;
    this.offerSeed = 0;
    this.offerPrice = 0;
    this.offerSender = "";
    this.offerHaggled = false;
    this.offerUntil = 0.0;
    this.reqCall = false;
    this.reqHome = false;
    this.reqPay = false;
    this.reqHire = false;
    this.reqLetGo = 0;
    this.reqCallOne = 0;
    this.reqHomeOne = 0;
  }

  // Once a session: nobody missing, numbers in range, nobody twice.
  private func Check() -> Void {
    if this.m_checked {
      return;
    }
    this.m_checked = true;
    let i = ArraySize(this.m_members) - 1;
    while i >= 0 {
      let m = this.m_members[i];
      if !IsDefined(m) || m.id <= 0 {
        ArrayErase(this.m_members, i);
      } else {
        m.loyalty = Clamp(m.loyalty, 0, 100);
        m.seat = Clamp(m.seat, 0, 3);
        m.kind = Clamp(m.kind, 0, 3);
        if m.id >= this.m_nextId {
          this.m_nextId = m.id + 1;
        }
      }
      i -= 1;
    }
    i = ArraySize(this.m_past) - 1;
    while i >= 0 {
      if !IsDefined(this.m_past[i]) {
        ArrayErase(this.m_past, i);
      }
      i -= 1;
    }
  }

  public func Count() -> Int32 {
    this.Check();
    return ArraySize(this.m_members);
  }

  public func At(i: Int32) -> ref<CBCrewMember> {
    this.Check();
    return i >= 0 && i < ArraySize(this.m_members) ? this.m_members[i] : null;
  }

  public func Find(id: Int32) -> ref<CBCrewMember> {
    this.Check();
    for m in this.m_members {
      if IsDefined(m) && m.id == id {
        return m;
      }
    }
    return null;
  }

  public func FindRival(rivalId: Int32) -> ref<CBCrewMember> {
    this.Check();
    for m in this.m_members {
      if IsDefined(m) && rivalId > 0 && m.rival == rivalId {
        return m;
      }
    }
    return null;
  }

  // A Rival this book is made of: one on the crew now, or one who was and left it any way but turning.
  public func Keeps(rivalId: Int32) -> Bool {
    this.Check();
    if rivalId <= 0 {
      return false;
    }
    for m in this.m_members {
      if IsDefined(m) && m.rival == rivalId {
        return true;
      }
    }
    for p in this.m_past {
      if IsDefined(p) && p.rival == rivalId && p.end != CBCrewEndTurned() {
        return true;
      }
    }
    // Or one the memorial names, whose name is that Rival's record too.
    let bb = CBCrewBannerBook.Get(GetGameInstance());
    return IsDefined(bb) && bb.RemembersRival(rivalId);
  }

  public func HasRoom() -> Bool {
    return this.Count() < CBConfig.MyCrewRoster();
  }

  public func Add(kind: Int32, record: TweakDBID, look: CName, faction: CName, rival: Int32, loyalty: Int32,
                  home: CName, now: Float, killsSeen: Int32) -> ref<CBCrewMember> {
    this.Check();
    if !this.HasRoom() {
      return null;
    }
    if this.m_nextId <= 0 {
      this.m_nextId = 1;
    }
    let m = new CBCrewMember();
    m.id = this.m_nextId;
    this.m_nextId += 1;
    m.kind = kind;
    m.record = record;
    m.look = look;
    m.faction = faction;
    m.rival = rival;
    m.seed = RandRange(1, 1000000);
    m.loyalty = Clamp(loyalty, 0, 100);
    m.seat = CBCrewSeatOf(record, m.seed);
    m.home = home;
    m.joinedAt = now;
    m.killsSeen = killsSeen;
    ArrayPush(this.m_members, m);
    return m;
  }

  // Off the roster, and into the past: fallen, let go, walked, sold V out, or turned.
  public func Remove(m: ref<CBCrewMember>, end: Int32, by: Int32, district: CName, now: Float) -> Void {
    this.Check();
    if !IsDefined(m) {
      return;
    }
    let p = new CBCrewPast();
    p.id = m.id;
    p.kind = m.kind;
    p.faction = m.faction;
    p.rival = m.rival;
    p.seed = m.seed;
    p.end = end;
    p.at = now;
    p.by = by;
    p.district = district;
    ArrayPush(this.m_past, p);
    while ArraySize(this.m_past) > CBConfig.MyCrewPastKept() {
      ArrayErase(this.m_past, 0);
    }
    let game = GetGameInstance();
    // Their story ends here (Reactions/CrewLife.reds): one who fell is buried by the rest a day later; anybody else's
    // story, asks and days off are forgotten. Asked while they are still on the roster, so the count is right.
    if end == CBCrewEndFell() {
      CBCrewLifeFell(CyberbaneSystem.Get(game), game, m, district);
    } else {
      let lbGone = CBCrewLifeBook.Get(game);
      if IsDefined(lbGone) {
        lbGone.Forget(m.id);
      }
    }
    ArrayRemove(this.m_members, m);
    if end == CBCrewEndFell() {
      CBCrewRememberFallen(game, m, by, district, now);   // the memorial, with what they carried
    }
    CBCrewBannerLeaves(game, m.id);   // no longer recruiting
    CBCrewKitLeaves(game, m.id);      // their weapon back to V, their kit forgotten
  }

  public func PastCount() -> Int32 {
    this.Check();
    return ArraySize(this.m_past);
  }

  public func PastAt(i: Int32) -> ref<CBCrewPast> {
    this.Check();
    return i >= 0 && i < ArraySize(this.m_past) ? this.m_past[i] : null;
  }

  public func FindPast(id: Int32) -> ref<CBCrewPast> {
    this.Check();
    for p in this.m_past {
      if IsDefined(p) && p.id == id {
        return p;
      }
    }
    return null;
  }

  // The one a Rival killed, still unanswered, for V to answer.
  public func PastKilledBy(rivalId: Int32) -> ref<CBCrewPast> {
    this.Check();
    let i = ArraySize(this.m_past) - 1;
    while i >= 0 {
      let p = this.m_past[i];
      if IsDefined(p) && rivalId > 0 && p.by == rivalId && p.end == CBCrewEndFell() {
        return p;
      }
      i -= 1;
    }
    return null;
  }

  public func CutOwed() -> Int32 { return this.m_cutOwed; }
  public func SetCutOwed(n: Int32) -> Void { this.m_cutOwed = Max(0, n); }
  public func CutDueAt() -> Float { return this.m_cutDueAt; }
  public func SetCutDueAt(t: Float) -> Void { this.m_cutDueAt = t; }
  public func DayDone() -> Int32 { return this.m_dayDone; }
  public func SetDayDone(d: Int32) -> Void { this.m_dayDone = d; }

  public func AllLoyalty(delta: Int32, why: Int32) -> Void {
    this.Check();
    for m in this.m_members {
      if IsDefined(m) {
        CBCrewLoyalty(m, delta, why);
      }
    }
  }

  // ---- Who is out now (session) ----

  public func AddOut(body: EntityID, member: Int32, tick: Int32) -> Void {
    ArrayPush(this.outBody, body);
    ArrayPush(this.outMember, member);
    ArrayPush(this.outDown, false);
    ArrayPush(this.outSeen, false);
    ArrayPush(this.outTick, tick);
  }

  public func OutCount() -> Int32 {
    return Min(Min(Min(ArraySize(this.outBody), ArraySize(this.outMember)), Min(ArraySize(this.outDown), ArraySize(this.outSeen))),
               ArraySize(this.outTick));
  }

  public func DropOut(i: Int32) -> Void {
    if i < 0 || i >= this.OutCount() {
      return;
    }
    ArrayErase(this.outBody, i);
    ArrayErase(this.outMember, i);
    ArrayErase(this.outDown, i);
    ArrayErase(this.outSeen, i);
    ArrayErase(this.outTick, i);
  }

  public func OutIndexOf(body: EntityID) -> Int32 {
    let i = 0;
    while i < this.OutCount() {
      if Equals(this.outBody[i], body) {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func OutIndexOfMember(id: Int32) -> Int32 {
    let i = 0;
    while i < this.OutCount() {
      if this.outMember[i] == id {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func IsOut(id: Int32) -> Bool {
    return this.OutIndexOfMember(id) >= 0;
  }

  public func MemberOfBody(body: EntityID) -> ref<CBCrewMember> {
    let i = this.OutIndexOf(body);
    return i >= 0 ? this.Find(this.outMember[i]) : null;
  }

  // Start over (Core/CyberbaneSystem.reds, HardReset).
  public func Clear() -> Void {
    ArrayClear(this.m_members);
    ArrayClear(this.m_past);
    this.m_nextId = 1;
    this.m_cutDueAt = 0.0;
    this.m_cutOwed = 0;
    this.m_dayDone = 0;
    this.ResetSession();
  }
}

// Start over (Core/CyberbaneSystem.reds, HardReset), before anything of ours is taken out of the world: everybody out
// on a call stops following V, so one kept in a car seat until they are out of it does not follow V into the new
// playthrough.
public func CBCrewStandDown(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) {
    return;
  }
  let i = 0;
  while i < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      CBEndFollower(p);
    }
    i += 1;
  }
}

// ---- Who they are -------------------------------------------------------------------------------------------------

public func CBCrewLoyalty(m: ref<CBCrewMember>, delta: Int32, why: Int32) -> Void {
  if !IsDefined(m) {
    return;
  }
  // Who they are decides how much it moves them: a hothead loves a win, the one in it for the money counts eddies.
  let moved = CBCrewTemperScale(m, delta, why);
  m.loyalty = Clamp(m.loyalty + moved, 0, 100);
  if moved < 0 && why != CBCrewWhyNone() && why < CBCrewWhyWin() {
    m.lastWhy = why;
  }
}

public func CBCrewRank(wins: Int32) -> Int32 {
  if wins >= CBCrewPaceWins(12) { return 4; }
  if wins >= CBCrewPaceWins(7) { return 3; }
  if wins >= CBCrewPaceWins(3) { return 2; }
  return 1;
}

// How hard the crew's life is (Mod Settings "How hard your crew has it").
public func CBCrewPace() -> ECBCrewPace {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().crewPace : ECBCrewPace.Standard;
}

// The wins a rank takes, by the pace: fewer on Easy, more on Hard.
public func CBCrewPaceWins(wins: Int32) -> Int32 {
  let pace = CBCrewPace();
  if Equals(pace, ECBCrewPace.Easy) { return Max(1, RoundF(Cast<Float>(wins) * 0.6)); }
  if Equals(pace, ECBCrewPace.Hard) { return RoundF(Cast<Float>(wins) * 1.5); }
  return wins;
}

// A gang's weight in a war, by the pace.
public func CBCrewPaceWarFactor() -> Float {
  let pace = CBCrewPace();
  if Equals(pace, ECBCrewPace.Easy) { return 0.85; }
  if Equals(pace, ECBCrewPace.Hard) { return 1.2; }
  return 1.0;
}

// The seat their record fills, read off its archetype the way an apex squad's chairs are; a record the game files
// under no role takes one by its seed.
func CBCrewSeatOf(record: TweakDBID, seed: Int32) -> Int32 {
  let role: ECBApexRole;
  if CBArchetypeRole(CBRecordArchetype(record), role) {
    if Equals(role, ECBApexRole.Tank) { return 0; }
    if Equals(role, ECBApexRole.Assault) { return 1; }
    if Equals(role, ECBApexRole.Blade) { return 2; }
    return 3;
  }
  return CBHashIndex(seed, 5, 2);   // a shooter or a heavy
}

public func CBCrewSeatWord(seat: Int32) -> String {
  if seat == 0 { return CBT(n"Cyberbane-Crew-Heavy"); }
  if seat == 2 { return CBT(n"Cyberbane-Crew-Blade"); }
  if seat == 3 { return CBT(n"Cyberbane-StreetRead-Netrunner"); }
  return CBT(n"Cyberbane-Crew-Shooter");
}

// The nickname they earn at rank 3, from what they do.
public func CBCrewNickname(seat: Int32, seed: Int32) -> String {
  if seat == 0 {
    let a = [CBT(n"Cyberbane-Crew-Wall"), CBT(n"Cyberbane-Crew-Anvil"), CBT(n"Cyberbane-Crew-Brick"), CBT(n"Cyberbane-Crew-Bulldozer"), CBT(n"Cyberbane-Crew-Mountain")];
    return a[CBHashIndex(seed, 61, ArraySize(a))];
  }
  if seat == 2 {
    let b = [CBT(n"Cyberbane-Crew-Knives"), CBT(n"Cyberbane-Crew-Edge"), CBT(n"Cyberbane-Crew-Whisper"), CBT(n"Cyberbane-Crew-PaperCut"), CBT(n"Cyberbane-Crew-Ribbons")];
    return b[CBHashIndex(seed, 61, ArraySize(b))];
  }
  if seat == 3 {
    let c = [CBT(n"Cyberbane-Crew-Ghost"), CBT(n"Cyberbane-Crew-Static"), CBT(n"Cyberbane-Crew-Daemon"), CBT(n"Cyberbane-Crew-Wire"), CBT(n"Cyberbane-Crew-Blackout")];
    return c[CBHashIndex(seed, 61, ArraySize(c))];
  }
  let d = [CBT(n"Cyberbane-Traits-Deadeye"), CBT(n"Cyberbane-Crew-Trigger"), CBT(n"Cyberbane-Crew-Ricochet"), CBT(n"Cyberbane-Crew-TapTap"), CBT(n"Cyberbane-Crew-Longshot")];
  return d[CBHashIndex(seed, 61, ArraySize(d))];
}

// Their first name: what they are called in a text.
public func CBCrewFirstName(sys: ref<CyberbaneSystem>, kind: Int32, faction: CName, rival: Int32, seed: Int32) -> String {
  if rival > 0 && IsDefined(sys) {
    let r = sys.FindRivalById(rival);
    if IsDefined(r) {
      let full = CBRivalDisplayName(sys.GetContent(), r);
      let space = StrFindFirst(full, " ");
      return space > 0 ? StrLeft(full, space) : full;
    }
  }
  let content = IsDefined(sys) ? sys.GetContent() : null;
  let pool = IsDefined(content) && NotEquals(faction, n"") ? content.GetFactionNames(faction) : null;
  if IsDefined(pool) && ArraySize(pool.firstNames) > 0 {
    return pool.firstNames[CBHashIndex(seed, 41, ArraySize(pool.firstNames))];
  }
  let solo = ["Rook", "Nadia", "Casimir", "June", "Teo", "Halima", "Brix", "Odette", "Mateo", "Sunny", "Ivo", "Reva"];
  return solo[CBHashIndex(seed, 41, ArraySize(solo))];
}

// The whole name, with the nickname once they have earned it: rank 3 from fights won alone, for anybody with no kit to
// count (a solo on offer, somebody who left).
public func CBCrewFullName(sys: ref<CyberbaneSystem>, kind: Int32, faction: CName, rival: Int32, seed: Int32, wins: Int32,
                           seat: Int32) -> String {
  return CBCrewFullNameNicked(sys, kind, faction, rival, seed, CBCrewRank(wins) >= 3, seat);
}

public func CBCrewFullNameNicked(sys: ref<CyberbaneSystem>, kind: Int32, faction: CName, rival: Int32, seed: Int32,
                                 nicked: Bool, seat: Int32) -> String {
  if rival > 0 && IsDefined(sys) {
    let r = sys.FindRivalById(rival);
    if IsDefined(r) {
      return CBRivalDisplayName(sys.GetContent(), r);
    }
  }
  let first = CBCrewFirstName(sys, kind, faction, rival, seed);
  let last = "";
  let content = IsDefined(sys) ? sys.GetContent() : null;
  let pool = IsDefined(content) && NotEquals(faction, n"") ? content.GetFactionNames(faction) : null;
  if IsDefined(pool) && ArraySize(pool.lastNames) > 0 {
    last = pool.lastNames[CBHashIndex(seed, 43, ArraySize(pool.lastNames))];
  } else {
    let solo = ["Vance", "Okafor", "Reyes", "Lindgren", "Abara", "Castillo", "Moretti", "Sato", "Kowal", "Duarte"];
    last = solo[CBHashIndex(seed, 43, ArraySize(solo))];
  }
  let nick = nicked ? " \"" + CBCrewNickname(seat, seed) + "\"" : "";
  return StrLen(last) > 0 ? first + nick + " " + last : first + nick;
}

// A member's name, nicknamed from Veteran up: their rank as the card shows it, fights and training together
// (Reactions/CrewKit.reds, CBCrewRankOf). It counted fights alone, so a member trained to Veteran had no nickname.
public func CBCrewName(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return CBT(n"Cyberbane-Telling-Somebody");
  }
  // The name V gave them (Reactions/CrewNames.reds), with the nickname they have earned.
  let given = CBCrewGivenNameOf(m.id);
  if StrLen(given) > 0 {
    return CBCrewRankOf(GetGameInstance(), m) >= 3 ? given + " \"" + CBCrewNickname(m.seat, m.seed) + "\"" : given;
  }
  return CBCrewFullNameNicked(sys, m.kind, m.faction, m.rival, m.seed, CBCrewRankOf(GetGameInstance(), m) >= 3, m.seat);
}

// The name they go by, short enough for a box on the crew picture: first name and nickname once they have one.
public func CBCrewBoxName(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let given = CBCrewGivenNameOf(m.id);
  if (m.rival > 0 && StrLen(given) == 0) || CBCrewRankOf(GetGameInstance(), m) < 3 {
    return CBCrewName(sys, m);
  }
  return CBCrewFirst(sys, m) + " \"" + CBCrewNickname(m.seat, m.seed) + "\"";
}

public func CBCrewFirst(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return CBT(n"Cyberbane-Telling-Somebody");
  }
  let given = CBCrewGivenNameOf(m.id);
  return StrLen(given) > 0 ? CBFirstWord(given) : CBCrewFirstName(sys, m.kind, m.faction, m.rival, m.seed);
}

public func CBCrewPastName(sys: ref<CyberbaneSystem>, p: ref<CBCrewPast>) -> String {
  if !IsDefined(p) {
    return CBT(n"Cyberbane-Telling-Somebody");
  }
  let given = CBCrewGivenNameOf(p.id);   // the name V knew them by, on the memorial too
  return StrLen(given) > 0 ? given : CBCrewFullName(sys, p.kind, p.faction, p.rival, p.seed, 0, 0);
}

// Where they came from, as a clause: "a shooter, once of the Valentinos, who owes you a life".
public func CBCrewFromWords(m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let gang = NotEquals(m.faction, n"") ? CBFactionLabel(m.faction) : "";
  if m.kind == CBCrewOwed() { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-OnceOfWhoOwesYouA", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-WhoOwesYouALife"); }
  if m.kind == CBCrewFrightened() { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-OnceOfScaredIntoWorkingFor", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-ScaredIntoWorkingForYou"); }
  if m.kind == CBCrewLent() { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-OnLoanFrom", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-OnLoan"); }
  return CBT(n"Cyberbane-Crew-ASoloPaidByTheWeek");
}

// The same, short enough for a row or a box.
public func CBCrewFromShort(m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let gang = NotEquals(m.faction, n"") ? CBPhoneGangSender(m.faction) : "";
  // A life, as the long form says: "owes you" alone reads as money.
  if m.kind == CBCrewOwed() { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-OwesYouALifeEx", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-OwesYouALife"); }
  if m.kind == CBCrewFrightened() { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-ScaredEx", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-ScaredIntoIt"); }
  if m.kind == CBCrewLent() { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Crew-OnLoan-2", [s"\(gang)"]) : CBT(n"Cyberbane-Crew-OnLoan"); }
  return CBT(n"Cyberbane-Crew-PaidSolo");
}

public func CBCrewRestless(m: ref<CBCrewMember>) -> Bool {
  return IsDefined(m) && m.loyalty < CBConfig.MyCrewRestless();
}

public func CBCrewHurt(m: ref<CBCrewMember>, now: Float) -> Bool {
  return IsDefined(m) && m.hurtUntil > now;
}

public func CBCrewReady(book: ref<CBCrewBook>, m: ref<CBCrewMember>, now: Float) -> Bool {
  return IsDefined(m) && !CBCrewHurt(m, now) && !book.IsOut(m.id) && !CBCrewAway(GetGameInstance(), m.id, now)
      && !CBCrewSparring(GetGameInstance(), m.id) && !CBGuardPosted(GetGameInstance(), m.id)
      && !CBCrewLoitering(GetGameInstance(), m.id)   // on a corner until they have gone: never two of the same person
      && (m.calledAt <= 0.0 || now - m.calledAt >= CBConfig.MyCrewCallSeconds());
}

// The roster, most loyal first, of the ones who can come now (and at least `minLoyalty` loyal).
func CBCrewReadyOrder(book: ref<CBCrewBook>, now: Float, minLoyalty: Int32) -> array<ref<CBCrewMember>> {
  let out: array<ref<CBCrewMember>>;
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if CBCrewReady(book, m, now) && m.loyalty >= minLoyalty {
      let k = 0;
      while k < ArraySize(out) && out[k].loyalty >= m.loyalty {
        k += 1;
      }
      ArrayInsert(out, k, m);
    }
  }
  return out;
}

// The crew on the phone (Reactions/CrewNames.reds). One of them about themselves: their own thread, under the name V
// knows them by.
public func CBCrewText(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, line: String, opt group: Bool, opt urgent: Bool) -> Void {
  if StrLen(line) == 0 {
    return;
  }
  // Answering a call, or warning V of something on V right now: it lands at once, not after the gossip.
  if urgent {
    let kbU = CBCrewKitBook.Get(game);
    if !(IsDefined(kbU) && kbU.deferTexts) {
      let senderU = IsDefined(m) && !group ? CBCrewThreadName(sys, m) : CBCrewGroupSender(game);
      CBPhonePost(game, senderU, IsDefined(m) && group ? CBCrewFirst(sys, m) + ": " + line : line, CBCrewColour(game), true, 0, n"", 0, 0);
      return;
    }
  }
  // An order carried out while the Hub is still open (CBCrewKitDoNow): the text waits for the game, as everything the
  // world says does, and goes on the next tick (CBCrewKitService).
  let kb = CBCrewKitBook.Get(game);
  if IsDefined(kb) && kb.deferTexts {
    ArrayPush(kb.laterWho, IsDefined(m) ? m.id : 0);
    ArrayPush(kb.laterLines, line);
    ArrayPush(kb.laterGroup, group);
    return;
  }
  if IsDefined(m) && !group {
    CBPhoneSendTinted(game, CBCrewThreadName(sys, m), line, CBCrewColour(game));
    return;
  }
  CBPhoneSendTinted(game, CBCrewGroupSender(game), IsDefined(m) ? CBCrewFirst(sys, m) + ": " + line : line, CBCrewColour(game));
}

// ---- Joining ([C1]-[C4]) --------------------------------------------------------------------------------------------

func CBCrewKillsOf(sys: ref<CyberbaneSystem>, faction: CName) -> Int32 {
  let fs = NotEquals(faction, n"") ? sys.FindFaction(faction) : null;
  return IsDefined(fs) ? fs.kills : 0;
}

func CBCrewJoined(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, line: String) -> Void {
  if !IsDefined(m) {
    return;
  }
  let now = CBGameSeconds(game);
  let book = CBCrewBook.Get(game);
  // The first one sets the week the cut is counted from.
  if IsDefined(book) && book.CutDueAt() <= 0.0 {
    book.SetCutDueAt(now + 7.0 * CBConfig.SecondsPerDay());
  }
  sys.AddRenownPoints(CBConfig.MyCrewRenown());   // people working for V is a name of its own
  // The gang they came from thinks better or worse of the crew for it (Reactions/CrewBanner.reds): one lent is trust,
  // one scared into it or a Rival of theirs who owes V is one of theirs taken.
  if m.kind == CBCrewLent() { CBCrewStandingShift(game, m.faction, CBConfig.CrewStandLent()); }
  if m.kind == CBCrewFrightened() { CBCrewStandingShift(game, m.faction, -CBConfig.CrewStandFrightened()); }
  if m.kind == CBCrewOwed() { CBCrewStandingShift(game, m.faction, -CBConfig.CrewStandOwed()); }
  CBFileLog(sys, n"CrewJoined", now, CBEventDistrict(sys, game), m.faction, Cast<Float>(m.id));
  CBCrewLifeNote(game, m.id, CBLifeJoined(), CBEventDistrict(sys, game), 0);   // the first line of their story
  CBCrewText(sys, game, m, line);
  CBLog.Info(n"Crew", s"Somebody joined V's crew (kind \(m.kind), loyalty \(m.loyalty)).");
}

// [C1] Where they lie: shown for a Rival V has spared before, while there is room.
public func CBCrewRecruitLine(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> ref<CBTalkLine> {
  let book = CBCrewBook.Get(game);
  if !CBMyCrewOn() || !IsDefined(book) || !IsDefined(r) || !book.HasRoom() || r.sparedByV < 1
     || CBRivalHasTrait(r, n"Broken") {
    return null;
  }
  let l = CBTalkMakeLine(CBT(n"Cyberbane-Crew-RecruitYouOweMeWorkFor"), CBTalkActRecruit(), t"ChoiceCaptionParts.HandshakeIcon");
  l.important = true;
  return l;
}

// Whether they say yes, from who they are.
func CBCrewRivalAccepts(r: ref<CBRival>) -> Bool {
  let chance = CBConfig.MyCrewRecruitBase();
  if CBRivalHasTrait(r, n"HardToScare") { chance -= 0.25; }
  if CBRivalHasTrait(r, n"GrudgeBearer") { chance -= 0.35; }
  if CBRivalHasTrait(r, n"Humiliated") { chance -= 0.2; }
  if CBRivalHasTrait(r, n"Shaken") { chance += 0.1; }
  chance += 0.05 * Cast<Float>(r.sparedByV - 1);
  return RandF() < ClampF(chance, 0.05, 0.95);
}

// The answer where they lie: yes is settled when the mercy is (Reactions/CombatFlee.reds, CBHandleSpared).
public func CBCrewRecruitAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, e: ref<CBEscapee>) -> ref<CBTalkAnswer> {
  let you = CBYou(sys, game);
  if !CBCrewRivalAccepts(r) {
    return CBTalkSay(CBLineOf([CBTf(n"Cyberbane-Crew-WorkForYouIDRather", [s"\(you)"]),
                               CBT(n"Cyberbane-Crew-YouLetMeLiveThatDoesn"),
                               CBTf(n"Cyberbane-Crew-TwiceYouHadMeTwiceAnd", [s"\(you)"])]), n"");
  }
  e.recruited = true;
  return CBTalkSay(CBLineOf([CBTf(n"Cyberbane-Crew-YeahYeahIOweYouTwice", [s"\(you)"]),
                             CBT(n"Cyberbane-Crew-GuessMyOldCrewCanFind"),
                             CBTf(n"Cyberbane-Crew-YouCouldVeEndedMeIn", [s"\(CBHere(sys))"])]), n"");
}

// A Rival who joins V's crew leaves the board: out of their chair, their ending "retired", no longer an informant, and
// Retired, the state every Rival system already leaves alone (the hunt, Rival life and its chrome, whereabouts,
// strongholds, the tree's living rows).
public func CBCrewRivalOffBoard(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(r) {
    return;
  }
  r.state = EnumInt(ECBRivalState.Retired);
  CBHierarchyFill(sys, r.faction);
  let rb = CBRivalBook.Get(game);
  if IsDefined(rb) {
    rb.SetEnding(r.id, CBEndingRetired(), CBGameSeconds(game));
  }
  let intel = CBIntelBook.Get(game);
  if IsDefined(intel) {
    let k = intel.InformantCount() - 1;
    while k >= 0 {
      if intel.InformantRival(k) == r.id {
        intel.RemoveInformant(k);   // working for V now, not texting tips from the outside
      }
      k -= 1;
    }
  }
}

// Saves from before: every Rival on the crew off the board, once they are seen still on it. From the slow tick.
public func CBCrewRivalsOffBoard(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) {
    return;
  }
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && m.rival > 0 {
      let r = sys.FindRivalById(m.rival);
      if IsDefined(r) && r.state != EnumInt(ECBRivalState.Retired) && r.state != EnumInt(ECBRivalState.Slain) {
        CBCrewRivalOffBoard(sys, game, r);
        CBLog.Info(n"Crew", "A Rival on V's crew taken off the board.");
      }
    }
  }
}

// Is this Rival one of V's crew now?
public func CBRivalRunsWithV(game: GameInstance, r: ref<CBRival>) -> Bool {
  let book = CBCrewBook.Get(game);
  return IsDefined(book) && IsDefined(r) && IsDefined(book.FindRival(r.id));
}

// From the mercy path, once they are let go: the Rival leaves the board and joins the roster.
public func CBCrewTakeRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, e: ref<CBEscapee>) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !book.HasRoom() || IsDefined(book.FindRival(r.id)) {
    return;
  }
  let now = CBGameSeconds(game);
  CBCloseRivalEncounter(sys, game, r, IsDefined(e) ? e.puppet : null);
  CBCrewRivalOffBoard(sys, game, r);
  let m = book.Add(CBCrewOwed(), r.recordID, r.appearance, r.faction, r.id, CBConfig.MyCrewLoyaltyOwed(),
                   CBEventDistrict(sys, game), now, CBCrewKillsOf(sys, r.faction));
  CBCrewJoined(sys, game, m, CBLineOf([CBT(n"Cyberbane-Crew-ItSMeSavedYourNumber"),
                                      CBT(n"Cyberbane-Crew-ToldMyOldCrewIM"),
                                      CBT(n"Cyberbane-Crew-PatchedUpArmedBoredSayThe")]));
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-Crew-WalkedOutOnAndRunsWith", [s"\(CBRivalDisplayName(sys.GetContent(), r))", s"\(CBFactionLabel(r.faction))"]), n"");
  }
}

// A Debtor's own thread: the same question, by text.
public func CBCrewRecruitDebtor(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !book.HasRoom() || IsDefined(book.FindRival(r.id)) {
    return CBT(n"Cyberbane-Crew-CanTNotNow");
  }
  if !CBCrewRivalAccepts(r) {
    return CBLineOf([CBT(n"Cyberbane-Crew-IOweYouTipsNotMy"), CBT(n"Cyberbane-Crew-IMOutOfThatLife")]);
  }
  let now = CBGameSeconds(game);
  let m = book.Add(CBCrewOwed(), r.recordID, r.appearance, r.faction, r.id, CBConfig.MyCrewLoyaltyOwed(),
                   NotEquals(r.origin, n"") ? r.origin : CBEventDistrict(sys, game), now, CBCrewKillsOf(sys, r.faction));
  if !IsDefined(m) {
    return CBT(n"Cyberbane-Crew-CanTNotNow");
  }
  CBCrewRivalOffBoard(sys, game, r);
  CBFileLog(sys, n"CrewJoined", now, CBEventDistrict(sys, game), m.faction, Cast<Float>(m.id));
  CBCrewLifeNote(game, m.id, CBLifeJoined(), CBEventDistrict(sys, game), 0);   // the first line of their story, as in person
  sys.AddRenownPoints(CBConfig.MyCrewRenown());
  // A Rival of theirs taken, as on the street (CBCrewJoined): the reply is this thread's text, so that is all it skips.
  CBCrewStandingShift(game, m.faction, -CBConfig.CrewStandOwed());
  if book.CutDueAt() <= 0.0 {
    book.SetCutDueAt(now + 7.0 * CBConfig.SecondsPerDay());
  }
  CBLog.Info(n"Crew", s"Somebody joined V's crew by text (kind \(m.kind), loyalty \(m.loyalty)).");
  return CBLineOf([CBT(n"Cyberbane-Crew-FunnyIWasGoingToAsk"), CBT(n"Cyberbane-Crew-PayingADebtWithMyTrigger")]);
}

// [C2] From the turn (Reactions/StreetIntel.reds, CBIntelTurn): somebody frightened enough joins instead. Frightened:
// afraid of V when V walked up, or leaned on until they folded (cbHoldState 1, a successful Intimidate).
public func CBCrewFrightenedJoins(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let book = CBCrewBook.Get(game);
  if !CBCrewTakesFrightened(game) || !IsDefined(t) || !IsDefined(t.npc) || Equals(t.faction, n"") || t.cop
     || !(t.mood == CBTalkAfraid() || t.npc.cbHoldState == 1) {
    return null;
  }
  // Somebody already afraid of V, leaned on until they fold, always says yes: a roll of 30 to 60% on top of the
  // Intimidate that worked left most of them informing instead. One who only folded is asked with the setting.
  if t.mood != CBTalkAfraid() {
    let chance = CBCrewFrightJoin() * (1.0 + ClampF(CBTalkNerveGap(t), 0.0, 1.0));
    if RandF() >= chance {
      return null;
    }
  }
  let now = CBGameSeconds(game);
  // Their own body when it is one that can be sent into a fight; a passer-by of the crowd, or one the game marks as
  // unfit, comes as one of their gang's own fighters instead (Data/ApexRoster.reds), so the crew member who answers
  // a call can fight.
  let record = t.npc.GetRecordID();
  let look = t.npc.GetCurrentAppearanceName();
  if t.npc.IsCrowd() || !CBHunterRecordFit(record) {
    record = CBApexRosterRecord(t.faction, RandRange(0, 4));
    look = n"";
  }
  if !CBHunterRecordFit(record) {
    return null;
  }
  let m = book.Add(CBCrewFrightened(), record, look, t.faction, 0,
                   CBConfig.MyCrewLoyaltyFrightened(), CBEventDistrict(sys, game), now, CBCrewKillsOf(sys, t.faction));
  if !IsDefined(m) {
    return null;
  }
  // One of V's crew now: they stand down here and now, by the game's rules as well as Cyberbane's.
  CBStandDownFromV(game, t.npc);
  CBCrewJoined(sys, game, m, CBTf(n"Cyberbane-Crew-ItSMeFromIDon", [s"\(CBHere(sys))"]));
  CBLog.Info(n"Crew", s"A frightened ganger of \(NameToString(t.faction)) joined V's crew.");
  return CBTalkSay(CBLineOf([CBTf(n"Cyberbane-Crew-OkayOkayIMYoursJust", [s"\(CBYou(sys, game))"]),
                             CBTf(n"Cyberbane-Crew-WorkForYouBetterThanThe", [s"\(CBCapFirst(CBFactionLabel(t.faction)))"]),
                             CBT(n"Cyberbane-Crew-WhateverYouSayILlKeep")]), n"");
}

// The crew is on and has room for one more: asked before a frightened ganger is offered the chance.
public func CBCrewTakesFrightened(game: GameInstance) -> Bool {
  let book = CBCrewBook.Get(game);
  return CBMyCrewOn() && IsDefined(book) && book.HasRoom() && CBCrewFrightJoin() > 0.0;
}

// [C4] An Allied gang lends one of its people, for good.
public func CBCrewLendLine(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkLine> {
  let book = CBCrewBook.Get(game);
  let score = sys.GetScore();
  // Friendly or Allied: Allied alone was a gang that would die for V, rarer than "a gang that likes you".
  let posture = IsDefined(score) && IsDefined(t) ? score.GetPosture(t.faction) : ECBPosture.Neutral;
  if !CBMyCrewOn() || !IsDefined(book) || !IsDefined(score) || !book.HasRoom() || !IsDefined(t) || t.cop
     || Equals(t.faction, n"") || !(Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly))
     || CBCrewHasLentFrom(book, t.faction) {
    return null;
  }
  return CBTalkMakeLine(CBT(n"Cyberbane-Crew-LendOneOfYoursOnMy"), CBTalkActLendOne(), t"ChoiceCaptionParts.ReinforcementIcon");
}

func CBCrewHasLentFrom(book: ref<CBCrewBook>, faction: CName) -> Bool {
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && m.kind == CBCrewLent() && Equals(m.faction, faction) {
      return true;
    }
  }
  return false;
}

public func CBCrewLendAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !book.HasRoom() {
    return CBTalkSay(CBT(n"Cyberbane-Crew-NobodyToSpareRightNow"), n"");
  }
  // Who they send: one of their seats as V has seen them fight, else one of their own fighters from the roster, else
  // the one V is talking to.
  let fs = sys.FindFaction(t.faction);
  let record = TDBID.None();
  if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
    let seats = [fs.roleAssaultRecord, fs.roleTankRecord, fs.roleBladeRecord, fs.roleNetrunnerRecord];
    record = CBCrewSeat(seats[RandRange(0, ArraySize(seats))], fs.sampleRecord);
  }
  if !CBHunterRecordFit(record) {
    record = CBApexRosterRecord(t.faction, RandRange(0, 4));
  }
  if !CBHunterRecordFit(record) && IsDefined(t.npc) && !t.npc.IsCrowd() {
    record = t.npc.GetRecordID();
  }
  if !CBHunterRecordFit(record) {
    return CBTalkSay(CBT(n"Cyberbane-Crew-NobodyToSpareRightNow"), n"");
  }
  let now = CBGameSeconds(game);
  let m = book.Add(CBCrewLent(), record, n"", t.faction, 0, CBConfig.MyCrewLoyaltyLent(), CBEventDistrict(sys, game), now,
                   CBCrewKillsOf(sys, t.faction));
  if !IsDefined(m) {
    return CBTalkSay(CBT(n"Cyberbane-Crew-NobodyToSpareRightNow"), n"");
  }
  let name = CBCrewFirst(sys, m);
  CBCrewJoined(sys, game, m, CBTf(n"Cyberbane-Crew-SayIMYoursNowAs", [s"\(CBCapFirst(CBFactionLabel(t.faction)))"]));
  return CBTalkSay(CBLineOf([CBTf(n"Cyberbane-Crew-SYoursGoodBringThemHome", [s"\(name)", s"\(CBCrewSeatWord(m.seat))"]),
                             CBTf(n"Cyberbane-Crew-TakeAndRememberWhoYourFriends", [s"\(name)", s"\(CBYou(sys, game))"])]), n"");
}

// [C3] A solo looking for work: a broker texts the price now and then.
func CBCrewMercOffer(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, now: Float) -> Void {
  let score = sys.GetScore();
  // One of the crew put to recruiting (Reactions/CrewBanner.reds): a solo more often, before V has a name of their own,
  // cheaper, and with fights already behind them.
  let recruiter = CBCrewRecruiterReady(game, book, now);
  let chance = CBConfig.MyCrewOfferChance() + (IsDefined(recruiter) ? CBConfig.CrewRecruitChance() : 0.0);
  if !IsDefined(score) || !book.HasRoom()
     || (!IsDefined(recruiter) && EnumInt(score.GetTier()) < EnumInt(ECBRenownTier.KnownMerc))
     || book.offerUntil > now || RandF() >= chance {
    return;
  }
  let seed = RandRange(1, 1000000);
  if !TDBID.IsValid(CBHunterRecord(seed, n"")) {
    return;
  }
  let district = sys.GetCurrentDistrict();
  book.offerSeed = seed;
  book.offerPrice = CBConfig.MyCrewMercBase() + CBConfig.MyCrewMercPerTier() * EnumInt(score.GetTier());
  book.offerHaggled = false;
  book.offerUntil = now + CBConfig.SecondsPerDay();
  book.offerSender = CBPhoneDistrictSender(district);
  if Equals(book.offerSender, CBPhoneUnknownSender()) {
    book.offerSender = CBT(n"Cyberbane-Crew-Broker");
  }
  let bb = CBCrewBannerBook.Get(game);
  if IsDefined(bb) {
    bb.offerWins = 0;
    if IsDefined(recruiter) {
      bb.offerWins = CBCrewRankOf(game, recruiter) >= CBConfig.CrewRecruitSeniorRank() ? CBConfig.CrewRecruitWinsSenior()
                                                                                      : CBConfig.CrewRecruitWins();
    }
  }
  if IsDefined(recruiter) {
    book.offerPrice = RoundF(Cast<Float>(book.offerPrice) * (1.0 - CBConfig.CrewRecruitDiscount()));
  }
  let solo = CBCrewOfferName(sys, game, book);
  let seat = CBCrewSeatWord(CBCrewSeatOf(CBHunterRecord(seed, n""), seed));
  if IsDefined(recruiter) {
    let rank = StrLower(CBCrewRankWord(CBCrewRank(IsDefined(bb) ? bb.offerWins : 0)));
    CBPhoneSendTinted(game, book.offerSender, CBLineOf([
      CBTf(n"Cyberbane-Crew-FromYourCrewSentMeFound", [s"\(CBCrewFirst(sys, recruiter))", s"\(solo)", s"\(seat)", s"\(rank)", s"\(book.offerPrice)"]),
      CBTf(n"Cyberbane-Crew-YourVouchesForThisOneFights", [s"\(CBCrewFirst(sys, recruiter))", s"\(solo)", s"\(seat)", s"\(book.offerPrice)"])]), CBHudCyan());
    CBLog.Info(n"Crew", "A broker offered V a solo the crew's recruiter found.");
    return;
  }
  CBPhoneSendTinted(game, book.offerSender, CBLineOf([
    CBTf(n"Cyberbane-Crew-GotASoloLookingForSteady", [s"\(solo)", s"\(seat)", s"\(book.offerPrice)"]),
    CBTf(n"Cyberbane-Crew-WordSOutYouReBuilding", [s"\(solo)", s"\(seat)", s"\(book.offerPrice)"])]), CBHudCyan());
  CBLog.Info(n"Crew", "A broker offered V a solo for the crew.");
}

// V takes the solo on: paid now, on the roster.
public func CBCrewHire(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  let now = CBGameSeconds(game);
  if !IsDefined(book) || book.offerSeed == 0 || book.offerUntil < now {
    return CBT(n"Cyberbane-Crew-ThatSoloFoundOtherWork");
  }
  if !book.HasRoom() {
    return CBT(n"Cyberbane-Crew-YourCrewSFull");
  }
  if !CBTalkTakeMoney(game, player, book.offerPrice) {
    return CBTf(n"Cyberbane-Crew-ComeBackWithEb", [s"\(book.offerPrice)"]);
  }
  let record = CBHunterRecord(book.offerSeed, n"");
  let bb = CBCrewBannerBook.Get(game);
  let m = book.Add(CBCrewPaid(), record, n"", n"", 0, CBConfig.MyCrewLoyaltyPaid(), CBEventDistrict(sys, game), now, 0);
  if IsDefined(m) {
    m.seed = book.offerSeed;   // the name on the offer is the name they go by
    m.seat = CBCrewSeatOf(record, m.seed);
    // Found by the crew's recruiter: their fights come with them, and somebody vouched for them.
    let found = IsDefined(bb) && bb.offerWins > 0;
    if found {
      m.wins = bb.offerWins;
      m.loyalty = Min(100, m.loyalty + CBConfig.CrewRecruitLoyalty());
    }
    CBCrewJoined(sys, game, m, found ? CBT(n"Cyberbane-Crew-HeardGoodThingsAboutThisCrew")
                                     : CBLineOf([CBT(n"Cyberbane-Crew-MoneySInIMYours"),
                                                 CBTf(n"Cyberbane-Crew-SignedAndLoadedWhereInDo", [s"\(CBHere(sys))"])]));
  }
  book.offerSeed = 0;
  book.offerUntil = 0.0;
  if IsDefined(bb) {
    bb.offerWins = 0;
  }
  return "";
}

// The solo on offer's name, as it will be once hired: one the recruiter found comes with fights, and a nickname with
// enough of them.
public func CBCrewOfferName(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> String {
  if !IsDefined(book) || book.offerSeed == 0 {
    return "";
  }
  let bb = CBCrewBannerBook.Get(game);
  let wins = IsDefined(bb) ? bb.offerWins : 0;
  let seat = CBCrewSeatOf(CBHunterRecord(book.offerSeed, n""), book.offerSeed);
  return CBCrewFullName(sys, CBCrewPaid(), n"", 0, book.offerSeed, wins, seat);
}

// ---- Calling them ([C5]) ------------------------------------------------------------------------------------------

// Is V in trouble with Cyberbane's people: hunted, a crew on its way, an ambush, or a fight with the street's own?
public func CBCrewTrouble(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(des) {
    return false;
  }
  if CBHuntersOut(sys, game) || CBHuntPending(sys) || CBLiveTaggedPresent(game, n"CB_Ambush") {
    return true;
  }
  // Any fight V is in. It counted only Cyberbane's own people, so a V jumped by the game's gangers could never call the
  // crew ("Nothing to call them for"), and a crew already out went home in the middle of the fight.
  return player.IsInCombat();
}

// The crew's key (Mod Settings > Your crew > Call your crew): the call, or home when they are out.
public func CBCrewKeyInput(game: GameInstance, evt: ref<KeyInputEvent>) -> Void {
  if !IsDefined(evt) || NotEquals(evt.GetAction(), EInputAction.IACT_Release) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() || !rt.IsEnabled() || !CBMyCrewOn() {
    return;
  }
  let key = rt.GetSettings().crewCallKey;
  if Equals(key, EInputKey.IK_None) || NotEquals(evt.GetKey(), key) {
    return;
  }
  let bbs = GameInstance.GetBlackboardSystem(game);
  let ui = IsDefined(bbs) ? bbs.Get(GetAllBlackboardDefs().UI_System) : null;
  if !IsDefined(ui) || ui.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) {
    return;
  }
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || book.Count() == 0 {
    return;
  }
  if book.OutCount() > 0 && !book.leaving {
    book.reqHome = true;
  } else {
    book.reqCall = true;
  }
}

// The places every other spawn of Cyberbane's leaves free for V's own crew: as many as come to a call, while anybody is
// on the roster and nobody is out yet.
public func CBCrewRoomKept(game: GameInstance) -> Int32 {
  if !CBMyCrewOn() {
    return 0;
  }
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || book.Count() == 0 || book.OutCount() > 0 {
    return 0;
  }
  return Min(CBConfig.MyCrewSpawnReserve(), book.Count());
}

// Can the crew be called right now? "" when yes, otherwise why not, in V's words.
public func CBCrewCallBlocked(sys: ref<CyberbaneSystem>, game: GameInstance, unasked: Bool, opt fromMenu: Bool, opt only: Int32) -> String {
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  if !CBMyCrewOn() || !IsDefined(book) || !IsDefined(player) {
    return CBT(n"Cyberbane-Crew-NobodySAnswering");
  }
  if book.Count() == 0 {
    return CBT(n"Cyberbane-Crew-YouDonTHaveACrew");
  }
  if only > 0 {
    if book.IsOut(only) {
      return CBT(n"Cyberbane-Crew-TheyReAlreadyWithYou");
    }
    if book.leaving {
      return CBT(n"Cyberbane-Crew-TheyReOnTheirWayHome");
    }
  } else {
    if book.OutCount() > 0 {
      return book.leaving ? CBT(n"Cyberbane-Crew-TheyReOnTheirWayHome") : CBT(n"Cyberbane-Crew-TheyReAlreadyWithYou");
    }
  }
  // A round with one of them is on: V is in a fight with their body, so a call went, and sent a second of the same
  // person with two others to fight the first.
  let kb = CBCrewKitBook.Get(game);
  if IsDefined(kb) && kb.sparMember > 0 {
    return CBT(n"Cyberbane-Crew-FinishTheRoundFirst");
  }
  if !fromMenu && !CBWorldStable(game) {
    return CBWorldStableWhy(game);
  }
  if IsDefined(player.GetMountedVehicle()) {
    return CBT(n"Cyberbane-Crew-NotWhileYouReDrivingGet");
  }
  let held = CBCrewHeldWhy(sys, game);
  if StrLen(held) > 0 {
    return held;
  }
  // Only room for one is needed now: they needed five of the shared places, which a big fight never left free, and
  // every other lane keeps room for them instead (CBCrewRoomKept, Spawn/Spawner.reds).
  if CBSpawnRoom(game) <= 0 {
    return CBT(n"Cyberbane-Crew-TooManyPeopleAroundTheyCan");
  }
  if only > 0 {
    let one = book.Find(only);
    if !IsDefined(one) {
      return CBT(n"Cyberbane-Crew-NobodySAnswering");
    }
    let now1 = CBGameSeconds(game);
    if !CBCrewReady(book, one, now1) {
      // Their own reason, which names them: "Nobody can come yet: Sai just got back" read wrong for one person, on the
      // Hub and in their own thread.
      let why1 = CBCrewWhyNotReady(sys, game, one, now1);
      return StrLen(why1) > 0 ? CBTf(n"Cyberbane-Crew-OneNotReady", [why1]) : CBTf(n"Cyberbane-Crew-OneCantComeNow", [CBCrewFirst(sys, one)]);
    }
    return "";
  }
  let readyList = CBCrewReadyOrder(book, CBGameSeconds(game), 0);   // a named list: ArraySize of a call's result reads garbage
  if ArraySize(readyList) == 0 {
    return CBCrewNobodyReadyWhy(sys, game, book);
  }
  return "";
}

// Nobody can come: who, why, and when they can.
func CBCrewNobodyReadyWhy(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> String {
  let now = CBGameSeconds(game);
  let parts = "";
  let i = 0;
  while i < book.Count() && i < 3 {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) {
      let why = CBCrewWhyNotReady(sys, game, m, now);
      if StrLen(why) > 0 {
        parts += (StrLen(parts) > 0 ? "; " : "") + why;
      }
    }
  }
  return StrLen(parts) > 0 ? CBTf(n"Cyberbane-Crew-NobodyCanComeYet", [parts]) : CBT(n"Cyberbane-Crew-EverybodySHurtBusyOrJust");
}

// Why this one cannot come now, named: hurt, away and where, sparring, just back; "" when none of those (out of
// CBCrewNobodyReadyWhy, so a call for one of them says the same as a call for all).
func CBCrewWhyNotReady(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, now: Float) -> String {
  if !IsDefined(m) {
    return "";
  }
  let who = CBCrewFirst(sys, m);
  if CBCrewHurt(m, now) {
    return CBTf(n"Cyberbane-Crew-SStillPatchedUpAboutH", [s"\(who)", s"\(CeilF((m.hurtUntil - now) / CBConfig.SecondsPerHour()))"]);
  }
  let away = CBCrewAwayWord(game, m.id, now);
  if StrLen(away) > 0 {
    return CBTf(n"Cyberbane-Crew-S", [s"\(who)", s"\(StrLower(away))"]);
  }
  if CBCrewSparring(game, m.id) {
    return CBTf(n"Cyberbane-Crew-SSparringWithYou", [s"\(who)"]);
  }
  // On watch at home: CBCrewReady keeps a guard back, and nothing here said so.
  if CBGuardPosted(game, m.id) {
    return CBTf(n"Cyberbane-Crew-SStandingGuard", [s"\(who)"]);
  }
  if m.calledAt > 0.0 && now - m.calledAt < CBConfig.MyCrewCallSeconds() {
    return CBTf(n"Cyberbane-Crew-JustGotBackGiveItMinutes", [s"\(who)", s"\(CeilF((CBConfig.MyCrewCallSeconds() - (now - m.calledAt)) / 60.0))"]);
  }
  return "";
}

// Where V is, for the crew: "" when they can come here, otherwise why not. The story, a scene and a safe place always
// keep them out; a job does by the setting (Your crew on jobs), and the game's hostile zones no longer do.
public func CBCrewHeldWhy(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  switch CBCrewHeldReason(sys, game) {
    case 1: return CBT(n"Cyberbane-Crew-NobodySAnswering");
    case 2: return CBT(n"Cyberbane-Crew-NotIntoTheStoryCallWhen");
    case 3: return CBT(n"Cyberbane-Crew-YouReInTheMiddleOf");
    case 4: return CBT(n"Cyberbane-Crew-SomewhereSafeTheyLlWaitFor");
    case 5: return CBT(n"Cyberbane-Crew-YouReOnAJobThey");
    case 6: return CBT(n"Cyberbane-Crew-ThatSNoGigTheyStay");
    default: return "";
  }
}

// Which of those it is, so that a crew already out says the real reason when it goes. They all said "Not our kind of
// place.
public func CBCrewHeldReason(sys: ref<CyberbaneSystem>, game: GameInstance) -> Int32 {
  if !IsDefined(sys) {
    return 1;
  }
  if sys.GetStoryHold() != CBStoryNone() {
    return 2;
  }
  if CBPlayerInScene(game) {
    return 3;
  }
  if sys.IsInSanctuary() {
    return 4;
  }
  let jobs = CBCrewOnJobs();
  if Equals(jobs, ECBCrewOnJobs.Never) && sys.IsOnJob() {
    return 5;
  }
  if Equals(jobs, ECBCrewOnJobs.GigsAndSideJobs) && CBOnMainStoryJob(sys, game) {
    return 6;
  }
  return 0;
}

// What the crew says as they go for that reason.
public func CBCrewHeldLeaving(reason: Int32) -> String {
  switch reason {
    case 2: return CBT(n"Cyberbane-Crew-TheStorySGotYouWe");
    case 3: return CBT(n"Cyberbane-Crew-YouReTiedUpWeLl");
    case 4: return CBT(n"Cyberbane-Crew-YouReSafeInThereWe");
    case 5: return CBT(n"Cyberbane-Crew-ThatSYourJobNotOurs");
    case 6: return CBT(n"Cyberbane-Crew-ThisIsTheBigStoryWe");
    default: return CBT(n"Cyberbane-Crew-WeReHeadingBack");
  }
}

public func CBCrewOnJobs() -> ECBCrewOnJobs {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().crewOnJobs : ECBCrewOnJobs.GigsAndSideJobs;
}

// Close to the tracked objective of a main-story quest: the game's quests, where people the story needs stand. A gig, a
// side job, a cyberpsycho or a street story is not this.
public func CBOnMainStoryJob(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) || !sys.NearTrackedPins(player.GetWorldPosition(), CBQuestAreaRadius()) {
    return false;
  }
  let jm = GameInstance.GetJournalManager(game);
  if !IsDefined(jm) {
    return false;
  }
  let entry = jm.GetTrackedEntry();
  let steps = 0;
  while IsDefined(entry) && steps < 4 {
    let quest = entry as JournalQuest;
    if IsDefined(quest) {
      return Equals(quest.GetType(), gameJournalQuestType.MainQuest);
    }
    entry = jm.GetParentEntry(entry);
    steps += 1;
  }
  return false;
}

// Would this one sell V out, called now? Low loyalty, and lower still when the people after V are their old gang.
func CBCrewWillBetray(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> Bool {
  if !CBCrewBetrayalOn() || m.kind == CBCrewLent() {
    return false;
  }
  let line = CBConfig.MyCrewBetrayLine();
  let hunters = sys.GetHuntFaction();
  if NotEquals(m.faction, n"") && (Equals(hunters, m.faction) || Equals(sys.GetPendingSquadFaction(), m.faction)) {
    line += CBConfig.MyCrewOldGangLine();
  }
  if m.loyalty >= line {
    return false;
  }
  return RandF() < ClampF(0.25 + 0.03 * Cast<Float>(line - m.loyalty), 0.0, 0.85);
}

// V calls: up to three come, the most loyal first. Unasked (come on their own), only the most loyal, and nobody who
// would sell V out.
public func CBCrewCall(sys: ref<CyberbaneSystem>, game: GameInstance, unasked: Bool, opt only: Int32) -> String {
  let blocked = CBCrewCallBlocked(sys, game, unasked, false, only);
  if StrLen(blocked) > 0 {
    // Said on the Hub, and now in the log too, with what is taking up the room: "I couldn't call my crew" came with
    // nothing to say which of these it was.
    CBLog.Info(n"Crew", s"V's crew was not called: \(blocked) (\(CBSpawnRoomNote(game))).");
    return blocked;
  }
  let book = CBCrewBook.Get(game);
  let now = CBGameSeconds(game);
  // Called with nothing to fight, they walk with V: two of them, until V sends them home. Up to then the call was only
  // ever "Nothing to call them for" outside a fight.
  let joining = book.OutCount() > 0;
  let escort = joining ? book.escort : (!unasked && !CBCrewTrouble(sys, game));
  let want = only > 0 ? Min(1, CBSpawnRoom(game)) : Min(escort ? CBConfig.MyCrewEscortOut() : CBConfig.MyCrewOut(), CBSpawnRoom(game));
  let order: array<ref<CBCrewMember>>;
  if only > 0 {
    let one = book.Find(only);
    if IsDefined(one) {
      ArrayPush(order, one);
    }
  } else {
    order = CBCrewReadyOrder(book, now, unasked ? CBConfig.MyCrewOwnLoyalty() : 0);
  }
  let sent = 0;
  let sold = 0;
  let i = 0;
  while i < ArraySize(order) && sent < want {
    let m = order[i];
    i += 1;
    let turns = false;
    let comes = true;
    if !unasked && CBCrewWillBetray(sys, m) {
      if book.turnMember == 0 && CBRivalsOn() && RandF() < 0.5 {
        turns = true;
      } else {
        comes = false;
        CBCrewSellOut(sys, game, book, m);
        sold += 1;
      }
    }
    if comes {
      let record = m.record;
      if (!TDBID.IsValid(record) || !CBRecordIsPerson(record)) && NotEquals(m.faction, n"") {
        record = CBGangTemplate(sys, m.faction);
      }
      let body: EntityID;
      // From further out when nowhere close will take them (CBSpawnOnSide), the way every hunter comes: "nowhere to put
      // them near V out of sight" refused the crew in the middle of a fight that an apex squad had walked into.
      let ring = 0;
      let placedOut = CBSpawnOnSide(game, record, m.look, n"CB_Own", CBConfig.MyCrewSpawnDistance(), body, ring) > 0;
      if placedOut && ring > 1 {
        CBLog.Info(n"Crew", s"One of V's crew placed from \(CBSpawnRingWords(ring)).");
      }
      if placedOut {
        // Their wait between calls starts when they are seen standing (CBMyCrewTick), not here: the engine can take a
        // spawn and never place it.
        book.AddOut(body, m.id, sys.GetTickCount());
        sent += 1;
        if turns {
          book.turnMember = m.id;
          book.turnTicks = 0;
        }
        CBCrewText(sys, game, m, CBCrewOnTheWay(sys, game, m, unasked, escort), false, true);
      }
    }
  }
  if sent == 0 {
    if sold == 0 {
      // The last spot's refusal too: "nowhere to put them" alone never said it was the job rule every time.
      let rtWhy = CyberbaneRuntime.Get();
      let lastWhy = IsDefined(rtWhy) ? CBBlockLabel(rtWhy.GetLastSpawnBlock()) : "";
      CBLog.Info(n"Crew", s"V's crew was not called: nowhere to put them on any ring round V, out to \(RoundF(CBConfig.MyCrewFarSpawnDistance())) m; the last spot refused for \(StrLen(lastWhy) > 0 ? lastWhy : "no ground") (\(CBSpawnRoomNote(game))).");
    }
    return sold > 0 ? "" : CBT(n"Cyberbane-Crew-NobodyCouldGetThroughToYou");
  }
  book.leaving = false;
  book.quiet = 0;
  book.driving = 0;
  if !joining {
    book.escort = escort;
    book.fought = !escort;
  }
  CBFileLog(sys, n"CrewCalled", now, CBEventDistrict(sys, game), n"", Cast<Float>(sent));
  CBLog.Info(n"Crew", s"V's crew is coming: \(sent)" + (escort ? ", to walk with V." : "."));
  return "";
}

func CBCrewOnTheWay(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, unasked: Bool, escort: Bool) -> String {
  let here = CBHere(sys);
  let hunters = sys.GetHuntFaction();
  let who = NotEquals(hunters, n"") ? CBFactionLabel(hunters) : CBT(n"Cyberbane-Crew-WhoeverItIs");
  if escort {
    return CBLineOf([CBTf(n"Cyberbane-Crew-ComingToWeLlWalkWith", [s"\(here)"]), CBT(n"Cyberbane-Crew-OnMyWayTellMeWhen"),
                     CBT(n"Cyberbane-Crew-QuietDayFineByMeComing")]);
  }
  if unasked {
    return CBLineOf([CBTf(n"Cyberbane-Crew-HeardWereWaitingForYouAlready", [s"\(who)"]), CBTf(n"Cyberbane-Crew-DonTCallDonTNeed", [s"\(here)"])]);
  }
  if NotEquals(m.faction, n"") && Equals(hunters, m.faction) {
    return CBLineOf([CBTf(n"Cyberbane-Crew-MyOldCrewFineIM", [s"\(CBCapFirst(who))"]), CBTf(n"Cyberbane-Crew-IKnowHowFightILl", [s"\(who)"])]);
  }
  if m.wins >= 5 {
    return CBLineOf([CBTf(n"Cyberbane-Crew-AgainSameAsAlwaysComingTo", [s"\(here)"]), CBT(n"Cyberbane-Crew-KeepYourHeadDownIKnow")]);
  }
  return CBLineOf([CBTf(n"Cyberbane-Crew-OnMyWayToHoldOn", [s"\(here)"]), CBTf(n"Cyberbane-Crew-ComingDonTDieBeforeI", [s"\(CBWhenTail(game))"]),
                   CBTf(n"Cyberbane-Crew-GotItWonTKnowWhat", [s"\(CBCapFirst(who))"])]);
}

// From spawn setup (Spawn/Spawner.reds): one of V's own, kitted for their seat, following V.
public func CBSetUpCrewMember(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(puppet) || !IsDefined(player) || !CBStillStanding(puppet) || !IsDefined(book) {
    return;
  }
  // One of them called out for a spar (Reactions/CrewKit.reds): set up for the round, never as a follower.
  if CBCrewSparSetUp(sys, game, puppet) {
    return;
  }
  let m = book.MemberOfBody(puppet.GetEntityID());
  // A body that came too late, after its call let go of it (CBMyCrewTick): nobody's, so it follows nobody. It walks off
  // at peace with V, and the sweep takes it once V is away.
  let desUp = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(m) && IsDefined(desUp) && desUp.IsTagged(puppet.GetEntityID(), n"CB_Orphan") {
    CBCrewFriendlyToV(game, puppet);
    CBOrderFlee(game, puppet, true);
    return;
  }
  CBDisarmGodMode(game, puppet);
  CBCrewKeepLook(sys, m, puppet);
  if IsDefined(m) {
    CBKitApexSeat(puppet, m.seat);
    CBCrewApplyKit(sys, game, puppet, m);   // rank, gear, the weapon handed over, chrome (Reactions/CrewKit.reds)
  } else {
    CBKitSquadMember(puppet);
  }
  CBMakeFollower(puppet, player);
  // When asked for, that weapon in their hand (experimental): after the role, so setting it cannot drop the order.
  if IsDefined(m) {
    CBCrewArmFromKit(game, puppet, m);
  }
  // In their own voices: into a fight, or a greeting for a walk.
  CBVoice(sys, game, puppet, book.escort && !CBCrewTrouble(sys, game) ? n"greeting" : n"start_combat", n"CrewArrive", 12.0);
}

// [C5] With Come on their own: an ambush has sprung on V, and the most loyal are already coming.
public func CBCrewKeepLook(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(m) || !CBNpcSafe(sys, puppet) {
    return;
  }
  let rec = puppet.GetRecordID();
  if (!TDBID.IsValid(m.record) || !CBRecordIsPerson(m.record)) && TDBID.IsValid(rec) && CBRecordIsPerson(rec) {
    m.record = rec;
    m.look = n"";
  }
  if Equals(m.look, n"") && rec == m.record {
    let look = puppet.GetCurrentAppearanceName();
    if IsNameValid(look) && NotEquals(look, n"default") {
      m.look = look;
      CBLog.Info(n"Crew", "One of the crew keeps the look they turned up in.");
    }
  }
}

func CBCrewAmbushSprung(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  return IsDefined(des) && IsDefined(player) && CBTagEngagedNear(sys, game, des, player, n"CB_Ambush");
}

// ---- Every tick: the ones out with V ([C6]) ------------------------------------------------------------------------

public func CBMyCrewTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(player) || !IsDefined(des) {
    return;
  }
  if EntityID.IsDefined(book.turnedBody) {
    CBCrewTurnedTick(sys, game, book, des, player);
  }
  CBCrewServiceHub(sys, game, book);
  // Nobody on the roster and nobody out: nothing to watch for.
  if book.Count() == 0 && book.OutCount() == 0 {
    return;
  }
  if book.OutCount() == 0 {
    if !CBLiveTaggedPresent(game, n"CB_Ambush") {
      book.ambushAnswered = false;
    } else {
      if !book.ambushAnswered && CBCrewComeOnOwnOn() && sys.GetTickCount() % 3 == 0 && CBWorldStable(game)
         && CBCrewAmbushSprung(sys, game) {
        book.ambushAnswered = true;
        CBCrewCall(sys, game, true);
      }
    }
    return;
  }
  if book.leaving {
    // Gone once V cannot see them; the list empties as they do. The dead are dropped by the death hook.
    CBDeleteTaggedSafe(game, n"CB_Own", true, true);
    let tagged = des.GetTaggedIDs(n"CB_Own");
    let i = book.OutCount() - 1;
    while i >= 0 {
      if !des.IsSpawning(book.outBody[i]) && !ArrayContains(tagged, book.outBody[i]) {
        book.DropOut(i);
      }
      i -= 1;
    }
    if book.OutCount() == 0 {
      book.leaving = false;
    }
    return;
  }
  let ppos = player.GetWorldPosition();
  let tick = sys.GetTickCount();
  let now = CBGameSeconds(game);
  let up = 0;
  let coming = 0;
  let near = false;
  let k = 0;
  while k < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[k]) as ScriptedPuppet;
    if CBStillStanding(p) {
      up += 1;
      book.outDown[k] = false;
      // Here at last: they have come, and their wait between calls starts now, never at the asking.
      if !book.outSeen[k] {
        book.outSeen[k] = true;
        let seenM = book.Find(book.outMember[k]);
        if IsDefined(seenM) {
          seenM.calledAt = now;
        }
      }
      // In the crew's own car, or waiting on it, they can fall further behind on the road without being lost
      // (Reactions/CrewDrive.reds).
      let reach = (p.cbCrewCarRider || CBCrewCarWaitingFor(game, book.outBody[k])) ? CBConfig.CrewCarLostDistance() : CBConfig.MyCrewLeaveDistance();
      if Vector4.Distance(p.GetWorldPosition(), ppos) <= reach {
        near = true;
      }
    } else {
      // Still on the way: the engine building them, or asked for a moment ago and not in the world yet.
      if des.IsSpawning(book.outBody[k]) || (!book.outSeen[k] && tick - book.outTick[k] <= CBConfig.MyCrewNoShowTicks()) {
        coming += 1;
        near = true;
      } else {
        // Where the game knocks a follower down, they die, with Your crew can die on (CBCrewDiesOfIt). Already dying:
        // nothing more, their death is on its way.
        if IsDefined(p) && !p.IsDead() && (p.cbCrewDying || CBCrewDiesOfIt(game, p)) {
          coming += 1;   // the call is not over before their death is
          near = true;
        } else {
        if IsDefined(p) && CBIsDown(p) && !p.IsDead() {
          // Down, not dead: the game's follower role drops a follower the way it drops its own companions, where
          // anybody else would die. Said at once, so a body on the ground is not read as a death nobody mentions.
          if !book.outDown[k] && book.outSeen[k] && CBMessagesOn() {
            let downM = book.Find(book.outMember[k]);
            if IsDefined(downM) {
              CBCrewText(sys, game, downM, CBLineOf([CBT(n"Cyberbane-Crew-IMDownStillBreathingFinish"), CBT(n"Cyberbane-Crew-HitBadIMDownNot"),
                                                     CBT(n"Cyberbane-Crew-CanTGetUpDonT")]));
            }
          }
          book.outDown[k] = true;
          if p.IsAttached() && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.MyCrewLeaveDistance() {
            near = true;   // lying where the fight is, not lost
          }
        }
        }
      }
    }
    k += 1;
  }
  // Taken by the engine and never put in the world: let go with no wait and nothing counted. Each one used to spend the
  // member's hour, text "Lost you" and, when the others fought, count a win for a fight they never saw.
  let noShows = 0;
  let back = book.OutCount() - 1;
  while back >= 0 {
    let gone = book.outBody[back];
    if !book.outSeen[back] && tick - book.outTick[back] > CBConfig.MyCrewNoShowTicks() && !des.IsSpawning(gone)
       && !IsDefined(GameInstance.FindEntityByID(game, gone)) {
      if des.IsTagged(gone, n"Cyberbane") && !des.IsTagged(gone, n"CB_Orphan") {
        des.AssignTag(gone, n"CB_Orphan");
      }
      book.DropOut(back);
      noShows += 1;
    }
    back -= 1;
  }
  if noShows > 0 {
    CBLog.Info(n"Crew", s"\(noShows) of V's crew never made it into the world; let go with no wait.");
    if book.OutCount() == 0 {
      book.escort = false;
      book.fought = false;
      if CBMessagesOn() {
        CBCrewText(sys, game, null, CBT(n"Cyberbane-Crew-CouldnTGetThroughToYou"));
      }
      return;
    }
  }
  // Anybody fighting V is their enemy too: the follower role alone left them blind to it.
  let trouble = CBCrewTrouble(sys, game);
  if trouble {
    book.fought = true;
  }
  book.quiet = trouble ? 0 : book.quiet + 1;
  // The fight they stood in, won: counted once that fight is over, whatever ends the call after it.
  CBCrewBattleTick(sys, game, book, player);
  book.driving = IsDefined(player.GetMountedVehicle()) ? book.driving + 1 : 0;
  // The one set to turn does it once the fight has them in it ([C7]).
  if book.turnMember > 0 && trouble && up > 0 {
    book.turnTicks += 1;
    if book.turnTicks >= CBConfig.MyCrewTurnTicks() {
      CBCrewTurn(sys, game, book);
    }
  }
  let why = -1;
  if book.quiet >= CBConfig.MyCrewQuietTicks() {
    if !book.escort {
      why = 0;
    } else {
      // Walking with V: after a fight on the way anybody down is carried home, and the call ends as a fight's does; the
      // rest stay. The win itself is counted when the fight is over (CBCrewBattleTick).
      if book.fought && CBCrewAnyDown(book) {
        why = 0;
      }
    }
  }
  // Sent home on the Hub, the phone or the key.
  if book.reqHome {
    book.reqHome = false;
    why = 6;
  }
  // V drove off without them. Riding with V, or in a car of their own behind V, is coming along.
  if book.driving >= CBConfig.MyCrewDriveTicks() && !CBCrewRidesWithV(sys, game, book, player) {
    why = 1;
  }
  if !near && tick % 5 == 0 {
    why = 2;
  }
  // The crew's own gates, the ones the call asks: the story, a scene, a safe place, a job by the setting.
  if StrLen(CBCrewHeldWhy(sys, game)) > 0 {
    why = 3;
  }
  if up == 0 && coming == 0 && !trouble {
    why = 4;
  }
  // Switched off with them out: they go home now, the one order they get, instead of following V until the fight went
  // quiet. No win is counted and nothing is said, as when arrivals are held.
  if !CBMyCrewOn() {
    why = 5;   // its own reason: 3 says where V is, and switching the crew off says nothing
  }
  if why >= 0 {
    CBCrewEndCall(sys, game, book, why);
  }
}

// One of them sent home on their own from their orders on the Hub, the rest staying with V. The last one out ends the
// call the way the whole crew's home does, which counts how it went (CBCrewEndCall).
public func CBCrewSendOneHome(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, id: Int32) -> Void {
  let k = book.OutIndexOfMember(id);
  if k < 0 || book.leaving {
    return;
  }
  let m = book.Find(id);
  if book.OutCount() <= 1 {
    book.reqHome = true;
    return;
  }
  let body = book.outBody[k];
  let p = GameInstance.FindEntityByID(game, body) as ScriptedPuppet;
  if !CBNpcSafe(sys, p) || !CBStillStanding(p) {
    if CBMessagesOn() {
      CBCrewText(sys, game, m, CBT(n"Cyberbane-Crew-CanTWalkHomeLikeThis"));
    }
    return;
  }
  CBEndFollower(p);
  CBCrewFriendlyToV(game, p);
  CBOrderFlee(game, p, true);
  let des = GameInstance.GetDynamicEntitySystem();
  if IsDefined(des) {
    des.UnassignTag(body, n"CB_Own");
    des.AssignTag(body, n"CB_Orphan");
  }
  book.DropOut(k);
  // Their wait between calls starts again now: called straight back, a second of them would walk up while the first was
  // still walking off.
  if IsDefined(m) {
    m.calledAt = CBGameSeconds(game);
  }
  if CBMessagesOn() {
    CBCrewText(sys, game, m, CBT(n"Cyberbane-Crew-HeadingHomeTheRestStay"));
  }
  CBLog.Info(n"Crew", "One of V's crew was sent home on their own; the rest stay with V.");
}

// The fight is over, or V has gone: everybody standing stops following and walks home, the one order they get.
// What happened to each is counted here: a win, a wound, and whether V stood over them when they went down.
func CBCrewEndCall(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, why: Int32) -> Void {
  let player = GetPlayer(game);
  let now = CBGameSeconds(game);
  // A win needs a fight, and is counted when that fight is over (CBCrewBattleTick). One won and over a moment ago, the
  // call cut short before the tick counted it (sent home, a car, a held place, V gone on), counts here.
  if why != 4 && why != 5 && book.battle && book.engaged && IsDefined(player) && CBCrewFightIsOver(sys, game, book, player) {
    CBCrewFightWon(sys, game, book, true);
  }
  let won = book.wonCall;
  let ppos = IsDefined(player) ? player.GetWorldPosition() : new Vector4(0.0, 0.0, 0.0, 1.0);
  let speaker: ref<CBCrewMember>;
  let leftLying: ref<CBCrewMember>;
  let i = 0;
  while i < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
    let m = book.Find(book.outMember[i]);
    // Only the ones who came: nothing is counted for, or said by, somebody still on the way.
    if IsDefined(m) && book.outSeen[i] {
      if book.outDown[i] {
        m.scars += 1;
        // A bed at the crew's home heals them faster (Reactions/CrewLife.reds).
        m.hurtUntil = now + CBConfig.MyCrewHurtDays() * CBCrewHomeHealFactor(game) * CBConfig.SecondsPerDay();
        // Their story: the scar, and who gave it when it was a Rival, for the revenge they may ask for.
        let scarBy = 0;
        if IsDefined(p) && IsDefined(p.cbLastAttacker) {
          let byRival = CBFindRivalByBody(sys, p.cbLastAttacker.GetEntityID());
          scarBy = IsDefined(byRival) ? byRival.id : 0;
        }
        CBCrewLifeNote(game, m.id, CBLifeScar(), CBEventDistrict(sys, game), scarBy);
        if scarBy > 0 {
          CBRivalTimelineNote(game, scarBy, CBTlScarredCrew());
          CBRivalCallingCard(sys, game, sys.FindRivalById(scarBy));   // and they let V know it
        }
        let stayed = IsDefined(p) && p.IsAttached() && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.MyCrewStayedDistance();
        if stayed {
          CBCrewLoyalty(m, CBConfig.MyCrewStayedLoyalty(), CBCrewWhyStayed());
          // Alive, and how long they are out: the card only said HURT, so a crew member seen falling read as dead.
          if CBMessagesOn() {
            CBCrewText(sys, game, m, CBTf(n"Cyberbane-Crew-YouStayedWithMeILl", [s"\(RoundF(CBConfig.MyCrewHurtDays() * 24.0))"]));
          }
        } else {
          CBCrewLoyalty(m, -CBConfig.MyCrewLeftLyingLoyalty(), CBCrewWhyLeftLying());
          leftLying = m;
        }
      } else {
        if !IsDefined(speaker) || m.loyalty > speaker.loyalty {
          speaker = m;
        }
      }
    }
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      CBEndFollower(p);   // out of V's car first, their seat given back
      CBCrewFriendlyToV(game, p);
      CBOrderFlee(game, p, true);   // walking home, as the comment above says; a sprint read as running away
    } else {
      // Down on the follower role: off it too, or the game stands them back up as a companion who follows V, in sight,
      // so the sweep that takes them home never can and the crew reads "on their way home" for good.
      if CBNpcSafe(sys, p) && !p.IsDead() {
        CBEndFollower(p);
        CBCrewFriendlyToV(game, p);
      }
    }
    i += 1;
  }
  book.leaving = true;
  book.turnMember = 0;
  book.turnTicks = 0;
  book.escort = false;
  book.fought = false;
  CBCrewBattleReset(game, book);
  book.wonCall = false;
  if !CBMessagesOn() {
    return;
  }
  if IsDefined(speaker) {
    let home = NotEquals(speaker.home, n"") ? CBDistrictLabel(speaker.home) : CBT(n"Cyberbane-Crew-Home");
    if why == 0 {
      CBCrewText(sys, game, speaker, won ? CBLineOf([CBTf(n"Cyberbane-Crew-CleanWeReHeadingBackTo", [s"\(home)"]), CBT(n"Cyberbane-Crew-ThatSDoneCallAgainSame"),
                                                    CBTf(n"Cyberbane-Crew-NotBadNotBadAtAll", [s"\(CBYou(sys, game))"])])
                                         : CBT(n"Cyberbane-Crew-QuietNowWeReGoing"), true);
    }
    if why == 1 {
      CBCrewText(sys, game, speaker, CBLineOf([CBT(n"Cyberbane-Crew-GoWeLlFindOurOwn"), CBT(n"Cyberbane-Crew-NiceOfYouToWaitWe")]), true);
    }
    if why == 2 {
      CBCrewText(sys, game, speaker, CBTf(n"Cyberbane-Crew-LostYouHeadingBackTo", [s"\(home)"]), true);
    }
    if why == 3 {
      CBCrewText(sys, game, speaker, CBCrewHeldLeaving(CBCrewHeldReason(sys, game)), true);
    }
    if why == 6 {
      CBCrewText(sys, game, speaker, CBLineOf([CBTf(n"Cyberbane-Crew-HeadingBackToCallWhenYou", [s"\(home)"]), CBT(n"Cyberbane-Crew-GoingYouKnowWhereToFind")]), true);
    }
  }
  if IsDefined(leftLying) {
    CBCrewText(sys, game, leftLying, CBLineOf([CBT(n"Cyberbane-Crew-YouLeftMeLyingThereI"), CBT(n"Cyberbane-Crew-WokeUpAloneOnThePavement")]));
  }
}

// Somebody V's crew was set against (CBCrewHostilityTick), so the pair can be stood down again when they stop being V's
// enemy: their hands up, talked round, paid.
@addField(ScriptedPuppet)
public let cbCrewPaired: Bool;

// V's crew against whoever is fighting V.
public func CBVsSideHostilityTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) || sys.GetTickCount() % 2 != 0 {
    return;
  }
  CBCrewHostilityTick(sys, game, CBCrewBook.Get(game), player);
}

func CBCrewHostilityTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, player: ref<PlayerPuppet>) -> Void {
  let reg = sys.GetRegistry();
  let pagent = player.GetAttitudeAgent();
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(reg) || !IsDefined(pagent) || !IsDefined(des) {
    return;
  }
  let crew: array<ref<ScriptedPuppet>>;
  let i = 0;
  while IsDefined(book) && !book.leaving && i < book.OutCount() {
    let c = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
    if CBNpcSafe(sys, c) && CBStillStanding(c) && IsDefined(c.GetAttitudeAgent()) {
      ArrayPush(crew, c);
    }
    i += 1;
  }
  CBApiSideBodies(sys, game, crew);
  if ArraySize(crew) == 0 {
    return;
  }
  let ppos = player.GetWorldPosition();
  let vFighting = player.IsInCombat();
  for p in reg.GetAll() {
    if CBNpcSafe(sys, p) && !p.IsDead() && CBStillStanding(p)
       && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.MyCrewFightRange()
       && !ScriptedPuppet.IsPlayerCompanion(p) && !des.IsTagged(p.GetEntityID(), n"CB_Own") && !ArrayContains(crew, p) {
      let agent = p.GetAttitudeAgent();
      if IsDefined(agent) {
        // Never a gang's street people standing calm, or anybody standing with V: V in a fight round the corner sent
        // the crew at a sit-down's Tyger Claws, hostile to V on their own turf but sitting at a table, and the meeting
        // went up with V's crew in the middle of it.
        let calmStreet = CBStreetPersonTag(des, p.GetEntityID()) && !CBNpcInCombat(p);
        let enemy = Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) && (vFighting || CBNpcInCombat(p))
                 && !calmStreet && !p.cbSidedWithV;
        if enemy || p.cbCrewPaired {
          // Somebody new fighting V: the crew calls out what they are, in their own voices.
          if enemy && !p.cbCrewPaired {
            CBCrewWarnVoice(sys, game, CBEnemyWarning(game, des, p));
          }
          // Somebody fighting V within reach of one of the crew (CBCrewBattleTick): their fight too.
          if enemy && IsDefined(book) {
            for near in crew {
              if Vector4.Distance(near.GetWorldPosition(), p.GetWorldPosition()) <= CBConfig.MyCrewEngageRadius() {
                book.enemyNear = true;
              }
            }
          }
          for c in crew {
            let cagent = c.GetAttitudeAgent();
            if IsDefined(cagent) && NotEquals(c.GetEntityID(), p.GetEntityID()) {
              if enemy {
                if NotEquals(agent.GetAttitudeTowards(cagent), EAIAttitude.AIA_Hostile)
                   || NotEquals(cagent.GetAttitudeTowards(agent), EAIAttitude.AIA_Hostile) {
                  CBTrace("attitude: V's crew and somebody fighting V");
                  agent.SetAttitudeTowards(cagent, EAIAttitude.AIA_Hostile);
                  cagent.SetAttitudeTowards(agent, EAIAttitude.AIA_Hostile);
                }
              } else {
                CBTrace("attitude: V's crew and somebody who stopped fighting V");
                agent.SetAttitudeTowards(cagent, EAIAttitude.AIA_Neutral);
                cagent.SetAttitudeTowards(agent, EAIAttitude.AIA_Neutral);
              }
            }
          }
          p.cbCrewPaired = enemy;
        }
      }
    }
  }
}

// Your crew can die (on by default).
public func CBCrewCanDie() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().crewCanDie;
}

@addField(ScriptedPuppet)
public let cbCrewDying: Bool;

// Down once already this call, on Easy (CBCrewDiesOfIt).
@addField(ScriptedPuppet)
public let cbCrewFellOnce: Bool;

// Down by the game's follower rule, and to die of it. True when it was.
func CBCrewDiesOfIt(game: GameInstance, p: ref<ScriptedPuppet>) -> Bool {
  if !CBCrewCanDie() || !IsDefined(p) || p.IsDead() || !StatusEffectSystem.ObjectHasStatusEffectWithTag(p, n"FollowerDefeated") {
    return false;
  }
  // Easy: the first fall of a call is a wound, the game's knock-down; the second is a death.
  if Equals(CBCrewPace(), ECBCrewPace.Easy) && !p.cbCrewFellOnce {
    p.cbCrewFellOnce = true;
    return false;
  }
  CBTrace("status: one of V's crew dies where the game would have knocked them down");
  StatusEffectHelper.RemoveStatusEffectsWithTag(p, n"FollowerDefeated");
  p.cbCrewDying = true;
  CBCrewQueueDeath(game, p, 0.25);
  return true;
}

func CBCrewQueueDeath(game: GameInstance, p: ref<ScriptedPuppet>, delay: Float) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) || !IsDefined(p) {
    return;
  }
  let cb = new CBCrewDeathCallback();
  cb.game = game;
  cb.body = p.GetEntityID();
  cb.tries = 0;
  ds.DelayCallback(cb, delay, false);
}

// The kill itself, a moment after the knock-down came off: the game refuses to kill anybody still invulnerable
// (NPCPuppet.Kill), so it is tried again a few times while the knock-down's invulnerability wears off.
public class CBCrewDeathCallback extends DelayCallback {
  public let game: GameInstance;
  public let body: EntityID;
  public let tries: Int32;

  public func Call() -> Void {
    let p = GameInstance.FindEntityByID(this.game, this.body) as ScriptedPuppet;
    if !IsDefined(p) || !p.IsAttached() || p.IsDead() || !p.cbCrewDying || !CBWorldStable(this.game) {
      return;
    }
    StatusEffectHelper.RemoveStatusEffectsWithTag(p, n"FollowerDefeated");
    let killer = p.cbLastAttacker;
    CBTrace("status: the game's own kill on one of V's crew");
    if IsDefined(killer) && killer.IsAttached() {
      StatusEffectHelper.ApplyStatusEffect(p, t"BaseStatusEffect.ForceKill", killer.GetEntityID());
    } else {
      StatusEffectHelper.ApplyStatusEffect(p, t"BaseStatusEffect.ForceKill");
    }
    this.tries += 1;
    if this.tries < 4 {
      let ds = GameInstance.GetDelaySystem(this.game);
      if IsDefined(ds) {
        ds.DelayCallback(this, 0.5, false);   // asked again; does nothing once they are dead
      }
    }
  }
}

func CBCrewAnyDown(book: ref<CBCrewBook>) -> Bool {
  let i = 0;
  while i < book.OutCount() {
    if book.outDown[i] {
      return true;
    }
    i += 1;
  }
  return false;
}

// A fight on the walk is over and nobody is down: a win for each of them standing, as a call's end counts it, and they
// stay with V.
func CBCrewBattleTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(book) || !IsDefined(player) {
    return;
  }
  let huntOut = CBHuntersOut(sys, game);
  if (huntOut || player.IsInCombat() || CBLiveTaggedPresent(game, n"CB_Ambush")) && CBCrewAnyStandingHere(book) {
    book.battle = true;
    if huntOut {
      book.battleHunt = true;
    }
  }
  // Were they really in it? Enemies near them for a few seconds, or a hit one of them took or landed.
  if book.battle {
    if book.enemyNear {
      book.engageTicks += 1;
      if book.engageTicks >= CBConfig.MyCrewEngageTicks() {
        book.engaged = true;
      }
    }
    if CBCrewHitInFight(game, book) {
      book.engaged = true;
    }
  }
  book.enemyNear = false;
  if book.battle && CBCrewFightIsOver(sys, game, book, player) {
    book.overTicks += 1;
    if book.overTicks >= CBConfig.MyCrewWonTicks() {
      if book.engaged {
        CBCrewFightWon(sys, game, book, false);
      } else {
        // Over before they got into it: V's combat outlasting a fight already finished, or one far from them.
        CBLog.Info(n"Crew", "A fight ended with V's crew never in it: no win counted.");
        CBCrewBattleReset(game, book);
      }
    }
  } else {
    book.overTicks = 0;
  }
}

// The fight is over, won or not: the next one starts from nothing, and the hits they took in this one stay in it.
func CBCrewBattleReset(game: GameInstance, book: ref<CBCrewBook>) -> Void {
  book.battle = false;
  book.battleHunt = false;
  book.overTicks = 0;
  book.engaged = false;
  book.engageTicks = 0;
  book.enemyNear = false;
  book.battleDowned = 0;
  let i = 0;
  while i < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
    if IsDefined(p) {
      p.cbFightHitTaken = false;
      p.cbFightHitDealt = false;
    }
    i += 1;
  }
}

// One of the crew took a hit or landed one since this fight began (the hit hook writes it on them, Signals/CombatSignals.reds).
func CBCrewHitInFight(game: GameInstance, book: ref<CBCrewBook>) -> Bool {
  let i = 0;
  while i < book.OutCount() {
    if book.outSeen[i] && !book.outDown[i] {
      let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
      if IsDefined(p) && (p.cbFightHitTaken || p.cbFightHitDealt) {
        return true;
      }
    }
    i += 1;
  }
  return false;
}

// An enemy went down near one of them while a call is out (from the death handler a frame after the death): they were
// in the fight. `byMember` is the member whose hit it was, 0 for anybody else's.
public func CBCrewNoteEnemyDown(sys: ref<CyberbaneSystem>, game: GameInstance, dead: ref<ScriptedPuppet>, byMember: Int32) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || book.OutCount() == 0 || !IsDefined(dead) {
    return;
  }
  let at = dead.GetWorldPosition();
  let near = byMember > 0;
  let i = 0;
  while !near && i < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
    if book.outSeen[i] && !book.outDown[i] && CBNpcSafe(sys, p)
       && Vector4.Distance(p.GetWorldPosition(), at) <= CBConfig.MyCrewEngageRadius() {
      near = true;
    }
    i += 1;
  }
  if near {
    book.engaged = true;
    book.battleDowned += 1;
    book.battle = true;   // a fight the game started counts too, with them in it from the first body
  }
}

// Which member's body this is, 0 for nobody on the roster out now.
public func CBCrewMemberOfBody(book: ref<CBCrewBook>, body: EntityID) -> Int32 {
  if !IsDefined(book) {
    return 0;
  }
  let i = 0;
  while i < book.OutCount() {
    if Equals(book.outBody[i], body) {
      return book.outMember[i];
    }
    i += 1;
  }
  return 0;
}

// Over: nobody the hunt sent still standing, no ambush, and V out of combat. Once the hunt's people were in it, the NCPD
// still on V is no longer this fight: their stars keep V in combat after the last of the gang is down.
func CBCrewFightIsOver(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, player: ref<PlayerPuppet>) -> Bool {
  if CBHuntersOut(sys, game) || CBLiveTaggedPresent(game, n"CB_Ambush") {
    return false;
  }
  return !player.IsInCombat() || (book.battleHunt && CBPoliceOnV(sys));
}

// Any of them in the world and on their feet.
func CBCrewAnyStandingHere(book: ref<CBCrewBook>) -> Bool {
  let i = 0;
  while i < book.OutCount() {
    if book.outSeen[i] && !book.outDown[i] {
      return true;
    }
    i += 1;
  }
  return false;
}

// A fight won (out of the walk's own win): a win for each of them standing, counted once whatever ends the call after
// it. On a walk they stay and say so; `ending`, the call is closing and its own line says the rest.
func CBCrewFightWon(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, ending: Bool) -> Void {
  let downed = book.battleDowned;
  CBCrewBattleReset(game, book);
  book.fought = false;
  book.wonCall = true;
  let now = CBGameSeconds(game);
  let speaker: ref<CBCrewMember>;
  let promoted: ref<CBCrewMember>;
  let promotedFrom = 0;
  let i = 0;
  while i < book.OutCount() {
    let m = book.Find(book.outMember[i]);
    if IsDefined(m) && book.outSeen[i] && !book.outDown[i] {
      let before = CBCrewRankOf(game, m);
      m.wins += 1;
      CBCrewLoyalty(m, CBConfig.MyCrewWinLoyalty(), CBCrewWhyWin());
      if CBCrewRankOf(game, m) > before {
        promoted = m;
        promotedFrom = before;
      }
      if !IsDefined(speaker) || m.loyalty > speaker.loyalty {
        speaker = m;
      }
    }
    i += 1;
  }
  CBFileLog(sys, n"CrewWon", now, CBEventDistrict(sys, game), n"", 0.0);
  CBLog.Info(n"Crew", IsDefined(speaker) ? s"A fight is won with V's crew: a win for each of them standing (\(downed) of theirs down near them)." : "A fight is won, with none of V's crew standing.");
  // Said the moment it is won, in the group chat and in their own voices: the win showed only when they went home. A
  // call closing on it (`ending`) has its own line.
  if IsDefined(speaker) && !ending {
    CBCrewWinLine(sys, game, book, speaker, downed);
  }
  if IsDefined(promoted) {
    // The rank the card shows (fights and training together), with what it lets them do now.
    CBCrewLifePromoted(sys, game, promoted, promotedFrom, CBCrewRankOf(game, promoted));
  }
}

// After the role is cleared they are back in their own attitude group; this keeps them from turning on V on the way.
func CBCrewFriendlyToV(game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !IsDefined(p) || !p.IsAttached() {
    return;
  }
  let agent = p.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) {
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Friendly);
  }
}

// ---- Betrayal ([C7]) ---------------------------------------------------------------------------------------------

// They stay away and tell the people after V where V is: a scout's work is done for them, a search becomes a find, and
// with nobody after V yet, their old gang hears where to send a crew.
func CBCrewSellOut(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>) -> Void {
  let player = GetPlayer(game);
  let now = CBGameSeconds(game);
  let district = CBEventDistrict(sys, game);
  if !IsDefined(player) {
    return;
  }
  let scout = sys.GetScoutFaction();
  if NotEquals(scout, n"") {
    let scoutId = sys.GetScoutId();
    sys.ClearScout();
    CBScoutDraws(game, scoutId);
    sys.SetHuntLkp(player.GetWorldPosition());
    sys.SetHuntLastSeenTick(sys.GetTickCount());
    CBScoutCallIn(sys, game, scout, true);
  } else {
    if CBHuntersOut(sys, game) && sys.GetHuntState() != CBHuntNone() {
      sys.SetHuntState(CBHuntLocated());
      sys.SetHuntLkp(player.GetWorldPosition());
      sys.SetHuntLastSeenTick(sys.GetTickCount());
    } else {
      if NotEquals(m.faction, n"") && CBGangMaySend(sys, m.faction) && Equals(sys.GetPendingSquadFaction(), n"") {
        CBHuntBegin(sys, game, m.faction);
        sys.SetPendingSquad(m.faction, CBWarningTicks(CBConfig.CrewWarningTicks()));
        sys.SetHuntGrade(CBCrewGrade(sys, m.faction));
      }
    }
  }
  let name = CBCrewName(sys, m);
  let why = m.lastWhy;
  book.Remove(m, CBCrewEndSold(), 0, district, now);
  CBFileLog(sys, n"CrewSold", now, district, m.faction, Cast<Float>(m.id));
  if CBMessagesOn() {
    let reason = why == CBCrewWhyUnpaid() ? CBT(n"Cyberbane-Crew-YouShouldHavePaidMe") : (why == CBCrewWhyLeftLying() ? CBT(n"Cyberbane-Crew-YouLeftMeLyingInThe")
                 : (why == CBCrewWhyOldGang() ? CBT(n"Cyberbane-Crew-YouKeptKillingMyPeopleThey") : CBT(n"Cyberbane-Crew-NothingPersonalTheyPayBetter")));
    CBPhoneSendTinted(game, name, CBTf(n"Cyberbane-Crew-NotComingTheyKnowExactlyWhere", [s"\(reason)"]), CBHudRed());
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-Crew-SoldYouOutWhoeverSAfter", [s"\(name)"]), n"");
  }
  CBLog.Info(n"Crew", "A crew member sold V out to the hunters.");
}

// One set to turn does it: the role cleared, hostile to V, and a Rival from now on (the Betrayer).
func CBCrewTurn(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
  CBUiSound(game, n"ui_jingle_chip_malfunction", n"CrewTurned", 30.0);
  let mid = book.turnMember;
  book.turnMember = 0;
  book.turnTicks = 0;
  let k = book.OutIndexOfMember(mid);
  let m = book.Find(mid);
  let des = GameInstance.GetDynamicEntitySystem();
  if k < 0 || !IsDefined(m) || !IsDefined(des) {
    return;
  }
  let id = book.outBody[k];
  let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
  if !CBNpcSafe(sys, p) || !CBStillStanding(p) {
    return;   // down or gone first: the moment passed
  }
  let now = CBGameSeconds(game);
  let district = CBEventDistrict(sys, game);
  let name = CBCrewName(sys, m);
  book.DropOut(k);
  des.UnassignTag(id, n"CB_Own");
  des.AssignTag(id, n"CB_Turned");
  CBEndFollower(p);
  CBGrantAbility(p as NPCPuppet, t"Ability.IsAggressive");
  CBMakeHostileToPlayer(game, p);
  // The Rival they become: the one they were, for one who owed V, or somebody new.
  let faction = NotEquals(m.faction, n"") ? m.faction : CBClassifyFaction(p);
  let r: ref<CBRival>;
  if m.rival > 0 {
    r = sys.FindRivalById(m.rival);
    if IsDefined(r) {
      r.source = EnumInt(ECBRivalSource.Betrayer);
      r.state = EnumInt(ECBRivalState.Active);
      r.origin = district;
      r.encounters += 1;
    }
  }
  if !IsDefined(r) && CBRivalsOn() && NotEquals(faction, n"") {
    r = CBCreateRival(sys, game, faction, p.GetRecordID(), p.GetCurrentAppearanceName(), ECBRivalSource.Betrayer, district, now, true);
  }
  book.turnedBody = id;
  book.turnedTicks = 0;
  book.turnedFled = false;
  book.turnedRival = IsDefined(r) ? r.id : 0;
  if IsDefined(r) {
    r.spawnedEntityId = id;   // their death and their mercy are a Rival's (CBFindRivalByBody)
    CBNoteRivalSeen(sys, game, r, p);
  }
  book.Remove(m, CBCrewEndTurned(), book.turnedRival, district, now);
  CBFileLog(sys, n"CrewTurned", now, district, faction, Cast<Float>(m.id));
  CBIntelSay(game, 3, name, CBLineOf([CBTf(n"Cyberbane-Crew-SorryBetterOffer", [s"\(CBYou(sys, game))"]), CBT(n"Cyberbane-Crew-ShouldVePaidMeWhatI"),
                                      CBT(n"Cyberbane-Crew-TurnAroundSlowlyThisWasAlways")]), 4.0);
  CBSayVoiced(sys, p, n"enemy_warning");
  if CBMessagesOn() {
    CBCrewText(sys, game, null, CBTf(n"Cyberbane-Crew-TurnedOnYouDidNotSee", [s"\(name)"]));
  }
  CBLog.Info(n"Crew", "A crew member turned on V in a fight.");
}

// One who turned: fights a while, then runs; gone once V cannot see them, a Rival who got away. Put down, they are
// the mercy path's (a Rival's body); dead, the death path's.
func CBCrewTurnedTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, des: ref<DynamicEntitySystem>,
                      player: ref<PlayerPuppet>) -> Void {
  let p = GameInstance.FindEntityByID(game, book.turnedBody) as ScriptedPuppet;
  book.turnedTicks += 1;
  if book.turnedFled {
    CBDeleteTaggedSafe(game, n"CB_Turned", true, true);
  }
  let tagged = des.GetTaggedIDs(n"CB_Turned");   // a local, never a temporary (UI/HubWeb.reds, CBWebPair)
  if !ArrayContains(tagged, book.turnedBody) && !des.IsSpawning(book.turnedBody) {
    CBCrewTurnedGone(sys, game, book, book.turnedFled);
    return;
  }
  if !IsDefined(p) {
    if book.turnedTicks > CBConfig.MyCrewTurnFightTicks() * 2 {
      CBDeleteTaggedSafe(game, n"CB_Turned", true, true);
    }
    return;
  }
  if !book.turnedFled && CBIsDown(p) && book.turnedTicks > CBConfig.MyCrewTurnFightTicks() * 2 {
    book.turnedFled = true;   // put down and left: cleared once V cannot see them (the mercy path has had its chance)
  }
  if book.turnedFled || !CBStillStanding(p) || !CBNpcSafe(sys, p) {
    return;
  }
  let far = Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition()) > CBConfig.MyCrewLeaveDistance();
  // Gone the moment the story wants the stage, as every hunter is (Core/StoryHold.reds): nobody hostile of ours stays.
  if book.turnedTicks >= CBConfig.MyCrewTurnFightTicks() || far || sys.GetStoryHold() != CBStoryNone() {
    book.turnedFled = true;
    CBOrderFlee(game, p);
  }
}

// `died`: their death is a Rival's, and the death path still has to find them by their body (CBFindRivalByBody), so
// the body is left on the Rival for it; CBCloseRivalEncounter forgets it.
func CBCrewTurnedGone(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, fled: Bool, opt died: Bool) -> Void {
  let r = book.turnedRival > 0 ? sys.FindRivalById(book.turnedRival) : null;
  let none: EntityID;
  if IsDefined(r) && !died && Equals(r.spawnedEntityId, book.turnedBody) {
    r.spawnedEntityId = none;
    if fled && CBMessagesOn() && r.state != EnumInt(ECBRivalState.Slain) {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-Crew-GotAwayTheyKnowYourHaunts", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]), n"");
    }
  }
  book.turnedBody = none;
  book.turnedRival = 0;
  book.turnedTicks = 0;
  book.turnedFled = false;
}

// A Betrayer of this gang is out there: the gang knows where V spends time (Spawn/Hunt.reds, CBHuntBegin).
public func CBBetrayerKnowsHaunts(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  if !IsDefined(sys) || Equals(faction, n"") {
    return false;
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, faction) && r.source == EnumInt(ECBRivalSource.Betrayer)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      return true;
    }
  }
  return false;
}

// ---- Death ([C8]) ---------------------------------------------------------------------------------------------------

@addField(ScriptedPuppet)
public let cbKilledCrew: Int32;   // one of V's crew died by this one's hand: the member's id

// From the death path (Signals/CombatSignals.reds). True when it was one of V's own, handled here in full; false for
// one who turned, whose death goes on as anybody's (a Rival's, if they became one).
public func CBCrewBodyDied(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Bool {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(puppet) {
    return false;
  }
  let id = puppet.GetEntityID();
  if CBCrewSparBodyDied(sys, game, id) {
    return true;   // a round that went too far: hurt, never a death or a kill
  }
  if Equals(book.turnedBody, id) {
    CBCrewTurnedGone(sys, game, book, false, true);
    if puppet.cbDamagedByPlayer {
      CBFileLog(sys, n"TraitorDown", CBGameSeconds(game), CBEventDistrict(sys, game), CBClassifyFaction(puppet), 0.0);
    }
    return false;
  }
  let k = book.OutIndexOf(id);
  if k < 0 {
    return true;
  }
  let m = book.Find(book.outMember[k]);
  book.DropOut(k);
  if !IsDefined(m) {
    return true;
  }
  let now = CBGameSeconds(game);
  let district = CBEventDistrict(sys, game);
  let name = CBCrewName(sys, m);
  // Whoever did it is marked: a Rival becomes a lead, anybody else carries it on their body, for the scanner and
  // for the hunt's end, when one who got away comes back with a name (Spawn/Spawner.reds).
  let byRival = 0;
  let killerGang = n"";
  let killer = puppet.cbLastAttacker;
  if IsDefined(killer) && killer.IsAttached() && !killer.IsDead() {
    killer.cbKilledCrew = m.id;
    let kr = CBFindRivalByBody(sys, killer.GetEntityID());
    if IsDefined(kr) {
      byRival = kr.id;
      killerGang = kr.faction;
      CBNoteRivalSeen(sys, game, kr, killer);
    }
    if !IsNameValid(killerGang) && CBNpcSafe(sys, killer) {
      killerGang = CBClassifyFaction(killer);
    }
  }
  // For the memorial, and the crew's own standing (Reactions/CrewBanner.reds): the killers' gang, and the gang that
  // lent somebody who did not come back.
  let bb = CBCrewBannerBook.Get(game);
  if IsDefined(bb) {
    bb.fallCause = CBCrewFellBeside();
    bb.fallGang = killerGang;
  }
  CBCrewStandingShift(game, killerGang, -CBConfig.CrewStandMemberKilled());
  if m.kind == CBCrewLent() {
    CBCrewStandingShift(game, m.faction, -CBConfig.CrewStandMemberKilled());
  }
  // The weapon in their hand fell with them: the one on the ground is it, so nothing is handed back twice.
  let armedFell = CBCrewArmedFell(game, puppet, m);
  book.Remove(m, CBCrewEndFell(), byRival, district, now);
  if armedFell && CBMessagesOn() {
    CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewKit-WeaponWhereTheyFell", [CBCrewFirst(sys, m)]), true);
  }
  CBMapRemember(sys, game, CBMemCrewFell(), puppet.GetWorldPosition(), m.id, m.faction, n"", n"", false);   // [85]
  // One who was a Rival dies as one: on the board as fallen, and not by V's hand.
  if m.rival > 0 {
    let was = sys.FindRivalById(m.rival);
    if IsDefined(was) {
      was.state = EnumInt(ECBRivalState.Slain);
      let rb = CBRivalBook.Get(game);
      if IsDefined(rb) {
        rb.SetEnding(was.id, CBEndingNotByV(), now);
      }
    }
  }
  book.AllLoyalty(-CBConfig.MyCrewDiedLoyalty(), CBCrewWhyLost());
  CBFileLog(sys, n"CrewFell", now, district, m.faction, Cast<Float>(m.id));
  // Their old gang hears, and buries them.
  if NotEquals(m.faction, n"") && m.kind != CBCrewLent() {
    CBOweFuneral(game, m.faction);
  }
  if CBMessagesOn() {
    let by = byRival > 0 ? CBRivalDisplayName(sys.GetContent(), sys.FindRivalById(byRival)) : "";
    let wins = m.wins == 1 ? CBT(n"Cyberbane-Crew-OneFightWithYouAndThisIs")
             : (m.wins > 1 ? CBTf(n"Cyberbane-Crew-FightsWithYouAndThisIs", [s"\(m.wins)"]) : "");
    CBCrewText(sys, game, null, StrLen(by) > 0 ? CBTf(n"Cyberbane-Crew-IsDeadDidItYouKnow", [s"\(name)", s"\(by)", s"\(wins)"])
                                               : CBTf(n"Cyberbane-Crew-IsDeadInFindWhoDid", [s"\(name)", s"\(CBHere(sys))", s"\(wins)"]));
    if m.kind == CBCrewLent() && NotEquals(m.faction, n"") {
      CBPhoneFromAlly(game, m.faction, CBTf(n"Cyberbane-Crew-WeLentYouYouWereSupposed", [s"\(CBCrewFirst(sys, m))"]));
    }
  }
  CBLog.Info(n"Crew", "One of V's crew was killed.");
  return true;
}

// The one who killed a crew member, killed by V (from the death path), or a Rival who did it, slain.
public func CBCrewAvenged(sys: ref<CyberbaneSystem>, game: GameInstance, memberId: Int32) -> Void {
  let book = CBCrewBook.Get(game);
  let p = IsDefined(book) ? book.FindPast(memberId) : null;
  if !IsDefined(p) || p.end != CBCrewEndFell() || p.by < 0 {
    return;
  }
  p.by = -1;   // answered
  CBFileLog(sys, n"CrewAvenged", CBGameSeconds(game), CBEventDistrict(sys, game), n"", Cast<Float>(memberId));
  if CBMessagesOn() {
    CBCrewText(sys, game, null, CBTf(n"Cyberbane-Crew-ThatWasForRestEasy", [s"\(CBCrewPastName(sys, p))"]));
  }
}

public func CBCrewRivalFell(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, byV: Bool) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !byV {
    return;
  }
  let p = book.PastKilledBy(r.id);
  if IsDefined(p) {
    CBCrewAvenged(sys, game, p.id);
  }
}

// The hunt gave up and somebody who killed one of V's own is still standing: they are the one who comes back with a
// name (Spawn/Spawner.reds, CBCrewSurvivorTakesItPersonally). True when one did.
public func CBCrewKillerGotAway(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, faction: CName) -> Bool {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(des) || !CBRivalsOn() {
    return false;
  }
  for id in des.GetTaggedIDs(n"CB_Squad") {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if !des.IsTagged(id, n"CB_Bounty") && CBStillStanding(p) && CBNpcSafe(sys, p) && p.cbKilledCrew > 0 {
      let nr = CBCreateRival(sys, game, faction, p.GetRecordID(), n"", ECBRivalSource.Hunter, CBEventDistrict(sys, game),
                             CBGameSeconds(game), true);
      if IsDefined(nr) {
        CBNoteRivalSeen(sys, game, nr, p);
        let past = book.FindPast(p.cbKilledCrew);
        if IsDefined(past) && past.by == 0 {
          past.by = nr.id;
        }
        if CBMessagesOn() {
          CBCrewText(sys, game, null, CBTf(n"Cyberbane-Crew-TheOneWhoKilledGotAway", [s"\(CBCrewPastName(sys, past))", s"\(CBRivalDisplayName(sys.GetContent(), nr))"]));
        }
      }
      return true;
    }
  }
  return false;
}

// ---- The day: loyalty drifts, the cut, the restless, a lent soldier recalled ([C7] [C9]) ---------------------------

public func CBCrewDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || !CBMyCrewOn() {
    return;
  }
  let now = CBGameSeconds(game);
  let day = CBGameDay(game) + 1;
  if book.DayDone() == day {
    return;
  }
  let firstDay = book.DayDone() == 0;
  book.SetDayDone(day);
  CBCrewMercOffer(sys, game, book, now);
  if book.Count() == 0 || firstDay {
    return;
  }
  let score = sys.GetScore();
  let cutUnpaid = book.CutOwed() > 0;
  let i = book.Count() - 1;
  while i >= 0 {
    let m = book.At(i);
    i -= 1;
    if IsDefined(m) {
      // Fear wears off.
      if m.kind == CBCrewFrightened() {
        CBCrewLoyalty(m, -CBConfig.MyCrewFearDrift(), CBCrewWhyFear());
      }
      // V hurting the gang they came from.
      let kills = CBCrewKillsOf(sys, m.faction);
      if kills > m.killsSeen {
        CBCrewLoyalty(m, -Min(10, (kills - m.killsSeen) * CBConfig.MyCrewOldGangHurt()), CBCrewWhyOldGang());
      }
      m.killsSeen = kills;
      // The cut, unpaid.
      if cutUnpaid {
        CBCrewLoyalty(m, -(m.kind == CBCrewPaid() ? CBConfig.MyCrewUnpaidDriftPaid() : CBConfig.MyCrewUnpaidDrift()), CBCrewWhyUnpaid());
      }
      // A lent soldier goes home the day their gang stops liking V.
      let posture = IsDefined(score) && NotEquals(m.faction, n"") ? score.GetPosture(m.faction) : ECBPosture.Neutral;
      let recalled = m.kind == CBCrewLent() && !Equals(posture, ECBPosture.Allied) && !Equals(posture, ECBPosture.Friendly);
      // Frightened at nothing left, or loyalty gone entirely: they walk.
      let walks = recalled || m.loyalty <= 0 && !book.IsOut(m.id);
      if walks && !book.IsOut(m.id) {
        let name = CBCrewName(sys, m);
        book.Remove(m, CBCrewEndWalked(), 0, CBEventDistrict(sys, game), now);
        CBFileLog(sys, n"CrewWalked", now, CBEventDistrict(sys, game), m.faction, Cast<Float>(m.id));
        if CBMessagesOn() {
          if recalled {
            CBPhoneFromGang(game, m.faction, CBTf(n"Cyberbane-Crew-WeWantBackYouKnowWhy", [s"\(CBCrewFirst(sys, m))"]));
          } else {
            CBPhoneSendTinted(game, name, CBT(n"Cyberbane-Crew-IMDoneDonTCall"), CBHudAmber());
          }
        }
      } else {
        CBCrewRestlessText(sys, game, m, day);
      }
    }
  }
  // The week's cut falls due.
  if CBCrewCutMult() > 0.0 && book.CutDueAt() > 0.0 && now >= book.CutDueAt() && book.Count() > 0 {
    book.SetCutDueAt(now + 7.0 * CBConfig.SecondsPerDay());
    let cut = CBCrewWeeklyCut(book);
    book.SetCutOwed(book.CutOwed() + cut);
    if CBMessagesOn() && cut > 0 {
      CBCrewText(sys, game, null, CBLineOf([CBTf(n"Cyberbane-Crew-WeekSUpTheCutS", [s"\(book.CutOwed())"]),
                                           CBTf(n"Cyberbane-Crew-PaydayEbForTheCrew", [s"\(CBYou(sys, game))", s"\(book.CutOwed())"])]));
    }
  }
}

// One text when somebody starts to come loose, every other day at most, about what is eating them.
func CBCrewRestlessText(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, day: Int32) -> Void {
  if !CBMessagesOn() || !CBCrewRestless(m) || day - m.warnedDay < 2 {
    return;
  }
  m.warnedDay = day;
  let line = CBT(n"Cyberbane-Crew-BeenThinkingAboutWhetherThisIs");
  if m.lastWhy == CBCrewWhyUnpaid() { line = CBT(n"Cyberbane-Crew-YouStillOweMeForThe"); }
  if m.lastWhy == CBCrewWhyLeftLying() { line = CBT(n"Cyberbane-Crew-StillThinkingAboutYouLeavingMe"); }
  if m.lastWhy == CBCrewWhyLost() { line = CBT(n"Cyberbane-Crew-WeLostOneCouldVeBeen"); }
  if m.lastWhy == CBCrewWhyOldGang() { line = CBTf(n"Cyberbane-Crew-YouKeepPuttingDownSomeOf", [s"\(CBFactionLabel(m.faction))"]); }
  if m.lastWhy == CBCrewWhyFear() { line = CBT(n"Cyberbane-Crew-NotAsScaredOfYouAs"); }
  CBCrewText(sys, game, m, line);
}

public func CBCrewWeeklyCut(book: ref<CBCrewBook>) -> Int32 {
  let total = 0;
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) {
      let base = m.kind == CBCrewPaid() ? CBConfig.MyCrewCutPaid() : CBConfig.MyCrewCutBase();
      total += base + CBConfig.MyCrewCutPerRank() * (CBCrewRankOf(GetGameInstance(), m) - 1);
    }
  }
  return RoundF(Cast<Float>(total) * CBCrewCutMult());
}

// V pays what the crew is owed: a fair cut.
public func CBCrewPayCut(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || book.CutOwed() <= 0 {
    return CBT(n"Cyberbane-Crew-NobodySOwedAnything");
  }
  let owed = book.CutOwed();
  if !CBTalkTakeMoney(game, GetPlayer(game), owed) {
    return CBTf(n"Cyberbane-Crew-YouDonTHaveEb", [s"\(owed)"]);
  }
  book.SetCutOwed(0);
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    CBCrewLoyalty(m, m.kind == CBCrewPaid() ? CBConfig.MyCrewFairCutPaid() : CBConfig.MyCrewFairCut(), CBCrewWhyPaid());
  }
  CBFileLog(sys, n"CrewPaid", CBGameSeconds(game), CBEventDistrict(sys, game), n"", Cast<Float>(owed));
  if CBMessagesOn() {
    CBCrewText(sys, game, null, CBLineOf([CBT(n"Cyberbane-Crew-CutSInEverybodySHappy"), CBT(n"Cyberbane-Crew-PaidInFullThatSHow")]));
  }
  return "";
}

// V lets somebody go: no hard feelings, mostly.
public func CBCrewLetGo(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32) -> Void {
  let book = CBCrewBook.Get(game);
  let m = IsDefined(book) ? book.Find(id) : null;
  if !IsDefined(m) || book.IsOut(id) {
    return;
  }
  let first = CBCrewFirst(sys, m);
  let restless = CBCrewRestless(m);
  book.Remove(m, CBCrewEndLetGo(), 0, CBEventDistrict(sys, game), CBGameSeconds(game));
  CBFileLog(sys, n"CrewLetGo", CBGameSeconds(game), CBEventDistrict(sys, game), m.faction, Cast<Float>(m.id));
  if m.kind == CBCrewOwed() && m.rival > 0 {
    let r = sys.FindRivalById(m.rival);
    if IsDefined(r) {
      r.state = EnumInt(ECBRivalState.Debtor);   // still owes V; just not on the crew
    }
  }
  if CBMessagesOn() {
    CBCrewText(sys, game, null, restless ? CBTf(n"Cyberbane-Crew-TookItWellTooWellIf", [s"\(first)"])
                                         : CBTf(n"Cyberbane-Crew-SaysThanksForTheWorkDoor", [s"\(first)"]));
  }
}

// [C9] A crew of three or more is an answer the gangs that hate V give back: one more in every crew they send.
public func CBCrewAnswerSize(sys: ref<CyberbaneSystem>, faction: CName) -> Int32 {
  let book = CBCrewBook.Get(sys.GetGameInstance());
  let score = sys.GetScore();
  if !CBMyCrewOn() || !IsDefined(book) || !IsDefined(score) || book.Count() < 3 {
    return 0;
  }
  let posture = score.GetPosture(faction);
  return Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) ? 1 : 0;
}

// ---- The phone ([C5] [C9] [C3] [C1]) -------------------------------------------------------------------------------

public func CBPhoneAnswerCrew() -> Int32 = 4
public func CBPhoneAnswerDebtor() -> Int32 = 5
public func CBPhoneAnswerHire() -> Int32 = 6

public func CBPhoneRowCallCrew() -> Int32 = 20
public func CBPhoneRowPayCut() -> Int32 = 21
public func CBPhoneRowRecruit() -> Int32 = 22
public func CBPhoneRowHire() -> Int32 = 23
public func CBPhoneRowHireHaggle() -> Int32 = 24
public func CBPhoneRowHirePass() -> Int32 = 25
public func CBPhoneRowSendHome() -> Int32 = 26
// One of them in their own thread (Reactions/CrewNames.reds): come to V on their own, or head home on their own.
public func CBPhoneAnswerCrewMember() -> Int32 = 7
public func CBPhoneRowComeToMe() -> Int32 = 27
public func CBPhoneRowHeadHome() -> Int32 = 28

// A Debtor's thread, by the name it carries, while there is room on the crew.
public func CBPhoneThreadDebtor(sys: ref<CyberbaneSystem>, store: ref<CBPhone>, thread: Int32) -> ref<CBRival> {
  let book = CBCrewBook.Get(sys.GetGameInstance());
  let name = store.ThreadName(thread);
  if !CBMyCrewOn() || !IsDefined(book) || !book.HasRoom() || StrLen(name) == 0 {
    return null;
  }
  let content = sys.GetContent();
  for r in sys.GetRivals() {
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Debtor) && !IsDefined(book.FindRival(r.id))
       && Equals(CBRivalDisplayName(content, r), name) {
      return r;
    }
  }
  return null;
}

// What a thread can be answered about, for the crew: its own thread, a Debtor's, or a broker's solo on offer.
public func CBCrewPhoneKind(sys: ref<CyberbaneSystem>, game: GameInstance, store: ref<CBPhone>, thread: Int32) -> Int32 {
  let book = CBCrewBook.Get(game);
  let name = store.ThreadName(thread);
  if !CBMyCrewOn() || !IsDefined(book) || StrLen(name) == 0 {
    return CBPhoneAnswerNone();
  }
  // The crew's group chat, under the crew's name once it has one.
  if Equals(name, CBCrewGroupSender(game)) || Equals(name, CBCrewSender()) {
    let rows = CBCrewPhoneRows(sys, game, CBPhoneAnswerCrew());
    if ArraySize(rows) > 0 {
      return CBPhoneAnswerCrew();
    }
  }
  // One of them in their own thread.
  let member = CBCrewMemberOfThread(sys, book, name);
  if IsDefined(member) {
    let memberRows = CBCrewPhoneRows(sys, game, CBPhoneAnswerCrewMember(), member.id);
    if ArraySize(memberRows) > 0 {
      return CBPhoneAnswerCrewMember();
    }
  }
  if book.offerSeed != 0 && book.offerUntil >= CBGameSeconds(game) && Equals(name, book.offerSender) && book.HasRoom() {
    return CBPhoneAnswerHire();
  }
  // Asked once per thing they say (UI/PhoneMessages.reds, ThreadAwaitsAnswer): "Work for me" stayed under every one of
  // their texts, so V could ask until the dice said yes.
  if IsDefined(CBPhoneThreadDebtor(sys, store, thread)) && store.ThreadAwaitsAnswer(thread) {
    return CBPhoneAnswerDebtor();
  }
  return CBPhoneAnswerNone();
}

// `member`: whose own thread it is, for CBPhoneAnswerCrewMember.
public func CBCrewPhoneRows(sys: ref<CyberbaneSystem>, game: GameInstance, kind: Int32, opt member: Int32) -> array<Int32> {
  let out: array<Int32>;
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) {
    return out;
  }
  // Just them: come to V beside whoever is out, or go home while the rest stay. Offered whenever it can be asked; pressed
  // when it cannot, they text back why (CBCrewCall), as the crew's own button does.
  if kind == CBPhoneAnswerCrewMember() && member > 0 && IsDefined(book.Find(member)) {
    if book.IsOut(member) {
      if !book.leaving {
        ArrayPush(out, CBPhoneRowHeadHome());
      }
    } else {
      if !book.leaving {
        ArrayPush(out, CBPhoneRowComeToMe());
      }
    }
  }
  if kind == CBPhoneAnswerCrew() {
    // Always offered while there is a crew: hidden whenever they could not come, the thread had nothing to press and no
    // word why. Pressed then, the crew texts back the reason (CBCrewPhoneReply).
    if book.Count() > 0 && book.OutCount() == 0 {
      ArrayPush(out, CBPhoneRowCallCrew());
    }
    // Out with V: sent home from the thread too.
    if book.OutCount() > 0 && !book.leaving {
      ArrayPush(out, CBPhoneRowSendHome());
    }
    if book.CutOwed() > 0 {
      ArrayPush(out, CBPhoneRowPayCut());
    }
  }
  if kind == CBPhoneAnswerDebtor() {
    ArrayPush(out, CBPhoneRowRecruit());
  }
  if kind == CBPhoneAnswerHire() {
    ArrayPush(out, CBPhoneRowHire());
    if !book.offerHaggled && CBTalkHaggleOn() {
      ArrayPush(out, CBPhoneRowHireHaggle());
    }
    ArrayPush(out, CBPhoneRowHirePass());
  }
  return out;
}

public func CBCrewPhoneRowText(sys: ref<CyberbaneSystem>, game: GameInstance, row: Int32) -> String {
  let book = CBCrewBook.Get(game);
  if row == CBPhoneRowCallCrew() { return CBT(n"Cyberbane-Crew-NeedYouNow"); }
  if row == CBPhoneRowSendHome() { return CBT(n"Cyberbane-Crew-GoHomeIVeGotThis"); }
  if row == CBPhoneRowComeToMe() { return CBT(n"Cyberbane-Crew-ComeToMe"); }
  if row == CBPhoneRowHeadHome() { return CBT(n"Cyberbane-Crew-HeadHomeIGotThis"); }
  if row == CBPhoneRowPayCut() { return IsDefined(book) ? CBTf(n"Cyberbane-Crew-HereSTheCutEb", [s"\(book.CutOwed())"]) : CBT(n"Cyberbane-Crew-HereSTheCut"); }
  if row == CBPhoneRowRecruit() { return CBT(n"Cyberbane-Crew-WorkForMe"); }
  if row == CBPhoneRowHire() { return IsDefined(book) ? CBTf(n"Cyberbane-Crew-DealEb", [s"\(book.offerPrice)"]) : CBT(n"Cyberbane-Crew-Deal"); }
  if row == CBPhoneRowHireHaggle() { return CBT(n"Cyberbane-Crew-TooMuch"); }
  if row == CBPhoneRowHirePass() { return CBT(n"Cyberbane-Crew-NotNow"); }
  return "";
}

public func CBCrewPhoneReply(sys: ref<CyberbaneSystem>, game: GameInstance, store: ref<CBPhone>, thread: Int32, row: Int32) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  store.Reply(game, thread, CBCrewPhoneRowText(sys, game, row));
  // The call and the send-home are only asked for here, as on the Hub: the next settled tick back in the world carries
  // them out and texts back why if it cannot (CBCrewServiceHub).
  if row == CBPhoneRowCallCrew() {
    book.reqCall = true;
    return;
  }
  if row == CBPhoneRowSendHome() {
    book.reqHome = true;
    return;
  }
  // Just them, from their own thread: asked here, carried out on the next settled tick (CBCrewServiceHub).
  if row == CBPhoneRowComeToMe() || row == CBPhoneRowHeadHome() {
    let one = CBCrewMemberOfThread(sys, book, store.ThreadName(thread));
    if IsDefined(one) {
      if row == CBPhoneRowComeToMe() {
        book.reqCallOne = one.id;
      } else {
        book.reqHomeOne = one.id;
      }
    }
    return;
  }
  if row == CBPhoneRowPayCut() {
    let paid = CBCrewPayCut(sys, game);
    if StrLen(paid) > 0 {
      CBCrewText(sys, game, null, paid);
    }
    return;
  }
  if row == CBPhoneRowRecruit() {
    let r = CBPhoneThreadDebtor(sys, store, thread);
    if IsDefined(r) {
      CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), CBCrewRecruitDebtor(sys, game, r), CBHudCyan());
    }
    return;
  }
  let sender = book.offerSender;
  if row == CBPhoneRowHire() {
    let hired = CBCrewHire(sys, game);
    if StrLen(hired) > 0 {
      CBPhoneSendTinted(game, sender, hired, CBHudCyan());
    } else {
      CBPhoneSendTinted(game, sender, CBT(n"Cyberbane-Crew-DoneTheyLlBeOnYour"), CBHudCyan());
    }
    return;
  }
  if row == CBPhoneRowHireHaggle() {
    book.offerHaggled = true;
    if RandF() < 0.5 {
      book.offerPrice = RoundF(Cast<Float>(book.offerPrice) * 0.8);
      CBPhoneSendTinted(game, sender, CBTf(n"Cyberbane-Crew-FineEbAndTheyReYours", [s"\(book.offerPrice)"]), CBHudCyan());
    } else {
      CBPhoneSendTinted(game, sender, CBTf(n"Cyberbane-Crew-GoodPeopleCostMoneyEb", [s"\(book.offerPrice)"]), CBHudCyan());
    }
    return;
  }
  if row == CBPhoneRowHirePass() {
    book.offerSeed = 0;
    book.offerUntil = 0.0;
    CBPhoneSendTinted(game, sender, CBT(n"Cyberbane-Crew-YourLossSomebodyElseWillTake"), CBHudCyan());
  }
}

// ---- For the Hub ([C10]) -------------------------------------------------------------------------------------------

// One line about a member's state: out, hurt, restless, ready. The state words the Crew page colours by, one function
// each so the colour asks the same word the page shows.
public func CBCrewWordWithYou() -> String {
  return CBT(n"Cyberbane-Crew-WITHYOU");
}

public func CBCrewWordHurt() -> String {
  return CBT(n"Cyberbane-Crew-HURT");
}

public func CBCrewWordResting() -> String {
  return CBT(n"Cyberbane-Crew-RESTING");
}

public func CBCrewWordRestless() -> String {
  return CBT(n"Cyberbane-Crew-RESTLESS");
}

public func CBCrewStateWord(book: ref<CBCrewBook>, m: ref<CBCrewMember>, now: Float) -> String {
  if !IsDefined(m) {
    return "";
  }
  if book.IsOut(m.id) {
    return CBCrewWordWithYou();
  }
  let away = CBCrewAwayWord(GetGameInstance(), m.id, now);
  if StrLen(away) > 0 {
    return away;
  }
  if CBCrewHurt(m, now) {
    let hours = CeilF((m.hurtUntil - now) / CBConfig.SecondsPerHour());
    return CBTf(n"Cyberbane-Crew-H", [CBCrewWordHurt(), s"\(hours)"]);
  }
  if m.calledAt > 0.0 && now - m.calledAt < CBConfig.MyCrewCallSeconds() {
    return CBCrewWordResting();
  }
  if CBCrewRestless(m) {
    return CBCrewWordRestless();
  }
  return CBT(n"Cyberbane-Crew-READY");
}

// The page's summary: how many, what is owed, what is on offer. `owedSaid`: the Hub's roster says what is owed, and
// where to pay it, at the top of the page, where it is not cut off; this line said it again at the bottom.
public func CBCrewSummary(sys: ref<CyberbaneSystem>, game: GameInstance, opt owedSaid: Bool) -> String {
  let book = CBCrewBook.Get(game);
  if !CBMyCrewOn() {
    return CBT(n"Cyberbane-Crew-YourCrewIsSwitchedOffIn");
  }
  if !IsDefined(book) || book.Count() == 0 {
    // Said as the options really are: "ask them where they lie" read as where their loyalty lies, and a gang lends one
    // as soon as it is Friendly, not only when it "would die for you".
    return CBT(n"Cyberbane-Crew-NobodyWorksForYouYetFour");
  }
  let out = CBTf(n"Cyberbane-Crew-OfOnTheRoster", [s"\(book.Count())", s"\(CBConfig.MyCrewRoster())"]) + CBCrewMoneyLine(game);
  if book.CutOwed() > 0 {
    if !owedSaid {
      out += CBTf(n"Cyberbane-Crew-TheyAreOwedEb", [s"\(book.CutOwed())"]);
    }
  } else {
    if book.CutDueAt() > 0.0 && CBCrewCutMult() > 0.0 {
      let days = CeilF((book.CutDueAt() - CBGameSeconds(game)) / CBConfig.SecondsPerDay());
      out += days <= 1 ? CBT(n"Cyberbane-Crew-TheCutIsDueWithinA") : CBTf(n"Cyberbane-Crew-TheCutIsDueInDays", [s"\(days)"]);
    }
  }
  return out;
}

// A History sentence for the crew's own entries ("" for anything else).
public func CBCrewHistoryLine(sys: ref<CyberbaneSystem>, e: ref<CBLogEntry>) -> String {
  if !IsDefined(sys) || !IsDefined(e) {
    return "";
  }
  let k = e.kind;
  if !Equals(k, n"CrewJoined") && !Equals(k, n"CrewCalled") && !Equals(k, n"CrewWon") && !Equals(k, n"CrewFell")
     && !Equals(k, n"CrewTurned") && !Equals(k, n"CrewSold") && !Equals(k, n"CrewWalked") && !Equals(k, n"CrewLetGo")
     && !Equals(k, n"CrewPaid") && !Equals(k, n"CrewAvenged") && !Equals(k, n"TraitorDown") {
    return "";
  }
  let n = RoundF(e.value);
  if Equals(k, n"CrewCalled") { return n == 1 ? CBT(n"Cyberbane-Crew-YouCalledYourCrewAndOne") : CBTf(n"Cyberbane-Crew-YouCalledYourCrewAndCame", [s"\(n)"]); }
  if Equals(k, n"CrewWon") { return CBT(n"Cyberbane-Crew-YourCrewFoughtBesideYouAnd"); }
  if Equals(k, n"CrewPaid") { return CBTf(n"Cyberbane-Crew-YouPaidYourCrewTheirCut", [s"\(n)"]); }
  if Equals(k, n"TraitorDown") { return CBT(n"Cyberbane-Crew-YouPutDownTheOneWho"); }
  let book = CBCrewBook.Get(sys.GetGameInstance());
  let m = IsDefined(book) ? book.Find(n) : null;
  let p = IsDefined(book) ? book.FindPast(n) : null;
  let name = IsDefined(m) ? CBCrewName(sys, m) : (IsDefined(p) ? CBCrewPastName(sys, p) : CBT(n"Cyberbane-Telling-Somebody"));
  if Equals(k, n"CrewJoined") { return CBTf(n"Cyberbane-Crew-JoinedYourCrew", [s"\(name)"]); }
  if Equals(k, n"CrewFell") { return CBTf(n"Cyberbane-Crew-DiedFightingForYou", [s"\(name)"]); }
  if Equals(k, n"CrewTurned") { return CBTf(n"Cyberbane-Crew-TurnedOnYouInTheMiddle", [s"\(name)"]); }
  if Equals(k, n"CrewSold") { return CBTf(n"Cyberbane-Crew-SoldYouOutToThePeople", [s"\(name)"]); }
  if Equals(k, n"CrewWalked") { return CBTf(n"Cyberbane-Crew-WalkedOutOnYourCrew", [s"\(name)"]); }
  if Equals(k, n"CrewLetGo") { return CBTf(n"Cyberbane-Crew-YouLetGo", [s"\(name)"]); }
  return CBTf(n"Cyberbane-Crew-YouAvenged", [s"\(name)"]);
}

// ---- The scanner (UI/ScannerName.reds) ------------------------------------------------------------------------------

// One of V's crew goes by their own name.
public func CBCrewScannerName(npc: ref<NPCPuppet>) -> String {
  let sys = IsDefined(npc) ? CyberbaneSystem.Get(npc.GetGame()) : null;
  let book = IsDefined(npc) ? CBCrewBook.Get(npc.GetGame()) : null;
  if !IsDefined(book) {
    return "";
  }
  let id = npc.GetEntityID();
  let m = book.MemberOfBody(id);
  // The one V is sparring with: a body of their own, not one of the crew out with V.
  let kb = CBCrewKitBook.Get(npc.GetGame());
  if !IsDefined(m) && IsDefined(kb) && kb.sparMember > 0 && Equals(kb.sparBody, id) {
    m = book.Find(kb.sparMember);
  }
  if IsDefined(m) {
    return CBCrewName(sys, m);
  }
  // One who turned on V: by the name V knew them by, now a Rival's.
  if EntityID.IsDefined(book.turnedBody) && Equals(book.turnedBody, id) && book.turnedRival > 0 && IsDefined(sys) {
    let r = sys.FindRivalById(book.turnedRival);
    if IsDefined(r) {
      return CBRivalDisplayName(sys.GetContent(), r);
    }
  }
  return "";
}

// Under the name: one of V's crew and their seat; or whoever killed one of them, marked.
public func CBCrewScannerNote(npc: ref<NPCPuppet>) -> String {
  let sys = IsDefined(npc) ? CyberbaneSystem.Get(npc.GetGame()) : null;
  let book = IsDefined(npc) ? CBCrewBook.Get(npc.GetGame()) : null;
  if !IsDefined(book) || npc.IsDead() {
    return "";
  }
  let m = book.MemberOfBody(npc.GetEntityID());
  if IsDefined(m) {
    // Their rank, and their loyalty in a word.
    return CBTf(n"Cyberbane-Crew-YOURCREW", [StrUpper(CBCrewRankWord(CBCrewRankOf(npc.GetGame(), m))), StrUpper(CBCrewSeatWord(m.seat))])
         + CBTf(n"Cyberbane-Crew-ScanLoyalty", [StrUpper(CBCrewLoyaltyWord(m.loyalty))]);
  }
  let kb = CBCrewKitBook.Get(npc.GetGame());
  if IsDefined(kb) && kb.sparMember > 0 && Equals(kb.sparBody, npc.GetEntityID()) {
    return CBT(n"Cyberbane-Crew-YOURCREWSPARRING");
  }
  if EntityID.IsDefined(book.turnedBody) && Equals(book.turnedBody, npc.GetEntityID()) {
    return CBT(n"Cyberbane-Crew-TURNEDONYOU");
  }
  if npc.cbKilledCrew > 0 {
    let p = book.FindPast(npc.cbKilledCrew);
    if IsDefined(p) {
      return CBTf(n"Cyberbane-Crew-KILLED", [StrUpper(CBCrewFirstName(sys, p.kind, p.faction, p.rival, p.seed))]);
    }
  }
  return "";
}

// ---- What the Hub asked for, carried out back in the game ----------------------------------------------------------

func CBCrewServiceHub(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
  CBCrewKitService(sys, game, book);   // kits, training, wars and the crew's name (Reactions/CrewKit.reds)
  if book.reqPay {
    book.reqPay = false;
    let paid = CBCrewPayCut(sys, game);
    if StrLen(paid) > 0 {
      CBCrewText(sys, game, null, paid);
    }
  }
  if book.reqHire {
    book.reqHire = false;
    let sender = book.offerSender;
    let hired = CBCrewHire(sys, game);
    if StrLen(hired) > 0 && StrLen(sender) > 0 {
      CBPhoneSendTinted(game, sender, hired, CBHudCyan());
    }
  }
  if book.reqLetGo > 0 {
    let id = book.reqLetGo;
    book.reqLetGo = 0;
    CBCrewLetGo(sys, game, id);
  }
  if book.reqCall {
    book.reqCall = false;
    let why = CBCrewCall(sys, game, false);
    if StrLen(why) > 0 {
      CBCrewText(sys, game, null, why);
    }
  }
  // One of them, called or sent home on their own from their orders.
  if book.reqCallOne > 0 {
    let one = book.reqCallOne;
    book.reqCallOne = 0;
    let whyOne = CBCrewCall(sys, game, false, one);
    if StrLen(whyOne) > 0 {
      CBCrewText(sys, game, book.Find(one), whyOne);
    }
  }
  if book.reqHomeOne > 0 {
    let homeOne = book.reqHomeOne;
    book.reqHomeOne = 0;
    CBCrewSendOneHome(sys, game, book, homeOne);
  }
  // Nobody out to send home any more (they went on their own, or are already walking): nothing to carry out.
  if book.reqHome && (book.OutCount() == 0 || book.leaving) {
    book.reqHome = false;
  }
}

// ---- The crew page's words ([C10]) -------------------------------------------------------------------------------

public func CBCrewLoyaltyTint(loyalty: Int32) -> HDRColor {
  if loyalty >= 60 { return CBHudGreen(); }
  if loyalty >= CBConfig.MyCrewRestless() { return CBHudCyan(); }
  if loyalty >= CBConfig.MyCrewBetrayLine() { return CBHudAmber(); }
  return CBHudRed();
}

public func CBCrewLoyaltyWord(loyalty: Int32) -> String {
  if loyalty >= 80 { return CBT(n"Cyberbane-Crew-WouldTakeABulletForYou"); }
  if loyalty >= 60 { return CBT(n"Cyberbane-Crew-Solid"); }
  if loyalty >= CBConfig.MyCrewRestless() { return CBT(n"Cyberbane-Crew-DoingTheJob"); }
  if loyalty >= CBConfig.MyCrewBetrayLine() { return CBT(n"Cyberbane-Crew-Restless"); }
  return CBT(n"Cyberbane-Crew-CloseToWalkingOrWorse");
}

// What is eating somebody, from what last cost them.
public func CBCrewWorry(m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) { return ""; }
  if m.lastWhy == CBCrewWhyUnpaid() { return CBT(n"Cyberbane-Crew-TheCutYouOweThem"); }
  if m.lastWhy == CBCrewWhyLeftLying() { return CBT(n"Cyberbane-Crew-YouLeftThemLyingInThe"); }
  if m.lastWhy == CBCrewWhyLost() { return CBT(n"Cyberbane-Crew-LosingOneOfTheCrew"); }
  if m.lastWhy == CBCrewWhyOldGang() { return CBTf(n"Cyberbane-Crew-WhatYouKeepDoingTo", [s"\(CBFactionLabel(m.faction))"]); }
  if m.lastWhy == CBCrewWhyFear() { return CBT(n"Cyberbane-Crew-TheyAreLessAfraidOfYou"); }
  return "";
}

// How somebody left, in a word for the crew picture, and the tint it is drawn in.
public func CBCrewEndWord(end: Int32) -> String {
  if end == CBCrewEndFell() { return CBT(n"Cyberbane-Crew-FELL"); }
  if end == CBCrewEndLetGo() { return CBT(n"Cyberbane-Crew-LETGO"); }
  if end == CBCrewEndWalked() { return CBT(n"Cyberbane-Crew-WALKED"); }
  if end == CBCrewEndSold() { return CBT(n"Cyberbane-Crew-SOLDYOUOUT"); }
  return CBT(n"Cyberbane-Crew-TURNEDONYOU");
}

public func CBCrewEndTint(end: Int32) -> HDRColor {
  if end == CBCrewEndSold() || end == CBCrewEndTurned() { return CBHudRed(); }
  if end == CBCrewEndFell() { return CBHudDim(); }
  return CBHudGrey();
}

// The picked member's file, or the solo on offer.
public func CBCrewFile(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>,
                       offer: Bool) -> String {
  let now = CBGameSeconds(game);
  if offer && IsDefined(book) && book.offerSeed != 0 {
    let solo = CBCrewOfferName(sys, game, book);
    let seat = CBCrewSeatWord(CBCrewSeatOf(CBHunterRecord(book.offerSeed, n""), book.offerSeed));
    let bbOffer = CBCrewBannerBook.Get(game);
    let found = IsDefined(bbOffer) && bbOffer.offerWins > 0
      ? CBTf(n"Cyberbane-Crew-YourRecruiterFoundThemTheyCome", [s"\(StrLower(CBCrewRankWord(CBCrewRank(bbOffer.offerWins))))"]) : "";
    return CBTf(n"Cyberbane-Crew-ASoloPutForwardAEb", [StrUpper(solo), s"\(book.offerSender)", s"\(seat)", s"\(book.offerPrice)", found]);
  }
  if !IsDefined(m) || !IsDefined(book) {
    return "";
  }
  let out = StrUpper(CBCrewName(sys, m)) + "\n";
  let home = NotEquals(m.home, n"") ? CBDistrictLabel(m.home) : CBT(n"Cyberbane-Crew-TheCity");
  let since = CBHudSince(now, m.joinedAt);
  out += CBTf(n"Cyberbane-Crew-ALivesIn", [s"\(CBCrewSeatWord(m.seat))", s"\(CBCrewFromWords(m))", s"\(home)", (StrLen(since) > 0 ? CBTf(n"Cyberbane-Crew-WithYou", [s"\(since)"]) : ".")]);
  let rank = CBCrewRankOf(game, m);
  let wins = m.wins == 0 ? CBT(n"Cyberbane-Crew-NoFightsWonWithYouYet") : (m.wins == 1 ? CBT(n"Cyberbane-Crew-OneFightWonWithYou") : CBTf(n"Cyberbane-Crew-FightsWonWithYou", [s"\(m.wins)"]));
  let scars = m.scars == 0 ? "" : (m.scars == 1 ? CBT(n"Cyberbane-Crew-OneScarToShowForIt") : CBTf(n"Cyberbane-Crew-ScarsToShowForIt", [s"\(m.scars)"]));
  out += CBTf(n"Cyberbane-Crew-RankOf6", [wins, scars, s"\(CBCrewRankWord(rank))", s"\(rank)", (rank >= 3 ? CBTf(n"Cyberbane-Crew-KnownAs", [s"\(CBCrewNickname(m.seat, m.seed))"]) : "")]);
  // How far to the next rank.
  let next = CBCrewNextRankLine(game, m);
  if StrLen(next) > 0 {
    out += next + "\n";
  }
  out += CBTf(n"Cyberbane-Crew-LoyaltyOf100", [s"\(m.loyalty)", s"\(CBCrewLoyaltyWord(m.loyalty))"]);
  let worry = CBCrewWorry(m);
  if CBCrewRestless(m) && StrLen(worry) > 0 {
    out += CBTf(n"Cyberbane-Crew-WhatSEatingThem", [s"\(worry)"]);
  }
  out += "\n";
  if book.IsOut(m.id) {
    out += book.leaving ? CBT(n"Cyberbane-Crew-HeadingHomeNow") : CBT(n"Cyberbane-Crew-WithYouNow");
  } else {
    if CBCrewHurt(m, now) {
      out += CBTf(n"Cyberbane-Crew-HurtBackOnTheirFeetIn", [s"\(CeilF((m.hurtUntil - now) / CBConfig.SecondsPerHour()))"]);
    } else {
      if m.calledAt > 0.0 && now - m.calledAt < CBConfig.MyCrewCallSeconds() {
        out += CBT(n"Cyberbane-Crew-JustGotBackTheyCanBe");
      }
    }
  }
  if CBCrewBetrayalOn() && m.kind != CBCrewLent() && m.loyalty < CBConfig.MyCrewBetrayLine() {
    out += CBT(n"Cyberbane-Crew-CallThemLikeThisAndThey");
  }
  return out;
}
