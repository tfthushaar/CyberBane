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

  let implantSum = 0.0;
  let visibleSum = 0.0;
  for area in areas {
    let item = data.GetActiveItem(area);
    if ItemID.IsValid(item) {
      implantSum += 3.0;
      visibleSum += CBVisibleChromeWeight(area);
    }
  }

  let c = CBComputeChrome(usage, implantSum, overalloc);
  let cVisible = CBComputeChromeVisible(visibleSum, 0.0);
  sys.GetScore().SetChrome(c, cVisible, overalloc);
}
