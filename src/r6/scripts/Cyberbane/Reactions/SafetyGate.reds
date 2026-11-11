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
    // A stand-in for V (photo mode's copy, VR, the paperdoll) is never somebody to react to V.
    if puppet.IsReplacer() || puppet.IsVRReplacer() || puppet.IsPaperdoll() {
      return false;
    }
    // Not fully in the world: just streamed in, or on its way out. Every reaction that passes this
    // gate goes on to call into the NPC's components, which is only safe on an attached entity.
    if !puppet.IsAttached() {
      return false;
    }
    if puppet.IsDead() {
      return false;
    }
    if puppet.IsQuest() {
      return false;   // never touch quest NPCs (spec §16.1)
    }
    // Nor anybody the story wrote. IsQuest is only set on some of them: a gig's contact such as
    // Alan in Treating Symptoms is not flagged, and was turned hostile mid-conversation. The
    // record's own quest affiliation is the game's statement about who it authored, the same test
    // that keeps story characters off the Rival roster. Worked out once per NPC.
    if puppet.cbAuthoredState == 0 {
      puppet.cbAuthoredState = CBRecordIsUniqueCharacter(puppet.GetRecordID()) ? 1 : 2;
    }
    if puppet.cbAuthoredState == 1 {
      return false;
    }
    // Standing at the job V is tracking: part of somebody else's story, whoever they are. This
    // covers crowd fear, morale, fleeing and hostility on sight alike, wherever V is.
    //
    // The tracked job's pins, not every active objective's. 1.8.4 put every objective's pins in one
    // list, and through this gate that stopped morale, fleeing and mercy for anybody within sixty
    // metres of any gig or quest marker on the map: a fight beside one made no Rivals and earned no
    // Conduct. The Director, which turns world NPCs hostile or scared, keeps its own check against
    // every job site (Reactions/Director.reds).
    let sysGate = CyberbaneSystem.Get(puppet.GetGame());
    if IsDefined(sysGate) && sysGate.NearTrackedPins(puppet.GetWorldPosition(), CBConfig.QuestSpawnClearance()) {
      return false;
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
    // Somewhere the game protects, and indoors with it. This is the game's own test, and
    // it is per NPC rather than per player: people inside a bar are left alone while the
    // crowd on the pavement outside still reacts. An outdoor safe area, a memorial say,
    // does not silence the people standing in it (spec §16).
    if CBNpcInSafeInterior(puppet) {
      return false;
    }
    // TODO S-13: unique exclusion list, AMM-spawned, braindance, active-quest-area
    // exclusions.
    return true;
  }
}

// Whether this NPC's record is one the story wrote: 0 not yet known, 1 yes, 2 no.
@addField(ScriptedPuppet)
public let cbAuthoredState: Int32;
