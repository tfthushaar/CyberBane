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
  if (sys.GetTickCount() - sys.GetLaneFired(lane)) < CBConfig.LaneSettleTicks() {
    return true;
  }
  if lane == CBLaneRival() {
    return CBLiveRivalPresent(sys, game);
  }
  if lane == CBLaneApex() {
    return NotEquals(sys.GetPendingApexFaction(), n"") || CBLiveTaggedPresent(game, n"CB_Apex");
  }
  return NotEquals(sys.GetPendingSquadFaction(), n"") || CBLiveTaggedPresent(game, n"CB_Squad");
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

// Can this Rival still be sent? The one test, used by the picker and by the lane's re-check,
// so the two can never disagree about who is eligible.
public func CBRivalQueueable(sys: ref<CyberbaneSystem>, rivalId: Int32) -> Bool {
  let r = sys.FindRivalById(rivalId);
  if !IsDefined(r) || !TDBID.IsValid(r.recordID) {
    return false;
  }
  return r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting);
}

func CBLaneTick(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Void {
  // Their kind is already happening. The clock does not run down during the fight they are
  // waiting on - nobody should be queuing up behind an encounter you are still in.
  if CBLaneBusy(sys, game, lane) {
    sys.MarkLaneBusy(lane);
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
    if (sys.GetTickCount() - sys.GetLaneFreed(lane)) < CBEncounterGapTicks() {
      return;
    }
    // And the day's allowance. Spent, so nothing more of this kind until tomorrow.
    if CBLaneBudgetLeft(sys, game, lane) <= 0 {
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
  CBLanePick(sys, game, lane);
}

// Choose who has most earned this lane's next turn, and start their clock.
//
// Scored rather than cycled, so the order means something: a gang that has sworn a vendetta
// outranks one that merely dislikes you, and a Rival who has got away from you repeatedly
// outranks a new one. Scoring is within the lane only, so the three never compete.
func CBLanePick(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Void {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  let now = CBGameSeconds(game);
  let factionCooldown = CBConfig.HitSquadFactionCooldownDays() * CBConfig.SecondsPerDay();
  let bestScore = 0.0;
  let bestFaction = n"";
  let bestRival = 0;

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
      if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
        let posture = score.GetPosture(fs.id);
        let hate = ClampF((-fs.standing / 100.0) * (fs.renown / 100.0), 0.0, 1.0);
        let s = 0.0;
        if lane == CBLaneApex() {
          if TDBID.IsValid(fs.eliteRecord)
             && (fs.kills - fs.apexAtKills) >= CBConfig.ApexKillThreshold() {
            s = CBConfig.QueueScoreApex() + hate * 20.0;
          }
        } else {
          let offCooldown = fs.lastHitSquadAt <= 0.0 || (now - fs.lastHitSquadAt) >= factionCooldown;
          if offCooldown && fs.renown >= CBConfig.HitSquadMinRenown() {
            if Equals(posture, ECBPosture.Vendetta) {
              s = CBConfig.QueueScoreVendetta() + hate * 30.0;
            } else {
              if Equals(posture, ECBPosture.Hostile) {
                s = CBConfig.QueueScoreHostile() + hate * 30.0;
              }
            }
          }
        }
        if s > 0.0 && Equals(fs.id, sys.GetLaneLastFaction(lane)) {
          s -= CBConfig.QueueRepeatPenalty();
        }
        if s > bestScore {
          bestScore = s; bestFaction = fs.id; bestRival = 0;
        }
      }
    }
  }

  if bestScore <= 0.0 {
    return;   // nobody in this lane has a reason to come for you
  }
  sys.SetLaneQueued(lane, bestFaction, bestRival, CBLaneTicksFor(sys, lane, bestFaction, bestRival));
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
      ticks = CBConfig.ApexQueueTicks();
    } else {
      let fs = sys.FindFaction(faction);
      let hate = IsDefined(fs) ? ClampF((-fs.standing / 100.0) * (fs.renown / 100.0), 0.0, 1.0) : 0.0;
      let span = Cast<Float>(CBConfig.HostileSquadTicksMax() - CBConfig.HostileSquadTicksMin());
      ticks = CBConfig.HostileSquadTicksMax() - FloorF(span * hate);
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
    sys.NoteLaneSent(lane, CBGameDay(game));
    sys.SetLaneFired(lane);
  } else {
    // Zero ticks and then run the dispatch straight away, in this same tick, so they arrive
    // the moment the clock reaches zero rather than a second or two later. The dispatch keeps
    // all its own handling for cars, interiors, quiet jobs and giving up; this only removes
    // the hand-off delay, which served no purpose except to make a finished timer look stuck.
    if lane == CBLaneApex() {
      sys.SetPendingApex(faction, 0);
      CBProcessPendingApex(sys, game);
    } else {
      sys.SetPendingSquad(faction, 0);
      CBProcessPendingSquad(sys, game);
    }
    sys.SetLaneLastFaction(lane, faction);
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
