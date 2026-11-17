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
// ways to change a gang's mind that do not go through a body, which players asked for (IMPROVEMENTS,
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

public class CBStreetTalk {
  private let m_game: GameInstance;
  private let m_generation: Int32;
  private let m_input: ref<CBTalkInput>;
  private let m_listening: wref<PlayerPuppet>;

  // The prompt on screen, if any.
  private let m_shown: Bool;
  private let m_index: Int32;
  private let m_target: ref<CBTalkTarget>;
  private let m_lines: array<String>;
  private let m_lostFor: Float;
  private let m_handsHeld: Bool;
  // Whether this session has made sure the lock is off (see OnTick).
  private let m_handsChecked: Bool;

  // Somebody V is looking at and how long for, before the prompt comes up.
  private let m_candidate: wref<ScriptedPuppet>;
  private let m_dwell: Float;

  // A choice made, waiting for the answer.
  // Field defaults cannot be negative in redscript, so whether a choice is waiting is its own flag.
  private let m_pending: Int32;
  private let m_hasPending: Bool;
  private let m_pendingTarget: ref<CBTalkTarget>;
  private let m_pendingIn: Float;

  // The two subtitle lines of an exchange: V's, then theirs (UI/PhoneMessages.reds slots 2 and 3).
  private let m_vLineLeft: Float;
  private let m_replyLeft: Float;

  // Keeping one notch of the wheel to one step (see Scroll).
  // After V reached for a weapon with the prompt up, how long before it may come up again (seconds).
  private let m_quietLeft: Float;
  private let m_lastScrollAt: Float;
  private let m_lastScrollStep: Int32;
  private let m_lastScrollByWeapon: Bool;
  private let m_choiceScrollSeen: Bool;

  public func Start(game: GameInstance) -> Void {
    this.m_game = game;
    this.m_generation += 1;
    this.m_shown = false;
    this.m_target = null;
    this.m_candidate = null;
    this.m_dwell = 0.0;
    this.m_hasPending = false;
    this.m_pendingTarget = null;
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
    return this.m_shown;
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
      this.StandDown(game);
      return;
    }
    // An answer that is due. Only with the world settled; otherwise the moment has passed.
    if this.m_hasPending {
      this.m_pendingIn -= dt;
      if this.m_pendingIn <= 0.0 {
        let choice = this.m_pending;
        let target = this.m_pendingTarget;
        this.m_hasPending = false;
        this.m_pendingTarget = null;
        if CBWorldStable(game) && CBStreetTalkOn() {
          this.Answer(sys, game, player, target, choice);
        }
      }
    }
    if !this.Allowed(sys, game, player) {
      this.StandDown(game);
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
    if !this.m_shown {
      this.StopListening();
    }
    let npc = this.LookedAt(game, player);
    if this.m_shown {
      let same = IsDefined(npc) && IsDefined(this.m_target) && Equals(npc.GetEntityID(), this.m_target.id);
      let held = IsDefined(this.m_target) && CBTalkEligible(sys, game, player, this.m_target.npc, CBConfig.TalkKeepRange());
      if !held || CBNativePromptUp(game) {
        this.Close(game);
        return;
      }
      // A glance away is not walking off: a moment's grace before the prompt goes.
      this.m_lostFor = same ? 0.0 : this.m_lostFor + dt;
      if this.m_lostFor > CBConfig.TalkLookGrace() {
        this.Close(game);
      }
      return;
    }
    // Nothing up: is V settling on somebody?
    if this.m_hasPending || this.m_quietLeft > 0.0 || !IsDefined(npc) || IsDefined(GameObject.GetActiveWeapon(player))
       || !CBTalkEligible(sys, game, player, npc, CBConfig.TalkRange()) || CBNativePromptUp(game) {
      this.m_candidate = null;
      this.m_dwell = 0.0;
      return;
    }
    let cand = this.m_candidate;
    if IsDefined(cand) && Equals(cand.GetEntityID(), npc.GetEntityID()) {
      this.m_dwell += dt;
    } else {
      this.m_candidate = npc;
      this.m_dwell = 0.0;
    }
    if this.m_dwell >= CBConfig.TalkDwell() {
      this.Open(sys, game, player, npc);
    }
  }

  // Everything that has to be true for anybody to be talked to at all.
  private func Allowed(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Bool {
    if !CBStreetTalkOn() || !CBWorldStable(game) || CBPlayerInScene(game) {
      return false;
    }
    if sys.GetStoryHold() != CBStoryNone() || sys.IsInSafeZone() || sys.IsInQuestArea() || !sys.WornReady() {
      return false;
    }
    if player.IsInCombat() || VehicleComponent.IsMountedToVehicle(game, player.GetEntityID()) {
      return false;
    }
    // Nobody sneaks up on somebody to say hello (1.9.5). Crouched behind a ganger for a takedown, the
    // prompt came up instead, and V's hands were held while it was up.
    if CBPlayerSneaking(game) {
      return false;
    }
    return true;
  }

  private func LookedAt(game: GameInstance, player: ref<PlayerPuppet>) -> ref<ScriptedPuppet> {
    let targeting = GameInstance.GetTargetingSystem(game);
    if !IsDefined(targeting) {
      return null;
    }
    return targeting.GetLookAtObject(player, true, true) as ScriptedPuppet;
  }

  private func Open(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, npc: ref<ScriptedPuppet>) -> Void {
    let t = CBTalkRead(sys, game, npc);
    if !IsDefined(t) {
      return;
    }
    this.m_target = t;
    this.m_lines = CBTalkChoices(sys, t);
    this.m_index = 0;
    this.m_lostFor = 0.0;
    this.m_dwell = 0.0;
    this.m_candidate = null;
    CBTalkPushHub(game, CBTalkTitle(t), this.m_lines, this.m_index);
    this.m_shown = true;
    this.Listen(player);
    // Hands stay empty while V talks, so the wheel picks a line instead of drawing a gun.
    if !this.m_handsHeld {
      CBQueueZoneArmsLock(player, true);
      this.m_handsHeld = true;
    }
    // They notice V.
    let reactions = npc.GetStimReactionComponent();
    if IsDefined(reactions) {
      reactions.CBGlanceAt(player);
    }
  }

  // The prompt comes down. The keys are let go on the next tick.
  private func Close(game: GameInstance) -> Void {
    if this.m_shown {
      CBTalkClearHub(game);
    }
    this.m_shown = false;
    this.m_target = null;
    this.m_lostFor = 0.0;
    this.ReleaseHands(game);
  }

  private func StandDown(game: GameInstance) -> Void {
    this.Close(game);
    this.StopListening();
    this.m_candidate = null;
    this.m_dwell = 0.0;
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
    // Reaching for a weapon closes the prompt (1.9.5). V's hands are held while it is up, so the scroll
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

  public func OnInput(action: ListenerAction) -> Void {
    if !this.m_shown {
      return;
    }
    let name = ListenerAction.GetName(action);
    let kind = ListenerAction.GetType(action);
    let pressed = Equals(kind, gameinputActionType.BUTTON_PRESSED);
    if CBTalkReachKey(name) {
      if pressed || Equals(kind, gameinputActionType.BUTTON_HOLD_COMPLETE) {
        this.Close(this.m_game);
        this.m_quietLeft = CBConfig.TalkQuietAfterReach();
      }
      return;
    }
    if Equals(name, n"ChoiceApply") || Equals(name, n"Choice1") {
      if pressed {
        this.Choose();
      }
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

  // V says it. The words go up at once; the answer and everything it does comes on the tick.
  private func Choose() -> Void {
    if !this.m_shown || !IsDefined(this.m_target) || this.m_index < 0 || this.m_index >= ArraySize(this.m_lines) {
      return;
    }
    this.m_pending = this.m_index;
    this.m_hasPending = true;
    this.m_pendingTarget = this.m_target;
    this.m_pendingIn = CBConfig.TalkAnswerDelay();
    if CBGameSubtitlesOn(this.m_game)
       && CBShowGameSubtitle(this.m_game, 2, "V", CBTalkWords(this.m_lines[this.m_index]), CBConfig.TalkLineSeconds()) {
      this.m_vLineLeft = CBConfig.TalkLineSeconds();
    }
    CBTalkClearHub(this.m_game);
    this.m_shown = false;
    this.m_target = null;
    this.ReleaseHands(this.m_game);
  }

  // ---- The answer ----------------------------------------------------------------------------------

  private func Answer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                      t: ref<CBTalkTarget>, choice: Int32) -> Void {
    if !IsDefined(t) {
      return;
    }
    let npc = t.npc;
    // Gone, down or already fighting by now: nobody left to answer.
    if !IsDefined(npc) || !npc.IsAttached() || npc.IsDead() || ScriptedPuppet.IsDefeated(npc)
       || CBNpcInCombat(npc) {
      return;
    }
    npc.cbTalkTick = Max(sys.GetTickCount(), 1);
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
    if !IsDefined(a) {
      return;
    }
    // In the game's subtitles; with those switched off, on Cyberbane's own line, so the answer is
    // never lost (UI/PhoneMessages.reds, CBOverheard).
    if StrLen(a.line) > 0 {
      if CBGameSubtitlesOn(game) {
        if CBShowGameSubtitle(game, 3, t.speaker, a.line, CBConfig.TalkReplySeconds()) {
          this.m_replyLeft = CBConfig.TalkReplySeconds();
        }
      } else {
        CBOverheard(game, t.speaker, a.line);
      }
    }
    if NotEquals(a.vo, n"") && npc.IsAttached() {
      GameObject.PlayVoiceOver(npc, a.vo, n"Scripts:CBStreetTalk");
    }
    let reactions = npc.GetStimReactionComponent();
    if IsDefined(reactions) && npc.IsAttached() && !npc.cbTalkSent {
      reactions.CBGlanceAt(player);
    }
    sys.GetScore().MarkDirty();
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

// ---- Who can be talked to ------------------------------------------------------------------------------

public func CBTalkEligible(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                           npc: wref<ScriptedPuppet>, range: Float) -> Bool {
  if !IsDefined(npc) || !IsDefined(player) || !npc.IsAttached() || npc.IsDead() || ScriptedPuppet.IsDefeated(npc)
     || !CBStillStanding(npc) {
    return false;
  }
  if !npc.IsHuman() || npc.IsMechanical() || npc.cbMoraleBroken || npc.cbTalkSent {
    return false;
  }
  if Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > range {
    return false;
  }
  if npc.cbTalkTick > 0 && (sys.GetTickCount() - npc.cbTalkTick) < CBConfig.TalkCooldownTicks() {
    return false;
  }
  if !CBNpcSafe(sys, npc) || !CBSafetyGate.CanAffect(npc) {
    return false;
  }
  if CBSentByUs(GameInstance.GetDynamicEntitySystem(), npc) || CBNpcInCombat(npc) {
    return false;
  }
  if sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.QuestSpawnClearance()) {
    return false;
  }
  if VehicleComponent.IsMountedToVehicle(game, npc.GetEntityID()) {
    return false;
  }
  if Equals(CBClassifyFaction(npc), n"MaxTac") {
    return false;
  }
  let agent = npc.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) && Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
    return false;
  }
  return true;
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

public func CBTalkPushHub(game: GameInstance, title: String, lines: array<String>, index: Int32) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return;
  }
  let choices: array<ListChoiceData>;
  for line in lines {
    let c: ListChoiceData;
    c.localizedName = line;
    ArrayPush(choices, c);
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

// What V can say, as "[Tag] words": the game shows the tag the way it shows its own.
public func CBTalkChoices(sys: ref<CyberbaneSystem>, t: ref<CBTalkTarget>) -> array<String> {
  let out: array<String>;
  let gang = NotEquals(t.faction, n"") && !t.cop;
  let m = t.mood;
  // Greet.
  if m == CBTalkFriendly() {
    ArrayPush(out, gang ? "[Greet] Good to see you. How's the crew?" : "[Greet] Hey there.");
  } else {
    if m == CBTalkAfraid() {
      ArrayPush(out, "[Greet] Easy. I'm just saying hi.");
    } else {
      if m == CBTalkHostile() {
        ArrayPush(out, "[Greet] Relax. Not here for trouble.");
      } else {
        ArrayPush(out, t.cop ? "[Greet] Evening, officer." : "[Greet] Hey, choom.");
      }
    }
  }
  // Dismiss.
  if m == CBTalkFriendly() {
    ArrayPush(out, "[Dismiss] Catch you later.");
  } else {
    if m == CBTalkAfraid() {
      ArrayPush(out, "[Dismiss] Get lost.");
    } else {
      ArrayPush(out, m == CBTalkHostile() ? "[Dismiss] Out of my way." : "[Dismiss] Not now.");
    }
  }
  // Antagonize.
  if t.cop {
    ArrayPush(out, "[Antagonize] Shouldn't you be eating a donut somewhere?");
  } else {
    if !gang {
      ArrayPush(out, "[Antagonize] What are you looking at?");
    } else {
      if m == CBTalkFriendly() {
        ArrayPush(out, "[Antagonize] Your boss know you're this soft?");
      } else {
        if m == CBTalkAfraid() {
          ArrayPush(out, "[Antagonize] Boo.");
        } else {
          ArrayPush(out, m == CBTalkHostile() ? "[Antagonize] Your crew's a joke." : "[Antagonize] Got a problem?");
        }
      }
    }
  }
  // Intimidate: what V leans with is how V works, and a name when there is one to get.
  if t.cop {
    ArrayPush(out, "[Intimidate] Back off, badge.");
  } else {
    if t.leadId > 0 {
      ArrayPush(out, "[Intimidate] Where's " + t.leadName + " hiding? Talk.");
    } else {
      ArrayPush(out, "[Intimidate] " + CBTalkThreat(sys.GetPrimaryArchetypeIndex()));
    }
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

// Sent on their way: one move order, never more (Reactions/Morale.reds, CBOrderFlee).
func CBTalkSendOff(game: GameInstance, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) || npc.cbTalkSent {
    return false;
  }
  npc.cbTalkSent = true;
  return CBOrderFlee(game, npc);
}

// A civilian frightened by V, the way the crowd reactions frighten them (Reactions/Crowd.reds): the one
// stim the game lets a sender choose the stage of, from V, and it stops with them.
func CBTalkScare(player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>, stage: Int32) -> Void {
  if !IsDefined(player) || !IsDefined(npc) || !npc.IsAttached() {
    return;
  }
  let data: stimInvestigateData;
  data.fearPhase = stage;
  StimBroadcasterComponent.SendStimDirectly(player, gamedataStimType.SpreadFear, npc, data);
}

// Picking a fight: the Director turns them, so it is tracked and reverted like every attitude Cyberbane
// sets, and the gangs at war with theirs hear about it.
func CBTalkFight(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> Bool {
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
      CBTalkSendOff(game, t.npc);
    } else {
      CBTalkScare(player, t.npc, 1);
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
      CBTalkScare(player, t.npc, t.fear >= CBConfig.TalkCivAfraid() ? 3 : 2);
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
    CBTalkSendOff(game, t.npc);
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
      CBTalkScare(player, npc, 3);
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
  let told = CBTalkInform(sys, game, player, t);
  if StrLen(told) > 0 {
    CBTalkSendOff(game, npc);
    return CBTalkSay(told, n"fear_beg");
  }
  let paid = CBTalkShakedown(sys, game, player, t);
  if paid > 0 {
    return CBTalkSay(CBWhisperPick3(s"Here. \(paid). Take it and go.", s"\(paid) eddies. That's all I got, I swear.", s"Fine! \(paid). We're square, right?"), n"fear_beg");
  }
  CBTalkSendOff(game, npc);
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
