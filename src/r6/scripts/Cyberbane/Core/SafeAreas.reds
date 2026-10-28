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

// Has the player opted into being hunted inside safe areas?
public func CBAllowSafeZoneSpawns() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().allowSafeZoneSpawns;
}

// Should Cyberbane refuse to put anyone down here?
//
// Checks the spawn point itself, not just where V is standing. V can be on the pavement with
// the point behind them inside a bar, or the reverse, and only the point matters for whether
// the arrival lands somewhere the player cannot fight.
public func CBSafeAreaBlocksSpawn(game: GameInstance, at: Vector4) -> Bool {
  if CBAllowSafeZoneSpawns() {
    return false;   // the player has asked for this fight
  }
  let sam = GameInstance.GetSafeAreaManager(game);
  if !IsDefined(sam) {
    return false;   // cannot tell: do not silently stop every spawn in the game
  }
  return sam.IsPointInSafeArea(at);
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
