// Cyberbane - Signal helpers (spec §7.5, §7.8)
//
// Small shared helpers for the signal hooks. All signatures compile-verified
// against Cyberpunk 2077 2.5.

// In-game time as Float game-seconds (spec §6.1). TimeSystem.GetGameTimeStamp()
// returns the in-game clock as a Float, which is exactly the unit Cyberbane stores.
// Which day of the playthrough this is, by the game's own calendar.
//
// GameTime.Days is exact and needs no interpretation, unlike GetGameTimeStamp, whose unit is
// still an open question. Anything paced "per day" uses this.
// Can the world clock be read yet?
//
// Right after a load the time system is not up, and every clock helper here answers 0 rather
// than failing. That is fine for a cooldown and ruinous for a timetable: a plan built at that
// moment is a plan for day 0 starting at midnight, and the real save was on day 87 in the
// afternoon. The log shows exactly that - "Day 0: timetable set" seconds before a load, then
// nothing from any lane until the day corrected itself five minutes later.
public func CBClockReady(game: GameInstance) -> Bool {
  return IsDefined(GameInstance.GetTimeSystem(game));
}

public func CBGameDay(game: GameInstance) -> Int32 {
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(ts) {
    return 0;
  }
  return GameTime.Days(ts.GetGameTime());
}

public func CBGameSeconds(game: GameInstance) -> Float {
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(ts) {
    return 0.0;
  }
  return ts.GetGameTimeStamp();
}

// Player Street Cred (spec §7.5), used as the Renown floor and in bootstrap.
public func CBPlayerStreetCred(game: GameInstance) -> Float {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return 0.0;
  }
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return 0.0;
  }
  return stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.StreetCred);
}

// Which life V started from (1.8.3): EnumInt(gamedataLifePath), or -1 when it cannot be read.
// It is saved with V and can never change inside a playthrough, which is what lets it tell two
// characters apart (CyberbaneSystem.VerifyPlaythroughOwner). The game's own getter answers
// Invalid when V's development data is not there yet (playerDevelopmentSystem.script).
public func CBPlayerLifePath(game: GameInstance) -> Int32 {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return -1;
  }
  let pds = CBGetSystem(game, n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
  if !IsDefined(pds) {
    return -1;
  }
  let lp = pds.GetLifePath(player);
  if Equals(lp, gamedataLifePath.Corporate) || Equals(lp, gamedataLifePath.Nomad)
     || Equals(lp, gamedataLifePath.StreetKid) {
    return EnumInt(lp);
  }
  return -1;
}

// Fetch a scriptable system by name, or null when the container is not there.
//
// The systems container is null during world transitions (loads, fast travel, Skip Time,
// braindance entry). Calling Get on a null container reads a null context and crashes, so
// every system lookup in the mod goes through this (crash safety).
public func CBGetSystem(game: GameInstance, name: CName) -> ref<ScriptableSystem> {
  let container = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return null;
  }
  return container.Get(name);
}

// Current Cyberbane district id (spec Appendix C), via PreventionSystem (S-06).
// The game may report a sub-district (e.g. Kabuki); CBMapGameDistrict folds those
// into the eight Cyberbane districts. Unknown names map to n"" (effects skipped).
public func CBCurrentDistrict(game: GameInstance) -> CName {
  let prev = CBGetSystem(game, n"PreventionSystem") as PreventionSystem;
  if !IsDefined(prev) {
    return n"";
  }
  let district = prev.GetCurrentDistrict();
  if !IsDefined(district) {
    return n"";
  }
  let rec = district.GetDistrictRecord();
  if !IsDefined(rec) {
    return n"";
  }
  return CBMapGameDistrict(rec.EnumName());
}

// District to attribute an event to, for code that runs outside the fast tick - a kill, a
// player death, the Hub. Prefers the district the tick already sampled, and only queries
// the Prevention system live when that cache is still empty and the world is settled, so
// these paths never drive a native world query mid-transition (crash safety).
public func CBEventDistrict(sys: ref<CyberbaneSystem>, game: GameInstance) -> CName {
  if IsDefined(sys) {
    let cached = sys.GetCurrentDistrict();
    if NotEquals(cached, n"") {
      return cached;
    }
  }
  if !CBWorldStable(game) {
    return n"";
  }
  return CBCurrentDistrict(game);
}

// Maps a game district/sub-district enum name to a Cyberbane district id.
// Exact game names are confirmed in spike S-06; this covers the common forms.
// District_Record.EnumName() returns a String.
public func CBMapGameDistrict(name: String) -> CName {
  // Lower-cased first, because the game does not spell its own districts one way. It is JapanTown
  // with a capital T, and both Vista_del_Rey and Vista_del_rey, and a case-sensitive "Japantown"
  // never matched: all of Japantown was no district at all, so nothing V did there counted, no gang
  // was on its own streets there and Westbrook only ever heard about half of itself. Checked by
  // running this over every value of gamedataDistrict. Morro Rock and the Langley clinic are the
  // only ones left out, and both are quest stages with no parent district.
  let n = StrLower(name);
  if StrContains(n, "kabuki") || StrContains(n, "northside") || StrContains(n, "littlechina")
     || StrContains(n, "watson") || StrContains(n, "arasakawaterfront") {
    return n"Watson";
  }
  if StrContains(n, "japantown") || StrContains(n, "charterhill") || StrContains(n, "northoak")
     || StrContains(n, "westbrook") {
    return n"Westbrook";
  }
  if StrContains(n, "downtown") || StrContains(n, "corpoplaza") || StrContains(n, "citycenter")
     || StrContains(n, "city_center") {
    return n"CityCenter";
  }
  if StrContains(n, "glen") || StrContains(n, "wellsprings") || StrContains(n, "vistadelrey")
     || StrContains(n, "vista_del_rey") || StrContains(n, "heywood") {
    return n"Heywood";
  }
  if StrContains(n, "arroyo") || StrContains(n, "rancho") || StrContains(n, "santo") {
    return n"SantoDomingo";
  }
  if StrContains(n, "coastview") || StrContains(n, "westwind") || StrContains(n, "pacifica") {
    return n"Pacifica";
  }
  if StrContains(n, "dogtown") || StrContains(n, "combat") {
    return n"Dogtown";
  }
  if StrContains(n, "badlands") || StrContains(n, "rockyridge") || StrContains(n, "redpeaks")
     || StrContains(n, "biotechnica") || StrContains(n, "lagunabend") {
    return n"Badlands";
  }
  return n"";
}
