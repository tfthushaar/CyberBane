// Cyberbane — Rival traits & weaknesses (spec §10.5)
//
// Registry metadata (id + display + isWeakness). The concrete stat effects
// (Tough +30% health, Armored +20 armor, etc.) are applied on spawn by the Rival
// spawner, keyed by id, once the stat-modifier API is wired (S-01).

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
