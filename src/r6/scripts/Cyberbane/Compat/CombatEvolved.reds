// Cyberbane - Combat Evolved
//
// Combat Evolved multiplies the damage of every gun and every blade or fist, V's included (three times and twice by
// default), in the game's own damage step. Cyberbane measures V's fire from the weapon's own number (CBMeasureV), so with
// it on, everybody Cyberbane builds to last a set time under V's fire went down that much sooner. Its settings are read
// through reflection, so nothing here names anything of Combat Evolved's and nothing changes without it.

public class CBCeProbe {
  public let state: Int32;   // 0 not looked yet, 1 found, 2 absent
  public let cls: ref<ReflectionClass>;

  public func Resolve() -> Bool {
    if this.state == 0 {
      this.state = 2;
      let c = Reflection.GetClass(CBCeConfigClass());
      if IsDefined(c) && IsDefined(c.GetProperty(n"firearmDamageMult")) && IsDefined(c.GetProperty(n"meleeDamageMult")) {
        this.cls = c;
        this.state = 1;
        CBLog.Info(n"Spawn", "Combat Evolved found: its damage multipliers count in how hard V is measured to hit.");
      }
    }
    return this.state == 1;
  }
}

public func CBCeConfigClass() -> CName = n"GangBattlePower.GBPConfig"

// One of its settings, or `fallback` when the setting is missing or not of that type.
func CBCeFloat(probe: ref<CBCeProbe>, owner: ref<IScriptable>, name: CName, fallback: Float) -> Float {
  let prop = probe.cls.GetProperty(name);
  if !IsDefined(prop) || !IsDefined(prop.GetType()) || NotEquals(prop.GetType().GetName(), n"Float") {
    return fallback;
  }
  return FromVariant<Float>(prop.GetValue(ToVariant(owner)));
}

func CBCeBool(probe: ref<CBCeProbe>, owner: ref<IScriptable>, name: CName, fallback: Bool) -> Bool {
  let prop = probe.cls.GetProperty(name);
  if !IsDefined(prop) || !IsDefined(prop.GetType()) || NotEquals(prop.GetType().GetName(), n"Bool") {
    return fallback;
  }
  return FromVariant<Bool>(prop.GetValue(ToVariant(owner)));
}

// What Combat Evolved does to hits with this kind of weapon, V's (`forV`) or anybody else's: 1 without it, or with it
// switched off.
public func CBOtherModsDamageScale(game: GameInstance, melee: Bool, forV: Bool) -> Float {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return 1.0;
  }
  let probe = rt.GetCeProbe();
  if !probe.Resolve() {
    return 1.0;
  }
  let container = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return 1.0;
  }
  let cfg = container.Get(CBCeConfigClass());
  if !IsDefined(cfg) || !CBCeBool(probe, cfg, n"modON", true) {
    return 1.0;
  }
  // V's own multipliers when it keeps V's apart from everybody else's, the shared ones otherwise.
  let own = forV && CBCeBool(probe, cfg, n"separateDamageMults", false);
  let name = melee ? (own ? n"playerMeleeDamageMult" : n"meleeDamageMult") : (own ? n"playerFirearmDamageMult" : n"firearmDamageMult");
  return ClampF(CBCeFloat(probe, cfg, name, 1.0), 0.05, 20.0);
}
