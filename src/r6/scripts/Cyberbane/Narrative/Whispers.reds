// Cyberbane - Whispers (spec §9.10)
//
// Overheard lines, shown when a recognized NPC is near and V is notable enough to be worth
// talking about.
//
// There used to be exactly six lines in here, one per mood and topic, with no substitution of
// any kind: the same sentence every time, whoever was speaking, wherever you were, whatever you
// had done. A line you have already heard says nothing about the city, so the whole system read
// as decoration rather than as word getting around.
//
// Three things give it variance now:
//
//   - Several lines per bucket, and the last one used is remembered for the session so the
//     same one never lands twice running.
//   - Substitution. The gang's name, the district a story came from, and V's current title go
//     into the line, so it is about this street and this V.
//   - Rumours. If a story has actually reached the district V is standing in, the speaker can
//     be talking about that specific thing - a massacre in Watson, a boss put down in Heywood -
//     rather than about V in the abstract. That is what the rumour engine is for, and until now
//     nothing the player could hear was driven by it.

// Who is talking. The game's own subtitles put this name in front of the line (1.9.5), so it says what
// the speaker is to anybody looking: one of a gang by that gang's own word for its people, a cop, or
// somebody off the street. "Ganger" six times running was its own kind of repetition, and it never
// said whose.
public func CBWhisperSpeaker(faction: CName) -> String {
  if Equals(faction, n"") || !CBFactionOn(faction) {
    return CBPick3(CBT(n"Cyberbane-Whispers-PasserBy"), CBT(n"Cyberbane-Whispers-Local"), CBT(n"Cyberbane-Whispers-SomeoneNearby"));
  }
  let member = CBFactionMemberWord(faction);
  return StrLen(member) > 0 ? member : CBPick3(CBT(n"Cyberbane-Whispers-Ganger"), CBT(n"Cyberbane-Whispers-Lookout"), CBT(n"Cyberbane-Whispers-CrewMember"));
}

// One of theirs, the way the street would say it.
public func CBFactionMemberWord(faction: CName) -> String {
  if Equals(faction, n"NCPD") { return CBPick2(CBT(n"Cyberbane-Whispers-NCPDOfficer"), CBT(n"Cyberbane-Whispers-PatrolCop")); }
  if Equals(faction, n"MaxTac") { return CBT(n"Cyberbane-TitleNaming-MaxTac"); }
  if Equals(faction, n"Maelstrom") { return CBT(n"Cyberbane-Whispers-Maelstromer"); }
  if Equals(faction, n"TygerClaws") { return CBT(n"Cyberbane-Whispers-TygerClaw"); }
  if Equals(faction, n"Valentinos") { return CBT(n"Cyberbane-Whispers-Valentino"); }
  if Equals(faction, n"SixthStreet") { return CBT(n"Cyberbane-TitleNaming-6thStreet"); }
  if Equals(faction, n"Animals") { return CBT(n"Cyberbane-Whispers-Animal"); }
  if Equals(faction, n"VoodooBoys") { return CBT(n"Cyberbane-Whispers-VoodooBoy"); }
  if Equals(faction, n"Scavengers") { return CBT(n"Cyberbane-Whispers-Scav"); }
  if Equals(faction, n"Mox") { return CBT(n"Cyberbane-TitleNaming-Mox"); }
  if Equals(faction, n"Barghest") { return CBT(n"Cyberbane-TitleNaming-Barghest"); }
  if Equals(faction, n"Scrappers") { return CBT(n"Cyberbane-Whispers-Scrapper"); }
  if Equals(faction, n"Aldecaldos") { return CBT(n"Cyberbane-Whispers-Aldecaldo"); }
  if Equals(faction, n"Wraiths") { return CBT(n"Cyberbane-Whispers-Wraith"); }
  if Equals(faction, n"Arasaka") { return CBT(n"Cyberbane-Whispers-ArasakaSecurity"); }
  if Equals(faction, n"Militech") { return CBT(n"Cyberbane-TitleNaming-Militech"); }
  if Equals(faction, n"KangTao") { return CBT(n"Cyberbane-TitleNaming-KangTao"); }
  return "";
}

// The strongest story that has actually travelled to where V is standing.
//
// Returns null when nothing has reached here, which is the normal case early on and the reason
// the generic lines below still exist.
public func CBWhisperRumor(sys: ref<CyberbaneSystem>, game: GameInstance) -> ref<CBRumor> {
  if !IsDefined(sys) {
    return null;
  }
  let here = CBDistrictIndex(CBEventDistrict(sys, game));
  if here < 0 {
    return null;
  }
  // Bound to a local first: GetRumors returns the array by value, and indexing the temporary
  // hands back a handle into a copy.
  let all = sys.GetRumors();
  let best: ref<CBRumor>;
  let bestMag = 0.0;
  let i = 0;
  while i < ArraySize(all) {
    let r = all[i];
    if IsDefined(r) && CBMaskHas(r.reachedMask, here) && r.magnitude > bestMag {
      best = r;
      bestMag = r.magnitude;
    }
    i += 1;
  }
  return best;
}

// What the street is saying about that story.
func CBRumorPhrase(sys: ref<CyberbaneSystem>, r: ref<CBRumor>) -> String {
  let where = CBDistrictLabel(r.origin);
  if StrLen(where) == 0 {
    where = CBT(n"Cyberbane-Grapevine-AcrossTown");
  } else {
    where = CBTf(n"Cyberbane-Whispers-In", [where]);
  }
  let gang = CBFactionLabel(r.faction);
  if Equals(r.kind, n"Massacre") {
    return CBLineOf([
      CBTf(n"Cyberbane-Whispers-HeardTheyFoundARoomFull", [where]),
      CBTf(n"Cyberbane-Whispers-WholeCrewWentQuietNobodyS", [where]),
      CBTf(n"Cyberbane-Whispers-WordIsSomebodyClearedABuilding", [where]),
      CBTf(n"Cyberbane-Whispers-TraumaTeamWouldnTEvenGo", [where]),
      CBTf(n"Cyberbane-Whispers-ScrollersAreSayingLookedLikeA", [where])]);
  }
  if Equals(r.kind, n"BossKill") {
    if StrLen(gang) > 0 {
      return CBPick3(
        CBTf(n"Cyberbane-Whispers-TheyPutABossOfIn", [gang, where]),
        CBTf(n"Cyberbane-Whispers-LostSomeoneWhoMattered", [CBCapFirst(gang), where]),
        CBTf(n"Cyberbane-Whispers-HeardAreShortABoss", [gang, where]));
    }
    return CBTf(n"Cyberbane-Whispers-SomebodyTookABossOffThe", [where]);
  }
  if Equals(r.kind, n"Deed") {
    return CBLineOf([
      CBTf(n"Cyberbane-Whispers-SomethingWentDownStreetSStill", [where]),
      CBTf(n"Cyberbane-Whispers-YouHearAboutThatJob", [where]),
      CBTf(n"Cyberbane-Whispers-EveryoneSTalkingAboutWhatHappened", [where]),
      CBTf(n"Cyberbane-Whispers-FixersAreCallingItTheJob", [where])]);
  }
  if StrLen(gang) > 0 {
    return CBLineOf([
      CBTf(n"Cyberbane-Whispers-AreCountingBodies", [CBCapFirst(gang), where]),
      CBTf(n"Cyberbane-Whispers-AnotherOneOfDown", [gang, where]),
      CBTf(n"Cyberbane-Whispers-NotAGoodWeekToBe", [gang]),
      CBTf(n"Cyberbane-Whispers-ArePullingTheirPeopleOffThe", [CBCapFirst(gang), where])]);
  }
  return CBTf(n"Cyberbane-Whispers-WordIsSomebodySBeenBusy", [where]);
}

// ---- What gets said (1.9.5) -------------------------------------------------------------------------
//
// "Make what the crowd says about you more relevant to what you are in Cyberbane." It said one of three
// moods, a title and now and then a rumour, and that was all it knew. Now every line comes from the
// street's read on V (Model/StreetRead.reds): how V works and how V treats people, the chrome on show,
// the mask, the heat, how well this district knows V, what V is doing right now, and, from somebody
// with a gang, everything between V and that gang - the blood, the mercy, the tribute, the Rival out
// after V, who runs their crew now and whether the gang is breaking. Each of those offers lines when it
// is true, weighted by how much it is worth saying, and the topic the last line was about sits the
// next one out, so the street moves from subject to subject the way people do.

// Is this gang breaking: below the line where the street calls them broken (Model/Territory.reds)?
// Their people stop acting on a vendetta and start being afraid of the one who broke them (1.9.5).
public func CBGangBroken(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  if !IsDefined(sys) || Equals(faction, n"") || !CBTurfWarsOn() || !CBFactionFieldsSquads(faction) {
    return false;
  }
  return CBGangStrength(sys, faction) < CBConfig.GangBrokenStrength();
}

// The line itself.
public func CBWhisperLine(sys: ref<CyberbaneSystem>, game: GameInstance,
                          faction: CName, mood: CName, topic: CName) -> String {
  let st = CBReadStreet(sys, game, faction);
  let gang = StrLen(st.factionLabel) > 0 ? st.factionLabel : CBT(n"Cyberbane-Whispers-ThatCrew");

  // Topic-specific lines take priority (spec §9.10 topic weighting).
  if Equals(topic, n"bossloss") {
    if StrLen(st.leader) > 0 {
      return CBPick4(
        CBTf(n"Cyberbane-Whispers-YouPutDownOneOfOur", [st.leader]),
        CBTf(n"Cyberbane-Whispers-WeKnowWhatYouDidTo", [st.leader]),
        CBTf(n"Cyberbane-Whispers-ThatWasABossOfYou", [gang]),
        CBT(n"Cyberbane-Whispers-EveryOneOfUsKnowsYour"));
    }
    return CBPick4(
      CBT(n"Cyberbane-Whispers-YouPutDownOneOfOur-2"),
      CBT(n"Cyberbane-Whispers-WeKnowWhatYouDidTo-2"),
      CBTf(n"Cyberbane-Whispers-ThatWasABossOfYou", [gang]),
      CBT(n"Cyberbane-Whispers-EveryOneOfUsKnowsYour"));
  }
  if Equals(topic, n"maxtac") {
    return CBPick4(
      CBT(n"Cyberbane-Whispers-ThatSTheMercWhoWent"),
      CBT(n"Cyberbane-Whispers-MaxTacCameForThatOneMaxTac"),
      CBT(n"Cyberbane-Whispers-IVeSeenTheFootageThey"),
      CBT(n"Cyberbane-Whispers-YouDonTSurviveMaxTacThat"));
  }
  if Equals(topic, n"warning") {
    // In their own voice, most of the time (Narrative/GangVoice.reds).
    // Their own words for a stranger (Narrative/GangVoice.reds): a gang V has bled does not call V "civilian" (2.6.1).
    let own = CBGangWarnLine(st.faction);
    if StrLen(own) > 0 && st.kills < CBConfig.WarnKnowsYouKills() && RandF() < CBConfig.GangVoiceShare() {
      return own;
    }
    if st.kills >= CBConfig.WarnKnowsYouKills() {
      return CBPick3(
        CBT(n"Cyberbane-Whispers-YouVePutEnoughOfUs"),
        CBTf(n"Cyberbane-Whispers-RememberEveryOneTurnAround", [CBCapFirst(gang)]),
        CBT(n"Cyberbane-Whispers-LastWarningAfterThisItS"));
    }
    return CBPick4(
      CBT(n"Cyberbane-Whispers-YouVeGotALotOf"),
      CBT(n"Cyberbane-Whispers-WrongStreetChoomTurnAround"),
      CBTf(n"Cyberbane-Whispers-WantYouGoneThisIsThe", [CBCapFirst(gang)]),
      CBT(n"Cyberbane-Whispers-YouReStandingOnOurBlock"));
  }

  let bag = new CBLineBag();
  // A gang V has broken is afraid, whatever its vendetta says.
  if Equals(mood, n"broken") {
    CBWhisperBroken(bag, st, gang);
    mood = n"fear";
  }
  // V's own streets (Economy/War.reds, [37]).
  if CBOwnDistrict(game, st.district) && !st.masked {
    bag.Add(n"own", 3.0, CBLineOf([CBT(n"Cyberbane-Whispers-TheseAreTheirStreetsNowNobody"), CBT(n"Cyberbane-Whispers-GangsPayToWalkThroughHere"),
                                    CBT(n"Cyberbane-Whispers-ThatSWhoRunsThisPlace")]));
  }
  // Streets V's crew holds, and a crew big enough to be talked about anywhere (Model/CrewTurf.reds, 2.7.6). A mask hides V,
  // not whose corners these are.
  if CBIsCrewTurf(st.turfHolder) {
    let crewName = CBCapFirst(CBCrewTurfLabel());
    bag.Add(n"crewturf", 3.0, CBLineOf([CBTf(n"Cyberbane-Whispers-CrewRunsTheseCorners", [crewName]),
                                        CBT(n"Cyberbane-Whispers-PayTheirPeopleOnTime"), CBT(n"Cyberbane-Whispers-WhoseStreetsNowTheirs")]));
  } else {
    if !st.masked && CBCrewWeight(game) >= 50.0 {
      bag.Add(n"crew", 1.5, CBLineOf([CBT(n"Cyberbane-Whispers-NeverAloneThatOne"), CBT(n"Cyberbane-Whispers-TouchThemAndTheirCrew"),
                                      CBT(n"Cyberbane-Whispers-HeardTheyRunACrew")]));
    }
  }
  // V's crew walking with V, by name (2.7.7): passers-by and gangers notice who V brought.
  let crewWith = CBCrewWalkingWith(sys, game);
  if !st.masked && StrLen(crewWith) > 0 {
    bag.Add(n"crewnames", 2.5, CBLineOf([CBTf(n"Cyberbane-Whispers-CrewWith1", [crewWith]), CBTf(n"Cyberbane-Whispers-CrewWith2", [crewWith]),
                                         CBTf(n"Cyberbane-Whispers-CrewWith3", [crewWith])]));
  }
  // V's title, more often than the generic lines that used to carry it (2.7.7).
  let titleWord = CBWhisperTitle(sys);
  if !st.masked && StrLen(titleWord) > 0 {
    bag.Add(n"titled", 1.5, CBLineOf([CBTf(n"Cyberbane-Whispers-Titled1", [titleWord]), CBTf(n"Cyberbane-Whispers-Titled2", [titleWord])]));
  }
  // Something coming near here (Spawn/StreetEvents.reds, [32]).
  let coming = CBEventWhisper(game);
  if StrLen(coming) > 0 {
    bag.Add(n"coming", 2.5, coming);
  }
  // A story that actually reached here.
  let r = CBWhisperRumor(sys, game);
  if IsDefined(r) {
    bag.Add(n"rumor", 3.0 * CBConfig.WhisperRumorChance() / 0.6, CBRumorPhrase(sys, r));
  }
  if st.masked && st.givenAway == 0 {
    // Behind a mask V is nobody: there is no V to talk about, only somebody nobody can place.
    mood = n"fear";
    CBWhisperMasked(bag, st);
    CBWhisperMoment(bag, st, mood);
  } else {
    CBWhisperGivenAway(bag, st);
    CBWhisperNow(bag, st, mood);
    CBWhisperMoment(bag, st, mood);
    CBWhisperRemembered(bag, st, mood, gang);
    CBWhisperIdentity(bag, st, mood);
    CBWhisperConduct(bag, st, mood);
    CBWhisperChrome(bag, st, mood);
    CBWhisperPlace(bag, st, mood);
    CBWhisperGang(bag, st, mood, gang);
  }
  CBWhisperGeneric(bag, st, mood);

  let rt = CyberbaneRuntime.Get();
  let last = IsDefined(rt) ? rt.GetLastWhisperTopic() : n"";
  let pick = bag.Pick(last);
  if pick < 0 {
    return "";
  }
  if IsDefined(rt) {
    rt.SetLastWhisperTopic(bag.topics[pick]);
  }
  return bag.lines[pick];
}

// What V is doing right now beats what V is known for.
func CBWhisperNow(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.recentKills >= 3 || st.aura >= 25.0 {
    if Equals(mood, n"respect") {
      bag.Add(n"now", 3.0, CBPick3(
        CBT(n"Cyberbane-Whispers-BusyNightForThatOneBetter"),
        CBT(n"Cyberbane-Whispers-StillGotTheFightOnThem"),
        CBT(n"Cyberbane-Whispers-WhateverJustHappenedIMGlad")));
    } else {
      bag.Add(n"now", 3.0, CBPick4(
        CBT(n"Cyberbane-Whispers-BloodSStillFreshOnThat"),
        CBT(n"Cyberbane-Whispers-TheyJustDidSomethingYouCan"),
        CBT(n"Cyberbane-Whispers-WalkDonTRunJustWalk"),
        CBT(n"Cyberbane-Whispers-SomebodySNotGoingHomeTonight")));
    }
  }
  if st.heat >= 2 {
    bag.Add(n"heat", 1.5, CBPick3(
      CBT(n"Cyberbane-Whispers-NCPDSAllOverTheNet"),
      CBT(n"Cyberbane-Whispers-CopsWantThatFaceIM"),
      CBT(n"Cyberbane-Whispers-EveryPatrolInTheDistrictS")));
  }
  if st.layingLow && st.renown >= 30.0 {
    bag.Add(n"quiet", 1.5, CBPick3(
      CBT(n"Cyberbane-Whispers-HavenTHeardThatOneS"),
      CBT(n"Cyberbane-Whispers-ThoughtTheyDSkippedTownGuess"),
      CBT(n"Cyberbane-Whispers-QuietLatelyThatSWhenYou")));
  }
}

// Who V is: the name the street gave them, the way they work, how famous they are.
func CBWhisperIdentity(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if StrLen(st.title) > 0 {
    if Equals(mood, n"respect") {
      bag.Add(n"title", 2.0, CBPick3(
        CBTf(n"Cyberbane-Whispers-ThatSForReal", [st.title]),
        CBTf(n"Cyberbane-Whispers-TheyCallThatOneEarnedIt", [st.title]),
        CBTf(n"Cyberbane-Whispers-RightThereDonTMakeA", [st.title])));
    } else {
      if Equals(mood, n"hate") {
        bag.Add(n"title", 2.0, CBPick2(
          CBTf(n"Cyberbane-Whispers-BigNameBleedsLikeAnybody", [st.title]),
          CBTf(n"Cyberbane-Whispers-TheyCallThatOneWeCall", [st.title])));
      } else {
        bag.Add(n"title", 2.0, CBPick3(
          CBTf(n"Cyberbane-Whispers-ThatSEyesDown", [st.title]),
          CBTf(n"Cyberbane-Whispers-DonTThatS", [st.title]),
          CBTf(n"Cyberbane-Whispers-YouKnowWhoThatIsKeep", [st.title])));
      }
    }
  }
  let a = st.archetype;
  if a == EnumInt(ECBArchetype.Butcher) {
    bag.Add(n"style", 2.0, CBPick3(
      CBT(n"Cyberbane-Whispers-HeardWhatThatOneLeavesBehind"),
      CBT(n"Cyberbane-Whispers-ThatSTheOneWhoDoesn"),
      CBT(n"Cyberbane-Whispers-DonTEndUpInA")));
  } else {
    if a == EnumInt(ECBArchetype.Ghost) {
      bag.Add(n"style", 2.0, CBPick3(
        CBT(n"Cyberbane-Whispers-BodiesTurnUpAndNobodySaw"),
        CBT(n"Cyberbane-Whispers-YouDonTSeeThatOne"),
        CBT(n"Cyberbane-Whispers-HalfTheJobsOnTheNet")));
    } else {
      if a == EnumInt(ECBArchetype.Professional) {
        bag.Add(n"style", 2.0, CBPick3(
          CBT(n"Cyberbane-Whispers-ThatOneDoesCleanWorkIn"),
          CBT(n"Cyberbane-Whispers-FixersLoveThatOneJobDone"),
          CBT(n"Cyberbane-Whispers-ARealProRareTheseDays")));
      } else {
        if a == EnumInt(ECBArchetype.Chromed) {
          bag.Add(n"style", 2.0, CBPick3(
            CBT(n"Cyberbane-Whispers-MoreChromeThanMeatOnThat"),
            CBT(n"Cyberbane-Whispers-HowMuchOfThemIsEven"),
            CBT(n"Cyberbane-Whispers-RipperdocsMustLoveThatOne")));
        } else {
          if a == EnumInt(ECBArchetype.Netrunner) {
            bag.Add(n"style", 2.0, CBPick3(
              CBT(n"Cyberbane-Whispers-NetrunnerFriesYouFromAcrossThe"),
              CBT(n"Cyberbane-Whispers-ThatOneCooksBrainsForA"),
              CBT(n"Cyberbane-Whispers-DonTJackInNearThat")));
          } else {
            if a == EnumInt(ECBArchetype.Brawler) {
              bag.Add(n"style", 2.0, CBPick3(
                CBT(n"Cyberbane-Whispers-SawThatOnePutAGuy"),
                CBT(n"Cyberbane-Whispers-DoesnTEvenNeedAGun"),
                CBT(n"Cyberbane-Whispers-FistsLikeThatWhoNeedsA")));
            }
          }
        }
      }
    }
  }
  if st.tier >= EnumInt(ECBRenownTier.Infamous) {
    bag.Add(n"fame", 1.5, CBPick3(
      CBT(n"Cyberbane-Whispers-WaitIsThatReallyThemOn"),
      CBT(n"Cyberbane-Whispers-EverybodyInTheCityKnowsThat"),
      CBT(n"Cyberbane-Whispers-IMTellingEveryoneISaw")));
  } else {
    if st.renown < 15.0 && st.dread >= 40.0 {
      bag.Add(n"fame", 1.5, CBPick2(
        CBT(n"Cyberbane-Whispers-NobodyKnowsWhoThatIsThat"),
        CBT(n"Cyberbane-Whispers-NoNameNoFaceOnThe")));
    }
  }
}

// How V treats people: the mercy, or the lack of it.
func CBWhisperConduct(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.code <= -40.0 {
    bag.Add(n"conduct", 2.5, CBPick4(
      CBT(n"Cyberbane-Whispers-ThatOneSABadDay"),
      CBT(n"Cyberbane-Whispers-HeardTheyShootWhoeverSIn"),
      CBT(n"Cyberbane-Whispers-SomebodyShouldCallMaxTacBeforeIt"),
      CBT(n"Cyberbane-Whispers-LookAtTheEyesNobodyS")));
    return;
  }
  if st.code >= 40.0 || (st.mercies >= 10 && st.code > 0.0) {
    if Equals(mood, n"hate") {
      bag.Add(n"conduct", 2.0, CBPick2(
        CBT(n"Cyberbane-Whispers-LeavesPeopleBreathingThinksThatMakes"),
        CBT(n"Cyberbane-Whispers-SoftPutsPeopleToSleepInstead")));
    } else {
      bag.Add(n"conduct", 2.5, CBPick4(
        CBT(n"Cyberbane-Whispers-ThatOneLeavesPeopleBreathingWeird"),
        CBT(n"Cyberbane-Whispers-GotACodeThatOneDoesn"),
        CBT(n"Cyberbane-Whispers-PutMyCousinDownOnceAnd"),
        CBT(n"Cyberbane-Whispers-HardButFairNotManyLike")));
    }
  }
}

// What people can see of V's chrome.
func CBWhisperChrome(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.chromeVisible >= 55.0 {
    bag.Add(n"chrome", 2.0, CBPick4(
      CBT(n"Cyberbane-Whispers-LookAtThoseArmsMilitaryGrade"),
      CBT(n"Cyberbane-Whispers-AllThatChromeOutInThe"),
      CBT(n"Cyberbane-Whispers-DonTStareAtTheChrome"),
      CBT(n"Cyberbane-Whispers-ThatSNotABodyThat")));
    return;
  }
  if st.chromeInstalled >= 60.0 && st.armsCovered {
    bag.Add(n"chrome", 1.0, CBPick2(
      CBT(n"Cyberbane-Whispers-SomethingHeavyUnderThatJacketMoves"),
      CBT(n"Cyberbane-Whispers-DressesPlainDoesnTFoolAnyone")));
  }
}

// Where V is standing: home turf for V's name, or somewhere it has not reached.
func CBWhisperPlace(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if StrLen(st.districtLabel) == 0 {
    return;
  }
  if st.districtRenown >= 60.0 {
    bag.Add(n"place", 1.5, CBPick3(
      CBTf(n"Cyberbane-Whispers-EverybodyInKnowsThatFace", [st.districtLabel]),
      CBTf(n"Cyberbane-Whispers-ThatOnePracticallyRunsNow", [st.districtLabel]),
      CBTf(n"Cyberbane-Whispers-AskAnyoneInTheyLlTell", [st.districtLabel])));
  } else {
    if st.districtRenown < 10.0 && st.renown >= 40.0 {
      bag.Add(n"place", 1.5, CBPick2(
        CBTf(n"Cyberbane-Whispers-NotFromHeardTheNameThough", [st.districtLabel]),
        CBTf(n"Cyberbane-Whispers-WhatSThatOneDoingIn", [st.districtLabel])));
    }
  }
  // A district whose gang V has bled dry, from somebody who lives there.
  if Equals(st.faction, n"") && NotEquals(st.turfHolder, n"") {
    let sys = CyberbaneSystem.Get(GetGameInstance());
    if CBGangBroken(sys, st.turfHolder) {
      let holder = CBFactionLabel(st.turfHolder);
      if StrLen(holder) > 0 {
        bag.Add(n"turf", 2.0, CBPick2(
          CBTf(n"Cyberbane-Whispers-HalfTheCornersRanAreEmpty", [CBCapFirst(holder)]),
          CBTf(n"Cyberbane-Whispers-DonTScareAnybodyRoundHere", [CBCapFirst(holder)])));
      }
    }
  }
}

// From somebody with a gang: everything between V and that gang.
func CBWhisperGang(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName, gang: String) -> Void {
  if Equals(st.faction, n"") {
    return;
  }
  if StrLen(st.hunter) > 0 && !st.broken && !Equals(st.posture, ECBPosture.Allied) && !Equals(st.posture, ECBPosture.Friendly) {
    bag.Add(n"hunter", 3.0, CBPick3(
      CBTf(n"Cyberbane-Whispers-SComingForYouEverybodyOn", [st.hunter]),
      CBTf(n"Cyberbane-Whispers-EnjoyTheWalkHasPlansFor", [st.hunter]),
      CBTf(n"Cyberbane-Whispers-WhenFindsYouIWantA", [st.hunter])));
  }
  if Equals(st.posture, ECBPosture.Allied) {
    bag.Add(n"gang", 2.5, CBPick3(
      CBTf(n"Cyberbane-Whispers-ThatSAFriendOfYou", [gang]),
      CBT(n"Cyberbane-Whispers-TreatThatOneLikeFamilyBoss"),
      CBT(n"Cyberbane-Whispers-OneOfOursNearEnoughAnybody")));
  } else {
    if Equals(st.posture, ECBPosture.Friendly) {
      bag.Add(n"gang", 2.0, CBPick3(
        CBTf(n"Cyberbane-Whispers-ThatOneSAllRightBy", [gang]),
        CBT(n"Cyberbane-Whispers-GoodWithTheCrewThatOne"),
        CBT(n"Cyberbane-Whispers-HeardTheyVeBeenDoingUs")));
    } else {
      // A broken gang's people have no threats left in them (1.9.5); CBWhisperBroken speaks for them.
      if !st.broken && (Equals(st.posture, ECBPosture.Hostile) || Equals(st.posture, ECBPosture.Vendetta)) {
        if st.kills >= 20 {
          bag.Add(n"blood", 2.5, CBPick3(
            CBTf(n"Cyberbane-Whispers-ThatOneSPutMoreOf", [gang]),
            CBT(n"Cyberbane-Whispers-EveryFuneralThisMonthThatOne"),
            CBT(n"Cyberbane-Whispers-YouKnowHowManyOfOurs")));
        } else {
          bag.Add(n"blood", 2.0, CBPick2(
            CBT(n"Cyberbane-Whispers-WeKnowYourFaceAllOf"),
            CBTf(n"Cyberbane-Whispers-KeepWalkingYouReOnStreets", [CBPossessive(gang)])));
        }
        if StrLen(st.leader) > 0 {
          bag.Add(n"leader", 1.5, CBPick2(
            CBTf(n"Cyberbane-Whispers-RunsThisCrewNowWantsA", [st.leader]),
            CBTf(n"Cyberbane-Whispers-WhenHearsYouCameByIt", [st.leader])));
        }
      } else {
        if st.fear >= 60.0 {
          bag.Add(n"fear", 2.0, CBPick3(
            CBT(n"Cyberbane-Whispers-DonTLookAtThemJust"),
            CBT(n"Cyberbane-Whispers-NobodyStartsAnythingNotWithThat"),
            CBT(n"Cyberbane-Whispers-IfTheyWantTheCornerThey")));
        }
      }
    }
  }
  if st.spared >= 3 && !Equals(st.posture, ECBPosture.Vendetta) {
    bag.Add(n"mercy", 2.0, CBPick2(
      CBT(n"Cyberbane-Whispers-ThatOneLetSomeOfOurs"),
      CBT(n"Cyberbane-Whispers-CouldVeFinishedMyBrotherDidn")));
  }
  if st.tributes > 0 {
    bag.Add(n"tribute", 1.5, CBPick2(
      CBT(n"Cyberbane-Whispers-BossPaysThatOneToStay"),
      CBT(n"Cyberbane-Whispers-WeSendThemEddiesSoThey")));
  }
}

// A gang V has broken, afraid out loud.
func CBWhisperBroken(bag: ref<CBLineBag>, st: ref<CBStreetRead>, gang: String) -> Void {
  bag.Add(n"broken", 4.0, CBPick4(
    CBT(n"Cyberbane-Whispers-DonTWeReDoneAlright"),
    CBT(n"Cyberbane-Whispers-ThereSHardlyAnyOfUs"),
    CBT(n"Cyberbane-Whispers-WhateverTheBossesSaidIM"),
    CBTf(n"Cyberbane-Whispers-ThatSTheOneWhoBroke", [gang])));
}

// Somebody nobody can put a name to.
func CBWhisperMasked(bag: ref<CBLineBag>, st: ref<CBStreetRead>) -> Void {
  bag.Add(n"mask", 3.0, CBPick4(
    CBT(n"Cyberbane-Whispers-WhoSUnderTheMaskNever"),
    CBT(n"Cyberbane-Whispers-CanTSeeAFaceDon"),
    st.night ? CBT(n"Cyberbane-Whispers-MaskedUpAfterDarkThatS") : CBT(n"Cyberbane-Whispers-MaskedUpInTheMiddleOf"),
    CBT(n"Cyberbane-Whispers-SomebodyWhoDoesnTWantTo")));
}

// What everybody can see right now (Model/Moment.reds, 2.3.1): the blood, a fight just over, the hour, the rain.
func CBWhisperMoment(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  if st.wounded {
    if Equals(mood, n"hate") {
      bag.Add(n"moment", 3.0, CBLineOf([
        CBT(n"Cyberbane-Whispers-BleedingAlreadySomebodyDidUsA"),
        CBT(n"Cyberbane-Whispers-LookWhoSLeakingShameIf"),
        CBT(n"Cyberbane-Whispers-HurtAndOnOurStreetBad"),
        CBT(n"Cyberbane-Whispers-SomebodySoftenedYouUpLuckyUs")]));
    } else {
      if Equals(mood, n"respect") {
        bag.Add(n"moment", 3.0, CBLineOf([
          CBT(n"Cyberbane-Whispers-SomebodyGetThatMercToA"),
          CBT(n"Cyberbane-Whispers-TheyReHurtGiveThemRoom"),
          CBT(n"Cyberbane-Whispers-StillStandingWithAllThatBlood"),
          CBT(n"Cyberbane-Whispers-WhoeverDidThatToThemIs")]));
      } else {
        bag.Add(n"moment", 3.0, CBLineOf([
          CBT(n"Cyberbane-Whispers-TheyReBleedingSomebodySGoing"),
          CBT(n"Cyberbane-Whispers-LookAtThatEvenLegendsLeak"),
          CBT(n"Cyberbane-Whispers-HurtAndStillWalkingAroundBrave"),
          CBT(n"Cyberbane-Whispers-DonTHelpDonTLook"),
          CBT(n"Cyberbane-Whispers-ThatSALotOfBlood")]));
      }
    }
  }
  if st.fresh && st.recentKills < 3 {
    bag.Add(n"moment", 2.5, CBLineOf([
      CBT(n"Cyberbane-Whispers-SmellThatCorditeSomethingJustWent"),
      CBT(n"Cyberbane-Whispers-StillShakingOffAFightThat"),
      CBT(n"Cyberbane-Whispers-HeardTheShotsAMinuteAgo"),
      CBT(n"Cyberbane-Whispers-WhateverThatWasItJustHappened")]));
  }
  if st.night {
    bag.Add(n"moment", 1.0, CBLineOf([
      CBT(n"Cyberbane-Whispers-OutWalkingAtThisHourCourse"),
      CBT(n"Cyberbane-Whispers-NightBelongsToPeopleLikeThat"),
      CBT(n"Cyberbane-Whispers-NobodyGoodIsOutThisLate"),
      CBT(n"Cyberbane-Whispers-LockTheDoorWhenYouGet")]));
  }
  if st.rain > 0 {
    bag.Add(n"moment", st.rain == 2 ? 1.5 : 0.8, CBLineOf([
      CBT(n"Cyberbane-Whispers-PouringDownAndThatOneDoesn"),
      CBT(n"Cyberbane-Whispers-WetNightAndTheyReStill"),
      CBT(n"Cyberbane-Whispers-RainWashesTheBloodOffThe"),
      CBT(n"Cyberbane-Whispers-CanTSeeAFaceIn")]));
  }
}

// Where V is standing, if something big happened there (Model/StreetBook.reds, 2.3.1).
func CBWhisperRemembered(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName, gang: String) -> Void {
  if Equals(st.placeKind, n"") {
    return;
  }
  // One of the gang that lost people here, standing where they lost them.
  if NotEquals(st.faction, n"") && Equals(st.faction, st.placeGang) && !Equals(mood, n"respect") {
    bag.Add(n"remembered", 3.5, CBLineOf([
      CBT(n"Cyberbane-Whispers-ThisIsWhereYouDidIt"),
      CBT(n"Cyberbane-Whispers-YouVeGotSomeNerveStanding"),
      CBT(n"Cyberbane-Whispers-WeStillHavenTWashedThis"),
      CBT(n"Cyberbane-Whispers-RightHereMyFriendsRightHere")]));
    return;
  }
  let theirs = CBFactionLabel(st.placeGang);
  if Equals(st.placeKind, n"Massacre") {
    bag.Add(n"remembered", 2.5, CBLineOf([
      CBT(n"Cyberbane-Whispers-ThisIsWhereTheyFoundThe"),
      CBT(n"Cyberbane-Whispers-StillCanTGetTheStains"),
      CBT(n"Cyberbane-Whispers-DonTStandThereThatS"),
      CBT(n"Cyberbane-Whispers-NCPDTookAWeekToBag")]));
    return;
  }
  if Equals(st.placeKind, n"BossKill") && StrLen(theirs) > 0 {
    bag.Add(n"remembered", 2.5, CBLineOf([
      CBTf(n"Cyberbane-Whispers-ThisIsWhereLostTheirBoss", [theirs]),
      CBTf(n"Cyberbane-Whispers-StillLeaveCandlesOnThisSpot", [CBCapFirst(theirs)]),
      CBT(n"Cyberbane-Whispers-TheirBossWentDownRightThere")]));
    return;
  }
  if Equals(st.placeKind, n"ApexDown") && StrLen(theirs) > 0 {
    bag.Add(n"remembered", 2.5, CBLineOf([
      CBTf(n"Cyberbane-Whispers-SentTheirBestHereTheirBest", [CBCapFirst(theirs)]),
      CBTf(n"Cyberbane-Whispers-ThisIsWhereHeavyHittersCame", [CBPossessive(theirs)])]));
    return;
  }
  if Equals(st.placeKind, n"MaxTacDown") {
    bag.Add(n"remembered", 2.5, CBLineOf([
      CBT(n"Cyberbane-Whispers-MaxTacLostOneOfTheirsRight"),
      CBT(n"Cyberbane-Whispers-YouKnowWhatHappenedOnThis")]));
  }
}

// A mask does not hide the car everybody knows, or the gun (Model/StreetBook.reds, 2.3.1).
func CBWhisperGivenAway(bag: ref<CBLineBag>, st: ref<CBStreetRead>) -> Void {
  if st.givenAway == 1 {
    bag.Add(n"knownby", 4.0, CBLineOf([
      CBT(n"Cyberbane-Whispers-MaskOrNoMaskThatS"),
      CBT(n"Cyberbane-Whispers-NiceMaskShameAboutTheRide"),
      CBT(n"Cyberbane-Whispers-YouCanCoverYourFaceCan"),
      CBT(n"Cyberbane-Whispers-SameCarEveryTimeYouD")]));
    return;
  }
  if st.givenAway == 2 {
    bag.Add(n"knownby", 4.0, CBLineOf([
      CBT(n"Cyberbane-Whispers-HideYourFaceAllYouWant"),
      CBT(n"Cyberbane-Whispers-KnowThatPieceAnywhereOnlyOne"),
      CBT(n"Cyberbane-Whispers-TheMaskSNewTheGun"),
      CBT(n"Cyberbane-Whispers-EverybodyOnTheBlockHasSeen")]));
  }
}

// How this district talks, whoever is talking (Data/Districts.reds, [6]).
func CBWhisperDistrict(bag: ref<CBLineBag>, st: ref<CBStreetRead>) -> Void {
  if !CBTempersOn() {
    return;
  }
  let lines: array<String>;
  switch CBDistrictIndex(st.district) {
    case 0:
      lines = [CBT(n"Cyberbane-Whispers-KabukiSGoingToBeBuzzing"), CBT(n"Cyberbane-Whispers-InWatsonYouReOldNews"),
               CBT(n"Cyberbane-Whispers-SomebodyLlBeSellingTheStory"),
               CBT(n"Cyberbane-Whispers-WatsonSeenWorse")];
      break;
    case 1:
      lines = [CBT(n"Cyberbane-Whispers-KeepItDownThisIsJapantown"), CBT(n"Cyberbane-Whispers-FolksRoundHerePayGoodMoney"),
               CBT(n"Cyberbane-Whispers-CharterHillDoesnTNeedThis"),
               CBT(n"Cyberbane-Whispers-WestbrookNicerClothes")];
      break;
    case 2:
      lines = [CBT(n"Cyberbane-Whispers-DonTLookCorpoRuleNumber"), CBT(n"Cyberbane-Whispers-SomebodyCallBuildingSecurityActuallyDon"),
               CBT(n"Cyberbane-Whispers-NotInFrontOfTheArasaka"),
               CBT(n"Cyberbane-Whispers-CorpoPlazaCorpoRules")];
      break;
    case 3:
      lines = [CBT(n"Cyberbane-Whispers-MyAbuelaWarnedMeAboutPeople"), CBT(n"Cyberbane-Whispers-InHeywoodWeRememberFacesThat"),
               CBT(n"Cyberbane-Whispers-TheValentinosHearEverythingThatHappens"),
               CBT(n"Cyberbane-Whispers-HeywoodLooksAfterItsOwn")];
      break;
    case 4:
      lines = [CBT(n"Cyberbane-Whispers-WorkingFolksDonTNeedThis"), CBT(n"Cyberbane-Whispers-ArroyoSSeenWorseNotMuch"),
               CBT(n"Cyberbane-Whispers-KeepWalkingWeVeGotShifts"),
               CBT(n"Cyberbane-Whispers-SantoDomingoDoubleShifts")];
      break;
    case 5:
      lines = [CBT(n"Cyberbane-Whispers-PacificaSSeenItAllStill"), CBT(n"Cyberbane-Whispers-NobodyCallsTheCopsInPacifica"),
               CBT(n"Cyberbane-Whispers-VoodooBoysLlKnowAboutThis"),
               CBT(n"Cyberbane-Whispers-PacificaDisappear")];
      break;
    case 6:
      lines = [CBT(n"Cyberbane-Whispers-BarghestWillKnowAboutThisBefore"), CBT(n"Cyberbane-Whispers-InDogtownYouDonTStare"),
               CBT(n"Cyberbane-Whispers-HansenSPeopleAreAlwaysWatching"), CBT(n"Cyberbane-Whispers-ScrappersLlHaveThatStrippedAnd"),
               CBT(n"Cyberbane-Whispers-DogtownWhoOwnsYou")];
      break;
    case 7:
      lines = [CBT(n"Cyberbane-Whispers-LongWayFromTheCityTo"), CBT(n"Cyberbane-Whispers-OutHereYouHearAName"),
               CBT(n"Cyberbane-Whispers-ClansLlBeTalkingAboutThis"),
               CBT(n"Cyberbane-Whispers-BadlandsSunCooks")];
      break;
    default:
      return;
  }
  bag.Add(n"district", 0.8, CBLineOf(lines));
}

// What anybody might say, the floor under everything else.
func CBWhisperGeneric(bag: ref<CBLineBag>, st: ref<CBStreetRead>, mood: CName) -> Void {
  CBWhisperDistrict(bag, st);
  if Equals(mood, n"respect") {
    // Twice as many as before (2.7.6): these are what the street says most, and four wore thin within an evening.
    bag.Add(n"generic", 1.0, CBLineOf([
      CBT(n"Cyberbane-Whispers-NowThatSAMercWorth"),
      CBT(n"Cyberbane-Whispers-SolidNoMessNoNoise"),
      CBT(n"Cyberbane-Whispers-IDTakeThatOneOn"),
      CBT(n"Cyberbane-Whispers-IfYouNeedSomethingDoingThat"),
      CBT(n"Cyberbane-Whispers-FixersCallThatOneFirst"),
      CBT(n"Cyberbane-Whispers-NeverSeenThemRattled"),
      CBT(n"Cyberbane-Whispers-FinishWhatTheyStart"),
      CBT(n"Cyberbane-Whispers-WantItDoneRight")]));
    return;
  }
  if Equals(mood, n"hate") {
    bag.Add(n"generic", 1.0, CBLineOf([
      CBT(n"Cyberbane-Whispers-YouVeGotSomeNerveShowing"),
      CBT(n"Cyberbane-Whispers-LookWhoCrawledOntoOurStreet"),
      CBT(n"Cyberbane-Whispers-KeepWalkingYouReNotWelcome"),
      CBT(n"Cyberbane-Whispers-OneDayYouLlBeSomewhere"),
      CBT(n"Cyberbane-Whispers-SmileWhileYouCan"),
      CBT(n"Cyberbane-Whispers-SomebodyCollectsOnYou"),
      CBT(n"Cyberbane-Whispers-LongMemoriesShortTempers"),
      CBT(n"Cyberbane-Whispers-AllTheStreetsYouPickedOurs")]));
    return;
  }
  bag.Add(n"generic", 1.0, CBLineOf([
    CBT(n"Cyberbane-Whispers-DonTStareChoomJustKeep"),
    CBT(n"Cyberbane-Whispers-EyesDownKeepMoving"),
    CBT(n"Cyberbane-Whispers-IMNotGettingInvolvedNeither"),
    CBT(n"Cyberbane-Whispers-WhateverThatOneWantsLetThem"),
    CBT(n"Cyberbane-Whispers-DontMakeEyeContact"),
    CBT(n"Cyberbane-Whispers-CrossTheStreetDontRun"),
    CBT(n"Cyberbane-Whispers-TheOneFromTheFeeds"),
    CBT(n"Cyberbane-Whispers-NobodySawAnything")]));
}

// V's current title, if they have one worth naming.
func CBWhisperTitle(sys: ref<CyberbaneSystem>) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let id = sys.GetActiveTitle();
  if Equals(id, n"") {
    let unlocked = sys.GetUnlockedTitles();
    if ArraySize(unlocked) == 0 {
      return "";
    }
    id = unlocked[ArraySize(unlocked) - 1];
  }
  if Equals(id, n"") {
    return "";
  }
  return CBTitleDisplayById(sys, sys.GetContent(), id);
}

// The Whispers switch, for anything else that would put an overheard line on the screen (1.9.1).
public func CBWhispersOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().whispers;
}

public func CBShowWhisper(sys: ref<CyberbaneSystem>, game: GameInstance,
                          faction: CName, mood: CName, topic: CName) -> Void {
  // A whisper is something said near V, not something sent to V, so it is a line of subtitle
  // and never a text. 1.4.7's first pass sent these as texts from "Passerby" and "Ganger",
  // which in the real phone would have meant contacts nobody could have had a number for.
  CBOverheard(game, CBWhisperSpeaker(faction), CBWhisperLine(sys, game, faction, mood, topic));
}

// The first name of one of V's crew walking with V now, for the street to say; "" when none is (2.7.7).
public func CBCrewWalkingWith(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || book.OutCount() == 0 || book.leaving {
    return "";
  }
  let i = 0;
  while i < book.OutCount() {
    if book.outSeen[i] && !book.outDown[i] {
      let m = book.Find(book.outMember[i]);
      if IsDefined(m) {
        return CBCrewFirst(sys, m);
      }
    }
    i += 1;
  }
  return "";
}
