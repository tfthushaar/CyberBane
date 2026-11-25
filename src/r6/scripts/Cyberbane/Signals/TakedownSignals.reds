// Cyberbane - Takedown signals (spec §7.1, §10.2)
//
// A takedown doesn't arrive as a hit, so OnHit never marks it as V's. Every takedown variant ends in a noise stim from
// the victim, so that's where cbDamagedByPlayer gets set; CBSparedSweep still decides on the next tick whether the
// victim was spared.

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
  // Taken down by somebody the story made you, not by V (Core/StoryHold.reds).
  if !CBGameHasVHere(puppet.GetGame()) {
    return;
  }
  // V had hands on them. Everything downstream - the kill attribution in CBOnPuppetDeath and
  // the mercy check in CBSparedSweep - keys off this one flag.
  puppet.cbDamagedByPlayer = true;
  puppet.cbLastHitByOther = false;   // V's hands are the last on them (Signals/CombatSignals.reds)
  puppet.cbLastHitVehicle = CBNoEntity();
  // And if it was a killing takedown, that is a finisher.
  if CBIsLethalTakedown(t) {
    puppet.cbLastMethodMask = CBMethodAdd(puppet.cbLastMethodMask, CBMethodFinisher());
  }
}

// A takedown that kills, as opposed to one that leaves them breathing.
func CBIsLethalTakedown(t: ETakedownActionType) -> Bool {
  return Equals(t, ETakedownActionType.Takedown)
    || Equals(t, ETakedownActionType.TakedownMassiveTarget)
    || Equals(t, ETakedownActionType.AerialTakedown)
    || Equals(t, ETakedownActionType.BossTakedown)
    || Equals(t, ETakedownActionType.DisposalTakedown)
    || Equals(t, ETakedownActionType.KillTarget);
}
