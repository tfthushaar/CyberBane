// Cyberbane - Smasher Encounters
//
// Smasher Encounters (Nexus 26824) sends Adam Smasher after V now and then, with Arasaka cars behind him.

public class CBSmasherProbe {
  public let state: Int32;   // 0 not looked yet, 1 usable, 2 not installed or not the shape this reads
  public let ask: ref<ReflectionMemberFunc>;
  public let on: Bool;
  public let askedAt: Float;
  public let logged: Bool;
}

public func CBSmasherEncountersClass() -> CName = n"SmasherEncountersEventSystem"

// Is one of Smasher Encounters' fights on right now?
public func CBSmasherEventOn(game: GameInstance) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return false;
  }
  let probe = rt.GetSmasherProbe();
  if probe.state == 2 {
    return false;
  }
  let ts = GameInstance.GetTimeSystem(game);
  let now = IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
  // Fresh enough: the same answer for two seconds. The sim clock starts again with a session, so a stamp from the future
  // is an old session's, and asked again.
  if probe.state == 1 && probe.askedAt > 0.0 && now >= probe.askedAt && now - probe.askedAt < 2.0 {
    return probe.on;
  }
  if probe.state == 0 {
    probe.state = 2;
    let type = Reflection.GetClass(CBSmasherEncountersClass());
    if IsDefined(type) {
      probe.ask = CBReflectNoArgs(type.GetFunction(n"IsSmasherEventInProgress"), n"Bool");
      if IsDefined(probe.ask) {
        probe.state = 1;
        CBLog.Info(n"Core", "Smasher Encounters detected: while Smasher is out, Cyberbane sends nobody new, turns nobody on you at sight, and Arasaka holds its ground. Your crew still comes when called.");
      } else {
        CBLog.Info(n"Core", "Smasher Encounters is installed, but it has no IsSmasherEventInProgress that answers yes or no; Cyberbane cannot tell when Smasher is out.");
      }
    }
    if probe.state != 1 {
      return false;
    }
  }
  probe.askedAt = MaxF(now, 0.001);
  probe.on = false;
  let container = GameInstance.GetScriptableSystemsContainer(game);
  let system = IsDefined(container) ? container.Get(CBSmasherEncountersClass()) : null;
  if IsDefined(system) {
    let none: array<Variant>;
    probe.on = FromVariant<Bool>(probe.ask.Call(system, none));
  }
  return probe.on;
}

// Why arrivals are held, for the Hub's lane line.
public func CBSmasherHeldWhy() -> String = CBT(n"Cyberbane-SmasherEncounters-AdamSmasherIsAfterYou")
