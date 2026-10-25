// Cyberbane — Combat signals (spec §7.1)
//
// Thin hooks on ScriptedPuppet: OnHit records whether V dealt the damage and by
// what method; OnDeath classifies the victim and applies the kill to the model.
// All signatures here are compile-verified against Cyberpunk 2077 2.31.
//
// Method detection is a first pass (quickhack / melee / firearm). Finisher,
// dismember, stealth and non-lethal-defeat detection are refined in spike S-01;
// until then OnDeath is treated as a lethal, witnessed kill.

// Per-puppet scratch state (transient; the puppet despawns after death).
@addField(ScriptedPuppet)
public let cbDamagedByPlayer: Bool;

@addField(ScriptedPuppet)
public let cbLastAttackType: gamedataAttackType;

// The last NPC to damage this puppet — read on the player to attribute V's death.
@addField(ScriptedPuppet)
public let cbLastAttacker: wref<ScriptedPuppet>;

@wrapMethod(ScriptedPuppet)
protected cb func OnHit(evt: ref<gameHitEvent>) -> Bool {
  let result = wrappedMethod(evt);
  CBOnPuppetHit(this, evt);
  return result;
}

@wrapMethod(ScriptedPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result = wrappedMethod(evt);
  CBOnPuppetDeath(this);
  return result;
}

// Player death (spec §7.1). For now this records the death; the cross-save Death
// Ledger and Killer-Rival creation land in M5 (spec §10.8).
@wrapMethod(PlayerPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result = wrappedMethod(evt);
  CBOnPlayerDeath(this);
  return result;
}

func CBOnPlayerDeath(player: ref<PlayerPuppet>) -> Void {
  let sys = CyberbaneSystem.Get(player.GetGame());
  if !IsDefined(sys) {
    return;
  }
  let stats = sys.GetStats();
  if IsDefined(stats) {
    stats.deaths += 1;
  }
  CBWriteDeathLedger(sys, player.GetGame(), player);
  CBLog.Info(n"Signals", "Player died; Death Ledger updated.");
}

func CBOnPuppetHit(puppet: ref<ScriptedPuppet>, evt: ref<gameHitEvent>) -> Void {
  if !IsDefined(evt) || !IsDefined(evt.attackData) {
    return;
  }
  let instigator = evt.attackData.GetInstigator();
  if IsDefined(instigator) && instigator.IsPlayer() {
    puppet.cbDamagedByPlayer = true;
    puppet.cbLastAttackType = evt.attackData.GetAttackType();
  }
  // Record the attacker on the target so V's killer is known at death time.
  let attacker = instigator as ScriptedPuppet;
  if IsDefined(attacker) && !attacker.IsPlayer() {
    puppet.cbLastAttacker = attacker;
  }
}

func CBOnPuppetDeath(puppet: ref<ScriptedPuppet>) -> Void {
  if !puppet.cbDamagedByPlayer {
    return;   // not V's kill (spec §7.1.2)
  }
  let game = puppet.GetGame();
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }

  // Keep the Renown floor current with V's Street Cred.
  sys.GetScore().SetStreetCred(CBPlayerStreetCred(game));

  let info = new CBKillInfo();
  info.victimEntityId = puppet.GetEntityID();
  info.recordID = puppet.GetRecordID();
  info.faction = CBClassifyFaction(puppet);
  info.victimClass = CBClassifyVictim(puppet, info.faction);
  info.lethal = true;
  info.witnessed = true;
  info.stealth = false;
  info.instigatorIsPlayer = true;
  info.district = CBCurrentDistrict(game);
  info.position = puppet.GetWorldPosition();
  info.at = CBGameSeconds(game);
  CBSetMethodFlags(info, puppet.cbLastAttackType);

  let tierBefore = sys.GetLastNotifiedTier();
  CBApplyKill(sys, info);
  CBEncounterRecordKill(sys, info);
  let tierAfter = EnumInt(sys.GetScore().GetTier());
  if tierAfter != tierBefore {
    if tierAfter > tierBefore && IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
      CBShowMessage(game, "Cyberbane: Renown rank up - " + CBTierName(tierAfter), 4.0);
    }
    sys.SetLastNotifiedTier(tierAfter);
  }

  // Titles mostly trigger off kills/stats, so evaluate promptly here as well as
  // on the slow tick.
  CBEvaluateTitles(sys, game);

  // Notable kills the city remembers: gang bosses and MaxTac (spec §7, §9.10).
  if info.lethal && IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    if info.victimClass == EnumInt(ECBVictimClass.Boss) {
      CBShowMessage(game, "Cyberbane: Boss down. Word of this spreads fast.", 4.0);
    } else {
      if info.victimClass == EnumInt(ECBVictimClass.MaxTac) {
        CBShowMessage(game, "Cyberbane: MaxTac operative down. They will not forget.", 4.0);
      }
    }
  }

  // Boss kills spread across districts as rumors (spec §8.5).
  if info.lethal && info.victimClass == EnumInt(ECBVictimClass.Boss) {
    CBCreateRumor(sys, game, n"BossKill", 15.0, info.district, info.faction, info.witnessed);
  }

  // Avenger Rival (spec §10.2): killing an Officer or Boss can summon an avenger
  // from that faction who hunts V.
  if info.lethal && NotEquals(info.faction, n"")
     && (info.victimClass == EnumInt(ECBVictimClass.Boss) || info.victimClass == EnumInt(ECBVictimClass.Officer)) {
    let freq = 1.0;
    if IsDefined(rt) && rt.HasSettings() {
      freq = rt.GetSettings().rivalFrequencyMult;
    }
    if RandF() < CBConfig.RivalChanceAvenger() * freq {
      CBCreateRival(sys, game, info.faction, info.recordID, n"", ECBRivalSource.Avenger, info.district, info.at);
    }
  }
}

// Map the victim's affiliation to a Cyberbane faction id (n"" if unmapped).
func CBClassifyFaction(puppet: ref<ScriptedPuppet>) -> CName {
  let rec = puppet.GetRecord();
  if !IsDefined(rec) {
    return n"";
  }
  let aff = rec.Affiliation();
  if !IsDefined(aff) {
    return n"";
  }
  let content = CyberbaneContent.Get();
  if !IsDefined(content) {
    return n"";
  }
  return content.FactionForAffiliation(aff.EnumName());
}

// Classify the victim (spec §7.1.2). Cyberpsycho/Rival are handled by their own
// paths; this covers MaxTac, Cop, Civilian, Corpo and the rarity tiers.
func CBClassifyVictim(puppet: ref<ScriptedPuppet>, faction: CName) -> Int32 {
  if Equals(faction, n"MaxTac") {
    return EnumInt(ECBVictimClass.MaxTac);
  }
  if Equals(faction, n"NCPD") {
    return EnumInt(ECBVictimClass.Cop);
  }
  if puppet.IsCrowd() {
    return EnumInt(ECBVictimClass.Civilian);
  }
  if Equals(faction, n"Arasaka") || Equals(faction, n"Militech") || Equals(faction, n"KangTao") {
    return EnumInt(ECBVictimClass.Corpo);
  }
  let rec = puppet.GetRecord();
  if IsDefined(rec) {
    let rarity = rec.Rarity();
    if IsDefined(rarity) {
      let t = rarity.Type();
      if Equals(t, gamedataNPCRarity.Boss) {
        return EnumInt(ECBVictimClass.Boss);
      }
      if Equals(t, gamedataNPCRarity.Elite) {
        return EnumInt(ECBVictimClass.Elite);
      }
      if Equals(t, gamedataNPCRarity.Officer) {
        return EnumInt(ECBVictimClass.Officer);
      }
    }
  }
  return EnumInt(ECBVictimClass.Ganger);
}

// First-pass method classification from the attack type (spec §7.1.2).
func CBSetMethodFlags(info: ref<CBKillInfo>, attackType: gamedataAttackType) -> Void {
  if Equals(attackType, gamedataAttackType.Hack) {
    info.mQuickhack = true;
  } else {
    if Equals(attackType, gamedataAttackType.Melee) {
      info.mBlade = true;   // approximation until weapon-level detection (S-01)
    } else {
      info.mFirearm = true;
    }
  }
}
