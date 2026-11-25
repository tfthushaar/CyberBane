// Cyberbane - The Hub as a tab of the game's menu
//
// The row across the top of the game's menu (Cyberware, Inventory, Map, Character, Journal) is drawn
// from a list, one label per entry, so an entry on that list is a real tab: the same label, the same
// underline, reached by the same keys and mouse as the others.

// What tells the Stats screen it is being opened for Cyberbane.
public class CBHubTabData {
  public let opened: Bool;
}

// An identifier the game's list will never use: its items stop at HubMenuItems.Count.
public func CBHubTabId() -> Int32 = 7731
public func CBHubTabScreen() -> CName = n"temp_stats"
public func CBHubTabLabel() -> String = CBT(n"Cyberbane-HubTab-CYBERBANE")

public func CBHubAsGameMenuTab() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || !rt.GetSettings().hubInPauseMenu;
}

// The entry goes in where the hub hands its row to the screen, not where the game builds the list. Both hubs pass their
// row through AddMenus on the panel that draws it, whoever built it.
@wrapMethod(SubMenuPanelLogicController)
public func AddMenus(const selectedMenu: script_ref<MenuData>, const menuDataArray: script_ref<array<MenuData>>,
                     opt subMenuData: MenuData, opt forceRefreshLines: Bool) -> Void {
  if !CBHubAsGameMenuTab() {
    wrappedMethod(selectedMenu, menuDataArray, subMenuData, forceRefreshLines);
    return;
  }
  let menus = Deref(menuDataArray);
  if !CBHasHubTab(menus) {
    ArrayPush(menus, CBHubTabEntry(EnumInt(HubMenuItems.None)));
  }
  wrappedMethod(selectedMenu, menus, subMenuData, forceRefreshLines);
}

@wrapMethod(RadialSubMenuPanelLogicController)
public func AddMenus(const selectedMenu: script_ref<MenuData>, const menuDataArray: script_ref<array<MenuData>>,
                     opt subMenuData: MenuData, opt forceRefreshLines: Bool) -> Void {
  if !CBHubAsGameMenuTab() {
    wrappedMethod(selectedMenu, menuDataArray, subMenuData, forceRefreshLines);
    return;
  }
  let menus = Deref(menuDataArray);
  if !CBHasHubTab(menus) {
    ArrayPush(menus, CBHubTabEntry(EnumInt(HubMenuItems.Character)));
  }
  wrappedMethod(selectedMenu, menus, subMenuData, forceRefreshLines);
}

// Taken by value: a copy of a short list, and never an array intrinsic on somebody else's temporary.
func CBHasHubTab(menus: array<MenuData>) -> Bool {
  let i = 0;
  while i < ArraySize(menus) {
    if menus[i].identifier == CBHubTabId() {
      return true;
    }
    i += 1;
  }
  return false;
}

func CBHubTabEntry(parent: Int32) -> MenuData {
  let tab: MenuData;
  tab.identifier = CBHubTabId();
  tab.parentIdentifier = parent;
  tab.label = CBHubTabLabel();
  tab.fullscreenName = CBHubTabScreen();
  tab.userData = new CBHubTabData();
  // Gone for the stretch of the story that takes V's hardware away, with the tabs it takes.
  let player = GetPlayer(GetGameInstance());
  tab.disabled = IsDefined(player) && HubMenuUtility.IsPlayerHardwareDisabled(player);
  return tab;
}

// ---- The screen -------------------------------------------------------------------------------

@addField(StatsMainGameController)
private let m_cbHubWanted: Bool;

@addField(StatsMainGameController)
private let m_cbHubReady: Bool;

@addField(StatsMainGameController)
private let m_cbHub: ref<CBHud>;

// The marker and the screen's own setup can arrive in either order, so each of these tries, and
// whichever comes second is the one that finds both.
@wrapMethod(StatsMainGameController)
protected cb func OnSetUserData(userData: ref<IScriptable>) -> Bool {
  wrappedMethod(userData);   // as a statement: never typed off what the game's event returns
  if IsDefined(userData as CBHubTabData) {
    this.m_cbHubWanted = true;
    this.CBBringHub();
  }
  return true;
}

@wrapMethod(StatsMainGameController)
protected cb func OnInitialize() -> Bool {
  wrappedMethod();   // as a statement: never typed off what the game's event returns
  this.m_cbHubReady = true;
  this.CBBringHub();
  return true;
}

// Callbacks go back while the widgets still exist, as the pause menu's do (crash rule 9).
@wrapMethod(StatsMainGameController)
protected cb func OnUninitialize() -> Bool {
  if IsDefined(this.m_cbHub) {
    let sys = CyberbaneSystem.Get(GetGameInstance());
    if IsDefined(sys) {
      sys.HubTabClosed(this.m_cbHub);
    }
    this.m_cbHub.Detach();
    this.m_cbHub = null;
  }
  wrappedMethod();
  return true;
}

@addMethod(StatsMainGameController)
private func CBBringHub() -> Void {
  if !this.m_cbHubWanted || !this.m_cbHubReady || IsDefined(this.m_cbHub) {
    return;
  }
  let game = GetGameInstance();
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  this.CBClearStatsScreen();
  let hub = new CBHud();
  if hub.Show(this, sys, game, true) {
    this.m_cbHub = hub;
    sys.HubTabOpened(hub);
    // Beside the game's Close, already on this screen.
    if IsDefined(this.m_buttonHintsController) {
      this.m_buttonHintsController.AddButtonHint(n"select", GetLocalizedText("UI-UserActions-Select"));
    }
  }
}

// Everything the screen drew, out of sight and out of reach, except its button hints. Nothing is
// removed: this screen's own code goes on running, and it holds references to all of it.
@addMethod(StatsMainGameController)
private func CBClearStatsScreen() -> Void {
  let root = this.GetRootCompoundWidget();
  if !IsDefined(root) {
    return;
  }
  let hints = inkWidgetRef.Get(this.m_buttonHintsManagerRef);
  let keep = IsDefined(hints) ? hints.GetName() : n"";
  let count = root.GetNumChildren();
  let i = 0;
  while i < count {
    let child = root.GetWidgetByIndex(i);
    if IsDefined(child) && NotEquals(child.GetName(), keep) {
      child.SetVisible(false);
    }
    i += 1;
  }
}
