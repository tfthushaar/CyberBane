// Cyberbane - Panic driving (spec §9.2)
//
// When V is terrifying and fighting out on the street, nearby drivers should panic and
// peel away. No direct "make this car flee" call is exposed to redscript, so this reuses the
// game's own fear path: a Gunshot stim broadcast from V, which the traffic AI and crowds
// react to. It only fires when V is both frightening (civilian Dread at the Terror tier)
// and in combat, and only once every few ticks, so it never spams. Reversible (a stock
// stim) and gated by the panicDriving setting. Driver response is tuned in-game.

public func CBPanicDrivingTick(sys: ref<CyberbaneSystem>, game: GameInstance, tickCount: Int32) -> Void {
  if tickCount % 5 != 0 {
    return;   // roughly once every five seconds
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() && !rt.GetSettings().panicDriving {
      return;
    }
  }
  if !IsDefined(sys) || sys.IsInSafeZone() {
    return;   // not in a safe area (spec §16)
  }
  let score = sys.GetScore();
  if !IsDefined(score) || score.GetDreadCiv() < CBConfig.CivTierTerror() {
    return;   // only the genuinely feared clear the streets
  }
  // And only the recognised. A driver cannot be frightened of a reputation they cannot attach
  // to the person in the road.
  if CBCrowdIgnoresPlayer(game) {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || !player.IsInCombat() {
    return;
  }
  let b = player.GetStimBroadcasterComponent();
  if IsDefined(b) {
    b.TriggerSingleBroadcast(player, gamedataStimType.Gunshot);
  }
}
