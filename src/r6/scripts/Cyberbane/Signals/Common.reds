// Cyberbane - Signal helpers (spec §7.5, §7.8)
//
// Small shared helpers for the signal hooks. All signatures compile-verified
// against Cyberpunk 2077 2.31.

// In-game time as Float game-seconds (spec §6.1). TimeSystem.GetGameTimeStamp()
// returns the in-game clock as a Float, which is exactly the unit Cyberbane stores.
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

// Current Cyberbane district id (spec Appendix C), via PreventionSystem (S-06).
// The game may report a sub-district (e.g. Kabuki); CBMapGameDistrict folds those
// into the eight Cyberbane districts. Unknown names map to n"" (effects skipped).
public func CBCurrentDistrict(game: GameInstance) -> CName {
  let prev = GameInstance.GetScriptableSystemsContainer(game).Get(n"PreventionSystem") as PreventionSystem;
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
