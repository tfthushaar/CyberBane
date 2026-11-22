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
    // A crew on its way brings its own gang's apex squad (CBCrewBringsApex), so the apex lane
    // does not send a second one into the same fight; nor while a squad is still being brought
    // up to four.
    let crewApexComing = CBCrewApexOn()
                      && (NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetScoutFaction(), n""));
    return NotEquals(sys.GetPendingApexFaction(), n"") || CBLiveTaggedPresent(game, n"CB_Apex")
        || NotEquals(sys.GetApexMusterFaction(), n"") || crewApexComing;
  }
  // A scout out looking holds the crew lane: the crew is waiting on what the scout finds. A crew
  // that came with its apex squad is out for as long as either half of it is standing.
  // A bounty hunter on the way holds it too (Spawn/Bounty.reds): once out, they are CB_Squad like anybody's crew.
  return NotEquals(sys.GetPendingSquadFaction(), n"") || NotEquals(sys.GetScoutFaction(), n"")
      || CBLiveTaggedPresent(game, n"CB_Squad") || CBBountyComing(game)
      || (sys.ActiveSquadHasApex() && CBLiveTaggedPresent(game, n"CB_Apex"));
}

// How many of ours are in the world or on their way into it.
//
// The ceiling on live spawns (CBSpawnGroup) counted only bodies that had finished attaching, and
// a spawn is a request that takes a moment to attach. So several groups asked for in the same
// tick - an apex squad and its crew, a Rival and their escorts - each saw the whole ceiling free,
// and the ceiling held only between ticks. Counting anything still spawning closes that.
public func CBCountLiveOrSpawning(game: GameInstance, tag: CName) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return 0;
  }
  let ids = des.GetTaggedIDs(tag);
  let n = 0;
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    if des.IsSpawning(id) {
      n += 1;
    } else {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if CBStillStanding(p) {
        n += 1;
      }
    }
  }
  return n;
}

// As above, leaving one body out: the one whose death is being handled. For "was that the last of
// them" - somebody still on their way into the world is not beaten yet.
// `without`: anybody also carrying that tag is not counted. A gang's crew is CB_Squad, and so is a bounty hunter (Spawn/
// Bounty.reds), who belongs to no crew: counted as one of it, a hunter still standing kept a crew whose last member had
// fallen from ever being beaten, and the hunter's own death was then never asked (2.5.0).
public func CBCountLiveOrSpawningExcept(game: GameInstance, tag: CName, except: EntityID, opt without: CName) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return 0;
  }
  let ids = des.GetTaggedIDs(tag);
  let n = 0;
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    if NotEquals(id, except) && !(IsNameValid(without) && des.IsTagged(id, without)) {
      if des.IsSpawning(id) {
        n += 1;
      } else {
        let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
        if CBStillStanding(p) {
          n += 1;
        }
      }
    }
  }
  return n;
}

// Room left under the ceiling on how many of ours may be in the world at once.
public func CBSpawnRoom(game: GameInstance) -> Int32 {
  return Max(0, CBConfig.MaxLiveSpawns() - CBCountLiveOrSpawning(game, n"Cyberbane"));
}

// What is taking up the room, in a line for the log (2.5.7): how many are still on their way into the world, and how
// many are standing under each tag. Every spawn of Cyberbane's shares MaxLiveSpawns, so a room that never frees blocks
// crews, the street and V's own crew at once, and nothing said so.
public func CBSpawnRoomNote(game: GameInstance) -> String {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return "";
  }
  let tags: array<CName> = [n"CB_Squad", n"CB_Escort", n"CB_Apex", n"CB_Rival", n"CB_Lair", n"CB_Orphan", n"CB_Scout",
                            n"CB_Bounty", n"CB_Own", n"CB_Ally", n"CB_Bagman", n"CB_Favour", n"CB_Meet", n"CB_Event",
                            n"CB_Patrol", n"CB_Ambush", n"CB_Wannabe", n"CB_Hangout", n"CB_Debtor", n"CB_Witness"];
  let counts: array<Int32>;
  for t in tags {
    ArrayPush(counts, 0);
  }
  let spawning = 0;
  let standing = 0;
  let ids = des.GetTaggedIDs(n"Cyberbane");
  for id in ids {
    let counted = false;
    if des.IsSpawning(id) {
      spawning += 1;
      counted = true;
    } else {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if CBStillStanding(p) {
        standing += 1;
        counted = true;
      }
    }
    if counted {
      let k = 0;
      while k < ArraySize(tags) {
        if des.IsTagged(id, tags[k]) {
          counts[k] += 1;
        }
        k += 1;
      }
    }
  }
  let parts = "";
  let k = 0;
  while k < ArraySize(tags) {
    if counts[k] > 0 {
      parts += (StrLen(parts) > 0 ? ", " : "") + s"\(NameToString(tags[k])) \(counts[k])";
    }
    k += 1;
  }
  return s"\(spawning + standing) of \(CBConfig.MaxLiveSpawns()) taken: \(spawning) still spawning, \(standing) standing [\(parts)]";
}

// ---- A hit squad is an apex squad and a crew ------------------------------------------
//
// "Apex squad should always be four members with MaxTac-like roles; a hit squad should contain an
// apex squad and other crew." Until 1.6.3 only a gang at vendetta brought its apex, and only when
// the four of them could be put in a car - which, with V on foot (the default), is never - so in
// practice no crew ever arrived with one. Now every crew brings its gang's apex squad, whichever
// way they come, and the one setting (Crews bring the apex squad) turns it off.
public func CBCrewApexOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return true;
  }
  return rt.GetSettings().vendettaApexSquad;
}

// Does this gang's next crew come with its apex squad? The one answer for the spawn, the warning
// text and the HUD line, so none of them promises what another will not do.
//
// Not while another apex squad is already in the world, on its way, or still being brought up to
// four: one apex squad at a time, as the apex lane has always kept it, and the people already out
// are in the fight anyway.
public func CBCrewBringsApex(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> Bool {
  if !IsDefined(sys) || !IsDefined(fs) || !CBCrewApexOn() {
    return false;
  }
  let record = CBApexRecordFor(fs);
  if !TDBID.IsValid(record) || !CBRecordIsPerson(record) {
    return false;
  }
  if NotEquals(sys.GetPendingApexFaction(), n"") || NotEquals(sys.GetApexMusterFaction(), n"") {
    return false;
  }
  return !CBLiveTaggedPresent(sys.GetGameInstance(), n"CB_Apex");
}

// What a gang says is coming, in its own words: the crew's number, and its best leading them.
public func CBCrewComingLine(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>) -> String {
  if !IsDefined(sys) || !IsDefined(fs) {
    return "Our people are on their way.";
  }
  let count = CBNumberWord(CBCrewSizeFor(sys, fs, CBCrewIsInfamous(sys)));
  if CBCrewBringsApex(sys, fs) {
    let name = CBApexName(CBContent(game), fs.id, fs.apexAtKills);
    return s"\(name) and three of our best are on their way. \(count) more of ours with them.";
  }
  return s"\(count) of ours are on their way.";
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
// `CBCountLiveTagged` was here: a standing-only head count, with no caller from 1.6.3 to 1.6.7
// and then one new one in 1.6.8 (the Rival escort top-up), which it got wrong. **Deleted on
// purpose - do not add it back.** Counting only bodies that are already standing misses everybody
// the engine has been asked for and has not finished building, so any "how many are already out"
// test written on it double-sends whatever was queued a moment ago. That is the same fault 1.6.3
// swept the codebase for (`CBCountLiveTaggedExcept` -> `CBCountLiveOrSpawningExcept`) and the
// reason `CBSpawnRoom` and `CBSpawnGroup` share their room by the or-spawning count.
//
// Use `CBCountLiveOrSpawning` (or `CBCountLiveOrSpawningExcept` inside a death event). If a
// standing-only count is ever genuinely wanted, say why at the call site - the default is wrong
// often enough that it should not be reachable by accident.

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
  CBScheduleTick(sys, game);   // a new in-game day gets a new timetable
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  CBRivalCooldownTick(sys);
  if sys.GetTickCount() % 5 == 0 {
    CBEnsureHuntingGangs(sys);
  }
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
  // A faction switched off in Mod Settings sends nobody, its Rivals included (1.9.1). They stay on the
  // roster, and come again once it is switched back on. The picker, the lane's re-check and the team-up
  // all ask this.
  if !CBFactionOn(r.faction) {
    return false;
  }
  // Waiting for V at a place they named (Rivals/RivalLife.reds, send word): they go to nobody. Sending
  // word took them off the lane once, and the next pick put them straight back on it.
  let book = CBIntelBook.Get(sys.GetGameInstance());
  if IsDefined(book) && book.WordSent(r.id) {
    return false;
  }
  return r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting);
}

// Why nobody at all could take this lane's next turn, in the player's words, or "" when somebody could (2.5.3). The
// Standing page named the time of the next window whether or not anybody could come in it, so a new game, with no
// Rival and no gang against V, read as a Rival, a crew and an apex squad on their way. Only what CBLanePick itself
// asks before it will pick anybody, so the two cannot disagree: a Rival who can be sent, or with none on the books a
// gang V has fought to put one forward (CBSeedRivalFromFactions); a gang that may send people (CBGangMaySend); a gang
// that has earned its apex squad (CBApexEligible). What changes by the hour (a reason to come today, a cooldown, a
// Rival lying low) is left to the lines that already say it.
public func CBLaneNobodyWhy(sys: ref<CyberbaneSystem>, lane: Int32) -> String {
  if !IsDefined(sys) {
    return "";
  }
  if lane == CBLaneRival() {
    if !CBRivalsOn() {
      return "Rivals are off in Mod Settings";
    }
    for r in sys.GetRivals() {
      if IsDefined(r) && CBRivalQueueable(sys, r.id) {
        return "";
      }
    }
    if sys.CountActiveRivals() > 0 {
      return "none of your Rivals can come right now";
    }
    for fs in sys.GetFactionStates() {
      if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) && CBFactionFieldsSquads(fs.id) && fs.kills > 0 {
        return "";
      }
    }
    return "nobody has a grudge against you yet";
  }
  if !CBHitSquadsOn() {
    return CBRememberSendsCrews() ? CBRememberModName() + " sends the gangs' people" : "crews are off in Mod Settings";
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) {
      if lane == CBLaneApex() {
        if CBApexEligible(sys, fs) {
          return "";
        }
      } else {
        if CBGangMaySend(sys, fs.id) {
          return "";
        }
      }
    }
  }
  return lane == CBLaneApex() ? "no gang is angry enough to send its best" : "no gang is after you";
}

func CBAnotherLaneJustFired(sys: ref<CyberbaneSystem>, lane: Int32) -> Bool {
  let i = CBLaneRival();
  while i <= CBLaneApex() {
    if i != lane && sys.GetLaneFired(i) > 0
       && (sys.GetTickCount() - sys.GetLaneFired(i)) < CBConfig.LaneCrossGapTicks() {
      return true;
    }
    i += 1;
  }
  return false;
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
    if lane == CBLaneApex() {
      CBApexLaneNote(sys, game, CBArrivalsHeldWhy(sys, game));
    }
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
    // Somebody's grudge has run out of patience (2.6.5, Spawn/Grudge.reds): no timetable and no day's allowance any more.
    let slotDue = CBPacingDue(sys, game, lane);
    if !slotDue && !provoked {
      return;
    }
    // Only the gang that was provoked may answer out of turn. Without this a provocation could open the lane for whichever
    // gang happened to score highest.
    provokedOnly = !slotDue;
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
    // And the warning they were given with it (2.5.6): left standing, a Rival warned and then spared, switched off or
    // waiting at a place they named would, picked again some day, skip the warning and walk straight in.
    if sys.GetRivalWarned() == sys.GetLaneRivalId(lane) {
      sys.SetRivalWarned(0);
    }
    sys.ClearLane(lane);
    return;
  }
  // And the gang a crew or apex lane is holding, the same way: switched off, crews switched off, or no
  // longer hostile since it was picked. Only the Rival lane asked, so a gang that had cooled, or that the
  // player had switched off, went on counting down and was sent when its turn came.
  // Never the Rival lane, whose target is the Rival's gang only for the record: a Rival is personal, and is asked
  // CBRivalQueueable above. Asking the crews' question of it let go of every Rival picked while crews were off, while
  // They Will Remember sent the gangs' people (CBHitSquadsOn is false then), or once their gang had stopped being
  // hostile to V, so with any of those no Rival ever came (2.0.0 to 2.4.2).
  let laneGang = sys.GetLaneTarget(lane);
  if lane != CBLaneRival() && NotEquals(laneGang, n"") && !CBGangMaySend(sys, laneGang) {
    CBLog.Info(n"Spawn", s"\(CBLaneLabel(lane)) lane let go of \(NameToString(laneGang)): they no longer send anybody.");
    sys.ClearLane(lane);
    return;
  }
  if sys.GetLaneTicks(lane) > 0 || NotEquals(sys.GetLaneTarget(lane), n"") || sys.GetLaneRivalId(lane) > 0 {
    if sys.TickDownLane(lane) > 0 {
      return;
    }
    if CBAnotherLaneJustFired(sys, lane) {
      return;   // still queued, at zero: it goes as soon as the road is clear
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
      // And the one test the lane's re-check asks (CBRivalQueueable), so nobody is picked who would be
      // let go again on the next tick.
      // And whose own patience has run out (2.6.5, CBRivalReady).
      if IsDefined(r) && r.huntTicks <= 0 && CBRivalQueueable(sys, r.id) && CBRivalReady(sys, game, r) {
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
      if lane == CBLaneApex() {
        CBApexLaneNote(sys, game, CBRememberSendsCrews() ? CBRememberModName() + " sends the gangs' people" : "crews are off in Mod Settings");
      }
      return;
    }
    for fs in sys.GetFactionStates() {
      // The law is not a gang and does not send crews; it has heat and MaxTac for that.
      // An apex squad is built from the gang's apex records (CBApexRecordFor), which CBApexEligible
      // already asks for. Demanding the crew template as well kept a gang the Hub called ready out
      // of the apex lane for good whenever it had no crew template on file.
      if IsDefined(fs) && CBFactionFieldsSquads(fs.id)
         && (lane == CBLaneApex() || TDBID.IsValid(fs.sampleRecord)) {
        let posture = score.GetPosture(fs.id);
        let hate = ClampF((-CBActingStanding(fs.id, fs.standing) / 100.0) * (fs.renown / 100.0), 0.0, 1.0);
        let s = 0.0;
        if lane == CBLaneApex() {
          if CBApexReady(sys, fs) {
            s = CBConfig.QueueScoreApex() + hate * 20.0;
          }
        } else {
          // Their patience run out (2.6.5, CBGangReady: their grudge, a fresh wound, how broken they are, their fear of V,
          // their own war, distance, a mask, their code, the hour), or V has just provoked them.
          let offCooldown = CBGangReady(sys, game, fs) || Equals(fs.id, sys.GetProvoked());
          // A crew needs a reason to come today, not only a grudge (CBCrewReason).
          let reason = CBCrewReason(sys, fs, posture, ArrayContains(turf, fs.id), now);
          // Knowing V well enough to send people is a given for a gang set by hand to come for V (2.1.0).
          let knowsV = fs.renown >= CBConfig.HitSquadMinRenown() || CBGangViewHunts(fs.id);
          if offCooldown && knowsV && reason >= 0.0
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
  //
  // Only for a roster that is really empty. This ran whenever nobody could be picked, and the usual
  // reason nobody can be picked is that every Rival V has is on their cooldown after their last fight
  // (RivalAfterEscapeTicks): so a player with five Rivals got a sixth, a stranger who had never met V,
  // every time the lane came due during that quarter of an hour, until the roster was full of them.
  if bestScore <= 0.0 && lane == CBLaneRival() && sys.CountActiveRivals() == 0 {
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
      CBLog.Info(n"Spawn", s"\(CBLaneLabel(lane)) lane is due but nobody qualifies (no gang has a reason to come yet, or those that do are on cooldown).");
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
      let hate = IsDefined(fs) ? ClampF((-CBActingStanding(fs.id, fs.standing) / 100.0) * (fs.renown / 100.0), 0.0, 1.0) : 0.0;
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
    // Now and then they name a place instead of coming (Rivals/RivalLife.reds, 1.9.9).
    if IsDefined(r) && sys.GetRivalWarned() != r.id && CBRivalMayCallOut(sys, game, r) {
      return;
    }
    if IsDefined(r) && sys.GetRivalWarned() != r.id {
      sys.SetRivalWarned(r.id);
      sys.SetLaneTicks(lane, CBRivalArrivalTicks(sys, game, r, CBConfig.RivalWarningTicks()));
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
    CBRivalBringPartners(sys, game, r, now);   // sometimes not alone (1.9.0, experimental)
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
      sys.SetPendingApex(faction, CBArrivalTicks(sys, game, faction, CBConfig.ApexWarningTicks()));
      sys.SetHuntGrade("APEX SQUAD");
      sys.ClearCrewBeaten(faction);   // the beaten crew has been answered
      CBApexOnTheWay(sys, game, faction);
    } else {
      // A gang that does not know where V is may send one person to look first (Spawn/Hunt.reds).
      // The crew then only comes if the scout finds V.
      if !CBTrySendScout(sys, game, faction) {
        sys.SetPendingSquad(faction, CBArrivalTicks(sys, game, faction, CBConfig.CrewWarningTicks()));
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
  // Only for a mod that sends crews of its own (2.6.7): Night City Remembers sends nobody, and standing down for it would have
  // left nobody coming after V at all.
  return !CBRememberSendsCrews();
}

// How many encounters this lane is allowed to send in one in-game day.
//
// This is the real pacing control. Before it, a lane sent somebody every time its gap elapsed
// and kept doing so for ever, so the only thing deciding how busy a day was was how long the
// player stayed in one. A day now has a shape: a few Rivals, a couple of crews, a couple of
// apex squads, and once a lane has spent its allowance it is quiet until tomorrow. The gap
// below still applies on top, so the day's allowance cannot all arrive at once.
// No day's allowance any more (2.6.5, Spawn/Grudge.reds): every gang and Rival comes on its own grudge's clock. Kept for
// the places that ask whether a kind is on at all: more than zero when it is, zero when it is switched off.
public func CBLaneDailyCap(lane: Int32) -> Int32 {
  if lane == CBLaneRival() { return CBRivalsOn() ? 99 : 0; }
  if lane == CBLaneApex() { return CBHitSquadsOn() && CBApexOnSetting() ? 99 : 0; }
  return CBHitSquadsOn() ? 99 : 0;
}

public func CBLaneBudgetLeft(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Int32 {
  return CBLaneDailyCap(lane);
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
//
// With turf wars on, that is whoever actually holds a share of the district now
// (Model/Territory.reds): a gang V has broken is pushed off its own streets, and a gang that moved
// in on them is on its streets there. Every question about turf - whose lookouts watch V, whose
// crew knows where V is, whose vendors know where V stands - goes through here, so they all agree.
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
  if CBTurfWarsOn() {
    // The answer from the last district sample, when it is about this district; worked out on
    // the spot only in the moment between walking into a district and the next sample.
    if Equals(sys.GetTurfHereDistrict(), district) {
      return sys.GetTurfHereGangs();
    }
    return CBTurfGangsIn(sys, sys.GetGameInstance(), district);
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
  // A corporation sends nobody of its own: it puts a price on V and hires the ladder (Spawn/Bounty.reds, 2.4.3).
  if CBCorpHiresKillers(fs.id) {
    return -1.0;
  }
  // Where V put a pile of their people in the ground, recently: they are slow to come back there
  // (Model/StreetBook.reds, 2.3.1).
  if CBGangAvoidsHere(sys, sys.GetGameInstance(), fs.id) {
    return -1.0;
  }
  // A grudge that stays in one district (Barghest's, in Dogtown; Data/GangCodes.reds).
  if !CBCodeAtHome(sys, fs.id) {
    return -1.0;
  }
  // A gang that cannot pay anybody, or has nobody left, sends nobody; and nobody comes onto V's own streets
  // (Economy/War.reds, 2.4.0). A stance set by hand to come for V is the player's word, and the money does not argue.
  if !CBGangViewHunts(fs.id) && !CBWarCanSend(sys.GetGameInstance(), fs.id) {
    return -1.0;
  }
  if CBOwnDistrict(sys.GetGameInstance(), sys.GetCurrentDistrict()) {
    return -1.0;
  }
  let bonus = 0.0;
  let reason = false;
  // A gang V has broken (1.9.5) has nobody to spare for a standing grudge or for V walking its streets:
  // it sends people when V has just hurt it or provoked it, and otherwise keeps its head down. Its
  // people said as much ("there's hardly any of us left") while it went on sending a crew a day.
  let broken = CBGangBroken(sys, fs.id);
  if Equals(posture, ECBPosture.Vendetta) && !broken {
    reason = true;
  }
  if Equals(fs.id, sys.GetProvoked()) {
    reason = true;
  }
  // A gang with a tracker on V, or in open season, always knows where to send (Spawn/HuntGrows.reds, 2.4.2).
  if Equals(fs.id, CBTrackerGang(sys.GetGameInstance())) || CBOpenSeasonFor(sys.GetGameInstance(), fs.id) {
    reason = true;
  }
  if onTheirTurf {
    if !broken {
      reason = true;
    }
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
  if TDBID.IsValid(fs.eliteRecord) {
    return fs.eliteRecord;
  }
  if TDBID.IsValid(fs.sampleRecord) {
    return fs.sampleRecord;
  }
  return CBApexRosterRecord(fs.id, 0);
}

// Has this gang earned the right to send its best? One test for the lane, the warning text and
// the Hub, so none of them can promise an apex squad another will not send.
// May this gang still send anybody after V at all: crews on, the gang fielding people (not the law, not
// switched off), and still hostile. Asked of whatever a gang already has queued or counting down - a lane
// holding them, a crew or apex squad warned and on the clock, an informant's set-up - so nothing goes out
// for a gang that has since been paid off, come round to V, or been switched off. Picking (CBLanePick,
// CBApexEligible) asks more than this; this is what must still hold once they have been picked.
public func CBGangMaySend(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  if !IsDefined(sys) || Equals(faction, n"") || !CBHitSquadsOn() || !CBFactionFieldsSquads(faction)
     || CBCorpHiresKillers(faction) {
    return false;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return false;
  }
  let posture = score.GetPosture(faction);
  return Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta);
}

public func CBApexEligible(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> Bool {
  if !IsDefined(sys) || !IsDefined(fs) || !CBFactionFieldsSquads(fs.id)
     || !TDBID.IsValid(CBApexRecordFor(fs)) || CBCorpHiresKillers(fs.id) {
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
  // Set by hand to Vendetta (How gangs see you, 2.1.0): their best come on their own, within How often they come.
  // The kills that earn an apex squad are how Earned in play, and a Hostile set by hand, decide it.
  if CBGangViewVendetta(fs.id) {
    return true;
  }
  // A gang whose code never sends its best (the Mox), or whose grudge stays at home (Data/GangCodes.reds).
  if !CBCodeSendsApex(fs.id) || !CBCodeAtHome(sys, fs.id) {
    return false;
  }
  // Their best cost money (Economy/War.reds, 2.4.0).
  if !CBWarCanSendApex(sys.GetGameInstance(), fs.id) {
    return false;
  }
  let since = fs.kills - fs.apexAtKills;
  if since < CBConfig.ApexKillThreshold() {
    return false;
  }
  return sys.CrewBeaten(fs.id)
      || since >= CBConfig.ApexKillThreshold() * CBConfig.ApexMassacreMultiplier();
}

// Every gang set by hand to come for V has what it takes to send people (How gangs see you, 2.1.0). A gang V has
// never crossed has no record on the books at all (only a kill or a pay-off files one), so the lanes, which go
// through the gangs on the books, never looked at it; and none of its people on file to build a crew from. Its
// record is opened, and its crew template is its own rank and file, the same fallback the session start gives any
// gang left without one (Rivals/RivalSystem.reds, CBPruneUniqueRivals). Gangs on Earned in play are not touched.
public func CBEnsureHuntingGangs(sys: ref<CyberbaneSystem>) -> Void {
  let content = IsDefined(sys) ? sys.GetContent() : null;
  if !IsDefined(content) {
    return;
  }
  for prof in content.GetFactions() {
    if IsDefined(prof) && prof.isGang && CBFactionFieldsSquads(prof.id) && CBGangViewHunts(prof.id) {
      let fs = sys.EnsureFaction(prof.id);
      if IsDefined(fs) && !TDBID.IsValid(fs.sampleRecord) {
        fs.sampleRecord = CBApexRosterRecord(fs.id, 1);
      }
    }
  }
}

// What the Hub says about this gang's apex squad when nothing is on its way.
public func CBApexProgressLine(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> String {
  // Nothing to count towards when Cyberbane sends nobody (crews off, or They Will Remember sending the gangs'
  // people): the Gangs screen said "apex squad in 20 kills" for a squad that was never coming (2.4.2).
  if !IsDefined(sys) || !IsDefined(fs) || !CBHitSquadsOn() {
    return "";
  }
  let score = sys.GetScore();
  let posture = IsDefined(score) ? score.GetPosture(fs.id) : ECBPosture.Neutral;
  if NotEquals(posture, ECBPosture.Hostile) && NotEquals(posture, ECBPosture.Vendetta) {
    return "";
  }
  // A corporation sends nobody: it pays the ladder (Spawn/Bounty.reds, 2.4.3).
  if CBCorpHiresKillers(fs.id) {
    return "they hire killers instead of sending their own";
  }
  if CBApexEligible(sys, fs) {
    // Ready is only ready if the lane can send them. Everything that stops it is said here, in the
    // lane's own order, so the Hub never promises a squad that is not coming (CBApexBlocker).
    let why = CBApexBlocker(sys, sys.GetGameInstance(), fs);
    return StrLen(why) == 0 ? "ready to send their best" : "their best waits: " + why;
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
  // Their apex squad came with them and is down too: nobody else of it walks into a fight that
  // is over. Read before the line below, which forgets that it came.
  if sys.ActiveSquadHasApex() && Equals(sys.GetApexMusterFaction(), faction) {
    sys.ClearApexMuster();
  }
  sys.SetActiveSquadFaction(n"");   // nobody left to have escaped
  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  sys.NoteCrewBeaten(faction);
  CBWeakenGang(sys, game, faction, CBConfig.GangLossCrew());   // a whole crew gone is felt on the street
  CBLog.Info(n"Spawn", s"Crew from \(NameToString(faction)) wiped out; their apex squad is next in line.");
  // Somebody is glad to see that crew gone, and pays for it (Spawn/Loot.reds).
  let crewLabel = CBFactionLabel(faction);
  CBPayBounty(sys, game, faction, RoundF(Cast<Float>(CBConfig.BountyCrew()) * CBLootLevelScale(game) / 50.0) * 50,
              StrLen(crewLabel) > 0 ? s"Heard you dealt with that crew of \(crewLabel)." : "Heard you dealt with that crew.");
  // Only promise what can follow: a gang that fields an apex, while the apex lane is on and
  // nothing is already on its way.
  if !CBToastsOn() || !CBHitSquadsOn() || CBLaneDailyCap(CBLaneApex()) <= 0
     || !TDBID.IsValid(CBApexRecordFor(fs)) || NotEquals(sys.GetPendingApexFaction(), n"") {
    return;
  }
  let name = CBApexName(CBContent(game), faction, fs.apexAtKills);
  if CBApexEligible(sys, fs) {
    CBHearsayFromGang(game, faction, s"That was our crew. Next time it is \(name), and three more like them.", n"");
  } else {
    CBHearsayFromGang(game, faction, s"That was our crew. Keep it up and you meet \(name).", n"");
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
    CBTurfWatchLetGo(game);
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
    CBTurfWatchLetGo(game);
    sys.SetTurfWatch(n"", now);
    return;
  }
  let turfBook = CBTurfBook.Get(game);
  if NotEquals(owner, sys.GetTurfWatchFaction()) {
    CBTurfWatchLetGo(game);
    sys.SetTurfWatch(owner, now);
    // Their eyes on the street: somebody in the crowd (Spawn/Hunted.reds, [50]).
    if IsDefined(turfBook) {
      turfBook.lookoutId = CBPickLookout(sys, game, owner);
    }
    return;
  }
  // Their lookout dealt with: nothing gets reported, and the street is quiet for a while.
  if IsDefined(turfBook) && CBLookoutDealt(game, turfBook.lookoutId) {
    CBTurfWatchLetGo(game);
    sys.SetTurfSpotNext(now + CBConfig.TurfSpotCooldownTicks());
    sys.SetTurfWatch(n"", now);
    CBLog.Info(n"Spawn", s"The \(NameToString(owner)) lookout was dealt with.");
    if CBToastsOn() {
      CBHearsayFromStreet(game, s"\(CBCapFirst(CBFactionLabel(owner))) had somebody watching for you. Not any more.", n"");
    }
    return;
  }
  if (now - sys.GetTurfWatchSince()) < CBConfig.TurfLingerTicks() || now < sys.GetTurfSpotNext() {
    return;
  }
  CBTurfWatchLetGo(game);
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
  return ECBPacing.Timetable;
}

public func CBPacingSetting() -> ECBPacing {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return ECBPacing.Timetable;
  }
  return ECBPacing.Timetable;
}

// Is this lane allowed to pick somebody this tick? The day's allowance, the rest between
// encounters and the reasons a gang needs are all still checked by the caller.
// Is anybody's grudge ready for this lane (2.6.5)? Asked every few ticks, not every one: it walks every gang.
public func CBPacingDue(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Bool {
  if sys.GetTickCount() % 5 != lane % 5 {
    return false;
  }
  let who: CName;
  let rid: Int32;
  return CBGrudgeNextIn(sys, game, lane, who, rid) == 0.0;
}

// The timetable's own test (until 2.6.5), kept for reference and no longer asked.
public func CBPacingDueOld(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Bool {
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
       + CBConfig.DifficultyWarningExtra() * CBDifficultyLevel()
       + CBWatchExtraTicks();   // somebody V paid to keep watch sees them sooner (Reactions/StreetPay.reds)
}

// How far they have to come (2.6.1): the warning before a gang's people arrive, by how many districts lie between V
// and the nearest streets that gang holds. On their own turf they are round the corner (Barghest in Dogtown); a gang
// from across the city takes a while to get there (the same Barghest with V in the City Center). A gang with no streets
// anywhere (a corporation) comes in the usual time.
public func CBArrivalTicks(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, base: Int32) -> Int32 {
  let hops = CBGangHopsToV(sys, game, faction);
  return Max(1, RoundF(Cast<Float>(CBWarningTicks(base)) * CBArrivalDistanceMult(hops)));
}

// A Rival comes from their own district, where they keep their place.
public func CBRivalArrivalTicks(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, base: Int32) -> Int32 {
  let hops = IsDefined(r) && IsDefined(sys) ? CBDistrictHops(game, r.origin, sys.GetCurrentDistrict()) : -1;
  // Nowhere known at either end is no distance at all, never "here" (2.6.3): CBDistrictHops reads an unknown district as
  // the same one, so a Rival sent while V's district was not yet known after a load arrived at home-turf speed.
  if !IsDefined(r) || !IsDefined(sys) || CBDistrictIndex(r.origin) < 0 || CBDistrictIndex(sys.GetCurrentDistrict()) < 0 {
    hops = -1;
  }
  return Max(1, RoundF(Cast<Float>(CBWarningTicks(base)) * CBArrivalDistanceMult(hops)));
}

public func CBArrivalDistanceMult(hops: Int32) -> Float {
  if hops < 0 { return 1.0; }   // nowhere they come from
  if hops == 0 { return CBConfig.ArrivalHomeMult(); }
  if hops == 1 { return 1.0; }
  if hops == 2 { return CBConfig.ArrivalFarMult(); }
  return CBConfig.ArrivalAcrossCityMult();
}

// Districts between V and the nearest place this gang has streets, -1 for a gang with none. With turf wars on, where
// it holds a share now (a gang pushed off its own streets comes from wherever it still is); otherwise its home turf.
public func CBGangHopsToV(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Int32 {
  let content = IsDefined(sys) ? sys.GetContent() : null;
  if !IsDefined(content) || Equals(faction, n"") {
    return -1;
  }
  let here = sys.GetCurrentDistrict();
  if CBDistrictIndex(here) < 0 {
    return -1;
  }
  let prof = content.GetFaction(faction);
  let best = -1;
  let i = 0;
  while i < CBDistrictCount() {
    let d = CBDistrictAt(i);
    i += 1;
    let holds = false;
    if CBTurfWarsOn() {
      let there = CBTurfGangsIn(sys, game, d);   // a local, never a temporary (UI/HubWeb.reds, CBWebPair)
      holds = ArrayContains(there, faction);
    } else {
      holds = IsDefined(prof) && ArrayContains(prof.turf, d);
    }
    if holds {
      let hops = CBDistrictHops(game, d, here);
      if best < 0 || hops < best {
        best = hops;
      }
    }
  }
  return best;
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
    line = CBCapFirst(who) + " are asking about you, and not their usual people.";
  } else {
    if lane == CBLaneRival() {
      line = s"\(who) has been asking around about you.";
    } else {
      switch RandRange(0, 3) {
        case 0: line = s"Somebody from \(who) was asking where you drink."; break;
        case 1: line = CBCapFirst(who) + " are asking questions about you."; break;
        default: line = s"Your name came up with \(who). They want to know where you are."; break;
      }
    }
  }
  // Overheard only with Whispers on, and only now and then (1.9.1). Overheard is a line drawn on the
  // screen, so a player who set messages to go to the phone and switched the overheard lines off
  // still had four in ten of these put up as a subtitle.
  if !CBWhispersOn() || RandF() < 0.6 || NotEquals(CBMessageDelivery(), ECBMessageDelivery.Phone) {
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
  // Tonight the Claws send one killer (Spawn/HuntGrows.reds, [11]).
  if CBClawsAssassin(sys.GetGameInstance(), fs.id) {
    return 1;
  }
  let size = 3 + FloorF(-CBActingStanding(fs.id, fs.standing) / 35.0);
  if size > 6 {
    size = 6;
  }
  if infamous {
    size += 1;
  }
  size += CBCrewAnswerSize(sys, fs.id);   // a crew of V's own is answered with a bigger one (Reactions/Crew.reds, 2.5.0)
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
  // A gang V has bled sends fewer of its people (1.9.5): from the whole crew at full strength down to
  // about three in five of it at the floor. Strength is 100 whenever turf wars are off.
  let strength = ClampF(CBGangStrength(sys, fs.id), 0.0, 100.0);
  if strength < 100.0 {
    size = Max(2, RoundF(Cast<Float>(size) * (CBConfig.CrewStrengthFloorShare()
                                                + (1.0 - CBConfig.CrewStrengthFloorShare()) * strength / 100.0)));
  }
  // Harder difficulty means harder fights, not instant deaths: a little smaller.
  size = Max(2, size - CBConfig.DifficultyCrewTrim() * CBDifficultyLevel());
  // How many this gang sends at all (Data/GangCodes.reds): the Mox and the Voodoo Boys few, Barghest more.
  size = Max(2, RoundF(Cast<Float>(size) * CBCodeCrew(fs.id)));
  // And how many it can pay for and still has (Economy/War.reds, 2.4.0).
  size = Max(2, RoundF(Cast<Float>(size) * CBWarCrewMult(GetGameInstance(), fs.id)));
  // Never more than can actually be in the world at once (CBSpawnGroup's ceiling), leaving the
  // apex squad's four chairs free when crews bring it. The vendetta slider goes past the ceiling,
  // so the text could promise twenty and eighteen at most could ever turn up; this is the one
  // number both the text and the spawn use, so it is the number that arrives.
  size += sys.WornPerk().crewDelta;
  // And V's own crew's places, kept free while they could be called (2.6.3, CBCrewRoomKept).
  let ceiling = CBConfig.MaxLiveSpawns() - (CBCrewApexOn() ? CBConfig.ApexStrikeTeamSize() : 0) - CBCrewRoomKept(GetGameInstance());
  return Min(size, Max(2, ceiling));
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
  if CBCrewBringsApex(sys, fs) {
    return "APEX CREW";
  }
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

// Why this gang's apex squad is not coming right now, in a few words, or "" when nothing stands in
// the way but the timetable (1.8.4). The lane's own checks, in the lane's order (CBLaneTick,
// CBLanePick): "ready to send their best" was shown on the gang's eligibility alone, so a player
// with 320 kills was told 6th Street was ready while crews were off, They Will Remember had the
// gangs, the day's squads were spent or V was standing on a job.
public func CBApexBlocker(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>) -> String {
  if !IsDefined(sys) || !IsDefined(fs) {
    return "";
  }
  if !CBHitSquadsOn() {
    return CBRememberSendsCrews() ? CBRememberModName() + " sends the gangs" : "crews are off in Mod Settings";
  }
  if CBLaneDailyCap(CBLaneApex()) <= 0 {
    return "apex squads are off in Mod Settings";
  }
  let queued = sys.GetLaneTarget(CBLaneApex());
  if NotEquals(queued, n"") && NotEquals(queued, fs.id) {
    return "another gang's best goes first";
  }
  if CBLaneBusy(sys, game, CBLaneApex()) {
    return "one squad is already out";
  }
  if CBArrivalsHeld(sys, game) {
    return "held while " + CBArrivalsHeldWhy(sys, game);
  }
  if CBLaneBudgetLeft(sys, game, CBLaneApex()) <= 0 {
    return "none left today";
  }
  return "";
}

// Said in the log, once a minute at most, when the apex lane stands still with a gang ready.
func CBApexLaneNote(sys: ref<CyberbaneSystem>, game: GameInstance, why: String) -> Void {
  if !IsDefined(sys) || (sys.GetTickCount() - sys.GetLaneQuietLogged(CBLaneApex())) <= 60 {
    return;
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBApexEligible(sys, fs) {
      sys.SetLaneQuietLogged(CBLaneApex(), sys.GetTickCount());
      CBLog.Info(n"Spawn", s"Apex squad: \(NameToString(fs.id)) is ready, held because \(why).");
      return;
    }
  }
}

// The turf watch's lookout is nobody's any more.
func CBTurfWatchLetGo(game: GameInstance) -> Void {
  let book = CBTurfBook.Get(game);
  if IsDefined(book) && EntityID.IsDefined(book.lookoutId) {
    CBLookoutRelease(game, book.lookoutId);
    let none: EntityID;
    book.lookoutId = none;
  }
}
