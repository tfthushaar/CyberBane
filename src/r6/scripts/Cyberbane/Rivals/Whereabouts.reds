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
  // Nor V's own building (2.7.1, Spawn/HomeGround.reds).
  return !CBHomePointKept(game, at);
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
  // Nobody tips V off about a faction switched off in Mod Settings (1.9.1): a tip ends in a fight.
  if !CBFactionOn(r.faction) {
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
  return StrLen(place) > 0 ? CBTf(n"Cyberbane-Whispers-In", [place]) : CBT(n"Cyberbane-Whereabouts-AroundTown");
}

func CBTipLine(name: String, inPlace: String, fromGang: Bool, pinned: Bool) -> String {
  let pin = pinned ? CBT(n"Cyberbane-StreetIntel-ItSOnYourMap") : "";
  if fromGang {
    switch RandRange(0, 3) {
      case 0: return CBTf(n"Cyberbane-Whereabouts-HeardYouGotBeefWithOur", [s"\(name)", s"\(inPlace)", s"\(pin)"]);
      case 1: return CBTf(n"Cyberbane-Whereabouts-HasBeenSeenYouWantThem", [s"\(name)", s"\(inPlace)", s"\(pin)"]);
      default: return CBTf(n"Cyberbane-Whereabouts-WordFromOurCornersIsLying", [s"\(name)", s"\(inPlace)", s"\(pin)"]);
    }
  }
  switch RandRange(0, 2) {
    case 0: return CBTf(n"Cyberbane-Whereabouts-SawEarlierHeardTheyHaveIt", [s"\(name)", s"\(inPlace)", s"\(pin)"]);
    default: return CBTf(n"Cyberbane-Whereabouts-YourFriendIsHoledUpYou", [s"\(name)", s"\(inPlace)", s"\(pin)"]);
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
  // With TweakXL (2.5.0) the pin is Cyberbane's own and sits under the map's CYBERBANE box (UI/MapPins.reds).
  data = CBPlacePinData(CBRivalPinCaption(CBRivalDisplayName(sys.GetContent(), CBSightingRival(sys, lead))));
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
    CBWithdrawWord(game, gone[i]);   // they waited, and nobody came
    i += 1;
  }
  let k = 0;
  while k < ArraySize(staleName) {
    let line = CBTf(n"Cyberbane-Whereabouts-MovedOnFromTookTooLong", [s"\(staleName[k])", s"\(CBPlacePhrase(staleWhere[k]))"]);
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
    CBLeadWitnessTick(sys, game, player);   // somebody who saw them, on the way there (2.6.5, Spawn/StreetStories.reds)
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
    CBLairHintTick(sys, game, player, CBLairTryPlace(sys, game, player));
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

// When the body at the place was last seen down, so one V put down gets time to be logged as a
// mercy before the place lets go of it (CBLairWatch, 1.9.3).
@addField(ScriptedPuppet)
public let cbLairDownTick: Int32;

// The place lets go of somebody lying there whom nothing is going to settle. They were found, so
// the tip is spent: the sighting and its pin go, the body stops being a Rival's (V finishing them
// later still counts, CBRetireRivalBody), and they lie low as after any other meeting.
func CBLairGiveUp(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, body: ref<ScriptedPuppet>) -> Void {
  CBUntrackOnMap(game, body);
  CBRetireRivalBody(sys, game, body, r);
  let none: EntityID;
  r.spawnedEntityId = none;
  r.huntTicks = Max(r.huntTicks, CBConfig.RivalAfterEscapeTicks());
  sys.ClearLair();
  if sys.IsLeadPinned() && sys.GetLeadPinRival() == r.id {
    CBDropLead(sys, game);
  }
  let svc = sys.GetPlayService();
  if IsDefined(svc) {
    svc.DropSighting(sys.GetPlaythroughId(), r.id);
  }
  CBWithdrawWord(game, r.id);
  CBLog.Info(n"Rivals", s"Rival \(r.id) was left lying at their place; the lead is spent.");
}

// Is anybody still breathing at a Rival's place? One body at a time: nobody new is put there while
// somebody is (1.9.3).
func CBLairBodyAround(game: GameInstance, des: ref<DynamicEntitySystem>) -> Bool {
  if !IsDefined(des) || !des.IsPopulated(n"CB_Lair") {
    return false;
  }
  let ids = des.GetTaggedIDs(n"CB_Lair");
  let i = 0;
  while i < ArraySize(ids) {
    let p = GameInstance.FindEntityByID(game, ids[i]) as ScriptedPuppet;
    i += 1;
    if IsDefined(p) && !p.IsDead() {
      return true;
    }
  }
  return false;
}

// Why nobody could be put at the place this pass (CBLairTryPlace), for the hint V gets when the
// place stays empty: 0 nothing to say, 1 V is not settled on foot, 2 somebody else is after V,
// 3 nowhere out of V's sight.
public func CBLairMissNone() -> Int32 = 0
public func CBLairMissNotCalm() -> Int32 = 1
public func CBLairMissBusy() -> Int32 = 2
public func CBLairMissNoSpot() -> Int32 = 3
public func CBLairMissDaytime() -> Int32 = 4   // they keep hours, and are out by day (2.4.4, [U10])

// V is standing at the pin and nobody is there. Said once per Rival, after a fair wait, with the
// reason, because an empty place with no word read as a coin toss ("is it chance-based?").
func CBLairHintTick(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, miss: Int32) -> Void {
  let lead = CBCurrentLead(sys, game);
  if miss == CBLairMissNone() || !IsDefined(lead)
     || Vector4.Distance(player.GetWorldPosition(), CBSightingPos(lead)) > CBConfig.LairHintDistance() {
    sys.SetLairMisses(0);
    return;
  }
  let misses = sys.GetLairMisses() + 1;
  sys.SetLairMisses(misses);
  if misses != CBConfig.LairHintTries() || sys.GetLairHinted() == lead.rivalId {
    return;
  }
  sys.SetLairHinted(lead.rivalId);
  let line = CBT(n"Cyberbane-Whereabouts-NobodyAtThePlaceYetThey");
  if miss == CBLairMissNotCalm() {
    line = CBT(n"Cyberbane-Whereabouts-NobodyAtThePlaceYetCome");
  }
  if miss == CBLairMissBusy() {
    line = CBT(n"Cyberbane-Whereabouts-NobodyAtThePlaceYetThey-2");
  }
  if miss == CBLairMissDaytime() {
    line = CBT(n"Cyberbane-Whereabouts-NobodyHomeTheyKeepHoursOut");
  }
  CBSystemNote(game, line, 6.0);
}

// Put them there, if everything says it is safe to.
func CBLairTryPlace(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Int32 {
  let lead = CBCurrentLead(sys, game);
  if !IsDefined(lead) {
    return CBLairMissNone();
  }
  if sys.GetLairCalmTicks() < CBConfig.LairCalmTicks() {
    return CBLairMissNotCalm();
  }
  let center = CBSightingPos(lead);
  let ppos = player.GetWorldPosition();
  // Anywhere within reach of the place, the place itself included. This used to refuse V closer
  // than 30 m, and getting out of a car at the pin, or walking straight up to it, is exactly
  // that: so the place was empty when V arrived, and the Rival was only put there once V had
  // wandered back out past 30 m looking for them - into whatever V had just turned away from.
  // How close a spot may be to V is now a test on the spot, below.
  if Vector4.Distance(ppos, center) > CBConfig.LairPlaceDistance() {
    return CBLairMissNone();
  }
  let r = CBSightingRival(sys, lead);
  if !IsDefined(r) || !CBTipEligible(sys, game, r) || !TDBID.IsValid(r.recordID) || !CBRecordIsPerson(r.recordID) {
    return CBLairMissNone();
  }
  // Somebody with a chair keeps hours: home by night, out by day, unless they named the place for V (2.4.4, [U10]).
  if CBRivalKeepsHours(game, r) && !CBIsNight(game) {
    return CBLairMissDaytime();
  }
  // Nobody else of ours out or coming, no live encounter, room under the ceiling, and the story
  // not about to want the stage. The same gates an arrival has, plus "nothing else going on".
  if sys.GetActiveRivalId() > 0 || CBHuntersOut(sys, game) || CBHuntPending(sys)
     || CBStoryHoldNow(game) || !CBWorldStable(game) {
    return CBLairMissBusy();
  }
  if CBSpawnRoom(game) <= 0 {
    return CBLairMissBusy();
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || CBLairBodyAround(game, des) {
    return CBLairMissNone();
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
  // A third ring further out (1.9.3): on an open lot both nearer rings can be in plain view.
  let k = 0;
  while k < 19 {
    let px = center.X;
    let py = center.Y;
    if k > 0 && k <= 6 {
      let angIn = Cast<Float>(k - 1) * 1.0472;
      px = center.X + CosF(angIn) * inner;
      py = center.Y + SinF(angIn) * inner;
    }
    if k > 6 && k <= 12 {
      let angOut = Cast<Float>(k - 7) * 1.0472 + 0.5236;
      px = center.X + CosF(angOut) * outer;
      py = center.Y + SinF(angOut) * outer;
    }
    if k > 12 {
      let angFar = Cast<Float>(k - 13) * 1.0472 + 0.2618;
      px = center.X + CosF(angFar) * CBConfig.LairFarSearchRadius();
      py = center.Y + SinF(angFar) * CBConfig.LairFarSearchRadius();
    }
    k += 1;
    let snapped: Vector4;
    let at: Vector4;
    if CBNavSnap(game, px, py, center.Z, snapped) && CBSettleOnGround(game, snapped, at)
       && Vector4.Distance(at, ppos) >= CBConfig.LairMinDistance()
       && !CBSafeAreaBlocksSpawn(game, at)
       && CBPointHiddenFrom(game, ppos, fwd, at)
       && CBStandsWith(game, at, center, 8.0)
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
        let alarmBook = CBRivalBook.Get(game);
        if IsDefined(alarmBook) {
          alarmBook.ResetLairAlarm();   // nobody has seen V yet at this place
        }
        CBLog.Info(n"Rivals", s"Rival \(r.id) is waiting at their place.");
        // Their people with them (Rivals/RivalLife.reds, 1.9.9).
        CBLairGuards(sys, game, des, r, at);
      }
      return CBLairMissNone();
    }
  }
  return CBLairMissNoSpot();
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
  // On their way in or out of the world: nothing is read from them, and nothing decided, until they are one or
  // the other (2.4.2). Taken as not standing, a body caught streaming was let go as if left lying there, and the
  // lead was spent.
  if IsDefined(body) && !body.IsAttached() {
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
  //
  // 1.9.3: letting go used to leave the tip standing. A takedown is a scene of its own, so for its
  // first seconds the body is down and the mercy path has not logged it yet; this let go at once,
  // and with the lead still live the next pass put a second body of the same Rival at the place.
  // A player knocked one out, then the next, then the next. So a body V put down is given time to
  // be logged, and letting go now ends the lead too (CBLairGiveUp).
  if IsDefined(body) && !CBStillStanding(body) {
    if body.cbSparedLogged && sys.HasEscapee(body.GetEntityID()) {
      return;   // the mercy path has it
    }
    let tick = sys.GetTickCount();
    if body.cbLairDownTick == 0 {
      body.cbLairDownTick = Max(tick, 1);
    }
    if body.cbDamagedByPlayer && !body.cbSparedLogged
       && (tick - body.cbLairDownTick) < CBConfig.LairDownWaitTicks() {
      return;
    }
    CBLairGiveUp(sys, game, r, body);
    return;
  }
  // Or one of their people (2.5.7): waiting calm, a guard V shot left the Rival standing there calm beside them.
  if IsDefined(body) && CBNpcSafe(sys, body) && (CBNpcInCombat(body) || body.cbDamagedByPlayer || CBLairGuardHit(sys, game)) {
    CBLairPromote(sys, game, r, body);
    return;
  }
  // Walked up to openly, with a facedown owed (2.5.7): they step out to face V, and the facedown opens from the Rival's
  // own tick (Rivals/RivalMoments.reds). Crouched, V is sneaking up, and it stays an ambush.
  if IsDefined(body) && CBNpcSafe(sys, body) && body.cbFacedownWait && !player.IsInCombat() && !CBPlayerCrouched(game)
     && Vector4.Distance(body.GetWorldPosition(), player.GetWorldPosition()) <= CBConfig.FacedownRange() {
    CBLairPromote(sys, game, r, body);
    return;
  }
  // One of their people has seen V and run to warn them (2.5.0, [U10]): they move before V gets there.
  if IsDefined(body) && CBLairAlarm(sys, game, player, r) {
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
  // Their people waiting calm for a facedown step out with them as the Rival's escorts (2.5.7), so the facedown holds
  // them, lets them go and turns them on V as it does any Rival's people; and every wait counts from now, not from when
  // they were put at the place. Those spawned hostile stay as they were.
  let tickNow = Max(sys.GetTickCount(), 1);
  let lairIds = des.GetTaggedIDs(n"CB_Lair");
  for gid in lairIds {
    let g = GameInstance.FindEntityByID(game, gid) as ScriptedPuppet;
    if IsDefined(g) && g.cbFacedownWait {
      g.cbFacedownWaitTick = tickNow;
      g.cbFacedownWaitHeld = 0;
      g.cbFacedownWaitSeen = 0;
      if NotEquals(gid, id) {
        des.UnassignTag(gid, n"CB_Lair");
        des.AssignTag(gid, n"CB_Escort");
      }
    }
  }
  // The same two calls the combat release has always used to move a body between tags.
  des.UnassignTag(id, n"CB_Lair");
  des.AssignTag(id, n"CB_Rival");
  sys.ClearLair();
  // Their marker said they were at their place; now they are after V (UI/Tracking.reds, 2.5.4).
  if body.cbMapped {
    CBUntrackOnMap(game, body);
    CBTrackOnMap(game, body);
  }
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
  sys.SetHuntGrade(CBT(n"Cyberbane-Whereabouts-RIVAL"));
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
  let line = CBT(n"Cyberbane-Whereabouts-SoSomebodySoldMeOutFine");
  let bookW = CBIntelBook.Get(game);
  if IsDefined(bookW) && bookW.WordSent(r.id) {
    line = CBTf(n"Cyberbane-Whereabouts-YouCameGood", [CBRivalCatchphrase(r)]);
  } else {
  if r.killedV > 0 {
    line = CBT(n"Cyberbane-Whereabouts-CameToFinishItYourselfGood");
  }
  }
  CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), line, CBHudRed());
  CBLog.Info(n"Rivals", s"Rival \(r.id) was found at their place; the fight is on.");
}

// One of the people waiting at a Rival's place hurt by V, or fighting (2.5.7). Our own field first, then the per-NPC gate.
func CBLairGuardHit(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !des.IsPopulated(n"CB_Lair") {
    return false;
  }
  let ids = des.GetTaggedIDs(n"CB_Lair");
  for gid in ids {
    let g = GameInstance.FindEntityByID(game, gid) as ScriptedPuppet;
    if IsDefined(g) && (g.cbDamagedByPlayer || (CBNpcSafe(sys, g) && CBNpcInCombat(g))) {
      return true;
    }
  }
  return false;
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
    CBHearsayFromAlly(game, from, CBTf(n"Cyberbane-Whereabouts-HeardAboutNeverSawYouComing", [s"\(name)"]), n"");
  } else {
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-Whereabouts-WordIsNeverSawItComing", [s"\(name)"]), n"");
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
  // Their faction is switched off in Mod Settings (1.9.1).
  if !CBFactionOn(r.faction) {
    return 5;
  }
  if !CBHideoutsOn() {
    return 1;
  }
  if sys.IsLairActive() && sys.GetLairRivalId() == r.id {
    return 3;
  }
  // Right here: in V's encounter, or their body in the world (down at V's feet, standing for a facedown). Nobody can
  // sell where they are hiding. A Rival V had put down and was talking to gave up "where they were lying low" (2.6.0).
  if r.id == sys.GetActiveRivalId() || CBRivalBodyPresent(game, r) {
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

// Where a Rival is holed up, ready to be told to V: where they were last seen, when that still holds,
// or else somewhere near V they are tracked down to (CBWhereaboutsSpot). Null when there is nowhere they
// could be put. Shared by a purchase on the Hub and by an informant V leans on in the street
// (Reactions/StreetTalk.reds, 1.9.5), so the two can never disagree about where somebody is.
public func CBRivalHideout(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                           r: ref<CBRival>) -> ref<CBSighting> {
  let svc = sys.GetPlayService();
  if !IsDefined(svc) || !IsDefined(r) || !IsDefined(player) {
    return null;
  }
  let now = CBGameSeconds(game);
  let s = CBSightingFor(sys, r);
  // A sighting from a newer branch of this playthrough is not this save's to tell, and one where a
  // Rival can no longer be put is no place at all.
  let usable = IsDefined(s) && now >= s.seenAt && CBLairPointUsable(sys, game, CBSightingPos(s));
  if !usable {
    let spot: Vector4;
    if !CBWhereaboutsSpot(sys, game, player, spot) {
      return null;
    }
    svc.NoteSighting(sys.GetPlaythroughId(), r.id, r.recordID, spot, sys.GetCurrentDistrict(), now);
    s = svc.FindSighting(sys.GetPlaythroughId(), r.id);
  }
  return s;
}

// V has been told. The lead, the pin and the Hub's file all follow from this (CBCurrentLead).
public func CBMarkLeadTold(sys: ref<CyberbaneSystem>, s: ref<CBSighting>, tipster: CName, now: Float) -> Void {
  if !IsDefined(sys) || !IsDefined(s) {
    return;
  }
  s.tippedAt = now;
  s.tipFaction = tipster;
  sys.SetLastTipAt(now);
}

// Carry out a purchase chosen on the Hub, from the settled tick (CyberbaneSystem.ServiceHubActions).
// Nothing is paid unless there is a place to sell: where they were last seen, when that still holds,
// or else somewhere the seller tracks them down near V.
public func CBBuyRivalWhereabouts(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32,
                                  opt agreedPrice: Int32, opt dealTipster: CName, opt dealSender: String) -> Bool {
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
  let price = agreedPrice > 0 ? agreedPrice : CBWhereaboutsPrice(r);
  let money = ItemID.FromTDBID(t"Items.money");
  if ts.GetItemQuantity(player, money) < price {
    CBMenuNote(game, CBTf(n"Cyberbane-Whereabouts-NotEnoughEddiesForThatIt", [s"\(price)"]), 4.0);
    return false;
  }
  let s = CBRivalHideout(sys, game, player, r);
  if !IsDefined(s) {
    CBMenuNote(game, CBT(n"Cyberbane-Whereabouts-NobodyCouldFindThemFromHere"), 5.0);
    CBLog.Info(n"Rivals", s"Whereabouts of rival \(id): no usable place near V; nothing paid.");
    return false;
  }
  ts.RemoveItem(player, money, price);
  let tipster = agreedPrice > 0 ? dealTipster : CBPickTipster(sys, r.faction);
  CBMarkLeadTold(sys, s, tipster, CBGameSeconds(game));
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let line = CBTipLine(name, CBPlacePhrase(s.district), IsNameValid(tipster), CBMapMarkersOn());
  // A deal made by text is answered in the same thread it was made in.
  if agreedPrice > 0 && StrLen(dealSender) > 0 {
    CBPhoneSendTinted(game, dealSender, line, CBHudCyan());
  } else {
    if IsNameValid(tipster) {
      CBPhoneFromAlly(game, tipster, line);
    } else {
      if IsNameValid(s.district) {
        CBPhoneFromDistrict(game, s.district, line);
      } else {
        CBPhoneFromStreet(game, line);
      }
    }
  }
  CBLog.Info(n"Rivals", s"Bought rival \(id)'s whereabouts for \(price)eb: \(NameToString(s.district)).");
  return true;
}

// ---- A lead as a deal by text (1.9.7) ----
//
// "Find them" on the Hub used to take the money and hand over the place in one go. With phone deals on,
// it puts the word out instead: whoever would sell it (the tipster CBPickTipster picks, or the broker for
// this part of town) texts V a price, and V answers in the thread: deal, too much, or forget it
// (UI/RealPhone.reds). The money and the place still go through CBBuyRivalWhereabouts.

public func CBPhoneDealsReady() -> Bool {
  let rt = CyberbaneRuntime.Get();
  let on = !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkPhoneDeals;
  return on && CBRealPhoneOn() && CBToastsOn();
}

// What the seller asks: the Hub's price, less from a gang that likes V, a little more from one that does
// not care, and never quite the same twice.
public func CBPhoneLeadPrice(sys: ref<CyberbaneSystem>, r: ref<CBRival>, tipster: CName) -> Int32 {
  let price = Cast<Float>(CBWhereaboutsPrice(r));
  let score = sys.GetScore();
  if IsNameValid(tipster) && IsDefined(score) {
    let posture = score.GetPosture(tipster);
    if Equals(posture, ECBPosture.Allied) {
      price *= 0.8;
    } else {
      if Equals(posture, ECBPosture.Friendly) {
        price *= 0.9;
      } else {
        price *= 1.1;
      }
    }
  }
  price *= RandRangeF(0.9, 1.15);
  return Max(100, RoundF(price / 50.0) * 50);
}

public func CBOfferRivalLead(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32) -> Bool {
  let r = sys.FindRivalById(id);
  if !IsDefined(r) || CBWhereaboutsForSale(sys, game, r) != 0 {
    return false;
  }
  let tipster = CBPickTipster(sys, r.faction);
  let sender = "";
  if IsNameValid(tipster) {
    sender = CBPhoneGangSender(tipster);
  } else {
    sender = NotEquals(sys.GetCurrentDistrict(), n"") ? CBPhoneDistrictSender(sys.GetCurrentDistrict()) : CBPhoneStreetSender(RandRange(0, 4));
  }
  let price = CBPhoneLeadPrice(sys, r, tipster);
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let line = "";
  switch RandRange(0, 3) {
    case 0: line = CBTf(n"Cyberbane-Whereabouts-HeardYouReAskingAfterI", [s"\(name)", s"\(price)"]); break;
    case 1: line = CBTf(n"Cyberbane-Whereabouts-WeKnowWhereEbAndYou", [s"\(name)", s"\(price)"]); break;
    default: line = CBTf(n"Cyberbane-Whereabouts-WordIsYouWantEbBuys", [s"\(name)", s"\(price)"]); break;
  }
  // The lead opens under the text as it lands (2.6.8, CBPhonePost).
  CBPhonePost(game, sender, line, CBHudCyan(), false, 3, tipster, r.id, price);
  CBLog.Info(n"Rivals", s"Put the word out for rival \(id); offered for \(price)eb by text.");
  return true;
}

// ---- [U10] A lookout who gets away (2.5.0) --------------------------------------------------------------------------
//
// One of a Rival's people at their place who has V in sight for a few seconds, before anybody has fired, runs to warn
// them, saying so. Stop them (down or dead) within a few seconds and nothing changes. If they get away, the Rival and
// their people leave, the place moves a short way off, and whoever told V where to look says so. The fight starting
// first settles it the other way: that is the ordinary encounter (CBLairPromote). One order to each, the run; every
// body taken out of the world only once V cannot see it.

// True when the place has just moved, and there is nothing left here to watch.
func CBLairAlarm(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, r: ref<CBRival>) -> Bool {
  let book = CBRivalBook.Get(game);
  let intel = CBStreetIntelFor(game);
  if !IsDefined(book) || !IsDefined(intel) {
    return false;
  }
  let tick = sys.GetTickCount();
  // Somebody already ran: stopped, or away.
  if EntityID.IsDefined(book.lairWarnBody) {
    let runner = GameInstance.FindEntityByID(game, book.lairWarnBody) as ScriptedPuppet;
    if IsDefined(runner) && CBIsDown(runner) {
      CBLog.Info(n"Rivals", s"Rival \(r.id)'s lookout was stopped before they could warn anybody.");
      book.ResetLairAlarm();
      return false;
    }
    if tick - book.lairWarnTick >= CBConfig.LairWarnTicks() {
      CBLairRelocate(sys, game, r, intel.GuardIds());
      return true;
    }
    return false;
  }
  // The witness showed V the way in nobody watches, or was paid to forget V (2.6.5): nobody here sees V coming.
  if book.lairQuiet {
    book.lairSeen = 0;
    return false;
  }
  // Does any of them have V in sight?
  let ppos = player.GetWorldPosition();
  // A mask, or their own gang's colours, gets V past them as it gets V past anybody on the street: only one of their
  // officers who looks long enough knows V (Reactions/Director.reds, CBSeesThroughDisguise) (2.5.0).
  let covered = CBPlayerMasked(game) || (Equals(r.faction, sys.GetDisguiseFaction()) && sys.GetDisguiseStrength() > 0.0);
  let spotter: ref<ScriptedPuppet>;
  for gid in intel.GuardIds() {
    let g = GameInstance.FindEntityByID(game, gid) as ScriptedPuppet;
    if !IsDefined(spotter) && CBNpcSafe(sys, g) && CBStillStanding(g) && !CBNpcInCombat(g) && !g.cbTalkPartner
       && Vector4.Distance(g.GetWorldPosition(), ppos) <= CBConfig.LairSpotRange() && CBWitnessCanSee(g, player)
       && (!covered || CBSeesThroughDisguise(sys, g, r.faction)) {
      spotter = g;
    }
  }
  if !IsDefined(spotter) {
    book.lairSeen = 0;
    return false;
  }
  book.lairSeen += 1;
  if book.lairSeen < CBConfig.LairSpotTicks() {
    return false;
  }
  // Seen long enough: they run to tell.
  book.lairWarnBody = spotter.GetEntityID();
  book.lairWarnTick = Max(tick, 1);
  CBIntelSay(game, 3, CBIntelSpeaker(r.faction), CBLineOf([CBTf(n"Cyberbane-Whereabouts-CompanyIsHere", [s"\(CBCapFirst(CBYou(sys, game)))"]),
                                                         CBT(n"Cyberbane-Whereabouts-WeVeBeenMadeGoGo"),
                                                         CBTf(n"Cyberbane-Whereabouts-ThatSIMOutOf", [s"\(CBYou(sys, game))"])]), 3.0);
  CBSayVoiced(sys, spotter, n"enemy_warning");
  CBOrderFlee(game, spotter);
  CBLog.Info(n"Rivals", s"One of Rival \(r.id)'s people saw V and ran to warn them.");
  return false;
}

// The warning got through: everybody at the place goes, and the place moves.
func CBLairRelocate(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, guards: array<EntityID>) -> Void {
  let book = CBRivalBook.Get(game);
  let runner: EntityID;
  if IsDefined(book) {
    runner = book.lairWarnBody;   // already running, their one order (CBLairAlarm)
    book.ResetLairAlarm();
  }
  let svc = sys.GetPlayService();
  let old = CBSightingFor(sys, r);
  let now = CBGameSeconds(game);
  // They leave on foot: the one order each.
  let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
  if CBNpcSafe(sys, body) && CBStillStanding(body) {
    CBOrderFlee(game, body);
  }
  for gid in guards {
    let g = GameInstance.FindEntityByID(game, gid) as ScriptedPuppet;
    if NotEquals(gid, runner) && CBNpcSafe(sys, g) && CBStillStanding(g) {
      CBOrderFlee(game, g);
    }
  }
  let intel = CBStreetIntelFor(game);
  if IsDefined(intel) {
    intel.ClearGuards();
  }
  CBLairStandDown(sys, game);
  CBDropLead(sys, game);   // the pin goes; it comes back at the new place, if there is one
  if !IsDefined(svc) || !IsDefined(old) {
    return;
  }
  let tipster = old.tipFaction;
  let district = old.district;
  let to: Vector4;
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let line = "";
  if CBLairSecondPlace(sys, game, CBSightingPos(old), to) {
    svc.NoteSighting(sys.GetPlaythroughId(), r.id, r.recordID, to, district, now);
    let moved = CBSightingFor(sys, r);
    if IsDefined(moved) {
      moved.tippedAt = now;   // still V's lead: the people who told V where to look know where they went
      moved.tipFaction = tipster;
    }
    line = CBLineOf([CBTf(n"Cyberbane-Whereabouts-OneOfPeopleSawYouComing", [s"\(CBPossessive(name))"]),
                     CBTf(n"Cyberbane-Whereabouts-KnowsYouReComingNowTheir", [s"\(name)"])]);
    if CBMapMarkersOn() {
      line += CBT(n"Cyberbane-StreetIntel-ItSOnYourMap");
    }
  } else {
    svc.DropSighting(sys.GetPlaythroughId(), r.id);
    line = CBTf(n"Cyberbane-Whereabouts-GotWarnedAndWentToGround", [s"\(name)"]);
  }
  CBFileLog(sys, n"LairMoved", now, district, r.faction, Cast<Float>(r.id));
  if IsNameValid(tipster) {
    CBPhoneFromAlly(game, tipster, line);
  } else {
    CBPhoneFromStreet(game, line);
  }
  CBLog.Info(n"Rivals", s"Rival \(r.id) was warned and moved.");
}

// Somewhere a short way off they could be waiting next: on the navmesh, standing room, where a place may be.
func CBLairSecondPlace(sys: ref<CyberbaneSystem>, game: GameInstance, from: Vector4, out to: Vector4) -> Bool {
  let start = RandRange(0, 12);
  let k = 0;
  while k < 12 {
    let ang = Cast<Float>((start + k) % 12) * 0.5236;
    let reach = CBConfig.LairMoveMin() + Cast<Float>(k % 3) * (CBConfig.LairMoveMax() - CBConfig.LairMoveMin()) * 0.5;
    k += 1;
    let snapped: Vector4;
    let spot: Vector4;
    if CBNavSnap(game, from.X + CosF(ang) * reach, from.Y + SinF(ang) * reach, from.Z, snapped)
       && CBSettleOnGround(game, snapped, spot) && CBLairPointUsable(sys, game, spot)
       && CBStandsWith(game, spot, from, 8.0) {
      to = spot;
      return true;
    }
  }
  return false;
}

// ---- [U9] Caught in the chair (2.5.0) -------------------------------------------------------------------------------
//
// A Rival who went under the knife (Rivals/RivalMoments.reds, CBRivalChromeTick) is, for a while, in a ripperdoc's
// chair: the ripperdoc nearest where they were last seen, from the game's own map (its ripperdoc pins). It is a lead
// like any tip: one at a time, a pin, the place keeping hours. True when there is one.
// A usable spot in the street by a door: two rings round it, the nearer first.
func CBSpotOutside(sys: ref<CyberbaneSystem>, game: GameInstance, door: Vector4, out to: Vector4) -> Bool {
  let k = 0;
  while k < 16 {
    let ang = Cast<Float>(k % 8) * 0.7854 + (k >= 8 ? 0.3927 : 0.0);
    let reach = k < 8 ? CBConfig.RipperdocOutsideNear() : CBConfig.RipperdocOutsideFar();
    k += 1;
    let snapped: Vector4;
    let spot: Vector4;
    if CBNavSnap(game, door.X + CosF(ang) * reach, door.Y + SinF(ang) * reach, door.Z, snapped)
       && CBSettleOnGround(game, snapped, spot) && CBLairPointUsable(sys, game, spot)
       && CBStandsWith(game, spot, door, CBConfig.GroundMaxDrop()) {
      to = spot;
      return true;
    }
  }
  return false;
}

public func CBRipperdocLead(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, implant: String) -> Bool {
  let svc = sys.GetPlayService();
  let ms = GameInstance.GetMappinSystem(game);
  if !CBHideoutsOn() || !IsDefined(svc) || !IsDefined(ms) || !IsDefined(r) || IsDefined(CBCurrentLead(sys, game))
     || !CBTipEligible(sys, game, r) || !CBWorldStable(game) {
    return false;
  }
  let near: Vector4;
  let nearDistrict = n"";
  let seen = CBSightingFor(sys, r);
  let player = GetPlayer(game);
  if IsDefined(seen) {
    near = CBSightingPos(seen);
    nearDistrict = seen.district;
  } else {
    if !IsDefined(player) {
      return false;
    }
    near = player.GetWorldPosition();
    nearDistrict = sys.GetCurrentDistrict();
  }
  // The clinics on the map, nearest first. A clinic is mostly a safe area, where no lead may be (CBLairPointUsable:
  // tips, bought whereabouts and the place itself all ask it), so the lead is the street outside the nearest one
  // that has a usable spot by its door (CBSpotOutside), a few of the nearest tried.
  let pins: array<ref<IMappin>>;
  ms.GetMappins(gamemappinsMappinTargetType.Map, pins);
  let clinics: array<Vector4>;
  for p in pins {
    if IsDefined(p) && Equals(p.GetVariant(), gamedataMappinVariant.ServicePointRipperdocVariant)
       && !sys.NearQuestPins(p.GetWorldPosition(), CBConfig.QuestSpawnClearance()) {
      ArrayPush(clinics, p.GetWorldPosition());
    }
  }
  let best: Vector4;
  let bestD = -1.0;
  let tries = 0;
  while bestD < 0.0 && tries < CBConfig.RipperdocClinicTries() && ArraySize(clinics) > 0 {
    tries += 1;
    let pick = 0;
    let k = 1;
    while k < ArraySize(clinics) {
      if Vector4.Distance(clinics[k], near) < Vector4.Distance(clinics[pick], near) {
        pick = k;
      }
      k += 1;
    }
    let outside: Vector4;
    if CBSpotOutside(sys, game, clinics[pick], outside) {
      best = outside;
      bestD = Vector4.Distance(clinics[pick], near);
    }
    ArrayErase(clinics, pick);
  }
  if bestD < 0.0 {
    return false;
  }
  let now = CBGameSeconds(game);
  // Nothing says which district a point is in, so the clinic is named by the district the search started from only
  // when it is close to there; further, the lead says "around town" rather than name the wrong place.
  let district = bestD <= CBConfig.RipperdocDistrictReach() ? nearDistrict : n"";
  svc.NoteSighting(sys.GetPlaythroughId(), r.id, r.recordID, best, district, now);
  let lead = CBSightingFor(sys, r);
  if !IsDefined(lead) {
    return false;
  }
  let tipster = CBPickTipster(sys, r.faction);
  lead.tippedAt = now;
  lead.tipFaction = tipster;
  sys.SetLastTipAt(now);
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let line = CBLineOf([CBTf(n"Cyberbane-Whereabouts-IsInARipperdocSChair", [s"\(name)", s"\(implant)"]),
                       CBTf(n"Cyberbane-Whereabouts-WordIsWentUnderTheKnife", [s"\(name)", s"\(implant)"])]);
  if CBRivalKeepsHours(game, r) {
    line += CBT(n"Cyberbane-Whereabouts-TheyLlBeThereAfterDark");
  }
  if CBMapMarkersOn() {
    line += CBT(n"Cyberbane-StreetIntel-ItSOnYourMap");
  }
  if IsNameValid(tipster) {
    CBPhoneFromAlly(game, tipster, line);
  } else {
    CBPhoneFromStreet(game, line);
  }
  CBFileLog(sys, n"RipperdocLead", now, CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
  CBLog.Info(n"Rivals", s"Rival \(r.id) is at a ripperdoc: a lead.");
  return true;
}
