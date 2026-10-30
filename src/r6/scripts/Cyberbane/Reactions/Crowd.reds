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
public func CBFearReact(game: GameInstance, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>, dist: Float, intensity: Float, faction: CName, tick: Int32, content: ref<CyberbaneContent>) -> Bool {
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
  // Behind a mask you are nobody, and nobody frightens anybody.
  if CBCrowdIgnoresPlayer(game) {
    return false;
  }

  // How intimidating V is: the scarier of reputation Dread or raw visible chrome, plus a
  // bump for a dangerous build (level, street cred and skills). See CBUpdateMenace.
  let chromeVisible = score.GetChromeVisible();
  // Aura is what V is doing right now; the rest is what V is known for. Added rather than
  // maxed, because a frightening reputation and a drawn weapon compound.
  let eff = (MaxF(score.GetDreadCiv(), chromeVisible)
             + score.GetAura()
             + score.GetMenace() * CBConfig.MenaceFearWeight()) * intensity;

  // Obvious chrome gets read from further out. Someone walking around with blades for arms is
  // clocked halfway down the block, where a clean-looking merc has to be close before anyone
  // reacts. Both ranges stay inside the Director's evaluation radius.
  let reach = 1.0 + (chromeVisible / 100.0) * CBConfig.ChromeNoticeRangeBonus();
  let fleeR = CBConfig.CivFleeRadius() * reach;
  let cowerR = CBConfig.CivCowerRadius() * reach;

  // What this one personally takes to rattle.
  //
  // courageMod has been defined per faction since the first release and read by nothing, so a
  // Valentino and a passer-by reacted identically. Applied on the same 0..100 scale the tiers
  // use, so a courage of 0.10 is ten points of nerve.
  let brave = 0.0;
  if IsDefined(content) && NotEquals(faction, n"") {
    let prof = content.GetFaction(faction);
    if IsDefined(prof) {
      brave = prof.courageMod * 100.0;
    }
  }
  let eff2 = eff - brave;

  let fire = false;
  if eff2 >= CBConfig.CivTierTerror() && dist <= fleeR {
    fire = true;   // Terror: flees on sight, fear spreads
  } else {
    if eff2 >= CBConfig.CivTierAfraid() && dist <= cowerR {
      fire = true;   // Afraid: cowers or flees when V is close
    }
  }
  if !fire {
    return false;
  }

  let b = npc.GetStimBroadcasterComponent();
  if IsDefined(b) {
    // With a radius this time.
    //
    // `TriggerSingleBroadcast` takes the radius as an optional argument and this call left it
    // out, so every one of these went out at zero. Every broadcast in the game's own code
    // passes one: an NPC's own terror is 10 m (`NPCPuppet.script:3726`) and the MaxTac AV
    // descending is 100 m (`psychoSquadAVSystem.script:111`). The stim record itself carries
    // no default, so nothing was supplying it.
    // Scaled by the civilian intensity slider, like everything else on this path. A fixed
    // radius meant Subtle and Dramatic spread panic exactly as far, which is not what a
    // setting called intensity should do.
    b.TriggerSingleBroadcast(npc, gamedataStimType.Terror,
                             CBConfig.FearStimRadius() * intensity);

    // And it carries to the people around them.
    //
    // The comment on the tier above has said "fear spreads" since the first release and
    // nothing was spreading it. SpreadFear is the stim the game's own panic uses to pass
    // along a crowd, with fearPhase saying how far along the panic is, so one person going to
    // pieces near V now unsettles the people next to them rather than being an isolated
    // animation.
    let spread: stimInvestigateData;
    spread.fearPhase = 3;
    b.TriggerSingleBroadcast(npc, gamedataStimType.SpreadFear,
                             CBConfig.FearSpreadRadius() * intensity, spread);
  }
  npc.cbCrowdReacted = true;
  npc.cbCrowdReactedTick = tick;
  return true;
}
