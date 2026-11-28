// Cyberbane - Waiting for the hour
//
// Some things happen at a set hour: a Rival home after dark, a street event, a counterattack, a night's fight in the
// crew's war. V standing there early is told at once when, and can skip straight to it from the Hub's first page or
// with the Skip time key. The skip itself is the game's own: the same clock call and the same catch-up its Skip Time
// screen makes, and only when the game would allow its own.

public class CBSkipTimeBook extends ScriptableSystem {
  // Session only: the hour waited for, what for, and where V has to be for the offer to stand.
  public let at: Float;
  public let why: String;
  public let where: Vector4;
  public let reach: Float;
  public let source: CName;
  public let told: Bool;
  public let req: Bool;

  public static func Get(game: GameInstance) -> ref<CBSkipTimeBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBSkipTimeBook") as CBSkipTimeBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.Clear();
  }

  public func Clear() -> Void {
    this.at = 0.0;
    this.why = "";
    this.reach = 0.0;
    this.source = n"";
    this.told = false;
    this.req = false;
  }

  public func Open() -> Bool {
    return this.at > 0.0 && IsNameValid(this.source);
  }
}

// The key from Mod Settings, or none.
public func CBSkipTimeKey() -> EInputKey {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().skipTimeKey : EInputKey.IK_None;
}

// Something V came for happens at `at`, at `where` (reach 0: wherever V is). Said once; offered while it stands.
public func CBSkipTimeOffer(game: GameInstance, source: CName, at: Float, why: String, where: Vector4, reach: Float) -> Void {
  let book = CBSkipTimeBook.Get(game);
  let now = CBGameSeconds(game);
  if !IsDefined(book) || !IsNameValid(source) || at - now < CBConfig.SkipTimeMinWait() {
    return;
  }
  let same = book.Open() && Equals(book.source, source) && AbsF(book.at - at) < 60.0;
  book.at = at;
  book.why = why;
  book.where = where;
  book.reach = reach;
  book.source = source;
  if same && book.told {
    return;
  }
  book.told = true;
  CBLog.Info(n"Time", s"Offered a skip to \(CBClockWord(at)) for \(NameToString(source)).");
  if CBMessagesOn() {
    CBSystemNote(game, CBTf(n"Cyberbane-GangWar-SkipOffer", [why, CBClockWord(at), CBSkipTimeHow()]), 8.0);
  }
}

// How to skip, in the words of the note: the key when one is set, the Hub otherwise.
public func CBSkipTimeHow() -> String {
  let key = CBSkipTimeKey();
  if NotEquals(key, EInputKey.IK_None) {
    return CBTf(n"Cyberbane-GangWar-SkipHowKey", [CBKeyWord(key)]);
  }
  return CBT(n"Cyberbane-GangWar-SkipHowHub");
}

// The key's own name, as the game spells it ("IK_F7" reads "F7").
public func CBKeyWord(key: EInputKey) -> String {
  let name = NameToString(EnumValueToName(n"EInputKey", Cast<Int64>(EnumInt(key))));
  return StrBeginsWith(name, "IK_") ? StrMid(name, 3, StrLen(name) - 3) : name;
}

// Its owner takes it down: the Rival placed, the event over, the fight begun.
public func CBSkipTimeWithdraw(game: GameInstance, source: CName) -> Void {
  let book = CBSkipTimeBook.Get(game);
  if IsDefined(book) && book.Open() && Equals(book.source, source) {
    book.Clear();
  }
}

// Is there something to skip to right now, with V where it wants V? For the Hub's button and the key.
public func CBSkipTimeStands(game: GameInstance) -> Bool {
  let book = CBSkipTimeBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(book) || !book.Open() || !IsDefined(player) {
    return false;
  }
  if book.at - CBGameSeconds(game) < CBConfig.SkipTimeMinWait() {
    return false;
  }
  return book.reach <= 0.0 || Vector4.Distance(player.GetWorldPosition(), book.where) <= book.reach * 1.5;
}

// "Skip to 21:00" for the Hub, and what it is for; "" when nothing stands.
public func CBSkipTimeLabel(game: GameInstance) -> String {
  let book = CBSkipTimeBook.Get(game);
  return CBSkipTimeStands(game) ? CBTf(n"Cyberbane-GangWar-SkipButton", [CBClockWord(book.at)]) : "";
}

public func CBSkipTimeWhy(game: GameInstance) -> String {
  let book = CBSkipTimeBook.Get(game);
  return CBSkipTimeStands(game) ? book.why : "";
}

// Asked from the Hub (a menu) or the key: carried out on the next settled tick.
public func CBSkipTimeAsk(game: GameInstance) -> Void {
  let book = CBSkipTimeBook.Get(game);
  if IsDefined(book) && CBSkipTimeStands(game) {
    book.req = true;
  }
}

public func CBSkipTimeKeyInput(game: GameInstance, evt: ref<KeyInputEvent>) -> Void {
  if !IsDefined(evt) || NotEquals(evt.GetAction(), EInputAction.IACT_Release) {
    return;
  }
  let key = CBSkipTimeKey();
  if Equals(key, EInputKey.IK_None) || NotEquals(evt.GetKey(), key) {
    return;
  }
  let bbs = GameInstance.GetBlackboardSystem(game);
  let ui = IsDefined(bbs) ? bbs.Get(GetAllBlackboardDefs().UI_System) : null;
  if !IsDefined(ui) || ui.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) {
    return;
  }
  CBSkipTimeAsk(game);
}

// Every settled tick: an offer V walked away from, or whose hour has come, is taken down; a skip asked for is made.
public func CBSkipTimeTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBSkipTimeBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(book) || !book.Open() || !IsDefined(player) {
    return;
  }
  let now = CBGameSeconds(game);
  let gone = book.reach > 0.0 && Vector4.Distance(player.GetWorldPosition(), book.where) > book.reach * 2.0;
  if now >= book.at || gone {
    book.Clear();
    return;
  }
  if !book.req || !CBWorldStable(game) {
    return;
  }
  book.req = false;
  let why = CBSkipTimeNow(game, book.at - CBConfig.SkipTimeLead());
  if StrLen(why) > 0 {
    CBSystemNote(game, why, 5.0);
  }
}

// Skip the clock forward to `target`, as the game's Skip Time screen does. "" when done, otherwise why not.
public func CBSkipTimeNow(game: GameInstance, target: Float) -> String {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return CBT(n"Cyberbane-GangWar-SkipNotNow");
  }
  if !GameTimeUtils.CanPlayerTimeSkip(player) {
    return CBT(n"Cyberbane-GangWar-SkipNotNow");
  }
  let minutes = Cast<Int32>((target - CBGameSeconds(game)) / 60.0);
  if minutes < 1 {
    return "";
  }
  let t = ts.GetGameTime();
  let total = GameTime.Hours(t) * 60 + GameTime.Minutes(t) + minutes;
  CBLog.Info(n"Time", s"Skipping \(minutes) game minutes, to \(CBClockWord(target)).");
  ts.SetGameTimeByHMS(total / 60, total % 60, GameTime.Seconds(t), n"ui_menu_timeskip");
  GameTimeUtils.FastForwardPlayerState(player);
  return "";
}

// The next time the clock reads `hour`:00, in game seconds.
public func CBNextHourAt(game: GameInstance, hour: Float) -> Float {
  let now = CBGameSeconds(game);
  let hourNow = CBGameHourOfDay(game);
  let ahead = hour - hourNow;
  if ahead <= 0.0 {
    ahead += 24.0;
  }
  return CBQuarterUp(now + ahead * CBConfig.SecondsPerHour());
}
