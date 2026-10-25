// Cyberbane - Hit squads (spec §9.9)
//
// A gang you have turned hostile can send a squad after you. Checked on the slow tick:
// eligible gangs (hostile or worse, known enough, off cooldown) roll a small chance that
// scales with how much they hate and know you. A squad spawns behind V out of view, made
// of the kind of member V has actually fought (captured record), tagged so it can always
// be swept away. Squads are time-despawned so they never pile up or linger after a fight.
//
// Needs in-game tuning (S-08): navmesh validity of the spawn point and squad pathing.

public func CBHitSquadTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  let freqMult = 1.0;
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() {
      if !rt.GetSettings().hitSquads {
        return;
      }
      freqMult = rt.GetSettings().hitSquadFrequencyMult;
    }
  }
  if CBTwrActive() {
    return;   // They Will Remember owns hit squads in compat mode (spec §17)
  }

  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let now = CBGameSeconds(game);
  let cd = sys.GetCooldowns();

  // Clear a stale squad once it has had its time (spec §9.9 despawn). A squad that loses
  // V this way can leave a survivor who becomes a Hunter Rival (spec §9.9 / §10.2).
  if IsDefined(cd) && des.IsPopulated(n"CB_Squad")
     && (now - cd.lastHitSquadAt) > CBConfig.HitSquadDespawnMinutes() * 60.0 {
    des.DeleteTagged(n"CB_Squad");
    let escaped = sys.GetActiveSquadFaction();
    if NotEquals(escaped, n"") && RandF() < CBConfig.RivalChanceHunter() {
      let efs = sys.FindFaction(escaped);
      if IsDefined(efs) && TDBID.IsValid(efs.sampleRecord) {
        CBCreateRival(sys, game, escaped, efs.sampleRecord, n"", ECBRivalSource.Hunter, CBCurrentDistrict(game), now);
      }
    }
    sys.SetActiveSquadFaction(n"");
  }

  // Global cooldown between squads, and never stack one onto an existing fight.
  if IsDefined(cd) && cd.lastHitSquadAt > 0.0
     && (now - cd.lastHitSquadAt) < CBConfig.HitSquadGlobalCooldownMinutes() * 60.0 {
    return;
  }
  if des.IsPopulated(n"CB_Squad") {
    return;   // a squad is already out
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    return;
  }

  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  let infamous = EnumInt(score.GetTier()) >= EnumInt(ECBRenownTier.Infamous);
  let factionCooldown = CBConfig.HitSquadFactionCooldownDays() * CBConfig.SecondsPerDay();

  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
      let posture = score.GetPosture(fs.id);
      let hostile = Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta);
      let offCooldown = fs.lastHitSquadAt <= 0.0 || (now - fs.lastHitSquadAt) >= factionCooldown;
      if hostile && fs.renown >= 30.0 && offCooldown {
        let chance = CBConfig.HitSquadBaseChance() * (-fs.standing / 70.0) * (fs.renown / 100.0) * freqMult;
        if RandF() < chance {
          CBSpawnHitSquad(sys, game, fs, infamous, now);
          return;   // at most one squad per check
        }
      }
    }
  }
}

func CBSpawnHitSquad(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>, infamous: Bool, now: Float) -> Void {
  // size = 3 + floor(-S_f / 35), capped at 6, +1 at Infamous or above (spec §9.9).
  let size = 3 + FloorF(-fs.standing / 35.0);
  if size > 6 {
    size = 6;
  }
  if infamous {
    size += 1;
  }

  let spawned = CBSpawnGroup(game, fs.sampleRecord, n"", size, n"CB_Squad", CBConfig.HitSquadMinSpawnDistance() + 12.0);
  if spawned <= 0 {
    return;   // nothing queued (e.g. no valid record) - don't start the cooldown
  }

  fs.lastHitSquadAt = now;
  sys.SetActiveSquadFaction(fs.id);
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastHitSquadAt = now;
  }

  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    CBShowMessage(game, s"Cyberbane: \(NameToString(fs.id)) sent people after you.", 4.0);
  }
  CBLog.Info(n"Spawn", s"Hit squad from \(NameToString(fs.id)): \(spawned).");
}
