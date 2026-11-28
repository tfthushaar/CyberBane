// Cyberbane - Each gang's voice ([L3])
//
// The texts, warnings, refusals and surrenders a gang's people say, written for that gang, from its code
// (Data/GangCodes.reds): the Valentinos' family and honour, the Claws' face and business, Maelstrom's chrome, 6th
// Street's veterans, the Animals' strength, the Voodoo Boys' Net, the Mox looking after their own, the Scavengers, the
// Wraiths' road, the Aldecaldos' family, Barghest's soldiers, the Scrappers' salvage.

// A street warning from one of theirs, before they draw (the Director's warning, Narrative/Whispers.reds).
public func CBGangWarnLine(f: CName) -> String {
  if Equals(f, n"Valentinos") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-ThisIsValentinoBloodSStreet"),
                     CBT(n"Cyberbane-GangVoice-PorLaFamiliaIMGiving"),
                     CBT(n"Cyberbane-GangVoice-YouDisrespectThisBarrioYouDisrespect")]);
  }
  if Equals(f, n"TygerClaws") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-ThisStreetPaysTheClawsYou"),
                     CBT(n"Cyberbane-GangVoice-BadForBusinessYouBeingHere"),
                     CBT(n"Cyberbane-GangVoice-WalkAwayNowAndNobodyLoses")]);
  }
  if Equals(f, n"Maelstrom") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-NiceChromeBeAShameIf"),
                     CBT(n"Cyberbane-GangVoice-MeatLikeYouDoesnTWalk"),
                     CBT(n"Cyberbane-GangVoice-KeepWalkingOrLeaveYourImplants")]);
  }
  if Equals(f, n"SixthStreet") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-ThisIsA6thStreetNeighbourhood"),
                     CBT(n"Cyberbane-GangVoice-WeVeDoneToursThatD"),
                     CBT(n"Cyberbane-GangVoice-PatrolSWatchingYouMercKeep")]);
  }
  if Equals(f, n"Animals") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-YouLookingForABeatingKeep"),
                     CBT(n"Cyberbane-GangVoice-SmallThingLikeYouOnAnimal"),
                     CBT(n"Cyberbane-GangVoice-PutTheGunDownAndI")]);
  }
  if Equals(f, n"VoodooBoys") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-WeAlreadyKnowEverythingAboutYou"),
                     CBT(n"Cyberbane-GangVoice-YourICEIsPaperMercDon"),
                     CBT(n"Cyberbane-GangVoice-LoaAreWatchingYouSoAre")]);
  }
  if Equals(f, n"Mox") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-NobodyHurtsAnyoneOnOurStreet"),
                     CBT(n"Cyberbane-GangVoice-WeLookAfterOurOwnHere"),
                     CBT(n"Cyberbane-GangVoice-LeaveTheGirlsAloneAndWalk")]);
  }
  if Equals(f, n"Scavengers") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-NicePartsWalkAwayBeforeWe"),
                     CBT(n"Cyberbane-GangVoice-KeepMovingUnlessYouWannaEnd"),
                     CBT(n"Cyberbane-GangVoice-EverythingOnYouHasAPrice")]);
  }
  if Equals(f, n"Wraiths") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-ThisIsWraithRoadTurnYour"),
                     CBT(n"Cyberbane-GangVoice-OutHereNobodyHearsYouScream"),
                     CBT(n"Cyberbane-GangVoice-TheDesertTakesEveryoneDonT")]);
  }
  if Equals(f, n"Aldecaldos") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-YouReNearTheFamilyS"),
                     CBT(n"Cyberbane-GangVoice-WeDonTWantTroubleDon"),
                     CBT(n"Cyberbane-GangVoice-FamilyLooksAfterFamilyYouRe")]);
  }
  if Equals(f, n"Barghest") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-RestrictedZoneLeaveTheArea"),
                     CBT(n"Cyberbane-GangVoice-ThisIsYourOnlyWarningCivilian"),
                     CBT(n"Cyberbane-GangVoice-YouAreBeingTrackedComplyAnd")]);
  }
  if Equals(f, n"Scrappers") {
    return CBLineOf([CBT(n"Cyberbane-GangVoice-ThisPileSSpokenForFind"),
                     CBT(n"Cyberbane-GangVoice-WalkOnChoomNothingHereWorth"),
                     CBT(n"Cyberbane-GangVoice-WePullWhatWePullDon")]);
  }
  return "";
}

// A crew on its way, in their own words, around how many and where (CBCrewWarning, Spawn/Hunt.reds).
public func CBGangCrewText(f: CName, where: String, coming: String, vendetta: Bool, onTheirTurf: Bool) -> String {
  let place = StrLen(where) > 0 ? where : CBT(n"Cyberbane-GangVoice-NightCity");   // after "in" and "to" below
  if Equals(f, n"Valentinos") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-YouHurtTheFamilyNowThe", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-WeKnowYouReInPray", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-HonourSaysWeTellYouFirst", [s"\(place)", s"\(coming)"])]);
  }
  if Equals(f, n"TygerClaws") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-YouCostUsFaceThatS", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-BusinessIsBusinessYouReBad", [s"\(coming)", s"\(place)"]),
                     CBTf(n"Cyberbane-GangVoice-WeFoundYouInTryNot", [s"\(place)", s"\(coming)"])]);
  }
  if Equals(f, n"Maelstrom") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-WeWantThoseImplantsChoomComing", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-HeardYouReInHopeYour", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-YourArmsDLookBetterOn", [s"\(coming)", s"\(place)"])]);
  }
  if Equals(f, n"SixthStreet") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-SquadSRollingOutToYou", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-TargetConfirmedIn", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-WeProtectThisCityFromPeople", [s"\(coming)", s"\(place)"])]);
  }
  if Equals(f, n"Animals") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-YouThinkYouReStrongWe", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-JuicedUpAndHeadedYourWay", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-GonnaBreakYouInHalfMerc", [s"\(place)", s"\(coming)"])]);
  }
  if Equals(f, n"VoodooBoys") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-WeTracedYouToBeforeYou", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-YourLocationIsYourTimeIs", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-TheNetToldUsWhereYou", [s"\(place)", s"\(coming)"])]);
  }
  if Equals(f, n"Mox") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-YouHurtOneOfOursWe", [s"\(coming)", s"\(place)"]),
                     CBTf(n"Cyberbane-GangVoice-ComingToThisIsForHer", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-WeProtectOurOwnAndYou", [s"\(coming)"])]);
  }
  if Equals(f, n"Scavengers") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-FreshPartsWalkingRoundWeRe", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-PriceOnYourOrgansJustWent", [s"\(coming)", s"\(place)"]),
                     CBTf(n"Cyberbane-GangVoice-FoundYouInHoldStill", [s"\(place)", s"\(coming)"])]);
  }
  if Equals(f, n"Wraiths") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-YouReOnOurRoadNow", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-EnginesAreRunning", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-OutHereNobodyComesToHelp", [s"\(coming)", s"\(place)"])]);
  }
  if Equals(f, n"Aldecaldos") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-YouHurtFamilyTheClanDoesn", [s"\(coming)", s"\(place)"]),
                     CBTf(n"Cyberbane-GangVoice-WeDRatherNotDoThis", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-FamilySComingForYouIn", [s"\(place)", s"\(coming)"])]);
  }
  if Equals(f, n"Barghest") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-HostileLocatedInUnitDeployed", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-EngagingTargetIn", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-YouWereWarnedStrikeTeamInbound", [s"\(place)", s"\(coming)"])]);
  }
  if Equals(f, n"Scrappers") {
    return CBLineOf([CBTf(n"Cyberbane-GangVoice-EverythingYouVeGotIsSalvage", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-WeKnowEveryHoleInYou", [s"\(place)", s"\(coming)"]),
                     CBTf(n"Cyberbane-GangVoice-YouTookFromUsWeRe", [s"\(place)", s"\(coming)"])]);
  }
  return "";
}

// One of theirs won't talk (StreetTalk.Refuse).
public func CBGangRefuseLine(f: CName) -> String {
  if Equals(f, n"Valentinos") { return CBLineOf([CBT(n"Cyberbane-GangVoice-NoTengoNadaParaTiWalk"), CBT(n"Cyberbane-GangVoice-YouDonTTalkToFamily"), CBT(n"Cyberbane-GangVoice-NotOneWordPendejo")]); }
  if Equals(f, n"TygerClaws") { return CBLineOf([CBT(n"Cyberbane-GangVoice-YouCanTAffordMyTime"), CBT(n"Cyberbane-GangVoice-TalkCostsYouReBrokeTo"), CBT(n"Cyberbane-GangVoice-MakeAnAppointmentNever")]); }
  if Equals(f, n"Maelstrom") { return CBLineOf([CBT(n"Cyberbane-GangVoice-TalkSForMeatMove"), CBT(n"Cyberbane-GangVoice-IDonTTalkToYou"), CBT(n"Cyberbane-GangVoice-YourVoiceIsUglyShutIt")]); }
  if Equals(f, n"SixthStreet") { return CBLineOf([CBT(n"Cyberbane-GangVoice-MoveAlongMerc"), CBT(n"Cyberbane-GangVoice-NothingToDiscussKeepWalking"), CBT(n"Cyberbane-GangVoice-YouReNotClearedToTalk")]); }
  if Equals(f, n"Animals") { return CBLineOf([CBT(n"Cyberbane-GangVoice-WordsAreForTheWeak"), CBT(n"Cyberbane-GangVoice-TalkToMyFists"), CBT(n"Cyberbane-GangVoice-NotInterestedWalk")]); }
  if Equals(f, n"VoodooBoys") { return CBLineOf([CBT(n"Cyberbane-GangVoice-WeHaveNothingToSayTo"), CBT(n"Cyberbane-GangVoice-YouReNotWorthTheBandwidth"), CBT(n"Cyberbane-GangVoice-GoTheNetSWatchingYou")]); }
  if Equals(f, n"Mox") { return CBLineOf([CBT(n"Cyberbane-GangVoice-NotTalkingToYouSweetie"), CBT(n"Cyberbane-GangVoice-YouLostTheRightToTalk"), CBT(n"Cyberbane-GangVoice-KeepWalking")]); }
  if Equals(f, n"Scavengers") { return CBLineOf([CBT(n"Cyberbane-GangVoice-WhatYouWantADiscountOn"), CBT(n"Cyberbane-GangVoice-TalkSCheapYouReNot"), CBT(n"Cyberbane-GangVoice-BeatIt")]); }
  if Equals(f, n"Wraiths") { return CBLineOf([CBT(n"Cyberbane-GangVoice-RoadSThisWayTakeIt"), CBT(n"Cyberbane-GangVoice-NothingToSayToYou"), CBT(n"Cyberbane-GangVoice-GetLostDesertSBigEnough")]); }
  if Equals(f, n"Aldecaldos") { return CBLineOf([CBT(n"Cyberbane-GangVoice-NotNowNotToYou"), CBT(n"Cyberbane-GangVoice-YouKnowWhatYouDid"), CBT(n"Cyberbane-GangVoice-FamilyDoesnTTalkToYou")]); }
  if Equals(f, n"Barghest") { return CBLineOf([CBT(n"Cyberbane-GangVoice-MoveAlongCivilian"), CBT(n"Cyberbane-GangVoice-NoComment"), CBT(n"Cyberbane-GangVoice-ThisConversationIsOverBeforeIt")]); }
  if Equals(f, n"Scrappers") { return CBLineOf([CBT(n"Cyberbane-GangVoice-BusyThisWonTStripItself"), CBT(n"Cyberbane-GangVoice-GotNothingToSellYou"), CBT(n"Cyberbane-GangVoice-TalkToSomebodyWhoCares")]); }
  return "";
}

// Their scout stopped answering (CBScoutSilenced).
public func CBGangScoutLostLine(f: CName) -> String {
  if Equals(f, n"Valentinos") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OurHermanoStoppedAnsweringWeLl"), CBT(n"Cyberbane-GangVoice-YouTookOurEyesTheFamily")]); }
  if Equals(f, n"TygerClaws") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OurManWentQuietCostlyFor"), CBT(n"Cyberbane-GangVoice-LostAScoutWeHaveMore")]); }
  if Equals(f, n"Maelstrom") { return CBLineOf([CBT(n"Cyberbane-GangVoice-SpotterSOfflineWeLlTrack"), CBT(n"Cyberbane-GangVoice-KilledOurEyesWeLlGrow")]); }
  if Equals(f, n"SixthStreet") { return CBLineOf([CBT(n"Cyberbane-GangVoice-LostContactWithOurReconWe"), CBT(n"Cyberbane-GangVoice-ScoutSDownDoesnTMatter")]); }
  if Equals(f, n"Animals") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OurGuySNotAnsweringLucky"), CBT(n"Cyberbane-GangVoice-YouGotOurBoyNextOne")]); }
  if Equals(f, n"VoodooBoys") { return CBLineOf([CBT(n"Cyberbane-GangVoice-YouCutOneThreadTheWeb"), CBT(n"Cyberbane-GangVoice-OurEyesWentDarkTheNet")]); }
  if Equals(f, n"Mox") { return CBLineOf([CBT(n"Cyberbane-GangVoice-SheStoppedAnsweringYouDBetter"), CBT(n"Cyberbane-GangVoice-LostOurLookoutWeLlBe")]); }
  if Equals(f, n"Scavengers") { return CBLineOf([CBT(n"Cyberbane-GangVoice-LostOurGuyWhateverThereS"), CBT(n"Cyberbane-GangVoice-HeSNotAnsweringMoreParts")]); }
  if Equals(f, n"Wraiths") { return CBLineOf([CBT(n"Cyberbane-GangVoice-RiderSGoneQuietTheRoad"), CBT(n"Cyberbane-GangVoice-LostOurSpotterDesertSStill")]); }
  if Equals(f, n"Aldecaldos") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OurCousinSNotAnsweringIf"), CBT(n"Cyberbane-GangVoice-LostOurScoutWeLlFind")]); }
  if Equals(f, n"Barghest") { return CBLineOf([CBT(n"Cyberbane-GangVoice-ReconUnitLostAdjusting"), CBT(n"Cyberbane-GangVoice-ForwardObserverDownMissionContinues")]); }
  if Equals(f, n"Scrappers") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OurLookoutWentQuietWeLl"), CBT(n"Cyberbane-GangVoice-LostOurEyesInTheRuins")]); }
  return "";
}

// Hands up, in their own words (Spawn/LivingStreet.reds, TrySurrender).
public func CBGangSurrenderLine(f: CName) -> String {
  if Equals(f, n"Valentinos") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OkayOkayIYieldOnMy"), CBT(n"Cyberbane-GangVoice-BastaItSOverIM"), CBT(n"Cyberbane-GangVoice-PorFavorIGiveUp")]); }
  if Equals(f, n"TygerClaws") { return CBLineOf([CBT(n"Cyberbane-GangVoice-EnoughILlPayYouJust"), CBT(n"Cyberbane-GangVoice-IYieldBadBusinessThis"), CBT(n"Cyberbane-GangVoice-StopYouWinYouWin")]); }
  if Equals(f, n"Maelstrom") { return CBLineOf([CBT(n"Cyberbane-GangVoice-FineFineTakeWhateverIM"), CBT(n"Cyberbane-GangVoice-MyChromeSFriedIM"), CBT(n"Cyberbane-GangVoice-DonTScrapMeIQuit")]); }
  if Equals(f, n"SixthStreet") { return CBLineOf([CBT(n"Cyberbane-GangVoice-IMOutHandsWhereYou"), CBT(n"Cyberbane-GangVoice-StandDownStandDownIM"), CBT(n"Cyberbane-GangVoice-SurrenderingDonTShoot")]); }
  if Equals(f, n"Animals") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OkayYouReStrongerIM"), CBT(n"Cyberbane-GangVoice-EnoughYouWinThisOne")]); }
  if Equals(f, n"VoodooBoys") { return CBLineOf([CBT(n"Cyberbane-GangVoice-IMDisconnectingIMOut"), CBT(n"Cyberbane-GangVoice-EnoughYouVeMadeYourPoint"), CBT(n"Cyberbane-GangVoice-StopIYield")]); }
  if Equals(f, n"Mox") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OkayOkayIMDonePlease"), CBT(n"Cyberbane-GangVoice-IGiveUpDonTHurt"), CBT(n"Cyberbane-GangVoice-EnoughIMOutOfThis")]); }
  if Equals(f, n"Scavengers") { return CBLineOf([CBT(n"Cyberbane-GangVoice-DonTShootILlGo"), CBT(n"Cyberbane-GangVoice-OkayTakeThePartsIM"), CBT(n"Cyberbane-GangVoice-PleaseIMDone")]); }
  if Equals(f, n"Wraiths") { return CBLineOf([CBT(n"Cyberbane-GangVoice-AlrightRoadSYoursIM"), CBT(n"Cyberbane-GangVoice-EnoughIGive")]); }
  if Equals(f, n"Aldecaldos") { return CBLineOf([CBT(n"Cyberbane-GangVoice-OkayForTheFamilySSake"), CBT(n"Cyberbane-GangVoice-StopIYieldIYield")]); }
  if Equals(f, n"Scrappers") { return CBLineOf([CBT(n"Cyberbane-GangVoice-TakeItTakeTheHaulI"), CBT(n"Cyberbane-GangVoice-OkayNotWorthDyingOverJunk"), CBT(n"Cyberbane-GangVoice-IMDoneIMWalking")]); }
  return CBPick3(CBT(n"Cyberbane-GangVoice-OkayOkayIMDone"), CBT(n"Cyberbane-GangVoice-DonTShootIGiveUp"), CBT(n"Cyberbane-GangVoice-EnoughItSOverIM"));
}

// ---- Each gang's own words for its price (Economy/Peace.reds) --------------------------------------------------------

public func CBPriceDemand() -> Int32 = 0
public func CBPriceSworn() -> Int32 = 1
public func CBPriceAsk() -> Int32 = 2
public func CBPriceBroken() -> Int32 = 3
public func CBPricePaid() -> Int32 = 4
public func CBPriceRefused() -> Int32 = 5
public func CBPriceCantPay() -> Int32 = 6

// What a gang says about its price, in its own voice: demanding it, naming it after a threat, begging once it is
// broken, taking it, being refused, and V coming up short. "" for anybody with no voice of its own (a corporation, the
// NCPD), who keep the general words.
public func CBGangPriceLine(f: CName, kind: Int32, cost: Int32) -> String {
  let p = s"\(cost)";
  if Equals(f, n"Valentinos") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Valentinos-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Valentinos-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Valentinos-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Valentinos-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Valentinos-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Valentinos-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Valentinos-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Valentinos-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Valentinos-Refused1"), CBT(n"Cyberbane-GangPrice-Valentinos-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Valentinos-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"TygerClaws") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-TygerClaws-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-TygerClaws-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-TygerClaws-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-TygerClaws-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-TygerClaws-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-TygerClaws-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-TygerClaws-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-TygerClaws-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-TygerClaws-Refused1"), CBT(n"Cyberbane-GangPrice-TygerClaws-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-TygerClaws-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Maelstrom") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Maelstrom-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Maelstrom-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Maelstrom-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Maelstrom-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Maelstrom-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Maelstrom-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Maelstrom-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Maelstrom-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Maelstrom-Refused1"), CBT(n"Cyberbane-GangPrice-Maelstrom-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Maelstrom-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"SixthStreet") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-SixthStreet-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-SixthStreet-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-SixthStreet-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-SixthStreet-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-SixthStreet-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-SixthStreet-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-SixthStreet-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-SixthStreet-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-SixthStreet-Refused1"), CBT(n"Cyberbane-GangPrice-SixthStreet-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-SixthStreet-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Animals") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Animals-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Animals-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Animals-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Animals-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Animals-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Animals-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Animals-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Animals-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Animals-Refused1"), CBT(n"Cyberbane-GangPrice-Animals-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Animals-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"VoodooBoys") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-VoodooBoys-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-VoodooBoys-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-VoodooBoys-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-VoodooBoys-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-VoodooBoys-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-VoodooBoys-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-VoodooBoys-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-VoodooBoys-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-VoodooBoys-Refused1"), CBT(n"Cyberbane-GangPrice-VoodooBoys-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-VoodooBoys-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Mox") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Mox-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Mox-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Mox-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Mox-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Mox-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Mox-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Mox-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Mox-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Mox-Refused1"), CBT(n"Cyberbane-GangPrice-Mox-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Mox-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Scavengers") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scavengers-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Scavengers-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scavengers-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Scavengers-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scavengers-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Scavengers-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scavengers-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scavengers-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Scavengers-Refused1"), CBT(n"Cyberbane-GangPrice-Scavengers-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scavengers-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Wraiths") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Wraiths-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Wraiths-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Wraiths-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Wraiths-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Wraiths-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Wraiths-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Wraiths-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Wraiths-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Wraiths-Refused1"), CBT(n"Cyberbane-GangPrice-Wraiths-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Wraiths-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Aldecaldos") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Aldecaldos-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Aldecaldos-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Aldecaldos-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Aldecaldos-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Aldecaldos-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Aldecaldos-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Aldecaldos-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Aldecaldos-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Aldecaldos-Refused1"), CBT(n"Cyberbane-GangPrice-Aldecaldos-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Aldecaldos-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Barghest") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Barghest-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Barghest-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Barghest-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Barghest-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Barghest-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Barghest-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Barghest-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Barghest-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Barghest-Refused1"), CBT(n"Cyberbane-GangPrice-Barghest-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Barghest-CantPay1", [p])]); }
    return "";
  }
  if Equals(f, n"Scrappers") {
    if kind == 0 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scrappers-Demand1", [p]), CBTf(n"Cyberbane-GangPrice-Scrappers-Demand2", [p])]); }
    if kind == 1 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scrappers-Sworn1", [p]), CBTf(n"Cyberbane-GangPrice-Scrappers-Sworn2", [p])]); }
    if kind == 2 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scrappers-Ask1", [p]), CBTf(n"Cyberbane-GangPrice-Scrappers-Ask2", [p])]); }
    if kind == 3 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scrappers-Broken1", [p])]); }
    if kind == 4 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scrappers-Paid1", [p])]); }
    if kind == 5 { return CBLineOf([CBT(n"Cyberbane-GangPrice-Scrappers-Refused1"), CBT(n"Cyberbane-GangPrice-Scrappers-Refused2")]); }
    if kind == 6 { return CBLineOf([CBTf(n"Cyberbane-GangPrice-Scrappers-CantPay1", [p])]); }
    return "";
  }
  return "";
}
