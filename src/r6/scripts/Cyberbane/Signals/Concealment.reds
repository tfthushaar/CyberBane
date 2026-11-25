// Cyberbane - What your clothes hide (spec §8.6)
//
// Visible chrome counts only what clothes leave on show: sleeves hide arm chrome, suits hide legs, masks and helmets
// hide the face. Reads Equipment-EX outfits and WEAVE's tags when they're installed.

public class CBWornRead {
  public let garments: array<ItemID>;   // everything a stranger can see V wearing, one per garment
  public let arms: Bool;
  public let legs: Bool;
  public let face: Bool;
  public let masked: Bool;
  public let fromMods: Int32;           // how many of the garments only the attached-clothing read found
  // They Will Remember's own reading of the same clothes, when it is the one deciding disguises: whether it answered,
  // how much of V's face it counts hidden (0..1, -1 when its face disguise is off), and whose gear it says V passes in
  // and how well (n"" and 0 for nobody, or its gang disguise off).
  public let twrRead: Bool;
  public let twrFace: Float;
  public let twrGangOn: Bool;
  public let twrFaction: CName;
  public let twrCover: Float;
  // Whether its gang reading could be asked at all: a version of theirs without one leaves the gang disguise to
  // Cyberbane's own reading instead of to nobody.
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
  // The Outfit area has no preset slot and no hide switch.
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
      // A yes or no from the slots' own bookkeeping.
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

// ---- Whose tags they are ----------------------------------------------------------------
//
// WEAVE's auto-tagger gives every garment a clothing mod left untagged one of the game's style tags and a wealth tag,
// often a gang's too (Casual, Simple, Moxies), so the game's crowds and Cyberbane's look and gang disguises read modded
// clothes the way they read the game's.

// WEAVE's auto-tagger, looked for once a launch through Codeware reflection, so nothing here names anything of WEAVE's.
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

// Are the style tags on a garment the game's word on it? False while WEAVE's tagger is installed (above).
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

// Is this garment of either of these kinds? The game's kinds of garment are carried in the price record each kind sets
// and every garment of it inherits (Price.Shorts, Price.Jumpsuit,...).
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

// One piece from wrist to ankle: a jumpsuit the game tags BodySuit. Its dresses carry the same tag and cover neither
// arms nor legs.
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
// both ways or none.
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
    // Sleeves an outfit mod files somewhere else still cover arms.
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

// Do V's clothes count at all? Off, nothing V wears is read: no chrome is covered, no mask hides who V is, no gang's
// colours fool anybody and no outfit makes V look more or less dangerous.
public func CBClothingCounts() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().clothingCounts;
}

// What V is wearing, both sources, and what it covers. One call per sample.
public func CBReadWorn(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> ref<CBWornRead> {
  // Never while a load is still putting V back together (CyberbaneSystem.WornReady): the last reading, if there is one,
  // and otherwise nothing worn.
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
  // Equipment-EX wearing an outfit: what people see is that outfit, nothing else.
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

// What one garment covers, for both readings: the game's clothing areas here, Equipment-EX's outfit slots below (one
// rule for both). `wholeBody` is a garment worn from shoulders to ankles, an Equipment-EX body slot: it covers the legs
// unless it is a dress or leaves them bare, and the arms unless it is known to be bare-armed.
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

// Is V's face hidden behind a mask right now?
public func CBPlayerMasked(game: GameInstance) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) && IsDefined(sys.GetWorn()) {
    return sys.GetWorn().masked;
  }
  // Before the session's first settled tick nothing has been read and nothing may be.
  if !IsDefined(sys) || !sys.WornReady() {
    return false;
  }
  return CBReadPlayerWorn(game).masked;
}

// Does the street have any reason to scatter from this person?
public func CBCrowdIgnoresPlayer(game: GameInstance) -> Bool {
  return CBPlayerMasked(game);
}

// How much of an area's chrome still shows once clothes are accounted for.
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
public func CBLogEquippedTags(game: GameInstance) -> Void {
  let player = GetPlayer(game);
  let es = CBGetSystem(game, n"EquipmentSystem") as EquipmentSystem;
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(es) || !IsDefined(ts) {
    CBLog.Info(n"Signals", "Clothing check: player or equipment system unavailable.");
    return;
  }
  let data = es.GetPlayerData(player);

  // The first version only logged items it found, so a session where nothing was found looked exactly like a session
  // where this never ran - which is what happened, and cost a round of guessing.
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

  // When a visual set is on these two disagree, and which of them is right is the entire question.
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

// ---- Equipment-EX ---------------------------------------------------------------------
//
// Equipment-EX blanks V's own clothing slots and shows its outfit as copies of the garments in slots of its own
// (OutfitSlots.*), so Cyberbane went on reading the clothes underneath.

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

// What an Equipment-EX outfit covers, slot by slot.
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

// Equipment-EX's body slots: where it puts what is worn from shoulders to ankles, the game's tight jumpsuits and
// netrunner suits, its jumpsuits, whole outfits, and anything a clothing mod files there as a body suit.
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

// ---- They Will Remember's disguises -----------------------------------------------------
//
// With They Will Remember installed and its compatibility on, Cyberbane handed it gang disguises and switched its own
// off, and never asked what They Will Remember made of V's clothes.

public class CBTwrDisguiseProbe {
  public let state: Int32;   // 0 not looked yet, 1 usable, 2 absent or not the shape this reads
  public let ready: ref<ReflectionMemberFunc>;
  public let faceOn: ref<ReflectionMemberFunc>;
  public let gangOn: ref<ReflectionMemberFunc>;
  public let face: ref<ReflectionMemberFunc>;
  public let cover: ref<ReflectionMemberFunc>;
  public let coverScore: ref<ReflectionMemberFunc>;
  public let why: String;

  // what it needs, not all six.
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
// is kept on the runtime for the Hub (CBTwrDisguiseWhy).
func CBReadTwrDisguise(game: GameInstance, worn: ref<CBWornRead>) -> Void {
  worn.twrRead = false;
  worn.twrFace = -1.0;
  // They Will Remember's alone: Night City Remembers has no disguise reading.
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
