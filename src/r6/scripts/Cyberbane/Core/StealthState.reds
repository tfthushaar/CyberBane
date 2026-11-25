// Cyberbane - Is V in the middle of something quiet (spec §16)
//
// Being out of combat isn't enough: someone clearing a place in stealth isn't in combat either. The game already tracks
// this (the Stealth combat state), so nobody is sent in on top of a sneaking V.

// Is V in the game's stealth state right this instant? Only true while crouched.
public func CBPlayerInStealthState(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let psm = CBPlayerPSM(game);
  if !IsDefined(psm) {
    return false;
  }
  // The game already knows. It puts V into the Stealth combat state when there is an active
  // stealth situation: hostiles who have not found V yet and a fight that has not started.
  let combatState = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Combat);
  return combatState == EnumInt(gamePSMCombat.Stealth);
}

// Should an arrival hold off? True through the whole quiet stretch, not only the crouched
// moments, because the system tops up a short grace window every tick it sees the state.
public func CBStealthEncounterNearby(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if CBPlayerInHostileZone(game) {
    return true;
  }
  if IsDefined(sys) {
    return sys.IsStealthHeld();
  }
  return CBPlayerInStealthState(game);
}

// One line for the Hub, so a held arrival explains itself instead of showing a countdown that
// never reaches zero.
public func CBStealthHoldReason(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  // The story first: it is the one hold no setting changes, and the one most worth explaining.
  if IsDefined(sys) && sys.GetStoryHold() != CBStoryNone() {
    return CBTf(n"Cyberbane-StealthState-HoldingOffNobodyWalksInOn", [CBStoryLabel(sys.GetStoryHold())]);
  }
  if CBPlayerInHostileZone(game) {
    let zone = CBPlayerZoneLabel(game);
    if StrLen(zone) == 0 {
      zone = CBT(n"Cyberbane-StealthState-SomebodyElseSTerritory");
    }
    return CBTf(n"Cyberbane-StealthState-HoldingOffTheGameCallsThis", [zone]);
  }
  if CBStealthEncounterNearby(sys, game) {
    return CBT(n"Cyberbane-StealthState-HoldingOffWhileYouAreWorking");
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
public func CBHoldWorldBusy() -> Int32 = 5
public func CBHoldStory() -> Int32 = 6

// What the Hub says while the clocks are stopped.
public func CBHoldLabel(reason: Int32) -> String {
  if reason == CBHoldQuietWork() {
    return CBT(n"Cyberbane-StealthState-HoldingOffQuietJob");
  }
  if reason == CBHoldOneAlreadyOut() {
    return CBT(n"Cyberbane-StealthState-WaitingTheirTurn");
  }
  if reason == CBHoldInCombat() {
    return CBT(n"Cyberbane-StealthState-HoldingOffYouAreBusy");
  }
  if reason == CBHoldNoRoom() {
    return CBT(n"Cyberbane-StealthState-CannotReachYouHere");
  }
  if reason == CBHoldWorldBusy() {
    return CBT(n"Cyberbane-StealthState-HoldingWorldIsLoading");
  }
  if reason == CBHoldStory() {
    return CBT(n"Cyberbane-StealthState-HoldingOffStory");
  }
  return "";
}
