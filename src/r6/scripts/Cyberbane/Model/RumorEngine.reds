// Cyberbane — Rumor engine (spec §8.5)
//
// Notable events create a rumor in their origin district, which raises District
// Renown there and then spreads to adjacent districts on the slow tick (every 6
// in-game hours, up to 2 hops, 50% magnitude per hop) before expiring after 3
// in-game days. Reputation is "local before global" (spec pillar 3).
//
// Pure logic. Origin districts come from the district signal (S-06); until that
// lands, origins are n"" and district effects are skipped, but the plumbing runs.

public func CBApplyDistrictRenown(sys: ref<CyberbaneSystem>, districtId: CName, amount: Float) -> Void {
  if Equals(districtId, n"") || amount <= 0.0 {
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
  ArrayPush(r.reached, origin);

  CBApplyDistrictRenown(sys, origin, r.magnitude * (witnessed ? 1.0 : 0.3));
  sys.AddRumor(r);
  CBTrimRumors(sys, now);
}

func CBTrimRumors(sys: ref<CyberbaneSystem>, now: Float) -> Void {
  let lifetime = CBConfig.RumorLifetimeDays() * CBConfig.SecondsPerDay();
  while ArraySize(sys.GetRumors()) > CBConfig.CapRumors() {
    let rumors = sys.GetRumors();
    let dropIdx = -1;
    let i = 0;
    while i < ArraySize(rumors) {
      if (now - rumors[i].createdAt) > lifetime {
        dropIdx = i;
        i = ArraySize(rumors);
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
  let content = CyberbaneContent.Get();
  let spreadInterval = CBConfig.RumorSpreadHours() * CBConfig.SecondsPerHour();
  let lifetime = CBConfig.RumorLifetimeDays() * CBConfig.SecondsPerDay();

  let i = 0;
  while i < ArraySize(sys.GetRumors()) {
    let r = sys.GetRumors()[i];
    if (now - r.createdAt) > lifetime {
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

func CBSpreadRumor(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, r: ref<CBRumor>, now: Float) -> Void {
  if !IsDefined(content) {
    return;
  }
  let spreadMag = r.magnitude * CBConfig.RumorSpreadMagnitudeMult();
  let newReached: array<CName>;
  for reachedId in r.reached {
    let d = content.GetDistrict(reachedId);
    if IsDefined(d) {
      for adj in d.adjacency {
        if !ArrayContains(r.reached, adj) && !ArrayContains(newReached, adj) {
          ArrayPush(newReached, adj);
        }
      }
    }
  }
  for adj in newReached {
    ArrayPush(r.reached, adj);
    CBApplyDistrictRenown(sys, adj, spreadMag);
  }
  r.hops += 1;
  r.lastSpreadAt = now;
  r.magnitude = spreadMag;
}
