// Cyberbane - Rival traits & weaknesses (spec §10.5)
//
// Registry metadata (id + display + isWeakness). The concrete stat effects
// (Tough +30% health, Armored +20 armor, etc.) are applied on spawn by the Rival
// spawner, keyed by id, once the stat-modifier API is wired (S-01).

// Stable bit index per trait id, used by CBRival.traitMask / weaknessMask. These values
// are part of the persistent schema: never renumber an existing one, only append.
public func CBTraitCount() -> Int32 = 14

public func CBTraitBit(id: CName) -> Int32 {
  if Equals(id, n"Tough") { return 0; }
  if Equals(id, n"Armored") { return 1; }
  if Equals(id, n"Deadeye") { return 2; }
  if Equals(id, n"Quick") { return 3; }
  if Equals(id, n"PackLeader") { return 4; }
  if Equals(id, n"GrudgeBearer") { return 5; }
  if Equals(id, n"HardToScare") { return 6; }
  if Equals(id, n"ChromedOut") { return 7; }
  if Equals(id, n"Scarred") { return 8; }
  if Equals(id, n"Confident") { return 9; }
  if Equals(id, n"Humiliated") { return 10; }
  if Equals(id, n"Shaken") { return 11; }
  if Equals(id, n"OldWound") { return 12; }
  if Equals(id, n"Reckless") { return 13; }
  return -1;
}

public func CBSeedTraits(c: ref<CyberbaneContent>) -> Void {
  // Traits.
  c.AddTrait(CBMakeTrait(n"Tough",        "Tough",         false));
  c.AddTrait(CBMakeTrait(n"Armored",      "Armored",       false));
  c.AddTrait(CBMakeTrait(n"Deadeye",      "Deadeye",       false));
  c.AddTrait(CBMakeTrait(n"Quick",        "Quick",         false));
  c.AddTrait(CBMakeTrait(n"PackLeader",   "Pack Leader",   false));
  c.AddTrait(CBMakeTrait(n"GrudgeBearer", "Grudge-Bearer", false));
  c.AddTrait(CBMakeTrait(n"HardToScare",  "Hard to Scare", false));
  c.AddTrait(CBMakeTrait(n"ChromedOut",   "Chromed-Out",   false));
  c.AddTrait(CBMakeTrait(n"Scarred",      "Scarred",       false));
  c.AddTrait(CBMakeTrait(n"Confident",    "Confident",     false));
  c.AddTrait(CBMakeTrait(n"Humiliated",   "Humiliated",    false));

  // Weaknesses.
  c.AddTrait(CBMakeTrait(n"Shaken",       "Shaken",        true));
  c.AddTrait(CBMakeTrait(n"OldWound",     "Old Wound",     true));
  c.AddTrait(CBMakeTrait(n"Reckless",     "Reckless",      true));
}
