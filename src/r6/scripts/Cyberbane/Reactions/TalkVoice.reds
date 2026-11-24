// Cyberbane - Voices in a conversation (2.7.8)
//
// "We can't make the voice for our dialogues, but can we at least fire a similar dialogue voice from the game when we are
// having a conversation with anyone? Where there's a perfect voice and subtitle combo, use the game's; for the ones that
// are Cyberbane's alone, a similar voice under our subtitles; if none fits an option, let it be."
//
// What the game has to say. Every person in the world carries a voiceset: a scene of the game's of short lines in their
// own voice and words, each under a name the game calls by (greeting, bump, fear_beg, ...) with two or three recordings
// (greeting, greeting_var_1, greeting_var_2). Read from the game's own files for every voiceset it has, 551 of them, and
// joined to their subtitles by script: all of them greet, flinch at a bump, beg, panic and take a call; 98, the gangs'
// and the guards', also warn V off (rep_ask_to_leave, rep_ask_to_holster, rep_final_warning) and say so when V backs down
// (rep_complies); 110 answer the game's own talk (return_answer). The words differ from voice to voice; what each name
// is for does not, and it is by that the answers below are matched (CBTalkVoiceFor).
//
// Two ways an answer is voiced:
//   - Theirs: a line of the game's is the whole answer, as well as or better than Cyberbane's words would be (somebody
//     begging V to stop, a ganger telling V to back off). Their words go in the answer's subtitle, and Cyberbane's own are
//     kept to stand in if their voiceset has nothing under that name, or the game will not say it now.
//   - Under: the answer carries what only Cyberbane knows (a name, a place, a price), so its words stay, and a line of
//     theirs in the same spirit is heard under them. The game would print that line's own words over their head as well;
//     they are kept off it while the answer is up, so the screen says one thing.
// One recording of the name for each answer, the same one every time that answer is given and a different one from the
// last, so a conversation does not repeat itself.
//
// V speaks too, from V's own voiceset (below, CBTalkVoiceForV). V's lines in the story are played by the story's scenes
// and nothing a script does reaches them; the voiceset is the game's other source of V's voice, and its lines are called
// by name like anybody's. Another mod ships the story's lines as sound files for an audio plugin; this needs neither.
//
// A crowd person's lines are switched off while V talks to them (CBTalkHush, so their idle chatter and greetings do not
// talk over the conversation): they are let through for the one line and switched off again a moment later. Everybody
// else's own voice calls are held back for the conversation (StreetTalk.reds, the PlayVoiceOver wrap); these go through
// on Cyberbane's own context. Under "Voices for the moments", with the rest of Cyberbane's voices.

public func CBTalkVoiceUnder() -> Int32 = 1
public func CBTalkVoiceTheirs() -> Int32 = 2

// The answer being voiced, one conversation at a time (on the runtime).
public class CBTalkVoiceNow {
  public let who: EntityID;
  public let until: Float;     // sim seconds: a line of theirs before then is this answer's
  public let theirs: Bool;     // their words are the answer
  public let fallback: String; // Cyberbane's words, if theirs never come
  public let speaker: String;
  public let dueAt: Float;     // when to stop waiting for theirs
  public let heard: String;    // their words, as the subtitles saw them
  public let done: Bool;       // the answer's subtitle is up
  public let last: CName;      // the recording said last, so the next answer says another
  public let vUntil: Float;    // sim seconds: a line of V's own voiceset before then is the option V chose
}

public func CBTalkVoiceState() -> ref<CBTalkVoiceNow> {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) ? rt.GetTalkVoice() : null;
}

// One recording of a name: the name itself, or its _var_1 or _var_2, picked by the answer's words so the same answer always
// sounds the same, and never the one said just before.
func CBTalkVoiceRecording(entry: CName, words: String, last: CName) -> CName {
  // The words' CRC, through the same hash TweakDB names its records with.
  let h = Cast<Int32>(TDBID.ToNumber(TDBID.Create(words)) % 3ul);
  let pick = 0;
  while pick < 3 {
    let name = h == 0 ? entry : StringToName(NameToString(entry) + "_var_" + IntToString(h));
    if NotEquals(name, last) {
      return name;
    }
    h = (h + 1) % 3;
    pick += 1;
  }
  return entry;
}

// Lets a crowd person's voiceset lines through for one line, and switches them off again a moment later.
public class CBTalkVoiceReHush extends DelayCallback {
  public let npc: wref<ScriptedPuppet>;
  public func Call() -> Void {
    let p = this.npc;
    if IsDefined(p) && p.IsAttached() && p.cbTalkPartner && p.cbTalkHushedLines {
      let quiet = new entChangeVoicesetStateEvent();
      quiet.enableVoicesetLines = false;
      quiet.enableVoicesetGrunts = true;
      p.QueueEvent(quiet);
    }
  }
}

// Says it in their voice: `entry` the name of one of their voiceset's lines, `mode` Theirs or Under, `ours` the answer's own
// words. True when it was asked of the game; with Theirs, the answer's subtitle then waits for their words (CBTalkVoiceTick).
public func CBTalkVoiceSay(sys: ref<CyberbaneSystem>, game: GameInstance, npc: ref<ScriptedPuppet>, entry: CName, mode: Int32,
                           ours: String, speaker: String) -> Bool {
  let v = CBTalkVoiceState();
  if !IsDefined(v) || !CBVoicesOn() || !IsNameValid(entry) || mode <= 0 || !CBNpcSafe(sys, npc) || npc.IsDead()
     || !npc.IsAttached() || CBPlayerInScene(game) || CBStoryHoldNow(game) {
    return false;
  }
  let said = CBTalkVoiceRecording(entry, ours, v.last);
  if npc.cbTalkHushedLines {
    let open = new entChangeVoicesetStateEvent();
    open.enableVoicesetLines = true;
    open.enableVoicesetGrunts = true;
    npc.QueueEvent(open);
    let ds = GameInstance.GetDelaySystem(game);
    if IsDefined(ds) {
      let back = new CBTalkVoiceReHush();
      back.npc = npc;
      ds.DelayCallback(back, CBConfig.TalkVoiceLinesOpen(), false);
    }
  }
  let now = CBSoundNow(game);
  v.who = npc.GetEntityID();
  v.until = now + CBConfig.TalkVoiceWindow();
  v.theirs = mode == CBTalkVoiceTheirs();
  v.fallback = ours;
  v.speaker = speaker;
  v.dueAt = now + CBConfig.TalkVoiceWait();
  v.heard = "";
  v.done = !v.theirs;
  v.last = said;
  CBTrace("voice: one of their own voiceset lines under a conversation's answer");
  GameObject.PlayVoiceOver(npc, said, n"Scripts:CBStreetTalk");
  return true;
}

// A new session (CyberbaneSystem.StartSession): nothing of a voice from before is taken as an answer here. Not when a
// conversation ends, which is often the very answer still waiting for its words.
public func CBTalkVoiceClear() -> Void {
  let v = CBTalkVoiceState();
  if IsDefined(v) {
    let none: EntityID;
    v.who = none;
    v.until = 0.0;
    v.theirs = false;
    v.fallback = "";
    v.heard = "";
    v.done = true;
    v.last = n"";
    v.vUntil = 0.0;
  }
}

// On talk's tick: an answer waiting for their words gets them, or Cyberbane's own once it has waited long enough. Returns the
// words to put up and how long for, "" when there is nothing to put up now.
public func CBTalkVoiceTick(game: GameInstance) -> String {
  let v = CBTalkVoiceState();
  if !IsDefined(v) || v.done || !v.theirs {
    return "";
  }
  if StrLen(v.heard) > 0 {
    v.done = true;
    return v.heard;
  }
  if CBSoundNow(game) >= v.dueAt {
    v.done = true;
    return v.fallback;
  }
  return "";
}

// The subtitles' side (the wraps below): is this line one of the answer's, from the person V is talking to, while it is up?
// Their words are kept for the answer when they are the answer; the line itself is never drawn over their head.
public func CBTalkVoiceTakes(line: scnDialogLineData) -> Bool {
  let v = CBTalkVoiceState();
  if !IsDefined(v) || !IsDefined(line.speaker) {
    return false;
  }
  // V's line: Cyberbane's own subtitle already says it, word for word or in Cyberbane's words; the game's copy stays off.
  // Never a line of the story's: nothing is kept off once a scene or the story has V, and the window is the line's length.
  if line.speaker.IsPlayer() {
    let pgame = line.speaker.GetGame();
    return !CBTalkVoiceOwnLine(line.id) && CBSoundNow(pgame) <= v.vUntil && !CBPlayerInScene(pgame) && !CBStoryHoldNow(pgame);
  }
  if !EntityID.IsDefined(v.who) || NotEquals(line.speaker.GetEntityID(), v.who) {
    return false;
  }
  let game = line.speaker.GetGame();
  if CBSoundNow(game) > v.until {
    return false;
  }
  if v.theirs && !v.done && StrLen(v.heard) == 0 {
    let shown = scnDialogLineData.GetDisplayText(line);
    let words = StrLen(shown.translation) > 0 ? shown.preTranslatedText + shown.translation + shown.postTranslatedText : shown.text;
    // Markup the game draws itself (a Kiroshi gloss, a word in their own tongue) is no good written out: Cyberbane's words then.
    v.heard = StrLen(words) > 0 && !StrContains(words, "<") ? words : v.fallback;
  }
  return true;
}

// ---- V --------------------------------------------------------------------------------------------------------
//
// "Every dialogue Cyberbane has: if it has a similar voiced counterpart, use that; if not, the old subtitles alone." V's
// options are V's own recorded words wherever V has recorded something in their spirit, and V says them, from one of two
// places:
//   - V's voiceset (vset_delamain, 171 lines in both of V's voices): the lines the game gives V outside the story's scenes
//     ("Get lost." to somebody in the way, "Hangin' in there?" to a hurt ally, a battle cry), each under its own name, so
//     the words are known before it plays. The game plays them itself (PlayVoiceOver), nothing else needed.
//   - V's lines from the story: 13,675 recordings, played by the story's scenes and by nothing a script can reach. The 28
//     that say what an option says, in its mood, ship with Cyberbane as sound files for AudioXL (red4ext/plugins/AudioXL/
//     sounds/Cyberbane, both of V's voices), which makes each one a sound the game's own audio system plays by name. Only
//     with AudioXL installed: without it those options are said in silence, as every option was before 2.7.8.
// The option's words are the recording's (English.reds), so V's subtitle is what V says. An option nothing of V's says
// keeps Cyberbane's words and is said in silence: anything with a name or a price in it, or a meaning only Cyberbane has.
// Matched by the words the option shows against the words of the key it was made from, so a translation matches as well.

public class CBTalkVoiceV {
  public let entry: CName;   // a line of V's voiceset
  public let file: String;   // or one of V's recordings shipped for AudioXL, its name without the voice ("_f", "_m")
  public let secs: Float;    // how long it runs, in the longer of V's two voices
}

func CBTalkVoiceVSet(entry: CName, secs: Float) -> ref<CBTalkVoiceV> {
  let v = new CBTalkVoiceV();
  v.entry = entry;
  v.secs = secs;
  return v;
}

func CBTalkVoiceVFile(file: String, secs: Float) -> ref<CBTalkVoiceV> {
  let v = new CBTalkVoiceV();
  v.file = "cyberbane_v_" + file;
  v.secs = secs;
  return v;
}

// Does this option say the words of this key? The tag in brackets is not said, nor the slot in front of the words that
// takes a tag ("{0}" for [Body] or [Intimidate]).
func CBTalkVoiceIs(words: String, key: CName) -> Bool {
  let said = CBT(key);
  if StrBeginsWith(said, "{0}") {
    said = StrMid(said, 3);
  }
  return Equals(words, CBTalkWords(said));
}

// What V says for this option, null when V says nothing. Lengths from the game's own voice-over length map (voiceset) or
// the recordings themselves (the story's), the longer of the two voices.
public func CBTalkVoiceForV(line: ref<CBTalkLine>) -> ref<CBTalkVoiceV> {
  if !IsDefined(line) {
    return null;
  }
  let w = CBTalkWords(line.text);
  // V's voiceset.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-GreetHeyThere") { return CBTalkVoiceVSet(n"scene_holocall_start_var_1", 1.4); }   // Hey, what's up?
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-GreetHeyChoom") { return CBTalkVoiceVSet(n"scene_holocall_start_var_2", 1.1); }   // Hello.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-DismissCatchYouLater") { return CBTalkVoiceVSet(n"interrupt_var_8", 1.7); }       // Nice talkin' to ya.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-DismissGetLost") { return CBTalkVoiceVSet(n"scene_insult_var_3", 1.6); }          // Get lost.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-DismissOutOfMyWay") { return CBTalkVoiceVSet(n"scene_crowd_var_1", 1.5); }        // Outta the way.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-DismissNotNow") { return CBTalkVoiceVSet(n"interrupt_var_9", 1.8); }              // Got somewhere else to be.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-LeaveTakeItEasy") { return CBTalkVoiceVSet(n"scene_holocall_end_var_2", 1.3); }   // Take care.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-AntagonizeWhatAreYouLookingAt") { return CBTalkVoiceVSet(n"scene_insult_var_5", 1.7); }   // Eh, fuck you.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-AntagonizeGotAProblem") { return CBTalkVoiceVSet(n"scene_insult_var_4", 1.7); }   // Fuckin' gonked?
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-AntagonizeYourCrewSAJoke") { return CBTalkVoiceVSet(n"scene_insult_var_2", 1.9); }   // Kiss my ass.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-AntagonizeYourBossKnowYouRe") { return CBTalkVoiceVSet(n"scene_insult_var_1", 2.0); }   // Fuck off.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-WalkAwayNow") { return CBTalkVoiceVSet(n"battlecry_curse_var_4", 2.6); }          // Wanna play rough? Gonna get rough.
  if CBTalkVoiceIs(w, n"Cyberbane-RivalLife-SpareWalkAwayNextTimeI") { return CBTalkVoiceVSet(n"follower_end_var_3", 3.3); }   // Worked out this time...
  if CBTalkVoiceIs(w, n"Cyberbane-RivalMoments-StareThemDownLookAtMe") { return CBTalkVoiceVSet(n"battlecry_curse_var_3", 1.9); }   // Gonna regret this.
  if CBTalkVoiceIs(w, n"Cyberbane-RivalMoments-DrawLetSGo") || CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-WantToEndUpLikeThe") {
    return CBTalkVoiceVSet(n"battlecry_curse_var_6", 2.2);                                                                     // Any last words?
  }
  if CBTalkVoiceIs(w, n"Cyberbane-RivalMoments-WalkAwayNotToday") { return CBTalkVoiceVSet(n"interrupt_var_4", 1.5); }         // Gotta get goin'.
  if CBTalkVoiceIs(w, n"Cyberbane-Allies-DrawTalkSOver") { return CBTalkVoiceVSet(n"battlecry_curse_var_1", 2.7); }            // I'ma fucking destroy you.
  if CBTalkVoiceIs(w, n"Cyberbane-Allies-QuitTheGangIMOut") { return CBTalkVoiceVSet(n"interrupt_var_1", 1.6); }               // Right, I'm out.
  if CBTalkVoiceIs(w, n"Cyberbane-CrewHome-AskHowAreYouHoldingUp") { return CBTalkVoiceVSet(n"combat_ally_check_var_2", 1.7); }   // Hangin' in there?
  if CBTalkVoiceIs(w, n"Cyberbane-CrewHome-DismissBackToIt") { return CBTalkVoiceVSet(n"interrupt_var_2", 1.7); }              // We'll talk later.
  // V's lines from the story, through AudioXL.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-GreetGoodToSeeYouHow") { return CBTalkVoiceVFile("greet_how", 1.4); }             // How's it goin'?
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-GreetEasyIMJustSaying") { return CBTalkVoiceVFile("greet_calm", 2.6); }           // Hey, hey... Calm down...
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-CoolEasyNobodyNeedsToBleed") { return CBTalkVoiceVFile("cool_talk", 2.8); }       // Calm down. Let's just talk.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-ParleyEasyIMNotHere") { return CBTalkVoiceVFile("parley_talk", 3.5); }            // Calm the fuck down! I just wanna talk!
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-GreetRelaxNotHereForTrouble") { return CBTalkVoiceVFile("greet_notrouble", 2.1); }   // Look, I don't want any trouble.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-AskGotAMinute") { return CBTalkVoiceVFile("ask_talk", 1.6); }                     // Can we talk?
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-AskWhatSTheWordOn") { return CBTalkVoiceVFile("ask_streets", 2.3); }              // How're things in the streets?
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-AskNeedAnythingDone") { return CBTalkVoiceVFile("ask_hand", 1.3); }               // Need a hand?
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-DealLetSTalkBusiness") { return CBTalkVoiceVFile("deal_offer", 2.8); }            // All right, what're you offerin'?
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-LeaveNotWorthIt") { return CBTalkVoiceVFile("leave_whatever", 2.1); }             // Whatever. I'm out.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-LeaveForgetIt") { return CBTalkVoiceVFile("leave_nevermind", 3.0); }              // You know what? Never mind...
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-BackSomethingElse") { return CBTalkVoiceVFile("back_else", 2.3); }                // Let's talk about something else.
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-ForgetItNeverMind") { return CBTalkVoiceVFile("forget_nevermind", 1.4); }         // Never mind.
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-HaggleThatSTooMuch") { return CBTalkVoiceVFile("haggle", 3.0); }                  // No. Askin' too much.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetPay-PayEbKeepAnEyeOut") { return CBTalkVoiceVFile("pay_lookout", 2.2); }               // Just keep a lookout.
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-OrYouCouldJustTellMe") { return CBTalkVoiceVFile("lean_talk", 1.7); }             // Start talkin'.
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-PayEb") { return CBTalkVoiceVFile("pay_here", 1.3); }                             // Here you go.
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-PayWhatDoesItCostTo") { return CBTalkVoiceVFile("toll_howmuch", 1.5); }           // How much?
  if CBTalkVoiceIs(w, n"Cyberbane-TalkTopics-StreetKidCameUpOnThese") { return CBTalkVoiceVFile("life_streetkid", 3.7); }      // Grew up in Heywood...
  if CBTalkVoiceIs(w, n"Cyberbane-War-SideWithThemYourWarIs") { return CBTalkVoiceVFile("side_in", 1.8); }                     // All right, I'm in.
  if CBTalkVoiceIs(w, n"Cyberbane-Allies-JoinTellThemYesIM") { return CBTalkVoiceVFile("join_in", 1.7); }                      // Hell yeah, I'm in!
  if CBTalkVoiceIs(w, n"Cyberbane-StreetEvents-SideIMWithYou") { return CBTalkVoiceVFile("stand_with", 2.2); }                 // All right, I'm with you.
  if CBTalkVoiceIs(w, n"Cyberbane-Allies-ThreatenWalkAwayWhileYouStill") || CBTalkVoiceIs(w, n"Cyberbane-StreetTalk-ThisDoesnTHaveToGet") {
    return CBTalkVoiceVFile("walk_away", 4.2);                                                                                 // Walk away. Do it while you still can.
  }
  if CBTalkVoiceIs(w, n"Cyberbane-Crew-RecruitYouOweMeWorkFor") { return CBTalkVoiceVFile("owe_me", 2.0); }                    // Think you still owe me one.
  if CBTalkVoiceIs(w, n"Cyberbane-CrewHome-AskHeardAnything") { return CBTalkVoiceVFile("crew_news", 1.9); }                   // What's new in the neighborhood?
  if CBTalkVoiceIs(w, n"Cyberbane-RivalLife-ExileLeaveNightCityTonightDon") || CBTalkVoiceIs(w, n"Cyberbane-RivalMoments-ExileGetOutOfNightCity") {
    return CBTalkVoiceVFile("exile_go", 3.0);                                                                                  // Go on, get outta here.
  }
  if CBTalkVoiceIs(w, n"Cyberbane-RivalLife-NotYetStayDownIHaven") { return CBTalkVoiceVFile("stay_put", 2.2); }               // Just stay put an' quiet.
  if CBTalkVoiceIs(w, n"Cyberbane-StreetEvents-RespectsIMSorryForYour") { return CBTalkVoiceVFile("sorry", 1.8); }             // I'm so sorry.
  // Not a word, under Cyberbane's words: V's laugh at a Rival on the ground.
  if line.act == CBTalkActHumiliate() { return CBTalkVoiceVSet(n"generic_21", 1.5); }
  return null;
}

// Which of V's two voices this V speaks in: the voice picked at character creation, which need not be the body's. The
// body's when the game will not say.
func CBVSpeaksMale(game: GameInstance, player: ref<PlayerPuppet>) -> Bool {
  let cc = GameInstance.GetCharacterCustomizationSystem(game);
  let state = IsDefined(cc) ? cc.GetState() : null;
  if IsDefined(state) {
    return state.IsBrainGenderMale();
  }
  return Equals(player.GetResolvedGenderName(), n"Male");
}

// V says it, as the line goes up (Reactions/StreetTalk.reds, Say). Only V in V's own world: not Johnny, not a braindance.
// Returns how long V's line runs, 0 when V says nothing: the answer waits for V to finish, so the two never talk over each
// other.
public func CBTalkVoiceSayV(sys: ref<CyberbaneSystem>, game: GameInstance, line: ref<CBTalkLine>) -> Float {
  let said = CBTalkVoiceForV(line);
  let player = GetPlayer(game);
  let v = CBTalkVoiceState();
  if !IsDefined(said) || !IsDefined(v) || !CBVoicesOn() || !IsDefined(player) || !CBPlayerIsVHere(player)
     || CBPlayerInScene(game) || CBStoryHoldNow(game) {
    return 0.0;
  }
  if StrLen(said.file) > 0 {
    let name = StringToName(said.file + (CBVSpeaksMale(game, player) ? "_m" : "_f"));
    let audio = GameInstance.GetAudioSystem(game);
    if !IsDefined(audio) || !CBAudioXLHas(name) {
      return 0.0;
    }
    CBTrace("voice: one of V's lines from the story, through AudioXL, for the option V chose");
    audio.Play(name, player.GetEntityID());
    return said.secs;
  }
  v.vUntil = CBSoundNow(game) + CBConfig.TalkVoiceVWindow();
  CBTrace("voice: a line of V's own voiceset for the option V chose");
  GameObject.PlayVoiceOver(player, said.entry, n"Scripts:CBStreetTalk");
  return said.secs;
}

// ---- AudioXL --------------------------------------------------------------------------------------------------
//
// Looked for once a launch through Codeware reflection, so nothing here names anything of AudioXL's and Cyberbane compiles
// and runs the same without it. Its native class answers whether a sound by a name is loaded (Has); the game's own audio
// system plays it (AudioSystem.Play), as AudioXL's own API does.

public class CBAudioXLProbe {
  public let state: Int32;   // 0 not looked yet, 1 AudioXL answers, 2 not installed, or not an AudioXL this knows
  public let has: ref<ReflectionStaticFunc>;

  public func Resolve() -> Bool {
    if this.state != 0 {
      return this.state == 1;
    }
    this.state = 2;
    let cls = Reflection.GetClass(n"AudioXL.AudioXLNative");
    if !IsDefined(cls) {
      cls = Reflection.GetClass(n"AudioXLNative");   // the same class, should a build register it without its module
    }
    let fn = IsDefined(cls) ? cls.GetStaticFunction(n"Has") : null;
    if IsDefined(fn) && CBReflectReturns(fn, n"Bool") {
      let params = fn.GetParameters();
      if ArraySize(params) == 1 && IsDefined(params[0]) {
        let type = params[0].GetType();
        if IsDefined(type) && Equals(type.GetName(), n"CName") {
          this.has = fn;
          this.state = 1;
        }
      }
    }
    if this.state != 1 {
      CBLog.Info(n"Talk", IsDefined(cls)
        ? "AudioXL is installed but does not answer as the AudioXL Cyberbane knows: V's lines from the story stay silent."
        : "AudioXL is not installed: V says the options V has a line of the story for in silence (V's own voiceset still speaks).");
      return false;
    }
    let loaded = this.Ask(n"cyberbane_v_ask_talk_f") && this.Ask(n"cyberbane_v_ask_talk_m");
    CBLog.Info(n"Talk", loaded
      ? "AudioXL found, with Cyberbane's sounds loaded: V says the options V has a line of the story for in V's own voice."
      : "AudioXL found, but Cyberbane's sounds are not loaded (red4ext/plugins/AudioXL/sounds/Cyberbane missing?): those options stay silent.");
    return true;
  }

  public func Ask(name: CName) -> Bool {
    if !IsDefined(this.has) {
      return false;
    }
    let args: array<Variant>;
    ArrayPush(args, ToVariant(name));
    return FromVariant<Bool>(this.has.Call(args));
  }
}

// Is this sound of Cyberbane's loaded by AudioXL, so playing it plays something?
public func CBAudioXLHas(name: CName) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return false;
  }
  let probe = rt.GetAudioXLProbe();
  return probe.Resolve() && probe.Ask(name);
}

// One of Cyberbane's own subtitle lines (UI/PhoneMessages.reds, CBSubtitleLineId): never one of the game's to keep off.
func CBTalkVoiceOwnLine(id: CRUID) -> Bool {
  let k = 0;
  while k <= 5 {
    if Equals(id, CBSubtitleLineId(k)) {
      return true;
    }
    k += 1;
  }
  return false;
}

@wrapMethod(ChattersGameController)
protected func ShouldDisplayLine(const lineData: script_ref<scnDialogLineData>) -> Bool {
  if CBTalkVoiceTakes(Deref(lineData)) {
    return false;
  }
  return wrappedMethod(lineData);
}

@wrapMethod(SubtitlesGameController)
protected func ShouldDisplayLine(const lineData: script_ref<scnDialogLineData>) -> Bool {
  if CBTalkVoiceTakes(Deref(lineData)) {
    return false;
  }
  return wrappedMethod(lineData);
}
