// Cyberbane - The day's timetable (spec §9.9)
//
// An in-game day is split into three sectors of eight hours. Every sector holds one window per
// kind of encounter, and those windows are staggered inside it, so a Rival and an apex squad
// that share a sector arrive hours apart rather than on top of each other.
//
//   SECTOR 1  00:00-08:00      SECTOR 2  08:00-16:00      SECTOR 3  16:00-24:00
//     [ ~2h40 ][ ~2h40 ][ ~2h40 ]  per sector, one sub-window per kind, order rolled daily
//
// How many slots each kind gets comes from its own per-day setting: three Rivals is one slot in
// every sector, two crews is a slot in two of the three. Which sectors they land in is rolled
// fresh each in-game day, and the exact moment inside a sub-window is random, so the city does
// not run to a timetable the player can learn.
//
// Why this replaced a gap between encounters: a fixed rest period only says how long since the
// last one, so the shape of a day depended entirely on how long the player stayed in it. A day
// now has a plan before it starts, which is what makes "three Rivals, two crews and two apex
// squads" a description of a day rather than a cap that may or may not be reached.
//
// **Skipped time is forfeited, deliberately.** Sleeping, fast travel and time skips move the
// clock past whole sectors. A slot whose sector has closed is marked spent without firing, so
// waking up never hands the player a backlog of everything that was owed while they were gone.
// That falls straight out of the rule that a slot is retried only while its own sector runs.

// Eight in-game hours, three to a day.
public func CBSectorHours() -> Float = 8.0
public func CBSectorCount() -> Int32 = 3

// Where the clock is in the current day, as hours 0.0 .. 24.0.
public func CBGameHourOfDay(game: GameInstance) -> Float {
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(ts) {
    return 0.0;
  }
  let t = ts.GetGameTime();
  return Cast<Float>(GameTime.Hours(t))
       + Cast<Float>(GameTime.Minutes(t)) / 60.0
       + Cast<Float>(GameTime.Seconds(t)) / 3600.0;
}

// Build today's timetable. Called once per in-game day.
public func CBRollSchedule(sys: ref<CyberbaneSystem>, game: GameInstance, day: Int32) -> Void {
  sys.ClearSchedule(day);

  let lanes: array<Int32>;
  ArrayPush(lanes, CBLaneRival());
  ArrayPush(lanes, CBLaneSquad());
  ArrayPush(lanes, CBLaneApex());

  // One rotation offset per kind, for the whole day.
  //
  // This was rolled inside the sector loop, which meant each sector decided independently
  // whether it was getting the remainder. Two crews a day could come out as one, two or three
  // depending on how the dice fell, so the number the player set was not the number they got.
  // Rolled once, the remainder lands in exactly as many sectors as there is remainder.
  let offsets: array<Int32>;
  let o = 0;
  while o < ArraySize(lanes) {
    ArrayPush(offsets, RandRange(0, CBSectorCount()));
    o += 1;
  }

  // How many slots each kind gets, and which sectors they go in.
  let s = 0;
  while s < CBSectorCount() {
    // The order the three kinds take their sub-windows is rolled per sector, so Rivals are not
    // always the first thing to happen in a morning.
    let order = CBShuffledLanes(lanes);
    let i = 0;
    while i < ArraySize(order) {
      let lane = order[i];
      let n = CBSlotsForSector(CBLaneDailyCap(lane), offsets[lane - 1], s);
      if n > 0 {
        // This kind's share of the sector, split again if it has more than one slot in it.
        let sub = CBSectorHours() / Cast<Float>(ArraySize(order));
        let subStart = Cast<Float>(s) * CBSectorHours() + Cast<Float>(i) * sub;
        let sectorEnd = Cast<Float>(s + 1) * CBSectorHours();
        let k = 0;
        while k < n {
          let slice = sub / Cast<Float>(n);
          let lo = subStart + Cast<Float>(k) * slice;
          // Never right at the edge, so two adjacent windows cannot resolve to the same moment.
          let at = lo + RandRangeF(slice * 0.1, slice * 0.9);
          sys.AddSlot(lane, at, sectorEnd);
          k += 1;
        }
      }
      i += 1;
    }
    s += 1;
  }
  CBPullFirstSlotForward(sys, game);
  CBLog.Info(n"Spawn", s"Day \(day) at \(RoundF(CBGameHourOfDay(game)))h: timetable set, \(sys.SlotCount()) encounters planned.");
}

// How many slots this kind gets in sector `s`.
//
// The day's allowance is spread as evenly as it will go: three Rivals is one per sector, two
// crews is one in each of two sectors chosen by the day's own roll, and a setting raised past
// three simply stacks more into each sector.
func CBSlotsForSector(cap: Int32, offset: Int32, s: Int32) -> Int32 {
  if cap <= 0 {
    return 0;
  }
  let base = cap / CBSectorCount();
  let extra = cap % CBSectorCount();
  // The remainder goes to `extra` sectors of a rotation that starts somewhere random, so it is
  // not always the morning that gets the odd one. The offset is the day's, not the sector's.
  let slot = (s + offset) % CBSectorCount();
  return slot < extra ? base + 1 : base;
}

func CBShuffledLanes(lanes: array<Int32>) -> array<Int32> {
  let out = lanes;
  let i = ArraySize(out) - 1;
  while i > 0 {
    let j = RandRange(0, i + 1);
    let tmp = out[i];
    out[i] = out[j];
    out[j] = tmp;
    i -= 1;
  }
  return out;
}

// Do not start a session with a long silence.
//
// A timetable is rolled at the start of an in-game day and whenever a save is loaded, and the
// windows it lays down are spread across the whole day. Load in at the wrong moment and the
// next one is most of an hour of real play away, which from the player's side is a mod that
// does nothing. This drags the soonest upcoming slot back to within a few minutes of now, so
// there is always something coming shortly after you sit down. It moves one slot; the rest of
// the day keeps its shape.
func CBPullFirstSlotForward(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let now = CBGameHourOfDay(game);
  let best = -1;
  let bestAt = 0.0;
  let i = 0;
  while i < sys.SlotCount() {
    if !sys.SlotSpent(i) && sys.SlotAt(i) > now && now < sys.SlotEnd(i) {
      if best < 0 || sys.SlotAt(i) < bestAt {
        best = i;
        bestAt = sys.SlotAt(i);
      }
    }
    i += 1;
  }
  // Already soon enough, or nothing left today. Either way leave it alone.
  if best < 0 || bestAt - now <= CBConfig.FirstSlotMaxWaitHours() {
    return;
  }
  sys.MoveSlot(best, now + RandRangeF(0.1, CBConfig.FirstSlotMaxWaitHours()));
}

// Is this lane due right now?
//
// True while an unspent slot's moment has arrived and its sector is still running. Once the
// sector closes the slot is marked spent whether or not it ever fired, which is what stops a
// skipped afternoon turning into a queue of arrivals the moment the player reappears.
public func CBSlotDue(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Bool {
  let now = CBGameHourOfDay(game);
  let i = 0;
  let due = false;
  while i < sys.SlotCount() {
    if sys.SlotLane(i) == lane && !sys.SlotSpent(i) {
      if now >= sys.SlotEnd(i) {
        sys.SpendSlot(i);   // its sector has closed; it is not owed any more
      } else {
        if now >= sys.SlotAt(i) {
          due = true;
        }
      }
    }
    i += 1;
  }
  return due;
}

// Mark the earliest live slot for this lane as used, once something has actually been sent.
public func CBSpendSlot(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Void {
  let now = CBGameHourOfDay(game);
  let best = -1;
  let bestAt = 0.0;
  let i = 0;
  while i < sys.SlotCount() {
    if sys.SlotLane(i) == lane && !sys.SlotSpent(i) && now >= sys.SlotAt(i) {
      if best < 0 || sys.SlotAt(i) < bestAt {
        best = i;
        bestAt = sys.SlotAt(i);
      }
    }
    i += 1;
  }
  if best >= 0 {
    sys.SpendSlot(best);
  }
}

// Roll a new timetable when the day turns. Safe to call every tick.
public func CBScheduleTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  // Nothing is planned until the clock and the world are both up. A timetable built against a
  // clock that is not running yet is a timetable for the wrong day at the wrong hour, and
  // every lane then sits waiting for windows that already passed or have not come.
  if !CBClockReady(game) || !CBWorldStable(game) {
    return;
  }
  let day = CBGameDay(game);
  if !sys.ScheduleRolled() || sys.ScheduleDay() != day {
    CBRollSchedule(sys, game, day);
  }
}

// When the next encounter of this kind is due, in in-game hours from now, or -1 if the day has
// nothing left for it. The Hub converts this to real time for display.
public func CBHoursUntilNextSlot(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> Float {
  let now = CBGameHourOfDay(game);
  let best = -1.0;
  let i = 0;
  while i < sys.SlotCount() {
    if sys.SlotLane(i) == lane && !sys.SlotSpent(i) && now < sys.SlotEnd(i) {
      // A slot whose moment has already come counts as zero rather than being skipped. Testing
      // only for slots in the future made a lane that was due right now report that the day had
      // nothing left for it, which is the opposite of true.
      let d = sys.SlotAt(i) > now ? sys.SlotAt(i) - now : 0.0;
      if best < 0.0 || d < best {
        best = d;
      }
    }
    i += 1;
  }
  return best;
}
