// Cyberbane - District registry seed (spec Appendix C)
//
// Adjacency drives rumor spread (spec §8.5). Values are approximate and meant
// to be tuned in playtest. District ids are matched to the game's districts in
// spike S-06.

public func CBSeedDistricts(c: ref<CyberbaneContent>) -> Void {
  let d: ref<CBDistrictDef>;

  d = CBMakeDistrict(n"Watson", "Cyberbane-District-Watson");
  d.adjacency = [n"CityCenter", n"Westbrook"];
  c.AddDistrict(d);

  d = CBMakeDistrict(n"Westbrook", "Cyberbane-District-Westbrook");
  d.adjacency = [n"Watson", n"CityCenter", n"Heywood", n"SantoDomingo", n"Badlands"];
  c.AddDistrict(d);

  d = CBMakeDistrict(n"CityCenter", "Cyberbane-District-CityCenter");
  d.adjacency = [n"Watson", n"Westbrook", n"Heywood"];
  c.AddDistrict(d);

  d = CBMakeDistrict(n"Heywood", "Cyberbane-District-Heywood");
  d.adjacency = [n"CityCenter", n"Westbrook", n"SantoDomingo", n"Pacifica"];
  c.AddDistrict(d);

  d = CBMakeDistrict(n"SantoDomingo", "Cyberbane-District-SantoDomingo");
  d.adjacency = [n"Heywood", n"Westbrook", n"Badlands"];
  c.AddDistrict(d);

  d = CBMakeDistrict(n"Pacifica", "Cyberbane-District-Pacifica");
  d.adjacency = [n"Heywood", n"Dogtown"];
  c.AddDistrict(d);

  d = CBMakeDistrict(n"Dogtown", "Cyberbane-District-Dogtown");
  d.adjacency = [n"Pacifica"];
  c.AddDistrict(d);

  d = CBMakeDistrict(n"Badlands", "Cyberbane-District-Badlands");
  d.adjacency = [n"SantoDomingo", n"Westbrook"];
  c.AddDistrict(d);
}
