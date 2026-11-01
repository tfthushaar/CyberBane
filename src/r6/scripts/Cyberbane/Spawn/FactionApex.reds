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
// This used to add its own stat modifiers, and that is the mistake the whole rebalance is
// about. A trait landing on Health put a second multiplier on top of the grade buff's, and
// nothing anywhere knew the product of the two. It rolls the numbers and hands them back now,
// so the one place that applies anything can see everything and clamp it.
func CBRollApexTraits(scale: Float, strength: Float,
                      out health: Float, out armour: Float, out damage: Float,
                      out critChance: Float, out critDamage: Float, out power: Float) -> Void {
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
  CBRollOneApexTrait(first, scale, strength, health, armour, damage, critChance, critDamage, power);
  CBRollOneApexTrait(second, scale, strength, health, armour, damage, critChance, critDamage, power);
}

func CBRollOneApexTrait(which: Int32, scale: Float, strength: Float,
                        out health: Float, out armour: Float, out damage: Float,
                        out critChance: Float, out critDamage: Float, out power: Float) -> Void {
  let amount = CBConfig.ApexTraitStrength() * (0.5 + scale * 0.5) * strength;
  if which == 0 {
    armour += amount;              // Plated: more of what was already stopping bullets.
  } else {
    if which == 1 {
      damage += amount;            // Brutal: hits harder than its own gang's elite.
    } else {
      if which == 2 {
        critChance += 20.0 * amount;   // Deadeye: will find the gap in your armour.
        critDamage += 40.0 * amount;
      } else {
        if which == 3 {
          health += amount;        // Juggernaut: takes some putting down.
        } else {
          // Overclocked: fights above its level. Clamped hard by the caller, because the game
          // derives health, armour and damage from power level, so this one term quietly
          // multiplies the other three. Ten of them was the largest single contributor to the
          // enemy nobody could kill.
          power += CBConfig.ApexPowerLevelBonus() * strength;
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
// less for a Rival working their way up.
public func CBApplyApexGradeBuff(sys: ref<CyberbaneSystem>, game: GameInstance,
                                 puppet: ref<ScriptedPuppet>, grade: Float) -> Void {
  CBApplyApexBuild(sys, game, puppet, grade, 1.0);
}

// The one place anything is ever done to a spawned enemy's stats.
//
// Everything that used to be applied separately - the grade multipliers, the random traits,
// the bonus a Rival running a crew gets - is combined here into one multiplier per stat and
// clamped against the ceilings in Config before a single modifier is created.
//
// That is the fix for the enemies players could not kill, and it is structural rather than a
// tuning pass. Three functions each added a term and none of them could see the others, so
// nothing in the codebase knew what it was building: at the top of the scale a Rival leading a
// crew came out near eleven times health behind three and a half times armour, several power
// levels above the gang it came from, and every individual number that produced it looked
// reasonable in isolation.
//
// `roleHealthMult` is the crew-rank bonus, 1.0 for anybody who is not running one.
// `traitHealth`, `traitArmour`, `traitDamage` and `traitCrit` are a Rival's own traits and
// weaknesses (CBRivalTraitTerms): fractions added to, or taken off, the same terms the random
// traits use, so they are clamped by the same ceilings and can never stack past them.
public func CBApplyApexBuild(sys: ref<CyberbaneSystem>, game: GameInstance,
                             puppet: ref<ScriptedPuppet>, grade: Float, roleHealthMult: Float,
                             opt traitHealth: Float, opt traitArmour: Float,
                             opt traitDamage: Float, opt traitCrit: Float) -> Void {
  if !IsDefined(puppet) {
    return;
  }
  // Once only. Stat modifiers add on top of each other, so a second pass squares every
  // multiplier and produces something nothing can hurt.
  if puppet.cbBuffed {
    return;
  }
  puppet.cbBuffed = true;
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let scale = CBMenaceScale(sys);
  // How hard the player asked for this to be, as a fraction of a boss-grade build.
  let strength = CBApexStrengthFraction() * ClampF(grade, 0.0, 1.0);

  let tHealth = 0.0;
  let tArmour = 0.0;
  let tDamage = 0.0;
  let tCritChance = 0.0;
  let tCritDamage = 0.0;
  let tPower = 0.0;
  CBRollApexTraits(scale, strength, tHealth, tArmour, tDamage, tCritChance, tCritDamage, tPower);
  tHealth += traitHealth;
  tArmour += traitArmour;
  tDamage += traitDamage;
  tCritChance += traitCrit;
  tCritDamage += traitCrit * 2.5;

  let hpMult = CBApexLerp(CBConfig.ApexHealthMultBase() + scale * CBConfig.ApexHealthMultRange(), strength)
               * (1.0 + tHealth) * MaxF(roleHealthMult, 1.0);
  let armourMult = CBApexLerp(CBConfig.ApexArmorMultBase() + scale * CBConfig.ApexArmorMultRange(), strength)
                   * (1.0 + tArmour);
  let dmgMult = CBApexLerp(CBConfig.ApexDamageMultBase() + scale * CBConfig.ApexDamageMultRange(), strength)
                * (1.0 + tDamage);
  let critChance = CBConfig.ApexCritChanceBonus() * scale * strength + tCritChance;
  let critDamage = CBConfig.ApexCritDamageBonus() * scale * strength + tCritDamage;

  // The ceilings. Nothing above may take a stat past these, whatever it all adds up to.
  hpMult = ClampF(hpMult, 1.0, CBConfig.ApexHealthMultCeiling());
  armourMult = ClampF(armourMult, 1.0, CBConfig.ApexArmorMultCeiling());
  dmgMult = ClampF(dmgMult, 1.0, CBConfig.ApexDamageMultCeiling());
  critChance = ClampF(critChance, 0.0, CBConfig.ApexCritChanceCeiling());
  critDamage = ClampF(critDamage, 0.0, CBConfig.ApexCritDamageCeiling());
  let power = ClampF(tPower, 0.0, CBConfig.ApexPowerLevelCeiling());

  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  CBAddMult(stats, id, gamedataStatType.Health, hpMult);
  CBAddMult(stats, id, gamedataStatType.Armor, armourMult);
  // Hitting back. A boss that only soaks damage is a chore; one that can actually kill you is
  // the event this is supposed to be.
  CBAddMult(stats, id, gamedataStatType.PhysicalDamage, dmgMult);
  CBAddFlat(stats, id, gamedataStatType.CritChance, critChance);
  CBAddFlat(stats, id, gamedataStatType.CritDamage, critDamage);
  CBAddFlat(stats, id, gamedataStatType.PowerLevel, power);
  // Logged because the numbers are the thing that keeps being wrong, and a player who reports
  // an unkillable enemy can now send a line that says exactly what was built.
  CBLog.Info(n"Spawn", s"Built at grade \(grade): health x\(hpMult), armour x\(armourMult), damage x\(dmgMult), +\(power) power.");
  let pools = GameInstance.GetStatPoolsSystem(game);
  if IsDefined(pools) {
    pools.RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, 100.0, null);
  }
}

// A multiplier, skipped entirely when it would change nothing.
func CBAddMult(stats: ref<StatsSystem>, id: StatsObjectID, stat: gamedataStatType, mult: Float) -> Void {
  if mult <= 1.0001 {
    return;
  }
  let m = RPGManager.CreateStatModifier(stat, gameStatModifierType.Multiplier, mult);
  if IsDefined(m) {
    stats.AddModifier(id, m);
  }
}

func CBAddFlat(stats: ref<StatsSystem>, id: StatsObjectID, stat: gamedataStatType, amount: Float) -> Void {
  if amount <= 0.0001 {
    return;
  }
  let m = RPGManager.CreateStatModifier(stat, gameStatModifierType.Additive, amount);
  if IsDefined(m) {
    stats.AddModifier(id, m);
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
//
// `role` is CBRoleLeader, CBRoleLieutenant or CBRoleNone. It used to be a second buff applied
// from its own function straight after this one, which is how a leader nemesis ended up with
// twice the health of a build that was already at the ceiling. It is one term of one
// calculation now.
public func CBApplyRivalApexBuff(sys: ref<CyberbaneSystem>, game: GameInstance,
                                 puppet: ref<ScriptedPuppet>, r: ref<CBRival>, role: Int32) -> Void {
  if !IsDefined(r) {
    return;
  }
  // A cyberpsycho gets none of this, the crew-rank bonus included. They already carry a boss's
  // own health and armour, and multiplying that was the whole of why the first one to come back
  // could not be killed. The crew-rank bonus was still reaching them, because it was applied
  // from somewhere this check could not cover. What they get instead is the kit: see
  // CBKitCyberpsycho. Marking them as buffed stops the attach path from applying it a moment
  // later from the other direction.
  if CBRecordIsSightingCyberpsycho(r.recordID) {
    if IsDefined(puppet) {
      puppet.cbBuffed = true;
    }
    return;
  }
  let roleMult = 1.0;
  if role == CBRoleLeader() {
    roleMult = CBConfig.LeaderHealthMult();
  } else {
    if role == CBRoleLieutenant() {
      roleMult = CBConfig.LieutenantHealthMult();
    }
  }
  let th = 0.0;
  let ta = 0.0;
  let td = 0.0;
  let tc = 0.0;
  CBRivalTraitTerms(r, th, ta, td, tc);
  CBApplyApexBuild(sys, game, puppet, CBRivalGrade(r), roleMult, th, ta, td, tc);
}

// What a Rival's traits and weaknesses do to their build.
//
// They were rolled, promoted, kept in the save and shown nowhere, and none of them changed how a
// Rival fought: the comment on the trait list promised the effects "once the stat-modifier API
// is wired", and it was wired for the apex build long ago without the traits ever being plugged
// into it. Each one is a small fraction on the same terms the build already uses, so the ceilings
// in Config still decide the most anyone can be.
public func CBRivalTraitTerms(r: ref<CBRival>, out health: Float, out armour: Float,
                              out damage: Float, out crit: Float) -> Void {
  if !IsDefined(r) {
    return;
  }
  let step = CBConfig.RivalTraitStep();
  if CBRivalHasTrait(r, n"Tough") { health += step; }
  if CBRivalHasTrait(r, n"Scarred") { health += step * 0.6; }
  if CBRivalHasTrait(r, n"Armored") { armour += step; }
  if CBRivalHasTrait(r, n"ChromedOut") { armour += step * 0.6; damage += step * 0.4; }
  if CBRivalHasTrait(r, n"Deadeye") { crit += CBConfig.RivalTraitCrit(); }
  if CBRivalHasTrait(r, n"Confident") { damage += step * 0.6; }
  if CBRivalHasTrait(r, n"Humiliated") { damage += step * 0.4; }
  // Weaknesses take away from the same terms.
  if CBRivalHasTrait(r, n"OldWound") { health -= step; }
  if CBRivalHasTrait(r, n"Reckless") { armour -= step; damage += step * 0.4; }
  if CBRivalHasTrait(r, n"Shaken") { damage -= step * 0.6; }
}

// The traits that are about how they fight rather than how much they can take.
public func CBKitRivalTraits(npc: ref<NPCPuppet>, r: ref<CBRival>) -> Void {
  if !IsDefined(npc) || !IsDefined(r) || CBAiKitOwner() {
    return;
  }
  if CBRivalHasTrait(r, n"Quick") {
    CBGrantAbility(npc, t"Ability.HasKerenzikov");
  }
  if CBRivalHasTrait(r, n"ChromedOut") {
    CBGrantAbility(npc, t"Ability.HasSubdermalArmorHigh");
  }
}

// The sound of something you do not want arriving.
//
// `av_maxtac_descent_horn` is the game's own MaxTac AV descent horn, which is exactly the
// association wanted here: every player who has drawn a five star heat level knows what that
// noise means before they have looked up. Played globally rather than from the car, because it
// is doing the job of a warning - the squad is seventy metres away and out of sight when it
// fires, and positional audio at that range would be missed.
// The street reacts to an apex squad the way it reacts to MaxTac.
//
// `psychoSquadAVSystem.script:111` broadcasts Terror from the player at 100 m the moment a
// MaxTac AV arrives, which is why the crowd scatters before you have seen anything. An apex
// squad is built to be the gang's answer to MaxTac, so it gets the same treatment: one stim,
// from V, once, at the moment they are actually standing there.
public func CBApexTerrorWave(game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return;
  }
  // This is a civilian reaction, so it answers to the civilian settings. Without this, a
  // player who had turned crowd reactions off still got the whole street scattering every
  // time an apex squad landed, which is the one thing they had asked not to happen.
  let intensity = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    if !rt.GetSettings().civReactions {
      return;
    }
    intensity = rt.GetSettings().civIntensity;
  }
  if intensity <= 0.0 {
    return;
  }
  StimBroadcasterComponent.BroadcastStim(player, gamedataStimType.Terror,
                                         CBConfig.ApexTerrorRadius() * intensity);
  CBLog.Info(n"Spawn", "Apex squad arrival: terror wave sent.");
}

public func CBApexArrivalSound(game: GameInstance) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() || !rt.GetSettings().apexArrivalSound {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return;
  }
  // Played on the player, with no emitter.
  //
  // This was AudioSystem.Play with nothing but the event name, and the game never plays this
  // one that way. psychoSquadAVSystem.script:112 is
  // `GameObject.PlaySound( evt.av, 'av_maxtac_descent_horn', 'vehicle_general_emitter' )`: an
  // event authored against a vehicle's emitter. Asking for it with no entity and no emitter is
  // how you get silence, with nothing in any log to say the call did nothing. Playing it on the
  // player is the pattern the game uses everywhere it wants something heard regardless of where
  // it came from, and that is what this wants - the squad is seventy metres out and not in
  // sight yet when the horn goes.
  GameObject.PlaySound(player, n"av_maxtac_descent_horn");
}

// Top a part-delivered apex squad up to its full strength on foot.
//
// Counts what is actually standing in the world rather than what was asked for, which is the
// rule this file has had to learn twice: a request is not an arrival, and neither is a seat.
public func CBFillApexSquad(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let want = CBConfig.ApexStrikeTeamSize();
  let have = CBCountLiveTagged(game, n"CB_Apex");
  if have >= want {
    return;
  }
  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  let record = TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
  if !TDBID.IsValid(record) {
    return;
  }
  // Carry on round the role cycle rather than resetting it: the seats the car filled took the
  // first few chairs, so the ones walking in are the chairs that are still empty.
  // Carry on round the role cycle rather than resetting it: the seats the car filled took the
  // first few chairs, so the ones walking in take the chairs still empty. Advancing the index
  // per body matters - PeekApexRole on its own would have handed the same record to all of
  // them, and the kit each one gets comes from NextApexRole at attach, which does advance, so
  // the record and the kit would have disagreed for every body after the first.
  let missing = want - have;
  let added = 0;
  let i = 0;
  while i < missing {
    let one: EntityID;
    let seat = (sys.PeekApexRole() + i) % CBConfig.ApexStrikeTeamSize();
    if CBSpawnGroup(game, CBApexRoleRecord(fs, seat, record), n"", 1, n"CB_Apex",
                    CBConfig.ApexSpawnDistance(), one, CBApexRoleTag(seat)) > 0 {
      added += 1;
    }
    i += 1;
  }
  if added > 0 {
    CBLog.Info(n"Spawn", s"Apex squad from \(NameToString(faction)) arrived \(have) strong by car; \(added) more walked in.");
  }
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
    // The law does not field an apex squad; heat and MaxTac are its escalation.
    if IsDefined(fs) && NotEquals(fs.id, n"") && CBFactionFieldsSquads(fs.id) {
      // Their toughest if V has met one, otherwise whoever V has been fighting.
      let record = TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
      if TDBID.IsValid(record) && (fs.kills - fs.apexAtKills) >= CBConfig.ApexKillThreshold() {
        // Announce only. Deciding when they actually set off belongs to Spawn/Queue.reds now,
        // which holds the one clock for the whole mod; arming a second countdown here would
        // put two encounters on their way at once and leave the Hub showing a timer for a
        // thing that was not really next.
        //
        // The kills are spent in CBProcessPendingApex, and only once someone has actually
        // arrived. Spending them here meant a spawn that failed for any reason quietly cost
        // the player twenty bodies and they simply never saw an apex.
        if NotEquals(sys.GetApexAnnounced(), fs.id) {
          sys.SetApexAnnounced(fs.id);
        } else {
          return;   // already told them about this one
        }

        let name = CBApexName(CBContent(game), fs.id, fs.kills);
        if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
          CBPhoneFromGang(game, fs.id, s"\(name) is coming for you, and not alone. Four of ours. Make your peace.");
        }
        CBAllyTipOff(sys, game, fs.id);
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
    // Holding, but an apex that can never find a quiet moment must not block the next one.
    if sys.GetPendingApexTicks() <= 0 {
      sys.AgePendingApexHold();
    }
    return;
  }
  if sys.TickDownPendingApex() > 0 {
    return;   // still counting down
  }
  // The clock was a drive, not a warning: this squad has already been sent. Whether the
  // appointment is finished depends on whether anybody actually got out of the car.
  //
  // This used to end here unconditionally, reasoning that a squad had been sent and sending a
  // second would turn into a stream of them. The reasoning was right and the conclusion was
  // wrong, because a request is not an arrival. The car can be accepted and deliver nothing:
  // no road near the player, the spawn refused, the adoption window closing before anything
  // attached. The squad was then written off in silence, which from the player's side is a
  // countdown in the Hub that reaches zero and nobody ever turning up. That is exactly the
  // report, and it got worse in 1.4.1: before that the chase request could not succeed at all,
  // so the walk-in below always ran and an apex always arrived on foot.
  //
  // Two ways to be sure they came. Somebody wearing the tag is standing in the world, or the
  // adoption counter says seats were filled, which still reads as delivered after the player
  // has killed them. Neither is true means nobody came, so they walk in instead.
  let carFailed = false;
  if sys.IsPendingApexDriving() {
    sys.SetPendingApex(faction, 0);   // the drive is over whichever way this goes
    let delivered = CBLiveTaggedPresent(game, n"CB_Apex")
                 || (Equals(sys.GetAdoptTag(), n"CB_Apex") && sys.GetAdoptTaken() > 0);
    if delivered {
      // Arrived. Anyone the car could not seat walked in when it was sent, and anyone it was
      // meant to carry and did not was walked in by CBProcessCarTopUp, so the squad is already
      // four. This used to top up from a live head count at the end of the drive, which both
      // left the squad short for the whole drive and replaced members the player had already
      // killed.
      sys.SetPendingApex(n"", 0);
      return;
    }
    carFailed = true;
    CBLog.Info(n"Spawn", s"Apex squad for \(NameToString(faction)) was sent by car and nobody arrived; walking them in.");
  }

  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) {
    sys.SetPendingApex(n"", 0);   // nothing to send; do not sit on a dead appointment
    return;
  }
  let record = TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
  if !TDBID.IsValid(record) {
    sys.SetPendingApex(n"", 0);
    return;
  }
  // An apex turning up on foot out of nowhere was the other half of the arrival complaint.
  // If a car can get here, the escort drives it in and the apex comes with them; the walk-in
  // below stays for indoors and anywhere a car cannot be placed.
  // A carload of them, all boss grade - the gang's answer to MaxTac rather than one heavy
  // with a lift. Every seat is tagged CB_Apex, so every one of them gets the full buff, and
  // the strength slider is how a player dials that back if four at once is too much.
  sys.ResetApexRoles();   // this squad starts again at the heavy
  sys.ClearSquadAnchor();
  if !carFailed
     && CBSendByCar(sys, game, fs, record, CBConfig.ApexStrikeTeamSize(), n"CB_Apex") > 0 {
    // The warning is spent, but they are not here yet: they are driving. Keep the clock
    // running for the length of the drive so the Hub has something true to show, instead of
    // the countdown vanishing the moment the car is dispatched and the squad turning up with
    // no warning at all. This is why there appeared to be no apex countdown.
    sys.SetPendingApexDriving(fs.id, CBConfig.ApexDriveTicks());
    CBApexArrivalSound(game);
    fs.apexAtKills = fs.kills;
    CBLog.Info(n"Spawn", s"Apex squad from \(NameToString(fs.id)) arriving by car.");
    return;
  }
  sys.SetPendingApex(n"", 0);
  // CBSpawnGroup will refuse while the world is still streaming in, so this can only land on
  // a settled frame. CB_Apex is also tagged n"Cyberbane", so the session sweep clears it.
  // Four of them, with their roles, the same as the carload.
  //
  // This spawned exactly one. Only the car arrival ever built a squad, so an apex that had to
  // walk in - indoors, a tight street, anywhere a car could not be placed, which is most of the
  // time - was one enemy with a couple of ordinary crew behind them. That is not an apex squad,
  // and it is not what the Hub, the bars or the readme describe. A seat whose role record the
  // gang has not filed yet falls back to the elite record, so a squad is always four.
  let apexEntity: EntityID;
  let arrived = 0;
  // The roles start again at the heavy. Reset at the top of this function too, but the car
  // path may have run since and taken some of them, so a walk-in that follows a failed car
  // would otherwise start partway round the cycle and send two netrunners.
  sys.ResetApexRoles();
  let seat = 0;
  while seat < CBConfig.ApexStrikeTeamSize() {
    let one: EntityID;
    if CBSpawnGroup(game, CBApexRoleRecord(fs, seat, record), n"", 1, n"CB_Apex",
                    CBConfig.ApexSpawnDistance(), one, CBApexRoleTag(seat)) > 0 {
      arrived += 1;
      apexEntity = one;
    }
    seat += 1;
  }
  if arrived <= 0 {
    // The world was not settled enough to place anyone. Keep the kills on the books so the
    // next slow tick tries again, rather than charging the player for a no-show.
    //
    // Age the hold while doing so. Returning here without it left the appointment standing,
    // and an appointment that is still standing makes the lane busy, so an apex squad that
    // could never be placed blocked every later one indefinitely. The same trap as the Rival
    // lane, in a second place; AgePendingApexHold gives up after a bounded wait and lets it be
    // rescheduled.
    let why = CBBlockLabel(CBLastSpawnBlock());
    if StrLen(why) == 0 {
      why = "no reason recorded";
    }
    CBLog.Info(n"Spawn", s"Apex squad for \(NameToString(faction)) could not be placed: \(why).");
    sys.AgePendingApexHold();
    return;
  }
  fs.apexAtKills = fs.kills;   // paid for: the next one needs fresh bodies
  CBApexArrivalSound(game);    // only once somebody is actually standing there
  CBApexTerrorWave(game);      // and everybody nearby gets out of the way
  if CBConfig.ApexEscortCount() > 0 && TDBID.IsValid(fs.sampleRecord) {
    let escortEntity: EntityID;
    // CB_Escort, not CB_Squad. They used to wear the hit squad's own tag, which had two
    // consequences: the squad lane saw a hit squad in the world that nobody had sent and
    // refused to arrange one, and an escort from this gang was indistinguishable from another
    // gang's crew that happened to be live at the same time - so the two read as one mixed
    // squad. They are still kitted, still hostile and still chase, because every list below
    // that matters now names this tag too.
    CBSpawnGroup(game, fs.sampleRecord, n"", CBConfig.ApexEscortCount(), n"CB_Escort",
      CBConfig.ApexSpawnDistance() + 4.0, escortEntity);
  }
}
