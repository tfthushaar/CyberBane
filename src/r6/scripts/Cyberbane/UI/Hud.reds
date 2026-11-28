import Codeware.UI.*   // HubTextInput, the crew's name box

// Cyberbane - The Hub (spec §12.1)
//
// A page of the pause menu: Escape, then Cyberbane. It opens over the menu's own list, the game stays paused underneath
// it, and everything on it is driven with the menu's own cursor. Click a screen name to change screen (or use the
// previous/next tab keys, Q and E or LB and RB), click a row to see more about it, click a title to go by it.

// Seven screens. Messages are not one of them: they live in V's phone (UI/RealPhone.reds).
public func CBHudTabCount() -> Int32 = 7
public func CBHudStandingTab() -> Int32 = 1
public func CBHudFactionsTab() -> Int32 = 2
// Next to GANGS on purpose: what the gangs think of V, then their streets. One map, two readings: who holds each
// district, and where V's name carries (the city's page, which it took in).
public func CBHudTurfTab() -> Int32 = 3
public func CBHudCityTab() -> Int32 = 3
public func CBHudRivalsTab() -> Int32 = 4
// Next to the Rivals: the people against V, then the people with V (Reactions/Crew.reds).
public func CBHudCrewTab() -> Int32 = 5
public func CBHudTitlesTab() -> Int32 = 6
public func CBHudHistoryTab() -> Int32 = 7

// Lines of prose each screen has room for under its own content, before the footer rule at 934.
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
// Everything is written against a fixed 1920x1080 design, centred and scaled as one piece to the space it is drawn in.
public func CBHudPanelW() -> Float = 1640.0
public func CBHudPanelH() -> Float = 1020.0
// The page as a tab of the game's menu (UI/HubTab.reds), which has the game's row above it and its button hints below.
public func CBHudTabFit() -> Float = 0.94
public func CBHudTabMaxScale() -> Float = 1.88
public func CBHudTabTop() -> Float = 280.0
public func CBHudTabFirstY() -> Float = 48.0
public func CBHudDesignW() -> Float = 1920.0
public func CBHudDesignH() -> Float = 1080.0

// How much to shrink Cyberbane's HUD widgets (the threat bars and the message cards) so they fit
// the screen they are on.
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
  // Interface size can shrink the page but never push it off the screen. `s` fits the 1920x1080 design to the space;
  // the panel is a little smaller than the design, so the most it may be enlarged is until the panel itself meets the
  // edge.
  let fullFit = s * MinF(CBHudDesignW() / CBHudPanelW(), CBHudDesignH() / CBHudPanelH());
  let scaled = ClampF(s * CBHudUserScale(), 0.4, MaxF(fullFit, 0.4));
  CBLog.Info(n"UI", s"Hub page: window \(RoundF(winX))x\(RoundF(winY)), inverse scale \(inv), menu root \(rootKind) \(RoundF(rootX))x\(RoundF(rootY)), drawn at \(RoundF(scaled * 100.0))%.");
  return scaled;
}

public func CBHudMarginX() -> Float = 160.0
public func CBHudContentW() -> Float = 1320.0
// Tabs: narrower, so the row spans about 1000 px instead of 1500.
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
// Two more buttons stacked under it, for a screen with more than one thing to do (the Rivals: find one, forget one,
// forget them all).
public func CBHudExtraActions() -> Int32 = 3
// The Crew page's orders list: the row that lets one go, after the kit's asks (CBCrewAskGive.. CBCrewAskWork).
public func CBHudCrewOrderLetGo() -> Int32 = 8
// A name of V's choosing. After the asks (1-7), letting go (8) and a job and a duel (9, 10); 11 was a row to call just
// them, which is the crew page's first button now.
public func CBHudCrewOrderRename() -> Int32 = 12
public func CBHudActionGap() -> Float = 8.0

// Row layouts, as the columns are positioned for them.
public func CBHudLayoutGangs() -> Int32 = 0
public func CBHudLayoutWide() -> Int32 = 1
public func CBHudLayoutTitles() -> Int32 = 2
public func CBHudLayoutCrew() -> Int32 = 3    // the crew
public func CBHudLayoutLanes() -> Int32 = 4   // what is on its way, on Standing
public func CBHudLayoutMember() -> Int32 = 5  // one member's numbers and slots, in the right-hand column
// The Member view's column of rows: right of the story, clear of the buttons below it.
public func CBHudMemberColX() -> Float = 690.0
public func CBHudMemberColW() -> Float = 630.0
public func CBHudCrewMemberMode() -> Int32 = 13
public func CBHudCrewOrderSecond() -> Int32 = 13
public func CBHudCrewOrderAsk() -> Int32 = 14
public func CBHudCrewViewName(i: Int32) -> CName {
  return CBHudWidgetName("cbHubCrewView", i + 1);
}

// A bar drawn in a row: where it sits on each screen, so no column's text runs under it. Gangs: standing, from the
// middle. The city and turf: renown and share, where the text meters were. Rivals: rank, and a gang's strength.
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
// A bar is ten segments, the way the game draws its own meters; and the gap between them.
public func CBHudBarSegs() -> Int32 = 10
public func CBHudBarGap() -> Float = 2.0

// Colours.
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
// the whole column is ever cut inside itself.
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
public func CBHudRowCols() -> Int32 = 6

// What each column is tinted: the name brightest, the two middle facts in the value colour, the one that says what V
// has done to them warm, and the status on the right dimmed.
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
    if layout == CBHudLayoutMember() {
      if col == 0 { return 21.0; }
      if col == 1 { return 180.0; }
      if col == 2 { return 470.0; }
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
  if layout == CBHudLayoutMember() {
    if col == 0 { return 11; }
    if col == 1 { return 30; }
    if col == 2 { return 0; }
    if col == 5 { return 12; }
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
    return CBT(n"Cyberbane-Hud-AnyMoment");
  }
  if ticks <= 120 {
    return CBT(n"Cyberbane-Hud-Soon");
  }
  if ticks <= 600 {
    return CBT(n"Cyberbane-Hud-BeforeLong");
  }
  return CBT(n"Cyberbane-Hud-Later");
}

// "in 2m 05s" with countdowns on, "soon" without: reads right after a noun either way.
public func CBWhen(ticks: Int32) -> String {
  return CBShowCountdowns() && ticks > 0 ? CBTf(n"Cyberbane-Whispers-In", [CBHudCountdown(ticks)]) : CBTimeText(ticks);
}

public func CBShowCountdowns() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().showCountdowns;
}

public func CBHudCountdown(ticks: Int32) -> String {
  if ticks <= 0 {
    return CBT(n"Cyberbane-Hud-AnyMoment");
  }
  let mins = ticks / 60;
  let secs = ticks % 60;
  if mins <= 0 {
    return CBTf(n"Cyberbane-Hud-S", [s"\(secs)"]);
  }
  if secs < 10 {
    return CBTf(n"Cyberbane-Hud-M0S", [s"\(mins)", s"\(secs)"]);
  }
  return CBTf(n"Cyberbane-Hud-MS", [s"\(mins)", s"\(secs)"]);
}

public func CBHudTabName(tab: Int32) -> String {
  switch tab {
    case 1: return CBT(n"Cyberbane-Hud-STANDING");
    case 2: return CBT(n"Cyberbane-Hud-GANGS");
    case 3: return CBT(n"Cyberbane-HubWar-STREETS");
    case 4: return CBT(n"Cyberbane-Hud-RIVALS");
    case 5: return CBT(n"Cyberbane-Queue-CREW");
    case 6: return CBT(n"Cyberbane-Hud-TITLES");
    case 7: return CBT(n"Cyberbane-Hud-HISTORY");
    default: return "";
  }
}

// One sentence saying what this screen is for, under the header.
public func CBHudTabBlurb(tab: Int32) -> String {
  switch tab {
    case 1: return CBT(n"Cyberbane-Hud-WhoYouAreInThisCity");
    case 2: return CBT(n"Cyberbane-Hud-WhatEachGangThinksOfYou");
    case 3: return CBT(n"Cyberbane-HubWar-StreetsBlurb");
    case 4: return CBT(n"Cyberbane-Hud-ThePeopleWhoHaveSurvivedYou");
    case 5: return CBT(n"Cyberbane-Hud-ThePeopleWhoWorkForYou");
    case 6: return CBT(n"Cyberbane-Hud-WhatTheStreetCallsYouAnd");
    case 7: return CBT(n"Cyberbane-Hud-TheLedgerWhatYouDidWhere");
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

// A widget name for a clickable thing, made once at build time.
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
  // The same tabs as the game's widgets, when the page is a tab of the game's menu.
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
  // List rows: a clickable box per row holding a band, a colour pip and six cells. Cells are flat: row r column c is at
  // r * CBHudRowCols + c.
  private let m_rowBox: array<wref<inkCanvas>>;
  private let m_rowBg: array<wref<inkWidget>>;
  private let m_rowPip: array<wref<inkRectangle>>;
  private let m_rowCell: array<wref<inkText>>;
  private let m_rowSeg: array<wref<inkRectangle>>;     // a bar in each row, ten segments (row r at r * CBHudBarSegs())
  private let m_rowTop: Float;                          // where the first row sits on this screen
  private let m_rowCrew: array<Int32>;                  // the crew member a row stands for; -1 the solo on offer
  private let m_pickCrew: Int32;
  private let m_letGoArmed: Int32;
  // The Crew page's three views: Roster, Member and Crew, as chips across the top the way the main tabs work.
  private let m_viewBox: array<wref<inkCanvas>>;
  private let m_viewBg: array<wref<inkRectangle>>;
  private let m_viewText: array<wref<inkText>>;
  private let m_viewShown: Bool;
  private let m_ordersFrom: Int32;      // the view a member's orders were opened from, for Back
  private let m_logFilter: Int32;       // the History page's filter: 0 everything
  // One line saying what the button under the cursor does, in the footer's place.
  private let m_footer: wref<inkText>;
  private let m_footerText: String;
  private let m_actionHelp: String;
  private let m_extraHelp: array<String>;
  private let m_rowHelp: array<String>;
  // The Crew page's screens: 0 the roster, 1 picking a weapon, 2 picking chrome, 3 picking a gang for a war, 4 naming
  // the crew, 5 the memorial, 6 the picked one's orders, 7 the crew itself; what is on offer in the list, the name box,
  // the memorial's pick (one up), and whether the Gangs page drew the crew's card.
  private let m_crewMode: Int32;
  private let m_pickFallen: Int32;
  private let m_crewCardShown: Bool;
  private let m_pickItems: array<ItemID>;
  private let m_pickGangs: array<CName>;
  // A job's targets (screen 8): a Rival's id for a hit, else the gang whose bag; and who can answer a challenge (screen
  // 9).
  private let m_pickJobRival: array<Int32>;
  private let m_pickJobGang: array<CName>;
  private let m_pickDuel: array<Int32>;
  private let m_streetsName: Bool;         // the Streets page reads where V's name carries, not who holds each district
  private let m_pickWar: CName;            // the war picked on the War view
  private let m_pickWarRow: Int32;         // or a captive (100+) or one of theirs the crew holds (200+)
  private let m_pickSquad: Int32;          // the squad picked, by its leader
  private let m_callOffArmed: Bool;        // calling off a war asks twice
  private let m_retireArmed: Int32;        // retiring one of them asks twice
  private let m_handTo: Int32;             // who a leaderless squad is offered to next
  private let m_nameInput: ref<HubTextInput>;
  // What the name box starts with and says when empty, for the crew or one of them (SeedNameInput).
  private let m_nameSeed: String;
  private let m_nameHint: String;
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
  // Q and E, at the two ends of the tab bar, where the game's menus put the keys that move between their tabs. Clicking
  // them does what pressing them does.
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
  private let m_undoArmed: Bool;           // and so does undoing it
  private let m_bountyArmed: Bool;         // and so does paying off the price on V's head
  private let m_legendShown: Bool;         // the History page tells V's story instead of the ledger
  private let m_hover: CName;              // the clickable thing under the cursor, by name
  private let m_inputBound: Bool;          // the tab keys are registered with the pause menu
  // Why no Rival can arrive right now, or "". Resolved once per render, not once per row.
  private let m_holdLabel: String;
  // How many of the pause menu's units one unit of the 1920x1080 design is (CBHubPageScale).
  private let m_scale: Float;
  // Another mod's overlay this page has put out of sight while it is up (CBForeignOverlays).
  private let m_overlaysOff: Bool;
  // The web of gangs ([H1], UI/HubWeb.reds): the Factions page as a picture. A pool built once with the page and hidden
  // until used: the lines first so they sit under the boxes, then the words, then a box per place.
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
  // The Rivals tree ([H2]) draws with the same pool: which gang it shows, whether it is up, and the Rival in each place
  // (0 for none).
  private let m_treeShown: Bool;
  private let m_treeGang: CName;
  private let m_treeGrudge: Int32;   // the Rival of the gang drawn V has met most, for their box
  private let m_webOrder: array<Int32>; // the gangs' cards, slot by slot, in the order they are shown
  private let m_hereSlot: Int32;        // the district card V is in, framed white on the maps
  private let m_actionTop: Float;     // where the buttons start on this page (PlaceActions)
  private let m_treeSlotRival: array<Int32>;
  // The pictures' look: every box a card of the game's art, a frame tinted by what it is and cyan when picked; two
  // segmented bars a box (box s, bar b, segment k at (s * 2 + b) * CBHudBarSegs + k); a soft glow under every line.
  private let m_webBoxArt: array<wref<inkImage>>;
  private let m_webBoxFrame: array<wref<inkImage>>;
  private let m_webSeg: array<wref<inkRectangle>>;
  private let m_webGlow: array<wref<inkRectangle>>;
  private let m_tileArt: array<wref<inkImage>>;
  private let m_tileFrame: array<wref<inkImage>>;
  // The same pool draws two pictures more: Night City as a map on the Turf and City pages, and V's crew round V.
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
    this.m_undoArmed = false;
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

  // Out of sight.
  public func Hide() -> Void {
    this.m_open = false;
    this.m_purgeArmed = false;
    this.m_resetArmed = false;
    this.m_undoArmed = false;
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

  // Another mod's text drawn over the menu as a whole, where this page sits, goes out of sight while the page is up and
  // comes back when it goes.
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
    i = 0;
    while i < ArraySize(this.m_viewBox) {
      this.Unhook(this.m_viewBox[i]);
      i += 1;
    }
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

  // Changing screen sounds like the game's tabs, on its own screen.
  private func ClickTab() -> Void {
    if this.m_inTab && IsDefined(this.m_owner) {
      this.m_owner.PlaySound(n"TabButton", n"OnPress");
    } else {
      this.Click();
    }
  }

  // ---- Building --------------------------------------------------------------------------------

  // Take a colour from the game instead of naming one here.
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

  // ---- The game's parts, for the page as a tab of the game's menu (UI/HubTab.reds) ----------
  //
  // On that page everything that is furniture rather than information is the game's: the row of screens is the label
  // the game spawns for its own top row, at either end of it is the widget the game draws a key with, and the button is
  // the game's button art.

  // The screens, in a row: the game's key for "previous", its labels, its key for "next", which is how
  // the game lays out its own row.
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

  // Once, eased in like the game's screens.
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
      return CBHudHasPicture(this.m_tab) || this.m_tab == CBHudHistoryTab();
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
    if this.ViewIndex(name) >= 0 {
      return this.m_viewShown;
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

  // What the page's buttons are drawn with: the game's button on its own screen, a band elsewhere.
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

  // The same art as a free piece of the page, placed and sized by whoever uses it (the Standing tiles).
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
    // As a tab the game's background is the page's, and its button hints have to show. Nothing is underneath to be
    // clicked by accident: the screen's own content is hidden (UI/HubTab.reds).
    if this.m_inTab {
      backdrop.SetVisible(false);
      backdrop.SetInteractive(false);
    }
    backdrop.Reparent(root, -1);
    // The game's vignette over it, faintly red, as its full-screen pages darken their edges.
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
    header.SetText(CBT(n"Cyberbane-HubTab-CYBERBANE"));
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
    // These were only ever named in the footer, a line of small print at the other end of the page from the tabs they
    // move between.
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
    this.m_listUpText = this.NewListButtonText(up, CBT(n"Cyberbane-Hud-Up"));
    this.m_listDownText = this.NewListButtonText(down, CBT(n"Cyberbane-Hud-Down"));
    up.SetVisible(false);
    down.SetVisible(false);
    this.m_listUpBox = up;
    this.m_listDownBox = down;

    // The switch between the gangs as a list and as a web, at the top left of the list.
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
      // As a tab, a row is the game's framed cell, the way the journal draws its list. No stripes: the game does not
      // stripe its lists.
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

    // ---- The Crew page's views: Roster, Member, Crew, beside the picture switch ----
    ArrayClear(this.m_viewBox);
    ArrayClear(this.m_viewBg);
    ArrayClear(this.m_viewText);
    let vi = 0;
    while vi < CBHudCrewViewCount() {
      let vbox = this.NewBox(panel, CBHudCrewViewName(vi), x + 250.0 + Cast<Float>(vi) * 176.0, CBHudContentTop() - 36.0, 168.0, 32.0);
      let vbg = this.NewBand(vbox, CBHudButtonIdle());
      let vtext = this.NewText(vbox, 19, n"Semibold", CBHudHead());
      vtext.SetLetterCase(textLetterCase.UpperCase);
      vtext.SetHorizontalAlignment(textHorizontalAlignment.Center);
      vtext.SetFitToContent(false);
      vtext.SetSize(this.PxSize(168.0, 26.0));
      vtext.SetMargin(this.PxAt(0.0, 4.0));
      vtext.SetText(CBHudCrewViewWord(vi));
      vbox.SetVisible(false);
      ArrayPush(this.m_viewBox, vbox);
      ArrayPush(this.m_viewBg, vbg);
      ArrayPush(this.m_viewText, vtext);
      vi += 1;
    }
    ArrayClear(this.m_rowHelp);
    let rh = 0;
    while rh < CBHudRowPool() {
      ArrayPush(this.m_rowHelp, "");
      rh += 1;
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
    ArrayClear(this.m_extraHelp);
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
      ArrayPush(this.m_extraHelp, "");
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
    this.m_footerText = CBHudFit(CBT(n"Cyberbane-Hud-ClickAScreenOrARow"), w - 260.0 - 40.0, 19, 1);
    footer.SetText(this.m_footerText);
    footer.SetVisible(!this.m_inTab);   // as a tab, the game's button hints say all of this
    this.m_footer = footer;

    let settings = this.NewBox(panel, CBHudSettingsName(), x + w - 260.0, CBHudFooterY() - 8.0, 260.0, 40.0);
    let settingsBg = this.NewBand(settings, CBHudButtonIdle());
    let settingsText = this.NewText(settings, 19, n"Semibold", CBHudHead());
    settingsText.SetLetterCase(textLetterCase.UpperCase);
    settingsText.SetHorizontalAlignment(textHorizontalAlignment.Center);
    settingsText.SetFitToContent(false);
    settingsText.SetSize(this.PxSize(260.0, 26.0));
    settingsText.SetMargin(this.PxAt(0.0, 8.0));
    settingsText.SetText(CBT(n"Cyberbane-Hud-ModSettings"));
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
    i = 0;
    while i < ArraySize(this.m_viewBox) {
      this.Hook(this.m_viewBox[i]);
      i += 1;
    }
    // The previous/next tab keys. Registered once and left until the menu goes, rather than on
    // every show and hide, so nothing is ever registered or unregistered in the middle of the very
    // input event that is being delivered.
    owner.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"CBOnGlobalRelease");
    // The wheel comes as relative input and the stick as an axis, as in the game's gallery and map, so each has its own
    // handler and one notch can never move a list twice.
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
    // `click` only. A release arrives once for every action bound to the button, and the left mouse button and A are
    // bound to `click` (UIMenuShared) and to `select` (UIMenu) at once (r6/config/inputContexts.xml,
    // inputUserMappings.xml).
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
    let vk = this.ViewIndex(name);
    if vk >= 0 {
      e.Handle();
      if this.m_viewShown {
        this.Click();
        this.m_crewMode = CBHudCrewViewMode(vk);
        this.m_letGoArmed = 0;
        this.m_listTop = 0;
        this.Render(sys, game);
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
    // The web of gangs: the switch, and a gang's box picked.
    if Equals(name, CBHudWebToggleName()) {
      e.Handle();
      if this.m_tab == CBHudHistoryTab() {
        this.Click();
        this.m_logFilter = (this.m_logFilter + 1) % 5;
        this.Render(sys, game);
        return true;
      }
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
  protected cb func CBOnGlobalRelease(e: ref<inkPointerEvent>) -> Bool {
    if !this.IsOpen() || !IsDefined(e) || e.IsHandled() || this.CrewNaming() {
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
    // On the web of gangs the keys and the pad go round the ring instead.
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

  // The window onto a list: which entry goes in the top row, kept inside the list as it grows and shrinks, and the line
  // over it that says there is more.
  private func ListWindow(total: Int32, rows: Int32) -> Int32 {
    this.m_listTotal = total;
    this.m_listRows = rows;
    this.m_listTop = Max(0, Min(this.m_listTop, total - rows));
    let long = total > rows;
    if IsDefined(this.m_listMore) {
      if long {
        let last = Min(this.m_listTop + rows, total);
        this.m_listMore.SetText(CBTf(n"Cyberbane-Hud-Of", [s"\(this.m_listTop + 1)", s"\(last)", s"\(total)"]));
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
    this.m_undoArmed = false;
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
    if this.m_tab == CBHudCrewTab() && this.m_crewMode >= 1 && this.m_crewMode <= 2 {
      // A pick from the list: carried out here and now (CBCrewKitDoNow: it moves only V's bag and the crew's books),
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
        CBCrewKitDoNow(sys, game);
      }
      this.m_crewMode = 6;
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() && (this.m_crewMode == 8 || this.m_crewMode == 9) {
      // A job's target, or who answers a challenge: asked, carried out here and now like the other orders.
      let pickJob = row < ArraySize(this.m_rowCrew) ? this.m_rowCrew[row] - 1 : -1;
      let kbJob = CBCrewKitBook.Get(game);
      let noJobItem: ItemID;
      if IsDefined(kbJob) && pickJob >= 0 {
        if this.m_crewMode == 8 && this.m_pickCrew > 0 && pickJob < ArraySize(this.m_pickJobRival) && pickJob < ArraySize(this.m_pickJobGang) {
          kbJob.Ask(this.m_pickCrew, CBCrewAskJob(), noJobItem, this.m_pickJobGang[pickJob], this.m_pickJobRival[pickJob]);
        }
        if this.m_crewMode == 9 && pickJob < ArraySize(this.m_pickDuel) {
          kbJob.Ask(this.m_pickDuel[pickJob], CBCrewAskDuel(), noJobItem, n"");
        }
        CBCrewKitDoNow(sys, game);
      }
      this.m_crewMode = this.m_crewMode == 8 ? 6 : 7;
      this.Render(sys, game);
      return;
    }
    // The war screens: a gang to go to war on, somebody in or out of tonight's party, a war or a captive picked, an
    // order, terms. Only words and books, so carried out here and now, their texts sent once back in the game.
    if this.m_tab == CBHudCrewTab() && (this.m_crewMode == 11 || this.m_crewMode == 12 || (this.m_crewMode >= 20 && this.m_crewMode <= 27)) {
      this.WarRowClicked(sys, game, row < ArraySize(this.m_rowCrew) ? this.m_rowCrew[row] : 0);
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() && this.m_crewMode == CBHudCrewMemberMode() {
      let mcode = row < ArraySize(this.m_rowCrew) ? this.m_rowCrew[row] : 0;
      if mcode > 0 {
        this.m_ordersFrom = CBHudCrewMemberMode();
        this.CrewOrderClicked(game, mcode);
      }
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

  // A row on the war, squad and crew-place screens.
  private func WarRowClicked(sys: ref<CyberbaneSystem>, game: GameInstance, code: Int32) -> Void {
    let fb = CBWarFrontBook.Get(game);
    let book = CBCrewBook.Get(game);
    let kb = CBCrewKitBook.Get(game);
    if !IsDefined(fb) || !IsDefined(book) || !IsDefined(kb) || code <= 0 {
      return;
    }
    let mode = this.m_crewMode;
    if mode == 12 {
      // Going to war on the gang picked: the war opens now, and tonight's order is next.
      let pick = code - 1;
      if pick >= 0 && pick < ArraySize(this.m_pickGangs) {
        let gang = this.m_pickGangs[pick];
        kb.deferTexts = true;
        let declared = CBGangWarDeclare(sys, game, gang, false);
        kb.deferTexts = false;
        if declared {
          this.m_pickWar = gang;
          this.m_pickWarRow = 0;
          fb.pickGang = gang;
          this.m_crewMode = 21;
        } else {
          CBMenuNote(game, CBTf(n"Cyberbane-HubWar-TooManyWars", [s"\(CBCrewWarsAtOnce(game))"]), 4.0);
          this.m_crewMode = 20;
        }
        this.m_listTop = 0;
      }
      return;
    }
    if mode == 11 {
      if ArrayContains(fb.pickParty, code) {
        ArrayRemove(fb.pickParty, code);
      } else {
        if CBCrewWarEligible(game, book, book.Find(code), CBGameSeconds(game)) && ArraySize(fb.pickParty) < CBConfig.CrewWarPartyMax() {
          ArrayPush(fb.pickParty, code);
        }
      }
      return;
    }
    if mode == 20 {
      if code < 100 {
        let f = fb.At(code - 1);
        if IsDefined(f) {
          this.m_pickWar = f.gang;
        }
        this.m_pickWarRow = 0;
      } else {
        this.m_pickWarRow = code;
      }
      this.m_callOffArmed = false;
      return;
    }
    if mode == 21 {
      let f = fb.Find(this.m_pickWar);
      if !IsDefined(f) {
        return;
      }
      fb.pickGang = f.gang;
      fb.pickOrder = code;
      fb.pickTarget = code == CBWarOrderLieutenant() ? CBWarLieutenantTarget(sys, game, f.gang) : 0;
      if CBWarOrderFights(code) {
        // Who goes: whoever went last time and still can, as a start.
        let keep: array<Int32>;
        for id in fb.pickParty {
          if CBCrewWarEligible(game, book, book.Find(id), CBGameSeconds(game)) {
            ArrayPush(keep, id);
          }
        }
        fb.pickParty = keep;
        this.m_crewMode = 11;
        this.m_listTop = 0;
        return;
      }
      let none: array<Int32>;
      kb.deferTexts = true;
      CBGangWarGiveOrder(sys, game, f.gang, code, none, 0, false, false);
      kb.deferTexts = false;
      this.m_crewMode = 20;
      return;
    }
    if mode == 22 {
      let f = fb.Find(this.m_pickWar);
      if !IsDefined(f) {
        this.m_crewMode = 20;
        return;
      }
      kb.deferTexts = true;
      if code == 91 {
        if this.m_callOffArmed {
          CBWarCallOff(sys, game, f);
          this.m_callOffArmed = false;
          this.m_crewMode = 20;
        } else {
          this.m_callOffArmed = true;
        }
      }
      if code == 90 {
        CBWarRefuseTerms(sys, game, f);
        this.m_crewMode = 20;
      }
      if code == 80 {
        let why = CBWarGiveIn(sys, game, f);
        if StrLen(why) > 0 {
          CBMenuNote(game, why, 4.0);
        } else {
          this.m_crewMode = 20;
        }
      }
      if code == 81 {
        CBWarRefuseDemand(sys, game, f);
        this.m_crewMode = 20;
      }
      if code >= CBTermsTribute() && code <= CBTermsClient() {
        CBWarTakeTerms(sys, game, f, code);
        this.m_crewMode = 20;
      }
      kb.deferTexts = false;
      return;
    }
    if mode == 23 {
      this.m_pickSquad = code;
      return;
    }
    if mode == 25 {
      let held = CBCrewHeldDistricts(sys, game);
      let gb = CBCrewGangBook.Get(game);
      if code - 1 < ArraySize(held) && IsDefined(gb) {
        let d = held[code - 1];
        gb.SetRunner(d, this.NextRunner(game, book, gb, d));
      }
      return;
    }
    if mode == 26 {
      kb.deferTexts = true;
      CBCrewMakePlace(sys, game, code - 1);
      kb.deferTexts = false;
      return;
    }
    if mode == 27 {
      let why = CBCrewBuyUpgrade(sys, game, code);
      CBMenuNote(game, StrLen(why) > 0 ? why : CBTf(n"Cyberbane-HubWar-UpgradeBought", [CBUpgradeWord(code)]), 4.0);
      return;
    }
  }

  // The next Lieutenant or better to run a district, in roster order, after whoever runs it now; nobody after the last.
  private func NextRunner(game: GameInstance, book: ref<CBCrewBook>, gb: ref<CBCrewGangBook>, d: CName) -> Int32 {
    let now = gb.Runner(d);
    let passed = now == 0;
    let i = 0;
    while i < book.Count() {
      let m = book.At(i);
      i += 1;
      if IsDefined(m) {
        if passed && CBCrewCanRun(game, m) && m.id != now {
          return m.id;
        }
        if m.id == now {
          passed = true;
        }
      }
    }
    return 0;
  }

  // The war, squad and crew-place screens' first button.
  private func WarActionClicked(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let fb = CBWarFrontBook.Get(game);
    let kb = CBCrewKitBook.Get(game);
    let mode = this.m_crewMode;
    if !IsDefined(fb) || !IsDefined(kb) {
      return;
    }
    if mode == 11 {
      this.GiveWarOrder(sys, game, fb, kb, true);
      return;
    }
    if mode == 20 {
      if this.m_pickWarRow >= 100 && this.m_pickWarRow < 200 {
        let cap = fb.CaptiveAt(this.m_pickWarRow - 101);
        kb.deferTexts = true;
        if IsDefined(cap) && CBWarPayRansom(sys, game, cap) {
          this.m_pickWarRow = 0;
        }
        kb.deferTexts = false;
        return;
      }
      if this.m_pickWarRow >= 200 {
        let pay = CBWarRansomPrisoner(sys, game, this.m_pickWarRow - 201);
        if pay > 0 {
          CBMenuNote(game, CBTf(n"Cyberbane-HubWar-SoldBack", [s"\(pay)"]), 4.0);
        }
        this.m_pickWarRow = 0;
        return;
      }
      if IsDefined(fb.Find(this.m_pickWar)) {
        this.m_crewMode = 21;
      } else {
        this.m_crewMode = 12;
      }
      this.m_listTop = 0;
      return;
    }
    if mode == 23 {
      let sb = CBSquadBook.Get(game);
      let s = IsDefined(sb) ? sb.Of(this.m_pickSquad) : null;
      if IsDefined(s) {
        s.standing = (s.standing + 1) % 3;
      }
      return;
    }
    if mode == 24 {
      let sb2 = CBSquadBook.Get(game);
      let s2 = IsDefined(sb2) ? sb2.Of(this.m_pickSquad) : null;
      if IsDefined(s2) && IsDefined(this.m_nameInput) {
        CBSquadSetName(s2, this.m_nameInput.GetText());
      }
      this.m_crewMode = 23;
      return;
    }
    // Back: the war's screens to the War view, the crew's places to the Crew view.
    this.m_crewMode = mode == 25 || mode == 26 || mode == 27 ? 7 : 20;
    this.m_listTop = 0;
  }

  // The party screen's two ways to give the order: V leads it, or sends them.
  private func GiveWarOrder(sys: ref<CyberbaneSystem>, game: GameInstance, fb: ref<CBWarFrontBook>, kb: ref<CBCrewKitBook>, lead: Bool) -> Void {
    kb.deferTexts = true;
    let given = CBGangWarGiveOrder(sys, game, fb.pickGang, fb.pickOrder, fb.pickParty, fb.pickTarget, false, lead);
    kb.deferTexts = false;
    if given {
      CBMenuNote(game, lead ? CBTf(n"Cyberbane-HubWar-OrderLed", [CBWarOrderWord(fb.pickOrder)]) : CBTf(n"Cyberbane-HubWar-OrderGiven", [CBWarOrderWord(fb.pickOrder)]), 4.0);
      this.m_crewMode = 20;
    }
  }

  // The war, squad and crew-place screens' other buttons.
  private func WarExtraClicked(sys: ref<CyberbaneSystem>, game: GameInstance, slot: Int32) -> Void {
    let fb = CBWarFrontBook.Get(game);
    let kb = CBCrewKitBook.Get(game);
    let mode = this.m_crewMode;
    if !IsDefined(fb) || !IsDefined(kb) {
      return;
    }
    if mode == 11 {
      if slot == 1 {
        this.GiveWarOrder(sys, game, fb, kb, false);
        return;
      }
      this.m_crewMode = 21;   // back to the orders, the party kept
      this.m_listTop = 0;
      return;
    }
    if mode == 24 {
      this.m_crewMode = 23;   // the name stays as it was
      return;
    }
    if mode == 20 {
      if this.m_pickWarRow >= 100 && this.m_pickWarRow < 200 {
        let cap = fb.CaptiveAt(this.m_pickWarRow - 101);
        kb.deferTexts = true;
        if slot == 1 && IsDefined(cap) && CBWarTradeCaptive(sys, game, cap) {
          this.m_pickWarRow = 0;
        }
        if slot == 2 && IsDefined(cap) {
          CBWarGoRescue(sys, game, cap);
          CBMenuNote(game, CBTf(n"Cyberbane-HubWar-RescuePinned", [CBWarCaptiveName(sys, game, cap)]), 5.0);
        }
        kb.deferTexts = false;
        return;
      }
      if this.m_pickWarRow >= 200 {
        if slot == 1 {
          kb.deferTexts = true;
          CBWarTurnPrisoner(sys, game, this.m_pickWarRow - 201);
          kb.deferTexts = false;
          this.m_pickWarRow = 0;
        }
        return;
      }
      let f = fb.Find(this.m_pickWar);
      if slot == 1 && IsDefined(f) {
        this.m_crewMode = 22;
        this.m_callOffArmed = false;
      }
      if slot == 2 && IsDefined(f) {
        kb.deferTexts = true;
        CBWarAskFriendIn(sys, game, f);
        kb.deferTexts = false;
      }
      if slot == 3 {
        this.m_crewMode = 12;
        this.m_listTop = 0;
      }
      return;
    }
    if mode == 23 {
      let sb = CBSquadBook.Get(game);
      let s = IsDefined(sb) ? sb.Of(this.m_pickSquad) : null;
      if !IsDefined(s) {
        return;
      }
      if slot == 1 {
        CBSquadChangeKind(game, s, s.kind % 6 + 1);
      }
      if slot == 2 {
        this.SeedNameInput(CBSquadName(sys, game, s), CBT(n"Cyberbane-HubWar-ANameForTheSquad"));
        this.m_crewMode = 24;
      }
      if slot == 3 {
        let book = CBCrewBook.Get(game);
        if IsDefined(book) && !IsDefined(book.Find(s.leader)) {
          let cand = this.HandCandidate(game, book, sb);
          if CBSquadHandTo(game, s, cand) {
            this.m_pickSquad = cand;
          }
          this.m_handTo = cand;
        } else {
          s.noRecruit = !s.noRecruit;
        }
      }
    }
  }

  // The button beside the detail panel. Neither action is carried out from here: the game is paused, and both touch the
  // world. They are recorded, and done on the first settled tick after the menu closes.
  private func ActionClicked(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    // The war, squad and crew-place screens (only words and books, so at once).
    if this.m_tab == CBHudCrewTab() && (this.m_crewMode == 11 || this.m_crewMode == 12 || (this.m_crewMode >= 20 && this.m_crewMode <= 27)) {
      this.WarActionClicked(sys, game);
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() && this.m_crewMode != 0 && this.m_crewMode != CBHudCrewMemberMode() {
      // "Back" out of a screen, "Save the name" when naming: a pick list goes back to the orders it came from, the name
      // and the memorial to the crew's own screen, the rest to the roster.
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
      // One of them, renamed: only words as well, saved here and now. Empty gives them back their own.
      if mode == 10 {
        let nbName = CBCrewNameBook.Get(game);
        if IsDefined(nbName) && IsDefined(this.m_nameInput) && this.m_pickCrew > 0 {
          nbName.SetName(this.m_pickCrew, this.m_nameInput.GetText());
          CBLog.Info(n"Crew", "V renamed one of the crew.");
        }
      }
      this.m_crewMode = (mode >= 1 && mode <= 2) || mode == 8 || mode == 10 ? 6 : (mode == 4 || mode == 5 || mode == 9 ? 7 : 0);
      if mode == 6 && this.m_ordersFrom == CBHudCrewMemberMode() {
        this.m_crewMode = CBHudCrewMemberMode();   // back to the file they were opened from
      }
      this.m_pickFallen = 0;
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() {
      let crew = CBCrewBook.Get(game);
      if IsDefined(crew) {
        // The first button is the picked one's: the solo on offer hired, or one of the crew called on their own, or
        // sent home on their own while the rest stay.
        let id = this.m_pickCrew;
        if id == -1 {
          crew.reqHire = !crew.reqHire;
        } else {
          if id > 0 && IsDefined(crew.Find(id)) {
            if crew.IsOut(id) && !crew.leaving {
              crew.reqHomeOne = crew.reqHomeOne == id ? 0 : id;
            } else {
              if crew.reqCallOne == id {
                crew.reqCallOne = 0;
              } else {
                crew.reqCallOne = StrLen(CBCrewCallBlocked(sys, game, false, true, id)) == 0 ? id : 0;
              }
            }
          }
        }
      }
      this.Render(sys, game);
      return;
    }
    // The price on V's head (Spawn/Bounty.reds): paid on the next tick back in the game, never from here.
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
    // An add-on's card: the click is recorded, and the add-on hears it on the next settled tick (API/HubCards.reds).
    if this.m_tab == CBHudFactionsTab() && IsDefined(CBApiCardOfRowId(game, this.m_pickFaction)) {
      let apiPick = CBApiCardOfRowId(game, this.m_pickFaction);
      let hubA = CBApiHub.Get(game);
      if IsDefined(hubA) && ArraySize(apiPick.actions) > 0 {
        hubA.Request(apiPick.id, 0);
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
        // The story or the ledger (the first button; Start over moved to the last).
        this.m_legendShown = !this.m_legendShown;
        this.m_resetArmed = false;
        this.m_undoArmed = false;
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
    // The first page's skip: asked here, made once the game is back (Core/SkipTime.reds).
    if this.m_tab == CBHudStandingTab() && slot == 1 {
      if CBSkipTimeStands(game) {
        CBSkipTimeAsk(game);
        CBMenuNote(game, CBT(n"Cyberbane-GangWar-SkipAsked"), 4.0);
      }
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudTurfTab() && slot == 1 {
      this.m_streetsName = !this.m_streetsName;
      this.m_pickDistrict = n"";
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudFactionsTab() && IsDefined(CBApiCardOfRowId(game, this.m_pickFaction)) {
      let apiExtra = CBApiCardOfRowId(game, this.m_pickFaction);
      let hubE = CBApiHub.Get(game);
      if IsDefined(hubE) && slot >= 1 && slot < ArraySize(apiExtra.actions) {
        hubE.Request(apiExtra.id, slot);
      }
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() && (this.m_crewMode == 11 || this.m_crewMode == 20 || this.m_crewMode == 23 || this.m_crewMode == 24) {
      this.WarExtraClicked(sys, game, slot);
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() && this.CrewNaming() {
      if slot == 1 {
        this.m_crewMode = this.m_crewMode == 10 ? 6 : (this.m_crewMode == 24 ? 23 : 7);   // Cancel: the name stays as it was
      }
      this.Render(sys, game);
      return;
    }
    if this.m_tab == CBHudCrewTab() {
      // The picked one's orders; the whole crew called or sent home, the same as the crew key; the crew's own page.
      // Calls and sending home are carried out back in the game.
      let cb = CBCrewBook.Get(game);
      if IsDefined(cb) {
        if slot == 1 && this.m_pickCrew > 0 {
          this.m_ordersFrom = this.m_crewMode;
          this.m_crewMode = 6;
          this.m_letGoArmed = 0;
        }
        if slot == 2 && cb.Count() > 0 {
          if cb.OutCount() > 0 && !cb.leaving {
            cb.reqHome = !cb.reqHome;
          } else {
            if cb.reqCall {
              cb.reqCall = false;
            } else {
              cb.reqCall = StrLen(CBCrewCallBlocked(sys, game, false, true)) == 0;
            }
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
    // Start over (the last button, not the first). Asks twice.
    if this.m_tab == CBHudHistoryTab() && slot == 2 {
      if this.m_resetArmed {
        this.m_resetArmed = false;
        // For this playthrough and no other, and on record at once (CyberbaneSystem,
        // RequestStartOver): loading another save from here cannot be wiped by it, and an
        // older save of this playthrough is started over too when it next loads.
        sys.RequestStartOver();
        CBLog.Info(n"UI", "Start over chosen on the Hub; the next tick back in the game wipes this playthrough's Cyberbane data.");
      } else {
        this.m_resetArmed = true;
        this.m_undoArmed = false;
      }
      this.Render(sys, game);
      return;
    }
    // Undo the last Start over: asks twice, then acts on the click, since it only takes a note off the record kept
    // outside the saves.
    if this.m_tab == CBHudHistoryTab() && slot == 1 {
      if this.m_undoArmed {
        this.m_undoArmed = false;
        let undone = sys.UndoLastStartOver();
        if IsNameValid(undone) {
          CBMenuNote(game, CBT(n"Cyberbane-Hud-TheLastStartOverIsUndone"), 12.0);
        }
      } else {
        this.m_undoArmed = true;
        this.m_resetArmed = false;
      }
      this.Render(sys, game);
      return;
    }
    if this.m_tab != CBHudRivalsTab() {
      return;
    }
    // 1 calls them out, 2 forgets them, 3 forgets everybody (call them out was the second).
    if slot == 2 {
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
      if slot == 1 {
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
  private func ViewIndex(name: CName) -> Int32 {
    let k = 0;
    while k < ArraySize(this.m_viewBox) {
      if Equals(name, CBHudCrewViewName(k)) {
        return k;
      }
      k += 1;
    }
    return -1;
  }

  // Which view the Crew page is on: Roster, Member, War, Squads, Crew; the view a screen inside one of them belongs to.
  private func CrewView() -> Int32 {
    let m = this.m_crewMode;
    if m == 0 { return 0; }
    if m == CBHudCrewMemberMode() { return 1; }
    if m == 20 || m == 21 || m == 22 || m == 11 || m == 12 { return 2; }
    if m == 23 || m == 24 { return 3; }
    if m == 7 || m == 25 || m == 26 || m == 27 { return 4; }
    return -1;
  }

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
    let view = this.CrewView();
    let vp = 0;
    while vp < ArraySize(this.m_viewBox) {
      let onView = view == vp;
      let hotView = Equals(this.m_hover, CBHudCrewViewName(vp));
      if IsDefined(this.m_viewBg[vp]) {
        this.m_viewBg[vp].SetTintColor(onView ? CBHudBandPicked() : (hotView ? CBHudButtonHover() : CBHudButtonIdle()));
      }
      if IsDefined(this.m_viewText[vp]) {
        this.m_viewText[vp].SetTintColor(onView ? CBHudCyan() : CBHudHead());
      }
      vp += 1;
    }
    this.PaintHelp();
    this.PaintWeb();
  }

  // What the button under the cursor does, one line where the footer's hint is.
  private func PaintHelp() -> Void {
    if !IsDefined(this.m_footer) {
      return;
    }
    let help = "";
    if Equals(this.m_hover, CBHudActionName()) {
      help = this.m_actionHelp;
    }
    let k = this.ExtraIndex(this.m_hover);
    if k >= 0 && k < ArraySize(this.m_extraHelp) {
      help = this.m_extraHelp[k];
    }
    let r = 0;
    while r < ArraySize(this.m_rowNames) && StrLen(help) == 0 {
      if Equals(this.m_rowNames[r], this.m_hover) && r < ArraySize(this.m_rowHelp) && this.m_rowShown[r] {
        help = this.m_rowHelp[r];
      }
      r += 1;
    }
    let vk = this.ViewIndex(this.m_hover);
    if vk >= 0 {
      help = CBHudCrewViewHelp(vk);
    }
    if StrLen(help) > 0 {
      this.m_footer.SetText(CBHudFit(help, CBHudContentW() - (this.m_inTab ? 0.0 : 300.0), 19, 1));
      this.m_footer.SetTintColor(CBHudCyan());
      this.m_footer.SetVisible(true);
    } else {
      this.m_footer.SetText(this.m_footerText);
      this.m_footer.SetTintColor(CBHudDim());
      this.m_footer.SetVisible(!this.m_inTab);
    }
  }

  // What a button does when its page did not say: by the page and the button's place on it. 0 is the first button.
  private func DefaultHelp(slot: Int32) -> String {
    if this.m_tab == CBHudStandingTab() && slot == 0 {
      return CBT(n"Cyberbane-Hud-HelpPayBounty");
    }
    if this.m_tab == CBHudFactionsTab() && slot == 0 {
      return CBT(n"Cyberbane-Hud-HelpPayOffGang");
    }
    if this.m_tab == CBHudRivalsTab() {
      if slot == 0 { return CBT(n"Cyberbane-Hud-HelpFindRival"); }
      if slot == 1 { return CBT(n"Cyberbane-Hud-HelpSendWord"); }
      if slot == 2 { return CBT(n"Cyberbane-Hud-HelpForgetRival"); }
      if slot == 3 { return CBT(n"Cyberbane-Hud-HelpForgetAll"); }
    }
    if this.m_tab == CBHudHistoryTab() {
      if slot == 0 { return CBT(n"Cyberbane-Hud-HelpStoryLedger"); }
      if slot == 1 { return CBT(n"Cyberbane-Hud-HelpUndo"); }
      if slot == 2 { return CBT(n"Cyberbane-Hud-HelpStartOver"); }
    }
    if this.m_tab == CBHudCrewTab() {
      if this.m_crewMode == 11 && slot == 0 { return CBT(n"Cyberbane-Hud-HelpSendWar"); }
      if this.m_crewMode == 0 && slot == 0 && this.m_pickCrew == -1 { return CBT(n"Cyberbane-Hud-HelpHire"); }
    }
    return "";
  }

  private func SetRowHelp(idx: Int32, help: String) -> Void {
    if idx >= 0 && idx < ArraySize(this.m_rowHelp) {
      this.m_rowHelp[idx] = help;
    }
  }

  // The chips show on the Crew page's three views, and nowhere else.
  private func ShowCrewViews(show: Bool) -> Void {
    this.m_viewShown = show;
    for b in this.m_viewBox {
      if IsDefined(b) {
        b.SetVisible(show);
      }
    }
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

  private func SetAction(label: String, enabled: Bool, opt help: String) -> Void {
    this.m_actionOn = enabled;
    this.m_actionHelp = StrLen(help) > 0 || StrLen(label) == 0 ? help : this.DefaultHelp(0);
    // Drawn smaller until it fits, rather than cut.
    this.BoxText(this.m_actionText, label, CBHudActionW() - 24.0, CBHudActionFont(), 14, true);
    if IsDefined(this.m_actionBox) {
      this.m_actionBox.SetVisible(StrLen(label) > 0);
    }
  }

  // The button and the ones under it, from `top` down. Every page starts them at CBHudDetailTop (Render); the web of
  // gangs is drawn taller and puts them beside the words under it.
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

  // The buttons showing, one under another from the top with no gap where a hidden one is: a page that showed its first
  // and fourth buttons left two buttons' worth of empty space between them.
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
  private func SetExtra(slot: Int32, label: String, enabled: Bool, opt help: String) -> Void {
    let k = slot - 1;
    if k < 0 || k >= ArraySize(this.m_extraBox) || k >= ArraySize(this.m_extraOn) {
      return;
    }
    this.m_extraOn[k] = enabled && StrLen(label) > 0;
    if k < ArraySize(this.m_extraHelp) {
      this.m_extraHelp[k] = StrLen(help) > 0 || StrLen(label) == 0 ? help : this.DefaultHelp(slot);
    }
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
      if i < ArraySize(this.m_rowHelp) { this.m_rowHelp[i] = ""; }
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
    let member = layout == CBHudLayoutMember();
    let stride = titles ? CBHudTitleRowHeight() : CBHudRowHeight();
    let rowW = titles ? CBHudTitleListW() : (member ? CBHudMemberColW() : CBHudContentW());
    let rowX = member ? CBHudMarginX() + CBHudMemberColX() : CBHudMarginX();
    let rowH = stride - 4.0;
    let textY = titles ? 0.0 : 5.0;
    let r = 0;
    while r < ArraySize(this.m_rowBox) {
      if IsDefined(this.m_rowBox[r]) {
        this.m_rowBox[r].SetMargin(this.PxAt(rowX, top + Cast<Float>(r) * stride));
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

  // The four scores as tiles, two by two: the meters keep their full story in half the height, and what is on its way
  // gets the room under them. Where tile `idx` sits.
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

  // What is on its way, as rows under the tiles: each lane with a pip for how close it is, and V's own crew. Returns
  // where the rows end.
  private func RenderLanes(sys: ref<CyberbaneSystem>, game: GameInstance) -> Float {
    let top = CBHudContentTop() + 2.0 * CBHudTileStride() - 4.0;
    this.PlaceRows(CBHudLayoutLanes(), top);
    let row = 0;
    row = this.LaneRow(sys, game, row, CBLaneRival(), CBT(n"Cyberbane-RivalSystem-ARival"));
    row = this.LaneRow(sys, game, row, CBLaneSquad(), CBT(n"Cyberbane-Hud-AGangCrew"));
    row = this.LaneRow(sys, game, row, CBLaneApex(), CBT(n"Cyberbane-Hud-AnApexSquad"));
    let crew = CBCrewBook.Get(game);
    if CBMyCrewOn() && IsDefined(crew) && crew.Count() > 0 {
      let out = crew.OutCount();
      // Into a named list first: ArraySize read straight off the call showed "32758 of 2 ready to call".
      let readyList = CBCrewReadyOrder(crew, CBGameSeconds(game), 0);
      let ready = ArraySize(readyList);
      let what = out > 0 ? (crew.leaving ? CBT(n"Cyberbane-Hud-HeadingHome") : CBTf(n"Cyberbane-Hud-WithYouNow", [s"\(out)"])) : CBTf(n"Cyberbane-Hud-OfReadyToCall", [s"\(ready)", s"\(crew.Count())"]);
      this.SetRow(row, CBHudLayoutLanes(), out > 0 ? CBHudGreen() : CBHudCyan(), false, false, CBT(n"Cyberbane-CrewBanner-YourCrew"), what, "", "", "",
                  crew.CutOwed() > 0 ? CBTf(n"Cyberbane-Hud-OwedEb", [s"\(crew.CutOwed())"]) : "");
      row += 1;
    }
    return top + Cast<Float>(row) * CBHudRowHeight();
  }

  private func LaneRow(sys: ref<CyberbaneSystem>, game: GameInstance, row: Int32, lane: Int32, label: String) -> Int32 {
    let text = CBHudLaneLine(sys, game, lane, "");
    while StrLen(text) > 0 && Equals(StrLeft(text, 1), " ") {
      text = StrRight(text, StrLen(text) - 1);   // the line starts after its (empty) label's gap
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
          // Too long for the column at its size: drawn smaller, down to CBHudMinCellFont, and only past that shortened,
          // at a word, so nothing is ever cut through the middle of one.
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

    // While the Street Cred floor holds Renown up, nothing V does moves the number until what Cyberbane has counted
    // passes it, so the tile says so and shows that count: "it never changes" was the floor, unexplained.
    let earned = score.GetEarnedRenown();
    let renownCaption = CBT(n"Cyberbane-Hud-HowWidelyNightCityKnowsYour");
    if renown >= earned + 1.0 {
      renownCaption = CBTf(n"Cyberbane-Hud-HeldHereByYourStreetCred", [s"\(RoundF(earned))"]);
    }
    this.SetBar(0, CBT(n"Cyberbane-TitleEngine-Renown"), s"\(RoundF(renown))   \(CBTierName(EnumInt(score.GetTier())))",
      renown / 1000.0, CBHudCyan(), renownCaption);

    // The number is Dread; the word is what the street does with it.
    let civ = score.GetDreadCiv();
    this.SetBar(1, CBT(n"Cyberbane-TitleEngine-Dread"), s"\(RoundF(dread))   \(CBDreadWord(civ))",
      dread / 100.0, CBHudRed(),
      CBTf(n"Cyberbane-Hud-HowFrighteningYouAreTheStreet", [s"\(RoundF(civ))"]));

    this.SetBar(2, CBT(n"Cyberbane-Hud-VisibleChrome"), s"\(RoundF(chrome))",
      chrome / 100.0, CBHudAmber(),
      CBHudWornLine(sys));

    this.SetBipolarBar(3, CBT(n"Cyberbane-Hud-Conduct"), s"\(RoundF(code))   \(CBCodeLabel(code))",
      code, code < 0.0 ? CBHudRed() : CBHudGreen(),
      CBT(n"Cyberbane-Hud-LeavingPeopleAliveRaisesItKilling"));
  }

  // The gangs, the ones that want you dead first.
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
    // Hostile on sight by somebody else's hand, asked once a draw (CBForeignHostile): They Will Remember's own verdict,
    // or their people seen hostile to V without Cyberbane having done it.
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
        // A faction an add-on shows somewhere else stays off the list (API level 5, SetFactionListed).
        if IsDefined(fs) && CBApiFactionListed(sys.GetGameInstance(), fs.id) {
          let posture = score.GetPosture(fs.id);
          let hostile = Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) || twr > 0;
          if CBTwrOwnsHostility(fs.id) && CBTwrGangHostile(sys.GetGameInstance(), fs.id) == 0 {
            hostile = false;   // They Will Remember or Night City Remembers decides, and it says not
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
    // An add-on's cards come after the factions (API/HubCards.reds), picked by an id no faction has.
    let hub = CBApiHub.Get(sys.GetGameInstance());
    let apiCount = IsDefined(hub) ? hub.Count() : 0;
    if !pickedOn && IsDefined(CBApiCardOfRowId(sys.GetGameInstance(), this.m_pickFaction)) {
      pickedOn = true;
    }
    if !pickedOn {
      this.m_pickFaction = n"";
    }
    let total = ArraySize(order) + apiCount;
    let top = this.ListWindow(total, CBHudListRows());
    let row = 0;
    while row < CBHudListRows() && top + row < total {
      let at = top + row;
      if at < ArraySize(order) {
        let shownFs = order[at];
        this.RenderFactionRow(sys, score, shownFs, score.GetPosture(shownFs.id), row,
                              Equals(shownFs.id, this.m_pickFaction), orderTwr[at]);
      } else {
        this.RenderApiCardRow(hub, at - ArraySize(order), row);
      }
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
    // Set by hand under How gangs see you in Mod Settings.
    if CBGangViewSet(fs.id) {
      postureText = CBTf(n"Cyberbane-Hud-Set", [postureText]);
    }
    // Switched off under Factions in Mod Settings: Cyberbane has no posture for them at all.
    let off = !CBFactionOn(fs.id);
    if off {
      postureText = CBT(n"Cyberbane-Hud-Off");
    }
    // Hostile on sight by somebody else's hand (CBForeignHostile), while Cyberbane's own posture is
    // milder: They Will Remember's record, or seen in the street and not Cyberbane's doing.
    if twrHostile > 0 && !Equals(posture, ECBPosture.Hostile) && !Equals(posture, ECBPosture.Vendetta) {
      pip = CBHudAmber();
      if off {
        postureText = CBT(n"Cyberbane-Hud-OffHostile");
      } else {
        postureText = twrHostile == 2 ? CBTf(n"Cyberbane-Hud-Hostile", [CBRememberModShort()]) : CBT(n"Cyberbane-Hud-SeenHostile");
      }
    }
    // A stance set by hand is the player's own.
    if !off && !CBGangViewSet(fs.id) && CBTwrOwnsHostility(fs.id) {
      let says = CBTwrGangHostile(sys.GetGameInstance(), fs.id);
      if says >= 0 {
        postureText = CBPostureName(posture) + " (" + CBRememberModShort() + ")";
      } else {
        postureText = CBPostureName(posture) + " (" + CBRememberModShort() + "?)";
      }
    }
    let right = CBHudGangStatus(sys, fs);
    if Equals(sys.GetPendingPeace(), fs.id) {
      right = CBT(n"Cyberbane-Hud-PAYINGOFF");
    }
    // Who this gang is at war with, because that is the one thing on this screen V can act on:
    // hurting a gang warms the gangs that hate it (Model/GangRivalries.reds).
    let enemy = CBFactionLabel(CBTopEnemyOf(sys, sys.GetContent(), fs.id));
    this.SetRow(row, CBHudLayoutGangs(), pip, true, picked,
      CBFactionLabel(fs.id),
      postureText,
      CBTf(n"Cyberbane-Hud-Fear", [s"\(RoundF(score.GetFactionFear(fs.id)))"]),
      StrLen(enemy) > 0 ? CBTf(n"Cyberbane-Hud-AtWar", [enemy]) : "",
      CBTf(n"Cyberbane-Hud-Down-2", [s"\(fs.kills)"]),
      right);
    this.m_rowFaction[row] = fs.id;
    // Where V stands with them, from the middle: red to the left, green to the right.
    if !off {
      let standing = score.GetStanding(fs.id);
      this.SetRowBar(row, CBHudGangBarX(), CBHudGangBarW(), ClampF(standing / 100.0, -1.0, 1.0),
                     standing < 0.0 ? CBHudRed() : CBHudGreen(), true);
    }
  }

  // The panel under the gangs: the one you clicked, and the button to buy them off. An add-on's card as a row of the
  // Gangs list (API/HubCards.reds): its title, its page and subtitle, its colour, and its pips as a bar.
  private func RenderApiCardRow(hub: ref<CBApiHub>, i: Int32, row: Int32) -> Void {
    let card = IsDefined(hub) ? hub.At(i) : null;
    if !IsDefined(card) {
      return;
    }
    let rowId = CBApiCardRowId(card);
    let page = hub.PageTitleAt(i);
    let sub = IsNameValid(page) ? CBT(page) + (StrLen(card.subtitle) > 0 ? "  ·  " + card.subtitle : "") : card.subtitle;
    let tint = CBApiCardTint(card.colour);
    this.SetRow(row, CBHudLayoutGangs(), tint, true, Equals(rowId, this.m_pickFaction), CBApiCardTitle(card), sub, "", "", "", "");
    if row < ArraySize(this.m_rowFaction) {
      this.m_rowFaction[row] = rowId;
    }
    if card.pips > 0 {
      this.SetRowBar(row, CBHudGangBarX(), CBHudGangBarW(), ClampF(Cast<Float>(card.pips) / 5.0, 0.0, 1.0), tint);
    }
  }

  private func RenderFactionDetail(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let top = CBHudContentTop() + Cast<Float>(CBHudListRows()) * CBHudRowHeight() + 24.0;
    if this.m_webShown {
      top = CBHudContentTop() + CBGridGangsH() + 20.0;
      this.PlaceActions(top - 4.0);
    }
    let width = CBHudContentW() - CBHudActionW() - 40.0;
    if Equals(this.m_pickFaction, n"") {
      this.SetAction("", false);
      // Under the web, only what its lines mean; the page's own words are the list's.
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), this.m_webShown ? CBWebLegend() : CBHudFactions(sys),
                   CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let id = this.m_pickFaction;
    // An add-on's card: its lines, and its actions on the page's buttons (API/HubCards.reds).
    let apiCard = CBApiCardOfRowId(game, id);
    if IsDefined(apiCard) {
      let text = "";
      for l in apiCard.lines {
        text += (StrLen(text) > 0 ? "\n" : "") + l;
      }
      let acts = ArraySize(apiCard.actions);
      this.SetAction(acts > 0 ? apiCard.actions[0] : "", acts > 0);
      this.SetExtra(1, acts > 1 ? apiCard.actions[1] : "", acts > 1);
      this.SetExtra(2, acts > 2 ? apiCard.actions[2] : "", acts > 2);
      this.SetBody(CBHudMarginX(), top, width, text, CBHudMaxLinesFor(this.m_tab));
      return;
    }
    let fs = sys.FindFaction(id);
    let score = sys.GetScore();
    // A gang V has never crossed has no record (only a kill or a pay-off files one), and the web can pick it: said so,
    // with what the web knows of it, and nothing is written.
    if !IsDefined(fs) && IsDefined(score) && this.m_webShown {
      this.SetAction("", false);
      let ties = CBWebRelationWords(sys, game, id);
      this.SetBody(CBHudMarginX(), top, CBHudContentW(), CBTf(n"Cyberbane-Hud-YouHaveNeverCrossedThemAnd", [StrUpper(CBFactionLabel(id)), CBPostureName(score.GetPosture(id)), (StrLen(ties) > 0 ? ties + "\n" : "")]),
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
    let out = StrUpper(gang) + "   " + (isOn ? CBPostureName(posture) : CBT(n"Cyberbane-HubWeb-OFF")) + "\n";
    // The web says in words what its lines show for this gang (UI/HubWeb.reds).
    if this.m_webShown && isOn {
      let ties = CBWebRelationWords(sys, game, id);
      out += CBTf(n"Cyberbane-Hud-ToYou", [(StrLen(ties) > 0 ? ties + " " : ""), s"\(CBPostureName(posture))", s"\(RoundF(score.GetStanding(id)))"]);
    }
    let crewLine = isOn ? CBCrewStandingLine(game, id) : "";
    if StrLen(crewLine) > 0 {
      out += crewLine + "\n";   // the crew's own standing with them
    }
    if !isOn {
      out += CBT(n"Cyberbane-Hud-SwitchedOffUnderFactionsInMod");
    } else {
      // Set by hand: what they do, and what V has earned with them underneath.
      if CBGangViewSet(id) {
        out += CBTf(n"Cyberbane-Hud-SetToUnderHowGangsSee", [CBPostureName(posture), CBPostureName(CBPostureFromStanding(fs.standing))]);
      }
      out += CBGangBossLines(sys, id);   // their boss, and what where V stands gets V (Model/GangBosses.reds)
    }
    // Two records, said as two (CBForeignHostile): somebody else's is who shoots on sight, and a pay-off
    // or the switch above changes Cyberbane's alone.
    let foreign = CBForeignHostile(sys, game, id);
    if isOn && !CBGangViewSet(id) && CBTwrOwnsHostility(id) {
      if CBTwrGangHostile(game, id) >= 0 {
        out += CBTf(n"Cyberbane-Hud-DecidesWhetherTheyAreHostileAnd", [CBRememberModName()]);
      } else {
        out += CBTf(n"Cyberbane-Hud-DecidesWhetherTheyAreHostileBut", [CBRememberModName(), CBTwrHostilityWhy()]);
      }
      foreign = 0;   // said just now; the two records are one here
    }
    if foreign == 2 {
      out += CBTf(n"Cyberbane-Hud-HasThemHostileOnSightTheir", [CBRememberModName()]);
    } else {
      if foreign == 1 {
        out += CBT(n"Cyberbane-Hud-TheirPeopleHaveBeenHostileTo");
      }
    }
    let leader = CBWebLeader(sys, game, id);
    if StrLen(leader) > 0 {
      out += CBTf(n"Cyberbane-Hud-LedBy", [s"\(leader)"]);
    }
    let enemy = CBFactionLabel(CBTopEnemyOf(sys, sys.GetContent(), id));
    if StrLen(enemy) > 0 {
      out += CBTf(n"Cyberbane-Hud-AtWarWithHurtingIsHow", [enemy, enemy]);
    }
    out += CBTf(n"Cyberbane-Hud-OfTheirsDownTheyFearYou", [s"\(fs.kills)", s"\(RoundF(score.GetFactionFear(id)))"]);
    // Fear against hatred, on their streets (Reactions/Morale.reds).
    if isOn && CBGangBroken(sys, id) {
      out += CBT(n"Cyberbane-Hud-TheyAreBrokenTheirPeopleFear");
    } else {
      if isOn && Equals(posture, ECBPosture.Vendetta) && foreign != 2 {
        let held = RoundF(CBHoldBackTypical(sys, id) * 10.0);
        if held > 0 {
          out += CBTf(n"Cyberbane-Hud-AboutIn10OfTheirPeople", [s"\(held)"]);
        } else {
          out += CBT(n"Cyberbane-Hud-NoneOfThemAreAfraidEnough");
        }
      }
    }
    // What talking to their people has done today (Reactions/StreetTalk.reds).
    let talked = CBHudTalkToday(sys, id);
    if StrLen(talked) > 0 {
      out += talked + "\n";
    }
    let status = CBHudGangStatus(sys, fs);
    let war = CBWarWords(game, id);   // their chest, their ranks, backed by V, a truce (Economy/War.reds)
    let heat = CBHeatWord(game, fs);  // still hot, or cooling off (Spawn/Hunted.reds)
    if StrLen(heat) > 0 {
      war = StrLen(war) > 0 ? heat + ", " + war : heat;
    }
    if StrLen(status) > 0 || StrLen(war) > 0 {
      let both = StrLen(status) > 0 && StrLen(war) > 0 ? StrLower(status) + "; " + war : StrLower(status) + war;
      out += CBTf(n"Cyberbane-Hud-RightNow", [both]);
    }
    out += "\n";
    let quote = CBPeaceQuote(sys, game, id);
    let money = CBHudEddies(game);
    if Equals(sys.GetPendingPeace(), id) {
      let price = quote >= 0 ? CBTf(n"Cyberbane-Hud-Eb", [s"\(quote)"]) : CBT(n"Cyberbane-Hud-WhatTheyAsk");
      out += CBTf(n"Cyberbane-Hud-YouArePayingThemItGoes", [price]);
      this.SetAction(CBT(n"Cyberbane-Hud-CancelThePayment"), true);
    } else {
      if quote >= 0 {
        out += CBTf(n"Cyberbane-Hud-TheyWillCallItOffFor", [s"\(quote)", s"\(money)"]);
        if money >= quote {
          if Equals(this.m_payArmed, id) {
            out += CBT(n"Cyberbane-Hud-ClickAgainToPay");
            this.SetAction(CBTf(n"Cyberbane-Hud-ConfirmPayEb", [s"\(quote)"]), true);
          } else {
            this.SetAction(CBTf(n"Cyberbane-Hud-PayThemOffEb", [s"\(quote)"]), true);
          }
        } else {
          this.SetAction(CBT(n"Cyberbane-Hud-NotEnoughEddies"), false);
        }
      } else {
        out += CBHudWhyNoPeace(game, id, posture);
        this.SetAction("", false);
      }
    }
    // Below the price, so the page can only ever lose these to its line limit, never the price: what the street knows V
    // by (Model/StreetBook.reds), and their code as V has learnt it (Data/GangCodes.reds).
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
          CBTf(n"Cyberbane-Hud-Down-2", [s"\(d.kills)"]),
          "",
          StrLen(quiet) > 0 ? CBTf(n"Cyberbane-Hud-Quiet", [quiet]) : CBT(n"Cyberbane-Hud-NothingYet"));
        this.SetRowBar(shown, CBHudWideBarX(), CBHudWideBarW(), d.renown / 100.0, rd >= 15 ? pip : CBHudCyan());
        shown += 1;
      }
    }
  }

  // Who holds each district (Model/Territory.reds). One row a district: the gang that holds it, a bar for how much of
  // it they hold, and one word or two for what is going on there.
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
    let order: array<ref<CBRival>>;
    let queuedId = sys.GetLaneRivalId(CBLaneRival());
    let pinned = sys.FindRivalById(queuedId);
    if IsDefined(pinned) && (pinned.state == EnumInt(ECBRivalState.Active)
                             || pinned.state == EnumInt(ECBRivalState.Hunting)) {
      ArrayPush(order, pinned);
    } else {
      queuedId = 0;
    }
    // Then whoever is out there right now, the one leading and anybody with them, then the rest. In roster order a
    // team's second and third names could sit below the fold while they shot at V.
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
    // Drawn as a hierarchy: each gang's line, then its leader, its lieutenants and the rest, in the order of `order`
    // for the gangs, so whoever is coming or already here is at the top.
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
      // Rivals of no gang: an empty name prints as "None"; the cards call the group the same.
      label = Equals(faction, n"") ? CBT(n"Cyberbane-Hud-NOGANG") : StrUpper(NameToString(faction));
    }
    let strength = CBTurfWarsOn() ? CBGangStrengthWord(CBGangStrength(sys, faction)) : "";
    this.SetRow(row, CBHudLayoutWide(), pip, false, false,
      label,
      CBPostureName(posture),
      "",
      strength,
      "",
      n == 1 ? CBT(n"Cyberbane-Hud-1Rival") : CBTf(n"Cyberbane-Hud-Rivals", [s"\(n)"]));   // a count, not a claim they are all out looking
    this.m_rowRival[row] = 0;
    // How much is left of them, where their Rivals show their rank.
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
      role = CBTf(n"Cyberbane-Hud-Rank", [s"\(r.rank)"]);
    }
    // Only one Rival is ever on the clock, so only that one shows a countdown.
    let onClock = r.id == sys.GetLaneRivalId(CBLaneRival());
    let rightCol = CBT(n"Cyberbane-StealthState-WaitingTheirTurn");
    if hunting {
      rightCol = CBT(n"Cyberbane-Hud-HereNow");
      // Not after V: standing where they were seen, for V to come to (Rivals/Whereabouts.reds).
      if sys.IsLairActive() && sys.GetLairRivalId() == r.id {
        rightCol = CBT(n"Cyberbane-Hud-AtTheirPlace");
      }
    } else {
      if onClock && sys.GetLaneTicks(CBLaneRival()) > 0 {
        rightCol = CBTf(n"Cyberbane-Hud-Arrives", [CBWhen(sys.GetLaneTicks(CBLaneRival()))]);
      } else {
        if onClock {
          rightCol = CBT(n"Cyberbane-Hud-AnyMoment");
        } else {
          if StrLen(this.m_holdLabel) > 0 {
            rightCol = this.m_holdLabel;
          }
          // On their cooldown after the last fight (RivalAfterEscapeTicks): nobody picks them until it
          // runs out, which "waiting their turn" did not say.
          if r.huntTicks > 0 {
            rightCol = CBT(n"Cyberbane-Hud-LyingLow");
          }
          let lead = CBCurrentLead(sys, sys.GetGameInstance());
          if IsDefined(lead) && lead.rivalId == r.id {
            rightCol = CBT(n"Cyberbane-Hud-YouKnowWhere");
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
      indent + (IsDefined(content) ? CBRivalDisplayName(content, r) : CBT(n"Cyberbane-RivalSystem-ARival")),
      gang,
      role,
      marks,
      "",
      rightCol);
    this.m_rowRival[row] = r.id;
    // Their rank, one to four, as a bar.
    this.SetRowBar(row, CBHudRankBarX(), CBHudRankBarW(), Cast<Float>(Clamp(r.rank, 1, 4)) / 4.0, hunting ? CBHudRed() : CBHudAmber());
  }

  // The panel under the Rivals: the file on the one you clicked, and three buttons beside it - buy where they are,
  // forget them, forget everybody.
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
      this.SetExtra(3, CBT(n"Cyberbane-Hud-KeepThem"), true);
    } else {
      let id = this.m_pickRival;
      let r = sys.FindRivalById(id);
      // 1. Where they are.
      let pending = sys.GetPendingFind();
      if pending > 0 && pending == id {
        this.SetAction(CBT(n"Cyberbane-Hud-CancelThePayment"), true);
      } else {
        if pending > 0 {
          this.SetAction(CBT(n"Cyberbane-Hud-BuyingAnotherLocation"), false);
        } else {
          let why = CBWhereaboutsForSale(sys, game, r);
          let price = CBWhereaboutsPrice(r);
          if why == 0 {
            if CBHudEddies(game) >= price {
              if CBPhoneDealsReady() {
                this.SetAction(this.m_findArmed == id ? CBT(n"Cyberbane-Hud-ConfirmPutTheWordOut") : CBTf(n"Cyberbane-Hud-AskAroundAboutEb", [s"\(price)"]), true);
              } else {
                this.SetAction(this.m_findArmed == id ? CBTf(n"Cyberbane-Hud-ConfirmPayEb", [s"\(price)"]) : CBTf(n"Cyberbane-Hud-AmbushThemEb", [s"\(price)"]), true);
              }
            } else {
              this.SetAction(CBT(n"Cyberbane-Hud-NotEnoughEddies"), false);
            }
          } else {
            if why == 1 {
              this.SetAction(CBT(n"Cyberbane-Hud-HideoutsAreOff"), false);
            } else {
              if why == 2 {
                this.SetAction(CBT(n"Cyberbane-Hud-OutAfterYouNow"), false);
              } else {
                if why == 3 {
                  this.SetAction(CBT(n"Cyberbane-Hud-YouKnowWhereTheyAre"), false);
                } else {
                  if why == 5 {
                    this.SetAction(CBT(n"Cyberbane-Hud-TheirFactionIsOff"), false);
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
      // 2. Call them out: next to finding them, both being ways to meet them.
      let bookH = CBIntelBook.Get(game);
      if !CBSendWordOn() || !IsDefined(r) {
        this.SetExtra(1, "", false);
      } else {
        if IsDefined(bookH) && bookH.WordSent(r.id) {
          this.SetExtra(1, CBT(n"Cyberbane-Hud-WordSent"), false);
        } else {
          if sys.GetPendingWord() == r.id {
            this.SetExtra(1, CBT(n"Cyberbane-Hud-SendingWord"), false);
          } else {
            this.SetExtra(1, CBT(n"Cyberbane-Hud-SendWord"), CBWhereaboutsForSale(sys, game, r) == 0);
          }
        }
      }
      // 3. Forget them.
      if sys.IsRivalForgetPending(id) {
        this.SetExtra(2, CBT(n"Cyberbane-Hud-KeepThisOne"), true);
      } else {
        if IsDefined(r) && !CBRivalForgettable(sys, r) {
          this.SetExtra(2, sys.RivalKeptByCrew(r.id) ? CBT(n"Cyberbane-Hud-OneOfYourCrew") : CBT(n"Cyberbane-Hud-OnTheirWayWait"), false);
        } else {
          this.SetExtra(2, this.m_forgetArmed == id ? CBT(n"Cyberbane-Hud-ClickAgainToForget") : CBT(n"Cyberbane-Hud-ForgetThisRival"), IsDefined(r));
        }
      }
      // 4. Forget everybody.
      this.SetExtra(3, this.m_purgeArmed ? CBTf(n"Cyberbane-Hud-ClickAgainForgetAll", [s"\(count)"]) : CBT(n"Cyberbane-Hud-ForgetEveryRival"), true);
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
    let autoLabel = ArraySize(earned) > 0 ? CBTf(n"Cyberbane-Hud-Automatic", [CBHudActiveTitle(sys)]) : CBT(n"Cyberbane-Hud-Automatic-2");
    // Automatic, then every title V has earned, then the rest, and the page shows a window onto them. There are more
    // titles than rows now, and the last of them had simply fallen off the end.
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
          autoLabel, "", "", "", "", onAuto ? CBT(n"Cyberbane-Hud-GOINGBY") : "");
        this.m_rowTitle[row] = n"";
      } else {
        let have = sys.HasTitle(def.id);
        let mine = Equals(def.id, chosen);
        let status = mine ? CBT(n"Cyberbane-Hud-GOINGBY") : CBT(n"Cyberbane-Hud-EARNED");
        if !have {
          status = CBTitleProgress(sys, def.id);
          if StrLen(status) == 0 {
            status = CBT(n"Cyberbane-Hud-LOCKED");
          }
        }
        this.SetRow(row, CBHudLayoutTitles(), mine ? CBHudCyan() : (have ? CBHudAmber() : CBHudGrey()), true,
          Equals(def.id, reading), CBTitleDisplay(sys, def), "", "", "", "", status);
        this.m_rowTitle[row] = def.id;
      }
      row += 1;
    }
  }

  // ---- The web of gangs ([H1], UI/HubWeb.reds) ------------------------------------------------------------

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
    // The glows first, so every one is under every line.
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
      // The game's card under the words, and its frame round them; both coloured by PaintWeb.
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
    // V's crew's card: the Crew page's screen for the crew itself.
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

  // ---- The Rivals tree ([H2]) -------------------------------------------------------------------------------

  // The gangs that have Rivals to draw, in roster order. Every gang with a Rival on the roster, and last a group of its
  // own for Rivals of no gang, whom the list showed and the cards never did.
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
    let name = CBT(n"Cyberbane-Hud-EMPTYCHAIR");
    // Who steps up, by name without the nickname so it fits whole; said once, in the first empty chair.
    let line = StrLen(empty) > 0 ? CBTf(n"Cyberbane-Hud-NEXT", [StrUpper(CBHudNameNoNick(empty))]) : CBT(n"Cyberbane-Hud-NOBODYYET");
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
          // One of V's crew now: said so, not "left Night City".
          if CBRivalRunsWithV(game, r) {
            line = CBT(n"Cyberbane-Hud-RUNSWITHYOU");
            tint = CBHudCyan();
          } else {
            line = CBT(n"Cyberbane-Hud-LEFTNIGHTCITY");
          }
        } else {
          line = how == CBEndingNotByV() ? CBT(n"Cyberbane-Hud-KILLEDNOTBYYOU") : CBT(n"Cyberbane-Hud-DEADBYYOURHAND");
        }
      } else {
        line = CBTf(n"Cyberbane-Hud-RANK", [s"\(r.rank)", StrUpper(hunting ? CBT(n"Cyberbane-Hud-HuntingYou") : CBRivalStateName(r.state))]);
        // Who they are to V or to another of theirs, in words: a bond and V's oldest grudge were lines across the tree
        // from the middle of one box to the middle of another, and showed only as strokes in the air between them.
        let bookT = CBRivalBook.Get(game);
        let with = IsDefined(bookT) ? bookT.BondWith(r.id) : 0;
        let partner = with > 0 ? sys.FindRivalById(with) : null;
        if r.id == this.m_treeGrudge {
          lead = CBTf(n"Cyberbane-Hud-YourOldestGrudgeMetTimes", [s"\(CBRivalTimesMet(r))"]);
          leadTint = CBHudRed();
        } else {
          if IsDefined(partner) && StrLen(CBBondWord(bookT.BondKind(r.id))) > 0 {
            lead = CBCapFirst(CBBondWord(bookT.BondKind(r.id))) + " " + CBHudNameNoNick(CBRivalDisplayName(sys.GetContent(), partner));
            leadTint = CBHudCyan();
          } else {
            lead = CBRivalTimesMet(r) > 0 ? CBTf(n"Cyberbane-Hud-MetRanSpared", [s"\(CBRivalTimesMet(r))", s"\(r.escapes)", s"\(r.sparedByV)"]) : CBT(n"Cyberbane-Hud-NeverMetYou");
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
    // Nothing faded: a faded card showed whatever was under it through its words. The picked one lights up.
    this.m_webBox[slot].SetOpacity(1.0);
  }

  // A gang's leader, their three lieutenants, the rest of their Rivals as the bench, and the fallen, top down: the
  // hierarchy that already exists (CBFactionState leader and lieutenants), with the first empty chair naming who steps
  // up next (the order CBHierarchyFill uses).
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
        this.m_webBoxLine[0].SetText(ArraySize(gangs) > 1 ? CBT(n"Cyberbane-Hud-NEXTGANG") : CBT(n"Cyberbane-Hud-YOU"));
      }
    }
    // Drawn whether or not the gang has a record: this asked for one, and a gang V had never killed one of or paid off
    // had none, so its Rival was in the list and the cards said "No Rivals yet".
    if ArraySize(gangs) == 0 || Equals(gang, n"") {
      this.PlaceWord(words, 660.0, 200.0, CBT(n"Cyberbane-Hud-NoRivalsYet"), CBHudGrey(), 1.0);
      words += 1;
    } else {
      // Rows, each named on the left: the leader, the lieutenants, the rest, the fallen. No lines between them: the
      // chair lines and the bond lines crossed the boxes wherever they were drawn.
      let gangName = Equals(gang, CBTreeNoGang()) ? CBT(n"Cyberbane-Hud-NoGang") : CBFactionLabel(gang);
      let label = StrUpper(StrLen(gangName) > 0 ? gangName : NameToString(gang));
      if ArraySize(gangs) > 1 {
        label += CBTf(n"Cyberbane-Hud-OF", [s"\(ArrayFindFirst(gangs, gang) + 1)", s"\(ArraySize(gangs))"]);
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
      this.m_treeGrudge = 0;
      let most = 1;
      for r in sys.GetRivals() {
        if IsDefined(r) && Equals(CBTreeGangOf(r), gang) {
          let seated = r.id == leaderId || r.id == lt1Id || r.id == lt2Id || r.id == lt3Id;
          let around = CBRivalStillAround(r) || r.state == EnumInt(ECBRivalState.Debtor) || r.state == EnumInt(ECBRivalState.Dormant);
          if around && CBRivalTimesMet(r) > most {
            most = CBRivalTimesMet(r);
            this.m_treeGrudge = r.id;
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
      this.PlaceLabel(words, 0.0, ch / 2.0, CBT(n"Cyberbane-Hierarchy-LEADER"), CBHudDim());
      words += 1;
      this.TreeBox(sys, game, 1, leader, IsDefined(nextUp) ? CBRivalDisplayName(sys.GetContent(), nextUp) : "",
                   CBTreeCardX(0), 0.0, cw, ch, false);
      let rowY = ch + CBTreeRowGap();
      this.PlaceLabel(words, 0.0, rowY + ch / 2.0, CBT(n"Cyberbane-Hud-LIEUTENANTS"), CBHudDim());
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
        this.PlaceLabel(words, 0.0, rowY + ch / 2.0, CBT(n"Cyberbane-Hud-THEREST"), CBHudDim());
        words += 1;
        k = 0;
        while k < ArraySize(benchIds) {
          this.TreeBox(sys, game, 5 + k, sys.FindRivalById(benchIds[k]), "", CBTreeCardX(k), rowY, cw, ch, false);
          k += 1;
        }
        rowY += ch + CBTreeRowGap();
      }
      if ArraySize(fallenIds) > 0 {
        this.PlaceLabel(words, 0.0, rowY + CBTreeFallenH() / 2.0, CBT(n"Cyberbane-Hud-THEFALLEN"), CBHudDim());
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

  // Filled from the books as the page is drawn: nothing per frame. The gangs as cards: a grid, the ones that want V
  // dead first, then the corporations and the police in a row of their own.
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
    while i <= CBWebGangSlots() {
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
    // V's crew in the row beneath, first beside the corporations and the law. It had the grid's one empty place, and
    // twelve gangs leave none: with the Scrappers it would have gone from the page.
    this.m_crewCardShown = false;
    let crew = this.CrewCardWanted(game);
    let across = crew ? 5 : 4;
    let rowW = (CBHudContentW() - Cast<Float>(across - 1) * CBCardGapX()) / Cast<Float>(across);
    let corpY = Cast<Float>((CBWebGangSlots() + 3) / 4) * (h + CBCardGapY());
    let col = 0;
    if crew {
      this.CrewWebCard(sys, game, 0.0, corpY, rowW, CBCardSmallH());
      col = 1;
    }
    let c = CBWebGangSlots() + 1;
    while c < CBWebSlotCount() {
      ArrayPush(this.m_webOrder, c);
      this.GangCard(sys, game, score, c, Cast<Float>(col) * (rowW + CBCardGapX()), corpY, rowW, CBCardSmallH(), true);
      col += 1;
      c += 1;
    }
    this.HideWebFrom(0, 0);
    this.PaintWeb();
  }

  // V's crew among the gangs, in the box the web once drew V in: its name and colours, and how the gang picked stands
  // with it, or else the one that thinks least of it. Clicked, the Crew page's screen for the crew itself.
  private func CrewCardWanted(game: GameInstance) -> Bool {
    let book = CBCrewBook.Get(game);
    let bb = CBCrewBannerBook.Get(game);
    return CBMyCrewOn() && IsDefined(book) && IsDefined(bb) && (book.Count() > 0 || bb.StandCount() > 0 || bb.FallenCount() > 0);
  }

  // Small in the row beneath the gangs: its name and roster on two lines, the bar for the gang, no third line.
  private func CrewWebCard(sys: ref<CyberbaneSystem>, game: GameInstance, x: Float, y: Float, w: Float, h: Float) -> Void {
    let book = CBCrewBook.Get(game);
    let bb = CBCrewBannerBook.Get(game);
    if !this.CrewCardWanted(game) {
      return;
    }
    let small = h < CBCardH();
    let slot = 0;
    this.PlaceWebBox(slot, x, y, w, h, true);
    this.DressBox(slot, w, h, small ? CBPicSmallName() : CBPicName(), small ? CBPicSmallLine() : CBPicLine(), CBPicLead(), false);
    let colour = CBCrewColour(game);
    let name = CBCrewNameOf(game);
    this.BoxText(this.m_webBoxName[slot], StrLen(name) > 0 ? name : CBT(n"Cyberbane-CrewBanner-YourCrew"), w - 24.0, small ? CBPicSmallName() : CBPicName(), CBPicNameLeast(), true);
    let kb = CBCrewKitBook.Get(game);
    let wars = IsDefined(kb) ? kb.WarsWon() : 0;
    let line = CBTf(n"Cyberbane-Hud-ONTHEROSTER", [s"\(book.Count())", (wars > 0 ? CBTf(n"Cyberbane-Hud-WON", [s"\(wars)", wars == 1 ? CBT(n"Cyberbane-Hud-WAR") : CBT(n"Cyberbane-Hud-WARS")]) : "")]);
    this.BoxText(this.m_webBoxLine[slot], line, w - 24.0, small ? CBPicSmallLine() : CBPicLine(), CBPicLineLeast(), false);
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
    let lead = IsNameValid(gang) ? CBTf(n"Cyberbane-Hud-With", [s"\(CBCrewStandWord(v))", s"\(CBPhoneGangSender(gang))"]) : CBT(n"Cyberbane-Hud-NoGangHoldsAGrudgeYet");
    if IsDefined(this.m_webBoxLead[slot]) {
      this.BoxText(this.m_webBoxLead[slot], lead, w - 24.0, CBPicLead(), CBPicLeadLeast(), false);
      this.m_webBoxLead[slot].SetTintColor(IsNameValid(gang) ? CBCrewStandTint(v) : CBHudDim());
      this.m_webBoxLead[slot].SetVisible(!small);
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
    // how it stands with that one, so one click reads the whole web for it: the lines the web drew, in words.
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
          tag = CBTf(n"Cyberbane-HubWeb-AtWarWith", [CBPhoneGangSender(enemy)]);
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

  // ---- The pool's boxes, dressed for each drawing --------------------------------------------------------

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
    // The plain bars are the web's; a picture of these segments instead.
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

  // ---- Night City as a map ---------------------------------------------------------------------------------

  // Each district a box where it lies, joined by its roads.
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
            line = CBTf(n"Cyberbane-Hud-Hold", [s"\(CBCapFirst(CBPhoneGangSender(holder)))", s"\(RoundF(shares[top] * 100.0))"]);
            if CBIsCrewTurf(holder) {
              tint = CBCrewColour(game);   // V's crew holds it, in its own colours
              barTint = tint;
            }
            lead = CBHudTurfStatus(game, content, d, holder, ids, shares, second);
            a = shares[top];
          } else {
            line = CBT(n"Cyberbane-Hud-NobodyHoldsIt");
          }
          if CBOwnDistrict(game, d) {
            line = CBT(n"Cyberbane-Hud-YourStreets");
            tint = CBHudGreen();
          }
        } else {
          let rd = RoundF(renown);
          tint = rd >= 75 ? CBHudRed() : (rd >= 40 ? CBHudAmber() : (rd >= 15 ? CBHudCyan() : CBHudGrey()));
          barTint = rd >= 15 ? tint : CBHudCyan();
          line = CBTf(n"Cyberbane-Hud-Renown", [s"\(rd)"]);
          let kills = IsDefined(ds) ? ds.kills : 0;
          lead = kills > 0 ? (kills == 1 ? CBT(n"Cyberbane-Hud-OnePutDownHere") : CBTf(n"Cyberbane-Hud-PutDownHere", [s"\(kills)"])) : CBT(n"Cyberbane-Hud-NothingYet-2");
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
    // Nothing picked: only what the map shows. The page's own words, the gangs you have broken and every district's
    // story, are the list's, where there is room for them.
    if Equals(d, n"") {
      return turf ? CBT(n"Cyberbane-Hud-EachCardIsADistrictAnd")
                  : CBT(n"Cyberbane-Hud-EachCardIsADistrictAnd-2");
    }
    let out = StrUpper(CBDistrictLabel(d)) + (Equals(d, sys.GetCurrentDistrict()) ? CBT(n"Cyberbane-Hud-YouAreHere") : "") + "\n";
    if turf && Equals(d, sys.GetCurrentDistrict()) {
      let hood = CBHoodHereLine(sys, game);
      if StrLen(hood) > 0 {
        out += hood + ".\n";
      }
    }
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
        out += CBTf(n"Cyberbane-Hud-HoldIt", [s"\(CBCapFirst(CBFactionLabel(holder)))"]);
      }
      // The crew's own: who runs it for them (Reactions/CrewGang.reds), and a war being fought there.
      let runs = CBRunnerLine(sys, game, d);
      if StrLen(runs) > 0 {
        out += runs + ".\n";
      }
      if IsDefined(CBGangWarFront(game, holder)) {
        out += CBTf(n"Cyberbane-HubWar-WarOnHere", [CBCapFirst(CBFactionLabel(holder))]);
      }
      if StrLen(list) > 0 {
        out += CBTf(n"Cyberbane-Hud-WhoHasStreetsHere", [list]);
      } else {
        out += CBT(n"Cyberbane-Hud-NoGangHasStreetsHere");
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
        out += CBT(n"Cyberbane-Hud-NobodyRunsItButYouThe");
      }
      out += CBTf(n"Cyberbane-Hud-YourNameHereOf100", [s"\(renown)"]);
      return out;
    }
    let peak = IsDefined(ds) ? RoundF(ds.renownPeak) : 0;
    out += CBTf(n"Cyberbane-Hud-YourRenownHereOf100", [s"\(renown)", (peak > renown ? CBTf(n"Cyberbane-Hud-AtItsHeight", [s"\(peak)"]) : "")]);
    if IsDefined(ds) && ds.kills > 0 {
      out += ds.kills == 1 ? CBT(n"Cyberbane-Hud-OnePutDownHere") : CBTf(n"Cyberbane-Hud-PutDownHere", [s"\(ds.kills)"]);
      if ds.lethalOrBrutal > 0 {
        out += CBTf(n"Cyberbane-Hud-OfThemTheHardWay", [s"\(ds.lethalOrBrutal)"]);
      }
      if ds.quietTakedowns > 0 {
        out += CBTf(n"Cyberbane-Hud-TakenDownWithoutASound", [s"\(ds.quietTakedowns)"]);
      }
      out += ".\n";
      let quiet = CBHudSince(CBGameSeconds(game), ds.lastIncidentAt);
      if StrLen(quiet) > 0 {
        out += CBTf(n"Cyberbane-Hud-TheLastTroubleHereWasAgo", [s"\(quiet)"]);
      }
    } else {
      out += CBT(n"Cyberbane-Hud-YouHaveNotMadeAnyTrouble");
    }
    out += CBCrewMapLines(sys, game, d);   // the crew's people, wars and corners here
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

  // ---- The crew (Reactions/Crew.reds) --------------------------------------------------------------------------

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
    this.ShowCrewViews(book.Count() > 0 || book.PastCount() > 0);
    if sys.HubVisual(CBHudCrewTab()) {
      this.RenderCrewPicture(sys, game, book, offer);
      top += CBWebHeight() + 24.0;
    } else {
      let rows = this.RenderCrewRows(sys, game, book, offer);
      top += Cast<Float>(Max(rows, 1)) * CBHudRowHeight() + 24.0;
    }
    // What can be done: the buttons follow the pick, top to bottom. The picked one first: "Need you.
    let m = this.m_pickCrew > 0 ? book.Find(this.m_pickCrew) : null;
    let why = "";
    let oneWhy = "";
    let calling = false;
    if IsDefined(m) {
      let first = CBCrewFirst(sys, m);
      if book.IsOut(m.id) && !book.leaving {
        this.SetAction(book.reqHomeOne == m.id ? CBTf(n"Cyberbane-Hud-SendingOneHome", [first]) : CBTf(n"Cyberbane-Hud-OneHeadHome", [first]), true,
                       CBTf(n"Cyberbane-Hud-HelpSendOneHome", [first]));
      } else {
        if book.reqCallOne == m.id {
          this.SetAction(CBTf(n"Cyberbane-Hud-CallingOne", [first]), true, CBT(n"Cyberbane-Hud-HelpTakeBack"));
          calling = true;
        } else {
          oneWhy = CBCrewCallBlocked(sys, game, false, true, m.id);
          this.SetAction(CBTf(n"Cyberbane-Hud-OneNeedYouNow", [first]), StrLen(oneWhy) == 0, CBTf(n"Cyberbane-Hud-HelpCallOne", [first]));
        }
      }
      this.SetExtra(1, CBTf(n"Cyberbane-Hud-OrdersFor", [first]), true, CBTf(n"Cyberbane-Hud-HelpOrders", [first]));
    }
    if offer && this.m_pickCrew == -1 {
      if book.reqHire {
        this.SetAction(CBT(n"Cyberbane-Hud-HiringClickToTakeItBack"), true);
      } else {
        this.SetAction(CBTf(n"Cyberbane-Hud-HireTheSoloEb", [s"\(book.offerPrice)"]), book.HasRoom() && CBHudEddies(game) >= book.offerPrice);
      }
    }
    let crewWhy = "";
    if book.Count() > 0 {
      if book.OutCount() > 0 && !book.leaving {
        this.SetExtra(2, book.reqHome ? CBT(n"Cyberbane-Hud-SendingThemHomeClickToTake") : CBT(n"Cyberbane-Hud-SendYourCrewHome"), true,
                      CBT(n"Cyberbane-Hud-HelpSendCrewHome"));
      } else {
        if book.reqCall {
          this.SetExtra(2, CBT(n"Cyberbane-Hud-CallingThemClickToTakeIt"), true, CBT(n"Cyberbane-Hud-HelpTakeBack"));
          calling = true;
        } else {
          crewWhy = CBCrewCallBlocked(sys, game, false, true);
          this.SetExtra(2, CBT(n"Cyberbane-Hud-CallYourCrew"), StrLen(crewWhy) == 0, CBT(n"Cyberbane-Hud-HelpCallCrew"));
        }
      }
    }
    // Why a call can't be made, once: the same reason for both (driving, a scene, a safe place) is said for both.
    if StrLen(oneWhy) > 0 && Equals(oneWhy, crewWhy) {
      why += CBTf(n"Cyberbane-Hud-CanTCallThemNow", [CBLowFirst(crewWhy)]);
    } else {
      if StrLen(oneWhy) > 0 && IsDefined(m) {
        // Their own reason names them and is a sentence of its own ("Sai just got back, give it 9 minutes."); anything
        // else (driving, a scene, no room) is why nobody can be called just now.
        let own = CBCrewWhyNotReady(sys, game, m, CBGameSeconds(game));
        if StrLen(own) > 0 && Equals(oneWhy, CBTf(n"Cyberbane-Crew-OneNotReady", [own])) {
          why += oneWhy + "\n";
        } else {
          why += CBTf(n"Cyberbane-Hud-CantCallOneNow", [CBCrewFirst(sys, m), CBLowFirst(oneWhy)]);
        }
      }
      if StrLen(crewWhy) > 0 {
        why += CBTf(n"Cyberbane-Hud-CanTCallThemNow", [CBLowFirst(crewWhy)]);
      }
    }
    if calling {
      why += CBT(n"Cyberbane-Hud-TheyLlAnswerOnceYouRe");
    } else {
      if book.Count() > 0 && book.OutCount() == 0 && StrLen(crewWhy) == 0 && !CBCrewTrouble(sys, game) {
        why += CBT(n"Cyberbane-Hud-NothingOnYouRightNowTwo");
      }
    }
    if book.CutOwed() > 0 {
      why += CBTf(n"Cyberbane-Hud-CutOwedWhere", [s"\(book.CutOwed())"]);
    }
    if offer && this.m_pickCrew != -1 {
      why += CBT(n"Cyberbane-Hud-ASoloIsOnOfferPick");
    }

    // The picked one in a line or two; everything about them is on the Member view. Written out whole here, it ran past
    // its lines and stopped at "Rookie, rank 1 of...".
    let file = this.m_pickCrew == -1 ? CBCrewFile(sys, game, book, m, true) : CBCrewRosterLine(sys, game, book, m);
    let crewName = CBCrewNameOf(game);
    let named = StrLen(crewName) > 0 ? StrUpper(crewName) + "\n" : "";
    named += CBCrewPowerLine(sys, game);   // what the crew counts for, and the streets it holds
    let kbWars = CBCrewKitBook.Get(game);
    if IsDefined(kbWars) && kbWars.WarsWon() > 0 {
      named += CBTf(n"Cyberbane-Hud-WarsYourCrewStartedAndWon", [s"\(kbWars.WarsWon())"]);
    }
    let summary = CBCrewSummary(sys, game, book.CutOwed() > 0);   // the cut owed is said above, with where to pay it
    let text = named + why + (StrLen(file) > 0 ? file + "\n" + summary : summary);
    this.SetBody(x, top, anything ? w - CBHudActionW() - 40.0 : w, text, CBHudMaxLinesFor(this.m_tab));
  }

  // The Crew page's other screens: a member's orders and the lists they pick from, the crew's own record, naming it,
  // and the memorial. False when there is nobody to show it for.
  private func RenderCrewMode(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Bool {
    let x = CBHudMarginX();
    let w = CBHudContentW();
    let top = CBHudContentTop();
    let m = this.m_pickCrew > 0 ? book.Find(this.m_pickCrew) : null;
    let forMember = (this.m_crewMode >= 1 && this.m_crewMode <= 2) || this.m_crewMode == 6 || this.m_crewMode == 8
                 || this.m_crewMode == 10 || this.m_crewMode == CBHudCrewMemberMode();
    if forMember && !IsDefined(m) {
      this.m_crewMode = 0;
      return false;
    }
    this.HideWeb();
    if this.m_crewMode == 4 {
      this.ShowNameInput(game, x, top);
      this.SetAction(CBT(n"Cyberbane-Hud-SaveTheName"), true, CBT(n"Cyberbane-Hud-HelpSaveName"));
      this.SetExtra(1, CBT(n"Cyberbane-Hud-Cancel"), true, CBT(n"Cyberbane-Hud-HelpCancelName"));
      this.SetBody(x, top + 110.0, w - CBHudActionW() - 40.0,
        CBT(n"Cyberbane-Hud-TypeANameForYourCrew"),
        CBHudMaxLinesFor(this.m_tab));
      return true;
    }
    if this.m_crewMode == 11 {
      this.ShowCrewViews(true);
      this.RenderWarParty(sys, game, book);
      return true;
    }
    if this.m_crewMode == 12 {
      this.ShowCrewViews(true);
      this.RenderWarTargets(sys, game);
      return true;
    }
    if this.m_crewMode == 20 {
      this.ShowCrewViews(true);
      this.RenderWarView(sys, game, book);
      return true;
    }
    if this.m_crewMode == 21 {
      this.ShowCrewViews(true);
      this.RenderWarOrders(sys, game);
      return true;
    }
    if this.m_crewMode == 22 {
      this.ShowCrewViews(true);
      this.RenderWarTerms(sys, game);
      return true;
    }
    if this.m_crewMode == 23 {
      this.ShowCrewViews(true);
      this.RenderSquads(sys, game, book);
      return true;
    }
    if this.m_crewMode == 24 {
      this.ShowNameInput(game, x, top);
      this.SetAction(CBT(n"Cyberbane-Hud-SaveTheName"), true, CBT(n"Cyberbane-Hud-HelpSaveName"));
      this.SetExtra(1, CBT(n"Cyberbane-Hud-Cancel"), true, CBT(n"Cyberbane-Hud-HelpCancelName"));
      this.SetBody(x, top + 110.0, w - CBHudActionW() - 40.0, CBT(n"Cyberbane-HubWar-TypeSquadName"), CBHudMaxLinesFor(this.m_tab));
      return true;
    }
    if this.m_crewMode == 25 {
      this.ShowCrewViews(true);
      this.RenderRunners(sys, game, book);
      return true;
    }
    if this.m_crewMode == 26 {
      this.ShowCrewViews(true);
      this.RenderCrewPlace(sys, game);
      return true;
    }
    if this.m_crewMode == 27 {
      this.ShowCrewViews(true);
      this.RenderUpgrades(sys, game);
      return true;
    }
    if this.m_crewMode == 10 {
      this.ShowNameInput(game, x, top);
      this.SetAction(CBT(n"Cyberbane-Hud-SaveTheName"), true, CBT(n"Cyberbane-Hud-HelpSaveName"));
      this.SetExtra(1, CBT(n"Cyberbane-Hud-Cancel"), true, CBT(n"Cyberbane-Hud-HelpCancelName"));
      this.SetBody(x, top + 110.0, w - CBHudActionW() - 40.0,
        CBTf(n"Cyberbane-Hud-TypeANameForThem", [CBCrewFullNameNicked(sys, m.kind, m.faction, m.rival, m.seed, false, m.seat)]),
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
      this.ShowCrewViews(true);
      this.RenderCrewRecord(sys, game, book);
      return true;
    }
    if this.m_crewMode == CBHudCrewMemberMode() {
      this.ShowCrewViews(true);
      this.RenderCrewMember(sys, game, book, m);
      return true;
    }
    if this.m_crewMode == 8 {
      this.RenderCrewJobs(sys, game, book, m);
      return true;
    }
    if this.m_crewMode == 9 {
      this.RenderCrewDuel(sys, game, book);
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
      // Through the list window, so a bag of more than one screen scrolls like every other list: it stopped at the
      // first ten.
      let i = this.ListWindow(ArraySize(this.m_pickItems), CBHudListRows());
      while i < ArraySize(this.m_pickItems) && row < CBHudListRows() {
        let id = this.m_pickItems[i];
        let data = this.m_crewMode == 1 ? CBCrewItemData(game, id) : (IsDefined(ts) && IsDefined(player) ? ts.GetItemData(player, id) : null);
        let kind = "";
        let tier = "";
        let change = "";
        if IsDefined(data) {
          tier = CBCrewTierWord(CBCrewTierOf(RPGManager.GetItemQuality(data)));
          kind = this.m_crewMode == 1 ? CBCrewSeatWord(CBCrewSeatForWeapon(data.GetItemType()))
                                      : CBCrewChromeNumbers(CBCrewChromeRead(ItemID.GetTDBID(id)), 2);
          // Before it goes in: "Armour x1.30 -> x1.48".
          if this.m_crewMode == 2 && IsDefined(m) {
            change = CBCrewChromeChange(game, m, ItemID.GetTDBID(id));
          }
        }
        this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBCrewItemName(ItemID.GetTDBID(id)), this.m_crewMode == 1 ? kind : "", tier,
                    this.m_crewMode == 1 ? "" : kind, "", change);
        this.SetRowHelp(row, this.m_crewMode == 1 ? CBCrewWeaponHelp(data) : (StrLen(change) > 0 ? change + ". " + kind : kind));
        this.m_rowCrew[row] = i + 1;
        row += 1;
        i += 1;
      }
      intro = this.m_crewMode == 1
        ? CBTf(n"Cyberbane-Hud-PickAWeaponForItsMods", [s"\(name)"])
        : CBTf(n"Cyberbane-Hud-PickChromeForFromWhatYou", [s"\(name)", s"\(CBCrewChromeSlots())"]);
      if row == 0 {
        intro = this.m_crewMode == 1 ? CBT(n"Cyberbane-Hud-YouHaveNoSpareWeaponTo")
                                     : CBT(n"Cyberbane-Hud-YouHaveNoSpareChromeThat");
      }
    }
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    // Why some of V's chrome is not in the list: it only works for V.
    if this.m_crewMode == 2 {
      let left = CBCrewChromeLeftOut(game);
      if left > 0 {
        intro += "\n" + (left == 1 ? CBT(n"Cyberbane-Hud-OneChromeOnlyYours") : CBTf(n"Cyberbane-Hud-ChromeOnlyYours", [s"\(left)"]));
      }
    }
    let bodyTop = top + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(x, bodyTop, w - CBHudActionW() - 40.0, intro, CBHudMaxLinesFor(this.m_tab));
    return true;
  }

  // Everything about one of them on one screen (the Member view): their story on the left; on the right their numbers
  // as the game gets them when they are called, the weapon slot and each chrome slot (a click puts something in), and
  // their rank with how far it is to the next.
  private func RenderCrewMember(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>) -> Void {
    this.PlaceRows(CBHudLayoutMember());
    let now = CBGameSeconds(game);
    let kb = CBCrewKitBook.Get(game);
    let k = IsDefined(kb) ? kb.Find(m.id) : null;
    let n = CBCrewNumbersNow(sys, game, book, m);
    let lay = CBHudLayoutMember();
    let row = 0;
    this.SetRow(row, lay, CBHudGreen(), false, false, CBT(n"Cyberbane-Hud-StatHealth"), CBCrewHealthText(n), "", "", "", CBCrewShareText(n.ToughShare()));
    this.SetRowHelp(row, CBCrewStatHelp(n, 0));
    row += 1;
    this.SetRow(row, lay, CBHudCyan(), false, false, CBT(n"Cyberbane-Hud-StatArmour"), CBCrewArmourText(n), "", "", "",
                n.vArmour > 0.0 ? StrUpper(CBTf(n"Cyberbane-Hud-StatYours", [CBHudNum(n.vArmour)])) : "");
    this.SetRowHelp(row, CBCrewStatHelp(n, 1));
    row += 1;
    this.SetRow(row, lay, CBHudRed(), false, false, CBT(n"Cyberbane-Hud-StatDamage"), CBCrewDamageText(n), "", "", "", CBCrewShareText(n.DpsShare()));
    this.SetRowHelp(row, CBCrewStatHelp(n, 2));
    row += 1;
    let extras = CBCrewKitExtrasLine(n);
    this.SetRow(row, lay, CBHudAmber(), false, false, CBT(n"Cyberbane-Hud-StatChrome"), StrLen(extras) > 0 ? extras : CBT(n"Cyberbane-Hud-StatNothingMore"), "", "", "", "");
    this.SetRowHelp(row, CBT(n"Cyberbane-Hud-HelpStatChrome"));
    row += 1;
    this.SetRow(row, lay, CBHudLabel(), false, false, CBT(n"Cyberbane-Hud-StatRank"), CBCrewRankShort(game, m), "", "", "", "");
    this.SetRowBar(row, 470.0, 140.0, CBCrewRankProgress(game, m), CBHudCyan());
    this.SetRowHelp(row, CBT(n"Cyberbane-Hud-HelpRankBar"));
    row += 1;
    // The weapon slot.
    let out = book.IsOut(m.id);
    let free = !out && !CBCrewAway(game, m.id, now);
    if IsDefined(k) && k.hasWeapon {
      this.SetRow(row, lay, CBHudLabel(), free, false, CBT(n"Cyberbane-Hud-SlotWeapon"), CBCrewItemName(ItemID.GetTDBID(k.weapon)), "", "", "",
                  StrUpper(CBCrewTierWord(k.weaponTier)));
      this.m_rowCrew[row] = CBCrewAskTakeBack();
      this.SetRowHelp(row, CBT(n"Cyberbane-Hud-HelpTakeBackWeapon"));
    } else {
      this.SetRow(row, lay, CBHudDim(), free, false, CBT(n"Cyberbane-Hud-SlotWeapon"), CBT(n"Cyberbane-Hud-SlotEmptyGive"), "", "", "", "");
      this.m_rowCrew[row] = CBCrewAskGive();
      this.SetRowHelp(row, CBT(n"Cyberbane-Hud-HelpGiveWeapon"));
    }
    row += 1;
    // Each chrome slot, filled or empty.
    let slot = 0;
    while slot < CBCrewChromeSlots() && row < CBHudListRows() {
      let c = IsDefined(k) ? k.ChromeAt(slot) : TDBID.None();
      if TDBID.IsValid(c) {
        this.SetRow(row, lay, CBHudAmber(), false, false, CBTf(n"Cyberbane-Hud-SlotChrome", [s"\(slot + 1)"]), CBCrewItemName(c), "", "", "",
                    "");
        this.SetRowHelp(row, CBCrewChromeNumbers(CBCrewChromeRead(c), 4));
      } else {
        this.SetRow(row, lay, CBHudDim(), free, false, CBTf(n"Cyberbane-Hud-SlotChrome", [s"\(slot + 1)"]), CBT(n"Cyberbane-Hud-SlotEmptyChrome"), "", "", "", "");
        this.m_rowCrew[row] = CBCrewAskChrome();
        this.SetRowHelp(row, CBT(n"Cyberbane-Hud-HelpChrome"));
      }
      row += 1;
      slot += 1;
    }
    this.SetBody(CBHudMarginX(), CBHudContentTop(), CBHudMemberColX() - 30.0, CBCrewMemberFile(sys, game, book, m), CBHudMaxLinesFor(this.m_tab));
    // The roster's buttons: their own call, their orders, the whole crew.
    let first = CBCrewFirst(sys, m);
    if out && !book.leaving {
      this.SetAction(book.reqHomeOne == m.id ? CBTf(n"Cyberbane-Hud-SendingOneHome", [first]) : CBTf(n"Cyberbane-Hud-OneHeadHome", [first]), true,
                     CBTf(n"Cyberbane-Hud-HelpSendOneHome", [first]));
    } else {
      if book.reqCallOne == m.id {
        this.SetAction(CBTf(n"Cyberbane-Hud-CallingOne", [first]), true, CBT(n"Cyberbane-Hud-HelpTakeBack"));
      } else {
        let oneWhy = CBCrewCallBlocked(sys, game, false, true, m.id);
        this.SetAction(CBTf(n"Cyberbane-Hud-OneNeedYouNow", [first]), StrLen(oneWhy) == 0, CBTf(n"Cyberbane-Hud-HelpCallOne", [first]));
      }
    }
    this.SetExtra(1, CBTf(n"Cyberbane-Hud-OrdersFor", [first]), true, CBTf(n"Cyberbane-Hud-HelpOrders", [first]));
  }

  // One member's orders, a row each, carried out back in the game. One asked for says so, and clicked again before then
  // is taken back.
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
      this.CrewOrderRow(0, CBCrewAskTakeBack(), asked ? CBT(n"Cyberbane-Hud-HandingItBack") : CBT(n"Cyberbane-Hud-TakeYourWeaponBack"), free || asked, asked,
                        CBCrewItemName(ItemID.GetTDBID(k.weapon)), StrUpper(CBCrewTierWord(k.weaponTier)));
    } else {
      asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskGive());
      this.CrewOrderRow(0, CBCrewAskGive(), asked ? CBT(n"Cyberbane-Hud-AWeaponOnItsWay") : CBT(n"Cyberbane-Hud-GiveThemAWeapon"), free || asked, asked,
                        CBT(n"Cyberbane-Hud-NothingOfYours"), "");
    }
    // Chrome.
    let chrome = IsDefined(k) ? k.ChromeCount() : 0;
    let room = chrome < CBCrewChromeSlots();
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskChrome());
    this.CrewOrderRow(1, CBCrewAskChrome(), asked ? CBT(n"Cyberbane-Hud-ChromeOnItsWay") : (room ? CBT(n"Cyberbane-Hud-HaveChromePutIn") : CBT(n"Cyberbane-Hud-NoRoomForMoreChrome")),
                      (free && room) || asked, asked, CBTf(n"Cyberbane-Hud-OfFitted", [s"\(chrome)", s"\(CBCrewChromeSlots())"]), "");
    // Training.
    let trained = IsDefined(k) ? k.trained : 0;
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskTrain());
    if trained >= CBConfig.CrewTrainMax() {
      this.CrewOrderRow(2, CBCrewAskTrain(), CBT(n"Cyberbane-Hud-FullyTrained"), false, false, CBTf(n"Cyberbane-Hud-OfDone", [s"\(trained)", s"\(CBConfig.CrewTrainMax())"]), "");
    } else {
      let cost = CBCrewTrainCost(k);
      this.CrewOrderRow(2, CBCrewAskTrain(), asked ? CBT(n"Cyberbane-Hud-OffToTrain") : CBT(n"Cyberbane-Hud-SendThemToTrain"),
                        (free && !hurt && CBHudEddies(game) >= cost) || asked, asked,
                        hurt ? CBT(n"Cyberbane-Hud-HurtNotYet") : CBTf(n"Cyberbane-Hud-AwayHours", [s"\(RoundF(CBCrewTrainHours(k)))"]), CBTf(n"Cyberbane-Hud-EB", [s"\(cost)"]));
    }
    // A war, from Lieutenant up.
    let rank = CBCrewRankOf(game, m);
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskWar());
    if rank < CBConfig.CrewWarMinRank() {
      this.CrewOrderRow(3, CBCrewAskWar(), CBT(n"Cyberbane-Hud-SendThemToStartAWar"), false, false,
                        CBTf(n"Cyberbane-Hud-Needs", [s"\(CBCrewRankWord(CBConfig.CrewWarMinRank()))"]), "");
    } else {
      this.CrewOrderRow(3, CBCrewAskWar(), asked ? CBT(n"Cyberbane-Hud-OffToWar") : CBT(n"Cyberbane-Hud-SendThemToStartAWar"), (free && !hurt) || asked, asked,
                        hurt ? CBT(n"Cyberbane-Hud-HurtNotYet") : CBTf(n"Cyberbane-Hud-AwayHours", [s"\(RoundF(CBConfig.CrewWarHours()))"]), "");
    }
    // A spar.
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskSpar());
    if IsDefined(kb) && kb.sparMember == m.id {
      this.CrewOrderRow(4, CBCrewAskSpar(), CBT(n"Cyberbane-Hud-SparringNow"), false, false, "", "");
    } else {
      let sparWhy = asked ? "" : CBCrewSparBlocked(sys, game, m, now);
      this.CrewOrderRow(4, CBCrewAskSpar(), asked ? CBT(n"Cyberbane-Hud-ComingToSpar") : CBT(n"Cyberbane-Hud-SparWithThem"), StrLen(sparWhy) == 0, asked, sparWhy, "");
    }
    // Work: earning, recruiting, or none.
    let work = CBCrewWorkOf(game, m.id);
    let next = CBCrewNextWork(game, m.id);
    asked = IsDefined(kb) && kb.Asked(m.id, CBCrewAskWork());
    let workLabel = CBT(n"Cyberbane-Hud-StopTheirWork");
    if next == 1 { workLabel = CBT(n"Cyberbane-Hud-PutThemToWorkEarning"); }
    if next == 2 { workLabel = CBT(n"Cyberbane-Hud-PutThemToRecruiting"); }
    if next == 3 { workLabel = CBT(n"Cyberbane-CrewHome-PutThemOnWatch"); }
    if next == 4 { workLabel = CBT(n"Cyberbane-CrewJobs-PutThemOnTheMoney"); }
    this.CrewOrderRow(5, CBCrewAskWork(), asked ? CBT(n"Cyberbane-Hud-TellingThem") : workLabel, free || asked, asked,
                      CBTf(n"Cyberbane-Hud-Now", [s"\(CBCrewWorkWord(work))"]), work == 1 ? CBTf(n"Cyberbane-Hud-EBADAY", [s"\(CBConfig.CrewEarnPerRank() * rank)"]) : "");
    // A job: a Rival's hit or a gang's bag, from Soldier up.
    let onJob = CBCrewJobAway(game, m.id, now);
    if !CBCrewJobsOn() {
      this.CrewOrderRow(6, CBCrewAskJob(), CBT(n"Cyberbane-CrewJobs-SendThemOnAJob"), false, false, CBT(n"Cyberbane-CrewJobs-JobsOff"), "");
    } else {
      if onJob {
        this.CrewOrderRow(6, CBCrewAskJob(), CBT(n"Cyberbane-CrewJobs-OnAJob"), false, false,
                          CBTf(n"Cyberbane-Hud-AwayHours", [s"\(CBCrewJobHoursLeft(game, m.id, now))"]), "");
      } else {
        if rank < CBConfig.CrewBagMinRank() {
          this.CrewOrderRow(6, CBCrewAskJob(), CBT(n"Cyberbane-CrewJobs-SendThemOnAJob"), false, false,
                            CBTf(n"Cyberbane-Hud-Needs", [s"\(CBCrewRankWord(CBConfig.CrewBagMinRank()))"]), "");
        } else {
          this.CrewOrderRow(6, CBCrewAskJob(), CBT(n"Cyberbane-CrewJobs-SendThemOnAJob"), free && !hurt, false,
                            hurt ? CBT(n"Cyberbane-Hud-HurtNotYet") : CBT(n"Cyberbane-CrewJobs-AHitOrABag"), "");
        }
      }
    }
    // Letting them go, asked twice.
    if book.reqLetGo == m.id {
      this.CrewOrderRow(7, CBHudCrewOrderLetGo(), CBT(n"Cyberbane-Hud-KeepThem"), true, true, CBT(n"Cyberbane-Hud-LeavingYourCrew"), "");
    } else {
      // A veteran retires alive (Reactions/CrewGang.reds); anybody newer is let go.
      let retires = CBCrewRankOf(game, m) >= CBConfig.CrewRetireMinRank();
      let goLabel = retires ? (this.m_letGoArmed == m.id ? CBT(n"Cyberbane-HubWar-ClickAgainRetire") : CBT(n"Cyberbane-HubWar-LetThemRetire"))
                            : (this.m_letGoArmed == m.id ? CBT(n"Cyberbane-Hud-ClickAgainToLetGo") : CBT(n"Cyberbane-Hud-LetThemGo"));
      this.CrewOrderRow(7, CBHudCrewOrderLetGo(), goLabel, !out, false, out ? CBT(n"Cyberbane-Hud-WithYouWait") : "", "");
      if retires {
        this.SetRowHelp(7, CBT(n"Cyberbane-HubWar-HelpRetire"));
      }
    }
    // Called or sent home on their own: the crew page's first button with them picked, so not a row here as well. A
    // name of V's choosing.
    let given = CBCrewGivenNameOf(m.id);
    this.CrewOrderRow(8, CBHudCrewOrderRename(), CBT(n"Cyberbane-Hud-RenameThem"), true, false,
                      StrLen(given) > 0 ? given : CBT(n"Cyberbane-Hud-TheNameTheyCameWith"), "");
    // Their ask, answered here when it is one the Hub answers (a day off, a cut); else V's second.
    let lbOrd = CBCrewLifeBook.Get(game);
    let askHere = IsDefined(lbOrd) && lbOrd.AskId() == m.id && CBAskByText(lbOrd.AskKind());
    if askHere {
      let askKind = lbOrd.AskKind();
      let paid = askKind == CBAskCut() || askKind == CBAskRipper();
      let askLabel = CBT(n"Cyberbane-Hud-GiveThemTheDayOff");
      if askKind == CBAskCut() { askLabel = CBTf(n"Cyberbane-Hud-PayTheirCut", [s"\(lbOrd.AskValue())"]); }
      if askKind == CBAskRipper() { askLabel = CBTf(n"Cyberbane-GangWar-HubSendToRipper", [s"\(lbOrd.AskValue())"]); }
      this.CrewOrderRow(9, CBHudCrewOrderAsk(), askLabel, paid ? CBHudEddies(game) >= lbOrd.AskValue() : !out, false,
                        CBT(n"Cyberbane-Hud-TheyAskedForIt"), "");
      let askHelp = CBT(n"Cyberbane-Hud-HelpDayOff");
      if askKind == CBAskCut() { askHelp = CBT(n"Cyberbane-Hud-HelpPayCut"); }
      if askKind == CBAskRipper() { askHelp = CBT(n"Cyberbane-GangWar-HubHelpRipper"); }
      this.SetRowHelp(9, askHelp);
    } else {
      let second = CBCrewIsSecond(game, m.id);
      this.CrewOrderRow(9, CBHudCrewOrderSecond(), second ? CBT(n"Cyberbane-Hud-StepDownAsSecond") : CBT(n"Cyberbane-Hud-MakeThemYourSecond"), true, second,
                        second ? CBT(n"Cyberbane-Hud-YourSecondNow") : "", "");
      this.SetRowHelp(9, CBT(n"Cyberbane-Hud-HelpSecond"));
    }
    this.SetRowHelp(0, IsDefined(k) && k.hasWeapon ? CBT(n"Cyberbane-Hud-HelpTakeBackWeapon") : CBT(n"Cyberbane-Hud-HelpGiveWeapon"));
    this.SetRowHelp(1, CBT(n"Cyberbane-Hud-HelpChrome"));
    this.SetRowHelp(2, CBT(n"Cyberbane-Hud-HelpTrain"));
    this.SetRowHelp(3, CBT(n"Cyberbane-Hud-HelpWar"));
    this.SetRowHelp(4, CBT(n"Cyberbane-Hud-HelpSpar"));
    this.SetRowHelp(5, CBT(n"Cyberbane-Hud-HelpWork"));
    this.SetRowHelp(6, CBT(n"Cyberbane-Hud-HelpJob"));
    this.SetRowHelp(7, CBT(n"Cyberbane-Hud-HelpLetGo"));
    this.SetRowHelp(8, CBT(n"Cyberbane-Hud-HelpRename"));
    let text = CBT(n"Cyberbane-Hud-OrdersShort");
    if out {
      text = CBTf(n"Cyberbane-Hud-WithYouNowOrdersWaitUntil", [text]);
    }
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + 10.0 * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  // A job's targets: the Rivals V knows that the crew can go after, from Veteran up, then the gangs whose bags they can
  // take, with the odds each.
  private func RenderCrewJobs(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    ArrayClear(this.m_pickJobRival);
    ArrayClear(this.m_pickJobGang);
    let now = CBGameSeconds(game);
    let rank = CBCrewRankOf(game, m);
    // Every target first, then a window of them: the list stopped at the first ten rows.
    if rank >= CBConfig.CrewHitMinRank() {
      for r in sys.GetRivals() {
        if CBCrewHitTarget(sys, game, r) {
          ArrayPush(this.m_pickJobRival, r.id);
          ArrayPush(this.m_pickJobGang, r.faction);
        }
      }
    }
    for g in CBCrewBagTargets(sys) {
      ArrayPush(this.m_pickJobRival, 0);
      ArrayPush(this.m_pickJobGang, g);
    }
    let total = Min(ArraySize(this.m_pickJobRival), ArraySize(this.m_pickJobGang));
    let row = 0;
    let i = this.ListWindow(total, CBHudListRows());
    while i < total && row < CBHudListRows() {
      let rid = this.m_pickJobRival[i];
      let r = rid > 0 ? sys.FindRivalById(rid) : null;
      if IsDefined(r) {
        let odds = CBCrewHitOdds(game, m, r, now);
        this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBRivalDisplayName(sys.GetContent(), r),
                    CBT(n"Cyberbane-CrewJobs-AHit"), "", CBTf(n"Cyberbane-Hud-AwayHours", [s"\(RoundF(CBConfig.CrewHitHoursBase() + 2.0 * Cast<Float>(r.rank)))"]),
                    "", s"\(RoundF(odds * 100.0))%");
      } else {
        let g = this.m_pickJobGang[i];
        let oddsBag = CBCrewBagOdds(sys, game, m, g, now);
        this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBCapFirst(CBFactionLabel(g)),
                    CBT(n"Cyberbane-CrewJobs-TheirBag"), "", CBTf(n"Cyberbane-Hud-AwayHours", [s"\(RoundF(CBConfig.CrewBagHours()))"]),
                    "", s"\(RoundF(oddsBag * 100.0))%");
      }
      this.m_rowCrew[row] = i + 1;
      row += 1;
      i += 1;
    }
    let intro = total == 0 ? CBT(n"Cyberbane-CrewJobs-NoTargets")
                           : CBTf(n"Cyberbane-CrewJobs-PickAJob", [CBCrewName(sys, m), CBCrewRankWord(CBConfig.CrewHitMinRank())]);
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, intro, CBHudMaxLinesFor(this.m_tab));
  }

  // Who answers a challenge: anybody here and not hurt, with the odds each.
  private func RenderCrewDuel(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    ArrayClear(this.m_pickDuel);
    let jb = CBCrewJobBook.Get(game);
    let gang = IsDefined(jb) ? jb.ChallengeGang() : n"";
    let now = CBGameSeconds(game);
    let row = 0;
    let i = 0;
    while i < book.Count() && row < CBHudListRows() && NotEquals(gang, n"") {
      let m = book.At(i);
      i += 1;
      if IsDefined(m) && !book.IsOut(m.id) && !CBCrewHurt(m, now) && !CBCrewAway(game, m.id, now) && !CBGuardPosted(game, m.id) {
        let odds = CBCrewDuelOdds(sys, game, m, gang, now);
        this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBCrewName(sys, m), CBCrewRankWord(CBCrewRankOf(game, m)), "", "",
                    "", s"\(RoundF(odds * 100.0))%");
        ArrayPush(this.m_pickDuel, m.id);
        this.m_rowCrew[row] = row + 1;
        row += 1;
      }
    }
    let intro = Equals(gang, n"") ? CBT(n"Cyberbane-CrewJobs-NoChallenge")
                                  : (row == 0 ? CBT(n"Cyberbane-CrewJobs-NobodyToSend") : CBTf(n"Cyberbane-CrewJobs-PickForTheChallenge", [CBFactionLabel(gang)]));
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, intro, CBHudMaxLinesFor(this.m_tab));
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
    if code == CBCrewAskGive() || code == CBCrewAskChrome() || code == CBCrewAskWar() || code == CBCrewAskJob() {
      this.m_listTop = 0;   // a pick list opens at its top
    }
    if code == CBCrewAskGive() { this.m_crewMode = 1; }
    if code == CBCrewAskChrome() { this.m_crewMode = 2; }
    if code == CBCrewAskJob() { this.m_crewMode = 8; }
    // A war: the same two screens as the crew page's Go to war, with them already in the party. It had a list of gangs
    // of its own, with other columns, that went to the same party screen.
    if code == CBCrewAskWar() {
      let wbGo = CBWarFrontBook.Get(game);
      if IsDefined(wbGo) {
        ArrayClear(wbGo.pickParty);
        ArrayPush(wbGo.pickParty, id);
        if wbGo.Count() > 0 {
          this.m_pickWar = wbGo.At(0).gang;
          this.m_pickWarRow = 0;
          this.m_crewMode = 21;
        } else {
          this.m_crewMode = 12;
        }
      }
      return;
    }
    if code == CBCrewAskTakeBack() || code == CBCrewAskTrain() || code == CBCrewAskSpar() || code == CBCrewAskWork() {
      kb.Ask(id, code, noItem, n"");
      CBCrewKitDoNow(CyberbaneSystem.Get(game), game);   // all but a spar, here and now
    }
    // Only words and books: V's second named or stood down, an ask answered, here and now.
    if code == CBHudCrewOrderSecond() || code == CBHudCrewOrderAsk() {
      let sysO = CyberbaneSystem.Get(game);
      let mo = cb.Find(id);
      let lbO = CBCrewLifeBook.Get(game);
      if IsDefined(mo) && IsDefined(lbO) {
        kb.deferTexts = true;
        if code == CBHudCrewOrderSecond() {
          CBCrewMakeSecond(sysO, game, mo);
        } else {
          CBCrewAnswerAsk(sysO, game, mo, true, false);
        }
        kb.deferTexts = false;
      }
      return;
    }
    if code == CBHudCrewOrderRename() {
      let given = CBCrewGivenNameOf(id);
      let mm = cb.Find(id);
      let own = IsDefined(mm) ? CBCrewFullNameNicked(CyberbaneSystem.Get(game), mm.kind, mm.faction, mm.rival, mm.seed, false, mm.seat) : "";
      this.SeedNameInput(StrLen(given) > 0 ? given : own, CBT(n"Cyberbane-Hud-ANameForThem"));
      this.m_crewMode = 10;
      return;
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

  // The crew itself: its name, its colours, the memorial, and its own standing with each gang, worst first. Going to
  // war, first: the gangs the crew can go to war on, each with what it weighs.
  private func RenderWarTargets(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    this.m_pickGangs = CBCrewWarTargets(sys);
    let row = 0;
    let g = this.ListWindow(ArraySize(this.m_pickGangs), CBHudListRows());
    while g < ArraySize(this.m_pickGangs) && row < CBHudListRows() {
      let gang = this.m_pickGangs[g];
      this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBCapFirst(CBFactionLabel(gang)),
                  CBGangStrengthWord(CBGangStrength(sys, gang)), "", CBTf(n"Cyberbane-CrewWar-TheyWeigh", [s"\(RoundF(CBGangWarPower(sys, game, gang)))"]), "", "");
      this.m_rowCrew[row] = g + 1;
      row += 1;
      g += 1;
    }
    let intro = row > 0 ? CBT(n"Cyberbane-HubWar-PickAGang") : CBT(n"Cyberbane-Hud-NoGangToGoToWar");
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, intro, CBHudMaxLinesFor(this.m_tab));
  }

  // ---- The War view ----

  // The crew's wars, the crew taken alive, their people the crew holds; the picked one's night below.
  private func RenderWarView(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    let fb = CBWarFrontBook.Get(game);
    if IsDefined(fb) && ((this.m_pickWarRow >= 100 && this.m_pickWarRow < 200 && !IsDefined(fb.CaptiveAt(this.m_pickWarRow - 101)))
                         || (this.m_pickWarRow >= 200 && this.m_pickWarRow - 201 >= fb.PrisonCount())) {
      this.m_pickWarRow = 0;
    }
    let row = 0;
    let now = CBGameSeconds(game);
    if IsDefined(fb) {
      let i = 0;
      while i < fb.Count() && row < CBHudListRows() {
        let f = fb.At(i);
        i += 1;
        if IsDefined(f) {
          let state = CBHubWarStateWord(f);
          let picked = this.m_pickWarRow == 0 && Equals(this.m_pickWar, f.gang);
          this.SetRow(row, CBHudLayoutCrew(), f.front >= 0.0 ? CBHudCyan() : CBHudRed(), true, picked, CBCapFirst(CBWarName(f)),
                      StrUpper(CBWarFrontWord(f.front)), "", StrLen(state) > 0 ? state : CBWarOrderWord(f.order), "",
                      CBTf(n"Cyberbane-HubWar-DayN", [s"\(f.nights + 1)"]));
          this.SetRowBar(row, CBHudCrewBarX(), CBHudCrewBarW(), ClampF(f.front / 100.0, -1.0, 1.0), f.front >= 0.0 ? CBHudCyan() : CBHudRed(), true);
          this.m_rowCrew[row] = i;
          row += 1;
        }
      }
      let c = 0;
      while c < fb.CaptiveCount() && row < CBHudListRows() {
        let cap = fb.CaptiveAt(c);
        c += 1;
        if IsDefined(cap) {
          this.SetRow(row, CBHudLayoutCrew(), CBHudAmber(), true, this.m_pickWarRow == 100 + c, CBWarCaptiveName(sys, game, cap),
                      CBT(n"Cyberbane-HubWar-HELD"), "", CBTf(n"Cyberbane-HubWar-ByGang", [CBFactionLabel(cap.gang)]), "",
                      CBTf(n"Cyberbane-Hud-EB", [s"\(cap.price)"]));
          this.m_rowCrew[row] = 100 + c;
          row += 1;
        }
      }
      let p = 0;
      while p < fb.PrisonCount() && row < CBHudListRows() {
        let r = sys.FindRivalById(fb.PrisonRival(p));
        p += 1;
        if IsDefined(r) {
          this.SetRow(row, CBHudLayoutCrew(), CBHudGreen(), true, this.m_pickWarRow == 200 + p, CBRivalDisplayName(sys.GetContent(), r),
                      CBT(n"Cyberbane-HubWar-YOURS"), "", CBTf(n"Cyberbane-HubWar-OfGang", [CBFactionLabel(fb.PrisonGang(p - 1))]), "", "");
          this.m_rowCrew[row] = 200 + p;
          row += 1;
        }
      }
    }
    // The pick: a war still on, or the first.
    let f = IsDefined(fb) && this.m_pickWarRow == 0 ? fb.Find(this.m_pickWar) : null;
    if this.m_pickWarRow == 0 && !IsDefined(f) && IsDefined(fb) && fb.Count() > 0 {
      f = fb.At(0);
      this.m_pickWar = f.gang;
    }
    let text = "";
    let canWar = IsDefined(fb) && fb.Count() < CBCrewWarsAtOnce(game) && book.Count() > 0;
    if this.m_pickWarRow >= 100 && this.m_pickWarRow < 200 {
      let cap = IsDefined(fb) ? fb.CaptiveAt(this.m_pickWarRow - 101) : null;
      if IsDefined(cap) {
        let name = CBWarCaptiveName(sys, game, cap);
        let left = Max(1, CeilF((CBWarCaptiveDeadline(game, cap) - now) / CBConfig.SecondsPerHour()));
        text = CBTf(n"Cyberbane-HubWar-CaptiveFile", [name, CBFactionLabel(cap.gang), s"\(cap.price)", s"\(left)"]);
        this.SetAction(CBTf(n"Cyberbane-HubWar-PayRansom", [s"\(cap.price)"]), CBHudEddies(game) >= cap.price, CBT(n"Cyberbane-HubWar-HelpPayRansom"));
        if fb.PrisonerOf(cap.gang) >= 0 {
          this.SetExtra(1, CBT(n"Cyberbane-HubWar-TradeForThem"), true, CBT(n"Cyberbane-HubWar-HelpTrade"));
        }
        this.SetExtra(2, cap.rescue ? CBT(n"Cyberbane-HubWar-OnYourWay") : CBT(n"Cyberbane-HubWar-GoGetThem"), !cap.rescue, CBT(n"Cyberbane-HubWar-HelpRescue"));
      }
    } else {
      if this.m_pickWarRow >= 200 {
        let pi = this.m_pickWarRow - 201;
        let r = IsDefined(fb) ? sys.FindRivalById(fb.PrisonRival(pi)) : null;
        if IsDefined(r) {
          text = CBTf(n"Cyberbane-HubWar-PrisonerFile", [CBRivalDisplayName(sys.GetContent(), r), CBFactionLabel(fb.PrisonGang(pi))]);
          this.SetAction(CBT(n"Cyberbane-HubWar-SellBack"), true, CBT(n"Cyberbane-HubWar-HelpSellBack"));
          this.SetExtra(1, CBT(n"Cyberbane-HubWar-TurnThem"), true, CBT(n"Cyberbane-HubWar-HelpTurn"));
        }
      } else {
        if IsDefined(f) {
          text = CBHubWarFile(sys, game, f);
          let canOrder = CBWarCanOrder(game, f);
          let orderLabel = CBT(n"Cyberbane-HubWar-GiveOrder");
          if f.order != CBWarOrderNone() {
            orderLabel = canOrder ? CBT(n"Cyberbane-HubWar-ChangeOrder") : CBT(n"Cyberbane-HubWar-FightUnderWay");
          } else {
            if !canOrder {
              orderLabel = CBTf(n"Cyberbane-HubWar-ReadyAt", [CBClockWord(f.orderAt)]);
            }
          }
          this.SetAction(orderLabel, canOrder, CBT(n"Cyberbane-HubWar-HelpOrder"));
          let termsLabel = CBT(n"Cyberbane-HubWar-EndThisWar");
          if f.state == CBWarStateTheyAsk() { termsLabel = CBT(n"Cyberbane-HubWar-TheyAskTerms"); }
          if f.state == CBWarStateTheyDemand() { termsLabel = CBT(n"Cyberbane-HubWar-TheyDemandTerms"); }
          this.SetExtra(1, termsLabel, true, CBT(n"Cyberbane-HubWar-HelpTerms"));
          let friend = CBWarAskableFriend(sys, game, f);
          if IsNameValid(friend) {
            this.SetExtra(2, CBTf(n"Cyberbane-HubWar-AskIn", [CBCapFirst(CBFactionLabel(friend))]), true, CBT(n"Cyberbane-HubWar-HelpAskIn"));
          }
        } else {
          text = CBT(n"Cyberbane-HubWar-NoWar");
          this.SetAction(CBT(n"Cyberbane-CrewWar-GoToWar"), canWar, CBT(n"Cyberbane-HubWar-HelpGoToWar"));
        }
        if IsDefined(fb) && fb.PastCount() > 0 {
          text += "\n\n" + CBHubWarPastLines(sys, game, fb);
        }
      }
    }
    if IsDefined(f) && this.m_pickWarRow == 0 && canWar {
      this.SetExtra(3, CBT(n"Cyberbane-CrewWar-GoToWar"), true, CBT(n"Cyberbane-HubWar-HelpGoToWar"));
    }
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  // Tonight's orders for the picked war, each with what they put up against it.
  private func RenderWarOrders(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    let f = CBGangWarFront(game, this.m_pickWar);
    if !IsDefined(f) {
      this.m_crewMode = 20;
      return;
    }
    let offered = CBWarOrdersOffered(sys, game, f);
    let theirs = CBGangWarWeight(sys, game, f.gang);
    let row = 0;
    for order in offered {
      if row < CBHudListRows() {
        let meets = CBWarOrderMeets(order);
        this.SetRow(row, CBHudLayoutCrew(), order == f.order ? CBHudCyan() : CBHudLabel(), true, order == f.order, CBWarOrderWord(order), "", "",
                    meets > 0.0 ? CBTf(n"Cyberbane-HubWar-TheyPutUp", [s"\(RoundF(theirs * meets))"]) : CBT(n"Cyberbane-HubWar-NoFight"), "", "");
        this.SetRowHelp(row, CBWarOrderHelp(order));
        this.m_rowCrew[row] = order;
        row += 1;
      }
    }
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0,
                 CBTf(n"Cyberbane-HubWar-OrdersIntro", [CBFactionLabel(f.gang)]), CBHudMaxLinesFor(this.m_tab));
  }

  // Terms: what the crew can take, or what they ask of it; refusing; or calling the war off.
  private func RenderWarTerms(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    let f = CBGangWarFront(game, this.m_pickWar);
    if !IsDefined(f) {
      this.m_crewMode = 20;
      return;
    }
    let row = 0;
    let intro = CBT(n"Cyberbane-HubWar-TermsNone");
    if f.state == CBWarStateTheyAsk() {
      intro = CBT(n"Cyberbane-HubWar-TermsAskIntro");
      let offered = CBWarTermsOffered(sys, game, f);
      for t in offered {
        this.SetRow(row, CBHudLayoutCrew(), CBHudCyan(), true, false, CBCapFirst(CBWarTermsWord(sys, game, f, t)), "", "", CBT(n"Cyberbane-HubWar-TakeThese"), "", "");
        this.m_rowCrew[row] = t;
        row += 1;
      }
      this.SetRow(row, CBHudLayoutCrew(), CBHudRed(), true, false, CBT(n"Cyberbane-HubWar-RefuseToTheEnd"), "", "", CBT(n"Cyberbane-HubWar-StormTheirBoss"), "", "");
      this.m_rowCrew[row] = 90;
      row += 1;
    }
    if f.state == CBWarStateTheyDemand() {
      intro = CBT(n"Cyberbane-HubWar-TermsDemandIntro");
      this.SetRow(row, CBHudLayoutCrew(), CBHudAmber(), true, false, CBTf(n"Cyberbane-HubWar-GiveIn", [CBWarTermsWord(sys, game, f, f.terms)]), "", "", CBT(n"Cyberbane-HubWar-WarEnds"), "", "");
      this.m_rowCrew[row] = 80;
      row += 1;
      this.SetRow(row, CBHudLayoutCrew(), CBHudRed(), true, false, CBT(n"Cyberbane-HubWar-Refuse"), "", "", CBT(n"Cyberbane-HubWar-FightOn"), "", "");
      this.m_rowCrew[row] = 81;
      row += 1;
    }
    this.SetRow(row, CBHudLayoutCrew(), CBHudDim(), true, this.m_callOffArmed,
                this.m_callOffArmed ? CBT(n"Cyberbane-HubWar-ClickAgainCallOff") : CBT(n"Cyberbane-HubWar-CallOff"), "", "", CBT(n"Cyberbane-HubWar-TheyRemember"), "", "");
    this.m_rowCrew[row] = 91;
    row += 1;
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, intro, CBHudMaxLinesFor(this.m_tab));
  }

  // ---- The Squads view ----

  private func RenderSquads(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    let sb = CBSquadBook.Get(game);
    let row = 0;
    let war = CBCrewAnyWar(game);
    if IsDefined(sb) {
      let i = this.ListWindow(sb.Count(), CBHudListRows());
      while i < sb.Count() && row < CBHudListRows() {
        let s = sb.At(i);
        i += 1;
        if IsDefined(s) {
          let job = war ? CBT(n"Cyberbane-HubWar-InTheWar") : CBSquadStandingWord(s.kind, s.standing);
          this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, this.m_pickSquad == s.leader, CBSquadName(sys, game, s), StrUpper(CBSquadKindWord(s.kind)),
                      s"\(s.heads)/\(CBSquadMax(game, s))", job, "", StrUpper(CBSquadSkillWord(s.skill)));
          this.SetRowHelp(row, CBSquadKindHelp(s.kind));
          this.m_rowCrew[row] = s.leader;
          row += 1;
        }
      }
    }
    let s = IsDefined(sb) ? sb.Of(this.m_pickSquad) : null;
    if !IsDefined(s) && IsDefined(sb) && sb.Count() > 0 {
      s = sb.At(0);
      this.m_pickSquad = s.leader;
    }
    let text = "";
    if IsDefined(s) {
      let leader = book.Find(s.leader);
      text = CBTf(n"Cyberbane-HubWar-SquadFile", [CBSquadName(sys, game, s), CBSquadKindWord(s.kind), CBSquadLine(sys, game, s), s"\(s.jobs)", s"\(s.lost)"]);
      text += "\n" + CBSquadKindHelp(s.kind);
      if !IsDefined(leader) {
        text += "\n" + CBT(n"Cyberbane-HubWar-SquadLeaderless");
      }
      let wage = CBSquadWage(s);
      text += "\n" + (wage > 0 ? CBTf(n"Cyberbane-HubWar-SquadWage", [s"\(wage)", s"\(CBSquadWagesWeek(game))"]) : CBT(n"Cyberbane-HubWar-SquadPaysItsWay"));
      this.SetAction(CBTf(n"Cyberbane-HubWar-BetweenWars", [CBSquadStandingWord(s.kind, s.standing)]), true, CBT(n"Cyberbane-HubWar-HelpStanding"));
      let next = s.kind % 6 + 1;
      this.SetExtra(1, CBTf(n"Cyberbane-HubWar-MakeThem", [CBSquadKindWord(next)]), s.heads <= CBConfig.SquadChangeMaxHeads(), CBT(n"Cyberbane-HubWar-HelpChangeKind"));
      this.SetExtra(2, CBT(n"Cyberbane-HubWar-RenameSquad"), true, CBT(n"Cyberbane-HubWar-HelpRenameSquad"));
      if !IsDefined(leader) {
        let cand = this.HandCandidate(game, book, sb);
        let candM = book.Find(cand);
        this.SetExtra(3, IsDefined(candM) ? CBTf(n"Cyberbane-HubWar-HandTo", [CBCrewFirst(sys, candM)]) : CBT(n"Cyberbane-HubWar-NobodyToLead"),
                      IsDefined(candM), CBT(n"Cyberbane-HubWar-HelpHandTo"));
      } else {
        this.SetExtra(3, s.noRecruit ? CBT(n"Cyberbane-HubWar-TakePeople") : CBT(n"Cyberbane-HubWar-StopTaking"), true, CBT(n"Cyberbane-HubWar-HelpRecruit"));
      }
    } else {
      text = CBTf(n"Cyberbane-HubWar-NoSquads", [CBCrewRankWord(CBConfig.CrewWarMinRank())]);
    }
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  // A Lieutenant or better with no squad of their own, for a squad without a leader: the next after the last offered.
  private func HandCandidate(game: GameInstance, book: ref<CBCrewBook>, sb: ref<CBSquadBook>) -> Int32 {
    let first = 0;
    let after = 0;
    let i = 0;
    while i < book.Count() {
      let m = book.At(i);
      i += 1;
      if IsDefined(m) && CBSquadMaxHeads(CBCrewRankOf(game, m)) > 0 && !IsDefined(sb.Of(m.id)) {
        if first == 0 { first = m.id; }
        if after == 0 && m.id > this.m_handTo { after = m.id; }
      }
    }
    return after > 0 ? after : first;
  }

  // ---- The crew's places, and what the kitty buys ----

  private func RenderRunners(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    let held = CBCrewHeldDistricts(sys, game);
    let gb = CBCrewGangBook.Get(game);
    let row = 0;
    let k = 0;
    while k < ArraySize(held) && row < CBHudListRows() {
      let d = held[k];
      k += 1;
      let m = CBRunnerOf(game, d);
      this.SetRow(row, CBHudLayoutCrew(), IsDefined(m) ? CBHudCyan() : CBHudAmber(), true, false, CBDistrictLabel(d),
                  IsDefined(m) ? CBCrewFirst(sys, m) : CBT(n"Cyberbane-HubWar-Nobody"), "", CBT(n"Cyberbane-Hud-ClickForTheNext"), "", "");
      this.SetRowHelp(row, CBT(n"Cyberbane-HubWar-HelpRunner"));
      this.m_rowCrew[row] = k;
      row += 1;
    }
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0,
                 row > 0 ? CBTf(n"Cyberbane-HubWar-RunnersIntro", [CBCrewRankWord(CBConfig.CrewWarMinRank())]) : CBT(n"Cyberbane-HubWar-NoStreetsYet"),
                 CBHudMaxLinesFor(this.m_tab));
  }

  private func RenderCrewPlace(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    let choices = CBCrewPlaceChoices(sys, game);
    let bases = CBBaseBook.Get(game);
    let gb = CBCrewGangBook.Get(game);
    let here: Vector4;
    let has = CBCrewPlaceAt(game, here);
    let row = 0;
    for idx in choices {
      if row < CBHudListRows() && IsDefined(bases) {
        let at = bases.BaseAt(idx);
        let ours = has && Vector4.Distance(at, here) < 5.0;
        this.SetRow(row, CBHudLayoutCrew(), ours ? CBHudCyan() : CBHudLabel(), !ours, ours, CBBaseName(game, bases.BaseHashAt(idx)),
                    CBDistrictLabel(bases.BaseDistrictAt(idx)), "", ours ? CBT(n"Cyberbane-HubWar-OurPlace") : CBT(n"Cyberbane-HubWar-MakeItOurs"), "", "");
        this.m_rowCrew[row] = idx + 1;
        row += 1;
      }
    }
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0,
                 row > 0 ? CBT(n"Cyberbane-HubWar-PlaceIntro") : CBT(n"Cyberbane-HubWar-NoPlaceYet"), CBHudMaxLinesFor(this.m_tab));
  }

  private func RenderUpgrades(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    this.PlaceRows(CBHudLayoutCrew());
    let jb = CBCrewJobBook.Get(game);
    let kitty = IsDefined(jb) ? jb.Kitty() : 0;
    let wages = CBSquadWagesWeek(game);
    let bits: array<Int32> = [1, 2, 4, 8];
    let row = 0;
    for bit in bits {
      let have = CBCrewHas(game, bit);
      let price = CBUpgradePrice(bit);
      let can = !have && kitty - wages >= price;
      this.SetRow(row, CBHudLayoutCrew(), have ? CBHudGreen() : (can ? CBHudLabel() : CBHudDim()), can, have, CBUpgradeWord(bit), "", "",
                  have ? CBT(n"Cyberbane-HubWar-Bought") : CBTf(n"Cyberbane-Hud-EB", [s"\(price)"]), "", "");
      this.SetRowHelp(row, CBUpgradeHelp(bit));
      this.m_rowCrew[row] = bit;
      row += 1;
    }
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0,
                 CBTf(n"Cyberbane-HubWar-UpgradesIntro", [s"\(kitty)", s"\(wages)"]), CBHudMaxLinesFor(this.m_tab));
  }

  // Then who goes: the roster, each with what they weigh and why anybody cannot go; the two sides weighed, and the
  // odds, before anybody leaves.
  private func RenderWarParty(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
    let wb = CBWarFrontBook.Get(game);
    let f = IsDefined(wb) ? wb.Find(wb.pickGang) : null;
    if !IsDefined(f) || !CBWarOrderFights(wb.pickOrder) {
      this.m_crewMode = 20;
      this.RenderWarView(sys, game, book);
      return;
    }
    this.PlaceRows(CBHudLayoutCrew());
    let gang = wb.pickGang;
    let now = CBGameSeconds(game);
    // Anybody picked who can no longer go is out of it: hurt, sent off, gone.
    let keep: array<Int32>;
    for id in wb.pickParty {
      if CBCrewWarEligible(game, book, book.Find(id), now) {
        ArrayPush(keep, id);
      }
    }
    wb.pickParty = keep;
    let row = 0;
    let i = this.ListWindow(book.Count(), CBHudListRows());
    while i < book.Count() && row < CBHudListRows() {
      let m = book.At(i);
      i += 1;
      if IsDefined(m) {
        let why = CBCrewWarWhyNot(sys, game, book, m, now);
        let going = ArrayContains(wb.pickParty, m.id);
        let can = StrLen(why) == 0;
        this.SetRow(row, CBHudLayoutCrew(), going ? CBHudCyan() : (can ? CBHudLabel() : CBHudDim()), can || going, going,
                    CBCrewName(sys, m), CBCrewSeatWord(m.seat), CBCrewRankShort(game, m),
                    going ? CBT(n"Cyberbane-CrewWar-Going") : (can ? CBT(n"Cyberbane-CrewWar-ClickToSend") : why),
                    "", s"\(RoundF(CBCrewMemberWarPower(game, m)))");
        this.m_rowCrew[row] = m.id;
        row += 1;
      }
    }
    let order = wb.pickOrder;
    let ours = CBWarOurWeight(sys, game, f, order, wb.pickParty);
    let theirs = CBGangWarWeight(sys, game, gang) * CBWarOrderMeets(order);
    let ratio = theirs > 0.0 ? ours / theirs : 0.0;
    let squadsLead = CBSquadsCanLead(game);
    let led = CBCrewWarPartyLed(game, book, wb.pickParty) || squadsLead;
    let n = ArraySize(wb.pickParty);
    let text = CBTf(n"Cyberbane-HubWar-PartyHeader", [CBWarOrderWord(order), CBCapFirst(CBFactionLabel(gang)), s"\(RoundF(theirs))"]);
    text += CBTf(n"Cyberbane-HubWar-PartyOdds", [s"\(RoundF(ours))", CBWarOddsWord(ratio), s"\(RoundF(CBWarWinChance(ratio) * 100.0))"]);
    if !led {
      text += CBTf(n"Cyberbane-CrewWar-PartyNeedsLeader", [CBCrewRankWord(CBConfig.CrewWarMinRank())]);
    }
    if CBSquadCount(game) > 0 {
      text += CBT(n"Cyberbane-HubWar-SquadsGoToo");
    }
    // V leads a led order, so it needs nobody; sent without V, somebody has to lead it.
    let ready = (n > 0 || squadsLead) && led;
    this.SetAction(CBT(n"Cyberbane-HubWar-LeadIt"), true, CBTf(n"Cyberbane-HubWar-HelpLeadIt", [s"\(RoundF(CBConfig.WarLeadHours()))"]));
    let storm = order == CBWarOrderStorm();
    this.SetExtra(1, CBT(n"Cyberbane-HubWar-SendIt"), ready && !storm, storm ? CBT(n"Cyberbane-HubWar-HelpStormLed") : CBT(n"Cyberbane-HubWar-HelpSendIt"));
    this.SetExtra(2, CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  private func RenderCrewRecord(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>) -> Void {
    let bb = CBCrewBannerBook.Get(game);
    let kb = CBCrewKitBook.Get(game);
    this.PlaceRows(CBHudLayoutCrew());
    let name = CBCrewNameOf(game);
    let row = 0;
    // Money first, then the crew's places, then its name, colours and the fallen. The wars have a view of their own.
    // The cut, paid here: it was a button on the roster, which has the calls now. Carried out back in the game.
    let owed = book.CutOwed();
    if owed > 0 || book.reqPay {
      let canPay = book.reqPay || CBHudEddies(game) >= owed;
      this.SetRow(row, CBHudLayoutCrew(), book.reqPay ? CBHudCyan() : (canPay ? CBHudAmber() : CBHudDim()), canPay, book.reqPay,
                  book.reqPay ? CBT(n"Cyberbane-Hud-PayingClickToTakeItBack") : CBTf(n"Cyberbane-Hud-PayTheCutEb", [s"\(owed)"]), "", "",
                  canPay ? CBT(n"Cyberbane-Hud-TheyWaitOnIt") : CBT(n"Cyberbane-Hud-NotEnoughEddies"), "", "");
      this.m_rowCrew[row] = 8;
      row += 1;
    }
    // The kitty: taken at home.
    let jbRec = CBCrewJobBook.Get(game);
    if IsDefined(jbRec) && CBCrewJobsOn() {
      let kitty = jbRec.Kitty();
      let home = CBOnHomeGround(game) || CBAtCrewPlace(game);
      this.SetRow(row, CBHudLayoutCrew(), kitty > 0 && home ? CBHudLabel() : CBHudDim(), kitty > 0 && home, false,
                  CBT(n"Cyberbane-CrewJobs-TakeTheKitty"), "", "",
                  kitty <= 0 ? CBT(n"Cyberbane-CrewJobs-KittyEmpty") : (home ? "" : CBT(n"Cyberbane-CrewJobs-AtHomeOnly")),
                  "", CBTf(n"Cyberbane-Hud-EB", [s"\(kitty)"]));
      this.m_rowCrew[row] = 4;
      row += 1;
      // A challenge waiting for an answer.
      let chGang = jbRec.ChallengeGang();
      if NotEquals(chGang, n"") {
        this.SetRow(row, CBHudLayoutCrew(), CBHudAmber(), true, false, CBTf(n"Cyberbane-CrewJobs-AnswerChallenge", [CBPossessive(CBFactionLabel(chGang))]), "", "",
                    CBTf(n"Cyberbane-CrewJobs-ChallengeHoursLeft", [s"\(Max(1, CeilF((jbRec.ChallengeUntil() - CBGameSeconds(game)) / CBConfig.SecondsPerHour())))"]), "", "");
        this.m_rowCrew[row] = 5;
        row += 1;
        this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBT(n"Cyberbane-CrewJobs-TurnItDown"), "", "",
                    CBT(n"Cyberbane-CrewJobs-TheyWillSayYouAreScared"), "", "");
        this.m_rowCrew[row] = 6;
        row += 1;
      }
    }
    // What the kitty buys, who runs the crew's streets, the crew's own place.
    let bought = 0;
    let ub: array<Int32> = [1, 2, 4, 8];
    for bit in ub {
      if CBCrewHas(game, bit) {
        bought += 1;
      }
    }
    this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBT(n"Cyberbane-HubWar-WhatKittyBuys"), "", "",
                CBTf(n"Cyberbane-HubWar-BoughtOf", [s"\(bought)"]), "", "");
    this.m_rowCrew[row] = 12;
    row += 1;
    let heldList = CBCrewHeldDistricts(sys, game);
    let heldCount = ArraySize(heldList);
    if heldCount > 0 {
      this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBT(n"Cyberbane-HubWar-WhoRunsOurStreets"), "", "",
                  heldCount == 1 ? CBT(n"Cyberbane-HubWar-OneDistrict") : CBTf(n"Cyberbane-HubWar-Districts", [s"\(heldCount)"]), "", "");
      this.m_rowCrew[row] = 10;
      row += 1;
      let placeAt: Vector4;
      this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, CBT(n"Cyberbane-HubWar-OurPlaceRow"), "", "",
                  CBCrewPlaceAt(game, placeAt) ? CBT(n"Cyberbane-HubWar-PlaceSetWord") : CBT(n"Cyberbane-HubWar-PlaceNone"), "", "");
      this.m_rowCrew[row] = 11;
      row += 1;
    }
    // Its name, its colours, the memorial.
    this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), true, false, StrLen(name) > 0 ? CBT(n"Cyberbane-Hud-RenameYourCrew") : CBT(n"Cyberbane-Hud-NameYourCrew"), "", "",
                StrLen(name) > 0 ? name : CBT(n"Cyberbane-Hud-NoNameYet"), "", "");
    this.m_rowCrew[row] = 1;
    row += 1;
    let colour = CBCrewColourIndex(game);
    this.SetRow(row, CBHudLayoutCrew(), CBCrewColourTint(colour), true, false, CBT(n"Cyberbane-Hud-ChangeItsColours"), StrUpper(CBCrewColourWord(colour)), "",
                CBT(n"Cyberbane-Hud-ClickForTheNext"), "", "");
    this.m_rowCrew[row] = 2;
    row += 1;
    // The crew's home: one of V's places, made theirs while V stands in it.
    let lbHome = CBCrewLifeBook.Get(game);
    let atHome = CBOnHomeGround(game);
    if IsDefined(lbHome) && (atHome || lbHome.HomeSet()) && row < CBHudListRows() - 2 {
      let isHere = lbHome.HomeSet() && atHome && Equals(lbHome.HomeDistrict(), sys.GetCurrentDistrict());
      this.SetRow(row, CBHudLayoutCrew(), CBHudLabel(), atHome && !isHere, isHere,
                  lbHome.HomeSet() ? CBT(n"Cyberbane-Hud-CrewHomeMove") : CBT(n"Cyberbane-Hud-CrewHomeSet"), "", "",
                  lbHome.HomeSet() ? CBTf(n"Cyberbane-Hud-CrewHomeIn", [CBDistrictLabel(lbHome.HomeDistrict())]) : CBT(n"Cyberbane-Hud-CrewHomeNone"), "", "");
      this.SetRowHelp(row, CBT(n"Cyberbane-Hud-HelpCrewHome"));
      this.m_rowCrew[row] = 9;
      row += 1;
    }
    let fallen = IsDefined(bb) ? bb.FallenCount() : 0;
    this.SetRow(row, CBHudLayoutCrew(), fallen > 0 ? CBHudLabel() : CBHudDim(), fallen > 0, false, CBT(n"Cyberbane-Hud-RememberTheFallen"), "", "",
                fallen > 0 ? (fallen == 1 ? CBT(n"Cyberbane-Hud-OneName") : CBTf(n"Cyberbane-Hud-Names", [s"\(fallen)"])) : CBT(n"Cyberbane-Hud-NobodyYet"), "", "");
    this.m_rowCrew[row] = 3;
    row += 1;
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
    let text = CBTf(n"Cyberbane-Hud-OnTheRosterFallen", [(StrLen(name) > 0 ? StrUpper(name) : CBT(n"Cyberbane-Hud-YOURCREW")), s"\(book.Count())", s"\(fallen)", (wars > 0 ? CBTf(n"Cyberbane-Hud-Won", [s"\(wars)", wars == 1 ? CBT(n"Cyberbane-Hud-War") : CBT(n"Cyberbane-Hud-Wars")]) : ".")]);
    if shown == 0 {
      text += CBT(n"Cyberbane-Hud-NoGangThinksAnythingOfYour");
    }
    text += CBTf(n"Cyberbane-HubWar-TierLine", [CBCrewSizeWord(CBCrewTier(game)), s"\(RoundF(CBCrewPower(game)))"]);
    text += CBCrewPowerLine(sys, game);
    let hoods = CBHoodsCrewLine(game);
    if StrLen(hoods) > 0 {
      text += CBTf(n"Cyberbane-HubWar-HoodsLine", [hoods]);
    }
    text += CBCrewPageLines(sys, game);   // V's second, a funeral owed, the wars, the home
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  private func CrewRecordClicked(game: GameInstance, code: Int32) -> Void {
    // The crew's places and the kitty's upgrades: screens of their own.
    if code == 10 || code == 11 || code == 12 {
      this.m_crewMode = code == 10 ? 25 : (code == 11 ? 26 : 27);
      this.m_listTop = 0;
      return;
    }
    // The crew's home, here: only words and books, so at once.
    if code == 9 {
      let lbSet = CBCrewLifeBook.Get(game);
      let player = GetPlayer(game);
      let sysSet = CyberbaneSystem.Get(game);
      if IsDefined(lbSet) && IsDefined(player) && IsDefined(sysSet) && CBOnHomeGround(game) {
        lbSet.SetHome(player.GetWorldPosition(), sysSet.GetCurrentDistrict());
        CBMenuNote(game, CBTf(n"Cyberbane-Hud-CrewHomeMade", [CBDistrictLabel(sysSet.GetCurrentDistrict())]), 5.0);
      }
      return;
    }
    // The cut (from the roster): asked here, paid on the first settled tick back in the game; again, taken back.
    if code == 8 {
      let cbPay = CBCrewBook.Get(game);
      if IsDefined(cbPay) && (cbPay.reqPay || (cbPay.CutOwed() > 0 && CBHudEddies(game) >= cbPay.CutOwed())) {
        cbPay.reqPay = !cbPay.reqPay;
      }
      return;
    }
    // Go to war (a row on older pages): the War view.
    if code == 7 {
      this.m_listTop = 0;
      this.m_crewMode = 20;
      return;
    }
    // The kitty, a challenge answered or turned down.
    if code == 4 {
      let took = CBKittyTake(game);
      if took > 0 {
        CBMenuNote(game, CBTf(n"Cyberbane-CrewJobs-YouTookTheKitty", [s"\(took)"]), 4.0);
      }
      return;
    }
    if code == 5 {
      this.m_crewMode = 9;
      return;
    }
    if code == 6 {
      let jbNo = CBCrewJobBook.Get(game);
      if IsDefined(jbNo) {
        CBCrewChallengeRefused(CyberbaneSystem.Get(game), game, jbNo, true);
      }
      return;
    }
    if code == 1 {
      this.m_crewMode = 4;
      this.SeedNameInput(CBCrewNameOf(game), CBT(n"Cyberbane-Hud-NameYourCrew"));
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

  // The memorial: the fallen, the last first; one picked, what is remembered of them.
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
             : CBT(n"Cyberbane-Hud-THEFALLENTheOnesWhoDied");
    if n == 0 {
      text = CBT(n"Cyberbane-Hud-THEFALLENNobodyFromYourCrew");
    }
    this.SetAction(CBT(n"Cyberbane-Hud-Back"), true, CBT(n"Cyberbane-Hud-HelpBack"));
    let bodyTop = CBHudContentTop() + Cast<Float>(Max(row, 1)) * CBHudRowHeight() + 24.0;
    this.SetBody(CBHudMarginX(), bodyTop, CBHudContentW() - CBHudActionW() - 40.0, text, CBHudMaxLinesFor(this.m_tab));
  }

  // The name box, built the first time it is wanted (Codeware's HubTextInput), in the page's own panel.
  // The name box is on screen: the crew's name (4) or one of them (10).
  private func CrewNaming() -> Bool {
    return this.m_crewMode == 4 || this.m_crewMode == 10 || this.m_crewMode == 24;
  }

  // What the name box holds when it opens, and says when empty: one box serves the crew's name and theirs, so it is
  // filled each time a naming screen opens, never on each draw, which would throw away what is being typed.
  private func SeedNameInput(text: String, hint: String) -> Void {
    this.m_nameSeed = text;
    this.m_nameHint = hint;
    if IsDefined(this.m_nameInput) {
      this.m_nameInput.SetDefaultText(hint);
      this.m_nameInput.SetText(text);
    }
  }

  private func ShowNameInput(game: GameInstance, x: Float, y: Float) -> Void {
    if !IsDefined(this.m_nameInput) && IsDefined(this.m_panel) {
      let input = HubTextInput.Create();
      input.SetName(n"CBCrewNameInput");
      input.SetMaxLength(CBConfig.CrewNameMaxLength());
      input.SetDefaultText(StrLen(this.m_nameHint) > 0 ? this.m_nameHint : CBT(n"Cyberbane-Hud-NameYourCrew"));
      input.Reparent(this.m_panel);
      input.SetText(StrLen(this.m_nameHint) > 0 ? this.m_nameSeed : CBCrewNameOf(game));
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
        this.SetRowHelp(row, CBTf(n"Cyberbane-Hud-HelpPickMember", [CBCrewFirst(sys, m)]));
        this.m_rowCrew[row] = m.id;
        row += 1;
      }
    }
    if offer && row < CBHudListRows() {
      let seat = CBCrewSeatOf(CBHunterRecord(book.offerSeed, n""), book.offerSeed);
      this.SetRow(row, CBHudLayoutCrew(), CBHudGrey(), true, this.m_pickCrew == -1,
        CBCrewOfferName(sys, game, book), CBCrewSeatWord(seat), "", CBT(n"Cyberbane-Hud-ASoloOnOffer"), "",
        CBTf(n"Cyberbane-Hud-EB", [s"\(book.offerPrice)"]));
      this.m_rowCrew[row] = -1;
      row += 1;
    }
    return row;
  }

  // V in the middle and the crew round V, each line as strong and as warm as their loyalty; the solo on offer to one
  // side, and the last few who left along the bottom, with how they left.
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
    this.PlaceLabel(words, 0.0, y + 10.0, CBTf(n"Cyberbane-Hud-YOURCREWOF", [s"\(book.Count())", s"\(CBConfig.MyCrewRoster())"]), CBHudDim());
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
          this.m_webBoxEdge[slot].SetTintColor(CBCrewColour(game));   // the crew's colours
          this.m_webBoxEdge[slot].SetVisible(true);
        }
        // Loyalty, and the climb to their next rank: fights won towards it.
        this.BoxBars(slot, mw, mh, Cast<Float>(m.loyalty) / 100.0, tint, CBCrewRankProgress(GetGameInstance(), m), CBHudCyan());
        this.m_boxCrew[slot] = m.id;
      }
      k += 1;
    }
    if book.Count() > 0 {
      y += mh + 20.0;
    }
    if offer {
      let os = 6;
      this.PlaceLabel(words, 0.0, y + 10.0, CBTf(n"Cyberbane-Hud-ONOFFERFROM", [s"\(StrUpper(book.offerSender))"]), CBHudDim());
      words += 1;
      y += 28.0;
      let seat = CBCrewSeatOf(CBHunterRecord(book.offerSeed, n""), book.offerSeed);
      this.PlaceWebBox(os, 0.0, y, mw, mh, true);
      this.DressBox(os, mw, mh, CBPicName(), CBPicLine(), CBPicLead(), false);
      this.BoxText(this.m_webBoxName[os], CBCrewOfferName(sys, game, book), mw - 24.0, CBPicName(),
                   CBPicNameLeast(), true);
      this.BoxText(this.m_webBoxLine[os], CBTf(n"Cyberbane-Hud-EB-2", [StrUpper(CBCrewSeatWord(seat)), s"\(book.offerPrice)"]), mw - 24.0, CBPicLine(),
                   CBPicLineLeast(), false);
      if IsDefined(this.m_webBoxLine[os]) { this.m_webBoxLine[os].SetTintColor(CBHudGrey()); }
      this.BoxText(this.m_webBoxLead[os], CBT(n"Cyberbane-Hud-ASoloForHire"), mw - 24.0, CBPicLead(), CBPicLeadLeast(), false);
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
      this.PlaceLabel(words, 0.0, y + 10.0, CBT(n"Cyberbane-Hud-GONE"), CBHudDim());
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
    if IsDefined(this.m_nameInput) && !this.CrewNaming() {
      let nameRoot = this.m_nameInput.GetRootWidget();
      if IsDefined(nameRoot) {
        nameRoot.SetVisible(false);
      }
    }
    let score = sys.GetScore();
    let titleName = CBHudActiveTitle(sys);
    let tier = IsDefined(score) ? CBTierName(EnumInt(score.GetTier())) : CBT(n"Cyberbane-Hud-Nobody");
    if IsDefined(this.m_subhead) {
      this.m_subhead.SetText(CBHudFit(titleName + "   |   " + tier, CBHudContentW(), 24, 1));
    }
    if IsDefined(this.m_tabline) {
      this.m_tabline.SetText(CBHudFit(CBHudTabBlurb(this.m_tab), CBHudContentW(), 20, 1));
    }

    this.HideBars();
    this.HideRows();
    this.HideWeb();
    this.ShowCrewViews(false);
    this.m_treeShown = false;
    // Every page that has a picture can be read as a list instead: the web, the map, the tree, the crew.
    let pictured = CBHudHasPicture(this.m_tab);
    if IsDefined(this.m_webToggle) {
      this.m_webToggle.SetVisible(pictured);
    }
    if IsDefined(this.m_webToggleText) && pictured {
      this.m_webToggleText.SetText(sys.HubVisual(this.m_tab) ? CBT(n"Cyberbane-Hud-ShowAsAList") : CBHudPictureWord(this.m_tab));
    }
    // The History page's filter, in the same box.
    if this.m_tab == CBHudHistoryTab() && !this.m_legendShown {
      if IsDefined(this.m_webToggle) {
        this.m_webToggle.SetVisible(true);
      }
      if IsDefined(this.m_webToggleText) {
        this.m_webToggleText.SetText(CBTf(n"Cyberbane-Hud-LogFilter", [CBHudLogFilterWord(this.m_logFilter)]));
      }
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
    // The crew (Reactions/Crew.reds): a page of its own, drawn whole by RenderCrew.
    if this.m_tab == CBHudCrewTab() {
      this.RenderCrew(sys, game);
      this.Paint();
      this.m_root.SetVisible(true);
      this.ForeignOverlaysOff();
      return;
    }
    if this.m_tab == CBHudStandingTab() {
      // Four tiles, what is on its way as rows, and two or three lines of why.
      this.RenderScores(sys);
      let lanesEnd = this.RenderLanes(sys, game);
      // A price on V's head can be paid off here (Spawn/Bounty.reds); asks twice, like every payment.
      let payOff = CBBountyPayOff(sys, game);
      let proseW = w;
      if payOff > 0 {
        if CBBountyPayPending(game) {
          this.SetAction(CBT(n"Cyberbane-Hud-PayingItOffClickToTake"), true);
        } else {
          if this.m_bountyArmed {
            this.SetAction(CBTf(n"Cyberbane-Hud-ClickAgainPayEb", [s"\(payOff)"]), true);
          } else {
            this.SetAction(CBTf(n"Cyberbane-Hud-PayOffThePriceOnYou", [s"\(payOff)"]), CBHudEddies(game) >= payOff);
          }
        }
        proseW = w - CBHudActionW() - 40.0;
      }
      // Something V came for happens at a set hour: skip straight to it.
      let skip = CBSkipTimeLabel(game);
      if StrLen(skip) > 0 {
        this.SetExtra(1, skip, true, CBSkipTimeWhy(game));
        proseW = w - CBHudActionW() - 40.0;
      }
      // Right now: who is coming and why, a counterattack, a funeral, an ask, first; then the legend.
      let nowLine = CBHudRightNow(sys, game);
      this.SetBody(x, lanesEnd + 16.0, proseW, StrLen(nowLine) > 0 ? nowLine + "\n" + CBHudLegend(sys, game) : CBHudLegend(sys, game), maxLines);
    } else {
      if this.m_tab == CBHudFactionsTab() {
        // The gangs as a list, or as the web of gangs (UI/HubWeb.reds); the panel below is the same either way.
        if sys.HubWeb() {
          this.RenderWeb(sys, game);
        } else {
          this.RenderFactions(sys);
        }
        this.RenderFactionDetail(sys, game);
      } else {
        // The streets: who holds them (with turf wars on), or where V's name carries; one button turns the reading.
        let streetsTurf = this.m_tab == CBHudTurfTab() && CBTurfWarsOn() && !this.m_streetsName;
        if this.m_tab == CBHudTurfTab() && CBTurfWarsOn() {
          this.SetExtra(1, this.m_streetsName ? CBT(n"Cyberbane-HubWar-ShowWhoHolds") : CBT(n"Cyberbane-HubWar-ShowYourName"), true,
                        CBT(n"Cyberbane-HubWar-HelpStreetsReading"));
        }
        if streetsTurf {
          // Night City as a map, or the list.
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
              // The Rivals as a list, or as each gang's tree ([H2]); the file below is the same either way.
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
                // The work is the switch that already exists: RequestHardReset, taken by the fast tick
                // (CyberbaneSystem, TakeHardResetRequest).
                this.SetAction(this.m_legendShown ? CBT(n"Cyberbane-Hud-ShowTheLedger") : CBT(n"Cyberbane-Hud-TellMyStory"), true);
                if sys.HasStartOverToUndo() {
                  this.SetExtra(1, this.m_undoArmed ? CBT(n"Cyberbane-Hud-ClickAgainUndoIt") : CBT(n"Cyberbane-Hud-UndoTheLastStartOver"), true);
                }
                this.SetExtra(2, this.m_resetArmed ? CBT(n"Cyberbane-Hud-ClickAgainEraseItAll") : CBT(n"Cyberbane-Hud-StartOver"), true);
                // Full width, but it stops above the buttons: run on to the footer, the ledger's last lines were drawn
                // underneath them.
                let page = "";
                if this.m_legendShown {
                  page = CBLegendTold(sys, game);
                } else {
                  let heads = CBScreamsheet(sys, game);
                  page = StrLen(heads) > 0 ? heads + "\n\n" + CBHudLog(sys, this.m_logFilter) : CBHudLog(sys, this.m_logFilter);
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
    return sys.IsPendingApexDriving() ? CBTf(n"Cyberbane-Hud-APEXSQUADDRIVING", [CBTimeText(sys.GetPendingApexTicks())])
                                      : CBTf(n"Cyberbane-Hud-APEXSQUAD", [CBWhen(sys.GetPendingApexTicks())]);
  }
  if Equals(sys.GetPendingSquadFaction(), fs.id) {
    if sys.GetPendingSquadTicks() <= 0 {
      let why = CBBlockLabel(CBLastSpawnBlock());
      return StrLen(why) > 0 ? CBTf(n"Cyberbane-Hud-HELD", [why]) : CBT(n"Cyberbane-Hud-CREWHELDUP");
    }
    return CBTf(n"Cyberbane-Hud-CREWINBOUND", [CBTimeText(sys.GetPendingSquadTicks())]);
  }
  if Equals(sys.GetLaneTarget(CBLaneApex()), fs.id) {
    return CBTf(n"Cyberbane-Hud-APEXSQUAD", [CBWhen(sys.GetLaneTicks(CBLaneApex()))]);
  }
  if Equals(sys.GetLaneTarget(CBLaneSquad()), fs.id) {
    return CBTf(n"Cyberbane-Hud-CREW", [CBWhen(sys.GetLaneTicks(CBLaneSquad()))]);
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
    return CBT(n"Cyberbane-Hud-SwitchedOffUnderFactionsInMod-2");
  }
  if CBGangViewSet(id) {
    return CBT(n"Cyberbane-Hud-HowTheyTreatYouIsSet");
  }
  let content = CBContent(game);
  if IsDefined(content) {
    let prof = content.GetFaction(id);
    if IsDefined(prof) && !prof.canBeBought {
      return CBT(n"Cyberbane-Hud-NobodyHereTakesMoneyToForget");
    }
  }
  if Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied) {
    return CBT(n"Cyberbane-Hud-TheyLikeYouFriendlyGangsCut");
  }
  return CBT(n"Cyberbane-Hud-TheyAreNotHostileSoThere");
}

// ---- Tab content -----------------------------------------------------------

func CBHudActiveTitle(sys: ref<CyberbaneSystem>) -> String {
  // The title that is showing: the player's choice, else the best one earned. GetActiveTitle only
  // comes back empty when nothing has been earned at all.
  let id = sys.GetActiveTitle();
  if Equals(id, n"") {
    return CBT(n"Cyberbane-Hud-NoTitleYet");
  }
  // Names the district or gang the title is actually about (Model/TitleNaming.reds).
  return CBTitleDisplayById(sys, sys.GetContent(), id);
}

// inkText does not clip to its box: hand it more than fits and it renders straight over the footer, the button beside
// it, or off the panel. So nothing reaches the page without being fitted to the box it goes in first.

// Average width of a character as a fraction of the font size, for the menu font. Generous on purpose; capitals are
// wider, so text drawn upper case gets its own figure.
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

// First "Nick" Last as First Last, for a line that names somebody in passing. Anything else as it is.
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

// The words of one paragraph that fit in `room` lines, with "..." on the end to say there was more. Empty if there is
// no room at all.
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
    // Only name a Rival the Rivals screen would also list.
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
    // Rivals who came together say so.
    if lane == CBLaneRival() {
      let together = CBRivalsOutTogether(sys, game);
      if together > 1 {
        return CBTf(n"Cyberbane-Hud-HereNowOfThemTogether", [label, CBNumberWord(together)]);
      }
    }
    return CBTf(n"Cyberbane-Hud-HereNow-2", [label]);
  }
  // A lane's clock does not run while nobody can arrive (CBLaneTick), so a countdown shown then stood
  // still with nothing to say why: the stuck clock this screen was built to never show.
  let held = CBArrivalsHeldWhy(sys, game);
  // Nothing queued. Say whether that is because the day's allowance is spent, rather than
  // leaving "nobody" to mean both "none due" and "none left", which look identical and are
  // the sort of silence that reads as the mod being broken.
  if StrLen(who) == 0 {
    if CBLaneDailyCap(lane) <= 0 {
      return CBTf(n"Cyberbane-Hud-Off-2", [label]);
    }
    // Nobody who could come at all: said instead of the next window's time, which on a new game read as a Rival, a crew
    // and an apex squad on their way with nobody against V.
    let nobody = CBLaneNobodyWhy(sys, lane);
    if StrLen(nobody) > 0 {
      return label + "   " + nobody;
    }
    // Whose grudge runs out first, and when (Spawn/Grudge.reds), in the player's own minutes.
    if StrLen(held) > 0 {
      return CBTf(n"Cyberbane-Hud-Waiting", [label, held]);
    }
    let rest = CBLaneRestLeft(sys, lane);
    if rest > 0 {
      return CBTf(n"Cyberbane-Hud-Breather", [label, CBTimeText(rest)]);
    }
    let soonest: CName;
    let soonestRival: Int32;
    let inSecs = CBGrudgeNextIn(sys, game, lane, soonest, soonestRival);
    if inSecs < 0.0 {
      if lane == CBLaneRival() && sys.CountActiveRivals() > 0 && CBRivalsAllLyingLow(sys) {
        return CBTf(n"Cyberbane-Hud-EveryRivalIsLyingLow", [label]);
      }
      return label + (lane == CBLaneApex() ? CBT(n"Cyberbane-Hud-NobodyHasEarnedIt") : CBT(n"Cyberbane-Hud-NobodyHoldsAGrudge"));
    }
    let whose = "";
    if soonestRival > 0 {
      let sr = sys.FindRivalById(soonestRival);
      whose = IsDefined(sr) ? CBRivalDisplayName(sys.GetContent(), sr) : "";
    } else {
      whose = NotEquals(soonest, n"") ? CBFactionLabel(soonest) : "";
    }
    if inSecs <= 0.0 {
      return label + "   " + (StrLen(whose) > 0 ? CBTf(n"Cyberbane-Hud-IsReadyToMove", [CBCapFirst(whose)]) : CBT(n"Cyberbane-Hud-Ready"));
    }
    return label + "   " + (StrLen(whose) > 0 ? CBTf(n"Cyberbane-Hud-Moves", [CBCapFirst(whose)]) : CBT(n"Cyberbane-Hud-Next"))
         + (CBShowCountdowns() ? CBTf(n"Cyberbane-Hud-InAbout", [CBHudRealFromGameHours(inSecs / CBConfig.SecondsPerHour())]) : CBT(n"Cyberbane-Hud-BeforeLong"));
  }
  if StrLen(held) > 0 {
    return CBTf(n"Cyberbane-Hud-Waiting-2", [label, who, held, CBHudBudgetTail(sys, game, lane)]);
  }
  // Lined up, and waiting out everybody's rest after another fight (CBLaneRestLeft): their clock stands still, so say
  // why instead of showing it. A Rival who has already said they are coming is not held by it.
  let warnedQ = lane == CBLaneRival() && sys.GetRivalWarned() > 0 && sys.GetRivalWarned() == sys.GetLaneRivalId(lane);
  let restQ = CBRestTogether() && !warnedQ ? CBLaneRestLeft(sys, lane) : 0;
  if restQ > 0 {
    return CBTf(n"Cyberbane-Hud-WaitingOutTheBreather", [label, who, CBTimeText(restQ)]);
  }
  let ticks = sys.GetLaneTicks(lane);
  if ticks <= 0 {
    let why = CBBlockLabel(CBLastSpawnBlock());
    let tail = CBHudBudgetTail(sys, game, lane);
    return StrLen(why) > 0 ? CBTf(n"Cyberbane-Hud-Held", [label, who, why, tail])
                           : CBTf(n"Cyberbane-Hud-AnyMoment-2", [label, who, tail]);
  }
  return label + "   " + who + "  " + CBTimeText(ticks) + CBHudBudgetTail(sys, game, lane);
}

// The Rivals page's cards group Rivals by gang; Rivals of no gang are a group of their own, under this name. No gang is
// called this, and nothing but the cards' own choice of group ever holds it.
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

// In-game hours as the real time they will actually take, using the clock rate measured at the start of the session.
func CBHudRealFromGameHours(hrs: Float) -> String {
  let secs = hrs * 3600.0 / CBGameSecondsPerReal();
  if secs >= 3600.0 {
    return CBTf(n"Cyberbane-Hud-H", [s"\(RoundF(secs / 3600.0))"]);
  }
  if secs >= 60.0 {
    return CBTf(n"Cyberbane-Hud-M", [s"\(RoundF(secs / 60.0))"]);
  }
  return CBTf(n"Cyberbane-Hud-S", [s"\(RoundF(secs))"]);
}

// " (2 of 3 today)". Shown so the pacing is something the player can see rather than guess at: each kind has its own
// daily allowance and this is what is left of it.
func CBHudBudgetTail(sys: ref<CyberbaneSystem>, game: GameInstance, lane: Int32) -> String {
  return CBLaneDailyCap(lane) <= 0 ? CBT(n"Cyberbane-Hud-Off-3") : "";
}

func CBHudLegend(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  // The four scores are meters now, so this screen's text only carries what a meter cannot: where you are, what the
  // city has already sent, and what it is doing about you right now.
  let out = "";
  // The price on V's head and the ladder (Spawn/Bounty.reds), when there is one.
  let bounty = CBBountyHubLine(sys, game);
  if StrLen(bounty) > 0 {
    out += bounty + "\n";
  }
  out += CBHudDreadReason(sys) + "\n";
  out += CBHudReactionState(sys);
  out += CBHudEsteemLine(sys);
  return out;
}

// What the people here think of V, under the crowd's line (Model/Esteem.reds).
func CBHudEsteemLine(sys: ref<CyberbaneSystem>) -> String {
  if !CBEsteemOn() {
    return "";
  }
  let game = sys.GetGameInstance();
  let district = sys.GetCurrentDistrict();
  if CBEsteemSoured(game, district) {
    return CBT(n"Cyberbane-Esteem-HudSoured");
  }
  let esteem = CBEsteemHere(sys, game);
  if esteem < CBConfig.EsteemKnown() {
    return CBT(n"Cyberbane-Esteem-HudNotYet");
  }
  let line = CBTf(n"Cyberbane-Esteem-HudHere", [CBEsteemWord(esteem), s"\(RoundF(esteem))"]);
  if esteem >= CBConfig.EsteemGreet() * sys.WornPerk().greetMult {
    line += CBT(n"Cyberbane-Esteem-HudTheyGreetYou");
  }
  return line;
}
// A live readout of what the city is actually doing about you right now, and what it would
// take to move the needle. This is the line that answers "is any of this working?".
func CBHudReactionState(sys: ref<CyberbaneSystem>) -> String {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return "";
  }
  // Say why nothing is happening, rather than reporting a threshold the player is already past while the whole system
  // is standing down for a reason they cannot see.
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return CBT(n"Cyberbane-Hud-RightNowCyberbaneIsSwitchedOff");
  }
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().civReactions {
    return CBT(n"Cyberbane-Hud-RightNowCrowdReactionsAreSwitched");
  }
  if sys.IsInSafeZone() {
    return CBT(n"Cyberbane-Hud-RightNowTheGameCallsThis");
  }
  let reg = sys.GetRegistry();
  if !IsDefined(reg) || reg.Count() == 0 {
    return CBT(n"Cyberbane-Hud-RightNowCyberbaneIsNotTracking");
  }
  // Say so before anything else, because a masked player reading "nobody backs off yet" would
  // reasonably conclude the mask had done nothing when it is doing all of it.
  if CBCrowdIgnoresPlayer(GetGameInstance()) {
    return CBTf(n"Cyberbane-Hud-RightNowYourFaceIsCovered", [s"\(reg.Count())"]);
  }
  let chromeVisible = score.GetChromeVisible();
  // The crowd's own number, from the crowd's own formula, including the intensity slider the
  // player set. Working it out separately here is what let this screen disagree with the street.
  let eff = CBCrowdFearHere(sys, GetGameInstance(), score, CBCivIntensity() * CBCrowdMomentMult(sys, GetGameInstance()));
  let reach = 1.0 + (chromeVisible / 100.0) * CBConfig.ChromeNoticeRangeBonus();
  if eff >= CBConfig.CivFearRun() {
    let r = RoundF(CBConfig.CivFleeRadius() * reach);
    return CBTf(n"Cyberbane-Hud-RightNowPeopleRunWhenYou", [s"\(r)", s"\(reg.Count())"]);
  }
  if eff >= CBConfig.CivFearCower() {
    let r = RoundF(CBConfig.CivCowerRadius() * reach);
    return CBTf(n"Cyberbane-Hud-RightNowPeopleFreezeWithTheir", [s"\(r)", s"\(reg.Count())"]);
  }
  if eff >= CBConfig.CivFearStartle() {
    let r = RoundF(CBConfig.CivStartleRadius() * reach);
    return CBTf(n"Cyberbane-Hud-RightNowPeopleFlinchAndStep", [s"\(r)", s"\(reg.Count())"]);
  }
  if eff >= CBConfig.CivFearGlance() {
    let r = RoundF(CBConfig.CivGlanceRadius() * reach);
    return CBTf(n"Cyberbane-Hud-RightNowPeopleLookOverAt", [s"\(r)", s"\(reg.Count())"]);
  }
  let need = RoundF(CBConfig.CivFearGlance() - eff);
  return CBTf(n"Cyberbane-Hud-RightNowNobodyLooksTwiceYet", [s"\(need)", s"\(reg.Count())"]);
}

// What V is wearing, read again as the Hub opens and on every change of screen.
func CBHudResampleWorn(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !IsDefined(GetPlayer(game)) {
    return;
  }
  // And They Will Remember's word on who is hostile, which the gangs' standing now follows.
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
  // Weighted by what each one actually contributes to Dread, not the raw score.
  let k = CBKillDreadComponent(sys.GetKillDreadPoints()) * CBConfig.DreadWeightK();
  let x = CBDeedDreadComponent(sys.GetDeedDreadPoints()) * CBConfig.DreadWeightX();
  let h = CBHeatDreadComponent(sys.GetHeatPoints()) * CBConfig.DreadWeightH();
  let c = score.GetChromeVisible() * CBConfig.DreadWeightC();
  let l = score.GetLook() * CBConfig.DreadWeightL();

  let bestLabel = CBT(n"Cyberbane-Hud-NothingInParticularYet");
  let bestHint = "";
  let best = 0.0;
  if k > best { best = k; bestLabel = CBT(n"Cyberbane-Hud-YourBodyCount"); bestHint = CBT(n"Cyberbane-Hud-ItFadesWhileYouLieLow"); }
  if c > best { best = c; bestLabel = CBT(n"Cyberbane-Hud-AllThatChrome"); bestHint = CBT(n"Cyberbane-Hud-LongSleevesTrousersAndAMask"); }
  if l > best { best = l; bestLabel = CBT(n"Cyberbane-Hud-TheWayYouCarryYourself"); bestHint = CBT(n"Cyberbane-Hud-DressDownAndItEases"); }
  if x > best { best = x; bestLabel = CBT(n"Cyberbane-Hud-TheThingsYouHaveDone"); bestHint = CBT(n"Cyberbane-Hud-TheStoriesFadeWhileYouLie"); }
  if h > best { best = h; bestLabel = CBT(n"Cyberbane-Hud-TheHeatYouDrawFromThe"); bestHint = CBT(n"Cyberbane-Hud-StayOffTheNCPDSRadar"); }

  if best <= 0.0 {
    return CBT(n"Cyberbane-Hud-PeopleBarelyKnowYouMakeSome");
  }
  // One line, so the screen stays as quiet as it was.
  return CBTf(n"Cyberbane-Hud-PeopleFearYouMostlyFor", [bestLabel, bestHint]);
}

func CBHudFactions(sys: ref<CyberbaneSystem>) -> String {
  let states = sys.GetFactionStates();
  if ArraySize(states) == 0 {
    return CBT(n"Cyberbane-Hud-NoGangHasFormedAnOpinion");
  }
  let out = CBT(n"Cyberbane-Hud-HostileGangsSendCrewsVendettaMeans");
  out += CBT(n"Cyberbane-Hud-ToBeThoughtWellOfHurt");
  out += CBT(n"Cyberbane-Hud-WithoutKillingThemLetTheirNames");
  out += CBT(n"Cyberbane-Hud-TroubleOrWalkUpToTheir");
  out += CBT(n"Cyberbane-Hud-TheirOwnTurfAndWarnYou");
  out += CBT(n"Cyberbane-Hud-BodyIntimidateTheirPeopleSomebodyAfraid");
  out += CBT(n"Cyberbane-Hud-ClickAGangToSeeMore");
  return out;
}
func CBHudDistricts(sys: ref<CyberbaneSystem>) -> String {
  let states = sys.GetDistrictStates();
  if ArraySize(states) == 0 {
    return CBT(n"Cyberbane-Hud-YourNameHasNotTravelledTo");
  }
  // The districts themselves are drawn as rows (RenderCity). This is only the line that says
  // how to read them.
  let out = CBT(n"Cyberbane-Hud-WordSpreadsOutwardFromWhereThings");
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
    return CBT(n"Cyberbane-Hud-WALLEDOFF");
  }
  let book = CBTurfBook.Get(game);
  if IsDefined(book) && NotEquals(book.Challenger(CBDistrictIndex(district)), n"") {
    return CBTf(n"Cyberbane-Hud-MOVINGIN", [s"\(CBBarFactionLabel(book.Challenger(CBDistrictIndex(district))))"]);
  }
  let prof = content.GetFaction(holder);
  let home = IsDefined(prof) && ArrayContains(prof.turf, district);
  if second >= 0 && shares[second] >= CBConfig.TurfPresenceShare()
     && (CBGangsAreRivals(content, holder, ids[second]) || CBGangsAreRivals(content, ids[second], holder)) {
    return CBTf(n"Cyberbane-Hud-VS", [s"\(CBBarFactionLabel(ids[second]))", s"\(RoundF(shares[second] * 100.0))"]);
  }
  if !home {
    return CBT(n"Cyberbane-Hud-MOVEDIN");
  }
  if second >= 0 && shares[second] >= CBConfig.TurfPresenceShare() {
    return CBT(n"Cyberbane-Hud-SHARED");
  }
  return CBT(n"Cyberbane-Hud-HELD-2");
}

// The few lines under the districts: which gangs V has hurt, and how badly.
func CBHudTurfBody(sys: ref<CyberbaneSystem>) -> String {
  if !CBTurfWarsOn() {
    return CBT(n"Cyberbane-Hud-TurfWarsAreOffInMod");
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
    return CBT(n"Cyberbane-Hud-EveryGangIsAtFullStrength");
  }
  return CBTf(n"Cyberbane-Hud-TheyRebuildWhileYouLeaveThem", [out]);
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

// Why this Rival has it in for you, in plain words. Whole sentences: the file opened on a fragment in lower case ("got
// away from you bleeding, at large"), two subjects run together ("you beat them down and left them alive, quiet").
func CBRivalSourceLine(source: Int32) -> String {
  if source == EnumInt(ECBRivalSource.Survivor) {
    return CBT(n"Cyberbane-Hud-TheyGotAwayFromYouBleeding");
  }
  if source == EnumInt(ECBRivalSource.Spared) {
    return CBT(n"Cyberbane-Hud-YouBeatThemDownAndLeft");
  }
  if source == EnumInt(ECBRivalSource.Killer) {
    return CBT(n"Cyberbane-Hud-TheyPutYouDownOnce");
  }
  if source == EnumInt(ECBRivalSource.Avenger) {
    return CBT(n"Cyberbane-Hud-TheyAreAvengingSomeoneYouKilled");
  }
  if source == EnumInt(ECBRivalSource.Hunter) {
    return CBT(n"Cyberbane-Hud-TheyCameForYourHeadAnd");
  }
  if source == EnumInt(ECBRivalSource.Betrayer) {
    return CBT(n"Cyberbane-Hud-TheyRanWithYourCrewThen");
  }
  return CBT(n"Cyberbane-Hud-TheyRememberYou");
}

// How many times V and they have met: every meeting since they became a Rival (encounters, what their file counts
// "since"), and the one they were made in, for one who got away from V, was spared by V, killed V or turned on V.
func CBRivalTimesMet(r: ref<CBRival>) -> Int32 {
  if !IsDefined(r) {
    return 0;
  }
  let born = r.source == EnumInt(ECBRivalSource.Survivor) || r.source == EnumInt(ECBRivalSource.Spared)
          || r.source == EnumInt(ECBRivalSource.Killer) || r.source == EnumInt(ECBRivalSource.Betrayer)
          || r.sparedByV > 0 || r.killedV > 0;
  return r.encounters + (born ? 1 : 0);
}

// Where they stand now, as a sentence for the file, by the same test as their row in the tree: the file went by the
// state alone, so the one coming for V read "at large" under a row that said HUNTING YOU, and a dead one read "quiet".
func CBRivalStateLine(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> String {
  if r.state == EnumInt(ECBRivalState.Slain) {
    return CBT(n"Cyberbane-Hud-TheyAreDead");
  }
  if r.state == EnumInt(ECBRivalState.Retired) && CBRivalRunsWithV(GetGameInstance(), r) {
    return CBT(n"Cyberbane-Hud-TheyRunWithYou");
  }
  if r.state == EnumInt(ECBRivalState.Retired) && CBWarHoldsRival(GetGameInstance(), r.id) {
    return CBT(n"Cyberbane-HubWar-HeldByYourCrew");
  }
  if r.state == EnumInt(ECBRivalState.Retired) {
    return CBT(n"Cyberbane-Hud-TheyHaveLeftNightCity");
  }
  if r.id == sys.GetActiveRivalId() || r.state == EnumInt(ECBRivalState.Hunting) {
    return CBT(n"Cyberbane-Hud-TheyAreHuntingYou");
  }
  if r.state == EnumInt(ECBRivalState.Debtor) {
    return CBT(n"Cyberbane-Hud-TheyOweYouTheirLife");
  }
  if r.state == EnumInt(ECBRivalState.Dormant) {
    return CBT(n"Cyberbane-Hud-TheyHaveGoneQuiet");
  }
  if r.id == sys.GetLaneRivalId(CBLaneRival()) {
    return CBT(n"Cyberbane-Hud-TheyAreAtLargeAndNext");
  }
  return CBT(n"Cyberbane-Hud-TheyAreAtLarge");
}

func CBHudRivals(sys: ref<CyberbaneSystem>, game: GameInstance, pickedId: Int32, opt findArmed: Int32,
                 opt forgetArmed: Int32) -> String {
  if sys.IsRivalPurgePending() {
    return CBT(n"Cyberbane-Hud-EveryRivalIsForgottenInThe");
  }
  let count = sys.CountActiveRivals();
  if count <= 0 {
    return CBT(n"Cyberbane-Hud-NoActiveRivalsYetLeaveSomeone");
  }
  let cap = CBRivalCap();
  let out = "";
  // The file on whoever was clicked, or on whoever is next when nobody was.
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
      out += CBTf(n"Cyberbane-Hud-Strengths", [strong]);
    }
    if StrLen(weak) > 0 {
      out += CBTf(n"Cyberbane-Hud-WeakSpots", [weak]);
    }
    // A fatal flaw (Reactions/StreetIntel.reds): named once the street has told V; hinted at for a Rival
    // senior enough to have one, which is a reason to go and ask.
    let flaw = CBRivalFlaw(r);
    let intelBook = CBIntelBook.Get(game);
    if flaw > 0 && IsDefined(intelBook) && intelBook.KnowsFlaw(r.id) {
      out += CBTf(n"Cyberbane-Hud-FatalFlawKillsThemOutright", [CBFlawWord(flaw)]);
    } else {
      if CBFlawsOn() && r.rank >= CBConfig.FlawMinRank() {
        out += CBT(n"Cyberbane-Hud-TheirPeopleMayKnowAFatal");
      }
    }
    // What the street says about them, their line, and their family.
    out += CBTf(n"Cyberbane-Hud-OnTheStreet", [CBRivalStreetStatus(sys, game, r)]);
    out += CBTf(n"Cyberbane-Hud-Says", [CBRivalCatchphrase(r)]);
    // Their story, from what is known of them (Narrative/Telling.reds, [84]).
    out += CBTf(n"Cyberbane-Hud-TheirStory", [CBRivalStory(sys, game, r)]);
    out += CBRivalTimelineLine(game, r);   // every time you crossed
    let kinBook = CBIntelBook.Get(game);
    let kinOf = IsDefined(kinBook) ? kinBook.KinOf(r.id) : 0;
    let kinDead = kinOf > 0 ? sys.FindRivalById(kinOf) : null;
    if IsDefined(kinDead) {
      out += CBTf(n"Cyberbane-Hud-FamilyOfWhomYouKilled", [CBRivalDisplayName(content, kinDead)]);
    }
    let scars = CBScarLabel(r.scarMask);
    if StrLen(scars) > 0 {
      out += CBTf(n"Cyberbane-Hud-CarriesYourMark", [scars]);
    }
    // Their chrome and their bond (Rivals/RivalMoments.reds).
    let chrome = CBRivalChromeWords(r);
    if StrLen(chrome) > 0 {
      out += CBTf(n"Cyberbane-Hud-Chrome", [chrome]);
    }
    let signature = CBRivalSignatureKind(r);
    if signature > 0 {
      out += CBSignatureCardLine(signature) + "\n";
    }
    let holdBook = CBBaseBook.Get(game);
    let holdAt = IsDefined(holdBook) ? holdBook.HoldIndexOfRival(r.id) : -1;
    if holdAt >= 0 {
      out += CBTf(n"Cyberbane-Strongholds-CardLine", [CBBaseName(game, holdBook.HoldBaseAt(holdAt))]);
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
  // Who owes V (Reactions/Allies.reds, [U12]).
  let owed = CBInformantsLine(sys, game);
  if StrLen(owed) > 0 {
    out += owed + "\n";
  }
  out += CBTf(n"Cyberbane-Hud-OfAPossibleAreStillLooking", [s"\(count)", s"\(cap)"]);
  if count >= cap {
    out += CBT(n"Cyberbane-Hud-NobodyNewCanTakeAgainstYou");
  }
  return out;
}
// The whereabouts line in a Rival's file (CBHudRivals).
func CBHudRivalWhere(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, findArmed: Int32,
                     forgetArmed: Int32) -> String {
  if sys.IsRivalForgetPending(r.id) {
    return CBT(n"Cyberbane-Hud-ForgottenAsSoonAsYouAre");
  }
  if forgetArmed == r.id {
    return CBT(n"Cyberbane-Hud-ClickAgainToForgetThemUntil");
  }
  let price = CBWhereaboutsPrice(r);
  if sys.GetPendingFind() == r.id {
    if CBPhoneDealsReady() {
      return CBT(n"Cyberbane-Hud-PuttingTheWordOutSomebodyTexts");
    }
    return CBTf(n"Cyberbane-Hud-PayingEbForWhereTheyAre", [s"\(price)"]);
  }
  if sys.IsLairActive() && sys.GetLairRivalId() == r.id {
    return CBT(n"Cyberbane-Hud-WaitingAtTheirPlaceRightNow");
  }
  // Somebody told V where they were seen (Rivals/Whereabouts.reds).
  let lead = CBCurrentLead(sys, game);
  if IsDefined(lead) && lead.rivalId == r.id {
    let from = IsNameValid(lead.tipFaction) ? CBFactionLabel(lead.tipFaction) : CBT(n"Cyberbane-Hud-TheStreet");
    let ago = CBHudSince(CBGameSeconds(game), lead.seenAt);
    let when = StrLen(ago) > 0 ? CBTf(n"Cyberbane-Hud-Ago", [ago]) : "";
    return CBTf(n"Cyberbane-Hud-WordFromSeenGoOnFoot", [s"\(from)", s"\(CBPlacePhrase(lead.district, CBSightingPos(lead)))", s"\(when)"]);
  }
  let why = CBWhereaboutsForSale(sys, game, r);
  if why == 0 {
    if CBPhoneDealsReady() {
      if findArmed == r.id {
        return CBT(n"Cyberbane-Hud-ClickAgainToPutTheWord");
      }
      return CBTf(n"Cyberbane-Hud-PutTheWordOutAndSomebody", [s"\(price)", s"\(CBHudEddies(game))"]);
    }
    if findArmed == r.id {
      return CBTf(n"Cyberbane-Hud-ClickAgainToPayEbFor", [s"\(price)"]);
    }
    return CBTf(n"Cyberbane-Hud-EbBuysWhereTheyAreHiding", [s"\(price)", s"\(CBHudEddies(game))"]);
  }
  if why == 1 {
    return CBT(n"Cyberbane-Hud-TurnOnTipsOnWhereRivals");
  }
  if why == 5 {
    return CBT(n"Cyberbane-Hud-TheirFactionIsSwitchedOffUnder");
  }
  return CBT(n"Cyberbane-Hud-NobodySellsWhereTheyAreWhile");
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
      return CBTf(n"Cyberbane-Hud-YouGoByTheBestTitle", [out]);
    }
    out += CBTf(n"Cyberbane-Hud-YouGoByTheBestTitle-2", [CBTitleDisplayById(sys, content, worn)]);
    shown = worn;
  } else {
    out += StrUpper(CBTitleDisplayById(sys, content, id)) + "\n";
    if sys.HasTitle(id) {
      out += Equals(id, worn) ? CBT(n"Cyberbane-Hud-YouGoByThis") : "Earned.\n";
    } else {
      out += CBT(n"Cyberbane-Hud-NotEarnedYet");
    }
    let need = CBTitleRequirement(sys, id);
    if StrLen(need) > 0 {
      out += CBTf(n"Cyberbane-Hud-WHATITTAKES", [need]);
    }
  }
  let def = content.GetTitle(shown);
  if IsDefined(def) && StrLen(def.effect) > 0 {
    out += CBTf(n"Cyberbane-Hud-WHATITDOES", [CBDisplay(def.effect)]);
  }
  out += CBTitlesDoThings() ? CBT(n"Cyberbane-Hud-OnlyTheTitleYouGoBy") : CBT(n"Cyberbane-Hud-TitleEffectsAreSwitchedOffIn");
  return out;
}

// "3d", "5h", "20m" - how long since something happened, for the screens that track it.
// Returns "" when it never has.
// How long since, in the player's seconds rather than the game's.
public func CBHudSince(now: Float, then: Float) -> String {
  if then <= 0.0 || now <= then {
    return "";
  }
  let secs = (now - then) / CBGameSecondsPerReal();
  if secs >= 86400.0 {
    return CBTf(n"Cyberbane-Hud-D", [s"\(RoundF(secs / 86400.0))"]);
  }
  if secs >= 3600.0 {
    return CBTf(n"Cyberbane-Hud-H", [s"\(RoundF(secs / 3600.0))"]);
  }
  return CBTf(n"Cyberbane-Hud-M", [s"\(RoundF(secs / 60.0))"]);
}

func CBHudLog(sys: ref<CyberbaneSystem>, opt filter: Int32) -> String {
  let log = sys.GetLog();
  let n = ArraySize(log);
  if n == 0 {
    return CBT(n"Cyberbane-Hud-STREETFILESUBJECTVNothingOn");
  }
  let out = CBT(n"Cyberbane-Hud-STREETFILESUBJECTV");
  out += CBT(n"Cyberbane-Hud-PutTogetherFromWhatPeopleSaw");
  out += CBT(n"Cyberbane-Hud-WorkNobodyWitnessedNeverReachesThis");

  // The running totals. Every one of these was being counted and shown nowhere, which is the
  // same as not counting it.
  let stats = sys.GetStats();
  if IsDefined(stats) {
    out += CBTf(n"Cyberbane-Hud-TALLYPutDownTimesRecognisedTimes", [s"\(stats.deaths)", s"\(stats.timesRecognized)"]);
    out += CBTf(n"Cyberbane-Hud-RivalsSpared", [s"\(stats.rivalsSpared)"]);
    // Moved off the Standing screen, where it was three lifetime numbers in the middle of a
    // screen about right now. This is the ledger; it belongs here.
    out += CBTf(n"Cyberbane-Hud-RivalsPutDownApexEnforcersKilled", [s"\(stats.rivalsSlain)", s"\(stats.apexKills)"]);
    out += CBTf(n"Cyberbane-Hud-NeverPinnedOnYou", [s"\(stats.unattributed)"]);
    let spent = CBHudPeaceSpend(sys);
    out += CBTf(n"Cyberbane-Hud-TributeTakenEbPaidOutFor", [s"\(stats.tributeEddies)", s"\(spent)"]);
    // How V fights, in a word. It left the Standing screen with the rest of the lifetime numbers,
    // and it is still worth saying once - this is the screen that says things once.
    // How V fights, in a word, and how every style stands, with what builds each.
    out += CBStyleLine(sys);
    out += "\n";
  }

  let shown = 0;
  let now = CBGameSeconds(sys.GetGameInstance());
  if filter > 0 {
    out += CBTf(n"Cyberbane-Hud-LogShowing", [CBHudLogFilterWord(filter)]);
  }
  let i = n - 1;
  while i >= 0 && shown < 18 {
    let e = log[i];
    i -= 1;
    // Filtered: fights, the crew, money, Rivals.
    if IsDefined(e) && (filter <= 0 || CBHudLogGroup(e.kind) == filter) {
      out += CBHudLogLine(sys, e, now) + "\n";
      shown += 1;
    }
  }
  return out;
}

// Which filter an entry falls under: 1 fights, 2 the crew, 3 money, 4 Rivals.
public func CBHudLogGroup(kind: CName) -> Int32 {
  let k = NameToString(kind);
  if StrBeginsWith(k, "Crew") || StrBeginsWith(k, "War") || Equals(kind, n"HoodTaken") || Equals(kind, n"SpokeAtSitDown") {
    return 2;
  }
  if StrContains(k, "Rival") {
    return 4;
  }
  if Equals(kind, n"BagmanRobbed") || Equals(kind, n"RacketHit") || StrContains(k, "Tribute") || StrContains(k, "Paid") || StrContains(k, "Peace")
     || StrContains(k, "Bounty") || StrContains(k, "Tax") || Equals(kind, n"DealCrashed") {
    return 3;
  }
  return 1;
}

public func CBHudLogFilterWord(f: Int32) -> String {
  if f == 1 { return CBT(n"Cyberbane-Hud-LogFights"); }
  if f == 2 { return CBT(n"Cyberbane-Hud-LogCrew"); }
  if f == 3 { return CBT(n"Cyberbane-Hud-LogMoney"); }
  if f == 4 { return CBT(n"Cyberbane-Hud-LogRivals"); }
  return CBT(n"Cyberbane-Hud-LogAll");
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
    ArrayPush(parts, CBT(n"Cyberbane-Hud-WarmedToYou"));
  }
  if t.slight >= 0.05 {
    ArrayPush(parts, CBT(n"Cyberbane-Hud-TookOffence"));
  }
  if t.fear > 0.05 {
    ArrayPush(parts, CBT(n"Cyberbane-Hud-FearYouMore"));
  }
  if t.leaks > 0 {
    ArrayPush(parts, CBT(n"Cyberbane-Hud-GaveUpARival"));
  }
  if t.taxes > 0 {
    ArrayPush(parts, CBT(n"Cyberbane-Hud-PaidYouOff"));
  }
  if ArraySize(parts) == 0 {
    return "";
  }
  let line = CBT(n"Cyberbane-Hud-TodayFromTalkingToTheirPeople");
  let i = 0;
  while i < ArraySize(parts) {
    if i > 0 {
      line += i == ArraySize(parts) - 1 ? CBT(n"Cyberbane-CrewKit-And") : ", ";
    }
    line += parts[i];
    i += 1;
  }
  return line + ".";
}

// What street talk put in the file (Reactions/StreetTalk.reds), and the entry's own name for anything this file does
// not know how to say.
func CBHudTalkLogLine(sys: ref<CyberbaneSystem>, e: ref<CBLogEntry>, gang: String) -> String {
  let who = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-OneOf", [gang]) : CBT(n"Cyberbane-TalkTopics-Somebody");
  if Equals(e.kind, n"Informant") {
    let r = sys.FindRivalById(RoundF(e.value));
    let name = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : CBT(n"Cyberbane-Hud-OneOfTheirOwn");
    return CBTf(n"Cyberbane-Hud-YouLeanedOnUntilTheyGave", [s"\(who)", s"\(name)"]);
  }
  if Equals(e.kind, n"ShakeDown") {
    return CBTf(n"Cyberbane-Hud-YouShookDownForEb", [s"\(who)", s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"TalkWarm") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-TalkingToTheirPeopleWarmedTo", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-TalkingToPeopleWarmedThemTo");
  }
  if Equals(e.kind, n"TalkSlight") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-TookOffenceAtHowYouSpoke", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-PeopleTookOffenceAtHowYou");
  }
  if Equals(e.kind, n"TalkFear") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-LeaningOnTheirPeopleMadeFear", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-LeaningOnPeopleMadeTheStreet");
  }
  if Equals(e.kind, n"TalkBought") {
    return CBTf(n"Cyberbane-Hud-YouPaidEbForWhereA", [s"\(who)", s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"TalkFan") {
    return CBTf(n"Cyberbane-Hud-AFanStoodYouADrink", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"TalkToll") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouPaidEbToWalkTheir", [s"\(gang)", s"\(RoundF(e.value))"])
                            : CBTf(n"Cyberbane-Hud-YouPaidEbForSafePassage", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"BagmanRobbed") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouRobbedBagmanOfEb", [s"\(CBPossessive(gang))", s"\(RoundF(e.value))"]) : CBTf(n"Cyberbane-Hud-YouRobbedABagmanOfEb", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"Favour") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouDidAFavourForEb", [s"\(gang)", s"\(RoundF(e.value))"]) : CBT(n"Cyberbane-Hud-YouDidSomebodyAFavour");
  }
  if Equals(e.kind, n"Contract") {
    return CBTf(n"Cyberbane-Hud-YouDidAContractFor", [s"\(gang)", s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"MeetCrashed") {
    return CBT(n"Cyberbane-Hud-YouCrashedASitDownBetween");
  }
  if Equals(e.kind, n"ShotSurrendered") {
    return CBT(n"Cyberbane-Hud-YouShotSomebodyWhoHadGiven");
  }
  if Equals(e.kind, n"WordSent") {
    return CBT(n"Cyberbane-Hud-YouCalledOutARivalThey");
  }
  if Equals(e.kind, n"CalledOut") {
    return CBT(n"Cyberbane-Hud-ARivalCalledYouOutAnd");
  }
  if Equals(e.kind, n"RivalExiled") {
    return CBT(n"Cyberbane-Hud-YouRanARivalOutOf");
  }
  if Equals(e.kind, n"KinSworn") {
    return CBT(n"Cyberbane-Hud-FamilyOfARivalYouKilled");
  }
  if Equals(e.kind, n"Squeezed") {
    return CBTf(n"Cyberbane-Hud-YouMadeTalk", [s"\(who)"]);
  }
  if Equals(e.kind, n"FlawLearned") {
    let r = sys.FindRivalById(RoundF(e.value));
    let name = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : CBT(n"Cyberbane-RivalSystem-ARival-2");
    return CBTf(n"Cyberbane-Hud-YouLearntSFatalFlaw", [s"\(name)"]);
  }
  if Equals(e.kind, n"FlawKill") {
    return CBT(n"Cyberbane-Hud-ARivalDiedOfTheFatal");
  }
  if Equals(e.kind, n"Turned") {
    return CBTf(n"Cyberbane-Hud-YouTurnedIntoAnInformant", [s"\(who)"]);
  }
  if Equals(e.kind, n"InformantTip") {
    return CBT(n"Cyberbane-Hud-AnInformantOfYoursTextedA");
  }
  if Equals(e.kind, n"TalkCallOff") {
    return CBTf(n"Cyberbane-Hud-YouPaidEbToCallOff", [s"\(who)", s"\(RoundF(e.value))"]);
  }
  // the street.
  if Equals(e.kind, n"WitnessHushed") {
    return CBT(n"Cyberbane-Hud-YouPaidAWitnessToForget");
  }
  if Equals(e.kind, n"KeepWatch") {
    return CBTf(n"Cyberbane-Hud-YouPaidSomebodyEbToKeep", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"WannabeBeaten") {
    return CBT(n"Cyberbane-Hud-AKidSquaredUpToYou");
  }
  if Equals(e.kind, n"WannabeLost") {
    return CBT(n"Cyberbane-Hud-AKidSquaredUpToYou-2");
  }
  if Equals(e.kind, n"WannabeWalked") {
    return CBT(n"Cyberbane-Hud-AKidSquaredUpToYou-3");
  }
  if Equals(e.kind, n"WannabeShot") {
    return CBT(n"Cyberbane-Hud-YouShotAKidWhoCame");
  }
  // the codes.
  if Equals(e.kind, n"GuardedHurt") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouHurtPeopleLookAfter", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouHurtPeopleSomebodyLooksAfter");
  }
  if Equals(e.kind, n"LetGo") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouLetOneOfWalkWith", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouLetSomebodyWalkWithTheir");
  }
  // the price on V's head, the ladder and the corporations.
  if Equals(e.kind, n"BountyPosted") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-PutAPriceOnYourHead", [s"\(CBCapFirst(gang))", s"\(RoundF(e.value))"]) : CBTf(n"Cyberbane-Hud-SomebodyPutAPriceOnYour", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"BountyPaid") {
    return CBT(n"Cyberbane-Hud-YouPaidOffThePriceOn");
  }
  if Equals(e.kind, n"BountyPosterDown") {
    return CBT(n"Cyberbane-Hud-WhoeverPutThePriceOnYour");
  }
  if Equals(e.kind, n"BountyLifted") {
    return CBT(n"Cyberbane-Hud-ThePriceOnYourHeadCame");
  }
  if Equals(e.kind, n"HunterKilled") {
    return CBTf(n"Cyberbane-Hud-YouKilledABountyHunterRanked", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"HunterBeaten") {
    return CBTf(n"Cyberbane-Hud-YouBeatABountyHunterRanked", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"LadderRank") {
    return RoundF(e.value) == 1 ? CBT(n"Cyberbane-Hud-YouReachedTheTopOfThe") : CBTf(n"Cyberbane-Hud-YouClimbedToNumberOnThe", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"CorpWarned") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-WarnedYouOff", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-ACorporationWarnedYouOff");
  }
  if Equals(e.kind, n"CorpOffer") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-ACorporationOfferedYouEbTo", [s"\(RoundF(e.value))", s"\(gang)"]) : CBT(n"Cyberbane-Hud-ACorporationOfferedYouAContract");
  }
  // talk and allies.
  if Equals(e.kind, n"CrewLent") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-SentPeopleToWatchYourBack", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-AGangSentPeopleToWatch"); }
  if Equals(e.kind, n"OneOfTheirs") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouBecameOneOf", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouJoinedAGang"); }
  if Equals(e.kind, n"LeftGang") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouStoppedBeingOneOf", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouLeftAGang"); }
  if Equals(e.kind, n"DutyAsked") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YourGangAskedYouToPut", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YourGangAskedAFavour"); }
  if Equals(e.kind, n"DutySettled") { return e.value > 0.5 ? CBT(n"Cyberbane-Hud-YouCameThroughForYourGang") : CBT(n"Cyberbane-Hud-YouLetYourGangDown"); }
  if Equals(e.kind, n"RansomPaid") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-PaidEbToGetOneOf", [s"\(CBCapFirst(gang))", s"\(RoundF(e.value))"]) : CBT(n"Cyberbane-Hud-AGangPaidARansom"); }
  if Equals(e.kind, n"RansomRefused") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-RefusedYourRansomAndCameFor", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-AGangRefusedYourRansom"); }
  if Equals(e.kind, n"HandedOver") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouHandedAPrisonerTo", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouHandedOverAPrisoner"); }
  if Equals(e.kind, n"LieSpread") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouFedALieThroughThe", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouFedTheStreetALie"); }
  if Equals(e.kind, n"LieSold") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-SomebodySoldYourLieOutTo", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-SomebodySoldYouOut"); }
  if Equals(e.kind, n"InformantSaved") { return CBT(n"Cyberbane-Hud-YouSavedAnInformantFromTheir"); }
  if Equals(e.kind, n"InformantLost") { return CBT(n"Cyberbane-Hud-AnInformantOfYoursWasRun"); }
  if Equals(e.kind, n"ParleyPaid") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouPaidACrewOfTo", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouPaidOffACrew"); }
  if Equals(e.kind, n"ParleyScared") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouTalkedACrewOfInto", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouTalkedACrewDown"); }
  if Equals(e.kind, n"PhoneThreatWorked") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouThreatenedByTextAndThey", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-AThreatByTextMadeA"); }
  if Equals(e.kind, n"PhoneInsult") { return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouToldToComeAndTry", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouDaredAGangToCome"); }
  // a crew of V's own (Reactions/Crew.reds).
  let crewLine = CBCrewHistoryLine(sys, e);
  if StrLen(crewLine) > 0 {
    return crewLine;
  }
  // the Rivals' moments.
  if Equals(e.kind, n"StaredDown") || Equals(e.kind, n"FacedownWalked") || Equals(e.kind, n"DuelWon")
     || Equals(e.kind, n"CalledEven") || Equals(e.kind, n"Humiliated") || Equals(e.kind, n"Trophy")
     || Equals(e.kind, n"RivalReturned") || Equals(e.kind, n"BondVengeance") || Equals(e.kind, n"RivalEndedUp")
     || Equals(e.kind, n"UnderTheKnife") || Equals(e.kind, n"FeudSet") || Equals(e.kind, n"RivalFeud")
     || Equals(e.kind, n"LairMoved") || Equals(e.kind, n"RipperdocLead") {
    let rv = sys.FindRivalById(RoundF(e.value));
    let rn = IsDefined(rv) ? CBRivalDisplayName(sys.GetContent(), rv) : CBT(n"Cyberbane-RivalSystem-ARival-2");
    if Equals(e.kind, n"StaredDown") { return CBTf(n"Cyberbane-Hud-YouStaredDownAndTheirPeople", [s"\(rn)"]); }
    if Equals(e.kind, n"FacedownWalked") { return CBTf(n"Cyberbane-Hud-LetYouWalkAwayOnce", [s"\(CBCapFirst(rn))"]); }
    if Equals(e.kind, n"DuelWon") { return CBTf(n"Cyberbane-Hud-YouBeatOneOnOneWhile", [s"\(rn)"]); }
    if Equals(e.kind, n"CalledEven") { return CBTf(n"Cyberbane-Hud-YouAndCalledItEven", [s"\(rn)"]); }
    if Equals(e.kind, n"Humiliated") { return CBTf(n"Cyberbane-Hud-YouHumiliatedWhereTheyLay", [s"\(rn)"]); }
    if Equals(e.kind, n"Trophy") { return CBTf(n"Cyberbane-Hud-YouTookATrophyOff", [s"\(rn)"]); }
    if Equals(e.kind, n"RivalReturned") { return CBTf(n"Cyberbane-Hud-CameBackFromTheDead", [s"\(CBCapFirst(rn))"]); }
    if Equals(e.kind, n"BondVengeance") { return CBTf(n"Cyberbane-Hud-SworeVengeanceForSomebodyYouKilled", [s"\(CBCapFirst(rn))"]); }
    if Equals(e.kind, n"RivalEndedUp") { return CBTf(n"Cyberbane-Hud-LongGoneFromNightCityGot", [s"\(CBCapFirst(rn))"]); }
    if Equals(e.kind, n"UnderTheKnife") { return CBTf(n"Cyberbane-Hud-WentUnderTheKnifeForYou", [s"\(CBCapFirst(rn))"]); }
    if Equals(e.kind, n"FeudSet") { return CBTf(n"Cyberbane-Hud-YouSetARivalOn", [s"\(rn)"]); }
    if Equals(e.kind, n"LairMoved") { return CBTf(n"Cyberbane-Hud-SLookoutSawYouAndGot", [s"\(CBCapFirst(rn))"]); }
    if Equals(e.kind, n"RipperdocLead") { return CBTf(n"Cyberbane-Hud-YouHeardWhichRipperdocWasIn", [s"\(rn)"]); }
    return CBTf(n"Cyberbane-Hud-OneRivalKilledAnotherIsGone", [s"\(rn)"]);
  }
  if Equals(e.kind, n"StreetClash") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-WonAFightWithTheirEnemies", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-TwoGangsFoughtInTheStreet");
  }
  if Equals(e.kind, n"CorpContractDone") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-PaidYouEbForAJob", [s"\(CBCapFirst(gang))", s"\(RoundF(e.value))"]) : CBTf(n"Cyberbane-Hud-ACorporationPaidYouEbFor", [s"\(RoundF(e.value))"]);
  }
  // the hunt grows.
  if Equals(e.kind, n"Tracked") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-PlantedATrackerOnYou", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-SomebodyPlantedATrackerOnYou");
  }
  if Equals(e.kind, n"OpenSeason") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-DeclaredOpenSeasonOnYou", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-AGangDeclaredOpenSeasonOn");
  }
  if Equals(e.kind, n"OpenSeasonSurvived") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouSurvivedOpenSeason", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouSurvivedOpenSeason-2");
  }
  if Equals(e.kind, n"OpenSeasonEnded") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouEndedOpenSeasonByKilling", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouEndedAnOpenSeasonBy");
  }
  if Equals(e.kind, n"AmbushBeaten") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouWalkedThroughAmbushOnThe", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouWalkedThroughAnAmbush");
  }
  // being hunted.
  if Equals(e.kind, n"ScoutBribed") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouPaidScoutToSayThey", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouPaidAScoutToSay");
  }
  // the war.
  if Equals(e.kind, n"WeeklyCut") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-PaidYouYourCutEb", [s"\(CBCapFirst(gang))", s"\(RoundF(e.value))"]) : CBTf(n"Cyberbane-Hud-YouWerePaidYourCutEb", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"Backed") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouThrewInWith", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouPickedASideInThe");
  }
  if Equals(e.kind, n"Incited") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouSetOnTheirEnemiesWith", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouSetTwoGangsOnEach");
  }
  if Equals(e.kind, n"Truce") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-MadeATruceWithTheirEnemies", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-TwoGangsMadeATruceAgainst");
  }
  if Equals(e.kind, n"OwnStreet") {
    return CBT(n"Cyberbane-Hud-ADistrictBecameYours");
  }
  if Equals(e.kind, n"OwnToll") {
    return CBTf(n"Cyberbane-Hud-TheGangsPaidTheirWayThrough", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"PeaceFavour") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouDidAFavourAndThey", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-AFavourBoughtYouPeace");
  }
  if Equals(e.kind, n"ProtectionPaid") {
    return CBTf(n"Cyberbane-Hud-YouPaidTheClawsEbFor", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"ProtectionRefused") {
    return CBT(n"Cyberbane-Hud-YouDidnTPayTheClaws");
  }
  // the fights.
  if Equals(e.kind, n"Executed") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-ExecutedSomebodyAndNobodyStoppedThem", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-SomebodyWasExecutedAndNobodyStopped");
  }
  if Equals(e.kind, n"PrisonerSaved") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouSavedOneOfFromAn", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouStoppedAnExecution");
  }
  if Equals(e.kind, n"FugitiveCaught") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-RanDownTheOneTheyWere", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-AGangRanSomebodyDown");
  }
  if Equals(e.kind, n"FugitiveSheltered") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouSavedOneOfFromThe", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouSavedSomebodyFromAGang");
  }
  if Equals(e.kind, n"FrontLine") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-WonAStreetFightAndTook", [s"\(CBCapFirst(gang))"]) : CBT(n"Cyberbane-Hud-AStreetFightDecidedWhoHolds");
  }
  if Equals(e.kind, n"StoodWith") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouStoodWithInAStreet", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouPickedASideInA");
  }
  if Equals(e.kind, n"StoodWithLost") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouStoodWithInAStreet-2", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouPickedASideInA-2");
  }
  if Equals(e.kind, n"StruggleBacked") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouDecidedWhoRuns", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouDecidedWhoRunsAGang");
  }
  if Equals(e.kind, n"StruggleBoth") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouKilledBothOfWouldBe", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouKilledBothWouldBeLeaders");
  }
  // gang life.
  if Equals(e.kind, n"FuneralCrashed") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouShotUpFuneral", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouShotUpAFuneral");
  }
  if Equals(e.kind, n"PaidRespects") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouPaidYourRespectsAtFuneral", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouPaidYourRespectsAtA");
  }
  if Equals(e.kind, n"DealCrashed") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouTookTheGunsWereBuying", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouHitAnArmsDeal");
  }
  if Equals(e.kind, n"RacketHit") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouHitRacketForEb", [s"\(CBPossessive(gang))", s"\(RoundF(e.value))"]) : CBTf(n"Cyberbane-Hud-YouHitARacketForEb", [s"\(RoundF(e.value))"]);
  }
  if Equals(e.kind, n"EventCrashed") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouBrokeUpSomethingHadPlanned", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouBrokeUpAGangS");
  }
  if Equals(e.kind, n"ApexBeaten") {
    return StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouBeatApexSquadAllFour", [s"\(CBPossessive(gang))"]) : CBT(n"Cyberbane-Hud-YouBeatAnApexSquadAll");
  }
  return NameToString(e.kind);
}

// One entry as a sentence. This printed the entry's internal name and its raw number, so the
// file read "RivalCreated (CityCenter) 12", where 12 was a Rival's id.
func CBHudLogLine(sys: ref<CyberbaneSystem>, e: ref<CBLogEntry>, now: Float, opt asSentence: Bool) -> String {
  let gang = CBFactionLabel(e.faction);
  let gangCap = CBCapFirst(gang);
  let line = "";
  if Equals(e.kind, n"RivalCreated") {
    let r = sys.FindRivalById(RoundF(e.value));
    let who = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : CBT(n"Cyberbane-Telling-Somebody");
    line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-OfTookItPersonally", [s"\(who)", s"\(gang)"]) : CBTf(n"Cyberbane-Hud-TookItPersonally", [s"\(who)"]);
  } else {
    if Equals(e.kind, n"RivalSlain") {
      line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouPutDownARankRival", [s"\(RoundF(e.value))", s"\(gang)"])
                              : CBTf(n"Cyberbane-Hud-YouPutDownARankRival-2", [s"\(RoundF(e.value))"]);
    } else {
      if Equals(e.kind, n"RivalAmbushed") {
        line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouCaughtARankRivalFrom", [s"\(RoundF(e.value))", s"\(gang)"])
                                : CBTf(n"Cyberbane-Hud-YouCaughtARankRivalWhere", [s"\(RoundF(e.value))"]);
      } else {
      if Equals(e.kind, n"Deed") {
        line = CBT(n"Cyberbane-Hud-AJobOfYoursMadeThe");
      } else {
        if Equals(e.kind, n"Massacre") {
          line = CBTf(n"Cyberbane-Hud-PeopleAreStillTalkingAboutThe", [s"\(RoundF(e.value))"]);
        } else {
          if Equals(e.kind, n"BossKill") {
            line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouTookDownSomebodyWhoMattered", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-YouTookDownSomebodyWhoMattered-2");
          } else {
            if Equals(e.kind, n"ApexDown") {
              line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-YouPutDownOneOfApex", [CBPossessive(gang)]) : CBT(n"Cyberbane-Hud-YouPutDownOneOfAn");
            } else {
              if Equals(e.kind, n"Vendetta") {
                line = CBTf(n"Cyberbane-Hud-SworeAVendettaAgainstYou", [s"\(gangCap)"]);
              } else {
                if Equals(e.kind, n"Peace") {
                  line = CBTf(n"Cyberbane-Hud-YouPaidEbToCallIt", [s"\(gang)", s"\(RoundF(e.value))"]);
                } else {
                  if Equals(e.kind, n"Tribute") {
                    line = CBTf(n"Cyberbane-Hud-PaidYouEbToStayOn", [s"\(gangCap)", s"\(RoundF(e.value))"]);
                  } else {
                    if Equals(e.kind, n"Death") {
                      line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-PutYouDown", [s"\(gangCap)"]) : CBT(n"Cyberbane-Hud-SomebodyPutYouDown");
                    } else {
                      if Equals(e.kind, n"Friendly") {
                        line = CBTf(n"Cyberbane-Hud-DecidedYouAreAllRight", [s"\(gangCap)"]);
                      } else {
                        if Equals(e.kind, n"Allied") {
                          line = CBTf(n"Cyberbane-Hud-StartedTreatingYouLikeOneOf", [s"\(gangCap)"]);
                        } else {
                          if Equals(e.kind, n"TurfTaken") {
                            line = CBTf(n"Cyberbane-Hud-TookOverTheStreets", [s"\(gangCap)"]);
                          } else {
                            if Equals(e.kind, n"TurfPush") {
                              line = CBTf(n"Cyberbane-Hud-CameBackToTakeTheirStreets", [s"\(gangCap)"]);
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
  // A war one of V's crew started.
  if Equals(e.kind, n"CrewWarWon") {
    line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-OneOfYourCrewStartedA", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-OneOfYourCrewStartedA-2");
  }
  if Equals(e.kind, n"CrewWarLost") {
    line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-OneOfYourCrewWentTo", [s"\(gang)"]) : CBT(n"Cyberbane-Hud-OneOfYourCrewWentTo-2");
  }
  // The crew's wars, night by night (Reactions/GangWar.reds).
  let warLine = CBHubWarLogLine(e, gangCap);
  if StrLen(warLine) > 0 {
    line = warLine;
  }
  // A Rival somebody else killed (CBRivalSlain): before, every Rival's death was written as V's.
  if Equals(e.kind, n"RivalDied") {
    line = StrLen(gang) > 0 ? CBTf(n"Cyberbane-Hud-ARankRivalFromDiedAnd", [s"\(RoundF(e.value))", s"\(gang)"])
                            : CBTf(n"Cyberbane-Hud-ARankRivalDiedAndNot", [s"\(RoundF(e.value))"]);
  }
  // An add-on's reason (CyberbaneAPI.AdjustStanding): its key is the entry's kind, and reads as its own text.
  // Cyberbane's own kinds never carry a dash.
  if StrLen(line) == 0 && StrContains(NameToString(e.kind), "-") {
    line = CBTf(e.kind, [gang]);   // {0} is the faction's label (API level 3, FileHistoryFor)
  }
  let place = CBDistrictLabel(e.district);
  let ago = CBHudSince(now, e.at);
  // In a text (the morning brief): The row's form, " Heywood, 58m ago" with no stop, read as a sentence left hanging,
  // with the next one glued on.
  if asSentence {
    let tail = place;
    if StrLen(ago) > 0 {
      tail += StrLen(tail) > 0 ? CBTf(n"Cyberbane-Hud-Ago", [ago]) : ago;
    }
    if StrLen(tail) > 0 {
      line += " (" + tail + ")";
    }
    if StrLen(line) > 0 && !StrEndsWith(line, ".") && !StrEndsWith(line, "!") && !StrEndsWith(line, "?") {
      line += ".";
    }
    return line;
  }
  if StrLen(place) > 0 {
    line += "  " + place;
  }
  if StrLen(ago) > 0 {
    line += CBTf(n"Cyberbane-Hud-Ago", [ago]);
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
func CBDreadWord(civ: Float) -> String {
  if civ >= CBConfig.CivTierTerror() {
    return CBT(n"Cyberbane-Hud-PeopleRun");
  }
  if civ >= CBConfig.CivTierAfraid() {
    return CBT(n"Cyberbane-Hud-PeopleAreAfraid");
  }
  if civ >= CBConfig.CivTierUneasy() {
    return CBT(n"Cyberbane-Hud-PeopleAreUneasy");
  }
  if civ >= CBConfig.CivTierNotice() {
    return CBT(n"Cyberbane-Hud-PeopleNotice");
  }
  return CBT(n"Cyberbane-Hud-NobodyMinds");
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

// The tally's style lines: the main one, the share each has of everything V has done so far, and what builds each.
func CBStyleLine(sys: ref<CyberbaneSystem>) -> String {
  let acc = sys.GetArchetypeAccumulators();
  let total = 0.0;
  for v in acc {
    total += MaxF(v, 0.0);
  }
  let main = sys.GetPrimaryArchetypeIndex();
  let out = "";
  if main < 0 || total <= 0.0 {
    out += CBTf(n"Cyberbane-Hud-StyleNotSettled", [s"\(RoundF(total))", s"\(RoundF(CBConfig.ArchetypeMinTotal()))"]);
  } else {
    // Largest first, the main one at the head whatever the order, every style with a share of its own.
    let parts = "";
    let used: array<Int32>;
    ArrayPush(used, main);
    let n = 0;
    while n < ArraySize(acc) {
      let best = -1;
      let bestVal = 0.0;
      let i = 0;
      while i < ArraySize(acc) {
        if !ArrayContains(used, i) && acc[i] > bestVal {
          best = i;
          bestVal = acc[i];
        }
        i += 1;
      }
      if best >= 0 && RoundF(100.0 * bestVal / total) >= 1 {
        ArrayPush(used, best);
        parts += (StrLen(parts) > 0 ? ", " : "") + CBArchetypeName(best) + " " + s"\(RoundF(100.0 * bestVal / total))%";
      }
      n += 1;
    }
    let mainShare = RoundF(100.0 * MaxF(acc[main], 0.0) / total);
    out += StrLen(parts) > 0 ? CBTf(n"Cyberbane-Hud-StyleShares", [CBArchetypeName(main), s"\(mainShare)", parts])
                             : CBTf(n"Cyberbane-Hud-StyleOnly", [CBArchetypeName(main)]);
  }
  out += CBT(n"Cyberbane-Hud-StyleGuide");
  return out;
}

func CBArchetypeName(idx: Int32) -> String {
  switch idx {
    case 0: return CBT(n"Cyberbane-Hud-Butcher");
    case 1: return CBT(n"Cyberbane-Crew-Ghost");
    // "Operator", not "Professional".
    case 2: return CBT(n"Cyberbane-Hud-Operator");
    case 3: return CBT(n"Cyberbane-Hud-Chromed");
    case 4: return CBT(n"Cyberbane-Hud-Netrunner");
    case 5: return CBT(n"Cyberbane-Hud-Brawler");
    default: return CBT(n"Cyberbane-Hud-Undefined");
  }
}

// "Disciplined", not "Professional".
func CBCodeLabel(code: Float) -> String {
  if code >= 40.0 {
    return CBT(n"Cyberbane-Hud-Disciplined");
  }
  if code <= -40.0 {
    return CBT(n"Cyberbane-Traits-Cyberpsycho");
  }
  return CBT(n"Cyberbane-Hud-Mixed");
}

func CBPostureName(posture: ECBPosture) -> String {
  switch posture {
    case ECBPosture.Allied: return CBT(n"Cyberbane-CrewBanner-Allied");
    case ECBPosture.Friendly: return CBT(n"Cyberbane-Hud-Friendly");
    case ECBPosture.Neutral: return CBT(n"Cyberbane-CrewBanner-Neutral");
    case ECBPosture.Hostile: return CBT(n"Cyberbane-CrewBanner-Hostile");
    case ECBPosture.Vendetta: return CBT(n"Cyberbane-Hud-Vendetta");
    default: return CBT(n"Cyberbane-CrewBanner-Neutral");
  }
}

func CBRivalStateName(state: Int32) -> String {
  if state == EnumInt(ECBRivalState.Hunting) {
    return CBT(n"Cyberbane-Hud-HuntingYou");
  }
  if state == EnumInt(ECBRivalState.Active) {
    return CBT(n"Cyberbane-Hud-AtLarge");
  }
  // Said as what they are: one who owes V their life read "quiet", the word for one keeping their head down. Their
  // life, in full: "owes you" alone reads as money.
  if state == EnumInt(ECBRivalState.Debtor) {
    return CBT(n"Cyberbane-Hud-OwesYouTheirLife");
  }
  return CBT(n"Cyberbane-Hud-Quiet-2");
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
      out += (n > 0 ? ", " : "") + CBDisplay(t.display);
      n += 1;
    }
  }
  return out;
}

// What V's clothes are doing, under the chrome bar: what they cover, a mask, and whose gear fools whom. This is it.
func CBHudWornLine(sys: ref<CyberbaneSystem>) -> String {
  if !CBClothingCounts() {
    return CBT(n"Cyberbane-Hud-ClothesAreNotReadModSettings");
  }
  let worn = sys.GetWorn();
  if !IsDefined(worn) {
    return CBT(n"Cyberbane-Hud-WhatAStrangerClocksFromAcross");
  }
  let parts = "";
  if worn.arms { parts = CBT(n"Cyberbane-Hud-Arms"); }
  if worn.legs { parts = StrLen(parts) > 0 ? CBTf(n"Cyberbane-Hud-Legs", [parts]) : CBT(n"Cyberbane-Hud-Legs-2"); }
  if worn.face { parts = StrLen(parts) > 0 ? CBTf(n"Cyberbane-Hud-Eyes", [parts]) : CBT(n"Cyberbane-Hud-Eyes-2"); }
  let line = StrLen(parts) > 0 ? CBTf(n"Cyberbane-Hud-Covered", [parts]) : CBT(n"Cyberbane-Hud-NothingYouWearCoversYourChrome");
  if worn.masked {
    line += CBT(n"Cyberbane-Standing-Masked");
  } else {
    if worn.twrRead && worn.twrFace >= 0.05 {
      line += CBTf(n"Cyberbane-Hud-FaceHidden", [s"\(RoundF(worn.twrFace * 100.0))"]);
    }
  }
  let gang = CBFactionLabel(sys.GetDisguiseFaction());
  if StrLen(gang) > 0 {
    line += worn.twrRead ? CBTf(n"Cyberbane-Hud-PassingFor", [s"\(gang)", s"\(RoundF(sys.GetDisguiseStrength() * 100.0))"]) : CBTf(n"Cyberbane-Standing-Colours", [gang]);
  }
  // Whose reading this is, when it is not Cyberbane's own.
  if worn.twrRead {
    line += CBT(n"Cyberbane-Hud-TheyWillRememberSReading");
  } else {
    if CBRememberReadsDisguises() {
      let rtWhy = CyberbaneRuntime.Get();
      let why = IsDefined(rtWhy) ? rtWhy.TwrDisguiseWhy() : "";
      if StrLen(why) > 0 {
        line += CBTf(n"Cyberbane-Hud-TheyWillRememberSDisguisesCould", [why]);
      } else {
        line += CBT(n"Cyberbane-Hud-TheyWillRememberSDisguisesCould-2");
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

// ---- The Hub's pictures and tiles --------------------------------------------------------------------------

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
  return CBT(n"Cyberbane-Hud-ShowAsCards");
}

// One word for a crew member's state, as a colour.
public func CBCrewStateTint(state: String) -> HDRColor {
  if Equals(state, CBCrewWordWithYou()) { return CBHudGreen(); }
  if StrBeginsWith(state, CBCrewWordHurt()) { return CBHudRed(); }
  if Equals(state, CBCrewWordRestless()) { return CBHudAmber(); }
  if Equals(state, CBCrewWordResting()) { return CBHudGrey(); }
  return CBHudCyan();
}

// ---- The map: each district roughly where it lies (index order of CBDistrictAt) --------------------------------------
//
// Watson at the top, City Center under it and Westbrook to its east, Heywood below with Santo Domingo to its east,
// Pacifica to the south-west with Dogtown at its foot, and the Badlands out east. The roads join neighbours.

// The cards: four to a row across the page, the gangs' grid three rows and the corporations' small row, the districts
// two rows.
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
