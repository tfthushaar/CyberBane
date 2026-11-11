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
//      Asked of the game by item ("is this attached to V anywhere", TransactionSystem.GetItemInSlotByItemID),
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
      if ItemID.IsValid(id) && !CBItemListHas(equipped, id) && !CBGarmentRecordListed(seen, id)
         && !CBGarmentRecordListed(out, id) && IsDefined(ts.GetItemInSlotByItemID(player, id)) {
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
// cover neither arms nor legs.
func CBGarmentIsSuit(id: ItemID) -> Bool {
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  return IsDefined(rec) && rec.TagsContains(n"BodySuit")
      && CBGarmentPricedAs(id, t"Price.Jumpsuit", t"Price.TightJumpsuit");
}

// Sleeves, as the game records them: 1 long (LongSleeve, or a suit), 0 bare arms (a garment the game
// tagged that says neither), -1 unknown (no tags at all).
func CBGarmentSleeves(id: ItemID) -> Int32 {
  let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(id));
  if !IsDefined(rec) {
    return -1;
  }
  if rec.TagsContains(n"LongSleeve") || CBGarmentIsSuit(id) {
    return 1;
  }
  return CBGarmentHasStyleTags(rec) ? 0 : -1;
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
    return false;
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
func CBItemIsMask(tdbid: TweakDBID) -> Bool {
  let id = TDBID.ToStringDEBUG(tdbid);
  if StrLen(id) == 0 {
    return false;
  }
  return StrContains(id, "Mask") || StrContains(id, "mask");
}

// What V is wearing, both sources, and what it covers. One call per sample.
public func CBReadWorn(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> ref<CBWornRead> {
  let worn = new CBWornRead();
  if !IsDefined(data) {
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
    let area = CBGarmentArea(id);
    if CBGarmentCoversArms(id, area) {
      worn.arms = true;
    }
    if CBGarmentCoversLegs(id, area) {
      worn.legs = true;
    }
    if Equals(area, gamedataEquipmentArea.Face) {
      worn.face = true;
      if CBItemIsMask(ItemID.GetTDBID(id)) {
        worn.masked = true;
      }
    }
  }
  return worn;
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
  CBLog.Info(n"Signals", s"Clothing read: \(ArraySize(worn.garments)) garments seen (\(worn.fromMods) only on V's body); arms covered \(worn.arms), legs \(worn.legs), face \(worn.face), masked \(worn.masked).");
}
