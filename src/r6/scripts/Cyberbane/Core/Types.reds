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

// Archetype accumulator count - keep in sync with ECBArchetype.
public func CBArchetypeCount() -> Int32 = 6
public func CBVictimClassCount() -> Int32 = 10
public func CBKillMethodCount() -> Int32 = 11
