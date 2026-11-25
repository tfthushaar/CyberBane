// Cyberbane - Signal helpers (spec §7.5, §7.8)
//
// Small shared helpers for the signal hooks. All signatures compile-verified
// against Cyberpunk 2077 2.5.

// Can the world clock be read yet?
public func CBClockReady(game: GameInstance) -> Bool {
  return IsDefined(GameInstance.GetTimeSystem(game));
}

// Which day of the playthrough this is, by the game's calendar. GameTime.Days is exact and needs no interpretation;
// anything paced "per day" uses this.
public func CBGameDay(game: GameInstance) -> Int32 {
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(ts) {
    return 0;
  }
  return GameTime.Days(ts.GetGameTime());
}

// In-game time as Float game-seconds (spec §6.1). TimeSystem.GetGameTimeStamp returns the in-game clock as a Float,
// which is exactly the unit Cyberbane stores.
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

// How far V's name carries yet, 0 to 1, by the game's Street Cred: 0 for a merc new to the street, 1 from
// StandingFullCred (about the Heist) on.
public func CBMercStanding(game: GameInstance) -> Float {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().earlyGrace {
    return 1.0;
  }
  return ClampF(CBPlayerStreetCred(game) / CBConfig.StandingFullCred(), 0.0, 1.0);
}

// A share at Street Cred 0 that eases to the whole of it as V becomes known.
public func CBStandingScale(game: GameInstance, share: Float) -> Float {
  return share + (1.0 - share) * CBMercStanding(game);
}

// No gang sends its best after a merc it has barely heard of. False with "Before you're known" off.
public func CBTooUnknownForApex(game: GameInstance) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().earlyGrace {
    return false;
  }
  return CBPlayerStreetCred(game) < CBConfig.ApexMinStreetCred();
}

// Which life V started from: EnumInt(gamedataLifePath), or -1 when it cannot be read.
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
public func CBGetSystem(game: GameInstance, name: CName) -> ref<ScriptableSystem> {
  let container = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return null;
  }
  return container.Get(name);
}

// Current Cyberbane district id (spec Appendix C), via PreventionSystem (S-06). The game may report a sub-district
// (e.g. Kabuki); CBMapGameDistrict folds those into the eight Cyberbane districts.
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

// Prefers the district the tick already sampled, and only queries the Prevention system live when that cache is still
// empty and the world is settled, so these paths never drive a native world query mid-transition (crash safety).
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

// Maps a game district/sub-district enum name to a Cyberbane district id. Exact game names are confirmed in spike S-06;
// this covers the common forms. District_Record.EnumName returns a String.
public func CBMapGameDistrict(name: String) -> CName {
  // Lower-cased first, because the game does not spell its own districts one way.
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
