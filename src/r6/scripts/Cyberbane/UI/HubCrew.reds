// Cyberbane - The Crew page's words
//
// What the Crew page's three views say: the Roster's line on the picked member, the Member view's file and numbers, and the
// Crew view's own lines; a member's climb as a bar, a piece of chrome's change before it goes in. Words only: the page
// (UI/Hud.reds) lays them out.

public func CBHudCrewViewWord(i: Int32) -> String {
  if i == 0 { return CBT(n"Cyberbane-Hud-ViewRoster"); }
  if i == 1 { return CBT(n"Cyberbane-Hud-ViewMember"); }
  return CBT(n"Cyberbane-Hud-ViewCrew");
}

public func CBHudCrewViewHelp(i: Int32) -> String {
  if i == 0 { return CBT(n"Cyberbane-Hud-HelpViewRoster"); }
  if i == 1 { return CBT(n"Cyberbane-Hud-HelpViewMember"); }
  return CBT(n"Cyberbane-Hud-HelpViewCrew");
}

// A multiplier as the game would show one: "x1.40".
public func CBHudMult(v: Float) -> String {
  return "x" + FloatToStringPrec(v, 2);
}

// A whole number with its thousands marked: "12,450".
public func CBHudNum(v: Float) -> String {
  let n = RoundF(MaxF(v, 0.0));
  let out = "";
  while n >= 1000 {
    let part = n % 1000;
    let pad = part < 10 ? "00" : (part < 100 ? "0" : "");
    out = "," + pad + s"\(part)" + out;
    n = n / 1000;
  }
  return s"\(n)" + out;
}

// Their numbers for the Member view: worked out from what their body had when last out, or read off the body itself
// while they are out with V.
public func CBCrewNumbersNow(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>) -> ref<CBCrewKitNumbers> {
  let n = CBCrewKitPreview(game, m);
  if !IsDefined(book) || !IsDefined(m) {
    return n;
  }
  let k = book.OutIndexOfMember(m.id);
  if k < 0 {
    return n;
  }
  let p = GameInstance.FindEntityByID(game, book.outBody[k]) as ScriptedPuppet;
  let stats = GameInstance.GetStatsSystem(game);
  let pools = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(p) || !p.IsAttached() || p.IsDead() || !p.cbCrewKitted || !CBNpcSafe(sys, p) || !IsDefined(stats) || !IsDefined(pools) {
    return n;
  }
  let id = Cast<StatsObjectID>(p.GetEntityID());
  n.known = true;
  n.maxHealth = stats.GetStatValue(id, gamedataStatType.Health);
  n.armourPoints = MaxF(stats.GetStatValue(id, gamedataStatType.Armor), 0.0);
  n.toughness = CBEffectiveHealth(game, stats, id);
  n.dps = MaxF(stats.GetStatValue(id, gamedataStatType.NPCDamage), 0.0) * MaxF(p.cbCrewHitMult, 1.0);
  n.current = pools.GetStatPoolValue(id, gamedataStatPoolType.Health, false);
  return n;
}

public func CBCrewHealthText(n: ref<CBCrewKitNumbers>) -> String {
  if !n.known {
    return CBT(n"Cyberbane-Hud-StatAfterFirstCall");
  }
  if n.current > 0.0 {
    return CBTf(n"Cyberbane-Hud-StatHealthOut", [CBHudNum(n.current), CBHudNum(n.maxHealth), CBHudNum(n.toughness)]);
  }
  return CBTf(n"Cyberbane-Hud-StatHealthValue", [CBHudNum(n.maxHealth), CBHudNum(n.toughness)]);
}

public func CBCrewArmourText(n: ref<CBCrewKitNumbers>) -> String {
  return n.known ? CBHudNum(n.armourPoints) : CBT(n"Cyberbane-Hud-StatAfterFirstCall");
}

public func CBCrewDamageText(n: ref<CBCrewKitNumbers>) -> String {
  if n.known && n.dps > 0.0 {
    return CBTf(n"Cyberbane-Hud-StatDamageValue", [CBHudNum(n.dps)]);
  }
  return n.share > 0.0 ? CBTf(n"Cyberbane-Hud-StatAtLeastYours", [s"\(RoundF(n.share * 100.0))"]) : CBT(n"Cyberbane-Hud-StatOffTheStreet");
}

// "82% of you", or nothing when either side can't be read.
public func CBCrewShareText(share: Float) -> String {
  return share > 0.0 ? StrUpper(CBTf(n"Cyberbane-Hud-StatShareOfYou", [s"\(RoundF(share * 100.0))"])) : "";
}

// The help line under each of the three: what the number is, and V's own beside it.
public func CBCrewStatHelp(n: ref<CBCrewKitNumbers>, which: Int32) -> String {
  let out = CBT(n"Cyberbane-Hud-HelpStatDamage");
  if which == 0 {
    out = CBT(n"Cyberbane-Hud-HelpStatHealth");
  }
  if which == 1 {
    out = CBT(n"Cyberbane-Hud-HelpStatArmour");
  }
  if which == 0 && n.vHealth > 0.0 {
    out += " " + CBTf(n"Cyberbane-Hud-HelpStatYourHealth", [CBHudNum(n.vHealth), CBHudNum(n.vToughness)]);
  }
  if which == 2 && n.vDps > 0.0 {
    out += " " + CBTf(n"Cyberbane-Hud-HelpStatYourDamage", [CBHudNum(n.vDps)]);
  }
  out += " " + CBTf(n"Cyberbane-Hud-HelpStatRankShare", [s"\(RoundF(n.share * 100.0))", s"\(RoundF(CBConfig.CrewVShareLegend() * 100.0))"]);
  if !n.known {
    out += " " + CBT(n"Cyberbane-Hud-HelpStatNotSeen");
  }
  return out;
}

// How far they are to their next rank by fights won, 0 to 1 (1 at the top of what wins alone can bring).
public func CBCrewRankProgress(game: GameInstance, m: ref<CBCrewMember>) -> Float {
  if !IsDefined(m) || CBCrewRankOf(game, m) >= 6 {
    return 1.0;
  }
  let winRank = CBCrewRank(m.wins);
  if winRank >= 4 {
    return 1.0;
  }
  let from = winRank <= 1 ? 0 : CBCrewWinsFor(winRank);
  let to = CBCrewWinsFor(winRank + 1);
  if to <= from {
    return 1.0;
  }
  return ClampF(Cast<Float>(m.wins - from) / Cast<Float>(to - from), 0.0, 1.0);
}

// The Roster's word on the picked one: who they are in a line, and whatever they are asking for.
public func CBCrewRosterLine(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) || !IsDefined(book) {
    return "";
  }
  let out = CBTf(n"Cyberbane-Hud-RosterLine", [StrUpper(CBCrewName(sys, m)), CBCrewTemperWord(CBCrewTemper(m)), CBCrewRankShort(game, m),
                                                s"\(m.loyalty)", CBCrewLoyaltyWord(m.loyalty)]);
  if CBCrewIsSecond(game, m.id) {
    out += CBT(n"Cyberbane-Hud-RosterSecond");
  }
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) && lb.AskId() == m.id {
    let ask = CBCrewAskWords(sys, game, lb);
    if StrLen(ask) > 0 {
      out += CBTf(n"Cyberbane-Hud-RosterAsking", [ask]);
    }
  }
  out += CBT(n"Cyberbane-Hud-RosterSeeMember");
  return out;
}

// What the chrome adds that is not a multiplier: dodge and the resistances, by the numbers.
public func CBCrewKitExtrasLine(n: ref<CBCrewKitNumbers>) -> String {
  if !IsDefined(n) {
    return "";
  }
  let parts: array<String>;
  let seenStat: array<gamedataStatType>;
  let seenType: array<gameStatModifierType>;
  let i = 0;
  while i < ArraySize(n.stats) {
    let stat = n.stats[i];
    let kind = n.types[i];
    let seen = false;
    let j = 0;
    while j < ArraySize(seenStat) {
      if Equals(seenStat[j], stat) && Equals(seenType[j], kind) {
        seen = true;
      }
      j += 1;
    }
    if !seen {
      ArrayPush(seenStat, stat);
      ArrayPush(seenType, kind);
      let total = n.Sum(stat, kind);
      if Equals(kind, gameStatModifierType.Multiplier) {
        total += 1.0;   // Sum gives the gain; the part wants the multiplier back
      }
      if Equals(stat, gamedataStatType.Evasion) && Equals(kind, gameStatModifierType.Additive) {
        total += n.evasion;
      }
      let part = CBCrewStatPart(stat, kind, total);
      if StrLen(part) > 0 {
        ArrayPush(parts, part);
      }
    }
    i += 1;
  }
  if n.evasion > 0.0 && !ArrayContains(seenStat, gamedataStatType.Evasion) {
    ArrayPush(parts, CBCrewStatPart(gamedataStatType.Evasion, gameStatModifierType.Additive, n.evasion));
  }
  let out = "";
  let k = 0;
  while k < ArraySize(parts) && k < 3 {
    out += (k > 0 ? ", " : "") + parts[k];
    k += 1;
  }
  if ArraySize(parts) > 3 {
    out += CBTf(n"Cyberbane-Hud-AndMore", [s"\(ArraySize(parts) - 3)"]);
  }
  return out;
}

// Before it goes in: what the piece changes in their numbers. "Armour x1.30 to x1.48"; the flat stats otherwise.
public func CBCrewChromeChange(game: GameInstance, m: ref<CBCrewMember>, rec: TweakDBID) -> String {
  let before = CBCrewKitPreview(game, m);
  let after = CBCrewKitPreview(game, m, rec);
  let out = "";
  if before.known {
    // Their real numbers: "armour 380 to 420, damage 352 to 380 a second".
    if RoundF(after.armourPoints) != RoundF(before.armourPoints) {
      out = CBTf(n"Cyberbane-Hud-ChangeNumbers", [CBT(n"Cyberbane-Hud-StatArmourWord"), CBHudNum(before.armourPoints), CBHudNum(after.armourPoints)]);
    }
    if RoundF(after.dps) != RoundF(before.dps) {
      out += (StrLen(out) > 0 ? ", " : "") + CBTf(n"Cyberbane-Hud-ChangeDamage", [CBHudNum(before.dps), CBHudNum(after.dps)]);
    }
    if RoundF(after.maxHealth) != RoundF(before.maxHealth) {
      out += (StrLen(out) > 0 ? ", " : "") + CBTf(n"Cyberbane-Hud-ChangeNumbers", [CBT(n"Cyberbane-Hud-StatHealthWord"), CBHudNum(before.maxHealth), CBHudNum(after.maxHealth)]);
    }
    return out;
  }
  if AbsF(after.armour - before.armour) >= 0.005 {
    out = CBTf(n"Cyberbane-Hud-ChangeFromTo", [CBT(n"Cyberbane-Hud-StatArmourWord"), FloatToStringPrec(before.armour, 2), FloatToStringPrec(after.armour, 2)]);
  }
  if AbsF(after.damage - before.damage) >= 0.005 {
    out += (StrLen(out) > 0 ? ", " : "") + CBTf(n"Cyberbane-Hud-ChangeFromTo", [CBT(n"Cyberbane-Hud-StatDamageWord"), FloatToStringPrec(before.damage, 2), FloatToStringPrec(after.damage, 2)]);
  }
  if AbsF(after.health - before.health) >= 0.005 {
    out += (StrLen(out) > 0 ? ", " : "") + CBTf(n"Cyberbane-Hud-ChangeFromTo", [CBT(n"Cyberbane-Hud-StatHealthWord"), FloatToStringPrec(before.health, 2), FloatToStringPrec(after.health, 2)]);
  }
  return out;
}

// What a weapon handed over would do for them, for the help line of the pick list.
public func CBCrewWeaponHelp(data: wref<gameItemData>) -> String {
  if !IsDefined(data) {
    return "";
  }
  let seat = CBLowFirst(CBCrewSeatWord(CBCrewSeatForWeapon(data.GetItemType())));
  let tier = CBLowFirst(CBCrewTierWord(CBCrewTierOf(RPGManager.GetItemQuality(data))));
  return CBCrewWeaponInHandOn() ? CBTf(n"Cyberbane-Hud-HelpWeaponInHand", [seat])
                                : CBTf(n"Cyberbane-Hud-HelpWeaponPick", [seat, tier]);
}

// The Member view's left column: who they are, their story, their rank and what the next one brings.
public func CBCrewMemberFile(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) || !IsDefined(book) {
    return "";
  }
  let now = CBGameSeconds(game);
  let out = StrUpper(CBCrewName(sys, m)) + "\n";
  let home = NotEquals(m.home, n"") ? CBDistrictLabel(m.home) : CBT(n"Cyberbane-Crew-TheCity");
  let since = CBHudSince(now, m.joinedAt);
  out += CBTf(n"Cyberbane-Hud-MemberTemper", [CBCrewTemperWord(CBCrewTemper(m))]);
  out += CBTf(n"Cyberbane-Crew-ALivesIn", [s"\(CBCrewSeatWord(m.seat))", s"\(CBCrewFromWords(m))", s"\(home)", (StrLen(since) > 0 ? CBTf(n"Cyberbane-Crew-WithYou", [s"\(since)"]) : ".")]);
  let state = CBCrewStateWord(book, m, now);
  out += CBTf(n"Cyberbane-Hud-MemberNow", [CBCapFirst(StrLower(state)), s"\(m.loyalty)", CBCrewLoyaltyWord(m.loyalty)]);
  if CBCrewIsSecond(game, m.id) {
    out += CBT(n"Cyberbane-Hud-MemberSecond");
  }
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) && lb.AskId() == m.id {
    let ask = CBCrewAskWords(sys, game, lb);
    if StrLen(ask) > 0 {
      out += CBTf(n"Cyberbane-Hud-MemberAsking", [ask, s"\(Max(1, CeilF((lb.AskUntil() - now) / CBConfig.SecondsPerHour())))"]);
    }
  }
  // Their rank, what it gives them, and what the next one needs and brings.
  let rank = CBCrewRankOf(game, m);
  out += "\n" + CBTf(n"Cyberbane-Hud-MemberRank", [CBCrewRankWord(rank), s"\(rank)", CBCrewRankGains(rank)]);
  let next = CBCrewNextRankLine(game, m);
  if StrLen(next) > 0 && rank < 6 {
    out += next + CBTf(n"Cyberbane-Hud-MemberNextBrings", [CBCrewRankGains(rank + 1)]);
  }
  // Their story, the newest lines.
  let story = CBCrewStoryLines(sys, game, m);
  if ArraySize(story) > 0 {
    out += "\n" + CBT(n"Cyberbane-Hud-MemberStory");
    let from = Max(0, ArraySize(story) - CBConfig.CrewStoryShown());
    let i = from;
    while i < ArraySize(story) {
      out += story[i] + "\n";
      i += 1;
    }
  }
  return out;
}

// The Crew view's own lines, under its standing: V's second, a funeral owed, the wars on and won, the crew's home.
public func CBCrewPageLines(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let out = "";
  let second = CBCrewSecond(game);
  out += IsDefined(second) ? CBTf(n"Cyberbane-Hud-PageSecond", [CBCrewName(sys, second)]) : CBT(n"Cyberbane-Hud-PageNoSecond");
  let wars = CBCrewWarsOnWord(game);
  if StrLen(wars) > 0 {
    out += CBTf(n"Cyberbane-Hud-PageWars", [wars]);
  }
  let lb = CBCrewLifeBook.Get(game);
  let book = CBCrewBook.Get(game);
  if IsDefined(lb) && lb.FuneralState() == 1 && IsDefined(book) {
    let past = book.FindPast(lb.FuneralPast());
    let who = IsDefined(past) ? CBCrewFirstName(sys, past.kind, past.faction, past.rival, past.seed) : CBT(n"Cyberbane-Hud-OneOfYours");
    out += CBTf(n"Cyberbane-Hud-PageFuneral", [who, CBClockWordAt(CBConfig.CrewFuneralHour()), CBDistrictLabel(lb.FuneralDistrict())]);
  }
  if IsDefined(lb) && lb.HomeSet() {
    out += CBTf(n"Cyberbane-Hud-PageHome", [CBDistrictLabel(lb.HomeDistrict())]);
  }
  return out;
}

// A district on the Hub's map, as the crew sees it: who of them lives there, a war on the gang that holds it, the
// crew's own corners and a counterattack coming, and the shops' tax waiting there.
public func CBCrewMapLines(sys: ref<CyberbaneSystem>, game: GameInstance, d: CName) -> String {
  let out = "";
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !CBMyCrewOn() || !IsNameValid(d) {
    return out;
  }
  let names = "";
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    if IsDefined(m) && Equals(m.home, d) {
      names += (StrLen(names) > 0 ? ", " : "") + CBCrewFirst(sys, m);
    }
    i += 1;
  }
  if StrLen(names) > 0 {
    out += CBTf(n"Cyberbane-Hud-MapCrewLives", [names]);
  }
  let holder = CBTurfHolder(sys, game, d);
  if CBCrewAtWarWith(game, holder) {
    out += CBTf(n"Cyberbane-Hud-MapCrewWar", [CBFactionLabel(holder)]);
  }
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) {
    if (lb.CaState() == 1 || lb.CaState() == 2) && Equals(lb.CaDistrict(), d) {
      out += CBTf(n"Cyberbane-Hud-MapCounter", [CBFactionLabel(lb.CaGang())]);
    }
    let owed = lb.TaxOwed(d);
    if owed > 0 {
      out += CBTf(n"Cyberbane-Hud-MapTaxOwed", [s"\(owed)"]);
    }
    if lb.HomeSet() && Equals(lb.HomeDistrict(), d) {
      out += CBT(n"Cyberbane-Hud-MapCrewHome");
    }
  }
  return out;
}

// The Standing page's "right now": who is on V now or coming, and the crew's business waiting on V, in one line;
// "" when nothing is.
public func CBHudRightNow(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let parts: array<String>;
  if CBHuntersOut(sys, game) {
    let gang = sys.GetHuntFaction();
    ArrayPush(parts, IsNameValid(gang) ? CBTf(n"Cyberbane-Hud-NowHuntedBy", [CBFactionLabel(gang)]) : CBT(n"Cyberbane-Hud-NowHunted"));
  } else {
    let pending = sys.GetPendingSquadFaction();
    if IsNameValid(pending) {
      ArrayPush(parts, CBTf(n"Cyberbane-Hud-NowComing", [CBFactionLabel(pending), CBTimeText(sys.GetPendingSquadTicks())]));
    }
  }
  let lb = CBCrewLifeBook.Get(game);
  if IsDefined(lb) {
    if lb.CaState() == 1 {
      ArrayPush(parts, CBTf(n"Cyberbane-Hud-NowCounter", [CBFactionLabel(lb.CaGang()), CBDistrictLabel(lb.CaDistrict())]));
    }
    if lb.FuneralState() == 1 {
      ArrayPush(parts, CBTf(n"Cyberbane-Hud-NowFuneral", [CBDistrictLabel(lb.FuneralDistrict())]));
    }
    let ask = CBCrewAskWords(sys, game, lb);
    let book = CBCrewBook.Get(game);
    let asker = IsDefined(book) && lb.AskId() > 0 ? book.Find(lb.AskId()) : null;
    if StrLen(ask) > 0 && IsDefined(asker) {
      ArrayPush(parts, CBTf(n"Cyberbane-Hud-NowAsk", [CBCrewFirst(sys, asker), ask]));
    }
  }
  let tl = CBRivalTimelineBook.Get(game);
  if IsDefined(tl) && tl.CardRival() > 0 {
    let r = sys.FindRivalById(tl.CardRival());
    if IsDefined(r) {
      ArrayPush(parts, CBTf(n"Cyberbane-Hud-NowCard", [CBRivalDisplayName(sys.GetContent(), r), CBDistrictLabel(tl.CardDistrict())]));
    }
  }
  if ArraySize(parts) == 0 {
    return "";
  }
  let out = "";
  for p in parts {
    out += (StrLen(out) > 0 ? " " : "") + p;
  }
  return CBTf(n"Cyberbane-Hud-RightNowBox", [out]);
}
