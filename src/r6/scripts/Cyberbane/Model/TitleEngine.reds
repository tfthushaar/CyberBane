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
      let rt = CyberbaneRuntime.Get();
      if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
        CBShowMessage(game, "Cyberbane: Title unlocked - " + CBTitleDisplay(sys, def), 5.0);
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
    return sys.GetPrimaryArchetypeIndex() == EnumInt(ECBArchetype.Brawler) && sys.TotalKills() >= 100;
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
  //
  // This was the only title in the mod with no condition at all: it hung off a deed, and deed
  // detection goes by payout size rather than quest identity, so it could never fire. Rather
  // than leave a title nobody can ever get, it now means what its name means - a great deal of
  // work that nobody could put a name to.
  if Equals(id, n"T_KONPEKI_GHOST") {
    return sys.GetPrimaryArchetypeIndex() == EnumInt(ECBArchetype.Ghost)
        && stats.unattributed >= CBConfig.KonpekiUnattributed();
  }
  if Equals(id, n"T_MERC_FROM") { return EnumInt(score.GetTier()) >= EnumInt(ECBRenownTier.LocalName); }
  if Equals(id, n"T_CYBERBANE") { return CBCyberbaneCondition(sys, score); }
  return false;   // deed-gated titles unlock through the deed system
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
    if fs.kills >= 75 && score.GetFactionFear(fs.id) >= 85.0 {
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
      && score.GetDread() >= 90.0
      && rivalsSlain >= 3
      && CBCountFactionsFeared(sys, score, 85.0) >= 3;
}
