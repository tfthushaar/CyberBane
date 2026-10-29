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

// Tick at which this NPC last reacted to V.
//
// The bool above is a one-way latch: it was set the first time an NPC reacted and never reset
// anywhere, so that NPC could never be frightened again for as long as it existed. Crowd NPCs
// linger in a district, so after one pass through a street nobody there would ever react again
// no matter how much more frightening V became, or how many times V walked back past them.
// Together with the tick starvation fixed in 1.1.8 that is most of "the crowd does not fear
// me": the few that were evaluated fired once and went inert.
//
// A stamp instead, so fear can be felt again after a cooldown rather than exactly once.
@addField(ScriptedPuppet)
public let cbCrowdReactedTick: Int32;

// Returns true when a reaction actually fired, so the Director can count it against the
// per-tick cap. `dist` is V's distance to the NPC, already measured by the Director loop.
public func CBFearReact(game: GameInstance, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>, dist: Float, intensity: Float, faction: CName, tick: Int32) -> Bool {
  if !IsDefined(npc) || intensity <= 0.0 {
    return false;
  }
  // Reacted recently. The zero check matters: an NPC that has never reacted has a stamp of 0,
  // and without it every NPC would look like it had just reacted for the first minute of play.
  if npc.cbCrowdReactedTick > 0 && (tick - npc.cbCrowdReactedTick) < CBConfig.CivReactionCooldownTicks() {
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
  let chromeVisible = score.GetChromeVisible();
  let eff = (MaxF(score.GetDreadCiv(), chromeVisible) + score.GetMenace() * CBConfig.MenaceFearWeight()) * intensity;

  // Obvious chrome gets read from further out. Someone walking around with blades for arms is
  // clocked halfway down the block, where a clean-looking merc has to be close before anyone
  // reacts. Both ranges stay inside the Director's evaluation radius.
  let reach = 1.0 + (chromeVisible / 100.0) * CBConfig.ChromeNoticeRangeBonus();
  let fleeR = CBConfig.CivFleeRadius() * reach;
  let cowerR = CBConfig.CivCowerRadius() * reach;

  let fire = false;
  if eff >= CBConfig.CivTierTerror() && dist <= fleeR {
    fire = true;   // Terror: flees on sight, fear spreads
  } else {
    if eff >= CBConfig.CivTierAfraid() && dist <= cowerR {
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
  npc.cbCrowdReactedTick = tick;
  return true;
}
