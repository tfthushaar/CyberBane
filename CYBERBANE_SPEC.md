# Cyberbane — Design & Technical Specification

> *Night City remembers what V has done, what V has become, and what V looks like, and it acts on that.*

| | |
|---|---|
| **Document** | Cyberbane design & technical spec |
| **Spec version** | 0.1 (draft, pre-implementation) |
| **Date** | 2026-10-24 |
| **Game target** | Cyberpunk 2077 **2.31** for development; **2.5** once RED4ext ships official 2.5 support |
| **Language / stack** | redscript + Codeware (RED4ext), Mod Settings; no native C++ |
| **Code namespace** | `Cyberbane` (classes prefixed `CB`) |
| **Status legend** | ✅ verified · 🔎 name found in game scripts, signature unverified · ❓ unverified (needs a research spike) |

---

## Table of contents

1. [Vision](#1-vision)
2. [Player experience](#2-player-experience)
3. [Glossary](#3-glossary)
4. [Platform & dependencies](#4-platform--dependencies)
5. [Architecture](#5-architecture)
6. [Data model & persistence](#6-data-model--persistence)
7. [Signals (inputs)](#7-signals-inputs)
8. [Scoring model](#8-scoring-model)
9. [Reactions (outputs)](#9-reactions-outputs)
10. [Rivals & the Death Ledger](#10-rivals--the-death-ledger)
11. [Player agency](#11-player-agency)
12. [User interface](#12-user-interface)
13. [Settings](#13-settings)
14. [Content registries (data)](#14-content-registries-data)
15. [Localization](#15-localization)
16. [Safety rules](#16-safety-rules)
17. [Compatibility](#17-compatibility)
18. [Performance budget](#18-performance-budget)
19. [Save safety, migration & uninstall](#19-save-safety-migration--uninstall)
20. [Logging & debug tooling](#20-logging--debug-tooling)
21. [Testing plan](#21-testing-plan)
22. [Packaging & release](#22-packaging--release)
23. [Milestones](#23-milestones)
24. [Research spikes](#24-research-spikes)
25. [API reference & verification status](#25-api-reference--verification-status)
26. [Legal & naming](#26-legal--naming)
27. [Appendices](#27-appendices)

---

## 1. Vision

Cyberbane gives V a **reputation that the world can perceive and react to**. Every NPC reaction must trace back to something real: missions V completed, people V killed or spared, chrome V installed, clothes V wears, and what V is doing right now.

### 1.1 Pillars

1. **Earned.** Every reaction comes from a measurable signal. Nothing is random flavour without cause.
2. **Legible.** The player can always find out *why* people react the way they do (Hub → Legend tab breakdown).
3. **Local before global.** Word spreads. V is a legend in Watson before Pacifica has heard the name.
4. **Different gangs, different values.** Maelstrom respects chrome, the Animals respect strength, the Voodoo Boys respect netrunners. The same V gets different reactions from each.
5. **Systemic, not scripted.** No hand-placed scenes. Cyberbane works anywhere in the open world.
6. **Safe.** Cyberbane never breaks quests, companions, romances or saves. When in doubt, do nothing.

### 1.2 Non-goals (v1)

- No new voice acting. Reactions use existing game VO, animations, and **text** whispers.
- No new quests or story outcomes.
- No LLM or AI-voice integration (listed as a far-future idea only).
- No edits to base game files. All changes are runtime, additive, and revert on uninstall.
- No multiplayer or cross-player features.

---

## 2. Player experience

These moments define success. Each must be reproducible in testing.

1. **The walk through Kabuki.** After a few hours of brutal fights in Watson, V walks down a busy street. Pedestrians drift out of V's path. A subtitle line appears: *Passerby: "Don't stare, choom. That's the Butcher of Watson."* Over in Pacifica, nobody notices V yet.
2. **Drawing the blades.** V deploys Mantis Blades in a crowd. People near V scream and run, and a car peels away in panic. With blades sheathed, the street calms within seconds.
3. **Maelstrom's respect.** V is 80% chromed. In Northside, Maelstrom gangers who used to watch V warily now say *"Now THAT is chrome. Respect."* They let V walk through their turf.
4. **Morale break.** V wipes out half a Tyger Claws squad with finishers in five seconds. Two of the survivors break and run. One escapes.
5. **The one who got away.** Three in-game days later in Japantown, a Rival card slams onto the screen: *Kenji "Who Ran" Morita, Tyger Claws, Marked. Survived the Kabuki massacre.* He brought friends, and he hits harder now.
6. **Tribute.** V's Dread is enormous and the Valentinos are neutral. A message arrives: *"A Valentinos lieutenant sends 1,500 €$ with a note: 'Stay out of Heywood business.'"*
7. **Death remembered.** A Scav kills V. The game reloads. Later, that same Scav, now named and promoted, is waiting for V with a taunt.
8. **Becoming Cyberbane.** V hits Legend renown, near-maximum Dread, has broken three factions and slain three Rivals. The title **Cyberbane** unlocks and a city-wide message goes out.

---

## 3. Glossary

| Term | Meaning |
|---|---|
| **Renown (R)** | How *known* V is, 0–1000. Accumulates from deeds, witnessed kills, gigs and titles. |
| **Dread (D)** | How *terrifying* V is, 0–100. Blends kills, chrome, looks, deeds and police history. |
| **Aura (A)** | Momentary threat, 0–40: weapon drawn, combat cyberware active, recent kills nearby. |
| **Standing (S_f)** | Faction relationship, −100 (vendetta) to +100 (allied). |
| **Faction Fear (F_f)** | How much faction *f* fears V, 0–100. |
| **Faction Respect (P_f)** | How much faction *f* rates V, 0–100. |
| **Faction Renown (RF_f)** | How well faction *f* knows V, 0–100. |
| **District Renown (RD_d)** | How well people in district *d* know V, 0–100. |
| **Recognition** | Per-NPC roll: does this NPC know who V is? |
| **Perceived Threat (T)** | Final per-NPC fear input, 0–100. |
| **Effective Fear (E)** | `T/100 − courage`. Drives behaviour choice. |
| **Archetype** | What *kind* of legend V is: Butcher, Ghost, Professional, Chromed, Netrunner or Brawler. |
| **Deed** | A notable completed quest, gig or outcome from the content registry. |
| **Encounter** | One combat episode, from combat start until 20 s after combat end. |
| **Rumor** | A record of an event that spreads between districts over game time. |
| **Rival** | A named, persistent individual enemy who remembers V and grows. |
| **Death Ledger** | Cross-save record of V's deaths, so killers can become Rivals despite reloads. |
| **Playthrough ID** | Random ID created on first run in a save line, used to match ledger entries. |
| **Low Profile** | Player state that suppresses Aura and lowers recognition. |
| **Posture** | Faction behaviour band derived from Standing: Allied, Friendly, Neutral, Hostile, Vendetta. |

---

## 4. Platform & dependencies

### 4.1 Runtime dependencies

| Dependency | Required? | Why | Known-good on 2.31 | 2.5 status (2026-10-24) |
|---|---|---|---|---|
| RED4ext | **Required** | Loads Codeware | 1.30.0 | ❌ Broken. Waiting on an official release |
| redscript | **Required** | All mod logic | 0.5.31 | 0.5.32 supports 2.5 |
| Codeware | **Required** | Persistent services, entity spawning, callbacks, UI, localization | 1.20.3 | 1.20.6 (unverified on 2.5) |
| Mod Settings | **Required** | In-game settings menu | 0.2.21 | Check before 2.5 |
| TweakXL | Conditional | Needed only if Spike S-07 uses runtime TweakDB records for Rival nameplates | 1.11.4 | 1.11.5 |
| ArchiveXL | Not required in v1 | Only needed if custom ink/archive assets are added later | 1.27.1 | 1.27.5 |
| Native Interactions Framework | Optional | Enables the **Intimidate** interaction (§11.3) | 1.05b | Check |
| Equipment-EX | Optional | Lets Look scoring read Equipment-EX outfits (§7.4) | – | Check |
| Cyber Engine Tweaks | Optional, dev only | Debug console commands (`CyberbaneDebug`, not shipped in main file) | 1.37.1 | 1.38.0 |

**Rule:** keep the required set as small as possible. Every extra native dependency is another thing that breaks on a game patch.

### 4.2 Development tools

- **WolvenKit**: inspect TweakDB records, journal paths, character records and appearances.
- **RedHotTools** (psiberx): in-game world inspector, plus hot reload of scripts and tweaks. Strongly recommended.
- **NativeDB** and the **decompiled game scripts**: authoritative class and function signatures.
- **VS Code + redscript language server**: syntax and type checking.
- **CET console**: quick prototyping of game calls before writing redscript.
- A **clean 2.31 install** with only the required dependencies, plus the owner's full mod list for compatibility passes.

### 4.3 Engineering conventions

- Classes are prefixed `CB` (e.g. `CBRival`). Enums are prefixed `ECB`. Module is `Cyberbane.*`.
- No `String`, `ResRef` or `Variant` in persistent fields (§6.1).
- All tunable numbers live in `Core/Config.reds` (§27 A) and are multiplied by settings where applicable.
- Every hook into a game method must be **thin**. It extracts data, publishes a Cyberbane event and returns, and contains no business logic.
- Every reaction must pass the **Safety Gate** (§16) before it is applied.

---

## 5. Architecture

### 5.1 Overview

```
                  ┌──────────────────── GAME ────────────────────┐
                  │ deaths · hits · journal · equipment · heat   │
                  │ districts · time · player state · entities   │
                  └──────────────┬───────────────────────────────┘
                                 │ thin hooks / callbacks
                                 ▼
┌───────────────────────── SIGNALS ─────────────────────────┐
│ CombatSignals  DeedSignals  ChromeSignals  LookSignals     │
│ HeatSignals    PlayerStateSignals   DistrictSignals        │
└──────────────┬────────────────────────────────────────────┘
               │ CB events (typed)
               ▼
        ┌───────────────┐        ┌───────────────────────────┐
        │  CBEventBus   │───────▶│ ENCOUNTER TRACKER         │
        └──────┬────────┘        └──────────┬────────────────┘
               ▼                            ▼
┌──────────────────────────── MODEL ─────────────────────────────┐
│ ScoreEngine (R, D, C, L, factions, districts)  RumorEngine     │
│ ArchetypeEngine   TitleEngine   Recognition   LegendLog        │
└──────────────┬─────────────────────────────────────────────────┘
               ▼
┌─────────────────────── REACTION DIRECTOR ──────────────────────┐
│ SafetyGate → Crowd · Gang · Morale · Police · Vendor · Tribute │
│ HitSquads · Whispers · Messages                                │
└──────────────┬─────────────────────────────────────────────────┘
               ▼
┌──────────── RIVALS ────────────┐   ┌──────────── UI ────────────┐
│ RivalSystem · RivalSpawner     │   │ Hub · Toasts · RivalCard   │
│ DeathLedger (cross-save)       │   │ WhisperOverlay · DebugHUD  │
└────────────────────────────────┘   └────────────────────────────┘

Persistence:  CyberbaneSystem (ScriptableSystem, per save)
              CyberbaneService (Codeware ScriptableService, global)
```

### 5.2 Components

| Component | Type | Responsibility |
|---|---|---|
| `CyberbaneSystem` | `ScriptableSystem` | Owns per-save state (§6.2) and lifecycle. It is the entry point for everything else. |
| `CyberbaneService` | Codeware `ScriptableService` | Global state: Death Ledger and install metadata. |
| `CBEventBus` | plain class | Synchronous publish/subscribe for internal events (§5.4). |
| `CBEncounterTracker` | plain class | Groups combat into encounters, tracks participants, witnesses and outcomes. |
| `CBScoreEngine` | plain class | Computes R, D, components, faction and district values. Caches derived values. |
| `CBRumorEngine` | plain class | Creates, spreads and expires rumors. |
| `CBArchetypeEngine` | plain class | Archetype accumulators and the primary archetype. |
| `CBTitleEngine` | plain class | Evaluates title conditions and unlocks titles. |
| `CBRecognition` | plain class | Per-NPC recognition rolls with an EntityID-keyed cache. |
| `CBNpcRegistry` | plain class | Set of attached NPC puppets, kept by Codeware entity attach/detach callbacks. |
| `CBReactionDirector` | plain class | Fast-tick evaluation of nearby NPCs. Dispatches to reaction modules. |
| `CBSafetyGate` | plain class | Single authority on whether an NPC or context may be touched (§16). |
| `CBCrowdReactions`, `CBGangReactions`, `CBMorale`, `CBPoliceReactions`, `CBVendorPricing`, `CBTribute`, `CBHitSquads` | plain classes | Reaction modules (§9). |
| `CBWhispers`, `CBMessages` | plain classes | Text narrative output (§9.10, §9.7). |
| `CBRivalSystem`, `CBRivalSpawner`, `CBDeathLedger` | plain classes | Rivals (§10). |
| `CBHub`, `CBToasts`, `CBRivalCard`, `CBWhisperOverlay`, `CBDebugHud` | Codeware UI | UI (§12). |
| `CBSettings` | Mod Settings class | User settings (§13). |
| `CBContent` | registry | Data tables: factions, deeds, implants, looks, titles, names (§14). |
| `CBLog` | static | Logging (§20). |

### 5.3 Lifecycle

1. **System attach** (`CyberbaneSystem.OnAttach` / restore). Load persistent state, then run `Migrate()` (§19.2).
2. **Wait until ready**: player puppet attached, `DynamicEntitySystem.IsReady()` ✅, journal available.
3. **First run in this save line**: create the Playthrough ID and run **Bootstrap** (§7.2.4).
4. **Session start**: `DeleteTagged(n"Cyberbane")` ✅ to clean up stray transient spawns, apply pending Death Ledger entries (§10.8), register callbacks, start ticks.
5. **Running**: event-driven updates, plus a **fast tick** (1.0 s real time) and a **slow tick** (each in-game hour, §5.5).
6. **Detach / unload**: unregister callbacks, despawn Cyberbane entities, and revert any NPC attitude overrides still active (§16.4).

### 5.4 Internal events

All signals publish one of these. Reaction and model modules subscribe.

| Event | Payload |
|---|---|
| `CB_NpcKilled` | victim EntityID, recordID, faction, victimClass, method flags, instigatorIsPlayer, position, district, timestamp |
| `CB_NpcDefeated` | same as above, non-lethal |
| `CB_PlayerDamaged` | source EntityID, amount, fraction of max HP |
| `CB_PlayerDied` | killer EntityID, recordID, appearance, faction, district |
| `CB_EncounterStarted` / `CB_EncounterResolved` | encounter object (§7.1.3) |
| `CB_DeedCompleted` | deed id, silent flag (bootstrap) |
| `CB_ChromeChanged` | new C, C_visible, overallocated |
| `CB_LookChanged` | new L, disguise value, faction-colors |
| `CB_HeatStageChanged` | stage |
| `CB_DistrictChanged` | old, new |
| `CB_CombatCyberwareActivated` | type (Berserk, Sandevistan, Kerenzikov, OpticalCamo, …) |
| `CB_TierChanged`, `CB_TitleUnlocked`, `CB_PostureChanged` | ids, old/new values |
| `CB_RivalEvent` | rival id, kind |

### 5.5 Scheduling

- **Fast tick (1.0 s real time):** Aura, Low Profile state, nearby NPC evaluation (budgeted, §18), whisper cooldowns, encounter timeouts.
- **Slow tick (each in-game hour):** decay, rumor spread (every 6 in-game hours), Chromed archetype accrual, hit-squad and rival scheduling checks, tribute checks (daily), title evaluation, safety re-scan of equipment (chrome and look).
- Implemented with `DelaySystem` callbacks 🔎. Game time comes from `TimeSystem` 🔎 (Spike S-17).

---

## 6. Data model & persistence

### 6.1 Persistence rules (from the redscript persistence docs)

- `ScriptableSystem` fields marked `persistent` are saved **inside the save file** ✅.
- Codeware `ScriptableService` `persistent` fields are saved **globally**, shared by all saves ✅.
- Persistable types include `Int32`, `Float`, `Bool`, `CName`, `TweakDBID`, enums, arrays of these, and `ref<Class>` (and arrays of them) **when the class's fields are also `persistent`** ✅.
- **Not persistable:** `String`, `ResRef`, `Variant`, or arrays of them ✅. Store text as `CName` or, better, as **indices into localized pools**.
- Unmarked fields reset to defaults on load ✅.
- **If a save is written without the mod, all Cyberbane data in that save is gone** ✅ (§19.3).
- In-game time is stored as `Float` total game seconds (conversion from `GameTime`: Spike S-17).

### 6.2 Per-save state (`CyberbaneSystem`)

```swift
// Illustrative. Field names are normative; final syntax per redscript.
public class CyberbaneSystem extends ScriptableSystem {
  private persistent let m_schemaVersion: Int32;          // starts at 1
  private persistent let m_playthroughId: CName;          // e.g. n"CB_7F3A19C2"
  private persistent let m_bootstrapped: Bool;
  private persistent let m_installedAt: Float;            // game seconds

  // Global accumulators (displayed values are derived, §8)
  private persistent let m_renownPoints: Float;
  private persistent let m_killDreadPoints: Float;
  private persistent let m_deedDreadPoints: Float;
  private persistent let m_heatPoints: Float;
  private persistent let m_archetype: array<Float>;       // index = ECBArchetype
  private persistent let m_primaryArchetype: Int32;       // -1 = Unknown

  private persistent let m_factions: array<ref<CBFactionState>>;
  private persistent let m_districts: array<ref<CBDistrictState>>;
  private persistent let m_deedsDone: array<CName>;
  private persistent let m_titles: array<CName>;
  private persistent let m_activeTitle: CName;            // n"" = auto
  private persistent let m_stats: ref<CBStats>;
  private persistent let m_rumors: array<ref<CBRumor>>;           // cap 64
  private persistent let m_rivals: array<ref<CBRival>>;           // cap 15 active + 32 archived
  private persistent let m_log: array<ref<CBLogEntry>>;           // cap 200, FIFO
  private persistent let m_appliedLedgerIds: array<Int32>;        // cap 100
  private persistent let m_cooldowns: ref<CBCooldowns>;
  private persistent let m_peaceDeals: array<ref<CBPeaceDeal>>;   // cap 16
}
```

```swift
public class CBFactionState {
  public persistent let id: CName;                 // n"TygerClaws"
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
}

public class CBDistrictState {
  public persistent let id: CName;                 // n"Watson"
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
}

public class CBRumor {
  public persistent let id: Int32;
  public persistent let kind: CName;               // n"Massacre", n"BossKill", n"Deed", …
  public persistent let magnitude: Float;
  public persistent let origin: CName;             // district id
  public persistent let faction: CName;            // n"" if none
  public persistent let createdAt: Float;
  public persistent let lastSpreadAt: Float;
  public persistent let hops: Int32;               // max 2
  public persistent let witnessed: Bool;
  public persistent let reached: array<CName>;     // districts already reached
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

public class CBRivalEvent {
  public persistent let kind: Int32;               // ECBRivalEventKind
  public persistent let at: Float;
  public persistent let district: CName;
  public persistent let detail: Int32;             // e.g. allies killed
}

public class CBLogEntry {
  public persistent let kind: CName;               // n"Deed", n"Massacre", n"Title", …
  public persistent let at: Float;
  public persistent let district: CName;
  public persistent let faction: CName;
  public persistent let value: Float;
  public persistent let refId: Int32;              // deed index / rival id / title index
}

public class CBCooldowns {
  public persistent let lastWhisperAt: Float;      // real-time cooldowns are NOT persisted
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
```

### 6.3 Global state (`CyberbaneService`)

```swift
public class CyberbaneService extends ScriptableService {
  private persistent let m_schemaVersion: Int32;
  private persistent let m_nextLedgerId: Int32;
  private persistent let m_ledger: array<ref<CBLedgerEntry>>;   // cap 100 total, 30 per playthrough, FIFO
}

public class CBLedgerEntry {
  public persistent let id: Int32;
  public persistent let playthroughId: CName;
  public persistent let at: Float;                 // game seconds at death
  public persistent let district: CName;
  public persistent let killerRecordID: TweakDBID;
  public persistent let killerAppearance: CName;
  public persistent let killerFaction: CName;
  public persistent let killerRivalId: Int32;      // -1 if the killer was not a Rival
  public persistent let method: Int32;             // ECBKillMethod used on V
}
```

The Service must never hold references to game objects ✅ (Codeware guidance).

### 6.4 Enums

```swift
enum ECBArchetype { Butcher = 0, Ghost = 1, Professional = 2, Chromed = 3, Netrunner = 4, Brawler = 5 }
enum ECBVictimClass { Civilian = 0, Ganger = 1, Elite = 2, Officer = 3, Boss = 4, Cop = 5, MaxTac = 6, Corpo = 7, Cyberpsycho = 8, Rival = 9 }
enum ECBKillMethod { Firearm = 0, Headshot = 1, Blade = 2, Blunt = 3, Fists = 4, Quickhack = 5, Explosive = 6, Vehicle = 7, Finisher = 8, Dismember = 9, Environmental = 10 }
enum ECBRivalSource { Survivor = 0, Spared = 1, Killer = 2, Avenger = 3, Hunter = 4 }
enum ECBRivalState { Active = 0, Hunting = 1, Dormant = 2, Slain = 3, Retired = 4, Debtor = 5 }
enum ECBRivalEventKind { Created = 0, Escaped = 1, Promoted = 2, KilledV = 3, SparedByV = 4, Slain = 5, Retired = 6 }
enum ECBRenownTier { Nobody = 0, LocalName = 1, KnownMerc = 2, Notorious = 3, Infamous = 4, Legend = 5 }
enum ECBCivTier { Normal = 0, Notice = 1, Uneasy = 2, Afraid = 3, Terror = 4 }
enum ECBPosture { Allied = 0, Friendly = 1, Neutral = 2, Hostile = 3, Vendetta = 4 }
```

### 6.5 Caps (hard limits)

| Collection | Cap | Overflow policy |
|---|---|---|
| Rumors | 64 | Drop oldest expired, then oldest |
| Legend Log | 200 | FIFO, but entries of kind `Title` and `Deed` are never dropped before others |
| Active Rivals | `settings.maxRivals` (≤ 15), ≤ 3 per faction | Retire the lowest-rank, oldest Rival |
| Archived Rivals | 32 | FIFO |
| Rival history | 10 per Rival | FIFO |
| Applied ledger ids | 100 | FIFO |
| Ledger (global) | 100 total, 30 per playthrough | FIFO |
| Recognition cache | 256 entries (memory only) | LRU |

Target save-size impact is **under 64 KB**.

---

## 7. Signals (inputs)

### 7.1 Combat & encounters

#### 7.1.1 Hooks

| Signal | Source | Status |
|---|---|---|
| NPC death with instigator | NPC `OnDeath` with `gameDeathEvent` (`instigator`) | 🔎 S-01 |
| NPC defeated / unconscious (non-lethal) | defeated/unconscious handling on NPC puppets | 🔎 S-01 |
| Hits on NPCs and on V | `OnHit`-family handlers, hit/attack data (weapon, body part, damage) | 🔎 S-01 |
| Dismemberment | dismemberment events | 🔎 S-01 |
| Finishers / takedowns | finisher and takedown events | 🔎 S-01 |
| Player death | player death event (instigator / last damage source within 3 s) | 🔎 S-01 |
| Combat state | player combat state changes | 🔎 S-01 |

#### 7.1.2 Attribution and classification

- **Counts only if V is the instigator**: V's weapons, quickhacks, V's grenades, V's vehicle, and V's own hacked turrets or drones. Companion kills (Panam, Takemura, etc.) **do not count**.
- **Victim faction**: character record affiliation (`gamedataAffiliation` 🔎) mapped to a Cyberbane faction id through the faction registry (§14).
- **Victim class** (first match wins):
  1. Cyberbane Rival (by tag) → `Rival`
  2. Cyberpsycho (record tag or registry list, S-01) → `Cyberpsycho`
  3. MaxTac → `MaxTac`
  4. NCPD → `Cop`
  5. Crowd or civilian (`IsCrowd` / civilian checks 🔎) → `Civilian`
  6. Rarity (`gamedataNPCRarity` 🔎): Boss → `Boss`, Elite → `Elite`, Officer → `Officer`
  7. Corporate security faction → `Corpo`
  8. Otherwise → `Ganger`
- **Method flags** (several can apply): Headshot, Blade, Blunt, Fists, Firearm, Quickhack, Explosive, Vehicle, Finisher, Dismember, Environmental. A **brutal** kill is any of Finisher, Dismember, Blade or Fists.
- **Stealth**: the kill or takedown happened while the victim was not in combat with V (S-01).

#### 7.1.3 Encounter tracker

- **Start**: player enters combat, or the first hostile hit between V and any NPC.
- **End**: 20 s with V out of combat, or V more than 150 m from every living participant.
- **Tracks**: participants (EntityIDs of NPCs hostile to or targeting V), kills (with timestamps and methods), defeats, fled participants, V's damage taken, duration, district, factions involved, civilians killed.
- **Derived flags on resolve:**

| Flag | Rule (defaults) |
|---|---|
| `Massacre` | ≥ 6 kills within any 30 s window, **or** ≥ 10 kills in the encounter |
| `Flawless` | ≥ 4 kills and V took < 5% of max HP |
| `Collateral` | ≥ 1 civilian killed by V |
| `Routed` | ≥ 2 participants broke morale and fled (§9.4) |
| `BossDown` | a Boss-class victim was killed or defeated |

#### 7.1.4 Witnesses

Approximation, documented as a heuristic:
- Witness candidates are surviving participants, crowd NPCs within 25 m who entered a fear state during the encounter, and NCPD units that responded.
- An event is **witnessed** if at least one witness candidate is alive at encounter end, or despawned while alive.
- Unwitnessed kills still hurt the victim's faction (bodies are found) at reduced weight, and add to Dread at 0.5× (§8).

### 7.2 Deeds (quests, gigs, hustles)

#### 7.2.1 Source

- Quest entry states from `JournalManager` 🔎 (`GetEntryState` 🔎). Branching outcomes use quest facts (`QuestsSystem.GetFact` 🔎). See S-02.
- Change detection uses journal notifications if available (S-02). The fallback is to poll unfinished deeds on the slow tick. The deed list is about 100 entries, so polling is cheap.

#### 7.2.2 Deed definition

| Field | Type | Meaning |
|---|---|---|
| `id` | CName | `n"DEED_HEIST"` |
| `journalPath` | String (content only, not persisted) | Quest/objective path (S-02) |
| `requiredState` | enum | Succeeded / Failed / Any-finished |
| `factCondition` | optional (fact name, op, value) | Outcome branches, e.g. Royce killed |
| `renown` | Float | Renown points |
| `dread` | Float | Deed-dread points |
| `archetype` | array of (archetype, delta) | Archetype nudges |
| `factions` | array of (faction, standing delta, renown delta) | Faction effects |
| `district` | CName | Where rumors originate |
| `rumor` | Float | Rumor magnitude |
| `titles` | array<CName> | Titles unlocked directly |
| `logKey` | loc key | Legend Log text |
| `whisperTopic` | loc key | How NPCs refer to it ("the Konpeki job") |

The seed list is in Appendix F.

#### 7.2.3 Generic deeds

- **Gig completed**: +20 Renown, Professional +3, standing effects only if the gig's target faction is known (S-02).
- **NCPD hustle completed**: +5 Renown, NCPD standing +1.5, Professional +1.
- **Cyberpsycho Sighting**: killed gives +15 Renown and +5 kill-dread. Pacified gives +20 Renown, NCPD +3 and Ghost +2.

#### 7.2.4 Bootstrap (first run on an existing save)

1. Scan every deed and apply all completed ones **silently** (no toasts, one summary log entry: "Before Cyberbane…").
2. Set the Renown floor from Street Cred (§8.1).
3. Estimate prior kills for display only: `estimatedPriorKills = 6 × playerLevel + 2 × streetCred`. Seed `killDreadPoints = 0.5 × estimatedPriorKills` (an approximation, shown as "~").
4. Seed archetype accumulators from the deeds and from current chrome.
5. Apply lifepath baselines (Appendix B).
6. Set `m_bootstrapped = true`.

### 7.3 Chrome (C)

- **Equipped cyberware per equipment area** via `EquipmentSystem` 🔎. Areas ✅🔎: `ArmsCW`, `HandsCW`, `EyesCW`, `FrontalCortexCW`, `NervousSystemCW`, `MusculoskeletalSystemCW`, `CardiovascularSystemCW`, `ImmuneSystemCW`, `IntegumentarySystemCW`, `SystemReplacementCW`, `LegsCW`.
- **Capacity**: in 2.x the internal stat for cyberware capacity is named "Humanity". The names `HumanityAllocated`, `HumanityTotalMaxValue`, `HumanityOverallocated` and `HumanityAvailable` 🔎 exist. Over-allocation corresponds to the Edgerunner perk.
- **Formula:**

```
usage      = clamp(HumanityAllocated / HumanityTotalMaxValue, 0, 1.5)
implantSum = Σ implantScore(item) × tierMult(item)            (cap 35)
C          = clamp( 55 × min(usage, 1) + implantSum + (overallocated ? 10 : 0), 0, 100 )
C_visible  = clamp( Σ visibleImplantScore × tierMult × 2.5 + faceChromeScore, 0, 100 )
```

- `tierMult`: Tier 1 0.60 · Tier 2 0.75 · Tier 3 0.90 · Tier 4 1.00 · Tier 5 1.10 · Tier 5+ / 5++ 1.20 · Iconic +0.10 (S-11).
- Scores per implant family are in Appendix D, matched by record family (S-11).
- **Recompute** on equip events (`ItemAddedToSlot` / `OnItemEquipped` 🔎) and on every slow tick as a safety net.
- **Combat cyberware activation** (Berserk, Sandevistan, Kerenzikov, Optical Camo) is detected via status effects (S-12) and raises `CB_CombatCyberwareActivated`.

### 7.4 Look (L)

- **Sources**:
  - equipped clothing in visual slots (head, face, outer torso, inner torso, legs, feet)
  - the active wardrobe outfit, if any, which wins over equipped items (S-10)
  - Equipment-EX outfits when installed (optional, S-10)
  - character creator options: face cyberware, scars, face tattoos, eyes, teeth. The Character Customization system 🔎 is re-read on load and on mirror/ACU changes (S-10).
- **Scoring**: exact record id first, otherwise visual tags (`GetVisualTags` 🔎) mapped to scores (Appendix E).
- **Formula**: `L = clamp( min(Σ clothingScore, 60) + min(Σ customizationScore, 40), 0, 100 )`
- **Disguise** `Dg = clamp(Σ disguise(item), 0, 0.6)`. Examples: full mask 0.25, hood or cap 0.10, sunglasses or visor 0.05.
- **Faction colors**: wearing ≥ 2 items tagged with faction X counts as wearing X's colours (§11.2).

### 7.5 Street Cred & level

`GetPlayerStreetCred` 🔎. Used as the Renown floor (§8.1) and in bootstrap.

### 7.6 Police heat

- Heat stage via `PreventionSystem` 🔎 (`HeatLevel` / `GetHeatStage` 🔎).
- Each time V reaches heat stage *n*: `heatPoints += n²`. A MaxTac encounter adds +15.

### 7.7 Momentary player state

Weapon drawn and weapon class, arm cyberware deployed, combat cyberware active, in combat, recent kills nearby, current heat stage, in vehicle, in a scene or workspot, in braindance (S-13).

### 7.8 Time & place

- Current district via the district APIs (`GetCurrentDistrict` / `District_Record` 🔎, S-06), mapped to Cyberbane district ids (Appendix C).
- Safe zones (`SafeZone` / `IsInSafeZone` 🔎).
- Game time via `TimeSystem` 🔎 (S-17).

---

## 8. Scoring model

All constants are defaults that live in `Core/Config.reds`. They are scaled by the settings multipliers (§13). Consolidated table: Appendix A.

### 8.1 Renown (R, 0–1000)

**Renown points per event:**

| Event | Points |
|---|---|
| Witnessed kill: Ganger / Elite / Officer / Boss | 1.5 / 3 / 6 / 30 |
| Witnessed kill: Cop / MaxTac / Corpo | 2 / 12 / 2 |
| Civilian kill | 0 (adds Dread only) |
| Cyberpsycho killed / pacified | 15 / 20 |
| Rival slain | 25 + 10 × rank |
| Encounter flags (witnessed): Massacre / Flawless / BossDown | +10 / +5 / +10 |
| Deed | per table |
| Gig / hustle | 20 / 5 |
| Title unlocked | 25 (Cyberbane: 100) |

Unwitnessed events earn **0.25×**.

```
R_raw = 1000 × (1 − exp(−renownPoints / 2500))
R     = max(R_raw, 14 × streetCred)        // floor; setting can disable it
```

| Tier | R |
|---|---|
| Nobody | 0–99 |
| Local Name | 100–249 |
| Known Merc | 250–449 |
| Notorious | 450–649 |
| Infamous | 650–849 |
| Legend | 850–1000 |

Sanity check: a full playthrough gives roughly 1,500 (main deeds) + 1,750 (≈70 gigs) + 500 (hustles) + 1,250 (kills) ≈ 5,000 points, so R ≈ 865, which is Legend near the end.

### 8.2 Dread (D, 0–100)

```
K = 100 × (1 − exp(−killDreadPoints / 600))     // body count & brutality
C = chrome (live, §7.3)
L = look (live, §7.4)
X = 100 × (1 − exp(−deedDreadPoints / 400))     // terrifying deeds
H = 100 × (1 − exp(−heatPoints / 150))           // police history

D = clamp(0.35K + 0.20C + 0.15L + 0.20X + 0.10H, 0, 100)
```

**Kill-dread points:**

| Victim | Points | Method bonus | Points |
|---|---|---|---|
| Ganger | 1 | Blade / Fists / Blunt | +0.5 |
| Elite | 2 | Finisher | +1 |
| Officer | 3 | Dismember | +1 |
| Boss | 12 | Explosive | +0.5 |
| Cop | 2 | Quickhack | +0.3 |
| MaxTac | 8 | | |
| Civilian | 5 | | |
| Cyberpsycho (killed) | 5 | | |
| Massacre flag | +10 | | |

Unwitnessed events earn **0.5×**.

**Civilian-perceived dread:**

```
mercyRatio = nonLethal / max(1, nonLethal + lethalKills)
D_civ      = D × civMult[primaryArchetype] × (1 − 0.3 × mercyRatio)
civMult    = Butcher 1.20 · Chromed 1.15 · Brawler 1.00 · Netrunner 0.95 · Professional 0.85 · Ghost 0.75 · Unknown 1.00
```

### 8.3 Archetypes

| Event | Butcher | Ghost | Professional | Chromed | Netrunner | Brawler |
|---|---|---|---|---|---|---|
| Lethal kill | +1 | | | | | |
| Brutal kill (extra) | +1 | | | | | +0.5 if fists/blunt |
| Civilian kill | +5 | | −3 | | | |
| Non-lethal defeat | | +1.5 | | | | |
| Stealth kill / takedown | | +1 | | | | |
| Quickhack kill | | | | | +1 | |
| Quickhack non-lethal | | +0.5 | | | +0.5 | |
| Fists / blunt kill | | | | | | +1 |
| Gig completed | | | +3 | | | |
| Hustle completed | | | +1 | | | |
| Combat cyberware activation (60 s cooldown) | | | | +0.5 | | |
| Per in-game hour with C ≥ 60 | | | | +C/100 | | |
| Deed-specific | per table | | | | | |

- Every accumulator decays ×0.995 per in-game day, so recent behaviour dominates.
- **Primary archetype**: if the total is under 30 → Unknown. Otherwise it is the argmax, and it only switches when the new top value is ≥ 1.25 × the current primary's value (hysteresis).

### 8.4 Factions

**Standing S_f (−100…100)**, starting at the profile baseline plus lifepath/deed modifiers (Appendix B).

| Event (involving a faction member) | ΔS_f |
|---|---|
| Witnessed kill: Ganger / Elite / Officer / Boss | −2 / −4 / −6 / −25 |
| Unwitnessed kill | ×0.25 |
| Non-lethal defeat | ×0.5 of the lethal value |
| Killing a member of one of the faction's **rivals** | +0.5 (cap +2 per in-game day per faction) |
| Gig for / against the faction | per deed (default ±5) |
| Tribute received | +5 |
| Peace brokered | S_f = max(S_f, −20) |
| Daily drift toward baseline | 1/day if S_f > −70; 0.25/day if ≤ −70 |

**Posture** from S_f: Allied ≥ 50 · Friendly 15…49 · Neutral −29…14 · Hostile −69…−30 · Vendetta ≤ −70.

**Faction Renown RF_f (0–100):** witnessed kill +1, brutal +2, massacre +10, boss +20, Rival slain +10. Rumor arrival in the faction's turf adds +0.25 × magnitude. Decays 0.5/day, never below 10% of peak.

**Faction Fear F_f (0–100):**
```
F_f = clamp( D × dreadSens_f × (0.35 + 0.65 × RF_f/100) + (C − 50) × chromeAttitude_f × 0.3 , 0, 100 )
```
`chromeAttitude_f`: positive means chrome scares them, negative means chrome earns respect instead (Maelstrom = −1.0).

**Faction Respect P_f (0–100):**
```
share_a = archetype_a / Σ archetype
P_f = clamp( (R/10) × (0.4 + 0.6 × RF_f/100) × (1 + Σ_a respect_f[a] × share_a)
             + max(0, −chromeAttitude_f) × max(0, C − 50) × 0.4 , 0, 100 )
```

### 8.5 Districts & rumors

- **District Renown RD_d (0–100)**: a rumor arriving adds its magnitude. Decays 1/day, never below 20% of peak.
- **Rumor magnitudes**: witnessed kill 0.5 · brutal kill 1 · massacre 8 · boss kill 15 · deed (per table, default 20) · Rival slain 6 · cyberpsycho 4 · tribute 2.
- **Origin**: applied immediately in the origin district (×1.0 if witnessed, ×0.3 if not).
- **Spread**: every 6 in-game hours, each live rumor spreads to adjacent districts (Appendix C) at 50% magnitude, up to 2 hops. Rumors expire after 3 in-game days.
- Small events (single kills) are **aggregated** into one rumor per district per in-game hour to respect the rumor cap.

### 8.6 Aura (A, 0–40)

| Condition | +A |
|---|---|
| Weapon drawn | +8 (blade, heavy weapon or arm cyberware deployed: +12 instead) |
| Combat cyberware active | +15 |
| In combat | +8 |
| Each kill within 40 m in the last 60 s | +4 (cap +16) |
| Heat stage ≥ 3 | +6 |

Clamp to 40. In **Low Profile** (§11.1), A = 0.

### 8.7 Recognition

Rolled **once per NPC per spawn** and cached by EntityID for 10 real minutes.

```
distinct = max(C_visible, L) / 100
p = 0.05 + 0.55 × RD_d/100 + 0.25 × R/1000 + 0.15 × distinct − Dg
p += (npc in faction f) ? 0.20 × RF_f/100 : 0
p += (npc is NCPD and H > 50) ? 0.10 : 0
p *= LowProfile ? 0.5 : 1
p = clamp(p, 0, 0.95)          // Rivals always recognize V (p = 1)
```

### 8.8 Perceived threat & effective fear

```
appearanceThreat = 0.5 × L + 0.3 × C_visible            // "looks like trouble", even when anonymous
base = recognized ? (factionMember ? F_f : D_civ) : 0
T    = clamp( max(base, appearanceThreat) + A, 0, 100 )
E    = T/100 − courage
```

**Courage by NPC type:**

| Type | Courage |
|---|---|
| Civilian | 0.10 |
| Ganger Trash / Weak | 0.30 |
| Ganger Normal | 0.40 |
| Ganger Rare | 0.50 |
| Officer | 0.65 |
| Elite | 0.75 |
| Boss | 0.95 |
| Cop | 0.55 |
| Corpo security | 0.50 |
| MaxTac, Rival, Cyberpsycho, quest NPCs | immune |

Modifiers: own turf +0.10 · each ally within 15 m +0.05 (cap +0.20) · faction profile `courageMod`.

### 8.9 Decay summary (per in-game day)

| Value | Decay |
|---|---|
| Deed renown points | none |
| Kill renown points | −1% |
| Kill-dread points | −0.5% (−1% while Laying Low) |
| Heat points | −2% (−4% while Laying Low) |
| RD_d | −1 (floor 20% of peak) |
| RF_f | −0.5 (floor 10% of peak); ×2 while Laying Low |
| S_f | drift toward baseline (§8.4) |
| Archetypes | ×0.995 |
| C, L | live values, no decay |
| Titles | never lost |

### 8.10 Worked example

V: R = 520 (Notorious), D = 62, primary archetype Butcher, mercyRatio 0.1, in Watson with RD = 70, no disguise, L = 40, C_visible = 30. A Tyger Claws Normal ganger in Kabuki (TC turf) with 2 allies nearby. TC: RF = 60, dreadSens 1.0, chromeAttitude +0.2, C = 65.

- Recognition: p = 0.05 + 0.385 + 0.13 + 0.06 + 0.12 = **0.745**. Roll: recognized.
- F_TC = 62 × 1.0 × (0.35 + 0.39) + (65 − 50) × 0.2 × 0.3 = 45.9 + 0.9 = **46.8**.
- appearanceThreat = 20 + 9 = 29. A (weapon drawn) = 8. **T = 54.8**.
- Courage = 0.40 + 0.10 (turf) + 0.10 (2 allies) = 0.60. **E = −0.05**.
- If S_TC = −40 (Hostile), the gang matrix (§9.3) gives **Warn → Hostile**. If V holsters the weapon, T = 46.8 and E = −0.13: still Warn.

---

## 9. Reactions (outputs)

### 9.1 Reaction Director

- `CBNpcRegistry` holds attached NPC puppets, maintained by Codeware `Entity/Attached` and `Entity/Detached` callbacks ✅. (The Codeware docs show both `Entity/Attach` and `Entity/Attached` in different places; confirm the correct name in S-01.)
- On each fast tick: take up to **12 nearest** registered NPCs within 30 m, round-robin across ticks. For each:
  1. **Safety Gate** (§16). Skip on fail.
  2. Classify: civilian, ganger (faction), cop, vendor, corpo, other.
  3. Recognition (cached), T, E.
  4. Choose a reaction from the module's rules. Apply only if the NPC is off its per-NPC cooldown (30 s) and global budgets allow it.
- **Global budgets**: max 6 civilians in a Cyberbane-induced fear state at once (setting) · max 1 whisper per 25 s · max 1 gang escalation per 5 s · max 8 Cyberbane-spawned NPCs alive.

### 9.2 Civilians

| Tier | T | Behaviour | Implementation |
|---|---|---|---|
| Normal | < 20 | none | – |
| Notice | 20–39 | Whisper chance 15% | Text only |
| Uneasy | 40–59 | Moves out of V's path within 4 m. Whisper chance 30% | Mild crowd fear stage / walk away (S-03) |
| Afraid | 60–79 | Cowers or flees when V is within 6 m or has a weapon drawn | Crowd fear stage, run (S-03) |
| Terror | ≥ 80 | Flees on sight within 15 m and spreads fear (10 m) | Fear stage + `SpreadFear` 🔎 |

- Drivers: if T ≥ 80, a weapon is drawn and V is within 10 m of an occupied car → panic driving (`TriggerPanicDrivingEvent` 🔎).
- Fear VO comes from the game's own fear behaviours (`TriggerFearRunningVO` 🔎). No custom audio.
- **Professional / Ghost** archetypes with high Renown can trigger **admiring** whispers instead of fear when D_civ < 40.
- Civilians never call police because of Cyberbane-induced fear alone (no crime is attributed to V).

### 9.3 Gangs: behaviour matrix

| Posture \ E | E ≤ 0 | 0 < E ≤ 0.25 | 0.25 < E ≤ 0.5 | E > 0.5 |
|---|---|---|---|---|
| **Allied** | Respect | Respect | Give Way | Give Way |
| **Friendly** | Watch | Watch | Give Way | Back Off |
| **Neutral** | Ignore | Watch | Give Way | Back Off |
| **Hostile** | Warn → Hostile | Warn → Hostile | Warn → Back Off | Back Off / Flee |
| **Vendetta** | Hostile on sight | Hostile on sight | Hostile (morale −0.2) | Flee on sight, **unless** group ≥ 4 with an Officer present → Hostile |

Behaviours:
- **Ignore**: base game behaviour.
- **Watch**: no behaviour change. Whisper eligible.
- **Respect**: admiring or respectful whisper. Never hostile from Cyberbane.
- **Give Way**: roaming NPCs step out of V's path. NPCs in workspots are never moved (S-03).
- **Warn**: warning whisper plus existing bark if available. If V stays within 8 m for 6 s, escalate (only in Hostile or Vendetta posture). Leaving cancels it.
- **Back Off**: NPC walks away from V for about 20 m (S-04).
- **Hostile on sight**: per-NPC attitude toward the player set to hostile (S-05). Only for recognized NPCs, only outside safety contexts, and tracked for revert (§16.4).
- **Flee**: same as a morale break (§9.4).
- Unrecognized gang NPCs use base-game behaviour plus appearanceThreat reactions (Give Way / Back Off only).

### 9.4 Combat morale

- Each non-immune participant starts with `m = 1 − max(0, E) × 0.6`.

| Shock | Δm |
|---|---|
| Ally killed within 15 m | −0.10 |
| Ally killed brutally (finisher, dismember) | −0.20 |
| Group's Officer or Boss killed | −0.35 |
| V activates Berserk or Sandevistan | −0.15 |
| Outnumbered (≤ 1 ally left) | −0.20 |
| Faction posture Vendetta | −0.10 (once) |

- If `m < 0.25` the NPC **breaks**: it flees (S-04). If fleeing isn't available it cowers. At most one check per NPC per 2 s.
- At most 60% of a group can break (setting). Someone always stands and fights.
- **Immune**: Boss, Rival, MaxTac, Cyberpsycho, quest-flagged NPCs, mechs and drones, NPCs in scripted combat.
- A broken NPC that escapes (despawns alive, or is > 60 m away when the encounter resolves) becomes a **witness** and a **Rival candidate** (Survivor, §10.2).
- Morale intensity setting (0–2) scales all shocks.

### 9.5 NCPD

- **NCPD standing** uses the faction model, id `NCPD`. Hustles +1.5, pacified cyberpsychos +3, cop kills −3, civilian kills −2.
- **Recognition**: recognized officers produce police whispers. If H > 50, recognition gets +0.10.
- **Cop morale**: same model as §9.4 with Cop courage (setting, default on).
- **Known Offender** (default **off**): if D ≥ 70 and NCPD posture ≤ Hostile, the first crime escalates heat one extra stage (S-09b: PreventionSystem hook).
- **Friend of the Force** (default on): NCPD posture ≥ Allied means the first minor offense per in-game day draws no heat (S-09b).
- MaxTac is never affected.

### 9.6 Vendors

Price modifiers are stacked, then clamped to **−20% … +15%** (`maxDiscount` setting).

| Rule | Modifier |
|---|---|
| **Fear discount**: vendor recognized V and T ≥ 60 | −(T − 60)/40 × 12% |
| **Respect discount**: vendor's faction P_f ≥ 60 or S_f ≥ 50 | −5% (−8% if Allied) |
| **Legend**: R ≥ 850 | −3% |
| **Hostile faction vendor**: S_f ≤ −50 | +10% |
| **Intimidated today** (§11.3) | −15% |
| **Failed intimidation today** | +10% |

- Applied to buy prices. Sell prices get half the magnitude in V's favour.
- Hooked via the vendor price functions (`GetBuyPrice` / `GetSellPrice` 🔎, S-09).
- Vendors **never refuse service** in v1.
- Optional tooltip line: *"Cyberbane: fear discount −8%"* (S-09).

### 9.7 Fixers, messages & gig bonus

- **Message events**: renown tier up, first title, Cyberbane title, posture → Vendetta, vendetta ended, tribute, Rival created / slain / Debtor tip, peace brokered.
- **v1 delivery**: "incoming message" toast (sender + text) plus a Legend Log entry. **v2**: real phone threads (S-18).
- **Gig reward bonus** on gig completion: Notorious +250 €$, Infamous +500 €$, Legend +1,000 €$ (× setting). Paid via `TransactionSystem` 🔎, with a toast.

### 9.8 Tribute

- **Eligible**: −60 ≤ S_f ≤ 40, F_f ≥ 75, RF_f ≥ 50, faction is a gang (not a corp or NCPD).
- **Check**: daily. 25% chance. 7 in-game day cooldown per faction.
- **Amount**: `round50(500 + 2500 × (F_f − 75)/25) × tributeMult`.
- **Effects**: eddies paid, S_f +5, message toast, log entry, `tributes++`. Five tributes unlock the title "Feared Landlord".

### 9.9 Bounties & hit squads

- **Bounty** (flavour, shown in the Hub): while in Vendetta, `2000 + 200 × kills_f` €$.
- **Hit squad scheduler** (each in-game hour):
  - **Eligible**: posture ≤ Hostile, RF_f ≥ 30, V in the faction's turf or a public district, no safety context, faction cooldown 2 in-game days, global cooldown 45 real minutes.
  - **Chance**: `0.04 × (−S_f/70) × (RF_f/100) × frequencyMult`.
  - **Size**: `3 + floor(−S_f/35)`, capped at 6, plus 1 if R ≥ Infamous.
  - **Composition**: from the faction's record pool by tier (Appendix B).
  - **Spawn**: ≥ 50 m from V, `spawnInView = false` ✅, on a valid navmesh point (S-08). Tagged `Cyberbane`, `CB_Squad`, `CB_Squad_<n>`. Non-persistent.
  - **Behaviour**: hostile toward V and moving toward V (S-04/S-05).
  - **Despawn**: after 5 in-game minutes unengaged, or when V is more than 300 m away.
  - If the squad leader escapes → Hunter Rival candidate (§10.2).
- Vehicle-borne squads are v2.
- They Will Remember compatibility mode disables Cyberbane hit squads (§17).

### 9.10 Whispers (text-only overheard lines)

- **Trigger**: a recognized NPC within 10 m, not in combat, with T ≥ 20 (or posture Allied/Vendetta), passing the 25 s global cooldown and once per NPC per spawn. 35% chance per eligible NPC per tick. Only one whisper on screen at a time.
- **Display**: subtitle-style line at lower centre, separate from game subtitles. Speaker label ("Passerby", "Tyger Claw", "NCPD Officer", "Vendor"). Shown for 4 s, then fades.
- **Selection**: template pool keyed by `(speakerType, mood, tier)`. Mood comes from the reaction: fear, respect, hate, admire or curious. Topic is weighted:

| Topic | Weight | Condition |
|---|---|---|
| Recent deed (last 3 in-game days) | 40 | any |
| Famous deed (highest renown) | 25 | any |
| Faction losses | 30 | speaker's faction lost ≥ 10 to V |
| Chrome | 15 | C ≥ 60 |
| Look | 10 | L ≥ 60 |
| Rival | 15 | Rival exists in speaker's faction |

- **Tokens**:
  - `{TITLE}`
  - `{V}`: "the merc" below Infamous; the title or "V" at Infamous and above
  - `{SUBJ}` `{OBJ}` `{POSS}` `{IS}`: pronouns
  - `{DEED}`, `{DISTRICT}`, `{FACTION}`, `{COUNT}`, `{IMPLANT}`, `{RIVAL}`
- **Pronouns**: Auto derives them from V's voice tone (`GetResolvedGenderName` 🔎, S-13). Settings can override with He, She or They.
- Examples: Appendix H.

---

## 10. Rivals & the Death Ledger

Cyberbane's named recurring enemies are called **Rivals** throughout the code, UI and mod page (§26).

### 10.1 Rules

- Caps: `maxRivals` active (default 8, max 15), ≤ 3 per faction, one promotion per in-game day.
- Never created from quest NPCs, unique characters, companions or AMM-spawned NPCs (§16).
- All Rival spawns are **transient** (`persistSpawn = false`, `persistState = false`). The *data* persists in `CBRival`, and each encounter respawns the Rival from the snapshot.

### 10.2 Sources

| Source | Trigger | Requirement | Chance |
|---|---|---|---|
| **Survivor** | Participant fled and escaped an encounter where V killed ≥ 3 of its group | rarity ≥ Normal | 15% |
| **Spared** | Defeated non-lethally and left alive at encounter end | rarity ≥ Rare | 20% (gains the trait *Humiliated*) |
| **Killer** | Killed V (via Death Ledger, §10.8) | any; 100% if rarity ≥ Normal, else 50% | as stated |
| **Avenger** | V killed an Officer or Boss (non-quest) | faction has a free Rival slot | 15%, appears after 1–3 in-game days |
| **Hunter** | Hit-squad leader escaped | – | 50% |

### 10.3 Identity snapshot

- `recordID` (character record), `appearance` (current appearance name, S-01), `faction`, `origin` district, creation time.
- **Name**: first and last name indices from the faction's name pool, plus an **epithet** chosen by source or event. Generated deterministically from `seed = rival.id`.
- **On-screen name**: in v1 the name appears on the Rival Card, in whispers and in the Hub. Nameplate names are S-07 (TweakDB runtime records plus Codeware localization). If S-07 fails, nameplates stay generic.

### 10.4 Ranks

| Rank | Name | Health | Damage | Armor | Extra |
|---|---|---|---|---|---|
| 1 | Marked | +25% | +8% | +10 | 1 trait |
| 2 | Veteran | +50% | +16% | +20 | 2 traits |
| 3 | Lieutenant | +75% | +24% | +30 | 3 traits, brings 2–4 grunts |
| 4 | Warlord | +100% | +32% | +40 | 4 traits, brings 3–5 grunts, can hunt anywhere public |

Stat modifiers are applied on spawn through the stats system (`StatModifier` / `AddModifier` 🔎). The exact stat types are confirmed in S-01.

### 10.5 Traits & weaknesses (data-driven)

| Trait | Effect |
|---|---|
| Tough | +30% Health |
| Armored | +20 Armor |
| Deadeye | +15% weapon damage |
| Quick | +10% movement speed (S-01: stat availability) |
| Pack Leader | +2 grunts per encounter |
| Grudge-Bearer | +15% damage vs V |
| Hard to Scare | Morale immunity for the Rival's grunts while the Rival lives |
| Chromed-Out | Uses a chromed appearance variant if one exists for the record (cosmetic) |
| Scarred | Cosmetic plus epithet. Gained after escaping below 20% HP |
| Confident | Gained after killing V: +10% damage, removes *Shaken* |
| Humiliated | From Spared: +10% damage vs V, taunts reference the defeat |

| Weakness | Effect |
|---|---|
| Shaken | Grunts start with morale −0.2 |
| Old Wound | Takes +20% damage from one damage family (chosen at creation) |
| Reckless | −10% accuracy (S-01: stat availability) |

Promotion adds +1 trait. Escaping badly hurt adds *Scarred* and a 50% chance of a weakness.

### 10.6 State machine

```
         create
           │
           ▼
 ┌──────► Active ──schedule──► Hunting ──spawn──► (encounter)
 │                                                   │
 │   ┌──────────────┬──────────────┬─────────────────┼──────────────────┐
 │   ▼              ▼              ▼                 ▼                  ▼
 │ Escaped       Killed V      Spared by V         Slain            Despawned
 │ (rank up)     (rank up,     (sparedByV++;       (archive;        (no contact:
 │   │            Confident)    2nd spare →         Avenger 15%)     back to Active)
 │   │              │           50% Debtor /
 │   │              │           50% rank up)
 └───┴──────────────┴──────────────┘
 Retired: cap overflow, or Debtor after its tip message.
 Dormant: setting disabled, or faction peace deal (wakes on Hostile).
```

**Debtor**: sends one tip message with a 1,000 €$ gift, then retires. This is the redemption path.

### 10.7 Encounters

- **Types**:
  - *Ambush*: Rival plus grunts close in on V in the Rival's turf.
  - *Sighting*: Rival is visible among a gang in their turf, marked on the map within 200 m (S-14b: mappins via `MappinSystem` 🔎). V chooses whether to engage.
  - *Showdown*: Warlord-rank challenge to a location (v2).
- **Scheduling** (each in-game hour):
  - **Eligible**: V in the Rival's faction turf, or the Rival is rank 4 and V is in any public district.
  - **Chance**: 10% + 5% × rank.
  - **Cooldowns**: per-Rival `nextEligibleAt` (1–2 in-game days), global 60 real minutes and 1 in-game day.
  - Never in safety contexts.
- **Spawn** with `DynamicEntitySpec` ✅:

```swift
let spec = new DynamicEntitySpec();
spec.recordID = rival.recordID;
spec.appearanceName = rival.appearance;
spec.position = spawnPos;              // S-08
spec.orientation = spawnRot;
spec.persistState = false;
spec.persistSpawn = false;
spec.spawnInView = false;
spec.tags = [n"Cyberbane", n"CB_Rival", StringToName("CB_Rival_" + IntToString(rival.id))];
let id = GameInstance.GetDynamicEntitySystem().CreateEntity(spec);   // accessor per Codeware docs
```

- **Rival Card** (UI) on first sighting within 30 m: name, epithet, faction, rank, two history lines, traits.
- **Taunts**: Rival-specific whisper templates that reference history ("Remember Kabuki, {TITLE}? I do.").
- **Outcomes** follow §10.6. Rival slain gives +Renown, +RF, a rumor (magnitude 6), title progress and an Avenger roll.

### 10.8 Death Ledger (cross-save)

**Problem:** when V dies, the game reloads an earlier save, and per-save state rolls back. A "Killer" Rival would never exist.

**Solution:**
1. On `CB_PlayerDied`: build a `CBLedgerEntry` (killer snapshot, district, method, playthroughId) and write it **immediately** to `CyberbaneService` (global).
2. On every session start or save load: for each ledger entry where `playthroughId == m_playthroughId` and `id ∉ m_appliedLedgerIds`, create a Killer Rival (or promote the existing Rival if `killerRivalId` matches), add a log entry *"You died in {DISTRICT}. {RIVAL} remembers."*, then add the id to `m_appliedLedgerIds`.
3. Consequence (by design): **any** save in that playthrough learns about deaths that happened after it. Document this as "Night City remembers your deaths". Setting `deathsRemembered` (default on) turns the whole feature off.
4. **Playthrough ID**: created on first run as `n"CB_" + 8 random hex chars`. Loading a save that predates Cyberbane creates a new ID, which is a separate line. That is acceptable.
5. Within a session the Service lives in memory, so reload-after-death works. Writing to disk across game restarts depends on Codeware's flush timing (S-15).

---

## 11. Player agency

### 11.1 Low Profile

- **Enter**: weapon holstered ≥ 30 s, not in combat, no combat cyberware active, arm cyberware retracted, **and** Dg ≥ 0.25.
- **Effect**: A = 0, recognition × 0.5, whisper chance × 0.5.
- **Exit**: immediately on drawing a weapon, entering combat or activating combat cyberware.
- Small HUD icon (setting).

### 11.2 Disguises & faction colours

- Disguise items lower recognition (§8.7).
- **Wearing faction X's colours** (≥ 2 tagged items):
  - Among X with S_X > −70: recognition −0.30, and X's posture is evaluated one step friendlier.
  - In the turf of one of X's rivals: that faction's posture is evaluated one step more hostile.
- Setting `factionDisguises` (default on).

### 11.3 Intimidate (optional: Native Interactions Framework)

- An interaction choice on NPCs within 3 m while V is not in combat. Integration via NIF's API (S-16b).
- Success chance: `clamp(0.2 + 0.8 × T/100 − courage, 0.05, 0.95)`.

| Target | Success | Failure |
|---|---|---|
| Civilian | Flees (no crime) | Nothing |
| Ganger (Hostile posture or worse) | Group backs off; no aggro for 2 real minutes | Group turns hostile |
| Vendor | −15% for the rest of the in-game day | +10% for the rest of the in-game day |
| Rival | Always fails; Rival taunts | – |

Cooldowns: 1 in-game day per vendor, 60 s per NPC.

### 11.4 Broker peace

- **Hub action**: "Make peace with {FACTION}".
- **Requirements**: not in combat, no Boss of that faction killed within 3 in-game days, 7-day cooldown per faction.
- **Cost**: `1500 + 100 × max(0, −S_f)` €$. NCPD costs ×1.5 ("fines"). **Corporations cannot be bought** (Arasaka, Militech, Kang Tao).
- **Effect**: S_f = max(S_f, −20), RF_f −20, that faction's active Rivals go Dormant. Log entry and message.

### 11.5 Laying Low

No kills and no non-lethal takedowns for 3 in-game days doubles the decay of kill-dread, heat and faction renown (§8.9) until the next combat kill.

---

## 12. User interface

All UI is built with **Codeware UI** in code (no archive assets in v1). It follows the game's fonts and colours, and all text goes through localization (§15).

### 12.1 Cyberbane Hub

- **Open**: hotkey (default `F7`, rebindable via Mod Settings), only while not in combat or a scene. Entry-point approach is S-14.
- **Tabs**:
  1. **Legend**
     - Active title, Renown tier bar, Dread meter with component breakdown (K, C, L, X, H) and the plain-language line *"People fear you mostly because of: body count, chrome"*
     - Archetype radar (6 axes)
     - Street Cred, current Aura, Low Profile state, recognition chance in the current district
  2. **Factions**: one row per faction showing posture badge, standing bar, Fear, Respect, Renown, kills, bounty, and a Broker Peace button.
  3. **Districts**: renown bars per district. A map overlay is v2.
  4. **Rivals**: active cards (name, epithet, faction, rank, traits, weaknesses known after first encounter, history, state) and an archive of slain or retired Rivals.
  5. **Legend Log**: newest-first timeline with filters (Deeds, Kills, Rivals, Titles, Factions).
  6. **Titles**: unlocked and locked titles. Hidden titles show `???` with a hint. Set the active title or choose Auto.
- Mouse and keyboard in v1. Controller navigation is v1.1.

### 12.2 HUD elements

| Element | Placement | Duration | Toggle |
|---|---|---|---|
| Toasts (tier, title, posture, tribute, Rival, bonus €$) | top-right, stacked max 3 | 3.5 s | `toasts` |
| Whisper line | lower centre, above game subtitles | 4 s | `whispers` |
| Rival Card | centre-left, slide-in | 4 s or until combat | `rivalCard` |
| Low Profile icon | near the minimap | while active | `lowProfileIcon` |
| Debug overlay | world-space labels over NPCs | – | `debugOverlay` |

---

## 13. Settings

Implemented with **Mod Settings** ✅ (`@runtimeProperty("ModSettings.mod", "Cyberbane")` on fields of a settings class, `ModSettings.RegisterListenerToClass(this)` ✅ to receive updates). Other attribute keys (`ModSettings.category`, `displayName`, `description`, `min`, `max`, `step`) follow the Mod Settings docs.

| Category | Setting | Type | Default | Range |
|---|---|---|---|---|
| General | `enabled` | Bool | true | – |
| General | `preset` | Enum | Default | Subtle / Default / Dramatic (sets multipliers below) |
| General | `hubKey` | Key | F7 | any |
| Reputation | `renownGainMult` | Float | 1.0 | 0–3 |
| Reputation | `dreadGainMult` | Float | 1.0 | 0–3 |
| Reputation | `decayMult` | Float | 1.0 | 0–3 |
| Reputation | `rumorSpreadMult` | Float | 1.0 | 0–3 |
| Reputation | `streetCredFloor` | Bool | true | – |
| Reputation | `bootstrapFromHistory` | Bool | true | – |
| Civilians | `civReactions` | Bool | true | – |
| Civilians | `civIntensity` | Float | 1.0 | 0–2 (scales T for civilians) |
| Civilians | `maxReactingCivilians` | Int | 6 | 0–15 |
| Civilians | `panicDriving` | Bool | true | – |
| Gangs | `gangReactions` | Bool | true | – |
| Gangs | `hostileOnSight` | Bool | true | – |
| Gangs | `warnings` | Bool | true | – |
| Gangs | `factionDisguises` | Bool | true | – |
| Gangs | `tribute` | Bool | true | – |
| Gangs | `tributeMult` | Float | 1.0 | 0–3 |
| Gangs | `hitSquads` | Bool | true | – |
| Gangs | `hitSquadFrequencyMult` | Float | 1.0 | 0–3 |
| Morale | `morale` | Bool | true | – |
| Morale | `moraleIntensity` | Float | 1.0 | 0–2 |
| Morale | `maxBreakFraction` | Float | 0.6 | 0–1 |
| Police | `policeRecognition` | Bool | true | – |
| Police | `knownOffender` | Bool | **false** | – |
| Police | `friendOfTheForce` | Bool | true | – |
| Police | `copMorale` | Bool | true | – |
| Economy | `vendorPricing` | Bool | true | – |
| Economy | `maxDiscount` | Int | 20 | 0–30 (%) |
| Economy | `gigBonus` | Bool | true | – |
| Economy | `gigBonusMult` | Float | 1.0 | 0–3 |
| Rivals | `rivals` | Bool | true | – |
| Rivals | `maxRivals` | Int | 8 | 0–15 |
| Rivals | `deathsRemembered` | Bool | true | – |
| Rivals | `rivalFrequencyMult` | Float | 1.0 | 0–3 |
| Rivals | `rivalNameplates` | Bool | true | – (only if S-07 succeeds) |
| UI | `whispers` | Bool | true | – |
| UI | `whisperCooldown` | Int | 25 | 5–120 (s) |
| UI | `pronouns` | Enum | Auto | Auto / He / She / They |
| UI | `toasts` | Bool | true | – |
| UI | `rivalCard` | Bool | true | – |
| UI | `lowProfileIcon` | Bool | true | – |
| Compatibility | `twrCompat` | Enum | Auto | Auto / On / Off (§17) |
| Compatibility | `dogtownEnabled` | Bool | true | – |
| Debug | `logLevel` | Enum | Info | Off / Info / Verbose |
| Debug | `debugOverlay` | Bool | false | – |
| Debug | `freezeReputation` | Bool | false | – |

**Presets**: *Subtle* ×0.6 on all intensity and frequency multipliers with `hostileOnSight` off. *Dramatic* ×1.5 on all of them. Changing any value by hand switches the preset to "Custom".

---

## 14. Content registries (data)

**Decision:** content tables are defined in **redscript** (`Data/*.reds`), not in TweakDB/YAML. Reasons: compile-checked, no extra dependency, and no TweakXL syntax uncertainty. Third-party add-ons can extend them through a public API.

```swift
// Illustrative public API, exposed for add-on mods
public abstract class CyberbaneAPI {
  public static func RegisterImplant(family: CName, score: Float, visible: Bool, archetype: ECBArchetype) -> Void;
  public static func RegisterLookItem(record: TweakDBID, score: Float, disguise: Float, factionTag: CName) -> Void;
  public static func RegisterLookTag(tag: CName, score: Float, disguise: Float, factionTag: CName) -> Void;
  public static func RegisterDeed(def: ref<CBDeedDef>) -> Void;
  public static func RegisterTitle(def: ref<CBTitleDef>) -> Void;
  public static func GetRenown() -> Float;          // read-only queries for other mods
  public static func GetDread() -> Float;
  public static func GetStanding(faction: CName) -> Float;
}
```

Registries:

| Registry | Contents | Seed |
|---|---|---|
| Factions | id, affiliation mapping, baseline, courageMod, dreadSens, chromeAttitude, respect weights, rivals, turf, record pools by tier, name-pool key | Appendix B |
| Districts | id, district-record mapping, adjacency, display key | Appendix C |
| Implants | family → score, visible, archetype | Appendix D |
| Looks | record or tag → score, disguise, faction tag | Appendix E |
| Customization | option → score | Appendix E |
| Deeds | §7.2.2 | Appendix F |
| Titles | id, condition, priority, hidden, loc key | Appendix G |
| Whispers | (speaker, mood, tier, topic) → loc keys | Appendix H |
| Names | faction → first, last and epithet loc keys | Appendix I |
| Traits | id → stat modifiers, flags, loc keys | §10.5 |

Record ids for implants and looks are generated in S-10 / S-11 by dumping TweakDB with WolvenKit or RedHotTools. Codeware ships TweakDB name hashes, which helps resolve IDs during development.

---

## 15. Localization

- Uses **Codeware localization** ✅: a `ModLocalizationProvider` (`GetPackage(language)`, `GetFallback()`) and one `ModLocalizationPackage` per language with `DefineTexts()` and `Text(key, value)`. Gendered variants use `Text(key, valueF, valueM)` ✅.
- **Key format**: `Cyberbane-<Area>-<Id>`, e.g. `Cyberbane-Whisper-Civ-Fear-T2-003`, `Cyberbane-Title-ChromeSaint`, `Cyberbane-Name-TygerClaws-First-012`.
- **Files**: `Localization/en-us.reds` first. Translators add `Localization/<lang>.reds`.
- Token substitution happens after lookup. Translators keep tokens unchanged.
- No text is hard-coded in logic files.

---

## 16. Safety rules

### 16.1 The Safety Gate (single authority)

An NPC may be affected by Cyberbane only if **all** of these hold:

1. It is not a quest NPC (`IsQuest` / `IsQuestTarget` checks 🔎, S-13).
2. It is not a unique or named character, companion, follower or romance partner (S-13; registry exclusion list as backup: Judy, Panam, River, Kerry, Johnny, Takemura, Misty, Viktor, Rogue, Claire, Mama Welles, Jackie, Songbird, Reed, Alex and others).
3. It is not in a scene or dialogue and not in a quest workspot (`IsInWorkspot` 🔎 blocks movement-based reactions).
4. It was not spawned by another mod (AMM etc., S-16).
5. It is not a vendor in mid-transaction.

The **context** must also allow it:
- No cutscene or scene with player control locked, no braindance (`BraindanceSystem` 🔎), not in a safe zone (`IsInSafeZone` 🔎), not in V's apartments, the Afterlife, ripperdocs or Viktor's clinic.
- **Spawning systems** (hit squads, Rivals) are additionally blocked when a tracked quest objective's mappin is within 200 m, or a main job or Phantom Liberty main quest is active in the area (S-13).

### 16.2 Never change

- TweakDB attitude groups or records globally. All changes are per-instance and at runtime.
- Quest facts, journal states, items in V's inventory (except paid €$ for bonuses and tributes).
- Time dilation, the camera, or player control.

### 16.3 Kill switch

`enabled = false` stops all reactions immediately, despawns `Cyberbane`-tagged entities, reverts tracked attitude overrides and stops price modifiers. State is kept. Re-enabling resumes.

### 16.4 Revert tracking

Every per-NPC override (attitude, reaction state) is recorded in an in-memory list. It is reverted on encounter end, NPC detach (no-op), kill switch, or system detach.

### 16.5 Fault isolation

Each module has an error counter. After 5 errors in one session, that module disables itself for the session, logs a warning and shows a single toast: *"Cyberbane: {module} disabled due to errors. See log."*

---

## 17. Compatibility

| Mod | Overlap | Policy |
|---|---|---|
| **They Will Remember** | Faction memory, hostility on sight, hit squads, disguise and identification | `twrCompat` On (or Auto if detected, S-16): Cyberbane **disables** hostile-on-sight, hit squads and faction-colour disguises. It keeps crowds, whispers, morale, vendors, tribute, Rivals, Hub and titles. |
| **Responsive NPCs** | Crowd reactions | Possible double reactions. Page advice: lower `civIntensity` or disable one side's crowd reactions. |
| **Night City Alive** | More NPCs and patrols | Performance budget matters (§18). Patrols are treated by faction. |
| **AMM** | Spawned NPCs | Ignore AMM-spawned entities (S-16). |
| **Equipment-EX / Wardrobe** | Visual outfit | Look reads the outfit when present (S-10). |
| **Appearance Change Unlocker** | Character customization | Re-read customization on change. |
| **Native Interactions Framework** | Interactions | Optional Intimidate integration. |
| **Romance / companion mods** (e.g. Judy mods) | Companions | Always excluded by the Safety Gate. |
| **New Game+** | New playthrough | New save line, so a new Playthrough ID and fresh bootstrap. |
| **Mod Settings** | Settings | Required. |

**Game patch policy**: every game patch is "unsupported until verified". After RED4ext and Codeware update, run the regression checklist (§21.4), then publish a compatibility note.

---

## 18. Performance budget

| Area | Budget |
|---|---|
| Fast tick average script time | ≤ 0.3 ms |
| NPCs evaluated per fast tick | ≤ 12 (round-robin) |
| Slow tick | ≤ 2 ms per in-game hour |
| Event handlers | O(1), no scans of persistent arrays in hot paths |
| Allocations | none per frame; reuse buffers in the director |
| Cyberbane-spawned NPCs alive | ≤ 8 |
| Save-data growth | < 64 KB |

Profile in the densest crowds (Jig-Jig Street, Kabuki market) with Night City Alive installed.

---

## 19. Save safety, migration & uninstall

### 19.1 Load-time validation

Clamp every value into range, drop rumors with unknown districts, retire Rivals with invalid records, and rebuild missing faction/district entries from the registries.

### 19.2 Schema migration

`m_schemaVersion` starts at 1. `Migrate(from)` runs step-by-step upgrades (1→2→3…). Each step is idempotent. New fields default sensibly.

### 19.3 Uninstall & reinstall

- **Uninstall**: all effects stop at once because they are runtime-only. The mod page must warn: **saving without Cyberbane permanently deletes its data from that save.**
- **Reinstall on a save without data**: fresh bootstrap from history (deeds re-scanned, kills estimated).
- The Death Ledger (global) survives uninstall in Codeware's storage and re-applies only to matching playthrough IDs.

---

## 20. Logging & debug tooling

- **Logging**: `CBLog.Info/Warn/Error/Verbose(category, message)` wraps the game's script logging (`FTLog` / `ModLog` 🔎; confirm the output location). Categories: Core, Signals, Model, Director, Crowd, Gang, Morale, Police, Vendor, Rivals, Ledger, UI, Safety.
- **Debug overlay** (`debugOverlay`): world-space labels over evaluated NPCs: class, faction, recognized (p), T, E, chosen reaction, cooldown.
- **Developer console (optional CET add-on, separate download)**, calling static redscript debug functions:
  - `CB.Dump()`: print state summary
  - `CB.AddKills(faction, n)`, `CB.SetDread(x)`, `CB.SetRenown(x)`, `CB.SetStanding(faction, s)`
  - `CB.SpawnRival(faction, rank)`, `CB.ForceHitSquad(faction)`, `CB.ForceTribute(faction)`
  - `CB.SimulateDeath()`: ledger test
  - `CB.Reset()`: wipe state for this save (asks for confirmation)

---

## 21. Testing plan

### 21.1 Environments

- **A**: clean 2.31 with the required dependencies only.
- **B**: the owner's full mod list (Judy mods, apartments, Native Interactions, NG+, etc.).

### 21.2 Test saves

1. Early game (Watson, before The Heist)
2. Mid game (after The Heist, several gigs)
3. Late game (Street Cred 50, heavy chrome)
4. Phantom Liberty (Dogtown)
5. New Game+ start

### 21.3 Core test cases (acceptance criteria)

| # | Area | Steps | Expected |
|---|---|---|---|
| T1 | Bootstrap | Load late save first time | Renown ≥ Notorious, deeds listed, one summary log entry, no toast spam |
| T2 | Kill attribution | Kill a ganger with a pistol, then a companion kills one | Only V's kill counted |
| T3 | Witnessing | Kill a lone ganger with nobody around, then kill one in a crowd | Unwitnessed earns 0.25× renown; witnessed full |
| T4 | Massacre | 6 kills in 30 s | Massacre flag, rumor 8, log entry |
| T5 | Rumor spread | Massacre in Watson, wait 6 and 12 in-game hours | RD rises in Westbrook/City Center, then 2-hop districts |
| T6 | Chrome | Equip and unequip Mantis Blades | C and C_visible change on equip event |
| T7 | Look | Equip a full mask | L up, Dg = 0.25, recognition down |
| T8 | Civilian tiers | Force D values via debug in a crowd | Each tier shows its behaviour; budgets respected |
| T9 | Weapon Aura | Draw / holster blades in a crowd | Fear spikes and calms within about 10 s |
| T10 | Gang matrix | Force each posture and E band | Matrix behaviours occur; no quest NPCs affected |
| T11 | Morale | Brutal kills against a squad | ≤ 60% break; immunities respected |
| T12 | Vendors | High-fear V buys from a vendor | Discount within clamp; never refuses |
| T13 | Tribute | Force eligibility | Eddies paid once; cooldown respected |
| T14 | Hit squad | Force squad | Spawns out of view ≥ 50 m; despawns per rules; never in a quest area |
| T15 | Rival (Survivor) | Let a broken NPC escape (forced chance) | Rival created with snapshot; appears later with the correct appearance |
| T16 | Death Ledger | Die to a ganger, reload | Rival "Killer" exists in the reloaded save and in older saves of the same line |
| T17 | Save/load mid-encounter | Save during a hit squad, reload | No orphan spawns; state consistent |
| T18 | Kill switch | Disable mid-combat | Overrides reverted, spawns removed |
| T19 | Uninstall | Remove mod, load, save, reinstall | Game fine; data gone; fresh bootstrap |
| T20 | Quest safety | Play The Pickup, a Mox/Clouds quest, the Dogtown entry, a Judy romance scene | Zero interference |
| T21 | Performance | Jig-Jig Street at night + Night City Alive | Within §18 budget |
| T22 | Localization | Switch the game language without a translation | Falls back to en-us; no missing-key text |

### 21.4 Patch regression checklist

1. Game launches with RED4ext + Codeware + Cyberbane, with no errors in the redscript and RED4ext logs.
2. Run T1, T2, T6, T8, T10, T14, T16, T20 on test saves 2 and 3.
3. Re-validate hook signatures (S-01) against the new decompiled scripts.
4. Update the supported-version line on the mod page.

---

## 22. Packaging & release

### 22.1 Repository layout

```
Cyberbane/
├─ src/                                   ← mirrors the game root
│  └─ r6/scripts/Cyberbane/
│     ├─ Core/        (CyberbaneSystem, CyberbaneService, EventBus, Config, Types, Version, Log)
│     ├─ Signals/     (Combat, Encounter, Deeds, Chrome, Look, Heat, PlayerState, District)
│     ├─ Model/       (ScoreEngine, RumorEngine, Archetypes, Titles, Recognition)
│     ├─ Reactions/   (Director, SafetyGate, Crowd, Gang, Morale, Police, Vendor, Tribute, HitSquads)
│     ├─ Rivals/      (RivalSystem, RivalSpawner, DeathLedger, Traits)
│     ├─ Narrative/   (Whispers, Messages)
│     ├─ UI/          (Hub, Toasts, RivalCard, WhisperOverlay, DebugHud)
│     ├─ Settings/    (CyberbaneSettings)
│     ├─ Data/        (Factions, Districts, Implants, Looks, Deeds, Titles, Whispers, Names, Traits)
│     ├─ Localization/(Provider, en-us)
│     └─ API/         (CyberbaneAPI)
├─ optional/CyberbaneDebug/bin/x64/plugins/cyber_engine_tweaks/mods/CyberbaneDebug/init.lua
├─ tools/build.ps1                        ← produces release zips
├─ docs/  (this spec, testing notes)
├─ CHANGELOG.md
└─ LICENSE                                ← MIT recommended
```

### 22.2 Build

`tools/build.ps1 -Version 1.0.0`:
- Writes `Core/Version.reds` (`CyberbaneVersion() -> "1.0.0"`).
- Zips `src/` into `dist/Cyberbane-1.0.0.zip`, with game-root structure so it installs with Vortex or manually.
- Zips `optional/CyberbaneDebug` into `dist/CyberbaneDebug-1.0.0.zip`.
- Fails if any `.reds` file contains `TODO-RELEASE`.

### 22.3 Versioning

Semantic versioning. Minor versions add features. Patch versions fix bugs and keep compatibility. Any schema change bumps at least the minor version and adds a migration.

### 22.4 Nexus Mods page checklist

- Title **Cyberbane**. Category Gameplay.
- Supported game version, required and optional dependencies (linked), install and uninstall instructions, uninstall data warning.
- A feature list with GIFs or short clips: crowd fear, morale break, Rival card, Hub.
- Settings overview, compatibility table (§17), known issues, changelog.
- Permissions: translations allowed; code reuse per license.
- Free. No paywalls (§26).

---

## 23. Milestones

| Milestone | Scope | Exit criteria |
|---|---|---|
| **M0 Setup** | Roll the game back to 2.31, dev tools, repo skeleton, system loads, logging, settings stub, build script | Empty Cyberbane loads cleanly and the log shows the version |
| **M1 Signals & model** | Encounter tracker, kill/defeat attribution, deeds + bootstrap, chrome, look (equipped items), heat, R/D/archetypes, debug overlay | T1–T7 pass |
| **M2 First visible payoff** | Civilian reactions, whispers (en-us), toasts | T8, T9 pass. **Alpha 0.1 (personal use)** |
| **M3 Factions** | Standing, fear, respect, renown, posture, gang matrix, warnings, hostile on sight, morale | T10, T11, T20 pass |
| **M4 Economy & messages** | Vendors, gig bonus, tribute, message toasts, broker peace | T12, T13 pass |
| **M5 Rivals** | Rival system, spawner, traits, Rival Card, Death Ledger, hit squads | T14–T17 pass |
| **M6 Hub & titles** | Full Hub, titles, Legend Log, settings complete, presets | UI review done |
| **M7 Hardening** | Compatibility pass, performance pass, safety pass, beta testers, page | T18–T22 pass. **1.0 on Nexus** |
| **Post-1.0** | Real phone messages, map overlays, vehicle squads, Showdowns, allied backup, controller support for the Hub, Equipment-EX deep support | – |
| **Far future (experimental)** | AI-generated spoken dialogue (needs network, TTS, an HTTP plugin) | Separate optional add-on, if ever |

---

## 24. Research spikes

Each spike ends with a short note in `docs/spikes/S-xx.md` containing the confirmed signature, a minimal working snippet, and any caveats.

| ID | Question | Approach | Blocks |
|---|---|---|---|
| S-01 | Exact hooks for NPC death/defeat (instigator, method, dismember, finisher), hits on V, combat state, rarity, affiliation, appearance name, stat types, Codeware attach event name | Decompiled scripts, NativeDB, RedHotTools | M1 |
| S-02 | Journal: quest states, change notification, gig/hustle categorization, deed journal paths and outcome facts | WolvenKit journal dump + JournalManager | M1 |
| S-03 | Put crowd NPCs into fear stages / walk-away / spread fear programmatically; avoid breaking workspots | Crowd fear functions (`ChangeFearStage`, `SpreadFear` 🔎) | M2 |
| S-04 | Make combat NPCs flee or cower (morale break); make squads move toward V | AI command classes (`AICommand` 🔎) | M3, M5 |
| S-05 | Set and revert per-NPC attitude toward the player safely | Attitude agent (`SetAttitudeTowards` / `SetAttitudeGroup` 🔎) | M3 |
| S-06 | District detection and mapping; turf data | District manager / records | M1 |
| S-07 | Rival names on nameplates (runtime TweakDB records + Codeware localization) | TweakXL runtime API, Codeware localization | M5 (optional) |
| S-08 | Find valid out-of-view navmesh spawn points ≥ 50 m from V | Navigation queries, road/sidewalk sampling | M5 |
| S-09 | Vendor buy/sell price hook points; tooltip line. S-09b: PreventionSystem crime/heat hook points | Decompiled vendor/market and prevention code | M4 |
| S-10 | Read visual clothing incl. wardrobe outfits and Equipment-EX; character customization option names at runtime | Equipment/wardrobe systems, CC state | M1 (basic), M6 (full) |
| S-11 | Identify cyberware families and tiers; confirm the capacity ("Humanity") stats | TweakDB dump, stats system | M1 |
| S-12 | Detect combat cyberware activation (status effects) | Status-effect listeners | M1 |
| S-13 | Safety detection: quest NPCs, unique characters, companions, scenes, braindance, safe zones, active quest areas; V's voice-tone pronouns | Decompiled scripts + testing | M2 |
| S-14 | Hub entry point and hotkey (Codeware input events); UI framework approach. S-14b: map pins for Sightings | Codeware UI examples | M6 |
| S-15 | When Codeware `ScriptableService` persistent data is flushed to disk | Codeware source/docs, crash test | M5 |
| S-16 | Detect They Will Remember (reflection on its classes) and AMM-spawned entities. S-16b: Native Interactions Framework API | Codeware reflection, NIF source | M7 |
| S-17 | GameTime ↔ Float seconds; DelaySystem callbacks; in-game hour boundaries | TimeSystem, DelaySystem | M0 |
| S-18 | Real phone messages (journal additions) | ArchiveXL/journal research | Post-1.0 |

---

## 25. API reference & verification status

**✅ Verified** (declarations read from the installed Codeware 1.20.3 / Mod Settings 0.2.21, or the redscript persistence docs):

| API | Notes |
|---|---|
| `DynamicEntitySystem`: `CreateEntity(spec) -> EntityID`, `DeleteEntity`, `EnableEntity`, `DisableEntity`, `IsReady`, `IsRestored`, `IsManaged`, `IsSpawned`, `GetEntity`, `IsPopulated(tag)`, `GetTagged(tag)`, `GetTaggedIDs(tag)`, `DeleteTagged(tag)`, `RegisterListener(tag, target, fn)` | Codeware |
| `DynamicEntitySpec`: `recordID`, `templatePath`, `appearanceName`, `position`, `orientation`, `persistState`, `persistSpawn`, `alwaysSpawned`, `spawnInView`, `active`, `tags` | Codeware |
| `ScriptableService` (abstract) | Codeware |
| `CallbackSystem.RegisterCallback(eventName, target, function, opt sticky)` | Codeware |
| `ModLocalizationProvider.GetPackage(language)`, `GetFallback()`; `ModLocalizationPackage.DefineTexts()`, `Text(key, value)`, `Text(key, valueF, valueM)` | Codeware |
| `ModSettings.RegisterListenerToClass`, `RegisterListenerToModifications`, `@runtimeProperty("ModSettings.mod", …)` | Mod Settings |
| `persistent` on `ScriptableSystem` / `PersistentState` / `ScriptableService` fields; no String/ResRef/Variant | redscript docs |

**🔎 Name present in the game's compiled scripts (2.5); signatures unverified:** `gameDeathEvent`, `instigator`, `OnDeath`, `NPCPuppet`, `ScriptedPuppet`, `GetRecordID`, `Affiliation`, `gamedataAffiliation`, `SetAttitudeTowards`, `SetAttitudeGroup`, `GetAttitudeAgent`, `GetCurrentAppearanceName`, `PlayVoiceOver`, `GetDisplayName`, `ReactionPreset`, `SetReactionPreset`, `StimBroadcaster`, `BroadcastStim`, `gameFearStage`, `ChangeFearStage`, `SpreadFear`, `TriggerFearRunningVO`, `RegisterFleeingNPC`, `CanTriggerPanicInCombat`, `TriggerPanicDrivingEvent`, `MaxTacFearEvent`, `JournalManager`, `GetEntryState`, `QuestsSystem`, `GetFact`, `GetPlayerStreetCred`, `PlayerDevelopmentSystem`, `EquipmentSystem`, `GetItemInSlot`, `GetVisualTags`, `ItemAddedToSlot`, `OnItemEquipped`, cyberware areas (`ArmsCW` … `LegsCW`), `HumanityAllocated`, `HumanityTotalMaxValue`, `HumanityOverallocated`, `HumanityAvailable`, `gameuiICharacterCustomizationSystem`, `PreventionSystem`, `HeatLevel`, `GetHeatStage`, `GetCurrentDistrict`, `District_Record`, `gamedataDistrict`, `IsInSafeZone`, `gamedataNPCRarity`, `IsCrowd`, `IsQuest`, `IsQuestTarget`, `IsInWorkspot`, `BraindanceSystem`, `GetResolvedGenderName`, `DelaySystem`, `TimeSystem`, `GetGameTime`, `TransactionSystem`, `GetBuyPrice`, `GetSellPrice`, `MappinSystem`, `RegisterMappin`, `StatModifier`, `AddModifier`, `AICommand`, `FTLog`, `ModLog`, `StringToName`, `RandRange`.

**❓ Not found / must research:** a dedicated flee AI command class (`AIFleeCommand` not found, S-04), a generic "surrender" behaviour, phone message authoring (S-18).

---

## 26. Legal & naming

- **Free mod.** CD Projekt RED permits non-commercial mods. Never sell Cyberbane or paywall features. Donations are fine.
- **Original work only.** Do not bundle other mods' files. List them as requirements.
- **Avoid Warner Bros terminology.** Never use "Nemesis" in code, UI, page text or marketing. Use **Rivals**. WB's patent on its Nemesis system runs to about August 2036. A free fan mod is a different situation from a commercial game, but this is not legal advice. Get proper advice if concerned before a public release.
- **Name check.** No existing Cyberpunk mod named "Cyberbane" was found on 2026-10-24. Re-check Nexus right before publishing.
- **Credit** frameworks used (RED4ext, redscript, Codeware, Mod Settings, optional NIF/Equipment-EX).

---

## 27. Appendices

### A. Default constants (consolidated)

| Constant | Default | Section |
|---|---|---|
| Fast tick | 1.0 s real | §5.5 |
| NPC eval radius / max per tick | 30 m / 12 | §9.1 |
| Encounter end timeout | 20 s | §7.1.3 |
| Massacre | 6 kills / 30 s, or 10 per encounter | §7.1.3 |
| Flawless | ≥ 4 kills, < 5% HP lost | §7.1.3 |
| Witness crowd radius | 25 m | §7.1.4 |
| Renown curve scale | 2500 | §8.1 |
| Street Cred floor factor | 14 | §8.1 |
| Unwitnessed renown / dread multiplier | 0.25 / 0.5 | §8.1, §8.2 |
| Dread weights K/C/L/X/H | 0.35/0.20/0.15/0.20/0.10 | §8.2 |
| K / X / H curve scales | 600 / 400 / 150 | §8.2 |
| Archetype decay | ×0.995/day | §8.3 |
| Archetype min total / hysteresis | 30 / 1.25 | §8.3 |
| Posture thresholds | 50 / 15 / −30 / −70 | §8.4 |
| Rumor spread interval / hops / lifetime | 6 h / 2 / 3 days | §8.5 |
| Aura cap | 40 | §8.6 |
| Recognition cap / cache | 0.95 / 10 real min | §8.7 |
| Civilian tier thresholds | 20/40/60/80 | §9.2 |
| Whisper cooldown / radius / chance | 25 s / 10 m / 35% | §9.10 |
| Morale break threshold / max fraction | 0.25 / 0.6 | §9.4 |
| Vendor clamp | −20% … +15% | §9.6 |
| Tribute chance / cooldown | 25% / 7 days | §9.8 |
| Hit squad base chance / cooldowns | 0.04 / 2 days faction, 45 min global | §9.9 |
| Rival chances | Survivor 15%, Spared 20%, Avenger 15%, Hunter 50% | §10.2 |
| Rival encounter chance | 10% + 5% × rank | §10.7 |
| Max Cyberbane spawns | 8 | §9.1 |

### B. Faction profiles (seed: flavour values to tune in playtest)

| id | Name | Affiliation (S-01) | Baseline S | courageMod | dreadSens | chromeAttitude | Respects (weight) | Rivals | Turf |
|---|---|---|---|---|---|---|---|---|---|
| `TygerClaws` | Tyger Claws | TygerClaws | 0 | +0.05 | 1.0 | +0.2 | Ghost 0.3, Brawler 0.3 | Mox | Westbrook (Japantown), Watson (Kabuki) |
| `Maelstrom` | Maelstrom | Maelstrom | 0 | +0.10 | 0.8 | **−1.0** | Chromed 0.6, Butcher 0.3 | – | Watson (Northside) |
| `Valentinos` | Valentinos | Valentinos | 0 | +0.05 | 1.0 | +0.2 | Professional 0.3, Brawler 0.3 | SixthStreet | Heywood |
| `SixthStreet` | 6th Street | SixthStreet | 0 | 0.00 | 1.0 | 0.0 | Professional 0.4 | Valentinos | Santo Domingo |
| `Animals` | Animals | Animals | 0 | +0.15 | 0.8 | 0.0 | Brawler 0.6 | – | Pacifica, roaming |
| `VoodooBoys` | Voodoo Boys | VoodooBoys | 0 | 0.00 | 1.0 | 0.0 | Netrunner 0.6 | – | Pacifica |
| `Scavengers` | Scavengers | Scavengers | −10 | −0.10 | 1.3 | +0.4 | – | everyone | Watson, scattered |
| `Mox` | Mox | Mox | +5 | −0.05 | 1.1 | +0.2 | Ghost 0.3, Professional 0.3 | TygerClaws | Watson (Kabuki), Westbrook |
| `Wraiths` | Wraiths | Wraiths | −5 | +0.05 | 1.0 | 0.0 | Butcher 0.3 | Aldecaldos | Badlands |
| `Aldecaldos` | Aldecaldos | Aldecaldos | +10 (+30 Nomad) | +0.10 | 0.7 | 0.0 | Professional 0.4 | Wraiths | Badlands |
| `Barghest` | Barghest | Barghest | 0 | +0.10 | 0.9 | +0.1 | Professional 0.3, Butcher 0.2 | – | Dogtown |
| `Arasaka` | Arasaka | Arasaka | 0 (+10 Corpo; −60 after The Heist) | +0.05 | 0.8 | +0.1 | Professional 0.2 | Militech | City Center, Watson (Arasaka Waterfront) |
| `Militech` | Militech | Militech | 0 | +0.05 | 0.8 | 0.0 | Professional 0.3 | Arasaka | City Center, Badlands outposts |
| `KangTao` | Kang Tao | KangTao | 0 | 0.00 | 0.9 | 0.0 | – | – | City Center |
| `NCPD` | NCPD | NCPD | +10 | 0.00 | 0.9 | +0.2 | Professional 0.5 | – | everywhere |
| `MaxTac` | MaxTac | (MaxTac) | – | immune | 0.3 | 0.0 | – | – | – |

- Record pools per faction and tier (grunt, veteran, officer) are filled in S-01/S-02 from TweakDB.
- Lifepath modifiers: Nomad → Aldecaldos +20; Corpo → Arasaka +10 (until The Heist); Street Kid → Heywood RD floor 15.
- Relationship deeds (e.g. Judy romance → Mox +15; Panam questline → Aldecaldos +20) are optional deed entries (Appendix F).

### C. Districts & adjacency (approximate; tune)

| id | Includes (log flavour) | Adjacent |
|---|---|---|
| `Watson` | Kabuki, Little China, Northside, Arasaka Waterfront | CityCenter, Westbrook |
| `Westbrook` | Japantown, Charter Hill, North Oak | Watson, CityCenter, Heywood, SantoDomingo, Badlands |
| `CityCenter` | Downtown, Corpo Plaza | Watson, Westbrook, Heywood |
| `Heywood` | The Glen, Wellsprings, Vista del Rey | CityCenter, Westbrook, SantoDomingo, Pacifica |
| `SantoDomingo` | Arroyo, Rancho Coronado | Heywood, Westbrook, Badlands |
| `Pacifica` | Coastview, West Wind Estate | Heywood, Dogtown |
| `Dogtown` | (Phantom Liberty) | Pacifica |
| `Badlands` | Rocky Ridge, Red Peaks, Biotechnica Flats, etc. | SantoDomingo, Westbrook |

### D. Implant scores (seed; families matched in S-11)

| Family | Score | Visible | Archetype nudge |
|---|---|---|---|
| Mantis Blades | 12 | ✔ | Butcher |
| Gorilla Arms | 10 | ✔ | Brawler |
| Monowire | 10 | ✔ | Butcher |
| Projectile Launch System | 12 | ✔ | Butcher |
| Berserk (OS) | 12 | – | Chromed |
| Sandevistan (OS) | 10 | – | Chromed |
| Cyberdeck (OS) | 6 | – | Netrunner |
| Kerenzikov | 4 | – | Chromed |
| Optical Camo | 6 | – | Ghost |
| Subdermal armor | 3 | ✔ (skin) | – |
| Kiroshi optics | 3 | ✔ (eyes) | – |
| Other implants (default) | 1 | – | – |

### E. Look scoring (seed; tags and records resolved in S-10)

| Match | Score | Disguise | Faction tag |
|---|---|---|---|
| Full face mask / helmet with visor | +12 | 0.25 | – |
| Hood / cap | +2 | 0.10 | – |
| Sunglasses / tech visor | +2 | 0.05 | – |
| Military / tactical outerwear | +8 | – | – |
| Spiked / skull / aggressive motifs | +6 | – | – |
| Gang-style items | +5 | – | that gang |
| Netrunner suit | +6 | – | – (Netrunner respect) |
| Formal corpo suit | −5 | – | – |
| Casual street clothes | 0 | – | – |
| **Customization**: visible face chrome | +10 | – | – |
| **Customization**: face scars | +6 | – | – |
| **Customization**: face tattoos | +6 | – | – |
| **Customization**: cyber / glowing eyes | +8 | – | – |
| **Customization**: cyber teeth | +5 | – | – |

### F. Deed catalogue (seed; journal paths and facts filled in S-02)

| id | Description | Renown | Dread | Effects | Titles |
|---|---|---|---|---|---|
| `DEED_HEIST` | The Heist (Konpeki Plaza) | 150 | 40 | Arasaka −60; rumor 30 CityCenter | Konpeki Ghost |
| `DEED_PICKUP_ROYCE` | The Pickup: Royce killed | 60 | 25 | Maelstrom −40 | – |
| `DEED_PICKUP_DEAL` | The Pickup: deal honoured | 40 | 5 | Maelstrom +20 | – |
| `DEED_ODA` | Play It Safe: Oda defeated | 60 | 20 | Arasaka −10 | – |
| `DEED_SASQUATCH` | Sasquatch (Animals boss) defeated (quest TBD) | 60 | 25 | Animals −30 | – |
| `DEED_PSYCHO_<n>` | Cyberpsycho Sighting n (killed / pacified) | 15 / 20 | 5 / 0 | NCPD 0 / +3 | progress |
| `DEED_PSYCHO_ALL_PACIFIED` | All sightings pacified | 50 | 0 | NCPD +10 | Psycho Whisperer |
| `DEED_BRAT_CHAMP` | Beat on the Brat: champion | 50 | 10 | Brawler +15 | Fist of Night City |
| `DEED_BEAST_IN_ME` | The Beast in Me: race series won | 30 | 0 | – | – |
| `DEED_PL_HANSEN` | Phantom Liberty: Kurt Hansen killed (outcome-dependent) | 80 | 25 | Barghest −50 | – |
| `DEED_PL_CHIMERA` | Phantom Liberty: Chimera destroyed | 50 | 15 | – | – |
| `DEED_REL_JUDY` | Judy romance completed (optional) | 10 | 0 | Mox +15 | – |
| `DEED_REL_PANAM` | Panam questline completed (optional) | 20 | 0 | Aldecaldos +20 | – |
| `DEED_GIG` | Any gig (generic) | 20 | 0 | Professional +3; target faction ±5 | – |
| `DEED_HUSTLE` | Any NCPD hustle (generic) | 5 | 0 | NCPD +1.5; Professional +1 | – |

Endings are not deeds: the game returns to the point-of-no-return save after the credits.

### G. Titles (seed)

| id | Display | Condition | Hidden |
|---|---|---|---|
| `T_MERC_FROM` | The Merc from {DISTRICT} | Tier ≥ Local Name (district = highest RD) | no |
| `T_DISTRICT_PROBLEM` | {DISTRICT}'s Problem | RD_d ≥ 80 and D ≥ 50 | no |
| `T_BUTCHER_OF` | Butcher of {DISTRICT} | Butcher primary and ≥ 50 lethal kills in district | no |
| `T_GHOST_OF` | Ghost of {DISTRICT} | Ghost primary and ≥ 30 quiet takedowns in district | no |
| `T_FACTION_NIGHTMARE` | {FACTION}'s Nightmare | F_f ≥ 85 and kills_f ≥ 75 | no |
| `T_FACTION_FRIEND` | Friend of the {FACTION} | S_f ≥ 75 | no |
| `T_CHROME_SAINT` | Chrome Saint | C ≥ 85 | no |
| `T_GLITCH` | Glitch in the System | Netrunner primary and ≥ 50 quickhack kills | no |
| `T_FIST` | Fist of Night City | `DEED_BRAT_CHAMP` | no |
| `T_PSYCHO_WHISPERER` | Psycho Whisperer | `DEED_PSYCHO_ALL_PACIFIED` | no |
| `T_PSYCHO_HUNTER` | Psycho Hunter | ≥ 10 cyberpsychos killed | no |
| `T_KONPEKI_GHOST` | Konpeki Ghost | `DEED_HEIST` | no |
| `T_UNTOUCHABLE` | Untouchable | ≥ 10 flawless encounters | yes |
| `T_RED_TIDE` | Red Tide | ≥ 5 massacres | yes |
| `T_MAXTAC_PROBLEM` | MaxTac's Problem | ≥ 10 MaxTac kills | yes |
| `T_RIVAL_BREAKER` | Rival-Breaker | ≥ 5 Rivals slain | no |
| `T_MERCIFUL` | The Merciful | ≥ 100 non-lethal and 0 civilian kills | yes |
| `T_LANDLORD` | Feared Landlord | ≥ 5 tributes | yes |
| `T_LIVING_LEGEND` | Living Legend | R ≥ 850 | no |
| `T_CYBERBANE` | **Cyberbane** | R ≥ 850, D ≥ 90, ≥ 3 Rivals slain, ≥ 3 factions with F_f ≥ 85 | yes |

Unlocking a title gives +25 Renown (Cyberbane +100) plus a toast. Cyberbane also triggers a city-wide message and a Hub banner. Auto active title = highest priority unlocked (Cyberbane > Living Legend > faction/district titles > others).

### H. Whisper templates (seed, en-us)

| Speaker / mood / tier | Line |
|---|---|
| Civilian / fear / Notice | "Don't stare, choom. That's {TITLE}." |
| Civilian / fear / Uneasy | "Heard {SUBJ} flatlined {COUNT} {FACTION} in one night." |
| Civilian / fear / Uneasy | "Keep walking. Just keep walking." |
| Civilian / fear / Terror | "Oh no. No no no, it's {TITLE}!" |
| Civilian / admire | "That's the merc who pulled the {DEED}. Preem." |
| Civilian / curious / chrome | "Look at all that chrome. How {IS} {SUBJ} still human?" |
| Civilian / curious / look | "Nobody dresses like that unless they're looking for a fight." |
| Civilian / fear / weapon | "Blades out in the street? Gonk or psycho, I'm not sticking around." |
| Ganger (any) / fear | "Let {OBJ} pass. Not worth dying for." |
| Ganger (any) / hate | "{TITLE}. You've got some nerve showing your face in {DISTRICT}." |
| Ganger (any) / warn | "Turn around, {V}. Last warning." |
| Ganger (Maelstrom) / respect / chrome | "Now THAT is chrome. Respect, choom." |
| Ganger (Animals) / respect / brawler | "Heard {SUBJ} won every fight in the city with bare hands. Respect." |
| Ganger (Voodoo Boys) / respect / netrunner | "{SUBJ} ghosts through ICE like it's nothing. Watch your deck." |
| Ganger (Tyger Claws) / hate / losses | "{COUNT} of ours, {V}. The Claws don't forget." |
| Ganger / rival | "{RIVAL} wants you breathing. For now." |
| Rival / taunt / escaped | "Remember {DISTRICT}, {TITLE}? I do. Every night." |
| Rival / taunt / killed V | "Back from the dead? Let's fix that." |
| Rival / taunt / spared | "You should've finished it, merc." |
| Cop / recognition | "That's {TITLE}. Call it in, quietly." |
| Cop / respect | "{SUBJ}'s cleaned up half our scanner list. Let {OBJ} be." |
| Vendor / fear | "Whatever you want. Discount. Big discount." |
| Vendor / respect | "For you? Friends-and-family price." |
| Ripperdoc / chrome | "Any more chrome and you'll need a firmware update for your soul." |
| Corpo / fear | "Security. Now. Quietly." |

### I. Name pools & epithets (seed: expand to about 40 names each)

| Faction | First names (sample) | Last names / handles (sample) |
|---|---|---|
| Tyger Claws | Kenji, Haru, Daisuke, Aiko, Ren | Morita, Sato, Kuroda, Ishikawa |
| Valentinos | Mateo, Lupe, Rafael, Inés, Santiago | Ortega, Vargas, Delgado, Cruz |
| 6th Street | Cody, Travis, Dana, Wade, Brooke | Hollis, McCray, Barnes, Tate |
| Maelstrom | (handles) Static, Rustbite, Null, Shardjaw | – |
| Voodoo Boys | Jean, Mirlande, Placid, Fabienne | Duval, Toussaint, Célestin |
| Animals | (handles) Bullneck, Tusk, Brickhouse | – |
| Scavengers | (handles) Gutter, Scalpel, Tin | – |
| Mox | Tess, Coral, Dex, Jo | Lane, Rivera, Shaw |
| Wraiths | (handles) Dustdevil, Rattler, Bonefire | – |
| Barghest | Viktor, Aleks, Jonas, Mira | Kessler, Brandt, Novak |

Epithets by source:
- **Survivor**: "Who Ran", "the Survivor", "Last One Standing"
- **Spared**: "the Humbled", "Second Chance", "Iron Jaw" (for fists)
- **Killer**: "V-Killer", "the Undertaker", "Flatline"
- **Avenger**: "Bloodsworn", "the Avenger"
- **Hunter**: "the Hound", "Bounty"
- **Promotion**: "Twice-Burned", "the Unbroken", "Scarface"

### J. Illustrative code skeletons

*Illustrative only. Final signatures come from the S-xx spikes.*

```swift
// Settings (Mod Settings)
public class CyberbaneSettings {
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "General")
  @runtimeProperty("ModSettings.displayName", "Enabled")
  public let enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Rivals")
  @runtimeProperty("ModSettings.displayName", "Max active Rivals")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "15")
  public let maxRivals: Int32 = 8;

  public func Init() { ModSettings.RegisterListenerToClass(this); }
}
```

```swift
// Localization (Codeware)
public class CBLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      case n"en-us": return new CBLocalizationEnUs();
      default: return null;
    }
  }
  public func GetFallback() -> CName { return n"en-us"; }
}

public class CBLocalizationEnUs extends ModLocalizationPackage {
  protected func DefineTexts() {
    this.Text("Cyberbane-Title-ChromeSaint", "Chrome Saint");
    this.Text("Cyberbane-Whisper-Civ-Fear-T1-001", "Don't stare, choom. That's {TITLE}.");
  }
}
```

```swift
// Thin death hook (signature to confirm in S-01)
@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result = wrappedMethod(evt);
  CyberbaneSystem.Get(this.GetGame()).Signals().OnNpcDeath(this, evt);   // extract → publish → return
  return result;
}
```

```swift
// Persistent system access pattern
public class CyberbaneSystem extends ScriptableSystem {
  public static func Get(game: GameInstance) -> ref<CyberbaneSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"Cyberbane.CyberbaneSystem") as CyberbaneSystem;
  }
}
```

---

*End of specification v0.1.*
