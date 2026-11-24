// Cyberbane - Fenix Rebirth (2.7.6)
//
// Fenix Rebirth (Nexus 28954) takes the reload out of dying: V gets back up somewhere else, hours later. It does it inside
// the damage. Its wrap on StatPoolsManager.ApplyDamage catches the hit that would kill V, never hands it on to the game,
// and starts its own sequence (read in its 1.5.3 scripts, FenixRebirth_0_Systems.reds). So the game never kills V: no
// death event reaches V, the state machine never says Dead, and Cyberbane, which knew of a death only from
// PlayerPuppet.OnDeath, never knew V had died. The killer was never made a Rival, the death never counted, and a few
// seconds after V was moved the hunt read V's being gone as V running from the fight ("Ran, did you?").
//
// Its runtime system counts the rebirths (GetRebirthId, one more the moment it catches the hit) and says while one is under
// way (IsRebirthPending, until V has arrived and can see again). Read here once a tick, before the world gate, through
// Codeware's reflection, so nothing in this build names anything of theirs: 1.4.6 removed a bridge that wrapped one of its
// events behind ModuleExists, and a Fenix version without that event failed every script mod's compile on the install.
// If those two functions are not there in that shape, its death count is read instead (the quest fact fenix_death_count,
// written once V has been moved), which says that a rebirth happened but not while one is going on.
//
// A new rebirth goes down the one path every death of V's takes (CBOnPlayerDeath): the Death Ledger, the count and V's
// file, the killer made a Rival or promoted, their gang's text. While one is under way V is down (CBVDown), so nothing
// works the world between the fall and the arrival, as nothing does between a death and a load. And the fight V fell in
// ends where V fell, on the first settled tick afterwards (CBFightEndsWithVDown), never as V getting away.

public class CBFenixProbe {
  public let state: Int32;   // 0 not looked yet, 1 both functions read, 2 not installed, 3 installed, death count only
  public let rebirthId: ref<ReflectionMemberFunc>;
  public let pending: ref<ReflectionMemberFunc>;
  public let captured: ref<ReflectionMemberFunc>;   // PlayerPuppet.FenixCaptureIsActive, its own method on V
}

public func CBFenixRuntimeClass() -> CName = n"FenixRebirthRuntime"

public func CBFenixDeathFact() -> CName = n"fenix_death_count"

// A death alternative is bringing V back right now: Fenix Rebirth between catching the hit and V's arrival. Written by
// CBFenixTick, read by CBVDown. A field of the player's, so a load (a new player) starts it false.
@addField(PlayerPuppet)
public let cbRebirthPending: Bool;

// Fenix Rebirth woke V up captured (its Scav capture: a room, guards, a way out). Written by CBFenixTick; nobody new is sent
// while it lasts (CBArrivalsHeldBase), or V would be fighting their way out of Fenix's den with Cyberbane's crews arriving.
@addField(PlayerPuppet)
public let cbFenixCaptured: Bool;

public func CBFenixCaptured(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  return IsDefined(player) && player.cbFenixCaptured;
}

// Is Fenix Rebirth installed? Looked up once a game launch. Chippin' In stands aside for it (Reactions/ChippinIn.reds).
public func CBFenixInstalled() -> Bool {
  let probe = CBFenixLook();
  return IsDefined(probe) && (probe.state == 1 || probe.state == 3);
}

func CBFenixLook() -> ref<CBFenixProbe> {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return null;
  }
  let probe = rt.GetFenixProbe();
  if probe.state != 0 {
    return probe;
  }
  probe.state = 2;
  let type = Reflection.GetClass(CBFenixRuntimeClass());
  if !IsDefined(type) {
    return probe;
  }
  probe.rebirthId = CBReflectNoArgs(type.GetFunction(n"GetRebirthId"), n"Int32");
  probe.pending = CBReflectNoArgs(type.GetFunction(n"IsRebirthPending"), n"Bool");
  let playerType = Reflection.GetClass(n"PlayerPuppet");
  if IsDefined(playerType) {
    probe.captured = CBReflectNoArgs(playerType.GetFunction(n"FenixCaptureIsActive"), n"Bool");
  }
  if IsDefined(probe.rebirthId) && IsDefined(probe.pending) {
    probe.state = 1;
    CBLog.Info(n"Core", "Fenix Rebirth detected: a rebirth counts as V's death (the killer becomes a Rival, the fight ends where V fell), and nothing happens while V is being brought back.");
  } else {
    probe.state = 3;
    CBLog.Info(n"Core", "Fenix Rebirth is installed, but its runtime does not answer the way Cyberbane reads it; its death count is read instead, so a rebirth is noticed once V has been moved.");
  }
  return probe;
}

// Once a fast tick, before the world gate (Core/CyberbaneSystem.reds, OnFastTick).
public func CBFenixTick(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(player) {
    return;
  }
  let probe = CBFenixLook();
  if !IsDefined(probe) || (probe.state != 1 && probe.state != 3) {
    return;
  }
  let count = -1;
  let pending = false;
  if probe.state == 1 {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    let system = IsDefined(container) ? container.Get(CBFenixRuntimeClass()) : null;
    if IsDefined(system) {
      let none: array<Variant>;
      count = FromVariant<Int32>(probe.rebirthId.Call(system, none));
      pending = FromVariant<Bool>(probe.pending.Call(system, none));
    }
  } else {
    let qs = GameInstance.GetQuestsSystem(game);
    if IsDefined(qs) {
      count = qs.GetFact(CBFenixDeathFact());
    }
  }
  player.cbRebirthPending = pending;
  let captured = false;
  if IsDefined(probe.captured) {
    let noArgs: array<Variant>;
    captured = FromVariant<Bool>(probe.captured.Call(player, noArgs));
  }
  if NotEquals(captured, player.cbFenixCaptured) {
    CBLog.Info(n"Core", captured ? "Fenix Rebirth woke V captured: nobody new is sent until V is out."
                                 : "V is out of Fenix Rebirth's capture.");
  }
  player.cbFenixCaptured = captured;
  if count < 0 {
    return;
  }
  // Its runtime counts from zero every session, as this system does, so the first look compares against zero. The death
  // count is saved with the game, so its first look only takes the count as it stands. A count below the last one read
  // is a new session's.
  if !sys.DeathAltRead() {
    sys.SetDeathAltSeen(probe.state == 1 ? 0 : count);
  }
  if count < sys.DeathAltSeen() {
    sys.SetDeathAltSeen(count);
    return;
  }
  if count == sys.DeathAltSeen() {
    return;
  }
  sys.SetDeathAltSeen(count);
  CBLog.Info(n"Signals", "Fenix Rebirth caught a hit that would have killed V: counted as V's death.");
  CBOnPlayerDeath(player);
  sys.NoteVFell();
}
