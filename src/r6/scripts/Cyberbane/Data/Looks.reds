// Cyberbane - Look registry seed (spec Appendix E)
//
// Feeds the Look (L) and Disguise (Dg) computations (spec §7.4). Tags are visual
// tags (GetVisualTags) resolved in spike S-10; gang-specific clothing is added as
// exact-record CBLookItemDef entries during S-10 with the right faction tag.
// The tag names below are stable identifiers.

func CBGangClothes(c: ref<CyberbaneContent>, record: TweakDBID, faction: CName) -> Void {
  let item = new CBLookItemDef();
  item.record = record;
  item.disguise = CBConfig.GangColoursDisguise();
  item.factionTag = faction;
  c.AddLookItem(item);
}

public func CBSeedLooks(c: ref<CyberbaneContent>) -> Void {
  // The gang clothing that exists, as exact records. Faction Disguises read this table and nothing
  // had ever been put in it, so the setting did nothing. This is everything in the game's clothing
  // files that belongs to a gang by name: the nomads, and one Wraiths vest. Other gangs' colours
  // are on their NPCs' appearances, which are not items V can wear.
  let nomads: array<TweakDBID> = [t"Items.Nomad_01_Set_Boots", t"Items.Nomad_01_Set_Jacket", t"Items.Nomad_01_Set_Mask",
                t"Items.Nomad_01_Set_Pants", t"Items.Nomad_01_Set_TShirt", t"Items.Q000_Nomad_Boots",
                t"Items.Q000_Nomad_Pants", t"Items.Q000_Nomad_TShirt", t"Items.Q000_Nomad_Vest",
                t"Items.Q000_Nomad_noPatch_Vest", t"Items.Q000_half_Nomad", t"Items.Q114_Aldecaldo_Jacket",
                t"Items.Q301_Nomad_MA_Boots", t"Items.Q301_Nomad_MA_Face", t"Items.Q301_Nomad_MA_InnerTorso",
                t"Items.Q301_Nomad_MA_OuterTorso", t"Items.Q301_Nomad_MA_Pants", t"Items.Q301_Nomad_WA_Boots",
                t"Items.Q301_Nomad_WA_Face", t"Items.Q301_Nomad_WA_InnerTorso",
                t"Items.Q301_Nomad_WA_OuterTorso", t"Items.Q301_Nomad_WA_Pants"];
  for nomad in nomads {
    CBGangClothes(c, nomad, n"Aldecaldos");
  }
  CBGangClothes(c, t"Items.SQ021_Wraiths_Vest", n"Wraiths");

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
