// Cyberbane - The day's timetable (spec §9.9)
//
// An in-game day is split into three sectors of eight hours. Every sector holds one window per
// kind of encounter, and those windows are staggered inside it, so a Rival and an apex squad
// that share a sector arrive hours apart rather than on top of each other.

// Eight in-game hours, three to a day.
public func CBSectorHours() -> Float = 8.0
public func CBSectorCount() -> Int32 = 3

// Where the clock is in the current day, as hours 0.0.. 24.0.
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
  if true {
    return;
  }
  // Nothing is planned until the clock and the world are both up.
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
