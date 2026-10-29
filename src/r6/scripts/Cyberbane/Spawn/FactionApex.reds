// Cyberbane - Faction apex enforcer (spec §9.9)
//
// Put enough of one gang in the ground and they stop sending squads and send someone who
// matters: a named heavy built from the toughest member of theirs V has actually put down.
// No story character is ever involved, so this cannot spoil anything, cannot collide with a
// quest version of anyone, and works for every gang including the ones with no famous boss.
//
// V gets a line first ("Rhino of the Animals is hunting you down"), then a short beat, then
// they walk in with a couple of their people. The apex is a plain spawned enemy, not a Rival:
// it is not tracked, ranked or remembered, it is just the gang's answer to you.
//
// Crash safety: the trigger reads only persisted scalars, the spawn goes through CBSpawnGroup
// (which refuses to spawn while the world is still streaming) and runs from the gated fast
// tick, and every faction entry is bound and checked before a field is read off it.

// A name for the gang's heavy, pulled from that faction's own name pool. Deterministic for a
// given seed so the warning and anything later agree.
public func CBApexName(content: ref<CyberbaneContent>, faction: CName, seed: Int32) -> String {
  if IsDefined(content) {
    let pool = content.GetFactionNames(faction);
    if IsDefined(pool) {
      let n = ArraySize(pool.firstNames);
      if n > 0 {
        return pool.firstNames[CBHashIndex(seed, 17, n)];
      }
    }
  }
  return "Their best";
}

// Make a spawned apex actually feel like one. The base record is a gang elite, which is not a
// boss by itself, so the spawned one is lifted to boss grade: far more health, much harder to
// chew through, and its health pool topped back up because raising the stat does not refill
// what it already had. Applied at attach, where the puppet is real and its stats exist, and
// only ever to our own CB_Apex spawn - nothing in the world is touched.
// How strong should an apex be, as a fraction of a boss-grade build?
//
// The settings slider is read as a percentage, where 100 is the full set of multipliers below
// and the default 70 is most of the way there. The numbers at the top of the scale are
// deliberately in the same territory as the game's own set piece enforcers rather than
// measured against one of them: the game does not expose a boss's health as a number a script
// can read, so this is calibrated by design, not copied off a record.
//
// New Game Plus is the one case that has to be handled rather than ignored. It rebuilds every
// NPC in the game to be harder, and its buffs and Cyberbane's multiply rather than replace
// each other, so an apex under both would be unkillable. When it is running, Cyberbane steps
// its own contribution down and leaves the random traits to New Game Plus, which already
// hands them out.
public func CBApexStrengthFraction() -> Float {
  let rt = CyberbaneRuntime.Get();
  let pct = CBConfig.ApexStrengthDefault();
  if IsDefined(rt) && rt.HasSettings() {
    pct = rt.GetSettings().apexStrength;
  }
  let frac = ClampF(Cast<Float>(pct) / 100.0, 0.1, 1.0);
  if CBNgpActive() {
    frac *= CBConfig.ApexNgpStepDown();
  }
  return frac;
}

// Scale a multiplier toward 1.0 (no change) rather than toward zero.
//
// A multiplier of 1.0 means "leave this stat alone", so half of a x25 multiplier is x13, not
// x12.5. Getting this wrong at the bottom of the slider would make an apex weaker than the
// ganger it was promoted from.
public func CBApexLerp(full: Float, frac: Float) -> Float {
  return 1.0 + (full - 1.0) * frac;
}

// Give this enforcer one or two traits of its own.
//
// Borrowed in spirit from New Game Plus, which gives ordinary NPCs a random chance of being
// the fast one or the tanky one, and is the reason its enemies stay interesting long after
// you know the encounter. The same idea applied to a single boss means two apexes from the
// same gang do not fight the same way: one is wearing plate, the next one hits like a truck.
//
// Stat modifiers rather than the game's ability groups: an ability group is referenced by a
// TweakDB id, and a mistyped id fails silently at runtime where a stat type is checked by the
// compiler. These are the five stats verified present on this patch.
public func CBApplyApexTraits(game: GameInstance, stats: ref<StatsSystem>, id: StatsObjectID,
                              scale: Float, strength: Float) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() || !rt.GetSettings().apexTraits {
    return;
  }
  // New Game Plus is already rolling traits on every NPC including this one.
  if CBNgpActive() {
    return;
  }
  let first = RandRange(0, 5);
  let second = RandRange(0, 5);
  if second == first {
    second = (first + 1) % 5;
  }
  CBApexTrait(stats, id, first, scale, strength);
  CBApexTrait(stats, id, second, scale, strength);
}

func CBApexTrait(stats: ref<StatsSystem>, id: StatsObjectID, which: Int32,
                 scale: Float, strength: Float) -> Void {
  let amount = CBConfig.ApexTraitStrength() * (0.5 + scale * 0.5) * strength;
  if which == 0 {
    // Plated: more of what was already stopping bullets.
    let m = RPGManager.CreateStatModifier(gamedataStatType.Armor, gameStatModifierType.Multiplier, 1.0 + amount);
    if IsDefined(m) {
      stats.AddModifier(id, m);
    }
  } else {
    if which == 1 {
      // Brutal: hits noticeably harder than its own gang's elite.
      let m = RPGManager.CreateStatModifier(gamedataStatType.PhysicalDamage, gameStatModifierType.Multiplier, 1.0 + amount);
      if IsDefined(m) {
        stats.AddModifier(id, m);
      }
    } else {
      if which == 2 {
        // Deadeye: will find the gap in your armour.
        let c = RPGManager.CreateStatModifier(gamedataStatType.CritChance, gameStatModifierType.Additive, 20.0 * amount);
        if IsDefined(c) {
          stats.AddModifier(id, c);
        }
        let d = RPGManager.CreateStatModifier(gamedataStatType.CritDamage, gameStatModifierType.Additive, 40.0 * amount);
        if IsDefined(d) {
          stats.AddModifier(id, d);
        }
      } else {
        if which == 3 {
          // Juggernaut: simply does not go down.
          let m = RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, 1.0 + amount);
          if IsDefined(m) {
            stats.AddModifier(id, m);
          }
        } else {
          // Overclocked: fights above its level, which lifts everything the game derives from it.
          let m = RPGManager.CreateStatModifier(gamedataStatType.PowerLevel, gameStatModifierType.Additive,
            CBConfig.ApexPowerLevelBonus() * strength);
          if IsDefined(m) {
            stats.AddModifier(id, m);
          }
        }
      }
    }
  }
}

public func CBApplyApexBuff(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  CBApplyApexGradeBuff(sys, game, puppet, 1.0);
}

// How much of V's own menace this enemy is measured against.
//
// Menace already folds in level, Street Cred and skills - the same number the Hub reports - so
// a maxed-out merc meets something that can take it, and an early character meets something
// beatable rather than a wall.
public func CBMenaceScale(sys: ref<CyberbaneSystem>) -> Float {
  if !IsDefined(sys) {
    return 0.0;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return 0.0;
  }
  return ClampF(score.GetMenace() / 100.0, 0.0, 1.0);
}

// Build one enemy to apex grade, or to a fraction of it.
//
// `grade` is how much of a full apex this one should be: 1.0 for a member of an apex squad,
// less for a Rival working their way up. Split out of CBApplyApexBuff so a Rival and an apex
// are built by the same arithmetic rather than by two sets of numbers that drift apart.
public func CBApplyApexGradeBuff(sys: ref<CyberbaneSystem>, game: GameInstance,
                                 puppet: ref<ScriptedPuppet>, grade: Float) -> Void {
  if !IsDefined(puppet) {
    return;
  }
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let scale = CBMenaceScale(sys);
  // How hard the player asked for this to be, as a fraction of a boss-grade build.
  let strength = CBApexStrengthFraction() * ClampF(grade, 0.0, 1.0);
  let hpMult = CBApexLerp(CBConfig.ApexHealthMultBase() + scale * CBConfig.ApexHealthMultRange(), strength);
  let armourMult = CBApexLerp(CBConfig.ApexArmorMultBase() + scale * CBConfig.ApexArmorMultRange(), strength);

  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  let hp = RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, hpMult);
  if IsDefined(hp) {
    stats.AddModifier(id, hp);
  }
  let armour = RPGManager.CreateStatModifier(gamedataStatType.Armor, gameStatModifierType.Multiplier, armourMult);
  if IsDefined(armour) {
    stats.AddModifier(id, armour);
  }
  // Hitting back. A boss that only soaks damage is a chore; one that can actually kill you is
  // the event this is supposed to be.
  let dmgMult = CBApexLerp(CBConfig.ApexDamageMultBase() + scale * CBConfig.ApexDamageMultRange(), strength);
  let dmg = RPGManager.CreateStatModifier(gamedataStatType.PhysicalDamage, gameStatModifierType.Multiplier, dmgMult);
  if IsDefined(dmg) {
    stats.AddModifier(id, dmg);
  }
  let critC = RPGManager.CreateStatModifier(gamedataStatType.CritChance, gameStatModifierType.Additive,
    CBConfig.ApexCritChanceBonus() * scale * strength);
  if IsDefined(critC) {
    stats.AddModifier(id, critC);
  }
  let critD = RPGManager.CreateStatModifier(gamedataStatType.CritDamage, gameStatModifierType.Additive,
    CBConfig.ApexCritDamageBonus() * scale * strength);
  if IsDefined(critD) {
    stats.AddModifier(id, critD);
  }
  // And one or two things that are this particular enforcer's own.
  CBApplyApexTraits(game, stats, id, scale, strength);
  let pools = GameInstance.GetStatPoolsSystem(game);
  if IsDefined(pools) {
    pools.RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, 100.0, null);
  }
}

// Where on the ladder is this Rival?
//
// The nemesis part of the nemesis system. A Rival starts dangerous and gets worse every time
// they get away from you or you let them live, which is the deal the mechanic offers: mercy
// and failure both have a price, and the price is the person you will meet next time.
//
// Rank, escapes and mercies all count, because they are three different ways of saying the
// same thing - this one has survived you before. Returns 0..1, where 1 is a full member of an
// apex squad: by the top of the ladder a Rival is the equal of one of the four, and an apex
// squad is four of those at once.
public func CBRivalGrade(r: ref<CBRival>) -> Float {
  if !IsDefined(r) {
    return 0.0;
  }
  let steps = (r.rank - 1) + r.escapes + r.sparedByV + r.killedV;
  let span = CBConfig.RivalLadderSteps();
  if span <= 0 {
    return 1.0;
  }
  let climbed = ClampF(Cast<Float>(steps) / Cast<Float>(span), 0.0, 1.0);
  // Even a brand new Rival is somebody, not a ganger with a name.
  let floorGrade = CBConfig.RivalGradeFloor();
  return floorGrade + (1.0 - floorGrade) * climbed;
}

// Build a Rival to their place on the ladder.
public func CBApplyRivalApexBuff(sys: ref<CyberbaneSystem>, game: GameInstance,
                                 puppet: ref<ScriptedPuppet>, r: ref<CBRival>) -> Void {
  if !IsDefined(r) {
    return;
  }
  CBApplyApexGradeBuff(sys, game, puppet, CBRivalGrade(r));
}

// Slow tick: has any gang lost enough people to send its apex after V?
public func CBApexTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() && !rt.GetSettings().hitSquads {
      return;   // shares the "gangs send people after you" switch
    }
  }
  // Another mod already owns gangs coming after you. The apex is the same kind of system as a
  // hit squad, so it stands down with them rather than stacking a second wave of enemies on
  // top of theirs (spec §17). Detection is the shared They Will Remember / Night City
  // Remembers scan, so this needs no setup from the player.
  if CBTwrActive() {
    return;
  }
  if NotEquals(sys.GetPendingApexFaction(), n"") {
    return;   // one is already on the way
  }
  // Unless the player has opted into being hunted indoors, the warning does not even fire
  // in a safe area: announcing someone who then cannot be placed is worse than silence.
  if sys.IsInSafeZone() && !CBAllowSafeZoneSpawns() {
    return;   // not in a bar or a clinic (spec §16)
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    return;   // let the fight V is already in finish first
  }
  if CBStealthEncounterNearby(sys, game) {
    return;   // and do not announce one into a quiet job either
  }
  // Indoors there is nowhere for somebody to come from: they can only appear in front of you,
  // which is the thing players notice and dislike. Wait until V is out in the open.
  if CBPlayerIndoors(game) && !CBAllowSafeZoneSpawns() {
    return;
  }

  let states = sys.GetFactionStates();
  let i = 0;
  while i < ArraySize(states) {
    let fs = states[i];
    i += 1;
    if IsDefined(fs) && NotEquals(fs.id, n"") {
      // Their toughest if V has met one, otherwise whoever V has been fighting.
      let record = TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
      if TDBID.IsValid(record) && (fs.kills - fs.apexAtKills) >= CBConfig.ApexKillThreshold() {
        // The kills are spent in CBProcessPendingApex, and only once someone has actually
        // arrived. Spending them here meant a spawn that failed for any reason quietly cost
        // the player twenty bodies and they simply never saw an apex.
        sys.SetPendingApex(fs.id, CBConfig.ApexWarningTicks());

        let name = CBApexName(CBContent(game), fs.id, fs.kills);
        if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
          CBShowMessage(game, s"Cyberbane: \(name) is bringing an apex squad of the \(NameToString(fs.id)) after you. Watch yourself.", 5.0);
        }
        CBLog.Info(n"Spawn", s"Faction apex inbound for \(NameToString(fs.id)).");
        return;   // only ever one gang at a time
      }
    }
  }
}

// Fast tick: the warning has had its moment, bring them in.
public func CBProcessPendingApex(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let faction = sys.GetPendingApexFaction();
  if Equals(faction, n"") {
    return;
  }
  // Hold the clock rather than spending it: if the apex is due while V is picking a place
  // apart quietly, it waits at the door instead of arriving and blowing the job.
  if CBStealthEncounterNearby(sys, game) {
    return;
  }
  if sys.TickDownPendingApex() > 0 {
    return;   // still counting the warning down
  }
  sys.SetPendingApex(n"", 0);

  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  let record = TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
  if !TDBID.IsValid(record) {
    return;
  }
  // An apex turning up on foot out of nowhere was the other half of the arrival complaint.
  // If a car can get here, the escort drives it in and the apex comes with them; the walk-in
  // below stays for indoors and anywhere a car cannot be placed.
  // A carload of them, all boss grade - the gang's answer to MaxTac rather than one heavy
  // with a lift. Every seat is tagged CB_Apex, so every one of them gets the full buff, and
  // the strength slider is how a player dials that back if four at once is too much.
  if CBSpawnVehicleArrival(sys, game, fs.id, record, CBConfig.ApexStrikeTeamSize(), n"CB_Apex",
                           record, n"CB_Apex") {
    sys.MarkArrivalRoleSquad(fs.id);
    sys.ClearSquadAnchor();
    fs.apexAtKills = fs.kills;
    CBLog.Info(n"Spawn", s"Apex from \(NameToString(fs.id)) arriving by car.");
    return;
  }
  // CBSpawnGroup will refuse while the world is still streaming in, so this can only land on
  // a settled frame. CB_Apex is also tagged n"Cyberbane", so the session sweep clears it.
  let apexEntity: EntityID;
  let arrived = CBSpawnGroup(game, record, n"", 1, n"CB_Apex", CBConfig.ApexSpawnDistance(), apexEntity);
  if arrived <= 0 {
    // The world was not settled enough to place anyone. Keep the kills on the books so the
    // next slow tick tries again, rather than charging the player for a no-show.
    CBLog.Info(n"Spawn", s"Apex spawn for \(NameToString(faction)) did not land; it will try again.");
    return;
  }
  fs.apexAtKills = fs.kills;   // paid for: the next one needs fresh bodies
  if CBConfig.ApexEscortCount() > 0 && TDBID.IsValid(fs.sampleRecord) {
    let escortEntity: EntityID;
    CBSpawnGroup(game, fs.sampleRecord, n"", CBConfig.ApexEscortCount(), n"CB_Squad",
      CBConfig.ApexSpawnDistance() + 4.0, escortEntity);
  }
}
