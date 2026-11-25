// Cyberbane - The grapevine (spec §8.5)
//
// Propagation you can actually hear. When a rumor about you reaches a district it had not
// touched before, somebody who trades in information there gets in touch about what they heard.
// A contact saying "heard about Northside" lands harder than a meter filling, and it is the
// audible surface for the mod's signature mechanic.

// Who is passing it on. Roles, never a named quest-giver: the player must never read one of
// these as a real fixer offering real work.
// Somebody gets in touch about a thing you did.
public func CBContactMessage(game: GameInstance, body: String) -> Void {
  // From whoever works the part of town V is standing in, when that is known. Word about your
  // reputation reaching you from the local broker reads as the city; the same word from a
  // rotating "Unknown number" reads as a feed.
  let sys = CyberbaneSystem.Get(game);
  if IsDefined(sys) && NotEquals(sys.GetCurrentDistrict(), n"") {
    CBPhoneFromDistrict(game, sys.GetCurrentDistrict(), body);
    return;
  }
  CBPhoneFromStreet(game, body);
}

// Word that carries your name, because people were there to put it there. Through the line library
// (Narrative/Lines.reds), so a broker never sends the same text twice running; `seed` is kept for the callers.
func CBGrapevineNamedLine(kind: CName, where: String, seed: Int32) -> String {
  if Equals(kind, n"BossKill") {
    return CBLineOf([
      CBTf(n"Cyberbane-Grapevine-HeardWhatYouDidToTheir", [where]),
      CBTf(n"Cyberbane-Grapevine-BossOfTheirsDownCanT", [where]),
      CBTf(n"Cyberbane-Grapevine-EveryBarInIsDrinkingTo", [where])]);
  }
  if Equals(kind, n"Massacre") {
    return CBLineOf([
      CBTf(n"Cyberbane-Grapevine-WordOutOfIsYouLeft", [where]),
      CBTf(n"Cyberbane-Grapevine-WhatYouLeftInTheAmbulances", [where]),
      CBTf(n"Cyberbane-Grapevine-PeopleInAreDescribingItTo", [where])]);
  }
  return CBLineOf([
    CBTf(n"Cyberbane-Grapevine-YourNameCameUpInToday", [where]),
    CBTf(n"Cyberbane-Grapevine-TheyAreTalkingAboutYouIn", [where]),
    CBTf(n"Cyberbane-Grapevine-HeardAboutWordTravelsFasterThan", [where]),
    CBTf(n"Cyberbane-Grapevine-SomebodyInKnowsYourNameNow", [where]),
    CBTf(n"Cyberbane-Grapevine-YourNameSDoingTheRounds", [where])]);
}

// Word with nobody's name on it, because nobody lived close enough to supply one.
func CBGrapevineAnonLine(where: String, seed: Int32) -> String {
  return CBLineOf([
    CBTf(n"Cyberbane-Grapevine-BodiesTurningUpInAndNobody", [where]),
    CBTf(n"Cyberbane-Grapevine-SomethingIsWorkingNoNameOn", [where]),
    CBTf(n"Cyberbane-Grapevine-HeardHasAProblemNobodyCan", [where]),
    CBTf(n"Cyberbane-Grapevine-WhateverHappenedInNoWitnessesWalked", [where]),
    CBTf(n"Cyberbane-Grapevine-PeopleInAreLockingTheirDoors", [where])]);
}

// Called when a rumor reaches a district it had not touched before.
public func CBGrapevineOnReach(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRumor>,
                               districtId: CName, now: Float) -> Void {
  if !IsDefined(sys) || !IsDefined(r) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return;
  }
  // Rides the existing toast setting: anyone who turned Cyberbane's messages off gets none.
  if !CBMessagesOn() {
    return;
  }
  // Word has to be worth repeating before anyone bothers passing it along.
  if r.magnitude < CBConfig.GrapevineMinMagnitude() {
    return;
  }
  let cd = sys.GetCooldowns();
  if IsDefined(cd) && cd.lastGrapevineAt > 0.0
     && (now - cd.lastGrapevineAt) < CBConfig.GrapevineCooldownHours() * CBConfig.SecondsPerHour() {
    return;
  }
  if RandF() >= CBConfig.GrapevineChance() {
    return;
  }
  // CBDistrictLabel lives in Model/TitleNaming.reds and returns "" for an unknown id.
  let where = CBDistrictLabel(districtId);
  if Equals(where, "") {
    where = CBT(n"Cyberbane-Grapevine-OutThere");
  }
  let seed = Cast<Int32>(RandF() * 4.0);
  if seed > 3 {
    seed = 3;   // RandF() can return 1.0 on some runtimes; never index past the pool
  }
  let line = r.witnessed ? CBGrapevineNamedLine(r.kind, where, seed)
                         : CBGrapevineAnonLine(where, seed);
  // From the broker who works the district the word reached, not from the one where V happens
  // to be standing. The message is "your name came up here", so the person saying it should be
  // the person who heard it.
  CBPhoneFromDistrict(game, districtId, line);
  if IsDefined(cd) {
    cd.lastGrapevineAt = now;
  }
}

// ---- Arriving somewhere word has already reached --------------------------
//
// It is the right half of the mechanic to make audible, because it is the half the player can verify.
public func CBGrapevineOnArrival(sys: ref<CyberbaneSystem>, game: GameInstance,
                                 districtId: CName, now: Float) -> Void {
  if !IsDefined(sys) || Equals(districtId, n"") {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return;
  }
  if !CBMessagesOn() {
    return;
  }
  let cd = sys.GetCooldowns();
  if IsDefined(cd) && cd.lastGrapevineAt > 0.0
     && (now - cd.lastGrapevineAt) < CBConfig.GrapevineCooldownHours() * CBConfig.SecondsPerHour() {
    return;
  }
  // Has anything about V actually reached here? The rumor's own reach mask is the honest
  // answer, so this cannot claim a district knows something it does not.
  let index = CBDistrictIndex(districtId);
  if index < 0 {
    return;
  }
  // Walked with GetRumorCount / GetRumorAt rather than GetRumors, which returns the array by value: indexing that
  // temporary hands back a handle into a copy destroyed at the end of the statement.
  let loudest: ref<CBRumor>;
  let best = 0.0;
  let i = 0;
  while i < sys.GetRumorCount() {
    let r = sys.GetRumorAt(i);
    i += 1;
    if IsDefined(r) && CBMaskHas(r.reachedMask, index)
       && NotEquals(r.origin, districtId) && r.magnitude > best {
      loudest = r;
      best = r.magnitude;
    }
  }
  if !IsDefined(loudest) || best < CBConfig.GrapevineMinMagnitude() {
    return;
  }
  let from = CBDistrictLabel(loudest.origin);
  if Equals(from, "") {
    from = CBT(n"Cyberbane-Grapevine-AcrossTown");
  }
  CBPhoneFromDistrict(game, districtId, CBGrapevineArrivalLine(loudest, from,
                                                               RandRange(0, 4)));
  if IsDefined(cd) {
    cd.lastGrapevineAt = now;
  }
  CBLog.Info(n"Narrative", s"Arrival in \(NameToString(districtId)): local broker mentions word out of \(NameToString(loudest.origin)).");
}

// What the local broker says when you turn up somewhere your name got to first.
func CBGrapevineArrivalLine(r: ref<CBRumor>, from: String, seed: Int32) -> String {
  if !r.witnessed {
    return CBLineOf([
      CBTf(n"Cyberbane-Grapevine-YouAreALongWayFrom", [from]),
      CBTf(n"Cyberbane-Grapevine-WordCameInFromBeforeYou", [from]),
      CBTf(n"Cyberbane-Grapevine-SomethingOutOfHasPeopleHere", [from]),
      CBTf(n"Cyberbane-Grapevine-PeopleHereHeardAboutNobodyCan", [from])]);
  }
  if Equals(r.kind, n"BossKill") {
    return CBLineOf([
      CBTf(n"Cyberbane-Grapevine-TheyKnowAboutTheBossYou", [from]),
      CBTf(n"Cyberbane-Grapevine-TheBossInEverybodyHereHas", [from])]);
  }
  if Equals(r.kind, n"Massacre") {
    return CBLineOf([
      CBTf(n"Cyberbane-Grapevine-WhatYouLeftInIsBeing", [from]),
      CBTf(n"Cyberbane-Grapevine-TheyVeHeardAboutHereSome", [from])]);
  }
  return CBLineOf([
    CBTf(n"Cyberbane-Grapevine-YourNameIsAlreadyInCirculation", [from]),
    CBTf(n"Cyberbane-Grapevine-YouAreKnownOnThisSide", [from]),
    CBTf(n"Cyberbane-Grapevine-HeardAboutBeforeYouEverWalked", [from]),
    CBTf(n"Cyberbane-Grapevine-TheyWereTalkingAboutHereBefore", [from])]);
}
