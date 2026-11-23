// Cyberbane - Hangouts (2.6.1)
//
// "The Mox should have a meeting place besides the ones in vanilla: it's almost impossible to come by Moxes to talk to."
//
// Some gangs are hard to find on their own streets: the game puts few of their people out, and everything Cyberbane
// lets V do with a gang through its people (ask around, a favour, a lead, being lent somebody, joining them) needs one
// to talk to. So now and then, on a gang's own turf where none of theirs are about, a few of them are hanging out a
// street or two from V, marked on the map as such. Talkable like anybody on the street, neutral to V, never sent after
// V. Once a day for each gang, one hangout at a time, never for a gang hostile to V, never while the story, a job or a
// scene has V, and they pack up (out of V's sight) once V has gone or a couple of hours have passed. Under Gang life's
// Gatherings switch. Session only: nothing is saved.

public class CBHangoutState extends ScriptableSystem {
  public let gang: CName;
  public let at: Vector4;
  public let since: Float;
  public let pin: NewMappinID;
  public let pinned: Bool;
  public let doneGang: array<CName>;
  public let doneDay: array<Int32>;
  public let lookedTick: Int32;
  // A gang's home V was last inside (Spawn/GangHomes.reds), one up, and where and when: session only.
  public let homeInside: Int32;
  public let homeInsideAt: Vector4;
  public let homeInsideWhen: Float;

  public static func Get(game: GameInstance) -> ref<CBHangoutState> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBHangoutState") as CBHangoutState : null;
  }

  public func DoneToday(g: CName, day: Int32) -> Bool {
    let i = ArrayFindFirst(this.doneGang, g);
    return i >= 0 && this.doneDay[i] == day;
  }

  public func MarkDone(g: CName, day: Int32) -> Void {
    let i = ArrayFindFirst(this.doneGang, g);
    if i >= 0 {
      this.doneDay[i] = day;
    } else {
      ArrayPush(this.doneGang, g);
      ArrayPush(this.doneDay, day);
    }
  }
}

// Every few ticks (Reactions/Director.reds).
public func CBHangoutTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let st = CBHangoutState.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(st) || !IsDefined(sys) || !IsDefined(player) {
    return;
  }
  let now = CBGameSeconds(game);
  if NotEquals(st.gang, n"") {
    // Packing up: V gone, their time up, the gang turned against V, or the feature switched off.
    let score = sys.GetScore();
    let posture = IsDefined(score) ? score.GetPosture(st.gang) : ECBPosture.Neutral;
    let over = !CBGatheringsOn() || Vector4.Distance(player.GetWorldPosition(), st.at) > CBConfig.HangoutLeaveDistance()
               || now - st.since > CBConfig.HangoutHours() * CBConfig.SecondsPerHour()
               || Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta);
    if over {
      CBHangoutEnd(game, st);
    }
    return;
  }
  if !CBGatheringsOn() || sys.GetTickCount() - st.lookedTick < CBConfig.HangoutLookTicks() {
    return;
  }
  st.lookedTick = sys.GetTickCount();
  // Never into the story, a job, a scene, a fight, a safe place or a car; and only with room for them.
  if sys.GetStoryHold() != CBStoryNone() || sys.IsInQuestArea() || sys.IsOnJob() || CBPlayerInScene(game) || player.IsInCombat()
     || sys.IsInSafeZone() || IsDefined(player.GetMountedVehicle()) || CBSpawnRoom(game) <= CBConfig.TurfPatrolKeepRoom()
     || CBHomeKeepsOut(sys) {
    return;
  }
  let day = CBGameDay(game);
  let score = sys.GetScore();
  let reg = sys.GetRegistry();
  if !IsDefined(score) || !IsDefined(reg) {
    return;
  }
  // A gang's home V is close to (2.7.2, Spawn/GangHomes.reds): somebody is there, whatever the dice say, once a day.
  let homeAt: Vector4;
  let home = CBGangHomesOn() ? CBGangHomeNear(game, player.GetWorldPosition(), CBConfig.GangHomeReach(), homeAt) : -1;
  if home >= 0 {
    let hg = CBGangHomeGang(home);
    if CBFactionOn(hg) && CBFactionFieldsSquads(hg) && !st.DoneToday(hg, day) && CBGangHomeShown(sys, game, hg)
       && CBHangoutScarce(sys, game, reg, hg) {
      st.MarkDone(hg, day);
      CBHangoutStart(sys, game, st, hg, now, homeAt);
      return;
    }
  }
  for g in CBTurfGangsHere(sys) {
    let posture = score.GetPosture(g);
    if CBFactionOn(g) && CBFactionFieldsSquads(g) && !st.DoneToday(g, day)
       && !Equals(posture, ECBPosture.Hostile) && !Equals(posture, ECBPosture.Vendetta) && CBHangoutScarce(sys, game, reg, g) {
      st.MarkDone(g, day);   // asked once a day, placed or not
      if RandF() < CBConfig.HangoutChance() {
        CBHangoutStart(sys, game, st, g, now);
        return;
      }
    }
  }
}

// None of theirs about: nobody of the gang standing within HangoutScarceRange of V.
func CBHangoutScarce(sys: ref<CyberbaneSystem>, game: GameInstance, reg: ref<CBNpcRegistry>, gang: CName) -> Bool {
  let player = GetPlayer(game);
  let ppos = player.GetWorldPosition();
  for p in reg.GetAll() {
    if CBNpcSafe(sys, p) && !p.IsDead() && Vector4.Distance(ppos, p.GetWorldPosition()) <= CBConfig.HangoutScarceRange()
       && Equals(CBClassifyFaction(p), gang) {
      return false;
    }
  }
  return true;
}

func CBHangoutStart(sys: ref<CyberbaneSystem>, game: GameInstance, st: ref<CBHangoutState>, gang: CName, now: Float,
                    opt home: Vector4) -> Void {
  let record = CBGangTemplate(sys, gang);
  if !TDBID.IsValid(record) {
    return;
  }
  // At their home when there is one to go to (2.7.2), else a street or two from V.
  let atHome = home.X != 0.0 || home.Y != 0.0;
  if atHome {
    if CBPlaceAround(sys, game, record, home, CBConfig.HangoutSize(), n"CB_Hangout") <= 0 {
      return;
    }
  } else {
    let body: EntityID;
    if CBSpawnGroup(game, record, n"", CBConfig.HangoutSize(), n"CB_Hangout", CBConfig.HangoutDistance(), body) <= 0 {
      return;
    }
  }
  let rt = CyberbaneRuntime.Get();
  st.gang = gang;
  st.since = now;
  st.at = atHome ? home : (IsDefined(rt) ? rt.lastSpawnAt : GetPlayer(game).GetWorldPosition());
  let ms = GameInstance.GetMappinSystem(game);
  // A place pin only where their own markers would not show (Mark them on the map at Named only): with Everyone, each of
  // them already wears one, and a pin on top was the same thing twice.
  if IsDefined(ms) && CBMapMarkersOn() && NotEquals(CBMarkerScope(), ECBMarkerScope.Everyone) {
    st.pin = ms.RegisterMappin(CBPlacePinData(CBEventPinCaption(CBTf(n"Cyberbane-Hangouts-HangingOut", [s"\(CBCapFirst(CBFactionLabel(gang)))"]))), st.at);
    st.pinned = true;
  }
  if CBMessagesOn() {
    CBOverheard(game, CBT(n"Cyberbane-Whispers-PasserBy"), CBLineOf([CBTf(n"Cyberbane-Hangouts-SomeOfTheHangOutRound", [s"\(CBFactionLabel(gang))"]),
                                             CBTf(n"Cyberbane-Hangouts-LookingForAFewOfThem", [s"\(CBFactionLabel(gang))"])]));
  }
  CBLog.Info(n"Street", s"A few of \(NameToString(gang)) are hanging out near V.");
}

func CBHangoutEnd(game: GameInstance, st: ref<CBHangoutState>) -> Void {
  if st.pinned {
    let ms = GameInstance.GetMappinSystem(game);
    if IsDefined(ms) {
      ms.UnregisterMappin(st.pin);
    }
    st.pinned = false;
  }
  CBDeleteTaggedSafe(game, n"CB_Hangout", true, true);   // out of V's sight, as every sweep
  st.gang = n"";
}
