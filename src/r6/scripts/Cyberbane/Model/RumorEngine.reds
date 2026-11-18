// Cyberbane - Rumor engine (spec §8.5)
//
// Notable events create a rumor in their origin district, which raises District
// Renown there and then spreads to adjacent districts on the slow tick (every 6
// in-game hours, up to 2 hops, 50% magnitude per hop) before expiring after 3
// in-game days. Reputation is "local before global" (spec pillar 3).
//
// Pure logic. Origin districts come from the district signal (S-06); until that
// lands, origins are n"" and district effects are skipped, but the plumbing runs.

public func CBApplyDistrictRenown(sys: ref<CyberbaneSystem>, districtId: CName, amount: Float) -> Void {
  if !IsDefined(sys) || Equals(districtId, n"") || amount <= 0.0 || CBReputationFrozen() {
    return;
  }
  let ds = sys.EnsureDistrict(districtId);
  ds.renown = ClampF(ds.renown + amount, 0.0, 100.0);
  ds.renownPeak = MaxF(ds.renownPeak, ds.renown);
  sys.GetScore().MarkDirty();
}

public func CBCreateRumor(sys: ref<CyberbaneSystem>, game: GameInstance, kind: CName, magnitude: Float, origin: CName, faction: CName, witnessed: Bool) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let spreadMult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    spreadMult = rt.GetSettings().rumorSpreadMult;
  }
  let now = CBGameSeconds(game);

  let r = new CBRumor();
  r.id = sys.AllocateRumorId();
  r.kind = kind;
  r.magnitude = magnitude * spreadMult;
  r.origin = origin;
  r.faction = faction;
  r.createdAt = now;
  r.lastSpreadAt = now;
  r.hops = 0;
  r.witnessed = witnessed;
  r.reachedMask = CBMaskSet(0, CBDistrictIndex(origin));   // unknown origin sets no bit

  CBApplyDistrictRenown(sys, origin, r.magnitude * (witnessed ? 1.0 : CBConfig.UnwitnessedSpreadMult()));
  CBBraindanceGoesRound(sys, game, r);
  sys.AddRumor(r);
  CBTrimRumors(sys, now);
}

public func CBBraindanceOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().braindanceGoesRound;
}

// The braindance goes round ([9], 2.3.1). Somebody had a recorder running: a deed big enough, done where people
// could see V's face, is on every BD stall in the city at once. It reaches every district in one go, at the
// strength a story has after one hop, and goes no further (there is nowhere further to go). Through the same
// renown and the same grapevine as any rumour, so nothing reads it twice.
func CBBraindanceGoesRound(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRumor>) -> Void {
  if !CBBraindanceOn() || !IsDefined(r) || !r.witnessed || r.magnitude < CBConfig.BraindanceMinMagnitude()
     || CBDistrictIndex(r.origin) < 0 || RandF() >= CBConfig.BraindanceChance() {
    return;
  }
  let mag = r.magnitude * CBConfig.RumorSpreadMagnitudeMult();
  let i = 0;
  while i < CBDistrictCount() {
    if !CBMaskHas(r.reachedMask, i) {
      r.reachedMask = CBMaskSet(r.reachedMask, i);
      CBApplyDistrictRenown(sys, CBDistrictAt(i), mag);
    }
    i += 1;
  }
  r.hops = CBConfig.RumorMaxHops();
  CBLog.Info(n"Model", s"\(NameToString(r.kind)) went round as a braindance.");
  if CBToastsOn() {
    let where = CBDistrictLabel(r.origin);
    CBHearsayFromStreet(game, CBPick3(
      "Somebody had a recorder running. What you did" + (StrLen(where) > 0 ? " in " + where : "") + " is on every BD stall from Kabuki to Pacifica.",
      "It's a braindance now. Kids in Japantown are playing your night on repeat.",
      "Every scroller in the city has the footage. Your face, frame by frame."), n"");
  }
}

// Drop rumors once the store is over its cap, oldest-expired first.
//
// Every element is fetched through GetRumorAt, which indexes the live persistent array
// directly. Never index the array returned by GetRumors(): that getter returns the array
// *by value*, so indexing the call result reads out of a temporary copy that is torn down
// at the end of the statement, leaving a handle to freed memory (crash safety).
func CBTrimRumors(sys: ref<CyberbaneSystem>, now: Float) -> Void {
  let lifetime = CBConfig.RumorLifetimeDays() * CBConfig.SecondsPerDay();
  let guardTrips = 0;
  while sys.GetRumorCount() > CBConfig.CapRumors() {
    // Belt and braces: a store that somehow never shrinks must not spin forever.
    guardTrips += 1;
    if guardTrips > CBConfig.CapRumors() * 2 {
      return;
    }
    let dropIdx = -1;
    let i = 0;
    let count = sys.GetRumorCount();
    while i < count {
      let r = sys.GetRumorAt(i);
      if !IsDefined(r) || (now - r.createdAt) > lifetime {
        dropIdx = i;
        i = count;
      } else {
        i += 1;
      }
    }
    if dropIdx < 0 {
      dropIdx = 0;   // none expired: drop the oldest
    }
    sys.RemoveRumorAt(dropIdx);
  }
}

// Called on the slow tick: expire old rumors and spread eligible ones.
public func CBRumorTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let now = CBGameSeconds(game);
  let content = CBContent(game);
  if !IsDefined(content) {
    return;   // nothing to spread into without the district table
  }
  let spreadInterval = CBConfig.RumorSpreadHours() * CBConfig.SecondsPerHour();
  let lifetime = CBConfig.RumorLifetimeDays() * CBConfig.SecondsPerDay();

  let i = 0;
  while i < sys.GetRumorCount() {
    let r = sys.GetRumorAt(i);
    // A hole in the store (a rumor that failed to come back from the save) is dropped
    // rather than dereferenced.
    if !IsDefined(r) || (now - r.createdAt) > lifetime {
      sys.RemoveRumorAt(i);
      // array shifted: do not advance i
    } else {
      // A district that talks moves a story on sooner ([6], Data/Districts.reds).
      if r.hops < CBConfig.RumorMaxHops() && (now - r.lastSpreadAt) >= spreadInterval / MaxF(CBTemperWord(r.origin), 0.1) {
        CBSpreadRumor(sys, game, content, r, now);
      }
      i += 1;
    }
  }
}

// Spread a rumor one hop outward: every district adjacent to one it has already reached
// picks it up at half magnitude.
//
// The "already reached" set is a bit per district on the rumor itself, and the walk is a
// counted loop over the fixed district list - there is no stored list to index into and
// nothing here can run past the end of anything, whatever a save hands back.
func CBSpreadRumor(sys: ref<CyberbaneSystem>, game: GameInstance, content: ref<CyberbaneContent>, r: ref<CBRumor>, now: Float) -> Void {
  if !IsDefined(sys) || !IsDefined(content) || !IsDefined(r) {
    return;
  }
  // Word nobody could attribute carries badly: it reaches the next district as a mutter
  // rather than a name, which is what keeps no-witness play local (spec §8.5).
  let spreadMag = r.magnitude * CBConfig.RumorSpreadMagnitudeMult();
  if !r.witnessed {
    spreadMag *= CBConfig.UnwitnessedSpreadMult();
  }
  let reached = r.reachedMask;
  let addedMask = 0;
  let count = CBDistrictCount();

  let i = 0;
  while i < count {
    if CBMaskHas(reached, i) {
      let d = content.GetDistrict(CBDistrictAt(i));
      if IsDefined(d) {
        for adj in d.adjacency {
          let bit = CBDistrictIndex(adj);
          if bit >= 0 && !CBMaskHas(reached, bit) && !CBMaskHas(addedMask, bit) {
            addedMask = CBMaskSet(addedMask, bit);
          }
        }
      }
    }
    i += 1;
  }

  let firstNew = n"";
  let j = 0;
  while j < count {
    if CBMaskHas(addedMask, j) {
      r.reachedMask = CBMaskSet(r.reachedMask, j);
      CBApplyDistrictRenown(sys, CBDistrictAt(j), spreadMag);
      if Equals(firstNew, n"") {
        firstNew = CBDistrictAt(j);
      }
    }
    j += 1;
  }

  // Word reaching somewhere new is the moment it is worth hearing about (spec §8.5).
  // Fired once per hop, not once per district, and rate-limited inside.
  if NotEquals(firstNew, n"") {
    CBGrapevineOnReach(sys, game, r, firstNew, now);
  }

  r.hops += 1;
  r.lastSpreadAt = now;
  r.magnitude = spreadMag;
}
