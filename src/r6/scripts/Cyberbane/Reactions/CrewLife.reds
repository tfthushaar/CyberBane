// Cyberbane - Your crew's own lives (2.7.7)
//
// The crew has numbers and a roster; this is what makes each of them somebody. Every member keeps a short story (where
// they joined, the scars, the ranks, the wars), counts the people they put down, and has a temperament from the same seed
// as their name: a hothead, the careful one, the one who still feels for the old gang, the one in it for the money. It
// shows in their texts and in what makes their loyalty move. Now and then one of them asks V for something. When one
// dies the crew buries them a day later in their home district, and notices who came. One of them can be V's second,
// who speaks for the crew and leads its wars.
//
// Saved in its own book (CBCrewLifeBook), never as fields on CBCrewMember: a new persistent field on a saved class wipes
// that class's saved data, and a saved class holding an array crashed the game before (schema 2 and 3). So every list
// here is a flat parallel array on the book itself, keyed by member id, and read up to the shortest of them.

// What a line in a member's story is.
public func CBLifeJoined() -> Int32 = 1
public func CBLifeScar() -> Int32 = 2
public func CBLifePromoted() -> Int32 = 3
public func CBLifeChrome() -> Int32 = 4
public func CBLifeWeapon() -> Int32 = 5
public func CBLifeWar() -> Int32 = 6
public func CBLifeTrained() -> Int32 = 7
public func CBLifeMourned() -> Int32 = 8
public func CBLifeSecond() -> Int32 = 9
public func CBLifeAskDone() -> Int32 = 10
public func CBLifeAskIgnored() -> Int32 = 11
public func CBLifeKills() -> Int32 = 12

// What a member can ask of V.
public func CBAskNone() -> Int32 = 0
public func CBAskGun() -> Int32 = 1
public func CBAskRevenge() -> Int32 = 2
public func CBAskDayOff() -> Int32 = 3
public func CBAskCut() -> Int32 = 4

// A temperament, from the member's seed.
public func CBTemperHothead() -> Int32 = 0
public func CBTemperCareful() -> Int32 = 1
public func CBTemperOldGang() -> Int32 = 2
public func CBTemperMoney() -> Int32 = 3

public class CBCrewLifeBook extends ScriptableSystem {
  private persistent let m_killId: array<Int32>;
  private persistent let m_killN: array<Int32>;
  private persistent let m_histId: array<Int32>;
  private persistent let m_histKind: array<Int32>;
  private persistent let m_histAt: array<Float>;
  private persistent let m_histPlace: array<CName>;
  private persistent let m_histValue: array<Int32>;
  private persistent let m_second: Int32;          // V's second-in-command, a member id; 0 for none
  // One thing asked of V at a time.
  private persistent let m_askId: Int32;
  private persistent let m_askKind: Int32;
  private persistent let m_askUntil: Float;
  private persistent let m_askValue: Int32;        // the Rival for revenge, the eddies for a cut, the tier for a gun
  private persistent let m_askNextAt: Float;       // game seconds; nobody asks again before then
  // A day off V gave: who, and until when.
  private persistent let m_restId: array<Int32>;
  private persistent let m_restUntil: array<Float>;
  // A funeral owed: whose (a past member's id), where, from when, and how it went (0 none, 1 owed, 2 V came, 3 missed).
  private persistent let m_funeralPast: Int32;
  private persistent let m_funeralDistrict: CName;
  private persistent let m_funeralAt: Float;
  private persistent let m_funeralState: Int32;
  // The crew's home (one of V's apartments), and the district it is in.
  private persistent let m_homeSet: Bool;
  private persistent let m_homeX: Float;
  private persistent let m_homeY: Float;
  private persistent let m_homeZ: Float;
  private persistent let m_homeDistrict: CName;
  // The street tax the shops in the crew's districts owe, paid to V in person (2.7.7): the district and what it owes.
  private persistent let m_taxDistrict: array<CName>;
  private persistent let m_taxOwed: array<Int32>;
  // A counterattack on the crew's corners, told ahead (2.7.7): where, who, when, and how it stands (0 none, 1 coming,
  // 2 under way with V there, 3 held, 4 lost).
  private persistent let m_caDistrict: CName;
  private persistent let m_caGang: CName;
  private persistent let m_caAt: Float;
  private persistent let m_caState: Int32;
  // V's part in the crew's wars (2.7.7): the gang, and how many of theirs V put down while the war on them was on.
  private persistent let m_warHelpGang: array<CName>;
  private persistent let m_warHelpKills: array<Int32>;
  // Said once a war, when V walks onto the war's streets.
  private persistent let m_warHereSaid: array<CName>;
  // Session only: the last numbers each member was kitted with, for the Hub; and kit texts waiting to go as one.
  public let kitId: array<Int32>;
  public let kitHealth: array<Float>;
  public let kitArmour: array<Float>;
  public let kitDamage: array<Float>;
  public let batchId: array<Int32>;
  public let batchLine: array<String>;
  public let batchAt: array<Int32>;
  public let funeralCalled: Bool;
  public let lastKillMember: Int32;   // whose hit downed the last enemy, this fight
  // The pins on the world map for the crew's war fronts and a counterattack coming (2.7.7): what each stands for, by key.
  public let frontKey: array<CName>;
  public let frontPin: array<NewMappinID>;

  public static func Get(game: GameInstance) -> ref<CBCrewLifeBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewLifeBook") as CBCrewLifeBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    ArrayClear(this.kitId);
    ArrayClear(this.kitHealth);
    ArrayClear(this.kitArmour);
    ArrayClear(this.kitDamage);
    ArrayClear(this.batchId);
    ArrayClear(this.batchLine);
    ArrayClear(this.batchAt);
    this.funeralCalled = false;
    this.lastKillMember = 0;
    ArrayClear(this.frontKey);
    ArrayClear(this.frontPin);
  }

  // A Start over (CyberbaneSystem.HardReset): every Rival id starts again, so nothing here keyed by one may stay.
  public func Clear() -> Void {
    ArrayClear(this.m_killId);
    ArrayClear(this.m_killN);
    ArrayClear(this.m_histId);
    ArrayClear(this.m_histKind);
    ArrayClear(this.m_histAt);
    ArrayClear(this.m_histPlace);
    ArrayClear(this.m_histValue);
    this.m_second = 0;
    this.ClearAsk();
    this.m_askNextAt = 0.0;
    ArrayClear(this.m_restId);
    ArrayClear(this.m_restUntil);
    this.m_funeralPast = 0;
    this.m_funeralState = 0;
    this.m_homeSet = false;
    this.m_homeDistrict = n"";
    ArrayClear(this.m_taxDistrict);
    ArrayClear(this.m_taxOwed);
    this.m_caState = 0;
    ArrayClear(this.m_warHelpGang);
    ArrayClear(this.m_warHelpKills);
    ArrayClear(this.m_warHereSaid);
    ArrayClear(this.batchId);
    ArrayClear(this.batchLine);
    ArrayClear(this.batchAt);
  }

  // ---- Kills ----

  public func Kills(id: Int32) -> Int32 {
    let n = Min(ArraySize(this.m_killId), ArraySize(this.m_killN));
    let i = 0;
    while i < n {
      if this.m_killId[i] == id {
        return this.m_killN[i];
      }
      i += 1;
    }
    return 0;
  }

  public func AddKill(id: Int32) -> Int32 {
    let n = Min(ArraySize(this.m_killId), ArraySize(this.m_killN));
    let i = 0;
    while i < n {
      if this.m_killId[i] == id {
        this.m_killN[i] += 1;
        return this.m_killN[i];
      }
      i += 1;
    }
    // Short arrays from an older save are evened before anything is added.
    while ArraySize(this.m_killId) > n { ArrayPop(this.m_killId); }
    while ArraySize(this.m_killN) > n { ArrayPop(this.m_killN); }
    ArrayPush(this.m_killId, id);
    ArrayPush(this.m_killN, 1);
    return 1;
  }

  // ---- The story ----

  public func HistCount() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_histId), ArraySize(this.m_histKind)), Min(ArraySize(this.m_histAt), ArraySize(this.m_histPlace))),
               ArraySize(this.m_histValue));
  }

  public func HistId(i: Int32) -> Int32 { return this.m_histId[i]; }
  public func HistKind(i: Int32) -> Int32 { return this.m_histKind[i]; }
  public func HistAt(i: Int32) -> Float { return this.m_histAt[i]; }
  public func HistPlace(i: Int32) -> CName { return this.m_histPlace[i]; }
  public func HistValue(i: Int32) -> Int32 { return this.m_histValue[i]; }

  public func Note(id: Int32, kind: Int32, at: Float, place: CName, value: Int32) -> Void {
    let n = this.HistCount();
    while ArraySize(this.m_histId) > n { ArrayPop(this.m_histId); }
    while ArraySize(this.m_histKind) > n { ArrayPop(this.m_histKind); }
    while ArraySize(this.m_histAt) > n { ArrayPop(this.m_histAt); }
    while ArraySize(this.m_histPlace) > n { ArrayPop(this.m_histPlace); }
    while ArraySize(this.m_histValue) > n { ArrayPop(this.m_histValue); }
    ArrayPush(this.m_histId, id);
    ArrayPush(this.m_histKind, kind);
    ArrayPush(this.m_histAt, at);
    ArrayPush(this.m_histPlace, place);
    ArrayPush(this.m_histValue, value);
    // A member's story keeps its newest lines; the book as a whole is kept small.
    let mine = 0;
    let first = -1;
    let i = 0;
    while i < ArraySize(this.m_histId) {
      if this.m_histId[i] == id {
        mine += 1;
        if first < 0 && this.m_histKind[i] != CBLifeJoined() {
          first = i;
        }
      }
      i += 1;
    }
    if mine > CBConfig.CrewStoryKept() && first >= 0 {
      this.Erase(first);
    }
    while this.HistCount() > CBConfig.CrewStoryBookCap() {
      this.Erase(0);
    }
  }

  private func Erase(i: Int32) -> Void {
    ArrayErase(this.m_histId, i);
    ArrayErase(this.m_histKind, i);
    ArrayErase(this.m_histAt, i);
    ArrayErase(this.m_histPlace, i);
    ArrayErase(this.m_histValue, i);
  }

  // Everything kept for somebody who is gone, once the memorial has what it needs.
  public func Forget(id: Int32) -> Void {
    let i = this.HistCount() - 1;
    while i >= 0 {
      if this.m_histId[i] == id {
        this.Erase(i);
      }
      i -= 1;
    }
    if this.m_second == id {
      this.m_second = 0;
    }
    if this.m_askId == id {
      this.ClearAsk();
    }
    let r = Min(ArraySize(this.m_restId), ArraySize(this.m_restUntil)) - 1;
    while r >= 0 {
      if this.m_restId[r] == id {
        ArrayErase(this.m_restId, r);
        ArrayErase(this.m_restUntil, r);
      }
      r -= 1;
    }
  }

  // ---- The street tax, owed in person ----

  public func TaxOwed(d: CName) -> Int32 {
    let n = Min(ArraySize(this.m_taxDistrict), ArraySize(this.m_taxOwed));
    let i = 0;
    while i < n {
      if Equals(this.m_taxDistrict[i], d) {
        return this.m_taxOwed[i];
      }
      i += 1;
    }
    return 0;
  }

  public func AddTax(d: CName, amount: Int32) -> Void {
    let n = Min(ArraySize(this.m_taxDistrict), ArraySize(this.m_taxOwed));
    let i = 0;
    while i < n {
      if Equals(this.m_taxDistrict[i], d) {
        this.m_taxOwed[i] = Min(this.m_taxOwed[i] + amount, CBConfig.CrewTaxOwedCap());
        return;
      }
      i += 1;
    }
    while ArraySize(this.m_taxDistrict) > n { ArrayPop(this.m_taxDistrict); }
    while ArraySize(this.m_taxOwed) > n { ArrayPop(this.m_taxOwed); }
    ArrayPush(this.m_taxDistrict, d);
    ArrayPush(this.m_taxOwed, Min(amount, CBConfig.CrewTaxOwedCap()));
  }

  public func ClearTax(d: CName) -> Void {
    let i = Min(ArraySize(this.m_taxDistrict), ArraySize(this.m_taxOwed)) - 1;
    while i >= 0 {
      if Equals(this.m_taxDistrict[i], d) {
        ArrayErase(this.m_taxDistrict, i);
        ArrayErase(this.m_taxOwed, i);
      }
      i -= 1;
    }
  }

  // ---- A counterattack told ahead ----

  public func CaDistrict() -> CName { return this.m_caDistrict; }
  public func CaGang() -> CName { return this.m_caGang; }
  public func CaAt() -> Float { return this.m_caAt; }
  public func CaState() -> Int32 { return this.m_caState; }
  public func SetCa(d: CName, gang: CName, at: Float, state: Int32) -> Void {
    this.m_caDistrict = d;
    this.m_caGang = gang;
    this.m_caAt = at;
    this.m_caState = state;
  }
  public func SetCaState(s: Int32) -> Void { this.m_caState = s; }

  // ---- V in the crew's wars ----

  public func WarHelp(gang: CName) -> Int32 {
    let n = Min(ArraySize(this.m_warHelpGang), ArraySize(this.m_warHelpKills));
    let i = 0;
    while i < n {
      if Equals(this.m_warHelpGang[i], gang) {
        return this.m_warHelpKills[i];
      }
      i += 1;
    }
    return 0;
  }

  public func AddWarHelp(gang: CName) -> Int32 {
    let n = Min(ArraySize(this.m_warHelpGang), ArraySize(this.m_warHelpKills));
    let i = 0;
    while i < n {
      if Equals(this.m_warHelpGang[i], gang) {
        this.m_warHelpKills[i] += 1;
        return this.m_warHelpKills[i];
      }
      i += 1;
    }
    while ArraySize(this.m_warHelpGang) > n { ArrayPop(this.m_warHelpGang); }
    while ArraySize(this.m_warHelpKills) > n { ArrayPop(this.m_warHelpKills); }
    ArrayPush(this.m_warHelpGang, gang);
    ArrayPush(this.m_warHelpKills, 1);
    return 1;
  }

  public func ClearWarHelp(gang: CName) -> Void {
    let i = Min(ArraySize(this.m_warHelpGang), ArraySize(this.m_warHelpKills)) - 1;
    while i >= 0 {
      if Equals(this.m_warHelpGang[i], gang) {
        ArrayErase(this.m_warHelpGang, i);
        ArrayErase(this.m_warHelpKills, i);
      }
      i -= 1;
    }
    ArrayRemove(this.m_warHereSaid, gang);
  }

  public func WarHereSaid(gang: CName) -> Bool {
    return ArrayContains(this.m_warHereSaid, gang);
  }

  public func NoteWarHereSaid(gang: CName) -> Void {
    if !ArrayContains(this.m_warHereSaid, gang) {
      ArrayPush(this.m_warHereSaid, gang);
    }
  }

  // ---- The second-in-command ----

  public func Second() -> Int32 { return this.m_second; }
  public func SetSecond(id: Int32) -> Void { this.m_second = Max(0, id); }

  // ---- Asks ----

  public func AskId() -> Int32 { return this.m_askId; }
  public func AskKind() -> Int32 { return this.m_askKind; }
  public func AskUntil() -> Float { return this.m_askUntil; }
  public func AskValue() -> Int32 { return this.m_askValue; }
  public func AskNextAt() -> Float { return this.m_askNextAt; }

  public func SetAsk(id: Int32, kind: Int32, until: Float, value: Int32) -> Void {
    this.m_askId = id;
    this.m_askKind = kind;
    this.m_askUntil = until;
    this.m_askValue = value;
  }

  public func ClearAsk() -> Void {
    this.m_askId = 0;
    this.m_askKind = CBAskNone();
    this.m_askUntil = 0.0;
    this.m_askValue = 0;
  }

  public func SetAskNextAt(t: Float) -> Void { this.m_askNextAt = t; }

  // ---- Days off ----

  public func RestUntil(id: Int32) -> Float {
    let n = Min(ArraySize(this.m_restId), ArraySize(this.m_restUntil));
    let i = 0;
    while i < n {
      if this.m_restId[i] == id {
        return this.m_restUntil[i];
      }
      i += 1;
    }
    return 0.0;
  }

  public func SetRest(id: Int32, until: Float) -> Void {
    let n = Min(ArraySize(this.m_restId), ArraySize(this.m_restUntil));
    let i = 0;
    while i < n {
      if this.m_restId[i] == id {
        this.m_restUntil[i] = until;
        return;
      }
      i += 1;
    }
    while ArraySize(this.m_restId) > n { ArrayPop(this.m_restId); }
    while ArraySize(this.m_restUntil) > n { ArrayPop(this.m_restUntil); }
    ArrayPush(this.m_restId, id);
    ArrayPush(this.m_restUntil, until);
  }

  // ---- Funerals ----

  public func FuneralPast() -> Int32 { return this.m_funeralPast; }
  public func FuneralDistrict() -> CName { return this.m_funeralDistrict; }
  public func FuneralAt() -> Float { return this.m_funeralAt; }
  public func FuneralState() -> Int32 { return this.m_funeralState; }

  public func OweFuneral(pastId: Int32, district: CName, at: Float) -> Void {
    this.m_funeralPast = pastId;
    this.m_funeralDistrict = district;
    this.m_funeralAt = at;
    this.m_funeralState = 1;
    this.funeralCalled = false;
  }

  public func SetFuneralState(s: Int32) -> Void { this.m_funeralState = s; }

  // ---- The crew's home ----

  public func HomeSet() -> Bool { return this.m_homeSet; }
  public func HomeDistrict() -> CName { return this.m_homeDistrict; }
  public func HomeAt() -> Vector4 { return new Vector4(this.m_homeX, this.m_homeY, this.m_homeZ, 1.0); }

  public func SetHome(at: Vector4, district: CName) -> Void {
    this.m_homeSet = true;
    this.m_homeX = at.X;
    this.m_homeY = at.Y;
    this.m_homeZ = at.Z;
    this.m_homeDistrict = district;
  }

  public func ClearHome() -> Void {
    this.m_homeSet = false;
    this.m_homeDistrict = n"";
  }

  // ---- What they were last kitted with (session) ----

  public func NoteKit(id: Int32, health: Float, armour: Float, damage: Float) -> Void {
    let i = 0;
    while i < ArraySize(this.kitId) {
      if this.kitId[i] == id {
        this.kitHealth[i] = health;
        this.kitArmour[i] = armour;
        this.kitDamage[i] = damage;
        return;
      }
      i += 1;
    }
    ArrayPush(this.kitId, id);
    ArrayPush(this.kitHealth, health);
    ArrayPush(this.kitArmour, armour);
    ArrayPush(this.kitDamage, damage);
  }
}

// ---- Temperament ------------------------------------------------------------------------------------------------------

public func CBCrewTemper(m: ref<CBCrewMember>) -> Int32 {
  return IsDefined(m) ? CBHashIndex(m.seed, 41, 4) : CBTemperCareful();
}

public func CBCrewTemperWord(t: Int32) -> String {
  if t == CBTemperHothead() { return CBT(n"Cyberbane-CrewLife-TemperHothead"); }
  if t == CBTemperCareful() { return CBT(n"Cyberbane-CrewLife-TemperCareful"); }
  if t == CBTemperOldGang() { return CBT(n"Cyberbane-CrewLife-TemperOldGang"); }
  return CBT(n"Cyberbane-CrewLife-TemperMoney");
}

// What their temperament makes of a change in loyalty (CBCrewLoyalty): a hothead loves a win and shrugs off fear, the
// careful one remembers who stayed and who left them lying, the one with old loyalties feels every one of their old gang V
// puts down, the one in it for the money counts every eddie paid or owed.
public func CBCrewTemperScale(m: ref<CBCrewMember>, delta: Int32, why: Int32) -> Int32 {
  if !IsDefined(m) || delta == 0 {
    return delta;
  }
  let t = CBCrewTemper(m);
  let f = 1.0;
  if t == CBTemperHothead() {
    if why == CBCrewWhyWin() { f = 1.5; }
    if why == CBCrewWhyFear() { f = 0.5; }
    if why == CBCrewWhyLost() { f = 1.5; }
  }
  if t == CBTemperCareful() {
    if why == CBCrewWhyStayed() || why == CBCrewWhyLeftLying() { f = 1.5; }
    if why == CBCrewWhyWin() { f = 0.75; }
  }
  if t == CBTemperOldGang() {
    if why == CBCrewWhyOldGang() { f = 2.0; }
    if why == CBCrewWhyMourned() { f = 1.5; }
  }
  if t == CBTemperMoney() {
    if why == CBCrewWhyPaid() || why == CBCrewWhyUnpaid() { f = 2.0; }
    if why == CBCrewWhyWin() { f = 0.75; }
  }
  let scaled = RoundF(Cast<Float>(delta) * f);
  if scaled == 0 {
    scaled = delta > 0 ? 1 : -1;
  }
  return scaled;
}

// ---- The story, in words ------------------------------------------------------------------------------------------------

public func CBCrewLifeNote(game: GameInstance, id: Int32, kind: Int32, place: CName, value: Int32) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) && id > 0 {
    lb.Note(id, kind, CBGameSeconds(game), place, value);
  }
}

public func CBCrewLifeKill(game: GameInstance, id: Int32) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) || id <= 0 {
    return;
  }
  lb.lastKillMember = id;
  let n = lb.AddKill(id);
  if n == 5 || n == 10 || n == 25 || n == 50 || n == 100 {
    let sys = CyberbaneSystem.Get(game);
    lb.Note(id, CBLifeKills(), CBGameSeconds(game), IsDefined(sys) ? CBEventDistrict(sys, game) : n"", n);
  }
}

public func CBCrewKillsOfMember(game: GameInstance, id: Int32) -> Int32 {
  let lb = CBCrewLifeBook.Get(game);
  return IsDefined(lb) ? lb.Kills(id) : 0;
}

// One line of their story.
func CBCrewStoryLine(sys: ref<CyberbaneSystem>, kind: Int32, place: CName, value: Int32) -> String {
  let where = CBDistrictLabel(place);
  let inWhere = StrLen(where) > 0 ? CBTf(n"Cyberbane-CrewLife-InPlace", [where]) : "";
  if kind == CBLifeJoined() { return CBTf(n"Cyberbane-CrewLife-StoryJoined", [inWhere]); }
  if kind == CBLifeScar() {
    let r = value > 0 && IsDefined(sys) ? sys.FindRivalById(value) : null;
    return IsDefined(r) ? CBTf(n"Cyberbane-CrewLife-StoryScarBy", [CBRivalDisplayName(sys.GetContent(), r), inWhere])
                        : CBTf(n"Cyberbane-CrewLife-StoryScar", [inWhere]);
  }
  if kind == CBLifePromoted() { return CBTf(n"Cyberbane-CrewLife-StoryPromoted", [CBCrewRankWord(value)]); }
  if kind == CBLifeChrome() { return CBT(n"Cyberbane-CrewLife-StoryChrome"); }
  if kind == CBLifeWeapon() { return CBTf(n"Cyberbane-CrewLife-StoryWeapon", [CBLowFirst(CBCrewTierWord(value))]); }
  if kind == CBLifeWar() {
    return value > 0 ? CBTf(n"Cyberbane-CrewLife-StoryWarWon", [CBFactionLabel(place)]) : CBTf(n"Cyberbane-CrewLife-StoryWarLost", [CBFactionLabel(place)]);
  }
  if kind == CBLifeTrained() { return CBT(n"Cyberbane-CrewLife-StoryTrained"); }
  if kind == CBLifeMourned() { return CBTf(n"Cyberbane-CrewLife-StoryMourned", [inWhere]); }
  if kind == CBLifeSecond() { return CBT(n"Cyberbane-CrewLife-StorySecond"); }
  if kind == CBLifeAskDone() { return CBT(n"Cyberbane-CrewLife-StoryAskDone"); }
  if kind == CBLifeAskIgnored() { return CBT(n"Cyberbane-CrewLife-StoryAskIgnored"); }
  if kind == CBLifeKills() { return CBTf(n"Cyberbane-CrewLife-StoryKills", [s"\(value)"]); }
  return "";
}

// Their story, oldest first, a line each: "Joined in Heywood." "Won 4 fights." "Took a scar in Westbrook." "Made Soldier."
public func CBCrewStoryLines(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> array<String> {
  let out: array<String>;
  if !IsDefined(m) {
    return out;
  }
  let lb = CBCrewLifeBook.Get(game);
  let joined = false;
  if IsDefined(lb) {
    let n = lb.HistCount();
    let i = 0;
    while i < n {
      if lb.HistId(i) == m.id {
        let line = CBCrewStoryLine(sys, lb.HistKind(i), lb.HistPlace(i), lb.HistValue(i));
        if lb.HistKind(i) == CBLifeJoined() {
          joined = true;
        }
        if StrLen(line) > 0 {
          ArrayPush(out, line);
        }
      }
      i += 1;
    }
  }
  // A member from before 2.7.7 has no story kept: where they live stands in for where they joined.
  if !joined {
    ArrayInsert(out, 0, CBCrewStoryLine(sys, CBLifeJoined(), m.home, 0));
  }
  // The running count goes after the first line.
  if m.wins > 0 {
    ArrayInsert(out, 1, m.wins == 1 ? CBT(n"Cyberbane-CrewLife-StoryWonOne") : CBTf(n"Cyberbane-CrewLife-StoryWon", [s"\(m.wins)"]));
  }
  let kills = IsDefined(lb) ? lb.Kills(m.id) : 0;
  if kills > 0 {
    ArrayPush(out, kills == 1 ? CBT(n"Cyberbane-CrewLife-StoryKillOne") : CBTf(n"Cyberbane-CrewLife-StoryKillCount", [s"\(kills)"]));
  }
  return out;
}

// ---- Ranks: what each one brings, and the word when somebody climbs --------------------------------------------------

// What a rank lets them do that the one below did not, in the player's words.
public func CBCrewRankGains(rank: Int32) -> String {
  if rank >= 6 { return CBT(n"Cyberbane-CrewLife-GainsLegend"); }
  if rank == 5 { return CBT(n"Cyberbane-CrewLife-GainsEnforcer"); }
  if rank == 4 { return CBT(n"Cyberbane-CrewLife-GainsLieutenant"); }
  if rank == 3 { return CBT(n"Cyberbane-CrewLife-GainsVeteran"); }
  if rank == 2 { return CBT(n"Cyberbane-CrewLife-GainsSoldier"); }
  return CBT(n"Cyberbane-CrewLife-GainsRookie");
}

// Somebody climbed (a fight won, a training finished): their story, the group chat with what they can do now, and the
// game's own sound for a perk bought.
public func CBCrewLifePromoted(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, from: Int32, to: Int32) -> Void {
  if !IsDefined(m) || to <= from {
    return;
  }
  CBCrewLifeNote(game, m.id, CBLifePromoted(), CBEventDistrict(sys, game), to);
  CBUiSound(game, to >= 6 ? n"ui_menu_perk_buy_master" : n"ui_menu_perk_buy_minor", n"CrewPromoted", 3.0);
  if !CBMessagesOn() {
    return;
  }
  let first = CBCrewFirst(sys, m);
  let line = to >= 3 && from < 3
    ? CBTf(n"Cyberbane-Crew-TheStreetSCallingNowEarned", [first, s"\(CBCrewNickname(m.seat, m.seed))"])
    : CBTf(n"Cyberbane-Crew-IsGettingGoodAtThisNow", [first, s"\(CBCrewRankWord(to))"]);
  CBCrewText(sys, game, null, line + " " + CBCrewRankGains(to), true);
}

// ---- A fight won, said when it is won ------------------------------------------------------------------------------

// The moment it ends, in the group chat, from whoever was in it (2.7.7): "Clean. Three of theirs down." Before this the
// win showed only when they went home. And the game's own line in their voice: the one whose hit ended it reports the
// kill, anyone else says it is over.
public func CBCrewWinLine(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, speaker: ref<CBCrewMember>, downed: Int32) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  let killer = IsDefined(lb) ? lb.lastKillMember : 0;
  if IsDefined(lb) {
    lb.lastKillMember = 0;
  }
  // Voices first: they come from the body standing there.
  let i = 0;
  let spoke = false;
  while i < book.OutCount() && !spoke {
    if book.outSeen[i] && !book.outDown[i] {
      let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
      if CBNpcSafe(sys, p) && CBStillStanding(p) {
        if killer > 0 && book.outMember[i] == killer {
          spoke = CBVoice(sys, game, p, n"coop_reports_kill", n"CrewWin", 20.0);
        } else {
          if killer == 0 {
            spoke = CBVoice(sys, game, p, n"combat_ended", n"CrewWin", 20.0);
          }
        }
      }
    }
    i += 1;
  }
  if !CBMessagesOn() || !IsDefined(speaker) {
    return;
  }
  let t = CBCrewTemper(speaker);
  let count = downed == 1 ? CBT(n"Cyberbane-CrewLife-OneOfTheirsDown") : (downed > 1 ? CBTf(n"Cyberbane-CrewLife-OfTheirsDown", [s"\(downed)"]) : "");
  let line = "";
  if t == CBTemperHothead() {
    line = CBLineOf([CBT(n"Cyberbane-CrewLife-WinHot1"), CBT(n"Cyberbane-CrewLife-WinHot2")]);
  } else {
    if t == CBTemperMoney() {
      line = CBLineOf([CBT(n"Cyberbane-CrewLife-WinMoney1"), CBT(n"Cyberbane-CrewLife-WinMoney2")]);
    } else {
      line = CBLineOf([CBT(n"Cyberbane-Crew-CleanStillWithYou"), CBT(n"Cyberbane-Crew-ThatSHandledLeadOn"), CBT(n"Cyberbane-CrewLife-WinCalm")]);
    }
  }
  CBCrewText(sys, game, speaker, StrLen(count) > 0 ? count + " " + line : line, true, true);
}

// ---- Texts that come as one ----------------------------------------------------------------------------------------

// Three pieces of chrome put in one member at once are one text, not three (2.7.7): each is held a moment, and the member's
// lines go together.
public func CBCrewBatchText(game: GameInstance, m: ref<CBCrewMember>, line: String) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(lb) || !IsDefined(sys) || !IsDefined(m) {
    CBCrewText(sys, game, m, line);
    return;
  }
  let i = 0;
  while i < ArraySize(lb.batchId) {
    if lb.batchId[i] == m.id {
      lb.batchLine[i] = lb.batchLine[i] + " " + line;
      lb.batchAt[i] = sys.GetTickCount();
      return;
    }
    i += 1;
  }
  ArrayPush(lb.batchId, m.id);
  ArrayPush(lb.batchLine, line);
  ArrayPush(lb.batchAt, sys.GetTickCount());
}

func CBCrewBatchFlush(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>, book: ref<CBCrewBook>) -> Void {
  let kb = CBCrewKitBook.Get(game);
  if IsDefined(kb) && kb.deferTexts {
    return;   // still in the Hub
  }
  let i = ArraySize(lb.batchId) - 1;
  while i >= 0 {
    if sys.GetTickCount() - lb.batchAt[i] >= CBConfig.CrewBatchTicks() {
      let m = book.Find(lb.batchId[i]);
      if IsDefined(m) {
        CBCrewText(sys, game, m, lb.batchLine[i]);
      }
      ArrayErase(lb.batchId, i);
      ArrayErase(lb.batchLine, i);
      ArrayErase(lb.batchAt, i);
    }
    i -= 1;
  }
}

// ---- The second-in-command ---------------------------------------------------------------------------------------

public func CBCrewSecond(game: GameInstance) -> ref<CBCrewMember> {
  let lb = CBCrewLifeBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(lb) || !IsDefined(book) || lb.Second() <= 0 {
    return null;
  }
  return book.Find(lb.Second());
}

public func CBCrewIsSecond(game: GameInstance, id: Int32) -> Bool {
  let lb = CBCrewLifeBook.Get(game);
  return IsDefined(lb) && id > 0 && lb.Second() == id;
}

// Made V's second from the Hub (CBCrewKitDoNow): said in the group chat, and in their story.
public func CBCrewMakeSecond(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) || !IsDefined(m) {
    return;
  }
  if lb.Second() == m.id {
    lb.SetSecond(0);
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewLife-SecondStepsDown"));
    return;
  }
  lb.SetSecond(m.id);
  CBCrewLifeNote(game, m.id, CBLifeSecond(), CBEventDistrict(sys, game), 0);
  CBCrewLoyalty(m, CBConfig.CrewSecondLoyalty(), CBCrewWhyNone());
  CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewLife-SecondNamed", [CBCrewFirst(sys, m)]), true);
}

public func CBCrewSecondId(game: GameInstance) -> Int32 {
  let lb = CBCrewLifeBook.Get(game);
  return IsDefined(lb) ? lb.Second() : 0;
}

// ---- V in the crew's wars ------------------------------------------------------------------------------------------

// Is the crew at war with this gang right now?
public func CBCrewAtWarWith(game: GameInstance, gang: CName) -> Bool {
  let wb = CBCrewWarBook.Get(game);
  if !IsDefined(wb) || !IsNameValid(gang) {
    return false;
  }
  let i = 0;
  while i < wb.Count() {
    if Equals(wb.Gang(i), gang) {
      return true;
    }
    i += 1;
  }
  return false;
}

// What V's kills while the war is on add to the crew's side, as a share; `take` spends it when the war is over.
public func CBCrewWarVHelp(game: GameInstance, gang: CName, take: Bool) -> Float {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) {
    return 0.0;
  }
  let share = MinF(Cast<Float>(lb.WarHelp(gang)) * CBConfig.WarVKillWeight(), CBConfig.WarVKillCeiling());
  if take {
    lb.ClearWarHelp(gang);
  }
  return share;
}

// V put down one of a gang the crew is at war with (from the scoring of V's kills): it counts for the war, and the crew
// sees it. Fight the war yourself.
public func CBCrewWarNoteVKill(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Void {
  if !CBCrewAtWarWith(game, gang) {
    return;
  }
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) {
    return;
  }
  let n = lb.AddWarHelp(gang);
  if (n == 1 || n % 5 == 0) && CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), n == 1 ? CBT(n"Cyberbane-CrewWar-VJoined") : CBTf(n"Cyberbane-CrewWar-VKills", [s"\(n)"]), true);
  }
}

// V walks onto the streets of a gang the crew is at war with: the crew says so once, and the ones at that war can be
// called there (CBCrewAway lets them come while V is on that gang's ground).
func CBCrewWarHereTick(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>) -> Void {
  let wb = CBCrewWarBook.Get(game);
  if !IsDefined(wb) || wb.Count() == 0 {
    return;
  }
  let here = sys.GetCurrentDistrict();
  let i = 0;
  while i < wb.Count() {
    let gang = wb.Gang(i);
    if Equals(CBGangHomeDistrict(sys, game, gang), here) && !lb.WarHereSaid(gang) {
      lb.NoteWarHereSaid(gang);
      if CBMessagesOn() {
        CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-CrewWar-YouAreOnTheirStreets", [CBFactionLabel(gang)]), true);
      }
    }
    i += 1;
  }
}

// One of the crew away at a war can still be called to V on that war's own streets.
public func CBCrewWarHere(game: GameInstance, gang: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  return IsDefined(sys) && IsNameValid(gang) && Equals(CBGangHomeDistrict(sys, game, gang), sys.GetCurrentDistrict());
}

// ---- The street tax, in person ------------------------------------------------------------------------------------

// The day's tax from a district the crew holds (Model/CrewTurf.reds): half comes in through the crew, half the shops keep
// for V to collect, and they pay more when they fear V.
public func CBCrewTaxOwe(game: GameInstance, d: CName, amount: Int32) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) && IsNameValid(d) && amount > 0 {
    lb.AddTax(d, amount);
  }
}

// V in one of the crew's districts, close to a shopkeeper: they pay what they owe, and say so.
func CBCrewTaxCollectTick(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>) -> Void {
  let here = sys.GetCurrentDistrict();
  let owed = lb.TaxOwed(here);
  let player = GetPlayer(game);
  let reg = sys.GetRegistry();
  if owed <= 0 || !IsDefined(player) || !IsDefined(reg) || player.IsInCombat() || !CBCrewHoldsHere(sys, game) {
    return;
  }
  let ppos = player.GetWorldPosition();
  let shop: ref<ScriptedPuppet>;
  for p in reg.GetAll() {
    if !IsDefined(shop) && CBNpcSafe(sys, p) && !p.IsDead() && p.IsVendor()
       && Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.CrewTaxShopRange() {
      shop = p;
    }
  }
  if !IsDefined(shop) {
    return;
  }
  let ds = sys.FindDistrict(here);
  let fear = IsDefined(ds) ? ClampF(ds.renown / 100.0, 0.0, 1.0) : 0.0;
  let pay = RoundF(Cast<Float>(owed) * (1.0 + CBConfig.CrewTaxFearBonus() * fear));
  lb.ClearTax(here);
  CBStreetGiveMoney(game, pay);
  CBVoice(sys, game, shop, n"greeting", n"ShopPays", 30.0);
  CBOverheard(game, CBT(n"Cyberbane-CrewLife-Shopkeeper"), fear >= 0.4 ? CBTf(n"Cyberbane-CrewLife-TaxPaidScared", [s"\(pay)"])
                                                                         : CBTf(n"Cyberbane-CrewLife-TaxPaid", [s"\(pay)"]));
  CBFileLog(sys, n"CrewTax", CBGameSeconds(game), here, n"", Cast<Float>(pay));
  CBLog.Info(n"Crew", s"A shopkeeper paid V the crew's street tax in person: \(pay)eb.");
}

// ---- Counterattacks you can defend ---------------------------------------------------------------------------------

// The gang that lost a district to the crew is coming back at it (Model/Territory.reds): told ahead, with the place and the
// hour. True when it is now waiting for V, so the territory code does not take the ground at once.
public func CBCrewCounterattackTold(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, gang: CName) -> Bool {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) || !CBMyCrewOn() || (lb.CaState() == 1 || lb.CaState() == 2) {
    return false;
  }
  let ts = GameInstance.GetTimeSystem(game);
  let hour = IsDefined(ts) ? GameTime.Hours(ts.GetGameTime()) : 12;
  let ahead = CBConfig.CrewCounterAheadHours();
  let atHour = (hour + RoundF(ahead) + 1) % 24;
  let at = CBGameSeconds(game) + Cast<Float>(RoundF(ahead) + 1) * CBConfig.SecondsPerHour();
  lb.SetCa(district, gang, at, 1);
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-CrewLife-CounterComing", [CBCapFirst(CBFactionLabel(gang)), CBDistrictLabel(district), CBClockWordAt(atHour)]), true);
  }
  CBLog.Info(n"Crew", s"A counterattack on the crew's corners is coming: \(NameToString(gang)) in \(NameToString(district)).");
  return true;
}

func CBCrewCounterTick(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>) -> Void {
  let state = lb.CaState();
  if state != 1 && state != 2 {
    return;
  }
  let now = CBGameSeconds(game);
  let window = CBConfig.CrewCounterWindowHours() * CBConfig.SecondsPerHour();
  let d = lb.CaDistrict();
  let gang = lb.CaGang();
  if state == 1 && now >= lb.CaAt() {
    // V is there: the crew comes, and so do they.
    if Equals(sys.GetCurrentDistrict(), d) && CBWorldStable(game) && !CBArrivalsHeld(sys, game) {
      lb.SetCaState(2);
      if StrLen(CBCrewCallBlocked(sys, game, true)) == 0 {
        CBCrewCall(sys, game, true);
      }
      if !IsNameValid(sys.GetPendingSquadFaction()) {
        sys.SetPendingSquad(gang, CBConfig.CrewCounterArriveTicks());
      }
      if CBMessagesOn() {
        CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-CrewLife-CounterHere", [CBFactionLabel(gang)]), true, true);
      }
      CBLog.Info(n"Crew", "V is there for the counterattack on the crew's corners.");
      return;
    }
    if now > lb.CaAt() + window {
      CBCrewCounterLost(sys, game, lb);
    }
    return;
  }
  // Under way: past the window with nobody beaten is a stand-off, and the ground holds.
  if state == 2 && now > lb.CaAt() + window * 2.0 {
    lb.SetCaState(3);
    CBCrewTurfRaise(sys, game, d, CBConfig.CrewCounterHeldFoot() * 0.5);
  }
}

// Nobody came to hold the corners: they take ground, and the crew says so.
func CBCrewCounterLost(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>) -> Void {
  lb.SetCaState(4);
  let d = lb.CaDistrict();
  let gang = lb.CaGang();
  CBCrewTurfRaise(sys, game, d, -CBConfig.CrewCounterLostFoot());
  let tb = CBTurfBook.Get(game);
  if IsDefined(tb) {
    tb.AddLocalLoss(d, CBCrewTurfId(), CBConfig.TurfPushDamage(), CBGameSeconds(game));
  }
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-CrewLife-CounterLost", [CBCapFirst(CBFactionLabel(gang)), CBDistrictLabel(d)]), true);
  }
  CBLog.Info(n"Crew", "Nobody held the crew's corners: ground lost.");
}

// Their people beaten while V held the corners (from CBOnCrewBeaten): the ground holds and grows.
public func CBCrewCounterBeaten(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) || lb.CaState() != 2 || !Equals(lb.CaGang(), faction) {
    return;
  }
  lb.SetCaState(3);
  CBCrewTurfRaise(sys, game, lb.CaDistrict(), CBConfig.CrewCounterHeldFoot());
  if CBMessagesOn() {
    CBCrewText(sys, game, CBCrewSecond(game), CBTf(n"Cyberbane-CrewLife-CounterHeld", [CBDistrictLabel(lb.CaDistrict())]), true);
  }
  CBUiSound(game, n"ui_phone_incoming_call_positive", n"CounterHeld", 10.0);
  CBLog.Info(n"Crew", "The crew's corners held.");
}

// ---- Asks ----------------------------------------------------------------------------------------------------------

public func CBCrewAskWords(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>) -> String {
  if !IsDefined(lb) || lb.AskId() <= 0 {
    return "";
  }
  let kind = lb.AskKind();
  if kind == CBAskGun() { return CBT(n"Cyberbane-CrewLife-AskGunShort"); }
  if kind == CBAskRevenge() {
    let r = IsDefined(sys) ? sys.FindRivalById(lb.AskValue()) : null;
    return IsDefined(r) ? CBTf(n"Cyberbane-CrewLife-AskRevengeShort", [CBRivalDisplayName(sys.GetContent(), r)]) : "";
  }
  if kind == CBAskDayOff() { return CBT(n"Cyberbane-CrewLife-AskDayOffShort"); }
  if kind == CBAskCut() { return CBTf(n"Cyberbane-CrewLife-AskCutShort", [s"\(lb.AskValue())"]); }
  return "";
}

// Once a game day: maybe one of them asks for something. Never two asks at once, never from somebody hurt or away.
public func CBCrewLifeDaily(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(lb) || !IsDefined(book) || !CBMyCrewOn() || book.Count() == 0 {
    return;
  }
  let now = CBGameSeconds(game);
  if lb.AskId() > 0 || now < lb.AskNextAt() || RandF() >= CBConfig.CrewAskChance() {
    return;
  }
  let pick = RandRange(0, book.Count());
  let tries = 0;
  while tries < book.Count() {
    let m = book.At((pick + tries) % book.Count());
    tries += 1;
    if IsDefined(m) && !CBCrewHurt(m, now) && !CBCrewAway(game, m.id, now) {
      let kind = CBCrewAskFor(sys, game, lb, m);
      if kind != CBAskNone() {
        CBCrewStartAsk(sys, game, lb, m, kind, now);
        return;
      }
    }
  }
}

// What this one would ask for, by who they are and how things stand; none when nothing fits.
func CBCrewAskFor(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>, m: ref<CBCrewMember>) -> Int32 {
  let t = CBCrewTemper(m);
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  // A Rival who scarred them and is still out there.
  let scarRival = CBCrewScarRival(sys, game, lb, m);
  if scarRival > 0 && (t == CBTemperHothead() || RandF() < 0.5) {
    return CBAskRevenge();
  }
  if t == CBTemperMoney() || (IsDefined(kb) && kb.WarsWon() > 0 && RandF() < 0.3) {
    return CBAskCut();
  }
  if t == CBTemperCareful() || m.loyalty < 60 {
    return CBAskDayOff();
  }
  if !IsDefined(k) || !k.hasWeapon || k.weaponTier < 3 {
    return CBAskGun();
  }
  return scarRival > 0 ? CBAskRevenge() : CBAskNone();
}

// The newest Rival in their story who scarred them and still lives, 0 for none.
func CBCrewScarRival(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>, m: ref<CBCrewMember>) -> Int32 {
  let i = lb.HistCount() - 1;
  while i >= 0 {
    if lb.HistId(i) == m.id && lb.HistKind(i) == CBLifeScar() && lb.HistValue(i) > 0 {
      let r = sys.FindRivalById(lb.HistValue(i));
      if IsDefined(r) && r.state != EnumInt(ECBRivalState.Slain) {
        return r.id;
      }
    }
    i -= 1;
  }
  return 0;
}

func CBCrewStartAsk(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>, m: ref<CBCrewMember>, kind: Int32, now: Float) -> Void {
  let value = 0;
  let line = "";
  if kind == CBAskGun() {
    let kb = CBCrewKitBook.Get(game);
    let k = IsDefined(kb) ? kb.Find(m.id) : null;
    value = IsDefined(k) && k.hasWeapon ? k.weaponTier : -1;
    line = CBLineOf([CBT(n"Cyberbane-CrewLife-AskGun1"), CBT(n"Cyberbane-CrewLife-AskGun2")]);
  }
  if kind == CBAskRevenge() {
    value = CBCrewScarRival(sys, game, lb, m);
    let r = sys.FindRivalById(value);
    if !IsDefined(r) {
      return;
    }
    line = CBTf(n"Cyberbane-CrewLife-AskRevenge", [CBRivalDisplayName(sys.GetContent(), r)]);
  }
  if kind == CBAskDayOff() {
    line = CBLineOf([CBT(n"Cyberbane-CrewLife-AskDayOff1"), CBT(n"Cyberbane-CrewLife-AskDayOff2")]);
  }
  if kind == CBAskCut() {
    value = CBConfig.CrewAskCutBase() + CBConfig.CrewAskCutPerRank() * CBCrewRankOf(game, m);
    line = CBTf(n"Cyberbane-CrewLife-AskCut", [s"\(value)"]);
  }
  lb.SetAsk(m.id, kind, now + CBConfig.CrewAskDays() * CBConfig.SecondsPerDay(), value);
  CBLog.Info(n"Crew", s"One of V's crew asked for something (kind \(kind)).");
  if CBMessagesOn() {
    CBCrewText(sys, game, m, line + " " + CBT(n"Cyberbane-CrewLife-AskWhere"));
  }
}

// It was done: a weapon handed over, the Rival dead, the day off given, the cut paid.
public func CBCrewAskDone(sys: ref<CyberbaneSystem>, game: GameInstance, kind: Int32, id: Int32, value: Int32) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(lb) || !IsDefined(book) || lb.AskKind() != kind || lb.AskId() <= 0 {
    return;
  }
  if kind == CBAskRevenge() {
    if lb.AskValue() != value {
      return;
    }
  } else {
    if lb.AskId() != id {
      return;
    }
  }
  if kind == CBAskGun() && value <= lb.AskValue() {
    return;   // no better than what they carried
  }
  let m = book.Find(lb.AskId());
  lb.ClearAsk();
  lb.SetAskNextAt(CBGameSeconds(game) + CBConfig.CrewAskGapDays() * CBConfig.SecondsPerDay());
  if !IsDefined(m) {
    return;
  }
  CBCrewLoyalty(m, CBConfig.CrewAskDoneLoyalty(), CBCrewWhyAsked());
  CBCrewLifeNote(game, m.id, CBLifeAskDone(), CBEventDistrict(sys, game), kind);
  if CBMessagesOn() {
    let line = kind == CBAskRevenge() ? CBT(n"Cyberbane-CrewLife-AskRevengeDone") : CBLineOf([CBT(n"Cyberbane-CrewLife-AskDone1"), CBT(n"Cyberbane-CrewLife-AskDone2")]);
    CBCrewText(sys, game, m, line);
  }
}

// A Rival is dead: revenge for whoever asked it (from CBRivalSlain, whoever's hand it was).
public func CBCrewLifeRivalDied(game: GameInstance, rivalId: Int32) -> Void {
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) && rivalId > 0 {
    CBCrewAskDone(sys, game, CBAskRevenge(), 0, rivalId);
  }
}

// A day off, given from the Hub: away for a day, and the ask (if it was theirs) answered.
public func CBCrewGiveDayOff(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) || !IsDefined(m) {
    return;
  }
  lb.SetRest(m.id, CBGameSeconds(game) + CBConfig.SecondsPerDay());
  CBCrewAskDone(sys, game, CBAskDayOff(), m.id, 0);
  CBMenuNote(game, CBTf(n"Cyberbane-CrewLife-DayOffGiven", [CBCrewFirst(sys, m)]), 4.0);
}

// The cut they asked for, paid from the Hub.
public func CBCrewPayAsk(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  if !IsDefined(lb) || !IsDefined(m) || lb.AskId() != m.id || lb.AskKind() != CBAskCut() {
    return;
  }
  let owed = lb.AskValue();
  if !CBTalkTakeMoney(game, GetPlayer(game), owed) {
    CBMenuNote(game, CBTf(n"Cyberbane-Crew-YouDonTHaveEb", [s"\(owed)"]), 4.0);
    return;
  }
  CBCrewLoyalty(m, CBConfig.MyCrewFairCut(), CBCrewWhyPaid());
  CBCrewAskDone(sys, game, CBAskCut(), m.id, 0);
}

public func CBCrewResting(game: GameInstance, id: Int32, now: Float) -> Bool {
  let lb = CBCrewLifeBook.Get(game);
  return IsDefined(lb) && lb.RestUntil(id) > now;
}

// ---- Funerals ------------------------------------------------------------------------------------------------------

// One of them died: the crew buries them a day later in their home district, in the evening (CBCrewLifeTick).
public func CBCrewLifeFell(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, district: CName) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(lb) || !IsDefined(m) || !CBMyCrewOn() {
    return;
  }
  // Somebody to bury them: the crew needs at least one other member.
  if !IsDefined(book) || book.Count() <= 1 {
    lb.Forget(m.id);
    return;
  }
  let place = IsNameValid(m.home) ? m.home : district;
  let ts = GameInstance.GetTimeSystem(game);
  let now = CBGameSeconds(game);
  let hour = IsDefined(ts) ? GameTime.Hours(ts.GetGameTime()) : 12;
  // Tomorrow at the funeral hour.
  let at = now + Cast<Float>(24 - hour + CBConfig.CrewFuneralHour()) * CBConfig.SecondsPerHour();
  lb.OweFuneral(m.id, place, at);
  lb.Forget(m.id);
  if CBMessagesOn() {
    let speaker = CBCrewSecond(game);
    let line = CBTf(n"Cyberbane-CrewLife-FuneralSet", [CBCrewFirst(sys, m), CBClockWordAt(CBConfig.CrewFuneralHour()), CBDistrictLabel(place)]);
    CBCrewText(sys, game, IsDefined(speaker) && speaker.id != m.id ? speaker : null, line, true);
    CBCrewGroupReplies(sys, game, 3, m.id);   // and the rest answer (2.7.7)
  }
}

// The hour as the street says it, "20:00".
func CBClockWordAt(hour: Int32) -> String {
  return (hour < 10 ? "0" : "") + IntToString(hour) + ":00";
}

// The funeral's window: V in the district while it is on is V there.
func CBCrewFuneralTick(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>, book: ref<CBCrewBook>) -> Void {
  if lb.FuneralState() != 1 {
    return;
  }
  let now = CBGameSeconds(game);
  if now < lb.FuneralAt() {
    return;
  }
  let window = CBConfig.CrewFuneralWindowHours() * CBConfig.SecondsPerHour();
  if now > lb.FuneralAt() + window {
    lb.SetFuneralState(3);
    let i = 0;
    while i < book.Count() {
      CBCrewLoyalty(book.At(i), -CBConfig.CrewFuneralMissLoyalty(), CBCrewWhyMourned());
      i += 1;
    }
    if CBMessagesOn() {
      let speaker = CBCrewSecond(game);
      CBCrewText(sys, game, speaker, CBLineOf([CBT(n"Cyberbane-CrewLife-FuneralMissed1"), CBT(n"Cyberbane-CrewLife-FuneralMissed2")]), true);
    }
    CBLog.Info(n"Crew", "V missed a crew funeral.");
    return;
  }
  if !Equals(sys.GetCurrentDistrict(), lb.FuneralDistrict()) || !CBWorldStable(game) {
    return;
  }
  // V came. The ones free to come stand with V a while (the crew's own call, to walk with V), and say so.
  lb.SetFuneralState(2);
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    CBCrewLoyalty(m, CBConfig.CrewFuneralLoyalty(), CBCrewWhyMourned());
    if IsDefined(m) {
      CBCrewLifeNote(game, m.id, CBLifeMourned(), lb.FuneralDistrict(), lb.FuneralPast());
    }
    i += 1;
  }
  if !lb.funeralCalled && book.OutCount() == 0 && StrLen(CBCrewCallBlocked(sys, game, true)) == 0 {
    lb.funeralCalled = true;
    CBCrewCall(sys, game, true);
  }
  if CBMessagesOn() {
    let speaker = CBCrewSecond(game);
    CBCrewText(sys, game, speaker, CBLineOf([CBT(n"Cyberbane-CrewLife-FuneralCame1"), CBT(n"Cyberbane-CrewLife-FuneralCame2")]), true);
  }
  CBLog.Info(n"Crew", "V came to a crew funeral.");
}

// ---- Every tick ----------------------------------------------------------------------------------------------------

public func CBCrewLifeTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let lb = CBCrewLifeBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(lb) || !IsDefined(book) {
    return;
  }
  if ArraySize(lb.batchId) > 0 {
    CBCrewBatchFlush(sys, game, lb, book);
  }
  if sys.GetTickCount() % 5 != 3 {
    return;
  }
  CBCrewFuneralTick(sys, game, lb, book);
  CBCrewWarHereTick(sys, game, lb);
  CBCrewTaxCollectTick(sys, game, lb);
  CBCrewCounterTick(sys, game, lb);
  CBCrewFrontPinsTick(sys, game, lb);
  CBCrewLoiterTick(sys, game);
  // An ask left too long: they notice.
  let now = CBGameSeconds(game);
  if lb.AskId() > 0 && now > lb.AskUntil() {
    let m = book.Find(lb.AskId());
    let kind = lb.AskKind();
    lb.ClearAsk();
    lb.SetAskNextAt(now + CBConfig.CrewAskGapDays() * CBConfig.SecondsPerDay());
    if IsDefined(m) {
      CBCrewLoyalty(m, -CBConfig.CrewAskIgnoredLoyalty(), CBCrewWhyAsked());
      CBCrewLifeNote(game, m.id, CBLifeAskIgnored(), n"", kind);
      if CBMessagesOn() {
        CBCrewText(sys, game, m, CBLineOf([CBT(n"Cyberbane-CrewLife-AskIgnored1"), CBT(n"Cyberbane-CrewLife-AskIgnored2")]));
      }
    }
  }
}

// ---- The crew's home ----------------------------------------------------------------------------------------------

// Hurt, they heal faster with a bed at the crew's home: their time out is cut once, when they get back (CBCrewEndCall).
public func CBCrewHomeHealFactor(game: GameInstance) -> Float {
  let lb = CBCrewLifeBook.Get(game);
  return IsDefined(lb) && lb.HomeSet() ? CBConfig.CrewHomeHealFactor() : 1.0;
}

// ---- The group chat answers itself ---------------------------------------------------------------------------------

// After a war or a death (2.7.7), two or three of them reply to each other in the group chat, each as who they are, rather
// than one line and silence. `kind`: 1 a war won, 2 a war lost, 3 one of them dead. `skip` is somebody not to speak.
public func CBCrewGroupReplies(sys: ref<CyberbaneSystem>, game: GameInstance, kind: Int32, skip: Int32) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !CBMessagesOn() || book.Count() < 2 {
    return;
  }
  let said = 0;
  let start = RandRange(0, book.Count());
  let i = 0;
  while i < book.Count() && said < CBConfig.CrewGroupReplies() {
    let m = book.At((start + i) % book.Count());
    i += 1;
    if IsDefined(m) && m.id != skip {
      let line = CBCrewReplyLine(m, kind, said);
      if StrLen(line) > 0 {
        CBCrewText(sys, game, m, line, true);
        said += 1;
      }
    }
  }
}

func CBCrewReplyLine(m: ref<CBCrewMember>, kind: Int32, nth: Int32) -> String {
  let t = CBCrewTemper(m);
  if kind == 1 {
    if t == CBTemperHothead() { return CBT(n"Cyberbane-CrewLife-ReplyWonHot"); }
    if t == CBTemperMoney() { return CBT(n"Cyberbane-CrewLife-ReplyWonMoney"); }
    if t == CBTemperOldGang() { return CBT(n"Cyberbane-CrewLife-ReplyWonOld"); }
    return nth == 0 ? CBT(n"Cyberbane-CrewLife-ReplyWonCareful") : CBT(n"Cyberbane-CrewLife-ReplyWonPlain");
  }
  if kind == 2 {
    if t == CBTemperHothead() { return CBT(n"Cyberbane-CrewLife-ReplyLostHot"); }
    if t == CBTemperCareful() { return CBT(n"Cyberbane-CrewLife-ReplyLostCareful"); }
    if t == CBTemperMoney() { return CBT(n"Cyberbane-CrewLife-ReplyLostMoney"); }
    return CBT(n"Cyberbane-CrewLife-ReplyLostPlain");
  }
  if kind == 3 {
    if t == CBTemperHothead() { return CBT(n"Cyberbane-CrewLife-ReplyDeadHot"); }
    if t == CBTemperCareful() { return CBT(n"Cyberbane-CrewLife-ReplyDeadCareful"); }
    if t == CBTemperOldGang() { return CBT(n"Cyberbane-CrewLife-ReplyDeadOld"); }
    return nth == 0 ? CBT(n"Cyberbane-CrewLife-ReplyDeadPlain") : CBT(n"Cyberbane-CrewLife-ReplyDeadMoney");
  }
  return "";
}

// ---- War fronts on the map -----------------------------------------------------------------------------------------

// A place the street knows in this district (Model/StreetBook.reds), for a pin there; false when none is known yet.
public func CBPlaceInDistrict(game: GameInstance, d: CName, out at: Vector4) -> Bool {
  let book = CBStreetBook.Get(game);
  if !IsDefined(book) || !IsNameValid(d) {
    return false;
  }
  let i = 0;
  while i < book.PlaceCount() {
    if Equals(book.PlaceDistrict(i), d) {
      at = book.PlacePos(i);
      return true;
    }
    i += 1;
  }
  return false;
}

// A pin for each of the crew's wars, on the gang's own streets, and one for a counterattack coming; each taken down when it
// is over. Session pins, put back after a load.
func CBCrewFrontPinsTick(sys: ref<CyberbaneSystem>, game: GameInstance, lb: ref<CBCrewLifeBook>) -> Void {
  if !CBWorldStable(game) {
    return;
  }
  let wantKey: array<CName>;
  let wantAt: array<Vector4>;
  let wantText: array<String>;
  let wb = CBCrewWarBook.Get(game);
  if IsDefined(wb) {
    let i = 0;
    while i < wb.Count() {
      let gang = wb.Gang(i);
      let at: Vector4;
      if CBPlaceInDistrict(game, CBGangHomeDistrict(sys, game, gang), at) {
        ArrayPush(wantKey, gang);
        ArrayPush(wantAt, at);
        ArrayPush(wantText, CBTf(n"Cyberbane-CrewLife-WarFrontPin", [CBCapFirst(CBFactionLabel(gang))]));
      }
      i += 1;
    }
  }
  if lb.CaState() == 1 || lb.CaState() == 2 {
    let ca: Vector4;
    if CBPlaceInDistrict(game, lb.CaDistrict(), ca) {
      ArrayPush(wantKey, n"CB_Counter");
      ArrayPush(wantAt, ca);
      ArrayPush(wantText, CBTf(n"Cyberbane-CrewLife-CounterPin", [CBCapFirst(CBFactionLabel(lb.CaGang()))]));
    }
  }
  // Down: what is no longer wanted.
  let k = ArraySize(lb.frontKey) - 1;
  while k >= 0 {
    if !ArrayContains(wantKey, lb.frontKey[k]) {
      CBUnpinPlace(game, lb.frontPin[k]);
      ArrayErase(lb.frontKey, k);
      ArrayErase(lb.frontPin, k);
    }
    k -= 1;
  }
  // Up: what is wanted and not pinned yet.
  let w = 0;
  while w < ArraySize(wantKey) {
    if !ArrayContains(lb.frontKey, wantKey[w]) {
      let id: NewMappinID;
      if CBPinPlace(game, wantAt[w], wantText[w], id) {
        ArrayPush(lb.frontKey, wantKey[w]);
        ArrayPush(lb.frontPin, id);
      }
    }
    w += 1;
  }
}
