// Cyberbane - Marking the ones who are here for you (spec §12.3)
//
// A player reported the honest version of this problem: "I get a notification that somebody has
// caught up to me, but I don't really see them, or know if a certain enemy on the street is a
// relevant enemy from the mod." On a busy street a Rival looks exactly like any other ganger
// until they open fire.
//
// So they get a marker, through the game's own mappin system rather than anything drawn by
// hand. `RegisterMappinWithObject` binds the pin to the NPC instead of to a position, so it
// follows them as they come for you and needs no updating from us.
//
// `Mappins.QuestEntityMappinDefinition` is the definition for a pin attached to an entity: it
// sets `showOnMinimap`, `showOnMap` and `showInWorld` itself, and it publishes the list of
// variants it will accept. `DefaultQuestVariant` is on that list and is in the
// `gamedataMappinVariant` enum, which not every name in the tweak list is - `Mappins.SoloVariant`
// appears there but has no matching enum member, so it would have been a dead pin.
//
// Marked: Rivals and apex squad members, which is at most five at a time. Not marked: ordinary
// crew, or the escorts that arrive with an apex squad. A vendetta crew runs to thirteen people
// and thirteen markers showing through walls is clutter rather than help; a crew arrives
// together and is obvious the moment it opens fire. The thing a player genuinely cannot
// identify is one named enemy standing in a street full of gangers, and that is what this is
// for.

@addField(ScriptedPuppet)
public let cbMappinId: NewMappinID;

@addField(ScriptedPuppet)
public let cbMapped: Bool;

// Does the player want these at all?
public func CBMapMarkersOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled()
      && (!rt.HasSettings() || rt.GetSettings().mapMarkers);
}

// Put a marker on this one.
public func CBTrackOnMap(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || puppet.cbMapped || !CBMapMarkersOn() {
    return;
  }
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(ms) {
    return;
  }
  let data: MappinData;
  data.mappinType = t"Mappins.QuestEntityMappinDefinition";
  data.variant = gamedataMappinVariant.DefaultQuestVariant;
  data.active = true;
  // Through walls deliberately. The whole reason this exists is that the player could not find
  // them; a marker that disappears the moment they step behind a building is the same problem
  // with extra steps. It is a position, not a scan: it says somebody is coming from that way,
  // which is what the message on screen already told them.
  data.visibleThroughWalls = true;
  puppet.cbMappinId = ms.RegisterMappinWithObject(data, puppet);
  puppet.cbMapped = true;
}

// Take it off again. Called when they die and when an encounter is swept.
public func CBUntrackOnMap(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || !puppet.cbMapped {
    return;
  }
  let ms = GameInstance.GetMappinSystem(game);
  if IsDefined(ms) {
    ms.UnregisterMappin(puppet.cbMappinId);
  }
  puppet.cbMapped = false;
}

// Clear the markers off everyone wearing one of our tags. Harmless on tags that were never
// marked, since each puppet checks its own flag.
//
// The pin is bound to the entity, so an NPC that streams out takes its pin with it. This is for
// the cases where the encounter ends while they are still standing there: outrunning them, or
// the session sweep.
public func CBUntrackTagged(game: GameInstance, tag: CName) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    if IsDefined(p) {
      CBUntrackOnMap(game, p);
    }
    i += 1;
  }
}
