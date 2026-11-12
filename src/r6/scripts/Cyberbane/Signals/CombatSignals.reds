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

// A death is worked through on the next frame, not here.
//
// The game delivers these on its worker threads, several at a time when a grenade takes out a group,
// and the fast tick runs on another. Handled here, two deaths, or a death and the tick, changed the
// same lists in Cyberbane's system at once; a player's crash in DropEscapeeByEntity is what that looks
// like. The game's own scripts never change a shared system from inside a puppet's event: they queue
// it (QueueRequest, DelayEvent). This queues it on the delay system, which is where the fast tick
// already runs, so every change to Cyberbane's state from a fight happens one at a time.
@wrapMethod(ScriptedPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result = wrappedMethod(evt);
  CBQueueDeath(this);
  return result;
}

public class CBDeathCallback extends DelayCallback {
  public let puppet: wref<ScriptedPuppet>;
  public let id: EntityID;
  public let waits: Int32;

  public func Call() -> Void {
    // Somebody died in the seconds V was down. Held until V is up again, which only a death
    // alternative brings; a load throws the whole world away first, and this with it. Given up on,
    // only the record goes, which touches nothing in the world.
    let game = GetGameInstance();
    if CBVDown(game) {
      let ds = GameInstance.GetDelaySystem(game);
      if this.waits < CBConfig.CallbackStableWaits() && IsDefined(ds) {
        let again = new CBDeathCallback();
        again.puppet = this.puppet;
        again.id = this.id;
        again.waits = this.waits + 1;
        ds.DelayCallback(again, CBConfig.ConvoyStepDelay(), false);
        return;
      }
      let sysW = CyberbaneSystem.Get(game);
      if IsDefined(sysW) {
        sysW.DropEscapeeByEntity(this.id);
      }
      return;
    }
    if IsDefined(this.puppet) {
      CBOnPuppetDeath(this.puppet);
      return;
    }
    // Gone before the next frame. Nothing about the death can be read any more, but nobody may go
    // on waiting to see whether it got away.
    let sys = CyberbaneSystem.Get(GetGameInstance());
    if IsDefined(sys) {
      sys.DropEscapeeByEntity(this.id);
    }
  }
}

func CBQueueDeath(puppet: ref<ScriptedPuppet>) -> Void {
  let ds = GameInstance.GetDelaySystem(puppet.GetGame());
  if !IsDefined(ds) {
    return;
  }
  let cb = new CBDeathCallback();
  cb.puppet = puppet;
  cb.id = puppet.GetEntityID();
  ds.DelayCallbackNextFrame(cb);
}

// The part of a hit that touches Cyberbane's shared state, on the next frame for the reason above.
// What the hit was is written onto the puppet straight away (CBOnPuppetHit), so nothing is lost by
// waiting. One per puppet at a time: a shotgun's pellets are one follow-up, not eight.
@addField(ScriptedPuppet)
public let cbHitQueued: Bool;

public class CBHitFollowUpCallback extends DelayCallback {
  public let puppet: wref<ScriptedPuppet>;

  public func Call() -> Void {
    let p = this.puppet;
    if !IsDefined(p) {
      return;
    }
    p.cbHitQueued = false;
    let game = p.GetGame();
    let sys = CyberbaneSystem.Get(game);
    // Nobody breaks and runs from V, or is spared by V, while V is dead.
    if !IsDefined(sys) || !p.IsAttached() || CBVDown(game) {
      return;
    }
    // A wounded enemy may lose its nerve and run (spec §10.2).
    CBCombatFleeCheck(sys, game, p);
    // Put them down without killing them? That gets remembered too (spec §10.2).
    CBSparedCheck(sys, game, p);
  }
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
  // Somebody the story made you dying is not V dying: Johnny's last stand in a flashback, a VR
  // bout lost. No death on the tally, no killer turned Rival (Core/StoryHold.reds).
  if !CBPlayerIsVHere(player) {
    return;
  }
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
  // The player, and the player being V. A hit landed as the VR avatar or as Johnny is not V's: it
  // marks nobody as V's to score, breaks nobody's nerve and spares nobody, so a VR bout cannot cost
  // a real gang's standing or send a VR enemy back as a Rival (Core/StoryHold.reds).
  if IsDefined(instigator) && instigator.IsPlayer() && CBPlayerIsVHere(instigator as PlayerPuppet) {
    puppet.cbDamagedByPlayer = true;
    puppet.cbLastAttackType = evt.attackData.GetAttackType();
    puppet.cbScarMask = CBMaskSet(puppet.cbScarMask, CBScarBitFor(puppet.cbLastAttackType));
    puppet.cbLastMethodMask = CBMethodMaskFor(evt.attackData);
    if !puppet.cbHitQueued {
      let ds = GameInstance.GetDelaySystem(puppet.GetGame());
      if IsDefined(ds) {
        puppet.cbHitQueued = true;
        let cb = new CBHitFollowUpCallback();
        cb.puppet = puppet;
        ds.DelayCallbackNextFrame(cb);
      }
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
  CBUntrackOnMap(game, puppet);   // no marker left hanging over a body
  let sysE = CyberbaneSystem.Get(game);
  let wasRival = false;
  // One of ours: its body is cleared later, once V has moved well away (CBSweepRemains).
  let desD = GameInstance.GetDynamicEntitySystem();
  if IsDefined(sysE) && IsDefined(desD) && desD.IsTagged(puppet.GetEntityID(), n"Cyberbane") {
    sysE.NoteDeadOurs(puppet.GetEntityID());
  }
  // Still waiting at their place when they went down: they never got into the fight at all
  // (Rivals/Whereabouts.reds). Read before anything below can change the body's tags.
  let caughtWaiting = IsDefined(desD) && desD.IsTagged(puppet.GetEntityID(), n"CB_Lair");
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
    // Their encounter was already over and the body was still here: put down and left breathing, or
    // got away, and finished after all - knocked out, then run over. That is the Rival dead, not a
    // stranger. Their encounter needs no closing and nobody else's body may be swept for it: another
    // Rival can be out by now.
    let former = false;
    if !IsDefined(slain) && !tagged {
      let formerId = sysE.TakeFormerRivalBody(puppet.GetEntityID());
      let was = formerId > 0 ? sysE.FindRivalById(formerId) : null;
      if IsDefined(was) && (was.state == EnumInt(ECBRivalState.Active) || was.state == EnumInt(ECBRivalState.Hunting)
                            || was.state == EnumInt(ECBRivalState.Debtor)) {
        slain = was;
        former = true;
      }
    }
    // Their chair, read before the hierarchy fills it again.
    let slainRole = IsDefined(slain) ? CBRivalRole(sysE, slain) : CBRoleNone();
    if IsDefined(slain) || tagged {
      wasRival = true;
      if IsDefined(slain) {
        CBRivalSlain(sysE, game, slain, CBGameSeconds(game), CBEventDistrict(sysE, game));
        // V's kill: the bounty, and what they carried (Spawn/Loot.reds).
        if puppet.cbDamagedByPlayer {
          CBPayRivalBounty(sysE, game, slain, slainRole);
          let rivalIconic = (slain.rank >= 4 || slainRole == CBRoleLeader()) ? CBConfig.LootIconicChanceRival() : 0.0;
          CBScheduleLoot(sysE, game, puppet, CBLootTierRival(slain, slainRole), rivalIconic);
          // And V caught them before they knew V was there: an ambush, on top of the kill.
          if caughtWaiting {
            CBLairAmbushed(sysE, game, slain);
          }
        }
      }
      if !former {
        // Shared with the escape and mercy endings, so all three clear the same things. The
        // marker is already off this puppet from the top of this function; this clears the
        // encounter slot and forgets the body.
        CBCloseRivalEncounter(sysE, game, slain, puppet);
        // Do not delete the entity from inside its own death handler - the engine is still
        // tearing this puppet down and destroying it here frees it underneath that work.
        // Queue the sweep instead; the next settled fast tick clears the tag (crash safety).
        sysE.RequestRivalSweep();
      }
    }
    // Putting a gang's apex enforcer down is a trophy worth keeping (spec §9.9). Only counts
    // when V actually had a hand in it.
    if IsDefined(desE) && puppet.cbDamagedByPlayer && desE.IsTagged(puppet.GetEntityID(), n"CB_Apex") {
      let st = sysE.GetStats();
      if IsDefined(st) {
        st.apexKills += 1;
      }
      CBScheduleLoot(sysE, game, puppet, CBLootTierApex(), CBConfig.LootIconicChanceApex());
      // The last of the squad: their enemies pay for it.
      if CBCountLiveOrSpawningExcept(game, n"CB_Apex", puppet.GetEntityID()) == 0 {
        CBPayApexBounty(sysE, game);
        // Their best, all four, put down: the gang feels it (Model/Territory.reds).
        CBWeakenGang(sysE, game, CBClassifyFaction(puppet), CBConfig.GangLossApexSquad());
      }
    }
    // Crew and escorts carry a little.
    if IsDefined(desE) && puppet.cbDamagedByPlayer
       && (desE.IsTagged(puppet.GetEntityID(), n"CB_Squad") || desE.IsTagged(puppet.GetEntityID(), n"CB_Escort")
           || desE.IsTagged(puppet.GetEntityID(), n"CB_Scout")) {
      CBScheduleLoot(sysE, game, puppet, CBLootTierCrew(), 0.0);
    }
    // The last of a crew: their gang's best is next (Spawn/Queue.reds). Counted without this
    // body, which may or may not read as dead yet inside its own death event. A crew that came
    // with its apex squad is one hit squad, and it is beaten when the last of either half goes
    // down with nobody left in the other - not while four of their best are still on V.
    let squadApex = sysE.ActiveSquadHasApex();
    let crewBody = IsDefined(desE)
                   && (desE.IsTagged(puppet.GetEntityID(), n"CB_Squad")
                       || (squadApex && desE.IsTagged(puppet.GetEntityID(), n"CB_Apex")));
    if crewBody && NotEquals(sysE.GetActiveSquadFaction(), n"")
       && CBCountLiveOrSpawningExcept(game, n"CB_Squad", puppet.GetEntityID()) == 0
       && (!squadApex || CBCountLiveOrSpawningExcept(game, n"CB_Apex", puppet.GetEntityID()) == 0) {
      CBOnCrewBeaten(sysE, game, sysE.GetActiveSquadFaction());
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

  // They were put down alive earlier and V has now finished them.
  //
  // Normally there is nothing to take back: the mercy waits on the escapee until V has left
  // them breathing, and the escapee was dropped at the top of this function, so it is simply
  // never scored and this is an ordinary kill. Only if V walked away, the mercy was settled, and
  // V then came back and killed them, is there credit on the books to reverse.
  if puppet.cbSparedLogged && puppet.cbMercyScored {
    CBRevokeMercy(sys, info.faction, puppet.cbMercyInfo, puppet.cbMercyPsycho);
    puppet.cbMercyScored = false;
    puppet.cbMercyInfo = null;
  }

  let tierBefore = sys.GetLastNotifiedTier();
  CBApplyKill(sys, info);
  // Already counted in this fight as somebody down; now they are a body. Not a second person.
  CBEncounterRecordKill(sys, info, puppet.cbSparedLogged);

  // Nearby squad-mates may lose their nerve and run (spec §9.4).
  CBMoraleOnKill(sys, game, info);
  let tierAfter = EnumInt(sys.GetScore().GetTier());
  if tierAfter != tierBefore {
    if tierAfter > tierBefore && CBMessagesOn() {
      CBHearsayFromContact(game, "People have stopped asking who you are. On the street you are " + CBTierName(tierAfter) + " now.", n"");
    }
    sys.SetLastNotifiedTier(tierAfter);
  }

  // Titles mostly trigger off kills/stats, so evaluate promptly here as well as
  // on the slow tick.
  CBEvaluateTitles(sys, game);

  // Notable kills the city remembers: gang bosses and MaxTac (spec §7, §9.10).
  if info.lethal && CBMessagesOn() {
    if info.victimClass == EnumInt(ECBVictimClass.Boss) {
      CBHearsayFromStreet(game, "You took down somebody who mattered. That will be around by morning.", n"BossKill");
    } else {
      if info.victimClass == EnumInt(ECBVictimClass.MaxTac) {
        CBHearsayFromStreet(game, "You put down a MaxTac operative. Nobody does that twice and stays quiet.", n"MaxTacDown");
      }
    }
  }

  // Boss kills spread across districts as rumors (spec §8.5).
  if info.lethal && info.victimClass == EnumInt(ECBVictimClass.Boss) {
    CBCreateRumor(sys, game, n"BossKill", 15.0, info.district, info.faction, info.witnessed);
    if info.witnessed {
      CBFileLog(sys, n"BossKill", info.at, info.district, info.faction, 0.0);
    }
  }
  // One of an apex squad, when somebody saw it: the file is what people passed on.
  let desApex = GameInstance.GetDynamicEntitySystem();
  if info.lethal && info.witnessed && IsDefined(desApex)
     && desApex.IsTagged(puppet.GetEntityID(), n"CB_Apex") {
    CBFileLog(sys, n"ApexDown", info.at, info.district, info.faction, 0.0);
  }

  // Avenger Rival (spec §10.2): killing an Officer or Boss can summon an avenger
  // from that faction who hunts V.
  // A Rival's death has already had its say about who comes next (CBRivalSlain).
  if info.lethal && !wasRival && NotEquals(info.faction, n"")
     && (info.victimClass == EnumInt(ECBVictimClass.Boss) || info.victimClass == EnumInt(ECBVictimClass.Officer)) {
    if CBRivalRoll(sys, "avenger", CBConfig.RivalChanceAvenger(), info.recordID, true) {
      // Once the fight is over (Rivals/Births.reds, 1.9.1).
      CBRivalAfterFight(sys, game, info.faction, info.recordID, n"", ECBRivalSource.Avenger,
                        info.district, info.at, null, 0, "");
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
  let faction = content.FactionForAffiliation(aff.EnumName());
  // MaxTac is not an affiliation. gamedataAffiliation has no such value and every MaxTac record is
  // Factions.NCPD, so nobody was ever classed as MaxTac: their kills scored as cops, MaxTac's Problem
  // could not be earned, and every "MaxTac holds its ground" test here was reading a name that
  // never turned up. Only asked of the NCPD, so ordinary NPCs pay nothing for it.
  if Equals(faction, n"NCPD") && CBRecordIsMaxTac(rec, puppet.GetRecordID()) {
    return n"MaxTac";
  }
  return faction;
}

// Three doors, because the game marks them three ways: the rarity on the ones sent from an AV, a
// tag on the ones a quest placed, and the record's own name on the rest.
func CBRecordIsMaxTac(rec: wref<Character_Record>, id: TweakDBID) -> Bool {
  if !IsDefined(rec) {
    return false;
  }
  let rarity = rec.Rarity();
  if IsDefined(rarity) && Equals(rarity.Type(), gamedataNPCRarity.MaxTac) {
    return true;
  }
  return rec.TagsContains(n"MaxTac_NotPrevention")
      || StrContains(StrLower(TDBID.ToStringDEBUG(id)), "maxtac");
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

// Undo the credit a settled non-lethal takedown was given, because V went back and killed them.
// The knockout itself still happened - the fear it caused and the standing it cost stay - but
// what it earned for being mercy goes. `mercy` is what it was scored from (CBSettleMercy).
public func CBRevokeMercy(sys: ref<CyberbaneSystem>, faction: CName, opt mercy: ref<CBKillInfo>,
                          opt psycho: Bool) -> Void {
  if !IsDefined(sys) {
    return;
  }
  sys.AddCode(-1.0);
  let stats = sys.GetStats();
  if IsDefined(stats) && stats.nonLethal > 0 {
    stats.nonLethal -= 1;
  }
  if IsDefined(stats) && psycho && stats.psychosPacified > 0 {
    stats.psychosPacified -= 1;
  }
  if IsDefined(mercy) && mercy.stealth && NotEquals(mercy.district, n"") {
    let ds = sys.EnsureDistrict(mercy.district);
    if IsDefined(ds) && ds.quietTakedowns > 0 {
      ds.quietTakedowns -= 1;
    }
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
// Set by the takedown hook rather than by the weapon, because it is about how V finished
// somebody rather than what they were holding. It rides alongside one of the five above.
public func CBMethodFinisher() -> Int32 = 64

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
  info.mFinisher = CBMaskHas(mask, CBMethodFinisher());
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
  // Never keep a story character as a spawn template.
  //
  // This was IsQuest alone, which is a much narrower question than the one being asked. A
  // cyberpsycho is not quest-flagged; neither is a boss-rarity elite. So killing one filed its
  // record as the gang's `eliteRecord`, and every apex squad that gang sent afterwards was
  // built from it - four copies of something with a boss's own health, with the mod's
  // apex multiplier applied on top. That is the enemy that cannot be killed, and it is the
  // same record test the Rival roster already uses, so the two now agree.
  // Three doors, because each catches something the others do not. IsQuest is true for a live
  // puppet the quest system placed; the record test is true for anyone the story owns whether
  // or not they are currently in a quest; and a companion is somebody fighting alongside V,
  // who has no business becoming the template a gang spawns its crews from.
  info.victimIsUnique = puppet.IsQuest()
                     || ScriptedPuppet.IsPlayerCompanion(puppet)
                     || CBRecordIsUniqueCharacter(puppet.GetRecordID());
  info.district = CBEventDistrict(sys, game);
  info.position = puppet.GetWorldPosition();
  let witnesses = CBCountWitnesses(sys, info.position, info.victimEntityId);
  // People saw it, but if V's face is covered they cannot say who did it, so nothing attaches
  // to V's name. That is what `witnessed` governs: renown, standing damage and whether a story
  // can name anybody. The body still turns up, so the unattributed dread path still runs, which
  // is exactly the reputation a masked merc should build - a district frightened of something
  // it cannot identify.
  info.witnessed = witnesses > 0 && !CBPlayerMasked(game);
  // Stealth stays literal: it is about whether anyone was there at all, and it feeds the quiet
  // takedown count rather than attribution.
  info.stealth = witnesses == 0;
  info.at = CBGameSeconds(game);
  CBSetMethodFlags(info, puppet.cbLastMethodMask);
  return info;
}
