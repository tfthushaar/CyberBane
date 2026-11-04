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

  // Laying Low (spec 11.5), which was specified from the beginning and never wired: three in-game
  // days without putting anybody down and the parts of V's reputation that fade do so twice as
  // fast, until the next one. It applies to what 11.5 names - the body count, police history and
  // faction renown - and to the jobs, which joined the fading set in 1.6.4 on exactly the same
  // "while V lies low" reasoning and would read oddly as the one thing a quiet spell did not
  // touch. Deliberately *not* applied to three things, so the next reader knows each was a choice
  // rather than an oversight: the archetype mix and standing drifting back to its baseline, which
  // are V's own shape and the gangs' settled opinion rather than the city's memory of what V did;
  // and district renown, because 11.5 names faction renown and local fame fading at double rate
  // would quietly undo the district-by-district spread the mod is built on.
  let quiet = f;
  if CBIsLayingLow(sys, CBGameSeconds(sys.GetGameInstance())) {
    quiet = f * CBConfig.LayingLowMult();
  }

  // The body count and the jobs fade while V lies low, a few points of each a day, down to what
  // V's whole record still earns. Until 1.6.4 the body count lost half a percent of its points a
  // day and the jobs nothing at all, so between them more than half of Dread only ever went up
  // (see CBFadeDreadPoints for why fading the points could not have fixed it). Heat points -2%/day;
  // archetypes x0.995/day.
  let kNow = sys.GetKillDreadPoints();
  let kNext = CBFadeDreadPoints(kNow, CBConfig.KillDreadCurveScale(),
                                CBConfig.KillDreadFadePerDay() * quiet, CBKillDreadFloor(sys));
  sys.AddKillDreadPoints(kNext - kNow);
  let xNow = sys.GetDeedDreadPoints();
  let xNext = CBFadeDreadPoints(xNow, CBConfig.DeedDreadCurveScale(),
                                CBConfig.DeedDreadFadePerDay() * quiet, CBDeedDreadFloor(sys));
  sys.AddDeedDreadPoints(xNext - xNow);
  sys.AddHeatPoints(sys.GetHeatPoints() * (PowF(0.98, quiet) - 1.0));
  sys.DecayArchetypes(PowF(0.995, f));
  sys.RefreshPrimaryArchetype();

  let content = sys.GetContent();

  // Faction renown decays toward a floor; standing drifts toward its baseline.
  for fs in sys.GetFactionStates() {
    let floorR = fs.renownPeak * CBConfig.RfFloorFraction();
    fs.renown = MaxF(floorR, fs.renown - CBConfig.RfDecayPerDay() * quiet);

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

// ---- Laying Low (spec 11.5) ------------------------------------------------------------------

// The last time V put anybody down anywhere, lethally or not, in game seconds. 0 if V never has.
//
// Read off state that is already saved rather than recorded again: `lastIncidentAt` is written on
// every kill, on both the faction and the district (Model/Reputation.reds, CBApplyKill), and the
// write sits outside the lethal branch, so a non-lethal takedown counts exactly as 11.5 says it
// should. Both are walked because a kill with no gang behind it still stamps its district, and one
// in no district still stamps its gang - so neither on its own sees everything V does.
//
// Doing it this way is the point: a new `persistent let` on anything the save holds would wipe
// every player's Cyberbane state (see the warning at the top of STATUS.md), and laying low is not
// worth that. Nothing new is stored at all.
public func CBLastIncidentAt(sys: ref<CyberbaneSystem>) -> Float {
  if !IsDefined(sys) {
    return 0.0;
  }
  let last = 0.0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) {
      last = MaxF(last, fs.lastIncidentAt);
    }
  }
  for ds in sys.GetDistrictStates() {
    if IsDefined(ds) {
      last = MaxF(last, ds.lastIncidentAt);
    }
  }
  return last;
}

// Is V lying low: long enough since the last one that the city has started to lose interest?
public func CBIsLayingLow(sys: ref<CyberbaneSystem>, now: Float) -> Bool {
  let last = CBLastIncidentAt(sys);
  if last <= 0.0 || now < last {
    // Never hurt anybody, so there is nothing to lie low from; or a clock that reads earlier than
    // the record, which is not a quiet spell either.
    return false;
  }
  return (now - last) >= CBConfig.LayingLowDays() * CBConfig.SecondsPerDay();
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
