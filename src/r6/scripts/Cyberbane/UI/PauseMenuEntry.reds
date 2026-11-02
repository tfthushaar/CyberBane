// Cyberbane - the Hub, from the pause menu (spec §12.1)
//
// Escape, then Cyberbane, the way you would reach anything else about your character.
//
// ---- Which menu this is, and why it is the only one -----------------------
//
// There are two menus a player would call "the menu" and only one of them can be added to.
//
// The hub menu (Tab: Inventory, Character, Journal, Map, Phone, Codex...) is closed. Every entry
// is a hardcoded `editable var ... : inkWidgetRef` bound from its own `.inkwidget`
// (`hubMenuLogicController.script:3-14`), and the data behind them is `HubMenuItems`, a game
// enum that ends at `Count = 18` (`menuDataBuilder.script:219-241`). There is no list to append
// to, so a tile there needs a resource this mod does not ship.
//
// The pause menu (Escape: Resume, Save, Load, Mods, Settings, Credits, Exit) is built by
// repeated `AddMenuItem(label, event)` calls (`pauseMenu.script:174-189`), so it can be appended
// to from script alone. That is what this file does, and it is the pattern Mod Settings has used
// on this game for years - read from its own shipped `packed.reds` rather than guessed at.
//
// ---- The three things that pattern gets right -----------------------------
//
//   1. Position is chosen by *which existing entry you append after*, not by an index. Ours goes
//      in after the Mods entry, so Cyberbane sits with the other mod business rather than in the
//      middle of Save/Load/Quit, and the list lays itself out - there is no coordinate to collide
//      with anything.
//   2. There is a fallback for when that anchor never appears, because another mod can hide the
//      mod.io entry or replace PopulateMenuItemList without it. Then ours goes on the end rather
//      than nowhere.
//   3. A flag stops it being added twice when the list is rebuilt.
//
// ---- Two traps worth naming -----------------------------------------------
//
// **Call `wrappedMethod` for our own entry, never `this.AddMenuItem`.** We are inside a wrapper on
// AddMenuItem; calling the wrapped name again re-enters the whole chain, and with another mod
// wrapping the same method that is how a menu ends up with one of everything per mod installed.
// The fallback below does call AddMenuItem, exactly as Mod Settings' does, which is safe only
// because the flag is set first.
//
// **Only the pause menu.** `gameuiMenuItemListGameController` is also the main menu's list and the
// death menu's, and both have a Mods entry. Neither has a game running to show a reputation for,
// so the check is on the controller type rather than on the event alone.

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
@addMethod(gameuiMenuItemListGameController)
protected func CBAddEntryIfMissing() {
  if !this.m_cbEntryAdded && this.IsA(n"PauseMenuGameController") {
    this.m_cbEntryAdded = true;      // set first: AddMenuItem below re-enters the wrapper
    this.AddMenuItem(CBPauseMenuLabel(), n"OnSwitchToCyberbane");
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
public func CBPauseMenuLabel() -> String = "Cyberbane";

// The entry was chosen.
//
// The game is paused while this menu is up, which settles the countdowns: the delayed tick that
// refreshes an open Hub does not run while the game is paused, so every time on it is the time as
// at the moment it was opened. That is the behaviour that was asked for.
//
// `GotoIdleState` is what the Resume entry does (`pauseScenario.script:290`), so the menu is
// dismissed exactly the way the game dismisses it.
//
// The Hub is only *asked for* here. Building its widget tree from inside this callback, while the
// menu this callback belongs to is being dismissed, is the interleaving behind the 1.3.5 rebuild
// loop; the fast tick does the actual opening a moment later, once nothing is mid-teardown.
@addMethod(MenuScenario_PauseMenu)
protected cb func OnSwitchToCyberbane() -> Bool {
  CBOpenHubFromMenu();
  this.GotoIdleState();
  return true;
}

// Record that the Hub should open. The fast tick opens it (Core/CyberbaneSystem.reds).
public func CBOpenHubFromMenu() -> Void {
  let game = GetGameInstance();
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  sys.RequestHubOpen();
}
