// Cyberbane - Messages instead of popups (spec §12.2)
//
// A line of white text across the middle of the screen is a mod talking to you. A text from somebody is the city
// talking to you, and this mod is entirely about the city noticing you.

// ---- Who is texting -------------------------------------------------------
//
// Handles rather than names, for the reason above. Written the way the phone writes a contact's name; the cards put
// them in capitals themselves.

// The sender a message has when nobody in particular sent it. One function, so whatever compares a sender with it
// agrees with whatever wrote it, in any language.
public func CBPhoneUnknownSender() -> String {
  return CBT(n"Cyberbane-PhoneMessages-UnknownNumber");
}

// The gang itself, when the message is the gang speaking.
public func CBPhoneGangSender(faction: CName) -> String {
  let name = CBFactionName(faction);
  return StrLen(name) > 0 ? name : CBPhoneUnknownSender();
}

// The local information broker, one per district, so the same handle keeps turning up in the same part of town.
public func CBPhoneDistrictSender(district: CName) -> String {
  if Equals(district, n"Watson") { return CBT(n"Cyberbane-PhoneMessages-Salt"); }
  if Equals(district, n"Westbrook") { return CBT(n"Cyberbane-PhoneMessages-Mira"); }
  if Equals(district, n"CityCenter") { return CBT(n"Cyberbane-PhoneMessages-Glasswork"); }
  if Equals(district, n"Heywood") { return CBT(n"Cyberbane-PhoneMessages-TioBenny"); }
  if Equals(district, n"Pacifica") { return CBT(n"Cyberbane-PhoneMessages-LowTide"); }
  if Equals(district, n"SantoDomingo") { return CBT(n"Cyberbane-PhoneMessages-Radiator"); }
  if Equals(district, n"Badlands") { return CBT(n"Cyberbane-PhoneMessages-Dust"); }
  if Equals(district, n"Dogtown") { return CBT(n"Cyberbane-PhoneMessages-SplitLip"); }
  return CBPhoneUnknownSender();
}

// For word that is not about anywhere in particular: the broker who works where V is, or, between districts, the last
// one who did.
public func CBPhoneStreetSender(seed: Int32) -> String {
  let sys = CyberbaneSystem.Get(GetGameInstance());
  let here = IsDefined(sys) ? sys.GetCurrentDistrict() : n"";
  let rt = CyberbaneRuntime.Get();
  if CBDistrictIndex(here) >= 0 && NotEquals(CBPhoneDistrictSender(here), CBPhoneUnknownSender()) {
    if IsDefined(rt) {
      rt.lastBrokerDistrict = here;
    }
    return CBPhoneDistrictSender(here);
  }
  if IsDefined(rt) && IsNameValid(rt.lastBrokerDistrict) {
    return CBPhoneDistrictSender(rt.lastBrokerDistrict);
  }
  return CBT(n"Cyberbane-PhoneMessages-Mira");
}

// ---- How messages are delivered -------------------------------------------

public func CBMessageDelivery() -> ECBMessageDelivery {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return ECBMessageDelivery.Phone;
  }
  return rt.GetSettings().messageDelivery;
}

// Whether Cyberbane says anything on screen at all.
public func CBMessageSize() -> Float {
  let rt = CyberbaneRuntime.Get();
  let pct = IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().messageSize : 100;
  return ClampF(Cast<Float>(pct) / 100.0, 0.8, 2.0);
}

public func CBMessageAmount() -> ECBMessageAmount {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().messageAmount : ECBMessageAmount.LessChatter;
}

public func CBMessagesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  if rt.HasSettings() && !rt.GetSettings().toasts {
    return false;
  }
  return !Equals(CBMessageDelivery(), ECBMessageDelivery.Off);
}

// The phone hook is live: Cyberbane's threads go into the phone and its wraps act on them.
// Off in every other mode, and off with the kill switch, so the fallbacks really are fallbacks.
public func CBRealPhoneOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  return Equals(CBMessageDelivery(), ECBMessageDelivery.Phone);
}

// ---- The widget -----------------------------------------------------------

public class CBPhoneRow {
  public let root: ref<inkCanvas>;
  public let back: ref<inkRectangle>;
  public let edge: ref<inkRectangle>;
  public let sender: ref<inkText>;
  public let stamp: ref<inkText>;
  public let body: ref<inkText>;
}

public class CBPhone {
  private let m_rows: array<ref<CBPhoneRow>>;
  private let m_built: Bool;
  private let m_game: GameInstance;
  private let m_lastSimTime: Float;

  // The cards currently on screen. Parallel arrays, as everything else in this codebase does
  // it, so there is never a dynamic array nested inside a class that might one day be persisted.
  private let m_sender: array<String>;
  private let m_body: array<String>;
  private let m_stamp: array<String>;
  private let m_accent: array<HDRColor>;
  private let m_left: array<Float>;    // seconds of life remaining
  private let m_shown: array<Float>;   // seconds on screen, for the slide-in

  // The threads, one per sender, in the order they first got in touch. A thread's index is
  // also its contact in the phone (CBPhoneThreadHash), so threads are never removed during a
  // session; a hard reset clears them all at once.
  private let m_thName: array<String>;
  private let m_thUnread: array<Int32>;
  private let m_thTime: array<GameTime>;
  // The gang whose offer V can answer in this thread, or n"" when there is nothing to answer.
  // Only ever a gang V can actually buy off, and re-checked every time the thread is drawn.
  private let m_thOffer: array<CName>;
  // A Rival's whereabouts offered for sale in this thread: the Rival (0 none), the price, the gang selling (n"" for a
  // broker), and whether V has already pushed back on the price once.
  private let m_thLead: array<Int32>;
  private let m_thLeadPrice: array<Int32>;
  private let m_thLeadTipster: array<CName>;
  private let m_thLeadHaggled: array<Bool>;
  // Every message, oldest first, each tagged with the thread it belongs to, and whether V
  // sent it (a reply) or received it.
  private let m_msgThread: array<Int32>;
  private let m_msgBody: array<String>;
  private let m_msgMine: array<Bool>;
  // The thread open and focused in the phone right now, so a message that arrives while the
  // player is reading it is not counted as unread. 0 when none is.
  private let m_focusedHash: Int32;

  // Waiting for a settled tick to be delivered.
  // When a notification was last put on screen, and what it said, so the phone neither repeats
  // itself nor rings continuously (Config.PhoneNotifyGapSeconds / PhoneRepeatGuardSeconds).
  private let m_lastNotifyAt: Float;
  private let m_lastNotifyBody: String;
  private let m_lastNotifyThread: Int32;
  // In Phone mode, when the waiting messages started waiting for a phone to hand them to (sim
  // seconds; 0 = not waiting). See Deliver.
  private let m_phoneWaitSince: Float;
  private let m_pendThread: array<Int32>;
  private let m_pendBody: array<String>;
  private let m_pendAccent: array<HDRColor>;

  // The last line each thread received and when (game seconds), parallel to m_thName. A contact
  // repeating itself word for word is one message, not two unread ones.
  private let m_thLastBody: array<String>;
  private let m_thLastAt: array<Float>;
  // When V last answered each thread (game seconds), -1 when what it last said is still unanswered.
  private let m_thAnsweredAt: array<Float>;

  // Texts on their way to V. "The texts happen instantly, so it kinda defeats immersiveness": a Rival's answer landed
  // the second V's reply went, a gang's threat the second V killed one of theirs, two contacts at once.
  private let m_postSender: array<String>;
  private let m_postBody: array<String>;
  private let m_postAccent: array<HDRColor>;
  private let m_postDue: array<Float>;
  private let m_postAnswer: array<Bool>;     // their answer to something V just said: it does not open the thread again
  private let m_postThen: array<Int32>;      // 0 nothing, 1 asks nothing back, 2 a gang's price on V (peace), 3 a lead
  private let m_postFaction: array<CName>;   // the gang for 2, the tipster for 3
  private let m_postRival: array<Int32>;
  private let m_postPrice: array<Int32>;
  private let m_postLastDue: Float;

  // Word that has not reached V yet (Hearsay).
  private let m_hsSender: array<String>;
  private let m_hsBody: array<String>;
  private let m_hsAccent: array<HDRColor>;
  private let m_hsKey: array<CName>;
  private let m_hsFaction: array<CName>;   // a gang whose message carries a peace offer, or n""
  private let m_hsDue: array<Float>;       // game seconds: when word has got round where it happened
  // Where it happened and how long word takes to get round there: from there it travels a district at a time to
  // wherever V is when it is due (ReleaseWord, CBDistrictHops).
  private let m_hsFrom: array<CName>;
  private let m_hsSpan: array<Float>;
  // Sim seconds V was last in a fight: nobody's news reaches V in the middle of one.
  private let m_lastFightReal: Float;
  // Stories already told, and when (game seconds), for the repeat window.
  private let m_toldKey: array<CName>;
  private let m_toldAt: array<Float>;
  private let m_lastWordReal: Float;       // sim seconds the last story was let out
  // Chatter let through lately (How much you hear): game seconds each was queued, and when V last overheard anything.
  private let m_chatterAt: array<Float>;
  private let m_lastOverheard: Float;
  // The size the cards were last laid out at (Message size), so a change in Mod Settings shows at once.
  private let m_laidSize: Float;
  private let m_laidScale: Float;

  // The phone in V's hand, and the messenger panel if one of ours is open in it. Weak, and
  // checked on every use: the HUD is rebuilt on every load and fast travel.
  private let m_phoneCtrl: wref<NewHudPhoneGameController>;
  private let m_openDialog: wref<MessengerDialogViewController>;

  // Something V overheard on the street. Not a text: nobody sent it, V was standing near the person who said it. It is
  // a line of the game's subtitles, and it never goes into the phone.
  private let m_subNativeSlot: Int32;
  private let m_subRoot: ref<inkCanvas>;
  private let m_subSpeaker: ref<inkText>;
  private let m_subLine: ref<inkText>;
  private let m_subLeft: Float;
  private let m_subShown: Float;
  private let m_subNewSpeaker: String;
  private let m_subNewLine: String;
  private let m_subDirty: Bool;

  private func EnsureBuilt() -> Bool {
    if this.m_built && ArraySize(this.m_rows) > 0 {
      return true;
    }
    let ink = GameInstance.GetInkSystem();
    if !IsDefined(ink) {
      return false;
    }
    let layer = ink.GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) {
      return false;
    }
    let win = layer.GetVirtualWindow();
    if !IsDefined(win) {
      return false;
    }
    this.Build(win);
    return this.m_built;
  }

  private func Build(win: wref<inkCompoundWidget>) -> Void {
    // Cards left behind by an earlier session, first.
    let strays = CBHideStrayHudWidgets(win, n"cyberbanePhoneCard", n"cyberbaneOverheard");
    if strays > 0 {
      CBLog.Info(n"UI", s"Took \(strays) message cards left over from an earlier session off the screen.");
    }
    // And a subtitle line of ours an earlier session may have left up. The ids are fixed, so taking them down is safe
    // whether or not anything is showing.
    CBHideGameSubtitle(this.m_game, 0);
    CBHideGameSubtitle(this.m_game, 1);
    CBHideGameSubtitle(this.m_game, 2);   // and 4
    CBHideGameSubtitle(this.m_game, 3);   // and 5
    this.m_subNativeSlot = -1;
    let font = "base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily";
    let width = CBConfig.PhoneCardWidth();
    let height = CBConfig.PhoneCardHeight();
    // The same fit the threat bars use: these are authored in 1080p units and the ink space is
    // not always that big.
    let scale = CBHudScale(this.m_game);

    let i = 0;
    while i < CBConfig.PhoneCardRows() {
      let root = new inkCanvas();
      root.SetName(n"cyberbanePhoneCard");
      root.SetAnchor(inkEAnchor.TopLeft);
      root.SetAnchorPoint(new Vector2(0.0, 0.0));
      root.SetSize(new Vector2(width, height));
      root.SetMargin(new inkMargin(CBConfig.PhoneCardLeft() * scale,
                                   (CBConfig.PhoneCardTop() + Cast<Float>(i) * (height + CBConfig.PhoneCardGap())) * scale,
                                   0.0, 0.0));
      root.SetVisible(false);
      root.SetRenderTransformPivot(new Vector2(0.0, 0.0));
      root.SetScale(new Vector2(scale, scale));

      // The card. Near black with a little blue in it, which is what the phone's own panels
      // read as against the city.
      let back = new inkRectangle();
      back.SetAnchor(inkEAnchor.TopLeft);
      back.SetSize(new Vector2(width, height));
      back.SetTintColor(CBPhoneBack());
      back.Reparent(root);

      // The accent down the left edge. The phone uses one; it is most of what makes a flat
      // rectangle read as a message rather than as a debug overlay.
      let edge = new inkRectangle();
      edge.SetAnchor(inkEAnchor.TopLeft);
      edge.SetSize(new Vector2(CBConfig.PhoneCardEdge(), height));
      edge.SetTintColor(CBHudCyan());
      edge.Reparent(root);

      let sender = new inkText();
      sender.SetFontFamily(font);
      sender.SetFontStyle(n"Medium");
      sender.SetFontSize(20);
      sender.SetAnchor(inkEAnchor.TopLeft);
      sender.SetMargin(new inkMargin(CBConfig.PhoneCardEdge() + 16.0, 12.0, 0.0, 0.0));
      sender.SetLetterCase(textLetterCase.UpperCase);
      sender.SetTintColor(CBHudCyan());
      sender.SetText("");
      sender.Reparent(root);

      let stamp = new inkText();
      stamp.SetFontFamily(font);
      stamp.SetFontSize(17);
      stamp.SetAnchor(inkEAnchor.TopRight);
      stamp.SetAnchorPoint(new Vector2(1.0, 0.0));
      stamp.SetMargin(new inkMargin(0.0, 13.0, 16.0, 0.0));
      stamp.SetTintColor(CBHudGrey());
      stamp.SetText("");
      stamp.Reparent(root);

      let body = new inkText();
      body.SetFontFamily(font);
      body.SetFontSize(21);
      body.SetAnchor(inkEAnchor.TopLeft);
      body.SetMargin(new inkMargin(CBConfig.PhoneCardEdge() + 16.0, 42.0, 0.0, 0.0));
      body.SetWrapping(true, width - CBConfig.PhoneCardEdge() - 34.0, textWrappingPolicy.Default);
      body.SetTintColor(CBHudValue());
      body.SetText("");
      body.Reparent(root);

      root.Reparent(win);

      let row = new CBPhoneRow();
      row.root = root;
      row.back = back;
      row.edge = edge;
      row.sender = sender;
      row.stamp = stamp;
      row.body = body;
      ArrayPush(this.m_rows, row);
      i += 1;
    }
    this.BuildOverheard(win, font, scale);
    this.m_built = true;
    this.LayOut();
  }

  // Where each card sits and how big, by the screen's scale and Message size. The cards stack down from under the
  // health bar, so a bigger card pushes the next one further down.
  private func LayOut() -> Void {
    let scale = CBHudScale(this.m_game);
    let size = CBMessageSize();
    this.m_laidSize = size;
    this.m_laidScale = scale;
    let height = CBConfig.PhoneCardHeight();
    let i = 0;
    while i < ArraySize(this.m_rows) {
      let root = this.m_rows[i].root;
      if IsDefined(root) {
        root.SetMargin(new inkMargin(CBConfig.PhoneCardLeft() * scale,
                                     (CBConfig.PhoneCardTop() + Cast<Float>(i) * (height + CBConfig.PhoneCardGap()) * size) * scale,
                                     0.0, 0.0));
        root.SetScale(new Vector2(scale * size, scale * size));
      }
      i += 1;
    }
    if IsDefined(this.m_subRoot) {
      this.m_subRoot.SetMargin(new inkMargin(0.0, 0.0, 0.0, CBConfig.OverheardBottom() * scale));
      this.m_subRoot.SetScale(new Vector2(scale * size, scale * size));
    }
  }

  // Cyberbane's own subtitle line, for when the game's subtitles are switched off: a speaker label over the words,
  // centred where the game draws its subtitles.
  private func BuildOverheard(win: wref<inkCompoundWidget>, font: String, scale: Float) -> Void {
    let width = CBConfig.OverheardWidth();
    let root = new inkCanvas();
    root.SetName(n"cyberbaneOverheard");
    root.SetAnchor(inkEAnchor.BottomCenter);
    root.SetAnchorPoint(new Vector2(0.5, 1.0));
    root.SetSize(new Vector2(width, 96.0));
    root.SetMargin(new inkMargin(0.0, 0.0, 0.0, CBConfig.OverheardBottom() * scale));
    root.SetRenderTransformPivot(new Vector2(0.5, 1.0));
    root.SetScale(new Vector2(scale, scale));
    root.SetVisible(false);

    let speaker = new inkText();
    speaker.SetFontFamily(font);
    speaker.SetFontStyle(n"Medium");
    speaker.SetFontSize(20);
    speaker.SetLetterCase(textLetterCase.UpperCase);
    speaker.SetAnchor(inkEAnchor.TopCenter);
    speaker.SetAnchorPoint(new Vector2(0.5, 0.0));
    speaker.SetHorizontalAlignment(textHorizontalAlignment.Center);
    speaker.SetTintColor(CBHudCyan());
    speaker.SetText("");
    speaker.Reparent(root);

    let line = new inkText();
    line.SetFontFamily(font);
    line.SetFontSize(26);
    line.SetAnchor(inkEAnchor.TopCenter);
    line.SetAnchorPoint(new Vector2(0.5, 0.0));
    line.SetMargin(new inkMargin(0.0, 26.0, 0.0, 0.0));
    line.SetHorizontalAlignment(textHorizontalAlignment.Center);
    line.SetWrapping(true, width, textWrappingPolicy.Default);
    line.SetTintColor(CBHudValue());
    line.SetText("");
    line.Reparent(root);

    root.Reparent(win);
    this.m_subRoot = root;
    this.m_subSpeaker = speaker;
    this.m_subLine = line;
  }

  // Something said within earshot. Safe from any hook; shown on the next settled tick.
  public func Overhear(game: GameInstance, speaker: String, line: String, opt important: Bool) -> Void {
    this.m_game = game;
    if StrLen(line) == 0 {
      return;
    }
    // In passing, at most every so often (How much you hear). A line said to V as it happens always comes.
    if !important {
      let amount = CBMessageAmount();
      let gap = Equals(amount, ECBMessageAmount.Rarely) ? CBConfig.OverheardGapQuiet()
              : (Equals(amount, ECBMessageAmount.LessChatter) ? CBConfig.OverheardGapLess() : 0.0);
      let nowReal = CBTalkNow(game);
      if gap > 0.0 && this.m_lastOverheard > 0.0 && nowReal >= this.m_lastOverheard && nowReal - this.m_lastOverheard < gap {
        return;
      }
      this.m_lastOverheard = nowReal;
    }
    this.m_subNewSpeaker = speaker;
    this.m_subNewLine = line;
    this.m_subDirty = true;
    CBLog.Info(n"UI", s"Overheard (\(speaker)): \(line)");
  }

  // ---- Sending ------------------------------------------------------------

  // A message arrives. Safe from any hook: this only touches our own arrays. It is filed in
  // its sender's thread straight away and delivered on the next settled tick.
  public func Send(game: GameInstance, sender: String, body: String, accent: HDRColor, opt isAnswer: Bool) -> Void {
    this.m_game = game;
    if StrLen(body) == 0 {
      return;
    }
    let thread = this.ThreadFor(sender);
    if thread >= 0 {
      // The same contact saying the same thing again, within the hour: already in the thread and
      // already unread. Filing it twice is how a long fight became a screen of identical lines.
      let now = CBGameSeconds(game);
      if now > 0.0 && this.m_thLastAt[thread] > 0.0 && Equals(this.m_thLastBody[thread], body)
         && now >= this.m_thLastAt[thread]
         && (now - this.m_thLastAt[thread]) < CBConfig.PhoneDuplicateHours() * CBConfig.SecondsPerHour() {
        return;
      }
      this.m_thLastBody[thread] = body;
      this.m_thLastAt[thread] = now;
      // Something new from them, not their answer to what V just said: it can be answered again. Their answer arrives a
      // while after V's reply now (Post), so it says so itself (isAnswer) rather than by arriving in the same second.
      if !isAnswer && thread < ArraySize(this.m_thAnsweredAt) && this.m_thAnsweredAt[thread] >= 0.0
         && now - this.m_thAnsweredAt[thread] > 1.0 {
        this.m_thAnsweredAt[thread] = -1.0;
      }
      this.File(game, thread, body, false);
      this.m_thUnread[thread] += 1;
    }
    ArrayPush(this.m_pendThread, thread);
    ArrayPush(this.m_pendBody, body);
    ArrayPush(this.m_pendAccent, accent);
    // A flood of messages in one tick (a reset, say) should not turn into a flood of
    // notifications. The thread keeps everything; only the newest few are announced.
    while ArraySize(this.m_pendBody) > CBConfig.PhonePendingCap() {
      ArrayErase(this.m_pendThread, 0);
      ArrayErase(this.m_pendBody, 0);
      ArrayErase(this.m_pendAccent, 0);
    }
    CBLog.Info(n"UI", s"Message from \(sender): \(body)");
  }

  // ---- Texts on their way ----------------------------------------------

  // Which thread is this sender's, without starting one.
  private func FindThread(sender: String) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_thName) {
      if Equals(this.m_thName[i], sender) {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  // A text is written now and lands a little later.
  public func Post(game: GameInstance, sender: String, body: String, accent: HDRColor, urgent: Bool, then: Int32,
                   faction: CName, rival: Int32, price: Int32) -> Void {
    this.m_game = game;
    if StrLen(body) == 0 {
      return;
    }
    let now = CBTalkNow(game);
    let thread = this.FindThread(sender);
    let gameNow = CBGameSeconds(game);
    let answer = thread >= 0 && thread < ArraySize(this.m_thAnsweredAt) && this.m_thAnsweredAt[thread] >= 0.0
              && gameNow >= this.m_thAnsweredAt[thread] && gameNow - this.m_thAnsweredAt[thread] <= 1.0;
    let delay = 0.0;
    if answer {
      delay = ClampF(CBConfig.TextTypingBase() + CBConfig.TextTypingPerChar() * Cast<Float>(StrLen(body)),
                     CBConfig.TextTypingMin(), CBConfig.TextTypingMax()) * RandRangeF(0.8, 1.25);
    } else {
      if urgent {
        delay = RandRangeF(CBConfig.TextUrgentMin(), CBConfig.TextUrgentMax());
      } else {
        delay = RandRangeF(CBConfig.TextReactMin(), CBConfig.TextReactMax());
      }
    }
    let due = now + delay;
    // Somebody typing: the game's sound while a text that takes a while is on its way.
    if !urgent && delay >= 3.0 && CBMessagesOn() {
      CBUiSound(game, n"ui_messenger_typing", n"Typing", 12.0);
    }
    // A stamp from another session's clock (it starts again with a load) is forgotten.
    if this.m_postLastDue > now + 600.0 {
      this.m_postLastDue = 0.0;
    }
    if !urgent && this.m_postLastDue > 0.0 && due < this.m_postLastDue + CBConfig.TextGapMin() {
      due = this.m_postLastDue + RandRangeF(CBConfig.TextGapMin(), CBConfig.TextGapMax());
    }
    if !urgent {
      this.m_postLastDue = MaxF(this.m_postLastDue, due);
    }
    ArrayPush(this.m_postSender, sender);
    ArrayPush(this.m_postBody, body);
    ArrayPush(this.m_postAccent, accent);
    ArrayPush(this.m_postDue, due);
    ArrayPush(this.m_postAnswer, answer);
    ArrayPush(this.m_postThen, then);
    ArrayPush(this.m_postFaction, faction);
    ArrayPush(this.m_postRival, rival);
    ArrayPush(this.m_postPrice, price);
  }

  // The text whose time has come, one a tick, and whatever it opens or closes in its thread.
  private func ReleasePosts(game: GameInstance) -> Void {
    if ArraySize(this.m_postBody) == 0 {
      return;
    }
    let now = CBTalkNow(game);
    let pick = -1;
    let i = 0;
    while i < ArraySize(this.m_postDue) {
      // Due, or stamped from another session's clock (far ahead of now): land it.
      let due = this.m_postDue[i];
      if (due <= now || due > now + 600.0) && (pick < 0 || due < this.m_postDue[pick]) {
        pick = i;
      }
      i += 1;
    }
    if pick < 0 {
      return;
    }
    let sender = this.m_postSender[pick];
    let body = this.m_postBody[pick];
    let accent = this.m_postAccent[pick];
    let answer = this.m_postAnswer[pick];
    let then = this.m_postThen[pick];
    let faction = this.m_postFaction[pick];
    let rival = this.m_postRival[pick];
    let price = this.m_postPrice[pick];
    ArrayErase(this.m_postSender, pick);
    ArrayErase(this.m_postBody, pick);
    ArrayErase(this.m_postAccent, pick);
    ArrayErase(this.m_postDue, pick);
    ArrayErase(this.m_postAnswer, pick);
    ArrayErase(this.m_postThen, pick);
    ArrayErase(this.m_postFaction, pick);
    ArrayErase(this.m_postRival, pick);
    ArrayErase(this.m_postPrice, pick);
    CBPhoneDeliverNow(game, sender, body, accent, answer);
    if then == 1 {
      this.Settle(game, sender);
    }
    if then == 2 {
      CBPhoneOfferPeace(game, faction);
    }
    if then == 3 {
      this.OfferLead(sender, rival, price, faction);
    }
  }

  // ---- Word getting around ------------------------------------------------

  // Somebody will tell V about this, once it has had time to get round.
  public func Hearsay(game: GameInstance, sender: String, body: String, accent: HDRColor,
                      key: CName, offerFaction: CName, opt from: CName, opt important: Bool) -> Void {
    this.m_game = game;
    if StrLen(body) == 0 {
      return;
    }
    let now = CBGameSeconds(game);
    if IsNameValid(key) {
      let q = 0;
      while q < ArraySize(this.m_hsKey) {
        if Equals(this.m_hsKey[q], key) {
          return;   // already on its way
        }
        q += 1;
      }
      let t = 0;
      while t < ArraySize(this.m_toldKey) {
        if Equals(this.m_toldKey[t], key) && now >= this.m_toldAt[t]
           && (now - this.m_toldAt[t]) < CBConfig.HearsayRepeatHours() * CBConfig.SecondsPerHour() {
          return;   // V heard this one not long ago
        }
        t += 1;
      }
    }
    // Chatter, word with nothing in it for V to answer, spaced out by How much you hear: a couple an in-game hour on
    // Less chatter, one every two on Rarely, never none. A gang's offer or demand always comes.
    if !IsNameValid(offerFaction) && !important {
      let amount = CBMessageAmount();
      if !Equals(amount, ECBMessageAmount.Everything) {
        let rarely = Equals(amount, ECBMessageAmount.Rarely);
        let hour = CBConfig.SecondsPerHour() * (rarely ? 2.0 : 1.0);
        let allowed = rarely ? 1 : CBConfig.ChatterPerHour();
        let recent = 0;
        let c = ArraySize(this.m_chatterAt) - 1;
        while c >= 0 {
          if now < this.m_chatterAt[c] || now - this.m_chatterAt[c] >= hour {
            ArrayErase(this.m_chatterAt, c);
          } else {
            recent += 1;
          }
          c -= 1;
        }
        if recent >= allowed {
          CBLog.Info(n"UI", s"Word let go (How much you hear) from \(sender): \(body)");
          return;
        }
        ArrayPush(this.m_chatterAt, now);
      }
    }
    // A full queue is a busy hour, and the stories already waiting are the older news; the new
    // one is let go rather than pushing them out.
    if ArraySize(this.m_hsBody) >= CBConfig.HearsayQueueCap() {
      CBLog.Info(n"UI", s"Word dropped (queue full) from \(sender): \(body)");
      return;
    }
    // Not to the minute: two things done together reach V at different times, the way word does. This is how long it
    // takes to get round where it happened; further off, it takes longer again (ReleaseWord).
    let delay = CBWordTravelSeconds() * RandRangeF(0.75, 1.25);
    if !IsNameValid(from) {
      let sysFrom = CyberbaneSystem.Get(game);
      from = IsDefined(sysFrom) ? CBEventDistrict(sysFrom, game) : n"";
    }
    ArrayPush(this.m_hsFrom, from);
    ArrayPush(this.m_hsSpan, delay);
    ArrayPush(this.m_hsSender, sender);
    ArrayPush(this.m_hsBody, body);
    ArrayPush(this.m_hsAccent, accent);
    ArrayPush(this.m_hsKey, key);
    ArrayPush(this.m_hsFaction, offerFaction);
    // With the clock not yet readable (straight after a load), now is 0 and it is due at once;
    // the release below waits for a readable clock anyway.
    ArrayPush(this.m_hsDue, now + delay);
    CBLog.Info(n"UI", s"Word on its way from \(sender): \(body)");
  }

  // Let out at most one story whose time has come. Runs from Update, on a settled tick.
  private func ReleaseWord(game: GameInstance) -> Void {
    if ArraySize(this.m_hsBody) == 0 {
      return;
    }
    let now = CBGameSeconds(game);
    if now <= 0.0 {
      return;   // the clock is not up yet
    }
    let tsNow = GameInstance.GetTimeSystem(game);
    if !IsDefined(tsNow) {
      return;
    }
    let simNow = EngineTime.ToFloat(tsNow.GetSimTime());
    // Nobody's news reaches V in the middle of a fight, nor straight after one: it waits, and the fight it might be
    // about has to be over before the word can start going round anyway.
    let player = GetPlayer(game);
    if IsDefined(player) && player.IsInCombat() {
      this.m_lastFightReal = simNow;
    }
    if this.m_lastFightReal > 0.0 && simNow >= this.m_lastFightReal
       && (simNow - this.m_lastFightReal) < CBConfig.WordCalmSeconds() {
      return;
    }
    // Word that reached V's part of town long ago and is still waiting (a long fight, a long night's sleep) is old news
    // and goes unsaid, unless it carries a gang's price.
    let o = ArraySize(this.m_hsBody) - 1;
    while o >= 0 {
      if !IsNameValid(this.m_hsFaction[o]) && now - this.m_hsDue[o] > CBConfig.HearsayStaleHours() * CBConfig.SecondsPerHour() {
        CBLog.Info(n"UI", s"Word let go (too old to matter) from \(this.m_hsSender[o]): \(this.m_hsBody[o])");
        this.DropWord(o);
      }
      o -= 1;
    }
    if this.m_lastWordReal > 0.0 && simNow >= this.m_lastWordReal && (simNow - this.m_lastWordReal) < CBInboxGapSeconds() {
      return;
    }
    // The one that has been due longest, among those that have reached V: word that has got round where it happened
    // still has to cross the city to wherever V is now, a district at a time (CBDistrictHops).
    let sysHere = CyberbaneSystem.Get(game);
    let here = IsDefined(sysHere) ? CBEventDistrict(sysHere, game) : n"";
    let pick = -1;
    let pickDue = 0.0;
    let i = 0;
    while i < ArraySize(this.m_hsDue) {
      // At most two districts' more (CBConfig.WordMaxHops): across the city it takes longer, never so long the story
      // stops mattering.
      let hops = i < ArraySize(this.m_hsFrom) ? Min(CBDistrictHops(game, this.m_hsFrom[i], here), CBConfig.WordMaxHops()) : 0;
      // Either end unknown (V's district right after a load, or news from nowhere on the map) is one district's travel,
      // never none: CBDistrictHops reads an unknown district as the same one.
      if i < ArraySize(this.m_hsFrom) && (CBDistrictIndex(this.m_hsFrom[i]) < 0 || CBDistrictIndex(here) < 0) {
        hops = 1;
      }
      let span = i < ArraySize(this.m_hsSpan) ? this.m_hsSpan[i] : 0.0;
      // Half as long again for each district it still has to cross.
      let due = this.m_hsDue[i] + span * 0.5 * Cast<Float>(hops);
      if due <= now && (pick < 0 || due < pickDue) {
        pick = i;
        pickDue = due;
      }
      i += 1;
    }
    if pick < 0 {
      return;
    }
    let sender = this.m_hsSender[pick];
    let body = this.m_hsBody[pick];
    let accent = this.m_hsAccent[pick];
    let key = this.m_hsKey[pick];
    let faction = this.m_hsFaction[pick];
    ArrayErase(this.m_hsSender, pick);
    ArrayErase(this.m_hsBody, pick);
    ArrayErase(this.m_hsAccent, pick);
    ArrayErase(this.m_hsKey, pick);
    ArrayErase(this.m_hsFaction, pick);
    ArrayErase(this.m_hsDue, pick);
    if pick < ArraySize(this.m_hsFrom) {
      ArrayErase(this.m_hsFrom, pick);
    }
    if pick < ArraySize(this.m_hsSpan) {
      ArrayErase(this.m_hsSpan, pick);
    }
    this.m_lastWordReal = simNow;
    if IsNameValid(key) {
      this.NoteTold(key, now);
    }
    // Through the ordinary door, so the silence switches and the delivery mode are asked about now, when it arrives,
    // not back when it was queued.
    CBPhoneDeliverNow(game, sender, IsNameValid(faction) ? CBPhoneDemandText(game, faction, body, false) : body, accent, false);
    if IsNameValid(faction) {
      CBPhoneOfferPeace(game, faction);
    }
  }

  // One story out of the queue, every list with it.
  private func DropWord(i: Int32) -> Void {
    if i < 0 || i >= ArraySize(this.m_hsBody) {
      return;
    }
    ArrayErase(this.m_hsSender, i);
    ArrayErase(this.m_hsBody, i);
    ArrayErase(this.m_hsAccent, i);
    ArrayErase(this.m_hsKey, i);
    ArrayErase(this.m_hsFaction, i);
    ArrayErase(this.m_hsDue, i);
    if i < ArraySize(this.m_hsFrom) {
      ArrayErase(this.m_hsFrom, i);
    }
    if i < ArraySize(this.m_hsSpan) {
      ArrayErase(this.m_hsSpan, i);
    }
  }

  private func NoteTold(key: CName, now: Float) -> Void {
    let t = 0;
    while t < ArraySize(this.m_toldKey) {
      if Equals(this.m_toldKey[t], key) {
        this.m_toldAt[t] = now;
        return;
      }
      t += 1;
    }
    ArrayPush(this.m_toldKey, key);
    ArrayPush(this.m_toldAt, now);
    while ArraySize(this.m_toldKey) > CBConfig.HearsayToldCap() {
      ArrayErase(this.m_toldKey, 0);
      ArrayErase(this.m_toldAt, 0);
    }
  }

  // ---- Threads ------------------------------------------------------------

  // Put one line into a thread and stamp the thread with the time.
  private func File(game: GameInstance, thread: Int32, body: String, mine: Bool) -> Void {
    ArrayPush(this.m_msgThread, thread);
    ArrayPush(this.m_msgBody, body);
    ArrayPush(this.m_msgMine, mine);
    let ts = GameInstance.GetTimeSystem(game);
    if IsDefined(ts) {
      this.m_thTime[thread] = ts.GetGameTime();
    }
    // Oldest first out when the store is full. A thread can lose its oldest lines this way;
    // it never loses its contact, so the phone list stays consistent.
    while ArraySize(this.m_msgBody) > CBConfig.PhoneMessageCap() {
      ArrayErase(this.m_msgThread, 0);
      ArrayErase(this.m_msgBody, 0);
      ArrayErase(this.m_msgMine, 0);
    }
  }

  // V answers in a thread. Filed as V's own line, never unread.
  public func Reply(game: GameInstance, thread: Int32, body: String) -> Void {
    if thread < 0 || thread >= ArraySize(this.m_thName) || StrLen(body) == 0 {
      return;
    }
    this.File(game, thread, body, true);
    if thread < ArraySize(this.m_thAnsweredAt) {
      this.m_thAnsweredAt[thread] = MaxF(CBGameSeconds(game), 0.0);
    }
    CBLog.Info(n"UI", s"V replied to \(this.m_thName[thread]): \(body)");
  }

  // A gang V can buy off has just been in touch: let V answer it.
  public func OfferPeace(sender: String, faction: CName) -> Void {
    let thread = this.ThreadFor(sender);
    if thread >= 0 {
      this.m_thOffer[thread] = faction;
    }
  }

  // Is an offer open in this sender's thread? Asked before a threat says its price again.
  public func OfferOpenFor(sender: String) -> Bool {
    let i = 0;
    while i < ArraySize(this.m_thName) {
      if Equals(this.m_thName[i], sender) {
        return i < ArraySize(this.m_thOffer) && IsNameValid(this.m_thOffer[i]);
      }
      i += 1;
    }
    return false;
  }

  // Has V answered the last thing this thread said? A Rival's answer to V's reply comes in the same moment as the reply
  // and does not open it again; anything they send later does (Send).
  public func ThreadAwaitsAnswer(i: Int32) -> Bool {
    return i >= 0 && i < ArraySize(this.m_thAnsweredAt) && this.m_thAnsweredAt[i] < 0.0;
  }

  // What this sender just said asks nothing back (CBPhoneSendAside): an offer, thanks, a warning on V's side.
  public func Settle(game: GameInstance, sender: String) -> Void {
    let i = 0;
    while i < ArraySize(this.m_thName) {
      if Equals(this.m_thName[i], sender) {
        if i < ArraySize(this.m_thAnsweredAt) {
          this.m_thAnsweredAt[i] = MaxF(CBGameSeconds(game), 0.0);
        }
        return;
      }
      i += 1;
    }
  }

  public func ThreadOffer(i: Int32) -> CName {
    if i < 0 || i >= ArraySize(this.m_thOffer) {
      return n"";
    }
    return this.m_thOffer[i];
  }

  public func ClearOffer(i: Int32) -> Void {
    if i >= 0 && i < ArraySize(this.m_thOffer) {
      this.m_thOffer[i] = n"";
    }
  }

  // One lead on offer at a time: a new one replaces any other.
  public func OfferLead(sender: String, rivalId: Int32, price: Int32, tipster: CName) -> Bool {
    let thread = this.ThreadFor(sender);
    if thread < 0 {
      return false;
    }
    let i = 0;
    while i < ArraySize(this.m_thLead) {
      this.m_thLead[i] = 0;
      i += 1;
    }
    this.m_thLead[thread] = rivalId;
    this.m_thLeadPrice[thread] = price;
    this.m_thLeadTipster[thread] = tipster;
    this.m_thLeadHaggled[thread] = false;
    return true;
  }

  public func ThreadLead(i: Int32) -> Int32 {
    return i >= 0 && i < ArraySize(this.m_thLead) ? this.m_thLead[i] : 0;
  }

  public func ThreadLeadPrice(i: Int32) -> Int32 {
    return i >= 0 && i < ArraySize(this.m_thLeadPrice) ? this.m_thLeadPrice[i] : 0;
  }

  public func ThreadLeadTipster(i: Int32) -> CName {
    return i >= 0 && i < ArraySize(this.m_thLeadTipster) ? this.m_thLeadTipster[i] : n"";
  }

  public func ThreadLeadHaggled(i: Int32) -> Bool {
    return i >= 0 && i < ArraySize(this.m_thLeadHaggled) && this.m_thLeadHaggled[i];
  }

  // The seller's answer to "too much": the price they stand on now, haggled once.
  public func SetLeadPrice(i: Int32, price: Int32) -> Void {
    if i >= 0 && i < ArraySize(this.m_thLeadPrice) {
      this.m_thLeadPrice[i] = price;
      this.m_thLeadHaggled[i] = true;
    }
  }

  public func ClearLead(i: Int32) -> Void {
    if i >= 0 && i < ArraySize(this.m_thLead) {
      this.m_thLead[i] = 0;
    }
  }

  public func SetFocusedThread(hash: Int32) -> Void {
    this.m_focusedHash = hash;
  }

  // The thread for this sender, made on first contact. -1 only if the session somehow has more
  // senders than the cap, in which case the message is still shown, just not filed.
  private func ThreadFor(sender: String) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_thName) {
      if Equals(this.m_thName[i], sender) {
        return i;
      }
      i += 1;
    }
    if ArraySize(this.m_thName) >= CBConfig.PhoneThreadCap() {
      return -1;
    }
    let empty: GameTime;
    ArrayPush(this.m_thName, sender);
    ArrayPush(this.m_thUnread, 0);
    ArrayPush(this.m_thTime, empty);
    ArrayPush(this.m_thOffer, n"");
    ArrayPush(this.m_thLead, 0);
    ArrayPush(this.m_thLeadPrice, 0);
    ArrayPush(this.m_thLeadTipster, n"");
    ArrayPush(this.m_thLeadHaggled, false);
    ArrayPush(this.m_thLastBody, "");
    ArrayPush(this.m_thLastAt, 0.0);
    ArrayPush(this.m_thAnsweredAt, -1.0);
    return ArraySize(this.m_thName) - 1;
  }

  public func ThreadCount() -> Int32 {
    return ArraySize(this.m_thName);
  }

  public func ThreadName(i: Int32) -> String {
    if i < 0 || i >= ArraySize(this.m_thName) {
      return "";
    }
    return this.m_thName[i];
  }

  public func ThreadTime(i: Int32) -> GameTime {
    let none: GameTime;
    if i < 0 || i >= ArraySize(this.m_thTime) {
      return none;
    }
    return this.m_thTime[i];
  }

  // How many of this thread's messages are still in the store.
  public func ThreadSize(i: Int32) -> Int32 {
    let n = 0;
    let k = 0;
    while k < ArraySize(this.m_msgThread) {
      if this.m_msgThread[k] == i {
        n += 1;
      }
      k += 1;
    }
    return n;
  }

  // Unread, never more than the thread still holds.
  public func ThreadUnread(i: Int32) -> Int32 {
    if i < 0 || i >= ArraySize(this.m_thUnread) {
      return 0;
    }
    let received = 0;
    let k = 0;
    while k < ArraySize(this.m_msgThread) {
      if this.m_msgThread[k] == i && !this.m_msgMine[k] {
        received += 1;
      }
      k += 1;
    }
    return Min(this.m_thUnread[i], received);
  }

  public func MarkThreadRead(i: Int32) -> Void {
    if i >= 0 && i < ArraySize(this.m_thUnread) {
      this.m_thUnread[i] = 0;
    }
  }

  // Whether the last line in the thread is V's, so the phone can write "You:" in front of it.
  public func ThreadPreviewMine(i: Int32) -> Bool {
    let k = ArraySize(this.m_msgThread) - 1;
    while k >= 0 {
      if this.m_msgThread[k] == i {
        return this.m_msgMine[k];
      }
      k -= 1;
    }
    return false;
  }

  // The last line in the thread, for the line under the sender's name in the phone.
  public func ThreadPreview(i: Int32) -> String {
    let k = ArraySize(this.m_msgThread) - 1;
    while k >= 0 {
      if this.m_msgThread[k] == i {
        return this.m_msgBody[k];
      }
      k -= 1;
    }
    return "";
  }

  // Which of ThreadBodies(i, limit) V sent, in the same order.
  public func ThreadMine(i: Int32, limit: Int32) -> array<Bool> {
    let newestFirst: array<Bool>;
    let k = ArraySize(this.m_msgThread) - 1;
    while k >= 0 && ArraySize(newestFirst) < limit {
      if this.m_msgThread[k] == i {
        ArrayPush(newestFirst, this.m_msgMine[k]);
      }
      k -= 1;
    }
    let out: array<Bool>;
    let j = ArraySize(newestFirst) - 1;
    while j >= 0 {
      ArrayPush(out, newestFirst[j]);
      j -= 1;
    }
    return out;
  }

  // The newest `limit` messages of a thread, oldest first, the way a thread reads.
  public func ThreadBodies(i: Int32, limit: Int32) -> array<String> {
    let newestFirst: array<String>;
    let k = ArraySize(this.m_msgThread) - 1;
    while k >= 0 && ArraySize(newestFirst) < limit {
      if this.m_msgThread[k] == i {
        ArrayPush(newestFirst, this.m_msgBody[k]);
      }
      k -= 1;
    }
    let out: array<String>;
    let j = ArraySize(newestFirst) - 1;
    while j >= 0 {
      ArrayPush(out, newestFirst[j]);
      j -= 1;
    }
    return out;
  }

  // ---- The phone ----------------------------------------------------------

  public func SetPhoneController(ctrl: ref<NewHudPhoneGameController>) -> Void {
    this.m_phoneCtrl = ctrl;
  }

  // A phone on its way out lets go of itself, and only of itself.
  public func ReleasePhoneController(ctrl: ref<NewHudPhoneGameController>) -> Void {
    if this.m_phoneCtrl == ctrl {
      this.m_phoneCtrl = null;
    }
  }

  public func SetOpenDialog(dialog: ref<MessengerDialogViewController>) -> Void {
    this.m_openDialog = dialog;
  }

  // The same for the messenger panel.
  public func ReleaseOpenDialog(dialog: ref<MessengerDialogViewController>) -> Void {
    if this.m_openDialog == dialog {
      this.m_openDialog = null;
    }
  }

  // Everything of ours off the screen, without forgetting any of it (Hold, while the tick stands down): whatever was
  // showing would otherwise freeze there, and if a load follows, stay there.
  public func Conceal() -> Void {
    if IsDefined(this.m_subRoot) {
      this.m_subRoot.SetVisible(false);
    }
    this.HideNativeLine();
    let i = 0;
    while i < ArraySize(this.m_rows) {
      if IsDefined(this.m_rows[i].root) {
        this.m_rows[i].root.SetVisible(false);
      }
      i += 1;
    }
  }

  // The tick is standing down (a scene, a menu, a workspot, the world settling): the cards and the overheard line come
  // off the screen and their clocks stop, so they are back for the rest of their time once it is over.
  public func Hold(game: GameInstance) -> Void {
    this.m_subLeft = 0.0;
    this.Conceal();
    let ts = GameInstance.GetTimeSystem(game);
    if IsDefined(ts) && this.m_lastSimTime > 0.0 {
      this.m_lastSimTime = EngineTime.ToFloat(ts.GetSimTime());
    }
  }

  // ---- Drawing ------------------------------------------------------------

  // Once per fast tick. Delivers anything waiting, then ages the cards, slides the new ones
  // in and fades the dying ones out.
  public func Update(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.m_game = game;
    this.ReleasePosts(game);  // texts whose time has come
    this.ReleaseWord(game);   // before Deliver, so a story let out this tick is shown this tick
    this.Deliver(game);
    this.Animate(sys, game);
  }

  // The cards' clock and their drawing, apart from delivering anything: the tick also runs it on the ticks it spends
  // letting the world settle (CyberbaneSystem.OnFastTick), when nothing new is delivered but what is up still has to
  // age.
  public func Animate(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.m_game = game;
    // Built on the first settled tick of a session whether or not a card is ever shown, because building is what clears
    // away the cards an earlier session left on the HUD layer (Build).
    if !this.m_built {
      this.EnsureBuilt();
    }
    if ArraySize(this.m_sender) == 0 && this.m_subLeft <= 0.0 {
      return;
    }
    // The cards stand back while the Hub page is up. It is a page of the pause menu now, which hides the HUD by itself,
    // so this is belt and braces.
    let hubOpen = IsDefined(sys) && sys.IsHubOpen();
    let ts = GameInstance.GetTimeSystem(game);
    if !IsDefined(ts) {
      return;
    }
    let now = EngineTime.ToFloat(ts.GetSimTime());
    let dt = this.m_lastSimTime > 0.0 ? now - this.m_lastSimTime : 0.0;
    this.m_lastSimTime = now;
    // A load, a hitch or a time skip can hand back a nonsense delta: at most a couple of ticks' worth counts, so the
    // stack is never wiped in one frame.
    if dt < 0.0 {
      dt = 0.0;
    }
    dt = MinF(dt, 2.0 * CBConfig.FastTickSeconds());
    if !this.EnsureBuilt() {
      return;   // no layer yet; the cards keep their time and appear when there is one
    }
    this.TickOverheard(dt, hubOpen);

    // Backwards, so erasing does not skip the next one.
    let i = ArraySize(this.m_left) - 1;
    while i >= 0 {
      this.m_left[i] -= dt;
      this.m_shown[i] += dt;
      if this.m_left[i] <= 0.0 {
        ArrayErase(this.m_sender, i);
        ArrayErase(this.m_body, i);
        ArrayErase(this.m_stamp, i);
        ArrayErase(this.m_accent, i);
        ArrayErase(this.m_left, i);
        ArrayErase(this.m_shown, i);
      }
      i -= 1;
    }

    let shown = hubOpen ? 0 : ArraySize(this.m_sender);
    if shown > 0 && (AbsF(this.m_laidSize - CBMessageSize()) > 0.001 || AbsF(this.m_laidScale - CBHudScale(this.m_game)) > 0.001) {
      this.LayOut();   // Message size changed in Mod Settings, or the screen did
    }
    let r = 0;
    while r < ArraySize(this.m_rows) {
      let row = this.m_rows[r];
      if r < shown {
        if IsDefined(row.sender) {
          row.sender.SetText(this.m_sender[r]);
        }
        if IsDefined(row.stamp) {
          row.stamp.SetText(this.m_stamp[r]);
        }
        if IsDefined(row.body) {
          row.body.SetText(this.m_body[r]);
        }
        // The edge is coloured by who is speaking, which is the one piece of information the
        // eye picks up before it has read anything: red means the gang is talking to you, and
        // that is never good news.
        if IsDefined(row.edge) {
          row.edge.SetTintColor(this.m_accent[r]);
        }
        if IsDefined(row.sender) {
          row.sender.SetTintColor(this.m_accent[r]);
        }
        if IsDefined(row.root) {
          // In from the left over a fifth of a second, out over the last of its life.
          let inT = ClampF(this.m_shown[r] / CBConfig.PhoneSlideSeconds(), 0.0, 1.0);
          let outT = ClampF(this.m_left[r] / CBConfig.PhoneFadeSeconds(), 0.0, 1.0);
          row.root.SetOpacity(MinF(inT, outT));
          row.root.SetTranslation(new Vector2((inT - 1.0) * CBConfig.PhoneSlideDistance(), 0.0));
          row.root.SetVisible(true);
        }
      } else {
        if IsDefined(row.root) {
          row.root.SetVisible(false);
        }
      }
      r += 1;
    }
  }

  // Age the subtitle line and fade it in and out. A line of the game's subtitles fades by itself;
  // it only has to be taken down when its time is up.
  private func TickOverheard(dt: Float, hubOpen: Bool) -> Void {
    if this.m_subLeft <= 0.0 {
      this.HideNativeLine();
      if IsDefined(this.m_subRoot) {
        this.m_subRoot.SetVisible(false);
      }
      return;
    }
    this.m_subLeft -= dt;
    this.m_subShown += dt;
    if this.m_subLeft <= 0.0 {
      this.HideNativeLine();
    }
    if this.m_subNativeSlot >= 0 || !IsDefined(this.m_subRoot) {
      if IsDefined(this.m_subRoot) {
        this.m_subRoot.SetVisible(false);
      }
      return;
    }
    if IsDefined(this.m_subSpeaker) {
      this.m_subSpeaker.SetText(this.m_subNewSpeaker);
    }
    if IsDefined(this.m_subLine) {
      this.m_subLine.SetText(this.m_subNewLine);
    }
    let inT = ClampF(this.m_subShown / CBConfig.PhoneSlideSeconds(), 0.0, 1.0);
    let outT = ClampF(this.m_subLeft / CBConfig.PhoneFadeSeconds(), 0.0, 1.0);
    this.m_subRoot.SetOpacity(MinF(inT, outT));
    this.m_subRoot.SetVisible(!hubOpen && this.m_subLeft > 0.0);
  }

  // Put the newest overheard line up: in the game's subtitles when they are on, otherwise in ours.
  private func ShowOverheardLine(game: GameInstance) -> Void {
    let previous = this.m_subNativeSlot;
    this.m_subNativeSlot = -1;
    if CBGameSubtitlesOn(game) {
      let slot = previous == 0 ? 1 : 0;
      if CBShowGameSubtitle(game, slot, this.m_subNewSpeaker, this.m_subNewLine, this.m_subLeft) {
        this.m_subNativeSlot = slot;
      }
    }
    if previous >= 0 {
      CBHideGameSubtitle(game, previous);
    }
  }

  private func HideNativeLine() -> Void {
    if this.m_subNativeSlot >= 0 {
      CBHideGameSubtitle(this.m_game, this.m_subNativeSlot);
      this.m_subNativeSlot = -1;
    }
  }

  // Hand everything waiting to whichever surface is in use. Runs on a settled tick only.
  private func Deliver(game: GameInstance) -> Void {
    // Silenced since these were filed: they stay in their threads and are not announced, the way a message sent after
    // the switch is never sent. Switching messages off used to let the last few through.
    if !CBMessagesOn() {
      this.m_subDirty = false;
      ArrayClear(this.m_pendThread);
      ArrayClear(this.m_pendBody);
      ArrayClear(this.m_pendAccent);
      return;
    }
    // Nothing talks over a conversation. While one of the game's dialogues is on screen, or a scene is playing, the
    // overheard line and the texts wait; while V is talking to somebody through street talk, the texts wait.
    let gameTalk = CBGameDialogueUp(game) || CBPlayerInScene(game);
    let sysTalk = CyberbaneSystem.Get(game);
    let talk = IsDefined(sysTalk) ? sysTalk.GetStreetTalk() : null;
    let ourTalk = IsDefined(talk) && talk.Busy();
    if this.m_subDirty && !gameTalk {
      this.m_subDirty = false;
      this.m_subLeft = MaxF(CBTalkReadSeconds(this.m_subNewLine, CBConfig.OverheardSeconds()), CBConfig.OverheardFloor());
      this.m_subShown = 0.0;
      this.ShowOverheardLine(game);
      let tsSub = GameInstance.GetTimeSystem(game);
      if IsDefined(tsSub) && ArraySize(this.m_sender) == 0 {
        this.m_lastSimTime = EngineTime.ToFloat(tsSub.GetSimTime());
      }
    }
    if ArraySize(this.m_pendBody) == 0 {
      this.m_phoneWaitSince = 0.0;
      return;
    }
    if gameTalk || ourTalk {
      return;
    }
    let phoneMode = CBRealPhoneOn();
    let usePhone = phoneMode && IsDefined(this.m_phoneCtrl);
    let sound = CBPhoneSoundOn();
    // Real seconds, for the two guards below. The simulation clock is the one the cards age on,
    // so the phone and the cards agree about what "a moment ago" means.
    let tsNow = GameInstance.GetTimeSystem(game);
    let nowReal = IsDefined(tsNow) ? EngineTime.ToFloat(tsNow.GetSimTime()) : 0.0;
    // Phone mode and no phone to hand them to yet: they wait for one.
    if phoneMode && !usePhone {
      if this.m_phoneWaitSince <= 0.0 || nowReal < this.m_phoneWaitSince {
        this.m_phoneWaitSince = MaxF(nowReal, 0.001);
      }
      if nowReal - this.m_phoneWaitSince < CBConfig.PhoneAttachWaitSeconds() {
        return;
      }
      CBLog.Info(n"UI", s"No phone to announce \(ArraySize(this.m_pendBody)) messages on; they are in their threads.");
      this.m_phoneWaitSince = 0.0;
      ArrayClear(this.m_pendThread);
      ArrayClear(this.m_pendBody);
      ArrayClear(this.m_pendAccent);
      return;
    }
    this.m_phoneWaitSince = 0.0;
    let k = 0;
    while k < ArraySize(this.m_pendBody) {
      let thread = this.m_pendThread[k];
      let body = this.m_pendBody[k];
      let sender = this.ThreadName(thread);
      if StrLen(sender) == 0 {
        sender = CBPhoneUnknownSender();
      }
      // The phone, when there is one to hand it to and the message has a thread to open.
      // Anything else falls back to a card rather than being lost.
      // Is this one allowed to announce itself?
      let repeat = Equals(body, this.m_lastNotifyBody) && thread == this.m_lastNotifyThread
                && nowReal > 0.0 && this.m_lastNotifyAt > 0.0
                && (nowReal - this.m_lastNotifyAt) < CBConfig.PhoneRepeatGuardSeconds();
      let tooSoon = nowReal > 0.0 && this.m_lastNotifyAt > 0.0
                 && (nowReal - this.m_lastNotifyAt) < CBConfig.PhoneNotifyGapSeconds();
      let announce = !repeat && !tooSoon;
      if announce {
        this.m_lastNotifyAt = nowReal;
        this.m_lastNotifyBody = body;
        this.m_lastNotifyThread = thread;
      }
      if usePhone && thread >= 0 {
        let hash = CBPhoneThreadHash(thread);
        // One of ours is open in the phone right now: draw the new line straight into it,
        // and the player is reading it as it arrives.
        let dialog = this.m_openDialog;
        let shownNow = IsDefined(dialog) && dialog.cbThreadHash == hash
                    && IsDefined(dialog.GetRootWidget()) && dialog.GetRootWidget().IsVisible();
        if shownNow {
          if this.m_focusedHash == hash {
            this.MarkThreadRead(thread);
          }
          dialog.CBQueueRedraw(true);   // drawn on the panel's own frame
        }
        // A thread V is reading is redrawn either way; only the notification is held back.
        if announce || shownNow {
          this.m_phoneCtrl.CBDeliverThread(hash, sender, body, sound);
        }
      } else {
        // Cards are Cards mode's. In Phone mode a message with no thread to open (more senders this
        // session than the phone keeps) is not turned into a card either.
        if announce && !phoneMode {
          this.ShowCard(game, sender, body, this.m_pendAccent[k], sound);
        }
      }
      k += 1;
    }
    ArrayClear(this.m_pendThread);
    ArrayClear(this.m_pendBody);
    ArrayClear(this.m_pendAccent);
  }

  // Put a card on screen. The fallback surface, and the whole surface in Cards mode.
  private func ShowCard(game: GameInstance, sender: String, body: String, accent: HDRColor,
                        sound: Bool) -> Void {
    // On screen, oldest first so the newest card is at the bottom, the way a thread reads.
    // When the stack is full the oldest card goes rather than the newest being dropped: the
    // thing that just happened is the thing the player needs.
    ArrayPush(this.m_sender, sender);
    ArrayPush(this.m_body, CBHudTrim(body, CBConfig.PhoneBodyMaxChars()));
    ArrayPush(this.m_stamp, CBPhoneStamp(game));
    ArrayPush(this.m_accent, accent);
    ArrayPush(this.m_left, CBPhoneHoldSeconds());
    ArrayPush(this.m_shown, 0.0);
    while ArraySize(this.m_sender) > CBConfig.PhoneCardRows() {
      ArrayErase(this.m_sender, 0);
      ArrayErase(this.m_body, 0);
      ArrayErase(this.m_stamp, 0);
      ArrayErase(this.m_accent, 0);
      ArrayErase(this.m_left, 0);
      ArrayErase(this.m_shown, 0);
    }
    // Start the clock here rather than letting Update discover a stale one. Update returns on
    // its first card check while nothing is on screen, so without this the first delta after a
    // quiet stretch is the length of that stretch.
    let tsNow = GameInstance.GetTimeSystem(game);
    if IsDefined(tsNow) {
      this.m_lastSimTime = EngineTime.ToFloat(tsNow.GetSimTime());
    }
    // The phone's own tone, played the way the game plays it: journalNotification.script sets
    // `soundEvent = 'ui_phone_sms'` and the notification system hands it to the audio system,
    // so this is the same event through the same door rather than a guess at an emitter.
    if sound {
      let audio = GameInstance.GetAudioSystem(game);
      if IsDefined(audio) {
        audio.Play(n"ui_phone_sms");
      }
    }
  }

  // Take everything off the screen and out of the phone. Called after a hard reset, when the
  // messages describe a reputation that no longer exists.
  public func Clear() -> Void {
    ArrayClear(this.m_sender);
    ArrayClear(this.m_body);
    ArrayClear(this.m_stamp);
    ArrayClear(this.m_accent);
    ArrayClear(this.m_left);
    ArrayClear(this.m_shown);
    ArrayClear(this.m_thName);
    ArrayClear(this.m_thUnread);
    ArrayClear(this.m_thTime);
    ArrayClear(this.m_thOffer);
    ArrayClear(this.m_thLead);
    ArrayClear(this.m_thLeadPrice);
    ArrayClear(this.m_thLeadTipster);
    ArrayClear(this.m_thLeadHaggled);
    ArrayClear(this.m_thLastBody);
    ArrayClear(this.m_thLastAt);
    ArrayClear(this.m_thAnsweredAt);
    ArrayClear(this.m_hsSender);
    ArrayClear(this.m_hsBody);
    ArrayClear(this.m_hsAccent);
    ArrayClear(this.m_hsKey);
    ArrayClear(this.m_hsFaction);
    ArrayClear(this.m_hsDue);
    ArrayClear(this.m_hsFrom);
    ArrayClear(this.m_hsSpan);
    this.m_lastFightReal = 0.0;
    ArrayClear(this.m_toldKey);
    ArrayClear(this.m_toldAt);
    this.m_lastWordReal = 0.0;
    ArrayClear(this.m_msgThread);
    ArrayClear(this.m_msgBody);
    ArrayClear(this.m_msgMine);
    this.m_focusedHash = 0;
    ArrayClear(this.m_pendThread);
    ArrayClear(this.m_pendBody);
    ArrayClear(this.m_pendAccent);
    // What was last announced belonged to threads that are gone. Kept, the first text after a start
    // over could be taken for a repeat of it (the threads start again at 0) and never ring.
    this.m_lastNotifyAt = 0.0;
    this.m_lastNotifyBody = "";
    this.m_lastNotifyThread = 0;
    this.m_phoneWaitSince = 0.0;
    this.m_subLeft = 0.0;
    this.m_subDirty = false;
    this.HideNativeLine();
    if IsDefined(this.m_subRoot) {
      this.m_subRoot.SetVisible(false);
    }
    let i = 0;
    while i < ArraySize(this.m_rows) {
      if IsDefined(this.m_rows[i].root) {
        this.m_rows[i].root.SetVisible(false);
      }
      i += 1;
    }
  }
}

// ---- Colours and clocks ---------------------------------------------------

public func CBPhoneBack() -> HDRColor = new HDRColor(0.035, 0.045, 0.060, 0.88)

public func CBPhoneSoundOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().phoneSound;
}

// The time on the card, as the city's clock reads it.
public func CBPhoneStamp(game: GameInstance) -> String {
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(ts) {
    return "";
  }
  let gt = ts.GetGameTime();
  return CBPhonePad(GameTime.Hours(gt)) + ":" + CBPhonePad(GameTime.Minutes(gt));
}

func CBPhonePad(n: Int32) -> String {
  if n < 10 {
    return "0" + IntToString(n);
  }
  return IntToString(n);
}

// How long a card stays, scaled by the same reading-speed setting the old channel used.
public func CBPhoneHoldSeconds() -> Float {
  return MaxF(CBConfig.PhoneHoldSeconds() * CBMessageHold(), CBConfig.PhoneHoldFloor());
}

// ---- The game's subtitles -------------------------------------
//
// The game draws subtitles from lines put on the UIGameData blackboard (ShowDialogLine) and takes them down by id
// (HideDialogLine): baseSubtitlesControllers.script, SubtitlesGameController.

// Is the player showing the game's subtitles? The same setting the subtitles controller reads.
public func CBGameSubtitlesOn(game: GameInstance) -> Bool {
  let settings = GameInstance.GetSettingsSystem(game);
  if !IsDefined(settings) || !settings.HasVar(n"/accessibility/subtitles", n"Cinematic") {
    return true;
  }
  let cinematic = settings.GetVar(n"/accessibility/subtitles", n"Cinematic") as ConfigVarBool;
  return !IsDefined(cinematic) || cinematic.GetValue();
}

// Cyberbane's subtitle line ids: 0 and 1 for what V overhears, taken in turn, 2 for V's own line in a street exchange
// and 3 for the answer (Reactions/StreetTalk.reds).
public func CBSubtitleIdCount() -> Int32 = 6

func CBSubtitleLineId(slot: Int32) -> CRUID {
  if slot == 1 {
    return CreateCRUID(7310582093516161002ul);
  }
  if slot == 2 {
    return CreateCRUID(7310582093516161003ul);
  }
  if slot == 3 {
    return CreateCRUID(7310582093516161004ul);
  }
  if slot == 4 {
    return CreateCRUID(7310582093516161005ul);
  }
  if slot == 5 {
    return CreateCRUID(7310582093516161006ul);
  }
  return CreateCRUID(7310582093516161001ul);
}

// A line's own take-down.
public class CBSubtitleHideCallback extends DelayCallback {
  public let game: GameInstance;
  public let id: Int32;
  public let gen: Int32;

  public func Call() -> Void {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.SubtitleGen(this.id) == this.gen {
      CBHideSubtitleId(this.game, this.id);
    }
  }
}

public func CBShowGameSubtitle(game: GameInstance, slot: Int32, speaker: String, text: String,
                               seconds: Float) -> Bool {
  let player = GetPlayer(game);
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(player) || !IsDefined(bbs) || StrLen(text) == 0 {
    return false;
  }
  let bb = bbs.Get(GetAllBlackboardDefs().UIGameData);
  if !IsDefined(bb) {
    return false;
  }
  CBLineHeard(text);   // the street's memory of what it has said (Narrative/Lines.reds)
  // V's line and the answer each go up under whichever of their channel's two ids is not up now, and the one
  // that is comes down (see CBSubtitleLineId).
  let id = slot;
  let rt = CyberbaneRuntime.Get();
  // The answer goes up and V's own line comes down: with lines held for as long as they take to read, the two would
  // otherwise share the space.
  if slot == 3 {
    CBHideGameSubtitle(game, 2);
  }
  if (slot == 2 || slot == 3) && IsDefined(rt) {
    let up = rt.SubtitleUp(slot);
    id = up == slot ? slot + 2 : slot;
    CBHideSubtitleId(game, up);
    rt.SetSubtitleUp(slot, id);
  }
  let line: scnDialogLineData;
  line.id = CBSubtitleLineId(id);
  line.text = text;
  line.type = scnDialogLineType.Regular;
  line.speaker = player;
  line.speakerName = speaker;
  line.isPersistent = false;
  line.duration = seconds;
  let lines: array<scnDialogLineData>;
  ArrayPush(lines, line);
  bb.SetVariant(GetAllBlackboardDefs().UIGameData.ShowDialogLine, ToVariant(lines), true);
  let ds = GameInstance.GetDelaySystem(game);
  if IsDefined(rt) && IsDefined(ds) {
    let cb = new CBSubtitleHideCallback();
    cb.game = game;
    cb.id = id;
    cb.gen = rt.SubtitleGenBump(id);
    ds.DelayCallback(cb, MaxF(seconds, 0.5), false);
  }
  return true;
}

// Down, for one of the slots the callers name: a channel's both ids (2 and 3), or the one id (0 and 1).
public func CBHideGameSubtitle(game: GameInstance, slot: Int32) -> Void {
  CBHideSubtitleId(game, slot);
  if slot == 2 || slot == 3 {
    CBHideSubtitleId(game, slot + 2);
  }
}

func CBHideSubtitleId(game: GameInstance, slot: Int32) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let bb = bbs.Get(GetAllBlackboardDefs().UIGameData);
  if !IsDefined(bb) {
    return;
  }
  let ids: array<CRUID>;
  ArrayPush(ids, CBSubtitleLineId(slot));
  bb.SetVariant(GetAllBlackboardDefs().UIGameData.HideDialogLine, ToVariant(ids), true);
}

// How long a spoken line stays up: long enough to read it, times How long words stay on screen.
public func CBTalkReadSeconds(text: String, base: Float) -> Float {
  let read = CBConfig.ReadSecondsBase() + Cast<Float>(StrLen(text)) * CBConfig.ReadSecondsPerChar();
  return MaxF(base, read) * CBMessageHold();
}

// How long an overheard line stays. Shorter than a card: it is one sentence somebody said.
public func CBOverheardSeconds() -> Float {
  return MaxF(CBConfig.OverheardSeconds() * CBMessageHold(), CBConfig.OverheardFloor());
}

// Something V overheard. Never a text and never in the phone; see CBPhone.Overhear.
public func CBOverheard(game: GameInstance, speaker: String, line: String, opt important: Bool) -> Void {
  if !CBMessagesOn() {
    return;
  }
  if Equals(CBMessageDelivery(), ECBMessageDelivery.Notices) {
    CBLineHeard(line);
    CBShowMessage(game, speaker + ": " + line, CBConfig.OverheardSeconds());
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  sys.GetPhone().Overhear(game, speaker, line, important);
}

// ---- The one door everything goes through ---------------------------------

// Send a message from a particular contact.
public func CBPhoneSend(game: GameInstance, sender: String, body: String) -> Void {
  CBPhoneSendTinted(game, sender, body, CBHudCyan());
}

// As above, with the accent a card uses to say what kind of message this is. Written now, it lands a little later
// (CBPhone.Post): nobody texts back the instant something happens.
public func CBPhoneSendTinted(game: GameInstance, sender: String, body: String,
                              accent: HDRColor) -> Void {
  CBPhonePost(game, sender, body, accent, false, 0, n"", 0, 0);
}

// Something is on V right now (a lookout, an ally's heads-up): a moment, not a while.
public func CBPhoneSendUrgent(game: GameInstance, sender: String, body: String, accent: HDRColor) -> Void {
  CBPhonePost(game, sender, body, accent, true, 0, n"", 0, 0);
}

// Every text goes through here, with what it opens or closes in its thread when it lands: `then` 1 asks nothing back, 2
// a gang's price on V (`faction`), 3 a lead on a Rival (`rival`, `price`, the tipster in `faction`).
public func CBPhonePost(game: GameInstance, sender: String, body: String, accent: HDRColor, urgent: Bool, then: Int32,
                        faction: CName, rival: Int32, price: Int32) -> Void {
  if !CBMessagesOn() {
    return;
  }
  // Heard as it is written, so the same line is not picked again while this one is on its way.
  CBLineHeard(body);
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  sys.GetPhone().Post(game, sender, body, accent, urgent, then, faction, rival, price);
}

// It lands: the phone, or the old centre-screen line for anybody who keeps it. The silence switches and the delivery mode
// are asked now, when it arrives.
public func CBPhoneDeliverNow(game: GameInstance, sender: String, body: String, accent: HDRColor, isAnswer: Bool) -> Void {
  if !CBMessagesOn() {
    return;
  }
  if Equals(CBMessageDelivery(), ECBMessageDelivery.Notices) {
    CBShowMessage(game, sender + ": " + body, CBConfig.PhoneHoldSeconds());
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  sys.GetPhone().Send(game, sender, body, accent, isAnswer);
}

// A text that asks nothing back: filed and shown as any other, and the thread offers no answers under it. For somebody
// whose other texts can be answered, a Rival above all, when this one is not a threat.
public func CBPhoneSendAside(game: GameInstance, sender: String, body: String, accent: HDRColor) -> Void {
  CBPhonePost(game, sender, body, accent, false, 1, n"", 0, 0);   // settled as it lands
}

// The gang is talking to you. Red, because they are not getting in touch to be friendly. Nothing to answer: news, a
// grudge, an answer to something V said.
public func CBPhoneFromGang(game: GameInstance, faction: CName, body: String) -> Void {
  CBPhoneSendTinted(game, CBPhoneGangSender(faction), body, CBHudRed());
}

// A threat V can answer from the phone (UI/RealPhone.reds): pay what they want, haggle, stall, threaten back, insult
// them or refuse; the same peace the Hub brokers, at the same price, through the same function.
public func CBPhoneDemandFromGang(game: GameInstance, faction: CName, body: String, opt priced: Bool) -> Void {
  // The answers open under it as it lands, not under whatever the thread said before.
  CBPhonePost(game, CBPhoneGangSender(faction), CBPhoneDemandText(game, faction, body, priced), CBHudRed(), false, 2, faction, 0, 0);
}

// A threat's words as they go out: as written when they name the price, when nobody can answer them, or when an offer
// is already open in the thread (its price is just above); otherwise with the price said after them.
public func CBPhoneDemandText(game: GameInstance, faction: CName, body: String, priced: Bool) -> String {
  if priced || !CBRealPhoneOn() || !CBToastsOn() {
    return body;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return body;
  }
  let quote = CBPeaceQuote(sys, game, faction);
  if quote < 0 || sys.GetPhone().OfferOpenFor(CBPhoneGangSender(faction)) {
    return body;
  }
  return body + " " + CBPeaceAskLine(quote);
}

// A gang on V's side: a tip-off, a welcome, a bounty paid. Same thread as the rest of what that
// gang sends, but nothing in it is a threat, so it is not tinted as one and never carries a peace
// offer.
public func CBPhoneFromAlly(game: GameInstance, faction: CName, body: String) -> Void {
  CBPhoneSendTinted(game, CBPhoneGangSender(faction), body, CBHudCyan());
}

// The gang again, but with nothing for V to answer: their reply to V turning them down.
public func CBPhoneFromGangFinal(game: GameInstance, faction: CName, body: String) -> Void {
  CBPhoneSendTinted(game, CBPhoneGangSender(faction), body, CBHudRed());
}

func CBPhoneOfferPeace(game: GameInstance, faction: CName) -> Void {
  // Only the phone can carry an answer, and only a message that was actually filed can be
  // answered.
  if !CBRealPhoneOn() || !CBToastsOn() {
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) || CBPeaceQuote(sys, game, faction) < 0 {
    return;
  }
  sys.GetPhone().OfferPeace(CBPhoneGangSender(faction), faction);
}

// Somebody who works this part of town is talking to you.
public func CBPhoneFromDistrict(game: GameInstance, district: CName, body: String) -> Void {
  CBPhoneSend(game, CBPhoneDistrictSender(district), body);
}

// Somebody on the street is talking to you.
public func CBPhoneFromStreet(game: GameInstance, body: String) -> Void {
  CBPhoneSend(game, CBPhoneStreetSender(RandRange(0, 4)), body);
}

// Cyberbane itself is talking to you, and there is no pretending otherwise: a tracker pinged, a fatal flaw found, a
// scan's find, a hint. On the old channel, because a text message from nobody about it is worse than a line of text.
public func CBSystemNote(game: GameInstance, body: String, duration: Float) -> Void {
  if !CBMessagesOn() {
    return;
  }
  CBShowMessage(game, CBTf(n"Cyberbane-PhoneMessages-Cyberbane", [body]), duration);
}

// The answer to something V just did in a menu (the Hub's buttons, Mod Settings): a reputation wiped, Rivals forgotten,
// a lead that could not be bought.
public func CBMenuNote(game: GameInstance, body: String, duration: Float) -> Void {
  CBShowMessage(game, CBTf(n"Cyberbane-PhoneMessages-Cyberbane", [body]), duration, true);   // first in line, never dropped
}

// ---- Word that has to get round first --------------------------------------
//
// The same senders as above, for anything that is somebody passing on what V did.

public func CBWordTravelSeconds() -> Float {
  let rt = CyberbaneRuntime.Get();
  let minutes = CBConfig.WordTravelMinutesDefault();
  if IsDefined(rt) && rt.HasSettings() {
    minutes = rt.GetSettings().wordTravelMinutes;
  }
  return Cast<Float>(Max(0, minutes)) * CBConfig.SecondsPerHour() / 60.0;
}

public func CBInboxGapSeconds() -> Float {
  let rt = CyberbaneRuntime.Get();
  let gap = CBConfig.InboxGapSecondsDefault();
  if IsDefined(rt) && rt.HasSettings() {
    gap = rt.GetSettings().inboxGapSeconds;
  }
  return Cast<Float>(Max(0, gap));
}

func CBHearsayTinted(game: GameInstance, sender: String, body: String, accent: HDRColor,
                     key: CName, offerFaction: CName, opt from: CName, opt important: Bool) -> Void {
  if !CBMessagesOn() {
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  sys.GetPhone().Hearsay(game, sender, body, accent, key, offerFaction, from, important);
}

// Somebody's answer to what V did: a gang naming a new Rival, a Rival's own taunt, a gang that learnt how V fights or
// turned V away.
public func CBAnswerLater(game: GameInstance, sender: String, body: String, accent: HDRColor) -> Void {
  CBHearsayTinted(game, sender, body, accent, n"", n"", n"", true);
}

public func CBGangAnswerLater(game: GameInstance, faction: CName, body: String) -> Void {
  CBAnswerLater(game, CBPhoneGangSender(faction), body, CBHudRed());
}

public func CBAllyAnswerLater(game: GameInstance, faction: CName, body: String) -> Void {
  CBAnswerLater(game, CBPhoneGangSender(faction), body, CBHudCyan());
}

// A gang's answer that carries its price on V: answerable from the phone once it lands, as a demand sent now is.
public func CBGangDemandLater(game: GameInstance, faction: CName, body: String) -> Void {
  CBHearsayTinted(game, CBPhoneGangSender(faction), body, CBHudRed(), n"", faction, n"", true);
}

public func CBHearsayFromStreet(game: GameInstance, body: String, key: CName) -> Void {
  CBHearsayTinted(game, CBPhoneStreetSender(RandRange(0, 4)), body, CBHudCyan(), key, n"");
}

public func CBHearsayFromDistrict(game: GameInstance, district: CName, body: String, key: CName) -> Void {
  CBHearsayTinted(game, CBPhoneDistrictSender(district), body, CBHudCyan(), key, n"", district);   // news from there
}

// A gang's threat that waits for word to get round: answerable once it arrives (CBPhoneDemandFromGang).
public func CBHearsayFromGang(game: GameInstance, faction: CName, body: String, key: CName) -> Void {
  CBHearsayTinted(game, CBPhoneGangSender(faction), body, CBHudRed(), key, faction);
}

// The gang, with nothing for V to answer.
public func CBHearsayFromGangFinal(game: GameInstance, faction: CName, body: String, key: CName) -> Void {
  CBHearsayTinted(game, CBPhoneGangSender(faction), body, CBHudRed(), key, n"");
}

public func CBHearsayFromAlly(game: GameInstance, faction: CName, body: String, key: CName) -> Void {
  CBHearsayTinted(game, CBPhoneGangSender(faction), body, CBHudCyan(), key, n"");
}

// From the broker who works the part of town V is in now, the way CBContactMessage picks them.
public func CBHearsayFromContact(game: GameInstance, body: String, key: CName) -> Void {
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) && NotEquals(sys.GetCurrentDistrict(), n"") {
    CBHearsayFromDistrict(game, sys.GetCurrentDistrict(), body, key);
    return;
  }
  CBHearsayFromStreet(game, body, key);
}
