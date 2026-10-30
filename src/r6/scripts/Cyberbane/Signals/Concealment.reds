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
// would not really conceal.
//
// **How to ask what is worn, which took three goes to get right.** The equipment areas are the
// obvious route and they are not the whole answer. When a wardrobe set is active the clothing
// areas are empty - the items live in the set, not in the slots - so `GetActiveItem` honestly
// reports nothing for a V who is visibly dressed head to foot. That is what the log was saying
// all along: visible chrome computed correctly from implants, `arms covered: false`, and
// nothing worn reported at all, on a character wearing a coat, trousers, boots and a mask.
//
// The game has its own answer for this and we were not using it. `GetVisualItemInSlot`
// (equipmentSystem.script:2195) reads the active set's `visualItem` for that area when a set is
// on, and falls through to `GetActiveItem` when one is not. It is the exact question being
// asked here, and the game asks it of itself everywhere it needs to know what the player
// appears to be wearing.

// What is actually on this part of V, whichever way the game is dressing them.
//
// Three routes, tried in the order of how much they know:
//
//   1. `GetVisualItemInSlot` - the game's own wardrobe-aware read, and the one that was
//      missing. This is what makes a wardrobe set visible to us at all.
//   2. `GetActiveItem` on the equipment area, for what the first route declines to handle: it
//      returns -1 for the Outfit area and for underwear by design.
//   3. The attachment slot, through the transaction system, as a last resort for anything
//      hung on the body without going through the equipment areas.
//
// Three routes can only ever find coverage that fewer would have missed; none of them can
// invent any.
func CBWornItem(game: GameInstance, data: ref<EquipmentSystemPlayerData>,
                area: gamedataEquipmentArea, slot: TweakDBID) -> ItemID {
  if IsDefined(data) {
    let visual = data.GetVisualItemInSlot(area);
    if ItemID.IsValid(visual) {
      return visual;
    }
    let active = data.GetActiveItem(area);
    if ItemID.IsValid(active) {
      return active;
    }
  }
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if IsDefined(player) && IsDefined(ts) && TDBID.IsValid(slot) {
    return ts.GetActiveItemInSlot(player, slot);
  }
  return ItemID.None();
}

func CBWorn(game: GameInstance, data: ref<EquipmentSystemPlayerData>,
            area: gamedataEquipmentArea, slot: TweakDBID) -> Bool {
  return ItemID.IsValid(CBWornItem(game, data, area, slot));
}

// An outer layer over the chest, which is what hides arms and skin.
public func CBArmsCovered(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> Bool {
  return CBWorn(game, data, gamedataEquipmentArea.OuterChest, t"AttachmentSlots.Chest")
      || CBWorn(game, data, gamedataEquipmentArea.Outfit, t"AttachmentSlots.Outfit");
}

public func CBLegsCovered(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> Bool {
  return CBWorn(game, data, gamedataEquipmentArea.Legs, t"AttachmentSlots.Legs")
      || CBWorn(game, data, gamedataEquipmentArea.Outfit, t"AttachmentSlots.Outfit");
}

// Something across the face. Hides eye chrome, and hides who you are.
public func CBFaceCovered(game: GameInstance, data: ref<EquipmentSystemPlayerData>) -> Bool {
  return CBWorn(game, data, gamedataEquipmentArea.Face, t"AttachmentSlots.Face");
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
  // Through the same three routes as the coverage checks, so a mask worn as part of a wardrobe
  // set counts exactly as a mask equipped on its own does. It did not before, which is the
  // whole of why putting one on changed nothing.
  let item = CBWornItem(game, es.GetPlayerData(player), gamedataEquipmentArea.Face,
                        t"AttachmentSlots.Face");
  return ItemID.IsValid(item) && CBItemIsMask(ItemID.GetTDBID(item));
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
}
