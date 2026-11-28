// Cyberbane - The Crew page's words
//
// What the Crew page's three views say: the Roster's line on the picked member, the Member view's file and numbers, and the
// Crew view's own lines; a member's climb as a bar, a piece of chrome's change before it goes in. Words only: the page
// (UI/Hud.reds) lays them out.

// The Crew page's views, left to right: the roster, one member, the wars, the squads, the crew's own page.
public func CBHudCrewViewCount() -> Int32 = 5

public func CBHudCrewViewWord(i: Int32) -> String {
  if i == 0 { return CBT(n"Cyberbane-Hud-ViewRoster"); }
  if i == 1 { return CBT(n"Cyberbane-Hud-ViewMember"); }
  if i == 2 { return CBT(n"Cyberbane-HubWar-ViewWar"); }
  if i == 3 { return CBT(n"Cyberbane-HubWar-ViewSquads"); }
  return CBT(n"Cyberbane-Hud-ViewCrew");
}

public func CBHudCrewViewHelp(i: Int32) -> String {
  if i == 0 { return CBT(n"Cyberbane-Hud-HelpViewRoster"); }
  if i == 1 { return CBT(n"Cyberbane-Hud-HelpViewMember"); }
  if i == 2 { return CBT(n"Cyberbane-HubWar-HelpViewWar"); }
  if i == 3 { return CBT(n"Cyberbane-HubWar-HelpViewSquads"); }
  return CBT(n"Cyberbane-Hud-HelpViewCrew");
}

// The screen each view opens.
public func CBHudCrewViewMode(i: Int32) -> Int32 {
  if i == 0 { return 0; }
  if i == 1 { return CBHudCrewMemberMode(); }
  if i == 2 { return 20; }
  if i == 3 { return 23; }
  return 7;
}

// ---- The War view's words ----

// Where a war stands when it is not just fighting: terms asked or demanded, to the end.
public func CBHubWarStateWord(f: ref<CBWarFront>) -> String {
  if !IsDefined(f) { return ""; }
  if f.state == CBWarStateTheyAsk() { return CBT(n"Cyberbane-HubWar-StateAsk"); }
  if f.state == CBWarStateTheyDemand() { return CBT(n"Cyberbane-HubWar-StateDemand"); }
  if f.state == CBWarStateToTheEnd() { return CBT(n"Cyberbane-HubWar-StateToTheEnd"); }
  return "";
}

// One war, in a few lines: how it stands, the crew's order, their move, the squads and what is missing, friends, losses.
public func CBHubWarFile(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>) -> String {
  if !IsDefined(f) {
    return "";
  }
  let label = CBCapFirst(CBFactionLabel(f.gang));
  let now = CBGameSeconds(game);
  let out = CBTf(n"Cyberbane-HubWar-FileHead", [CBCapFirst(CBWarName(f)), label, CBWarFrontWord(f.front), CBWarWearyWord(f.theirWeary), CBWarWearyWord(f.ourWeary)]);
  // The crew's order: on, regrouping, or ready.
  if f.order == CBWarOrderNone() {
    if now < f.orderAt {
      out += "\n" + CBTf(n"Cyberbane-HubWar-Regrouping", [CBClockWord(f.orderAt)]);
    } else {
      let second = CBCrewSecond(game);
      let sendsAt = f.orderAt + CBConfig.WarSecondIdleHours() * CBConfig.SecondsPerHour();
      out += "\n" + (IsDefined(second) && CBSecondRunsWars() ? CBTf(n"Cyberbane-HubWar-ReadySecond", [CBCrewFirst(sys, second), CBClockWord(sendsAt)])
                                                              : CBT(n"Cyberbane-HubWar-Ready"));
    }
  } else {
    if CBWarFightOnFor(game, f.gang, true) {
      out += "\n" + CBTf(n"Cyberbane-HubWar-FightingNow", [CBWarOrderWord(f.order)]);
    } else {
      if CBWarOrderFights(f.order) {
        let book = CBCrewBook.Get(game);
        out += "\n" + CBTf(n"Cyberbane-HubWar-OrderOn", [CBWarOrderWord(f.order), CBWarWhere(sys, game, f), CBClockWord(f.orderAt),
                                                         CBCrewWarPartyWords(sys, game, book, CBWarParty(game, f.gang))]);
      } else {
        out += "\n" + CBTf(n"Cyberbane-HubWar-OrderQuiet", [CBWarOrderWord(f.order), CBClockWord(f.orderAt)]);
      }
    }
  }
  // Their move: on its way, or the next one.
  if f.move != CBWarMoveNone() && !f.moveDone {
    if CBWarSpotKnown(f.MovePlace()) {
      out += "\n" + CBTf(n"Cyberbane-HubWar-TheirMovePlaced", [CBHubWarMoveWord(f.move), CBWarMoveWhere(f), CBClockWord(f.moveAt)]);
    } else {
      out += "\n" + (f.moveTold ? CBTf(n"Cyberbane-HubWar-TheirMoveKnown", [CBHubWarMoveWord(f.move), CBClockWord(f.moveAt)]) : CBT(n"Cyberbane-HubWar-TheirMoveUnknown"));
    }
  } else {
    out += "\n" + (now < f.scoutUntil ? CBTf(n"Cyberbane-HubWar-TheirNextAround", [CBClockWord(f.moveAt)]) : CBT(n"Cyberbane-HubWar-TheirMoveUnknown"));
  }
  if now < f.scoutUntil {
    out += "\n" + CBTf(n"Cyberbane-HubWar-TheirWeight", [s"\(RoundF(CBGangWarWeight(sys, game, f.gang)))"]);
  }
  let plan = CBSquadsPlanLine(sys, game, f);
  if StrLen(plan) > 0 {
    out += "\n" + plan;
  }
  if IsNameValid(f.ally) {
    out += "\n" + CBTf(n"Cyberbane-HubWar-AllyWithUs", [CBCapFirst(CBFactionLabel(f.ally))]);
  }
  if IsNameValid(f.theirAlly) {
    out += "\n" + CBTf(n"Cyberbane-HubWar-AllyWithThem", [CBCapFirst(CBFactionLabel(f.theirAlly))]);
  }
  if f.ourLost > 0 || f.theirLost > 0 {
    out += "\n" + CBTf(n"Cyberbane-HubWar-Losses", [s"\(f.ourLost)", s"\(f.theirLost)"]);
  }
  return out;
}

// The crew's last wars, newest first: their names and how each ended.
public func CBHubWarPastLines(sys: ref<CyberbaneSystem>, game: GameInstance, fb: ref<CBWarFrontBook>) -> String {
  let out = CBT(n"Cyberbane-HubWar-PastHeader");
  let shown = 0;
  let i = fb.PastCount() - 1;
  while i >= 0 && shown < 3 {
    let p = fb.PastAt(i);
    i -= 1;
    if IsDefined(p) {
      let how = CBT(n"Cyberbane-HubWar-PastLost");
      if p.how == CBWarEndTerms() { how = CBT(n"Cyberbane-HubWar-PastTerms"); }
      if p.how == CBWarEndBroken() { how = CBT(n"Cyberbane-HubWar-PastBroken"); }
      if p.how == CBWarEndCalledOff() { how = CBT(n"Cyberbane-HubWar-PastCalledOff"); }
      out += "\n" + CBTf(n"Cyberbane-HubWar-PastLine", [CBCapFirst(CBWarPastName(p)), CBFactionLabel(p.gang), how, s"\(Max(1, p.nights))", s"\(p.ourLost)"]);
      shown += 1;
    }
  }
  return out;
}

// A line of History for the crew's wars; "" for any other entry.
public func CBHubWarLogLine(e: ref<CBLogEntry>, gang: String) -> String {
  let v = RoundF(e.value);
  if Equals(e.kind, n"WarBegan") {
    return v == 1 ? CBTf(n"Cyberbane-HubWar-LogBeganByThem", [gang]) : CBTf(n"Cyberbane-HubWar-LogBegan", [gang]);
  }
  if Equals(e.kind, n"WarNight") {
    let order = v / 10;
    let outcome = v % 10 - 1;
    let how = outcome >= CBWarOutcomeWon() ? CBT(n"Cyberbane-HubWar-LogWon") : (outcome == CBWarOutcomeStalemate() ? CBT(n"Cyberbane-HubWar-LogEven") : CBT(n"Cyberbane-HubWar-LogLost"));
    return CBTf(n"Cyberbane-HubWar-LogNight", [CBWarOrderWord(order), gang, how]);
  }
  if Equals(e.kind, n"WarMove") {
    return CBTf(n"Cyberbane-HubWar-LogMove", [gang, CBHubWarMoveWord(v / 10), v % 10 == 1 ? CBT(n"Cyberbane-HubWar-LogHeld") : CBT(n"Cyberbane-HubWar-LogNotHeld")]);
  }
  if Equals(e.kind, n"WarEnded") {
    if v == CBWarEndTerms() { return CBTf(n"Cyberbane-HubWar-LogEndTerms", [gang]); }
    if v == CBWarEndBroken() { return CBTf(n"Cyberbane-HubWar-LogEndBroken", [gang]); }
    if v == CBWarEndCalledOff() { return CBTf(n"Cyberbane-HubWar-LogEndCalledOff", [gang]); }
    return CBTf(n"Cyberbane-HubWar-LogEndLost", [gang]);
  }
  if Equals(e.kind, n"WarTaken") { return CBTf(n"Cyberbane-HubWar-LogTaken", [gang]); }
  if Equals(e.kind, n"WarTookRival") { return CBTf(n"Cyberbane-HubWar-LogTookRival", [gang]); }
  if Equals(e.kind, n"WarAlly") { return CBTf(n"Cyberbane-HubWar-LogAlly", [gang]); }
  if Equals(e.kind, n"HoodTaken") { return CBTf(n"Cyberbane-HubWar-LogHood", [gang]); }
  if Equals(e.kind, n"CrewBought") { return CBTf(n"Cyberbane-HubWar-LogBought", [CBUpgradeWord(v)]); }
  return "";
}

public func CBHubWarMoveWord(move: Int32) -> String {
  if move == CBWarMoveCorner() { return CBT(n"Cyberbane-HubWar-MoveCorner"); }
  if move == CBWarMoveAmbush() { return CBT(n"Cyberbane-HubWar-MoveAmbush"); }
  if move == CBWarMoveRaid() { return CBT(n"Cyberbane-HubWar-MoveRaid"); }
  if move == CBWarMovePrice() { return CBT(n"Cyberbane-HubWar-MovePrice"); }
  if move == CBWarMoveLean() { return CBT(n"Cyberbane-HubWar-MoveLean"); }
  return CBT(n"Cyberbane-HubWar-MoveCoalition");
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
  let measured = CBCrewBaseOf(game, m.id);
  n.dps = IsDefined(measured) ? measured.dps * MaxF(p.cbCrewHitMult, 1.0) * CBOtherModsDamageScale(game, false, false) : 0.0;
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
  // What they lead and run, and what the wars left on them.
  let sb = CBSquadBook.Get(game);
  let squad = IsDefined(sb) ? sb.Of(m.id) : null;
  if IsDefined(squad) {
    out += CBTf(n"Cyberbane-HubWar-MemberLeads", [CBSquadName(sys, game, squad), s"\(squad.heads)"]);
  }
  let gb = CBCrewGangBook.Get(game);
  let runs = IsDefined(gb) ? gb.RunsWhere(m.id) : n"";
  if IsNameValid(runs) {
    out += CBTf(n"Cyberbane-HubWar-MemberRuns", [CBDistrictLabel(runs)]);
  }
  let marks = CBCrewMarksLine(game, m.id);
  if StrLen(marks) > 0 {
    out += CBTf(n"Cyberbane-HubWar-MemberMarks", [marks]);
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
  // The crew's wars: an order waiting on V with its deadline, a crew ready for one, their move when it is known, and
  // anybody of the crew held.
  let fb = CBWarFrontBook.Get(game);
  if IsDefined(fb) {
    let w = 0;
    while w < fb.Count() {
      let f = fb.At(w);
      w += 1;
      if IsDefined(f) {
        if CBWarOrderFights(f.order) && !f.orderDone && f.orderAt > 0.0 {
          ArrayPush(parts, CBTf(n"Cyberbane-HubWar-NowOrder", [CBWarOrderWord(f.order), CBFactionLabel(f.gang), CBClockWord(f.orderAt)]));
        }
        if f.order == CBWarOrderNone() && CBWarCanOrder(game, f) {
          ArrayPush(parts, CBTf(n"Cyberbane-HubWar-NowNoOrder", [CBFactionLabel(f.gang)]));
        }
        if f.moveTold && !f.moveDone && f.move != CBWarMoveNone() && f.moveAt > 0.0 {
          ArrayPush(parts, CBTf(n"Cyberbane-HubWar-NowMove", [CBCapFirst(CBFactionLabel(f.gang)), CBClockWord(f.moveAt)]));
        }
        if f.state == CBWarStateTheyAsk() || f.state == CBWarStateTheyDemand() {
          ArrayPush(parts, CBTf(n"Cyberbane-HubWar-NowTerms", [CBCapFirst(CBFactionLabel(f.gang))]));
        }
      }
    }
    let c = 0;
    while c < fb.CaptiveCount() {
      let cap = fb.CaptiveAt(c);
      c += 1;
      if IsDefined(cap) {
        ArrayPush(parts, CBTf(n"Cyberbane-HubWar-NowHeld", [CBWarCaptiveName(sys, game, cap), CBFactionLabel(cap.gang)]));
      }
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
