// Cyberbane - Per-event point tables & archetype selection (spec §8.1 - §8.4)
//
// Pure functions. The Signals/Model layers call these to turn a classified
// event into point deltas. Unwitnessed multipliers are applied by the caller
// (renown 0.25x, dread 0.5x, standing 0.25x).

// ---- Archetype primary (spec §8.3) ---------------------------------------
// Returns the primary archetype index, or -1 (Unknown) when the total is below
// the minimum. Switching primary requires the new leader to beat 1.25x the
// current primary's value (hysteresis), which avoids flip-flopping.
public func CBPrimaryArchetype(archetype: array<Float>, currentPrimary: Int32) -> Int32 {
  let count = ArraySize(archetype);
  if count == 0 {
    return -1;
  }
  let total = 0.0;
  let i = 0;
  while i < count {
    total += archetype[i];
    i += 1;
  }
  if total < CBConfig.ArchetypeMinTotal() {
    return -1;
  }
  // Start from whatever V already reads as, so an exact tie keeps the existing label rather
  // than snapping to whichever archetype happens to sit at index 0 (Butcher). Without this,
  // a player whose Ghost and Butcher scores are level is told they are a Butcher.
  let best = 0;
  let bestVal = archetype[0];
  if currentPrimary >= 0 && currentPrimary < count {
    best = currentPrimary;
    bestVal = archetype[currentPrimary];
  }
  i = 0;
  while i < count {
    if archetype[i] > bestVal {
      bestVal = archetype[i];
      best = i;
    }
    i += 1;
  }
  if currentPrimary >= 0 && currentPrimary < count && best != currentPrimary {
    if bestVal < CBConfig.ArchetypeHysteresis() * archetype[currentPrimary] {
      return currentPrimary;
    }
  }
  return best;
}

// ---- Renown per witnessed kill (spec §8.1) -------------------------------
// Cyberpsycho and Rival kills are scored by their own paths, not here.
public func CBRenownForKill(victimClass: Int32) -> Float {
  if victimClass == EnumInt(ECBVictimClass.Ganger) { return 1.5; }
  if victimClass == EnumInt(ECBVictimClass.Elite) { return 3.0; }
  if victimClass == EnumInt(ECBVictimClass.Officer) { return 6.0; }
  if victimClass == EnumInt(ECBVictimClass.Boss) { return 30.0; }
  if victimClass == EnumInt(ECBVictimClass.Cop) { return 2.0; }
  if victimClass == EnumInt(ECBVictimClass.MaxTac) { return 12.0; }
  if victimClass == EnumInt(ECBVictimClass.Corpo) { return 2.0; }
  return 0.0;   // Civilian and anything else
}

// ---- Kill-dread per victim (spec §8.2) -----------------------------------
public func CBKillDreadBase(victimClass: Int32) -> Float {
  if victimClass == EnumInt(ECBVictimClass.Ganger) { return 1.0; }
  if victimClass == EnumInt(ECBVictimClass.Elite) { return 2.0; }
  if victimClass == EnumInt(ECBVictimClass.Officer) { return 3.0; }
  if victimClass == EnumInt(ECBVictimClass.Boss) { return 12.0; }
  if victimClass == EnumInt(ECBVictimClass.Cop) { return 2.0; }
  if victimClass == EnumInt(ECBVictimClass.MaxTac) { return 8.0; }
  if victimClass == EnumInt(ECBVictimClass.Civilian) { return 5.0; }
  if victimClass == EnumInt(ECBVictimClass.Cyberpsycho) { return 5.0; }
  return 0.0;
}

// Method bonus (spec §8.2). Several can apply. brutalMelee covers Blade/Fists/Blunt.
public func CBKillDreadMethodBonus(brutalMelee: Bool, finisher: Bool, dismember: Bool, explosive: Bool, quickhack: Bool) -> Float {
  let b = 0.0;
  if brutalMelee { b += 0.5; }
  if finisher { b += 1.0; }
  if dismember { b += 1.0; }
  if explosive { b += 0.5; }
  if quickhack { b += 0.3; }
  return b;
}

// ---- Standing delta per witnessed kill (spec §8.4) -----------------------
public func CBStandingDeltaForKill(victimClass: Int32) -> Float {
  if victimClass == EnumInt(ECBVictimClass.Ganger) { return -2.0; }
  if victimClass == EnumInt(ECBVictimClass.Elite) { return -4.0; }
  if victimClass == EnumInt(ECBVictimClass.Officer) { return -6.0; }
  if victimClass == EnumInt(ECBVictimClass.Boss) { return -25.0; }
  return 0.0;
}

// ---- Faction renown gain per witnessed kill (spec §8.4) ------------------
public func CBFactionRenownForKill(victimClass: Int32, brutal: Bool) -> Float {
  let base = 1.0;
  if victimClass == EnumInt(ECBVictimClass.Boss) {
    base = 20.0;
  }
  if brutal {
    base += 1.0;   // brutal witnessed kill is worth +2 total (spec §8.4)
  }
  return base;
}

// A kill counts as brutal when it used a finisher, dismember, blade or fists (spec §7.1.2).
public func CBIsBrutalKill(finisher: Bool, dismember: Bool, blade: Bool, fists: Bool) -> Bool {
  return finisher || dismember || blade || fists;
}
