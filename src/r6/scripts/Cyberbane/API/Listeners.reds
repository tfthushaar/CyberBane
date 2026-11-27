// Cyberbane - listening to Cyberbane's events (extension API level 1)
//
// An add-on extends CBListener, overrides what it wants and registers it with CyberbaneAPI.RegisterListener, each
// session (from its own system's OnAttach or the player's attach).

public abstract class CBListener extends IScriptable {
  // Somebody died. `faction` is Cyberbane's own id for them ("" when nobody's); `byV` is decided the way Cyberbane
  // decides it (the killing blow, CBLastHitWasOthers), not by who hit them first.
  public func OnNpcKilled(game: GameInstance, faction: CName, byV: Bool) -> Void {}
  // A Rival changed: kind is one of n"Made", n"Climbed", n"Escaped", n"Spared", n"KilledV", n"Slain".
  public func OnRivalEvent(game: GameInstance, rivalId: Int32, kind: CName) -> Void {}
  // A faction's posture towards V changed: the values of ECBPosture (Allied 0... Vendetta 4).
  public func OnPostureChanged(game: GameInstance, faction: CName, before: Int32, after: Int32) -> Void {}
  // The world has settled after a load, a fast travel or a scene: a safe moment to place people.
  public func OnSettled(game: GameInstance) -> Void {}
  // Start over: every Rival, standing and record of this playthrough is gone, and Rival ids start again.
  public func OnPlaythroughReset(game: GameInstance, epoch: Int32) -> Void {}
  // A playthrough Cyberbane had never seen began (or began again after Start over): the game's gamedataLifePath value.
  public func OnPlaythroughBorn(game: GameInstance, lifepath: Int32) -> Void {}
  // API level 2: every couple of seconds on Cyberbane's settled tick, for an add-on's own clocks. Never during a load,
  // a scene, a menu or the settle after a fast travel; CyberbaneAPI.WorldStable answers the same question.
  public func OnTick(game: GameInstance) -> Void {}
  // API level 3: a signal from Cyberbane or another add-on (CyberbaneAPI.Emit). Names carry the sender's prefix
  // ("Cyberbane/RivalSlain", "Madmax/ConvoyBroken", "Corpo/Tier").
  public func OnSignal(game: GameInstance, name: CName, faction: CName, value: Int32) -> Void {}
  // API level 3: told alongside OnNpcKilled, with who it was: their record, and their rarity as gamedataNPCRarity.
  public func OnNpcKilledBy(game: GameInstance, faction: CName, byV: Bool, record: TweakDBID, rarity: Int32) -> Void {}
  // API level 3: a standing change an add-on made through AdjustStanding, with the reason key it gave.
  public func OnStandingAdjusted(game: GameInstance, faction: CName, delta: Float, reasonKey: CName) -> Void {}
}

public func CBApiQKilled() -> Int32 = 1
public func CBApiQRival() -> Int32 = 2
public func CBApiQPosture() -> Int32 = 3
public func CBApiQSettled() -> Int32 = 4
public func CBApiQReset() -> Int32 = 5
public func CBApiQBorn() -> Int32 = 6
public func CBApiQSignal() -> Int32 = 7
public func CBApiQKilledBy() -> Int32 = 8
public func CBApiQStanding() -> Int32 = 9

public class CBApiBook extends ScriptableSystem {
  // Resets on this playthrough. Its own book: a field added to an existing one would wipe that one's save data.
  private persistent let m_epoch: Int32;
  private let m_listeners: array<ref<CBListener>>;
  private let m_qKind: array<Int32>;
  private let m_qName: array<CName>;
  private let m_qA: array<Int32>;
  private let m_qB: array<Int32>;
  private let m_qName2: array<CName>;
  private let m_qF: array<Float>;
  private let m_qRec: array<TweakDBID>;
  private let m_settled: Bool;
  private let m_ticks: Int32;

  public static func Get(game: GameInstance) -> ref<CBApiBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiBook") as CBApiBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    ArrayClear(this.m_qKind);
    ArrayClear(this.m_qName);
    ArrayClear(this.m_qA);
    ArrayClear(this.m_qB);
    ArrayClear(this.m_qName2);
    ArrayClear(this.m_qF);
    ArrayClear(this.m_qRec);
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

  // The tick stood down (a load, a scene, a menu, the settle after a fast travel): the next settled tick says so again.
  // Drain runs only on a settled tick, so it could never see the world go: OnSettled came after a load and never after
  // a scene or a fast travel.
  public func Unsettle() -> Void { this.m_settled = false; }

  public func Queue(kind: Int32, name: CName, a: Int32, b: Int32, opt name2: CName, opt f: Float, opt rec: TweakDBID) -> Void {
    if ArraySize(this.m_listeners) == 0 {
      return;
    }
    ArrayPush(this.m_qKind, kind);
    ArrayPush(this.m_qName, name);
    ArrayPush(this.m_qA, a);
    ArrayPush(this.m_qB, b);
    ArrayPush(this.m_qName2, name2);
    ArrayPush(this.m_qF, f);
    ArrayPush(this.m_qRec, rec);
    // A queue nobody drains (the tick stopped) never grows without end.
    while ArraySize(this.m_qKind) > 256 {
      ArrayErase(this.m_qKind, 0);
      ArrayErase(this.m_qName, 0);
      ArrayErase(this.m_qA, 0);
      ArrayErase(this.m_qB, 0);
      ArrayErase(this.m_qName2, 0);
      ArrayErase(this.m_qF, 0);
      ArrayErase(this.m_qRec, 0);
    }
  }

  // On Cyberbane's tick: everything written down since the last one, in order, to every listener.
  public func Drain(game: GameInstance) -> Void {
    let stable = CBWorldStable(game);
    if stable && !this.m_settled {
      this.Queue(CBApiQSettled(), n"", 0, 0);
    }
    this.m_settled = stable;
    let n = Min(Min(Min(ArraySize(this.m_qKind), ArraySize(this.m_qName)), Min(ArraySize(this.m_qA), ArraySize(this.m_qB))),
                Min(Min(ArraySize(this.m_qName2), ArraySize(this.m_qF)), ArraySize(this.m_qRec)));
    if n > 0 {
      this.Tell(game, n);
    }
    // OnTick: its own count, so it keeps its pace whatever else was told.
    this.m_ticks += 1;
    if stable && this.m_ticks % CBConfig.ApiListenerTickEvery() == 0 {
      let ticking = this.m_listeners;
      for l in ticking {
        if IsDefined(l) {
          l.OnTick(game);
        }
      }
    }
  }

  private func Tell(game: GameInstance, n: Int32) -> Void {
    let kinds = this.m_qKind;
    let names = this.m_qName;
    let avals = this.m_qA;
    let bvals = this.m_qB;
    let names2 = this.m_qName2;
    let fvals = this.m_qF;
    let recs = this.m_qRec;
    ArrayClear(this.m_qKind);
    ArrayClear(this.m_qName);
    ArrayClear(this.m_qA);
    ArrayClear(this.m_qB);
    ArrayClear(this.m_qName2);
    ArrayClear(this.m_qF);
    ArrayClear(this.m_qRec);
    let listeners = this.m_listeners;
    let i = 0;
    while i < n {
      for l in listeners {
        if IsDefined(l) {
          CBApiTell(game, l, kinds[i], names[i], avals[i], bvals[i], names2[i], fvals[i], recs[i]);
        }
      }
      i += 1;
    }
  }
}

func CBApiTell(game: GameInstance, l: ref<CBListener>, kind: Int32, name: CName, a: Int32, b: Int32, name2: CName, f: Float,
               rec: TweakDBID) -> Void {
  if kind == CBApiQSignal() { l.OnSignal(game, name, name2, a); return; }
  if kind == CBApiQKilledBy() { l.OnNpcKilledBy(game, name, a != 0, rec, b); return; }
  if kind == CBApiQStanding() { l.OnStandingAdjusted(game, name, f, name2); return; }
  if kind == CBApiQKilled() { l.OnNpcKilled(game, name, a != 0); return; }
  if kind == CBApiQRival() { l.OnRivalEvent(game, a, name); return; }
  if kind == CBApiQPosture() { l.OnPostureChanged(game, name, a, b); return; }
  if kind == CBApiQSettled() { l.OnSettled(game); return; }
  if kind == CBApiQReset() { l.OnPlaythroughReset(game, a); return; }
  if kind == CBApiQBorn() { l.OnPlaythroughBorn(game, a); }
}

// Written down where it happens; told on the next tick.
public func CBApiNote(kind: Int32, name: CName, a: Int32, b: Int32, opt name2: CName, opt f: Float, opt rec: TweakDBID) -> Void {
  let book = CBApiBook.Get(GetGameInstance());
  if IsDefined(book) {
    book.Queue(kind, name, a, b, name2, f, rec);
  }
}

public func CBApiRivalEvent(r: ref<CBRival>, kind: CName) -> Void {
  if IsDefined(r) && r.id > 0 {
    CBApiNote(CBApiQRival(), kind, r.id, 0);
    // Every moment of a Rival's comes through here, so their timeline is written here too (Rivals/RivalTimeline.reds).
    CBRivalTimelineEvent(r, kind);
  }
}

// The API level this Cyberbane offers (API/ApiModule.reds, Api2Module.reds and Api3Module.reds say the same to
// compile-time guards).
public func CBApiLevel() -> Int32 = 4

public func CBApiListening(game: GameInstance) -> Bool {
  let book = CBApiBook.Get(game);
  return IsDefined(book) && book.HasListeners();
}

// The tick stood down this time round (Core/CyberbaneSystem.reds, OnFastTick): no native read, a flag on the book.
public func CBApiWorldBusy(game: GameInstance) -> Void {
  let book = CBApiBook.Get(game);
  if IsDefined(book) {
    book.Unsettle();
  }
}

public func CBApiTick(game: GameInstance) -> Void {
  let book = CBApiBook.Get(game);
  if IsDefined(book) && book.HasListeners() {
    book.Drain(game);
  }
}
