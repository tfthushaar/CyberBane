// Cyberbane - Rivals with a life
//
// Catchphrases, the street's word on each Rival, their arrival announcement, mercy, kin, calling V out and bodyguards.

public func CBMercyChoiceOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().mercyChoice;
}

public func CBSendWordOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHideoutsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().sendWord);
}

// ---- A catchphrase ---------------------------------------------------------------------------------------

public func CBRivalCatchphrase(r: ref<CBRival>) -> String {
  if !IsDefined(r) {
    return "";
  }
  if CBRivalHasTrait(r, n"Broken") {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-TheVoicesKnowYourName"), CBT(n"Cyberbane-RivalLife-CanTStopWonTStop"), CBT(n"Cyberbane-RivalLife-EverythingSSoLoudYouFirst"));
  }
  if r.source == EnumInt(ECBRivalSource.Betrayer) {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-IWatchedYourBackIKnow"), CBT(n"Cyberbane-RivalLife-YouNeverPaidMeWhatI"),
                         CBT(n"Cyberbane-RivalLife-ILearnedEverythingFromYouIncluding"));
  }
  if r.source == EnumInt(ECBRivalSource.Avenger) {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-BloodPaysForBlood"), CBT(n"Cyberbane-RivalLife-ICarryThemWithMeEvery"), CBT(n"Cyberbane-RivalLife-YouTookOneOfOursI"));
  }
  if r.source == EnumInt(ECBRivalSource.Spared) || r.sparedByV > 0 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-YouShouldHaveFinishedIt"), CBT(n"Cyberbane-RivalLife-MercySTheLastMistakeYou"), CBT(n"Cyberbane-RivalLife-IWokeUpYouWonT"));
  }
  if r.killedV > 0 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-LieDownYouKnowHowThis"), CBT(n"Cyberbane-RivalLife-AgainFineSameEnding"), CBT(n"Cyberbane-RivalLife-IVeDoneThisBefore"));
  }
  if CBRivalHasTrait(r, n"Confident") || CBRivalHasTrait(r, n"PackLeader") {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-NobodyWalksAwayFromMeTwice"), CBT(n"Cyberbane-RivalLife-MyStreetMyRulesMyKill"), CBT(n"Cyberbane-RivalLife-YouReJustAStoryThey"));
  }
  if CBRivalHasTrait(r, n"Scarred") || r.escapes > 0 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-StillBreathingBetThatBugsYou"), CBT(n"Cyberbane-RivalLife-EveryScarSAPromise"), CBT(n"Cyberbane-RivalLife-IKeepComingBackYouKeep"));
  }
  return CBRivalPhrase(r, CBT(n"Cyberbane-RivalLife-NothingPersonalJustBusiness"), CBT(n"Cyberbane-RivalLife-NightCitySTooSmallFor"), CBT(n"Cyberbane-RivalLife-YouMadeItPersonal"));
}

func CBRivalPhrase(r: ref<CBRival>, a: String, b: String, c: String) -> String {
  let k = CBHashIndex(r.id, 61, 3);
  if k == 0 {
    return a;
  }
  return k == 1 ? b : c;
}

// ---- The street's word on them ---------------------------------------------------------------------------

public func CBRivalStreetStatus(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  if !IsDefined(r) {
    return "";
  }
  let book = CBIntelBook.Get(game);
  if IsDefined(book) && book.WordSent(r.id) {
    return CBT(n"Cyberbane-RivalLife-WaitingForYouAtTheirPlace");
  }
  if r.state == EnumInt(ECBRivalState.Debtor) {
    return CBT(n"Cyberbane-RivalLife-OwesYouTheirLifeAndKnows");
  }
  if r.state == EnumInt(ECBRivalState.Retired) && CBWarHoldsRival(game, r.id) {
    return CBT(n"Cyberbane-HubWar-HeldByYourCrew");
  }
  if r.state == EnumInt(ECBRivalState.Retired) {
    return CBT(n"Cyberbane-RivalLife-LeftNightCityNobodyExpectsThem");
  }
  if r.state == EnumInt(ECBRivalState.Slain) {
    return CBT(n"Cyberbane-RivalLife-DeadPeopleStillTalkAboutHow");
  }
  if r.state == EnumInt(ECBRivalState.Dormant) {
    return CBT(n"Cyberbane-RivalLife-GoneQuietNobodySSeenThem");
  }
  if r.id == sys.GetActiveRivalId() || r.state == EnumInt(ECBRivalState.Hunting) {
    return CBT(n"Cyberbane-RivalLife-OutLookingForYouAskingEverybody");
  }
  if r.id == sys.GetLaneRivalId(CBLaneRival()) {
    return CBT(n"Cyberbane-RivalLife-GettingTheirPeopleTogetherYouLl");
  }
  // In the HUD's own words for a countdown (CBWhen). The cooldown is in fast ticks, a real second each, and this called
  // every 150 of them an hour: an in-game hour is about 450, so the page said six hours for two.
  if r.huntTicks > 0 {
    return CBTf(n"Cyberbane-RivalLife-LickingTheirWoundsBack", [s"\(CBWhen(r.huntTicks))"]);
  }
  return CBT(n"Cyberbane-RivalLife-AroundKeepingTheirEarsOpenFor");
}

// ---- The announcement -------------------------------------------------------------------------------------

public class CBAnnounceCallback extends DelayCallback {
  public let game: GameInstance;
  public let speaker: String;
  public let line: String;

  public func Call() -> Void {
    if CBWorldStable(this.game) {
      CBIntelSay(this.game, 3, this.speaker, this.line, 3.5);
    }
  }
}

func CBAnnounceLater(game: GameInstance, speaker: String, line: String, delay: Float) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) || StrLen(line) == 0 {
    return;
  }
  let cb = new CBAnnounceCallback();
  cb.game = game;
  cb.speaker = speaker;
  cb.line = line;
  ds.DelayCallback(cb, delay, false);
}

// When the Rival's people find V: one of them names the Rival, then the Rival says their line. Words only,
// in the game's subtitles; the fight is whatever it already is.
public func CBRivalAnnounce(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  if !IsDefined(r) || !CBMessagesOn() {
    return;
  }
  let content = sys.GetContent();
  let name = CBRivalDisplayName(content, r);
  let crew = CBIntelSpeaker(r.faction);
  let who = CBT(n"Cyberbane-RivalLife-ThatSThem");
  if r.killedV > 0 {
    who = CBTf(n"Cyberbane-RivalLife-ThatSTheOnePutDown", [s"\(name)"]);
  } else {
    if r.escapes > 0 || r.sparedByV > 0 {
      who = CBTf(n"Cyberbane-RivalLife-ThatSThemTheOneWalked", [s"\(name)"]);
    } else {
      if r.source == EnumInt(ECBRivalSource.Avenger) {
        who = CBTf(n"Cyberbane-RivalLife-ThatSWhoDidItWants", [s"\(name)"]);
      }
    }
  }
  CBAnnounceLater(game, crew, who, 0.3);
  CBAnnounceLater(game, name, CBRivalCatchphrase(r), 3.2);
  // And one of their people says it in their own voice (Narrative/Telling.reds, [79]).
  CBSayVoiced(sys, CBNearestTagged(sys, game, n"CB_Escort", CBConfig.PanicRange()), n"enemy_warning");
}

// ---- Kin ------------------------------------------------------------------------------------------------

// What a relative brings against how their family member died (the marks V left on them).
public func CBKinTrait(scarMask: Int32) -> CName {
  if CBMaskHas(scarMask, CBScarFried()) {
    return n"ChromedOut";
  }
  if CBMaskHas(scarMask, CBScarBurned()) {
    return n"Tough";
  }
  if CBMaskHas(scarMask, CBScarCut()) {
    return n"Quick";
  }
  return n"Armored";
}

// ---- Send word, and the call-out --------------------------------------------------------------------------

// They name a place near V and wait there, ready (the hideout machinery, Rivals/Whereabouts.reds). V
// called them out from the Hub, or they called V out instead of coming. False when they cannot be put
// anywhere or are out already.
public func CBSendWord(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, calledOut: Bool) -> Bool {
  let book = CBIntelBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(r) || !IsDefined(book) || !IsDefined(player) || !CBSendWordOn() || CBWhereaboutsForSale(sys, game, r) != 0 {
    return false;
  }
  // Calling V out, they name somewhere that matters if they can ([62]).
  let why = "";
  let s = calledOut ? CBRivalMeaningfulPlace(sys, game, player, r, why) : null;
  if !IsDefined(s) {
    why = "";
    s = CBRivalHideout(sys, game, player, r);
  }
  if !IsDefined(s) {
    if !calledOut {
      CBMenuNote(game, CBT(n"Cyberbane-RivalLife-NowhereNearHereTheyWouldAgree"), 5.0);
    }
    return false;
  }
  let now = CBGameSeconds(game);
  CBMarkLeadTold(sys, s, n"", now);
  book.SendWord(r.id);
  if sys.GetLaneRivalId(CBLaneRival()) == r.id {
    sys.ClearLane(CBLaneRival());
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let place = CBPlacePhrase(s.district, CBSightingPos(s));
  let pin = CBMapMarkersOn() ? CBT(n"Cyberbane-StreetIntel-ItSOnYourMap") : "";
  let meant = StrLen(why) > 0 ? " " + why : "";
  let line = calledOut ? CBTf(n"Cyberbane-RivalLife-YouAndMeILlBe", [s"\(CBCapFirst(place))", s"\(meant)", s"\(pin)", s"\(CBRivalCatchphrase(r))"])
                       : CBTf(n"Cyberbane-RivalLife-GotYourMessageComeAndTry", [s"\(CBCapFirst(place))", s"\(pin)", s"\(CBRivalCatchphrase(r))"]);
  CBPhoneSendTinted(game, name, line, CBHudRed());
  CBFileLog(sys, calledOut ? n"CalledOut" : n"WordSent", now, CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
  CBLog.Info(n"Rivals", s"Rival \(r.id) is waiting at their place (\(calledOut ? "they called V out" : "V sent word")).");
  return true;
}

// A Rival taking their turn calls V out instead, now and then: never the first time they come, and only
// somebody with a name to defend.
public func CBRivalMayCallOut(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(r) || !CBSendWordOn() || r.rank < 2 || r.encounters == 0 || RandF() >= CBConfig.CallOutChance() {
    return false;
  }
  return CBSendWord(sys, game, r, true);
}

// The meeting is off without V finishing it there: their encounter ended some other way, the lead ran out, they were
// left lying at the place, or V forgot them.
public func CBWithdrawWord(game: GameInstance, rivalId: Int32) -> Void {
  let book = CBIntelBook.Get(game);
  if IsDefined(book) && rivalId > 0 {
    book.ClearWord(rivalId);
  }
}

// Finished it at the place they named: the street hears it, and it pays more.
public func CBWordKept(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  let book = CBIntelBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !book.WordSent(r.id) {
    return;
  }
  book.ClearWord(r.id);
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints((25.0 + 10.0 * Cast<Float>(r.rank)) * CBConfig.WordKeptRenownShare() * mult);
  CBTalkFear(sys, game, r.faction, CBConfig.WordKeptFear());
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalLife-TheyNamedThePlaceAndYou", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]), n"");
  }
}

// ---- Bodyguards ------------------------------------------------------------------------------------------

// Somebody senior waiting at their place has their people round them: one for a lieutenant, two for a leader, one more
// when they are expecting V.
public func CBLairGuards(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, r: ref<CBRival>, at: Vector4) -> Void {
  let book = CBIntelBook.Get(game);
  let count = 0;
  if r.rank >= CBConfig.LeaderMinRank() {
    count = 2;
  } else {
    if r.rank >= CBConfig.LieutenantMinRank() {
      count = 1;
    }
  }
  if IsDefined(book) && book.WordSent(r.id) {
    count += 1;
  }
  count = Min(count, CBSpawnRoom(game) - 1);
  let fs = sys.FindFaction(r.faction);
  let intel = CBStreetIntelFor(game);
  if count <= 0 || !IsDefined(fs) || !TDBID.IsValid(fs.sampleRecord) || !IsDefined(intel) {
    return;
  }
  intel.ClearGuards();
  let k = 0;
  let placed = 0;
  while k < 6 && placed < count {
    let ang = Cast<Float>(k) * 1.0472 + 0.3;
    k += 1;
    let snapped: Vector4;
    let spot: Vector4;
    if CBNavSnap(game, at.X + CosF(ang) * 2.6, at.Y + SinF(ang) * 2.6, at.Z, snapped) && CBSettleOnGround(game, snapped, spot)
       && CBStandsWith(game, spot, at, CBConfig.GroundMaxDrop()) {
      let facing = Quaternion.BuildFromDirectionVector(new Vector4(CosF(ang), SinF(ang), 0.0, 0.0));
      let gid: EntityID;
      if CBCreateSpawn(des, fs.sampleRecord, n"", spot, facing, n"CB_Lair", gid) {
        intel.NoteGuard(gid, r.id);
        placed += 1;
      }
    }
  }
  if placed > 0 {
    CBLog.Info(n"Rivals", s"Rival \(r.id) has \(placed) of their people with them.");
  }
}

// ---- Mercy, where they lie (the lines; Reactions/StreetTalk.reds carries the conversation) -------------------

public func CBTalkActSpare() -> Int32 = 27
public func CBTalkActCollect() -> Int32 = 28
public func CBTalkActExile() -> Int32 = 29

@addField(ScriptedPuppet)
public let cbMercyOpen: Bool;

public func CBRivalMercyLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let s = CBTalkMakeLine(CBT(n"Cyberbane-RivalLife-SpareWalkAwayNextTimeI"), CBTalkActSpare(), t"ChoiceCaptionParts.HandshakeIcon");
  ArrayPush(out, s);
  let other = CBTalkRivalForFaction(sys, game, n"", t.rivalId);
  if IsDefined(other) {
    let c = CBTalkMakeLine(CBTf(n"Cyberbane-RivalLife-CollectYouOweMeYourLife", [CBRivalDisplayName(sys.GetContent(), other)]),
                           CBTalkActCollect(), t"ChoiceCaptionParts.BountyHuntIcon");
    c.important = true;
    ArrayPush(out, c);
  }
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalLife-ExileLeaveNightCityTonightDon"), CBTalkActExile(), t"ChoiceCaptionParts.BackOutIcon"));
  // A fourth way to leave them ([55]), and a fifth: set them on somebody of a gang at war with theirs ([57]).
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalLife-HumiliateLookAtYouCrawlingEverybody"), CBTalkActHumiliate(), TDBID.None()));
  let r = sys.FindRivalById(t.rivalId);
  let target = CBFeudTargetFor(sys, game, r);
  if IsDefined(target) {
    let so = CBTalkMakeLine(CBTf(n"Cyberbane-RivalLife-SetOnIsTheOneYou", [CBRivalDisplayName(sys.GetContent(), target)]),
                            CBTalkActSetOn(), t"ChoiceCaptionParts.BountyHuntIcon");
    ArrayPush(out, so);
  }
  // [C1] Work for V (Reactions/Crew.reds): a Rival V has spared before.
  let recruit = CBCrewRecruitLine(sys, game, r);
  if IsDefined(recruit) {
    ArrayPush(out, recruit);
  }
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalLife-NotYetStayDownIHaven"), CBTalkActLeave(), TDBID.None()));
  return out;
}

// What they say, and the mercy decided: the escapee record is settled by the mercy path on its next pass.
public func CBRivalMercyAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                               t: ref<CBTalkTarget>, choice: Int32) -> ref<CBTalkAnswer> {
  let r = sys.FindRivalById(t.rivalId);
  let e = IsDefined(t.npc) ? sys.FindEscapee(t.npc.GetEntityID()) : null;
  if !IsDefined(r) || !IsDefined(e) {
    return CBTalkSay("...", n"");
  }
  if IsDefined(t.npc) {
    CBTalkMarkSent(game, t.npc);   // it is over, whatever was said
    t.npc.cbMercyOpen = false;
  }
  if choice == CBTalkActExile() {
    let chance = CBConfig.ExileBase() - 0.15 * Cast<Float>(r.rank - 1);
    if CBRivalHasTrait(r, n"Shaken") {
      chance += 0.2;
    }
    if CBRivalHasTrait(r, n"HardToScare") || CBRivalHasTrait(r, n"Broken") {
      chance = 0.0;
    }
    e.mercyChosen = true;
    if RandF() < chance {
      e.exiled = true;
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalLife-OkayOkayIMGoneYou"), CBT(n"Cyberbane-RivalLife-FineNightCitySYoursI")), n"");
    }
    CBRivalGiveTrait(r, n"Humiliated");
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalLife-ThisIsMyCityILl"), CBT(n"Cyberbane-RivalLife-RunFromYouNever")), n"");
  }
  e.mercyChosen = true;
  if choice == CBTalkActRecruit() {
    return CBCrewRecruitAnswer(sys, game, r, e);
  }
  if choice == CBTalkActHumiliate() {
    return CBTalkSay(CBRivalHumiliate(sys, game, r, e), n"");
  }
  if choice == CBTalkActSetOn() {
    return CBTalkSay(CBRivalSetOn(sys, game, r), n"");
  }
  if choice == CBTalkActCollect() {
    let i = CBIntelGive(sys, game, player, n"", true, r.id);
    if i.kind == CBIntelNone() {
      return CBTalkSay(CBT(n"Cyberbane-RivalLife-IDonTKnowAnythingWorth"), n"fear_beg");
    }
    return CBTalkSay(CBTf(n"Cyberbane-RivalLife-WeReEven", [CBIntelSpoken(i)]), n"");
  }
  return CBTalkSay(CBPick2(CBTf(n"Cyberbane-RivalLife-IWonTForgetThis", [s"\(CBRivalCatchphrase(r))"]), CBT(n"Cyberbane-RivalLife-WhyDoesnTMatterIOwe")), n"");
}
