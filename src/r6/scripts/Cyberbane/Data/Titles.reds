// Cyberbane — Title registry seed (spec Appendix G)
//
// id, display name, priority (higher wins the auto active title: Cyberbane >
// Living Legend > faction/district > others), hidden (shown as ??? until earned).
// Conditions are evaluated in code (Model/TitleEngine.reds). District- and
// faction-parameterised titles ({DISTRICT}/{FACTION}) use the generic name here;
// token substitution for the specific place/gang arrives with the Hub.

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
  c.AddTitle(CBMakeTitle(n"T_KONPEKI_GHOST",     "Konpeki Ghost",             40, false));
  c.AddTitle(CBMakeTitle(n"T_UNTOUCHABLE",       "Untouchable",               35, true));
  c.AddTitle(CBMakeTitle(n"T_RED_TIDE",          "Red Tide",                  35, true));
  c.AddTitle(CBMakeTitle(n"T_MAXTAC_PROBLEM",    "MaxTac's Problem",          35, true));
  c.AddTitle(CBMakeTitle(n"T_MERCIFUL",          "The Merciful",              35, true));
  c.AddTitle(CBMakeTitle(n"T_LANDLORD",          "Feared Landlord",           30, true));
  c.AddTitle(CBMakeTitle(n"T_MERC_FROM",         "The Merc from the District", 20, false));
}
