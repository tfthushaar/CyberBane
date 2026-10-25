// Cyberbane — Deed catalogue seed (spec Appendix F)
//
// requiredState: 0 = Succeeded, 1 = Failed, 2 = Any-finished. Journal paths and
// outcome facts are filled in during spike S-02; the deed effects (Renown, Dread,
// faction standing, rumor, titles) are complete here and apply once the journal
// signal detects completion. Generic gigs/hustles are handled by their own path.

public func CBSeedDeeds(c: ref<CyberbaneContent>) -> Void {
  let d: ref<CBDeedDef>;

  d = CBMakeDeed(n"DEED_HEIST", 0, 150.0, 40.0, n"CityCenter", 30.0);
  d.AddFactionEffect(n"Arasaka", -60.0, 10.0);
  d.AddTitle(n"T_KONPEKI_GHOST");
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_PICKUP_ROYCE", 0, 60.0, 25.0, n"Watson", 8.0);
  d.AddFactionEffect(n"Maelstrom", -40.0, 8.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_PICKUP_DEAL", 0, 40.0, 5.0, n"Watson", 4.0);
  d.AddFactionEffect(n"Maelstrom", 20.0, 5.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_ODA", 0, 60.0, 20.0, n"Westbrook", 6.0);
  d.AddFactionEffect(n"Arasaka", -10.0, 5.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_SASQUATCH", 0, 60.0, 25.0, n"Pacifica", 6.0);
  d.AddFactionEffect(n"Animals", -30.0, 8.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_PSYCHO_ALL_PACIFIED", 0, 50.0, 0.0, n"", 0.0);
  d.AddFactionEffect(n"NCPD", 10.0, 5.0);
  d.AddTitle(n"T_PSYCHO_WHISPERER");
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_BRAT_CHAMP", 0, 50.0, 10.0, n"", 0.0);
  d.AddTitle(n"T_FIST");
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_BEAST_IN_ME", 0, 30.0, 0.0, n"", 0.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_PL_HANSEN", 0, 80.0, 25.0, n"Dogtown", 10.0);
  d.AddFactionEffect(n"Barghest", -50.0, 10.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_PL_CHIMERA", 0, 50.0, 15.0, n"Dogtown", 6.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_REL_JUDY", 0, 10.0, 0.0, n"", 0.0);
  d.AddFactionEffect(n"Mox", 15.0, 3.0);
  c.AddDeed(d);

  d = CBMakeDeed(n"DEED_REL_PANAM", 0, 20.0, 0.0, n"", 0.0);
  d.AddFactionEffect(n"Aldecaldos", 20.0, 4.0);
  c.AddDeed(d);
}
