// Cyberbane - The pin on a Rival's place (1.7.1)
//
// "I want a proper custom pin, which can be identified easily and can't be confused with anything
// else." Every mappin variant in the game already means something, and the pin wears whatever its
// variant looks like: up to 1.6.4 an NCPD hustle, then the player's own waypoint, which the game
// owns and moved off the Rival's place. There is no variant that means "Cyberbane's".
//
// So the look is not left to the variant. The pin is registered on a variant nothing in the game
// claims, and every controller that draws it is told to draw Cyberbane's mark instead:
//
//   the glyph   `bounty_hunt` in the game's own mappin atlas (ChoiceIcons.BountyHuntIcon,
//               choice_ui_icon.tweak). On 2.31 and 2.5 nothing on any map draws that part - it is
//               only ever a dialogue choice icon - so on the map it can mean nothing but this. It is
//               the same mark Cyberbane puts on a Rival on the minimap (UI/Tracking.reds), so the
//               person and their place are visibly the same thing;
//   the colour  Cyberbane's Rival gold, the colour the Hub gives a Rival's row;
//   the words   the Rival's name, and "Cyberbane Rival" under it, where the map's tooltip and the
//               pin in the world would print the variant's own text.
//
// The base variant is ApartmentVariant (Rivals/Whereabouts.reds, CBLeadPinTick). The world map draws
// it, no 2.31 or 2.5 script reads it, it is not quest-grouped so the player can track it, and its
// filter group is Your Property (world_map.tweak, CommonFilterGroup) - the group the player's own
// waypoint and vehicles are in, on by default. It is never seen as an apartment: every surface that
// draws it is overridden below.
//
// The technique - a tag in debugCaption, which IMappin.GetDisplayName() returns, and the icon set on
// the controllers rather than in the mappin data - is the one Spuddeh's NC Zoning District Guide
// (MIT) uses for its own marker and documented from play, along with the two ways it can go wrong,
// both kept out of here:
//   - the mappin is only asked who it is where it is certainly alive: UpdateIcon, the container
//     building its profile, the tooltip being filled. Never from UpdateTrackedState, which also
//     runs while mappins are being destroyed; a wref to a dead one is not null, and reading it there
//     crashed their game on every map open;
//   - the tint is unbound and set directly. A style-bound tint is re-read on every state change and
//     the controllers change state on every update, so a bound colour does not stay.
//
// Crash rules: nothing here creates a widget, removes a mappin or touches an entity. Every hook calls
// the game's own code first and unconditionally, then changes only text, texture and tint on our own
// pin; every other pin on screen costs one name read and a prefix test.

public func CBRivalPinTag() -> String = "CB_RIVAL|"

public func CBRivalPinCaption(name: String) -> String {
  return CBRivalPinTag() + name;
}

// The marker on somebody out looking for V, as opposed to the pin on a place (UI/Tracking.reds). It
// goes through the world map's hooks below and no others: on the minimap and in the world it is an
// ordinary role pin, with the colour and the fight rules it has always had.
public func CBHunterPinMark() -> String = "+"

public func CBHunterPinCaption(name: String) -> String {
  return CBRivalPinTag() + CBHunterPinMark() + name;
}

// The marker on somebody of Cyberbane's who is not out looking for V (2.5.4): a bagman, a gang's people at a sit-down
// or a gathering, a wannabe, a favour's lookout, a Rival waiting at their place, a passer-by a favour is about. Every
// one of them wore the hunter's caption, so the map called them "Hunting you", and a passer-by with no gang, the one a
// favour asks V to lean on, read "Crew - Hunting you". The caption carries what they are and a line about them,
// split by CBMarkedPinSplit.
public func CBMarkedPinMark() -> String = "~"
public func CBMarkedPinSplit() -> String = "^"

public func CBMarkedPinCaption(name: String, note: String) -> String {
  return CBRivalPinTag() + CBMarkedPinMark() + name + CBMarkedPinSplit() + note;
}

public func CBIsMarkedPin(mappin: wref<IMappin>) -> Bool {
  return IsDefined(mappin) && StrBeginsWith(mappin.GetDisplayName(), CBRivalPinTag() + CBMarkedPinMark());
}

// The name or the line of a marked pin's caption.
func CBMarkedPinPart(mappin: wref<IMappin>, note: Bool) -> String {
  let caption = mappin.GetDisplayName();
  let skip = StrLen(CBRivalPinTag()) + StrLen(CBMarkedPinMark());
  let body = StrMid(caption, skip, StrLen(caption) - skip);
  let name: String;
  let line: String;
  if !StrSplitFirst(body, CBMarkedPinSplit(), name, line) {
    return note ? "" : body;
  }
  return note ? line : name;
}

// A gathering on the way (Spawn/StreetEvents.reds) and a place the map remembers (UI/MapPins.reds, 2.5.0): marks of
// their own after the tag, so each says what it is.
public func CBEventPinMark() -> String = "#"

public func CBEventPinCaption(text: String) -> String {
  return CBRivalPinTag() + CBEventPinMark() + text;
}

public func CBIsEventPin(mappin: wref<IMappin>) -> Bool {
  return IsDefined(mappin) && StrBeginsWith(mappin.GetDisplayName(), CBRivalPinTag() + CBEventPinMark());
}

public func CBIsMemoryPin(mappin: wref<IMappin>) -> Bool {
  return IsDefined(mappin) && StrBeginsWith(mappin.GetDisplayName(), CBRivalPinTag() + CBMemoryPinMark());
}

public func CBMemoryPinId(mappin: wref<IMappin>) -> Int32 {
  let caption = mappin.GetDisplayName();
  let skip = StrLen(CBRivalPinTag()) + StrLen(CBMemoryPinMark());
  return StringToInt(StrMid(caption, skip, StrLen(caption) - skip));
}

public func CBIsHunterPin(mappin: wref<IMappin>) -> Bool {
  if !IsDefined(mappin) {
    return false;
  }
  return StrBeginsWith(mappin.GetDisplayName(), CBRivalPinTag() + CBHunterPinMark());
}

// One of ours? Runs for every pin the game draws, so it stays this small.
public func CBIsRivalPin(mappin: wref<IMappin>) -> Bool {
  if !IsDefined(mappin) {
    return false;
  }
  return StrBeginsWith(mappin.GetDisplayName(), CBRivalPinTag());
}

// The Rival's name, out of the caption; or a remembered place's title, worked out now.
public func CBRivalPinName(mappin: wref<IMappin>) -> String {
  if CBIsMemoryPin(mappin) {
    return CBMapMemoryTitle(CyberbaneSystem.Get(GetGameInstance()), CBMemoryPinId(mappin));
  }
  if CBIsMarkedPin(mappin) {
    return CBMarkedPinPart(mappin, false);
  }
  let caption = mappin.GetDisplayName();
  let skip = StrLen(CBRivalPinTag());
  if CBIsHunterPin(mappin) {
    skip += StrLen(CBHunterPinMark());
  }
  if CBIsEventPin(mappin) {
    skip += StrLen(CBEventPinMark());
  }
  return StrMid(caption, skip, StrLen(caption) - skip);
}

// Rival gold, unless the pin says otherwise: the same three colours as the minimap's markers.
public func CBRivalPinColor(mappin: wref<IMappin>) -> HDRColor {
  let look = mappin.GetScriptData() as GameplayRoleMappinData;
  if IsDefined(look) {
    if Equals(look.m_quality, gamedataQuality.Epic) {
      return new HDRColor(0.66, 0.38, 0.92, 1.0);
    }
    if Equals(look.m_quality, gamedataQuality.Common) {
      return CBHudValue();
    }
  }
  return CBHudAmber();
}

public func CBRivalPinSubtitle(mappin: wref<IMappin>) -> String {
  if CBIsMemoryPin(mappin) {
    let sys = CyberbaneSystem.Get(GetGameInstance());
    return IsDefined(sys) ? CBMapMemoryDesc(sys, CBMemoryPinId(mappin)) : "";
  }
  // A gathering's pin said "Cyberbane Rival. Last seen here." up to 2.5.0.
  if CBIsEventPin(mappin) {
    return "Gang business. It starts around the time on the pin. Crash it, or leave them to it.";
  }
  if CBIsMarkedPin(mappin) {
    return CBMarkedPinPart(mappin, true);
  }
  return CBIsHunterPin(mappin) ? "Hunting you." : "Cyberbane Rival. Last seen here.";
}

// Draw Cyberbane's mark on this controller's icon, if the pin is ours. Safe on any controller: the
// glyph comes from a record checked at runtime, and with no record the game's own icon is left alone.
@addMethod(BaseMappinBaseController)
protected final func CBBrandRivalPin() -> Bool {
  if !CBIsRivalPin(this.GetMappin()) {
    return false;
  }
  // A gathering, a district taken, a place a fight was crashed: the game's own map glyph for it, in our colour.
  let part = n"";
  let tint = CBRivalPinColor(this.GetMappin());
  if CBIsEventPin(this.GetMappin()) {
    part = n"dynamic_event";
    tint = CBHudAmber();
  }
  if CBIsMemoryPin(this.GetMappin()) {
    let sys = CyberbaneSystem.Get(GetGameInstance());
    let id = CBMemoryPinId(this.GetMappin());
    part = CBMapMemoryPart(sys, id);
    tint = CBMapMemoryTint(sys, id);
  }
  if NotEquals(part, n"") {
    inkImageRef.SetAtlasResource(this.iconWidget, r"base\\gameplay\\gui\\common\\icons\\mappin_icons.inkatlas");
    inkImageRef.SetTexturePart(this.iconWidget, part);
    let mapIcon = inkWidgetRef.Get(this.iconWidget);
    if IsDefined(mapIcon) {
      mapIcon.UnbindProperty(n"tintColor");
      mapIcon.SetTintColor(tint);
    }
    return true;
  }
  let glyph = TweakDBInterface.GetUIIconRecord(t"ChoiceIcons.BountyHuntIcon");
  if !IsDefined(glyph) {
    return true;
  }
  inkImageRef.SetAtlasResource(this.iconWidget, glyph.AtlasResourcePath());
  inkImageRef.SetTexturePart(this.iconWidget, glyph.AtlasPartName());
  let icon = inkWidgetRef.Get(this.iconWidget);
  if IsDefined(icon) {
    icon.UnbindProperty(n"tintColor");
    icon.SetTintColor(tint);
  }
  return true;
}

// ---- The world map ----------------------------------------------------------------------------

@wrapMethod(BaseWorldMapMappinController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  this.CBBrandRivalPin();
}

// Hovering it names the Rival. The variant's own title and description would say Apartment.
@wrapMethod(WorldMapTooltipController)
public func SetData(const data: script_ref<WorldMapTooltipData>, menu: ref<WorldMapMenuGameController>) -> Void {
  wrappedMethod(data, menu);
  let mappin = Deref(data).mappin;
  if !CBIsRivalPin(mappin) {
    return;
  }
  inkTextRef.SetText(this.m_titleText, CBRivalPinName(mappin));
  inkTextRef.SetText(this.m_descText, CBRivalPinSubtitle(mappin));
}

// ---- The minimap ------------------------------------------------------------------------------

// The minimap has no entry for this variant on a plain position pin and would draw it only once
// tracked (minimap.script, CreateMappinUIProfile). Ours gets the profile the game gives the player's
// own waypoint: the POI widget, always spawned.
@wrapMethod(MinimapContainerController)
public func CreateMappinUIProfile(mappin: wref<IMappin>, mappinVariant: gamedataMappinVariant,
                                  customData: ref<MappinControllerCustomData>) -> MappinUIProfile {
  let profile = wrappedMethod(mappin, mappinVariant, customData);
  if !CBIsRivalPin(mappin) || CBIsHunterPin(mappin) || CBIsMarkedPin(mappin) {
    return profile;
  }
  return MappinUIProfile.Create(r"base\\gameplay\\gui\\widgets\\minimap\\minimap_poi_mappin.inkwidget",
                                t"MappinUISpawnProfile.Always", t"MinimapMappinUIProfile.Default");
}

@wrapMethod(MinimapPOIMappinController)
protected final func UpdateIcon() -> Void {
  wrappedMethod();
  this.CBBrandRivalPin();
}

// ---- In the world -----------------------------------------------------------------------------

// The floating pin, within range or once tracked. It prints the mappin's display name when V is
// close (MappinUIRuntimeProfile.showNameMinRange), and that is the tagged caption, so the Rival's
// name goes there instead. UpdateDisplayName runs just before UpdateIcon in OnUpdate
// (questMappins.script), so this is the text that stays.
@wrapMethod(QuestMappinController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  if this.CBBrandRivalPin() && inkWidgetRef.IsValid(this.displayName) {
    inkTextRef.SetText(this.displayName, CBRivalPinName(this.GetMappin()));
  }
}
