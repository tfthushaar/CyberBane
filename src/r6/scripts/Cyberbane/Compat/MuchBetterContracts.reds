// Cyberbane - Much Better Contracts (Repeatable Gigs, the Wire), detected on its own (2.7.5)
//
// "How well does it run next to Repeatable Gigs (Much Better Contracts)?" Read side by side (its 2.4.8): it adds no
// method of its own over the game's that Cyberbane also hooks (every one of its 46 hooks is a wrap that calls through),
// it replays a gig as a journal quest of its own with tracked objectives, and the game's own spawners put that gig's
// people back. So Cyberbane already treats a contract's site as a job: nobody it sends comes for V there, and its people
// at the site are left alone, as at any gig. A base learned from a gig is one base to a place, however often the gig is
// played again (Rivals/Strongholds.reds).
//
// What it does that Cyberbane could not see on its own:
// - A contract runs on after V leaves its site, and three of them send their own pursuit after V (its FactionResponses).
//   Detected, a fight while one of its contracts is running is the contract's, and nobody new of Cyberbane's is sent
//   into it (CBArrivalsHeldBase).
// - It pays a contract straight into V's pockets, not through the game's reward grant, so the payout Cyberbane measures
//   to know a job was done (Economy/GigBonus.reds) never saw one. Detected, each contract its board counts as completed
//   is a finished job to Cyberbane, as a gig is: Renown, and the professional's name. Its own pay is left as it set it:
//   no gig bonus on top.
//
// Both read by reflection, from its board's public HasAssignment and Completed, so a later Much Better Contracts that
// renames either turns that rule off and says so in the log, never stops the scripts compiling.

public class CBMbcProbe {
  public let state: Int32;   // 0 not looked yet, 1 usable, 2 not installed or not the shape this reads
  public let ask: ref<ReflectionMemberFunc>;
  public let done: ref<ReflectionMemberFunc>;
  public let on: Bool;
  public let askedAt: Float;
}

// What this session has seen of its completed count. A system, so a load starts it over: the runtime keeps its probe
// across loads, and a count carried from one save to another would credit the difference as jobs.
public class CBMbcWatch extends ScriptableSystem {
  public let seen: Int32;
  public let known: Bool;

  public static func Get(game: GameInstance) -> ref<CBMbcWatch> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBMbcWatch") as CBMbcWatch : null;
  }
}

public func CBMbcClass() -> CName = n"MuchBetterContracts.Board.BoardSystem"

// Looked for once a game: its board, and the two questions this asks of it.
func CBMbcResolve() -> ref<CBMbcProbe> {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return null;
  }
  let probe = rt.GetMbcProbe();
  if probe.state != 0 {
    return probe;
  }
  probe.state = 2;
  let type = Reflection.GetClass(CBMbcClass());
  if !IsDefined(type) {
    return probe;
  }
  probe.ask = CBReflectNoArgs(type.GetFunction(n"HasAssignment"), n"Bool");
  probe.done = CBReflectNoArgs(type.GetFunction(n"Completed"), n"Int32");
  if IsDefined(probe.ask) || IsDefined(probe.done) {
    probe.state = 1;
  }
  CBLog.Info(n"Core", "Much Better Contracts detected: its contract sites are jobs to Cyberbane"
    + (IsDefined(probe.ask) ? "; while a contract runs, a fight is the contract's and nobody of Cyberbane's is sent into it" : "; its board's HasAssignment could not be read, so fights during a contract are not held")
    + (IsDefined(probe.done) ? "; each contract it completes is a finished job." : "; its board's Completed could not be read, so its contracts earn no Renown here."));
  return probe;
}

func CBMbcBoard(game: GameInstance) -> ref<IScriptable> {
  let container = GameInstance.GetScriptableSystemsContainer(game);
  return IsDefined(container) ? container.Get(CBMbcClass()) : null;
}

// One of its contracts (or operations) is running and has not failed or finished.
public func CBMbcContractRunning(game: GameInstance) -> Bool {
  let probe = CBMbcResolve();
  if !IsDefined(probe) || probe.state != 1 || !IsDefined(probe.ask) {
    return false;
  }
  let ts = GameInstance.GetTimeSystem(game);
  let now = IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
  if probe.askedAt > 0.0 && now >= probe.askedAt && now - probe.askedAt < 2.0 {
    return probe.on;
  }
  probe.askedAt = MaxF(now, 0.001);
  probe.on = false;
  let board = CBMbcBoard(game);
  if IsDefined(board) {
    let none: array<Variant>;
    probe.on = FromVariant<Bool>(probe.ask.Call(board, none));
  }
  return probe.on;
}

// A fight that belongs to one of its contracts: one running, and V fighting.
public func CBMbcContractFight(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  return IsDefined(player) && player.IsInCombat() && CBMbcContractRunning(game);
}

// Every few ticks: contracts its board has completed since the last look are finished jobs (CBApplyGig, as a measured gig
// payout is). The first look of a session only learns the count.
public func CBMbcTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || sys.GetTickCount() % 5 != 3 {
    return;
  }
  let probe = CBMbcResolve();
  let watch = CBMbcWatch.Get(game);
  if !IsDefined(probe) || probe.state != 1 || !IsDefined(probe.done) || !IsDefined(watch) {
    return;
  }
  let board = CBMbcBoard(game);
  if !IsDefined(board) {
    return;
  }
  let none: array<Variant>;
  let count = FromVariant<Int32>(probe.done.Call(board, none));
  if !watch.known || count < watch.seen {
    watch.seen = count;
    watch.known = true;
    return;
  }
  let fresh = Min(count - watch.seen, CBConfig.MbcJobsPerLook());
  watch.seen = count;
  if fresh <= 0 {
    return;
  }
  let k = 0;
  while k < fresh {
    CBApplyGig(sys, game);
    k += 1;
  }
  CBEvaluateTitles(sys, game);
  CBLog.Info(n"Core", s"Much Better Contracts completed \(fresh) contract(s): counted as finished jobs.");
}
