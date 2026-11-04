// Cyberbane - Decay (spec §8.9)
//
// Applied on the slow tick (each in-game hour) with the fraction of an in-game
// day that elapsed. Pure: operates on the stored accumulators and faction/district
// state. Scaled by the decay setting; skipped entirely when reputation is frozen.

public func CBApplyDecay(sys: ref<CyberbaneSystem>, elapsedDays: Float) -> Void {
  if !IsDefined(sys) || elapsedDays <= 0.0 {
    return;
  }
  let decayMult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    if rt.GetSettings().freezeReputation {
      return;
    }
    decayMult = rt.GetSettings().decayMult;
  }
  let f = elapsedDays * decayMult;

  // The body count and the jobs fade while V lies low, a few points of each a day, down to what
  // V's whole record still earns. Until 1.6.4 the body count lost half a percent of its points a
  // day and the jobs nothing at all, so between them more than half of Dread only ever went up
  // (see CBFadeDreadPoints for why fading the points could not have fixed it). Heat points -2%/day;
  // archetypes x0.995/day.
  let kNow = sys.GetKillDreadPoints();
  let kNext = CBFadeDreadPoints(kNow, CBConfig.KillDreadCurveScale(),
                                CBConfig.KillDreadFadePerDay() * f, CBKillDreadFloor(sys));
  sys.AddKillDreadPoints(kNext - kNow);
  let xNow = sys.GetDeedDreadPoints();
  let xNext = CBFadeDreadPoints(xNow, CBConfig.DeedDreadCurveScale(),
                                CBConfig.DeedDreadFadePerDay() * f, CBDeedDreadFloor(sys));
  sys.AddDeedDreadPoints(xNext - xNow);
  sys.AddHeatPoints(sys.GetHeatPoints() * (PowF(0.98, f) - 1.0));
  sys.DecayArchetypes(PowF(0.995, f));
  sys.RefreshPrimaryArchetype();

  let content = sys.GetContent();

  // Faction renown decays toward a floor; standing drifts toward its baseline.
  for fs in sys.GetFactionStates() {
    let floorR = fs.renownPeak * CBConfig.RfFloorFraction();
    fs.renown = MaxF(floorR, fs.renown - CBConfig.RfDecayPerDay() * f);

    let baseline = 0.0;
    if IsDefined(content) {
      let prof = content.GetFaction(fs.id);
      if IsDefined(prof) {
        baseline = prof.baselineStanding;
      }
    }
    let rate = fs.standing > -70.0 ? 1.0 : 0.25;
    if fs.standing < baseline {
      fs.standing = MinF(baseline, fs.standing + rate * f);
    } else {
      if fs.standing > baseline {
        fs.standing = MaxF(baseline, fs.standing - rate * f);
      }
    }
  }

  // District renown decays toward its floor.
  for ds in sys.GetDistrictStates() {
    let floorD = ds.renownPeak * CBConfig.RdFloorFraction();
    ds.renown = MaxF(floorD, ds.renown - CBConfig.RdDecayPerDay() * f);
  }

  sys.GetScore().MarkDirty();
}

// What V's body count can never fade below: everybody V has ever killed. A few dozen bodies fade
// to almost nothing; a few hundred leave something people never quite forget.
public func CBKillDreadFloor(sys: ref<CyberbaneSystem>) -> Float {
  if !IsDefined(sys) {
    return 0.0;
  }
  let kills = Cast<Float>(sys.TotalKills());
  return CBConfig.KillDreadFloorMax() * (1.0 - ExpF(-kills / CBConfig.KillDreadFloorKills()));
}

// And the jobs: a share of what every job V finished was worth, and of the killing nobody could
// put a name to. The street keeps the story long after it stops telling it.
public func CBDeedDreadFloor(sys: ref<CyberbaneSystem>) -> Float {
  if !IsDefined(sys) {
    return 0.0;
  }
  let pts = 0.0;
  let content = sys.GetContent();
  if IsDefined(content) {
    for id in sys.GetDeedsDone() {
      let def = content.GetDeed(id);
      if IsDefined(def) {
        pts += def.dread;
      }
    }
  }
  let stats = sys.GetStats();
  if IsDefined(stats) {
    pts += Cast<Float>(stats.unattributed) * CBConfig.UnattributedDeedDread();
  }
  return CBDeedDreadComponent(pts * CBConfig.DeedDreadFloorShare());
}
