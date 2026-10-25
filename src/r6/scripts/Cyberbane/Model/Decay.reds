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

  // Kill-dread points -0.5%/day; heat points -2%/day; archetypes x0.995/day.
  sys.AddKillDreadPoints(sys.GetKillDreadPoints() * (PowF(0.995, f) - 1.0));
  sys.AddHeatPoints(sys.GetHeatPoints() * (PowF(0.98, f) - 1.0));
  sys.DecayArchetypes(PowF(0.995, f));
  sys.RefreshPrimaryArchetype();

  let content = CyberbaneContent.Get();

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
