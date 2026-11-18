// Cyberbane - Turf, money and war (2.4.0)
//
// The turf war gets a strategy, all through the systems that already run it:
//
//   [34] the war chest  each gang's money. Its streets earn it every day, a missed racket or deal adds to it;
//                       crews, apex squads, tribute and bounties spend it, and robbing a bagman or hitting a
//                       racket takes from it. A broke gang sends fewer people, and none when it cannot pay at all
//                       (CBCrewSizeFor, CBCrewReason, CBApexEligible).
//   [35] manpower       a massacre empties a gang's ranks for days: smaller crews, and none at all near empty.
//   [33] back a gang    in street talk, with a gang that likes V. V's work against its enemies counts double
//                       (CBCreditRivalGangs), and every week it holds streets it pays V a cut.
//   [70] set gangs on each other   a lie in street talk. Believed, the two gangs are far likelier to meet in a
//                       street fight near V (the event engine), and both lose a little ground.
//   [36] a common enemy two gangs at war that both fear and hate V stop fighting each other for a day, and their
//                       crews come together.
//   [37] V's own streets at Legend, a district where every gang is broken and V's name is everything: no crews
//                       come there, and the gangs passing through pay.
//   [U6] peace with terms  a price haggled by text, or peace for a favour (crash their enemy's next event); and the
//                       Tyger Claws' protection money for working Japantown ([11], their code).
//
// The Hub's gang page says how a gang stands (flush, counting every eddie, broke; ranks thin) on its "Right now"
// line. Everything is in the war book (Model/WarBook.reds). Each part has its switch; off, the war runs as before.

public func CBWarChestOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().warChest;
}

public func CBBackingOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().backAGang;
}

public func CBCommonEnemyOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHitSquadsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().commonEnemy);
}

public func CBOwnStreetsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().ownStreets;
}

public func CBInciteOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBStreetTalkOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkIncite);
}

public func CBTalkActBack() -> Int32 = 35
public func CBTalkActIncite() -> Int32 = 36
public func CBTalkActProtection() -> Int32 = 37
public func CBTalkActTerms() -> Int32 = 38

// ---- The chest and the ranks ---------------------------------------------------------------------------

public func CBWarSpend(game: GameInstance, gang: CName, amount: Float) -> Void {
  let book = CBWarBook.Get(game);
  if CBWarChestOn() && IsDefined(book) && amount > 0.0 && CBFactionFieldsSquads(gang) {
    book.AddChest(gang, -amount);
  }
}

public func CBWarEarn(game: GameInstance, gang: CName, amount: Float) -> Void {
  let book = CBWarBook.Get(game);
  if CBWarChestOn() && IsDefined(book) && amount > 0.0 && CBFactionFieldsSquads(gang) {
    book.AddChest(gang, amount);
  }
}

public func CBWarLoseMen(game: GameInstance, gang: CName, amount: Float) -> Void {
  let book = CBWarBook.Get(game);
  if CBWarChestOn() && IsDefined(book) && amount > 0.0 && CBFactionFieldsSquads(gang) {
    book.AddMen(gang, -amount);
  }
}

// How many of a crew this gang can field and pay for, as a share of what it would send.
public func CBWarCrewMult(game: GameInstance, gang: CName) -> Float {
  let book = CBWarBook.Get(game);
  if !CBWarChestOn() || !IsDefined(book) {
    return 1.0;
  }
  let chest = book.Chest(gang);
  let m = chest < CBConfig.WarChestBroke() ? CBConfig.WarBrokeCrew() : (chest > CBConfig.WarChestFlush() ? CBConfig.WarFlushCrew() : 1.0);
  return m * (0.5 + 0.5 * book.Men(gang) / 100.0);
}

// Can this gang send anybody at all?
public func CBWarCanSend(game: GameInstance, gang: CName) -> Bool {
  let book = CBWarBook.Get(game);
  if !CBWarChestOn() || !IsDefined(book) {
    return true;
  }
  return book.Chest(gang) >= CBConfig.WarCrewCost() * 2.0 && book.Men(gang) >= CBConfig.WarMenFloor();
}

public func CBWarCanSendApex(game: GameInstance, gang: CName) -> Bool {
  let book = CBWarBook.Get(game);
  return !CBWarChestOn() || !IsDefined(book) || book.Chest(gang) >= CBConfig.WarApexCost();
}

// How the gang stands, in words, for the Hub's "Right now" line. "" when there is nothing to say.
public func CBWarWords(game: GameInstance, gang: CName) -> String {
  let book = CBWarBook.Get(game);
  if !IsDefined(book) {
    return "";
  }
  let out = "";
  if CBWarChestOn() {
    let chest = book.Chest(gang);
    out = chest < CBConfig.WarChestBroke() ? "broke" : (chest > CBConfig.WarChestFlush() ? "flush" : "counting every eddie");
    let men = book.Men(gang);
    if men < 50.0 {
      out += men < CBConfig.WarMenFloor() ? ", nobody left to send" : ", ranks thin";
    }
  }
  if CBBackingOn() && Equals(book.Backed(), gang) {
    out += StrLen(out) > 0 ? ", and you back them" : "you back them";
  }
  let truce = book.TruceWith(gang, CBGameSeconds(game));
  if NotEquals(truce, n"") && CBCommonEnemyOn() {
    out += ", in a truce with " + CBFactionLabel(truce) + " against you";
  }
  return out;
}

// ---- Every in-game day (the slow tick) -----------------------------------------------------------------

public func CBWarTick(sys: ref<CyberbaneSystem>, game: GameInstance, days: Float) -> Void {
  let book = CBWarBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || days <= 0.0 {
    return;
  }
  let now = CBGameSeconds(game);
  // The chest fills from the streets each gang holds, and the ranks refill.
  if CBWarChestOn() {
    for fs in sys.GetFactionStates() {
      if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) {
        let streets = Cast<Float>(CBWarStreetsHeld(sys, game, fs.id));
        book.AddChest(fs.id, (CBConfig.WarIncomeBase() + CBConfig.WarIncomePerDistrict() * streets) * days);
        book.AddMen(fs.id, CBConfig.WarMenPerDay() * days);
      }
    }
  }
  CBWarBackedCut(sys, game, book, now);
  CBWarOwnStreets(sys, game, book, now);
  CBWarTruceRoll(sys, game, book, now, days);
  CBWarProtection(sys, game, book, now);
  if NotEquals(book.FavourFor(), n"") && now > book.FavourUntil() {
    book.SetFavour(n"", 0.0);
  }
}

func CBWarStreetsHeld(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Int32 {
  let n = 0;
  let i = 0;
  while i < CBDistrictCount() {
    if Equals(CBTurfHolder(sys, game, CBDistrictAt(i)), gang) {
      n += 1;
    }
    i += 1;
  }
  return n;
}

// ---- [33] Backing a gang -------------------------------------------------------------------------------

// Does V's work against this gang's enemies count double right now? Where the gang V backs is on the streets.
public func CBBackedHere(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Bool {
  let book = CBWarBook.Get(game);
  return CBBackingOn() && IsDefined(book) && IsDefined(sys) && Equals(book.Backed(), gang)
      && ArrayContains(CBTurfGangsHere(sys), gang);
}

func CBWarBackedCut(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, now: Float) -> Void {
  let gang = book.Backed();
  if !CBBackingOn() || Equals(gang, n"") || now < book.CutPaidAt() + 7.0 * CBConfig.SecondsPerDay() {
    return;
  }
  book.SetCutPaidAt(now);
  let streets = CBWarStreetsHeld(sys, game, gang);
  if streets <= 0 {
    return;
  }
  let cut = CBConfig.BackedCutPerDistrict() * streets;
  CBStreetGiveMoney(game, cut);
  CBFileLog(sys, n"WeeklyCut", now, CBEventDistrict(sys, game), gang, Cast<Float>(cut));
  if CBToastsOn() {
    let plural = streets == 1 ? "district" : "districts";
    CBPhoneFromGang(game, gang, s"Your cut for the week: \(cut)eb. \(streets) \(plural) ours, thanks to you.");
  }
}

// ---- [37] V's own streets -------------------------------------------------------------------------------

public func CBOwnDistrict(game: GameInstance, district: CName) -> Bool {
  let book = CBWarBook.Get(game);
  let i = CBDistrictIndex(district);
  return CBOwnStreetsOn() && IsDefined(book) && i >= 0 && CBMaskHas(book.OwnMask(), i);
}

func CBWarOwnStreets(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, now: Float) -> Void {
  if !CBOwnStreetsOn() {
    if book.OwnMask() != 0 {
      book.SetOwnMask(0);
    }
    return;
  }
  let score = sys.GetScore();
  let legend = IsDefined(score) && EnumInt(score.GetTier()) >= EnumInt(ECBRenownTier.Legend);
  let mask = 0;
  let i = 0;
  while i < CBDistrictCount() {
    let d = CBDistrictAt(i);
    let ds = sys.FindDistrict(d);
    if legend && IsDefined(ds) && ds.renown >= CBConfig.OwnStreetsRenown() && CBTurfWarsOn() {
      let gangs = CBTurfGangsIn(sys, game, d);
      let allBroken = ArraySize(gangs) > 0;
      for g in gangs {
        if !CBGangBroken(sys, g) {
          allBroken = false;
        }
      }
      if allBroken {
        mask = CBMaskSet(mask, i);
        if !CBMaskHas(book.OwnMask(), i) {
          CBFileLog(sys, n"OwnStreet", now, d, n"", 0.0);
          CBEventSay(game, s"Nobody runs \(CBDistrictLabel(d)) any more but you. The gangs pass through on your say-so.");
        }
      }
    }
    i += 1;
  }
  book.SetOwnMask(mask);
  // The gangs passing through pay, once a week.
  if mask != 0 && now >= book.OwnPaidAt() + 7.0 * CBConfig.SecondsPerDay() {
    book.SetOwnPaidAt(now);
    let n = 0;
    i = 0;
    while i < CBDistrictCount() {
      if CBMaskHas(mask, i) {
        n += 1;
      }
      i += 1;
    }
    let toll = CBConfig.OwnStreetsToll() * n;
    CBStreetGiveMoney(game, toll);
    CBFileLog(sys, n"OwnToll", now, CBEventDistrict(sys, game), n"", Cast<Float>(toll));
    CBEventSay(game, s"The gangs paid their way through your streets this week: \(toll)eb.");
  }
}

// ---- [36] A common enemy --------------------------------------------------------------------------------

public func CBTrucePartner(game: GameInstance, gang: CName) -> CName {
  let book = CBWarBook.Get(game);
  return CBCommonEnemyOn() && IsDefined(book) ? book.TruceWith(gang, CBGameSeconds(game)) : n"";
}

func CBWarTruceRoll(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, now: Float, days: Float) -> Void {
  let score = sys.GetScore();
  if !CBCommonEnemyOn() || !IsDefined(score) || book.AnyTruce(now)
     || EnumInt(score.GetTier()) < EnumInt(ECBRenownTier.Infamous) || RandF() >= CBConfig.TruceChancePerDay() * days {
    return;
  }
  let content = sys.GetContent();
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBTruceReady(score, fs.id) {
      for other in CBGangRivalsOf(content, fs.id) {
        if CBTruceReady(score, other) && IsDefined(sys.FindFaction(other)) {
          book.SetTruce(fs.id, other, now + CBConfig.TruceDays() * CBConfig.SecondsPerDay());
          CBFileLog(sys, n"Truce", now, CBEventDistrict(sys, game), fs.id, 0.0);
          CBEventSay(game, s"\(CBCapFirst(CBFactionLabel(fs.id))) and \(CBFactionLabel(other)) have stopped killing each other. They're coming for you together.");
          return;
        }
      }
    }
  }
}

func CBTruceReady(score: ref<CBScoreEngine>, gang: CName) -> Bool {
  if !CBFactionFieldsSquads(gang) || CBIsCorpFaction(gang) {
    return false;
  }
  let p = score.GetPosture(gang);
  return (Equals(p, ECBPosture.Hostile) || Equals(p, ECBPosture.Vendetta)) && score.GetFactionFear(gang) >= CBConfig.TruceFear();
}

// ---- [U6] Peace with terms, and the Claws' protection money --------------------------------------------

// The share off a gang's price haggled by text, while it holds (a day).
public func CBPeaceCut(game: GameInstance, gang: CName) -> Float {
  let book = CBWarBook.Get(game);
  if !IsDefined(book) {
    return 0.0;
  }
  let at = book.HaggledAt(gang);
  return at > 0.0 && CBGameSeconds(game) < at + CBConfig.SecondsPerDay() ? book.PeaceCut(gang) : 0.0;
}

public func CBPeaceCanHaggle(game: GameInstance, gang: CName) -> Bool {
  let book = CBWarBook.Get(game);
  if !CBTalkHaggleOn() || !IsDefined(book) {
    return false;
  }
  let at = book.HaggledAt(gang);
  return at <= 0.0 || CBGameSeconds(game) >= at + CBConfig.SecondsPerDay();
}

// "Too much", by text: come down a quarter, or the price stands. Business is easier to talk down (the Claws).
public func CBPeaceHaggle(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Bool {
  let book = CBWarBook.Get(game);
  let score = sys.GetScore();
  if !IsDefined(book) || !IsDefined(score) {
    return false;
  }
  let chance = CBConfig.PeaceHaggleBase() + score.GetFactionFear(gang) / 200.0;
  if CBGangCodesOn() && Equals(gang, n"TygerClaws") {
    chance += 0.15;
  }
  let won = RandF() < chance;
  book.SetPeaceCut(gang, won ? CBConfig.PeaceHaggleCut() : 0.0, CBGameSeconds(game));
  return won;
}

// Peace without money (a favour done): the same calling-off a paid peace does.
public func CBSettlePeace(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Void {
  let fs = sys.FindFaction(gang);
  if !IsDefined(fs) {
    return;
  }
  fs.standing = MaxF(fs.standing, 15.0);
  fs.vendettaSince = 0.0;
  fs.lastPeaceAt = CBGameSeconds(game);
  CBCallOffGang(sys, game, gang);
  CBFileLog(sys, n"PeaceFavour", fs.lastPeaceAt, CBEventDistrict(sys, game), gang, 0.0);
  if CBToastsOn() {
    CBPhoneFromGang(game, gang, "You did what we asked. We're square. For now.");
  }
}

// An event V crashed: was it the favour a gang asked for peace?
public func CBWarEventCrashed(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  let book = CBWarBook.Get(game);
  if !IsDefined(book) || !IsDefined(ev) {
    return;
  }
  let owed = book.FavourFor();
  if NotEquals(owed, n"") && CBGameSeconds(game) <= book.FavourUntil() {
    let content = sys.GetContent();
    if CBGangsAreRivals(content, owed, ev.a) || (NotEquals(ev.b, n"") && CBGangsAreRivals(content, owed, ev.b)) {
      book.SetFavour(n"", 0.0);
      CBSettlePeace(sys, game, owed);
    }
  }
}

// Working Japantown, the Claws want paying ([11], their code): every week V has spent long enough in Westbrook,
// unless V is on good terms with them or at war with them. Paid in talk to any of them; unpaid, they come.
func CBWarProtection(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, now: Float) -> Void {
  if !CBGangCodesOn() || !CBFactionFieldsSquads(n"TygerClaws") {
    return;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  if book.ProtectDue() > 0.0 {
    if now > book.ProtectDue() {
      let fs = sys.EnsureFaction(n"TygerClaws");
      if !CBReputationFrozen() {
        fs.standing = ClampF(fs.standing - CBConfig.ProtectionUnpaidStanding(), -100.0, 100.0);
      }
      fs.lastIncidentAt = now;
      CBProvoke(sys, game, n"TygerClaws");
      CBFileLog(sys, n"ProtectionRefused", now, CBEventDistrict(sys, game), n"TygerClaws", 0.0);
      if CBToastsOn() {
        CBPhoneFromGang(game, n"TygerClaws", "You didn't pay. That's bad for business. Yours.");
      }
      book.SetProtect(0.0, 0, now);
    }
    return;
  }
  let p = score.GetPosture(n"TygerClaws");
  let fair = Equals(p, ECBPosture.Neutral);
  if !fair || book.ProtectSeen() < CBConfig.ProtectionSeenSeconds() || now < book.ProtectAskedAt() + 7.0 * CBConfig.SecondsPerDay() {
    return;
  }
  let amount = RoundF(CBConfig.ProtectionBase() + score.GetRenown() * CBConfig.ProtectionPerRenown());
  book.SetProtect(now + CBConfig.ProtectionDays() * CBConfig.SecondsPerDay(), amount, now);
  if CBToastsOn() {
    CBPhoneFromGang(game, n"TygerClaws", s"You work Japantown, you pay the Claws. \(amount)eb, to any of ours on the street, in the next two days. Don't make us come asking.");
  }
}

// Once a tick, from the fast tick: time V spends in Westbrook counts towards the Claws' notice.
public func CBWarNoteWestbrook(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBWarBook.Get(game);
  if IsDefined(book) && IsDefined(sys) && Equals(sys.GetCurrentDistrict(), n"Westbrook") && book.ProtectDue() <= 0.0 {
    book.AddProtectSeen(CBConfig.ProtectionSeenPerTick());
  }
}

// ---- Talk: backing, the lie, protection money, terms ---------------------------------------------------

public func CBWarTalkLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let book = CBWarBook.Get(game);
  if !IsDefined(book) || !IsDefined(t) || !IsDefined(t.npc) || t.cop || Equals(t.faction, n"") || !CBFactionFieldsSquads(t.faction)
     || CBIsCorpFaction(t.faction) {
    return out;
  }
  let now = CBGameSeconds(game);
  // Protection money, to any Claw.
  if Equals(t.faction, n"TygerClaws") && book.ProtectDue() > 0.0 {
    let l = CBTalkMakeLine(s"[Pay] \(book.ProtectAmount())eb. Protection.", CBTalkActProtection(), t"ChoiceCaptionParts.PayIcon");
    l.inactive = CBTalkMoney(game) < book.ProtectAmount();
    l.important = true;
    ArrayPush(out, l);
  }
  // Backing them: a gang that likes V, not already backed, a week after the last change of heart.
  if CBBackingOn() && t.mood == CBTalkFriendly() && NotEquals(book.Backed(), t.faction)
     && (Equals(book.Backed(), n"") || now >= book.BackedSince() + 7.0 * CBConfig.SecondsPerDay()) {
    ArrayPush(out, CBTalkMakeLine("[Back] Your war is my war.", CBTalkActBack(), t"ChoiceCaptionParts.HandshakeIcon"));
  }
  // The lie: one of a gang at war with somebody, not hostile to V.
  if CBInciteOn() && t.mood != CBTalkHostile() && now >= book.InciteUntil() {
    let enemy = CBWarIncitable(sys, t.faction);
    if NotEquals(enemy, n"") {
      ArrayPush(out, CBTalkMakeLine("[Lie] " + CBCapFirst(CBFactionLabel(enemy)) + " are planning a hit on you.", CBTalkActIncite(),
                                    t"ChoiceCaptionParts.ClueIcon"));
    }
  }
  // Terms: a gang at war with V that would take a favour instead of eddies.
  if t.mood == CBTalkHostile() && CBPeaceQuote(sys, game, t.faction) >= 0 && NotEquals(book.FavourFor(), t.faction) {
    ArrayPush(out, CBTalkMakeLine("[Deal] What would it take to end this?", CBTalkActTerms(), t"ChoiceCaptionParts.HandshakeIcon"));
  }
  return out;
}

// The gang at war with this one that has people near V, for the lie.
func CBWarIncitable(sys: ref<CyberbaneSystem>, gang: CName) -> CName {
  for g in CBGangRivalsOf(sys.GetContent(), gang) {
    if CBFactionFieldsSquads(g) && CBFactionOn(g) && IsDefined(sys.FindFaction(g)) {
      return g;
    }
  }
  return n"";
}

public func CBWarTalkAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>,
                            choice: Int32) -> ref<CBTalkAnswer> {
  let book = CBWarBook.Get(game);
  let now = CBGameSeconds(game);
  if !IsDefined(book) {
    return CBTalkSay("Not now.", n"");
  }
  if choice == CBTalkActProtection() {
    let amount = book.ProtectAmount();
    if book.ProtectDue() <= 0.0 {
      return CBTalkSay("You're paid up. Don't worry about it.", n"");
    }
    if !CBTalkTakeMoney(game, player, amount) {
      return CBTalkSay("That's short. Come back with all of it.", n"");
    }
    book.SetProtect(0.0, 0, now);
    CBWarEarn(game, n"TygerClaws", Cast<Float>(amount));
    let fs = sys.EnsureFaction(n"TygerClaws");
    if !CBReputationFrozen() {   // as the unpaid side already was (CBWarProtection)
      fs.standing = ClampF(fs.standing + CBConfig.ProtectionPaidStanding(), -100.0, 100.0);
    }
    CBFileLog(sys, n"ProtectionPaid", now, CBEventDistrict(sys, game), n"TygerClaws", Cast<Float>(amount));
    return CBTalkSay(CBLineOf(["Pleasure doing business. Japantown's safe for you this week.",
                               "Smart. Nobody of ours bothers a paying customer."]), n"");
  }
  if choice == CBTalkActBack() {
    let old = book.Backed();
    book.SetBacked(t.faction, now);
    // Their enemies hear about it.
    for g in CBGangRivalsOf(sys.GetContent(), t.faction) {
      if CBFactionFieldsSquads(g) && !CBReputationFrozen() {
        let efs = sys.EnsureFaction(g);
        efs.standing = ClampF(efs.standing - CBConfig.BackedEnemyStanding(), -100.0, 100.0);
      }
    }
    CBFileLog(sys, n"Backed", now, CBEventDistrict(sys, game), t.faction, 0.0);
    CBLog.Info(n"Model", s"V backs \(NameToString(t.faction)) (was \(NameToString(old))).");
    return CBTalkSay(CBLineOf(["Then you're with us. Hurt our enemies and you'll get your cut.",
                               "Good. Every street we take, you get a piece.",
                               "Welcome to the war, choom. Our enemies are yours now."]), n"greeting");
  }
  if choice == CBTalkActIncite() {
    let enemy = CBWarIncitable(sys, t.faction);
    let chance = CBConfig.InciteBase() + (CBTalkStat(game, gamedataStatType.Cool) >= CBConfig.TalkAttributeCheck() ? CBConfig.TalkAttributeBonus() : 0.0);
    if Equals(enemy, n"") {
      return CBTalkSay("Who? Never heard of them.", n"");
    }
    if RandF() < chance {
      book.SetIncite(t.faction, enemy, now + CBConfig.SecondsPerDay());
      CBWeakenGang(sys, game, t.faction, CBConfig.InciteLoss());
      CBWeakenGang(sys, game, enemy, CBConfig.InciteLoss());
      CBFileLog(sys, n"Incited", now, CBEventDistrict(sys, game), t.faction, 0.0);
      return CBTalkSay(CBLineOf(["They're what? Then we hit them first.", "I knew it. I knew they'd try something. Thanks, merc.",
                                 "Everybody's going to hear about this."]), n"");
    }
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultCost() * CBCodeInsult(t.faction));
    return CBTalkSay(CBLineOf(["Nice try. You want us fighting so you can pick at the bones.", "You think I'm stupid?"]), n"bump");
  }
  if choice == CBTalkActTerms() {
    let quote = CBPeaceQuote(sys, game, t.faction);
    let enemy = CBWarIncitable(sys, t.faction);
    if quote < 0 {
      return CBTalkSay("There's nothing to end.", n"");
    }
    if Equals(enemy, n"") {
      return CBTalkSay(s"\(quote)eb. Pay it on the Hub and we're done.", n"");
    }
    book.SetFavour(t.faction, now + CBConfig.FavourDays() * CBConfig.SecondsPerDay());
    return CBTalkSay(s"Eddies, \(quote) of them. Or do us a favour: break up whatever \(CBFactionLabel(enemy)) have going next near here. Do that and we're square.", n"");
  }
  return null;
}
