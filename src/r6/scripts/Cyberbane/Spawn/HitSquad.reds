// Cyberbane - Hit squads (spec §9.9)
//
// A gang you have turned hostile can send a squad after you. Who comes next, and when, lives in
// Spawn/Queue.reds; this file brings a crew in once its lane has decided it is their turn.
//
// A hit squad is the gang's apex squad - four of their best, one in each chair: a heavy, a
// shooter, a blade and a netrunner, the way a MaxTac drop reads - with the rest of the crew
// behind them (CBCrewBringsApex). It spawns out of view, built from the kind of member V has
// actually fought (captured records), and tagged so it can always be swept away.
//
// How long a squad stays in the world is the hunt's business and nobody else's
// (Spawn/Hunt.reds): they search, find V, fight, and leave only when V has given them the slip
// or the story takes the stage. Until 1.6.3 a second clock ran here as well, left over from
// before the hunt existed: "five minutes" after a crew was sent, the slow tick deleted every
// living member V could not see at that moment. Five minutes of the in-game clock is under forty
// real seconds, and the slow tick only looks once an in-game hour, so whenever that hourly look
// fell inside a fight - which was most fights - anybody flanking behind V or ducked behind cover
// simply vanished, and those still in view were stripped of their tag and vanished the moment
// they were not. That was the "enemies despawn mid fight, only hit squads, never Rivals" report:
// it only ever looked at CB_Squad. The clock is gone rather than retuned, because no length of
// it can know whether a fight is on; the hunt does.

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
  // The story has the stage: the clock stops where it is, and nothing about waiting it out counts
  // against them either. They are still coming, once it lets go (Core/StoryHold.reds).
  if sys.GetStoryHold() != CBStoryNone() {
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
  // They may have been paid off, or simply calmed down, while the crew was on its way, or the
  // player may have switched them or crews off (CBGangMaySend). "Still wants you dead" rather than
  // Vendetta alone, since an ordinary hostile gang schedules a crew too.
  if !CBGangMaySend(sys, fs.id) {
    sys.ClearPendingSquad();
    CBLog.Info(n"Spawn", s"Squad from \(NameToString(fs.id)) called off.");
    return;
  }
  let infamous = IsDefined(score) && EnumInt(score.GetTier()) >= EnumInt(ECBRenownTier.Infamous);
  // Only a crew that actually set off ends the appointment. This cleared it whatever happened,
  // so a crew the street would not take on its first try - every point in view, no floor, the
  // world still settling - was dropped on the spot, and the hold-and-retry written for exactly
  // that case (AgePendingSquadHold, below in CBSpawnHitSquad) never got a second tick to work in.
  if CBSpawnHitSquad(sys, game, fs, infamous, CBGameSeconds(game)) {
    sys.ClearPendingSquad();
  }
}

// Bring the crew in: the gang's apex squad first, then the rest of them. True when anybody was
// sent; false means nobody could be placed this tick, the hold has been aged, and the
// appointment stands for another try.
func CBSpawnHitSquad(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>, infamous: Bool, now: Float) -> Bool {
  // How many: the one formula the warning also uses (Spawn/Queue.reds, CBCrewSizeFor), so the
  // number they texted is the number that turns up.
  let size = CBCrewSizeFor(sys, fs, infamous);
  let squadEntity: EntityID;
  sys.ClearSquadAnchor();   // this crew is its own squad, not a late joiner to the last one

  // Their best come first: four, one in each chair, the way a MaxTac drop reads - a heavy, a
  // shooter, a blade and a netrunner (Spawn/ApexSquad.reds). First so the ceiling on live
  // spawns can never leave the crew standing there without them. By car when V is driving and
  // a car can get here, otherwise on foot; whichever chairs either way cannot fill now, the
  // muster walks in shortly (CBApexMusterTick). Same decision as the warning and the HUD line.
  let team = CBConfig.ApexStrikeTeamSize();
  let assassin = CBClawsAssassin(game, fs.id);
  let withApex = !assassin && CBCrewBringsApex(sys, fs);
  // On foot with a job tracked far away: they may wait for V there instead (Spawn/HuntGrows.reds, [47]).
  if !withApex && !assassin && CBTryWaitOnRoad(sys, game, fs, size) {
    fs.lastHitSquadAt = now;
    let cdRoad = sys.GetCooldowns();
    if IsDefined(cdRoad) {
      cdRoad.lastHitSquadAt = now;
    }
    CBWarSpend(game, fs.id, CBConfig.WarCrewCost() * Cast<Float>(size));
    CBLog.Info(n"Spawn", s"\(NameToString(fs.id)) are waiting for you on the road to your job.");
    return true;
  }
  let apexFuture = 0;   // chairs a car has yet to bring into the world
  if withApex {
    let apexRecord = CBApexRecordFor(fs);
    sys.BeginApexMuster(fs.id, apexRecord);
    if CBSendByCar(sys, game, fs, apexRecord, team, n"CB_Apex") > 0 {
      apexFuture = team;
      CBApexArrivalSound(game);
    } else {
      sys.ResetApexRoles();
      if CBWalkInRest(sys, game, fs, apexRecord, n"CB_Apex", 0, team) <= 0 {
        // Nobody could be placed. The crew does not come without them: if the street will not
        // take four people now, it will not take the rest either, and a crew that is promised
        // with its best should arrive with them. The appointment stands and tries again.
        sys.ClearApexMuster();
        CBLog.Info(n"Spawn", s"Crew from \(NameToString(fs.id)) is holding for its apex squad: \(CBSpawnBlockWhy()).");
        sys.AgePendingSquadHold();
        return false;
      }
      CBApexArrivalSound(game);
      CBApexTerrorWave(game);
    }
  }

  // The rest of the crew, inside whatever room the ceiling has left, keeping room for the apex
  // chairs a car is still bringing. If they can drive to you, they drive, all of them: as many
  // cars as it takes, one after another, behind the apex squad's own (CBSendByCar, CBConvoyTick).
  // This used to send one car of four at most and walk everybody else in, and with the apex squad
  // in that one car the whole crew walked. Whoever the "Cars per arrival" limit leaves over, or a
  // car cannot be sent for, still comes on foot.
  let crew = Min(size, Max(0, CBSpawnRoom(game) - apexFuture));
  let spawned = 0;
  let crewFuture = 0;   // crew a car has yet to bring into the world
  if crew > 0 {
    sys.SetAmbushWanted(CBCrewLiesInWait(sys, game, fs, withApex));
    let byCar = CBSendByCar(sys, game, fs, fs.sampleRecord, crew, n"CB_Squad");
    sys.SetAmbushWanted(false);
    spawned = byCar;
    crewFuture = Max(0, byCar);
    if byCar <= 0 {
      if assassin {
        // One killer with a blade, alone (Spawn/HuntGrows.reds, [11]).
        let killer = CBAssassinRecord();
        spawned = TDBID.IsValid(killer) ? CBSpawnGroup(game, killer, n"", 1, n"CB_Squad", CBConfig.HitSquadMinSpawnDistance() + 12.0, squadEntity) : 0;
      } else {
        spawned = CBSpawnMixedCrew(game, fs, crew, CBConfig.HitSquadMinSpawnDistance() + 12.0, squadEntity);
      }
    }
  }
  // And their netrunner (1.8.5), hanging back while the rest go in. Not with an apex squad, which
  // brings its own fourth chair; not for a crew of one or two; never past the live ceiling. One body,
  // placed the way the crew was (CBSpawnGroup), so it is one of the crew in every count. A crew coming
  // by car is not in the world until its car is, so its seats are counted here as taken: without that
  // the netrunner walked into the room the car's last passenger then could not have.
  if spawned >= CBConfig.NetrunnerSeatMinCrew() && !withApex {
    let netrunner = CBNetrunnerSeatRecord(fs);
    if TDBID.IsValid(netrunner) && CBSpawnRoom(game) - crewFuture >= 1 {
      let netBody: EntityID;
      if CBSpawnGroup(game, netrunner, n"", 1, n"CB_Squad", CBConfig.HitSquadMinSpawnDistance() + 20.0, netBody) > 0 {
        spawned += 1;
        CBLog.Info(n"Spawn", s"A netrunner comes with the \(NameToString(fs.id)) crew.");
      }
    }
  }
  if spawned <= 0 && !withApex {
    // Nothing queued, so the cooldown does not start - but the appointment has to be aged or
    // it stands for ever, and a standing appointment keeps the lane busy. That is the Rival
    // lane's trap again, in a third place, and it was silent here too.
    CBLog.Info(n"Spawn", s"Crew from \(NameToString(fs.id)) could not be placed: \(CBSpawnBlockWhy()).");
    sys.AgePendingSquadHold();
    return false;
  }

  // A common enemy (Economy/War.reds, 2.4.0): the gang they have a truce with sends a couple of its own along.
  let partner = CBTrucePartner(game, fs.id);
  let partnerFs = sys.FindFaction(partner);
  if IsDefined(partnerFs) && TDBID.IsValid(partnerFs.sampleRecord) && CBSpawnRoom(game) > 0 {
    let joinBody: EntityID;
    let joined = CBSpawnGroup(game, partnerFs.sampleRecord, n"", CBConfig.TruceJoin(), n"CB_Squad",
                              CBConfig.HitSquadMinSpawnDistance() + 16.0, joinBody);
    if joined > 0 {
      spawned += joined;
      CBLog.Info(n"Spawn", s"\(joined) of \(NameToString(partner)) came along with the \(NameToString(fs.id)) crew.");
    }
  }
  // Paid for out of their chest (Economy/War.reds, 2.4.0).
  CBWarSpend(game, fs.id, CBConfig.WarCrewCost() * Cast<Float>(Max(spawned, 0)) + (withApex ? CBConfig.WarApexCost() : 0.0));
  fs.lastHitSquadAt = now;
  sys.SetActiveSquadFaction(fs.id);
  // Said for this crew either way, not left over from the last one: whether a crew grenadier is
  // chosen, and when the crew counts as beaten, both read it (Spawn/Spawner.reds, CombatSignals).
  sys.SetActiveSquadApex(withApex);
  if withApex {
    // One hit squad: the crew is beaten once its apex is down too, and their kills are spent.
    sys.SetActiveSquadApex(true);
    fs.apexAtKills = fs.kills;
    sys.ClearCrewBeaten(fs.id);
    sys.ArmApexBounty(fs.id);
  }
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastHitSquadAt = now;
  }
  // They said they were coming when they set off (CBCrewWarning); arriving is not news.
  let apexNote = withApex ? s" with their apex squad (\(team))" : "";
  CBLog.Info(n"Spawn", s"Hit squad from \(NameToString(fs.id)): \(spawned)\(apexNote).");
  return true;
}

// Why the last arrival was refused, in words, for the log.
public func CBSpawnBlockWhy() -> String {
  let why = CBBlockLabel(CBLastSpawnBlock());
  if StrLen(why) == 0 {
    why = "no reason recorded";
  }
  return why;
}

// A crew that isn't five of one person ([U1], 2.3.2). Each seat from whoever of theirs V has met in that role (the
// records the apex roster already captures as V fights them, CBCaptureRoleRecord): a heavy once there are four, a
// blade once there are three, and the rest shooters, half of them the gang's own last-seen face. A seat whose record
// is not a fit person to spawn falls back to that face. One CBSpawnGroup per record, under the same live ceiling.
// The car path still seats one record (CBSendByCar takes one); whoever walks in is mixed.
public func CBSpawnMixedCrew(game: GameInstance, fs: ref<CBFactionState>, crew: Int32, dist: Float, out last: EntityID,
                             opt tag: CName) -> Int32 {
  let wear = IsNameValid(tag) ? tag : n"CB_Squad";
  let base = fs.sampleRecord;
  if crew <= 0 || !TDBID.IsValid(base) {
    return 0;
  }
  let heavy = crew >= 4 ? CBCrewSeat(fs.roleTankRecord, base) : base;
  let blade = crew >= 3 ? CBCrewSeat(fs.roleBladeRecord, base) : base;
  let shooter = CBCrewSeat(fs.roleAssaultRecord, base);
  let records: array<TweakDBID>;
  let counts: array<Int32>;
  let left = crew;
  if heavy != base {
    ArrayPush(records, heavy);
    ArrayPush(counts, 1);
    left -= 1;
  }
  if blade != base && left > 1 {
    ArrayPush(records, blade);
    ArrayPush(counts, 1);
    left -= 1;
  }
  let shooters = shooter != base ? left / 2 : 0;
  if shooters > 0 {
    ArrayPush(records, shooter);
    ArrayPush(counts, shooters);
    left -= shooters;
  }
  if left > 0 {
    ArrayPush(records, base);
    ArrayPush(counts, left);
  }
  let spawned = 0;
  let i = 0;
  while i < ArraySize(records) && i < ArraySize(counts) {
    let body: EntityID;
    let n = CBSpawnGroup(game, records[i], n"", counts[i], wear, dist, body);
    if n > 0 {
      spawned += n;
      last = body;
    }
    i += 1;
  }
  if ArraySize(records) > 1 {
    CBLog.Info(n"Spawn", s"A mixed crew: \(ArraySize(records)) kinds of people in \(spawned).");
  }
  return spawned;
}

// A captured role record if it is a fit person to put in a crew, otherwise the gang's own face.
func CBCrewSeat(record: TweakDBID, fallback: TweakDBID) -> TweakDBID {
  if !TDBID.IsValid(record) || !CBRecordIsPerson(record) || CBRecordUnfitTemplate(record) {
    return fallback;
  }
  return record;
}
