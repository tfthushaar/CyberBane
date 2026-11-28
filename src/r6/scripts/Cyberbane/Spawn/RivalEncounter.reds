// Cyberbane - Rival encounters (spec §10, §9.9; spike S-08)
//
// A Rival who is hunting you can actually turn up. On the slow tick, if one of your hunting Rivals is off cooldown and
// you are not already fighting, there is a chance it spawns near you (behind, out of view) wearing its captured record
// and appearance, tagged CB_Rival so it starts hostile and can be swept away.

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
  let player = GetPlayer(game);

  // Retire a Rival who has been left standing around too long.
  let fighting = (IsDefined(player) && player.IsInCombat()) || sys.GetHuntState() == CBHuntLocated();
  if IsDefined(cd) && !fighting && des.IsPopulated(n"CB_Rival")
     && (now - cd.lastRivalEncounterAt) > CBConfig.RivalRetireGameSeconds() {
    // You got away from them, and that has to count.
    CBRivalsShakenOff(sys, game, false);
    sys.ClearPack();
    CBDeleteTaggedSafe(game, n"CB_Rival", false, true);
    sys.SetActiveRivalId(0);
  }
  // Who comes next, and when, is the Rival lane's (Spawn/Queue.reds).
}

// How many Rivals you are allowed to be carrying at once.
public func CBRivalCap() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    return rt.GetSettings().maxRivals;
  }
  return CBConfig.RivalMaxActiveHardCap();
}

public func CBRivalsAtCap(sys: ref<CyberbaneSystem>) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  return sys.CountActiveRivals() >= CBRivalCap();
}

// How long this Rival takes to find you, in fast ticks. Higher rank, better information.
public func CBRivalHuntTicksFor(rank: Int32, atCap: Bool) -> Int32 {
  let t = Max(CBConfig.RivalHuntTicksMin(),
              CBConfig.RivalHuntTicksBase() - rank * CBConfig.RivalHuntTicksPerRank());
  if atCap {
    t = Max(CBConfig.RivalHuntTicksMin() / 2, RoundF(Cast<Float>(t) * CBConfig.RivalCapHurryMult()));
  }
  // Spread them out.
  let jitter = CBConfig.RivalHuntJitterTicks();
  if jitter > 0 {
    t += RandRange(0, jitter);
  }
  return t;
}

// Advance the countdowns without touching the world.
public func CBTickClocksOnly(sys: ref<CyberbaneSystem>) -> Void {
  if !IsDefined(sys) {
    return;
  }
  sys.TickDownPendingApex();
  sys.TickDownPendingSquad();
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Active)
                        || r.state == EnumInt(ECBRivalState.Hunting)) {
      // Only ever counted down. huntTicks is a cooldown now, not a countdown to arrival, so
      // zero means "eligible" and setting it here would quietly make an escaped Rival wait
      // all over again every time the world streamed.
      if r.huntTicks > 0 {
        r.huntTicks -= 1;
      }
    }
  }
}

// You got away from the Rival who was after you, and that has to count.

// V shook this one off (any Rival, not only the active one, so one who came with them counts).
public func CBRivalEscapedByPlayerFor(sys: ref<CyberbaneSystem>, game: GameInstance, got: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(got) {
    return;
  }
  let content = CBContent(game);
  // Where they were standing when V shook them off: both callers run this before the body is
  // removed, so it is still there to read if it is still in the world at all, and where it was
  // last seen standing if it is not (Rivals/Whereabouts.reds).
  let lostBody: ref<ScriptedPuppet>;
  if EntityID.IsDefined(got.spawnedEntityId) {
    lostBody = GameInstance.FindEntityByID(game, got.spawnedEntityId) as ScriptedPuppet;
  }
  CBNoteRivalSeen(sys, game, got, lostBody);
  CBRivalTimelineNote(game, got.id, CBTlLostThem());   // V lost them (Rivals/RivalTimeline.reds)
  got.encounters += 1;
  CBPromoteRival(got, content, CBGameSeconds(game));
  got.huntTicks = CBConfig.RivalAfterEscapeTicks();
  // From them, not about them: the person you just lost is the one who should be telling you
  // it is not over.
  if CBToastsOn() && IsDefined(content) {
    CBPhoneSendTinted(game, CBRivalDisplayName(content, got), CBRivalLostLine(got), CBHudRed());
  }
  CBLog.Info(n"Rivals", s"Player escaped rival id=\(got.id); promoted to rank \(got.rank).");
  CBRivalMaybeBreak(sys, game, got);
}

// Is any Rival actually alive and in the world right now?
public func CBLiveRivalPresent(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Hunting)
       && EntityID.IsDefined(r.spawnedEntityId) {
      let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
      if CBStillStanding(body) {
        return true;
      }
    }
  }
  return false;
}

// Is the body we queued for this Rival actually in the world?
public func CBRivalBodyPresent(game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(r) || !EntityID.IsDefined(r.spawnedEntityId) {
    return false;
  }
  return IsDefined(GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet);
}


// Drive the hunt countdown, once per fast tick.
public func CBRivalHuntTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
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
  // One Rival in the world at a time, and never on top of a fight already in progress.
  // "Is a Rival out?" means a living one.
  let busy = des.IsPopulated(n"CB_Rival") && CBLiveRivalPresent(sys, game);
  let player = GetPlayer(game);
  let inCombat = !IsDefined(player) || player.IsInCombat();
  // Never walk into a stealth job. Arriving mid-infiltration starts a fight the player was
  // deliberately avoiding, and the arrival alerts the guards being slipped past.
  let quietWork = CBStealthEncounterNearby(sys, game);

  let now = CBGameSeconds(game);
  let atCap = CBRivalsAtCap(sys);
  let rivals = sys.GetRivals();
  // NOTE: the scheduling that used to live here now belongs to Spawn/Queue.reds. Every Rival running its own countdown
  // meant several clocks for encounters that could never all happen, and no way to say which one was actually next.
  let hold = CBHoldNone();
  if sys.GetStoryHold() != CBStoryNone() {
    hold = CBHoldStory();   // the story has the stage (Core/StoryHold.reds)
  } else {
    if quietWork {
      hold = CBHoldQuietWork();
    } else {
      if busy {
        hold = CBHoldOneAlreadyOut();
      } else {
        if inCombat {
          hold = CBHoldInCombat();
        }
      }
    }
  }
  // Everybody waits, and every clock stays where it is, except the one below.

  // Written once, at the end, rather than up here.
  let failedToPlace = false;
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && TDBID.IsValid(r.recordID)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      // Waiting to see whether the one we queued actually turned up.
      if r.arrivalCheckTicks > 0 {
        r.arrivalCheckTicks -= 1;
        if r.arrivalCheckTicks <= 0 {
          let byCar = sys.GetRivalCarPending() == r.id;
          if byCar {
            sys.SetRivalCarPending(0);
          }
          if CBRivalBodyPresent(game, r) {
            r.huntTicks = CBRivalHuntTicksFor(r.rank, atCap);   // they are really here
          } else {
            // A car that never delivered them: they walk in next time rather than waiting on
            // the same road again.
            if byCar {
              sys.SetRivalCarFailed(r.id);
            }
            CBLog.Info(n"Spawn", s"Rival \(r.id) was queued but never arrived; trying again.");
            r.state = EnumInt(ECBRivalState.Active);
            sys.RemovePackRival(r.id);
            if sys.GetActiveRivalId() == r.id {
              sys.SetActiveRivalId(0);
              CBPackHandOffLead(sys);   // anybody who came with them and did arrive leads instead
            }
            r.huntTicks = CBConfig.RivalHuntRetryTicks();
            failedToPlace = true;
          }
        }
      }
    }
  }
  if hold != CBHoldNone() {
    sys.SetHuntHoldReason(hold);
    return;
  }
  sys.SetHuntHoldReason(failedToPlace ? CBHoldNoRoom() : CBHoldNone());
}

func CBSpawnRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float) -> Bool {
  CBRivalTakeSignature(sys, game, r);   // high enough, they come back chromed (Rivals/Signature.reds)
  // By car whenever a car can be sent, on foot only when it cannot. They get out when the car
  // reaches V, or keep chasing if V is driving.
  if CBRivalByCar(sys, game, r) {
    let noBody: EntityID;   // the body is filled in when the city's spawn is adopted
    r.spawnedEntityId = noBody;
    r.arrivalCheckTicks = CBConfig.RivalCarArrivalCheckTicks();
    CBRivalOnTheirWay(sys, game, r, now, true);   // their people are in the car with them
    CBLog.Info(n"Spawn", s"Rival encounter on its way by car (id \(r.id)).");
    return true;
  }
  // Closer than a crew, behind V and out of sight. They start from the tip their warning gave and
  // search; the fight starts when they find V (Spawn/Hunt.reds), not the moment they are placed.
  let body: EntityID;
  let spawned = CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Rival", CBConfig.RivalSpawnDistance(), body);
  if spawned <= 0 {
    // Say why. This path was silent, so a Rival that could not be placed produced a Hub reading "any moment" for as
    // long as the player stood somewhere unsuitable and nothing anywhere said what was wrong.
    let why = CBBlockLabel(CBLastSpawnBlock());
    if StrLen(why) == 0 {
      why = CBT(n"Cyberbane-FactionApex-NoReasonRecorded");
    }
    CBLog.Info(n"Spawn", s"Rival \(r.id) could not be placed: \(why).");
    return false;
  }
  // Remember which body is theirs.
  r.spawnedEntityId = body;
  r.arrivalCheckTicks = CBConfig.RivalArrivalCheckTicks();   // confirm they really showed up
  CBRivalOnTheirWay(sys, game, r, now);
  CBLog.Info(n"Spawn", s"Rival encounter spawned (id \(r.id)).");
  return true;
}

// Send this Rival by car, if a car can be sent.
func CBRivalByCar(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(sys) || !IsDefined(r) {
    return false;
  }
  if sys.GetRivalCarFailed() == r.id {
    sys.SetRivalCarFailed(0);
    return false;
  }
  let refused = CBCarRefusal(game);
  if StrLen(refused) > 0 {
    CBCarRefused(refused);
    return false;
  }
  if sys.HasPendingArrival() || sys.GetTopUpWanted() > 0 {
    CBCarRefused("another car is still on its way");
    return false;
  }
  // Active and pending before the car is sent, so the seat that is created for them knows
  // whose body it is (Spawn/Arrival.reds, CBOnArrivalCarAttached).
  let previous = sys.GetActiveRivalId();
  sys.SetActiveRivalId(r.id);
  sys.SetRivalCarPending(r.id);
  // Their own people ride with them.
  let escorts = CBRivalEscortCount(sys, r);
  let fs = sys.FindFaction(r.faction);
  let sent = false;
  if escorts > 0 && IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
    sent = CBSpawnVehicleArrival(sys, game, r.faction, fs.sampleRecord, 1 + escorts, n"CB_Escort",
                                 r.recordID, n"CB_Rival");
  } else {
    escorts = 0;
    sent = CBSpawnVehicleArrival(sys, game, r.faction, r.recordID, 1, n"CB_Rival", TDBID.None(), n"");
  }
  if !sent {
    sys.SetRivalCarPending(0);
    sys.SetActiveRivalId(previous);
    return false;
  }
  let seated = Max(0, Min(sys.GetLastCarSeats(), 1 + escorts) - 1);
  if escorts > seated {
    let walker: EntityID;
    CBSpawnGroup(game, fs.sampleRecord, n"", escorts - seated, n"CB_Escort",
                 CBConfig.RivalSpawnDistance() + 4.0, walker);
  }
  return true;
}

// How many of their own people a Rival brings. Somebody who runs people does not come alone: a
// Pack Leader brings their own, and so does whoever holds a chair in the gang's crew - the leader
// brings two, a lieutenant one.
func CBRivalEscortCount(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> Int32 {
  let escorts = CBRivalHasTrait(r, n"PackLeader") ? CBConfig.PackLeaderEscort() : 0;
  let role = CBRivalRole(sys, r);
  if role == CBRoleLeader() {
    escorts = Max(escorts, CBConfig.LeaderEscort());
  } else {
    if role == CBRoleLieutenant() {
      escorts = Max(escorts, CBConfig.LieutenantEscort());
    }
  }
  return escorts;
}

// Everything that is true of a Rival the moment they set off, whichever way they are coming.
func CBRivalOnTheirWay(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float,
                       opt byCar: Bool) -> Void {
  // Their people walk in as escorts, so they fight, chase and give up with the encounter and never hold up the crew
  // lane.
  let escorts = 0;
  if !byCar {
    escorts = CBRivalEscortCount(sys, r) - CBCountLiveOrSpawning(game, n"CB_Escort");
  }
  if escorts > 0 {
    let fs = sys.FindFaction(r.faction);
    if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
      let escort: EntityID;
      CBSpawnGroup(game, fs.sampleRecord, n"", escorts, n"CB_Escort",
                   CBConfig.RivalSpawnDistance() + 4.0, escort);
    }
  }
  r.state = EnumInt(ECBRivalState.Hunting);   // it is actively hunting you now
  r.lastSeenAt = now;
  sys.SetActiveRivalId(r.id);                 // track it for escape / slain handling
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastRivalEncounterAt = now;
  }
  // No text here. They already said they were coming (CBRivalWarning), and they say they have found you when they
  // actually lay eyes on you (Spawn/Hunt.reds, CBHuntOnLocated).
}

// What a Rival texts when they have found you. Chosen by how they came to be one, so the one
// you let go sounds different from the one who put you down.
func CBRivalArrivalLine(r: ref<CBRival>) -> String {
  if CBRivalHasTrait(r, n"Broken") {
    return CBT(n"Cyberbane-RivalEncounter-CanTStopHearingYouCan");
  }
  if r.killedV > 0 {
    return CBT(n"Cyberbane-RivalEncounter-FoundYouAgainYouKnowHow");
  }
  if r.sparedByV > 0 {
    return CBT(n"Cyberbane-RivalEncounter-YouShouldHaveFinishedItWhen");
  }
  if r.escapes > 0 {
    return CBT(n"Cyberbane-RivalEncounter-YouLetMeWalkICame");
  }
  return CBLineOf([CBT(n"Cyberbane-RivalEncounter-FoundYouLookAround"), CBT(n"Cyberbane-RivalEncounter-Found2"),
                   CBT(n"Cyberbane-RivalEncounter-Found3"), CBT(n"Cyberbane-RivalEncounter-Found4")]);
}

// What a Rival texts when V has given them the slip.
func CBRivalLostLine(r: ref<CBRival>) -> String {
  if r.killedV > 0 {
    return CBT(n"Cyberbane-RivalEncounter-RunThenIFoundYouOnce");
  }
  if r.rank >= 4 {
    return CBT(n"Cyberbane-RivalEncounter-EveryTimeYouRunIGet");
  }
  switch RandRange(0, 3) {
    case 0: return CBT(n"Cyberbane-RivalEncounter-LostMeForNow");
    case 1: return CBT(n"Cyberbane-RivalEncounter-KeepRunningIKnowWhereYou");
    default: return CBT(n"Cyberbane-RivalEncounter-NextTimeIBringMore");
  }
}

// What a Rival texts after getting away from V.
func CBRivalGotAwayLine(r: ref<CBRival>) -> String {
  if CBRivalHasTrait(r, n"OldWound") {
    return CBT(n"Cyberbane-RivalEncounter-SamePlaceAsLastTimeIt");
  }
  if CBRivalHasTrait(r, n"Scarred") {
    return CBT(n"Cyberbane-RivalEncounter-YouLeftAMarkIWill");
  }
  return CBT(n"Cyberbane-RivalEncounter-CloseNotCloseEnoughSeeYou");
}

// Now and then the Rival who comes brings one or two others of the same gang who are free to come.
public func CBRivalTeamUpsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() || !CBRivalsOn() {
    return false;
  }
  return !rt.HasSettings() || rt.GetSettings().rivalTeams;
}

func CBRivalTeamSize() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return 2;
  }
  return Clamp(rt.GetSettings().rivalTeamSize, 2, 3);
}

// How likely this Rival is to bring others. Somebody who runs people calls on them.
func CBRivalTeamUpChanceFor(sys: ref<CyberbaneSystem>, lead: ref<CBRival>) -> Float {
  let chance = CBConfig.RivalTeamUpChance();
  let role = CBRivalRole(sys, lead);
  if role == CBRoleLeader() || role == CBRoleLieutenant() || CBRivalHasTrait(lead, n"PackLeader") {
    chance += CBConfig.RivalTeamUpChanceLeader();
  }
  return ClampF(chance, 0.0, 0.75);
}

// May this Rival come along with somebody else's encounter right now?
func CBRivalCanJoinTeam(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, lead: ref<CBRival>) -> Bool {
  if !IsDefined(r) || !IsDefined(lead) || r.id == lead.id || NotEquals(r.faction, lead.faction)
     || r.huntTicks > 0 || !CBRivalQueueable(sys, r.id) || CBRecordIsSightingCyberpsycho(r.recordID) {
    return false;
  }
  // Already somewhere: out after V, on their way by car, waiting at their place, about to be found
  // there for V (the Hub's ambush), or about to be forgotten.
  if CBRivalBodyPresent(game, r) || sys.GetRivalCarPending() == r.id
     || (sys.IsLairActive() && sys.GetLairRivalId() == r.id) || sys.GetPendingFind() == r.id
     || sys.IsRivalForgetPending(r.id) {
    return false;
  }
  return true;
}

public func CBRivalBringPartners(sys: ref<CyberbaneSystem>, game: GameInstance, lead: ref<CBRival>, now: Float) -> Void {
  if !IsDefined(sys) || !IsDefined(lead) || !CBRivalTeamUpsOn()
     || RandF() >= CBRivalTeamUpChanceFor(sys, lead) {
    return;
  }
  // Who comes: the ones with the most reason to, with a little chance in it so it is not always the
  // same two. Scored like the lane's own pick (CBLanePick).
  let picks: array<ref<CBRival>>;
  let scores: array<Float>;
  for r in sys.GetRivals() {
    if CBRivalCanJoinTeam(sys, game, r, lead) {
      ArrayPush(picks, r);
      ArrayPush(scores, Cast<Float>(r.rank) * 8.0 + Cast<Float>(r.escapes) * 4.0
                        + Cast<Float>(r.encounters) * 2.0 + RandRangeF(0.0, 12.0));
    }
  }
  let content = CBContent(game);
  let want = CBRivalTeamSize() - 1;
  let brought = 0;
  let names = "";
  while brought < want && ArraySize(picks) > 0 && CBSpawnRoom(game) >= 1 {
    let best = 0;
    let k = 1;
    while k < ArraySize(picks) {
      if scores[k] > scores[best] {
        best = k;
      }
      k += 1;
    }
    let r = picks[best];
    ArrayErase(picks, best);
    ArrayErase(scores, best);
    // A little further back each, so they come in one after another rather than as one knot.
    let body: EntityID;
    let away = CBConfig.RivalSpawnDistance() + CBConfig.RivalTeamSpacing() * Cast<Float>(brought + 1);
    if CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Rival", away, body) > 0 {
      r.spawnedEntityId = body;
      r.arrivalCheckTicks = CBConfig.RivalArrivalCheckTicks();
      r.state = EnumInt(ECBRivalState.Hunting);
      r.lastSeenAt = now;
      sys.AddPackRival(r.id);
      brought += 1;
      if IsDefined(content) {
        let who = CBRivalDisplayName(content, r);
        names = StrLen(names) == 0 ? who : CBTf(n"Cyberbane-RivalEncounter-And", [names, who]);
      }
    }
  }
  if brought <= 0 {
    return;
  }
  // One word from the one leading, naming who came with them.
  if CBToastsOn() && IsDefined(content) && StrLen(names) > 0 {
    CBPhoneSendUrgent(game, CBRivalDisplayName(content, lead), CBTf(n"Cyberbane-RivalEncounter-NotComingAloneThisTimeWanted", [names]), CBHudRed());
  }
  CBLog.Info(n"Spawn", s"Rival \(lead.id) brings \(brought) more of \(NameToString(lead.faction))'s Rivals.");
}

// The lead's encounter has ended (CBCloseRivalEncounter): the next of the team still out leads now.
// Nobody left out of it, and the team is over.
public func CBPackHandOffLead(sys: ref<CyberbaneSystem>) -> Void {
  if !IsDefined(sys) || sys.GetActiveRivalId() > 0 {
    return;
  }
  let ids = sys.GetPackRivals();
  for pid in ids {
    let p = sys.FindRivalById(pid);
    if IsDefined(p) && p.state == EnumInt(ECBRivalState.Hunting) && EntityID.IsDefined(p.spawnedEntityId) {
      sys.RemovePackRival(pid);
      sys.SetActiveRivalId(pid);
      CBLog.Info(n"Rivals", s"Rival \(pid) carries the encounter on.");
      return;
    }
  }
  sys.ClearPack();
}

// V got away from the Rival encounter: the one leading it and everybody who came with them, each promoted and each on
// their cooldown, the way one Rival always was (CBRivalEscapedByPlayerFor), and each encounter closed. `onlyGone`
// counts only those whose body has left the world; otherwise anybody still standing or streamed out counts too.
public func CBRivalsShakenOff(sys: ref<CyberbaneSystem>, game: GameInstance, onlyGone: Bool) -> Int32 {
  if !IsDefined(sys) {
    return 0;
  }
  if sys.GetActiveRivalId() > 0 {
    CBUiSound(game, n"ui_gmpl_stealth_avoid_combat", n"ShookThemOff", 30.0);
  }
  // A list of ids first: every close below changes the team and can move the lead.
  let ids: array<Int32>;
  if sys.GetActiveRivalId() > 0 {
    ArrayPush(ids, sys.GetActiveRivalId());
  }
  for pid in sys.GetPackRivals() {
    if !ArrayContains(ids, pid) {
      ArrayPush(ids, pid);
    }
  }
  let n = 0;
  for id in ids {
    let r = sys.FindRivalById(id);
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Hunting) && EntityID.IsDefined(r.spawnedEntityId) {
      let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
      // On their way out of the world is gone too: CBStillStanding reads nothing from a body that is not attached and
      // calls it not standing, which left one caught mid-stream filed as out after V.
      let counts = !IsDefined(body) || !body.IsAttached() || (!onlyGone && CBStillStanding(body));
      if counts {
        CBRivalEscapedByPlayerFor(sys, game, r);
        // With the body, when it is still here: it is handed off as theirs (CBRetireRivalBody), so if
        // V comes back and finishes it, it is this Rival who dies, not whoever is out by then.
        CBCloseRivalEncounter(sys, game, r, body);
        n += 1;
      }
    }
  }
  return n;
}

// How many Rivals are out together right now, the one leading included.
public func CBRivalsOutTogether(sys: ref<CyberbaneSystem>, game: GameInstance) -> Int32 {
  if !IsDefined(sys) {
    return 0;
  }
  let n = 0;
  let lead = sys.FindRivalById(sys.GetActiveRivalId());
  if IsDefined(lead) && CBRivalBodyPresent(game, lead) {
    n += 1;
  }
  for pid in sys.GetPackRivals() {
    let p = sys.FindRivalById(pid);
    if IsDefined(p) && CBRivalBodyPresent(game, p) {
      n += 1;
    }
  }
  return n;
}
