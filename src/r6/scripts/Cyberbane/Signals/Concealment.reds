// Cyberbane - What your clothes hide (spec §8.6)
//
// Chrome only frightens people who can see it. A coat over gorilla arms is a coat over gorilla
// arms, and the street reacts to what is on show rather than to what is installed. Until now
// visible chrome was computed purely from what V had fitted, so a fully chromed merc in a
// parka read exactly as loud as the same merc in a vest.
//
// **What is worn, read the way the game draws it (1.9.0).** Two sources, both always read:
//
//   1. The game's own clothing areas, as drawn. With an outfit preset on, an area shows the preset's
//      item; an area the preset clears shows nothing, whatever is equipped under it; an area the
//      preset leaves alone shows what is equipped. With no preset, an area shows what is equipped
//      unless its hide switch is on. That is the game's rule (EquipmentSystemPlayerData: EquipVisuals,
//      ClearVisuals, UnequipVisuals), and CBVisibleInArea follows it. The reading before this fell
//      back to the equipped item whenever the preset's slot was empty, so a preset that showed bare
//      arms still counted the jacket under it.
//   2. Anything else of V's clothing that is physically on V (CBAttachedGarments): what an outfit mod
//      such as EquipmentEx puts in slots of its own, which the game's clothing areas know nothing about.
//      Asked of the game by item ("is this attached to V anywhere", TransactionSystem.HasItemInAnySlot),
//      so no slot name of any mod is typed here, and an item the game's areas already account for, or
//      a second copy of a garment already counted, is left out.
//
// **What a garment covers, by what the game says it is.** The garment records answer it. The game tags
// its own long-sleeved garments LongSleeve (all its shirts, nearly all jackets and coats, a few vests,
// no t-shirts, tank tops or undershirts), and every base-game torso garment carries style tags, so a
// tagged one without it has bare arms (CBGarmentSleeves). Its jumpsuits are tagged BodySuit instead and
// cover arms and legs; so are its dresses, which cover neither, so a suit is BodySuit on a jumpsuit
// (Price.Jumpsuit, Price.TightJumpsuit). Shorts and skirts are their own kinds of garment to the game
// (Price.Shorts, Price.Skirt, inherited by every one of them). A whole-body outfit item covers both, as
// it always did. Checked by script against every base-game garment record. Before
// this, an outer layer covered the arms and an inner one never did: a vest hid gorilla arms and a
// long-sleeved shirt did not. A garment with no tags at all - most likely from a mod that set none - is
// read the old way: an outer layer covers, an inner one does not.
//
// Read once a sample (CBReadWorn), and that one reading answers the chrome, the look, the disguise and
// the mask.

public class CBWornRead {
  public let garments: array<ItemID>;   // everything a stranger can see V wearing, one per garment
  public let arms: Bool;
  public let legs: Bool;
  public let face: Bool;
  public let masked: Bool;
  public let fromMods: Int32;           // how many of the garments only the attached-clothing read found
  // They Will Remember's own reading of the same clothes, when it is the one deciding disguises (2.4.2):
  // whether it answered, how much of V's face it counts hidden (0..1, -1 when its face disguise is off),
  // and whose gear it says V passes in and how well (n"" and 0 for nobody, or its gang disguise off).
  public let twrRead: Bool;
  public let twrFace: Float;
  public let twrGangOn: Bool;
  public let twrFaction: CName;
  public let twrCover: Float;
  // Whether its gang reading could be asked at all (2.5.1): a version of theirs without one leaves the gang
  // disguise to Cyberbane's own reading instead of to nobody.
  public let twrGangRead: Bool;
}

func CBClothingAreas() -> array<gamedataEquipmentArea> {
  let areas: array<gamedataEquipmentArea>;
  ArrayPush(areas, gamedataEquipmentArea.Head);
  ArrayPush(areas, gamedataEquipmentArea.Face);
  ArrayPush(areas, gamedataEquipmentArea.OuterChest);
  ArrayPush(areas, gamedataEquipmentArea.InnerChest);
  ArrayPush(areas, gamedataEquipmentArea.Legs);
  ArrayPush(areas, gamedataEquipmentArea.Feet);
  ArrayPush(areas, gamedataEquipmentArea.Outfit);
  return areas;
}

// One of the game's clothing areas as it is drawn (point 1 above).
func CBVisibleInArea(data: ref<EquipmentSystemPlayerData>, area: gamedataEquipmentArea) -> ItemID {
  if !IsDefined(data) {
    return ItemID.None();
  }
  // The Outfit area has no preset slot and no hide switch. IsSlotHidden finds its row with the same
  // search GetVisualItemInSlot uses, which answers -1 for the Outfit area, and reads that row without
  // a check: asked about the Outfit area it would read before the start of the game's table.
  let outfit = Equals(area, gamedataEquipmentArea.Outfit);
  if !outfit && data.IsVisualSetActive() {
    let visual = data.GetVisualItemInSlot(area);
    if ItemID.IsValid(visual) {
      return visual;
    }
  }
  if !outfit && data.IsSlotHidden(area) {
    return ItemID.None();
  }
  return data.GetActiveItem(area);
}

// Is this item one of these? By value, item by item.
func CBItemListHas(list: array<ItemID>, id: ItemID) -> Bool {
  for known in list {
    if Equals(known, id) {
      return true;
    }
  }
  return false;
}

// Is a garment of this record already in the list? The wardrobe draws a preset item on a body with
// nothing equipped there by attaching a preview copy of it, which is another item of the same record.
func CBGarmentRecordListed(list: array<ItemID>, id: ItemID) -> Bool {
  let record = ItemID.GetTDBID(id);
  for known in list {
    if ItemID.GetTDBID(known) == record {
      return true;
    }
  }
  return false;
}

// V's clothing that is on V and that the game's clothing areas do not account for (point 2 above).
// `equipped` is what is equipped in those areas, drawn or not: an equipped item a preset hides is still
// attached, with its look cleared, and must not count as worn.
func CBAttachedGarments(game: GameInstance, equipped: array<ItemID>, seen: array<ItemID>) -> array<ItemID> {
  let out: array<ItemID>;
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return out;
  }
  let list: array<wref<gameItemData>>;
  if !ts.GetItemListByTag(player, n"Clothing", list) {
    return out;
  }
  let n = Min(ArraySize(list), CBConfig.WornScanCap());
  let i = 0;
  while i < n {
    let d = list[i];
    i += 1;
    if IsDefined(d) {
      let id = d.GetID();
      // A yes or no from the slots' own bookkeeping (1.9.5). GetItemInSlotByItemID answered the same
      // question by handing back the garment's spawned object, which for a copy an outfit mod is putting
      // on or taking off can be half made or on its way out; nothing here needs the object.
      if ItemID.IsValid(id) && !CBItemListHas(equipped, id) && !CBGarmentRecordListed(seen, id)
         && !CBGarmentRecordListed(out, id) && ts.HasItemInAnySlot(player, id) {
        ArrayPush(out, id);
      }
    }
  }
  return out;
}

// The kind of body this garment is worn on, from its own record: what the game files it under.
func CBGarmentArea(id: ItemID) -> gamedataEquipmentArea {
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  if !IsDefined(rec) || !IsDefined(rec.EquipArea()) {
    return gamedataEquipmentArea.Invalid;
  }
  return rec.EquipArea().Type();
}

// The words the game tags every one of its own torso garments with, whatever their sleeves.
func CBGarmentHasStyleTags(rec: ref<Item_Record>) -> Bool {
  return rec.TagsContains(n"Simple") || rec.TagsContains(n"Stylish") || rec.TagsContains(n"Rich")
      || rec.TagsContains(n"Poor") || rec.TagsContains(n"Streetwear") || rec.TagsContains(n"Casual")
      || rec.TagsContains(n"Military") || rec.TagsContains(n"Formal") || rec.TagsContains(n"Punk")
      || rec.TagsContains(n"Rocker") || rec.TagsContains(n"Biker") || rec.TagsContains(n"Cowboy")
      || rec.TagsContains(n"Sports") || rec.TagsContains(n"Industrial") || rec.TagsContains(n"Corpo")
      || rec.TagsContains(n"Tomboy") || rec.TagsContains(n"Samurai");
}

// ---- Whose tags they are (2.7.8) ----------------------------------------------------------------
//
// "Ever since the latest Equipment-EX / WEAVE updates, outfits don't hide chrome anymore. A full body suit and a face
// covering helmet, and the chrome rating stays at 89." WEAVE's auto-tagger gives every garment a clothing mod left
// untagged one of the game's own style tags and a wealth tag, often a gang's too (Casual, Simple, Moxies), so the
// game's crowds and Cyberbane's look and gang disguises read modded clothes the way they read the game's. Cyberbane
// read sleeves from those same words: a garment the game tags is either LongSleeve or bare-armed, so a style tag with
// no LongSleeve meant bare arms. Written by WEAVE it means nothing about sleeves, since WEAVE never writes them, and
// every modded jacket, coat and body suit read bare-armed: the chrome under them counted in full.
//
// So a missing LongSleeve says bare arms only when the game wrote the garment's tags, and that cannot be told from the
// record once WEAVE has been: with RedFunctions it writes its tags into a TweakXL file that loads at start, where they
// look exactly like the game's. WEAVE also gives a reaction tag to every garment it scans, the game's own included, and
// no garment in the game carries one of its own, so with its tagger installed every garment V owns has been through it.
// While it is installed no style tag is taken as the game's word on sleeves; a garment's kind is.
//
// A garment's kind is the price record every garment of that kind inherits (Price.Jacket, Price.TShirt), which no
// tagger touches. Against the game's own clothes, checked by script (tools/redmod/tweaks): shirts, loose shirts and
// formal jackets are sleeved, every one; jackets 234 of 249, coats 58 of 64. T-shirts, tank tops, undershirts and
// dresses never are; vests 3 of 170, and those three carry LongSleeve. Formal shirts (19 of 27) and tight jumpsuits go
// both ways and say nothing. With WEAVE installed, the game's eighteen bare-armed jackets, coats and formal shirts read
// as their kind does: the price of knowing nothing else about the rest.

// WEAVE's auto-tagger, looked for once a launch through Codeware reflection, so nothing here names anything of WEAVE's.
// Without RedFunctions WEAVE ships an empty stand-in under the same name, which tags nothing; the real one is told
// apart by a function only it has.
public class CBWeaveProbe {
  public let state: Int32;   // 0 not looked yet, 1 its tagger is installed, 2 not

  public func Resolve() -> Bool {
    if this.state == 0 {
      this.state = 2;
      let cls = Reflection.GetClass(n"EquipmentEx.AutoTagEngine");
      if IsDefined(cls) && IsDefined(cls.GetFunction(n"ProcessBatch")) {
        this.state = 1;
        CBLog.Info(n"Signals", "WEAVE's auto-tagger found: clothes go by their kind for sleeves, and its face tags count.");
      }
    }
    return this.state == 1;
  }
}

// Are the style tags on a garment the game's own word on it? False while WEAVE's tagger is installed (above).
public func CBStyleTagsAreTheGames() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.GetWeaveProbe().Resolve();
}

// Sleeves by kind of garment: 1 the game sleeves its own of this kind, 0 it does not, -1 either way or no kind on record.
// One pass over the garment's price records.
func CBGarmentKindSleeves(id: ItemID) -> Int32 {
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  if !IsDefined(rec) {
    return -1;
  }
  let k = 0;
  while k < rec.GetBuyPriceCount() {
    let price = rec.GetBuyPriceItem(k);
    k += 1;
    if IsDefined(price) {
      let p = price.GetID();
      if p == t"Price.Jacket" || p == t"Price.Coat" || p == t"Price.Shirt" || p == t"Price.LooseShirt"
         || p == t"Price.FormalJacket" || p == t"Price.Jumpsuit" {
        return 1;
      }
      if p == t"Price.TShirt" || p == t"Price.TankTop" || p == t"Price.Undershirt" || p == t"Price.Vest"
         || p == t"Price.Dress" {
        return 0;
      }
    }
  }
  return -1;
}

// Is this garment of either of these kinds? The game's kinds of garment are carried in the price record
// each kind sets and every garment of it inherits (Price.Shorts, Price.Jumpsuit, ...).
func CBGarmentPricedAs(id: ItemID, a: TweakDBID, b: TweakDBID) -> Bool {
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  if !IsDefined(rec) {
    return false;
  }
  let k = 0;
  while k < rec.GetBuyPriceCount() {
    let price = rec.GetBuyPriceItem(k);
    k += 1;
    if IsDefined(price) && (price.GetID() == a || price.GetID() == b) {
      return true;
    }
  }
  return false;
}

// One piece from wrist to ankle: a jumpsuit the game tags BodySuit. Its dresses carry the same tag and
// cover neither arms nor legs. Every one of the game's jumpsuits is tagged so, and a clothing mod's built on the game's
// jumpsuit is not (the tag is set garment by garment, not by the kind), so the kind alone makes one (2.7.8); a tight
// jumpsuit still needs the tag, since the game makes those both ways.
func CBGarmentIsSuit(id: ItemID) -> Bool {
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  if !IsDefined(rec) {
    return false;
  }
  return CBGarmentPricedAs(id, t"Price.Jumpsuit", t"Price.Jumpsuit")
      || (rec.TagsContains(n"BodySuit") && CBGarmentPricedAs(id, t"Price.TightJumpsuit", t"Price.TightJumpsuit"));
}

// Sleeves, as the game records them: 1 long (LongSleeve, or a suit), 0 bare arms (a garment the game tagged that says
// neither), and otherwise what the game makes garments of its kind with (CBGarmentKindSleeves), -1 for a kind it makes
// both ways or none. Style tags another mod wrote say nothing about sleeves (CBStyleTagsAreTheGames, 2.7.8).
func CBGarmentSleeves(id: ItemID) -> Int32 {
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  if !IsDefined(rec) {
    return -1;
  }
  if rec.TagsContains(n"LongSleeve") || CBGarmentIsSuit(id) {
    return 1;
  }
  if CBGarmentHasStyleTags(rec) && CBStyleTagsAreTheGames() {
    return 0;
  }
  return CBGarmentKindSleeves(id);
}

// Shorts or a skirt: a legs garment that leaves the lower legs on show.
func CBGarmentLeavesLegsBare(id: ItemID) -> Bool {
  return CBGarmentPricedAs(id, t"Price.Shorts", t"Price.Skirt");
}

// Does this garment hide V's arms?
func CBGarmentCoversArms(id: ItemID, area: gamedataEquipmentArea) -> Bool {
  // A whole-body outfit item is the whole body.
  if Equals(area, gamedataEquipmentArea.Outfit) {
    return true;
  }
  let outer = Equals(area, gamedataEquipmentArea.OuterChest);
  if !outer && !Equals(area, gamedataEquipmentArea.InnerChest) {
    // Sleeves an outfit mod files somewhere else still cover arms (1.9.4).
    return CBGarmentSleeves(id) == 1;
  }
  let sleeves = CBGarmentSleeves(id);
  if sleeves == 1 {
    return true;
  }
  if sleeves == 0 {
    return false;
  }
  return outer;   // nothing on record: the old answer, an outer layer covers and an inner one does not
}

// Does this garment hide V's legs?
func CBGarmentCoversLegs(id: ItemID, area: gamedataEquipmentArea) -> Bool {
  if Equals(area, gamedataEquipmentArea.Legs) {
    return !CBGarmentLeavesLegsBare(id);
  }
  if Equals(area, gamedataEquipmentArea.Outfit) {
    return true;
  }
  return CBGarmentIsSuit(id);
}

// A mask, as opposed to sunglasses.
//
// Glasses hide eye chrome and nothing else; a mask hides who you are. The game knows the
// difference - face clothing descends from Glasses, Mask, Visor or Tech - but it keeps that
// distinction only in record inheritance, and gamedataItemType flattens all of it to Clo_Face,
// so it cannot be read back at runtime. What survives is the record id, and every one of the
// eleven mask records in the base game carries "Mask" in its name: Mask_03_basic_01,
// Nomad_01_Set_Mask, TygerClawsMask, WraithsMask. Glasses carry "Glasses" and visors "Visor",
// so neither is caught by this.
//
// Same class of heuristic as the cyberpsycho check, with the same honest failure: a mask from
// another mod named something else will not count, which simply leaves the old behaviour.
//
// 1.9.3: the record does keep it, in what the thing costs. Every mask descends from a base that is
// priced as Price.Mask and every balaclava from one priced as Price.Balaclava, the same way jumpsuits
// and shorts are told apart above. A record's name can only be read with Cyber Engine Tweaks
// installed, so on any other install no mask ever counted; and a balaclava sits on the head, which
// was never looked at. The name stays as the fallback for a mask another mod prices its own way.
//
// 2.7.8: or what another mod has written on it. The game keeps no word in its records for a helmet that closes over the
// face; WEAVE does, tagging helmets, balaclavas, gas masks and respirators FullFace and half masks, face plates and
// visors Mask, and a player can set or take off either tag in its wardrobe. No garment in the game carries either tag
// itself (only photo mode lists Mask, as a look, never on a record). FullFace hides who V is; Mask does on anything but
// eyewear the game prices as glasses or a visor, which hides the eyes alone, as it always has here.
func CBItemIsMask(id: ItemID) -> Bool {
  if CBGarmentPricedAs(id, t"Price.Mask", t"Price.Balaclava") {
    return true;
  }
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  if IsDefined(rec) && (rec.TagsContains(n"FullFace")
     || (rec.TagsContains(n"Mask") && !CBGarmentPricedAs(id, t"Price.Glasses", t"Price.Visor"))) {
    return true;
  }
  if !Equals(CBGarmentArea(id), gamedataEquipmentArea.Face) {
    return false;
  }
  let name = TDBID.ToStringDEBUG(ItemID.GetTDBID(id));
  return StrLen(name) > 0 && (StrContains(name, "Mask") || StrContains(name, "mask"));
}

// Do V's clothes count at all? A player asked to dress for looks alone. Off, nothing V wears is
// read: no chrome is covered, no mask hides who V is, no gang's colours fool anybody and no outfit
// makes V look more or less dangerous (1.9.3).
public func CBClothingCounts() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().clothingCounts;
}

// What V is wearing, both sources, and what it covers. One call per sample.
public func CBReadWorn(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> ref<CBWornRead> {
  // Never while a load is still putting V back together (CyberbaneSystem.WornReady, 1.9.5): the last
  // reading, if there is one, and otherwise nothing worn.
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) || !sys.WornReady() {
    if IsDefined(sys) && IsDefined(sys.GetWorn()) {
      return sys.GetWorn();
    }
    return new CBWornRead();
  }
  let worn = new CBWornRead();
  if !IsDefined(data) || !CBClothingCounts() {
    return worn;
  }
  // Equipment-EX wearing an outfit (1.9.4): what people see is that outfit, nothing else.
  let eqexSlots: array<TweakDBID>;
  if CBEqExOutfitSlots(game, eqexSlots) {
    CBReadEqExOutfit(game, worn, eqexSlots);
    CBReadTwrDisguise(game, worn);
    return worn;
  }
  let equipped: array<ItemID>;
  for area in CBClothingAreas() {
    let active = data.GetActiveItem(area);
    if ItemID.IsValid(active) {
      ArrayPush(equipped, active);
    }
    let shown = CBVisibleInArea(data, area);
    if ItemID.IsValid(shown) && !CBGarmentRecordListed(worn.garments, shown) {
      ArrayPush(worn.garments, shown);
    }
  }
  let extra = CBAttachedGarments(game, equipped, worn.garments);
  worn.fromMods = ArraySize(extra);
  for id in extra {
    ArrayPush(worn.garments, id);
  }
  for id in worn.garments {
    CBCountGarment(worn, id, CBGarmentArea(id), false);
  }
  CBReadTwrDisguise(game, worn);
  return worn;
}

// What one garment covers, for both readings: the game's clothing areas here, Equipment-EX's outfit slots below (2.7.8,
// one rule for both). `wholeBody` is a garment worn from shoulders to ankles, an Equipment-EX body slot: it covers the
// legs unless it is a dress or leaves them bare, and the arms unless it is known to be bare-armed.
func CBCountGarment(worn: ref<CBWornRead>, id: ItemID, area: gamedataEquipmentArea, wholeBody: Bool) -> Void {
  if CBGarmentCoversArms(id, area) || (wholeBody && CBGarmentSleeves(id) != 0) {
    worn.arms = true;
  }
  if CBGarmentCoversLegs(id, area)
     || (wholeBody && !CBGarmentLeavesLegsBare(id) && !CBGarmentPricedAs(id, t"Price.Dress", t"Price.Dress")) {
    worn.legs = true;
  }
  if Equals(area, gamedataEquipmentArea.Face) {
    worn.face = true;
  }
  if CBItemIsMask(id) {
    worn.face = true;
    worn.masked = true;
  }
}

// The reading for V, for callers that have nothing else to hand.
public func CBReadPlayerWorn(game: GameInstance) -> ref<CBWornRead> {
  let player = GetPlayer(game);
  let es = CBGetSystem(game, n"EquipmentSystem") as EquipmentSystem;
  if !IsDefined(player) || !IsDefined(es) {
    return new CBWornRead();
  }
  return CBReadWorn(game, es.GetPlayerData(player));
}

// Is V's face hidden behind a mask right now? The question the witness system asks, on every kill, so
// it reads the last sample's answer (kept by CBUpdateChrome, every ten ticks and as the Hub opens)
// rather than reading the whole wardrobe again in the middle of a fight. Before the first sample it
// reads it there and then.
public func CBPlayerMasked(game: GameInstance) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) && IsDefined(sys.GetWorn()) {
    return sys.GetWorn().masked;
  }
  // Before the session's first settled tick nothing has been read and nothing may be (1.9.5).
  if !IsDefined(sys) || !sys.WornReady() {
    return false;
  }
  return CBReadPlayerWorn(game).masked;
}

// Does the street have any reason to scatter from this person?
//
// A mask means nobody can say who you are, and that is absolute rather than damped: wear one
// and people do not run. Not a smaller radius, not a lesser tier - nothing. The chrome is still
// on show and the reputation is still yours, but the stranger walking past has no way to
// connect the figure in front of them to any of it, and being nobody in particular is the whole
// reason to put a mask on.
//
// What this cannot and should not stop is the game's own panic. Open fire in a crowd and people
// run from the gunfire, mask or no mask, because that reaction belongs to Cyberpunk. This governs
// what Cyberbane adds on top: being feared on sight for who you are.
public func CBCrowdIgnoresPlayer(game: GameInstance) -> Bool {
  return CBPlayerMasked(game);
}

// How much of an area's chrome still shows once clothes are accounted for.
//
// Not zero: a coat moves, sleeves ride up, and something heavy underneath still changes how a
// person carries themselves. Covered chrome reads at a quarter, which keeps a chromed V in a
// coat more unsettling than an unchromed one in the same coat without making the coat
// pointless.
public func CBCoveredChromeMult() -> Float = 0.25

// What fraction of this area's visible weight survives being dressed.
public func CBChromeVisibility(area: gamedataEquipmentArea, worn: ref<CBWornRead>) -> Float {
  if !IsDefined(worn) {
    return 1.0;
  }
  if Equals(area, gamedataEquipmentArea.ArmsCW) && worn.arms {
    return CBCoveredChromeMult();
  }
  if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) && worn.arms {
    return CBCoveredChromeMult();   // the skin people can see is mostly arms and chest
  }
  if Equals(area, gamedataEquipmentArea.LegsCW) && worn.legs {
    return CBCoveredChromeMult();
  }
  if Equals(area, gamedataEquipmentArea.EyesCW) && worn.face {
    return CBCoveredChromeMult();
  }
  return 1.0;
}

// One-shot diagnostic: what the game actually tags V's clothes with.
//
// Written to the log once a session so the coverage rules above can one day be driven by real
// visual tags instead of by which slots are filled. Costs nothing and answers a question that
// cannot be answered by reading the game's files, because the tags live in the appearance
// archives rather than in TweakDB.
public func CBLogEquippedTags(game: GameInstance) -> Void {
  let player = GetPlayer(game);
  let es = CBGetSystem(game, n"EquipmentSystem") as EquipmentSystem;
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(es) || !IsDefined(ts) {
    CBLog.Info(n"Signals", "Clothing check: player or equipment system unavailable.");
    return;
  }
  let data = es.GetPlayerData(player);

  // Both routes, reported whether or not they find anything.
  //
  // The first version only logged items it found, so a session where nothing was found looked
  // exactly like a session where this never ran - which is what happened, and cost a round of
  // guessing. Silence is not evidence; say what was asked and what came back.
  let areas = [
    gamedataEquipmentArea.Head, gamedataEquipmentArea.Face, gamedataEquipmentArea.OuterChest,
    gamedataEquipmentArea.InnerChest, gamedataEquipmentArea.Legs, gamedataEquipmentArea.Feet,
    gamedataEquipmentArea.Outfit
  ];
  let byArea = 0;
  let i = 0;
  while i < ArraySize(areas) {
    if IsDefined(data) && ItemID.IsValid(data.GetActiveItem(areas[i])) {
      byArea += 1;
      let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(data.GetActiveItem(areas[i])));
      let line = "";
      if IsDefined(rec) {
        let tags = rec.VisualTags();
        for t in tags {
          line += NameToString(t) + " ";
        }
      }
      CBLog.Info(n"Signals", s"Worn (area): \(TDBID.ToStringDEBUG(ItemID.GetTDBID(data.GetActiveItem(areas[i])))) tags: \(line)");
    }
    i += 1;
  }

  // The wardrobe-aware route, reported separately from the plain equipment areas above. When a
  // visual set is on these two disagree, and which of them is right is the entire question.
  let byVisual = 0;
  let v = 0;
  while v < ArraySize(areas) {
    if IsDefined(data) {
      let vis = data.GetVisualItemInSlot(areas[v]);
      if ItemID.IsValid(vis) {
        byVisual += 1;
        CBLog.Info(n"Signals", s"Worn (visual): \(TDBID.ToStringDEBUG(ItemID.GetTDBID(vis)))");
      }
    }
    v += 1;
  }

  let slots = [
    t"AttachmentSlots.Head", t"AttachmentSlots.Face", t"AttachmentSlots.Chest",
    t"AttachmentSlots.Torso", t"AttachmentSlots.Legs", t"AttachmentSlots.Feet",
    t"AttachmentSlots.Outfit"
  ];
  let bySlot = 0;
  let j = 0;
  while j < ArraySize(slots) {
    let id = ts.GetActiveItemInSlot(player, slots[j]);
    if ItemID.IsValid(id) {
      bySlot += 1;
      CBLog.Info(n"Signals", s"Worn (slot): \(TDBID.ToStringDEBUG(slots[j])) holds \(TDBID.ToStringDEBUG(ItemID.GetTDBID(id)))");
    }
    j += 1;
  }
  CBLog.Info(n"Signals", s"Clothing check: \(byArea) by equipment area, \(byVisual) by wardrobe visual, \(bySlot) by attachment slot. Masked: \(CBPlayerMasked(game)).");
  // And what CBReadWorn makes of it all, which is what the chrome, the look and the mask go by, with
  // each garment's sleeves as the game records them (1 long, 0 bare, -1 not on record).
  let worn = CBReadWorn(game, data);
  let k = 0;
  while k < ArraySize(worn.garments) {
    let g = worn.garments[k];
    k += 1;
    CBLog.Info(n"Signals", s"Seen: \(TDBID.ToStringDEBUG(ItemID.GetTDBID(g))), sleeves \(CBGarmentSleeves(g)), covers arms \(CBGarmentCoversArms(g, CBGarmentArea(g))), legs \(CBGarmentCoversLegs(g, CBGarmentArea(g))).");
  }
  let sleevesBy = CBStyleTagsAreTheGames() ? "the game's tags, else the kind" : "the kind (WEAVE retags clothes)";
  CBLog.Info(n"Signals", s"Clothing read: \(ArraySize(worn.garments)) garments seen (\(worn.fromMods) only on V's body); arms covered \(worn.arms), legs \(worn.legs), face \(worn.face), masked \(worn.masked); sleeves by \(sleevesBy).");
}

// ---- Equipment-EX (1.9.4) ---------------------------------------------------------------------
//
// "I added layers with Equipment-EX that cover my arms, face and feet, and the score is still high."
// Equipment-EX blanks V's own clothing slots and shows its outfit as copies of the garments in slots
// of its own (OutfitSlots.*), so Cyberbane went on reading the clothes underneath. Asked through
// Codeware reflection, as They Will Remember is, so nothing here needs Equipment-EX to be installed.
//
// 1.9.5: read as data, never as objects. 1.9.4 asked the transaction system for the object in each
// outfit slot (GetItemInSlot) and read the garment off it. Those objects are the copies Equipment-EX
// spawns, and it clears and respawns them on every load and while its wardrobe changes an outfit, so an
// object asked for at the wrong moment was half made or already gone, and the game crashed reading it.
// Which garment a slot holds is in the slot's own bookkeeping the moment it is put there
// (GetActiveItemInSlot, an item id), and that is all a garment's sleeves, trousers and mask are read
// from. The reflection lookups are made once a launch and their return types checked, so a value is only
// ever taken out as the type it really is (CBEqExProbe).

// What Equipment-EX's outfit system offers, looked up once a launch. The functions belong to its class,
// not to a session, so they stay good across loads; the system itself is fetched fresh on every read.
public class CBEqExProbe {
  public let state: Int32;   // 0 not looked yet, 1 usable, 2 absent or not the shape this reads
  public let isActive: ref<ReflectionMemberFunc>;
  public let usedSlots: ref<ReflectionMemberFunc>;

  public func Resolve() -> Bool {
    if this.state == 0 {
      this.state = 2;
      let type = Reflection.GetClass(n"EquipmentEx.OutfitSystem");
      if IsDefined(type) {
        let active = type.GetFunction(n"IsActive");
        let used = type.GetFunction(n"GetUsedSlots");
        let activeParams: array<ref<ReflectionProp>>;
        let usedParams: array<ref<ReflectionProp>>;
        if IsDefined(active) {
          activeParams = active.GetParameters();
        }
        if IsDefined(used) {
          usedParams = used.GetParameters();
        }
        if IsDefined(active) && IsDefined(used)
           && ArraySize(activeParams) == 0 && ArraySize(usedParams) == 0
           && CBReflectReturns(active, n"Bool") && CBReflectReturns(used, n"array:TweakDBID") {
          this.isActive = active;
          this.usedSlots = used;
          this.state = 1;
          CBLog.Info(n"Signals", "Equipment-EX found: its outfits are read as what V is wearing.");
        }
      }
    }
    return this.state == 1;
  }
}

// Does this function hand back exactly this type? Checked before any value it returns is taken out of
// its Variant, so a version of somebody else's mod that changed a signature reads as absent, not wrong.
func CBReflectReturns(fn: ref<ReflectionFunc>, typeName: CName) -> Bool {
  if !IsDefined(fn) {
    return false;
  }
  let ret = fn.GetReturnType();
  return IsDefined(ret) && Equals(ret.GetName(), typeName);
}

// The outfit slots Equipment-EX has filled, when it is wearing an outfit at all.
public func CBEqExOutfitSlots(game: GameInstance, out slots: array<TweakDBID>) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return false;
  }
  let probe = rt.GetEqExProbe();
  if !probe.Resolve() {
    return false;
  }
  let container = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return false;
  }
  let outfits = container.Get(n"EquipmentEx.OutfitSystem");
  if !IsDefined(outfits) {
    return false;
  }
  let none: array<Variant>;
  if !FromVariant<Bool>(probe.isActive.Call(outfits, none)) {
    return false;
  }
  slots = FromVariant<array<TweakDBID>>(probe.usedSlots.Call(outfits, none));
  return true;
}

// What an Equipment-EX outfit covers, slot by slot. A garment keeps its own rules (long sleeves,
// trousers, a mask), and one in a body slot is worn from shoulders to ankles (CBEqExBodySlot, 2.7.8); the small layers
// it adds for hands, wrists, elbows, shoulders, thighs, knees and ankles cover a limb once two of its parts are covered.
func CBReadEqExOutfit(game: GameInstance, worn: ref<CBWornRead>, slots: array<TweakDBID>) -> Void {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return;
  }
  let armParts = 0;
  let legParts = 0;
  let armSeen: array<Int32>;
  let legSeen: array<Int32>;
  for slot in slots {
    // The garment the slot holds, by id (see the note above): its record is all that is read.
    let id = ts.GetActiveItemInSlot(player, slot);
    if ItemID.IsValid(id) {
      if !CBGarmentRecordListed(worn.garments, id) {
        ArrayPush(worn.garments, id);
        worn.fromMods += 1;
      }
      let area = CBGarmentArea(id);
      CBCountGarment(worn, id, area, CBEqExBodySlot(slot));
      if slot == t"OutfitSlots.Mask" || slot == t"OutfitSlots.Balaclava" {
        worn.face = true;
        worn.masked = true;
      }
      if slot == t"OutfitSlots.Glasses" || slot == t"OutfitSlots.Eyes" || slot == t"OutfitSlots.EyeLeft"
         || slot == t"OutfitSlots.EyeRight" {
        worn.face = true;
      }
      let arm = CBEqExArmPart(slot);
      if arm >= 0 && !ArrayContains(armSeen, arm) {
        ArrayPush(armSeen, arm);
        armParts += 1;
      }
      let leg = CBEqExLegPart(slot);
      if leg >= 0 && !ArrayContains(legSeen, leg) {
        ArrayPush(legSeen, leg);
        legParts += 1;
      }
    }
  }
  if armParts >= 2 {
    worn.arms = true;
  }
  if legParts >= 2 {
    worn.legs = true;
  }
}

// Which part of the arm an outfit slot covers: 0 hands, 1 wrists, 2 elbows, 3 shoulders; -1 none.
func CBEqExArmPart(slot: TweakDBID) -> Int32 {
  if slot == t"OutfitSlots.Hands" || slot == t"OutfitSlots.HandLeft" || slot == t"OutfitSlots.HandRight" {
    return 0;
  }
  if slot == t"OutfitSlots.WristLeft" || slot == t"OutfitSlots.WristRight" {
    return 1;
  }
  if slot == t"OutfitSlots.ElbowLeft" || slot == t"OutfitSlots.ElbowRight" {
    return 2;
  }
  if slot == t"OutfitSlots.ShoulderLeft" || slot == t"OutfitSlots.ShoulderRight" {
    return 3;
  }
  return -1;
}

// Equipment-EX's body slots (2.7.8): where it puts what is worn from shoulders to ankles, the game's tight jumpsuits and
// netrunner suits, its jumpsuits, whole outfits, and anything a clothing mod files there as a body suit. Equipment-EX
// hides V's chest and legs under all four. A body suit in one of them read as whatever its own record said, and a
// clothing mod's carries next to nothing, so the suit covered neither arms nor legs.
func CBEqExBodySlot(slot: TweakDBID) -> Bool {
  return slot == t"OutfitSlots.BodyUnder" || slot == t"OutfitSlots.BodyInner"
      || slot == t"OutfitSlots.BodyMiddle" || slot == t"OutfitSlots.BodyOuter";
}

// And of the leg: 0 thighs, 1 knees, 2 ankles; -1 none.
func CBEqExLegPart(slot: TweakDBID) -> Int32 {
  if slot == t"OutfitSlots.ThighLeft" || slot == t"OutfitSlots.ThighRight" {
    return 0;
  }
  if slot == t"OutfitSlots.KneeLeft" || slot == t"OutfitSlots.KneeRight" {
    return 1;
  }
  if slot == t"OutfitSlots.AnkleLeft" || slot == t"OutfitSlots.AnkleRight" {
    return 2;
  }
  return -1;
}

// ---- They Will Remember's disguises (2.4.2) -----------------------------------------------------
//
// "With a disguise score of 89 my standing stays the same." With They Will Remember installed and its
// compatibility on, Cyberbane handed it gang disguises and switched its own off, and never asked what They
// Will Remember made of V's clothes. So the two mods disagreed about the same outfit: They Will Remember
// said V's face was 89% hidden and V passed for a Tyger Claw, while Cyberbane's street, crews and hunters
// went on placing V as if V were bare-faced in street clothes, or as if no gang's gear counted at all.
// Its face reading is also much the finer one: it rates every helmet, hood and visor by how much of the
// face it leaves, where Cyberbane only knows masks and balaclavas.
//
// So whoever decides disguises decides them for both. With compatibility on and its disguise system
// answering, They Will Remember's face reading counts towards Cyberbane's mask (a face it counts mostly
// hidden is a mask), and its gang reading is Cyberbane's faction disguise. If it cannot be asked, or a
// version of it lacks these functions, Cyberbane's own reading stands, as before. Asked through Codeware
// reflection with every function's shape checked once a launch, as Equipment-EX is (CBEqExProbe), so
// nothing here names anything of theirs and no version of theirs can break this build.

public class CBTwrDisguiseProbe {
  public let state: Int32;   // 0 not looked yet, 1 usable, 2 absent or not the shape this reads
  public let ready: ref<ReflectionMemberFunc>;
  public let faceOn: ref<ReflectionMemberFunc>;
  public let gangOn: ref<ReflectionMemberFunc>;
  public let face: ref<ReflectionMemberFunc>;
  public let cover: ref<ReflectionMemberFunc>;
  public let coverScore: ref<ReflectionMemberFunc>;
  public let why: String;

  // 2.5.1: what it needs, not all six. Every one of the six had to be there in exactly its shape, so a version of theirs
  // that renamed or dropped any one (the switches, say) read as not there at all: "They Will Remember's disguises could
  // not be read". The face reading alone, or the gang reading alone, is enough now; a switch that is missing reads as
  // on, and readiness as ready. Which functions it lacks is kept for the Hub and the log, and a look that failed is
  // tried again each session (Retry).
  public func Resolve() -> Bool {
    if this.state == 0 {
      this.state = 2;
      this.why = "";
      let type = Reflection.GetClass(CBTwrDisguiseClass());
      if !IsDefined(type) {
        this.why = CBT(n"Cyberbane-Concealment-ItsDisguiseClassIsNotIn");
        CBLog.Info(n"Signals", "They Will Remember's disguise class was not found; Cyberbane reads disguises itself.");
      } else {
        this.ready = CBReflectNoArgs(type.GetFunction(n"IsDisguiseReady"), n"Bool");
        this.faceOn = CBReflectNoArgs(type.GetFunction(n"IsFaceDisguiseEnabled"), n"Bool");
        this.gangOn = CBReflectNoArgs(type.GetFunction(n"IsAffiliationDisguiseEnabled"), n"Bool");
        this.face = CBReflectNoArgs(type.GetFunction(n"DisguiseScore"), n"Float");
        this.cover = CBReflectNoArgs(type.GetFunction(n"Cover"), n"Int32");
        this.coverScore = CBReflectNoArgs(type.GetFunction(n"CoverScore"), n"Float");
        let missing = "";
        if !IsDefined(this.ready) { missing += CBT(n"Cyberbane-Concealment-IsDisguiseReady"); }
        if !IsDefined(this.faceOn) { missing += CBT(n"Cyberbane-Concealment-IsFaceDisguiseEnabled"); }
        if !IsDefined(this.gangOn) { missing += CBT(n"Cyberbane-Concealment-IsAffiliationDisguiseEnabled"); }
        if !IsDefined(this.face) { missing += CBT(n"Cyberbane-Concealment-DisguiseScore"); }
        if !IsDefined(this.cover) { missing += CBT(n"Cyberbane-Concealment-Cover"); }
        if !IsDefined(this.coverScore) { missing += CBT(n"Cyberbane-Concealment-CoverScore"); }
        let faceOk = IsDefined(this.face);
        let gangOk = IsDefined(this.cover) && IsDefined(this.coverScore);
        if faceOk || gangOk {
          this.state = 1;
          if StrLen(missing) > 0 {
            CBLog.Info(n"Signals", "They Will Remember's disguises found, without:" + missing + ". The rest is read.");
          } else {
            CBLog.Info(n"Signals", "They Will Remember's disguises found: its face and gang readings are Cyberbane's too.");
          }
        } else {
          this.why = CBTf(n"Cyberbane-Concealment-ItHasNeitherAFaceReading", [missing]);
          CBLog.Info(n"Signals", "They Will Remember's disguise system is not the shape Cyberbane reads (missing:" + missing + "); Cyberbane reads disguises itself.");
        }
      }
    }
    return this.state == 1;
  }

  public func Retry() -> Void {
    if this.state == 2 {
      this.state = 0;
    }
  }
}

public func CBTwrDisguiseClass() -> CName = n"TheyWillRemember.Disguise.Disguise"

// A function taking nothing and handing back exactly this type, or nothing.
func CBReflectNoArgs(fn: ref<ReflectionMemberFunc>, typeName: CName) -> ref<ReflectionMemberFunc> {
  if !IsDefined(fn) {
    return null;
  }
  let params = fn.GetParameters();
  if ArraySize(params) != 0 || !CBReflectReturns(fn, typeName) {
    return null;
  }
  return fn;
}

// Fills the They Will Remember part of this reading, when compatibility is on and it answers. Why it could not be read
// is kept on the runtime for the Hub (CBTwrDisguiseWhy, 2.5.1).
func CBReadTwrDisguise(game: GameInstance, worn: ref<CBWornRead>) -> Void {
  worn.twrRead = false;
  worn.twrFace = -1.0;
  // They Will Remember's alone (2.6.7): Night City Remembers has no disguise reading.
  if !CBRememberReadsDisguises() {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  let container = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(rt) || !IsDefined(container) {
    return;
  }
  let probe = rt.GetTwrDisguiseProbe();
  if !probe.Resolve() {
    rt.SetTwrDisguiseWhy(probe.why);
    return;
  }
  let disguise = container.Get(CBTwrDisguiseClass());
  if !IsDefined(disguise) {
    rt.SetTwrDisguiseWhy(CBT(n"Cyberbane-Concealment-ItsDisguiseSystemIsNotRunning"));
    return;
  }
  let none: array<Variant>;
  if IsDefined(probe.ready) && !FromVariant<Bool>(probe.ready.Call(disguise, none)) {
    rt.SetTwrDisguiseWhy(CBT(n"Cyberbane-Concealment-ItHasNotReadYourOutfit"));
    return;
  }
  rt.SetTwrDisguiseWhy("");
  worn.twrRead = true;
  if IsDefined(probe.face) && (!IsDefined(probe.faceOn) || FromVariant<Bool>(probe.faceOn.Call(disguise, none))) {
    // Its score is what is left to see: 1 a bare face, 0.11 a face 89% hidden.
    worn.twrFace = ClampF(1.0 - FromVariant<Float>(probe.face.Call(disguise, none)), 0.0, 1.0);
    if worn.twrFace >= CBConfig.TwrMaskedFace() {
      worn.face = true;
      worn.masked = true;
    }
  }
  let gangReadable = IsDefined(probe.cover) && IsDefined(probe.coverScore);
  worn.twrGangRead = gangReadable;
  worn.twrGangOn = gangReadable && (!IsDefined(probe.gangOn) || FromVariant<Bool>(probe.gangOn.Call(disguise, none)));
  if worn.twrGangOn {
    let gang = CBTwrFactionAt(FromVariant<Int32>(probe.cover.Call(disguise, none)));
    if NotEquals(gang, n"") {
      worn.twrFaction = gang;
      worn.twrCover = ClampF(1.0 - FromVariant<Float>(probe.coverScore.Call(disguise, none)), 0.0, 1.0);
    }
  }
}
