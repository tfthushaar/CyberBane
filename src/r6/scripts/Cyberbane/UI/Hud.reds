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
public func CBHudMaxLines() -> Int32 = 22

// Lines that fit below each screen's own content, before the footer at y=854. The meters
// end at 566 and the lists at 608, so those screens have far less room for prose than the
// plain ones that start at 212. Text is clamped to this, so nothing can run into the footer.
// Every screen draws its own content first and the prose goes underneath, so what fits is
// whatever is left between that content and the footer. These are measured against the
// positions in Build and the 26 px line height of the body font; leaving a line of slack is
// deliberate, since text running into the footer is the one failure a player actually sees.
public func CBHudMaxLinesFor(tab: Int32) -> Int32 {
  if tab == 1 {
    return 11;   // under four meters
  }
  if tab == CBHudFactionsTab() || tab == CBHudRivalsTab() {
    return 9;    // under ten list rows
  }
  return CBHudMaxLines();
}

// Which tab the Rivals screen is, so the key handler does not hardcode a number.
public func CBHudRivalsTab() -> Int32 = 4
public func CBHudFactionsTab() -> Int32 = 2

// Layout.
//
// Full screen, laid out against a fixed 1860x1020 design that is centred on whatever the
// screen actually is. Fixed rather than stretched because every row below is positioned by
// hand, and a design that is centred reads correctly at any resolution while one that is
// stretched does not.
//
// The shape is the game's own settings menu: a centred row of tabs across the top, a line of
// description under them, a rule, then the content, with the key hints along the bottom. That
// screen is the one players already know how to read, so the Hub borrows its proportions as
// well as its colours.
public func CBHudPanelW() -> Float = 1860.0
public func CBHudPanelH() -> Float = 1020.0
public func CBHudMarginX() -> Float = 160.0
public func CBHudContentW() -> Float = 1540.0
public func CBHudChipWidth() -> Float = 250.0
public func CBHudBarCount() -> Int32 = 4
public func CBHudBarWidth() -> Float = 1540.0
public func CBHudRowCount() -> Int32 = 10
public func CBHudRowHeight() -> Float = 44.0
public func CBHudContentTop() -> Float = 200.0
public func CBHudFooterY() -> Float = 952.0

// Colours.
//
// The first five are the settings menu's: salmon labels, white values, a brighter white for
// anything selected, and a dim red rule. The last five are Cyberbane's own and are used for
// meters and status pips, where a reputation screen needs to say good, bad or dangerous and
// the settings menu has nothing to borrow.
// Nothing here goes above 1.0, and that is the whole point.
//
// HDRColor is high dynamic range: a channel above 1.0 is brighter than white and the game
// blooms it. The first version of this palette ran up to 2.25, so every label, every meter and
// every rule was emitting light, the thin ones worst of all. On a dark background that reads as
// a screen smeared in glow rather than a menu. The game's own settings screen is flat colour,
// so these are flat too.
public func CBHudLabel() -> HDRColor = new HDRColor(0.85, 0.28, 0.30, 1.0)
public func CBHudValue() -> HDRColor = new HDRColor(0.92, 0.93, 0.95, 1.0)
public func CBHudHead() -> HDRColor = new HDRColor(1.00, 1.00, 1.00, 1.0)
public func CBHudRule() -> HDRColor = new HDRColor(0.62, 0.18, 0.20, 0.70)
public func CBHudDim() -> HDRColor = new HDRColor(0.62, 0.40, 0.41, 0.95)
public func CBHudCyan() -> HDRColor = new HDRColor(0.16, 0.78, 0.88, 1.0)
public func CBHudAmber() -> HDRColor = new HDRColor(0.88, 0.64, 0.16, 1.0)
public func CBHudRed() -> HDRColor = new HDRColor(0.88, 0.26, 0.29, 1.0)
public func CBHudGreen() -> HDRColor = new HDRColor(0.26, 0.78, 0.50, 1.0)
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
// Characters each column can show. Raised across the board when the Hub went full screen:
// the columns are roughly half as wide again, so a Rival's full name now fits where it used
// to be cut.
public func CBHudColA() -> Int32 = 40
public func CBHudColB() -> Int32 = 34
public func CBHudColC() -> Int32 = 16
public func CBHudColD() -> Int32 = 26

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
  // One strip behind each row. The settings menu banding is what makes a long list scannable;
  // without it the eye has to track across 1540 px of empty space to pair a name with a value.
  private let m_rowBg: array<ref<inkRectangle>>;
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
    // The menu layer first, because the HUD layer is curved.
    //
    // Everything drawn on inkHUDLayer goes through the gameplay HUD's barrel distortion, which
    // is why a full-width rule bows in the middle. It is right for a visor overlay and wrong
    // for a page of text. inkMenuLayer is where the game's own settings screen lives and it is
    // flat. If it cannot be reached we fall back to the HUD layer, which is exactly what the
    // Hub did before, so the worst case is the old look rather than no Hub.
    let layer = ink.GetLayer(n"inkMenuLayer");
    let win: wref<inkCompoundWidget>;
    if IsDefined(layer) {
      win = layer.GetVirtualWindow();
    }
    if !IsDefined(win) {
      layer = ink.GetLayer(n"inkHUDLayer");
      if !IsDefined(layer) {
        return false;
      }
      win = layer.GetVirtualWindow();
      if !IsDefined(win) {
        return false;
      }
      CBLog.Info(n"UI", "Hub on inkHUDLayer: the menu layer was unavailable, so it will look curved.");
    } else {
      CBLog.Info(n"UI", "Hub built on inkMenuLayer (flat).");
    }
    this.Build(win);
    return this.m_built;
  }

  private func Build(win: wref<inkCompoundWidget>) -> Void {
    let font = "base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily";
    let x = CBHudMarginX();
    let w = CBHudContentW();

    let root = new inkCanvas();
    root.SetName(n"cyberbaneHub");
    root.SetAnchor(inkEAnchor.Fill);
    root.SetVisible(false);

    // The settings menu dims the world almost to black with a red cast rather than greying it.
    let backdrop = new inkRectangle();
    backdrop.SetAnchor(inkEAnchor.Fill);
    backdrop.SetTintColor(new HDRColor(0.055, 0.012, 0.022, 0.97));
    backdrop.Reparent(root);

    let panel = new inkCanvas();
    panel.SetAnchor(inkEAnchor.Centered);
    panel.SetAnchorPoint(new Vector2(0.5, 0.5));
    panel.SetSize(new Vector2(CBHudPanelW(), CBHudPanelH()));
    panel.Reparent(root);

    // ---- Title block, top left, the way the menus mark themselves -------
    let header = new inkText();
    header.SetFontFamily(font);
    header.SetFontStyle(n"Semibold");
    header.SetFontSize(28);
    header.SetLetterCase(textLetterCase.UpperCase);
    header.SetText("CYBERBANE");
    header.SetTintColor(CBHudLabel());
    header.SetAnchor(inkEAnchor.TopLeft);
    // Its own line. The tab row is centred across the panel and the first tab started at
    // x=180 against a title at x=160, so LEGEND was printed over CYBERBANE.
    header.SetMargin(new inkMargin(x, 14.0, 0.0, 0.0));
    header.Reparent(panel);

    // ---- Tabs, centred across the top ------------------------------------
    let tabsW = Cast<Float>(CBHudTabCount()) * CBHudChipWidth();
    let tabsX = (CBHudPanelW() - tabsW) / 2.0;
    let t = 0;
    while t < CBHudTabCount() {
      let cx = tabsX + Cast<Float>(t) * CBHudChipWidth();

      let label = new inkText();
      label.SetFontFamily(font);
      label.SetFontStyle(n"Semibold");
      label.SetFontSize(24);
      label.SetLetterCase(textLetterCase.UpperCase);
      label.SetAnchor(inkEAnchor.TopLeft);
      label.SetHorizontalAlignment(textHorizontalAlignment.Center);
      label.SetFitToContent(false);
      label.SetSize(new Vector2(CBHudChipWidth(), 32.0));
      label.SetMargin(new inkMargin(cx, 58.0, 0.0, 0.0));
      label.Reparent(panel);
      ArrayPush(this.m_chipText, label);

      // The open tab is marked by a bar under it, which is what the game does. A filled
      // chip was the old look and it reads as a button you are meant to click.
      let under = new inkRectangle();
      under.SetAnchor(inkEAnchor.TopLeft);
      under.SetSize(new Vector2(CBHudChipWidth() - 40.0, 3.0));
      under.SetMargin(new inkMargin(cx + 20.0, 96.0, 0.0, 0.0));
      under.Reparent(panel);
      ArrayPush(this.m_chipBg, under);
      t += 1;
    }

    // ---- The line under the tabs that says what you are looking at -------
    let subhead = new inkText();
    subhead.SetFontFamily(font);
    subhead.SetFontStyle(n"Medium");
    subhead.SetFontSize(24);
    subhead.SetTintColor(CBHudDim());
    subhead.SetAnchor(inkEAnchor.TopLeft);
    subhead.SetHorizontalAlignment(textHorizontalAlignment.Center);
    subhead.SetFitToContent(false);
    subhead.SetSize(new Vector2(CBHudPanelW(), 32.0));
    subhead.SetMargin(new inkMargin(0.0, 122.0, 0.0, 0.0));
    subhead.Reparent(panel);
    this.m_subhead = subhead;

    // Kept so nothing that still references it breaks; the tabs above replaced it.
    let tabline = new inkText();
    tabline.SetFontFamily(font);
    tabline.SetVisible(false);
    tabline.Reparent(panel);
    this.m_tabline = tabline;

    let divider = new inkRectangle();
    divider.SetAnchor(inkEAnchor.TopLeft);
    divider.SetSize(new Vector2(w, 2.0));
    divider.SetTintColor(CBHudRule());
    divider.SetMargin(new inkMargin(x, 164.0, 0.0, 0.0));
    divider.Reparent(panel);

    let body = new inkText();
    body.SetFontFamily(font);
    body.SetFontStyle(n"Medium");
    body.SetFontSize(21);
    body.SetTintColor(CBHudValue());
    body.SetAnchor(inkEAnchor.TopLeft);
    body.SetMargin(new inkMargin(x, CBHudContentTop(), 0.0, 0.0));
    body.SetWrapping(true, w);
    body.SetSize(new Vector2(w, 740.0));
    body.Reparent(panel);
    this.m_body = body;

    let footRule = new inkRectangle();
    footRule.SetAnchor(inkEAnchor.TopLeft);
    footRule.SetSize(new Vector2(w, 2.0));
    footRule.SetTintColor(CBHudRule());
    footRule.SetMargin(new inkMargin(x, CBHudFooterY() - 18.0, 0.0, 0.0));
    footRule.Reparent(panel);

    let footer = new inkText();
    footer.SetFontFamily(font);
    footer.SetFontStyle(n"Medium");
    footer.SetFontSize(19);
    footer.SetTintColor(CBHudDim());
    footer.SetAnchor(inkEAnchor.TopLeft);
    footer.SetMargin(new inkMargin(x, CBHudFooterY(), 0.0, 0.0));
    footer.SetText("HUB KEY  next tab, and closes on the last    SHIFT+HUB  broker peace    CTRL+HUB  switch title");
    footer.Reparent(panel);

    let footerRight = new inkText();
    footerRight.SetFontFamily(font);
    footerRight.SetFontStyle(n"Medium");
    footerRight.SetFontSize(19);
    footerRight.SetTintColor(CBHudDim());
    footerRight.SetAnchor(inkEAnchor.TopLeft);
    footerRight.SetHorizontalAlignment(textHorizontalAlignment.Right);
    footerRight.SetFitToContent(false);
    footerRight.SetSize(new Vector2(w, 26.0));
    footerRight.SetMargin(new inkMargin(x, CBHudFooterY(), 0.0, 0.0));
    footerRight.SetText("SETTINGS  Pause > Mods > Cyberbane");
    footerRight.Reparent(panel);

    // ---- Score meters ---------------------------------------------------
    let b = 0;
    while b < CBHudBarCount() {
      let top = CBHudContentTop() + Cast<Float>(b) * 96.0;

      let bl = new inkText();
      bl.SetFontFamily(font);
      bl.SetFontStyle(n"Semibold");
      bl.SetFontSize(25);
      bl.SetLetterCase(textLetterCase.UpperCase);
      bl.SetTintColor(CBHudLabel());
      bl.SetAnchor(inkEAnchor.TopLeft);
      bl.SetMargin(new inkMargin(x, top, 0.0, 0.0));
      bl.Reparent(panel);
      ArrayPush(this.m_barLabel, bl);

      // Right-aligned against the same edge the meter ends on, so every value on the screen
      // lines up in one column the way a settings page does.
      let bv = new inkText();
      bv.SetFontFamily(font);
      bv.SetFontStyle(n"Semibold");
      bv.SetFontSize(25);
      bv.SetAnchor(inkEAnchor.TopLeft);
      bv.SetHorizontalAlignment(textHorizontalAlignment.Right);
      bv.SetFitToContent(false);
      bv.SetSize(new Vector2(w, 30.0));
      bv.SetMargin(new inkMargin(x, top, 0.0, 0.0));
      bv.Reparent(panel);
      ArrayPush(this.m_barValue, bv);

      let track = new inkRectangle();
      track.SetAnchor(inkEAnchor.TopLeft);
      track.SetSize(new Vector2(CBHudBarWidth(), 10.0));
      track.SetTintColor(new HDRColor(0.26, 0.08, 0.10, 0.9));
      track.SetMargin(new inkMargin(x, top + 36.0, 0.0, 0.0));
      track.Reparent(panel);
      ArrayPush(this.m_barTrack, track);

      let fill = new inkRectangle();
      fill.SetAnchor(inkEAnchor.TopLeft);
      fill.SetSize(new Vector2(1.0, 10.0));
      fill.SetMargin(new inkMargin(x, top + 36.0, 0.0, 0.0));
      fill.Reparent(panel);
      ArrayPush(this.m_barFill, fill);

      let cap = new inkText();
      cap.SetFontFamily(font);
      cap.SetFontStyle(n"Medium");
      cap.SetFontSize(19);
      cap.SetTintColor(CBHudDim());
      cap.SetAnchor(inkEAnchor.TopLeft);
      cap.SetMargin(new inkMargin(x, top + 54.0, 0.0, 0.0));
      cap.SetWrapping(true, w);
      cap.Reparent(panel);
      ArrayPush(this.m_barCap, cap);
      b += 1;
    }

    // ---- List rows ------------------------------------------------------
    let r = 0;
    while r < CBHudRowCount() {
      let rtop = CBHudContentTop() + Cast<Float>(r) * CBHudRowHeight();

      let bg = new inkRectangle();
      bg.SetAnchor(inkEAnchor.TopLeft);
      bg.SetSize(new Vector2(w, CBHudRowHeight() - 4.0));
      bg.SetTintColor(r % 2 == 0 ? new HDRColor(0.14, 0.05, 0.06, 0.50)
                                 : new HDRColor(0.08, 0.03, 0.04, 0.30));
      bg.SetMargin(new inkMargin(x, rtop - 4.0, 0.0, 0.0));
      bg.Reparent(panel);
      ArrayPush(this.m_rowBg, bg);

      let pip = new inkRectangle();
      pip.SetAnchor(inkEAnchor.TopLeft);
      pip.SetSize(new Vector2(5.0, 26.0));
      pip.SetMargin(new inkMargin(x, rtop, 0.0, 0.0));
      pip.Reparent(panel);
      ArrayPush(this.m_rowPip, pip);

      let ra = new inkText();
      ra.SetFontFamily(font);
      ra.SetFontStyle(n"Semibold");
      ra.SetFontSize(23);
      ra.SetAnchor(inkEAnchor.TopLeft);
      ra.SetMargin(new inkMargin(x + 24.0, rtop, 0.0, 0.0));
      ra.Reparent(panel);
      ArrayPush(this.m_rowA, ra);

      let rb = new inkText();
      rb.SetFontFamily(font);
      rb.SetFontStyle(n"Medium");
      rb.SetFontSize(22);
      rb.SetTintColor(CBHudValue());
      rb.SetAnchor(inkEAnchor.TopLeft);
      rb.SetMargin(new inkMargin(x + 540.0, rtop + 2.0, 0.0, 0.0));
      rb.Reparent(panel);
      ArrayPush(this.m_rowB, rb);

      // Narrow middle column: a scar word, or a body count.
      let rc = new inkText();
      rc.SetFontFamily(font);
      rc.SetFontStyle(n"Medium");
      rc.SetFontSize(22);
      rc.SetTintColor(new HDRColor(0.80, 0.52, 0.34, 1.0));
      rc.SetAnchor(inkEAnchor.TopLeft);
      rc.SetMargin(new inkMargin(x + 960.0, rtop + 2.0, 0.0, 0.0));
      rc.Reparent(panel);
      ArrayPush(this.m_rowC, rc);

      // Right-aligned, same edge as the meter values.
      let rd = new inkText();
      rd.SetFontFamily(font);
      rd.SetFontStyle(n"Medium");
      rd.SetFontSize(22);
      rd.SetTintColor(CBHudDim());
      rd.SetAnchor(inkEAnchor.TopLeft);
      rd.SetHorizontalAlignment(textHorizontalAlignment.Right);
      rd.SetFitToContent(false);
      rd.SetSize(new Vector2(w, 26.0));
      rd.SetMargin(new inkMargin(x, rtop + 2.0, 0.0, 0.0));
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
      if IsDefined(this.m_rowBg[i]) { this.m_rowBg[i].SetVisible(false); }
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
      this.m_barFill[idx].SetSize(new Vector2(w, 10.0));
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
    if IsDefined(this.m_rowBg[idx]) {
      this.m_rowBg[idx].SetVisible(true);
    }
    if IsDefined(this.m_rowPip[idx]) {
      this.m_rowPip[idx].SetTintColor(pip);
      this.m_rowPip[idx].SetVisible(true);
    }
    if IsDefined(this.m_rowA[idx]) {
      this.m_rowA[idx].SetText(CBHudTrim(a, CBHudColA()));
      this.m_rowA[idx].SetTintColor(CBHudHead());
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
        // How long this has been going on. Both of these were recorded and read by nothing.
        let now = CBGameSeconds(sys.GetGameInstance());
        let age = "";
        if Equals(posture, ECBPosture.Vendetta) {
          let sworn = CBHudSince(now, fs.vendettaSince);
          age = StrLen(sworn) > 0 ? "   sworn " + sworn : "";
        } else {
          let quiet = CBHudSince(now, fs.lastIncidentAt);
          age = StrLen(quiet) > 0 ? "   quiet " + quiet : "";
        }
        this.SetRow(shown, pip, CBFactionLabel(fs.id),
          CBPostureName(posture) + s"   fear \(RoundF(score.GetFactionFear(fs.id)))" + age,
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
        // Standing in front of you, not merely carrying a grudge.
        //
        // This read the Hunting state, which is set when a Rival starts coming for you and is
        // never cleared afterwards, so every Rival who had ever hunted you claimed to be here
        // now - several at once, while the lane only ever has one out. Ask the world instead.
        let body = GameInstance.FindEntityByID(sys.GetGameInstance(), r.spawnedEntityId) as ScriptedPuppet;
        let hunting = EntityID.IsDefined(r.spawnedEntityId) && CBStillStanding(body);
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
        this.m_chipBg[i].SetTintColor(on ? CBHudHead() : new HDRColor(0.0, 0.0, 0.0, 0.0));
      }
      if IsDefined(this.m_chipText[i]) {
        this.m_chipText[i].SetText(CBHudTabName(i + 1));
        this.m_chipText[i].SetTintColor(on ? CBHudHead() : CBHudLabel());
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
    let bodyTop = CBHudContentTop();
    if this.m_tab == 1 {
      this.RenderScores(sys);
      bodyTop = CBHudContentTop() + Cast<Float>(CBHudBarCount()) * 96.0 + 20.0;
    } else {
      if this.m_tab == CBHudFactionsTab() {
        this.RenderFactions(sys);
        bodyTop = CBHudContentTop() + Cast<Float>(CBHudRowCount()) * CBHudRowHeight() + 20.0;
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
          bodyTop = CBHudContentTop() + Cast<Float>(CBHudRowCount()) * CBHudRowHeight() + 20.0;
        }
      }
    }
    if IsDefined(this.m_body) {
      this.m_body.SetMargin(new inkMargin(CBHudMarginX(), bodyTop, 0.0, 0.0));
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
      let quiet = CBHudSince(CBGameSeconds(sys.GetGameInstance()), d.lastIncidentAt);
      let tail = StrLen(quiet) > 0 ? ("   quiet " + quiet) : "";
      out += CBHudPad(NameToString(d.id), 18) + s"renown \(rd)   kills \(d.kills)" + tail + "\n";
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

// "3d", "5h", "20m" - how long since something happened, for the screens that track it.
// Returns "" when it never has.
// Returns "" when it never happened, and also when it was so long ago that the number stops
// being information. "Quiet 3d" tells you nothing you would act on, and these timestamps are
// in whatever unit TimeSystem.GetGameTimeStamp() counts in, which is the game's clock rather
// than yours, so a long gap reads as a bigger number than the player expects. Anything past a
// day is simply dropped, which leaves the column meaning "recently" and nothing else.
public func CBHudSince(now: Float, then: Float) -> String {
  if then <= 0.0 || now <= then {
    return "";
  }
  let secs = now - then;
  if secs >= 86400.0 {
    return "";
  }
  if secs >= 3600.0 {
    return s"\(RoundF(secs / 3600.0))h";
  }
  return s"\(RoundF(secs / 60.0))m";
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

  // The running totals. Every one of these was being counted and shown nowhere, which is the
  // same as not counting it.
  let stats = sys.GetStats();
  if IsDefined(stats) {
    out += s"TALLY   put down \(stats.deaths) times      recognised \(stats.timesRecognized) times";
    out += s"      rivals spared \(stats.rivalsSpared)\n";
    let spent = CBHudPeaceSpend(sys);
    out += s"        tribute taken \(stats.tributeEddies)eb      paid out for peace \(spent)eb\n\n";
  }

  let shown = 0;
  let i = n - 1;
  while i >= 0 && shown < 11 {
    let e = log[i];
    i -= 1;
    if IsDefined(e) {
      let where = Equals(e.district, n"") ? "" : ("  (" + NameToString(e.district) + ")");
      // What the entry was worth, where it had a number. Recorded since the first release and
      // never once displayed.
      let amount = e.value != 0.0 ? s"   \(RoundF(e.value))" : "";
      out += NameToString(e.kind) + where + amount + "\n";
      shown += 1;
    }
  }
  return out;
}

// Everything V has ever paid to buy a gang off.
func CBHudPeaceSpend(sys: ref<CyberbaneSystem>) -> Int32 {
  let deals = sys.GetPeaceDeals();
  let total = 0;
  let i = 0;
  while i < ArraySize(deals) {
    if IsDefined(deals[i]) {
      total += deals[i].cost;
    }
    i += 1;
  }
  return total;
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
    // "Operator", not "Professional".
    //
    // Conduct's top band was renamed Disciplined in 1.3.2 to break this collision, which only
    // half worked: the mod still told players that sparing people gets them treated like a
    // professional while a readout on the same screen said STYLE Professional and moved on
    // finished gigs instead. Renaming both halves is what actually fixes it.
    case 2: return "Operator";
    case 3: return "Chromed";
    case 4: return "Netrunner";
    case 5: return "Brawler";
    default: return "Undefined";
  }
}

// "Disciplined", not "Professional".
//
// Conduct's top band and the STYLE archetype at CBArchetypeName(2) were both called
// Professional, and they measure different things and move on different events: the archetype
// goes up for finishing gigs and hustles, the bar only moves on how you treat people in a
// fight. Two meters reading "Professional" for unrelated reasons is the kind of thing a player
// reasonably reads as a bug in one of them.
func CBCodeLabel(code: Float) -> String {
  if code >= 40.0 {
    return "Disciplined";
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
