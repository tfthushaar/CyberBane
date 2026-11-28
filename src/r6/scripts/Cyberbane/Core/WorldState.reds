// Cyberbane - Runtime world-state gate (crash safety)
//
// CyberBane's runtime (the fast tick and the Entity/Attached callback) drives native world queries every tick: NPC
// world positions, attitude agents, the workspot system, dynamic NPC spawns and traffic.

// Registered-at tick for each NPC, so freshly-streamed-in NPCs are left alone until their
// components are ready. 0 (the default) reads as "long ago" for anything we never registered.
@addField(ScriptedPuppet)
public let cbSeenTick: Int32;

// Does a callback waiting for a settled world count this wait towards giving up? Only while the world is really going
// away: no player (a load or a fast travel), no blackboards, or V down (a load or a death alternative is coming).
public func CBWaitCounts(game: GameInstance) -> Bool {
  return !IsDefined(GetPlayer(game)) || CBVDown(game) || !IsDefined(GameInstance.GetBlackboardSystem(game));
}

public func CBWorldStable(game: GameInstance) -> Bool {
  // No controllable player means a teleport / load / fast travel is in flight.
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  // V is down. What comes next is a load, or a death alternative standing V back up, and until one of them does, the
  // world in front of us is about to be thrown away.
  if CBVDown(game) {
    return false;
  }
  // Paused: nothing should tick.
  let ts = GameInstance.GetTimeSystem(game);
  if IsDefined(ts) && ts.IsPausedState() {
    return false;
  }
  // Photo mode.
  let pms = GameInstance.GetPhotoModeSystem(game);
  if IsDefined(pms) && pms.IsPhotoModeActive() {
    return false;
  }
  // The blackboard system itself is gone mid-transition, and dereferencing it then is the
  // very thing this gate exists to prevent. No blackboards means "not stable".
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  // A blocking menu or loading screen is up: the Skip Time menu, or the fast-travel load
  // screen. Both pause normal gameplay and overlap the streaming flood.
  let ui = bbs.Get(GetAllBlackboardDefs().UI_System);
  if IsDefined(ui) && ui.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) {
    return false;
  }
  // The player is in a workspot / scripted scene - most importantly a ripperdoc cyberware
  // install, which also advances time behind a fade. Stand down rather than query a world
  // that is mid-transition.
  let ws = GameInstance.GetWorkspotSystem(game);
  if IsDefined(ws) && ws.IsActorInWorkspot(player) {
    return false;
  }
  // The player is in a staged / limited / cinematic scene - a holocall, a conversation, a cutscene. These overlap heavy
  // streaming and leave world state in flux, so stand down.
  let psm = CBPlayerPSM(game);
  if IsDefined(psm) {
    // SceneTier carries a GameplayTier, not a gamePSMHighLevel.
    let tier = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.SceneTier);
    if tier != EnumInt(GameplayTier.Undefined) && tier != EnumInt(GameplayTier.Tier1_FullGameplay) {
      return false;
    }
  }
  return true;
}

// Which of CBWorldStable's tests failed, in a few words, "" when none did. Every failure used to be logged and told as
// "the world is loading, paused or in photo mode", including a grapple, a workspot, a scene and any open menu.
public func CBWorldStableWhy(game: GameInstance) -> String {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return CBT(n"Cyberbane-WorldState-TheWorldIsStillLoading");
  }
  if CBVDown(game) {
    return CBT(n"Cyberbane-WorldState-YouReDown");
  }
  let ts = GameInstance.GetTimeSystem(game);
  if IsDefined(ts) && ts.IsPausedState() {
    return CBT(n"Cyberbane-WorldState-TheGameIsPaused");
  }
  let pms = GameInstance.GetPhotoModeSystem(game);
  if IsDefined(pms) && pms.IsPhotoModeActive() {
    return CBT(n"Cyberbane-WorldState-YouReInPhotoMode");
  }
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return CBT(n"Cyberbane-WorldState-TheWorldIsStillLoading");
  }
  let ui = bbs.Get(GetAllBlackboardDefs().UI_System);
  if IsDefined(ui) && ui.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) {
    return CBT(n"Cyberbane-WorldState-AMenuIsOpen");
  }
  let ws = GameInstance.GetWorkspotSystem(game);
  if IsDefined(ws) && ws.IsActorInWorkspot(player) {
    return CBT(n"Cyberbane-WorldState-YouReBusyWithSomethingSitting");
  }
  let psm = CBPlayerPSM(game);
  if IsDefined(psm) {
    let tier = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.SceneTier);
    if tier != EnumInt(GameplayTier.Undefined) && tier != EnumInt(GameplayTier.Tier1_FullGameplay) {
      return CBT(n"Cyberbane-WorldState-YouReInTheMiddleOf");
    }
  }
  return "";
}

// Is the player standing in a zone the game itself treats as safe?
public func CBPlayerInSafeZone(game: GameInstance) -> Bool {
  // Ask the system that owns safe areas whether the point V is standing on is one.
  if CBPlayerNoCombatTag(game) {
    return true;
  }
  // The zone the game put V in, as it set it: a zone the story made safe is one the point test below does not know.
  if CBPlayerZoneSafe(game) {
    return true;
  }
  let sam = GameInstance.GetSafeAreaManager(game);
  let player = GetPlayer(game);
  if IsDefined(sam) && IsDefined(player) {
    return sam.IsPointInSafeArea(player.GetWorldPosition());
  }

  // The manager is not up yet (a load, or early streaming). Fall back to the old zone read,
  // and fail open rather than closed: someone flinching in a bar is a cosmetic mistake, the
  // whole mod doing nothing is not.
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let psm = CBPlayerPSM(game);
  if !IsDefined(psm) {
    return false;
  }
  let zone = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Zones);
  return zone == EnumInt(gamePSMZones.Safe);
}

// True only when this NPC is safe to read native state from. Guards every per-NPC query so the
// runtime never touches a streaming-out (detaching) or freshly-streamed-in (not-yet-ready) NPC.
// Is this one still a participant?
public func CBStillStanding(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) || !p.IsAttached() || p.IsDead() {
    return false;
  }
  return !ScriptedPuppet.IsDefeated(p) && !p.IsIncapacitated();
}

// Is this somebody put down: dead, or defeated or out cold where they lie?
public func CBIsDown(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) {
    return false;
  }
  if p.IsDead() {
    return true;
  }
  return p.IsAttached() && (ScriptedPuppet.IsDefeated(p) || p.IsIncapacitated());
}

// Is this NPC in combat? NPCs have no IsInCombat of their own (that is the player's); the game
// reads their high-level AI state off the puppet blackboard (NPCPuppet.IsInCombat).
public func CBNpcInCombat(npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) || !npc.IsAttached() {
    return false;
  }
  return NPCPuppet.IsInCombat(npc);
}

// Their health in percent, 100 when it cannot be read. Only of somebody in the world.
public func CBHealthPercent(game: GameInstance, npc: wref<ScriptedPuppet>) -> Float {
  if !IsDefined(npc) || !npc.IsAttached() {
    return 100.0;
  }
  let sps = GameInstance.GetStatPoolsSystem(game);
  return IsDefined(sps) ? sps.GetStatPoolValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health, true) : 100.0;
}

public func CBNpcSafe(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) || !npc.IsAttached() {
    return false;
  }
  if !IsDefined(sys) {
    return true;
  }
  return (sys.GetTickCount() - npc.cbSeenTick) >= CBConfig.NpcReadyTicks();
}

// The player's own state-machine blackboard.
public func CBPlayerPSM(game: GameInstance) -> ref<IBlackboard> {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return null;
  }
  return player.GetPlayerStateMachineBlackboard();
}

// V is dead, or being brought back.
public func CBVDown(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  if player.cbRebirthPending {
    return true;
  }
  let psm = player.GetPlayerStateMachineBlackboard();
  if !IsDefined(psm) {
    return false;
  }
  let v = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vitals);
  return v == EnumInt(gamePSMVitals.Dead) || v == EnumInt(gamePSMVitals.Resurrecting);
}
