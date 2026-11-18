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
  d.sealed = true;   // behind a wall, and Barghest's
  c.AddDistrict(d);

  d = CBMakeDistrict(n"Badlands", "Cyberbane-District-Badlands");
  d.adjacency = [n"SantoDomingo", n"Westbrook"];
  c.AddDistrict(d);
}

// ---- How each district takes what V does ([6], 2.3.1) ------------------------------------------------
//
// The same deed lands differently in Watson and in City Center. Four numbers per district, each 1.0 for
// "as before", read by the systems that already handle each thing, never kept a second time:
//
//   word    how fast a story moves on from here (the rumour engine's spread interval is divided by it)
//   scare   how easily people here frighten (the crowd's fear, Reactions/Crowd.reds)
//   memory  how many in-game days a place here remembers what happened in it ([7], Model/StreetBook.reds)
//   tells   how likely somebody who saw V hurt a ganger is to tell the gang ([2], Model/Witness.reds)
//
// Off (Mod Settings, The crowd), every district answers 1.0 and three days.

public func CBTempersOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().districtTempers;
}

public func CBTemperWord(id: CName) -> Float {
  if !CBTempersOn() {
    return 1.0;
  }
  switch CBDistrictIndex(id) {
    case 0: return 1.35;   // Watson: Kabuki's stalls and the market, everybody talking
    case 1: return 1.0;    // Westbrook
    case 2: return 0.8;    // City Center: nobody wants to be the one who said it
    case 3: return 1.2;    // Heywood: families, and families talk
    case 4: return 1.0;    // Santo Domingo
    case 5: return 0.9;    // Pacifica
    case 6: return 1.15;   // Dogtown: Barghest hears everything
    case 7: return 0.7;    // the Badlands: a long way between people
    default: return 1.0;
  }
}

public func CBTemperScare(id: CName) -> Float {
  if !CBTempersOn() {
    return 1.0;
  }
  switch CBDistrictIndex(id) {
    case 0: return 1.1;
    case 1: return 1.15;   // Japantown and Charter Hill, money that scares
    case 2: return 1.3;    // corpo plazas
    case 3: return 0.85;
    case 4: return 0.8;    // working people who have seen worse
    case 5: return 0.7;    // Pacifica has seen everything
    case 6: return 0.6;    // a war zone
    case 7: return 0.75;
    default: return 1.0;
  }
}

public func CBTemperMemoryDays(id: CName) -> Float {
  if !CBTempersOn() {
    return 3.0;
  }
  switch CBDistrictIndex(id) {
    case 0: return 2.0;    // Watson forgets fast; it has to
    case 1: return 3.0;
    case 2: return 2.0;    // cleaned up by morning
    case 3: return 5.0;    // Heywood never forgets a name
    case 4: return 4.0;
    case 5: return 3.0;
    case 6: return 5.0;
    case 7: return 6.0;    // the desert keeps everything
    default: return 3.0;
  }
}

public func CBTemperTells(id: CName) -> Float {
  if !CBTempersOn() {
    return 1.0;
  }
  switch CBDistrictIndex(id) {
    case 0: return 1.0;
    case 1: return 0.8;
    case 2: return 0.5;    // not my business
    case 3: return 1.4;    // the Valentinos are family here
    case 4: return 1.2;    // 6th Street looks after its blocks
    case 5: return 1.1;
    case 6: return 1.3;
    case 7: return 1.2;    // the clans look after their own
    default: return 1.0;
  }
}

// How the district takes things, in a few words, for the Hub.
public func CBTemperWords(id: CName) -> String {
  if !CBTempersOn() {
    return "";
  }
  switch CBDistrictIndex(id) {
    case 0: return "Watson talks fast and forgets fast.";
    case 1: return "Westbrook scares easily and keeps it to itself.";
    case 2: return "City Center sees nothing and says less.";
    case 3: return "Heywood remembers every name, and tells the Valentinos.";
    case 4: return "Santo Domingo has seen worse, and looks after its own.";
    case 5: return "Pacifica has seen everything.";
    case 6: return "Dogtown is a war zone, and Barghest hears everything.";
    case 7: return "Out in the Badlands word travels slowly and is never lost.";
    default: return "";
  }
}
