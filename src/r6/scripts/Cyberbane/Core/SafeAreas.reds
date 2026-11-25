// Cyberbane - Safe areas (spec §16)
//
// Night City marks apartments, clinics, bars and memorials as safe areas, and that marking does two separate things.
// The first is the zone itself: the SAFE AREA label, the minimap tint, and who reacts to what.

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
public func CBBlockStory() -> Int32 = 11
public func CBBlockHomeGround() -> Int32 = 12
public func CBBlockTalking() -> Int32 = 13
public func CBBlockNoPath() -> Int32 = 14
public func CBBlockCount() -> Int32 = 15

// Every refusal is counted for the placement under way, so the log and the Hub name the reason that refused the most
// spots, never only the last one tried: the last-resort spot used to write "out of your sight" whatever stopped it, 237
// times, which hid a conversation's lock and the safe areas behind one wrong word.
public func CBNoteSpawnBlock(reason: Int32) -> Void {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    rt.SetLastSpawnBlock(reason);
  }
}

// The starting guess of a placement, which is not a refusal of any spot.
public func CBAssumeSpawnBlock(reason: Int32) -> Void {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    rt.AssumeSpawnBlock(reason);
  }
}

// Short, plain description for the Hub.
public func CBBlockLabel(reason: Int32) -> String {
  if reason == CBBlockWorldBusy() {
    return CBT(n"Cyberbane-SafeAreas-WorldStillLoading");
  }
  if reason == CBBlockCannotFight() {
    return CBT(n"Cyberbane-SafeAreas-YouCannotDrawHere");
  }
  if reason == CBBlockQuestArea() {
    return CBT(n"Cyberbane-SafeAreas-YouAreOnAJob");
  }
  if reason == CBBlockProtectedZone() {
    return CBT(n"Cyberbane-SafeAreas-ProtectedArea");
  }
  if reason == CBBlockSafeArea() {
    return CBT(n"Cyberbane-SafeAreas-SafeArea");
  }
  if reason == CBBlockNoGround() {
    return CBT(n"Cyberbane-SafeAreas-NoGroundToStandOn");
  }
  if reason == CBBlockEngineRefused() {
    return CBT(n"Cyberbane-SafeAreas-TheGameRefusedTheSpawn");
  }
  if reason == CBBlockNoRecord() {
    return CBT(n"Cyberbane-SafeAreas-NoGangMemberOnFile");
  }
  if reason == CBBlockInView() {
    return CBT(n"Cyberbane-SafeAreas-NowhereOutOfYourSight");
  }
  if reason == CBBlockHostileArea() {
    return CBT(n"Cyberbane-SafeAreas-YouAreInsideSomebodyElseS");
  }
  if reason == CBBlockStory() {
    return CBT(n"Cyberbane-SafeAreas-TheStoryHasTheStage");
  }
  if reason == CBBlockHomeGround() {
    return CBT(n"Cyberbane-Held-HomeGround");
  }
  if reason == CBBlockTalking() {
    return CBT(n"Cyberbane-SafeAreas-YouAreTalking");
  }
  if reason == CBBlockNoPath() {
    return CBT(n"Cyberbane-SafeAreas-NoWayToYou");
  }
  return "";
}

// Has the player opted into being hunted inside safe areas?
public func CBAllowSafeZoneSpawns() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().allowSafeZoneSpawns;
}

// Can V actually fight where they are standing?
public func CBPlayerCannotFight(game: GameInstance) -> Bool {
  if CBPlayerNoCombatTag(game) {
    return true;
  }
  // A conversation's own lock is not a place where V cannot fight.
  if CBTalkHandLockOnly(game) {
    return false;
  }
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let psm = CBPlayerPSM(game);
  if !IsDefined(psm) {
    return false;
  }
  let upper = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody);
  // An unread or freshly reset blackboard int is 0.
  let emptyHands = EnumInt(gamePSMUpperBodyStates.ForceEmptyHands);
  if emptyHands == EnumInt(gamePSMUpperBodyStates.Default) {
    return false;
  }
  return upper == emptyHands;
}

// Is V's empty-hands lock only street talk's own? True while a conversation holds V's hands outside any game safe area.
// The one question for telling the talk's lock apart from the place's or the story's.
public func CBTalkHandLockOnly(game: GameInstance) -> Bool {
  if !CBTalkHoldsHandsNow(game) {
    return false;
  }
  return !CBPlayerInGameSafeArea(game);
}

public func CBTalkHoldsHandsNow(game: GameInstance) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return false;
  }
  let talk = sys.GetStreetTalk();
  return IsDefined(talk) && talk.HoldsHands();
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
public func CBPlayerInQuestArea(game: GameInstance) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  return IsDefined(sys) && sys.IsInQuestArea();
}

// What "Stay out of quest areas" means, worked out every few ticks (CyberbaneSystem fast tick).
public func CBComputeQuestArea(game: GameInstance) -> Bool {
  let rtQ = CyberbaneRuntime.Get();
  if IsDefined(rtQ) && rtQ.HasSettings() && !rtQ.GetSettings().respectQuestAreas {
    return false;
  }
  if CBPlayerInScene(game) || CBPlayerInHostileZone(game) {
    return true;
  }
  // The tracked objective's pins only. Every other active objective is IsOnJob (CBComputeOnJob),
  // which holds arrivals and hunters; this one also stills the street (Reactions/Director.reds).
  let sys = CyberbaneSystem.Get(game);
  let player = GetPlayer(game);
  return IsDefined(sys) && IsDefined(player)
      && sys.NearTrackedPins(player.GetWorldPosition(), CBQuestAreaRadius());
}

// V at the job V is tracking, as "Stay out of quest areas" reads it: its own pins only, and not the gangs' ground,
// which CBComputeQuestArea also counts.
public func CBAtTrackedJob(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  let rtQ = CyberbaneRuntime.Get();
  if IsDefined(rtQ) && rtQ.HasSettings() && !rtQ.GetSettings().respectQuestAreas {
    return false;
  }
  let player = GetPlayer(game);
  return IsDefined(sys) && IsDefined(player) && sys.NearTrackedPins(player.GetWorldPosition(), CBQuestAreaRadius());
}

// The player's chosen size of a quest area, in metres.
public func CBQuestAreaRadius() -> Float {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return CBConfig.QuestAreaRadius();
  }
  return ClampF(Cast<Float>(rt.GetSettings().questAreaRadius), 40.0, 150.0);
}

// The tracked objective's map pins, read the way the game's world map reads them
// (MappinSystem.GetQuestMappinPositionsByObjective, worldMap.script), and kept on the system so every check that needs
// them (V's position, spawn points, NPCs, search points) uses one copy.
public func CBRefreshQuestPins(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let pins: array<Vector4>;
  let trackedPins: array<Vector4>;
  let rtQ = CyberbaneRuntime.Get();
  let respect = !IsDefined(rtQ) || !rtQ.HasSettings() || rtQ.GetSettings().respectQuestAreas;
  let journal = GameInstance.GetJournalManager(game);
  let ms = GameInstance.GetMappinSystem(game);
  if IsDefined(sys) && respect && IsDefined(journal) && IsDefined(ms) {
    let tracked = journal.GetTrackedEntry() as JournalQuestObjectiveBase;
    if IsDefined(tracked) {
      let positions: array<Vector3>;
      if ms.GetQuestMappinPositionsByObjective(Cast<Uint32>(journal.GetEntryHash(tracked)), positions) {
        for p in positions {
          ArrayPush(pins, Vector4.Vector3To4(p));
          ArrayPush(trackedPins, Vector4.Vector3To4(p));
        }
      }
    }
    // And every other active objective's, gathered less often (CBRefreshJobPins). The tracked one alone left a gig V
    // was doing without tracking it - "Rite of Passage" - open to a Valentino walking in on it.
    for jp in sys.GetJobPins() {
      ArrayPush(pins, jp);
    }
  }
  if IsDefined(sys) {
    sys.SetQuestPins(pins);
    sys.SetTrackedPins(trackedPins);
  }
}

// The pins of every active quest and gig objective: active quests, their active phases, their active objectives, and
// where each objective's pins are. Read-only journal and mappin calls, both on 2.31 and 2.5.
public func CBRefreshJobPins(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let pins: array<Vector4>;
  let rtQ = CyberbaneRuntime.Get();
  let respect = !IsDefined(rtQ) || !rtQ.HasSettings() || rtQ.GetSettings().respectQuestAreas;
  let journal = GameInstance.GetJournalManager(game);
  let ms = GameInstance.GetMappinSystem(game);
  if IsDefined(sys) && respect && IsDefined(journal) && IsDefined(ms) {
    let ctx: JournalRequestContext;
    ctx.stateFilter.active = true;
    let quests: array<wref<JournalEntry>>;
    journal.GetQuests(ctx, quests);
    for q in quests {
      let phases: array<wref<JournalEntry>>;
      journal.GetChildren(q, ctx.stateFilter, phases);
      for ph in phases {
        let objectives: array<wref<JournalEntry>>;
        journal.GetChildren(ph, ctx.stateFilter, objectives);
        for o in objectives {
          if IsDefined(o as JournalQuestObjectiveBase) && ArraySize(pins) < CBConfig.JobPinCap() {
            let positions: array<Vector3>;
            if ms.GetQuestMappinPositionsByObjective(Cast<Uint32>(journal.GetEntryHash(o)), positions) {
              for p in positions {
                if ArraySize(pins) < CBConfig.JobPinCap() {
                  ArrayPush(pins, Vector4.Vector3To4(p));
                }
              }
            }
          }
        }
      }
    }
  }
  if IsDefined(sys) {
    sys.SetJobPins(pins);
  }
}

// On a job: in a scene, or near one of the pins above. The quest area without its hostile zones: a gang's territory is
// not a job, and a fight that moves into one carries on as it always has.
public func CBComputeOnJob(game: GameInstance) -> Bool {
  let rtQ = CyberbaneRuntime.Get();
  if IsDefined(rtQ) && rtQ.HasSettings() && !rtQ.GetSettings().respectQuestAreas {
    return false;
  }
  if CBPlayerInScene(game) {
    return true;
  }
  let sys = CyberbaneSystem.Get(game);
  let player = GetPlayer(game);
  return IsDefined(sys) && IsDefined(player)
      && sys.NearQuestPins(player.GetWorldPosition(), CBQuestAreaRadius());
}

// Can anybody arrive right now? Not in a safe area (unless allowed), not on a job, not in a scene, and never while the
// story has the stage (Core/StoryHold.reds).
public func CBWordsHeld(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  return !IsDefined(sys) || sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game) || sys.IsInSanctuary();
}

public func CBArrivalsHeld(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return true;
  }
  // Home ground under Quiet, and the quiet a night at home bought (Spawn/HomeGround.reds): the lanes, bounty hunters
  // and street fights wait. V's own crew does not ask this (CBArrivalsHeldBase): a spar at home is V's choice.
  return CBArrivalsHeldBase(sys, game) || CBHomeHoldsAll(sys) || CBSleepPeace(game);
}

// The holds that keep any fight from starting, Cyberbane's people or V's own (a spar): the story, a scene, a job, somewhere
// safe, the police, another mod's event.
public func CBArrivalsHeldBase(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return true;
  }
  return sys.IsInSanctuary() || sys.IsInQuestArea() || sys.IsOnJob() || CBPlayerInScene(game)
      || sys.GetStoryHold() != CBStoryNone() || CBPoliceOnV(sys) || CBSmasherEventOn(game) || CBMbcContractFight(game)
      || CBFenixCaptured(game);   // Fenix Rebirth's capture (Compat/FenixRebirth.reds)
}

// The NCPD after V: any wanted level. The gangs lie low while the cops swarm.
public func CBPoliceOnV(sys: ref<CyberbaneSystem>) -> Bool {
  let score = IsDefined(sys) ? sys.GetScore() : null;
  return IsDefined(score) && score.GetHeatStage() > 0;
}

// Why, in a few words, or "" when nothing is held. The same questions as above, so the Hub can never
// show a countdown standing still without saying what it is waiting for.
public func CBArrivalsHeldWhy(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  if !IsDefined(sys) {
    return "";
  }
  if sys.GetStoryHold() != CBStoryNone() {
    return CBT(n"Cyberbane-SafeAreas-TheStoryHasTheStage");
  }
  if sys.IsInSanctuary() {
    return CBT(n"Cyberbane-SafeAreas-YouAreSomewhereSafe");
  }
  if CBPlayerInScene(game) {
    return CBT(n"Cyberbane-SafeAreas-YouAreInAScene");
  }
  if sys.IsOnJob() {
    return CBT(n"Cyberbane-SafeAreas-YouAreOnAJob");
  }
  if sys.IsInQuestArea() {
    return CBPlayerInHostileZone(game) ? CBT(n"Cyberbane-SafeAreas-YouAreOnSomebodyElseS") : CBT(n"Cyberbane-SafeAreas-YouAreOnAJob");
  }
  if CBPoliceOnV(sys) {
    return CBT(n"Cyberbane-SafeAreas-TheNCPDAreAfterYou");
  }
  if CBSmasherEventOn(game) {
    return CBSmasherHeldWhy();
  }
  if CBMbcContractFight(game) {
    return CBT(n"Cyberbane-Compat-AContractSFight");
  }
  if CBFenixCaptured(game) {
    return CBT(n"Cyberbane-Compat-FenixCaptured");
  }
  if CBHomeHoldsAll(sys) {
    return CBT(n"Cyberbane-Held-HomeGround");
  }
  if CBSleepPeace(game) {
    let book = CBHomeBook.Get(game);
    let left = IsDefined(book) ? MaxF(0.0, book.PeaceUntil() - CBGameSeconds(game)) / CBConfig.SecondsPerHour() : 0.0;
    return CBTf(n"Cyberbane-Held-SleepPeace", [CBHudRealFromGameHours(left)]);
  }
  return "";
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
public func CBPlayerInDangerZone(game: GameInstance) -> Bool {
  return CBPlayerZone(game) == EnumInt(gamePSMZones.Dangerous);
}

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
  let psm = CBPlayerPSM(game);
  if !IsDefined(psm) {
    return EnumInt(gamePSMZones.Default);
  }
  return psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Zones);
}

// Short label for the Hub, so a held arrival explains itself.
public func CBPlayerZoneLabel(game: GameInstance) -> String {
  let zone = CBPlayerZone(game);
  if zone == EnumInt(gamePSMZones.Safe) {
    return CBT(n"Cyberbane-SafeAreas-SafeArea");
  }
  if zone == EnumInt(gamePSMZones.Restricted) {
    return CBT(n"Cyberbane-SafeAreas-RestrictedArea");
  }
  if zone == EnumInt(gamePSMZones.Dangerous) {
    return CBT(n"Cyberbane-SafeAreas-DangerousArea");
  }
  if zone == EnumInt(gamePSMZones.Public) {
    return CBT(n"Cyberbane-SafeAreas-OpenCity");
  }
  return "";
}

// It was tracking the right thing through the wrong door. `ESecurityAreaType` does not expose its members to redscript
// by name, so the test compared ordinals, and the guess about which low ordinals meant "protected" was wrong: the open
// street reports a low one too.

// Should Cyberbane refuse to put anyone down here?
public func CBSafeAreaBlocksSpawn(game: GameInstance, at: Vector4, opt onVsSide: Bool) -> Bool {
  // 1. The story has the stage: V is not V, a scene is playing, the story is directing what V
  //    can do, or somebody from the story is walking with V. No setting opens this up.
  if CBStoryHoldNow(game) {
    CBNoteSpawnBlock(CBBlockStory());
    return true;
  }
  let sysQ = CyberbaneSystem.Get(game);
  let optIn = CBAllowSafeZoneSpawns();
  // 2. V's hands forced empty. Inside a safe area with the opt-in, that is the zone's own weapon
  //    lock, which the player asked to fight through (and can lift with the setting beside it).
  //    Anywhere else it is the story's, and it holds whatever the settings say.
  let inSafe = IsDefined(sysQ) && sysQ.IsInSafeZone();
  if CBPlayerCannotFight(game) && !(optIn && inSafe) {
    CBNoteSpawnBlock(CBBlockCannotFight());
    return true;
  }
  // Mid-conversation: people sent against V wait for the talk to end, as they always did; somebody V asked for in the
  // conversation (lent gangers, V's crew) comes now.
  if !onVsSide && CBTalkHoldsHandsNow(game) {
    CBNoteSpawnBlock(CBBlockTalking());
    return true;
  }
  // 3. On a job, or in a restricted or dangerous zone, when V asked Cyberbane to stay out of them -
  //    the quest-area switch's own question, which the safe-area opt-in has nothing to do with.
  if !onVsSide && (CBPlayerInQuestArea(game) || (IsDefined(sysQ) && sysQ.IsOnJob())) {
    // The quest area also holds restricted and dangerous zones; the Hub names which it was, as
    // CBArrivalsHeldWhy does, instead of calling a gang's compound a job.
    let onJob = (IsDefined(sysQ) && sysQ.IsOnJob()) || CBPlayerInScene(game)
        || (IsDefined(sysQ) && IsDefined(GetPlayer(game))
            && sysQ.NearTrackedPins(GetPlayer(game).GetWorldPosition(), CBQuestAreaRadius()));
    CBNoteSpawnBlock((!onJob && CBPlayerInHostileZone(game)) ? CBBlockHostileArea() : CBBlockQuestArea());
    return true;
  }
  // And never placed at the job itself, wherever V is standing. Checking only V's position let a
  // crew be placed inside the job area while V stood just outside it.
  if !onVsSide && IsDefined(sysQ) && sysQ.NearQuestPins(at, CBConfig.QuestSpawnClearance()) {
    CBNoteSpawnBlock(CBBlockQuestArea());
    return true;
  }
  // Home ground under Quiet (Spawn/HomeGround.reds): the building round V's apartment, whatever the safe-area settings
  // say, for anybody against V. V's own crew and people lent to V come there as anywhere.
  if !onVsSide && CBHomePointQuiet(game, at) {
    CBNoteSpawnBlock(CBBlockHomeGround());
    return true;
  }
  // 4. Safe areas, and the places the game keeps free of police. This is all the opt-in opens.
  if optIn {
    return false;   // the player has asked for this fight
  }
  // The game's no-spawn areas, which is how the NCPD know not to materialise inside a megabuilding lobby.
  let pss = GameInstance.GetPreventionSpawnSystem(game);
  if IsDefined(pss) && pss.IsPointInPreventionFreeArea(at) {
    CBNoteSpawnBlock(CBBlockProtectedZone());
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
public func CBPlayerNoCombatTag(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  return StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"NoCombat");
}

// Undo the disarm the game applies on entering a safe area, when the player has asked for it.
@wrapMethod(PlayerPuppet)
private final func OnEnterSafeZone() -> Void {
  wrappedMethod();
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() || !rt.HasSettings() || !rt.GetSettings().allowSafeZoneCombat {
    return;
  }
  // The same rules as the tick that keeps it lifted (CBSafeZoneArmsTick): never in a scene, never under an open
  // talk prompt, and recorded as ours so that tick puts the lock back if the setting is turned off inside.
  let game = this.GetGame();
  let sys = CyberbaneSystem.Get(game);
  if CBPlayerInScene(game) {
    return;
  }
  if IsDefined(sys) {
    let talk = sys.GetStreetTalk();
    if IsDefined(talk) && talk.HoldsHands() {
      return;
    }
    sys.SetSafeArmsApplied(true);
  }
  CBQueueZoneArmsLock(this, false);
}

// Keep the safe-area weapon lock lifted for as long as V is in a safe area with the setting on.
public func CBSafeZoneArmsTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  let setting = IsDefined(rt) && rt.IsEnabled() && rt.HasSettings() && rt.GetSettings().allowSafeZoneCombat;
  // The place only, asked only when it matters (CBPlayerInGameSafeArea).
  let inArea = (setting || sys.IsSafeArmsApplied()) && CBPlayerInGameSafeArea(game);
  let want = setting && inArea && !CBPlayerInScene(game);
  if want {
    // Not while street talk is holding V's hands: talk now works in safe areas, and lifting the lock under an open
    // prompt would let the wheel draw a gun instead of picking a line.
    let talk = sys.GetStreetTalk();
    if IsDefined(talk) && talk.HoldsHands() {
      return;
    }
    if !sys.IsSafeArmsApplied() || sys.GetTickCount() % 4 == 0 {
      CBQueueZoneArmsLock(player, false);
      sys.SetSafeArmsApplied(true);
    }
    return;
  }
  if sys.IsSafeArmsApplied() {
    // Lifted by us and no longer wanted: put the game's lock back if V is still inside.
    if inArea {
      CBQueueZoneArmsLock(player, true);
    }
    sys.SetSafeArmsApplied(false);
  }
}

// Is V in a safe area the game itself locks V's hands in: the place, not a NoCombat tag a scene has put on V.
public func CBPlayerInGameSafeArea(game: GameInstance) -> Bool {
  let sam = GameInstance.GetSafeAreaManager(game);
  let player = GetPlayer(game);
  if IsDefined(sam) && IsDefined(player) {
    return sam.IsPointInSafeArea(player.GetWorldPosition());
  }
  return CBPlayerZone(game) == EnumInt(gamePSMZones.Safe);
}

func CBQueueZoneArmsLock(player: ref<PlayerPuppet>, locked: Bool) -> Void {
  let evt = new PSMPostponedParameterBool();
  evt.id = n"ForceEmptyHandsByZone";
  evt.value = locked;
  evt.aspect = gamestateMachineParameterAspect.Permanent;
  player.QueueEvent(evt);
}
