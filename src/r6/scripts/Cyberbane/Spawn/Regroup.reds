// Cyberbane - Hunters who regroup
//
// A crew that's losing badly (two thirds down) breaks and runs, and its gang sends another one a little later through
// the usual lane. Once per crew, never with an apex squad.

// One of the crew sent after V went down (Signals/CombatSignals.reds, a frame after the death).
public func CBSquadLostOne(sys: ref<CyberbaneSystem>, game: GameInstance, gone: EntityID) -> Void {
  let faction = sys.GetActiveSquadFaction();
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsNameValid(faction) || !IsDefined(des) || sys.ActiveSquadHasApex() {
    return;
  }
  sys.squadDown += 1;
  if sys.squadRegrouped || sys.squadDown < CBConfig.RegroupMinDown() {
    return;
  }
  let left = CBCountLiveOrSpawningExcept(game, n"CB_Squad", gone, n"CB_Bounty");
  if left < 1 || left * 2 > sys.squadDown {
    return;
  }
  sys.squadRegrouped = true;
  let broke = 0;
  let ids = des.GetTaggedIDs(n"CB_Squad");
  for id in ids {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if !Equals(id, gone) && CBNpcSafe(sys, p) && CBStillStanding(p) && !p.cbMoraleBroken && !des.IsTagged(id, n"CB_Bounty") {
      if CBMoraleBreak(sys, game, p, faction, 1.0) {
        broke += 1;
      }
    }
  }
  if broke == 0 {
    return;
  }
  if CBToastsOn() {
    CBPhoneSendUrgent(game, CBPhoneGangSender(faction), CBT(n"Cyberbane-Regroup-PullBack"), CBHudRed());
  }
  if !IsNameValid(sys.GetPendingSquadFaction()) {
    sys.SetPendingSquad(faction, CBConfig.RegroupReinforceTicks());
  }
  CBLog.Info(n"Spawn", s"A \(NameToString(faction)) crew losing badly pulled back (\(broke) ran) and is sending more.");
}
