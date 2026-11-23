// Cyberbane - Telling it (2.4.6)
//
//   [79] voices                 the people Cyberbane moves speak in their own game voices at its moments, with the
//                               game's own voiceset lines (only names the game itself plays: enemy_warning, fear_beg,
//                               start_combat, combat_ended), through the context the talk wrap already lets through
//   [80] panic in the dark      when V picks off a crew unseen, the rest grow afraid: who is not answering, by name,
//                               and nerve that falls with each one, until somebody runs
//   [81] the screamsheet        headlines from the last day on the History page, in the tabloids' voice
//   [82] the legend, told       a button on the History page that tells V's story from the biggest things in it
//   [83] the morning brief      one broker text at dawn: the night's news, who is after V, what is coming
//   [84] a Rival's story        their page tells it from what is known of them
//   [87] Street Cred            the biggest deeds give a little of the game's own Street Cred, the way the game's
//                               own bounties do (ExperiencePointsEvent)
//   [90] presets with a shape   Nemesis, Turf war and Quiet life (Settings/CyberbaneSettings.reds)
//   [91] events other mods hear Cyberbane/RivalSlain, Cyberbane/HuntStarted and the rest, through the game's callback
//                               system
//   [U13] phone threads         a gang's thread can be threatened, stalled or insulted, and a Rival's answered
//                               (UI/RealPhone.reds)
//   [U14] the scanner           a scout's job, and how a gang sees V, under the name
//   [U15] titles                for the ladder, the war, gang life, trophies and the gang V belongs to
//   [L5] the lines              everything said here draws on what Cyberbane knows: V's name on the street, where V
//                               is, the hour, the weather, who is involved and what V did to them
//
// Everything here reads the books and the History; nothing new is saved.

public func CBVoicesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().voices;
}

public func CBMorningBriefOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBMessagesOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().morningBrief);
}

public func CBPanicInDarkOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().panicInDark;
}

public func CBStreetCredFollowsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().streetCredFollows;
}

// ---- [L5] What the street knows, for any line -------------------------------------------------------------------

// What the street calls V: the title they go by, or what their name has reached.
public func CBYou(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let st = CBReadStreet(sys, game, n"");
  if IsDefined(st) && StrLen(st.title) > 0 {
    return st.title;
  }
  let score = IsDefined(sys) ? sys.GetScore() : null;
  let tier = IsDefined(score) ? EnumInt(score.GetTier()) : 0;
  if tier >= EnumInt(ECBRenownTier.Infamous) {
    return CBT(n"Cyberbane-Telling-TheMercEverybodySTalkingAbout");
  }
  return tier >= EnumInt(ECBRenownTier.KnownMerc) ? CBT(n"Cyberbane-Telling-Merc") : CBT(n"Cyberbane-Telling-Choom");
}

// Where V is, in the street's words.
public func CBHere(sys: ref<CyberbaneSystem>) -> String {
  if !IsDefined(sys) || Equals(sys.GetCurrentDistrict(), n"") {
    return CBT(n"Cyberbane-Telling-AroundHere");
  }
  return CBDistrictLabel(sys.GetCurrentDistrict());
}

// The hour and the weather, as a speaker would put it, or "".
public func CBWhenWords(game: GameInstance) -> String {
  if CBRainLevel(game) >= 2 {
    return CBIsNight(game) ? CBT(n"Cyberbane-Telling-InTheRainInTheMiddle") : CBT(n"Cyberbane-Telling-InThePouringRain");
  }
  return CBIsNight(game) ? CBT(n"Cyberbane-Telling-InTheMiddleOfTheNight") : "";
}

// The same, with a space before it when there is anything to say: for the middle of a sentence.
public func CBWhenTail(game: GameInstance) -> String {
  let w = CBWhenWords(game);
  return StrLen(w) > 0 ? " " + w : "";
}

// ---- [79] Voices ------------------------------------------------------------------------------------------------

// One of the game's own voiceset lines from this person, through the context Cyberbane's talk wrap lets through.
public func CBSayVoiced(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>, line: CName) -> Void {
  if !CBVoicesOn() || !CBNpcSafe(sys, npc) || npc.IsDead() {
    return;
  }
  CBTrace("voice: a game voiceset line for one of Cyberbane's moments");
  GameObject.PlayVoiceOver(npc, line, n"Scripts:CBStreetTalk");
}

// The nearest of a tag to V who is standing, for a voice.
public func CBNearestTagged(sys: ref<CyberbaneSystem>, game: GameInstance, tag: CName, within: Float) -> ref<ScriptedPuppet> {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(des) || !IsDefined(player) {
    return null;
  }
  let best: ref<ScriptedPuppet>;
  let bestD = within;
  for id in des.GetTaggedIDs(tag) {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      let d = Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition());
      if d < bestD {
        bestD = d;
        best = p;
      }
    }
  }
  return best;
}

// ---- [80] Panic in the dark --------------------------------------------------------------------------------------

// A name for one of a crew, from their gang's own list and their body, the same name every time.
public func CBCrewMemberName(game: GameInstance, faction: CName, at: Vector4) -> String {
  let content = CBContent(game);
  let pool = IsDefined(content) ? content.GetFactionNames(faction) : null;
  if !IsDefined(pool) || ArraySize(pool.firstNames) == 0 {
    return "";
  }
  // Where they fell picks the name: the same one for anybody asking about the same body.
  let h = RoundF(at.X * 7.0 + at.Y * 13.0);
  return pool.firstNames[CBHashIndex(h, 31, ArraySize(pool.firstNames))];
}

// From the death path: one of a crew died by V's hand while none of them could see V.
public func CBPanicInDark(sys: ref<CyberbaneSystem>, game: GameInstance, dead: ref<ScriptedPuppet>) -> Void {
  if !CBPanicInDarkOn() || !IsDefined(dead) || sys.GetHuntState() == CBHuntLocated() {
    return;
  }
  let book = CBHuntBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  book.darkKills += 1;
  let faction = CBClassifyFaction(dead);
  let name = CBCrewMemberName(game, faction, dead.GetWorldPosition());
  let speaker = CBNearestTagged(sys, game, n"CB_Squad", CBConfig.PanicRange());
  if !IsDefined(speaker) {
    return;
  }
  if CBMessagesOn() {
    let gone = StrLen(name) > 0 ? name : CBT(n"Cyberbane-Telling-Somebody");
    let line = book.darkKills <= 1
      ? CBLineOf([CBTf(n"Cyberbane-Telling-TalkToMe", [gone, gone]), CBT(n"Cyberbane-Telling-WhereDTheyGoAnybodySee"), CBTf(n"Cyberbane-Telling-SNotAnswering", [gone])])
      : CBLineOf([CBTf(n"Cyberbane-Telling-ThatSOfUsWhereARE", [s"\(book.darkKills)"]), CBT(n"Cyberbane-Telling-ICanTSeeThemI"),
                  CBTf(n"Cyberbane-Telling-TooWeNeedToGetOut", [gone]), CBT(n"Cyberbane-Telling-StayTogetherBacksToTheWall")]);
    CBIntelSay(game, 4, CBIntelSpeaker(faction), line, 3.0);
  }
  CBSayVoiced(sys, speaker, n"enemy_warning");
  // Each one nobody saw coming leaves the rest shakier; past a point somebody runs.
  if book.darkKills >= CBConfig.PanicRunAfter() {
    CBMoraleBreak(sys, game, speaker, faction, CBConfig.PanicBreakChance() * Cast<Float>(book.darkKills - CBConfig.PanicRunAfter() + 1));
  }
}

// ---- [87] Street Cred follows the legend ---------------------------------------------------------------------------

// A little of the game's own Street Cred, the way the game's own bounties give it (bountyManager.script).
public func CBGiveStreetCred(game: GameInstance, amount: Int32) -> Void {
  let player = GetPlayer(game);
  if !CBStreetCredFollowsOn() || amount <= 0 || !IsDefined(player) || CBReputationFrozen() {
    return;
  }
  let evt = new ExperiencePointsEvent();
  evt.amount = amount;
  evt.type = gamedataProficiencyType.StreetCred;
  evt.isDebug = false;
  player.QueueEvent(evt);
}

// ---- [91] Events other mods can hear --------------------------------------------------------------------------------

public class CBModEvent extends CallbackSystemEvent {
  public let faction: CName;
  public let value: Float;
}

// A name other mods register for (Cyberbane/RivalSlain, Cyberbane/HuntStarted, Cyberbane/BountyPosted,
// Cyberbane/LadderRank, Cyberbane/StreetEvent), with the gang and a number. Nothing waits on the answer.
public func CBEmit(name: CName, faction: CName, value: Float) -> Void {
  let cbs = GameInstance.GetCallbackSystem();
  if !IsDefined(cbs) {
    return;
  }
  let evt = new CBModEvent();
  evt.faction = faction;
  evt.value = value;
  cbs.DispatchEventAs(name, evt);
}

// ---- [83] The morning brief ----------------------------------------------------------------------------------------

// From the slow tick: the first in-game hour after dawn, once a day.
public func CBMorningBriefTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBHuntBook.Get(game);
  let ts = GameInstance.GetTimeSystem(game);
  if !CBMorningBriefOn() || !IsDefined(book) || !IsDefined(ts) {
    return;
  }
  let hour = GameTime.Hours(ts.GetGameTime());
  let day = CBGameDay(game);
  if hour < 6 || hour > 9 || book.briefDay == day + 1 {
    return;
  }
  book.briefDay = day + 1;
  let now = CBGameSeconds(game);
  let night = 0;
  let worst = "";
  for e in sys.GetLog() {
    if IsDefined(e) && now - e.at <= CBConfig.BriefHours() * CBConfig.SecondsPerHour() {
      night += 1;
      if CBWhileOutWorthIt(e.kind) {
        worst = CBHudLogLine(sys, e, now);
      }
    }
  }
  let out = night == 0 ? CBT(n"Cyberbane-Telling-QuietNightNobodySSaidYour") : (StrLen(worst) > 0 ? CBTf(n"Cyberbane-Telling-Overnight", [worst]) : CBTf(n"Cyberbane-Telling-BusyNightThingsTheStreetS", [s"\(night)"]));
  let after = "";
  let hunters = 0;
  for r in sys.GetRivals() {
    if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Hunting) || r.id == sys.GetLaneRivalId(CBLaneRival())) {
      hunters += 1;
    }
  }
  if hunters > 0 {
    after += hunters == 1 ? CBT(n"Cyberbane-Telling-OneOfYourRivalsIsOut") : CBTf(n"Cyberbane-Telling-OfYourRivalsAreOutLooking", [s"\(hunters)"]);
  }
  let price = CBBountyUp(game);
  if price > 0 {
    after += CBTf(n"Cyberbane-Telling-ThereSStillOnYourHead", [s"\(price)"]);
  }
  let open = CBOpenSeasonGang(game);
  if NotEquals(open, n"") {
    after += CBTf(n"Cyberbane-Telling-AreStillInOpenSeasonOn", [s"\(CBCapFirst(CBFactionLabel(open)))"]);
  }
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  if IsDefined(ev) && !ev.placed {
    after += " " + CBEventWordLine(ev);
  }
  CBPhoneSendTinted(game, CBT(n"Cyberbane-Telling-MorningBrief"), CBTf(n"Cyberbane-Telling-StaySharp", [out, after, s"\(CBYou(sys, game))"]), CBHudCyan());
}

// ---- [81] [82] The screamsheet and the legend ---------------------------------------------------------------------

// Up to three headlines from the last game day, in the tabloids' voice, from what the street filed.
public func CBScreamsheet(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let now = CBGameSeconds(game);
  let out = "";
  let n = 0;
  let log = sys.GetLog();
  let i = ArraySize(log) - 1;
  while i >= 0 && n < 3 {
    let e = log[i];
    i -= 1;
    if IsDefined(e) && now - e.at <= CBConfig.SecondsPerDay() {
      let h = CBHeadline(sys, e);
      if StrLen(h) > 0 {
        out += (StrLen(out) > 0 ? "\n" : "") + h;
        n += 1;
      }
    }
  }
  return out;
}

public func CBHeadline(sys: ref<CyberbaneSystem>, e: ref<CBLogEntry>) -> String {
  let gang = StrUpper(CBFactionLabel(e.faction));
  let where = StrUpper(CBDistrictLabel(e.district));
  // Somewhere the file has no district for (a death outside the eight, a load before the first sample): the city.
  if StrLen(where) == 0 {
    where = CBT(n"Cyberbane-Telling-NIGHTCITY");
  }
  // And a story about a gang the file has no name for, told about a gang.
  if StrLen(gang) == 0 && (Equals(e.kind, n"BossKill") || Equals(e.kind, n"TurfTaken") || Equals(e.kind, n"OpenSeasonSurvived")
     || Equals(e.kind, n"StreetClash") || Equals(e.kind, n"RivalFeud") || Equals(e.kind, n"ApexBeaten")) {
    gang = CBT(n"Cyberbane-Telling-AGANG");
  }
  if Equals(e.kind, n"RivalSlain") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Telling-MERCPUTSNAMEINTHEGROUND", [s"\(gang)", s"\(where)"]) : CBTf(n"Cyberbane-Telling-NAMEDKILLERDIESIN", [s"\(where)"]); }
  if Equals(e.kind, n"RivalDied") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Telling-LOSEANAMEIN", [s"\(gang)", s"\(where)"]) : CBTf(n"Cyberbane-Telling-NAMEDKILLERDIESIN", [s"\(where)"]); }
  if Equals(e.kind, n"BossKill") { return CBTf(n"Cyberbane-Telling-LOSETHEIRBIGFISHIN", [s"\(gang)", s"\(where)"]); }
  if Equals(e.kind, n"MeetCrashed") { return CBTf(n"Cyberbane-Telling-SITDOWNTURNSBLOODBATHIN", [s"\(where)"]); }
  if Equals(e.kind, n"TurfTaken") { return CBTf(n"Cyberbane-Telling-CHANGESHANDSMOVEIN", [s"\(where)", s"\(gang)"]); }
  if Equals(e.kind, n"BountyPosted") { return CBTf(n"Cyberbane-Telling-PRICEONMERCSHEADEDDIES", [s"\(RoundF(e.value))"]); }
  if Equals(e.kind, n"HunterKilled") { return CBTf(n"Cyberbane-Telling-RANKBOUNTYHUNTERFOUNDDEADIN", [s"\(RoundF(e.value))", s"\(where)"]); }
  if Equals(e.kind, n"LadderRank") { return RoundF(e.value) == 1 ? CBT(n"Cyberbane-Telling-NEWNUMBERONEONTHEHUNTERS") : CBTf(n"Cyberbane-Telling-MERCCLIMBSTONUMBER", [s"\(RoundF(e.value))"]); }
  if Equals(e.kind, n"OpenSeasonSurvived") { return CBTf(n"Cyberbane-Telling-OPENSEASONENDSMERCSTILLBREATHING", [s"\(gang)"]); }
  if Equals(e.kind, n"StreetClash") { return CBTf(n"Cyberbane-Telling-GANGWARINWALKAWAYWINNERS", [s"\(where)", s"\(gang)"]); }
  if Equals(e.kind, n"RivalReturned") { return CBT(n"Cyberbane-Telling-DEADMANWALKINGKILLERBACKFROM"); }
  if Equals(e.kind, n"RivalFeud") { return CBTf(n"Cyberbane-Telling-STARTAKESOUTARIVALS", [s"\(gang)"]); }
  if Equals(e.kind, n"Massacre") { return CBTf(n"Cyberbane-Telling-BLOODBATHIN", [s"\(where)"]); }
  if Equals(e.kind, n"ApexBeaten") { return CBTf(n"Cyberbane-Telling-BESTWIPEDOUTIN", [s"\(gang)", s"\(where)"]); }
  if Equals(e.kind, n"OwnStreet") { return CBTf(n"Cyberbane-Telling-BELONGSTOONEMERCNOW", [s"\(where)"]); }
  return "";
}

// V's story, the way the street would tell it, from the biggest things on file.
public func CBLegendTold(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let stats = sys.GetStats();
  let score = sys.GetScore();
  if !IsDefined(stats) || !IsDefined(score) {
    return "";
  }
  let you = CBYou(sys, game);
  let out = CBTf(n"Cyberbane-Telling-TheyCallYou", [s"\(you)"]);
  let tier = EnumInt(score.GetTier());
  if tier <= EnumInt(ECBRenownTier.LocalName) {
    out += CBT(n"Cyberbane-Telling-MostOfNightCityHasNever");
  } else {
    out += CBTf(n"Cyberbane-Telling-YourNameIsKnownInAnd", [s"\(CBTopDistrictWords(sys))"]);
  }
  if stats.rivalsSlain > 0 {
    out += CBTf(n"Cyberbane-Telling-YouHavePutOfYourRivals", [s"\(stats.rivalsSlain)"]);
    out += stats.apexKills > 0 ? CBTf(n"Cyberbane-Telling-AndOfTheGangsBestWith", [s"\(stats.apexKills)"]) : ".";
  }
  let nightmare = CBTopEnemyGang(sys);
  if NotEquals(nightmare, n"") {
    out += CBTf(n"Cyberbane-Telling-HateYouMoreThanAnybodyAnd", [s"\(CBCapFirst(CBFactionLabel(nightmare)))"]);
  }
  let book = CBHuntBook.Get(game);
  if IsDefined(book) && book.LadderRank() > 0 {
    out += book.LadderRank() == 1 ? CBT(n"Cyberbane-Telling-OnTheHuntersBoardYouAre")
                                  : CBTf(n"Cyberbane-Telling-OnTheHuntersBoardYouAre-2", [s"\(book.LadderRank())"]);
  }
  let mine = CBOneOfTheirsGang(game);
  if NotEquals(mine, n"") {
    out += CBTf(n"Cyberbane-Telling-CallYouOneOfTheirOwn", [s"\(CBCapFirst(CBFactionLabel(mine)))"]);
  }
  if stats.nonLethal > stats.rivalsSlain * 10 && stats.nonLethal >= 20 {
    out += CBT(n"Cyberbane-Telling-ForAllOfItYouLeave");
  }
  return out;
}

func CBTopDistrictWords(sys: ref<CyberbaneSystem>) -> String {
  let best = n"";
  let high = 0.0;
  for d in sys.GetDistrictStates() {
    if IsDefined(d) && d.renown > high {
      high = d.renown;
      best = d.id;
    }
  }
  return NotEquals(best, n"") ? CBDistrictLabel(best) : CBT(n"Cyberbane-Telling-AFewStreets");
}

func CBTopEnemyGang(sys: ref<CyberbaneSystem>) -> CName {
  let best = n"";
  let low = -20.0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && fs.standing < low {
      low = fs.standing;
      best = fs.id;
    }
  }
  return best;
}

// ---- [84] A Rival's story --------------------------------------------------------------------------------------------

public func CBRivalStory(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  if !IsDefined(r) {
    return "";
  }
  let out = CBRivalSourceStory(r);
  if r.encounters > 0 {
    out += r.encounters == 1 ? CBT(n"Cyberbane-Telling-YouHaveMetOnceSince") : CBTf(n"Cyberbane-Telling-YouHaveMetTimesSince", [s"\(r.encounters)"]);
  }
  if r.escapes > 0 {
    out += r.escapes == 1 ? CBT(n"Cyberbane-Telling-TheyGotAwayFromYouOnce") : CBTf(n"Cyberbane-Telling-TheyHaveGotAwayFromYou", [s"\(r.escapes)"]);
  }
  if r.sparedByV > 0 {
    out += r.sparedByV == 1 ? CBT(n"Cyberbane-Telling-YouLetThemLiveOnce") : CBTf(n"Cyberbane-Telling-YouHaveLetThemLiveTimes", [s"\(r.sparedByV)"]);
  }
  if r.killedV > 0 {
    out += r.killedV == 1 ? CBT(n"Cyberbane-Telling-TheyHavePutYouDownOnce") : CBTf(n"Cyberbane-Telling-TheyHavePutYouDownTimes", [s"\(r.killedV)"]);
  }
  if CBRivalReturned(r) {
    out += CBT(n"Cyberbane-Telling-YouKilledThemOnceTheyCame");
  }
  if CBRivalWasHumiliated(r) {
    out += CBT(n"Cyberbane-Telling-YouHumiliatedThemWhereTheyLay");
  }
  let s = CBSightingFor(sys, r);
  if IsDefined(s) && NotEquals(s.district, n"") {
    out += CBTf(n"Cyberbane-Telling-LastSeenIn", [s"\(CBDistrictLabel(s.district))"]);
  }
  return out;
}

func CBRivalSourceStory(r: ref<CBRival>) -> String {
  // " in Watson", or nothing for a Rival made somewhere the eight districts do not cover.
  let place = CBDistrictLabel(r.origin);
  let inPlace = StrLen(place) > 0 ? CBTf(n"Cyberbane-RumorEngine-In", [place]) : "";
  if r.source == EnumInt(ECBRivalSource.Spared) {
    return StrLen(place) > 0 ? CBTf(n"Cyberbane-Telling-YouPutThemDownAndWalked", [s"\(place)"]) : CBT(n"Cyberbane-Telling-YouPutThemDownAndWalked-2");
  }
  if r.source == EnumInt(ECBRivalSource.Survivor) {
    return CBTf(n"Cyberbane-Telling-TheyRanFromYouAndLived", [s"\(inPlace)"]);
  }
  if r.source == EnumInt(ECBRivalSource.Killer) {
    return CBTf(n"Cyberbane-Telling-TheyAreTheOneWhoPut", [s"\(inPlace)"]);
  }
  if r.source == EnumInt(ECBRivalSource.Avenger) {
    return CBTf(n"Cyberbane-Telling-YouKilledSomebodyOfTheirsAnd", [s"\(inPlace)"]);
  }
  if r.source == EnumInt(ECBRivalSource.Betrayer) {
    return CBTf(n"Cyberbane-Telling-TheyRanWithYourCrewAnd", [s"\(inPlace)"]);
  }
  return StrLen(place) > 0 ? CBTf(n"Cyberbane-Telling-TheyCameAfterYouForThe", [s"\(place)"]) : CBT(n"Cyberbane-Telling-TheyCameAfterYouForThe-2");
}

// ---- [U14] The scanner tells the story --------------------------------------------------------------------------------

// Under a gang's person's name: their class, and how their gang sees V, when it is anything but neutral.
public func CBScannerStance(npc: ref<NPCPuppet>) -> String {
  let sys = CyberbaneSystem.Get(npc.GetGame());
  if !IsDefined(sys) || npc.IsDead() || npc.IsCrowd() {
    return "";
  }
  let faction = CBClassifyFaction(npc);
  let score = sys.GetScore();
  if Equals(faction, n"") || !CBFactionFieldsSquads(faction) || !IsDefined(score) {
    return "";
  }
  let p = score.GetPosture(faction);
  let word = "";
  if Equals(p, ECBPosture.Vendetta) { word = CBT(n"Cyberbane-Telling-SWORNAGAINSTYOU"); }
  if Equals(p, ECBPosture.Hostile) { word = CBT(n"Cyberbane-Telling-HOSTILETOYOU"); }
  if Equals(p, ECBPosture.Friendly) { word = CBT(n"Cyberbane-Telling-FRIENDLYTOYOU"); }
  if Equals(p, ECBPosture.Allied) { word = CBT(n"Cyberbane-Telling-ALLIEDWITHYOU"); }
  // "ONE OF YOURS" read like V's own crew, whose line is YOUR CREW (2.5.5): this is the gang V belongs to.
  if Equals(CBOneOfTheirsGang(npc.GetGame()), faction) { word = CBT(n"Cyberbane-Telling-YOURGANG"); }
  return word;
}

// ---- [U15] Titles for what is new --------------------------------------------------------------------------------------

public func CBNewTitleCondition(sys: ref<CyberbaneSystem>, game: GameInstance, id: CName) -> Bool {
  if Equals(id, n"T_NUMBER_ONE") {
    let hunt = CBHuntBook.Get(game);
    return IsDefined(hunt) && hunt.LadderRank() == 1;
  }
  if Equals(id, n"T_WARLORD") {
    let war = CBWarBook.Get(game);
    return IsDefined(war) && war.OwnMask() != 0;
  }
  if Equals(id, n"T_PARTY_CRASHER") {
    return CBLogCount(sys, n"MeetCrashed") + CBLogCount(sys, n"EventCrashed") + CBLogCount(sys, n"DealCrashed")
         + CBLogCount(sys, n"FuneralCrashed") >= 3;
  }
  if Equals(id, n"T_TROPHY_HUNTER") { return CBLogCount(sys, n"Trophy") >= 3; }
  if Equals(id, n"T_MADE") { return NotEquals(CBOneOfTheirsGang(game), n""); }
  if Equals(id, n"T_SEASON_SURVIVOR") { return CBLogCount(sys, n"OpenSeasonSurvived") >= 1; }
  return false;
}

public func CBLogCount(sys: ref<CyberbaneSystem>, kind: CName) -> Int32 {
  let n = 0;
  for e in sys.GetLog() {
    if IsDefined(e) && Equals(e.kind, kind) {
      n += 1;
    }
  }
  return n;
}
