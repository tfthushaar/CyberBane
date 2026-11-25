// Cyberbane - Witnesses (spec §8.5)
//
// Reputation travels because somebody lived to carry it. A kill counts as witnessed when at
// least one living NPC who is not the victim, and not one of V's own companions, was close
// enough to see it happen.

// Can this NPC actually see V, or is there a wall in the way? Falls back to "yes" when the
// reaction component is missing, so a missing component never silently hands out free stealth.
func CBWitnessCanSee(npc: wref<ScriptedPuppet>, player: wref<GameObject>) -> Bool {
  if !CBConfig.WitnessRequiresLineOfSight() || !IsDefined(player) {
    return true;
  }
  if !IsDefined(npc) || !npc.IsAttached() {
    return false;
  }
  let reaction = npc.GetStimReactionComponent();
  if !IsDefined(reaction) {
    return true;
  }
  return reaction.IsTargetVisible(player);
}

// How many nearby NPCs could have seen this. Capped: the callers only need "any" and a rough
// sense of "a crowd", not an exact tally.
public func CBCountWitnesses(sys: ref<CyberbaneSystem>, at: Vector4, victim: EntityID) -> Int32 {
  if !IsDefined(sys) {
    return 1;   // cannot tell: treat as seen
  }
  let reg = sys.GetRegistry();
  if !IsDefined(reg) {
    return 1;   // same - degrade toward "witnessed", never toward silently free stealth
  }
  let npcs = reg.GetAll();
  let player = GetPlayer(sys.GetGameInstance());
  // Fewer eyes reach as far at night and in the rain (Model/Moment.reds).
  let radius = CBConfig.WitnessRadius() * CBSightMult(sys.GetGameInstance());
  let seen = 0;
  let scanned = 0;
  let i = 0;
  while i < ArraySize(npcs) && scanned < CBConfig.WitnessScanCap() && seen < CBConfig.WitnessCountCap() {
    let npc = npcs[i];
    i += 1;
    // CBNpcSafe is the same gate the Director uses: attached, and past its warm-up ticks. Only somebody in range counts
    // against the scan cap.
    if CBNpcSafe(sys, npc) && Vector4.Distance(at, npc.GetWorldPosition()) <= radius {
      scanned += 1;
      // Anybody in the fight saw it: somebody shooting at V knows where V is.
      if NotEquals(npc.GetEntityID(), victim)
         && CBStillStanding(npc)
         && !ScriptedPuppet.IsPlayerCompanion(npc)
         && (CBNpcInCombat(npc) || CBWitnessCanSee(npc, player)) {
        seen += 1;
      }
    }
  }
  return seen;
}
