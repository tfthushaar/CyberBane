// Cyberbane - Messages instead of popups (spec §12.2)
//
// Every player report about this mod's presentation said the same thing in different words:
// "can the gang messages be actual text messages instead of showing on the HUD", "the constant
// popups ruin it", "it doesn't feel immersive with the popups". A line of white text across the
// middle of the screen is a mod talking to you. A text from somebody is the city talking to you,
// and this mod is entirely about the city noticing you.
//
// ---- Where the messages go ----
//
// Into the phone V already carries. Each sender is a contact in the phone's own Messages list:
// the gang that is coming for you, the broker who works the district you are in, an unknown
// number. A new message arrives through the game's own incoming-SMS notification, with the
// game's own tone, and pressing it opens the thread in the phone. The thread is drawn by the
// phone's own messenger panel, bubble by bubble. UI/RealPhone.reds is the hook that does that.
//
// Two fallbacks, both reachable from Mod Settings without the phone:
//   - Cards: Cyberbane draws the message itself on the left of the screen, where the game puts
//     an incoming SMS. Nothing of Cyberbane's goes into the phone in this mode, so if the phone
//     hook ever misbehaves on somebody's setup this switch takes it out completely.
//   - Notices: the old line across the middle of the screen.
//
// ---- Why these are not journal entries ----
//
// The reference mod the user supplied (Judy Romance Messages 4.0.6.1) sends real journal
// messages. Its redscript only listens to two quest facts; the messages are an authored
// `.journal` and `.questphase` injected by ArchiveXL, with every string fixed when the archive
// was built. Cyberbane's messages are put together at runtime out of a gang's name, a Rival's
// name, a district and a price, and a journal entry cannot hold "the Valentinos want 14,500eb
// to call it off". So the phone gets Cyberbane contacts whose threads Cyberbane draws, which
// keeps every word dynamic and needs no archive.
//
// Putting the words in a real character's mouth was considered and refused. A fixer the story
// wrote texting "the Animals have sent a crew" reads as a real lead, and a player cannot tell it
// apart from a gig. Cyberbane's contacts are its own: the gang itself, district brokers, unknown
// numbers. Nobody the base game has written.
//
// ---- Session only ----
//
// The threads start empty after a load. Keeping them in the save needs a new `persistent let`,
// and adding one wipes every player's saved Cyberbane state (see the warning at the top of
// STATUS.md). An inbox that starts empty is a far smaller cost than a wiped reputation.
//
// Crash safety: Send only pushes onto arrays, so it is safe from any hook. Everything that
// touches a widget or the phone runs from Update, which the fast tick only reaches once it has
// passed the world-stable gate. Nothing here holds an entity handle; the phone controller and
// the open messenger panel are held weakly and re-checked on every use.

// ---- Who is texting -------------------------------------------------------
//
// Handles rather than names, for the reason above. A player should read these as somebody on
// the street who knows things, never as a quest-giver. Written the way the phone writes a
// contact's name; the cards put them in capitals themselves.

// The gang itself, when the message is the gang speaking.
public func CBPhoneGangSender(faction: CName) -> String {
  let label = CBFactionLabel(faction);
  if StrLen(label) == 0 {
    return "Unknown Number";
  }
  if StrBeginsWith(label, "the ") {
    return StrMid(label, 4, StrLen(label) - 4);
  }
  return label;
}

// The local information broker, one per district, so the same handle keeps turning up in the
// same part of town. This is what makes the grapevine read as people rather than as a feed:
// word out of Watson arrives from the person who works Watson.
public func CBPhoneDistrictSender(district: CName) -> String {
  if Equals(district, n"Watson") { return "Salt"; }
  if Equals(district, n"Westbrook") { return "Mira"; }
  if Equals(district, n"CityCenter") { return "Glasswork"; }
  if Equals(district, n"Heywood") { return "Tio Benny"; }
  if Equals(district, n"Pacifica") { return "Low Tide"; }
  if Equals(district, n"SantoDomingo") { return "Radiator"; }
  if Equals(district, n"Badlands") { return "Dust"; }
  if Equals(district, n"Dogtown") { return "Split Lip"; }
  return "Unknown Number";
}

// For word that is not about anywhere in particular.
public func CBPhoneStreetSender(seed: Int32) -> String {
  let s = seed % 4;
  if s == 0 { return "Unknown Number"; }
  if s == 1 { return "Broker"; }
  if s == 2 { return "Ripperdoc"; }
  return "No Caller ID";
}

// ---- How messages are delivered -------------------------------------------

public func CBMessageDelivery() -> ECBMessageDelivery {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return ECBMessageDelivery.Phone;
  }
  return rt.GetSettings().messageDelivery;
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
  // Every message, oldest first, each tagged with the thread it belongs to, and whether V
  // sent it (a reply) or received it.
  private let m_msgThread: array<Int32>;
  private let m_msgBody: array<String>;
  private let m_msgMine: array<Bool>;
  // The thread open and focused in the phone right now, so a message that arrives while the
  // player is reading it is not counted as unread. 0 when none is.
  private let m_focusedHash: Int32;

  // Waiting for a settled tick to be delivered.
  private let m_pendThread: array<Int32>;
  private let m_pendBody: array<String>;
  private let m_pendAccent: array<HDRColor>;

  // The phone in V's hand, and the messenger panel if one of ours is open in it. Weak, and
  // checked on every use: the HUD is rebuilt on every load and fast travel.
  private let m_phoneCtrl: wref<NewHudPhoneGameController>;
  private let m_openDialog: wref<MessengerDialogViewController>;

  // Something V overheard on the street. Not a text: nobody sent it, V was standing near the
  // person who said it. It is drawn as a line of subtitle at the bottom of the screen, the way
  // the game shows speech, and it never goes into the phone. One at a time; a newer line
  // replaces an older one, which is how overheard speech works.
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
    let font = "base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily";
    let width = CBConfig.PhoneCardWidth();
    let height = CBConfig.PhoneCardHeight();
    // The same fit the Hub and the threat bars use: these are authored in 1080p units and the
    // ink space is not always that big.
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
  }

  // The subtitle line: a speaker label over the words, centred near the bottom of the screen,
  // above where the game draws its own subtitles so the two never sit on top of each other.
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
  public func Overhear(game: GameInstance, speaker: String, line: String) -> Void {
    this.m_game = game;
    if StrLen(line) == 0 {
      return;
    }
    this.m_subNewSpeaker = speaker;
    this.m_subNewLine = line;
    this.m_subDirty = true;
    CBLog.Info(n"UI", s"Overheard (\(speaker)): \(line)");
  }

  // ---- Sending ------------------------------------------------------------

  // A message arrives. Safe from any hook: this only touches our own arrays. It is filed in
  // its sender's thread straight away and delivered on the next settled tick.
  public func Send(game: GameInstance, sender: String, body: String, accent: HDRColor) -> Void {
    this.m_game = game;
    if StrLen(body) == 0 {
      return;
    }
    let thread = this.ThreadFor(sender);
    if thread >= 0 {
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
    CBLog.Info(n"UI", s"V replied to \(this.m_thName[thread]): \(body)");
  }

  // A gang V can buy off has just been in touch: let V answer it.
  public func OfferPeace(sender: String, faction: CName) -> Void {
    let thread = this.ThreadFor(sender);
    if thread >= 0 {
      this.m_thOffer[thread] = faction;
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

  public func SetOpenDialog(dialog: ref<MessengerDialogViewController>) -> Void {
    this.m_openDialog = dialog;
  }

  // ---- Drawing ------------------------------------------------------------

  // Once per fast tick. Delivers anything waiting, then ages the cards, slides the new ones
  // in and fades the dying ones out.
  //
  // Driven off the simulation clock rather than counting ticks, because the tick interval is a
  // setting and a card's life is in seconds the player can read.
  public func Update(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.m_game = game;
    this.Deliver(game);
    if ArraySize(this.m_sender) == 0 && this.m_subLeft <= 0.0 {
      return;
    }
    // The Hub is a full-screen panel on this same layer and a card sits over the left of its
    // body text. Cards keep ageing while hidden, so closing the Hub does not hand back a stack
    // of stale ones, and every one of them is still in the phone.
    let hubOpen = IsDefined(sys) && sys.IsHubOpen();
    let ts = GameInstance.GetTimeSystem(game);
    if !IsDefined(ts) {
      return;
    }
    let now = EngineTime.ToFloat(ts.GetSimTime());
    let dt = this.m_lastSimTime > 0.0 ? now - this.m_lastSimTime : 0.0;
    this.m_lastSimTime = now;
    // A load or a time skip can hand back a nonsense delta; ignore it rather than wiping the
    // stack in one frame.
    if dt < 0.0 || dt > 5.0 {
      dt = 0.0;
    }
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
          // In from the left over a fifth of a second, out over the last of its life. Done by
          // hand rather than through PlayLibraryAnimation, which needs an animation authored in
          // a widget library - and there is no library here, the widgets are built from script.
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

  // Age the subtitle line and fade it in and out.
  private func TickOverheard(dt: Float, hubOpen: Bool) -> Void {
    if !IsDefined(this.m_subRoot) {
      return;
    }
    if this.m_subLeft <= 0.0 {
      this.m_subRoot.SetVisible(false);
      return;
    }
    this.m_subLeft -= dt;
    this.m_subShown += dt;
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

  // Hand everything waiting to whichever surface is in use. Runs on a settled tick only.
  private func Deliver(game: GameInstance) -> Void {
    if this.m_subDirty {
      this.m_subDirty = false;
      this.m_subLeft = CBOverheardSeconds();
      this.m_subShown = 0.0;
      let tsSub = GameInstance.GetTimeSystem(game);
      if IsDefined(tsSub) && ArraySize(this.m_sender) == 0 {
        this.m_lastSimTime = EngineTime.ToFloat(tsSub.GetSimTime());
      }
    }
    if ArraySize(this.m_pendBody) == 0 {
      return;
    }
    let usePhone = CBRealPhoneOn() && IsDefined(this.m_phoneCtrl);
    let sound = CBPhoneSoundOn();
    let k = 0;
    while k < ArraySize(this.m_pendBody) {
      let thread = this.m_pendThread[k];
      let body = this.m_pendBody[k];
      let sender = this.ThreadName(thread);
      if StrLen(sender) == 0 {
        sender = "Unknown Number";
      }
      // The phone, when there is one to hand it to and the message has a thread to open.
      // Anything else falls back to a card rather than being lost.
      if usePhone && thread >= 0 {
        let hash = CBPhoneThreadHash(thread);
        // One of ours is open in the phone right now: draw the new line straight into it,
        // and the player is reading it as it arrives.
        let dialog = this.m_openDialog;
        let shownNow = IsDefined(dialog) && dialog.cbThreadHash == hash;
        if shownNow {
          if this.m_focusedHash == hash {
            this.MarkThreadRead(thread);
          }
          dialog.CBRenderThread(true);
        }
        this.m_phoneCtrl.CBDeliverThread(hash, sender, body, sound);
      } else {
        this.ShowCard(game, sender, body, this.m_pendAccent[k], sound);
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
    ArrayClear(this.m_msgThread);
    ArrayClear(this.m_msgBody);
    ArrayClear(this.m_msgMine);
    this.m_focusedHash = 0;
    ArrayClear(this.m_pendThread);
    ArrayClear(this.m_pendBody);
    ArrayClear(this.m_pendAccent);
    this.m_subLeft = 0.0;
    this.m_subDirty = false;
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

// How long an overheard line stays. Shorter than a card: it is one sentence somebody said.
public func CBOverheardSeconds() -> Float {
  return MaxF(CBConfig.OverheardSeconds() * CBMessageHold(), CBConfig.OverheardFloor());
}

// Something V overheard. Never a text and never in the phone; see CBPhone.Overhear.
public func CBOverheard(game: GameInstance, speaker: String, line: String) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return;
  }
  if rt.HasSettings() && !rt.GetSettings().toasts {
    return;
  }
  if Equals(CBMessageDelivery(), ECBMessageDelivery.Notices) {
    CBShowMessage(game, speaker + ": " + line, CBConfig.OverheardSeconds());
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  sys.GetPhone().Overhear(game, speaker, line);
}

// ---- The one door everything goes through ---------------------------------

// Send a message from a particular contact.
//
// This is what the call sites that used to shout across the middle of the screen call now.
// Each one says who is speaking and what they are saying; what the presentation does with it
// is settled in one place.
public func CBPhoneSend(game: GameInstance, sender: String, body: String) -> Void {
  CBPhoneSendTinted(game, sender, body, CBHudCyan());
}

// As above, with the accent a card uses to say what kind of message this is.
public func CBPhoneSendTinted(game: GameInstance, sender: String, body: String,
                              accent: HDRColor) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return;
  }
  // The messages switch covers every surface, so a player who wants silence gets it.
  if rt.HasSettings() && !rt.GetSettings().toasts {
    return;
  }
  // Anyone who would rather have the old centre-screen line keeps it.
  if Equals(CBMessageDelivery(), ECBMessageDelivery.Notices) {
    CBShowMessage(game, sender + ": " + body, CBConfig.PhoneHoldSeconds());
    return;
  }
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  sys.GetPhone().Send(game, sender, body, accent);
}

// The gang is talking to you. Red, because they are not getting in touch to be friendly.
//
// If they are a gang V can buy off and they are hostile, the thread also gets an answer V can
// send from the phone (UI/RealPhone.reds): pay what they want, or refuse. That is the same
// peace the Hub brokers, at the same price, through the same function.
public func CBPhoneFromGang(game: GameInstance, faction: CName, body: String) -> Void {
  CBPhoneSendTinted(game, CBPhoneGangSender(faction), body, CBHudRed());
  CBPhoneOfferPeace(game, faction);
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

// Cyberbane itself is talking to you, and there is no pretending otherwise: a title unlocked, a
// reputation wiped, a settings change confirmed. These are the only things left on the old
// channel, because a text message from nobody about a menu you just used is worse than a line
// of white text.
public func CBSystemNote(game: GameInstance, body: String, duration: Float) -> Void {
  CBShowMessage(game, "Cyberbane: " + body, duration);
}
