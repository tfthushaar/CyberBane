// Cyberbane - Gangs that adapt to how V fights ([40])
//
// Every gang keeps a ledger of how V hurts its people: shot, cut or beaten, hacked, blown up, or taken quietly with
// nobody to see. It comes from the method flags the scoring already works out for every kill and takedown (CBKillInfo),
// counted in CBApplyKill, and fades by a fifth every in-game day.

public func CBGangsAdaptOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().gangsAdapt;
}

public func CBAdaptNone() -> Int32 = 0
public func CBAdaptGuns() -> Int32 = 1
public func CBAdaptMelee() -> Int32 = 2
public func CBAdaptHacks() -> Int32 = 3
public func CBAdaptBlast() -> Int32 = 4
public func CBAdaptQuiet() -> Int32 = 5

public class CBLedgerBook extends ScriptableSystem {
  private persistent let m_gang: array<CName>;
  private persistent let m_guns: array<Float>;
  private persistent let m_melee: array<Float>;
  private persistent let m_hacks: array<Float>;
  private persistent let m_blast: array<Float>;
  private persistent let m_quiet: array<Float>;
  private persistent let m_adapt: array<Int32>;      // what they are prepared for now, to say it once
  private let m_trimmed: Bool;

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_trimmed = false;
  }

  public static func Get(game: GameInstance) -> ref<CBLedgerBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBLedgerBook") as CBLedgerBook;
  }

  private func Trim() -> Void {
    if this.m_trimmed {
      return;
    }
    this.m_trimmed = true;
    let n = Min(Min(ArraySize(this.m_gang), ArraySize(this.m_guns)), Min(Min(ArraySize(this.m_melee), ArraySize(this.m_hacks)),
                Min(Min(ArraySize(this.m_blast), ArraySize(this.m_quiet)), ArraySize(this.m_adapt))));
    ArrayResize(this.m_gang, n);
    ArrayResize(this.m_guns, n);
    ArrayResize(this.m_melee, n);
    ArrayResize(this.m_hacks, n);
    ArrayResize(this.m_blast, n);
    ArrayResize(this.m_quiet, n);
    ArrayResize(this.m_adapt, n);
  }

  private func IndexOf(gang: CName, add: Bool) -> Int32 {
    this.Trim();
    let i = 0;
    while i < ArraySize(this.m_gang) {
      if Equals(this.m_gang[i], gang) {
        return i;
      }
      i += 1;
    }
    if !add {
      return -1;
    }
    ArrayPush(this.m_gang, gang);
    ArrayPush(this.m_guns, 0.0);
    ArrayPush(this.m_melee, 0.0);
    ArrayPush(this.m_hacks, 0.0);
    ArrayPush(this.m_blast, 0.0);
    ArrayPush(this.m_quiet, 0.0);
    ArrayPush(this.m_adapt, 0);
    return ArraySize(this.m_gang) - 1;
  }

  // One of theirs, put down this way. The weight is 1 for a body and less for somebody left breathing.
  public func Note(gang: CName, info: ref<CBKillInfo>, weight: Float) -> Void {
    let i = this.IndexOf(gang, true);
    if info.mFirearm { this.m_guns[i] += weight; }
    if info.mBlade || info.mBlunt || info.mFists || info.mFinisher { this.m_melee[i] += weight; }
    if info.mQuickhack { this.m_hacks[i] += weight; }
    if info.mExplosive { this.m_blast[i] += weight; }
    if info.stealth { this.m_quiet[i] += weight; }
  }

  // What dominates, or none: enough of it, and more than half of everything.
  public func Dominant(gang: CName) -> Int32 {
    let i = this.IndexOf(gang, false);
    if i < 0 {
      return CBAdaptNone();
    }
    let g = this.m_guns[i];
    let m = this.m_melee[i];
    let h = this.m_hacks[i];
    let b = this.m_blast[i];
    let q = this.m_quiet[i];
    let total = g + m + h + b;   // quiet rides alongside a method, so it is weighed against the kills it came with
    if total < CBConfig.AdaptMinWeight() {
      return CBAdaptNone();
    }
    let share = CBConfig.AdaptShare();
    if q >= total * share { return CBAdaptQuiet(); }
    if h >= total * share { return CBAdaptHacks(); }
    if b >= total * share { return CBAdaptBlast(); }
    if m >= total * share { return CBAdaptMelee(); }
    if g >= total * share { return CBAdaptGuns(); }
    return CBAdaptNone();
  }

  public func Prepared(gang: CName) -> Int32 {
    let i = this.IndexOf(gang, false);
    return i >= 0 ? this.m_adapt[i] : CBAdaptNone();
  }

  // Whether what they are prepared for has just changed, and to what. Kept, so it is said once.
  public func Settle(gang: CName) -> Int32 {
    let i = this.IndexOf(gang, false);
    if i < 0 {
      return -1;
    }
    let now = this.Dominant(gang);
    if now == this.m_adapt[i] {
      return -1;
    }
    this.m_adapt[i] = now;
    return now;
  }

  // A day's fading, from the slow tick.
  public func Fade(days: Float) -> Void {
    this.Trim();
    let keep = PowF(CBConfig.AdaptDailyKeep(), MaxF(days, 0.0));
    let i = 0;
    while i < ArraySize(this.m_gang) {
      this.m_guns[i] *= keep;
      this.m_melee[i] *= keep;
      this.m_hacks[i] *= keep;
      this.m_blast[i] *= keep;
      this.m_quiet[i] *= keep;
      i += 1;
    }
  }

  public func Gangs() -> array<CName> {
    this.Trim();
    return this.m_gang;
  }

  public func Clear() -> Void {
    ArrayClear(this.m_gang);
    ArrayClear(this.m_guns);
    ArrayClear(this.m_melee);
    ArrayClear(this.m_hacks);
    ArrayClear(this.m_blast);
    ArrayClear(this.m_quiet);
    ArrayClear(this.m_adapt);
    this.m_trimmed = true;
  }
}

// From CBApplyKill: how V put one of theirs down.
public func CBLedgerNote(sys: ref<CyberbaneSystem>, game: GameInstance, info: ref<CBKillInfo>) -> Void {
  if !CBGangsAdaptOn() || !IsDefined(info) || Equals(info.faction, n"") || !CBFactionFieldsSquads(info.faction) {
    return;
  }
  let book = CBLedgerBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  book.Note(info.faction, info, info.lethal ? 1.0 : CBConfig.AdaptLiveWeight());
  CBLedgerSettle(game, book, info.faction);
}

// From the slow tick: the ledger fades, and a gang V stopped fighting that way lets its guard down.
public func CBLedgerFade(game: GameInstance, days: Float) -> Void {
  let book = CBLedgerBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  book.Fade(days);
  for g in book.Gangs() {
    CBLedgerSettle(game, book, g);
  }
}

func CBLedgerSettle(game: GameInstance, book: ref<CBLedgerBook>, gang: CName) -> Void {
  let changed = book.Settle(gang);
  if changed <= 0 || !CBToastsOn() || !CBFactionOn(gang) {
    return;   // nothing new, or they have only let their guard down: no news in that
  }
  CBLog.Info(n"Model", s"\(NameToString(gang)) are preparing for how you fight (\(changed)).");
  CBGangAnswerLater(game, gang, CBAdaptLine(changed));
}

func CBAdaptLine(kind: Int32) -> String {
  if kind == CBAdaptGuns() {
    return CBLineOf([CBT(n"Cyberbane-Ledger-WeHeardHowYouShootOur"),
                     CBT(n"Cyberbane-Ledger-YouLikeYourGunsWeBought"),
                     CBT(n"Cyberbane-Ledger-EveryOneOfOursIsPlated")]);
  }
  if kind == CBAdaptMelee() {
    return CBLineOf([CBT(n"Cyberbane-Ledger-YouLikeItUpCloseWe"),
                     CBT(n"Cyberbane-Ledger-HeardYouFightWithYourHands"),
                     CBT(n"Cyberbane-Ledger-NextTimeYouGetCloseYou")]);
  }
  if kind == CBAdaptHacks() {
    return CBLineOf([CBT(n"Cyberbane-Ledger-OurPeopleAreRunningFreshICE"),
                     CBT(n"Cyberbane-Ledger-WePaidANetrunnerToLock"),
                     CBT(n"Cyberbane-Ledger-TheyReBringingICEForYou")]);
  }
  if kind == CBAdaptBlast() {
    return CBLineOf([CBT(n"Cyberbane-Ledger-YouAndYourGrenadesWeWear"),
                     CBT(n"Cyberbane-Ledger-BlowUsUpAgainSeeHow"),
                     CBT(n"Cyberbane-Ledger-WeLearnedFromEveryBlastCome")]);
  }
  return CBLineOf([CBT(n"Cyberbane-Ledger-SneakingWonTWorkTwiceEvery"),
                   CBT(n"Cyberbane-Ledger-YouLikeTheShadowsWeVe"),
                   CBT(n"Cyberbane-Ledger-NoMoreBodiesWithNobodySeeing")]);
}

// What their builds take from it. Fractions on the same terms the builds already use, bounded there.
public func CBAdaptArmour(game: GameInstance, gang: CName) -> Float {
  let book = CBGangsAdaptOn() ? CBLedgerBook.Get(game) : null;
  return IsDefined(book) && book.Prepared(gang) == CBAdaptGuns() ? CBConfig.AdaptArmour() : 0.0;
}

public func CBAdaptHealth(game: GameInstance, gang: CName) -> Float {
  let book = CBGangsAdaptOn() ? CBLedgerBook.Get(game) : null;
  if !IsDefined(book) {
    return 0.0;
  }
  let p = book.Prepared(gang);
  return p == CBAdaptMelee() || p == CBAdaptBlast() ? CBConfig.AdaptHealth() : 0.0;
}

public func CBAdaptIce(game: GameInstance, gang: CName) -> Float {
  let book = CBGangsAdaptOn() ? CBLedgerBook.Get(game) : null;
  return IsDefined(book) && book.Prepared(gang) == CBAdaptHacks() ? CBConfig.AdaptIce() : 0.0;
}

// The hunt's sense against V, for a gang prepared for a quiet V (Spawn/Hunt.reds).
public func CBAdaptSense(game: GameInstance, gang: CName) -> Float {
  let book = CBGangsAdaptOn() ? CBLedgerBook.Get(game) : null;
  return IsDefined(book) && NotEquals(gang, n"") && book.Prepared(gang) == CBAdaptQuiet() ? CBConfig.AdaptSense() : 1.0;
}
