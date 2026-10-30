// Cyberbane - What your clothes hide (spec §8.6)
//
// Chrome only frightens people who can see it. A coat over gorilla arms is a coat over gorilla
// arms, and the street reacts to what is on show rather than to what is installed. Until now
// visible chrome was computed purely from what V had fitted, so a fully chromed merc in a
// parka read exactly as loud as the same merc in a vest.
//
// This reads the slots that are actually filled rather than trying to interpret what a garment
// looks like. Sleeve length lives in the appearance archives, not in TweakDB, so there is no
// honest way to ask "does this jacket have sleeves" from script. What can be asked, exactly and
// cheaply, is whether something is worn over the chest, over the legs, over the face. That is
// enough to carry the idea: an outer layer covers your arms, trousers cover your legs, a mask
// covers your face.
//
// Deliberately a partial truth rather than a guess: a sleeveless jacket will conceal arms it
// would not really conceal. The alternative was inventing visual-tag names that may not exist,
// which ships a feature that silently does nothing - the exact failure this mod has spent
// several versions removing. CBLogEquippedTags below exists so the tag table can be built from
// a real session later, and this replaced with something exact.

// Is anything actually hanging on this attachment slot?
//
// The second of two ways to ask, and the reason there are two. The equipment areas are what
// the game's own code reads, and on this save they came back empty for every clothing slot
// while the cyberware slots in the same data object resolved perfectly: the log shows visible
// chrome computed from implants and `arms covered: false` with nothing worn reported at all.
// Clothing is hung on attachment slots as well, so this asks the transaction system directly
// and either answer counts. Checking both can only ever find coverage the single check missed.
func CBSlotWorn(game: GameInstance, slot: TweakDBID) -> Bool {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return false;
  }
  return ItemID.IsValid(ts.GetActiveItemInSlot(player, slot));
}

// An outer layer over the chest, which is what hides arms and skin.
public func CBArmsCovered(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> Bool {
  if IsDefined(data)
     && (ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.OuterChest))
         || ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Outfit))) {
    return true;
  }
  return CBSlotWorn(game, t"AttachmentSlots.Chest")
      || CBSlotWorn(game, t"AttachmentSlots.Torso")
      || CBSlotWorn(game, t"AttachmentSlots.Outfit");
}

public func CBLegsCovered(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> Bool {
  if IsDefined(data)
     && (ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Legs))
         || ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Outfit))) {
    return true;
  }
  return CBSlotWorn(game, t"AttachmentSlots.Legs")
      || CBSlotWorn(game, t"AttachmentSlots.Outfit");
}

// Something across the face. Hides eye chrome, and hides who you are.
public func CBFaceCovered(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> Bool {
  if IsDefined(data) && ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Face)) {
    return true;
  }
  return CBSlotWorn(game, t"AttachmentSlots.Face");
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

// Is V's face hidden behind a mask right now? The question the witness system asks.
public func CBPlayerMasked(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  let es = CBGetSystem(game, n"EquipmentSystem") as EquipmentSystem;
  if !IsDefined(es) {
    return false;
  }
  let data = es.GetPlayerData(player);
  if !IsDefined(data) {
    return false;
  }
  let item = data.GetActiveItem(gamedataEquipmentArea.Face);
  if ItemID.IsValid(item) {
    return CBItemIsMask(ItemID.GetTDBID(item));
  }
  // Same second route as the coverage checks: the equipment area can be empty while the item
  // is hanging on the attachment slot.
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(ts) {
    return false;
  }
  let slotted = ts.GetActiveItemInSlot(player, t"AttachmentSlots.Face");
  return ItemID.IsValid(slotted) && CBItemIsMask(ItemID.GetTDBID(slotted));
}

// How much of an area's chrome still shows once clothes are accounted for.
//
// Not zero: a coat moves, sleeves ride up, and something heavy underneath still changes how a
// person carries themselves. Covered chrome reads at a quarter, which keeps a chromed V in a
// coat more unsettling than an unchromed one in the same coat without making the coat
// pointless.
public func CBCoveredChromeMult() -> Float = 0.25

// What fraction of this area's visible weight survives being dressed.
public func CBChromeVisibility(game: GameInstance, area: gamedataEquipmentArea,
                               data: ref<EquipmentSystemPlayerData>) -> Float {
  if Equals(area, gamedataEquipmentArea.ArmsCW) && CBArmsCovered(game, data) {
    return CBCoveredChromeMult();
  }
  if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) && CBArmsCovered(game, data) {
    return CBCoveredChromeMult();   // the skin people can see is mostly arms and chest
  }
  if Equals(area, gamedataEquipmentArea.LegsCW) && CBLegsCovered(game, data) {
    return CBCoveredChromeMult();
  }
  if Equals(area, gamedataEquipmentArea.EyesCW) && CBFaceCovered(game, data) {
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
  CBLog.Info(n"Signals", s"Clothing check: \(byArea) by equipment area, \(bySlot) by attachment slot.");
}
