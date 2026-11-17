# Cyberbane improvements

Research for changes not built yet. Each section says what it would take, what stands in the way, and
what is recommended. Player requests, and what was done about each, are in
[PLAYER_REQUESTS.md](PLAYER_REQUESTS.md) (this file's name until 1.9.5).

---

## Voicing the street: a voice for every subtitle

**Goal.** Every line Cyberbane puts in the game's subtitles is heard as well as read: what V overhears
from the crowd (`Narrative/Whispers.reds`), what people answer when V talks to them, and V's own line in
that exchange (`Reactions/StreetTalk.reds`). Texts on the phone stay texts.

**Short answer.** It is possible without touching the game's files, with one optional framework
(Audioware) and audio Cyberbane would ship as a separate download. What it cannot have is lip sync, and
the lines that name somebody or something (a gang, a district, a Rival, a sum of eddies) need work before
they can be voiced. The voices themselves have to be synthetic voices nobody owns, never copies of the
game's cast. Recommended: build it in phases, starting with groundwork that changes nothing players see.

### 1. What there is to voice

Counted from the source (1.9.5): about **263 spoken lines**.

| Where | Fixed lines | Lines with a name or number in them |
|---|---|---|
| Overheard lines (`Whispers.reds`) | 105 | 66 |
| Street talk, V's choices and the answers (`StreetTalk.reds`) | 83 | 9 |

What goes into the templated ones: a district or place phrase (about 14 lines), a gang's name (10), V's
title (8), the district V is in (5), the gang's leader or the Rival hunting V (5), a Rival's name and
hideout (the informant and tip lines), and eddie amounts (the shake-down answers).

Two things already in the code matter here:

- Subtitles go through the game's own subtitle system (`CBShowGameSubtitle`, `UIGameData.ShowDialogLine`),
  named for the speaker but owned by V, because the person who said a line can be gone when it shows.
  A voice has to come from the actual person, so the code that picks a line has to keep hold of who said
  it (today `CBShowWhisper` is given a faction, not the NPC).
- Street talk already plays one of the game's own barks on the person answering (`GameObject.PlayVoiceOver`
  with `greeting`, `fear_beg` or `bump`) next to Cyberbane's subtitle. What V hears and what V reads are
  two different sentences, and with the game's overhead chatter subtitles on, the game may show its own
  line as well (`chattersControllers.script` draws `OverHead` lines). Once a real voice exists, that bark
  should go.

### 2. What the game itself offers (checked in its scripts, `tools/redmod/scripts`)

- **`GameObject.PlayVoiceOver(npc, context)`** sends `SoundPlayVo` and the NPC says a line of their own
  voice set for that context: their real voice, lip-synced, in 3D, under the dialogue volume. The game's
  scripts use contexts such as `fear_beg`, `fear_run`, `pedestrian_hit`, `bump`, `enemy_warning`,
  `danger`, `battlecry_01`, `stlh_curious_grunt`. **The words cannot be chosen**: the voice set picks a
  line, and nothing tells a script which line or what it said. Good for a tone (a frightened yelp, a
  grunt), never for a sentence of Cyberbane's.
- **`AudioSystem.Play(event, entityID, emitter)`** plays Wwise events. Dialogue is not made of Wwise
  events: voice lines are `.wem` files under `localization/<lang>/vo`, keyed by string id and played by the
  scene system. There is no script call that plays a dialogue line by its id outside a scene.
- **Scenes** play lines with voice and lip sync, but a scene is an authored asset run by the quest system,
  not something a script can put together at runtime.
- **Who is speaking** can be read: `gamePuppet.GetResolvedGenderName()` answers `Female` or `Male` for NPCs
  as well as V (the game uses it in `equipmentSystem.script` and the photo mode). `Character_Record.VoiceTag()`
  names a voice only for story characters; generic NPCs have none in TweakDB. Faction is already known
  (`CBClassifyFaction`). Gender plus faction is enough to choose a voice and keep it for that person.

### 3. What mods can add

- **Audioware** (cyb3rpsych0s1s; Nexus and GitHub) is the established way to add new audio. It runs a
  second audio engine beside the game's and plays files declared in a `.yml` manifest: `.wav`, `.ogg`,
  `.mp3` or `.flac`, in sections `sfx`, `onos`, `voices` and `music`. Voices can be split by locale and by
  `fem`/`male`, and they play on the game's **dialogue volume**. The redscript side is
  `GameInstance.GetAudioSystemExt(game)`: `Play(name, entityID, emitterName, scnDialogLineType, settings)`,
  and for sound that comes from a person, `RegisterEmitter(entityID, tag)` then
  `PlayOnEmitter(name, entityID, tag)`. Emitters can be any entity (NPCs, not V) and are dropped
  automatically when the entity dies or streams out. It needs Codeware (1.11.1 or later) and TweakXL
  (1.10.2 or later). The latest release when this was written is 1.11.0 (28 October 2026); 1.10.0 is the
  one that moved it to patch 2.5. It is a native plugin, so each release works on one game patch:
  players on 2.31 would need the last release before 1.10.0, and anything Cyberbane calls has to exist in
  both. Its repository carries no licence file, which does not matter for depending on it (players install
  it themselves) but would for copying any of it.
  Its limits, all from its documentation:
  - **Every file is declared at startup.** Sound banks are built when the game launches and a sound can
    only be played by its declared name. Nothing plays a file from a path, or a file made after launch.
  - **No lip sync.** "Creating custom lipsync animation is not possible yet." The engine only lip-syncs a
    line with a `.wem` behind it. The documented workaround reuses an existing animation of matching
    length through a `.lipmap`, which is only practical for a handful of hand-made lines.
  - Its own subtitles come from the manifest (fixed text, registered through Codeware localization), not
    from text supplied at runtime. Cyberbane keeps its own subtitle path and only asks Audioware for sound.
  - All its audio pauses in menus and is stopped on every save load; it follows time dilation.
- **REDmod audio** (`customSounds.json`) adds or replaces Wwise events, but needs REDmod deployment and has
  no notion of genders or voices. Audioware supersedes it for this.
- **WolvenKit's sound tool** imports `.wav` into `.wem` to replace existing lines. It cannot add a line the
  game does not already play.

### 4. Where the voices would come from

| Option | Exact words | Effort | Risk |
|---|---|---|---|
| A. The game's own barks (`PlayVoiceOver`) | No | None, already used | Words never match |
| B. Synthetic voices made ahead of time and shipped as audio | Yes, for every line written down | A build pipeline, 40-80 MB download | Templated lines need work (section 5) |
| C. Speech made in the game as each line comes up | Yes, every line, names and numbers included | A native RED4ext plugin with a speech engine and its own playback | New native code to maintain for 2.5 and 2.31, CPU spikes, 100-300 MB of model, a new kind of crash |

Nobody has published option C for Cyberpunk 2077. The AI-conversation mods that exist (Convai's NPC mod,
Generative Texting) run through cloud services, which Cyberbane will not do: it would send a player's game
to somebody else's server.

**Whose voices.** Never a copy of the game's cast or of any real person. The xVASynth voice models made for
Cyberpunk 2077 are trained on the game's actors and are out. CD Projekt's fan content guideline asks for
permission from everybody concerned; a voice actor's likeness is theirs. Use voices made to be used: speech
models whose licence allows redistributing what they generate (Kokoro's weights are Apache-2.0; Piper's
engine is MIT but each voice carries the licence of the recordings it was trained on, and many are
non-commercial), and check every voice's model card. Nexus Mods requires mods that use AI to say so and
explain how, so the voice pack's page must, and Cyberbane's own page should mention it.

**Cast.** Enough that a street does not sound like one person: four women's and four men's voices to
start, chosen per NPC from a hash of their entity id so the same person keeps the same voice, then flavour
by background (street and gang, corporate, nomad, police) if more voices are added. Processed to sit in the
world: 48 kHz, trimmed, loudness matched to the game's dialogue, no reverb baked in (Audioware's reverb mix
and the emitter's position do that).

**V.** Stays unvoiced. A synthetic V would clash with the voice V has in every scene, and V's actors are not
to be copied. V's line keeps its subtitle, as now.

### 5. The lines with names in them

A pre-made voice can only say what was written down. For the 75 templated lines:

1. **Write a voiced version without the name.** "They put a boss of the Tyger Claws in the ground in
   Japantown" becomes "They put one of their bosses in the ground", and with voices on, the subtitle shows
   the voiced sentence, so what is heard and read always match. The specifics stay in the Hub and the texts.
   This covers most of them.
2. **Pre-make the few that are worth it per value.** A gang's name is one of 16 and a district one of 8, so
   the ten gang lines are 160 clips per voice: feasible, and generated, not recorded.
3. **Never splice.** Joining a clip of a name into a sentence breaks the speech's rhythm and sounds like a
   tannoy announcement.
4. **Amounts and Rival names** (shake-downs, informants, tips) get a voiced sentence that does not say them
   ("Here. Take it and go."; "I'll tell you where they are. Just go."), with the exact sum or name in the
   subtitle line that follows it or on the map pin.

### 6. Fitting it into the game

- **Placed on the speaker.** `RegisterEmitter` on the NPC at the moment the line plays (never inside an
  attach event: crash rule 3), `PlayOnEmitter`, and the subtitle as now. Distance and direction come free.
- **One voice at a time.** A queue: a new overheard line waits for the last to finish, and street talk
  pre-empts the crowd (the Director already holds its lines while `CBStreetTalk.Busy()`).
- **Never over the story.** Nothing plays in a scene (`CBPlayerInScene`), during a phone or holo call, while
  V is down, or with the world unsettled (`CBWorldStable`); combat starting stops what is playing.
- **Timing from the audio.** The subtitle stays up for the clip's length plus a beat, read from a generated
  table of durations, instead of today's fixed seconds.
- **Optional, and safe without it.** Audioware's script functions do not exist without Audioware, and a
  missing symbol stops every redscript mod a player has. So Cyberbane calls `AudioSystemExt` through
  Codeware reflection, as it already does for Equipment-EX and They Will Remember, and the voice pack is
  audio files plus an Audioware manifest, with no scripts of its own. Without Audioware or without the
  pack, everything stays exactly as it is now.
- **Settings.** "Voices" on/off under Street talk, and a volume trim, which Audioware applies per play.

### 7. Groundwork first

The lines are written inline today, as arguments to `CBWhisperPick3("...", "...", "...")`. To give each
one a sound it needs an identity:

- Move every spoken line into a data table (`Data/Lines.reds`): an id, the text, the voiced variant if
  the text has a name in it, and its topic. The code picks an id; the subtitle and the sound both come from
  that entry.
- A build script (`tools/voice_lines.py`) reads the table and writes the list to generate, the Audioware
  manifest and the table of clip lengths. The audio itself is made outside the game, from that list.
- This step changes nothing a player sees and can ship on its own.

### 8. Recommended order

1. **Groundwork** (section 7). No audio yet.
2. **Voice pack, first cut**: option B, eight voices, the overheard lines and the street talk answers,
   placed on the speaker, through Audioware by reflection, as a separate optional download.
3. **More voices and backgrounds**, and the gang and district variants of the templated lines.
4. **Only if wanted, much later**: option C, speech made in the game, for every line exactly as written.
   It is the only route to fully dynamic voiced lines, and the most expensive one to keep working.

### 9. Still to find out before building

- **Audioware on 2.31.** Which pre-1.10.0 release is the last for 2.31, and whether `AudioSystemExt`,
  `RegisterEmitter` and `PlayOnEmitter` have the same shape there. The exact signatures are in its
  `crates/audioware/reds/Ext.reds`; read that, not the examples, before writing the reflection calls.
- Whether registering an emitter on a crowd NPC for one line and leaving it is cheap and safe over hours of
  play, or whether it should be unregistered after each line.
- Whether the game shows its own overhead subtitle for the barks street talk plays today (section 1), which
  would mean two lines on screen for one answer.
- Whether a "talking" facial animation can be triggered on the speaker (the game's facial reactions,
  `TriggerFearFacial` and its kin in `reactionComponent.script`) so a voiced line is not said by a still
  face. Real lip sync stays out of reach.
- Size: about 263 lines x 8 voices at around 25 KB each (Ogg, roughly 2.5 seconds) is about 50 MB, more with
  gang and district variants.

**Sources.** The game's scripts in `tools/redmod/scripts` (`gameObject.script`, `audioSystem.script`,
`baseSubtitlesControllers.script`, `chattersControllers.script`, `reactionComponent.script`,
`puppet.script`, `tweakDBRecords.script`); the Audioware book (cyb3rpsych0s1s.github.io/audioware) and the
RED modding wiki's sound guides; CD Projekt RED's fan content guideline; press coverage of Nexus Mods' AI
disclosure rules; the Convai and Generative Texting mod pages.
