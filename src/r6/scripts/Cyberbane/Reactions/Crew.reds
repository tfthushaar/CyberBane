// Cyberbane - A crew of my own (2.5.0)
//
//   [C1] the ones who owe me   a Rival V has spared before, lying at V's feet again, can be told "[Recruit] You owe
//                              me. Work for me." A Debtor can be asked the same by text. The most loyal kind.
//   [C2] the ones I frighten   "[Intimidate] You work for me now", pushed further: somebody frightened enough joins
//                              instead of informing. Fear wears off, and they still have friends where they came from.
//   [C3] the ones I pay        a broker texts a solo's price now and then; V answers in the thread (once haggled) or on
//                              the Hub. Loyal while paid.
//   [C4] the ones my friends lend me   an Allied gang lends one of its people for good; gone the day it stops liking V
//   [C5] calling them          "Need you. Now." on the "My crew" thread and the Hub, while V is hunted, ambushed or in a
//                              fight with Cyberbane's people. Up to three come, out of V's sight, each once an hour.
//                              With Come on their own, the most loyal turn up unasked when an ambush springs.
//   [C6] whose side they're on the game's own follower role (Reactions/Allies.reds, CBMakeFollower). Tagged CB_Own,
//                              which no list of ours names: nothing that re-arms, cuts off, releases or sweeps the
//                              people after V ever reaches them. One order each, home, a minute after the fight or
//                              once V drives off; removed once V cannot see them.
//   [C7] loyalty, and betrayal where they came from sets where loyalty starts; fights won, a fair cut and being stood
//                              over when down raise it; being left lying, a dead friend, an unpaid cut and V hurting
//                              their old gang lower it. Called while it is low, one may sell V to the hunters (the hunt
//                              skips its scout) or come and turn in the fight, and live on as a Rival, the Betrayer.
//   [C8] a life                a name from their gang's own list, a rank from fights won, scars, a nickname at rank 3,
//                              a seat (heavy, shooter, blade, netrunner) kitted with the apex role kit. Killed means
//                              gone: their old gang buries them, and whoever did it is marked for V.
//   [C9] the cut               weekly, asked for by text and paid from the phone or the Hub; unpaid, loyalty falls.
//                              Gangs that hate V send bigger crews against a crew of three or more.
//   [C10] the crew page        on the Hub (UI/Hud.reds), drawn from this book.
//
// The roster is a save book of its own (a new class, so no saved class changes shape). Names, nicknames and lines are
// worked out from what is kept (the gang's name list and a seed, or the Rival they were), never saved as text.

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

public func CBTalkActRecruit() -> Int32 = 58
public func CBTalkActLendOne() -> Int32 = 59

public func CBCrewSender() -> String = "My crew"

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
  public let reqPay: Bool;
  public let reqHire: Bool;
  public let reqLetGo: Int32;

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
    this.reqPay = false;
    this.reqHire = false;
    this.reqLetGo = 0;
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

  // A Rival this book is made of: one on the crew now, or one who was and left it any way but turning. Their name and
  // their story are that Rival's record (CBCrewFullName), so no forget, purge or trim takes it from under them
  // (Core/CyberbaneSystem.reds, RivalKeptByCrew). One who turned is a Betrayer on the board like any Rival (2.5.0).
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
    // Or one the memorial names (2.6.0), whose name is that Rival's record too.
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
    ArrayRemove(this.m_members, m);
    let game = GetGameInstance();
    if end == CBCrewEndFell() {
      CBCrewRememberFallen(game, m, by, district, now);   // the memorial, with what they carried (2.6.0)
    }
    CBCrewBannerLeaves(game, m.id);   // no longer recruiting (2.6.0)
    CBCrewKitLeaves(game, m.id);      // their weapon back to V, their kit forgotten (2.6.0)
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

  public func AddOut(body: EntityID, member: Int32) -> Void {
    ArrayPush(this.outBody, body);
    ArrayPush(this.outMember, member);
    ArrayPush(this.outDown, false);
  }

  public func OutCount() -> Int32 {
    return Min(Min(ArraySize(this.outBody), ArraySize(this.outMember)), ArraySize(this.outDown));
  }

  public func DropOut(i: Int32) -> Void {
    if i < 0 || i >= this.OutCount() {
      return;
    }
    ArrayErase(this.outBody, i);
    ArrayErase(this.outMember, i);
    ArrayErase(this.outDown, i);
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
// playthrough. The book itself is cleared after (CBCrewBook.Clear). (2.5.0)
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
  m.loyalty = Clamp(m.loyalty + delta, 0, 100);
  if delta < 0 && why != CBCrewWhyNone() {
    m.lastWhy = why;
  }
}

public func CBCrewRank(wins: Int32) -> Int32 {
  if wins >= 12 { return 4; }
  if wins >= 7 { return 3; }
  if wins >= 3 { return 2; }
  return 1;
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
  if seat == 0 { return "heavy"; }
  if seat == 2 { return "blade"; }
  if seat == 3 { return "netrunner"; }
  return "shooter";
}

// The nickname they earn at rank 3, from what they do.
public func CBCrewNickname(seat: Int32, seed: Int32) -> String {
  if seat == 0 {
    let a = ["Wall", "Anvil", "Brick", "Bulldozer", "Mountain"];
    return a[CBHashIndex(seed, 61, ArraySize(a))];
  }
  if seat == 2 {
    let b = ["Knives", "Edge", "Whisper", "Paper Cut", "Ribbons"];
    return b[CBHashIndex(seed, 61, ArraySize(b))];
  }
  if seat == 3 {
    let c = ["Ghost", "Static", "Daemon", "Wire", "Blackout"];
    return c[CBHashIndex(seed, 61, ArraySize(c))];
  }
  let d = ["Deadeye", "Trigger", "Ricochet", "Tap-Tap", "Longshot"];
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

// The whole name, with the nickname once they have earned it.
public func CBCrewFullName(sys: ref<CyberbaneSystem>, kind: Int32, faction: CName, rival: Int32, seed: Int32, wins: Int32,
                           seat: Int32) -> String {
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
  let nick = CBCrewRank(wins) >= 3 ? " \"" + CBCrewNickname(seat, seed) + "\"" : "";
  return StrLen(last) > 0 ? first + nick + " " + last : first + nick;
}

public func CBCrewName(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "Somebody";
  }
  return CBCrewFullName(sys, m.kind, m.faction, m.rival, m.seed, m.wins, m.seat);
}

// The name they go by, short enough for a box on the crew picture: first name and nickname once they have one.
public func CBCrewBoxName(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  if m.rival > 0 || CBCrewRank(m.wins) < 3 {
    return CBCrewName(sys, m);
  }
  return CBCrewFirst(sys, m) + " \"" + CBCrewNickname(m.seat, m.seed) + "\"";
}

public func CBCrewFirst(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> String {
  return IsDefined(m) ? CBCrewFirstName(sys, m.kind, m.faction, m.rival, m.seed) : "Somebody";
}

public func CBCrewPastName(sys: ref<CyberbaneSystem>, p: ref<CBCrewPast>) -> String {
  return IsDefined(p) ? CBCrewFullName(sys, p.kind, p.faction, p.rival, p.seed, 0, 0) : "Somebody";
}

// Where they came from, as a clause: "a shooter, once of the Valentinos, who owes you a life".
public func CBCrewFromWords(m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let gang = NotEquals(m.faction, n"") ? CBFactionLabel(m.faction) : "";
  if m.kind == CBCrewOwed() { return StrLen(gang) > 0 ? s"once of \(gang), who owes you a life" : "who owes you a life"; }
  if m.kind == CBCrewFrightened() { return StrLen(gang) > 0 ? s"once of \(gang), scared into working for you" : "scared into working for you"; }
  if m.kind == CBCrewLent() { return StrLen(gang) > 0 ? s"on loan from \(gang)" : "on loan"; }
  return "a solo, paid by the week";
}

// The same, short enough for a row or a box.
public func CBCrewFromShort(m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let gang = NotEquals(m.faction, n"") ? CBPhoneGangSender(m.faction) : "";
  // A life, as the long form says (2.5.5): "owes you" alone reads as money.
  if m.kind == CBCrewOwed() { return StrLen(gang) > 0 ? s"owes you a life, ex-\(gang)" : "owes you a life"; }
  if m.kind == CBCrewFrightened() { return StrLen(gang) > 0 ? s"scared, ex-\(gang)" : "scared into it"; }
  if m.kind == CBCrewLent() { return StrLen(gang) > 0 ? s"on loan, \(gang)" : "on loan"; }
  return "paid solo";
}

public func CBCrewRestless(m: ref<CBCrewMember>) -> Bool {
  return IsDefined(m) && m.loyalty < CBConfig.MyCrewRestless();
}

public func CBCrewHurt(m: ref<CBCrewMember>, now: Float) -> Bool {
  return IsDefined(m) && m.hurtUntil > now;
}

public func CBCrewReady(book: ref<CBCrewBook>, m: ref<CBCrewMember>, now: Float) -> Bool {
  return IsDefined(m) && !CBCrewHurt(m, now) && !book.IsOut(m.id) && !CBCrewAway(GetGameInstance(), m.id, now)
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

// The crew's thread on the phone: every text from one of them, signed with their first name.
public func CBCrewText(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, line: String) -> Void {
  if StrLen(line) == 0 {
    return;
  }
  CBPhoneSendTinted(game, CBCrewSender(), IsDefined(m) ? CBCrewFirst(sys, m) + ": " + line : line, CBCrewColour(game));
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
  // The gang they came from thinks better or worse of the crew for it (Reactions/CrewBanner.reds, 2.6.0): one lent is
  // trust, one scared into it or a Rival of theirs who owes V is one of theirs taken.
  if m.kind == CBCrewLent() { CBCrewStandingShift(game, m.faction, CBConfig.CrewStandLent()); }
  if m.kind == CBCrewFrightened() { CBCrewStandingShift(game, m.faction, -CBConfig.CrewStandFrightened()); }
  if m.kind == CBCrewOwed() { CBCrewStandingShift(game, m.faction, -CBConfig.CrewStandOwed()); }
  CBFileLog(sys, n"CrewJoined", now, CBEventDistrict(sys, game), m.faction, Cast<Float>(m.id));
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
  let l = CBTalkMakeLine("[Recruit] You owe me. Work for me.", CBTalkActRecruit(), t"ChoiceCaptionParts.HandshakeIcon");
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
    return CBTalkSay(CBLineOf([s"Work for you? I'd rather bleed out right here, \(you).",
                               "You let me live. That doesn't make me yours.",
                               s"Twice you had me, \(you). Twice. And now you want me fetching your coffee? No."]), n"");
  }
  e.recruited = true;
  return CBTalkSay(CBLineOf([s"...Yeah. Yeah, I owe you. Twice over. Call and I'll come, \(you).",
                             "Guess my old crew can find a new number two. I'm with you.",
                             s"You could've ended me in \(CBHere(sys)). You didn't. That buys you my gun."]), n"");
}

// From the mercy path, once they are let go: the Rival leaves the board and joins the roster.
public func CBCrewTakeRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, e: ref<CBEscapee>) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !book.HasRoom() || IsDefined(book.FindRival(r.id)) {
    return;
  }
  let now = CBGameSeconds(game);
  r.state = EnumInt(ECBRivalState.Debtor);   // out of the fight for good, and out of their chair
  CBHierarchyFill(sys, r.faction);
  CBCloseRivalEncounter(sys, game, r, IsDefined(e) ? e.puppet : null);
  let rb = CBRivalBook.Get(game);
  if IsDefined(rb) {
    rb.SetEnding(r.id, CBEndingRetired(), now);
  }
  let m = book.Add(CBCrewOwed(), r.recordID, r.appearance, r.faction, r.id, CBConfig.MyCrewLoyaltyOwed(),
                   CBEventDistrict(sys, game), now, CBCrewKillsOf(sys, r.faction));
  CBCrewJoined(sys, game, m, CBLineOf([s"It's me. Saved your number. Whatever you need, I'm there.",
                                      s"Told my old crew I'm done. They took it about as well as you'd think. Call me.",
                                      s"Patched up, armed, bored. Say the word."]));
  if CBMessagesOn() {
    CBHearsayFromStreet(game, s"\(CBRivalDisplayName(sys.GetContent(), r)) walked out on \(CBFactionLabel(r.faction)) and runs with you now. Nobody saw that coming.", n"");
  }
}

// A Debtor's own thread: the same question, by text.
public func CBCrewRecruitDebtor(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !book.HasRoom() || IsDefined(book.FindRival(r.id)) {
    return "Can't. Not now.";
  }
  if !CBCrewRivalAccepts(r) {
    return CBLineOf(["I owe you tips. Not my life. Let's keep it that way.", "I'm out of that life. Don't ask again."]);
  }
  let now = CBGameSeconds(game);
  let m = book.Add(CBCrewOwed(), r.recordID, r.appearance, r.faction, r.id, CBConfig.MyCrewLoyaltyOwed(),
                   NotEquals(r.origin, n"") ? r.origin : CBEventDistrict(sys, game), now, CBCrewKillsOf(sys, r.faction));
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
  CBFileLog(sys, n"CrewJoined", now, CBEventDistrict(sys, game), m.faction, Cast<Float>(m.id));
  sys.AddRenownPoints(CBConfig.MyCrewRenown());
  if book.CutDueAt() <= 0.0 {
    book.SetCutDueAt(now + 7.0 * CBConfig.SecondsPerDay());
  }
  return CBLineOf([s"Funny. I was going to ask you the same thing. I'm in.", "Paying a debt with my trigger finger. Fair. I'm in."]);
}

// [C2] From the turn (Reactions/StreetIntel.reds, CBIntelTurn): somebody frightened enough joins instead.
// Frightened: afraid of V when V walked up, or leaned on until they folded (cbHoldState 1, a successful Intimidate).
// Until 2.5.0 only the first counted, and a ganger who had just folded under Intimidate read as wary, not afraid, so
// the one way to frighten somebody into the crew almost never could (2.5.0).
public func CBCrewFrightenedJoins(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let book = CBCrewBook.Get(game);
  if !CBCrewTakesFrightened(game) || !IsDefined(t) || !IsDefined(t.npc) || Equals(t.faction, n"") || t.cop
     || !(t.mood == CBTalkAfraid() || t.npc.cbHoldState == 1) {
    return null;
  }
  // Somebody already afraid of V, leaned on until they fold, always says yes (2.5.0): a roll of 30 to 60% on top of the
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
  t.npc.cbHoldState = 1;
  CBCrewJoined(sys, game, m, s"It's me. From \(CBHere(sys)). I don't want trouble with you. Ever. Tell me where to be.");
  CBLog.Info(n"Crew", s"A frightened ganger of \(NameToString(t.faction)) joined V's crew.");
  return CBTalkSay(CBLineOf([s"Okay. Okay! I'm yours. Just... don't look at me like that, \(CBYou(sys, game)).",
                             s"Work for you? Better than the other thing. Fine. \(CBCapFirst(CBFactionLabel(t.faction))) never paid me anyway.",
                             "Whatever you say. I'll keep my phone on. Please."]), n"");
}

// The crew is on and has room for one more (2.5.0): asked before a frightened ganger is offered the chance.
public func CBCrewTakesFrightened(game: GameInstance) -> Bool {
  let book = CBCrewBook.Get(game);
  return CBMyCrewOn() && IsDefined(book) && book.HasRoom() && CBCrewFrightJoin() > 0.0;
}

// [C4] An Allied gang lends one of its people, for good.
public func CBCrewLendLine(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkLine> {
  let book = CBCrewBook.Get(game);
  let score = sys.GetScore();
  // Friendly or Allied (2.5.0): Allied alone was a gang that would die for V, rarer than "a gang that likes you".
  let posture = IsDefined(score) && IsDefined(t) ? score.GetPosture(t.faction) : ECBPosture.Neutral;
  if !CBMyCrewOn() || !IsDefined(book) || !IsDefined(score) || !book.HasRoom() || !IsDefined(t) || t.cop
     || Equals(t.faction, n"") || !(Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly))
     || CBCrewHasLentFrom(book, t.faction) {
    return null;
  }
  return CBTalkMakeLine("[Lend] One of yours on my crew. For good.", CBTalkActLendOne(), t"ChoiceCaptionParts.ReinforcementIcon");
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
    return CBTalkSay("Nobody to spare right now.", n"");
  }
  // Who they send: one of their seats as V has seen them fight, else one of their own fighters from the roster, else
  // the one V is talking to. Their seats are only ever filled from V's kills, so a gang V had never fought, the gangs
  // most likely to like V, always had "nobody to spare" (2.5.0).
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
    return CBTalkSay("Nobody to spare right now.", n"");
  }
  let now = CBGameSeconds(game);
  let m = book.Add(CBCrewLent(), record, n"", t.faction, 0, CBConfig.MyCrewLoyaltyLent(), CBEventDistrict(sys, game), now,
                   CBCrewKillsOf(sys, t.faction));
  if !IsDefined(m) {
    return CBTalkSay("Nobody to spare right now.", n"");
  }
  let name = CBCrewFirst(sys, m);
  CBCrewJoined(sys, game, m, s"\(CBCapFirst(CBFactionLabel(t.faction))) say I'm yours now. As long as you're good with them, I'm good with you.");
  return CBTalkSay(CBLineOf([s"\(name)'s yours. Good \(CBCrewSeatWord(m.seat)). Bring them home when it matters.",
                             s"Take \(name). And remember who your friends are, \(CBYou(sys, game))."]), n"");
}

// [C3] A solo looking for work: a broker texts the price now and then.
func CBCrewMercOffer(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, now: Float) -> Void {
  let score = sys.GetScore();
  // One of the crew put to recruiting (Reactions/CrewBanner.reds, 2.6.0): a solo more often, before V has a name of
  // their own, cheaper, and with fights already behind them.
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
  if Equals(book.offerSender, "Unknown Number") {
    book.offerSender = "Broker";
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
      s"\(CBCrewFirst(sys, recruiter)) from your crew sent me. Found you \(solo): a \(seat), a \(rank) already. \(book.offerPrice)eb up front, then the weekly cut, and that's the friends price.",
      s"Your \(CBCrewFirst(sys, recruiter)) vouches for this one: \(solo), \(seat), fights behind them. \(book.offerPrice)eb to sign. Say the word."]), CBHudCyan());
    CBLog.Info(n"Crew", "A broker offered V a solo the crew's recruiter found.");
    return;
  }
  CBPhoneSendTinted(game, book.offerSender, CBLineOf([
    s"Got a solo looking for steady work: \(solo), a \(seat). Wants \(book.offerPrice)eb up front, then the weekly cut. Interested?",
    s"Word's out you're building a crew. \(solo) wants in: \(seat), clean record, \(book.offerPrice)eb to sign. Say the word."]), CBHudCyan());
  CBLog.Info(n"Crew", "A broker offered V a solo for the crew.");
}

// V takes the solo on: paid now, on the roster.
public func CBCrewHire(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  let now = CBGameSeconds(game);
  if !IsDefined(book) || book.offerSeed == 0 || book.offerUntil < now {
    return "That solo found other work.";
  }
  if !book.HasRoom() {
    return "Your crew's full.";
  }
  if !CBTalkTakeMoney(game, player, book.offerPrice) {
    return s"Come back with \(book.offerPrice)eb.";
  }
  let record = CBHunterRecord(book.offerSeed, n"");
  let bb = CBCrewBannerBook.Get(game);
  let m = book.Add(CBCrewPaid(), record, n"", n"", 0, CBConfig.MyCrewLoyaltyPaid(), CBEventDistrict(sys, game), now, 0);
  if IsDefined(m) {
    m.seed = book.offerSeed;   // the name on the offer is the name they go by
    m.seat = CBCrewSeatOf(record, m.seed);
    // Found by the crew's recruiter (2.6.0): their fights come with them, and somebody vouched for them.
    let found = IsDefined(bb) && bb.offerWins > 0;
    if found {
      m.wins = bb.offerWins;
      m.loyalty = Min(100, m.loyalty + CBConfig.CrewRecruitLoyalty());
    }
    CBCrewJoined(sys, game, m, found ? "Heard good things about this crew. Didn't think I'd get the chance. Call me."
                                     : CBLineOf(["Money's in. I'm yours till it stops. Call when it gets loud.",
                                                 s"Signed and loaded. Where in \(CBHere(sys)) do you want me?"]));
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
  if !player.IsInCombat() {
    return false;
  }
  for tag in CBStreetTags() {
    if CBTagEngagedNear(sys, game, des, player, tag) {
      return true;
    }
  }
  return false;
}

// Can the crew be called right now? "" when yes, otherwise why not, in V's words.
public func CBCrewCallBlocked(sys: ref<CyberbaneSystem>, game: GameInstance, unasked: Bool) -> String {
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  if !CBMyCrewOn() || !IsDefined(book) || !IsDefined(player) {
    return "Nobody's answering.";
  }
  if book.Count() == 0 {
    return "You don't have a crew yet.";
  }
  if book.OutCount() > 0 {
    return book.leaving ? "They're on their way home. Give them a minute." : "They're already with you.";
  }
  if !unasked && !CBCrewTrouble(sys, game) {
    return "Nothing to call them for.";
  }
  if CBArrivalsHeld(sys, game) || !CBWorldStable(game) || IsDefined(player.GetMountedVehicle()) {
    return "They can't get to you here.";
  }
  if CBSpawnRoom(game) - CBConfig.MyCrewSpawnReserve() <= 0 {
    return "Too many people around. They can't get close.";
  }
  if ArraySize(CBCrewReadyOrder(book, CBGameSeconds(game), 0)) == 0 {
    return "Everybody's hurt or just got back.";
  }
  return "";
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

// V calls: up to three come, the most loyal first. Unasked (come on their own), only the most loyal, and nobody
// who would sell V out. Returns "" when somebody is coming, otherwise why not.
public func CBCrewCall(sys: ref<CyberbaneSystem>, game: GameInstance, unasked: Bool) -> String {
  let blocked = CBCrewCallBlocked(sys, game, unasked);
  if StrLen(blocked) > 0 {
    // Said on the Hub, and now in the log too (2.5.7), with what is taking up the room: "I couldn't call my crew" came
    // with nothing to say which of these it was.
    CBLog.Info(n"Crew", s"V's crew was not called: \(blocked) (\(CBSpawnRoomNote(game))).");
    return blocked;
  }
  let book = CBCrewBook.Get(game);
  let now = CBGameSeconds(game);
  let want = Min(CBConfig.MyCrewOut(), CBSpawnRoom(game) - CBConfig.MyCrewSpawnReserve());
  let order = CBCrewReadyOrder(book, now, unasked ? CBConfig.MyCrewOwnLoyalty() : 0);
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
      if TDBID.IsValid(record) && CBSpawnGroup(game, record, m.look, 1, n"CB_Own", CBConfig.MyCrewSpawnDistance(), body) > 0 {
        book.AddOut(body, m.id);
        m.calledAt = now;
        sent += 1;
        if turns {
          book.turnMember = m.id;
          book.turnTicks = 0;
        }
        CBCrewText(sys, game, m, CBCrewOnTheWay(sys, game, m, unasked));
      }
    }
  }
  if sent == 0 {
    if sold == 0 {
      CBLog.Info(n"Crew", s"V's crew was not called: nowhere to put them near V out of sight (\(CBSpawnRoomNote(game))).");
    }
    return sold > 0 ? "" : "Nobody could get to you.";
  }
  book.leaving = false;
  book.quiet = 0;
  book.driving = 0;
  CBFileLog(sys, n"CrewCalled", now, CBEventDistrict(sys, game), n"", Cast<Float>(sent));
  CBLog.Info(n"Crew", s"V's crew is coming: \(sent).");
  return "";
}

func CBCrewOnTheWay(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, unasked: Bool) -> String {
  let here = CBHere(sys);
  let hunters = sys.GetHuntFaction();
  let who = NotEquals(hunters, n"") ? CBFactionLabel(hunters) : "whoever it is";
  if unasked {
    return CBLineOf([s"Heard \(who) were waiting for you. Already on my way.", s"Don't call, don't need to. Coming to \(here)."]);
  }
  if NotEquals(m.faction, n"") && Equals(hunters, m.faction) {
    return CBLineOf([s"\(CBCapFirst(who))? My old crew. ...Fine. I'm coming.", s"I know how \(who) fight. I'll be there."]);
  }
  if m.wins >= 5 {
    return CBLineOf([s"Again? Same as always. Coming to \(here).", s"Keep your head down. I know the way by now."]);
  }
  return CBLineOf([s"On my way to \(here). Hold on.", s"Coming\(CBWhenTail(game)). Don't die before I get there.",
                   s"Got it. \(CBCapFirst(who)) won't know what hit them."]);
}

// From spawn setup (Spawn/Spawner.reds): one of V's own, kitted for their seat, following V.
public func CBSetUpCrewMember(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(puppet) || !IsDefined(player) || !CBStillStanding(puppet) || !IsDefined(book) {
    return;
  }
  // One of them called out for a spar (Reactions/CrewKit.reds, 2.6.0): set up for the round, never as a follower.
  if CBCrewSparSetUp(sys, game, puppet) {
    return;
  }
  let m = book.MemberOfBody(puppet.GetEntityID());
  CBDisarmGodMode(game, puppet);
  if IsDefined(m) {
    CBKitApexSeat(puppet, m.seat);
    CBCrewApplyKit(sys, game, puppet, m);   // rank, gear, the weapon handed over, chrome (Reactions/CrewKit.reds, 2.6.0)
  } else {
    CBKitSquadMember(puppet);
  }
  CBMakeFollower(puppet, player);
}

// [C5] With Come on their own: an ambush has sprung on V, and the most loyal are already coming.
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
  let up = 0;
  let coming = 0;
  let near = false;
  let k = 0;
  while k < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[k]) as ScriptedPuppet;
    if CBStillStanding(p) {
      up += 1;
      book.outDown[k] = false;
      if Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.MyCrewLeaveDistance() {
        near = true;
      }
    } else {
      if des.IsSpawning(book.outBody[k]) {
        coming += 1;
        near = true;
      } else {
        if IsDefined(p) && CBIsDown(p) && !p.IsDead() {
          book.outDown[k] = true;
          if p.IsAttached() && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.MyCrewLeaveDistance() {
            near = true;   // lying where the fight is, not lost
          }
        }
      }
    }
    k += 1;
  }
  let trouble = CBCrewTrouble(sys, game);
  book.quiet = trouble ? 0 : book.quiet + 1;
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
    why = 0;
  }
  if book.driving >= CBConfig.MyCrewDriveTicks() {
    why = 1;
  }
  if !near && sys.GetTickCount() % 5 == 0 {
    why = 2;
  }
  if CBArrivalsHeld(sys, game) {
    why = 3;
  }
  if up == 0 && coming == 0 && !trouble {
    why = 4;
  }
  // Switched off with them out (2.5.6): they go home now, the one order they get, instead of following V until the fight
  // went quiet. No win is counted and nothing is said, as when arrivals are held.
  if !CBMyCrewOn() {
    why = 3;
  }
  if why >= 0 {
    CBCrewEndCall(sys, game, book, why);
  }
}

// The fight is over, or V has gone: everybody standing stops following and walks home, the one order they get.
// What happened to each is counted here: a win, a wound, and whether V stood over them when they went down.
func CBCrewEndCall(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, why: Int32) -> Void {
  let player = GetPlayer(game);
  let now = CBGameSeconds(game);
  let won = why == 0 && !CBHuntersOut(sys, game);
  let ppos = IsDefined(player) ? player.GetWorldPosition() : new Vector4(0.0, 0.0, 0.0, 1.0);
  let speaker: ref<CBCrewMember>;
  let promoted: ref<CBCrewMember>;
  let leftLying: ref<CBCrewMember>;
  let i = 0;
  while i < book.OutCount() {
    let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
    let m = book.Find(book.outMember[i]);
    if IsDefined(m) {
      if book.outDown[i] {
        m.scars += 1;
        m.hurtUntil = now + CBConfig.MyCrewHurtDays() * CBConfig.SecondsPerDay();
        let stayed = IsDefined(p) && p.IsAttached() && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.MyCrewStayedDistance();
        if stayed {
          CBCrewLoyalty(m, CBConfig.MyCrewStayedLoyalty(), CBCrewWhyNone());
        } else {
          CBCrewLoyalty(m, -CBConfig.MyCrewLeftLyingLoyalty(), CBCrewWhyLeftLying());
          leftLying = m;
        }
      } else {
        if won {
          let before = CBCrewRank(m.wins);
          m.wins += 1;
          CBCrewLoyalty(m, CBConfig.MyCrewWinLoyalty(), CBCrewWhyNone());
          if CBCrewRank(m.wins) > before {
            promoted = m;
          }
        }
        if !IsDefined(speaker) || m.loyalty > speaker.loyalty {
          speaker = m;
        }
      }
    }
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      CBEndFollower(p);
      CBCrewFriendlyToV(game, p);
      CBOrderFlee(game, p, true);   // walking home, as the comment above says (2.5.1); a sprint read as running away
    }
    i += 1;
  }
  book.leaving = true;
  book.turnMember = 0;
  book.turnTicks = 0;
  if won {
    CBFileLog(sys, n"CrewWon", now, CBEventDistrict(sys, game), n"", 0.0);
  }
  if !CBMessagesOn() {
    return;
  }
  if IsDefined(speaker) {
    let home = NotEquals(speaker.home, n"") ? CBDistrictLabel(speaker.home) : "home";
    if why == 0 {
      CBCrewText(sys, game, speaker, won ? CBLineOf([s"Clean. We're heading back to \(home).", "That's done. Call again, same price.",
                                                    s"Not bad, \(CBYou(sys, game)). Not bad at all."])
                                         : "Quiet now. We're going.");
    }
    if why == 1 {
      CBCrewText(sys, game, speaker, CBLineOf(["Go, we'll find our own way home.", "Nice of you to wait. We'll walk."]));
    }
    if why == 2 {
      CBCrewText(sys, game, speaker, s"Lost you. Heading back to \(home).");
    }
    if why == 3 {
      CBCrewText(sys, game, speaker, "Not our kind of place. We're gone.");
    }
  }
  if IsDefined(promoted) {
    let rank = CBCrewRank(promoted.wins);
    CBCrewText(sys, game, null, rank >= 3
      ? s"The street's calling \(CBCrewFirst(sys, promoted)) \"\(CBCrewNickname(promoted.seat, promoted.seed))\" now. Earned it."
      : s"\(CBCrewFirst(sys, promoted)) is getting good at this. Rank \(rank).");
  }
  if IsDefined(leftLying) {
    CBCrewText(sys, game, leftLying, CBLineOf(["You left me lying there. I'll remember that.", "Woke up alone on the pavement. Thanks for nothing."]));
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
    let reason = why == CBCrewWhyUnpaid() ? "You should have paid me." : (why == CBCrewWhyLeftLying() ? "You left me lying in the street. Now you know how it feels."
                 : (why == CBCrewWhyOldGang() ? "You kept killing my people. They're still my people." : "Nothing personal. They pay better."));
    CBPhoneSendTinted(game, name, s"Not coming. They know exactly where you are now. \(reason)", CBHudRed());
    CBHearsayFromStreet(game, s"\(name) sold you out. Whoever's after you knows where you're standing.", n"");
  }
  CBLog.Info(n"Crew", "A crew member sold V out to the hunters.");
}

// One set to turn does it: the role cleared, hostile to V, and a Rival from now on (the Betrayer).
func CBCrewTurn(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
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
  CBIntelSay(game, 3, name, CBLineOf([s"Sorry, \(CBYou(sys, game)). Better offer.", "Should've paid me what I was worth.",
                                      "Turn around. Slowly. This was always going to happen."]), 4.0);
  CBSayVoiced(sys, p, n"enemy_warning");
  if CBMessagesOn() {
    CBCrewText(sys, game, null, s"\(name) turned on you. Did not see that coming. Or maybe we did.");
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
      CBHearsayFromStreet(game, s"\(CBRivalDisplayName(sys.GetContent(), r)) got away. They know your haunts, your habits, your crew. Expect them.", n"");
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
    return true;   // a round that went too far: hurt, never a death or a kill (2.6.0)
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
  // For the memorial, and the crew's own standing (Reactions/CrewBanner.reds, 2.6.0): the killers' gang, and the gang
  // that lent somebody who did not come back.
  let bb = CBCrewBannerBook.Get(game);
  if IsDefined(bb) {
    bb.fallCause = CBCrewFellBeside();
    bb.fallGang = killerGang;
  }
  CBCrewStandingShift(game, killerGang, -CBConfig.CrewStandMemberKilled());
  if m.kind == CBCrewLent() {
    CBCrewStandingShift(game, m.faction, -CBConfig.CrewStandMemberKilled());
  }
  book.Remove(m, CBCrewEndFell(), byRival, district, now);
  CBMapRemember(sys, game, CBMemCrewFell(), puppet.GetWorldPosition(), m.id, m.faction, n"", n"", false);   // [85], 2.5.0
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
    let wins = m.wins > 0 ? s" \(m.wins) fights with you, and this is how it ends." : "";
    CBCrewText(sys, game, null, StrLen(by) > 0 ? s"\(name) is dead. \(by) did it.\(wins) You know what to do."
                                               : s"\(name) is dead, in \(CBHere(sys)).\(wins) Find who did it.");
    if m.kind == CBCrewLent() && NotEquals(m.faction, n"") {
      CBPhoneFromAlly(game, m.faction, s"We lent you \(CBCrewFirst(sys, m)). You were supposed to bring them back.");
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
    CBCrewText(sys, game, null, s"That was for \(CBCrewPastName(sys, p)). Rest easy.");
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
          CBCrewText(sys, game, null, s"The one who killed \(CBCrewPastName(sys, past)) got away. The street calls them \(CBRivalDisplayName(sys.GetContent(), nr)) now. We won't forget.");
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
            CBPhoneFromGang(game, m.faction, s"We want \(CBCrewFirst(sys, m)) back. You know why.");
          } else {
            CBPhoneSendTinted(game, name, "I'm done. Don't call this number again.", CBHudAmber());
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
      CBCrewText(sys, game, null, CBLineOf([s"Week's up. The cut's \(book.CutOwed())eb. Everybody's asking.",
                                           s"Payday, \(CBYou(sys, game)). \(book.CutOwed())eb for the crew."]));
    }
  }
}

// One text when somebody starts to come loose, every other day at most, about what is eating them.
func CBCrewRestlessText(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, day: Int32) -> Void {
  if !CBMessagesOn() || !CBCrewRestless(m) || day - m.warnedDay < 2 {
    return;
  }
  m.warnedDay = day;
  let line = "Been thinking about whether this is worth it.";
  if m.lastWhy == CBCrewWhyUnpaid() { line = "You still owe me for the last job. I don't work for free."; }
  if m.lastWhy == CBCrewWhyLeftLying() { line = "Still thinking about you leaving me lying there."; }
  if m.lastWhy == CBCrewWhyLost() { line = "We lost one. Could've been me. Could still be."; }
  if m.lastWhy == CBCrewWhyOldGang() { line = s"You keep putting down \(CBFactionLabel(m.faction)). Some of them were my friends."; }
  if m.lastWhy == CBCrewWhyFear() { line = "Not as scared of you as I used to be. Just so you know."; }
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
      total += base + CBConfig.MyCrewCutPerRank() * (CBCrewRank(m.wins) - 1);
    }
  }
  return RoundF(Cast<Float>(total) * CBCrewCutMult());
}

// V pays what the crew is owed: a fair cut.
public func CBCrewPayCut(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || book.CutOwed() <= 0 {
    return "Nobody's owed anything.";
  }
  let owed = book.CutOwed();
  if !CBTalkTakeMoney(game, GetPlayer(game), owed) {
    return s"You don't have \(owed)eb.";
  }
  book.SetCutOwed(0);
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    CBCrewLoyalty(m, m.kind == CBCrewPaid() ? CBConfig.MyCrewFairCutPaid() : CBConfig.MyCrewFairCut(), CBCrewWhyNone());
  }
  CBFileLog(sys, n"CrewPaid", CBGameSeconds(game), CBEventDistrict(sys, game), n"", Cast<Float>(owed));
  if CBMessagesOn() {
    CBCrewText(sys, game, null, CBLineOf(["Cut's in. Everybody's happy. For now.", "Paid in full. That's how you keep a crew."]));
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
    CBCrewText(sys, game, null, restless ? s"\(first) took it well. Too well, if you ask me."
                                         : s"\(first) says thanks for the work. Door's open if you ever need them.");
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
  if Equals(name, CBCrewSender()) && ArraySize(CBCrewPhoneRows(sys, game, CBPhoneAnswerCrew())) > 0 {
    return CBPhoneAnswerCrew();
  }
  if book.offerSeed != 0 && book.offerUntil >= CBGameSeconds(game) && Equals(name, book.offerSender) && book.HasRoom() {
    return CBPhoneAnswerHire();
  }
  // Asked once per thing they say (UI/PhoneMessages.reds, ThreadAwaitsAnswer): "Work for me" stayed under every one of
  // their texts, so V could ask until the dice said yes (2.5.0).
  if IsDefined(CBPhoneThreadDebtor(sys, store, thread)) && store.ThreadAwaitsAnswer(thread) {
    return CBPhoneAnswerDebtor();
  }
  return CBPhoneAnswerNone();
}

public func CBCrewPhoneRows(sys: ref<CyberbaneSystem>, game: GameInstance, kind: Int32) -> array<Int32> {
  let out: array<Int32>;
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) {
    return out;
  }
  if kind == CBPhoneAnswerCrew() {
    if StrLen(CBCrewCallBlocked(sys, game, false)) == 0 {
      ArrayPush(out, CBPhoneRowCallCrew());
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
  if row == CBPhoneRowCallCrew() { return "Need you. Now."; }
  if row == CBPhoneRowPayCut() { return IsDefined(book) ? s"Here's the cut: \(book.CutOwed())eb" : "Here's the cut"; }
  if row == CBPhoneRowRecruit() { return "Work for me."; }
  if row == CBPhoneRowHire() { return IsDefined(book) ? s"Deal: \(book.offerPrice)eb" : "Deal"; }
  if row == CBPhoneRowHireHaggle() { return "Too much"; }
  if row == CBPhoneRowHirePass() { return "Not now"; }
  return "";
}

public func CBCrewPhoneReply(sys: ref<CyberbaneSystem>, game: GameInstance, store: ref<CBPhone>, thread: Int32, row: Int32) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  store.Reply(game, thread, CBCrewPhoneRowText(sys, game, row));
  if row == CBPhoneRowCallCrew() {
    let why = CBCrewCall(sys, game, false);
    if StrLen(why) > 0 {
      CBCrewText(sys, game, null, why);
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
      CBPhoneSendTinted(game, sender, "Done. They'll be on your crew thread.", CBHudCyan());
    }
    return;
  }
  if row == CBPhoneRowHireHaggle() {
    book.offerHaggled = true;
    if RandF() < 0.5 {
      book.offerPrice = RoundF(Cast<Float>(book.offerPrice) * 0.8);
      CBPhoneSendTinted(game, sender, s"Fine. \(book.offerPrice)eb, and they're yours. Last offer.", CBHudCyan());
    } else {
      CBPhoneSendTinted(game, sender, s"Good people cost money. \(book.offerPrice)eb.", CBHudCyan());
    }
    return;
  }
  if row == CBPhoneRowHirePass() {
    book.offerSeed = 0;
    book.offerUntil = 0.0;
    CBPhoneSendTinted(game, sender, "Your loss. Somebody else will take them.", CBHudCyan());
  }
}

// ---- For the Hub ([C10]) -------------------------------------------------------------------------------------------

// One line about a member's state: out, hurt, restless, ready.
public func CBCrewStateWord(book: ref<CBCrewBook>, m: ref<CBCrewMember>, now: Float) -> String {
  if !IsDefined(m) {
    return "";
  }
  if book.IsOut(m.id) {
    return "WITH YOU";
  }
  let away = CBCrewAwayWord(GetGameInstance(), m.id, now);
  if StrLen(away) > 0 {
    return away;
  }
  if CBCrewHurt(m, now) {
    let hours = CeilF((m.hurtUntil - now) / CBConfig.SecondsPerHour());
    return s"HURT, \(hours)H";
  }
  if m.calledAt > 0.0 && now - m.calledAt < CBConfig.MyCrewCallSeconds() {
    return "RESTING";
  }
  if CBCrewRestless(m) {
    return "RESTLESS";
  }
  return "READY";
}

// The page's summary: how many, what is owed, what is on offer.
public func CBCrewSummary(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBCrewBook.Get(game);
  if !CBMyCrewOn() {
    return "Your crew is switched off in Mod Settings.";
  }
  if !IsDefined(book) || book.Count() == 0 {
    // Said as the options really are (2.5.5): "ask them where they lie" read as where their loyalty lies, and a gang
    // lends one as soon as it is Friendly (2.5.0), not only when it "would die for you".
    return "Nobody works for you yet. Four ways in: beat down a Rival you have spared before and, while they are on the ground, tell them to work for you; scare a ganger badly enough and tell them they work for you now; hire a solo a broker offers you; or ask a Friendly or Allied gang to lend you one of theirs.";
  }
  let out = s"\(book.Count()) of \(CBConfig.MyCrewRoster()) on the roster.";
  if book.CutOwed() > 0 {
    out += s" They are owed \(book.CutOwed())eb.";
  } else {
    if book.CutDueAt() > 0.0 && CBCrewCutMult() > 0.0 {
      let days = CeilF((book.CutDueAt() - CBGameSeconds(game)) / CBConfig.SecondsPerDay());
      out += days <= 1 ? " The cut is due within a day." : s" The cut is due in \(days) days.";
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
  if Equals(k, n"CrewCalled") { return n == 1 ? "You called your crew, and one of them came." : s"You called your crew, and \(n) came."; }
  if Equals(k, n"CrewWon") { return "Your crew fought beside you, and won."; }
  if Equals(k, n"CrewPaid") { return s"You paid your crew their cut: \(n)eb."; }
  if Equals(k, n"TraitorDown") { return "You put down the one who turned on you."; }
  let book = CBCrewBook.Get(sys.GetGameInstance());
  let m = IsDefined(book) ? book.Find(n) : null;
  let p = IsDefined(book) ? book.FindPast(n) : null;
  let name = IsDefined(m) ? CBCrewName(sys, m) : (IsDefined(p) ? CBCrewPastName(sys, p) : "Somebody");
  if Equals(k, n"CrewJoined") { return s"\(name) joined your crew."; }
  if Equals(k, n"CrewFell") { return s"\(name) died fighting for you."; }
  if Equals(k, n"CrewTurned") { return s"\(name) turned on you in the middle of a fight."; }
  if Equals(k, n"CrewSold") { return s"\(name) sold you out to the people hunting you."; }
  if Equals(k, n"CrewWalked") { return s"\(name) walked out on your crew."; }
  if Equals(k, n"CrewLetGo") { return s"You let \(name) go."; }
  return s"You avenged \(name).";
}

// ---- The scanner (UI/ScannerName.reds) ------------------------------------------------------------------------------

// One of V's crew goes by their own name.
public func CBCrewScannerName(npc: ref<NPCPuppet>) -> String {
  let sys = IsDefined(npc) ? CyberbaneSystem.Get(npc.GetGame()) : null;
  let book = IsDefined(npc) ? CBCrewBook.Get(npc.GetGame()) : null;
  let m = IsDefined(book) ? book.MemberOfBody(npc.GetEntityID()) : null;
  return IsDefined(m) ? CBCrewName(sys, m) : "";
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
    return "YOUR CREW  /  " + StrUpper(CBCrewSeatWord(m.seat));
  }
  if npc.cbKilledCrew > 0 {
    let p = book.FindPast(npc.cbKilledCrew);
    if IsDefined(p) {
      return "KILLED " + StrUpper(CBCrewFirstName(sys, p.kind, p.faction, p.rival, p.seed));
    }
  }
  return "";
}

// ---- What the Hub asked for, carried out back in the game ----------------------------------------------------------

func CBCrewServiceHub(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
  CBCrewKitService(sys, game, book);   // kits, training, wars and the crew's name (Reactions/CrewKit.reds, 2.6.0)
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
}

// ---- The crew page's words ([C10]) -------------------------------------------------------------------------------

public func CBCrewLoyaltyTint(loyalty: Int32) -> HDRColor {
  if loyalty >= 60 { return CBHudGreen(); }
  if loyalty >= CBConfig.MyCrewRestless() { return CBHudCyan(); }
  if loyalty >= CBConfig.MyCrewBetrayLine() { return CBHudAmber(); }
  return CBHudRed();
}

public func CBCrewLoyaltyWord(loyalty: Int32) -> String {
  if loyalty >= 80 { return "would take a bullet for you"; }
  if loyalty >= 60 { return "solid"; }
  if loyalty >= CBConfig.MyCrewRestless() { return "doing the job"; }
  if loyalty >= CBConfig.MyCrewBetrayLine() { return "restless"; }
  return "close to walking, or worse";
}

// What is eating somebody, from what last cost them.
public func CBCrewWorry(m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) { return ""; }
  if m.lastWhy == CBCrewWhyUnpaid() { return "the cut you owe them"; }
  if m.lastWhy == CBCrewWhyLeftLying() { return "you left them lying in the street"; }
  if m.lastWhy == CBCrewWhyLost() { return "losing one of the crew"; }
  if m.lastWhy == CBCrewWhyOldGang() { return s"what you keep doing to \(CBFactionLabel(m.faction))"; }
  if m.lastWhy == CBCrewWhyFear() { return "they are less afraid of you than they were"; }
  return "";
}

// How somebody left, in a word for the crew picture, and the tint it is drawn in.
public func CBCrewEndWord(end: Int32) -> String {
  if end == CBCrewEndFell() { return "FELL"; }
  if end == CBCrewEndLetGo() { return "LET GO"; }
  if end == CBCrewEndWalked() { return "WALKED"; }
  if end == CBCrewEndSold() { return "SOLD YOU OUT"; }
  return "TURNED ON YOU";
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
      ? s"Your recruiter found them: they come as a \(StrLower(CBCrewRankWord(CBCrewRank(bbOffer.offerWins)))), more loyal than most. " : "";
    return StrUpper(solo) + "\n" + s"A solo \(book.offerSender) put forward: a \(seat), \(book.offerPrice)eb to sign, then the weekly cut. "
         + found + "Paid people are loyal while the money keeps coming. The offer stands for a day.";
  }
  if !IsDefined(m) || !IsDefined(book) {
    return "";
  }
  let out = StrUpper(CBCrewName(sys, m)) + "\n";
  let home = NotEquals(m.home, n"") ? CBDistrictLabel(m.home) : "the city";
  let since = CBHudSince(now, m.joinedAt);
  out += s"A \(CBCrewSeatWord(m.seat)), \(CBCrewFromWords(m)). Lives in \(home)" + (StrLen(since) > 0 ? s", with you \(since)." : ".") + "\n";
  let rank = CBCrewRank(m.wins);
  let wins = m.wins == 0 ? "No fights won with you yet" : (m.wins == 1 ? "One fight won with you" : s"\(m.wins) fights won with you");
  let scars = m.scars == 0 ? "" : (m.scars == 1 ? ", one scar to show for it" : s", \(m.scars) scars to show for it");
  out += wins + scars + s". Rank \(rank)" + (rank >= 3 ? s", known as \"\(CBCrewNickname(m.seat, m.seed))\"" : "") + ".\n";
  out += s"Loyalty \(m.loyalty) of 100: \(CBCrewLoyaltyWord(m.loyalty)).";
  let worry = CBCrewWorry(m);
  if CBCrewRestless(m) && StrLen(worry) > 0 {
    out += s" What's eating them: \(worry).";
  }
  out += "\n";
  if book.IsOut(m.id) {
    out += book.leaving ? "Heading home now.\n" : "With you now.\n";
  } else {
    if CBCrewHurt(m, now) {
      out += s"Hurt: back on their feet in about \(CeilF((m.hurtUntil - now) / CBConfig.SecondsPerHour())) hours.\n";
    } else {
      if m.calledAt > 0.0 && now - m.calledAt < CBConfig.MyCrewCallSeconds() {
        out += "Just got back. They can be called again within the hour.\n";
      }
    }
  }
  if CBCrewBetrayalOn() && m.kind != CBCrewLent() && m.loyalty < CBConfig.MyCrewBetrayLine() {
    out += "Call them like this and they might sell you out, or worse. Pay them, win with them, or let them go.\n";
  }
  return out;
}
