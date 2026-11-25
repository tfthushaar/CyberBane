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
