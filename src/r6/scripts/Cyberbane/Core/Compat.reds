// Cyberbane - Compile-time compatibility with other mods
//
// Redscript can test for another mod's module at compile time. That is the steadiest detection available: it costs
// nothing at runtime, it creates no dependency (the mod does not need to be installed), and it cannot fail the way a
// runtime lookup or a settings-list string match can.

@if(ModuleExists("MuchBetterAI.Core"))
public func CBMbaiActive() -> Bool {
  return true;
}

@if(!ModuleExists("MuchBetterAI.Core"))
public func CBMbaiActive() -> Bool {
  return false;
}

// True when another mod already equips NPCs with gameplay abilities, so Cyberbane should not
// also do it. Ability packages stack rather than merge, so two mods both handing out a
// Sandevistan produce an enemy with two of them.
public func CBAiKitOwner() -> Bool {
  return CBMbaiActive() || CBNgpActive();
}

// True when some other mod owns making enemies break and run, so Cyberbane should not also
// push them. Kept as its own function so more mods can be added without touching call sites.
public func CBExternalMoraleOwner() -> Bool {
  return CBMbaiActive();
}

// Street Sense (Nexus 28989) by DigitalVixen gives crowds their own reactions to V: NPCs clock what you are carrying
// and what you are wearing, double-take, and call out as you pass.
public func CBDetectStreetSense() -> Bool {
  let mods = CBModSettingsMods();
  if ArraySize(mods) == 0 {
    return false;
  }
  for mod in mods {
    if StrContains(NameToString(mod), "Street Sense") || StrContains(NameToString(mod), "StreetSense") {
      return true;
    }
  }
  return false;
}
