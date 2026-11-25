// Cyberbane - Public add-on API (spec §14)
//
// Stable surface for third-party mods to extend the content registries and to
// read Cyberbane's live reputation values. Content registration goes through the
// global content service (no GameInstance needed); read queries take a
// GameInstance because reputation is per-save.

// Whoever put V down, promoted now.
//
// Takes a faction Cyberbane already knows, so the two callers cannot disagree about how an
// affiliation is mapped: the public API maps it first, and the death hook already has the
// answer from CBClassifyFaction.
public func CBPromoteKiller(game: GameInstance, faction: CName, killerRecordID: TweakDBID,
                            weaponCategory: CName, opt killerBody: EntityID,
                            opt killerLook: CName) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  if rt.HasSettings() && !rt.GetSettings().deathsRemembered {
    return false;
  }
  let sys = CyberbaneSystem.Get(game);
  let content = CBContent(game);
  if !IsDefined(sys) || !IsDefined(content) || !TDBID.IsValid(killerRecordID)
     || Equals(faction, n"") {
    return false;
  }
  let now = CBGameSeconds(game);
  let district = CBEventDistrict(sys, game);

  // The Rival who did it, if it was one. With a body to go on (our own death hook), only that
  // body counts: the record is shared by everyone of that kind in the gang. Without one (another
  // mod reporting through the API) the record is all there is, so it is used as before.
  let who: ref<CBRival>;
  if EntityID.IsDefined(killerBody) {
    let byBody = CBFindRivalByBody(sys, killerBody);
    if IsDefined(byBody)
       && (byBody.state == EnumInt(ECBRivalState.Active) || byBody.state == EnumInt(ECBRivalState.Hunting)) {
      who = byBody;
    }
    // Not a Rival's body, but the same face as a Killer Rival already out: the game's NPC who killed V once has killed
    // V again. Without this a death alternative such as Fenix Rebirth, which carries V on without a reload, made a
    // second Rival of them with a name of their own.
    if !IsDefined(who) {
      who = CBKillerRivalLike(sys, faction, killerRecordID, killerLook);
    }
  } else {
    for r in sys.GetRivals() {
      if IsDefined(r) && r.recordID == killerRecordID
         && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        who = r;
      }
    }
  }
  let isNew = false;
  if !IsDefined(who) {
    // Quiet: "put you down. They will be looking for you." below is this death's one message.
    who = CBCreateRival(sys, game, faction, killerRecordID, killerLook, ECBRivalSource.Killer,
                        district, now, true);
    isNew = true;
  }
  if !IsDefined(who) {
    return false;   // refused: the roster is full, or this is somebody the story owns
  }
  CBRivalKilledV(who, content, now, district);
  // A scar is a bit position (Core/Types.reds), set as every other scar is: OR-ing the position in itself left a gun
  // (position 0) as no scar at all and turned a blade into a gunshot.
  let scar = CBScarForWeaponCategory(weaponCategory);
  if scar >= 0 {
    who.scarMask = CBMaskSet(who.scarMask, scar);
  }

  // The gang saw it done. Standing is V's footing with them, and somebody who has put V down is harder to frighten. Not
  // with reputation frozen, which every other change to standing already respected.
  let fs = sys.FindFaction(faction);
  if IsDefined(fs) && !CBReputationFrozen() {
    fs.standing = ClampF(fs.standing - CBConfig.DeathStandingDrop(), -100.0, 100.0);
  }
  if CBMessagesOn() {
    let name = CBRivalDisplayName(content, who);
    if isNew {
      CBPhoneDemandFromGang(game, faction, CBTf(n"Cyberbane-CyberbaneAPI-PutYouDownTheyWillBe", [s"\(name)"]));
    } else {
      CBPhoneDemandFromGang(game, faction, CBTf(n"Cyberbane-CyberbaneAPI-PutYouDownAgainTheyAre", [s"\(name)"]));
    }
  }
  CBLog.Info(n"Rivals", s"Killed by \(NameToString(faction)) (\(TDBID.ToStringDEBUG(killerRecordID))); rival \(who.id) is now rank \(who.rank).");
  return true;
}

// Which wound this weapon leaves on the Rival who dealt it.
//
// Fenix Rebirth reports the weapon's `gamedataItemType` as a name, which is the same vocabulary
// Cyberbane's own scars use, so the mapping is a read and not a guess. Anything unrecognised
// counts as shot, which is what the overwhelming majority of deaths are. -1 when nothing is known.
public func CBScarForWeaponCategory(category: CName) -> Int32 {
  let c = NameToString(category);
  if StrLen(c) == 0 {
    return -1;   // nothing known about the weapon; do not invent a wound
  }
  if StrContains(c, "Katana") || StrContains(c, "Knife") || StrContains(c, "Sword")
     || StrContains(c, "Blade") || StrContains(c, "Machete") || StrContains(c, "Axe") {
    return CBScarCut();
  }
  if StrContains(c, "Grenade") || StrContains(c, "Launcher") || StrContains(c, "Rocket") {
    return CBScarBurned();
  }
  if StrContains(c, "Cyberdeck") || StrContains(c, "Hack") || StrContains(c, "Program") {
    return CBScarFried();
  }
  return CBScarShot();
}

public abstract class CyberbaneAPI {
  // ---- Dying, for mods that let V get back up ----------------------------
  //
  // V was killed and did not reload. Hand over who did it and Cyberbane makes them the Rival
  // who did, or promotes the one who already was.
  //
  // Cyberbane has had this mechanic since the beginning, through the cross-save Death Ledger
  // (spec §10.8), and the ledger only ever applies at session start. That is the right place
  // for it when dying means reloading, and the wrong place when it does not: a death
  // alternative brings V back in the same session, so nothing in Cyberbane ever noticed. This
  // is the same promotion, applied now.
  public static func ReportPlayerKilledBy(game: GameInstance, killerRecordID: TweakDBID,
                                          killerAffiliation: CName, weaponCategory: CName) -> Bool {
    let rt = CyberbaneRuntime.Get();
    if !IsDefined(rt) || !rt.IsEnabled() {
      return false;
    }
    if rt.HasSettings() && !rt.GetSettings().deathsRemembered {
      return false;
    }
    let sys = CyberbaneSystem.Get(game);
    let content = CBContent(game);
    if !IsDefined(sys) || !IsDefined(content) || !TDBID.IsValid(killerRecordID) {
      return false;
    }
    let faction = content.FactionForAffiliation(killerAffiliation);
    if Equals(faction, n"") {
      return false;   // not a gang Cyberbane tracks; nothing to pin this on
    }
    return CBPromoteKiller(game, faction, killerRecordID, weaponCategory);
  }


  // ---- Content extension ------------------------------------------------
  public static func RegisterImplant(family: CName, score: Float, visible: Bool, archetype: ECBArchetype) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddImplant(CBMakeImplant(family, score, visible, EnumInt(archetype)));
    }
  }

  public static func RegisterLookTag(tag: CName, score: Float, disguise: Float, factionTag: CName) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddLookTag(CBMakeLookTag(tag, score, disguise, factionTag));
    }
  }

  public static func RegisterLookItem(record: TweakDBID, score: Float, disguise: Float, factionTag: CName) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      let item = new CBLookItemDef();
      item.record = record;
      item.score = score;
      item.disguise = disguise;
      item.factionTag = factionTag;
      content.AddLookItem(item);
    }
  }

  public static func RegisterDeed(def: ref<CBDeedDef>) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddDeed(def);
    }
  }

  public static func RegisterTitle(def: ref<CBTitleDef>) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddTitle(def);
    }
  }

  // ---- Read queries -----------------------------------------------------
  public static func GetRenown(game: GameInstance) -> Float {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return sys.GetScore().GetRenown();
    }
    return 0.0;
  }

  public static func GetDread(game: GameInstance) -> Float {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return sys.GetScore().GetDread();
    }
    return 0.0;
  }

  public static func GetStanding(game: GameInstance, faction: CName) -> Float {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return sys.GetScore().GetStanding(faction);
    }
    return 0.0;
  }

  public static func GetVersion() -> String {
    return CyberbaneVersion();
  }

  // ---- Actions ----------------------------------------------------------
  // Pay a gang you can buy off to drop a hostility / vendetta. Returns true on success.
  public static func BrokerPeace(game: GameInstance, faction: CName) -> Bool {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return CBBrokerPeace(sys, game, faction);
    }
    return false;
  }

  // ---- Extension API, level 1 -------------------------------------
  //
  // Guard every call below with @if(ModuleExists("Cyberbane.Api")). An API function is never removed or renamed; a
  // later level adds its own marker module (Cyberbane.Api2 ...). See README, "For mod authors".

  public static func ApiLevel() -> Int32 {
    return CBApiLevel();
  }

  // Told on Cyberbane's tick, never inside a game event (API/Listeners.reds). Register each session.
  public static func RegisterListener(game: GameInstance, listener: ref<CBListener>) -> Void {
    let book = CBApiBook.Get(game);
    if IsDefined(book) {
      book.Add(listener);
    }
  }

  public static func UnregisterListener(game: GameInstance, listener: ref<CBListener>) -> Void {
    let book = CBApiBook.Get(game);
    if IsDefined(book) {
      book.Remove(listener);
    }
  }

  // How many times this playthrough has been started over; kept in the save. Data keyed by a Rival id belongs to the
  // epoch it was written in.
  public static func PlaythroughEpoch(game: GameInstance) -> Int32 {
    let book = CBApiBook.Get(game);
    return IsDefined(book) ? book.Epoch() : 0;
  }

  // ---- Read-only settings: follow Cyberbane's switches rather than ask the player twice.
  public static func IsEnabled() -> Bool {
    let rt = CyberbaneRuntime.Get();
    return IsDefined(rt) && rt.IsEnabled();
  }

  // Where messages go: 0 the phone, 1 cards, 2 notices, 3 off (ECBMessageDelivery).
  public static func MessagesMode() -> Int32 {
    return EnumInt(CBMessageDelivery());
  }

  // How much you hear: 0 everything, 1 less chatter, 2 rarely (ECBMessageAmount).
  public static func HowMuchYouHear() -> Int32 {
    return EnumInt(CBMessageAmount());
  }

  public static func FactionOn(faction: CName) -> Bool {
    return CBFactionOn(faction);
  }

  // The preset: 0 Subtle, 1 Default, 2 Dramatic, 3 Custom, 4 Blood feud, 5 Turf war, 6 Quiet life (ECBPreset).
  public static func Preset() -> Int32 {
    let rt = CyberbaneRuntime.Get();
    return IsDefined(rt) && rt.HasSettings() ? EnumInt(rt.GetSettings().preset) : EnumInt(ECBPreset.Default);
  }

  // True while "Before you're known" still holds V back (Street Cred under the full mark, with the setting on).
  public static func BeforeYoureKnownHolds(game: GameInstance) -> Bool {
    return CBMercStanding(game) < 1.0;
  }

  public static func GangCodesOn() -> Bool {
    return CBGangCodesOn();
  }

  // ---- People (API/Requests.reds): a handle, or 0 with the reason from GroupWhyNot.
  public static func RequestGroup(game: GameInstance, spec: ref<CBSpawnSpec>) -> Int32 {
    return CBApiRequestGroup(game, spec);
  }

  public static func GroupWhyNot(game: GameInstance, handle: Int32) -> String {
    let reg = CBApiRequests.Get(game);
    return handle == 0 && IsDefined(reg) ? reg.LastWhy() : "";
  }

  public static func GroupAlive(game: GameInstance, handle: Int32) -> Int32 {
    return CBApiGroupAlive(game, handle);
  }

  public static func GroupBodies(game: GameInstance, handle: Int32, out bodies: array<EntityID>) -> Int32 {
    return CBApiGroupBodies(game, handle, bodies);
  }

  // Removed the safe way: never in V's sight, never from a seat; anybody still in view walks off first.
  public static func ReleaseGroup(game: GameInstance, handle: Int32) -> Void {
    CBApiReleaseGroup(game, handle);
  }

  // ---- Map pins, in the CYBERBANE filter box. untilGameSeconds 0 keeps it until Unpin. 0 when markers are off.
  public static func PinPlace(game: GameInstance, captionKey: CName, pos: Vector4, untilGameSeconds: Float) -> Int32 {
    return CBApiPinPlace(game, captionKey, pos, untilGameSeconds);
  }

  public static func Unpin(game: GameInstance, id: Int32) -> Bool {
    let reg = CBApiRequests.Get(game);
    return IsDefined(reg) && reg.RemovePin(game, id);
  }

  // ---- Texts from a contact of the add-on's own (never a story character).
  public static func RegisterSender(game: GameInstance, id: CName, nameKey: CName) -> Void {
    let reg = CBApiRequests.Get(game);
    if IsDefined(reg) && IsNameValid(id) && IsNameValid(nameKey) {
      reg.AddSender(id, nameKey);
    }
  }

  // A text that asks nothing, through the hearsay queue and the player's message settings. False when it was not sent.
  public static func SendAside(game: GameInstance, sender: CName, text: String) -> Bool {
    return CBApiSendAside(game, sender, text);
  }

  // ---- Standing with a reason: honours Freeze reputation and the faction switch; the reason key goes into the History.
  public static func AdjustStanding(game: GameInstance, faction: CName, delta: Float, reasonKey: CName) -> Bool {
    return CBApiAdjustStanding(game, faction, delta, reasonKey);
  }

  // ---- Factions of an add-on's own. A profile to fill in: a gang (crews, codes, cars on the profile) or standing-only
  // (standing, decay and posture with V, never anybody sent). displayKey is the add-on's localization key for its name.
  public static func MakeFactionProfile(id: CName, displayKey: String, isGang: Bool, standingOnly: Bool) -> ref<CBFactionProfile> {
    let p = CBMakeFaction(id, 0.0, 0.0, 1.0, 0.0, isGang && !standingOnly, false, displayKey);
    p.standingOnly = standingOnly;
    p.fieldsSquads = !standingOnly;
    p.hasBodies = !standingOnly;
    p.code = new CBGangCode();
    return p;
  }

  // Appended after Cyberbane's own factions, never among them (their order seeds the turf drift), once per id. Its
  // standing is kept in the save by id like any faction's. Mod Settings cannot grow a switch for it: the add-on's own
  // settings page gives one. False when the id is taken or the profile is empty.
  public static func RegisterFaction(profile: ref<CBFactionProfile>) -> Bool {
    let content = CyberbaneContent.Get();   // built first, so a registered faction always comes after the rest
    if !IsDefined(content) || !IsDefined(profile) || !IsNameValid(profile.id) || IsDefined(content.GetFaction(profile.id)) {
      return false;
    }
    if profile.standingOnly {
      profile.fieldsSquads = false;
      profile.isGang = false;
    }
    if !IsDefined(profile.code) {
      profile.code = new CBGangCode();
    }
    content.AddFaction(profile);
    CBLog.Info(n"Model", s"An add-on registered a faction: \(NameToString(profile.id)).");
    return true;
  }

  // A question with answers, the first one priced (0 for free), answered in the contact's thread on the phone. The add-on
  // hears the answer on its listener with this token. False when messages do not go to the phone, or nothing to ask.
  public static func AskPriced(game: GameInstance, sender: CName, text: String, options: array<String>, price: Int32,
                               token: Int32, listener: ref<CBApiAnswerListener>) -> Bool {
    return CBApiAskPriced(game, sender, text, options, price, token, listener);
  }

  // ---- A convoy that travels (API/Convoy.reds): on paper along its route until V is near, then on the road. A handle,
  // or 0 with the reason from ConvoyWhyNot. State: 0 on paper, 1 boarding, 2 driving, 3 in a fight, 4 done.
  public static func RequestConvoy(game: GameInstance, spec: ref<CBConvoySpec>) -> Int32 {
    return CBApiRequestConvoy(game, spec);
  }

  public static func ConvoyWhyNot(game: GameInstance) -> String {
    let reg = CBApiConvoys.Get(game);
    return IsDefined(reg) ? reg.LastWhy() : "";
  }

  public static func ConvoyState(game: GameInstance, handle: Int32) -> Int32 {
    let reg = CBApiConvoys.Get(game);
    let run = IsDefined(reg) ? reg.Find(handle) : null;
    if IsDefined(run) {
      return run.state;
    }
    // Off the road now: done if it is remembered, -1 for a handle it never had or lost with a load.
    return IsDefined(reg) && reg.Outcome(handle) != CBConvoyOutcomeUnknown() ? CBConvoyDone() : -1;
  }

  public static func ConvoyWhere(game: GameInstance, handle: Int32) -> Vector4 {
    let reg = CBApiConvoys.Get(game);
    let run = IsDefined(reg) ? reg.Find(handle) : null;
    return IsDefined(run) ? CBConvoyWhere(game, run) : new Vector4(0.0, 0.0, 0.0, 0.0);
  }

  // Off the road the safe way: crews unseated first, nobody removed in V's sight.
  public static func ReleaseConvoy(game: GameInstance, handle: Int32) -> Void {
    let reg = CBApiConvoys.Get(game);
    let run = IsDefined(reg) ? reg.Find(handle) : null;
    if IsDefined(run) {
      run.releasing = true;
    }
  }

  // ---- Hub cards (API/HubCards.reds): data the Hub draws in the Gangs page's list. A click on an action is told to the
  // listener on the next settled tick. Keep the card objects and change them as you like; the Hub reads them as it draws.
  public static func RegisterGangsRow(game: GameInstance, card: ref<CBHubCardSpec>, listener: ref<CBHubActionListener>) -> Bool {
    let hub = CBApiHub.Get(game);
    return IsDefined(hub) && hub.Add(card, listener, n"");
  }

  // A page of cards, listed under its title (the Hub's tabs are the game's own, so a page gets no tab of its own).
  public static func RegisterPage(game: GameInstance, page: ref<CBHubPageSpec>, listener: ref<CBHubActionListener>) -> Bool {
    let hub = CBApiHub.Get(game);
    if !IsDefined(hub) || !IsDefined(page) {
      return false;
    }
    let any = false;
    for card in page.cards {
      if hub.Add(card, listener, page.titleKey) {
        any = true;
      }
    }
    return any;
  }

  // ---- Event kinds (API/EventKinds.reds): registered each session, started into Cyberbane's one event slot.
  public static func RegisterEventKind(game: GameInstance, kind: CName, handler: ref<CBEventKindHandler>, captionKey: CName) -> Bool {
    let reg = CBApiEventKinds.Get(game);
    return IsDefined(reg) && reg.Register(kind, handler, captionKey);
  }

  public static func SetEventKindOn(game: GameInstance, kind: CName, on: Bool) -> Void {
    let reg = CBApiEventKinds.Get(game);
    if IsDefined(reg) {
      reg.SetOn(kind, on);
    }
  }

  // False when another event (Cyberbane's or an add-on's) already has the slot, or the kind is unknown or off.
  public static func StartEvent(game: GameInstance, kind: CName, side: CName, at: Vector4, inGameSeconds: Float) -> Bool {
    return CBApiStartEvent(game, kind, side, at, inGameSeconds);
  }

  // ======== API level 2: guard each call with @if(ModuleExists("Cyberbane.Api2")) ========

  // ---- Clocks and the world. OnTick on CBListener comes every couple of seconds on the settled tick.
  public static func WorldStable(game: GameInstance) -> Bool {
    return CBWorldStable(game);
  }

  // A time of day the way Cyberbane writes one in a text ("04:45"), for an add-on announcing its own event.
  public static func ClockWord(gameSeconds: Float) -> String {
    return CBClockWord(gameSeconds);
  }

  // ---- Where V is: Cyberbane's district id (n"" before it knows), and the game's name for the part of town ("Rocky Ridge").
  public static func CurrentDistrict(game: GameInstance) -> CName {
    let sys = CyberbaneSystem.Get(game);
    return IsDefined(sys) ? sys.GetCurrentDistrict() : n"";
  }

  public static func PlaceName(game: GameInstance) -> String {
    return CBSubDistrictLabel(game);
  }

  // Fast-travel points of a district (n"" for V's own) between two distances from V, where somebody can stand: the
  // places Cyberbane holds its street events. How many were found.
  public static func FindPlaces(game: GameInstance, district: CName, minDistance: Float, maxDistance: Float,
                                out positions: array<Vector4>, out names: array<String>) -> Int32 {
    return CBApiFindPlaces(game, district, minDistance, maxDistance, positions, names);
  }

  // ---- An event announced by the add-on's own contact (one registered with RegisterSender); n"" for whoever works V's
  // district, as StartEvent does.
  public static func StartEventFrom(game: GameInstance, kind: CName, side: CName, at: Vector4, inGameSeconds: Float,
                                    sender: CName) -> Bool {
    return CBApiStartEvent(game, kind, side, at, inGameSeconds, sender);
  }

  // ---- Two sides towards each other, body to body, kept as people arrive and taken back when either side is released.
  // Hostile for a raid; neutral for two crews who should leave each other alone. False when either side is not there.
  public static func SetGroupsHostile(game: GameInstance, groupA: Int32, groupB: Int32) -> Bool {
    return CBApiSetSides(game, CBApiSideGroup(), groupA, CBApiSideGroup(), groupB, true);
  }

  public static func SetGroupsNeutral(game: GameInstance, groupA: Int32, groupB: Int32) -> Bool {
    return CBApiSetSides(game, CBApiSideGroup(), groupA, CBApiSideGroup(), groupB, false);
  }

  public static func SetGroupConvoyHostile(game: GameInstance, group: Int32, convoy: Int32) -> Bool {
    return CBApiSetSides(game, CBApiSideGroup(), group, CBApiSideConvoy(), convoy, true);
  }

  public static func SetGroupConvoyNeutral(game: GameInstance, group: Int32, convoy: Int32) -> Bool {
    return CBApiSetSides(game, CBApiSideGroup(), group, CBApiSideConvoy(), convoy, false);
  }

  // ---- A vehicle with nobody in it, placed out of V's sight; wrecked lays the game's visual damage on it. A handle, or 0
  // with the reason from VehicleWhyNot. Removed the safe way by ReleaseVehicle, never from under V.
  public static func RequestVehicle(game: GameInstance, record: TweakDBID, at: Vector4, wrecked: Bool) -> Int32 {
    return CBApiRequestVehicle(game, record, at, wrecked);
  }

  public static func VehicleWhyNot(game: GameInstance) -> String {
    let reg = CBApiVehicles.Get(game);
    return IsDefined(reg) ? reg.LastWhy() : "";
  }

  public static func ReleaseVehicle(game: GameInstance, handle: Int32) -> Void {
    CBApiReleaseVehicle(game, handle);
  }

  // ---- Loot in the game's drop bag at a point near V, scaled to V's level: tier 1 (a crew's) to 5 (the best a Rival
  // carries). The add-on never moves items into V's pockets itself. False when nothing was laid.
  public static func DropLoot(game: GameInstance, pos: Vector4, tier: Int32) -> Bool {
    return CBApiDropLoot(game, pos, tier);
  }

  // ---- A convoy: how it ended (0 running, 1 arrived, 2 broken, 3 got away, 4 released, -1 unknown, as after a load),
  // and its people.
  public static func ConvoyOutcome(game: GameInstance, handle: Int32) -> Int32 {
    let reg = CBApiConvoys.Get(game);
    return IsDefined(reg) ? reg.Outcome(handle) : CBConvoyOutcomeUnknown();
  }

  public static func ConvoyAlive(game: GameInstance, handle: Int32) -> Int32 {
    return CBApiConvoyAlive(game, handle);
  }

  public static func ConvoyBodies(game: GameInstance, handle: Int32, out bodies: array<EntityID>) -> Int32 {
    return CBApiConvoyBodies(game, handle, bodies);
  }

  // ---- A faction's name in the player's language ("Tyger Claws"), and as a label ("the Tyger Claws"). Registered
  // factions answer from their profile's keys.
  public static func FactionName(id: CName) -> String {
    return CBFactionName(id);
  }

  public static func FactionLabel(id: CName) -> String {
    return CBFactionLabel(id);
  }

  // ---- A pin moved to where its subject is now, instead of taken down and put up again.
  public static func MovePin(game: GameInstance, id: Int32, pos: Vector4) -> Bool {
    return CBApiMovePin(game, id, pos);
  }

  // ---- Rivals, read only. Ids start again after Start over (OnPlaythroughReset): key by id together with the epoch.
  public static func RivalIds(game: GameInstance) -> array<Int32> {
    return CBApiRivalIds(game);
  }

  public static func RivalFaction(game: GameInstance, id: Int32) -> CName {
    let r = CBApiRival(game, id);
    return IsDefined(r) ? r.faction : n"";
  }

  // 1 to 4; 0 for an id Cyberbane does not know.
  public static func RivalRank(game: GameInstance, id: Int32) -> Int32 {
    let r = CBApiRival(game, id);
    return IsDefined(r) ? r.rank : 0;
  }

  public static func RivalName(game: GameInstance, id: Int32) -> String {
    return CBApiRivalName(game, id);
  }

  // Still breathing: not slain (one who left town is alive).
  public static func RivalAlive(game: GameInstance, id: Int32) -> Bool {
    let r = CBApiRival(game, id);
    return IsDefined(r) && r.state != EnumInt(ECBRivalState.Slain);
  }

  // ---- A line in the History that moves no standing: a promise kept or broken. The key is the add-on's localization key
  // (it must carry a dash, as every key does); faction n"" for none. False when not filed.
  public static func FileHistory(game: GameInstance, faction: CName, reasonKey: CName) -> Bool {
    return CBApiFileHistory(game, faction, reasonKey);
  }
}
