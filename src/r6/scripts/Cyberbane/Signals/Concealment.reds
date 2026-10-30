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

// An outer layer over the chest, which is what hides arms and skin.
public func CBArmsCovered(data: ref<EquipmentSystemPlayerData>) -> Bool {
  if !IsDefined(data) {
    return false;
  }
  return ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.OuterChest))
      || ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Outfit));
}

public func CBLegsCovered(data: ref<EquipmentSystemPlayerData>) -> Bool {
  if !IsDefined(data) {
    return false;
  }
  return ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Legs))
      || ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Outfit));
}

// Something across the face. Hides eye chrome, and hides who you are.
public func CBFaceCovered(data: ref<EquipmentSystemPlayerData>) -> Bool {
  if !IsDefined(data) {
    return false;
  }
  return ItemID.IsValid(data.GetActiveItem(gamedataEquipmentArea.Face));
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
  return ItemID.IsValid(item) && CBItemIsMask(ItemID.GetTDBID(item));
}

// How much of an area's chrome still shows once clothes are accounted for.
//
// Not zero: a coat moves, sleeves ride up, and something heavy underneath still changes how a
// person carries themselves. Covered chrome reads at a quarter, which keeps a chromed V in a
// coat more unsettling than an unchromed one in the same coat without making the coat
// pointless.
public func CBCoveredChromeMult() -> Float = 0.25

// What fraction of this area's visible weight survives being dressed.
public func CBChromeVisibility(area: gamedataEquipmentArea, data: ref<EquipmentSystemPlayerData>) -> Float {
  if Equals(area, gamedataEquipmentArea.ArmsCW) && CBArmsCovered(data) {
    return CBCoveredChromeMult();
  }
  if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) && CBArmsCovered(data) {
    return CBCoveredChromeMult();   // the skin people can see is mostly arms and chest
  }
  if Equals(area, gamedataEquipmentArea.LegsCW) && CBLegsCovered(data) {
    return CBCoveredChromeMult();
  }
  if Equals(area, gamedataEquipmentArea.EyesCW) && CBFaceCovered(data) {
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
  if !IsDefined(player) || !IsDefined(es) {
    return;
  }
  let data = es.GetPlayerData(player);
  if !IsDefined(data) {
    return;
  }
  let areas = [
    gamedataEquipmentArea.Head, gamedataEquipmentArea.Face, gamedataEquipmentArea.OuterChest,
    gamedataEquipmentArea.InnerChest, gamedataEquipmentArea.Legs, gamedataEquipmentArea.Feet,
    gamedataEquipmentArea.Outfit
  ];
  for area in areas {
    let item = data.GetActiveItem(area);
    if ItemID.IsValid(item) {
      let rec = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(item));
      if IsDefined(rec) {
        let line = "";
        let tags = rec.VisualTags();
        for t in tags {
          line += NameToString(t) + " ";
        }
        CBLog.Info(n"Signals", s"Worn: \(TDBID.ToStringDEBUG(ItemID.GetTDBID(item))) tags: \(line)");
      }
    }
  }
}
