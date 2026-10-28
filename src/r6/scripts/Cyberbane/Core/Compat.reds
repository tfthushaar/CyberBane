// Cyberbane - Compile-time compatibility with other mods
//
// Redscript can test for another mod's module at compile time. That is the steadiest
// detection available: it costs nothing at runtime, it creates no dependency (the mod does
// not need to be installed), and it cannot fail the way a runtime lookup or a settings-list
// string match can. Much Better AI uses the same technique to detect Immersive Shooting AI,
// which is where this approach came from.
//
// Much Better AI (Nexus 31402) by cshiai rebuilds enemy combat, stealth and detection AI, and
// its Nerve system owns morale: when an enemy breaks, runs, or spreads panic to the people
// around it, that is MBAI's call to make. Cyberbane runs its own morale break and its own
// terror broadcast, so with both installed the same enemy gets told to panic twice.
//
// What Cyberbane stands down when MBAI is present: the terror stim that makes a wounded enemy
// run, and the morale shock that spreads a nearby death through a squad. What it keeps: every
// bit of its own reputation work, including tracking which enemies got away, so Rivals still
// come from people who escaped you even though MBAI is the one deciding they should run.

@if(ModuleExists("MuchBetterAI.Core"))
public func CBMbaiActive() -> Bool {
  return true;
}

@if(!ModuleExists("MuchBetterAI.Core"))
public func CBMbaiActive() -> Bool {
  return false;
}

// True when some other mod owns making enemies break and run, so Cyberbane should not also
// push them. Kept as its own function so more mods can be added without touching call sites.
public func CBExternalMoraleOwner() -> Bool {
  return CBMbaiActive();
}

// Street Sense (Nexus 28989) by DigitalVixen gives crowds their own reactions to V: NPCs
// clock what you are carrying and what you are wearing, double-take, and call out as you
// pass. That is the same ground as Cyberbane's whispers - overheard lines from people
// reacting to you - so with both installed the street talks over itself.
//
// Cyberbane stands its whispers down and keeps everything else. The two are not really
// rivals: Street Sense owns being noticed, Cyberbane owns being feared, and a crowd that
// greets you and then scatters from you is the point.
//
// Detected through Mod Settings rather than ModuleExists, because the name players see in
// the settings menu is steadier than a module path we cannot verify without the mod in hand.
// Returns false while Mod Settings is still registering, and that answer is not cached.
public func CBDetectStreetSense() -> Bool {
  let mods = ModSettings.GetMods();
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
