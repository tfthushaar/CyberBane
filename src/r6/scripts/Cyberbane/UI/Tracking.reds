// Cyberbane - Marking the ones who are here for you (spec 12.3)
//
// A player reported the honest version of this problem: "I get a notification that somebody has
// caught up to me, but I don't really see them, or know if a certain enemy on the street is a
// relevant enemy from the mod." On a busy street a Rival looks exactly like any other ganger
// until they open fire.
//
// So everybody Cyberbane sends carries a marker of Cyberbane's own, through the game's own mappin
// system rather than anything drawn by hand. `RegisterMappinWithObject` binds the pin to the NPC
// instead of to a position, so it follows them as they come for you and needs no updating from us.
//
// ---- Why it looks the way it does (1.7.0) ----
//
// The markers have been wrong twice, and both times for the same reason: a pin's look was left to
// its variant, and every variant already means something. 1.4.7 moved off the yellow quest diamond
// to `GangWatchVariant`, which reads as gang business in the tweak files and is an NCPD scanner
// hustle everywhere a player can see it: `map_bounty` on the map, in the police group, and treated
// as an NCPD scanner by the minimap's POI controller (minimapMappins.script, IsNcpdScanner). So
// everybody hunting V was marked as police, which is the report that replaced this. There is no
// variant that means "Cyberbane's".
//
// A pin that carries `GameplayRoleMappinData` does not take its look from its variant at all. This
// is how the game marks what you can interact with: `MinimapContainerController.CreateMappinUIProfile`
// sends any pin with that data to the device mappin, and `MinimapDeviceMappinController.Update`
// draws the icon named by the data's `m_textureID`, always, at any range, and colours it by the
// data's quality. So the look is ours to set, in data, with no widget of ours and no hook:
//
//   the icon    the `bounty_hunt` part of the game's own mappin atlas, which the map itself never
//               uses (BountyHuntVariant draws `gigs`), so on the minimap it means only this;
//   the colour  gold for a Rival, purple for an apex squad, white for a crew, so the one that
//               matters can be picked out of a street full.
//
// `Mappins.DeviceWorldMapMappinDefinition` shows on the minimap, over their heads and on the big map
// (1.7.1; the plain device definition, used in 1.7.0, is the one with the map switched off).
// (Rivals/Whereabouts.reds).
//
// ---- And what stays from before ----
//
// `visibleThroughWalls` is off, so a pin is a place rather than a scan. A body that has gone takes
// its pin with it.
//
// ---- The fight ----
//
// These used to come off for good, for everybody, the moment V was in combat with anybody, and
// nothing put them back. So one scout was enough to take every marker off the map, and the crew
// still walking in from behind had none. Now the minimap marker stays for as long as they are
// alive. What the fight takes away is only the icon over the head of somebody who is actually
// fighting V: the game already draws them, and twenty icons in a firefight was the complaint that
// rule was written for. That is `m_isBroken`, which the world controller reads to hide the icon
// (gameplayMappins.script, UpdateIcon) and the minimap controller does not read at all.

@addField(ScriptedPuppet)
public let cbMappinId: NewMappinID;

@addField(ScriptedPuppet)
public let cbMapped: Bool;

// The pin's data, kept so the fight can change it. Never read for anything else.
@addField(ScriptedPuppet)
public let cbMapData: ref<GameplayRoleMappinData>;

// How much does the player want marked?
public func CBMarkerScope() -> ECBMarkerScope {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return ECBMarkerScope.Off;
  }
  if !rt.HasSettings() {
    return ECBMarkerScope.Everyone;
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
// here. Everyone, the default, adds the crews and the escorts.
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
  // A Rival waiting at their place is a Rival (Rivals/Whereabouts.reds).
  return des.IsTagged(id, n"CB_Rival") || des.IsTagged(id, n"CB_Apex") || des.IsTagged(id, n"CB_Lair");
}

// The icon. The person glyph if the part we want is not on this install, because a pin whose
// record cannot be found draws nothing at all.
func CBMarkerIcon() -> TweakDBID {
  if IsDefined(TweakDBInterface.GetUIIconRecord(t"ChoiceIcons.BountyHuntIcon")) {
    return t"ChoiceIcons.BountyHuntIcon";
  }
  return t"MappinIcons.NPCMappin";
}

// What colour this one is. Quality is the one colour control the device pin has that means
// nothing else on an NPC.
func CBMarkerQuality(game: GameInstance, puppet: ref<ScriptedPuppet>) -> gamedataQuality {
  let des = GameInstance.GetDynamicEntitySystem();
  if IsDefined(des) {
    let id = puppet.GetEntityID();
    if des.IsTagged(id, n"CB_Rival") || des.IsTagged(id, n"CB_Lair") {
      return gamedataQuality.Legendary;
    }
    if des.IsTagged(id, n"CB_Apex") {
      return gamedataQuality.Epic;
    }
  }
  return gamedataQuality.Common;
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
  if !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  let look = new GameplayRoleMappinData();
  look.m_textureID = CBMarkerIcon();
  look.m_quality = CBMarkerQuality(game, puppet);
  look.m_showOnMiniMap = true;
  look.m_visibleThroughWalls = false;
  let data: MappinData;
  // DeviceWorldMapMappinDefinition is the same pin with the big map switched on. 1.7.0 used the
  // plain device definition, which has showOnMap false, so moving off the NCPD icon also took
  // everybody off the map: the pins stayed on the minimap and a player looking for a leader on the
  // big map found nothing. The variant is here for the map's filters alone, because GenericRole is
  // in none of them. Everything that draws this pin elsewhere goes by the role data, and the map
  // draws it from the caption (UI/RivalPin.reds).
  data.mappinType = t"Mappins.DeviceWorldMapMappinDefinition";
  data.variant = gamedataMappinVariant.ApartmentVariant;
  data.active = true;
  data.visibleThroughWalls = false;
  data.scriptData = look;
  data.debugCaption = CBHunterPinCaption(CBMarkerName(game, puppet));
  CBTrace("map: marker on a spawned enemy");
  // The same slot the game hangs its own role pins from, so the icon sits over the head.
  puppet.cbMappinId = ms.RegisterMappinWithObject(data, puppet, puppet.GetRoleMappinSlotName());
  puppet.cbMapData = look;
  puppet.cbMapped = true;
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) {
    sys.NoteMarker(puppet.GetEntityID(), puppet.cbMappinId);
  }
}

// Who this is, for the map's tooltip.
func CBMarkerName(game: GameInstance, puppet: ref<ScriptedPuppet>) -> String {
  let sys = CyberbaneSystem.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(des) {
    return "";
  }
  let id = puppet.GetEntityID();
  if des.IsTagged(id, n"CB_Rival") || des.IsTagged(id, n"CB_Lair") {
    let who = CBFindRivalByBody(sys, id);
    if !IsDefined(who) {
      who = sys.FindRivalById(sys.GetActiveRivalId());
    }
    return CBRivalDisplayName(sys.GetContent(), who);
  }
  let gang = CBCapFirst(CBFactionLabel(CBClassifyFaction(puppet)));
  if StrLen(gang) == 0 {
    return des.IsTagged(id, n"CB_Apex") ? "Apex squad" : "Crew";
  }
  return gang + (des.IsTagged(id, n"CB_Apex") ? " apex squad" : " crew");
}

// Take down any pin whose owner has left the world.
//
// A pin on an object goes to an unpredictable place when the object does (psiberx's map pin sample
// says so outright). An NPC who streams out never reaches CBUntrackOnMap, and its id went with the
// puppet, so nothing could take that pin down. On the minimap it was never noticed. On the big map
// it would be a marker on somebody who is not there. The owner and the pin are kept on the system
// for this, and only the entity's id is looked up, so nothing here touches anybody who has gone.
func CBMarkerSweep(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(ms) {
    return;
  }
  let i = sys.MarkerCount() - 1;
  while i >= 0 {
    let p = GameInstance.FindEntityByID(game, sys.MarkerOwner(i)) as ScriptedPuppet;
    if !IsDefined(p) || !p.IsAttached() {
      ms.UnregisterMappin(sys.MarkerPin(i));
      sys.DropMarkerAt(i);
    }
    i -= 1;
  }
}

// Take it off again. Called when they die and when the encounter is swept.
public func CBUntrackOnMap(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || !puppet.cbMapped {
    return;
  }
  let ms = GameInstance.GetMappinSystem(game);
  if IsDefined(ms) {
    ms.UnregisterMappin(puppet.cbMappinId);
  }
  puppet.cbMapped = false;
  puppet.cbMapData = null;
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) {
    sys.ForgetMarker(puppet.GetEntityID());
  }
}

// Clear the markers off everyone wearing one of our tags. Harmless on tags that were never
// marked, since each puppet checks its own flag.
//
// The pin is bound to the entity, so an NPC that streams out takes its pin with it. This is for
// the cases where the encounter ends while they are still standing there: outrunning them, the
// session sweep, the switch being turned off.
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

// Who is fighting V loses the icon over their head, and gets it back if the fight moves on.
func CBMarkerFightTag(game: GameInstance, des: ref<DynamicEntitySystem>, tag: CName) -> Void {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if IsDefined(p) && p.cbMapped && IsDefined(p.cbMapData) {
      p.cbMapData.m_isBroken = CBNpcInCombat(p);
    }
  }
}

// Called from the fast tick, a pass every other second: nobody moves in or out of a fight faster
// than that matters, and each pass walks every tag we have.
public func CBMarkerCombatTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || sys.GetTickCount() % 2 != 0 {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  CBMarkerSweep(sys, game);
  // Switched off with people out: their markers go now, not when they next happen to be swept.
  let on = CBMapMarkersOn();
  if !on {
    CBUntrackTagged(game, n"Cyberbane");
    return;
  }
  CBMarkerFightTag(game, des, n"CB_Rival");
  CBMarkerFightTag(game, des, n"CB_Apex");
  CBMarkerFightTag(game, des, n"CB_Squad");
  CBMarkerFightTag(game, des, n"CB_Escort");
  CBMarkerFightTag(game, des, n"CB_Scout");
  CBMarkerFightTag(game, des, n"CB_Lair");
}
