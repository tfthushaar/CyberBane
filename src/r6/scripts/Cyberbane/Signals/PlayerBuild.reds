// Cyberbane - Player build / menace signal (spec §8.6)
//
// How dangerous V looks on paper feeds how the street treats them. This reads V's character
// level, Street Cred and skill proficiencies (the lines behind Solo, Netrunner, Shinobi,
// Engineer and Headhunter) and folds them into a single 0-100 "menace" value. Menace adds
// to how intimidating V is, so a high-level, skill-maxed, well-known merc gets reactions a
// fresh character never would. Cached on the score engine and refreshed with chrome, so the
// hot per-NPC path just reads it.

public func CBUpdateMenace(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  score.SetMenace(CBComputePlayerMenace(game));
}

public func CBComputePlayerMenace(game: GameInstance) -> Float {
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return 0.0;
  }
  let pds = GameInstance.GetScriptableSystemsContainer(game).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
  if !IsDefined(pds) {
    return 0.0;
  }
  let dev = pds.GetDevelopmentData(player);
  if !IsDefined(dev) {
    return 0.0;
  }

  let level = Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Level));       // ~1-60
  let cred = Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.StreetCred));    // ~1-50

  // Skill lines (2.0 renamed these in the UI; the underlying proficiencies still track).
  let skills = 0.0;
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Hacking));        // Netrunner
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.CombatHacking));
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Engineering));     // Engineer
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Demolition));
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Stealth));         // Shinobi / Headhunter
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.ColdBlood));
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Kenjutsu));
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Athletics));       // Solo
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Brawling));
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Assault));
  skills += Cast<Float>(dev.GetProficiencyLevel(gamedataProficiencyType.Gunslinger));

  // Level carries the most weight (it aggregates everything), street cred next, then the
  // raw skill spread. Clamped to 0-100 to sit alongside Dread and visible chrome.
  let m = (level / 60.0) * 55.0
        + MinF(cred / 50.0, 1.0) * 25.0
        + MinF(skills / 300.0, 1.0) * 20.0;
  return ClampF(m, 0.0, 100.0);
}
