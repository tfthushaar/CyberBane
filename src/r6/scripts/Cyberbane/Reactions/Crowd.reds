// Cyberbane - Fear reactions (spec §9.2)
//
// Anyone on the street can read how dangerous V looks and back off. The trigger is the
// greater of civilian-perceived Dread (D_civ) and visible Chrome (C_visible), so a merc
// decked out in obvious combat chrome scares people even before a reputation is built,
// and a feared legend scares them on top of that. Civilians, gangers and cops all react;
// only bosses and MaxTac hold their ground. Vendetta gangs attack instead of fleeing (the
// Director handles that first). Reactions use the game's own fear behaviour via a Terror
// stim, so nothing here is permanent or needs custom audio. The Director caps how many
// react per tick (Mod Settings) so the street never empties all at once.

@addField(ScriptedPuppet)
public let cbCrowdReacted: Bool;

// Returns true when a reaction actually fired, so the Director can count it against the
// per-tick cap. `dist` is V's distance to the NPC, already measured by the Director loop.
public func CBFearReact(game: GameInstance, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>, dist: Float, intensity: Float, faction: CName) -> Bool {
  if !IsDefined(npc) || npc.cbCrowdReacted || intensity <= 0.0 {
    return false;
  }
  if !IsDefined(score) {
    return false;
  }
  // Bosses and MaxTac are the ones people fear; they do not run.
  if npc.IsBoss() || Equals(faction, n"MaxTac") {
    return false;
  }

  // How intimidating V is: the scarier of reputation Dread or raw visible chrome, plus a
  // bump for a dangerous build (level, street cred and skills). See CBUpdateMenace.
  let eff = (MaxF(score.GetDreadCiv(), score.GetChromeVisible()) + score.GetMenace() * CBConfig.MenaceFearWeight()) * intensity;

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
