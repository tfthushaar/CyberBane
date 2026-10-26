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
  // The toughest member of this gang V has actually put down (elite, officer or boss). The
  // faction apex is built from this, so the heavy they send is their own kind and no story
  // character is ever involved. Falls back to sampleRecord if V has only fought rank and file.
  // Scalars, never arrays: nothing nested inside a persisted class (see CBRumor).
  public persistent let eliteRecord: TweakDBID;
  // Value of `kills` when this gang last sent its apex, so the next one needs fresh bodies.
  public persistent let apexAtKills: Int32;
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

// Scalars only. The kill tallies used to live here as `killsByClass` / `killsByMethod`
// (array<Int32> nested inside this persisted class) and were ArrayResize'd on every load,
// which is an allocation against a header that just came off disk - the same shape and the
// same risky operation behind the 0.1.8 crash. They now live as a flat array directly on
// CyberbaneSystem, which is the supported place for persisted collections (schema 3).
public class CBStats {
  public persistent let nonLethal: Int32;
  public persistent let psychosKilled: Int32;
  public persistent let psychosPacified: Int32;
  public persistent let massacres: Int32;
  public persistent let flawless: Int32;
  public persistent let encounters: Int32;
  public persistent let deaths: Int32;
  public persistent let rivalsSlain: Int32;
  public persistent let rivalsSpared: Int32;
  public persistent let apexKills: Int32;              // gang apex enforcers V has put down
  public persistent let tributeEddies: Int32;
  public persistent let timesRecognized: Int32;
  public persistent let maxHeat: Int32;
  public persistent let estimatedPriorKills: Int32;   // bootstrap estimate, display only
  public persistent let quickhackKills: Int32;
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
  // Districts already reached, as a bit per district (CBDistrictIndex). This was an
  // array<CName> through 0.1.8. A dynamic array nested inside a persisted class is not a
  // documented-supported shape, and one that did not survive a save/load round trip handed
  // the engine a buffer header with a nonsense capacity, which is what crashed the slow
  // tick. A plain Int32 cannot come back malformed (schema 2).
  public persistent let reachedMask: Int32;
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
  // Traits and weaknesses as a bit per registry entry (CBTraitBit); see the note on
  // CBRumor.reachedMask for why these are no longer nested CName arrays (schema 2).
  public persistent let traitMask: Int32;
  public persistent let weaknessMask: Int32;
  public persistent let encounters: Int32;
  public persistent let escapes: Int32;
  public persistent let killedV: Int32;
  public persistent let sparedByV: Int32;
  public persistent let origin: CName;             // district
  public persistent let createdAt: Float;
  public persistent let lastSeenAt: Float;
  public persistent let nextEligibleAt: Float;
  // No `history` array here any more. It was an array<ref<CBRivalEvent>> nested inside this
  // class, and this class lives inside the persisted m_rivals array - the exact shape that
  // crashed the game via CBRumor.reached. It was also write-only: nothing ever read it back,
  // so it is simply gone rather than relocated (schema 3). If Rival cards ever need an event
  // log, put it in a flat array on CyberbaneSystem keyed by rival id.
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

// A wounded enemy that ran. Session-only (not persisted): if it gets away it becomes or
// promotes a Rival; if V catches and kills it first, it is dropped (spec §10.2).
public class CBEscapee {
  public let puppet: wref<ScriptedPuppet>;
  public let entityId: EntityID;
  public let faction: CName;
  public let record: TweakDBID;
  public let at: Float;
  public let wasRival: Bool;
  // Logged because V put them down without killing them (a knockout / non-lethal takedown)
  // rather than because they ran. Resolved into a Spared Rival if V leaves them breathing.
  public let spared: Bool;
}
