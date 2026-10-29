// Cyberbane - The grapevine (spec §8.5)
//
// Propagation you can actually hear. When a rumor about you reaches a district it had not
// touched before, someone who trades in information may get in touch about what they heard.
// A contact saying "heard about Northside" lands harder than a meter filling, and it is the
// audible surface for the mod's signature mechanic.
//
// It is also where the witness system shows its face. Word that came from people who saw you
// arrives with your name on it. Word about work nobody witnessed arrives as a question: the
// street knows something happened and cannot say who did it.
//
// Deliberately NOT the in-game phone. A real SMS is authored journal content:
// `JournalPhoneMessage` is abstract and cannot be constructed, there is no phone-notification
// blackboard, and `ChangeEntryState` only flips the state of entries the base game already
// ships. Faking one would mean shipping journal entries and driving the quest system - the
// exact surface this mod refuses to touch - and it would mean putting words in a real fixer's
// mouth, where a player could mistake flavour for an actual gig. So these arrive on the same
// on-screen channel the whispers already use, from contacts who are nobody in particular.
//
// Crash safety: no new engine API at all. CBShowMessage already guards the blackboard, and
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
  let seed = RandRange(0, 4);
  CBShowMessage(game, CBGrapevineSender(seed) + ": " + body, CBConfig.GrapevineDurationSeconds());
}

func CBGrapevineSender(seed: Int32) -> String {
  switch seed {
    case 0: return "Unknown number";
    case 1: return "A fixer";
    case 2: return "Ripperdoc";
    default: return "A broker";
  }
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
  if rt.HasSettings() && !rt.GetSettings().toasts {
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
  CBShowMessage(game, CBGrapevineSender(seed) + ": " + line, CBConfig.GrapevineDurationSeconds());
  if IsDefined(cd) {
    cd.lastGrapevineAt = now;
  }
}
