// Cyberbane - Player-state signals (spec §7.5, §7.6)
//
// Refreshes the live inputs the score engine needs each fast tick: Street Cred
// (Renown floor) and police Heat. Chrome and Look are pushed in by their own
// signals (S-11 / S-10) when those land.

public func CBRefreshLiveInputs(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  // Street Cred is no longer read here: this waits for a tick without heavy streaming, which on a busy street can be
  // minutes, and Renown went without its floor all that time. CBRefreshStreetCred, on every tenth tick.
  CBUpdateHeat(sys, game);
  // Not the aura: the fast tick reads it every other tick on its own (CyberbaneSystem), and this runs on
  // one of those same ticks, so it was being worked out twice in a row.
}

// V's Street Cred into the score engine, the floor under Renown (Model/ScoreMath.reds, CBComputeRenown).
public func CBRefreshStreetCred(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  sys.GetScore().SetStreetCred(CBPlayerStreetCred(game));
}

// Aura (spec 8.6): how dangerous V looks at this moment.
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
  let bladed = IsDefined(weapon) && (weapon.IsBlade() || weapon.IsBlunt());
  let obvious = score.GetChromeVisible() >= CBConfig.AuraObviousChrome() || bladed;
  // The game's tags, as its AI conditions read them (commonconditionchecks.tweak). The bare n"Sandevistan" is no
  // gameplay tag, so a Sandevistan running never counted here.
  let running: array<CName> = [n"SandevistanPlayerBuff", n"BerserkBuff", n"Berserk"];
  let chromeRunning = CBHasAnyTag(player, running);
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
