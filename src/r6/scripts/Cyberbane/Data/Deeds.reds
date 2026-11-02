// Cyberbane - Deed catalogue seed (spec Appendix F)
//
// requiredState: 0 = Succeeded, 1 = Failed, 2 = Any-finished. The deed effects (Renown, Dread,
// faction standing, rumor, titles) have always been complete here; what was missing was anything
// to fire them. Generic gigs/hustles are handled by their own path (CBApplyHustle).
//
// `d.fact` is the game's own record that this happened, read with QuestsSystem.GetFact on the
// slow tick (Model/DeedEngine.reds, CBDeedFactTick). The convention is `<questid>_done` and is
// confirmed by the shipped scripts, which contain q005_done, q101_done, q201_done..q204_done,
// mq048_done, mq057_done, mq058_done, sq024_done and q001_ripperdoc_done.
//
// Only the ones whose exact fact name appears in the game's own source are wired. A wrong name
// reads 0 for ever and the deed simply never fires, so a guess cannot break anything - but it
// also cannot be told apart from the bug this is fixing, which is the whole reason the rest are
// left empty rather than filled in optimistically. To confirm the others: set Mod Settings >
// Cyberbane > Debug > Log level to Verbose, finish the job, and CBProbeDeedFacts prints the
// candidates and their values.
//
// Deliberately NOT guessed: DEED_PICKUP_DEAL and DEED_PICKUP_ROYCE are opposite endings of the
// same quest (q003), so a single `q003_done` would fire the wrong one half the time. Those two
// need the branch fact, not the quest fact.

public func CBSeedDeeds(c: ref<CyberbaneContent>) -> Void {
  let d: ref<CBDeedDef>;

  d = CBMakeDeed(n"DEED_HEIST", 0, 150.0, 40.0, n"CityCenter", 30.0);
  // Verified: cyberpunk/managers/rpgManager.script:2465 reads GetFact( gi, 'q005_done' ).
  d.fact = n"q005_done";
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
