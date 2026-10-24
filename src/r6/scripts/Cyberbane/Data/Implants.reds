// Cyberbane — Implant registry seed (spec Appendix D)
//
// Scores feed the Chrome (C) computation (spec §7.3). `family` keys are matched
// to cyberware records in spike S-11; the names below are stable identifiers.
// The row with family n"" is the default score for unlisted implants.
// archetype is an ECBArchetype value, or -1 for no nudge.

public func CBSeedImplants(c: ref<CyberbaneContent>) -> Void {
  c.AddImplant(CBMakeImplant(n"MantisBlades",           12.0, true,  EnumInt(ECBArchetype.Butcher)));
  c.AddImplant(CBMakeImplant(n"GorillaArms",            10.0, true,  EnumInt(ECBArchetype.Brawler)));
  c.AddImplant(CBMakeImplant(n"Monowire",               10.0, true,  EnumInt(ECBArchetype.Butcher)));
  c.AddImplant(CBMakeImplant(n"ProjectileLaunchSystem", 12.0, true,  EnumInt(ECBArchetype.Butcher)));
  c.AddImplant(CBMakeImplant(n"Berserk",                12.0, false, EnumInt(ECBArchetype.Chromed)));
  c.AddImplant(CBMakeImplant(n"Sandevistan",            10.0, false, EnumInt(ECBArchetype.Chromed)));
  c.AddImplant(CBMakeImplant(n"Cyberdeck",               6.0, false, EnumInt(ECBArchetype.Netrunner)));
  c.AddImplant(CBMakeImplant(n"Kerenzikov",              4.0, false, EnumInt(ECBArchetype.Chromed)));
  c.AddImplant(CBMakeImplant(n"OpticalCamo",             6.0, false, EnumInt(ECBArchetype.Ghost)));
  c.AddImplant(CBMakeImplant(n"SubdermalArmor",          3.0, true,  -1));
  c.AddImplant(CBMakeImplant(n"KiroshiOptics",           3.0, true,  -1));
  c.AddImplant(CBMakeImplant(n"",                        1.0, false, -1));   // default
}
