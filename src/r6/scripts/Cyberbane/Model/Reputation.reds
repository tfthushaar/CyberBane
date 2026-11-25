// Cyberbane - Reputation updates from classified events (spec §8)
//
// The Signals layer classifies a game event into a CBKillInfo and calls
// CBApplyKill. This file holds no game calls: it maps a classified kill/defeat to
// point, faction, district, archetype and stat changes. Companion kills are
// ignored here (instigatorIsPlayer == false), per spec §7.1.2.

public class CBKillInfo {
  public let victimEntityId: EntityID;
  public let recordID: TweakDBID;
  public let faction: CName;        // Cyberbane faction id, n"" if none
  public let victimClass: Int32;    // ECBVictimClass
  public let lethal: Bool;          // false = non-lethal defeat
  public let witnessed: Bool;
  public let stealth: Bool;
  // V was in an open fight when it happened: the game had V in combat. A firefight is never stealth.
  public let loud: Bool;
  public let instigatorIsPlayer: Bool;
  // A one-off story character rather than a generic archetype. Their record is never kept as
  // a spawn template, because spawning from it would put a visible duplicate of a named
  // individual on the street.
  public let victimIsUnique: Bool;
  public let district: CName;
  public let position: Vector4;
  public let at: Float;             // game seconds

  // How it was done. One of the first six is set from the weapon and attack type recorded on
  // the puppet when V last hit it; mFinisher rides alongside and comes from the takedown hook.
  public let mBlade: Bool;
  public let mBlunt: Bool;
  public let mFists: Bool;
  public let mFirearm: Bool;
  public let mQuickhack: Bool;
  public let mExplosive: Bool;
  // Killed by hand, in a takedown. Set from ETakedownActionType, which is the only place the
  // distinction exists; it is gone by the time the puppet dies.
  public let mFinisher: Bool;
  // The weapon in V's hands at the last hit, for the gun the street comes to know (Model/StreetBook.reds).
  public let weaponRecord: TweakDBID;
  // The one who led a crew ([U2]): their fall shakes the rest like an officer's (Reactions/Morale.reds).
  public let sergeant: Bool;
}

// How much of a kill's dread survives nobody having seen it.
public func CBUnwitnessedDread() -> Float {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    return rt.GetSettings().unseenDreadMult;
  }
  return CBConfig.UnwitnessedDreadMult();
}

// Does the player want how-you-killed scored against their Conduct at all?
public func CBReputationFrozen() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().freezeReputation;
}

public func CBBrutalConductOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().brutalConduct;
}

// Applies one classified kill or defeat to the per-save reputation state.
// One incident, maybe one story.
func CBRumorFromKill(sys: ref<CyberbaneSystem>, game: GameInstance, info: ref<CBKillInfo>) -> Void {
  if !IsDefined(sys) || !IsDefined(info) {
    return;
  }
  // No witness, no story. This is the whole point of the witness system: clear a room properly
  // and the street never learns who did it.
  if !info.witnessed {
    return;
  }
  let notable = info.victimClass == EnumInt(ECBVictimClass.Elite)
             || info.victimClass == EnumInt(ECBVictimClass.Officer)
             || info.victimClass == EnumInt(ECBVictimClass.Boss);
  if !notable && RandF() > CBConfig.RumorChanceOrdinary() {
    return;
  }
  let magnitude = notable ? CBConfig.RumorMagnitudeNotable() : CBConfig.RumorMagnitudeOrdinary();
  if info.victimClass == EnumInt(ECBVictimClass.Civilian) {
    magnitude = CBConfig.RumorMagnitudeCivilian();   // a bystander going down travels fast
  }
  CBCreateRumor(sys, game, n"Kill", magnitude, info.district, info.faction, true);
}

public func CBApplyKill(sys: ref<CyberbaneSystem>, info: ref<CBKillInfo>) -> Void {
  if !IsDefined(sys) || !IsDefined(info) {
    return;
  }
  if !info.instigatorIsPlayer {
    return;   // only V's own kills count (spec §7.1.2)
  }

  let renownMult = 1.0;
  let dreadMult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    let s = rt.GetSettings();
    if s.freezeReputation {
      return;
    }
    renownMult = s.renownGainMult;
    dreadMult = s.dreadGainMult;
  }

  renownMult *= sys.WornPerk().renownMult;
  let brutal = CBIsBrutalKill(info.mFinisher, info.mBlade, info.mFists);
  let renownWitness = info.witnessed ? 1.0 : CBConfig.UnwitnessedRenownMult();
  // How frightening unseen work is. Half, by default: the bodies turn up even when nobody saw who left them, which is
  // the whole "dread without renown" idea.
  let dreadWitness = info.witnessed ? 1.0 : CBUnwitnessedDread();
  let standingWitness = info.witnessed ? 1.0 : 0.25;

  // Renown - cyberpsycho and Rival kills are scored by their own paths.
  if info.victimClass != EnumInt(ECBVictimClass.Cyberpsycho) && info.victimClass != EnumInt(ECBVictimClass.Rival) {
    sys.AddRenownPoints(CBRenownForKill(info.victimClass) * renownWitness * renownMult);
  }

  // Kill-dread. Somebody V put down and left breathing frightens people a good deal less than a body does: they get up
  // and tell it, and the street hears restraint in it.
  let brutalMelee = info.mBlade || info.mFists || info.mBlunt;
  let killDread = (CBKillDreadBase(info.victimClass)
                 + CBKillDreadMethodBonus(brutalMelee, info.mFinisher, info.mExplosive,
                                          info.mQuickhack))
                 * dreadWitness * dreadMult
                 * (info.lethal ? 1.0 : CBConfig.NonLethalDreadShare());
  sys.AddKillDreadPoints(killDread);

  // Archetype accrual, then refresh the primary.
  CBAccrueArchetypeForKill(sys, info, brutal);
  sys.RefreshPrimaryArchetype();

  // Aura counts a body as a body, whoever it belonged to.
  sys.NoteRecentKill();

  // A district's own people, and whoever guards them (Data/GangCodes.reds).
  CBGuardiansHear(sys, GetGameInstance(), info);

  // Faction effects.
  if NotEquals(info.faction, n"") {
    let fs = sys.EnsureFaction(info.faction);
    // A gang minds a body far more than somebody who woke up. The same loss used to be taken
    // either way, so there was no reason on this axis to ever hold back.
    let standingLoss = CBStandingDeltaForKill(info.victimClass) * standingWitness
                     * (info.lethal ? 1.0 : CBConfig.NonLethalStandingShare()) * sys.WornPerk().standingLossMult
                     * CBCodeGrudge(info.faction, info);   // how this gang takes it (Data/GangCodes.reds)
    fs.standing = ClampF(fs.standing + standingLoss, -100.0, 100.0);
    // And their enemies hear about it (Model/GangRivalries.reds).
    CBCreditRivalGangs(sys, GetGameInstance(), info.faction, standingLoss);
    // The Scavengers are everybody's enemy: every other gang is glad (Data/GangCodes.reds).
    if info.lethal && info.witnessed && CBCodeEverybodysEnemy(info.faction) {
      CBCreditEverybody(sys, info.faction);
    }
    // Killing a hostile gang's people where somebody sees it is what sends their next crew.
    // When only people off the street saw it, one of them has to carry it to the gang first (Reactions/Witnesses.reds).
    if info.lethal && info.witnessed && !CBWitnessCarries(sys, GetGameInstance(), info) {
      CBProvoke(sys, GetGameInstance(), info.faction);
    }
    // How V fights, in their ledger (Model/Ledger.reds).
    CBLedgerNote(sys, GetGameInstance(), info);
    // And their ranks thin (Economy/War.reds).
    if info.lethal {
      CBWarLoseMen(GetGameInstance(), info.faction, CBConfig.WarMenPerKill());
    }
    fs.renown = ClampF(fs.renown + CBFactionRenownForKill(info.victimClass, brutal) * standingWitness, 0.0, 100.0);
    fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
    fs.kills += 1;
    // Somebody knocked out with a fist was not butchered: only a body counts here.
    if brutal && info.lethal { fs.brutalKills += 1; }
    if info.victimClass == EnumInt(ECBVictimClass.Officer) { fs.officersKilled += 1; }
    if info.victimClass == EnumInt(ECBVictimClass.Boss) { fs.bossesKilled += 1; }
    // And it thins their numbers on the street (Model/Territory.reds).
    CBWeakenGang(sys, GetGameInstance(), info.faction, CBGangLossForKill(info.victimClass, info.lethal));
    if !info.lethal {
      fs.spared += 1;
      // And it counts for something. fs.spared was tallied from the beginning and read by
      // nothing (Model/GangRivalries.reds).
      CBCreditMercy(sys, info.faction, CBConfig.MercyCredit() * standingWitness);
    }
    fs.lastIncidentAt = info.at;
    // Remember a real combatant record so a later hit squad spawns their kind (S-08). Generic gang archetypes only.
    if info.victimClass != EnumInt(ECBVictimClass.Civilian) && TDBID.IsValid(info.recordID)
       && !info.victimIsUnique && CBRecordIsPerson(info.recordID)
       && !CBRecordDrawsPolice(info.recordID) {
      // Never a netrunner as the crew's template. A crew is copies of this one record, so the last kill being a
      // netrunner - often, with More Netrunners - sent a whole crew of them, weak in the open.
      let netrunner = CBRecordIsNetrunner(info.recordID);
      if !netrunner {
        fs.sampleRecord = info.recordID;
      }
      // And file it under its combat role, for the apex squad (spec §9.9).
      CBCaptureRoleRecord(fs, info.recordID);
      // An elite, officer or boss makes a far better template for the gang's apex enforcer
      // than a rank-and-file ganger (spec §9.9).
      if !netrunner && (info.victimClass == EnumInt(ECBVictimClass.Elite)
         || info.victimClass == EnumInt(ECBVictimClass.Officer)
         || info.victimClass == EnumInt(ECBVictimClass.Boss)) {
        fs.eliteRecord = info.recordID;
      }
    }
  }

  // Word gets out.
  CBRumorFromKill(sys, GetGameInstance(), info);

  // District effects.
  if NotEquals(info.district, n"") {
    let ds = sys.EnsureDistrict(info.district);
    ds.kills += 1;
    if info.lethal { ds.lethalOrBrutal += 1; }   // a knockout is neither
    if info.stealth && !info.lethal { ds.quietTakedowns += 1; }
    ds.lastIncidentAt = info.at;
  }

  // Lifetime stats.
  let stats = sys.GetStats();
  if IsDefined(stats) {
    if info.lethal {
      sys.AddKillByClass(info.victimClass);   // tallies live on the system now (schema 3)
    }
    if !info.lethal {
      stats.nonLethal += 1;
    }
    if info.mQuickhack && info.lethal {
      stats.quickhackKills += 1;
    }
    if info.lethal && info.victimClass == EnumInt(ECBVictimClass.Cyberpsycho) {
      stats.psychosKilled += 1;
    }
    // Nobody saw it. The body still turns up, so the district gets a reputation for
    // something it cannot put a name to - dread without renown (spec §8.5).
    if info.lethal && !info.witnessed {
      stats.unattributed += 1;
      // Scaled the same way. This is the extra on top of the kill's own dread for work that
      // cannot be pinned on anyone, so it answers to the same slider.
      sys.AddDeedDreadPoints(CBConfig.UnattributedDeedDread() * dreadMult * CBUnwitnessedDread()
                             / CBConfig.UnwitnessedDreadMult());
    }
  }

  // Code axis (spec §8.11): clean, non-lethal work reads as professional; killing
  // civilians reads as cyberpsycho behaviour; brutal finishers and cop-killing
  // chip at it. Dropping hostile gangers in a fight is just business (neutral).
  if !info.lethal {
    sys.AddCode(1.0);
  } else {
    if info.victimClass == EnumInt(ECBVictimClass.Civilian) {
      sys.AddCode(-5.0);
    } else {
      if info.victimClass == EnumInt(ECBVictimClass.Cop) {
        sys.AddCode(-0.5);
      } else {
        // Only if somebody saw it, and only if the player wants this scored at all.
        if brutal && info.witnessed && CBBrutalConductOn() {
          sys.AddCode(-0.3);
        }
      }
    }
  }

  CBLog.Verbose(n"Model", s"Kill applied: class=\(info.victimClass) faction=\(NameToString(info.faction)) lethal=\(info.lethal) witnessed=\(info.witnessed).");
}

// Archetype accumulators for one kill/defeat (spec §8.3).
func CBAccrueArchetypeForKill(sys: ref<CyberbaneSystem>, info: ref<CBKillInfo>, brutal: Bool) -> Void {
  if info.lethal {
    // Butcher is about *how* you kill, not that you killed.
    sys.AddArchetype(EnumInt(ECBArchetype.Butcher), CBConfig.ButcherPerLethalKill());
    if brutal {
      // Finishers, dismemberment, blades and fists. This is the butchery.
      sys.AddArchetype(EnumInt(ECBArchetype.Butcher), CBConfig.ButcherPerBrutalKill());
      if info.mFists || info.mBlunt {
        sys.AddArchetype(EnumInt(ECBArchetype.Brawler), 0.5);
      }
    }
    if info.victimClass == EnumInt(ECBVictimClass.Civilian) {
      sys.AddArchetype(EnumInt(ECBArchetype.Butcher), 5.0);
      sys.AddArchetype(EnumInt(ECBArchetype.Professional), -3.0);
    }
    // Guns blazing: killing in an open fight is the body count Butcher is built from ("Killing people builds it").
    if info.loud {
      sys.AddArchetype(EnumInt(ECBArchetype.Butcher), CBConfig.ButcherPerLoudKill());
      if info.mExplosive {
        sys.AddArchetype(EnumInt(ECBArchetype.Butcher), CBConfig.ButcherPerLoudKill() * 0.5);
      }
    }
    if info.stealth {
      // Lethal, and nobody alive saw it. That is the definition of ghosting a place, so it
      // outweighs the quiet body count it also produced.
      sys.AddArchetype(EnumInt(ECBArchetype.Ghost), CBConfig.GhostPerUnseenKill());
      sys.AddArchetype(EnumInt(ECBArchetype.Professional), 0.5);
      if info.mFirearm && !brutal {
        // Taken from distance without being seen: a marksman, not a maniac.
        sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 0.5);
      }
    }
    if info.mQuickhack {
      sys.AddArchetype(EnumInt(ECBArchetype.Netrunner), 1.0);
    }
    if info.mFists || info.mBlunt {
      sys.AddArchetype(EnumInt(ECBArchetype.Brawler), 1.0);
    }
  } else {
    // Putting somebody to sleep with fists or a club in a stand-up fight is a brawler's work.
    let hands = info.mFists || info.mBlunt;
    if hands {
      sys.AddArchetype(EnumInt(ECBArchetype.Brawler), 1.5);
    }
    // Quiet work, out of any fight or unseen, is a ghost's.
    if (!hands && !info.loud) || info.stealth {
      sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 1.5);
    }
    if !hands && info.loud && !info.stealth {
      sys.AddArchetype(EnumInt(ECBArchetype.Professional), 1.0);
    }
    if info.stealth {
      sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 1.0);
    }
    if info.mQuickhack {
      sys.AddArchetype(EnumInt(ECBArchetype.Netrunner), 0.5);
      if !info.loud {
        sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 0.5);
      }
    }
  }
}

// When did each gang swear its vendetta?
public func CBVendettaWatch(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return;
  }
  let now = CBGameSeconds(game);
  // At most one gang states its price per pass; see the note further down.
  let demanded = false;
  for fs in sys.GetFactionStates() {
    // A faction switched off in Mod Settings is left exactly as it was.
    if IsDefined(fs) && NotEquals(fs.id, n"") && CBFactionOn(fs.id) {
      let posture = score.GetPosture(fs.id);
      // Set by the player under How gangs see you, or just moved there or back: the player's doing, not the gang's.
      let view = CBGangView(fs.id);
      let viewBefore = sys.SwapSeenView(fs.id, view);
      let quiet = view != 0 || (viewBefore >= 0 && viewBefore != view);
      // Coming round to V.
      let before = sys.SwapSeenPosture(fs.id, EnumInt(posture));
      if before >= 0 && before != EnumInt(posture) {
        CBApiNote(CBApiQPosture(), fs.id, before, EnumInt(posture));   // extension API
      }
      if !quiet && before >= 0 && EnumInt(posture) < before && EnumInt(posture) <= EnumInt(ECBPosture.Friendly) {
        CBAnnounceWarming(sys, game, fs.id, Equals(posture, ECBPosture.Allied));
      }
      let sworn = Equals(posture, ECBPosture.Vendetta);
      if sworn && fs.vendettaSince <= 0.0 && quiet {
        fs.vendettaSince = MaxF(now, 1.0);
      }
      if sworn && fs.vendettaSince <= 0.0 {
        fs.vendettaSince = MaxF(now, 1.0);
        CBFileLog(sys, n"Vendetta", now, CBEventDistrict(sys, game), fs.id, 0.0);
        if CBToastsOn() && CBFactionFieldsSquads(fs.id) && !CBTwrOwnsHostility(fs.id) {
          CBPhoneDemandFromGang(game, fs.id, CBGangBossSigned(sys, game, fs.id, CBT(n"Cyberbane-Reputation-YouAreDeadToUsEvery")));
          // That message already carries the pay-off answer, so this gang has had its say.
          sys.NotePeaceOffered(fs.id);
        }
        CBLog.Info(n"Model", s"\(NameToString(fs.id)) swore a vendetta.");
      } else {
        if !sworn && fs.vendettaSince > 0.0 {
          fs.vendettaSince = 0.0;
        }
      }
      // Every hostile gang that can be bought puts its price to V once a session.
      let offerPlayer = GetPlayer(game);
      if !demanded && CBToastsOn() && CBFactionFieldsSquads(fs.id)
         && (sworn || Equals(posture, ECBPosture.Hostile))
         && sys.PeaceOfferDue(now) && !(IsDefined(offerPlayer) && offerPlayer.IsInCombat()) {
        let quote = CBPeaceQuote(sys, game, fs.id);
        if quote >= 0 && sys.NotePeaceOffered(fs.id) {
          CBPhoneDemandFromGang(game, fs.id, CBGangBroken(sys, fs.id) ? CBPeaceBrokenLine(quote) : CBPeaceDemandLine(quote, sworn), true);
          sys.NotePeaceOfferAt(now);
          demanded = true;
          CBLog.Info(n"Model", s"\(NameToString(fs.id)) put its price to you: \(quote)eb.");
        }
      }
    }
  }
}

// A Scavenger down where people saw it: a little standing with every other gang, under the mercy ceiling, the way
// a favour is (Data/GangCodes.reds).
public func CBCreditEverybody(sys: ref<CyberbaneSystem>, except: CName) -> Void {
  if CBReputationFrozen() {
    return;   // as every standing change
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && NotEquals(fs.id, except) && CBFactionFieldsSquads(fs.id) && fs.standing < CBConfig.MercyCeiling() {
      fs.standing = MinF(CBConfig.MercyCeiling(), fs.standing + CBConfig.ScavengerFavour());
    }
  }
}

// One of a district's ordinary people killed where it was seen: the gangs who guard that district's people take
// it as done to them (6th Street in Santo Domingo, the Mox in Westbrook; Data/GangCodes.reds).
public func CBGuardiansHear(sys: ref<CyberbaneSystem>, game: GameInstance, info: ref<CBKillInfo>) -> Void {
  if !IsDefined(info) || !info.lethal || !info.witnessed || NotEquals(info.faction, n"")
     || info.victimClass != EnumInt(ECBVictimClass.Civilian) || CBReputationFrozen() {
    return;
  }
  let guards: array<CName> = [n"SixthStreet", n"Mox"];
  for g in guards {
    if CBCodeGuards(g, info.district) && CBFactionFieldsSquads(g) {
      let fs = sys.EnsureFaction(g);
      fs.standing = ClampF(fs.standing - CBConfig.GuardCivilianLoss(), -100.0, 100.0);
      fs.lastIncidentAt = info.at;
      CBProvoke(sys, game, g);
      CBFileLog(sys, n"GuardedHurt", info.at, info.district, g, 0.0);
      CBLog.Info(n"Model", s"\(NameToString(g)) look after the people here, and saw that.");
    }
  }
}
