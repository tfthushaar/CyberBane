// Cyberbane - Kitting out the crew
//
// V's crew, made V's own: a weapon handed over from V's inventory, chrome V owns and does not wear, training that
// brings them back stronger, a war on a gang sent with somebody senior, and a name for the crew itself. All of it
// asked for on the Hub's Crew page and carried out on the game's tick (CBCrewKitService), never from the menu.

// One member's kit.
public class CBCrewKit {
  public persistent let id: Int32;
  public persistent let hasWeapon: Bool;
  public persistent let weapon: ItemID;
  public persistent let weaponType: Int32;    // gamedataItemType, as a number
  public persistent let weaponTier: Int32;    // 0 common .. 4 legendary or iconic
  // The chrome put in them, up to CBCrewChromeSlots, as four scalars.
  public persistent let chrome0: TweakDBID;
  public persistent let chrome1: TweakDBID;
  public persistent let chrome2: TweakDBID;
  public persistent let chrome3: TweakDBID;
  public persistent let trained: Int32;       // trainings finished
  public persistent let trainUntil: Float;    // game seconds; 0 when not away training
  public persistent let warUntil: Float;      // game seconds; 0 when not away at war
  public persistent let warOn: CName;         // the gang they went to war on
  public persistent let spars: Int32;         // rounds sparred with V
  public persistent let sparDay: Int32;       // the game day of the last, stored one up
  public persistent let sharpUntil: Float;    // a spar's edge, until then
  public persistent let earning: Bool;        // put to work

  public func ChromeCount() -> Int32 {
    let n = 0;
    let i = 0;
    while i < CBCrewChromeSlots() {
      if TDBID.IsValid(this.ChromeAt(i)) {
        n += 1;
      }
      i += 1;
    }
    return n;
  }

  public func ChromeAt(i: Int32) -> TweakDBID {
    if i == 0 { return this.chrome0; }
    if i == 1 { return this.chrome1; }
    if i == 2 { return this.chrome2; }
    if i == 3 { return this.chrome3; }
    return TDBID.None();
  }

  // Into the first empty slot. False when every slot is taken.
  public func AddChrome(rec: TweakDBID) -> Bool {
    if !TDBID.IsValid(this.chrome0) { this.chrome0 = rec; return true; }
    if !TDBID.IsValid(this.chrome1) { this.chrome1 = rec; return true; }
    if !TDBID.IsValid(this.chrome2) { this.chrome2 = rec; return true; }
    if !TDBID.IsValid(this.chrome3) { this.chrome3 = rec; return true; }
    return false;
  }
}

// How many implants a crew member can carry: the four fields above, or fewer if the setting asks.
public func CBCrewChromeSlots() -> Int32 {
  return Clamp(CBConfig.CrewChromeMax(), 0, 4);
}

// One order asked for on the Hub, for one member, carried out on the next tick. Each member's orders are their own: one
// slot for everybody gave the first one's order to the next one picked.
public class CBCrewKitAsk {
  public let member: Int32;
  public let what: Int32;     // CBCrewAskGive .. CBCrewAskWork
  public let item: ItemID;    // the weapon or the chrome
  public let gang: CName;     // the war's gang, or a job's
  public let rival: Int32;    // a hit's Rival
}

public func CBCrewAskGive() -> Int32 = 1
public func CBCrewAskTakeBack() -> Int32 = 2
public func CBCrewAskChrome() -> Int32 = 3
public func CBCrewAskTrain() -> Int32 = 4
public func CBCrewAskWar() -> Int32 = 5
public func CBCrewAskSpar() -> Int32 = 6
public func CBCrewAskWork() -> Int32 = 7

public class CBCrewKitBook extends ScriptableSystem {
  private persistent let m_kits: array<ref<CBCrewKit>>;
  private persistent let m_name: array<Int32>;    // the crew's name, as places in CBCrewNameAlphabet, one up
  private persistent let m_warsWon: Int32;
  private persistent let m_earnDay: Int32;   // the last game day the earners were paid, stored one up
  // A spar under way (session only: a load ends it).
  public let sparMember: Int32;
  public let sparBody: EntityID;
  public let sparStart: Int32;     // the tick it was asked for
  public let sparSeen: Int32;      // the tick their body was first in the world, 0 before
  // The body of a round just over, walking off: its member is not called again until it is gone, or two of the same
  // person stand in the street.
  public let sparLeftMember: Int32;
  public let sparLeftBody: EntityID;
  // Asked for on the Hub: a spar on the next tick (CBCrewKitService), the rest at once (CBCrewKitDoNow).
  public let asks: array<ref<CBCrewKitAsk>>;
  // Texts from orders carried out while the Hub is open, sent on the next tick (CBCrewText). Session only.
  public let deferTexts: Bool;
  public let laterWho: array<Int32>;
  public let laterLines: array<String>;
  public let laterGroup: array<Bool>;   // for the crew's group chat rather than their own thread

  public static func Get(game: GameInstance) -> ref<CBCrewKitBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewKitBook") as CBCrewKitBook : null;
  }

  // A load starts the session over, as the crew's other books do: a spar under way went with the world the save threw
  // away (left set, the next tick scored a round nobody fought), and nothing asked on a Hub carries into another save.
  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.sparMember = 0;
    let none: EntityID;
    this.sparBody = none;
    this.sparStart = 0;
    this.sparSeen = 0;
    this.sparLeftMember = 0;
    this.sparLeftBody = none;
    ArrayClear(this.asks);
    this.deferTexts = false;
    ArrayClear(this.laterWho);
    ArrayClear(this.laterLines);
    ArrayClear(this.laterGroup);   // kept, it put the next lines in the wrong chat
  }

  public func Find(id: Int32) -> ref<CBCrewKit> {
    for k in this.m_kits {
      if IsDefined(k) && k.id == id {
        return k;
      }
    }
    return null;
  }

  public func Kit(id: Int32) -> ref<CBCrewKit> {
    let k = this.Find(id);
    if !IsDefined(k) {
      k = new CBCrewKit();
      k.id = id;
      ArrayPush(this.m_kits, k);
    }
    return k;
  }

  public func Forget(id: Int32) -> Void {
    let i = 0;
    while i < ArraySize(this.m_kits) {
      if IsDefined(this.m_kits[i]) && this.m_kits[i].id == id {
        ArrayErase(this.m_kits, i);
        return;
      }
      i += 1;
    }
  }

  public func Clear() -> Void {
    ArrayClear(this.m_kits);
    ArrayClear(this.m_name);
    this.m_warsWon = 0;
    this.m_earnDay = 0;
    this.sparMember = 0;
    this.sparLeftMember = 0;
    ArrayClear(this.asks);
  }

  // An order for a member, in place of any of the same kind already asked for them.
  public func Ask(member: Int32, what: Int32, item: ItemID, gang: CName, opt rival: Int32) -> Void {
    if member <= 0 {
      return;
    }
    this.Unask(member, what);
    let a = new CBCrewKitAsk();
    a.member = member;
    a.what = what;
    a.item = item;
    a.gang = gang;
    a.rival = rival;
    ArrayPush(this.asks, a);
  }

  // Taken back before it was carried out.
  public func Unask(member: Int32, what: Int32) -> Void {
    let i = ArraySize(this.asks) - 1;
    while i >= 0 {
      if IsDefined(this.asks[i]) && this.asks[i].member == member && this.asks[i].what == what {
        ArrayErase(this.asks, i);
      }
      i -= 1;
    }
  }

  public func Asked(member: Int32, what: Int32) -> Bool {
    for a in this.asks {
      if IsDefined(a) && a.member == member && a.what == what {
        return true;
      }
    }
    return false;
  }

  // A weapon or an implant already asked to go to one of them: not offered twice.
  public func ItemAsked(item: ItemID) -> Bool {
    for a in this.asks {
      if IsDefined(a) && (a.what == CBCrewAskGive() || a.what == CBCrewAskChrome()) && Equals(a.item, item) {
        return true;
      }
    }
    return false;
  }

  public func EarnDay() -> Int32 {
    return this.m_earnDay;
  }

  public func SetEarnDay(day: Int32) -> Void {
    this.m_earnDay = day;
  }

  public func WarsWon() -> Int32 {
    return this.m_warsWon;
  }

  public func NoteWarWon() -> Void {
    this.m_warsWon += 1;
  }

  public func Name() -> String {
    let a = CBCrewNameAlphabet();
    let out = "";
    for c in this.m_name {
      if c > 0 && c <= StrLen(a) {
        out += StrMid(a, c - 1, 1);
      }
    }
    return out;
  }

  // Letters from the set only, at most CrewNameMaxLength, spaces at the ends trimmed. "" clears it.
  public func SetName(text: String) -> Void {
    ArrayClear(this.m_name);
    let a = CBCrewNameAlphabet();
    let trimmed = CBCrewNameTrim(text);
    let i = 0;
    while i < StrLen(trimmed) && ArraySize(this.m_name) < CBConfig.CrewNameMaxLength() {
      let at = StrFindFirst(a, StrMid(trimmed, i, 1));
      if at >= 0 {
        ArrayPush(this.m_name, at + 1);
      }
      i += 1;
    }
  }
}

// What a crew's name may be made of.
public func CBCrewNameAlphabet() -> String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -'.&!"

func CBCrewNameTrim(text: String) -> String {
  let s = text;
  while StrLen(s) > 0 && Equals(StrLeft(s, 1), " ") {
    s = StrRight(s, StrLen(s) - 1);
  }
  while StrLen(s) > 0 && Equals(StrRight(s, 1), " ") {
    s = StrLeft(s, StrLen(s) - 1);
  }
  return s;
}

// The crew's name, or "" when V has not given it one.
public func CBCrewNameOf(game: GameInstance) -> String {
  let kb = CBCrewKitBook.Get(game);
  return IsDefined(kb) ? kb.Name() : "";
}

// ---- Rank ----------------------------------------------------------------------------------------

// Their wins and their training together, 1 to 6.
public func CBCrewRankOf(game: GameInstance, m: ref<CBCrewMember>) -> Int32 {
  if !IsDefined(m) {
    return 1;
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  return Min(6, CBCrewRank(m.wins) + (IsDefined(k) ? k.trained : 0));
}

// Where they stand on the climb, for a card or a row: "Veteran 3/6".
public func CBCrewRankShort(game: GameInstance, m: ref<CBCrewMember>) -> String {
  let rank = CBCrewRankOf(game, m);
  return s"\(CBCrewRankWord(rank)) \(rank)/6";
}

// The fights won it takes to reach this rank by wins alone (Reactions/Crew.reds, CBCrewRank).
func CBCrewWinsFor(rank: Int32) -> Int32 {
  if rank <= 2 { return CBCrewPaceWins(3); }
  if rank == 3 { return CBCrewPaceWins(7); }
  return CBCrewPaceWins(12);
}

// What it takes to reach the next rank, said plainly: Every way there is, from their wins and their training as they
// are now.
public func CBCrewNextRankLine(game: GameInstance, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let rank = CBCrewRankOf(game, m);
  if rank >= 6 {
    return CBT(n"Cyberbane-CrewKit-LegendTheTopOfTheClimb");
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  let trained = IsDefined(k) ? k.trained : 0;
  let spars = IsDefined(k) ? k.spars : 0;
  let ways = "";
  let winRank = CBCrewRank(m.wins);
  if winRank < 4 {
    let need = Max(1, CBCrewWinsFor(winRank + 1) - m.wins);
    ways = need == 1 ? CBT(n"Cyberbane-CrewKit-1MoreFightWon") : CBTf(n"Cyberbane-CrewKit-MoreFightsWon", [s"\(need)"]);
  }
  if trained < CBConfig.CrewTrainMax() {
    let left = CBConfig.CrewSparsPerTraining() - spars % CBConfig.CrewSparsPerTraining();
    let train = CBTf(n"Cyberbane-CrewKit-ATrainingMoreSparCountAs", [s"\(left)", (left == 1 ? "" : "s")]);
    ways = StrLen(ways) > 0 ? CBTf(n"Cyberbane-CrewKit-Or", [ways, train]) : train;
  }
  if StrLen(ways) == 0 {
    return "";
  }
  return CBTf(n"Cyberbane-CrewKit-Next", [s"\(CBCrewRankWord(rank + 1))", s"\(ways)"]);
}

public func CBCrewRankWord(rank: Int32) -> String {
  if rank >= 6 { return CBT(n"Cyberbane-CrewKit-Legend"); }
  if rank == 5 { return CBT(n"Cyberbane-CrewKit-Enforcer"); }
  if rank == 4 { return CBT(n"Cyberbane-CrewKit-Lieutenant"); }
  if rank == 3 { return CBT(n"Cyberbane-CrewKit-Veteran"); }
  if rank == 2 { return CBT(n"Cyberbane-CrewKit-Soldier"); }
  return CBT(n"Cyberbane-CrewKit-Rookie");
}

// ---- Weapons and chrome, read from V's inventory --------------------------------------------------

// How somebody fights with a weapon of this kind: 0 heavy, 1 shooter, 2 blade; -1 for anything that is not a weapon a
// person carries into a street fight (fists, a car's guns).
public func CBCrewSeatForWeapon(t: gamedataItemType) -> Int32 {
  switch t {
    case gamedataItemType.Wea_LightMachineGun:
    case gamedataItemType.Wea_HeavyMachineGun:
    case gamedataItemType.Wea_Shotgun:
    case gamedataItemType.Wea_ShotgunDual:
    case gamedataItemType.Wea_GrenadeLauncher:
      return 0;
    case gamedataItemType.Wea_AssaultRifle:
    case gamedataItemType.Wea_Rifle:
    case gamedataItemType.Wea_PrecisionRifle:
    case gamedataItemType.Wea_SniperRifle:
    case gamedataItemType.Wea_Handgun:
    case gamedataItemType.Wea_Revolver:
    case gamedataItemType.Wea_SubmachineGun:
      return 1;
    case gamedataItemType.Wea_Katana:
    case gamedataItemType.Wea_Knife:
    case gamedataItemType.Wea_ShortBlade:
    case gamedataItemType.Wea_LongBlade:
    case gamedataItemType.Wea_Machete:
    case gamedataItemType.Wea_Sword:
    case gamedataItemType.Wea_Chainsword:
    case gamedataItemType.Wea_Axe:
    case gamedataItemType.Wea_Hammer:
    case gamedataItemType.Wea_OneHandedClub:
    case gamedataItemType.Wea_TwoHandedClub:
      return 2;
  }
  return -1;
}

// 0 common.. 4 legendary or iconic, read off the quality's name so every "Plus" lands with its own.
public func CBCrewTierOf(q: gamedataQuality) -> Int32 {
  let n = EnumValueToString(CBT(n"Cyberbane-CrewKit-GamedataQuality"), Cast<Int64>(EnumInt(q)));
  if StrContains(n, "Legendary") || StrContains(n, "Iconic") { return 4; }
  if StrContains(n, "Epic") { return 3; }
  if StrContains(n, "Rare") { return 2; }
  if StrContains(n, "Uncommon") { return 1; }
  return 0;
}

public func CBCrewTierWord(tier: Int32) -> String {
  if tier >= 4 { return CBT(n"Cyberbane-CrewKit-Legendary"); }
  if tier == 3 { return CBT(n"Cyberbane-CrewKit-Epic"); }
  if tier == 2 { return CBT(n"Cyberbane-CrewKit-Rare"); }
  if tier == 1 { return CBT(n"Cyberbane-CrewKit-Uncommon"); }
  return CBT(n"Cyberbane-CrewKit-Common");
}

public func CBCrewItemName(id: TweakDBID) -> String {
  let rec = TweakDBInterface.GetItemRecord(id);
  if !IsDefined(rec) {
    return CBT(n"Cyberbane-CrewKit-Something");
  }
  let n = GetLocalizedTextByKey(rec.DisplayName());
  return StrLen(n) > 0 ? n : CBT(n"Cyberbane-CrewKit-Something");
}

// What V carries that a crew member could use: unequipped weapons of a kind people fight with, never a quest item.
public func CBCrewWeaponChoices(game: GameInstance) -> array<ItemID> {
  let out: array<ItemID>;
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return out;
  }
  let items: array<wref<gameItemData>>;
  ts.GetItemListByTag(player, n"Weapon", items);
  for d in items {
    if IsDefined(d) && !d.HasTag(n"Quest") && CBCrewSeatForWeapon(d.GetItemType()) >= 0
       && !RPGManager.IsItemEquipped(player, d.GetID()) && ArraySize(out) < CBConfig.CrewPickListMax() {
      ArrayPush(out, d.GetID());
    }
  }
  // And the stash's, when V is at it (Reactions/CrewHome.reds).
  for s in CBArmoryChoices(game) {
    if ArraySize(out) < CBConfig.CrewPickListMax() {
      ArrayPush(out, s);
    }
  }
  return out;
}

// Chrome V owns and is not wearing, that would do something for one of the crew in a fight (CBCrewChromeRead).
public func CBCrewChromeChoices(game: GameInstance) -> array<ItemID> {
  let out: array<ItemID>;
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return out;
  }
  let items: array<wref<gameItemData>>;
  ts.GetItemListByTag(player, n"Cyberware", items);
  for d in items {
    if IsDefined(d) && !d.HasTag(n"Quest") && !RPGManager.IsItemEquipped(player, d.GetID())
       && CBCrewChromeRead(ItemID.GetTDBID(d.GetID())).Any() && ArraySize(out) < CBConfig.CrewPickListMax() {
      ArrayPush(out, d.GetID());
    }
  }
  return out;
}

// ---- Chrome: what each piece does for them, by the game's numbers ------------------------------------
//
// It sorted implants into five rough kinds by where they go (armour, health, damage, critical hits, hack resistance),
// so a Mechatronic Core, which makes whoever wears it hit drones, mechs and robots harder, read as hack resistance.
public class CBCrewChromeEffect {
  public let stats: array<gamedataStatType>;
  public let types: array<gameStatModifierType>;
  public let values: array<Float>;
  public let critChance: Float;   // percent, as the game keeps it
  public let critDamage: Float;   // percent
  public let headshot: Float;     // the multiplier's gain: 0.3 for x1.3
  public let weakspot: Float;
  public let speed: Float;        // attack speed's gain
  public let armourMult: Float;   // the armour multiplier's gain
  public let abilities: array<TweakDBID>;
  public let words: array<String>;
  // Arm cyberware: the kind of fighter it makes them, as a signature kind (Rivals/Signature.reds): 1 mantis blades or a
  // monowire, 2 gorilla arms, 3 a projectile launcher's heavy. 0 for anything else.
  public let style: Int32;

  public func Any() -> Bool {
    return ArraySize(this.stats) > 0 || ArraySize(this.abilities) > 0 || this.critChance > 0.0 || this.critDamage > 0.0
        || this.headshot > 0.0 || this.weakspot > 0.0 || this.speed > 0.0 || this.armourMult > 0.0 || this.style > 0;
  }

  public func Say(w: String) -> Void {
    if !ArrayContains(this.words, w) {
      ArrayPush(this.words, w);
    }
  }
}

// The implant's quality as the two stats its own numbers lean on: Quality 0 (common) to 4 (legendary), and IsItemPlus
// 0, 1 or 2 (items/quality/quality.tweak).
func CBCrewQualityOf(rec: ref<Item_Record>, out quality: Float, out plus: Float) -> Void {
  quality = 0.0;
  plus = 0.0;
  let qr = IsDefined(rec) ? rec.Quality() : null;
  if !IsDefined(qr) {
    return;
  }
  switch qr.Type() {
    case gamedataQuality.CommonPlus: plus = 1.0; break;
    case gamedataQuality.Uncommon: quality = 1.0; break;
    case gamedataQuality.UncommonPlus: quality = 1.0; plus = 1.0; break;
    case gamedataQuality.Rare: quality = 2.0; break;
    case gamedataQuality.RarePlus: quality = 2.0; plus = 1.0; break;
    case gamedataQuality.Epic: quality = 3.0; break;
    case gamedataQuality.EpicPlus: quality = 3.0; plus = 1.0; break;
    case gamedataQuality.Legendary: quality = 4.0; break;
    case gamedataQuality.Iconic: quality = 4.0; break;
    case gamedataQuality.LegendaryPlus: quality = 4.0; plus = 1.0; break;
    case gamedataQuality.LegendaryPlusPlus: quality = 4.0; plus = 2.0; break;
  }
}

// One of the implant's stat modifiers, sorted into what it does for them.
func CBCrewChromeTake(e: ref<CBCrewChromeEffect>, mod: wref<StatModifier_Record>, quality: Float, plus: Float) -> Void {
  if !IsDefined(mod) || !IsDefined(mod.StatType()) {
    return;
  }
  let value = 0.0;
  let constant = mod as ConstantStatModifier_Record;
  if IsDefined(constant) {
    value = constant.Value();
  } else {
    // A share by the implant's own quality ("value * Quality", "value * IsItemPlus") is the item's, so it is known here.
    // Anything leaning on V (an attribute of V's, refObject Player) is V's and left out.
    let combined = mod as CombinedStatModifier_Record;
    if !IsDefined(combined) || !IsDefined(combined.RefStat()) || NotEquals(combined.OpSymbol(), n"*")
       || Equals(combined.RefObject(), n"Player") {
      return;
    }
    let by = combined.RefStat().StatType();
    if Equals(by, gamedataStatType.Quality) {
      value = combined.Value() * quality;
    } else {
      if Equals(by, gamedataStatType.IsItemPlus) {
        value = combined.Value() * plus;
      } else {
        return;
      }
    }
  }
  if value == 0.0 {
    return;
  }
  let kind = mod.ModifierType();
  let modType = gameStatModifierType.Additive;
  if Equals(kind, n"Multiplier") {
    modType = gameStatModifierType.Multiplier;
  } else {
    if Equals(kind, n"AdditiveMultiplier") {
      modType = gameStatModifierType.AdditiveMultiplier;
    } else {
      if NotEquals(kind, n"Additive") {
        return;
      }
    }
  }
  let stat = mod.StatType().StatType();
  let multiplied = Equals(modType, gameStatModifierType.Multiplier);
  // What the game only lets V use, worth its average.
  switch stat {
    case gamedataStatType.CritChance:
      e.critChance += value;
      e.Say(CBT(n"Cyberbane-CrewKit-MoreDamage"));
      return;
    case gamedataStatType.CritDamage:
      e.critDamage += value;
      e.Say(CBT(n"Cyberbane-CrewKit-MoreDamage"));
      return;
    case gamedataStatType.HeadshotDamageMultiplier:
      e.headshot += multiplied ? value - 1.0 : value;
      e.Say(CBT(n"Cyberbane-CrewKit-MoreDamage"));
      return;
    case gamedataStatType.WeakspotDamageMultiplier:
      e.weakspot += multiplied ? value - 1.0 : value;
      e.Say(CBT(n"Cyberbane-CrewKit-MoreDamage"));
      return;
    case gamedataStatType.AttackSpeed:
      e.speed += multiplied ? value - 1.0 : value;
      e.Say(CBT(n"Cyberbane-CrewKit-MoreDamage"));
      return;
    case gamedataStatType.ArmorMultBonus:
      e.armourMult += value;
      e.Say(CBT(n"Cyberbane-CrewKit-MoreArmour"));
      return;
  }
  // What the game reads for anybody in a fight, as it is.
  let word = CBCrewChromeStatWord(stat);
  if StrLen(word) == 0 {
    return;   // V's own business
  }
  ArrayPush(e.stats, stat);
  ArrayPush(e.types, modType);
  ArrayPush(e.values, value);
  e.Say(word);
}

// The stats the game reads for anybody in a fight, in words; "" for one it reads for V alone.
func CBCrewChromeStatWord(stat: gamedataStatType) -> String {
  switch stat {
    case gamedataStatType.Armor: return CBT(n"Cyberbane-CrewKit-MoreArmour");
    case gamedataStatType.Health: return CBT(n"Cyberbane-CrewKit-MoreHealth");
    case gamedataStatType.MitigationChance: return CBT(n"Cyberbane-CrewKit-ShruggingOffHits");
    case gamedataStatType.MitigationStrength: return CBT(n"Cyberbane-CrewKit-ShruggingOffHits");
    case gamedataStatType.BonusDamageAgainstMechanicals: return CBT(n"Cyberbane-CrewKit-HarderHitsOnDronesMechsAnd");
    case gamedataStatType.ThermalResistance: return CBT(n"Cyberbane-CrewKit-FireResistance");
    case gamedataStatType.ChemicalResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToChemicals");
    case gamedataStatType.ElectricResistance: return CBT(n"Cyberbane-CrewKit-ShockResistance");
    case gamedataStatType.ExplosionResistance: return CBT(n"Cyberbane-CrewKit-BlastResistance");
    case gamedataStatType.MeleeResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToBladesAndFists");
    case gamedataStatType.QuickhackResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToQuickhacks");
    case gamedataStatType.DamageOverTimeResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToBleedingAndBurning");
    case gamedataStatType.BossResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToTheBigOnes");
    case gamedataStatType.MechResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToMachines");
    case gamedataStatType.BurningImmunity: return CBT(n"Cyberbane-CrewKit-Fireproof");
    case gamedataStatType.ElectrocuteImmunity: return CBT(n"Cyberbane-CrewKit-Shockproof");
    case gamedataStatType.EMPImmunity: return CBT(n"Cyberbane-CrewKit-Shockproof");
    case gamedataStatType.BleedingImmunity: return CBT(n"Cyberbane-CrewKit-NoBleeding");
    case gamedataStatType.PoisonImmunity: return CBT(n"Cyberbane-CrewKit-PoisonProof");
  }
  return "";
}

// What an implant's power is worth to one of the crew, by the implant's cyberwareType (the key the game itself asks of
// an implant: rpgManager.script, player.script).
func CBCrewChromeAbilities(e: ref<CBCrewChromeEffect>, kind: CName, quality: Float) -> Void {
  switch kind {
    case n"Sandevistan":
      ArrayPush(e.abilities, t"Ability.HasDodge");   // the game's dodge, behaviour only
      CBCrewChromeStat(e, gamedataStatType.Evasion, gameStatModifierType.Additive, 4.0 + 2.0 * quality);
      e.speed += 0.10 + 0.05 * quality;
      e.Say(CBT(n"Cyberbane-CrewKit-ASandevistanSSpeedHarderTo"));
      break;
    case n"Kerenzikov":
      ArrayPush(e.abilities, t"Ability.HasDodge");
      CBCrewChromeStat(e, gamedataStatType.Evasion, gameStatModifierType.Additive, 5.0 + 2.0 * quality);
      e.Say(CBT(n"Cyberbane-CrewKit-KerenzikovReflexesHarderToHit"));
      break;
    case n"SecondHeart":
      CBCrewChromeStat(e, gamedataStatType.Health, gameStatModifierType.Multiplier, 1.2 + 0.05 * quality);
      e.Say(CBT(n"Cyberbane-CrewKit-ASecondHeartMoreHealth"));
      break;
    case n"OpticalCamo":
      CBCrewChromeStat(e, gamedataStatType.Evasion, gameStatModifierType.Additive, 3.0 + quality);
      e.Say(CBT(n"Cyberbane-CrewKit-OpticalCamoHarderToHit"));
      break;
    case n"Berserk":
      e.armourMult += 0.10 + 0.03 * quality;
      e.speed += 0.08 + 0.03 * quality;
      e.Say(CBT(n"Cyberbane-CrewKit-BerserkMoreArmourMoreDamage"));
      break;
    case n"HealthMonitor":
      CBCrewChromeStat(e, gamedataStatType.Health, gameStatModifierType.Multiplier, 1.1 + 0.03 * quality);
      e.Say(CBT(n"Cyberbane-CrewKit-ABiomonitorMoreHealth"));
      break;
    case n"PainReductor":
      ArrayPush(e.abilities, t"Ability.HasPainEditor");
      e.Say(CBT(n"Cyberbane-CrewKit-NoFlinching"));
      break;
    // Arm cyberware has no stats of its own to read, so it was never offered.
    case n"MantisBlades":
    case n"NanoWires":
      e.style = 1;
      e.speed += 0.10 + 0.03 * quality;
      e.Say(CBT(n"Cyberbane-CrewKit-FightsWithBlades"));
      break;
    case n"StrongArms":
      e.style = 2;
      e.speed += 0.08 + 0.03 * quality;
      ArrayPush(e.abilities, t"Ability.HasMeleeHitReactionAndTakedownResistance");
      e.Say(CBT(n"Cyberbane-CrewKit-FightsWithGorillaArms"));
      break;
    // What works only on a condition for V (a kill, a dodge), as a fair fixed share for them: never a heal in a fight,
    // which would break the rule that nothing of Cyberbane's mends itself under fire.
    case n"HealOnKill":
      CBCrewChromeStat(e, gamedataStatType.Health, gameStatModifierType.Multiplier, 1.06 + 0.02 * quality);
      e.Say(CBT(n"Cyberbane-CrewKit-ToughenedByAKillChrome"));
      break;
    case n"ReflexRecorder":
      e.speed += 0.04 + 0.02 * quality;
      e.Say(CBT(n"Cyberbane-CrewKit-SharperAfterADodgeChrome"));
      break;
    case n"ProjectileLauncher":
      e.style = 3;
      e.speed += 0.08 + 0.03 * quality;
      e.Say(CBT(n"Cyberbane-CrewKit-FightsAsAHeavy"));
      break;
  }
}

// What it does for them by the numbers: "+18% armour, +10% fire resistance". "More armour" named the kind of bonus and
// never how much. The first `most` of them.
public func CBCrewChromeNumbers(e: ref<CBCrewChromeEffect>, most: Int32) -> String {
  if !IsDefined(e) {
    return "";
  }
  let parts: array<String>;
  let i = 0;
  while i < ArraySize(e.stats) {
    let part = CBCrewStatPart(e.stats[i], e.types[i], e.values[i]);
    if StrLen(part) > 0 && !ArrayContains(parts, part) {
      ArrayPush(parts, part);
    }
    i += 1;
  }
  // What only V could use, at what it is worth to them.
  let baseChance = CBConfig.CrewCritBaseChance() / 100.0;
  let baseDamage = CBConfig.CrewCritBaseDamage() / 100.0;
  let chance = ClampF(baseChance + e.critChance / 100.0, 0.0, 1.0);
  let dmg = chance * (baseDamage + e.critDamage / 100.0) - baseChance * baseDamage
          + CBConfig.CrewHeadshotShare() * e.headshot + CBConfig.CrewWeakspotShare() * e.weakspot + e.speed;
  if dmg > 0.005 {
    ArrayPush(parts, CBTf(n"Cyberbane-CrewKit-PctDamage", [IntToString(RoundF(dmg * 100.0))]));
  }
  if e.armourMult > 0.005 {
    ArrayPush(parts, CBTf(n"Cyberbane-CrewKit-PctArmour", [IntToString(RoundF(e.armourMult * 100.0))]));
  }
  if e.style > 0 && ArraySize(e.words) > 0 {
    ArrayPush(parts, e.words[ArraySize(e.words) - 1]);
  }
  for a in e.abilities {
    if a == t"Ability.HasPainEditor" {
      ArrayPush(parts, CBT(n"Cyberbane-CrewKit-NoFlinching"));
    }
  }
  if ArraySize(parts) == 0 {
    return CBCrewChromeWords(e, most);
  }
  let out = "";
  let n = Min(ArraySize(parts), most);
  let k = 0;
  while k < n {
    out += (k > 0 ? ", " : "") + parts[k];
    k += 1;
  }
  return out;
}

// One stat as a number and a word: "+30 armour", "+10% fire resistance", "fireproof".
public func CBCrewStatPart(stat: gamedataStatType, modType: gameStatModifierType, value: Float) -> String {
  let noun = CBCrewStatNoun(stat);
  if StrLen(noun) == 0 {
    return "";
  }
  switch stat {
    case gamedataStatType.BurningImmunity:
    case gamedataStatType.ElectrocuteImmunity:
    case gamedataStatType.EMPImmunity:
    case gamedataStatType.BleedingImmunity:
    case gamedataStatType.PoisonImmunity:
      return noun;
  }
  if Equals(modType, gameStatModifierType.Multiplier) {
    return CBTf(n"Cyberbane-CrewKit-PctOf", [IntToString(RoundF((value - 1.0) * 100.0)), noun]);
  }
  if Equals(modType, gameStatModifierType.AdditiveMultiplier) {
    return CBTf(n"Cyberbane-CrewKit-PctOf", [IntToString(RoundF(value * 100.0)), noun]);
  }
  // Flat: armour and health are points; the rest the game keeps as percentages.
  if Equals(stat, gamedataStatType.Armor) || Equals(stat, gamedataStatType.Health) {
    return CBTf(n"Cyberbane-CrewKit-FlatOf", [IntToString(RoundF(value)), noun]);
  }
  return CBTf(n"Cyberbane-CrewKit-PctOf", [IntToString(RoundF(value)), noun]);
}

public func CBCrewStatNoun(stat: gamedataStatType) -> String {
  switch stat {
    case gamedataStatType.Armor: return CBT(n"Cyberbane-CrewKit-NounArmour");
    case gamedataStatType.Health: return CBT(n"Cyberbane-CrewKit-NounHealth");
    case gamedataStatType.Evasion: return CBT(n"Cyberbane-CrewKit-NounDodge");
    case gamedataStatType.MitigationChance: return CBT(n"Cyberbane-CrewKit-NounMitigation");
    case gamedataStatType.MitigationStrength: return CBT(n"Cyberbane-CrewKit-NounMitigationStrength");
    case gamedataStatType.BonusDamageAgainstMechanicals: return CBT(n"Cyberbane-CrewKit-NounMachines");
    case gamedataStatType.ThermalResistance: return CBT(n"Cyberbane-CrewKit-FireResistance");
    case gamedataStatType.ChemicalResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToChemicals");
    case gamedataStatType.ElectricResistance: return CBT(n"Cyberbane-CrewKit-ShockResistance");
    case gamedataStatType.ExplosionResistance: return CBT(n"Cyberbane-CrewKit-BlastResistance");
    case gamedataStatType.MeleeResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToBladesAndFists");
    case gamedataStatType.QuickhackResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToQuickhacks");
    case gamedataStatType.DamageOverTimeResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToBleedingAndBurning");
    case gamedataStatType.BossResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToTheBigOnes");
    case gamedataStatType.MechResistance: return CBT(n"Cyberbane-CrewKit-ResistanceToMachines");
    case gamedataStatType.BurningImmunity: return CBT(n"Cyberbane-CrewKit-Fireproof");
    case gamedataStatType.ElectrocuteImmunity: return CBT(n"Cyberbane-CrewKit-Shockproof");
    case gamedataStatType.EMPImmunity: return CBT(n"Cyberbane-CrewKit-Shockproof");
    case gamedataStatType.BleedingImmunity: return CBT(n"Cyberbane-CrewKit-NoBleeding");
    case gamedataStatType.PoisonImmunity: return CBT(n"Cyberbane-CrewKit-PoisonProof");
  }
  return "";
}

// Arm cyberware put in: the body they come in fights that way from the next call, one of their old gang's signature
// fighters when the gang has one, else anybody's of that kind; one who was a Rival keeps their own body and only fights
// differently in name.
public func CBCrewStyleFromChrome(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, e: ref<CBCrewChromeEffect>) -> Void {
  if !IsDefined(m) || !IsDefined(e) || e.style <= 0 {
    return;
  }
  m.seat = e.style == 3 ? 0 : 2;
  if m.rival > 0 {
    return;
  }
  let rec = CBCrewStyleRecord(m.faction, e.style, m.seed, CBRecordSex(m.record));
  if TDBID.IsValid(rec) && CBRecordIsPerson(rec) && IsDefined(TweakDBInterface.GetCharacterRecord(rec)) {
    m.record = rec;
    m.look = n"";
    CBLog.Info(n"Crew", s"One of the crew takes a body that fights the new way (signature kind \(e.style)).");
  }
}

// A signature record of this kind: the gang's own first, else every gang's, by the member's seed.
// `sex`: 1 a woman's body, 2 a man's, 0 not known (CBRecordSex): a body of the same sex as theirs, so they are still who
// they were, or nothing.
func CBCrewStyleRecord(gang: CName, style: Int32, seed: Int32, sex: Int32) -> TweakDBID {
  let kinds: array<Int32>;
  let recs: array<TweakDBID>;
  let female: array<Bool>;
  CBRivalSignatureTable(gang, recs, kinds, female);
  let i = 0;
  while i < Min(Min(ArraySize(recs), ArraySize(kinds)), ArraySize(female)) {
    if kinds[i] == style && (sex == 0 || Equals(sex == 1, female[i])) && TDBID.IsValid(recs[i])
       && IsDefined(TweakDBInterface.GetCharacterRecord(recs[i])) {
      return recs[i];
    }
    i += 1;
  }
  let gangs: array<CName>;
  ArrayPush(gangs, n"Maelstrom");
  ArrayPush(gangs, n"TygerClaws");
  ArrayPush(gangs, n"Wraiths");
  ArrayPush(gangs, n"Mox");
  ArrayPush(gangs, n"Militech");
  let found: array<TweakDBID>;
  for g in gangs {
    let gk: array<Int32>;
    let gr: array<TweakDBID>;
    let gf: array<Bool>;
    CBRivalSignatureTable(g, gr, gk, gf);
    let j = 0;
    while j < Min(Min(ArraySize(gr), ArraySize(gk)), ArraySize(gf)) {
      if gk[j] == style && (sex == 0 || Equals(sex == 1, gf[j])) && TDBID.IsValid(gr[j])
         && IsDefined(TweakDBInterface.GetCharacterRecord(gr[j])) {
        ArrayPush(found, gr[j]);
      }
      j += 1;
    }
  }
  return ArraySize(found) > 0 ? found[CBHashIndex(seed, 23, ArraySize(found))] : TDBID.None();
}

// The sex a character record's body has: 1 a woman, 2 a man, 0 when the record allows both or says nothing.
public func CBRecordSex(rec: TweakDBID) -> Int32 {
  let cr = TweakDBInterface.GetCharacterRecord(rec);
  if !IsDefined(cr) || cr.GetGendersCount() != 1 {
    return 0;
  }
  let ge = cr.GetGendersItem(0);
  let g = IsDefined(ge) ? ge.Gender() : null;
  if !IsDefined(g) {
    return 0;
  }
  if Equals(g.Type(), gamedataGender.Female) { return 1; }
  if Equals(g.Type(), gamedataGender.Male) { return 2; }
  return 0;
}

// How many pieces of chrome V owns and is not wearing that would do nothing for anybody but V, so the list can say why
// they are not there.
public func CBCrewChromeLeftOut(game: GameInstance) -> Int32 {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return 0;
  }
  let n = 0;
  let items: array<wref<gameItemData>>;
  ts.GetItemListByTag(player, n"Cyberware", items);
  for d in items {
    if IsDefined(d) && !d.HasTag(n"Quest") && !RPGManager.IsItemEquipped(player, d.GetID())
       && !CBCrewChromeRead(ItemID.GetTDBID(d.GetID())).Any() {
      n += 1;
    }
  }
  return n;
}

// ---- Their own weapon in their hands (experimental) ---------------------------------------------------------
//
// The weapon handed over stays V's, kept for them (CBCrewKit.weapon), and what reaches the fight is how they fight and
// the damage its grade brings.
public func CBCrewWeaponInHandOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().crewWeaponInHand;
}

@addField(ScriptedPuppet)
public let cbCrewArmed: Bool;

public func CBCrewArmFromKit(game: GameInstance, puppet: ref<ScriptedPuppet>, m: ref<CBCrewMember>) -> Void {
  if !CBCrewWeaponInHandOn() || !IsDefined(puppet) || !IsDefined(m) || puppet.cbCrewArmed || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(k) || !k.hasWeapon || !IsDefined(ts) {
    return;
  }
  let rec = ItemID.GetTDBID(k.weapon);
  if !TDBID.IsValid(rec) || !IsDefined(TweakDBInterface.GetWeaponItemRecord(rec)) {
    return;
  }
  let ai = puppet.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  puppet.cbCrewArmed = true;
  CBTrace("inventory: one of V's crew is handed their weapon");
  ts.GiveItem(puppet, ItemID.FromTDBID(rec), 1);
  let cmd = new AIEquipCommand();
  cmd.slotId = t"AttachmentSlots.WeaponRight";
  cmd.itemId = rec;
  cmd.failIfItemNotFound = true;
  CBTrace("order: one of V's crew draws their own weapon");
  ai.SendCommand(cmd);
  CBLog.Info(n"Crew", "One of the crew came carrying the weapon V gave them.");
}

// Down for good with it in their hand: it fell with them, and is theirs no longer (nothing to hand back twice).
public func CBCrewArmedFell(game: GameInstance, puppet: ref<ScriptedPuppet>, m: ref<CBCrewMember>) -> Bool {
  if !IsDefined(puppet) || !puppet.cbCrewArmed || !IsDefined(m) {
    return false;
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  if !IsDefined(k) || !k.hasWeapon {
    return false;
  }
  k.hasWeapon = false;
  k.weaponTier = 0;
  return true;
}

func CBCrewChromeStat(e: ref<CBCrewChromeEffect>, stat: gamedataStatType, modType: gameStatModifierType, value: Float) -> Void {
  ArrayPush(e.stats, stat);
  ArrayPush(e.types, modType);
  ArrayPush(e.values, value);
}

// What one implant does for a crew member. Empty for anything that is not chrome, or does nothing for anybody but V.
public func CBCrewChromeRead(id: TweakDBID) -> ref<CBCrewChromeEffect> {
  let e = new CBCrewChromeEffect();
  let rec = TweakDBInterface.GetItemRecord(id);
  if !IsDefined(rec) || !IsDefined(rec.ItemCategory()) || NotEquals(rec.ItemCategory().Type(), gamedataItemCategory.Cyberware) {
    return e;
  }
  let quality: Float;
  let plus: Float;
  CBCrewQualityOf(rec, quality, plus);
  let n = rec.GetStatModifiersCount();
  let i = 0;
  while i < n {
    CBCrewChromeTake(e, rec.GetStatModifiersItem(i), quality, plus);
    i += 1;
  }
  let p = rec.GetOnEquipCount();
  i = 0;
  while i < p {
    let pkg = rec.GetOnEquipItem(i);
    i += 1;
    if IsDefined(pkg) {
      let s = pkg.GetStatsCount();
      let j = 0;
      while j < s {
        CBCrewChromeTake(e, pkg.GetStatsItem(j), quality, plus);
        j += 1;
      }
    }
  }
  CBCrewChromeAbilities(e, TweakDBInterface.GetCName(id + t".cyberwareType", n""), quality);
  return e;
}

// What it does for them in words, the first `most` of them: "more armour and fire resistance".
public func CBCrewChromeWords(e: ref<CBCrewChromeEffect>, most: Int32) -> String {
  if !IsDefined(e) {
    return "";
  }
  let n = Min(ArraySize(e.words), most);
  let out = "";
  let i = 0;
  while i < n {
    if i > 0 {
      out += i == n - 1 ? CBT(n"Cyberbane-CrewKit-And") : ", ";
    }
    out += e.words[i];
    i += 1;
  }
  return out;
}

// ---- Training and war -----------------------------------------------------------------------------

public func CBCrewTrainCost(k: ref<CBCrewKit>) -> Int32 {
  let level = IsDefined(k) ? k.trained : 0;
  return CBConfig.CrewTrainCostBase() * (level + 1);
}

public func CBCrewTrainHours(k: ref<CBCrewKit>) -> Float {
  let level = IsDefined(k) ? k.trained : 0;
  return CBConfig.CrewTrainHoursBase() * Cast<Float>(level + 1);
}

// Away training or at war: not to be called.
public func CBCrewAway(game: GameInstance, id: Int32, now: Float) -> Bool {
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(id) : null;
  return (IsDefined(k) && (k.trainUntil > now || (k.warUntil > now && !CBCrewWarHere(game, k.warOn))))
      || CBCrewJobAway(game, id, now)
      || CBCrewResting(game, id, now);   // a day off V gave them; a war's party can come on the war's own streets
}

// "TRAINING, 6H" or "AT WAR, 12H" for the card, "" when here.
public func CBCrewAwayWord(game: GameInstance, id: Int32, now: Float) -> String {
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(id) : null;
  // A job is kept in its own book, so a member with no kit of their own can still be away on one.
  if CBCrewJobAway(game, id, now) {
    return CBTf(n"Cyberbane-CrewJobs-ONAJOBH", [s"\(CBCrewJobHoursLeft(game, id, now))"]);
  }
  let lbRest = CBCrewLifeBook.Get(game);
  if IsDefined(lbRest) && lbRest.RestUntil(id) > now {
    return CBTf(n"Cyberbane-CrewLife-DAYOFFH", [s"\(CeilF((lbRest.RestUntil(id) - now) / CBConfig.SecondsPerHour()))"]);
  }
  if !IsDefined(k) {
    return "";
  }
  if k.trainUntil > now {
    return CBTf(n"Cyberbane-CrewKit-TRAININGH", [s"\(CeilF((k.trainUntil - now) / CBConfig.SecondsPerHour()))"]);
  }
  if k.warUntil > now {
    return CBTf(n"Cyberbane-CrewKit-ATWARH", [s"\(CeilF((k.warUntil - now) / CBConfig.SecondsPerHour()))"]);
  }
  return "";
}

// The gangs a senior member can be sent to start a war on: any that fields people and is not friendly with V.
public func CBCrewWarTargets(sys: ref<CyberbaneSystem>) -> array<CName> {
  let out: array<CName>;
  let score = IsDefined(sys) ? sys.GetScore() : null;
  let content = IsDefined(sys) ? sys.GetContent() : null;
  if !IsDefined(score) || !IsDefined(content) {
    return out;
  }
  for f in content.GetFactions() {
    if IsDefined(f) && CBFactionFieldsSquads(f.id) && CBFactionOn(f.id) && !CBIsCorpFaction(f.id) {
      let posture = score.GetPosture(f.id);
      if !Equals(posture, ECBPosture.Allied) && !Equals(posture, ECBPosture.Friendly) && ArraySize(out) < CBConfig.CrewPickListMax() {
        ArrayPush(out, f.id);
      }
    }
  }
  return out;
}

// ---- What it all does in the world ----------------------------------------------------------------

// On their way into the world for a call (CBSetUpCrewMember): rank, gear, the weapon's quality and their chrome, all as
// the stats the game already reads, once per body.
@addField(ScriptedPuppet)
public let cbCrewKitted: Bool;

// What a member's kit comes to: every multiplier, stat and ability CBCrewApplyKit puts on them, worked out without
// touching anybody, so the Hub can show their real numbers and what a piece of chrome would change before it goes in.
public class CBCrewKitNumbers {
  public let rank: Int32;
  public let health: Float;
  public let armour: Float;
  public let damage: Float;
  public let npcDamage: Float;
  public let healthCeiling: Float;
  public let damageCeiling: Float;
  public let hitCap: Float;
  public let evasion: Float;                       // flat, from rank 6
  public let stats: array<gamedataStatType>;       // chrome's own stats, as the game reads them for anybody
  public let types: array<gameStatModifierType>;
  public let values: array<Float>;
  public let abilities: array<TweakDBID>;          // chrome's and the rank's
  public let chromeSaid: String;
  public let smasherSaid: String;

  // A chrome stat summed over every piece, for the Hub: the flat part and the share.
  public func Sum(stat: gamedataStatType, modType: gameStatModifierType) -> Float {
    let total = 0.0;
    let i = 0;
    while i < ArraySize(this.stats) {
      if Equals(this.stats[i], stat) && Equals(this.types[i], modType) {
        total += Equals(modType, gameStatModifierType.Multiplier) ? this.values[i] - 1.0 : this.values[i];
      }
      i += 1;
    }
    return total;
  }
}

// `pl` is the power level the body has (V's level when there is no body), `baseHealth` the body's health before any of
// this (0 when there is no body: the match to V's fire is then left out, and the number is the least they get). `extra` is
// one more piece of chrome, for the preview of putting it in.
public func CBCrewKitCalc(game: GameInstance, m: ref<CBCrewMember>, pl: Float, baseHealth: Float, opt extra: TweakDBID) -> ref<CBCrewKitNumbers> {
  let n = new CBCrewKitNumbers();
  if !IsDefined(m) {
    n.rank = 1;
    n.health = 1.0;
    n.armour = 1.0;
    n.damage = 1.0;
    n.npcDamage = 1.0;
    return n;
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  let rank = CBCrewRankOf(game, m);
  n.rank = rank;
  let steps = Cast<Float>(rank - 1);
  let health = 1.0 + CBConfig.CrewRankHealthStep() * steps;
  let armour = 1.0 + CBConfig.CrewRankArmourStep() * steps;
  let damage = 1.0 + CBConfig.CrewRankDamageStep() * steps;
  // What the game lets only V use (CBCrewChromeRead), gathered from the chrome and a spar, and turned into damage below.
  let critChance = 0.0;
  let critDamage = 0.0;
  let headshot = 0.0;
  let weakspot = 0.0;
  let chrome: array<TweakDBID>;
  if IsDefined(k) {
    // Training brings better gear: armour and health.
    health += CBConfig.CrewGearStep() * Cast<Float>(k.trained);
    armour += CBConfig.CrewGearStep() * Cast<Float>(k.trained);
    if k.hasWeapon {
      damage += CBConfig.CrewWeaponTierDamage() * Cast<Float>(k.weaponTier + 1);
    }
    if k.sharpUntil > CBGameSeconds(game) {
      damage += CBConfig.CrewSharpDamage();
      critChance += CBConfig.CrewSharpCrit();
    }
    let ci = 0;
    while ci < CBCrewChromeSlots() {
      let c = k.ChromeAt(ci);
      ci += 1;
      if TDBID.IsValid(c) {
        ArrayPush(chrome, c);
      }
    }
  }
  if TDBID.IsValid(extra) {
    ArrayPush(chrome, extra);
  }
  // Each implant as the game has it (CBCrewChromeRead): its own stats on them, its power as the game's people have it,
  // and what only V could use turned into its worth.
  for c in chrome {
    let e = CBCrewChromeRead(c);
    let si = 0;
    while si < ArraySize(e.stats) {
      ArrayPush(n.stats, e.stats[si]);
      ArrayPush(n.types, e.types[si]);
      ArrayPush(n.values, e.values[si]);
      si += 1;
    }
    for a in e.abilities {
      ArrayPush(n.abilities, a);
    }
    critChance += e.critChance;
    critDamage += e.critDamage;
    headshot += e.headshot;
    weakspot += e.weakspot;
    damage += e.speed;          // more attacks in the same time
    armour += e.armourMult;
    n.chromeSaid += (StrLen(n.chromeSaid) > 0 ? "; " : "") + CBCrewItemName(c) + ": " + CBCrewChromeWords(e, 4);
  }
  // The game lets nobody but V land a critical hit, a headshot bonus or a weak spot (damageSystem.script), so what those
  // stats would do is given as the damage they add on average: the gain over V's own base chance and damage, and the
  // share of hits that land on a head or a weak spot.
  let baseChance = CBConfig.CrewCritBaseChance() / 100.0;
  let baseDamage = CBConfig.CrewCritBaseDamage() / 100.0;
  let chance = ClampF(baseChance + critChance / 100.0, 0.0, 1.0);
  damage += chance * (baseDamage + critDamage / 100.0) - baseChance * baseDamage;
  damage += CBConfig.CrewHeadshotShare() * headshot + CBConfig.CrewWeakspotShare() * weakspot;
  // Their climb, on the scale the apex squads are built on (Spawn/FactionApex.reds): Adam Smasher's own curves at their
  // power level, a share of him that grows with every rank and every spar, and the same measure of V's fire an apex
  // squad member takes.
  let climb = ClampF(Cast<Float>(rank - 1) / 5.0, 0.0, 1.0);
  let sparred = IsDefined(k) ? MinF(Cast<Float>(k.spars) * CBConfig.CrewSmasherSparStep(), CBConfig.CrewSmasherSparMax()) : 0.0;
  let share = CBConfig.CrewSmasherShareTop() * climb + sparred;
  let healthCeiling = CBConfig.CrewMultCeiling();
  let damageCeiling = CBConfig.CrewMultCeiling();
  let npcDamage = 1.0;
  if share > 0.0 {
    let sm = CBSmasherScale(game, pl);
    // As far as V is into the game (Spawn/MeasureV.reds CBVProgress), as for a Rival.
    let measure = CBMeasureV(game);
    let progress = CBVProgress(measure);
    if sm.X > 0.0 {
      health = MaxF(health, CBSmasherPart(sm.X, share, progress));
      healthCeiling = MaxF(healthCeiling, CBSmasherPart(sm.X, CBConfig.SmasherCeilingShare(), progress));
    }
    if sm.Y > 0.0 {
      let smDamage = CBSmasherPart(sm.Y * CBConfig.SmasherDamageScale(), share, progress);
      damage = MaxF(damage, smDamage);
      npcDamage = smDamage;
      damageCeiling = MaxF(damageCeiling, CBSmasherPart(sm.Y * CBConfig.SmasherDamageScale(), CBConfig.SmasherCeilingShare(), progress));
    }
    if baseHealth > 0.0 {
      // What an apex squad member at the highest strength would take of V's fire, and a tenth more at Legend.
      let seconds = CBConfig.ApexMatchSeconds() * 1.5 * climb * CBConfig.CrewPastApex();
      let underFire = CBMatchHealthMult(measure, baseHealth, seconds);
      health = MaxF(health, underFire);
      healthCeiling = MaxF(healthCeiling, underFire);
    }
    n.hitCap = CBConfig.CrewHitCapRookie() - (CBConfig.CrewHitCapRookie() - CBConfig.CrewHitCapLegend()) * climb;
    n.smasherSaid = CBTf(n"Cyberbane-CrewKit-SmasherXHealthXDamageAt", [s"\(sm.X)", s"\(sm.Y)", s"\(share)", s"\(n.hitCap)"]);
  }
  // What a rank brings with it, the game's abilities (gmpl_abilities/abilities.tweak).
  if rank >= 3 {
    ArrayPush(n.abilities, t"Ability.HasDodge");
    ArrayPush(n.abilities, t"Ability.CanCatchUp");
  }
  if rank >= 4 {
    ArrayPush(n.abilities, t"Ability.CanUseCovers");
    ArrayPush(n.abilities, t"Ability.CanShootWhileMoving");
  }
  if rank >= 5 {
    ArrayPush(n.abilities, t"Ability.HasExtendedHitReactionImmunity");
    ArrayPush(n.abilities, t"Ability.HasMeleeHitReactionAndTakedownResistance");
    ArrayPush(n.abilities, t"Ability.CanUseAntiStun");
  }
  if rank >= 6 {
    n.evasion = CBConfig.CrewLegendEvasion();
    ArrayPush(n.abilities, t"Ability.CanGuardBreak");
  }
  n.healthCeiling = healthCeiling;
  n.damageCeiling = damageCeiling;
  n.health = ClampF(health, 1.0, healthCeiling);
  n.armour = ClampF(armour, 1.0, CBConfig.CrewMultCeiling());
  n.damage = ClampF(damage, 1.0, damageCeiling);
  n.npcDamage = ClampF(npcDamage, 1.0, damageCeiling);
  return n;
}

// The same numbers for the Hub, with nobody in the world: at V's own level, the least they come with.
public func CBCrewKitPreview(game: GameInstance, m: ref<CBCrewMember>, opt extra: TweakDBID) -> ref<CBCrewKitNumbers> {
  let player = GetPlayer(game);
  let stats = GameInstance.GetStatsSystem(game);
  let pl = IsDefined(player) && IsDefined(stats) ? stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.PowerLevel) : 1.0;
  return CBCrewKitCalc(game, m, pl, 0.0, extra);
}

public func CBCrewApplyKit(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, m: ref<CBCrewMember>) -> Void {
  if !IsDefined(puppet) || !IsDefined(m) || puppet.cbCrewKitted || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  puppet.cbCrewKitted = true;
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  CBTrace("stats: kitting one of V's crew");
  let n = CBCrewKitCalc(game, m, stats.GetStatValue(id, gamedataStatType.PowerLevel), stats.GetStatValue(id, gamedataStatType.Health));
  let si = 0;
  while si < ArraySize(n.stats) {
    let mod = RPGManager.CreateStatModifier(n.stats[si], n.types[si], n.values[si]);
    if IsDefined(mod) {
      stats.AddModifier(id, mod);
    }
    si += 1;
  }
  let npc = puppet as NPCPuppet;
  for a in n.abilities {
    CBGrantAbility(npc, a);
  }
  if n.evasion > 0.0 {
    CBAddFlat(stats, id, gamedataStatType.Evasion, n.evasion);
  }
  CBSetKillLimit(game, puppet, CBConfig.KillableApexSeconds());
  CBAddMult(stats, id, gamedataStatType.Health, n.health);
  CBAddMult(stats, id, gamedataStatType.Armor, n.armour);
  CBAddMult(stats, id, gamedataStatType.PhysicalDamage, n.damage);
  CBAddMult(stats, id, gamedataStatType.NPCDamage, n.npcDamage);
  puppet.cbHitCap = n.hitCap;   // no single hit takes more than this share of them (Spawn/FactionApex.reds, ApplyDamage)
  CBKeepKillable(game, puppet, false);
  // Topped up to the new maximum, the way the game refills a pool.
  let pools = GameInstance.GetStatPoolsSystem(game);
  if IsDefined(pools) {
    pools.RequestSettingStatPoolMaxValue(id, gamedataStatPoolType.Health, null);
  }
  // What the Hub shows as their numbers when last called.
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) {
    lb.NoteKit(m.id, n.health, n.armour, n.damage);
  }
  CBLog.Info(n"Crew", s"Kitted for the call: rank \(n.rank), health x\(n.health), armour x\(n.armour), damage x\(n.damage).\(n.smasherSaid)"
                    + (StrLen(n.chromeSaid) > 0 ? s" Chrome: \(n.chromeSaid)." : ""));
}

// The weapon back to V, wherever it was going: on request, and whenever they leave the crew.
public func CBCrewReturnWeapon(game: GameInstance, k: ref<CBCrewKit>) -> Bool {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(k) || !k.hasWeapon || !IsDefined(player) || !IsDefined(ts) {
    return false;
  }
  // One from the stash never left it.
  if CBArmoryReturn(game, k) {
    return true;
  }
  ts.GiveItem(player, k.weapon, 1);
  k.hasWeapon = false;
  k.weaponTier = 0;
  return true;
}

// Off the roster (CBCrewBook.Remove): their weapon comes back to V, and their kit is forgotten.
public func CBCrewKitLeaves(game: GameInstance, id: Int32) -> Void {
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(id) : null;
  if !IsDefined(k) {
    return;
  }
  let ab = CBArmoryBook.Get(game);
  let fromStash = IsDefined(ab) && ab.Has(id);
  if CBCrewReturnWeapon(game, k) && CBMessagesOn() && !fromStash {
    CBHearsayFromStreet(game, CBT(n"Cyberbane-CrewKit-SomebodyDroppedOffAWeaponOf"), n"");
  }
  kb.Forget(id);
}

// ---- The Hub's requests, carried out on the tick ----------------------------------------------------

public func CBCrewKitService(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
  let kb = CBCrewKitBook.Get(game);
  if !IsDefined(kb) || !IsDefined(book) {
    return;
  }
  let now = CBGameSeconds(game);
  // The texts of orders carried out on the Hub, now that the game is back.
  let t = 0;
  while t < ArraySize(kb.laterLines) {
    let who = t < ArraySize(kb.laterWho) ? book.Find(kb.laterWho[t]) : null;
    let toGroup = t < ArraySize(kb.laterGroup) && kb.laterGroup[t];
    CBCrewText(sys, game, who, kb.laterLines[t], toGroup);
    t += 1;
  }
  ArrayClear(kb.laterWho);
  ArrayClear(kb.laterLines);
  ArrayClear(kb.laterGroup);
  // Every order still waiting, in the order asked: a spar, and anything the Hub could not carry out itself.
  let asks: array<ref<CBCrewKitAsk>>;
  for queued in kb.asks {
    ArrayPush(asks, queued);
  }
  ArrayClear(kb.asks);
  for a in asks {
    CBCrewKitCarryOut(sys, game, kb, book, a, now);
  }
  CBCrewKitReturns(sys, game, kb, book, now);
  CBCrewWarTick(sys, game);   // how the crew's wars are going, in its group chat (Reactions/CrewWar.reds)
  CBCrewSparTick(sys, game, kb, book, now);
  CBCrewEarnTick(sys, game, kb, book, now);
  CBCrewJobsTick(sys, game, book, now);   // jobs, the kitty, challenges and goods (Reactions/CrewJobs.reds)
  CBCrewBannerTick(sys, game, now);
}

// One order, for a member still on the roster, here and not away.
func CBCrewKitCarryOut(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, book: ref<CBCrewBook>,
                       a: ref<CBCrewKitAsk>, now: Float) -> Void {
  let m = IsDefined(a) ? book.Find(a.member) : null;
  if !IsDefined(m) {
    return;
  }
  if book.IsOut(m.id) || CBCrewAway(game, m.id, now) {
    CBMenuNote(game, CBTf(n"Cyberbane-CrewKit-IsNotHereForThatOut", [s"\(CBCrewName(sys, m))"]), 4.0);
    return;
  }
  if a.what == CBCrewAskTakeBack() { CBCrewTakeBack(sys, game, kb, m); }
  if a.what == CBCrewAskGive() { CBCrewGiveWeapon(sys, game, kb, m, a.item); }
  if a.what == CBCrewAskChrome() { CBCrewInstallChrome(sys, game, kb, m, a.item); }
  if a.what == CBCrewAskTrain() { CBCrewSendTraining(sys, game, kb, m, now); }
  if a.what == CBCrewAskWar() {
    // A war party of one (Reactions/CrewWar.reds): the Hub's war screen sends whole parties itself.
    let one: array<Int32>;
    ArrayPush(one, m.id);
    CBCrewSendWarParty(sys, game, a.gang, one);
  }
  if a.what == CBCrewAskSpar() { CBCrewSparStart(sys, game, kb, m, now); }
  if a.what == CBCrewAskWork() { CBCrewSetWork(sys, game, m); }   // earning, recruiting, or none (CrewBanner.reds)
  // A job: a Rival's hit, or a gang's bag; and the answer to a challenge.
  if a.what == CBCrewAskJob() {
    CBCrewSendOnJob(sys, game, m, a.rival > 0 ? CBCrewJobHit() : CBCrewJobBag(), a.rival, a.gang);
  }
  if a.what == CBCrewAskDuel() {
    CBCrewChallengeAccept(sys, game, m);
  }
}

// What the Hub asked that touches nothing but V's bag and the crew's own books, done while the menu is still open: a
// weapon given or taken back, chrome put in, training, work, a war.
public func CBCrewKitDoNow(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let kb = CBCrewKitBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(sys) || !IsDefined(kb) || !IsDefined(book) {
    return;
  }
  let now = CBGameSeconds(game);
  let todo: array<ref<CBCrewKitAsk>>;
  let wait: array<ref<CBCrewKitAsk>>;
  for a in kb.asks {
    if IsDefined(a) {
      if a.what == CBCrewAskSpar() {
        ArrayPush(wait, a);
      } else {
        ArrayPush(todo, a);
      }
    }
  }
  ArrayClear(kb.asks);
  for w in wait {
    ArrayPush(kb.asks, w);
  }
  kb.deferTexts = true;
  for a in todo {
    CBCrewKitCarryOut(sys, game, kb, book, a, now);
  }
  kb.deferTexts = false;
}

// ---- A spar --------------------------------------------------------------------------------------

// In a round with V, or their round's body still walking off: not to be called, or two of them stand in the street.
public func CBCrewSparring(game: GameInstance, id: Int32) -> Bool {
  let kb = CBCrewKitBook.Get(game);
  if !IsDefined(kb) || id <= 0 {
    return false;
  }
  if kb.sparMember == id {
    return true;
  }
  if kb.sparLeftMember != id || !EntityID.IsDefined(kb.sparLeftBody) {
    return false;
  }
  if CBStillStanding(GameInstance.FindEntityByID(game, kb.sparLeftBody) as ScriptedPuppet) {
    return true;
  }
  kb.sparLeftMember = 0;
  let none: EntityID;
  kb.sparLeftBody = none;
  return false;
}

public func CBCrewSparDayOf(now: Float) -> Int32 {
  return Cast<Int32>(now / CBConfig.SecondsPerDay()) + 1;
}

// Why a spar cannot start now, or "".
public func CBCrewSparBlocked(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, now: Float) -> String {
  let player = GetPlayer(game);
  let kb = CBCrewKitBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(player) || !IsDefined(kb) || !IsDefined(book) || !IsDefined(m) {
    return CBT(n"Cyberbane-CrewKit-NobodyToSparWith");
  }
  if kb.sparMember > 0 {
    return CBT(n"Cyberbane-CrewKit-ARoundIsAlreadyOn");
  }
  if book.OutCount() > 0 {
    return CBT(n"Cyberbane-CrewKit-YourCrewIsOutWithYou");
  }
  if book.IsOut(m.id) || CBCrewAway(game, m.id, now) {
    return CBT(n"Cyberbane-CrewKit-TheyAreNotHere");
  }
  if CBCrewHurt(m, now) {
    return CBT(n"Cyberbane-CrewKit-TheyAreHurt");
  }
  let k = kb.Find(m.id);
  if IsDefined(k) && k.sparDay == CBCrewSparDayOf(now) {
    return CBT(n"Cyberbane-CrewKit-OnceADayEach");
  }
  if player.IsInCombat() || CBArrivalsHeldBase(sys, game) || IsDefined(player.GetMountedVehicle()) || sys.IsInSafeZone() {
    return CBT(n"Cyberbane-CrewKit-NotHereNotNow");
  }
  if CBHuntersOut(sys, game) || CBHuntPending(sys) {
    return CBT(n"Cyberbane-CrewKit-SomebodyIsHuntingYou");
  }
  if CBSpawnRoom(game) < 1 {
    return CBT(n"Cyberbane-CrewKit-TooManyPeopleAround");
  }
  return "";
}

func CBCrewSparStart(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>, now: Float) -> Void {
  let blocked = CBCrewSparBlocked(sys, game, m, now);
  if StrLen(blocked) > 0 {
    CBMenuNote(game, CBTf(n"Cyberbane-CrewKit-NoSpar", [s"\(blocked)"]), 4.0);
    return;
  }
  let record = m.record;
  if (!TDBID.IsValid(record) || !CBRecordIsPerson(record)) && NotEquals(m.faction, n"") {
    record = CBGangTemplate(sys, m.faction);
  }
  let body: EntityID;
  let ring = 0;
  if CBSpawnOnSide(game, record, m.look, n"CB_Own", CBConfig.CrewSparSpawnDistance(), body, ring, n"CB_Spar") == 0 {
    CBMenuNote(game, CBT(n"Cyberbane-CrewKit-NoSparTheyCouldNotGet"), 4.0);
    return;
  }
  kb.sparMember = m.id;
  kb.sparBody = body;
  kb.sparStart = sys.GetTickCount();
  kb.sparSeen = 0;
  CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewKit-OnMyWayHandsUpWhen"));
  CBLog.Info(n"Crew", "V called one of the crew out for a spar.");
}

// Their body on its way into the world (CBSetUpCrewMember): coming at V for the round, tougher and hitting soft.
// True when this was the spar's body.
public func CBCrewSparSetUp(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Bool {
  let kb = CBCrewKitBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(kb) || !IsDefined(book) || !IsDefined(puppet) || kb.sparMember <= 0
     || !Equals(kb.sparBody, puppet.GetEntityID()) {
    return false;
  }
  let m = book.Find(kb.sparMember);
  CBDisarmGodMode(game, puppet);
  if IsDefined(m) {
    CBKitApexSeat(puppet, m.seat);
    CBCrewApplyKit(sys, game, puppet, m);
  }
  let stats = GameInstance.GetStatsSystem(game);
  if IsDefined(stats) {
    let id = Cast<StatsObjectID>(puppet.GetEntityID());
    // Tougher for a round, less so the further they have climbed: a Legend is built near an apex squad's grade already
    // (CBCrewApplyKit), and two and a half times that again only ever ran a round out on the clock.
    let climb = IsDefined(m) ? ClampF(Cast<Float>(CBCrewRankOf(game, m) - 1) / 5.0, 0.0, 1.0) : 0.0;
    CBAddMult(stats, id, gamedataStatType.Health, 1.0 + (CBConfig.CrewSparHealthMult() - 1.0) * (1.0 - climb));
    // Hitting softly, for real: CBAddMult only ever raises a stat, so the spar's 0.35 was never applied.
    let soft = RPGManager.CreateStatModifier(gamedataStatType.PhysicalDamage, gameStatModifierType.Multiplier, CBConfig.CrewSparDamageMult());
    if IsDefined(soft) {
      stats.AddModifier(id, soft);
    }
    let softNpc = RPGManager.CreateStatModifier(gamedataStatType.NPCDamage, gameStatModifierType.Multiplier, CBConfig.CrewSparDamageMult());
    if IsDefined(softNpc) {
      stats.AddModifier(id, softNpc);
    }
  }
  CBMakeHostileToPlayer(game, puppet);
  CBOrderPursue(sys, game, puppet);
  return true;
}

// The round: over at the time, or when either of them is close to going down.
func CBCrewSparTick(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, book: ref<CBCrewBook>, now: Float) -> Void {
  if kb.sparMember <= 0 {
    return;
  }
  let tick = sys.GetTickCount();
  let m = book.Find(kb.sparMember);
  let p = GameInstance.FindEntityByID(game, kb.sparBody) as ScriptedPuppet;
  if !IsDefined(m) {
    CBCrewSparEnd(sys, game, kb, m, p, 0);
    return;
  }
  // The story, a scene, a job or a safe place takes over mid-round: the bell goes (or the round is called off before it
  // began).
  if sys.GetStoryHold() != CBStoryNone() || CBArrivalsHeldBase(sys, game) {
    CBCrewSparEnd(sys, game, kb, m, p, kb.sparSeen > 0 ? 3 : 0);
    return;
  }
  // Real trouble on the way: the round is off, and the crew can be called. Nothing is scored for it.
  if CBHuntersOut(sys, game) || CBHuntPending(sys) {
    CBCrewSparEnd(sys, game, kb, m, p, 0);
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewKit-RealTroubleComingRoundSOff"));
    return;
  }
  if kb.sparSeen == 0 {
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      kb.sparSeen = tick;
    } else {
      if tick - kb.sparStart > CBConfig.CrewSparArriveTicks() {
        CBCrewSparEnd(sys, game, kb, m, p, 0);
      }
      return;
    }
  }
  let player = GetPlayer(game);
  let sps = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(player) || !IsDefined(sps) || !CBNpcSafe(sys, p) || !CBStillStanding(p) {
    CBCrewSparEnd(sys, game, kb, m, p, 1);
    return;
  }
  let theirs = sps.GetStatPoolValue(Cast<StatsObjectID>(p.GetEntityID()), gamedataStatPoolType.Health, true);
  let yours = sps.GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, true);
  if theirs <= CBConfig.CrewSparStopHealth() {
    CBCrewSparEnd(sys, game, kb, m, p, 1);   // V had the better of it
    return;
  }
  if yours <= CBConfig.CrewSparStopHealth() {
    CBCrewSparEnd(sys, game, kb, m, p, 2);   // they did
    return;
  }
  if tick - kb.sparSeen >= CBConfig.CrewSparTicks() {
    CBCrewSparEnd(sys, game, kb, m, p, 3);   // the bell
  }
}

// 0 called off before it began, 1 V won, 2 they won, 3 time.
func CBCrewSparEnd(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>,
                   p: ref<ScriptedPuppet>, how: Int32) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  // Out of the round: not hostile, walking off, and taken out of the world once nobody is looking.
  if IsDefined(p) && p.IsAttached() && !p.IsDead() && IsDefined(player) {
    let agent = p.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if IsDefined(agent) && IsDefined(pagent) {
      CBTrace("attitude: a spar ends");
      agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
    }
    CBOrderFlee(game, p, true);
  }
  if IsDefined(des) && EntityID.IsDefined(kb.sparBody) {
    if des.IsTagged(kb.sparBody, n"CB_Spar") {
      des.UnassignTag(kb.sparBody, n"CB_Spar");
    }
    if des.IsTagged(kb.sparBody, n"Cyberbane") && !des.IsTagged(kb.sparBody, n"CB_Orphan") {
      des.AssignTag(kb.sparBody, n"CB_Orphan");
    }
  }
  // Walking off now: their member is not called again until this body is gone (CBCrewSparring).
  kb.sparLeftMember = IsDefined(m) ? m.id : 0;
  kb.sparLeftBody = kb.sparBody;
  kb.sparMember = 0;
  let none: EntityID;
  kb.sparBody = none;
  if !IsDefined(m) || how == 0 {
    return;
  }
  let now = CBGameSeconds(game);
  let k = kb.Kit(m.id);
  k.spars += 1;
  k.sparDay = CBCrewSparDayOf(now);
  k.sharpUntil = now + CBConfig.CrewSharpHours() * CBConfig.SecondsPerHour();
  m.loyalty = Min(100, m.loyalty + (how == 1 ? 3 : 2));
  let levelled = false;
  let rankBefore = CBCrewRankOf(game, m);
  if k.spars % CBConfig.CrewSparsPerTraining() == 0 && k.trained < CBConfig.CrewTrainMax() {
    k.trained += 1;
    levelled = true;
    CBCrewLifeNote(game, m.id, CBLifeTrained(), n"", 0);
    CBCrewLifePromoted(sys, game, m, rankBefore, CBCrewRankOf(game, m));
  }
  let line = how == 1 ? CBT(n"Cyberbane-CrewKit-YouGotMeGoodRoundI")
           : (how == 2 ? CBT(n"Cyberbane-CrewKit-ToldYouIWouldnTHold") : CBT(n"Cyberbane-CrewKit-TimeNotBadEitherOfUs"));
  if levelled {
    line += CBTf(n"Cyberbane-CrewKit-ThatSTheWorkOfA", [s"\(StrLower(CBCrewRankWord(CBCrewRankOf(game, m))))"]);
  }
  CBCrewText(sys, game, m, line);
  CBLog.Info(n"Crew", s"A spar ended (\(how)); spars \(k.spars), trained \(k.trained).");
}

// The spar's body died after all (CBCrewBodyDied): a round that went too far. They are hurt, not dead: it was the body
// for the round, and they are still on the roster.
public func CBCrewSparBodyDied(sys: ref<CyberbaneSystem>, game: GameInstance, id: EntityID) -> Bool {
  let kb = CBCrewKitBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(kb) || !IsDefined(book) || kb.sparMember <= 0 || !Equals(kb.sparBody, id) {
    return false;
  }
  let m = book.Find(kb.sparMember);
  if IsDefined(m) {
    m.hurtUntil = CBGameSeconds(game) + CBConfig.CrewWarHurtHours() * CBConfig.SecondsPerHour();
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewKit-ThatWentTooFarILl"));
  }
  kb.sparMember = 0;
  let none: EntityID;
  kb.sparBody = none;
  return true;
}

// ---- Work -----------------------------------------------------------------------------------------

func CBCrewEarnTick(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, book: ref<CBCrewBook>, now: Float) -> Void {
  let day = CBCrewSparDayOf(now);
  if kb.EarnDay() == day {
    return;
  }
  if kb.EarnDay() == 0 {
    kb.SetEarnDay(day);   // the first look: from tomorrow
    return;
  }
  kb.SetEarnDay(day);
  let total = 0;
  let hurt = "";
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    let k = IsDefined(m) ? kb.Find(m.id) : null;
    if IsDefined(k) && k.earning && !CBCrewAway(game, m.id, now) && !CBCrewHurt(m, now) {
      total += CBConfig.CrewEarnPerRank() * CBCrewRankOf(game, m);
      if RandF() < CBConfig.CrewEarnHurtChance() {
        m.hurtUntil = now + CBConfig.SecondsPerDay();
        hurt = CBCrewName(sys, m);
      }
    }
  }
  total = CBReward(total);
  if total <= 0 {
    return;
  }
  let jb = CBCrewJobBook.Get(game);
  let toKitty = CBCrewJobsOn() && IsDefined(jb);
  if toKitty {
    jb.AddKitty(total);
  } else {
    CBStreetGiveMoney(game, total);
  }
  let note = toKitty ? CBTf(n"Cyberbane-CrewJobs-WorkIntoTheKitty", [s"\(total)"]) : CBTf(n"Cyberbane-CrewKit-YourCrewSWorkBroughtIn", [s"\(total)"]);
  if StrLen(hurt) > 0 {
    note += CBTf(n"Cyberbane-CrewKit-GotHurtDoingIt", [s"\(hurt)"]);
  }
  CBCrewText(sys, game, null, note);
  CBLog.Info(n"Crew", s"The crew's earners brought in \(total)eb.");
}

func CBCrewGiveWeapon(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>, item: ItemID) -> Void {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) || !ItemID.IsValid(item) {
    return;
  }
  // From the stash V is at: it stays there (Reactions/CrewHome.reds).
  if CBArmoryFromStash(game, item) {
    CBArmoryGive(sys, game, kb, m, item);
    return;
  }
  let data = ts.GetItemData(player, item);
  if !IsDefined(data) || RPGManager.IsItemEquipped(player, item) {
    CBMenuNote(game, CBT(n"Cyberbane-CrewKit-ThatWeaponIsNotInYour"), 4.0);
    return;
  }
  let seat = CBCrewSeatForWeapon(data.GetItemType());
  if seat < 0 {
    return;
  }
  let k = kb.Kit(m.id);
  // One at a time: the one they had comes back first.
  CBCrewReturnWeapon(game, k);
  // Its mods and attachments back into V's bag, the way the game's stash takes them off (stash.script).
  let slots = RPGManager.GetModsSlotIDs(data.GetItemType());
  for s in slots {
    ts.RemovePart(player, item, s);
  }
  let attach = RPGManager.GetAttachmentSlotIDs();
  for s in attach {
    ts.RemovePart(player, item, s);
  }
  let tier = CBCrewTierOf(RPGManager.GetItemQuality(data));
  if !ts.RemoveItem(player, item, 1) {
    return;
  }
  k.hasWeapon = true;
  k.weapon = item;
  k.weaponType = EnumInt(data.GetItemType());
  k.weaponTier = tier;
  // How they fight from the next call: a body of their gang's that fights that way. One who was a Rival keeps their
  // own body, who they are; only the way they fight follows the weapon.
  if seat != m.seat {
    m.seat = seat;
    if m.rival == 0 && NotEquals(m.faction, n"") {
      let rec = CBApexRosterRecord(m.faction, seat, m.seed);
      if TDBID.IsValid(rec) && CBRecordIsPerson(rec) {
        m.record = rec;
        m.look = n"";
      }
    }
  }
  let what = CBCrewItemName(ItemID.GetTDBID(item));
  // What it really does: the way they fight and the damage its grade brings, unless they carry it themselves.
  let how = CBCrewWeaponInHandOn() ? CBTf(n"Cyberbane-CrewKit-InTheirHands", [CBLowFirst(CBCrewSeatWord(seat))])
                                   : CBTf(n"Cyberbane-CrewKit-FightAsWithGrade", [CBLowFirst(CBCrewSeatWord(seat)), CBLowFirst(CBCrewTierWord(tier))]);
  CBCrewBatchText(game, m, (tier >= 3 ? CBTf(n"Cyberbane-CrewKit-SeriousPiece", [what]) : CBTf(n"Cyberbane-CrewKit-PutItToWork", [what])) + " " + how);
  CBCrewLifeNote(game, m.id, CBLifeWeapon(), n"", tier);
  CBCrewAskDone(sys, game, CBAskGun(), m.id, tier);
  CBLog.Info(n"Crew", s"V gave one of the crew a weapon (\(CBCrewSeatWord(seat)), tier \(tier)).");
}

func CBCrewTakeBack(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>) -> Void {
  let k = kb.Find(m.id);
  if CBCrewReturnWeapon(game, k) {
    CBMenuNote(game, CBTf(n"Cyberbane-CrewKit-HandedYourWeaponBack", [s"\(CBCrewName(sys, m))"]), 4.0);
  }
}

func CBCrewInstallChrome(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>, item: ItemID) -> Void {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) || !ItemID.IsValid(item) {
    return;
  }
  let k = kb.Kit(m.id);
  if k.ChromeCount() >= CBCrewChromeSlots() {
    CBMenuNote(game, CBTf(n"Cyberbane-CrewKit-HasNoRoomForMoreChrome", [s"\(CBCrewName(sys, m))"]), 4.0);
    return;
  }
  let rec = ItemID.GetTDBID(item);
  let e = CBCrewChromeRead(rec);
  if !e.Any() {
    CBMenuNote(game, CBT(n"Cyberbane-CrewKit-ThatImplantWouldDoNothingFor"), 4.0);
    return;
  }
  if RPGManager.IsItemEquipped(player, item) || !ts.RemoveItem(player, item, 1) {
    CBMenuNote(game, CBT(n"Cyberbane-CrewKit-ThatImplantIsNotInYour"), 4.0);
    return;
  }
  k.AddChrome(rec);
  // What it really does for them, by the numbers (CBCrewChromeNumbers): "+18% armour, +10% fire resistance". Three
  // pieces put in at once are one text (CBCrewBatchText), and the game's sound for a finished build.
  let what = CBCrewChromeNumbers(e, 3);
  CBCrewBatchText(game, m, CBTf(n"Cyberbane-CrewKit-GotThePutInFeelIt", [s"\(CBCrewItemName(rec))", s"\(CBCapFirst(what))"]));
  CBCrewLifeNote(game, m.id, CBLifeChrome(), n"", 0);
  CBUiSound(game, n"ui_menu_item_crafting_done", n"CrewChrome", 1.0);
  CBCrewStyleFromChrome(sys, game, m, e);
  CBLog.Info(n"Crew", s"V had chrome put in one of the crew: \(CBCrewItemName(rec)) (\(CBCrewChromeWords(e, 6))).");
}

func CBCrewSendTraining(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>, now: Float) -> Void {
  let k = kb.Kit(m.id);
  if k.trained >= CBConfig.CrewTrainMax() || CBCrewHurt(m, now) {
    return;
  }
  let cost = CBCrewTrainCost(k);
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) || ts.GetItemQuantity(player, ItemID.FromTDBID(t"Items.money")) < cost {
    CBMenuNote(game, CBTf(n"Cyberbane-CrewKit-TrainingCostsEb", [s"\(cost)"]), 4.0);
    return;
  }
  ts.RemoveItem(player, ItemID.FromTDBID(t"Items.money"), cost);
  let hours = CBCrewTrainHours(k);
  k.trainUntil = now + hours * CBConfig.SecondsPerHour();
  CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewKit-HeadingOutGiveMeHoursAnd", [s"\(RoundF(hours))"]));
  CBLog.Info(n"Crew", s"One of the crew went to train (level \(k.trained + 1), \(cost)eb).");
}

// Back from training or from a war, once their time is up.
func CBCrewKitReturns(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, book: ref<CBCrewBook>, now: Float) -> Void {
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    let k = IsDefined(m) ? kb.Find(m.id) : null;
    if IsDefined(k) && k.trainUntil > 0.0 && now >= k.trainUntil {
      k.trainUntil = 0.0;
      let rankBefore = CBCrewRankOf(game, m);
      k.trained += 1;
      CBCrewLifeNote(game, m.id, CBLifeTrained(), n"", 0);
      CBCrewLifePromoted(sys, game, m, rankBefore, CBCrewRankOf(game, m));
      m.loyalty = Min(100, m.loyalty + CBConfig.CrewTrainLoyalty());
      CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewKit-BackNowBetterGearAndThey", [s"\(CBCrewRankWord(CBCrewRankOf(game, m)))"]));
      CBLog.Info(n"Crew", "One of the crew is back from training.");
    }
    if IsDefined(k) && k.warUntil > 0.0 && now >= k.warUntil {
      if CBCrewWarPartyResolve(sys, game, kb, book, k.warOn, k.warUntil, now) {
        return;   // the roster changed under the walk
      }
    }
  }
}

// A gang's own ground, for what happens on it away from V: the first district it holds, else the first its profile names,
// else where V is.
public func CBGangHomeDistrict(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> CName {
  let i = 0;
  while i < CBDistrictCount() {
    let d = CBDistrictAt(i);
    i += 1;
    if Equals(CBTurfHolder(sys, game, d), gang) {
      return d;
    }
  }
  let content = IsDefined(sys) ? sys.GetContent() : null;
  let prof = IsDefined(content) ? content.GetFaction(gang) : null;
  if IsDefined(prof) && ArraySize(prof.turf) > 0 {
    return prof.turf[0];
  }
  return CBEventDistrict(sys, game);
}

// What the card says about their kit, a line or two.
public func CBCrewKitLines(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  let rank = CBCrewRankOf(game, m);
  let out = CBTf(n"Cyberbane-CrewKit-RankOf6", [s"\(CBCrewRankWord(rank))", s"\(rank)"]);
  if IsDefined(k) {
    if k.hasWeapon {
      out += CBTf(n"Cyberbane-CrewKit-CarryingYourTheyFightAsA", [s"\(CBCrewItemName(ItemID.GetTDBID(k.weapon)))", s"\(CBCrewTierWord(k.weaponTier))", s"\(CBCrewSeatWord(m.seat))"]);
    }
    if k.ChromeCount() > 0 {
      let parts = "";
      let ci = 0;
      while ci < CBCrewChromeSlots() {
        let c = k.ChromeAt(ci);
        ci += 1;
        if TDBID.IsValid(c) {
          parts += (StrLen(parts) > 0 ? ", " : "") + CBCrewItemName(c);
        }
      }
      out += CBTf(n"Cyberbane-CrewKit-Chrome", [s"\(parts)"]);
    }
    if k.trained > 0 {
      out += CBTf(n"Cyberbane-CrewKit-TrainedOfTimes", [s"\(k.trained)", s"\(CBConfig.CrewTrainMax())"]);
    }
    let away = CBCrewAwayWord(game, m.id, CBGameSeconds(game));
    if StrLen(away) > 0 {
      out += s" \(CBCapFirst(StrLower(away))).";
    }
  }
  if IsDefined(k) && k.sharpUntil > CBGameSeconds(game) {
    out += CBT(n"Cyberbane-CrewKit-SharpFromASpar");
  }
  if IsDefined(k) && k.earning {
    out += CBT(n"Cyberbane-CrewKit-WorkingTheStreetForYou");
  }
  if CBCrewIsRecruiter(game, m.id) {
    out += CBT(n"Cyberbane-CrewKit-RecruitingForTheCrewTheBroker");
    let roster = CBCrewBook.Get(game);
    if IsDefined(roster) && !roster.HasRoom() {
      out += CBT(n"Cyberbane-CrewKit-YourCrewIsFullSoThey");
    }
  }
  if IsDefined(k) && k.spars > 0 {
    out += CBTf(n"Cyberbane-CrewKit-SparredTimes", [s"\(k.spars)"]);
  }
  if rank < CBConfig.CrewWarMinRank() {
    out += CBTf(n"Cyberbane-CrewKit-AtTheyCanBeSentTo", [s"\(CBCrewRankWord(CBConfig.CrewWarMinRank()))"]);
  }
  return out;
}
