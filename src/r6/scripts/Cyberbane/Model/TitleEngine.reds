// Cyberbane - Title engine (spec Appendix G)
//
// Evaluated on the slow tick. Each title's condition is checked in code against
// the current score, stats and faction/district state. Unlocking grants Renown
// (+25, or +100 for Cyberbane) and a message. Deed-gated titles unlock once the
// deed system lands; chrome-gated ones once the chrome signal lands.

public func CBEvaluateTitles(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let content = CBContent(game);
  if !IsDefined(content) {
    return;
  }
  for def in content.GetTitles() {
    if IsDefined(def) && !sys.HasTitle(def.id) && CBCheckTitleCondition(sys, def.id) {
      sys.UnlockTitle(def.id);
      sys.AddRenownPoints(Equals(def.id, n"T_CYBERBANE") ? 100.0 : 25.0);
      if CBMessagesOn() {
        // From somebody on the street rather than from the mod. A title is a thing other
        // people decided to call you, so hearing it from them is the right way round.
        CBHearsayFromContact(game, CBTf(n"Cyberbane-TitleEngine-PeopleAreCallingYouNow", [CBTitleDisplay(sys, def)]), n"");
      }
      CBLog.Info(n"Model", s"Title unlocked: \(NameToString(def.id)).");
    }
  }
}

func CBCheckTitleCondition(sys: ref<CyberbaneSystem>, id: CName) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let score = sys.GetScore();
  let stats = sys.GetStats();
  if !IsDefined(stats) {
    return false;
  }
  if Equals(id, n"T_LIVING_LEGEND") { return score.GetRenown() >= CBConfig.TierLegend(); }
  if Equals(id, n"T_CHROME_SAINT") { return score.GetChrome() >= 85.0; }
  if Equals(id, n"T_GLITCH") {
    return sys.GetPrimaryArchetypeIndex() == EnumInt(ECBArchetype.Netrunner) && stats.quickhackKills >= 50;
  }
  if Equals(id, n"T_PSYCHO_HUNTER") { return stats.psychosKilled >= 10; }
  if Equals(id, n"T_PSYCHO_WHISPERER") { return stats.psychosPacified >= 5; }
  if Equals(id, n"T_FIST") {
    // Knockouts count: the Fist of Night City may well never have killed anybody.
    return sys.GetPrimaryArchetypeIndex() == EnumInt(ECBArchetype.Brawler)
        && sys.TotalKills() + stats.nonLethal >= 100;
  }
  if Equals(id, n"T_UNTOUCHABLE") { return stats.flawless >= 10; }
  if Equals(id, n"T_RED_TIDE") { return stats.massacres >= 5; }
  if Equals(id, n"T_MAXTAC_PROBLEM") { return CBKillsByClass(sys, EnumInt(ECBVictimClass.MaxTac)) >= 10; }
  if Equals(id, n"T_RIVAL_BREAKER") { return stats.rivalsSlain >= 5; }
  if Equals(id, n"T_MERCIFUL") {
    return stats.nonLethal >= 100 && CBKillsByClass(sys, EnumInt(ECBVictimClass.Civilian)) == 0;
  }
  if Equals(id, n"T_LANDLORD") { return CBTotalTributes(sys) >= 5; }
  if Equals(id, n"T_FACTION_FRIEND") { return CBAnyFactionStandingAtLeast(sys, 75.0); }
  if Equals(id, n"T_FACTION_NIGHTMARE") { return CBAnyFactionNightmare(sys, score); }
  if Equals(id, n"T_BUTCHER_OF") {
    return sys.GetPrimaryArchetypeIndex() == EnumInt(ECBArchetype.Butcher) && CBAnyDistrictLethalAtLeast(sys, 50);
  }
  if Equals(id, n"T_GHOST_OF") {
    return sys.GetPrimaryArchetypeIndex() == EnumInt(ECBArchetype.Ghost) && CBAnyDistrictQuietAtLeast(sys, 30);
  }
  if Equals(id, n"T_DISTRICT_PROBLEM") { return CBAnyDistrictProblem(sys, score); }
  // Earned by working unseen rather than by finishing one specific job.
  if Equals(id, n"T_KONPEKI_GHOST") {
    return sys.GetPrimaryArchetypeIndex() == EnumInt(ECBArchetype.Ghost)
        && stats.unattributed >= CBConfig.KonpekiUnattributed();
  }
  if Equals(id, n"T_MERC_FROM") { return EnumInt(score.GetTier()) >= EnumInt(ECBRenownTier.LocalName); }
  if Equals(id, n"T_CYBERBANE") { return CBCyberbaneCondition(sys, score); }
  if CBNewTitleCondition(sys, sys.GetGameInstance(), id) {
    return true;   // the ladder, the war, gang life, trophies, a gang's own (Narrative/Telling.reds)
  }
  return false;   // deed-gated titles unlock through the deed system
}

// What this title takes, in plain words, with progress where there is a number to show.
public func CBTitleRequirement(sys: ref<CyberbaneSystem>, id: CName) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let score = sys.GetScore();
  let stats = sys.GetStats();
  if !IsDefined(score) || !IsDefined(stats) {
    return "";
  }
  // An add-on's title says what it takes in its own words.
  let content = sys.GetContent();
  let def = IsDefined(content) ? content.GetTitle(id) : null;
  if IsDefined(def) && IsNameValid(def.conditionKey) {
    return CBT(def.conditionKey);
  }
  let renown = RoundF(score.GetRenown());
  if Equals(id, n"T_NUMBER_ONE") { return CBT(n"Cyberbane-TitleEngine-ReachTheTopOfTheHunters"); }
  if Equals(id, n"T_WARLORD") { return CBT(n"Cyberbane-TitleEngine-MakeADistrictYourOwnA"); }
  if Equals(id, n"T_SEASON_SURVIVOR") { return CBT(n"Cyberbane-TitleEngine-LiveThroughAGangSOpen"); }
  if Equals(id, n"T_PARTY_CRASHER") { return CBT(n"Cyberbane-TitleEngine-CrashThreeOfTheGangsGatherings"); }
  if Equals(id, n"T_TROPHY_HUNTER") { return CBT(n"Cyberbane-TitleEngine-TakeATrophyOffThreeNamed"); }
  if Equals(id, n"T_MADE") { return CBT(n"Cyberbane-TitleEngine-BecomeOneOfAGangS"); }
  if Equals(id, n"T_LIVING_LEGEND") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-ReachThisMuchRenown"), renown, RoundF(CBConfig.TierLegend())) + ".";
  }
  if Equals(id, n"T_MERC_FROM") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-ReachThisMuchRenown"), renown, RoundF(CBConfig.TierLocalName())) + ".";
  }
  if Equals(id, n"T_CHROME_SAINT") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-InstalledChromeScoreFromHowMuch"), RoundF(score.GetChrome()), 85) + ".";
  }
  if Equals(id, n"T_GLITCH") {
    return CBReqStyle(sys, ECBArchetype.Netrunner, CBT(n"Cyberbane-TitleEngine-QuickhackKillsBuildIt")) + "\n"
         + CBReqNum(CBT(n"Cyberbane-TitleEngine-KillPeopleWithQuickhacks"), stats.quickhackKills, 50) + ".";
  }
  if Equals(id, n"T_PSYCHO_HUNTER") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-KillCyberpsychos"), stats.psychosKilled, 10) + ".";
  }
  if Equals(id, n"T_PSYCHO_WHISPERER") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-TakeCyberpsychosDownWithoutKillingThem"), stats.psychosPacified, 5) + ".";
  }
  if Equals(id, n"T_FIST") {
    return CBReqStyle(sys, ECBArchetype.Brawler, CBT(n"Cyberbane-TitleEngine-FistsAndBluntWeaponsBuildIt")) + "\n"
         + CBReqNum(CBT(n"Cyberbane-TitleEngine-PutPeopleDownDeadOrBreathing"), sys.TotalKills() + stats.nonLethal, 100) + ".";
  }
  if Equals(id, n"T_UNTOUCHABLE") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-WinFightsOf2OrMore"), stats.flawless, 10) + ".";
  }
  if Equals(id, n"T_RED_TIDE") {
    return CBReqNum(CBTf(n"Cyberbane-TitleEngine-MassacresBodiesInOneFightOr", [s"\(CBConfig.MassacreTotalKills())", s"\(CBConfig.MassacreWindowKills())", s"\(RoundF(CBConfig.MassacreWindowSeconds()))"]), stats.massacres, 5) + ".";
  }
  if Equals(id, n"T_MAXTAC_PROBLEM") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-KillMaxTacOfficers"), CBKillsByClass(sys, EnumInt(ECBVictimClass.MaxTac)), 10) + ".";
  }
  if Equals(id, n"T_RIVAL_BREAKER") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-KillRivals"), stats.rivalsSlain, 5) + ".";
  }
  if Equals(id, n"T_MERCIFUL") {
    return CBTf(n"Cyberbane-TitleEngine-NeverKillACivilianYouHave", [CBReqNum(CBT(n"Cyberbane-TitleEngine-TakePeopleDownWithoutKillingThem"), stats.nonLethal, 100), s"\(CBKillsByClass(sys, EnumInt(ECBVictimClass.Civilian)))"]);
  }
  if Equals(id, n"T_LANDLORD") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-CollectTributeFromGangsAfraidOf"), CBTotalTributes(sys), 5) + ".";
  }
  if Equals(id, n"T_FACTION_FRIEND") {
    let friend = "";
    let best = CBBestStanding(sys, friend);
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-ReachThisStandingWithOneGang"), best, 75) + CBReqBest(friend) + ".";
  }
  if Equals(id, n"T_FACTION_NIGHTMARE") {
    let gang = n"";
    let most = CBMostKilledGang(sys, gang);
    let fearNeed = RoundF(CBConfig.TitleFearNeeded());
    return CBTf(n"Cyberbane-TitleEngine-OneGangHasToLose75", [s"\(fearNeed)", (Equals(gang, n"") ? CBT(n"Cyberbane-TitleEngine-YouHaveNotFoughtOneYet")
            : CBTf(n"Cyberbane-TitleEngine-75KilledFear", [CBCapFirst(CBFactionLabel(gang)), s"\(Min(most, 75))", s"\(RoundF(score.GetFactionFear(gang)))", s"\(fearNeed)"]))]);
  }
  if Equals(id, n"T_BUTCHER_OF") {
    let where = "";
    let best = CBBestDistrict(sys, 0, where);
    return CBReqStyle(sys, ECBArchetype.Butcher, CBT(n"Cyberbane-TitleEngine-KillingPeopleBuildsItBrutallyFaster")) + "\n"
         + CBReqNum(CBT(n"Cyberbane-TitleEngine-KillsInOneDistrict"), best, 50) + CBReqBest(where) + ".";
  }
  if Equals(id, n"T_GHOST_OF") {
    let where = "";
    let best = CBBestDistrict(sys, 1, where);
    return CBReqStyle(sys, ECBArchetype.Ghost, CBT(n"Cyberbane-TitleEngine-TakingPeopleDownUnseenBuildsIt")) + "\n"
         + CBReqNum(CBT(n"Cyberbane-TitleEngine-QuietNonLethalTakedownsInOne"), best, 30) + CBReqBest(where) + ".";
  }
  if Equals(id, n"T_DISTRICT_PROBLEM") {
    let where = "";
    let best = CBBestDistrict(sys, 2, where);
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-ReachThisMuchDread"), RoundF(score.GetDread()), 50) + ".\n"
         + CBReqNum(CBT(n"Cyberbane-TitleEngine-ReachThisMuchRenownInOne"), best, 80) + CBReqBest(where) + ".";
  }
  if Equals(id, n"T_KONPEKI_GHOST") {
    return CBTf(n"Cyberbane-TitleEngine-FinishTheHeistOrDoBoth", [CBReqStyle(sys, ECBArchetype.Ghost, CBT(n"Cyberbane-TitleEngine-TakingPeopleDownUnseenBuildsIt")), CBReqNum(CBT(n"Cyberbane-TitleEngine-KillsNobodySaw"), stats.unattributed, CBConfig.KonpekiUnattributed())]);
  }
  if Equals(id, n"T_CYBERBANE") {
    return CBReqNum(CBT(n"Cyberbane-TitleEngine-Renown"), renown, 850) + "\n"
         + CBReqNum(CBT(n"Cyberbane-TitleEngine-Dread"), RoundF(score.GetDread()), RoundF(CBConfig.TitleDreadNeeded())) + "\n"
         + CBReqNum(CBT(n"Cyberbane-TitleEngine-RivalsKilled"), stats.rivalsSlain, 3) + "\n"
         + CBReqNum(CBTf(n"Cyberbane-TitleEngine-GangsThatFearYouAtOr", [s"\(RoundF(CBConfig.TitleFearNeeded()))"]), CBCountFactionsFeared(sys, score, CBConfig.TitleFearNeeded()), 3);
  }
  return "";
}

func CBReqBest(where: String) -> String {
  return StrLen(where) > 0 ? CBTf(n"Cyberbane-TitleEngine-BestSoFar", [where]) : "";
}

func CBReqStyle(sys: ref<CyberbaneSystem>, style: ECBArchetype, how: String) -> String {
  let now = sys.GetPrimaryArchetypeIndex();
  let yours = now >= 0 ? CBArchetypeName(now) : CBT(n"Cyberbane-TitleEngine-NotSettledYet");
  return CBTf(n"Cyberbane-TitleEngine-MustBeYourMainFightingStyle", [CBArchetypeName(EnumInt(style)), how, yours]);
}

func CBBestStanding(sys: ref<CyberbaneSystem>, out who: String) -> Int32 {
  let best = 0.0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && fs.standing > best {
      best = fs.standing;
      who = CBFactionLabel(fs.id);
    }
  }
  return RoundF(best);
}

func CBMostKilledGang(sys: ref<CyberbaneSystem>, out gang: CName) -> Int32 {
  let most = 0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && fs.kills > most {
      most = fs.kills;
      gang = fs.id;
    }
  }
  return most;
}

func CBBestDistrict(sys: ref<CyberbaneSystem>, mode: Int32, out where: String) -> Int32 {
  let best = 0;
  for ds in sys.GetDistrictStates() {
    if IsDefined(ds) {
      let v = mode == 0 ? ds.lethalOrBrutal : (mode == 1 ? ds.quietTakedowns : RoundF(ds.renown));
      if v > best {
        best = v;
        where = CBDistrictLabel(ds.id);
      }
    }
  }
  return best;
}

// The short form, for the list. "" means there is no single number to show.
public func CBTitleProgress(sys: ref<CyberbaneSystem>, id: CName) -> String {
  let score = sys.GetScore();
  let stats = sys.GetStats();
  if !IsDefined(score) || !IsDefined(stats) {
    return "";
  }
  let have = -1;
  let need = 0;
  let label = "";
  if Equals(id, n"T_LIVING_LEGEND") || Equals(id, n"T_CYBERBANE") { have = RoundF(score.GetRenown()); need = 850; }
  if Equals(id, n"T_MERC_FROM") { have = RoundF(score.GetRenown()); need = RoundF(CBConfig.TierLocalName()); }
  if Equals(id, n"T_CHROME_SAINT") { have = RoundF(score.GetChrome()); need = 85; }
  if Equals(id, n"T_GLITCH") { have = stats.quickhackKills; need = 50; }
  if Equals(id, n"T_PSYCHO_HUNTER") { have = stats.psychosKilled; need = 10; }
  if Equals(id, n"T_PSYCHO_WHISPERER") { have = stats.psychosPacified; need = 5; }
  if Equals(id, n"T_FIST") { have = sys.TotalKills() + stats.nonLethal; need = 100; }
  if Equals(id, n"T_UNTOUCHABLE") { have = stats.flawless; need = 10; }
  if Equals(id, n"T_RED_TIDE") { have = stats.massacres; need = 5; }
  if Equals(id, n"T_MAXTAC_PROBLEM") { have = CBKillsByClass(sys, EnumInt(ECBVictimClass.MaxTac)); need = 10; }
  if Equals(id, n"T_RIVAL_BREAKER") { have = stats.rivalsSlain; need = 5; }
  if Equals(id, n"T_MERCIFUL") { have = stats.nonLethal; need = 100; }
  if Equals(id, n"T_LANDLORD") { have = CBTotalTributes(sys); need = 5; }
  if Equals(id, n"T_KONPEKI_GHOST") { have = stats.unattributed; need = CBConfig.KonpekiUnattributed(); }
  if Equals(id, n"T_FACTION_FRIEND") { have = CBBestStanding(sys, label); need = 75; }
  if Equals(id, n"T_BUTCHER_OF") { have = CBBestDistrict(sys, 0, label); need = 50; }
  if Equals(id, n"T_GHOST_OF") { have = CBBestDistrict(sys, 1, label); need = 30; }
  if Equals(id, n"T_DISTRICT_PROBLEM") { have = CBBestDistrict(sys, 2, label); need = 80; }
  if Equals(id, n"T_FACTION_NIGHTMARE") {
    let gang = n"";
    have = CBMostKilledGang(sys, gang);
    need = 75;
  }
  if have < 0 {
    return "";
  }
  return s"\(Min(have, need))/\(need)";
}

// Whether titles do anything at all.
public func CBTitlesDoThings() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().titlePerks;
}

func CBReqNum(what: String, have: Int32, need: Int32) -> String {
  let shown = have > need ? need : have;
  return what + s" (\(shown)/\(need))";
}

func CBKillsByClass(sys: ref<CyberbaneSystem>, idx: Int32) -> Int32 {
  if !IsDefined(sys) {
    return 0;
  }
  return sys.GetKillsByClass(idx);
}

func CBTotalTributes(sys: ref<CyberbaneSystem>) -> Int32 {
  let total = 0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) {
      total += fs.tributes;
    }
  }
  return total;
}

func CBAnyFactionStandingAtLeast(sys: ref<CyberbaneSystem>, threshold: Float) -> Bool {
  for fs in sys.GetFactionStates() {
    if fs.standing >= threshold {
      return true;
    }
  }
  return false;
}

func CBAnyFactionNightmare(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>) -> Bool {
  for fs in sys.GetFactionStates() {
    if fs.kills >= 75 && score.GetFactionFear(fs.id) >= CBConfig.TitleFearNeeded() {
      return true;
    }
  }
  return false;
}

func CBCountFactionsFeared(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>, threshold: Float) -> Int32 {
  let count = 0;
  for fs in sys.GetFactionStates() {
    if score.GetFactionFear(fs.id) >= threshold {
      count += 1;
    }
  }
  return count;
}

func CBAnyDistrictLethalAtLeast(sys: ref<CyberbaneSystem>, threshold: Int32) -> Bool {
  for ds in sys.GetDistrictStates() {
    if ds.lethalOrBrutal >= threshold {
      return true;
    }
  }
  return false;
}

func CBAnyDistrictQuietAtLeast(sys: ref<CyberbaneSystem>, threshold: Int32) -> Bool {
  for ds in sys.GetDistrictStates() {
    if ds.quietTakedowns >= threshold {
      return true;
    }
  }
  return false;
}

func CBAnyDistrictProblem(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>) -> Bool {
  if score.GetDread() < 50.0 {
    return false;
  }
  for ds in sys.GetDistrictStates() {
    if ds.renown >= 80.0 {
      return true;
    }
  }
  return false;
}

func CBCyberbaneCondition(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>) -> Bool {
  let stats = sys.GetStats();
  let rivalsSlain = IsDefined(stats) ? stats.rivalsSlain : 0;
  return score.GetRenown() >= 850.0
      && score.GetDread() >= CBConfig.TitleDreadNeeded()
      && rivalsSlain >= 3
      && CBCountFactionsFeared(sys, score, CBConfig.TitleFearNeeded()) >= 3;
}
