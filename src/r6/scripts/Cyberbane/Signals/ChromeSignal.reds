// Cyberbane - Chrome signal (spec §7.3)
//
// Reads V's equipped cyberware and Humanity to compute Chrome (C) and visible
// Chrome (C_visible), then pushes them to the score engine. All APIs here are
// compile-verified against 2.31 (EquipmentSystem, GetActiveItem, Humanity stats,
// ItemID.IsValid). Per-implant family scores and tiers are refined in S-11; this
// first pass derives C from Humanity usage plus the number of implants, and
// C_visible from visibly-chromed areas (arms, eyes, skin).

public func CBUpdateChrome(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return;
  }
  let es = GameInstance.GetScriptableSystemsContainer(game).Get(n"EquipmentSystem") as EquipmentSystem;
  if !IsDefined(es) {
    return;
  }
  let data = es.GetPlayerData(player);
  if !IsDefined(data) {
    return;
  }

  let stats = GameInstance.GetStatsSystem(game);
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
      if Equals(area, gamedataEquipmentArea.ArmsCW) {
        visibleSum += 12.0;
      } else {
        if Equals(area, gamedataEquipmentArea.EyesCW) {
          visibleSum += 3.0;
        } else {
          if Equals(area, gamedataEquipmentArea.IntegumentarySystemCW) {
            visibleSum += 3.0;
          }
        }
      }
    }
  }

  let c = CBComputeChrome(usage, implantSum, overalloc);
  let cVisible = CBComputeChromeVisible(visibleSum, 0.0);
  sys.GetScore().SetChrome(c, cVisible, overalloc);
}
