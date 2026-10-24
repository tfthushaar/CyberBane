// Cyberbane — Look registry seed (spec Appendix E)
//
// Feeds the Look (L) and Disguise (Dg) computations (spec §7.4). Tags are visual
// tags (GetVisualTags) resolved in spike S-10; gang-specific clothing is added as
// exact-record CBLookItemDef entries during S-10 with the right faction tag.
// The tag names below are stable identifiers.

public func CBSeedLooks(c: ref<CyberbaneContent>) -> Void {
  // tag, score, disguise, factionTag
  c.AddLookTag(CBMakeLookTag(n"FaceMask",          12.0, 0.25, n""));
  c.AddLookTag(CBMakeLookTag(n"Hood",               2.0, 0.10, n""));
  c.AddLookTag(CBMakeLookTag(n"Sunglasses",         2.0, 0.05, n""));
  c.AddLookTag(CBMakeLookTag(n"MilitaryOuterwear",  8.0, 0.0,  n""));
  c.AddLookTag(CBMakeLookTag(n"AggressiveMotif",    6.0, 0.0,  n""));
  c.AddLookTag(CBMakeLookTag(n"GangStyle",          5.0, 0.0,  n""));
  c.AddLookTag(CBMakeLookTag(n"NetrunnerSuit",      6.0, 0.0,  n""));
  c.AddLookTag(CBMakeLookTag(n"FormalCorpoSuit",   -5.0, 0.0,  n""));
  c.AddLookTag(CBMakeLookTag(n"CasualStreet",       0.0, 0.0,  n""));

  // Character-customization options (spec §7.4), resolved in S-10.
  c.AddCustomization(CBMakeCustomization(n"FaceChrome",  10.0));
  c.AddCustomization(CBMakeCustomization(n"FaceScars",    6.0));
  c.AddCustomization(CBMakeCustomization(n"FaceTattoos",  6.0));
  c.AddCustomization(CBMakeCustomization(n"CyberEyes",    8.0));
  c.AddCustomization(CBMakeCustomization(n"CyberTeeth",   5.0));
}
