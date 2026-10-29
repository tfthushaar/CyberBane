// Cyberbane - The threat bar (spec §12)
//
// A boss bar across the top of the screen for whoever is currently hunting you: an apex squad
// enforcer, or a Rival far enough up the ladder to deserve it.
//
// This is drawn by Cyberbane rather than handed to the game's own boss bar, and that is a
// deliberate retreat after proving the engine route does not exist on this patch. For the
// record, so nobody spends another evening on it:
//
//   - `BossHealthBarGameController.AddBoss(ref<NPCPuppet>)` is real and callable, but the
//     controller is only reachable by wrapping its `OnInitialize`, and whether that ever runs
//     depends on the HUD constructing it, which it does not appear to do for an ordinary fight.
//   - NPC rarity is what the game keys the bar off, and there is no setter.
//   - `canHaveBossHealthbar` turns out to be a TweakDB flat on the character record. Readable,
//     and not writable: `TweakDBManager` is a RED4ext API with no redscript binding. A TweakXL
//     file cannot help either, because the records Cyberbane spawns are sampled from whoever V
//     has actually fought and are not known when the mod is built.
//   - `UI_Targeting.BossTarget`, `HighlightInstance.isBoss`, `gamedataNPCType.Boss`,
//     `Character_Record.NPCType()` and `TargetTrackerComponent.SetThreat` were all suggested as
//     routes and **none of them exist on 2.5**. Every one was probed.
//
// So: our own widget, built the same way the Hub is, which is a thing that already works.
//
// Crash safety: everything is created once on an inkHUDLayer virtual window and only ever has
// its size and text set afterwards. The tracked puppet is held weakly and re-checked through
// CBNpcSafe on every update, so a dead or streamed-out target hides the bar rather than being
// read.

public class CBThreatBar {
  private let m_root: ref<inkCanvas>;
  private let m_fill: ref<inkRectangle>;
  private let m_name: ref<inkText>;
  private let m_kind: ref<inkText>;
  private let m_built: Bool;
  private let m_target: wref<ScriptedPuppet>;
  private let m_shown: Bool;

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
    root.SetName(n"cyberbaneThreatBar");
    root.SetAnchor(inkEAnchor.TopCenter);
    root.SetAnchorPoint(new Vector2(0.5, 0.0));
    root.SetMargin(new inkMargin(0.0, 90.0, 0.0, 0.0));
    root.SetSize(new Vector2(CBConfig.ThreatBarWidth(), 64.0));
    root.SetVisible(false);

    let kind = new inkText();
    kind.SetFontFamily(font);
    kind.SetFontSize(18);
    kind.SetAnchor(inkEAnchor.TopLeft);
    kind.SetTintColor(new HDRColor(2.60, 0.30, 0.35, 1.0));
    kind.SetText("");
    kind.Reparent(root);

    let name = new inkText();
    name.SetFontFamily(font);
    name.SetFontSize(26);
    name.SetAnchor(inkEAnchor.TopLeft);
    name.SetMargin(new inkMargin(0.0, 20.0, 0.0, 0.0));
    name.SetTintColor(new HDRColor(2.40, 2.40, 2.60, 1.0));
    name.SetText("");
    name.Reparent(root);

    // The track, then the fill on top of it.
    let track = new inkRectangle();
    track.SetAnchor(inkEAnchor.TopLeft);
    track.SetMargin(new inkMargin(0.0, 52.0, 0.0, 0.0));
    track.SetSize(new Vector2(CBConfig.ThreatBarWidth(), 8.0));
    track.SetTintColor(new HDRColor(0.10, 0.03, 0.04, 0.85));
    track.Reparent(root);

    let fill = new inkRectangle();
    fill.SetAnchor(inkEAnchor.TopLeft);
    fill.SetMargin(new inkMargin(0.0, 52.0, 0.0, 0.0));
    fill.SetSize(new Vector2(CBConfig.ThreatBarWidth(), 8.0));
    fill.SetTintColor(new HDRColor(2.60, 0.25, 0.30, 1.0));
    fill.Reparent(root);

    root.Reparent(win);

    this.m_root = root;
    this.m_fill = fill;
    this.m_name = name;
    this.m_kind = kind;
    this.m_built = true;
  }

  // Point the bar at somebody. Passing null clears it.
  public func Track(puppet: wref<ScriptedPuppet>, kindLabel: String, displayName: String) -> Void {
    this.m_target = puppet;
    if !this.EnsureBuilt() {
      return;
    }
    if IsDefined(this.m_kind) {
      this.m_kind.SetText(kindLabel);
    }
    if IsDefined(this.m_name) {
      this.m_name.SetText(displayName);
    }
  }

  public func Hide() -> Void {
    this.m_target = null;
    if this.m_shown && IsDefined(this.m_root) {
      this.m_root.SetVisible(false);
      this.m_shown = false;
    }
  }

  // Once per fast tick. Reads the target's health and resizes the fill.
  public func Update(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if !IsDefined(this.m_target) {
      this.Hide();
      return;
    }
    // CBNpcSafe covers attachment and the post-spawn settling window, so a target that is
    // being torn down is never read.
    if !CBNpcSafe(sys, this.m_target) || this.m_target.IsDead() {
      this.Hide();
      return;
    }
    let pools = GameInstance.GetStatPoolsSystem(game);
    if !IsDefined(pools) {
      this.Hide();
      return;
    }
    if !this.EnsureBuilt() {
      return;
    }
    let pct = pools.GetStatPoolValue(Cast<StatsObjectID>(this.m_target.GetEntityID()),
                                     gamedataStatPoolType.Health, false);
    let frac = ClampF(pct / 100.0, 0.0, 1.0);
    if IsDefined(this.m_fill) {
      this.m_fill.SetSize(new Vector2(CBConfig.ThreatBarWidth() * frac, 8.0));
    }
    if !this.m_shown && IsDefined(this.m_root) {
      this.m_root.SetVisible(true);
      this.m_shown = true;
    }
  }
}

// Does the player want this at all?
public func CBThreatBarOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && rt.HasSettings() && rt.GetSettings().apexBossBar;
}
