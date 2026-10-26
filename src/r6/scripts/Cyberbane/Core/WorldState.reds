// Cyberbane - Runtime world-state gate (crash safety)
//
// CyberBane's runtime (the fast tick and the Entity/Attached callback) drives native world
// queries every tick: NPC world positions, attitude agents, the workspot system, dynamic NPC
// spawns and traffic. While the engine is streaming the world in or out - a fast travel, a time
// skip, a ripperdoc install, a load, or just walking through a dense district or a scene - those
// entities are half-built (streaming in) or being torn down (streaming out), and querying them
// dereferences a not-ready or freed native object and crashes the game (seen as a dynamicBuffer
// assert and as an access violation reading 0xFFFFFFFFFFFFFFFF in DelaySystem/Tick).
//
// Two guards handle every case:
//   CBWorldStable - a coarse gate: false during loads / fast travel / menus / scenes, so the
//     whole tick stands down (paired with a settle window for the streaming flood that follows).
//   CBNpcSafe     - a fine gate used at every per-NPC query: an NPC is touched only when it is
//     currently attached AND has had a few ticks to initialize after attaching. This holds no
//     matter what caused the streaming, including ambient streaming during normal gameplay.
//
// All calls here are confirmed to resolve against the live game on the target patch.

// Registered-at tick for each NPC, so freshly-streamed-in NPCs are left alone until their
// components are ready. 0 (the default) reads as "long ago" for anything we never registered.
@addField(ScriptedPuppet)
public let cbSeenTick: Int32;

public func CBWorldStable(game: GameInstance) -> Bool {
  // No controllable player means a teleport / load / fast travel is in flight.
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return false;
  }
  // Paused - pause menu, photo mode: nothing should tick.
  let ts = GameInstance.GetTimeSystem(game);
  if IsDefined(ts) && ts.IsPausedState() {
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
  // The player is in a staged / limited / cinematic scene - a holocall, a conversation, a
  // cutscene. These overlap heavy streaming and leave world state in flux, so stand down.
  // Only Default and full-gameplay (SceneTier1) are treated as safe.
  let psm = bbs.Get(GetAllBlackboardDefs().PlayerStateMachine);
  if IsDefined(psm) {
    let tier = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.SceneTier);
    if tier != EnumInt(gamePSMHighLevel.Default) && tier != EnumInt(gamePSMHighLevel.SceneTier1) {
      return false;
    }
  }
  return true;
}

// True only when this NPC is safe to read native state from. Guards every per-NPC query so the
// runtime never touches a streaming-out (detaching) or freshly-streamed-in (not-yet-ready) NPC.
public func CBNpcSafe(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) || !npc.IsAttached() {
    return false;
  }
  if !IsDefined(sys) {
    return true;
  }
  return (sys.GetTickCount() - npc.cbSeenTick) >= CBConfig.NpcReadyTicks();
}
