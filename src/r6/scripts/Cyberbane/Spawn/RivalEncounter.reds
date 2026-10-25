// Cyberbane - Rival encounters (spec §10, §9.9; spike S-08)
//
// A Rival who is hunting you can actually turn up. On the slow tick, if one of your
// hunting Rivals is off cooldown and you are not already fighting, there is a chance it
// spawns near you (behind, out of view) wearing its captured record and appearance,
// tagged CB_Rival so it starts hostile and can be swept away. One Rival at a time; it is
// time-despawned if you never engage. Encounter outcomes (killed V / escaped / slain) are
// handled by the existing Rival transitions when the fight actually happens.

public func CBRivalEncounterTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() && !rt.GetSettings().rivals {
      return;
    }
  }

  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let now = CBGameSeconds(game);
  let cd = sys.GetCooldowns();

  // Retire a Rival who has been left standing around too long (twice a squad's patience).
  if IsDefined(cd) && des.IsPopulated(n"CB_Rival")
     && (now - cd.lastRivalEncounterAt) > CBConfig.HitSquadDespawnMinutes() * 120.0 {
    des.DeleteTagged(n"CB_Rival");
  }

  if des.IsPopulated(n"CB_Rival") {
    return;   // one Rival encounter at a time
  }
  // One encounter per in-game hour at most.
  if IsDefined(cd) && cd.lastRivalEncounterAt > 0.0
     && (now - cd.lastRivalEncounterAt) < CBConfig.SecondsPerDay() / 24.0 {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    return;
  }

  // Find a hunting Rival ready to appear.
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Hunting)
       && TDBID.IsValid(r.recordID)
       && (r.nextEligibleAt <= 0.0 || now >= r.nextEligibleAt) {
      if RandF() < 0.35 {
        CBSpawnRival(sys, game, r, now);
        return;
      }
    }
  }
}

func CBSpawnRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float) -> Void {
  let spawned = CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Rival");
  if spawned <= 0 {
    return;
  }
  r.lastSeenAt = now;
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastRivalEncounterAt = now;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    let content = CyberbaneContent.Get();
    let name = IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival";
    CBShowMessage(game, s"Cyberbane: \(name) has caught up with you.", 4.0);
  }
  CBLog.Info(n"Spawn", s"Rival encounter spawned (id \(r.id)).");
}
