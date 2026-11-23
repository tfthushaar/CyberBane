// Cyberbane - nobody we send is beyond V's reach (2.7.2)
//
// Every body Cyberbane builds for a fight against V gets a ceiling on how long V's own damage takes to put it down,
// counted the way the game counts it: health, and armour, which the game turns into health (each point divides a hit
// by 1 + armour x the game's armour effectiveness, DamageSystem's mitigation). The build's terms are each sensible on
// their own; what made a Scavs Rival shrug off 3k crits was them stacking on a body that already carried the game's
// own subdermal armour, so the ceiling is taken on the finished body, after every term, implant and ability, and again
// the first time V's damage reaches it, when anything the game or another mod added since is on it too.
//
// And nothing heals them out of V's reach: while V is landing hits, the damage the game itself decided to deal is
// compared with what stays off their health. When most of it keeps coming back (regeneration, god mode, anything), the
// cause is taken off and the damage that should have stuck is put back on, never as the killing blow, so the kill is
// still V's own hit.

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

// The game's own armour effectiveness for an NPC (StatsDataSystem, as DamageSystem uses it).
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
