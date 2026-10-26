// Cyberbane - Tribute (spec §9.8)
//
// A gang you have made feared - but not yet pushed into open war - may quietly pay you
// to stay on their good side. Once per in-game day each eligible gang rolls a chance to
// send eddies; paying nudges its standing back up a little and counts toward the Feared
// Landlord title. Corps and the NCPD never pay tribute.

public func CBTributeTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  let tributeMult = 1.0;
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() {
      if !rt.GetSettings().tribute {
        return;
      }
      tributeMult = rt.GetSettings().tributeMult;
    }
  }

  let now = CBGameSeconds(game);
  let cd = sys.GetCooldowns();
  // Run the whole sweep at most once per in-game day.
  if IsDefined(cd) {
    if cd.lastTributeCheckAt > 0.0 && (now - cd.lastTributeCheckAt) < CBConfig.SecondsPerDay() {
      return;
    }
    cd.lastTributeCheckAt = now;
  }

  let score = sys.GetScore();
  let content = CBContent(game);
  let player = GetPlayer(game);
  if !IsDefined(score) || !IsDefined(content) || !IsDefined(player) {
    return;
  }

  let cooldown = CBConfig.TributeCooldownDays() * CBConfig.SecondsPerDay();
  for fs in sys.GetFactionStates() {
    let prof = content.GetFaction(fs.id);
    // Feared, not yet at war, and known to the gang; corps and cops never pay (spec §9.8).
    let eligible = IsDefined(prof) && prof.isGang
      && fs.standing >= -60.0 && fs.standing <= 40.0
      && fs.renown >= CBConfig.TributeRenownThreshold()
      && score.GetFactionFear(fs.id) >= CBConfig.TributeFearThreshold()
      && (fs.lastTributeAt <= 0.0 || (now - fs.lastTributeAt) >= cooldown);
    if eligible && RandF() < CBConfig.TributeChance() {
      CBPayTribute(sys, game, player, score, fs, tributeMult, now);
    }
  }
}

func CBPayTribute(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<GameObject>, score: ref<CBScoreEngine>, fs: ref<CBFactionState>, tributeMult: Float, now: Float) -> Void {
  // round50(500 + 2500 × (F_f − 75)/25) × tributeMult  (spec §9.8).
  let ff = score.GetFactionFear(fs.id);
  let raw = (500.0 + 2500.0 * (ff - 75.0) / 25.0) * tributeMult;
  let amount = RoundF(raw / 50.0) * 50;
  if amount <= 0 {
    return;
  }

  let ts = GameInstance.GetTransactionSystem(game);
  if IsDefined(ts) {
    ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
  }

  fs.standing = ClampF(fs.standing + 5.0, -100.0, 100.0);
  fs.lastTributeAt = now;
  fs.tributes += 1;
  let stats = sys.GetStats();
  if IsDefined(stats) {
    stats.tributeEddies += amount;
  }

  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    CBShowMessage(game, s"Cyberbane: \(NameToString(fs.id)) sent \(amount) eddies in tribute.", 4.0);
  }
  CBLog.Info(n"Model", s"Tribute from \(NameToString(fs.id)): \(amount) eddies.");
}
