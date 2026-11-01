// Cyberbane - Safe areas (spec §16)
//
// Night City marks apartments, clinics, bars and memorials as safe areas, and that marking
// does two separate things. The first is the zone itself: the SAFE AREA label, the minimap
// tint, and who reacts to what. The second is a restriction layer that forces V's hands empty
// so no weapon can be drawn, which is why "Action Blocked" appears if you try.
//
// That second part is what made a Rival arriving in an apartment a problem rather than a
// surprise: the fight starts, and V cannot draw. So Cyberbane keeps its spawns out of safe
// areas by default, and offers the two settings that let a player opt into that fight.
//
// The gates here deliberately mirror what the game's own reaction component does, rather than
// inventing a rule:
//   per NPC  - in a safe area AND indoors. An outdoor safe area, a memorial plaza say, does
//              not silence the people standing in it.
//   per V    - a NoCombat status tag, or the Safe zone state, or standing in a safe area.

// ---- Why an arrival was refused ----------------------------------------------
//
// Recorded on the runtime every time a spawn is declined, so the Hub and the log can name the
// gate instead of leaving it to be found by reading source. Plain Int32 constants to match the
// other ids in this codebase.
public func CBBlockNone() -> Int32 = 0
public func CBBlockWorldBusy() -> Int32 = 1
public func CBBlockCannotFight() -> Int32 = 2
public func CBBlockQuestArea() -> Int32 = 3
public func CBBlockProtectedZone() -> Int32 = 4
public func CBBlockSafeArea() -> Int32 = 5
public func CBBlockNoGround() -> Int32 = 6
public func CBBlockEngineRefused() -> Int32 = 7
public func CBBlockNoRecord() -> Int32 = 8
public func CBBlockInView() -> Int32 = 9
public func CBBlockHostileArea() -> Int32 = 10

public func CBNoteSpawnBlock(reason: Int32) -> Void {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    rt.SetLastSpawnBlock(reason);
  }
}

// Short, plain description for the Hub.
public func CBBlockLabel(reason: Int32) -> String {
  if reason == CBBlockWorldBusy() {
    return "world still loading";
  }
  if reason == CBBlockCannotFight() {
    return "you cannot draw here";
  }
  if reason == CBBlockQuestArea() {
    return "you are on a job";
  }
  if reason == CBBlockProtectedZone() {
    return "protected area";
  }
  if reason == CBBlockSafeArea() {
    return "safe area";
  }
  if reason == CBBlockNoGround() {
    return "no ground to stand on";
  }
  if reason == CBBlockEngineRefused() {
    return "the game refused the spawn";
  }
  if reason == CBBlockNoRecord() {
    return "no gang member on file";
  }
  if reason == CBBlockInView() {
    return "nowhere out of your sight";
  }
  if reason == CBBlockHostileArea() {
    return "you are inside somebody else's turf";
  }
  return "";
}

// Has the player opted into being hunted inside safe areas?
public func CBAllowSafeZoneSpawns() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().allowSafeZoneSpawns;
}

// Can V actually fight where they are standing?
//
// This is the question that matters before sending anyone, and it is NOT the same question as
// "is this a security area". V's apartment is the case that proved it: the SAFE AREA system
// governs the label, the minimap tint and who reacts, while a separate restriction layer is
// what empties V's hands. An apartment can fail the first test and still pass the second, so
// checking only the safe area let Rivals walk into H10 even with safe area spawns turned off.
//
// `ForceEmptyHands` on the player's upper body is the restriction itself, and it is true for
// as long as V is somewhere weapons are not allowed. If V cannot draw, nobody should arrive.
public func CBPlayerCannotFight(game: GameInstance) -> Bool {
  if CBPlayerNoCombatTag(game) {
    return true;
  }
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let psm = bbs.Get(GetAllBlackboardDefs().PlayerStateMachine);
  if !IsDefined(psm) {
    return false;
  }
  let upper = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody);
  // Bounded against the same mistake that broke the zone check in 1.1.5.
  //
  // An unread or freshly reset blackboard int is 0. If `ForceEmptyHands` happened to be the
  // zero member of its enum, this would read true before the game had said anything at all,
  // and every arrival in the mod would be refused everywhere - exactly the failure the zone
  // ordinal produced. Requiring the state to differ from Default makes that impossible to
  // happen silently: if the two ever coincided, the test simply never fires, which costs one
  // apartment check rather than the whole mod.
  let emptyHands = EnumInt(gamePSMUpperBodyStates.ForceEmptyHands);
  if emptyHands == EnumInt(gamePSMUpperBodyStates.Default) {
    return false;
  }
  return upper == emptyHands;
}

// Is V inside? Used to keep an arrival out of a corridor or a one room flat, where there is
// nowhere for somebody to come from and they can only appear in front of you.
public func CBPlayerIndoors(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  return IsEntityInInteriorArea(player);
}

// Is V inside a quest or gig area?
//
// This is the gate behind the worst report the mod has had: "I was attacked by rivals during
// I WALK THE LINE, they appeared in the middle of the Animals' nest, and it forced me to
// restart several times." The gate existed, was switched on, and did not fire.
//
// `PreventionSystem.IsPlayerInQuestArea` is not what its name suggests. Reading it
// (`core/systems/preventionSystem.script:352`):
//
//     return ( Int32 )m_playerHLS > ( Int32 )gamePSMHighLevel.SceneTier1
//         && ( Int32 )m_playerHLS <= ( Int32 )gamePSMHighLevel.SceneTier5;
//
// It is a scene test. It is true during a cutscene or a locked conversation and false for
// every other second of a quest, so walking a gang compound with a gun out was, as far as this
// gate was concerned, an ordinary afternoon in Night City.
//
// What the game does track is the zone, on `PlayerStateMachine.Zones` as a `gamePSMZones`:
// Default, Public, Safe, Restricted, Dangerous. `Player.OnEnterRestrictedZone` and
// `OnEnterDangerousZone` set it, and `GetCurrentZoneType` shows a quest can set it too, by
// fact, overriding the security area. So a gang nest, a corpo floor, a compound a quest has
// marked hostile - all of them report Restricted or Dangerous, and the open street reports
// Public. That is exactly the question this gate was trying to ask.
//
// It is also safe in a way the previous attempt was not. 1.1.5 compared `ESecurityAreaType`
// ordinals, which redscript cannot see by name, guessed wrong, and blocked every spawn in the
// game for three releases. `gamePSMZones` is a named enum we can compile against, so there is
// nothing left to guess.
public func CBPlayerInQuestArea(game: GameInstance) -> Bool {
  // Switchable, because this is the one gate here that can cover a large area and there is no
  // way to measure how large from script. After three releases lost to gates that silently
  // refused everything, a player who suspects it should be able to rule it out in one toggle
  // rather than wait for a patch. The diagnostic names it too.
  let rtQ = CyberbaneRuntime.Get();
  if IsDefined(rtQ) && rtQ.HasSettings() && !rtQ.GetSettings().respectQuestAreas {
    return false;
  }
  if CBPlayerInScene(game) {
    return true;
  }
  return CBPlayerInHostileZone(game);
}

// Mid-scene: a cutscene, a locked conversation, a braindance.
public func CBPlayerInScene(game: GameInstance) -> Bool {
  let container = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return false;
  }
  let ps = container.Get(n"PreventionSystem") as PreventionSystem;
  if !IsDefined(ps) {
    return false;
  }
  return ps.IsPlayerInQuestArea();
}

// Standing in a restricted or dangerous zone: somebody else's turf, marked as such by the
// security system or by a quest.
//
// This is also the answer to the stealth complaint. A player slipping through a compound is
// inside one of these the whole time, whether or not the game has decided a stealth situation
// is live, so an arrival now holds off for the duration rather than only while V is crouched
// and already spotted-but-not-seen.
public func CBPlayerInHostileZone(game: GameInstance) -> Bool {
  let zone = CBPlayerZone(game);
  return zone == EnumInt(gamePSMZones.Restricted) || zone == EnumInt(gamePSMZones.Dangerous);
}

// The zone the game says V is in. `Default` (0) means it has not said yet, which reads as
// ordinary city rather than as a reason to refuse everything - the same bounding that keeps
// CBPlayerCannotFight honest about an unread blackboard.
public func CBPlayerZone(game: GameInstance) -> Int32 {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return EnumInt(gamePSMZones.Default);
  }
  let psm = bbs.Get(GetAllBlackboardDefs().PlayerStateMachine);
  if !IsDefined(psm) {
    return EnumInt(gamePSMZones.Default);
  }
  return psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Zones);
}

// Short label for the Hub, so a held arrival explains itself.
public func CBPlayerZoneLabel(game: GameInstance) -> String {
  let zone = CBPlayerZone(game);
  if zone == EnumInt(gamePSMZones.Safe) {
    return "safe area";
  }
  if zone == EnumInt(gamePSMZones.Restricted) {
    return "restricted area";
  }
  if zone == EnumInt(gamePSMZones.Dangerous) {
    return "dangerous area";
  }
  if zone == EnumInt(gamePSMZones.Public) {
    return "open city";
  }
  return "";
}

// Gone with 1.4.7: the ESecurityAreaType cache, the OnZoneChange wrapper that filled it, and
// the CBInProtectedZone test that read it.
//
// It was tracking the right thing through the wrong door. `ESecurityAreaType` does not expose
// its members to redscript by name, so the test compared ordinals, and the guess about which
// low ordinals meant "protected" was wrong: the open street reports a low one too. That
// blocked every spawn in the city for three releases, and the eventual patch - only apply it
// when V is also indoors - is what let a Rival appear in the middle of a gang compound during
// a quest, because a courtyard is not an interior.
//
// `PlayerStateMachine.Zones` carries the same information as a named `gamePSMZones`, which the
// compiler can check. See CBPlayerZone above. Nothing guesses any more, so there is nothing
// left for this to cache.

// Should Cyberbane refuse to put anyone down here?
//
// Checks the spawn point itself, not just where V is standing. V can be on the pavement with
// the point behind them inside a bar, or the reverse, and only the point matters for whether
// the arrival lands somewhere the player cannot fight.
public func CBSafeAreaBlocksSpawn(game: GameInstance, at: Vector4) -> Bool {
  if CBAllowSafeZoneSpawns() {
    return false;   // the player has asked for this fight
  }
  // The restriction layer, which is what actually stops V drawing a weapon in an apartment.
  if CBPlayerCannotFight(game) {
    CBNoteSpawnBlock(CBBlockCannotFight());
    return true;
  }
  // The game's own no-spawn areas, which is how the NCPD know not to materialise inside a
  // megabuilding lobby. Reusing the police answer rather than keeping a second opinion: this
  // is a plain point test with no side effects, and it can only ever refuse a point, never
  // allow one the checks below would have rejected.
  let pss = GameInstance.GetPreventionSpawnSystem(game);
  if IsDefined(pss) && pss.IsPointInPreventionFreeArea(at) {
    CBNoteSpawnBlock(CBBlockProtectedZone());
    return true;
  }
  // Mid-scene: a cutscene or a locked conversation.
  if CBPlayerInScene(game) {
    CBNoteSpawnBlock(CBBlockQuestArea());
    return true;
  }
  // Somebody else's turf. The zone the game itself publishes, by name.
  //
  // This replaces a comparison of `ESecurityAreaType` ordinals that redscript cannot read by
  // name. That guess was wrong in 1.1.5 and blocked every spawn in the city for three
  // releases, which is why it had been narrowed to "only when also indoors" - and that
  // narrowing is what let a Rival walk into the middle of a gang nest during a quest, because
  // a compound courtyard is not an interior. `gamePSMZones` is a named enum and needs no
  // guess, so the test can be the right one again. Switchable with the quest-area gate, since
  // it is the same question.
  let rtZone = CyberbaneRuntime.Get();
  let respect = !IsDefined(rtZone) || !rtZone.HasSettings() || rtZone.GetSettings().respectQuestAreas;
  if respect && CBPlayerInHostileZone(game) {
    CBNoteSpawnBlock(CBBlockHostileArea());
    return true;
  }
  let sam = GameInstance.GetSafeAreaManager(game);
  if !IsDefined(sam) {
    return false;   // cannot tell: do not silently stop every spawn in the game
  }
  if sam.IsPointInSafeArea(at) {
    CBNoteSpawnBlock(CBBlockSafeArea());
    return true;
  }
  return false;
}

// Is this NPC somewhere it should be left alone, whatever V has done?
//
// Mirrors the game's own check: a safe area on its own is not enough, it has to be an indoor
// one. That is what keeps people inside a bar out of it while the crowd on the street outside
// still reacts normally, which the old single global flag could not express.
public func CBNpcInSafeInterior(npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) {
    return false;
  }
  let sam = GameInstance.GetSafeAreaManager(npc.GetGame());
  if !IsDefined(sam) {
    return false;
  }
  return sam.IsPointInSafeArea(npc.GetWorldPosition()) && IsEntityInInteriorArea(npc);
}

// Is V under a scripted no-combat restriction right now?
//
// Separate from the zone: scenes and story beats apply this tag without the player being in a
// safe area at all. The game's reaction component checks it before anything else, and
// Cyberbane was missing it, so reactions could fire during moments the game had explicitly
// put a lid on.
public func CBPlayerNoCombatTag(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  return StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"NoCombat");
}

// Undo the disarm the game applies on entering a safe area, when the player has asked for it.
//
// Wrapped rather than replaced on purpose. OnEnterSafeZone queues the ForceEmptyHandsByZone
// parameter, sets the Safe zone state and plays a tone; replacing it would mean owning all
// three forever and fighting any other mod that touches the same method. Letting it run and
// then queueing the one parameter back to false leaves the zone semantics completely intact -
// Cyberbane's own safe-area logic, the minimap, the label and every other mod still see a
// normal safe area - and only the weapon lock is lifted.
//
// If the setting is off this does nothing at all, which is the default.
@wrapMethod(PlayerPuppet)
private final func OnEnterSafeZone() -> Void {
  wrappedMethod();
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() || !rt.HasSettings() || !rt.GetSettings().allowSafeZoneCombat {
    return;
  }
  let evt = new PSMPostponedParameterBool();
  evt.id = n"ForceEmptyHandsByZone";
  evt.value = false;
  evt.aspect = gamestateMachineParameterAspect.Permanent;
  this.QueueEvent(evt);
}
