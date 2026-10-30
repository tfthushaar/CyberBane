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
public func CBMapGameDistrict(n: String) -> CName {
  if StrContains(n, "Kabuki") || StrContains(n, "Northside") || StrContains(n, "LittleChina")
     || StrContains(n, "Watson") || StrContains(n, "ArasakaWaterfront") {
    return n"Watson";
  }
  if StrContains(n, "Japantown") || StrContains(n, "CharterHill") || StrContains(n, "NorthOak")
     || StrContains(n, "Westbrook") {
    return n"Westbrook";
  }
  if StrContains(n, "Downtown") || StrContains(n, "CorpoPlaza") || StrContains(n, "CityCenter")
     || StrContains(n, "City_Center") {
    return n"CityCenter";
  }
  if StrContains(n, "Glen") || StrContains(n, "Wellsprings") || StrContains(n, "VistaDelRey")
     || StrContains(n, "Heywood") {
    return n"Heywood";
  }
  if StrContains(n, "Arroyo") || StrContains(n, "Rancho") || StrContains(n, "SantoDomingo")
     || StrContains(n, "Santo") {
    return n"SantoDomingo";
  }
  if StrContains(n, "Coastview") || StrContains(n, "WestWind") || StrContains(n, "Pacifica") {
    return n"Pacifica";
  }
  if StrContains(n, "Dogtown") || StrContains(n, "Combat") {
    return n"Dogtown";
  }
  if StrContains(n, "Badlands") || StrContains(n, "RockyRidge") || StrContains(n, "RedPeaks")
     || StrContains(n, "Biotechnica") {
    return n"Badlands";
  }
  return n"";
}
