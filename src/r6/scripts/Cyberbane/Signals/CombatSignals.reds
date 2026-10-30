// Cyberbane - Combat signals (spec §7.1)
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

@addField(ScriptedPuppet)
// How V last hit this one, as a CBMethod* bit. The weapon only exists on the hit event, and
// scoring happens on death or defeat long after that event is gone, so the classification has
// to be done here and carried on the puppet. Reading the attack type alone is what made every
// melee kill score as a blade.
public let cbLastMethodMask: Int32;

// Everything V has done to this one, accumulated across hits rather than just the last.
// Someone shot and then set on fire remembers both.
@addField(ScriptedPuppet)
public let cbScarMask: Int32;

// The last NPC to damage this puppet - read on the player to attribute V's death.
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
    puppet.cbScarMask = CBMaskSet(puppet.cbScarMask, CBScarBitFor(puppet.cbLastAttackType));
    puppet.cbLastMethodMask = CBMethodMaskFor(evt.attackData);
    // A wounded enemy may lose its nerve and run (spec §10.2).
    let game = puppet.GetGame();
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      CBCombatFleeCheck(sys, game, puppet);
      // Put them down without killing them? That gets remembered too (spec §10.2).
      CBSparedCheck(sys, game, puppet);
    }
  }
  // Record the attacker on the target so V's killer is known at death time.
  let attacker = instigator as ScriptedPuppet;
  if IsDefined(attacker) && !attacker.IsPlayer() {
    puppet.cbLastAttacker = attacker;
  }
}

func CBOnPuppetDeath(puppet: ref<ScriptedPuppet>) -> Void {
  let game = puppet.GetGame();
  let sysE = CyberbaneSystem.Get(game);
  // Any death cancels a pending escape: this enemy did not get away (spec §10.2). If it
  // was the Rival hunting V, V just slew it.
  if IsDefined(sysE) {
    sysE.DropEscapeeByEntity(puppet.GetEntityID());
    let desE = GameInstance.GetDynamicEntitySystem();
    // Tagged is the normal case and can use the whole resolution chain. Untagged, only an
    // exact body match counts: the retire sweep can clear the tag off a Rival who is still
    // standing there, and before this a kill in that state was simply lost. The faction
    // fallback is deliberately NOT used here, or any dead ganger of that gang would be
    // mistaken for the Rival.
    let tagged = IsDefined(desE) && desE.IsTagged(puppet.GetEntityID(), n"CB_Rival");
    let slain = tagged ? CBResolveSlainRival(sysE, puppet)
                       : CBFindRivalByBody(sysE, puppet.GetEntityID());
    if IsDefined(slain) || tagged {
      if IsDefined(slain) {
        CBRivalSlain(sysE, game, slain, CBGameSeconds(game), CBEventDistrict(sysE, game));
      }
      sysE.SetActiveRivalId(0);
      // Do not delete the entity from inside its own death handler - the engine is still
      // tearing this puppet down and destroying it here frees it underneath that work.
      // Queue the sweep instead; the next settled fast tick clears the tag (crash safety).
      sysE.RequestRivalSweep();
    }
    // Putting a gang's apex enforcer down is a trophy worth keeping (spec §9.9). Only counts
    // when V actually had a hand in it.
    if IsDefined(desE) && puppet.cbDamagedByPlayer && desE.IsTagged(puppet.GetEntityID(), n"CB_Apex") {
      let st = sysE.GetStats();
      if IsDefined(st) {
        st.apexKills += 1;
      }
    }
  }

  if !puppet.cbDamagedByPlayer {
    return;   // not V's kill (spec §7.1.2)
  }
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

  // Who was alive and close enough to carry the story is worked out inside the builder
  // (spec §8.5); it was hardcoded before 0.1.16, which scored every kill as if a crowd watched.
  let info = CBBuildKillInfo(sys, game, puppet, true);

  // They were put down alive earlier and V has now finished them. Take the mercy back, or
  // knocking somebody out and then shooting them would pay for both.
  if puppet.cbSparedLogged {
    CBRevokeMercy(sys, info.faction);
  }

  let tierBefore = sys.GetLastNotifiedTier();
  CBApplyKill(sys, info);
  CBEncounterRecordKill(sys, info);

  // Nearby squad-mates may lose their nerve and run (spec §9.4).
  CBMoraleOnKill(sys, game, info);
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
  let content = CBContent(puppet.GetGame());
  if !IsDefined(content) {
    return n"";
  }
  return content.FactionForAffiliation(aff.EnumName());
}

// Is this one of Night City's cyberpsychos?
//
// There is no typed way to ask on 2.5. Probed and absent: IsCyberpsycho on ScriptedPuppet,
// on Character_Record and as a static; gamedataAffiliation has no Cyberpsycho or Psycho
// member. The record id is the only handle left, and the game's cyberpsycho characters are
// named for it.
//
// This is a best-effort heuristic, not a guarantee. If the id string is unavailable the
// check simply never matches, which is exactly how the mod behaved before it existed - a
// cyberpsycho then scores as an ordinary ganger. It has no other failure mode.
func CBIsCyberpsycho(puppet: ref<ScriptedPuppet>) -> Bool {
  let id = TDBID.ToStringDEBUG(puppet.GetRecordID());
  if Equals(id, "") {
    return false;
  }
  return StrContains(id, "cyberpsycho") || StrContains(id, "Cyberpsycho");
}

// Classify the victim (spec §7.1.2). Rival is handled by its own path; this covers
// Cyberpsycho, MaxTac, Cop, Civilian, Corpo and the rarity tiers.
func CBClassifyVictim(puppet: ref<ScriptedPuppet>, faction: CName) -> Int32 {
  if Equals(faction, n"MaxTac") {
    return EnumInt(ECBVictimClass.MaxTac);
  }
  if CBIsCyberpsycho(puppet) {
    return EnumInt(ECBVictimClass.Cyberpsycho);
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
// Which scar an attack leaves. The engine only separates a few kinds of damage at this
// level, so this is deliberately coarse: enough for a Rival to remember the shape of what
// happened to them, not a forensic record.
public func CBScarBitFor(attackType: gamedataAttackType) -> Int32 {
  if Equals(attackType, gamedataAttackType.Hack) {
    return CBScarFried();
  }
  if Equals(attackType, gamedataAttackType.Explosion) {
    return CBScarBurned();
  }
  if Equals(attackType, gamedataAttackType.Melee) {
    return CBScarCut();
  }
  return CBScarShot();
}

// Undo the credit a non-lethal takedown was given, because V went back and killed them.
public func CBRevokeMercy(sys: ref<CyberbaneSystem>, faction: CName) -> Void {
  if !IsDefined(sys) {
    return;
  }
  sys.AddCode(-1.0);
  let stats = sys.GetStats();
  if IsDefined(stats) && stats.nonLethal > 0 {
    stats.nonLethal -= 1;
  }
  if NotEquals(faction, n"") {
    let fs = sys.FindFaction(faction);
    if IsDefined(fs) && fs.spared > 0 {
      fs.spared -= 1;
    }
  }
}

public func CBMethodBlade() -> Int32 = 1
public func CBMethodBlunt() -> Int32 = 2
public func CBMethodFists() -> Int32 = 4
public func CBMethodFirearm() -> Int32 = 8
public func CBMethodQuickhack() -> Int32 = 16
public func CBMethodExplosive() -> Int32 = 32

// What this blow actually was.
//
// The old version read the attack type and nothing else, so `Melee` became "blade" whether V
// was holding a katana, a baseball bat or nothing at all, and explosives scored as gunfire.
// The weapon is on the attack data, and the game classifies it for us: WeaponObject.IsBlade
// covers machete, katana, sword, chainsword, long blade and mantis blades, and IsBlunt covers
// hammers, clubs, gorilla arms and bare fists - fists are checked first so they do not get
// filed as blunt.
func CBMethodMaskFor(ad: ref<AttackData>) -> Int32 {
  if !IsDefined(ad) {
    return 0;
  }
  let at = ad.GetAttackType();
  if AttackData.IsHack(at) {
    return CBMethodQuickhack();
  }
  if AttackData.IsExplosion(at) || AttackData.IsPressureWave(at) {
    return CBMethodExplosive();
  }
  if AttackData.IsMelee(at) || AttackData.IsQuickMelee(at) || AttackData.IsStrongMelee(at) {
    let weapon = ad.GetWeapon();
    if !IsDefined(weapon) {
      return CBMethodFists();   // no weapon object at all: bare hands
    }
    if WeaponObject.IsFists(weapon.GetItemID()) {
      return CBMethodFists();
    }
    if weapon.IsBlade() {
      return CBMethodBlade();
    }
    if weapon.IsBlunt() {
      return CBMethodBlunt();
    }
    return CBMethodFists();
  }
  return CBMethodFirearm();
}

func CBSetMethodFlags(info: ref<CBKillInfo>, mask: Int32) -> Void {
  info.mBlade = CBMaskHas(mask, CBMethodBlade());
  info.mBlunt = CBMaskHas(mask, CBMethodBlunt());
  info.mFists = CBMaskHas(mask, CBMethodFists());
  info.mFirearm = CBMaskHas(mask, CBMethodFirearm());
  info.mQuickhack = CBMaskHas(mask, CBMethodQuickhack());
  info.mExplosive = CBMaskHas(mask, CBMethodExplosive());
}

// One classified incident, lethal or not.
//
// Pulled out of CBOnPuppetKilled so a non-lethal takedown can be scored through exactly the
// same path. CBApplyKill has always had a !lethal branch on every axis it touches - the conduct
// credit, the nonLethal tally, fs.spared, the quiet-takedown count - and nothing ever handed it
// an info with lethal = false, so all of it was dead and Conduct could only ever fall.
public func CBBuildKillInfo(sys: ref<CyberbaneSystem>, game: GameInstance,
                            puppet: ref<ScriptedPuppet>, lethal: Bool) -> ref<CBKillInfo> {
  let info = new CBKillInfo();
  info.victimEntityId = puppet.GetEntityID();
  info.recordID = puppet.GetRecordID();
  info.faction = CBClassifyFaction(puppet);
  info.victimClass = CBClassifyVictim(puppet, info.faction);
  info.lethal = lethal;
  info.instigatorIsPlayer = true;
  info.victimIsUnique = puppet.IsQuest();   // never keep a story character as a spawn template
  info.district = CBEventDistrict(sys, game);
  info.position = puppet.GetWorldPosition();
  let witnesses = CBCountWitnesses(sys, info.position, info.victimEntityId);
  info.witnessed = witnesses > 0;
  info.stealth = witnesses == 0;
  info.at = CBGameSeconds(game);
  CBSetMethodFlags(info, puppet.cbLastMethodMask);
  return info;
}
