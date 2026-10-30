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
  CBUpdateAura(sys, game);
}

// Aura (spec 8.6): how dangerous V looks at this moment.
//
// This was specified and never wired: CBComputeAura and AuraCap both existed and nothing called
// either, so walking around armed, mid-fight, standing over fresh bodies with chrome running
// read exactly the same to the street as walking around clean. Reputation was the only thing
// that frightened anybody.
//
// Every input is read from something already verified present, including the weapon: the
// "heavy or blade" term inspects what V actually has out rather than using visible chrome as
// its stand-in, which is what it did until the kill scoring proved the lookup was free.
public func CBUpdateAura(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let score = sys.GetScore();
  let player = GetPlayer(game);
  if !IsDefined(score) || !IsDefined(player) {
    return;
  }
  let weapon = GameObject.GetActiveWeapon(player);
  let drawn = IsDefined(weapon);
  // "Heavy or blade" means it now.
  //
  // This term used visible chrome as its stand-in and said so, on the grounds that a
  // weapon-type lookup was not worth four points. The lookup turned out to be free: the game
  // classifies its own weapons, and the kill scoring already uses the same two calls. So
  // someone walking around with a katana out reads as dangerous whether or not they are
  // chromed, which is what the term was always supposed to mean.
  let bladed = IsDefined(weapon) && (weapon.IsBlade() || weapon.IsBlunt());
  let obvious = score.GetChromeVisible() >= CBConfig.AuraObviousChrome() || bladed;
  let chromeRunning = StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"Sandevistan")
                   || StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"Berserk");
  score.SetAura(CBComputeAura(drawn, obvious, chromeRunning, player.IsInCombat(),
                              sys.GetRecentKills(), score.GetHeatStage() >= 3));
}

// Heat (spec §7.6): each time V reaches a new heat stage n, add n^2 heat points.
func CBUpdateHeat(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let prev = CBGetSystem(game, n"PreventionSystem") as PreventionSystem;
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
