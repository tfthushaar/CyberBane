// Cyberbane - Persistent data classes (spec §6.2)
//
// These are stored inside CyberbaneSystem's persistent arrays. Every field is
// `persistent` so the ref<Class> instances serialise with the save. No String,
// ResRef or Variant fields are allowed - text is stored as CName or as integer
// indices into localized pools (spec §6.1).

public class CBFactionState {
  public persistent let id: CName;                 // e.g. n"TygerClaws"
  public persistent let standing: Float;           // -100..100
  public persistent let renown: Float;             // 0..100 (RF_f)
  public persistent let renownPeak: Float;
  public persistent let kills: Int32;
  public persistent let brutalKills: Int32;
  public persistent let officersKilled: Int32;
  public persistent let bossesKilled: Int32;
  public persistent let spared: Int32;
  public persistent let lastIncidentAt: Float;
  public persistent let vendettaSince: Float;      // 0 = not in vendetta
  public persistent let lastTributeAt: Float;
  public persistent let tributes: Int32;
  public persistent let lastHitSquadAt: Float;
  public persistent let lastPeaceAt: Float;
  // A real character record of a member V has fought, captured so hit squads spawn
  // faction-appropriate NPCs without hardcoding TweakDB ids (spec §9.9, S-08).
  public persistent let sampleRecord: TweakDBID;
}

public class CBDistrictState {
  public persistent let id: CName;                 // e.g. n"Watson"
  public persistent let renown: Float;             // 0..100 (RD_d)
  public persistent let renownPeak: Float;
  public persistent let kills: Int32;
  public persistent let lethalOrBrutal: Int32;     // for "Butcher of X"
  public persistent let quietTakedowns: Int32;     // for "Ghost of X"
  public persistent let lastIncidentAt: Float;
}

public class CBStats {
  public persistent let killsByClass: array<Int32>;    // index = ECBVictimClass
  public persistent let killsByMethod: array<Int32>;   // index = ECBKillMethod
  public persistent let nonLethal: Int32;
  public persistent let psychosKilled: Int32;
  public persistent let psychosPacified: Int32;
  public persistent let massacres: Int32;
  public persistent let flawless: Int32;
  public persistent let encounters: Int32;
  public persistent let deaths: Int32;
  public persistent let rivalsSlain: Int32;
  public persistent let rivalsSpared: Int32;
  public persistent let tributeEddies: Int32;
  public persistent let timesRecognized: Int32;
  public persistent let maxHeat: Int32;
  public persistent let estimatedPriorKills: Int32;   // bootstrap estimate, display only
  public persistent let quickhackKills: Int32;

  // Total lethal kills across all victim classes (for the mercy ratio, spec §8.2).
  public func TotalKills() -> Int32 {
    let total = 0;
    let i = 0;
    while i < ArraySize(this.killsByClass) {
      total += this.killsByClass[i];
      i += 1;
    }
    return total;
  }
}

public class CBRumor {
  public persistent let id: Int32;
  public persistent let kind: CName;               // n"Massacre", n"BossKill", n"Deed", ...
  public persistent let magnitude: Float;
  public persistent let origin: CName;             // district id
  public persistent let faction: CName;            // n"" if none
  public persistent let createdAt: Float;
  public persistent let lastSpreadAt: Float;
  public persistent let hops: Int32;               // max 2
  public persistent let witnessed: Bool;
  public persistent let reached: array<CName>;     // districts already reached
}

public class CBRivalEvent {
  public persistent let kind: Int32;               // ECBRivalEventKind
  public persistent let at: Float;
  public persistent let district: CName;
  public persistent let detail: Int32;             // e.g. allies killed
}

public class CBRival {
  public persistent let id: Int32;
  public persistent let recordID: TweakDBID;       // character record snapshot
  public persistent let appearance: CName;         // appearance name snapshot
  public persistent let faction: CName;
  public persistent let rank: Int32;               // 1..4
  public persistent let source: Int32;             // ECBRivalSource
  public persistent let state: Int32;              // ECBRivalState
  public persistent let firstName: Int32;          // index into faction name pool
  public persistent let lastName: Int32;
  public persistent let epithet: Int32;            // index into epithet pool
  public persistent let traits: array<CName>;
  public persistent let weaknesses: array<CName>;
  public persistent let encounters: Int32;
  public persistent let escapes: Int32;
  public persistent let killedV: Int32;
  public persistent let sparedByV: Int32;
  public persistent let origin: CName;             // district
  public persistent let createdAt: Float;
  public persistent let lastSeenAt: Float;
  public persistent let nextEligibleAt: Float;
  public persistent let history: array<ref<CBRivalEvent>>;   // cap 10
}

public class CBLogEntry {
  public persistent let kind: CName;               // n"Deed", n"Massacre", n"Title", ...
  public persistent let at: Float;
  public persistent let district: CName;
  public persistent let faction: CName;
  public persistent let value: Float;
  public persistent let refId: Int32;              // deed index / rival id / title index
}

public class CBCooldowns {
  // Game-time cooldowns persist. Real-time cooldowns are session-only and are not stored here.
  public persistent let lastHitSquadAt: Float;
  public persistent let lastRivalEncounterAt: Float;
  public persistent let lastTributeCheckAt: Float;
  public persistent let lastDecayAt: Float;
  public persistent let lastRumorTickAt: Float;
  public persistent let lastPromotionAt: Float;
}

public class CBPeaceDeal {
  public persistent let faction: CName;
  public persistent let at: Float;
  public persistent let cost: Int32;
}
