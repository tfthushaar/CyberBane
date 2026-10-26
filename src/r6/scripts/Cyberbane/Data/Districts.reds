// Cyberbane - District registry seed (spec Appendix C)
//
// Adjacency drives rumor spread (spec §8.5). Values are approximate and meant
// to be tuned in playtest. District ids are matched to the game's districts in
// spike S-06.

// How many districts the seed below defines. Keep in sync with CBSeedDistricts.
public func CBDistrictCount() -> Int32 = 8

// Stable bit index per district, used by CBRumor.reachedMask. These values are part of
// the persistent schema: never renumber an existing one, only append.
public func CBDistrictIndex(id: CName) -> Int32 {
  if Equals(id, n"Watson") { return 0; }
  if Equals(id, n"Westbrook") { return 1; }
  if Equals(id, n"CityCenter") { return 2; }
  if Equals(id, n"Heywood") { return 3; }
  if Equals(id, n"SantoDomingo") { return 4; }
  if Equals(id, n"Pacifica") { return 5; }
  if Equals(id, n"Dogtown") { return 6; }
  if Equals(id, n"Badlands") { return 7; }
  return -1;
}

public func CBDistrictAt(index: Int32) -> CName {
  switch index {
    case 0: return n"Watson";
    case 1: return n"Westbrook";
    case 2: return n"CityCenter";
    case 3: return n"Heywood";
    case 4: return n"SantoDomingo";
    case 5: return n"Pacifica";
    case 6: return n"Dogtown";
    case 7: return n"Badlands";
    default: return n"";
  }
}

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
