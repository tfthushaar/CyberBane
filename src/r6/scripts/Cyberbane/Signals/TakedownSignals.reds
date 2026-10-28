// Cyberbane - Takedown signals (spec §7.1, §10.2)
//
// Cyberbane attributes everything through `cbDamagedByPlayer`, which was only ever set in the
// OnHit hook. A takedown does not land as a hit event, so **every stealth takedown was
// invisible to the mod**: a lethal one scored no reputation at all (CBOnPuppetDeath returns
// early without the flag), and a non-lethal one never became a spared Rival, which is exactly
// what players kept reporting when they knocked people out and got nothing.
//
// The completion of a takedown broadcasts a noise stim through the victim's
// StimBroadcasterComponent, with the action type attached. That is the one place every
// takedown variant passes through, so it is where V's involvement gets recorded. This hook
// only sets the flag: whether the victim ends up spared is still decided by CBSparedSweep on
// the next tick, once the engine has actually put them in a defeated state.
//
// Crash safety: no new systems, no allocation, no world queries. It reads the action type,
// casts the owner, sets one boolean on a puppet we were handed, and calls through. The
// wrapped method always runs.
//
// Hook point found by reading Much Better AI (Nexus 31402) by cshiai, which wraps the same
// method for its own takedown reactions. No code from that mod is used here.

@wrapMethod(StimBroadcasterComponent)
public final func TriggerNoiseStim(owner: wref<GameObject>, takedownActionType: ETakedownActionType) -> Void {
  wrappedMethod(owner, takedownActionType);
  CBOnTakedownNoise(owner, takedownActionType);
}

// Is this action type V finishing a takedown on someone, rather than ambient noise?
func CBIsTakedownAction(t: ETakedownActionType) -> Bool {
  return Equals(t, ETakedownActionType.Takedown)
    || Equals(t, ETakedownActionType.TakedownNonLethal)
    || Equals(t, ETakedownActionType.TakedownNetrunner)
    || Equals(t, ETakedownActionType.TakedownMassiveTarget)
    || Equals(t, ETakedownActionType.AerialTakedown)
    || Equals(t, ETakedownActionType.BossTakedown)
    || Equals(t, ETakedownActionType.DisposalTakedown)
    || Equals(t, ETakedownActionType.DisposalTakedownNonLethal)
    || Equals(t, ETakedownActionType.KillTarget)
    || Equals(t, ETakedownActionType.SpareTarget)
    || Equals(t, ETakedownActionType.Grapple);
}

func CBOnTakedownNoise(owner: wref<GameObject>, t: ETakedownActionType) -> Void {
  if !CBIsTakedownAction(t) {
    return;
  }
  let puppet = owner as ScriptedPuppet;
  if !IsDefined(puppet) || puppet.IsPlayer() {
    return;   // the stim owner is the one being taken down, never V
  }
  // V had hands on them. Everything downstream - the kill attribution in CBOnPuppetDeath and
  // the mercy check in CBSparedSweep - keys off this one flag.
  puppet.cbDamagedByPlayer = true;
}
