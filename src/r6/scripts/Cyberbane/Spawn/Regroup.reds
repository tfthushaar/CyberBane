// Cyberbane - Hunters who regroup (2.7.7)
//
// A crew sent after V used to fight to the last body. Now one losing badly (two thirds of it down, the rest still
// standing) pulls back: the ones left break and run, the way any broken ganger does (CBMoraleBreak, Reactions/Morale.reds),
// their gang says so, and it sends more a little later through the same lane any crew comes by. Once a crew. An apex squad,
// and a crew that came with its apex squad, never pulls back: they are the gang's last word.

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
