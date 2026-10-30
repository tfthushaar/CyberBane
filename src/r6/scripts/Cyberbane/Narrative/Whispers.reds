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

// Who is talking. Not the same word every time, because "Ganger" six times running is its own
// kind of repetition.
public func CBWhisperSpeaker(faction: CName) -> String {
  if Equals(faction, n"NCPD") {
    return CBWhisperPick2("NCPD Officer", "Patrol Cop");
  }
  if Equals(faction, n"") {
    return CBWhisperPick3("Passerby", "Local", "Someone nearby");
  }
  return CBWhisperPick3("Ganger", "Lookout", "Crew member");
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
        "They put " + gang + "' boss in the ground " + where + ".",
        gang + " lost someone who mattered " + where + ".",
        "Heard " + gang + " are short a boss. " + where + ", they say.");
    }
    return "Somebody took a boss off the board " + where + ".";
  }
  if Equals(r.kind, n"Deed") {
    return CBWhisperPick3(
      "Something went down " + where + ". Street's still chewing on it.",
      "You hear about that job " + where + "?",
      "Everyone's talking about " + where + " right now.");
  }
  if StrLen(gang) > 0 {
    return CBWhisperPick3(
      gang + " are counting bodies " + where + ".",
      "Another one of " + gang + " down " + where + ".",
      "Not a good week to be " + gang + ".");
  }
  return "Word from " + where + " is somebody's been busy.";
}

// The line itself.
public func CBWhisperLine(sys: ref<CyberbaneSystem>, game: GameInstance,
                          faction: CName, mood: CName, topic: CName) -> String {
  let gang = CBFactionLabel(faction);
  if StrLen(gang) == 0 {
    gang = "that crew";
  }

  // Topic-specific lines take priority (spec §9.10 topic weighting).
  if Equals(topic, n"bossloss") {
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
    return CBWhisperPick4(
      "You've got a lot of nerve showing up here. Walk away while you still can.",
      "Wrong street, choom. Turn around.",
      gang + " want you gone. This is the only time we ask nicely.",
      "You're standing on our block. That's one mistake. Don't make two.");
  }

  // A story that actually reached here beats anything generic.
  let r = CBWhisperRumor(sys, game);
  if IsDefined(r) && RandF() < CBConfig.WhisperRumorChance() {
    return CBRumorPhrase(sys, r);
  }

  let title = CBWhisperTitle(sys);
  if Equals(mood, n"respect") {
    if StrLen(title) > 0 {
      return CBWhisperPick4(
        "Now that's a merc worth knowing. Preem.",
        "That's " + title + ". For real.",
        "They call that one " + title + ". Earned it, too.",
        "If you need something doing, that's who you call.");
    }
    return CBWhisperPick4(
      "Now that's a merc worth knowing. Preem.",
      "That one does clean work. Respect.",
      "Solid. No mess, no noise.",
      "I'd take that one on a job any day.");
  }
  if Equals(mood, n"hate") {
    return CBWhisperPick4(
      "You've got some nerve showing your face around here.",
      "Look who crawled onto our street.",
      "Keep walking. You're not welcome and you know it.",
      "One day you'll be somewhere without an audience.");
  }
  // fear (default)
  if StrLen(title) > 0 {
    return CBWhisperPick4(
      "Don't stare, choom. Just keep walking.",
      "That's " + title + ". Eyes down.",
      "Don't. Whatever you're thinking, don't.",
      "I'm not getting involved. Neither are you.");
  }
  return CBWhisperPick4(
    "Don't stare, choom. Just keep walking.",
    "Eyes down. Keep moving.",
    "I'm not getting involved. Neither are you.",
    "Whatever that one wants, let them have it.");
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

public func CBShowWhisper(sys: ref<CyberbaneSystem>, game: GameInstance,
                          faction: CName, mood: CName, topic: CName) -> Void {
  CBShowMessage(game, CBWhisperSpeaker(faction) + ": " + CBWhisperLine(sys, game, faction, mood, topic),
                CBConfig.WhisperDurationSeconds());
}
