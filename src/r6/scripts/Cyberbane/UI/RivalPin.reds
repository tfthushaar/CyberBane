// Cyberbane - The pin on a Rival's place
//
// Registered on a mappin variant nothing in the game uses, and drawn with the bounty_hunt glyph, so it can't be
// mistaken for anything else on the map.

public func CBRivalPinTag() -> String = "CB_RIVAL|"

public func CBRivalPinCaption(name: String) -> String {
  return CBRivalPinTag() + name;
}

// The marker on somebody out looking for V, as opposed to the pin on a place (UI/Tracking.reds).
public func CBHunterPinMark() -> String = "+"

public func CBHunterPinCaption(name: String) -> String {
  return CBRivalPinTag() + CBHunterPinMark() + name;
}

// The marker on somebody of Cyberbane's who is not out looking for V: a bagman, a gang's people at a sit-down or a
// gathering, a wannabe, a favour's lookout, a Rival waiting at their place, a passer-by a favour is about.
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

// A gathering on the way (Spawn/StreetEvents.reds) and a place the map remembers (UI/MapPins.reds): marks of their own
// after the tag, so each says what it is.
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
  // A gathering's pin said "Cyberbane Rival.
  if CBIsEventPin(mappin) {
    return CBT(n"Cyberbane-RivalPin-GangBusinessItStartsAroundThe");
  }
  if CBIsMarkedPin(mappin) {
    return CBMarkedPinPart(mappin, true);
  }
  return CBIsHunterPin(mappin) ? CBT(n"Cyberbane-RivalPin-HuntingYou") : CBT(n"Cyberbane-RivalPin-CyberbaneRivalLastSeenHere");
}

// Draw Cyberbane's mark on this controller's icon, if the pin is ours. Safe on any controller: the glyph comes from a
// record checked at runtime, and with no record the game's icon is left alone.
@addMethod(BaseMappinBaseController)
protected final func CBBrandRivalPin() -> Bool {
  if !CBIsRivalPin(this.GetMappin()) {
    return false;
  }
  // A gathering, a district taken, a place a fight was crashed: the game's map glyph for it, in our colour.
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

// The minimap has no entry for this variant on a plain position pin and would draw it only once tracked
// (minimap.script, CreateMappinUIProfile).
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

// The floating pin, within range or once tracked. It prints the mappin's display name when V is close
// (MappinUIRuntimeProfile.showNameMinRange), and that is the tagged caption, so the Rival's name goes there instead.
@wrapMethod(QuestMappinController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  if this.CBBrandRivalPin() && inkWidgetRef.IsValid(this.displayName) {
    inkTextRef.SetText(this.displayName, CBRivalPinName(this.GetMappin()));
  }
}
