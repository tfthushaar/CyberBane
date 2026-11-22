// Cyberbane - Faction registry seed (spec Appendix B)
//
// Flavour values to tune in playtest. `affiliations` (the game's gamedataAffiliation
// record names that map to each faction) are filled in during spike S-01; the
// strings below are the expected names and are safe to leave until then.
// chromeAttitude < 0 means chrome earns respect (Maelstrom).

// Does this faction go to war with V the way a gang does?
//
// The law does not. It has its own escalation already - heat, stars, and MaxTac at the top -
// and Cyberbane has no business bolting a second one onto it.
//
// `isGang` could not answer this: it only ever decided whether a faction pays tribute, so the
// NCPD were eligible for crews, apex squads and car chases like any gang. Killing police
// drives their standing down the same as killing Maelstrom, so a player who had been fighting
// the law found police turning up to pick fights and ramming them in the street with no stars
// showing, which is exactly the report. Those chases go out through the game's own police
// pursuit call, so they behave like a pursuit while the heat system knows nothing about them.
//
// Corps stay in. Arasaka and Militech sending a squad after V is intended, and they are not
// the law.
//
// Nor does a faction the player has switched off under Factions in Mod Settings (1.9.1). This is the
// test every crew, apex squad, scout, lookout, patrol, provocation, bounty and gang text already asks,
// so the switch reaches all of them from here.
public func CBFactionFieldsSquads(faction: CName) -> Bool {
  return NotEquals(faction, n"NCPD")
      && NotEquals(faction, n"Police")
      && NotEquals(faction, n"MaxTac")
      && CBFactionOn(faction);
}

// Does Cyberbane treat this faction as having an opinion of V at all (1.9.1)?
//
// "Is there an option to turn off the Barghest and NCPD as gangs entirely? I'm infamous in NC and
// almost every cop and Barghest will slowly get sus of me and eventually combat." One switch per
// faction, under Factions in Mod Settings. Off, and Cyberbane leaves that faction alone: no posture
// towards V (CBScoreEngine.GetPosture reads Neutral), so nobody of theirs is turned on V on sight or
// warns V off, no crews or apex squads (CBFactionFieldsSquads), no Rivals made or sent, no tribute, no
// texts. Kills still count towards V's reputation and their standing is still kept, so switching them
// back on picks up where it was. Hostility the game or another mod sets is theirs, not this switch's.
//
// Read per NPC by the Director, so it is a settings read and a few name comparisons, nothing more.
public func CBFactionOn(faction: CName) -> Bool {
  if Equals(faction, n"") {
    return true;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return true;
  }
  return rt.GetSettings().FactionOn(faction);
}

// How a gang treats V by hand, under How gangs see you in Mod Settings (2.1.0): 0 as earned in play, else
// 1 Allied, 2 Friendly, 3 Neutral, 4 Hostile, 5 Vendetta. Only gangs have one.
public func CBGangView(faction: CName) -> Int32 {
  if Equals(faction, n"") {
    return 0;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return 0;
  }
  return rt.GetSettings().GangView(faction);
}

public func CBGangViewSet(faction: CName) -> Bool {
  return CBGangView(faction) != 0;
}

// Set by hand to come for V: Hostile or Vendetta (2.1.0). A stance chosen in Mod Settings is the gang knowing
// exactly who V is, which is what the player asked for ("everyone having a Vendetta against us"): their people
// know V's face (CBRecognizes), and they send crews without first having to hear of V (CBLanePick,
// CBEnsureHuntingGangs). Earned in play asks none of this and goes by what V has done, as it always has.
public func CBGangViewHunts(faction: CName) -> Bool {
  let view = CBGangView(faction);
  return view == 4 || view == 5;
}

// Set by hand to Vendetta: their best come on their own too, inside How often they come (CBApexEligible).
public func CBGangViewVendetta(faction: CName) -> Bool {
  return CBGangView(faction) == 5;
}

// The standing a gang acts on (2.1.0). The one question for what a gang does about V: its posture
// (CBScoreEngine.GetStanding and GetPosture), who sends crews and how many (Spawn/Queue.reds), tribute, and
// the price of peace. A player asked to set how the gangs see V by hand, and a stance only on the posture
// would have argued with all of those: a gang set to Vendetta with V in its good books was never picked to
// send anybody, because who sends is weighed by how far below zero the standing is.
//
// Set by hand, the standing V earned is kept when it already lies in the stance chosen (a gang that already
// hates V keeps all of it, and sends the bigger crews that go with it), and is otherwise the middle of that
// stance. What V earns is never written over: it keeps counting, and is what comes back on Earned in play.
// What earns standing (rewards, decay, titles) reads the earned figure, CBFactionState.standing, directly.
//
// With They Will Remember deciding who is hostile (2.4.2; compatibility on, and it tracks the gang), its answer
// is the line between hostile and not: hostile there is hostile here (V's earned standing kept if it is
// already in the hostile band or below, the middle of the band if not), and not hostile there is at worst
// neutral here (friendlier standing V earned is kept, since it keeps no such thing). Until 2.4.2 only the
// Gangs screen asked it, so the rest of Cyberbane went by its own standing and a gang could be hostile in one
// mod and not the other. A stance set by hand still comes first: it is the player's own word on that gang.
public func CBActingStanding(faction: CName, earned: Float) -> Float {
  let view = CBGangView(faction);
  let allied = CBConfig.PostureAllied();
  let friendly = CBConfig.PostureFriendly();
  let hostile = CBConfig.PostureHostile();
  let vendetta = CBConfig.PostureVendetta();
  if view == 0 {
    if CBTwrOwnsHostility(faction) {
      let says = CBTwrGangHostile(GetGameInstance(), faction);
      // It could not be asked (2.5.1): what its people do is the next best answer. Hostile on sight lately, by any
      // hand but Cyberbane's (which stands down from hostility under compatibility), is hostile here.
      if says < 0 {
        let sysSeen = CyberbaneSystem.Get(GetGameInstance());
        if IsDefined(sysSeen) && sysSeen.SeenHostileRecently(faction) {
          says = 1;
        }
      }
      if says == 1 {
        return earned <= hostile ? earned : (vendetta + hostile) / 2.0;
      }
      if says == 0 {
        return earned > hostile ? earned : 0.0;
      }
    }
    return earned;
  }
  if view == 1 {
    return earned >= allied ? earned : (allied + 100.0) / 2.0;
  }
  if view == 2 {
    return earned >= friendly && earned < allied ? earned : (friendly + allied) / 2.0;
  }
  if view == 3 {
    return earned > hostile && earned < friendly ? earned : 0.0;
  }
  if view == 4 {
    return earned > vendetta && earned <= hostile ? earned : (vendetta + hostile) / 2.0;
  }
  return earned <= vendetta ? earned : (vendetta - 100.0) / 2.0;
}

public func CBSeedFactions(c: ref<CyberbaneContent>) -> Void {
  let f: ref<CBFactionProfile>;

  // id, baseline, courageMod, dreadSens, chromeAttitude, isGang, canBeBought, displayKey
  f = CBMakeFaction(n"TygerClaws", 0.0, 0.05, 1.0, 0.2, true, true, "Cyberbane-Faction-TygerClaws");
  f.affiliations = [n"TygerClaws"];
  f.SetRespect(ECBArchetype.Ghost, 0.3);
  f.SetRespect(ECBArchetype.Brawler, 0.3);
  f.rivalFactions = [n"Mox", n"Valentinos", n"Maelstrom"];
  f.turf = [n"Westbrook", n"Watson"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Maelstrom", 0.0, 0.10, 0.8, -1.0, true, true, "Cyberbane-Faction-Maelstrom");
  f.affiliations = [n"Maelstrom"];
  f.SetRespect(ECBArchetype.Chromed, 0.6);
  f.SetRespect(ECBArchetype.Butcher, 0.3);
  f.rivalFactions = [n"TygerClaws", n"Scavengers"];
  f.turf = [n"Watson"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Valentinos", 0.0, 0.05, 1.0, 0.2, true, true, "Cyberbane-Faction-Valentinos");
  f.affiliations = [n"Valentinos"];
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.SetRespect(ECBArchetype.Brawler, 0.3);
  f.rivalFactions = [n"SixthStreet", n"TygerClaws", n"Scavengers"];
  f.turf = [n"Heywood"];
  c.AddFaction(f);

  f = CBMakeFaction(n"SixthStreet", 0.0, 0.0, 1.0, 0.0, true, true, "Cyberbane-Faction-SixthStreet");
  f.affiliations = [n"SixthStreet"];
  f.SetRespect(ECBArchetype.Professional, 0.4);
  f.rivalFactions = [n"Valentinos", n"Scavengers"];
  f.turf = [n"SantoDomingo"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Animals", 0.0, 0.15, 0.8, 0.0, true, true, "Cyberbane-Faction-Animals");
  f.affiliations = [n"Animals"];
  f.SetRespect(ECBArchetype.Brawler, 0.6);
  f.rivalFactions = [n"VoodooBoys", n"Barghest"];
  f.turf = [n"Pacifica"];
  c.AddFaction(f);

  f = CBMakeFaction(n"VoodooBoys", 0.0, 0.0, 1.0, 0.0, true, true, "Cyberbane-Faction-VoodooBoys");
  f.affiliations = [n"VoodooBoys"];
  f.SetRespect(ECBArchetype.Netrunner, 0.6);
  f.rivalFactions = [n"Animals", n"Barghest"];
  f.turf = [n"Pacifica"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Scavengers", -10.0, -0.10, 1.3, 0.4, true, true, "Cyberbane-Faction-Scavengers");
  f.affiliations = [n"Scavengers"];
  // Everybody's enemy: they harvest people, and every crew that has a neighbourhood to protect
  // has lost somebody to them.
  f.rivalFactions = [n"Valentinos", n"Maelstrom", n"Mox", n"SixthStreet"];
  f.turf = [n"Watson"];
  f.turfClaim = 0.3;   // they harvest people out of the ruins; they have never run a district (2.7.0)
  c.AddFaction(f);

  f = CBMakeFaction(n"Mox", 5.0, -0.05, 1.1, 0.2, true, true, "Cyberbane-Faction-Mox");
  // TheMox is the game's name for them (factions.tweak). This said Mox and nothing else, so nobody
  // in the game was ever one of the Mox: not a kill, not a Rival, not a witness.
  f.affiliations = [n"TheMox", n"Mox"];
  f.SetRespect(ECBArchetype.Ghost, 0.3);
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.rivalFactions = [n"TygerClaws", n"Scavengers"];
  f.turf = [n"Watson", n"Westbrook"];
  // They protect their own blocks of Kabuki and the people who work them; they run a district only once everybody else in
  // it has been bled white (2.7.0). "The Mox control Watson."
  f.turfClaim = 0.3;
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
  f.rivalFactions = [n"Militech", n"Animals", n"VoodooBoys", n"Scrappers"];
  f.turf = [n"Dogtown"];
  c.AddFaction(f);

  // Corporations cannot be bought (spec §11.4).
  f = CBMakeFaction(n"Arasaka", 0.0, 0.05, 0.8, 0.1, false, false, "Cyberbane-Faction-Arasaka");
  f.affiliations = [n"Arasaka"];
  f.SetRespect(ECBArchetype.Professional, 0.2);
  f.rivalFactions = [n"Militech", n"KangTao"];
  f.turf = [n"CityCenter", n"Watson"];
  c.AddFaction(f);

  f = CBMakeFaction(n"Militech", 0.0, 0.05, 0.8, 0.0, false, false, "Cyberbane-Faction-Militech");
  f.affiliations = [n"Militech"];
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.rivalFactions = [n"Arasaka", n"Barghest"];
  f.turf = [n"CityCenter", n"Badlands"];
  c.AddFaction(f);

  f = CBMakeFaction(n"KangTao", 0.0, 0.0, 0.9, 0.0, false, false, "Cyberbane-Faction-KangTao");
  f.affiliations = [n"KangTao"];
  f.rivalFactions = [n"Arasaka"];
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

  // Dogtown's Scrappers (2.6.4): the people who live off what the war leaves lying in the ruins. A player met them and
  // asked who they were: "they looked like Voodoo Boys... they didn't have Scav masks nor did they look like Barghest
  // soldiers". The game files every one of them Factions.Unaffiliated, so Cyberbane had never known them from a passer-by:
  // their kills counted for nobody, they made no Rivals and sent nobody. They are known by the game's attitude group for
  // them instead. Last in the list, so every gang before them keeps its place (the turf drift is seeded by it).
  f = CBMakeFaction(n"Scrappers", -5.0, -0.05, 1.2, 0.0, true, true, "Cyberbane-Faction-Scrappers");
  f.attitudeGroups = [n"scrappers"];
  f.SetRespect(ECBArchetype.Ghost, 0.3);
  f.SetRespect(ECBArchetype.Professional, 0.2);
  f.rivalFactions = [n"Barghest", n"Scavengers"];
  f.turf = [n"Dogtown"];
  f.turfHold = 0.55;   // Barghest's Dogtown; the Scrappers hold it only when Barghest has been bled white
  c.AddFaction(f);
}
