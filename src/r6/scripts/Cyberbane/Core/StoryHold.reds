// Cyberbane - When the story has the stage (spec §16)
//
// Two reports, one cause:
//
//   "In the VR fight section I saw an enemy rival spawn in, but the only damage you can do is
//    melee from the pistol you are holding, so you can't progress until you reload."
//   "An attack happened while going with River to the water tower."
//
// Every gate Cyberbane had asked about *places*: a safe area, a restricted or dangerous zone,
// the map pins of the objective V happens to be tracking, and the scene tier. None of those is
// what makes a moment the story's. A VR fight is ordinary gameplay on scene tier 1, in no hostile
// zone, with no map pins; a walk with River is an open field with the objective's pin somewhere
// else, or with nothing tracked at all. Both passed every gate, so the clocks ran, the arrival
// was placed, and the story was broken.
//
// The game does say when it is directing V, and says it on V rather than on the map. This file
// reads what it says, in three plain questions:
//
//   1. Is the player V at all? `PlayerPuppet.IsReplacer` is true whenever the player is
//      somebody else - the VR avatar (`Character.q000_vr_replacer`, the same check the settings
//      menu uses to refuse the tutorial replay), Johnny in a flashback, anyone the story puts you
//      in - and V is not in V's own world in cyberspace or a braindance either. Then nothing
//      Cyberbane does means anything: nobody is sent, nothing is scored, nobody reacts to a
//      reputation that is not the player's, and nothing is paid out of somebody else's pocket.
//   2. Has the story taken control of what V can do? Quests and set pieces apply gameplay
//      restrictions as status effects, and the game itself reads them by tag to decide what V
//      may wield, whether the weapon wheel opens, whether V can move (quickSlotsManager.script
//      326, radialWheel.script 788, equipmentSystem.script 4262-4345). A fist fight, a shooting
//      contest, a VR bout with one pistol, a ride in somebody's car, a metro seat, a lore scene:
//      each is one of these, and a Rival walking into any of them is a fight V cannot have.
//   3. Is somebody from the story walking with V? `ScriptedPuppet.IsPlayerCompanion` is the
//      game's own test for an NPC whose AI role is following the player
//      (aiComponent.script:520-532). With a story character in that role - River, Panam, Judy -
//      V is in the middle of their quest, wherever the objective's pin happens to be.
//
// While any of these is true, nobody is sent, every clock waits, anybody of ours who has not yet
// reached V is quietly called back, and the street does not turn on V. Unlike "Stay out of quest
// areas", none of this can be switched off: it is not a preference about where trouble may find
// V, it is the game saying the stage is taken.

public func CBStoryNone() -> Int32 = 0
public func CBStoryScene() -> Int32 = 1
public func CBStoryRestricted() -> Int32 = 2
public func CBStoryCompanion() -> Int32 = 3
public func CBStoryNotV() -> Int32 = 4

// What the Hub and the log say about it.
public func CBStoryLabel(reason: Int32) -> String {
  if reason == CBStoryScene() {
    return "a scene is playing";
  }
  if reason == CBStoryRestricted() {
    return "the story is directing what you can do";
  }
  if reason == CBStoryCompanion() {
    return "somebody from the story is with you";
  }
  if reason == CBStoryNotV() {
    return "you are not yourself right now";
  }
  return "";
}

// The gameplay restrictions that mean the story has V.
//
// Only tags the game applies to stage something, each of which it reads itself before letting V
// fight, move or change weapons. Two lists, because the game also puts some of the same
// restrictions on V during ordinary play, and those must never read as the story:
//
//   - In any vehicle, driving or riding, the game limits V's weapons itself: NoWeapons for a
//     driver who cannot fight from that car, Firearms for a passenger
//     (vehicleTransition.script:99, 126, 1556, 1854). So the weapon limits below are ignored while
//     V is in a car. A ride the story is giving V carries VehicleScene, which is on the first list.
//   - A thrown melee weapon holds FirearmsNoUnequipNoSwitch for the length of the throw
//     (meleeTransitions.script:791), and getting in or out of a car passes through the vehicle
//     limits on the way. Those last a moment; a VR bout or a ride with River lasts minutes. So a
//     restriction has to have held for StoryRestrictionSettleTicks before anything is called back
//     (CyberbaneSystem.RefreshStoryHold); a new arrival is refused the moment one appears, because
//     a refusal costs nothing but a short wait.
//   - NoMovement is not on either list. The game applies it when V dies (highLevelTransitions
//     .script:692) and while lifting a body (carriedObject.script:813), and with a death mod such
//     as Fenix Rebirth the first of those would call the hunters back in the middle of the fight.
//     A quest that holds V in place does it with a scene, which is checked separately.
//
// Deliberately on neither list: the driving-combat and vehicle-weapon tags (V fighting from a car
// in free roam), the perk and cyberware buffs that share the status-effect system, phone call tags
// (fixers ring in free roam all the time), and the fast-travel and time-skip blocks, which some
// regions carry for long stretches of ordinary play. A tag on these lists costs at most a quiet
// stretch; one wrongly added could silence the mod.
public func CBStoryRestrictionTags() -> array<CName> {
  let tags: array<CName>;
  // V may not fight, or may only fight the way the scene allows.
  ArrayPush(tags, n"NoCombat");
  ArrayPush(tags, n"Fists");
  ArrayPush(tags, n"FistFight");
  ArrayPush(tags, n"Melee");
  ArrayPush(tags, n"ShootingRangeCompetition");
  // V is somewhere else, or being carried there.
  ArrayPush(tags, n"Braindance");
  ArrayPush(tags, n"Cyberspace");
  ArrayPush(tags, n"VehicleScene");
  ArrayPush(tags, n"FastForward");
  ArrayPush(tags, n"MetroRide");
  ArrayPush(tags, n"DelamainTaxi");
  ArrayPush(tags, n"SpaceShuttleInterior");
  // V is held by the scene.
  ArrayPush(tags, n"LoreAnim");
  ArrayPush(tags, n"NoWorldInteractions");
  ArrayPush(tags, n"Sleep");
  return tags;
}

// The story choosing V's weapon - one pistol V cannot put away, no weapons at all - which the game
// also does by itself in any car (see above), so these only count outside one.
public func CBStoryWeaponTags() -> array<CName> {
  let tags: array<CName>;
  ArrayPush(tags, n"NoWeapons");
  ArrayPush(tags, n"Firearms");
  ArrayPush(tags, n"OneHandedFirearms");
  ArrayPush(tags, n"FirearmsNoSwitch");
  ArrayPush(tags, n"FirearmsNoUnequip");
  ArrayPush(tags, n"FirearmsNoUnequipNoSwitch");
  ArrayPush(tags, n"NoWeaponWheel");
  return tags;
}

public func CBHasAnyTag(obj: ref<GameObject>, tags: array<CName>) -> Bool {
  if !IsDefined(obj) {
    return false;
  }
  for tag in tags {
    if StatusEffectSystem.ObjectHasStatusEffectWithTag(obj, tag) {
      return true;
    }
  }
  return false;
}

// Is the player V, in V's own world?
//
// False for the VR avatar, Johnny, anyone else the story makes you, and for V in cyberspace or a
// braindance. Asked on every hit V lands, so it is kept to a record id compare and two tag reads.
public func CBPlayerIsVHere(player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  if player.IsReplacer() {
    return false;
  }
  return !StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"Cyberspace")
      && !StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"Braindance");
}

public func CBGameHasVHere(game: GameInstance) -> Bool {
  return CBPlayerIsVHere(GetPlayer(game));
}

// Has the story taken control of what V can do? As of this instant; see CBStoryRestrictionTags
// for why the system only acts on this once it has held for a few ticks.
public func CBPlayerStoryRestricted(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  if CBHasAnyTag(player, CBStoryRestrictionTags()) {
    return true;
  }
  // In a car the weapon limits are the car's, not the story's.
  if VehicleComponent.IsMountedToVehicle(game, player) {
    return false;
  }
  return CBHasAnyTag(player, CBStoryWeaponTags());
}

// Somebody the story placed is walking with V.
//
// The registry already holds every NPC that has attached near V, so this is a pass over it with
// the cheap tests first: settled, alive, close. Only then the game's own companion test, and only
// for a companion the question of whose they are.
public func CBStoryCompanionWithV(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let player = GetPlayer(game);
  let reg = sys.GetRegistry();
  if !IsDefined(player) || !IsDefined(reg) {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  let ppos = player.GetWorldPosition();
  let reach = CBConfig.StoryCompanionRadius();
  for p in reg.GetAll() {
    if CBNpcSafe(sys, p) && !p.IsDead()
       && Vector4.Distance(p.GetWorldPosition(), ppos) <= reach
       && p.IsPlayerCompanion() && CBIsStoryCompanion(p, des) {
      return true;
    }
  }
  return false;
}

// Whose companion is this: the story's, or one somebody chose?
//
// A companion from Appearance Menu Mod or anything like it can be a story character too - Panam
// is a popular one - and walks around with V for hours of ordinary play. Holding everything for
// those would switch the mod off for the people who use them. So: anybody the quest system has
// flagged is the story's; anybody a script mod created through the dynamic entity system is not;
// and between those, the record's own quest affiliation decides, the same test that keeps story
// characters off the Rival roster (CBRecordIsUniqueCharacter).
public func CBIsStoryCompanion(p: wref<ScriptedPuppet>, des: ref<DynamicEntitySystem>) -> Bool {
  if !IsDefined(p) {
    return false;
  }
  if p.IsQuest() {
    return true;
  }
  if IsDefined(des) && des.IsManaged(p.GetEntityID()) {
    return false;
  }
  return CBRecordIsUniqueCharacter(p.GetRecordID());
}

// The whole question, in order of how much it settles. Called once per settled fast tick by the
// system, which works out whether a restriction has held long enough to count; the answer is kept
// on the system (GetStoryHold) for everything that runs between ticks.
public func CBComputeStoryHold(sys: ref<CyberbaneSystem>, game: GameInstance, restrictionHeld: Bool) -> Int32 {
  if !CBGameHasVHere(game) {
    return CBStoryNotV();
  }
  if CBPlayerInScene(game) {
    return CBStoryScene();
  }
  if restrictionHeld {
    return CBStoryRestricted();
  }
  if CBStoryCompanionWithV(sys, game) {
    return CBStoryCompanion();
  }
  return CBStoryNone();
}

// Asked at the moment of placing somebody, which can be between ticks: the live answer for
// everything that is cheap to read, and the last tick's answer for the companion pass. A
// restriction refuses the arrival the instant it appears, without waiting for it to settle: a
// refusal only makes them try again later, and the story may have only just begun.
public func CBStoryHoldNow(game: GameInstance) -> Bool {
  if !CBGameHasVHere(game) || CBPlayerInScene(game) || CBPlayerStoryRestricted(game) {
    return true;
  }
  let sys = CyberbaneSystem.Get(game);
  return IsDefined(sys) && sys.GetStoryHold() != CBStoryNone();
}

// The story has the stage: call back anybody of ours who has not reached V.
//
// Quietly. This is not V shaking them off, so nobody is promoted, nobody texts, and no gang
// thinks less of V for running; a Rival simply goes back to waiting their turn. Only people out
// of V's sight are removed, the same discretion the chase give-up uses, and anybody in sight is
// left exactly as they are - not untagged, not orphaned - so if a fight is already on it still
// counts. They are removed on a later tick, once V can no longer see them. A car's crew is told
// to get out somewhere V cannot see it, and removed once they are out; until then it holds its
// seats, as it does at a job (Spawn/Arrival.reds).
public func CBStoryStandDown(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !des.IsPopulated(n"Cyberbane") {
    if sys.GetHuntState() != CBHuntNone() {
      CBStoryResetHunt(sys);
    }
    return;
  }
  let removed = CBStoryRemoveUnseen(game, des, n"CB_Rival")
              + CBStoryRemoveUnseen(game, des, n"CB_Squad")
              + CBStoryRemoveUnseen(game, des, n"CB_Apex")
              + CBStoryRemoveUnseen(game, des, n"CB_Escort")
              + CBStoryRemoveUnseen(game, des, n"CB_Scout")
              + CBStoryRemoveUnseen(game, des, n"CB_Lair");
  if removed > 0 {
    CBLog.Info(n"Spawn", s"The story has the stage (\(CBStoryLabel(sys.GetStoryHold()))): called back \(removed) of ours who had not reached you.");
  }
  let anyLeft = CBLiveTaggedPresent(game, n"CB_Rival") || CBLiveTaggedPresent(game, n"CB_Squad")
             || CBLiveTaggedPresent(game, n"CB_Apex") || CBLiveTaggedPresent(game, n"CB_Escort")
             || CBLiveTaggedPresent(game, n"CB_Scout");
  if !anyLeft && sys.GetHuntState() != CBHuntNone() {
    CBStoryResetHunt(sys);
  }
}

// Remove everybody wearing this tag whom V cannot see, and nobody else.
//
// Through CBRemoveOne, the removal every sweep in the mod already uses: it leaves anybody still
// spawning or in V's sight where they are, and orders anybody in a seat out first, so they are
// removed on a later tick once they are standing somewhere V cannot see - never deleted from inside
// a car. What it does not do, and CBDeleteTaggedSafe does, is untag the ones it leaves behind;
// here they keep their tags, so a fight already under way still counts as the fight it is. The
// cars themselves are left to the remains sweep, which takes a car once nobody of ours sits in it.
func CBStoryRemoveUnseen(game: GameInstance, des: ref<DynamicEntitySystem>, tag: CName) -> Int32 {
  let removed = 0;
  let ids = des.GetTaggedIDs(tag);
  for id in ids {
    if CBRemoveOne(game, des, id, false, true) {
      removed += 1;
    }
  }
  return removed;
}

// Nobody of ours is left standing: the hunt is simply over, with nothing said about it.
func CBStoryResetHunt(sys: ref<CyberbaneSystem>) -> Void {
  let r = sys.FindRivalById(sys.GetActiveRivalId());
  if IsDefined(r) {
    // Back in the queue, unpromoted, and not straight back out the moment the story lets go.
    r.huntTicks = Max(r.huntTicks, CBConfig.RivalHuntRetryTicks());
  }
  sys.ClearScout();
  sys.ClearApexMuster();   // nobody of theirs keeps walking in while the story has the stage
  sys.SetHuntState(CBHuntNone());
  sys.SetHuntFaction(n"");
  sys.SetHuntGrade("");
  sys.SetActiveRivalId(0);
  sys.SetActiveSquadFaction(n"");
  sys.GetThreatBar().Hide();
}
