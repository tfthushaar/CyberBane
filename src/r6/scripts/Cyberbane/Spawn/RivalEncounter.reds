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
    sys.SetActiveRivalId(0);
  }

  if des.IsPopulated(n"CB_Rival") {
    return;   // one Rival encounter at a time
  }
  // Leave a gap between encounters so a Rival catching up stays an event, not an ambush loop.
  if IsDefined(cd) && cd.lastRivalEncounterAt > 0.0
     && (now - cd.lastRivalEncounterAt) < CBConfig.SecondsPerHour() * CBConfig.RivalEncounterCooldownHours() {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    return;
  }

  // Find a Rival ready to come after V. Active or already Hunting both count, so your
  // rivals actually turn up instead of only ever living on the Hub.
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    // Check the handle before reading anything off it.
    if IsDefined(r) {
      let seeking = r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting);
      if seeking
         && TDBID.IsValid(r.recordID)
         && (r.nextEligibleAt <= 0.0 || now >= r.nextEligibleAt) {
        // A Rival that has climbed the ranks presses harder than a fresh one, so it turns up
        // more often. Capped so even a veteran nemesis is not waiting around every corner.
        let chance = ClampF(CBConfig.RivalEncounterBaseChance()
          + Cast<Float>(r.rank) * CBConfig.RivalEncounterChancePerRank(), 0.0, 0.75);
        if RandF() < chance {
          CBSpawnRival(sys, game, r, now);
          return;
        }
      }
    }
  }
}

func CBSpawnRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float) -> Void {
  // Spawn close and behind so the Rival perceives V right away and gives chase.
  let spawned = CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Rival", CBConfig.RivalSpawnDistance());
  if spawned <= 0 {
    return;
  }
  r.state = EnumInt(ECBRivalState.Hunting);   // it is actively hunting you now
  r.lastSeenAt = now;
  sys.SetActiveRivalId(r.id);                 // track it for escape / slain handling
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastRivalEncounterAt = now;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    let content = CBContent(game);
    let name = IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival";
    CBShowMessage(game, s"Cyberbane: \(name) has caught up with you.", 4.0);
  }
  CBLog.Info(n"Spawn", s"Rival encounter spawned (id \(r.id)).");
}
