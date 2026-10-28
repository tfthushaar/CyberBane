// Cyberbane - Faction apex enforcer (spec §9.9)
//
// Put enough of one gang in the ground and they stop sending squads and send someone who
// matters: a named heavy built from the toughest member of theirs V has actually put down.
// No story character is ever involved, so this cannot spoil anything, cannot collide with a
// quest version of anyone, and works for every gang including the ones with no famous boss.
//
// V gets a line first ("Rhino of the Animals is hunting you down"), then a short beat, then
// they walk in with a couple of their people. The apex is a plain spawned enemy, not a Rival:
// it is not tracked, ranked or remembered, it is just the gang's answer to you.
//
// Crash safety: the trigger reads only persisted scalars, the spawn goes through CBSpawnGroup
// (which refuses to spawn while the world is still streaming) and runs from the gated fast
// tick, and every faction entry is bound and checked before a field is read off it.

// A name for the gang's heavy, pulled from that faction's own name pool. Deterministic for a
// given seed so the warning and anything later agree.
public func CBApexName(content: ref<CyberbaneContent>, faction: CName, seed: Int32) -> String {
  if IsDefined(content) {
    let pool = content.GetFactionNames(faction);
    if IsDefined(pool) {
      let n = ArraySize(pool.firstNames);
      if n > 0 {
        return pool.firstNames[CBHashIndex(seed, 17, n)];
      }
    }
  }
  return "Their best";
}

// Make a spawned apex actually feel like one. The base record is a gang elite, which is not a
// boss by itself, so the spawned one is lifted to boss grade: far more health, much harder to
// chew through, and its health pool topped back up because raising the stat does not refill
// what it already had. Applied at attach, where the puppet is real and its stats exist, and
// only ever to our own CB_Apex spawn - nothing in the world is touched.
public func CBApplyApexBuff(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(puppet) {
    return;
  }
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  // Scale to V. Menace already folds in level, Street Cred and skills - the same number the
  // Hub reports - so a maxed-out merc meets something that can take it, and a early character
  // meets something beatable rather than a wall.
  let scale = 0.0;
  if IsDefined(sys) {
    let score = sys.GetScore();
    if IsDefined(score) {
      scale = ClampF(score.GetMenace() / 100.0, 0.0, 1.0);
    }
  }
  let hpMult = CBConfig.ApexHealthMultBase() + scale * CBConfig.ApexHealthMultRange();
  let armourMult = CBConfig.ApexArmorMultBase() + scale * CBConfig.ApexArmorMultRange();

  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  let hp = RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, hpMult);
  if IsDefined(hp) {
    stats.AddModifier(id, hp);
  }
  let armour = RPGManager.CreateStatModifier(gamedataStatType.Armor, gameStatModifierType.Multiplier, armourMult);
  if IsDefined(armour) {
    stats.AddModifier(id, armour);
  }
  let pools = GameInstance.GetStatPoolsSystem(game);
  if IsDefined(pools) {
    pools.RequestSettingStatPoolValue(id, gamedataStatPoolType.Health, 100.0, null);
  }
}

// Slow tick: has any gang lost enough people to send its apex after V?
public func CBApexTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() && !rt.GetSettings().hitSquads {
      return;   // shares the "gangs send people after you" switch
    }
  }
  // Another mod already owns gangs coming after you. The apex is the same kind of system as a
  // hit squad, so it stands down with them rather than stacking a second wave of enemies on
  // top of theirs (spec §17). Detection is the shared They Will Remember / Night City
  // Remembers scan, so this needs no setup from the player.
  if CBTwrActive() {
    return;
  }
  if NotEquals(sys.GetPendingApexFaction(), n"") {
    return;   // one is already on the way
  }
  if sys.IsInSafeZone() {
    return;   // not in a bar or a clinic (spec §16)
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    return;   // let the fight V is already in finish first
  }

  let states = sys.GetFactionStates();
  let i = 0;
  while i < ArraySize(states) {
    let fs = states[i];
    i += 1;
    if IsDefined(fs) && NotEquals(fs.id, n"") {
      // Their toughest if V has met one, otherwise whoever V has been fighting.
      let record = TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
      if TDBID.IsValid(record) && (fs.kills - fs.apexAtKills) >= CBConfig.ApexKillThreshold() {
        // The kills are spent in CBProcessPendingApex, and only once someone has actually
        // arrived. Spending them here meant a spawn that failed for any reason quietly cost
        // the player twenty bodies and they simply never saw an apex.
        sys.SetPendingApex(fs.id, CBConfig.ApexWarningTicks());

        let name = CBApexName(CBContent(game), fs.id, fs.kills);
        if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
          CBShowMessage(game, s"Cyberbane: \(name) of the \(NameToString(fs.id)) is hunting you down. Watch yourself.", 5.0);
        }
        CBLog.Info(n"Spawn", s"Faction apex inbound for \(NameToString(fs.id)).");
        return;   // only ever one gang at a time
      }
    }
  }
}

// Fast tick: the warning has had its moment, bring them in.
public func CBProcessPendingApex(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let faction = sys.GetPendingApexFaction();
  if Equals(faction, n"") {
    return;
  }
  if sys.TickDownPendingApex() > 0 {
    return;   // still counting the warning down
  }
  sys.SetPendingApex(n"", 0);

  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  let record = TDBID.IsValid(fs.eliteRecord) ? fs.eliteRecord : fs.sampleRecord;
  if !TDBID.IsValid(record) {
    return;
  }
  // CBSpawnGroup will refuse while the world is still streaming in, so this can only land on
  // a settled frame. CB_Apex is also tagged n"Cyberbane", so the session sweep clears it.
  let arrived = CBSpawnGroup(game, record, n"", 1, n"CB_Apex", CBConfig.ApexSpawnDistance());
  if arrived <= 0 {
    // The world was not settled enough to place anyone. Keep the kills on the books so the
    // next slow tick tries again, rather than charging the player for a no-show.
    CBLog.Info(n"Spawn", s"Apex spawn for \(NameToString(faction)) did not land; it will try again.");
    return;
  }
  fs.apexAtKills = fs.kills;   // paid for: the next one needs fresh bodies
  if CBConfig.ApexEscortCount() > 0 && TDBID.IsValid(fs.sampleRecord) {
    CBSpawnGroup(game, fs.sampleRecord, n"", CBConfig.ApexEscortCount(), n"CB_Squad",
      CBConfig.ApexSpawnDistance() + 4.0);
  }
}
