// Cyberbane - event kinds an add-on registers (extension API level 1)
//
// Cyberbane's gang life (Spawn/StreetEvents.reds) already does the hard parts of an event: a time to the minute and a
// pin, the note when V comes early, holding while the story, a scene or a job has the place, placement only once V is
// near and its time has come, one event at a time, and removal the safe way. A registered kind gets all of it.

public abstract class CBEventKindHandler extends IScriptable {
  // The text that announces it, or "" for none. ev.at is the place, ev.from when it starts (CBClockWord for the time).
  public func Announce(game: GameInstance, ev: ref<CBStreetEvent>) -> String { return ""; }
  // V is near and its time has come: put its people there, and hand back the group (RequestGroup); 0 to try again later.
  public func Place(game: GameInstance, ev: ref<CBStreetEvent>) -> Int32 { return 0; }
  // Each tick once its people are there: true when its business is done (V crashed it, or it finished).
  public func Watch(game: GameInstance, ev: ref<CBStreetEvent>, handle: Int32) -> Bool { return false; }
  // It is over: `placed` false when V never came. Its people are released by the engine straight after.
  public func Ended(game: GameInstance, ev: ref<CBStreetEvent>, placed: Bool) -> Void {}
}

public class CBApiEventKinds extends ScriptableSystem {
  private let m_kinds: array<CName>;
  private let m_handlers: array<ref<CBEventKindHandler>>;
  private let m_captions: array<CName>;
  private let m_on: array<Bool>;

  public static func Get(game: GameInstance) -> ref<CBApiEventKinds> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiEventKinds") as CBApiEventKinds : null;
  }

  private func IndexOf(kind: CName) -> Int32 {
    let i = ArrayFindFirst(this.m_kinds, kind);
    return i >= 0 && i < ArraySize(this.m_handlers) && i < ArraySize(this.m_captions) && i < ArraySize(this.m_on) ? i : -1;
  }

  public func Register(kind: CName, handler: ref<CBEventKindHandler>, captionKey: CName) -> Bool {
    if !IsNameValid(kind) || !IsDefined(handler) || CBEventKindIsOwn(kind) {
      return false;
    }
    let i = this.IndexOf(kind);
    if i >= 0 {
      this.m_handlers[i] = handler;
      this.m_captions[i] = captionKey;
      return true;
    }
    ArrayPush(this.m_kinds, kind);
    ArrayPush(this.m_handlers, handler);
    ArrayPush(this.m_captions, captionKey);
    ArrayPush(this.m_on, true);
    return true;
  }

  public func Handler(kind: CName) -> ref<CBEventKindHandler> {
    let i = this.IndexOf(kind);
    return i >= 0 ? this.m_handlers[i] : null;
  }

  public func Caption(kind: CName) -> CName {
    let i = this.IndexOf(kind);
    return i >= 0 ? this.m_captions[i] : n"";
  }

  public func IsOn(kind: CName) -> Bool {
    let i = this.IndexOf(kind);
    return i >= 0 && this.m_on[i];
  }

  public func SetOn(kind: CName, on: Bool) -> Void {
    let i = this.IndexOf(kind);
    if i >= 0 {
      this.m_on[i] = on;
    }
  }
}

// One of Cyberbane's own kinds, which an add-on can never take over.
public func CBEventKindIsOwn(kind: CName) -> Bool {
  return StrBeginsWith(NameToString(kind), "Cyberbane") || Equals(kind, CBEvSitDown()) || Equals(kind, CBEvAmbush())
      || Equals(kind, CBEvFuneral()) || Equals(kind, CBEvCelebration()) || Equals(kind, CBEvInitiation())
      || Equals(kind, CBEvRecruitment()) || Equals(kind, CBEvArmsDeal()) || Equals(kind, CBEvExecution())
      || Equals(kind, CBEvFrontLine()) || Equals(kind, CBEvRacket()) || Equals(kind, CBEvFugitive());   // every kind of
      // Spawn/StreetEvents.reds (2.7.9): Racket and Fugitive were missing, so an add-on could register over them
}

public func CBApiEventHandler(game: GameInstance, kind: CName) -> ref<CBEventKindHandler> {
  let reg = CBApiEventKinds.Get(game);
  return IsDefined(reg) ? reg.Handler(kind) : null;
}

public func CBApiEventCaption(game: GameInstance, kind: CName) -> String {
  let reg = CBApiEventKinds.Get(game);
  let key = IsDefined(reg) ? reg.Caption(kind) : n"";
  return IsNameValid(key) ? CBT(key) : "";
}

public func CBApiEventOn(game: GameInstance, kind: CName) -> Bool {
  let reg = CBApiEventKinds.Get(game);
  return IsDefined(reg) && reg.IsOn(kind);
}

// Starting one: the one event slot must be free, the kind registered and on, and Cyberbane on. Announced by the
// add-on's own contact when it names one registered with RegisterSender, else by whoever works V's district.
public func CBApiStartEvent(game: GameInstance, kind: CName, side: CName, at: Vector4, inGameSeconds: Float, opt sender: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let life = CBStreetLifeFor(game);
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(sys) || !IsDefined(life) || !IsDefined(rt) || !rt.IsEnabled() || !IsDefined(CBApiEventHandler(game, kind))
     || !CBApiEventOn(game, kind) {
    return false;
  }
  return life.Events().StartApi(sys, game, kind, side, at, inGameSeconds, sender);
}
