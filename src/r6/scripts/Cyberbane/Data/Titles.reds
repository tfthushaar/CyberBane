// Cyberbane - Title registry seed (spec Appendix G)
//
// id, display name, priority (higher wins the auto active title: Cyberbane >
// Living Legend > faction/district > others), hidden (shown as ??? until earned).
// Konpeki Ghost is earned from The Heist's own quest fact (Data/Deeds.reds, q005_done) or by the
// unseen-kill count in Model/TitleEngine.reds.

public func CBSeedTitles(c: ref<CyberbaneContent>) -> Void {
  c.AddTitle(CBMakeTitle(n"T_CYBERBANE",         CBT(n"Cyberbane-Titles-Cyberbane"),                100, true));
  c.AddTitle(CBMakeTitle(n"T_LIVING_LEGEND",     CBT(n"Cyberbane-Titles-LivingLegend"),             90, false));
  c.AddTitle(CBMakeTitle(n"T_FACTION_NIGHTMARE", CBT(n"Cyberbane-Titles-AFactionSNightmare"),     60, false));
  c.AddTitle(CBMakeTitle(n"T_FACTION_FRIEND",    CBT(n"Cyberbane-Titles-FriendOfAFaction"),       55, false));
  c.AddTitle(CBMakeTitle(n"T_BUTCHER_OF",        CBT(n"Cyberbane-Titles-ButcherOfTheDistrict"),   50, false));
  c.AddTitle(CBMakeTitle(n"T_GHOST_OF",          CBT(n"Cyberbane-Titles-GhostOfTheDistrict"),     50, false));
  c.AddTitle(CBMakeTitle(n"T_RIVAL_BREAKER",     CBT(n"Cyberbane-Titles-RivalBreaker"),             45, false));
  c.AddTitle(CBMakeTitle(n"T_DISTRICT_PROBLEM",  CBT(n"Cyberbane-Titles-TheDistrictSProblem"),    45, false));
  c.AddTitle(CBMakeTitle(n"T_CHROME_SAINT",      CBT(n"Cyberbane-Titles-ChromeSaint"),              40, false));
  c.AddTitle(CBMakeTitle(n"T_GLITCH",            CBT(n"Cyberbane-Titles-GlitchInTheSystem"),      40, false));
  c.AddTitle(CBMakeTitle(n"T_FIST",              CBT(n"Cyberbane-Titles-FistOfNightCity"),        40, false));
  c.AddTitle(CBMakeTitle(n"T_PSYCHO_WHISPERER",  CBT(n"Cyberbane-Titles-PsychoWhisperer"),          40, false));
  c.AddTitle(CBMakeTitle(n"T_PSYCHO_HUNTER",     CBT(n"Cyberbane-Titles-PsychoHunter"),             40, false));
  c.AddTitle(CBMakeTitle(n"T_UNTOUCHABLE",       CBT(n"Cyberbane-Titles-Untouchable"),               35, true));
  c.AddTitle(CBMakeTitle(n"T_RED_TIDE",          CBT(n"Cyberbane-Titles-RedTide"),                  35, true));
  c.AddTitle(CBMakeTitle(n"T_MAXTAC_PROBLEM",    CBT(n"Cyberbane-Titles-MaxTacSProblem"),          35, true));
  c.AddTitle(CBMakeTitle(n"T_MERCIFUL",          CBT(n"Cyberbane-Titles-TheMerciful"),              35, true));
  c.AddTitle(CBMakeTitle(n"T_KONPEKI_GHOST",     CBT(n"Cyberbane-Titles-KonpekiGhost"),             35, false));
  c.AddTitle(CBMakeTitle(n"T_LANDLORD",          CBT(n"Cyberbane-Titles-FearedLandlord"),           30, true));
  c.AddTitle(CBMakeTitle(n"T_MERC_FROM",         CBT(n"Cyberbane-Titles-TheMercFromTheDistrict"), 20, false));
  c.AddTitle(CBMakeTitle(n"T_NUMBER_ONE",        CBT(n"Cyberbane-Titles-NumberOne"),                70, true));
  c.AddTitle(CBMakeTitle(n"T_WARLORD",           CBT(n"Cyberbane-Titles-Warlord"),                   65, true));
  c.AddTitle(CBMakeTitle(n"T_SEASON_SURVIVOR",   CBT(n"Cyberbane-Titles-OpenSeasonSurvivor"),      45, true));
  c.AddTitle(CBMakeTitle(n"T_PARTY_CRASHER",     CBT(n"Cyberbane-Titles-PartyCrasher"),             38, false));
  c.AddTitle(CBMakeTitle(n"T_TROPHY_HUNTER",     CBT(n"Cyberbane-Titles-TrophyHunter"),             38, false));
  c.AddTitle(CBMakeTitle(n"T_MADE",              CBT(n"Cyberbane-Titles-Made"),                      36, false));
  CBSeedTitlePerks(c);
}

// A title that does not exist still has to be writable, so a mistyped id here costs one title its
// effect and nothing else.
func CBPerkOf(c: ref<CyberbaneContent>, id: CName, effect: String) -> ref<CBTitleDef> {
  let t = c.GetTitle(id);
  if !IsDefined(t) {
    t = new CBTitleDef();
  }
  t.effect = effect;
  return t;
}

// What each title gets you while you go by it. Mostly good; the big ones cost something. The text is
// what the player reads, so a number changed here has to be changed in the sentence too.
func CBSeedTitlePerks(c: ref<CyberbaneContent>) -> Void {
  let n1 = CBPerkOf(c, n"T_NUMBER_ONE", CBT(n"Cyberbane-Titles-RewardsForKillsPay25More"));
  n1.bountyMult = 1.25;
  n1.crowdMult = 1.1;
  let wl = CBPerkOf(c, n"T_WARLORD", CBT(n"Cyberbane-Titles-EnemiesAre15MoreLikelyTo"));
  wl.breakMult = 1.15;
  let ss = CBPerkOf(c, n"T_SEASON_SURVIVOR", CBT(n"Cyberbane-Titles-EnemiesAre10MoreLikelyTo"));
  ss.breakMult = 1.1;
  let pc = CBPerkOf(c, n"T_PARTY_CRASHER", CBT(n"Cyberbane-Titles-RewardsForKillsPay10More"));
  pc.bountyMult = 1.1;
  let th = CBPerkOf(c, n"T_TROPHY_HUNTER", CBT(n"Cyberbane-Titles-RewardsForKillsPay15More"));
  th.bountyMult = 1.15;
  let md = CBPerkOf(c, n"T_MADE", CBT(n"Cyberbane-Titles-PeopleReadYouAs10More"));
  md.crowdMult = 1.1;
  let t = CBPerkOf(c, n"T_CYBERBANE", CBT(n"Cyberbane-Titles-EnemiesAre25MoreLikelyTo"));
  t.breakMult = 1.25;
  t.crowdMult = 1.15;
  t.bountyMult = 1.25;
  t.crewDelta = 1;

  t = CBPerkOf(c, n"T_LIVING_LEGEND", CBT(n"Cyberbane-Titles-YouEarnAnExtra10On"));
  t.gigBonus = 0.10;
  t.priceMod = -0.05;
  t.recognitionAdd = 0.10;

  t = CBPerkOf(c, n"T_FACTION_NIGHTMARE", CBT(n"Cyberbane-Titles-EnemiesAre20MoreLikelyTo"));
  t.breakMult = 1.2;
  t.peaceMult = 1.25;

  t = CBPerkOf(c, n"T_FACTION_FRIEND", CBT(n"Cyberbane-Titles-PayingAGangOffCosts30"));
  t.peaceMult = 0.7;
  t.standingLossMult = 0.75;

  t = CBPerkOf(c, n"T_BUTCHER_OF", CBT(n"Cyberbane-Titles-YourKillsHurtAGangS"));
  t.turfMult = 1.3;
  t.standingLossMult = 1.25;

  t = CBPerkOf(c, n"T_GHOST_OF", CBT(n"Cyberbane-Titles-HuntersFindYou20LessEasily"));
  t.senseMult = 0.8;
  t.recognitionAdd = -0.10;

  t = CBPerkOf(c, n"T_RIVAL_BREAKER", CBT(n"Cyberbane-Titles-RewardsForKillsPay40More"));
  t.bountyMult = 1.4;

  t = CBPerkOf(c, n"T_DISTRICT_PROBLEM", CBT(n"Cyberbane-Titles-VendorsCharge6LessToKeep"));
  t.priceMod = -0.06;
  t.recognitionAdd = 0.05;

  t = CBPerkOf(c, n"T_CHROME_SAINT", CBT(n"Cyberbane-Titles-PeopleReadYouAs15More"));
  t.crowdMult = 1.15;
  t.breakMult = 1.1;

  t = CBPerkOf(c, n"T_GLITCH", CBT(n"Cyberbane-Titles-HuntersGiveUpOnYou25"));
  t.giveUpMult = 0.75;

  t = CBPerkOf(c, n"T_FIST", CBT(n"Cyberbane-Titles-EnemiesAre15MoreLikelyTo-2"));
  t.breakMult = 1.15;
  t.renownMult = 1.1;

  t = CBPerkOf(c, n"T_PSYCHO_WHISPERER", CBT(n"Cyberbane-Titles-SparingPeopleEarns50MoreGoodwill"));
  t.mercyMult = 1.5;

  t = CBPerkOf(c, n"T_PSYCHO_HUNTER", CBT(n"Cyberbane-Titles-RewardsForKillsPay20More"));
  t.bountyMult = 1.2;

  t = CBPerkOf(c, n"T_UNTOUCHABLE", CBT(n"Cyberbane-Titles-HuntersFindYou15LessEasily"));
  t.senseMult = 0.85;
  t.giveUpMult = 0.85;

  t = CBPerkOf(c, n"T_RED_TIDE", CBT(n"Cyberbane-Titles-EnemiesAre20MoreLikelyTo-2"));
  t.breakMult = 1.2;
  t.recognitionAdd = 0.10;

  t = CBPerkOf(c, n"T_MAXTAC_PROBLEM", CBT(n"Cyberbane-Titles-CrewsRivalsAndApexSquadsLeave"));
  t.lootMult = 1.25;

  t = CBPerkOf(c, n"T_MERCIFUL", CBT(n"Cyberbane-Titles-SparingPeopleEarnsTwiceTheGoodwill"));
  t.mercyMult = 2.0;
  t.peaceMult = 0.8;
  t.crowdMult = 0.75;

  t = CBPerkOf(c, n"T_KONPEKI_GHOST", CBT(n"Cyberbane-Titles-HuntersFindYou25LessEasily"));
  t.senseMult = 0.75;
  t.recognitionAdd = -0.15;
  t.renownMult = 0.9;

  t = CBPerkOf(c, n"T_LANDLORD", CBT(n"Cyberbane-Titles-TributePays50More"));
  t.tributeMult = 1.5;

  t = CBPerkOf(c, n"T_MERC_FROM", CBT(n"Cyberbane-Titles-YouEarnAnExtra5On"));
  t.gigBonus = 0.05;
  t.priceMod = -0.02;
}
