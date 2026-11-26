// Cyberbane - Mod Settings bridge
//
// Every call into Mod Settings goes through here, compiled only when its module is installed. Without it Cyberbane runs
// on its default settings.

@if(ModuleExists("ModSettingsModule"))
public func CBModSettingsMods() -> array<CName> {
  return ModSettings.GetMods();
}

@if(!ModuleExists("ModSettingsModule"))
public func CBModSettingsMods() -> array<CName> {
  let none: array<CName>;
  return none;
}

@if(ModuleExists("ModSettingsModule"))
public func CBModSettingsListen(s: ref<IScriptable>) -> Void {
  ModSettings.RegisterListenerToClass(s);
  ModSettings.RegisterListenerToModifications(s);
}

@if(!ModuleExists("ModSettingsModule"))
public func CBModSettingsListen(s: ref<IScriptable>) -> Void {
}

@if(ModuleExists("ModSettingsModule"))
public func CBModSettingsUnlisten(s: ref<IScriptable>) -> Void {
  ModSettings.UnregisterListenerToClass(s);
  ModSettings.UnregisterListenerToModifications(s);
}

@if(!ModuleExists("ModSettingsModule"))
public func CBModSettingsUnlisten(s: ref<IScriptable>) -> Void {
}

// Whether Mod Settings is installed, for the log.
@if(ModuleExists("ModSettingsModule"))
public func CBModSettingsPresent() -> Bool = true

@if(!ModuleExists("ModSettingsModule"))
public func CBModSettingsPresent() -> Bool = false

// The stored value of an enum setting another mod keeps in Mod Settings, found by its mod and label keys. -1 when there
// is no such setting.
@if(ModuleExists("ModSettingsModule"))
public func CBModSettingsEnumByLabel(mod: CName, label: CName) -> Int32 {
  let cats = ModSettings.GetCategories(mod);
  let c = 0;
  while c < ArraySize(cats) {
    let vars = ModSettings.GetVars(mod, cats[c]);
    let v = 0;
    while v < ArraySize(vars) {
      let e = vars[v] as ModConfigVarEnum;
      if IsDefined(e) && Equals(e.GetDisplayName(), label) {
        return e.GetValue();
      }
      v += 1;
    }
    c += 1;
  }
  return -1;
}

@if(!ModuleExists("ModSettingsModule"))
public func CBModSettingsEnumByLabel(mod: CName, label: CName) -> Int32 = -1
