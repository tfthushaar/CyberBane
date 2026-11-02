// Cyberbane - The grapevine (spec §8.5)
//
// Propagation you can actually hear. When a rumor about you reaches a district it had not
// touched before, somebody who trades in information there gets in touch about what they heard.
// A contact saying "heard about Northside" lands harder than a meter filling, and it is the
// audible surface for the mod's signature mechanic.
//
// It is also where the witness system shows its face. Word that came from people who saw you
// arrives with your name on it. Word about work nobody witnessed arrives as a question: the
// street knows something happened and cannot say who did it.
//
// Since 1.4.7 these arrive as text messages rather than as a line across the middle of the
// screen, and from the broker who works the district the word reached rather than from a
// rotating anonymous handle. That is the point of a grapevine: the same person keeps calling
// you about their own part of town. See UI/PhoneMessages.reds for why this is Cyberbane's own
// presentation of a message rather than a real journal entry, and for why the senders are
// handles instead of the game's own fixers.
//
// Crash safety: no engine API beyond one guarded blackboard write inside the presenter, and
// this runs from the rumor slow tick, which is behind the world-state gate.

// Who is passing it on. Roles, never a named quest-giver: the player must never read one of
// these as a real fixer offering real work.
// Somebody gets in touch about a thing you did.
//
// A player asked for the phone to tell them when their standing changes. Real phone messages
// are not available to a script mod: JournalPhoneMessage is abstract and cannot be built, and
// the journal entry lookup that would let an existing thread be triggered does not exist on
// this patch either (both verified by probe, along with every other route suggested). What is
// available is this - a message that reads as coming from somebody rather than from a mod -
// and it is already how word of your reputation reaches you, so milestones now arrive the
// same way instead of as a system notice.
public func CBContactMessage(game: GameInstance, body: String) -> Void {
  // From whoever works the part of town V is standing in, when that is known. Word about your
  // reputation reaching you from the local broker reads as the city; the same word from a
  // rotating "Unknown number" reads as a feed.
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) && NotEquals(sys.GetCurrentDistrict(), n"") {
    CBPhoneFromDistrict(game, sys.GetCurrentDistrict(), body);
    return;
  }
  CBPhoneFromStreet(game, body);
}

// Word that carries your name, because people were there to put it there.
func CBGrapevineNamedLine(kind: CName, where: String, seed: Int32) -> String {
  if Equals(kind, n"BossKill") {
    return "Heard what you did to their boss. " + where + " is talking about it.";
  }
  if Equals(kind, n"Massacre") {
    return "Word out of " + where + " is you left a mess. People are repeating it.";
  }
  switch seed {
    case 0: return "Your name came up in " + where + " today. Thought you should know.";
    case 1: return "They are talking about you in " + where + ". Not quietly.";
    case 2: return "Heard about " + where + ". Word travels faster than you do.";
    default: return "Somebody in " + where + " knows your name now. Make of that what you will.";
  }
}

// Word with nobody's name on it, because nobody lived close enough to supply one.
func CBGrapevineAnonLine(where: String, seed: Int32) -> String {
  switch seed {
    case 0: return "Bodies turning up in " + where + " and nobody can say whose work it is.";
    case 1: return "Something is working " + where + ". No name on it. People are nervous.";
    case 2: return "Heard " + where + " has a problem nobody can describe. Know anything?";
    default: return "Whatever happened in " + where + ", no witnesses walked. Street is spooked.";
  }
}

// Called when a rumor reaches a district it had not touched before.
public func CBGrapevineOnReach(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRumor>,
                               districtId: CName, now: Float) -> Void {
  if !IsDefined(sys) || !IsDefined(r) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return;
  }
  // Rides the existing toast setting: anyone who turned Cyberbane's messages off gets none.
  if !CBMessagesOn() {
    return;
  }
  // Word has to be worth repeating before anyone bothers passing it along.
  if r.magnitude < CBConfig.GrapevineMinMagnitude() {
    return;
  }
  let cd = sys.GetCooldowns();
  if IsDefined(cd) && cd.lastGrapevineAt > 0.0
     && (now - cd.lastGrapevineAt) < CBConfig.GrapevineCooldownHours() * CBConfig.SecondsPerHour() {
    return;
  }
  if RandF() >= CBConfig.GrapevineChance() {
    return;
  }
  // CBDistrictLabel lives in Model/TitleNaming.reds and returns "" for an unknown id.
  let where = CBDistrictLabel(districtId);
  if Equals(where, "") {
    where = "out there";
  }
  let seed = Cast<Int32>(RandF() * 4.0);
  if seed > 3 {
    seed = 3;   // RandF() can return 1.0 on some runtimes; never index past the pool
  }
  let line = r.witnessed ? CBGrapevineNamedLine(r.kind, where, seed)
                         : CBGrapevineAnonLine(where, seed);
  // From the broker who works the district the word reached, not from the one where V happens
  // to be standing. The message is "your name came up here", so the person saying it should be
  // the person who heard it.
  CBPhoneFromDistrict(game, districtId, line);
  if IsDefined(cd) {
    cd.lastGrapevineAt = now;
  }
}

// ---- Arriving somewhere word has already reached --------------------------
//
// Asked for directly: "if we fast travel and land in a different region and the rumours have
// spread there, the fixers could mention that."
//
// It is the right half of the mechanic to make audible, because it is the half the player can
// verify. Propagation happening on a slow tick behind the scenes is invisible; walking off a
// fast-travel terminal into a district that already knows your name is the mechanic happening
// to you. The broker who works that district is the one who says so, and it is the same handle
// every time you come back.
//
// Called when the cached district changes, which the fast tick already tracks for the Director.
// Rides the same cooldown as the rest of the grapevine, so arriving somewhere does not jump the
// queue ahead of word that is still travelling.
public func CBGrapevineOnArrival(sys: ref<CyberbaneSystem>, game: GameInstance,
                                 districtId: CName, now: Float) -> Void {
  if !IsDefined(sys) || Equals(districtId, n"") {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return;
  }
  if !CBMessagesOn() {
    return;
  }
  let cd = sys.GetCooldowns();
  if IsDefined(cd) && cd.lastGrapevineAt > 0.0
     && (now - cd.lastGrapevineAt) < CBConfig.GrapevineCooldownHours() * CBConfig.SecondsPerHour() {
    return;
  }
  // Has anything about V actually reached here? The rumor's own reach mask is the honest
  // answer, so this cannot claim a district knows something it does not.
  let index = CBDistrictIndex(districtId);
  if index < 0 {
    return;
  }
  // Walked with GetRumorCount / GetRumorAt rather than GetRumors, which returns the array by
  // value: indexing that temporary hands back a handle into a copy destroyed at the end of the
  // statement. The note on the getter spells this out and it has cost a crash before.
  let loudest: ref<CBRumor>;
  let best = 0.0;
  let i = 0;
  while i < sys.GetRumorCount() {
    let r = sys.GetRumorAt(i);
    i += 1;
    if IsDefined(r) && CBMaskHas(r.reachedMask, index)
       && NotEquals(r.origin, districtId) && r.magnitude > best {
      loudest = r;
      best = r.magnitude;
    }
  }
  if !IsDefined(loudest) || best < CBConfig.GrapevineMinMagnitude() {
    return;
  }
  let from = CBDistrictLabel(loudest.origin);
  if Equals(from, "") {
    from = "across town";
  }
  CBPhoneFromDistrict(game, districtId, CBGrapevineArrivalLine(loudest, from,
                                                               RandRange(0, 4)));
  if IsDefined(cd) {
    cd.lastGrapevineAt = now;
  }
  CBLog.Info(n"Narrative", s"Arrival in \(NameToString(districtId)): local broker mentions word out of \(NameToString(loudest.origin)).");
}

// What the local broker says when you turn up somewhere your name got to first.
func CBGrapevineArrivalLine(r: ref<CBRumor>, from: String, seed: Int32) -> String {
  if !r.witnessed {
    switch seed {
      case 0: return "You are a long way from " + from + ". Whatever happened there followed you here anyway.";
      case 1: return "Word came in from " + from + " before you did. No name on it. Still made people careful.";
      case 2: return "Something out of " + from + " has people here talking. You would not know anything about it.";
      default: return "People here heard about " + from + ". Nobody can say who. Welcome to the neighbourhood.";
    }
  }
  if Equals(r.kind, n"BossKill") {
    return "They know about the boss you put down in " + from + ". That story got here before you.";
  }
  if Equals(r.kind, n"Massacre") {
    return "What you left in " + from + " is being repeated on this side of town. Word for word.";
  }
  switch seed {
    case 0: return "Your name is already in circulation here. Came up from " + from + ".";
    case 1: return "You are known on this side of town now. Word travelled out of " + from + ".";
    case 2: return "Heard about " + from + " before you ever walked in here. People notice.";
    default: return "They were talking about " + from + " here before you arrived. You should know that.";
  }
}
