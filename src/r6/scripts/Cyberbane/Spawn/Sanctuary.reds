// Cyberbane - Nobody follows V through their own front door
//
// While V is somewhere the game protects, nobody is given a move order or handed V as a target, and anyone already
// fighting V stops at the door.

// Is V somewhere the people after them must not follow? Worked out once a tick (CyberbaneSystem).
public func CBComputeSanctuary(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) || CBAllowSafeZoneSpawns() {
    return false;
  }
  if sys.IsInSafeZone() {
    return true;
  }
  return CBPlayerZone(game) == EnumInt(gamePSMZones.Safe) && CBPlayerCannotFight(game);
}

// Somewhere nobody of ours is sent to look, wherever V is standing.
public func CBPointIsSafeArea(game: GameInstance, at: Vector4) -> Bool {
  if CBAllowSafeZoneSpawns() {
    return false;
  }
  let sam = GameInstance.GetSafeAreaManager(game);
  return IsDefined(sam) && sam.IsPointInSafeArea(at);
}

// Take V off this person's list. What the police do when they stand down, without any of the police:
// the second call is what stops them going to look where they last knew V was, which here is the
// other side of the door.
func CBForgetV(npc: ref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(npc) || !IsDefined(player) || !npc.IsAttached() {
    return;
  }
  let tracker = npc.GetTargetTrackerComponent();
  if !IsDefined(tracker) {
    return;
  }
  CBTrace("combat: one of ours has lost V to a safe area");
  tracker.RemoveThreat(tracker.MapThreat(player));
  tracker.ResetRecentlyDroppedThreat();
}

// Once a tick while V is safe, for everybody of ours. Also while V is on a job (Spawn/Hunt.reds), more gently: `onJob`.
public func CBSanctuaryHold(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                            player: ref<PlayerPuppet>, opt onJob: Bool) -> Void {
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Rival", onJob);
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Apex", onJob);
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Squad", onJob);
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Escort", onJob);
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Scout", onJob);
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Orphan", onJob);
}

// `fightersOnly` is for the street's own people (CBStreetLife.Tick): nobody sent them after V, so a bagman walking his
// round is left to walk it, and only somebody already fighting V is held.
func CBSanctuaryHoldTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                        player: ref<PlayerPuppet>, tag: CName, onJob: Bool, opt fightersOnly: Bool) -> Void {
  let ppos = player.GetWorldPosition();
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    // Somebody still in a car is the car's, and it lets them out when it stops (CBOrderPursue then gives them nothing
    // to do).
    if CBStillStanding(p) && CBNpcSafe(sys, p) && !p.cbMoraleBroken && (!fightersOnly || CBNpcInCombat(p))
       && !VehicleComponent.IsMountedToVehicle(game, p.GetEntityID()) {
      CBCancelMove(p);
      p.cbSearchGen = 0;
      // Somebody who can still see V has not lost V: a fight in a doorway goes on being a fight.
      if CBNpcInCombat(p) && !CBWitnessCanSee(p, player)
         && (!onJob || Vector4.Distance(p.GetWorldPosition(), ppos) > CBConfig.CombatReleaseDistance()) {
        CBForgetV(p, player);
      }
    }
  }
}

// ---- The door ---------------------------------------------------------------------------------
//
// The last line, for whoever is already on their way when V gets inside.
@wrapMethod(Door)
protected cb func OnApproachingAreaResponseEvent(evt: ref<AIApproachingAreaResponseEvent>) -> Bool {
  if IsDefined(evt) && evt.isPassingThrough && CBDoorTurnsAway(this, evt.sender as ScriptedPuppet) {
    return false;
  }
  wrappedMethod(evt);
  return true;
}

func CBDoorTurnsAway(door: ref<GameObject>, npc: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(door) || !IsDefined(npc) || !npc.IsAttached() {
    return false;
  }
  let game = door.GetGame();
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) || !sys.IsInSanctuary() {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !CBSentByUs(des, npc) && !npc.cbHostileByCyberbane {
    return false;
  }
  // V's own side comes in with V: V's crew (one who has not turned), a friendly gang's people riding with V, and the
  // help V called.
  let id = npc.GetEntityID();
  if IsDefined(des) && (des.IsTagged(id, n"CB_Ally") || des.IsTagged(id, n"CB_Follower")
                        || (des.IsTagged(id, n"CB_Own") && !des.IsTagged(id, n"CB_Turned"))) {
    return false;
  }
  // Only the doors around V. A hunter crossing a shop on the far side of the block is not at V's door.
  let player = GetPlayer(game);
  if !IsDefined(player)
     || Vector4.Distance(door.GetWorldPosition(), player.GetWorldPosition()) > CBConfig.SanctuaryDoorReach() {
    return false;
  }
  CBLog.Info(n"Spawn", "A door stayed shut to one of ours: you are safe inside.");
  CBCancelMove(npc);
  CBForgetV(npc, player);
  return true;
}
