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
  let withApex = CBCrewBringsApex(sys, fs);
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
  if crew > 0 {
    sys.SetAmbushWanted(CBCrewLiesInWait(sys, game, fs, withApex));
    let byCar = CBSendByCar(sys, game, fs, fs.sampleRecord, crew, n"CB_Squad");
    sys.SetAmbushWanted(false);
    spawned = byCar;
    if byCar <= 0 {
      spawned = CBSpawnGroup(game, fs.sampleRecord, n"", crew, n"CB_Squad",
                             CBConfig.HitSquadMinSpawnDistance() + 12.0, squadEntity);
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

  fs.lastHitSquadAt = now;
  sys.SetActiveSquadFaction(fs.id);
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
