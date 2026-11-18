// Cyberbane - Being hunted, fairer and more readable (2.4.1)
//
//   [44] a fair first volley  for a moment after a hunter is handed V (CBEngageV), their aim is off: the game's own
//                             Accuracy stat, a modifier added and taken off again the way the game's effectors do
//   [41] lie low on purpose   while they are still searching, changing clothes or slipping into another district
//                             unseen can make the trail go cold, and the Hub says how hot each gang is
//   [42] the metro             riding it already calls back whoever had not reached V (Core/StoryHold.reds); now the
//                             street says so
//   [46] [U8] haunts           the districts V spends time in are counted (CBHuntBook); a hunt starting in one starts
//                             from a closer tip, and hunters see V sooner near the car they know
//   [U7] [68] scouts worth catching   a scout looks without drawing: hostile only once they have called it in, so V
//                             can walk up and pay them to say they found nothing; the Voodoo Boys' scout is a
//                             netrunner who spots V from further off; calling it in shows on the HUD
//   [50] lookouts in the crowd on a hostile gang's streets, the turf watch is somebody: a passer-by who will report V.
//                             The scanner shows them; deal with them (talk, a takedown) and nothing is reported
//
// Its own save book for what outlives a session (haunts now; the bounty, the hunters' ladder, a tracker and a
// corporation's interest in 2.4.2 and 2.4.3), laid out whole so its saved shape never changes.

public func CBFairVolleyOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().fairVolley;
}

public func CBLieLowOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().lieLow;
}

public func CBHauntsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().haunts;
}

public func CBLookoutsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHitSquadsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().lookouts);
}

public func CBTalkActBribeScout() -> Int32 = 39

public class CBHuntBook extends ScriptableSystem {
  private persistent let m_haunt: array<Float>;        // game seconds V has spent in each district (CBDistrictIndex)
  // Later releases (2.4.2, 2.4.3): a tracker, the bounty, the hunters' ladder, a corporation's interest.
  private persistent let m_trackedBy: CName;
  private persistent let m_trackedUntil: Float;
  private persistent let m_bountyBy: CName;
  private persistent let m_bountyAmount: Int32;
  private persistent let m_bountySince: Float;
  private persistent let m_hunterSeed: array<Int32>;
  private persistent let m_hunterRank: array<Int32>;
  private persistent let m_hunterState: array<Int32>;
  private persistent let m_ladderRank: Int32;
  private persistent let m_hunterNext: Float;
  private persistent let m_corpBy: CName;
  private persistent let m_corpAt: Float;
  private let m_padded: Bool;
  public let safeTicks: Int32;         // real seconds V has spent somewhere safe while tracked (2.4.2)

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.m_padded = false;
    // Whoever was out or on their way went with the world the save threw away.
    ArrayClear(this.outBody);
    ArrayClear(this.outSlot);
    ArrayClear(this.outDownTick);
    this.comingSlot = 0;
    this.comingPair = 0;
    this.comingTicks = 0;
    this.payRequested = false;
  }

  public func TrackedBy() -> CName { return this.m_trackedBy; }
  public func TrackedUntil() -> Float { return this.m_trackedUntil; }

  public func SetTracked(gang: CName, until: Float) -> Void {
    this.m_trackedBy = gang;
    this.m_trackedUntil = until;
    this.safeTicks = 0;
  }

  // ---- The price on V's head and the hunters' ladder (Spawn/Bounty.reds, 2.4.3) ----
  // Session only: who of the ladder is out after V now, and who is on their way.
  public let outBody: array<EntityID>;
  public let outSlot: array<Int32>;      // index into the roster, for each body above
  public let outDownTick: array<Int32>;  // the tick they were first seen down and breathing, 0 not yet
  public let comingSlot: Int32;          // roster index + 1 of the one on their way (0: nobody)
  public let comingPair: Int32;          // and a second, likewise
  public let comingTicks: Int32;
  public let payRequested: Bool;         // chosen on the Hub, carried out on the next tick back in the game
  public let darkKills: Int32;           // a crew picked off this hunt with nobody seeing V (2.4.6, [80])
  public let briefDay: Int32;            // the game day + 1 the morning brief last went out (2.4.6, [83])

  public func BountyBy() -> CName { return this.m_bountyBy; }
  public func BountyAmount() -> Int32 { return this.m_bountyAmount; }
  public func BountySince() -> Float { return this.m_bountySince; }
  public func SetBounty(by: CName, amount: Int32, since: Float) -> Void {
    this.m_bountyBy = by;
    this.m_bountyAmount = Max(amount, 0);
    this.m_bountySince = since;
  }
  public func LadderRank() -> Int32 { return this.m_ladderRank; }
  public func SetLadderRank(rank: Int32) -> Void { this.m_ladderRank = Clamp(rank, 0, CBConfig.LadderPlaces()); }
  public func HunterNext() -> Float { return this.m_hunterNext; }
  public func SetHunterNext(at: Float) -> Void { this.m_hunterNext = at; }
  public func CorpBy() -> CName { return this.m_corpBy; }
  public func CorpAt() -> Float { return this.m_corpAt; }
  public func SetCorp(by: CName, at: Float) -> Void {
    this.m_corpBy = by;
    this.m_corpAt = at;
  }

  // The roster: three arrays kept in step, read only as far as the shortest (Pad).
  public func HunterCount() -> Int32 {
    this.Pad();
    return ArraySize(this.m_hunterSeed);
  }
  public func HunterSeed(i: Int32) -> Int32 {
    this.Pad();
    return i >= 0 && i < ArraySize(this.m_hunterSeed) ? this.m_hunterSeed[i] : 0;
  }
  public func HunterRank(i: Int32) -> Int32 {
    this.Pad();
    return i >= 0 && i < ArraySize(this.m_hunterRank) ? this.m_hunterRank[i] : 0;
  }
  public func HunterState(i: Int32) -> Int32 {
    this.Pad();
    return i >= 0 && i < ArraySize(this.m_hunterState) ? this.m_hunterState[i] : 1;
  }
  public func SetHunterRank(i: Int32, rank: Int32) -> Void {
    this.Pad();
    if i >= 0 && i < ArraySize(this.m_hunterRank) {
      this.m_hunterRank[i] = rank;
    }
  }
  public func SetHunterState(i: Int32, state: Int32) -> Void {
    this.Pad();
    if i >= 0 && i < ArraySize(this.m_hunterState) {
      this.m_hunterState[i] = state;
    }
  }
  public func AddHunter(seed: Int32, rank: Int32) -> Void {
    this.Pad();
    ArrayPush(this.m_hunterSeed, seed);
    ArrayPush(this.m_hunterRank, rank);
    ArrayPush(this.m_hunterState, 0);
  }
  // The roster's oldest gone entries, once it has grown long: nobody reads a dead hunter's place.
  public func DropGone(keep: Int32) -> Void {
    this.Pad();
    let i = 0;
    while ArraySize(this.m_hunterSeed) > keep && i < ArraySize(this.m_hunterSeed) {
      if this.m_hunterState[i] != 0 {
        ArrayErase(this.m_hunterSeed, i);
        ArrayErase(this.m_hunterRank, i);
        ArrayErase(this.m_hunterState, i);
      } else {
        i += 1;
      }
    }
  }

  public static func Get(game: GameInstance) -> ref<CBHuntBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBHuntBook") as CBHuntBook;
  }

  private func Pad() -> Void {
    if this.m_padded {
      return;
    }
    this.m_padded = true;
    while ArraySize(this.m_haunt) < CBDistrictCount() {
      ArrayPush(this.m_haunt, 0.0);
    }
    let n = Min(ArraySize(this.m_hunterSeed), Min(ArraySize(this.m_hunterRank), ArraySize(this.m_hunterState)));
    ArrayResize(this.m_hunterSeed, n);
    ArrayResize(this.m_hunterRank, n);
    ArrayResize(this.m_hunterState, n);
  }

  public func AddHaunt(i: Int32, seconds: Float) -> Void {
    this.Pad();
    if i >= 0 && i < ArraySize(this.m_haunt) {
      this.m_haunt[i] += seconds;
    }
  }

  // A haunt: a district holding at least a third of the time V has spent anywhere lately.
  public func IsHaunt(i: Int32) -> Bool {
    this.Pad();
    if i < 0 || i >= ArraySize(this.m_haunt) {
      return false;
    }
    let total = 0.0;
    for t in this.m_haunt {
      total += t;
    }
    return total >= CBConfig.HauntMinSeconds() && this.m_haunt[i] >= total * CBConfig.HauntShare();
  }

  public func FadeHaunts(days: Float) -> Void {
    this.Pad();
    let keep = PowF(CBConfig.HauntDailyKeep(), MaxF(days, 0.0));
    let i = 0;
    while i < ArraySize(this.m_haunt) {
      this.m_haunt[i] *= keep;
      i += 1;
    }
  }

  public func Clear() -> Void {
    ArrayClear(this.m_haunt);
    this.m_trackedBy = n"";
    this.m_trackedUntil = 0.0;
    this.m_bountyBy = n"";
    this.m_bountyAmount = 0;
    this.m_bountySince = 0.0;
    ArrayClear(this.m_hunterSeed);
    ArrayClear(this.m_hunterRank);
    ArrayClear(this.m_hunterState);
    this.m_ladderRank = 0;
    this.m_hunterNext = 0.0;
    this.m_corpBy = n"";
    this.m_corpAt = 0.0;
    this.m_padded = false;
    ArrayClear(this.outBody);
    ArrayClear(this.outSlot);
    ArrayClear(this.outDownTick);
    this.comingSlot = 0;
    this.comingPair = 0;
    this.comingTicks = 0;
    this.payRequested = false;
  }
}

// ---- [44] A fair first volley ---------------------------------------------------------------------------

@addField(ScriptedPuppet)
public let cbVolleyed: Bool;

public class CBVolleyEndCallback extends DelayCallback {
  public let game: GameInstance;
  public let id: EntityID;
  public let mod: ref<gameStatModifierData>;

  public func Call() -> Void {
    let stats = GameInstance.GetStatsSystem(this.game);
    if IsDefined(stats) && IsDefined(this.mod) {
      stats.RemoveModifier(Cast<StatsObjectID>(this.id), this.mod);
    }
  }
}

// The first time a hunter is handed V: their aim is off for a moment, then back. Once per body.
public func CBFairVolley(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !CBFairVolleyOn() || !IsDefined(puppet) || puppet.cbVolleyed || !puppet.IsAttached() {
    return;
  }
  puppet.cbVolleyed = true;
  let stats = GameInstance.GetStatsSystem(game);
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(stats) || !IsDefined(ds) {
    return;
  }
  let id = puppet.GetEntityID();
  let mod = RPGManager.CreateStatModifier(gamedataStatType.Accuracy, gameStatModifierType.Multiplier, CBConfig.FairVolleyAim());
  if !IsDefined(mod) || !stats.AddModifier(Cast<StatsObjectID>(id), mod) {
    return;
  }
  let cb = new CBVolleyEndCallback();
  cb.game = game;
  cb.id = id;
  cb.mod = mod;
  ds.DelayCallback(cb, CBConfig.FairVolleySeconds(), false);
}

// ---- [41] Lie low; [46] haunts --------------------------------------------------------------------------

// How hot a gang is, for the Hub: from when they last had reason.
public func CBHeatWord(game: GameInstance, fs: ref<CBFactionState>) -> String {
  if !CBLieLowOn() || !IsDefined(fs) || fs.lastIncidentAt <= 0.0 {
    return "";
  }
  let ago = CBGameSeconds(game) - fs.lastIncidentAt;
  if ago < 0.0 {
    return "";
  }
  if ago < CBConfig.HeatHotHours() * CBConfig.SecondsPerHour() {
    return "still hot about you";
  }
  if ago < CBConfig.HeatCoolHours() * CBConfig.SecondsPerHour() {
    return "cooling off";
  }
  return "";
}

// From the fast tick: V's time in each district, and the hunt's chances to lose the trail.
public func CBHuntedTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBHuntBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(player) {
    return;
  }
  let tick = sys.GetTickCount();
  if CBHauntsOn() && tick % 10 == 0 {
    book.AddHaunt(CBDistrictIndex(sys.GetCurrentDistrict()), CBConfig.HauntSecondsPerSample());
  }
  // The trail goes cold: still searching, nobody has eyes on V, and V has changed how they look or where they are.
  let rt = CyberbaneRuntime.Get();
  if !CBLieLowOn() || !IsDefined(rt) || sys.GetHuntState() != CBHuntSearching() {
    if IsDefined(rt) {
      rt.ClearTrail();
    }
    return;
  }
  let score = sys.GetScore();
  let look = IsDefined(score) ? score.GetLook() : 0.0;
  let here = sys.GetCurrentDistrict();
  if !rt.TrailSet() {
    rt.SetTrailLook(look, here);
    return;
  }
  let changedClothes = AbsF(look - rt.TrailLook()) >= CBConfig.TrailLookChange();
  let changedDistrict = NotEquals(here, rt.TrailDistrict()) && NotEquals(here, n"");
  if !changedClothes && !changedDistrict {
    return;
  }
  rt.SetTrailLook(look, here);
  if tick - sys.GetHuntLastSeenTick() < CBConfig.TrailUnseenTicks() || RandF() >= CBConfig.TrailColdChance() {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  let faction = sys.GetHuntFaction();
  CBChaseGiveUp(sys, game, des, true);
  sys.SetHuntState(CBHuntNone());
  sys.SetHuntFaction(n"");
  sys.SetHuntGrade("");
  CBLog.Info(n"Spawn", "The trail went cold.");
  if CBToastsOn() && NotEquals(faction, n"") {
    CBHearsayFromStreet(game, changedClothes ? "Whoever was after you lost you when you changed. They're looking for somebody else now."
                                             : "Whoever was after you lost your trail when you crossed over.", n"");
  }
}

// A hunt starting where V spends time starts from a closer tip ([U8]).
public func CBHauntTipMult(sys: ref<CyberbaneSystem>, game: GameInstance) -> Float {
  let book = CBHuntBook.Get(game);
  if !CBHauntsOn() || !IsDefined(book) || !IsDefined(sys) {
    return 1.0;
  }
  return book.IsHaunt(CBDistrictIndex(sys.GetCurrentDistrict())) ? CBConfig.HauntTipMult() : 1.0;
}

// ---- [U7] [68] Scouts worth catching --------------------------------------------------------------------

// A scout looks without drawing (Spawn/Spawner.reds sets them up this way): neutral to V until they have called it in.
public func CBSetUpScout(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !CBStillStanding(puppet) || !puppet.IsAttached() {
    return;
  }
  let agent = puppet.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) {
    if !IsNameValid(agent.GetAttitudeGroup()) {
      let group = CBRecordAttitudeGroup(puppet.GetRecordID());
      if IsNameValid(group) {
        agent.SetAttitudeGroupUnsavable(group);
      }
    }
    CBTrace("attitude: a scout looks without drawing");
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
  }
  CBGrantAbility(puppet as NPCPuppet, t"Ability.IsAggressive");
  CBDisarmGodMode(game, puppet);
  CBOrderPursue(sys, game, puppet);
  CBTrackOnMap(game, puppet);
}

// The scout has called it in: now they fight.
public func CBScoutDraws(game: GameInstance, scoutId: EntityID) -> Void {
  let scout = GameInstance.FindEntityByID(game, scoutId) as ScriptedPuppet;
  if CBStillStanding(scout) && scout.IsAttached() {
    CBMakeHostileToPlayer(game, scout);
  }
}

// Which record a gang's scout comes from: the Voodoo Boys send a netrunner, everybody else one of their own.
public func CBScoutRecord(fs: ref<CBFactionState>) -> TweakDBID {
  if CBGangCodesOn() && Equals(fs.id, n"VoodooBoys") {
    let net = CBNetrunnerSeatRecord(fs);
    if TDBID.IsValid(net) {
      return net;
    }
  }
  return TDBID.IsValid(fs.sampleRecord) ? fs.sampleRecord : CBApexRosterRecord(fs.id, 1);
}

// How far a gang's scout sees, as a share: a Voodoo Boys netrunner pings from further off.
public func CBScoutReach(faction: CName) -> Float {
  return CBGangCodesOn() && Equals(faction, n"VoodooBoys") ? CBConfig.NetrunnerScoutReach() : 1.0;
}

public func CBIsScoutBody(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> Bool {
  return IsDefined(sys) && IsDefined(npc) && EntityID.IsDefined(sys.GetScoutId()) && Equals(npc.GetEntityID(), sys.GetScoutId());
}

public func CBScoutBribePrice(sys: ref<CyberbaneSystem>) -> Int32 {
  let score = sys.GetScore();
  return RoundF(CBConfig.ScoutBribeBase() + (IsDefined(score) ? score.GetRenown() : 0.0) * CBConfig.ScoutBribePerRenown());
}

public func CBScoutTalkLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  if !CBPayTheStreetOn() || !IsDefined(t) || !CBIsScoutBody(sys, t.npc) {
    return out;
  }
  let price = CBScoutBribePrice(sys);
  let l = CBTalkMakeLine(s"[Pay] \(price)eb. Tell them you didn't find me.", CBTalkActBribeScout(), t"ChoiceCaptionParts.PayIcon");
  l.inactive = CBTalkMoney(game) < price;
  l.important = true;
  ArrayPush(out, l);
  return out;
}

public func CBScoutTalkAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  if !CBIsScoutBody(sys, t.npc) {
    return CBTalkSay("Find what? I'm just walking.", n"");
  }
  let price = CBScoutBribePrice(sys);
  if !CBTalkTakeMoney(game, player, price) {
    return CBTalkSay("That doesn't buy my silence.", n"");
  }
  let faction = sys.GetScoutFaction();
  sys.ClearScout();
  let fs = sys.FindFaction(faction);
  if IsDefined(fs) {
    fs.lastHitSquadAt = CBGameSeconds(game);   // they leave V alone a while, as a silenced scout's gang does
  }
  if IsDefined(t.npc) {
    CBOrderFlee(game, t.npc);
  }
  CBFileLog(sys, n"ScoutBribed", CBGameSeconds(game), CBEventDistrict(sys, game), faction, Cast<Float>(price));
  return CBTalkSay(CBLineOf(["Never saw you. Nobody here but me.", "You were never here. Good doing business.",
                             "I'll tell them the trail went cold. Don't make me a liar."]), n"");
}

// ---- [50] Lookouts in the crowd -------------------------------------------------------------------------

@addField(ScriptedPuppet)
public let cbLookoutFor: CName;

public func CBIsLookout(npc: wref<ScriptedPuppet>) -> Bool {
  return IsDefined(npc) && NotEquals(npc.cbLookoutFor, n"");
}

// Somebody near V in the crowd, to be the gang's eyes on its streets. None, and the watch works as it always did.
public func CBPickLookout(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> EntityID {
  let none: EntityID;
  let reg = sys.GetRegistry();
  let player = GetPlayer(game);
  if !CBLookoutsOn() || !IsDefined(reg) || !IsDefined(player) {
    return none;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  let ppos = player.GetWorldPosition();
  for npc in reg.GetAll() {
    if CBNpcSafe(sys, npc) && CBStillStanding(npc) && !CBSentByUs(des, npc) && !npc.cbTalkPartner {
      let d = Vector4.Distance(ppos, npc.GetWorldPosition());
      if d >= CBConfig.LookoutMinDistance() && d <= CBConfig.LookoutMaxDistance() && Equals(CBClassifyFaction(npc), n"") {
        npc.cbLookoutFor = gang;
        npc.SetScannerDirty(true);
        return npc.GetEntityID();
      }
    }
  }
  return none;
}

// Has V dealt with the lookout: put them down, or talked them out of it?
public func CBLookoutDealt(game: GameInstance, id: EntityID) -> Bool {
  if !EntityID.IsDefined(id) {
    return false;
  }
  let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
  if !IsDefined(p) || !p.IsAttached() {
    return false;   // out of the world, or on the way out: they may yet report
  }
  return !CBStillStanding(p) || p.cbWitnessHushed;
}

public func CBLookoutRelease(game: GameInstance, id: EntityID) -> Void {
  if !EntityID.IsDefined(id) {
    return;
  }
  let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
  if IsDefined(p) {
    p.cbLookoutFor = n"";
    p.SetScannerDirty(true);
  }
}
