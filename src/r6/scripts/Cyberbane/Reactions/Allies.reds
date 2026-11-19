// Cyberbane - Talk and allies (2.4.5)
//
//   [65] run with a crew      with a gang Friendly or better, [Watch my back] to one of its people: two of them (three
//                             at Allied) come and follow V, the way the game makes its own companions follow
//                             (AIFollowerRole), and fight whoever fights V. They go home after a game hour, when V
//                             has been off their turf a while, drives off, goes to a job, or shoots one. Once a day.
//   [66] one of theirs        at Allied, a gang may offer to make V one of its own. Joined, V counts as wearing their
//                             colours everywhere, their enemies know V for one of them, their people greet V, and a
//                             favour becomes a duty once a week that costs standing when ignored. V can leave, at a
//                             cost.
//   [67] ransom               a ganger who gave up can be held for their gang's money; the gang pays or comes to take
//                             them back. Or V hands them to a gang at war with theirs.
//   [69] feed the street a lie a talkative passer-by or a frightened ganger can carry a lie to whoever is after V: the
//                             next of them goes looking in the wrong place, and the gang cools off a while. Fail the
//                             Cool check, or tell a liar, and they sell V out instead.
//   [U12] informants          the people who owe V are listed on the Hub; one whose gang finds out is hunted through
//                             the street, and V can stand between them and the hunters.
//   [U2] the sergeant's parley a crew's sergeant who reaches V before anybody fires stops to talk: pay them, scare them
//                             off, or draw.
//
// Followers are spawned for it (CB_Ally with CB_Follower beside it), never a world NPC taken over; one order each, the
// walk home at the end; removed out of V's sight. Session state on the war book, and the one save field it had laid out
// for this: "one of theirs".

public func CBRunWithCrewOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || (rt.GetSettings().runWithCrew && rt.GetSettings().streetTalk);
}

public func CBOneOfTheirsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().oneOfTheirs;
}

public func CBRansomOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBStreetLifeOn(n"surrender") && (!IsDefined(rt) || !rt.HasSettings() || (rt.GetSettings().ransom && rt.GetSettings().streetTalk));
}

public func CBTalkLiesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || (rt.GetSettings().talkLies && rt.GetSettings().streetTalk);
}

public func CBTalkActWatchBack() -> Int32 = 49
public func CBTalkActJoin() -> Int32 = 50
public func CBTalkActLeaveGang() -> Int32 = 51
public func CBTalkActRansom() -> Int32 = 52
public func CBTalkActHandOver() -> Int32 = 53
public func CBTalkActSpreadLie() -> Int32 = 54
public func CBTalkActParleyPay() -> Int32 = 55
public func CBTalkActParleyScare() -> Int32 = 56
public func CBTalkActParleyDraw() -> Int32 = 57

public func CBTalkActIsAlly(act: Int32) -> Bool {
  return act >= CBTalkActWatchBack() && act <= CBTalkActSpreadLie();
}

public func CBTalkActIsParley(act: Int32) -> Bool {
  return act >= CBTalkActParleyPay() && act <= CBTalkActParleyDraw();
}

// ---- The game's own follower role ----------------------------------------------------------------------------------

// The role finds who to follow through its entity reference (AIFollowerRole.OnRoleSet, FindFollowTarget), which a
// quest fills in its editor and the game's own Flathead never needs. Pointed at the player the way the game names the
// player in a reference ("#player", GetGameObjectFromEntityReference).
@addMethod(AIFollowerRole)
public func CBFollowV() -> Void {
  let none: array<CName>;
  this.followerRef = CreateEntityReference("#player", none);
}

// Somebody follows V: their attitude group becomes V's, they join V's squad and V's fights, and the game's companion
// rules (and Cyberbane's own, CBMakeHostileToCompanions) treat them as V's. Cleared, their own group comes back.
public func CBMakeFollower(npc: ref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(npc) || !IsDefined(player) || !npc.IsAttached() {
    return;
  }
  CBTrace("role: one of a friendly gang follows V");
  let role = new AIFollowerRole();
  role.CBFollowV();
  role.SetFollowTarget(player);
  AIHumanComponent.SetCurrentRole(npc, role);
}

public func CBEndFollower(npc: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) || !npc.IsAttached() {
    return;
  }
  CBTrace("role: a follower goes back to their own");
  AIHumanComponent.SetCurrentRole(npc, new AINoRole());
}

// From spawn setup (Spawn/Spawner.reds): one of V's crew for the hour.
public func CBSetUpFollower(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(puppet) || !IsDefined(player) || !CBStillStanding(puppet) {
    return;
  }
  CBDisarmGodMode(game, puppet);
  CBKitSquadMember(puppet);
  CBMakeFollower(puppet, player);
  CBLog.Info(n"Talk", "One of a friendly gang is with V.");
}

// ---- What V can say ------------------------------------------------------------------------------------------------

public func CBAllyTalkLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let war = CBWarBook.Get(game);
  let score = sys.GetScore();
  if !IsDefined(war) || !IsDefined(score) || !IsDefined(t) || !IsDefined(t.npc) || t.cop {
    return out;
  }
  let gang = NotEquals(t.faction, n"") && CBFactionFieldsSquads(t.faction) && !CBIsCorpFaction(t.faction);
  let posture = gang ? score.GetPosture(t.faction) : ECBPosture.Neutral;
  let friendly = Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied);
  // [67] One who gave up.
  if gang && t.npc.cbSurrendered && CBRansomOn() && !IsDefined(war.ransomNpc) {
    let r = CBTalkMakeLine("[Ransom] Your people can have you back. For a price.", CBTalkActRansom(), t"ChoiceCaptionParts.PayIcon");
    r.important = true;
    ArrayPush(out, r);
    let buyer = CBHandOverBuyer(sys, game, t.faction);
    if NotEquals(buyer, n"") {
      ArrayPush(out, CBTalkMakeLine(s"[Hand over] \(CBCapFirst(CBFactionLabel(buyer))) will want a word with you.", CBTalkActHandOver(), TDBID.None()));
    }
    return out;
  }
  // [65] Watch my back.
  if gang && friendly && CBRunWithCrewOn() && ArraySize(war.crewIds) == 0 && war.crewDay != CBGameDay(game) + 1 {
    ArrayPush(out, CBTalkMakeLine("[Watch my back] Some of yours could ride with me for a while.", CBTalkActWatchBack(), t"ChoiceCaptionParts.ReinforcementIcon"));
  }
  // [C4] One of theirs on V's crew for good (Reactions/Crew.reds, 2.5.0).
  if gang {
    let lend = CBCrewLendLine(sys, game, t);
    if IsDefined(lend) {
      ArrayPush(out, lend);
    }
  }
  // [66] One of theirs: join when offered, leave when in.
  if gang && CBOneOfTheirsOn() {
    if Equals(war.OneOfTheirs(), t.faction) {
      ArrayPush(out, CBTalkMakeLine("[Leave] I'm out. Tell them I'm done.", CBTalkActLeaveGang(), t"ChoiceCaptionParts.BackOutIcon"));
    } else {
      if Equals(posture, ECBPosture.Allied) && Equals(war.joinOffer, t.faction) && Equals(war.OneOfTheirs(), n"") {
        let j = CBTalkMakeLine("[Join] Tell them yes. I'm one of yours.", CBTalkActJoin(), t"ChoiceCaptionParts.HandshakeIcon");
        j.important = true;
        ArrayPush(out, j);
      }
    }
  }
  // [69] A lie for whoever is after V, told by somebody who talks.
  let after = CBLieTargetGang(sys, game);
  if CBTalkLiesOn() && NotEquals(after, n"") && !Equals(after, t.faction) && (!gang || t.mood == CBTalkAfraid())
     && war.lieUntil < CBGameSeconds(game) {
    ArrayPush(out, CBTalkMakeLine(s"[Lie] If \(CBFactionLabel(after)) ask, I left for \(CBLieDistrictLabel(sys)).", CBTalkActSpreadLie(), TDBID.None()));
  }
  return out;
}

public func CBAllyTalkAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>,
                             choice: Int32) -> ref<CBTalkAnswer> {
  let war = CBWarBook.Get(game);
  if !IsDefined(war) || !IsDefined(t) || !IsDefined(t.npc) {
    return CBTalkSay("...", n"");
  }
  if choice == CBTalkActWatchBack() {
    return CBWatchMyBack(sys, game, war, t);
  }
  if choice == CBTalkActJoin() {
    war.SetOneOfTheirs(t.faction);
    war.joinOffer = n"";
    CBFileLog(sys, n"OneOfTheirs", CBGameSeconds(game), CBEventDistrict(sys, game), t.faction, 0.0);
    return CBTalkSay(CBPick2("Welcome to the family. Don't make us regret it.", "You're one of us now. Act like it."), n"");
  }
  if choice == CBTalkActLeaveGang() {
    war.SetOneOfTheirs(n"");
    CBTalkSlight(sys, game, t.faction, CBConfig.LeaveGangStanding());
    CBFileLog(sys, n"LeftGang", CBGameSeconds(game), CBEventDistrict(sys, game), t.faction, 0.0);
    return CBTalkSay(CBPick2("Just like that? Fine. Don't come crying to us.", "Out's out. Nobody here owes you anything now."), n"bump");
  }
  if choice == CBTalkActRansom() {
    return CBRansomAsk(sys, game, war, t);
  }
  if choice == CBTalkActHandOver() {
    return CBHandOver(sys, game, t);
  }
  if choice == CBTalkActSpreadLie() {
    return CBSpreadLie(sys, game, player, war, t);
  }
  return CBTalkSay("...", n"");
}

// ---- [65] Run with a crew ------------------------------------------------------------------------------------------

func CBWatchMyBack(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let score = sys.GetScore();
  let fs = sys.FindFaction(t.faction);
  let base = CBGangTemplate(sys, t.faction);   // their own people even if V has never fought one of them (2.5.0)
  // Never on top of a Rival who came to help ("Nobody kills you but me" shares the CB_Ally tag and its clean-up).
  if !TDBID.IsValid(base) || CBSpawnRoom(game) < 3 || CBArrivalsHeld(sys, game) || CBLiveTaggedPresent(game, n"CB_Ally") {
    return CBTalkSay(CBPick2("Not now. Everybody's busy.", "Can't spare anybody right now."), n"");
  }
  let count = IsDefined(score) && Equals(score.GetPosture(t.faction), ECBPosture.Allied) ? CBConfig.CrewAllied() : CBConfig.CrewFriendly();
  let records: array<TweakDBID>;
  ArrayPush(records, IsDefined(fs) ? CBCrewSeat(fs.roleAssaultRecord, base) : CBApexRosterRecord(t.faction, 1));
  ArrayPush(records, IsDefined(fs) ? CBCrewSeat(fs.roleTankRecord, base) : CBApexRosterRecord(t.faction, 0));
  ArrayPush(records, base);
  let sent = 0;
  let k = 0;
  while k < count && k < ArraySize(records) {
    let body: EntityID;
    if CBSpawnGroup(game, records[k], n"", 1, n"CB_Ally", CBConfig.CrewSpawnDistance(), body, n"CB_Follower") > 0 {
      ArrayPush(war.crewIds, body);
      sent += 1;
    }
    k += 1;
  }
  if sent == 0 {
    return CBTalkSay("Nobody can get here. Try again later.", n"");
  }
  let now = CBGameSeconds(game);
  war.crewGang = t.faction;
  war.crewUntil = now + CBConfig.CrewHours() * CBConfig.SecondsPerHour();
  war.crewAway = 0;
  war.crewLeaving = false;
  war.crewDay = CBGameDay(game) + 1;   // stored one up, so day zero still counts as used
  CBFileLog(sys, n"CrewLent", now, CBEventDistrict(sys, game), t.faction, Cast<Float>(sent));
  let here = CBHere(sys);
  let you = CBYou(sys, game);
  return CBTalkSay(sent == 1 ? s"One of ours is on the way to \(here). Keep them breathing, \(you)."
                             : CBLineOf([s"\(sent) of ours are on their way to \(here). Bring them back in one piece.",
                                         s"For you, \(you)? \(sent) of ours. They'll stick with you for an hour. Don't waste them."]), n"");
}

func CBCrewTick(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, player: ref<PlayerPuppet>) -> Void {
  if ArraySize(war.crewIds) == 0 {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  if war.crewLeaving {
    // Gone once V cannot see them; the list empties as they do.
    CBDeleteTaggedSafe(game, n"CB_Follower", true, true);
    let tagged = des.GetTaggedIDs(n"CB_Follower");   // a local, never a temporary (UI/HubWeb.reds, CBWebPair)
    let i = ArraySize(war.crewIds) - 1;
    while i >= 0 {
      if !des.IsSpawning(war.crewIds[i]) && !ArrayContains(tagged, war.crewIds[i]) {
        ArrayErase(war.crewIds, i);
      }
      i -= 1;
    }
    return;
  }
  let now = CBGameSeconds(game);
  let ppos = player.GetWorldPosition();
  let shot = false;
  let far = true;
  let up = 0;
  for id in war.crewIds {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      up += 1;
      if p.cbDamagedByPlayer {
        shot = true;
      }
      if Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.CrewLeaveDistance() {
        far = false;
      }
    } else {
      if des.IsSpawning(id) {
        far = false;
      }
    }
  }
  // Off their turf for long, they go home.
  let gangsHere = CBTurfGangsHere(sys);
  if ArrayContains(gangsHere, war.crewGang) {
    war.crewAway = 0;
  } else {
    war.crewAway += 1;
  }
  let why = "";
  if now >= war.crewUntil {
    why = "Time's up. We're heading back.";
  }
  if war.crewAway >= CBConfig.CrewAwayTicks() {
    why = "This isn't our part of town. We're going home.";
  }
  if far && sys.GetTickCount() % 5 == 0 {
    why = "Lost you. We'll catch up some other time.";
  }
  if CBArrivalsHeld(sys, game) {
    why = "Looks like you've got business. We'll leave you to it.";
  }
  if up == 0 {
    why = "-";
  }
  if shot {
    why = "You shot one of us. We're done here.";
    if !CBReputationFrozen() {
      CBTalkSlight(sys, game, war.crewGang, CBConfig.CrewShotStanding());
    }
  }
  if StrLen(why) > 0 {
    CBCrewGoHome(sys, game, war, why);
  }
}

// Every one of them stops following and walks off: the one order they get.
func CBCrewGoHome(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, why: String) -> Void {
  war.crewLeaving = true;
  for id in war.crewIds {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      CBEndFollower(p);
      // Walked off, as the line says (2.5.1): a sprint away from V read as the crew running from something.
      CBOrderFlee(game, p, true);
    }
  }
  if StrLen(why) > 1 && CBMessagesOn() {
    CBPhoneFromAlly(game, war.crewGang, why);
  }
  CBLog.Info(n"Talk", "V's borrowed crew is going home.");
}

// Start over (Core/CyberbaneSystem.reds, HardReset), before anything of ours is taken out of the world: what the war
// book has going there ends the way it would on its own. The street clash's gangers are the world's own and stay, so
// they are put back as they were; the borrowed crew stop following V, so one still in a car seat, kept until they are
// out of it, does not follow V into the new playthrough; and a held hostage the street's own reset did not let go is
// let go (CBStreetLife.Reset). An open parley's people are ours and go with the rest. Nothing is said. (2.5.0)
public func CBWarStandDown(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>) -> Void {
  if !IsDefined(sys) || !IsDefined(war) {
    return;
  }
  CBClashPutBack(sys, game, war);
  for id in war.crewIds {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      CBEndFollower(p);
    }
  }
  let held = war.ransomNpc;
  if CBNpcSafe(sys, held) && CBStillStanding(held) && held.cbSurrendered {
    held.cbSurrendered = false;
    CBTalkReleaseHold(held);
    CBOrderFlee(game, held);
  }
  war.ResetSession();
}

// ---- [66] One of theirs --------------------------------------------------------------------------------------------

// One of theirs counts as wearing their colours everywhere (Core/CyberbaneSystem.reds, GetDisguiseFaction).
public func CBOneOfTheirsGang(game: GameInstance) -> CName {
  let war = CBWarBook.Get(game);
  return CBOneOfTheirsOn() && IsDefined(war) ? war.OneOfTheirs() : n"";
}

// Their enemies know V for one of them (Reactions/Director.reds, CBRecognizes).
public func CBKnownAsOneOfTheirEnemies(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  let mine = CBOneOfTheirsGang(sys.GetGameInstance());
  if Equals(mine, n"") || Equals(faction, n"") {
    return false;
  }
  let content = sys.GetContent();
  if !IsDefined(content) {
    return false;
  }
  let enemies = CBGangRivalsOf(content, mine);
  return ArrayContains(enemies, faction);
}

// Once a game day (the slow tick): an offer, the week's duty, and leaving when they stop liking V.
public func CBAlliesDaily(sys: ref<CyberbaneSystem>, game: GameInstance, days: Float) -> Void {
  let war = CBWarBook.Get(game);
  let score = sys.GetScore();
  if !IsDefined(war) || !IsDefined(score) || !CBOneOfTheirsOn() {
    return;
  }
  let now = CBGameSeconds(game);
  let mine = war.OneOfTheirs();
  if NotEquals(mine, n"") {
    let p = score.GetPosture(mine);
    if NotEquals(p, ECBPosture.Allied) && NotEquals(p, ECBPosture.Friendly) {
      war.SetOneOfTheirs(n"");
      CBFileLog(sys, n"LeftGang", now, CBEventDistrict(sys, game), mine, 0.0);
      if CBMessagesOn() {
        CBPhoneFromGang(game, mine, "You're not one of ours any more. You know why.");
      }
      return;
    }
    CBGangDuty(sys, game, mine, now);
    return;
  }
  // An offer, from an Allied gang, now and then.
  if NotEquals(war.joinOffer, n"") || RandF() >= CBConfig.JoinOfferChancePerDay() * days || !CBMessagesOn() {
    return;
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) && Equals(score.GetPosture(fs.id), ECBPosture.Allied) {
      war.joinOffer = fs.id;
      let st = CBReadStreet(sys, game, fs.id);
      let deed = IsDefined(st) && st.kills > 0 ? "You've bled for us" : "You've done right by us";
      CBPhoneFromAlly(game, fs.id, s"\(deed), \(CBYou(sys, game)), more than once. Want to be one of ours? Say so to any of us on the street.");
      return;
    }
  }
}

// Favours become duties: once a week they ask for five of an enemy's people, and remember whether V did it. The ask is
// kept in the History (the kills of the enemy when it was asked), so nothing new is saved for it.
func CBGangDuty(sys: ref<CyberbaneSystem>, game: GameInstance, mine: CName, now: Float) -> Void {
  let asked = CBLastLogOf(sys, n"DutyAsked");
  if IsDefined(asked) && now - asked.at < CBConfig.DutyDays() * CBConfig.SecondsPerDay() {
    return;   // the week is not out yet
  }
  if IsDefined(asked) && !IsDefined(CBLastLogOfAfter(sys, n"DutySettled", asked.at)) {
    let enemy = sys.FindFaction(asked.faction);
    let done = IsDefined(enemy) && Cast<Float>(enemy.kills) - asked.value >= Cast<Float>(CBConfig.DutyKills());
    CBFileLog(sys, n"DutySettled", now, CBEventDistrict(sys, game), mine, done ? 1.0 : 0.0);
    if done {
      CBTalkWarm(sys, game, mine, CBConfig.DutyStanding(), 100.0);
      if CBMessagesOn() {
        CBPhoneFromAlly(game, mine, "You did what we asked. That's what family does.");
      }
    } else {
      CBTalkSlight(sys, game, mine, CBConfig.DutyStanding());
      if CBMessagesOn() {
        CBPhoneFromGang(game, mine, "We asked, you didn't come through. People are noticing.");
      }
    }
  }
  let content = sys.GetContent();
  let enemies: array<CName>;
  if IsDefined(content) {
    enemies = CBGangRivalsOf(content, mine);
  }
  for e in enemies {
    let efs = sys.FindFaction(e);
    if IsDefined(efs) && CBFactionFieldsSquads(e) {
      CBFileLog(sys, n"DutyAsked", now, CBEventDistrict(sys, game), e, Cast<Float>(efs.kills));
      if CBMessagesOn() {
        CBPhoneFromAlly(game, mine, s"Family business, \(CBYou(sys, game)): \(CBFactionLabel(e)) are getting comfortable. Put down five of them this week. We'll know.");
      }
      return;
    }
  }
}

// The newest History entry of a kind, or null.
public func CBLastLogOf(sys: ref<CyberbaneSystem>, kind: CName) -> ref<CBLogEntry> {
  let best: ref<CBLogEntry>;
  for e in sys.GetLog() {
    if IsDefined(e) && Equals(e.kind, kind) && (!IsDefined(best) || e.at >= best.at) {
      best = e;
    }
  }
  return best;
}

public func CBLastLogOfAfter(sys: ref<CyberbaneSystem>, kind: CName, after: Float) -> ref<CBLogEntry> {
  let e = CBLastLogOf(sys, kind);
  return IsDefined(e) && e.at >= after ? e : null;
}

// ---- [67] Ransom ---------------------------------------------------------------------------------------------------

// A gang at war with theirs that likes V well enough to take a prisoner off V's hands.
func CBHandOverBuyer(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> CName {
  let content = sys.GetContent();
  let score = sys.GetScore();
  if !IsDefined(content) || !IsDefined(score) {
    return n"";
  }
  for g in CBGangRivalsOf(content, faction) {
    if CBFactionFieldsSquads(g) && score.GetStanding(g) >= 0.0 {
      return g;
    }
  }
  return n"";
}

func CBRansomAsk(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let amount = Max(500, RoundF(CBConfig.RansomBase() * CBLootLevelScale(game) / 100.0) * 100);
  war.ransomNpc = t.npc;
  war.ransomGang = t.faction;
  war.ransomAmount = amount;
  war.ransomTick = sys.GetTickCount();
  if CBMessagesOn() {
    CBPhoneFromGang(game, t.faction, CBLineOf([s"We hear you've got one of ours in \(CBHere(sys)). \(amount)eb, you say? We'll see.",
                                               s"\(amount) for one of ours. You've got some nerve, \(CBYou(sys, game)). Give us a minute."]));
  }
  return CBTalkSay(CBPick2("They'll pay. They'd better pay.", "You think they care enough to pay? ...They'd better."), n"");
}

func CBRansomTick(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(war.ransomNpc) {
    return;
  }
  let p = war.ransomNpc;
  if !CBNpcSafe(sys, p) || !CBStillStanding(p) {
    war.ransomNpc = null;
    return;
  }
  if sys.GetTickCount() - war.ransomTick < CBConfig.RansomTicks() {
    return;
  }
  let gang = war.ransomGang;
  let amount = war.ransomAmount;
  war.ransomNpc = null;
  let now = CBGameSeconds(game);
  let chest = CBWarChestOn() && IsDefined(war) ? war.Chest(gang) : Cast<Float>(amount) * 4.0;
  let pays = chest >= Cast<Float>(amount) && RandF() < CBConfig.RansomPayChance() / MaxF(CBCodeShotHands(gang), 0.5);
  p.cbSurrendered = false;
  CBTalkReleaseHold(p);
  CBOrderFlee(game, p);
  if pays {
    let ts = GameInstance.GetTransactionSystem(game);
    if IsDefined(ts) {
      ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
    }
    CBWarSpend(game, gang, Cast<Float>(amount));
    CBFileLog(sys, n"RansomPaid", now, CBEventDistrict(sys, game), gang, Cast<Float>(amount));
    if CBMessagesOn() {
      CBPhoneFromGang(game, gang, s"\(amount)eb. Now let them walk, and we never did business.");
    }
    return;
  }
  // They come to take them back.
  CBProvoke(sys, game, gang);
  CBFileLog(sys, n"RansomRefused", now, CBEventDistrict(sys, game), gang, 0.0);
  if CBMessagesOn() {
    CBPhoneFromGang(game, gang, "We don't pay for our people. We come and get them.");
  }
}

func CBHandOver(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let buyer = CBHandOverBuyer(sys, game, t.faction);
  if Equals(buyer, n"") {
    return CBTalkSay("...", n"");
  }
  CBTalkWarm(sys, game, buyer, CBConfig.HandOverWarm(), 100.0);
  CBTalkSlight(sys, game, t.faction, CBConfig.HandOverSlight());
  CBFileLog(sys, n"HandedOver", CBGameSeconds(game), CBEventDistrict(sys, game), buyer, 0.0);
  t.npc.cbSurrendered = false;
  CBTalkMarkSent(game, t.npc);
  CBTalkReleaseHold(t.npc);
  CBOrderFlee(game, t.npc);
  if CBMessagesOn() {
    CBPhoneFromAlly(game, buyer, "We'll take it from here. Good doing business.");
  }
  return CBTalkSay(CBPick2("No. No, not them, anybody but them...", "You're handing me to THEM? You're worse than they say."), n"");
}

// ---- [69] Feed the street a lie --------------------------------------------------------------------------------------

// Whoever is after V now, or about to be: the hunt's gang, else the gang queued for a crew.
public func CBLieTargetGang(sys: ref<CyberbaneSystem>, game: GameInstance) -> CName {
  let hunt = sys.GetHuntFaction();
  if NotEquals(hunt, n"") && CBFactionFieldsSquads(hunt) {
    return hunt;
  }
  let lane = sys.GetLaneTarget(CBLaneSquad());
  return NotEquals(lane, n"") && CBFactionFieldsSquads(lane) ? lane : n"";
}

// Somewhere far from V, by name.
public func CBLieDistrictLabel(sys: ref<CyberbaneSystem>) -> String {
  let here = CBDistrictIndex(sys.GetCurrentDistrict());
  let far = (here + 4 + CBHashIndex(sys.GetTickCount() / 600, 5, 3)) % CBDistrictCount();
  return CBDistrictLabel(CBDistrictAt(far));
}

func CBSpreadLie(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, war: ref<CBWarBook>,
                 t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = CBLieTargetGang(sys, game);
  if Equals(gang, n"") {
    return CBTalkSay("Who'd I even tell?", n"");
  }
  let stats = GameInstance.GetStatsSystem(game);
  let cool = IsDefined(stats) ? stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Cool) : 3.0;
  let fs = sys.FindFaction(gang);
  let known = IsDefined(fs) ? ClampF(fs.renown / 100.0, 0.0, 1.0) : 0.0;
  let chance = CBConfig.LieBase() + ClampF((cool - 3.0) / 17.0, 0.0, 1.0) * CBConfig.LieCool() - known * CBConfig.LieKnown();
  let liar = CBTalkTemper(t.npc) == CBTalkTemperLiar();
  let now = CBGameSeconds(game);
  if !liar && RandF() < ClampF(chance, 0.05, 0.9) {
    war.lieGang = gang;
    war.lieUntil = now + CBConfig.LieHours() * CBConfig.SecondsPerHour();
    // And they cool off: no fresh reason to send anybody for a while.
    if IsDefined(fs) {
      fs.lastIncidentAt = MinF(fs.lastIncidentAt, now - CBConfig.CrewReasonHours() * CBConfig.SecondsPerHour());
    }
    CBFileLog(sys, n"LieSpread", now, CBEventDistrict(sys, game), gang, 0.0);
    let away = CBLieDistrictLabel(sys);
    return CBTalkSay(CBLineOf([s"Gone to \(away). Got it. That's what \(CBFactionLabel(gang)) will hear.",
                               s"Sure. You were never in \(CBHere(sys)). Left for \(away), I'll tell them."]), n"");
  }
  CBProvoke(sys, game, gang);
  CBFileLog(sys, n"LieSold", now, CBEventDistrict(sys, game), gang, 0.0);
  return CBTalkSay(CBPick2("Funny. Pretty sure they'll pay more for where you really are.", "Sure, sure. ...Hey, I know who'd love to hear from me."), n"bump");
}

// A lie that is out there for this gang, taken once by the next hunt that starts (Spawn/Hunt.reds, CBHuntBegin):
// true when it was, and their tip is somewhere else entirely.
public func CBTakeLie(game: GameInstance, gang: CName) -> Bool {
  let war = CBWarBook.Get(game);
  if !IsDefined(war) || !Equals(war.lieGang, gang) || CBGameSeconds(game) >= war.lieUntil {
    return false;
  }
  war.lieGang = n"";
  war.lieUntil = 0.0;
  return true;
}

// ---- [U12] Informants with a life ------------------------------------------------------------------------------------

// Who owes V, for the Hub.
public func CBInformantsLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBIntelBook.Get(game);
  if !IsDefined(book) || book.InformantCount() == 0 {
    return "";
  }
  let out = "";
  let i = 0;
  while i < book.InformantCount() {
    let rid = book.InformantRival(i);
    let r = rid > 0 ? sys.FindRivalById(rid) : null;
    let who = IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "somebody in " + CBFactionLabel(book.InformantFaction(i));
    let tips = book.InformantTips(i);
    out += (StrLen(out) > 0 ? "; " : "") + who + (tips == 1 ? ", one tip left" : s", \(tips) tips left");
    i += 1;
  }
  return "Who owes you: " + out + ".";
}

// Once a game day: an informant's gang may find out, and hunt them through the street (the event engine's hunt).
public func CBInformantsDaily(sys: ref<CyberbaneSystem>, game: GameInstance, days: Float) -> Void {
  let book = CBIntelBook.Get(game);
  if !IsDefined(book) || book.InformantCount() == 0 || RandF() >= CBConfig.InformantFoundChancePerDay() * days {
    return;
  }
  let i = RandRange(0, book.InformantCount());
  let gang = book.InformantFaction(i);
  if Equals(gang, n"") || !CBFactionFieldsSquads(gang) {
    return;
  }
  let life = CBStreetLifeFor(game);
  if !IsDefined(life) || !CBGangFightsOn() {
    return;
  }
  life.Events().OweInformantHunt(gang, book.InformantRival(i), CBGameSeconds(game));
  if CBMessagesOn() {
    let rid = book.InformantRival(i);
    let r = rid > 0 ? sys.FindRivalById(rid) : null;
    CBPhoneSend(game, IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : "Your informant",
                s"They know. \(CBCapFirst(CBFactionLabel(gang))) know I've been talking to you. They're coming for me tonight. If you want me alive, be there.");
  }
}

// The hunt is over: the one who talked to V lives or dies (Spawn/StreetEvents.reds, CBFightOver).
public func CBInformantHuntOver(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, rivalId: Int32, saved: Bool) -> Void {
  let book = CBIntelBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  let i = 0;
  while i < book.InformantCount() {
    if Equals(book.InformantFaction(i), gang) && book.InformantRival(i) == rivalId {
      if saved {
        book.GiveTips(i, CBConfig.InformantSavedTips());
        CBFileLog(sys, n"InformantSaved", CBGameSeconds(game), CBEventDistrict(sys, game), gang, 0.0);
      } else {
        book.RemoveInformant(i);
        CBFileLog(sys, n"InformantLost", CBGameSeconds(game), CBEventDistrict(sys, game), gang, 0.0);
      }
      return;
    }
    i += 1;
  }
}

// ---- [U2] The sergeant's parley ---------------------------------------------------------------------------------------

func CBParleyTick(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, player: ref<PlayerPuppet>) -> Void {
  let tick = sys.GetTickCount();
  if war.parleyOpen {
    let s = GameInstance.FindEntityByID(game, war.parleyBody) as ScriptedPuppet;
    let crewHit = false;
    for id in war.parleyCrew {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if IsDefined(p) && p.cbDamagedByPlayer {
        crewHit = true;
      }
    }
    // The clock holds while V is talking to the sergeant (2.5.1, CBTalkEngaged).
    if CBNpcSafe(sys, s) && CBTalkEngaged(sys, s) {
      war.parleyTick = tick;
    }
    if !CBNpcSafe(sys, s) || !CBStillStanding(s) || s.cbDamagedByPlayer || crewHit || tick - war.parleyTick > CBConfig.FacedownTicks() {
      CBParleyFight(sys, game, war);
    }
    return;
  }
  let faction = sys.GetActiveSquadFaction();
  if Equals(faction, n"") || tick % 2 != 0
     || (war.parleyDoneTick > 0 && tick - war.parleyDoneTick < CBConfig.ParleyGapTicks()) {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  // Before the shooting starts, asked as that (2.5.0): nobody of the crew hit by V, and V not hit by the crew. It was
  // asked as "neither side in combat", and a crew sent hostile is in combat the moment it sees V, well before the
  // sergeant is in talking range, so the parley all but never opened. Opening it calms them (CBParleyOpen).
  if CBParleyShotsFired(sys, game, des, player) {
    return;
  }
  for id in des.GetTaggedIDs(n"CB_Squad") {
    let s = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, s) && s.cbSergeant && CBStillStanding(s) && !s.cbDamagedByPlayer
       && !des.IsTagged(id, n"CB_Bounty") && !VehicleComponent.IsMountedToVehicle(game, s.GetEntityID())
       && Vector4.Distance(s.GetWorldPosition(), player.GetWorldPosition()) <= CBConfig.SergeantParleyRange() {
      CBParleyOpen(sys, game, war, des, s, faction);
      return;
    }
  }
}

// Has the fight with this crew begun: V hurt one of them, or the last to hurt V is one of them.
func CBParleyShotsFired(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>) -> Bool {
  for id in des.GetTaggedIDs(n"CB_Squad") {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.cbDamagedByPlayer && !des.IsTagged(id, n"CB_Bounty") {
      return true;
    }
  }
  let by = player.cbLastAttacker;
  return IsDefined(by) && by.IsAttached() && !by.IsDead() && des.IsTagged(by.GetEntityID(), n"CB_Squad");
}

func CBParleyOpen(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, des: ref<DynamicEntitySystem>,
                  s: ref<ScriptedPuppet>, faction: CName) -> Void {
  war.parleyOpen = true;
  war.parleyBody = s.GetEntityID();
  war.parleyGang = faction;
  war.parleyTick = sys.GetTickCount();
  war.parleyDoneTick = sys.GetTickCount();
  ArrayClear(war.parleyCrew);
  for id in des.GetTaggedIDs(n"CB_Squad") {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    // Nobody in a car seat is held or ordered (crash rule 4). Those already in combat are held too: nobody has fired yet.
    if CBNpcSafe(sys, p) && CBStillStanding(p) && !VehicleComponent.IsMountedToVehicle(game, id)
       && Vector4.Distance(p.GetWorldPosition(), s.GetWorldPosition()) <= CBConfig.FacedownEscortRange() {
      ArrayPush(war.parleyCrew, id);
      CBFacedownCalm(game, p);
    }
  }
  s.cbFacedownOpen = true;
  CBSayVoiced(sys, s, n"enemy_warning");
  let crewSize = ArraySize(war.parleyCrew);
  CBIntelSay(game, 3, "Crew sergeant", CBLineOf([s"Hold it! Nobody shoot. \(crewSize) of us, one of \(CBYou(sys, game)). Let's hear what you've got to say.",
                                                 s"Easy. \(CBCapFirst(CBFactionLabel(faction))) talk first. Then we'll see.",
                                                 "Hold your fire! I want to hear this before we start."]), 3.5);
  CBLog.Info(n"Talk", s"A crew sergeant of \(NameToString(faction)) stops to talk.");
}

func CBParleyFight(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>) -> Void {
  let s = GameInstance.FindEntityByID(game, war.parleyBody) as ScriptedPuppet;
  if IsDefined(s) {
    s.cbFacedownOpen = false;
  }
  for id in war.parleyCrew {
    CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
  }
  ArrayClear(war.parleyCrew);
  war.parleyOpen = false;
}

public func CBParleyLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let war = CBWarBook.Get(game);
  let price = IsDefined(war) ? CBParleyPrice(sys, game, war.parleyGang) : 0;
  let pay = CBTalkMakeLine(s"[Pay] \(price)eb, and you tell them you never found me.", CBTalkActParleyPay(), t"ChoiceCaptionParts.PayIcon");
  pay.inactive = CBTalkMoney(game) < price;
  ArrayPush(out, pay);
  ArrayPush(out, CBTalkMakeLine("[Threaten] Walk away while you still can.", CBTalkActParleyScare(), t"ChoiceCaptionParts.GrappleIcon"));
  ArrayPush(out, CBTalkMakeLine("[Draw] Talk's over.", CBTalkActParleyDraw(), TDBID.None()));
  return out;
}

func CBParleyPrice(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Int32 {
  let quote = CBPeaceQuote(sys, game, gang);
  let base = quote > 0 ? Cast<Float>(quote) * CBConfig.TalkCallOffShare() : CBConfig.TalkCallOffMin();
  return Max(RoundF(MaxF(base, CBConfig.TalkCallOffMin()) / 50.0) * 50, 50);
}

public func CBParleyAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>,
                           choice: Int32) -> ref<CBTalkAnswer> {
  let war = CBWarBook.Get(game);
  if !IsDefined(war) || !war.parleyOpen {
    return CBTalkSay("...", n"");
  }
  let gang = war.parleyGang;
  if IsDefined(t.npc) {
    CBTalkMarkSent(game, t.npc);
    t.npc.cbFacedownOpen = false;
  }
  if choice == CBTalkActParleyPay() {
    let price = CBParleyPrice(sys, game, gang);
    if CBTalkTakeMoney(game, player, price) {
      war.parleyOpen = false;
      ArrayClear(war.parleyCrew);
      CBCallOffGang(sys, game, gang);
      CBFileLog(sys, n"ParleyPaid", CBGameSeconds(game), CBEventDistrict(sys, game), gang, Cast<Float>(price));
      return CBTalkSay(CBPick2("Pleasure. We never saw you.", "Money talks. Boys, we're done here."), n"");
    }
    CBParleyFight(sys, game, war);
    return CBTalkSay("You can't cover that. Your loss.", n"");
  }
  if choice == CBTalkActParleyScare() {
    let score = sys.GetScore();
    let fear = IsDefined(score) ? score.GetFactionFear(gang) / 100.0 : 0.0;
    let stats = GameInstance.GetStatsSystem(game);
    let cool = IsDefined(stats) ? stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Cool) : 3.0;
    let chance = CBConfig.ParleyScareBase() + fear * CBConfig.ParleyScareFear() + ClampF((cool - 3.0) / 17.0, 0.0, 1.0) * CBConfig.ParleyScareCool();
    if CBGangCodesOn() && CBCodeNerve(gang) <= 0.0 {
      chance = 0.0;   // a gang whose code never breaks (Barghest) does not back off for words
    }
    if RandF() < chance {
      war.parleyOpen = false;
      ArrayClear(war.parleyCrew);
      CBCallOffGang(sys, game, gang);
      CBTalkFear(sys, game, gang, CBConfig.StareFear());
      CBFileLog(sys, n"ParleyScared", CBGameSeconds(game), CBEventDistrict(sys, game), gang, 0.0);
      return CBTalkSay(CBPick2("...Not worth it. We're out.", "Fine. FINE. Nobody's paying us enough for this."), n"");
    }
    CBParleyFight(sys, game, war);
    return CBTalkSay(CBPick2("Big words. Light them up!", "Is that a threat? Take them!"), n"");
  }
  CBParleyFight(sys, game, war);
  return CBTalkSay("Your call.", n"");
}

// ---- Every tick ---------------------------------------------------------------------------------------------------

public func CBAlliesTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let war = CBWarBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(war) || !IsDefined(player) || !CBWorldStable(game) {
    return;
  }
  CBCrewTick(sys, game, war, player);
  CBRansomTick(sys, game, war, player);
  if CBStreetTalkOn() || war.parleyOpen {
    CBParleyTick(sys, game, war, player);
  }
}

// Somebody of the gang V belongs to, close by, greets V now and then (from the Director's walk).
public func CBOneOfTheirsGreet(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, dist: Float, tick: Int32) -> Void {
  let war = CBWarBook.Get(game);
  if !IsDefined(war) || !CBMessagesOn() || dist > CBConfig.GreetDistance() || tick - war.greetTick < CBConfig.GreetTicks()
     || !Equals(CBOneOfTheirsGang(game), faction) {
    return;
  }
  war.greetTick = tick;
  let st = CBReadStreet(sys, game, faction);
  let you = StrLen(st.title) > 0 ? st.title : "family";
  CBOverheard(game, CBWhisperSpeaker(faction), CBLineOf(["Hey, " + you + ". Good to see you.", "That's one of ours. Make room.",
                                                         "Anybody bothering you round here, you tell us.", "Looking sharp, " + you + "."]));
}
