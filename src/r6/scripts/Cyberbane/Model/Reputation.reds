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

  // Method flags (several may be true).
  public let mHeadshot: Bool;
  public let mBlade: Bool;
  public let mBlunt: Bool;
  public let mFists: Bool;
  public let mFirearm: Bool;
  public let mQuickhack: Bool;
  public let mExplosive: Bool;
  public let mVehicle: Bool;
  public let mFinisher: Bool;
  public let mDismember: Bool;
  public let mEnvironmental: Bool;
}

// Applies one classified kill or defeat to the per-save reputation state.
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

  let brutal = CBIsBrutalKill(info.mFinisher, info.mDismember, info.mBlade, info.mFists);
  let renownWitness = info.witnessed ? 1.0 : CBConfig.UnwitnessedRenownMult();
  let dreadWitness = info.witnessed ? 1.0 : CBConfig.UnwitnessedDreadMult();
  let standingWitness = info.witnessed ? 1.0 : 0.25;

  // Renown - cyberpsycho and Rival kills are scored by their own paths.
  if info.victimClass != EnumInt(ECBVictimClass.Cyberpsycho) && info.victimClass != EnumInt(ECBVictimClass.Rival) {
    sys.AddRenownPoints(CBRenownForKill(info.victimClass) * renownWitness * renownMult);
  }

  // Kill-dread.
  let brutalMelee = info.mBlade || info.mFists || info.mBlunt;
  let killDread = (CBKillDreadBase(info.victimClass)
                 + CBKillDreadMethodBonus(brutalMelee, info.mFinisher, info.mDismember, info.mExplosive, info.mQuickhack))
                 * dreadWitness * dreadMult;
  sys.AddKillDreadPoints(killDread);

  // Archetype accrual, then refresh the primary.
  CBAccrueArchetypeForKill(sys, info, brutal);
  sys.RefreshPrimaryArchetype();

  // Faction effects.
  if NotEquals(info.faction, n"") {
    let fs = sys.EnsureFaction(info.faction);
    fs.standing = ClampF(fs.standing + CBStandingDeltaForKill(info.victimClass) * standingWitness, -100.0, 100.0);
    fs.renown = ClampF(fs.renown + CBFactionRenownForKill(info.victimClass, brutal) * standingWitness, 0.0, 100.0);
    fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
    fs.kills += 1;
    if brutal { fs.brutalKills += 1; }
    if info.victimClass == EnumInt(ECBVictimClass.Officer) { fs.officersKilled += 1; }
    if info.victimClass == EnumInt(ECBVictimClass.Boss) { fs.bossesKilled += 1; }
    if !info.lethal { fs.spared += 1; }
    fs.lastIncidentAt = info.at;
    // Remember a real combatant record so a later hit squad spawns their kind (S-08).
    // Generic gang archetypes only. A record is a template the game spawns many separate NPCs
    // from, so reusing one is "they sent another of those", not the dead one walking back - but
    // that only holds for generic archetypes. A one-off story character's record would spawn a
    // visible duplicate of that individual, so it is never kept.
    if info.victimClass != EnumInt(ECBVictimClass.Civilian) && TDBID.IsValid(info.recordID)
       && !info.victimIsUnique {
      fs.sampleRecord = info.recordID;
      // An elite, officer or boss makes a far better template for the gang's apex enforcer
      // than a rank-and-file ganger (spec §9.9).
      if info.victimClass == EnumInt(ECBVictimClass.Elite)
         || info.victimClass == EnumInt(ECBVictimClass.Officer)
         || info.victimClass == EnumInt(ECBVictimClass.Boss) {
        fs.eliteRecord = info.recordID;
      }
    }
  }

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
    // Nobody saw it. The body still turns up, so the district gets a reputation for
    // something it cannot put a name to - dread without renown (spec §8.5).
    if info.lethal && !info.witnessed {
      stats.unattributed += 1;
      sys.AddDeedDreadPoints(CBConfig.UnattributedDeedDread() * dreadMult);
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
        if brutal {
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
    sys.AddArchetype(EnumInt(ECBArchetype.Butcher), 1.0);
    if brutal {
      sys.AddArchetype(EnumInt(ECBArchetype.Butcher), 1.0);
      if info.mFists || info.mBlunt {
        sys.AddArchetype(EnumInt(ECBArchetype.Brawler), 0.5);
      }
    }
    if info.victimClass == EnumInt(ECBVictimClass.Civilian) {
      sys.AddArchetype(EnumInt(ECBArchetype.Butcher), 5.0);
      sys.AddArchetype(EnumInt(ECBArchetype.Professional), -3.0);
    }
    if info.stealth {
      sys.AddArchetype(EnumInt(ECBArchetype.Ghost), 1.0);
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
