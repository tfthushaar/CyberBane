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

public func CBHudTabName(tab: Int32) -> String {
  switch tab {
    case 1: return "LEGEND";
    case 2: return "FACTIONS";
    case 3: return "DISTRICTS";
    case 4: return "RIVALS";
    case 5: return "TITLES";
    case 6: return "LEGEND LOG";
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

  public func IsOpen() -> Bool {
    return this.m_tab != 0;
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
    panel.SetSize(new Vector2(1100.0, 760.0));
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
    stripe.SetSize(new Vector2(5.0, 760.0));
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
    body.SetFontSize(24);
    body.SetTintColor(new HDRColor(0.82, 0.88, 0.93, 1.0));
    body.SetAnchor(inkEAnchor.TopLeft);
    body.SetMargin(new inkMargin(50.0, 206.0, 0.0, 0.0));
    body.SetWrapping(true, 1004.0);
    body.SetSize(new Vector2(1004.0, 494.0));
    body.Reparent(panel);
    this.m_body = body;

    let footer = new inkText();
    footer.SetFontFamily(font);
    footer.SetFontStyle(n"Medium");
    footer.SetFontSize(18);
    footer.SetTintColor(new HDRColor(0.60, 0.65, 0.70, 0.75));
    footer.SetAnchor(inkEAnchor.TopLeft);
    footer.SetMargin(new inkMargin(50.0, 714.0, 0.0, 0.0));
    footer.SetText("Press the Hub key to cycle tabs, again on the last to close.  Settings: Pause > Mods > Cyberbane.");
    footer.Reparent(panel);

    root.Reparent(win);
    this.m_root = root;
    this.m_built = true;
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
    this.m_tabline.SetText(CBHudTabName(this.m_tab) + "        [ Hub key: next ]");
    this.m_body.SetText(CBHudBody(sys, game, this.m_tab));
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
  let content = CyberbaneContent.Get();
  if IsDefined(content) {
    let def = content.GetTitle(id);
    if IsDefined(def) {
      return def.display;
    }
  }
  return NameToString(id);
}

func CBHudBody(sys: ref<CyberbaneSystem>, game: GameInstance, tab: Int32) -> String {
  switch tab {
    case 1: return CBHudLegend(sys, game);
    case 2: return CBHudFactions(sys);
    case 3: return CBHudDistricts(sys);
    case 4: return CBHudRivals(sys);
    case 5: return CBHudTitles(sys);
    case 6: return CBHudLog(sys);
    default: return "";
  }
}

func CBHudLegend(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return "No data yet.";
  }
  let renown = RoundF(score.GetRenown());
  let tier = CBTierName(EnumInt(score.GetTier()));
  let dread = RoundF(score.GetDread());
  let dreadCiv = RoundF(score.GetDreadCiv());
  let code = RoundF(sys.GetCode());
  let cred = RoundF(CBPlayerStreetCred(game));
  let style = CBArchetypeName(sys.GetPrimaryArchetypeIndex());
  let district = NameToString(CBCurrentDistrict(game));
  let codeLabel = CBCodeLabel(sys.GetCode());

  let out = s"RENOWN        \(renown)        ( \(tier) )\n";
  out += s"DREAD         \(dread)        FEAR, CIVILIAN   \(dreadCiv)\n";
  out += s"CODE          \(code)        ( \(codeLabel) )\n";
  out += s"STREET CRED   \(cred)\n";
  out += s"STYLE         \(style)\n";
  out += s"DISTRICT      \(district)\n\n";
  out += CBHudDreadReason(sys);
  return out;
}

// Plain-language line: what is driving V's Dread the most (spec §12.1).
func CBHudDreadReason(sys: ref<CyberbaneSystem>) -> String {
  let score = sys.GetScore();
  let k = CBKillDreadComponent(sys.GetKillDreadPoints());
  let x = CBDeedDreadComponent(sys.GetDeedDreadPoints());
  let h = CBHeatDreadComponent(sys.GetHeatPoints());
  let c = score.GetChrome();
  let l = score.GetLook();

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
  let score = sys.GetScore();
  let states = sys.GetFactionStates();
  if ArraySize(states) == 0 {
    return "No faction has formed an opinion of you yet.";
  }
  let out = "";
  let shown = 0;
  let i = 0;
  while i < ArraySize(states) && shown < 13 {
    let fs = states[i];
    i += 1;
    if IsDefined(fs) {
      let postureEnum = score.GetPosture(fs.id);
      let posture = CBPostureName(postureEnum);
      let st = RoundF(fs.standing);
      let fear = RoundF(score.GetFactionFear(fs.id));
      let resp = RoundF(score.GetFactionRespect(fs.id));
      out += CBHudPad(NameToString(fs.id), 16) + CBHudPad(posture, 11)
        + s"S \(st)   F \(fear)   R \(resp)   kills \(fs.kills)";
      // While a gang has a vendetta with you they put a price on your head (spec §9.9).
      if Equals(postureEnum, ECBPosture.Vendetta) {
        let bounty = 2000 + 200 * fs.kills;
        out += s"   bounty \(bounty)eb";
      }
      out += "\n";
      shown += 1;
    }
  }
  out += "\n[ Shift + Hub key ]  buy off the worst gang you can.";
  return out;
}

func CBHudDistricts(sys: ref<CyberbaneSystem>) -> String {
  let states = sys.GetDistrictStates();
  if ArraySize(states) == 0 {
    return "Your name has not travelled to any district yet.";
  }
  let out = "";
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

func CBHudRivals(sys: ref<CyberbaneSystem>) -> String {
  let rivals = sys.GetRivals();
  let content = CyberbaneContent.Get();
  let out = "";
  let shown = 0;
  let i = 0;
  while i < ArraySize(rivals) && shown < 12 {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      let name = IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival";
      out += name + "  -  " + NameToString(r.faction) + s"  -  rank \(r.rank)  -  " + CBRivalStateName(r.state) + "\n";
      shown += 1;
    }
  }
  if shown == 0 {
    return "No active rivals. Leave survivors and that will change.";
  }
  return out;
}

func CBHudTitles(sys: ref<CyberbaneSystem>) -> String {
  let unlocked = sys.GetUnlockedTitles();
  let content = CyberbaneContent.Get();
  if ArraySize(unlocked) == 0 {
    return "No titles earned yet.";
  }
  let active = sys.GetActiveTitle();
  let out = "EARNED:\n";
  let i = 0;
  while i < ArraySize(unlocked) && i < 16 {
    let id = unlocked[i];
    let name = NameToString(id);
    if IsDefined(content) {
      let def = content.GetTitle(id);
      if IsDefined(def) {
        name = def.display;
      }
    }
    let mark = Equals(id, active) ? "  <- active" : "";
    out += "  " + name + mark + "\n";
    i += 1;
  }
  if Equals(active, n"") {
    out += "\nActive title: Auto (highest earned).";
  }
  out += "\n[ Ctrl + Hub key ]  cycle the active title / Auto.";
  return out;
}

func CBHudLog(sys: ref<CyberbaneSystem>) -> String {
  let log = sys.GetLog();
  let n = ArraySize(log);
  if n == 0 {
    return "Nothing logged yet.";
  }
  let out = "";
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
    return "Mad Dog";
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
