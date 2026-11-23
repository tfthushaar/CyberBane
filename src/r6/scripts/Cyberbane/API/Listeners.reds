// Cyberbane - listening to Cyberbane's events (extension API level 1, 2.7.4)
//
// An add-on extends CBListener, overrides what it wants and registers it with CyberbaneAPI.RegisterListener, each
// session (from its own system's OnAttach or the player's attach). Every call is delivered on Cyberbane's own tick,
// never inside a game event: a death or a hit runs where the game calls it, so Cyberbane only writes it down there and
// tells listeners on the next tick. A listener that throws away nothing it is told breaks nothing: each call is
// independent, and a listener registered twice is told once.
//
// OnPlaythroughReset matters most: Start over (HardReset) restarts Rival ids at 0, so data an add-on keys by a Rival id
// would attach to the wrong Rival after it. The epoch counts resets on this playthrough and is kept in the save, so an
// add-on that stores it can compare on load (CyberbaneAPI.PlaythroughEpoch) even if it missed the call.

public abstract class CBListener extends IScriptable {
  // Somebody died. `faction` is Cyberbane's own id for them ("" when nobody's); `byV` is decided the way Cyberbane
  // decides it (the killing blow, CBLastHitWasOthers), not by who hit them first.
  public func OnNpcKilled(game: GameInstance, faction: CName, byV: Bool) -> Void {}
  // A Rival changed: kind is one of n"Made", n"Climbed", n"Escaped", n"Spared", n"KilledV", n"Slain".
  public func OnRivalEvent(game: GameInstance, rivalId: Int32, kind: CName) -> Void {}
  // A faction's posture towards V changed: the values of ECBPosture (Allied 0 ... Vendetta 4).
  public func OnPostureChanged(game: GameInstance, faction: CName, before: Int32, after: Int32) -> Void {}
  // The world has settled after a load, a fast travel or a scene: a safe moment to place people.
  public func OnSettled(game: GameInstance) -> Void {}
  // Start over: every Rival, standing and record of this playthrough is gone, and Rival ids start again.
  public func OnPlaythroughReset(game: GameInstance, epoch: Int32) -> Void {}
  // A playthrough Cyberbane had never seen began (or began again after Start over): the game's gamedataLifePath value.
  public func OnPlaythroughBorn(game: GameInstance, lifepath: Int32) -> Void {}
}

public func CBApiQKilled() -> Int32 = 1
public func CBApiQRival() -> Int32 = 2
public func CBApiQPosture() -> Int32 = 3
public func CBApiQSettled() -> Int32 = 4
public func CBApiQReset() -> Int32 = 5
public func CBApiQBorn() -> Int32 = 6

public class CBApiBook extends ScriptableSystem {
  // Resets on this playthrough. Its own book: a field added to an existing one would wipe that one's save data.
  private persistent let m_epoch: Int32;
  private let m_listeners: array<ref<CBListener>>;
  private let m_qKind: array<Int32>;
  private let m_qName: array<CName>;
  private let m_qA: array<Int32>;
  private let m_qB: array<Int32>;
  private let m_settled: Bool;

  public static func Get(game: GameInstance) -> ref<CBApiBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiBook") as CBApiBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    ArrayClear(this.m_qKind);
    ArrayClear(this.m_qName);
    ArrayClear(this.m_qA);
    ArrayClear(this.m_qB);
    this.m_settled = false;
  }

  public func Epoch() -> Int32 { return this.m_epoch; }
  public func BumpEpoch() -> Int32 {
    this.m_epoch += 1;
    return this.m_epoch;
  }

  public func Add(l: ref<CBListener>) -> Void {
    if IsDefined(l) && !ArrayContains(this.m_listeners, l) {
      ArrayPush(this.m_listeners, l);
    }
  }

  public func Remove(l: ref<CBListener>) -> Void {
    ArrayRemove(this.m_listeners, l);
  }

  public func HasListeners() -> Bool { return ArraySize(this.m_listeners) > 0; }

  public func Queue(kind: Int32, name: CName, a: Int32, b: Int32) -> Void {
    if ArraySize(this.m_listeners) == 0 {
      return;
    }
    ArrayPush(this.m_qKind, kind);
    ArrayPush(this.m_qName, name);
    ArrayPush(this.m_qA, a);
    ArrayPush(this.m_qB, b);
    // A queue nobody drains (the tick stopped) never grows without end.
    while ArraySize(this.m_qKind) > 256 {
      ArrayErase(this.m_qKind, 0);
      ArrayErase(this.m_qName, 0);
      ArrayErase(this.m_qA, 0);
      ArrayErase(this.m_qB, 0);
    }
  }

  // On Cyberbane's tick: everything written down since the last one, in order, to every listener.
  public func Drain(game: GameInstance) -> Void {
    let stable = CBWorldStable(game);
    if stable && !this.m_settled {
      this.Queue(CBApiQSettled(), n"", 0, 0);
    }
    this.m_settled = stable;
    let n = Min(Min(ArraySize(this.m_qKind), ArraySize(this.m_qName)), Min(ArraySize(this.m_qA), ArraySize(this.m_qB)));
    if n == 0 {
      return;
    }
    let kinds = this.m_qKind;
    let names = this.m_qName;
    let avals = this.m_qA;
    let bvals = this.m_qB;
    ArrayClear(this.m_qKind);
    ArrayClear(this.m_qName);
    ArrayClear(this.m_qA);
    ArrayClear(this.m_qB);
    let listeners = this.m_listeners;
    let i = 0;
    while i < n {
      for l in listeners {
        if IsDefined(l) {
          CBApiTell(game, l, kinds[i], names[i], avals[i], bvals[i]);
        }
      }
      i += 1;
    }
  }
}

func CBApiTell(game: GameInstance, l: ref<CBListener>, kind: Int32, name: CName, a: Int32, b: Int32) -> Void {
  if kind == CBApiQKilled() { l.OnNpcKilled(game, name, a != 0); return; }
  if kind == CBApiQRival() { l.OnRivalEvent(game, a, name); return; }
  if kind == CBApiQPosture() { l.OnPostureChanged(game, name, a, b); return; }
  if kind == CBApiQSettled() { l.OnSettled(game); return; }
  if kind == CBApiQReset() { l.OnPlaythroughReset(game, a); return; }
  if kind == CBApiQBorn() { l.OnPlaythroughBorn(game, a); }
}

// Written down where it happens; told on the next tick.
public func CBApiNote(kind: Int32, name: CName, a: Int32, b: Int32) -> Void {
  let book = CBApiBook.Get(GetGameInstance());
  if IsDefined(book) {
    book.Queue(kind, name, a, b);
  }
}

public func CBApiRivalEvent(r: ref<CBRival>, kind: CName) -> Void {
  if IsDefined(r) && r.id > 0 {
    CBApiNote(CBApiQRival(), kind, r.id, 0);
  }
}

// The API level this Cyberbane offers (API/ApiModule.reds says the same to compile-time guards).
public func CBApiLevel() -> Int32 = 1

public func CBApiListening(game: GameInstance) -> Bool {
  let book = CBApiBook.Get(game);
  return IsDefined(book) && book.HasListeners();
}

public func CBApiTick(game: GameInstance) -> Void {
  let book = CBApiBook.Get(game);
  if IsDefined(book) && book.HasListeners() {
    book.Drain(game);
  }
}
