// Cyberbane - Fenix Rebirth bridge (spec §17)
//
// Fenix Rebirth is a death alternative: V is killed, does not reload, and gets back up
// somewhere with consequences. That is the one thing Cyberbane's nemesis loop was missing.
//
// Cyberbane has always promoted whoever killed V, through the cross-save Death Ledger
// (spec §10.8), and the ledger is applied at session start because without a death
// alternative a death means a reload and a session start is the only moment it can be
// applied. With Fenix installed there is no reload, so that moment never comes and the
// killer was never promoted. The loop that makes a nemesis system a nemesis system - you
// lose, they get stronger, they come looking - was quietly absent for anyone running both.
//
// Fenix publishes `FenixRebirthConfirmedEvent` on the player once a death is confirmed,
// carrying the killer's character record, their affiliation and the weapon used. That is
// everything Cyberbane needs, so this bridge is a hand-off and nothing more: all of the
// judgement lives in `CyberbaneAPI.ReportPlayerKilledBy`, which any other mod can call the
// same way.
//
// **Compiled only when Fenix is installed.** `ModuleExists` is evaluated by redscript before
// anything here is type-checked, so on a machine without Fenix this file contributes nothing
// and cannot fail to compile against types that are not there. `FenixRebirth.Settings` is the
// detector because the death history types themselves are in the global module and there is
// nothing there to test for; Settings ships in Fenix's own core folder and is present in every
// install of it.

@if(ModuleExists("FenixRebirth.Settings"))
@wrapMethod(PlayerPuppet)
protected cb func OnFenixRebirthConfirmedEvent(evt: ref<FenixRebirthConfirmedEvent>) -> Bool {
  // Fenix's own handler first, always, and its return value is passed through untouched. This
  // wraps their event so Cyberbane can hear it; it has no business changing what it does.
  let handled = wrappedMethod(evt);
  if IsDefined(evt) {
    CyberbaneAPI.ReportPlayerKilledBy(this.GetGame(), evt.record.killerRecordID,
                                      evt.record.killerFaction, evt.record.weaponCategory);
  }
  return handled;
}

// Is Fenix Rebirth running? Readable from the rest of the mod and from add-ons.
@if(ModuleExists("FenixRebirth.Settings"))
public func CBFenixActive() -> Bool = true

@if(!ModuleExists("FenixRebirth.Settings"))
public func CBFenixActive() -> Bool = false
