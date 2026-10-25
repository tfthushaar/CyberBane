// Cyberbane - Player-state signals (spec §7.5, §7.6)
//
// Refreshes the live inputs the score engine needs each fast tick: Street Cred
// (Renown floor) and police Heat. Chrome and Look are pushed in by their own
// signals (S-11 / S-10) when those land.

public func CBRefreshLiveInputs(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  sys.GetScore().SetStreetCred(CBPlayerStreetCred(game));
  CBUpdateHeat(sys, game);
}

// Heat (spec §7.6): each time V reaches a new heat stage n, add n^2 heat points.
func CBUpdateHeat(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let prev = GameInstance.GetScriptableSystemsContainer(game).Get(n"PreventionSystem") as PreventionSystem;
  if !IsDefined(prev) {
    return;
  }
  let stage = EnumInt(prev.GetHeatStage());
  let last = sys.GetLastHeatStage();
  if stage > last {
    sys.AddHeatPoints(Cast<Float>(stage * stage));
    let stats = sys.GetStats();
    if IsDefined(stats) && stage > stats.maxHeat {
      stats.maxHeat = stage;
    }
  }
  if stage != last {
    sys.SetLastHeatStage(stage);
  }
  sys.GetScore().SetHeatStage(stage);
}
