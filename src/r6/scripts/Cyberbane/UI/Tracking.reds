// Cyberbane - Marking the ones who are here for you (spec §12.3)
//
// Everyone Cyberbane sends gets a map marker bound to them with RegisterMappinWithObject, so it follows them without
// any updates from us.

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
  // Somebody a favour is about, and a bagman or a favour's lookout (Spawn/LivingStreet.reds).
  if puppet.cbFavourMark {
    return true;
  }
  // A Rival waiting at their place is a Rival (Rivals/Whereabouts.reds).
  return des.IsTagged(id, n"CB_Rival") || des.IsTagged(id, n"CB_Apex") || des.IsTagged(id, n"CB_Lair")
      || des.IsTagged(id, n"CB_Bagman") || des.IsTagged(id, n"CB_Favour");
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
  // A marker is for somebody up and about. One on a body on the ground outlived every encounter.
  if !puppet.IsAttached() || !CBStillStanding(puppet) {
    return;
  }
  let look = new GameplayRoleMappinData();
  look.m_textureID = CBMarkerIcon();
  look.m_quality = CBMarkerQuality(game, puppet);
  look.m_showOnMiniMap = true;
  look.m_visibleThroughWalls = false;
  let data: MappinData;
  // The variant is here for the map's filters alone, because GenericRole is in none of them. Everything that draws this
  // pin elsewhere goes by the role data, and the map draws it from the caption (UI/RivalPin.reds).
  data.mappinType = t"Mappins.DeviceWorldMapMappinDefinition";
  data.variant = gamedataMappinVariant.ApartmentVariant;
  data.active = true;
  data.visibleThroughWalls = false;
  data.scriptData = look;
  // Somebody out for V wears the hunter's caption; anybody else of ours says what they are (CBMarkerNote).
  let note = CBMarkerNote(game, puppet);
  data.debugCaption = StrLen(note) > 0 ? CBMarkedPinCaption(CBMarkerName(game, puppet), note)
                                       : CBHunterPinCaption(CBMarkerName(game, puppet));
  CBTrace("map: marker on a spawned enemy");
  // The same slot the game hangs its own role pins from, so the icon sits over the head.
  // A body that streamed out and back in has lost cbMapped and is set up again. Whatever pin it had
  // goes first, so it never wears two.
  let sysPin = CyberbaneSystem.Get(game);
  if IsDefined(sysPin) {
    let k = sysPin.MarkerCount() - 1;
    while k >= 0 {
      if Equals(sysPin.MarkerOwner(k), puppet.GetEntityID()) {
        ms.UnregisterMappin(sysPin.MarkerPin(k));
        sysPin.DropMarkerAt(k);
      }
      k -= 1;
    }
  }
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
  // One of the hunters' ladder by their own name, a passer-by by what a favour says of them, and the street's people by
  // what they are doing. Everybody of no gang was "Crew".
  if des.IsTagged(id, n"CB_Bounty") {
    let hunter = CBBountyScannerName(puppet);
    return StrLen(hunter) > 0 ? hunter : CBT(n"Cyberbane-Tracking-BountyHunter");
  }
  let gang = CBCapFirst(CBFactionLabel(CBClassifyFaction(puppet)));
  // A corporation's contract: the mark, and their guards.
  if des.IsTagged(id, n"CB_Mark") {
    let lifeC = CBStreetLifeFor(game);
    let client = IsDefined(lifeC) ? CBFactionLabel(lifeC.FavourFaction()) : "";
    if puppet.cbFavourMark {
      return StrLen(client) > 0 ? CBTf(n"Cyberbane-Tracking-ContractMark", [client]) : CBT(n"Cyberbane-Tracking-AContractMark");
    }
    return CBTf(n"Cyberbane-Tracking-ContractGuard", [gang]);
  }
  if puppet.cbFavourMark || des.IsTagged(id, n"CB_Debtor") {
    let life = CBStreetLifeFor(game);
    let owed = IsDefined(life) ? CBFactionLabel(life.FavourFaction()) : "";
    // Money, said as money: "Owes the Valentinos" alone read as easily as a contract on them as a debt.
    return StrLen(owed) > 0 ? CBTf(n"Cyberbane-Tracking-OwesMoney", [owed]) : CBT(n"Cyberbane-Tracking-OwesAGangMoney");
  }
  if des.IsTagged(id, n"CB_Wannabe") {
    return des.IsTagged(id, n"CB_WannabeFriend") ? CBT(n"Cyberbane-Wannabe-WannabeSFriend") : CBT(n"Cyberbane-Wannabe-Wannabe");
  }
  if puppet.cbLeadWitnessFor > 0 || des.IsTagged(id, n"CB_Witness") {
    return CBT(n"Cyberbane-Tracking-SawYourRival");
  }
  let what = "";
  if des.IsTagged(id, n"CB_Bagman") { what = CBT(n"Cyberbane-Tracking-Bagman"); }
  if des.IsTagged(id, n"CB_Favour") { what = CBT(n"Cyberbane-Tracking-Lookout"); }
  if des.IsTagged(id, n"CB_Patrol") { what = CBT(n"Cyberbane-Tracking-Patrol"); }
  if des.IsTagged(id, n"CB_Hangout") { what = CBT(n"Cyberbane-Tracking-HangingOut"); }
  if des.IsTagged(id, n"CB_Meet") || des.IsTagged(id, n"CB_Event") { what = CBT(n"Cyberbane-Tracking-Gathering"); }
  if des.IsTagged(id, n"CB_Apex") { what = CBT(n"Cyberbane-Tracking-ApexSquad"); }
  let crew = StrLen(what) == 0;
  if crew {
    what = CBT(n"Cyberbane-Tracking-Crew");
  }
  if StrLen(gang) == 0 {
    return CBCapFirst(crew ? CBT(n"Cyberbane-Tracking-Hunter") : what);
  }
  return gang + " " + what;
}

// The line under the name for somebody of ours who is not out for V, "" for somebody who is.
func CBMarkerNote(game: GameInstance, puppet: ref<ScriptedPuppet>) -> String {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !IsDefined(puppet) {
    return "";
  }
  let id = puppet.GetEntityID();
  if des.IsTagged(id, n"CB_Mark") {
    return CBT(n"Cyberbane-Tracking-ContractNote");
  }
  if puppet.cbFavourMark || des.IsTagged(id, n"CB_Debtor") {
    // What does it, said plainly: words first, fists if they swing, never a body.
    return CBT(n"Cyberbane-Tracking-ADebtToCollectTalkThem");
  }
  if des.IsTagged(id, n"CB_Lair") {
    return CBT(n"Cyberbane-Tracking-AtTheirPlaceNotLookingFor");
  }
  if des.IsTagged(id, n"CB_Bagman") {
    return CBT(n"Cyberbane-Tracking-CarryingTheTakeRobThemOr");
  }
  if des.IsTagged(id, n"CB_Favour") {
    return CBT(n"Cyberbane-Tracking-AFavourWatchingYourFriendsCorner");
  }
  if des.IsTagged(id, n"CB_Meet") || des.IsTagged(id, n"CB_Event") {
    return CBT(n"Cyberbane-Tracking-GangBusinessCrashItOrLeave");
  }
  if des.IsTagged(id, n"CB_WannabeFriend") {
    return CBT(n"Cyberbane-Tracking-HereToWatchAndToTell");
  }
  if des.IsTagged(id, n"CB_Wannabe") {
    return CBT(n"Cyberbane-Tracking-OutToMakeANameOff");
  }
  if puppet.cbLeadWitnessFor > 0 || des.IsTagged(id, n"CB_Witness") {
    return CBT(n"Cyberbane-Tracking-SawYourRivalAskThemPay");
  }
  if des.IsTagged(id, n"CB_Patrol") {
    return CBT(n"Cyberbane-Tracking-WalkingTheirTurf");
  }
  if des.IsTagged(id, n"CB_Hangout") {
    return CBT(n"Cyberbane-Tracking-HangingOutOnTheirOwnStreets");
  }
  return "";
}

// Take down any pin whose owner has left the world.
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

// Every marker Cyberbane has put on anybody, off, from the system's own list of them (NoteMarker): so none is missed
// whatever tag its owner wears now, or if they wear none - a favour's mark is on a passer-by (Spawn/LivingStreet.reds),
// and a body handed to the orphan sweep keeps its pin.
public func CBUntrackAllMarkers(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(sys) || !IsDefined(ms) {
    return;
  }
  let guard = sys.MarkerCount();
  while sys.MarkerCount() > 0 && guard > 0 {
    guard -= 1;
    let last = sys.MarkerCount() - 1;
    let p = GameInstance.FindEntityByID(game, sys.MarkerOwner(last)) as ScriptedPuppet;
    ms.UnregisterMappin(sys.MarkerPin(last));
    sys.DropMarkerAt(last);
    if IsDefined(p) {
      p.cbMapped = false;
      p.cbMapData = null;
    }
  }
}

// Clear the markers off everyone wearing one of our tags. Harmless on tags that were never
// marked, since each puppet checks its own flag.
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
    CBUntrackAllMarkers(sys, game);
    return;
  }
  CBMarkerFightTag(game, des, n"CB_Rival");
  CBMarkerFightTag(game, des, n"CB_Apex");
  CBMarkerFightTag(game, des, n"CB_Squad");
  CBMarkerFightTag(game, des, n"CB_Escort");
  CBMarkerFightTag(game, des, n"CB_Scout");
  CBMarkerFightTag(game, des, n"CB_Lair");
}
