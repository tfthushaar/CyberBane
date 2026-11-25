// Cyberbane - Turf, money and war
//
// War chests and manpower, backing a gang, setting two gangs on each other, a common enemy, V's own streets and peace
// with terms. A gang's money and people limit what it can send after V.

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
    out = chest < CBConfig.WarChestBroke() ? CBT(n"Cyberbane-War-Broke") : (chest > CBConfig.WarChestFlush() ? CBT(n"Cyberbane-War-Flush") : CBT(n"Cyberbane-War-CountingEveryEddie"));
    let men = book.Men(gang);
    if men < 50.0 {
      out += men < CBConfig.WarMenFloor() ? CBT(n"Cyberbane-War-NobodyLeftToSend") : CBT(n"Cyberbane-War-RanksThin");
    }
  }
  if CBBackingOn() && Equals(book.Backed(), gang) {
    out += StrLen(out) > 0 ? CBT(n"Cyberbane-War-AndYouBackThem") : CBT(n"Cyberbane-War-YouBackThem");
  }
  let truce = book.TruceWith(gang, CBGameSeconds(game));
  if NotEquals(truce, n"") && CBCommonEnemyOn() {
    out += CBTf(n"Cyberbane-War-InATruceWithAgainstYou", [CBFactionLabel(truce)]);
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
  if !CBBackingOn() || !IsDefined(book) || !IsDefined(sys) || !Equals(book.Backed(), gang) {
    return false;
  }
  let here = CBTurfGangsHere(sys);   // searched from a local, never a temporary (UI/HubWeb.reds, CBWebPair)
  return ArrayContains(here, gang);
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
    let plural = streets == 1 ? CBT(n"Cyberbane-War-District") : CBT(n"Cyberbane-War-Districts");
    CBPhoneFromAlly(game, gang, CBTf(n"Cyberbane-War-YourCutForTheWeekEb", [s"\(cut)", s"\(streets)", s"\(plural)"]));
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
          CBEventSay(game, CBTf(n"Cyberbane-War-NobodyRunsAnyMoreButYou", [s"\(CBDistrictLabel(d))"]));
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
    // V's crew keeps an eye on them while V is away (Reactions/Crew.reds, [C9]): a quarter more comes in.
    let crew = CBCrewBook.Get(game);
    if CBMyCrewOn() && IsDefined(crew) && crew.Count() >= 2 {
      toll = RoundF(Cast<Float>(toll) * 1.25);
    }
    CBStreetGiveMoney(game, toll);
    CBFileLog(sys, n"OwnToll", now, CBEventDistrict(sys, game), n"", Cast<Float>(toll));
    CBEventSay(game, CBTf(n"Cyberbane-War-TheGangsPaidTheirWayThrough", [s"\(toll)"]));
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
          CBEventSay(game, CBTf(n"Cyberbane-War-AndHaveStoppedKillingEachOther", [s"\(CBCapFirst(CBFactionLabel(fs.id)))", s"\(CBFactionLabel(other))"]));
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
  fs.standing = MaxF(fs.standing, 0.0);   // to neutral, as a paid peace does (CBBrokerPeace): square, not friends
  fs.vendettaSince = 0.0;
  fs.lastPeaceAt = CBGameSeconds(game);
  CBCallOffGang(sys, game, gang);
  CBFileLog(sys, n"PeaceFavour", fs.lastPeaceAt, CBEventDistrict(sys, game), gang, 0.0);
  if CBToastsOn() {
    CBPhoneFromAlly(game, gang, CBT(n"Cyberbane-War-YouDidWhatWeAskedWe"));
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
        CBPhoneFromGang(game, n"TygerClaws", CBT(n"Cyberbane-War-YouDidnTPayThatS"));
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
    CBPhoneFromGang(game, n"TygerClaws", CBTf(n"Cyberbane-War-YouWorkJapantownYouPayThe", [s"\(amount)"]));
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
    let l = CBTalkMakeLine(CBTf(n"Cyberbane-War-PayEbProtection", [s"\(book.ProtectAmount())"]), CBTalkActProtection(), t"ChoiceCaptionParts.PayIcon");
    l.inactive = CBTalkMoney(game) < book.ProtectAmount();
    l.important = true;
    ArrayPush(out, l);
  }
  // Backing them: a gang that likes V, not already backed, a week after the last change of heart.
  if CBBackingOn() && t.mood == CBTalkFriendly() && NotEquals(book.Backed(), t.faction)
     && (Equals(book.Backed(), n"") || now >= book.BackedSince() + 7.0 * CBConfig.SecondsPerDay()) {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-War-SideWithThemYourWarIs"), CBTalkActBack(), t"ChoiceCaptionParts.HandshakeIcon"));
  }
  // The lie: one of a gang at war with somebody, not hostile to V.
  if CBInciteOn() && t.mood != CBTalkHostile() && now >= book.InciteUntil() {
    let enemy = CBWarIncitable(sys, t.faction);
    if NotEquals(enemy, n"") {
      ArrayPush(out, CBTalkMakeLine(CBTf(n"Cyberbane-War-LieArePlanningAHitOn", [CBCapFirst(CBFactionLabel(enemy))]), CBTalkActIncite(),
                                    t"ChoiceCaptionParts.ClueIcon"));
    }
  }
  // Terms: a gang at war with V that would take a favour instead of eddies.
  if t.mood == CBTalkHostile() && CBPeaceQuote(sys, game, t.faction) >= 0 && NotEquals(book.FavourFor(), t.faction) {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-War-DealWhatWouldItTakeTo"), CBTalkActTerms(), t"ChoiceCaptionParts.HandshakeIcon"));
  }
  return out;
}

// The gang at war with this one that has people near V, for the lie.
func CBWarIncitable(sys: ref<CyberbaneSystem>, gang: CName) -> CName {
  for g in CBGangRivalsOf(sys.GetContent(), gang) {
    if CBFactionFieldsSquads(g) && CBFactionOn(g) {
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
    return CBTalkSay(CBT(n"Cyberbane-War-NotNow"), n"");
  }
  if choice == CBTalkActProtection() {
    let amount = book.ProtectAmount();
    if book.ProtectDue() <= 0.0 {
      return CBTalkSay(CBT(n"Cyberbane-War-YouRePaidUpDonT"), n"");
    }
    if !CBTalkTakeMoney(game, player, amount) {
      return CBTalkSay(CBT(n"Cyberbane-War-ThatSShortComeBackWith"), n"");
    }
    book.SetProtect(0.0, 0, now);
    CBWarEarn(game, n"TygerClaws", Cast<Float>(amount));
    let fs = sys.EnsureFaction(n"TygerClaws");
    if !CBReputationFrozen() {   // as the unpaid side already was (CBWarProtection)
      fs.standing = ClampF(fs.standing + CBConfig.ProtectionPaidStanding(), -100.0, 100.0);
    }
    CBFileLog(sys, n"ProtectionPaid", now, CBEventDistrict(sys, game), n"TygerClaws", Cast<Float>(amount));
    CBCalmTowardsV(game, t.npc, 1);   // a paying customer is nobody's target, starting with the one paid
    return CBTalkSay(CBLineOf([CBT(n"Cyberbane-War-PleasureDoingBusinessJapantownSSafe"),
                               CBT(n"Cyberbane-War-SmartNobodyOfOursBothersA")]), n"");
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
    CBCalmTowardsV(game, t.npc, 1);   // on their side now: the one V shook on it with stands down
    return CBTalkSay(CBLineOf([CBT(n"Cyberbane-War-ThenYouReWithUsHurt"),
                               CBT(n"Cyberbane-War-GoodEveryStreetWeTakeYou"),
                               CBT(n"Cyberbane-War-WelcomeToTheWarChoomOur")]), n"greeting");
  }
  if choice == CBTalkActIncite() {
    let enemy = CBWarIncitable(sys, t.faction);
    let chance = CBConfig.InciteBase() + (CBTalkStat(game, gamedataStatType.Cool) >= CBConfig.TalkAttributeCheck() ? CBConfig.TalkAttributeBonus() : 0.0);
    if Equals(enemy, n"") {
      return CBTalkSay(CBT(n"Cyberbane-War-WhoNeverHeardOfThem"), n"");
    }
    if RandF() < chance {
      book.SetIncite(t.faction, enemy, now + CBConfig.SecondsPerDay());
      CBWeakenGang(sys, game, t.faction, CBConfig.InciteLoss());
      CBWeakenGang(sys, game, enemy, CBConfig.InciteLoss());
      CBFileLog(sys, n"Incited", now, CBEventDistrict(sys, game), t.faction, 0.0);
      return CBTalkSay(CBLineOf([CBT(n"Cyberbane-War-TheyReWhatThenWeHit"), CBT(n"Cyberbane-War-IKnewItIKnewThey"),
                                 CBT(n"Cyberbane-War-EverybodySGoingToHearAbout")]), n"");
    }
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultCost() * CBCodeInsult(t.faction));
    return CBTalkSay(CBLineOf([CBT(n"Cyberbane-War-NiceTryYouWantUsFighting"), CBT(n"Cyberbane-War-YouThinkIMStupid")]), n"bump");
  }
  if choice == CBTalkActTerms() {
    let quote = CBPeaceQuote(sys, game, t.faction);
    let enemy = CBWarIncitable(sys, t.faction);
    if quote < 0 {
      return CBTalkSay(CBT(n"Cyberbane-War-ThereSNothingToEnd"), n"");
    }
    if Equals(enemy, n"") {
      return CBTalkSay(CBTf(n"Cyberbane-War-EbSendItAndWeRe", [s"\(quote)"]), n"");
    }
    book.SetFavour(t.faction, now + CBConfig.FavourDays() * CBConfig.SecondsPerDay());
    return CBTalkSay(CBTf(n"Cyberbane-War-EddiesOfThemOrDoUs", [s"\(quote)", s"\(CBFactionLabel(enemy))"]), n"");
  }
  return null;
}
