// Cyberbane - Chrome signal (spec §7.3)
//
// Reads V's equipped cyberware and Humanity to compute Chrome (C) and visible
// Chrome (C_visible), then pushes them to the score engine. All APIs here are
// compile-verified against 2.31 (EquipmentSystem, GetActiveItem, Humanity stats,
// ItemID.IsValid). Per-implant family scores and tiers are refined in S-11; this
// first pass derives C from Humanity usage plus the number of implants, and
// C_visible from visibly-chromed areas (arms, eyes, skin).

// How obvious a piece of chrome is to someone looking at V. Arms carry the most - mantis blades,
// gorilla arms and a monowire read as a threat from across the street. Eyes and chromed skin get
// clocked closer in, and chromed legs show the moment you move. Everything internal scores 0,
// because nobody on the street can tell what your cardiovascular system is running.
// Max visible sum is 24, which becomes 60 after the x2.5 in CBComputeChromeVisible.
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
//
// Compared by name rather than cast from the enum's ordinal. The ordinals are not visible from
// a compile, and assuming them is the single mistake that has cost this project the most.
public func CBQualityTier(q: gamedataQuality) -> Int32 {
  if Equals(q, gamedataQuality.Iconic) { return 6; }
  if Equals(q, gamedataQuality.Legendary) { return 5; }
  if Equals(q, gamedataQuality.Epic) { return 4; }
  if Equals(q, gamedataQuality.Rare) { return 3; }
  if Equals(q, gamedataQuality.Uncommon) { return 2; }
  return 1;   // Common, and anything the game adds later
}

public func CBUpdateChrome(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
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
  // Its own comment says the caller should pass the sum of visibleScore x tierMult; no caller
  // did, so a rack of legendary chrome scored exactly the same as the common version of the
  // same slots. Quality is read through the item's data rather than guessed from the id.
  let ts = GameInstance.GetTransactionSystem(game);
  let implantSum = 0.0;
  let visibleSum = 0.0;
  for area in areas {
    let item = data.GetActiveItem(area);
    if ItemID.IsValid(item) {
      let mult = 1.0;
      if IsDefined(ts) {
        let idata = ts.GetItemData(player, item);
        if IsDefined(idata) {
          mult = CBTierMult(CBQualityTier(RPGManager.GetItemDataQuality(idata)));
        }
      }
      implantSum += 3.0 * mult;
      // Scaled by what V is wearing over it (Signals/Concealment.reds). Installed chrome is
      // still installed; this is only about what a stranger can see.
      visibleSum += CBVisibleChromeWeight(area) * mult * CBChromeVisibility(area, data);
    }
  }

  let c = CBComputeChrome(usage, implantSum, overalloc);
  let cVisible = CBComputeChromeVisible(visibleSum, 0.0);

  // Report it when it moves. Concealment is the sort of feature that can look like it does
  // nothing when it is in fact working and being hidden by the ceiling, and there is no way to
  // tell those apart from a screenshot of a bar sitting at 100.
  let rounded = RoundF(cVisible);
  if rounded != sys.GetLastLoggedChrome() {
    sys.SetLastLoggedChrome(rounded);
    CBLog.Info(n"Signals", s"Visible chrome \(rounded) (arms covered: \(CBArmsCovered(data)), legs: \(CBLegsCovered(data)), face: \(CBFaceCovered(data))).");
  }
  sys.GetScore().SetChrome(c, cVisible, overalloc);
}
