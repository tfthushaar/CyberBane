// Cyberbane - what each faction is, as data (2.7.4)
//
// Every faction's code (Data/GangCodes.reds reads it), its cars (Spawn/Arrival.reds) and whether it fields people at
// all, on its profile instead of in chains of faction names in the code that uses them. Adding a faction is one block
// here, and an add-on's faction answers through the same path. Generated from the chains it replaced and checked against
// them value by value, so every faction answers exactly as before; the only new answers are the painted cars for the
// Aldecaldos, the Wraiths and the corporations, and the Wraiths keeping to the Badlands and the city's edge.
//
// Car records are the game's own, each checked against its TweakDB; the v_* ones are those the game's own gang spawns
// use (sts_gang_retaliation dynamic spawn data), so they seat a crew.

public func CBSeedFactionProfiles(c: ref<CyberbaneContent>) -> Void {
  let f: ref<CBFactionProfile>;
  f = c.GetFaction(n"TygerClaws");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.peace = 0.75;
    f.code.insult = 1.6;
    f.code.respectKey = n"Cyberbane-GangCodes-BusinessAndFace";
    f.code.neverKey = n"Cyberbane-GangCodes-AnInsult";
    f.code.fightKey = n"Cyberbane-GangCodes-FastAndTheyDRatherPay";
    f.code.peaceKey = n"Cyberbane-GangCodes-PayTheyReCheapest";
    f.cars = [t"Vehicle.cs_savable_mizutani_shion", t"Vehicle.cs_savable_villefort_alvarado", t"Vehicle.cs_savable_archer_quartz"];
    f.paintedCars = [t"Vehicle.cs_savable_mizutani_shion_tyger", t"Vehicle.cs_savable_archer_quartz_tyger", t"Vehicle.cs_savable_villefort_columbus_tyger"];
    f.loneRide = t"Vehicle.v_sportbike1_yaiba_kusanagi_tyger";
  }
  f = c.GetFaction(n"Maelstrom");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.mercy = 0.7;
    f.code.surrender = 0.6;
    f.code.seesChrome = 0.15;
    f.code.respectKey = n"Cyberbane-GangCodes-ChromeTheMoreOnShowThe";
    f.code.neverKey = n"Cyberbane-GangCodes-HiddenChrome";
    f.code.fightKey = n"Cyberbane-GangCodes-ForYourChrome";
    f.code.peaceKey = n"Cyberbane-GangCodes-Pay";
    f.cars = [t"Vehicle.cs_savable_thorton_colby", t"Vehicle.cs_savable_villefort_columbus", t"Vehicle.cs_savable_thorton_mackinaw"];
    f.paintedCars = [t"Vehicle.cs_savable_thorton_galena_maelstrom", t"Vehicle.cs_savable_chevalier_thrax_maelstrom"];
  }
  f = c.GetFaction(n"Valentinos");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.mercy = 1.6;
    f.code.shotHands = 2.0;
    f.code.surrender = 0.8;
    f.code.peace = 1.15;
    f.code.insult = 1.3;
    f.code.forgive = 0.7;
    f.code.kin = 1.5;
    f.code.grudgeFinisher = 0.9;
    f.code.respectKey = n"Cyberbane-GangCodes-HonourFamilyAndAFairFight";
    f.code.neverKey = n"Cyberbane-GangCodes-AShotSurrenderDouble";
    f.code.fightKey = n"Cyberbane-GangCodes-TogetherAndKinTakeAFallen";
    f.code.peaceKey = n"Cyberbane-GangCodes-SpareTheirsItCountsMoreThan";
    f.cars = [t"Vehicle.cs_savable_mizutani_shion", t"Vehicle.cs_savable_villefort_alvarado", t"Vehicle.cs_savable_archer_quartz"];
    f.paintedCars = [t"Vehicle.cs_savable_villefort_alvarado_valentinos", t"Vehicle.cs_savable_thorton_colby_valentinos", t"Vehicle.cs_savable_chevalier_thrax_valentino", t"Vehicle.cs_savable_thorton_mackinaw_valentinos"];
  }
  f = c.GetFaction(n"SixthStreet");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.nerve = 0.8;
    f.code.surrender = 0.7;
    f.code.soldiers = true;
    f.code.guards = n"SantoDomingo";
    f.code.respectKey = n"Cyberbane-GangCodes-TheNeighbourhoodAndItsPeople";
    f.code.neverKey = n"Cyberbane-GangCodes-HurtingSantoDomingoSPeople";
    f.code.fightKey = n"Cyberbane-GangCodes-LikeSoldiers";
    f.code.peaceKey = n"Cyberbane-GangCodes-PayAndLeaveTheirNeighbourhoodAlone";
    f.cars = [t"Vehicle.cs_savable_thorton_colby", t"Vehicle.cs_savable_villefort_columbus", t"Vehicle.cs_savable_thorton_mackinaw"];
    f.paintedCars = [t"Vehicle.cs_savable_thorton_mackinaw_sixth_street", t"Vehicle.cs_savable_villefort_columbus_sixth_street", t"Vehicle.cs_savable_archer_hella_sixth_street"];
  }
  f = c.GetFaction(n"Animals");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.mercy = 0.7;
    f.code.nerve = 0.5;
    f.code.surrender = 0.3;
    f.code.toughness = 0.25;
    f.code.grudgeClose = 0.6;
    f.code.grudgeGun = 1.25;
    f.code.respectKey = n"Cyberbane-GangCodes-StrengthFistsOverGuns";
    f.code.neverKey = n"Cyberbane-GangCodes-ACowardWithAGun";
    f.code.fightKey = n"Cyberbane-GangCodes-JuicedAndBarelyAfraid";
    f.code.peaceKey = n"Cyberbane-GangCodes-Pay";
    f.cars = [t"Vehicle.cs_savable_thorton_galena", t"Vehicle.cs_savable_thorton_mackinaw", t"Vehicle.cs_savable_thorton_colby"];
  }
  f = c.GetFaction(n"VoodooBoys");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.crew = 0.75;
    f.code.respectKey = n"Cyberbane-GangCodes-Information";
    f.code.neverKey = n"Cyberbane-GangCodes-AnyoneTheyCanTTrace";
    f.code.fightKey = n"Cyberbane-GangCodes-ThroughTheNetFewInPerson";
    f.code.peaceKey = n"Cyberbane-GangCodes-Pay";
    f.paintedCars = [t"Vehicle.cs_savable_mahir_voodoo_boys", t"Vehicle.cs_savable_thorton_galena_voodoo_boys"];
  }
  f = c.GetFaction(n"Scavengers");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.nerve = 1.4;
    f.code.surrender = 1.5;
    f.code.peace = 0.8;
    f.code.insult = 0.7;
    f.code.forgive = 1.5;
    f.code.everybodysEnemy = true;
    f.code.respectKey = n"Cyberbane-GangCodes-NothingAndNobodyMissesThem";
    f.code.neverKey = n"Cyberbane-GangCodes-MuchTheyRunAndNeverCome";
    f.code.fightKey = n"Cyberbane-GangCodes-WhenYouReHurtTheyBreak";
    f.code.peaceKey = n"Cyberbane-GangCodes-CheapAndNobodyElseMinds";
    f.cars = [t"Vehicle.cs_savable_thorton_galena", t"Vehicle.cs_savable_thorton_mackinaw", t"Vehicle.cs_savable_thorton_colby"];
  }
  f = c.GetFaction(n"Mox");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.mercy = 1.4;
    f.code.shotHands = 1.5;
    f.code.nerve = 1.2;
    f.code.surrender = 1.6;
    f.code.crew = 0.7;
    f.code.sendsApex = false;
    f.code.guards = n"Westbrook";
    f.code.respectKey = n"Cyberbane-GangCodes-LookingAfterTheirOwn";
    f.code.neverKey = n"Cyberbane-GangCodes-HurtingJigJigStreetSPeople";
    f.code.fightKey = n"Cyberbane-GangCodes-InSmallCrewsNeverTheirBest";
    f.code.peaceKey = n"Cyberbane-GangCodes-LeaveTheirPeopleAloneSpareThe";
  }
  f = c.GetFaction(n"Wraiths");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounRaffen";
    f.cardLabelKey = n"Cyberbane-Faction-CardRaffen";
    f.code.surrender = 0.8;
    f.code.homes = [n"Badlands", n"SantoDomingo", n"Westbrook"];
    f.code.homeKey = n"Cyberbane-GangCodes-OnlyTheDesert";
    f.code.respectKey = n"Cyberbane-GangCodes-TheRoad";
    f.code.neverKey = n"Cyberbane-GangCodes-AnyoneOnTheirRoad";
    f.code.fightKey = n"Cyberbane-GangCodes-OnTheRoad";
    f.code.peaceKey = n"Cyberbane-GangCodes-PayAndStayOffTheirRoad";
    f.cars = [t"Vehicle.cs_savable_thorton_galena", t"Vehicle.cs_savable_thorton_mackinaw", t"Vehicle.cs_savable_thorton_colby"];
    f.paintedCars = [t"Vehicle.v_standard2_thorton_galena_nomad_wraith", t"Vehicle.v_standard25_thorton_colby_nomad_wraith", t"Vehicle.v_sport2_quadra_type66_nomad_wraith", t"Vehicle.v_standard2_archer_quartz_nomad_wraith", t"Vehicle.v_sport2_mizutani_shion_nomad_wraith"];
  }
  f = c.GetFaction(n"Aldecaldos");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounClan";
    f.cardLabelKey = n"Cyberbane-Faction-CardClan";
    f.code.mercy = 1.3;
    f.code.shotHands = 1.5;
    f.code.surrender = 0.8;
    f.code.forgive = 0.5;
    f.code.kin = 1.3;
    f.code.grudgeAll = 1.3;
    f.code.respectKey = n"Cyberbane-GangCodes-FamilyAFavourRepaidAHarm";
    f.code.neverKey = n"Cyberbane-GangCodes-HarmToFamilyTwiceAsLong";
    f.code.fightKey = n"Cyberbane-GangCodes-AsOneFamily";
    f.code.peaceKey = n"Cyberbane-GangCodes-SpareTheFamily";
    f.cars = [t"Vehicle.cs_savable_thorton_galena", t"Vehicle.cs_savable_thorton_mackinaw", t"Vehicle.cs_savable_thorton_colby"];
    f.paintedCars = [t"Vehicle.cs_savable_thorton_galena_nomad", t"Vehicle.cs_savable_thorton_colby_nomad", t"Vehicle.cs_savable_quadra_type66_nomad"];
  }
  f = c.GetFaction(n"Barghest");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounArmy";
    f.code.mercy = 0.6;
    f.code.nerve = 0.0;
    f.code.surrender = 0.0;
    f.code.peace = 1.4;
    f.code.crew = 1.2;
    f.code.toughness = 0.15;
    f.code.soldiers = true;
    f.code.homes = [n"Dogtown"];
    f.code.respectKey = n"Cyberbane-GangCodes-Discipline";
    f.code.neverKey = n"Cyberbane-GangCodes-AnythingButOnlyInDogtown";
    f.code.fightKey = n"Cyberbane-GangCodes-InNumbersNeverBreakingOrSurrendering";
    f.code.peaceKey = n"Cyberbane-GangCodes-PayALotOrStayOut";
    f.cars = [t"Vehicle.cs_savable_thorton_galena", t"Vehicle.cs_savable_thorton_mackinaw", t"Vehicle.cs_savable_thorton_colby"];
  }
  f = c.GetFaction(n"Arasaka");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounCorporation";
    f.paintedCars = [t"Vehicle.cs_savable_villefort_columbus_arasaka", t"Vehicle.v_standard2_villefort_cortes_arasaka"];
  }
  f = c.GetFaction(n"Militech");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounCorporation";
    f.paintedCars = [t"Vehicle.v_standard3_chevalier_emperor_militech", t"Vehicle.v_standard3_militech_hellhound"];
  }
  f = c.GetFaction(n"KangTao");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounCorporation";
    f.paintedCars = [t"Vehicle.cs_savable_villefort_columbus_kangtao", t"Vehicle.cs_savable_villefort_cortes_kangtao"];
  }
  f = c.GetFaction(n"NCPD");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounLaw";
    f.fieldsSquads = false;
  }
  f = c.GetFaction(n"MaxTac");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.nounKey = n"Cyberbane-Faction-NounLaw";
    f.fieldsSquads = false;
  }
  f = c.GetFaction(n"Scrappers");
  if IsDefined(f) {
    f.code = new CBGangCode();
    f.code.mercy = 1.3;
    f.code.shotHands = 1.5;
    f.code.nerve = 1.3;
    f.code.surrender = 1.4;
    f.code.peace = 0.8;
    f.code.forgive = 1.3;
    f.code.homes = [n"Dogtown"];
    f.code.respectKey = n"Cyberbane-GangCodes-AGoodHaulAndAChance";
    f.code.neverKey = n"Cyberbane-GangCodes-AShotSurrenderButOnlyIn";
    f.code.fightKey = n"Cyberbane-GangCodes-InTheRuinsTheyKnowAnd";
    f.code.peaceKey = n"Cyberbane-GangCodes-CheapAndSpareTheOnesWho";
    f.cars = [t"Vehicle.cs_savable_thorton_galena", t"Vehicle.cs_savable_thorton_mackinaw", t"Vehicle.cs_savable_thorton_colby"];
  }
}
