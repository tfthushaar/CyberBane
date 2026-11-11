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
  // V is down. What comes next is a load, or a death alternative standing V back up, and until one of
  // them does, the world in front of us is about to be thrown away. This gate missed it: for the
  // seconds between V dying and the death screen, cars were still sent at V's body, crews ordered out
  // of them and lanes left free to send more, into a world the load was about to tear down.
  if CBVDown(game) {
    return false;
  }
  // Paused: nothing should tick.
  let ts = GameInstance.GetTimeSystem(game);
  if IsDefined(ts) && ts.IsPausedState() {
    return false;
  }
  // Photo mode. This comment used to say the pause test above covered it, and it never did: the
  // game freezes the world for photo mode with a time dilation of its own (PlayerStateMachine
  // .TimeDilation is Photomode) and never sets the paused state, whose setter is test-only. So the
  // fast tick, which ignores time dilation, went on working a frozen world through every photo,
  // and outside a safe area the crowd reactions took the photo mode's posed copy of V for a passer-by
  // and gave it a worried look at V: the head that turned on its own ten or twenty seconds in. The
  // game's own question, the one GameObject.IsPhotoModeBlocked asks, on both patches.
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
  // The player is in a staged / limited / cinematic scene - a holocall, a conversation, a
  // cutscene. These overlap heavy streaming and leave world state in flux, so stand down.
  // Only Default and full-gameplay (SceneTier1) are treated as safe.
  let psm = CBPlayerPSM(game);
  if IsDefined(psm) {
    // SceneTier carries a GameplayTier, not a gamePSMHighLevel. The two happen to share their
    // first two ordinals, which is why the old comparison read correctly; it is written against
    // the right enum now that it is actually being read (see CBPlayerPSM).
    let tier = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.SceneTier);
    if tier != EnumInt(GameplayTier.Undefined) && tier != EnumInt(GameplayTier.Tier1_FullGameplay) {
      return false;
    }
  }
  return true;
}

// Is the player standing in a zone the game itself treats as safe?
//
// The engine tags apartments, clinics, bars, memorials and the like as safe areas, and
// that classification is the right authority on where Cyberbane should keep its hands to
// itself - people do not scatter from a columbarium because a chromed merc walked in.
// Reading the game's own zone means this covers every such place without Cyberbane having
// to carry a list of locations (spec §16, S-13).
public func CBPlayerInSafeZone(game: GameInstance) -> Bool {
  // Ask the system that owns safe areas whether the point V is standing on is one.
  //
  // This replaces comparing the player-state blackboard's zone integer against
  // `gamePSMZones.Safe`. That comparison was the mod's weakest link: the enum's numeric value
  // cannot be confirmed from a compile, and if it happened to be 0 then an unset or
  // default-initialized blackboard read as "safe" everywhere - which silently stands down
  // crowds, gangs, morale, apex hunters and the mercy check all at once and presents as the
  // city simply ignoring V. A boolean query about a position carries no such ambiguity, and
  // being a live spatial query it cannot go stale the way cached player state can.
  //
  // Crash safety: `SafeAreaManager` is checked before use, the query takes a position rather
  // than an entity so nothing is dereferenced, and this runs once per fast tick on the
  // player's own position - the same frequency as the blackboard read it replaces.
  // Scenes and story beats put a lid on combat without V being in a safe area at all. The
  // game's reaction component checks this before anything else and Cyberbane was missing it,
  // so reactions could fire in moments the game had explicitly quieted.
  if CBPlayerNoCombatTag(game) {
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
//
// `IsDead()` on its own is not the question. Put a whole squad down non-lethally and every one
// of them answers "not dead", so the lane that sent them stayed busy for ever and no further
// encounter of that kind could be arranged - you had cleared the fight and the mod disagreed.
// Anyone defeated or incapacitated is out of it as surely as a corpse is.
public func CBStillStanding(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) || p.IsDead() {
    return false;
  }
  return !ScriptedPuppet.IsDefeated(p) && !p.IsIncapacitated();
}

// Is this NPC in combat? NPCs have no IsInCombat of their own (that is the player's); the game
// reads their high-level AI state off the puppet blackboard (NPCPuppet.IsInCombat).
public func CBNpcInCombat(npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) || !npc.IsAttached() {
    return false;
  }
  return NPCPuppet.IsInCombat(npc);
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
//
// Every read of the player's state in this mod went through `BlackboardSystem.Get(
// PlayerStateMachine)`, the global instance, and the game never writes there. The player's state
// lives on a blackboard instanced to the player entity: `PlayerPuppet.SetBlackboardIntVariable`
// writes the zone with `GetLocalInstanced(GetEntityID(), PlayerStateMachine)`
// (cyberpunk/player/player.script:7667), and `GetPlayerStateMachineBlackboard` returns that same
// instance (player.script:1920). So the zone, the stealth state, the forced-empty-hands state and
// the scene tier all read zero, always. Five gates were switched on and doing nothing: the turf
// gate behind the I WALK THE LINE report, the stealth hold, the apartment gate, the safe-zone
// fallback and the scene stand-down.
public func CBPlayerPSM(game: GameInstance) -> ref<IBlackboard> {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return null;
  }
  return player.GetPlayerStateMachineBlackboard();
}

// V is dead, or being brought back. The game writes it to V's state machine the moment V goes down,
// three seconds before the death screen (highLevelTransitions.script, DeathEvents), and back to Alive
// when V is up again (ResurrectEvents, and the respawn on load). The same value the game's own death
// menu and vision modes read, on 2.31 and 2.5 alike.
public func CBVDown(game: GameInstance) -> Bool {
  let psm = CBPlayerPSM(game);
  if !IsDefined(psm) {
    return false;
  }
  let v = psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vitals);
  return v == EnumInt(gamePSMVitals.Dead) || v == EnumInt(gamePSMVitals.Resurrecting);
}
