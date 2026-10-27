// Cyberbane - Witnesses (spec §8.5)
//
// Reputation travels because somebody lived to carry it. A kill counts as witnessed when at
// least one living NPC who is not the victim, and not one of V's own companions, was close
// enough to see it happen.
//
// Everything downstream of this was already built and was being handed a hardcoded `true`:
// the unwitnessed Renown / Dread / standing multipliers in CBApplyKill, the Ghost archetype
// accrual, and the rumor spread multiplier in CBCreateRumor. Wiring the real count turns one
// constant into two playstyles - leave people alive and word travels fast and far, or leave
// nobody and the street gets a reputation it cannot put a name to.
//
// Crash safety: this walks CBNpcRegistry, the same list the reaction Director already walks
// every tick, and every entry goes through CBNpcSafe before anything is read off it, so a
// detaching or not-yet-initialized puppet is never touched. The scan is bounded by
// WitnessScanCap and runs once per kill, never per tick. It adds no new engine API: the
// registry, CBNpcSafe, GetWorldPosition and IsDead are all already on the reaction hot path.

// How many nearby NPCs could have seen this. Capped: the callers only need "any" and a rough
// sense of "a crowd", not an exact tally.
public func CBCountWitnesses(sys: ref<CyberbaneSystem>, at: Vector4, victim: EntityID) -> Int32 {
  if !IsDefined(sys) {
    return 1;   // cannot tell: treat as seen, which is the pre-0.1.16 behaviour
  }
  let reg = sys.GetRegistry();
  if !IsDefined(reg) {
    return 1;   // same - degrade toward "witnessed", never toward silently free stealth
  }
  let npcs = reg.GetAll();
  let radius = CBConfig.WitnessRadius();
  let seen = 0;
  let scanned = 0;
  let i = 0;
  while i < ArraySize(npcs) && scanned < CBConfig.WitnessScanCap() && seen < CBConfig.WitnessCountCap() {
    let npc = npcs[i];
    i += 1;
    // CBNpcSafe is the same gate the Director uses: attached, and past its warm-up ticks.
    if CBNpcSafe(sys, npc) {
      scanned += 1;
      if NotEquals(npc.GetEntityID(), victim)
         && !npc.IsDead()
         && !ScriptedPuppet.IsPlayerCompanion(npc)
         && Vector4.Distance(at, npc.GetWorldPosition()) <= radius {
        seen += 1;
      }
    }
  }
  return seen;
}
