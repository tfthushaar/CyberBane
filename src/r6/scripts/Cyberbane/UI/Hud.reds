// Cyberbane - The Hub (spec §12.1)
//
// A native-styled reputation readout drawn straight onto the gameplay HUD layer and
// toggled with the Hub key (F7 by default, rebindable in Mod Settings). It needs no
// menu or mouse: each press of the key steps through the tabs - Legend, Factions,
// Rivals, Titles, Legend Log - and the press after the last tab closes it. Because it
// never takes input focus it is safe to open any time you are not mid-combat, and it
// reads live data from CyberbaneSystem each time it is shown.
//
// The look is built from the game's own font (Rajdhani) and Cyberpunk's cyan-on-black
// palette, so it sits in the world like a stock UI panel. Widget geometry is tuned in
// game; everything here is reversible (it only adds widgets to the HUD layer).

public func CBHudTabCount() -> Int32 = 6

// Lines the body box can show at its size and font before text would spill past the footer.
// Body is 640 px tall at font size 20, so about 26 lines fit; 25 leaves a line of slack.
public func CBHudMaxLines() -> Int32 = 25

// Lines that fit below each screen's own content, before the footer at y=854. The meters
// end at 566 and the lists at 608, so those screens have far less room for prose than the
// plain ones that start at 212. Text is clamped to this, so nothing can run into the footer.
public func CBHudMaxLinesFor(tab: Int32) -> Int32 {
  if tab == 1 {
    // Ten, not eleven. The body sits above a fixed footer line, and at eleven the last line of
    // a full first page ran into it. Three lines of explanation came out of that screen when
    // the INCOMING block went in; this is the margin that keeps it from happening again if
    // anything is ever added back.
    return 10;
  }
  if tab == CBHudFactionsTab() || tab == CBHudRivalsTab() {
    return 9;
  }
  return CBHudMaxLines();
}

// Which tab the Rivals screen is, so the key handler does not hardcode a number.
public func CBHudRivalsTab() -> Int32 = 4
public func CBHudFactionsTab() -> Int32 = 2

// Layout. The panel is 1100 wide, and the content column starts at x=50.
public func CBHudChipWidth() -> Float = 166.0
public func CBHudBarCount() -> Int32 = 4
public func CBHudBarWidth() -> Float = 980.0
public func CBHudRowCount() -> Int32 = 10

// Colours, kept together so the screens read as one palette.
public func CBHudCyan() -> HDRColor = new HDRColor(0.10, 1.80, 2.10, 1.0)
public func CBHudAmber() -> HDRColor = new HDRColor(2.00, 1.30, 0.20, 1.0)
public func CBHudRed() -> HDRColor = new HDRColor(2.10, 0.35, 0.40, 1.0)
public func CBHudGreen() -> HDRColor = new HDRColor(0.40, 1.80, 0.90, 1.0)
public func CBHudGrey() -> HDRColor = new HDRColor(0.55, 0.62, 0.70, 1.0)

// Fast ticks are about a second, so this reads as real time to the player.
// Cut a column's text to what its box can actually show.
//
// The row columns are fixed pixel widths, and inkText does not clip, so an over-long string
// runs straight into the next column. Rival names are the dangerous ones: a name like
// Santiago "Last One Standing" Ibarra is 35 characters against a 28 character column.
// Budgets are per column and enforced in SetRow, so this cannot be forgotten at a call site.
public func CBHudTrim(text: String, maxChars: Int32) -> String {
  if StrLen(text) <= maxChars {
    return text;
  }
  if maxChars <= 1 {
    return "";
  }
  return StrLeft(text, maxChars - 1) + ".";
}

// Characters each row column can show at its width and font.
public func CBHudColA() -> Int32 = 28
public func CBHudColB() -> Int32 = 25
public func CBHudColC() -> Int32 = 13
public func CBHudColD() -> Int32 = 30

public func CBHudCountdown(ticks: Int32) -> String {
  if ticks <= 0 {
    return "any moment";
  }
  let mins = ticks / 60;
  let secs = ticks % 60;
  if mins <= 0 {
    return s"\(secs)s";
  }
  if secs < 10 {
    return s"\(mins)m 0\(secs)s";
  }
  return s"\(mins)m \(secs)s";
}

public func CBHudTabName(tab: Int32) -> String {
  switch tab {
    case 1: return "LEGEND";
    case 2: return "FACTIONS";
    case 3: return "DISTRICTS";
    case 4: return "RIVALS";
    case 5: return "TITLES";
    case 6: return "THE FILE";
    default: return "";
  }
}

public class CBHud {
  private let m_built: Bool;
  private let m_tab: Int32;               // 0 = closed, 1..CBHudTabCount = open on that tab
  private let m_root: ref<inkCanvas>;
  private let m_subhead: ref<inkText>;
  private let m_tabline: ref<inkText>;
  private let m_body: ref<inkText>;
  // Tab chips: one background and one label per tab, so the open tab is something you can
  // see rather than a word in a sentence.
  private let m_chipBg: array<ref<inkRectangle>>;
  private let m_chipText: array<ref<inkText>>;
  // Meters: label, value, track, fill and caption per score on the Legend screen.
  private let m_barLabel: array<ref<inkText>>;
  private let m_barValue: array<ref<inkText>>;
  private let m_barTrack: array<ref<inkRectangle>>;
  private let m_barFill: array<ref<inkRectangle>>;
  private let m_barCap: array<ref<inkText>>;
  // List rows: a colour pip and three columns, reused by the gang and rival screens.
  private let m_rowPip: array<ref<inkRectangle>>;
  private let m_rowA: array<ref<inkText>>;
  private let m_rowB: array<ref<inkText>>;
  private let m_rowC: array<ref<inkText>>;
  private let m_rowD: array<ref<inkText>>;
  // Whether arrivals are currently being held back because V is in the middle of a quiet job.
  // Resolved once per render, not once per row.
  private let m_holdLabel: String;   // why no Rival can arrive right now, or "" 

  public func IsOpen() -> Bool {
    return this.m_tab != 0;
  }

  public func GetTab() -> Int32 {
    return this.m_tab;
  }

  // Hub key pressed: advance to the next tab, closing once we step past the last.
  public func Advance(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if !this.EnsureBuilt() {
      return;
    }
    this.m_tab += 1;
    if this.m_tab > CBHudTabCount() {
      this.m_tab = 0;
    }
    this.Render(sys, game);
  }

  public func Close() -> Void {
    this.m_tab = 0;
    if IsDefined(this.m_root) {
      this.m_root.SetVisible(false);
    }
  }

  // Re-render the current tab in place (e.g. after an action like brokering peace).
  public func Refresh(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if this.m_tab != 0 {
      this.Render(sys, game);
    }
  }

  private func EnsureBuilt() -> Bool {
    if this.m_built && IsDefined(this.m_root) {
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

    let root = new inkCanvas();
    root.SetName(n"cyberbaneHub");
    root.SetAnchor(inkEAnchor.Fill);
    root.SetVisible(false);

    let backdrop = new inkRectangle();
    backdrop.SetAnchor(inkEAnchor.Fill);
    backdrop.SetTintColor(new HDRColor(0.01, 0.01, 0.02, 0.80));
    backdrop.Reparent(root);

    let panel = new inkCanvas();
    panel.SetAnchor(inkEAnchor.Centered);
    panel.SetAnchorPoint(new Vector2(0.5, 0.5));
    panel.SetSize(new Vector2(1100.0, 900.0));
    panel.Reparent(root);

    let panelBg = new inkRectangle();
    panelBg.SetAnchor(inkEAnchor.Fill);
    panelBg.SetTintColor(new HDRColor(0.04, 0.05, 0.07, 0.97));
    panelBg.Reparent(panel);

    let accent = new inkRectangle();
    accent.SetAnchor(inkEAnchor.TopLeft);
    accent.SetSize(new Vector2(1100.0, 5.0));
    accent.SetTintColor(new HDRColor(0.10, 2.20, 2.60, 1.0));
    accent.Reparent(panel);

    let stripe = new inkRectangle();
    stripe.SetAnchor(inkEAnchor.TopLeft);
    stripe.SetSize(new Vector2(5.0, 900.0));
    stripe.SetTintColor(new HDRColor(0.10, 2.20, 2.60, 1.0));
    stripe.Reparent(panel);

    let header = new inkText();
    header.SetFontFamily(font);
    header.SetFontStyle(n"Semibold");
    header.SetFontSize(50);
    header.SetLetterCase(textLetterCase.UpperCase);
    header.SetText("CYBERBANE");
    header.SetTintColor(new HDRColor(0.20, 2.00, 2.40, 1.0));
    header.SetAnchor(inkEAnchor.TopLeft);
    header.SetMargin(new inkMargin(48.0, 28.0, 0.0, 0.0));
    header.Reparent(panel);

    let subhead = new inkText();
    subhead.SetFontFamily(font);
    subhead.SetFontStyle(n"Medium");
    subhead.SetFontSize(26);
    subhead.SetTintColor(new HDRColor(0.80, 0.85, 0.90, 1.0));
    subhead.SetAnchor(inkEAnchor.TopLeft);
    subhead.SetMargin(new inkMargin(50.0, 100.0, 0.0, 0.0));
    subhead.Reparent(panel);
    this.m_subhead = subhead;

    let tabline = new inkText();
    tabline.SetFontFamily(font);
    tabline.SetFontStyle(n"Medium");
    tabline.SetFontSize(22);
    tabline.SetLetterCase(textLetterCase.UpperCase);
    tabline.SetTintColor(new HDRColor(0.10, 1.80, 2.10, 1.0));
    tabline.SetAnchor(inkEAnchor.TopLeft);
    tabline.SetMargin(new inkMargin(50.0, 146.0, 0.0, 0.0));
    tabline.SetVisible(false);   // replaced by the tab chips below
    tabline.Reparent(panel);
    this.m_tabline = tabline;

    let divider = new inkRectangle();
    divider.SetAnchor(inkEAnchor.TopLeft);
    divider.SetSize(new Vector2(1004.0, 2.0));
    divider.SetTintColor(new HDRColor(0.10, 1.20, 1.50, 0.45));
    divider.SetMargin(new inkMargin(48.0, 184.0, 0.0, 0.0));
    divider.Reparent(panel);

    let body = new inkText();
    body.SetFontFamily(font);
    body.SetFontStyle(n"Medium");
    body.SetFontSize(20);
    body.SetTintColor(new HDRColor(0.82, 0.88, 0.93, 1.0));
    body.SetAnchor(inkEAnchor.TopLeft);
    body.SetMargin(new inkMargin(50.0, 206.0, 0.0, 0.0));
    body.SetWrapping(true, 1004.0);
    body.SetSize(new Vector2(1004.0, 640.0));
    body.Reparent(panel);
    this.m_body = body;

    let footer = new inkText();
    footer.SetFontFamily(font);
    footer.SetFontStyle(n"Medium");
    footer.SetFontSize(18);
    footer.SetTintColor(new HDRColor(0.60, 0.65, 0.70, 0.75));
    footer.SetAnchor(inkEAnchor.TopLeft);
    footer.SetMargin(new inkMargin(50.0, 854.0, 0.0, 0.0));
    footer.SetText("Press the Hub key to cycle tabs, again on the last to close.  Settings: Pause > Mods > Cyberbane.");
    footer.Reparent(panel);

    // ---- Tab chips ------------------------------------------------------
    let t = 0;
    while t < CBHudTabCount() {
      let chip = new inkRectangle();
      chip.SetAnchor(inkEAnchor.TopLeft);
      chip.SetSize(new Vector2(CBHudChipWidth() - 8.0, 34.0));
      chip.SetMargin(new inkMargin(48.0 + Cast<Float>(t) * CBHudChipWidth(), 140.0, 0.0, 0.0));
      chip.Reparent(panel);
      ArrayPush(this.m_chipBg, chip);

      let label = new inkText();
      label.SetFontFamily(font);
      label.SetFontStyle(n"Medium");
      label.SetFontSize(19);
      label.SetLetterCase(textLetterCase.UpperCase);
      label.SetAnchor(inkEAnchor.TopLeft);
      label.SetMargin(new inkMargin(58.0 + Cast<Float>(t) * CBHudChipWidth(), 146.0, 0.0, 0.0));
      label.Reparent(panel);
      ArrayPush(this.m_chipText, label);
      t += 1;
    }

    // ---- Score meters ---------------------------------------------------
    let b = 0;
    while b < CBHudBarCount() {
      let top = 212.0 + Cast<Float>(b) * 86.0;

      let bl = new inkText();
      bl.SetFontFamily(font);
      bl.SetFontStyle(n"Semibold");
      bl.SetFontSize(24);
      bl.SetLetterCase(textLetterCase.UpperCase);
      bl.SetTintColor(new HDRColor(0.70, 0.80, 0.88, 1.0));
      bl.SetAnchor(inkEAnchor.TopLeft);
      bl.SetMargin(new inkMargin(50.0, top, 0.0, 0.0));
      bl.Reparent(panel);
      ArrayPush(this.m_barLabel, bl);

      let bv = new inkText();
      bv.SetFontFamily(font);
      bv.SetFontStyle(n"Semibold");
      bv.SetFontSize(24);
      bv.SetAnchor(inkEAnchor.TopLeft);
      bv.SetMargin(new inkMargin(760.0, top, 0.0, 0.0));
      bv.Reparent(panel);
      ArrayPush(this.m_barValue, bv);

      let track = new inkRectangle();
      track.SetAnchor(inkEAnchor.TopLeft);
      track.SetSize(new Vector2(CBHudBarWidth(), 14.0));
      track.SetTintColor(new HDRColor(0.10, 0.14, 0.18, 1.0));
      track.SetMargin(new inkMargin(50.0, top + 32.0, 0.0, 0.0));
      track.Reparent(panel);
      ArrayPush(this.m_barTrack, track);

      let fill = new inkRectangle();
      fill.SetAnchor(inkEAnchor.TopLeft);
      fill.SetSize(new Vector2(1.0, 14.0));
      fill.SetMargin(new inkMargin(50.0, top + 32.0, 0.0, 0.0));
      fill.Reparent(panel);
      ArrayPush(this.m_barFill, fill);

      let cap = new inkText();
      cap.SetFontFamily(font);
      cap.SetFontStyle(n"Medium");
      cap.SetFontSize(19);
      cap.SetTintColor(new HDRColor(0.55, 0.62, 0.70, 1.0));
      cap.SetAnchor(inkEAnchor.TopLeft);
      cap.SetMargin(new inkMargin(50.0, top + 52.0, 0.0, 0.0));
      cap.SetWrapping(true, 980.0);
      cap.Reparent(panel);
      ArrayPush(this.m_barCap, cap);
      b += 1;
    }

    // ---- List rows ------------------------------------------------------
    let r = 0;
    while r < CBHudRowCount() {
      let rtop = 212.0 + Cast<Float>(r) * 38.0;

      let pip = new inkRectangle();
      pip.SetAnchor(inkEAnchor.TopLeft);
      pip.SetSize(new Vector2(6.0, 24.0));
      pip.SetMargin(new inkMargin(50.0, rtop, 0.0, 0.0));
      pip.Reparent(panel);
      ArrayPush(this.m_rowPip, pip);

      let ra = new inkText();
      ra.SetFontFamily(font);
      ra.SetFontStyle(n"Semibold");
      ra.SetFontSize(22);
      ra.SetAnchor(inkEAnchor.TopLeft);
      ra.SetMargin(new inkMargin(70.0, rtop, 0.0, 0.0));
      ra.Reparent(panel);
      ArrayPush(this.m_rowA, ra);

      let rb = new inkText();
      rb.SetFontFamily(font);
      rb.SetFontStyle(n"Medium");
      rb.SetFontSize(21);
      rb.SetTintColor(new HDRColor(0.72, 0.80, 0.88, 1.0));
      rb.SetAnchor(inkEAnchor.TopLeft);
      rb.SetMargin(new inkMargin(350.0, rtop + 2.0, 0.0, 0.0));
      rb.Reparent(panel);
      ArrayPush(this.m_rowB, rb);

      // Narrow middle column: a scar word, or a body count. Never more than 14 characters.
      let rc = new inkText();
      rc.SetFontFamily(font);
      rc.SetFontStyle(n"Medium");
      rc.SetFontSize(21);
      rc.SetTintColor(new HDRColor(0.80, 0.55, 0.45, 1.0));
      rc.SetAnchor(inkEAnchor.TopLeft);
      rc.SetMargin(new inkMargin(600.0, rtop + 2.0, 0.0, 0.0));
      rc.Reparent(panel);
      ArrayPush(this.m_rowC, rc);

      let rd = new inkText();
      rd.SetFontFamily(font);
      rd.SetFontStyle(n"Medium");
      rd.SetFontSize(21);
      rd.SetTintColor(new HDRColor(0.55, 0.62, 0.70, 1.0));
      rd.SetAnchor(inkEAnchor.TopLeft);
      rd.SetMargin(new inkMargin(740.0, rtop + 2.0, 0.0, 0.0));
      rd.Reparent(panel);
      ArrayPush(this.m_rowD, rd);
      r += 1;
    }

    root.Reparent(win);
    this.m_root = root;
    this.m_built = true;
  }

  // ---- Widget helpers. Every one checks the handle first, so a widget that failed to
  // build can never take the Hub (or the game) down with it. ----------------------

  private func HideBars() -> Void {
    let i = 0;
    while i < ArraySize(this.m_barLabel) {
      if IsDefined(this.m_barLabel[i]) { this.m_barLabel[i].SetVisible(false); }
      if IsDefined(this.m_barValue[i]) { this.m_barValue[i].SetVisible(false); }
      if IsDefined(this.m_barTrack[i]) { this.m_barTrack[i].SetVisible(false); }
      if IsDefined(this.m_barFill[i]) { this.m_barFill[i].SetVisible(false); }
      if IsDefined(this.m_barCap[i]) { this.m_barCap[i].SetVisible(false); }
      i += 1;
    }
  }

  private func HideRows() -> Void {
    let i = 0;
    while i < ArraySize(this.m_rowA) {
      if IsDefined(this.m_rowPip[i]) { this.m_rowPip[i].SetVisible(false); }
      if IsDefined(this.m_rowA[i]) { this.m_rowA[i].SetVisible(false); }
      if IsDefined(this.m_rowB[i]) { this.m_rowB[i].SetVisible(false); }
      if IsDefined(this.m_rowC[i]) { this.m_rowC[i].SetVisible(false); }
      if IsDefined(this.m_rowD[i]) { this.m_rowD[i].SetVisible(false); }
      i += 1;
    }
  }

  private func SetBar(idx: Int32, label: String, value: String, frac: Float, col: HDRColor, caption: String) -> Void {
    if idx < 0 || idx >= ArraySize(this.m_barLabel) {
      return;
    }
    if IsDefined(this.m_barLabel[idx]) {
      this.m_barLabel[idx].SetText(label);
      this.m_barLabel[idx].SetVisible(true);
    }
    if IsDefined(this.m_barValue[idx]) {
      this.m_barValue[idx].SetText(value);
      this.m_barValue[idx].SetTintColor(col);
      this.m_barValue[idx].SetVisible(true);
    }
    if IsDefined(this.m_barTrack[idx]) {
      this.m_barTrack[idx].SetVisible(true);
    }
    if IsDefined(this.m_barFill[idx]) {
      let w = ClampF(frac, 0.0, 1.0) * CBHudBarWidth();
      if w < 2.0 {
        w = 2.0;      // always show a sliver, so an empty meter still reads as a meter
      }
      this.m_barFill[idx].SetSize(new Vector2(w, 14.0));
      this.m_barFill[idx].SetTintColor(col);
      this.m_barFill[idx].SetVisible(true);
    }
    if IsDefined(this.m_barCap[idx]) {
      this.m_barCap[idx].SetText(caption);
      this.m_barCap[idx].SetVisible(true);
    }
  }

  private func SetRow(idx: Int32, pip: HDRColor, a: String, b: String, c: String, d: String) -> Void {
    if idx < 0 || idx >= ArraySize(this.m_rowA) {
      return;
    }
    if IsDefined(this.m_rowPip[idx]) {
      this.m_rowPip[idx].SetTintColor(pip);
      this.m_rowPip[idx].SetVisible(true);
    }
    if IsDefined(this.m_rowA[idx]) {
      this.m_rowA[idx].SetText(CBHudTrim(a, CBHudColA()));
      this.m_rowA[idx].SetVisible(true);
    }
    if IsDefined(this.m_rowB[idx]) {
      this.m_rowB[idx].SetText(CBHudTrim(b, CBHudColB()));
      this.m_rowB[idx].SetVisible(true);
    }
    if IsDefined(this.m_rowC[idx]) {
      this.m_rowC[idx].SetText(CBHudTrim(c, CBHudColC()));
      this.m_rowC[idx].SetVisible(true);
    }
    if IsDefined(this.m_rowD[idx]) {
      this.m_rowD[idx].SetText(CBHudTrim(d, CBHudColD()));
      this.m_rowD[idx].SetVisible(true);
    }
  }

  // The four scores, as meters you can read at a glance instead of numbers in a sentence.
  private func RenderScores(sys: ref<CyberbaneSystem>) -> Void {
    let score = sys.GetScore();
    if !IsDefined(score) {
      return;
    }
    let renown = score.GetRenown();
    let dread = score.GetDread();
    let chrome = score.GetChromeVisible();
    let code = sys.GetCode();

    this.SetBar(0, "Renown", s"\(RoundF(renown))   \(CBTierName(EnumInt(score.GetTier())))",
      renown / 1000.0, CBHudCyan(),
      "How widely Night City knows your name.");

    this.SetBar(1, "Dread", s"\(RoundF(dread))   the street reads \(RoundF(score.GetDreadCiv()))",
      dread / 100.0, CBHudRed(),
      "How frightening you are. This is what makes people back off.");

    this.SetBar(2, "Visible chrome", s"\(RoundF(chrome))",
      chrome / 100.0, CBHudAmber(),
      "What a stranger clocks from across the street. Arms read loudest.");

    // Code runs -100..100, so the meter shows how far along that line you sit.
    this.SetBar(3, "Conduct", s"\(RoundF(code))   \(CBCodeLabel(code))",
      (code + 100.0) / 200.0, code < 0.0 ? CBHudRed() : CBHudGreen(),
      "Clean and controlled, or one bad night from going over.");
  }

  private func RenderFactions(sys: ref<CyberbaneSystem>) -> Void {
    let score = sys.GetScore();
    if !IsDefined(score) {
      return;
    }
    let states = sys.GetFactionStates();
    let shown = 0;
    let i = 0;
    while i < ArraySize(states) && shown < CBHudRowCount() {
      let fs = states[i];
      i += 1;
      if IsDefined(fs) {
        let posture = score.GetPosture(fs.id);
        let pip = CBHudGrey();
        if Equals(posture, ECBPosture.Vendetta) { pip = CBHudRed(); }
        if Equals(posture, ECBPosture.Hostile) { pip = CBHudAmber(); }
        if Equals(posture, ECBPosture.Friendly) { pip = CBHudGreen(); }

        // Most urgent thing this gang is doing. Anything actually on its way wins over a
        // count of how far off the next thing is.
        let right = "";
        if Equals(sys.GetPendingApexFaction(), fs.id) {
          right = (sys.IsPendingApexDriving() ? "APEX SQUAD DRIVING " : "APEX SQUAD IN ")
                + CBHudCountdown(sys.GetPendingApexTicks());
        } else {
          if Equals(sys.GetPendingSquadFaction(), fs.id) {
            if sys.GetPendingSquadTicks() <= 0 {
              let why = CBBlockLabel(CBLastSpawnBlock());
              right = StrLen(why) > 0 ? "HELD: " + why : "CREW HELD UP";
            } else {
              right = "CREW INBOUND " + CBHudCountdown(sys.GetPendingSquadTicks());
            }
          } else {
            if Equals(sys.GetLaneTarget(CBLaneApex()), fs.id) {
              right = "APEX SQUAD IN " + CBHudCountdown(sys.GetLaneTicks(CBLaneApex()));
            } else {
              if Equals(sys.GetLaneTarget(CBLaneSquad()), fs.id) {
                right = "CREW IN " + CBHudCountdown(sys.GetLaneTicks(CBLaneSquad()));
              } else {
                let toApex = CBConfig.ApexKillThreshold() - (fs.kills - fs.apexAtKills);
                right = toApex <= 0 ? "ready to send their best"
                                    : s"apex squad in \(toApex) kills";
              }
            }
          }
        }
        this.SetRow(shown, pip, CBFactionLabel(fs.id),
          CBPostureName(posture) + s"   fear \(RoundF(score.GetFactionFear(fs.id)))",
          s"\(fs.kills) down", right);
        shown += 1;
      }
    }
  }

  private func RenderRivals(sys: ref<CyberbaneSystem>) -> Void {
    let content = sys.GetContent();
    let rivals = sys.GetRivals();
    let shown = 0;
    let i = 0;
    while i < ArraySize(rivals) && shown < CBHudRowCount() {
      let r = rivals[i];
      i += 1;
      if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        let hunting = r.state == EnumInt(ECBRivalState.Hunting);
        let role = CBRoleShort(CBRivalRole(sys, r));
        let gang = CBFactionLabel(r.faction);
        if NotEquals(role, "") {
          gang += "  " + role;
        } else {
          gang += s"  rank \(r.rank)";
        }
        // Only one Rival is ever on the clock, so only that one shows a countdown. The rest
        // say plainly that they are waiting rather than each showing a timer for a turn they
        // are not having, which is what made several clocks appear to run at once.
        let queued = r.id == sys.GetLaneRivalId(CBLaneRival()) && sys.GetLaneTicks(CBLaneRival()) > 0;
        let rightCol = "waiting their turn";
        if hunting {
          rightCol = "here now";
        } else {
          if queued {
            rightCol = "arrives in " + CBHudCountdown(sys.GetLaneTicks(CBLaneRival()));
          } else {
            if StrLen(this.m_holdLabel) > 0 {
              rightCol = this.m_holdLabel;
            }
          }
        }
        this.SetRow(shown, hunting ? CBHudRed() : CBHudAmber(),
          IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival",
          gang,
          CBScarLabel(r.scarMask),
          rightCol);
        shown += 1;
      }
    }
  }

  private func RenderChips() -> Void {
    let i = 0;
    while i < ArraySize(this.m_chipBg) {
      let on = (i + 1) == this.m_tab;
      if IsDefined(this.m_chipBg[i]) {
        this.m_chipBg[i].SetTintColor(on ? new HDRColor(0.10, 1.60, 1.90, 0.85)
                                         : new HDRColor(0.10, 0.14, 0.18, 0.85));
      }
      if IsDefined(this.m_chipText[i]) {
        this.m_chipText[i].SetText(CBHudTabName(i + 1));
        this.m_chipText[i].SetTintColor(on ? new HDRColor(0.02, 0.05, 0.07, 1.0)
                                           : new HDRColor(0.60, 0.70, 0.78, 1.0));
      }
      i += 1;
    }
  }

  private func Render(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if !IsDefined(this.m_root) {
      return;
    }
    if this.m_tab == 0 {
      this.m_root.SetVisible(false);
      return;
    }
    // Refresh the live inputs so the Hub always shows current values (the Street Cred floor on
    // Renown, chrome, look, menace), even right after a fast travel when the background tick is
    // still in its settle window. Gated by CBWorldStable so it only reads player/world state when
    // the world is ready - never during a transition, so it cannot reintroduce the crash.
    if CBWorldStable(game) {
      CBRefreshLiveInputs(sys, game);
      CBUpdateChrome(sys, game);
      CBUpdateLook(sys, game);
      CBUpdateMenace(sys, game);
    }
    let score = sys.GetScore();
    let titleName = CBHudActiveTitle(sys);
    let tier = IsDefined(score) ? CBTierName(EnumInt(score.GetTier())) : "Nobody";
    this.m_subhead.SetText(titleName + "   |   " + tier);

    this.RenderChips();
    this.HideBars();
    this.HideRows();

    // Each screen decides what it is: meters, a list, or prose. The body text sits under
    // whatever the screen drew, rather than being the whole screen.
    let bodyTop = 212.0;
    if this.m_tab == 1 {
      this.RenderScores(sys);
      bodyTop = 566.0;
    } else {
      if this.m_tab == CBHudFactionsTab() {
        this.RenderFactions(sys);
        bodyTop = 608.0;
      } else {
        if this.m_tab == CBHudRivalsTab() {
          this.m_holdLabel = CBHoldLabel(sys.GetHuntHoldReason());
          // If an arrival was actually attempted and refused, that is more specific than the
          // hold reason and more useful to say.
          let blocked = CBBlockLabel(CBLastSpawnBlock());
          if StrLen(blocked) > 0 && sys.GetHuntHoldReason() == CBHoldNoRoom() {
            this.m_holdLabel = blocked;
          }
          this.RenderRivals(sys);
          bodyTop = 608.0;
        }
      }
    }
    if IsDefined(this.m_body) {
      this.m_body.SetMargin(new inkMargin(50.0, bodyTop, 0.0, 0.0));
      this.m_body.SetText(CBHudClamp(CBHudBody(sys, game, this.m_tab), CBHudMaxLinesFor(this.m_tab)));
    }
    this.m_root.SetVisible(true);
  }
}

// ---- Tab content -----------------------------------------------------------

func CBHudActiveTitle(sys: ref<CyberbaneSystem>) -> String {
  let id = sys.GetActiveTitle();
  if Equals(id, n"") {
    let unlocked = sys.GetUnlockedTitles();
    if ArraySize(unlocked) > 0 {
      id = unlocked[ArraySize(unlocked) - 1];
    }
  }
  if Equals(id, n"") {
    return "Unknown";
  }
  // Names the district or gang the title is actually about (Model/TitleNaming.reds).
  return CBTitleDisplayById(sys, sys.GetContent(), id);
}

// inkText does not clip to its box: hand it more lines than fit and they render straight
// over the footer and off the bottom of the panel, which is exactly what a longer Legend tab
// did. Every tab body goes through here so that can never happen again, whatever is added to
// a tab later. Truncation is the failure mode, not overlap.
func CBHudClamp(text: String, maxLines: Int32) -> String {
  let lines = StrSplit(text, "\n");
  if ArraySize(lines) <= maxLines {
    return text;
  }
  let out = "";
  let i = 0;
  while i < maxLines - 1 {
    out += lines[i] + "\n";
    i += 1;
  }
  out += "    ...";
  return out;
}

func CBHudBody(sys: ref<CyberbaneSystem>, game: GameInstance, tab: Int32) -> String {
  switch tab {
    case 1: return CBHudLegend(sys, game);
    case 2: return CBHudFactions(sys);
    case 3: return CBHudDistricts(sys);
    case 4: return CBHudRivals(sys, game);
    case 5: return CBHudTitles(sys);
    case 6: return CBHudLog(sys);
    default: return "";
  }
}

// What is on its way, in one place.
//
// Three lanes, three clocks, always shown together even when a lane is empty. Showing an idle
// lane as "nobody" is the point: silence used to be ambiguous - it could mean nothing was
// coming, or that something was coming and the clock had stalled, and those two looked
// identical. A line that says nobody is after you right now is information. A line that says
// held, and why, is information. A blank screen is not.
func CBHudIncoming(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let out = "INCOMING\n";
  out += "  " + CBHudLaneLine(sys, game, CBLaneRival(), "Rival") + "\n";
  out += "  " + CBHudLaneLine(sys, game, CBLaneSquad(), "Crew ") + "\n";
  out += "  " + CBHudLaneLine(sys, game, CBLaneApex(), "Apex ") + "\n";
  return out;
}

func CBHudLaneLine(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32, label: String) -> String {
  let who = "";
  if lane == CBLaneRival() {
    let r = sys.FindRivalById(sys.GetLaneRivalId(lane));
    who = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "";
  } else {
    let f = sys.GetLaneTarget(lane);
    who = NotEquals(f, n"") ? CBFactionLabel(f) : "";
  }

  // Already here. Their lane is held until that encounter is over, which is the honest thing
  // to say rather than counting down to a turn that cannot start.
  if CBLaneBusy(sys, game, lane) {
    return label + "   here now";
  }
  if StrLen(who) == 0 {
    return label + "   nobody";
  }
  let ticks = sys.GetLaneTicks(lane);
  if ticks <= 0 {
    let why = CBBlockLabel(CBLastSpawnBlock());
    return StrLen(why) > 0 ? label + "   " + who + "  held: " + why
                           : label + "   " + who + "  any moment";
  }
  return label + "   " + who + "  " + CBHudCountdown(ticks);
}

func CBHudLegend(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  // The four scores are meters now, so this screen's text only carries what a meter cannot:
  // where you are, what the city has already sent, and what it is doing about you right now.
  let style = CBArchetypeName(sys.GetPrimaryArchetypeIndex());
  let districtId = CBEventDistrict(sys, game);
  let district = CBDistrictLabel(districtId);
  if Equals(district, "") {
    district = NameToString(districtId);
  }
  let cred = RoundF(CBPlayerStreetCred(game));

  let out = s"STREET CRED \(cred)      STYLE \(style)      HERE \(district)\n\n";
  let stats = sys.GetStats();
  if IsDefined(stats) {
    // Two explanatory lines came out of here when the INCOMING block went in. The screen
    // clamps at eleven lines and the block is five of them, so something had to give, and a
    // live readout of what is actually on its way is worth more than a reminder of how apex
    // squads are earned - which the Factions screen already counts down for you anyway.
    out += s"APEX SQUAD KILLS \(stats.apexKills)      RIVALS PUT DOWN \(stats.rivalsSlain)      UNSEEN \(stats.unattributed)\n\n";
  }
  out += CBHudIncoming(sys, game) + "\n";
  out += CBHudDreadReason(sys) + "\n";
  out += CBHudReactionState(sys);
  return out;
}
// A live readout of what the city is actually doing about you right now, and what it would
// take to move the needle. This is the line that answers "is any of this working?".
func CBHudReactionState(sys: ref<CyberbaneSystem>) -> String {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return "";
  }
  // Say why nothing is happening, rather than reporting a threshold the player is already
  // past while the whole system is standing down for a reason they cannot see. Every one of
  // these gates silently disables crowd reactions, and all of them looked identical from the
  // outside: a city that ignores you.
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return "Right now: Cyberbane is switched off in Mod Settings, so nothing reacts.";
  }
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().civReactions {
    return "Right now: crowd reactions are switched off in Mod Settings.";
  }
  if sys.IsInSafeZone() {
    return "Right now: the game calls this a safe area, so nobody here reacts. Step outside.";
  }
  let reg = sys.GetRegistry();
  if !IsDefined(reg) || reg.Count() == 0 {
    return "Right now: Cyberbane is not tracking anybody nearby, so nobody can react yet.";
  }
  let chromeVisible = score.GetChromeVisible();
  let eff = MaxF(score.GetDreadCiv(), chromeVisible) + score.GetMenace() * CBConfig.MenaceFearWeight();
  let reach = 1.0 + (chromeVisible / 100.0) * CBConfig.ChromeNoticeRangeBonus();
  if eff >= CBConfig.CivTierTerror() {
    let r = RoundF(CBConfig.CivFleeRadius() * reach);
    return s"Right now: people break and run when you come within \(r) metres. (\(reg.Count()) tracked)";
  }
  if eff >= CBConfig.CivTierAfraid() {
    let r = RoundF(CBConfig.CivCowerRadius() * reach);
    return s"Right now: people flinch and give way within \(r) metres. (\(reg.Count()) tracked)";
  }
  let need = RoundF(CBConfig.CivTierAfraid() - eff);
  return s"Right now: nobody backs off yet, about \(need) short. (\(reg.Count()) tracked)";
}

// Plain-language line: what is driving V's Dread the most (spec §12.1).
func CBHudDreadReason(sys: ref<CyberbaneSystem>) -> String {
  let score = sys.GetScore();
  // Weighted by what each one actually contributes to Dread, not the raw score. Comparing
  // the raw numbers meant chrome (capped at 100, weighted 0.20) beat a body count (weighted
  // 0.35) whenever its number was bigger, so the Hub kept telling players they were feared
  // for their chrome after hundreds of kills. Dread is
  // 0.35K + 0.20C + 0.15L + 0.20X + 0.10H, so the comparison has to use the same weights.
  let k = CBKillDreadComponent(sys.GetKillDreadPoints()) * CBConfig.DreadWeightK();
  let x = CBDeedDreadComponent(sys.GetDeedDreadPoints()) * CBConfig.DreadWeightX();
  let h = CBHeatDreadComponent(sys.GetHeatPoints()) * CBConfig.DreadWeightH();
  let c = score.GetChrome() * CBConfig.DreadWeightC();
  let l = score.GetLook() * CBConfig.DreadWeightL();

  let bestLabel = "nothing in particular yet";
  let best = 0.0;
  if k > best { best = k; bestLabel = "your body count"; }
  if c > best { best = c; bestLabel = "all that chrome"; }
  if l > best { best = l; bestLabel = "the way you carry yourself"; }
  if x > best { best = x; bestLabel = "the jobs you have pulled"; }
  if h > best { best = h; bestLabel = "the heat you draw from the law"; }

  if best <= 0.0 {
    return "People barely know you. Make some noise.";
  }
  return "People fear you mostly for " + bestLabel + ".";
}

func CBHudFactions(sys: ref<CyberbaneSystem>) -> String {
  let states = sys.GetFactionStates();
  if ArraySize(states) == 0 {
    return "No gang has formed an opinion of you yet.\n\nWork in their territory and that changes quickly.";
  }
  let out = "Standing is whether they like you. Fear is how badly they want to avoid you.\n";
  out += "The last column counts their dead and how close they are to sending an apex squad.\n\n";
  out += "Wary means they keep an eye on you. Hostile means they draw on sight.\n";
  out += "Vendetta means they hunt you and put a price on your head.\n\n";
  out += "[ Shift + Hub key ]  buy off the worst gang you can afford.";
  return out;
}
func CBHudDistricts(sys: ref<CyberbaneSystem>) -> String {
  let states = sys.GetDistrictStates();
  if ArraySize(states) == 0 {
    return "Your name has not travelled to any district yet.";
  }
  let out = "Where your name has travelled. Word spreads outward from where things happened,\n";
  out += "so you can be a legend in one district and a nobody in the next.\n\n";
  let shown = 0;
  let i = 0;
  while i < ArraySize(states) && shown < 14 {
    let d = states[i];
    i += 1;
    if IsDefined(d) {
      let rd = RoundF(d.renown);
      out += CBHudPad(NameToString(d.id), 18) + s"renown \(rd)   kills \(d.kills)\n";
      shown += 1;
    }
  }
  return out;
}

// Why this Rival has it in for you, in plain words.
func CBRivalSourceLine(source: Int32) -> String {
  if source == EnumInt(ECBRivalSource.Survivor) {
    return "got away from you bleeding";
  }
  if source == EnumInt(ECBRivalSource.Spared) {
    return "you beat them down and left them alive";
  }
  if source == EnumInt(ECBRivalSource.Killer) {
    return "put you down once";
  }
  if source == EnumInt(ECBRivalSource.Avenger) {
    return "avenging someone you killed";
  }
  if source == EnumInt(ECBRivalSource.Hunter) {
    return "lost you after coming for your head";
  }
  return "remembers you";
}

func CBHudRivals(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let rivals = sys.GetRivals();
  let any = false;
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      any = true;
    }
  }
  if !any {
    return "No active rivals yet.\n\nLeave someone alive after you put them down, or let a wounded\nenemy get away, and one of them will come back with your name.";
  }
  let count = sys.CountActiveRivals();
  let cap = CBRivalCap();
  let out = s"CARRYING \(count) OF \(cap)\n\n";
  // Why the one who is next is after you.
  //
  // The rows carry name, gang, rank, scars and a clock, and never once say what any of this is
  // about. CBRivalSourceLine has existed as long as rivals have and was never called, so the
  // single most interesting fact about a nemesis - that you spared them, or that they put you
  // down once - was being kept from the player. Shown for whoever is next rather than on every
  // row, because it is a sentence and the rows are columns.
  let nextId = sys.GetLaneRivalId(CBLaneRival());
  if nextId > 0 {
    let nxt = sys.FindRivalById(nextId);
    if IsDefined(nxt) {
      let why = CBRivalSourceLine(nxt.source);
      if StrLen(why) > 0 {
        out += "NEXT  " + CBRivalDisplayName(sys.GetContent(), nxt) + " - " + why
             + ", " + CBRivalStateName(nxt.state) + ".\n\n";
      }
    }
  }
  // A held arrival used to keep resetting its clock to a few seconds and never come, which
  // read as the Hub promising someone was seconds away over and over. Say what is happening.
  let held = CBStealthHoldReason(sys, game);
  if NotEquals(held, "") {
    out += held + "\n\n";
  }
  out += "The clock is how long until they catch up with you. They arrive when it runs\n";
  out += "out, wherever you are, and come back a rank higher every time one escapes.\n\n";
  if count >= cap {
    out += "Nobody new can take against you until you clear some, so the ones you\n";
    out += "already have come at you faster until you do.\n\n";
  }
  out += "[ Shift + Hub key ]  forget every rival (use after updating the mod).";
  return out;
}
func CBHudTitles(sys: ref<CyberbaneSystem>) -> String {
  let unlocked = sys.GetUnlockedTitles();
  let content = sys.GetContent();
  let active = sys.GetActiveTitle();
  let out = "";

  if ArraySize(unlocked) == 0 {
    out += "EARNED: nothing yet.\n";
  } else {
    out += "EARNED:\n";
    let i = 0;
    while i < ArraySize(unlocked) && i < CBConfig.HudTitlesEarnedShown() {
      let id = unlocked[i];
      // Names the district or gang the title is actually about (Model/TitleNaming.reds).
      let name = CBTitleDisplayById(sys, content, id);
      let mark = Equals(id, active) ? "   <- you are going by this" : "";
      out += "  " + name + mark + "\n";
      i += 1;
    }
  }

  // And the ones you have not got, with what each of them takes.
  //
  // A player reported that the titles were the least understandable part of the mod: they
  // arrive unannounced, and nothing anywhere says what they mean or how to go after one. A
  // list of names you already have cannot fix that. A list of the ones you do not, each with
  // the thing you would have to do, turns the whole system into something you can aim at.
  if IsDefined(content) {
    let shown = 0;
    out += "\nNOT YET:\n";
    for def in content.GetTitles() {
      if IsDefined(def) && !sys.HasTitle(def.id) && shown < CBConfig.HudTitlesLockedShown() {
        let need = CBTitleRequirement(sys, def.id);
        if StrLen(need) > 0 {
          out += "  " + CBTitleDisplayById(sys, content, def.id) + "\n      " + need + "\n";
          shown += 1;
        }
      }
    }
    if shown == 0 {
      out += "  Nothing left. You have all of them.\n";
    }
  }

  if Equals(active, n"") {
    out += "\nGoing by: whichever is the best one you have earned.";
  }
  out += "\n[ Ctrl + Hub key ]  change which title you go by.";
  return out;
}

func CBHudLog(sys: ref<CyberbaneSystem>) -> String {
  let log = sys.GetLog();
  let n = ArraySize(log);
  if n == 0 {
    return "STREET FILE // SUBJECT: V\n\nNothing on file. Nobody has anything on you yet.";
  }
  let out = "STREET FILE // SUBJECT: V\n";
  out += "Put together from what people saw and passed on. Most recent first.\n";
  out += "Work nobody witnessed never reaches this page.\n\n";
  let shown = 0;
  let i = n - 1;
  while i >= 0 && shown < 14 {
    let e = log[i];
    i -= 1;
    if IsDefined(e) {
      let where = Equals(e.district, n"") ? "" : ("  (" + NameToString(e.district) + ")");
      out += NameToString(e.kind) + where + "\n";
      shown += 1;
    }
  }
  return out;
}

// Cycle the active title: Auto -> each unlocked title -> Auto (spec §12.1 Titles tab).
public func CBCycleActiveTitle(sys: ref<CyberbaneSystem>) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let unlocked = sys.GetUnlockedTitles();
  if ArraySize(unlocked) == 0 {
    return;
  }
  let cur = sys.GetActiveTitle();
  if Equals(cur, n"") {
    sys.SetActiveTitle(unlocked[0]);   // Auto -> first earned title
    return;
  }
  let idx = -1;
  let i = 0;
  while i < ArraySize(unlocked) {
    if Equals(unlocked[i], cur) {
      idx = i;
    }
    i += 1;
  }
  let next = idx + 1;
  if next >= ArraySize(unlocked) {
    sys.SetActiveTitle(n"");            // wrap back to Auto
  } else {
    sys.SetActiveTitle(unlocked[next]);
  }
}

// ---- Small label helpers ---------------------------------------------------

func CBArchetypeName(idx: Int32) -> String {
  switch idx {
    case 0: return "Butcher";
    case 1: return "Ghost";
    case 2: return "Professional";
    case 3: return "Chromed";
    case 4: return "Netrunner";
    case 5: return "Brawler";
    default: return "Undefined";
  }
}

func CBCodeLabel(code: Float) -> String {
  if code >= 40.0 {
    return "Professional";
  }
  if code <= -40.0 {
    return "Cyberpsycho";
  }
  return "Mixed";
}

func CBPostureName(posture: ECBPosture) -> String {
  switch posture {
    case ECBPosture.Allied: return "Allied";
    case ECBPosture.Friendly: return "Friendly";
    case ECBPosture.Neutral: return "Neutral";
    case ECBPosture.Hostile: return "Hostile";
    case ECBPosture.Vendetta: return "Vendetta";
    default: return "Neutral";
  }
}

func CBRivalStateName(state: Int32) -> String {
  if state == EnumInt(ECBRivalState.Hunting) {
    return "hunting you";
  }
  if state == EnumInt(ECBRivalState.Active) {
    return "at large";
  }
  return "quiet";
}

// Pad a label with spaces to a column width for the fixed-width readout.
func CBHudPad(s: String, width: Int32) -> String {
  let out = s;
  let i = StrLen(s);
  while i < width {
    out += " ";
    i += 1;
  }
  return out;
}
