// Cyberbane - Mod Settings, when it is there (2.6.5)
//
// "I am using Mod Configuration Menu instead of Mod Settings. It seems the mod requires Mod Settings." It did, and harder than
// it had to: four calls named the ModSettings class directly, and a script that names a class nobody declared stops the
// whole game's script compile, every mod's, not only this one. Those calls come through here now, compiled only when Mod
// Settings' own module is in the build (ModuleExists, the same test Core/Compat.reds and Economy/Peace.reds make for other
// mods). Without it, Cyberbane runs on its defaults: the settings class still exists and every value in it is its default,
// and a settings menu that reads the same annotations (@runtimeProperty "ModSettings.*") shows and changes them.

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
