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
    return "the merc everybody's talking about";
  }
  return tier >= EnumInt(ECBRenownTier.KnownMerc) ? "merc" : "choom";
}

// Where V is, in the street's words.
public func CBHere(sys: ref<CyberbaneSystem>) -> String {
  if !IsDefined(sys) || Equals(sys.GetCurrentDistrict(), n"") {
    return "around here";
  }
  return CBDistrictLabel(sys.GetCurrentDistrict());
}

// The hour and the weather, as a speaker would put it, or "".
public func CBWhenWords(game: GameInstance) -> String {
  if CBRainLevel(game) >= 2 {
    return CBIsNight(game) ? "in the rain, in the middle of the night" : "in the pouring rain";
  }
  return CBIsNight(game) ? "in the middle of the night" : "";
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
    let gone = StrLen(name) > 0 ? name : "Somebody";
    let line = book.darkKills <= 1
      ? CBLineOf([gone + "? " + gone + ", talk to me!", "Where'd they go?! Anybody see them?", gone + "'s not answering."])
      : CBLineOf([s"That's \(book.darkKills) of us! Where ARE they?!", "I can't see them, I can't see anything!",
                  gone + " too? We need to get out of here.", "Stay together! Backs to the wall!"]);
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
  let out = night == 0 ? "Quiet night. Nobody's said your name." : (StrLen(worst) > 0 ? "Overnight: " + worst : s"Busy night: \(night) things the street's talking about.");
  let after = "";
  let hunters = 0;
  for r in sys.GetRivals() {
    if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Hunting) || r.id == sys.GetLaneRivalId(CBLaneRival())) {
      hunters += 1;
    }
  }
  if hunters > 0 {
    after += hunters == 1 ? " One of your Rivals is out looking for you." : s" \(hunters) of your Rivals are out looking.";
  }
  let price = CBBountyUp(game);
  if price > 0 {
    after += s" There's still \(price) on your head.";
  }
  let open = CBOpenSeasonGang(game);
  if NotEquals(open, n"") {
    after += s" \(CBCapFirst(CBFactionLabel(open))) are still in open season on you.";
  }
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  if IsDefined(ev) && !ev.placed {
    after += " " + CBEventWordLine(ev);
  }
  CBPhoneSendTinted(game, "Morning brief", out + after + s" Stay sharp, \(CBYou(sys, game)).", CBHudCyan());
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
  if Equals(e.kind, n"RivalSlain") { return StrLen(gang) > 0 ? s"MERC PUTS \(gang) NAME IN THE GROUND IN \(where)" : s"NAMED KILLER DIES IN \(where)"; }
  if Equals(e.kind, n"RivalDied") { return StrLen(gang) > 0 ? s"\(gang) LOSE A NAME IN \(where)" : s"NAMED KILLER DIES IN \(where)"; }
  if Equals(e.kind, n"BossKill") { return s"\(gang) LOSE THEIR BIG FISH IN \(where)"; }
  if Equals(e.kind, n"MeetCrashed") { return s"SIT-DOWN TURNS BLOODBATH IN \(where)"; }
  if Equals(e.kind, n"TurfTaken") { return s"\(where) CHANGES HANDS: \(gang) MOVE IN"; }
  if Equals(e.kind, n"BountyPosted") { return s"PRICE ON MERC'S HEAD: \(RoundF(e.value)) EDDIES"; }
  if Equals(e.kind, n"HunterKilled") { return s"RANK \(RoundF(e.value)) BOUNTY HUNTER FOUND DEAD IN \(where)"; }
  if Equals(e.kind, n"LadderRank") { return RoundF(e.value) == 1 ? "NEW NUMBER ONE ON THE HUNTERS' BOARD" : s"MERC CLIMBS TO NUMBER \(RoundF(e.value))"; }
  if Equals(e.kind, n"OpenSeasonSurvived") { return s"\(gang) OPEN SEASON ENDS: MERC STILL BREATHING"; }
  if Equals(e.kind, n"StreetClash") { return s"GANG WAR IN \(where): \(gang) WALK AWAY WINNERS"; }
  if Equals(e.kind, n"RivalReturned") { return "DEAD MAN WALKING: KILLER BACK FROM THE GRAVE"; }
  if Equals(e.kind, n"RivalFeud") { return s"\(gang) STAR TAKES OUT A RIVAL'S NAME"; }
  if Equals(e.kind, n"Massacre") { return s"BLOODBATH IN \(where)"; }
  if Equals(e.kind, n"ApexBeaten") { return s"\(gang) BEST WIPED OUT IN \(where)"; }
  if Equals(e.kind, n"OwnStreet") { return s"\(where) BELONGS TO ONE MERC NOW"; }
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
  let out = s"They call you \(you). ";
  let tier = EnumInt(score.GetTier());
  if tier <= EnumInt(ECBRenownTier.LocalName) {
    out += "Most of Night City has never heard of you, and the ones who have are still deciding what to make of it.";
  } else {
    out += s"Your name is known in \(CBTopDistrictWords(sys)), and it was not always.";
  }
  if stats.rivalsSlain > 0 {
    out += s" You have put \(stats.rivalsSlain) of your Rivals in the ground";
    out += stats.apexKills > 0 ? s", and \(stats.apexKills) of the gangs' best with them." : ".";
  }
  let nightmare = CBTopEnemyGang(sys);
  if NotEquals(nightmare, n"") {
    out += s" \(CBCapFirst(CBFactionLabel(nightmare))) hate you more than anybody, and they have reason to.";
  }
  let book = CBHuntBook.Get(game);
  if IsDefined(book) && book.LadderRank() > 0 {
    out += book.LadderRank() == 1 ? " On the hunters' board you are number one, and every solo with a gun knows it."
                                  : s" On the hunters' board you are number \(book.LadderRank()).";
  }
  let mine = CBOneOfTheirsGang(game);
  if NotEquals(mine, n"") {
    out += s" \(CBCapFirst(CBFactionLabel(mine))) call you one of their own.";
  }
  if stats.nonLethal > stats.rivalsSlain * 10 && stats.nonLethal >= 20 {
    out += " For all of it, you leave more people breathing than most would, and the street has noticed.";
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
  return NotEquals(best, n"") ? CBDistrictLabel(best) : "a few streets";
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
    out += r.encounters == 1 ? " You have met once since." : s" You have met \(r.encounters) times since.";
  }
  if r.escapes > 0 {
    out += r.escapes == 1 ? " They got away from you once." : s" They have got away from you \(r.escapes) times.";
  }
  if r.sparedByV > 0 {
    out += r.sparedByV == 1 ? " You let them live once." : s" You have let them live \(r.sparedByV) times.";
  }
  if r.killedV > 0 {
    out += r.killedV == 1 ? " They have put you down once." : s" They have put you down \(r.killedV) times.";
  }
  if CBRivalReturned(r) {
    out += " You killed them once. They came back.";
  }
  if CBRivalWasHumiliated(r) {
    out += " You humiliated them where they lay, and they have not forgotten.";
  }
  let s = CBSightingFor(sys, r);
  if IsDefined(s) && NotEquals(s.district, n"") {
    out += s" Last seen in \(CBDistrictLabel(s.district)).";
  }
  return out;
}

func CBRivalSourceStory(r: ref<CBRival>) -> String {
  if r.source == EnumInt(ECBRivalSource.Spared) {
    return s"You put them down and walked away, back in \(CBDistrictLabel(r.origin)).";
  }
  if r.source == EnumInt(ECBRivalSource.Survivor) {
    return s"They ran from you in \(CBDistrictLabel(r.origin)) and lived.";
  }
  if r.source == EnumInt(ECBRivalSource.Killer) {
    return s"They are the one who put you down in \(CBDistrictLabel(r.origin)).";
  }
  if r.source == EnumInt(ECBRivalSource.Avenger) {
    return s"You killed somebody of theirs in \(CBDistrictLabel(r.origin)), and they swore on it.";
  }
  if r.source == EnumInt(ECBRivalSource.Betrayer) {
    return s"They ran with your crew, and turned on you in \(CBDistrictLabel(r.origin)). They know where you sleep.";
  }
  return s"They came after you for the money, out of \(CBDistrictLabel(r.origin)).";
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
  if Equals(p, ECBPosture.Vendetta) { word = "SWORN AGAINST YOU"; }
  if Equals(p, ECBPosture.Hostile) { word = "HOSTILE TO YOU"; }
  if Equals(p, ECBPosture.Friendly) { word = "FRIENDLY TO YOU"; }
  if Equals(p, ECBPosture.Allied) { word = "ALLIED WITH YOU"; }
  // "ONE OF YOURS" read like V's own crew, whose line is YOUR CREW (2.5.5): this is the gang V belongs to.
  if Equals(CBOneOfTheirsGang(npc.GetGame()), faction) { word = "YOUR GANG"; }
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
