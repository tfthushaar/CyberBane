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
  if !IsDefined(sys) || Equals(districtId, n"") || amount <= 0.0 {
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

  CBApplyDistrictRenown(sys, origin, r.magnitude * (witnessed ? 1.0 : 0.3));
  sys.AddRumor(r);
  CBTrimRumors(sys, now);
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
      if r.hops < CBConfig.RumorMaxHops() && (now - r.lastSpreadAt) >= spreadInterval {
        CBSpreadRumor(sys, content, r, now);
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
func CBSpreadRumor(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, r: ref<CBRumor>, now: Float) -> Void {
  if !IsDefined(sys) || !IsDefined(content) || !IsDefined(r) {
    return;
  }
  let spreadMag = r.magnitude * CBConfig.RumorSpreadMagnitudeMult();
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

  let j = 0;
  while j < count {
    if CBMaskHas(addedMask, j) {
      r.reachedMask = CBMaskSet(r.reachedMask, j);
      CBApplyDistrictRenown(sys, CBDistrictAt(j), spreadMag);
    }
    j += 1;
  }

  r.hops += 1;
  r.lastSpreadAt = now;
  r.magnitude = spreadMag;
}
