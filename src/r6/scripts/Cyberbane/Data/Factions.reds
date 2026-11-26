// Cyberbane - Faction registry seed (spec Appendix B)
//
// Flavour values to tune in playtest. `affiliations` (the game's gamedataAffiliation
// record names that map to each faction) are filled in during spike S-01; the
// strings below are the expected names and are safe to leave until then.
// chromeAttitude < 0 means chrome earns respect (Maelstrom).

// Does this faction go to war with V the way a gang does?
public func CBFactionFieldsSquads(faction: CName) -> Bool {
  // V's crew holding a district (Model/CrewTurf.reds) is no gang that fields people: nothing that sends a district
  // holder's people (a bagman, a patrol, a street clash, an event) may ask for the crew's.
  if CBIsCrewTurf(faction) {
    return false;
  }
  let content = CyberbaneContent.Get();
  let p = IsDefined(content) && NotEquals(faction, n"") ? content.GetFaction(faction) : null;
  if IsDefined(p) {
    return p.fieldsSquads && CBFactionOn(faction);
  }
  return NotEquals(faction, n"NCPD")
      && NotEquals(faction, n"Police")
      && NotEquals(faction, n"MaxTac")
      && CBFactionOn(faction);
}

// Does Cyberbane treat this faction as having an opinion of V at all?
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

// How a gang treats V by hand, under How gangs see you in Mod Settings: 0 as earned in play, else 1 Allied, 2 Friendly,
// 3 Neutral, 4 Hostile, 5 Vendetta. Only gangs have one.
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

// Set by hand to come for V: Hostile or Vendetta.
public func CBGangViewHunts(faction: CName) -> Bool {
  let view = CBGangView(faction);
  return view == 4 || view == 5;
}

// Set by hand to Vendetta: their best come on their own too, inside How often they come (CBApexEligible).
public func CBGangViewVendetta(faction: CName) -> Bool {
  return CBGangView(faction) == 5;
}

// The standing a gang acts on. The one question for what a gang does about V: its posture (CBScoreEngine.GetStanding
// and GetPosture), who sends crews and how many (Spawn/Queue.reds), tribute, and the price of peace.
public func CBActingStanding(faction: CName, earned: Float) -> Float {
  let view = CBGangView(faction);
  let allied = CBConfig.PostureAllied();
  let friendly = CBConfig.PostureFriendly();
  let hostile = CBConfig.PostureHostile();
  let vendetta = CBConfig.PostureVendetta();
  if view == 0 {
    // An add-on's layers (API level 3, AddPostureLayer) move how they act, never what V earned with them.
    let layered = earned + CBApiPostureLayers(faction);
    if CBTwrOwnsHostility(faction) {
      let says = CBTwrGangHostile(GetGameInstance(), faction);
      // It could not be asked: what its people do is the next best answer. Hostile on sight lately, by any hand but
      // Cyberbane's (which stands down from hostility under compatibility), is hostile here.
      if says < 0 {
        let sysSeen = CyberbaneSystem.Get(GetGameInstance());
        if IsDefined(sysSeen) && sysSeen.SeenHostileRecently(faction) {
          says = 1;
        }
      }
      if says == 1 {
        return layered <= hostile ? layered : (vendetta + hostile) / 2.0;
      }
      if says == 0 {
        return layered > hostile ? layered : 0.0;
      }
    }
    return ClampF(layered, -100.0, 100.0);
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
  // Everybody's enemy: they harvest people, and every crew that has a neighbourhood to protect has lost somebody to
  // them.
  f.rivalFactions = [n"Valentinos", n"Maelstrom", n"Mox", n"SixthStreet", n"Scrappers"];
  f.turf = [n"Watson"];
  f.turfClaim = 0.3;   // they harvest people out of the ruins; they have never run a district
  c.AddFaction(f);

  f = CBMakeFaction(n"Mox", 5.0, -0.05, 1.1, 0.2, true, true, "Cyberbane-Faction-Mox");
  // TheMox is the game's name for them (factions.tweak). This said Mox and nothing else, so nobody
  // in the game was ever one of the Mox: not a kill, not a Rival, not a witness.
  f.affiliations = [n"TheMox", n"Mox"];
  f.SetRespect(ECBArchetype.Ghost, 0.3);
  f.SetRespect(ECBArchetype.Professional, 0.3);
  f.rivalFactions = [n"TygerClaws", n"Scavengers"];
  f.turf = [n"Watson", n"Westbrook"];
  // They protect their own blocks of Kabuki and the people who work them; they run a district only once everybody else
  // in it has been bled white.
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

  // Dogtown's Scrappers: the people who live off what the war leaves lying in the ruins.
  f = CBMakeFaction(n"Scrappers", -5.0, -0.05, 1.2, 0.0, true, true, "Cyberbane-Faction-Scrappers");
  f.attitudeGroups = [n"scrappers"];
  f.SetRespect(ECBArchetype.Ghost, 0.3);
  f.SetRespect(ECBArchetype.Professional, 0.2);
  f.rivalFactions = [n"Barghest", n"Scavengers"];
  f.turf = [n"Dogtown"];
  f.turfHold = 0.55;   // Barghest's Dogtown; the Scrappers hold it only when Barghest has been bled white
  c.AddFaction(f);
}
