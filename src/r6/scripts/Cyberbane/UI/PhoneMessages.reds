// Cyberbane - Messages instead of popups (spec §12.2)
//
// Every player report about this mod's presentation said the same thing in different words:
// "can the gang messages be actual text messages instead of showing on the HUD", "the constant
// popups ruin it", "it doesn't feel immersive with the popups". They are right. A line of white
// text across the middle of the screen is a mod talking to you. A text message from somebody is
// the city talking to you, and this mod is entirely about the city noticing you.
//
// ---- What a real phone message would have taken, and why this is not one ----
//
// The reference mod the user supplied (Judy Romance Messages 4.0.6.1) does send real in-game
// messages, and reading it is what settled this question rather than leaving it a guess. Its
// redscript does nothing but listen to two quest facts. The messages themselves are in the
// archive, declared in `JRME_4.0.archive.xl`:
//
//     quest:   phases: - path: mod\...\jrme_root.questphase
//     journal: - mod\...\jrme_journal.journal
//
// So: an authored `.journal` resource injected by ArchiveXL, driven by an authored quest phase
// graph, with the text in an authored onscreens `.json` per language. That is the only route to
// a genuine `JournalPhoneMessage`, and it has two properties that rule it out here. It needs
// binary CR2W resources built in WolvenKit, which a script-only mod cannot produce at runtime;
// and every message is a fixed localized string chosen at authoring time. Cyberbane's messages
// are assembled at runtime out of a gang's name, a Rival's name, a district, a price and a
// count. A journal entry cannot hold "the Valentinos want 14,500eb to call it off".
//
// Putting the words in a real character's mouth was also considered and refused. Judy sending
// more Judy messages is in character for a romance mod. A fixer texting "the Animals have sent
// a crew" is a fixer apparently offering a real lead, and a player cannot tell flavour from a
// gig they should act on. Cyberbane's contacts are its own: handles, brokers, a ripperdoc, the
// gang itself. Nobody the base game has written.
//
// ---- So what this is ----
//
// The messenger's own presentation, drawn by Cyberbane: the sender, the time, the message, in
// the phone's visual language, on the left of the screen where the game puts an incoming SMS,
// with the game's own `ui_phone_sms` tone. Messages stack like a thread rather than replacing
// one another, which is the other half of the complaint - the HUD channel shows one line at a
// time, so a Rival arriving while a crew was dispatched meant the player read half of one
// sentence. And the Hub keeps the thread, so anything missed can be read back.
//
// The thread is for this session only. That is a deliberate limit, not an oversight: a
// persisted thread means a new `persistent let`, and adding one wipes every player's saved
// Cyberbane state (see the warning at the top of STATUS.md). A reputation reset is a far worse
// bug than an inbox that starts empty after a load.
//
// Crash safety: rows are created once on an inkHUDLayer virtual window and afterwards only have
// their text, size, colour and visibility set. Nothing here holds an entity handle, and Send is
// safe to call from any tick because it only pushes onto arrays - the widgets are built lazily
// by Update, on a tick that has already passed the world-stable gate.

// ---- Who is texting -------------------------------------------------------
//
// Handles rather than names, for the reason above. A player should read these as somebody on
// the street who knows things, never as a quest-giver.

// The gang itself, when the message is the gang speaking.
public func CBPhoneGangSender(faction: CName) -> String {
  let label = CBFactionLabel(faction);
  if StrLen(label) == 0 {
    return "UNKNOWN NUMBER";
  }
  return StrUpper(StrReplace(label, "the ", ""));
}

// The local information broker, one per district, so the same handle keeps turning up in the
// same part of town. This is what makes the grapevine read as people rather than as a feed:
// word out of Watson arrives from the person who works Watson.
public func CBPhoneDistrictSender(district: CName) -> String {
  if Equals(district, n"Watson") { return "SALT"; }
  if Equals(district, n"Westbrook") { return "MIRA"; }
  if Equals(district, n"CityCenter") { return "GLASSWORK"; }
  if Equals(district, n"Heywood") { return "TIO BENNY"; }
  if Equals(district, n"Pacifica") { return "LOW TIDE"; }
  if Equals(district, n"SantoDomingo") { return "RADIATOR"; }
  if Equals(district, n"Badlands") { return "DUST"; }
  if Equals(district, n"Dogtown") { return "SPLIT LIP"; }
  return "UNKNOWN NUMBER";
}

// For word that is not about anywhere in particular.
public func CBPhoneStreetSender(seed: Int32) -> String {
  let s = seed % 4;
  if s == 0 { return "UNKNOWN NUMBER"; }
  if s == 1 { return "A BROKER"; }
  if s == 2 { return "RIPPERDOC"; }
  return "NO CALLER ID";
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

  // The popups currently on screen. Parallel arrays, as everything else in this codebase does
  // it, so there is never a dynamic array nested inside a class that might one day be persisted.
  private let m_sender: array<String>;
  private let m_body: array<String>;
  private let m_stamp: array<String>;
  private let m_accent: array<HDRColor>;
  private let m_left: array<Float>;    // seconds of life remaining
  private let m_shown: array<Float>;   // seconds on screen, for the slide-in

  // The session thread, newest first, for the Hub.
  private let m_logSender: array<String>;
  private let m_logBody: array<String>;
  private let m_logStamp: array<String>;

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
    this.m_built = true;
  }

  // ---- Sending ------------------------------------------------------------

  // A message arrives. Safe from any tick: this only touches our own arrays.
  public func Send(game: GameInstance, sender: String, body: String, accent: HDRColor) -> Void {
    this.m_game = game;
    if StrLen(body) == 0 {
      return;
    }
    let stamp = CBPhoneStamp(game);
    // The thread keeps everything, including anything dropped from the screen below.
    ArrayInsert(this.m_logSender, 0, sender);
    ArrayInsert(this.m_logBody, 0, body);
    ArrayInsert(this.m_logStamp, 0, stamp);
    while ArraySize(this.m_logSender) > CBConfig.PhoneLogCap() {
      let last = ArraySize(this.m_logSender) - 1;
      ArrayErase(this.m_logSender, last);
      ArrayErase(this.m_logBody, last);
      ArrayErase(this.m_logStamp, last);
    }

    // On screen, oldest first so the newest card is at the bottom, the way a thread reads.
    // When the stack is full the oldest card goes rather than the newest being dropped: the
    // thing that just happened is the thing the player needs.
    ArrayPush(this.m_sender, sender);
    ArrayPush(this.m_body, CBHudTrim(body, CBConfig.PhoneBodyMaxChars()));
    ArrayPush(this.m_stamp, stamp);
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
    // its first line while nothing is on screen, so without this the first delta after a quiet
    // stretch is the length of that stretch - which the sanity clamp there throws away, costing
    // the card a frame of its slide for no reason.
    let tsNow = GameInstance.GetTimeSystem(game);
    if IsDefined(tsNow) {
      this.m_lastSimTime = EngineTime.ToFloat(tsNow.GetSimTime());
    }

    // The phone's own tone, played the way the game plays it: journalNotification.script sets
    // `soundEvent = 'ui_phone_sms'` and the notification system hands it to the audio system,
    // so this is the same event through the same door rather than a guess at an emitter.
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().phoneSound {
      let audio = GameInstance.GetAudioSystem(game);
      if IsDefined(audio) {
        audio.Play(n"ui_phone_sms");
      }
    }
    CBLog.Info(n"UI", s"Message from \(sender): \(body)");
  }

  // ---- Drawing ------------------------------------------------------------

  // Once per fast tick. Ages the cards, slides the new ones in, fades the dying ones out.
  //
  // Driven off the simulation clock rather than counting ticks, because the tick interval is a
  // setting and a card's life is in seconds the player can read.
  public func Update(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.m_game = game;
    if ArraySize(this.m_sender) == 0 {
      return;
    }
    // The Hub is a full-screen panel on this same layer, and a card is positioned over the
    // left of its body text. Nothing is lost by holding them: the Hub's own MESSAGES screen is
    // showing the thread, which is strictly more than the card would have said. They keep
    // ageing while hidden, so closing the Hub does not hand back a stack of stale cards.
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

  // Take everything off the screen. Called when the kill switch is thrown.
  public func Clear() -> Void {
    ArrayClear(this.m_sender);
    ArrayClear(this.m_body);
    ArrayClear(this.m_stamp);
    ArrayClear(this.m_accent);
    ArrayClear(this.m_left);
    ArrayClear(this.m_shown);
    let i = 0;
    while i < ArraySize(this.m_rows) {
      if IsDefined(this.m_rows[i].root) {
        this.m_rows[i].root.SetVisible(false);
      }
      i += 1;
    }
  }

  // ---- The thread, for the Hub -------------------------------------------

  public func LogCount() -> Int32 {
    return ArraySize(this.m_logSender);
  }

  public func LogSender(i: Int32) -> String {
    if i < 0 || i >= ArraySize(this.m_logSender) {
      return "";
    }
    return this.m_logSender[i];
  }

  public func LogBody(i: Int32) -> String {
    if i < 0 || i >= ArraySize(this.m_logBody) {
      return "";
    }
    return this.m_logBody[i];
  }

  public func LogStamp(i: Int32) -> String {
    if i < 0 || i >= ArraySize(this.m_logStamp) {
      return "";
    }
    return this.m_logStamp[i];
  }
}

// ---- Colours and clocks ---------------------------------------------------

public func CBPhoneBack() -> HDRColor = new HDRColor(0.035, 0.045, 0.060, 0.88)

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

// ---- The one door everything goes through ---------------------------------

// Send a message from a particular contact.
//
// This is what the twenty-odd call sites that used to shout across the middle of the screen
// call now. Each one says who is speaking and what they are saying; what the presentation does
// with it is settled in one place, which is the same reasoning that put the reading-speed
// multiplier in CBShowMessage rather than at the call sites.
public func CBPhoneSend(game: GameInstance, sender: String, body: String) -> Void {
  CBPhoneSendTinted(game, sender, body, CBHudCyan());
}

// As above, with the accent that says what kind of message this is.
public func CBPhoneSendTinted(game: GameInstance, sender: String, body: String,
                              accent: HDRColor) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return;
  }
  // The messages switch covers both surfaces, so a player who wants silence still gets it.
  if rt.HasSettings() && !rt.GetSettings().toasts {
    return;
  }
  // Anyone who would rather have the old centre-screen line keeps it.
  if rt.HasSettings() && !rt.GetSettings().phoneMessages {
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
public func CBPhoneFromGang(game: GameInstance, faction: CName, body: String) -> Void {
  CBPhoneSendTinted(game, CBPhoneGangSender(faction), body, CBHudRed());
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
