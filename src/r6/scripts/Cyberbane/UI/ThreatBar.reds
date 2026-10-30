// Cyberbane - The threat bars (spec §12)
//
// A stack of bars across the top of the screen, one per enemy that is actually somebody: a
// Rival shows their name, and each member of an apex squad shows their role. The point is that
// you can tell at a glance which of the people shooting at you is a Rival, which four are the
// apex squad, and which are ordinary crew with no bar at all.
//
// This is drawn by Cyberbane rather than handed to the game's own boss bar, and the reason is
// no longer a guess. The game's own controller is at
// `cyberpunk/UI/widgets/healthbar/bossHealthBar.script`, and `AddBoss` opens with:
//
//     if( !boss || ( !boss.IsBoss() && boss.GetNPCRarity() != gamedataNPCRarity.MaxTac ) )
//         return;
//
// Everything Cyberbane spawns fails that test, because boss-ness lives on the character record
// and there is no setter for it. So every `AddBoss` call Cyberbane ever made returned without
// drawing anything, which is why no bar was ever seen. That controller also only draws one bar
// at a time (`m_boss`, with the rest queued in `m_bossPuppets`), so it could not show a squad
// even if it accepted them.
//
// For the record, so nobody spends another evening on it: NPC rarity has no setter;
// `canHaveBossHealthbar` is a TweakDB flat and `TweakDBManager` is a RED4ext API with no
// redscript binding; and `UI_Targeting.BossTarget`, `HighlightInstance.isBoss`,
// `gamedataNPCType.Boss`, `Character_Record.NPCType()` and `TargetTrackerComponent.SetThreat`
// do not exist on 2.5. Every one was probed.
//
// Crash safety: the rows are created once on an inkHUDLayer virtual window and only ever have
// their size, text and visibility set afterwards. Targets are held weakly and re-checked
// through CBNpcSafe on every update, so a dead or streamed-out one drops off the stack rather
// than being read.

// One bar: a line of text with a health track under it.
public class CBThreatRow {
  public let root: ref<inkCanvas>;
  public let fill: ref<inkRectangle>;
  public let text: ref<inkText>;
}

public class CBThreatBar {
  private let m_rows: array<ref<CBThreatRow>>;
  private let m_built: Bool;
  // Parallel arrays rather than one struct per entry, for the same reason the rest of the mod
  // does it: nothing here is ever nested inside a persistent class.
  private let m_targets: array<wref<ScriptedPuppet>>;
  private let m_ids: array<EntityID>;
  private let m_labels: array<String>;

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
    let width = CBConfig.ThreatBarWidth();
    let stride = CBConfig.ThreatBarRowStride();

    let i = 0;
    while i < CBConfig.ThreatBarRows() {
      let root = new inkCanvas();
      root.SetName(n"cyberbaneThreatRow");
      root.SetAnchor(inkEAnchor.TopCenter);
      root.SetAnchorPoint(new Vector2(0.5, 0.0));
      root.SetMargin(new inkMargin(0.0, CBConfig.ThreatBarTopMargin() + Cast<Float>(i) * stride,
                                   0.0, 0.0));
      root.SetSize(new Vector2(width, stride));
      root.SetVisible(false);

      let text = new inkText();
      text.SetFontFamily(font);
      text.SetFontSize(18);
      text.SetAnchor(inkEAnchor.TopLeft);
      text.SetTintColor(new HDRColor(2.40, 2.40, 2.60, 1.0));
      text.SetText("");
      text.Reparent(root);

      // The track, then the fill on top of it.
      let track = new inkRectangle();
      track.SetAnchor(inkEAnchor.TopLeft);
      track.SetMargin(new inkMargin(0.0, 24.0, 0.0, 0.0));
      track.SetSize(new Vector2(width, 6.0));
      track.SetTintColor(new HDRColor(0.10, 0.03, 0.04, 0.85));
      track.Reparent(root);

      let fill = new inkRectangle();
      fill.SetAnchor(inkEAnchor.TopLeft);
      fill.SetMargin(new inkMargin(0.0, 24.0, 0.0, 0.0));
      fill.SetSize(new Vector2(width, 6.0));
      fill.SetTintColor(new HDRColor(2.60, 0.25, 0.30, 1.0));
      fill.Reparent(root);

      root.Reparent(win);

      let row = new CBThreatRow();
      row.root = root;
      row.fill = fill;
      row.text = text;
      ArrayPush(this.m_rows, row);
      i += 1;
    }
    this.m_built = true;
  }

  // Put somebody on the stack, or update the line they already have.
  public func Track(puppet: wref<ScriptedPuppet>, label: String) -> Void {
    if !IsDefined(puppet) {
      return;
    }
    let id = puppet.GetEntityID();
    if !EntityID.IsDefined(id) {
      return;
    }
    let i = 0;
    while i < ArraySize(this.m_ids) {
      if Equals(this.m_ids[i], id) {
        this.m_labels[i] = label;
        return;
      }
      i += 1;
    }
    // Full. The stack is sized for an apex squad plus a Rival, which is the most that can be on
    // you at once, so this only happens if something upstream has gone wrong.
    if ArraySize(this.m_ids) >= CBConfig.ThreatBarRows() {
      return;
    }
    if !this.EnsureBuilt() {
      // Logged because a bar that silently fails to build is indistinguishable from one that
      // was never asked for, and telling those two apart from the outside is impossible.
      CBLog.Info(n"UI", "Threat bar could not be built (no ink layer yet).");
      return;
    }
    ArrayPush(this.m_targets, puppet);
    ArrayPush(this.m_ids, id);
    ArrayPush(this.m_labels, label);
    CBLog.Info(n"UI", s"Threat bar tracking \(label).");
  }

  public func Hide() -> Void {
    ArrayClear(this.m_targets);
    ArrayClear(this.m_ids);
    ArrayClear(this.m_labels);
    let i = 0;
    while i < ArraySize(this.m_rows) {
      if IsDefined(this.m_rows[i].root) {
        this.m_rows[i].root.SetVisible(false);
      }
      i += 1;
    }
  }

  // Once per fast tick. Drops anyone who is gone, then redraws the rows that are left.
  public func Update(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if ArraySize(this.m_targets) == 0 {
      return;
    }
    let pools = GameInstance.GetStatPoolsSystem(game);
    if !IsDefined(pools) || !this.EnsureBuilt() {
      return;
    }
    // Backwards, so erasing an entry does not skip the next one.
    let i = ArraySize(this.m_targets) - 1;
    while i >= 0 {
      // CBNpcSafe covers attachment and the post-spawn settling window, so a target that is
      // being torn down is never read.
      if !CBNpcSafe(sys, this.m_targets[i]) || !CBStillStanding(this.m_targets[i]) {
        ArrayErase(this.m_targets, i);
        ArrayErase(this.m_ids, i);
        ArrayErase(this.m_labels, i);
      }
      i -= 1;
    }

    let width = CBConfig.ThreatBarWidth();
    let shown = ArraySize(this.m_targets);
    let r = 0;
    while r < ArraySize(this.m_rows) {
      let row = this.m_rows[r];
      if r < shown {
        let pct = pools.GetStatPoolValue(Cast<StatsObjectID>(this.m_ids[r]),
                                         gamedataStatPoolType.Health, false);
        let frac = ClampF(pct / 100.0, 0.0, 1.0);
        if IsDefined(row.text) {
          row.text.SetText(this.m_labels[r]);
        }
        if IsDefined(row.fill) {
          row.fill.SetSize(new Vector2(width * frac, 6.0));
        }
        if IsDefined(row.root) {
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
}

// Does the player want this at all?
public func CBThreatBarOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && rt.HasSettings() && rt.GetSettings().apexBossBar;
}
