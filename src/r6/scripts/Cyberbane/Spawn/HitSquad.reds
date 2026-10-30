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
  // Not into the middle of a quiet job (spec §16).
  if CBStealthEncounterNearby(sys, game) {
    return;
  }
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
        CBCreateRival(sys, game, escaped, efs.sampleRecord, n"", ECBRivalSource.Hunter, CBEventDistrict(sys, game), now);
      }
    }
    sys.SetActiveSquadFaction(n"");
  }

  // Global cooldown between squads, and never stack one onto an existing fight.
  if IsDefined(cd) && cd.lastHitSquadAt > 0.0
     && (now - cd.lastHitSquadAt) < CBConfig.HitSquadGlobalCooldownMinutes() * 60.0 {
    return;
  }
  // A squad is already out - meaning one that can still fight. IsPopulated counts tagged
  // entities, and since a knocked-out squad stopped holding its lane, a tag-only test here
  // would have let the lane re-arm and then refused every spawn it asked for.
  if des.IsPopulated(n"CB_Squad") && CBLiveTaggedPresent(game, n"CB_Squad") {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    return;
  }

  // Choosing who comes next, and when, lives in Spawn/Queue.reds now: three lanes, each with
  // one clock, so there is exactly one answer to "who is coming" per kind of trouble. What
  // stays here is everything about bringing a crew in once a lane has decided it is their
  // turn - the despawn sweep and cooldowns above, and CBSpawnHitSquad below.
}

// How many a gang at full vendetta sends when V is at full menace.
public func CBVendettaSquadSize() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return CBConfig.VendettaSquadSizeDefault();
  }
  return rt.GetSettings().vendettaSquadSize;
}

// Is the player happy to be hunted this hard?
public func CBVendettaSquadsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().vendettaSquads;
}


// Run the clock down, and send them when it reaches zero.
//
// Everything that would make an arrival wrong right now - a safe area, a gig, a quiet job -
// holds the timer where it is instead of cancelling it. The gang has not changed its mind
// because you walked into a bar; they are waiting outside.
public func CBProcessPendingSquad(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let faction = sys.GetPendingSquadFaction();
  if Equals(faction, n"") {
    return;
  }
  if sys.GetPendingSquadTicks() > 0 {
    sys.TickDownPendingSquad();
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    sys.AgePendingSquadHold();
    return;
  }
  // Time is up. Hold, do not cancel, if this is a bad moment - but not forever.
  if CBStealthEncounterNearby(sys, game) || CBSafeAreaBlocksSpawn(game, player.GetWorldPosition()) {
    sys.AgePendingSquadHold();
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || (des.IsPopulated(n"CB_Squad") && CBLiveTaggedPresent(game, n"CB_Squad")) {
    sys.AgePendingSquadHold();
    return;
  }
  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) || !TDBID.IsValid(fs.sampleRecord) {
    sys.ClearPendingSquad();
    return;
  }
  let score = sys.GetScore();
  // They may have been paid off, or simply calmed down, while the crew was on its way.
  //
  // This used to insist on Vendetta specifically, which was correct while only a vendetta could
  // schedule a crew. Now that an ordinary hostile gang schedules one too, that test would have
  // cancelled every hostile squad the moment its timer ran out - the new feature quietly
  // cancelling itself. It checks for "still wants you dead" instead.
  if IsDefined(score) {
    let nowPosture = score.GetPosture(fs.id);
    if NotEquals(nowPosture, ECBPosture.Vendetta) && NotEquals(nowPosture, ECBPosture.Hostile) {
      sys.ClearPendingSquad();
      CBLog.Info(n"Spawn", s"Squad from \(NameToString(fs.id)) called off.");
      return;
    }
  }
  let infamous = IsDefined(score) && EnumInt(score.GetTier()) >= EnumInt(ECBRenownTier.Infamous);
  CBSpawnHitSquad(sys, game, fs, infamous, CBGameSeconds(game));
  sys.ClearPendingSquad();
}

// Does a vendetta crew bring the gang's apex squad with it?
public func CBVendettaApexOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().vendettaApexSquad;
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
  // A vendetta sends a crew, not a patrol, and how big a crew depends on what they think
  // they are dealing with. Menace is the same number the Hub reports, so a maxed out merc
  // gets the full party and an early character gets something they can survive.
  let score = sys.GetScore();
  let posture = IsDefined(score) ? score.GetPosture(fs.id) : ECBPosture.Neutral;
  if Equals(posture, ECBPosture.Vendetta) && CBVendettaSquadsOn() {
    let menace = IsDefined(score) ? ClampF(score.GetMenace() / 100.0, 0.0, 1.0) : 0.0;
    let target = CBVendettaSquadSize();
    let floorSize = FloorF(Cast<Float>(target) * CBConfig.VendettaSquadFloorFraction());
    let scaled = floorSize + FloorF(Cast<Float>(target - floorSize) * menace);
    if scaled > size {
      size = scaled;
    }
  }

  let squadEntity: EntityID;
  sys.ClearSquadAnchor();   // this crew is its own squad, not a late joiner to the last one

  // A vendetta does not send muscle, it sends everybody. The crew comes with the gang's apex
  // squad in it: four boss-grade enforcers in a car, with the rest of the crew behind them on
  // foot. This is the fight a vendetta is supposed to be.
  let withApex = Equals(posture, ECBPosture.Vendetta) && CBVendettaSquadsOn()
                 && CBVendettaApexOn() && TDBID.IsValid(fs.eliteRecord);
  if withApex {
    if CBSpawnVehicleArrival(sys, game, fs.id, fs.eliteRecord, CBConfig.ApexStrikeTeamSize(),
                             n"CB_Apex", fs.eliteRecord, n"CB_Apex") {
      sys.MarkArrivalRoleSquad(fs.id);
      CBLog.Info(n"Spawn", s"Vendetta crew from \(NameToString(fs.id)) brings an apex squad.");
      // The crew on foot is the whole squad; the car is extra.
      let footAll = CBSpawnGroup(game, fs.sampleRecord, n"", size, n"CB_Squad",
                                 CBConfig.HitSquadMinSpawnDistance() + 12.0, squadEntity);
      fs.lastHitSquadAt = now;
      sys.SetActiveSquadFaction(fs.id);
      let cdApex = sys.GetCooldowns();
      if IsDefined(cdApex) {
        cdApex.lastHitSquadAt = now;
      }
      let rtApex = CyberbaneRuntime.Get();
      if IsDefined(rtApex) && rtApex.HasSettings() && rtApex.GetSettings().toasts {
        CBShowMessage(game, s"Cyberbane: vendetta crew and apex squad - the \(NameToString(fs.id)) are coming for you in force.", 5.0);
      }
      CBLog.Info(n"Spawn", s"Vendetta crew from \(NameToString(fs.id)): \(footAll) on foot plus an apex squad.");
      return;
    }
  }
  // If they can drive to you, they drive. A car seats four, so a crew bigger than that sends
  // a car and the rest come on foot behind it - which is what a gang turning out in numbers
  // actually looks like, rather than a bus.
  let byCar = 0;
  if CBSpawnVehicleArrival(sys, game, fs.id, fs.sampleRecord, CBConfig.CarMaxSeats(), n"CB_Squad",
                           TDBID.None(), n"") {
    byCar = CBConfig.CarMaxSeats();
    if byCar > size {
      byCar = size;
    }
  }
  let onFoot = size - byCar;
  let spawned = byCar;
  if onFoot > 0 {
    spawned += CBSpawnGroup(game, fs.sampleRecord, n"", onFoot, n"CB_Squad",
                            CBConfig.HitSquadMinSpawnDistance() + 12.0, squadEntity);
  }
  if spawned <= 0 {
    // Nothing queued, so the cooldown does not start - but the appointment has to be aged or
    // it stands for ever, and a standing appointment keeps the lane busy. That is the Rival
    // lane's trap again, in a third place, and it was silent here too.
    let why = CBBlockLabel(CBLastSpawnBlock());
    if StrLen(why) == 0 {
      why = "no reason recorded";
    }
    CBLog.Info(n"Spawn", s"Crew from \(NameToString(fs.id)) could not be placed: \(why).");
    sys.AgePendingSquadHold();
    return;
  }

  fs.lastHitSquadAt = now;
  sys.SetActiveSquadFaction(fs.id);
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastHitSquadAt = now;
  }

  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    CBShowMessage(game, s"Cyberbane: hit squad - \(NameToString(fs.id)) sent people after you.", 4.0);
  }
  CBLog.Info(n"Spawn", s"Hit squad from \(NameToString(fs.id)): \(spawned).");
}
