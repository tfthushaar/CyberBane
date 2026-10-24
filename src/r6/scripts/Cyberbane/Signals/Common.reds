// Cyberbane — Signal helpers (spec §7.5, §7.8)
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

// Current Cyberbane district id (spec Appendix C). Placeholder pending S-06.
public func CBCurrentDistrict(game: GameInstance) -> CName {
  return n"";
}
