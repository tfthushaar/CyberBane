// Cyberbane - The Hub (spec §12.1)
//
// A page of the pause menu: Escape, then Cyberbane. It opens over the menu's own list, the game
// stays paused underneath it, and everything on it is driven with the menu's own cursor. Click a
// screen name to change screen (or use the previous/next tab keys, Q and E or LB and RB), click a
// row to see more about it, click a title to go by it. Escape goes back to the pause menu's list.
// The hooks that put it there, and the reasons it is built this way, are in UI/PauseMenuEntry.reds.
//
// The look is the game's settings menu: the same font (Rajdhani), a centred row of tabs, a line
// saying what the screen is, a rule, then the content, with hints along the bottom. Every colour is
// flat, nothing above 1.0, because HDR colours above white bloom and read as glow, not as a menu.
//
// ---- Paused, and what that means for the numbers --------------------------------------------------
//
// The pause menu stops the game clock, and Cyberbane's own tick stops with it, so every countdown
// on this page is the time as it stood when the menu was opened. That is the honest reading of a
// paused game and it is what was asked for. It also settles the rule for anything the page can
// *do*: choosing a title is a value in a field and happens at once, but paying a gang off moves
// eddies and sends texts, and forgetting the Rivals deletes people from the world. Neither of
// those is done from inside a paused menu. The page records the request and the first settled
// tick after you resume carries it out (CyberbaneSystem.ServiceHubActions), the same way every
// other piece of world work in this mod is kept off UI callbacks.

// Six screens. Messages are not one of them: they live in V's phone (UI/RealPhone.reds).
public func CBHudTabCount() -> Int32 = 7
public func CBHudStandingTab() -> Int32 = 1
public func CBHudFactionsTab() -> Int32 = 2
// Next to GANGS on purpose: what the gangs think of V, then what V has done to their streets.
public func CBHudTurfTab() -> Int32 = 3
public func CBHudCityTab() -> Int32 = 4
public func CBHudRivalsTab() -> Int32 = 5
public func CBHudTitlesTab() -> Int32 = 6
public func CBHudHistoryTab() -> Int32 = 7

// Lines of prose each screen has room for under its own content, before the footer rule at 934.
// Every screen draws its own content first and the prose goes underneath or beside it; these are
// measured against the positions below and the 26 px line height of the body font, with a line of
// slack, because text running into the footer is the one failure a player actually sees.
public func CBHudMaxLinesFor(tab: Int32) -> Int32 {
  if tab == CBHudStandingTab() {
    return 11;   // under four meters
  }
  if tab == CBHudFactionsTab() || tab == CBHudRivalsTab() || tab == CBHudCityTab()
     || tab == CBHudTurfTab() {
    return 9;    // under ten list rows
  }
  if tab == CBHudTitlesTab() {
    return 26;   // the right-hand column, full height
  }
  return 26;
}

// ---- Layout ----------------------------------------------------------------------------------------
//
// Everything is written against a fixed 1920x1080 design, centred and scaled as one piece to the
// space it is drawn in. Fixed rather than stretched because every row is positioned by hand, and a
// design that is centred reads correctly at any resolution while one that is stretched does not.
// 1640 x 1020, not 1860.
//
// The page is the widest thing in the game's interface by a long way, and width is what exposes
// the distortion the whole UI is drawn with: a 1540 px horizontal run bows visibly where a 300 px
// one does not. The game's own screens keep content in a narrower column for exactly that reason,
// and Engram - the mod on this machine that does read as native - wraps its text at 1180.
//
// Narrowed by 14% rather than to 1180, because every row column is positioned by hand and
// budgeted in characters: at 1180 a Rival's full name no longer fits. 14% takes the widest run
// from 1540 to 1320 and still leaves 28 characters for a name. The margin stays 160, so the
// content is still centred (1640 - 1320 = 320, 160 a side).
public func CBHudPanelW() -> Float = 1640.0
public func CBHudPanelH() -> Float = 1020.0
public func CBHudDesignW() -> Float = 1920.0
public func CBHudDesignH() -> Float = 1080.0

// How much to shrink Cyberbane's HUD widgets (the threat bars and the message cards) so they fit
// the screen they are on.
//
// The ink coordinate space is not a fixed 1920x1080. The game's own code states the relationship
// in `cyberpunk/UI/widgets/cpo/targetHitIndicator.script`: the usable space is the window size times
// the inverse UI scale. Raise the game's UI scale, or play below 1080p, and the space shrinks below
// the layout - the "UI is so big I can barely see the text" report.
//
// Measured two ways and the smaller wins, because which side of that conversion the HUD layer is
// already in could not be settled from the source, and the cost of being wrong is a widget drawn
// somewhat smaller than it needed to be rather than one running off the screen. Never above 1.0 on
// its own; anything larger is the player's business, through the slider below.
public func CBUiFitScale(game: GameInstance) -> Float {
  let ui = GameInstance.GetUISystem(game);
  if !IsDefined(ui) {
    return 1.0;
  }
  let win = ui.GetCurrentWindowSize();
  let inv = ui.GetInverseUIScale();
  if win.X <= 0.0 || win.Y <= 0.0 || inv <= 0.0 {
    return 1.0;   // nothing sensible to measure against; leave the layout alone
  }
  let byPixels = MinF(win.X / CBHudDesignW(), win.Y / CBHudDesignH());
  let byWidget = MinF((win.X * inv) / CBHudDesignW(), (win.Y * inv) / CBHudDesignH());
  return ClampF(MinF(byPixels, byWidget), 0.35, 1.0);
}

// The player's own size preference from Mod Settings (Interface size), as a multiplier.
public func CBHudUserScale() -> Float {
  let user = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    user = Cast<Float>(rt.GetSettings().hudScale) / 100.0;
  }
  return ClampF(user, 0.5, 1.5);
}

// The HUD fit above, times what the player asked for. Used by the threat bars and the cards.
public func CBHudScale(game: GameInstance) -> Float {
  return ClampF(CBUiFitScale(game) * CBHudUserScale(), 0.3, 1.5);
}

// How much to scale the Hub page so the 1920x1080 design fills the pause menu.
//
// The page is drawn in the pause menu's own units, which are not the HUD's. The game converts
// between menu units and screen pixels with the inverse UI scale: on the perks screen a menu-space
// height times 1 / GetInverseUIScale is compared against the cursor in pixels
// (NewPerksCategoriesGameController.script:530-536), so the whole screen is window size times the
// inverse scale in menu units. The game's menus are authored at 3840x2160, which at 1080p is an
// inverse scale of 2, so this normally comes out at about 2.
//
// The size the pause menu's root reports is taken as a second opinion, and the smaller of the two
// wins, for the same reason as the HUD fit: a page drawn a little small is a cosmetic problem and a
// page running off the screen is one the player cannot work around. The figures are logged, so a
// report of a wrongly sized Hub comes with the numbers that explain it.
public func CBHubPageScale(game: GameInstance, root: wref<inkCompoundWidget>) -> Float {
  let s = 0.0;
  let ui = GameInstance.GetUISystem(game);
  let winX = 0.0;
  let winY = 0.0;
  let inv = 0.0;
  if IsDefined(ui) {
    let win = ui.GetCurrentWindowSize();
    winX = win.X;
    winY = win.Y;
    inv = ui.GetInverseUIScale();
    if winX > 0.0 && winY > 0.0 && inv > 0.0 {
      s = MinF((winX * inv) / CBHudDesignW(), (winY * inv) / CBHudDesignH());
    }
  }
  let rootX = 0.0;
  let rootY = 0.0;
  let rootKind = "none";
  if IsDefined(root) {
    rootKind = NameToString(root.GetClassName());
    let size = root.GetSize();
    rootX = size.X;
    rootY = size.Y;
    // Only a size that could be a whole screen counts; a root sized by its anchor reports little.
    if rootX >= 1000.0 && rootY >= 560.0 {
      let byRoot = MinF(rootX / CBHudDesignW(), rootY / CBHudDesignH());
      s = s > 0.0 ? MinF(s, byRoot) : byRoot;
    }
  }
  if s <= 0.0 {
    s = 2.0;   // nothing to measure: the menus are authored at twice the design
  }
  let scaled = ClampF(s * CBHudUserScale(), 0.4, 4.0);
  CBLog.Info(n"UI", s"Hub page: window \(RoundF(winX))x\(RoundF(winY)), inverse scale \(inv), menu root \(rootKind) \(RoundF(rootX))x\(RoundF(rootY)), drawn at \(RoundF(scaled * 100.0))%.");
  return scaled;
}

public func CBHudMarginX() -> Float = 160.0
public func CBHudContentW() -> Float = 1320.0
// Tabs: narrower, so the row spans about 1000 px instead of 1500.
//
// Reported twice: the Hub looks curved while the game's own menus and Mod Settings look flat, and
// it stayed curved after being moved onto the menu layer and again after being moved inside the
// pause menu's own widget tree. Nothing in this file warps anything - the only transform on the
// page is a uniform scale, and a uniform scale cannot bow a straight line.
//
// What the page did have, and no menu in the game has, is 1540 px-wide one-pixel horizontal rules
// and a tab row almost as wide. A long thin horizontal line is the shape that shows the UI's
// distortion most; the game's own screens keep their content in a narrower column and divide it
// with panels rather than hairlines, which is why the same distortion is invisible on them. So
// the fix for "it looks curved" is the same as the fix for "it does not look like the game":
// stop drawing the shapes that reveal it.
public func CBHudChipWidth() -> Float = 172.0
public func CBHudBarCount() -> Int32 = 4
public func CBHudBarWidth() -> Float = 1320.0
public func CBHudContentTop() -> Float = 200.0
public func CBHudFooterY() -> Float = 952.0

// The list rows. One pool, laid out per screen: ten wide rows for the gangs, the city and the
// Rivals, or a narrow column of up to twenty-one for the titles (all twenty plus "automatic").
public func CBHudRowPool() -> Int32 = 21
public func CBHudListRows() -> Int32 = 10
public func CBHudRowHeight() -> Float = 44.0
public func CBHudTitleRowHeight() -> Float = 32.0
public func CBHudTitleListW() -> Float = 760.0

// The panel under a list, where the selected row is described, and the one button beside it.
public func CBHudDetailTop() -> Float = 664.0
public func CBHudActionW() -> Float = 420.0
public func CBHudActionH() -> Float = 56.0

// Row layouts, as the columns are positioned for them.
public func CBHudLayoutGangs() -> Int32 = 0
public func CBHudLayoutWide() -> Int32 = 1
public func CBHudLayoutTitles() -> Int32 = 2

// Colours.
//
// The first five are the settings menu's: salmon labels, white values, a brighter white for
// anything selected, and a dim red rule. The next five are Cyberbane's own, for meters and status
// pips, where a reputation screen needs to say good, bad or dangerous and the settings menu has
// nothing to borrow. Nothing here goes above 1.0.
public func CBHudLabel() -> HDRColor = new HDRColor(0.85, 0.28, 0.30, 1.0)
public func CBHudValue() -> HDRColor = new HDRColor(0.92, 0.93, 0.95, 1.0)
public func CBHudHead() -> HDRColor = new HDRColor(1.00, 1.00, 1.00, 1.0)
public func CBHudDim() -> HDRColor = new HDRColor(0.62, 0.40, 0.41, 0.95)
public func CBHudCyan() -> HDRColor = new HDRColor(0.16, 0.78, 0.88, 1.0)
public func CBHudAmber() -> HDRColor = new HDRColor(0.88, 0.64, 0.16, 1.0)
public func CBHudRed() -> HDRColor = new HDRColor(0.88, 0.26, 0.29, 1.0)
public func CBHudGreen() -> HDRColor = new HDRColor(0.26, 0.78, 0.50, 1.0)
public func CBHudGrey() -> HDRColor = new HDRColor(0.55, 0.62, 0.70, 1.0)

// What something you can click looks like at rest, under the cursor, and chosen. The settings
// menu marks hover with a lighter band and the chosen item with a stronger one; so does this.
public func CBHudBandEven() -> HDRColor = new HDRColor(0.14, 0.05, 0.06, 0.50)
public func CBHudBandOdd() -> HDRColor = new HDRColor(0.08, 0.03, 0.04, 0.30)
public func CBHudBandHover() -> HDRColor = new HDRColor(0.26, 0.08, 0.10, 0.80)
public func CBHudBandPicked() -> HDRColor = new HDRColor(0.38, 0.11, 0.13, 0.90)
public func CBHudButtonIdle() -> HDRColor = new HDRColor(0.30, 0.09, 0.11, 0.85)
public func CBHudButtonHover() -> HDRColor = new HDRColor(0.48, 0.14, 0.16, 0.95)
public func CBHudButtonOff() -> HDRColor = new HDRColor(0.12, 0.05, 0.06, 0.60)
public func CBHudClear() -> HDRColor = new HDRColor(0.0, 0.0, 0.0, 0.0)

// Cut a column's text to what its box can actually show.
//
// The row columns are fixed widths, and inkText does not clip, so an over-long string runs straight
// into the next column. Budgets are per column and enforced in SetRow, so this cannot be forgotten
// at a call site.
public func CBHudTrim(text: String, maxChars: Int32) -> String {
  if StrLen(text) <= maxChars {
    return text;
  }
  if maxChars <= 1 {
    return "";
  }
  return StrLeft(text, maxChars - 1) + ".";
}

// Row columns.
//
// Six fields per row, one field per column, positioned per screen, so the fields line up down the
// list and each one is trimmed against its own width. Column 5 is right-aligned to the row's right
// edge, because it is the "what is coming" column and the settings menu puts its values there too.
public func CBHudRowCols() -> Int32 = 6

// What each column is tinted: the name brightest, the two middle facts in the value colour, the one
// that says what V has done to them warm, and the status on the right dimmed.
public func CBHudRowColTint(col: Int32) -> HDRColor {
  if col == 0 { return CBHudHead(); }
  if col == 1 { return CBHudValue(); }
  if col == 2 { return CBHudGrey(); }
  if col == 3 { return CBHudCyan(); }
  if col == 4 { return new HDRColor(0.80, 0.52, 0.34, 1.0); }
  return CBHudDim();
}

// x, as an offset from the row's left edge.
public func CBHudRowColX(col: Int32, layout: Int32) -> Float {
  if layout == CBHudLayoutGangs() {
    if col == 0 { return 21.0; }
    if col == 1 { return 231.0; }
    if col == 2 { return 360.0; }
    if col == 3 { return 480.0; }
    if col == 4 { return 703.0; }
  } else {
    if col == 0 { return 21.0; }
    if col == 1 { return 411.0; }
    if col == 2 { return 626.0; }
    if col == 3 { return 737.0; }
    if col == 4 { return 968.0; }
  }
  return 0.0;      // column 5 is right-aligned across the row
}

// Characters each column can show at its width and font, measured against the positions above.
public func CBHudRowColChars(col: Int32, layout: Int32) -> Int32 {
  // Scaled with the widths above (x 0.857). A budget that did not move would let one column's
  // text run under the next one's, which reads worse than a word being cut short.
  if layout == CBHudLayoutTitles() {
    if col == 0 { return 34; }
    if col == 5 { return 12; }
    return 0;
  }
  if layout == CBHudLayoutGangs() {
    if col == 0 { return 15; }
    if col == 1 { return 9; }
    if col == 2 { return 8; }
    if col == 3 { return 15; }
    if col == 4 { return 10; }
    return 24;
  }
  if col == 0 { return 28; }
  if col == 1 { return 15; }
  if col == 2 { return 8; }
  if col == 3 { return 16; }
  if col == 4 { return 0; }
  return 20;
}

// A time as the player asked to see it: exact, or in words when "Show countdowns" is off, so
// nothing on screen gives them a clock to keep.
public func CBTimeText(ticks: Int32) -> String {
  if CBShowCountdowns() {
    return CBHudCountdown(ticks);
  }
  if ticks <= 30 {
    return "any moment";
  }
  if ticks <= 120 {
    return "soon";
  }
  if ticks <= 600 {
    return "before long";
  }
  return "later";
}

// "in 2m 05s" with countdowns on, "soon" without: reads right after a noun either way.
public func CBWhen(ticks: Int32) -> String {
  return CBShowCountdowns() && ticks > 0 ? "in " + CBHudCountdown(ticks) : CBTimeText(ticks);
}

public func CBShowCountdowns() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().showCountdowns;
}

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

// Plain words: a player opening the Hub for the first time should be able to guess what each
// screen holds from its name, which is the whole job of a tab label.
public func CBHudTabName(tab: Int32) -> String {
  switch tab {
    case 1: return "STANDING";
    case 2: return "GANGS";
    case 3: return "TURF";
    case 4: return "THE CITY";
    case 5: return "RIVALS";
    case 6: return "TITLES";
    case 7: return "HISTORY";
    default: return "";
  }
}

// One sentence saying what this screen is for, under the header.
public func CBHudTabBlurb(tab: Int32) -> String {
  switch tab {
    case 1: return "Who you are in this city, and what is on its way to you.";
    case 2: return "What each gang thinks of you. Click one to see more, or to pay them off.";
    case 3: return "Who holds each district, how firmly, and who is fighting them for it.";
    case 4: return "Where in Night City your name carries, district by district.";
    case 5: return "The people who have survived you and are still looking. Click one for their file.";
    case 6: return "What the street calls you. Click a title to go by it.";
    case 7: return "The ledger: what you did, where, and who it was.";
    default: return "";
  }
}

// A screen number that is always one of the seven.
public func CBHudClampTab(tab: Int32) -> Int32 {
  if tab < 1 {
    return 1;
  }
  if tab > CBHudTabCount() {
    return CBHudTabCount();
  }
  return tab;
}

// A widget name for a clickable thing, made once at build time. The click handler is told which
// widget it is running for (inkEvent.GetCurrentTarget, core/ui/events.script:7) and matches the
// name against these, so one handler serves every tab, row and button.
func CBHudWidgetName(prefix: String, index: Int32) -> CName {
  let text = prefix + IntToString(index);
  return StringToName(text);
}

public func CBHudActionName() -> CName = n"cbHubAction"
public func CBHudSettingsName() -> CName = n"cbHubModSettings"

// The event Mod Settings adds to the pause scenario for its own entry. Spawning it from the page is
// exactly what clicking "Mod Settings" in the pause menu's list does.
public func CBModSettingsEvent() -> CName = n"OnSwitchToModSettings"

public class CBHud {
  // The pause menu this page is drawn in. Weak: the menu owns the page, never the other way round.
  private let m_owner: wref<PauseMenuGameController>;
  private let m_built: Bool;
  private let m_open: Bool;
  private let m_tab: Int32;               // 1..CBHudTabCount
  // Every widget is held weakly. The pause menu's tree owns them, and when the menu goes they go
  // with it; nothing here can keep a widget alive past the menu it was drawn in.
  private let m_root: wref<inkCanvas>;
  private let m_panel: wref<inkCanvas>;
  private let m_subhead: wref<inkText>;
  private let m_tabline: wref<inkText>;
  private let m_body: wref<inkText>;
  // Tabs: a clickable box per screen, with a band behind the name and a bar under the open one.
  private let m_tabBox: array<wref<inkCanvas>>;
  private let m_tabBg: array<wref<inkRectangle>>;
  private let m_tabUnder: array<wref<inkRectangle>>;
  private let m_tabText: array<wref<inkText>>;
  private let m_tabNames: array<CName>;
  // Meters: label, value, track, fill and caption per score on the Standing screen.
  private let m_barLabel: array<wref<inkText>>;
  private let m_barValue: array<wref<inkText>>;
  private let m_barTrack: array<wref<inkRectangle>>;
  private let m_barFill: array<wref<inkRectangle>>;
  private let m_barCap: array<wref<inkText>>;
  // List rows: a clickable box per row holding a band, a colour pip and six cells. Cells are flat:
  // row r column c is at r * CBHudRowCols() + c.
  private let m_rowBox: array<wref<inkCanvas>>;
  private let m_rowBg: array<wref<inkRectangle>>;
  private let m_rowPip: array<wref<inkRectangle>>;
  private let m_rowCell: array<wref<inkText>>;
  private let m_rowNames: array<CName>;
  private let m_rowLayout: Int32;
  private let m_rowPlaced: Bool;
  // What each row stands for as drawn, so a click can be answered without recomputing the list.
  private let m_rowShown: array<Bool>;
  private let m_rowClickable: array<Bool>;
  private let m_rowPicked: array<Bool>;
  private let m_rowFaction: array<CName>;
  private let m_rowRival: array<Int32>;
  private let m_rowTitle: array<CName>;
  // The one action button beside the detail panel, and the Mod Settings link in the footer.
  private let m_actionBox: wref<inkCanvas>;
  private let m_actionBg: wref<inkRectangle>;
  private let m_actionText: wref<inkText>;
  private let m_actionOn: Bool;
  private let m_settingsBox: wref<inkCanvas>;
  private let m_settingsBg: wref<inkRectangle>;
  // What the player has picked on the screens that have something to pick.
  private let m_pickFaction: CName;
  private let m_pickRival: Int32;
  private let m_purgeArmed: Bool;          // "forget every rival" asks twice
  private let m_resetArmed: Bool;          // "start over" asks twice as well
  private let m_hover: CName;              // the clickable thing under the cursor, by name
  private let m_inputBound: Bool;          // the tab keys are registered with the pause menu
  // Why no Rival can arrive right now, or "". Resolved once per render, not once per row.
  private let m_holdLabel: String;

  public func IsOpen() -> Bool {
    return this.m_open && this.m_built;
  }

  // Show the page in this pause menu, building it the first time. False if there was nowhere to
  // draw it, in which case the menu is left exactly as it was.
  public func Show(owner: ref<PauseMenuGameController>, sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
    if !IsDefined(owner) || !IsDefined(sys) {
      return false;
    }
    if !this.m_built {
      this.m_owner = owner;
      if !this.Build(owner, game) {
        return false;
      }
    }
    if this.m_tab < 1 || this.m_tab > CBHudTabCount() {
      this.m_tab = CBHudClampTab(sys.GetHubTab());
    }
    this.m_open = true;
    this.m_purgeArmed = false;
    this.m_resetArmed = false;
    this.m_hover = n"";
    this.Render(sys, game);
    return true;
  }

  // Out of sight. Nothing is removed: the widgets stay in the menu's tree until the menu goes,
  // because taking widgets out by hand is what the 1.4.7 phone crash was made of.
  public func Hide() -> Void {
    this.m_open = false;
    this.m_purgeArmed = false;
    this.m_resetArmed = false;
    this.m_hover = n"";
    if IsDefined(this.m_root) {
      this.m_root.SetVisible(false);
    }
  }

  // The pause menu is going. Hand every callback back while the widgets still exist, then let go.
  // Called from the menu's OnUninitialize, before the game starts dismantling it.
  public func Detach() -> Void {
    let i = 0;
    while i < ArraySize(this.m_tabBox) {
      this.Unhook(this.m_tabBox[i]);
      i += 1;
    }
    i = 0;
    while i < ArraySize(this.m_rowBox) {
      this.Unhook(this.m_rowBox[i]);
      i += 1;
    }
    this.Unhook(this.m_actionBox);
    this.Unhook(this.m_settingsBox);
    if this.m_inputBound && IsDefined(this.m_owner) {
      this.m_owner.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"CBOnGlobalRelease");
    }
    this.m_inputBound = false;
    this.m_open = false;
    this.m_built = false;
    this.m_owner = null;
  }

  private func Hook(box: wref<inkCanvas>) -> Void {
    if !IsDefined(box) {
      return;
    }
    box.SetInteractive(true);
    box.RegisterToCallback(n"OnRelease", this, n"CBOnClick");
    box.RegisterToCallback(n"OnHoverOver", this, n"CBOnHoverOver");
    box.RegisterToCallback(n"OnHoverOut", this, n"CBOnHoverOut");
  }

  private func Unhook(box: wref<inkCanvas>) -> Void {
    if !IsDefined(box) {
      return;
    }
    box.UnregisterFromCallback(n"OnRelease", this, n"CBOnClick");
    box.UnregisterFromCallback(n"OnHoverOver", this, n"CBOnHoverOver");
    box.UnregisterFromCallback(n"OnHoverOut", this, n"CBOnHoverOut");
    box.SetInteractive(false);
  }

  private func Click() -> Void {
    if IsDefined(this.m_owner) {
      this.m_owner.CBPlayClick();
    }
  }

  // ---- Building --------------------------------------------------------------------------------

  // Take a colour from the game instead of naming one here.
  //
  // `main_colors.inkstyle` is the palette the whole interface is drawn from, and its names carry
  // a system: plain (`Red`, `Blue`, `Grey`) for foreground, `Panel*` for backgrounds, `Active*`
  // for the selected thing, `Mild*` and `Faint*` for what should sit back. Binding to it is what
  // makes a code-built page read as part of the game rather than as something drawn on top of it,
  // and it is how Engram - the other mod on this machine, which does look native - gets its look.
  // There is no borrowed artwork in this: the native feel is the palette, the type scale and the
  // spacing, not an atlas.
  //
  // Two rules learned the hard way:
  //
  //   1. **Tint first, bind second.** `BindProperty` returns a Bool and a name that does not
  //      resolve simply does not bind, leaving whatever tint the widget already had. Every caller
  //      therefore passes a real colour as well, so the failure mode is the old palette rather
  //      than an untinted white box.
  //   2. **Only bind what does not change.** A bound property wins over a later `SetTintColor`,
  //      so anything whose colour is a state - a picked tab, a hovered row, a meter fill - keeps
  //      its explicit tint and is not bound at all. Static text is bound; state is not.
  private func Paint(w: ref<inkWidget>, colour: CName) -> Void {
    if !IsDefined(w) || Equals(colour, n"") {
      return;
    }
    w.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    w.BindProperty(n"tintColor", colour);
  }

  private func NewText(parent: ref<inkCompoundWidget>, size: Int32, style: CName, tint: HDRColor,
                       opt colour: CName) -> ref<inkText> {
    let t = new inkText();
    t.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    t.SetFontStyle(style);
    t.SetFontSize(size);
    t.SetTintColor(tint);
    t.SetAnchor(inkEAnchor.TopLeft);
    t.Reparent(parent, -1);
    this.Paint(t, colour);
    return t;
  }

  private func NewRect(parent: ref<inkCompoundWidget>, tint: HDRColor) -> ref<inkRectangle> {
    let r = new inkRectangle();
    r.SetAnchor(inkEAnchor.TopLeft);
    r.SetTintColor(tint);
    r.Reparent(parent, -1);
    return r;
  }

  // A box that can be clicked: a canvas with a band filling it. The canvas is the target, so the
  // text drawn on it is part of the target too, and the band is what changes under the cursor.
  private func NewBox(parent: ref<inkCompoundWidget>, name: CName, x: Float, y: Float, w: Float, h: Float) -> ref<inkCanvas> {
    let box = new inkCanvas();
    box.SetName(name);
    box.SetAnchor(inkEAnchor.TopLeft);
    box.SetSize(new Vector2(w, h));
    box.SetMargin(new inkMargin(x, y, 0.0, 0.0));
    box.Reparent(parent, -1);
    return box;
  }

  private func NewBand(box: ref<inkCanvas>, tint: HDRColor) -> ref<inkRectangle> {
    let bg = new inkRectangle();
    bg.SetAnchor(inkEAnchor.Fill);
    bg.SetTintColor(tint);
    bg.Reparent(box, -1);
    return bg;
  }

  private func Build(owner: ref<PauseMenuGameController>, game: GameInstance) -> Bool {
    let parent = owner.GetRootCompoundWidget();
    if !IsDefined(parent) {
      return false;
    }
    let x = CBHudMarginX();
    let w = CBHudContentW();

    let root = new inkCanvas();
    root.SetName(n"cyberbaneHub");
    root.SetAnchor(inkEAnchor.Fill);
    root.SetVisible(false);

    // The settings menu dims the world almost to black with a red cast rather than greying it.
    // Interactive, so the cursor lands on the page and never on the menu underneath it.
    let backdrop = new inkRectangle();
    backdrop.SetAnchor(inkEAnchor.Fill);
    backdrop.SetTintColor(new HDRColor(0.055, 0.012, 0.022, 0.97));
    backdrop.SetInteractive(true);
    backdrop.Reparent(root, -1);

    let panel = new inkCanvas();
    panel.SetAnchor(inkEAnchor.Centered);
    panel.SetAnchorPoint(new Vector2(0.5, 0.5));
    panel.SetSize(new Vector2(CBHudPanelW(), CBHudPanelH()));
    panel.SetRenderTransformPivot(new Vector2(0.5, 0.5));
    let s = CBHubPageScale(game, parent);
    panel.SetScale(new Vector2(s, s));
    panel.Reparent(root, -1);

    // ---- Title block, top left, the way the menus mark themselves --------
    let header = this.NewText(panel, 28, n"Semibold", CBHudLabel(), n"MainColors.Red");
    header.SetLetterCase(textLetterCase.UpperCase);
    header.SetText("CYBERBANE");
    header.SetMargin(new inkMargin(x, 10.0, 0.0, 0.0));

    // ---- Tabs, centred across the top -------------------------------------
    let tabsW = Cast<Float>(CBHudTabCount()) * CBHudChipWidth();
    let tabsX = (CBHudPanelW() - tabsW) / 2.0;
    let t = 0;
    while t < CBHudTabCount() {
      let name = CBHudWidgetName("cbHubTab", t + 1);
      let box = this.NewBox(panel, name, tabsX + Cast<Float>(t) * CBHudChipWidth() + 4.0, 48.0,
                            CBHudChipWidth() - 8.0, 52.0);
      let bg = this.NewBand(box, CBHudClear());
      let label = this.NewText(box, 24, n"Semibold", CBHudLabel());
      label.SetLetterCase(textLetterCase.UpperCase);
      label.SetHorizontalAlignment(textHorizontalAlignment.Center);
      label.SetFitToContent(false);
      label.SetSize(new Vector2(CBHudChipWidth() - 8.0, 32.0));
      label.SetMargin(new inkMargin(0.0, 9.0, 0.0, 0.0));
      label.SetText(CBHudTabName(t + 1));
      // The open screen is marked by a bar under its name, which is what the game does.
      let under = this.NewRect(box, CBHudClear());
      under.SetSize(new Vector2(CBHudChipWidth() - 48.0, 3.0));
      under.SetMargin(new inkMargin(20.0, 47.0, 0.0, 0.0));
      ArrayPush(this.m_tabBox, box);
      ArrayPush(this.m_tabBg, bg);
      ArrayPush(this.m_tabText, label);
      ArrayPush(this.m_tabUnder, under);
      ArrayPush(this.m_tabNames, name);
      t += 1;
    }

    // ---- The lines under the tabs that say what you are looking at ---------
    let subhead = this.NewText(panel, 24, n"Medium", CBHudDim(), n"MainColors.Grey");
    subhead.SetHorizontalAlignment(textHorizontalAlignment.Center);
    subhead.SetFitToContent(false);
    subhead.SetSize(new Vector2(CBHudPanelW(), 32.0));
    subhead.SetMargin(new inkMargin(0.0, 110.0, 0.0, 0.0));
    this.m_subhead = subhead;

    let tabline = this.NewText(panel, 20, n"Medium", CBHudGrey(), n"MainColors.Grey");
    tabline.SetHorizontalAlignment(textHorizontalAlignment.Center);
    tabline.SetFitToContent(false);
    tabline.SetSize(new Vector2(CBHudPanelW(), 28.0));
    tabline.SetMargin(new inkMargin(0.0, 136.0, 0.0, 0.0));
    this.m_tabline = tabline;

    // No rule under the header. It was 1540 px of two-pixel line, which is the single most
    // warp-revealing shape on the page, and the heading above it already separates the screens.

    // ---- Score meters -------------------------------------------------------
    let b = 0;
    while b < CBHudBarCount() {
      let top = CBHudContentTop() + Cast<Float>(b) * 96.0;
      let bl = this.NewText(panel, 25, n"Semibold", CBHudLabel(), n"MainColors.Red");
      bl.SetLetterCase(textLetterCase.UpperCase);
      bl.SetMargin(new inkMargin(x, top, 0.0, 0.0));
      // Right-aligned against the edge the meter ends on, so every value lines up in one column.
      let bv = this.NewText(panel, 25, n"Semibold", CBHudValue());
      bv.SetHorizontalAlignment(textHorizontalAlignment.Right);
      bv.SetFitToContent(false);
      bv.SetSize(new Vector2(w, 30.0));
      bv.SetMargin(new inkMargin(x, top, 0.0, 0.0));
      let track = this.NewRect(panel, new HDRColor(0.26, 0.08, 0.10, 0.9));
      track.SetSize(new Vector2(CBHudBarWidth(), 10.0));
      track.SetMargin(new inkMargin(x, top + 36.0, 0.0, 0.0));
      let fill = this.NewRect(panel, CBHudCyan());
      fill.SetSize(new Vector2(2.0, 10.0));
      fill.SetMargin(new inkMargin(x, top + 36.0, 0.0, 0.0));
      let cap = this.NewText(panel, 19, n"Medium", CBHudDim(), n"MainColors.Grey");
      cap.SetMargin(new inkMargin(x, top + 54.0, 0.0, 0.0));
      cap.SetWrapping(true, w);
      ArrayPush(this.m_barLabel, bl);
      ArrayPush(this.m_barValue, bv);
      ArrayPush(this.m_barTrack, track);
      ArrayPush(this.m_barFill, fill);
      ArrayPush(this.m_barCap, cap);
      b += 1;
    }

    // ---- List rows -----------------------------------------------------------
    // Positions are set per screen in PlaceRows; here they only need to exist.
    let r = 0;
    while r < CBHudRowPool() {
      let rname = CBHudWidgetName("cbHubRow", r);
      let rbox = this.NewBox(panel, rname, x, CBHudContentTop() + Cast<Float>(r) * CBHudRowHeight(),
                             w, CBHudRowHeight() - 4.0);
      let band = this.NewBand(rbox, r % 2 == 0 ? CBHudBandEven() : CBHudBandOdd());
      let pip = this.NewRect(rbox, CBHudGrey());
      pip.SetSize(new Vector2(5.0, 26.0));
      pip.SetMargin(new inkMargin(0.0, 7.0, 0.0, 0.0));
      ArrayPush(this.m_rowBox, rbox);
      ArrayPush(this.m_rowBg, band);
      ArrayPush(this.m_rowPip, pip);
      ArrayPush(this.m_rowNames, rname);
      ArrayPush(this.m_rowShown, false);
      ArrayPush(this.m_rowClickable, false);
      ArrayPush(this.m_rowPicked, false);
      ArrayPush(this.m_rowFaction, n"");
      ArrayPush(this.m_rowRival, 0);
      ArrayPush(this.m_rowTitle, n"");
      // Column 0 is the name, so it carries the heavier weight; the last column is right-aligned.
      let c = 0;
      while c < CBHudRowCols() {
        let cell = this.NewText(rbox, c == 0 ? 23 : 22, c == 0 ? n"Semibold" : n"Medium", CBHudRowColTint(c));
        if c == CBHudRowCols() - 1 {
          cell.SetHorizontalAlignment(textHorizontalAlignment.Right);
          cell.SetFitToContent(false);
          cell.SetSize(new Vector2(w - 16.0, 28.0));
        }
        ArrayPush(this.m_rowCell, cell);
        c += 1;
      }
      rbox.SetVisible(false);
      r += 1;
    }

    // ---- Prose: under the meters, under a list, or beside the titles -----------
    let body = this.NewText(panel, 21, n"Medium", CBHudValue());
    body.SetMargin(new inkMargin(x, CBHudContentTop(), 0.0, 0.0));
    body.SetWrapping(true, w);
    body.SetSize(new Vector2(w, 700.0));
    this.m_body = body;

    // ---- The button beside the detail panel ---------------------------------------
    let action = this.NewBox(panel, CBHudActionName(), x + w - CBHudActionW(), CBHudDetailTop() - 4.0,
                             CBHudActionW(), CBHudActionH());
    let actionBg = this.NewBand(action, CBHudButtonIdle());
    let actionText = this.NewText(action, 23, n"Semibold", CBHudHead());
    actionText.SetLetterCase(textLetterCase.UpperCase);
    actionText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    actionText.SetFitToContent(false);
    actionText.SetSize(new Vector2(CBHudActionW(), 30.0));
    actionText.SetMargin(new inkMargin(0.0, 13.0, 0.0, 0.0));
    action.SetVisible(false);
    this.m_actionBox = action;
    this.m_actionBg = actionBg;
    this.m_actionText = actionText;

    // ---- Footer: hints on the left, the Mod Settings link on the right -----------
    // The footer is set off by its own dimmer text and the gap above it rather than by a rule
    // across the whole page, for the same reason as the header.

    let footer = this.NewText(panel, 19, n"Medium", CBHudDim(), n"MainColors.Grey");
    footer.SetMargin(new inkMargin(x, CBHudFooterY(), 0.0, 0.0));
    footer.SetText("Click a screen, or Q / E (LB / RB) to switch      Click a row for more      Esc / B: back to the pause menu");

    let settings = this.NewBox(panel, CBHudSettingsName(), x + w - 260.0, CBHudFooterY() - 8.0, 260.0, 40.0);
    let settingsBg = this.NewBand(settings, CBHudButtonIdle());
    let settingsText = this.NewText(settings, 19, n"Semibold", CBHudHead());
    settingsText.SetLetterCase(textLetterCase.UpperCase);
    settingsText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    settingsText.SetFitToContent(false);
    settingsText.SetSize(new Vector2(260.0, 26.0));
    settingsText.SetMargin(new inkMargin(0.0, 8.0, 0.0, 0.0));
    settingsText.SetText("Mod Settings");
    this.m_settingsBox = settings;
    this.m_settingsBg = settingsBg;

    // Into the pause menu, on top of everything it already draws. A root drawn back to front puts
    // its first child on top, so the page goes in first there and last everywhere else.
    if Equals(parent.GetChildOrder(), inkEChildOrder.Backward) {
      root.Reparent(parent, 0);
    } else {
      root.Reparent(parent, -1);
    }
    this.m_root = root;
    this.m_panel = panel;

    // Clicks and hover, once, for the life of the menu.
    let i = 0;
    while i < ArraySize(this.m_tabBox) {
      this.Hook(this.m_tabBox[i]);
      i += 1;
    }
    i = 0;
    while i < ArraySize(this.m_rowBox) {
      this.Hook(this.m_rowBox[i]);
      i += 1;
    }
    this.Hook(this.m_actionBox);
    this.Hook(this.m_settingsBox);
    // The previous/next tab keys. Registered once and left until the menu goes, rather than on
    // every show and hide, so nothing is ever registered or unregistered in the middle of the very
    // input event that is being delivered.
    owner.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"CBOnGlobalRelease");
    this.m_inputBound = true;
    this.m_built = true;
    return true;
  }

  // ---- Input -----------------------------------------------------------------------------------

  // Every tab, row and button. Which one it was comes from the widget the handler is running for.
  protected cb func CBOnClick(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) {
      return false;
    }
    // The mouse button is `click`; a controller's confirm button is `select` in some menus; touch is
    // `tap`. The game's own handlers take whichever of these they expect (pauseMenu.script:196,
    // inventoryGameController.script:942), and one release is one event however many it matches,
    // so taking all three cannot fire anything twice.
    if !e.IsAction(n"click") && !e.IsAction(n"select") && !e.IsAction(n"tap") {
      return false;
    }
    let target = e.GetCurrentTarget();
    if !IsDefined(target) {
      return false;
    }
    let name = target.GetName();
    let game = GetGameInstance();
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) {
      return false;
    }
    let i = 0;
    while i < ArraySize(this.m_tabNames) {
      if Equals(this.m_tabNames[i], name) {
        e.Handle();
        if this.m_tab != i + 1 {
          this.Click();
          this.SelectTab(sys, game, i + 1);
        }
        return true;
      }
      i += 1;
    }
    i = 0;
    while i < ArraySize(this.m_rowNames) {
      if Equals(this.m_rowNames[i], name) {
        e.Handle();
        if this.m_rowShown[i] && this.m_rowClickable[i] {
          this.Click();
          this.RowClicked(sys, game, i);
        }
        return true;
      }
      i += 1;
    }
    if Equals(name, CBHudActionName()) {
      e.Handle();
      if this.m_actionOn {
        this.Click();
        this.ActionClicked(sys, game);
      }
      return true;
    }
    if Equals(name, CBHudSettingsName()) {
      e.Handle();
      this.Click();
      // Last thing done here: switching screens closes the pause menu's page, which takes this one
      // with it, so nothing may touch the page after the event is spawned.
      if IsDefined(this.m_owner) {
        this.m_owner.CBSpawnMenuEvent(CBModSettingsEvent());
      }
      return true;
    }
    return false;
  }

  protected cb func CBOnHoverOver(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) {
      return false;
    }
    let target = e.GetCurrentTarget();
    if IsDefined(target) {
      this.m_hover = target.GetName();
      this.Paint();
    }
    return false;
  }

  protected cb func CBOnHoverOut(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) {
      return false;
    }
    let target = e.GetCurrentTarget();
    if IsDefined(target) && Equals(target.GetName(), this.m_hover) {
      this.m_hover = n"";
      this.Paint();
    }
    return false;
  }

  // The previous/next tab keys, the same actions the settings menu uses (settingsMain.script:1311).
  protected cb func CBOnGlobalRelease(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) || e.IsHandled() {
      return false;
    }
    let step = 0;
    if e.IsAction(n"prior_menu") {
      step = -1;
    } else {
      if e.IsAction(n"next_menu") {
        step = 1;
      }
    }
    if step == 0 {
      return false;
    }
    let game = GetGameInstance();
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) {
      return false;
    }
    let tab = this.m_tab + step;
    if tab < 1 {
      tab = CBHudTabCount();
    }
    if tab > CBHudTabCount() {
      tab = 1;
    }
    e.Handle();
    this.Click();
    this.SelectTab(sys, game, tab);
    return true;
  }

  private func SelectTab(sys: ref<CyberbaneSystem>, game: GameInstance, tab: Int32) -> Void {
    this.m_tab = CBHudClampTab(tab);
    sys.SetHubTab(this.m_tab);
    this.m_purgeArmed = false;
    this.m_resetArmed = false;
    this.m_hover = n"";
    this.Render(sys, game);
  }

  private func RowClicked(sys: ref<CyberbaneSystem>, game: GameInstance, row: Int32) -> Void {
    if this.m_tab == CBHudFactionsTab() {
      let f = this.m_rowFaction[row];
      // Clicking the one already open closes it again.
      this.m_pickFaction = Equals(f, this.m_pickFaction) ? n"" : f;
    } else {
      if this.m_tab == CBHudRivalsTab() {
        this.m_pickRival = this.m_rowRival[row];
        this.m_purgeArmed = false;
        this.m_resetArmed = false;
      } else {
        if this.m_tab == CBHudTitlesTab() {
          // A value in a field; safe to set at once, paused or not. n"" is automatic.
          sys.SetActiveTitle(this.m_rowTitle[row]);
          CBLog.Info(n"UI", s"Title chosen on the Hub: \(NameToString(sys.GetChosenTitle())).");
        }
      }
    }
    this.Render(sys, game);
  }

  // The button beside the detail panel. Neither action is carried out from here: the game is
  // paused, and both touch the world. They are recorded, and done on the first settled tick after
  // the menu closes. Clicking again before then takes the request back.
  private func ActionClicked(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if this.m_tab == CBHudFactionsTab() {
      if NotEquals(this.m_pickFaction, n"") {
        if Equals(sys.GetPendingPeace(), this.m_pickFaction) {
          sys.RequestPeace(n"");
        } else {
          if CBHudCanPayOff(sys, game, this.m_pickFaction) {
            sys.RequestPeace(this.m_pickFaction);
          }
        }
      }
    } else {
      if this.m_tab == CBHudHistoryTab() {
        if this.m_resetArmed {
          this.m_resetArmed = false;
          // For this playthrough and no other, and on record at once (CyberbaneSystem,
          // RequestStartOver): loading another save from here cannot be wiped by it, and an
          // older save of this playthrough is started over too when it next loads.
          sys.RequestStartOver();
          CBLog.Info(n"UI", "Start over chosen on the Hub; the next tick back in the game wipes this playthrough's Cyberbane data.");
        } else {
          this.m_resetArmed = true;
        }
      } else {
      if this.m_tab == CBHudRivalsTab() {
        if sys.IsRivalPurgePending() {
          sys.RequestRivalPurge(false);
          this.m_purgeArmed = false;
          this.m_resetArmed = false;
        } else {
          if this.m_purgeArmed {
            sys.RequestRivalPurge(true);
            this.m_purgeArmed = false;
            this.m_resetArmed = false;
          } else {
            this.m_purgeArmed = true;
          }
        }
      }
      }
    }
    this.Render(sys, game);
  }

  // ---- Painting --------------------------------------------------------------------------------

  // Recolour everything that reacts to the cursor or to being chosen. Cheap: a tint per widget.
  private func Paint() -> Void {
    let i = 0;
    while i < ArraySize(this.m_tabBox) {
      let on = (i + 1) == this.m_tab;
      let hot = Equals(this.m_tabNames[i], this.m_hover);
      if IsDefined(this.m_tabBg[i]) {
        this.m_tabBg[i].SetTintColor(on ? CBHudBandPicked() : (hot ? CBHudBandHover() : CBHudClear()));
      }
      if IsDefined(this.m_tabText[i]) {
        this.m_tabText[i].SetTintColor((on || hot) ? CBHudHead() : CBHudLabel());
      }
      if IsDefined(this.m_tabUnder[i]) {
        this.m_tabUnder[i].SetTintColor(on ? CBHudHead() : CBHudClear());
      }
      i += 1;
    }
    let r = 0;
    while r < ArraySize(this.m_rowBg) {
      if IsDefined(this.m_rowBg[r]) {
        let band = r % 2 == 0 ? CBHudBandEven() : CBHudBandOdd();
        if this.m_rowClickable[r] && Equals(this.m_rowNames[r], this.m_hover) {
          band = CBHudBandHover();
        }
        if this.m_rowPicked[r] {
          band = CBHudBandPicked();
        }
        this.m_rowBg[r].SetTintColor(band);
      }
      r += 1;
    }
    if IsDefined(this.m_actionBg) {
      let tint = CBHudButtonOff();
      if this.m_actionOn {
        tint = Equals(this.m_hover, CBHudActionName()) ? CBHudButtonHover() : CBHudButtonIdle();
      }
      this.m_actionBg.SetTintColor(tint);
    }
    if IsDefined(this.m_actionText) {
      this.m_actionText.SetTintColor(this.m_actionOn ? CBHudHead() : CBHudDim());
    }
    if IsDefined(this.m_settingsBg) {
      this.m_settingsBg.SetTintColor(Equals(this.m_hover, CBHudSettingsName()) ? CBHudButtonHover() : CBHudButtonIdle());
    }
  }

  private func SetAction(label: String, enabled: Bool) -> Void {
    this.m_actionOn = enabled;
    if IsDefined(this.m_actionText) {
      this.m_actionText.SetText(label);
    }
    if IsDefined(this.m_actionBox) {
      this.m_actionBox.SetVisible(StrLen(label) > 0);
    }
  }

  // ---- Widget helpers. Every one checks the handle first, so a widget that failed to build can
  // never take the page (or the game) down with it. -------------------------------------------

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
    while i < ArraySize(this.m_rowBox) {
      if IsDefined(this.m_rowBox[i]) {
        this.m_rowBox[i].SetVisible(false);
      }
      this.m_rowShown[i] = false;
      this.m_rowClickable[i] = false;
      this.m_rowPicked[i] = false;
      this.m_rowFaction[i] = n"";
      this.m_rowRival[i] = 0;
      this.m_rowTitle[i] = n"";
      i += 1;
    }
  }

  // Move the rows and their cells to where the screen about to be drawn needs them. Only touches
  // them when the layout has changed, so changing screen is not re-laying out every cell.
  private func PlaceRows(layout: Int32) -> Void {
    if this.m_rowPlaced && this.m_rowLayout == layout {
      return;
    }
    let titles = layout == CBHudLayoutTitles();
    let stride = titles ? CBHudTitleRowHeight() : CBHudRowHeight();
    let rowW = titles ? CBHudTitleListW() : CBHudContentW();
    let rowH = stride - 4.0;
    let textY = titles ? 0.0 : 5.0;
    let r = 0;
    while r < ArraySize(this.m_rowBox) {
      if IsDefined(this.m_rowBox[r]) {
        this.m_rowBox[r].SetMargin(new inkMargin(CBHudMarginX(), CBHudContentTop() + Cast<Float>(r) * stride, 0.0, 0.0));
        this.m_rowBox[r].SetSize(new Vector2(rowW, rowH));
      }
      if IsDefined(this.m_rowPip[r]) {
        this.m_rowPip[r].SetSize(new Vector2(5.0, rowH - 12.0));
        this.m_rowPip[r].SetMargin(new inkMargin(0.0, 6.0, 0.0, 0.0));
      }
      let c = 0;
      while c < CBHudRowCols() {
        let idx = r * CBHudRowCols() + c;
        if idx < ArraySize(this.m_rowCell) && IsDefined(this.m_rowCell[idx]) {
          if c == CBHudRowCols() - 1 {
            this.m_rowCell[idx].SetSize(new Vector2(rowW - 16.0, 28.0));
            this.m_rowCell[idx].SetMargin(new inkMargin(0.0, textY + 2.0, 0.0, 0.0));
          } else {
            this.m_rowCell[idx].SetMargin(new inkMargin(CBHudRowColX(c, layout), textY + (c == 0 ? 0.0 : 2.0), 0.0, 0.0));
          }
        }
        c += 1;
      }
      r += 1;
    }
    this.m_rowLayout = layout;
    this.m_rowPlaced = true;
  }

  // Conduct runs -100 to +100, so it is drawn from the middle: left of centre in red as V slides
  // towards cyberpsycho, right of centre in green as they stay clean.
  private func SetBipolarBar(idx: Int32, label: String, value: String, signed: Float,
                             col: HDRColor, caption: String) -> Void {
    this.SetBar(idx, label, value, 0.0, col, caption);
    if idx < 0 || idx >= ArraySize(this.m_barFill) || !IsDefined(this.m_barFill[idx]) {
      return;
    }
    let half = CBHudBarWidth() * 0.5;
    let reach = ClampF(AbsF(signed) / 100.0, 0.0, 1.0) * half;
    if reach < 2.0 {
      reach = 2.0;
    }
    let left = signed < 0.0 ? half - reach : half;
    this.m_barFill[idx].SetSize(new Vector2(reach, 10.0));
    this.m_barFill[idx].SetMargin(
      new inkMargin(CBHudMarginX() + left, CBHudContentTop() + Cast<Float>(idx) * 96.0 + 36.0, 0.0, 0.0));
    this.m_barFill[idx].SetTintColor(col);
    this.m_barFill[idx].SetVisible(true);
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
      // Back to the left edge: SetBipolarBar moves this same widget to the middle.
      this.m_barFill[idx].SetMargin(
        new inkMargin(CBHudMarginX(), CBHudContentTop() + Cast<Float>(idx) * 96.0 + 36.0, 0.0, 0.0));
      this.m_barFill[idx].SetSize(new Vector2(w, 10.0));
      this.m_barFill[idx].SetTintColor(col);
      this.m_barFill[idx].SetVisible(true);
    }
    if IsDefined(this.m_barCap[idx]) {
      this.m_barCap[idx].SetText(caption);
      this.m_barCap[idx].SetVisible(true);
    }
  }

  // One row, six fields, and what it stands for. Anything handed an empty string stays hidden, so
  // a screen that has nothing for a column does not leave the last screen's value sitting there.
  private func SetRow(idx: Int32, layout: Int32, pip: HDRColor, clickable: Bool, picked: Bool,
                      a: String, b: String, c: String, d: String, e: String, f: String) -> Void {
    if idx < 0 || idx >= ArraySize(this.m_rowBox) {
      return;
    }
    this.m_rowShown[idx] = true;
    this.m_rowClickable[idx] = clickable;
    this.m_rowPicked[idx] = picked;
    if IsDefined(this.m_rowBox[idx]) {
      this.m_rowBox[idx].SetVisible(true);
    }
    if IsDefined(this.m_rowPip[idx]) {
      this.m_rowPip[idx].SetTintColor(pip);
    }
    let col = 0;
    while col < CBHudRowCols() {
      let cellIdx = idx * CBHudRowCols() + col;
      if cellIdx < ArraySize(this.m_rowCell) && IsDefined(this.m_rowCell[cellIdx]) {
        let text = a;
        if col == 1 { text = b; }
        if col == 2 { text = c; }
        if col == 3 { text = d; }
        if col == 4 { text = e; }
        if col == 5 { text = f; }
        let budget = CBHudRowColChars(col, layout);
        if StrLen(text) == 0 || budget <= 0 {
          this.m_rowCell[cellIdx].SetVisible(false);
        } else {
          this.m_rowCell[cellIdx].SetText(CBHudTrim(text, budget));
          this.m_rowCell[cellIdx].SetVisible(true);
        }
      }
      col += 1;
    }
  }

  // Where the prose goes on this screen, how wide it may run, and what it says.
  private func SetBody(x: Float, y: Float, width: Float, text: String, maxLines: Int32) -> Void {
    if !IsDefined(this.m_body) {
      return;
    }
    this.m_body.SetMargin(new inkMargin(x, y, 0.0, 0.0));
    this.m_body.SetWrapping(true, width);
    this.m_body.SetSize(new Vector2(width, CBHudFooterY() - 30.0 - y));
    this.m_body.SetText(CBHudClamp(text, maxLines));
  }

  // ---- Screens ---------------------------------------------------------------------------------

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

    // The number is Dread; the word is what the street does with it. The second figure is what
    // the street actually reads, which is not the same number and never was - it belongs in the
    // sentence that explains it rather than loose beside the first.
    let civ = score.GetDreadCiv();
    this.SetBar(1, "Dread", s"\(RoundF(dread))   \(CBDreadWord(civ))",
      dread / 100.0, CBHudRed(),
      s"How frightening you are. The street reads it as \(RoundF(civ)), and that is the figure that makes people back off.");

    this.SetBar(2, "Visible chrome", s"\(RoundF(chrome))",
      chrome / 100.0, CBHudAmber(),
      "What a stranger clocks from across the street. Arms read loudest.");

    this.SetBipolarBar(3, "Conduct", s"\(RoundF(code))   \(CBCodeLabel(code))",
      code, code < 0.0 ? CBHudRed() : CBHudGreen(),
      "Clean and controlled, or one bad night from going over. This one runs both ways from the middle.");
  }

  // The gangs, the ones that want you dead first.
  //
  // The list holds ten. Taken in storage order, a hostile gang past the tenth row was simply not
  // there, and with buying peace now done by clicking a row, a gang that is not on screen is a gang
  // you cannot pay off. So the hostile and the sworn go in first and everybody else fills the rest.
  private func RenderFactions(sys: ref<CyberbaneSystem>) -> Void {
    this.PlaceRows(CBHudLayoutGangs());
    let score = sys.GetScore();
    if !IsDefined(score) {
      return;
    }
    let states = sys.GetFactionStates();
    let shown = 0;
    let sweep = 0;
    let pickedShown = false;
    while sweep < 2 {
      let i = 0;
      while i < ArraySize(states) && shown < CBHudListRows() {
        let fs = states[i];
        i += 1;
        if IsDefined(fs) {
          let posture = score.GetPosture(fs.id);
          let hostile = Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta);
          if (sweep == 0 && hostile) || (sweep == 1 && !hostile) {
            let picked = Equals(fs.id, this.m_pickFaction);
            if picked {
              pickedShown = true;
            }
            this.RenderFactionRow(sys, score, fs, posture, shown, picked);
            shown += 1;
          }
        }
      }
      sweep += 1;
    }
    // A pick that is no longer on the list (reset, or pushed off by new gangs) is no pick.
    if !pickedShown {
      this.m_pickFaction = n"";
    }
  }

  private func RenderFactionRow(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>, fs: ref<CBFactionState>,
                                posture: ECBPosture, row: Int32, picked: Bool) -> Void {
    let pip = CBHudGrey();
    if Equals(posture, ECBPosture.Vendetta) { pip = CBHudRed(); }
    if Equals(posture, ECBPosture.Hostile) { pip = CBHudAmber(); }
    if Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied) { pip = CBHudGreen(); }
    let right = CBHudGangStatus(sys, fs);
    if Equals(sys.GetPendingPeace(), fs.id) {
      right = "PAYING OFF ON RESUME";
    }
    // Who this gang is at war with, because that is the one thing on this screen V can act on:
    // hurting a gang warms the gangs that hate it (Model/GangRivalries.reds).
    let enemy = CBFactionLabel(CBTopEnemyOf(sys, sys.GetContent(), fs.id));
    this.SetRow(row, CBHudLayoutGangs(), pip, true, picked,
      CBFactionLabel(fs.id),
      CBPostureName(posture),
      s"fear \(RoundF(score.GetFactionFear(fs.id)))",
      StrLen(enemy) > 0 ? "at war: " + enemy : "",
      s"\(fs.kills) down",
      right);
    this.m_rowFaction[row] = fs.id;
  }

  // The panel under the gangs: the one you clicked, and the button to buy them off.
  private func RenderFactionDetail(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let top = CBHudContentTop() + Cast<Float>(CBHudListRows()) * CBHudRowHeight() + 24.0;
    let width = CBHudContentW() - CBHudActionW() - 40.0;
    if Equals(this.m_pickFaction, n"") {
      this.SetAction("", false);
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), CBHudFactions(sys), CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let id = this.m_pickFaction;
    let fs = sys.FindFaction(id);
    let score = sys.GetScore();
    if !IsDefined(fs) || !IsDefined(score) {
      this.m_pickFaction = n"";
      this.SetAction("", false);
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), CBHudFactions(sys), CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let posture = score.GetPosture(id);
    let gang = CBFactionLabel(id);
    let out = StrUpper(gang) + "   " + CBPostureName(posture) + "\n";
    let enemy = CBFactionLabel(CBTopEnemyOf(sys, sys.GetContent(), id));
    if StrLen(enemy) > 0 {
      out += "At war with " + enemy + ". Hurting " + enemy + " is how this gang comes to like you.\n";
    }
    out += s"\(fs.kills) of theirs down. They fear you at \(RoundF(score.GetFactionFear(id))) of 100.\n";
    let status = CBHudGangStatus(sys, fs);
    if StrLen(status) > 0 {
      out += "Right now: " + StrLower(status) + ".\n";
    }
    out += "\n";
    let quote = CBPeaceQuote(sys, game, id);
    let money = CBHudEddies(game);
    if Equals(sys.GetPendingPeace(), id) {
      let price = quote >= 0 ? s"\(quote)eb" : "what they ask";
      out += "You are paying them " + price + ". It goes through a few seconds after you are back in the game,\nand anything they had on its way to you is called off.";
      this.SetAction("Cancel the payment", true);
    } else {
      if quote >= 0 {
        out += s"They will call it off for \(quote)eb. You have \(money)eb.";
        if money >= quote {
          this.SetAction(s"Pay them off: \(quote)eb", true);
        } else {
          this.SetAction("Not enough eddies", false);
        }
      } else {
        out += CBHudWhyNoPeace(game, id, posture);
        this.SetAction("", false);
      }
    }
    this.SetBody(CBHudMarginX(), top, width, out, CBHudMaxLinesFor(this.m_tab));
  }

  // The City, as a list rather than a paragraph: a name and three numbers per district, with the
  // renown bar giving the shape of where V is known at a glance.
  private func RenderCity(sys: ref<CyberbaneSystem>) -> Void {
    this.PlaceRows(CBHudLayoutWide());
    let states = sys.GetDistrictStates();
    let now = CBGameSeconds(sys.GetGameInstance());
    let shown = 0;
    let i = 0;
    while i < ArraySize(states) && shown < CBHudListRows() {
      let d = states[i];
      i += 1;
      if IsDefined(d) {
        let dname = CBDistrictLabel(d.id);
        if StrLen(dname) == 0 {
          dname = NameToString(d.id);
        }
        let rd = RoundF(d.renown);
        let quiet = CBHudSince(now, d.lastIncidentAt);
        let pip = CBHudGrey();
        if rd >= 75 {
          pip = CBHudRed();
        } else {
          if rd >= 40 {
            pip = CBHudAmber();
          } else {
            if rd >= 15 {
              pip = CBHudCyan();
            }
          }
        }
        this.SetRow(shown, CBHudLayoutWide(), pip, false, false,
          dname,
          CBHudMeter(d.renown, 100.0, 10),
          s"\(rd)",
          s"\(d.kills) down",
          "",
          StrLen(quiet) > 0 ? "quiet " + quiet : "nothing yet");
        shown += 1;
      }
    }
  }

  // Who holds each district (Model/Territory.reds). One row a district: the gang that holds it,
  // a bar for how much of it they hold, and one word or two for what is going on there. Nothing on
  // it is clickable, because there is nothing to do here but read it. Returns how many rows it drew.
  private func RenderTurf(sys: ref<CyberbaneSystem>, game: GameInstance) -> Int32 {
    this.PlaceRows(CBHudLayoutWide());
    let shown = 0;
    if !CBTurfWarsOn() {
      return shown;
    }
    let score = sys.GetScore();
    let content = sys.GetContent();
    let i = 0;
    while i < CBDistrictCount() && shown < CBHudListRows() {
      let district = CBDistrictAt(i);
      i += 1;
      let ids: array<CName>;
      let shares: array<Float>;
      CBTurfShares(sys, game, district, ids, shares);
      if ArraySize(ids) > 0 {
        let top = 0;
        let k = 1;
        while k < ArraySize(ids) {
          if shares[k] > shares[top] {
            top = k;
          }
          k += 1;
        }
        let second = -1;
        k = 0;
        while k < ArraySize(ids) {
          if k != top && (second < 0 || shares[k] > shares[second]) {
            second = k;
          }
          k += 1;
        }
        let holder = ids[top];
        let status = CBHudTurfStatus(content, district, holder, ids, shares, second);
        let pip = CBHudGrey();
        if IsDefined(score) {
          let posture = score.GetPosture(holder);
          if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
            pip = CBHudRed();
          } else {
            if Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied) {
              pip = CBHudGreen();
            }
          }
        }
        let place = CBDistrictLabel(district);
        if StrLen(place) == 0 {
          place = NameToString(district);
        }
        this.SetRow(shown, CBHudLayoutWide(), pip, false, false,
          place,
          CBHudMeter(shares[top], 1.0, 12),
          s"\(RoundF(shares[top] * 100.0))%",
          CBBarFactionLabel(holder),
          "",
          status);
        shown += 1;
      }
    }
    return shown;
  }

  private func RenderRivals(sys: ref<CyberbaneSystem>) -> Void {
    this.PlaceRows(CBHudLayoutWide());
    let content = sys.GetContent();
    let rivals = sys.GetRivals();
    let shown = 0;
    let pickedShown = false;

    // The one who is actually coming goes first, so the name the Standing screen gives as incoming
    // is always on this screen, whatever the cap is.
    let queuedId = sys.GetLaneRivalId(CBLaneRival());
    let pinned = sys.FindRivalById(queuedId);
    if IsDefined(pinned) && (pinned.state == EnumInt(ECBRivalState.Active)
                             || pinned.state == EnumInt(ECBRivalState.Hunting)) {
      if this.m_pickRival == 0 {
        this.m_pickRival = pinned.id;   // open on whoever is next
      }
      if pinned.id == this.m_pickRival {
        pickedShown = true;
      }
      this.RenderRivalRow(sys, content, pinned, shown);
      shown += 1;
    } else {
      queuedId = 0;
    }

    let i = 0;
    while i < ArraySize(rivals) && shown < CBHudListRows() {
      let r = rivals[i];
      i += 1;
      // Skipping the pinned one by id rather than by `continue`, which redscript does not have.
      if IsDefined(r) && r.id != queuedId
         && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        if this.m_pickRival == 0 {
          this.m_pickRival = r.id;
        }
        if r.id == this.m_pickRival {
          pickedShown = true;
        }
        this.RenderRivalRow(sys, content, r, shown);
        shown += 1;
      }
    }
    // The one that was picked is gone (put down, forgotten): fall back to the top of the list,
    // which is whoever is next, rather than leaving the panel under the list empty.
    if !pickedShown {
      this.m_pickRival = shown > 0 ? this.m_rowRival[0] : 0;
      if shown > 0 {
        this.m_rowPicked[0] = true;
      }
    }
  }

  // One Rival's line. Pulled out of the loop so the Rival who is actually on their way can be
  // drawn first without duplicating any of this.
  private func RenderRivalRow(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>,
                              r: ref<CBRival>, row: Int32) -> Void {
    // Standing in front of you, not merely carrying a grudge: ask the world, not the state, which
    // is set when a Rival starts hunting and never cleared afterwards.
    let body = GameInstance.FindEntityByID(sys.GetGameInstance(), r.spawnedEntityId) as ScriptedPuppet;
    let hunting = EntityID.IsDefined(r.spawnedEntityId) && CBStillStanding(body);
    let role = CBRoleShort(CBRivalRole(sys, r));
    let gang = CBFactionLabel(r.faction);
    if Equals(role, "") {
      role = s"rank \(r.rank)";
    }
    // Only one Rival is ever on the clock, so only that one shows a countdown.
    let onClock = r.id == sys.GetLaneRivalId(CBLaneRival());
    let rightCol = "waiting their turn";
    if hunting {
      rightCol = "here now";
      // Not after V: standing where they were seen, for V to come to (Rivals/Whereabouts.reds).
      if sys.IsLairActive() && sys.GetLairRivalId() == r.id {
        rightCol = "at their place";
      }
    } else {
      if onClock && sys.GetLaneTicks(CBLaneRival()) > 0 {
        rightCol = "arrives " + CBWhen(sys.GetLaneTicks(CBLaneRival()));
      } else {
        if onClock {
          rightCol = "any moment";
        } else {
          if StrLen(this.m_holdLabel) > 0 {
            rightCol = this.m_holdLabel;
          }
          let lead = CBCurrentLead(sys, sys.GetGameInstance());
          if IsDefined(lead) && lead.rivalId == r.id {
            rightCol = "you know where";
          }
        }
      }
    }
    // What makes this one different, in the space a column has: their first trait, or the mark V
    // left on them if they have none.
    let marks = CBRivalTraitList(content, r, false, 1);
    if StrLen(marks) == 0 {
      marks = CBScarLabel(r.scarMask);
    }
    this.SetRow(row, CBHudLayoutWide(), hunting ? CBHudRed() : CBHudAmber(), true, r.id == this.m_pickRival,
      IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival",
      gang,
      role,
      marks,
      "",
      rightCol);
    this.m_rowRival[row] = r.id;
  }

  // The panel under the Rivals: the file on the one you clicked, and the button that forgets them.
  private func RenderRivalDetail(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let top = CBHudContentTop() + Cast<Float>(CBHudListRows()) * CBHudRowHeight() + 24.0;
    let width = CBHudContentW() - CBHudActionW() - 40.0;
    let count = sys.CountActiveRivals();
    if count <= 0 && !sys.IsRivalPurgePending() {
      this.SetAction("", false);
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), CBHudRivals(sys, game, 0), CBHudMaxLinesFor(this.m_tab));
      return;
    }
    if sys.IsRivalPurgePending() {
      this.SetAction("Keep them", true);
    } else {
      if this.m_purgeArmed {
        this.SetAction(s"Click again: forget all \(count)", true);
      } else {
        this.SetAction("Forget every rival", true);
      }
    }
    this.SetBody(CBHudMarginX(), top, width, CBHudRivals(sys, game, this.m_pickRival), CBHudMaxLinesFor(this.m_tab));
  }

  // The titles, as a list you can click. Automatic first, then every one V has earned - all of
  // them: this screen used to show the first eight and say nothing about the rest.
  private func RenderTitles(sys: ref<CyberbaneSystem>) -> Void {
    this.PlaceRows(CBHudLayoutTitles());
    let content = sys.GetContent();
    let chosen = sys.GetChosenTitle();
    let unlocked = sys.GetUnlockedTitles();
    let onAuto = Equals(chosen, n"");
    let autoLabel = ArraySize(unlocked) > 0 ? "Automatic: " + CBHudActiveTitle(sys) : "Automatic";
    this.SetRow(0, CBHudLayoutTitles(), onAuto ? CBHudCyan() : CBHudGrey(), ArraySize(unlocked) > 0, onAuto,
      autoLabel, "", "", "", "", onAuto ? "GOING BY" : "");
    this.m_rowTitle[0] = n"";
    let i = 0;
    while i < ArraySize(unlocked) && i + 1 < CBHudRowPool() {
      let id = unlocked[i];
      let mine = Equals(id, chosen);
      this.SetRow(i + 1, CBHudLayoutTitles(), mine ? CBHudCyan() : CBHudAmber(), true, mine,
        CBTitleDisplayById(sys, content, id), "", "", "", "", mine ? "GOING BY" : "");
      this.m_rowTitle[i + 1] = id;
      i += 1;
    }
  }

  private func Render(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if !IsDefined(this.m_root) || !this.m_open {
      return;
    }
    let score = sys.GetScore();
    let titleName = CBHudActiveTitle(sys);
    let tier = IsDefined(score) ? CBTierName(EnumInt(score.GetTier())) : "Nobody";
    if IsDefined(this.m_subhead) {
      this.m_subhead.SetText(titleName + "   |   " + tier);
    }
    if IsDefined(this.m_tabline) {
      this.m_tabline.SetText(CBHudTabBlurb(this.m_tab));
    }

    this.HideBars();
    this.HideRows();
    this.SetAction("", false);

    // Each screen decides what it is: meters, a list, or prose. The prose sits under or beside
    // whatever the screen drew, rather than being the whole screen.
    let x = CBHudMarginX();
    let w = CBHudContentW();
    let maxLines = CBHudMaxLinesFor(this.m_tab);
    let listBottom = CBHudContentTop() + Cast<Float>(CBHudListRows()) * CBHudRowHeight() + 24.0;
    if this.m_tab == CBHudStandingTab() {
      this.RenderScores(sys);
      this.SetBody(x, CBHudContentTop() + Cast<Float>(CBHudBarCount()) * 96.0 + 20.0, w,
                   CBHudLegend(sys, game), maxLines);
    } else {
      if this.m_tab == CBHudFactionsTab() {
        this.RenderFactions(sys);
        this.RenderFactionDetail(sys, game);
      } else {
        if this.m_tab == CBHudTurfTab() {
          let turfRows = this.RenderTurf(sys, game);
          // Straight under the last district rather than under ten rows' worth of empty space.
          let turfTop = CBHudContentTop() + Cast<Float>(Max(turfRows, 1)) * CBHudRowHeight() + 24.0;
          this.SetBody(x, turfTop, w, CBHudTurfBody(sys), maxLines);
        } else {
          if this.m_tab == CBHudCityTab() {
            this.RenderCity(sys);
            this.SetBody(x, listBottom, w, CBHudDistricts(sys), maxLines);
          } else {
            if this.m_tab == CBHudRivalsTab() {
              this.m_holdLabel = CBHoldLabel(sys.GetHuntHoldReason());
              // An arrival that was actually attempted and refused is more specific than the hold.
              let blocked = CBBlockLabel(CBLastSpawnBlock());
              if StrLen(blocked) > 0 && sys.GetHuntHoldReason() == CBHoldNoRoom() {
                this.m_holdLabel = blocked;
              }
              this.RenderRivals(sys);
              this.RenderRivalDetail(sys, game);
            } else {
              if this.m_tab == CBHudTitlesTab() {
                this.RenderTitles(sys);
                let colX = x + CBHudTitleListW() + 60.0;
                this.SetBody(colX, CBHudContentTop(), w - CBHudTitleListW() - 60.0, CBHudTitles(sys), maxLines);
              } else {
                // History is the ledger - everything V has accumulated - so starting over belongs
                // on it, rather than buried in Mod Settings where a player looking at what they
                // have built is not looking.
                //
                // The work is the switch that already exists: RequestHardReset, taken by the fast
                // tick (CyberbaneSystem, TakeHardResetRequest). That matters twice over - it
                // happens out of the paused menu like every other Hub action, and it is one code
                // path rather than a second wipe that could drift from the first.
                //
                // It clears what playing earned: reputation, gangs, districts, rumours, Rivals,
                // titles, deeds, the log. It deliberately leaves chrome, look, menace and aura,
                // because those are not stored progress - they are read back off V's cyberware,
                // clothes and build on every sample, so wiping them would mean nothing and they
                // would be back within the second.
                if this.m_resetArmed {
                  this.SetAction("Click again: erase everything", true);
                } else {
                  this.SetAction("Start over", true);
                }
                this.SetBody(x, CBHudContentTop(), w, CBHudLog(sys), maxLines);
              }
            }
          }
        }
      }
    }
    this.Paint();
    this.m_root.SetVisible(true);
  }
}

// ---- Things the gang screen says ----------------------------------------------------------------

// Most urgent thing this gang is doing. Anything actually on its way wins over a count of how far
// off the next thing is.
func CBHudGangStatus(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> String {
  if Equals(sys.GetPendingApexFaction(), fs.id) {
    return sys.IsPendingApexDriving() ? "APEX SQUAD DRIVING " + CBTimeText(sys.GetPendingApexTicks())
                                      : "APEX SQUAD " + CBWhen(sys.GetPendingApexTicks());
  }
  if Equals(sys.GetPendingSquadFaction(), fs.id) {
    if sys.GetPendingSquadTicks() <= 0 {
      let why = CBBlockLabel(CBLastSpawnBlock());
      return StrLen(why) > 0 ? "HELD: " + why : "CREW HELD UP";
    }
    return "CREW INBOUND " + CBTimeText(sys.GetPendingSquadTicks());
  }
  if Equals(sys.GetLaneTarget(CBLaneApex()), fs.id) {
    return "APEX SQUAD " + CBWhen(sys.GetLaneTicks(CBLaneApex()));
  }
  if Equals(sys.GetLaneTarget(CBLaneSquad()), fs.id) {
    return "CREW " + CBWhen(sys.GetLaneTicks(CBLaneSquad()));
  }
  return CBApexProgressLine(sys, fs);
}

// V's eddies. Read only: nothing here takes any.
func CBHudEddies(game: GameInstance) -> Int32 {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return 0;
  }
  return ts.GetItemQuantity(player, ItemID.FromTDBID(t"Items.money"));
}

// Whether the button may offer a payment: there is something to buy and V can afford it now.
func CBHudCanPayOff(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Bool {
  let quote = CBPeaceQuote(sys, game, faction);
  return quote >= 0 && CBHudEddies(game) >= quote;
}

// Why there is no price on this gang, in the same terms CBPeaceQuote decides it.
func CBHudWhyNoPeace(game: GameInstance, id: CName, posture: ECBPosture) -> String {
  let content = CBContent(game);
  if IsDefined(content) {
    let prof = content.GetFaction(id);
    if IsDefined(prof) && !prof.canBeBought {
      return "Nobody here takes money to forget you. Corporations and the law cannot be bought off.";
    }
  }
  if Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied) {
    return "They like you. Friendly gangs cut their prices on their own turf and warn you when their enemies come for you.";
  }
  return "They are not hostile, so there is nothing to pay them for.";
}

// ---- Tab content -----------------------------------------------------------

func CBHudActiveTitle(sys: ref<CyberbaneSystem>) -> String {
  // The title that is showing: the player's choice, else the best one earned. GetActiveTitle only
  // comes back empty when nothing has been earned at all.
  let id = sys.GetActiveTitle();
  if Equals(id, n"") {
    return "No title yet";
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


// What is on its way, in one place.
//
// Three lanes, three clocks, always shown together even when a lane is empty. Showing an idle
// lane as "nobody" is the point: silence used to be ambiguous - it could mean nothing was
// coming, or that something was coming and the clock had stalled, and those two looked
// identical. A line that says nobody is after you right now is information. A line that says
// held, and why, is information. A blank screen is not.
func CBHudIncoming(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let out = "On its way to you\n";
  out += "  " + CBHudLaneLine(sys, game, CBLaneRival(), "A rival    ") + "\n";
  out += "  " + CBHudLaneLine(sys, game, CBLaneSquad(), "A gang crew") + "\n";
  out += "  " + CBHudLaneLine(sys, game, CBLaneApex(), "An apex squad") + "\n";
  return out;
}

func CBHudLaneLine(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32, label: String) -> String {
  let who = "";
  if lane == CBLaneRival() {
    // Only name a Rival the Rivals screen would also list. This read the lane's id and printed
    // whoever it found, with no check on their state, so a Rival who had been spared or retired
    // after being queued was announced as incoming on one screen and absent from the other.
    let r = sys.FindRivalById(sys.GetLaneRivalId(lane));
    if IsDefined(r) && !CBRivalQueueable(sys, r.id) {
      r = null;
    }
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
  // Nothing queued. Say whether that is because the day's allowance is spent, rather than
  // leaving "nobody" to mean both "none due" and "none left", which look identical and are
  // the sort of silence that reads as the mod being broken.
  if StrLen(who) == 0 {
    if CBLaneDailyCap(lane) <= 0 {
      return label + "   off";
    }
    // When the day's timetable next has room for this kind, in the player's own minutes. The
    // schedule is kept in in-game hours because that is what the sectors are made of; nobody
    // reading a Hub wants to be told "in 3 game hours", so it is converted here.
    // Without a timetable there is no next window to name.
    if !Equals(CBPacing(), ECBPacing.Timetable) {
      if CBLaneBudgetLeft(sys, game, lane) <= 0 {
        return label + "   done for today" + CBHudBudgetTail(sys, game, lane);
      }
      if Equals(CBPacing(), ECBPacing.Reactive) && lane == CBLaneSquad() {
        return label + "   only if you give them a reason" + CBHudBudgetTail(sys, game, lane);
      }
      return label + "   no telling when" + CBHudBudgetTail(sys, game, lane);
    }
    let hrs = CBHoursUntilNextSlot(sys, game, lane);
    if hrs < 0.0 {
      return label + "   done for today" + CBHudBudgetTail(sys, game, lane);
    }
    // Due now but nothing queued means the timetable has room and nobody qualifies: no gang
    // has taken enough losses to send their best, or no Rival is off their cooldown. Saying
    // "next in 0s" was true and told the player nothing, and a zero that never counts down
    // reads as a stuck clock.
    if hrs <= 0.0 {
      // A lane that is due can still be resting: the gap after its last encounter runs on its
      // own clock and has nothing to do with who is on the books. Saying "nobody qualifies"
      // then is simply untrue, and it sent a player hunting for a bug in a Rival list that was
      // eleven names long and working perfectly.
      let rest = CBLaneRestLeft(sys, lane);
      if rest > 0 {
        return label + "   breather, " + CBTimeText(rest) + CBHudBudgetTail(sys, game, lane);
      }
      return label + "   due, nobody qualifies yet" + CBHudBudgetTail(sys, game, lane);
    }
    return label + "   next " + (CBShowCountdowns() ? "in " + CBHudRealFromGameHours(hrs) : "later today") + CBHudBudgetTail(sys, game, lane);
  }
  let ticks = sys.GetLaneTicks(lane);
  if ticks <= 0 {
    let why = CBBlockLabel(CBLastSpawnBlock());
    let tail = CBHudBudgetTail(sys, game, lane);
    return StrLen(why) > 0 ? label + "   " + who + "  held: " + why + tail
                           : label + "   " + who + "  any moment" + tail;
  }
  return label + "   " + who + "  " + CBTimeText(ticks) + CBHudBudgetTail(sys, game, lane);
}

// In-game hours as the real time they will actually take, using the clock rate measured at the
// start of the session. About 8.1 by default, so eight in-game hours is roughly an hour of
// play; a mod that slows the world clock brings the two closer together.
func CBHudRealFromGameHours(hrs: Float) -> String {
  let ratio = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.GetClockRatio() > 0.0 {
    ratio = rt.GetClockRatio();
  }
  let secs = hrs * 3600.0 / ratio;
  if secs >= 3600.0 {
    return s"\(RoundF(secs / 3600.0))h";
  }
  if secs >= 60.0 {
    return s"\(RoundF(secs / 60.0))m";
  }
  return s"\(RoundF(secs))s";
}

// "  (2 of 3 today)". Shown so the pacing is something the player can see rather than guess
// at: each kind has its own daily allowance and this is what is left of it.
func CBHudBudgetTail(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> String {
  let cap = CBLaneDailyCap(lane);
  if cap <= 0 {
    return "   (off)";
  }
  let sent = sys.LaneSentToday(lane, CBGameDay(game));
  return s"   (\(sent) of \(cap) today)";
}

func CBHudLegend(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  // The four scores are meters now, so this screen's text only carries what a meter cannot:
  // where you are, what the city has already sent, and what it is doing about you right now.
  // Two sentences rather than two rows of shouted key-value pairs.
  //
  // "STREET CRED 34      STYLE Blades      HERE Watson" is six words of label for three
  // values, in capitals, with no indication of what any of it means or why they are on the
  // same line. A player called the Hub cluttered and hard to understand, and lines like that
  // one are most of why: everything on screen had the same weight and none of it was a
  // sentence. The numbers have not changed; what they sit in has.
  // "fighting mostly with Butcher" was read by a player as fighting the Butchers - a gang.
  //
  // It never meant that: `style` is V's archetype, and Butcher is one of six (CBArchetypeName
  // below). "Fighting with" takes an opponent in English, so a style put there reads as a gang
  // on a screen whose other lines really are about gangs, and the title block overhead saying
  // "Butcher of City Center" makes it worse. This is the third time this collision has been
  // fixed in this file - see the notes on Operator and Disciplined below - and the lesson each
  // time is the same: do not put a style where a name is expected.
  //
  // Its own sentence now, with no preposition that can take an object, and no article to get
  // wrong ("a Butcher" against "an Operator").
  // What is left on this screen, and what went.
  //
  // Asked for directly: keep only what a player needs. The four meters above already say who V
  // is; under them belongs the one thing they cannot say, which is what is on its way. Everything
  // else here was either already on screen somewhere better or was a number with nothing to do:
  //
  //   - "You are in Heywood, street cred 50" - the district is on the HUD line during play now
  //     (CBDistrictStatusLine) and street cred is the game's own readout, two inches away in the
  //     same pause menu. Repeating both at the top of a reputation screen said nothing new.
  //   - "Your style is Butcher" - interesting once, not every time, and it is what the archetype
  //     meters and the titles already express. Gone from here; the archetype still drives titles.
  //   - "So far: 4 rivals put down, 8 apex enforcers killed, 833 jobs nobody could pin on you" -
  //     a lifetime ledger, which is what the History screen is for. Moved there rather than
  //     dropped, so nothing stops being counted.
  //
  // What stays: what is coming, why people are frightened, and what that does right now. Three
  // things a player can act on.
  let out = CBHudIncoming(sys, game) + "\n";
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
  // Say so before anything else, because a masked player reading "nobody backs off yet" would
  // reasonably conclude the mask had done nothing when it is doing all of it.
  if CBCrowdIgnoresPlayer(GetGameInstance()) {
    return s"Right now: your face is covered, so nobody can place you and nobody runs. (\(reg.Count()) tracked)";
  }
  let chromeVisible = score.GetChromeVisible();
  // The crowd's own number, from the crowd's own formula, including the intensity slider the
  // player set. Working it out separately here is what let this screen disagree with the street.
  let eff = CBCrowdFear(score, CBCivIntensity());
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
  let out = "Hostile gangs send crews. Vendetta means they also shoot on sight. Hostile and sworn gangs are listed first.\n\n";
  out += "To be thought well of: hurt the gang they are at war with, or put their people down\n";
  out += "without killing them and let their names walk. Friendly gangs cut their prices on\n";
  out += "their own turf and warn you when their enemies come for you.\n\n";
  out += "Click a gang to see more about them, and to pay off one that wants you dead.";
  return out;
}
func CBHudDistricts(sys: ref<CyberbaneSystem>) -> String {
  let states = sys.GetDistrictStates();
  if ArraySize(states) == 0 {
    return "Your name has not travelled to any district yet.";
  }
  // The districts themselves are drawn as rows (RenderCity). This is only the line that says
  // how to read them.
  return "Word spreads outward from where things happened, so you can be a legend in one "
       + "district and a nobody in the next. The bar is how widely your name carries there.";
}

// What is going on in a district, in as few words as will do, for the right-hand column of TURF.
func CBHudTurfStatus(content: ref<CyberbaneContent>, district: CName, holder: CName,
                     ids: array<CName>, shares: array<Float>, second: Int32) -> String {
  if !IsDefined(content) {
    return "";
  }
  let prof = content.GetFaction(holder);
  let home = IsDefined(prof) && ArrayContains(prof.turf, district);
  if second >= 0 && shares[second] >= CBConfig.TurfPresenceShare()
     && (CBGangsAreRivals(content, holder, ids[second]) || CBGangsAreRivals(content, ids[second], holder)) {
    return s"VS \(CBBarFactionLabel(ids[second])) \(RoundF(shares[second] * 100.0))%";
  }
  if !home {
    return "MOVED IN";
  }
  if second >= 0 && shares[second] >= CBConfig.TurfPresenceShare() {
    return "SHARED";
  }
  return "HELD";
}

// The few lines under the districts: which gangs V has hurt, and how badly. Only those, so a
// player who has hurt nobody reads one sentence instead of a table of full bars.
func CBHudTurfBody(sys: ref<CyberbaneSystem>) -> String {
  if !CBTurfWarsOn() {
    return "Turf wars are off in Mod Settings: every gang keeps its own streets whatever you do to it.";
  }
  let content = sys.GetContent();
  if !IsDefined(content) {
    return "";
  }
  // The weakest few, weakest first. A handful of gangs, so a pick-the-lowest pass is plenty.
  let picked: array<CName>;
  let out = "";
  let n = 0;
  while n < 4 {
    let best = n"";
    let bestS = 97.0;   // anything this close to full is not worth a line
    for prof in content.GetFactions() {
      if IsDefined(prof) && prof.isGang && ArraySize(prof.turf) > 0 && !ArrayContains(picked, prof.id) {
        let st = CBGangStrength(sys, prof.id);
        if st < bestS {
          best = prof.id;
          bestS = st;
        }
      }
    }
    if Equals(best, n"") {
      break;
    }
    ArrayPush(picked, best);
    out += s"\(CBBarFactionLabel(best))   \(CBHudMeter(bestS, 100.0, 10))   \(CBGangStrengthWord(bestS))" + "\n";
    n += 1;
  }
  if n == 0 {
    return "Every gang is at full strength. Hurt one and its grip on its streets slips; break one and the gang at war with it next door moves in.";
  }
  return out + "They rebuild while you leave them alone. Break one and the gang at war with it next door moves in.";
}

// A number as a short bar of blocks, for a list where a real widget would be ten more of them.
// Filled blocks then empty ones, so a column of these reads as a shape down the screen the way
// the meters on the first screen do.
public func CBHudMeter(value: Float, full: Float, cells: Int32) -> String {
  if cells <= 0 || full <= 0.0 {
    return "";
  }
  let on = RoundF(ClampF(value / full, 0.0, 1.0) * Cast<Float>(cells));
  let out = "";
  let i = 0;
  while i < cells {
    out += i < on ? "|" : ".";
    i += 1;
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

func CBHudRivals(sys: ref<CyberbaneSystem>, game: GameInstance, pickedId: Int32) -> String {
  if sys.IsRivalPurgePending() {
    return "Every rival is forgotten a few seconds after you are back in the game.\n\nThe ones out looking for you stop, and nobody on this list comes after you again.\nIt sticks: quitting now, or loading an older save of this playthrough, forgets them too.\nClick the button again to keep them after all.";
  }
  let count = sys.CountActiveRivals();
  if count <= 0 {
    return "No active rivals yet.\n\nLeave someone alive after you put them down, or let a wounded\nenemy get away, and one of them will come back with your name.";
  }
  let cap = CBRivalCap();
  let out = "";
  // The file on whoever was clicked, or on whoever is next when nobody was.
  //
  // The rows carry name, gang, rank, scars and a clock, and never once say what any of this is
  // about. CBRivalSourceLine is the single most interesting fact about a nemesis - that you spared
  // them, or that they put you down once - so it is the first line of the file.
  let r = sys.FindRivalById(pickedId);
  if IsDefined(r) {
    let content = sys.GetContent();
    out += StrUpper(CBRivalDisplayName(content, r)) + "\n";
    out += CBRivalSourceLine(r.source) + ", " + CBRivalStateName(r.state);
    if r.id == sys.GetLaneRivalId(CBLaneRival()) {
      out += ", and next in line";
    }
    out += ".\n";
    // Somebody told V where they were seen (Rivals/Whereabouts.reds).
    let lead = CBCurrentLead(sys, game);
    if IsDefined(lead) && lead.rivalId == r.id {
      let from = IsNameValid(lead.tipFaction) ? CBFactionLabel(lead.tipFaction) : "the street";
      let ago = CBHudSince(CBGameSeconds(game), lead.seenAt);
      let when = StrLen(ago) > 0 ? ", " + ago + " ago" : "";
      out += s"Word from \(from): seen \(CBPlacePhrase(lead.district))\(when). Go on foot and they may not see you coming.\n";
    }
    let strong = CBRivalTraitList(content, r, false, 6);
    let weak = CBRivalTraitList(content, r, true, 6);
    if StrLen(strong) > 0 {
      out += "Strengths: " + strong + ".\n";
    }
    if StrLen(weak) > 0 {
      out += "Weak spots: " + weak + ".\n";
    }
    let scars = CBScarLabel(r.scarMask);
    if StrLen(scars) > 0 {
      out += "Carries your mark: " + scars + ".\n";
    }
    out += "\n";
  }
  // A held arrival used to keep resetting its clock to a few seconds and never come, which read as
  // the Hub promising someone was seconds away over and over. Say what is happening.
  let held = CBStealthHoldReason(sys, game);
  if NotEquals(held, "") {
    out += held + "\n";
  }
  out += s"\(count) of a possible \(cap) are still looking for you. They come back a rank higher each time one escapes.";
  if count >= cap {
    out += "\nNobody new can take against you until you clear some, so the ones you have come faster.";
  }
  return out;
}
func CBHudTitles(sys: ref<CyberbaneSystem>) -> String {
  let content = sys.GetContent();
  let out = "";
  if Equals(sys.GetChosenTitle(), n"") {
    out += "On automatic: you go by the best title you have earned.\n\n";
  } else {
    out += "Click Automatic to go back to going by the best one you have earned.\n\n";
  }
  // The ones you have not got, with what each of them takes.
  //
  // A player reported that the titles were the least understandable part of the mod: they arrive
  // unannounced, and nothing anywhere said what they mean or how to go after one. A list of the
  // ones you do not have, each with the thing you would have to do, turns the whole system into
  // something you can aim at. Earned titles are the rows on the left.
  if IsDefined(content) {
    let shown = 0;
    out += "NOT YET\n";
    for def in content.GetTitles() {
      if IsDefined(def) && !sys.HasTitle(def.id) && shown < CBConfig.HudTitlesLockedShown() {
        let need = CBTitleRequirement(sys, def.id);
        if StrLen(need) > 0 {
          out += CBTitleDisplayById(sys, content, def.id) + "\n    " + need + "\n";
          shown += 1;
        }
      }
    }
    if shown == 0 {
      out += "Nothing left. You have all of them.\n";
    }
  }
  return out;
}

// "3d", "5h", "20m" - how long since something happened, for the screens that track it.
// Returns "" when it never has.
// How long since, in the player's seconds rather than the game's.
//
// These timestamps come off the world clock, which by default runs about eight times faster
// than real time, so "quiet 43m" meant roughly five minutes of actually playing. Every other
// number on this screen is a real-time countdown, and one game-clock figure sitting among them
// is worse than useless. The ratio is measured once a session rather than assumed, because a
// mod that changes the day length changes it: CP Chronology brings it to about 1.
//
// An earlier version dropped anything past a day because "quiet 3d" looked wrong. That hid the
// reading instead of converting it, which is the actual answer.
public func CBHudSince(now: Float, then: Float) -> String {
  if then <= 0.0 || now <= then {
    return "";
  }
  let ratio = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.GetClockRatio() > 0.0 {
    ratio = rt.GetClockRatio();
  }
  let secs = (now - then) / ratio;
  if secs >= 86400.0 {
    return s"\(RoundF(secs / 86400.0))d";
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
    // Moved off the Standing screen, where it was three lifetime numbers in the middle of a
    // screen about right now. This is the ledger; it belongs here.
    out += s"        rivals put down \(stats.rivalsSlain)      apex enforcers killed \(stats.apexKills)";
    out += s"      never pinned on you \(stats.unattributed)\n";
    let spent = CBHudPeaceSpend(sys);
    out += s"        tribute taken \(stats.tributeEddies)eb      paid out for peace \(spent)eb\n";
    // How V fights, in a word. It left the Standing screen with the rest of the lifetime numbers,
    // and it is still worth saying once - this is the screen that says things once.
    let style = CBArchetypeName(sys.GetPrimaryArchetypeIndex());
    if NotEquals(style, "Undefined") {
      out += s"        style \(style)\n";
    }
    out += "\n";
  }

  let shown = 0;
  let now = CBGameSeconds(sys.GetGameInstance());
  let i = n - 1;
  while i >= 0 && shown < 18 {
    let e = log[i];
    i -= 1;
    if IsDefined(e) {
      out += CBHudLogLine(sys, e, now) + "\n";
      shown += 1;
    }
  }
  return out;
}

// One entry as a sentence. This printed the entry's internal name and its raw number, so the
// file read "RivalCreated (CityCenter) 12", where 12 was a Rival's id.
func CBHudLogLine(sys: ref<CyberbaneSystem>, e: ref<CBLogEntry>, now: Float) -> String {
  let gang = CBFactionLabel(e.faction);
  let gangCap = StrLen(gang) > 0 ? StrUpper(StrMid(gang, 0, 1)) + StrMid(gang, 1, StrLen(gang) - 1) : "";
  let line = "";
  if Equals(e.kind, n"RivalCreated") {
    let r = sys.FindRivalById(RoundF(e.value));
    let who = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "Somebody";
    line = StrLen(gang) > 0 ? s"\(who) of \(gang) took it personally." : s"\(who) took it personally.";
  } else {
    if Equals(e.kind, n"RivalSlain") {
      line = StrLen(gang) > 0 ? s"You put down a rank \(RoundF(e.value)) rival from \(gang)."
                              : s"You put down a rank \(RoundF(e.value)) rival.";
    } else {
      if Equals(e.kind, n"RivalAmbushed") {
        line = StrLen(gang) > 0 ? s"You caught a rank \(RoundF(e.value)) rival from \(gang) where they were lying low. They never saw you."
                                : s"You caught a rank \(RoundF(e.value)) rival where they were lying low. They never saw you.";
      } else {
      if Equals(e.kind, n"Deed") {
        line = "A job of yours made the rounds.";
      } else {
        if Equals(e.kind, n"Massacre") {
          line = s"People are still talking about the \(RoundF(e.value)) you left behind.";
        } else {
          if Equals(e.kind, n"BossKill") {
            line = StrLen(gang) > 0 ? s"You took down somebody who mattered to \(gang)." : "You took down somebody who mattered.";
          } else {
            if Equals(e.kind, n"ApexDown") {
              line = StrLen(gang) > 0 ? s"You put down one of \(gang)'s apex squad." : "You put down one of an apex squad.";
            } else {
              if Equals(e.kind, n"Vendetta") {
                line = s"\(gangCap) swore a vendetta against you.";
              } else {
                if Equals(e.kind, n"Peace") {
                  line = s"You paid \(gang) \(RoundF(e.value))eb to call it off.";
                } else {
                  if Equals(e.kind, n"Tribute") {
                    line = s"\(gangCap) paid you \(RoundF(e.value))eb to stay on your good side.";
                  } else {
                    if Equals(e.kind, n"Death") {
                      line = StrLen(gang) > 0 ? s"\(gangCap) put you down." : "Somebody put you down.";
                    } else {
                      if Equals(e.kind, n"Friendly") {
                        line = s"\(gangCap) decided you are all right.";
                      } else {
                        if Equals(e.kind, n"Allied") {
                          line = s"\(gangCap) started treating you like one of their own.";
                        } else {
                          if Equals(e.kind, n"TurfTaken") {
                            line = s"\(gangCap) took over the streets.";
                          } else {
                            line = NameToString(e.kind);
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      }
    }
  }
  let place = CBDistrictLabel(e.district);
  if StrLen(place) > 0 {
    line += "  " + place;
  }
  let ago = CBHudSince(now, e.at);
  if StrLen(ago) > 0 {
    line += ", " + ago + " ago";
  }
  return line;
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

// ---- Small label helpers ---------------------------------------------------

// What the street actually does at this much Dread, in a word.
//
// The four meters are read as a column and three of them said "number, then a word" - 700
// Infamous, -99 Cyberpsycho, and chrome with no word at all. Dread said "70   the street reads
// 84": two numbers side by side with nothing to say which was which, on the one meter whose own
// caption promises to explain what it does to people. The bands are the same thresholds the
// crowd itself uses (Config.CivTier*), so the word is not a new idea invented for the readout -
// it is the behaviour the number already drives.
func CBDreadWord(civ: Float) -> String {
  if civ >= CBConfig.CivTierTerror() {
    return "people run";
  }
  if civ >= CBConfig.CivTierAfraid() {
    return "people are afraid";
  }
  if civ >= CBConfig.CivTierUneasy() {
    return "people are uneasy";
  }
  if civ >= CBConfig.CivTierNotice() {
    return "people notice";
  }
  return "nobody minds";
}

// The civilian intensity slider, as the Director passes it to the crowd (Director.reds:87-106).
// Defaults to 1.0 before the settings store has filled in, which is what the Director does too.
func CBCivIntensity() -> Float {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    return rt.GetSettings().civIntensity;
  }
  return 1.0;
}

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

// A Rival's traits, or their weaknesses, by name: the first `limit` of them, comma separated.
func CBRivalTraitList(content: ref<CyberbaneContent>, r: ref<CBRival>, weaknesses: Bool, limit: Int32) -> String {
  if !IsDefined(content) || !IsDefined(r) {
    return "";
  }
  let out = "";
  let n = 0;
  for t in content.GetTraits() {
    if IsDefined(t) && Equals(t.isWeakness, weaknesses) && n < limit && CBRivalHasTrait(r, t.id) {
      out += (n > 0 ? ", " : "") + t.display;
      n += 1;
    }
  }
  return out;
}
