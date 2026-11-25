// Cyberbane - Chrome signal (spec §7.3)
//
// Reads V's equipped cyberware and Humanity to compute Chrome (C) and visible Chrome (C_visible), then pushes them to
// the score engine. All APIs here are compile-verified against 2.31 (EquipmentSystem, GetActiveItem, Humanity stats,
// ItemID.IsValid).

// How obvious a piece of chrome is to someone looking at V. Arms carry the most - mantis blades, gorilla arms and a
// monowire read as a threat from across the street.
func CBVisibleChromeWeight(area: gamedataEquipmentArea) -> Float {
  if Equals(area, gamedataEquipmentArea.ArmsCW) {
    return 12.0;
  }
  if Equals(area, gamedataEquipmentArea.EyesCW) {
    return 4.0;
  }
  if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) {
    return 4.0;
  }
  if Equals(area, gamedataEquipmentArea.LegsCW) {
    return 4.0;
  }
  return 0.0;
}

// Quality to the tier number CBTierMult expects.
public func CBQualityTier(q: gamedataQuality) -> Int32 {
  if Equals(q, gamedataQuality.Iconic) { return 6; }
  if Equals(q, gamedataQuality.Legendary) { return 5; }
  if Equals(q, gamedataQuality.Epic) { return 4; }
  if Equals(q, gamedataQuality.Rare) { return 3; }
  if Equals(q, gamedataQuality.Uncommon) { return 2; }
  return 1;   // Common, and anything the game adds later
}

public func CBUpdateChrome(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  // Not before the session's first settled tick: the load may still be putting V's implants and clothes back on
  // (CyberbaneSystem.StartSession).
  if !IsDefined(sys) || !sys.WornReady() {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return;
  }
  let es = CBGetSystem(game, n"EquipmentSystem") as EquipmentSystem;
  if !IsDefined(es) {
    return;
  }
  let data = es.GetPlayerData(player);
  if !IsDefined(data) {
    return;
  }

  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let sid = Cast<StatsObjectID>(player.GetEntityID());
  let alloc = stats.GetStatValue(sid, gamedataStatType.HumanityAllocated);
  let maxv = stats.GetStatValue(sid, gamedataStatType.HumanityTotalMaxValue);
  let usage = maxv > 0.0 ? ClampF(alloc / maxv, 0.0, 1.5) : 0.0;
  let overalloc = usage > 1.0;

  let areas = [
    gamedataEquipmentArea.ArmsCW, gamedataEquipmentArea.HandsCW, gamedataEquipmentArea.EyesCW,
    gamedataEquipmentArea.FrontalCortexCW, gamedataEquipmentArea.NervousSystemCW,
    gamedataEquipmentArea.MusculoskeletalSystemCW, gamedataEquipmentArea.CardiovascularSystemCW,
    gamedataEquipmentArea.ImmuneSystemCW, gamedataEquipmentArea.IntegumentarySystemCW,
    gamedataEquipmentArea.SystemReplacementCW, gamedataEquipmentArea.LegsCW
  ];

  // Weighted by tier, which CBTierMult has always been written to do and nothing ever called.
  let ts = GameInstance.GetTransactionSystem(game);
  // What V is wearing, from the game's clothing areas as drawn and from anything else on V (an outfit
  // mod's own slots), read once for this sample and kept for the look and the mask test.
  let worn = CBReadWorn(game, data);
  sys.SetWorn(worn);
  let implantSum = 0.0;
  let visibleSum = 0.0;
  let slots = 0;
  let filled = 0;
  // The public test for a missing area, GetEquipAreaIndex, is private on 2.31, and calling it there would stop every
  // script mod compiling.
  for area in areas {
    // Only slots that exist: GetItemInEquipSlot has no bounds check of its own.
    let count = data.GetNumberOfSlots(area, true);
    slots += data.GetNumberOfSlots(area);
    let best = 0.0;
    let k = 0;
    while k < count {
      let item = data.GetItemInEquipSlot(area, k);
      k += 1;
      if ItemID.IsValid(item) {
        filled += 1;
        let mult = 1.0;
        if IsDefined(ts) {
          let idata = ts.GetItemData(player, item);
          if IsDefined(idata) {
            mult = CBTierMult(CBQualityTier(RPGManager.GetItemDataQuality(idata)));
          }
        }
        best = MaxF(best, mult);
      }
    }
    if best > 0.0 {
      implantSum += 3.0 * best;
      // Scaled by what V is wearing over it (Signals/Concealment.reds). Installed chrome is
      // still installed; this is only about what a stranger can see.
      visibleSum += CBVisibleChromeWeight(area) * best * CBChromeVisibility(area, worn);
    }
  }
  // How much of V is chrome: the share of capacity used, or the share of slots filled, whichever is
  // more. A mod that raises capacity cannot make a body with every slot filled read as part flesh.
  let coverage = slots > 0 ? Cast<Float>(filled) / Cast<Float>(slots) : 0.0;

  let c = CBComputeChrome(MaxF(usage, coverage), implantSum, overalloc);
  let cVisible = CBComputeChromeVisible(visibleSum, 0.0);

  // Report it when it moves.
  let rounded = RoundF(cVisible);
  if rounded != sys.GetLastLoggedChrome() {
    sys.SetLastLoggedChrome(rounded);
    CBLog.Info(n"Signals", s"Visible chrome \(rounded) (arms covered: \(worn.arms), legs: \(worn.legs), face: \(worn.face); \(ArraySize(worn.garments)) garments seen, \(worn.fromMods) of them only on V's body). Installed \(RoundF(c)): \(filled) of \(slots) slots, \(RoundF(usage * 100.0))% of capacity.");
  }
  sys.GetScore().SetChrome(c, cVisible, overalloc);
}
