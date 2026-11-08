// Cyberbane - The Hub as a tab of the game's own menu (1.7.3)
//
// The row across the top of the game's menu (Cyberware, Inventory, Map, Character, Journal) is drawn
// from a list, one label per entry, so an entry on that list is a real tab: the same label, the same
// underline, reached by the same keys and mouse as the others.
//
// A tab has to open a screen, and the game only knows the screens in its own menu file. Adding one
// would mean shipping a new interface file, which Cyberbane does not do and does not require anything
// to do. So the tab opens the game's Stats screen, which nothing reaches from this row, with a marker
// handed to it. That screen sees the marker, puts its own content out of sight and draws the Hub
// page in its place. Everything around the page is then the game's: the row above it, the background
// behind it, the button hints below it, opening and closing, and Esc, which closes the menu here as it
// does on any other tab. The page itself is built from the game's parts on this screen (CBHud).
//
// This is where the Hub lives unless the player turns on "Hub in the pause menu". Then the entry is
// not added, nothing can hand the Stats screen the marker, and the Stats screen goes on being the
// Stats screen. The setting is read each time the menu opens.
//
// Mod Settings is the one thing the page cannot link to from here. It is a screen of the pause menu's,
// and this is not the pause menu, so the page does not offer the button.

// What tells the Stats screen it is being opened for Cyberbane.
public class CBHubTabData {
  public let opened: Bool;
}

// An identifier the game's own list will never use: its items stop at HubMenuItems.Count.
public func CBHubTabId() -> Int32 = 7731
public func CBHubTabScreen() -> CName = n"temp_stats"
public func CBHubTabLabel() -> String = "CYBERBANE"

public func CBHubAsGameMenuTab() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || !rt.GetSettings().hubInPauseMenu;
}

// The entry goes in where the hub hands its row to the screen, not where the game builds the list.
// There are two hubs, and only one of them builds its list with HubMenuUtility.CreateMenuData: the
// radial hub (the game's own option, `radial_hub_menu_enabled`) builds its own and never calls it, and
// a mod that replaces that function from CET without calling the original drops anything added to it.
// 1.7.3 added the tab there, and a player with several menu mods installed never saw it. Both hubs
// pass their row through AddMenus on the panel that draws it, whoever built it.
//
// The standard hub's row is every entry with no parent, so the tab is one of those, at the end.
// The radial hub's row is the group of the screen that is open, so the tab joins Character's group,
// beside Character and Stats: open Character from the wheel and it is in the row.
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
  let result = wrappedMethod(userData);
  if IsDefined(userData as CBHubTabData) {
    this.m_cbHubWanted = true;
    this.CBBringHub();
  }
  return result;
}

@wrapMethod(StatsMainGameController)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();
  this.m_cbHubReady = true;
  this.CBBringHub();
  return result;
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
  return wrappedMethod();
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
    // Beside the game's own Close, already on this screen.
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
