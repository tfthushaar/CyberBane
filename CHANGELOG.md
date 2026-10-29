# Changelog

All notable changes to Cyberbane are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [1.2.5] - 2026-10-30

### Changed
- **Three lanes, three clocks: one rival, one crew, one apex squad.** Every rival used to run
  its own countdown, hit squads ran theirs and the apex ran a third, so the Hub showed several
  timers for things that could not all happen and anything without a clock just said "due".
  Now exactly one contender per lane is on the clock. A rival can catch you while a gang's crew
  is already on its way, but two rivals can never jump you at once, and nor can two apex squads.
- **The Hub has an INCOMING block** on the first screen showing all three lanes at once, each
  one either counting down, saying who is here now, saying why it is held, or saying plainly
  that nobody is coming. An empty lane says "nobody", because silence used to mean either
  nothing is coming or something is stuck and those looked identical.
- **Who comes next is ranked, not random.** A gang that has sworn a vendetta outranks one that
  merely dislikes you; a rival who has got away from you repeatedly outranks a new one. The same
  gang or rival will not take two turns in a row while somebody else is owed one.
- **They arrive the moment the clock ends**, instead of a second or two later.

### Fixed
- **Clearing a crew or an apex squad frees their lane immediately.** It was being judged by a
  tag, and the tag stays on the body after death, so wiping a crew left that lane blocked for
  minutes. Rivals were fixed in 1.2.4; crews and apex squads had the same bug.
- **A chase stays a chase.** The order to come after you finished once they reached you, so the
  moment you broke away they reverted to ordinary behaviour and drifted off, which read as them
  giving up rather than you escaping. Anybody still alive who has fallen behind is told again.
  Nobody is ever moved, and you can still outrun or outdrive them.
- Escaping a rival puts them on a cooldown again. The refactor had quietly orphaned that, which
  would have let somebody you just shook be picked as the very next encounter.
- A lane can no longer send a second encounter during the moment between asking for a spawn and
  it existing.

## [1.2.4] - 2026-10-29

Found by watching a live session.

### Fixed
- **A gang arriving in numbers shouted its warning once per member.** Thirteen Barghest turning
  up meant thirteen copies of the same line stacked on top of each other in the middle of the
  fight. They still each decide to draw on you; only the line is rationed now, using the same
  cooldown the street's other overheard lines already share.
- **Killing a rival blocked every other rival.** "Is one of them out there" was answered by
  looking for the tag Cyberbane puts on them, and that tag stays on the body after they die
  until a sweep clears it a couple of minutes later, which never happens during a fight. So
  putting one down left the whole list stuck on "waiting their turn" with nobody actually out
  there. A corpse no longer counts as somebody hunting you.

## [1.2.3] - 2026-10-29

### Fixed
- **The Hub now tells you why a gang's crew has not turned up.** It could already explain a
  held rival, but only on the Rivals screen and only after a rival had actually been turned
  away. A hit squad or apex squad whose timer had run out and was waiting for a workable moment
  showed nothing at all, which is indistinguishable from the mod being broken. The gang's line
  now reads "HELD:" and the reason, instead of a countdown sitting on zero.

## [1.2.2] - 2026-10-29

From player feedback asking what the titles actually mean and for a less hidden way to read
your standing.

### Added
- **The Titles screen now shows what you have not earned yet, and what each one takes.** Every
  locked title lists the thing you would have to do, with a count where there is one to show,
  so the system is something you can go after rather than something that happens to you.
- **A bar across the top of the screen for whoever is hunting you**, with their name and their
  health, for an apex squad enforcer or a rival far enough up the ladder. This is Cyberbane's
  own, drawn in the game's style, because the game's boss bar cannot be driven by a script mod
  on this version. Uses the apex squad boss bar setting.
- **Titles arrive as a message from somebody on the street** rather than a system notice. A
  title is what other people decided to call you, so hearing it from them is the right way
  round.

### Changed
- The Titles screen says "you are going by this" and "change which title you go by" instead of
  naming a key combination and leaving you to work out what Auto meant.

## [1.2.1] - 2026-10-29

Found from a live session: enemies were spawning correctly and then doing nothing.

### Fixed
- **Spawned enemies stood around until you walked into them.** This is why an arrival could
  feel like nothing had happened even when it had. At the exact moment the game creates an NPC
  its insides do not exist yet, and Cyberbane was turning it hostile and ordering it to come
  find you in that same instant. Both orders were being quietly discarded, so the NPC carried
  on as whatever it had been spawned as, which for an NCPD rival means a neutral cop standing
  in the street that only fights back when you get in its face. Cyberbane now waits until the
  game has finished building them before giving any orders, and retries until it has.
- **No health bar on a rival**, for the same reason and fixed by the same change.
- **One badly timed squad could stop every later one, for the rest of the session.** A crew
  whose timer ran out at a bad moment - mid-fight, on a quiet job, in a safe area or a quest
  area - correctly waited instead of barging in, but it waited forever, and nothing new could
  be scheduled while one was waiting. So a single unlucky expiry in somewhere like City Center
  silently ended hit squads for that playthrough. An appointment that cannot find a workable
  moment now gives up after a couple of minutes and gets rescheduled.
- The same hold could stall a pending apex squad indefinitely. Fixed the same way.
- **The mod was standing itself down while you walked around.** Cyberbane counted people
  appearing nearby as a sign the game was rebuilding the world, and paused itself when there
  were a lot. Walking through a busy district trips that constantly, which is why arrivals
  landed when you stood still and not when you were out in the city, and why hit squads and
  apex squads never came at all: the part that decides to send them was paused too. That count
  now only skips the heaviest piece of work. Everything else keeps running, and an arrival that
  genuinely cannot land still refuses and reschedules on its own.
- **Enemies no longer turn up standing in mid-air.** A spawn point was allowed to be fifteen
  metres above or below you, which is three storeys, so a billboard or a first-floor walkway
  counted as solid ground. Somebody coming to fight you now arrives on your level.
- **You can escape a rival, and it counts.** Losing one did nothing at all: they vanished, their
  timer restarted, and the same person reappeared behind you a short while later. With no way to
  get away, the only way to resolve a rival was to kill them, which is the one outcome that
  stops them ever being promoted. Shaking a rival now promotes them, tells you that you lost
  them, and buys real time before they find you again.

## [1.2.0] - 2026-10-29

Everything the feature audit found dead or missing is now implemented.

### Added
- **How you look right now matters, not just what you are known for.** Walking around with a
  weapon out, with chrome running, mid-fight, standing over fresh bodies, or with the police
  already after you all make you read as dangerous on the spot. This was written into the
  design from the start and never connected to anything, which is why walking around armed and
  bloody got the same reaction as walking around clean.
- **Different people have different nerve.** Every gang has had a courage value since the first
  release and nothing ever read it, so a Valentino and a passer-by reacted identically. Tyger
  Claws hold their ground a little better than a civilian; Maelstrom better again.
- **Cyberware quality counts.** A rack of legendary chrome now reads as more frightening than
  the common version of the same slots. The weighting was written and never applied.
- **Ordinary work gets talked about.** Word only spread from massacres and boss kills, so the
  whole premise of reputation travelling because somebody saw it almost never happened in
  normal play. Any witnessed kill can now become word on the street: somebody who mattered
  always travels, the rank and file sometimes, and a bystander going down travels fast. Clear a
  room with nobody left alive and still nothing spreads, which is the point.
- **Hit squads arrive on a visible clock.** They were a roughly four percent dice roll taken
  once per in-game hour, so at full hostility one turned up about once an hour of play and the
  Hub had nothing to show because a dice roll cannot be counted down. Now a gang that is
  hostile and knows who you are puts a crew together on a timer between about four and fifteen
  minutes depending on how much they hate you, and the Hub counts it down like everything else.
- **Switching your title tells you it worked.** Cycling the active title with Ctrl and the Hub
  key always did work and stuck, but it was completely silent: unless you happened to be on the
  Titles tab you could not tell anything had happened, which makes a working feature look like
  a broken one. It now says who you are going by.
- **The Konpeki Ghost title can be earned.** It was the only title in the mod with no condition
  at all, hanging off quest detection that cannot work. It now means what its name means: a
  great deal of work, as a Ghost, that nobody could put a name to.

### Changed
- Common-tier cyberware scores lower than it used to now that quality is weighted, so your
  chrome score may drop a little on an existing save if your implants are mostly common. Rare
  and above gain. This is the weighting working rather than a loss.
- Crowds react more during a fight, because being mid-fight now counts toward how dangerous you
  look. The same person still will not flinch twice in quick succession.
- Removed a leftover settings category label from the ten settings deleted in 1.1.4.

## [1.1.9] - 2026-10-29

Found by going through every feature in the mod and checking it against what it claims to do.

### Fixed
- **A civilian could only ever be frightened once.** The flag marking "this person has reacted
  to you" was set the first time and never cleared, so once somebody had flinched at you they
  were inert for the rest of their life. Crowd NPCs hang around a district, so after one walk
  down a street nobody there would react again no matter how much more frightening you became
  or how many times you came back. Along with the pause bug in 1.1.8, that is most of why the
  city never seemed to fear you. People can be frightened again now, after a short cooldown.
- **Sparing someone who is already a Rival did nothing.** Every mercy created a brand new
  Rival, so letting the same person live twice was never recorded. The code that counts it,
  turns them into a Debtor who owes you one, and promotes them was never called from anywhere
  in the mod. That also meant the nemesis ladder only ever climbed from escapes, never from
  mercy, despite mercy being half the point. Letting a known Rival walk now counts, and they
  carry the new scars on top of the old ones.

## [1.1.8] - 2026-10-29

### Fixed
- **The mod was standing itself down almost all the time, and that is why nothing happened.**
  Cyberbane watches for the game rebuilding the world around you and pauses its own work while
  that happens, because running then can crash. The counter feeding that check was counting
  every single thing that streamed in: every pedestrian, car, parked bike, prop, door and
  vending machine. The limit was set thinking about people, so on any populated street it was
  tripped more or less permanently, and each trip paused the mod for thirty seconds. It now
  counts people only, the limit is higher, and an ordinary crowd settles in six seconds
  instead of thirty.
- **This was starving almost everything, not just arrivals.** Rival timers, apex squads, hit
  squads, tribute, rumours spreading, titles being earned, crowd fear, and even your own score
  updates all live behind that pause. If the city has felt like it was ignoring you, or your
  scores looked stuck, this was why.
- **Timers keep running while the world loads.** Counting down is arithmetic on Cyberbane's own
  numbers and cannot be the thing that crashes, so only the arrival itself waits now. A timer
  that reaches zero during a load simply waits at zero instead of freezing partway.
- **The Hub says why nothing is coming.** Every refusal now names itself: the world is still
  loading, you cannot draw a weapon here, you are on a job, a protected area, a safe area, no
  ground to stand on, or the game refused the spawn. No more staring at a number that is not
  moving and guessing.
- **A new setting: "stay out of quest areas"**, on by default. Quest areas can cover a lot of
  ground, and this was the last thing that could quietly hold every arrival back. If arrivals
  never come, the Hub will tell you this is why, and you can switch it off.
- The check for whether you can draw a weapon where you stand is now written so that it can
  never read true before the game has said anything, which is the mistake that broke arrivals
  in 1.1.5.
- The out-of-view test for spawn points no longer depends on an assumption about whether an
  angle is measured in degrees or radians, which would have silently disabled it.

## [1.1.7] - 2026-10-29

### Fixed
- **Nobody was arriving anywhere, and the Hub said they all would "any moment".** A check added
  in 1.1.5 was reading the game's own security zone and treating the low values as protected.
  The open street reports a low value too, so that quietly blocked every rival and apex spawn in
  the entire city. Their timers ran out against a gate that never opened, which is why they sat
  on "any moment" and nothing ever came. The zone is now only a blocker when you are also
  indoors, which is how the mod this was learned from uses it.
- **A queued arrival is confirmed before it counts as arrived.** The game hands back a valid
  entity when a spawn is requested even if it then declines to place it, so "queued" was being
  treated as "arrived". A rival that never materialised stayed marked as hunting, held the
  one-at-a-time slot, and blocked everybody behind it. Cyberbane now checks a few seconds later
  whether they actually turned up, and tries again if they did not.
- **Arrivals are placed properly out of view.** They were being put 20 m behind you, which one
  camera turn is enough to bring into view, and an out-of-view spawn that comes into view is
  not refused loudly, it is silently never placed. Points are now rejected unless they are well
  off your facing and far enough back for that to hold, and arrivals come at a run so the extra
  distance costs nothing.
- Chrome that drives visual effects (Sandevistan, optical camo, berserk) is no longer granted to
  gang enforcers. A crash report came in from inside the game's effect system while an NPC was
  being processed, and although nothing named Cyberbane, this was the only new thing it was
  doing that touches that system. The abilities that change how they fight are all still there.

## [1.1.6] - 2026-10-29

### Fixed
- **Rival countdowns were frozen on a small number.** The clock kept running while an arrival
  was impossible, hit zero, got reset to the retry interval, ran down and reset again, forever,
  and because all three things that block an arrival are global this happened to every Rival at
  once, so the Hub showed all of them pinned at the same figure. A held clock now actually
  stops, and the Hub says what it is waiting for instead: you are in a fight, one is already
  out, you are on a quiet job, or there is nowhere here to put anybody.
- **The Hub is live.** It drew itself once when you opened it and then sat there, so every
  countdown on it was a snapshot from the moment you pressed the key. It updates every second
  while it is open now.
- **The apex squad has a visible countdown.** The warning clock was being thrown away the
  moment the squad was dispatched, so they arrived with nothing on screen. The Hub counts the
  warning down and then keeps counting while they drive, and says which of the two it is.
- **Rivals no longer arrive in a bunch.** The countdown was a function of rank and nothing
  else, so every Rival of the same rank had an identical timer to the second and they all
  queued up to arrive together. They are spread out now.
- **An overdue arrival says so.** If the timer runs out and there is genuinely nowhere to put
  them, the Hub tells you, instead of quietly showing a fresh countdown that is really a retry.
- An apex appointment could stall permanently if the gang's record lookup failed, because the
  pending state was never cleared.

### Added
- **The MaxTac descent horn plays when a gang sends its apex squad.** The game's own one. If
  you have ever drawn a five star heat level you know what it means, and it means the same
  thing here. There is a setting for it.

## [1.1.5] - 2026-10-29

### Added
- **The apex squad fights like MaxTac.** Four roles, not four copies of the same ganger: a
  heavy who walks at you and breaks your guard, a shooter who flushes you out of cover with
  grenades, a blade who closes the distance on a Sandevistan, and a netrunner who hangs back
  and takes your weapon off you. Each chair is filled with a real record of that kind belonging
  to that gang, so the game's own AI gives them the right weapon and the right behaviour, and
  each one is handed a kit of real gameplay abilities on top.
- **They fight as a squad.** Everyone Cyberbane sends as a group now joins one squad, so they
  coordinate instead of picking their own targets. Before this an arrival was four separate
  duels standing next to each other.
- **An apex squad gets the boss health bar.** The game's own one, across the top of the screen,
  the same bar a story boss or MaxTac gets.
- **Rivals are built to apex grade, and they climb.** A Rival is now one apex-grade enemy
  where an apex squad is four of them, and they get stronger every single time they get away
  from you, every time you spare them, and every time they put you down. Mercy and failure both
  have a price now, and the price is the person you meet next time. Every Rival arrives with
  the game's own boss health bar, because every Rival is built to that grade.
- **Rivals fight like somebody with a name**, with the same role kit. A named enemy that never
  used cover or chrome was a ganger with a nameplate.
- **A gang at vendetta sends the apex squad with the crew.** Four boss-grade enforcers in a
  car, the rest of the crew on foot behind them. This is the hardest fight Cyberbane will put
  in front of you, and there is a setting to turn it off.
- **They drive over.** A hit squad or a gang's apex now arrives by car. One is spawned out of
  sight, loads its crew, drives to you and the crew gets out and comes for you; if you are
  behind the wheel, it gives chase instead. A car cannot reach you indoors or where there is
  no room to put one, and then they arrive on foot as before. There is a setting for it.
- **A gang at vendetta sends a strike team of four.** Not one heavy with an escort: a carload
  of boss-grade enforcers, a gang's own answer to MaxTac.
- **Apex strength is yours to set.** A slider from 20 to 100 percent of a full boss build,
  default 70. It scales health, armour, damage and crit together, and your own menace still
  scales it on top, so an apex is always measured against where you actually are.
- **Every apex has two traits of its own**, so no two fight the same way: heavier plate, a
  harder hit, a better eye for the gap in your armour, a deeper health pool, or simply
  fighting above its level.
- **The Hub shows when a vendetta crew arrives**, counting down on the gang's own line next to
  the apex readout.
- **New Game Plus is detected**, and Cyberbane halves its own apex buffs and stops rolling its
  traits when it is installed, because that mod already rebuilds every NPC in the game and the
  two sets of buffs multiply rather than replace.
- **Ability kits stand down for Much Better AI and New Game Plus.** Both already equip NPCs,
  and ability packages stack rather than merge, so two mods each handing out a Sandevistan
  produce an enemy with two of them. Either one installed and Cyberbane leaves the kit to them
  and keeps what is its own: who gets sent, when, in what, and the boss bar.

### Changed
- **"Apex" is "apex squad" everywhere**, in the Hub and in every message, because it is four
  people now rather than one.
- **On-screen messages stay up long enough to read them.** They were going away too fast. Every
  Cyberbane message is now held for most of a second longer than the game's own notifications,
  never less than five seconds, and there is a slider if you want longer still.

### Fixed
- **Paying a gang off now costs what they actually think of you.** It worked, but the price was
  the body count and nothing else, so a gang at vendetta charged exactly the same as one that
  merely disliked you. The price now also rises with how far their standing has fallen, and a
  vendetta costs double, because a vendetta is a decision they have already taken and taking it
  back should be expensive. The cap is higher to match.
- **Paying a gang off calls off what they already had coming.** The Hub went on counting down a
  crew from a gang you had just paid, and a pending apex warning still stood.
- **A gang at vendetta now actually comes after you.** This is the Barghest report. A vendetta
  was rolling the same dice as a gang that merely disliked you: it still had to clear a renown
  gate and then win a roll of a few percent per check, so a gang could sit at vendetta
  indefinitely and never send anybody. A vendetta is a decision that has already been taken,
  so it is now a certainty on a clock that the Hub shows you. Broker peace while they are on
  the way and they are called off.
- **Nobody is sent into V's apartment any more.** This is the H10 report. Cyberbane had been
  asking the game's safe-area system, but an apartment's weapon lock comes from a separate
  restriction layer, so the apartment passed the check it was being given. Cyberbane now asks
  the question that matters - can V draw a weapon here - and also stands down inside any quest
  or gig area and in the game's own safe and restricted security zones.
- **Arrivals are placed on the navmesh and checked for a walkable route to you.** The old
  check only asked whether there was a floor under the spot, which is not the same question as
  whether a person could stand there and reach you: a spawn across a wall, on a balcony
  opposite, or in a sealed lot all passed it. That is also the end of the mid-air arrivals.
- **Arrivals come at you.** They were hostile but had no reason to move, so an encounter could
  spawn forty metres back behind a wall and wait there until you happened to walk into its
  line of sight. This is the single biggest reason the mod could feel like nothing was
  happening. They are now told to come and find you.
- **A large crew forms up in ranks instead of a single line.** Twenty people at two and a half
  metres apart was a fifty metre row, most of which failed the ground check.
- **An apex no longer walks into a one-room flat**, where there is nowhere for anyone to come
  from and they can only appear in front of you.
- **They Will Remember is now detected exactly**, by asking the compiler whether its scripts
  are in the build rather than by matching the name of a settings page. The name match stays as
  a fallback, because Night City Remembers is a separate rewrite.

### Changed
- An apex hits as hard as it takes. It was close to a pure health sponge, which is tedious
  rather than frightening; it now carries damage and crit scaling too.
- Vendetta crew size scales with your menace, up to a number you set (default 20).

## [1.1.4] - 2026-10-29

### Fixed
- **Killing a Rival counts now, every time.** Cyberbane recognised a Rival by a marker on the
  body, and it was wiping that marker about ten seconds after they turned up. If the game could
  not remove them while you were fighting, they stayed in the world unmarked, so killing them
  did nothing: no message, no change in your standing with them, nobody promoted in their
  place, and the same Rival back again later. Cyberbane now remembers exactly which body is
  theirs, so the kill lands whatever has happened to the marker.
- **Rivals are no longer retired almost as soon as they arrive**, and never while you are
  fighting them.
- A Maelstrom street handle read as a crash. "Null" is now "Nullwire". It was a real name from
  the gang's name pool all along, sitting next to Static and Rustbite, but seeing a rival
  called Null is not reassuring and the report was fair.

### Changed
- **Removed ten settings that did nothing.** Police recognition, known offender, friend of the
  force, cop morale, rival nameplates, rival cards, the low profile icon, pronouns, the Dogtown
  toggle and the debug overlay were all listed in the menu and wired to nothing at all. A
  setting that does nothing is worse than no setting. The thirty nine that remain all work and
  all explain themselves.

## [1.1.3] - 2026-10-29

### Added
- **Rivals carry what you did to them.** Set someone on fire and the one who comes back is
  burned. Shoot them, cut them, fry them with a quickhack, and they wear that instead. It
  shows on their line in the Hub, so you recognise them before they open their mouth.
- **Gangs have a leader and lieutenants.** Your Rivals fill those chairs. Put the leader down
  and the strongest of the rest steps up and takes the crew, which means you can fight a gang
  but never behead it: there is always somebody next in line. The Hub shows who runs what.
- Running a crew is now worth something. A leader takes real killing, a lieutenant takes more
  than the rank and file. Rank used to be a label with nothing behind it.

### Fixed
- The Hub's rows can no longer run into each other. Each column now trims to what its box can
  actually show, so a long rival name stops at the edge instead of printing over the next
  column.

## [1.1.2] - 2026-10-29

### Fixed
- **Killing cleanly is no longer treated as butchery.** Every lethal kill added a full point
  toward Butcher no matter how it was done, so a player who took a whole hideout apart quietly
  from range still ended up labelled a Butcher. Worse, a clean stealth run scored Butcher and
  Ghost dead level, and a tie silently went to Butcher. How you kill is what counts now:
  finishers, dismemberment, blades and fists are butchery, a clean kill barely registers, and
  killing without being seen reads as the ghost work it is.
- **Nobody walks in on a stealth job.** Cyberbane only asked whether you were in combat before
  sending someone after you, and a player sneaking through a place is not in combat, so rivals
  and hit squads turned up at the worst possible moment and their arrival alerted the guards
  you were avoiding. Arrivals now wait while you are working quietly and come once you are
  clear, so you never lose the encounter, you just do not get ambushed mid-infiltration.
- **The Hub no longer promises someone who never comes.** A held arrival kept resetting its
  clock to a few seconds, so the Hub said one was seconds away over and over. It now says it is
  holding off and why.
- Non-lethal takedowns are no longer the only way to stay out of trouble. Clean lethal work
  counts as professional too, which was the point all along.

### Added
- **Every setting now explains what it does.** All forty nine of them have a description in
  Mod Settings, instead of a bare name you had to guess at.

## [1.1.1] - 2026-10-29

### Fixed
- **Nobody comes after you inside an apartment any more.** A Rival could turn up in a safe
  area, and the game forces your hands empty in those places, so you were attacked somewhere
  you could not draw a weapon. Rivals, hit squads and apex hunters now stay out of apartments,
  bars, clinics and the like, and a Rival who was due to arrive waits for you to step outside
  rather than losing their turn.
- **Crowd reactions understand safe areas properly now.** Cyberbane used to decide with a
  single yes or no based on where you were standing, so stepping into a doorway switched off
  every reaction in the district. It now works person by person, the same way the game itself
  does: people inside a bar are left alone while the crowd on the pavement outside carries on
  reacting normally. An outdoor safe area, a memorial for instance, no longer silences the
  people standing in it.
- Cyberbane also stays quiet during scripted moments where the game has put a lid on combat,
  which it used to miss entirely.

### Added
- **Two settings for people who want that fight anyway**, both off by default and found under
  Safe areas in Mod Settings. One lets rivals, hit squads and apex hunters turn up inside safe
  areas. The other stops the game forcing your hands empty when you enter one, so you can
  fight back. They are only sensible together.

## [1.1.0] - 2026-10-29

### Fixed
- **The crowd really does react now.** Cyberbane only ever noticed an NPC if that NPC happened
  to arrive at a quiet moment. Anyone who turned up while the game was busy, which is most of
  a crowd while you are walking, was skipped and never looked at again. They were invisible to
  the mod for good, which is why nobody flinched even at point blank.
- **Rivals have names.** Anyone from the police or a corp came out as "Unknown", because those
  factions had no names to draw on. They do now, and nobody falls back to being called Unknown
  any more.
- **Killing a Rival counts.** If one had been hanging around long enough for Cyberbane to stop
  tracking it, killing it registered as nothing at all.
- The Rivals screen ran its columns into each other.

### Added
- **You can see them coming.** Rivals used to arrive on a dice roll, so one might show up in
  ten seconds or never. Each one now has a clock, the Hub shows it, and they arrive the moment
  it runs out, wherever you are. Higher ranks find you faster. The gang screen shows the same
  countdown for an apex hunter on its way.
- **A rebuilt Hub.** Tabs are tabs you can see, your scores are meters rather than numbers in a
  sentence, and gangs and rivals are colour-coded rows. Red means they are coming for you.
- **Shift + Hub key on the Rivals screen forgets every rival.** Updating the mod mid-playthrough
  could leave rivals built from records that no longer made sense, with no way to clear them.

### Changed
- Rivals and apex hunters arrive much closer to you. They used to turn up far enough away that
  you could drive off before meeting them.
- More people take against you. An enemy who gets away from you bleeding comes back as a Rival
  far more often, and killing a Rival, an officer or a boss now usually means someone rises to
  avenge them.
- **The Hub says how many Rivals you are carrying and what the limit is.** Once you are at the
  limit nobody new can take against you, so the ones you already have close in faster, giving
  you the chance to clear some out the only way that counts.

### Compatibility
- **Street Sense** is detected automatically. It owns crowds noticing and calling out to you,
  so Cyberbane stands its own overheard lines down and sticks to being feared. Everything else
  carries on. Thanks to DigitalVixen for the mod.

## [1.0.0] - 2026-10-28

First full release. Everything below is what changed since 0.1.19.

### Fixed
- **Wounding someone and walking away now makes a Rival.** Cyberbane only remembered an enemy
  if it first decided they should run, so half of everyone you shot to the brink and left
  behind was never even considered. It remembers them either way now. This is the one that
  was stopping "leave them alive" from working.
- **A gang that never managed to send its apex no longer loses the bodies anyway.** The kill
  count was spent the moment the warning went out, so if the hunter failed to turn up for any
  reason you were charged twenty kills for someone who never arrived, and it looked like the
  feature did not exist. The count is only spent once they are actually there.
- **Nobody arriving at all is no longer possible.** Cyberbane looks for solid ground before it
  puts anyone down, and if that search came up empty it simply did not place them. One bad
  search quietly switched off Rivals, hit squads and apex hunters together. It now falls back
  to putting them in close rather than not at all.

### Fixed (fear and chrome)
- **Your chrome could never read higher than 60.** The visible areas it counts add up to a
  ceiling the scale could not get past, so filling every slot still left you at 60 out of 100
  and unable to look any more frightening than that. A fully chromed V now reads in the
  nineties, and arms alone are enough to be clocked across the street.
- **The Hub kept saying people feared you for your chrome** no matter how many bodies you had
  left behind. It was comparing the raw numbers instead of how much each one actually feeds
  your Dread, and chrome has a much higher number but counts for a lot less. It names the real
  reason now, which for most players is the body count.
- **The Hub tells you why the city is ignoring you.** If nothing is reacting, the first screen
  now says which of the reasons it is: the mod switched off, crowd reactions switched off, the
  game treating where you stand as a safe area, or nobody nearby being tracked. It also shows
  how many people it is watching.
- **Cyberbane now asks the game directly whether you are standing somewhere safe**, instead of
  reading a player state value it had to interpret. That interpretation was the mod's weakest
  point: if it got the answer wrong it stood down crowds, gangs, morale, apex hunters and the
  mercy check all at once, which looks exactly like the mod doing nothing at all. And if it
  cannot get an answer now, it carries on rather than assuming the worst.

### Fixed (things that were advertised but never worked)
- **Finishing jobs builds your reputation.** The readme has always led with "finish jobs",
  and jobs did nothing at all: the part of Cyberbane that scores them existed but was never
  connected to anything. Gigs, jobs and NCPD work now count, with bigger contracts worth more
  than street hustles. This also means the jobs you pull feed into how frightening people
  find you, which they never did before.
- **Cyberpsychos are recognised as cyberpsychos** rather than scored as ordinary gangers, so
  hunting them down, or putting them down without killing them, means something.
- **Five titles could never be earned.** Fist of Night City, Psycho Whisperer, Psycho Hunter
  and Untouchable had no way to unlock. They do now. Konpeki Ghost has been retired: it was
  tied to one specific quest played one specific way, which Cyberbane cannot detect, and
  offering a title nobody can earn is worse than not offering it.
- Coming through a real fight without taking a scratch now counts, which is what Untouchable
  was always supposed to be about.
- Gangs differ in how easily they break. The faction table has always carried a courage value
  and nothing read it, so every crew held its nerve the same way.
- Removed a settings toggle that did nothing. What it promised, your existing Street Cred
  counting as reputation you had already earned, is what the Street Cred floor setting does.
- Cyberbane no longer claims to integrate with Native Interactions Framework or Equipment-EX.
  Neither integration was ever built. Outfits are read through the game's own equipment slots,
  so outfit mods work without one.

### Added
- **Enemies have nerve.** Who breaks and runs now depends on what they are. Rank and file
  crack, officers mostly hold, elites rarely run and bosses never do, instead of everyone
  rolling the same dice. Thanks to cshiai's Much Better AI for the idea of giving each enemy a
  temperament rather than one global chance.
- The Hub's gang screen counts down to each gang's apex hunter, so you can see how close they
  are instead of guessing.

## [0.1.19] - 2026-10-28

### Fixed
- **Stealth takedowns were invisible to the mod.** Cyberbane worked out who was responsible
  for a body from damage events, and a takedown does not produce one. So knocking someone out
  never made them a Rival no matter how many you spared, and a lethal takedown earned no
  reputation at all. Takedowns are now recognised, lethal and non-lethal both. If sparing
  people has done nothing for you, this is why.
- Sparing someone used to take two minutes of standing around before anything came of it.
  It now settles in about twenty-five seconds.
- **Witnesses have to be able to see you.** Anyone inside the radius counted before, even
  through a wall or on another floor, which made quiet work far harder than it looked. Line
  of sight is checked now, so cover and walls do what you would expect.

### Changed
- Rivals come from sparing and from enemies who get away far more often: sparing is roughly
  double what it was, and survivors and avengers are up as well. They were rare enough that
  players could spare a dozen people and never see one.

### Compatibility
- **Much Better AI** is detected automatically and needs no setup. Its Nerve system owns
  morale, so Cyberbane stops pushing the same enemy to panic and stops breaking the same squad
  on top of it. Everything else Cyberbane does carries on, including tracking who got away, so
  Rivals still come from enemies that Much Better AI sent running.

## [0.1.18] - 2026-10-27

### Fixed
- **The Hub's first screen was writing over itself.** The Legend tab had grown past the space
  it was given, so the bottom of it ran straight through the footer line and off the end of
  the panel. The panel is taller now, the text sits at a size that fits, and the wording is
  tighter. Nothing was dropped.
- The Hub can no longer overflow like that again, whatever gets added to a screen later. If a
  screen ever runs long it now ends in a visible "..." instead of printing over the panel.
- Your current district reads properly in the Hub. It said "SantoDomingo" where it should say
  "Santo Domingo".

## [0.1.17] - 2026-10-27

### Fixed
- **Titles name the place or the gang now.** "Butcher of the District" was never meant to be
  the title you earned, and the readme has been advertising "Butcher of Watson" the whole
  time. Six titles were shipping placeholder wording because the part that fills in the name
  was never written. They now read Butcher of Watson, Ghost of Pacifica, Heywood's Problem,
  The Merc from Watson, the Animals' Nightmare and Friend of the Mox. This also fixes titles
  you have already earned, so you do not need a new save to see it.
- **Mercy counts however they went down.** Sparing someone only registered when they dropped
  to a hit Cyberbane could see. Anyone who went down to a burn, a quickhack tick, an
  explosion or another mod's damage could end up beaten and breathing with Cyberbane none the
  wiser, so walking away earned you nothing. It now checks downed enemies directly, whatever
  put them there. If you use a dismemberment or gore mod, this is the one that was biting you.
- **Someone who dies after you spare them no longer comes back as a Rival.** If you left
  somebody alive and they bled out afterwards, they could still return with a grudge. They
  are dead, so now they stay dead. Leaving them alive and walking off still works exactly as
  before.

## [0.1.16] - 2026-10-27

### Added
- **Word spreads because somebody saw it.** Every kill used to count as though a crowd had
  watched it. Cyberbane now checks who was actually alive and close enough to see, and that
  decides how far the story travels. Leave people alive and your name moves fast and far.
  Leave nobody and the street never learns who did it: you build almost no reputation you can
  claim, word barely leaves the district, and the place gets a name for something it cannot
  identify instead. Two ways to play fall out of one rule, and it is now a decision in every
  fight rather than a number on a timer.
- **The street gets word back to you.** When a rumour about you reaches a district it had not
  touched before, someone who trades in information may get in touch about what they heard.
  If people saw you do it, your name is in the message. If nobody did, it arrives as a
  question about who is doing this. These are Cyberbane messages rather than calls from real
  fixers, and they switch off with the rest of the mod's messages.
- **A gang does not lose its best and move on.** Put a Rival down and someone can step into
  their place carrying the same grudge, inheriting the standing of the one they replaced
  instead of starting from nothing. The higher the one you killed, the likelier it is. You
  can no longer decapitate a crew in a single fight.

### Changed
- The Hub counts the work nobody saw, and explains what it is worth.
- The Log is now the file the street keeps on you, put together from what people actually
  witnessed. Work nobody saw never reaches that page.
- Because of the witness change, killing in an empty place now builds far less reputation
  than it did. That is the point of the feature, but it will feel different if you have been
  working quietly. Nothing was taken away from what you have already earned.

## [0.1.15] - 2026-10-27

### Fixed
- Rivals, hit squads and apex hunters no longer arrive hanging in mid-air. They were being put
  down at your own height, which is right on flat ground and wrong everywhere else: on a motel
  walkway, a stairwell, a raised lot or the lip of an overpass, the spot behind you sits over a
  drop, and whoever came for you stood in the air above it until something knocked them loose.
  Cyberbane now finds the floor that is actually under that spot and puts them on it. Where
  there is no floor there at all, they come in closer to you instead of being placed blind.
  Thanks to the player who reported this from the Sunset Motel during Ghost Town, with the
  version and patch attached.

## [0.1.14] - 2026-10-27

### Changed
- The conduct axis now runs Professional to Cyberpsycho in the Hub. It is what Night City would
  actually call it, and it reads a lot better than the old wording.
- The heavy a gang sends now scales with your build. It reads the same measure of how dangerous
  you are that the rest of the mod uses, your level, Street Cred and skills together, so an early
  character meets something beatable and a maxed-out merc meets something that can actually take
  a beating. The Hub shows roughly how tough the next one will be.

### Fixed
- Cyberbane no longer remembers a one-off story character as the template for the people a gang
  sends after you. It keeps generic gang archetypes only, so you will never meet a walking
  duplicate of someone you already put down. Hit squads had the same gap and are covered too.

## [0.1.13] - 2026-10-27

### Changed
- The heavy a gang sends after you is a real fight now. It is still built from that gang's own
  toughest member rather than any story character, but it is lifted to boss grade, so it no
  longer goes down like the elite it was based on.

### Fixed
- Removed the last two places where Cyberbane kept a list inside a saved record. One of them was
  the same shape that caused the crashes people were reporting, and it turned out to be written
  but never read, so it is simply gone. Every list Cyberbane saves now sits where the game
  expects one. Your kill tallies by enemy type restart from zero as part of this, so one or two
  titles that count those may need earning again. Rivals, gangs, districts, reputation and the
  titles you already hold are untouched.

## [0.1.12] - 2026-10-27

### Added
- Keep hitting the same gang and they stop sending squads and send someone who matters. Put
  enough of one crew down and their apex comes looking for you: a named heavy built from the
  toughest member of theirs you have actually fought, with a couple of their people alongside.
  You get a warning line first, then they arrive. No story character is ever involved, so this
  cannot spoil anything or interfere with a quest, and it works for every gang rather than only
  the ones with a famous name. It uses the same setting as hit squads.
- The Hub counts the gang heavies and Rivals you have put down, so the ones you beat stay on
  the board.

### Compatibility
- If another mod already handles gangs coming after you, such as They Will Remember or Night
  City Remembers, Cyberbane now stands its apex enforcers down alongside its hit squads instead
  of sending a second wave on top of theirs. This is automatic and needs no setup.

## [0.1.11] - 2026-10-27

### Added
- Beat someone down and walk away and they can come back as a Rival who remembers it. Sparing
  an enemy was always meant to make a nemesis and never actually did. Finishing them off
  afterwards cancels it, as you would expect.
- The Hub explains itself now. Every screen says what its numbers mean instead of showing bare
  abbreviations, gangs list standing, fear and respect in words, and each Rival tells you how
  they came to hate you. The first screen ends with a line stating exactly what the city is
  doing about you right now, and what it would take to change that.

### Changed
- Night City reacts far more. The thresholds for people noticing you and backing off were set so
  high that most characters never crossed them, which made the mod look like it was doing
  nothing. They are much lower now, the reaction ranges are wider, and more people are checked
  at a time. Intensity and the per-moment cap are still yours to set.
- Visible cyberware counts for more and reads from further off. Chromed legs now count alongside
  arms, eyes and skin, and the more obvious your chrome the further away people clock it.
- Rivals turn up more often, and one that has climbed the ranks comes for you harder than a
  fresh one does.
- Overheard lines come a little more often and from a little further away.

### Fixed
- The Hub key could do nothing at all on some setups. It now works whether your setup reports the
  key press or the release, falls back to F7 when the key setting has not filled in yet, and
  registers itself at several points during startup instead of relying on a single moment.
- Hardened one more place that read an entry without checking it first, the same class of fault
  behind the earlier crashes.

## [0.1.10] - 2026-10-26

### Fixed
- **They Will Remember compatibility was never actually switching itself on.** The setting has
  an Auto mode, and the README said Cyberbane would spot the mod and stand down from the
  systems that overlap. The detection behind Auto had never been written, so Auto quietly
  behaved as Off and both mods ran their own hostility and hit squads side by side. Cyberbane
  now asks Mod Settings which mods are installed, which is the same list you see in the
  settings menu, and backs off when it finds They Will Remember. Night City Remembers is
  recognized too, since it replaces They Will Remember and overlaps the same way. You can
  still force the compatibility mode on or off yourself. If you have been running either mod
  alongside Cyberbane, this is the fix you wanted.
- **Cyberbane now leaves people alone in places the game treats as safe.** Apartments, clinics,
  bars, memorials and similar spots are tagged as safe areas by the game itself, and Cyberbane
  was ignoring that: crowd fear, gang reactions, morale breaks and panic driving all still ran
  inside them. Mourners at the North Oak columbarium would scatter from a well-chromed V, and
  driving the game's flee behaviour around a cramped interior is a bad idea besides. All four
  systems now stand down in a safe area. Thanks to the player who tracked their columbarium
  crashes down to this mod and reported it with the mod list attached.

### Note
Your build counts toward how frightening you are, not just your reputation, so a New Game Plus
character carrying maxed-out chrome and skills reads as terrifying from the first minute even
on a fresh save. That is working as intended out in the city. It is the reason the safe-area
fix above mattered so much in a quiet interior.

## [0.1.9] - 2026-10-26

This release fixes the crash the last three releases kept chasing. The earlier fixes all
treated it as a problem with how Cyberbane looked up its own data, because that is where the
crash reports pointed. It was not: the fault was in how rumors were stored, and each fix moved
it one step further down the same code path instead of removing it.

### Fixed
- **Fixed the recurring crash in the background tick, at the root this time.** Cyberbane spreads
  word of what you have done from one district to the next, and each rumor carried the list of
  districts it had already reached. That list was stored inside your save in a shape the game
  does not reliably bring back, and a list that came back malformed asked the game for an
  impossible amount of memory the moment the rumor spread, which crashed it. Rumors now track
  where they have been as a single number instead of a list, so there is nothing left to come
  back wrong. The same change was made to the traits your Rivals carry, which were stored the
  same way. Thanks to everyone who kept sending crash reports through 0.1.6, 0.1.7 and 0.1.8 -
  the stack traces are what made the real cause findable.
- **Crashes after finishing an NCPD crime.** Clearing a crime scene is the most common way to
  set a rumor going, so NCPD jobs were the likeliest thing to trigger the crash above. Finishing
  one also makes the whole encounter despawn at once, which is exactly when the background tick
  resumes after standing down - so the crash tended to land just after the job, rather than
  during it.
- **Cyberbane now checks its save data when you load.** Anything stored that does not make sense
  is repaired or dropped on load instead of being handed to the game later. This was documented
  behaviour that had never actually been written.
- **Closed off the rest of the same class of crash.** Six more places read a game system without
  first checking it was there, which is the same mistake behind the 0.1.6 crash - sleeping, fast
  travelling, loading or a cutscene could still catch any of them. They are all guarded now, and
  anything that looks up a game system goes through one checked path.
- Cyberbane no longer removes a spawned Rival from inside that Rival's own death, which could
  pull it out from under the game mid-death. The cleanup now happens a moment later, once things
  have settled.
- Reading the district you are in no longer queries the police system on every kill; kills use
  the value the background tick already sampled.
- A kill-streak that never ends, a long session spent turning gangs hostile, and a playthrough
  with many finished Rivals no longer grow their internal lists without limit.

### Changed
- Job payout bonuses are no longer paid twice on a single reward. An NCPD job that pushed your
  Street Cred over a level handed out two rewards at once, and Cyberbane was topping up the
  second one and then counting it again in the first.

### Note on saves
Your reputation, Rivals, titles, factions, districts and log all carry over. Rumors in flight
are cleared once on first load (they expire after three in-game days anyway, and the district
renown they had already earned you is kept), and Rivals start the new storage with a clean set
of traits, which fills back in as they climb. Nothing else is affected.

## [0.1.8] - 2026-10-26

### Fixed
- Fixed the remaining crash in the background tick, which could hit after a load as well as after
  a transition. Cyberbane looks up its content service through the game, and during a load or
  while the world is streaming that lookup could come back pointing at freed memory that still
  looked valid, so the game crashed when the slow tick used it. Cyberbane now looks that service
  up once, at a safe moment, reuses it from then on, and holds the slow tick until it is ready, so
  the tick never touches the unstable lookup again. Thanks to r3bels90 for pinpointing the exact
  call and cause.

## [0.1.7] - 2026-10-26

### Fixed
- The Hub now shows your current Renown and Dread the moment you open it, including right after
  a fast travel or sleep. Before this, the Street Cred floor on Renown and your chrome could read
  as 0 for a short time after a world transition, because those values were only refreshed on a
  slow timer. Opening the Hub now refreshes them on the spot.

## [0.1.6] - 2026-10-26

### Fixed
- Fixed a crash that could still happen after sleeping, fast travelling, skipping time, or
  entering a braindance. Cyberbane was looking up its own data while the game was mid-transition,
  before the service that holds it was ready, which crashed the game. Cyberbane now checks that
  the service is ready first and waits instead of crashing. Thanks to the players who tracked
  down the exact cause and shared their crash reports.

## [0.1.5] - 2026-10-26

Updated for Cyberpunk 2077 2.5.

### Changed
- Cyberbane now runs on Cyberpunk 2077 2.5. Install the 2.5 versions of the required
  frameworks (RED4ext, redscript, Codeware, Mod Settings).

### Fixed
- Reworked how Cyberbane runs during world streaming so it no longer reads world data while the
  game is still loading it in. Cyberbane stands its background systems down during loading, fast
  travel, time skips, and scenes, and resumes once the world has settled. This fixed the
  fast-travel crash.

## [0.1.1] - 2026-10-26

### Changed
- Everyone now reacts to how dangerous you look, not just civilians. Gang members and the
  police can also notice you and back off or flee. Visible cyberware now drives fear directly,
  so a heavily chromed V gets reactions even before building a reputation. Bosses and MaxTac
  hold their ground, and gangs with a vendetta still attack on sight.
- Your whole build counts. Your character level, Street Cred and skills now feed into how
  intimidating you are, so a high-level, skilled, well-known merc gets reactions a fresh
  character never would.

### Added
- Wounded enemies can lose their nerve and run. Catch them and that is the end of it; let one
  get away and it comes back as a named Rival with a grudge.
- Rivals are a proper nemesis now. They actually turn up and chase you, they climb the ranks
  while you leave them alone, and every time one escapes it returns a rank higher and scarred.
  Put down the one hunting you and it is finally finished.

### Performance
- The background NPC checks now do the heavier work only for nearby NPCs, and the tracked-NPC
  list is capped, so dense crowds stay smooth.

## [0.1.0] - 2026-10-25

First public release, available on [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/35847).

### Added
- **Core runtime:** persistent per-save system and global cross-save service, logging,
  tunable config, shared types, the full Mod Settings page, and Codeware localization.
- **Reputation model:** Renown and Dread with their district/faction spread, archetypes
  (Butcher, Ghost, Professional, Chromed, Netrunner, Brawler), titles, and time decay.
- **Code axis:** a Night-City-flavoured conduct meter - Professional (clean, controlled
  work, mercy) versus Cyberpsycho (civilian kills, brutality) - that shifts how people read you.
- **Combat tracking:** kills attributed to you and classified by faction and class; an
  encounter tracker that flags massacres and boss-downs; Street Cred, police Heat and
  chrome (cyberware) all feed the model.
- **The city reacts:** recognized NPCs drop overheard whispers whose tone follows the
  faction's posture, your Code and notable kills (gang bosses, MaxTac). On-screen messages
  for rank-ups, titles, massacres and boss/MaxTac kills.
- **Crowds that react:** pedestrians read how frightening you are and, as you get close,
  cower or flee; once your reputation turns to terror the panic spreads through the crowd.
  How many react at once is capped so the streets never empty all at once.
- **Gangs that turn on you:** a gang you have pushed to a vendetta gives you one spoken warning
  the first time they place you, then attacks on sight. Turn the systems off and every attitude
  change is undone.
- **Enemies that break:** cut down enough of a squad and the survivors can lose their nerve
  and run, though someone always stands and fights. Those who get away can return as Rivals.
- **Vendor prices move with your reputation:** the more the city fears you (and the cleaner
  your reputation as a professional), the better your buy prices; a mad-dog reputation costs
  you extra. The swing is capped, set in Mod Settings, and only ever touches what you pay.
- **Tribute:** a gang you have made feared, but not yet pushed into open war, may quietly pay
  you eddies to stay on their good side. Pay enough gangs and you earn the Feared Landlord title.
- **Hit squads:** turn a gang hostile enough and they send people after you. A squad of the
  kind of member you have fought spawns out of sight and comes for you; squads never stack,
  sit on a cooldown, and clear themselves if you slip away. Give one the slip and a survivor
  can come back as a Hunter Rival. Toggle and frequency in Mod Settings.
- **Rivals that come to you:** a Rival who is hunting you can actually show up in the world,
  wearing the face and gang you remember, instead of only existing on the Hub.
- **The Hub:** a reputation screen in Cyberpunk's own style, opened with the Hub key (F7 by
  default, rebindable in Mod Settings). Each press steps through tabs for your standing (Renown,
  Dread, Code, Street Cred, and what the city fears you for), factions, rivals, titles, and a log
  of what you have done; the press after the last tab closes it. No menu and no mouse needed.
- **Rivals:** named, persistent enemies that rank up, carry traits, taunt about your
  history, and remember your deaths across saves. They climb the ranks on their own when
  ignored, and slaying one can raise an avenger from the same crew.
- **Rumors & districts:** notable deeds spread outward from where they happened, so your
  reputation builds locally before it goes city-wide.
- **Deeds & factions:** notable jobs shift Renown, Dread, faction standing and titles.

- **Gig payouts scale with your legend:** fixers and clients pay the famous more. Sizable job
  payouts get a bonus on top that grows with your Renown tier.
- **Panic driving:** when you are terrifying and fighting out in the open, nearby drivers panic
  and clear the street.
- **Disguise:** masks and hoods make you harder to place, and dressing in a gang's colours makes
  that gang slower to recognize you. (The clothing data this reads from is tuned over time.)
- **Broker peace:** pay a gang you can buy off to drop a hostility or vendetta. The price
  scales with how much blood is between you. From the Hub, hold Shift and press the Hub key to
  buy off the worst gang you can afford; mods can also trigger it through the public API.

- **Presets and titles from the Hub:** a Subtle / Default / Dramatic preset in Mod Settings tunes
  how loud and frequent reactions are in one pick. From the Hub, Ctrl and the Hub key cycle which
  title you wear, or leave it on Auto to always show your highest.

### Compatibility

- A They Will Remember compatibility mode: when it is on, Cyberbane stands down from the
  systems that overlap (hostility on sight, hit squads, faction disguises) and keeps the rest.

### Safety

- The systems that touch NPCs now leave companions, vendors, and anyone in a scripted
  scene or workspot alone, on top of the existing hands-off rule for quest characters.

_Built for Cyberpunk 2077 v2.5. Cyberbane is in active development, so expect frequent updates._
