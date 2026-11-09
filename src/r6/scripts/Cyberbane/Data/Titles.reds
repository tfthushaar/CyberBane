// Cyberbane - Title registry seed (spec Appendix G)
//
// id, display name, priority (higher wins the auto active title: Cyberbane >
// Living Legend > faction/district > others), hidden (shown as ??? until earned).
// Konpeki Ghost used to sit here. It is tied to one specific quest played one specific way,
// and Cyberbane has no per-quest detection (job completion is recognised by payout size, not
// by name), so it could never be awarded. Offering a title nobody can earn is worse than not
// offering it; if per-quest tracking is ever added, put it back.
//
// Conditions are evaluated in code (Model/TitleEngine.reds). The six district- and
// faction-parameterised titles keep their generic wording here and are rewritten at display
// time by Model/TitleNaming.reds, which fills in the actual place or gang ("Butcher of
// Watson"). The generic strings below are the fallback for when nothing qualifies yet, so
// they must stay readable on their own.

public func CBSeedTitles(c: ref<CyberbaneContent>) -> Void {
  c.AddTitle(CBMakeTitle(n"T_CYBERBANE",         "Cyberbane",                100, true));
  c.AddTitle(CBMakeTitle(n"T_LIVING_LEGEND",     "Living Legend",             90, false));
  c.AddTitle(CBMakeTitle(n"T_FACTION_NIGHTMARE", "A Faction's Nightmare",     60, false));
  c.AddTitle(CBMakeTitle(n"T_FACTION_FRIEND",    "Friend of a Faction",       55, false));
  c.AddTitle(CBMakeTitle(n"T_BUTCHER_OF",        "Butcher of the District",   50, false));
  c.AddTitle(CBMakeTitle(n"T_GHOST_OF",          "Ghost of the District",     50, false));
  c.AddTitle(CBMakeTitle(n"T_RIVAL_BREAKER",     "Rival-Breaker",             45, false));
  c.AddTitle(CBMakeTitle(n"T_DISTRICT_PROBLEM",  "The District's Problem",    45, false));
  c.AddTitle(CBMakeTitle(n"T_CHROME_SAINT",      "Chrome Saint",              40, false));
  c.AddTitle(CBMakeTitle(n"T_GLITCH",            "Glitch in the System",      40, false));
  c.AddTitle(CBMakeTitle(n"T_FIST",              "Fist of Night City",        40, false));
  c.AddTitle(CBMakeTitle(n"T_PSYCHO_WHISPERER",  "Psycho Whisperer",          40, false));
  c.AddTitle(CBMakeTitle(n"T_PSYCHO_HUNTER",     "Psycho Hunter",             40, false));
  c.AddTitle(CBMakeTitle(n"T_UNTOUCHABLE",       "Untouchable",               35, true));
  c.AddTitle(CBMakeTitle(n"T_RED_TIDE",          "Red Tide",                  35, true));
  c.AddTitle(CBMakeTitle(n"T_MAXTAC_PROBLEM",    "MaxTac's Problem",          35, true));
  c.AddTitle(CBMakeTitle(n"T_MERCIFUL",          "The Merciful",              35, true));
  // Dropped from this table once and given a condition in 1.2.0, which nothing could reach with the
  // title not listed here. The Heist still awarded it, as the raw id: "Heard them calling you
  // T_KONPEKI_GHOST today."
  c.AddTitle(CBMakeTitle(n"T_KONPEKI_GHOST",     "Konpeki Ghost",             35, false));
  c.AddTitle(CBMakeTitle(n"T_LANDLORD",          "Feared Landlord",           30, true));
  c.AddTitle(CBMakeTitle(n"T_MERC_FROM",         "The Merc from the District", 20, false));
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
  let t = CBPerkOf(c, n"T_CYBERBANE", "Enemies are 25% more likely to break and people read you as 15% more frightening. Bounties pay 25% more. Crews send one extra.");
  t.breakMult = 1.25;
  t.crowdMult = 1.15;
  t.bountyMult = 1.25;
  t.crewDelta = 1;

  t = CBPerkOf(c, n"T_LIVING_LEGEND", "You earn an extra 10% on every job and vendors charge 5% less. 10% more people recognise you.");
  t.gigBonus = 0.10;
  t.priceMod = -0.05;
  t.recognitionAdd = 0.10;

  t = CBPerkOf(c, n"T_FACTION_NIGHTMARE", "Enemies are 20% more likely to break. Paying a gang off costs 25% more.");
  t.breakMult = 1.2;
  t.peaceMult = 1.25;

  t = CBPerkOf(c, n"T_FACTION_FRIEND", "Paying a gang off costs 30% less, and each kill costs you 25% less standing with that gang.");
  t.peaceMult = 0.7;
  t.standingLossMult = 0.75;

  t = CBPerkOf(c, n"T_BUTCHER_OF", "Your kills hurt a gang's hold on its streets 30% more. Each kill costs you 25% more standing.");
  t.turfMult = 1.3;
  t.standingLossMult = 1.25;

  t = CBPerkOf(c, n"T_GHOST_OF", "Hunters find you 20% less easily, and 10% fewer people recognise you.");
  t.senseMult = 0.8;
  t.recognitionAdd = -0.10;

  t = CBPerkOf(c, n"T_RIVAL_BREAKER", "Bounties pay 40% more.");
  t.bountyMult = 1.4;

  t = CBPerkOf(c, n"T_DISTRICT_PROBLEM", "Vendors charge 6% less to keep you happy. 5% more people recognise you.");
  t.priceMod = -0.06;
  t.recognitionAdd = 0.05;

  t = CBPerkOf(c, n"T_CHROME_SAINT", "People read you as 15% more frightening, and enemies are 10% more likely to break.");
  t.crowdMult = 1.15;
  t.breakMult = 1.1;

  t = CBPerkOf(c, n"T_GLITCH", "Hunters give up on you 25% sooner.");
  t.giveUpMult = 0.75;

  t = CBPerkOf(c, n"T_FIST", "Enemies are 15% more likely to break, and kills earn you 10% more Renown.");
  t.breakMult = 1.15;
  t.renownMult = 1.1;

  t = CBPerkOf(c, n"T_PSYCHO_WHISPERER", "Sparing people earns 50% more goodwill with their gang.");
  t.mercyMult = 1.5;

  t = CBPerkOf(c, n"T_PSYCHO_HUNTER", "Bounties pay 20% more.");
  t.bountyMult = 1.2;

  t = CBPerkOf(c, n"T_UNTOUCHABLE", "Hunters find you 15% less easily and give up on you 15% sooner.");
  t.senseMult = 0.85;
  t.giveUpMult = 0.85;

  t = CBPerkOf(c, n"T_RED_TIDE", "Enemies are 20% more likely to break. 10% more people recognise you.");
  t.breakMult = 1.2;
  t.recognitionAdd = 0.10;

  t = CBPerkOf(c, n"T_MAXTAC_PROBLEM", "Crews, Rivals and apex squads leave 25% more loot.");
  t.lootMult = 1.25;

  t = CBPerkOf(c, n"T_MERCIFUL", "Sparing people earns twice the goodwill and paying a gang off costs 20% less. People find you 25% less frightening.");
  t.mercyMult = 2.0;
  t.peaceMult = 0.8;
  t.crowdMult = 0.75;

  t = CBPerkOf(c, n"T_KONPEKI_GHOST", "Hunters find you 25% less easily and 15% fewer people recognise you. Kills earn you 10% less Renown.");
  t.senseMult = 0.75;
  t.recognitionAdd = -0.15;
  t.renownMult = 0.9;

  t = CBPerkOf(c, n"T_LANDLORD", "Tribute pays 50% more.");
  t.tributeMult = 1.5;

  t = CBPerkOf(c, n"T_MERC_FROM", "You earn an extra 5% on every job and vendors charge 2% less.");
  t.gigBonus = 0.05;
  t.priceMod = -0.02;
}
