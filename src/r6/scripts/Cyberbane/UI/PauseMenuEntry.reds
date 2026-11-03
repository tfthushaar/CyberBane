// Cyberbane - the Hub, in the pause menu (spec §12.1)
//
// Escape, then Cyberbane, the way you would reach anything else about your character. The Hub is
// a page of the pause menu: it opens over the menu's own list, the game stays paused underneath
// it, the cursor is the menu's cursor, and Escape takes you back to the list the way it does from
// Settings or Load. The Hub key is a shortcut to the same page (Core/CyberbaneSystem.reds).
//
// ---- Why the page lives inside the pause menu's own widget tree --------------------------------
//
// 1.6's first attempt drew the Hub on inkMenuLayer as a tree of its own, opened from the fast tick
// after the pause menu had been dismissed. That tree belonged to no menu. It had no cursor, so
// nothing on it could be clicked; it took no input, so the mouse still turned the camera and the
// left button still fired; and nothing closed it except stepping past the last tab. Worst of all,
// it stayed drawn on top of whatever the game opened next, so pressing Escape opened the real pause
// menu *underneath* the Hub and every press of Escape looked like it went to the Hub instead.
//
// A page parented to PauseMenuGameController's root cannot do any of that. It exists only while the
// pause menu does, because it is part of that menu's tree and is dropped in the controller's
// OnUninitialize; it gets the cursor and the pointer events the menu already has; and the game is
// paused for as long as it is up, because PauseMenuBackgroundGameController pauses on initialise
// and unpauses on uninitialise (pauseMenu.script:17-36). This is the same thing the game does with
// its own GOG panel, which the pause scenario spawns into the pause menu's tree at runtime
// (pauseScenario.script, SpawnGogPopupWidget).
//
// ---- The hooks, and what each one is for ------------------------------------------------------
//
//   AddMenuItem / PopulateMenuItemList  - put the entry in the list, after the game's Mods entry.
//   OnInitialize / OnUninitialize       - tell CyberbaneSystem the pause menu is up, and take the
//                                         page down with it. Nothing outlives the menu.
//   OnSwitchToCyberbane (scenario)      - the entry was chosen: show the page.
//   OnBack (scenario)                   - Escape / B. The in-game menu controller turns `back`
//                                         into this event without looking at IsHandled
//                                         (inGameMenuGameController.script:346-361), so this is the
//                                         only place Escape can be caught. With the page up it
//                                         closes the page and stops; otherwise the game's own
//                                         handling runs untouched.
//
// Nothing here pauses, unpauses, opens or closes a menu by hand except through the menu's own
// event dispatcher, the way the game's own entries do.

// ---- The entry --------------------------------------------------------------------------------
//
// The pattern Mod Settings has used on this game for years (read from its shipped source): position
// chosen by which existing entry we append after, a fallback for when that entry never appears, and
// a flag so a rebuild cannot add ours twice. Our own entry goes in through wrappedMethod, never
// this.AddMenuItem: calling the wrapped name re-enters the whole chain, and with another mod wrapping
// the same method that is how a menu ends up with one of everything per mod installed.
//
// Only the pause menu. gameuiMenuItemListGameController is also the main menu's list and the death
// menu's, and neither has a game running to show a reputation for. Both are siblings of
// PauseMenuGameController, not subclasses, so the IsA check below cannot match them.

@addField(gameuiMenuItemListGameController)
private let m_cbEntryAdded: Bool;

@wrapMethod(gameuiMenuItemListGameController)
protected func AddMenuItem(const label: script_ref<String>, spawnEvent: CName) {
  wrappedMethod(label, spawnEvent);
  if this.m_cbEntryAdded || !this.IsA(n"PauseMenuGameController") {
    return;
  }
  // Right after the game's own Mods entry.
  if Equals(spawnEvent, n"OnSwitchToModioMenu") {
    wrappedMethod(CBPauseMenuLabel(), n"OnSwitchToCyberbane");
    this.m_cbEntryAdded = true;
  }
}

// If the Mods entry never turned up, put ours on the end rather than losing it.
//
// The list has already been refreshed by the time this runs (PopulateMenuItemList ends with
// m_menuListController.Refresh()), so an entry pushed now is data the list has not drawn. Mod
// Settings refreshes after its own fallback for exactly that reason, and so does this; before it
// did, the fallback added an entry nobody could see.
@addMethod(gameuiMenuItemListGameController)
protected func CBAddEntryIfMissing() {
  if !this.m_cbEntryAdded && this.IsA(n"PauseMenuGameController") {
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

// What the entry is called. A plain string rather than a localization key: the key would have to
// resolve through Codeware's provider at the moment the pause menu is built, and a key that does
// not resolve shows as the key itself in the middle of the game's own menu.
public func CBPauseMenuLabel() -> String = "Cyberbane"

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
  let result = wrappedMethod();
  let sys = CyberbaneSystem.Get(GetGameInstance());
  if IsDefined(sys) {
    this.m_cbGeneration = sys.PauseMenuOpened(this);
    // The Hub key asked for the pause menu so that it could open on this page.
    if sys.TakeHubOnPause() {
      this.CBShowHub();
    }
  }
  return result;
}

// Callbacks are handed back while every widget they point at still exists: before the wrapped
// uninitialise, which is when the game starts dismantling the menu. Leaving a registration on a
// widget that is being destroyed is the shape of the 1.4.7 phone crash (crash rule 9).
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
  return wrappedMethod();
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
  if this.m_cbHub.Show(this, sys, game) {
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
//
// The page draws an opaque backdrop over it, and that alone would hide it, but a hidden widget is
// also one the cursor cannot land on. Without this, anything that let a click through the backdrop
// would land on whatever entry was underneath it, and one of those is Exit to Main Menu. Reached
// through the list controller's root widget, the same way the game's own OnInitialize reaches it.
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

// Close the pause menu altogether and go back to the game, the way the Resume entry does: through
// the menu's own dispatcher, never by pulling widgets out by hand.
@addMethod(PauseMenuGameController)
public func CBResumeGame() -> Void {
  this.CBHideHub();
  if IsDefined(this.m_menuEventDispatcher) {
    this.m_menuEventDispatcher.SpawnEvent(n"OnClosePauseMenu");
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

@addMethod(PauseMenuGameController)
public func CBPlayClick() -> Void {
  this.PlaySound(n"Button", n"OnPress");
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

// Escape / B. With the page up, close the page and stop there, so the next press reaches the
// game's own handling and closes the pause menu as usual. With it down, this does nothing at all.
@wrapMethod(MenuScenario_PauseMenu)
protected cb func OnBack() -> Bool {
  let sys = CyberbaneSystem.Get(GetGameInstance());
  if IsDefined(sys) && sys.HideHubPage() {
    return true;
  }
  return wrappedMethod();
}
