// Cyberbane - Title naming: the place or gang a title is actually about (spec Appendix G)
//
// Six titles are parameterised on a district or a faction. The seed table shipped the generic
// wording ("Butcher of the District") with a comment saying substitution would arrive with the
// Hub. The Hub arrived in 0.1.11; this did not, so players earned "Butcher of the District"
// while the readme advertised "Butcher of Watson". This is that substitution.
//
// The token is worked out from current state at display time rather than stored at unlock.
// That is deliberate: it needs no new persistent field and so no migration, it fixes saves
// that already hold these titles instead of leaving them stuck on the generic wording, and the
// district your name belongs to reads better as "where you do this" than as "where you first
// crossed a threshold".
//
// Iteration uses the same `for x in sys.GetXStates()` form the title conditions already use.
// The by-value copy stays alive for the loop, which is safe; the trap called out in
// CBTrimRumors is indexing a getter's result inside a single statement, which this never does.

public func CBDistrictLabel(id: CName) -> String {
  if Equals(id, n"Watson") { return CBT(n"Cyberbane-TitleNaming-Watson"); }
  if Equals(id, n"Westbrook") { return CBT(n"Cyberbane-TitleNaming-Westbrook"); }
  if Equals(id, n"CityCenter") { return CBT(n"Cyberbane-TitleNaming-CityCenter"); }
  if Equals(id, n"Heywood") { return CBT(n"Cyberbane-TitleNaming-Heywood"); }
  if Equals(id, n"SantoDomingo") { return CBT(n"Cyberbane-TitleNaming-SantoDomingo"); }
  if Equals(id, n"Pacifica") { return CBT(n"Cyberbane-TitleNaming-Pacifica"); }
  if Equals(id, n"Dogtown") { return CBT(n"Cyberbane-TitleNaming-Dogtown"); }
  if Equals(id, n"Badlands") { return CBT(n"Cyberbane-TitleNaming-TheBadlands"); }
  return "";
}

public func CBFactionLabel(id: CName) -> String {
  if Equals(id, n"Maelstrom") { return CBT(n"Cyberbane-TitleNaming-Maelstrom"); }
  if Equals(id, n"TygerClaws") { return CBT(n"Cyberbane-TitleNaming-TheTygerClaws"); }
  if Equals(id, n"Valentinos") { return CBT(n"Cyberbane-TitleNaming-TheValentinos"); }
  if Equals(id, n"SixthStreet") { return CBT(n"Cyberbane-TitleNaming-6thStreet"); }
  if Equals(id, n"Animals") { return CBT(n"Cyberbane-TitleNaming-TheAnimals"); }
  if Equals(id, n"VoodooBoys") { return CBT(n"Cyberbane-TitleNaming-TheVoodooBoys"); }
  if Equals(id, n"Scavengers") { return CBT(n"Cyberbane-TitleNaming-TheScavs"); }
  if Equals(id, n"Mox") { return CBT(n"Cyberbane-TitleNaming-TheMox"); }
  if Equals(id, n"Barghest") { return CBT(n"Cyberbane-TitleNaming-Barghest"); }
  if Equals(id, n"Scrappers") { return CBT(n"Cyberbane-TitleNaming-TheScrappers"); }
  if Equals(id, n"Aldecaldos") { return CBT(n"Cyberbane-TitleNaming-TheAldecaldos"); }
  if Equals(id, n"Wraiths") { return CBT(n"Cyberbane-TitleNaming-TheWraiths"); }
  if Equals(id, n"Arasaka") { return CBT(n"Cyberbane-TitleNaming-Arasaka"); }
  if Equals(id, n"Militech") { return CBT(n"Cyberbane-TitleNaming-Militech"); }
  if Equals(id, n"KangTao") { return CBT(n"Cyberbane-TitleNaming-KangTao"); }
  if Equals(id, n"NCPD") { return CBT(n"Cyberbane-TitleNaming-TheNCPD"); }
  if Equals(id, n"MaxTac") { return CBT(n"Cyberbane-TitleNaming-MaxTac"); }
  return "";
}

// A gang's name on its own, with no article: a phone contact, a bar over a head (2.7.1). Said where a stripped label used to
// be ("the Tyger Claws" less "the "), which only works in English.
public func CBFactionName(id: CName) -> String {
  if Equals(id, n"Maelstrom") { return CBT(n"Cyberbane-TitleNaming-Maelstrom"); }
  if Equals(id, n"TygerClaws") { return CBT(n"Cyberbane-TitleNaming-TygerClaws"); }
  if Equals(id, n"Valentinos") { return CBT(n"Cyberbane-TitleNaming-Valentinos"); }
  if Equals(id, n"SixthStreet") { return CBT(n"Cyberbane-TitleNaming-6thStreet"); }
  if Equals(id, n"Animals") { return CBT(n"Cyberbane-TitleNaming-Animals"); }
  if Equals(id, n"VoodooBoys") { return CBT(n"Cyberbane-TitleNaming-VoodooBoys"); }
  if Equals(id, n"Scavengers") { return CBT(n"Cyberbane-TitleNaming-Scavs"); }
  if Equals(id, n"Mox") { return CBT(n"Cyberbane-TitleNaming-Mox"); }
  if Equals(id, n"Barghest") { return CBT(n"Cyberbane-TitleNaming-Barghest"); }
  if Equals(id, n"Scrappers") { return CBT(n"Cyberbane-TitleNaming-Scrappers"); }
  if Equals(id, n"Aldecaldos") { return CBT(n"Cyberbane-TitleNaming-Aldecaldos"); }
  if Equals(id, n"Wraiths") { return CBT(n"Cyberbane-TitleNaming-Wraiths"); }
  if Equals(id, n"Arasaka") { return CBT(n"Cyberbane-TitleNaming-Arasaka"); }
  if Equals(id, n"Militech") { return CBT(n"Cyberbane-TitleNaming-Militech"); }
  if Equals(id, n"KangTao") { return CBT(n"Cyberbane-TitleNaming-KangTao"); }
  if Equals(id, n"NCPD") { return CBT(n"Cyberbane-TitleNaming-NCPD"); }
  if Equals(id, n"MaxTac") { return CBT(n"Cyberbane-TitleNaming-MaxTac"); }
  return "";
}

// The same, to start a sentence with: "the Tyger Claws" opens with a small letter.
//
// Only a plain a to z is raised (2.7.1). A translation can start a line with a letter the game writes in more than one byte
// (é, ü, д, あ), and taking the first one alone would cut it in half and garble the line; such a line is left as written,
// which a translator can capitalise in the text itself.
public func CBCapFirst(s: String) -> String {
  if StrLen(s) == 0 {
    return s;
  }
  let first = StrMid(s, 0, 1);
  if !StrContains("abcdefghijklmnopqrstuvwxyz", first) {
    return s;
  }
  return StrUpper(first) + StrMid(s, 1, StrLen(s) - 1);
}

// "Maelstrom's", "the Mox's", "the Tyger Claws'". Every label here that ends in an s is a plural.
public func CBPossessive(s: String) -> String {
  if StrLen(s) == 0 {
    return s;
  }
  return StrEndsWith(s, "s") ? s + "'" : CBTf(n"Cyberbane-TitleNaming-S", [s]);
}

// mode 0 = most lethal/brutal work (Butcher), 1 = most quiet work (Ghost), 2 = best known.
func CBTopDistrictLabel(sys: ref<CyberbaneSystem>, mode: Int32) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let bestLabel = "";
  let best = 0.0;
  for ds in sys.GetDistrictStates() {
    if IsDefined(ds) {
      let label = CBDistrictLabel(ds.id);
      if NotEquals(label, "") {
        let v = ds.renown;
        if mode == 0 {
          v = Cast<Float>(ds.lethalOrBrutal);
        }
        if mode == 1 {
          v = Cast<Float>(ds.quietTakedowns);
        }
        // Strictly greater than zero: a district you have never touched never names you.
        if v > best {
          best = v;
          bestLabel = label;
        }
      }
    }
  }
  return bestLabel;
}

// friendly = the gang that likes you most; otherwise the one that hates you most.
func CBTopFactionLabel(sys: ref<CyberbaneSystem>, friendly: Bool) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let bestLabel = "";
  let best = 0.0;
  let seen = false;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) {
      let label = CBFactionLabel(fs.id);
      if NotEquals(label, "") {
        let better = false;
        if !seen {
          better = true;
        } else {
          if friendly {
            better = fs.standing > best;
          } else {
            better = fs.standing < best;
          }
        }
        if better {
          seen = true;
          best = fs.standing;
          bestLabel = label;
        }
      }
    }
  }
  return bestLabel;
}

// The gang a Nightmare title is about: the one that earned it (75 of theirs down, fearing V at TitleFearNeeded), the
// most of theirs down first; before any does, the gang V has put the most of down. It named the gang with the worst
// standing, which need not be the one the title was earned on.
func CBNightmareGangLabel(sys: ref<CyberbaneSystem>) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let score = sys.GetScore();
  let earned = n"";
  let earnedKills = 0;
  let most = n"";
  let mostKills = 0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && StrLen(CBFactionLabel(fs.id)) > 0 {
      if fs.kills > mostKills {
        most = fs.id;
        mostKills = fs.kills;
      }
      if fs.kills >= 75 && fs.kills > earnedKills && IsDefined(score)
         && score.GetFactionFear(fs.id) >= CBConfig.TitleFearNeeded() {
        earned = fs.id;
        earnedKills = fs.kills;
      }
    }
  }
  return CBFactionLabel(NotEquals(earned, n"") ? earned : most);
}

// The readable place or gang a parameterised title is about, or "" when nothing qualifies.
public func CBTitleToken(sys: ref<CyberbaneSystem>, id: CName) -> String {
  if Equals(id, n"T_BUTCHER_OF") { return CBTopDistrictLabel(sys, 0); }
  if Equals(id, n"T_GHOST_OF") { return CBTopDistrictLabel(sys, 1); }
  if Equals(id, n"T_DISTRICT_PROBLEM") { return CBTopDistrictLabel(sys, 2); }
  if Equals(id, n"T_MERC_FROM") { return CBTopDistrictLabel(sys, 2); }
  if Equals(id, n"T_FACTION_NIGHTMARE") { return CBNightmareGangLabel(sys); }
  if Equals(id, n"T_FACTION_FRIEND") { return CBTopFactionLabel(sys, true); }
  return "";
}

// A title's name with the place or gang filled in. Falls back to the table's own generic
// wording when there is nothing to fill it with, so a half-built string can never show.
public func CBTitleDisplay(sys: ref<CyberbaneSystem>, def: ref<CBTitleDef>) -> String {
  if !IsDefined(def) {
    return "";
  }
  let token = CBTitleToken(sys, def.id);
  if Equals(token, "") {
    return def.display;
  }
  if Equals(def.id, n"T_BUTCHER_OF") { return CBTf(n"Cyberbane-TitleNaming-ButcherOf", [token]); }
  if Equals(def.id, n"T_GHOST_OF") { return CBTf(n"Cyberbane-TitleNaming-GhostOf", [token]); }
  if Equals(def.id, n"T_DISTRICT_PROBLEM") { return CBTf(n"Cyberbane-TitleNaming-Problem", [CBCapFirst(CBPossessive(token))]); }
  if Equals(def.id, n"T_MERC_FROM") { return CBTf(n"Cyberbane-TitleNaming-TheMercFrom", [token]); }
  if Equals(def.id, n"T_FACTION_NIGHTMARE") { return CBTf(n"Cyberbane-TitleNaming-Nightmare", [CBCapFirst(CBPossessive(token))]); }
  if Equals(def.id, n"T_FACTION_FRIEND") { return CBTf(n"Cyberbane-TitleNaming-FriendOf", [token]); }
  return def.display;
}

// For the display sites that only hold the id.
public func CBTitleDisplayById(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, id: CName) -> String {
  if !IsDefined(content) {
    return NameToString(id);
  }
  let def = content.GetTitle(id);
  if !IsDefined(def) {
    return NameToString(id);
  }
  return CBTitleDisplay(sys, def);
}
