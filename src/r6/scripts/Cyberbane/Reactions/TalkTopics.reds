// Cyberbane - What there is to talk about (1.9.7)
//
// Street talk (Reactions/StreetTalk.reds) carries the conversation; this is what is said in it. The point of
// talking to somebody is that they know things V does not, and want things V has:
//
//   Questions   "What's the word?" (the loudest story in this district), "Who runs these streets?" (the
//               turf, how strong its gang is, who wants it), "Anyone looking for me?" (who is coming for V
//               next, from the lanes and the Rivals out hunting: a warning V can use).
//   A Rival     "Heard anything about [Rival]?" A ganger of a gang at war with the Rival's is glad to sell;
//               one of the Rival's own people sells dear, refuses, or warns them. Afraid enough, or a fan,
//               they just say it. Otherwise they name a price, and V can pay, haggle, lean on them or walk.
//               A rare liar sells a story, and the street lets V know later. Paying goes through the same
//               lead the Hub sells (CBRivalHideout, CBMarkLeadTold): the pin, the waiting Rival, the fight.
//   Who V is    a Street Kid, a Nomad or a Corpo has a line of their own with the people who would care,
//               and V's Body and Cool show in a threat that cannot fail on rank-and-file and a parley that
//               holds more often, the way the game shows lifepath and attribute lines.
//   Fans        somebody who knows V's name and likes it may stand V a drink: a few eddies, twice a day.
//
// Everything here only reads the world and writes Cyberbane's own numbers; the only thing it gives V is
// eddies, straight to the inventory. Daily ceilings per gang (CBTalkTally) keep it from being farmed, and
// loading a save does not reset them.

// The questions and the deal (StreetTalk's lines carry these as their act).
public func CBTalkActMenuAsk() -> Int32 = 12
public func CBTalkActAskWord() -> Int32 = 13
public func CBTalkActAskTurf() -> Int32 = 14
public func CBTalkActAskComing() -> Int32 = 15
public func CBTalkActAskRival() -> Int32 = 16
public func CBTalkActMenuBack() -> Int32 = 17
public func CBTalkActLifepath() -> Int32 = 18
public func CBTalkActDealPay() -> Int32 = 19
public func CBTalkActDealHaggle() -> Int32 = 20
public func CBTalkActDealLean() -> Int32 = 21
public func CBTalkActDealForget() -> Int32 = 22

public func CBTalkActBusiness() -> Int32 = 23
public func CBTalkActDealToll() -> Int32 = 24
public func CBTalkActDealCallOff() -> Int32 = 25
public func CBTalkActTurn() -> Int32 = 26

// Which list is up.
public func CBTalkMenuMain() -> Int32 = 0
public func CBTalkMenuAsk() -> Int32 = 1
public func CBTalkMenuDeal() -> Int32 = 2
public func CBTalkMenuBusiness() -> Int32 = 3

// What the deal on the table is for.
public func CBTalkDealLead() -> Int32 = 0
public func CBTalkDealToll() -> Int32 = 1
public func CBTalkDealCallOff() -> Int32 = 2

public func CBTalkHaggleOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkHaggle;
}

// A person's temperament, rolled the first time V talks to them and kept while they are in the world.
public func CBTalkTemperLoyal() -> Int32 = 1
public func CBTalkTemperGreedy() -> Int32 = 2
public func CBTalkTemperChatty() -> Int32 = 3
public func CBTalkTemperLiar() -> Int32 = 4
public func CBTalkTemperPlain() -> Int32 = 5

@addField(ScriptedPuppet)
public let cbTalkTemper: Int32;

// How many conversations V has had with this person (1.9.7): they remember V while they are around.
@addField(ScriptedPuppet)
public let cbTalkTimes: Int32;

public func CBTalkLiarsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkLiars;
}

public func CBTalkTemper(npc: wref<ScriptedPuppet>) -> Int32 {
  if !IsDefined(npc) {
    return CBTalkTemperPlain();
  }
  if npc.cbTalkTemper == 0 {
    let roll = RandRange(0, 100);
    if roll < 15 {
      npc.cbTalkTemper = CBTalkTemperLoyal();
    } else {
      if roll < 45 {
        npc.cbTalkTemper = CBTalkTemperGreedy();
      } else {
        if roll < 70 {
          npc.cbTalkTemper = CBTalkTemperChatty();
        } else {
          if roll < 76 && CBTalkLiarsOn() {
            npc.cbTalkTemper = CBTalkTemperLiar();
          } else {
            npc.cbTalkTemper = CBTalkTemperPlain();
          }
        }
      }
    }
  }
  return npc.cbTalkTemper;
}

// V's attribute, as the stats system has it (Body is the Strength stat).
public func CBTalkStat(game: GameInstance, stat: gamedataStatType) -> Float {
  let player = GetPlayer(game);
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(player) || !IsDefined(stats) {
    return 0.0;
  }
  return stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), stat);
}

// ---- The lists ----------------------------------------------------------------------------------------

// The questions V can ask this person. Each once; asked again, it is dimmed and they say so.
public func CBTalkQuestionLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let done = IsDefined(t.npc) ? t.npc.cbTalkDone : 0;
  let w = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-AskWhatSTheWordOn"), CBTalkActAskWord(), t"ChoiceCaptionParts.ClueIcon");
  w.said = CBMaskHas(done, CBTalkActAskWord());
  ArrayPush(out, w);
  let tf = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-AskWhoRunsTheseStreets"), CBTalkActAskTurf(), t"ChoiceCaptionParts.GangWatchIcon");
  tf.said = CBMaskHas(done, CBTalkActAskTurf());
  ArrayPush(out, tf);
  let c = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-AskAnyoneLookingForMe"), CBTalkActAskComing(), t"ChoiceCaptionParts.ReinforcementIcon");
  c.said = CBMaskHas(done, CBTalkActAskComing());
  ArrayPush(out, c);
  let home = CBGangHomeTalkLine(t);
  if IsDefined(home) {
    ArrayPush(out, home);
  }
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-BackSomethingElse"), CBTalkActMenuBack(), TDBID.None()));
  return out;
}

// The deal on the table. Pay is greyed when V cannot cover it.
public func CBTalkDealLines(game: GameInstance, t: ref<CBTalkTarget>, price: Int32, haggled: Bool, kind: Int32) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let what = CBTf(n"Cyberbane-TalkTopics-PayEb", [s"\(price)"]);
  if kind == CBTalkDealToll() {
    what = CBTf(n"Cyberbane-TalkTopics-PayEbForSafePassage", [s"\(price)"]);
  } else {
    if kind == CBTalkDealCallOff() {
      what = CBTf(n"Cyberbane-TalkTopics-PayEbMakeTheCall", [s"\(price)"]);
    }
  }
  let pay = CBTalkMakeLine(what, CBTalkActDealPay(), t"ChoiceCaptionParts.PayIcon");
  pay.inactive = CBTalkMoney(game) < price;
  ArrayPush(out, pay);
  if !haggled {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-HaggleThatSTooMuch"), CBTalkActDealHaggle(), t"ChoiceCaptionParts.HandshakeIcon"));
  }
  // Leaning on somebody for a name works; nobody can be frightened into calling off a crew.
  if kind == CBTalkDealLead() {
    let body = CBTalkStat(game, gamedataStatType.Strength) >= CBConfig.TalkAttributeCheck();
    ArrayPush(out, CBTalkMakeLine(CBTf(n"Cyberbane-TalkTopics-OrYouCouldJustTellMe", [(body ? CBT(n"Cyberbane-StreetPay-Body") : CBT(n"Cyberbane-StreetPay-Intimidate"))]), CBTalkActDealLean(),
                                  t"ChoiceCaptionParts.GrappleIcon"));
  }
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-ForgetItNeverMind"), CBTalkActDealForget(), t"ChoiceCaptionParts.BackOutIcon"));
  return out;
}

// ---- Business: what a gang at war with V will sell (1.9.7) ------------------------------------------------

// What a deal costs from this person: a base moved by what they are like and how afraid they are.
func CBTalkPriceFor(t: ref<CBTalkTarget>, base: Float) -> Int32 {
  let price = base;
  if CBTalkTemper(t.npc) == CBTalkTemperGreedy() {
    price *= 1.3;
  }
  if t.mood == CBTalkAfraid() {
    price *= 0.6;
  }
  return Max(100, RoundF(price / 50.0) * 50);
}

// Safe passage: a gang at war with V whose street people would draw on V on sight (Reactions/Director.reds,
// TryGangHostile), and no passage already bought. 0 when there is none to sell.
public func CBTalkTollPrice(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> Int32 {
  if Equals(t.faction, n"") || t.cop || !CBFactionFieldsSquads(t.faction) || CBTwrActive() {
    return 0;
  }
  let score = sys.GetScore();
  if !IsDefined(score) || !Equals(score.GetPosture(t.faction), ECBPosture.Vendetta)
     || sys.TollActive(t.faction, CBGameSeconds(game)) {
    return 0;
  }
  let quote = CBPeaceQuote(sys, game, t.faction);
  let base = quote > 0 ? Cast<Float>(quote) * CBConfig.TalkTollShare() : CBConfig.TalkTollMin();
  return CBTalkPriceFor(t, MaxF(base, CBConfig.TalkTollMin()));
}

// A crew of theirs on its way to V, or being put together for V.
public func CBTalkCrewComing(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  return NotEquals(faction, n"")
         && (Equals(sys.GetPendingSquadFaction(), faction) || Equals(sys.GetLaneTarget(CBLaneSquad()), faction));
}

public func CBTalkCallOffPrice(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> Int32 {
  if Equals(t.faction, n"") || t.cop || !CBTalkCrewComing(sys, t.faction) {
    return 0;
  }
  let quote = CBPeaceQuote(sys, game, t.faction);
  let base = quote > 0 ? Cast<Float>(quote) * CBConfig.TalkCallOffShare() : CBConfig.TalkCallOffMin();
  return CBTalkPriceFor(t, MaxF(base, CBConfig.TalkCallOffMin()));
}

public func CBTalkHasBusiness(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> Bool {
  return CBTalkTollPrice(sys, game, t) > 0 || CBTalkCallOffPrice(sys, game, t) > 0;
}

public func CBTalkBusinessLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let done = IsDefined(t.npc) ? t.npc.cbTalkDone : 0;
  if CBTalkTollPrice(sys, game, t) > 0 {
    let toll = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-PayWhatDoesItCostTo"), CBTalkActDealToll(), t"ChoiceCaptionParts.PayIcon");
    toll.said = CBMaskHas(done, CBTalkActDealToll());
    ArrayPush(out, toll);
  }
  if CBTalkCallOffPrice(sys, game, t) > 0 {
    let off = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-PayCallOffTheCrewYou"), CBTalkActDealCallOff(), t"ChoiceCaptionParts.ReinforcementIcon");
    off.said = CBMaskHas(done, CBTalkActDealCallOff());
    off.important = !off.said;
    ArrayPush(out, off);
  }
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-BackSomethingElse"), CBTalkActMenuBack(), TDBID.None()));
  return out;
}

public func CBTalkAnswerBusiness(t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  if t.mood == CBTalkAfraid() {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-BusinessYeahBusinessIsGoodWhat"), CBT(n"Cyberbane-TalkTopics-AnythingNameIt")), n"");
  }
  return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-MoneyTalksGoOn"), CBT(n"Cyberbane-TalkTopics-IMListening"), CBT(n"Cyberbane-TalkTopics-BusinessWithYouDependsWhatIt")), n"");
}

public func CBTalkAskToll(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkOffer> {
  let o = new CBTalkOffer();
  let price = CBTalkTollPrice(sys, game, t);
  if price <= 0 {
    o.answer = CBTalkSay(CBT(n"Cyberbane-TalkTopics-NothingToSellYouNotToday"), n"");
    return o;
  }
  if CBTalkTemper(t.npc) == CBTalkTemperLoyal() && t.mood == CBTalkHostile() {
    o.answer = CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-YourMoneySNoGoodHere"), CBT(n"Cyberbane-TalkTopics-YouCanTBuyYourWay")), n"bump");
    return o;
  }
  o.price = price;
  let hours = RoundF(CBConfig.TalkTollHours());
  o.answer = CBTalkSay(CBPick2(CBTf(n"Cyberbane-TalkTopics-EbAndNobodyOfOursTouches", [s"\(price)", s"\(hours)"]),
                                     CBTf(n"Cyberbane-TalkTopics-WalkOurStreetsInOnePiece", [s"\(price)", s"\(hours)"])), n"");
  return o;
}

public func CBTalkAskCallOff(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkOffer> {
  let o = new CBTalkOffer();
  let price = CBTalkCallOffPrice(sys, game, t);
  if price <= 0 {
    o.answer = CBTalkSay(CBT(n"Cyberbane-TalkTopics-WhatCrewNobodySComingNot"), n"");
    return o;
  }
  if CBTalkTemper(t.npc) == CBTalkTemperLoyal() && t.mood != CBTalkAfraid() {
    o.answer = CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-ThoseAreMyPeopleHopeThey"), CBT(n"Cyberbane-TalkTopics-CallThemOffIDRather")), n"bump");
    return o;
  }
  o.price = price;
  o.answer = CBTalkSay(CBPick2(CBTf(n"Cyberbane-TalkTopics-TheyReAlreadyMovingEbAnd", [s"\(price)"]),
                                     CBTf(n"Cyberbane-TalkTopics-EbAndITellThemYou", [s"\(price)"])), n"");
  return o;
}

public func CBTalkTakeMoney(game: GameInstance, player: ref<PlayerPuppet>, price: Int32) -> Bool {
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(ts) || !IsDefined(player) || CBTalkMoney(game) < price {
    return false;
  }
  ts.RemoveItem(player, ItemID.FromTDBID(t"Items.money"), price);
  return true;
}

public func CBTalkDealPayToll(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                              t: ref<CBTalkTarget>, price: Int32) -> ref<CBTalkAnswer> {
  if !CBTalkTakeMoney(game, player, price) {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-ComeBackWhenYouVeGot"), CBT(n"Cyberbane-TalkTopics-ThatSNotTheNumberChoom")), n"");
  }
  let now = CBGameSeconds(game);
  sys.AddToll(t.faction, now + CBConfig.TalkTollHours() * 3600.0);
  CBFileLog(sys, n"TalkToll", now, CBEventDistrict(sys, game), t.faction, Cast<Float>(price));
  CBLog.Info(n"Talk", s"V bought safe passage from \(NameToString(t.faction)) for \(price)eb.");
  // Starting with the one V paid, here and now; the rest of theirs as V passes them (Reactions/Director.reds, KeepCalm).
  CBCalmTowardsV(game, t.npc, 2);
  return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-DoneWordGoesRoundYouWalk"),
                                  CBT(n"Cyberbane-TalkTopics-PleasureKeepYourHeadDownAnd")), n"");
}

public func CBTalkDealPayCallOff(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                                 t: ref<CBTalkTarget>, price: Int32) -> ref<CBTalkAnswer> {
  if !CBTalkCrewComing(sys, t.faction) {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-TooLateOrTheyNeverLeft"), n"");
  }
  if !CBTalkTakeMoney(game, player, price) {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-ComeBackWhenYouVeGot"), CBT(n"Cyberbane-TalkTopics-ThatSNotTheNumberChoom")), n"");
  }
  // The same calling-off a pay-off does (Economy/Peace.reds), for the one crew; the grudge stays.
  if Equals(sys.GetPendingSquadFaction(), t.faction) {
    sys.ClearPendingSquad();
  }
  if Equals(sys.GetLaneTarget(CBLaneSquad()), t.faction) {
    sys.ClearLane(CBLaneSquad());
  }
  CBFileLog(sys, n"TalkCallOff", CBGameSeconds(game), CBEventDistrict(sys, game), t.faction, Cast<Float>(price));
  CBLog.Info(n"Talk", s"V paid one of \(NameToString(t.faction)) \(price)eb to call off their crew.");
  CBCalmTowardsV(game, t.npc, 1);   // the one who took V's money is not the one to draw on V (2.6.0)
  return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-AlrightILlTellThemYou"),
                                  CBT(n"Cyberbane-TalkTopics-DoneTheyLlTurnAroundNext")), n"");
}

// The line only this V has with this person, or null: lifepath, shown with the game's lifepath icon.
public func CBTalkLifepathLine(game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkLine> {
  let lp = CBPlayerLifePath(game);
  let f = t.faction;
  let gang = NotEquals(f, n"") && !t.cop;
  let line: ref<CBTalkLine>;
  if lp == EnumInt(gamedataLifePath.StreetKid) && gang && !CBTalkIsCorp(f) {
    line = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-StreetKidCameUpOnThese"), CBTalkActLifepath(), t"ChoiceCaptionParts.LifepathStreetKid");
  }
  if lp == EnumInt(gamedataLifePath.Nomad) && (Equals(f, n"Aldecaldos") || Equals(f, n"Wraiths")) {
    line = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-NomadOutInTheBadlandsWe"), CBTalkActLifepath(), t"ChoiceCaptionParts.LifepathNomad");
  }
  if lp == EnumInt(gamedataLifePath.Corporate) && CBTalkIsCorp(f) {
    line = CBTalkMakeLine(CBT(n"Cyberbane-TalkTopics-CorpoIKnowHowYourBosses"), CBTalkActLifepath(), t"ChoiceCaptionParts.LifepathCorpo");
  }
  if IsDefined(line) && IsDefined(t.npc) {
    line.said = CBMaskHas(t.npc.cbTalkDone, CBTalkActLifepath());
  }
  return line;
}

func CBTalkIsCorp(faction: CName) -> Bool {
  return Equals(faction, n"Arasaka") || Equals(faction, n"Militech") || Equals(faction, n"KangTao");
}

public func CBTalkMoney(game: GameInstance) -> Int32 {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return 0;
  }
  return ts.GetItemQuantity(player, ItemID.FromTDBID(t"Items.money"));
}

// ---- Answers ------------------------------------------------------------------------------------------

// "Got a minute?": how they take being asked.
public func CBTalkAnswerMenuAsk(t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  if t.cop {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-MakeItQuickCitizen"), CBT(n"Cyberbane-TalkTopics-DependsWhatYouReAsking")), n"");
  }
  if t.mood == CBTalkFriendly() {
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-SureChoomWhatDoYouNeed"), CBT(n"Cyberbane-TalkTopics-ForYouAlways"), CBT(n"Cyberbane-TalkTopics-Shoot")), n"greeting");
  }
  if t.mood == CBTalkAfraid() {
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-WWhatDoYouWantTo"), CBT(n"Cyberbane-TalkTopics-IDonTKnowAnythingI"), CBT(n"Cyberbane-TalkTopics-OkayOkayWhat")), n"fear_beg");
  }
  if t.mood == CBTalkHostile() {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-TalkFast"), CBT(n"Cyberbane-TalkTopics-YouVeGotAMinuteLess")), n"");
  }
  return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-MakeItQuick"), CBT(n"Cyberbane-TalkTopics-Depends"), CBT(n"Cyberbane-TalkTopics-WhatAbout")), n"");
}

// "What's the word on the street?"
public func CBTalkAnswerWord(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, again: Bool) -> ref<CBTalkAnswer> {
  if again {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-ToldYouAlreadyThatSAll"), n"");
  }
  let r = CBWhisperRumor(sys, game);
  if IsDefined(r) {
    return CBTalkSay(CBRumorPhrase(sys, r), n"");
  }
  // Where V is standing, if it remembers something (Model/StreetBook.reds, 2.3.1).
  let st = CBReadStreet(sys, game, t.faction);
  if Equals(st.placeKind, n"Massacre") {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-YouReStandingOnItThat"),
                             CBT(n"Cyberbane-TalkTopics-RightHereBodiesEverywhereNotLong")), n"");
  }
  if Equals(st.placeKind, n"BossKill") && StrLen(CBFactionLabel(st.placeGang)) > 0 {
    return CBTalkSay(CBTf(n"Cyberbane-TalkTopics-ThisCornerLostTheirBossRight", [s"\(CBCapFirst(CBFactionLabel(st.placeGang)))"]), n"");
  }
  if st.wounded {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-WordIsYouReBleedingChoom"),
                             CBT(n"Cyberbane-TalkTopics-TheWordIsThereSBlood")), n"");
  }
  let district = sys.GetCurrentDistrict();
  let book = CBTurfBook.Get(game);
  let index = CBDistrictIndex(district);
  if IsDefined(book) && index >= 0 && NotEquals(book.Challenger(index), n"") {
    let who = CBFactionLabel(book.Challenger(index));
    if StrLen(who) > 0 {
      return CBTalkSay(CBTf(n"Cyberbane-TalkTopics-ArePushingInRoundHereWon", [s"\(CBCapFirst(who))"]), n"");
    }
  }
  if CBIsLayingLow(sys, CBGameSeconds(game)) {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-QuietLatelyTooQuiet"), CBT(n"Cyberbane-TalkTopics-NothingPeopleKeepWaitingForSomething")), n"");
  }
  return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-SameOldNightCitySomebodyS"), CBT(n"Cyberbane-TalkTopics-NothingWorthTheBreath"), CBT(n"Cyberbane-TalkTopics-CorposUpTopTheRestOf")), n"");
}

// "Who runs these streets?"
public func CBTalkAnswerTurf(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, again: Bool) -> ref<CBTalkAnswer> {
  if again {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-SameAsFiveMinutesAgo"), n"");
  }
  let district = sys.GetCurrentDistrict();
  let holder = NotEquals(district, n"") ? CBTurfHolder(sys, game, district) : n"";
  // V's own crew (Model/CrewTurf.reds, 2.7.6): the street knows whose people these are, and says so to V's face.
  if CBIsCrewTurf(holder) {
    return CBTalkSay(CBCrewTurfLine(), n"");
  }
  let label = CBFactionLabel(holder);
  if StrLen(label) == 0 {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-NobodyOwnsTheseStreetsNotReally"), CBT(n"Cyberbane-TalkTopics-DependsWhoSGotTheMost")), n"");
  }
  let line = "";
  if Equals(holder, t.faction) {
    line = CBPick2(CBT(n"Cyberbane-TalkTopics-WeDoDonTForgetIt"), CBT(n"Cyberbane-TalkTopics-YouReStandingOnOurs"));
  } else {
    line = CBTf(n"Cyberbane-TalkTopics-RunIt", [s"\(CBCapFirst(label))"]);
  }
  if CBTurfWarsOn() {
    let band = CBGangStrengthBand(CBGangStrength(sys, holder));
    if band == 0 {
      line += CBT(n"Cyberbane-TalkTopics-WhatSLeftOfThemAnyway");
    } else {
      if band == 1 {
        line += CBT(n"Cyberbane-TalkTopics-TheyReBleedingThoughEverybodyCan");
      }
    }
    let book = CBTurfBook.Get(game);
    let index = CBDistrictIndex(district);
    if IsDefined(book) && index >= 0 && NotEquals(book.Challenger(index), n"") {
      let who = CBFactionLabel(book.Challenger(index));
      if StrLen(who) > 0 {
        line += CBTf(n"Cyberbane-TalkTopics-WantIt", [s"\(CBCapFirst(who))"]);
      }
    }
  }
  let score = sys.GetScore();
  if IsDefined(score) && NotEquals(holder, t.faction) {
    let posture = score.GetPosture(holder);
    if Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly) {
      line += CBT(n"Cyberbane-TalkTopics-TheyLikeYouFarAsI");
    } else {
      if Equals(posture, ECBPosture.Vendetta) {
        line += CBT(n"Cyberbane-TalkTopics-AndTheyWantYouDeadSo");
      }
    }
  }
  return CBTalkSay(line, n"");
}

// "Anyone looking for me?" From what is actually on its way: the lanes, the crews already sent, the Rivals
// out hunting.
public func CBTalkAnswerComing(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, again: Bool) -> ref<CBTalkAnswer> {
  if again {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-LikeISaidWatchYourself"), n"");
  }
  let content = sys.GetContent();
  let ownGang = NotEquals(t.faction, n"") && !t.cop;
  // A crew already on its way.
  let squad = sys.GetPendingSquadFaction();
  if NotEquals(squad, n"") {
    return CBTalkSay(CBTalkComingLine(t, squad, CBT(n"Cyberbane-TalkTopics-ACrewOfGIsOn"), ownGang), n"");
  }
  let apex = sys.GetPendingApexFaction();
  if NotEquals(apex, n"") {
    return CBTalkSay(CBTalkComingLine(t, apex, CBT(n"Cyberbane-TalkTopics-GAreSendingTheirBestAfter"), ownGang), n"");
  }
  // One getting ready.
  let laneGang = sys.GetLaneTarget(CBLaneSquad());
  if NotEquals(laneGang, n"") {
    let when = sys.GetLaneTicks(CBLaneSquad()) <= 120 ? CBT(n"Cyberbane-TalkTopics-AnyMinuteNow") : CBT(n"Cyberbane-TalkTopics-Soon");
    return CBTalkSay(CBTalkComingLine(t, laneGang, CBTf(n"Cyberbane-TalkTopics-GArePuttingACrewTogether", [when]), ownGang), n"");
  }
  let laneRival = sys.GetLaneRivalId(CBLaneRival());
  if laneRival > 0 {
    let r = sys.FindRivalById(laneRival);
    if IsDefined(r) {
      return CBTalkSay(CBTf(n"Cyberbane-TalkTopics-IsGettingReadyToComeFor", [s"\(CBRivalDisplayName(content, r))"]), n"");
    }
  }
  // A Rival out looking.
  for r in sys.GetRivals() {
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Hunting) {
      return CBTalkSay(CBPick2(CBTf(n"Cyberbane-TalkTopics-IsOutLookingForYouAsking", [s"\(CBRivalDisplayName(content, r))"]),
                                     CBTf(n"Cyberbane-TalkTopics-HeardWantsAWordWithYou", [s"\(CBRivalDisplayName(content, r))"])), n"");
    }
  }
  return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-NobodyIVeHeardOfLucky"), CBT(n"Cyberbane-TalkTopics-NotThatIKnowDoesnT"), CBT(n"Cyberbane-TalkTopics-QuietFarAsIHear")), n"");
}

// A gang's name put into a line (%g lower case, %G capitalised); a ganger of that gang says it their way.
func CBTalkComingLine(t: ref<CBTalkTarget>, gang: CName, line: String, ownGang: Bool) -> String {
  let label = CBFactionLabel(gang);
  if StrLen(label) == 0 {
    label = CBT(n"Cyberbane-TalkTopics-Somebody");
  }
  if ownGang && Equals(gang, t.faction) {
    if t.mood == CBTalkAfraid() || t.mood == CBTalkFriendly() {
      return CBT(n"Cyberbane-TalkTopics-OursAreComingForYouYou");
    }
    return CBT(n"Cyberbane-TalkTopics-YouLlFindOut");
  }
  return StrReplaceAll(StrReplaceAll(line, "%G", CBCapFirst(label)), "%g", label);
}

// The Rival this person could talk about: one of their own gang's, then one of a gang at war with theirs,
// then for somebody of no gang, any Rival whose whereabouts are for sale. Null when there is none.
public func CBTalkRivalFor(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBRival> {
  if !IsDefined(sys) || !CBHideoutsOn() || t.cop {
    return null;
  }
  if t.leadId > 0 {
    let own = sys.FindRivalById(t.leadId);
    if IsDefined(own) && CBWhereaboutsForSale(sys, game, own) == 0 {
      return own;
    }
  }
  let content = sys.GetContent();
  let enemies: array<CName>;
  if NotEquals(t.faction, n"") {
    enemies = CBGangRivalsOf(content, t.faction);
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && CBWhereaboutsForSale(sys, game, r) == 0
       && (Equals(t.faction, n"") || ArrayContains(enemies, r.faction)) {
      return r;
    }
  }
  return null;
}

// What a lead from this person costs: the Hub's price, moved by who they are to the Rival, how they stand
// with V, how afraid they are and what they are like.
public func CBTalkLeadPrice(sys: ref<CyberbaneSystem>, t: ref<CBTalkTarget>, r: ref<CBRival>) -> Int32 {
  let price = Cast<Float>(CBWhereaboutsPrice(r));
  if Equals(t.faction, r.faction) {
    price *= CBConfig.TalkPriceOwnGang();
  } else {
    price *= NotEquals(t.faction, n"") ? CBConfig.TalkPriceEnemyGang() : CBConfig.TalkPriceCivilian();
  }
  let temper = CBTalkTemper(t.npc);
  if temper == CBTalkTemperGreedy() {
    price *= 1.4;
  } else {
    if temper == CBTalkTemperChatty() {
      price *= 0.85;
    }
  }
  if t.mood == CBTalkFriendly() {
    price *= 0.7;
  } else {
    if t.mood == CBTalkHostile() {
      price *= 1.3;
    } else {
      if t.mood == CBTalkAfraid() {
        price *= 0.5;
      }
    }
  }
  return Max(100, RoundF(price / 50.0) * 50);
}

// The offer that comes back from asking about a Rival.
public class CBTalkOffer {
  public let answer: ref<CBTalkAnswer>;
  public let rivalId: Int32;
  public let price: Int32;     // > 0: a deal is on the table
}

// "Heard anything about [Rival]?"
public func CBTalkAskRival(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                           t: ref<CBTalkTarget>, again: Bool) -> ref<CBTalkOffer> {
  let o = new CBTalkOffer();
  if again {
    o.answer = CBTalkSay(CBT(n"Cyberbane-TalkTopics-ISaidWhatISaid"), n"");
    return o;
  }
  let r = CBTalkRivalFor(sys, game, t);
  if !IsDefined(r) {
    o.answer = CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-HavenTHeardAThingWorth"), CBT(n"Cyberbane-TalkTopics-NobodySTalkingAboutThemNot")), n"");
    return o;
  }
  let content = sys.GetContent();
  let name = CBRivalDisplayName(content, r);
  let tally = CBTalkTallyFor(sys, game, t.faction);
  if !IsDefined(tally) || tally.leaks >= CBConfig.TalkLeaksPerDay() {
    o.answer = CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-AlreadySaidTooMuchToday"), CBT(n"Cyberbane-TalkTopics-AskMeTomorrowTooManyEars")), n"");
    return o;
  }
  let temper = CBTalkTemper(t.npc);
  let ownGang = Equals(t.faction, r.faction);
  // One of their own, loyal: nothing, and they may warn the Rival.
  if ownGang && temper == CBTalkTemperLoyal() && t.mood != CBTalkAfraid() {
    if RandF() < CBConfig.TalkLoyalWarnChance() && r.state != EnumInt(ECBRivalState.Hunting) {
      r.state = EnumInt(ECBRivalState.Hunting);
      CBPhoneSendTinted(game, name, CBPick2(CBT(n"Cyberbane-TalkTopics-HeardYouVeBeenAskingAbout"),
                                                   CBT(n"Cyberbane-TalkTopics-OneOfMineSaysYouWere")), CBHudRed());
      CBLog.Info(n"Talk", s"A loyal ganger warned rival \(r.id) that V was asking.");
    }
    o.answer = CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-IDonTSellOutMy"), CBT(n"Cyberbane-TalkTopics-AskMeAgainAndSeeWhat"), CBT(n"Cyberbane-TalkTopics-YouThinkIDRatWalk")), n"bump");
    return o;
  }
  // Afraid enough, or a fan of V's who has nothing to lose by it: they just say it.
  let civilianFan = Equals(t.faction, n"") && (t.mood == CBTalkFriendly() || t.mood == CBTalkAfraid());
  let scared = t.mood == CBTalkAfraid() && CBTalkNerveGap(t) > 0.2;
  if civilianFan || scared {
    o.answer = CBTalkSay(CBTalkGiveLead(sys, game, player, t, r, false), scared ? n"fear_beg" : n"");
    return o;
  }
  o.rivalId = r.id;
  o.price = CBTalkLeadPrice(sys, t, r);
  let p = o.price;
  if temper == CBTalkTemperGreedy() {
    o.answer = CBTalkSay(CBPick2(CBTf(n"Cyberbane-TalkTopics-ForYouEddiesFirst", [s"\(p)"]), CBTf(n"Cyberbane-TalkTopics-AndIRememberEverything", [s"\(p)"])), n"");
  } else {
    if ownGang {
      o.answer = CBTalkSay(CBPick2(CBTf(n"Cyberbane-TalkTopics-SellingOutMyOwnCosts", [s"\(p)"]), CBTf(n"Cyberbane-TalkTopics-AndYouNeverHeardMyName", [s"\(p)"])), n"");
    } else {
      o.answer = CBTalkSay(CBPick3(CBTf(n"Cyberbane-TalkTopics-YeahIKnowWhere", [s"\(name)", s"\(p)"]), CBTf(n"Cyberbane-TalkTopics-ThatOneAndTheyReYours", [s"\(p)"]), CBTf(n"Cyberbane-TalkTopics-WorthEveryEddieTrustMe", [s"\(p)"])), n"");
    }
  }
  return o;
}

// The lead itself, through the same path as the Hub's purchase. A liar's is a story instead: a place with
// nobody there and no pin, and the street lets V know a while later. Returns what they say.
public func CBTalkGiveLead(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                           t: ref<CBTalkTarget>, r: ref<CBRival>, paid: Bool) -> String {
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let tally = CBTalkTallyFor(sys, game, t.faction);
  if IsDefined(tally) {
    tally.leaks += 1;
  }
  let now = CBGameSeconds(game);
  if CBTalkTemper(t.npc) == CBTalkTemperLiar() {
    let fake = CBDistrictAt(RandRange(0, CBDistrictCount()));
    // The street lets V know, a while later.
    let ds = GameInstance.GetDelaySystem(game);
    if IsDefined(ds) {
      let cb = new CBTalkLiarCallback();
      cb.game = game;
      cb.body = CBTf(n"Cyberbane-TalkTopics-ThatOneWhoSoldYouS", [s"\(name)"]);
      ds.DelayCallback(cb, CBConfig.TalkLiarRevealSeconds(), false);
    }
    CBLog.Info(n"Talk", s"A liar sold V a story about rival \(r.id).");
    return CBPick2(CBTf(n"Cyberbane-TalkTopics-SHoledUpSwearIt", [s"\(name)", s"\(CBPlacePhrase(fake))"]), CBTf(n"Cyberbane-TalkTopics-LastIHeardWasGoLook", [s"\(name)", s"\(CBPlacePhrase(fake))"]));
  }
  let s = CBRivalHideout(sys, game, player, r);
  if !IsDefined(s) {
    return CBT(n"Cyberbane-TalkTopics-TheyMoveAroundCanTPin");
  }
  CBMarkLeadTold(sys, s, t.faction, now);
  CBFileLog(sys, n"Informant", now, CBEventDistrict(sys, game), t.faction, Cast<Float>(r.id));
  CBLog.Info(n"Talk", s"Rival \(r.id) given up in the street (paid: \(paid)).");
  let place = CBPlacePhrase(s.district, CBSightingPos(s));
  let pin = CBMapMarkersOn() ? CBT(n"Cyberbane-StreetIntel-ItSOnYourMap") : "";
  return CBPick3(CBTf(n"Cyberbane-TalkTopics-SHoledUp", [s"\(name)", s"\(place)", s"\(pin)"]), CBTf(n"Cyberbane-TalkTopics-LyingLowDonTSayWhere", [s"\(name)", s"\(place)", s"\(pin)"]),
                        CBTf(n"Cyberbane-TalkTopics-SawLastNight", [s"\(name)", s"\(place)", s"\(pin)"]));
}

public class CBTalkLiarCallback extends DelayCallback {
  public let game: GameInstance;
  public let body: String;

  public func Call() -> Void {
    if CBWorldStable(this.game) {
      CBHearsayFromStreet(this.game, this.body, n"");
    }
  }
}

// What somebody who knows where a Rival is lying low lets drop on hello. "" when they have nothing to sell,
// already sold it today, or are loyal to the Rival.
public func CBTalkTipHint(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> String {
  if t.cop || !IsDefined(t.npc) || CBMaskHas(t.npc.cbTalkDone, CBTalkActAskRival()) {
    return "";
  }
  let r = CBTalkRivalFor(sys, game, t);
  if !IsDefined(r) || (Equals(r.faction, t.faction) && CBTalkTemper(t.npc) == CBTalkTemperLoyal()) {
    return "";
  }
  let tally = CBTalkTallyFor(sys, game, t.faction);
  if !IsDefined(tally) || tally.leaks >= CBConfig.TalkLeaksPerDay() {
    return "";
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  return CBPick3(CBTf(n"Cyberbane-TalkTopics-HeardYouReAfterIMight", [s"\(name)"]),
                        CBTf(n"Cyberbane-TalkTopics-YouReTheOneLookingFor", [s"\(name)"]),
                        CBTf(n"Cyberbane-TalkTopics-WordIsYouWantICould", [s"\(name)"]));
}

// [Pay]: only what V can cover, taken once the lead is good.
public func CBTalkDealPay(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                          t: ref<CBTalkTarget>, rivalId: Int32, price: Int32) -> ref<CBTalkAnswer> {
  let r = sys.FindRivalById(rivalId);
  if !IsDefined(r) || CBWhereaboutsForSale(sys, game, r) != 0 {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-ForgetItNothingToSellAnymore"), n"");
  }
  if CBTalkMoney(game) < price {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-ComeBackWhenYouVeGot"), CBT(n"Cyberbane-TalkTopics-ThatSNotTheNumberChoom")), n"");
  }
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(ts) {
    return CBTalkSay(CBT(n"Cyberbane-War-NotNow"), n"");
  }
  ts.RemoveItem(player, ItemID.FromTDBID(t"Items.money"), price);
  CBFileLog(sys, n"TalkBought", CBGameSeconds(game), CBEventDistrict(sys, game), t.faction, Cast<Float>(price));
  CBCalmTowardsV(game, t.npc, 1);   // paid and told: they do not turn round and draw on V (2.6.0, CBCalmTowardsV)
  return CBTalkSay(CBTalkGiveLead(sys, game, player, t, r, true), n"");
}

// [Haggle]: the odds lean on how afraid they are, how they stand with V and what they are like.
public class CBTalkHaggle {
  public let answer: ref<CBTalkAnswer>;
  public let price: Int32;
  public let walked: Bool;   // pushed too far: the deal is off
}

// `round` 0 is the first push; the second (1.9.8) is harder, and failing it may end the deal.
public func CBTalkDealHaggle(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, price: Int32, round: Int32) -> ref<CBTalkHaggle> {
  let h = new CBTalkHaggle();
  h.price = price;
  let temper = CBTalkTemper(t.npc);
  let chance = CBTalkNerveGap(t) + CBConfig.TalkHaggleBase() - 0.15 * Cast<Float>(round);
  if t.mood == CBTalkFriendly() {
    chance += 0.2;
  }
  if temper == CBTalkTemperGreedy() {
    chance -= 0.15;
  } else {
    if temper == CBTalkTemperChatty() {
      chance += 0.1;
    }
  }
  if CBTalkStat(game, gamedataStatType.Cool) >= CBConfig.TalkAttributeCheck() {
    chance += 0.15;
  }
  chance = ClampF(chance, 0.1, 0.85);
  if RandF() < chance {
    h.price = Max(100, RoundF(Cast<Float>(price) * CBConfig.TalkHaggleCut() / 50.0) * 50);
    let p = h.price;
    h.answer = CBTalkSay(CBPick3(CBTf(n"Cyberbane-TalkTopics-FineDonTPushIt", [s"\(p)"]), CBTf(n"Cyberbane-TalkTopics-AlrightAlright", [s"\(p)"]), CBTf(n"Cyberbane-TalkTopics-FinalOffer", [s"\(p)"])), n"");
    return h;
  }
  if round > 0 && RandF() < 0.4 {
    h.walked = true;
    h.answer = CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-ForgetItDealSOff"), CBT(n"Cyberbane-TalkTopics-YouKnowWhatFindOutYourself")), n"");
    return h;
  }
  if temper == CBTalkTemperGreedy() {
    h.price = RoundF(Cast<Float>(price) * 1.2 / 50.0) * 50;
    let p = h.price;
    h.answer = CBTalkSay(CBTf(n"Cyberbane-TalkTopics-NowItSWantToTry", [s"\(p)"]), n"");
    return h;
  }
  h.answer = CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-TakeItOrLeaveIt"), CBT(n"Cyberbane-TalkTopics-ThatSThePriceNotA")), n"");
  return h;
}

// [Intimidate] on the deal: the same odds as leaning on them; it works, and they talk for nothing.
public func CBTalkDealLean(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                           t: ref<CBTalkTarget>, rivalId: Int32) -> ref<CBTalkAnswer> {
  let r = sys.FindRivalById(rivalId);
  if !IsDefined(r) {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-NothingToTellAnymore"), n"");
  }
  let npc = t.npc;
  let chance = CBTalkNerveGap(t) * CBConfig.TalkIntimidateScale() + CBConfig.TalkIntimidateBase();
  if CBTalkStat(game, gamedataStatType.Strength) >= CBConfig.TalkAttributeCheck() {
    chance += CBConfig.TalkAttributeBonus();
  }
  chance = ClampF(chance * sys.WornPerk().breakMult, CBConfig.TalkIntimidateMin(), CBConfig.TalkIntimidateMax());
  if IsDefined(npc) && !npc.IsBoss() && !CBHoldsGround(npc) && RandF() < chance {
    CBTalkFear(sys, game, t.faction, CBConfig.TalkLeanFear());
    CBStandDownFromV(game, npc);
    return CBTalkSay(CBTalkGiveLead(sys, game, player, t, r, false), n"fear_beg");
  }
  CBTalkFear(sys, game, t.faction, -CBConfig.TalkLostFace());
  return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-NiceTryPriceJustWentTo"), CBT(n"Cyberbane-TalkTopics-ThreatenMeAgainGoOn"), CBT(n"Cyberbane-TalkTopics-ThatSNotHowThisWorks")), n"bump");
}

// The lifepath line's answer and what it does.
public func CBTalkAnswerLifepath(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let lp = CBPlayerLifePath(game);
  let f = t.faction;
  if lp == EnumInt(gamedataLifePath.Nomad) && Equals(f, n"Wraiths") {
    CBTalkSlight(sys, game, f, CBConfig.TalkInsultCost() * CBCodeInsult(f) * 0.5);
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-ANomadShouldVeGuessedFrom"), CBT(n"Cyberbane-TalkTopics-YourClanIsnTWelcomeHere")), n"bump");
  }
  CBTalkWarm(sys, game, f, CBConfig.TalkLifepathWarmth(), CBConfig.PostureAllied() - 1.0);
  if lp == EnumInt(gamedataLifePath.StreetKid) {
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-TalkTopics-YeahThenYouKnowHowIt"), CBT(n"Cyberbane-TalkTopics-HuhThoughtYouLookedFamiliar"), CBT(n"Cyberbane-TalkTopics-StreetKidHuhRespect")), n"greeting");
  }
  if lp == EnumInt(gamedataLifePath.Nomad) {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-FamilySFamilyYouNeedAnything"), CBT(n"Cyberbane-TalkTopics-TheRoadBroughtYouBackHuh")), n"greeting");
  }
  return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkTopics-ThenYouKnowTheyDSell"), CBT(n"Cyberbane-TalkTopics-ExCorpoDidnTThinkYou")), n"");
}

// A fan stands V a drink: eddies, twice a day at most across the whole street.
public func CBTalkFanGift(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Int32 {
  let score = sys.GetScore();
  let tally = CBTalkTallyFor(sys, game, n"");   // n"": everybody of no gang
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(score) || !IsDefined(tally) || !IsDefined(ts) || CBReputationFrozen()
     || tally.tips >= CBConfig.TalkFanGiftsPerDay() || RandF() >= CBConfig.TalkFanGiftChance() {
    return 0;
  }
  // tally.tips counts a friend's tips for a gang; for people of no gang, whom no gang tips through, it
  // counts the drinks.
  let amount = RoundF((CBConfig.TalkFanGiftBase() + score.GetRenown() * CBConfig.TalkFanGiftPerRenown()) / 10.0) * 10;
  if amount <= 0 {
    return 0;
  }
  ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
  tally.tips += 1;
  CBFileLog(sys, n"TalkFan", CBGameSeconds(game), CBEventDistrict(sys, game), n"", Cast<Float>(amount));
  CBLog.Info(n"Talk", s"A fan stood V \(amount)eb.");
  return amount;
}
