// Cyberbane - Who comes for you next (spec §9.9)
//
// Three lanes, each with its own clock: one Rival, one crew, one apex squad.
//
// Before this, every Rival ran its own countdown, hit squads ran theirs, and the apex ran a
// third. They all held each other off at the moment of arrival, so only one ever actually
// landed - but because each kept its own clock, the Hub showed several timers for things that
// could not all happen, and anything without a clock just said "due", which from the outside
// is indistinguishable from broken.
//
// Lanes rather than one queue, because the alternative is too polite. One global slot means
// you are only ever fighting one thing, and the mod has no way to put you under real pressure.
// Three lanes mean a Rival can catch up with you while a gang's crew is already on its way,
// which is the situation worth building toward - and because a lane holds its own kind off
// until that encounter is finished, you can never be jumped by two Rivals at once or two apex
// squads at once. The pressure comes from different kinds of trouble arriving together, not
// from the same kind stacking.
//
// Each lane owns *when*. None of them owns *how*: firing a crew or an apex hands off to the
// pending mechanism those systems already have, which knows about cars, safe areas, quiet jobs
// and giving up. Reusing them means this cannot break arrival paths that were only just made
// to work.

public func CBLaneRival() -> Int32 = 1
public func CBLaneSquad() -> Int32 = 2
public func CBLaneApex() -> Int32 = 3

// Is this lane's kind already here or already on its way?
public func CBLaneBusy(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Bool {
  if !IsDefined(sys) {
    return true;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return true;
  }
  // Just sent somebody. Spawning is a request, not an instant: for a moment afterwards
  // nothing has attached, every "is one of these alive" test answers no, and the lane would
  // send a second one on top of the first. Bounded by a tick count rather than by waiting for
  // an attach that might never come, so this can delay a lane but never wedge it.
  // Zero means this lane has never sent anybody, not that it sent somebody at tick zero. The
  // tick counter increments before any lane code runs, so a real stamp is always one or more.
  if sys.GetLaneFired(lane) > 0
     && (sys.GetTickCount() - sys.GetLaneFired(lane)) < CBConfig.LaneSettleTicks() {
    return true;
  }
  if lane == CBLaneRival() {
    // A Rival the city is still driving in counts as out: their body only becomes theirs once
    // it is adopted, and until then the live test cannot see them.
    // So does one waiting at their place for V (Rivals/Whereabouts.reds): one Rival in the world
    // at a time, whichever way round the ambush is.
    return CBLiveRivalPresent(sys, game) || sys.GetRivalCarPending() > 0 || sys.IsLairActive();
  }
  if lane == CBLaneApex() {
    return NotEquals(sys.GetPendingApexFaction(), n"") || CBLiveTaggedPresent(game, n"CB_Apex");
  }
  // A scout out looking holds the crew lane: the crew is waiting on what the scout finds.
  return NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetScoutFaction(), n"")
      || CBLiveTaggedPresent(game, n"CB_Squad");
}

// Is anyone wearing this tag still alive?
//
// IsPopulated counts tagged entities, and the tag stays on the body after death until the
// despawn sweep clears it minutes later. So wiping a crew left its lane blocked and the next
// gang could not be queued - the same mistake that was fixed for Rivals and missed here.
// Clearing a squad should free its lane the moment the last one goes down.
//
// Escaping them frees it too, just not instantly: they stay alive and tagged until the sweep
// removes them, which is the honest reading - you lost them, they are still out there.
// How many of them are alive. Same walk as CBLiveTaggedPresent, which answers the cheaper
// question and stops at the first one; this one has to count, so it is kept separate rather
// than making every caller of the common case pay for a full pass.
public func CBCountLiveTagged(game: GameInstance, tag: CName) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return 0;
  }
  let ids = des.GetTaggedIDs(tag);
  let n = 0;
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) {
      n += 1;
    }
  }
  return n;
}

// As above, leaving one body out of the count: the one whose death is being handled.
public func CBCountLiveTaggedExcept(game: GameInstance, tag: CName, except: EntityID) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return 0;
  }
  let ids = des.GetTaggedIDs(tag);
  let n = 0;
  let i = 0;
  while i < ArraySize(ids) {
    if NotEquals(ids[i], except) {
      let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
      if CBStillStanding(p) {
        n += 1;
      }
    }
    i += 1;
  }
  return n;
}

public func CBLiveTaggedPresent(game: GameInstance, tag: CName) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let ids = des.GetTaggedIDs(tag);
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if CBStillStanding(p) {
      return true;
    }
  }
  return false;
}

// All three lanes, once per fast tick.
public func CBEncounterQueueTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  CBScheduleTick(sys, game);   // a new in-game day gets a new timetable
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  CBRivalCooldownTick(sys);
  CBLaneTick(sys, game, CBLaneRival());
  CBLaneTick(sys, game, CBLaneSquad());
  CBLaneTick(sys, game, CBLaneApex());
}

// Run down every Rival's personal cooldown. Cheap: a counter per Rival, capped at fifteen.
func CBRivalCooldownTick(sys: ref<CyberbaneSystem>) -> Void {
  for r in sys.GetRivals() {
    if IsDefined(r) && r.huntTicks > 0 {
      r.huntTicks -= 1;
    }
  }
}

// Somebody from a gang V has actually fought, when the Rival list has nobody to offer.
//
// Picks the gang with the most history: the one whose people V has put down most often is the
// one most likely to send somebody after them. The record is the one already sampled from a
// real enemy of that gang, which is the same source a hit squad draws from, so nothing here
// invents a character the game would not otherwise produce.
func CBSeedRivalFromFactions(sys: ref<CyberbaneSystem>, game: GameInstance) -> ref<CBRival> {
  if !CBRivalsOn() {
    return null;
  }
  let best: ref<CBFactionState>;
  let bestKills = 0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) && CBFactionFieldsSquads(fs.id)
       && fs.kills > bestKills {
      best = fs;
      bestKills = fs.kills;
    }
  }
  if !IsDefined(best) {
    return null;   // V has not fought anybody yet; there is genuinely nobody to send
  }
  let r = CBCreateRival(sys, game, best.id, best.sampleRecord, n"", ECBRivalSource.Hunter,
                        CBEventDistrict(sys, game), CBGameSeconds(game));
  if IsDefined(r) {
    CBLog.Info(n"Spawn", s"No Rival on the books; \(NameToString(best.id)) put somebody forward.");
  }
  return r;
}

// Can this Rival still be sent? The one test, used by the picker and by the lane's re-check,
// so the two can never disagree about who is eligible.
public func CBRivalQueueable(sys: ref<CyberbaneSystem>, rivalId: Int32) -> Bool {
  let r = sys.FindRivalById(rivalId);
  if !IsDefined(r) || !TDBID.IsValid(r.recordID) || !CBRecordIsPerson(r.recordID) {
    return false;
  }
  return r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting);
}

func CBLaneTick(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Void {
  let provokedOnly = false;
  // Their kind is already happening. The clock does not run down during the fight they are
  // waiting on - nobody should be queuing up behind an encounter you are still in.
  if CBLaneBusy(sys, game, lane) {
    sys.MarkLaneBusy(lane);
    return;
  }
  // Nobody can arrive right now (a safe area, a job, a scene): the clock waits with them.
  if CBArrivalsHeld(sys, game) {
    return;
  }
  // And a breather afterwards.
  //
  // Measured from the end of the last encounter in this lane rather than from when it was
  // sent, so a long fight does not eat the gap. Without it a lane re-armed the instant the
  // last body dropped and the next one was on its way before you had holstered, which reads
  // as harassment instead of a city reacting to you.
  //
  // Only applies to picking somebody new. A lane that already has somebody on the clock keeps
  // counting.
  if sys.GetLaneTicks(lane) <= 0 && Equals(sys.GetLaneTarget(lane), n"") && sys.GetLaneRivalId(lane) <= 0 {
    // Nothing starts unless the day's timetable says this kind is due (Spawn/Schedule.reds).
    // That is what gives a day a shape instead of leaving it to however long the player
    // happened to stay in one.
    // A provoked gang does not wait for the timetable: what V just did is the reason they are
    // coming. The day's allowance and the rest below still apply.
    let provoked = lane == CBLaneSquad() && NotEquals(sys.GetProvoked(), n"");
    let slotDue = CBPacingDue(sys, game, lane);
    if !slotDue && !provoked {
      return;
    }
    // Off the timetable, only the gang that was provoked may answer. Without this a provocation
    // could open the lane for whichever gang happened to score highest.
    provokedOnly = !slotDue;
    // The timetable is built from the per-day setting, so this should never bite. It is here
    // because the setting is the player's instruction and a scheduling bug must not be able to
    // exceed it: whatever the plan says, the count is the ceiling.
    if CBLaneBudgetLeft(sys, game, lane) <= 0 {
      return;
    }
    // The spacing floor still applies on top. At default settings the slots are about an hour
    // of real play apart and it never binds; it only matters if the per-day sliders are pushed
    // high enough that two windows in one sector crowd each other.
    if CBLaneRestLeft(sys, lane) > 0 {
      return;
    }
  }
  // Is the person this lane is holding still somebody who can turn up?
  //
  // The lane records a Rival's id when it picks them and then only counts down. If that Rival
  // is spared, retired or promoted out of the running in the meantime, the lane kept counting
  // toward somebody the Rivals screen no longer lists, which is why the INCOMING line could
  // name a Rival who did not appear on the Rivals tab at all. Re-checking each tick costs one
  // lookup and lets the lane pick somebody who can actually come.
  if sys.GetLaneRivalId(lane) > 0 && !CBRivalQueueable(sys, sys.GetLaneRivalId(lane)) {
    sys.ClearLane(lane);
    return;
  }
  if sys.GetLaneTicks(lane) > 0 || NotEquals(sys.GetLaneTarget(lane), n"") || sys.GetLaneRivalId(lane) > 0 {
    if sys.TickDownLane(lane) > 0 {
      return;
    }
    CBLaneFire(sys, game, lane);
    return;
  }
  CBLanePick(sys, game, lane, provokedOnly);
}

// Choose who has most earned this lane's next turn, and start their clock.
//
// Scored rather than cycled, so the order means something: a gang that has sworn a vendetta
// outranks one that merely dislikes you, and a Rival who has got away from you repeatedly
// outranks a new one. Scoring is within the lane only, so the three never compete.
func CBLanePick(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32, opt provokedOnly: Bool) -> Void {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  let now = CBGameSeconds(game);
  let factionCooldown = CBConfig.HitSquadFactionCooldownDays() * CBConfig.SecondsPerDay();
  let bestScore = 0.0;
  let bestFaction = n"";
  let bestRival = 0;
  let turf = CBTurfGangsHere(sys);

  if lane == CBLaneRival() {
    if !CBRivalsOn() {
      return;
    }
    for r in sys.GetRivals() {
      // huntTicks is this Rival's own cooldown now rather than their scheduler: it is set when
      // you escape one, so somebody you just shook cannot be picked again straight away.
      // Without honouring it here, escaping would have gone back to meaning nothing, which is
      // the bug that hollowed out the nemesis loop in the first place.
      if IsDefined(r) && TDBID.IsValid(r.recordID) && r.huntTicks <= 0
         && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        let s = CBConfig.QueueScoreRival()
              + Cast<Float>(r.rank) * 8.0
              + Cast<Float>(r.escapes) * 4.0
              + Cast<Float>(r.encounters) * 2.0;
        // A Grudge-Bearer is the one who comes first; it is the whole of what they are about.
        if CBRivalHasTrait(r, n"GrudgeBearer") {
          s += CBConfig.QueueGrudgeBonus();
        }
        // On their own gang's streets they are easier to run into, and easier still where they
        // came from: they know those streets.
        if ArrayContains(turf, r.faction) {
          s += CBConfig.RivalTurfBonus();
        }
        if NotEquals(r.origin, n"") && Equals(r.origin, sys.GetCurrentDistrict()) {
          s += CBConfig.RivalHomeBonus();
        }
        // Not the same person twice in a row while somebody else is owed a turn.
        if r.id == sys.GetLaneLastRival() {
          s -= CBConfig.QueueRepeatPenalty();
        }
        if s > bestScore {
          bestScore = s; bestRival = r.id; bestFaction = r.faction;
        }
      }
    }
  } else {
    if !CBHitSquadsOn() {
      return;
    }
    for fs in sys.GetFactionStates() {
      // The law is not a gang and does not send crews; it has heat and MaxTac for that.
      if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) && CBFactionFieldsSquads(fs.id) {
        let posture = score.GetPosture(fs.id);
        let hate = ClampF((-fs.standing / 100.0) * (fs.renown / 100.0), 0.0, 1.0);
        let s = 0.0;
        if lane == CBLaneApex() {
          if CBApexEligible(sys, fs) {
            s = CBConfig.QueueScoreApex() + hate * 20.0;
          }
        } else {
          let offCooldown = fs.lastHitSquadAt <= 0.0 || (now - fs.lastHitSquadAt) >= factionCooldown;
          // A crew needs a reason to come today, not only a grudge (CBCrewReason).
          let reason = CBCrewReason(sys, fs, posture, ArrayContains(turf, fs.id), now);
          if offCooldown && fs.renown >= CBConfig.HitSquadMinRenown() && reason >= 0.0
             && (!provokedOnly || Equals(fs.id, sys.GetProvoked())) {
            if Equals(posture, ECBPosture.Vendetta) {
              s = CBConfig.QueueScoreVendetta() + hate * 30.0 + reason;
            } else {
              if Equals(posture, ECBPosture.Hostile) {
                s = CBConfig.QueueScoreHostile() + hate * 30.0 + reason;
              }
            }
          }
        }
        if s > 0.0 && Equals(fs.id, sys.GetLaneLastFaction(lane)) {
          s -= CBConfig.QueueRepeatPenalty();
        }
        // The gang V has just provoked goes first.
        if s > 0.0 && lane == CBLaneSquad() && Equals(fs.id, sys.GetProvoked()) {
          s += CBConfig.QueueProvokedBonus();
        }
        if s > bestScore {
          bestScore = s; bestFaction = fs.id; bestRival = 0;
        }
      }
    }
  }

  // Nobody on the books. Make somebody, rather than going quiet.
  //
  // Rivals exist only once enemies have escaped V or been spared, so a fresh save - or one
  // whose state was reset by a mod update - has none at all, and the Rival lane then sits
  // silent through the whole opening of a playthrough. From the player's side that is a mod
  // that does nothing, and it is exactly what happened here: six state resets in an afternoon
  // left an empty roster every time and the lane had nobody to pick.
  //
  // So when the lane's turn comes and the roster cannot supply anyone, the gang V has actually
  // been fighting supplies one instead. It uses the record already sampled from a real enemy
  // of theirs, so the person who turns up is somebody that gang would plausibly send, and it
  // needs nothing the player has not already done: hit a gang once and they can answer.
  if bestScore <= 0.0 && lane == CBLaneRival() {
    let seeded = CBSeedRivalFromFactions(sys, game);
    if IsDefined(seeded) {
      bestScore = CBConfig.QueueScoreRival();
      bestRival = seeded.id;
      bestFaction = seeded.faction;
    }
  }
  if bestScore <= 0.0 {
    // Still nobody. Said out loud once a minute at most, because a lane that is due and silent
    // is indistinguishable from a lane that is broken, and that ambiguity has now cost several
    // rounds of looking in the wrong place.
    if (sys.GetTickCount() - sys.GetLaneQuietLogged(lane)) > 60 {
      sys.SetLaneQuietLogged(lane, sys.GetTickCount());
      CBLog.Info(n"Spawn", s"\(CBLaneLabel(lane)) lane is due but nobody qualifies (no gang has been fought yet, or everyone is on cooldown).");
    }
    return;
  }
  let ticks = CBLaneTicksFor(sys, lane, bestFaction, bestRival);
  let provokedPick = lane == CBLaneSquad() && Equals(bestFaction, sys.GetProvoked());
  if provokedPick {
    ticks = CBConfig.QueueMinTicks();   // they are already on it
    sys.ClearProvoked();
  }
  sys.SetLaneQueued(lane, bestFaction, bestRival, ticks);
  // Somebody starts asking around. A provoked gang already knows where V is, so it skips this.
  if !provokedPick {
    CBTrackingNotice(sys, game, lane, bestFaction, bestRival);
  }
  CBLog.Info(n"Spawn", s"Next \(CBLaneLabel(lane)): \(NameToString(bestFaction)) in \(sys.GetLaneTicks(lane)) ticks.");
}

// How long this one takes to reach you.
func CBLaneTicksFor(sys: ref<CyberbaneSystem>, lane: Int32, faction: CName, rivalId: Int32) -> Int32 {
  let freq = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    freq = rt.GetSettings().hitSquadFrequencyMult;
  }
  let ticks = CBConfig.HostileSquadTicksMax();
  if lane == CBLaneRival() {
    let r = sys.FindRivalById(rivalId);
    ticks = IsDefined(r) ? CBRivalHuntTicksFor(r.rank, CBRivalsAtCap(sys)) : CBConfig.RivalHuntTicksBase();
  } else {
    if lane == CBLaneApex() {
      ticks = CBJitter(CBConfig.ApexQueueTicks(), CBConfig.QueueJitterFraction());
    } else {
      let fs = sys.FindFaction(faction);
      let hate = IsDefined(fs) ? ClampF((-fs.standing / 100.0) * (fs.renown / 100.0), 0.0, 1.0) : 0.0;
      let span = Cast<Float>(CBConfig.HostileSquadTicksMax() - CBConfig.HostileSquadTicksMin());
      ticks = CBJitter(CBConfig.HostileSquadTicksMax() - FloorF(span * hate), CBConfig.QueueJitterFraction());
    }
  }
  if freq > 0.01 {
    ticks = FloorF(Cast<Float>(ticks) / freq);
  }
  if ticks < CBConfig.QueueMinTicks() {
    ticks = CBConfig.QueueMinTicks();
  }
  return ticks;
}

// Their turn. Hand off to the system that knows how to bring them in.
func CBLaneFire(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Void {
  let faction = sys.GetLaneTarget(lane);
  let now = CBGameSeconds(game);

  if lane == CBLaneRival() {
    let r = sys.FindRivalById(sys.GetLaneRivalId(lane));
    // They tell you first, and you get a little time. The lane's clock runs again for the
    // warning, and the arrival is the next time it reaches zero.
    if IsDefined(r) && sys.GetRivalWarned() != r.id {
      sys.SetRivalWarned(r.id);
      sys.SetLaneTicks(lane, CBWarningTicks(CBConfig.RivalWarningTicks()));
      sys.SetHuntGrade("RIVAL");
      CBHuntBegin(sys, game, r.faction);
      CBRivalWarning(sys, game, r);
      return;
    }
    sys.SetRivalWarned(0);
    if !IsDefined(r) || !CBSpawnRival(sys, game, r, now) {
      // Could not be placed. Put this one on their own cooldown and let the lane go.
      //
      // It used to keep their turn and retry on the spot, which is fine when the refusal is
      // momentary and a trap when it is not: a Rival the world will not accept held the lane
      // indefinitely, the Hub said "any moment" the whole time, and every other Rival sat
      // behind them saying they were waiting their turn. Releasing the lane lets the picker
      // choose somebody else next tick, and it skips this one while their cooldown runs, so
      // the queue keeps moving. If nobody else can go either, the same one comes back round.
      if IsDefined(r) {
        r.huntTicks = CBConfig.RivalHuntRetryTicks();
      }
      sys.ClearLane(lane);
      return;
    }
    sys.SetLaneLastRival(sys.GetLaneRivalId(lane));
    CBSpendSlot(sys, game, lane);
    sys.NoteLaneSent(lane, CBGameDay(game));
    sys.SetLaneFired(lane);
  } else {
    // Zero ticks and then run the dispatch straight away, in this same tick, so they arrive
    // the moment the clock reaches zero rather than a second or two later. The dispatch keeps
    // all its own handling for cars, interiors, quiet jobs and giving up; this only removes
    // the hand-off delay, which served no purpose except to make a finished timer look stuck.
    // On their way, with a warning and a countdown, rather than standing behind V the moment
    // the clock runs out. The pending countdowns already hold for a safe area, a quiet job or a
    // fight in progress, and bring them in when they reach zero.
    CBHuntBegin(sys, game, faction);
    if lane == CBLaneApex() {
      sys.SetPendingApex(faction, CBWarningTicks(CBConfig.ApexWarningTicks()));
      sys.SetHuntGrade("APEX SQUAD");
      sys.ClearCrewBeaten(faction);   // the beaten crew has been answered
      CBApexOnTheWay(sys, game, faction);
    } else {
      // A gang that does not know where V is may send one person to look first (Spawn/Hunt.reds).
      // The crew then only comes if the scout finds V.
      if !CBTrySendScout(sys, game, faction) {
        sys.SetPendingSquad(faction, CBWarningTicks(CBConfig.CrewWarningTicks()));
        sys.SetHuntGrade(CBCrewGrade(sys, faction));
        CBCrewWarning(sys, game, faction);
      }
    }
    sys.SetLaneLastFaction(lane, faction);
    CBSpendSlot(sys, game, lane);
    sys.NoteLaneSent(lane, CBGameDay(game));
    sys.SetLaneFired(lane);
  }
  sys.ClearLane(lane);
}

public func CBLaneLabel(lane: Int32) -> String {
  if lane == CBLaneRival() {
    return "rival";
  }
  if lane == CBLaneApex() {
    return "apex squad";
  }
  return "crew";
}

// Shared switches, so the lanes honour the same settings the old schedulers did.
public func CBHitSquadsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().hitSquads {
    return false;
  }
  return !CBTwrActive();
}

// How many encounters this lane is allowed to send in one in-game day.
//
// This is the real pacing control. Before it, a lane sent somebody every time its gap elapsed
// and kept doing so for ever, so the only thing deciding how busy a day was was how long the
// player stayed in one. A day now has a shape: a few Rivals, a couple of crews, a couple of
// apex squads, and once a lane has spent its allowance it is quiet until tomorrow. The gap
// below still applies on top, so the day's allowance cannot all arrive at once.
public func CBLaneDailyCap(lane: Int32) -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    if lane == CBLaneRival() { return CBConfig.RivalsPerDayDefault(); }
    if lane == CBLaneApex() { return CBConfig.ApexSquadsPerDayDefault(); }
    return CBConfig.HitSquadsPerDayDefault();
  }
  let s = rt.GetSettings();
  if lane == CBLaneRival() { return s.rivalsPerDay; }
  if lane == CBLaneApex() { return s.apexSquadsPerDay; }
  return s.hitSquadsPerDay;
}

// How many this lane has left today.
public func CBLaneBudgetLeft(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Int32 {
  let left = CBLaneDailyCap(lane) - sys.LaneSentToday(lane, CBGameDay(game));
  return left < 0 ? 0 : left;
}

// How long this lane still has to rest before it may pick anybody, in ticks. Zero when it is
// free to go.
//
// The stamp and the tick counter both start at zero on a fresh session, so the old arithmetic
// read "nothing has happened for no time at all" as "this lane finished an encounter a moment
// ago" and sat out the full gap - ten real minutes of silence after every single load, in all
// three lanes, with the Hub reporting that the lane was due and nobody qualified while eleven
// Rivals waited their turn. A lane that has never been busy has nothing to rest from.
public func CBLaneRestLeft(sys: ref<CyberbaneSystem>, lane: Int32) -> Int32 {
  if !IsDefined(sys) || sys.GetLaneFreed(lane) <= 0 {
    return 0;
  }
  let left = CBEncounterGapTicks() - (sys.GetTickCount() - sys.GetLaneFreed(lane));
  return left > 0 ? left : 0;
}

// How long a lane rests after its encounter ends, in ticks of about a second.
public func CBEncounterGapTicks() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  let mins = CBConfig.EncounterGapMinutesDefault();
  if IsDefined(rt) && rt.HasSettings() {
    mins = rt.GetSettings().encounterGapMinutes;
  }
  return mins * 60;
}

public func CBRivalsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().rivals;
}

// ---- What it takes ----------------------------------------------------------------
//
// "It feels like an arbitrary timer." The day's timetable says when the city has time for V; it
// should not be the reason anybody comes. These are the reasons.
//
// A crew comes from a gang that is hostile, knows V well enough (HitSquadMinRenown), has not sent
// one in the last couple of days, and has a reason today:
//   - a vendetta, which is a standing reason;
//   - V provoked them (a witnessed kill of their people, Model/Reputation.reds);
//   - V has been hanging around on their turf and a lookout called it in (CBTurfWatchTick);
//   - V has hurt them recently (CrewReasonHours).
// A gang that hates V but has not seen or heard of V in a day keeps its people at home.
//
// An apex squad is the gang's answer to V beating its people: it comes from a hostile gang that
// has lost enough of its own since its last apex (ApexKillThreshold), after V has beaten one of
// its crews, or with no crew in between once the bodies reach a massacre
// (ApexMassacreMultiplier times the threshold). The beaten crew is remembered for the session.
// So the ladder reads: hurt a gang and get seen, a crew comes; beat the crew, their best comes.

// The gangs whose turf V is standing on. Usually one, sometimes two, often none.
public func CBTurfGangsHere(sys: ref<CyberbaneSystem>) -> array<CName> {
  let out: array<CName>;
  if !IsDefined(sys) {
    return out;
  }
  let content = sys.GetContent();
  let district = sys.GetCurrentDistrict();
  if !IsDefined(content) || Equals(district, n"") {
    return out;
  }
  for prof in content.GetFactions() {
    if IsDefined(prof) && prof.isGang && ArrayContains(prof.turf, district) {
      ArrayPush(out, prof.id);
    }
  }
  return out;
}

// Why this gang would send a crew now: a score bonus of zero or more, or -1 for no reason.
public func CBCrewReason(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>, posture: ECBPosture,
                         onTheirTurf: Bool, now: Float) -> Float {
  if !IsDefined(sys) || !IsDefined(fs) {
    return -1.0;
  }
  let bonus = 0.0;
  let reason = false;
  if Equals(posture, ECBPosture.Vendetta) {
    reason = true;
  }
  if Equals(fs.id, sys.GetProvoked()) {
    reason = true;
  }
  if onTheirTurf {
    reason = true;
    bonus += CBConfig.QueueTurfBonus();
  }
  let window = CBConfig.CrewReasonHours() * CBConfig.SecondsPerHour();
  if fs.lastIncidentAt > 0.0 && window > 0.0 && now >= fs.lastIncidentAt
     && (now - fs.lastIncidentAt) < window {
    reason = true;
    // Fresher trouble, stronger reason.
    bonus += CBConfig.QueueRecentBonus() * (1.0 - (now - fs.lastIncidentAt) / window);
  }
  return reason ? bonus : -1.0;
}

// The record an apex squad from this gang would be built from: their toughest if V has met one,
// otherwise whoever V has been fighting. The same rule CBProcessPendingApex spawns with.
public func CBApexRecordFor(fs: ref<CBFactionState>) -> TweakDBID {
  if !IsDefined(fs) {
    return TDBID.None();
  }
  return TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
}

// Has this gang earned the right to send its best? One test for the lane, the warning text and
// the Hub, so none of them can promise an apex squad another will not send.
public func CBApexEligible(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> Bool {
  if !IsDefined(sys) || !IsDefined(fs) || !CBFactionFieldsSquads(fs.id)
     || !TDBID.IsValid(CBApexRecordFor(fs)) {
    return false;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return false;
  }
  let posture = score.GetPosture(fs.id);
  if NotEquals(posture, ECBPosture.Hostile) && NotEquals(posture, ECBPosture.Vendetta) {
    return false;   // a gang V is square with does not send its best
  }
  let since = fs.kills - fs.apexAtKills;
  if since < CBConfig.ApexKillThreshold() {
    return false;
  }
  return sys.CrewBeaten(fs.id)
      || since >= CBConfig.ApexKillThreshold() * CBConfig.ApexMassacreMultiplier();
}

// What the Hub says about this gang's apex squad when nothing is on its way.
public func CBApexProgressLine(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> String {
  if !IsDefined(sys) || !IsDefined(fs) {
    return "";
  }
  let score = sys.GetScore();
  let posture = IsDefined(score) ? score.GetPosture(fs.id) : ECBPosture.Neutral;
  if NotEquals(posture, ECBPosture.Hostile) && NotEquals(posture, ECBPosture.Vendetta) {
    return "";
  }
  if CBApexEligible(sys, fs) {
    return "ready to send their best";
  }
  let since = fs.kills - fs.apexAtKills;
  let toApex = CBConfig.ApexKillThreshold() - since;
  if toApex > 0 {
    return s"apex squad in \(toApex) kills";
  }
  // Enough bodies, no beaten crew yet.
  let toMassacre = CBConfig.ApexKillThreshold() * CBConfig.ApexMassacreMultiplier() - since;
  return s"beat a crew, or \(toMassacre) more kills";
}

// A crew of this gang has just been wiped out. Remember it, so their best comes next, and let
// them say so.
public func CBOnCrewBeaten(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") {
    return;
  }
  sys.SetActiveSquadFaction(n"");   // nobody left to have escaped
  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  sys.NoteCrewBeaten(faction);
  CBLog.Info(n"Spawn", s"Crew from \(NameToString(faction)) wiped out; their apex squad is next in line.");
  // Somebody is glad to see that crew gone, and pays for it (Spawn/Loot.reds).
  let crewLabel = CBFactionLabel(faction);
  CBPayBounty(sys, game, faction, RoundF(Cast<Float>(CBConfig.BountyCrew()) * CBLootLevelScale(game) / 50.0) * 50,
              StrLen(crewLabel) > 0 ? s"Heard you dealt with \(crewLabel)'s crew." : "Heard you dealt with that crew.");
  // Only promise what can follow: a gang that fields an apex, while the apex lane is on and
  // nothing is already on its way.
  if !CBToastsOn() || !CBHitSquadsOn() || CBLaneDailyCap(CBLaneApex()) <= 0
     || !TDBID.IsValid(CBApexRecordFor(fs)) || NotEquals(sys.GetPendingApexFaction(), n"") {
    return;
  }
  let name = CBApexName(CBContent(game), faction, fs.apexAtKills);
  if CBApexEligible(sys, fs) {
    CBPhoneFromGang(game, faction, s"That was our crew. Next time it is \(name), and three more like them.");
  } else {
    CBPhoneFromGang(game, faction, s"That was our crew. Keep it up and you meet \(name).");
  }
}

// Hanging around on a hostile gang's streets gets noticed.
//
// The NCPD half of being hunted: do something, or simply be somewhere you should not, and
// somebody calls it in. After TurfLingerTicks on the turf of a gang that wants V dead, out in the
// open and not sneaking, a lookout calls it in, which provokes that gang (Spawn/Hunt.reds) and
// lets its crew come off the timetable. One lookout per TurfSpotCooldownTicks at most. Called
// every five ticks.
public func CBTurfWatchTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !CBHitSquadsOn() || !CBWorldStable(game) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  let now = sys.GetTickCount();
  let player = GetPlayer(game);
  if !IsDefined(player) || sys.IsInSafeZone() || sys.IsInQuestArea() || CBPlayerInStealthState(game)
     || sys.GetStoryHold() != CBStoryNone()
     || NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetProvoked(), n"") {
    sys.SetTurfWatch(n"", now);
    return;
  }
  // The worst gang whose streets these are.
  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  let owner = n"";
  let worst = 0.0;
  let turf = CBTurfGangsHere(sys);
  for id in turf {
    let posture = score.GetPosture(id);
    if CBFactionFieldsSquads(id)
       && (Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta)) {
      let st = score.GetStanding(id);
      if Equals(owner, n"") || st < worst {
        owner = id;
        worst = st;
      }
    }
  }
  if Equals(owner, n"") {
    sys.SetTurfWatch(n"", now);
    return;
  }
  if NotEquals(owner, sys.GetTurfWatchFaction()) {
    sys.SetTurfWatch(owner, now);
    return;
  }
  if (now - sys.GetTurfWatchSince()) < CBConfig.TurfLingerTicks() || now < sys.GetTurfSpotNext() {
    return;
  }
  CBProvoke(sys, game, owner);
  sys.SetTurfSpotNext(now + CBConfig.TurfSpotCooldownTicks());
  sys.SetTurfWatch(owner, now);
  CBLog.Info(n"Spawn", s"A lookout for \(NameToString(owner)) spotted V on their turf.");
}

// ---- Pacing without a clock ------------------------------------------------------
//
// "I eventually kept a mental clock in my head." Three things fed that clock: windows on a daily
// timetable, countdowns that were the same length every time, and the exact times on the Hub and
// the HUD. The windows are now one of three pacing modes, every countdown and warning varies, and
// the times can be turned into words (UI/Hud.reds, CBTimeText).

public func CBPacing() -> ECBPacing {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return ECBPacing.Timetable;
  }
  return rt.GetSettings().pacing;
}

// Is this lane allowed to pick somebody this tick? The day's allowance, the rest between
// encounters and the reasons a gang needs are all still checked by the caller.
public func CBPacingDue(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Bool {
  let mode = CBPacing();
  if Equals(mode, ECBPacing.Timetable) {
    return CBSlotDue(sys, game, lane);
  }
  if Equals(mode, ECBPacing.Reactive) {
    if lane == CBLaneSquad() {
      return false;   // a crew only comes when provoked, which the caller lets through
    }
    if lane == CBLaneApex() {
      return true;    // an apex squad only ever comes for a gang that has earned it
    }
  }
  // Unpredictable, and Rivals under Reactive: a small chance every second, so that the day's
  // allowance is spread over about a day of play with no pattern to it.
  let cap = CBLaneDailyCap(lane);
  if cap <= 0 {
    return false;
  }
  let p = Cast<Float>(cap) / Cast<Float>(Max(1, CBConfig.UnpredictableDayTicks()));
  return RandF() < p * CBTimeOfDayPacing(game, lane);
}

public func CBIsNight(game: GameInstance) -> Bool {
  let h = CBGameHourOfDay(game);
  return h >= CBConfig.NightStartHour() || h < CBConfig.NightEndHour();
}

// Crews and Rivals come more often after dark; an apex squad, sent to be seen, favours the day.
func CBTimeOfDayPacing(game: GameInstance, lane: Int32) -> Float {
  let night = CBIsNight(game);
  if lane == CBLaneApex() {
    return night ? CBConfig.DayPacingMult() : CBConfig.NightPacingMult();
  }
  return night ? CBConfig.NightPacingMult() : CBConfig.DayPacingMult();
}

// A count of ticks, varied by up to `frac` either way. Never below one.
public func CBJitter(ticks: Int32, frac: Float) -> Int32 {
  if ticks <= 0 || frac <= 0.0 {
    return ticks;
  }
  let span = RoundF(Cast<Float>(ticks) * frac);
  if span <= 0 {
    return ticks;
  }
  return Max(1, ticks + RandRange(-span, span + 1));
}

// How long a warning lasts: varied, and longer on harder difficulties so there is time to get
// ready.
public func CBWarningTicks(base: Int32) -> Int32 {
  return CBJitter(base, CBConfig.WarningJitterFraction())
       + CBConfig.DifficultyWarningExtra() * CBDifficultyLevel();
}

// ---- Being tracked -----------------------------------------------------------------
//
// "If it warned me I was being actively tracked." Before anybody sets off, somebody starts asking
// around about V. Either the local broker texts, or V overhears it, never both. The HUD line
// shows TRACKED while it lasts. It says nothing about how long.
public func CBTrackingNotice(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32,
                             faction: CName, rivalId: Int32) -> Void {
  if !IsDefined(sys) || !CBToastsOn() || !sys.TakeTrackNotice(lane, CBConfig.TrackNoticeGapTicks()) {
    return;
  }
  let who = "";
  if lane == CBLaneRival() {
    let r = sys.FindRivalById(rivalId);
    let content = CBContent(game);
    if IsDefined(r) && IsDefined(content) {
      who = CBRivalDisplayName(content, r);
    }
  } else {
    who = CBFactionLabel(faction);
  }
  if StrLen(who) == 0 {
    return;
  }
  let line = "";
  if lane == CBLaneApex() {
    line = s"\(who) are asking about you, and not their usual people.";
  } else {
    if lane == CBLaneRival() {
      line = s"\(who) has been asking around about you.";
    } else {
      switch RandRange(0, 3) {
        case 0: line = s"Somebody from \(who) was asking where you drink."; break;
        case 1: line = s"\(who) are asking questions about you."; break;
        default: line = s"Your name came up with \(who). They want to know where you are."; break;
      }
    }
  }
  if RandF() < 0.6 || NotEquals(CBMessageDelivery(), ECBMessageDelivery.Phone) {
    let district = sys.GetCurrentDistrict();
    if NotEquals(district, n"") {
      CBPhoneFromDistrict(game, district, line);
    } else {
      CBPhoneFromStreet(game, line);
    }
  } else {
    CBOverheard(game, "Passer-by", line);
  }
}

// ---- How big a threat ----------------------------------------------------------------

// How many a crew from this gang would be. The one formula, used by the spawn and by the warning,
// so the warning never promises a different number from the one that turns up.
public func CBCrewSizeFor(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>, infamous: Bool) -> Int32 {
  if !IsDefined(sys) || !IsDefined(fs) {
    return 3;
  }
  let size = 3 + FloorF(-fs.standing / 35.0);
  if size > 6 {
    size = 6;
  }
  if infamous {
    size += 1;
  }
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
  // Harder difficulty means harder fights, not instant deaths: a little smaller.
  return Max(2, size - CBConfig.DifficultyCrewTrim() * CBDifficultyLevel());
}

func CBCrewIsInfamous(sys: ref<CyberbaneSystem>) -> Bool {
  let score = sys.GetScore();
  return IsDefined(score) && EnumInt(score.GetTier()) >= EnumInt(ECBRenownTier.Infamous);
}

// One word for how bad this is, shown on the HUD line and the Hub.
public func CBCrewGrade(sys: ref<CyberbaneSystem>, faction: CName) -> String {
  if !IsDefined(sys) {
    return "CREW";
  }
  let fs = sys.FindFaction(faction);
  let size = CBCrewSizeFor(sys, fs, CBCrewIsInfamous(sys));
  return size >= 5 ? "HEAVY CREW" : "CREW";
}

public func CBNumberWord(n: Int32) -> String {
  switch n {
    case 1: return "One";
    case 2: return "Two";
    case 3: return "Three";
    case 4: return "Four";
    case 5: return "Five";
    case 6: return "Six";
    case 7: return "Seven";
    case 8: return "Eight";
    default: return s"\(n)";
  }
}
