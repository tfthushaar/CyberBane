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

// One of ours? Runs for every pin the game draws, so it stays this small.
public func CBIsRivalPin(mappin: wref<IMappin>) -> Bool {
  if !IsDefined(mappin) {
    return false;
  }
  return StrBeginsWith(mappin.GetDisplayName(), CBRivalPinTag());
}

// The Rival's name, out of the caption.
public func CBRivalPinName(mappin: wref<IMappin>) -> String {
  let caption = mappin.GetDisplayName();
  let skip = StrLen(CBRivalPinTag());
  return StrMid(caption, skip, StrLen(caption) - skip);
}

public func CBRivalPinColor() -> HDRColor {
  return CBHudAmber();
}

public func CBRivalPinSubtitle() -> String = "Cyberbane Rival. Last seen here."

// Draw Cyberbane's mark on this controller's icon, if the pin is ours. Safe on any controller: the
// glyph comes from a record checked at runtime, and with no record the game's own icon is left alone.
@addMethod(BaseMappinBaseController)
protected final func CBBrandRivalPin() -> Bool {
  if !CBIsRivalPin(this.GetMappin()) {
    return false;
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
    icon.SetTintColor(CBRivalPinColor());
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
  inkTextRef.SetText(this.m_descText, CBRivalPinSubtitle());
}

// ---- The minimap ------------------------------------------------------------------------------

// The minimap has no entry for this variant on a plain position pin and would draw it only once
// tracked (minimap.script, CreateMappinUIProfile). Ours gets the profile the game gives the player's
// own waypoint: the POI widget, always spawned.
@wrapMethod(MinimapContainerController)
public func CreateMappinUIProfile(mappin: wref<IMappin>, mappinVariant: gamedataMappinVariant,
                                  customData: ref<MappinControllerCustomData>) -> MappinUIProfile {
  let profile = wrappedMethod(mappin, mappinVariant, customData);
  if !CBIsRivalPin(mappin) {
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
