// Cyberbane — Civilian crowd reactions (spec §9.2)
//
// Pedestrians read V's civilian-perceived Dread (D_civ). The more frightening V is, the
// closer a civilian has to be before it reacts — from cowering up close at the Afraid
// tier to fleeing on sight at the Terror tier, where the panic also spreads through the
// crowd. Reactions use the game's own fear behaviour, driven by a Terror stim broadcast
// from the civilian, so nothing here is permanent or needs custom audio. The Director
// caps how many civilians react per tick (Mod Settings) to keep crowds from all bolting.

@addField(ScriptedPuppet)
public let cbCrowdReacted: Bool;

// Returns true when a reaction actually fired, so the Director can count it against the
// per-tick civilian cap. `dist` is V's distance to the civilian, already measured by the
// Director's evaluation loop.
public func CBCrowdReact(game: GameInstance, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>, dist: Float, intensity: Float) -> Bool {
  if !IsDefined(npc) || npc.cbCrowdReacted || intensity <= 0.0 {
    return false;
  }
  if !IsDefined(score) {
    return false;
  }

  // Intensity (Mod Settings) scales how readily the crowd spooks.
  let eff = score.GetDreadCiv() * intensity;

  let fire = false;
  if eff >= CBConfig.CivTierTerror() && dist <= CBConfig.CivFleeRadius() {
    fire = true;   // Terror: flees on sight, fear spreads
  } else {
    if eff >= CBConfig.CivTierAfraid() && dist <= CBConfig.CivCowerRadius() {
      fire = true;   // Afraid: cowers or flees when V is close
    }
  }
  if !fire {
    return false;
  }

  let b = npc.GetStimBroadcasterComponent();
  if IsDefined(b) {
    b.TriggerSingleBroadcast(npc, gamedataStimType.Terror);
  }
  npc.cbCrowdReacted = true;
  return true;
}
