# Cyberbane improvements

Research for changes not built yet, ranked by how feasible each is: the surest and smallest first. Nothing
here is implemented. Player requests, and what was done about each, are in
[PLAYER_REQUESTS.md](PLAYER_REQUESTS.md).

Every item has to fit the crash rules (summarised in PLAYER_REQUESTS.md): no police system, one AI order per
NPC, no entity work inside attach events or on hit/death threads, UI as data rather than injected widgets,
no loot put on bodies, no runtime appearance changes, scripts only (no archives, no TweakDB records).
Ideas taken from other mods are taken as ideas: nothing of their code, numbers or text is copied, and each
is redesigned around what Cyberbane already has.

---

## 1. Talking to gangers: what goes wrong, and the fixes

**Built in 1.9.6:** items 1, 2, 3, 4 and 6, plus the parley (a vendetta ganger lets an empty-handed V walk up
and talk; `[Parley]` can talk them and their crew down). Item 5 needed no change: Cyberbane's combat release
already lets go of its own people who are far off, out of sight and not closing in (`CBCombatReleaseTick`).

**The report (1.9.5, 17 November):** "So many times I tried to talk to gangers with no weapons drawn while
they were just standing around and it didn't work. I could talk with NPCs fine, but gangers I could only
speak to once."

**What the log shows** (`[Cyberbane][Talk]` lines, CET `gamelog.log`, sessions of 17 November):

| Line | Count | What it means |
|---|---|---|
| `Prompt up: Tyger Claw - knows you` | 11 in 42 s, no answer between them | The prompt kept opening and closing on its own. Nobody got to choose a line. |
| `V spoke to them a moment ago` | 7 | The 45 s lockout per person after any answer (`TalkCooldownTicks`). This is "I could only speak once". |
| `V is in combat` | 19 | Talk is off in combat, and Cyberbane's own crews and hunters keep V in combat from a distance. |
| `they are running from V` | 2 | Somebody V sent off can never be spoken to again (`cbTalkSent`, no exit). |
| `TygerClaws: their people are hostile to you, and not by Cyberbane's doing` | 1 | The game itself turned the gang hostile (their turf or an earlier fight), so nobody of theirs can talk. |

**Why the prompt flickered on gangers and not on passers-by.** Gangers stand in groups, shoulder to shoulder.
Once the prompt is up, it stays only while `LookedAt` keeps returning the same person, with 0.8 s of grace
(`TalkLookGrace`). The game's look-at follows the crosshair from body to body, and when it returns nobody,
the fallback takes the **nearest** person in the cone, often the man beside the one V chose. The target
"changes", the grace runs out, the prompt closes, the next man is settled on, and it opens again. Nothing in
the log says so because a prompt closing is never logged, only one failing to open.

**Fixes, most certain first:**

1. **Log why a prompt closes** ("Prompt down: looked away / walked off / they turned / a game prompt came
   up"), the same way refusals are logged. Small. Makes every later report exact.
2. **A sticky target.** Once the prompt is up on somebody, it stays on them while V is within keep range and
   they are inside a wide cone (about 45 degrees), whoever else the crosshair crosses. The fallback picks by
   the smallest angle from the crosshair, not the shortest distance, and the grace grows to about 2 s. Small.
3. **A conversation, not a single exchange.** After an answer the prompt comes back on the same person for a
   few seconds with follow-ups that fit what was said (after a greeting: "How's business?", "Seen any of
   [enemy gang] around?", "Who runs this block?"; after a threat: "Walk away", "Last chance"). The per-person
   lockout applies to the *effects* (standing, fear, tips: they already have daily ceilings in `CBTalkTally`),
   not to talking. Only somebody sent off, or a finished conversation, ends it. Medium.
4. **Say no out loud.** When V settles on a ganger who will not talk (their gang is hostile through the game
   or at Vendetta, they are in a fight, they are at a job), they answer with one line in the game's subtitles
   ("Keep walking.", "Not talking to you, merc.") instead of nothing. Then a refusal reads as the ganger's
   choice, not a broken feature. Small.
5. **Release lingering combat sooner.** Talk is off in combat, and the log shows combat dragging on. Our
   release (`CBCombatReleaseTick`, `CBCutOffTick`) already lets go of crew who cannot reach V. A stricter
   rule for crew far off, not moving and not seeing V for half a minute (sent home, the fight over for V)
   would give V the street back faster. Small to medium.
6. **An exit for `cbTalkSent`.** Somebody sent packing is talkable again after a while (a few minutes), or
   once they have stopped running. Every state needs an exit (crash-rule note from 1.8.0). Small.

---

## 2. Gangers who reply and haggle over a Rival's whereabouts

**Built in 1.9.7:** both: the street (ask, a price by temperament and standing, pay, haggle, lean, forget, the loyal
who warn, the rare liar) and the phone (the Hub's button puts the word out; Deal / Too much / Forget it in the thread).

Today a lead is bought on the Hub at a fixed price (`CBWhereaboutsPrice`: base plus so much a rank), paid at
once, and a gang at war with the Rival's texts it (`CBPickTipster`, `CBTipLine`). Nobody answers back. Two
places a deal could be struck instead, both feasible:

**In the street (medium).** Street talk gains one line on gangers: "[Ask] Heard anything about [Rival]?",
offered when a Rival of theirs, or of a gang at war with theirs, has whereabouts for sale
(`CBWhereaboutsForSale`). The answer comes from who this ganger is, rolled once per person and kept on the
puppet the way `cbHoldState` is:

- **Their gang and the Rival's.** One of the Rival's own people sells dear or refuses (and may warn the
  Rival, who then comes for V); one of a gang at war with the Rival's is glad to sell.
- **A temperament:** loyal (won't say), greedy (names a price), scared (gives it cheap, or for nothing when
  afraid enough), a liar (rare; sells a place where nobody waits, and the street later tells V they were
  played). The roll leans on V's standing with them and their gang's fear of V.
- **The price** starts from `CBWhereaboutsPrice` and moves: cheaper for a friendly gang or a frightened
  ganger, dearer for the Rival's own people and the greedy.

The next prompt is the deal: **Pay [price]**, **Haggle** (an odds roll on fear against nerve, the same sum
intimidation uses: success knocks the price down, failure raises it or ends the talk), **Lean on them**
(the existing intimidate path, `CBTalkInform`) or **Forget it**. Paying goes through the same code as the
Hub purchase (`CBRivalHideout`, `CBMarkLeadTold`), so the pin, the waiting Rival and the ambush are
untouched. Street talk already shows any number of lines, so the deal is one more step in its state machine.

**On the phone (medium).** The Hub's "find them" sends a text to the tipster instead of paying at once.
They name a price in their gang's voice, and the reply rows (`CBRealPhoneChoices`, which already carries the
pay-off offer) give **Deal**, **Too much** and **Forget it**. Too much brings a counter-offer or a refusal,
by their posture to V. Each round is one text, so it takes a little time, which suits a phone deal.

---

## 3. Talking the way the game does it

**Built in 1.9.6:** items 1, 2 and 3 (icons and line types, "Talk" first, eyes on V and a longer keep range).
**Built in 1.9.8:** item 5 (the talk bubble, at most two near V).
**Built in 1.9.7:** item 4 (lifepath lines with the game's lifepath icons; Body and Cool shown in the threat, the
parley and haggling; a price V cannot cover greyed and unselectable).

**How the game handles a story character** (read from its scripts, `tools/redmod/scripts`):

- **The bubble over their head** is a map pin attached to the person (`MappinSystem.RegisterMappinWithObject`
  on their role-pin slot) with the variant `ConversationVariant` or `SpeechVariant`, both drawn with the
  game's `talk` icon (`mappinUtils.script`). It says, from a distance, "this one has something for you".
  Cyberbane already hangs pins on people the same way, for the markers over its crews (`UI/Tracking.reds`).
- **Two steps.** Close up, one interaction comes up ("Talk", F). Pressing it hands over to a scene, which
  puts up the choice list and turns the person to face V.
- **The choice list carries more than text.** Each line (`ListChoiceData`) can have:
  - **icons**, from records the game already has (`ChoiceCaptionParts.TalkIcon`, `PayIcon`, `HandshakeIcon`,
    `GiveTakeIcon`, `GrappleIcon`, `IllegalIcon`, `BountyHuntIcon`, the lifepath icons `LifepathStreetKid`,
    `LifepathNomad`, `LifepathCorpo`, and `Solo`, `Netrunner`, `Techie`, `Cool`, `Reflexes`), added with
    `InteractionChoiceCaption.AddPartFromRecordID`. No new game data needed;
  - a **tag** in brackets, which Cyberbane already uses ("[Greet]");
  - a **line type** (`ChoiceTypeWrapper.SetType`): `QuestImportant` (highlighted: this moves something
    forward), `AlreadyRead` (dimmed: said before), `Inactive` and `CheckFailed` (greyed: the option exists but
    V cannot take it), `Illegal` (a crime). Doors and terminals set these from script, so they are open to
    us too.
  - The boxed attribute check with its numbers ("Body 9") and the payment box are made natively by the scene
    system (`InteractionChoiceCaptionBluelinePart` cannot be filled from a script). An icon plus the tag
    "Body 9", greyed when V is short, reads almost the same. Timed choices need a native timer and are out.

**What to take from it, easiest first:**

1. **Icons and line types on our lines.** A talk icon on greetings, the pay icon on anything that costs, a
   handshake on deals, the grapple icon on leaning on someone, the illegal type on a shake-down, the
   quest-important highlight on lines that lead somewhere (asking about a Rival), dimmed lines for what V
   already said to this person, greyed lines for what V cannot afford. Data only, set where the hub is built
   (`CBTalkPushHub`). Small.
2. **Talk first, then the list.** When V settles on somebody, one line comes up: "[Talk]" with the talk icon.
   F opens the full list, the way the game's own "Talk" works. Fewer prompts popping up while V walks
   through a crowd, and V's hands are only held once V has chosen to talk. Small.
3. **They look at V the whole time.** The look-at reaction Cyberbane already sends (`CBGlanceAt`, three
   seconds) is renewed while the prompt is up and while an answer is due, so the person keeps facing V the way
   a scene makes them. For somebody walking past, talking range follows them a little further, so a
   conversation does not end because they took two more steps. Small.
4. **Lines for this V.** The game shows lifepath and attribute lines to the players who qualify, and greyed
   lines to the ones who do not. Ours can too: a **[Street Kid]** line gangers warm to (cheaper tips, a
   warmer greeting), a **[Nomad]** line with the Aldecaldos and the Wraiths, a **[Corpo]** line with corporate
   security, a **[Body]** threat that does not fail on rank-and-file when V's Body is high enough, a
   **[Cool]** bluff, a netrunner's threat only when V has the Intelligence for it. Lifepath comes from
   `PlayerDevelopmentSystem.GetLifePath`, attributes from the stats system. Small to medium.
5. **The talk bubble.** The game's own `talk` pin over people who really have something for V: a ganger with
   word of a Rival (section 2), an informant (section 5, item 9), a friendly gang's lookout with a tip or a job
   (section 4), somebody of a broken gang ready to deal. At most two at a time near V, taken away when used,
   when they stream out or when V moves on, registered on a settled tick (never in an attach event). It uses
   the call the markers already use. V then knows who is worth talking to instead of trying everybody.
   Medium.

## 4. Making talk worth doing

**Built in 1.9.6:** item 1 (the History lines and the gang page's "today" line).
**Built in 1.9.7:** items 2 (the questions), 3 (leads, the toll and the crew called off; the lookout left out because
allies already warn V), 4 in 1.9.8 (turning a ganger), 6 (being remembered) and 7 (a fan's drink, as eddies; "who runs these streets" points V at
the local gang).

A conversation should leave V with something: information V can act on, a deal, a change in how a gang
treats V, or a consequence. And V should be told what it did. Easiest first:

1. **Say what it did.** When an exchange moves something (standing, fear, a lead, Conduct), the History
   records it in a line, and the gang's page on the Hub says what V has done with its people today ("You
   greeted their people today", "You leaned on two of them"). The daily ceilings already exist
   (`CBTalkTally`); this just shows them. Small.
2. **Questions with real answers.** New lines, answered from what Cyberbane already knows:
   - "Anyone looking for me?" The next crew or Rival in the queue, said the street's way ("Maelstrom have been
     asking about you. Tonight, I'd say."). A warning V can use. (The lanes and their timers, `Spawn/Queue.reds`.)
   - "Who runs these streets?" The turf holder, how strong they are, whether it is contested
     (`Model/Territory.reds`).
   - "What's the word?" The loudest rumour that has reached this district (the rumour engine).
   - "Where's [Rival]?" A lead, with the haggling of section 2.
   Small to medium, because the answers already exist.
3. **Deals.** Buying a lead (section 2). Paying a hostile gang's people a toll to be left alone on their
   streets for a few hours (they hold back, the way the frightened already do: `cbHoldState`). Paying to have
   a crew that is on its way called off (the pay-off's lane clearing, for one crew only). Asking a friendly
   gang's lookout to warn V when a crew comes (the warnings friendly gangs already send). Medium.
4. **Turning someone.** Lean on a ganger hard enough and a new line appears: "You work for me now." If they
   take it they become an informant and text V a tip later (section 5, item 9); if they do not, they warn
   their gang and a crew comes sooner. Medium.
5. **Talking to a Rival who is not fighting.** A Rival met in the street who owes V, who is holding back
   from fear, or who is a Debtor gets lines of their own: "Call it even" (the Debtor retires), "You owe me:
   where's [another Rival]?" (a lead), "Get out of Night City" (if afraid enough, they leave the roster). A
   conversation with a named enemy is the most memorable kind there is. Medium.
6. **Being remembered.** Within the session the same person remembers V ("You again? Make it quick."), and
   somebody V greeted or helped is easier next time. From the per-person talk fields already kept. Small.
7. **Civilians worth stopping.** A fan (V well known, the person friendly) gives a small gift once a day:
   eddies or a consumable, straight to V's inventory. A frightened passer-by points V at the local gang ("The
   Claws hang out by the noodle stand. Please, just go."). Small to medium.
8. **Favours.** "Need anything done?" to a friendly or neutral ganger gives a small street job built from
   Cyberbane's own pieces: run off a rival gang's lookout two streets away (somebody spawned there with a pin),
   lean on a named civilian who owes them, carry word to a Rival. The reward is standing above the greeting
   ceiling, eddies, sometimes a lead. This is the "befriend a gang without a body" request given real
   content. Larger.

Left out: anything that changes the police's heat (the police system is off limits), timed choices, voices.

## 5. What can be borrowed from Stay Dead (Night City Nemesis, 0.1.6)

Read from its scripts (72,000 lines of redscript, a CET part, Audioware sounds, TweakXL records and
archives). It is a Shadow of War-style nemesis system with a lot of overlap with Cyberbane. Listed here are
only the ideas that are feasible within Cyberbane's rules, easiest first. Each says what it does, what
Cyberbane already has, and how ours would be built.

**Built in 1.9.6:** items 1 (texts wait during a conversation) and 2 (the re-arm watch).
**Built in 1.9.9:** items 5 (catchphrases), 6 (the street's word on a Rival), 10 (mercy as a choice, with
talking to a downed Rival), 11 (kin, as the successor), 12 (send word, and the call-out), 14 (the announcement,
as words: the crew is not made neutral for it, because the re-arm watch and the game's combat state would fight
it), 15 (bodyguards at the lair, costing the Rival health as they fall) and 17 in part (gang-painted cars, the
Claws bike, the call-out; the marksman on high ground is left out: script cannot find high ground reliably).
**Built in 1.9.8:** items 3 (intel from a scan), 7 (the squeeze), 8 (the downed talk; a Rival's body), 9 (the
informant, from the Debtor) and 13 (fatal flaws, killed from the hit's next-frame follow-up). See
`Reactions/StreetIntel.reds`.

### Small

1. **Texts and overheard lines wait while a choice list is up.** Stay Dead holds its pop-ups while dialogue
   choices are on screen, in scenes and in menus. Cyberbane's phone and subtitle delivery (`CBPhone.Update`,
   `Deliver`) does not check for the game's dialogue choices or its own talk prompt. Hold both while any
   `DialogChoiceHubs` entry is up (`CBNativePromptUp` already reads it) or V is in a scene.
2. **A spawned crew re-armed if it comes up neutral.** Stay Dead found crews spawned hostile that later read
   neutral, and re-checks every one of its men once a second for their first 30 s, setting hostility again
   if it has slipped. Cyberbane sets hostility once at setup. The same short watch over our tagged crews
   (attitude only, no AI order) is cheap insurance.
3. **Intel from a scan.** A completed scan of a ganger (a wrap of `ScriptedPuppet.OnScanningEvent`, which
   only observes) has a chance to turn up one thing about a Rival of their gang: a weakness V did not know,
   or a lead. Once per ganger. Uses the traits Cyberbane already gives Rivals.
4. **"While you were out".** One line in the game's subtitles a little after a load, once V is really in the
   game: the most important thing that happened since (a Rival promoted, a gang broken, turf taken), from
   the History log Cyberbane already keeps. Never on the loading screen.
5. **A catchphrase per Rival.** Each Rival gets one line of their own, picked at birth from their gang's
   pool, and says it when they arrive, when they get away and in their texts. The same face, the same words:
   cheap, and it makes a Rival a person.
6. **Rival status as the street says it.** The Rivals screen says why a Rival has not come back the way the
   street would ("licking their wounds; back in about two days", "waiting for you in Kabuki"), never naming
   the rules. Cyberbane has the data (`CBRivalSourceLine`, lying low, the lair); only the wording changes.

### Medium

7. **Squeeze a ganger in a grapple.** V grabs a ganger (the game's own grab) and holds them for about three
   seconds, and they talk: a Rival's hideout, a weakness, who is coming next. The game's grapple state is
   `GrappleStandEvents` (`locomotionTakedown.script`, present on 2.5 and 2.31); wrapping its `OnEnter` and
   `OnExit` only observes, and the hold time is counted on our tick, never in the callback. The vanilla hold
   lasts long enough for every rank (`SetGrappleDuration`). The temperaments of section 2 apply: the loyal
   say nothing, the greedy name a price that V pays by holding on, the scared talk at once. A line in the
   subtitles shows the seconds left. A takedown before the end, or aiming (a human shield), ends it
   unsaid. No new key and no prompt: holding them is the question. This is the most natural ganger
   interaction available, because it is a move players already make. Leads go through `CBMarkLeadTold`.
8. **Make the downed talk.** V crouches over a defeated ganger (alive on the floor) and looks at them for a
   few seconds; they give one thing up. And a Rival's body can carry a lead about another of their gang (V
   crouches over it). Built on the look-at Cyberbane already uses and the defeated state it already tracks.
9. **The informant.** Cyberbane's Debtor (a Rival spared twice) retires after one redemption tip. Instead,
   somebody spared who is grateful texts V two or three tips over the next days (where a leader holds court,
   a weakness of another Rival, who is about to come), then "we're square". A small chance, higher if V later
   kills somebody close to them, that the last tip is a set-up: the place is an ambush. All through the
   existing tip and lair code.
10. **Mercy is a choice.** When V defeats a Rival (down, alive), V has about ten seconds: put the weapon away
    for three seconds or walk off and they are spared; finish them and they die. Nothing happens by
    accident (a Rival dropped from a rooftop by a quickhack has not been "spared"). Cyberbane's sparing
    pipeline (`CBSparedCheck`, escapees, `CBRivalSparedByV`) stays; only the decision becomes V's.
11. **Kin who swear revenge.** When V kills a Rival in front of witnesses (`CBCountWitnesses`), a relative
    may swear revenge: a new Rival born a few in-game hours later ("Sister of [name]"), the delay longer the
    farther the news has to travel, with the trait that counters what killed their kin (Cyberbane's traits)
    and a grief text. One pending avenger per gang. Built on `CBRivalAfterFight` and the Rival births.
12. **Send word.** A line on a Rival's Hub page: V sends a threat, with optional terms ("the same way as last
    time", "in front of their crew"). The Rival answers by text, prepares (more guards, armour, a car to run
    to), and waits at a place on the map: the lair machinery Cyberbane already has (`Rivals/Whereabouts.reds`).
    Keeping the terms pays more (bounty, street renown, the gang's fear). Medium, because the preparation
    touches spawning.
13. **Fatal flaws.** A rare, high-rank Rival carries one hidden weakness tied to something V already does: a
    headshot from a precision rifle, a blunt takedown, a burn, a toxin, a Short Circuit. Meeting it kills
    them outright. Learned through intel (items 3, 7, 8, 9). The hit is read in the existing hit hook and the
    kill is queued to the next frame (crash rule: no entity work on the hit thread). Uses Cyberbane's trait
    data.
14. **The announcement.** Before a Rival's crew opens fire, they hold a beat: the crew stays neutral, one of
    them steps out and names the Rival in the subtitles in two to four short parts (what they survived, what
    they did to V, their catchphrase), and the fight starts when it is said, when V hurts one of them, or when
    V walks up. Attitude changes and subtitles only, plus at most one move order per man.

### Larger

15. **Bodyguards that matter.** A gang leader's lieutenants stand as their guards at the lair (Cyberbane's
    hierarchy already ranks them). Kill them first and the leader is weaker for the fight; a guard's death in
    front of the leader sets off a reaction (shaken and quicker to break, enraged for a while, or vowing to
    come for V afterwards).
16. **Bagmen.** Now and then on a gang's turf, a named bagman walks the week's take past V with a lookout,
    spawned out of sight and walking a route that comes near V. Rob or drop them and the eddies go to V's
    inventory (never into the body: crash rule 6); the gang and the lieutenant whose money it was take the
    loss (turf strength, standing). Uses Cyberbane's spawner and its out-of-sight placement.
17. **More ways to arrive.** Rivals and crews already come on foot and by car. Add: two bikes for the Tyger
    Claws, a marksman of theirs on high ground covering the Rival's approach, and the call-out (the Rival
    texts a place, turns up there a minute or two later and waits). Each is a new arrival style in
    `Spawn/Arrival.reds`.
18. **Surrender.** A beaten ganger sometimes gives up instead of running: they stop fighting (attitude
    neutral, their threats cleared, one hold-position order, the game's own fear animation), hands empty.
    V answers: walk away or holster and they go; squeeze them (item 7) and they talk; shoot them and the
    street hears that V killed someone with their hands up (Conduct, fear, witnesses). Stay Dead gets the pose
    from its own animation archive, which Cyberbane will not ship, so ours is script-only and plainer. Larger
    and less certain: it depends on how a ganger's AI takes the hold order mid-fight.
19. **"Nobody kills V but me".** When V is outnumbered by somebody else's people, a Rival with a claim on V
    may roll in with their crew and fight on V's side, then walk off with a promise of "tomorrow", and keep it.
    Cyberbane already sets its people against V's companions (`CBCompanionHostilityTick`), the same kind of
    attitude work. Larger: a truce that ends if V shoots them.
20. **Gang events with a time and a place.** A lieutenant executes a prisoner at a marked spot at a set hour,
    or a gang's leaders hold a sit-down. V hears of it (a text, a pin) and can stop it, crash it, or let it
    happen, with turf and standing following. Built on the lair pins and spawns. The largest item here.
