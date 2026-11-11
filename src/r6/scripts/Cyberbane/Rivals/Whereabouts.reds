// Cyberbane - Hunting a Rival down (1.6.2)
//
// "It would be peak to track my Nemesis and go ambush them. Like they do with us." Rivals come for
// V on their own timetable; this is the other direction. Somebody who got away from V is seen
// somewhere afterwards, the street or a gang that hates theirs tells V where, and if V goes there
// on foot the Rival is there, not expecting anybody. Catch them unawares and the street hears
// about it.
//
// The pieces, in the order they happen:
//   Seen       When a Rival walks away from an encounter alive - V lost them, they ran, V spared
//              them - the spot they were standing on is written down. It is standing room by
//              construction: Cyberbane placed them and they walked there.
//   Tip        Now and then, a gang at war with theirs, or somebody on the street, texts V where
//              the Rival was seen and a pin goes on the map. One lead at a time; it goes stale
//              after a day, because people move on.
//   Waiting    V comes to the pin. Inside LairPlaceDistance, on foot, out of combat, with the
//              world settled and nothing else of Cyberbane's out or on its way, the Rival is put
//              there - at the place or round it, somewhere V cannot see (1.7.1), idle, given no
//              orders at all, and tagged CB_Lair instead of CB_Rival.
//   The fight  The moment they are in combat or V has hurt them, the tag becomes CB_Rival and
//              from then on it is an ordinary Rival encounter, run entirely by the code that
//              already runs every other one: the hunt, the escape, the mercy, the death.
//   Ambush     Put down before they ever got into the fight, it counts as an ambush: extra
//              renown, a line in the street's file, and word back from whoever tipped V off.
//
// Why it is built like this. Crash safety first:
//   - Nothing new reaches the engine. The body is placed through the same checks and the same
//     CreateEntity call as every arrival (Spawn/Spawner.reds), torn down through
//     CBDeleteTaggedSafe, marked through the same mappin system. The one call this mod had not
//     made before is MappinSystem.RegisterMappin with a position, which both 2.31 and 2.5 have
//     and which the game's own drop points use. The game's own systems register those pins again
//     on every load (DropPointSystem.OnRestored), so they are not kept in the save, and a pin left
//     over from another session cannot exist.
//   - The arrival is placed only when V is on foot and has been calm for several settled ticks.
//     A car or a fast travel is exactly when the world streams hardest, which is where the mod's
//     crashes have always come from, so those are the moments it refuses.
//   - One waiting Rival at a time, never while anything else of ours is out or on its way, and
//     never more bodies than the live ceiling allows.
//   - While waiting they carry their own tag, so the hunt, the chase give-up, the retire sweep
//     and the lanes - everything that would otherwise send them off after V or declare them lost
//     - cannot see them. Leaving the hunt's state machine untouched was the point.
// And no save changes shape: where Rivals were seen lives in the global service (see
// CBSighting); what is going on right now lives in session fields on the system.

// ---- On or off ------------------------------------------------------------------------------

public func CBHideoutsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  if rt.HasSettings() {
    let s = rt.GetSettings();
    return s.rivals && s.rivalHideouts;
  }
  return true;
}

// ---- Where they were seen -------------------------------------------------------------------

// Could anybody be waiting here later? Point tests only. CBSafeAreaBlocksSpawn asks the same
// questions but also writes down why it refused, for the Hub's "why has nobody come" line, and
// noting a sighting is not an arrival. Stricter than an arrival on purpose: a hideout is never in a
// safe area, whatever the safe-area setting says.
func CBLairPointUsable(sys: ref<CyberbaneSystem>, game: GameInstance, at: Vector4) -> Bool {
  if !IsDefined(sys) || sys.NearQuestPins(at, CBConfig.QuestSpawnClearance()) {
    return false;
  }
  let pss = GameInstance.GetPreventionSpawnSystem(game);
  if IsDefined(pss) && pss.IsPointInPreventionFreeArea(at) {
    return false;
  }
  let sam = GameInstance.GetSafeAreaManager(game);
  if IsDefined(sam) && sam.IsPointInSafeArea(at) {
    return false;
  }
  return true;
}

// This Rival was standing here, alive, as an encounter ended. Called from the places where one
// ends that way (CBRivalEscapedByPlayer, CBHandleEscape, CBHandleSpared, a crew survivor in
// CBChaseGiveUp), all on settled ticks.
//
// "I'm not getting tips to hunt my rivals." This asked only the body, and only a body that was
// still attached. The usual way a Rival walks away alive is V outrunning them, and the hunt only
// gives up once every hunter is well over a hundred metres off and has stayed there - which is
// exactly where a body streams out. So the commonest escape wrote nothing down, and with nothing
// written down there was nothing for anybody to tip V off about. Where the Rival was last seen
// standing is kept as they move (CBTrackRivalWhereabouts), and that is used when the body cannot
// answer for itself.
public func CBNoteRivalSeen(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>,
                            body: wref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(r) || !CBWorldStable(game) {
    return;
  }
  let at: Vector4;
  if CBNpcSafe(sys, body) {
    at = body.GetWorldPosition();
  } else {
    if !sys.RivalLastPos(r.id, CBConfig.RivalLastPosFreshTicks(), at) {
      return;
    }
  }
  CBNoteRivalSeenAt(sys, game, r, at);
}

// The same, for somebody who walked away from V as an escapee: their body if it is still here,
// otherwise the last place the escape tracker saw them standing (Reactions/CombatFlee.reds).
public func CBNoteEscapeeSeen(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>,
                              e: ref<CBEscapee>) -> Void {
  if !IsDefined(sys) || !IsDefined(r) || !IsDefined(e) {
    return;
  }
  if CBNpcSafe(sys, e.puppet) || !e.hasPos {
    CBNoteRivalSeen(sys, game, r, e.puppet);
    return;
  }
  if CBWorldStable(game) {
    CBNoteRivalSeenAt(sys, game, r, e.lastPos);
  }
}

// Write down that this Rival was seen standing here.
func CBNoteRivalSeenAt(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, at: Vector4) -> Void {
  let svc = sys.GetPlayService();
  if !IsDefined(svc) || !CBLairPointUsable(sys, game, at) {
    return;
  }
  // Somewhere new, so whatever V was told before no longer holds.
  if sys.IsLeadPinned() && sys.GetLeadPinRival() == r.id {
    CBDropLead(sys, game);
  }
  svc.NoteSighting(sys.GetPlaythroughId(), r.id, r.recordID, at, sys.GetCurrentDistrict(), CBGameSeconds(game));
}

// Is this sighting about a Rival this save actually has, as they are now?
func CBSightingRival(sys: ref<CyberbaneSystem>, s: ref<CBSighting>) -> ref<CBRival> {
  if !IsDefined(sys) || !IsDefined(s) || !Equals(s.playthroughId, sys.GetPlaythroughId()) {
    return null;
  }
  let r = sys.FindRivalById(s.rivalId);
  if !IsDefined(r) || r.recordID != s.recordID {
    return null;
  }
  if r.state != EnumInt(ECBRivalState.Active) && r.state != EnumInt(ECBRivalState.Hunting) {
    return null;
  }
  return r;
}

func CBSightingPos(s: ref<CBSighting>) -> Vector4 {
  return new Vector4(s.x, s.y, s.z, 1.0);
}

// The lead V is on, if any: the newest tip that has not gone stale.
public func CBCurrentLead(sys: ref<CyberbaneSystem>, game: GameInstance) -> ref<CBSighting> {
  if !IsDefined(sys) {
    return null;
  }
  let svc = sys.GetPlayService();
  if !IsDefined(svc) {
    return null;
  }
  let now = CBGameSeconds(game);
  let life = CBConfig.LeadLifetimeHours() * CBConfig.SecondsPerHour();
  let best: ref<CBSighting>;
  for s in svc.GetSightings() {
    if IsDefined(s) && s.tippedAt > 0.0 && now >= s.tippedAt && (now - s.tippedAt) <= life
       && IsDefined(CBSightingRival(sys, s)) {
      if !IsDefined(best) || s.tippedAt > best.tippedAt {
        best = s;
      }
    }
  }
  return best;
}

// What the Hub shows for one Rival: their sighting, tipped or not, when it still applies.
public func CBSightingFor(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> ref<CBSighting> {
  if !IsDefined(sys) || !IsDefined(r) {
    return null;
  }
  let svc = sys.GetPlayService();
  if !IsDefined(svc) {
    return null;
  }
  let s = svc.FindSighting(sys.GetPlaythroughId(), r.id);
  if !IsDefined(s) || s.recordID != r.recordID {
    return null;
  }
  return s;
}

// ---- Tips -----------------------------------------------------------------------------------

// Who passes it on: a gang at war with the Rival's that does not want V dead, the friendliest
// first. n"" when there is none, and the street tells V instead.
func CBPickTipster(sys: ref<CyberbaneSystem>, faction: CName) -> CName {
  let content = sys.GetContent();
  let score = sys.GetScore();
  if !IsDefined(content) || !IsDefined(score) {
    return n"";
  }
  let enemies = CBGangRivalsOf(content, faction);
  let best = n"";
  let bestRank = 0;
  let i = 0;
  while i < ArraySize(enemies) {
    let g = enemies[i];
    i += 1;
    if NotEquals(g, n"") && NotEquals(g, faction) && CBFactionFieldsSquads(g) {
      let posture = score.GetPosture(g);
      let rank = 0;
      if Equals(posture, ECBPosture.Allied) {
        rank = 3;
      } else {
        if Equals(posture, ECBPosture.Friendly) {
          rank = 2;
        } else {
          if Equals(posture, ECBPosture.Neutral) {
            rank = 1;
          }
        }
      }
      if rank > bestRank {
        best = g;
        bestRank = rank;
      }
    }
  }
  return best;
}

// Can this Rival be the subject of a tip right now? Not while they are on their way to V, out
// there already, or waiting at their place.
//
// Merely being next in the Rival lane's queue does not count as on their way. It used to: the
// lane picks whoever has got away from V most, which is almost always the Rival V has just lost,
// so the one Rival there was a sighting of was the one Rival nobody would tip V off about. Until
// they text V that they are coming they are only asking around about V, somewhere - and that
// somewhere is what the tip is about. If V finds them first, the lane lets them go
// (CBLairTryPlace).
func CBTipEligible(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if r.id == sys.GetActiveRivalId() || r.id == sys.GetRivalWarned() || r.id == sys.GetRivalCarPending() {
    return false;
  }
  if sys.IsLairActive() && sys.GetLairRivalId() == r.id {
    return false;
  }
  if EntityID.IsDefined(r.spawnedEntityId) {
    let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
    if CBStillStanding(body) {
      return false;
    }
  }
  return true;
}

public func CBPlacePhrase(district: CName) -> String {
  let place = CBDistrictLabel(district);
  return StrLen(place) > 0 ? "in " + place : "around town";
}

func CBTipLine(name: String, inPlace: String, fromGang: Bool, pinned: Bool) -> String {
  let pin = pinned ? " It's on your map." : "";
  if fromGang {
    switch RandRange(0, 3) {
      case 0: return s"Heard you got beef with \(name). Our people saw them \(inPlace) not long ago.\(pin)";
      case 1: return s"\(name) has been seen \(inPlace). You want them, they are yours. Nobody here will miss them.\(pin)";
      default: return s"Word from our corners: \(name) is lying low \(inPlace). Do us all a favour.\(pin)";
    }
  }
  switch RandRange(0, 2) {
    case 0: return s"Saw \(name) \(inPlace) earlier. Heard they have it in for you.\(pin)";
    default: return s"Your friend \(name) is holed up \(inPlace). You did not hear it from me.\(pin)";
  }
}

// One tip, now and then. Slow tick, so about once an in-game hour at most.
public func CBTipTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !CBHideoutsOn() || !CBWorldStable(game) {
    return;
  }
  let svc = sys.GetPlayService();
  if !IsDefined(svc) || IsDefined(CBCurrentLead(sys, game)) {
    return;   // one lead at a time
  }
  let now = CBGameSeconds(game);
  let last = sys.GetLastTipAt();
  if last > 0.0 && now >= last && (now - last) < CBConfig.TipGapHours() * CBConfig.SecondsPerHour() {
    return;
  }
  let minAge = CBConfig.TipMinAgeHours() * CBConfig.SecondsPerHour();
  let picks: array<ref<CBSighting>>;
  let oldest = 0.0;
  for s in svc.GetSightings() {
    if IsDefined(s) && s.tippedAt <= 0.0 && now >= s.seenAt && (now - s.seenAt) >= minAge {
      let r = CBSightingRival(sys, s);
      if IsDefined(r) && CBTipEligible(sys, game, r) && CBLairPointUsable(sys, game, CBSightingPos(s)) {
        ArrayPush(picks, s);
        oldest = MaxF(oldest, now - s.seenAt);
      }
    }
  }
  if ArraySize(picks) == 0 {
    return;
  }
  // Word gets round. The longer somebody has been seen and nobody has said, the likelier it is
  // that somebody does: a flat chance an hour could leave a sighting untold until the Rival had
  // come back for V anyway, which is the other half of why tips felt like they never came.
  let overHours = (oldest - minAge) / CBConfig.SecondsPerHour();
  let chance = ClampF(CBConfig.TipChancePerHour() + CBConfig.TipChanceRisePerHour() * overHours, 0.0, 1.0);
  if RandF() >= chance {
    return;
  }
  let pick = picks[RandRange(0, ArraySize(picks))];
  let rival = CBSightingRival(sys, pick);
  if !IsDefined(rival) {
    return;
  }
  let tipster = CBPickTipster(sys, rival.faction);
  pick.tippedAt = now;
  pick.tipFaction = tipster;
  sys.SetLastTipAt(now);
  // The text is the only part a player can switch off; the lead, the pin and the Hub's file stand
  // either way, so silence costs being told and nothing else.
  let name = CBRivalDisplayName(sys.GetContent(), rival);
  let line = CBTipLine(name, CBPlacePhrase(pick.district), IsNameValid(tipster), CBMapMarkersOn());
  if IsNameValid(tipster) {
    CBPhoneFromAlly(game, tipster, line);
  } else {
    if IsNameValid(pick.district) {
      CBPhoneFromDistrict(game, pick.district, line);
    } else {
      CBPhoneFromStreet(game, line);
    }
  }
  CBLog.Info(n"Rivals", s"Tip: rival \(rival.id) seen in \(NameToString(pick.district)), from \(NameToString(tipster)).");
}

// ---- The pin --------------------------------------------------------------------------------

// Take the pin on somebody's place off the map. Safe to call with nothing pinned. The record is
// only forgotten once the pin is actually gone, so a missing mappin system cannot strand one.
public func CBDropLead(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !sys.IsLeadPinned() {
    return;
  }
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(ms) {
    return;
  }
  ms.UnregisterMappin(sys.GetLeadPinId());
  sys.ClearLeadPin();
}

// Keep the map in step with the lead: one pin, on the newest lead, while there is one, the map
// markers setting is on and the Rival is not standing there already (then they carry their own).
func CBLeadPinTick(sys: ref<CyberbaneSystem>, game: GameInstance, on: Bool) -> Void {
  let lead: ref<CBSighting>;
  if on && CBMapMarkersOn() {
    lead = CBCurrentLead(sys, game);
  }
  let leadId = -1;
  if IsDefined(lead) {
    leadId = lead.rivalId;
  }
  let want = leadId >= 0 && !(sys.IsLairActive() && sys.GetLairRivalId() == leadId);
  if sys.IsLeadPinned() && (!want || sys.GetLeadPinRival() != leadId) {
    CBDropLead(sys, game);
  }
  if !want || sys.IsLeadPinned() {
    return;
  }
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(ms) {
    return;
  }
  let data: MappinData;
  // A pin for a place, wearing Cyberbane's own mark (UI/RivalPin.reds).
  //
  // It has been wrong twice. Up to 1.6.4 it was the gang-business variant the Rival markers used,
  // which the game draws as an NCPD scanner hustle (map_bounty, mappinUtils.script): on the map
  // it was one more hustle among dozens, and the minimap never drew it at all.
  //
  // 1.6.5 to 1.7.0 used CustomPositionVariant, and a player on 1.7.0 still found nothing but the
  // NCPD icons where the text said to look. That variant is not a look, it is a role: the one
  // waypoint the player drops on the map. The game keeps exactly one pin in that role and finds
  // it by variant. The map writes to whichever one it finds - another mod that registered a
  // second one saw its pin moved to a spot nobody chose (spuddeh's NC Zoning District Guide,
  // WorldActions.reds) - and on 2.31 the auto-drive deletes any tracked pin of that variant when it
  // arrives (autoDriveSystem.script, OnStopAutoDriveOnDestinationReachedRequest). So the pin was
  // not where the Rival was, and Cyberbane, which owns neither of those, could not keep it there.
  //
  // Now the variant only decides where the pin may live, never what it looks like. ApartmentVariant:
  // the world map draws it, no 2.31 or 2.5 script reads it, it is not a quest pin so it can be
  // tracked for a route, and its filter is Your Property, with the player's own waypoint and cars,
  // which is on unless the player turns it off. The caption carries Cyberbane's tag and the Rival's
  // name, and every controller that draws a pin with that tag draws Cyberbane's gold mark and the
  // Rival's name instead of an apartment. Through walls, as a destination is: the reason the people
  // markers stay off that does not apply to a place.
  data.mappinType = t"Mappins.DefaultStaticMappin";
  data.variant = gamedataMappinVariant.ApartmentVariant;
  data.active = true;
  data.visibleThroughWalls = true;
  data.debugCaption = CBRivalPinCaption(CBRivalDisplayName(sys.GetContent(), CBSightingRival(sys, lead)));
  CBTrace("map: pin on a rival's last known place");
  let id = ms.RegisterMappin(data, CBSightingPos(lead));
  sys.SetLeadPin(leadId, id);
}

// Leads go stale. Dropped quietly when they no longer apply to this save, and with a word from
// whoever passed it on when the day simply ran out.
func CBLeadExpiryTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let svc = sys.GetPlayService();
  if !IsDefined(svc) {
    return;
  }
  let pid = sys.GetPlaythroughId();
  let now = CBGameSeconds(game);
  let life = CBConfig.LeadLifetimeHours() * CBConfig.SecondsPerHour();
  let gone: array<Int32>;
  let staleFrom: array<CName>;
  let staleName: array<String>;
  let staleWhere: array<CName>;
  for s in svc.GetSightings() {
    // A Rival waiting at the place right now keeps it until that encounter is over, one way or
    // the other; nobody texts that they moved on while they are standing there.
    let waitingThere = sys.IsLairActive() && IsDefined(s) && sys.GetLairRivalId() == s.rivalId;
    if IsDefined(s) && Equals(s.playthroughId, pid) && !waitingThere {
      let r = CBSightingRival(sys, s);
      // From a newer branch of this playthrough (its times are ahead of this save), or about a
      // Rival this save no longer has: not this save's to keep.
      let foreign = now < s.seenAt || (s.tippedAt > 0.0 && now < s.tippedAt) || !IsDefined(r);
      let stale = s.tippedAt > 0.0 && now >= s.tippedAt && (now - s.tippedAt) > life;
      if foreign || stale {
        ArrayPush(gone, s.rivalId);
        if stale && !foreign {
          ArrayPush(staleFrom, s.tipFaction);
          ArrayPush(staleName, CBRivalDisplayName(sys.GetContent(), r));
          ArrayPush(staleWhere, s.district);
        }
      }
    }
  }
  let i = 0;
  while i < ArraySize(gone) {
    if sys.IsLeadPinned() && sys.GetLeadPinRival() == gone[i] {
      CBDropLead(sys, game);
    }
    svc.DropSighting(pid, gone[i]);
    i += 1;
  }
  let k = 0;
  while k < ArraySize(staleName) {
    let line = s"\(staleName[k]) moved on from \(CBPlacePhrase(staleWhere[k])). Took too long.";
    if IsNameValid(staleFrom[k]) {
      CBPhoneFromAlly(game, staleFrom[k], line);
    } else {
      CBPhoneFromStreet(game, line);
    }
    k += 1;
  }
}

// ---- The waiting Rival ----------------------------------------------------------------------

// Once per settled fast tick, from CyberbaneSystem.
public func CBWhereaboutsTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return;
  }
  let on = CBHideoutsOn();
  let tick = sys.GetTickCount();
  if tick % 2 == 0 {
    CBTrackRivalWhereabouts(sys, game);
  }
  if tick % 10 == 0 {
    CBLeadExpiryTick(sys, game);
  }
  if tick % 3 == 0 {
    CBLeadPinTick(sys, game, on);
  }
  // Calm: on foot, out of combat, nowhere the story or a job has the stage, a settled world.
  let calm = on && CBWorldStable(game) && !IsDefined(player.GetMountedVehicle()) && !player.IsInCombat()
             && sys.GetStoryHold() == CBStoryNone() && !sys.IsInSafeZone() && !sys.IsInQuestArea()
             && !sys.IsOnJob();
  sys.SetLairCalmTicks(calm ? Min(sys.GetLairCalmTicks() + 1, 1000) : 0);
  if sys.IsLairActive() {
    CBLairWatch(sys, game, player, on);
    return;
  }
  if tick % 10 == 0 {
    CBSweepStrayLairBodies(sys, game, player.GetWorldPosition());
  }
  if on && tick % CBConfig.LairTryEveryTicks() == 0 {
    CBLairTryPlace(sys, game, player);
  }
}

// Keep note of where the Rival out in the world is standing, while they are standing, so the
// street can say where they were last seen even once their body has streamed out of reach
// (CBNoteRivalSeen). One read of a position every other tick, on our own recorded body only.
// Every Rival of the encounter, the one leading and anybody who came with them (1.9.0): one of a team
// who got away left no sighting behind, because only the lead's position was ever noted.
func CBTrackRivalWhereabouts(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if sys.GetActiveRivalId() > 0 {
    CBTrackOneRivalWhereabouts(sys, game, sys.GetActiveRivalId());
  }
  for pid in sys.GetPackRivals() {
    CBTrackOneRivalWhereabouts(sys, game, pid);
  }
}

func CBTrackOneRivalWhereabouts(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32) -> Void {
  let r = sys.FindRivalById(id);
  if !IsDefined(r) || !EntityID.IsDefined(r.spawnedEntityId) {
    return;
  }
  let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
  if CBStillStanding(body) && CBNpcSafe(sys, body)
     && !VehicleComponent.IsMountedToVehicle(game, body.GetEntityID()) {
    sys.NoteRivalLastPos(id, body.GetWorldPosition());
  }
}

// Put them there, if everything says it is safe to.
func CBLairTryPlace(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
  if sys.GetLairCalmTicks() < CBConfig.LairCalmTicks() {
    return;
  }
  let lead = CBCurrentLead(sys, game);
  if !IsDefined(lead) {
    return;
  }
  let center = CBSightingPos(lead);
  let ppos = player.GetWorldPosition();
  // Anywhere within reach of the place, the place itself included. This used to refuse V closer
  // than 30 m, and getting out of a car at the pin, or walking straight up to it, is exactly
  // that: so the place was empty when V arrived, and the Rival was only put there once V had
  // wandered back out past 30 m looking for them - into whatever V had just turned away from.
  // How close a spot may be to V is now a test on the spot, below.
  if Vector4.Distance(ppos, center) > CBConfig.LairPlaceDistance() {
    return;
  }
  let r = CBSightingRival(sys, lead);
  if !IsDefined(r) || !CBTipEligible(sys, game, r) || !TDBID.IsValid(r.recordID) || !CBRecordIsPerson(r.recordID) {
    return;
  }
  // Nobody else of ours out or coming, no live encounter, room under the ceiling, and the story
  // not about to want the stage. The same gates an arrival has, plus "nothing else going on".
  if sys.GetActiveRivalId() > 0 || CBHuntersOut(sys, game) || CBHuntPending(sys)
     || CBStoryHoldNow(game) || !CBWorldStable(game) {
    return;
  }
  if CBSpawnRoom(game) <= 0 {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let fwd = player.GetWorldForward();
  let inner = CBConfig.LairSearchRadius();
  let outer = CBConfig.LairOuterSearchRadius();
  // The spot itself, then six round it, then six further out between those. Every test is one
  // an ordinary arrival passes - a floor under them, on the navmesh, not at a job or in a safe
  // area, a path to V - except the one about being seen. Somebody who is going to stand still
  // where V is looking for them has to be put where V cannot see them at all, whichever way V
  // turns while the body streams in (CBPointHiddenFrom); the walk-in test let a point merely
  // behind V through. The cheap rays go before the path query. The first spot that passes is
  // used; none passing means not this time, and the next try is three seconds off.
  let k = 0;
  while k < 13 {
    let px = center.X;
    let py = center.Y;
    if k > 0 && k <= 6 {
      let angIn = Cast<Float>(k - 1) * 1.0472;
      px = center.X + CosF(angIn) * inner;
      py = center.Y + SinF(angIn) * inner;
    }
    if k > 6 {
      let angOut = Cast<Float>(k - 7) * 1.0472 + 0.5236;
      px = center.X + CosF(angOut) * outer;
      py = center.Y + SinF(angOut) * outer;
    }
    k += 1;
    let snapped: Vector4;
    let at: Vector4;
    if CBNavSnap(game, px, py, center.Z, snapped) && CBSettleOnGround(game, snapped, at)
       && Vector4.Distance(at, ppos) >= CBConfig.LairMinDistance()
       && !CBSafeAreaBlocksSpawn(game, at)
       && CBPointHiddenFrom(game, ppos, fwd, at)
       && CBPointReachable(game, at, ppos) {
      // Facing anywhere but at V: they are minding their own business.
      let yaw = RandRangeF(0.0, 6.2831);
      let facing = Quaternion.BuildFromDirectionVector(new Vector4(CosF(yaw), SinF(yaw), 0.0, 0.0));
      let body: EntityID;
      if CBCreateSpawn(des, r.recordID, r.appearance, at, facing, n"CB_Lair", body) {
        r.spawnedEntityId = body;
        // V found them before their turn came round: the lane lets them go rather than send the
        // same person after V from somewhere else as well. The lane is busy while they wait, and
        // picks again once this encounter is over.
        if sys.GetLaneRivalId(CBLaneRival()) == r.id {
          sys.ClearLane(CBLaneRival());
        }
        // Nothing else may think it sent them: a leftover arrival check from an earlier walk-in
        // would otherwise have the Rival tick re-examine this body as if it had.
        r.arrivalCheckTicks = 0;
        // At large, not hunting: CBLiveRivalPresent and everything keyed off it must not read a
        // Rival who is minding their own business as one who is out looking for V.
        r.state = EnumInt(ECBRivalState.Active);
        sys.SetLair(r.id);
        CBLog.Info(n"Rivals", s"Rival \(r.id) is waiting at their place.");
      }
      return;
    }
  }
}

// Somebody is waiting. Has the fight started, has V gone, or is it over?
func CBLairWatch(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, on: Bool) -> Void {
  let r = sys.FindRivalById(sys.GetLairRivalId());
  // Over already: killed (the death handler closed the encounter and forgot the body), spared
  // (the mercy path did the same), forgotten, or retired.
  if !IsDefined(r) || !EntityID.IsDefined(r.spawnedEntityId)
     || r.state != EnumInt(ECBRivalState.Active) {
    sys.ClearLair();
    return;
  }
  let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
  if IsDefined(body) && body.IsDead() {
    sys.ClearLair();   // the death handler has it
    return;
  }
  // Down but breathing: never removed from here. If V put them down, the mercy path settles it
  // within seconds (CBHandleSpared closes the encounter, which forgets the body, and the check
  // above clears this on the next tick); taking the body first would leave it nobody to settle.
  // If somebody else did, nothing ever will, so let go of them now and leave the body to the
  // stray sweep, rather than hold the Rival lane on somebody lying in the street.
  //
  // And if V did, but the record that settles it is gone - pushed out, or settled without closing
  // anything because the Rivals switch went off in between - nothing ever will either. That held
  // the Rival lane, and the marker on the body, for the rest of the session.
  if IsDefined(body) && !CBStillStanding(body) {
    if !body.cbSparedLogged || !sys.HasEscapee(body.GetEntityID()) {
      CBUntrackOnMap(game, body);
      let none: EntityID;
      r.spawnedEntityId = none;
      sys.ClearLair();
    }
    return;
  }
  if IsDefined(body) && CBNpcSafe(sys, body) && (CBNpcInCombat(body) || body.cbDamagedByPlayer) {
    CBLairPromote(sys, game, r, body);
    return;
  }
  // Still waiting. Taken back out, quietly, if V has gone, the story wants the stage, the switch
  // went off, or the engine never put them in the world at all.
  let ppos = player.GetWorldPosition();
  let far = true;
  if IsDefined(body) {
    far = Vector4.Distance(body.GetWorldPosition(), ppos) > CBConfig.LairLeaveDistance();
  } else {
    let s = CBSightingFor(sys, r);
    if IsDefined(s) {
      far = Vector4.Distance(CBSightingPos(s), ppos) > CBConfig.LairLeaveDistance();
    }
  }
  let noShow = !IsDefined(body) && (sys.GetTickCount() - sys.GetLairPlacedTick()) > 60;
  if far || noShow || !on || sys.GetStoryHold() != CBStoryNone() {
    CBLairStandDown(sys, game);
  }
}

// The fight has started: from here on they are a Rival encounter like any other.
func CBLairPromote(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, body: ref<ScriptedPuppet>) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let id = body.GetEntityID();
  // The same two calls the combat release has always used to move a body between tags.
  des.UnassignTag(id, n"CB_Lair");
  des.AssignTag(id, n"CB_Rival");
  sys.ClearLair();
  let now = CBGameSeconds(game);
  // What CBRivalOnTheirWay sets for one who walked in, so the encounter code finds them where it
  // expects them: hunting, the active Rival, and the retire clock starting now rather than from
  // whenever the last encounter was.
  r.state = EnumInt(ECBRivalState.Hunting);
  r.lastSeenAt = now;
  sys.SetActiveRivalId(r.id);
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastRivalEncounterAt = now;
  }
  sys.SetHuntGrade("RIVAL");
  if CBRivalGrade(r) >= CBConfig.RivalBossBarGrade() {
    CBShowBossBar(body);
  }
  // The lead is spent. Survive this and they are seen again wherever it ends.
  if sys.IsLeadPinned() && sys.GetLeadPinRival() == r.id {
    CBDropLead(sys, game);
  }
  let svc = sys.GetPlayService();
  if IsDefined(svc) {
    svc.DropSighting(sys.GetPlaythroughId(), r.id);
  }
  let line = "So somebody sold me out. Fine. Come and get it.";
  if r.killedV > 0 {
    line = "Came to finish it yourself? Good. Saves me the trip.";
  }
  CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), line, CBHudRed());
  CBLog.Info(n"Rivals", s"Rival \(r.id) was found at their place; the fight is on.");
}

// Take a waiting Rival back out of the world, without a word: nobody escaped anybody. Living
// bodies only, and only out of V's sight; one still in view is handed to the orphan sweep.
public func CBLairStandDown(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if IsDefined(sys) && sys.IsLairActive() {
    let r = sys.FindRivalById(sys.GetLairRivalId());
    if IsDefined(r) {
      let none: EntityID;
      r.spawnedEntityId = none;
    }
    sys.ClearLair();
  }
  CBUntrackTagged(game, n"CB_Lair");
  CBDeleteTaggedSafe(game, n"CB_Lair", true, true);
}

// A body that was waiting at somebody's place and is nobody's encounter any more: spared and left
// lying there, say. Removed once V is well away and cannot see it. The dead are the remains
// sweep's, as they are for every other body of ours.
func CBSweepStrayLairBodies(sys: ref<CyberbaneSystem>, game: GameInstance, ppos: Vector4) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !des.IsPopulated(n"CB_Lair") || !CBWorldStable(game) {
    return;
  }
  let ids = des.GetTaggedIDs(n"CB_Lair");
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && !p.IsDead() && Vector4.Distance(p.GetWorldPosition(), ppos) > CBConfig.LairLeaveDistance() {
      CBRemoveOne(game, des, id, false, true);
    }
  }
}

// ---- The payoff -----------------------------------------------------------------------------

// Put down before they ever got into the fight. Called from the death handler after the ordinary
// slain path has run, so this only adds to it.
public func CBLairAmbushed(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(r) {
    return;
  }
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints((25.0 + 10.0 * Cast<Float>(r.rank)) * CBConfig.LairAmbushRenownShare() * mult);
  let now = CBGameSeconds(game);
  CBFileLog(sys, n"RivalAmbushed", now, CBEventDistrict(sys, game), r.faction, Cast<Float>(r.rank));
  // Word gets back to whoever pointed V there.
  let from = n"";
  let svc = sys.GetPlayService();
  if IsDefined(svc) {
    let s = svc.FindSighting(sys.GetPlaythroughId(), r.id);
    if IsDefined(s) {
      from = s.tipFaction;
    }
    svc.DropSighting(sys.GetPlaythroughId(), r.id);
  }
  if sys.IsLeadPinned() && sys.GetLeadPinRival() == r.id {
    CBDropLead(sys, game);
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  if IsNameValid(from) {
    CBHearsayFromAlly(game, from, s"Heard about \(name). Never saw you coming. Clean work.", n"");
  } else {
    CBHearsayFromStreet(game, s"Word is \(name) never saw it coming.", n"");
  }
  CBLog.Info(n"Rivals", s"Rival \(r.id) ambushed at their place.");
}

// ---- Buying it (the Hub's Ambush button, 1.8.2) ------------------------------------------------
//
// The other way to a lead: instead of waiting for somebody to text it, V pays for it. Everything after
// the purchase is the system above, untouched - the pin, the waiting Rival, the ambush - so this only
// has to produce a tipped sighting, which is exactly what CBTipTick produces.

public func CBWhereaboutsPrice(r: ref<CBRival>) -> Int32 {
  if !IsDefined(r) {
    return 0;
  }
  return CBConfig.WhereaboutsPriceBase() + CBConfig.WhereaboutsPricePerRank() * Max(r.rank, 1);
}

// Whether a Rival's whereabouts are for sale, and if not, why:
// 0 for sale, 1 hideouts are switched off, 2 out after V or on their way, 3 V already knows,
// 4 not somebody still after V.
public func CBWhereaboutsForSale(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Int32 {
  if !IsDefined(sys) || !IsDefined(r)
     || (r.state != EnumInt(ECBRivalState.Active) && r.state != EnumInt(ECBRivalState.Hunting)) {
    return 4;
  }
  if !CBHideoutsOn() {
    return 1;
  }
  if sys.IsLairActive() && sys.GetLairRivalId() == r.id {
    return 3;
  }
  let lead = CBCurrentLead(sys, game);
  if IsDefined(lead) && lead.rivalId == r.id {
    return 3;
  }
  if !CBTipEligible(sys, game, r) {
    return 2;
  }
  return 0;
}

// Somewhere near V a Rival could be holed up: standing room the navigation system offers, which no
// safe area, no job and no quest covers (CBLairPointUsable). Searched from a random bearing, so it is
// not always the same street.
func CBWhereaboutsSpot(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, out spot: Vector4) -> Bool {
  let a = RandRangeF(-3.14159, 3.14159);
  let dir = new Vector4(CosF(a), SinF(a), 0.0, 0.0);
  let pts: array<Vector4>;
  if !CBPursuitPoints(game, player.GetWorldPosition(), dir, CBConfig.WhereaboutsCandidates(),
                      CBConfig.WhereaboutsMinDistance(), CBConfig.WhereaboutsMaxDistance(), pts) {
    return false;
  }
  let i = 0;
  while i < ArraySize(pts) {
    let p = pts[i];
    i += 1;
    if CBLairPointUsable(sys, game, p) {
      spot = p;
      return true;
    }
  }
  return false;
}

// Carry out a purchase chosen on the Hub, from the settled tick (CyberbaneSystem.ServiceHubActions).
// Nothing is paid unless there is a place to sell: where they were last seen, when that still holds,
// or else somewhere the seller tracks them down near V.
public func CBBuyRivalWhereabouts(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32) -> Bool {
  if !IsDefined(sys) || !CBWorldStable(game) {
    return false;
  }
  let r = sys.FindRivalById(id);
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  let svc = sys.GetPlayService();
  if !IsDefined(r) || !IsDefined(player) || !IsDefined(ts) || !IsDefined(svc) {
    return false;
  }
  let why = CBWhereaboutsForSale(sys, game, r);
  if why != 0 {
    CBLog.Info(n"Rivals", s"Whereabouts of rival \(id) not for sale any more (\(why)).");
    return false;
  }
  let price = CBWhereaboutsPrice(r);
  let money = ItemID.FromTDBID(t"Items.money");
  if ts.GetItemQuantity(player, money) < price {
    CBSystemNote(game, s"not enough eddies for that. It costs \(price)eb.", 4.0);
    return false;
  }
  let now = CBGameSeconds(game);
  let pid = sys.GetPlaythroughId();
  let s = CBSightingFor(sys, r);
  // A sighting from a newer branch of this playthrough is not this save's to sell, and one where a
  // Rival can no longer be put is no place at all.
  let usable = IsDefined(s) && now >= s.seenAt && CBLairPointUsable(sys, game, CBSightingPos(s));
  if !usable {
    let spot: Vector4;
    if !CBWhereaboutsSpot(sys, game, player, spot) {
      CBSystemNote(game, "nobody could find them from here. Try again somewhere else.", 5.0);
      CBLog.Info(n"Rivals", s"Whereabouts of rival \(id): no usable place near V; nothing paid.");
      return false;
    }
    svc.NoteSighting(pid, r.id, r.recordID, spot, sys.GetCurrentDistrict(), now);
    s = svc.FindSighting(pid, r.id);
  }
  if !IsDefined(s) {
    return false;
  }
  ts.RemoveItem(player, money, price);
  let tipster = CBPickTipster(sys, r.faction);
  s.tippedAt = now;
  s.tipFaction = tipster;
  sys.SetLastTipAt(now);
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let line = CBTipLine(name, CBPlacePhrase(s.district), IsNameValid(tipster), CBMapMarkersOn());
  if IsNameValid(tipster) {
    CBPhoneFromAlly(game, tipster, line);
  } else {
    if IsNameValid(s.district) {
      CBPhoneFromDistrict(game, s.district, line);
    } else {
      CBPhoneFromStreet(game, line);
    }
  }
  CBLog.Info(n"Rivals", s"Bought rival \(id)'s whereabouts for \(price)eb: \(NameToString(s.district)).");
  return true;
}
