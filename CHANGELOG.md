# Changelog

All notable changes to Cyberbane are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [1.7.1] - 2026-11-07

The pin a tip puts on your map is Cyberbane's own and stays where the Rival is, and the Rival is
waiting there when you arrive instead of appearing in front of you.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **"I get tips that a Rival has been spotted, I check the map and I just see the NCPD icons."**
  Since 1.6.5 the pin used the variant of the waypoint you drop on the map yourself. That variant is
  not a look but a role: the game keeps one waypoint, finds it by that variant, and moves whichever
  pin it finds. So the pin was not where the Rival was, and anything that touched your own waypoint
  could take it.
- **The pin is Cyberbane's own now, and cannot be mistaken for anything else.** Every pin the game
  has already means something - a hustle, a gig, a cyberpsycho, your waypoint - so the pin no longer
  wears one. On the world map, the minimap and in the world it is a gold bounty-hunt glyph: a mark
  the game has but never puts on any map, and the same one a Rival carries on your minimap when they
  come for you, so the person and their place look like the same thing. Hovering it on the map gives
  the Rival's name and "Cyberbane Rival. Last seen here.", and the pin in the world shows their name
  when you are close. It is on the minimap from the moment the tip comes in, not only once tracked.
  Select it and track it for a route. It is listed under the **Your Property** filter, beside your
  own waypoint and cars. A pin from before this update was never kept in your save, so the new one
  goes up as soon as you load.
- **"When I get to his location he isn't there, then he spawns after a few seconds in front of
  me."** A Rival at their place was only ever put there while you were at least 30 m from it, so
  pulling up at the pin, or walking straight to it, found nobody. They went in once you wandered back
  out past 30 m looking for them, and the check on whether you could see them was the one for
  somebody who walks up to you: anywhere behind you passed with nothing in the way, and so did
  anywhere far in front. They appear a few seconds after the spot is chosen, which is when a player
  looking for them turns round. Now they are put there however close you are, at the place or round
  it, and only where a wall stands between you and them at the shins, the waist and the head, so
  turning round shows you nobody appearing. The search covers a wider ring round the place to find a
  spot like that.

### Known
- **"1.7 gets me a red error."** That is redscript reporting a script that did not compile. Every
  file was checked against the game's own scripts for 2.31 and 2.5 and the Codeware build each one
  uses, and against the compiler's own rules, and no fault turned up. Please send
  `r6\logs\redscript_rCURRENT.log` and your game version: the log names the file and the line.
  As a precaution, the few lines 1.7.0 wrote in a way the mod had never used before are now written
  the way the rest of it is. Nothing plays differently. Whether those lines were the cause is not
  known, so if you still see the error, the log is still what is needed.

## [1.7.0] - 2026-11-06

Everybody sent after you now comes looking for you, drives to you, and has a marker of their own on
your minimap. Apex squads fight like four different people. A few systems that had been quietly
doing nothing work now.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

If cars misbehave on your setup, turn off **Cars arrive on foot too**, under Gangs. That is the
first switch to try: a car coming for you on foot is the path this release opens up the most.

### Fixed
- **"They spawn, but they don't actively search. They just walk around and hit me if they find
  me."** Five separate causes, and it took all of them:
  - The hunt's clocks started when the warning went out, a minute or two before anybody was in the
    world. They arrived with their patience mostly spent and their search already closed tight
    round wherever you stood when the text came. The search now starts when they arrive, from word
    on where you are at that moment.
  - The search itself was a walk to a random point in a circle. It is now a ring that closes on you
    from their own side, tightening over time. They sprint while they are far off and run when
    they are close, and anybody already inside the ring cuts across it.
  - The fear system treated them as bystanders. Anybody near a frightening V could be told to panic,
    so a crew closing in was broadcasting terror at its own members. People sent after you are
    now out of that system. Whether they break under fire is still up to morale.
  - Hunters still running at you were being deleted. Getting forty-five metres clear of a fight was
    enough to have them released as "stuck", even while they were closing the gap. Anybody still
    getting closer is left alone.
  - Their give-up clock ran while a car was on its way to them, so a crew could call the hunt off
    before its own ride turned up.
- **"The apex squad are all the same. All they do is use guns."** A chair was only filled by a
  record of that kind if you had already killed one, so a gang you had only fought shooters from
  sent four shooters with different labels. Every gang now has its own roster: 88 of the game's real
  characters across 14 gangs, a heavy who carries a heavy weapon, a blade who closes in with one, a
  netrunner who hacks you. A gang that has nobody of a kind sends the nearest thing it really
  fields. Their role on the bar now comes from who they are, so the label and the fighting agree.
- **"They don't arrive in cars. I was standing in the middle of the road."** On foot, a car was
  only sent if the game's road data agreed you were near a road, and that test is the likeliest
  reason the logs show no car sent at all since it went in. It is gone. A Rival also only took a car 60%
  of the time, the space a car needed was measured at twice its real size, and hunters could be
  lost at 120 m while their car spawned at 140 m. Cars now come from 110 m, the spot is tried at
  several distances and facings, and every refusal is written to the log. A car that gets stuck
  lets its crew out to come on foot, and the car's orders change if you get in or out of a car
  while it is on its way.
- **"They're all marked with NCPD markers."** The marker was the game's gang-activity pin, which is
  drawn everywhere as an NCPD scanner hustle. Rivals, apex squads and crews now carry their own
  marker on the minimap: gold for a Rival, purple for an apex squad, white for a crew. It stays on
  the minimap through the fight; the one over their head comes off while they are fighting you.
- **"Barghest ambushes give me wanted stars right away, even outside Dogtown."** Most likely because
  Dogtown's Barghest patrols are built on the game's police records, and a kill of one was kept as
  a template for that gang's crews and Rivals, and an enemy built on a police record brings the
  police the moment it fights, wherever it stands. Those records are no longer kept, and any
  Rival already built from one is re-enlisted from the gang's roster the next time you load.
  **This one is an inference from the game's files.** If Barghest still bring stars, please say so.
- **Rival and apex health bars stayed full until the last moment.** The bar read hit points and
  treated them as a percentage, so it sat at 100% until they were under 100 hit points.
- **Wounded enemies almost never ran.** The same mistake: "below 25%" was reading "below 25 hit
  points", and very few people survive to that. Enemies now really do break at a quarter health.
  Because everybody you leave wounded could otherwise come back as a Rival, one who gets away
  now rolls the same chance as one who breaks in a morale collapse.
- **Flawless was nearly automatic.** Same mistake a third time: you counted as unhurt with anything
  over 95 hit points. It now means what it says, and Untouchable is earned.
- **A Rival who arrived could be logged as never having arrived.** The ten-second check waited
  behind "one Rival at a time", which the Rival's own arrival switched on. Minutes later the check
  ran, found the body gone, and put them back in the queue with no escape counted.
- **A gang's tribute offered to let you pay them.** The message paying you went out as a threat,
  with the "pay them off" answer attached.
- **The first Rival on an old save** was numbered 0, which every slot reads as "nobody". They could
  never warn you first, come by car or be picked by a lane. They are renumbered on load.
- **A few overheard lines read wrong**, such as "Everyone's talking about in Watson" and "They put
  Maelstrom' boss in the ground". Lines that open with a gang's name start with a capital now.
- **All of Japantown counted as nowhere.** The game spells it JapanTown, and the mod was looking
  for Japantown. So nothing you did there reached any district, and no gang was on its own streets
  there, which took turf, hanging around in the wrong place and vendor prices with it. Four spots
  in Vista del Rey and one in the Badlands went the same way. Japantown is Westbrook now, as it
  was always meant to be.
- **The Mox were never the Mox.** The game calls them TheMox, so no Mox member was ever recognised
  as one. Hurting them cost you nothing with them and gained you nothing with the Tyger Claws, and
  none could become a Rival. They count now.
- **MaxTac were never MaxTac.** Every MaxTac officer is filed under the NCPD, so they scored as
  cops, MaxTac's Problem could not be earned, and "MaxTac hold their ground" was not being enforced.
  All three work now.
- **The Wraiths had no name.** Their row in the Hub was blank and their texts came from Unknown
  Number. MaxTac's row was blank too.
- **The Heist named you T_KONPEKI_GHOST.** The title had been left out of the list while the Heist
  still awarded it. Konpeki Ghost is a real title again, and earning it by working unseen, which
  has been promised since 1.2.0, works for the first time.
- **Anybody of ours who arrived while you were in a menu, on a call or in a scene stood there doing
  nothing.** They were never made hostile, marked or given orders. They are now set up as soon as
  the world settles.
- **Start Over left things running.** An apex squad already announced still arrived, the hunt line
  stayed up, and the first new Rival could skip their warning. It all stops now.
- **Presets overwrote your sliders on every launch.** With Subtle or Dramatic saved, anything you
  had tuned by hand went back to the preset's numbers when the game started.
- **Disguises did nothing in a wardrobe set**, and could not have done anything anyway, because no
  clothing had ever been listed. Nomad clothing now slows the Aldecaldos down and the Wraiths vest
  slows the Wraiths. Those are the only gang clothes in the game that V can wear.
- **A running Sandevistan did not make you look dangerous**, because the mod was checking a tag the
  game does not use.
- **Messages in Notices mode could vanish after loading a save.**
- **Titles built from a place or a gang read wrong**, such as "the Tyger Claws's Nightmare". It is
  "The Tyger Claws' Nightmare" now.

### Changed
- The settings text for vehicles, markers and disguises says what they do now.

## [1.6.8] - 2026-11-06

People sent to find you walk where they search, they can find you if you stay put, and the ones
you got away from stay gone.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **"They kept teleporting around me, and vanished every time I scanned one."** While a crew or
  a Rival was searching, every searcher was given a new spot to go and look every eight seconds,
  whether or not they had got anywhere near the last one. The spot was anywhere in a circle round
  where they thought you were, at your height, and it was never checked against anything but job
  sites (and after a gig, when every try was near one, the last try was used anyway). So
  searchers were sent into walls, onto roofs, over drops and into lots nobody can get into. The
  game cannot walk somebody to a place like that, and what it does instead, out of your sight, is
  put them there. That is the Tyger Claw who blinked out of the scanner after a couple of seconds
  and turned up somewhere else on the minimap. Every spot a searcher is sent to is now a floor
  with navmesh on it that this searcher has a path to - the same tests a spawn point has to pass
  - and they get a new one only once they reach it, the walk takes too long, or a new search
  starts. If there is nowhere walkable to send them they stay where they are and are asked again
  shortly, instead of being given an order they cannot carry out.
- **"The countdown ends and the Rival never shows up, even with the health bar on screen."** A
  hunt starts from a tip that can be up to 45 m off where you really are, and the search circle
  narrowed round that tip for the whole hunt. Standing still where the warning found you meant
  being searched for 30 to 60 m away until they gave up: they had arrived, which is why the
  health bar showed, and they never came near. Until somebody has actually seen you, the tip now
  firms up the longer they ask around, towards the street's latest word on where you are, which
  is only refreshed every twenty seconds. They still have to see you to start the fight;
  crouching, the dark and moving on still lose them; once they have lost sight of you, they
  search where they last saw you, as before.
- **A Rival coming by car turned up on foot with their people.** A Rival who brings people of
  their own (a Pack Leader, or one of the gang's leader or lieutenant) had those people walked in
  the moment the car set off, so the group arrived on foot and the car, if it came, came
  separately. If the car never delivered the Rival, the walk-in that followed brought a second
  set of them. Their people now ride in the car with them, the Rival in the first seat; whoever
  the car cannot seat walks in, and a walk-in after a failed car only brings whoever of theirs is
  not already here.

- **People you got away from came back.** When everybody hunting you had streamed out of the
  world - you drove off, or went far enough - the hunt ended as "threat ended", but they stayed
  registered. Whenever you next passed that way they came back into the world as hostile
  hunters, starting a hunt out of nowhere, and a Rival among them stayed "hunting" with a body
  nobody could reach. Getting that far away now ends it the way losing them does: "lost them",
  the Rival counts it as an escape, and the people left behind are cleared. A crew still driving
  in from a long way off is not counted as left behind.
- **Somebody from an earlier car could be pulled into a later one.** Seats were handed to anybody
  carrying the car-crew tag, which they keep for good, and the hand-out runs again whenever one
  of them streams back into the world. So a crew member who had got out of one car and streamed
  back in while another was boarding was mounted into it instantly, from wherever they stood:
  another way for somebody to blink out of sight, and the new car left with a seat its own crew
  needed. Only the people created for the car now boarding are seated in it.
- **A Rival who runs people could arrive with twice as many.** The count of how many of their
  people were already here only saw the ones standing, not the ones the game was still building.
  So escorts asked for a moment earlier read as absent and a second set was sent for them: the
  group turned up over strength and ate room that other arrivals needed. It now counts anybody
  already on the way in as present, the same way everything else that asks "how many of ours are
  out" does. The head count that only sees people standing has been removed so nothing can reach
  for it again.
- **Two places that could read past the end of a list.** The queue of cars still to send for a
  convoy, and the day's timetable read from your save, were each read by position, trusting
  every caller to have checked the length first. Reading past the end is a crash, not an error.
  Both now check for themselves, and the timetable is counted by its shortest part, so a save in
  which one part came back short is read as a shorter day rather than taking the game down.

### Known
- **"1.6.7 would not launch on Steam Deck; 1.6.6 did."** Not reproduced. 1.6.7 changed only the
  Hub page in the pause menu, and none of that runs until you open it, so if the game stops
  before the main menu, the likeliest cause is the script compile at startup. On Steam Deck in
  Game Mode, the error box the script compiler shows can sit hidden behind the game window, and
  that looks exactly like a game that will not start. If it happens with 1.6.8, start once from
  Desktop Mode and send the text of that box, or `r6/logs/redscript_rCURRENT.log`, along with
  your report.

## [1.6.7] - 2026-11-06

The Cyberbane page in the pause menu answers the mouse where it is drawn, and nothing on it runs
off the page or into anything else.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **"I can't click the rows, and Q and E don't line up with anything."** The page was laid out at
  1920x1080 and then enlarged, usually to about twice that, by scaling the whole panel at draw
  time. That kind of scaling only changes how the panel is painted; the game still works out what
  is under the mouse from where everything was laid out, at the small size. So every row, tab and
  button answered clicks and hover from a spot that was not where it was drawn - rows could not be
  clicked, the highlight under the cursor lit the wrong thing, and nothing on the page lined up
  with what it responded to. The page is now laid out at its real size, so what you see is exactly
  where you click. It looks the same as before.
- **Text no longer sits between the mouse and the rows.** The paragraph under a list is as wide as
  the list and laid over it. Every piece of text and every coloured band on the page is now set to
  ignore the mouse, so only the rows, tabs and buttons can be clicked.
- **Q and E are on the tab bar.** The keys that change screen were only named in the footer, at
  the other end of the page from the tabs they move between. They are now drawn at the two ends of
  the tab bar, level with it, the way the game's own menus show them, and clicking them changes
  screen too.
- **Text ran into the footer.** The prose under each list was held to a number of lines by
  counting the line breaks in it, but a sentence with no break wraps onto two or three lines on
  screen and still counted as one, so a long Rival file or gang note ran down into the footer.
  Every piece of text on the page is now fitted to its own box, wrapped word by word against the
  box's real width and the room left above whatever is under it, and cut short at a word with
  "..." rather than ever drawn over something else.
- **The History ledger ran underneath the Start over button.** It now stops above it.
- **The footer ran underneath the Mod Settings button.** It is shorter now that Q and E are on
  the tab bar, and held to the space left of the button.
- **The button under a list could be too narrow for its own label.** "Click again: erase
  everything", in capitals, was wider than the button. Button labels are a size smaller and fitted
  to the button, and that one now reads "Click again: erase it all".
- **The captions under the meters stay on one line**, so a long one can no longer wrap onto the
  next meter's name. The two longest were reworded to read whole.
- **The line under the tabs stays inside the page.** The title and tier line and the screen's
  one-line description are held to the content column instead of the full width of the panel.
- **Interface size above 100% pushed the page off the screen.** It enlarged the page past the
  edges, footer and tabs included. It can now enlarge the page only until it fills the screen;
  below 100% it still shrinks it as before.

## [1.6.6] - 2026-11-05

Finishing somebody you knocked out is a kill, Rivals stand on the ground, news of what you did
takes time to reach your phone, and gangs drive to you.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **"I put them down with Pax, then headshot them, and it still counted as non-lethal."** A
  knockout was scored as mercy the moment they dropped - Conduct, the non-lethal tally, the
  gang's "spared" count, goodwill with their rivals, the quiet-takedown count - and killing them
  afterwards only took back three of those. Worse, the mercy was settled for good once you had
  been out of combat for twenty-five seconds, which after a stealth takedown is right away, so
  walking round scanning a sleeping room locked every one of them in as spared (and could make
  a Spared Rival of them) before the shots. A takedown is now recorded when it happens and only
  scored as mercy once you have actually left them breathing: walked away (45 m), or they
  streamed out of the world. Finish them first and it is an ordinary kill, counted once. Mercy
  also no longer depends on the Rivals setting.
- **Rivals spawning near you floated until enough damage knocked them over.** Every spawn was
  placed 0.35 m above the floor found by a ray cast from three metres up, which could also land
  on an awning or ledge above the real spot. An NPC is not dropped by physics when it is
  created, so one that opened fire without moving hung there. Spawns now stand on the navmesh
  point itself, the way the game places its own pursuers, and spots found by raycast alone are
  moved onto the navmesh under them or skipped.
- **The phone knew everything the instant it happened, and filled up with repeats.** News of
  what you did - a body, a dead Rival, a crew taking over, a gang finding its crew gone, your
  name going up - now takes in-game time to reach you, arrives no closer together than a set
  gap, and the same story is told once while it gets around: a cyberpsycho episode is one "you
  left a mess" message, not one per lull in the fight. A contact sending the same words twice
  within the hour files them once. Gangs and Rivals talking to you in the moment are unchanged.
- **Cars arrived empty, or with the crew standing in a heap beside them.** The car was picked
  by the length of the gang's name, blind to how many it had to carry, and its seats were read
  from a passenger count that the traffic cars Cyberbane uses leave blank - so it read zero, the
  car seated nobody, and the whole crew was walked in afterwards. When a count did come back,
  the crew were mounted by a fixed list of four seat names, so a two-seater was handed people
  for back seats it does not have. The car is now chosen by the seats it really has (from its
  own seat set), the gang's own kind of car first, and the crew is seated by that car's own
  seat names, driver first.
- **A crew too big for one car walked in.** One car came, seating four at most, and everybody
  else - and the whole crew, whenever their apex squad was in that car - walked up behind it. A
  group now comes in as many cars as it needs, one after another, each picked to seat as many as
  it can: an apex squad in one or two, the crew in the cars behind theirs. Only those past the
  new **Cars per arrival** limit, or anybody a car cannot be sent for, come on foot. Each car's
  crew gets out of their own car only, so nobody is ever ordered out of a car still driving.
- **A car that could not finish boarding never left.** If one seat never filled, the car was
  never given its orders, and whoever was already in it sat parked out of sight for good. It now
  sets off with whoever got in, and the rest come on foot.
- **A crowded spot behind you sent the whole crew in on foot.** Finding room for a car made one
  real attempt. It now also tries the places the game itself would put a pursuer, with the same
  out-of-sight, same-level and room-for-a-car tests.
- **A car drove to where you were, not where you are.** On foot, it was sent to the spot you
  stood on when it set off, and sat there until it gave up waiting. It is now sent on to you if
  you have moved well away, a few times at most.

### Changed
- **Cars arrive on foot too is on by default.** Gangs, Rivals and apex squads now drive up and
  get out while you are walking, not only while you are driving. Indoors, or with no road near,
  they still come on foot. It was turned off in 1.5.2 after a crash that was never traced; the
  seat faults above are fixed at the source and are the likeliest candidates, but if you see
  instability around cars arriving, turn it off under Gangs and it stops at once. The switch was
  renamed so the new default reaches installs that never changed it.

### Added
- **Cars per arrival** (Gangs): how many cars one crew or apex squad can arrive in, 1 to 5. 4 by
  default.
- **Word travels** (Interface): how many in-game minutes news takes to reach your phone. 30 by
  default; 0 is the old behaviour.
- **Gap between messages** (Interface): the least time, in real seconds, between two pieces of
  news. 45 by default.

Bounty payouts are still paid, and announced, the moment you earn them, so a reload can never
lose one.

## [1.6.5] - 2026-11-05

The pin a tip puts on your map is one you can actually find.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **"They said they'd put it on my map, but I can't find it."** The pin for where a Rival was
  seen used the game's gang-activity marker, and the game's own map code treats that marker as
  an NCPD scanner hustle. So the minimap never drew it at all, and the world map drew it with the
  same icon as every NCPD hustle around it, folded it into their clusters when zoomed out, hid it
  whenever the NCPD filter was off, and described it as a police activity when you hovered it. In
  Watson, which is full of hustles, it was as good as invisible. It now uses the marker the game
  uses for a waypoint dropped on your map: always on the minimap, its own icon on the world map,
  and labelled as a custom location. Select it on the map and track it for a route. A pin already
  on your map changes the next time you load.
- **The readme promised markers on people on the minimap.** Rivals, apex squads and crews carry
  their marker over their heads and on the world map; the game's minimap has no way to draw that
  marker on a person, so they appear there only as enemies once the fight starts. The readme says
  so now.

## [1.6.4] - 2026-11-04

Your phone works while people are still looking for you, and Dread comes down when you stop
earning it.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **The phone said "you can't do that right now" while you were being hunted.** The game blocks
  the phone, saving and fast travel while you are in combat, and it counts you as in combat
  whenever any hostile is tracking you, wherever they are. Everybody Cyberbane sent was handed
  your position the moment they were placed, ninety metres off and out of sight, so you were in
  combat from then until the hunt ended, with nobody in view and the HUD saying they were still
  searching. Now they are only told where you are once one of them has actually found you: has
  eyes on you, or hears you fighting. Until then they search, the phone opens, and you can save.
  If one of them walks into your line of sight, the fight starts the way any fight does.
- **The hunt searches for real.** Because everybody already knew where you were, "searching" was
  a fight in all but name, a scout's call-in was over before it began, and the Rival who texts
  "found you" texted it almost as soon as they arrived. They now arrive, search, and say so when
  they find you.
- **A Rival you were tipped off about knew you were coming.** The one waiting at their place was
  handed your position when they were placed, so they were in the fight before you got near.
  They now stand there minding their own business until they see you, or you hurt them.
- **Putting people down alive made you as frightening as killing them.** A knockout added the
  same Dread as a body. It adds a quarter now, the same share it already cost a gang's opinion
  of you.
- **A room of people knocked out counted as a massacre.** Massacres, and the title that counts
  them, count bodies only.
- **Dread only went up.** More than half of it - your body count and the jobs you have pulled -
  never came down: the body count lost half a percent a day of a number that had long since
  stopped moving, and the jobs lost nothing at all. While you lie low they now fade a few points
  a day each, down to what your whole record still earns, so a few dozen bodies fade to almost
  nothing and a few hundred never quite do. Decay rate, under Reputation, sets the pace, and at
  zero nothing fades, as before. Titles you have earned are never taken away.
- **Laying low did nothing.** It was always meant to: three in-game days without putting anybody
  down, lethally or otherwise, and the city was supposed to forget twice as fast. Nothing ever
  implemented it, so a quiet spell faded your reputation at exactly the same rate as a killing
  spree. It works now, and it covers your body count, the jobs you have pulled, your heat with
  the law and each gang's renown. Put anybody down and the clock starts again. Your own build and
  a gang's settled opinion of you are not affected, and neither is your reputation in a
  particular district, so lying low does not quietly erase where you are known.
- **The Hub blamed chrome you had covered up.** "People fear you mostly for all that chrome"
  counted the chrome you have installed, while Dread counts the chrome people can see. It counts
  what they can see now, and says what brings the biggest part down.

### How to bring Dread down
- **At once:** cover your chrome (a coat, trousers, something across your face) and dress down.
  Those two are a third of Dread and follow what you are wearing.
- **What the street reacts to** is lower still with a mask on, the more people you leave
  breathing, and the quieter your style.
- **Over time:** lie low. Your body count, your jobs and your heat with the law all fade. Go three
  in-game days without putting anybody down and they fade twice as fast, until the next one.
- **To stop it climbing:** leave people alive, avoid finishers, blades, explosives and
  bystanders, and lower Dread gain under Reputation.

### How it stays out of trouble
- No new calls into the game: the call that hands a hunter your position is the same one, moved
  to the moment you are found. The fade uses the game's own logarithm, next to the exponential
  Dread has always used.
- Nothing in your save changed shape.

## [1.6.3] - 2026-11-04

Three reports fixed at the root, and gangs now fight over the city's streets. Crews no longer
vanish in the middle of a fight, tips on where your Rivals are actually arrive, and every crew a
gang sends is led by its apex squad. Turf wars are new: hurting a gang weakens it, and a broken
gang loses its districts to the gang at war with it next door.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **Crews vanished in the middle of fights.** Reported as "enemies spawned by Cyberbane despawn
  mid fight, with hit squads, not Rivals". A timer left over from before crews hunted you deleted
  every living crew member you could not see "five minutes" after the crew was sent. Those were
  five minutes of the in-game clock, which is under forty real seconds, checked once an in-game
  hour: so whenever that hourly check fell during a fight, anybody flanking behind you or ducked
  behind cover disappeared, and anybody you could see disappeared the moment you could not. It
  only ever looked at crews, which is why Rivals never did it. The timer is gone. How long a crew
  stays is decided by the hunt alone: they search, find you, fight, and leave only when you have
  got away from them or the story takes the stage.
- **The fight-release could take a flanker.** Somebody of Cyberbane's keeping you in combat from
  far off is still let go so a finished fight can end, but only once nobody of theirs is close to
  you or can see you. While the fight is on, the ones working round behind a wall stay in it.
- **A Rival could be retired while still on you.** The backstop that takes away a Rival nobody is
  engaging no longer fires while the hunt has eyes on you.
- **Tips on where your Rivals are never came.** Two causes. A sighting was only written down if
  the Rival's body was still in the world when the encounter ended, and the usual way a Rival
  walks away - you outrunning them - ends with them over a hundred metres off and usually already
  streamed out, so nothing was written down and there was nothing to tip you off about. Where a
  Rival was last seen standing is now kept as they move, and used when their body cannot answer.
  The same goes for anybody who escaped you and came back as a Rival. And the Rival you had just
  lost was nearly always the next one queued to come after you, which made them the one Rival
  nobody would tip you about; being next in the queue no longer counts as being on their way, and
  if you find them first they are taken off the queue. A sighting nobody has passed on also gets
  likelier to be passed on the longer it waits.
- **Hit squads never had apex members.** Only a gang at vendetta brought its apex squad, and only
  when all four could come by car, which never happens while you are on foot - so in practice no
  crew ever had one. See below.
- **Somebody you knocked out was "spared" three seconds later.** The wait before a knockout counts
  as mercy, and the time a wounded enemy has to get away, were measured on the in-game clock and
  meant real seconds, so they ran eight times fast. A knockout became a Spared Rival, with a text
  saying they walked away breathing, while you were still fighting over them, and finishing them
  a moment later no longer counted. Mercy now needs you to have walked off or the fight to be over.
- **A crew or apex squad that could not be placed on its first try was dropped.** Both were meant
  to hold and try again for a while; both cleared their appointment before the retry could
  happen. They now keep it until somebody arrives or the wait runs out.
- **Paying a gang off did not cancel what was queued.** A crew or apex squad already picked from
  that gang and not yet on its way still came, and an apex squad never checked whether its gang
  still wanted you dead before setting off. Both are called off now.
- **An apex car could seat the wrong kit.** Seats in a car took their role in the order they
  finished loading, so the heavy's body could be given the netrunner's kit and bar. Each seat now
  carries its role from the moment it is created.
- **The cap on how many of Cyberbane's people can be out at once leaked.** It only counted people
  who had finished arriving, so several groups sent in the same moment each saw it empty. It
  counts everybody on their way into the world now. A crew is also never promised as bigger than
  can actually turn up, so the number in the text is the number that arrives.
- **Knocked-out crew were never cleared up** except by the timer above. They are now cleared like
  bodies, once you are well away and cannot see them.

### Every crew is led by its apex squad
- **A hit squad is the gang's apex squad and the rest of its crew.** Four of their best - a heavy,
  a shooter, a blade and a netrunner, each fighting the way their kind fights, the way a MaxTac
  drop reads - with the crew behind them. The text names who is leading them and how many follow,
  and the line on the HUD reads APEX CREW.
- **Always four.** Whoever a car has no seat for, or the street will not take on the first try,
  walks in shortly after, chair by chair, so the right person fills the right role. Nobody you
  have already put down is replaced, and nobody walks into a fight that is already over.
- **One squad.** The crew counts as beaten only when its apex squad is down too, and only then
  does the gang pay the bounty and text you about it. No second apex squad is sent into a fight
  that already has one, and you get the apex squad's own bounty when the last of the four falls.
- **Give a crew the slip** and one of the people you actually lost can come back as a Rival, seen
  where they were standing. This used to happen on the timer above, mid-fight, out of a generic
  member of the gang.
- **Crews bring the apex squad**, under Gangs (it was Vendetta brings the apex squad, and keeps
  your setting), sends crews alone.

### Turf wars
- **Gangs have strength.** Each of their people you put down weakens a gang a little; an officer,
  a boss, one of their Rivals, a whole crew or their apex squad, a lot. They rebuild while you
  leave them alone, and are never wiped out.
- **Districts are split between the gangs that work them,** and the stronger holds more. The
  front line drifts a little from day to day on its own, because gangs fight each other too.
- **Break a gang and its enemies move in.** A gang at war with them whose streets are next door
  pushes into their district, harder the more broken they are. Let them rebuild and they take it
  back. The street texts you when a district changes hands, and the History screen keeps it.
- **The holder is who counts there.** Whoever holds a real share of a district is on their own
  streets: their lookouts watch you, their crews know where you are, their vendors price you by
  what they think of you. A gang pushed out of a district is none of those there any more.
- **The Turf screen on the Hub,** next to Gangs: one line a district, with who holds it, how
  firmly, and who is fighting them for it, and underneath, only the gangs you have actually hurt
  and how badly.
- **Turf wars**, under Gangs, turns it off: every gang keeps its own streets, as before.
- The idea comes from Gang Retaliation by NovaAntonsito. No code from it is used.

### How it stays out of trouble
- **No new calls into the game.** Everything above is Cyberbane's own arithmetic over numbers it
  already keeps, and every arrival still goes through the one placement path with all of its
  checks. Checked against the engine surface of 1.6.2: the list of engine calls is unchanged.
- **Nothing in your save changed shape.** Gang strength is kept where 1.6.2 keeps where Rivals
  were seen, outside the save and tied to the playthrough. Loading an older save ignores what was
  written later, and Start over clears it.
- **The Hub stays data, not new widgets.** The Turf screen is drawn with the same rows and bars as
  the other screens.

## [1.6.2] - 2026-11-03

You can go after your Rivals now, the way they come after you. Somebody who walked away from you
alive gets seen somewhere afterwards, and sooner or later a gang that hates theirs, or somebody on
the street, texts you where. Go there on foot and they are there, not expecting anybody. And a
Rival scans under their own name.

This release also fixes "I cleared my rivals on the Hub, closed the game, loaded my save and they
were all back", at the root, along with a worse problem that came from the same place: Start over
could wipe the wrong save. And gangs that already want you dead will now name their price, so the
offer to pay a vendetta off is reachable again instead of only arriving the moment they turn.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Hunting a Rival down
- **Where they were last seen.** When a Rival walks away from an encounter alive (you lost them,
  they ran, or you let them go), the street notes where they were standing.
- **Somebody tells you.** Now and then a gang at war with the Rival's gang texts you where they
  were seen: "Heard you got beef with Kenji. Our people saw them in Heywood not long ago." If no
  gang that tolerates you hates theirs, it comes from somebody on the street instead. A pin goes
  on your map, with the same icon as a Rival's marker. One lead at a time, and at most one tip
  every few hours.
- **Go there.** Get within about 80 metres on foot and they are there: idle, minding their own
  business, given no orders at all. Sneak up, take a shot, or knock them out. Once they see you
  or you hurt them, it is an ordinary Rival fight, and everything that applies to one applies
  here: they can run, they can be spared, and they can be killed for good.
- **Catch them before they react** and it counts as an ambush: extra renown on top of the kill,
  a line in the street's file on the History screen, and word back from whoever tipped you off.
- **Leads go stale.** Leave it a day and they move on; whoever told you says so. Every encounter
  they survive gets them seen somewhere new.
- **They still come for you** on their own schedule, exactly as before. Somebody waiting at their
  place counts as the one Rival in the world, so no other Rival is sent while they wait.
- **On the Hub,** a Rival you have a lead on reads "you know where", and their file says who told
  you and where. One waiting at their place reads "at their place".
- **Tips on where Rivals are,** under Rivals in Mod Settings, turns all of this off. With messages
  off you are not texted, but the lead, the pin and the Hub's file still work. The pin follows the
  Map markers setting.

### How it stays out of trouble
- **Nobody is placed at a bad moment.** A waiting Rival is put there only when you are on foot,
  out of combat, the world is settled and has been for several seconds, the story and your job
  both leave the stage to Cyberbane, and nothing else of Cyberbane's is out or on its way.
  Arriving by car or by fast travel is exactly when the game is busiest loading, which is where
  this mod's crashes have always come from, so those are the moments it waits out.
- **Only the checks every arrival already passes:** a floor under them, on the walkable map, not
  in a safe area or at a job, a path to you, and not in front of your eyes. Placing them uses the
  same call as every other arrival, and they are taken out the same way, out of your sight. One
  at a time, and never past the cap on how many of Cyberbane's people can be in the world at
  once.
- **The hunt cannot see them while they wait.** They wear their own tag until the fight starts,
  so nothing sends them off after you or decides you have "lost" them while you are still sneaking
  up. The moment the fight starts they become an ordinary Rival encounter, handled entirely by
  the code that already runs every other one.
- **Walk away and they go quietly.** Get far enough away, or let the story take over, and they
  are taken back out of sight, with no promotion and no text. The pin comes back.
- **The pin does not outlive the session.** It uses the game's own map pins, and the game does
  not keep those in the save; its own systems put theirs back on every load. Cyberbane puts its
  pin back the same way, from what the street saw.
- **Checked against both patches.** The only engine call Cyberbane had not made before is placing
  a map pin at a position. Both 2.31 and 2.5 have it, and the game's own drop points use it.

### Rivals in the scanner
- **The scanner gives a Rival's name.** A player pointed out that Rivals scanned as Racketeer,
  Thug or Tyger, or sometimes under a generated name that was never the one they used anywhere
  else. The scanner now shows the name Cyberbane gives them everywhere, such as Kenji "Who Ran"
  Morita, with their class (Netrunner, Sniper and so on) underneath. These are the same two lines
  the game uses for named targets.
- **It stays with the body.** Somebody you put down, or knocked out, still scans as themselves.
- **The rest of the scan is the game's own.** Level, health, faction, weaknesses and bounty are
  untouched, and nobody but a Rival is affected. Where the game would not show a name at all,
  this does not show one either.
- It runs on both 2.31 and 2.5. The game builds the scanner's name the same way on both patches,
  and that was checked against each patch's script source.

### Forgetting your Rivals sticks now
- **What was happening.** "Forget every rival" changed only the save's own copy of your Rivals,
  and only once you went back to the game. So quitting from the pause menu straight after
  choosing it threw it away, and loading any save written before it brought every Rival back.
- **What it does now.** It is recorded the moment you confirm it, against the playthrough rather
  than the save, in the same place Cyberbane already keeps the deaths it remembers across saves.
  Every save of that playthrough forgets those Rivals when it loads, including saves older than
  the one you chose it on.
- **Deaths from before the forget no longer bring anybody back** as a Rival either, so loading an
  older save cannot raise one through that door.
- **"Keep them" still takes it back,** exactly as it was, until you go back to the game.
- New Rivals after a forget are numbered past the forgotten ones, so a Rival made later is never
  mistaken for one of them.

### Start over could wipe the wrong save
- **What was happening.** Start over was parked in a place that outlives every save, and nothing
  tied it to the playthrough it was chosen in. Choose Start over, then Load Game from the pause
  menu, and the reset ran on whatever loaded, even a save from a completely different
  playthrough. The Reset all Cyberbane data switch in Mod Settings went the same way.
- **What it does now.** A reset belongs to the playthrough it was chosen in. A save from any other
  playthrough is never touched by it. From the main menu, with nothing loaded, the switch still
  applies to the next save you load, as it always did.
- **And it sticks, like forgetting your Rivals.** Start over on the Hub is recorded against the
  playthrough when you confirm it, and older saves of that playthrough are started over too when
  they next load, instead of bringing back what you wiped.

### Fixed
- **You could not buy off a gang you had already angered.** Reported as "I don't get the messages
  where you can either pay for the vendetta to be over or not". The message that carries the
  pay-or-refuse answer was only ever the one a gang sends at the moment it turns on you, and your
  phone's Cyberbane threads start empty every time you load. So if a gang swore a vendetta in an
  earlier session, there was nothing left in the phone to answer and no way to pay them off from
  it at all — only the Hub's shortcut still worked. Now every gang that is hostile to you and can
  be bought puts its price to you once a session, unprompted, which re-opens the answer in their
  thread: pay what they want, or tell them no. One gang at a time, so a save with several enemies
  does not light up your phone at once, and a gang you have already turned down stays turned down
  for that session.
- **Sparing a Rival could make a second Rival of them.** When a Rival you put down without killing
  was settled after their body had already streamed out or been cleared, Cyberbane looked for the
  body to work out who they were, found nothing, and took them for a stranger. It made a brand new
  Rival of the same person. It now goes by the id it noted when they went down, which outlives the
  body.
- **The first Rival on a save was missing part of their behaviour.** Rivals are numbered, the
  numbering started at 0, and Cyberbane also uses 0 to mean "nobody". So the first Rival on every
  save, and the first after Start over, had three faults:
  - they arrived without texting first;
  - they never came by car;
  - when they fled at low health they were taken for an ordinary ganger, which made a second
    Rival out of them instead of promoting them.

  New Rivals are numbered from 1. A Rival your save already numbers 0 stays as they are.


## [1.6.1] - 2026-11-03

Cyberbane runs on Cyberpunk 2077 2.31 as well as 2.5. Players who have not moved to 2.5 asked to
try it, and it is one download for both: install the versions of the required frameworks that
match your game (the table is in the readme). Nothing changes for anyone already on 2.5.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### What stood in the way on 2.31
- **One call to the game did not exist in the same shape.** The function the game uses to hand an
  NPC an ability takes two arguments on 2.31 and three on 2.5, and Cyberbane called the 2.5 form
  when kitting Rivals and apex squads. On 2.31 that is a script compile error, and a compile error
  stops every script mod from loading, not only this one. Cyberbane now does what that function
  does itself, through the two calls underneath it, which are the same on both patches. On 2.5 an
  NPC gets exactly the same abilities, applied exactly the same way.
- **The Cyberbane entry in the pause menu has a sensible place on 2.31.** It goes right after the
  game's Mods entry, and 2.31 has no Mods entry, so it was being added below Exit to Main Menu. On
  2.31 it now goes right after Settings, which is the game's own entry and does not depend on any
  other mod. On 2.5 it stays where it was.

### How it was checked
Without a 2.31 install to compile against, everything Cyberbane uses from outside itself was
checked against the game's own script source for both patches, and against the 2.31 builds of
Codeware (1.20.6) and Mod Settings (0.2.21):
- Every one of the 30 game functions Cyberbane hooks has exactly the same signature on 2.31.
- Every game field those hooks read, every enum value Cyberbane names, and every function it calls
  exists on 2.31 with the same shape, or comes from Codeware 1.20.6 with the same shape (the text
  wrapping, service and callback functions that 2.5 took into the game itself).
- Every vehicle, weapon, crafting material, ability and map marker record Cyberbane names exists in
  2.31's game data.
- The phone and pause menu code Cyberbane hooks into differs between the patches only in touch,
  gyro and Mac input, none of which Cyberbane touches.

### The line at the top of the screen goes away on its own
- **Where you stand in the district you are in no longer sits there.** DOGTOWN - TALKED ABOUT
  HERE stayed up for as long as nobody was hunting you, which is most of a session. It now shows
  when you arrive somewhere and again when your standing there crosses into the next word, then
  clears itself after ten seconds.
- **District line**, under Interface, sets that: Briefly is the new default, Always is what it did
  before, Off never shows it. **District line, seconds** sets how long Briefly lasts, from 3 to
  60.
- The hunt warnings are untouched, and **Hunt line on the HUD** still governs the whole line, so
  HuntsOnly and Off hide the district half as they always did.

### Shorter descriptions in Mod Settings
- **Every setting description has been cut**, from 194 characters on average to 97. They used to
  say why a setting exists and what it was written for. They now say what it does, what each
  choice means, and what zero means where that matters. The reasoning is in the readme and in the
  source, where there is room for it.


## [1.6.0] - 2026-11-03

Cyberbane stays out of the story. A Rival walked into a VR fight where the only thing you could do
was pistol-whip, and a crew attacked on the way to the water tower with River. Both came from the
same blind spot, and it is closed at the root rather than for those two quests. And the Hub moves
into the pause menu: press Escape and it is there, next to Mods and Mod Settings, with the game
paused underneath it and everything on it clickable.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Nobody walks in on the story
- **Why it happened.** Cyberbane decided whether somebody could arrive by asking about places: a
  safe area, somebody else's turf, the map pins of the objective you were tracking, a cutscene. A VR
  fight is ordinary gameplay with no map pins and no turf, and a walk with River is an open field
  with the pin somewhere else, or nothing tracked at all. Every check passed.
- **What it asks now is what the game itself says about you**, which is far harder to miss:
  - **Are you V?** In the VR fight you are not: you are a VR avatar, the same way you are Johnny in
    his flashbacks. While you are somebody else, or in cyberspace or a braindance, Cyberbane does
    nothing at all. Nobody is sent, nothing counts, nobody reacts, and nothing is paid out of the
    wrong pocket.
  - **Has the story taken over what you can do?** Quests limit V for their set pieces: fists only,
    one weapon you cannot put away, no weapons, a seat in somebody's car, a metro ride, a scene you
    cannot walk out of. The game marks each of these on V, and Cyberbane now reads them.
  - **Is somebody from the story walking with you?** When River, Panam or anyone the story placed
    is following you, you are in the middle of their quest, wherever the objective's pin is. A
    companion you spawned yourself with a mod is not counted when it can be told apart from the
    story's: one the quest system has not flagged and that the mod created through Codeware, or
    one who is not a story character at all. That keeps Cyberbane from going quiet for the people
    who walk around with one.
- **While any of those is true**, nobody is sent, every countdown waits where it is, and the street
  does not turn on you: anybody Cyberbane had turned hostile who is not already fighting you goes
  back to how the game had them.
- **Anybody already on their way is called back** quietly, out of your sight. A Rival goes back to
  waiting their turn without being promoted, nobody texts you, and no gang thinks less of you for
  it. Anybody you can already see is left exactly as they are, so a fight that has started still
  counts. A crew in a car stays in it.
- **Kills that are not V's no longer count as V's.** Fighting as the VR avatar or as Johnny used to
  raise V's Dread, cost real gangs' standing and could even send a VR enemy back as a Rival. Their
  loot and V's deaths are not recorded for somebody else either.
- **"Allow spawns in safe areas" only opens safe areas.** Turning it on used to switch off the
  scene, job and no-combat checks along with them, so asking to be found in your apartment also
  asked to be found in the middle of every quest.
- None of this can be switched off, because none of it is a preference: it is the game saying the
  stage is taken. **Stay out of quest areas** still covers everything else, as before.

### The Hub is a page of the pause menu
- **Escape, then Cyberbane.** It opens over the pause menu's own list, and Escape takes you back to
  that list, the way it does from Settings or Load Game. Escape again closes the pause menu as
  usual. Nothing about Escape or the pause menu changes when the Hub is not open.
- **Click everything.** Click a screen name to switch screens, or use Q and E (LB and RB on a
  controller), the same keys the game's settings menu uses.
- **The game is paused while you read it**, because it is the pause menu. The countdowns show the
  time as it stood when you paused, and start moving again when you go back to the game.
- **The Hub key is now a shortcut** to the same page: press it in the game and the pause menu opens
  straight on Cyberbane, press it again to close it. It only works where the game would let you
  pause anyway.
- **Gangs: click a gang** to see who they are at war with, how many of theirs are down, what they
  are about to do, and what it would cost to buy them off, with a button to do it. You choose which
  gang now; before, the shortcut always picked the worst one you could afford. The payment goes
  through a few seconds after you are back in the game, and clicking again before then cancels it.
- **Hostile gangs are listed first**, so a gang that wants you dead is never pushed off the bottom
  of the list by gangs that do not.
- **Rivals: click a Rival** for their file: why they have it in for you, their strengths and weak
  spots, and the mark you left on them. It opens on whoever is coming next.
- **Forgetting every Rival asks twice** now that it is a button, and like a payment it happens when
  you are back in the game, and can be taken back until then.
- **A Mod Settings button** at the bottom of the page goes straight to Cyberbane's settings.
- The page is built from the game's own menu: it lives inside the pause menu and is taken down with
  it, so it can never be left on screen over anything else. The first 1.6 builds drew it on its
  own, where it had no cursor, took no input, stayed on top of whatever opened next, and made
  Escape look like it went to the Hub instead of the pause menu. That is gone.

### Titles
- **"I have five titles and can only switch to the last two."** Fixed. Switching asked the game
  which title was showing, rather than whether you had picked one, and on automatic those are
  different answers: it started from whichever title was best and could only step forward from
  there. With the best one fourth of five, the only choices left were the fifth and automatic.
- **Titles are clicked now.** The Titles screen lists every title you have earned, plus Automatic;
  click the one you want to go by. The ones you have not earned yet are listed beside them with
  what each takes.
- **Every earned title is listed.** The screen used to show the first eight and say nothing about
  the rest.

### The top of the screen
- **"How do I turn off who is tracking me? I turned off show messages and the hunt line and it is
  still there."** Two things, both fixed.
  - The name and health bar at the top of the screen is not the hunt line: it is its own setting,
    and it was filed under Gangs as "Apex squad boss bar", which says nothing about Rivals or about
    the top of the screen. It is now **Rival and apex bars**, under Interface, directly below
    **Hunt line on the HUD**, and each one's description says which of the two it is.
  - Turning either of them off now takes it down at once. The only thing that ever hid them was
    skipped whenever the bars were switched off, so switching the bars off mid-hunt froze both the
    bars and the hunt line exactly where they were, and with the bars off the hunt line setting did
    nothing either. Each switch now controls its own part of the screen, every second.
- Your existing choice for the bars is kept; only its name and place in the list changed.

### The Hub looks like the game
- **It takes its colours from the game.** The page is painted from Cyberpunk's own palette rather
  than from colours written into the mod, so the headings, the descriptions and the footer are the
  same red and grey the rest of the interface uses, and they follow it if it ever changes.
- **It is narrower, and the long lines are gone.** The two full-width rules have been removed and
  the screen names tightened up. The whole interface is drawn with a slight curve, and a
  pixel-thin line a metre wide is the one shape that shows it: no screen in the game draws one,
  which is why theirs look flat and this one did not. It is much less obvious now, and turning off
  the interface distortion in the game's own Accessibility settings removes it everywhere.

### Only what you need to read
- **The Standing screen is shorter.** Your district and street cred are already on screen while you
  play and in the game's own menus, and the lifetime totals belong in a ledger, so they have moved
  to History along with your fighting style. Nothing stopped being counted. What is left is what is
  coming, why people are frightened of you, and what that does right now.
- **Dread reads like the other three meters.** They say a number and then a word; Dread said a
  number and then another number. It now says what the street actually does - "people are uneasy",
  "people are afraid", "people run" - with the figure the street reads explained underneath.
- **Fixed: the Standing screen could disagree with the street.** It worked out how frightening you
  are with a different sum from the one the crowd uses, leaving out what you are doing right now
  and ignoring the civilian intensity setting entirely. So it could say people were uneasy while
  they were running. Both now use the same figure.
- **Fixed: "fighting mostly with Butcher"** read as a gang you were fighting. It was your own
  fighting style. It says "Your style is Butcher" now, on the History screen.

### Starting over, from the Hub
- **A Start over button on the History screen**, which asks twice. It clears everything you earned
  by playing - reputation, gangs, districts, rumours, Rivals, titles, deeds and the log - and
  leaves everything that is read off your build, so your chrome, your look and how dangerous you
  carry yourself stay exactly as they are. Same thing the Reset all Cyberbane data switch in Mod
  Settings does, now where you can see it.
- Forgetting your Rivals, paying a gang off and starting over all happen when you are back in the
  game, and all of them need a save afterwards to stick, the same as everything else in your save.

### Settings
- **The Hub key is gone.** The Hub is a page of the pause menu, so a key that opens the pause menu
  on it was a second way in for no gain. Escape, then Cyberbane.
- **Hub style** is gone. It chose between two ways of drawing the Hub that it is no longer drawn
  either way.
- If the Mods entry is missing from the pause menu because another mod removed it, Cyberbane's
  entry is still added at the end, and now actually appears there.

## [1.5.5] - 2026-11-02

A player asked whether there was any way to turn all the messages off: they liked the mechanics
but did not care that a Rival had climbed a rank or that somebody was tracking them, and would
rather be surprised. There was a way, and it was called Toasts, which is not a word anybody goes
looking for. Now it is where you would expect it.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### New
- **Where messages go: Off.** Silence, in the setting you would actually open to find it. Nothing
  goes in your phone, no cards, no notices, no overheard lines and no message tone. Cyberbane
  stays out of the phone entirely.
- **None of it changes the way the mod plays.** Gangs still send crews, apex squads still come,
  Rivals still hunt you, loot and bounties still arrive with the game's own notices, and the Hub
  still shows where you stand with everyone and still brokers peace. The only thing you give up is
  being told.
- **The HUD line stays its own setting**, so you can keep the one line and lose the texts, or
  turn both off and meet them with no warning at all. Hunt line on the HUD has Everything,
  HuntsOnly and Off.

### The Hub
- **The lists are laid out as lists.** The Gangs screen used to pack a gang's posture, how
  frightened of you they are and how long they had been quiet into a single column joined by
  spaces. The font is proportional, so those joins landed somewhere different on every row and
  the column read as ragged. Each fact now has its own column and lines up down the screen.
- **Nothing is cut off mid-word.** Packing three things into one column meant its width had to
  cover all three, which is why "beat a crew, or 7 more kills" arrived as "beat a crew, or 7
  more ki." at the right edge.
- **The Gangs screen says who each gang is at war with.** Hurting a gang warms the gangs that
  hate it, and until now the only way to know who hated whom was to find out the hard way.
- **The City is a list instead of a paragraph.** Nine districts padded into a block of text,
  with two thirds of the screen empty underneath, is now a row per district with a bar for how
  widely your name carries there and a colour for how well known you are.
- **Conduct reads properly at the bottom of its range.** It runs from -100 to +100 and was drawn
  as a left-to-right fill, so -100 - the worst Conduct there is - showed an empty bar and looked
  broken. It now fills from the middle: left in red towards cyberpsycho, right in green for
  clean.
- **Less text.** The Gangs screen explained each of its own columns in five lines; it now says
  only the part you cannot see, which is how to be thought well of. "CARRYING 11 OF 15" is now a
  sentence.
- The Hub already fits every screen: it is scaled by the smaller of width and height against a
  1920x1080 design and centred, so no aspect ratio crops it, and the scale slider is still there
  on top of that. Verified, not changed.

### More ways to be thought well of by a gang
Standing could only rise by hurting the gang they are at war with, so the only road to Friendly
ran through somebody else's body. It no longer has to.
- **Mercy counts.** Putting one of their people down without killing them costs their opinion of
  you a quarter of what a body costs, instead of exactly the same.
- **And it earns a little.** Every one of theirs you leave breathing is worth something to them.
  On its own this road reaches tolerated and stops well short of allied, because restraint makes
  a gang put up with you - only hurting their enemies makes them like you.
- **Letting a name walk is worth more.** Spare a Rival of theirs and their gang hears that you
  had one of their own cold and let them go.

### New setting
- **Cars arrive on foot too (experimental), off by default.** Gangs normally drive to you only
  when you are driving; on foot they walk in out of sight. Turn this on and they will pull up and
  get out while you are on foot as well. It is off by default because driving a crew in and
  getting them out again is the most demanding thing Cyberbane asks of the game, and it was
  limited to chases in 1.5.2 after a crash nobody could trace. Everything known to cause one has
  been fixed since, so this may be perfectly stable, but it has not been proven. If the game
  becomes unstable with it on, turn it off and it stops at once.

### From player reports
- **Your phone is no longer relentless.** Cyberbane has a sender per gang, a broker per district
  and a few unknown numbers, so a busy few minutes really could ring over and over. Notifications
  are now spaced out, and a message that arrives while the phone is still busy is filed in its
  thread and marks the contact unread without putting anything on screen. Nothing is lost - it is
  waiting on the contact when you next look.
- **One notification per message.** A message identical to the last one from the same contact
  within a few seconds is now announced once.
- **Nobody vanishes in front of you any more.** This is the one that mattered. When somebody
  broke off and ran, or was let go, they were removed the instant the escape resolved - so an
  enemy who really did flee was taken off the screen while you were still watching them go.
  Everyone whose encounter ends while you can see them now stays until you cannot, and leaves
  then. The low-health flee you suggested was already in the mod; this is what was hiding it.
- Anybody held back that way can still be let out of a fight with you, so they cannot keep you
  in combat while they wait to be removed.

### Deeds finally fire
- **Finishing a big job now changes what gangs think of you.** The deeds have had their effects
  written since early development - the Heist costing you Arasaka, Panam's people and the Mox and
  the NCPD thinking better of you - and nothing ever triggered them. The reason recorded for it
  was also wrong: the method the mod was trying to hook is native, and native functions cannot be
  hooked at all, so no amount of work on it would ever have succeeded. The game records what you
  have finished as quest facts and reads them back that way itself, so Cyberbane just asks.
- **The Heist is live**, because its fact name appears in the game's own scripts. The rest are
  left switched off rather than guessed: a wrong name silently never fires, which is
  indistinguishable from the bug being fixed here. With Debug > Log level on Verbose the mod now
  prints the candidate names and their values, so the remaining ones can be confirmed from one
  playthrough and switched on in the next release.

### Fixed
- **Rumours checked end to end.** Word still spreads the way it is meant to: a notable thing
  creates a rumour where it happened, it reaches neighbouring districts every six in-game hours
  at half strength, two hops, and it expires after three days. The City screen reads the same
  district record the engine writes to, so what it shows is what happened.
- A handful of functions and one setting label that no longer did anything were removed,
  including the padding helper that produced the ragged columns above.

### Changed
- The **Toasts** setting is now called **Show messages**, and both it and Where messages go
  explain that they do the same thing and that neither affects how anything plays. It was the
  master switch all along; nobody could find it under that name.

### Fixed
- **A superseded file was still in the source tree and stopped the mod compiling.** An earlier
  draft of the phone screen, replaced in 1.4.7 by the real phone integration, referred to a
  setting and three functions that no longer exist. Because redscript compiles every mod's
  scripts together, this did not just break Cyberbane: on any install where it had shipped it
  would have taken down every other redscript mod with it. It is gone, and the build is
  compile-checked against the game again.

## [1.5.3] - 2026-11-02

Fixes for player reports on 1.5.2, each traced to its cause rather than patched where it showed.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Fixed
- **A drone as a Rival.** Anything that escaped or was spared could become a Rival, drones
  included, and a Rival gets a boss-grade build. A Maelstrom drone came back again and again,
  nearly unkillable and firing missiles. Only people can become Rivals or a gang's spawn template
  now: drones, mechs, spiderbots, androids and turrets are refused, and any already in your save
  are retired when it loads.
- **A gig contact turned hostile mid-conversation** (Alan in Treating Symptoms, with low Voodoo
  Boys standing). The check that keeps Cyberbane away from story characters only knew the ones
  the game flags directly, and most job contacts are not flagged. It now uses the same record
  test that keeps story characters off the Rival roster. Nobody is turned hostile during a
  conversation or a scene, nobody the game has made friendly towards you is turned at all, and
  with Stay out of quest areas on, nothing happens on a job.
- **Stay out of quest areas did almost nothing.** The quest-area test was never called, so the
  switch only kept arrivals out of restricted and dangerous zones. It now covers being on a job,
  worked out the way the game's world map places the job: within 80 metres of the tracked
  objective's map pins (adjustable from 40 to 150 with the new **Quest area size** setting).
  Nobody arrives, nobody is called in by a lookout, and nobody is turned hostile while you are on
  one. Scenes and conversations count too.
- **The job site itself is protected, wherever you stand.** Only your own position was checked,
  so a crew could still be placed at the job while you stood just outside it. Nobody is placed
  within 60 metres of the job's pins, nobody standing there is pushed by crowd fear, morale or
  hostility, searchers are never sent into it, hunters already out stop following you onto it,
  a car crew stays in the car rather than getting out there, and an apex squad's arrival scare
  does not reach it. Anybody Cyberbane had already turned hostile who is standing at the job goes
  back to how the game had them.
- **Nothing vanishes in front of you.** Bodies, spent cars, leftovers and anyone let go to end a
  fight are only removed when you cannot see them.
- **Let me fight in safe areas did not work.** It lifted the game's weapon lock once, at the
  moment you walked in, and the game puts the lock back every time the area updates. It also
  missed loading a save inside a safe area and turning the setting on while already inside. It
  now keeps the lock lifted for as long as you are inside with the setting on, and puts it back if
  you turn the setting off. A few places (the Afterlife, some apartments) also have a story
  restriction on fighting, and Cyberbane leaves that alone.
- **Stuck in combat after the hunters were dead.** The game keeps you in combat while anyone is in
  combat with you. Cyberbane's people who had broken and run, got stuck, or were still sitting in a
  car far away kept it going. Anyone of ours in combat with you but far away and out of sight for
  twenty seconds is now let go, out of sight.
- **TRACKED kept coming back.** The countdowns ran while you were somewhere nobody could reach
  you, such as home, a job or a scene. The arrival was then refused, and the next attempt showed
  TRACKED again. The countdowns now wait while nobody can arrive.

### New setting
- **Hunt line on the HUD:** Everything (default), HuntsOnly (only while somebody is on their way
  or out looking, no TRACKED) or Off.

## [1.5.2] - 2026-11-02

A robustness release. A crash was still reported on 1.5.1 after playing for a while. Every
system that runs on a timer or reacts to NPCs was read again, end to end, for anything that
could touch an NPC or a car after it had left the world, for anything that builds up over a long
session, and for calls into the game that have been part of a crash before.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Stability
- **Nothing builds up over a long session.** The bodies of everyone Cyberbane sent, and the car
  every convoy arrived in, used to stay registered with the game for the rest of the session and
  spawn back in whenever you passed. They are now cleared once you are well away from them.
- **No more than 18 of Cyberbane's people alive at once.** A vendetta crew of twenty on top of an
  apex squad, escorts and a Rival was a lot for the game to stream in at one spot.
- **Cars are for chases.** Cyberbane's people drive in only while you are driving. On foot,
  everybody walks in out of sight and searches for you. Seating a crew in a car, driving it and
  getting them out are the most delicate things Cyberbane asks of the game, and they no longer
  happen around a player standing still.
- **Bodies are never removed in front of you.** A Rival's body and a crew's bodies were cleared
  a moment after death, while they could still be falling. Bodies now go only once you are far
  from them.
- **Nothing touches an NPC that has left the world.** Crowd fear, morale, hostility on sight,
  witness checks, abilities, stat changes, map markers and squad forming all check first that the
  NPC is still fully in the world, including NPCs that streamed out a moment earlier.
- **The phone forgets a controller the moment the HUD tears it down**, along with any open
  thread, so a text can never be delivered into a piece of interface that no longer exists.
  Until the new one is ready, texts show as cards.

### For bug reports
- With **Mod Settings > Cyberbane > Debug > Log level** set to Verbose, Cyberbane writes a short
  line before every call into the game that has ever been part of a crash: spawning, seating a
  crew, giving orders, removing an NPC, showing a text, changing an NPC's stats or attitude. The
  last lines before a crash then say what it was doing.

## [1.5.1] - 2026-11-02

Built from player feedback on being hunted: the timer was easy to read and hard to forget, squads
appeared with no sense of how bad it was going to be, and every encounter ended in a fight. This
release takes the clock away, warns you earlier and more clearly, and gives passive play a real
cat and mouse loop. Everything follows the crash rules 1.5.0 set.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### No clock to keep
- **New setting: When they come.** Timetable is the daily windows from before. Unpredictable
  has no windows: any minute might be the one, more often at night for crews and Rivals and in
  the day for apex squads. Reactive only sends a crew when you give a gang a reason, and an apex
  squad only after you beat one of their crews. The per-day limits apply in every mode.
- **Every countdown varies.** How long a crew or apex squad takes to set off, and how long every
  warning lasts, now changes each time.
- **New setting: Show countdowns.** Turn it off and the Hub and the HUD say "soon", "any
  moment" or "later" in place of exact times.

### Warnings you can prepare for
- **You hear you are being tracked first.** When a gang or a Rival starts coming for you, the
  local broker texts that somebody is asking about you, or you overhear it on the street. In the
  last two minutes before they set off, the HUD line reads TRACKED.
- **How big the threat is.** The HUD line names it (SCOUT, CREW, HEAVY CREW, APEX SQUAD,
  RIVAL), and a crew's warning says how many are coming, from the same number that turns up.
- **Scouts.** A gang that does not know where you are sometimes sends one scout first. If the
  scout keeps eyes on you for a few seconds, they call in the crew. Deal with the scout, or stay
  out of sight, and the crew never comes and that gang backs off for a while. New setting:
  **Scouts before crews**, on by default.
- **How it ended.** For a few seconds after a hunt the HUD line reads LOST THEM or THREAT
  ENDED.

### Cat and mouse
- **A glimpse is not a fix.** A hunter has to keep you in sight for a moment before the hunt
  counts you as found, and the HUD line reads SPOTTED while they do. Break line of sight in that
  moment and they go back to searching.
- **Stealth counts.** Crouching, the dark and wearing the hunting gang's own colours all
  shorten how far hunters see and hear you.
- **They search like guards.** Searchers run to the area, then walk it, and how long they keep
  looking varies.
- **Ways to shake them.** Getting into a safe area, or driving out of the district they are
  searching, makes them lose interest twice as fast.
- **Rivals know their streets.** A Rival is more likely to come for you in the district they
  came from.

### Worth the fight
- **Loot scales with your level**, and crews now carry cash.
- **A bounty for a wiped crew**, paid by a gang at war with theirs that does not want you dead.
- **Running costs something.** Lose a crew or an apex squad by running and that gang thinks a
  little less of you, and lets you know. They also leave you alone for a while, so lying low
  works.

### Fairer fights
- **Difficulty does more.** On Hard and Very Hard, crews are slightly smaller and placed further
  out, warnings last longer, and hunters do not see or hear as far.
- **Combat overhauls.** When Immersive Shooting AI shows up in the Mod Settings list, apex
  squads keep only part of their damage bonus. If it does not appear there on your setup, the
  apex strength slider does the same job.

### HUD
- Still one line, never more. Names on it are cut short and the whole line has a hard length
  limit, so it fits on every screen.
- Fixed in testing: right after a crew's warning ran out, the line could briefly read THREAT
  ENDED before they appeared.

## [1.5.0] - 2026-11-02

A stability release, and it includes everything that was built for 1.4.8. Players reported the
game crashing within minutes of a Rival or a crew being due, sometimes with V just standing
idle, and after reading a gang's texts. Every system that touches the game's engine was gone
through again against the game's own scripts and against the crash causes recorded in earlier
versions. Anything that could take the game down was removed or rebuilt the way the game does
it itself.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Crash fixes
- **Cyberbane no longer touches the police system.** 1.4.7 asked the police chase system to
  check the road network ahead of time and then to spawn gang cars and crews through it. Those
  road checks were refreshed every few seconds for as long as a Rival or crew was queued, even
  while V stood still, replacing requests the game was still working on in the background. This
  is the most likely cause of the idle crashes and of crashes shortly after a gang's warning.
  All of it is gone. Cars now come only from Cyberbane's own convoy: a car placed out of sight
  on a road, its crew seated, driven to you. Rivals use the same convoy.
- **No more risky abilities on spawned enemies.** Rivals with the Quick trait were given
  Kerenzikov, and apex members were given Kerenzikov, Charge Jump, combat stims, quickhacks,
  a cooling system and reinforcement calls. These drive cyberware effects, animations and
  game systems on characters the game never made for them, the same kind of thing behind an
  earlier recorded crash. Every kit is now behaviour only: cover, pace, firing on the move,
  resisting stuns, seeing through smoke and camo, grenades.
- **Orders to enemies are sent once.** Every move order was sent twice and the old one was never
  cancelled, while the hunt re-sent orders every few seconds. Each enemy now has at most one
  order from Cyberbane at a time.
- **Nothing is removed from the world mid-action.** Clearing out a crew or a Rival removed
  whoever carried the tag, including people sitting in a car seat and people the game was still
  spawning. Those are now left until they are out and fully spawned, and they stop counting
  against anything straight away, so nothing waits on them.
- **Cars are set up after the game has finished building them.** The crew used to be created
  and seated from inside the game's own notification that the car had appeared. Both now happen
  a moment later, after checking the car and the crew still exist. A crew never gets out of a car
  that is still moving, or while you are driving.
- **Opening a gang's text could crash the game.** Cyberbane added its own widgets to the phone's
  message and reply lists and removed them in a way that pulled out widgets the game was still
  using. Messages now go into those lists as data, the way the game adds its own, and replies
  redraw on the next frame.
- **Loot goes straight into your inventory.** Dropping a bag from a body is something the game
  never does, so Cyberbane no longer does it either. Everything still arrives, with the game's
  own notices.
- Anything Cyberbane schedules for later waits until the world has finished loading, and gives
  up cleanly if that takes too long. Spawn setup skips anyone killed before it ran, and squads
  are only formed from people who are still there.
- A crew you wiped out could still produce a Rival "who got away". Only somebody still standing
  can escape now.

### Being hunted
- **They tell you first, and you get time.** A crew, an apex squad or a Rival texts before they
  set off, with roughly where they think you are, and there is a real gap before they arrive.
- **They arrive out of sight and have to find you.** Spawn distances are much longer, and
  nobody is placed where you can see them appear. They head for where you were last seen and
  search the area, narrowing in, the way the police do.
- **A line on the HUD says what is happening**, above the bars: HUNTED, then who, and whether
  they are on their way, searching for you, have you, or are losing your trail.
- **You can break contact.** Get out of sight and far enough away and they lose you, then give
  up. A Rival you lose texts you about it.
- **Rivals say "found you" when they actually find you.** The text used to arrive the moment
  they spawned.

### They come for a reason
- **A crew needs a reason.** A gang that wants you dead sends people when
  you have killed their people where somebody saw it, when you have been hanging around on
  their streets long enough for a lookout to call it in, when you have hurt them in the last
  half a day, or when they have sworn a vendetta. A gang that hates you but has not seen or
  heard of you in a day keeps its people at home. The daily timetable only limits how often the
  city has time for you.
- **On their turf, they notice.** Spend a few minutes out in the open on the streets of a gang
  that wants you dead and a lookout calls it in. Their crew comes off the timetable, and their
  warning says you were seen on their streets. Sneaking, safe areas and being indoors do not
  count.
- **Their apex squad is their answer to you beating their crew.** An apex squad comes from a
  gang that is hostile to you, has lost enough people since its last one, and has had one of
  its crews wiped out by you. Kill twice as many with no crew in between and it comes anyway.
  When you wipe out a crew, the gang texts you who is coming next. A gang you are square with
  never sends its best, and the warning and the Hub use the same test as the scheduler, so
  neither can promise a squad that will not come.
- The Hub's gang line says where each gang stands: kills until their apex squad, "beat a crew,
  or N more kills", or ready.

### Worth the fight
- **Loot.** Anyone Cyberbane sends who you put down leaves you something, straight into your
  inventory. Crew sometimes carry ammo and crafting parts. Rivals carry better parts the higher they ranked, more for a
  crew leader. Apex squad members carry rare and epic parts with a chance of legendary ones.
- **A small chance of an iconic weapon** from apex squad members, top-ranked Rivals and crew
  leaders. Only weapons you could otherwise find exploring the city: anything the game tags as
  a quest item is refused, and mission, gig, story and companion weapons are not on the list.
  Each one drops at most once per session.
- **Bounties.** Put down a Rival, or wipe out an apex squad, and a gang at war with theirs that
  does not want you dead pays you for it, and texts to say so.
- New settings: **Loot from the people sent after you** and **Bounties**, both on by default.

### Fairer fights
- **Difficulty aware.** On Hard and Very Hard the game already makes every enemy hit harder,
  and the apex build was stacking on top of that. Cyberbane now adds less at those settings.
- **Apex strength defaults to 55** (was 70). If you set it yourself, your value is kept.

### Nemesis
- **Crew leaders do not come alone.** A Rival who leads their gang's crew brings two of their
  people, a lieutenant brings one, and a Pack Leader still brings two.
- **Rivals talk to you themselves** when they get away from you and when you lose them, and
  what they say depends on what you have done to them.

### Other fixes
- Gang texts that are friendly (a gang warming to you, a tip-off, a bounty) are no longer tinted
  as threats and never carry a peace offer.
- A provocation can no longer open the crew lane for a different gang from the one you
  provoked.

## [1.4.7] - 2026-11-01

A major release. Every report this answers came down to the same thing: the mod described what
was happening instead of letting it happen. Enemies could not be killed, they appeared from
nothing, cars were dispatched and never arrived, an apex squad of four turned up as one, and
everything the city had to say about any of it was white text across the middle of the screen.
Going through every system against the game's own scripts turned up a lot more of the same
kind: switches that were on and did nothing, numbers that were recorded and never used, and
features that existed only on paper. This release fixes the lot.

Your saved Cyberbane progress carries over. Nothing stored in your save changed shape.

### Messages now live in your phone
- **Everyone who gets in touch is a contact in V's phone.** The gang coming for you, the broker
  who works the district you are in, a Rival who has found you, an unknown number. A new message
  arrives through the game's own text notification, with the game's own tone, and opening the
  contact shows the whole thread in the phone's messenger, drawn with the game's own message
  bubbles. Press the notification and the phone opens on that thread.
- **You can reply.** When a gang you could buy off sends you something hostile, the thread
  offers you an answer the same way the game's own conversations do: pay what they want to call
  it off, or refuse. Paying is the same deal the Hub brokers, at the same price, and calls off
  anything they already had on its way. If you cannot cover it they say so and the offer stays
  open.
- **The Hub's MESSAGES screen is gone.** Your phone is where you read texts.
- **Brokers talk about the city.** When word about you reaches a district, the broker who works
  it gets in touch, and it is the same person every time. Walk into a district your name reached
  first and they mention it. A new title and a step up in renown arrive the same way now; the
  only things still shown across the middle of the screen are replies to something you just did
  in the Hub or the menus.
- **Overheard lines are a subtitle.** Things people say near you appear as a line of subtitle at
  the bottom of the screen, with who said it. They used to be texts from "Passerby".
- A **Where messages go** setting replaces the on/off switch: Phone (default), Cards (Cyberbane
  draws them on the left of the screen and stays out of the phone entirely, which is the one to
  pick if the phone misbehaves on your setup) or Notices (the old line in the middle).

### Cars that actually arrive
- **Why no car was ever seen.** The city's chase only answers "is there a road to send a car
  down" if somebody asked the road network that question in advance. The police ask it during a
  police chase; outside one, the game clears the question and nothing asks it, so every car
  Cyberbane requested was refused before it was sent. Cyberbane now asks it itself, a little
  before a car could be needed, and lets go when nothing is coming. It never touches the police's
  own set while they are chasing you.
- **The crew gets out.** The police get out of their cars because the police system runs them; a
  gang crew the city carried for Cyberbane had nothing telling it to, so even a car that arrived
  would have sat there. Every one of them is watched now: once the car reaches you and you are on
  foot, they get out and come for you. If you are driving, they stay in and chase.
- **Rivals can drive in too.** More often than not, when there is a road. A Rival whose car never
  delivered them walks in next time.
- **A car that cannot seat everyone no longer leaves the group short.** Whoever does not fit
  walks in straight away, and whoever the car was meant to carry but did not deliver walks in as
  soon as that is clear. This is the apex squad that arrived as one enforcer because the car
  seated one.

### Apex squads and Rivals, like MaxTac
- **Nobody had a boss bar.** Bars were put up a moment after an enemy spawned and erased on the
  very next tick, because a freshly spawned enemy fails the "has it settled" check and the bar
  treated that as "gone". A Rival's bar went up at the instant they appeared and was always
  erased. They stay up now, full until the enemy settles and live after that.
- **Roles that agree.** Each chair of an apex squad (heavy, shooter, blade, netrunner) is carried
  on the body that was spawned for it, so the record it came from, the kit it fights with and the
  role on its bar always match. They were handed out in the order bodies finished loading, which
  is not the order they were sent.
- **They hold their ground.** Apex squad members could panic and run like any ganger. Like
  MaxTac, they no longer break.
- **Enemies nothing could kill.** The stated health range was one of four terms: a random trait
  on the same stat, a power level bonus (which the game uses to derive health, armour and damage,
  so it multiplied everything again) and a crew rank bonus. Everything is now one calculation per
  enemy with a hard ceiling on each stat, and the numbers are down to where an apex enforcer is
  a cyberpsycho you have to take seriously.
- **Rival traits do something.** Tough, Armored, Deadeye, Quick, Chromed-Out, Pack Leader,
  Grudge-Bearer, Hard to Scare, Confident, Scarred and Humiliated were rolled, saved and promoted
  for every Rival and changed nothing about how any of them fought. Each one now does: more
  health or armour, crit, a Kerenzikov dodge, subdermal armour, two of their own walking in with
  them, a place at the front of the queue, never breaking. They stay inside the same ceilings.
- **Weak spots.** Shaken, Old Wound and Reckless were defined and never given to anybody. Sparing
  a Rival leaves them Shaken, escaping you half dead twice leaves an Old Wound, and an avenger
  comes in Reckless, and each takes something off their build. The Rivals screen lists strengths
  and weak spots for whoever is coming next.
- **The wrong Rival got the credit for killing you.** Your killer was matched to a Rival by the
  record they were built from, which dozens of their gang share, so any ganger of the same kind
  who put you down promoted that named Rival. It is matched to the actual body now. A reload also
  promotes that Rival instead of creating a copy of them, and a killer who becomes a Rival keeps
  the face they had.
- **A gang whose survivors were all lieutenants never got a new leader.** The strongest of them
  steps up now, and their chair is filled after.
- **Story characters kept off the roster.** Panam showed up as a Rival with a sniper rifle, and
  unkillable. The filter now reads the record's own quest affiliation and refuses anyone the game
  wrote and placed, and the once-a-session sweep clears any already on an existing save.

### Nothing arrives where it should not
- **The turf, stealth and apartment gates never worked.** The player's state (which zone you are
  in, whether you are in a stealth situation, whether the game has emptied your hands, whether a
  scene is running) lives on a blackboard that belongs to the player. Every read in Cyberbane went
  to the game's shared one instead, which is always zero. So the gate meant to keep Rivals out of
  a gang compound during a quest, the one that holds arrivals during a stealth job, and the one
  that keeps them out of apartments were all switched on and doing nothing. All of them read the
  right place now. This is the I WALK THE LINE report: nothing arrives while you are inside a
  restricted or dangerous area, which is what a gang nest, a corpo floor and a quest compound all
  report. The Hub says when this is why an arrival is waiting, and the Respect quest areas setting
  still turns it off.
- **Enemies appearing in front of you.** The out-of-view test was applied to the point a group
  forms up on and never to the points bodies were actually placed at. Every placement is tested
  now. The last-resort placement also checks that the spot is free and, for the first body, that
  it can reach you, so nobody is stacked on one point or dropped somewhere sealed off.
- **Gang crews spawned into another gang's territory were invisible to it.** They are given the
  attitude group the game itself would have given them.

### Gangs at war
- **A gang can come to like you.** Standing could only ever fall. Gangs now have enemies of their
  own (the Valentinos and 6th Street, the Tyger Claws and the Mox, the Aldecaldos and the Wraiths,
  Arasaka and Militech, and nearly everybody against the Scavs), and hurting a gang raises your
  standing with every gang that hates it, by a share of what it lost and by whether anybody saw
  it was you.
- **What being liked gets you.** A gang that comes round texts you about it. Friendly gangs stop
  backing away from you in the street, vendors on their turf give you better prices, and they warn
  you when their enemies send people after you. Vendors on the turf of a gang that wants you dead
  charge more.
- **Vendettas are dated.** The Gangs screen has always had room to say when a vendetta was sworn,
  and nothing ever recorded it. It is recorded the moment it happens now, and the gang tells you.

### The Hub
- Plain names for every screen and a line under each saying what it holds.
- **History reads as sentences.** It printed the entry's internal name and a raw number, such as
  "RivalCreated (CityCenter) 12", where 12 was a Rival's id. It also only ever recorded Rivals and
  jobs. It now records what the street talks about: Rivals made and put down, apex enforcers and
  bosses people saw you kill, massacres, vendettas sworn, gangs that came round, peace bought,
  tribute taken and the times you were put down.
- The City uses district names instead of internal ids, the Gangs screen explains what each
  posture means and how to win a gang over, and its wording now matches what gangs actually do.

### Map markers
- They use the game's gang-activity marker, do not show through walls, and come off once the
  fight starts. A setting chooses everyone Cyberbane sends (default), only the named ones, or none.

### Note on your settings
Two options changed type, so Mod Settings may reset them to their defaults: the map markers
(everyone Cyberbane sends) and where messages go (your phone). Nothing else is affected.

## [1.4.6] - 2026-11-01

### Fixed
- **1.4.5 would not compile for some people running Fenix Rebirth.** The file that talked to
  Fenix hooked a function from Fenix's death-history API, which is a recent addition to that
  mod, so anyone on an older build of it had the mod but not the function and redscript
  stopped with an error. That is my mistake twice over: I tested against one version of
  Fenix and treated "the mod is installed" as "this part of the mod exists". The file is gone.
- **The integration still works, and now it works with any death alternative.** Cyberbane
  already knew V had died and already knew who did it; it was only waiting for the next load
  to act on it, which never comes if you do not reload. It acts at the moment of death now, so
  whoever put you down becomes the rival who did it whether you are running Fenix Rebirth,
  something else, or nothing at all. There is no longer anything to install, enable or match
  versions with.
- **Rivals arriving inside terrain and locked buildings.** Spawn points come from the game's
  own navigation search, which answers "can somebody stand here" and not "can somebody walk
  from here to the player". Those are different questions inside a sealed building or under
  the landscape. The first arrival of any group is now checked for an actual walkable route to
  you and refused without one, and the rest of the group forms up near them rather than each
  going looking for its own corner.

## [1.4.5] - 2026-11-01

### Added
- **Fenix Rebirth integration.** Fenix lets V survive death instead of reloading. Cyberbane has
  always promoted whoever killed you, but it did that on the next load, which with Fenix never
  comes, so the one thing a nemesis system is for was quietly missing for anyone running both.
  Now the moment Fenix confirms a death, the enemy who did it becomes the rival who did it, or
  the rival who already was gets promoted for doing it again. They carry the mark of the weapon
  they used, and their gang reads you as somebody they have beaten. It needs no setup and no
  extra download: with Fenix installed it is on, without it nothing changes. Thanks to the
  Fenix Rebirth author for the API and for getting in touch.
- Any mod can do the same through `CyberbaneAPI.ReportPlayerKilledBy`.

### Fixed
- **Apex squads never arrived.** The Hub counted down and nobody came. Once the squad was put
  in a car, Cyberbane treated the request as the arrival and closed the appointment when the
  drive clock ran out, whether or not anybody had got out of the car. If the car could not be
  delivered, which is most places, the squad was written off in silence. Cyberbane now checks
  whether they actually turned up and walks them in when they did not. This got worse in 1.4.1,
  because before then the car request could not succeed at all and the walk-in always ran.
- **An apex squad is four roles, always.** The heavy, the shooter, the blade and the netrunner
  were worked out from each spawned enemy's own record, so a gang that had only lost shooters
  to you sent four shooters. The roles are handed out by seat now, so a squad reads the way a
  MaxTac drop reads whatever that gang has on file. They are the gang's own people, not
  reskinned MaxTac, so putting them down still draws nothing from the law.
- **Bodies stacking into a column.** Everyone arriving in a car was created at the exact centre
  of the car and moved into their seat a moment later. When that move does not happen, and it
  does not happen indoors or wherever the car itself landed badly, several people end up
  occupying one point and the engine resolves it by piling them up. Reported with a photograph
  of eight Tyger Claws fused together on a balcony. Seats are now spread around the car, and
  nothing Cyberbane spawns can be placed on top of anybody else.
- **The Hub at 720p and 768p.** It still ran off the edges below 1080p. It now measures the
  screen two ways and takes the smaller, so it fits whichever way the game is reporting it.

## [1.4.4] - 2026-10-31

### Fixed
- **Every gang was arriving in the same car.** The car was meant to be picked per faction so
  each gang had a look, but the arithmetic behind it always landed on the first one in the
  list, so every gang in the game turned up in the same pickup. Which car a gang brings is now
  written down per gang rather than worked out: a pickup for the crews who live rough, a saloon
  for the ones who work the city, a van for the ones who come in numbers. Corps keep the
  Militech security car, which suits Arasaka, Militech and Kang Tao and was only ever wrong on
  a gang.

## [1.4.3] - 2026-10-31

### Added
- **Reset all Cyberbane data**, in Mod Settings under Debug. Turn it on, hit Apply, and
  everything Cyberbane has recorded on this save is cleared: Renown, Dread, Conduct, every
  faction and district, your Rivals, titles, log and tallies. The switch turns itself back off
  once it is done. Reputation only ever built up before this, Conduct included, so a
  playthrough that ended up somewhere you did not intend was stuck that way and the only way
  out was a new save. Your cyberware rating is not affected, because it is not stored: it is
  read back off the chrome you are wearing every few seconds and returns on its own.
- **Interface size**, in Mod Settings under UI. Sets how large Cyberbane's own screens and bars
  are, on top of the automatic fit below.

### Fixed
- **The Hub and the threat bars no longer overflow the screen.** They were drawn at a fixed size
  that assumed a 1920x1080 interface. That is what you get at 1080p with the game's UI scale
  left alone, which is why this was missed, but raise the UI scale or play below 1080p and the
  space available shrinks under what Cyberbane was drawing, so the panel ran off the edges and
  took the text with it. Cyberbane now measures the space it actually has and fits itself to
  it, rechecking whenever the Hub is opened so changing resolution or UI scale takes effect
  straight away.
- **A Rival you put down without killing left a map marker behind forever.** The marker is
  attached to the body and was only ever removed when one died, so beating a Rival unconscious
  left a pin on the map for the rest of the save. Anyone raising their Conduct by going
  non-lethal collected one per Rival and had no way to clear them.
- **Rivals appearing to teleport.** Same cause. Because an unconscious Rival did not count as
  being in the world, Cyberbane thought the encounter was over and sent the same Rival again
  with a new body, placed behind you: in an alley a block on, or on top of a building you had
  just climbed. The body you left behind stayed where it fell, which is the one players kept
  walking back into. Leaving a Rival alive now ends the encounter properly and puts them on the
  same cooldown as one who got away.
- **Police picking fights and ramming you with no stars showing.** The NCPD were being treated
  as just another gang, so once you had killed enough police they turned on you and started
  sending crews and cars after you, dispatched through the game's own pursuit behaviour and
  completely separately from your heat level. The law now stays out of all of that; it already
  has heat and MaxTac for the same job. Corps are unchanged, since Arasaka and Militech sending
  people after you is the point.
- A gang's hit squad no longer turns up in a Militech security car. Any crew of more than two
  was being given one, which read as the law arriving rather than the gang you had annoyed.

## [1.4.2] - 2026-10-30

### Added
- **A cyberpsycho you take alive can come back for you.** Regina asks you to leave them
  breathing and then nothing in the game ever follows it up. Now there is an even chance that
  one you spared turns up as a rival later, under their own name. They come back with wits and
  nothing else: they press the attack while shooting, keep pace when you walk away, do not
  freeze under a stun and are not fooled by optical camo, and not one point of health or armour
  is added to what they already had. Only sparing does it, killing one ends it, and the rival
  cap still applies, so a full list means nobody new until you clear it. There is a setting.
  Story characters are still refused: the cyberpsycho tag alone would have let Adam Smasher,
  Placide and Woodman through, so the test is the quest affiliation the sightings carry.

### Fixed
- **An apex squad arriving on foot was one enemy.** Only the car arrival ever built a squad of
  four with their roles. Anywhere a car could not be placed, which is most of the time, you got
  a single apex with a couple of ordinary crew. Walking in now puts the same four on the
  ground: the heavy, the shooter, the blade and the netrunner.
- **The MaxTac horn never played.** It was asked for with no emitter and no entity, and the
  game only ever plays that event on a vehicle's emitter, so it produced silence with nothing
  anywhere to say the call had done nothing. An apex squad arriving sounds like one now.

## [1.4.1] - 2026-10-30

### Fixed
- **Enemies that could not be killed.** An apex was built at up to seventeen times health
  behind seven times armour against a maxed character, which is not a hard fight, it is a wall.
  They now take several times the punishment of the enemy they were promoted from and no more.
  Their damage is untouched and so is the tactical kit, which is what was supposed to be
  carrying the difficulty.
- **Gangs were building their enforcers from story characters.** A gang files the record of
  somebody it has lost to you and sends more of that kind later. The test for "this is a
  one-off character, do not keep it" only caught quest NPCs, so killing a cyberpsycho or a
  boss-rarity elite filed that record, and every apex squad the gang sent afterwards was built
  from it: four copies of something with a boss's health, with the apex multiplier on top. The
  test is now the same one the rival roster uses, and any such record already on file is
  dropped when you load.
- **Enemies spawning in mid air.** Spawn points taken from the game's own navigation search
  were used as handed over. In the vertical parts of the city a point can sit well above
  whatever is underneath it, and what lands after the fall is a ragdoll that cannot be shot and
  carries no bar. Every spawn point is now stood on the floor beneath it, and a point with no
  floor within reach is refused.
- **No crew ever arrived by car.** The call that asks the city to send one went through the
  wrong system and could never succeed; the compiler had been saying so on every build. Fixed,
  so crews can pull up instead of only ever walking in.
- **Nothing was sent for the first ten minutes of every session.** Each lane rests for a while
  after an encounter ends. Both the clock and the stamp it is measured against start at zero on
  a load, so a lane that had never done anything read as one that had just finished something,
  and sat out the whole rest period after every single load. The Hub reported this as "due,
  nobody qualifies yet" while a full rival list waited, which was not true and sent people
  looking in the wrong place. A lane that is resting now says so and counts down.
- **Clothes were not being read at all on a lot of saves.** If you dress through the wardrobe
  rather than by equipping items one at a time, the clothing slots are empty and the items live
  in the wardrobe set, so a fully dressed V reported as wearing nothing: no chrome hidden, no
  mask detected, the whole concealment system quietly doing nothing. It now asks the game the
  same way the game asks itself.
- **Health bars going missing.** An enemy who arrived while the HUD was being rebuilt, which
  happens after a load or a fast travel, was dropped and never got a bar for the rest of the
  fight. They are held now and the bar appears as soon as there is somewhere to draw it.

### Changed
- **A mask means nobody runs.** Covering your face used to take about a fifth off what the
  street reads, which is not enough to change anything you could see. Now people do not scatter
  from you at all while it is on: whatever you are known for, a stranger cannot attach it to the
  person walking past them. Opening fire still frightens people, because that reaction is the
  game's, not this mod's.
- **Everyone the mod sends is on your map.** Markers were on rivals and apex squads only, so
  searching for a crew that had just been announced turned up nothing and looked broken. Crews
  and escorts carry one too.

## [1.4.0] - 2026-10-30

### Fixed
- **Story characters and cyberpsychos could come back as rivals.** A player killed LT Mower on
  a cyberpsycho gig and later found her waiting outside their apartment, effectively unkillable
  - a cyberpsycho's own health is enormous before a rival's buffs are added on top. Rivals are
  built by respawning a character, which is right for a nameless ganger and wrong for anybody
  the story owns. They are now refused outright, using the marker the game itself puts on those
  characters, so this is closed wherever a rival is created rather than in one of the eight
  places that create them.
- **Messages no longer talk over each other.** The game shows one centre-screen message at a
  time, so when several things happened at once each one replaced the last before it could be
  read. There is a minimum gap between them now.

### Added
- **The corps fight like soldiers now.** Arasaka, Militech and Kang Tao were always full
  factions, so they already turned on you, bred rivals and sent crews and apex squads. They
  just fought like a gang with better guns. They advance while firing instead of trading shots
  from cover, they keep pace if you try to walk away, they call it in, they do not fall over to
  a stun-lock, and they can see through optical camo, so a stealth build has to work for it.
  None of this makes them take longer to kill. The complaint that started this was an enemy
  nothing could hurt, and more health would have been the wrong answer.
- **They show up on your map and minimap.** A rival, an apex squad or a crew that has been sent
  after you carries a marker, so you can tell which of the people on the street are the ones
  that matter instead of guessing. It follows them as they come for you and clears when they
  are dead. The escorts that arrive with an apex squad are deliberately left unmarked, since
  the point is to pick the dangerous one out of a crowd. There is a switch for it under
  Interface.

### Changed
- **Arrival messages say something useful.** "Has caught up with you" was read as "caught up in
  level" as often as "is standing behind you", and never said which of the people nearby was
  the one that mattered. A rival arriving now names their gang and points at the bar carrying
  their name, and gangs are called what they are called rather than by their internal id.

## [1.3.9] - 2026-10-30

### Fixed
- **Rivals can start themselves.** A rival only exists once somebody has escaped you or been
  spared, so a new playthrough had none at all and the rival queue sat silent through the whole
  opening. If your state was ever reset by an update, the same thing happened to you mid-save.
  When the queue's turn comes and there is nobody on the books, the gang you have actually been
  fighting puts somebody forward instead, built from one of their own people you have already
  met. Hit a gang once and they can answer.

### Changed
- **This update does not reset your progress.** No saved field changed shape, so your
  reputation, rivals and gang standing carry over. Earlier builds today did reset it, which is
  why rivals kept vanishing.

## [1.3.8] - 2026-10-30

### Fixed
- **Enemies sent after you were never marked as aggressive, so everything else was being asked
  of an NPC the game still thought was passive.** The game marks its own pursuers with a flag,
  and an ordinary ganger does not have it. Without it the order to turn on you can quietly do
  nothing. They get it now, the same way the NCPD and the gangs' own fighters do. This is the
  piece that was missing behind several versions of enemies standing around.
- **You were being left waiting the better part of an hour.** The daily allowance was set by
  feel rather than against the clock. A day in Night City is about three hours of actually
  playing, so three rivals a day meant one every fifty-nine real minutes, and the Hub was
  honestly reporting it. Something now comes for you about every ten minutes: rivals roughly
  every twenty, crews every thirty-five, apex squads every forty-five, so an apex squad is
  still the rare one. All three remain sliders, now up to twenty a day.
- **No more dead start.** The day's plan is laid out across the whole day, so loading in at the
  wrong moment could leave the next encounter most of an hour away. The soonest one is pulled
  to within a few minutes of you sitting down. The rest of the day keeps its shape.
- **The plan is no longer built before the clock is running.** Right after a load the game
  cannot say what day or hour it is, and the timetable was being built against that: the log
  showed a plan for "Day 0" seconds before a save on day 87 loaded, then no lane doing anything
  for five minutes. It waits for the clock now.
- **The incoming line can no longer name a rival the Rivals screen does not list.** It printed
  whoever the queue held without checking they were still someone who could come.
- **Clothing is detected properly.** Coverage only asked one of the two ways the game stores
  what you are wearing, and on a real save that one came back empty for every slot, so nothing
  ever counted as covered. It asks both now.

### Changed
- When a queue is due but has nobody who qualifies, it says so in the log once a minute instead
  of sitting silent, since silence and a broken queue look identical from the outside.

## [1.3.7] - 2026-10-30

### Fixed
- **A rival who could not be placed blocked every other one behind them.** If the mod could not
  find anywhere to put a rival, it kept their turn and tried the same one again, forever. The
  Hub said they were arriving any moment the whole time while everyone else sat waiting their
  turn. Now that rival goes on a short cooldown and the queue moves on to somebody who can
  actually turn up, coming back round to them later.
- **It never said why.** A rival that could not be placed failed silently, so there was nothing
  to go on. It now says so, and says what stopped it.
- **The Hub was rebuilding itself every time you opened it.** The flat-panel option added in
  1.3.5 asked for a layer that does not exist, so it fell back every time and then rebuilt on
  the next open because the layer it got was not the one it asked for.

- **Hit squads and apex squads had the same trap as rivals.** If one could not be placed, the
  appointment stayed on the books and that gang's whole lane stayed blocked. All three give up
  after a bounded wait now and reschedule, and all three say why they could not be placed.
- **Quiet killing no longer reads as brutality.** Killing with a blade, bare hands or a takedown
  only costs Conduct if somebody actually saw it. Conduct is the street's read on you and the
  street cannot have an opinion about something nobody witnessed. There is also a switch to
  turn that scoring off entirely.

### Fixed
- **Enemies are placed the way the police are placed.** Every spot the mod considered was
  directly behind you, so a wall, a building or a drop in that one direction failed all of them
  and the encounter was refused while perfectly good ground sat to either side. It now asks the
  game's own navigation system where a pursuer could stand, which is exactly what the NCPD use
  to put a squad on your street. Rivals, gang crews and apex squads all go through it.
- **Nothing spawns in the game's own no-spawn areas any more**, using the same test the police
  use rather than a second opinion.
- **Covering up now visibly changes the number.** The visible chrome scale ran off the end of
  its own ceiling, so a fully chromed V was pinned at the maximum and putting a coat on could
  cut the real figure by a third while the bar did not move at all. Fully chromed and uncovered
  now reads 98 instead of overflowing, and the same build under a coat reads 49.
- **A mask lowers how frightening you are to a stranger, the moment you put it on.** Your
  reputation is a total built up over a playthrough and a mask cannot undo that, but it does
  stop people connecting any of it to the person in front of them, so the street reads you as
  less dangerous straight away.
- **How frightening you are now follows what people can see.** It was reading everything you
  had installed rather than what was on show, so putting a coat on could never change it.
- **The Rivals screen could name somebody it then did not list.** With more rivals than rows,
  the one actually on their way could fall off the end of the list. They are pinned to the top
  now.
- A lane that was due but had nobody eligible read "next in 0s", a clock that never counted
  down. It says what is actually holding it up.

### Added
- **What you wear hides what you are carrying.** Visible chrome was counted from what you had
  installed, so a fully chromed merc in a parka read exactly as loud as the same merc in a
  vest. An outer layer now covers your arms and skin, trousers cover your legs, and anything
  across your face covers your eyes. Covered chrome still counts for a quarter, because a coat
  moves and heavy arms still change how somebody carries themselves. Everything that reads your
  chrome follows: how frightening you are, and how far away people start noticing you.
- **A mask means nobody can say it was you.** Wear one and witnesses stop being able to put
  your name to what they saw. Your reputation barely grows, no story about you travels, and
  gangs are far slower to turn against you. The bodies still turn up, so the district grows
  frightened of something it cannot identify, which is exactly the reputation a masked merc
  should have. Glasses and visors do not do this; they only hide eye chrome.
- **The day runs to a plan now.** An in-game day is split into three eight-hour stretches, and
  each kind of encounter gets its own window inside them, staggered so a rival and an apex squad
  sharing a stretch arrive hours apart rather than together. Three rivals means one in each
  stretch; two crews and two apex squads take two stretches each, and which ones is decided
  fresh every day. The exact moment inside a window is random, so it never becomes a timetable
  you can learn. Raising the per-day sliders puts more into each stretch.
- **Sleeping and fast travel no longer bank encounters.** Anything whose window passed while you
  were away is simply missed, so you never arrive somewhere and get everything you were owed at
  once. An encounter that cannot be placed keeps trying until its window closes, then gives up.
- **The Hub says when the next one is due, in real time.** Scheduling is all in-game time, but
  the screen converts it, so a window eight in-game hours out reads as about an hour of play.

- **A slider for how frightening unseen work is.** Half of a killing nobody witnessed used to
  count toward how frightening you are, because the bodies still turn up. That is still the
  default, but you can now turn it down, or to zero if you want only what people actually saw
  to count. Made for quiet playstyles where the street was emptying around someone nobody had
  ever seen do anything.

### Changed
- **The Hub's timers are in real time.** Readings like how long a gang has been quiet came off
  the world clock, which normally runs about eight times faster than real time, so "quiet 43m"
  meant about five minutes of play. Everything on that screen is now in your seconds. The rate
  is measured each session rather than assumed, so it stays right with mods that change how
  fast the day passes.
- **The flat Hub option is gone, and the Hub is back on one layer for good.** Three layers were
  tried across three versions: one takes your controls away, one does not exist, and the
  original works. The curve stays. Flat colour was the larger half of that problem and it was
  fixed in 1.3.4 without touching layers.

## [1.3.5] - 2026-10-30

### Fixed
- **The Escape key had taken over the Hub.** 1.3.4 moved the Hub onto the layer the game uses
  for its own menus, to get rid of the curve. That made the game treat the Hub as an open menu,
  so Escape started driving it. The Hub key is F7 again and nothing but your Hub key controls
  it. Escape is now refused outright as a Hub key, whatever it is set to.

### Changed
- **The Hub is still flat, by a different route.** It is drawn on the layer the game uses for
  its own passive overlays, which is straight rather than curved and does not take control away
  from you. There is a switch for it in Mod Settings under Interface, on by default: if the Hub
  ever stops opening or Escape starts controlling it again, turn that off and it goes straight
  back to the old behaviour without waiting for an update.

## [1.3.4] - 2026-10-30

### Fixed
- **The Hub was glowing far too much.** Every colour on it was set brighter than white, which
  the game turns into bloom, so text and thin lines smeared light across a dark screen. It is
  flat colour now, like the game's own menus.
- **The Hub was bowed in the middle.** It was being drawn on the gameplay HUD, which the game
  curves on purpose so it reads like a visor. That is wrong for a page of text, so it is drawn
  on the menu layer instead, which is flat.
- **The first tab was printed on top of the Cyberbane title.** The title has its own line now.
- **The Rivals screen said several rivals were here at once.** It was reading a flag that is
  set when a rival starts hunting you and never cleared, so anyone who had ever come for you
  claimed to be standing in front of you. It asks the world now, so only a rival actually there
  says so.
- **The incoming line could name a rival who was not on the Rivals screen.** If that rival was
  spared or retired after being queued, the queue kept counting down toward them anyway. The
  queue re-checks who it is holding and moves on to somebody who can actually turn up.
- **A gang could be quiet for days because nothing decided how busy a day should be.** A lane
  sent somebody whenever its gap elapsed and went on doing that for ever, so how much happened
  depended only on how long you stayed in one in-game day.

### Added
- **A day now has a shape.** Three Rivals, two gang crews and two apex squads can reach you in
  one in-game day. Each kind keeps its own allowance, so a busy day of Rivals does not use up
  the crews, and once a kind has spent its allowance it is quiet until the next day. All three
  are sliders in Mod Settings, up to twelve each, and setting one to zero turns that kind off.
- **The Hub shows the allowance.** Each line on the incoming list says how many of that kind
  have come today out of how many can, so the pacing is something you can see. A kind that is
  finished for the day says so rather than just saying nobody is coming.

## [1.3.3] - 2026-10-30

### Fixed
- **Turning Rivals off was silently turning Conduct off.** The credit for putting someone down
  alive was awarded inside the same check that decides whether they come back as a Rival, so
  switching Rivals off took the whole non-lethal half of Conduct with it and nothing said so.
  Conduct is earned the same way whatever your settings are; the Rivals switch now only
  controls the Rival.
- **Enemies sent after you now actually have you as a target.** They were made hostile, which
  decides how they feel about you, but were never handed you as something to track, so until
  one of them happened to spot you on their own they had nobody to fight. This is the missing
  half of how the game itself starts a fight.
- **Your own systems had been cancelling each other.** An enemy whose nerve broke and ran was
  immediately handed a fresh order to come at you, which cancelled the panic. They are left to
  run now.
- **Enemies breaking and running frightened nobody.** The same missing detail as the crowd fear
  fixed in 1.3.2, in one more place.

### Changed
- **The STYLE readout is called Operator rather than Professional.** Conduct's top band was
  renamed Disciplined last version to stop the two reading as the same thing, which only half
  worked while the other one was still called Professional. Both halves are distinct now.
  Operator goes up for finished gigs and hustles; Conduct moves on how you treat people in a
  fight. They are unrelated and now look it.

## [1.3.2] - 2026-10-30

### Changed
- **The Hub is a full-screen page now, built to look like the game's own settings menu.** Same
  font, same salmon-and-white palette, tabs centred across the top with the open one underlined,
  a rule under them, and the key hints along the bottom. The columns are half as wide again, so
  a Rival's full name fits where it used to be cut off, and the gang and rival lists are banded
  so a name and its numbers stay paired across the width of the screen.
- **The street stopped repeating itself.** There were six overheard lines in the whole mod, one
  per mood, with nothing substituted into them, so you heard the same sentence for the hundredth
  time and it stopped meaning anything. There are now several for every mood, the last one used
  is never the next one used, and they name the gang, the district and your title. Most
  importantly they can be about a specific thing you actually did: if a story has travelled to
  the district you are standing in, that is what you overhear, which is the first time anything
  a player can hear has come out of the rumour system at all.

### Fixed
- **Clearing a room without killing anyone now counts as clearing it.** Put a whole crew down
  non-lethally and the mod went on believing the fight was still happening: that gang could
  never be sent after you again, and the fight never ended. Anyone unconscious is out of it now,
  the same as anyone dead, and a takedown counts toward the fight you are in.
- **The Hub shows what it had been quietly counting.** How many times you have been put down,
  how often you have been recognised on the street, what you have taken in tribute and paid out
  for peace, and how many rivals you let live. Gangs show how long they have been quiet, or how
  long a vendetta has been running, and districts show how long since you last did anything
  there. All of it was being recorded already and none of it was on screen.
- **Frightened people were not frightening anyone else.** When somebody panics at the sight of
  you, the game is told about it so everyone nearby can react. Cyberbane was sending that
  signal without saying how far it carried, which is nobody. Crowd fear now reaches the people
  around the person it happens to, so a street clears the way it is supposed to instead of one
  person flinching on their own.
- **An apex squad arriving now clears the street.** The game does this when MaxTac drops in, and
  an apex squad is meant to land the same way, so everyone in sight gets out of the way as they
  arrive.
- **Walking around with a blade out makes people nervous.** How dangerous you look was reading
  your chrome and guessing from that; it reads what you are actually holding now.
- **Conduct could only ever go down.** Sparing someone is worth a point of Conduct, and that
  point was never awarded: every incident was recorded as a kill, including the ones where you
  left them breathing, so the whole non-lethal half of the scoring never ran. The Disciplined
  band at +40 was unreachable, which is why nothing you did seemed to move the bar. With it
  working, the vendor goodwill and the respect-toned street talk that sit behind that band can
  happen at all, the "leave people alive" titles are obtainable, and mercy counts toward how
  civilians read you. Knocking somebody out and then killing them anyway takes the credit back.
- **Your gang and district tallies for sparing people were stuck at zero** for the same reason,
  as was the quiet-takedown count that the Ghost of a district is named for.
- **Every melee kill was scored as a blade kill.** The game was asked what kind of attack it
  was and never which weapon did it, so a hammer, bare fists and a katana all came out the same
  and all took the brutality penalty. The weapon is read properly now: blades and bare hands
  count as brutal, clubs and hammers are their own thing, and explosives are no longer filed as
  gunfire. Five of the eleven ways a kill could be described were never detected at all, so the
  formulas reading them were adding nothing. Killing someone by hand in a takedown counts as a
  finisher again, which is the one case the brutality rule was really about; the rest are gone
  rather than left in looking useful.

### Changed
- **The Conduct bar's top band is called Disciplined.** It used to be Professional, which is
  also the name of a STYLE on the same screen, and the two measure unrelated things and move on
  unrelated events.

## [1.3.1] - 2026-10-30

### Fixed
- **The car that was always sent and never seen.** The game seats a chase crew by two numbers
  on the car's own record, and the cars Cyberbane was asking for are ordinary traffic that do
  not carry those numbers at all. A car with no stated capacity seats nobody. It now asks for
  the cars the game's own pursuits use, picking one that holds the whole crew, and it never
  asks for more people than the car will take.
- **An apex squad's escort was being counted as a hit squad.** They wore the same tag, which
  meant two things went wrong: a gang that had sent nobody looked like it had a crew on you, so
  no hit squad from that gang was ever arranged while an apex squad was out, and an escort was
  indistinguishable from another gang's crew that happened to be there at the same time, so the
  two read as one squad with members of two gangs in it. They fight exactly as before.

### Changed
- **The bars name the gang.** A Rival still shows their name. Everyone else shows their role and
  who they are with, so a Scav apex squad turning up while a Valentinos crew is still on you
  reads as two separate problems instead of one confusing one.

## [1.3.0] - 2026-10-30

### Fixed
- **The boss bar never appeared, for anybody.** Rivals and apex squad members were being handed
  to the game's own boss health bar, which turns out to reject anybody who is not a boss in the
  game's own files before it draws anything. Nothing Cyberbane sends can pass that test, so the
  call did nothing every time, and the bar Cyberbane draws itself was never reached because the
  code treated the rejected call as a success. It is drawn by Cyberbane now, always.

### Changed
- **A bar each, and they tell you who you are fighting.** There is a stack of them now rather
  than one, so you can see at a glance which of the people shooting at you matters: a Rival
  shows their name, and each member of an apex squad shows their role, the way a MaxTac drop
  reads as a heavy, a blade, a netrunner and a shooter instead of four interchangeable enemies.
  Ordinary crew still get nothing, which is the point. The stack holds an apex squad of four
  plus a Rival, which is the most that can be on you at once, and bars drop off as they die.
- Bars come down the moment you outrun an encounter, rather than a beat later.

## [1.2.9] - 2026-10-30

### Changed
- **The city sends the car now.** A vehicle arrival used to be assembled by hand: find a spot,
  put a car on it, sit the crew inside, point it at you. The game already has a vehicle chase
  that works, because it is the one the NCPD run on you, so Cyberbane asks for that one instead.
  The car is placed properly on the road network and driven at you with real pathing, and it
  keeps coming across junctions and districts.
- **The crew that turns up is still a Cyberbane crew.** They are adopted the moment they
  arrive, so they get their buffs and their role kits, the Hub counts them as the encounter they
  are, an apex squad still brings the boss health bar, and you can still shake them off and lose
  them. An apex squad also keeps its shape in the car: a heavy, a shooter, a blade and a
  netrunner in the four seats, instead of four of the same.
- If the city cannot take the request, the hand-built convoy still runs as a fallback, and
  indoors or anywhere there is no room for a car they come on foot, the same as before.

## [1.2.8] - 2026-10-30

### Fixed
- **You can lose them now.** Hunters were being handed your position every few seconds no
  matter how far you got, which is a leash rather than a chase. Get about a hundred and twenty
  metres clear of all of them and stay clear for twenty seconds or so, and they give up, the
  same way the police in this game do. A rival you shake still takes it personally and comes
  back promoted, so escaping remains a real outcome rather than a free pass.
- **The first screen no longer runs into the line at the bottom.** Two explanations came off
  that page when the incoming block was added, with a line of headroom kept in reserve.

### Changed
- Vehicle arrivals now record what the car actually did - that it set off, that it gave chase,
  and when its crew got out - so a car that is dispatched and never seen can be told apart from
  one that was never dispatched.

## [1.2.7] - 2026-10-30

### Fixed
- **Some spawned enemies lay face down on the ground doing nothing.** Crew arriving by car were
  told to get out of it, and that order was going to everyone wearing the crew tag rather than
  only the ones actually sitting in a vehicle. The tag is never removed and the check repeats,
  so it also reached people already standing on the pavement and people whose ride never took.
  Telling somebody to climb out of a car they are not in leaves them like that.
- Spawns are placed a little higher off the floor. A tenth of a metre left them clipping the
  surface they had been put on, which the game resolves by dropping them into a ragdoll.

### Changed
- **The city leaves you alone between encounters.** Each kind now rests for ten minutes after
  its last fight ends before it starts arranging the next one, and the three kinds rest
  separately, so a rival can still be on the way while a gang is cooling off. The wait is
  measured from the end of the fight, so a long one does not eat into your breathing room.
  There is a setting for it, from two minutes up to thirty.
- Once a lane does pick somebody, the warning before they arrive is shorter, since the wait
  between encounters now does the spacing instead of the countdown.

## [1.2.6] - 2026-10-30

### Fixed
- **Some enemies took no damage at all.** If one of them attached to the world twice, which
  streaming can cause, every stat boost was applied a second time on top of the first. At full
  strength that turns sixteen times armour into two hundred and fifty six times, which is not a
  hard fight, it is an enemy nothing can hurt. Boosts are applied once now.
- **Enemies spawning in mid-air.** The last attempt at placing somebody used your own height
  with no check for a floor underneath. On flat ground that is fine; standing on a walkway, a
  bridge or a ramp, it drops an enemy into the air over the gap. It now refuses that spot, and
  because a refused arrival keeps its turn and tries again shortly, nothing is lost by refusing.
- **Arrival messages say what has turned up.** They now name it as a rival, a hit squad, or a
  vendetta crew with an apex squad, instead of leaving you to work out which one you are
  looking at.

## [1.2.5] - 2026-10-30

### Added
- **The Rivals screen now says why the next one is after you.** "You beat them down and left
  them alive." "Got away from you bleeding." "Put you down once." The mod has always known this
  and has never once told you, so the rows carried a name, a gang and a clock while the single
  most interesting fact about a nemesis went unsaid.

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
