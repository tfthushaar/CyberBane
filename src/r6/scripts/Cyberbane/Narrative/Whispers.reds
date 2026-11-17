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
    return CBWhisperPick3("Passer-by", "Local", "Someone nearby");
  }
  let member = CBFactionMemberWord(faction);
  return StrLen(member) > 0 ? member : CBWhisperPick3("Ganger", "Lookout", "Crew member");
}

// One of theirs, the way the street would say it.
public func CBFactionMemberWord(faction: CName) -> String {
  if Equals(faction, n"NCPD") { return CBWhisperPick2("NCPD Officer", "Patrol Cop"); }
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
    return CBWhisperPick3(
      "Heard they found a room full of bodies " + where + ".",
      "Whole crew went quiet " + where + ". Nobody's saying who.",
      "Word " + where + " is somebody cleared a building on their own.");
  }
  if Equals(r.kind, n"BossKill") {
    if StrLen(gang) > 0 {
      return CBWhisperPick3(
        "They put a boss of " + gang + " in the ground " + where + ".",
        CBCapFirst(gang) + " lost someone who mattered " + where + ".",
        "Heard " + gang + " are short a boss " + where + ".");
    }
    return "Somebody took a boss off the board " + where + ".";
  }
  if Equals(r.kind, n"Deed") {
    return CBWhisperPick3(
      "Something went down " + where + ". Street's still chewing on it.",
      "You hear about that job " + where + "?",
      "Everyone's talking about what happened " + where + ".");
  }
  if StrLen(gang) > 0 {
    return CBWhisperPick3(
      CBCapFirst(gang) + " are counting bodies " + where + ".",
      "Another one of " + gang + " down " + where + ".",
      "Not a good week to be " + gang + ".");
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

// The lines on offer for one whisper, each with what it is about and how much it is worth saying.
public class CBLineBag {
  public let lines: array<String>;
  public let topics: array<CName>;
  public let weights: array<Float>;

  public func Add(topic: CName, weight: Float, line: String) -> Void {
    if weight <= 0.0 || StrLen(line) == 0 {
      return;
    }
    ArrayPush(this.lines, line);
    ArrayPush(this.topics, topic);
    ArrayPush(this.weights, weight);
  }

  public func Size() -> Int32 {
    return ArraySize(this.lines);
  }

  // A weighted draw, leaving out whatever the last line was about while anything else is on offer.
  public func Pick(lastTopic: CName) -> Int32 {
    let total = 0.0;
    let others = 0;
    let i = 0;
    while i < ArraySize(this.lines) {
      if NotEquals(this.topics[i], lastTopic) {
        total += this.weights[i];
        others += 1;
      }
      i += 1;
    }
    let skipLast = others > 0;
    if !skipLast {
      total = 0.0;
      for w in this.weights {
        total += w;
      }
    }
    if total <= 0.0 {
      return -1;
    }
    let roll = RandRangeF(0.0, total);
    i = 0;
    while i < ArraySize(this.lines) {
      if !skipLast || NotEquals(this.topics[i], lastTopic) {
        roll -= this.weights[i];
        if roll <= 0.0 {
          return i;
        }
      }
      i += 1;
    }
    return ArraySize(this.lines) - 1;
  }
}

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
      return CBWhisperPick4(
        "You put down one of our bosses. " + st.leader + " runs things now, and remembers.",
        "We know what you did to ours. " + st.leader + " has your name on a list.",
        "That was a boss of " + gang + " you killed. Someone's getting paid for you.",
        "Every one of us knows your face now. Think about that.");
    }
    return CBWhisperPick4(
      "You put down one of our bosses. The crew doesn't forget that.",
      "We know what you did to ours. We're not done.",
      "That was a boss of " + gang + " you killed. Someone's getting paid for you.",
      "Every one of us knows your face now. Think about that.");
  }
  if Equals(topic, n"maxtac") {
    return CBWhisperPick4(
      "That's the merc who went up against MaxTac and walked away.",
      "MaxTac came for that one. MaxTac went home light.",
      "I've seen the footage. They took on MaxTac and they're still breathing.",
      "You don't survive MaxTac. That one did.");
  }
  if Equals(topic, n"warning") {
    if st.kills >= 20 {
      return CBWhisperPick3(
        "You've put enough of us in the ground. Walk away, or you're next.",
        CBCapFirst(gang) + " remember every one. Turn around.",
        "Last warning. After this it's not talking.");
    }
    return CBWhisperPick4(
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
  // A story that actually reached here.
  let r = CBWhisperRumor(sys, game);
  if IsDefined(r) {
    bag.Add(n"rumor", 3.0 * CBConfig.WhisperRumorChance() / 0.6, CBRumorPhrase(sys, r));
  }
  if st.masked {
    // Behind a mask V is nobody: there is no V to talk about, only somebody nobody can place.
    mood = n"fear";
    CBWhisperMasked(bag, mood);
  } else {
    CBWhisperNow(bag, st, mood);
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
      bag.Add(n"now", 3.0, CBWhisperPick3(
        "Busy night for that one. Better them than us.",
        "Still got the fight on them. Give them room.",
        "Whatever just happened, I'm glad it wasn't me."));
    } else {
      bag.Add(n"now", 3.0, CBWhisperPick4(
        "Blood's still fresh on that one. Don't look.",
        "They just did something. You can see it on them.",
        "Walk. Don't run, just walk.",
        "Somebody's not going home tonight, and that's who did it."));
    }
  }
  if st.heat >= 2 {
    bag.Add(n"heat", 1.5, CBWhisperPick3(
      "NCPD's all over the net looking for that one.",
      "Cops want that face. I'm not standing next to it.",
      "Every patrol in the district's got that one's description."));
  }
  if st.layingLow && st.renown >= 30.0 {
    bag.Add(n"quiet", 1.5, CBWhisperPick3(
      "Haven't heard that one's name in days. Gone quiet.",
      "Thought they'd skipped town. Guess not.",
      "Quiet lately. That's when you worry."));
  }
}

// Who V is: the name the street gave them, the way they work, how famous they are.
func CBWhisperIdentity(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if StrLen(st.title) > 0 {
    if Equals(mood, n"respect") {
      bag.Add(n"title", 2.0, CBWhisperPick3(
        "That's " + st.title + ". For real.",
        "They call that one " + st.title + ". Earned it, too.",
        st.title + ", right there. Don't make a thing of it."));
    } else {
      if Equals(mood, n"hate") {
        bag.Add(n"title", 2.0, CBWhisperPick2(
          st.title + ". Big name. Bleeds like anybody.",
          "They call that one " + st.title + ". We call them a target."));
      } else {
        bag.Add(n"title", 2.0, CBWhisperPick3(
          "That's " + st.title + ". Eyes down.",
          "Don't. That's " + st.title + ".",
          "You know who that is? " + st.title + ". Keep walking."));
      }
    }
  }
  let a = st.archetype;
  if a == EnumInt(ECBArchetype.Butcher) {
    bag.Add(n"style", 2.0, CBWhisperPick3(
      "Heard what that one leaves behind. They hose the place down after.",
      "That's the one who doesn't stop when it's over.",
      "Don't end up in a room with that one. Nobody comes out in one piece."));
  } else {
    if a == EnumInt(ECBArchetype.Ghost) {
      bag.Add(n"style", 2.0, CBWhisperPick3(
        "Bodies turn up and nobody saw a thing. That's them.",
        "You don't see that one coming. That's the whole point.",
        "Half the jobs on the net they never got pinned for."));
    } else {
      if a == EnumInt(ECBArchetype.Professional) {
        bag.Add(n"style", 2.0, CBWhisperPick3(
          "That one does clean work. In, out, nobody hurt who didn't have to be.",
          "Fixers love that one. Job done, no mess.",
          "A real pro. Rare these days."));
      } else {
        if a == EnumInt(ECBArchetype.Chromed) {
          bag.Add(n"style", 2.0, CBWhisperPick3(
            "More chrome than meat on that one.",
            "How much of them is even left under all that?",
            "Ripperdocs must love that one."));
        } else {
          if a == EnumInt(ECBArchetype.Netrunner) {
            bag.Add(n"style", 2.0, CBWhisperPick3(
              "Netrunner. Fries you from across the street. Keep your ICE up.",
              "That one cooks brains for a living.",
              "Don't jack in near that one. Seriously."));
          } else {
            if a == EnumInt(ECBArchetype.Brawler) {
              bag.Add(n"style", 2.0, CBWhisperPick3(
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
    bag.Add(n"fame", 1.5, CBWhisperPick3(
      "Wait. Is that really them? On our street?",
      "Everybody in the city knows that face.",
      "I'm telling everyone I saw them. Nobody's going to believe me."));
  } else {
    if st.renown < 15.0 && st.dread >= 40.0 {
      bag.Add(n"fame", 1.5, CBWhisperPick2(
        "Nobody knows who that is. That's worse.",
        "No name, no face on the net, and people are scared anyway."));
    }
  }
}

// How V treats people: the mercy, or the lack of it.
func CBWhisperConduct(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.code <= -40.0 {
    bag.Add(n"conduct", 2.5, CBWhisperPick4(
      "That one's a bad day away from cyberpsycho.",
      "Heard they shoot whoever's in the way. Civvies too.",
      "Somebody should call MaxTac before it's too late.",
      "Look at the eyes. Nobody's home."));
    return;
  }
  if st.code >= 40.0 || (st.mercies >= 10 && st.code > 0.0) {
    if Equals(mood, n"hate") {
      bag.Add(n"conduct", 2.0, CBWhisperPick2(
        "Leaves people breathing. Thinks that makes them a saint.",
        "Soft. Puts people to sleep instead of finishing it."));
    } else {
      bag.Add(n"conduct", 2.5, CBWhisperPick4(
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
    bag.Add(n"chrome", 2.0, CBWhisperPick4(
      "Look at those arms. Military grade, easy.",
      "All that chrome out in the open. Nobody's going to try them.",
      "Don't stare at the chrome. They notice.",
      "That's not a body. That's a weapon with legs."));
    return;
  }
  if st.chromeInstalled >= 60.0 && st.armsCovered {
    bag.Add(n"chrome", 1.0, CBWhisperPick2(
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
    bag.Add(n"place", 1.5, CBWhisperPick3(
      "Everybody in " + st.districtLabel + " knows that face.",
      "That one practically runs " + st.districtLabel + " now.",
      "Ask anyone in " + st.districtLabel + ". They'll tell you about that one."));
  } else {
    if st.districtRenown < 10.0 && st.renown >= 40.0 {
      bag.Add(n"place", 1.5, CBWhisperPick2(
        "Not from " + st.districtLabel + ". Heard the name, though.",
        "What's that one doing in " + st.districtLabel + "?"));
    }
  }
  // A district whose gang V has bled dry, from somebody who lives there.
  if Equals(st.faction, n"") && NotEquals(st.turfHolder, n"") {
    let sys = CyberbaneSystem.Get(GetGameInstance());
    if IsDefined(sys) && CBGangBroken(sys, st.turfHolder) {
      let holder = CBFactionLabel(st.turfHolder);
      if StrLen(holder) > 0 {
        bag.Add(n"turf", 2.0, CBWhisperPick2(
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
  if StrLen(st.hunter) > 0 && !Equals(st.posture, ECBPosture.Allied) && !Equals(st.posture, ECBPosture.Friendly) {
    bag.Add(n"hunter", 3.0, CBWhisperPick3(
      st.hunter + "'s coming for you. Everybody on the block knows it.",
      "Enjoy the walk. " + st.hunter + " has plans for you.",
      "When " + st.hunter + " finds you, I want a good seat."));
  }
  if Equals(st.posture, ECBPosture.Allied) {
    bag.Add(n"gang", 2.5, CBWhisperPick3(
      "That's a friend of " + gang + ". You hear me? A friend.",
      "Treat that one like family. Boss's orders.",
      "One of ours, near enough. Anybody starts something, we finish it."));
  } else {
    if Equals(st.posture, ECBPosture.Friendly) {
      bag.Add(n"gang", 2.0, CBWhisperPick3(
        "That one's all right by " + gang + ".",
        "Good with the crew, that one. Leave it.",
        "Heard they've been doing us favours. Nod, don't stare."));
    } else {
      if Equals(st.posture, ECBPosture.Hostile) || Equals(st.posture, ECBPosture.Vendetta) {
        if st.kills >= 20 {
          bag.Add(n"blood", 2.5, CBWhisperPick3(
            "That one's put more of " + gang + " in the ground than the cops ever did.",
            "Every funeral this month, that one's the reason.",
            "You know how many of ours? Too many."));
        } else {
          bag.Add(n"blood", 2.0, CBWhisperPick2(
            "We know your face. All of us.",
            "Keep walking. You're on " + CBPossessive(gang) + " streets."));
        }
        if StrLen(st.leader) > 0 {
          bag.Add(n"leader", 1.5, CBWhisperPick2(
            st.leader + " runs this crew now. Wants a word with you.",
            "When " + st.leader + " hears you came by, it's on."));
        }
      } else {
        if st.fear >= 60.0 {
          bag.Add(n"fear", 2.0, CBWhisperPick3(
            "Don't look at them. Just don't.",
            "Nobody starts anything. Not with that one.",
            "If they want the corner, they can have it."));
        }
      }
    }
  }
  if st.spared >= 3 && !Equals(st.posture, ECBPosture.Vendetta) {
    bag.Add(n"mercy", 2.0, CBWhisperPick2(
      "That one let some of ours walk. People remember that.",
      "Could've finished my brother. Didn't. I don't forget."));
  }
  if st.tributes > 0 {
    bag.Add(n"tribute", 1.5, CBWhisperPick2(
      "Boss pays that one to stay off our backs. Don't make it worse.",
      "We send them eddies so they leave us alone. Think about that."));
  }
}

// A gang V has broken, afraid out loud.
func CBWhisperBroken(bag: ref<CBLineBag>, st: ref<CBStreetRead>, gang: String) -> Void {
  bag.Add(n"broken", 4.0, CBWhisperPick4(
    "Don't. We're done, alright? We're done.",
    "There's hardly any of us left. Just let us be.",
    "Whatever the bosses said, I'm not dying for it.",
    "That's the one who broke " + gang + ". Nobody move."));
}

// Somebody nobody can put a name to.
func CBWhisperMasked(bag: ref<CBLineBag>, mood: CName) -> Void {
  bag.Add(n"mask", 3.0, CBWhisperPick4(
    "Who's under the mask? Never mind. I don't want to know.",
    "Can't see a face. Don't need to.",
    "Masked up in the middle of the day. That's never good.",
    "Somebody who doesn't want to be known. Fine by me."));
}

// What anybody might say, the floor under everything else.
func CBWhisperGeneric(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if Equals(mood, n"respect") {
    bag.Add(n"generic", 1.0, CBWhisperPick4(
      "Now that's a merc worth knowing. Preem.",
      "Solid. No mess, no noise.",
      "I'd take that one on a job any day.",
      "If you need something doing, that's who you call."));
    return;
  }
  if Equals(mood, n"hate") {
    bag.Add(n"generic", 1.0, CBWhisperPick4(
      "You've got some nerve showing your face around here.",
      "Look who crawled onto our street.",
      "Keep walking. You're not welcome and you know it.",
      "One day you'll be somewhere without an audience."));
    return;
  }
  bag.Add(n"generic", 1.0, CBWhisperPick4(
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

// ---- Picking, without saying the same thing twice in a row -----------------
//
// The index of the last line used is kept for the session, and a roll that lands on it is
// nudged along by one. That is the whole trick: it costs nothing and it removes the thing
// players actually notice, which is the immediate repeat.
func CBWhisperIndex(count: Int32) -> Int32 {
  if count <= 1 {
    return 0;
  }
  let idx = RandRange(0, count);
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    if idx == rt.GetLastWhisperIndex() {
      idx = (idx + 1) % count;
    }
    rt.SetLastWhisperIndex(idx);
  }
  return idx;
}

func CBWhisperPick2(a: String, b: String) -> String {
  return CBWhisperIndex(2) == 0 ? a : b;
}

func CBWhisperPick3(a: String, b: String, c: String) -> String {
  let i = CBWhisperIndex(3);
  if i == 0 { return a; }
  if i == 1 { return b; }
  return c;
}

func CBWhisperPick4(a: String, b: String, c: String, d: String) -> String {
  let i = CBWhisperIndex(4);
  if i == 0 { return a; }
  if i == 1 { return b; }
  if i == 2 { return c; }
  return d;
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
