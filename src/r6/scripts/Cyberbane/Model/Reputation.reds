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
  //
  // There used to be eleven of these and only three were ever assigned. mHeadshot, mVehicle,
  // mEnvironmental, mFinisher and mDismember were never written by anything, so every formula
  // reading them was adding a permanent zero, and mBlade was set for any melee attack at all,
  // which made a hammer score as a blade. A flag with no source is worse than a missing one:
  // it reads as contributing and quietly does not.
  //
  // mDismember stays gone, having no signal on 2.5 - AttackData.IsDismembermentCause covers
  // only charged whips and explosions, which is not the question. mFinisher was dropped for
  // the same reason and then recovered: the takedown hook already had ETakedownActionType in
  // hand, which says outright whether V killed them by hand.
  public let mBlade: Bool;
  public let mBlunt: Bool;
  public let mFists: Bool;
  public let mFirearm: Bool;
  public let mQuickhack: Bool;
  public let mExplosive: Bool;
  // Killed by hand, in a takedown. Set from ETakedownActionType, which is the only place the
  // distinction exists; it is gone by the time the puppet dies.
  public let mFinisher: Bool;
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
  // How frightening unseen work is. Half, by default: the bodies turn up even when nobody saw
  // who left them, which is the whole "dread without renown" idea. It is a slider because for
  // a player who kills quietly and almost never in front of anyone, half of every kill still
  // adds up fast enough to empty streets around somebody nobody has ever seen do anything.
  let dreadWitness = info.witnessed ? 1.0 : CBUnwitnessedDread();
  let standingWitness = info.witnessed ? 1.0 : 0.25;

  // Renown - cyberpsycho and Rival kills are scored by their own paths.
  if info.victimClass != EnumInt(ECBVictimClass.Cyberpsycho) && info.victimClass != EnumInt(ECBVictimClass.Rival) {
    sys.AddRenownPoints(CBRenownForKill(info.victimClass) * renownWitness * renownMult);
  }

  // Kill-dread. Somebody V put down and left breathing frightens people a good deal less than a
  // body does: they get up and tell it, and the street hears restraint in it. This was the full
  // amount for a knockout, so a player who never killed anybody grew exactly as frightening as one
  // who killed everybody - the opposite of what leaving people breathing is meant to say.
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

  // Faction effects.
  if NotEquals(info.faction, n"") {
    let fs = sys.EnsureFaction(info.faction);
    // A gang minds a body far more than somebody who woke up. The same loss used to be taken
    // either way, so there was no reason on this axis to ever hold back.
    let standingLoss = CBStandingDeltaForKill(info.victimClass) * standingWitness
                     * (info.lethal ? 1.0 : CBConfig.NonLethalStandingShare()) * sys.WornPerk().standingLossMult;
    fs.standing = ClampF(fs.standing + standingLoss, -100.0, 100.0);
    // And their enemies hear about it (Model/GangRivalries.reds).
    CBCreditRivalGangs(sys, GetGameInstance(), info.faction, standingLoss);
    // Killing a hostile gang's people where somebody sees it is what sends their next crew.
    if info.lethal && info.witnessed {
      CBProvoke(sys, GetGameInstance(), info.faction);
    }
    fs.renown = ClampF(fs.renown + CBFactionRenownForKill(info.victimClass, brutal) * standingWitness, 0.0, 100.0);
    fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
    fs.kills += 1;
    if brutal { fs.brutalKills += 1; }
    // Aura counts a body as a body. Sitting inside the record-capture branch below would have
    // meant civilian kills never made V look dangerous, which is backwards.
    sys.NoteRecentKill();
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
    // Remember a real combatant record so a later hit squad spawns their kind (S-08).
    // Generic gang archetypes only. A record is a template the game spawns many separate NPCs
    // from, so reusing one is "they sent another of those", not the dead one walking back - but
    // that only holds for generic archetypes. A one-off story character's record would spawn a
    // visible duplicate of that individual, so it is never kept.
    // Never a police record, whoever's colours it wears (CBRecordDrawsPolice).
    if info.victimClass != EnumInt(ECBVictimClass.Civilian) && TDBID.IsValid(info.recordID)
       && !info.victimIsUnique && CBRecordIsPerson(info.recordID)
       && !CBRecordDrawsPolice(info.recordID) {
      fs.sampleRecord = info.recordID;
      // And file it under its combat role, for the apex squad (spec §9.9).
      CBCaptureRoleRecord(fs, info.recordID);
      // An elite, officer or boss makes a far better template for the gang's apex enforcer
      // than a rank-and-file ganger (spec §9.9).
      if info.victimClass == EnumInt(ECBVictimClass.Elite)
         || info.victimClass == EnumInt(ECBVictimClass.Officer)
         || info.victimClass == EnumInt(ECBVictimClass.Boss) {
        fs.eliteRecord = info.recordID;
      }
    }
  }

  // Word gets out.
  //
  // The rumour engine was built, correct, and starved: CBCreateRumor had exactly two live
  // callers, a massacre and a boss kill. So the whole premise the mod advertises - word
  // spreading district to district because somebody saw it, and a contact getting in touch
  // about what they heard - almost never fired during ordinary play. The witness system was
  // already doing its half correctly, scaling reputation by whether anyone lived to tell it;
  // nothing was turning an ordinary witnessed incident into a story.
  //
  // Not every kill, or the board fills with noise and every rumour is worth nothing. Somebody
  // who mattered always travels; the rank and file travel sometimes.
  CBRumorFromKill(sys, GetGameInstance(), info);

  // District effects.
  if NotEquals(info.district, n"") {
    let ds = sys.EnsureDistrict(info.district);
    ds.kills += 1;
    if info.lethal || brutal { ds.lethalOrBrutal += 1; }
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
        //
        // Conduct is the street's read on you, and the street cannot have an opinion about a
        // killing nobody witnessed. Ungated, this punished exactly the playstyle it should not
        // have: quiet melee work, done where there was no one to see it, read the same as
        // beating someone to death in a crowd. The civilian and police penalties stay ungated
        // because a body turns up and gets identified either way; how it was done is the part
        // that needs a witness.
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
    // Butcher is about *how* you kill, not that you killed. Every lethal kill used to add a
    // full Butcher point, so a sniper who never missed and was never seen still ended up
    // labelled a Butcher: fifty quiet kills scored Butcher 50 against Ghost 50, and a tie
    // went to Butcher. Killing cleanly now barely registers as butchery at all, and only
    // a sustained body count drags it up.
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
    sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 1.5);
    if info.stealth {
      sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 1.0);
    }
    if info.mQuickhack {
      sys.AddArchetype(EnumInt(ECBArchetype.Netrunner), 0.5);
      sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 0.5);
    }
  }
}

// When did each gang swear its vendetta?
//
// `vendettaSince` was declared, cleared by brokering peace and read by the Hub, and nothing ever
// set it, so the Gangs screen's "sworn 2h ago" never once appeared. A gang's posture is worked
// out from its standing (CBPostureFromStanding), and standing moves in eight different places,
// so rather than patch each of them this looks at the result: the moment a gang's posture is
// Vendetta and no date is on file, that is when it was sworn. They say so, it goes in the file,
// and the date clears again when the vendetta ends, however it ends.
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
    if IsDefined(fs) && NotEquals(fs.id, n"") {
      let posture = score.GetPosture(fs.id);
      // Coming round to V. The postures run Allied, Friendly, Neutral, Hostile, Vendetta, so a
      // smaller number is a better one; the first look of a session only records where they
      // are, so a load does not replay every friendship V already had.
      let before = sys.SwapSeenPosture(fs.id, EnumInt(posture));
      if before >= 0 && EnumInt(posture) < before && EnumInt(posture) <= EnumInt(ECBPosture.Friendly) {
        CBAnnounceWarming(sys, game, fs.id, Equals(posture, ECBPosture.Allied));
      }
      let sworn = Equals(posture, ECBPosture.Vendetta);
      if sworn && fs.vendettaSince <= 0.0 {
        fs.vendettaSince = MaxF(now, 1.0);
        CBFileLog(sys, n"Vendetta", now, CBEventDistrict(sys, game), fs.id, 0.0);
        if CBToastsOn() && CBFactionFieldsSquads(fs.id) {
          CBPhoneFromGang(game, fs.id, "You are dead to us. Every one of ours who sees you will try.");
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
      //
      // A vendetta is persisted (`vendettaSince`), but the phone's threads are not: they start
      // empty after a load ("Session only" at the top of UI/PhoneMessages.reds). The pay-off
      // answer lives on a thread (UI/RealPhone.reds, m_thOffer), and the only message that
      // opened one was the swearing-in above, which is sent once, on the transition. So a player
      // who loaded a save with a gang already against them had nobody to answer and no way to
      // buy them off from the phone at all - reported as "I don't get the messages where you can
      // either pay for the vendetta to be over or not". The Hub could still broker it; the
      // messages the mod advertises could not be reached.
      //
      // One gang per pass, so several at once do not all text in the same instant after a load,
      // and never a gang that has already been offered this session - including one that refused
      // one, because NotePeaceOffered marks them the first time either way.
      if !demanded && CBToastsOn() && CBFactionFieldsSquads(fs.id)
         && (sworn || Equals(posture, ECBPosture.Hostile)) {
        let quote = CBPeaceQuote(sys, game, fs.id);
        if quote >= 0 && sys.NotePeaceOffered(fs.id) {
          CBPhoneFromGang(game, fs.id, CBPeaceDemandLine(quote, sworn));
          demanded = true;
          CBLog.Info(n"Model", s"\(NameToString(fs.id)) put its price to you: \(quote)eb.");
        }
      }
    }
  }
}
