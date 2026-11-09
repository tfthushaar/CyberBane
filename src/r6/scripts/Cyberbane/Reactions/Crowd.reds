// Cyberbane - Fear reactions (spec §9.2)
//
// Anyone on the street can read how dangerous V looks and back off. The trigger is the
// greater of civilian-perceived Dread (D_civ) and visible Chrome (C_visible), so a merc
// decked out in obvious combat chrome scares people even before a reputation is built,
// and a feared legend scares them on top of that. Civilians, gangers and cops all react;
// only bosses and MaxTac hold their ground. Vendetta gangs attack instead of fleeing (the
// Director handles that first). Reactions use the game's own four stages of crowd fear, so
// nothing here is permanent or needs custom audio. The Director caps how many react per tick
// (Mod Settings) so the street never empties all at once.

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

// How the last reaction went, so somebody who only glanced can still flinch when V walks up to
// them, without waiting out the cooldown that stops anyone reacting to the same thing twice.
@addField(ScriptedPuppet)
public let cbCrowdLastFear: Int32;

// How easily this one person rattles, rolled once. Everybody on a street reading V identically
// is what made a whole pavement do the same thing at the same moment.
@addField(ScriptedPuppet)
public let cbCrowdNerve: Int32;

// A look over at V and a worried face, then back to their day. The game's first stage of fear,
// which it reserves for a car horn; a horn sent from V would pass a walk-away to everybody within
// 15 m, so the two things that stage does are done here instead. Nothing is asked of their AI.
@addMethod(ReactionManagerComponent)
public func CBGlanceAt(target: ref<GameObject>) -> Void {
  if this.m_desiredFearPhase > -1 || IsDefined(this.m_activeReaction)
     || NotEquals(this.m_crowdFearStage, gameFearStage.Relaxed) {
    return;
  }
  if !this.ActivateReactionLookAt(target, true, false, 3.0) {
    return;
  }
  if this.m_inCrowd {
    this.TriggerFearFacial(1);
    this.ResetFacial(4.0);
  }
}

// Which stage of fear a person this rattled, this far from V, has reached. -1 is none.
//   0  looks over and looks worried
//   1  flinches and steps out of V's way
//   2  hands up, frozen, with V right on top of them
//   3  runs
// Each stage needs more fear and, apart from running, a shorter distance, so one V on one street
// gets a mix: heads turning at the edge, people stepping aside nearer in.
public func CBFearStage(fear: Float, dist: Float, reach: Float) -> Int32 {
  if fear >= CBConfig.CivFearRun() && dist <= CBConfig.CivFleeRadius() * reach {
    return 3;
  }
  if fear >= CBConfig.CivFearCower() && dist <= CBConfig.CivCowerRadius() * reach {
    return 2;
  }
  if fear >= CBConfig.CivFearStartle() && dist <= CBConfig.CivStartleRadius() * reach {
    return 1;
  }
  if fear >= CBConfig.CivFearGlance() && dist <= CBConfig.CivGlanceRadius() * reach {
    return 0;
  }
  return -1;
}

// Returns true when a reaction that counts against the Director's per-tick cap fired. `dist` is
// V's distance to the NPC, already measured by the Director loop.
public func CBFearReact(game: GameInstance, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>, dist: Float, intensity: Float, faction: CName, tick: Int32, content: ref<CyberbaneContent>) -> Bool {
  if !IsDefined(npc) || intensity <= 0.0 || !IsDefined(score) {
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
  // A gang that likes V does not run from V. Fear is for the people who are not sure which side
  // of V they are on, and these ones are sure.
  if NotEquals(faction, n"") && !npc.IsCrowd() {
    let posture = score.GetPosture(faction);
    if Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly) {
      return false;
    }
  }

  // Obvious chrome gets read from further out. Someone walking around with blades for arms is
  // clocked halfway down the block, where a clean-looking merc has to be close before anyone
  // reacts. Every range stays inside the Director's evaluation radius.
  let reach = 1.0 + (score.GetChromeVisible() / 100.0) * CBConfig.ChromeNoticeRangeBonus();

  // courageMod is ten points of nerve for 0.10, on the same scale the stages use.
  let brave = 0.0;
  if IsDefined(content) && NotEquals(faction, n"") {
    let prof = content.GetFaction(faction);
    if IsDefined(prof) {
      brave = prof.courageMod * 100.0;
    }
  }
  if npc.cbCrowdNerve == 0 {
    npc.cbCrowdNerve = RandRange(1, 52);
  }
  // A quarter either way. A share and not a flat amount, so turning the slider down quietens
  // everybody and cannot leave a few jumpy people reacting to nothing at all.
  let jumpy = 1.0 + Cast<Float>(npc.cbCrowdNerve - 26) / 100.0;
  // One copy of the sum, in Model/ScoreMath.reds, because the Hub needs the same answer.
  let fear = CBCrowdFear(score, intensity) * jumpy - brave;

  let stage = CBFearStage(fear, dist, reach);
  if stage < 0 {
    return false;
  }
  // The zero check matters: an NPC that has never reacted has a stamp of 0, and without it every
  // NPC would look like it had just reacted for the first minute of play.
  if npc.cbCrowdReactedTick > 0 && (tick - npc.cbCrowdReactedTick) < CBConfig.CivReactionCooldownTicks()
     && stage <= npc.cbCrowdLastFear {
    return false;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }

  // The game's own test for who takes the crowd's path through its reaction code.
  let civilian = npc.IsCrowd() || npc.IsCharacterCivilian();
  let counted = false;
  if stage == 0 || !civilian {
    // Somebody with a job to do sizes V up and stays put. They used to shout Terror at everyone
    // within ten metres, which did nothing to them (the game drops a stim whose source is its own
    // target, IsStimuliEventValid) and sent every civilian nearby running: much of why walking past
    // a gang corner emptied the street.
    let reactions = npc.GetStimReactionComponent();
    if IsDefined(reactions) {
      reactions.CBGlanceAt(player);
    }
  } else {
    // SpreadFear is the one stim the game lets a sender choose the stage of. It comes from V, so
    // they turn to V and move away from V, and it is tagged to stop with this person: the crowd
    // does not pass it on, and it cannot start an armed civilian on V.
    let data: stimInvestigateData;
    data.fearPhase = stage;
    StimBroadcasterComponent.SendStimDirectly(player, gamedataStimType.SpreadFear, npc, data);
    counted = true;

    // Somebody bolting past you is startling, and no more than that.
    if stage == 3 {
      let b = npc.GetStimBroadcasterComponent();
      if IsDefined(b) {
        let spread: stimInvestigateData;
        spread.fearPhase = 1;
        b.TriggerSingleBroadcast(npc, gamedataStimType.SpreadFear,
                                 CBConfig.FearSpreadRadius() * intensity, spread);
      }
    }
  }
  npc.cbCrowdReacted = true;
  npc.cbCrowdReactedTick = tick;
  npc.cbCrowdLastFear = stage;
  return counted;
}
