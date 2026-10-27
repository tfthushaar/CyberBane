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
  // Names the district or gang the title is actually about (Model/TitleNaming.reds).
  return CBTitleDisplayById(sys, sys.GetContent(), id);
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
  let district = NameToString(CBEventDistrict(sys, game));
  let codeLabel = CBCodeLabel(sys.GetCode());

  let chrome = RoundF(score.GetChromeVisible());

  let out = s"RENOWN            \(renown)    ( \(tier) )\n";
  out += "    How widely Night City knows your name. Jobs, fights and notable\n";
  out += "    deeds spread it outward from where they happened.\n\n";
  out += s"DREAD             \(dread)    ( the street reads it as \(dreadCiv) )\n";
  out += "    How frightening you are. This is what actually makes people back off.\n\n";
  out += s"VISIBLE CHROME    \(chrome)\n";
  out += "    How much of your cyberware a stranger can see from across the street.\n";
  out += "    Arms read loudest, then eyes, skin and legs.\n\n";
  out += s"CODE              \(code)    ( \(codeLabel) )\n";
  out += "    How you do the work. Clean and controlled, or one bad night from\n";
  out += "    going cyberpsycho.\n\n";
  out += s"STREET CRED  \(cred)        STYLE  \(style)        HERE  \(district)\n\n";
  let stats = sys.GetStats();
  if IsDefined(stats) {
    let apexMult = RoundF(CBConfig.ApexHealthMultBase()
      + ClampF(score.GetMenace() / 100.0, 0.0, 1.0) * CBConfig.ApexHealthMultRange());
    out += s"APEX HUNTERS PUT DOWN   \(stats.apexKills)        RIVALS PUT DOWN   \(stats.rivalsSlain)\n";
    out += "    Keep hitting one gang and they send an apex hunter after you. They are\n";
    out += s"    sized to your build: right now roughly \(apexMult)x what their rank and file take.\n\n";
    out += s"WORK NOBODY SAW   \(stats.unattributed)\n";
    out += "    Kills with no living witness close by. They build almost no reputation you\n";
    out += "    can claim, because nobody can say it was you - but the bodies still frighten\n";
    out += "    the district. Leave people alive and your name travels instead.\n\n";
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
  let chromeVisible = score.GetChromeVisible();
  let eff = MaxF(score.GetDreadCiv(), chromeVisible) + score.GetMenace() * CBConfig.MenaceFearWeight();
  let reach = 1.0 + (chromeVisible / 100.0) * CBConfig.ChromeNoticeRangeBonus();
  if eff >= CBConfig.CivTierTerror() {
    let r = RoundF(CBConfig.CivFleeRadius() * reach);
    return s"Right now: people break and run when you come within \(r) metres.";
  }
  if eff >= CBConfig.CivTierAfraid() {
    let r = RoundF(CBConfig.CivCowerRadius() * reach);
    return s"Right now: people flinch and give way within \(r) metres. Push it further and they run.";
  }
  let need = RoundF(CBConfig.CivTierAfraid() - eff);
  return s"Right now: nobody is backing off yet. You are about \(need) short - more visible chrome, a harder reputation, or a bigger build.";
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
    return "No gang has formed an opinion of you yet. Work in their territory and that changes.";
  }
  let out = "How each gang reads you. Standing is whether they like you, fear is how badly\n";
  out += "they want to avoid you, respect is whether they rate you as a professional.\n\n";
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
      out += CBHudPad(NameToString(fs.id), 15) + CBHudPad(posture, 11)
        + s"standing \(st)   fear \(fear)   respect \(resp)   kills \(fs.kills)";
      // While a gang has a vendetta with you they put a price on your head (spec §9.9).
      if Equals(postureEnum, ECBPosture.Vendetta) {
        let bounty = 2000 + 200 * fs.kills;
        out += s"   bounty \(bounty)eb";
      }
      out += "\n";
      shown += 1;
    }
  }
  out += "\nWary means they keep an eye on you. Hostile means they draw on sight.\n";
  out += "Vendetta means they hunt you and put a price on your head.\n";
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

func CBHudRivals(sys: ref<CyberbaneSystem>) -> String {
  let rivals = sys.GetRivals();
  let content = sys.GetContent();
  let out = "People who got away, or got back up. They climb the ranks while you are busy\n";
  out += "elsewhere, and sooner or later they come looking for you.\n\n";
  let shown = 0;
  let i = 0;
  while i < ArraySize(rivals) && shown < 10 {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      let name = IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival";
      out += name + "\n";
      out += "    " + CBHudPad(NameToString(r.faction), 14) + s"rank \(r.rank)   "
           + CBHudPad(CBRivalStateName(r.state), 10) + CBRivalSourceLine(r.source) + "\n";
      shown += 1;
    }
  }
  if shown == 0 {
    return "No active rivals yet.\n\nLeave someone alive after you put them down, or let a wounded\nenemy get away, and one of them will come back with your name.";
  }
  out += "\nHunting means they are actively looking for you. Every time one escapes\n";
  out += "you it comes back a rank higher and harder to put down.";
  return out;
}

func CBHudTitles(sys: ref<CyberbaneSystem>) -> String {
  let unlocked = sys.GetUnlockedTitles();
  let content = sys.GetContent();
  if ArraySize(unlocked) == 0 {
    return "No titles earned yet.";
  }
  let active = sys.GetActiveTitle();
  let out = "EARNED:\n";
  let i = 0;
  while i < ArraySize(unlocked) && i < 16 {
    let id = unlocked[i];
    // Names the district or gang the title is actually about (Model/TitleNaming.reds).
    let name = CBTitleDisplayById(sys, content, id);
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
