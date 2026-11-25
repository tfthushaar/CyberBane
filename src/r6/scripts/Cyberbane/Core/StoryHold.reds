// Cyberbane - When the story has the stage (spec §16)
//
// Places alone can't tell when the story is running (a VR fight or a walk with River passes every place check). The
// game flags it on V while it directs the player, so every Cyberbane clock and arrival waits while that flag is up.

public func CBStoryNone() -> Int32 = 0
public func CBStoryScene() -> Int32 = 1
public func CBStoryRestricted() -> Int32 = 2
public func CBStoryCompanion() -> Int32 = 3
public func CBStoryNotV() -> Int32 = 4

// What the Hub and the log say about it.
public func CBStoryLabel(reason: Int32) -> String {
  if reason == CBStoryScene() {
    return CBT(n"Cyberbane-StoryHold-ASceneIsPlaying");
  }
  if reason == CBStoryRestricted() {
    return CBT(n"Cyberbane-StoryHold-TheStoryIsDirectingWhatYou");
  }
  if reason == CBStoryCompanion() {
    return CBT(n"Cyberbane-StoryHold-SomebodyFromTheStoryIsWith");
  }
  if reason == CBStoryNotV() {
    return CBT(n"Cyberbane-StoryHold-YouAreNotYourselfRightNow");
  }
  return "";
}

// The gameplay restrictions that mean the story has V.
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

// Does V carry any of these tags from something the story put on V? The same tags the game reads,
// looked at effect by effect, so that the ones V brings on V's own are not taken for the story.
public func CBHasStoryTag(game: GameInstance, player: ref<GameObject>, tags: array<CName>) -> Bool {
  if !IsDefined(player) {
    return false;
  }
  let ses = GameInstance.GetStatusEffectSystem(game);
  if !IsDefined(ses) {
    return false;
  }
  let id = player.GetEntityID();
  for tag in tags {
    // The cheap test first: almost always nothing carries the tag at all.
    if StatusEffectSystem.ObjectHasStatusEffectWithTag(player, tag) {
      let effects: array<ref<StatusEffect>>;
      ses.GetAppliedEffectsWithTag(id, tag, effects);
      for e in effects {
        if IsDefined(e) && !CBEffectIsVsOwn(e.GetRecord()) {
          return true;
        }
      }
    }
  }
  return false;
}

// An effect the game puts on V for something V is doing, not something the story is doing to V.
public func CBEffectIsVsOwn(rec: ref<StatusEffect_Record>) -> Bool {
  if !IsDefined(rec) {
    return false;
  }
  let kind = rec.StatusEffectType();
  if IsDefined(kind) && Equals(kind.Type(), gamedataStatusEffectType.Berserk) {
    return true;
  }
  if rec.GetID() == t"BaseStatusEffect.PlayerInFinisherWorkspot" {
    return true;
  }
  return rec.GameplayTagsContains(n"BodyCarryingGeneric")
      || rec.GameplayTagsContains(n"BodyCarryingCanSprint")
      || rec.GameplayTagsContains(n"BodyCarryingBodyMasterPerk5");
}

// Is the player V, in V's own world?
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

public func CBInPreGame() -> Bool {
  let handler = GameInstance.GetSystemRequestsHandler();
  return IsDefined(handler) && handler.IsPreGame();
}

// Has the story taken control of what V can do? As of this instant; see CBStoryRestrictionTags
// for why the system only acts on this once it has held for a few ticks.
public func CBPlayerStoryRestricted(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  if CBHasStoryTag(game, player, CBStoryRestrictionTags()) {
    return true;
  }
  // In a car the weapon limits are the car's, not the story's.
  if VehicleComponent.IsMountedToVehicle(game, player) {
    return false;
  }
  return CBHasStoryTag(game, player, CBStoryWeaponTags());
}

// Somebody the story placed is walking with V.
public func CBStoryCompanionWithV(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let player = GetPlayer(game);
  let reg = sys.GetRegistry();
  if !IsDefined(player) || !IsDefined(reg) {
    return false;
  }
  // Every few ticks, not every tick. This walks the whole registry - two hundred people on a busy street - reading each
  // one's position, every second.
  let found = false;
  if sys.TakeCompanionScan(CBConfig.StoryCompanionScanTicks(), found) {
    return found;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  let ppos = player.GetWorldPosition();
  let reach = CBConfig.StoryCompanionRadius();
  for p in reg.GetAll() {
    if !found && CBNpcSafe(sys, p) && !p.IsDead()
       && Vector4.Distance(p.GetWorldPosition(), ppos) <= reach
       && p.IsPlayerCompanion() && CBIsStoryCompanion(p, des) {
      found = true;
    }
  }
  sys.NoteCompanionScan(found);
  return found;
}

// Whose companion is this: the story's, or one somebody chose?
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

// The whole question, in order of how much it settles.
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

// Asked at the moment of placing somebody, which can be between ticks: the live answer for everything that is cheap to
// read, and the last tick's answer for the companion pass.
public func CBStoryHoldNow(game: GameInstance) -> Bool {
  if !CBGameHasVHere(game) || CBPlayerInScene(game) || CBPlayerStoryRestricted(game) {
    return true;
  }
  let sys = CyberbaneSystem.Get(game);
  return IsDefined(sys) && sys.GetStoryHold() != CBStoryNone();
}

// The story has the stage: call back anybody of ours who has not reached V.
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
              + CBStoryRemoveUnseen(game, des, n"CB_Lair")
              // A crew lying in wait for V (Spawn/HuntGrows.reds) is a crew sent after V like the rest.
              + CBStoryRemoveUnseen(game, des, n"CB_Ambush")
              // So is one of V's own crew who turned on V (Reactions/Crew.reds): hostile to V like a hunter.
              + CBStoryRemoveUnseen(game, des, n"CB_Turned")
              // And a stronghold's garrison (Rivals/Strongholds.reds); the stronghold stays.
              + CBStoryRemoveUnseen(game, des, n"CB_Hold");
  if removed > 0 {
    CBLog.Info(n"Spawn", s"The story has the stage (\(CBStoryLabel(sys.GetStoryHold()))): called back \(removed) of ours who had not reached you.");
  }
  let anyLeft = CBLiveTaggedPresent(game, n"CB_Rival") || CBLiveTaggedPresent(game, n"CB_Squad")
             || CBLiveTaggedPresent(game, n"CB_Apex") || CBLiveTaggedPresent(game, n"CB_Escort")
             || CBLiveTaggedPresent(game, n"CB_Scout");
  if !anyLeft && sys.GetHuntState() != CBHuntNone() {
    // A ride (the metro, a cab, a seat the story gives V) took V away from them: the street says so ([42]).
    if removed > 0 && sys.GetStoryHold() == CBStoryRestricted() && CBToastsOn() {
      CBHearsayFromStreet(game, CBT(n"Cyberbane-StoryHold-WhoeverWasAfterYouLostYou"), n"");
    }
    CBStoryResetHunt(sys);
  }
}

// Remove everybody wearing this tag whom V cannot see, and nobody else.
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
  // So is everyone who came with them.
  for pid in sys.GetPackRivals() {
    let partner = sys.FindRivalById(pid);
    if IsDefined(partner) {
      partner.huntTicks = Max(partner.huntTicks, CBConfig.RivalHuntRetryTicks());
    }
  }
  sys.ClearPack();
  sys.ClearScout();
  sys.ClearApexMuster();   // nobody of theirs keeps walking in while the story has the stage
  sys.SetHuntState(CBHuntNone());
  sys.SetHuntFaction(n"");
  sys.SetHuntGrade("");
  sys.SetActiveRivalId(0);
  sys.SetActiveSquadFaction(n"");
  sys.GetThreatBar().Hide();
}
