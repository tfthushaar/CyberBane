// Cyberbane - The grudge clock (2.6.5)
//
// "The default frequency of people chasing you for revenge is a little too high." "No, let's not keep a cap: let the
// whole queue work on standing with the gang." "And the more we break a gang, the less often they come. Consider all
// factors."
//
// Until 2.6.5 a day had a shape fixed in advance: a timetable of windows built from three per-day sliders (8 Rivals, 5
// crews, 4 apex squads), and whoever scored highest filled each window. How a gang stood with V decided who came, never
// whether or how often. Now there is no day's allowance at all. Each gang holding a grudge has its own patience, and moves
// when it has run out; each Rival has theirs. The lanes (Spawn/Queue.reds) still send one of each kind at a time, with a
// breather after each (Encounter gap), so two fights never land on top of each other; that is all that is left of pacing.
//
// A gang's patience, in game hours, starts from how hot its grudge runs and is then stretched or shortened by what it
// would weigh before sending anybody:
//
//   the grudge     just over the line into Hostile, about a day between moves; at the bottom of Vendetta, three hours
//   a fresh wound  V hurt them within GrudgeFreshHours: they move sooner
//   manpower       the more of them V has put down, the longer they take to find anybody to send (Model/Territory.reds);
//                  a gang that is all but broken barely comes at all, and fields no apex squad
//   a beaten crew  the last crew they sent was beaten: they regroup first (an apex squad is how they answer that)
//   fear of V      a frightening V, to a gang that frightens easily (the faction's dread), keeps them home longer
//   their own war  at war with another gang over a district: busy
//   distance       V on their streets is round the corner; across town it takes them longer to come
//   a mask         V they cannot place takes longer to find
//   knowing V      a gang that has only heard of V looks harder than one that knows V's face
//   their code     a gang that sends many (Barghest) is quicker to it than one that sends few (the Mox)
//   the hour       night is theirs
//   the setting    How eager gangs are (hitSquadFrequencyMult)
//
// A Rival's patience is personal: the steps they have climbed against V (rank, escapes, mercies, V's deaths), their gang's
// grudge counted for less, a Grudge-Bearer quicker, their own streets and the night quicker, a mask slower, and How eager
// Rivals are. Their gang being broken slows them only a little: it is personal.
//
// Read only from what the save already keeps (standing, renown, kills, lastIncidentAt, lastHitSquadAt, lastPeaceAt, a
// Rival's lastSeenAt and createdAt) and the live world, so no persistent field changes and every save carries over.

public func CBGrudgeHostileLine() -> Float = CBConfig.PostureHostile()

// How hot a gang's grudge runs: -1 for no grudge (not hostile to V by its acting standing), else 0 just over the line
// into Hostile to 1 at the bottom of Vendetta.
public func CBGrudgeHeat(fs: ref<CBFactionState>) -> Float {
  if !IsDefined(fs) {
    return -1.0;
  }
  let st = CBActingStanding(fs.id, fs.standing);
  let line = CBGrudgeHostileLine();
  if st > line {
    return -1.0;
  }
  return ClampF((line - st) / (line + 100.0), 0.0, 1.0);
}

// How much of a gang is left to send, 0 to 1 (Model/Territory.reds, CBGangStrength).
func CBGrudgeManpower(sys: ref<CyberbaneSystem>, faction: CName) -> Float {
  return ClampF(CBGangStrength(sys, faction) / 100.0, 0.0, 1.0);
}

// Is this gang fighting another over a district right now?
func CBGrudgeAtWar(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Bool {
  let content = sys.GetContent();
  if !IsDefined(content) {
    return false;
  }
  let others = CBGangRivalsOf(content, faction);
  for o in others {
    if CBWebAtWar(sys, game, faction, o) {
      return true;
    }
  }
  return false;
}

func CBGrudgeHourOfNight(game: GameInstance) -> Float {
  return CBIsNight(game) ? CBConfig.GrudgeNightMult() : 1.0;
}

// A gang's patience, in game hours. -1 when it holds no grudge.
public func CBGangPatienceHours(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>) -> Float {
  let heat = CBGrudgeHeat(fs);
  if heat < 0.0 || !IsDefined(sys) {
    return -1.0;
  }
  let hours = CBConfig.GrudgeSlowHours() + (CBConfig.GrudgeFastHours() - CBConfig.GrudgeSlowHours()) * heat;
  let now = CBGameSeconds(game);
  let hour = CBConfig.SecondsPerHour();
  // A fresh wound.
  if fs.lastIncidentAt > 0.0 && now >= fs.lastIncidentAt && now - fs.lastIncidentAt < CBConfig.GrudgeFreshHours() * hour {
    hours *= CBConfig.GrudgeFreshMult();
  }
  // Manpower: broken gangs take far longer to find anybody to send.
  let left = CBGrudgeManpower(sys, fs.id);
  hours *= 1.0 + CBConfig.GrudgeBrokenWeight() * PowF(1.0 - left, 1.5);
  // Their last crew was beaten: regroup.
  if sys.CrewBeaten(fs.id) {
    hours *= CBConfig.GrudgeRegroupMult();
  }
  // Fear of V, by how easily this gang frightens.
  let content = sys.GetContent();
  let prof = IsDefined(content) ? content.GetFaction(fs.id) : null;
  let dread = IsDefined(prof) ? prof.dreadSens : 1.0;
  hours *= 1.0 + CBConfig.GrudgeFearWeight() * CBMenaceScale(sys) * ClampF(dread, 0.0, 2.0);
  // Busy with a war of their own.
  if CBGrudgeAtWar(sys, game, fs.id) {
    hours *= CBConfig.GrudgeAtWarMult();
  }
  // Distance: on their streets, round the corner; otherwise a district at a time.
  let turf = CBTurfGangsHere(sys);
  if ArrayContains(turf, fs.id) {
    hours *= CBConfig.GrudgeOnTurfMult();
  } else {
    let hops = CBGangHopsToV(sys, game, fs.id);
    if hops > 0 {
      hours *= 1.0 + CBConfig.GrudgeHopWeight() * Cast<Float>(Min(hops, 4));
    }
  }
  // A V they cannot place, or barely know.
  if CBPlayerMasked(game) {
    hours *= CBConfig.GrudgeMaskMult();
  }
  hours *= 1.5 - 0.5 * ClampF(fs.renown / 100.0, 0.0, 1.0);
  // Their code, and the hour.
  hours /= MaxF(CBCodeCrew(fs.id), 0.25);
  hours *= CBGrudgeHourOfNight(game);
  // A merc they have barely heard of (2.7.0): finding out who it was, and whether they are worth a crew, takes longer.
  hours *= CBConfig.EarlyPatienceMult() - (CBConfig.EarlyPatienceMult() - 1.0) * CBMercStanding(game);
  // The player's say.
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    hours /= MaxF(rt.GetSettings().hitSquadFrequencyMult, 0.05);
  }
  return MaxF(hours, CBConfig.GrudgeFloorHours());
}

// When this gang last moved against V, or made peace: game seconds, 0 for never. A gang that has never sent anybody is
// counted from the last time V hurt them, so a grudge that has just begun waits its turn too.
func CBGangLastMove(fs: ref<CBFactionState>) -> Float {
  let last = MaxF(fs.lastHitSquadAt, fs.lastPeaceAt);
  return last > 0.0 ? last : fs.lastIncidentAt;
}

// Game seconds until this gang moves: 0 now, -1 never (no grudge).
public func CBGangMovesIn(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>) -> Float {
  let hours = CBGangPatienceHours(sys, game, fs);
  if hours < 0.0 {
    return -1.0;
  }
  let last = CBGangLastMove(fs);
  if last <= 0.0 {
    return 0.0;
  }
  let now = CBGameSeconds(game);
  let due = last + hours * CBConfig.SecondsPerHour();
  return now >= due ? 0.0 : due - now;
}

public func CBGangReady(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>) -> Bool {
  return CBGangMovesIn(sys, game, fs) == 0.0;
}

// Their best, too (an apex squad): earned the way it always was (CBApexEligible), and only by a gang with the people to
// field them. A broken gang sends nobody of that grade.
public func CBApexReady(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> Bool {
  return CBApexOnSetting() && CBApexEligible(sys, fs) && CBGrudgeManpower(sys, fs.id) >= CBConfig.GrudgeApexMinManpower();
}

public func CBApexOnSetting() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().apexSquadsOn;
}

// A Rival's patience, in game hours.
public func CBRivalPatienceHours(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Float {
  if !IsDefined(r) || !IsDefined(sys) {
    return -1.0;
  }
  let steps = (r.rank - 1) + r.escapes + r.sparedByV + r.killedV;
  let grudge = ClampF(Cast<Float>(steps) / Cast<Float>(Max(1, CBConfig.RivalLadderSteps())), 0.0, 1.0);
  let fs = sys.FindFaction(r.faction);
  let gang = MaxF(CBGrudgeHeat(fs), 0.0);
  let heat = MaxF(grudge, gang * CBConfig.GrudgeRivalGangShare());
  let hours = CBConfig.GrudgeRivalSlowHours() + (CBConfig.GrudgeRivalFastHours() - CBConfig.GrudgeRivalSlowHours()) * heat;
  if CBRivalHasTrait(r, n"GrudgeBearer") {
    hours *= 0.5;
  }
  let turf = CBTurfGangsHere(sys);
  if ArrayContains(turf, r.faction) || (NotEquals(r.origin, n"") && Equals(r.origin, sys.GetCurrentDistrict())) {
    hours *= CBConfig.GrudgeOnTurfMult();
  }
  // It is personal: a broken gang slows its Rival only a little.
  hours *= 1.0 + 0.5 * PowF(1.0 - CBGrudgeManpower(sys, r.faction), 1.5);
  if CBPlayerMasked(game) {
    hours *= CBConfig.GrudgeMaskMult();
  }
  hours *= CBGrudgeHourOfNight(game);
  // Finding a merc with no name yet takes longer (2.7.0).
  hours *= CBConfig.EarlyPatienceMult() - (CBConfig.EarlyPatienceMult() - 1.0) * CBMercStanding(game);
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    hours /= MaxF(rt.GetSettings().rivalFrequencyMult, 0.05);
  }
  return MaxF(hours, CBConfig.GrudgeFloorHours());
}

// Game seconds until this Rival comes looking: 0 now.
public func CBRivalMovesIn(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Float {
  let hours = CBRivalPatienceHours(sys, game, r);
  if hours < 0.0 {
    return -1.0;
  }
  let last = MaxF(r.lastSeenAt, r.createdAt);
  if last <= 0.0 {
    return 0.0;
  }
  let now = CBGameSeconds(game);
  let due = last + hours * CBConfig.SecondsPerHour();
  return now >= due ? 0.0 : due - now;
}

public func CBRivalReady(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  return CBRivalMovesIn(sys, game, r) == 0.0;
}

// The soonest any candidate for this lane moves, in game seconds (0 now, -1 nobody), and whose clock it is.
public func CBGrudgeNextIn(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32, out faction: CName,
                           out rivalId: Int32) -> Float {
  faction = n"";
  rivalId = 0;
  let best = -1.0;
  if !IsDefined(sys) {
    return best;
  }
  if lane == CBLaneRival() {
    if !CBRivalsOn() {
      return best;
    }
    for r in sys.GetRivals() {
      if IsDefined(r) && r.huntTicks <= 0 && CBRivalQueueable(sys, r.id) {
        let inR = CBRivalMovesIn(sys, game, r);
        if inR >= 0.0 && (best < 0.0 || inR < best) {
          best = inR;
          faction = r.faction;
          rivalId = r.id;
        }
      }
    }
    // Nobody on the roster yet: the lane makes its first Rival from a gang V has fought (CBLanePick, CBSeedRivalFromFactions),
    // when that gang's grudge is ready. Without this an empty roster was never due, and no first Rival was ever made.
    if best < 0.0 && sys.CountActiveRivals() == 0 {
      for fs in sys.GetFactionStates() {
        if IsDefined(fs) && fs.kills > 0 && TDBID.IsValid(fs.sampleRecord) && CBFactionFieldsSquads(fs.id) {
          let inS = CBGangMovesIn(sys, game, fs);
          if inS >= 0.0 && (best < 0.0 || inS < best) {
            best = inS;
            faction = fs.id;
          }
        }
      }
    }
    return best;
  }
  if !CBHitSquadsOn() {
    return best;
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) {
      let inG = -1.0;
      if lane == CBLaneApex() {
        inG = CBApexReady(sys, fs) ? 0.0 : -1.0;
      } else {
        // Ready means they would really come: known to them, and a reason today (CBCrewReason), the lane's own tests.
        let score = sys.GetScore();
        let turf = CBTurfGangsHere(sys);
        let posture = IsDefined(score) ? score.GetPosture(fs.id) : ECBPosture.Neutral;
        if TDBID.IsValid(fs.sampleRecord) && (fs.renown >= CBConfig.HitSquadMinRenown() || CBGangViewHunts(fs.id))
           && CBCrewReason(sys, fs, posture, ArrayContains(turf, fs.id), CBGameSeconds(game)) >= 0.0 {
          inG = CBGangMovesIn(sys, game, fs);
        }
      }
      if inG >= 0.0 && (best < 0.0 || inG < best) {
        best = inG;
        faction = fs.id;
      }
    }
  }
  return best;
}
