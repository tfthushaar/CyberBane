// Cyberbane - Rival name pools & epithets (spec Appendix I)
//
// Names are stored on a Rival as integer indices into these pools (no String in
// persistent fields). Handle-only factions have no surnames. ASCII only, so the
// strings survive any encoding round-trip.

public func CBSeedNames(c: ref<CyberbaneContent>) -> Void {
  // Cops and corps had no pool at all, so every Rival from them came out as "Unknown".
  // They use real names rather than street handles.
  c.AddFactionNames(CBMakeFactionNames(n"NCPD",
    ["Marcus", "Dana", "Elliot", "Rosa", "Tyler"],
    ["Reyes", "Okafor", "Vasquez", "Delgado", "Brennan"]));
  c.AddFactionNames(CBMakeFactionNames(n"Police",
    ["Marcus", "Dana", "Elliot", "Rosa", "Tyler"],
    ["Reyes", "Okafor", "Vasquez", "Delgado", "Brennan"]));
  c.AddFactionNames(CBMakeFactionNames(n"Arasaka",
    ["Hiroshi", "Yuki", "Kenzo", "Mariko", "Takeda"],
    ["Oshima", "Nakai", "Fujimoto", "Arakawa"]));
  c.AddFactionNames(CBMakeFactionNames(n"Militech",
    ["Grant", "Dallas", "Vera", "Cole", "Shane"],
    ["Hollister", "Pryce", "Kowalski", "Ramsey"]));
  c.AddFactionNames(CBMakeFactionNames(n"KangTao",
    ["Wei", "Lian", "Jun", "Mei", "Bohai"],
    ["Zhao", "Ling", "Xu", "Chen"]));
  c.AddFactionNames(CBMakeFactionNames(n"Aldecaldos",
    ["Santiago", "Paloma", "Esteban", "Luz", "Mateo"],
    ["Ibarra", "Cortes", "Mendoza", "Rivas"]));

  c.AddFactionNames(CBMakeFactionNames(n"TygerClaws",
    ["Kenji", "Haru", "Daisuke", "Aiko", "Ren"],
    ["Morita", "Sato", "Kuroda", "Ishikawa"]));

  c.AddFactionNames(CBMakeFactionNames(n"Valentinos",
    ["Mateo", "Lupe", "Rafael", "Ines", "Santiago"],
    ["Ortega", "Vargas", "Delgado", "Cruz"]));

  c.AddFactionNames(CBMakeFactionNames(n"SixthStreet",
    ["Cody", "Travis", "Dana", "Wade", "Brooke"],
    ["Hollis", "McCray", "Barnes", "Tate"]));

  c.AddFactionNames(CBMakeFactionNames(n"VoodooBoys",
    ["Jean", "Mirlande", "Placid", "Fabienne"],
    ["Duval", "Toussaint", "Celestin"]));

  c.AddFactionNames(CBMakeFactionNames(n"Mox",
    ["Tess", "Coral", "Dex", "Jo"],
    ["Lane", "Rivera", "Shaw"]));

  c.AddFactionNames(CBMakeFactionNames(n"Barghest",
    ["Viktor", "Aleks", "Jonas", "Mira"],
    ["Kessler", "Brandt", "Novak"]));

  // Handle-only factions.
  c.AddFactionNames(CBMakeHandleNames(n"Maelstrom", ["Static", "Rustbite", "Null", "Shardjaw"]));
  c.AddFactionNames(CBMakeHandleNames(n"Animals", ["Bullneck", "Tusk", "Brickhouse"]));
  c.AddFactionNames(CBMakeHandleNames(n"Scavengers", ["Gutter", "Scalpel", "Tin"]));
  c.AddFactionNames(CBMakeHandleNames(n"Wraiths", ["Dustdevil", "Rattler", "Bonefire"]));

  // Epithets by Rival source + promotion.
  let e = new CBEpithets();
  e.survivor = ["Who Ran", "the Survivor", "Last One Standing"];
  e.spared = ["the Humbled", "Second Chance", "Iron Jaw"];
  e.killer = ["V-Killer", "the Undertaker", "Flatline"];
  e.avenger = ["Bloodsworn", "the Avenger"];
  e.hunter = ["the Hound", "Bounty"];
  e.promotion = ["Twice-Burned", "the Unbroken", "Scarface"];
  c.SetEpithets(e);
}
