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
// The page as a tab of the game's menu (UI/HubTab.reds), which has the game's own row above it and
// its button hints below. How much smaller it is drawn so it fits between them, where in the screen's
// 3840x2160 its tabs start (level with the game's own content), and the y on the page they are at.
public func CBHudTabFit() -> Float = 0.94
public func CBHudTabMaxScale() -> Float = 1.88
public func CBHudTabTop() -> Float = 280.0
public func CBHudTabFirstY() -> Float = 48.0
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
  // Interface size can shrink the page but never push it off the screen. `s` fits the 1920x1080
  // design to the space; the panel is a little smaller than the design, so the most it may be
  // enlarged is until the panel itself meets the edge. Above that, 150% Interface size ran the
  // page's top, bottom and sides off the screen, footer and tabs included.
  let fullFit = s * MinF(CBHudDesignW() / CBHudPanelW(), CBHudDesignH() / CBHudPanelH());
  let scaled = ClampF(s * CBHudUserScale(), 0.4, MaxF(fullFit, 0.4));
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
// Space kept clear above the footer, so the last line of prose never touches it.
public func CBHudFooterGap() -> Float = 24.0
// The prose under and beside the lists.
public func CBHudBodyFont() -> Int32 = 21

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
// The button's label is drawn in capitals, which run wide: at 23 "CLICK AGAIN: ERASE EVERYTHING"
// was wider than the button. At 20, with that one reworded, every label the page uses fits, and
// CBHudFit guards anything added later.
public func CBHudActionFont() -> Int32 = 20
// Two more buttons stacked under it, for a screen with more than one thing to do (the Rivals: find
// one, forget one, forget them all). Three of them end at 844, well clear of the footer at 952, and
// they stand in the column the prose beside them already leaves free (CBHudActionW).
public func CBHudExtraActions() -> Int32 = 2
public func CBHudActionGap() -> Float = 8.0

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
// The game's button when the page is a tab: dark, lit from behind when the cursor is on it.
// The tint's own alpha does nothing on these, so they are dark colours rather than see-through ones.
public func CBHudGameButtonBack() -> HDRColor = new HDRColor(0.05, 0.03, 0.04, 1.0)
public func CBHudGameButtonHot() -> HDRColor = new HDRColor(0.06, 0.17, 0.19, 1.0)
public func CBHudGameRowPicked() -> HDRColor = new HDRColor(0.05, 0.15, 0.17, 1.0)
public func CBHudGameCell() -> HDRColor = new HDRColor(0.06, 0.025, 0.035, 1.0)
public func CBHudGameCellHot() -> HDRColor = new HDRColor(0.10, 0.05, 0.06, 1.0)
public func CBHudGameCellEdge() -> HDRColor = new HDRColor(0.40, 0.13, 0.15, 1.0)
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
// The same columns on the game's own screens: a list's name is cyan there, in capitals, and what is
// said about it sits back.
public func CBHudGameRowTint(col: Int32) -> HDRColor {
  if col == 0 { return CBHudCyan(); }
  if col == 1 { return new HDRColor(0.78, 0.80, 0.84, 1.0); }
  if col == 2 { return CBHudGrey(); }
  if col == 3 { return CBHudLabel(); }
  if col == 4 { return new HDRColor(0.80, 0.52, 0.34, 1.0); }
  return CBHudGrey();
}

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
    case 6: return "What the street calls you and what it gets you. Click any title to read it, or go by one you have earned.";
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
// The buttons under it, numbered from 1.
public func CBHudExtraActionName(k: Int32) -> CName {
  return CBHudWidgetName("cbHubAction", k);
}
public func CBHudSettingsName() -> CName = n"cbHubModSettings"
// The previous and next screen keys drawn at the two ends of the tab bar.
public func CBHudPrevName() -> CName = n"cbHubPrevTab"
public func CBHudNextName() -> CName = n"cbHubNextTab"
// The two buttons that page a long list, beside the line that says where in it you are.
public func CBHudListUpName() -> CName = n"cbHubListUp"
public func CBHudListDownName() -> CName = n"cbHubListDown"
public func CBHudListButtonW() -> Float = 110.0
public func CBHudKeyW() -> Float = 48.0

// The event Mod Settings adds to the pause scenario for its own entry. Spawning it from the page is
// exactly what clicking "Mod Settings" in the pause menu's list does.
public func CBModSettingsEvent() -> CName = n"OnSwitchToModSettings"

// Which of the game's parts this is, handed back when it lands: a screen's index, or one of the keys.
public class CBHudGamePart {
  public let index: Int32;
}

public func CBHudGamePartPrev() -> Int32 = -1
public func CBHudGamePartNext() -> Int32 = -2
// Long enough for a slow disk, and only ever waited out if the parts are not coming at all.
public func CBHudGameTabsWait() -> Float = 1.5

public class CBHud {
  // The pause menu this page is drawn in. Weak: the menu owns the page, never the other way round.
  private let m_owner: wref<inkGameController>;
  private let m_inTab: Bool;              // drawn as a tab of the game's menu rather than in the pause menu
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
  // The same tabs as the game's own widgets, when the page is a tab of the game's menu.
  private let m_gameTabRoot: array<wref<inkWidget>>;
  private let m_gameTabLabel: array<wref<HubMenuLabelContentContainer>>;
  private let m_gameRow: wref<inkHorizontalPanel>;
  private let m_gameLabels: wref<inkHorizontalPanel>;
  private let m_gameArrived: Int32;
  private let m_gameTabsSettled: Bool;
  private let m_gameTimer: ref<inkAnimProxy>;
  private let m_rowFrame: array<wref<inkImage>>;
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
  private let m_rowBg: array<wref<inkWidget>>;
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
  private let m_actionBg: wref<inkWidget>;
  private let m_actionFrame: wref<inkImage>;
  private let m_actionText: wref<inkText>;
  private let m_actionOn: Bool;
  // The buttons under it, index 0 being the second button on the page (CBHudExtraActionName(1)).
  private let m_extraBox: array<wref<inkCanvas>>;
  private let m_extraBg: array<wref<inkWidget>>;
  private let m_extraFrame: array<wref<inkImage>>;
  private let m_extraText: array<wref<inkText>>;
  private let m_extraOn: array<Bool>;
  private let m_settingsBox: wref<inkCanvas>;
  private let m_settingsBg: wref<inkRectangle>;
  // Q and E, at the two ends of the tab bar, where the game's own menus put the keys that move
  // between their tabs. Clicking them does what pressing them does.
  private let m_prevBox: wref<inkCanvas>;
  private let m_prevBg: wref<inkRectangle>;
  private let m_nextBox: wref<inkCanvas>;
  private let m_nextBg: wref<inkRectangle>;
  // What the player has picked on the screens that have something to pick.
  private let m_pickFaction: CName;
  private let m_pickRival: Int32;
  // The title being read on the Titles screen, once somebody has clicked one.
  private let m_titlePick: CName;
  private let m_titlePicked: Bool;
  private let m_purgeArmed: Bool;          // "forget every rival" asks twice
  private let m_findArmed: Int32;          // buying a Rival's whereabouts asks twice: the Rival it is armed for
  private let m_forgetArmed: Int32;        // forgetting one Rival asks twice too
  private let m_payArmed: CName;           // paying a gang off asks twice too: the gang it is armed for
  // A list longer than the page scrolls (ListWindow): which entry is in the top row, how long the
  // list is, how many rows it gets, the line saying so, and the stick's latch.
  private let m_listTop: Int32;
  private let m_listTotal: Int32;
  private let m_listRows: Int32;
  private let m_listMore: wref<inkText>;
  private let m_listUpBox: wref<inkCanvas>;
  private let m_listUpBg: wref<inkWidget>;
  private let m_listUpText: wref<inkText>;
  private let m_listDownBox: wref<inkCanvas>;
  private let m_listDownBg: wref<inkWidget>;
  private let m_listDownText: wref<inkText>;
  private let m_listScrolled: Bool;        // said so in the log once this page was opened
  private let m_stickLatched: Bool;
  private let m_resetArmed: Bool;          // "start over" asks twice as well
  private let m_hover: CName;              // the clickable thing under the cursor, by name
  private let m_inputBound: Bool;          // the tab keys are registered with the pause menu
  // Why no Rival can arrive right now, or "". Resolved once per render, not once per row.
  private let m_holdLabel: String;
  // How many of the pause menu's units one unit of the 1920x1080 design is (CBHubPageScale).
  //
  // The page used to be laid out at design size and then blown up with SetScale on the panel.
  // SetScale is a render transform: it changes how the panel is drawn and nothing about where
  // its widgets are. Pointer events are hit-tested against where the widgets are - their layout
  // - so at the usual scale of about 2 every row, tab and button was drawn at twice the size,
  // half-way out from the centre, while the place that answered the mouse was the small,
  // unscaled one underneath. Clicking a row landed on whatever box sat there at design size, or
  // on nothing; hover lit up a different row from the one under the cursor; and the visible
  // page did not line up with anything it responded to. Now the page is laid out at its real
  // size and nothing is scaled at draw time, so what you see is exactly what you click.
  private let m_scale: Float;

  public func IsOpen() -> Bool {
    return this.m_open && this.m_built;
  }

  // Show the page in this pause menu, building it the first time. False if there was nowhere to
  // draw it, in which case the menu is left exactly as it was.
  public func Show(owner: ref<inkGameController>, sys: ref<CyberbaneSystem>, game: GameInstance, inTab: Bool) -> Bool {
    if !IsDefined(owner) || !IsDefined(sys) {
      return false;
    }
    if !this.m_built {
      this.m_owner = owner;
      this.m_inTab = inTab;
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
    this.m_payArmed = n"";
    this.m_findArmed = 0;
    this.m_forgetArmed = 0;
    this.m_listTop = 0;
    this.m_listScrolled = false;
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
    this.m_payArmed = n"";
    this.m_findArmed = 0;
    this.m_forgetArmed = 0;
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
    while i < ArraySize(this.m_gameTabRoot) {
      this.Unhook(this.m_gameTabRoot[i]);
      i += 1;
    }
    i = 0;
    while i < ArraySize(this.m_rowBox) {
      this.Unhook(this.m_rowBox[i]);
      i += 1;
    }
    this.Unhook(this.m_actionBox);
    i = 0;
    while i < ArraySize(this.m_extraBox) {
      this.Unhook(this.m_extraBox[i]);
      i += 1;
    }
    this.Unhook(this.m_settingsBox);
    this.Unhook(this.m_prevBox);
    this.Unhook(this.m_nextBox);
    this.Unhook(this.m_listUpBox);
    this.Unhook(this.m_listDownBox);
    if this.m_inputBound && IsDefined(this.m_owner) {
      this.m_owner.UnregisterFromGlobalInputCallback(n"OnPostOnRelease", this, n"CBOnGlobalRelease");
      this.m_owner.UnregisterFromGlobalInputCallback(n"OnPostOnRelative", this, n"CBOnWheel");
      this.m_owner.UnregisterFromGlobalInputCallback(n"OnPostOnAxis", this, n"CBOnStick");
    }
    this.m_inputBound = false;
    this.m_open = false;
    this.m_built = false;
    if IsDefined(this.m_gameTimer) {
      this.m_gameTimer.UnregisterFromCallback(inkanimEventType.OnFinish, this, n"CBOnGameTabsLate");
      this.m_gameTimer.Stop();
      this.m_gameTimer = null;
    }
    if this.m_inTab && IsDefined(this.m_owner) {
      this.m_owner.SetCursorContext(n"Default");
    }
    this.m_owner = null;
  }

  private func Hook(box: wref<inkWidget>) -> Void {
    if !IsDefined(box) {
      return;
    }
    box.SetInteractive(true);
    box.RegisterToCallback(n"OnRelease", this, n"CBOnClick");
    box.RegisterToCallback(n"OnHoverOver", this, n"CBOnHoverOver");
    box.RegisterToCallback(n"OnHoverOut", this, n"CBOnHoverOut");
  }

  private func Unhook(box: wref<inkWidget>) -> Void {
    if !IsDefined(box) {
      return;
    }
    box.UnregisterFromCallback(n"OnRelease", this, n"CBOnClick");
    box.UnregisterFromCallback(n"OnHoverOver", this, n"CBOnHoverOver");
    box.UnregisterFromCallback(n"OnHoverOut", this, n"CBOnHoverOut");
    box.SetInteractive(false);
  }

  // Design units to the menu's units. Every placement on the page goes through these.
  private func Scale() -> Float {
    return this.m_scale > 0.0 ? this.m_scale : 1.0;
  }

  private func Px(v: Float) -> Float {
    return v * this.Scale();
  }

  private func PxSize(w: Float, h: Float) -> Vector2 {
    return new Vector2(w * this.Scale(), h * this.Scale());
  }

  private func PxAt(x: Float, y: Float) -> inkMargin {
    return new inkMargin(x * this.Scale(), y * this.Scale(), 0.0, 0.0);
  }

  private func Click() -> Void {
    if IsDefined(this.m_owner) {
      this.m_owner.PlaySound(n"Button", n"OnPress");
    }
  }

  // Changing screen sounds like the game's own tabs, on its own screen.
  private func ClickTab() -> Void {
    if this.m_inTab && IsDefined(this.m_owner) {
      this.m_owner.PlaySound(n"TabButton", n"OnPress");
    } else {
      this.Click();
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
    t.SetFontSize(Max(1, RoundF(Cast<Float>(size) * this.Scale())));
    t.SetTintColor(tint);
    t.SetAnchor(inkEAnchor.TopLeft);
    // Never a target. The boxes are what answer the mouse; the prose under a list is as wide as
    // the list and is laid over it, and text that took pointer events would sit between the
    // cursor and the rows it covers.
    t.SetInteractive(false);
    t.Reparent(parent, -1);
    this.Paint(t, colour);
    return t;
  }

  private func NewRect(parent: ref<inkCompoundWidget>, tint: HDRColor) -> ref<inkRectangle> {
    let r = new inkRectangle();
    r.SetAnchor(inkEAnchor.TopLeft);
    r.SetTintColor(tint);
    r.SetInteractive(false);
    r.Reparent(parent, -1);
    return r;
  }

  // A box that can be clicked: a canvas with a band filling it. The canvas is the target, so the
  // text drawn on it is part of the target too, and the band is what changes under the cursor.
  private func NewBox(parent: ref<inkCompoundWidget>, name: CName, x: Float, y: Float, w: Float, h: Float) -> ref<inkCanvas> {
    let box = new inkCanvas();
    box.SetName(name);
    box.SetAnchor(inkEAnchor.TopLeft);
    box.SetSize(this.PxSize(w, h));
    box.SetMargin(this.PxAt(x, y));
    box.Reparent(parent, -1);
    return box;
  }

  private func NewBand(box: ref<inkCanvas>, tint: HDRColor) -> ref<inkRectangle> {
    let bg = new inkRectangle();
    bg.SetAnchor(inkEAnchor.Fill);
    bg.SetTintColor(tint);
    bg.SetInteractive(false);   // the box behind it is the target, so the whole box is
    bg.Reparent(box, -1);
    return bg;
  }

  // ---- The game's own parts, for the page as a tab of the game's menu (UI/HubTab.reds) ----------
  //
  // On that page everything that is furniture rather than information is the game's: the row of
  // screens is the label the game spawns for its own top row, at either end of it is the widget the
  // game draws a key with, and the button is the game's button art. Spawned by name, so a part a patch
  // has moved comes back as nothing, and then the page falls back on what it draws for the pause menu.

  // The screens, in a row: the game's key for "previous", its labels, its key for "next", which is how
  // the game lays out its own row.
  //
  // Loaded rather than spawned on the spot. A screen can only spawn at once from the libraries its own
  // file already names, and the Stats screen names the button hints and nothing else, so the game
  // quietly gave back nothing. They are all asked for together, each with its place, and the page stays
  // out of sight until the last has landed, then comes up once. The first version put the page's own
  // boxes up while it waited and swapped them, and the swap could be seen.
  //
  // The boxes are still built, hidden, for a game that never delivers (CBOnGameTabsLate).
  private func StartGameTabs(panel: ref<inkCanvas>) -> Void {
    let row = new inkHorizontalPanel();
    row.SetName(n"cbHubGameTabs");
    row.SetAnchor(inkEAnchor.TopCenter);
    row.SetAnchorPoint(new Vector2(0.5, 0.0));
    row.SetFitToContent(true);
    row.SetMargin(new inkMargin(0.0, this.Px(CBHudTabFirstY()), 0.0, 0.0));
    row.Reparent(panel, -1);
    // A holder each, because parts from two different files need not land in the order they were asked for.
    let leftKey = this.NewGameHolder(row);
    let labels = this.NewGameHolder(row);
    let rightKey = this.NewGameHolder(row);
    this.m_gameRow = row;
    this.m_gameLabels = labels;
    this.m_gameArrived = 0;
    ArrayResize(this.m_gameTabRoot, CBHudTabCount());
    ArrayResize(this.m_gameTabLabel, CBHudTabCount());
    // If it has not all come by then, it is not coming. Measured on the interface's own clock, by an
    // animation that changes nothing, because the world's clock is slowed while this menu is open.
    let wait = new inkAnimTransparency();
    wait.SetStartTransparency(1.0);
    wait.SetEndTransparency(1.0);
    wait.SetDuration(CBHudGameTabsWait());
    let timer = new inkAnimDef();
    timer.AddInterpolator(wait);
    this.m_gameTimer = panel.PlayAnimation(timer);
    if IsDefined(this.m_gameTimer) {
      this.m_gameTimer.RegisterToCallback(inkanimEventType.OnFinish, this, n"CBOnGameTabsLate");
    }
    this.SpawnGameKey(leftKey, CBHudGamePartPrev());
    let t = 0;
    while t < CBHudTabCount() {
      let part = new CBHudGamePart();
      part.index = t;
      this.m_owner.AsyncSpawnFromExternal(labels, r"base\\gameplay\\gui\\fullscreen\\hub_menu\\new_hub.inkwidget", n"new_menu_element",
                                          this, n"CBOnGamePartSpawned", part);
      t += 1;
    }
    this.SpawnGameKey(rightKey, CBHudGamePartNext());
  }

  private func NewGameHolder(row: ref<inkHorizontalPanel>) -> ref<inkHorizontalPanel> {
    let holder = new inkHorizontalPanel();
    holder.SetFitToContent(true);
    holder.SetVAlign(inkEVerticalAlign.Center);
    holder.Reparent(row, -1);
    return holder;
  }

  private func SpawnGameKey(holder: ref<inkHorizontalPanel>, which: Int32) -> Void {
    let part = new CBHudGamePart();
    part.index = which;
    this.m_owner.AsyncSpawnFromExternal(holder, r"base\\gameplay\\gui\\common\\buttons\\base_buttons.inkwidget", n"inputDisplayLabelFlex",
                                        this, n"CBOnGamePartSpawned", part);
  }

  protected cb func CBOnGamePartSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool {
    // The menu can have gone in the time it took, or the wait can have run out.
    let part = userData as CBHudGamePart;
    if !IsDefined(this.m_owner) || !IsDefined(this.m_gameRow) || this.m_gameTabsSettled || !IsDefined(part) {
      return false;
    }
    if part.index == CBHudGamePartPrev() {
      this.PlaceGameKey(widget, n"option_switch_prev_settings");
    } else {
      if part.index == CBHudGamePartNext() {
        this.PlaceGameKey(widget, n"option_switch_next_settings");
      } else {
        if !this.PlaceGameTab(widget, part.index) {
          this.UseOwnTabs();
          return false;
        }
      }
    }
    this.m_gameArrived += 1;
    if this.m_gameArrived >= CBHudTabCount() + 2 {
      this.ShowGameTabs();
    }
    return true;
  }

  private func PlaceGameTab(widget: ref<inkWidget>, index: Int32) -> Bool {
    if !IsDefined(widget) || index >= ArraySize(this.m_tabNames) {
      return false;
    }
    let label = widget.GetController() as HubMenuLabelContentContainer;
    if !IsDefined(label) {
      return false;
    }
    let data: MenuData;
    data.label = StrUpper(CBHudTabName(index + 1));
    label.SetData(data);
    widget.SetName(this.m_tabNames[index]);
    widget.SetVAlign(inkEVerticalAlign.Center);
    widget.SetMargin(new inkMargin(20.0, 0.0, 20.0, 0.0));
    this.m_gameTabRoot[index] = widget;
    this.m_gameTabLabel[index] = label;
    this.Hook(widget);
    return true;
  }

  // The game's key glyph for this action: whatever the player has bound, or the controller's button.
  private func PlaceGameKey(widget: ref<inkWidget>, action: CName) -> Void {
    if !IsDefined(widget) {
      return;
    }
    let key = widget.GetController() as LabelInputDisplayController;
    if IsDefined(key) {
      key.SetInputActionLabel(action, "");
      widget.SetVAlign(inkEVerticalAlign.Center);
    }
  }

  // Everything is here. In the order the screens go, whatever order it landed in.
  private func ShowGameTabs() -> Void {
    this.m_gameTabsSettled = true;
    let i = 0;
    while i < ArraySize(this.m_gameTabRoot) {
      if IsDefined(this.m_gameTabRoot[i]) {
        this.m_gameLabels.ReorderChild(this.m_gameTabRoot[i], i);
      }
      i += 1;
    }
    this.Paint();
    this.RevealPage();
  }

  // The game did not hand over its parts. The page's own boxes do the job.
  private func UseOwnTabs() -> Void {
    this.m_gameTabsSettled = true;
    CBLog.Info(n"UI", "The game's tab labels did not arrive; the Hub tab is drawing its own.");
    if IsDefined(this.m_gameRow) {
      this.m_gameRow.SetVisible(false);
    }
    let i = 0;
    while i < ArraySize(this.m_tabBox) {
      if IsDefined(this.m_tabBox[i]) {
        this.m_tabBox[i].SetVisible(true);
      }
      i += 1;
    }
    if IsDefined(this.m_prevBox) {
      this.m_prevBox.SetVisible(true);
    }
    if IsDefined(this.m_nextBox) {
      this.m_nextBox.SetVisible(true);
    }
    // Their labels came to nothing: nothing to colour, and nothing to answer the mouse.
    ArrayClear(this.m_gameTabLabel);
    this.Paint();
    this.RevealPage();
  }

  protected cb func CBOnGameTabsLate(proxy: ref<inkAnimProxy>) -> Bool {
    if !this.m_gameTabsSettled && IsDefined(this.m_owner) {
      this.UseOwnTabs();
    }
    return true;
  }

  // Once, eased in like the game's own screens.
  private func RevealPage() -> Void {
    if IsDefined(this.m_gameTimer) {
      this.m_gameTimer.UnregisterFromCallback(inkanimEventType.OnFinish, this, n"CBOnGameTabsLate");
      this.m_gameTimer.Stop();
      this.m_gameTimer = null;
    }
    if !IsDefined(this.m_root) {
      return;
    }
    let fade = new inkAnimTransparency();
    fade.SetStartTransparency(0.0);
    fade.SetEndTransparency(1.0);
    fade.SetDuration(0.2);
    let intro = new inkAnimDef();
    intro.AddInterpolator(fade);
    this.m_root.PlayAnimation(intro);
  }

  // What can be clicked right now, for the hand cursor and the hover sound.
  private func IsLive(name: CName) -> Bool {
    if Equals(name, CBHudActionName()) {
      return this.m_actionOn;
    }
    let k = this.ExtraIndex(name);
    if k >= 0 {
      return this.m_extraOn[k];
    }
    if Equals(name, CBHudListUpName()) {
      return this.m_listTop > 0;
    }
    if Equals(name, CBHudListDownName()) {
      return this.m_listTop + this.m_listRows < this.m_listTotal;
    }
    let i = 0;
    while i < ArraySize(this.m_tabNames) {
      if Equals(this.m_tabNames[i], name) {
        return true;
      }
      i += 1;
    }
    i = 0;
    while i < ArraySize(this.m_rowNames) {
      if Equals(this.m_rowNames[i], name) {
        return this.m_rowClickable[i];
      }
      i += 1;
    }
    return false;
  }

  // What the page's buttons are drawn with: the game's own button on its own screen, a band elsewhere.
  private func NewListButtonBack(box: ref<inkCanvas>) -> ref<inkWidget> {
    if this.m_inTab {
      let back: ref<inkWidget> = this.NewGameArt(box, n"cell_bg", CBHudGameButtonBack());
      this.NewGameArt(box, n"cell_fg", CBHudLabel());
      return back;
    }
    return this.NewBand(box, CBHudButtonIdle());
  }

  private func NewListButtonText(box: ref<inkCanvas>, label: String) -> ref<inkText> {
    let t = this.NewText(box, 19, n"Semibold", CBHudHead());
    t.SetLetterCase(textLetterCase.UpperCase);
    t.SetHorizontalAlignment(textHorizontalAlignment.Center);
    t.SetFitToContent(false);
    t.SetSize(this.PxSize(CBHudListButtonW(), 24.0));
    t.SetMargin(this.PxAt(0.0, 5.0));
    t.SetText(label);
    return t;
  }

  // A layer of the game's button, out of the atlas its own buttons are cut from. The cut corner stays
  // the size it was drawn at however wide the button is.
  private func NewGameArt(box: ref<inkCanvas>, part: CName, tint: HDRColor) -> ref<inkImage> {
    let art = new inkImage();
    art.SetAtlasResource(r"base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");
    art.SetTexturePart(part);
    art.SetNineSliceScale(true);
    art.SetNineSliceGrid(new inkMargin(0.0, 0.0, 10.0, 0.0));
    art.SetAnchor(inkEAnchor.Fill);
    art.SetTintColor(tint);
    art.SetInteractive(false);
    art.Reparent(box, -1);
    return art;
  }

  private func Build(owner: ref<inkGameController>, game: GameInstance) -> Bool {
    let parent = owner.GetRootCompoundWidget();
    if !IsDefined(parent) {
      return false;
    }
    // Worked out once, before anything is placed: every position, size, wrap width and font size
    // below goes through it (Scale, Px, PxSize, PxAt).
    this.m_scale = CBHubPageScale(game, parent);
    if this.m_inTab {
      this.m_scale = MinF(this.m_scale * CBHudTabFit(), CBHudTabMaxScale());
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
    // As a tab the game's own background is the page's, and its button hints have to show. Nothing is
    // underneath to be clicked by accident: the screen's own content is hidden (UI/HubTab.reds).
    if this.m_inTab {
      backdrop.SetVisible(false);
      backdrop.SetInteractive(false);
    }
    backdrop.Reparent(root, -1);

    let panel = new inkCanvas();
    panel.SetAnchor(inkEAnchor.Centered);
    panel.SetAnchorPoint(new Vector2(0.5, 0.5));
    panel.SetSize(this.PxSize(CBHudPanelW(), CBHudPanelH()));
    if this.m_inTab {
      panel.SetAnchor(inkEAnchor.TopCenter);
      panel.SetAnchorPoint(new Vector2(0.5, 0.0));
      panel.SetMargin(new inkMargin(0.0, CBHudTabTop() - this.Px(CBHudTabFirstY()), 0.0, 0.0));
    }
    panel.Reparent(root, -1);

    // ---- Title block, top left, the way the menus mark themselves --------
    let header = this.NewText(panel, 28, n"Semibold", CBHudLabel(), n"MainColors.Red");
    header.SetLetterCase(textLetterCase.UpperCase);
    header.SetText("CYBERBANE");
    header.SetMargin(this.PxAt(x, 10.0));
    header.SetVisible(!this.m_inTab);   // the game's row already says where this is

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
      label.SetSize(this.PxSize(CBHudChipWidth() - 8.0, 32.0));
      label.SetMargin(this.PxAt(0.0, 9.0));
      label.SetText(CBHudTabName(t + 1));
      // The open screen is marked by a bar under its name, which is what the game does.
      let under = this.NewRect(box, CBHudClear());
      under.SetSize(this.PxSize(CBHudChipWidth() - 48.0, 3.0));
      under.SetMargin(this.PxAt(20.0, 47.0));
      ArrayPush(this.m_tabBox, box);
      ArrayPush(this.m_tabBg, bg);
      ArrayPush(this.m_tabText, label);
      ArrayPush(this.m_tabUnder, under);
      ArrayPush(this.m_tabNames, name);
      box.SetVisible(!this.m_inTab);
      t += 1;
    }

    // ---- The keys that change screen, at the ends of the row they change ----------
    //
    // These were only ever named in the footer, a line of small print at the other end of the
    // page from the tabs they move between. The game's menus draw them at the two ends of the tab
    // bar, level with it, so that is where they go: one just before the first tab, one just after
    // the last, centred on the tabs' own height.
    //
    // What they say has to be what they do. They read Q and E from 1.6 to 1.7.2, and neither key has
    // ever been on these actions: on a keyboard prior_menu and next_menu are 1 and 3
    // (r6/config/inputUserMappings.xml). Q and E are lean, and nothing here listens for them.
    let keyW = CBHudKeyW();
    let keyY = 48.0 + (52.0 - keyW) / 2.0;
    let prev = this.NewBox(panel, CBHudPrevName(), tabsX - keyW - 8.0, keyY, keyW, keyW);
    let prevBg = this.NewBand(prev, CBHudButtonIdle());
    let prevText = this.NewText(prev, 24, n"Semibold", CBHudHead());
    prevText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    prevText.SetFitToContent(false);
    prevText.SetSize(this.PxSize(keyW, 32.0));
    prevText.SetMargin(this.PxAt(0.0, (keyW - 32.0) / 2.0));
    prevText.SetText(this.m_inTab ? "A" : "1");
    let next = this.NewBox(panel, CBHudNextName(), tabsX + tabsW + 8.0, keyY, keyW, keyW);
    let nextBg = this.NewBand(next, CBHudButtonIdle());
    let nextText = this.NewText(next, 24, n"Semibold", CBHudHead());
    nextText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    nextText.SetFitToContent(false);
    nextText.SetSize(this.PxSize(keyW, 32.0));
    nextText.SetMargin(this.PxAt(0.0, (keyW - 32.0) / 2.0));
    nextText.SetText(this.m_inTab ? "D" : "3");
    prev.SetVisible(!this.m_inTab);
    next.SetVisible(!this.m_inTab);
    this.m_prevBox = prev;
    this.m_prevBg = prevBg;
    this.m_nextBox = next;
    this.m_nextBg = nextBg;

    // ---- The lines under the tabs that say what you are looking at ---------
    let subhead = this.NewText(panel, 24, n"Medium", CBHudDim(), n"MainColors.Grey");
    subhead.SetHorizontalAlignment(textHorizontalAlignment.Center);
    subhead.SetFitToContent(false);
    subhead.SetSize(this.PxSize(w, 32.0));
    subhead.SetMargin(this.PxAt(x, 110.0));
    this.m_subhead = subhead;

    let tabline = this.NewText(panel, 20, n"Medium", CBHudGrey(), n"MainColors.Grey");
    tabline.SetHorizontalAlignment(textHorizontalAlignment.Center);
    tabline.SetFitToContent(false);
    tabline.SetSize(this.PxSize(w, 28.0));
    tabline.SetMargin(this.PxAt(x, 136.0));
    this.m_tabline = tabline;

    // Over the right end of a list that runs past the page: where in it you are, and that it scrolls.
    let more = this.NewText(panel, 19, n"Medium", CBHudGrey(), n"MainColors.Grey");
    more.SetHorizontalAlignment(textHorizontalAlignment.Right);
    more.SetFitToContent(false);
    more.SetSize(this.PxSize(w - 2.0 * CBHudListButtonW() - 24.0, 26.0));
    more.SetMargin(this.PxAt(x, CBHudContentTop() - 30.0));
    more.SetVisible(false);
    this.m_listMore = more;

    // Up and down, a page at a time. The wheel and the stick are quicker, and these are the ones that
    // always work: they are clicked like everything else on the page.
    let btnW = CBHudListButtonW();
    let up = this.NewBox(panel, CBHudListUpName(), x + w - 2.0 * btnW - 8.0, CBHudContentTop() - 36.0, btnW, 32.0);
    let down = this.NewBox(panel, CBHudListDownName(), x + w - btnW, CBHudContentTop() - 36.0, btnW, 32.0);
    this.m_listUpBg = this.NewListButtonBack(up);
    this.m_listDownBg = this.NewListButtonBack(down);
    this.m_listUpText = this.NewListButtonText(up, "Up");
    this.m_listDownText = this.NewListButtonText(down, "Down");
    up.SetVisible(false);
    down.SetVisible(false);
    this.m_listUpBox = up;
    this.m_listDownBox = down;

    // No rule under the header. It was 1540 px of two-pixel line, which is the single most
    // warp-revealing shape on the page, and the heading above it already separates the screens.

    // ---- Score meters -------------------------------------------------------
    let b = 0;
    while b < CBHudBarCount() {
      let top = CBHudContentTop() + Cast<Float>(b) * 96.0;
      let bl = this.NewText(panel, 25, n"Semibold", CBHudLabel(), n"MainColors.Red");
      bl.SetLetterCase(textLetterCase.UpperCase);
      bl.SetMargin(this.PxAt(x, top));
      // Right-aligned against the edge the meter ends on, so every value lines up in one column.
      let bv = this.NewText(panel, 25, n"Semibold", CBHudValue());
      bv.SetHorizontalAlignment(textHorizontalAlignment.Right);
      bv.SetFitToContent(false);
      bv.SetSize(this.PxSize(w, 30.0));
      bv.SetMargin(this.PxAt(x, top));
      let track = this.NewRect(panel, new HDRColor(0.26, 0.08, 0.10, 0.9));
      track.SetSize(this.PxSize(CBHudBarWidth(), 10.0));
      track.SetMargin(this.PxAt(x, top + 36.0));
      let fill = this.NewRect(panel, CBHudCyan());
      fill.SetSize(this.PxSize(2.0, 10.0));
      fill.SetMargin(this.PxAt(x, top + 36.0));
      let cap = this.NewText(panel, 19, n"Medium", CBHudDim(), n"MainColors.Grey");
      cap.SetMargin(this.PxAt(x, top + 54.0));
      cap.SetWrapping(true, this.Px(w));
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
      // As a tab, a row is the game's own framed cell, the way the journal draws its list. No stripes:
      // the game does not stripe its lists.
      let band: ref<inkWidget>;
      if this.m_inTab {
        band = this.NewGameArt(rbox, n"cell_bg", CBHudGameCell());
        band.SetOpacity(0.85);
        ArrayPush(this.m_rowFrame, this.NewGameArt(rbox, n"cell_fg", CBHudGameCellEdge()));
      } else {
        band = this.NewBand(rbox, r % 2 == 0 ? CBHudBandEven() : CBHudBandOdd());
      }
      let pip = this.NewRect(rbox, CBHudGrey());
      pip.SetSize(this.PxSize(5.0, 26.0));
      pip.SetMargin(this.PxAt(0.0, 7.0));
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
        let cell = this.NewText(rbox, c == 0 ? 23 : 22, c == 0 ? n"Semibold" : n"Medium",
                                this.m_inTab ? CBHudGameRowTint(c) : CBHudRowColTint(c));
        if this.m_inTab && c == 0 {
          cell.SetLetterCase(textLetterCase.UpperCase);
        }
        if c == CBHudRowCols() - 1 {
          cell.SetHorizontalAlignment(textHorizontalAlignment.Right);
          cell.SetFitToContent(false);
          cell.SetSize(this.PxSize(w - 16.0, 28.0));
        }
        ArrayPush(this.m_rowCell, cell);
        c += 1;
      }
      rbox.SetVisible(false);
      r += 1;
    }

    // ---- Prose: under the meters, under a list, or beside the titles -----------
    // The game writes its descriptions in its red, and the page does the same on its own screen.
    let body = this.NewText(panel, CBHudBodyFont(), n"Medium", this.m_inTab ? CBHudLabel() : CBHudValue(),
                            this.m_inTab ? n"MainColors.Red" : n"");
    body.SetMargin(this.PxAt(x, CBHudContentTop()));
    body.SetWrapping(true, this.Px(w));
    body.SetSize(this.PxSize(w, 700.0));
    this.m_body = body;

    // ---- The button beside the detail panel ---------------------------------------
    let action = this.NewBox(panel, CBHudActionName(), x + w - CBHudActionW(), CBHudDetailTop() - 4.0,
                             CBHudActionW(), CBHudActionH());
    let actionBg: ref<inkWidget> = this.NewBand(action, CBHudButtonIdle());
    if this.m_inTab {
      actionBg.SetVisible(false);
      actionBg = this.NewGameArt(action, n"cell_bg", CBHudGameButtonBack());
      this.m_actionFrame = this.NewGameArt(action, n"cell_fg", CBHudLabel());
    }
    let actionText = this.NewText(action, CBHudActionFont(), n"Semibold", CBHudHead());
    actionText.SetLetterCase(textLetterCase.UpperCase);
    actionText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    actionText.SetFitToContent(false);
    actionText.SetSize(this.PxSize(CBHudActionW(), 30.0));
    actionText.SetMargin(this.PxAt(0.0, 13.0));
    action.SetVisible(false);
    this.m_actionBox = action;
    this.m_actionBg = actionBg;
    this.m_actionText = actionText;

    // ---- The buttons under it, built the same way ------------------------------------
    ArrayClear(this.m_extraBox);
    ArrayClear(this.m_extraBg);
    ArrayClear(this.m_extraFrame);
    ArrayClear(this.m_extraText);
    ArrayClear(this.m_extraOn);
    let ex = 1;
    while ex <= CBHudExtraActions() {
      let ey = CBHudDetailTop() - 4.0 + Cast<Float>(ex) * (CBHudActionH() + CBHudActionGap());
      let extra = this.NewBox(panel, CBHudExtraActionName(ex), x + w - CBHudActionW(), ey,
                              CBHudActionW(), CBHudActionH());
      let extraBg: ref<inkWidget> = this.NewBand(extra, CBHudButtonIdle());
      let extraFrame: ref<inkImage>;
      if this.m_inTab {
        extraBg.SetVisible(false);
        extraBg = this.NewGameArt(extra, n"cell_bg", CBHudGameButtonBack());
        extraFrame = this.NewGameArt(extra, n"cell_fg", CBHudLabel());
      }
      let extraText = this.NewText(extra, CBHudActionFont(), n"Semibold", CBHudHead());
      extraText.SetLetterCase(textLetterCase.UpperCase);
      extraText.SetHorizontalAlignment(textHorizontalAlignment.Center);
      extraText.SetFitToContent(false);
      extraText.SetSize(this.PxSize(CBHudActionW(), 30.0));
      extraText.SetMargin(this.PxAt(0.0, 13.0));
      extra.SetVisible(false);
      ArrayPush(this.m_extraBox, extra);
      ArrayPush(this.m_extraBg, extraBg);
      ArrayPush(this.m_extraFrame, extraFrame);
      ArrayPush(this.m_extraText, extraText);
      ArrayPush(this.m_extraOn, false);
      ex += 1;
    }

    // ---- Footer: hints on the left, the Mod Settings link on the right -----------
    // The footer is set off by its own dimmer text and the gap above it rather than by a rule
    // across the whole page, for the same reason as the header.

    let footer = this.NewText(panel, 19, n"Medium", CBHudDim(), n"MainColors.Grey");
    footer.SetMargin(this.PxAt(x, CBHudFooterY()));
    // Kept short enough to stop well clear of the Mod Settings button at the right of the same
    // line. It used to also explain Q and E, and ran some way underneath that button; the keys are
    // on the tab bar now, where they are used.
    footer.SetText(CBHudFit("Click a screen or a row for more      LB / RB on a controller      Esc / B: back",
                            w - 260.0 - 40.0, 19, 1));
    footer.SetVisible(!this.m_inTab);   // as a tab, the game's own button hints say all of this

    let settings = this.NewBox(panel, CBHudSettingsName(), x + w - 260.0, CBHudFooterY() - 8.0, 260.0, 40.0);
    let settingsBg = this.NewBand(settings, CBHudButtonIdle());
    let settingsText = this.NewText(settings, 19, n"Semibold", CBHudHead());
    settingsText.SetLetterCase(textLetterCase.UpperCase);
    settingsText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    settingsText.SetFitToContent(false);
    settingsText.SetSize(this.PxSize(260.0, 26.0));
    settingsText.SetMargin(this.PxAt(0.0, 8.0));
    settingsText.SetText("Mod Settings");
    settings.SetVisible(!this.m_inTab);   // a screen of the pause menu's, which this is not
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
    i = 0;
    while i < ArraySize(this.m_extraBox) {
      this.Hook(this.m_extraBox[i]);
      i += 1;
    }
    this.Hook(this.m_settingsBox);
    this.Hook(this.m_prevBox);
    this.Hook(this.m_nextBox);
    this.Hook(this.m_listUpBox);
    this.Hook(this.m_listDownBox);
    // The previous/next tab keys. Registered once and left until the menu goes, rather than on
    // every show and hide, so nothing is ever registered or unregistered in the middle of the very
    // input event that is being delivered.
    owner.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"CBOnGlobalRelease");
    // The wheel comes as relative input and the stick as an axis, as in the game's own gallery and
    // map, so each has its own handler and one notch can never move a list twice.
    owner.RegisterToGlobalInputCallback(n"OnPostOnRelative", this, n"CBOnWheel");
    owner.RegisterToGlobalInputCallback(n"OnPostOnAxis", this, n"CBOnStick");
    this.m_inputBound = true;
    this.m_built = true;
    if this.m_inTab {
      // Nothing on screen until it can all come up at once (StartGameTabs).
      root.SetOpacity(0.0);
      this.StartGameTabs(panel);
    }
    return true;
  }

  // ---- Input -----------------------------------------------------------------------------------

  // Every tab, row and button. Which one it was comes from the widget the handler is running for.
  protected cb func CBOnClick(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) {
      return false;
    }
    // `click` only. A release arrives once for every action bound to the button, and the left mouse
    // button and A are bound to `click` (UIMenuShared) and to `select` (UIMenu) at once
    // (r6/config/inputContexts.xml, inputUserMappings.xml). Taking either ran every press here twice:
    // the log has every title chosen on the Hub written two times. That opened a gang and closed it
    // again in one press, so clicking a gang showed nothing, and it armed and confirmed Forget every
    // rival and Start over in one press as well. `click` also carries Enter, F and a touch tap, and it
    // is the one the game's own pause menu takes (pauseMenu.script, OnGogPressed).
    if !e.IsAction(n"click") {
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
          this.ClickTab();
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
    let ek = this.ExtraIndex(name);
    if ek >= 0 {
      e.Handle();
      if this.m_extraOn[ek] {
        this.Click();
        this.ExtraClicked(sys, game, ek + 1);
      }
      return true;
    }
    if Equals(name, CBHudListUpName()) || Equals(name, CBHudListDownName()) {
      e.Handle();
      let page = Equals(name, CBHudListUpName()) ? -this.m_listRows : this.m_listRows;
      if this.ScrollBy(sys, game, page) {
        this.Click();
      }
      return true;
    }
    if Equals(name, CBHudPrevName()) || Equals(name, CBHudNextName()) {
      e.Handle();
      let dir = 1;
      if Equals(name, CBHudPrevName()) {
        dir = -1;
      }
      this.StepTab(sys, game, dir);
      return true;
    }
    if Equals(name, CBHudSettingsName()) {
      e.Handle();
      this.Click();
      // Last thing done here: switching screens closes the pause menu's page, which takes this one
      // with it, so nothing may touch the page after the event is spawned.
      let pauseMenu = this.m_owner as PauseMenuGameController;
      if IsDefined(pauseMenu) {
        pauseMenu.CBSpawnMenuEvent(CBModSettingsEvent());
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
      if this.m_inTab && IsDefined(this.m_owner) && this.IsLive(this.m_hover) {
        this.m_owner.SetCursorContext(n"Hover");
        this.m_owner.PlaySound(n"Button", n"OnHover");
      }
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
      if this.m_inTab && IsDefined(this.m_owner) {
        this.m_owner.SetCursorContext(n"Default");
      }
    }
    return false;
  }

  // The previous/next tab keys, the same actions the settings menu uses (settingsMain.script:1311).
  // As a tab of the game's menu those belong to the game's own row, which moves between its tabs on
  // them, so the page takes the keys the game's screens use for their inner pages (the perk trees,
  // the journal, the ripperdoc's categories).
  protected cb func CBOnGlobalRelease(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) || e.IsHandled() {
      return false;
    }
    let step = 0;
    if this.m_inTab {
      if e.IsAction(n"option_switch_prev_settings") {
        step = -1;
      } else {
        if e.IsAction(n"option_switch_next_settings") {
          step = 1;
        }
      }
    } else {
      if e.IsAction(n"prior_menu") {
        step = -1;
      } else {
        if e.IsAction(n"next_menu") {
          step = 1;
        }
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
    e.Handle();
    this.StepTab(sys, game, step);
    return true;
  }

  // The mouse wheel moves a long list a row a notch. Up is a positive notch, as the gallery reads it.
  //
  // Not refused when something else has already marked the event handled: on its own screen the
  // page sits over the game's, and a scroll area of the game's hidden underneath could take the wheel
  // first. Nothing of the game's is in view to have wanted it.
  protected cb func CBOnWheel(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) || !e.IsAction(n"mouse_wheel") {
      return false;
    }
    let v = e.GetAxisData();
    let step = 0;
    if v > 0.0 {
      step = -1;
    }
    if v < 0.0 {
      step = 1;
    }
    return step != 0 && this.ScrollFromInput(e, step);
  }

  // The right stick, a row a push: it has to come back towards the middle before it moves again.
  protected cb func CBOnStick(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) || e.IsHandled() || !e.IsAction(n"right_stick_y") {
      return false;
    }
    let v = e.GetAxisData();
    if AbsF(v) < 0.3 {
      this.m_stickLatched = false;
      return false;
    }
    if this.m_stickLatched || AbsF(v) < 0.6 {
      return false;
    }
    this.m_stickLatched = true;
    return this.ScrollFromInput(e, v > 0.0 ? -1 : 1);
  }

  private func ScrollFromInput(e: ref<inkPointerEvent>, step: Int32) -> Bool {
    let game = GetGameInstance();
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) || !this.ScrollBy(sys, game, step) {
      return false;
    }
    e.Handle();
    return true;
  }

  // Move the window on the list being shown. False when it is already as far as it goes that way.
  private func ScrollBy(sys: ref<CyberbaneSystem>, game: GameInstance, step: Int32) -> Bool {
    if this.m_listTotal <= this.m_listRows {
      return false;
    }
    let top = Max(0, Min(this.m_listTop + step, this.m_listTotal - this.m_listRows));
    if top == this.m_listTop {
      return false;
    }
    this.m_listTop = top;
    if !this.m_listScrolled {
      this.m_listScrolled = true;
      CBLog.Info(n"UI", s"Hub list scrolled: \(top + 1) to \(Min(top + this.m_listRows, this.m_listTotal)) of \(this.m_listTotal).");
    }
    this.Render(sys, game);
    return true;
  }

  // The window onto a list: which entry goes in the top row, kept inside the list as it grows and
  // shrinks, and the line over it that says there is more. Every list screen asks this before it
  // draws, so none of them can have entries nobody can reach again.
  private func ListWindow(total: Int32, rows: Int32) -> Int32 {
    this.m_listTotal = total;
    this.m_listRows = rows;
    this.m_listTop = Max(0, Min(this.m_listTop, total - rows));
    let long = total > rows;
    if IsDefined(this.m_listMore) {
      if long {
        let last = Min(this.m_listTop + rows, total);
        this.m_listMore.SetText(s"\(this.m_listTop + 1)-\(last) of \(total)");
      }
      this.m_listMore.SetVisible(long);
    }
    if IsDefined(this.m_listUpBox) {
      this.m_listUpBox.SetVisible(long);
    }
    if IsDefined(this.m_listDownBox) {
      this.m_listDownBox.SetVisible(long);
    }
    return this.m_listTop;
  }

  // One screen back or forward, wrapping round. The keys and the key boxes on the tab bar both
  // come here, so the two can never disagree about where they go.
  private func StepTab(sys: ref<CyberbaneSystem>, game: GameInstance, step: Int32) -> Void {
    let tab = this.m_tab + step;
    if tab < 1 {
      tab = CBHudTabCount();
    }
    if tab > CBHudTabCount() {
      tab = 1;
    }
    this.ClickTab();
    this.SelectTab(sys, game, tab);
  }

  private func SelectTab(sys: ref<CyberbaneSystem>, game: GameInstance, tab: Int32) -> Void {
    this.m_tab = CBHudClampTab(tab);
    sys.SetHubTab(this.m_tab);
    this.m_purgeArmed = false;
    this.m_resetArmed = false;
    this.m_payArmed = n"";
    this.m_findArmed = 0;
    this.m_forgetArmed = 0;
    this.m_listTop = 0;
    this.m_listScrolled = false;
    this.m_hover = n"";
    this.Render(sys, game);
  }

  private func RowClicked(sys: ref<CyberbaneSystem>, game: GameInstance, row: Int32) -> Void {
    if this.m_tab == CBHudFactionsTab() {
      let f = this.m_rowFaction[row];
      // Clicking the one already open closes it again.
      this.m_pickFaction = Equals(f, this.m_pickFaction) ? n"" : f;
      this.m_payArmed = n"";
    } else {
      if this.m_tab == CBHudRivalsTab() {
        this.m_pickRival = this.m_rowRival[row];
        this.m_purgeArmed = false;
        this.m_resetArmed = false;
        this.m_findArmed = 0;
        this.m_forgetArmed = 0;
      } else {
        if this.m_tab == CBHudTitlesTab() {
          // A value in a field; safe to set at once, paused or not. n"" is automatic.
          // Any row can be read. Only one V has earned can be gone by.
          this.m_titlePick = this.m_rowTitle[row];
          this.m_titlePicked = true;
          if Equals(this.m_titlePick, n"") || sys.HasTitle(this.m_titlePick) {
            sys.SetActiveTitle(this.m_titlePick);
            CBLog.Info(n"UI", s"Title chosen on the Hub: \(NameToString(sys.GetChosenTitle())).");
          }
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
      // Money leaves V's pocket, so it asks first: the first click turns the button into a
      // confirmation, the second pays. A payment already chosen can be taken back in one.
      if NotEquals(this.m_pickFaction, n"") {
        if Equals(sys.GetPendingPeace(), this.m_pickFaction) {
          sys.RequestPeace(n"");
          this.m_payArmed = n"";
        } else {
          if CBHudCanPayOff(sys, game, this.m_pickFaction) {
            if Equals(this.m_payArmed, this.m_pickFaction) {
              this.m_payArmed = n"";
              sys.RequestPeace(this.m_pickFaction);
              CBLog.Info(n"UI", s"Pay-off confirmed on the Hub for \(NameToString(this.m_pickFaction)).");
            } else {
              this.m_payArmed = this.m_pickFaction;
            }
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
        // The first button on the Rivals is the picked one's whereabouts. Money leaves V's pocket,
        // so it asks first, like a pay-off; a purchase already chosen is taken back in one click.
        let id = this.m_pickRival;
        if id > 0 && sys.GetPendingFind() == id {
          sys.RequestRivalFind(0);
          this.m_findArmed = 0;
        } else {
          if CBHudCanFind(sys, game, id) {
            if this.m_findArmed == id {
              this.m_findArmed = 0;
              sys.RequestRivalFind(id);
            } else {
              this.m_findArmed = id;
              this.m_forgetArmed = 0;
              this.m_purgeArmed = false;
            }
          }
        }
      }
      }
    }
    this.Render(sys, game);
  }

  // The buttons under the first. Only the Rivals have them: forget this one, and forget them all.
  // Neither is carried out from here, for the reason given above ActionClicked.
  private func ExtraClicked(sys: ref<CyberbaneSystem>, game: GameInstance, slot: Int32) -> Void {
    if this.m_tab != CBHudRivalsTab() {
      return;
    }
    if slot == 1 {
      let id = this.m_pickRival;
      let r = sys.FindRivalById(id);
      if sys.IsRivalForgetPending(id) {
        sys.RequestRivalForget(id, false);
        this.m_forgetArmed = 0;
      } else {
        if IsDefined(r) && CBRivalForgettable(sys, r) {
          if this.m_forgetArmed == id {
            this.m_forgetArmed = 0;
            sys.RequestRivalForget(id, true);
          } else {
            this.m_forgetArmed = id;
            this.m_findArmed = 0;
            this.m_purgeArmed = false;
          }
        }
      }
    } else {
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
          this.m_findArmed = 0;
          this.m_forgetArmed = 0;
        }
      }
    }
    this.Render(sys, game);
  }

  // Which of the buttons under the first this widget name is, or -1.
  private func ExtraIndex(name: CName) -> Int32 {
    let k = 0;
    while k < ArraySize(this.m_extraBox) && k < ArraySize(this.m_extraOn) {
      if Equals(name, CBHudExtraActionName(k + 1)) {
        return k;
      }
      k += 1;
    }
    return -1;
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
    // The game's labels colour themselves: each state is in the widget, and these are its names for them.
    i = 0;
    while i < ArraySize(this.m_gameTabLabel) {
      if IsDefined(this.m_gameTabLabel[i]) {
        let state = n"Default";
        if Equals(this.m_tabNames[i], this.m_hover) {
          state = n"Hover";
        }
        if (i + 1) == this.m_tab {
          state = n"Selected";
        }
        this.m_gameTabLabel[i].SetTextState(state);
      }
      i += 1;
    }
    let r = 0;
    while r < ArraySize(this.m_rowBg) {
      if IsDefined(this.m_rowBg[r]) {
        let band = r % 2 == 0 ? CBHudBandEven() : CBHudBandOdd();
        let lit = false;
        if this.m_inTab {
          band = CBHudGameCell();
        }
        if this.m_rowClickable[r] && Equals(this.m_rowNames[r], this.m_hover) {
          band = this.m_inTab ? CBHudGameCellHot() : CBHudBandHover();
          lit = true;
        }
        if this.m_rowPicked[r] {
          band = this.m_inTab ? CBHudGameRowPicked() : CBHudBandPicked();
          lit = true;
        }
        if r < ArraySize(this.m_rowFrame) && IsDefined(this.m_rowFrame[r]) {
          this.m_rowFrame[r].SetTintColor(lit ? CBHudCyan() : CBHudGameCellEdge());
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
    if IsDefined(this.m_actionFrame) {
      let hotAction = this.m_actionOn && Equals(this.m_hover, CBHudActionName());
      this.m_actionFrame.SetTintColor(hotAction ? CBHudCyan() : (this.m_actionOn ? CBHudLabel() : CBHudDim()));
      if IsDefined(this.m_actionBg) {
        this.m_actionBg.SetTintColor(hotAction ? CBHudGameButtonHot() : CBHudGameButtonBack());
      }
      if IsDefined(this.m_actionText) {
        this.m_actionText.SetTintColor(this.m_actionOn ? CBHudCyan() : CBHudDim());
      }
    }
    let pe = 0;
    while pe < ArraySize(this.m_extraBox) {
      let on = this.m_extraOn[pe];
      let hot = on && Equals(this.m_hover, CBHudExtraActionName(pe + 1));
      if IsDefined(this.m_extraFrame[pe]) {
        this.m_extraFrame[pe].SetTintColor(hot ? CBHudCyan() : (on ? CBHudLabel() : CBHudDim()));
        if IsDefined(this.m_extraBg[pe]) {
          this.m_extraBg[pe].SetTintColor(hot ? CBHudGameButtonHot() : CBHudGameButtonBack());
        }
        if IsDefined(this.m_extraText[pe]) {
          this.m_extraText[pe].SetTintColor(on ? CBHudCyan() : CBHudDim());
        }
      } else {
        if IsDefined(this.m_extraBg[pe]) {
          this.m_extraBg[pe].SetTintColor(on ? (hot ? CBHudButtonHover() : CBHudButtonIdle()) : CBHudButtonOff());
        }
        if IsDefined(this.m_extraText[pe]) {
          this.m_extraText[pe].SetTintColor(on ? CBHudHead() : CBHudDim());
        }
      }
      pe += 1;
    }
    if IsDefined(this.m_settingsBg) {
      this.m_settingsBg.SetTintColor(Equals(this.m_hover, CBHudSettingsName()) ? CBHudButtonHover() : CBHudButtonIdle());
    }
    if IsDefined(this.m_prevBg) {
      this.m_prevBg.SetTintColor(Equals(this.m_hover, CBHudPrevName()) ? CBHudButtonHover() : CBHudButtonIdle());
    }
    if IsDefined(this.m_nextBg) {
      this.m_nextBg.SetTintColor(Equals(this.m_hover, CBHudNextName()) ? CBHudButtonHover() : CBHudButtonIdle());
    }
    this.PaintListButton(this.m_listUpBg, this.m_listUpText, CBHudListUpName());
    this.PaintListButton(this.m_listDownBg, this.m_listDownText, CBHudListDownName());
  }

  // Lit under the cursor, dimmed when there is nothing further that way.
  private func PaintListButton(bg: wref<inkWidget>, label: wref<inkText>, name: CName) -> Void {
    let live = this.IsLive(name);
    let hot = live && Equals(this.m_hover, name);
    if IsDefined(bg) {
      if this.m_inTab {
        bg.SetTintColor(hot ? CBHudGameButtonHot() : CBHudGameButtonBack());
      } else {
        bg.SetTintColor(hot ? CBHudButtonHover() : (live ? CBHudButtonIdle() : CBHudButtonOff()));
      }
    }
    if IsDefined(label) {
      label.SetTintColor(live ? (this.m_inTab ? CBHudCyan() : CBHudHead()) : CBHudDim());
    }
  }

  private func SetAction(label: String, enabled: Bool) -> Void {
    this.m_actionOn = enabled;
    if IsDefined(this.m_actionText) {
      this.m_actionText.SetText(CBHudFit(label, CBHudActionW() - 24.0, CBHudActionFont(), 1, true));
    }
    if IsDefined(this.m_actionBox) {
      this.m_actionBox.SetVisible(StrLen(label) > 0);
    }
  }

  // The same, for the buttons under it, numbered from 1. "" hides one.
  private func SetExtra(slot: Int32, label: String, enabled: Bool) -> Void {
    let k = slot - 1;
    if k < 0 || k >= ArraySize(this.m_extraBox) || k >= ArraySize(this.m_extraOn) {
      return;
    }
    this.m_extraOn[k] = enabled && StrLen(label) > 0;
    if IsDefined(this.m_extraText[k]) {
      this.m_extraText[k].SetText(CBHudFit(label, CBHudActionW() - 24.0, CBHudActionFont(), 1, true));
    }
    if IsDefined(this.m_extraBox[k]) {
      this.m_extraBox[k].SetVisible(StrLen(label) > 0);
    }
  }

  private func HideExtras() -> Void {
    let k = 1;
    while k <= ArraySize(this.m_extraBox) {
      this.SetExtra(k, "", false);
      k += 1;
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
        this.m_rowBox[r].SetMargin(this.PxAt(CBHudMarginX(), CBHudContentTop() + Cast<Float>(r) * stride));
        this.m_rowBox[r].SetSize(this.PxSize(rowW, rowH));
      }
      if IsDefined(this.m_rowPip[r]) {
        this.m_rowPip[r].SetSize(this.PxSize(5.0, rowH - 12.0));
        this.m_rowPip[r].SetMargin(this.PxAt(0.0, 6.0));
      }
      let c = 0;
      while c < CBHudRowCols() {
        let idx = r * CBHudRowCols() + c;
        if idx < ArraySize(this.m_rowCell) && IsDefined(this.m_rowCell[idx]) {
          if c == CBHudRowCols() - 1 {
            this.m_rowCell[idx].SetSize(this.PxSize(rowW - 16.0, 28.0));
            this.m_rowCell[idx].SetMargin(this.PxAt(0.0, textY + 2.0));
          } else {
            this.m_rowCell[idx].SetMargin(this.PxAt(CBHudRowColX(c, layout), textY + (c == 0 ? 0.0 : 2.0)));
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
    this.m_barFill[idx].SetSize(this.PxSize(reach, 10.0));
    this.m_barFill[idx].SetMargin(this.PxAt(CBHudMarginX() + left, CBHudContentTop() + Cast<Float>(idx) * 96.0 + 36.0));
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
      this.m_barFill[idx].SetMargin(this.PxAt(CBHudMarginX(), CBHudContentTop() + Cast<Float>(idx) * 96.0 + 36.0));
      this.m_barFill[idx].SetSize(this.PxSize(w, 10.0));
      this.m_barFill[idx].SetTintColor(col);
      this.m_barFill[idx].SetVisible(true);
    }
    if IsDefined(this.m_barCap[idx]) {
      // One line: the next meter starts 42 px below this caption, and a second line would be
      // drawn over its label.
      this.m_barCap[idx].SetText(CBHudFit(caption, CBHudContentW(), 19, 1));
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
  // `bottom`, when given, is where the prose must stop instead of the footer: something else is
  // drawn below it across the same width.
  private func SetBody(x: Float, y: Float, width: Float, text: String, maxLines: Int32,
                       opt bottom: Float) -> Void {
    if !IsDefined(this.m_body) {
      return;
    }
    this.m_body.SetMargin(this.PxAt(x, y));
    this.m_body.SetWrapping(true, this.Px(width));
    // As many lines as there is room for above the footer, never more than the screen asked for.
    let room = (bottom > 0.0 ? bottom : CBHudFooterY() - CBHudFooterGap()) - y;
    let fits = Cast<Int32>(room / CBHudLineHeight(CBHudBodyFont()));
    this.m_body.SetSize(this.PxSize(width, MaxF(room, 0.0)));
    this.m_body.SetText(CBHudFit(text, width, CBHudBodyFont(), Min(maxLines, fits)));
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
      s"How frightening you are. The street reads it as \(RoundF(civ)): that is what makes people back off.");

    this.SetBar(2, "Visible chrome", s"\(RoundF(chrome))",
      chrome / 100.0, CBHudAmber(),
      "What a stranger clocks from across the street. Arms read loudest.");

    this.SetBipolarBar(3, "Conduct", s"\(RoundF(code))   \(CBCodeLabel(code))",
      code, code < 0.0 ? CBHudRed() : CBHudGreen(),
      "Clean and controlled, or one bad night from going over. Runs both ways from the middle.");
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
    // Every gang, the hostile ones first, and the page shows a window onto it. It used to stop at
    // the tenth, and there are sixteen.
    let states = sys.GetFactionStates();
    let order: array<ref<CBFactionState>>;
    let sweep = 0;
    while sweep < 2 {
      let i = 0;
      while i < ArraySize(states) {
        let fs = states[i];
        i += 1;
        if IsDefined(fs) {
          let posture = score.GetPosture(fs.id);
          let hostile = Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta);
          if (sweep == 0 && hostile) || (sweep == 1 && !hostile) {
            ArrayPush(order, fs);
          }
        }
      }
      sweep += 1;
    }
    // A pick that is no longer on the list (reset, or forgotten) is no pick. Scrolled out of view
    // is still a pick: the panel underneath goes on showing it.
    let pickedOn = false;
    let k = 0;
    while k < ArraySize(order) {
      if Equals(order[k].id, this.m_pickFaction) {
        pickedOn = true;
      }
      k += 1;
    }
    if !pickedOn {
      this.m_pickFaction = n"";
    }
    let top = this.ListWindow(ArraySize(order), CBHudListRows());
    let row = 0;
    while row < CBHudListRows() && top + row < ArraySize(order) {
      let shownFs = order[top + row];
      this.RenderFactionRow(sys, score, shownFs, score.GetPosture(shownFs.id), row,
                            Equals(shownFs.id, this.m_pickFaction));
      row += 1;
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
      right = "PAYING OFF";
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
      out += "You are paying them " + price + ". It goes through in the next few seconds of play,\nand anything they had on its way to you is called off.";
      this.SetAction("Cancel the payment", true);
    } else {
      if quote >= 0 {
        out += s"They will call it off for \(quote)eb. You have \(money)eb.";
        if money >= quote {
          if Equals(this.m_payArmed, id) {
            out += "\nClick again to pay.";
            this.SetAction(s"Confirm: pay \(quote)eb", true);
          } else {
            this.SetAction(s"Pay them off: \(quote)eb", true);
          }
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
        // The one written down, once somebody has been: the shares are only who is ahead today.
        let written = CBTurfHolder(sys, game, district);
        k = 0;
        while k < ArraySize(ids) {
          if Equals(ids[k], written) {
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
        let status = CBHudTurfStatus(game, content, district, holder, ids, shares, second);
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
    // Everybody still after V, and the page shows a window onto it. It used to stop at ten, and the
    // setting goes higher: "I have 14 max rivals but can see 10".
    //
    // The one who is actually coming goes first, so the name the Standing screen gives as incoming
    // is always at the top of this screen, whatever the cap is.
    let order: array<ref<CBRival>>;
    let queuedId = sys.GetLaneRivalId(CBLaneRival());
    let pinned = sys.FindRivalById(queuedId);
    if IsDefined(pinned) && (pinned.state == EnumInt(ECBRivalState.Active)
                             || pinned.state == EnumInt(ECBRivalState.Hunting)) {
      ArrayPush(order, pinned);
    } else {
      queuedId = 0;
    }
    let i = 0;
    while i < ArraySize(rivals) {
      let r = rivals[i];
      i += 1;
      // Skipping the pinned one by id rather than by `continue`, which redscript does not have.
      if IsDefined(r) && r.id != queuedId
         && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        ArrayPush(order, r);
      }
    }
    // The one that was picked is gone (put down, forgotten), or nobody was: the top of the list,
    // which is whoever is next, rather than an empty panel. Scrolled out of view is still picked.
    let pickedOn = false;
    let k = 0;
    while k < ArraySize(order) {
      if order[k].id == this.m_pickRival {
        pickedOn = true;
      }
      k += 1;
    }
    if !pickedOn {
      this.m_pickRival = ArraySize(order) > 0 ? order[0].id : 0;
    }
    let top = this.ListWindow(ArraySize(order), CBHudListRows());
    let row = 0;
    while row < CBHudListRows() && top + row < ArraySize(order) {
      this.RenderRivalRow(sys, content, order[top + row], row);
      row += 1;
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

  // The panel under the Rivals: the file on the one you clicked, and three buttons beside it - buy
  // where they are, forget them, forget everybody. Each asks twice, and each can be taken back until
  // the game is unpaused, when it is carried out.
  private func RenderRivalDetail(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let top = CBHudContentTop() + Cast<Float>(CBHudListRows()) * CBHudRowHeight() + 24.0;
    let width = CBHudContentW() - CBHudActionW() - 40.0;
    let count = sys.CountActiveRivals();
    if count <= 0 && !sys.IsRivalPurgePending() {
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), CBHudRivals(sys, game, 0), CBHudMaxLinesFor(this.m_tab));
      return;
    }
    if sys.IsRivalPurgePending() {
      // Where "Forget every rival" was, so taking it back is the same place clicked again.
      this.SetExtra(2, "Keep them", true);
    } else {
      let id = this.m_pickRival;
      let r = sys.FindRivalById(id);
      // 1. Where they are.
      let pending = sys.GetPendingFind();
      if pending > 0 && pending == id {
        this.SetAction("Cancel the payment", true);
      } else {
        if pending > 0 {
          this.SetAction("Buying another location", false);
        } else {
          let why = CBWhereaboutsForSale(sys, game, r);
          let price = CBWhereaboutsPrice(r);
          if why == 0 {
            if CBHudEddies(game) >= price {
              this.SetAction(this.m_findArmed == id ? s"Confirm: pay \(price)eb" : s"Ambush them: \(price)eb", true);
            } else {
              this.SetAction("Not enough eddies", false);
            }
          } else {
            if why == 1 {
              this.SetAction("Hideouts are off", false);
            } else {
              if why == 2 {
                this.SetAction("Out after you now", false);
              } else {
                if why == 3 {
                  this.SetAction("You know where they are", false);
                }
              }
            }
          }
        }
      }
      // 2. Forget them.
      if sys.IsRivalForgetPending(id) {
        this.SetExtra(1, "Keep this one", true);
      } else {
        if IsDefined(r) && !CBRivalForgettable(sys, r) {
          this.SetExtra(1, "On their way: wait", false);
        } else {
          this.SetExtra(1, this.m_forgetArmed == id ? "Click again to forget" : "Forget this rival", IsDefined(r));
        }
      }
      // 3. Forget everybody.
      this.SetExtra(2, this.m_purgeArmed ? s"Click again: forget all \(count)" : "Forget every rival", true);
    }
    this.SetBody(CBHudMarginX(), top, width, CBHudRivals(sys, game, this.m_pickRival, this.m_findArmed, this.m_forgetArmed),
                 CBHudMaxLinesFor(this.m_tab));
  }

  // The titles, as a list you can click. Automatic first, then every one V has earned - all of
  // them: this screen used to show the first eight and say nothing about the rest.
  private func RenderTitles(sys: ref<CyberbaneSystem>) -> Void {
    this.PlaceRows(CBHudLayoutTitles());
    let content = sys.GetContent();
    let chosen = sys.GetChosenTitle();
    let reading = this.m_titlePicked ? this.m_titlePick : chosen;
    let earned = sys.GetUnlockedTitles();
    let onAuto = Equals(chosen, n"");
    let autoLabel = ArraySize(earned) > 0 ? "Automatic: " + CBHudActiveTitle(sys) : "Automatic";
    this.SetRow(0, CBHudLayoutTitles(), onAuto ? CBHudCyan() : CBHudGrey(), true, Equals(reading, n""),
      autoLabel, "", "", "", "", onAuto ? "GOING BY" : "");
    this.m_rowTitle[0] = n"";
    if !IsDefined(content) {
      return;
    }
    // Earned first, then the rest. One row each and the whole list fits the pool, with no scrolling.
    let row = 1;
    let pass = 0;
    while pass < 2 {
      for def in content.GetTitles() {
        if IsDefined(def) && Equals(sys.HasTitle(def.id), pass == 0) && row < CBHudRowPool() {
          let mine = Equals(def.id, chosen);
          let status = mine ? "GOING BY" : "EARNED";
          if pass == 1 {
            status = CBTitleProgress(sys, def.id);
            if StrLen(status) == 0 {
              status = "LOCKED";
            }
          }
          this.SetRow(row, CBHudLayoutTitles(), mine ? CBHudCyan() : (pass == 0 ? CBHudAmber() : CBHudGrey()), true,
            Equals(def.id, reading), CBTitleDisplay(sys, def), "", "", "", "", status);
          this.m_rowTitle[row] = def.id;
          row += 1;
        }
      }
      pass += 1;
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
      this.m_subhead.SetText(CBHudFit(titleName + "   |   " + tier, CBHudContentW(), 24, 1));
    }
    if IsDefined(this.m_tabline) {
      this.m_tabline.SetText(CBHudFit(CBHudTabBlurb(this.m_tab), CBHudContentW(), 20, 1));
    }

    this.HideBars();
    this.HideRows();
    this.SetAction("", false);
    this.HideExtras();
    this.m_listTotal = 0;
    this.m_listRows = 0;
    if IsDefined(this.m_listMore) {
      this.m_listMore.SetVisible(false);
    }
    if IsDefined(this.m_listUpBox) {
      this.m_listUpBox.SetVisible(false);
    }
    if IsDefined(this.m_listDownBox) {
      this.m_listDownBox.SetVisible(false);
    }

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
                this.SetBody(colX, CBHudContentTop(), w - CBHudTitleListW() - 60.0,
                             CBHudTitles(sys, this.m_titlePicked ? this.m_titlePick : sys.GetChosenTitle()), maxLines);
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
                  this.SetAction("Click again: erase it all", true);
                } else {
                  this.SetAction("Start over", true);
                }
                // Full width, but it stops above the button: run on to the footer, the ledger's last
                // lines were drawn underneath Start over.
                this.SetBody(x, CBHudContentTop(), w, CBHudLog(sys), maxLines,
                             CBHudDetailTop() - 4.0 - CBHudFooterGap());
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

// inkText does not clip to its box: hand it more than fits and it renders straight over the
// footer, the button beside it, or off the panel. So nothing reaches the page without being fitted
// to the box it goes in first. Truncation, at a word, is the failure mode - never overlap.
//
// This used to count lines by the line breaks in the text, which is not what the screen does: a
// sentence with no break in it wraps onto two or three lines and counted as one, so a long Rival
// file or a long gang note ran on down into the footer. Wrapping is now worked out the way the
// text box does it - word by word against the width - from a deliberately generous estimate of
// how wide a character is, so the estimate can only ever err towards cutting a line short.

// Average width of a character as a fraction of the font size, for the menu font. Generous on
// purpose; capitals are wider, so text drawn upper case gets its own figure.
public func CBHudCharEm() -> Float = 0.58
public func CBHudCapsEm() -> Float = 0.70
public func CBHudLineHeight(fontSize: Int32) -> Float {
  return Cast<Float>(fontSize) * 1.32;
}

public func CBHudCharsPerLine(width: Float, fontSize: Int32, opt caps: Bool) -> Int32 {
  let em = caps ? CBHudCapsEm() : CBHudCharEm();
  let per = Cast<Float>(Max(fontSize, 1)) * em;
  return Max(6, Cast<Int32>(width / per));
}

// How many lines one paragraph (no line breaks in it) takes once wrapped at `cpl` characters.
public func CBHudWrapCount(line: String, cpl: Int32) -> Int32 {
  if StrLen(line) <= cpl {
    return 1;
  }
  let words = StrSplit(line, " ");
  let lines = 1;
  let run = 0;
  let i = 0;
  while i < ArraySize(words) {
    let n = StrLen(words[i]);
    if n > cpl {
      // A word longer than the line is broken by the box; count every line it fills.
      if run > 0 {
        lines += 1;
      }
      lines += (n - 1) / cpl;
      run = n % cpl;
    } else {
      let need = run == 0 ? n : run + 1 + n;
      if need > cpl {
        lines += 1;
        run = n;
      } else {
        run = need;
      }
    }
    i += 1;
  }
  return lines;
}

// The words of one paragraph that fit in `room` lines, with " ..." on the end to say there was
// more. Empty if there is no room at all.
public func CBHudCutToLines(line: String, cpl: Int32, room: Int32) -> String {
  if room <= 0 {
    return "";
  }
  let words = StrSplit(line, " ");
  let out = "";
  let lines = 1;
  let run = 0;
  let i = 0;
  while i < ArraySize(words) {
    let w = words[i];
    let n = StrLen(w);
    // The last line keeps four characters back for the marker.
    let limit = lines == room ? cpl - 4 : cpl;
    let need = run == 0 ? n : run + 1 + n;
    if need > limit {
      if lines == room || n > cpl {
        return out + " ...";
      }
      lines += 1;
      run = n;
      out += " " + w;
    } else {
      out += run == 0 ? w : " " + w;
      run = need;
    }
    i += 1;
  }
  return out;
}

// Fit text to a box `width` wide that has room for `maxLines` lines at this font size.
public func CBHudFit(text: String, width: Float, fontSize: Int32, maxLines: Int32,
                     opt caps: Bool) -> String {
  if maxLines <= 0 || StrLen(text) == 0 {
    return "";
  }
  let cpl = CBHudCharsPerLine(width, fontSize, caps);
  let paras = StrSplit(text, "\n");
  let out = "";
  let used = 0;
  let i = 0;
  while i < ArraySize(paras) {
    let para = paras[i];
    let need = CBHudWrapCount(para, cpl);
    let room = maxLines - used;
    let last = i == ArraySize(paras) - 1;
    // Fits, and either it is the end or there is still a line left after it for what follows.
    if need < room || (need == room && last) {
      out += i == 0 ? para : "\n" + para;
      used += need;
    } else {
      let cut = CBHudCutToLines(para, cpl, room);
      if StrLen(cut) > 0 {
        out += i == 0 ? cut : "\n" + cut;
      } else {
        out += " ...";
      }
      return out;
    }
    i += 1;
  }
  return out;
}

// Kept for anything that only knows a line count. Fits against the full content width.
func CBHudClamp(text: String, maxLines: Int32) -> String {
  return CBHudFit(text, CBHudContentW(), 21, maxLines);
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
    return s"Right now: your face is covered, so nobody can place you and nobody reacts. (\(reg.Count()) tracked)";
  }
  let chromeVisible = score.GetChromeVisible();
  // The crowd's own number, from the crowd's own formula, including the intensity slider the
  // player set. Working it out separately here is what let this screen disagree with the street.
  let eff = CBCrowdFear(score, CBCivIntensity());
  let reach = 1.0 + (chromeVisible / 100.0) * CBConfig.ChromeNoticeRangeBonus();
  if eff >= CBConfig.CivFearRun() {
    let r = RoundF(CBConfig.CivFleeRadius() * reach);
    return s"Right now: people run when you come within \(r) metres. (\(reg.Count()) tracked)";
  }
  if eff >= CBConfig.CivFearCower() {
    let r = RoundF(CBConfig.CivCowerRadius() * reach);
    return s"Right now: people freeze with their hands up within \(r) metres, and step aside further out. (\(reg.Count()) tracked)";
  }
  if eff >= CBConfig.CivFearStartle() {
    let r = RoundF(CBConfig.CivStartleRadius() * reach);
    return s"Right now: people flinch and step out of your way within \(r) metres. (\(reg.Count()) tracked)";
  }
  if eff >= CBConfig.CivFearGlance() {
    let r = RoundF(CBConfig.CivGlanceRadius() * reach);
    return s"Right now: people look over at you within \(r) metres. (\(reg.Count()) tracked)";
  }
  let need = RoundF(CBConfig.CivFearGlance() - eff);
  return s"Right now: nobody looks twice yet, about \(need) short. (\(reg.Count()) tracked)";
}

// Plain-language line: what is driving V's Dread the most (spec §12.1).
func CBHudDreadReason(sys: ref<CyberbaneSystem>) -> String {
  let score = sys.GetScore();
  // Weighted by what each one actually contributes to Dread, not the raw score. Comparing
  // the raw numbers meant chrome (capped at 100, weighted 0.20) beat a body count (weighted
  // 0.35) whenever its number was bigger, so the Hub kept telling players they were feared
  // for their chrome after hundreds of kills. Dread is
  // 0.35K + 0.20C + 0.15L + 0.20X + 0.10H, so the comparison has to use the same weights.
  //
  // Visible chrome, the same figure Dread is built from (Model/ScoreEngine.reds). This read the
  // chrome V has installed, so a player who had put a coat on over it was still told they were
  // feared for their chrome - and covering it up is exactly what they would have tried.
  let k = CBKillDreadComponent(sys.GetKillDreadPoints()) * CBConfig.DreadWeightK();
  let x = CBDeedDreadComponent(sys.GetDeedDreadPoints()) * CBConfig.DreadWeightX();
  let h = CBHeatDreadComponent(sys.GetHeatPoints()) * CBConfig.DreadWeightH();
  let c = score.GetChromeVisible() * CBConfig.DreadWeightC();
  let l = score.GetLook() * CBConfig.DreadWeightL();

  let bestLabel = "nothing in particular yet";
  let bestHint = "";
  let best = 0.0;
  if k > best { best = k; bestLabel = "your body count"; bestHint = "It fades while you lie low."; }
  if c > best { best = c; bestLabel = "all that chrome"; bestHint = "Cover it up and they see less of it."; }
  if l > best { best = l; bestLabel = "the way you carry yourself"; bestHint = "Dress down and it eases."; }
  if x > best { best = x; bestLabel = "the jobs you have pulled"; bestHint = "The stories fade while you lie low."; }
  if h > best { best = h; bestLabel = "the heat you draw from the law"; bestHint = "Stay off the NCPD's radar and it cools."; }

  if best <= 0.0 {
    return "People barely know you. Make some noise.";
  }
  // What it is, then the one thing that brings it down: the question a player looking at this
  // line is asking. One line, so the screen stays as quiet as it was.
  return "People fear you mostly for " + bestLabel + ". " + bestHint;
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
func CBHudTurfStatus(game: GameInstance, content: ref<CyberbaneContent>, district: CName, holder: CName,
                     ids: array<CName>, shares: array<Float>, second: Int32) -> String {
  if !IsDefined(content) {
    return "";
  }
  let sealedDef = content.GetDistrict(district);
  if IsDefined(sealedDef) && sealedDef.sealed {
    return "WALLED OFF";
  }
  let book = CBTurfBook.Get(game);
  if IsDefined(book) && NotEquals(book.Challenger(CBDistrictIndex(district)), n"") {
    return s"\(CBBarFactionLabel(book.Challenger(CBDistrictIndex(district)))) MOVING IN";
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
  return out + "They rebuild while you leave them alone, and your work counts double on their own streets. Break one and the gang at war with it next door moves in, and stays until somebody takes it back.";
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

func CBHudRivals(sys: ref<CyberbaneSystem>, game: GameInstance, pickedId: Int32, opt findArmed: Int32,
                 opt forgetArmed: Int32) -> String {
  if sys.IsRivalPurgePending() {
    return "Every rival is forgotten in the next few seconds of play.\n\nThe ones out looking for you stop, and nobody on this list comes after you again.\nIt sticks: quitting now, or loading an older save of this playthrough, forgets them too.\nClick the button again to keep them after all.";
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
    // What is about to happen to them, or where they are: one line, near the top, so nothing that
    // matters is what the panel cuts when it runs out of room (CBHudFit).
    out += CBHudRivalWhere(sys, game, r, findArmed, forgetArmed) + "\n";
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
// The whereabouts line in a Rival's file (CBHudRivals).
func CBHudRivalWhere(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, findArmed: Int32,
                     forgetArmed: Int32) -> String {
  if sys.IsRivalForgetPending(r.id) {
    return "Forgotten as soon as you are back in the game, on this save and every other of this playthrough.";
  }
  if forgetArmed == r.id {
    return "Click again to forget them. Until you go back to the game, you can still keep them.";
  }
  let price = CBWhereaboutsPrice(r);
  if sys.GetPendingFind() == r.id {
    return s"Paying \(price)eb for where they are. It goes through as soon as you are back in the game.";
  }
  if sys.IsLairActive() && sys.GetLairRivalId() == r.id {
    return "Waiting at their place right now, and not expecting you.";
  }
  // Somebody told V where they were seen (Rivals/Whereabouts.reds).
  let lead = CBCurrentLead(sys, game);
  if IsDefined(lead) && lead.rivalId == r.id {
    let from = IsNameValid(lead.tipFaction) ? CBFactionLabel(lead.tipFaction) : "the street";
    let ago = CBHudSince(CBGameSeconds(game), lead.seenAt);
    let when = StrLen(ago) > 0 ? ", " + ago + " ago" : "";
    return s"Word from \(from): seen \(CBPlacePhrase(lead.district))\(when). Go on foot and they may not see you coming.";
  }
  let why = CBWhereaboutsForSale(sys, game, r);
  if why == 0 {
    if findArmed == r.id {
      return s"Click again to pay \(price)eb for where they are hiding.";
    }
    return s"\(price)eb buys where they are hiding. Go there on foot and catch them unawares. You have \(CBHudEddies(game))eb.";
  }
  if why == 1 {
    return "Turn on Rival hideouts in Mod Settings to buy where they are hiding.";
  }
  return "Nobody sells where they are while they are out after you.";
}

// Whether the whereabouts button may take a click: for sale, affordable, and no other purchase waiting.
func CBHudCanFind(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32) -> Bool {
  let r = sys.FindRivalById(id);
  if !IsDefined(r) || sys.GetPendingFind() > 0 || CBWhereaboutsForSale(sys, game, r) != 0 {
    return false;
  }
  return CBHudEddies(game) >= CBWhereaboutsPrice(r);
}

func CBHudTitles(sys: ref<CyberbaneSystem>, id: CName) -> String {
  let content = sys.GetContent();
  if !IsDefined(content) {
    return "";
  }
  let out = "";
  let worn = sys.GetActiveTitle();
  let shown = id;
  if Equals(id, n"") {
    out += "AUTOMATIC\n";
    if Equals(worn, n"") {
      return out + "You go by the best title you earn. You have not earned one yet. Click any title to see what it takes and what it does.";
    }
    out += "You go by the best title you have earned, which is " + CBTitleDisplayById(sys, content, worn) + ".\n";
    shown = worn;
  } else {
    out += StrUpper(CBTitleDisplayById(sys, content, id)) + "\n";
    if sys.HasTitle(id) {
      out += Equals(id, worn) ? "You go by this.\n" : "Earned.\n";
    } else {
      out += "Not earned yet.\n";
    }
    let need = CBTitleRequirement(sys, id);
    if StrLen(need) > 0 {
      out += "\nWHAT IT TAKES\n" + need + "\n";
    }
  }
  let def = content.GetTitle(shown);
  if IsDefined(def) && StrLen(def.effect) > 0 {
    out += "\nWHAT IT DOES\n" + def.effect + "\n";
  }
  out += CBTitlesDoThings() ? "\nOnly the title you go by has any effect." : "\nTitle effects are switched off in Mod Settings.";
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
              line = StrLen(gang) > 0 ? "You put down one of " + CBPossessive(gang) + " apex squad." : "You put down one of an apex squad.";
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
                            if Equals(e.kind, n"TurfPush") {
                              line = s"\(gangCap) came back to take their streets.";
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
