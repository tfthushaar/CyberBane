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
  if Equals(id, n"Watson") { return "Watson"; }
  if Equals(id, n"Westbrook") { return "Westbrook"; }
  if Equals(id, n"CityCenter") { return "City Center"; }
  if Equals(id, n"Heywood") { return "Heywood"; }
  if Equals(id, n"SantoDomingo") { return "Santo Domingo"; }
  if Equals(id, n"Pacifica") { return "Pacifica"; }
  if Equals(id, n"Dogtown") { return "Dogtown"; }
  if Equals(id, n"Badlands") { return "the Badlands"; }
  return "";
}

public func CBFactionLabel(id: CName) -> String {
  if Equals(id, n"Maelstrom") { return "Maelstrom"; }
  if Equals(id, n"TygerClaws") { return "the Tyger Claws"; }
  if Equals(id, n"Valentinos") { return "the Valentinos"; }
  if Equals(id, n"SixthStreet") { return "6th Street"; }
  if Equals(id, n"Animals") { return "the Animals"; }
  if Equals(id, n"VoodooBoys") { return "the Voodoo Boys"; }
  if Equals(id, n"Scavengers") { return "the Scavs"; }
  if Equals(id, n"Mox") { return "the Mox"; }
  if Equals(id, n"Barghest") { return "Barghest"; }
  if Equals(id, n"Aldecaldos") { return "the Aldecaldos"; }
  if Equals(id, n"Arasaka") { return "Arasaka"; }
  if Equals(id, n"Militech") { return "Militech"; }
  if Equals(id, n"KangTao") { return "Kang Tao"; }
  if Equals(id, n"NCPD") { return "the NCPD"; }
  return "";
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

// The readable place or gang a parameterised title is about, or "" when nothing qualifies.
public func CBTitleToken(sys: ref<CyberbaneSystem>, id: CName) -> String {
  if Equals(id, n"T_BUTCHER_OF") { return CBTopDistrictLabel(sys, 0); }
  if Equals(id, n"T_GHOST_OF") { return CBTopDistrictLabel(sys, 1); }
  if Equals(id, n"T_DISTRICT_PROBLEM") { return CBTopDistrictLabel(sys, 2); }
  if Equals(id, n"T_MERC_FROM") { return CBTopDistrictLabel(sys, 2); }
  if Equals(id, n"T_FACTION_NIGHTMARE") { return CBTopFactionLabel(sys, false); }
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
  if Equals(def.id, n"T_BUTCHER_OF") { return "Butcher of " + token; }
  if Equals(def.id, n"T_GHOST_OF") { return "Ghost of " + token; }
  if Equals(def.id, n"T_DISTRICT_PROBLEM") { return token + "'s Problem"; }
  if Equals(def.id, n"T_MERC_FROM") { return "The Merc from " + token; }
  if Equals(def.id, n"T_FACTION_NIGHTMARE") { return token + "'s Nightmare"; }
  if Equals(def.id, n"T_FACTION_FRIEND") { return "Friend of " + token; }
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
