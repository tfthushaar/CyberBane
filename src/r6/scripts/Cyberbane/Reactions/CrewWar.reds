// Cyberbane - The crew at war: who can go, what they weigh, and the spoils
//
// Who of the crew can go on a war's order and what each weighs, the odds words, a war chest left on the gang's streets,
// the district's hidden stashes, a loose tongue and a defector. The war itself is Reactions/GangWar.reds; the old
// eighteen-hour parties a save may still have out are settled here when they come due.

public func CBMemWarChest() -> Int32 = 6

public func CBWarOutcomeRouted() -> Int32 = -1
public func CBWarOutcomeLost() -> Int32 = 0
public func CBWarOutcomeStalemate() -> Int32 = 1
public func CBWarOutcomeWon() -> Int32 = 2
public func CBWarOutcomeDecisive() -> Int32 = 3

public class CBCrewWarBook extends ScriptableSystem {
  private persistent let m_gang: array<CName>;
  private persistent let m_start: array<Float>;
  private persistent let m_end: array<Float>;
  private persistent let m_phase: array<Int32>;
  private persistent let m_odds: array<Float>;     // the weights' ratio when they set off, for how the reports sound
  // The Hub's party being put together (session): the gang, who is in it, and the screen to go back to.
  public let pickGang: CName;
  public let pickParty: array<Int32>;
  public let pickFrom: Int32;

  public static func Get(game: GameInstance) -> ref<CBCrewWarBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewWarBook") as CBCrewWarBook : null;
  }

  public func Count() -> Int32 {
    return Min(Min(ArraySize(this.m_gang), ArraySize(this.m_start)), Min(Min(ArraySize(this.m_end), ArraySize(this.m_phase)), ArraySize(this.m_odds)));
  }

  public func Gang(i: Int32) -> CName { return i >= 0 && i < this.Count() ? this.m_gang[i] : n""; }
  public func StartAt(i: Int32) -> Float { return i >= 0 && i < this.Count() ? this.m_start[i] : 0.0; }
  public func EndAt(i: Int32) -> Float { return i >= 0 && i < this.Count() ? this.m_end[i] : 0.0; }
  public func Phase(i: Int32) -> Int32 { return i >= 0 && i < this.Count() ? this.m_phase[i] : 0; }
  public func Odds(i: Int32) -> Float { return i >= 0 && i < this.Count() ? this.m_odds[i] : 1.0; }

  public func SetPhase(i: Int32, p: Int32) -> Void {
    if i >= 0 && i < this.Count() {
      this.m_phase[i] = p;
    }
  }

  public func Index(gang: CName, end: Float) -> Int32 {
    let i = 0;
    while i < this.Count() {
      if Equals(this.m_gang[i], gang) && AbsF(this.m_end[i] - end) < 1.0 {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func Start(gang: CName, start: Float, end: Float, odds: Float) -> Void {
    ArrayPush(this.m_gang, gang);
    ArrayPush(this.m_start, start);
    ArrayPush(this.m_end, end);
    ArrayPush(this.m_phase, 0);
    ArrayPush(this.m_odds, odds);
  }

  public func Remove(i: Int32) -> Void {
    if i < 0 || i >= this.Count() {
      return;
    }
    ArrayErase(this.m_gang, i);
    ArrayErase(this.m_start, i);
    ArrayErase(this.m_end, i);
    ArrayErase(this.m_phase, i);
    ArrayErase(this.m_odds, i);
  }

  public func InParty(id: Int32) -> Bool {
    return ArrayContains(this.pickParty, id);
  }

  public func Toggle(id: Int32) -> Void {
    if ArrayContains(this.pickParty, id) {
      ArrayRemove(this.pickParty, id);
    } else {
      if ArraySize(this.pickParty) < CBConfig.CrewWarPartyMax() {
        ArrayPush(this.pickParty, id);
      }
    }
  }

  public func Clear() -> Void {
    ArrayClear(this.m_gang);
    ArrayClear(this.m_start);
    ArrayClear(this.m_end);
    ArrayClear(this.m_phase);
    ArrayClear(this.m_odds);
    this.pickGang = n"";
    ArrayClear(this.pickParty);
    this.pickFrom = 0;
  }
}

// ---- Who can go, and what each side weighs ---------------------------------------------------------------------------

public func CBCrewWarEligible(game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>, now: Float) -> Bool {
  return IsDefined(book) && IsDefined(m) && CBCrewRankOf(game, m) >= CBConfig.CrewWarFollowMinRank() && !CBCrewHurt(m, now)
      && !book.IsOut(m.id) && !CBCrewAway(game, m.id, now) && !CBCrewSparring(game, m.id) && m.loyalty >= CBConfig.MyCrewBetrayLine();
}

// Why this one cannot go, in a few words for the party screen; "" when they can.
public func CBCrewWarWhyNot(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>, now: Float) -> String {
  if !IsDefined(m) {
    return "";
  }
  if CBCrewRankOf(game, m) < CBConfig.CrewWarFollowMinRank() {
    return CBTf(n"Cyberbane-CrewWar-NeedsRank", [CBCrewRankWord(CBConfig.CrewWarFollowMinRank())]);
  }
  if CBCrewHurt(m, now) {
    return CBT(n"Cyberbane-Hud-HurtNotYet");
  }
  if book.IsOut(m.id) {
    return CBT(n"Cyberbane-CrewWar-WithYou");
  }
  let away = CBCrewAwayWord(game, m.id, now);
  if StrLen(away) > 0 {
    return StrLower(away);
  }
  if CBCrewSparring(game, m.id) {
    return CBT(n"Cyberbane-CrewWar-Sparring");
  }
  if m.loyalty < CBConfig.MyCrewBetrayLine() {
    return CBT(n"Cyberbane-CrewWar-NotForYou");
  }
  return "";
}

public func CBCrewMemberWarPower(game: GameInstance, m: ref<CBCrewMember>) -> Float {
  if !IsDefined(m) {
    return 0.0;
  }
  let p = CBConfig.WarPowerBase() + CBConfig.WarPowerPerRank() * Cast<Float>(CBCrewRankOf(game, m));
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  // The crew's armoury puts a better gun in every hand (Reactions/CrewGang.reds).
  if CBCrewHas(game, CBUpgradeArmoury()) {
    p += CBConfig.WarPowerPerTier() * Cast<Float>(CBConfig.UpgradeArmouryTiers());
  }
  if IsDefined(k) {
    p += CBConfig.WarPowerPerChrome() * Cast<Float>(k.ChromeCount());
    p += CBConfig.WarPowerPerTier() * Cast<Float>(k.hasWeapon ? k.weaponTier : 0);
    p += CBConfig.WarPowerPerTrain() * Cast<Float>(k.trained);
    if k.sharpUntil > CBGameSeconds(game) {
      p += CBConfig.WarPowerSharp();
    }
  }
  return p * (0.7 + 0.3 * Cast<Float>(Clamp(m.loyalty, 0, 100)) / 100.0) * CBCrewMarkMult(game, m.id);
}

public func CBCrewPartyWarPower(sys: ref<CyberbaneSystem>, game: GameInstance, party: array<Int32>, gang: CName) -> Float {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || ArraySize(party) == 0 {
    return 0.0;
  }
  let sum = 0.0;
  let seats: array<Int32>;
  for id in party {
    let m = book.Find(id);
    if IsDefined(m) {
      sum += CBCrewMemberWarPower(game, m);
      if !ArrayContains(seats, m.seat) {
        ArrayPush(seats, m.seat);
      }
    }
  }
  sum *= 1.0 + CBConfig.WarSeatBonus() * Cast<Float>(Max(ArraySize(seats) - 1, 0));
  let home = CBGangHomeDistrict(sys, game, gang);
  sum += CBConfig.WarFootPower() * CBCrewFoothold(game, home) + CBConfig.WarWeightPower() * CBCrewWeight(game);
  return sum;
}

// What the gang has, whole (Reactions/GangWar.reds): its people, money, names, places and friends.
public func CBGangWarPower(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Float {
  return CBGangWarWeight(sys, game, gang);
}

// The chance a party of this weight against the gang's wins at all (a win or a decisive win): each fight swings the ratio
// by a factor between WarSwingLow and WarSwingHigh, and a win is the swung ratio reaching one.
public func CBWarWinChance(ratio: Float) -> Float {
  if ratio <= 0.0 {
    return 0.0;
  }
  let lo = CBConfig.WarSwingLow();
  let hi = CBConfig.WarSwingHigh();
  return ClampF((hi - MaxF(lo, 1.0 / ratio)) / (hi - lo), 0.0, 1.0);
}

public func CBWarOddsWord(ratio: Float) -> String {
  if ratio >= 1.5 { return CBT(n"Cyberbane-CrewWar-OddsWalkIt"); }
  if ratio >= 1.15 { return CBT(n"Cyberbane-CrewWar-OddsShouldWin"); }
  if ratio >= 0.85 { return CBT(n"Cyberbane-CrewWar-OddsEven"); }
  if ratio >= 0.6 { return CBT(n"Cyberbane-CrewWar-OddsLong"); }
  return CBT(n"Cyberbane-CrewWar-OddsSuicide");
}

// Somebody of Lieutenant rank or more leads it.
public func CBCrewWarPartyLed(game: GameInstance, book: ref<CBCrewBook>, party: array<Int32>) -> Bool {
  for id in party {
    let m = IsDefined(book) ? book.Find(id) : null;
    if IsDefined(m) && CBCrewRankOf(game, m) >= CBConfig.CrewWarMinRank() {
      return true;
    }
  }
  return false;
}

// "2 wars under way" for the Crew page's Go to war row, "" when there are none.
public func CBCrewWarsOnWord(game: GameInstance) -> String {
  let wb = CBCrewWarBook.Get(game);
  let n = IsDefined(wb) ? wb.Count() : 0;
  if n <= 0 {
    return "";
  }
  return n == 1 ? CBT(n"Cyberbane-CrewWar-OneWarOn") : CBTf(n"Cyberbane-CrewWar-WarsOn", [s"\(n)"]);
}

// Their first names, for a line: "Ryo, Kai and Mina".
func CBCrewNamesList(sys: ref<CyberbaneSystem>, book: ref<CBCrewBook>, ids: array<Int32>) -> String {
  let out = "";
  let n = ArraySize(ids);
  let i = 0;
  while i < n {
    let m = book.Find(ids[i]);
    let name = IsDefined(m) ? CBCrewFirst(sys, m) : CBT(n"Cyberbane-Telling-Somebody");
    if i == 0 {
      out = name;
    } else {
      out += (i == n - 1 ? CBT(n"Cyberbane-CrewWar-And") : ", ") + name;
    }
    i += 1;
  }
  return out;
}

// ---- Off to war -----------------------------------------------------------------------------------------------------

// The party goes. Only words and the crew's books: carried out from the Hub here and now, its texts sent once the game is
// back (CBCrewKitBook.deferTexts). True when they went.
public func CBCrewSendWarParty(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, party: array<Int32>) -> Bool {
  if !IsDefined(sys) || Equals(gang, n"") {
    return false;
  }
  // A war on them first, if there is none; then the party is sent on an order: their corners.
  if !CBCrewWarOn(game, gang) && !CBGangWarDeclare(sys, game, gang, false) {
    return false;
  }
  return CBGangWarGiveOrder(sys, game, gang, CBWarOrderCorners(), party, 0, false, false);
}

// ---- How it goes ----------------------------------------------------------------------------------------------------

// Twice on the way the crew's group chat says how it is going, sounding the way the weights said it would.
public func CBCrewWarTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let wb = CBCrewWarBook.Get(game);
  if !IsDefined(sys) || !IsDefined(wb) {
    return;
  }
  let now = CBGameSeconds(game);
  let i = 0;
  while i < wb.Count() {
    let start = wb.StartAt(i);
    let span = wb.EndAt(i) - start;
    let phase = wb.Phase(i);
    if span > 0.0 && phase < 2 && now >= start + span * Cast<Float>(phase + 1) / 3.0 && now < wb.EndAt(i) {
      wb.SetPhase(i, phase + 1);
      let place = CBDistrictLabel(CBGangHomeDistrict(sys, game, wb.Gang(i)));
      let label = CBFactionLabel(wb.Gang(i));
      let odds = wb.Odds(i);
      let line = "";
      if phase == 0 {
        line = odds >= 1.15 ? CBTf(n"Cyberbane-CrewWar-NightOneGood", [place, label])
             : (odds >= 0.85 ? CBTf(n"Cyberbane-CrewWar-NightOneEven", [place, label]) : CBTf(n"Cyberbane-CrewWar-NightOneBad", [place, label]));
      } else {
        line = odds >= 1.15 ? CBTf(n"Cyberbane-CrewWar-NightTwoGood", [label])
             : (odds >= 0.85 ? CBT(n"Cyberbane-CrewWar-NightTwoEven") : CBT(n"Cyberbane-CrewWar-NightTwoBad"));
      }
      if CBMessagesOn() {
        CBCrewText(sys, game, null, line);
      }
    }
    i += 1;
  }
}

// The war is over for the party this member went with (everybody who went on the same gang, due at the same moment).
// True when somebody did not come back (the roster changed under the caller's walk).
public func CBCrewWarPartyResolve(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, book: ref<CBCrewBook>,
                                  gang: CName, end: Float, now: Float) -> Bool {
  if Equals(gang, n"") || !IsDefined(kb) || !IsDefined(book) {
    return false;
  }
  let party: array<ref<CBCrewMember>>;
  let ids: array<Int32>;
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    let k = IsDefined(m) ? kb.Find(m.id) : null;
    if IsDefined(k) && Equals(k.warOn, gang) && k.warUntil > 0.0 && AbsF(k.warUntil - end) < 1.0 {
      k.warUntil = 0.0;
      k.warOn = n"";
      ArrayPush(party, m);
      ArrayPush(ids, m.id);
    }
  }
  let wb = CBCrewWarBook.Get(game);
  if IsDefined(wb) {
    wb.Remove(wb.Index(gang, end));
  }
  if ArraySize(party) == 0 {
    return false;
  }
  let ours = CBCrewPartyWarPower(sys, game, ids, gang);
  // V's second leading it, and V in it: each of theirs V put down while it was on.
  if ArrayContains(ids, CBCrewSecondId(game)) {
    ours *= 1.0 + CBConfig.CrewSecondWarBonus();
  }
  let vHelp = CBCrewWarVHelp(game, gang, false);
  ours *= 1.0 + vHelp;
  // A party sent the old way, before the wars had fronts, is weighed on the scale it was sent on.
  let theirs = CBGangWarPower(sys, game, gang) / CBConfig.GangWarScale();
  let ratio = ours / theirs;
  let score = ratio * RandRangeF(CBConfig.WarSwingLow(), CBConfig.WarSwingHigh());
  let outcome = CBWarOutcomeRouted();
  if score >= 1.5 { outcome = CBWarOutcomeDecisive(); } else {
    if score >= 1.0 { outcome = CBWarOutcomeWon(); } else {
      if score >= 0.75 { outcome = CBWarOutcomeStalemate(); } else {
        if score >= 0.45 { outcome = CBWarOutcomeLost(); }
      }
    }
  }
  CBLog.Info(n"Crew", s"War on \(NameToString(gang)) over: \(ArraySize(party)) went, weights \(RoundF(ours)) to \(RoundF(theirs)), swung \(RoundF(score * 100.0))%, outcome \(outcome).");
  return CBCrewWarApply(sys, game, kb, book, gang, party, outcome, now);
}

func CBCrewWarApply(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, book: ref<CBCrewBook>, gang: CName,
                    party: array<ref<CBCrewMember>>, outcome: Int32, now: Float) -> Bool {
  let where = CBGangHomeDistrict(sys, game, gang);
  let label = CBCapFirst(CBFactionLabel(gang));
  let place = CBDistrictLabel(where);
  let n = ArraySize(party);
  let strengthBefore = CBGangStrength(sys, gang);
  // The weakest of them is the one a bad night costs first.
  let weakest: ref<CBCrewMember>;
  let maxPower = 0.0;
  for m in party {
    let p = CBCrewMemberWarPower(game, m);
    maxPower = MaxF(maxPower, p);
    if !IsDefined(weakest) || p < CBCrewMemberWarPower(game, weakest) {
      weakest = m;
    }
  }
  let hurtNames: array<Int32>;
  let fallen: array<ref<CBCrewMember>>;
  let won = outcome >= CBWarOutcomeWon();
  if won {
    let decisive = outcome == CBWarOutcomeDecisive();
    CBWeakenGang(sys, game, gang, CBConfig.CrewWarGangLoss() * (decisive ? 1.5 : 1.0), where);
    CBTalkSlight(sys, game, gang, CBConfig.CrewWarStanding());
    CBCrewStandingShift(game, gang, -CBConfig.CrewStandWarWon());
    let content = sys.GetContent();
    let enemy = IsDefined(content) ? CBTopEnemyOf(sys, content, gang) : n"";
    CBCrewStandingShift(game, enemy, CBConfig.CrewStandWarEnemy());   // the enemy of their enemy
    if Equals(CBTurfHolder(sys, game, where), gang) {
      CBCrewTurfRaise(sys, game, where, decisive ? CBConfig.WarFootDecisive() : CBConfig.WarFootWon());
    }
    kb.NoteWarWon();
    for m in party {
      m.wins += decisive ? 3 : 2;
      m.loyalty = Min(100, m.loyalty + (decisive ? 6 : 4));
    }
    if !decisive && IsDefined(weakest) && RandF() < CBConfig.WarWonHurtChance() {
      weakest.hurtUntil = now + 0.5 * CBConfig.CrewWarHurtHours() * CBConfig.SecondsPerHour();
      ArrayPush(hurtNames, weakest.id);
    }
    // The spoils: what their corners held, the kitty's; more when V was out there with them.
    let spoils = CBReward(RoundF(CBConfig.WarSpoilsPerMember() * Cast<Float>(n) * (decisive ? 1.0 : 0.6) * (0.5 + strengthBefore / 100.0)
                        * (1.0 + CBCrewWarVHelp(game, gang, false))));
    let jb = CBCrewJobBook.Get(game);
    if IsDefined(jb) && spoils > 0 {
      jb.AddKitty(spoils);
    }
    CBFileLog(sys, n"CrewWarWon", now, where, gang, Cast<Float>(n));
    if CBMessagesOn() {
      CBCrewText(sys, game, null, decisive ? CBTf(n"Cyberbane-CrewWar-ResultDecisive", [label, place, s"\(spoils)"])
                                           : CBTf(n"Cyberbane-CrewWar-ResultWon", [label, place, s"\(spoils)"]));
    }
    CBWarChestOwe(sys, game, gang, where, decisive ? 2 : 1);
    // And the district's own hidden stashes, as many as the win earned.
    let stashes = CBWarSecretStashes(sys, game, where, decisive ? CBConfig.WarStashesDecisive() : CBConfig.WarStashesWon());
    if stashes > 0 && CBMessagesOn() {
      CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewWar-StashesMarked", [label, s"\(stashes)", place]));
    }
    // Who carried it, by name, and V's part when V fought on their streets.
    let best: ref<CBCrewMember>;
    for bm in party {
      if !IsDefined(best) || CBCrewMemberWarPower(game, bm) > CBCrewMemberWarPower(game, best) {
        best = bm;
      }
    }
    if CBMessagesOn() && IsDefined(best) && n > 1 {
      CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewWar-Carried", [CBCrewFirst(sys, best)]));
    }
    if CBMessagesOn() && CBCrewWarVHelp(game, gang, false) > 0.0 {
      CBCrewText(sys, game, null, CBT(n"Cyberbane-CrewWar-YouWereThere"));
    }
    CBWarLooseTongue(sys, game, gang);
    if decisive {
      CBWarDefector(sys, game, book, gang);
    }
  } else {
    if outcome == CBWarOutcomeStalemate() {
      CBWeakenGang(sys, game, gang, CBConfig.CrewWarGangLoss() * 0.4, where);
      CBTalkSlight(sys, game, gang, CBConfig.CrewWarStanding() * 0.5);
      CBCrewStandingShift(game, gang, -CBConfig.CrewStandWarLost() / 2);
      if Equals(CBTurfHolder(sys, game, where), gang) {
        CBCrewTurfRaise(sys, game, where, CBConfig.WarFootStalemate());
      }
      for m in party {
        m.wins += 1;
        if RandF() < 0.5 {
          m.hurtUntil = now + 0.6 * CBConfig.CrewWarHurtHours() * CBConfig.SecondsPerHour();
          ArrayPush(hurtNames, m.id);
        }
      }
      if CBMessagesOn() {
        CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewWar-ResultStalemate", [label, place]));
      }
    } else {
      // Lost, or routed: everybody comes back hurt, if they come back.
      let routed = outcome == CBWarOutcomeRouted();
      CBWeakenGang(sys, game, gang, routed ? 0.0 : CBConfig.CrewWarGangLoss() * 0.1, where);
      CBCrewStandingShift(game, gang, -CBConfig.CrewStandWarLost());
      CBCrewTurfRaise(sys, game, where, routed ? -CBConfig.WarFootRouted() : -CBConfig.WarFootLost());
      CBFileLog(sys, n"CrewWarLost", now, where, gang, Cast<Float>(n));
      for m in party {
        let p = CBCrewMemberWarPower(game, m);
        let die = 0.0;
        if routed {
          die = CBConfig.WarRoutDeathBase() + CBConfig.WarRoutDeathSpread() * (1.0 - (maxPower > 0.0 ? p / maxPower : 1.0));
        } else {
          die = m == weakest ? CBConfig.CrewWarDeathShare() * 0.6 : 0.0;
        }
        if RandF() < die {
          ArrayPush(fallen, m);
        } else {
          m.hurtUntil = now + CBConfig.CrewWarHurtHours() * CBConfig.SecondsPerHour();
          m.loyalty = Max(0, m.loyalty - (routed ? 6 : 3));
          ArrayPush(hurtNames, m.id);
        }
      }
      if CBMessagesOn() {
        CBCrewText(sys, game, null, routed ? CBTf(n"Cyberbane-CrewWar-ResultRouted", [label, place]) : CBTf(n"Cyberbane-CrewWar-ResultLost", [label, place]));
      }
    }
  }
  if ArraySize(hurtNames) > 0 && CBMessagesOn() {
    CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewWar-Hurt", [CBCrewNamesList(sys, book, hurtNames), s"\(RoundF(CBConfig.CrewWarHurtHours()))"]));
  }
  // In each of their stories, and the phone's short chirp for a call that went well or badly (it ends on its own). V's
  // part in this war is spent.
  for wm in party {
    CBCrewLifeNote(game, wm.id, CBLifeWar(), gang, won ? 1 : 0);
  }
  CBUiSound(game, won ? n"ui_phone_incoming_call_positive" : n"ui_phone_incoming_call_negative", n"WarResult", 5.0);
  CBCrewGroupReplies(sys, game, won ? 1 : 2, 0);   // the group chat talks it over
  CBCrewWarVHelp(game, gang, true);
  // The fallen, last: taking them off the roster changes the book.
  let bb = CBCrewBannerBook.Get(game);
  for f in fallen {
    let name = CBCrewName(sys, f);
    if IsDefined(bb) {
      bb.fallCause = CBCrewFellAtWar();   // for the memorial
      bb.fallGang = gang;
    }
    book.Remove(f, CBCrewEndFell(), 0, where, now);
    if CBMessagesOn() {
      CBPhoneSendTinted(game, CBPhoneGangSender(gang), CBTf(n"Cyberbane-CrewKit-CameForUsIsnTComing", [s"\(name)", s"\(name)"]), CBHudRed());
    }
  }
  return ArraySize(fallen) > 0;
}

// ---- The spoils ------------------------------------------------------------------------------------------------------

// Their war chest, left at a fast travel point on their home streets: a pin on the map, and the loot laid when V gets
// there (CBWarChestTick). `tier` 2 for a decisive win.
func CBWarChestOwe(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, district: CName, tier: Int32) -> Void {
  let player = GetPlayer(game);
  let book = CBMapBook.Get(game);
  if !IsDefined(player) || !IsDefined(book) {
    return;
  }
  let picks: array<Vector4>;
  let names: array<String>;
  if CBFastTravelPlaces(sys, game, district, player.GetWorldPosition(), 0.0, 100000.0, picks, names) <= 0 || ArraySize(picks) == 0 {
    CBLog.Info(n"Crew", s"No fast travel point in \(NameToString(district)) to leave a war chest at; the spoils are the kitty's alone.");
    return;
  }
  let k = RandRange(0, ArraySize(picks));
  book.Add(CBMemWarChest(), picks[k], CBGameSeconds(game), tier, gang, n"", n"", district, true);
  if CBMessagesOn() {
    let spot = k < ArraySize(names) ? names[k] : CBDistrictLabel(district);
    CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewWar-ChestLeft", [CBPossessive(CBFactionLabel(gang)), spot, CBDistrictLabel(district)]));
  }
  CBLog.Info(n"Crew", s"A war chest of \(NameToString(gang))'s was left in \(NameToString(district)).");
}

// V at a war chest, out of a fight and on foot: the loot laid there, and the pin taken down.
public func CBWarChestTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  let book = CBMapBook.Get(game);
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(book) || player.IsInCombat() || IsDefined(player.GetMountedVehicle())
     || !CBWorldStable(game) {
    return;
  }
  let ppos = player.GetWorldPosition();
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && m.kind == CBMemWarChest() {
      let at = new Vector4(m.x, m.y, m.z, 1.0);
      if Vector4.Distance(ppos, at) <= CBConfig.StrongholdStashReach() {
        let tiers: array<Int32>;
        ArrayPush(tiers, CBLootTierApex());
        if m.subject >= 2 {
          ArrayPush(tiers, CBLootTierApex() + 1);
        }
        let laid = CBLootBagAt(sys, game, player, at, tiers);
        let label = CBCapFirst(CBPossessive(CBFactionLabel(m.a)));
        book.Unpin(GameInstance.GetMappinSystem(game), m.id);
        book.Forget(m);
        if CBMessagesOn() {
          CBSystemNote(game, laid > 0 ? CBTf(n"Cyberbane-CrewWar-ChestFound", [label]) : CBTf(n"Cyberbane-CrewWar-ChestKept", [label]), 7.0);
        }
        CBLog.Info(n"Crew", s"A war chest was opened: \(laid) kinds of item.");
        return;   // the list changed
      }
    }
  }
}

// ---- The district's hidden stashes ------------------------------------------------------------------------------------
//
// The game's hidden stashes are points of interest on its map (the HiddenStash variant, paid from
// LootTables.HiddenStashMoneyReward).

public func CBMemSecretStash() -> Int32 = 7

// The district of the fast travel point nearest a spot: the game's word on where a place is, for spots V is nowhere
// near.
public func CBDistrictNear(sys: ref<CyberbaneSystem>, game: GameInstance, at: Vector4) -> CName {
  if !CBWorldStable(game) {
    return n"";
  }
  let container = GameInstance.GetScriptableSystemsContainer(game);
  let fts = IsDefined(container) ? container.Get(n"FastTravelSystem") as FastTravelSystem : null;
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(fts) || !IsDefined(ms) {
    return n"";
  }
  let best = n"";
  let bestAway = -1.0;
  let points = fts.GetFastTravelPoints();
  for pt in points {
    if IsDefined(pt) {
      let pointId = pt.GetPointRecord();
      let rec = TDBID.IsValid(pointId) ? TweakDBInterface.GetFastTravelPointRecord(pointId) : null;
      if IsDefined(rec) && !rec.SubwayStation() {
        let flat = pointId;
        TDBID.Append(flat, t".district");
        let districtId = TweakDBInterface.GetForeignKey(flat, TDBID.None());
        let dRec = TDBID.IsValid(districtId) ? TweakDBInterface.GetDistrictRecord(districtId) : null;
        let pin = IsDefined(dRec) ? ms.GetMappin(pt.mappinID) : null;
        if IsDefined(pin) {
          let away = Vector4.Distance(at, pin.GetWorldPosition());
          if bestAway < 0.0 || away < bestAway {
            bestAway = away;
            best = CBMapGameDistrict(dRec.EnumName());
          }
        }
      }
    }
  }
  return best;
}

// Mark up to `most` of the game's hidden stashes in this district that V has not emptied. How many were marked.
func CBWarSecretStashes(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName, most: Int32) -> Int32 {
  let ms = GameInstance.GetMappinSystem(game);
  let book = CBMapBook.Get(game);
  if !IsDefined(ms) || !IsDefined(book) || most <= 0 || Equals(district, n"") || !CBWorldStable(game) {
    return 0;
  }
  let pins: array<ref<IMappin>>;
  ms.GetMappins(gamemappinsMappinTargetType.Map, pins);
  let marked = 0;
  for p in pins {
    if marked < most && IsDefined(p) && Equals(p.GetVariant(), gamedataMappinVariant.HiddenStashVariant)
       && NotEquals(p.GetPhase(), gamedataMappinPhase.CompletedPhase) {
      let at = p.GetWorldPosition();
      if !CBSecretStashMarked(book, at) && Equals(CBDistrictNear(sys, game, at), district) {
        book.Add(CBMemSecretStash(), at, CBGameSeconds(game), 0, n"", n"", n"", district, true);
        marked += 1;
      }
    }
  }
  return marked;
}

func CBSecretStashMarked(book: ref<CBMapBook>, at: Vector4) -> Bool {
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && m.kind == CBMemSecretStash() && Vector4.Distance(at, new Vector4(m.x, m.y, m.z, 1.0)) < 5.0 {
      return true;
    }
  }
  return false;
}

// V has been to a marked stash: the mark comes off (the stash itself is the game's, to open as it always is).
public func CBSecretStashTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let player = GetPlayer(game);
  let book = CBMapBook.Get(game);
  if !IsDefined(player) || !IsDefined(book) {
    return;
  }
  let ppos = player.GetWorldPosition();
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && m.kind == CBMemSecretStash() && Vector4.Distance(ppos, new Vector4(m.x, m.y, m.z, 1.0)) <= CBConfig.SecretStashReach() {
      book.Unpin(GameInstance.GetMappinSystem(game), m.id);
      book.Forget(m);
      CBLog.Info(n"Crew", "V reached a hidden stash the crew had marked.");
      return;   // the list changed
    }
  }
}

// A tongue loosened: where one of their Rivals was last seen, made a lead (the one the Hub and the map already follow).
func CBWarLooseTongue(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Void {
  let now = CBGameSeconds(game);
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, gang)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) && !CBRivalBodyPresent(game, r) {
      let s = CBSightingFor(sys, r);
      if IsDefined(s) {
        CBMarkLeadTold(sys, s, n"", now);
        if CBMessagesOn() {
          CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewWar-TongueLoosened", [CBRivalDisplayName(sys.GetContent(), r), CBPlacePhrase(s.district, CBSightingPos(s))]));
        }
        CBLog.Info(n"Crew", s"A war loosened a tongue: a lead on rival \(r.id).");
        return;
      }
    }
  }
}

// After a decisive win somebody of theirs walks out and wants in: a broker's offer, cheap, with fights behind them.
func CBWarDefector(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, gang: CName) -> Void {
  let now = CBGameSeconds(game);
  if !book.HasRoom() || book.offerUntil > now {
    return;
  }
  let seed = RandRange(1, 1000000);
  if !TDBID.IsValid(CBHunterRecord(seed, n"")) {
    return;
  }
  let score = sys.GetScore();
  let tier = IsDefined(score) ? EnumInt(score.GetTier()) : 0;
  book.offerSeed = seed;
  book.offerPrice = RoundF(Cast<Float>(CBConfig.MyCrewMercBase() + CBConfig.MyCrewMercPerTier() * tier) * CBConfig.WarDefectorPrice());
  book.offerHaggled = false;
  book.offerUntil = now + CBConfig.SecondsPerDay();
  book.offerSender = CBPhoneDistrictSender(CBGangHomeDistrict(sys, game, gang));
  if Equals(book.offerSender, CBPhoneUnknownSender()) {
    book.offerSender = CBT(n"Cyberbane-Crew-Broker");
  }
  let bb = CBCrewBannerBook.Get(game);
  if IsDefined(bb) {
    bb.offerWins = CBConfig.CrewRecruitWins();
  }
  let solo = CBCrewOfferName(sys, game, book);
  let seat = CBCrewSeatWord(CBCrewSeatOf(CBHunterRecord(seed, n""), seed));
  CBPhoneSendTinted(game, book.offerSender, CBTf(n"Cyberbane-CrewWar-Defector", [CBFactionLabel(gang), solo, seat, s"\(book.offerPrice)"]), CBHudCyan());
  CBLog.Info(n"Crew", "A decisive war brought V a defector's offer.");
}
