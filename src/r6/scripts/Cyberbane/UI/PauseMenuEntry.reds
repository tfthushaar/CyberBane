// Cyberbane - the Hub, in the pause menu (spec §12.1)
//
// Escape, then Cyberbane, the way you would reach anything else about your character. The Hub is a page of the pause
// menu: it opens over the menu's own list, the game stays paused underneath it, the cursor is the menu's cursor, and
// Escape takes you back to the list the way it does from Settings or Load.

// ---- The entry --------------------------------------------------------------------------------
//
// The pattern Mod Settings has used on this game for years (read from its shipped source): position chosen by which
// existing entry we append after, a fallback for when that entry never appears, and a flag so a rebuild cannot add ours
// twice.

@addField(gameuiMenuItemListGameController)
private let m_cbEntryAdded: Bool;

//   2.5   Resume, Save, Load, Mods, Settings, Credits, Exit to Main Menu
//   2.31  Resume, Save, Load, Settings, Credits, Exit to Main Menu   (there is no Mods entry)
@wrapMethod(gameuiMenuItemListGameController)
protected func AddMenuItem(const label: script_ref<String>, spawnEvent: CName) {
  wrappedMethod(label, spawnEvent);
  if this.m_cbEntryAdded || !this.IsA(n"PauseMenuGameController") || CBHubAsGameMenuTab() {
    return;
  }
  // Right after the game's Mods entry (2.5), or its Settings entry where there is no Mods entry to follow (2.31).
  if Equals(spawnEvent, n"OnSwitchToModioMenu") || Equals(spawnEvent, n"OnSwitchToSettings") {
    wrappedMethod(CBPauseMenuLabel(), n"OnSwitchToCyberbane");
    this.m_cbEntryAdded = true;
  }
}

// If neither the Mods entry nor the Settings entry turned up (another mod rebuilt the list without
// them), put ours on the end rather than losing it.
@addMethod(gameuiMenuItemListGameController)
protected func CBAddEntryIfMissing() {
  if !this.m_cbEntryAdded && this.IsA(n"PauseMenuGameController") && !CBHubAsGameMenuTab() {
    this.m_cbEntryAdded = true;      // set first: AddMenuItem below re-enters the wrapper
    this.AddMenuItem(CBPauseMenuLabel(), n"OnSwitchToCyberbane");
    if IsDefined(this.m_menuListController) {
      this.m_menuListController.Refresh();
    }
  }
}

@wrapMethod(PauseMenuGameController)
private func PopulateMenuItemList() {
  this.m_cbEntryAdded = false;
  wrappedMethod();
  this.CBAddEntryIfMissing();
}

// What the entry is called.
public func CBPauseMenuLabel() -> String = CBT(n"Cyberbane-Titles-Cyberbane")

// ---- The page's lifetime ----------------------------------------------------------------------

// The page, owned by the pause menu it is drawn in. When the controller goes, this goes with it.
@addField(PauseMenuGameController)
private let m_cbHub: ref<CBHud>;

// Which registration with CyberbaneSystem is ours, so an old menu being torn down after a new one
// has already come up cannot unregister the new one.
@addField(PauseMenuGameController)
private let m_cbGeneration: Int32;

@wrapMethod(PauseMenuGameController)
protected cb func OnInitialize() -> Bool {
  wrappedMethod();   // as a statement: never typed off what the game's event returns
  let sys = CyberbaneSystem.Get(GetGameInstance());
  if IsDefined(sys) {
    this.m_cbGeneration = sys.PauseMenuOpened(this);
  }
  return true;
}

// Callbacks are handed back while every widget they point at still exists: before the wrapped uninitialise, which is
// when the game starts dismantling the menu.
@wrapMethod(PauseMenuGameController)
protected cb func OnUninitialize() -> Bool {
  if IsDefined(this.m_cbHub) {
    this.m_cbHub.Detach();
    this.m_cbHub = null;
  }
  let sys = CyberbaneSystem.Get(GetGameInstance());
  if IsDefined(sys) {
    sys.PauseMenuClosed(this.m_cbGeneration);
  }
  wrappedMethod();
  return true;
}

// Show the Hub page over this menu's list. Safe to call when it is already up (it redraws).
@addMethod(PauseMenuGameController)
public func CBShowHub() -> Void {
  let game = GetGameInstance();
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  if !IsDefined(this.m_cbHub) {
    this.m_cbHub = new CBHud();
  }
  if this.m_cbHub.Show(this, sys, game, false) {
    this.CBSetListVisible(false);
  }
}

// Take the page down and give the list back. True if there was a page to take down.
@addMethod(PauseMenuGameController)
public func CBHideHub() -> Bool {
  if !IsDefined(this.m_cbHub) || !this.m_cbHub.IsOpen() {
    return false;
  }
  this.m_cbHub.Hide();
  this.CBSetListVisible(true);
  return true;
}

@addMethod(PauseMenuGameController)
public func CBHubIsOpen() -> Bool {
  return IsDefined(this.m_cbHub) && this.m_cbHub.IsOpen();
}

// The pause menu's own list goes out of sight, and out of reach, while the page is up.
@addMethod(PauseMenuGameController)
private func CBSetListVisible(visible: Bool) -> Void {
  if !IsDefined(this.m_menuListController) {
    return;
  }
  let list = this.m_menuListController.GetRootWidget();
  if IsDefined(list) {
    list.SetVisible(visible);
  }
}

// Ask the pause scenario to switch to another of its screens, exactly as the list's own entries do
// (PauseMenuGameController.OnMenuItemActivated). Used for the Mod Settings link on the page.
@addMethod(PauseMenuGameController)
public func CBSpawnMenuEvent(eventName: CName) -> Void {
  if IsDefined(this.m_menuEventDispatcher) {
    this.m_menuEventDispatcher.SpawnEvent(eventName);
  }
}

// ---- The scenario -------------------------------------------------------------------------------

// The entry was chosen. The list has already played the click (OnMenuItemActivated).
@addMethod(MenuScenario_PauseMenu)
protected cb func OnSwitchToCyberbane() -> Bool {
  let sys = CyberbaneSystem.Get(GetGameInstance());
  if IsDefined(sys) {
    sys.ShowHubPage();
  }
  return true;
}

// Escape / B. With the page up, close the page and stop there, so the next press reaches the game's handling and closes
// the pause menu as usual. With it down, this does nothing at all.
@wrapMethod(MenuScenario_PauseMenu)
protected cb func OnBack() -> Bool {
  let sys = CyberbaneSystem.Get(GetGameInstance());
  if IsDefined(sys) && sys.HideHubPage() {
    return true;
  }
  wrappedMethod();
  return true;
}
