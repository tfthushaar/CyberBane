// Cyberbane - Street talk (1.9.5)
//
// Walk up to somebody, look at them, and the game's own choice prompt comes up, the one it shows when V
// can talk to somebody: Greet, Dismiss, Antagonize, Intimidate. Scroll (the D-pad on a controller) to
// pick and press F (A) to say it, the way the game's own choices work. What they say back and what it
// does depends on everything Cyberbane knows: whether they know who V is, how much they and their gang
// fear and respect V, the gang's standing with V and whether V has broken it, and how V works.
//
// ---- What it is for --------------------------------------------------------------------------------
//
// It is the other half of the reputation: the city reacting to V was all one way. And it gives V the
// ways to change a gang's mind that do not go through a body, which players asked for (PLAYER_REQUESTS.md,
// "more explicit ways to become friendly with a gang"):
//
//   Greet       warms a gang a little at a time, up to the edge of Friendly, as keeping the peace does.
//               A friend of V's may pass on where one of their enemies' Rivals is. A frightened member
//               of a gang at war with V takes it as mercy, which is a way back from a vendetta that
//               does not cost eddies.
//   Dismiss     ends it. Friends do not like being blanked often; the frightened take the hint and go.
//   Antagonize  starts something: the frightened back down or run, the bold talk back, and somebody
//               with the nerve for it, or a gang already against V, fights. The gangs at war with
//               theirs like hearing about it.
//   Intimidate  works on fear. Somebody who is afraid enough gives up where one of their own gang's
//               Rivals is hiding (the same lead a purchase on the Hub gives), or pays V to go away, or
//               simply leaves. It fails on the brave and on the backed-up, and V loses face for it.
//               Leaning on people makes their gang fear V more, which is the way to make a gang afraid
//               without killing it.
//
// It works together with holding back (Reactions/Morale.reds, CBHoldBackChance): a gang at war with V
// no longer turns every one of its people on V, only the ones who are not too afraid to. The rest are
// the people V can talk to.
//
// ---- How it fits into the game (read against the 2.5 scripts) --------------------------------------
//
// The prompt. dialogWidgetGameController draws whatever is on the UIInteractions blackboard's
// DialogChoiceHubs (interactionUIBase.script), highlights SelectedIndex in the hub ActiveChoiceHubID
// names, and splits a "[Tag] words" choice into the caption tag and the line (dialogUI.script,
// UpdateDialogHubData). Cyberbane writes its hub there only while nothing of the game's is: no dialogue,
// no interaction prompt, no loot list. It takes it back down only if what is there is still its own.
// The player's state machine reads the same blackboard (AreChoiceHubsActive), so while the prompt is up
// the D-pad does not use a consumable, exactly as with the game's own.
//
// The keys. The game hands a choice's keys to whoever registers for them (GameObject.RegisterInputListener,
// as tutorialGameController does for ChoiceApply), so Cyberbane listens for ChoiceScrollUp/Down and
// ChoiceApply/Choice1 only while its prompt is up. The mouse wheel also draws a weapon from empty hands
// (upperBodyTransitions.script, EmptyHands, CheckSwitchInput), so while the prompt is up V's hands are
// kept empty with the game's own lock, the one a safe area uses (ForceEmptyHandsByZone). The prompt only
// comes up with V's hands empty and outside safe areas, and the lock is let go the moment it goes, so
// nothing V could do with a weapon is ever held back.
//
// ---- Safety -----------------------------------------------------------------------------------------
//
// Nothing happens inside the key callback but choosing: the answer comes on Cyberbane's own tick, with
// the world settled. The person must pass the Safety Gate (no quest characters, vendors, companions,
// scripted beats or safe interiors), stand away from every job site, and not be anybody Cyberbane sent.
// Turning somebody hostile goes through the Director, which tracks it and reverts it with every other
// attitude it set. At most one move order per person (cbTalkSent). No police system is touched: the law
// answers in words. With the kill switch thrown, or the setting off, nothing comes up at all.

// When V last spoke to this person, in fast ticks (0 never), what V has done (CBTalk* bits), and whether
// they have already been sent on their way (one move order each).
@addField(ScriptedPuppet)
public let cbTalkTick: Int32;

@addField(ScriptedPuppet)
public let cbTalkDone: Int32;

@addField(ScriptedPuppet)
public let cbTalkSent: Bool;

// When they were sent on their way (settled ticks), so it wears off (1.9.6): every state needs an exit.
@addField(ScriptedPuppet)
public let cbTalkSentTick: Int32;

// Whether they have already told V they will not talk (1.9.6). Once per person.
@addField(ScriptedPuppet)
public let cbTalkRefused: Bool;

// The settled tick V last had the prompt up on this person, or was waiting on their answer (1.9.5). The
// Director does not turn somebody on V mid-conversation (Reactions/Director.reds, TryGangHostile).
@addField(ScriptedPuppet)
public let cbTalkHeldTick: Int32;

// The four choices, in the order they are shown.
public func CBTalkGreet() -> Int32 = 0
public func CBTalkDismiss() -> Int32 = 1
public func CBTalkAntagonize() -> Int32 = 2
public func CBTalkIntimidate() -> Int32 = 3

// How the person stands with V, decided as the prompt goes up.
public func CBTalkFriendly() -> Int32 = 0
public func CBTalkWary() -> Int32 = 1
public func CBTalkAfraid() -> Int32 = 2
public func CBTalkHostile() -> Int32 = 3

public func CBStreetTalkOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().streetTalk);
}

public func CBShakedownsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkShakedowns;
}

// The person V is talking to, as they stood when the prompt went up.
public class CBTalkTarget {
  public let npc: wref<ScriptedPuppet>;
  public let id: EntityID;
  public let faction: CName;     // n"" for somebody of no gang
  public let cop: Bool;
  public let recognized: Bool;
  public let mood: Int32;        // CBTalkFriendly .. CBTalkHostile
  public let fear: Float;        // how afraid of V, about 0..1 (more for a broken gang)
  public let nerve: Float;       // CBNerve
  public let backers: Int32;     // their own people standing with them
  public let speaker: String;    // how the subtitles name them
  public let leadId: Int32;      // a Rival of their gang whose hiding place they could give up; 0 none
  public let leadName: String;
  public let first: Bool;        // the first time V has said this to them
  public let safe: Bool;         // a safe place (V in one, or they are indoors in one): words only (1.9.5)
  public let atWork: Bool;       // at a workspot: never a move order, the game walks them off (1.9.5)
}

// What they say back.
public class CBTalkAnswer {
  public let line: String;
  public let vo: CName;
}

// Hands the keys on to the talk, while its prompt is up.
public class CBTalkInput extends IScriptable {
  public let owner: wref<CBStreetTalk>;

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let talk = this.owner;
    if IsDefined(talk) {
      talk.OnInput(action);
    }
    return false;
  }
}

// Its own tick, a few times a second: the prompt has to follow where V is looking. A generation token,
// as the fast tick has, so a chain from an earlier session stops.
public class CBTalkTickCallback extends DelayCallback {
  public let game: GameInstance;
  public let generation: Int32;

  public func Call() -> Void {
    let sys = CyberbaneSystem.Get(this.game);
    if IsDefined(sys) {
      let talk = sys.GetStreetTalk();
      if IsDefined(talk) {
        talk.OnTick(this.game, this.generation);
      }
    }
  }
}

// ---- The conversation (1.9.6) ------------------------------------------------------------------------
//
// A short conversation in the game's own rhythm. One "Talk" comes up on the person V settles on, the way the
// game's own "Talk" does for its characters; F opens the lines; a line said waits for the answer; and the
// lines come back, what V has already said dimmed, until V leaves, walks off or looks away. V's hands are
// held only while the lines are up, never for the single "Talk".
//
// Before 1.9.6 the prompt held only while the game's look-at kept answering the same person, with 0.8 s of
// grace, and after one exchange the person was locked away for 45 seconds. Gangers stand shoulder to
// shoulder: the look-at slid to the man beside, the prompt closed and reopened on him, and in the log of
// 17 November eleven Tyger Claw prompts came and went in 42 seconds with nobody spoken to. Now it stays on
// whoever V chose while they are close and in front of V, every close says why in the log, and the lockout
// only starts once a conversation is over (the effects already have their daily ceilings, CBTalkTally).

public func CBTalkStageIdle() -> Int32 = 0
public func CBTalkStageOffered() -> Int32 = 1   // "Talk" on screen
public func CBTalkStageOpen() -> Int32 = 2      // the lines on screen
public func CBTalkStageWaiting() -> Int32 = 3   // a line said, the answer due

// What a line does beyond the four choices.
public func CBTalkActTalk() -> Int32 = 10
public func CBTalkActLeave() -> Int32 = 11

// One line of the list: its words, what it does, and how the game should show it (dialogUI.script reads an
// icon from the caption parts and dims, greys or highlights by the choice type, as for its own lines).
public class CBTalkLine {
  public let text: String;
  public let act: Int32;
  public let icon: TweakDBID;
  public let important: Bool;    // highlighted: this one leads somewhere
  public let said: Bool;         // dimmed: V has said it to them before
  public let inactive: Bool;     // greyed: shown, but V cannot take it
  public let illegal: Bool;      // a crime
}

func CBTalkMakeLine(text: String, act: Int32, icon: TweakDBID) -> ref<CBTalkLine> {
  let l = new CBTalkLine();
  l.text = text;
  l.act = act;
  l.icon = icon;
  return l;
}

public func CBTalkFirstOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkFirst;
}

public class CBStreetTalk {
  private let m_game: GameInstance;
  private let m_generation: Int32;
  private let m_input: ref<CBTalkInput>;
  private let m_listening: wref<PlayerPuppet>;

  // The conversation, if any.
  private let m_stage: Int32;
  private let m_index: Int32;
  private let m_target: ref<CBTalkTarget>;
  private let m_lines: array<ref<CBTalkLine>>;
  private let m_exchanges: Int32;   // lines said in this conversation
  private let m_lostFor: Float;
  private let m_glanceIn: Float;
  private let m_handsHeld: Bool;
  // Whether this session has made sure the lock is off (see OnTick).
  private let m_handsChecked: Bool;

  // What the keys asked for, carried out on the next tick, never inside the key callback.
  private let m_wantOpen: Bool;
  private let m_wantSay: Bool;
  private let m_wantIndex: Int32;

  // Somebody V is looking at and how long for, before "Talk" comes up.
  private let m_candidate: wref<ScriptedPuppet>;
  private let m_dwell: Float;

  // A line said, waiting for the answer.
  private let m_pending: Int32;
  private let m_pendingIn: Float;

  // The two subtitle lines of an exchange: V's, then theirs (UI/PhoneMessages.reds slots 2 and 3).
  private let m_vLineLeft: Float;
  private let m_replyLeft: Float;

  // After V reached for a weapon with the prompt up, how long before it may come up again (seconds).
  private let m_quietLeft: Float;
  // Why the prompt did not come up for the person V is facing, as last logged, and how long V has faced
  // them without it (1.9.5): one line in the log per reason, so a report can say exactly what stopped it.
  private let m_whyLogged: String;
  private let m_whyFor: Float;
  private let m_whyLogAt: Float;
  private let m_reassertLogged: Bool;

  // Keeping one notch of the wheel to one step (see Scroll).
  private let m_lastScrollAt: Float;
  private let m_lastScrollStep: Int32;
  private let m_lastScrollByWeapon: Bool;
  private let m_choiceScrollSeen: Bool;

  public func Start(game: GameInstance) -> Void {
    this.m_game = game;
    this.m_generation += 1;
    this.m_stage = CBTalkStageIdle();
    this.m_target = null;
    ArrayClear(this.m_lines);
    this.m_candidate = null;
    this.m_dwell = 0.0;
    this.m_wantOpen = false;
    this.m_wantSay = false;
    this.m_handsHeld = false;
    this.m_handsChecked = false;
    this.m_listening = null;
    this.m_quietLeft = 0.0;
    this.Schedule(game);
  }

  private func Schedule(game: GameInstance) -> Void {
    let ds = GameInstance.GetDelaySystem(game);
    if !IsDefined(ds) {
      return;
    }
    let cb = new CBTalkTickCallback();
    cb.game = game;
    cb.generation = this.m_generation;
    ds.DelayCallback(cb, CBConfig.TalkTickSeconds(), false);
  }

  public func IsShown() -> Bool {
    return this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen();
  }

  // Mid-exchange: a conversation is on, or a line of one is still on screen. The street's overheard lines
  // and the phone wait (Reactions/Director.reds, UI/PhoneMessages.reds), so they do not talk over it.
  public func Busy() -> Bool {
    return this.m_stage != CBTalkStageIdle() || this.m_vLineLeft > 0.0 || this.m_replyLeft > 0.0;
  }

  public func HoldsHands() -> Bool {
    return this.m_handsHeld;
  }

  public func OnTick(game: GameInstance, generation: Int32) -> Void {
    if generation != this.m_generation {
      return;
    }
    this.m_game = game;
    this.Schedule(game);
    let dt = CBConfig.TalkTickSeconds();
    this.AgeLines(game, dt);
    if this.m_quietLeft > 0.0 {
      this.m_quietLeft -= dt;
    }
    let sys = CyberbaneSystem.Get(game);
    let player = GetPlayer(game);
    if !IsDefined(sys) || !IsDefined(player) {
      this.StandDown(game, "the world is changing");
      return;
    }
    let tick = Max(sys.GetTickCount(), 1);
    // A line said: the answer comes after a beat, only with the world settled.
    if this.m_stage == CBTalkStageWaiting() {
      if IsDefined(this.m_target) && IsDefined(this.m_target.npc) {
        this.m_target.npc.cbTalkHeldTick = tick;
      }
      this.m_pendingIn -= dt;
      if this.m_pendingIn <= 0.0 {
        if CBWorldStable(game) && CBStreetTalkOn() {
          this.Answer(sys, game, player);
        } else {
          this.End(game, "the moment passed");
        }
      }
      return;
    }
    let notNow = this.AllowedWhyNot(sys, game, player);
    if StrLen(notNow) > 0 {
      this.StandDown(game, notNow);
      // Said in the log when V is facing somebody; not looked for at all while talk is off, the world
      // is loading or V is driving.
      if CBStreetTalkOn() && CBWorldStable(game) && !VehicleComponent.IsMountedToVehicle(game, player.GetEntityID()) {
        this.NoteWhyNot(game, dt, this.LookedAt(game, player), notNow);
      }
      return;
    }
    // Once a session, on its first settled tick: the hands lock is a state-machine setting, and one
    // left on by a prompt that was up when the game was saved must not follow V into the next session.
    // Never in a safe area, where the lock is the game's own.
    if !this.m_handsChecked {
      this.m_handsChecked = true;
      if !CBPlayerInSafeZone(game) {
        CBQueueZoneArmsLock(player, false);
      }
    }
    // The keys are let go on a tick, never inside their own callback.
    if this.m_stage == CBTalkStageIdle() {
      this.StopListening();
    }
    let npc = this.LookedAt(game, player);
    if this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen() {
      this.Keep(sys, game, player, npc, dt, tick);
      return;
    }
    this.Settle(sys, game, player, npc, dt, tick);
  }

  // A conversation on screen: act on the keys, keep it, or end it and say why.
  private func Keep(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                    npc: ref<ScriptedPuppet>, dt: Float, tick: Int32) -> Void {
    let t = this.m_target;
    if !IsDefined(t) || !IsDefined(t.npc) {
      this.End(game, "they are gone");
      return;
    }
    let why = CBTalkWhyNot(sys, game, player, t.npc, CBConfig.TalkKeepRange(), true);
    if StrLen(why) > 0 {
      this.End(game, why);
      return;
    }
    if CBNativePromptUp(game) {
      this.End(game, "one of the game's own prompts came up");
      return;
    }
    // With only "Talk" up V's hands are free: drawing a weapon ends it.
    if !this.m_handsHeld && IsDefined(GameObject.GetActiveWeapon(player)) {
      this.End(game, "V drew a weapon");
      return;
    }
    t.npc.cbTalkHeldTick = tick;
    if this.m_wantOpen {
      this.m_wantOpen = false;
      if this.m_stage == CBTalkStageOffered() {
        this.OpenLines(sys, game, player);
        return;
      }
    }
    if this.m_wantSay {
      this.m_wantSay = false;
      if this.m_stage == CBTalkStageOpen() {
        this.Say(game, this.m_wantIndex);
        return;
      }
    }
    // Still on screen? Something of the game's may have written over the hub without a hub of its own
    // (CBNativePromptUp would have ended ours for one of those). Put it back, and say so once.
    if !CBTalkHubShown(game) {
      this.Push(game);
      if !this.m_reassertLogged {
        this.m_reassertLogged = true;
        CBLog.Info(n"Talk", "The talk prompt was taken off the screen by the game; putting it back.");
      }
    }
    // They keep their eyes on V, the way a scene turns the game's own characters to face V.
    this.m_glanceIn -= dt;
    if this.m_glanceIn <= 0.0 {
      this.m_glanceIn = CBConfig.TalkGlanceEvery();
      let reactions = t.npc.GetStimReactionComponent();
      if IsDefined(reactions) {
        reactions.CBGlanceAt(player);
      }
    }
    // Whoever V chose, while they are close and in front of V; the crosshair sliding onto the man beside
    // them changes nothing. A glance away is not walking off: a moment's grace before it goes.
    let facing = (IsDefined(npc) && Equals(npc.GetEntityID(), t.id)) || CBTalkFacing(player, t.npc);
    this.m_lostFor = facing ? 0.0 : this.m_lostFor + dt;
    if this.m_lostFor > CBConfig.TalkLookGrace() {
      this.End(game, "V looked away");
    }
  }

  // Nothing up: is V settling on somebody?
  private func Settle(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                      npc: ref<ScriptedPuppet>, dt: Float, tick: Int32) -> Void {
    // A weapon in hand keeps the prompt away (the wheel would switch guns instead of lines), and is said
    // once a launch (1.9.5).
    let armed = IsDefined(GameObject.GetActiveWeapon(player));
    let why = "";
    if this.m_quietLeft > 0.0 {
      why = "V reached for a weapon a moment ago";
    } else {
      if IsDefined(npc) {
        why = CBTalkWhyNot(sys, game, player, npc, CBConfig.TalkRange());
        if StrLen(why) == 0 && CBNativePromptUp(game) {
          why = "one of the game's own prompts is up";
        }
      }
    }
    if !IsDefined(npc) || StrLen(why) > 0 {
      this.m_candidate = null;
      this.m_dwell = 0.0;
      this.NoteWhyNot(game, dt, npc, why);
      // A ganger or a cop who will not talk says so, once, instead of nothing (1.9.6).
      if IsDefined(npc) && Equals(why, CBTalkWhyHostile()) && this.m_whyFor >= CBConfig.TalkDwell() * 2.0 {
        this.Refuse(game, npc);
      }
      return;
    }
    this.m_whyFor = 0.0;
    let cand = this.m_candidate;
    if IsDefined(cand) && Equals(cand.GetEntityID(), npc.GetEntityID()) {
      this.m_dwell += dt;
    } else {
      this.m_candidate = npc;
      this.m_dwell = 0.0;
    }
    // Whoever V is settling on is left alone meanwhile (1.9.5): the crowd reactions sent a frightened
    // passer-by running, and a warned ganger drew, in the moment before the prompt came up.
    npc.cbTalkHeldTick = tick;
    if armed {
      this.NoteWhyNot(game, dt, npc, "a weapon is in V's hands");
      let rt = CyberbaneRuntime.Get();
      if this.m_dwell >= CBConfig.TalkArmedHintDwell() && IsDefined(rt) && !rt.GetTalkHolsterHinted() {
        rt.SetTalkHolsterHinted(true);
        CBSystemNote(game, "put your weapon away to talk to people. Look at somebody up close with empty hands and the choices come up.", 7.0);
      }
      return;
    }
    if this.m_dwell >= CBConfig.TalkDwell() {
      this.Begin(sys, game, player, npc);
    }
  }

  private func Begin(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                     npc: ref<ScriptedPuppet>) -> Void {
    let t = CBTalkRead(sys, game, npc);
    if !IsDefined(t) {
      return;
    }
    this.m_target = t;
    this.m_exchanges = 0;
    this.m_lostFor = 0.0;
    this.m_glanceIn = CBConfig.TalkGlanceEvery();
    this.m_dwell = 0.0;
    this.m_candidate = null;
    this.m_whyFor = 0.0;
    this.m_wantOpen = false;
    this.m_wantSay = false;
    this.Listen(player);
    let reactions = npc.GetStimReactionComponent();
    if IsDefined(reactions) {
      reactions.CBGlanceAt(player);
    }
    if CBTalkFirstOn() {
      ArrayClear(this.m_lines);
      ArrayPush(this.m_lines, CBTalkMakeLine("Talk", CBTalkActTalk(), t"ChoiceCaptionParts.TalkIcon"));
      this.m_index = 0;
      this.m_stage = CBTalkStageOffered();
      this.Push(game);
      CBLog.Info(n"Talk", s"Talk offered: \(CBTalkTitle(t)).");
      return;
    }
    this.OpenLines(sys, game, player);
  }

  // The lines go up, read again from how the person stands with V now: a ganger V has just leaned on may
  // be afraid by the second exchange, and the title says so.
  private func OpenLines(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let t = this.m_target;
    if !IsDefined(t) || !IsDefined(t.npc) {
      this.End(game, "they are gone");
      return;
    }
    if this.m_exchanges > 0 {
      let fresh = CBTalkRead(sys, game, t.npc);
      if IsDefined(fresh) {
        this.m_target = fresh;
        t = fresh;
      }
    }
    this.m_lines = CBTalkChoices(sys, t, this.m_exchanges > 0);
    this.m_index = 0;
    this.m_stage = CBTalkStageOpen();
    this.m_lostFor = 0.0;
    this.Push(game);
    // Hands stay empty while the lines are up, so the wheel picks a line instead of drawing a gun.
    if !this.m_handsHeld {
      CBQueueZoneArmsLock(player, true);
      this.m_handsHeld = true;
    }
    if this.m_exchanges == 0 {
      CBLog.Info(n"Talk", s"Prompt up: \(CBTalkTitle(t)).");
    }
  }

  private func Push(game: GameInstance) -> Void {
    if IsDefined(this.m_target) {
      CBTalkPushHub(game, CBTalkTitle(this.m_target), this.m_lines, this.m_index);
    }
  }

  // V says it. The words go up at once; the answer and everything it does come after a beat.
  private func Say(game: GameInstance, index: Int32) -> Void {
    if index < 0 || index >= ArraySize(this.m_lines) || !IsDefined(this.m_target) {
      return;
    }
    let line = this.m_lines[index];
    if CBGameSubtitlesOn(game)
       && CBShowGameSubtitle(game, 2, "V", CBTalkWords(line.text), CBConfig.TalkLineSeconds()) {
      this.m_vLineLeft = CBConfig.TalkLineSeconds();
    }
    if line.act == CBTalkActLeave() {
      this.End(game, "V left it there");
      return;
    }
    CBTalkClearHub(game);
    this.m_pending = line.act;
    this.m_pendingIn = CBConfig.TalkAnswerDelay();
    this.m_stage = CBTalkStageWaiting();
    this.m_exchanges += 1;
  }

  // ---- The answer ----------------------------------------------------------------------------------

  private func Answer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let t = this.m_target;
    let choice = this.m_pending;
    let npc = IsDefined(t) ? t.npc : null;
    // Gone, down or already fighting by now: nobody left to answer.
    if !IsDefined(npc) || !npc.IsAttached() || npc.IsDead() || ScriptedPuppet.IsDefeated(npc)
       || CBNpcInCombat(npc) {
      this.End(game, "they are gone");
      return;
    }
    t.first = !CBMaskHas(npc.cbTalkDone, choice);
    npc.cbTalkDone = CBMaskSet(npc.cbTalkDone, choice);
    let a: ref<CBTalkAnswer>;
    if choice == CBTalkGreet() {
      a = CBTalkOnGreet(sys, game, player, t);
    } else {
      if choice == CBTalkDismiss() {
        a = CBTalkOnDismiss(sys, game, player, t);
      } else {
        if choice == CBTalkAntagonize() {
          a = CBTalkOnAntagonize(sys, game, player, t);
        } else {
          a = CBTalkOnIntimidate(sys, game, player, t);
        }
      }
    }
    // In the game's subtitles; with those switched off, on Cyberbane's own line, so the answer is
    // never lost (UI/PhoneMessages.reds, CBOverheard).
    if IsDefined(a) && StrLen(a.line) > 0 {
      if CBGameSubtitlesOn(game) {
        if CBShowGameSubtitle(game, 3, t.speaker, a.line, CBConfig.TalkReplySeconds()) {
          this.m_replyLeft = CBConfig.TalkReplySeconds();
        }
      } else {
        CBOverheard(game, t.speaker, a.line);
      }
    }
    if IsDefined(a) && NotEquals(a.vo, n"") && npc.IsAttached() {
      GameObject.PlayVoiceOver(npc, a.vo, n"Scripts:CBStreetTalk");
    }
    let reactions = npc.GetStimReactionComponent();
    if IsDefined(reactions) && npc.IsAttached() && !npc.cbTalkSent {
      reactions.CBGlanceAt(player);
    }
    sys.GetScore().MarkDirty();
    // On, or over? Over when V brushed them off, they have gone, the talk turned to a fight, or it has
    // gone on long enough; otherwise the lines come back for more.
    let over = choice == CBTalkDismiss() || npc.cbTalkSent || this.m_exchanges >= CBConfig.TalkMaxExchanges()
               || StrLen(CBTalkWhyNot(sys, game, player, npc, CBConfig.TalkKeepRange(), true)) > 0;
    if over {
      this.End(game, "the conversation is over");
      return;
    }
    this.OpenLines(sys, game, player);
  }

  // A ganger or a cop who is hostile to V and will not talk says so (1.9.6). Once per person.
  private func Refuse(game: GameInstance, npc: ref<ScriptedPuppet>) -> Void {
    if !IsDefined(npc) || npc.cbTalkRefused {
      return;
    }
    let faction = CBClassifyFaction(npc);
    let line = "";
    if Equals(faction, n"NCPD") {
      line = CBWhisperPick2("Move along.", "Not now. Keep walking.");
    } else {
      if NotEquals(faction, n"") && NotEquals(faction, n"MaxTac") {
        line = CBWhisperPick3("Keep walking, merc.", "Not talking to you. Move.", "Wrong street to stop on.");
      }
    }
    if StrLen(line) == 0 {
      return;
    }
    npc.cbTalkRefused = true;
    let speaker = CBFactionMemberWord(faction);
    if StrLen(speaker) == 0 {
      speaker = "Ganger";
    }
    if CBGameSubtitlesOn(game) {
      if CBShowGameSubtitle(game, 3, speaker, line, CBConfig.TalkReplySeconds()) {
        this.m_replyLeft = CBConfig.TalkReplySeconds();
      }
    } else {
      CBOverheard(game, speaker, line);
    }
    CBLog.Info(n"Talk", s"A \(speaker) would not talk: hostile to V.");
  }

  // The conversation is over, whatever ended it. The person cannot be spoken to again for a moment once
  // something was said (TalkCooldownTicks), and the log says why it ended.
  private func End(game: GameInstance, why: String) -> Void {
    let wasOn = this.m_stage != CBTalkStageIdle();
    if this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen() {
      CBTalkClearHub(game);
    }
    if wasOn && this.m_exchanges > 0 && IsDefined(this.m_target) && IsDefined(this.m_target.npc) {
      let sys = CyberbaneSystem.Get(game);
      this.m_target.npc.cbTalkTick = IsDefined(sys) ? Max(sys.GetTickCount(), 1) : 1;
    }
    if wasOn {
      CBLog.Info(n"Talk", s"Prompt down: \(why).");
    }
    this.m_stage = CBTalkStageIdle();
    this.m_target = null;
    ArrayClear(this.m_lines);
    this.m_lostFor = 0.0;
    this.m_wantOpen = false;
    this.m_wantSay = false;
    this.ReleaseHands(game);
  }

  private func StandDown(game: GameInstance, why: String) -> Void {
    this.End(game, why);
    this.StopListening();
    this.m_candidate = null;
    this.m_dwell = 0.0;
  }

  // Everything that has to be true for anybody to be talked to at all, as the first reason it fails
  // ("" when it does not), for the log.
  private func AllowedWhyNot(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> String {
    if !CBStreetTalkOn() {
      return "Talk to people is off in Mod Settings, or Cyberbane is off";
    }
    if !CBWorldStable(game) {
      return "the world is loading, paused or in photo mode";
    }
    if CBPlayerInScene(game) {
      return "V is in a scene";
    }
    if sys.GetStoryHold() != CBStoryNone() {
      return "the story has the stage";
    }
    // A safe area, a job nearby and a gang's own turf used to switch talk off outright (1.9.5): the
    // Director's rules for when it may turn or scatter people, borrowed whole. Talk is words, so each
    // person is judged instead (CBTalkWhyNot: the job's own people, the hostile, the story's), and in a
    // safe place the words are all that happens (CBTalkTarget.safe). Only a moment the story has
    // quieted (the NoCombat status) still says no.
    if CBPlayerNoCombatTag(game) {
      return "the story has quieted things here";
    }
    if !sys.WornReady() {
      return "the session has only just started";
    }
    if player.IsInCombat() {
      return "V is in combat";
    }
    if VehicleComponent.IsMountedToVehicle(game, player.GetEntityID()) {
      return "V is in a vehicle";
    }
    // Nobody sneaks up on somebody to say hello (1.9.5). Crouched behind a ganger for a takedown, the
    // prompt came up instead, and V's hands were held while it was up.
    if CBPlayerSneaking(game) {
      return "V is crouched";
    }
    return "";
  }

  // V has been facing somebody close for a moment and the prompt did not come up: say why, once per
  // reason, at most every few seconds. Only for somebody in talking range, so it never fills the log.
  private func NoteWhyNot(game: GameInstance, dt: Float, npc: ref<ScriptedPuppet>, why: String) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(npc) || !IsDefined(player) || StrLen(why) == 0
       || Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > CBConfig.TalkRange() {
      this.m_whyFor = 0.0;
      return;
    }
    this.m_whyFor += dt;
    if this.m_whyFor < CBConfig.TalkDwell() * 2.0 {
      return;
    }
    let ts = GameInstance.GetTimeSystem(game);
    let now = IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
    if Equals(why, this.m_whyLogged) && now - this.m_whyLogAt < CBConfig.TalkWhyLogSeconds() {
      return;
    }
    this.m_whyLogged = why;
    this.m_whyLogAt = now;
    CBLog.Info(n"Talk", s"No prompt for the person in front of V: \(why).");
  }

  // Who V is facing, up close. The game's own look-at first; then, when that hands back nobody (it misses
  // people whose bodies the crosshair is not exactly on, and passers-by the targeting skips), the person
  // in talking range closest to the line of V's sight, from Cyberbane's registry. By angle, not distance
  // (1.9.6): the nearest of a group is often not the one V is looking at.
  private func LookedAt(game: GameInstance, player: ref<PlayerPuppet>) -> ref<ScriptedPuppet> {
    let ppos = player.GetWorldPosition();
    let targeting = GameInstance.GetTargetingSystem(game);
    if IsDefined(targeting) {
      let hit = targeting.GetLookAtObject(player, true, true) as ScriptedPuppet;
      if IsDefined(hit) && !hit.IsPlayer() && Vector4.Distance(ppos, hit.GetWorldPosition()) <= CBConfig.TalkKeepRange() {
        return hit;
      }
    }
    let sys = CyberbaneSystem.Get(game);
    let reg = IsDefined(sys) ? sys.GetRegistry() : null;
    if !IsDefined(reg) {
      return null;
    }
    let fwd = Vector4.Normalize2D(player.GetWorldForward());
    let best: ref<ScriptedPuppet>;
    let bestDot = CBConfig.TalkFacingDot();
    for p in reg.GetAll() {
      if IsDefined(p) && p.IsAttached() && !p.IsPlayer() && !p.IsDead() {
        let pos = p.GetWorldPosition();
        if Vector4.Distance(ppos, pos) <= CBConfig.TalkRange() && AbsF(pos.Z - ppos.Z) <= 1.5 {
          let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
          let dot = fwd.X * dir.X + fwd.Y * dir.Y;
          if dot >= bestDot {
            best = p;
            bestDot = dot;
          }
        }
      }
    }
    return best;
  }

  // The lock comes off unless V is now somewhere the game itself keeps V's hands empty: a safe area
  // keeps its own lock, and lifting it there would be lifting the game's.
  private func ReleaseHands(game: GameInstance) -> Void {
    if !this.m_handsHeld {
      return;
    }
    this.m_handsHeld = false;
    let player = GetPlayer(game);
    if IsDefined(player) && !CBPlayerInSafeZone(game) {
      CBQueueZoneArmsLock(player, false);
    }
  }

  private func Listen(player: ref<PlayerPuppet>) -> Void {
    if IsDefined(this.m_listening) {
      return;
    }
    if !IsDefined(this.m_input) {
      this.m_input = new CBTalkInput();
      this.m_input.owner = this;
    }
    player.RegisterInputListener(this.m_input, n"ChoiceScrollUp");
    player.RegisterInputListener(this.m_input, n"ChoiceScrollDown");
    player.RegisterInputListener(this.m_input, n"ChoiceApply");
    player.RegisterInputListener(this.m_input, n"Choice1");
    player.RegisterInputListener(this.m_input, n"NextWeapon");
    player.RegisterInputListener(this.m_input, n"PreviousWeapon");
    // Reaching for a weapon ends it (1.9.5). V's hands are held while the lines are up, so the scroll
    // wheel picks a line instead of a gun; a weapon key used to do nothing at all until V looked away.
    player.RegisterInputListener(this.m_input, n"SwitchItem");
    player.RegisterInputListener(this.m_input, n"WeaponSlot1");
    player.RegisterInputListener(this.m_input, n"WeaponSlot2");
    player.RegisterInputListener(this.m_input, n"WeaponSlot3");
    player.RegisterInputListener(this.m_input, n"WeaponSlot4");
    player.RegisterInputListener(this.m_input, n"WeaponWheel");
    player.RegisterInputListener(this.m_input, n"QuickMelee");
    player.RegisterInputListener(this.m_input, n"UseCombatGadget");
    this.m_listening = player;
  }

  private func StopListening() -> Void {
    let player = this.m_listening;
    if IsDefined(player) && IsDefined(this.m_input) {
      player.UnregisterInputListener(this.m_input);
    }
    this.m_listening = null;
  }

  // ---- The keys ------------------------------------------------------------------------------------
  // Only requests are made here; the tick carries them out.

  public func OnInput(action: ListenerAction) -> Void {
    if this.m_stage == CBTalkStageIdle() {
      return;
    }
    let name = ListenerAction.GetName(action);
    let kind = ListenerAction.GetType(action);
    let pressed = Equals(kind, gameinputActionType.BUTTON_PRESSED);
    // Reaching for a weapon ends it at any point, an answer on its way included: V's hands are held
    // from the moment the lines go up until the conversation is over.
    if CBTalkReachKey(name) {
      if pressed || Equals(kind, gameinputActionType.BUTTON_HOLD_COMPLETE) {
        this.End(this.m_game, "V reached for a weapon");
        this.m_quietLeft = CBConfig.TalkQuietAfterReach();
      }
      return;
    }
    if this.m_stage != CBTalkStageOffered() && this.m_stage != CBTalkStageOpen() {
      return;
    }
    if Equals(name, n"ChoiceApply") || Equals(name, n"Choice1") {
      if pressed {
        if this.m_stage == CBTalkStageOffered() {
          this.m_wantOpen = true;
        } else {
          this.m_wantSay = true;
          this.m_wantIndex = this.m_index;
        }
      }
      return;
    }
    // Nothing to scroll with only "Talk" up; with V's hands free, the wheel is the game's.
    if this.m_stage != CBTalkStageOpen() {
      return;
    }
    // A D-pad press, its repeat, or a notch of the mouse wheel, which can come as a relative change.
    let notch = Equals(kind, gameinputActionType.RELATIVE_CHANGE) && AbsF(ListenerAction.GetValue(action)) > 0.0;
    if !pressed && !notch && !Equals(kind, gameinputActionType.REPEAT) {
      return;
    }
    if Equals(name, n"ChoiceScrollUp") {
      this.Scroll(-1, false);
    } else {
      if Equals(name, n"ChoiceScrollDown") {
        this.Scroll(1, false);
      } else {
        if Equals(name, n"PreviousWeapon") {
          this.Scroll(-1, true);
        } else {
          if Equals(name, n"NextWeapon") {
            this.Scroll(1, true);
          }
        }
      }
    }
  }

  // One notch of the wheel can arrive as both a choice action and a weapon action. The choice actions
  // are the game's own for this, and once one has been seen the weapon ones are ignored; until then a
  // weapon action steps, and a choice action in the same frame replaces its step rather than adding one.
  private func Scroll(step: Int32, byWeapon: Bool) -> Void {
    let count = ArraySize(this.m_lines);
    if count == 0 {
      return;
    }
    let ts = GameInstance.GetTimeSystem(this.m_game);
    let now = IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
    let sameFrame = this.m_lastScrollAt > 0.0 && now == this.m_lastScrollAt;
    if byWeapon {
      if this.m_choiceScrollSeen || sameFrame {
        return;
      }
    } else {
      this.m_choiceScrollSeen = true;
      if sameFrame {
        if !this.m_lastScrollByWeapon {
          return;
        }
        this.m_index = (this.m_index - this.m_lastScrollStep + count) % count;
      }
    }
    this.m_index = (this.m_index + step + count) % count;
    this.m_lastScrollAt = now;
    this.m_lastScrollStep = step;
    this.m_lastScrollByWeapon = byWeapon;
    CBTalkSelect(this.m_game, this.m_index);
  }

  private func AgeLines(game: GameInstance, dt: Float) -> Void {
    if this.m_vLineLeft > 0.0 {
      this.m_vLineLeft -= dt;
      if this.m_vLineLeft <= 0.0 {
        CBHideGameSubtitle(game, 2);
      }
    }
    if this.m_replyLeft > 0.0 {
      this.m_replyLeft -= dt;
      if this.m_replyLeft <= 0.0 {
        CBHideGameSubtitle(game, 3);
      }
    }
  }
}

// Is this person still close and in front of V? Wide enough that a conversation survives V's eyes moving
// across the group, narrow enough that turning away ends it.
func CBTalkFacing(player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(player) || !IsDefined(npc) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let pos = npc.GetWorldPosition();
  if Vector4.Distance(ppos, pos) > CBConfig.TalkKeepRange() {
    return false;
  }
  let fwd = Vector4.Normalize2D(player.GetWorldForward());
  let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
  return fwd.X * dir.X + fwd.Y * dir.Y >= CBConfig.TalkKeepDot();
}

// A key V reaches for a weapon or a gadget with (CBStreetTalk.Listen).
func CBTalkReachKey(name: CName) -> Bool {
  return Equals(name, n"SwitchItem") || Equals(name, n"WeaponSlot1") || Equals(name, n"WeaponSlot2")
      || Equals(name, n"WeaponSlot3") || Equals(name, n"WeaponSlot4") || Equals(name, n"WeaponWheel")
      || Equals(name, n"QuickMelee") || Equals(name, n"UseCombatGadget");
}

// Is V creeping about? Crouched, or in the stealth state the game puts V in when there are hostiles about
// who have not found V yet.
public func CBPlayerSneaking(game: GameInstance) -> Bool {
  let psm = CBPlayerPSM(game);
  if IsDefined(psm)
     && psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion) == EnumInt(gamePSMLocomotionStates.Crouch) {
    return true;
  }
  return CBPlayerInStealthState(game);
}

// The parley held: this one, and everybody of their gang standing with them who has not already been
// turned on V, hold back from V from now on. How many of the crew went with them.
func CBTalkParleyCrew(sys: ref<CyberbaneSystem>, t: ref<CBTalkTarget>) -> Int32 {
  let npc = t.npc;
  if !IsDefined(npc) {
    return 0;
  }
  npc.cbHoldState = 1;
  let reg = IsDefined(sys) ? sys.GetRegistry() : null;
  if !IsDefined(reg) {
    return 0;
  }
  let here = npc.GetWorldPosition();
  let id = npc.GetEntityID();
  let count = 0;
  for other in reg.GetAll() {
    if CBNpcSafe(sys, other) && NotEquals(other.GetEntityID(), id) && !other.IsDead() && !other.cbHostileByCyberbane
       && Vector4.Distance(here, other.GetWorldPosition()) <= CBConfig.HoldBackBackerRadius()
       && Equals(CBClassifyFaction(other), t.faction) {
      other.cbHoldState = 1;
      count += 1;
    }
  }
  return count;
}

// ---- Who can be talked to ------------------------------------------------------------------------------

// The reason a hostile person gives, kept as one string so the refusal line can recognise it.
public func CBTalkWhyHostile() -> String = "they are hostile to V"

// The first reason this person cannot be talked to, "" when they can (1.9.5: the log says which). With
// `talking`, V is already in a conversation with them, and the wait between conversations does not apply.
public func CBTalkWhyNot(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                         npc: wref<ScriptedPuppet>, range: Float, opt talking: Bool) -> String {
  if !IsDefined(npc) || !IsDefined(player) || !npc.IsAttached() || npc.IsDead() || ScriptedPuppet.IsDefeated(npc)
     || !CBStillStanding(npc) {
    return "they are down or gone";
  }
  if !npc.IsHuman() || npc.IsMechanical() {
    return "not a person";
  }
  // Somebody V sent on their way can be spoken to again a few minutes later (1.9.6); before that they
  // stayed out of reach until they streamed out.
  if npc.cbTalkSent && npc.cbTalkSentTick > 0 && sys.GetTickCount() - npc.cbTalkSentTick >= CBConfig.TalkSentRestTicks() {
    npc.cbTalkSent = false;
  }
  if npc.cbMoraleBroken || npc.cbTalkSent {
    return "they are running from V";
  }
  if Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > range {
    return "too far";
  }
  if !talking && npc.cbTalkTick > 0 && (sys.GetTickCount() - npc.cbTalkTick) < CBConfig.TalkCooldownTicks() {
    return "V spoke to them a moment ago";
  }
  if !CBNpcSafe(sys, npc) {
    return "they have only just appeared";
  }
  if !CBSafetyGate.CanTalkTo(npc) {
    return CBTalkGateReason(sys, npc);
  }
  if CBSentByUs(GameInstance.GetDynamicEntitySystem(), npc) {
    return "one of Cyberbane's own (a crew, a Rival or a hunter)";
  }
  if CBNpcInCombat(npc) {
    return "they are in a fight";
  }
  // Somebody standing at a job of V's: a gig's target, a contact. Close to the marker only (1.9.5): sixty
  // metres round every active objective on the map left whole streets with nobody to talk to.
  if sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.TalkJobClearance()) {
    return "they are at one of V's jobs";
  }
  if VehicleComponent.IsMountedToVehicle(game, npc.GetEntityID()) {
    return "they are in a vehicle";
  }
  if Equals(CBClassifyFaction(npc), n"MaxTac") {
    return "MaxTac";
  }
  let agent = npc.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) && Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
    return CBTalkWhyHostile();
  }
  return "";
}

// Which of the Safety Gate's rules keeps this person out of it, in words. For the log only.
func CBTalkGateReason(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> String {
  if npc.IsQuest() || npc.cbAuthoredState == 1 {
    return "part of a story or a job (a quest character)";
  }
  if npc.IsVendor() {
    return "a vendor";
  }
  if npc.IsPlayerCompanion() {
    return "V's companion";
  }
  if IsDefined(sys) && sys.NearTrackedPins(npc.GetWorldPosition(), CBConfig.TalkTrackedClearance()) {
    return "at the job V is tracking";
  }
  return "the game protects them (a stand-in, or not fully in the world)";
}

// Is Cyberbane's hub what the game's dialog list is showing?
public func CBTalkHubShown(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return false;
  }
  let hubs = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  for hub in hubs.choiceHubs {
    if hub.id == CBConfig.TalkHubId() {
      return true;
    }
  }
  return false;
}

// Who they are to V, read once as the prompt goes up.
public func CBTalkRead(sys: ref<CyberbaneSystem>, game: GameInstance, npc: ref<ScriptedPuppet>) -> ref<CBTalkTarget> {
  let score = sys.GetScore();
  if !IsDefined(score) || !IsDefined(npc) {
    return null;
  }
  let t = new CBTalkTarget();
  t.npc = npc;
  t.id = npc.GetEntityID();
  let faction = CBClassifyFaction(npc);
  t.cop = Equals(faction, n"NCPD");
  if !CBFactionOn(faction) {
    faction = n"";
  }
  t.faction = faction;
  t.recognized = CBRecognizes(sys, score, npc, faction, sys.GetCurrentDistrict());
  t.safe = sys.IsInSafeZone() || CBNpcInSafeInterior(npc);
  let ws = GameInstance.GetWorkspotSystem(game);
  t.atWork = IsDefined(ws) && ws.IsActorInWorkspot(npc);
  t.nerve = CBNerve(npc);
  let gang = NotEquals(faction, n"") && !t.cop;
  if gang {
    t.backers = CBSameGangNear(sys, npc, faction, CBConfig.HoldBackBackerRadius(), CBConfig.HoldBackMaxBackers());
  }
  // How afraid: what anybody can see, and for somebody who knows who V is, what V is known for. A gang V
  // has broken is afraid on top of that.
  let looks = (CBAppearanceThreat(score.GetLook(), score.GetChromeVisible()) + score.GetAura()) / 100.0;
  let fear = looks;
  if t.recognized {
    if gang {
      fear = MaxF(score.GetFactionFear(faction) / 100.0, looks);
    } else {
      fear = MaxF(CBCrowdFear(score, 1.0) / 100.0, looks);
    }
  }
  if gang && CBGangBroken(sys, faction) {
    fear += CBConfig.BrokenGangFear();
  }
  t.fear = fear;
  // How they stand with V.
  if t.cop {
    t.mood = CBTalkWary();
  } else {
    if gang {
      let posture = score.GetPosture(faction);
      if Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly) {
        t.mood = CBTalkFriendly();
      } else {
        if npc.cbHoldState == 1 || fear - t.nerve * CBConfig.HoldBackNerveWeight() >= CBConfig.TalkAfraidMargin() {
          t.mood = CBTalkAfraid();
        } else {
          if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
            t.mood = CBTalkHostile();
          } else {
            t.mood = CBTalkWary();
          }
        }
      }
    } else {
      if fear >= CBConfig.TalkCivAfraid() {
        t.mood = CBTalkAfraid();
      } else {
        if t.recognized && (score.GetRenown() >= CBConfig.TalkCivFanRenown() || sys.GetCode() >= 40.0) {
          t.mood = CBTalkFriendly();
        } else {
          t.mood = CBTalkWary();
        }
      }
    }
  }
  if gang || t.cop {
    t.speaker = CBFactionMemberWord(t.cop ? n"NCPD" : faction);
  }
  if StrLen(t.speaker) == 0 {
    t.speaker = gang ? "Ganger" : "Passer-by";
  }
  // One of their own V could make them give up.
  if gang && t.mood != CBTalkFriendly() {
    let lead = CBTalkLeadFor(sys, game, faction);
    if IsDefined(lead) {
      t.leadId = lead.id;
      t.leadName = CBRivalDisplayName(sys.GetContent(), lead);
    }
  }
  return t;
}

// A Rival of this gang whose hiding place is there to be told (Rivals/Whereabouts.reds), if any.
public func CBTalkLeadFor(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> ref<CBRival> {
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, faction) && CBWhereaboutsForSale(sys, game, r) == 0 {
      return r;
    }
  }
  return null;
}

// ---- The prompt ----------------------------------------------------------------------------------------

// Anything of the game's own on screen: a dialogue, an interaction prompt, a loot list.
public func CBNativePromptUp(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return true;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return true;
  }
  let dialogs = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  for hub in dialogs.choiceHubs {
    if hub.id != CBConfig.TalkHubId() {
      return true;
    }
  }
  let prompt = FromVariant<InteractionChoiceHubData>(bb.GetVariant(defs.InteractionChoiceHub));
  if prompt.active {
    return true;
  }
  let loot = FromVariant<LootData>(bb.GetVariant(defs.LootData));
  return loot.isActive;
}

// Is one of the game's own dialogues on screen (a hub that is not street talk's)? Texts wait for it (1.9.6).
public func CBGameDialogueUp(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return false;
  }
  let dialogs = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  for hub in dialogs.choiceHubs {
    if hub.id != CBConfig.TalkHubId() {
      return true;
    }
  }
  return false;
}

public func CBTalkPushHub(game: GameInstance, title: String, lines: array<ref<CBTalkLine>>, index: Int32) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return;
  }
  // Each line the way the game shows its own (1.9.6): an icon from the game's own choice icons, and the
  // choice type that highlights, dims or greys it (ChoiceTypeWrapper, as doors and terminals set it).
  let choices: array<ListChoiceData>;
  for line in lines {
    if IsDefined(line) {
      let c: ListChoiceData;
      c.localizedName = line.text;
      if TDBID.IsValid(line.icon) {
        // The record itself, as the game's devices hand it over (baseDeviceActions.script); a missing one
        // is simply no icon.
        let icon = TweakDBInterface.GetChoiceCaptionIconPartRecord(line.icon);
        if IsDefined(icon) {
          InteractionChoiceCaption.AddPartFromRecord(c.captionParts, icon);
        }
      }
      if line.important {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.QuestImportant);
      }
      if line.said {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.AlreadyRead);
      }
      if line.inactive {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.Inactive);
      }
      if line.illegal {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.Illegal);
      }
      ArrayPush(choices, c);
    }
  }
  let hub: ListChoiceHubData;
  hub.id = CBConfig.TalkHubId();
  hub.activityState = EVisualizerActivityState.Active;
  hub.title = title;
  hub.choices = choices;
  let list: array<ListChoiceHubData>;
  ArrayPush(list, hub);
  let hubs: DialogChoiceHubs;
  hubs.choiceHubs = list;
  bb.SetVariant(defs.DialogChoiceHubs, ToVariant(hubs), true);
  bb.SetInt(defs.ActiveChoiceHubID, hub.id, true);
  bb.SetInt(defs.SelectedIndex, index, true);
}

public func CBTalkSelect(game: GameInstance, index: Int32) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if IsDefined(bb) {
    bb.SetInt(defs.SelectedIndex, index, true);
  }
}

// Down again, only if what is up is still Cyberbane's: anything of the game's that replaced it stays.
public func CBTalkClearHub(game: GameInstance) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return;
  }
  let current = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  if ArraySize(current.choiceHubs) == 1 && current.choiceHubs[0].id == CBConfig.TalkHubId() {
    let empty: DialogChoiceHubs;
    bb.SetVariant(defs.DialogChoiceHubs, ToVariant(empty), true);
  }
  if bb.GetInt(defs.ActiveChoiceHubID) == CBConfig.TalkHubId() {
    bb.SetInt(defs.ActiveChoiceHubID, -1, true);
  }
}

// Who they are, and how they take V, over the choices.
public func CBTalkTitle(t: ref<CBTalkTarget>) -> String {
  let how = "";
  if t.mood == CBTalkFriendly() {
    how = "friendly";
  } else {
    if t.mood == CBTalkAfraid() {
      how = "afraid of you";
    } else {
      if t.mood == CBTalkHostile() {
        how = "hostile";
      } else {
        how = t.recognized ? "knows you" : "wary";
      }
    }
  }
  return t.speaker + " - " + how;
}

// What V can say, as "[Tag] words": the game shows the tag the way it shows its own. Each line carries
// what it does and how it is shown (1.9.6): an icon, dimmed once said to this person, the Rival question
// highlighted. After the first exchange the list comes back with a way to leave it there.
public func CBTalkChoices(sys: ref<CyberbaneSystem>, t: ref<CBTalkTarget>, followUp: Bool) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let gang = NotEquals(t.faction, n"") && !t.cop;
  let m = t.mood;
  let done = IsDefined(t.npc) ? t.npc.cbTalkDone : 0;
  // Greet.
  let greet = "";
  if m == CBTalkFriendly() {
    greet = gang ? "[Greet] Good to see you. How's the crew?" : "[Greet] Hey there.";
  } else {
    if m == CBTalkAfraid() {
      greet = "[Greet] Easy. I'm just saying hi.";
    } else {
      if m == CBTalkHostile() {
        greet = gang ? "[Parley] Easy. I'm not here to fight." : "[Greet] Relax. Not here for trouble.";
      } else {
        greet = t.cop ? "[Greet] Evening, officer." : "[Greet] Hey, choom.";
      }
    }
  }
  let parley = gang && m == CBTalkHostile();
  let g = CBTalkMakeLine(greet, CBTalkGreet(),
                         m == CBTalkFriendly() || parley ? t"ChoiceCaptionParts.HandshakeIcon" : t"ChoiceCaptionParts.TalkIcon");
  g.important = parley && !CBMaskHas(done, CBTalkGreet());
  g.said = CBMaskHas(done, CBTalkGreet());
  ArrayPush(out, g);
  // Dismiss.
  let dismiss = "";
  if m == CBTalkFriendly() {
    dismiss = "[Dismiss] Catch you later.";
  } else {
    if m == CBTalkAfraid() {
      dismiss = "[Dismiss] Get lost.";
    } else {
      dismiss = m == CBTalkHostile() ? "[Dismiss] Out of my way." : "[Dismiss] Not now.";
    }
  }
  let d = CBTalkMakeLine(dismiss, CBTalkDismiss(), t"ChoiceCaptionParts.BackOutIcon");
  d.said = CBMaskHas(done, CBTalkDismiss());
  ArrayPush(out, d);
  // Antagonize.
  let antagonize = "";
  if t.cop {
    antagonize = "[Antagonize] Shouldn't you be eating a donut somewhere?";
  } else {
    if !gang {
      antagonize = "[Antagonize] What are you looking at?";
    } else {
      if m == CBTalkFriendly() {
        antagonize = "[Antagonize] Your boss know you're this soft?";
      } else {
        if m == CBTalkAfraid() {
          antagonize = "[Antagonize] Boo.";
        } else {
          antagonize = m == CBTalkHostile() ? "[Antagonize] Your crew's a joke." : "[Antagonize] Got a problem?";
        }
      }
    }
  }
  let an = CBTalkMakeLine(antagonize, CBTalkAntagonize(), t"ChoiceCaptionParts.HitIcon");
  an.said = CBMaskHas(done, CBTalkAntagonize());
  ArrayPush(out, an);
  // Intimidate: what V leans with is how V works, and a name when there is one to get.
  let intimidate = "";
  let asks = false;
  if t.cop {
    intimidate = "[Intimidate] Back off, badge.";
  } else {
    if t.leadId > 0 {
      intimidate = "[Intimidate] Where's " + t.leadName + " hiding? Talk.";
      asks = true;
    } else {
      intimidate = "[Intimidate] " + CBTalkThreat(sys.GetPrimaryArchetypeIndex());
    }
  }
  let it = CBTalkMakeLine(intimidate, CBTalkIntimidate(),
                          asks ? t"ChoiceCaptionParts.BountyHuntIcon" : t"ChoiceCaptionParts.GrappleIcon");
  it.important = asks;
  it.said = CBMaskHas(done, CBTalkIntimidate());
  ArrayPush(out, it);
  // Leave it there, once something has been said.
  if followUp {
    let leave = m == CBTalkHostile() ? "[Leave] Not worth it." : (m == CBTalkFriendly() ? "[Leave] Take it easy." : "[Leave] Forget it.");
    ArrayPush(out, CBTalkMakeLine(leave, CBTalkActLeave(), TDBID.None()));
  }
  return out;
}

func CBTalkThreat(archetype: Int32) -> String {
  if archetype == EnumInt(ECBArchetype.Butcher) { return "Want to end up like the last ones?"; }
  if archetype == EnumInt(ECBArchetype.Ghost) { return "You never saw me. Keep it that way."; }
  if archetype == EnumInt(ECBArchetype.Professional) { return "This doesn't have to get ugly. Walk."; }
  if archetype == EnumInt(ECBArchetype.Chromed) { return "See these? Walk away."; }
  if archetype == EnumInt(ECBArchetype.Netrunner) { return "I could cook your implants from here."; }
  if archetype == EnumInt(ECBArchetype.Brawler) { return "I don't need a gun for you."; }
  return "Walk away. Now.";
}

// The words of a "[Tag] words" line.
public func CBTalkWords(line: String) -> String {
  if StrBeginsWith(line, "[") {
    let tag: String;
    let rest: String;
    if StrSplitFirst(line, "] ", tag, rest) {
      return rest;
    }
  }
  return line;
}

func CBTalkSay(line: String, vo: CName) -> ref<CBTalkAnswer> {
  let a = new CBTalkAnswer();
  a.line = line;
  a.vo = vo;
  return a;
}

// ---- What talking does to a reputation, a little at a time ----------------------------------------------
//
// Every change goes through these, which hold it to its ceiling for the day and gang (CBTalkTally in the
// play service) and do nothing at all while reputation is frozen.

func CBTalkTallyFor(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> ref<CBTalkTally> {
  let svc = sys.GetPlayService();
  if !IsDefined(svc) {
    return null;
  }
  let day = FloorF(CBGameSeconds(game) / CBConfig.SecondsPerDay());
  return svc.TalkTally(sys.GetPlaythroughId(), faction, day);
}

// Standing gained, up to `ceiling`.
func CBTalkWarm(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float, ceiling: Float) -> Float {
  if CBReputationFrozen() || Equals(faction, n"") || amount <= 0.0 {
    return 0.0;
  }
  let tally = CBTalkTallyFor(sys, game, faction);
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(tally) || !IsDefined(fs) || fs.standing >= ceiling {
    return 0.0;
  }
  let gain = MinF(MinF(amount, CBConfig.TalkWarmthPerDay() - tally.warmth), ceiling - fs.standing);
  if gain <= 0.0 {
    return 0.0;
  }
  fs.standing = ClampF(fs.standing + gain, -100.0, 100.0);
  // The first warmth of the day with this gang goes in the History (1.9.6), so V can see it worked.
  if tally.warmth <= 0.0 {
    CBFileLog(sys, n"TalkWarm", CBGameSeconds(game), CBEventDistrict(sys, game), faction, gain);
  }
  tally.warmth += gain;
  return gain;
}

// Standing lost.
func CBTalkSlight(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float) -> Float {
  if CBReputationFrozen() || Equals(faction, n"") || amount <= 0.0 {
    return 0.0;
  }
  let tally = CBTalkTallyFor(sys, game, faction);
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(tally) || !IsDefined(fs) {
    return 0.0;
  }
  let loss = MinF(amount, CBConfig.TalkSlightPerDay() - tally.slight);
  if loss <= 0.0 {
    return 0.0;
  }
  fs.standing = ClampF(fs.standing - loss, -100.0, 100.0);
  // The first offence of the day; a friend's first brush-off only marks the tally (0.01) and is not one.
  if tally.slight < 0.05 {
    CBFileLog(sys, n"TalkSlight", CBGameSeconds(game), CBEventDistrict(sys, game), faction, loss);
  }
  tally.slight += loss;
  return loss;
}

// How much their gang fears V: the gang's renown of V, which faction fear is built on (CBFactionFear). A
// gain is held to its daily ceiling; losing face is not.
func CBTalkFear(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float) -> Void {
  if CBReputationFrozen() || Equals(faction, n"") || amount == 0.0 {
    return;
  }
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  if amount > 0.0 {
    let tally = CBTalkTallyFor(sys, game, faction);
    if !IsDefined(tally) {
      return;
    }
    let gain = MinF(amount, CBConfig.TalkFearPerDay() - tally.fear);
    if gain <= 0.0 {
      return;
    }
    if tally.fear <= 0.0 {
      CBFileLog(sys, n"TalkFear", CBGameSeconds(game), CBEventDistrict(sys, game), faction, gain);
    }
    tally.fear += gain;
    fs.renown = ClampF(fs.renown + gain, 0.0, 100.0);
    fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
    return;
  }
  fs.renown = ClampF(fs.renown + amount, 0.0, 100.0);
}

// Conduct, either way, held to a daily total per gang (n"" for people with no gang).
func CBTalkConduct(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, delta: Float) -> Void {
  if CBReputationFrozen() || delta == 0.0 {
    return;
  }
  let tally = CBTalkTallyFor(sys, game, faction);
  if !IsDefined(tally) {
    return;
  }
  let room = CBConfig.TalkConductPerDay() - tally.conduct;
  if room <= 0.0 {
    return;
  }
  let step = delta > 0.0 ? MinF(delta, room) : MaxF(delta, -room);
  tally.conduct += AbsF(step);
  sys.AddCode(step);
}

// A ganger's odds against V's fear: above zero they fold, below it they stand.
func CBTalkNerveGap(t: ref<CBTalkTarget>) -> Float {
  return t.fear - t.nerve * CBConfig.HoldBackNerveWeight() - Cast<Float>(t.backers) * CBConfig.HoldBackPerBacker();
}

// Sent on their way: one move order, never more (Reactions/Morale.reds, CBOrderFlee). Somebody at a workspot
// is never given one (S-03): the fear stim lets the game take them out of it its own way. In a safe place
// they stay where they are; the words did it.
func CBTalkSendOff(game: GameInstance, t: ref<CBTalkTarget>) -> Bool {
  let npc = IsDefined(t) ? t.npc : null;
  if !IsDefined(npc) || npc.cbTalkSent {
    return false;
  }
  npc.cbTalkSent = true;
  let sysSent = CyberbaneSystem.Get(game);
  npc.cbTalkSentTick = IsDefined(sysSent) ? Max(sysSent.GetTickCount(), 1) : 1;
  // Whoever V has sent packing holds back from V from now on (1.9.5): a vendetta ganger talked down
  // in their warning was otherwise turned on V by the Director a second later, mid-retreat.
  npc.cbHoldState = 1;
  if t.safe {
    return false;
  }
  if t.atWork {
    CBTalkScare(GetPlayer(game), t, 1);
    return true;
  }
  return CBOrderFlee(game, npc);
}

// A civilian frightened by V, the way the crowd reactions frighten them (Reactions/Crowd.reds): the one
// stim the game lets a sender choose the stage of, from V, and it stops with them.
func CBTalkScare(player: ref<PlayerPuppet>, t: ref<CBTalkTarget>, stage: Int32) -> Void {
  let npc = IsDefined(t) ? t.npc : null;
  if !IsDefined(player) || !IsDefined(npc) || !npc.IsAttached() || t.safe {
    return;   // nobody is sent screaming out of a bar
  }
  let data: stimInvestigateData;
  data.fearPhase = stage;
  StimBroadcasterComponent.SendStimDirectly(player, gamedataStimType.SpreadFear, npc, data);
}

// Picking a fight: the Director turns them, so it is tracked and reverted like every attitude Cyberbane
// sets, and the gangs at war with theirs hear about it.
func CBTalkFight(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> Bool {
  if t.safe {
    return false;   // not in here: the answer is words ("Not here. Not now. But soon.")
  }
  let director = sys.GetDirector();
  if !IsDefined(director) || !director.TurnHostileFromTalk(player, t.npc, t.faction) {
    return false;
  }
  let lost = CBTalkSlight(sys, game, t.faction, CBConfig.TalkFightCost());
  if lost > 0.0 {
    CBCreditRivalGangs(sys, game, t.faction, -lost);
  }
  return true;
}

// ---- Greet ---------------------------------------------------------------------------------------------

func CBTalkOnGreet(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  // Credit for saying hello once to each person; saying it again is just being friendly.
  let first = t.first;
  if t.cop {
    return CBTalkSay(CBWhisperPick3("Move along, citizen.", "Keep it clean tonight.", "Mhm. Don't make me run your ID."), n"");
  }
  if !gang {
    if t.mood == CBTalkAfraid() {
      return CBTalkSay(CBWhisperPick3("H-hi. I don't want any trouble.", "Please, I'm just going home.", "Okay. Okay. Hi."), n"fear_beg");
    }
    if first {
      CBTalkConduct(sys, game, n"", CBConfig.TalkGreetConduct());
    }
    if t.mood == CBTalkFriendly() {
      let title = CBWhisperTitle(sys);
      if StrLen(title) > 0 {
        return CBTalkSay(CBWhisperPick3("No way. " + title + ", saying hi to me?", "Wait till I tell everyone. " + title + "!", "Hey! Big fan. Seriously."), n"greeting");
      }
      return CBTalkSay(CBWhisperPick3("Hey! Good to see you around.", "Evening. Stay safe out there.", "Heard good things about you."), n"greeting");
    }
    return CBTalkSay(CBWhisperPick4("Hey.", "Evening.", "Uh. Hi.", "Do I know you?"), n"greeting");
  }
  let label = StrLen(CBFactionLabel(t.faction)) > 0 ? CBFactionLabel(t.faction) : "the crew";
  if t.mood == CBTalkFriendly() {
    if first {
      CBTalkWarm(sys, game, t.faction, CBConfig.TalkGreetWarmth(), CBConfig.PostureAllied() - 1.0);
    }
    // A friend may have word on their enemies.
    let tip = CBTalkFriendTip(sys, game, player, t);
    if StrLen(tip) > 0 {
      return CBTalkSay(tip, n"greeting");
    }
    return CBTalkSay(CBWhisperPick4("Good to see you, choom.", "Always welcome here.", "You need anything, you ask " + label + ".", "The boss says hi."), n"greeting");
  }
  if t.mood == CBTalkAfraid() {
    // Saying hello to somebody who expected worse: mercy, in a small way, and the way back from a
    // grudge that does not cost eddies (CBCreditMercy keeps it under MercyCeiling).
    if first && !CBReputationFrozen() {
      let tally = CBTalkTallyFor(sys, game, t.faction);
      if IsDefined(tally) && tally.warmth < CBConfig.TalkWarmthPerDay() {
        let fs = sys.EnsureFaction(t.faction);
        let before = IsDefined(fs) ? fs.standing : 0.0;
        CBCreditMercy(sys, t.faction, CBConfig.TalkGreetMercy());
        if IsDefined(fs) {
          tally.warmth += MaxF(0.0, fs.standing - before);
        }
      }
    }
    return CBTalkSay(CBWhisperPick3("We good? We're good. Right?", "Hey. Yeah. Hi. I'm not looking for anything.", "Didn't see you. Whatever you need, it's fine."), n"fear_beg");
  }
  if t.mood == CBTalkHostile() {
    // The parley (1.9.6), once per person: talked down, they and the crew standing with them back off for
    // good (they hold back from V, as the frightened do, CBHoldsBackFromV); not, and they are as they were,
    // which for a gang at war with V means the fight starts once the talk is over.
    if first && !CBReputationFrozen() {
      let chance = ClampF(CBTalkNerveGap(t) * CBConfig.ParleyScale() + CBConfig.ParleyBase(),
                          CBConfig.ParleyMin(), CBConfig.ParleyMax());
      if RandF() < chance * sys.WornPerk().breakMult {
        let calmed = CBTalkParleyCrew(sys, t);
        CBLog.Info(n"Talk", s"Parley held with one of \(NameToString(t.faction)); \(calmed) of their crew back off with them.");
        return CBTalkSay(CBWhisperPick3("Fine. Walk away. This time.", "You've got nerve. Go on, before I change my mind.", "Alright. Nobody here saw you."), n"");
      }
      CBLog.Info(n"Talk", s"Parley refused by one of \(NameToString(t.faction)).");
    }
    return CBTalkSay(CBWhisperPick3("You've got nerve, walking up to me.", "Keep walking before I change my mind.", "Not your street. Not your friend."), n"bump");
  }
  if first {
    CBTalkWarm(sys, game, t.faction, CBConfig.TalkGreetWarmth(), CBConfig.MercyCeiling());
  }
  return CBTalkSay(CBWhisperPick3("Hey. You're all right, I guess.", "Choom.", "Evening. Keep it friendly."), n"greeting");
}

// A friend of V's passing on where one of their enemies' Rivals is: once a day per gang.
func CBTalkFriendTip(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> String {
  if !CBHideoutsOn() || IsDefined(CBCurrentLead(sys, game)) {
    return "";
  }
  let tally = CBTalkTallyFor(sys, game, t.faction);
  if !IsDefined(tally) || tally.tips >= CBConfig.TalkTipsPerDay() || RandF() > CBConfig.TalkTipChance() {
    return "";
  }
  let enemies = CBGangRivalsOf(sys.GetContent(), t.faction);
  for r in sys.GetRivals() {
    if IsDefined(r) && ArrayContains(enemies, r.faction) && CBWhereaboutsForSale(sys, game, r) == 0 {
      let s = CBRivalHideout(sys, game, player, r);
      if IsDefined(s) {
        CBMarkLeadTold(sys, s, t.faction, CBGameSeconds(game));
        tally.tips += 1;
        let name = CBRivalDisplayName(sys.GetContent(), r);
        let pin = CBMapMarkersOn() ? " Put it on your map." : "";
        CBLog.Info(n"Talk", s"A friend of \(NameToString(t.faction)) gave up rival \(r.id).");
        return s"Since you're here: \(name) has been seen \(CBPlacePhrase(s.district)). Do us a favour.\(pin)";
      }
    }
  }
  return "";
}

// ---- Dismiss -------------------------------------------------------------------------------------------

func CBTalkOnDismiss(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  if t.cop {
    return CBTalkSay(CBWhisperPick2("Watch the attitude.", "Sure. Move along."), n"");
  }
  if t.mood == CBTalkAfraid() {
    if gang {
      CBTalkFear(sys, game, t.faction, CBConfig.TalkDismissFear());
      CBTalkSendOff(game, t);
    } else {
      CBTalkScare(player, t, 1);
    }
    return CBTalkSay(CBWhisperPick3("Going. I'm going.", "Sorry. Sorry.", "You got it."), n"fear_beg");
  }
  if gang && t.mood == CBTalkFriendly() {
    // Blanking friends once is nothing. Doing it all day is noticed.
    let tally = CBTalkTallyFor(sys, game, t.faction);
    if IsDefined(tally) && tally.slight > 0.0 {
      CBTalkSlight(sys, game, t.faction, CBConfig.TalkDismissFriendCost());
    } else {
      if IsDefined(tally) {
        tally.slight += 0.01;
      }
    }
    return CBTalkSay(CBWhisperPick2("Whatever, choom.", "Busy, huh? Fine."), n"");
  }
  if t.mood == CBTalkHostile() {
    return CBTalkSay(CBWhisperPick2("Watch yourself.", "Walk while you can."), n"bump");
  }
  return CBTalkSay(CBWhisperPick3("Fine.", "Yeah, yeah.", "Your loss."), n"");
}

// ---- Antagonize ----------------------------------------------------------------------------------------

func CBTalkOnAntagonize(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  // The law answers in words, always.
  if t.cop {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkCopCost());
    CBTalkConduct(sys, game, n"", -CBConfig.TalkBullyConduct());
    return CBTalkSay(CBWhisperPick3("Real funny. Move it before I run your ID.", "Keep talking and see where it gets you.", "I've got your face now, merc."), n"bump");
  }
  if !gang {
    CBTalkConduct(sys, game, n"", -CBConfig.TalkCivAntagonizeConduct());
    if t.mood == CBTalkAfraid() || RandF() < t.fear {
      CBTalkScare(player, t, t.fear >= CBConfig.TalkCivAfraid() ? 3 : 2);
      return CBTalkSay(CBWhisperPick3("Leave me alone!", "I don't want trouble!", "Psycho!"), n"fear_beg");
    }
    return CBTalkSay(CBWhisperPick3("The hell's your problem?", "Get out of my face.", "Real tough. Go bother someone else."), n"bump");
  }
  if t.mood == CBTalkFriendly() {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultFriendCost());
    return CBTalkSay(CBWhisperPick3("Not funny, choom. Not funny at all.", "Careful. Friends have limits.", "Say that again and we're done."), n"bump");
  }
  if t.mood == CBTalkHostile() {
    if CBTalkFight(sys, game, player, t) {
      return CBTalkSay(CBWhisperPick3("You're dead.", "Big mistake.", "Been waiting for this."), n"");
    }
    return CBTalkSay("Not here. Not now. But soon.", n"bump");
  }
  let gap = CBTalkNerveGap(t) + RandRangeF(-0.15, 0.15);
  if t.mood == CBTalkAfraid() || gap > CBConfig.TalkFoldGap() {
    // Most fold. A few snap.
    if t.mood == CBTalkAfraid() && RandF() < CBConfig.TalkSnapChance() && CBTalkFight(sys, game, player, t) {
      return CBTalkSay(CBWhisperPick2("I'm not running from you!", "Enough! ENOUGH!"), n"");
    }
    CBTalkFear(sys, game, t.faction, CBConfig.TalkFoldFear());
    CBTalkConduct(sys, game, t.faction, -CBConfig.TalkBullyConduct());
    CBTalkSendOff(game, t);
    return CBTalkSay(CBWhisperPick3("Okay, okay! Forget it!", "Not worth it. Not worth it.", "Whatever you say."), n"fear_beg");
  }
  if gap < -CBConfig.TalkFoldGap() && CBTalkFight(sys, game, player, t) {
    return CBTalkSay(CBWhisperPick3("Alright. Let's dance.", "You picked the wrong one.", "Say that to my face. Oh wait."), n"");
  }
  CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultCost());
  return CBTalkSay(CBWhisperPick3("Keep running your mouth, see what happens.", "Big talk. Walk away.", "Another word and you're bleeding."), n"bump");
}

// ---- Intimidate ----------------------------------------------------------------------------------------

func CBTalkOnIntimidate(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  if t.cop {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkCopCost() * 2.0);
    CBTalkConduct(sys, game, n"", -CBConfig.TalkBullyConduct());
    return CBTalkSay(CBWhisperPick2("Threatening an officer? Bold.", "Try that again. I dare you."), n"bump");
  }
  let npc = t.npc;
  let immovable = npc.IsBoss() || CBHoldsGround(npc);
  // What V leans with: their fear, and what V looks like doing it.
  let chance = CBTalkNerveGap(t) * CBConfig.TalkIntimidateScale() + CBConfig.TalkIntimidateBase();
  if t.mood == CBTalkAfraid() {
    chance += CBConfig.TalkAfraidBonus();
  }
  chance = ClampF(chance * sys.WornPerk().breakMult, CBConfig.TalkIntimidateMin(), CBConfig.TalkIntimidateMax());
  if !gang {
    if !immovable && RandF() < chance {
      CBTalkScare(player, t, 3);
      CBTalkConduct(sys, game, n"", -CBConfig.TalkCivIntimidateConduct());
      if !CBReputationFrozen() {
        let tally = CBTalkTallyFor(sys, game, n"");
        if IsDefined(tally) && tally.fear < CBConfig.TalkFearPerDay() {
          tally.fear += CBConfig.TalkCivDread();
          sys.AddDeedDreadPoints(CBConfig.TalkCivDread());
        }
      }
      return CBTalkSay(CBWhisperPick3("Okay! I'm going!", "Please, I didn't see anything!", "Don't hurt me!"), n"fear_beg");
    }
    return CBTalkSay(CBWhisperPick3("Yeah? Whatever, poser.", "Is that supposed to scare me?", "Go practise on someone else."), n"bump");
  }
  if t.mood == CBTalkFriendly() {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkLeanOnFriendCost());
    return CBTalkSay(CBWhisperPick2("Whoa. Okay. No need for that, choom.", "That's how you treat friends? Noted."), n"bump");
  }
  if immovable || RandF() >= chance {
    // Lost face. And somebody with the nerve, or the grudge, takes it further.
    CBTalkFear(sys, game, t.faction, -CBConfig.TalkLostFace());
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultCost() * 0.5);
    if (t.mood == CBTalkHostile() || CBTalkNerveGap(t) < -CBConfig.TalkFoldGap()) && RandF() < CBConfig.TalkCallBluffFight()
       && CBTalkFight(sys, game, player, t) {
      return CBTalkSay(CBWhisperPick2("Let's see you back that up.", "Wrong one to push."), n"");
    }
    return CBTalkSay(CBWhisperPick3("That supposed to scare me?", "Heard of you. Thought you'd be scarier.", "Walk away while I'm feeling generous."), n"bump");
  }
  // It worked. What they give up depends on what they have.
  CBTalkFear(sys, game, t.faction, CBConfig.TalkLeanFear());
  CBTalkSlight(sys, game, t.faction, CBConfig.TalkLeanCost());
  npc.cbHoldState = 1;   // leaned on and folded: they will not draw on V after this (1.9.5)
  let told = CBTalkInform(sys, game, player, t);
  if StrLen(told) > 0 {
    CBTalkSendOff(game, t);
    return CBTalkSay(told, n"fear_beg");
  }
  let paid = CBTalkShakedown(sys, game, player, t);
  if paid > 0 {
    return CBTalkSay(CBWhisperPick3(s"Here. \(paid). Take it and go.", s"\(paid) eddies. That's all I got, I swear.", s"Fine! \(paid). We're square, right?"), n"fear_beg");
  }
  CBTalkSendOff(game, t);
  return CBTalkSay(CBWhisperPick3("Alright, alright! I'm gone.", "I'm leaving. Look, I'm leaving.", "Didn't mean anything by it!"), n"fear_beg");
}

// Somebody leaned on hard enough gives up where one of their own gang's Rivals is lying low: the same
// lead the Hub sells, free, once per gang a day. "" when there was nothing to give up.
func CBTalkInform(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> String {
  if t.leadId <= 0 || !CBHideoutsOn() {
    return "";
  }
  let tally = CBTalkTallyFor(sys, game, t.faction);
  if !IsDefined(tally) || tally.leaks >= CBConfig.TalkLeaksPerDay() {
    return "";
  }
  let r = sys.FindRivalById(t.leadId);
  if !IsDefined(r) || CBWhereaboutsForSale(sys, game, r) != 0 {
    return "";
  }
  let s = CBRivalHideout(sys, game, player, r);
  if !IsDefined(s) {
    return "";
  }
  let now = CBGameSeconds(game);
  CBMarkLeadTold(sys, s, n"", now);
  tally.leaks += 1;
  CBFileLog(sys, n"Informant", now, CBEventDistrict(sys, game), t.faction, Cast<Float>(r.id));
  CBLog.Info(n"Talk", s"Leaned on one of \(NameToString(t.faction)): rival \(r.id) is \(NameToString(s.district)).");
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let place = CBPlacePhrase(s.district);
  let pin = CBMapMarkersOn() ? " It's on your map." : "";
  return CBWhisperPick3(
    s"Fine! \(name)'s lying low \(place). You didn't hear it from me.\(pin)",
    s"\(name)? Holed up \(place). Please, just go.\(pin)",
    s"Okay! \(name), \(place). Last I heard. That's all I know.\(pin)");
}

// Paying V to go away: street tax, scaled to V's level, once per gang a day. 0 when nothing was paid.
func CBTalkShakedown(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> Int32 {
  if !CBShakedownsOn() || CBReputationFrozen() {
    return 0;
  }
  let tally = CBTalkTallyFor(sys, game, t.faction);
  let ts = GameInstance.GetTransactionSystem(game);
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(tally) || !IsDefined(ts) || tally.taxes >= CBConfig.TalkTaxesPerDay() {
    return 0;
  }
  let level = IsDefined(stats) ? stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Level) : 1.0;
  let amount = Min(CBConfig.TalkTaxMax(), RoundF(CBConfig.TalkTaxBase() + level * CBConfig.TalkTaxPerLevel()
                                                * RandRangeF(0.7, 1.3)));
  if amount <= 0 {
    return 0;
  }
  ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
  tally.taxes += 1;
  // Extortion is not how a professional works.
  CBTalkConduct(sys, game, t.faction, -CBConfig.TalkShakedownConduct());
  CBFileLog(sys, n"ShakeDown", CBGameSeconds(game), CBEventDistrict(sys, game), t.faction, Cast<Float>(amount));
  CBLog.Info(n"Talk", s"Shook down one of \(NameToString(t.faction)) for \(amount)eb.");
  return amount;
}
