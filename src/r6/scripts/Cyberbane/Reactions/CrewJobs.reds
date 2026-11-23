// Cyberbane - The crew at work, and goods that change hands (2.7.2)
//
// "Take out a Rival; one of yours vs one of mine; take out a bagman; be a bagman and bank the cash; all without V there.
// And sell what comes out of a stolen bag to other gangs."
//
// All of it is arithmetic on the crew's tick, told by text and shown on the Hub; nothing is spawned for it.
//   - Send them on a job (a member's Orders): a hit on a Rival V knows (from Veteran up), or a gang's bag (from Soldier
//     up). Away some hours, then the odds decide: their rank, the weapon and chrome V gave them, their training, a spar's
//     edge, and for a hit what the crew knows of the Rival's weak spot, against the Rival's rank and escapes or the gang's
//     strength. A hit lands (the Rival is dead, on V's side), leaves the Rival wounded and holed up (a lead with a pin),
//     or goes wrong (the member comes back hurt, or not at all, and the Rival climbs).
//   - The kitty: what the crew brings in (earnings and bags) goes into it. It pays the weekly cut by itself, V takes it on
//     the Hub when home, and a member running the money drops it at V's place every couple of days, unless a gang that
//     hates the crew jumps them on the way.
//   - One of yours against one of mine: the Tyger Claws and the Valentinos, gangs with a code for it, now and then send
//     V a challenge. V picks somebody on the Hub, or turns it down and loses face with them. Settled off-screen.
//   - Goods: now and then a robbed bag is a gang's goods instead of cash, kept as a number (never an item). Sold to
//     somebody of another gang, best to that gang's enemies, or back to its owners for less. Goods go stale in days.

public func CBCrewJobHit() -> Int32 = 1
public func CBCrewJobBag() -> Int32 = 2
public func CBCrewJobDuel() -> Int32 = 3
public func CBCrewWorkRunner() -> Int32 = 4
public func CBCrewAskJob() -> Int32 = 9
public func CBCrewAskDuel() -> Int32 = 10

public func CBGoodsForce() -> Int32 = 1
public func CBGoodsQuiet() -> Int32 = 2

public func CBTalkActSellGoods() -> Int32 = 65

public func CBCrewJobsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBMyCrewOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().crewJobs);
}

public func CBCrewDuelsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBCrewJobsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().crewDuels);
}

public func CBGoodsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().bagGoods);
}

// ---- The books -------------------------------------------------------------------------------------------------------

public class CBCrewJobBook extends ScriptableSystem {
  // Who is away on a job: parallel lists, read by the shortest.
  private persistent let m_member: array<Int32>;
  private persistent let m_kind: array<Int32>;
  private persistent let m_rival: array<Int32>;
  private persistent let m_gang: array<CName>;
  private persistent let m_until: array<Float>;
  private persistent let m_odds: array<Float>;
  // The kitty and who runs it to V.
  private persistent let m_kitty: Int32;
  private persistent let m_runners: array<Int32>;
  private persistent let m_runDue: Float;
  // A challenge waiting for an answer, and when the next may come.
  private persistent let m_chGang: CName;
  private persistent let m_chUntil: Float;
  private persistent let m_chNext: Float;
  private persistent let m_rollDay: Int32;   // the game day the daily rolls were made, one up

  public static func Get(game: GameInstance) -> ref<CBCrewJobBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewJobBook") as CBCrewJobBook : null;
  }

  public func Count() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_member), ArraySize(this.m_kind)), Min(ArraySize(this.m_rival), ArraySize(this.m_gang))),
               Min(ArraySize(this.m_until), ArraySize(this.m_odds)));
  }

  public func IndexOf(member: Int32) -> Int32 {
    let i = 0;
    while i < this.Count() {
      if this.m_member[i] == member {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func RivalTargeted(rival: Int32) -> Bool {
    let i = 0;
    while i < this.Count() {
      if this.m_kind[i] == CBCrewJobHit() && this.m_rival[i] == rival {
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func Add(member: Int32, kind: Int32, rival: Int32, gang: CName, until: Float, odds: Float) -> Void {
    if member <= 0 || this.IndexOf(member) >= 0 {
      return;
    }
    ArrayPush(this.m_member, member);
    ArrayPush(this.m_kind, kind);
    ArrayPush(this.m_rival, rival);
    ArrayPush(this.m_gang, gang);
    ArrayPush(this.m_until, until);
    ArrayPush(this.m_odds, odds);
  }

  public func RemoveAt(i: Int32) -> Void {
    if i >= 0 && i < this.Count() {
      ArrayErase(this.m_member, i);
      ArrayErase(this.m_kind, i);
      ArrayErase(this.m_rival, i);
      ArrayErase(this.m_gang, i);
      ArrayErase(this.m_until, i);
      ArrayErase(this.m_odds, i);
    }
  }

  public func MemberAt(i: Int32) -> Int32 { return this.m_member[i]; }
  public func KindAt(i: Int32) -> Int32 { return this.m_kind[i]; }
  public func RivalAt(i: Int32) -> Int32 { return this.m_rival[i]; }
  public func GangAt(i: Int32) -> CName { return this.m_gang[i]; }
  public func UntilAt(i: Int32) -> Float { return this.m_until[i]; }
  public func OddsAt(i: Int32) -> Float { return this.m_odds[i]; }

  public func Kitty() -> Int32 { return this.m_kitty; }
  public func AddKitty(n: Int32) -> Void { this.m_kitty = Max(0, this.m_kitty + n); }
  public func TakeKitty() -> Int32 {
    let n = this.m_kitty;
    this.m_kitty = 0;
    return n;
  }

  public func IsRunner(id: Int32) -> Bool { return id > 0 && ArrayContains(this.m_runners, id); }
  public func AddRunner(id: Int32) -> Void {
    if id > 0 && !ArrayContains(this.m_runners, id) {
      ArrayPush(this.m_runners, id);
    }
  }
  public func RemoveRunner(id: Int32) -> Void { ArrayRemove(this.m_runners, id); }
  public func RunnerCount() -> Int32 { return ArraySize(this.m_runners); }
  public func RunnerAt(i: Int32) -> Int32 { return this.m_runners[i]; }
  public func RunDue() -> Float { return this.m_runDue; }
  public func SetRunDue(at: Float) -> Void { this.m_runDue = at; }

  public func ChallengeGang() -> CName { return this.m_chGang; }
  public func ChallengeUntil() -> Float { return this.m_chUntil; }
  public func SetChallenge(gang: CName, until: Float, next: Float) -> Void {
    this.m_chGang = gang;
    this.m_chUntil = until;
    this.m_chNext = next;
  }
  public func ClearChallenge() -> Void {
    this.m_chGang = n"";
    this.m_chUntil = 0.0;
  }
  public func ChallengeNext() -> Float { return this.m_chNext; }
  public func RollDay() -> Int32 { return this.m_rollDay; }
  public func SetRollDay(d: Int32) -> Void { this.m_rollDay = d; }

  // Off the roster: off any job, and no longer running the money.
  public func Forget(member: Int32) -> Void {
    this.RemoveAt(this.IndexOf(member));
    this.RemoveRunner(member);
  }

  public func Clear() -> Void {
    ArrayClear(this.m_member);
    ArrayClear(this.m_kind);
    ArrayClear(this.m_rival);
    ArrayClear(this.m_gang);
    ArrayClear(this.m_until);
    ArrayClear(this.m_odds);
    this.m_kitty = 0;
    ArrayClear(this.m_runners);
    this.m_runDue = 0.0;
    this.m_chGang = n"";
    this.m_chUntil = 0.0;
    this.m_chNext = 0.0;
    this.m_rollDay = 0;
  }
}

public class CBGoodsBook extends ScriptableSystem {
  private persistent let m_gang: array<CName>;
  private persistent let m_worth: array<Int32>;
  private persistent let m_how: array<Int32>;
  private persistent let m_at: array<Float>;

  public static func Get(game: GameInstance) -> ref<CBGoodsBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBGoodsBook") as CBGoodsBook : null;
  }

  public func Count() -> Int32 {
    return Min(Min(ArraySize(this.m_gang), ArraySize(this.m_worth)), Min(ArraySize(this.m_how), ArraySize(this.m_at)));
  }

  public func Add(gang: CName, worth: Int32, how: Int32, at: Float) -> Void {
    ArrayPush(this.m_gang, gang);
    ArrayPush(this.m_worth, worth);
    ArrayPush(this.m_how, how);
    ArrayPush(this.m_at, at);
  }

  public func RemoveAt(i: Int32) -> Void {
    if i >= 0 && i < this.Count() {
      ArrayErase(this.m_gang, i);
      ArrayErase(this.m_worth, i);
      ArrayErase(this.m_how, i);
      ArrayErase(this.m_at, i);
    }
  }

  public func GangAt(i: Int32) -> CName { return this.m_gang[i]; }
  public func HowAt(i: Int32) -> Int32 { return this.m_how[i]; }

  // What it would fetch now: hot goods lose a share of their worth every day.
  public func WorthAt(i: Int32, now: Float) -> Int32 {
    let days = MaxF(now - this.m_at[i], 0.0) / CBConfig.SecondsPerDay();
    return RoundF(Cast<Float>(this.m_worth[i]) * MaxF(1.0 - CBConfig.GoodsStalePerDay() * days, 0.0));
  }

  // Gone stale: nobody will touch it any more.
  public func Prune(now: Float) -> Int32 {
    let gone = 0;
    let i = this.Count() - 1;
    while i >= 0 {
      if now - this.m_at[i] > CBConfig.GoodsLifeDays() * CBConfig.SecondsPerDay() {
        this.RemoveAt(i);
        gone += 1;
      }
      i -= 1;
    }
    return gone;
  }

  public func Clear() -> Void {
    ArrayClear(this.m_gang);
    ArrayClear(this.m_worth);
    ArrayClear(this.m_how);
    ArrayClear(this.m_at);
  }
}

// ---- Away on a job ---------------------------------------------------------------------------------------------------

public func CBCrewJobAway(game: GameInstance, id: Int32, now: Float) -> Bool {
  let jb = CBCrewJobBook.Get(game);
  let i = IsDefined(jb) ? jb.IndexOf(id) : -1;
  return i >= 0 && jb.UntilAt(i) > now;
}

public func CBCrewJobHoursLeft(game: GameInstance, id: Int32, now: Float) -> Int32 {
  let jb = CBCrewJobBook.Get(game);
  let i = IsDefined(jb) ? jb.IndexOf(id) : -1;
  return i >= 0 ? Max(1, CeilF((jb.UntilAt(i) - now) / CBConfig.SecondsPerHour())) : 0;
}

// What a member brings to a fight they go to alone: rank, the gear and chrome V gave them, training, a spar's edge.
func CBCrewJobEdge(game: GameInstance, m: ref<CBCrewMember>, now: Float) -> Float {
  let kb = CBCrewKitBook.Get(game);
  let k = IsDefined(kb) ? kb.Find(m.id) : null;
  let edge = CBConfig.CrewJobPerRank() * Cast<Float>(CBCrewRankOf(game, m));
  if IsDefined(k) {
    edge += 0.02 * Cast<Float>(k.weaponTier) + 0.03 * Cast<Float>(k.ChromeCount()) + 0.02 * Cast<Float>(k.trained);
    if k.sharpUntil > now {
      edge += 0.05;
    }
  }
  return edge;
}

public func CBCrewHitOdds(game: GameInstance, m: ref<CBCrewMember>, r: ref<CBRival>, now: Float) -> Float {
  if !IsDefined(m) || !IsDefined(r) {
    return 0.0;
  }
  let chance = CBConfig.CrewHitBase() + CBCrewJobEdge(game, m, now) - CBConfig.CrewHitPerRivalRank() * Cast<Float>(r.rank)
               - 0.03 * Cast<Float>(r.escapes);
  let intel = CBIntelBook.Get(game);
  if IsDefined(intel) && intel.KnowsFlaw(r.id) && CBRivalFlaw(r) != 0 {
    chance += CBConfig.CrewHitFlawBonus();
  }
  return ClampF(chance, 0.1, 0.85);
}

public func CBCrewBagOdds(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, gang: CName, now: Float) -> Float {
  if !IsDefined(m) {
    return 0.0;
  }
  let chance = CBConfig.CrewBagBase() + CBCrewJobEdge(game, m, now) - 0.25 * CBGangStrength(sys, gang) / 100.0;
  return ClampF(chance, 0.2, 0.9);
}

public func CBCrewDuelOdds(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, gang: CName, now: Float) -> Float {
  if !IsDefined(m) {
    return 0.0;
  }
  let chance = CBConfig.CrewDuelBase() + CBCrewJobEdge(game, m, now) - 0.10 * CBGangStrength(sys, gang) / 100.0;
  return ClampF(chance, 0.15, 0.85);
}

// A Rival the crew can go after: alive, not in a fight with V right now, not at their place with V there, not one of
// V's own crew, and not already somebody's job.
public func CBCrewHitTarget(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(r) || r.id <= 0 {
    return false;
  }
  if r.state == EnumInt(ECBRivalState.Slain) || r.state == EnumInt(ECBRivalState.Retired)
     || r.state == EnumInt(ECBRivalState.Debtor) {
    return false;
  }
  if r.id == sys.GetActiveRivalId() || r.id == sys.GetLairRivalId() || sys.RivalKeptByCrew(r.id) {
    return false;
  }
  let jb = CBCrewJobBook.Get(game);
  return !IsDefined(jb) || !jb.RivalTargeted(r.id);
}

public func CBCrewBagTargets(sys: ref<CyberbaneSystem>) -> array<CName> {
  let out: array<CName>;
  let gangs: array<CName> = [n"Maelstrom", n"TygerClaws", n"Valentinos", n"SixthStreet", n"Animals", n"VoodooBoys",
                             n"Scavengers", n"Mox", n"Barghest", n"Scrappers", n"Wraiths", n"Aldecaldos"];
  let score = sys.GetScore();
  for g in gangs {
    let posture = IsDefined(score) ? score.GetPosture(g) : ECBPosture.Neutral;
    if CBFactionOn(g) && CBFactionFieldsSquads(g) && !Equals(posture, ECBPosture.Allied) && !Equals(posture, ECBPosture.Friendly) {
      ArrayPush(out, g);
    }
  }
  return out;
}

// Sent from the Hub (CBCrewKitCarryOut): kind and target, the odds fixed as they leave.
public func CBCrewSendOnJob(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, kind: Int32, rival: Int32,
                            gang: CName) -> Bool {
  let jb = CBCrewJobBook.Get(game);
  let now = CBGameSeconds(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(jb) || !IsDefined(m) || !IsDefined(book) || !CBCrewJobsOn() || book.IsOut(m.id) || CBCrewHurt(m, now)
     || CBCrewAway(game, m.id, now) || CBGuardPosted(game, m.id) {
    return false;
  }
  let rank = CBCrewRankOf(game, m);
  let hours = 0.0;
  let odds = 0.0;
  if kind == CBCrewJobHit() {
    let r = sys.FindRivalById(rival);
    if rank < CBConfig.CrewHitMinRank() || !CBCrewHitTarget(sys, game, r) {
      return false;
    }
    hours = CBConfig.CrewHitHoursBase() + 2.0 * Cast<Float>(r.rank);
    odds = CBCrewHitOdds(game, m, r, now);
    CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-OnMyWayToHit", [CBRivalDisplayName(sys.GetContent(), r)]));
  } else {
    if kind == CBCrewJobBag() {
      if rank < CBConfig.CrewBagMinRank() || Equals(gang, n"") {
        return false;
      }
      hours = CBConfig.CrewBagHours();
      odds = CBCrewBagOdds(sys, game, m, gang, now);
      CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-GoingForTheBag", [CBPossessive(CBFactionLabel(gang))]));
    } else {
      if kind != CBCrewJobDuel() || Equals(gang, n"") {
        return false;
      }
      hours = CBConfig.CrewDuelHours();
      odds = CBCrewDuelOdds(sys, game, m, gang, now);
      CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-IllTakeTheirBest", [CBFactionLabel(gang)]));
    }
  }
  jb.Add(m.id, kind, rival, gang, now + hours * CBConfig.SecondsPerHour(), odds);
  CBLog.Info(n"Crew", s"One of the crew went on a job (kind \(kind), odds \(odds), \(hours) h).");
  return true;
}

// ---- On the crew's tick ----------------------------------------------------------------------------------------------

public func CBCrewJobsTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, now: Float) -> Void {
  let jb = CBCrewJobBook.Get(game);
  if !IsDefined(jb) || !IsDefined(book) {
    return;
  }
  // Jobs that are due, one a tick.
  let i = 0;
  let done = false;
  while i < jb.Count() && !done {
    if now >= jb.UntilAt(i) {
      done = true;
      let m = book.Find(jb.MemberAt(i));
      let kind = jb.KindAt(i);
      let rival = jb.RivalAt(i);
      let gang = jb.GangAt(i);
      let odds = jb.OddsAt(i);
      jb.RemoveAt(i);
      if IsDefined(m) {
        if kind == CBCrewJobHit() {
          CBCrewHitResolve(sys, game, book, m, rival, odds, now);
        } else {
          if kind == CBCrewJobBag() {
            CBCrewBagResolve(sys, game, book, m, gang, odds, now);
          } else {
            CBCrewDuelResolve(sys, game, m, gang, odds, now);
          }
        }
      }
    }
    i += 1;
  }
  // Once a game day: a challenge, the money run, the cut out of the kitty, stale goods.
  let day = CBGameDay(game) + 1;
  if jb.RollDay() != day {
    let first = jb.RollDay() == 0;
    jb.SetRollDay(day);
    if !first {
      CBCrewChallengeRoll(sys, game, jb, book, now);
      CBKittyPaysCut(sys, game, jb, book);
      let goods = CBGoodsBook.Get(game);
      if IsDefined(goods) && goods.Prune(now) > 0 && CBMessagesOn() {
        CBSystemNote(game, CBT(n"Cyberbane-CrewJobs-GoodsWentStale"), 5.0);
      }
    }
  }
  if NotEquals(jb.ChallengeGang(), n"") && now > jb.ChallengeUntil() {
    CBCrewChallengeRefused(sys, game, jb, false);
  }
  CBKittyRun(sys, game, jb, book, now);
}

func CBCrewHitResolve(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>,
                      rival: Int32, odds: Float, now: Float) -> Void {
  let r = sys.FindRivalById(rival);
  let content = sys.GetContent();
  if !IsDefined(r) || r.state == EnumInt(ECBRivalState.Slain) || r.state == EnumInt(ECBRivalState.Retired) {
    CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewJobs-AlreadyGone"));
    return;
  }
  let name = CBRivalDisplayName(content, r);
  let where = CBGangHomeDistrict(sys, game, r.faction);
  let roll = RandF();
  if roll < odds {
    CBRivalSlain(sys, game, r, now, where, true);
    let rb = CBRivalBook.Get(game);
    if IsDefined(rb) {
      rb.SetEnding(r.id, CBEndingByV(), now);
    }
    CBOweFuneral(game, r.faction, true);
    m.wins += 2;
    m.loyalty = Min(100, m.loyalty + 5);
    CBFileLog(sys, n"CrewHit", now, where, r.faction, Cast<Float>(r.id));
    CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-HitDone", [name]));
    CBLog.Info(n"Crew", s"One of the crew killed Rival \(r.id) on a job.");
    return;
  }
  // Wounded and gone to ground: V can finish it.
  if roll < odds + (1.0 - odds) * CBConfig.CrewHitWoundShare() {
    r.scarMask = CBMaskSet(r.scarMask, CBScarShot());
    let player = GetPlayer(game);
    let s = IsDefined(player) ? CBRivalHideout(sys, game, player, r) : null;
    if IsDefined(s) {
      CBMarkLeadTold(sys, s, m.faction, now);
      CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-HitWounded", [name, CBPlacePhrase(s.district)]));
    } else {
      CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-HitWoundedLost", [name]));
    }
    CBLog.Info(n"Crew", s"One of the crew wounded Rival \(r.id); they went to ground.");
    return;
  }
  // It went wrong: the Rival climbs, and the member comes back hurt, or not at all.
  CBPromoteRival(r, content, now);
  r.scarMask = CBMaskSet(r.scarMask, CBScarCut());
  if RandF() < ClampF(CBConfig.CrewJobDeathBase() - 0.04 * Cast<Float>(CBCrewRankOf(game, m)), 0.05, 0.5) {
    let bb = CBCrewBannerBook.Get(game);
    if IsDefined(bb) {
      bb.fallCause = CBCrewFellBeside();
      bb.fallGang = r.faction;
    }
    let who = CBCrewName(sys, m);
    book.Remove(m, CBCrewEndFell(), r.id, where, now);
    CBFileLog(sys, n"CrewHitLost", now, where, r.faction, Cast<Float>(r.id));
    if CBMessagesOn() {
      CBPhoneSendTinted(game, name, CBTf(n"Cyberbane-CrewJobs-HitKilledMember", [who]), CBHudRed());
    }
    CBLog.Info(n"Crew", s"One of the crew died going after Rival \(r.id).");
    return;
  }
  m.hurtUntil = now + CBConfig.CrewJobHurtHours() * CBConfig.SecondsPerHour();
  CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-HitFailed", [name]));
  CBLog.Info(n"Crew", s"One of the crew failed a hit on Rival \(r.id) and came back hurt; the Rival climbed.");
}

func CBCrewBagResolve(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, m: ref<CBCrewMember>,
                      gang: CName, odds: Float, now: Float) -> Void {
  let jb = CBCrewJobBook.Get(game);
  let label = CBFactionLabel(gang);
  let where = CBGangHomeDistrict(sys, game, gang);
  if RandF() < odds {
    let take = CBConfig.CrewBagTakeBase() + CBConfig.CrewBagTakePerRank() * CBCrewRankOf(game, m) + RandRange(0, CBConfig.CrewBagTakeBase());
    let kept = RoundF(Cast<Float>(take) * (1.0 - CBConfig.CrewBagMemberShare()));
    if IsDefined(jb) {
      jb.AddKitty(kept);
    }
    CBWeakenGang(sys, game, gang, CBConfig.BagmanGangLoss() * 0.5);
    m.wins += 1;
    let known = RandF() < CBConfig.CrewBagKnownChance();
    if known {
      CBTalkSlight(sys, game, gang, CBConfig.BagmanStandingLoss());
      CBCrewStandingShift(game, gang, -CBConfig.CrewStandWarLost());
    }
    CBFileLog(sys, n"CrewBag", now, where, gang, Cast<Float>(kept));
    CBCrewText(sys, game, m, known ? CBTf(n"Cyberbane-CrewJobs-BagDoneKnown", [CBPossessive(label), s"\(kept)", label])
                                   : CBTf(n"Cyberbane-CrewJobs-BagDone", [CBPossessive(label), s"\(kept)"]));
    CBLog.Info(n"Crew", s"One of the crew took a bag off \(NameToString(gang)): \(kept)eb to the kitty (known: \(known)).");
    return;
  }
  if RandF() < CBConfig.CrewBagDeathChance() {
    let bb = CBCrewBannerBook.Get(game);
    if IsDefined(bb) {
      bb.fallCause = CBCrewFellBeside();
      bb.fallGang = gang;
    }
    let who = CBCrewName(sys, m);
    book.Remove(m, CBCrewEndFell(), 0, where, now);
    if CBMessagesOn() {
      CBPhoneSendTinted(game, CBCapFirst(label), CBTf(n"Cyberbane-CrewJobs-BagKilledMember", [who]), CBHudRed());
    }
    CBLog.Info(n"Crew", s"One of the crew died going for a bag of \(NameToString(gang)).");
    return;
  }
  m.hurtUntil = now + CBConfig.CrewJobHurtHours() * CBConfig.SecondsPerHour() * 0.5;
  CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-BagFailed", [CBCapFirst(label)]));
}

func CBCrewDuelResolve(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>, gang: CName, odds: Float,
                       now: Float) -> Void {
  let label = CBFactionLabel(gang);
  let who = CBCrewFirst(sys, m);
  if RandF() < odds {
    CBTalkFear(sys, game, gang, CBConfig.CrewDuelFear());
    CBTalkWarm(sys, game, gang, CBConfig.CrewDuelStanding(), CBConfig.CrewDuelStandingCeiling());
    CBCrewStandingShift(game, gang, CBConfig.CrewStandWarEnemy());
    m.wins += 1;
    m.loyalty = Min(100, m.loyalty + 3);
    CBFileLog(sys, n"CrewDuelWon", now, CBEventDistrict(sys, game), gang, Cast<Float>(m.id));
    if CBMessagesOn() {
      CBPhoneFromGang(game, gang, CBTf(n"Cyberbane-CrewJobs-DuelWon", [who]));
    }
    CBLog.Info(n"Crew", s"One of the crew won a duel against \(NameToString(gang)).");
    return;
  }
  m.hurtUntil = now + CBConfig.CrewJobHurtHours() * CBConfig.SecondsPerHour() * 0.5;
  CBTalkFear(sys, game, gang, -CBConfig.CrewDuelFear());
  CBFileLog(sys, n"CrewDuelLost", now, CBEventDistrict(sys, game), gang, Cast<Float>(m.id));
  if CBMessagesOn() {
    CBPhoneFromGang(game, gang, CBTf(n"Cyberbane-CrewJobs-DuelLost", [who]));
  }
  CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewJobs-DuelLostMember", [CBPossessive(label)]));
  CBLog.Info(n"Crew", s"One of the crew lost a duel against \(NameToString(gang)).");
}

// ---- One of yours against one of mine -------------------------------------------------------------------------------

// The gangs with a code for it.
public func CBDuelGangs() -> array<CName> {
  let out: array<CName> = [n"TygerClaws", n"Valentinos"];
  return out;
}

func CBCrewChallengeRoll(sys: ref<CyberbaneSystem>, game: GameInstance, jb: ref<CBCrewJobBook>, book: ref<CBCrewBook>,
                         now: Float) -> Void {
  if !CBCrewDuelsOn() || NotEquals(jb.ChallengeGang(), n"") || now < jb.ChallengeNext() || book.Count() == 0 {
    return;
  }
  let score = sys.GetScore();
  let gangs = CBDuelGangs();
  let start = RandRange(0, ArraySize(gangs));
  let k = 0;
  let sent = false;
  while k < ArraySize(gangs) && !sent {
    let g = gangs[(start + k) % ArraySize(gangs)];
    k += 1;
    let posture = IsDefined(score) ? score.GetPosture(g) : ECBPosture.Neutral;
    if CBFactionOn(g) && !Equals(posture, ECBPosture.Vendetta) && !Equals(posture, ECBPosture.Allied)
       && RandF() < CBConfig.CrewDuelChancePerDay() {
      sent = true;
      jb.SetChallenge(g, now + CBConfig.CrewDuelAnswerHours() * CBConfig.SecondsPerHour(),
                      now + CBConfig.CrewDuelGapDays() * CBConfig.SecondsPerDay());
      if CBMessagesOn() {
        CBPhoneFromGang(game, g, CBT(n"Cyberbane-CrewJobs-Challenge"));
      }
      CBLog.Info(n"Crew", s"\(NameToString(g)) challenged V's crew: one of theirs against one of V's.");
    }
  }
}

// Turned down on the Hub, or let run out: they say V's crew is scared of them.
public func CBCrewChallengeRefused(sys: ref<CyberbaneSystem>, game: GameInstance, jb: ref<CBCrewJobBook>, asked: Bool) -> Void {
  let g = jb.ChallengeGang();
  if Equals(g, n"") {
    return;
  }
  jb.ClearChallenge();
  CBTalkFear(sys, game, g, -CBConfig.CrewDuelRefuseFear());
  if CBMessagesOn() {
    CBPhoneFromGang(game, g, asked ? CBT(n"Cyberbane-CrewJobs-ChallengeRefused") : CBT(n"Cyberbane-CrewJobs-ChallengeIgnored"));
  }
  CBLog.Info(n"Crew", s"V's crew \(asked ? "turned down" : "never answered") a challenge from \(NameToString(g)).");
}

// Answered on the Hub: the member picked goes.
public func CBCrewChallengeAccept(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> Bool {
  let jb = CBCrewJobBook.Get(game);
  if !IsDefined(jb) || Equals(jb.ChallengeGang(), n"") {
    return false;
  }
  let g = jb.ChallengeGang();
  if !CBCrewSendOnJob(sys, game, m, CBCrewJobDuel(), 0, g) {
    return false;
  }
  jb.ClearChallenge();
  return true;
}

// ---- The kitty -------------------------------------------------------------------------------------------------------

// The cut, out of the kitty, when it holds enough: the same fair cut as V paying it.
func CBKittyPaysCut(sys: ref<CyberbaneSystem>, game: GameInstance, jb: ref<CBCrewJobBook>, book: ref<CBCrewBook>) -> Void {
  let owed = book.CutOwed();
  if owed <= 0 || jb.Kitty() < owed {
    return;
  }
  jb.AddKitty(-owed);
  book.SetCutOwed(0);
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    CBCrewLoyalty(m, m.kind == CBCrewPaid() ? CBConfig.MyCrewFairCutPaid() : CBConfig.MyCrewFairCut(), CBCrewWhyNone());
  }
  if CBMessagesOn() {
    CBCrewText(sys, game, null, CBTf(n"Cyberbane-CrewJobs-KittyPaidTheCut", [s"\(owed)"]));
  }
  CBLog.Info(n"Crew", s"The crew's cut (\(owed)eb) was paid out of the kitty.");
}

// On the Hub, at home: the kitty into V's pocket.
public func CBKittyTake(game: GameInstance) -> Int32 {
  let jb = CBCrewJobBook.Get(game);
  if !IsDefined(jb) || jb.Kitty() <= 0 || !CBOnHomeGround(game) {
    return 0;
  }
  let n = jb.TakeKitty();
  CBStreetGiveMoney(game, n);
  CBLog.Info(n"Crew", s"V took \(n)eb out of the crew's kitty.");
  return n;
}

// Every few days, a member running the money drops the kitty at V's place, unless somebody jumps them.
func CBKittyRun(sys: ref<CyberbaneSystem>, game: GameInstance, jb: ref<CBCrewJobBook>, book: ref<CBCrewBook>, now: Float) -> Void {
  if jb.RunnerCount() == 0 {
    return;
  }
  if jb.RunDue() <= 0.0 {
    jb.SetRunDue(now + CBConfig.CrewRunDays() * CBConfig.SecondsPerDay());
    return;
  }
  if now < jb.RunDue() {
    return;
  }
  jb.SetRunDue(now + CBConfig.CrewRunDays() * CBConfig.SecondsPerDay());
  if jb.Kitty() <= 0 {
    return;
  }
  let runner: ref<CBCrewMember>;
  let free = 0;
  let i = 0;
  while i < jb.RunnerCount() {
    let m = book.Find(jb.RunnerAt(i));
    i += 1;
    if IsDefined(m) && !CBCrewHurt(m, now) && !CBCrewAway(game, m.id, now) {
      free += 1;
      if !IsDefined(runner) {
        runner = m;
      }
    }
  }
  if !IsDefined(runner) {
    return;
  }
  // A gang that hates the crew may be waiting on the way; two together are a harder target.
  let bb = CBCrewBannerBook.Get(game);
  let enemy = n"";
  let worst = 0;
  if IsDefined(bb) {
    let s = 0;
    while s < bb.StandCount() {
      if bb.StandValueAt(s) < worst && CBFactionOn(bb.StandGangAt(s)) {
        worst = bb.StandValueAt(s);
        enemy = bb.StandGangAt(s);
      }
      s += 1;
    }
  }
  let jump = CBConfig.CrewRunJumpBase() + (worst <= CBConfig.CrewRunHatedBelow() ? CBConfig.CrewRunJumpHated() : 0.0)
             - CBConfig.CrewRunJumpPerExtra() * Cast<Float>(free - 1);
  let money = jb.Kitty();
  if NotEquals(enemy, n"") && RandF() < ClampF(jump, 0.0, 0.6) {
    let lost = RoundF(Cast<Float>(money) * RandRangeF(0.3, 0.6));
    jb.AddKitty(-lost);
    runner.hurtUntil = now + CBConfig.CrewJobHurtHours() * CBConfig.SecondsPerHour() * 0.5;
    CBCrewText(sys, game, runner, CBTf(n"Cyberbane-CrewJobs-RunJumped", [CBCapFirst(CBFactionLabel(enemy)), s"\(lost)"]));
    CBLog.Info(n"Crew", s"The money run was jumped by \(NameToString(enemy)): \(lost)eb lost.");
    return;
  }
  jb.TakeKitty();
  CBStreetGiveMoney(game, money);
  CBCrewText(sys, game, runner, CBTf(n"Cyberbane-CrewJobs-RunDelivered", [s"\(money)"]));
  CBLog.Info(n"Crew", s"The money run brought V \(money)eb.");
}

// ---- Goods -----------------------------------------------------------------------------------------------------------

// From a robbed bagman (Spawn/LivingStreet.reds): goods instead of cash, now and then. True when it was goods.
public func CBGoodsFromBag(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, take: Int32, quiet: Bool) -> Bool {
  let goods = CBGoodsBook.Get(game);
  if !CBGoodsOn() || !IsDefined(goods) || Equals(gang, n"") || RandF() >= CBConfig.GoodsShare() {
    return false;
  }
  let worth = RoundF(Cast<Float>(take) * CBConfig.GoodsWorthMult());
  goods.Add(gang, worth, quiet ? CBGoodsQuiet() : CBGoodsForce(), CBGameSeconds(game));
  CBSystemNote(game, CBTf(n"Cyberbane-CrewJobs-BagWasGoods", [CBPossessive(CBFactionLabel(gang)), s"\(worth)"]), 7.0);
  CBLog.Info(n"Street", s"A bag of \(NameToString(gang)) was goods, worth \(worth)eb (quiet: \(quiet)).");
  return true;
}

// The goods worth offering this person: another gang's if V has any, else their own gang's, to sell back.
func CBGoodsPick(game: GameInstance, buyer: CName) -> Int32 {
  let goods = CBGoodsBook.Get(game);
  if !IsDefined(goods) || Equals(buyer, n"") {
    return -1;
  }
  let now = CBGameSeconds(game);
  let best = -1;
  let bestWorth = 0;
  let own = -1;
  let i = 0;
  while i < goods.Count() {
    let w = goods.WorthAt(i, now);
    if w > 0 {
      if Equals(goods.GangAt(i), buyer) {
        if own < 0 {
          own = i;
        }
      } else {
        if w > bestWorth {
          best = i;
          bestWorth = w;
        }
      }
    }
    i += 1;
  }
  return best >= 0 ? best : own;
}

public func CBGoodsTalkLine(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkLine> {
  if !CBGoodsOn() || t.cop || Equals(t.faction, n"") || t.mood == CBTalkHostile() {
    return null;
  }
  let goods = CBGoodsBook.Get(game);
  let i = CBGoodsPick(game, t.faction);
  if i < 0 {
    return null;
  }
  let owner = goods.GangAt(i);
  let text = Equals(owner, t.faction) ? CBT(n"Cyberbane-CrewJobs-SellBack")
                                      : CBTf(n"Cyberbane-CrewJobs-SellTo", [CBPossessive(CBFactionLabel(owner))]);
  let line = CBTalkMakeLine(text, CBTalkActSellGoods(), t"ChoiceCaptionParts.PayIcon");
  line.important = true;
  return line;
}

public func CBGoodsSell(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let goods = CBGoodsBook.Get(game);
  let i = CBGoodsPick(game, t.faction);
  if !IsDefined(goods) || i < 0 {
    return CBTalkSay(CBT(n"Cyberbane-CrewJobs-NothingToSell"), n"");
  }
  let now = CBGameSeconds(game);
  let owner = goods.GangAt(i);
  let how = goods.HowAt(i);
  let worth = goods.WorthAt(i, now);
  goods.RemoveAt(i);
  // Sold back: they are glad to have it, and pay less for what was theirs.
  if Equals(owner, t.faction) {
    let back = RoundF(Cast<Float>(worth) * CBConfig.GoodsSellBackShare());
    CBStreetGiveMoney(game, back);
    CBTalkWarm(sys, game, owner, CBConfig.GoodsBackStanding(), 60.0);
    CBLog.Info(n"Street", s"V sold \(NameToString(owner)) their own goods back for \(back)eb.");
    return CBTalkSay(CBTf(n"Cyberbane-CrewJobs-BoughtBack", [s"\(back)"]), n"");
  }
  // Sold to another gang: more to the owner's sworn enemies, and the owner hears of it when it was taken by force or
  // went to those enemies.
  let sworn = ArrayContains(CBGangRivalsOf(sys.GetContent(), t.faction), owner);
  let price = RoundF(Cast<Float>(worth) * (sworn ? CBConfig.GoodsEnemyMult() : 1.0));
  CBStreetGiveMoney(game, price);
  CBTalkWarm(sys, game, t.faction, CBConfig.GoodsBuyerStanding(), 60.0);
  if sworn || how == CBGoodsForce() {
    CBTalkSlight(sys, game, owner, CBConfig.GoodsOwnerStanding());
  }
  CBFileLog(sys, n"GoodsSold", now, CBEventDistrict(sys, game), t.faction, Cast<Float>(price));
  CBLog.Info(n"Street", s"V sold goods of \(NameToString(owner)) to \(NameToString(t.faction)) for \(price)eb (sworn enemies: \(sworn)).");
  return CBTalkSay(sworn ? CBTf(n"Cyberbane-CrewJobs-BoughtGladly", [CBCapFirst(CBPossessive(CBFactionLabel(owner))), s"\(price)"])
                         : CBTf(n"Cyberbane-CrewJobs-Bought", [s"\(price)"]), n"");
}

// For the Hub: a line about the crew's money, and goods V is holding.
public func CBCrewMoneyLine(game: GameInstance) -> String {
  let jb = CBCrewJobBook.Get(game);
  let goods = CBGoodsBook.Get(game);
  let out = "";
  if IsDefined(jb) && CBCrewJobsOn() {
    out += CBTf(n"Cyberbane-CrewJobs-KittyLine", [s"\(jb.Kitty())"]);
  }
  if IsDefined(goods) && goods.Count() > 0 {
    let now = CBGameSeconds(game);
    let total = 0;
    let i = 0;
    while i < goods.Count() {
      total += goods.WorthAt(i, now);
      i += 1;
    }
    out += CBTf(n"Cyberbane-CrewJobs-GoodsLine", [s"\(goods.Count())", s"\(total)"]);
  }
  return out;
}
