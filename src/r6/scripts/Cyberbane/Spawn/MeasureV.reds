// Cyberbane - V, measured by the game
//
// Everything here is read from the game itself, at the moment somebody is built, never kept: V's level and the five
// attributes, V's health and armour as the game has them (cyberware included), V's best equipped weapon's damage per
// second (EffectiveDPS, the number the game's tooltips show), V's critical hits, and the chrome that changes how V
// fights (a cyberdeck and its RAM, a Sandevistan, a Kerenzikov, Berserk, optical camo, a Smart link).

public class CBVMeasure {
  public let level: Float;
  public let body: Float;
  public let reflexes: Float;
  public let tech: Float;
  public let intelligence: Float;
  public let cool: Float;
  public let health: Float;
  public let armour: Float;
  public let armourFactor: Float;   // armour x effectiveness: a hit on V is cut by 1 / (1 + this)
  public let bestDps: Float;        // V's hardest-hitting equipped weapon
  public let bestMelee: Bool;       // and whether it is a blade or a fist
  public let dpsScale: Float;       // what another mod's damage step does to V's hits with it (Compat/CombatEvolved.reds)
  public let critChance: Float;     // fractions
  public let critDamage: Float;
  public let ram: Float;
  public let cyberdeck: Bool;
  public let sandevistan: Bool;
  public let kerenzikov: Bool;
  public let berserk: Bool;
  public let camo: Bool;
  public let smartLink: Bool;
  public let blades: Int32;         // equipped weapons that are melee
  public let longGuns: Int32;       // equipped rifles of the precision and sniper kinds

  // How V fights, from the build: true for each that fits (several can).
  public func Netrunner() -> Bool { return this.cyberdeck && (this.intelligence >= 12.0 || this.ram >= 10.0); }
  public func Blade() -> Bool { return this.blades > 0 && (this.reflexes >= 12.0 || this.body >= 12.0 || this.blades >= 2); }
  public func Stealth() -> Bool { return this.cool >= 12.0 || this.camo; }
  public func Quick() -> Bool { return this.sandevistan || this.kerenzikov || this.reflexes >= 15.0; }
  public func Tank() -> Bool { return this.body >= 15.0 || this.berserk; }
  public func Tech() -> Bool { return this.tech >= 15.0 || this.smartLink; }
  public func Marksman() -> Bool { return this.longGuns > 0; }

  // V's damage as a fight sees it: the best weapon, with what V's critical hits add on average, and whatever another
  // mod's damage step does to it.
  public func Dps() -> Float {
    let scale = this.dpsScale > 0.0 ? this.dpsScale : 1.0;
    return this.bestDps * (1.0 + this.critChance * this.critDamage) * scale;
  }

  public func Styles() -> String {
    let out = "";
    if this.Netrunner() { out += "netrunner "; }
    if this.Blade() { out += "blade "; }
    if this.Stealth() { out += "stealth "; }
    if this.Quick() { out += "reflexes "; }
    if this.Tank() { out += "tank "; }
    if this.Tech() { out += "tech "; }
    if this.Marksman() { out += "marksman "; }
    return StrLen(out) > 0 ? out : "gunner ";
  }
}

public func CBMeasureV(game: GameInstance) -> ref<CBVMeasure> {
  let m = new CBVMeasure();
  let player = GetPlayer(game);
  let stats = GameInstance.GetStatsSystem(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(stats) {
    return m;
  }
  let v = Cast<StatsObjectID>(player.GetEntityID());
  m.level = stats.GetStatValue(v, gamedataStatType.Level);
  m.body = stats.GetStatValue(v, gamedataStatType.Strength);
  m.reflexes = stats.GetStatValue(v, gamedataStatType.Reflexes);
  m.tech = stats.GetStatValue(v, gamedataStatType.TechnicalAbility);
  m.intelligence = stats.GetStatValue(v, gamedataStatType.Intelligence);
  m.cool = stats.GetStatValue(v, gamedataStatType.Cool);
  m.health = stats.GetStatValue(v, gamedataStatType.Health);
  m.armour = MaxF(stats.GetStatValue(v, gamedataStatType.Armor), 0.0);
  let sds = GameInstance.GetStatsDataSystem(game);
  if IsDefined(sds) {
    m.armourFactor = m.armour * sds.GetArmorEffectivenessValue(true)
                   * MaxF(stats.GetStatValue(v, gamedataStatType.ArmorEffectivenessMultiplier), 0.0);
  }
  m.critChance = ClampF(stats.GetStatValue(v, gamedataStatType.CritChance) / 100.0, 0.0, 1.0);
  m.critDamage = MaxF(stats.GetStatValue(v, gamedataStatType.CritDamage) / 100.0, 0.0);
  m.ram = stats.GetStatValue(v, gamedataStatType.Memory);
  m.cyberdeck = stats.GetStatValue(v, gamedataStatType.HasCyberdeck) > 0.0;
  m.sandevistan = stats.GetStatValue(v, gamedataStatType.HasSandevistan) > 0.0;
  m.kerenzikov = stats.GetStatValue(v, gamedataStatType.HasKerenzikov) > 0.0;
  m.berserk = stats.GetStatValue(v, gamedataStatType.HasBerserk) > 0.0;
  m.camo = stats.GetStatValue(v, gamedataStatType.OpticalCamoCharges) > 0.0;
  m.smartLink = stats.GetStatValue(v, gamedataStatType.HasSmartLink) > 0.0;
  // The weapons V carries: the best one's damage, and what kinds they are.
  let eq = EquipmentSystem.GetData(player);
  if IsDefined(eq) && IsDefined(ts) {
    let slot = 0;
    while slot < 3 {
      let item = eq.GetItemInEquipSlot(gamedataEquipmentArea.Weapon, slot);
      slot += 1;
      if ItemID.IsValid(item) {
        let data = ts.GetItemData(player, item);
        if IsDefined(data) {
          let dps = data.GetStatValueByType(gamedataStatType.EffectiveDPS);
          let kind = data.GetItemType();
          if dps > m.bestDps {
            m.bestDps = dps;
            m.bestMelee = CBCrewSeatForWeapon(kind) == 2;
          }
          if CBCrewSeatForWeapon(kind) == 2 {
            m.blades += 1;
          }
          if Equals(kind, gamedataItemType.Wea_PrecisionRifle) || Equals(kind, gamedataItemType.Wea_SniperRifle) {
            m.longGuns += 1;
          }
        }
      }
    }
  }
  m.dpsScale = CBOtherModsDamageScale(game, m.bestMelee, true);
  return m;
}

// How far into the game V is: 0 at level 1, 1 at the game's level cap (Proficiencies.Level, 60 with Phantom Liberty and
// 50 without).
public func CBVProgress(m: ref<CBVMeasure>) -> Float {
  if !IsDefined(m) {
    return 0.0;
  }
  let cap = 50.0;
  let rec = RPGManager.GetProficiencyRecord(gamedataProficiencyType.Level);
  if IsDefined(rec) && rec.MaxLevel() > 1 {
    cap = Cast<Float>(rec.MaxLevel());
  }
  return ClampF((m.level - 1.0) / (cap - 1.0), 0.0, 1.0);
}

// A share of Smasher's multiplier, and the ceiling over it, both weighed by how far into the game V is: 1 (nothing of
// him) for a new V, the whole share at the level cap.
public func CBSmasherPart(full: Float, share: Float, progress: Float) -> Float {
  return full > 0.0 ? 1.0 + MaxF(full - 1.0, 0.0) * share * ClampF(progress, 0.0, 1.0) : 0.0;
}

// How much tougher to make somebody so they last `seconds` of V's fire: a health multiplier, 0 when V's damage cannot be
// read (no weapon equipped: a netrunner), and the build stands without it.
public func CBMatchHealthMult(m: ref<CBVMeasure>, npcHealth: Float, seconds: Float) -> Float {
  if !IsDefined(m) || npcHealth <= 0.0 || m.Dps() <= 0.0 {
    return 0.0;
  }
  return m.Dps() * seconds / npcHealth;
}

// Hitting hard enough to get through V's armour: `answer` of what it takes off every hit.
public func CBMatchDamageMult(m: ref<CBVMeasure>, answer: Float) -> Float {
  return IsDefined(m) ? 1.0 + m.armourFactor * answer : 1.0;
}

// The game's abilities that answer how V fights (gmpl_abilities/abilities.tweak), and ICE against a netrunner. `grade`
// is how much of a full answer this one brings: an apex squad all of it, a Rival as far as they have come.
public func CBCounterV(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, m: ref<CBVMeasure>,
                       grade: Float) -> String {
  let npc = puppet as NPCPuppet;
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(npc) || !IsDefined(m) || !IsDefined(stats) || grade <= 0.0 {
    return "";
  }
  let said = "";
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  if m.Netrunner() {
    // ICE against V's quickhacks, more the more V can do with them.
    CBAddFlat(stats, id, gamedataStatType.HackingResistance, CBConfig.CounterIce() * grade * ClampF(m.intelligence / 20.0, 0.25, 1.0));
    CBGrantAbility(npc, t"Ability.HasICELevelBooster");
    said += "ICE ";
  }
  if m.Blade() {
    CBGrantAbility(npc, t"Ability.CanBlock");
    CBGrantAbility(npc, t"Ability.HasDodge");
    if grade >= 0.5 {
      CBGrantAbility(npc, t"Ability.CanGuardBreak");
    }
    said += "blocks ";
  }
  if m.Stealth() {
    CBGrantAbility(npc, t"Ability.CanSeeThroughOpticalCamos");
    CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");
    said += "sharp-eyed ";
  }
  if m.Quick() {
    CBGrantAbility(npc, t"Ability.HasDodge");
    CBGrantAbility(npc, t"Ability.CanCatchUp");
    CBAddFlat(stats, id, gamedataStatType.Evasion, CBConfig.CounterEvasion() * grade);
    said += "quick ";
  }
  if m.Tank() {
    CBGrantAbility(npc, t"Ability.CanUseAntiStun");
    if grade >= 0.5 {
      CBGrantAbility(npc, t"Ability.CanGuardBreak");
    }
    said += "steady ";
  }
  if m.Marksman() {
    CBGrantAbility(npc, t"Ability.CanUseCovers");
    CBGrantAbility(npc, t"Ability.CanShootWhileMoving");
    said += "cover ";
  }
  if m.Tech() {
    CBGrantAbility(npc, t"Ability.CanUseCovers");
    CBGrantAbility(npc, t"Ability.CanSprint");
    said += "moving ";
  }
  return said;
}
