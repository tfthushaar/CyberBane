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
// ---- What 1.4.7 changed, and why ----
//
// The answer to that first report over-corrected into a second one: "the obnoxious yellow
// markers need some work". Both halves of that are fair.
//
// Obnoxious, because of what was being asked for. `Mappins.QuestEntityMappinDefinition` with
// `DefaultQuestVariant` is the pin the game uses for the objective you are supposed to be
// doing, and `MappinUIUtils.MappinToTexturePart` maps that variant to `minor_quest` - the
// yellow quest diamond. So a gang crew turning up put yellow quest markers on the HUD, which
// is the game's own language for "go here", pointed at people trying to kill you.
//
// And too many of them, because 1.1.5 widened the marker to every single body the mod sends. A
// vendetta crew is up to twenty people. Twenty pins, through walls, is not a way of finding
// the dangerous one; it is a second minimap laid over the first.
//
// Three changes, then. `GangWatchVariant` instead, which the same function maps to the bounty
// icon the game uses for gang activity - the right language for a gang coming after you.
// `visibleThroughWalls` off, so a pin is a place rather than a scan. And the default scope is
// the people who are somebody: a Rival and the four of an apex squad. Crews are available on
// the Everyone setting for anybody who wants them.
//
// The fourth change is the one that actually answers "obnoxious": the pin comes off when the
// fight starts. The game already draws hostiles in combat on the minimap by itself, so from
// the moment shooting begins ours is duplicating a display that is already there - and that is
// precisely the stretch when the screen is busiest and a pin is most in the way. Finding them
// is the job; fighting them is not.

@addField(ScriptedPuppet)
public let cbMappinId: NewMappinID;

@addField(ScriptedPuppet)
public let cbMapped: Bool;

// How much does the player want marked?
public func CBMarkerScope() -> ECBMarkerScope {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return ECBMarkerScope.Off;
  }
  if !rt.HasSettings() {
    return ECBMarkerScope.NamedOnly;
  }
  return rt.GetSettings().mapMarkers;
}

// Does the player want these at all?
public func CBMapMarkersOn() -> Bool {
  return NotEquals(CBMarkerScope(), ECBMarkerScope.Off);
}

// Is this one of ours worth a pin, at the scope the player chose?
//
// A Rival and the members of an apex squad are people: one name, one role, one reason they are
// here. A crew is a crowd, and a pin per head in a crowd is the complaint.
func CBWorthMarking(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Bool {
  let scope = CBMarkerScope();
  if Equals(scope, ECBMarkerScope.Off) {
    return false;
  }
  if Equals(scope, ECBMarkerScope.Everyone) {
    return true;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let id = puppet.GetEntityID();
  return des.IsTagged(id, n"CB_Rival") || des.IsTagged(id, n"CB_Apex");
}

// Put a marker on this one.
public func CBTrackOnMap(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || puppet.cbMapped || !CBWorthMarking(game, puppet) {
    return;
  }
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(ms) {
    return;
  }
  let data: MappinData;
  data.mappinType = t"Mappins.QuestEntityMappinDefinition";
  // The gang-activity icon rather than the quest diamond. `MappinUIUtils.MappinToTexturePart`
  // maps GangWatchVariant to `map_bounty`, which is what the game puts on gang business, and
  // DefaultQuestVariant to `minor_quest`, which is what it puts on your current objective.
  // Asking for the second one was the whole of the "yellow markers" complaint. GangWatchVariant
  // is in `gamedataMappinVariant`, which not every name in the tweak list is - that is the trap
  // Mappins.SoloVariant fell into once, and the reason this is worth writing down.
  data.variant = gamedataMappinVariant.GangWatchVariant;
  data.active = true;
  // Not through walls any more. A pin that reads through a building is a scan, and a scan of
  // where every enemy is standing is both more help than this is meant to be and the main
  // reason the markers read as intrusive. It still tells the player which direction somebody is
  // coming from, which is what the message on screen already said.
  data.visibleThroughWalls = false;
  puppet.cbMappinId = ms.RegisterMappinWithObject(data, puppet);
  puppet.cbMapped = true;
}

// Take it off again. Called when they die, when the encounter is swept, and when the fight
// starts and the game's own display takes over.
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
// the cases where the encounter ends while they are still standing there: outrunning them, the
// session sweep, and the fight starting.
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

// Once the shooting starts, our pins come down.
//
// Called from the fast tick. The game draws hostiles it knows about on the minimap during
// combat, so from here on ours add nothing and sit on top of the busiest moment on screen.
// Nothing puts them back: by the time a fight is over, the player has either won or the
// encounter has been swept, and a marker to help you find somebody you are already fighting is
// the thing being complained about.
public func CBMarkerCombatTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !CBMapMarkersOn() {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || !player.IsInCombat() {
    return;
  }
  CBUntrackTagged(game, n"CB_Rival");
  CBUntrackTagged(game, n"CB_Apex");
  CBUntrackTagged(game, n"CB_Squad");
  CBUntrackTagged(game, n"CB_Escort");
}
