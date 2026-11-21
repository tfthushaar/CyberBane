import Codeware.UI.*   // HubTextInput, the crew's name box (2.6.0)

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

// Eight screens (2.5.0: the crew joined them). Messages are not one of them: they live in V's phone (UI/RealPhone.reds).
public func CBHudTabCount() -> Int32 = 8
public func CBHudStandingTab() -> Int32 = 1
public func CBHudFactionsTab() -> Int32 = 2
// Next to GANGS on purpose: what the gangs think of V, then what V has done to their streets.
public func CBHudTurfTab() -> Int32 = 3
public func CBHudCityTab() -> Int32 = 4
public func CBHudRivalsTab() -> Int32 = 5
// Next to the Rivals: the people against V, then the people with V (Reactions/Crew.reds, 2.5.0).
public func CBHudCrewTab() -> Int32 = 6
public func CBHudTitlesTab() -> Int32 = 7
public func CBHudHistoryTab() -> Int32 = 8

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
  if tab == CBHudCrewTab() {
    return 12;   // under six rows at most
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
public func CBHudChipWidth() -> Float = 156.0
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
public func CBHudExtraActions() -> Int32 = 3
// The Crew page's orders list: the row that lets one go, after the kit's asks (CBCrewAskGive .. CBCrewAskWork).
public func CBHudCrewOrderLetGo() -> Int32 = 8
public func CBHudActionGap() -> Float = 8.0

// Row layouts, as the columns are positioned for them.
public func CBHudLayoutGangs() -> Int32 = 0
public func CBHudLayoutWide() -> Int32 = 1
public func CBHudLayoutTitles() -> Int32 = 2
public func CBHudLayoutCrew() -> Int32 = 3    // the crew (2.5.0)
public func CBHudLayoutLanes() -> Int32 = 4   // what is on its way, on Standing (2.5.0)

// A bar drawn in a row (2.5.0): where it sits on each screen, so no column's text runs under it. Gangs: standing, from
// the middle. The city and turf: renown and share, where the text meters were. Rivals: rank, and a gang's strength.
// The crew: loyalty.
public func CBHudRowBarH() -> Float = 10.0
public func CBHudGangBarX() -> Float = 384.0
public func CBHudGangBarW() -> Float = 88.0
public func CBHudWideBarX() -> Float = 411.0
public func CBHudWideBarW() -> Float = 196.0
public func CBHudRankBarX() -> Float = 954.0
public func CBHudRankBarW() -> Float = 84.0
public func CBHudCrewBarX() -> Float = 884.0
public func CBHudCrewBarW() -> Float = 120.0
// The smallest a cell's text is drawn when it is too long for its column: smaller than this, it is shortened at a word.
public func CBHudMinCellFont() -> Int32 = 16
public func CBHudBarTrack() -> HDRColor = new HDRColor(0.26, 0.08, 0.10, 0.90)
// A bar is ten segments, the way the game draws its own meters (2.5.0); and the gap between them.
public func CBHudBarSegs() -> Int32 = 10
public func CBHudBarGap() -> Float = 2.0

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

// The same, but at a word: what is left ends on a whole word and says there was more. Only a single word longer than
// the whole column is ever cut inside itself (2.5.0).
public func CBHudTrimWords(text: String, maxChars: Int32) -> String {
  if StrLen(text) <= maxChars {
    return text;
  }
  if maxChars <= 4 {
    return CBHudTrim(text, maxChars);
  }
  let words = StrSplit(text, " ");
  let out = "";
  let i = 0;
  while i < ArraySize(words) {
    let next = StrLen(out) == 0 ? words[i] : out + " " + words[i];
    if StrLen(next) + 3 > maxChars {
      return StrLen(out) > 0 ? out + "..." : CBHudTrim(text, maxChars);
    }
    out = next;
    i += 1;
  }
  return out;
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
    if col == 2 { return 484.0; }
    if col == 3 { return 596.0; }
    if col == 4 { return 790.0; }
  } else {
    if layout == CBHudLayoutCrew() {
      if col == 0 { return 21.0; }
      if col == 1 { return 350.0; }
      if col == 2 { return 486.0; }
      if col == 3 { return 586.0; }
      return 0.0;
    }
    if layout == CBHudLayoutLanes() {
      if col == 0 { return 21.0; }
      if col == 1 { return 236.0; }
      return 0.0;
    }
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
    if col == 1 { return 11; }
    if col == 2 { return 8; }
    if col == 3 { return 14; }
    if col == 4 { return 9; }
    return 22;
  }
  if layout == CBHudLayoutCrew() {
    if col == 0 { return 24; }
    if col == 1 { return 10; }
    if col == 2 { return 7; }
    if col == 3 { return 22; }
    if col == 4 { return 0; }
    return 12;
  }
  if layout == CBHudLayoutLanes() {
    if col == 0 { return 15; }
    if col == 1 { return 58; }
    if col == 5 { return 16; }
    return 0;
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
    case 6: return "CREW";
    case 7: return "TITLES";
    case 8: return "HISTORY";
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
    case 6: return "The people who work for you: who is ready, who is restless, and what they are owed.";
    case 7: return "What the street calls you and what it gets you. Click any title to read it, or go by one you have earned.";
    case 8: return "The ledger: what you did, where, and who it was.";
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
  private let m_rowSeg: array<wref<inkRectangle>>;     // a bar in each row, ten segments (row r at r * CBHudBarSegs())
  private let m_rowTop: Float;                          // where the first row sits on this screen
  private let m_rowCrew: array<Int32>;                  // the crew member a row stands for (2.5.0); -1 the solo on offer
  private let m_pickCrew: Int32;
  private let m_letGoArmed: Int32;
  // The Crew page's screens (2.6.0): 0 the roster, 1 picking a weapon, 2 picking chrome, 3 picking a gang for a war,
  // 4 naming the crew, 5 the memorial, 6 the picked one's orders, 7 the crew itself; what is on offer in the list, the
  // name box, the memorial's pick (one up), and whether the Gangs page drew the crew's card.
  private let m_crewMode: Int32;
  private let m_pickFallen: Int32;
  private let m_crewCardShown: Bool;
  private let m_pickItems: array<ItemID>;
  private let m_pickGangs: array<CName>;
  private let m_nameInput: ref<HubTextInput>;
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
  private let m_bountyArmed: Bool;         // and so does paying off the price on V's head (2.4.3)
  private let m_legendShown: Bool;         // the History page tells V's story instead of the ledger (2.4.6)
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
  // Another mod's overlay this page has put out of sight while it is up (CBForeignOverlays, 2.4.2).
  private let m_overlaysOff: Bool;
  // The web of gangs ([H1], UI/HubWeb.reds, 2.4.3): the Factions page as a picture. A pool built once with the page and
  // hidden until used: the lines first so they sit under the boxes, then the words, then a box per place.
  private let m_webRoot: wref<inkCanvas>;
  private let m_webLine: array<wref<inkRectangle>>;
  private let m_webWord: array<wref<inkText>>;
  private let m_webBox: array<wref<inkCanvas>>;
  private let m_webBoxBg: array<wref<inkRectangle>>;
  private let m_webBoxEdge: array<wref<inkRectangle>>;
  private let m_webBoxName: array<wref<inkText>>;
  private let m_webBoxLine: array<wref<inkText>>;
  private let m_webBoxLead: array<wref<inkText>>;
  private let m_webBarMen: array<wref<inkRectangle>>;
  private let m_webBarChest: array<wref<inkRectangle>>;
  private let m_webBoxNames: array<CName>;
  private let m_webToggle: wref<inkCanvas>;
  private let m_webToggleBg: wref<inkRectangle>;
  private let m_webToggleText: wref<inkText>;
  private let m_webShown: Bool;
  // The Rivals tree ([H2], 2.4.4) draws with the same pool: which gang it shows, whether it is up, and the Rival in
  // each place (0 for none).
  private let m_treeShown: Bool;
  private let m_treeGang: CName;
  private let m_treeNemesis: Int32;   // the Rival of the gang drawn V has met most, for their box (2.5.0)
  private let m_webOrder: array<Int32>; // the gangs' cards, slot by slot, in the order they are shown (2.5.0)
  private let m_hereSlot: Int32;        // the district card V is in, framed white on the maps (2.5.0)
  private let m_actionTop: Float;     // where the buttons start on this page (PlaceActions)
  private let m_treeSlotRival: array<Int32>;
  // The pictures' look (2.5.0): every box a card of the game's own art, a frame tinted by what it is and cyan when
  // picked; two segmented bars a box (box s, bar b, segment k at (s * 2 + b) * CBHudBarSegs() + k); a soft glow under
  // every line. And the four Standing tiles drawn as cards.
  private let m_webBoxArt: array<wref<inkImage>>;
  private let m_webBoxFrame: array<wref<inkImage>>;
  private let m_webSeg: array<wref<inkRectangle>>;
  private let m_webGlow: array<wref<inkRectangle>>;
  private let m_tileArt: array<wref<inkImage>>;
  private let m_tileFrame: array<wref<inkImage>>;
  // The same pool draws two pictures more (2.5.0): Night City as a map on the Turf and City pages, and V's crew round V.
  private let m_mapShown: Bool;
  private let m_crewPicShown: Bool;
  private let m_pickDistrict: CName;
  private let m_boxDistrict: array<CName>;   // the district each box stands for on the map
  private let m_boxCrew: array<Int32>;       // the crew member each box stands for (-1 the solo on offer)

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
    this.m_bountyArmed = false;
    this.m_payArmed = n"";
    this.m_findArmed = 0;
    this.m_forgetArmed = 0;
    this.m_letGoArmed = 0;
    this.m_listTop = 0;
    this.m_listScrolled = false;
    this.m_hover = n"";
    CBHudResampleWorn(sys, game);
    this.Render(sys, game);
    return true;
  }

  // Out of sight. Nothing is removed: the widgets stay in the menu's tree until the menu goes,
  // because taking widgets out by hand is what the 1.4.7 phone crash was made of.
  public func Hide() -> Void {
    this.m_open = false;
    this.m_purgeArmed = false;
    this.m_resetArmed = false;
    this.m_bountyArmed = false;
    this.m_payArmed = n"";
    this.m_findArmed = 0;
    this.m_forgetArmed = 0;
    this.m_hover = n"";
    if IsDefined(this.m_root) {
      this.m_root.SetVisible(false);
    }
    this.ForeignOverlaysBack();
  }

  // Another mod's text drawn over the menu as a whole, where this page sits, goes out of sight while the
  // page is up and comes back when it goes (2.4.2). They Will Remember writes its disguise scores on the
  // menu layer whenever V's paperdoll is set up, at a place fixed for the inventory screens, and on this
  // page it landed across the title and the first lines. It hides that text itself while a weapon tooltip
  // covers the spot, by its name (DisguiseScoresUI.reds, Journal.SetTooltipOpen); this does the same for a
  // page it does not know about. Nothing of theirs is removed or changed but whether it shows, and what it
  // says is on this page instead, under the chrome bar (CBHudWornLine). Asked at every draw and as the page
  // comes up, since the paperdoll can be set up after the page is.
  private func ForeignOverlaysOff() -> Void {
    if CBForeignOverlays(false) {
      this.m_overlaysOff = true;
    }
  }

  private func ForeignOverlaysBack() -> Void {
    if this.m_overlaysOff {
      this.m_overlaysOff = false;
      CBForeignOverlays(true);
    }
  }

  // The pause menu is going. Hand every callback back while the widgets still exist, then let go.
  // Called from the menu's OnUninitialize, before the game starts dismantling it.
  public func Detach() -> Void {
    this.ForeignOverlaysBack();
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
    this.ForeignOverlaysOff();
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
    if Equals(name, CBHudWebToggleName()) {
      return CBHudHasPicture(this.m_tab);
    }
    let wbox = this.WebIndex(name);
    if wbox >= 0 {
      if this.m_mapShown {
        return wbox < ArraySize(this.m_boxDistrict) && NotEquals(this.m_boxDistrict[wbox], n"");
      }
      if this.m_crewPicShown {
        return wbox < ArraySize(this.m_boxCrew) && this.m_boxCrew[wbox] != 0;
      }
      return this.m_webShown || this.m_treeShown;
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

  // The same art as a free piece of the page, placed and sized by whoever uses it (the Standing tiles, 2.5.0).
  private func NewPanelArt(panel: ref<inkCanvas>, part: CName, tint: HDRColor) -> ref<inkImage> {
    let art = new inkImage();
    art.SetAtlasResource(r"base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");
    art.SetTexturePart(part);
    art.SetNineSliceScale(true);
    art.SetNineSliceGrid(new inkMargin(0.0, 0.0, 10.0, 0.0));
    art.SetAnchor(inkEAnchor.TopLeft);
    art.SetTintColor(tint);
    art.SetInteractive(false);
    art.Reparent(panel, -1);
    return art;
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
    // The game's own vignette over it, faintly red, as its full-screen pages darken their edges (2.5.0).
    if !this.m_inTab {
      let vignette = new inkImage();
      vignette.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\notifications\\vignette.inkatlas");
      vignette.SetTexturePart(n"vignette_1");
      vignette.SetNineSliceScale(true);
      vignette.SetAnchor(inkEAnchor.Fill);
      vignette.SetTintColor(CBHudLabel());
      vignette.SetOpacity(0.2);
      vignette.SetInteractive(false);
      vignette.Reparent(root, -1);
    }

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

    // The switch between the gangs as a list and as a web (2.4.3), at the top left of the list.
    let toggle = this.NewBox(panel, CBHudWebToggleName(), x, CBHudContentTop() - 36.0, 230.0, 32.0);
    this.m_webToggleBg = this.NewBand(toggle, CBHudButtonIdle());
    let toggleText = this.NewText(toggle, 18, n"Semibold", CBHudHead());
    toggleText.SetLetterCase(textLetterCase.UpperCase);
    toggleText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    toggleText.SetFitToContent(false);
    toggleText.SetSize(this.PxSize(230.0, 24.0));
    toggleText.SetMargin(this.PxAt(0.0, 5.0));
    toggle.SetVisible(false);
    this.m_webToggle = toggle;
    this.m_webToggleText = toggleText;
    this.BuildWeb(panel, x);

    // No rule under the header. It was 1540 px of two-pixel line, which is the single most
    // warp-revealing shape on the page, and the heading above it already separates the screens.

    // ---- Score meters -------------------------------------------------------
    let b = 0;
    while b < CBHudBarCount() {
      // The tile's card, under its words; placed with the tile (SetBar).
      let tileArt = this.NewPanelArt(panel, n"cell_bg", CBHudGameCell());
      tileArt.SetOpacity(0.85);
      tileArt.SetVisible(false);
      let tileFrame = this.NewPanelArt(panel, n"cell_fg", CBHudGameCellEdge());
      tileFrame.SetVisible(false);
      ArrayPush(this.m_tileArt, tileArt);
      ArrayPush(this.m_tileFrame, tileFrame);
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
      // A bar of its own, in segments: placed and filled by whichever screen uses it (SetRowBar).
      let seg = 0;
      while seg < CBHudBarSegs() {
        let piece = this.NewRect(rbox, CBHudBarTrack());
        piece.SetVisible(false);
        ArrayPush(this.m_rowSeg, piece);
        seg += 1;
      }
      ArrayPush(this.m_rowCrew, 0);
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
    actionText.SetVerticalAlignment(textVerticalAlignment.Center);
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
      extraText.SetVerticalAlignment(textVerticalAlignment.Center);
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
    this.Hook(this.m_webToggle);
    i = 0;
    while i < ArraySize(this.m_webBox) {
      this.Hook(this.m_webBox[i]);
      i += 1;
    }
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
    // The web of gangs (2.4.3): the switch, and a gang's box picked.
    if Equals(name, CBHudWebToggleName()) {
      e.Handle();
      if CBHudHasPicture(this.m_tab) {
        this.Click();
        sys.SetHubVisual(this.m_tab, !sys.HubVisual(this.m_tab));
        this.m_payArmed = n"";
        this.m_listTop = 0;
        this.Render(sys, game);
      }
      return true;
    }
    let wi = this.WebIndex(name);
    if wi >= 0 {
      e.Handle();
      if this.m_webShown {
        this.Click();
        this.WebPick(sys, game, wi);
      }
      if this.m_treeShown {
        this.Click();
        this.TreePick(sys, game, wi);
      }
      if this.m_mapShown {
        this.Click();
        this.MapPick(sys, game, wi);
      }
      if this.m_crewPicShown {
        this.Click();
        this.CrewPick(sys, game, wi);
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
    if !this.IsOpen() || !IsDefined(e) || e.IsHandled() || this.m_crewMode == 4 {
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
    // On the web of gangs the keys and the pad go round the ring instead (2.4.3).
    if this.m_webShown && step != 0 && ArraySize(this.m_webOrder) > 0 {
      let at = ArrayFindFirst(this.m_webOrder, CBWebSlotOf(this.m_pickFaction));
      let n = ArraySize(this.m_webOrder);
      let next = at < 0 ? (step > 0 ? 0 : n - 1) : ((at + (step > 0 ? 1 : -1)) % n + n) % n;
      this.WebPick(sys, game, this.m_webOrder[next]);
      return true;
    }
    // On the Rivals tree they go from gang to gang.
    if this.m_treeShown && step != 0 {
      this.TreeStep(sys, game, step > 0 ? 1 : -1);
      return true;
    }
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
    CBHudResampleWorn(sys, game);
    this.m_purgeArmed = false;
    this.m_resetArmed = false;
    this.m_bountyArmed = false;
    this.m_payArmed = n"";
    this.m_findArmed = 0;
    this.m_forgetArmed = 0;
    this.m_letGoArmed = 0;
    this.m_listTop = 0;
    this.m_listScrolled = false;
    this.m_hover = n"";
    this.Render(sys, game);
  }

  private func RowClicked(sys: ref<CyberbaneSystem>, game: GameInstance, row: Int32) -> Void {
    if this.m_tab == CBHudCrewTab() && this.m_crewMode >= 1 && this.m_crewMode <= 3 {
      // A pick from the list (2.6.0): carried out here and now (CBCrewKitDoNow: it moves only V's bag and the crew's books),
      // its text sent once back in the game; back to their orders, where it shows.
      let pick = row < ArraySize(this.m_rowCrew) ? this.m_rowCrew[row] - 1 : -1;
      let kbPick = CBCrewKitBook.Get(game);
      let noItem: ItemID;
      if IsDefined(kbPick) && pick >= 0 && this.m_pickCrew > 0 {
        if this.m_crewMode == 1 && pick < ArraySize(this.m_pickItems) {
          kbPick.Ask(this.m_pickCrew, CBCrewAskGive(), this.m_pickItems[pick], n"");
        }
        if this.m_crewMode == 2 && pick < ArraySize(this.m_pickItems) {
          kbPick.Ask(this.m_pickCrew, CBCrewAskChrome(), this.m_pickItems[pick], n"");
        }
        if this.m_crewMode == 3 && pick < ArraySize(this.m_pickGangs) {
          kbPick.Ask(this.m_pickCrew, CBCrewAskWar(), noItem, this.m_pickGangs[pick]);
        }
        CBCrewKitDoNow(sys, game);
      }
      this.m_crewMode = 6;
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() && this.m_crewMode >= 5 {
      let code = row < ArraySize(this.m_rowCrew) ? this.m_rowCrew[row] : 0;
      if this.m_crewMode == 5 {
        this.m_pickFallen = code == this.m_pickFallen ? 0 : code;
      }
      if this.m_crewMode == 6 {
        this.CrewOrderClicked(game, code);
      } else {
        if this.m_crewMode == 7 {
          this.CrewRecordClicked(game, code);
        }
      }
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() {
      this.m_pickCrew = row < ArraySize(this.m_rowCrew) ? this.m_rowCrew[row] : 0;
      this.m_letGoArmed = 0;
      this.Render(sys, game);
      return;
    }
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
    // The crew (2.5.0): "Need you. Now." is carried out on the first tick back in the game; clicked again, taken back.
    if this.m_tab == CBHudCrewTab() && this.m_crewMode != 0 {
      // "Back" out of a screen, "Save the name" when naming (2.6.0): a pick list goes back to the orders it came from,
      // the name and the memorial to the crew's own screen, the rest to the roster.
      let mode = this.m_crewMode;
      // The name is only words: it touches nothing in the world, so it is saved here and now and the crew's screen
      // shows it at once. Waiting for the next tick, as the orders do, it read as not saved until the menu closed.
      if mode == 4 {
        let kbName = CBCrewKitBook.Get(game);
        if IsDefined(kbName) && IsDefined(this.m_nameInput) {
          kbName.SetName(this.m_nameInput.GetText());
          CBLog.Info(n"Crew", s"V named the crew: \(kbName.Name()).");
        }
      }
      this.m_crewMode = mode >= 1 && mode <= 3 ? 6 : (mode == 4 || mode == 5 ? 7 : 0);
      this.m_pickFallen = 0;
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() {
      let crew = CBCrewBook.Get(game);
      if IsDefined(crew) {
        if crew.reqCall {
          crew.reqCall = false;
        } else {
          crew.reqCall = StrLen(CBCrewCallBlocked(sys, game, false)) == 0;
        }
      }
      this.Render(sys, game);
      return;
    }
    // The price on V's head (Spawn/Bounty.reds, 2.4.3): paid on the next tick back in the game, never from here.
    if this.m_tab == CBHudStandingTab() {
      if CBBountyPayPending(game) {
        CBBountyRequestPay(game, false);
        this.m_bountyArmed = false;
      } else {
        let price = CBBountyPayOff(sys, game);
        if price > 0 && CBHudEddies(game) >= price {
          if this.m_bountyArmed {
            this.m_bountyArmed = false;
            CBBountyRequestPay(game, true);
            CBLog.Info(n"UI", "Paying off the price on V's head, chosen on the Hub.");
          } else {
            this.m_bountyArmed = true;
          }
        }
      }
      this.Render(sys, game);
      return;
    }
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
    if this.m_tab == CBHudCrewTab() && this.m_crewMode == 4 {
      if slot == 1 {
        this.m_crewMode = 7;   // Cancel: the name stays as it was
      }
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() {
      // Pay the cut; the picked one's orders, or the solo hired; the crew itself (2.6.0). Requests are carried out back
      // in the game.
      let cb = CBCrewBook.Get(game);
      if IsDefined(cb) {
        if slot == 1 {
          cb.reqPay = !cb.reqPay;
        }
        if slot == 2 {
          if this.m_pickCrew > 0 {
            this.m_crewMode = 6;
            this.m_letGoArmed = 0;
          }
          if this.m_pickCrew == -1 {
            cb.reqHire = !cb.reqHire;
          }
        }
        if slot == 3 {
          this.m_crewMode = 7;
          this.m_pickFallen = 0;
        }
      }
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudHistoryTab() && slot == 1 {
      this.m_legendShown = !this.m_legendShown;
      this.Render(sys, game);
      return;
    }
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
      if slot == 2 {
        if this.m_pickRival > 0 {
          sys.RequestSendWord(this.m_pickRival);
        }
        this.Render(sys, game);
        return;
      }
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
    this.PackActions();
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
    this.PaintWeb();
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
    // Drawn smaller until it fits, rather than cut (2.5.0).
    this.BoxText(this.m_actionText, label, CBHudActionW() - 24.0, CBHudActionFont(), 14, true);
    if IsDefined(this.m_actionBox) {
      this.m_actionBox.SetVisible(StrLen(label) > 0);
    }
  }

  // The button and the ones under it, from `top` down (2.5.0). Every page starts them at CBHudDetailTop (Render); the
  // web of gangs is drawn taller and puts them beside the words under it.
  private func PlaceActions(top: Float) -> Void {
    this.m_actionTop = top;
    let x = CBHudMarginX() + CBHudContentW() - CBHudActionW();
    if IsDefined(this.m_actionBox) {
      this.m_actionBox.SetMargin(this.PxAt(x, top));
    }
    let k = 0;
    while k < ArraySize(this.m_extraBox) {
      if IsDefined(this.m_extraBox[k]) {
        this.m_extraBox[k].SetMargin(this.PxAt(x, top + Cast<Float>(k + 1) * (CBHudActionH() + CBHudActionGap())));
      }
      k += 1;
    }
  }

  // The buttons showing, one under another from the top with no gap where a hidden one is (2.5.0): a page that
  // showed its first and fourth buttons left two buttons' worth of empty space between them. Each keeps its own name,
  // so a click still reaches the same action.
  private func PackActions() -> Void {
    let x = CBHudMarginX() + CBHudContentW() - CBHudActionW();
    let y = this.m_actionTop > 0.0 ? this.m_actionTop : CBHudDetailTop() - 4.0;
    let step = CBHudActionH() + CBHudActionGap();
    if IsDefined(this.m_actionBox) && this.m_actionBox.IsVisible() {
      this.m_actionBox.SetMargin(this.PxAt(x, y));
      y += step;
    }
    let k = 0;
    while k < ArraySize(this.m_extraBox) {
      if IsDefined(this.m_extraBox[k]) && this.m_extraBox[k].IsVisible() {
        this.m_extraBox[k].SetMargin(this.PxAt(x, y));
        y += step;
      }
      k += 1;
    }
  }

  // The same, for the buttons under it, numbered from 1. "" hides one.
  private func SetExtra(slot: Int32, label: String, enabled: Bool) -> Void {
    let k = slot - 1;
    if k < 0 || k >= ArraySize(this.m_extraBox) || k >= ArraySize(this.m_extraOn) {
      return;
    }
    this.m_extraOn[k] = enabled && StrLen(label) > 0;
    this.BoxText(this.m_extraText[k], label, CBHudActionW() - 24.0, CBHudActionFont(), 14, true);
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
    let t = 0;
    while t < ArraySize(this.m_tileArt) {
      if IsDefined(this.m_tileArt[t]) { this.m_tileArt[t].SetVisible(false); }
      if t < ArraySize(this.m_tileFrame) && IsDefined(this.m_tileFrame[t]) { this.m_tileFrame[t].SetVisible(false); }
      t += 1;
    }
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
      if i < ArraySize(this.m_rowCrew) { this.m_rowCrew[i] = 0; }
      let seg = 0;
      while seg < CBHudBarSegs() {
        let k = i * CBHudBarSegs() + seg;
        if k < ArraySize(this.m_rowSeg) && IsDefined(this.m_rowSeg[k]) {
          this.m_rowSeg[k].SetVisible(false);
        }
        seg += 1;
      }
      i += 1;
    }
  }

  // A bar in row `idx`, at `x` from the row's left edge and `w` wide, in ten segments: `frac` of them lit, or with
  // `bipolar`, lit from the middle towards the side `frac` (-1..1) leans. Any amount at all lights one.
  private func SetRowBar(idx: Int32, x: Float, w: Float, frac: Float, tint: HDRColor, opt bipolar: Bool) -> Void {
    let segs = CBHudBarSegs();
    if idx < 0 || (idx + 1) * segs > ArraySize(this.m_rowSeg) {
      return;
    }
    let stride = this.m_rowLayout == CBHudLayoutTitles() ? CBHudTitleRowHeight() : CBHudRowHeight();
    let y = (stride - 4.0 - CBHudRowBarH()) / 2.0;
    this.PlaceSegments(this.m_rowSeg, idx * segs, x, y, w, CBHudRowBarH(), frac, tint, bipolar);
  }

  // Ten segments of a pool, from `first`, laid out along `w` at (x, y) and lit for `frac`.
  private func PlaceSegments(pool: array<wref<inkRectangle>>, first: Int32, x: Float, y: Float, w: Float, h: Float,
                             frac: Float, tint: HDRColor, bipolar: Bool) -> Void {
    let segs = CBHudBarSegs();
    let gap = CBHudBarGap();
    let sw = MaxF((w - gap * Cast<Float>(segs - 1)) / Cast<Float>(segs), 1.0);
    let from = 0;
    let lit = 0;
    if bipolar {
      let half = segs / 2;
      lit = Min(half, RoundF(AbsF(ClampF(frac, -1.0, 1.0)) * Cast<Float>(half)));
      if lit == 0 && AbsF(frac) > 0.02 {
        lit = 1;
      }
      from = frac < 0.0 ? half - lit : half;
    } else {
      lit = Min(segs, RoundF(ClampF(frac, 0.0, 1.0) * Cast<Float>(segs)));
      if lit == 0 && frac > 0.02 {
        lit = 1;
      }
    }
    let k = 0;
    while k < segs {
      let i = first + k;
      if i < ArraySize(pool) && IsDefined(pool[i]) {
        pool[i].SetSize(this.PxSize(sw, h));
        pool[i].SetMargin(this.PxAt(x + Cast<Float>(k) * (sw + gap), y));
        pool[i].SetTintColor(k >= from && k < from + lit ? tint : CBHudBarTrack());
        pool[i].SetVisible(true);
      }
      k += 1;
    }
  }

  private func HideSegments(pool: array<wref<inkRectangle>>, first: Int32) -> Void {
    let k = 0;
    while k < CBHudBarSegs() {
      let i = first + k;
      if i < ArraySize(pool) && IsDefined(pool[i]) {
        pool[i].SetVisible(false);
      }
      k += 1;
    }
  }

  // Move the rows and their cells to where the screen about to be drawn needs them. Only touches
  // them when the layout has changed, so changing screen is not re-laying out every cell.
  private func PlaceRows(layout: Int32, opt topY: Float) -> Void {
    let top = topY > 0.0 ? topY : CBHudContentTop();
    if this.m_rowPlaced && this.m_rowLayout == layout && this.m_rowTop == top {
      return;
    }
    this.m_rowTop = top;
    let titles = layout == CBHudLayoutTitles();
    let stride = titles ? CBHudTitleRowHeight() : CBHudRowHeight();
    let rowW = titles ? CBHudTitleListW() : CBHudContentW();
    let rowH = stride - 4.0;
    let textY = titles ? 0.0 : 5.0;
    let r = 0;
    while r < ArraySize(this.m_rowBox) {
      if IsDefined(this.m_rowBox[r]) {
        this.m_rowBox[r].SetMargin(this.PxAt(CBHudMarginX(), top + Cast<Float>(r) * stride));
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

  // The four scores as tiles, two by two (2.5.0): the meters keep their full story in half the height, and what is on
  // its way gets the room under them. Where tile `idx` sits.
  private func TileX(idx: Int32) -> Float {
    return CBHudMarginX() + Cast<Float>(idx % 2) * (CBHudTileW() + CBHudTileGap());
  }

  private func TileY(idx: Int32) -> Float {
    return CBHudContentTop() + Cast<Float>(idx / 2) * CBHudTileStride();
  }

  // Conduct runs -100 to +100, so it is drawn from the middle: left of centre in red as V slides
  // towards cyberpsycho, right of centre in green as they stay clean.
  private func SetBipolarBar(idx: Int32, label: String, value: String, signed: Float,
                             col: HDRColor, caption: String) -> Void {
    this.SetBar(idx, label, value, 0.0, col, caption);
    if idx < 0 || idx >= ArraySize(this.m_barFill) || !IsDefined(this.m_barFill[idx]) {
      return;
    }
    let half = CBHudTileW() * 0.5;
    let reach = MaxF(ClampF(AbsF(signed) / 100.0, 0.0, 1.0) * half, 2.0);
    let left = signed < 0.0 ? half - reach : half;
    this.m_barFill[idx].SetSize(this.PxSize(reach, 10.0));
    this.m_barFill[idx].SetMargin(this.PxAt(this.TileX(idx) + left, this.TileY(idx) + 36.0));
    this.m_barFill[idx].SetTintColor(col);
    this.m_barFill[idx].SetVisible(true);
  }

  private func SetBar(idx: Int32, label: String, value: String, frac: Float, col: HDRColor, caption: String) -> Void {
    if idx < 0 || idx >= ArraySize(this.m_barLabel) {
      return;
    }
    let tx = this.TileX(idx);
    let ty = this.TileY(idx);
    let tw = CBHudTileW();
    if idx < ArraySize(this.m_tileArt) && IsDefined(this.m_tileArt[idx]) && IsDefined(this.m_tileFrame[idx]) {
      this.m_tileArt[idx].SetMargin(this.PxAt(tx - 14.0, ty - 8.0));
      this.m_tileArt[idx].SetSize(this.PxSize(tw + 28.0, CBHudTileStride() - 6.0));
      this.m_tileArt[idx].SetVisible(true);
      this.m_tileFrame[idx].SetMargin(this.PxAt(tx - 14.0, ty - 8.0));
      this.m_tileFrame[idx].SetSize(this.PxSize(tw + 28.0, CBHudTileStride() - 6.0));
      this.m_tileFrame[idx].SetTintColor(col);
      this.m_tileFrame[idx].SetOpacity(0.7);
      this.m_tileFrame[idx].SetVisible(true);
    }
    if IsDefined(this.m_barLabel[idx]) {
      this.m_barLabel[idx].SetMargin(this.PxAt(tx, ty));
      this.m_barLabel[idx].SetText(label);
      this.m_barLabel[idx].SetVisible(true);
    }
    if IsDefined(this.m_barValue[idx]) {
      this.m_barValue[idx].SetSize(this.PxSize(tw, 30.0));
      this.m_barValue[idx].SetMargin(this.PxAt(tx, ty));
      this.m_barValue[idx].SetText(value);
      this.m_barValue[idx].SetTintColor(col);
      this.m_barValue[idx].SetVisible(true);
    }
    if IsDefined(this.m_barTrack[idx]) {
      this.m_barTrack[idx].SetSize(this.PxSize(tw, 10.0));
      this.m_barTrack[idx].SetMargin(this.PxAt(tx, ty + 36.0));
      this.m_barTrack[idx].SetVisible(true);
    }
    if IsDefined(this.m_barFill[idx]) {
      this.m_barFill[idx].SetMargin(this.PxAt(tx, ty + 36.0));
      this.m_barFill[idx].SetSize(this.PxSize(MaxF(ClampF(frac, 0.0, 1.0) * tw, 2.0), 10.0));
      this.m_barFill[idx].SetTintColor(col);
      this.m_barFill[idx].SetVisible(true);
    }
    if IsDefined(this.m_barCap[idx]) {
      // Two lines: the tile below starts clear of a second one.
      this.m_barCap[idx].SetMargin(this.PxAt(tx, ty + 54.0));
      this.m_barCap[idx].SetWrapping(true, this.Px(tw));
      this.m_barCap[idx].SetText(CBHudFit(caption, tw, 19, 2));
      this.m_barCap[idx].SetVisible(true);
    }
  }

  // What is on its way, as rows under the tiles (2.5.0): each lane with a pip for how close it is, and V's own crew.
  // Returns where the rows end.
  private func RenderLanes(sys: ref<CyberbaneSystem>, game: GameInstance) -> Float {
    let top = CBHudContentTop() + 2.0 * CBHudTileStride() - 4.0;
    this.PlaceRows(CBHudLayoutLanes(), top);
    let row = 0;
    row = this.LaneRow(sys, game, row, CBLaneRival(), "A rival");
    row = this.LaneRow(sys, game, row, CBLaneSquad(), "A gang crew");
    row = this.LaneRow(sys, game, row, CBLaneApex(), "An apex squad");
    let crew = CBCrewBook.Get(game);
    if CBMyCrewOn() && IsDefined(crew) && crew.Count() > 0 {
      let out = crew.OutCount();
      let ready = ArraySize(CBCrewReadyOrder(crew, CBGameSeconds(game), 0));
      let what = out > 0 ? (crew.leaving ? "Heading home" : s"\(out) with you now") : s"\(ready) of \(crew.Count()) ready to call";
      this.SetRow(row, CBHudLayoutLanes(), out > 0 ? CBHudGreen() : CBHudCyan(), false, false, "Your crew", what, "", "", "",
                  crew.CutOwed() > 0 ? s"owed \(crew.CutOwed())eb" : "");
      row += 1;
    }
    return top + Cast<Float>(row) * CBHudRowHeight();
  }

  private func LaneRow(sys: ref<CyberbaneSystem>, game: GameInstance, row: Int32, lane: Int32, label: String) -> Int32 {
    let text = CBHudLaneLine(sys, game, lane, "");
    if StrLen(text) > 3 {
      text = StrRight(text, StrLen(text) - 3);   // the line starts after its label's gap
    }
    let tail = "";
    let cut = StrFindFirst(text, "   (");
    if cut >= 0 {
      tail = StrRight(text, StrLen(text) - cut - 3);
      text = StrLeft(text, cut);
    }
    let busy = CBLaneBusy(sys, game, lane);
    let coming = lane == CBLaneRival() ? sys.GetLaneRivalId(lane) > 0 : NotEquals(sys.GetLaneTarget(lane), n"");
    let pip = busy ? CBHudRed() : (coming ? CBHudAmber() : CBHudGrey());
    this.SetRow(row, CBHudLayoutLanes(), pip, false, false, label, CBCapFirst(text), "", "", "", tail);
    return row + 1;
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
          // Too long for the column at its size: drawn smaller, down to CBHudMinCellFont, and only past that
          // shortened, at a word, so nothing is ever cut through the middle of one (2.5.0).
          let base = col == 0 ? 23 : 22;
          let size = base;
          let len = StrLen(text);
          if len > budget {
            size = Max(CBHudMinCellFont(), (base * budget) / len);
          }
          let room = (budget * base) / size;
          this.m_rowCell[cellIdx].SetFontSize(Max(1, RoundF(Cast<Float>(size) * this.Scale())));
          // Drawn smaller, it is moved down by half the difference, so it stays level with its row.
          let rowTextY = layout == CBHudLayoutTitles() ? 0.0 : 5.0;
          let cellX = col == CBHudRowCols() - 1 ? 0.0 : CBHudRowColX(col, layout);
          this.m_rowCell[cellIdx].SetMargin(this.PxAt(cellX, rowTextY + (col == 0 ? 0.0 : 2.0) + Cast<Float>(base - size) * 0.5));
          this.m_rowCell[cellIdx].SetText(len > room ? CBHudTrimWords(text, room) : text);
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

    // While the Street Cred floor holds Renown up (2.5.2), nothing V does moves the number until what Cyberbane has
    // counted passes it, so the tile says so and shows that count: "it never changes" was the floor, unexplained.
    let earned = score.GetEarnedRenown();
    let renownCaption = "How widely Night City knows your name.";
    if renown >= earned + 1.0 {
      renownCaption = s"Held here by your Street Cred. What you have done counts \(RoundF(earned)) so far.";
    }
    this.SetBar(0, "Renown", s"\(RoundF(renown))   \(CBTierName(EnumInt(score.GetTier())))",
      renown / 1000.0, CBHudCyan(), renownCaption);

    // The number is Dread; the word is what the street does with it. The second figure is what
    // the street actually reads, which is not the same number and never was - it belongs in the
    // sentence that explains it rather than loose beside the first.
    let civ = score.GetDreadCiv();
    this.SetBar(1, "Dread", s"\(RoundF(dread))   \(CBDreadWord(civ))",
      dread / 100.0, CBHudRed(),
      s"How frightening you are. The street reads it as \(RoundF(civ)): that is what makes people back off.");

    this.SetBar(2, "Visible chrome", s"\(RoundF(chrome))",
      chrome / 100.0, CBHudAmber(),
      CBHudWornLine(sys));

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
    let orderTwr: array<Int32>;
    // Hostile on sight by somebody else's hand, asked once a draw (CBForeignHostile): They Will
    // Remember's own verdict, or their people seen hostile to V without Cyberbane having done it. A gang
    // either says is hostile sorts and reads as hostile whatever Cyberbane's own standing says.
    let twrHostile: array<Int32>;
    let t = 0;
    while t < ArraySize(states) {
      ArrayPush(twrHostile, IsDefined(states[t]) ? CBForeignHostile(sys, sys.GetGameInstance(), states[t].id) : 0);
      t += 1;
    }
    let sweep = 0;
    while sweep < 2 {
      let i = 0;
      while i < ArraySize(states) {
        let fs = states[i];
        let twr = twrHostile[i];
        i += 1;
        if IsDefined(fs) {
          let posture = score.GetPosture(fs.id);
          let hostile = Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) || twr > 0;
          if CBTwrOwnsHostility(fs.id) && CBTwrGangHostile(sys.GetGameInstance(), fs.id) == 0 {
            hostile = false;   // They Will Remember decides, and it says not
          }
          if (sweep == 0 && hostile) || (sweep == 1 && !hostile) {
            ArrayPush(order, fs);
            ArrayPush(orderTwr, twr);
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
                            Equals(shownFs.id, this.m_pickFaction), orderTwr[top + row]);
      row += 1;
    }
  }

  private func RenderFactionRow(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>, fs: ref<CBFactionState>,
                                posture: ECBPosture, row: Int32, picked: Bool, twrHostile: Int32) -> Void {
    let pip = CBHudGrey();
    if Equals(posture, ECBPosture.Vendetta) { pip = CBHudRed(); }
    if Equals(posture, ECBPosture.Hostile) { pip = CBHudAmber(); }
    if Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied) { pip = CBHudGreen(); }
    let postureText = CBPostureName(posture);
    // Set by hand under How gangs see you in Mod Settings (2.1.0).
    if CBGangViewSet(fs.id) {
      postureText = postureText + " (set)";
    }
    // Switched off under Factions in Mod Settings (1.9.1): Cyberbane has no posture for them at all.
    let off = !CBFactionOn(fs.id);
    if off {
      postureText = "Off";
    }
    // Hostile on sight by somebody else's hand (CBForeignHostile), while Cyberbane's own posture is
    // milder: They Will Remember's record, or seen in the street and not Cyberbane's doing.
    if twrHostile > 0 && !Equals(posture, ECBPosture.Hostile) && !Equals(posture, ECBPosture.Vendetta) {
      pip = CBHudAmber();
      if off {
        postureText = "Off: hostile";
      } else {
        postureText = twrHostile == 2 ? "TWR: Hostile" : "Seen hostile";
      }
    }
    // They Will Remember decides who is hostile (1.9.4), and since 2.4.2 the posture itself follows it
    // (CBActingStanding), so all this adds is whose word it is. A stance set by hand is the player's own.
    if !off && !CBGangViewSet(fs.id) && CBTwrOwnsHostility(fs.id) {
      let says = CBTwrGangHostile(sys.GetGameInstance(), fs.id);
      if says >= 0 {
        postureText = CBPostureName(posture) + " (TWR)";
      } else {
        postureText = CBPostureName(posture) + " (TWR?)";
      }
    }
    let right = CBHudGangStatus(sys, fs);
    if Equals(sys.GetPendingPeace(), fs.id) {
      right = "PAYING OFF";
    }
    // Who this gang is at war with, because that is the one thing on this screen V can act on:
    // hurting a gang warms the gangs that hate it (Model/GangRivalries.reds).
    let enemy = CBFactionLabel(CBTopEnemyOf(sys, sys.GetContent(), fs.id));
    this.SetRow(row, CBHudLayoutGangs(), pip, true, picked,
      CBFactionLabel(fs.id),
      postureText,
      s"fear \(RoundF(score.GetFactionFear(fs.id)))",
      StrLen(enemy) > 0 ? "at war: " + enemy : "",
      s"\(fs.kills) down",
      right);
    this.m_rowFaction[row] = fs.id;
    // Where V stands with them, from the middle: red to the left, green to the right (2.5.0).
    if !off {
      let standing = score.GetStanding(fs.id);
      this.SetRowBar(row, CBHudGangBarX(), CBHudGangBarW(), ClampF(standing / 100.0, -1.0, 1.0),
                     standing < 0.0 ? CBHudRed() : CBHudGreen(), true);
    }
  }

  // The panel under the gangs: the one you clicked, and the button to buy them off.
  private func RenderFactionDetail(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let top = CBHudContentTop() + Cast<Float>(CBHudListRows()) * CBHudRowHeight() + 24.0;
    if this.m_webShown {
      top = CBHudContentTop() + CBGridGangsH() + 20.0;
      this.PlaceActions(top - 4.0);
    }
    let width = CBHudContentW() - CBHudActionW() - 40.0;
    if Equals(this.m_pickFaction, n"") {
      this.SetAction("", false);
      // Under the web, only what its lines mean (2.5.0); the page's own words are the list's.
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), this.m_webShown ? CBWebLegend() : CBHudFactions(sys),
                   CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let id = this.m_pickFaction;
    let fs = sys.FindFaction(id);
    let score = sys.GetScore();
    // A gang V has never crossed has no record (only a kill or a pay-off files one), and the web can pick it: said so,
    // with what the web knows of it, and nothing is written.
    if !IsDefined(fs) && IsDefined(score) && this.m_webShown {
      this.SetAction("", false);
      let ties = CBWebRelationWords(sys, game, id);
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), StrUpper(CBFactionLabel(id)) + "   " + CBPostureName(score.GetPosture(id)) + "\n"
                   + (StrLen(ties) > 0 ? ties + "\n" : "") + "You have never crossed them, and they have no opinion of you yet.",
                   CBHudMaxLinesFor(this.m_tab));
      return;
    }
    if !IsDefined(fs) || !IsDefined(score) {
      this.m_pickFaction = n"";
      this.SetAction("", false);
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), CBHudFactions(sys), CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let posture = score.GetPosture(id);
    let gang = CBFactionLabel(id);
    let isOn = CBFactionOn(id);
    let out = StrUpper(gang) + "   " + (isOn ? CBPostureName(posture) : "OFF") + "\n";
    // The web says in words what its lines show for this gang (UI/HubWeb.reds, 2.4.3).
    if this.m_webShown && isOn {
      let ties = CBWebRelationWords(sys, game, id);
      out += (StrLen(ties) > 0 ? ties + " " : "") + s"\(CBPostureName(posture)) to you, \(RoundF(score.GetStanding(id))).\n";
    }
    let crewLine = isOn ? CBCrewStandingLine(game, id) : "";
    if StrLen(crewLine) > 0 {
      out += crewLine + "\n";   // the crew's own standing with them (2.6.0)
    }
    if !isOn {
      out += "Switched off under Factions in Mod Settings. Cyberbane leaves them alone: nobody of theirs\n"
           + "turns on you because of Cyberbane, they send nobody, and your standing is kept for later.\n";
    } else {
      // Set by hand (2.1.0): what they do, and what V has earned with them underneath.
      if CBGangViewSet(id) {
        out += "Set to " + CBPostureName(posture) + " under How gangs see you in Mod Settings. What you have\n"
             + "earned with them is " + CBPostureName(CBPostureFromStanding(fs.standing)) + ", and that comes back with Earned in play.\n";
      }
    }
    // Two records, said as two (CBForeignHostile): somebody else's is who shoots on sight, and a pay-off
    // or the switch above changes Cyberbane's alone.
    let foreign = CBForeignHostile(sys, game, id);
    if isOn && !CBGangViewSet(id) && CBTwrOwnsHostility(id) {
      if CBTwrGangHostile(game, id) >= 0 {
        out += "They Will Remember decides whether they are hostile, and Cyberbane follows it.\n";
      } else {
        out += "They Will Remember decides whether they are hostile, but could not be asked (" + CBTwrHostilityWhy() + "),\n"
             + "so Cyberbane goes by what their people do: hostile while they have lately been hostile to you on\n"
             + "sight, and otherwise its own standing, until it answers.\n";
      }
      foreign = 0;   // said just now; the two records are one here
    }
    if foreign == 2 {
      out += "They Will Remember has them hostile on sight: their people attack you when they know you.\n"
           + "That is its own record, kept apart from your standing here, and nothing here changes it.\n";
    } else {
      if foreign == 1 {
        out += "Their people have been hostile to you on sight, and Cyberbane did not make them so:\n"
             + "They Will Remember, another mod or the game has them that way. Nothing here changes it.\n";
      }
    }
    // Who runs them, which the gang's box on the web said in small type until 2.5.0.
    let leader = CBWebLeader(sys, game, id);
    if StrLen(leader) > 0 {
      out += s"Led by \(leader).\n";
    }
    let enemy = CBFactionLabel(CBTopEnemyOf(sys, sys.GetContent(), id));
    if StrLen(enemy) > 0 {
      out += "At war with " + enemy + ". Hurting " + enemy + " is how this gang comes to like you.\n";
    }
    out += s"\(fs.kills) of theirs down. They fear you at \(RoundF(score.GetFactionFear(id))) of 100.\n";
    // Fear against hatred, on their streets (Reactions/Morale.reds, 1.9.5).
    if isOn && CBGangBroken(sys, id) {
      out += "They are broken. Their people fear you whatever their grudge, they only send anyone when you have just hurt them, and they would settle for less.\n";
    } else {
      if isOn && Equals(posture, ECBPosture.Vendetta) && foreign != 2 {
        let held = RoundF(CBHoldBackTypical(sys, id) * 10.0);
        if held > 0 {
          out += s"About \(held) in 10 of their people are too afraid of you to act on it. Those you can talk to.\n";
        } else {
          out += "None of them are afraid enough of you to hold back.\n";
        }
      }
    }
    // What talking to their people has done today (Reactions/StreetTalk.reds, 1.9.6).
    let talked = CBHudTalkToday(sys, id);
    if StrLen(talked) > 0 {
      out += talked + "\n";
    }
    let status = CBHudGangStatus(sys, fs);
    let war = CBWarWords(game, id);   // their chest, their ranks, backed by V, a truce (Economy/War.reds, 2.4.0)
    let heat = CBHeatWord(game, fs);  // still hot, or cooling off (Spawn/Hunted.reds, 2.4.1)
    if StrLen(heat) > 0 {
      war = StrLen(war) > 0 ? heat + ", " + war : heat;
    }
    if StrLen(status) > 0 || StrLen(war) > 0 {
      let both = StrLen(status) > 0 && StrLen(war) > 0 ? StrLower(status) + "; " + war : StrLower(status) + war;
      out += "Right now: " + both + ".\n";
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
    // Below the price, so the page can only ever lose these to its line limit, never the price: what the street
    // knows V by (Model/StreetBook.reds, 2.3.1), and their code as V has learnt it (Data/GangCodes.reds, 2.3.2).
    let knownBy = CBKnownByLine(game);
    if StrLen(knownBy) > 0 {
      out += "\n" + knownBy;
    }
    let code = CBCodeLines(sys, id);
    if StrLen(code) > 0 {
      out += "\n" + code;
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
          "",
          s"\(rd)",
          s"\(d.kills) down",
          "",
          StrLen(quiet) > 0 ? "quiet " + quiet : "nothing yet");
        this.SetRowBar(shown, CBHudWideBarX(), CBHudWideBarW(), d.renown / 100.0, rd >= 15 ? pip : CBHudCyan());
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
          "",
          s"\(RoundF(shares[top] * 100.0))%",
          CBBarFactionLabel(holder),
          "",
          status);
        this.SetRowBar(shown, CBHudWideBarX(), CBHudWideBarW(), shares[top], CBHudCyan());
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
    // Then whoever is out there right now, the one leading and anybody with them (1.9.0), then the
    // rest. In roster order a team's second and third names could sit below the fold while they shot
    // at V.
    let game = sys.GetGameInstance();
    let pass = 0;
    while pass < 2 {
      let i = 0;
      while i < ArraySize(rivals) {
        let r = rivals[i];
        i += 1;
        // Skipping the pinned one by id rather than by `continue`, which redscript does not have.
        if IsDefined(r) && r.id != queuedId
           && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting))
           && Equals(pass == 0, CBRivalBodyPresent(game, r)) {
          ArrayPush(order, r);
        }
      }
      pass += 1;
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
    // Drawn as a hierarchy (1.9.4): each gang's line, then its leader, its lieutenants and the rest, in
    // the order of `order` for the gangs, so whoever is coming or already here is at the top.
    let gangs: array<CName>;
    for o in order {
      if !ArrayContains(gangs, o.faction) {
        ArrayPush(gangs, o.faction);
      }
    }
    let entries: array<ref<CBRival>>;
    let heads: array<CName>;
    let nobody: ref<CBRival>;
    for g in gangs {
      ArrayPush(entries, nobody);
      ArrayPush(heads, g);
      let members: array<ref<CBRival>>;
      for o in order {
        if Equals(o.faction, g) {
          ArrayPush(members, o);
        }
      }
      while ArraySize(members) > 0 {
        let best = 0;
        let m = 1;
        while m < ArraySize(members) {
          if CBHudRivalStanding(sys, members[m]) > CBHudRivalStanding(sys, members[best]) {
            best = m;
          }
          m += 1;
        }
        ArrayPush(entries, members[best]);
        ArrayPush(heads, g);
        ArrayErase(members, best);
      }
    }
    let top = this.ListWindow(ArraySize(entries), CBHudListRows());
    let row = 0;
    while row < CBHudListRows() && top + row < ArraySize(entries) {
      let e = entries[top + row];
      if IsDefined(e) {
        this.RenderRivalRow(sys, content, e, row);
      } else {
        this.RenderGangHead(sys, heads[top + row], order, row);
      }
      row += 1;
    }
  }

  // A gang's line on the Rivals screen: who they are, where V stands with them, how strong they still
  // are, and how many of theirs are after V.
  private func RenderGangHead(sys: ref<CyberbaneSystem>, faction: CName, order: array<ref<CBRival>>, row: Int32) -> Void {
    let n = 0;
    for o in order {
      if Equals(o.faction, faction) {
        n += 1;
      }
    }
    let score = sys.GetScore();
    let posture = IsDefined(score) ? score.GetPosture(faction) : ECBPosture.Neutral;
    let pip = CBHudGrey();
    if Equals(posture, ECBPosture.Vendetta) { pip = CBHudRed(); }
    if Equals(posture, ECBPosture.Hostile) { pip = CBHudAmber(); }
    let label = CBBarFactionLabel(faction);
    if StrLen(label) == 0 {
      // Rivals of no gang (2.5.3): an empty name prints as "None"; the cards call the group the same.
      label = Equals(faction, n"") ? "NO GANG" : StrUpper(NameToString(faction));
    }
    let strength = CBTurfWarsOn() ? CBGangStrengthWord(CBGangStrength(sys, faction)) : "";
    this.SetRow(row, CBHudLayoutWide(), pip, false, false,
      label,
      CBPostureName(posture),
      "",
      strength,
      "",
      n == 1 ? "1 Rival" : s"\(n) Rivals");   // a count, not a claim they are all out looking (2.5.5)
    this.m_rowRival[row] = 0;
    // How much is left of them, where their Rivals show their rank (2.5.0).
    if CBTurfWarsOn() {
      this.SetRowBar(row, CBHudRankBarX(), CBHudRankBarW(), ClampF(CBGangStrength(sys, faction), 0.0, 100.0) / 100.0, CBHudGrey());
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
          // On their cooldown after the last fight (RivalAfterEscapeTicks): nobody picks them until it
          // runs out, which "waiting their turn" did not say.
          if r.huntTicks > 0 {
            rightCol = "lying low";
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
    // Under their gang's line (RenderGangHead): the leader one step in, everybody else two.
    let indent = CBRivalRole(sys, r) == CBRoleLeader() ? "   " : "      ";
    this.SetRow(row, CBHudLayoutWide(), hunting ? CBHudRed() : CBHudAmber(), true, r.id == this.m_pickRival,
      indent + (IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival"),
      gang,
      role,
      marks,
      "",
      rightCol);
    this.m_rowRival[row] = r.id;
    // Their rank, one to four, as a bar (2.5.0).
    this.SetRowBar(row, CBHudRankBarX(), CBHudRankBarW(), Cast<Float>(Clamp(r.rank, 1, 4)) / 4.0, hunting ? CBHudRed() : CBHudAmber());
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
      this.SetExtra(3, "Keep them", true);
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
              if CBPhoneDealsReady() {
                this.SetAction(this.m_findArmed == id ? "Confirm: put the word out" : s"Ask around: about \(price)eb", true);
              } else {
                this.SetAction(this.m_findArmed == id ? s"Confirm: pay \(price)eb" : s"Ambush them: \(price)eb", true);
              }
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
                } else {
                  if why == 5 {
                    this.SetAction("Their faction is off", false);
                  } else {
                    // Not after V any more (4): nothing to buy. Left unset, the button kept the last
                    // Rival's label and stayed clickable.
                    this.SetAction("", false);
                  }
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
          this.SetExtra(1, sys.RivalKeptByCrew(r.id) ? "One of your crew" : "On their way: wait", false);
        } else {
          this.SetExtra(1, this.m_forgetArmed == id ? "Click again to forget" : "Forget this rival", IsDefined(r));
        }
      }
      // 3. Call them out (1.9.9).
      let bookH = CBIntelBook.Get(game);
      if !CBSendWordOn() || !IsDefined(r) {
        this.SetExtra(2, "", false);
      } else {
        if IsDefined(bookH) && bookH.WordSent(r.id) {
          this.SetExtra(2, "Word sent", false);
        } else {
          if sys.GetPendingWord() == r.id {
            this.SetExtra(2, "Sending word", false);
          } else {
            this.SetExtra(2, "Send word", CBWhereaboutsForSale(sys, game, r) == 0);
          }
        }
      }
      // 4. Forget everybody.
      this.SetExtra(3, this.m_purgeArmed ? s"Click again: forget all \(count)" : "Forget every rival", true);
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
    // Automatic, then every title V has earned, then the rest, and the page shows a window onto them. There are more
    // titles than rows now (2.5.0), and the last of them had simply fallen off the end.
    let defs: array<ref<CBTitleDef>>;
    let none: ref<CBTitleDef>;
    ArrayPush(defs, none);
    if IsDefined(content) {
      let pass = 0;
      while pass < 2 {
        for def in content.GetTitles() {
          if IsDefined(def) && Equals(sys.HasTitle(def.id), pass == 0) {
            ArrayPush(defs, def);
          }
        }
        pass += 1;
      }
    }
    let rows = CBHudRowPool() - 1;
    let top = this.ListWindow(ArraySize(defs), rows);
    let row = 0;
    while row < rows && top + row < ArraySize(defs) {
      let def = defs[top + row];
      if !IsDefined(def) {
        this.SetRow(row, CBHudLayoutTitles(), onAuto ? CBHudCyan() : CBHudGrey(), true, Equals(reading, n""),
          autoLabel, "", "", "", "", onAuto ? "GOING BY" : "");
        this.m_rowTitle[row] = n"";
      } else {
        let have = sys.HasTitle(def.id);
        let mine = Equals(def.id, chosen);
        let status = mine ? "GOING BY" : "EARNED";
        if !have {
          status = CBTitleProgress(sys, def.id);
          if StrLen(status) == 0 {
            status = "LOCKED";
          }
        }
        this.SetRow(row, CBHudLayoutTitles(), mine ? CBHudCyan() : (have ? CBHudAmber() : CBHudGrey()), true,
          Equals(def.id, reading), CBTitleDisplay(sys, def), "", "", "", "", status);
        this.m_rowTitle[row] = def.id;
      }
      row += 1;
    }
  }

  // ---- The web of gangs ([H1], UI/HubWeb.reds, 2.4.3) ------------------------------------------------------------

  // Built once with the page. Every widget is the Hub's own kind: thin rectangles for lines, its clickable box for the
  // places. Nothing takes a click but the boxes.
  private func BuildWeb(panel: ref<inkCanvas>, x: Float) -> Void {
    let web = new inkCanvas();
    web.SetName(n"cbHubWeb");
    web.SetAnchor(inkEAnchor.TopLeft);
    web.SetSize(this.PxSize(CBHudContentW(), CBWebHeight()));
    web.SetMargin(this.PxAt(x, CBHudContentTop()));
    web.Reparent(panel, -1);
    web.SetVisible(false);
    this.m_webRoot = web;
    // The glows first, so every one is under every line (2.5.0).
    let g = 0;
    while g < CBWebLinePool() {
      let glow = this.NewRect(web, CBHudGrey());
      glow.SetRenderTransformPivot(new Vector2(0.0, 0.5));
      glow.SetVisible(false);
      ArrayPush(this.m_webGlow, glow);
      g += 1;
    }
    let k = 0;
    while k < CBWebLinePool() {
      let line = this.NewRect(web, CBHudGrey());
      line.SetRenderTransformPivot(new Vector2(0.0, 0.5));
      line.SetVisible(false);
      ArrayPush(this.m_webLine, line);
      k += 1;
    }
    k = 0;
    while k < CBWebWordPool() {
      let word = this.NewText(web, CBPicWord(), n"Semibold", CBHudAmber());
      word.SetLetterCase(textLetterCase.UpperCase);
      word.SetVisible(false);
      ArrayPush(this.m_webWord, word);
      k += 1;
    }
    let i = 0;
    while i < CBWebSlotCount() {
      let name = CBHudWidgetName("cbHubWebBox", i);
      let w = CBWebSlotW(i);
      let h = CBWebSlotH(i);
      let box = this.NewBox(web, name, CBWebSlotX(i), CBWebSlotY(i), w, h);
      let bg = this.NewBand(box, CBHudClear());
      // The game's own card under the words, and its frame round them (2.5.0); both coloured by PaintWeb.
      ArrayPush(this.m_webBoxArt, this.NewGameArt(box, n"cell_bg", CBHudGameCell()));
      ArrayPush(this.m_webBoxFrame, this.NewGameArt(box, n"cell_fg", CBHudGameCellEdge()));
      let edge = this.NewRect(box, CBHudGrey());
      edge.SetSize(this.PxSize(4.0, h));
      // Two bars of ten segments, for the pictures that use them (BoxBars).
      let bseg = 0;
      while bseg < 2 * CBHudBarSegs() {
        let piece = this.NewRect(box, CBHudBarTrack());
        piece.SetVisible(false);
        ArrayPush(this.m_webSeg, piece);
        bseg += 1;
      }
      let big = i == 0 || CBWebSlotIsGang(i);
      let title = this.NewText(box, i == 0 ? 30 : (big ? 20 : 16), n"Semibold", CBHudHead());
      title.SetLetterCase(textLetterCase.UpperCase);
      title.SetMargin(this.PxAt(i == 0 ? 0.0 : 12.0, i == 0 ? 2.0 : 3.0));
      if i == 0 {
        title.SetHorizontalAlignment(textHorizontalAlignment.Center);
        title.SetFitToContent(false);
        title.SetSize(this.PxSize(w, 36.0));
      }
      let line2 = this.NewText(box, big ? 15 : 13, n"Medium", CBHudValue());
      line2.SetMargin(this.PxAt(i == 0 ? 0.0 : 12.0, i == 0 ? 36.0 : (big ? 28.0 : 21.0)));
      if i == 0 {
        line2.SetHorizontalAlignment(textHorizontalAlignment.Center);
        line2.SetFitToContent(false);
        line2.SetSize(this.PxSize(w, 20.0));
      }
      let lead = this.NewText(box, 14, n"Medium", CBHudDim());
      lead.SetMargin(this.PxAt(12.0, 47.0));
      lead.SetVisible(big && i > 0);
      let men = this.NewRect(box, CBHudCyan());
      men.SetMargin(this.PxAt(12.0, h - 6.0));
      men.SetSize(this.PxSize(2.0, 3.0));
      men.SetVisible(CBWebSlotIsGang(i));
      let chest = this.NewRect(box, CBHudAmber());
      chest.SetMargin(this.PxAt(w / 2.0 + 4.0, h - 6.0));
      chest.SetSize(this.PxSize(2.0, 3.0));
      chest.SetVisible(CBWebSlotIsGang(i));
      ArrayPush(this.m_webBox, box);
      ArrayPush(this.m_webBoxBg, bg);
      ArrayPush(this.m_webBoxEdge, edge);
      ArrayPush(this.m_webBoxName, title);
      ArrayPush(this.m_webBoxLine, line2);
      ArrayPush(this.m_webBoxLead, lead);
      ArrayPush(this.m_webBarMen, men);
      ArrayPush(this.m_webBarChest, chest);
      ArrayPush(this.m_webBoxNames, name);
      i += 1;
    }
  }

  private func WebIndex(name: CName) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_webBoxNames) {
      if Equals(this.m_webBoxNames[i], name) {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  // A place picked by click, key or pad: its gang is the pick, as a row is on the list; V's own place, or the one
  // already picked, clears it.
  private func WebPick(sys: ref<CyberbaneSystem>, game: GameInstance, slot: Int32) -> Void {
    // V's crew's card (2.6.0): the Crew page's screen for the crew itself.
    if slot == 0 && this.m_crewCardShown {
      this.m_crewMode = 7;
      this.m_pickFallen = 0;
      this.SelectTab(sys, game, CBHudCrewTab());
      return;
    }
    let gang = CBWebSlotGang(slot);
    this.m_pickFaction = (Equals(gang, n"") || Equals(gang, this.m_pickFaction)) ? n"" : gang;
    this.m_payArmed = n"";
    this.Render(sys, game);
  }

  // One box of the pool, moved and sized: the web and the tree place them differently.
  private func PlaceWebBox(s: Int32, x: Float, y: Float, w: Float, h: Float, show: Bool) -> Void {
    if s < 0 || s >= ArraySize(this.m_webBox) || !IsDefined(this.m_webBox[s]) {
      return;
    }
    this.m_webBox[s].SetMargin(this.PxAt(x, y));
    this.m_webBox[s].SetSize(this.PxSize(w, h));
    this.m_webBox[s].SetVisible(show);
    if IsDefined(this.m_webBoxEdge[s]) {
      this.m_webBoxEdge[s].SetSize(this.PxSize(4.0, h));
    }
    if IsDefined(this.m_webBarMen[s]) {
      this.m_webBarMen[s].SetMargin(this.PxAt(12.0, h - 6.0));
    }
    if IsDefined(this.m_webBarChest[s]) {
      this.m_webBarChest[s].SetMargin(this.PxAt(w / 2.0 + 4.0, h - 6.0));
    }
  }

  // ---- The Rivals tree ([H2], 2.4.4) -------------------------------------------------------------------------------

  // The gangs that have Rivals to draw, in roster order.
  // Every gang with a Rival on the roster, and last a group of its own for Rivals of no gang (2.5.3), whom the list showed
  // and the cards never did.
  private func TreeGangs(sys: ref<CyberbaneSystem>) -> array<CName> {
    let out: array<CName>;
    let gangless = false;
    for r in sys.GetRivals() {
      if IsDefined(r) {
        if Equals(r.faction, n"") {
          gangless = true;
        } else {
          if !ArrayContains(out, r.faction) {
            ArrayPush(out, r.faction);
          }
        }
      }
    }
    if gangless {
      ArrayPush(out, CBTreeNoGang());
    }
    return out;
  }

  private func TreeStep(sys: ref<CyberbaneSystem>, game: GameInstance, step: Int32) -> Void {
    let gangs = this.TreeGangs(sys);
    let n = ArraySize(gangs);
    if n == 0 {
      return;
    }
    let at = ArrayFindFirst(gangs, this.m_treeGang);
    at = at < 0 ? 0 : ((at + step) % n + n) % n;
    this.m_treeGang = gangs[at];
    this.m_pickRival = 0;
    this.Render(sys, game);
  }

  private func TreePick(sys: ref<CyberbaneSystem>, game: GameInstance, slot: Int32) -> Void {
    if slot == 0 {
      this.TreeStep(sys, game, 1);   // V's marker in the corner: the next gang
      return;
    }
    let id = slot < ArraySize(this.m_treeSlotRival) ? this.m_treeSlotRival[slot] : 0;
    if id > 0 {
      this.m_pickRival = this.m_pickRival == id ? 0 : id;
      this.m_findArmed = 0;
      this.m_forgetArmed = 0;
      this.m_purgeArmed = false;
      this.Render(sys, game);
    }
  }

  // One Rival in one place of the tree. `empty` names who steps up next when the place has nobody.
  private func TreeBox(sys: ref<CyberbaneSystem>, game: GameInstance, slot: Int32, r: ref<CBRival>, empty: String,
                       x: Float, y: Float, w: Float, h: Float, fallen: Bool) -> Void {
    if slot < 0 || slot >= ArraySize(this.m_webBox) {
      return;
    }
    this.PlaceWebBox(slot, x, y, w, h, true);
    this.DressDefault(slot, w, h);
    while ArraySize(this.m_treeSlotRival) < ArraySize(this.m_webBox) {
      ArrayPush(this.m_treeSlotRival, 0);
    }
    this.m_treeSlotRival[slot] = IsDefined(r) ? r.id : 0;
    let tint = CBHudGrey();
    let name = "EMPTY CHAIR";
    // Who steps up, by name without the nickname so it fits whole (2.5.0); said once, in the first empty chair.
    let line = StrLen(empty) > 0 ? "NEXT: " + StrUpper(CBHudNameNoNick(empty)) : "NOBODY YET";
    let lead = "";
    let leadTint = CBHudDim();
    if IsDefined(r) {
      name = CBRivalDisplayName(sys.GetContent(), r);
      let hunting = r.id == sys.GetActiveRivalId() || r.state == EnumInt(ECBRivalState.Hunting);
      tint = fallen ? CBHudDim() : (hunting ? CBHudRed() : (r.state == EnumInt(ECBRivalState.Debtor) ? CBHudCyan() : CBHudAmber()));
      if fallen {
        let book = CBRivalBook.Get(game);
        let how = IsDefined(book) ? book.Ending(r.id) : CBEndingNone();
        if r.state == EnumInt(ECBRivalState.Retired) {
          line = "LEFT NIGHT CITY";
        } else {
          line = how == CBEndingNotByV() ? "KILLED, NOT BY YOU" : "DEAD BY YOUR HAND";
        }
      } else {
        line = s"RANK \(r.rank)  " + StrUpper(hunting ? "hunting you" : CBRivalStateName(r.state));
        // Who they are to V or to another of theirs, in words (2.5.0): a bond and V's nemesis were lines across the
        // tree from the middle of one box to the middle of another, and showed only as strokes in the air between
        // them. Otherwise what V and they have been through, or that they have never met.
        let bookT = CBRivalBook.Get(game);
        let with = IsDefined(bookT) ? bookT.BondWith(r.id) : 0;
        let partner = with > 0 ? sys.FindRivalById(with) : null;
        if r.id == this.m_treeNemesis {
          lead = s"Your nemesis: met \(r.encounters) times";
          leadTint = CBHudRed();
        } else {
          if IsDefined(partner) && StrLen(CBBondWord(bookT.BondKind(r.id))) > 0 {
            lead = CBCapFirst(CBBondWord(bookT.BondKind(r.id))) + " " + CBHudNameNoNick(CBRivalDisplayName(sys.GetContent(), partner));
            leadTint = CBHudCyan();
          } else {
            lead = r.encounters > 0 ? s"Met \(r.encounters), ran \(r.escapes), spared \(r.sparedByV)" : "Never met you";
          }
        }
      }
    }
    if IsDefined(this.m_webBoxEdge[slot]) {
      this.m_webBoxEdge[slot].SetTintColor(tint);
      this.m_webBoxEdge[slot].SetVisible(true);
    }
    this.BoxText(this.m_webBoxName[slot], name, w - 24.0, fallen ? CBPicSmallName() : CBPicName(), CBPicNameLeast(), true);
    this.BoxText(this.m_webBoxLine[slot], line, w - 24.0, fallen ? CBPicSmallLine() : CBPicLine(), CBPicLineLeast(), false);
    if IsDefined(this.m_webBoxLine[slot]) {
      this.m_webBoxLine[slot].SetTintColor(tint);
    }
    this.BoxText(this.m_webBoxLead[slot], lead, w - 24.0, CBPicLead(), CBPicLeadLeast(), false);
    if IsDefined(this.m_webBoxLead[slot]) {
      this.m_webBoxLead[slot].SetTintColor(leadTint);
      this.m_webBoxLead[slot].SetVisible(StrLen(lead) > 0 && !fallen);
    }
    if IsDefined(this.m_webBarMen[slot]) {
      this.m_webBarMen[slot].SetVisible(false);
    }
    if IsDefined(this.m_webBarChest[slot]) {
      this.m_webBarChest[slot].SetVisible(false);
    }
    // Nothing faded (2.5.0): a faded card showed whatever was under it through its words. The picked one lights up.
    this.m_webBox[slot].SetOpacity(1.0);
  }

  // A gang's leader, their three lieutenants, the rest of their Rivals as the bench, and the fallen, top down: the
  // hierarchy that already exists (CBFactionState leader and lieutenants), with the first empty chair naming who steps
  // up next (the order CBHierarchyFill uses). A bond, and V's nemesis, are said in the box (TreeBox), not drawn.
  private func RenderTree(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if !IsDefined(this.m_webRoot) {
      return;
    }
    let gangs = this.TreeGangs(sys);
    if !ArrayContains(gangs, this.m_treeGang) {
      let picked = sys.FindRivalById(this.m_pickRival);
      if IsDefined(picked) && ArrayContains(gangs, CBTreeGangOf(picked)) {
        this.m_treeGang = CBTreeGangOf(picked);
      } else {
        this.m_treeGang = ArraySize(gangs) > 0 ? gangs[0] : n"";
      }
    }
    this.m_treeShown = true;
    this.m_webRoot.SetVisible(true);
    let s = 0;
    while s < ArraySize(this.m_webBox) {
      this.PlaceWebBox(s, 0.0, 0.0, CBWebSlotW(s), CBWebSlotH(s), false);
      this.ResetBoxLook(s);
      if s < ArraySize(this.m_treeSlotRival) {
        this.m_treeSlotRival[s] = 0;
      }
      s += 1;
    }
    let words = 0;
    let gang = this.m_treeGang;
    let fs = sys.FindFaction(gang);
    // V, in the corner: click for the next gang.
    this.PlaceWebBox(0, CBHudContentW() - CBWebVW(), 0.0, CBWebVW(), CBWebVH(), true);
    this.DressDefault(0, CBWebVW(), CBWebVH());
    if ArraySize(this.m_webBoxName) > 0 && ArraySize(this.m_webBoxLine) > 0 {
      if IsDefined(this.m_webBoxName[0]) {
        this.m_webBoxName[0].SetText("V");
      }
      if IsDefined(this.m_webBoxLine[0]) {
        this.m_webBoxLine[0].SetText(ArraySize(gangs) > 1 ? "NEXT GANG" : "YOU");
      }
    }
    // Drawn whether or not the gang has a record (2.5.3): this asked for one, and a gang V had never killed one of or paid
    // off had none, so its Rival was in the list and the cards said "No Rivals yet". Without one nobody holds a chair,
    // and every Rival of theirs is in the rest.
    if ArraySize(gangs) == 0 || Equals(gang, n"") {
      this.PlaceWord(words, 660.0, 200.0, "No Rivals yet", CBHudGrey(), 1.0);
      words += 1;
    } else {
      // Rows, each named on the left (2.5.0): the leader, the lieutenants, the rest, the fallen. No lines between them:
      // the chair lines and the bond lines crossed the boxes wherever they were drawn.
      let gangName = Equals(gang, CBTreeNoGang()) ? "No gang" : CBFactionLabel(gang);
      let label = StrUpper(StrLen(gangName) > 0 ? gangName : NameToString(gang));
      if ArraySize(gangs) > 1 {
        label += s"  (\(ArrayFindFirst(gangs, gang) + 1) OF \(ArraySize(gangs)))";
      }
      this.PlaceWord(words, 805.0, 40.0, label, CBHudHead(), 1.0);
      words += 1;
      let leaderId = IsDefined(fs) ? fs.leaderRivalId : 0;
      let lt1Id = IsDefined(fs) ? fs.lt1RivalId : 0;
      let lt2Id = IsDefined(fs) ? fs.lt2RivalId : 0;
      let lt3Id = IsDefined(fs) ? fs.lt3RivalId : 0;
      let leader = leaderId > 0 ? sys.FindRivalById(leaderId) : null;
      if IsDefined(leader) && !CBRivalStillAround(leader) {
        leader = null;
      }
      let benchIds: array<Int32>;
      let fallenIds: array<Int32>;
      this.m_treeNemesis = 0;
      let most = 1;
      for r in sys.GetRivals() {
        if IsDefined(r) && Equals(CBTreeGangOf(r), gang) {
          let seated = r.id == leaderId || r.id == lt1Id || r.id == lt2Id || r.id == lt3Id;
          let around = CBRivalStillAround(r) || r.state == EnumInt(ECBRivalState.Debtor) || r.state == EnumInt(ECBRivalState.Dormant);
          if around && r.encounters > most {
            most = r.encounters;
            this.m_treeNemesis = r.id;
          }
          if !seated {
            if around {
              if ArraySize(benchIds) < 4 {
                ArrayPush(benchIds, r.id);
              }
            } else {
              if ArraySize(fallenIds) < 4 && (r.state == EnumInt(ECBRivalState.Slain) || r.state == EnumInt(ECBRivalState.Retired)) {
                ArrayPush(fallenIds, r.id);
              }
            }
          }
        }
      }
      let cw = CBTreeCardW();
      let ch = CBTreeCardH();
      let nextUp = IsDefined(fs) ? CBBestCandidate(sys, fs) : null;
      let nextLt = IsDefined(fs) ? CBBestLieutenant(sys, fs) : null;
      this.PlaceLabel(words, 0.0, ch / 2.0, "LEADER", CBHudDim());
      words += 1;
      this.TreeBox(sys, game, 1, leader, IsDefined(nextUp) ? CBRivalDisplayName(sys.GetContent(), nextUp) : "",
                   CBTreeCardX(0), 0.0, cw, ch, false);
      let rowY = ch + CBTreeRowGap();
      this.PlaceLabel(words, 0.0, rowY + ch / 2.0, "LIEUTENANTS", CBHudDim());
      words += 1;
      let ltIds: array<Int32> = [lt1Id, lt2Id, lt3Id];
      let named = false;
      let k = 0;
      while k < 3 {
        let lt = ltIds[k] > 0 ? sys.FindRivalById(ltIds[k]) : null;
        if IsDefined(lt) && !CBRivalStillAround(lt) {
          lt = null;
        }
        let next = "";
        if !IsDefined(lt) && !named && IsDefined(nextLt) {
          next = CBRivalDisplayName(sys.GetContent(), nextLt);
          named = true;
        }
        this.TreeBox(sys, game, 2 + k, lt, next, CBTreeCardX(k), rowY, cw, ch, false);
        k += 1;
      }
      rowY += ch + CBTreeRowGap();
      if ArraySize(benchIds) > 0 {
        this.PlaceLabel(words, 0.0, rowY + ch / 2.0, "THE REST", CBHudDim());
        words += 1;
        k = 0;
        while k < ArraySize(benchIds) {
          this.TreeBox(sys, game, 5 + k, sys.FindRivalById(benchIds[k]), "", CBTreeCardX(k), rowY, cw, ch, false);
          k += 1;
        }
        rowY += ch + CBTreeRowGap();
      }
      if ArraySize(fallenIds) > 0 {
        this.PlaceLabel(words, 0.0, rowY + CBTreeFallenH() / 2.0, "THE FALLEN", CBHudDim());
        words += 1;
        k = 0;
        while k < ArraySize(fallenIds) {
          this.TreeBox(sys, game, 12 + k, sys.FindRivalById(fallenIds[k]), "", CBTreeCardX(k), rowY, cw, CBTreeFallenH(), true);
          k += 1;
        }
      }
    }
    this.HideWebFrom(0, words);
    this.PaintWeb();
  }

  private func HideWeb() -> Void {
    this.m_hereSlot = -1;
    this.m_webShown = false;
    this.m_mapShown = false;
    this.m_crewPicShown = false;
    if IsDefined(this.m_webRoot) {
      this.m_webRoot.SetVisible(false);
    }
  }

  private func PlaceWord(k: Int32, x: Float, y: Float, text: String, tint: HDRColor, alpha: Float) -> Void {
    if k < 0 || k >= ArraySize(this.m_webWord) || !IsDefined(this.m_webWord[k]) {
      return;
    }
    let word = this.m_webWord[k];
    word.SetText(text);
    // Centred on (x, y) for its size: half a capital's width a letter, and six tenths of its height up.
    let size = Cast<Float>(CBPicWord());
    word.SetMargin(this.PxAt(x - Cast<Float>(StrLen(text)) * size * CBHudCapsEm() * 0.5, y - size * 0.6));
    word.SetTintColor(tint);
    word.SetOpacity(alpha);
    word.SetVisible(true);
  }

  // Filled from the books as the page is drawn: nothing per frame.
  // The gangs as cards (2.5.0): a grid, the ones that want V dead first, then the corporations and the police in a row of
  // their own. Each card is the gang, where it stands with V in a word and a bar from red to green, and the one thing
  // most worth knowing: what is live between them and V, or who they are at war with. No lines: the web drew a line
  // from V to every gang and between gangs at war, and however it was laid out the lines crossed boxes and words.
  private func RenderWeb(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let score = sys.GetScore();
    if !this.WebPoolReady() || !IsDefined(score) {
      return;
    }
    this.m_webShown = true;
    this.m_webRoot.SetVisible(true);
    let place = 0;
    while place < ArraySize(this.m_webBox) {
      this.PlaceWebBox(place, 0.0, 0.0, 10.0, 10.0, false);
      this.ResetBoxLook(place);
      place += 1;
    }
    // The order: worst first, as the list has it, and the corporations and police after.
    ArrayClear(this.m_webOrder);
    let i = 1;
    while i <= 11 {
      let rank = CBCardRank(score, CBWebSlotGang(i));
      let k = 0;
      while k < ArraySize(this.m_webOrder) && CBCardRank(score, CBWebSlotGang(this.m_webOrder[k])) <= rank {
        k += 1;
      }
      ArrayInsert(this.m_webOrder, k, i);
      i += 1;
    }
    let w = CBCardW();
    let h = CBCardH();
    let n = 0;
    while n < ArraySize(this.m_webOrder) {
      let col = n % 4;
      let row = n / 4;
      this.GangCard(sys, game, score, this.m_webOrder[n], Cast<Float>(col) * (w + CBCardGapX()), Cast<Float>(row) * (h + CBCardGapY()),
                    w, h, false);
      n += 1;
    }
    // V's crew in the grid's empty place (2.6.0).
    this.m_crewCardShown = false;
    if ArraySize(this.m_webOrder) == 11 {
      this.CrewWebCard(sys, game, 3.0 * (w + CBCardGapX()), 2.0 * (h + CBCardGapY()), w, h);
    }
    let corpY = 3.0 * (h + CBCardGapY());
    let c = 12;
    while c <= 15 {
      ArrayPush(this.m_webOrder, c);
      this.GangCard(sys, game, score, c, Cast<Float>(c - 12) * (w + CBCardGapX()), corpY, w, CBCardSmallH(), true);
      c += 1;
    }
    this.HideWebFrom(0, 0);
    this.PaintWeb();
  }

  // V's crew among the gangs (2.6.0), in the box the web once drew V in: its name and colours, and how the gang picked
  // stands with it, or else the one that thinks least of it. Clicked, the Crew page's screen for the crew itself.
  private func CrewWebCard(sys: ref<CyberbaneSystem>, game: GameInstance, x: Float, y: Float, w: Float, h: Float) -> Void {
    let book = CBCrewBook.Get(game);
    let bb = CBCrewBannerBook.Get(game);
    if !CBMyCrewOn() || !IsDefined(book) || !IsDefined(bb) || (book.Count() == 0 && bb.StandCount() == 0 && bb.FallenCount() == 0) {
      return;
    }
    let slot = 0;
    this.PlaceWebBox(slot, x, y, w, h, true);
    this.DressBox(slot, w, h, CBPicName(), CBPicLine(), CBPicLead(), false);
    let colour = CBCrewColour(game);
    let name = CBCrewNameOf(game);
    this.BoxText(this.m_webBoxName[slot], StrLen(name) > 0 ? name : "Your crew", w - 24.0, CBPicName(), CBPicNameLeast(), true);
    let kb = CBCrewKitBook.Get(game);
    let wars = IsDefined(kb) ? kb.WarsWon() : 0;
    let line = s"\(book.Count()) ON THE ROSTER" + (wars > 0 ? s"  /  \(wars) \(wars == 1 ? "WAR" : "WARS") WON" : "");
    this.BoxText(this.m_webBoxLine[slot], line, w - 24.0, CBPicLine(), CBPicLineLeast(), false);
    if IsDefined(this.m_webBoxLine[slot]) {
      this.m_webBoxLine[slot].SetTintColor(colour);
    }
    if IsDefined(this.m_webBoxEdge[slot]) {
      this.m_webBoxEdge[slot].SetTintColor(colour);
      this.m_webBoxEdge[slot].SetVisible(true);
    }
    let gang = this.m_pickFaction;
    if !IsNameValid(gang) || !CBWebSlotIsGang(CBWebSlotOf(gang)) {
      gang = CBCrewWorstGang(game);
    }
    let v = IsNameValid(gang) ? bb.Standing(gang) : 0;
    let lead = IsNameValid(gang) ? s"\(CBCrewStandWord(v)) with \(CBPhoneGangSender(gang))" : "No gang holds a grudge yet";
    if IsDefined(this.m_webBoxLead[slot]) {
      this.BoxText(this.m_webBoxLead[slot], lead, w - 24.0, CBPicLead(), CBPicLeadLeast(), false);
      this.m_webBoxLead[slot].SetTintColor(IsNameValid(gang) ? CBCrewStandTint(v) : CBHudDim());
      this.m_webBoxLead[slot].SetVisible(true);
    }
    this.BoxBarSigned(slot, w, h, ClampF(Cast<Float>(v) / 100.0, -1.0, 1.0), v < 0 ? CBHudRed() : CBHudGreen());
    this.m_crewCardShown = true;
  }

  // One gang's card.
  private func GangCard(sys: ref<CyberbaneSystem>, game: GameInstance, score: ref<CBScoreEngine>, slot: Int32,
                        x: Float, y: Float, w: Float, h: Float, small: Bool) -> Void {
    this.PlaceWebBox(slot, x, y, w, h, true);
    this.DressBox(slot, w, h, small ? CBPicSmallName() : CBPicName(), small ? CBPicSmallLine() : CBPicLine(), CBPicLead(), false);
    let gang = CBWebSlotGang(slot);
    let on = CBFactionOn(gang);
    let posture = score.GetPosture(gang);
    let tint = on ? CBWebPostureColour(posture) : CBHudDim();
    this.BoxText(this.m_webBoxName[slot], CBPhoneGangSender(gang), w - 24.0, small ? CBPicSmallName() : CBPicName(), CBPicNameLeast(), true);
    this.BoxText(this.m_webBoxLine[slot], CBWebBoxLine(sys, game, gang), w - 24.0, small ? CBPicSmallLine() : CBPicLine(), CBPicLineLeast(), false);
    if IsDefined(this.m_webBoxLine[slot]) {
      this.m_webBoxLine[slot].SetTintColor(tint);
    }
    if IsDefined(this.m_webBoxEdge[slot]) {
      this.m_webBoxEdge[slot].SetTintColor(tint);
      this.m_webBoxEdge[slot].SetVisible(true);
    }
    if small || !on {
      return;
    }
    // What is live between them and V, else who they are at war with. With a gang picked, every other card says instead
    // how it stands with that one, so one click reads the whole web for it (2.5.0): the lines the web drew, in words.
    let tag = CBWebVWord(sys, game, gang);
    let tagTint = CBWebVWordTint(tag);
    let picked = this.m_pickFaction;
    if IsNameValid(picked) && NotEquals(picked, gang) && CBWebSlotIsGang(CBWebSlotOf(picked)) && CBFactionOn(picked) {
      let kind = CBWebPair(sys, game, gang, picked);
      tag = CBCardPairWords(kind, CBPhoneGangSender(picked));
      tagTint = CBCardPairTint(kind);
    } else {
      if StrLen(tag) == 0 {
        let enemy = CBTopEnemyOf(sys, sys.GetContent(), gang);
        if IsNameValid(enemy) {
          tag = "At war with " + CBPhoneGangSender(enemy);
          tagTint = CBHudDim();
        }
      }
    }
    if IsDefined(this.m_webBoxLead[slot]) {
      this.BoxText(this.m_webBoxLead[slot], tag, w - 24.0, CBPicLead(), CBPicLeadLeast(), false);
      this.m_webBoxLead[slot].SetTintColor(tagTint);
      this.m_webBoxLead[slot].SetVisible(StrLen(tag) > 0);
    }
    let standing = score.GetStanding(gang);
    this.BoxBarSigned(slot, w, h, ClampF(standing / 100.0, -1.0, 1.0), standing < 0.0 ? CBHudRed() : CBHudGreen());
  }

  // A box's bar, lit from the middle towards the side `frac` (-1..1) leans, as the gangs' list rows have it.
  private func BoxBarSigned(s: Int32, w: Float, h: Float, frac: Float, tint: HDRColor) -> Void {
    if s < 0 || s >= ArraySize(this.m_webBarMen) {
      return;
    }
    if IsDefined(this.m_webBarMen[s]) { this.m_webBarMen[s].SetVisible(false); }
    if s < ArraySize(this.m_webBarChest) && IsDefined(this.m_webBarChest[s]) { this.m_webBarChest[s].SetVisible(false); }
    this.PlaceSegments(this.m_webSeg, (s * 2) * CBHudBarSegs(), 12.0, h - 13.0, w - 24.0, 7.0, frac, tint, true);
    this.HideSegments(this.m_webSeg, (s * 2 + 1) * CBHudBarSegs());
  }

  // A word that starts at `x` rather than centred on it.
  private func PlaceLabel(k: Int32, x: Float, y: Float, text: String, tint: HDRColor) -> Void {
    this.PlaceWord(k, x + Cast<Float>(StrLen(text)) * Cast<Float>(CBPicWord()) * CBHudCapsEm() * 0.5, y, text, tint, 1.0);
  }

  // The boxes' bands: picked, under the cursor, or at rest.
  private func PaintWeb() -> Void {
    let pickSlot = this.m_webShown ? CBWebSlotOf(this.m_pickFaction) : -1;
    if this.m_treeShown && this.m_pickRival > 0 {
      pickSlot = ArrayFindFirst(this.m_treeSlotRival, this.m_pickRival);
    }
    if this.m_mapShown && NotEquals(this.m_pickDistrict, n"") {
      pickSlot = ArrayFindFirst(this.m_boxDistrict, this.m_pickDistrict);
    }
    if this.m_crewPicShown && this.m_pickCrew != 0 {
      pickSlot = ArrayFindFirst(this.m_boxCrew, this.m_pickCrew);
    }
    let s = 0;
    while s < ArraySize(this.m_webBoxBg) {
      let hot = s < ArraySize(this.m_webBoxNames) && Equals(this.m_webBoxNames[s], this.m_hover);
      // The card: darker at rest, lighter under the cursor, the game's picked colour when chosen. The frame takes the
      // colour of what the box is (its edge), cyan when chosen, and lights under the cursor.
      if s < ArraySize(this.m_webBoxArt) && IsDefined(this.m_webBoxArt[s]) {
        this.m_webBoxArt[s].SetTintColor(s == pickSlot ? CBHudGameRowPicked() : (hot ? CBHudGameCellHot() : CBHudGameCell()));
      }
      if s < ArraySize(this.m_webBoxFrame) && IsDefined(this.m_webBoxFrame[s]) {
        let frame = CBHudGameCellEdge();
        if s < ArraySize(this.m_webBoxEdge) && IsDefined(this.m_webBoxEdge[s]) && this.m_webBoxEdge[s].IsVisible() {
          frame = this.m_webBoxEdge[s].GetTintColor();
        }
        if s == this.m_hereSlot {
          frame = CBHudHead();
        }
        if s == pickSlot || hot {
          frame = CBHudCyan();
        }
        this.m_webBoxFrame[s].SetTintColor(frame);
        this.m_webBoxFrame[s].SetOpacity(s == pickSlot || hot || s == this.m_hereSlot ? 1.0 : 0.75);
      }
      s += 1;
    }
    let g = 0;
    while g < ArraySize(this.m_webGlow) && g < ArraySize(this.m_webLine) {
      if IsDefined(this.m_webGlow[g]) && IsDefined(this.m_webLine[g]) {
        this.m_webGlow[g].SetVisible(this.m_webLine[g].IsVisible());
      }
      g += 1;
    }
    if IsDefined(this.m_webToggleBg) {
      this.m_webToggleBg.SetTintColor(Equals(this.m_hover, CBHudWebToggleName()) ? CBHudButtonHover() : CBHudButtonIdle());
    }
  }

  // ---- The pool's boxes, dressed for each drawing (2.5.0) --------------------------------------------------------

  // The size of each of a box's three lines, whether the first two are centred, and where each sits. Every drawing
  // dresses the boxes it uses, so none inherits another drawing's sizes.
  private func DressBox(s: Int32, w: Float, h: Float, nameSize: Int32, lineSize: Int32, leadSize: Int32, centred: Bool) -> Void {
    if s < 0 || s >= ArraySize(this.m_webBox) {
      return;
    }
    let inset = centred ? 0.0 : 12.0;
    let textW = MaxF(w - inset - 8.0, 10.0);
    let lineY = 3.0 + Cast<Float>(nameSize) * 1.2;
    let leadY = lineY + Cast<Float>(lineSize) * 1.3;
    let align = centred ? textHorizontalAlignment.Center : textHorizontalAlignment.Left;
    if s < ArraySize(this.m_webBoxName) && IsDefined(this.m_webBoxName[s]) {
      let name = this.m_webBoxName[s];
      name.SetFontSize(Max(1, RoundF(Cast<Float>(nameSize) * this.Scale())));
      name.SetHorizontalAlignment(align);
      name.SetFitToContent(false);
      name.SetSize(this.PxSize(centred ? w : textW, Cast<Float>(nameSize) * 1.35));
      name.SetMargin(this.PxAt(inset, 3.0));
    }
    if s < ArraySize(this.m_webBoxLine) && IsDefined(this.m_webBoxLine[s]) {
      let line = this.m_webBoxLine[s];
      line.SetFontSize(Max(1, RoundF(Cast<Float>(lineSize) * this.Scale())));
      line.SetHorizontalAlignment(align);
      line.SetFitToContent(false);
      line.SetSize(this.PxSize(centred ? w : textW, Cast<Float>(lineSize) * 1.35));
      line.SetMargin(this.PxAt(inset, lineY));
    }
    if s < ArraySize(this.m_webBoxLead) && IsDefined(this.m_webBoxLead[s]) {
      let lead = this.m_webBoxLead[s];
      lead.SetFontSize(Max(1, RoundF(Cast<Float>(leadSize) * this.Scale())));
      lead.SetHorizontalAlignment(textHorizontalAlignment.Left);
      lead.SetFitToContent(false);
      lead.SetSize(this.PxSize(MaxF(w - 20.0, 10.0), Cast<Float>(leadSize) * 1.35));
      lead.SetMargin(this.PxAt(12.0, leadY));
    }
  }

  // A box's colours, bars and edge back to how the web built them, before a drawing uses it: the pictures share the
  // pool, and none may show another's bars, tints or edge.
  private func ResetBoxLook(s: Int32) -> Void {
    if s < 0 || s >= ArraySize(this.m_webBox) {
      return;
    }
    if s < ArraySize(this.m_webBoxLead) && IsDefined(this.m_webBoxLead[s]) {
      this.m_webBoxLead[s].SetTintColor(CBHudDim());
      this.m_webBoxLead[s].SetVisible(false);
    }
    if s < ArraySize(this.m_webBarMen) && IsDefined(this.m_webBarMen[s]) {
      this.m_webBarMen[s].SetTintColor(CBHudCyan());
      this.m_webBarMen[s].SetSize(this.PxSize(2.0, 3.0));
      this.m_webBarMen[s].SetVisible(false);
    }
    if s < ArraySize(this.m_webBarChest) && IsDefined(this.m_webBarChest[s]) {
      this.m_webBarChest[s].SetTintColor(CBHudAmber());
      this.m_webBarChest[s].SetSize(this.PxSize(2.0, 3.0));
      this.m_webBarChest[s].SetVisible(false);
    }
    if s < ArraySize(this.m_webBoxEdge) && IsDefined(this.m_webBoxEdge[s]) {
      this.m_webBoxEdge[s].SetVisible(false);
    }
    this.HideSegments(this.m_webSeg, (s * 2) * CBHudBarSegs());
    this.HideSegments(this.m_webSeg, (s * 2 + 1) * CBHudBarSegs());
    if IsDefined(this.m_webBox[s]) {
      this.m_webBox[s].SetOpacity(1.0);
    }
  }

  // The web's own dress for a box, as it was built.
  private func DressDefault(s: Int32, w: Float, h: Float) -> Void {
    if s == 0 {
      this.DressBox(s, w, h, CBPicV(), CBPicLead(), CBPicLead(), true);
    } else {
      let big = CBWebSlotIsGang(s);
      this.DressBox(s, w, h, big ? CBPicName() : CBPicSmallName(), big ? CBPicLine() : CBPicSmallLine(), CBPicLead(), false);
    }
  }

  // Text that always fits the width it is given: drawn smaller, down to `least`, and only then shortened, at a word.
  private func BoxText(t: wref<inkText>, text: String, width: Float, base: Int32, least: Int32, caps: Bool) -> Void {
    if !IsDefined(t) {
      return;
    }
    if caps {
      text = CBHudBoxName(text, width, base, least);
    }
    let em = caps ? CBHudCapsEm() : CBHudCharEm();
    let len = Max(StrLen(text), 1);
    let size = base;
    let fitAt = Cast<Int32>(width / (Cast<Float>(len) * em));
    if fitAt < size {
      size = Max(least, fitAt);
    }
    let room = Max(4, Cast<Int32>(width / (Cast<Float>(size) * em)));
    t.SetFontSize(Max(1, RoundF(Cast<Float>(size) * this.Scale())));
    t.SetText(StrLen(text) > room ? CBHudTrimWords(text, room) : text);
  }

  // A box's two bars, at its foot: `a` across the whole width, or with `b` given (0..1), the two side by side.
  private func BoxBars(s: Int32, w: Float, h: Float, a: Float, aTint: HDRColor, b: Float, bTint: HDRColor) -> Void {
    if s < 0 || s >= ArraySize(this.m_webBarMen) {
      return;
    }
    // The plain bars are the web's; a picture of these segments instead (2.5.0).
    if IsDefined(this.m_webBarMen[s]) { this.m_webBarMen[s].SetVisible(false); }
    if s < ArraySize(this.m_webBarChest) && IsDefined(this.m_webBarChest[s]) { this.m_webBarChest[s].SetVisible(false); }
    let two = b >= 0.0;
    let full = w - 24.0;
    let half = w / 2.0 - 16.0;
    let firstA = (s * 2) * CBHudBarSegs();
    let firstB = (s * 2 + 1) * CBHudBarSegs();
    if a >= 0.0 {
      this.PlaceSegments(this.m_webSeg, firstA, 12.0, h - 13.0, two ? half : full, 7.0, a, aTint, false);
    } else {
      this.HideSegments(this.m_webSeg, firstA);
    }
    if two {
      this.PlaceSegments(this.m_webSeg, firstB, w / 2.0 + 4.0, h - 13.0, half, 7.0, b, bTint, false);
    } else {
      this.HideSegments(this.m_webSeg, firstB);
    }
  }

  // Is the whole pool there, every list the same length? Built together in BuildWeb, so they always are; a drawing
  // that indexes them by slot asks first, because a read past the end is a crash, not an error.
  private func WebPoolReady() -> Bool {
    let n = ArraySize(this.m_webBox);
    return n >= CBWebSlotCount() && ArraySize(this.m_webBoxName) == n && ArraySize(this.m_webBoxLine) == n
        && ArraySize(this.m_webBoxLead) == n && ArraySize(this.m_webBoxEdge) == n && ArraySize(this.m_webBarMen) == n
        && ArraySize(this.m_webBarChest) == n && ArraySize(this.m_webBoxBg) == n && IsDefined(this.m_webRoot);
  }

  // Every line and word from these on out of sight: a drawing uses the first few.
  private func HideWebFrom(lines: Int32, words: Int32) -> Void {
    let k = lines;
    while k < ArraySize(this.m_webLine) {
      if IsDefined(this.m_webLine[k]) {
        this.m_webLine[k].SetVisible(false);
      }
      k += 1;
    }
    k = words;
    while k < ArraySize(this.m_webWord) {
      if IsDefined(this.m_webWord[k]) {
        this.m_webWord[k].SetVisible(false);
      }
      k += 1;
    }
  }

  // ---- Night City as a map (2.5.0) ---------------------------------------------------------------------------------

  // Each district a box where it lies, joined by its roads. On the Turf page a box is the gang holding it, coloured by
  // how they treat V, with their hold and V's name there as two bars; on the City page it is V's renown there, coloured
  // by how hot V's name runs. Click a district for the whole of it underneath.
  // The districts as cards (2.5.0): two rows of four, in the order the game lists them. On Turf a card is who holds the
  // district, coloured by how they treat V, with how firmly as its bar and what is moving there; on The City it is V's
  // renown there. The district V is in has a white frame. No roads: lines between the boxes crossed them.
  private func RenderMap(sys: ref<CyberbaneSystem>, game: GameInstance, turf: Bool) -> Void {
    let score = sys.GetScore();
    if !this.WebPoolReady() {
      return;
    }
    this.m_mapShown = true;
    this.m_webRoot.SetVisible(true);
    while ArraySize(this.m_boxDistrict) < ArraySize(this.m_webBox) {
      ArrayPush(this.m_boxDistrict, n"");
    }
    let w = CBCardW();
    let h = CBCardH();
    let here = sys.GetCurrentDistrict();
    let content = sys.GetContent();
    let s = 0;
    while s < ArraySize(this.m_webBox) {
      let show = s < CBDistrictCount();
      let col = s % 4;
      let row = s / 4;
      this.PlaceWebBox(s, Cast<Float>(col) * (w + CBCardGapX()), Cast<Float>(row) * (h + CBCardGapY()), w, h, show);
      this.ResetBoxLook(s);
      this.m_boxDistrict[s] = show ? CBDistrictAt(s) : n"";
      if show {
        this.DressBox(s, w, h, CBPicName(), CBPicLine(), CBPicLead(), false);
        let d = CBDistrictAt(s);
        if Equals(d, here) {
          this.m_hereSlot = s;
        }
        let ds = sys.FindDistrict(d);
        let renown = IsDefined(ds) ? ds.renown : 0.0;
        let tint = CBHudGrey();
        let barTint = CBHudCyan();
        let line = "";
        let lead = "";
        let a = 0.0;
        if turf {
          let ids: array<CName>;
          let shares: array<Float>;
          CBTurfShares(sys, game, d, ids, shares);
          let holder = CBTurfHolder(sys, game, d);
          let top = ArrayFindFirst(ids, holder);
          let second = -1;
          let i = 0;
          while i < ArraySize(ids) {
            if i != top && (second < 0 || shares[i] > shares[second]) {
              second = i;
            }
            i += 1;
          }
          if top >= 0 && IsDefined(score) {
            let posture = score.GetPosture(holder);
            tint = CBWebPostureColour(posture);
            barTint = Equals(posture, ECBPosture.Neutral) ? CBHudCyan() : tint;
            line = s"\(CBCapFirst(CBPhoneGangSender(holder))) hold \(RoundF(shares[top] * 100.0))%";
            lead = CBHudTurfStatus(game, content, d, holder, ids, shares, second);
            a = shares[top];
          } else {
            line = "Nobody holds it";
          }
          if CBOwnDistrict(game, d) {
            line = "Your streets";
            tint = CBHudGreen();
          }
        } else {
          let rd = RoundF(renown);
          tint = rd >= 75 ? CBHudRed() : (rd >= 40 ? CBHudAmber() : (rd >= 15 ? CBHudCyan() : CBHudGrey()));
          barTint = rd >= 15 ? tint : CBHudCyan();
          line = s"Renown \(rd)";
          let kills = IsDefined(ds) ? ds.kills : 0;
          lead = kills > 0 ? (kills == 1 ? "One put down here" : s"\(kills) put down here") : "Nothing yet";
          a = ClampF(renown / 100.0, 0.0, 1.0);
        }
        this.BoxText(this.m_webBoxName[s], CBDistrictLabel(d), w - 24.0, CBPicName(), CBPicNameLeast(), true);
        this.BoxText(this.m_webBoxLine[s], line, w - 24.0, CBPicLine(), CBPicLineLeast(), false);
        if IsDefined(this.m_webBoxLine[s]) {
          this.m_webBoxLine[s].SetTintColor(tint);
        }
        this.BoxText(this.m_webBoxLead[s], lead, w - 24.0, CBPicLead(), CBPicLeadLeast(), false);
        if IsDefined(this.m_webBoxLead[s]) {
          this.m_webBoxLead[s].SetVisible(StrLen(lead) > 0);
        }
        if IsDefined(this.m_webBoxEdge[s]) {
          this.m_webBoxEdge[s].SetTintColor(tint);
          this.m_webBoxEdge[s].SetVisible(true);
        }
        this.BoxBars(s, w, h, a, barTint, -1.0, CBHudCyan());
      }
      s += 1;
    }
    this.HideWebFrom(0, 0);
    this.PaintWeb();
  }

  // Under the map: what it shows, or everything about the district picked.
  private func MapDetail(sys: ref<CyberbaneSystem>, game: GameInstance, turf: Bool) -> String {
    let d = this.m_pickDistrict;
    // Nothing picked: only what the map shows (2.5.0). The page's own words, the gangs you have broken and every
    // district's story, are the list's, where there is room for them.
    if Equals(d, n"") {
      return turf ? "Each card is a district and the gang holding it, coloured by how they treat you: green friendly, amber hostile, red out for blood. The bar is how firmly they hold it. White frame: you are here.\nClick a district for who else wants it, and how far your name carries there."
                  : "Each card is a district and how far your name carries there: red a legend, amber known, cyan heard of. The bar is your renown. White frame: you are here.\nClick a district for what you have done there.";
    }
    let out = StrUpper(CBDistrictLabel(d)) + (Equals(d, sys.GetCurrentDistrict()) ? "   (you are here)" : "") + "\n";
    let ds = sys.FindDistrict(d);
    let renown = IsDefined(ds) ? RoundF(ds.renown) : 0;
    if turf {
      let ids: array<CName>;
      let shares: array<Float>;
      CBTurfShares(sys, game, d, ids, shares);
      let holder = CBTurfHolder(sys, game, d);
      // Everybody with streets there, the largest first.
      let order: array<Int32>;
      let i = 0;
      while i < ArraySize(ids) {
        let k = 0;
        while k < ArraySize(order) && shares[order[k]] >= shares[i] {
          k += 1;
        }
        ArrayInsert(order, k, i);
        i += 1;
      }
      let list = "";
      for o in order {
        let part = s"\(CBCapFirst(CBPhoneGangSender(ids[o]))) \(RoundF(shares[o] * 100.0))%";
        list = StrLen(list) > 0 ? list + ", " + part : part;
      }
      if NotEquals(holder, n"") {
        out += s"\(CBCapFirst(CBFactionLabel(holder))) hold it. ";
      }
      if StrLen(list) > 0 {
        out += "Who has streets here: " + list + ".\n";
      } else {
        out += "No gang has streets here.\n";
      }
      let second = -1;
      let top = ArrayFindFirst(ids, holder);
      i = 0;
      while i < ArraySize(ids) {
        if i != top && (second < 0 || shares[i] > shares[second]) {
          second = i;
        }
        i += 1;
      }
      if top >= 0 {
        let status = CBHudTurfStatus(game, sys.GetContent(), d, holder, ids, shares, second);
        if StrLen(status) > 0 {
          out += CBCapFirst(status) + ".\n";
        }
      }
      if CBOwnDistrict(game, d) {
        out += "Nobody runs it but you. The gangs pass through on your say-so.\n";
      }
      out += s"Your name here: \(renown) of 100.";
      return out;
    }
    let peak = IsDefined(ds) ? RoundF(ds.renownPeak) : 0;
    out += s"Your renown here: \(renown) of 100" + (peak > renown ? s", at its height \(peak)" : "") + ".\n";
    if IsDefined(ds) && ds.kills > 0 {
      out += ds.kills == 1 ? "One put down here" : s"\(ds.kills) put down here";
      if ds.lethalOrBrutal > 0 {
        out += s", \(ds.lethalOrBrutal) of them the hard way";
      }
      if ds.quietTakedowns > 0 {
        out += s", \(ds.quietTakedowns) taken down without a sound";
      }
      out += ".\n";
      let quiet = CBHudSince(CBGameSeconds(game), ds.lastIncidentAt);
      if StrLen(quiet) > 0 {
        out += s"The last trouble here was \(quiet) ago.";
      }
    } else {
      out += "You have not made any trouble here yet.";
    }
    return out;
  }

  private func MapPick(sys: ref<CyberbaneSystem>, game: GameInstance, slot: Int32) -> Void {
    let d = slot >= 0 && slot < ArraySize(this.m_boxDistrict) ? this.m_boxDistrict[slot] : n"";
    if Equals(d, n"") {
      return;
    }
    this.m_pickDistrict = Equals(d, this.m_pickDistrict) ? n"" : d;
    this.Render(sys, game);
  }

  // ---- The crew (Reactions/Crew.reds, 2.5.0) --------------------------------------------------------------------------

  // V's crew: as a picture with V in the middle, or as a list, then the picked one's file and what can be done.
  private func RenderCrew(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let book = CBCrewBook.Get(game);
    let x = CBHudMarginX();
    let w = CBHudContentW();
    if !CBMyCrewOn() || !IsDefined(book) {
      this.SetBody(x, CBHudContentTop(), w, CBCrewSummary(sys, game), CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let now = CBGameSeconds(game);
    if this.m_crewMode != 0 && this.RenderCrewMode(sys, game, book) {
      return;
    }
    let offer = book.offerSeed != 0 && book.offerUntil >= now;
    // The pick: still on the roster, or the offer still standing; otherwise the first of them.
    if this.m_pickCrew > 0 && !IsDefined(book.Find(this.m_pickCrew)) {
      this.m_pickCrew = 0;
    }
    if this.m_pickCrew == -1 && !offer {
      this.m_pickCrew = 0;
    }
    if this.m_pickCrew == 0 {
      this.m_pickCrew = book.Count() > 0 ? book.At(0).id : (offer ? -1 : 0);
    }
    let anything = book.Count() > 0 || offer;
    if !anything && book.PastCount() == 0 {
      this.SetBody(x, CBHudContentTop(), w, CBCrewSummary(sys, game), CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let top = CBHudContentTop();
    if sys.HubVisual(CBHudCrewTab()) {
      this.RenderCrewPicture(sys, game, book, offer);
      top += CBWebHeight() + 24.0;
    } else {
      let rows = this.RenderCrewRows(sys, game, book, offer);
      top += Cast<Float>(Max(rows, 1)) * CBHudRowHeight() + 24.0;
    }
    // What can be done: call them, pay the cut, the picked one's orders or the solo hired, and the crew itself.
    let why = "";
    if book.Count() > 0 {
      if book.reqCall {
        this.SetAction("Calling them. Click to take it back", true);
      } else {
        let blocked = CBCrewCallBlocked(sys, game, false);
        this.SetAction("Need you. Now.", StrLen(blocked) == 0);
        if StrLen(blocked) > 0 {
          why = "Can't call them now: " + StrLower(StrLeft(blocked, 1)) + StrRight(blocked, StrLen(blocked) - 1) + "\n";
        }
      }
    }
    if book.CutOwed() > 0 {
      if book.reqPay {
        this.SetExtra(1, "Paying. Click to take it back", true);
      } else {
        this.SetExtra(1, s"Pay the cut: \(book.CutOwed())eb", CBHudEddies(game) >= book.CutOwed());
      }
    }
    let m = this.m_pickCrew > 0 ? book.Find(this.m_pickCrew) : null;
    // The picked one's orders on a screen of their own (2.6.0): a button each ran off the bottom of the page.
    if IsDefined(m) {
      this.SetExtra(2, s"Orders for \(CBCrewFirst(sys, m))", true);
    }
    if offer && this.m_pickCrew == -1 {
      if book.reqHire {
        this.SetExtra(2, "Hiring. Click to take it back", true);
      } else {
        this.SetExtra(2, s"Hire the solo: \(book.offerPrice)eb", book.HasRoom() && CBHudEddies(game) >= book.offerPrice);
      }
    }
    if offer && this.m_pickCrew != -1 {
      why += "A solo is on offer: pick them to hire them.\n";
    }
    let bbPage = CBCrewBannerBook.Get(game);
    if book.Count() > 0 || (IsDefined(bbPage) && bbPage.FallenCount() > 0) {
      this.SetExtra(3, "Name, colours, the fallen", true);
    }
    let file = CBCrewFile(sys, game, book, m, this.m_pickCrew == -1);
    if IsDefined(m) && this.m_pickCrew > 0 {
      file += "\n" + CBCrewKitLines(sys, game, m);
    }
    let crewName = CBCrewNameOf(game);
    let named = StrLen(crewName) > 0 ? StrUpper(crewName) + "\n" : "";
    let kbWars = CBCrewKitBook.Get(game);
    if IsDefined(kbWars) && kbWars.WarsWon() > 0 {
      named += s"Wars your crew started and won: \(kbWars.WarsWon()).\n";
    }
    let text = named + why + (StrLen(file) > 0 ? file + "\n" + CBCrewSummary(sys, game) : CBCrewSummary(sys, game));
    this.SetBody(x, top, anything ? w - CBHudActionW() - 40.0 : w, text, CBHudMaxLinesFor(this.m_tab));
  }

  // The Crew page's other screens (2.6.0): a member's orders and the lists they pick from, the crew's own record,
  // naming it, and the memorial. False when there is nobody to show it for.
  private func RenderCrewMode(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Bool {
    let x = CBHudMarginX();
    let w = CBHudContentW();
    let top = CBHudContentTop();
    let m = this.m_pickCrew > 0 ? book.Find(this.m_pickCrew) : null;
    let forMember = (this.m_crewMode >= 1 && this.m_crewMode <= 3) || this.m_crewMode == 6;
    if forMember && !IsDefined(m) {
      this.m_crewMode = 0;
      return false;
    }
    this.HideWeb();
    if this.m_crewMode == 4 {
      this.ShowNameInput(game, x, top);
      this.SetAction("Save the name", true);
      this.SetExtra(1, "Cancel", true);
      this.SetBody(x, top + 110.0, w - CBHudActionW() - 40.0,
        "Type a name for your crew, then save it. Letters, numbers, spaces and - ' . & ! only, up to 24. Save it empty to go without one.",
        CBHudMaxLinesFor(this.m_tab));
      return true;
    }
    if this.m_crewMode == 5 {
      this.RenderCrewFallen(sys, game);
      return true;
    }
    if this.m_crewMode == 6 {
      this.RenderCrewOrders(sys, game, book, m);
      return true;
    }
    if this.m_crewMode == 7 {
      this.RenderCrewRecord(sys, game, book);
      return true;
    }
    this.PlaceRows(CBHudLayoutCrew());
    let player = GetPlayer(game);
    let ts = GameInstance.GetTransactionSystem(game);
    let row = 0;
    let intro = "";
    let name = CBCrewName(sys, m);
    if this.m_crewMode == 1 || this.m_crewMode == 2 {
      // What V has, less anything already asked to go to one of them.
      let choices = this.m_crewMode == 1 ? CBCrewWeaponChoices(game) : CBCrewChromeChoices(game);
      let kbItems = CBCrewKitBook.Get(game);
      ArrayClear(this.m_pickItems);
      for c in choices {
        if !IsDefined(kbItems) || !kbItems.ItemAsked(c) {
          ArrayPush(this.m_pickItems, c);
        }
      }
      let i = 0;
      while i < ArraySize(this.m_pickItems) && row < CBHudListRows() {
        let id = this.m_pickItems[i];
        let data = IsDefined(ts) && IsDefined(player) ? ts.GetItemData(player, id) : null;
        let kind = "";
        let tier = "";
        if IsDefined(data) {
          tier = CBCrewTierWord(CBCrewTierOf(RPGManager.GetItemQuality(data)));
          kind = this.m_crewMode == 1 ? CBCrewSeatWord(CBCrewSeatForWeapon(data.GetItemType()))
                                      : CBCrewChromeWords(CBCrewChromeRead(ItemID.GetTDBID(id)), 1);
        }
        this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBCrewItemName(ItemID.GetTDBID(id)), kind, tier, "", "", "");
        this.m_rowCrew[row] = i + 1;
        row += 1;
        i += 1;
      }
      intro = this.m_crewMode == 1
        ? s"Pick a weapon for \(name). Its mods and attachments go back in your bag. From their next call they fight the way it is used, and it adds to their damage by its quality. Take it back any time; it comes back if they leave."
        : s"Pick chrome for \(name), from what you own and do not wear. It goes in for good and does for them what it does in a fight, by the game's own numbers. Chrome that only helps you (RAM, zoom, stamina) is not listed. Up to \(CBCrewChromeSlots()).";
      if row == 0 {
        intro = this.m_crewMode == 1 ? "You have no spare weapon to give: everything is equipped, or there is nothing a person could fight with."
                                     : "You have no spare chrome that would help them in a fight: what you own is installed in you, or only helps you.";
      }
    }
    if this.m_crewMode == 3 {
      this.m_pickGangs = CBCrewWarTargets(sys);
      let g = 0;
      while g < ArraySize(this.m_pickGangs) && row < CBHudListRows() {
        let gang = this.m_pickGangs[g];
        let stand = CBCrewStandingWith(game, gang);
        this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBCapFirst(CBFactionLabel(gang)),
          CBGangStrengthWord(CBGangStrength(sys, gang)), "", s"your crew: \(StrLower(CBCrewStandWord(stand)))", "", "");
        this.m_rowCrew[row] = g + 1;
        row += 1;
        g += 1;
      }
      intro = s"Pick a gang for \(name) to start a war on. Away \(RoundF(CBConfig.CrewWarHours())) hours. Won, the gang loses ground and blames you; lost, \(name) comes back hurt, or not at all. The weaker the gang, the better the odds, and a gang that already hates your crew is ready for it.";
      if row == 0 {
        intro = "No gang to go to war on: every gang that fields people is friendly with you.";
      }
    }
    this.SetAction("Back", true);
    let bodyTop = top + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(x, bodyTop, w - CBHudActionW() - 40.0, intro, CBHudMaxLinesFor(this.m_tab));
    return true;
  }

  // One member's orders (2.6.0), a row each, carried out back in the game. One asked for says so, and clicked again
  // before then is taken back.
  private func RenderCrewOrders(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>) -> Void {
    let now = CBGameSeconds(game);
    let kb = CBCrewKitBook.Get(game);
    let k = IsDefined(kb) ? kb.Find(m.id) : null;
    let out = book.IsOut(m.id);
    let free = !out && !CBCrewAway(game, m.id, now);
    let hurt = CBCrewHurt(m, now);
    let asked = false;
    this.PlaceRows(CBHudLayoutCrew());
    // A weapon from V's bag, or theirs handed back.
    if IsDefined(k) && k.hasWeapon {
      asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskTakeBack());
      this.CrewOrderRow(0, CBCrewAskTakeBack(), asked ? "Handing it back..." : "Take your weapon back", free || asked, asked,
                        CBCrewItemName(ItemID.GetTDBID(k.weapon)), StrUpper(CBCrewTierWord(k.weaponTier)));
    } else {
      asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskGive());
      this.CrewOrderRow(0, CBCrewAskGive(), asked ? "A weapon on its way..." : "Give them a weapon", free || asked, asked,
                        "nothing of yours", "");
    }
    // Chrome.
    let chrome = IsDefined(k) ? k.ChromeCount() : 0;
    let room = chrome < CBCrewChromeSlots();
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskChrome());
    this.CrewOrderRow(1, CBCrewAskChrome(), asked ? "Chrome on its way..." : (room ? "Have chrome put in" : "No room for more chrome"),
                      (free && room) || asked, asked, s"\(chrome) of \(CBCrewChromeSlots()) fitted", "");
    // Training.
    let trained = IsDefined(k) ? k.trained : 0;
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskTrain());
    if trained >= CBConfig.CrewTrainMax() {
      this.CrewOrderRow(2, CBCrewAskTrain(), "Fully trained", false, false, s"\(trained) of \(CBConfig.CrewTrainMax()) done", "");
    } else {
      let cost = CBCrewTrainCost(k);
      this.CrewOrderRow(2, CBCrewAskTrain(), asked ? "Off to train..." : "Send them to train",
                        (free && !hurt && CBHudEddies(game) >= cost) || asked, asked,
                        hurt ? "hurt: not yet" : s"away \(RoundF(CBCrewTrainHours(k))) hours", s"\(cost)EB");
    }
    // A war, from Lieutenant up.
    let rank = CBCrewRankOf(game, m);
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskWar());
    if rank < CBConfig.CrewWarMinRank() {
      this.CrewOrderRow(3, CBCrewAskWar(), "Send them to start a war", false, false,
                        s"needs \(CBCrewRankWord(CBConfig.CrewWarMinRank()))", "");
    } else {
      this.CrewOrderRow(3, CBCrewAskWar(), asked ? "Off to war..." : "Send them to start a war", (free && !hurt) || asked, asked,
                        hurt ? "hurt: not yet" : s"away \(RoundF(CBConfig.CrewWarHours())) hours", "");
    }
    // A spar.
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskSpar());
    if IsDefined(kb) && kb.sparMember == m.id {
      this.CrewOrderRow(4, CBCrewAskSpar(), "Sparring now", false, false, "", "");
    } else {
      let sparWhy = asked ? "" : CBCrewSparBlocked(sys, game, m, now);
      this.CrewOrderRow(4, CBCrewAskSpar(), asked ? "Coming to spar..." : "Spar with them", StrLen(sparWhy) == 0, asked, sparWhy, "");
    }
    // Work: earning, recruiting, or none.
    let work = CBCrewWorkOf(game, m.id);
    let next = CBCrewNextWork(game, m.id);
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskWork());
    let workLabel = next == 1 ? "Put them to work earning" : (next == 2 ? "Put them to recruiting" : "Stop their work");
    this.CrewOrderRow(5, CBCrewAskWork(), asked ? "Telling them..." : workLabel, free || asked, asked,
                      s"now: \(CBCrewWorkWord(work))", work == 1 ? s"\(CBConfig.CrewEarnPerRank() * rank)EB A DAY" : "");
    // Letting them go, asked twice.
    if book.reqLetGo == m.id {
      this.CrewOrderRow(6, CBHudCrewOrderLetGo(), "Keep them", true, true, "leaving your crew", "");
    } else {
      this.CrewOrderRow(6, CBHudCrewOrderLetGo(), this.m_letGoArmed == m.id ? "Click again to let go" : "Let them go", !out, false,
                        out ? "with you: wait" : "", "");
    }
    let text = CBCrewFile(sys, game, book, m, false) + "\n" + CBCrewKitLines(sys, game, m) + "\n"
             + "Orders happen as you pick them; their texts come once you are back in the game. A spar waits for the game: click it again before then to call it off. One of your crew recruits at a time.";
    if out {
      text = "With you now: orders wait until they are home.\n" + text;
    }
    this.SetAction("Back", true);
    let bodyTop = CBHudContentTop() + 7.0 * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  private func CrewOrderRow(row: Int32, code: Int32, label: String, clickable: Bool, asked: Bool, detail: String, right: String) -> Void {
    this.SetRow(row, CBHudLayoutCrew(), asked ? CBHudCyan() : (clickable ? CBHudLabel() : CBHudDim()), clickable, asked,
                label, "", "", detail, "", right);
    if row >= 0 && row < ArraySize(this.m_rowCrew) {
      this.m_rowCrew[row] = code;
    }
  }

  // An order picked: a list to pick from, the order asked for, or taken back if it already was.
  private func CrewOrderClicked(game: GameInstance, code: Int32) -> Void {
    let kb = CBCrewKitBook.Get(game);
    let cb = CBCrewBook.Get(game);
    let id = this.m_pickCrew;
    if !IsDefined(kb) || !IsDefined(cb) || id <= 0 || code <= 0 {
      return;
    }
    if code != CBHudCrewOrderLetGo() {
      this.m_letGoArmed = 0;
    }
    if code < CBHudCrewOrderLetGo() && kb.Asked(id, code) {
      kb.Unask(id, code);
      return;
    }
    let noItem: ItemID;
    if code == CBCrewAskGive() { this.m_crewMode = 1; }
    if code == CBCrewAskChrome() { this.m_crewMode = 2; }
    if code == CBCrewAskWar() { this.m_crewMode = 3; }
    if code == CBCrewAskTakeBack() || code == CBCrewAskTrain() || code == CBCrewAskSpar() || code == CBCrewAskWork() {
      kb.Ask(id, code, noItem, n"");
      CBCrewKitDoNow(CyberbaneSystem.Get(game), game);   // all but a spar, here and now
    }
    if code == CBHudCrewOrderLetGo() {
      if cb.reqLetGo == id {
        cb.reqLetGo = 0;
        this.m_letGoArmed = 0;
      } else {
        if this.m_letGoArmed == id {
          cb.reqLetGo = id;
          this.m_letGoArmed = 0;
        } else {
          this.m_letGoArmed = id;
        }
      }
    }
  }

  // The crew itself (2.6.0): its name, its colours, the memorial, and its own standing with each gang, worst first.
  private func RenderCrewRecord(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
    let bb = CBCrewBannerBook.Get(game);
    let kb = CBCrewKitBook.Get(game);
    this.PlaceRows(CBHudLayoutCrew());
    let name = CBCrewNameOf(game);
    this.SetRow(0, CBHudLayoutCrew(), CBHudLabel(), true, false, StrLen(name) > 0 ? "Rename your crew" : "Name your crew", "", "",
                StrLen(name) > 0 ? name : "no name yet", "", "");
    this.m_rowCrew[0] = 1;
    let colour = CBCrewColourIndex(game);
    this.SetRow(1, CBHudLayoutCrew(), CBCrewColourTint(colour), true, false, "Change its colours", StrUpper(CBCrewColourWord(colour)), "",
                "click for the next", "", "");
    this.m_rowCrew[1] = 2;
    let fallen = IsDefined(bb) ? bb.FallenCount() : 0;
    this.SetRow(2, CBHudLayoutCrew(), fallen > 0 ? CBHudLabel() : CBHudDim(), fallen > 0, false, "Remember the fallen", "", "",
                fallen > 0 ? s"\(fallen) \(fallen == 1 ? "name" : "names")" : "nobody yet", "", "");
    this.m_rowCrew[2] = 3;
    let row = 3;
    // Its standing, worst first.
    let order: array<Int32>;
    let n = IsDefined(bb) ? bb.StandCount() : 0;
    let i = 0;
    while i < n {
      let v = bb.StandValueAt(i);
      let at = 0;
      while at < ArraySize(order) && bb.StandValueAt(order[at]) <= v {
        at += 1;
      }
      ArrayInsert(order, at, i);
      i += 1;
    }
    let shown = 0;
    for idx in order {
      let gang = bb.StandGangAt(idx);
      if row < CBHudListRows() && CBFactionOn(gang) {
        let value = bb.StandValueAt(idx);
        let tint = CBCrewStandTint(value);
        this.SetRow(row, CBHudLayoutCrew(), tint, false, false, CBPhoneGangSender(gang), StrUpper(CBCrewStandWord(value)), "", "", "",
                    s"\(value)");
        this.SetRowBar(row, CBHudCrewBarX(), CBHudCrewBarW(), ClampF(Cast<Float>(value) / 100.0, -1.0, 1.0), tint, true);
        this.m_rowCrew[row] = 0;
        row += 1;
        shown += 1;
      }
    }
    let wars = IsDefined(kb) ? kb.WarsWon() : 0;
    let text = (StrLen(name) > 0 ? StrUpper(name) : "YOUR CREW") + "\n"
             + s"\(book.Count()) on the roster, \(fallen) fallen" + (wars > 0 ? s", \(wars) \(wars == 1 ? "war" : "wars") won." : ".") + "\n";
    if shown == 0 {
      text += "No gang thinks anything of your crew yet.\n";
    }
    text += "Your crew has its own standing with the gangs, apart from yours. A war it starts sets that gang against it, more when it wins, and pleases the gang at war with them. A gang that lends you somebody warms to it; one whose people it scares into joining or kills cools, and so does one that kills one of yours. A gang that hates your crew is ready for its next war. It all eases a little every day.";
    this.SetAction("Back", true);
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  private func CrewRecordClicked(game: GameInstance, code: Int32) -> Void {
    if code == 1 {
      this.m_crewMode = 4;
    }
    if code == 2 {
      let bb = CBCrewBannerBook.Get(game);
      if IsDefined(bb) {
        bb.reqColour = (CBCrewColourIndex(game) + 1) % CBCrewColourCount() + 1;   // the next one, carried out on the tick
      }
    }
    if code == 3 {
      this.m_crewMode = 5;
      this.m_pickFallen = 0;
    }
  }

  // The memorial (2.6.0): the fallen, the last first; one picked, what is remembered of them.
  private func RenderCrewFallen(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let bb = CBCrewBannerBook.Get(game);
    this.PlaceRows(CBHudLayoutCrew());
    let row = 0;
    let n = IsDefined(bb) ? bb.FallenCount() : 0;
    let picked: ref<CBCrewFallen>;
    let i = n - 1;
    while i >= 0 && row < CBHudListRows() {
      let f = bb.FallenAt(i);
      if IsDefined(f) {
        let isPicked = this.m_pickFallen == i + 1;
        if isPicked {
          picked = f;
        }
        this.SetRow(row, CBHudLayoutCrew(), CBCrewColour(game), true, isPicked, CBCrewFallenName(sys, f), CBCrewRankWord(f.rank), "",
                    CBCrewFallenShort(sys, f), "", StrUpper(CBCrewFallenAgo(game, f)));
        this.m_rowCrew[row] = i + 1;
        row += 1;
      }
      i -= 1;
    }
    let text = IsDefined(picked) ? CBCrewEpitaph(sys, game, picked)
             : "THE FALLEN\nThe ones who died for your crew, and what they carried. Pick a name to read what is remembered of them.";
    if n == 0 {
      text = "THE FALLEN\nNobody from your crew has died yet.";
    }
    this.SetAction("Back", true);
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  // The name box, built the first time it is wanted (Codeware's HubTextInput), in the page's own panel.
  private func ShowNameInput(game: GameInstance, x: Float, y: Float) -> Void {
    if !IsDefined(this.m_nameInput) && IsDefined(this.m_panel) {
      let input = HubTextInput.Create();
      input.SetName(n"CBCrewNameInput");
      input.SetMaxLength(CBConfig.CrewNameMaxLength());
      input.SetDefaultText("Name your crew");
      input.Reparent(this.m_panel);
      input.SetText(CBCrewNameOf(game));
      this.m_nameInput = input;
    }
    if !IsDefined(this.m_nameInput) {
      return;
    }
    let root = this.m_nameInput.GetRootWidget();
    if IsDefined(root) {
      root.SetVisible(true);
      root.SetMargin(this.PxAt(x, y));
    }
    this.m_nameInput.SetWidth(this.Px(760.0));
  }

  private func RenderCrewRows(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, offer: Bool) -> Int32 {
    this.PlaceRows(CBHudLayoutCrew());
    let now = CBGameSeconds(game);
    let row = 0;
    let i = 0;
    while i < book.Count() && row < CBHudListRows() {
      let m = book.At(i);
      i += 1;
      if IsDefined(m) {
        let state = CBCrewStateWord(book, m, now);
        this.SetRow(row, CBHudLayoutCrew(), CBCrewStateTint(state), true, m.id == this.m_pickCrew,
          CBCrewName(sys, m), CBCrewSeatWord(m.seat), CBCrewRankShort(game, m), CBCrewFromShort(m), "", state);
        this.SetRowBar(row, CBHudCrewBarX(), CBHudCrewBarW(), Cast<Float>(m.loyalty) / 100.0, CBCrewLoyaltyTint(m.loyalty));
        this.m_rowCrew[row] = m.id;
        row += 1;
      }
    }
    if offer && row < CBHudListRows() {
      let seat = CBCrewSeatOf(CBHunterRecord(book.offerSeed, n""), book.offerSeed);
      this.SetRow(row, CBHudLayoutCrew(), CBHudGrey(), true, this.m_pickCrew == -1,
        CBCrewOfferName(sys, game, book), CBCrewSeatWord(seat), "", "a solo on offer", "",
        s"\(book.offerPrice)EB");
      this.m_rowCrew[row] = -1;
      row += 1;
    }
    return row;
  }

  // V in the middle and the crew round V, each line as strong and as warm as their loyalty; the solo on offer to one
  // side, and the last few who left along the bottom, with how they left.
  // V's crew as cards (2.5.0): the crew in a row, a solo on offer under it, and the ones who are gone under that, each row
  // named. Each card is who they are, their seat and rank, how they are and where they came from, and their loyalty as
  // the bar. No lines from a V in the middle: they crossed the cards and their words.
  private func RenderCrewPicture(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, offer: Bool) -> Void {
    if !this.WebPoolReady() {
      return;
    }
    this.m_crewPicShown = true;
    this.m_webRoot.SetVisible(true);
    while ArraySize(this.m_boxCrew) < ArraySize(this.m_webBox) {
      ArrayPush(this.m_boxCrew, 0);
    }
    let now = CBGameSeconds(game);
    let s = 0;
    while s < ArraySize(this.m_webBox) {
      this.PlaceWebBox(s, 0.0, 0.0, 10.0, 10.0, false);
      this.ResetBoxLook(s);
      this.m_boxCrew[s] = 0;
      s += 1;
    }
    let words = 0;
    let mw = CBCrewCardW();
    let mh = CBCrewCardH();
    let y = 0.0;
    this.PlaceLabel(words, 0.0, y + 10.0, s"YOUR CREW  (\(book.Count()) OF \(CBConfig.MyCrewRoster()))", CBHudDim());
    words += 1;
    y += 28.0;
    let k = 0;
    while k < book.Count() && k < 5 {
      let m = book.At(k);
      let slot = k + 1;
      if IsDefined(m) {
        let tint = CBCrewLoyaltyTint(m.loyalty);
        this.PlaceWebBox(slot, Cast<Float>(k) * (mw + CBCrewCardGap()), y, mw, mh, true);
        this.DressBox(slot, mw, mh, CBPicName(), CBPicLine(), CBPicLead(), false);
        this.BoxText(this.m_webBoxName[slot], CBCrewBoxName(sys, m), mw - 24.0, CBPicName(), CBPicNameLeast(), true);
        this.BoxText(this.m_webBoxLine[slot], StrUpper(CBCrewSeatWord(m.seat)) + "  /  " + StrUpper(CBCrewRankShort(GetGameInstance(), m)), mw - 24.0,
                     CBPicLine(), CBPicLineLeast(), false);
        if IsDefined(this.m_webBoxLine[slot]) { this.m_webBoxLine[slot].SetTintColor(tint); }
        let state = CBCrewStateWord(book, m, now);
        this.BoxText(this.m_webBoxLead[slot], state + "  /  " + CBCrewFromShort(m), mw - 24.0, CBPicLead(), CBPicLeadLeast(), false);
        if IsDefined(this.m_webBoxLead[slot]) {
          this.m_webBoxLead[slot].SetVisible(true);
          this.m_webBoxLead[slot].SetTintColor(CBCrewStateTint(state));
        }
        if IsDefined(this.m_webBoxEdge[slot]) {
          this.m_webBoxEdge[slot].SetTintColor(CBCrewColour(game));   // the crew's colours (2.6.0)
          this.m_webBoxEdge[slot].SetVisible(true);
        }
        this.BoxBars(slot, mw, mh, Cast<Float>(m.loyalty) / 100.0, tint, -1.0, CBHudCyan());
        this.m_boxCrew[slot] = m.id;
      }
      k += 1;
    }
    if book.Count() > 0 {
      y += mh + 20.0;
    }
    if offer {
      let os = 6;
      this.PlaceLabel(words, 0.0, y + 10.0, s"ON OFFER FROM \(StrUpper(book.offerSender))", CBHudDim());
      words += 1;
      y += 28.0;
      let seat = CBCrewSeatOf(CBHunterRecord(book.offerSeed, n""), book.offerSeed);
      this.PlaceWebBox(os, 0.0, y, mw, mh, true);
      this.DressBox(os, mw, mh, CBPicName(), CBPicLine(), CBPicLead(), false);
      this.BoxText(this.m_webBoxName[os], CBCrewOfferName(sys, game, book), mw - 24.0, CBPicName(),
                   CBPicNameLeast(), true);
      this.BoxText(this.m_webBoxLine[os], StrUpper(CBCrewSeatWord(seat)) + s"  /  \(book.offerPrice)EB", mw - 24.0, CBPicLine(),
                   CBPicLineLeast(), false);
      if IsDefined(this.m_webBoxLine[os]) { this.m_webBoxLine[os].SetTintColor(CBHudGrey()); }
      this.BoxText(this.m_webBoxLead[os], "A solo for hire", mw - 24.0, CBPicLead(), CBPicLeadLeast(), false);
      if IsDefined(this.m_webBoxLead[os]) {
        this.m_webBoxLead[os].SetVisible(true);
        this.m_webBoxLead[os].SetTintColor(CBHudDim());
      }
      if IsDefined(this.m_webBoxEdge[os]) {
        this.m_webBoxEdge[os].SetTintColor(CBHudGrey());
        this.m_webBoxEdge[os].SetVisible(true);
      }
      this.m_boxCrew[os] = -1;
      y += mh + 20.0;
    }
    if book.PastCount() > 0 {
      this.PlaceLabel(words, 0.0, y + 10.0, "GONE", CBHudDim());
      words += 1;
      y += 28.0;
    }
    let shown = 0;
    let p = book.PastCount() - 1;
    while p >= 0 && shown < 4 {
      let past = book.PastAt(p);
      p -= 1;
      if IsDefined(past) {
        let ps = 12 + shown;
        let tint = CBCrewEndTint(past.end);
        this.PlaceWebBox(ps, Cast<Float>(shown) * (mw + CBCrewCardGap()), y, mw, CBTreeFallenH(), true);
        this.DressBox(ps, mw, CBTreeFallenH(), CBPicSmallName(), CBPicSmallLine(), CBPicLead(), false);
        this.BoxText(this.m_webBoxName[ps], CBCrewFirstName(sys, past.kind, past.faction, past.rival, past.seed), mw - 24.0,
                     CBPicSmallName(), CBPicLineLeast(), true);
        this.BoxText(this.m_webBoxLine[ps], CBCrewEndWord(past.end), mw - 24.0, CBPicSmallLine(), 14, false);
        if IsDefined(this.m_webBoxLine[ps]) { this.m_webBoxLine[ps].SetTintColor(tint); }
        if IsDefined(this.m_webBoxLead[ps]) { this.m_webBoxLead[ps].SetVisible(false); }
        if IsDefined(this.m_webBoxEdge[ps]) {
          this.m_webBoxEdge[ps].SetTintColor(tint);
          this.m_webBoxEdge[ps].SetVisible(true);
        }
        shown += 1;
      }
    }
    this.HideWebFrom(0, words);
    this.PaintWeb();
  }

  private func CrewPick(sys: ref<CyberbaneSystem>, game: GameInstance, slot: Int32) -> Void {
    let id = slot >= 0 && slot < ArraySize(this.m_boxCrew) ? this.m_boxCrew[slot] : 0;
    if id == 0 {
      return;
    }
    this.m_pickCrew = id;
    this.m_letGoArmed = 0;
    this.Render(sys, game);
  }


  private func Render(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if !IsDefined(this.m_root) || !this.m_open {
      return;
    }
    if this.m_tab != CBHudCrewTab() {
      this.m_crewMode = 0;
    }
    if IsDefined(this.m_nameInput) && this.m_crewMode != 4 {
      let nameRoot = this.m_nameInput.GetRootWidget();
      if IsDefined(nameRoot) {
        nameRoot.SetVisible(false);
      }
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
    this.HideWeb();
    this.m_treeShown = false;
    // Every page that has a picture can be read as a list instead (2.5.0): the web, the map, the tree, the crew.
    let pictured = CBHudHasPicture(this.m_tab) && !(this.m_tab == CBHudTurfTab() && !CBTurfWarsOn());
    if IsDefined(this.m_webToggle) {
      this.m_webToggle.SetVisible(pictured);
    }
    if IsDefined(this.m_webToggleText) && pictured {
      this.m_webToggleText.SetText(sys.HubVisual(this.m_tab) ? "Show as a list" : CBHudPictureWord(this.m_tab));
    }
    this.SetAction("", false);
    this.HideExtras();
    this.PlaceActions(CBHudDetailTop() - 4.0);
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
    // The crew (Reactions/Crew.reds, 2.5.0): a page of its own, drawn whole by RenderCrew.
    if this.m_tab == CBHudCrewTab() {
      this.RenderCrew(sys, game);
      this.Paint();
      this.m_root.SetVisible(true);
      this.ForeignOverlaysOff();
      return;
    }
    if this.m_tab == CBHudStandingTab() {
      // Four tiles, what is on its way as rows, and two or three lines of why (2.5.0).
      this.RenderScores(sys);
      let lanesEnd = this.RenderLanes(sys, game);
      // A price on V's head can be paid off here (Spawn/Bounty.reds, 2.4.3); asks twice, like every payment.
      let payOff = CBBountyPayOff(sys, game);
      let proseW = w;
      if payOff > 0 {
        if CBBountyPayPending(game) {
          this.SetAction("Paying it off. Click to take it back", true);
        } else {
          if this.m_bountyArmed {
            this.SetAction(s"Click again: pay \(payOff)eb", true);
          } else {
            this.SetAction(s"Pay off the price on you (\(payOff)eb)", CBHudEddies(game) >= payOff);
          }
        }
        proseW = w - CBHudActionW() - 40.0;
      }
      this.SetBody(x, lanesEnd + 16.0, proseW, CBHudLegend(sys, game), maxLines);
    } else {
      if this.m_tab == CBHudFactionsTab() {
        // The gangs as a list, or as the web of gangs (UI/HubWeb.reds, 2.4.3); the panel below is the same either way.
        if sys.HubWeb() {
          this.RenderWeb(sys, game);
        } else {
          this.RenderFactions(sys);
        }
        this.RenderFactionDetail(sys, game);
      } else {
        if this.m_tab == CBHudTurfTab() {
          // Night City as a map (2.5.0), or the list.
          if sys.HubVisual(CBHudTurfTab()) && CBTurfWarsOn() {
            this.RenderMap(sys, game, true);
            this.SetBody(x, CBHudContentTop() + CBGridMapH() + 20.0, w, this.MapDetail(sys, game, true), maxLines);
          } else {
            let turfRows = this.RenderTurf(sys, game);
            // Straight under the last district rather than under ten rows' worth of empty space.
            let turfTop = CBHudContentTop() + Cast<Float>(Max(turfRows, 1)) * CBHudRowHeight() + 24.0;
            this.SetBody(x, turfTop, w, CBHudTurfBody(sys), maxLines);
          }
        } else {
          if this.m_tab == CBHudCityTab() {
            if sys.HubVisual(CBHudCityTab()) {
              this.RenderMap(sys, game, false);
              this.SetBody(x, CBHudContentTop() + CBGridMapH() + 20.0, w, this.MapDetail(sys, game, false), maxLines);
            } else {
              this.RenderCity(sys);
              this.SetBody(x, listBottom, w, CBHudDistricts(sys), maxLines);
            }
          } else {
            if this.m_tab == CBHudRivalsTab() {
              this.m_holdLabel = CBHoldLabel(sys.GetHuntHoldReason());
              // An arrival that was actually attempted and refused is more specific than the hold.
              let blocked = CBBlockLabel(CBLastSpawnBlock());
              if StrLen(blocked) > 0 && sys.GetHuntHoldReason() == CBHoldNoRoom() {
                this.m_holdLabel = blocked;
              }
              // The Rivals as a list, or as each gang's tree ([H2], 2.4.4); the file below is the same either way.
              if sys.HubTree() {
                this.RenderTree(sys, game);
              } else {
                this.RenderRivals(sys);
              }
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
                // The legend, told (2.4.6, [82]), or the day's headlines (the screamsheet, [81]) over the ledger.
                this.SetExtra(1, this.m_legendShown ? "Show the ledger" : "Tell my story", true);
                let page = "";
                if this.m_legendShown {
                  page = CBLegendTold(sys, game);
                } else {
                  let heads = CBScreamsheet(sys, game);
                  page = StrLen(heads) > 0 ? heads + "\n\n" + CBHudLog(sys) : CBHudLog(sys);
                }
                this.SetBody(x, CBHudContentTop(), w, page, maxLines,
                             CBHudDetailTop() - 4.0 - CBHudFooterGap());
              }
            }
          }
        }
      }
    }
    this.Paint();
    this.m_root.SetVisible(true);
    this.ForeignOverlaysOff();
  }
}

// Other mods' overlays on the menu layer that this page covers, by the names they give them: They Will
// Remember's disguise scores (They_Will_Remember/HubMenu/DisguiseScoresUI.reds, "disguise_journal").
func CBForeignOverlayName(name: CName) -> Bool {
  return Equals(name, n"disguise_journal");
}

// Out of sight (show false) or back (show true). True when one was there to hide, visible, or to bring back.
// Only the top level of the menu layer is looked through, where those mods put them, as they look for them.
func CBForeignOverlays(show: Bool) -> Bool {
  let ink = GameInstance.GetInkSystem();
  let layer = IsDefined(ink) ? ink.GetLayer(n"inkMenuLayer") : null;
  let window = IsDefined(layer) ? layer.GetVirtualWindow() : null;
  if !IsDefined(window) {
    return false;
  }
  let found = false;
  let count = window.GetNumChildren();
  let i = 0;
  while i < count {
    let w = window.GetWidgetByIndex(i);
    i += 1;
    if IsDefined(w) && CBForeignOverlayName(w.GetName()) {
      if show {
        if !w.IsVisible() {
          w.SetVisible(true);
          found = true;
        }
      } else {
        if w.IsVisible() {
          w.SetVisible(false);
          found = true;
        }
      }
    }
  }
  return found;
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
  if !CBFactionOn(id) {
    return "Switched off under Factions in Mod Settings: Cyberbane leaves them alone, so there is nothing to pay them for.";
  }
  if CBGangViewSet(id) {
    return "How they treat you is set under How gangs see you in Mod Settings, so money changes nothing. Set them to Earned in play to deal.";
  }
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
// A name for a box (CBHud.BoxText): whole when it fits at a comfortable size (four under its own), else a name with a
// nickname in it, First "Nick" Last, gives up a part before anything is cut: the nickname and surname, then the first
// name and surname, then the nickname alone (2.5.0). The whole name is in the file under the picture.
public func CBHudBoxName(text: String, width: Float, base: Int32, least: Int32) -> String {
  let comfy = Cast<Int32>(width / (Cast<Float>(Max(least, base - 4)) * CBHudCapsEm()));
  if StrLen(text) <= comfy {
    return text;
  }
  let a = StrFindFirst(text, "\"");
  let b = StrFindLast(text, "\"");
  if a < 0 || b <= a {
    return text;
  }
  let first = a > 1 ? StrLeft(text, a - 1) : "";
  let nick = StrMid(text, a, b - a + 1);
  let last = b + 2 < StrLen(text) ? StrRight(text, StrLen(text) - b - 2) : "";
  let nickLast = StrLen(last) > 0 ? nick + " " + last : nick;
  let firstLast = StrLen(first) > 0 && StrLen(last) > 0 ? first + " " + last : (StrLen(first) > 0 ? first : last);
  let tight = Cast<Int32>(width / (Cast<Float>(least) * CBHudCapsEm()));
  if StrLen(nickLast) <= comfy { return nickLast; }
  if StrLen(firstLast) <= comfy { return firstLast; }
  if StrLen(nickLast) <= tight { return nickLast; }
  if StrLen(firstLast) <= tight { return firstLast; }
  if StrLen(nick) <= tight { return nick; }
  return firstLast;
}

// First "Nick" Last as First Last, for a line that names somebody in passing (2.5.0). Anything else as it is.
public func CBHudNameNoNick(text: String) -> String {
  let a = StrFindFirst(text, "\"");
  let b = StrFindLast(text, "\"");
  if a < 0 || b <= a {
    return text;
  }
  let first = a > 1 ? StrLeft(text, a - 1) : "";
  let last = b + 2 < StrLen(text) ? StrRight(text, StrLen(text) - b - 2) : "";
  if StrLen(first) > 0 && StrLen(last) > 0 {
    return first + " " + last;
  }
  return StrLen(first) > 0 ? first : (StrLen(last) > 0 ? last : text);
}

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
    // Rivals who came together say so (1.9.0).
    if lane == CBLaneRival() {
      let together = CBRivalsOutTogether(sys, game);
      if together > 1 {
        return label + "   here now, " + CBNumberWord(together) + " of them together";
      }
    }
    return label + "   here now";
  }
  // A lane's clock does not run while nobody can arrive (CBLaneTick), so a countdown shown then stood
  // still with nothing to say why: the stuck clock this screen was built to never show.
  let held = CBArrivalsHeldWhy(sys, game);
  // Nothing queued. Say whether that is because the day's allowance is spent, rather than
  // leaving "nobody" to mean both "none due" and "none left", which look identical and are
  // the sort of silence that reads as the mod being broken.
  if StrLen(who) == 0 {
    if CBLaneDailyCap(lane) <= 0 {
      return label + "   off";
    }
    // Nobody who could come at all (2.5.3): said instead of the next window's time, which on a new game read as a
    // Rival, a crew and an apex squad on their way with nobody against V.
    let nobody = CBLaneNobodyWhy(sys, lane);
    if StrLen(nobody) > 0 {
      return label + "   " + nobody;
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
      // Nor does anybody get picked while arrivals are held, so "nobody qualifies" was untrue then too.
      if StrLen(held) > 0 {
        return label + "   due, waiting: " + held + CBHudBudgetTail(sys, game, lane);
      }
      let rest = CBLaneRestLeft(sys, lane);
      if rest > 0 {
        return label + "   breather, " + CBTimeText(rest) + CBHudBudgetTail(sys, game, lane);
      }
      // Every Rival V has is lying low after their last fight, which is a reason, not nobody.
      if lane == CBLaneRival() && sys.CountActiveRivals() > 0 && CBRivalsAllLyingLow(sys) {
        return label + "   due, every Rival is lying low" + CBHudBudgetTail(sys, game, lane);
      }
      return label + "   due, nobody qualifies yet" + CBHudBudgetTail(sys, game, lane);
    }
    return label + "   next " + (CBShowCountdowns() ? "in " + CBHudRealFromGameHours(hrs) : "later today") + CBHudBudgetTail(sys, game, lane);
  }
  if StrLen(held) > 0 {
    return label + "   " + who + "  waiting: " + held + CBHudBudgetTail(sys, game, lane);
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

// The Rivals page's cards group Rivals by gang; Rivals of no gang are a group of their own, under this name (2.5.3). No
// gang is called this, and nothing but the cards' own choice of group ever holds it.
func CBTreeNoGang() -> CName = n"CB_NoGang"

func CBTreeGangOf(r: ref<CBRival>) -> CName {
  if !IsDefined(r) {
    return n"";
  }
  return Equals(r.faction, n"") ? CBTreeNoGang() : r.faction;
}

// Is every Rival who could come on their cooldown after their last fight?
func CBRivalsAllLyingLow(sys: ref<CyberbaneSystem>) -> Bool {
  for r in sys.GetRivals() {
    if IsDefined(r) && r.huntTicks <= 0 && CBRivalQueueable(sys, r.id) {
      return false;
    }
  }
  return true;
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
  // What is coming is drawn as rows under the tiles now (2.5.0, RenderLanes), each with a pip for how close it is.
  let out = "";
  // The price on V's head and the ladder (Spawn/Bounty.reds, 2.4.3), when there is one.
  let bounty = CBBountyHubLine(sys, game);
  if StrLen(bounty) > 0 {
    out += bounty + "\n";
  }
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
    return "Right now: Cyberbane is switched off in Mod Settings (Enabled, under General), so nothing reacts.";
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
  let eff = CBCrowdFear(score, CBCivIntensity() * CBCrowdMomentMult(sys, GetGameInstance()));
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

// What V is wearing, read again as the Hub opens and on every change of screen.
//
// "It tells me to cover up my chrome, but the number does not change whatever I wear." Visible chrome
// and the look are sampled every ten seconds of settled play (CyberbaneSystem fast tick), and never
// inside a menu, which is where clothes are changed. The Hub is a tab of that same menu, so a player who
// put a coat on in the inventory and went straight to the Hub was shown the reading from before the
// coat, every time; it only moved ten seconds after they closed the menu, and later still on a busy
// street, when the sample waits for the streaming to settle. Both reads are equipment and stat data
// only, the same data the inventory screen reads while it is open.
func CBHudResampleWorn(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !IsDefined(GetPlayer(game)) {
    return;
  }
  // And They Will Remember's word on who is hostile, which the gangs' standing now follows (2.4.2).
  CBTwrRefreshHostility(game);
  CBUpdateChrome(sys, game);
  CBUpdateLook(sys, game);
  let score = sys.GetScore();
  if IsDefined(score) {
    score.MarkDirty();
  }
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
  if c > best { best = c; bestLabel = "all that chrome"; bestHint = "Long sleeves, trousers and a mask hide most of it."; }
  if l > best { best = l; bestLabel = "the way you carry yourself"; bestHint = "Dress down and it eases."; }
  if x > best { best = x; bestLabel = "the things you have done"; bestHint = "The stories fade while you lie low."; }
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
  let out = "Hostile gangs send crews. Vendetta means their people shoot on sight, all but the ones too afraid of you to. Hostile and sworn gangs are listed first.\n\n";
  out += "To be thought well of: hurt the gang they are at war with, put their people down\n";
  out += "without killing them, let their names walk, spend time on their streets without\n";
  out += "trouble, or walk up to their people and greet them. Friendly gangs cut their prices on\n";
  out += "their own turf and warn you when their enemies come for you. To be feared without a\n";
  out += "body: intimidate their people. Somebody afraid enough gives up one of their Rivals.\n\n";
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
  let out = "Word spreads outward from where things happened, so you can be a legend in one "
          + "district and a nobody in the next. The bar is how widely your name carries there.";
  // How the district V is standing in takes things ([6], Data/Districts.reds).
  let temper = CBTemperWords(sys.GetCurrentDistrict());
  if StrLen(temper) > 0 {
    out += " " + temper;
  }
  return out;
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
// Whole sentences (2.5.5): the file opened on a fragment in lower case ("got away from you bleeding, at large"),
// two subjects run together ("you beat them down and left them alive, quiet").
func CBRivalSourceLine(source: Int32) -> String {
  if source == EnumInt(ECBRivalSource.Survivor) {
    return "They got away from you bleeding.";
  }
  if source == EnumInt(ECBRivalSource.Spared) {
    return "You beat them down and left them alive.";
  }
  if source == EnumInt(ECBRivalSource.Killer) {
    return "They put you down once.";
  }
  if source == EnumInt(ECBRivalSource.Avenger) {
    return "They are avenging someone you killed.";
  }
  if source == EnumInt(ECBRivalSource.Hunter) {
    return "They came for your head and lost you.";
  }
  if source == EnumInt(ECBRivalSource.Betrayer) {
    return "They ran with your crew, then turned on you.";
  }
  return "They remember you.";
}

// Where they stand now, as a sentence for the file, by the same test as their row in the tree (2.5.5): the file
// went by the state alone, so the one coming for V read "at large" under a row that said HUNTING YOU, and a dead
// one read "quiet".
func CBRivalStateLine(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> String {
  if r.state == EnumInt(ECBRivalState.Slain) {
    return "They are dead.";
  }
  if r.state == EnumInt(ECBRivalState.Retired) {
    return "They have left Night City.";
  }
  if r.id == sys.GetActiveRivalId() || r.state == EnumInt(ECBRivalState.Hunting) {
    return "They are hunting you.";
  }
  if r.state == EnumInt(ECBRivalState.Debtor) {
    return "They owe you their life.";
  }
  if r.state == EnumInt(ECBRivalState.Dormant) {
    return "They have gone quiet.";
  }
  if r.id == sys.GetLaneRivalId(CBLaneRival()) {
    return "They are at large, and next in line to come for you.";
  }
  return "They are at large.";
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
    out += CBRivalSourceLine(r.source) + " " + CBRivalStateLine(sys, r) + "\n";
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
    // A fatal flaw (Reactions/StreetIntel.reds): named once the street has told V; hinted at for a Rival
    // senior enough to have one, which is a reason to go and ask.
    let flaw = CBRivalFlaw(r);
    let intelBook = CBIntelBook.Get(game);
    if flaw > 0 && IsDefined(intelBook) && intelBook.KnowsFlaw(r.id) {
      out += "Fatal flaw: " + CBFlawWord(flaw) + " kills them outright.\n";
    } else {
      if CBFlawsOn() && r.rank >= CBConfig.FlawMinRank() {
        out += "Their people may know a fatal flaw. Squeeze one, scan one, or ask around.\n";
      }
    }
    // What the street says about them, their line, and their family (1.9.9).
    out += "On the street: " + CBRivalStreetStatus(sys, game, r) + "\n";
    out += "Says: \"" + CBRivalCatchphrase(r) + "\"\n";
    // Their story, from what is known of them (Narrative/Telling.reds, [84], 2.4.6).
    out += "Their story: " + CBRivalStory(sys, game, r) + "\n";
    let kinBook = CBIntelBook.Get(game);
    let kinOf = IsDefined(kinBook) ? kinBook.KinOf(r.id) : 0;
    let kinDead = kinOf > 0 ? sys.FindRivalById(kinOf) : null;
    if IsDefined(kinDead) {
      out += "Family of " + CBRivalDisplayName(content, kinDead) + ", whom you killed.\n";
    }
    let scars = CBScarLabel(r.scarMask);
    if StrLen(scars) > 0 {
      out += "Carries your mark: " + scars + ".\n";
    }
    // Their chrome and their bond (Rivals/RivalMoments.reds, 2.4.4).
    let chrome = CBRivalChromeWords(r);
    if StrLen(chrome) > 0 {
      out += "Chrome: " + chrome + ".\n";
    }
    let rivalBook = CBRivalBook.Get(game);
    let bondId = IsDefined(rivalBook) ? rivalBook.BondWith(r.id) : 0;
    let bonded = bondId > 0 ? sys.FindRivalById(bondId) : null;
    if IsDefined(bonded) {
      out += CBCapFirst(CBBondWord(rivalBook.BondKind(r.id))) + " " + CBRivalDisplayName(content, bonded) + ".\n";
    }
    out += "\n";
  }
  // A held arrival used to keep resetting its clock to a few seconds and never come, which read as
  // the Hub promising someone was seconds away over and over. Say what is happening.
  let held = CBStealthHoldReason(sys, game);
  if NotEquals(held, "") {
    out += held + "\n";
  }
  // Who owes V (Reactions/Allies.reds, [U12], 2.4.5).
  let owed = CBInformantsLine(sys, game);
  if StrLen(owed) > 0 {
    out += owed + "\n";
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
    if CBPhoneDealsReady() {
      return "Putting the word out. Somebody texts you a price as soon as you are back in the game.";
    }
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
    if CBPhoneDealsReady() {
      if findArmed == r.id {
        return "Click again to put the word out for where they are hiding.";
      }
      return s"Put the word out and somebody texts you a price for where they are hiding, about \(price)eb. Answer in the thread: take it, push back once, or walk away. Then go there on foot and catch them unawares. You have \(CBHudEddies(game))eb.";
    }
    if findArmed == r.id {
      return s"Click again to pay \(price)eb for where they are hiding.";
    }
    return s"\(price)eb buys where they are hiding. Go there on foot and catch them unawares. You have \(CBHudEddies(game))eb.";
  }
  if why == 1 {
    return "Turn on Tips on where Rivals are (under Rivals in Mod Settings) to buy where they are hiding.";
  }
  if why == 5 {
    return "Their faction is switched off under Factions in Mod Settings. Nobody of theirs is sent after you or found for you.";
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

// What talking to this gang's people has done today, in one line ("" for nothing yet).
func CBHudTalkToday(sys: ref<CyberbaneSystem>, faction: CName) -> String {
  let svc = IsDefined(sys) ? sys.GetPlayService() : null;
  if !IsDefined(svc) {
    return "";
  }
  let day = FloorF(CBGameSeconds(sys.GetGameInstance()) / CBConfig.SecondsPerDay());
  let t = svc.FindTalkTally(sys.GetPlaythroughId(), faction, day);
  if !IsDefined(t) {
    return "";
  }
  let parts: array<String>;
  if t.warmth > 0.05 {
    ArrayPush(parts, "warmed to you");
  }
  if t.slight >= 0.05 {
    ArrayPush(parts, "took offence");
  }
  if t.fear > 0.05 {
    ArrayPush(parts, "fear you more");
  }
  if t.leaks > 0 {
    ArrayPush(parts, "gave up a Rival");
  }
  if t.taxes > 0 {
    ArrayPush(parts, "paid you off");
  }
  if ArraySize(parts) == 0 {
    return "";
  }
  let line = "Today, from talking to their people: they ";
  let i = 0;
  while i < ArraySize(parts) {
    if i > 0 {
      line += i == ArraySize(parts) - 1 ? " and " : ", ";
    }
    line += parts[i];
    i += 1;
  }
  return line + ".";
}

// What street talk put in the file (Reactions/StreetTalk.reds, 1.9.5), and the entry's own name for
// anything this file does not know how to say.
func CBHudTalkLogLine(sys: ref<CyberbaneSystem>, e: ref<CBLogEntry>, gang: String) -> String {
  let who = StrLen(gang) > 0 ? "one of " + gang : "somebody";
  if Equals(e.kind, n"Informant") {
    let r = sys.FindRivalById(RoundF(e.value));
    let name = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "one of their own";
    return s"You leaned on \(who) until they gave up \(name).";
  }
  if Equals(e.kind, n"ShakeDown") {
    return s"You shook down \(who) for \(RoundF(e.value))eb.";
  }
  if Equals(e.kind, n"TalkWarm") {
    return StrLen(gang) > 0 ? s"Talking to their people warmed \(gang) to you." : "Talking to people warmed them to you.";
  }
  if Equals(e.kind, n"TalkSlight") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) took offence at how you spoke to their people." : "People took offence at how you spoke to them.";
  }
  if Equals(e.kind, n"TalkFear") {
    return StrLen(gang) > 0 ? s"Leaning on their people made \(gang) fear you more." : "Leaning on people made the street fear you more.";
  }
  if Equals(e.kind, n"TalkBought") {
    return s"You paid \(who) \(RoundF(e.value))eb for where a Rival was hiding.";
  }
  if Equals(e.kind, n"TalkFan") {
    return s"A fan stood you a drink: \(RoundF(e.value))eb.";
  }
  if Equals(e.kind, n"TalkToll") {
    return StrLen(gang) > 0 ? s"You paid \(gang) \(RoundF(e.value))eb to walk their streets in peace for a few hours."
                            : s"You paid \(RoundF(e.value))eb for safe passage.";
  }
  if Equals(e.kind, n"BagmanRobbed") {
    return StrLen(gang) > 0 ? s"You robbed \(CBPossessive(gang)) bagman of \(RoundF(e.value))eb." : s"You robbed a bagman of \(RoundF(e.value))eb.";
  }
  if Equals(e.kind, n"Favour") {
    return StrLen(gang) > 0 ? s"You did \(gang) a favour, for \(RoundF(e.value))eb." : "You did somebody a favour.";
  }
  if Equals(e.kind, n"MeetCrashed") {
    return "You crashed a sit-down between two gangs.";
  }
  if Equals(e.kind, n"ShotSurrendered") {
    return "You shot somebody who had given up.";
  }
  if Equals(e.kind, n"WordSent") {
    return "You called out a Rival. They named a place.";
  }
  if Equals(e.kind, n"CalledOut") {
    return "A Rival called you out and named a place.";
  }
  if Equals(e.kind, n"RivalExiled") {
    return "You ran a Rival out of Night City.";
  }
  if Equals(e.kind, n"KinSworn") {
    return "Family of a Rival you killed swore to finish what they started.";
  }
  if Equals(e.kind, n"Squeezed") {
    return s"You made \(who) talk.";
  }
  if Equals(e.kind, n"FlawLearned") {
    let r = sys.FindRivalById(RoundF(e.value));
    let name = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "a Rival";
    return s"You learnt \(name)'s fatal flaw.";
  }
  if Equals(e.kind, n"FlawKill") {
    return "A Rival died of the fatal flaw you found.";
  }
  if Equals(e.kind, n"Turned") {
    return s"You turned \(who) into an informant.";
  }
  if Equals(e.kind, n"InformantTip") {
    return "An informant of yours texted a tip.";
  }
  if Equals(e.kind, n"TalkCallOff") {
    return s"You paid \(who) \(RoundF(e.value))eb to call off the crew coming for you.";
  }
  // 2.3.1: the street.
  if Equals(e.kind, n"WitnessHushed") {
    return "You paid a witness to forget what they saw.";
  }
  if Equals(e.kind, n"KeepWatch") {
    return s"You paid somebody \(RoundF(e.value))eb to keep watch for you.";
  }
  if Equals(e.kind, n"WannabeBeaten") {
    return "A kid squared up to you for a name. You put them down.";
  }
  if Equals(e.kind, n"WannabeLost") {
    return "A kid squared up to you for a name, and won.";
  }
  if Equals(e.kind, n"WannabeWalked") {
    return "A kid squared up to you for a name. You walked away.";
  }
  if Equals(e.kind, n"WannabeShot") {
    return "You shot a kid who came at you with their fists.";
  }
  // 2.3.2: the codes.
  if Equals(e.kind, n"GuardedHurt") {
    return StrLen(gang) > 0 ? s"You hurt people \(gang) look after." : "You hurt people somebody looks after.";
  }
  if Equals(e.kind, n"LetGo") {
    return StrLen(gang) > 0 ? s"You let one of \(gang) walk with their hands up." : "You let somebody walk with their hands up.";
  }
  // 2.4.3: the price on V's head, the ladder and the corporations.
  if Equals(e.kind, n"BountyPosted") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) put a price on your head: \(RoundF(e.value))eb." : s"Somebody put a price on your head: \(RoundF(e.value))eb.";
  }
  if Equals(e.kind, n"BountyPaid") {
    return "You paid off the price on your head.";
  }
  if Equals(e.kind, n"BountyPosterDown") {
    return "Whoever put the price on your head is dead, and the price with them.";
  }
  if Equals(e.kind, n"BountyLifted") {
    return "The price on your head came down.";
  }
  if Equals(e.kind, n"HunterKilled") {
    return s"You killed a bounty hunter ranked \(RoundF(e.value)) on the ladder.";
  }
  if Equals(e.kind, n"HunterBeaten") {
    return s"You beat a bounty hunter ranked \(RoundF(e.value)) and left them breathing.";
  }
  if Equals(e.kind, n"LadderRank") {
    return RoundF(e.value) == 1 ? "You reached the top of the hunters' ladder." : s"You climbed to number \(RoundF(e.value)) on the hunters' ladder.";
  }
  if Equals(e.kind, n"CorpWarned") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) warned you off." : "A corporation warned you off.";
  }
  if Equals(e.kind, n"CorpOffer") {
    return StrLen(gang) > 0 ? s"A corporation offered you \(RoundF(e.value))eb to kill the leader of \(gang)." : "A corporation offered you a contract.";
  }
  // 2.4.5: talk and allies.
  if Equals(e.kind, n"CrewLent") { return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) sent people to watch your back." : "A gang sent people to watch your back."; }
  if Equals(e.kind, n"OneOfTheirs") { return StrLen(gang) > 0 ? s"You became one of \(gang)." : "You joined a gang."; }
  if Equals(e.kind, n"LeftGang") { return StrLen(gang) > 0 ? s"You stopped being one of \(gang)." : "You left a gang."; }
  if Equals(e.kind, n"DutyAsked") { return StrLen(gang) > 0 ? s"Your gang asked you to put down five of \(gang) in a week." : "Your gang asked a favour."; }
  if Equals(e.kind, n"DutySettled") { return e.value > 0.5 ? "You came through for your gang." : "You let your gang down."; }
  if Equals(e.kind, n"RansomPaid") { return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) paid \(RoundF(e.value))eb to get one of theirs back." : "A gang paid a ransom."; }
  if Equals(e.kind, n"RansomRefused") { return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) refused your ransom and came for their own." : "A gang refused your ransom."; }
  if Equals(e.kind, n"HandedOver") { return StrLen(gang) > 0 ? s"You handed a prisoner to \(gang)." : "You handed over a prisoner."; }
  if Equals(e.kind, n"LieSpread") { return StrLen(gang) > 0 ? s"You fed \(gang) a lie through the street." : "You fed the street a lie."; }
  if Equals(e.kind, n"LieSold") { return StrLen(gang) > 0 ? s"Somebody sold your lie out to \(gang)." : "Somebody sold you out."; }
  if Equals(e.kind, n"InformantSaved") { return "You saved an informant from their own gang."; }
  if Equals(e.kind, n"InformantLost") { return "An informant of yours was run down by their own gang."; }
  if Equals(e.kind, n"ParleyPaid") { return StrLen(gang) > 0 ? s"You paid a crew of \(gang) to say they never found you." : "You paid off a crew."; }
  if Equals(e.kind, n"ParleyScared") { return StrLen(gang) > 0 ? s"You talked a crew of \(gang) into walking away." : "You talked a crew down."; }
  // Answers by text (UI/RealPhone.reds, 2.4.6): written to the file and, until 2.6.0, read out as their own names.
  if Equals(e.kind, n"PhoneThreatWorked") { return StrLen(gang) > 0 ? s"You threatened \(gang) by text, and they backed down." : "A threat by text made a gang back down."; }
  if Equals(e.kind, n"PhoneInsult") { return StrLen(gang) > 0 ? s"You told \(gang) to come and try it." : "You dared a gang to come for you."; }
  // 2.5.0: a crew of V's own (Reactions/Crew.reds).
  let crewLine = CBCrewHistoryLine(sys, e);
  if StrLen(crewLine) > 0 {
    return crewLine;
  }
  // 2.4.4: the Rivals' moments.
  if Equals(e.kind, n"StaredDown") || Equals(e.kind, n"FacedownWalked") || Equals(e.kind, n"DuelWon")
     || Equals(e.kind, n"CalledEven") || Equals(e.kind, n"Humiliated") || Equals(e.kind, n"Trophy")
     || Equals(e.kind, n"RivalReturned") || Equals(e.kind, n"BondVengeance") || Equals(e.kind, n"RivalEndedUp")
     || Equals(e.kind, n"UnderTheKnife") || Equals(e.kind, n"FeudSet") || Equals(e.kind, n"RivalFeud")
     || Equals(e.kind, n"LairMoved") || Equals(e.kind, n"RipperdocLead") {
    let rv = sys.FindRivalById(RoundF(e.value));
    let rn = IsDefined(rv) ? CBRivalDisplayName(sys.GetContent(), rv) : "a Rival";
    if Equals(e.kind, n"StaredDown") { return s"You stared down \(rn), and their people ran."; }
    if Equals(e.kind, n"FacedownWalked") { return s"\(CBCapFirst(rn)) let you walk away, once."; }
    if Equals(e.kind, n"DuelWon") { return s"You beat \(rn) one on one while their people watched."; }
    if Equals(e.kind, n"CalledEven") { return s"You and \(rn) called it even."; }
    if Equals(e.kind, n"Humiliated") { return s"You humiliated \(rn) where they lay."; }
    if Equals(e.kind, n"Trophy") { return s"You took a trophy off \(rn)."; }
    if Equals(e.kind, n"RivalReturned") { return s"\(CBCapFirst(rn)) came back from the dead."; }
    if Equals(e.kind, n"BondVengeance") { return s"\(CBCapFirst(rn)) swore vengeance for somebody you killed."; }
    if Equals(e.kind, n"RivalEndedUp") { return s"\(CBCapFirst(rn)), long gone from Night City, got in touch."; }
    if Equals(e.kind, n"UnderTheKnife") { return s"\(CBCapFirst(rn)) went under the knife for you."; }
    if Equals(e.kind, n"FeudSet") { return s"You set a Rival on \(rn)."; }
    if Equals(e.kind, n"LairMoved") { return s"\(CBCapFirst(rn))'s lookout saw you and got away; they moved."; }
    if Equals(e.kind, n"RipperdocLead") { return s"You heard which ripperdoc \(rn) was in."; }
    return s"One Rival killed another: \(rn) is gone.";
  }
  if Equals(e.kind, n"StreetClash") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) won a fight with their enemies in the street." : "Two gangs fought in the street.";
  }
  if Equals(e.kind, n"CorpContractDone") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) paid you \(RoundF(e.value))eb for a job." : s"A corporation paid you \(RoundF(e.value))eb for a job.";
  }
  // 2.4.2: the hunt grows.
  if Equals(e.kind, n"Tracked") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) planted a tracker on you." : "Somebody planted a tracker on you.";
  }
  if Equals(e.kind, n"OpenSeason") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) declared open season on you." : "A gang declared open season on you.";
  }
  if Equals(e.kind, n"OpenSeasonSurvived") {
    return StrLen(gang) > 0 ? s"You survived \(CBPossessive(gang)) open season." : "You survived open season.";
  }
  if Equals(e.kind, n"OpenSeasonEnded") {
    return StrLen(gang) > 0 ? s"You ended \(CBPossessive(gang)) open season by killing the one who called it." : "You ended an open season by killing the one who called it.";
  }
  if Equals(e.kind, n"AmbushBeaten") {
    return StrLen(gang) > 0 ? s"You walked through \(CBPossessive(gang)) ambush on the way to a job." : "You walked through an ambush.";
  }
  // 2.4.1: being hunted.
  if Equals(e.kind, n"ScoutBribed") {
    return StrLen(gang) > 0 ? s"You paid \(CBPossessive(gang)) scout to say they never found you." : "You paid a scout to say they never found you.";
  }
  // 2.4.0: the war.
  if Equals(e.kind, n"WeeklyCut") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) paid you your cut: \(RoundF(e.value))eb." : s"You were paid your cut: \(RoundF(e.value))eb.";
  }
  if Equals(e.kind, n"Backed") {
    return StrLen(gang) > 0 ? s"You threw in with \(gang)." : "You picked a side in the war.";
  }
  if Equals(e.kind, n"Incited") {
    return StrLen(gang) > 0 ? s"You set \(gang) on their enemies with a lie." : "You set two gangs on each other with a lie.";
  }
  if Equals(e.kind, n"Truce") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) made a truce with their enemies, against you." : "Two gangs made a truce against you.";
  }
  if Equals(e.kind, n"OwnStreet") {
    return "A district became yours.";
  }
  if Equals(e.kind, n"OwnToll") {
    return s"The gangs paid their way through your streets: \(RoundF(e.value))eb.";
  }
  if Equals(e.kind, n"PeaceFavour") {
    return StrLen(gang) > 0 ? s"You did \(gang) a favour, and they called it off." : "A favour bought you peace.";
  }
  if Equals(e.kind, n"ProtectionPaid") {
    return s"You paid the Claws \(RoundF(e.value))eb for protection.";
  }
  if Equals(e.kind, n"ProtectionRefused") {
    return "You didn't pay the Claws' protection.";
  }
  // 2.3.4: the fights.
  if Equals(e.kind, n"Executed") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) executed somebody, and nobody stopped them." : "Somebody was executed, and nobody stopped it.";
  }
  if Equals(e.kind, n"PrisonerSaved") {
    return StrLen(gang) > 0 ? s"You saved one of \(gang) from an execution." : "You stopped an execution.";
  }
  if Equals(e.kind, n"FugitiveCaught") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) ran down the one they were hunting." : "A gang ran somebody down.";
  }
  if Equals(e.kind, n"FugitiveSheltered") {
    return StrLen(gang) > 0 ? s"You saved one of \(gang) from the people hunting them." : "You saved somebody from a gang's hunt.";
  }
  if Equals(e.kind, n"FrontLine") {
    return StrLen(gang) > 0 ? s"\(CBCapFirst(gang)) won a street fight and took ground." : "A street fight decided who holds the ground.";
  }
  if Equals(e.kind, n"StoodWith") {
    return StrLen(gang) > 0 ? s"You stood with \(gang) in a street fight, and won it with them." : "You picked a side in a street fight, and won.";
  }
  if Equals(e.kind, n"StoodWithLost") {
    return StrLen(gang) > 0 ? s"You stood with \(gang) in a street fight, and lost it with them." : "You picked a side in a street fight, and lost.";
  }
  if Equals(e.kind, n"StruggleBacked") {
    return StrLen(gang) > 0 ? s"You decided who runs \(gang)." : "You decided who runs a gang.";
  }
  if Equals(e.kind, n"StruggleBoth") {
    return StrLen(gang) > 0 ? s"You killed both of \(CBPossessive(gang)) would-be leaders." : "You killed both would-be leaders.";
  }
  // 2.3.3: gang life.
  if Equals(e.kind, n"FuneralCrashed") {
    return StrLen(gang) > 0 ? s"You shot up \(CBPossessive(gang)) funeral." : "You shot up a funeral.";
  }
  if Equals(e.kind, n"PaidRespects") {
    return StrLen(gang) > 0 ? s"You paid your respects at \(CBPossessive(gang)) funeral." : "You paid your respects at a funeral.";
  }
  if Equals(e.kind, n"DealCrashed") {
    return StrLen(gang) > 0 ? s"You took the guns \(gang) were buying." : "You hit an arms deal.";
  }
  if Equals(e.kind, n"RacketHit") {
    return StrLen(gang) > 0 ? s"You hit \(CBPossessive(gang)) racket for \(RoundF(e.value))eb." : s"You hit a racket for \(RoundF(e.value))eb.";
  }
  if Equals(e.kind, n"EventCrashed") {
    return StrLen(gang) > 0 ? s"You broke up something \(gang) had planned." : "You broke up a gang's plans.";
  }
  if Equals(e.kind, n"ApexBeaten") {
    return StrLen(gang) > 0 ? s"You beat \(CBPossessive(gang)) apex squad, all four." : "You beat an apex squad, all four.";
  }
  return NameToString(e.kind);
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
                              line = CBHudTalkLogLine(sys, e, gang);
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
  // A war one of V's crew started (2.6.0).
  if Equals(e.kind, n"CrewWarWon") {
    line = StrLen(gang) > 0 ? s"One of your crew started a war on \(gang), and won it." : "One of your crew started a war, and won it.";
  }
  if Equals(e.kind, n"CrewWarLost") {
    line = StrLen(gang) > 0 ? s"One of your crew went to war on \(gang), and did not come back." : "One of your crew went to war, and did not come back.";
  }
  // A Rival somebody else killed (2.5.6, CBRivalSlain): before, every Rival's death was written as V's.
  if Equals(e.kind, n"RivalDied") {
    line = StrLen(gang) > 0 ? s"A rank \(RoundF(e.value)) rival from \(gang) died, and not by your hand."
                            : s"A rank \(RoundF(e.value)) rival died, and not by your hand.";
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
  // Said as what they are (2.5.5): one who owes V their life read "quiet", the word for one keeping their head down.
  // Their life, in full: "owes you" alone reads as money.
  if state == EnumInt(ECBRivalState.Debtor) {
    return "owes you their life";
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

// What V's clothes are doing, under the chrome bar (1.9.4): what they cover, a mask, and whose gear
// fools whom. "Is there a way to know which clothes affect the gangs?" This is it.
func CBHudWornLine(sys: ref<CyberbaneSystem>) -> String {
  if !CBClothingCounts() {
    return "Clothes are not read (Mod Settings), so all your chrome shows.";
  }
  let worn = sys.GetWorn();
  if !IsDefined(worn) {
    return "What a stranger clocks from across the street. Arms read loudest.";
  }
  let parts = "";
  if worn.arms { parts = "arms"; }
  if worn.legs { parts = StrLen(parts) > 0 ? parts + ", legs" : "legs"; }
  if worn.face { parts = StrLen(parts) > 0 ? parts + ", eyes" : "eyes"; }
  let line = StrLen(parts) > 0 ? "Covered: " + parts + "." : "Nothing you wear covers your chrome.";
  if worn.masked {
    line += " Masked: nobody can place you.";
  } else {
    if worn.twrRead && worn.twrFace >= 0.05 {
      line += s" Face \(RoundF(worn.twrFace * 100.0))% hidden.";
    }
  }
  let gang = CBFactionLabel(sys.GetDisguiseFaction());
  if StrLen(gang) > 0 {
    line += worn.twrRead ? s" Passing for \(gang), \(RoundF(sys.GetDisguiseStrength() * 100.0))%." : " In " + gang + " gear: slower to place you.";
  }
  // Whose reading this is, when it is not Cyberbane's own (2.4.2).
  if worn.twrRead {
    line += " (They Will Remember's reading.)";
  } else {
    if CBTwrActive() {
      let rtWhy = CyberbaneRuntime.Get();
      let why = IsDefined(rtWhy) ? rtWhy.TwrDisguiseWhy() : "";
      if StrLen(why) > 0 {
        line += " They Will Remember's disguises could not be read (" + why + "); this is Cyberbane's own.";
      } else {
        line += " They Will Remember's disguises could not be read; this is Cyberbane's own.";
      }
    }
  }
  return line;
}

// Where a Rival sits in their gang, for the hierarchy on the Rivals screen: the leader, then the
// lieutenants, then everybody else by rank and how often they have met V.
func CBHudRivalStanding(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> Int32 {
  let role = CBRivalRole(sys, r);
  let place = role == CBRoleLeader() ? 2000 : (role == CBRoleLieutenant() ? 1000 : 0);
  return place + r.rank * 100 + Min(r.encounters, 99);
}

// ---- The Hub's pictures and tiles (2.5.0) --------------------------------------------------------------------------

// The four scores, two by two.
public func CBHudTileW() -> Float = 640.0
public func CBHudTileGap() -> Float = 40.0
public func CBHudTileStride() -> Float = 124.0

// The pages that can be drawn as a picture, and what the switch offers when one is showing as a list.
public func CBHudHasPicture(tab: Int32) -> Bool {
  return tab == CBHudFactionsTab() || tab == CBHudTurfTab() || tab == CBHudCityTab() || tab == CBHudRivalsTab()
      || tab == CBHudCrewTab();
}

public func CBHudPictureWord(tab: Int32) -> String {
  return "Show as cards";
}

// One word for a crew member's state, as a colour.
public func CBCrewStateTint(state: String) -> HDRColor {
  if Equals(state, "WITH YOU") { return CBHudGreen(); }
  if StrBeginsWith(state, "HURT") { return CBHudRed(); }
  if Equals(state, "RESTLESS") { return CBHudAmber(); }
  if Equals(state, "RESTING") { return CBHudGrey(); }
  return CBHudCyan();
}

// ---- The map: each district roughly where it lies (index order of CBDistrictAt) --------------------------------------
//
// Watson at the top, City Center under it and Westbrook to its east, Heywood below with Santo Domingo to its east,
// Pacifica to the south-west with Dogtown at its foot, and the Badlands out east. The roads join neighbours.

// The cards (2.5.0): four to a row across the page, the gangs' grid three rows and the corporations' small row, the
// districts two rows.
public func CBCardW() -> Float = 315.0
public func CBCardH() -> Float = 104.0
public func CBCardSmallH() -> Float = 56.0
public func CBCardGapX() -> Float = 20.0
public func CBCardGapY() -> Float = 14.0
public func CBGridGangsH() -> Float = 410.0   // 3 x 104 + 3 x 14 + 56
public func CBGridMapH() -> Float = 222.0     // 2 x 104 + 14

// The Rivals' rows: a column for the row's name, then up to four cards.
public func CBTreeCardW() -> Float = 280.0
public func CBTreeCardH() -> Float = 92.0
public func CBTreeFallenH() -> Float = 56.0
public func CBTreeRowGap() -> Float = 14.0
public func CBTreeCardX(k: Int32) -> Float = 160.0 + Cast<Float>(k) * 293.0

// ---- The crew picture --------------------------------------------------------------------------------------------

// The crew's cards: five across the page.
public func CBCrewCardW() -> Float = 252.0
public func CBCrewCardH() -> Float = 110.0
public func CBCrewCardGap() -> Float = 15.0
