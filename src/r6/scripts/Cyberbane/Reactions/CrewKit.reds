// Cyberbane - Kitting out the crew (2.6.0)
//
// V's crew, made V's own: a weapon handed over from V's inventory, chrome V owns and does not wear, training that
// brings them back stronger, a war on a gang sent with somebody senior, and a name for the crew itself. All of it
// asked for on the Hub's Crew page and carried out on the game's tick (CBCrewKitService), never from the menu.
//
// What the game lets a script do, and so how each one works:
//   - A weapon. The game's AI picks an NPC's weapon from its record in a fight, so the gun itself cannot be put in their
//     hands to stay. A weapon handed over sets how they fight (heavy, shooter or blade, from what kind of weapon it is),
//     and from their next call they come on a body of their gang's that fights that way; its quality adds to their
//     damage. The weapon itself is kept for V, mods and attachments handed back first, and given back on request or
//     whenever they leave the crew.
//   - Chrome. Installed for good: what it does follows where it goes (armour, health, damage, critical hits,
//     resistance), worked in as they come into the world. Never an ability the crash rules keep off NPCs.
//   - Rank. Their wins and their training together, Rookie to Legend, each rank tougher than the last.
//   - Training. Away for some game hours at a price; back a rank higher, with better gear and better field chrome.
//   - A war. From Lieutenant up, sent to start one on a gang: won, the gang loses ground and knows who sent it;
//     lost, they come back hurt, or not at all.
//   - A name. Typed on the Hub (Codeware's text input), kept in the save as letters from a fixed set.
//   - A spar. V calls one of them out for a timed round: they come at V, tougher and hitting soft, and the round stops
//     the moment either side is close to going down, or the time runs out. Nobody dies of it: the game's god mode is
//     what Cyberbane strips off its people (CBDisarmGodMode), so the round is kept safe by its own stop instead. Each
//     spar leaves them sharp for a day, and every few count as a training. Once a game day each.
//   - Work. Put on earning, they bring in money every game day by their rank, and now and then come back hurt. Or
//     put to recruiting (one at a time), they find the broker better solos (Reactions/CrewBanner.reds).
//
// Everything is kept in CBCrewKitBook, keyed by the member's id: the crew's own saved class is never changed.

// One member's kit.
public class CBCrewKit {
  public persistent let id: Int32;
  public persistent let hasWeapon: Bool;
  public persistent let weapon: ItemID;
  public persistent let weaponType: Int32;    // gamedataItemType, as a number
  public persistent let weaponTier: Int32;    // 0 common .. 4 legendary or iconic
  public persistent let chrome: array<TweakDBID>;
  public persistent let trained: Int32;       // trainings finished
  public persistent let trainUntil: Float;    // game seconds; 0 when not away training
  public persistent let warUntil: Float;      // game seconds; 0 when not away at war
  public persistent let warOn: CName;         // the gang they went to war on
  public persistent let spars: Int32;         // rounds sparred with V
  public persistent let sparDay: Int32;       // the game day of the last, stored one up
  public persistent let sharpUntil: Float;    // a spar's edge, until then
  public persistent let earning: Bool;        // put to work
}

// One order asked for on the Hub, for one member, carried out on the next tick. Each member's orders are their own: one
// slot for everybody gave the first one's order to the next one picked.
public class CBCrewKitAsk {
  public let member: Int32;
  public let what: Int32;     // CBCrewAskGive .. CBCrewAskWork
  public let item: ItemID;    // the weapon or the chrome
  public let gang: CName;     // the war's gang
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
  // Asked for on the Hub, carried out on the next tick (CBCrewKitService).
  public let asks: array<ref<CBCrewKitAsk>>;
  public let reqName: Bool;
  public let reqNameText: String;

  public static func Get(game: GameInstance) -> ref<CBCrewKitBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewKitBook") as CBCrewKitBook : null;
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
    ArrayClear(this.asks);
  }

  // An order for a member, in place of any of the same kind already asked for them.
  public func Ask(member: Int32, what: Int32, item: ItemID, gang: CName) -> Void {
    if member <= 0 {
      return;
    }
    this.Unask(member, what);
    let a = new CBCrewKitAsk();
    a.member = member;
    a.what = what;
    a.item = item;
    a.gang = gang;
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

public func CBCrewRankWord(rank: Int32) -> String {
  if rank >= 6 { return "Legend"; }
  if rank == 5 { return "Enforcer"; }
  if rank == 4 { return "Lieutenant"; }
  if rank == 3 { return "Veteran"; }
  if rank == 2 { return "Soldier"; }
  return "Rookie";
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

// 0 common .. 4 legendary or iconic, read off the quality's name so every "Plus" lands with its own.
public func CBCrewTierOf(q: gamedataQuality) -> Int32 {
  let n = EnumValueToString("gamedataQuality", Cast<Int64>(EnumInt(q)));
  if StrContains(n, "Legendary") || StrContains(n, "Iconic") { return 4; }
  if StrContains(n, "Epic") { return 3; }
  if StrContains(n, "Rare") { return 2; }
  if StrContains(n, "Uncommon") { return 1; }
  return 0;
}

public func CBCrewTierWord(tier: Int32) -> String {
  if tier >= 4 { return "legendary"; }
  if tier == 3 { return "epic"; }
  if tier == 2 { return "rare"; }
  if tier == 1 { return "uncommon"; }
  return "common";
}

public func CBCrewItemName(id: TweakDBID) -> String {
  let rec = TweakDBInterface.GetItemRecord(id);
  if !IsDefined(rec) {
    return "something";
  }
  let n = GetLocalizedTextByKey(rec.DisplayName());
  return StrLen(n) > 0 ? n : "something";
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
  return out;
}

// Chrome V owns and is not wearing.
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
       && CBCrewChromeArea(ItemID.GetTDBID(d.GetID())) >= 0 && ArraySize(out) < CBConfig.CrewPickListMax() {
      ArrayPush(out, d.GetID());
    }
  }
  return out;
}

// What an implant does for a crew member, by where it goes: 0 armour, 1 health, 2 damage, 3 critical hits,
// 4 resistance to hacks; -1 for anything else.
public func CBCrewChromeArea(id: TweakDBID) -> Int32 {
  let rec = TweakDBInterface.GetItemRecord(id);
  if !IsDefined(rec) || !IsDefined(rec.EquipArea()) {
    return -1;
  }
  switch rec.EquipArea().Type() {
    case gamedataEquipmentArea.IntegumentarySystemCW:
    case gamedataEquipmentArea.LegsCW:
      return 0;
    case gamedataEquipmentArea.MusculoskeletalSystemCW:
    case gamedataEquipmentArea.CardiovascularSystemCW:
    case gamedataEquipmentArea.ImmuneSystemCW:
      return 1;
    case gamedataEquipmentArea.ArmsCW:
    case gamedataEquipmentArea.SystemReplacementCW:
    case gamedataEquipmentArea.HandsCW:
      return 2;
    case gamedataEquipmentArea.NervousSystemCW:
    case gamedataEquipmentArea.EyesCW:
      return 3;
    case gamedataEquipmentArea.FrontalCortexCW:
      return 4;
  }
  return -1;
}

public func CBCrewChromeWord(area: Int32) -> String {
  if area == 0 { return "armour"; }
  if area == 1 { return "health"; }
  if area == 2 { return "damage"; }
  if area == 3 { return "critical hits"; }
  if area == 4 { return "hack resistance"; }
  return "";
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
  return IsDefined(k) && (k.trainUntil > now || k.warUntil > now);
}

// "TRAINING, 6H" or "AT WAR, 12H" for the card, "" when here.
public func CBCrewAwayWord(game: GameInstance, id: Int32, now: Float) -> String {
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(id) : null;
  if !IsDefined(k) {
    return "";
  }
  if k.trainUntil > now {
    return s"TRAINING, \(CeilF((k.trainUntil - now) / CBConfig.SecondsPerHour()))H";
  }
  if k.warUntil > now {
    return s"AT WAR, \(CeilF((k.warUntil - now) / CBConfig.SecondsPerHour()))H";
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

public func CBCrewApplyKit(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, m: ref<CBCrewMember>) -> Void {
  if !IsDefined(puppet) || !IsDefined(m) || puppet.cbCrewKitted || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  puppet.cbCrewKitted = true;
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  let rank = CBCrewRankOf(game, m);
  let steps = Cast<Float>(rank - 1);
  let health = 1.0 + CBConfig.CrewRankHealthStep() * steps;
  let armour = 1.0 + CBConfig.CrewRankArmourStep() * steps;
  let damage = 1.0 + CBConfig.CrewRankDamageStep() * steps;
  let crit = 0.0;
  let ice = 0.0;
  if IsDefined(k) {
    // Training brings better gear: armour and health.
    health += CBConfig.CrewGearStep() * Cast<Float>(k.trained);
    armour += CBConfig.CrewGearStep() * Cast<Float>(k.trained);
    if k.hasWeapon {
      damage += CBConfig.CrewWeaponTierDamage() * Cast<Float>(k.weaponTier + 1);
    }
    if k.sharpUntil > CBGameSeconds(game) {
      damage += CBConfig.CrewSharpDamage();
      crit += CBConfig.CrewSharpCrit();
    }
    for c in k.chrome {
      let area = CBCrewChromeArea(c);
      if area == 0 { armour += CBConfig.CrewChromeStep(); }
      if area == 1 { health += CBConfig.CrewChromeStep(); }
      if area == 2 { damage += CBConfig.CrewChromeStep(); }
      if area == 3 { crit += CBConfig.CrewChromeCrit(); }
      if area == 4 { ice += CBConfig.CrewChromeIce(); }
    }
  }
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  CBTrace("stats: kitting one of V's crew");
  CBAddMult(stats, id, gamedataStatType.Health, ClampF(health, 1.0, CBConfig.CrewMultCeiling()));
  CBAddMult(stats, id, gamedataStatType.Armor, ClampF(armour, 1.0, CBConfig.CrewMultCeiling()));
  CBAddMult(stats, id, gamedataStatType.PhysicalDamage, ClampF(damage, 1.0, CBConfig.CrewMultCeiling()));
  if crit > 0.0 {
    CBAddFlat(stats, id, gamedataStatType.CritChance, crit);
  }
  if ice > 0.0 {
    CBAddFlat(stats, id, gamedataStatType.HackingResistance, ice);
  }
  CBLog.Info(n"Crew", s"Kitted for the call: rank \(rank), health x\(health), armour x\(armour), damage x\(damage).");
}

// The weapon back to V, wherever it was going: on request, and whenever they leave the crew.
public func CBCrewReturnWeapon(game: GameInstance, k: ref<CBCrewKit>) -> Bool {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(k) || !k.hasWeapon || !IsDefined(player) || !IsDefined(ts) {
    return false;
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
  if CBCrewReturnWeapon(game, k) && CBMessagesOn() {
    CBHearsayFromStreet(game, "Somebody dropped off a weapon of yours. Said it was what they were carrying for you.", n"");
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
  if kb.reqName {
    kb.reqName = false;
    kb.SetName(kb.reqNameText);
    let named = kb.Name();
    CBSystemNote(game, StrLen(named) > 0 ? s"your crew is \(named) now." : "your crew has no name now.", 4.0);
    CBLog.Info(n"Crew", s"V named the crew: \(named).");
  }
  // Every order asked for, in the order asked; each for a member still on the roster, here and not away.
  let asks: array<ref<CBCrewKitAsk>>;
  for queued in kb.asks {
    ArrayPush(asks, queued);
  }
  ArrayClear(kb.asks);
  for a in asks {
    let m = IsDefined(a) ? book.Find(a.member) : null;
    if IsDefined(m) && !book.IsOut(m.id) && !CBCrewAway(game, m.id, now) {
      if a.what == CBCrewAskTakeBack() { CBCrewTakeBack(sys, game, kb, m); }
      if a.what == CBCrewAskGive() { CBCrewGiveWeapon(sys, game, kb, m, a.item); }
      if a.what == CBCrewAskChrome() { CBCrewInstallChrome(sys, game, kb, m, a.item); }
      if a.what == CBCrewAskTrain() { CBCrewSendTraining(sys, game, kb, m, now); }
      if a.what == CBCrewAskWar() { CBCrewSendToWar(sys, game, kb, m, a.gang, now); }
      if a.what == CBCrewAskSpar() { CBCrewSparStart(sys, game, kb, m, now); }
      if a.what == CBCrewAskWork() { CBCrewSetWork(sys, game, m); }   // earning, recruiting, or none (CrewBanner.reds)
    }
  }
  CBCrewKitReturns(sys, game, kb, book, now);
  CBCrewSparTick(sys, game, kb, book, now);
  CBCrewEarnTick(sys, game, kb, book, now);
  CBCrewBannerTick(sys, game, now);
}

// ---- A spar --------------------------------------------------------------------------------------

public func CBCrewSparDayOf(now: Float) -> Int32 {
  return Cast<Int32>(now / CBConfig.SecondsPerDay()) + 1;
}

// Why a spar cannot start now, or "".
public func CBCrewSparBlocked(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, now: Float) -> String {
  let player = GetPlayer(game);
  let kb = CBCrewKitBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(player) || !IsDefined(kb) || !IsDefined(book) || !IsDefined(m) {
    return "nobody to spar with";
  }
  if kb.sparMember > 0 {
    return "a round is already on";
  }
  if book.OutCount() > 0 {
    return "your crew is out with you";
  }
  if book.IsOut(m.id) || CBCrewAway(game, m.id, now) {
    return "they are not here";
  }
  if CBCrewHurt(m, now) {
    return "they are hurt";
  }
  let k = kb.Find(m.id);
  if IsDefined(k) && k.sparDay == CBCrewSparDayOf(now) {
    return "once a day each";
  }
  if player.IsInCombat() || CBArrivalsHeld(sys, game) || IsDefined(player.GetMountedVehicle()) || sys.IsInSafeZone() {
    return "not here, not now";
  }
  if CBHuntersOut(sys, game) || CBHuntPending(sys) {
    return "somebody is hunting you";
  }
  if CBSpawnRoom(game) < 1 {
    return "too many people around";
  }
  return "";
}

func CBCrewSparStart(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>, now: Float) -> Void {
  let blocked = CBCrewSparBlocked(sys, game, m, now);
  if StrLen(blocked) > 0 {
    CBSystemNote(game, s"no spar: \(blocked).", 4.0);
    return;
  }
  let record = m.record;
  if (!TDBID.IsValid(record) || !CBRecordIsPerson(record)) && NotEquals(m.faction, n"") {
    record = CBGangTemplate(sys, m.faction);
  }
  let body: EntityID;
  if !TDBID.IsValid(record) || CBSpawnGroup(game, record, m.look, 1, n"CB_Own", CBConfig.CrewSparSpawnDistance(), body, n"CB_Spar") == 0 {
    CBSystemNote(game, "no spar: they could not get to you.", 4.0);
    return;
  }
  kb.sparMember = m.id;
  kb.sparBody = body;
  kb.sparStart = sys.GetTickCount();
  kb.sparSeen = 0;
  CBCrewText(sys, game, m, "On my way. Hands up when I get there. Don't hold back, I won't.");
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
    CBAddMult(stats, id, gamedataStatType.Health, CBConfig.CrewSparHealthMult());
    CBAddMult(stats, id, gamedataStatType.PhysicalDamage, CBConfig.CrewSparDamageMult());
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
  if k.spars % CBConfig.CrewSparsPerTraining() == 0 && k.trained < CBConfig.CrewTrainMax() {
    k.trained += 1;
    levelled = true;
  }
  let line = how == 1 ? "You got me. Good round. I'll be sharper for it."
           : (how == 2 ? "Told you I wouldn't hold back. Again tomorrow?" : "Time. Not bad, either of us.");
  if levelled {
    line += s" That's the work of a \(StrLower(CBCrewRankWord(CBCrewRankOf(game, m)))) now.";
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
    CBCrewText(sys, game, m, "That went too far. I'll live. Give me a couple of days.");
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
  if total <= 0 {
    return;
  }
  CBStreetGiveMoney(game, total);
  let note = s"Your crew's work brought in \(total)eb.";
  if StrLen(hurt) > 0 {
    note += s" \(hurt) got hurt doing it.";
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
  let data = ts.GetItemData(player, item);
  if !IsDefined(data) || RPGManager.IsItemEquipped(player, item) {
    CBSystemNote(game, "that weapon is not in your bag any more.", 4.0);
    return;
  }
  let seat = CBCrewSeatForWeapon(data.GetItemType());
  if seat < 0 {
    return;
  }
  let k = kb.Kit(m.id);
  // One at a time: the one they had comes back first.
  CBCrewReturnWeapon(game, k);
  // Its mods and attachments back into V's bag, the way the game's own stash takes them off (stash.script).
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
  CBCrewText(sys, game, m, s"\(what). \(tier >= 3 ? "That's a serious piece. I'll bring it back in one piece." : "I'll put it to work.")");
  CBLog.Info(n"Crew", s"V gave one of the crew a weapon (\(CBCrewSeatWord(seat)), tier \(tier)).");
}

func CBCrewTakeBack(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>) -> Void {
  let k = kb.Find(m.id);
  if CBCrewReturnWeapon(game, k) {
    CBSystemNote(game, s"\(CBCrewName(sys, m)) handed your weapon back.", 4.0);
  }
}

func CBCrewInstallChrome(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>, item: ItemID) -> Void {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) || !ItemID.IsValid(item) {
    return;
  }
  let k = kb.Kit(m.id);
  if ArraySize(k.chrome) >= CBConfig.CrewChromeMax() {
    CBSystemNote(game, s"\(CBCrewName(sys, m)) has no room for more chrome.", 4.0);
    return;
  }
  let rec = ItemID.GetTDBID(item);
  let area = CBCrewChromeArea(rec);
  if area < 0 || RPGManager.IsItemEquipped(player, item) || !ts.RemoveItem(player, item, 1) {
    CBSystemNote(game, "that implant is not in your bag any more.", 4.0);
    return;
  }
  ArrayPush(k.chrome, rec);
  CBCrewText(sys, game, m, s"Got the \(CBCrewItemName(rec)) put in. Feel it already. More \(CBCrewChromeWord(area)), next time you call.");
  CBLog.Info(n"Crew", s"V had chrome put in one of the crew (\(CBCrewChromeWord(area))).");
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
    CBSystemNote(game, s"training costs \(cost)eb.", 4.0);
    return;
  }
  ts.RemoveItem(player, ItemID.FromTDBID(t"Items.money"), cost);
  let hours = CBCrewTrainHours(k);
  k.trainUntil = now + hours * CBConfig.SecondsPerHour();
  CBCrewText(sys, game, m, s"Heading out. Give me \(RoundF(hours)) hours, and I'll come back worth more.");
  CBLog.Info(n"Crew", s"One of the crew went to train (level \(k.trained + 1), \(cost)eb).");
}

func CBCrewSendToWar(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>, gang: CName, now: Float) -> Void {
  if Equals(gang, n"") || CBCrewRankOf(game, m) < CBConfig.CrewWarMinRank() || CBCrewHurt(m, now) {
    return;
  }
  let k = kb.Kit(m.id);
  k.warOn = gang;
  k.warUntil = now + CBConfig.CrewWarHours() * CBConfig.SecondsPerHour();
  CBCrewText(sys, game, m, s"\(CBCapFirst(CBFactionLabel(gang))). Consider it started. You won't hear from me for a while.");
  CBLog.Info(n"Crew", s"One of the crew went to start a war on \(NameToString(gang)).");
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
      k.trained += 1;
      m.loyalty = Min(100, m.loyalty + CBConfig.CrewTrainLoyalty());
      CBCrewText(sys, game, m, s"Back. \(CBCrewRankWord(CBCrewRankOf(game, m))) now, better gear, and they put in some field chrome. Call me.");
      CBLog.Info(n"Crew", "One of the crew is back from training.");
    }
    if IsDefined(k) && k.warUntil > 0.0 && now >= k.warUntil {
      let gang = k.warOn;
      k.warUntil = 0.0;
      k.warOn = n"";
      if CBCrewWarResolve(sys, game, kb, book, m, k, gang, now) {
        return;   // the roster changed under the walk
      }
    }
  }
}

// How a war a crew member started went. True when they did not come back (the roster changed).
func CBCrewWarResolve(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, book: ref<CBCrewBook>,
                      m: ref<CBCrewMember>, k: ref<CBCrewKit>, gang: CName, now: Float) -> Bool {
  if Equals(gang, n"") {
    return false;
  }
  let rank = CBCrewRankOf(game, m);
  let strength = CBGangStrength(sys, gang) / 100.0;
  let chance = CBConfig.CrewWarBase() + CBConfig.CrewWarPerRank() * Cast<Float>(rank)
             + 0.03 * Cast<Float>(ArraySize(k.chrome)) + 0.02 * Cast<Float>(k.weaponTier) + 0.03 * Cast<Float>(k.trained)
             - CBConfig.CrewWarStrengthWeight() * strength;
  // A gang that already hates the crew is ready for it; one that respects it is caught out (Reactions/CrewBanner.reds).
  chance += CBConfig.CrewStandWarWeight() * Cast<Float>(CBCrewStandingWith(game, gang)) / 100.0;
  chance = ClampF(chance, 0.15, 0.9);
  let label = CBFactionLabel(gang);
  if RandF() < chance {
    CBWeakenGang(sys, game, gang, CBConfig.CrewWarGangLoss());
    CBTalkSlight(sys, game, gang, CBConfig.CrewWarStanding());
    CBCrewStandingShift(game, gang, -CBConfig.CrewStandWarWon());
    let content = sys.GetContent();
    let enemy = IsDefined(content) ? CBTopEnemyOf(sys, content, gang) : n"";
    CBCrewStandingShift(game, enemy, CBConfig.CrewStandWarEnemy());   // the enemy of their enemy
    m.wins += 2;
    m.loyalty = Min(100, m.loyalty + 5);
    kb.NoteWarWon();
    CBFileLog(sys, n"CrewWarWon", now, CBEventDistrict(sys, game), gang, Cast<Float>(m.id));
    CBCrewText(sys, game, m, s"It's done. \(CBCapFirst(label)) lost corners, people and nerve. They know whose crew did it, so watch yourself.");
    CBLog.Info(n"Crew", s"A crew member's war on \(NameToString(gang)) was won.");
    return false;
  }
  CBCrewStandingShift(game, gang, -CBConfig.CrewStandWarLost());
  if RandF() < CBConfig.CrewWarDeathShare() {
    let name = CBCrewName(sys, m);
    CBFileLog(sys, n"CrewWarLost", now, CBEventDistrict(sys, game), gang, Cast<Float>(m.id));
    let bb = CBCrewBannerBook.Get(game);
    if IsDefined(bb) {
      bb.fallCause = CBCrewFellAtWar();   // for the memorial
      bb.fallGang = gang;
    }
    book.Remove(m, CBCrewEndFell(), 0, CBEventDistrict(sys, game), now);
    if CBMessagesOn() {
      CBPhoneSendTinted(game, CBCapFirst(label), s"\(name) came for us. \(name) isn't coming back.", CBHudRed());
    }
    CBLog.Info(n"Crew", s"A crew member died in their war on \(NameToString(gang)).");
    return true;
  }
  m.hurtUntil = now + CBConfig.CrewWarHurtHours() * CBConfig.SecondsPerHour();
  CBTalkSlight(sys, game, gang, CBConfig.CrewWarStanding() * 0.5);
  CBCrewText(sys, game, m, s"\(CBCapFirst(label)) were ready for me. I got out, barely. I need a few days.");
  CBLog.Info(n"Crew", s"A crew member's war on \(NameToString(gang)) was lost; they came back hurt.");
  return false;
}

// What the card says about their kit, a line or two.
public func CBCrewKitLines(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return "";
  }
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  let rank = CBCrewRankOf(game, m);
  let out = s"Rank: \(CBCrewRankWord(rank)) (\(rank) of 6).";
  if IsDefined(k) {
    if k.hasWeapon {
      out += s" Carrying your \(CBCrewItemName(ItemID.GetTDBID(k.weapon))) (\(CBCrewTierWord(k.weaponTier))): they fight as a \(CBCrewSeatWord(m.seat)).";
    }
    if ArraySize(k.chrome) > 0 {
      let parts = "";
      for c in k.chrome {
        parts += (StrLen(parts) > 0 ? ", " : "") + CBCrewItemName(c);
      }
      out += s" Chrome: \(parts).";
    }
    if k.trained > 0 {
      out += s" Trained \(k.trained) of \(CBConfig.CrewTrainMax()) times.";
    }
    let away = CBCrewAwayWord(game, m.id, CBGameSeconds(game));
    if StrLen(away) > 0 {
      out += s" \(CBCapFirst(StrLower(away))).";
    }
  }
  if IsDefined(k) && k.sharpUntil > CBGameSeconds(game) {
    out += " Sharp from a spar.";
  }
  if IsDefined(k) && k.earning {
    out += " Working the street for you.";
  }
  if CBCrewIsRecruiter(game, m.id) {
    out += " Recruiting for the crew: the broker's solos come more often, cheaper, and with fights behind them.";
    let roster = CBCrewBook.Get(game);
    if IsDefined(roster) && !roster.HasRoom() {
      out += " Your crew is full, so they have nobody to bring until somebody leaves.";
    }
  }
  if IsDefined(k) && k.spars > 0 {
    out += s" Sparred \(k.spars) times.";
  }
  if rank < CBConfig.CrewWarMinRank() {
    out += s" At \(CBCrewRankWord(CBConfig.CrewWarMinRank())) they can be sent to start a war.";
  }
  return out;
}
