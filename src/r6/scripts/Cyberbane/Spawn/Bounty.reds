// Cyberbane - Bounties and the corporations
//
// Prices on V's head from gangs, Rivals and corporations, the named hunters who come to collect, and corporate interest
// in V.

public func CBPriceOnHeadOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHitSquadsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().priceOnHead);
}

public func CBCorpContractsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBPriceOnHeadOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().corpContracts);
}

// A corporation that hires the ladder instead of sending its own ([20]). Asked by the crew reason, apex eligibility
// and CBGangMaySend, so a corporation's crews stop everywhere a crew is decided.
public func CBCorpHiresKillers(faction: CName) -> Bool {
  return CBIsCorpFaction(faction) && CBFactionOn(faction) && CBCorpContractsOn();
}

public func CBHunterOnLadder() -> Int32 = 0
public func CBHunterDead() -> Int32 = 1
public func CBHunterTurnedRival() -> Int32 = 2

// ---- Who they are -------------------------------------------------------------------------------------

// Names of their own: solos, not anybody's gang. Only ever add to the end of a list (a hunter is saved as a seed).
public func CBHunterName(seed: Int32) -> String {
  let firsts = ["Ash", "Kade", "Mira", "Sable", "Juno", "Silas", "Vex", "Nadja", "Cass", "Ezra", "Lyra", "Tomas",
                "Wren", "Idris", "Kira", "Osric", "Petra", "Zane", "Ines", "Bram", "Selene", "Hollis", "Dagny"];
  let lasts = ["Kovach", "Okoro", "Lindqvist", "Marchetti", "Haddad", "Novak", "Achebe", "Dubois", "Varga",
               "Castell", "Mbeki", "Sorel", "Halloran", "Ferro", "Quist", "Dragan", "Ilves", "Moreau", "Brandt"];
  return firsts[CBHashIndex(seed, 11, ArraySize(firsts))] + " \"" + CBHunterHandle(seed) + "\" "
       + lasts[CBHashIndex(seed, 13, ArraySize(lasts))];
}

public func CBHunterHandle(seed: Int32) -> String {
  let handles = ["the Hound", "Long Arm", "Bird Dog", "Lockjaw", "Steel Trap", "Crosshair", "Packwolf", "Manhunter",
                 "Sure Shot", "Homing", "the Collector", "Repo", "Night Owl", "Snare", "Gunsight", "Leash", "Headhunter"];
  return CBEpithetText(handles[CBHashIndex(seed, 7, ArraySize(handles))]);   // translated as every epithet is
}

// What they fight with: 0 a gunslinger, 1 a blade, 2 a heavy, 3 a netrunner, 4 a sniper.
public func CBHunterKind(seed: Int32) -> Int32 = CBHashIndex(seed, 17, 5)

public func CBHunterKindWord(seed: Int32) -> String {
  switch CBHunterKind(seed) {
    case 1: return CBT(n"Cyberbane-StreetIntel-ABlade");
    case 2: return CBT(n"Cyberbane-Bounty-HeavyGuns");
    case 3: return CBT(n"Cyberbane-Bounty-ACyberdeck");
    case 4: return CBT(n"Cyberbane-Bounty-ALongRifle");
    default: return CBT(n"Cyberbane-Bounty-APistolAndPatience");
  }
}

// How they work: 0 patient (a long warning), 1 reckless (hardly any), 2 a night worker (only after dark), 3 plain.
public func CBHunterTrait(seed: Int32) -> Int32 = CBHashIndex(seed, 23, 4)

public func CBHunterTraitWord(seed: Int32) -> String {
  switch CBHunterTrait(seed) {
    case 0: return CBT(n"Cyberbane-Bounty-Patient");
    case 1: return CBT(n"Cyberbane-Bounty-Reckless");
    case 2: return CBT(n"Cyberbane-Bounty-WorksNights");
    default: return CBT(n"Cyberbane-Bounty-AProfessional");
  }
}

// How long until the next hunter on the ladder: as the grudge clock reads a gang (Spawn/Grudge.reds), by the grudge of
// whoever put the price on V, and the player's How eager gangs are.
func CBBountyGapHours(sys: ref<CyberbaneSystem>, book: ref<CBHuntBook>) -> Float {
  let hours = CBConfig.BountyGapHours();
  let payer = IsDefined(book) ? book.BountyBy() : n"";
  let fs = IsDefined(sys) && NotEquals(payer, n"") ? sys.FindFaction(payer) : null;
  if IsDefined(fs) && !CBIsCorpFaction(payer) {
    let heat = CBGrudgeHeat(fs);
    hours *= heat < 0.0 ? 2.0 : 1.5 - heat;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    hours /= MaxF(rt.GetSettings().hitSquadFrequencyMult, 0.05);
  }
  return MaxF(hours, CBConfig.GrudgeFloorHours());
}

// The apex chair their kind sits in, for a body taken from whoever paid them and for their kit.
func CBHunterChair(kind: Int32) -> Int32 {
  switch kind {
    case 1: return 2;
    case 2: return 0;
    case 3: return 3;
    default: return 1;
  }
}

// The Afterlife's own solos when Phantom Liberty is there to give them a body; otherwise one of the payer's own best,
// of the same kind. Only a fit person to spawn either way.
public func CBHunterRecord(seed: Int32, payer: CName) -> TweakDBID {
  let kind = CBHunterKind(seed);
  let woman = CBHashIndex(seed, 19, 2) == 1;
  if IsEP1() {
    let id = t"Character.afterlife_rare_franged2_saratoga_ma_rare";
    if kind == 0 {
      id = woman ? t"Character.afterlife_rare_franged2_ajax_wa_rare" : t"Character.afterlife_rare_franged2_ajax_ma_rare";
    } else {
      if kind == 1 {
        id = woman ? t"Character.afterlife_rare_fmelee3_katana_wa_elite" : t"Character.afterlife_rare_fmelee3_mantis_ma_elite";
      } else {
        if kind == 2 {
          id = woman ? t"Character.afterlife_rare_franged2_overture_wa_rare" : t"Character.afterlife_rare_gunner3_hmg_mb_elite";
        } else {
          if kind == 3 {
            id = woman ? t"Character.afterlife_netrunner_netrunner2_yukimura_wa_rare" : t"Character.afterlife_netrunner_netrunner2_yukimura_ma_rare";
          } else {
            id = woman ? t"Character.afterlife_rare_franged2_saratoga_wa_rare" : t"Character.afterlife_rare_sniper3_ashura_ma_elite";
          }
        }
      }
    }
    if CBHunterRecordFit(id) {
      return id;
    }
  }
  // Nobody's: a solo for V's crew (Reactions/Crew.reds, [C3]). The roster has no list for no gang, so without Phantom
  // Liberty this was always invalid and the broker never once offered a solo.
  let from = payer;
  if !IsNameValid(from) {
    let freelance: array<CName> = [n"Militech", n"KangTao", n"Arasaka", n"SixthStreet", n"Aldecaldos"];
    from = freelance[CBHashIndex(seed, 29, ArraySize(freelance))];
  }
  let fallback = CBApexRosterRecord(from, CBHunterChair(kind), seed);
  return CBHunterRecordFit(fallback) ? fallback : TDBID.None();
}

func CBHunterRecordFit(id: TweakDBID) -> Bool {
  return TDBID.IsValid(id) && IsDefined(TweakDBInterface.GetCharacterRecord(id)) && CBRecordIsPerson(id)
      && !CBRecordUnfitTemplate(id);
}

// ---- The price -------------------------------------------------------------------------------------------

// A Rival who put the price up is kept as "rival:<id>" in the one name the book saves for it.
public func CBBountyRivalId(by: CName) -> Int32 {
  let s = NameToString(by);
  return StrBeginsWith(s, "rival:") ? StringToInt(StrMid(s, 6), 0) : 0;
}

// Whose price it is, as a gang or corporation: the poster's own, or the Rival's gang.
public func CBBountyGang(sys: ref<CyberbaneSystem>, by: CName) -> CName {
  let rid = CBBountyRivalId(by);
  if rid > 0 {
    let r = IsDefined(sys) ? sys.FindRivalById(rid) : null;
    return IsDefined(r) ? r.faction : n"";
  }
  return by;
}

public func CBBountyPosterName(sys: ref<CyberbaneSystem>, game: GameInstance, by: CName) -> String {
  let rid = CBBountyRivalId(by);
  if rid > 0 {
    let r = IsDefined(sys) ? sys.FindRivalById(rid) : null;
    return IsDefined(r) ? CBRivalDisplayName(CBContent(game), r) : CBT(n"Cyberbane-RivalSystem-ARival-2");
  }
  return CBFactionLabel(by);
}

// The price on V right now, or 0.
public func CBBountyUp(game: GameInstance) -> Int32 {
  let book = CBHuntBook.Get(game);
  return CBPriceOnHeadOn() && IsDefined(book) && NotEquals(book.BountyBy(), n"") ? book.BountyAmount() : 0;
}

// What it costs V to make it go away: the price, and more for a corporation's contract.
public func CBBountyPayOff(sys: ref<CyberbaneSystem>, game: GameInstance) -> Int32 {
  let book = CBHuntBook.Get(game);
  if !IsDefined(book) || CBBountyUp(game) <= 0 {
    return 0;
  }
  let mult = CBIsCorpFaction(book.BountyBy()) ? CBConfig.BountyCorpPayMult() : 1.0;
  return RoundF(Cast<Float>(book.BountyAmount()) * mult / 500.0) * 500;
}

// Does whoever put the price up still want V dead? Gone, square with V, or switched off: the price comes down.
func CBBountyStands(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>) -> Bool {
  let by = book.BountyBy();
  let rid = CBBountyRivalId(by);
  if rid > 0 {
    let r = sys.FindRivalById(rid);
    return IsDefined(r) && CBRivalStillAround(r) && CBFactionOn(r.faction);
  }
  let score = sys.GetScore();
  if !CBFactionOn(by) || !IsDefined(score) {
    return false;
  }
  let posture = score.GetPosture(by);
  if NotEquals(posture, ECBPosture.Hostile) && NotEquals(posture, ECBPosture.Vendetta) {
    return false;
  }
  // A corporation's contract runs its term and is put out again if they still want it.
  if CBIsCorpFaction(by) {
    return CBGameSeconds(game) - book.BountySince() < CBConfig.BountyCorpDays() * CBConfig.SecondsPerDay();
  }
  return true;
}

// The price comes down, for this reason; said once, where V will hear it.
func CBBountyEnd(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>, how: CName) -> Void {
  let by = book.BountyBy();
  if Equals(by, n"") {
    return;
  }
  let who = CBBountyPosterName(sys, game, by);
  let gang = CBBountyGang(sys, by);
  book.SetBounty(n"", 0, 0.0);
  book.comingSlot = 0;
  book.comingPair = 0;
  book.comingTicks = 0;
  let now = CBGameSeconds(game);
  CBFileLog(sys, Equals(how, n"paid") ? n"BountyPaid" : (Equals(how, n"poster") ? n"BountyPosterDown" : n"BountyLifted"),
            now, CBEventDistrict(sys, game), gang, 0.0);
  if !CBToastsOn() {
    return;
  }
  if Equals(how, n"poster") {
    CBHearsayFromStreet(game, CBPick2(CBTf(n"Cyberbane-Bounty-WhoeverPutThePriceOnYou", [s"\(CBCapFirst(who))"]),
                                      CBTf(n"Cyberbane-Bounty-NoMorePriceOnYourHead", [s"\(who)"])), n"");
    return;
  }
  if Equals(how, n"paid") {
    CBPhoneSend(game, CBBountyContact(by), CBPick2(CBT(n"Cyberbane-Bounty-PaidYourNameSOffThe"),
                                                   CBT(n"Cyberbane-Bounty-MoneyTalksTheContractSWithdrawn")));
    return;
  }
  CBHearsayFromStreet(game, CBPick2(CBTf(n"Cyberbane-Bounty-ThePricePutOnYouIs", [s"\(who)"]),
                                    CBT(n"Cyberbane-Bounty-YourNameSOffTheBoard")), n"");
}

// Who texts about a price: the corporation's own fixer, or the board itself.
public func CBBountyContact(by: CName) -> String {
  if Equals(by, n"Arasaka") {
    return CBT(n"Cyberbane-Bounty-ArasakaLiaison");
  }
  if Equals(by, n"Militech") {
    return CBT(n"Cyberbane-Bounty-MilitechProcurement");
  }
  if Equals(by, n"KangTao") {
    return CBT(n"Cyberbane-Bounty-KangTaoRepresentative");
  }
  return CBT(n"Cyberbane-Bounty-TheBoard");
}

// From the slow tick: somebody may put a price on V. One price at a time.
public func CBBountyRoll(sys: ref<CyberbaneSystem>, game: GameInstance, days: Float) -> Void {
  let book = CBHuntBook.Get(game);
  let score = sys.GetScore();
  if !CBPriceOnHeadOn() || !IsDefined(book) || !IsDefined(score) {
    return;
  }
  CBLadderEnsure(book);
  if NotEquals(book.BountyBy(), n"") {
    if !CBBountyStands(sys, game, book) {
      CBBountyEnd(sys, game, book, n"lifted");
    }
    return;
  }
  let now = CBGameSeconds(game);
  // A corporation that wants V dead puts out a contract instead of sending anybody ([20]).
  let corps = [n"Arasaka", n"Militech", n"KangTao"];
  for corp in corps {
    let posture = score.GetPosture(corp);
    if CBCorpHiresKillers(corp) && (Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta))
       && RandF() < CBConfig.BountyCorpChancePerDay() * days {
      let amount = Equals(posture, ECBPosture.Vendetta) ? CBConfig.BountyCorpVendetta() : CBConfig.BountyCorpHostile();
      CBBountyPost(sys, game, book, corp, CBBountyRound(Cast<Float>(amount) * CBLootLevelScale(game)), now);
      return;
    }
  }
  if RandF() >= CBConfig.BountyChancePerDay() * days {
    return;
  }
  // A gang sworn against V that can pay for it, with somebody to sign for it.
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id)
       && Equals(score.GetPosture(fs.id), ECBPosture.Vendetta) && fs.kills >= CBConfig.BountyGangKills()
       && fs.leaderRivalId > 0 && !CBGangBroken(sys, fs.id) {
      let war = CBWarBook.Get(game);
      let chest = IsDefined(war) && CBWarChestOn() ? war.Chest(fs.id) : CBConfig.BountyMinChest() * 4.0;
      let leader = sys.FindRivalById(fs.leaderRivalId);
      if chest >= CBConfig.BountyMinChest() && IsDefined(leader) && CBRivalStillAround(leader) {
        CBBountyPost(sys, game, book, fs.id, CBBountyRound(ClampF(chest * CBConfig.BountyChestShare(),
                     Cast<Float>(CBConfig.BountyGangMin()), Cast<Float>(CBConfig.BountyGangMax()))), now);
        return;
      }
    }
  }
  // A Rival who has met V often enough to want it over with, and has the name to put money behind it.
  for r in sys.GetRivals() {
    if IsDefined(r) && CBRivalStillAround(r) && r.rank >= CBConfig.BountyRivalRank()
       && r.encounters >= CBConfig.BountyRivalMeetings() && CBFactionFieldsSquads(r.faction)
       && !CBRecordIsSightingCyberpsycho(r.recordID) {
      CBBountyPost(sys, game, book, StringToName("rival:" + IntToString(r.id)),
                   CBBountyRound(Cast<Float>(CBConfig.BountyRivalPostPerRank() * r.rank) * CBLootLevelScale(game)), now);
      return;
    }
  }
}

func CBBountyRound(amount: Float) -> Int32 {
  return Max(500, RoundF(amount / 500.0) * 500);
}

func CBBountyPost(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>, by: CName, amount: Int32, now: Float) -> Void {
  book.SetBounty(by, amount, now);
  // The first of them a few hours out, never straight away.
  book.SetHunterNext(now + RandRangeF(CBConfig.BountyFirstHoursMin(), CBConfig.BountyFirstHoursMax()) * CBConfig.SecondsPerHour());
  let gang = CBBountyGang(sys, by);
  CBFileLog(sys, n"BountyPosted", now, CBEventDistrict(sys, game), gang, Cast<Float>(amount));
  CBEmit(n"Cyberbane/BountyPosted", gang, Cast<Float>(amount));   // [91]
  CBLog.Info(n"Spawn", s"A price on V's head: \(amount)eb from \(NameToString(by)).");
  if !CBMessagesOn() {
    return;
  }
  let who = CBBountyPosterName(sys, game, by);
  if CBIsCorpFaction(by) {
    let warned = Equals(book.CorpBy(), by) ? CBT(n"Cyberbane-Bounty-WeToldYouToStop") : "";
    CBPhoneSendTinted(game, CBBountyContact(by),
      CBTf(n"Cyberbane-Bounty-AContractHasBeenOpenedOn", [warned, s"\(amount)"]), CBHudRed());
    return;
  }
  let you = CBYou(sys, game);
  let here = CBHere(sys);
  CBHearsayFromStreet(game, CBLineOf([CBTf(n"Cyberbane-Bounty-ThereSAPriceOnYour", [s"\(you)", s"\(amount)", s"\(who)"]),
                                      CBTf(n"Cyberbane-Bounty-PutEbOnYouEverySolo", [s"\(CBCapFirst(who))", s"\(amount)", s"\(here)"]),
                                      CBTf(n"Cyberbane-Bounty-WordIsWouldPayToSee", [s"\(who)", s"\(amount)", s"\(here)"]),
                                      CBTf(n"Cyberbane-Bounty-EddiesOnThatSMoreThan", [s"\(amount)", s"\(you)"])]), n"");
}

// Chosen on the Hub, carried out on the next tick back in the game; false takes it back.
public func CBBountyRequestPay(game: GameInstance, wanted: Bool) -> Void {
  let book = CBHuntBook.Get(game);
  if IsDefined(book) {
    book.payRequested = wanted;
  }
}

public func CBBountyPayPending(game: GameInstance) -> Bool {
  let book = CBHuntBook.Get(game);
  return IsDefined(book) && book.payRequested;
}

// From the Hub: V pays it off. Done on the next tick back in the game, never from the menu.
func CBBountyPayNow(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>) -> Void {
  book.payRequested = false;
  let price = CBBountyPayOff(sys, game);
  let player = GetPlayer(game);
  if price <= 0 || !IsDefined(player) {
    return;
  }
  // The Hub only offers it with the eddies in V's pocket; spent between the click and the game, the button's answer is
  // said rather than lost.
  if !CBTalkTakeMoney(game, player, price) {
    CBMenuNote(game, CBTf(n"Cyberbane-Bounty-NotEnoughEddiesToClearThe", [s"\(price)"]), 5.0);
    return;
  }
  let gang = CBBountyGang(sys, book.BountyBy());
  if NotEquals(gang, n"") {
    CBWarEarn(game, gang, Cast<Float>(price));   // into whoever put it up (Economy/War.reds)
  }
  CBBountyEnd(sys, game, book, n"paid");
}

// From the death path (Signals/CombatSignals.reds): a Rival is dead. If they were the price, or signed for it as their
// gang's leader and V did it, the price dies with them.
public func CBBountyPosterSlain(sys: ref<CyberbaneSystem>, game: GameInstance, slain: ref<CBRival>, wasLeader: Bool, byV: Bool) -> Void {
  let book = CBHuntBook.Get(game);
  if !IsDefined(book) || !IsDefined(slain) {
    return;
  }
  let by = book.BountyBy();
  if NotEquals(by, n"") && (CBBountyRivalId(by) == slain.id || (byV && wasLeader && Equals(by, slain.faction))) {
    CBBountyEnd(sys, game, book, n"poster");
  }
  // Whether or not anybody has a price on V: a corporation may have wanted this one gone ([88]).
  CBCorpContractSlain(sys, game, book, slain, wasLeader, byV);
}

// ---- The ladder ------------------------------------------------------------------------------------------

// Ten places, filled the first time anybody looks.
public func CBLadderEnsure(book: ref<CBHuntBook>) -> Void {
  if !IsDefined(book) {
    return;
  }
  book.DropGone(CBConfig.LadderKeep());
  CBLadderRepack(book);
}

// Everybody still on it, in order, around V's own place; new names at the bottom for every place empty.
func CBLadderRepack(book: ref<CBHuntBook>) -> Void {
  let vRank = book.LadderRank();
  let order: array<Int32>;
  let r = 1;
  while r <= CBConfig.LadderPlaces() * 4 {
    let i = 0;
    while i < book.HunterCount() {
      if book.HunterState(i) == CBHunterOnLadder() && book.HunterRank(i) == r {
        ArrayPush(order, i);
      }
      i += 1;
    }
    r += 1;
  }
  let place = 1;
  for idx in order {
    if place == vRank {
      place += 1;
    }
    book.SetHunterRank(idx, place);
    place += 1;
  }
  let filled = ArraySize(order) + (vRank > 0 ? 1 : 0);
  while filled < CBConfig.LadderPlaces() {
    if place == vRank {
      place += 1;
    }
    book.AddHunter(RandRange(1000, 2000000000), place);
    place += 1;
    filled += 1;
  }
}

// The roster index of the one on the ladder at this place, or -1.
func CBLadderAt(book: ref<CBHuntBook>, rank: Int32) -> Int32 {
  let i = 0;
  while i < book.HunterCount() {
    if book.HunterState(i) == CBHunterOnLadder() && book.HunterRank(i) == rank {
      return i;
    }
    i += 1;
  }
  return -1;
}

// Who comes for V next: the one just above, or at the top, the one just below.
public func CBLadderNext(book: ref<CBHuntBook>) -> Int32 {
  let v = book.LadderRank();
  if v == 0 {
    return CBLadderAt(book, CBConfig.LadderPlaces());
  }
  return CBLadderAt(book, v == 1 ? 2 : v - 1);
}

// ---- Every tick ------------------------------------------------------------------------------------------

public func CBBountyTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBHuntBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(player) {
    return;
  }
  if book.payRequested {
    CBBountyPayNow(sys, game, book);
  }
  CBBountyWatchOut(sys, game, book, player);
  if !CBPriceOnHeadOn() || Equals(book.BountyBy(), n"") {
    book.comingSlot = 0;
    book.comingPair = 0;
    return;
  }
  if !CBWorldStable(game) || CBVDown(game) {
    return;
  }
  let now = CBGameSeconds(game);
  // On their way: the clock holds while V cannot be reached, as a crew's does.
  // Home ground holds them as anybody sent after V; the quiet a night at home bought does not: they had already set off.
  if book.comingSlot > 0 {
    if CBArrivalsHeldBase(sys, game) || CBHomeKeepsOut(sys) || sys.IsInSafeZone() {
      return;
    }
    if book.comingTicks > 0 {
      book.comingTicks -= 1;
      return;
    }
    if player.IsInCombat() || IsDefined(player.GetMountedVehicle()) || CBHuntersOut(sys, game)
       || CBSafeAreaBlocksSpawn(game, player.GetWorldPosition()) || CBSpawnRoom(game) < 2 {
      return;   // held, not called off: they wait for a better moment
    }
    CBBountySend(sys, game, book, now);
    return;
  }
  // The next of them, in their own time.
  if now < book.HunterNext() || sys.GetTickCount() % 5 != 0 || CBArrivalsHeld(sys, game) || CBHomeKeepsOut(sys) || sys.IsInSafeZone()
     || CBHuntersOut(sys, game) || CBHuntPending(sys) {
    return;
  }
  CBLadderEnsure(book);
  let next = CBLadderNext(book);
  if next < 0 {
    return;
  }
  let seed = book.HunterSeed(next);
  // One who only works after dark waits for it.
  if CBHunterTrait(seed) == 2 && !CBIsNight(game) {
    return;
  }
  book.SetHunterNext(now + CBBountyGapHours(sys, book) * CBConfig.SecondsPerHour() * RandRangeF(0.75, 1.25));
  book.comingSlot = next + 1;
  book.comingPair = 0;
  // A big enough price brings two, the next one down with them.
  if book.BountyAmount() >= CBConfig.BountyPairAmount() && RandF() < CBConfig.BountyPairChance() {
    let second = CBLadderAt(book, book.HunterRank(next) + 1);
    if second >= 0 && second != next {
      book.comingPair = second + 1;
    }
  }
  let warn = CBConfig.CrewWarningTicks();
  if CBHunterTrait(seed) == 0 {
    warn = warn * 2;
  }
  if CBHunterTrait(seed) == 1 {
    warn = warn / 3;
  }
  book.comingTicks = CBWarningTicks(warn);
  sys.SetHuntGrade(CBT(n"Cyberbane-Bounty-BOUNTYHUNTER"));
  CBHuntBegin(sys, game, CBBountyGang(sys, book.BountyBy()));
  if CBMessagesOn() {
    let rank = book.HunterRank(next);
    let pair = book.comingPair > 0 ? CBT(n"Cyberbane-Bounty-BroughtAFriend") : "";
    let you = CBYou(sys, game);
    let vRank = book.LadderRank();
    let standing = vRank == 0 ? CBT(n"Cyberbane-Bounty-YouReNotEvenOnThe")
                 : (vRank < rank ? CBTf(n"Cyberbane-Bounty-YouReNumberIMNumber", [s"\(vRank)", s"\(rank)"]) : CBTf(n"Cyberbane-Bounty-NumberOnTheBoardSomebodyHas", [s"\(vRank)"]));
    let when = CBWhenWords(game);
    CBPhoneSendTinted(game, CBTf(n"Cyberbane-Bounty-Rank", [CBHunterName(seed), s"\(rank)"]), CBLineOf([
      CBTf(n"Cyberbane-Bounty-EddiesSaysIFindYouNothing", [s"\(book.BountyAmount())", s"\(you)", s"\(standing)", s"\(pair)"]),
      CBTf(n"Cyberbane-Bounty-ITookContractIWorkWith", [s"\(CBPossessive(CBBountyPosterName(sys, game, book.BountyBy())))", s"\(CBHunterTraitWord(seed))", s"\(CBHunterKindWord(seed))", s"\(pair)"]),
      CBTf(n"Cyberbane-Bounty-DonTBotherLeavingIVe", [s"\(CBHere(sys))", s"\(book.BountyAmount())", s"\(pair)"]),
      (StrLen(when) > 0 ? CBTf(n"Cyberbane-Bounty-ILikeWorkingSeeYouSoon", [s"\(when)", s"\(you)", s"\(pair)"]) : CBTf(n"Cyberbane-Bounty-SeeYouSoon", [s"\(you)", s"\(standing)", s"\(pair)"]))]), CBHudRed());
  }
  CBLog.Info(n"Spawn", s"Bounty hunter on the way: rank \(book.HunterRank(next)).");
}

func CBBountySend(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>, now: Float) -> Void {
  let gang = CBBountyGang(sys, book.BountyBy());
  let slots: array<Int32>;
  ArrayPush(slots, book.comingSlot - 1);
  if book.comingPair > 0 {
    ArrayPush(slots, book.comingPair - 1);
  }
  book.comingSlot = 0;
  book.comingPair = 0;
  let sent = 0;
  for slot in slots {
    let record = CBHunterRecord(book.HunterSeed(slot), gang);
    let body: EntityID;
    if TDBID.IsValid(record) && book.HunterState(slot) == CBHunterOnLadder()
       && CBSpawnGroup(game, record, n"", 1, n"CB_Squad", CBConfig.HitSquadMinSpawnDistance() + 15.0, body, n"CB_Bounty") > 0 {
      ArrayPush(book.outBody, body);
      ArrayPush(book.outSlot, slot);
      ArrayPush(book.outDownTick, 0);
      sent += 1;
    }
  }
  if sent == 0 {
    // Nobody could be placed: they try again a little later rather than being lost.
    book.SetHunterNext(now + CBConfig.SecondsPerHour());
    CBLog.Info(n"Spawn", s"A bounty hunter could not be placed: \(CBSpawnBlockWhy()).");
    return;
  }
  // Nobody's crew: a hunter going down is not a crew of whoever paid beaten.
  sys.SetActiveSquadFaction(n"");
  sys.SetActiveSquadApex(false);
  CBHuntBegin(sys, game, gang);   // a hunt already under way keeps what it knows
  CBLog.Info(n"Spawn", s"\(sent) bounty hunter(s) sent.");
}

// The ones out after V: who went down, who was left breathing, who is gone from the world.
func CBBountyWatchOut(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>, player: ref<PlayerPuppet>) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if ArraySize(book.outBody) == 0 || !IsDefined(des) {
    return;
  }
  let n = Min(ArraySize(book.outBody), Min(ArraySize(book.outSlot), ArraySize(book.outDownTick)));
  let i = n - 1;
  while i >= 0 {
    let id = book.outBody[i];
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    let drop = false;
    if !IsDefined(p) {
      // Gone from the world and not on the way into it: the hunt let them go, or the world did. Still on the ladder.
      // One who has only streamed out is still registered, and stays on the list until they are.
      let tagged = des.GetTaggedIDs(n"CB_Bounty");   // a local, never a temporary (UI/HubWeb.reds, CBWebPair)
      drop = !des.IsSpawning(id) && !ArrayContains(tagged, id);
    } else {
      if p.IsAttached() && CBIsDown(p) && !p.IsDead() {
        // Beaten and left breathing, once V has walked away from them.
        if book.outDownTick[i] == 0 {
          book.outDownTick[i] = Max(sys.GetTickCount(), 1);
        }
        let far = Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition()) > CBConfig.BountyLeftDistance();
        if far || (!player.IsInCombat() && sys.GetTickCount() - book.outDownTick[i] > CBConfig.BountyLeftTicks()) {
          CBHunterBeaten(sys, game, book, book.outSlot[i], p, false);
          drop = true;
        }
      }
    }
    if drop {
      ArrayErase(book.outBody, i);
      ArrayErase(book.outSlot, i);
      ArrayErase(book.outDownTick, i);
    }
    i -= 1;
  }
}

// From the death path: one of them is dead.
public func CBBountyHunterDied(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let book = CBHuntBook.Get(game);
  if !IsDefined(book) || !IsDefined(puppet) {
    return;
  }
  let id = puppet.GetEntityID();
  let n = Min(ArraySize(book.outBody), Min(ArraySize(book.outSlot), ArraySize(book.outDownTick)));
  let i = 0;
  while i < n {
    if Equals(book.outBody[i], id) {
      let slot = book.outSlot[i];
      ArrayErase(book.outBody, i);
      ArrayErase(book.outSlot, i);
      ArrayErase(book.outDownTick, i);
      if puppet.cbDamagedByPlayer {
        CBHunterBeaten(sys, game, book, slot, puppet, true);
      } else {
        CBLog.Info(n"Spawn", "A bounty hunter died, and not by V's hand: their place goes to the next one down.");
        book.SetHunterState(slot, CBHunterDead());
        CBLadderRepack(book);
      }
      return;
    }
    i += 1;
  }
}

// V beat one of them: dead, or left breathing. V takes their place if it was above V's own.
func CBHunterBeaten(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>, slot: Int32,
                    puppet: ref<ScriptedPuppet>, killed: Bool) -> Void {
  if book.HunterState(slot) != CBHunterOnLadder() {
    return;
  }
  let seed = book.HunterSeed(slot);
  let rank = book.HunterRank(slot);
  let name = CBHunterName(seed);
  let gang = CBBountyGang(sys, book.BountyBy());
  let before = book.LadderRank();
  let now = CBGameSeconds(game);
  let turned = false;
  if !killed && CBRivalsOn() && RandF() < CBConfig.HunterRivalChance() && IsDefined(puppet) {
    // Left breathing, they come back for whoever was paying, as one of theirs. Only where the fight's own mercy path
    // could not make them a Rival (a solo of nobody's gang), so nobody is made twice.
    let own = CBClassifyFaction(puppet);
    let payer = NotEquals(gang, n"") ? gang : CBApexFallbackGang(sys);
    if Equals(own, n"") && NotEquals(payer, n"") {
      CBRivalAfterFight(sys, game, payer, puppet.GetRecordID(), n"", ECBRivalSource.Hunter, CBEventDistrict(sys, game),
                        now, null, 0, "");
      turned = true;
    }
  }
  book.SetHunterState(slot, killed ? CBHunterDead() : (turned ? CBHunterTurnedRival() : CBHunterDead()));
  if before == 0 || rank < before {
    book.SetLadderRank(rank);
  }
  CBLadderRepack(book);
  let after = book.LadderRank();
  CBFileLog(sys, killed ? n"HunterKilled" : n"HunterBeaten", now, CBEventDistrict(sys, game), gang, Cast<Float>(rank));
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints((CBConfig.HunterRenownBase() + CBConfig.HunterRenownPerPlace() * Cast<Float>(CBConfig.LadderPlaces() + 1 - rank)) * mult);
  if after != before {
    CBFileLog(sys, n"LadderRank", now, CBEventDistrict(sys, game), n"", Cast<Float>(after));
    CBEmit(n"Cyberbane/LadderRank", gang, Cast<Float>(after));   // [91]
  }
  if killed {
    CBGiveStreetCred(game, CBConfig.CredHunterPerPlace() * (CBConfig.LadderPlaces() + 1 - rank)
                           + (after == 1 && before != 1 ? CBConfig.CredLadderTop() : 0));   // [87]
  }
  CBLog.Info(n"Spawn", s"Bounty hunter rank \(rank) beaten (killed: \(killed)); V is rank \(after).");
  if !CBMessagesOn() {
    return;
  }
  if after == 1 && before != 1 {
    CBHearsayFromStreet(game, CBPick2(CBTf(n"Cyberbane-Bounty-WasNumberOneOnTheHunters", [s"\(name)"]),
                                      CBT(n"Cyberbane-Bounty-TopOfTheBoardNobodyIn")), n"");
    return;
  }
  if after != before {
    CBHearsayFromStreet(game, CBLineOf([CBTf(n"Cyberbane-Bounty-CameForYouInAndLost", [s"\(name)", s"\(CBHere(sys))", s"\(after)"]),
                                        CBTf(n"Cyberbane-Bounty-TheBoardSBeenRewrittenYou", [s"\(CBHunterHandle(seed))", s"\(after)"]),
                                        CBTf(n"Cyberbane-Bounty-SolosAreTalkingYouBeatA", [s"\(rank)", s"\(CBWhenTail(game))"]),
                                        CBTf(n"Cyberbane-Bounty-WonTBeCollectingAnythingNow", [s"\(CBCapFirst(CBHunterHandle(seed)))", s"\(after)"])]), n"");
    return;
  }
  if turned {
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-Bounty-YouLeftBreathingTheyReOff", [s"\(name)", s"\(CBFactionLabel(gang))"]), n"");
  }
}

// A hunter on their way, for the hunt's "is anybody coming" (CBHuntPending) and the crew lane's "busy".
public func CBBountyComing(game: GameInstance) -> Bool {
  let book = CBHuntBook.Get(game);
  return IsDefined(book) && book.comingSlot > 0;
}

// A gang to stand behind a hunter who turns Rival when the price was nobody's (never, in practice): the most hostile one.
func CBApexFallbackGang(sys: ref<CyberbaneSystem>) -> CName {
  let score = sys.GetScore();
  let best = n"";
  let low = 1000.0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && IsDefined(score) && CBFactionFieldsSquads(fs.id) && score.GetStanding(fs.id) < low {
      low = score.GetStanding(fs.id);
      best = fs.id;
    }
  }
  return best;
}

// ---- Setting them up ---------------------------------------------------------------------------------------

@addField(ScriptedPuppet)
public let cbBountySeed: Int32;
@addField(ScriptedPuppet)
public let cbBountyRank: Int32;

// Which of the ladder a body is, or -1.
func CBBountySlotOf(book: ref<CBHuntBook>, id: EntityID) -> Int32 {
  let n = Min(ArraySize(book.outBody), ArraySize(book.outSlot));
  let i = 0;
  while i < n {
    if Equals(book.outBody[i], id) {
      return book.outSlot[i];
    }
    i += 1;
  }
  return -1;
}

// From spawn setup (Spawn/Spawner.reds): hostile, after V, kitted by their kind and built by their rank.
public func CBSetUpBountyHunter(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, riding: Bool) -> Void {
  let book = CBHuntBook.Get(game);
  if !IsDefined(book) || !IsDefined(puppet) {
    return;
  }
  let slot = CBBountySlotOf(book, puppet.GetEntityID());
  let rank = slot >= 0 ? book.HunterRank(slot) : CBConfig.LadderPlaces();
  if slot >= 0 {
    puppet.cbBountySeed = book.HunterSeed(slot);
    puppet.cbBountyRank = rank;
    puppet.SetScannerDirty(true);
  }
  CBGrantAbility(puppet as NPCPuppet, t"Ability.IsAggressive");
  CBMakeHostileToPlayer(game, puppet);
  CBDisarmGodMode(game, puppet);
  if !riding {
    CBOrderPursue(sys, game, puppet);
  }
  CBTrackOnMap(game, puppet);
  CBKitApexSeat(puppet, CBHunterChair(CBHunterKind(puppet.cbBountySeed)));
  // Rank ten is two-thirds of an apex; rank one is a whole one. The same build, ceilings and slider as theirs.
  let grade = CBConfig.HunterGradeLow() + (1.0 - CBConfig.HunterGradeLow()) * Cast<Float>(CBConfig.LadderPlaces() - rank)
              / Cast<Float>(Max(CBConfig.LadderPlaces() - 1, 1));
  CBApplyApexBuild(sys, game, puppet, grade, CBApexStrengthFraction(), 1.0);
  if rank <= CBConfig.HunterBossBarRank() {
    CBShowBossBar(puppet);
  }
  CBLog.Info(n"Spawn", s"A bounty hunter, rank \(rank), is up and coming for you.");
}

// What the scanner calls them: their name, and their place on the ladder under it.
public func CBBountyScannerName(npc: ref<ScriptedPuppet>) -> String {
  return IsDefined(npc) && npc.cbBountySeed != 0 ? CBHunterName(npc.cbBountySeed) : "";
}

public func CBBountyScannerNote(npc: ref<ScriptedPuppet>) -> String {
  return IsDefined(npc) && npc.cbBountySeed != 0 && !npc.IsDead() ? CBTf(n"Cyberbane-Bounty-BOUNTYHUNTERRANK", [s"\(npc.cbBountyRank)"]) : "";
}

// For the HUD line: the one on their way or out after V, by name, or "".
public func CBBountyHudWho(game: GameInstance) -> String {
  let book = CBHuntBook.Get(game);
  if !IsDefined(book) {
    return "";
  }
  if book.comingSlot > 0 {
    return StrUpper(CBHunterHandle(book.HunterSeed(book.comingSlot - 1)));
  }
  if ArraySize(book.outSlot) > 0 {
    return StrUpper(CBHunterHandle(book.HunterSeed(book.outSlot[0])));
  }
  return "";
}

public func CBBountyComingTicks(game: GameInstance) -> Int32 {
  let book = CBHuntBook.Get(game);
  return IsDefined(book) && book.comingSlot > 0 ? book.comingTicks : 0;
}

// ---- What the Hub says (Standing page) ------------------------------------------------------------------------

public func CBBountyHubLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBHuntBook.Get(game);
  if !CBPriceOnHeadOn() || !IsDefined(book) {
    return "";
  }
  let out = "";
  let amount = CBBountyUp(game);
  if amount > 0 {
    out = CBTf(n"Cyberbane-Bounty-APriceOnYourHeadEddies", [s"\(amount)", s"\(CBBountyPosterName(sys, game, book.BountyBy()))", s"\(CBBountyPayOff(sys, game))"]);
  }
  let v = book.LadderRank();
  if v > 0 || amount > 0 {
    let next = CBLadderNext(book);
    let place = v > 0 ? CBTf(n"Cyberbane-Bounty-YouAreNumberOnTheHunters", [s"\(v)"]) : CBT(n"Cyberbane-Bounty-YouAreNotOnTheHunters");
    let who = next >= 0 ? CBTf(n"Cyberbane-Bounty-NextToComeForYouRank", [s"\(CBHunterName(book.HunterSeed(next)))", s"\(book.HunterRank(next))", s"\(CBHunterTraitWord(book.HunterSeed(next)))", s"\(CBHunterKindWord(book.HunterSeed(next)))"]) : "";
    out += (StrLen(out) > 0 ? " " : "") + place + (amount > 0 ? who : "");
  }
  return out;
}

// ---- [88] Corporate interest ----------------------------------------------------------------------------------

// "Arasaka:Valentinos" is an offer on that gang's leader; "Arasaka" alone a warning.
func CBCorpContractTarget(book: ref<CBHuntBook>) -> CName {
  let parts = StrSplit(NameToString(book.CorpBy()), ":");
  return ArraySize(parts) == 2 ? StringToName(parts[1]) : n"";
}

func CBCorpContractCorp(book: ref<CBHuntBook>) -> CName {
  let parts = StrSplit(NameToString(book.CorpBy()), ":");
  return ArraySize(parts) >= 1 ? StringToName(parts[0]) : n"";
}

func CBCorpContractOpen(game: GameInstance, book: ref<CBHuntBook>) -> Bool {
  return NotEquals(CBCorpContractTarget(book), n"")
      && CBGameSeconds(game) - book.CorpAt() < CBConfig.CorpContractDays() * CBConfig.SecondsPerDay();
}

// From the slow tick: a Legend gets noticed, about once a week.
public func CBCorpInterestRoll(sys: ref<CyberbaneSystem>, game: GameInstance, days: Float) -> Void {
  let book = CBHuntBook.Get(game);
  let score = sys.GetScore();
  if !CBCorpContractsOn() || !IsDefined(book) || !IsDefined(score) || !CBMessagesOn()
     || EnumInt(score.GetTier()) < EnumInt(ECBRenownTier.Legend) {
    return;
  }
  let now = CBGameSeconds(game);
  if book.CorpAt() > 0.0 && now - book.CorpAt() < CBConfig.CorpInterestDays() * CBConfig.SecondsPerDay() {
    return;
  }
  if RandF() >= CBConfig.CorpInterestChancePerDay() * days {
    return;
  }
  let corps = [n"Arasaka", n"Militech", n"KangTao"];
  let corp = corps[RandRange(0, ArraySize(corps))];
  if !CBFactionOn(corp) {
    return;
  }
  let posture = score.GetPosture(corp);
  if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
    return;   // past talking: their contract is the price on V's head
  }
  // Costing them: a warning, and the next step is a contract (CBBountyRoll reads that they warned).
  if score.GetStanding(corp) < CBConfig.CorpWarnStanding() {
    book.SetCorp(corp, now);
    CBFileLog(sys, n"CorpWarned", now, CBEventDistrict(sys, game), corp, 0.0);
    CBPhoneSendTinted(game, CBBountyContact(corp), CBPick2(
      CBT(n"Cyberbane-Bounty-YouVeCostUsMoreThis"),
      CBT(n"Cyberbane-Bounty-WeKnowYourNameWeD")), CBHudAmber());
    return;
  }
  // Otherwise a job: a gang's leader they want gone, a gang V has trouble with first.
  let target = n"";
  let leaderName = "";
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && Equals(target, n"") && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) && fs.leaderRivalId > 0 {
      let leader = sys.FindRivalById(fs.leaderRivalId);
      let p = score.GetPosture(fs.id);
      if IsDefined(leader) && CBRivalStillAround(leader)
         && (Equals(p, ECBPosture.Hostile) || Equals(p, ECBPosture.Vendetta)) {
        target = fs.id;
        leaderName = CBRivalDisplayName(CBContent(game), leader);
      }
    }
  }
  if Equals(target, n"") {
    return;
  }
  let pay = CBReward(CBBountyRound(Cast<Float>(CBConfig.CorpLeaderContractPay()) * CBLootLevelScale(game)));
  book.SetCorp(StringToName(NameToString(corp) + ":" + NameToString(target)), now);
  CBFileLog(sys, n"CorpOffer", now, CBEventDistrict(sys, game), target, Cast<Float>(pay));
  CBPhoneSendTinted(game, CBBountyContact(corp),
    CBTf(n"Cyberbane-Bounty-AProposalForOfHasBecome", [s"\(CBYou(sys, game))", s"\(leaderName)", s"\(CBFactionLabel(target))", s"\(pay)"]), CBHudCyan());
}

// The leader they wanted gone is dead by V's hand: paid.
func CBCorpContractSlain(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBHuntBook>, slain: ref<CBRival>, wasLeader: Bool, byV: Bool) -> Void {
  if !byV || !wasLeader || !CBCorpContractOpen(game, book) || !Equals(CBCorpContractTarget(book), slain.faction) {
    return;
  }
  let corp = CBCorpContractCorp(book);
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  let pay = CBReward(CBBountyRound(Cast<Float>(CBConfig.CorpLeaderContractPay()) * CBLootLevelScale(game)));
  // Done: no target left, the week still counts. "Arasaka:" rather than "Arasaka", which is what a warning leaves, so a
  // contract they put out on V later does not open with "We told you to stop" to a merc who did their job for them.
  book.SetCorp(StringToName(NameToString(corp) + ":"), book.CorpAt());
  if IsDefined(player) && IsDefined(ts) {
    ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), pay);
  }
  if !CBReputationFrozen() {
    let fs = sys.EnsureFaction(corp);
    if IsDefined(fs) {
      fs.standing = ClampF(fs.standing + CBConfig.CorpLeaderContractStanding(), -100.0, 100.0);
    }
  }
  CBFileLog(sys, n"CorpContractDone", CBGameSeconds(game), CBEventDistrict(sys, game), corp, Cast<Float>(pay));
  if CBToastsOn() {
    CBPhoneSend(game, CBBountyContact(corp), CBTf(n"Cyberbane-Bounty-SatisfactoryEddiesHaveBeenTransferredWe", [s"\(pay)"]));
  }
}
