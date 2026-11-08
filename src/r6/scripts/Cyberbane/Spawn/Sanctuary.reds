// Cyberbane - Nobody follows V through their own front door (1.7.3)
//
// "They don't spawn in the safe area, however unlock the door and walk in." Keeping arrivals out of
// a safe area only ever spoke for where somebody is placed. Once they exist they are after V, and
// nothing told them where to stop: the search ring follows V inside, a hunter who has found V is
// handed V to walk to, and somebody already fighting V simply carries on. A door does not stand in
// the way of any of that. The game lets an NPC through any door that is closed, powered and
// unlocked (Door.EvaluateOffMeshLinksTask), and opens it for them when they get there.
//
// So the rule is about V rather than about a spawn point. While V is somewhere the game protects,
// unless the player has asked to be hunted there:
//
//   nobody is given a move order, and any they had is taken back     CBOrderPursue, CBSanctuaryHold
//   nobody is handed V as a target                                   CBHuntTick
//   somebody fighting V who has lost sight of V stops fighting V     CBSanctuaryHold
//   and a door will not open for anybody of ours                     Door, below
//
// They stay where they are, outside, for as long as the hunt lasts, which runs out twice as fast
// while V is safe. Step back out while they are still there and it starts again, because the only
// thing they lost was V: they are as hostile as they ever were. That is the point of it being a
// door and not a teleport.
//
// The door itself is not changed. Locking it, or switching off its route for NPCs, would be a change
// to a device the story uses, and Judy or Panam walking into V's apartment is the story. It is one
// refusal, to one person, for as long as it takes them to stop trying.

// Is V somewhere the people after them must not follow? Worked out once a tick (CyberbaneSystem).
//
// Two questions because the game has two answers. The safe area manager is asked about a point, and
// the SAFE AREA the HUD shows is a zone on the player's state, and an apartment can be one without
// the other: that is the H10 report from 1.1.1. The player's opt-in opens all of this at once.
//
// The zone only counts while its weapon lock is on. The zone is written when V goes in and is not
// written again if V walks out into somewhere the game calls undefined (Player.OnZoneFactChanged:
// OnEnterUndefinedZone is empty), so on its own it can still say Safe long after V has left, and this
// answer holds every hunt and every arrival in the game. The lock is lifted on the way out by every
// path, so the two together cannot go stale. 1.1.5 broke the whole mod on a zone read that lied.
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

// Once a tick while V is safe, for everybody of ours.
public func CBSanctuaryHold(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                            player: ref<PlayerPuppet>) -> Void {
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Rival");
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Apex");
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Squad");
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Escort");
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Scout");
  CBSanctuaryHoldTag(sys, game, des, player, n"CB_Orphan");
}

func CBSanctuaryHoldTag(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                        player: ref<PlayerPuppet>, tag: CName) -> Void {
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    // Somebody still in a car is the car's, and it lets them out when it stops (CBOrderPursue then
    // gives them nothing to do).
    if CBStillStanding(p) && CBNpcSafe(sys, p) && !VehicleComponent.IsMountedToVehicle(game, p.GetEntityID()) {
      CBCancelMove(p);
      p.cbSearchGen = 0;
      // Somebody who can still see V has not lost V: a fight in a doorway goes on being a fight.
      if CBNpcInCombat(p) && !CBWitnessCanSee(p, player) {
        CBForgetV(p, player);
      }
    }
  }
}

// ---- The door ---------------------------------------------------------------------------------
//
// The last line, for whoever is already on their way when V gets inside. When somebody walks up to
// a closed door the game asks them whether they mean to go through it, and this is the answer
// arriving: the one moment an NPC opens a door. It only runs for that, so every other door in Night
// City, and every other person at this one, costs one test and goes straight to the game's own code.
@wrapMethod(Door)
protected cb func OnApproachingAreaResponseEvent(evt: ref<AIApproachingAreaResponseEvent>) -> Bool {
  if IsDefined(evt) && evt.isPassingThrough && CBDoorTurnsAway(this, evt.sender as ScriptedPuppet) {
    return false;
  }
  return wrappedMethod(evt);
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
  if !CBSentByUs(GameInstance.GetDynamicEntitySystem(), npc) && !npc.cbHostileByCyberbane {
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
