// Cyberbane - nobody we send is beyond V's reach
//
// Every body Cyberbane builds for a fight against V gets a ceiling on how long V's own damage takes to put it down,
// counted the way the game counts it: health, and armour, which the game turns into health (each point divides a hit by
// 1 + armour x the game's armour effectiveness, DamageSystem's mitigation).

@addField(ScriptedPuppet)
public let cbKillLimit: Float;          // the most effective health this body may carry; 0 = not one of our fighters

@addField(ScriptedPuppet)
public let cbKillChecked: Bool;         // checked again on V's first hit

@addField(ScriptedPuppet)
public let cbWatchAt: Float;            // when the last burst of V's hits started (sim seconds)

@addField(ScriptedPuppet)
public let cbWatchPool: Float;          // health before that burst

@addField(ScriptedPuppet)
public let cbWatchLost: Float;          // what the game drained in that burst

@addField(ScriptedPuppet)
public let cbWatchTried: Float;         // all the game drained since the last look

@addField(ScriptedPuppet)
public let cbWatchUndone: Float;        // how much of it came back

// How many seconds of V's measured fire the toughest of each kind may take. Generous on purpose: the build's own
// targets sit well inside these, and real fights have misses, cover and reloads on top.
public func CBKillableSecondsRival(grade: Float) -> Float {
  return CBConfig.KillableRivalSecondsLow()
         + (CBConfig.KillableRivalSecondsTop() - CBConfig.KillableRivalSecondsLow()) * ClampF(grade, 0.0, 1.0);
}

// The game's armour effectiveness for an NPC (StatsDataSystem, as DamageSystem uses it).
public func CBArmourPerPoint(game: GameInstance) -> Float {
  let sds = GameInstance.GetStatsDataSystem(game);
  return IsDefined(sds) ? MaxF(sds.GetArmorEffectivenessValue(false), 0.0) : 0.0;
}

// Health as V's damage meets it: max health times what armour multiplies it by.
public func CBEffectiveHealth(game: GameInstance, stats: ref<StatsSystem>, id: StatsObjectID) -> Float {
  let health = stats.GetStatValue(id, gamedataStatType.Health);
  let armour = MaxF(stats.GetStatValue(id, gamedataStatType.Armor), 0.0);
  return health * (1.0 + armour * CBArmourPerPoint(game));
}

// Sets the ceiling for a body about to be built: `seconds` of V's measured damage, or, when V's damage cannot be read
// (no weapon out: a netrunner), a few times what the body carried before the build.
public func CBSetKillLimit(game: GameInstance, puppet: ref<ScriptedPuppet>, seconds: Float, opt measure: ref<CBVMeasure>) -> Void {
  if !IsDefined(puppet) {
    return;
  }
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let m = IsDefined(measure) ? measure : CBMeasureV(game);
  let dps = IsDefined(m) ? m.Dps() : 0.0;
  let base = CBEffectiveHealth(game, stats, Cast<StatsObjectID>(puppet.GetEntityID()));
  let limit = dps > 0.0 ? dps * MaxF(seconds, 1.0) : base * CBConfig.KillableBlindMult();
  // Never below what the body already carried: the ceiling only ever takes away what Cyberbane stacked on.
  puppet.cbKillLimit = MaxF(limit, base);
}

// Brings the finished body inside its ceiling. Armour first, so no hit glances off for next to nothing, then health.
// `refill` tops health up to the new maximum (at the build, before the fight); later checks leave it where it is.
public func CBKeepKillable(game: GameInstance, puppet: ref<ScriptedPuppet>, refill: Bool) -> Void {
  if !IsDefined(puppet) || puppet.cbKillLimit <= 0.0 || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  let stats = GameInstance.GetStatsSystem(game);
  let pools = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(stats) || !IsDefined(pools) {
    return;
  }
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  CBStopHealthRegen(pools, id);
  let per = CBArmourPerPoint(game);
  let armour = MaxF(stats.GetStatValue(id, gamedataStatType.Armor), 0.0);
  let said = "";
  if per > 0.0 && 1.0 + armour * per > CBConfig.KillableArmourFactor() {
    let keep = (CBConfig.KillableArmourFactor() - 1.0) / (armour * per);
    let m = RPGManager.CreateStatModifier(gamedataStatType.Armor, gameStatModifierType.Multiplier, keep);
    if IsDefined(m) {
      stats.AddModifier(id, m);
      said += s" armour x\(keep)";
    }
  }
  let ehp = CBEffectiveHealth(game, stats, id);
  if ehp > puppet.cbKillLimit && ehp > 0.0 {
    let cut = puppet.cbKillLimit / ehp;
    let h = RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, cut);
    if IsDefined(h) {
      stats.AddModifier(id, h);
      said += s" health x\(cut)";
    }
  }
  if StrLen(said) > 0 {
    CBLog.Info(n"Spawn", s"Kept within V's reach (\(ehp) effective health, no more than \(puppet.cbKillLimit)):\(said).");
    if refill {
      pools.RequestSettingStatPoolMaxValue(id, gamedataStatPoolType.Health, null);
    }
    // The build's record of this body follows, so streaming back in is not taken for a lost build and built again.
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      sys.NoteRebuilt(puppet.GetEntityID(), stats.GetStatValue(id, gamedataStatType.Health));
    }
  }
}

// V's own people (the crew, followers, allies, anybody turned to V's side) are protected while down on purpose, by their
// own setup; the watch never takes that off.
public func CBKillableFriend(p: ref<ScriptedPuppet>) -> Bool {
  if ScriptedPuppet.IsPlayerCompanion(p) || StatusEffectSystem.ObjectHasStatusEffectWithTag(p, n"FollowerDefeated") {
    return true;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let id = p.GetEntityID();
  return des.IsTagged(id, n"CB_Own") || des.IsTagged(id, n"CB_Follower") || des.IsTagged(id, n"CB_Ally")
      || des.IsTagged(id, n"CB_Turned") || des.IsTagged(id, n"CB_Guard");
}

// No regeneration on a body fighting V, whoever turned it on.
public func CBStopHealthRegen(pools: ref<StatPoolsSystem>, id: StatsObjectID) -> Void {
  let regen: StatPoolModifier;
  pools.GetModifier(id, gamedataStatPoolType.Health, gameStatPoolModificationTypes.Regeneration, regen);
  if regen.enabled {
    regen.enabled = false;
    pools.RequestSettingModifier(id, gamedataStatPoolType.Health, gameStatPoolModificationTypes.Regeneration, regen);
  }
}

public func CBKillableHitter(instigator: wref<GameObject>) -> Bool {
  return IsDefined(instigator) && (instigator.IsPlayer() || ScriptedPuppet.IsPlayerCompanion(instigator));
}

// Before the game applies one of V's hits: the first hit queues the second look at the ceiling, and health that came
// back since the last burst is counted.
public func CBKillableWatchBefore(p: ref<ScriptedPuppet>, hitEvent: ref<gameHitEvent>) -> Float {
  let game = p.GetGame();
  let pools = GameInstance.GetStatPoolsSystem(game);
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(pools) || !IsDefined(ts) {
    return -1.0;
  }
  if !p.cbKillChecked {
    p.cbKillChecked = true;
    let ds = GameInstance.GetDelaySystem(game);
    if IsDefined(ds) {
      let cb = new CBKillableCheckCallback();
      cb.game = game;
      cb.body = p.GetEntityID();
      ds.DelayCallback(cb, 0.1, false);
    }
  }
  let now = EngineTime.ToFloat(ts.GetSimTime());
  let before = pools.GetStatPoolValue(Cast<StatsObjectID>(p.GetEntityID()), gamedataStatPoolType.Health, false);
  if p.cbWatchAt > 0.0 && now - p.cbWatchAt >= CBConfig.KillableBurstSeconds() {
    let expected = p.cbWatchPool - p.cbWatchLost;
    if before > expected + 1.0 {
      p.cbWatchUndone += before - expected;
    }
    p.cbWatchAt = 0.0;
  }
  if p.cbWatchAt <= 0.0 {
    p.cbWatchAt = MaxF(now, 0.001);
    p.cbWatchPool = before;
    p.cbWatchLost = 0.0;
  }
  return before;
}

// After the game applied it: what it drained is counted, and when most of what V has dealt keeps coming back, the
// cause comes off and the damage goes back on.
public func CBKillableWatchAfter(p: ref<ScriptedPuppet>, hitEvent: ref<gameHitEvent>, valuesLost: array<SDamageDealt>) -> Void {
  let lost = 0.0;
  let i = 0;
  while i < ArraySize(valuesLost) {
    if Equals(valuesLost[i].affectedStatPool, gamedataStatPoolType.Health) {
      lost += valuesLost[i].value;
    }
    i += 1;
  }
  p.cbWatchLost += lost;
  p.cbWatchTried += lost;
  if p.IsDead() {
    return;
  }
  let game = p.GetGame();
  let stats = GameInstance.GetStatsSystem(game);
  let pools = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(stats) || !IsDefined(pools) {
    return;
  }
  let id = Cast<StatsObjectID>(p.GetEntityID());
  let maxHealth = stats.GetStatValue(id, gamedataStatType.Health);
  if maxHealth <= 0.0 || p.cbWatchTried < maxHealth * CBConfig.KillableWatchWindow() {
    return;
  }
  let undone = p.cbWatchUndone;
  let tried = p.cbWatchTried;
  p.cbWatchTried = 0.0;
  p.cbWatchUndone = 0.0;
  if undone < tried * CBConfig.KillableUndoneShare() || CBKillableFriend(p) {
    return;
  }
  CBDisarmGodMode(game, p);
  CBStopHealthRegen(pools, id);
  let now = pools.GetStatPoolValue(id, gamedataStatPoolType.Health, false);
  let floor = maxHealth * 0.01;
  let back = MaxF(now - undone, floor);
  if back < now {
    pools.RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, back, hitEvent.attackData.GetInstigator(), false);
  }
  CBLog.Info(n"Spawn", s"Something kept one of ours on their feet: \(undone) of the last \(tried) of V's damage came back. Took it off and put the damage back on (\(now) to \(back)).");
}

// The second look, a moment after V's first hit landed.
public class CBKillableCheckCallback extends DelayCallback {
  public let game: GameInstance;
  public let body: EntityID;

  public func Call() -> Void {
    let p = GameInstance.FindEntityByID(this.game, this.body) as ScriptedPuppet;
    if !IsDefined(p) || !p.IsAttached() || p.IsDead() || !CBWorldStable(this.game) {
      return;
    }
    CBKeepKillable(this.game, p, false);
  }
}

// Whether a body already carries an ability from its own record or archetype, which the game applies itself.
public func CBRecordCarriesAbility(npc: ref<NPCPuppet>, ability: wref<GameplayAbility_Record>) -> Bool {
  if !IsDefined(npc) || !IsDefined(ability) {
    return false;
  }
  let rec = TweakDBInterface.GetCharacterRecord(npc.GetRecordID());
  if !IsDefined(rec) {
    return false;
  }
  if rec.AbilitiesContains(ability) {
    return true;
  }
  let arch = rec.ArchetypeData();
  if !IsDefined(arch) {
    return false;
  }
  let groups: array<wref<GameplayAbilityGroup_Record>>;
  arch.AbilityGroups(groups);
  let i = 0;
  while i < ArraySize(groups) {
    if IsDefined(groups[i]) && groups[i].AbilitiesContains(ability) {
      return true;
    }
    i += 1;
  }
  return false;
}

// The subdermal armour family: each tier adds to HasSubdermalArmor and then multiplies armour and bonus health by it,
// so two of them on one body compound.
public func CBIsSubdermalAbility(id: TweakDBID) -> Bool {
  return id == t"Ability.HasSubdermalArmorHigh" || id == t"Ability.HasSubdermalArmorMedium"
      || id == t"Ability.HasSubdermalArmorLow" || id == t"Ability.HasSubdermalArmorHigh_Mechanical"
      || id == t"Ability.HasSubdermalArmorMedium_Mechanical" || id == t"Ability.HasSubdermalArmorLow_Mechanical";
}

// ---- Hits that would do nothing -------------------------------------------------------------------------------
//
// The game drops a hit to nothing before any damage is worked out when the target is invulnerable (god mode, or the
// IsInvulnerable stat from a status effect or its record), and stops death for an immortal one. Such a hit never reaches
// StatPoolsManager.ApplyDamage, so the watch above cannot see it. So the check runs at the start of the game's own
// pipeline, on every hit V's side lands on one of ours: whatever makes them untouchable comes off before the hit is
// weighed. The moment of grace the game gives right after a defeat (InvulnerableAfterDefeated) stays, and so does
// anything protecting V's own people.

@addField(ScriptedPuppet)
public let cbHittableLogged: Bool;      // said once in the log that something had made them untouchable

@addField(ScriptedPuppet)
public let cbInvulnCut: Bool;           // the record's own invulnerability has been cancelled with a stat modifier

@wrapMethod(DamageSystem)
private func PreProcess(hitEvent: ref<gameHitEvent>, cache: ref<CacheData>) -> Bool {
  if IsDefined(hitEvent) {
    CBKeepHittable(hitEvent);
  }
  return wrappedMethod(hitEvent, cache);
}

public func CBKeepHittable(hitEvent: ref<gameHitEvent>) -> Void {
  let p = hitEvent.target as ScriptedPuppet;
  if !IsDefined(p) || p.cbKillLimit <= 0.0 || !p.IsAttached() || p.IsDead()
     || !CBKillableHitter(hitEvent.attackData.GetInstigator()) {
    return;
  }
  if CBKillableFriend(p) || ScriptedPuppet.IsDefeated(p) {
    return;
  }
  let game = p.GetGame();
  let id = p.GetEntityID();
  let gms = GameInstance.GetGodModeSystem(game);
  let stats = GameInstance.GetStatsSystem(game);
  let godded = IsDefined(gms) && (gms.HasGodMode(id, gameGodModeType.Invulnerable) || gms.HasGodMode(id, gameGodModeType.Immortal));
  let flagged = IsDefined(stats) && stats.GetStatValue(Cast<StatsObjectID>(id), gamedataStatType.IsInvulnerable) > 0.0;
  if !godded && !flagged {
    return;
  }
  if godded {
    CBDisarmGodMode(game, p);
  }
  if flagged {
    CBDropInvulnerableEffects(game, p);
    let left = stats.GetStatValue(Cast<StatsObjectID>(id), gamedataStatType.IsInvulnerable);
    if left > 0.0 && !p.cbInvulnCut {
      // From the record itself, with no effect to take off.
      let m = RPGManager.CreateStatModifier(gamedataStatType.IsInvulnerable, gameStatModifierType.Additive, -left);
      if IsDefined(m) {
        stats.AddModifier(Cast<StatsObjectID>(id), m);
        p.cbInvulnCut = true;
      }
    }
  }
  if !p.cbHittableLogged {
    p.cbHittableLogged = true;
    CBLog.Info(n"Spawn", s"One of ours could not be hurt (god mode \(godded), invulnerable stat \(flagged)); that came off before V's hit landed.");
  }
}

// Status effects that make them invulnerable, except the game's short grace after a defeat.
func CBDropInvulnerableEffects(game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  let ses = GameInstance.GetStatusEffectSystem(game);
  if !IsDefined(ses) {
    return;
  }
  let id = p.GetEntityID();
  let effects: array<ref<StatusEffect>>;
  ses.GetAppliedEffects(id, effects);
  let i = 0;
  while i < ArraySize(effects) {
    let rec = IsDefined(effects[i]) ? effects[i].GetRecord() : null;
    i += 1;
    if IsDefined(rec) && rec.GetID() != t"BaseStatusEffect.InvulnerableAfterDefeated" && CBEffectMakesInvulnerable(rec) {
      CBTrace("stats: an invulnerability effect off one of ours");
      ses.RemoveStatusEffect(id, rec.GetID());
    }
  }
}

func CBEffectMakesInvulnerable(rec: wref<StatusEffect_Record>) -> Bool {
  let packages: array<wref<GameplayLogicPackage_Record>>;
  rec.Packages(packages);
  for pkg in packages {
    if IsDefined(pkg) {
      let mods: array<wref<StatModifier_Record>>;
      pkg.Stats(mods);
      for mod in mods {
        let stat = IsDefined(mod) ? mod.StatType() : null;
        if IsDefined(stat) && Equals(stat.StatType(), gamedataStatType.IsInvulnerable) {
          return true;
        }
      }
    }
  }
  return false;
}
