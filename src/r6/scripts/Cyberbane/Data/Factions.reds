// Cyberbane - Faction registry seed (spec Appendix B)
//
// Flavour values to tune in playtest. `affiliations` (the game's gamedataAffiliation
// record names that map to each faction) are filled in during spike S-01; the
// strings below are the expected names and are safe to leave until then.
// chromeAttitude < 0 means chrome earns respect (Maelstrom).

public func CBSeedFactions(c: ref<CyberbaneContent>) -> Void {
  let f: ref<CBFactionProfile>;

  // id, baseline, courageMod, dreadSens, chromeAttitude, isGang, canBeBought, displayKey
  f = CBMakeFaction(n"TygerClaws", 0.0, 0.05, 1.0, 0.2, true, true, "Cyberbane-Faction-TygerClaws");
  f.affiliations = [n"TygerClaws"];
  f.SetRespect(ECBArchetype.Ghost, 0.3);
  f.SetRespect(ECBArchetype.Brawler, 0.3);
  f.rivalFactions = [n"Mox"];
  f.turf = [n"Westbrook", n"Watson"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Maelstrom", 0.0, 0.10, 0.8, -1.0, true, true, "Cyberbane-Faction-Maelstrom");
  f.affiliations = [n"Maelstrom"];
  f.SetRespect(ECBArchetype.Chromed, 0.6);
  f.SetRespect(ECBArchetype.Butcher, 0.3);
  f.turf = [n"Watson"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Valentinos", 0.0, 0.05, 1.0, 0.2, true, true, "Cyberbane-Faction-Valentinos");
  f.affiliations = [n"Valentinos"];
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.SetRespect(ECBArchetype.Brawler, 0.3);
  f.rivalFactions = [n"SixthStreet"];
  f.turf = [n"Heywood"];
  c.AddFaction(f);

  f = CBMakeFaction(n"SixthStreet", 0.0, 0.0, 1.0, 0.0, true, true, "Cyberbane-Faction-SixthStreet");
  f.affiliations = [n"SixthStreet"];
  f.SetRespect(ECBArchetype.Professional, 0.4);
  f.rivalFactions = [n"Valentinos"];
  f.turf = [n"SantoDomingo"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Animals", 0.0, 0.15, 0.8, 0.0, true, true, "Cyberbane-Faction-Animals");
  f.affiliations = [n"Animals"];
  f.SetRespect(ECBArchetype.Brawler, 0.6);
  f.turf = [n"Pacifica"];
  c.AddFaction(f);

  f = CBMakeFaction(n"VoodooBoys", 0.0, 0.0, 1.0, 0.0, true, true, "Cyberbane-Faction-VoodooBoys");
  f.affiliations = [n"VoodooBoys"];
  f.SetRespect(ECBArchetype.Netrunner, 0.6);
  f.turf = [n"Pacifica"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Scavengers", -10.0, -0.10, 1.3, 0.4, true, true, "Cyberbane-Faction-Scavengers");
  f.affiliations = [n"Scavengers"];
  f.turf = [n"Watson"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Mox", 5.0, -0.05, 1.1, 0.2, true, true, "Cyberbane-Faction-Mox");
  f.affiliations = [n"Mox"];
  f.SetRespect(ECBArchetype.Ghost, 0.3);
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.rivalFactions = [n"TygerClaws"];
  f.turf = [n"Watson", n"Westbrook"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Wraiths", -5.0, 0.05, 1.0, 0.0, true, true, "Cyberbane-Faction-Wraiths");
  f.affiliations = [n"Wraiths"];
  f.SetRespect(ECBArchetype.Butcher, 0.3);
  f.rivalFactions = [n"Aldecaldos"];
  f.turf = [n"Badlands"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Aldecaldos", 10.0, 0.10, 0.7, 0.0, true, true, "Cyberbane-Faction-Aldecaldos");
  f.affiliations = [n"Aldecaldos"];
  f.SetRespect(ECBArchetype.Professional, 0.4);
  f.rivalFactions = [n"Wraiths"];
  f.turf = [n"Badlands"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Barghest", 0.0, 0.10, 0.9, 0.1, true, true, "Cyberbane-Faction-Barghest");
  f.affiliations = [n"Barghest"];
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.SetRespect(ECBArchetype.Butcher, 0.2);
  f.turf = [n"Dogtown"];
  c.AddFaction(f);

  // Corporations cannot be bought (spec §11.4).
  f = CBMakeFaction(n"Arasaka", 0.0, 0.05, 0.8, 0.1, false, false, "Cyberbane-Faction-Arasaka");
  f.affiliations = [n"Arasaka"];
  f.SetRespect(ECBArchetype.Professional, 0.2);
  f.rivalFactions = [n"Militech"];
  f.turf = [n"CityCenter", n"Watson"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Militech", 0.0, 0.05, 0.8, 0.0, false, false, "Cyberbane-Faction-Militech");
  f.affiliations = [n"Militech"];
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.rivalFactions = [n"Arasaka"];
  f.turf = [n"CityCenter", n"Badlands"];
  c.AddFaction(f);

  f = CBMakeFaction(n"KangTao", 0.0, 0.0, 0.9, 0.0, false, false, "Cyberbane-Faction-KangTao");
  f.affiliations = [n"KangTao"];
  f.turf = [n"CityCenter"];
  c.AddFaction(f);

  f = CBMakeFaction(n"NCPD", 10.0, 0.0, 0.9, 0.2, false, true, "Cyberbane-Faction-NCPD");
  f.affiliations = [n"NCPD", n"Police"];
  f.SetRespect(ECBArchetype.Professional, 0.5);
  f.turf = [n"Watson", n"Westbrook", n"CityCenter", n"Heywood", n"SantoDomingo", n"Pacifica", n"Dogtown", n"Badlands"];
  c.AddFaction(f);

  // MaxTac: never bought, courage immune (handled at reaction time), low dreadSens.
  f = CBMakeFaction(n"MaxTac", 0.0, 0.0, 0.3, 0.0, false, false, "Cyberbane-Faction-MaxTac");
  f.affiliations = [n"MaxTac"];
  c.AddFaction(f);
}
