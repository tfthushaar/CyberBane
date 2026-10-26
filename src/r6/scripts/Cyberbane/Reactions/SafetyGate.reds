// Cyberbane - Safety Gate (spec §16)
//
// Single authority on whether an NPC may be affected by Cyberbane. This is the
// first-pass gate; the full quest/companion/scene/workspot/braindance checks are
// spike S-13 and are layered in as those detections are verified. When in doubt,
// return false (do nothing) - that is the safe default the whole spec is built on.

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
    if puppet.IsQuest() {
      return false;   // never touch quest NPCs (spec §16.1)
    }
    if puppet.IsPlayerCompanion() {
      return false;   // never touch companions / crew (spec §16.1)
    }
    if puppet.IsVendor() {
      return false;   // leave vendors and their transactions alone (spec §16)
    }
    // NPCs driving a workspot are usually in a scripted beat (scenes, sitting,
    // leaning, performances). Safe default: leave them be (spec §16, S-13).
    let ws = GameInstance.GetWorkspotSystem(puppet.GetGame());
    if IsDefined(ws) && ws.IsActorInWorkspot(puppet) {
      return false;
    }
    // Safe areas are handled one level up, by the reaction systems themselves, via
    // CBPlayerInSafeZone - it is a property of where V is standing, not of this NPC.
    // TODO S-13: unique exclusion list, AMM-spawned, braindance, active-quest-area
    // exclusions.
    return true;
  }
}
