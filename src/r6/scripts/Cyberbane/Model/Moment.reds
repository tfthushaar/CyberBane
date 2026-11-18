// Cyberbane - The moment ([3], [4], [5], 2.3.1)
//
// What the street can see about right now, on top of what it knows about V: the hour and the rain,
// whether V is bleeding, whether V has just come out of a fight. One reader for each, asked by the systems
// that already make each decision, so the crowd, recognition, witnesses, the nerve of a ganger and the
// lines all agree about the same moment:
//
//   night and rain   harder to see a face (recognition) and fewer eyes on a kill (witnesses); the rain also
//                    shortens hunters' and scouts' sight (CBHuntSenseScale), which already counted the dark
//   V wounded        the crowd sees the blood and backs off; a ganger sees a chance and holds less
//   fresh from it    the crowd keeps its distance; the lines say what everybody can see
//
// Off (Mod Settings, The crowd: "Night, rain and blood"), every reader answers as if it were midday, dry,
// and V had not been in a fight, which is how everything behaved before 2.3.1. The night is the lanes' own
// (CBIsNight, Spawn/Queue.reds), so crews by night and the hunt's sense of the dark are never touched by it.

public func CBMomentOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().streetReadsMoment;
}

// The lanes' night, for what the street reads into it.
public func CBMomentNight(game: GameInstance) -> Bool {
  return CBMomentOn() && CBIsNight(game);
}

// 0 dry, 1 light rain, 2 heavy rain. The weather system is the game's own read (WeatherSystem, the same one
// the time-skip screen asks), never anybody's puppet.
public func CBRainLevel(game: GameInstance) -> Int32 {
  if !CBMomentOn() {
    return 0;
  }
  let ws = GameInstance.GetWeatherSystem(game);
  if !IsDefined(ws) {
    return 0;
  }
  let t = ws.GetRainIntensityType();
  if Equals(t, worldRainIntensity.HeavyRain) {
    return 2;
  }
  if Equals(t, worldRainIntensity.LightRain) {
    return 1;
  }
  return 0;
}

// How well a face can be made out right now, as a share: night and rain each take some off.
public func CBSightMult(game: GameInstance) -> Float {
  if !CBMomentOn() {
    return 1.0;
  }
  let m = CBRainSightMult(game);
  if CBMomentNight(game) {
    m *= CBConfig.NightSight();
  }
  return m;
}

// The rain's share alone, for the hunt, whose sense already counts the dark.
public func CBRainSightMult(game: GameInstance) -> Float {
  let rain = CBRainLevel(game);
  if rain == 2 {
    return CBConfig.HeavyRainSight();
  }
  return rain == 1 ? CBConfig.LightRainSight() : 1.0;
}

// V's health as a share of the pool, under the line where it shows.
public func CBVWounded(game: GameInstance) -> Bool {
  if !CBMomentOn() {
    return false;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsDead() {
    return false;
  }
  let hp = CBSamplePlayerHp(game, player);
  return hp >= 0.0 && hp < CBConfig.WoundedHealthPercent();
}

// V hurt somebody a moment ago (noted on the hit follow-up, a frame after the hit).
public func CBVFreshFromFight(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !CBMomentOn() || !IsDefined(sys) {
    return false;
  }
  let at = sys.GetLastFightAt();
  let now = CBGameSeconds(game);
  return at > 0.0 && now >= at && (now - at) < CBConfig.FreshFightSeconds();
}

// How much more the crowd fears V right now than V's name alone would make it: the district's temper
// ([6]), the blood, a fight just over. Multiplies the crowd's intensity wherever the crowd's fear is worked
// out (the Director, the Hub's "right now", talk), so the three never disagree.
public func CBCrowdMomentMult(sys: ref<CyberbaneSystem>, game: GameInstance) -> Float {
  if !IsDefined(sys) {
    return 1.0;
  }
  let m = CBTemperScare(sys.GetCurrentDistrict());
  if CBVFreshFromFight(sys, game) {
    m *= CBConfig.FreshFightCrowdMult();
  }
  if CBVWounded(game) {
    m *= CBConfig.WoundedCrowdMult();
  }
  return m;
}
