// Cyberbane - The crew's own numbers
//
// What each member's body came with the last time they were out, before anything of Cyberbane's went on: health,
// armour, the game's own damage a second for them (NPCDamage, what their guns turn into each hit) and their rarity.
// The Hub works their real numbers out from these while they are at home, and the kit builds on them when they come.

public class CBCrewBase {
  public let health: Float;
  public let armour: Float;
  public let dps: Float;
  public let rarity: Int32;    // gamedataNPCRarity
  public let level: Float;     // V's level when it was read
}

public class CBCrewStatBook extends ScriptableSystem {
  private persistent let m_id: array<Int32>;
  private persistent let m_health: array<Float>;
  private persistent let m_armour: array<Float>;
  private persistent let m_dps: array<Float>;
  private persistent let m_rarity: array<Int32>;
  private persistent let m_level: array<Float>;

  public static func Get(game: GameInstance) -> ref<CBCrewStatBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewStatBook") as CBCrewStatBook : null;
  }

  private func IndexOf(id: Int32) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_id) {
      if this.m_id[i] == id {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func Note(id: Int32, b: ref<CBCrewBase>) -> Void {
    if !IsDefined(b) || b.health <= 0.0 {
      return;
    }
    let i = this.IndexOf(id);
    if i < 0 {
      ArrayPush(this.m_id, id);
      ArrayPush(this.m_health, b.health);
      ArrayPush(this.m_armour, b.armour);
      ArrayPush(this.m_dps, b.dps);
      ArrayPush(this.m_rarity, b.rarity);
      ArrayPush(this.m_level, b.level);
      return;
    }
    this.m_health[i] = b.health;
    this.m_armour[i] = b.armour;
    this.m_dps[i] = b.dps;
    this.m_rarity[i] = b.rarity;
    this.m_level[i] = b.level;
  }

  // Null for somebody who has never been out with V.
  public func Base(id: Int32) -> ref<CBCrewBase> {
    let i = this.IndexOf(id);
    if i < 0 || i >= ArraySize(this.m_health) {
      return null;
    }
    let b = new CBCrewBase();
    b.health = this.m_health[i];
    b.armour = this.m_armour[i];
    b.dps = this.m_dps[i];
    b.rarity = this.m_rarity[i];
    b.level = this.m_level[i];
    return b;
  }

  public func Forget(id: Int32) -> Void {
    let i = this.IndexOf(id);
    if i < 0 {
      return;
    }
    ArrayErase(this.m_id, i);
    ArrayErase(this.m_health, i);
    ArrayErase(this.m_armour, i);
    ArrayErase(this.m_dps, i);
    ArrayErase(this.m_rarity, i);
    ArrayErase(this.m_level, i);
  }

  public func Clear() -> Void {
    ArrayClear(this.m_id);
    ArrayClear(this.m_health);
    ArrayClear(this.m_armour);
    ArrayClear(this.m_dps);
    ArrayClear(this.m_rarity);
    ArrayClear(this.m_level);
  }
}

// What their body has before the kit: read in CBCrewApplyKit before anything goes on.
public func CBCrewReadBase(game: GameInstance, puppet: ref<ScriptedPuppet>) -> ref<CBCrewBase> {
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(puppet) || !IsDefined(stats) {
    return null;
  }
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  let b = new CBCrewBase();
  b.health = stats.GetStatValue(id, gamedataStatType.Health);
  b.armour = MaxF(stats.GetStatValue(id, gamedataStatType.Armor), 0.0);
  b.dps = MaxF(stats.GetStatValue(id, gamedataStatType.NPCDamage), 0.0);
  b.rarity = EnumInt(puppet.GetNPCRarity());
  let player = GetPlayer(game);
  b.level = IsDefined(player) ? stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Level) : 0.0;
  return b;
}

public func CBCrewBaseOf(game: GameInstance, memberId: Int32) -> ref<CBCrewBase> {
  let book = CBCrewStatBook.Get(game);
  return IsDefined(book) ? book.Base(memberId) : null;
}

// A MaxTac operative at this power level over somebody of this rarity, as the game builds both (npcrarities.tweak): X
// how much more health, Y how much more damage a second. 1 for each when the curves can't be read.
public func CBMaxTacOver(game: GameInstance, powerLevel: Float, rarity: Int32) -> Vector4 {
  let sds = GameInstance.GetStatsDataSystem(game);
  if !IsDefined(sds) || powerLevel <= 0.0 {
    return new Vector4(1.0, 1.0, 0.0, 0.0);
  }
  let mtHealth = CBRarityHealthMult(sds, powerLevel, EnumInt(gamedataNPCRarity.MaxTac));
  let mtDps = CBRarityDpsMult(sds, powerLevel, EnumInt(gamedataNPCRarity.MaxTac));
  let ownHealth = CBRarityHealthMult(sds, powerLevel, rarity);
  let ownDps = CBRarityDpsMult(sds, powerLevel, rarity);
  return new Vector4(MaxF(mtHealth / MaxF(ownHealth, 0.01), 1.0), MaxF(mtDps / MaxF(ownDps, 0.01), 1.0), 0.0, 0.0);
}

// The health multiplier each rarity puts on a body at a power level (a Normal one has none).
func CBRarityHealthMult(sds: ref<StatsDataSystem>, pl: Float, rarity: Int32) -> Float {
  let column = n"";
  if rarity == EnumInt(gamedataNPCRarity.Trash) { column = n"puppet_powerLevelToRarityHealthMultiplier_trash"; }
  if rarity == EnumInt(gamedataNPCRarity.Weak) { column = n"puppet_powerLevelToRarityHealthMultiplier_weak"; }
  if rarity == EnumInt(gamedataNPCRarity.Rare) || rarity == EnumInt(gamedataNPCRarity.Officer) {
    column = n"puppet_powerLevelToRarityHealthMultiplier_rare";
  }
  if rarity == EnumInt(gamedataNPCRarity.Elite) { column = n"puppet_powerLevelToRarityHealthMultiplier_elite"; }
  if rarity == EnumInt(gamedataNPCRarity.Boss) || rarity == EnumInt(gamedataNPCRarity.MaxTac) {
    column = n"puppet_powerLevelToRarityHealthMultiplier_boss";
  }
  if !IsNameValid(column) {
    return 1.0;
  }
  let v = sds.GetValueFromCurve(n"puppet_powerLevelToHealth", pl, column);
  return v > 0.0 ? v : 1.0;
}

// The damage-a-second multiplier each rarity puts on a body: the weak ones' is a multiplier of its own, a boss's and a
// MaxTac's an addition to the one (npcrarities.tweak, modifierType).
func CBRarityDpsMult(sds: ref<StatsDataSystem>, pl: Float, rarity: Int32) -> Float {
  if rarity == EnumInt(gamedataNPCRarity.Weak) {
    let w = sds.GetValueFromCurve(n"puppet_preset_weak_mods", pl, n"power_level_to_dps_mod");
    return w > 0.0 ? w : 1.0;
  }
  if rarity == EnumInt(gamedataNPCRarity.Trash) {
    let t = sds.GetValueFromCurve(n"puppet_preset_trash_mods", pl, n"power_level_to_dps_mod");
    return t > 0.0 ? t : 1.0;
  }
  if rarity == EnumInt(gamedataNPCRarity.Boss) || rarity == EnumInt(gamedataNPCRarity.MaxTac) {
    return 1.0 + MaxF(sds.GetValueFromCurve(n"puppet_preset_boss_mods", pl, n"power_level_to_dps_mod"), 0.0);
  }
  return 1.0;
}

// ---- Their damage, where the game scales a companion's ----------------------------------------------------------------
//
// An NPC's guns read only the game's NPCDamage for them (AttackModifier.PhysicalEnemyDamage, attack_stat_mods.tweak),
// and that same stat is what they would hit V with. So the crew's damage goes on in the step where the game itself
// scales a companion's hits on everybody else (DamageSystem.ProcessPlayerIncomingDamageMultiplier): on anybody but V
// and V's own people, never on V.

@addField(ScriptedPuppet)
public let cbCrewHitMult: Float;   // 0 = none

@wrapMethod(DamageSystem)
private func ProcessPlayerIncomingDamageMultiplier(hitEvent: ref<gameHitEvent>) -> Void {
  wrappedMethod(hitEvent);
  CBCrewHitScale(hitEvent);
}

public func CBCrewHitScale(hitEvent: ref<gameHitEvent>) -> Void {
  if !IsDefined(hitEvent) || !IsDefined(hitEvent.attackData) {
    return;
  }
  let crew = hitEvent.attackData.GetInstigator() as ScriptedPuppet;
  if !IsDefined(crew) || crew.cbCrewHitMult <= 1.0 || crew.IsDead() {
    return;
  }
  let target = hitEvent.target;
  if !IsDefined(target) || target.IsPlayer() {
    return;
  }
  let tp = target as ScriptedPuppet;
  if IsDefined(tp) && CBKillableFriend(tp) {
    return;
  }
  hitEvent.attackComputed.MultAttackValue(crew.cbCrewHitMult);
}
