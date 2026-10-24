// Cyberbane — Safety Gate (spec §16)
//
// Single authority on whether an NPC may be affected by Cyberbane. This is the
// first-pass gate; the full quest/companion/scene/workspot/braindance checks are
// spike S-13 and are layered in as those detections are verified. When in doubt,
// return false (do nothing) — that is the safe default the whole spec is built on.

public abstract class CBSafetyGate {
  public static func CanAffect(puppet: ref<ScriptedPuppet>) -> Bool {
    if !IsDefined(puppet) {
      return false;
    }
    if puppet.IsPlayer() {
      return false;
    }
    if puppet.IsDead() {
      return false;
    }
    // TODO S-13: quest NPC, unique/companion, scene/workspot, AMM-spawned, vendor
    // mid-transaction, safe zones, braindance, active-quest-area exclusions.
    return true;
  }
}
