// Cyberbane - Faction apex enforcer (spec §9.9)
//
// Put enough of one gang in the ground and they stop sending squads and send someone who matters: a named heavy built
// from the toughest member of theirs V has actually put down.

// A name for the gang's heavy, pulled from that faction's own name pool. Deterministic for a
// given seed so the warning and anything later agree.
public func CBApexName(content: ref<CyberbaneContent>, faction: CName, seed: Int32) -> String {
  if IsDefined(content) {
    let pool = content.GetFactionNames(faction);
    if IsDefined(pool) {
      let n = ArraySize(pool.firstNames);
      // A handle is a person's whole name, so a gang of handles keeps its heavy on the old ones,
      // which no new Rival can be given.
      if ArraySize(pool.lastNames) == 0 && pool.oldFirsts > 0 {
        n = pool.oldFirsts;
      }
      if n > 0 {
        return pool.firstNames[CBHashIndex(seed, 17, n)];
      }
    }
  }
  return CBT(n"Cyberbane-FactionApex-TheirBest");
}

// Make a spawned apex actually feel like one.
public func CBApexStrengthFraction() -> Float {
  let rt = CyberbaneRuntime.Get();
  let pct = CBConfig.ApexStrengthDefault();
  if IsDefined(rt) && rt.HasSettings() {
    pct = rt.GetSettings().apexStrength;
  }
  return CBStrengthFraction(pct);
}

// The same for Rivals, from their own slider (under Rivals). Rivals have always been built with the apex build, and
// until this they were scaled by the apex squad's slider too: It was that one, and nothing said so.
public func CBRivalStrengthFraction() -> Float {
  let rt = CyberbaneRuntime.Get();
  let pct = CBConfig.ApexStrengthDefault();
  if IsDefined(rt) && rt.HasSettings() {
    pct = rt.GetSettings().rivalStrength;
  }
  return CBStrengthFraction(pct);
}

// A strength slider's percentage as a fraction of the full build, with New Game Plus and the game's
// difficulty taken into account the same way for both.
func CBStrengthFraction(pct: Int32) -> Float {
  let frac = ClampF(Cast<Float>(pct) / 100.0, 0.1, 1.0);
  if CBNgpActive() {
    frac *= CBConfig.ApexNgpStepDown();
  }
  return frac * CBDifficultyStepDown();
}

// The game's difficulty already scales what every enemy does to V. Cyberbane gives back part of its share at those
// settings. Steps above Easy: Hard is one, Very Hard two, Easy and Story none.
public func CBDifficultyLevel() -> Int32 {
  let sds = GameInstance.GetStatsDataSystem(GetGameInstance());
  if !IsDefined(sds) {
    return 0;
  }
  let d = sds.GetDifficulty();
  if Equals(d, gameDifficulty.VeryHard) {
    return 2;
  }
  if Equals(d, gameDifficulty.Hard) {
    return 1;
  }
  return 0;
}

// Is a combat overhaul installed that already makes every enemy deadlier?
public func CBCombatOverhaulActive() -> Bool {
  let mods = CBModSettingsMods();
  for mod in mods {
    let name = NameToString(mod);
    if StrContains(name, "Immersive Shooting") || StrContains(name, "ImmersiveShooting") {
      return true;
    }
  }
  return false;
}

public func CBDifficultyStepDown() -> Float {
  let game = GetGameInstance();
  let sds = GameInstance.GetStatsDataSystem(game);
  if !IsDefined(sds) {
    return 1.0;
  }
  let d = sds.GetDifficulty();
  if Equals(d, gameDifficulty.VeryHard) {
    return CBConfig.ApexVeryHardStepDown();
  }
  if Equals(d, gameDifficulty.Hard) {
    return CBConfig.ApexHardStepDown();
  }
  return 1.0;
}

// Scale a multiplier toward 1.0 (no change) rather than toward zero.
public func CBApexLerp(full: Float, frac: Float) -> Float {
  return 1.0 + (full - 1.0) * frac;
}

// Give this enforcer one or two traits of its own.
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
          // Overclocked: fights above its level. Clamped hard by the caller, because the game derives health, armour
          // and damage from power level, so this one term quietly multiplies the other three.
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
public func CBApplyApexGradeBuff(sys: ref<CyberbaneSystem>, game: GameInstance,
                                 puppet: ref<ScriptedPuppet>, grade: Float) -> Void {
  CBApplyApexBuild(sys, game, puppet, grade, CBApexStrengthFraction(), 1.0);
}

// The one place anything is ever done to a spawned enemy's stats.
public func CBApplyApexBuild(sys: ref<CyberbaneSystem>, game: GameInstance,
                             puppet: ref<ScriptedPuppet>, grade: Float, slider: Float, roleHealthMult: Float,
                             opt traitHealth: Float, opt traitArmour: Float,
                             opt traitDamage: Float, opt traitCrit: Float) -> Void {
  // Stat modifiers go only on somebody fully in the world and alive.
  if !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  CBTrace("stats: building a spawned enemy");
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
  // The flag above is on the puppet, and a body that streams out and back in is a new puppet. If the
  // bonus is still on it, leave it alone: building it again multiplies it, and refills its health.
  if IsDefined(sys) && sys.WasBuiltAt(puppet.GetEntityID(),
                                      stats.GetStatValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatType.Health)) {
    return;
  }
  let scale = CBMenaceScale(sys);
  // How hard the player asked for this to be, as a fraction of a boss-grade build.
  let strength = slider * ClampF(grade, 0.0, 1.0);

  let tHealth = 0.0;
  let tArmour = 0.0;
  let tDamage = 0.0;
  let tCritChance = 0.0;
  let tCritDamage = 0.0;
  let tPower = 0.0;
  CBRollApexTraits(scale, strength, tHealth, tArmour, tDamage, tCritChance, tCritDamage, tPower);
  tHealth += traitHealth;
  tArmour += traitArmour;
  // What they know about this fight ([U3]): how strong their gang is now, how dangerous the district, their code, and
  // what they have prepared for how V fights. Terms on the same fractions, under the same ceilings.
  let gangOf = CBClassifyFaction(puppet);
  tHealth += CBFightReadHealth(sys, game, gangOf);
  tArmour += CBAdaptArmour(game, gangOf);
  tDamage += traitDamage;
  tCritChance += traitCrit;
  tCritDamage += traitCrit * 2.5;

  let hpMult = CBApexLerp(CBConfig.ApexHealthMultBase() + scale * CBConfig.ApexHealthMultRange(), strength)
               * (1.0 + tHealth) * MaxF(roleHealthMult, 1.0);
  let armourMult = CBApexLerp(CBConfig.ApexArmorMultBase() + scale * CBConfig.ApexArmorMultRange(), strength)
                   * (1.0 + tArmour);
  let dmgMult = CBApexLerp(CBConfig.ApexDamageMultBase() + scale * CBConfig.ApexDamageMultRange(), strength)
                * (1.0 + tDamage);
  // With a combat overhaul already making every shot count, keep only part of the bonus.
  if CBCombatOverhaulActive() {
    dmgMult = 1.0 + (dmgMult - 1.0) * CBConfig.OverhaulDamageKeep();
  }
  let critChance = CBConfig.ApexCritChanceBonus() * scale * strength + tCritChance;
  let critDamage = CBConfig.ApexCritDamageBonus() * scale * strength + tCritDamage;

  // The ceilings. Nothing above may take a stat past these, whatever it all adds up to.
  hpMult = ClampF(hpMult, 1.0, CBConfig.ApexHealthMultCeiling());
  armourMult = ClampF(armourMult, 1.0, CBConfig.ApexArmorMultCeiling());
  dmgMult = ClampF(dmgMult, 1.0, CBConfig.ApexDamageMultCeiling());
  // An apex squad's people and a Rival, measured against V by the game's numbers (Spawn/MeasureV.reds): whichever is
  // tougher, this or the build above, under ceilings of their own, and the game's abilities that answer how V fights.
  let desMatch = GameInstance.GetDynamicEntitySystem();
  let matchId = puppet.GetEntityID();
  let isApex = IsDefined(desMatch) && (desMatch.IsTagged(matchId, n"CB_Apex") || desMatch.IsTagged(matchId, n"CB_HoldLt"));
  // A named bounty hunter is measured as a Rival is, at their rank on the ladder.
  let isRival = IsDefined(desMatch) && (desMatch.IsTagged(matchId, n"CB_Rival") || desMatch.IsTagged(matchId, n"CB_Lair")
                                        || desMatch.IsTagged(matchId, n"CB_Bounty")
                                        || (desMatch.IsTagged(matchId, n"CB_Hold") && !desMatch.IsTagged(matchId, n"CB_HoldLt")));
  let counters = "";
  let measure: ref<CBVMeasure>;
  let npcDamageMult = 1.0;
  let hitCap = 0.0;
  if isApex || isRival {
    measure = CBMeasureV(game);
    let npcId = Cast<StatsObjectID>(matchId);
    let level = ClampF(strength, 0.0, 1.0);
    let seconds = (isRival ? CBConfig.RivalMatchSeconds() : CBConfig.ApexMatchSeconds()) * (0.5 + level);
    let matchHp = CBMatchHealthMult(measure, stats.GetStatValue(npcId, gamedataStatType.Health), seconds);
    let matchDmg = CBMatchDamageMult(measure, CBConfig.ApexArmourAnswer() * (isRival ? ClampF(grade, 0.4, 1.0) : 1.0));
    // Read from the game at this one's power level, which in the open world follows V's own, and a share of it given to
    // them: an apex squad's people a share each, a Rival more as they climb.
    let sm = CBSmasherScale(game, stats.GetStatValue(npcId, gamedataStatType.PowerLevel));
    let share = isRival ? (CBConfig.RivalSmasherShareMin() + (CBConfig.RivalSmasherShareMax() - CBConfig.RivalSmasherShareMin()) * level) * ClampF(grade, 0.25, 1.0)
                        : CBConfig.ApexSmasherShareMin() + (CBConfig.ApexSmasherShareMax() - CBConfig.ApexSmasherShareMin()) * level;
    // As far as V is into the game (CBVProgress): none of him for a new V, all of the share at the level cap.
    let progress = CBVProgress(measure);
    let smHp = CBSmasherPart(sm.X, share, progress);
    let smDmg = CBSmasherPart(sm.Y * CBConfig.SmasherDamageScale(), share, progress);
    let hpCeiling = MaxF(CBConfig.ApexMatchHealthCeiling(), CBSmasherPart(sm.X, CBConfig.SmasherCeilingShare(), progress));
    let dmgCeiling = MaxF(CBConfig.ApexMatchDamageCeiling(), CBSmasherPart(sm.Y * CBConfig.SmasherDamageScale(), CBConfig.SmasherCeilingShare(), progress));
    hpMult = ClampF(MaxF(hpMult, MaxF(matchHp, smHp)), 1.0, hpCeiling);
    // Their hits: the most of their own build, V's armour answered, and Smasher's share, on the damage multiplier this
    // build has always used for their weapons; and the same share on NPCDamage, which is what their burning and
    // bleeding is made of (primary_stats.tweak, NPCDoTDPS).
    dmgMult = ClampF(MaxF(dmgMult, MaxF(matchDmg, smDmg)), 1.0, dmgCeiling);
    npcDamageMult = smDmg > 1.0 ? ClampF(smDmg, 1.0, dmgCeiling) : 1.0;
    // And no burst kills (statPoolsManager.script: MaxPercentDamageTakenPerHit, 7 on Smasher): no single hit takes more
    // than this share of their health. The game applies it to bosses alone, so Cyberbane applies it to these (CBHitCap).
    hitCap = CBConfig.ApexHitCapAtMin() + (CBConfig.ApexHitCapAtMax() - CBConfig.ApexHitCapAtMin()) * level;
    if isRival {
      hitCap = MaxF(hitCap, CBConfig.ApexHitCapAtMin() - (CBConfig.ApexHitCapAtMin() - CBConfig.RivalHitCapTop()) * ClampF(grade, 0.0, 1.0));
    }
    counters = CBCounterV(sys, game, puppet, measure, isRival ? ClampF(grade, 0.0, 1.0) : 1.0);
    // Smasher's footing: hit reactions and takedowns do not stop them as they stop a ganger.
    if level >= 0.4 && (isApex || grade >= 0.6) {
      CBGrantAbility(puppet as NPCPuppet, t"Ability.HasExtendedHitReactionImmunity");
      CBGrantAbility(puppet as NPCPuppet, t"Ability.HasMeleeHitReactionAndTakedownResistance");
      counters += "Smasher's footing ";
    }
    CBLog.Info(n"Spawn", s"Measured you for this one: level \(measure.level), best weapon \(measure.bestDps) DPS (\(measure.Dps()) with crits), armour \(measure.armour), health \(measure.health); you fight as \(measure.Styles()); they bring \(counters). Their power level \(stats.GetStatValue(npcId, gamedataStatType.PowerLevel)); Smasher there: health x\(sm.X), damage x\(sm.Y); their share \(share) of it, x\(progress) for how far you are into the game: health x\(hpMult), NPC damage x\(npcDamageMult), no more than \(hitCap)% a hit.");
  }
  critChance = ClampF(critChance, 0.0, CBConfig.ApexCritChanceCeiling());
  critDamage = ClampF(critDamage, 0.0, CBConfig.ApexCritDamageCeiling());
  let power = ClampF(tPower, 0.0, CBConfig.ApexPowerLevelCeiling());

  // The ceiling on the finished body (Spawn/Killable.reds), taken before this build's terms go on.
  CBSetKillLimit(game, puppet, isRival ? CBKillableSecondsRival(grade)
                                       : (isApex ? CBConfig.KillableApexSeconds() : CBConfig.KillableCrewSeconds()), measure);
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  CBAddMult(stats, id, gamedataStatType.Health, hpMult);
  CBAddMult(stats, id, gamedataStatType.Armor, armourMult);
  // Hitting back. A boss that only soaks damage is a chore; one that can actually kill you is
  // the event this is supposed to be.
  CBAddMult(stats, id, gamedataStatType.PhysicalDamage, dmgMult);
  CBAddMult(stats, id, gamedataStatType.NPCDamage, npcDamageMult);   // Smasher's share, 1 for anybody else
  puppet.cbHitCap = hitCap;
  CBAddFlat(stats, id, gamedataStatType.CritChance, critChance);
  CBAddFlat(stats, id, gamedataStatType.CritDamage, critDamage);
  CBAddFlat(stats, id, gamedataStatType.PowerLevel, power);
  CBAddFlat(stats, id, gamedataStatType.HackingResistance, CBAdaptIce(game, gangOf));
  CBLog.Info(n"Spawn", s"Built at grade \(grade): health x\(hpMult), armour x\(armourMult), damage x\(dmgMult), +\(power) power.");
  CBKeepKillable(game, puppet, false);
  if IsDefined(sys) {
    sys.NoteBuilt(puppet.GetEntityID(), stats.GetStatValue(id, gamedataStatType.Health));
  }
  // Topped up to the new maximum, the way the game refills a pool (RequestSettingStatPoolMaxValue).
  let pools = GameInstance.GetStatPoolsSystem(game);
  if IsDefined(pools) {
    pools.RequestSettingStatPoolMaxValue(id, gamedataStatPoolType.Health, null);
  }
}

// Adam Smasher's health and damage multipliers at this power level, read from the game's curves
// (Main_boss_adam_smasher_stats): X health, Y damage before his 0.7. Zeros when the curves cannot be read.
public func CBSmasherScale(game: GameInstance, powerLevel: Float) -> Vector4 {
  let sds = GameInstance.GetStatsDataSystem(game);
  if !IsDefined(sds) || powerLevel <= 0.0 {
    return new Vector4(0.0, 0.0, 0.0, 0.0);
  }
  let hp = sds.GetValueFromCurve(n"puppet_powerLevelToHealth", powerLevel, n"smasher_level_to_health");
  let dps = sds.GetValueFromCurve(n"boss_power_level_to_dps_mult", powerLevel, n"smasher_level_to_dps_mult");
  return new Vector4(MaxF(hp, 0.0), MaxF(dps, 0.0), 0.0, 0.0);
}

// No single hit takes more than this share of an apex's or a Rival's health: the rule the game keeps for its bosses
// (StatPoolsManager.ApplyDamage, MaxPercentDamageTakenPerHit), for the people Cyberbane builds to that grade.
@addField(ScriptedPuppet)
public let cbHitCap: Float;

@wrapMethod(StatPoolsManager)
public static func ApplyDamage(hitEvent: ref<gameHitEvent>, forReal: Bool, out valuesLost: array<SDamageDealt>) -> Void {
  // Chippin' In (Reactions/ChippinIn.reds): the blow that would kill V, caught before the game applies it, and nothing
  // at all while V is down and one of the crew is on the way.
  let pv = IsDefined(hitEvent) ? hitEvent.target as PlayerPuppet : null;
  if forReal && IsDefined(pv) && (pv.cbChipArmed > 0 || pv.cbChipDown) && CBChipInCatch(pv, hitEvent) {
    return;
  }
  let p = IsDefined(hitEvent) ? hitEvent.target as ScriptedPuppet : null;
  if IsDefined(p) && p.cbHitCap > 0.0 && !p.IsDead() {
    let instigator = hitEvent.attackData.GetInstigator();
    if !IsDefined(instigator) || !instigator.GetIsInFastFinisher() {
      let stats = GameInstance.GetStatsSystem(p.GetGame());
      let ceiling = p.cbHitCap / 100.0 * stats.GetStatValue(Cast<StatsObjectID>(p.GetEntityID()), gamedataStatType.Health);
      let weapon = hitEvent.attackData.GetWeapon();
      if IsDefined(weapon) {
        let per = stats.GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.ProjectilesPerShot);
        if per > 0.0 {
          ceiling /= per;
        }
      }
      if ceiling > 0.0 {
        let values = hitEvent.attackComputed.GetAttackValues();
        let i = 0;
        while i < ArraySize(values) {
          values[i] = ClampF(values[i], 0.0, ceiling);
          i += 1;
        }
        hitEvent.attackComputed.SetAttackValues(values);
      }
    }
  }
  let watched = forReal && IsDefined(p) && p.cbKillLimit > 0.0 && !p.IsDead()
                && CBKillableHitter(hitEvent.attackData.GetInstigator());
  if watched {
    CBKillableWatchBefore(p, hitEvent);
  }
  wrappedMethod(hitEvent, forReal, valuesLost);
  if watched {
    CBKillableWatchAfter(p, hitEvent, valuesLost);
  }
}

// The fight, read for the build ([U3]): a gang at full strength holds nothing back and a bled one has less to send; a
// dangerous district puts tougher people on its streets; a gang's code may make its people tougher; and what they have
// prepared for V.
public func CBFightReadHealth(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Float {
  if Equals(gang, n"") {
    return 0.0;
  }
  let t = CBCodeToughness(gang) + CBAdaptHealth(game, gang);
  if IsDefined(sys) && CBTurfWarsOn() {
    t += (ClampF(CBGangStrength(sys, gang), 0.0, 100.0) - 100.0) / 100.0 * CBConfig.BuildStrengthWeight();
  }
  if IsDefined(sys) {
    t += CBDistrictDanger(sys.GetCurrentDistrict());
  }
  return ClampF(t, -CBConfig.BuildReadFloor(), CBConfig.BuildReadCeiling());
}

// How dangerous a district's streets are, as a fraction of health on the people sent there.
public func CBDistrictDanger(district: CName) -> Float {
  switch CBDistrictIndex(district) {
    case 6: return 0.1;    // Dogtown
    case 5: return 0.05;   // Pacifica
    case 7: return 0.05;   // the Badlands
    default: return 0.0;
  }
}

// A crew member's build. Crews were never built at all, and still are not by V's menace: only what their gang's code
// and preparation add (the Animals' toughness, Barghest's, plate against a V who shoots, ICE against a V who hacks).
public func CBApplyCrewBuild(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() || puppet.cbBuffed {
    return;
  }
  CBSetKillLimit(game, puppet, CBConfig.KillableCrewSeconds());
  let gang = CBClassifyFaction(puppet);
  let health = ClampF(CBCodeToughness(gang) + CBAdaptHealth(game, gang), 0.0, CBConfig.CrewBuildHealthCeiling());
  let armour = ClampF(CBAdaptArmour(game, gang), 0.0, CBConfig.CrewBuildArmourCeiling());
  let ice = CBAdaptIce(game, gang);
  if health <= 0.0 && armour <= 0.0 && ice <= 0.0 {
    return;
  }
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  if IsDefined(sys) && sys.WasBuiltAt(puppet.GetEntityID(), stats.GetStatValue(id, gamedataStatType.Health)) {
    return;
  }
  puppet.cbBuffed = true;
  CBAddMult(stats, id, gamedataStatType.Health, 1.0 + health);
  CBAddMult(stats, id, gamedataStatType.Armor, 1.0 + armour);
  CBAddFlat(stats, id, gamedataStatType.HackingResistance, ice);
  CBLog.Info(n"Spawn", s"Crew built by their code and preparation: health x\(1.0 + health), armour x\(1.0 + armour), +\(ice) ICE.");
  CBKeepKillable(game, puppet, false);
  if IsDefined(sys) {
    sys.NoteBuilt(puppet.GetEntityID(), stats.GetStatValue(id, gamedataStatType.Health));
  }
  // Topped up to the new maximum, the way the game refills a pool (RequestSettingStatPoolMaxValue).
  let pools = GameInstance.GetStatPoolsSystem(game);
  if IsDefined(pools) {
    pools.RequestSettingStatPoolMaxValue(id, gamedataStatPoolType.Health, null);
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
                                 puppet: ref<ScriptedPuppet>, r: ref<CBRival>, role: Int32) -> Void {
  if !IsDefined(r) {
    return;
  }
  // A cyberpsycho gets none of this, the crew-rank bonus included. They already carry a boss's own health and armour,
  // and multiplying that was the whole of why the first one to come back could not be killed.
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
  CBApplyApexBuild(sys, game, puppet, CBRivalGrade(r), CBRivalStrengthFraction(), roleMult, th, ta, td, tc);
}

// What a Rival's traits and weaknesses do to their build.
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
  // Their chrome (Rivals/RivalMoments.reds, [U9]): on the same terms, under the same ceilings.
  CBRivalImplantTerms(r, health, armour, damage, crit);
}

// The traits that are about how they fight rather than how much they can take.
public func CBKitRivalTraits(npc: ref<NPCPuppet>, r: ref<CBRival>) -> Void {
  if !IsDefined(npc) || !IsDefined(r) || CBAiKitOwner() {
    return;
  }
  // Quick: keeps pace and shoots on the move. Kerenzikov used to be granted here, which drives a
  // cyberware effect on a record that was never made for one (see CBApplyRoleKit).
  if CBRivalHasTrait(r, n"Quick") {
    CBGrantAbility(npc, t"Ability.CanCatchUp");
    CBGrantAbility(npc, t"Ability.CanShootWhileMoving");
  }
  if CBRivalHasTrait(r, n"ChromedOut") {
    CBGrantAbility(npc, t"Ability.HasSubdermalArmorHigh");
  }
  // And what their chrome and their kind of Rival bring ([U9] [U11]).
  CBKitRivalImplants(npc, r);
}

// The sound of something you do not want arriving.
public func CBApexTerrorWave(game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return;
  }
  // This is a civilian reaction, so it answers to the civilian settings.
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
  // Not when the wave would reach the job V is tracking: it would scatter that job's people.
  let sysWave = CyberbaneSystem.Get(game);
  if IsDefined(sysWave) && sysWave.NearQuestPins(player.GetWorldPosition(), CBConfig.ApexTerrorRadius() * intensity) {
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
  // never heard in play.
  CBApexWarningSound(game);
}

// ---- Four, every time ----------------------------------------------------------------
//
// Every path that brings one in - the apex lane's car or walk-in, a crew bringing its best - marks each chair as
// somebody is put in the world for it (sys.NoteApexChair).
public func CBApexMusterTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let faction = sys.GetApexMusterFaction();
  if Equals(faction, n"") {
    return;
  }
  let mask = sys.GetApexMusterMask();
  if mask == CBApexChairsAll() {
    sys.ClearApexMuster();   // all four are in
    return;
  }
  if sys.TickApexMuster() <= 0 {
    CBLog.Info(n"Spawn", s"Apex squad from \(NameToString(faction)) could not be brought to four in time.");
    sys.ClearApexMuster();
    return;
  }
  // A car still seating chairs: let it finish, or let it be given up on.
  if (sys.HasPendingArrival() && sys.IsArrivalRoleSquad()) || sys.ConvoyHasTag(n"CB_Apex") {
    return;
  }
  // The apex lane's own drive is still on the clock and nobody has arrived yet: when it runs out,
  // CBProcessPendingApex walks the squad in if the car delivered nobody.
  if mask == 0 && sys.IsPendingApexDriving() && Equals(sys.GetPendingApexFaction(), faction) {
    return;
  }
  // Everyone who came is down already: the fight is over, and nobody else is sent into it.
  if mask != 0 && CBCountLiveOrSpawning(game, n"CB_Apex") == 0 {
    sys.ClearApexMuster();
    return;
  }
  // Nor onto home ground (Spawn/HomeGround.reds): no spot there would take them anyway.
  if sys.GetStoryHold() != CBStoryNone() || CBStealthEncounterNearby(sys, game) || CBHomeHolds(sys, faction) {
    return;   // wait for the stage, the quiet job or home ground to be over
  }
  if sys.GetTickCount() % 3 != 0 {
    return;   // a few seconds between tries is plenty, and keeps the probing cheap
  }
  let fs = sys.FindFaction(faction);
  let record = sys.GetApexMusterRecord();
  if !IsDefined(fs) || !TDBID.IsValid(record) {
    sys.ClearApexMuster();
    return;
  }
  let added = CBWalkInRest(sys, game, fs, record, n"CB_Apex", 0, CBConfig.ApexStrikeTeamSize());
  if added > 0 {
    CBLog.Info(n"Spawn", s"Apex squad from \(NameToString(faction)): \(added) more walked in to make four.");
  }
}

// The four chairs as bits, so a squad can say which of them are filled.
public func CBApexChairsAll() -> Int32 = 15

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
  // Another mod already owns gangs coming after you. The apex is the same kind of system as a hit squad, so it stands
  // down with them rather than stacking a second wave of enemies on top of theirs (spec §17).
  if CBRememberSendsCrews() {
    return;
  }
  if NotEquals(sys.GetPendingApexFaction(), n"") {
    return;   // one is already on the way
  }
  // Apex squads per day at zero sends none, so none is promised (as a beaten crew's line already asks, CBOnCrewBeaten).
  if CBLaneDailyCap(CBLaneApex()) <= 0 {
    return;
  }
  // Unless the player has opted into being hunted indoors, the warning does not even fire
  // in a safe area: announcing someone who then cannot be placed is worse than silence.
  if sys.IsInSanctuary() {
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
      // The same test the apex lane picks with, so this never announces a squad that will not come.
      if CBApexEligible(sys, fs) {
        // Announce only.
        if !sys.IsApexAnnounced(fs.id, fs.apexAtKills) {
          sys.SetApexAnnounced(fs.id, fs.apexAtKills);
        } else {
          return;   // already told them about this one
        }

        // Seeded by the kills already paid for, which does not move until they are sent, so the
        // name in this warning is the name in the one that says they are on the road.
        let name = CBApexName(CBContent(game), fs.id, fs.apexAtKills);
        // One voice (CBCrewWarning): a friendly gang's word, or theirs.
        if !CBAllyTipOff(sys, game, fs.id) && CBMessagesOn() {
          CBPhoneDemandFromGang(game, fs.id, CBTf(n"Cyberbane-FactionApex-IsComingForYouAndNot", [s"\(name)"]));
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
  // The story has the stage: the warning's clock stops, and is not aged either (Core/StoryHold.reds).
  if sys.GetStoryHold() != CBStoryNone() {
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
  let carFailed = false;
  if sys.IsPendingApexDriving() {
    sys.SetPendingApex(faction, 0);   // the drive is over whichever way this goes
    // A chair the car filled counts as delivered even after V has put that member down, which
    // is what a live head count could not tell apart from nobody turning up.
    let delivered = sys.PendingApexCame() || CBLiveTaggedPresent(game, n"CB_Apex")
                 || (Equals(sys.GetApexMusterFaction(), faction) && sys.GetApexMusterMask() != 0);
    if delivered {
      // Arrived. Whoever the car could not seat is walked in by the muster, chair by chair
      // (CBApexMusterTick), so the squad is four without replacing anybody V already killed.
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
  // The name their warning gave them, kept for their bodies (CBApexMemberName): it moves on once they are sent.
  let rtName = CyberbaneRuntime.Get();
  if IsDefined(rtName) {
    rtName.lastApexFaction = fs.id;
    rtName.lastApexSeed = fs.apexAtKills;
  }
  // They may have been paid off, or come round to V, while their best were on their way, or been
  // switched off since - the same question the crew asks before it sets off (CBGangMaySend).
  if !CBGangMaySend(sys, fs.id) {
    sys.SetPendingApex(n"", 0);
    if Equals(sys.GetApexMusterFaction(), fs.id) {
      sys.ClearApexMuster();
    }
    CBLog.Info(n"Spawn", s"Apex squad from \(NameToString(fs.id)) called off.");
    return;
  }
  // What V did while they were on their way, and home ground (Spawn/Slip.reds, Spawn/HomeGround.reds). Not for a car
  // that delivered nobody: that squad set off already.
  if !carFailed {
    if CBSlipResolve(sys, game, fs.id) {
      return;
    }
    if CBHomeHolds(sys, fs.id) {
      if sys.AgePendingApexHold() {
        sys.ClearApexMuster();
      }
      return;
    }
  }
  let record = CBApexRecordFor(fs);
  if !TDBID.IsValid(record) {
    sys.SetPendingApex(n"", 0);
    return;
  }
  // If a car can get here, the escort drives it in and the apex comes with them; the walk-in below stays for indoors
  // and anywhere a car cannot be placed.
  sys.ResetApexRoles();   // this squad starts again at the heavy
  sys.ClearSquadAnchor();
  // One muster for this squad, whichever way it comes. Kept if it is already this gang's - a
  // walk-in after a failed car must not forget a chair somebody already filled.
  if NotEquals(sys.GetApexMusterFaction(), fs.id) {
    sys.BeginApexMuster(fs.id, record);
  }
  if !carFailed
     && CBSendByCar(sys, game, fs, record, CBConfig.ApexStrikeTeamSize(), n"CB_Apex") > 0 {
    // The warning is spent, but they are not here yet: they are driving.
    sys.SetPendingApexDriving(fs.id, CBConfig.ApexDriveTicks());
    CBApexArrivalSound(game);
    fs.apexAtKills = fs.kills;
    sys.ArmApexBounty(fs.id);
    CBLog.Info(n"Spawn", s"Apex squad from \(NameToString(fs.id)) arriving by car.");
    return;
  }
  // CBSpawnGroup will refuse while the world is still streaming in, so this can only land on a settled frame. CB_Apex
  // is also tagged n"Cyberbane", so the session sweep clears it.
  CBWalkInRest(sys, game, fs, record, n"CB_Apex", 0, CBConfig.ApexStrikeTeamSize());
  if sys.GetApexMusterMask() == 0 {
    // The world was not settled enough to place anyone. Keep the kills on the books and keep
    // the appointment, so the next tick tries again rather than charging the player for a
    // no-show.
    let why = CBBlockLabel(CBLastSpawnBlock());
    if StrLen(why) == 0 {
      why = CBT(n"Cyberbane-FactionApex-NoReasonRecorded");
    }
    CBLog.Info(n"Spawn", s"Apex squad for \(NameToString(faction)) could not be placed: \(why).");
    if sys.AgePendingApexHold() {
      sys.ClearApexMuster();
    }
    return;
  }
  sys.SetPendingApex(n"", 0);   // somebody is standing there: the appointment is kept
  fs.apexAtKills = fs.kills;   // paid for: the next one needs fresh bodies
  sys.ArmApexBounty(fs.id);
  CBApexArrivalSound(game);    // only once somebody is actually standing there
  CBApexTerrorWave(game);      // and everybody nearby gets out of the way
  if CBConfig.ApexEscortCount() > 0 && TDBID.IsValid(fs.sampleRecord) {
    let escortEntity: EntityID;
    // CB_Escort, not CB_Squad.
    CBSpawnGroup(game, fs.sampleRecord, n"", CBConfig.ApexEscortCount(), n"CB_Escort",
      CBConfig.ApexSpawnDistance() + 4.0, escortEntity);
  }
}
