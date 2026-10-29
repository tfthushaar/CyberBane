// Cyberbane - Reading whether V is in the middle of something quiet (spec §16)
//
// Cyberbane only ever asked "is V in combat?" before sending someone after them. A player
// picking a hideout apart silently is not in combat, so that check said "now is a fine time"
// at precisely the worst moment: a Rival or a hit squad would materialise in the middle of an
// infiltration, and the arrival itself alerted the guards being slipped past.
//
// The game maintains exactly the state needed for this, so Cyberbane reads it rather than
// trying to infer it: V's combat state goes to Stealth while a stealth situation is live.
//
// Crash safety: one guarded blackboard read, no entity handles, no scan. Called when
// something is about to spawn and when the Hub is open.

// Is V in the game's own stealth state right this instant? Only true while crouched.
public func CBPlayerInStealthState(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let psm = bbs.Get(GetAllBlackboardDefs().PlayerStateMachine);
  if !IsDefined(psm) {
    return false;
  }
  // The game already knows. It puts V into the Stealth combat state when there is an active
  // stealth situation: hostiles who have not found V yet and a fight that has not started.
  //
  // An earlier version of this scanned for nearby hostile NPCs who were not in combat, which
  // sounded right and was badly wrong: gangers idling in their own turf are hostile and not
  // fighting, so most of Watson would have counted as a stealth job and Rivals would have
  // stopped arriving almost everywhere. Reading the state the game itself maintains is both
  // more accurate and far cheaper, since it is one blackboard read instead of a scan.
  let combatState = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Combat);
  return combatState == EnumInt(gamePSMCombat.Stealth);
}

// Should an arrival hold off? True through the whole quiet stretch, not only the crouched
// moments, because the system tops up a short grace window every tick it sees the state.
public func CBStealthEncounterNearby(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if IsDefined(sys) {
    return sys.IsStealthHeld();
  }
  return CBPlayerInStealthState(game);
}

// One line for the Hub, so a held arrival explains itself instead of showing a countdown that
// never reaches zero.
public func CBStealthHoldReason(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  if CBStealthEncounterNearby(sys, game) {
    return "Holding off while you are working quietly. They will not walk in on a stealth job.";
  }
  return "";
}

// ---- Why no Rival can arrive right now --------------------------------------
//
// Plain Int32 constants rather than an enum, to match how the other masks and role ids in
// this codebase are done and so the value can sit on the system without a schema change.
public func CBHoldNone() -> Int32 = 0
public func CBHoldQuietWork() -> Int32 = 1
public func CBHoldOneAlreadyOut() -> Int32 = 2
public func CBHoldInCombat() -> Int32 = 3
public func CBHoldNoRoom() -> Int32 = 4

// What the Hub says while the clocks are stopped.
public func CBHoldLabel(reason: Int32) -> String {
  if reason == CBHoldQuietWork() {
    return "holding off, quiet job";
  }
  if reason == CBHoldOneAlreadyOut() {
    return "waiting their turn";
  }
  if reason == CBHoldInCombat() {
    return "holding off, you are busy";
  }
  if reason == CBHoldNoRoom() {
    return "cannot reach you here";
  }
  return "";
}
