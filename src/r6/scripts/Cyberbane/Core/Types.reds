// Cyberbane - Shared enums (spec §6.4)
//
// Enums are prefixed ECB. Integer values are stable and part of the persistent
// schema: never renumber an existing value; only append new ones.

enum ECBArchetype {
  Butcher = 0,
  Ghost = 1,
  Professional = 2,
  Chromed = 3,
  Netrunner = 4,
  Brawler = 5,
}

enum ECBVictimClass {
  Civilian = 0,
  Ganger = 1,
  Elite = 2,
  Officer = 3,
  Boss = 4,
  Cop = 5,
  MaxTac = 6,
  Corpo = 7,
  Cyberpsycho = 8,
  Rival = 9,
}

enum ECBKillMethod {
  Firearm = 0,
  Headshot = 1,
  Blade = 2,
  Blunt = 3,
  Fists = 4,
  Quickhack = 5,
  Explosive = 6,
  Vehicle = 7,
  Finisher = 8,
  Dismember = 9,
  Environmental = 10,
}

// Scar kinds, as bit indices for CBMaskSet / CBMaskHas. Coarse on purpose: the engine only
// separates a few kinds of damage at the point we see it.
public func CBScarShot() -> Int32 = 0
public func CBScarCut() -> Int32 = 1
public func CBScarBurned() -> Int32 = 2
public func CBScarFried() -> Int32 = 3

enum ECBRivalSource {
  Survivor = 0,
  Spared = 1,
  Killer = 2,
  Avenger = 3,
  Hunter = 4,
}

enum ECBRivalState {
  Active = 0,
  Hunting = 1,
  Dormant = 2,
  Slain = 3,
  Retired = 4,
  Debtor = 5,
}

enum ECBRivalEventKind {
  Created = 0,
  Escaped = 1,
  Promoted = 2,
  KilledV = 3,
  SparedByV = 4,
  Slain = 5,
  Retired = 6,
}

enum ECBRenownTier {
  Nobody = 0,
  LocalName = 1,
  KnownMerc = 2,
  Notorious = 3,
  Infamous = 4,
  Legend = 5,
}

enum ECBCivTier {
  Normal = 0,
  Notice = 1,
  Uneasy = 2,
  Afraid = 3,
  Terror = 4,
}

enum ECBPosture {
  Allied = 0,
  Friendly = 1,
  Neutral = 2,
  Hostile = 3,
  Vendetta = 4,
}

// ---- Small bit-set helpers -------------------------------------------------
//
// Persisted classes store their small fixed sets (districts a rumor reached, the traits a
// Rival carries) as a bit per entry in an Int32 rather than as a nested array. A scalar
// always comes back from a save intact; a nested dynamic array is not a documented-
// supported shape and a malformed one takes the game down (see CBRumor.reachedMask).
//
// redscript has &, | and ~ but no shift operator, so the bit value is built by doubling.
// Bit indices are part of the persistent schema: never renumber an existing one.
public func CBBitValue(bit: Int32) -> Int32 {
  if bit < 0 || bit > 30 {
    return 0;
  }
  let v = 1;
  let i = 0;
  while i < bit {
    v *= 2;
    i += 1;
  }
  return v;
}

public func CBMaskHas(mask: Int32, bit: Int32) -> Bool {
  let v = CBBitValue(bit);
  return v != 0 && (mask & v) != 0;
}

public func CBMaskSet(mask: Int32, bit: Int32) -> Int32 {
  return mask | CBBitValue(bit);
}

public func CBMaskClear(mask: Int32, bit: Int32) -> Int32 {
  return mask & ~CBBitValue(bit);
}

public func CBMaskCount(mask: Int32, slots: Int32) -> Int32 {
  let n = 0;
  let i = 0;
  while i < slots {
    if CBMaskHas(mask, i) {
      n += 1;
    }
    i += 1;
  }
  return n;
}

// Archetype accumulator count - keep in sync with ECBArchetype.
public func CBArchetypeCount() -> Int32 = 6
public func CBVictimClassCount() -> Int32 = 10
public func CBKillMethodCount() -> Int32 = 11
