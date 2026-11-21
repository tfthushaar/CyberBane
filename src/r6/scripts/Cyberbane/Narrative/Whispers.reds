// Cyberbane - Whispers (spec §9.10)
//
// Overheard lines, shown when a recognized NPC is near and V is notable enough to be worth
// talking about.
//
// There used to be exactly six lines in here, one per mood and topic, with no substitution of
// any kind: the same sentence every time, whoever was speaking, wherever you were, whatever you
// had done. A line you have already heard says nothing about the city, so the whole system read
// as decoration rather than as word getting around.
//
// Three things give it variance now:
//
//   - Several lines per bucket, and the last one used is remembered for the session so the
//     same one never lands twice running.
//   - Substitution. The gang's name, the district a story came from, and V's current title go
//     into the line, so it is about this street and this V.
//   - Rumours. If a story has actually reached the district V is standing in, the speaker can
//     be talking about that specific thing - a massacre in Watson, a boss put down in Heywood -
//     rather than about V in the abstract. That is what the rumour engine is for, and until now
//     nothing the player could hear was driven by it.

// Who is talking. The game's own subtitles put this name in front of the line (1.9.5), so it says what
// the speaker is to anybody looking: one of a gang by that gang's own word for its people, a cop, or
// somebody off the street. "Ganger" six times running was its own kind of repetition, and it never
// said whose.
public func CBWhisperSpeaker(faction: CName) -> String {
  if Equals(faction, n"") || !CBFactionOn(faction) {
    return CBPick3("Passer-by", "Local", "Someone nearby");
  }
  let member = CBFactionMemberWord(faction);
  return StrLen(member) > 0 ? member : CBPick3("Ganger", "Lookout", "Crew member");
}

// One of theirs, the way the street would say it.
public func CBFactionMemberWord(faction: CName) -> String {
  if Equals(faction, n"NCPD") { return CBPick2("NCPD Officer", "Patrol Cop"); }
  if Equals(faction, n"MaxTac") { return "MaxTac"; }
  if Equals(faction, n"Maelstrom") { return "Maelstromer"; }
  if Equals(faction, n"TygerClaws") { return "Tyger Claw"; }
  if Equals(faction, n"Valentinos") { return "Valentino"; }
  if Equals(faction, n"SixthStreet") { return "6th Street"; }
  if Equals(faction, n"Animals") { return "Animal"; }
  if Equals(faction, n"VoodooBoys") { return "Voodoo Boy"; }
  if Equals(faction, n"Scavengers") { return "Scav"; }
  if Equals(faction, n"Mox") { return "Mox"; }
  if Equals(faction, n"Barghest") { return "Barghest"; }
  if Equals(faction, n"Aldecaldos") { return "Aldecaldo"; }
  if Equals(faction, n"Wraiths") { return "Wraith"; }
  if Equals(faction, n"Arasaka") { return "Arasaka Security"; }
  if Equals(faction, n"Militech") { return "Militech"; }
  if Equals(faction, n"KangTao") { return "Kang Tao"; }
  return "";
}

// The strongest story that has actually travelled to where V is standing.
//
// Returns null when nothing has reached here, which is the normal case early on and the reason
// the generic lines below still exist.
public func CBWhisperRumor(sys: ref<CyberbaneSystem>, game: GameInstance) -> ref<CBRumor> {
  if !IsDefined(sys) {
    return null;
  }
  let here = CBDistrictIndex(CBEventDistrict(sys, game));
  if here < 0 {
    return null;
  }
  // Bound to a local first: GetRumors returns the array by value, and indexing the temporary
  // hands back a handle into a copy.
  let all = sys.GetRumors();
  let best: ref<CBRumor>;
  let bestMag = 0.0;
  let i = 0;
  while i < ArraySize(all) {
    let r = all[i];
    if IsDefined(r) && CBMaskHas(r.reachedMask, here) && r.magnitude > bestMag {
      best = r;
      bestMag = r.magnitude;
    }
    i += 1;
  }
  return best;
}

// What the street is saying about that story.
func CBRumorPhrase(sys: ref<CyberbaneSystem>, r: ref<CBRumor>) -> String {
  let where = CBDistrictLabel(r.origin);
  if StrLen(where) == 0 {
    where = "across town";
  } else {
    where = "in " + where;
  }
  let gang = CBFactionLabel(r.faction);
  if Equals(r.kind, n"Massacre") {
    return CBLineOf([
      "Heard they found a room full of bodies " + where + ".",
      "Whole crew went quiet " + where + ". Nobody's saying who.",
      "Word " + where + " is somebody cleared a building on their own.",
      "Trauma Team wouldn't even go in " + where + ". Nothing left to save.",
      "Scrollers are saying " + where + " looked like a war zone. One shooter."]);
  }
  if Equals(r.kind, n"BossKill") {
    if StrLen(gang) > 0 {
      return CBPick3(
        "They put a boss of " + gang + " in the ground " + where + ".",
        CBCapFirst(gang) + " lost someone who mattered " + where + ".",
        "Heard " + gang + " are short a boss " + where + ".");
    }
    return "Somebody took a boss off the board " + where + ".";
  }
  if Equals(r.kind, n"Deed") {
    return CBLineOf([
      "Something went down " + where + ". Street's still chewing on it.",
      "You hear about that job " + where + "?",
      "Everyone's talking about what happened " + where + ".",
      "Fixers " + where + " are calling it the job of the year."]);
  }
  if StrLen(gang) > 0 {
    return CBLineOf([
      CBCapFirst(gang) + " are counting bodies " + where + ".",
      "Another one of " + gang + " down " + where + ".",
      "Not a good week to be " + gang + ".",
      CBCapFirst(gang) + " are pulling their people off the corners " + where + ". Scared, if you ask me."]);
  }
  return "Word is somebody's been busy " + where + ".";
}

// ---- What gets said (1.9.5) -------------------------------------------------------------------------
//
// "Make what the crowd says about you more relevant to what you are in Cyberbane." It said one of three
// moods, a title and now and then a rumour, and that was all it knew. Now every line comes from the
// street's read on V (Model/StreetRead.reds): how V works and how V treats people, the chrome on show,
// the mask, the heat, how well this district knows V, what V is doing right now, and, from somebody
// with a gang, everything between V and that gang - the blood, the mercy, the tribute, the Rival out
// after V, who runs their crew now and whether the gang is breaking. Each of those offers lines when it
// is true, weighted by how much it is worth saying, and the topic the last line was about sits the
// next one out, so the street moves from subject to subject the way people do.

// Is this gang breaking: below the line where the street calls them broken (Model/Territory.reds)?
// Their people stop acting on a vendetta and start being afraid of the one who broke them (1.9.5).
public func CBGangBroken(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  if !IsDefined(sys) || Equals(faction, n"") || !CBTurfWarsOn() || !CBFactionFieldsSquads(faction) {
    return false;
  }
  return CBGangStrength(sys, faction) < CBConfig.GangBrokenStrength();
}

// The line itself.
public func CBWhisperLine(sys: ref<CyberbaneSystem>, game: GameInstance,
                          faction: CName, mood: CName, topic: CName) -> String {
  let st = CBReadStreet(sys, game, faction);
  let gang = StrLen(st.factionLabel) > 0 ? st.factionLabel : "that crew";

  // Topic-specific lines take priority (spec §9.10 topic weighting).
  if Equals(topic, n"bossloss") {
    if StrLen(st.leader) > 0 {
      return CBPick4(
        "You put down one of our bosses. " + st.leader + " runs things now, and remembers.",
        "We know what you did to ours. " + st.leader + " has your name on a list.",
        "That was a boss of " + gang + " you killed. Someone's getting paid for you.",
        "Every one of us knows your face now. Think about that.");
    }
    return CBPick4(
      "You put down one of our bosses. The crew doesn't forget that.",
      "We know what you did to ours. We're not done.",
      "That was a boss of " + gang + " you killed. Someone's getting paid for you.",
      "Every one of us knows your face now. Think about that.");
  }
  if Equals(topic, n"maxtac") {
    return CBPick4(
      "That's the merc who went up against MaxTac and walked away.",
      "MaxTac came for that one. MaxTac went home light.",
      "I've seen the footage. They took on MaxTac and they're still breathing.",
      "You don't survive MaxTac. That one did.");
  }
  if Equals(topic, n"warning") {
    // In their own voice, most of the time (Narrative/GangVoice.reds).
    // Their own words for a stranger (Narrative/GangVoice.reds): a gang V has bled does not call V "civilian" (2.6.1).
    let own = CBGangWarnLine(st.faction);
    if StrLen(own) > 0 && st.kills < CBConfig.WarnKnowsYouKills() && RandF() < CBConfig.GangVoiceShare() {
      return own;
    }
    if st.kills >= CBConfig.WarnKnowsYouKills() {
      return CBPick3(
        "You've put enough of us in the ground. Walk away, or you're next.",
        CBCapFirst(gang) + " remember every one. Turn around.",
        "Last warning. After this it's not talking.");
    }
    return CBPick4(
      "You've got a lot of nerve showing up here. Walk away while you still can.",
      "Wrong street, choom. Turn around.",
      CBCapFirst(gang) + " want you gone. This is the only time we ask nicely.",
      "You're standing on our block. That's one mistake. Don't make two.");
  }

  let bag = new CBLineBag();
  // A gang V has broken is afraid, whatever its vendetta says.
  if Equals(mood, n"broken") {
    CBWhisperBroken(bag, st, gang);
    mood = n"fear";
  }
  // V's own streets (Economy/War.reds, [37]).
  if CBOwnDistrict(game, st.district) && !st.masked {
    bag.Add(n"own", 3.0, CBLineOf(["These are their streets now. Nobody argues.", "Gangs pay to walk through here now. Pay them, I mean.",
                                    "That's who runs this place. Not the Claws, not anybody. Them."]));
  }
  // Something coming near here (Spawn/StreetEvents.reds, [32]).
  let coming = CBEventWhisper(game);
  if StrLen(coming) > 0 {
    bag.Add(n"coming", 2.5, coming);
  }
  // A story that actually reached here.
  let r = CBWhisperRumor(sys, game);
  if IsDefined(r) {
    bag.Add(n"rumor", 3.0 * CBConfig.WhisperRumorChance() / 0.6, CBRumorPhrase(sys, r));
  }
  if st.masked && st.givenAway == 0 {
    // Behind a mask V is nobody: there is no V to talk about, only somebody nobody can place.
    mood = n"fear";
    CBWhisperMasked(bag, st);
    CBWhisperMoment(bag, st, mood);
  } else {
    CBWhisperGivenAway(bag, st);
    CBWhisperNow(bag, st, mood);
    CBWhisperMoment(bag, st, mood);
    CBWhisperRemembered(bag, st, mood, gang);
    CBWhisperIdentity(bag, st, mood);
    CBWhisperConduct(bag, st, mood);
    CBWhisperChrome(bag, st, mood);
    CBWhisperPlace(bag, st, mood);
    CBWhisperGang(bag, st, mood, gang);
  }
  CBWhisperGeneric(bag, st, mood);

  let rt = CyberbaneRuntime.Get();
  let last = IsDefined(rt) ? rt.GetLastWhisperTopic() : n"";
  let pick = bag.Pick(last);
  if pick < 0 {
    return "";
  }
  if IsDefined(rt) {
    rt.SetLastWhisperTopic(bag.topics[pick]);
  }
  return bag.lines[pick];
}

// What V is doing right now beats what V is known for.
func CBWhisperNow(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.recentKills >= 3 || st.aura >= 25.0 {
    if Equals(mood, n"respect") {
      bag.Add(n"now", 3.0, CBPick3(
        "Busy night for that one. Better them than us.",
        "Still got the fight on them. Give them room.",
        "Whatever just happened, I'm glad it wasn't me."));
    } else {
      bag.Add(n"now", 3.0, CBPick4(
        "Blood's still fresh on that one. Don't look.",
        "They just did something. You can see it on them.",
        "Walk. Don't run, just walk.",
        "Somebody's not going home tonight, and that's who did it."));
    }
  }
  if st.heat >= 2 {
    bag.Add(n"heat", 1.5, CBPick3(
      "NCPD's all over the net looking for that one.",
      "Cops want that face. I'm not standing next to it.",
      "Every patrol in the district's got that one's description."));
  }
  if st.layingLow && st.renown >= 30.0 {
    bag.Add(n"quiet", 1.5, CBPick3(
      "Haven't heard that one's name in days. Gone quiet.",
      "Thought they'd skipped town. Guess not.",
      "Quiet lately. That's when you worry."));
  }
}

// Who V is: the name the street gave them, the way they work, how famous they are.
func CBWhisperIdentity(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if StrLen(st.title) > 0 {
    if Equals(mood, n"respect") {
      bag.Add(n"title", 2.0, CBPick3(
        "That's " + st.title + ". For real.",
        "They call that one " + st.title + ". Earned it, too.",
        st.title + ", right there. Don't make a thing of it."));
    } else {
      if Equals(mood, n"hate") {
        bag.Add(n"title", 2.0, CBPick2(
          st.title + ". Big name. Bleeds like anybody.",
          "They call that one " + st.title + ". We call them a target."));
      } else {
        bag.Add(n"title", 2.0, CBPick3(
          "That's " + st.title + ". Eyes down.",
          "Don't. That's " + st.title + ".",
          "You know who that is? " + st.title + ". Keep walking."));
      }
    }
  }
  let a = st.archetype;
  if a == EnumInt(ECBArchetype.Butcher) {
    bag.Add(n"style", 2.0, CBPick3(
      "Heard what that one leaves behind. They hose the place down after.",
      "That's the one who doesn't stop when it's over.",
      "Don't end up in a room with that one. Nobody comes out in one piece."));
  } else {
    if a == EnumInt(ECBArchetype.Ghost) {
      bag.Add(n"style", 2.0, CBPick3(
        "Bodies turn up and nobody saw a thing. That's them.",
        "You don't see that one coming. That's the whole point.",
        "Half the jobs on the net they never got pinned for."));
    } else {
      if a == EnumInt(ECBArchetype.Professional) {
        bag.Add(n"style", 2.0, CBPick3(
          "That one does clean work. In, out, nobody hurt who didn't have to be.",
          "Fixers love that one. Job done, no mess.",
          "A real pro. Rare these days."));
      } else {
        if a == EnumInt(ECBArchetype.Chromed) {
          bag.Add(n"style", 2.0, CBPick3(
            "More chrome than meat on that one.",
            "How much of them is even left under all that?",
            "Ripperdocs must love that one."));
        } else {
          if a == EnumInt(ECBArchetype.Netrunner) {
            bag.Add(n"style", 2.0, CBPick3(
              "Netrunner. Fries you from across the street. Keep your ICE up.",
              "That one cooks brains for a living.",
              "Don't jack in near that one. Seriously."));
          } else {
            if a == EnumInt(ECBArchetype.Brawler) {
              bag.Add(n"style", 2.0, CBPick3(
                "Saw that one put a guy down with bare hands. One punch.",
                "Doesn't even need a gun. That's the scary part.",
                "Fists like that, who needs a piece?"));
            }
          }
        }
      }
    }
  }
  if st.tier >= EnumInt(ECBRenownTier.Infamous) {
    bag.Add(n"fame", 1.5, CBPick3(
      "Wait. Is that really them? On our street?",
      "Everybody in the city knows that face.",
      "I'm telling everyone I saw them. Nobody's going to believe me."));
  } else {
    if st.renown < 15.0 && st.dread >= 40.0 {
      bag.Add(n"fame", 1.5, CBPick2(
        "Nobody knows who that is. That's worse.",
        "No name, no face on the net, and people are scared anyway."));
    }
  }
}

// How V treats people: the mercy, or the lack of it.
func CBWhisperConduct(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.code <= -40.0 {
    bag.Add(n"conduct", 2.5, CBPick4(
      "That one's a bad day away from cyberpsycho.",
      "Heard they shoot whoever's in the way. Civvies too.",
      "Somebody should call MaxTac before it's too late.",
      "Look at the eyes. Nobody's home."));
    return;
  }
  if st.code >= 40.0 || (st.mercies >= 10 && st.code > 0.0) {
    if Equals(mood, n"hate") {
      bag.Add(n"conduct", 2.0, CBPick2(
        "Leaves people breathing. Thinks that makes them a saint.",
        "Soft. Puts people to sleep instead of finishing it."));
    } else {
      bag.Add(n"conduct", 2.5, CBPick4(
        "That one leaves people breathing. Weird, for a merc.",
        "Got a code, that one. Doesn't kill who doesn't need killing.",
        "Put my cousin down once and he woke up. Not a scratch on him.",
        "Hard, but fair. Not many like that left."));
    }
  }
}

// What people can see of V's chrome.
func CBWhisperChrome(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.chromeVisible >= 55.0 {
    bag.Add(n"chrome", 2.0, CBPick4(
      "Look at those arms. Military grade, easy.",
      "All that chrome out in the open. Nobody's going to try them.",
      "Don't stare at the chrome. They notice.",
      "That's not a body. That's a weapon with legs."));
    return;
  }
  if st.chromeInstalled >= 60.0 && st.armsCovered {
    bag.Add(n"chrome", 1.0, CBPick2(
      "Something heavy under that jacket. Moves wrong for flesh.",
      "Dresses plain. Doesn't fool anyone who's looking."));
  }
}

// Where V is standing: home turf for V's name, or somewhere it has not reached.
func CBWhisperPlace(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if StrLen(st.districtLabel) == 0 {
    return;
  }
  if st.districtRenown >= 60.0 {
    bag.Add(n"place", 1.5, CBPick3(
      "Everybody in " + st.districtLabel + " knows that face.",
      "That one practically runs " + st.districtLabel + " now.",
      "Ask anyone in " + st.districtLabel + ". They'll tell you about that one."));
  } else {
    if st.districtRenown < 10.0 && st.renown >= 40.0 {
      bag.Add(n"place", 1.5, CBPick2(
        "Not from " + st.districtLabel + ". Heard the name, though.",
        "What's that one doing in " + st.districtLabel + "?"));
    }
  }
  // A district whose gang V has bled dry, from somebody who lives there.
  if Equals(st.faction, n"") && NotEquals(st.turfHolder, n"") {
    let sys = CyberbaneSystem.Get(GetGameInstance());
    if CBGangBroken(sys, st.turfHolder) {
      let holder = CBFactionLabel(st.turfHolder);
      if StrLen(holder) > 0 {
        bag.Add(n"turf", 2.0, CBPick2(
          "Half the corners " + CBCapFirst(holder) + " ran are empty now. Guess why.",
          CBCapFirst(holder) + " don't scare anybody round here any more. That one saw to it."));
      }
    }
  }
}

// From somebody with a gang: everything between V and that gang.
func CBWhisperGang(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName, gang: String) -> Void {
  if Equals(st.faction, n"") {
    return;
  }
  if StrLen(st.hunter) > 0 && !st.broken && !Equals(st.posture, ECBPosture.Allied) && !Equals(st.posture, ECBPosture.Friendly) {
    bag.Add(n"hunter", 3.0, CBPick3(
      st.hunter + "'s coming for you. Everybody on the block knows it.",
      "Enjoy the walk. " + st.hunter + " has plans for you.",
      "When " + st.hunter + " finds you, I want a good seat."));
  }
  if Equals(st.posture, ECBPosture.Allied) {
    bag.Add(n"gang", 2.5, CBPick3(
      "That's a friend of " + gang + ". You hear me? A friend.",
      "Treat that one like family. Boss's orders.",
      "One of ours, near enough. Anybody starts something, we finish it."));
  } else {
    if Equals(st.posture, ECBPosture.Friendly) {
      bag.Add(n"gang", 2.0, CBPick3(
        "That one's all right by " + gang + ".",
        "Good with the crew, that one. Leave it.",
        "Heard they've been doing us favours. Nod, don't stare."));
    } else {
      // A broken gang's people have no threats left in them (1.9.5); CBWhisperBroken speaks for them.
      if !st.broken && (Equals(st.posture, ECBPosture.Hostile) || Equals(st.posture, ECBPosture.Vendetta)) {
        if st.kills >= 20 {
          bag.Add(n"blood", 2.5, CBPick3(
            "That one's put more of " + gang + " in the ground than the cops ever did.",
            "Every funeral this month, that one's the reason.",
            "You know how many of ours? Too many."));
        } else {
          bag.Add(n"blood", 2.0, CBPick2(
            "We know your face. All of us.",
            "Keep walking. You're on " + CBPossessive(gang) + " streets."));
        }
        if StrLen(st.leader) > 0 {
          bag.Add(n"leader", 1.5, CBPick2(
            st.leader + " runs this crew now. Wants a word with you.",
            "When " + st.leader + " hears you came by, it's on."));
        }
      } else {
        if st.fear >= 60.0 {
          bag.Add(n"fear", 2.0, CBPick3(
            "Don't look at them. Just don't.",
            "Nobody starts anything. Not with that one.",
            "If they want the corner, they can have it."));
        }
      }
    }
  }
  if st.spared >= 3 && !Equals(st.posture, ECBPosture.Vendetta) {
    bag.Add(n"mercy", 2.0, CBPick2(
      "That one let some of ours walk. People remember that.",
      "Could've finished my brother. Didn't. I don't forget."));
  }
  if st.tributes > 0 {
    bag.Add(n"tribute", 1.5, CBPick2(
      "Boss pays that one to stay off our backs. Don't make it worse.",
      "We send them eddies so they leave us alone. Think about that."));
  }
}

// A gang V has broken, afraid out loud.
func CBWhisperBroken(bag: ref<CBLineBag>, st: ref<CBStreetRead>, gang: String) -> Void {
  bag.Add(n"broken", 4.0, CBPick4(
    "Don't. We're done, alright? We're done.",
    "There's hardly any of us left. Just let us be.",
    "Whatever the bosses said, I'm not dying for it.",
    "That's the one who broke " + gang + ". Nobody move."));
}

// Somebody nobody can put a name to.
func CBWhisperMasked(bag: ref<CBLineBag>, st: ref<CBStreetRead>) -> Void {
  bag.Add(n"mask", 3.0, CBPick4(
    "Who's under the mask? Never mind. I don't want to know.",
    "Can't see a face. Don't need to.",
    st.night ? "Masked up after dark. That's never good." : "Masked up in the middle of the day. That's never good.",
    "Somebody who doesn't want to be known. Fine by me."));
}

// What everybody can see right now (Model/Moment.reds, 2.3.1): the blood, a fight just over, the hour, the rain.
func CBWhisperMoment(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.wounded {
    if Equals(mood, n"hate") {
      bag.Add(n"moment", 3.0, CBLineOf([
        "Bleeding already? Somebody did us a favour.",
        "Look who's leaking. Shame if it got worse.",
        "Hurt and on our street. Bad combination, merc.",
        "Somebody softened you up. Lucky us."]));
    } else {
      if Equals(mood, n"respect") {
        bag.Add(n"moment", 3.0, CBLineOf([
          "Somebody get that merc to a ripperdoc.",
          "They're hurt. Give them room, they've earned it.",
          "Still standing, with all that blood. Respect.",
          "Whoever did that to them is in worse shape. Count on it."]));
      } else {
        bag.Add(n"moment", 3.0, CBLineOf([
          "They're bleeding. Somebody's going to try their luck tonight.",
          "Look at that. Even legends leak.",
          "Hurt and still walking around. Brave or stupid.",
          "Don't help. Don't look. Just walk.",
          "That's a lot of blood for somebody still on their feet."]));
      }
    }
  }
  if st.fresh && st.recentKills < 3 {
    bag.Add(n"moment", 2.5, CBLineOf([
      "Smell that? Cordite. Something just went down.",
      "Still shaking off a fight, that one. Don't be the next one.",
      "Heard the shots a minute ago. Now look who walks by.",
      "Whatever that was, it just happened. Keep moving."]));
  }
  if st.night {
    bag.Add(n"moment", 1.0, CBLineOf([
      "Out walking at this hour. Course they are.",
      "Night belongs to people like that.",
      "Nobody good is out this late. Present company included.",
      "Lock the door when you get home tonight. Just saying."]));
  }
  if st.rain > 0 {
    bag.Add(n"moment", st.rain == 2 ? 1.5 : 0.8, CBLineOf([
      "Pouring down and that one doesn't even flinch.",
      "Wet night, and they're still working.",
      "Rain washes the blood off the streets. Busy night for the rain.",
      "Can't see a face in this weather. Didn't need to."]));
  }
}

// Where V is standing, if something big happened there (Model/StreetBook.reds, 2.3.1).
func CBWhisperRemembered(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName, gang: String) -> Void {
  if Equals(st.placeKind, n"") {
    return;
  }
  // One of the gang that lost people here, standing where they lost them.
  if NotEquals(st.faction, n"") && Equals(st.faction, st.placeGang) && !Equals(mood, n"respect") {
    bag.Add(n"remembered", 3.5, CBLineOf([
      "This is where you did it. To our people. And you come back here?",
      "You've got some nerve, standing on this corner of all places.",
      "We still haven't washed this street. And here you are.",
      "Right here. My friends, right here. Keep walking before I forget myself."]));
    return;
  }
  let theirs = CBFactionLabel(st.placeGang);
  if Equals(st.placeKind, n"Massacre") {
    bag.Add(n"remembered", 2.5, CBLineOf([
      "This is where they found the bodies. Right here.",
      "Still can't get the stains out of this pavement. And look who's back.",
      "Don't stand there. That's where it happened.",
      "NCPD took a week to bag everybody from this block. Everybody knows whose work it was."]));
    return;
  }
  if Equals(st.placeKind, n"BossKill") && StrLen(theirs) > 0 {
    bag.Add(n"remembered", 2.5, CBLineOf([
      "This is where " + theirs + " lost their boss. Right on this corner.",
      CBCapFirst(theirs) + " still leave candles on this spot.",
      "Their boss went down right there. The one who did it is walking past us."]));
    return;
  }
  if Equals(st.placeKind, n"ApexDown") && StrLen(theirs) > 0 {
    bag.Add(n"remembered", 2.5, CBLineOf([
      CBCapFirst(theirs) + " sent their best here. Their best didn't leave.",
      "This is where " + CBPossessive(theirs) + " heavy hitters came to die. Look who came back to visit."]));
    return;
  }
  if Equals(st.placeKind, n"MaxTacDown") {
    bag.Add(n"remembered", 2.5, CBLineOf([
      "MaxTac lost one of theirs right about here. Nobody believed it till they saw the scorch marks.",
      "You know what happened on this street? MaxTac happened. And then that one happened to MaxTac."]));
  }
}

// A mask does not hide the car everybody knows, or the gun (Model/StreetBook.reds, 2.3.1).
func CBWhisperGivenAway(bag: ref<CBLineBag>, st: ref<CBStreetRead>) -> Void {
  if st.givenAway == 1 {
    bag.Add(n"knownby", 4.0, CBLineOf([
      "Mask or no mask, that's their car. Everybody knows that car.",
      "Nice mask. Shame about the ride.",
      "You can cover your face. Can't cover that car.",
      "Same car every time. You'd think a pro would know better."]));
    return;
  }
  if st.givenAway == 2 {
    bag.Add(n"knownby", 4.0, CBLineOf([
      "Hide your face all you want. That gun's famous.",
      "Know that piece anywhere. Only one merc carries it like that.",
      "The mask's new. The gun isn't.",
      "Everybody on the block has seen that gun on a scroller. Everybody."]));
  }
}

// How this district talks, whoever is talking (Data/Districts.reds, [6]).
func CBWhisperDistrict(bag: ref<CBLineBag>, st: ref<CBStreetRead>) -> Void {
  if !CBTempersOn() {
    return;
  }
  let lines: array<String>;
  switch CBDistrictIndex(st.district) {
    case 0:
      lines = ["Kabuki's going to be buzzing about this by tonight.", "In Watson you're old news by morning. Not that one, though.",
               "Somebody'll be selling the story at the market in an hour."];
      break;
    case 1:
      lines = ["Keep it down. This is Japantown, not Watson.", "Folks round here pay good money not to see things like that.",
               "Charter Hill doesn't need this kind of attention."];
      break;
    case 2:
      lines = ["Don't look. Corpo rule number one: you never saw a thing.", "Somebody call building security. Actually, don't.",
               "Not in front of the Arasaka tower. Have some class."];
      break;
    case 3:
      lines = ["My abuela warned me about people like that.", "In Heywood we remember faces. That one's hard to forget.",
               "The Valentinos hear everything that happens on this street. Everything."];
      break;
    case 4:
      lines = ["Working folks don't need this kind of trouble.", "Arroyo's seen worse. Not much worse.",
               "Keep walking. We've got shifts to get to."];
      break;
    case 5:
      lines = ["Pacifica's seen it all. Still, that one's new.", "Nobody calls the cops in Pacifica. Nobody comes.",
               "Voodoo Boys'll know about this before it's done happening."];
      break;
    case 6:
      lines = ["Barghest will know about this before you finish blinking.", "In Dogtown you don't stare. You survive.",
               "Hansen's people are always watching. Always."];
      break;
    case 7:
      lines = ["Long way from the city to run into that one.", "Out here you hear a name once and never forget it.",
               "Clans'll be talking about this round every fire tonight."];
      break;
    default:
      return;
  }
  bag.Add(n"district", 0.8, CBLineOf(lines));
}

// What anybody might say, the floor under everything else.
func CBWhisperGeneric(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  CBWhisperDistrict(bag, st);
  if Equals(mood, n"respect") {
    bag.Add(n"generic", 1.0, CBPick4(
      "Now that's a merc worth knowing. Preem.",
      "Solid. No mess, no noise.",
      "I'd take that one on a job any day.",
      "If you need something doing, that's who you call."));
    return;
  }
  if Equals(mood, n"hate") {
    bag.Add(n"generic", 1.0, CBPick4(
      "You've got some nerve showing your face around here.",
      "Look who crawled onto our street.",
      "Keep walking. You're not welcome and you know it.",
      "One day you'll be somewhere without an audience."));
    return;
  }
  bag.Add(n"generic", 1.0, CBPick4(
    "Don't stare, choom. Just keep walking.",
    "Eyes down. Keep moving.",
    "I'm not getting involved. Neither are you.",
    "Whatever that one wants, let them have it."));
}

// V's current title, if they have one worth naming.
func CBWhisperTitle(sys: ref<CyberbaneSystem>) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let id = sys.GetActiveTitle();
  if Equals(id, n"") {
    let unlocked = sys.GetUnlockedTitles();
    if ArraySize(unlocked) == 0 {
      return "";
    }
    id = unlocked[ArraySize(unlocked) - 1];
  }
  if Equals(id, n"") {
    return "";
  }
  return CBTitleDisplayById(sys, sys.GetContent(), id);
}

// The Whispers switch, for anything else that would put an overheard line on the screen (1.9.1).
public func CBWhispersOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().whispers;
}

public func CBShowWhisper(sys: ref<CyberbaneSystem>, game: GameInstance,
                          faction: CName, mood: CName, topic: CName) -> Void {
  // A whisper is something said near V, not something sent to V, so it is a line of subtitle
  // and never a text. 1.4.7's first pass sent these as texts from "Passerby" and "Ganger",
  // which in the real phone would have meant contacts nobody could have had a number for.
  CBOverheard(game, CBWhisperSpeaker(faction), CBWhisperLine(sys, game, faction, mood, topic));
}
