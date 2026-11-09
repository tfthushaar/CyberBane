// Cyberbane - Turf wars (1.6.3)
//
// Night City's gangs already had turf here, but it was a fixed list: whatever V did, the Tyger
// Claws held Westbrook and the Valentinos held Heywood for ever. The idea of gangs that actually
// fight over districts, where the stronger one wins and putting a gang's people in the ground
// weakens it, was suggested from Gang Retaliation by NovaAntonsito. The implementation is
// Cyberbane's own and is built from what this mod already tracks.
//
//   Strength   Every gang stands at 100 until V starts on them. Each of their people V puts down
//              costs them a little, an officer more, a boss, a Rival or a beaten crew a lot. They
//              rebuild while V leaves them alone, a dozen points an in-game day, and never fall
//              below a floor: a gang is weakened, never wiped out.
//   Control    A district is split between the gangs whose streets it is, by strength squared, so
//              a stronger gang holds clearly more and a broken one is pushed to the margins. The
//              split drifts a little day to day on its own (gangs skirmish without V), the same
//              way for everybody on the same day, so the map moves without anything random being
//              stored.
//   Moving in  When a district's own gang is broken, a gang at war with them from next door moves
//              in: the weaker the owners, the harder the push. Break the Valentinos and 6th Street
//              walks into Heywood. Let them rebuild and they take it back.
//   Holding    Whoever holds a real share of a district (TurfPresenceShare) is on their own streets
//              there: their lookouts watch V, their crews know where V is, their vendors know
//              where V stands with them. A gang pushed out of a district is none of those there.
//
// When a district changes hands the street texts V, and the History screen keeps it. The Hub's
// TURF screen shows who holds each district, how firmly, and who is fighting over it.
//
// Crash safety and saves. Nothing here touches the engine: it is arithmetic over Cyberbane's own
// numbers, read on settled ticks and from the Hub. Strength is kept in the global play service,
// keyed by playthrough, exactly as 1.6.2 keeps where Rivals were seen (Core/CyberbaneService.reds):
// nothing in the save changes shape. A record from a later point in the same playthrough (an older
// save loaded) is ignored rather than trusted, and a fresh playthrough starts everybody at full
// strength.

public func CBTurfWarsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  return !rt.HasSettings() || rt.GetSettings().turfWars;
}

// ---- Strength ---------------------------------------------------------------------------------

// How strong this gang is right now, 0..100, with what it has rebuilt since it was last hurt.
// Read-only: rebuilding is worked out from the time, never written back here.
public func CBGangStrength(sys: ref<CyberbaneSystem>, faction: CName) -> Float {
  if !IsDefined(sys) || Equals(faction, n"") || !CBTurfWarsOn() {
    return 100.0;
  }
  let svc = sys.GetPlayService();
  if !IsDefined(svc) {
    return 100.0;
  }
  let p = svc.FindGangPower(sys.GetPlaythroughId(), faction);
  if !IsDefined(p) {
    return 100.0;
  }
  let now = CBGameSeconds(sys.GetGameInstance());
  // Written later in this playthrough than this save has reached: an older save is loaded. Not
  // this save's history, so it does not count against them.
  if p.at > now + CBConfig.SecondsPerHour() {
    return 100.0;
  }
  let days = MaxF(0.0, now - p.at) / CBConfig.SecondsPerDay();
  return ClampF(p.strength + days * CBConfig.GangRecoverPerDay(), CBConfig.GangStrengthFloor(), 100.0);
}

// One word for it, for the Hub and the texts.
public func CBGangStrengthWord(strength: Float) -> String {
  if strength < CBConfig.GangBrokenStrength() {
    return "broken";
  }
  if strength < CBConfig.GangBleedingStrength() {
    return "bleeding";
  }
  if strength < 85.0 {
    return "hurting";
  }
  return "strong";
}

// V has cost this gang something. Settled callers only (the kill path, a Rival's death, a crew
// or an apex squad beaten), and it only ever writes a number into the play service.
public func CBWeakenGang(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") || amount <= 0.0 || !CBTurfWarsOn()
     || !CBGangHoldsTurf(sys, faction) {
    return;
  }
  let svc = sys.GetPlayService();
  let pid = sys.GetPlaythroughId();
  if !IsDefined(svc) || !IsNameValid(pid) {
    return;
  }
  let before = CBGangStrength(sys, faction);
  let dealt = amount * sys.WornPerk().turfMult;
  let after = MaxF(CBConfig.GangStrengthFloor(), before - dealt);
  svc.NoteGangPower(pid, faction, after, CBGameSeconds(game));
  CBTurfNoteLocalLoss(sys, game, faction, dealt);
  // Said once, as they cross: the street notices a gang thinning out before the map does.
  if !CBMessagesOn() {
    return;
  }
  let label = CBFactionLabel(faction);
  if StrLen(label) == 0 {
    return;
  }
  let cap = StrUpper(StrMid(label, 0, 1)) + StrMid(label, 1, StrLen(label) - 1);
  if before >= CBConfig.GangBrokenStrength() && after < CBConfig.GangBrokenStrength() {
    CBHearsayFromStreet(game, s"\(cap) are broken. Half their corners are empty, and everybody knows who emptied them.", n"");
  } else {
    if before >= CBConfig.GangBleedingStrength() && after < CBConfig.GangBleedingStrength() {
      CBHearsayFromStreet(game, s"\(cap) are bleeding. Their corners have been thin since you started on them.", n"");
    }
  }
}

// What one of their people going down costs a gang. Somebody knocked out is out of the fight
// too, just not for good.
public func CBGangLossForKill(victimClass: Int32, lethal: Bool) -> Float {
  let loss = CBConfig.GangLossMember();
  if victimClass == EnumInt(ECBVictimClass.Officer) || victimClass == EnumInt(ECBVictimClass.Elite) {
    loss = CBConfig.GangLossOfficer();
  } else {
    if victimClass == EnumInt(ECBVictimClass.Boss) {
      loss = CBConfig.GangLossBoss();
    }
  }
  return lethal ? loss : loss * 0.5;
}

// Does this gang hold turf at all? Corps, the law and anybody without streets of their own are not
// part of the war over them.
public func CBGangHoldsTurf(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let content = sys.GetContent();
  if !IsDefined(content) {
    return false;
  }
  let prof = content.GetFaction(faction);
  return IsDefined(prof) && prof.isGang && ArraySize(prof.turf) > 0;
}

// ---- Control ----------------------------------------------------------------------------------

// A gang's own drift in one district on one day, 0..1. The same answer for everybody on the same
// day, so nothing about it has to be stored.
func CBTurfWobbleAt(day: Int32, district: Int32, gang: Int32) -> Float {
  return Cast<Float>(CBHashIndex(day * 131 + district * 17 + gang * 3, 29, 1000)) / 1000.0;
}

// The drift, eased from one day's into the next over the course of the day.
func CBTurfWobble(game: GameInstance, district: Int32, gang: Int32) -> Float {
  let day = CBGameDay(game);
  let t = ClampF(CBGameHourOfDay(game) / 24.0, 0.0, 1.0);
  let a = CBTurfWobbleAt(day, district, gang);
  let b = CBTurfWobbleAt(day + 1, district, gang);
  let w = a + (b - a) * t;
  return 1.0 + CBConfig.TurfDrift() * (w - 0.5) * 2.0;
}

// Who is fighting over this district, and how hard each of them pushes. `ids` and `weights` come
// back in step; shares are each weight over their sum.
public func CBTurfContenders(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName,
                             out ids: array<CName>, out weights: array<Float>) -> Void {
  ArrayClear(ids);
  ArrayClear(weights);
  if !IsDefined(sys) || Equals(district, n"") {
    return;
  }
  let content = sys.GetContent();
  if !IsDefined(content) {
    return;
  }
  let dIdx = CBDistrictIndex(district);
  // Somebody from outside holding it makes the home gangs the ones trying to get in.
  let held = n"";
  if CBTurfWarsOn() {
    let book = CBTurfBook.Get(game);
    if IsDefined(book) {
      held = book.Holder(dIdx);
    }
  }
  let heldProf = NotEquals(held, n"") ? content.GetFaction(held) : null;
  let def = content.GetDistrict(district);
  let sealed = IsDefined(def) && def.sealed;
  let invaded = !sealed && IsDefined(heldProf) && !ArrayContains(heldProf.turf, district);
  let factions = content.GetFactions();
  let weakestNative = 100.0;
  let natives: array<CName>;
  let i = 0;
  while i < ArraySize(factions) {
    let prof = factions[i];
    if IsDefined(prof) && prof.isGang {
      if ArrayContains(prof.turf, district) {
        let s = CBGangStrengthIn(sys, prof.id, district);
        ArrayPush(ids, prof.id);
        ArrayPush(weights, s * s * CBTurfWobble(game, dIdx, i) * (invaded ? CBConfig.TurfLostGroundMult() : 1.0));
        ArrayPush(natives, prof.id);
        weakestNative = MinF(weakestNative, s);
      } else {
        if invaded && Equals(prof.id, held) {
          let sh = CBGangStrengthIn(sys, prof.id, district);
          ArrayPush(ids, prof.id);
          ArrayPush(weights, sh * sh * CBTurfWobble(game, dIdx, i));
        }
      }
    }
    i += 1;
  }
  if ArraySize(natives) == 0 || !CBTurfWarsOn() || weakestNative >= CBConfig.TurfOpenStrength()
     || !IsDefined(def) || sealed {
    return;
  }
  let openness = 1.0 - weakestNative / CBConfig.TurfOpenStrength();
  let j = 0;
  while j < ArraySize(factions) {
    let g = factions[j];
    if IsDefined(g) && g.isGang && !ArrayContains(ids, g.id) && CBTurfNextDoor(g, def)
       && CBTurfAtWarWithAny(content, g.id, natives) {
      let sg = CBGangStrength(sys, g.id);
      if sg > weakestNative {
        ArrayPush(ids, g.id);
        ArrayPush(weights, sg * sg * CBConfig.TurfInvaderWeight() * openness * CBTurfWobble(game, dIdx, j));
      }
    }
    j += 1;
  }
}

func CBTurfNextDoor(g: ref<CBFactionProfile>, def: ref<CBDistrictDef>) -> Bool {
  for d in g.turf {
    if def.IsAdjacentTo(d) {
      return true;
    }
  }
  return false;
}

func CBTurfAtWarWithAny(content: ref<CyberbaneContent>, gang: CName, others: array<CName>) -> Bool {
  for o in others {
    if CBGangsAreRivals(content, gang, o) || CBGangsAreRivals(content, o, gang) {
      return true;
    }
  }
  return false;
}

// Shares of a district, in step with `ids`. Empty when no gang has streets there.
public func CBTurfShares(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName,
                         out ids: array<CName>, out shares: array<Float>) -> Void {
  let weights: array<Float>;
  CBTurfContenders(sys, game, district, ids, weights);
  ArrayClear(shares);
  let total = 0.0;
  for w in weights {
    total += w;
  }
  let k = 0;
  while k < ArraySize(weights) {
    ArrayPush(shares, total > 0.0 ? weights[k] / total : 1.0 / Cast<Float>(ArraySize(weights)));
    k += 1;
  }
}

// Who holds the district: the largest share. n"" when no gang has streets there.
public func CBTurfHolder(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName) -> CName {
  let book = CBTurfWarsOn() ? CBTurfBook.Get(game) : null;
  if IsDefined(book) {
    let written = book.Holder(CBDistrictIndex(district));
    if NotEquals(written, n"") {
      return written;
    }
  }
  let ids: array<CName>;
  let shares: array<Float>;
  CBTurfShares(sys, game, district, ids, shares);
  return CBTurfLeader(ids, shares);
}

func CBTurfLeader(ids: array<CName>, shares: array<Float>) -> CName {
  let best = n"";
  let bestShare = -1.0;
  let k = 0;
  while k < ArraySize(ids) {
    if shares[k] > bestShare {
      best = ids[k];
      bestShare = shares[k];
    }
    k += 1;
  }
  return best;
}

func CBTurfShareOf(ids: array<CName>, shares: array<Float>, gang: CName) -> Float {
  let k = 0;
  while k < ArraySize(ids) {
    if Equals(ids[k], gang) {
      return shares[k];
    }
    k += 1;
  }
  return 0.0;
}

// How strong a gang is on these particular streets. City-wide strength, less what V has done here.
public func CBGangStrengthIn(sys: ref<CyberbaneSystem>, faction: CName, district: CName) -> Float {
  let s = CBGangStrength(sys, faction);
  if !IsDefined(sys) || !CBTurfWarsOn() {
    return s;
  }
  let game = sys.GetGameInstance();
  let book = CBTurfBook.Get(game);
  if !IsDefined(book) {
    return s;
  }
  return MaxF(CBConfig.GangStrengthFloor(), s - book.LocalLoss(district, faction, CBGameSeconds(game)));
}

// Hurting a gang on its own streets hurts it there twice: once everywhere, once on that block.
func CBTurfNoteLocalLoss(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float) -> Void {
  let book = CBTurfBook.Get(game);
  let content = sys.GetContent();
  let here = CBEventDistrict(sys, game);
  let index = CBDistrictIndex(here);
  if !IsDefined(book) || !IsDefined(content) || index < 0 {
    return;
  }
  let prof = content.GetFaction(faction);
  if IsDefined(prof) && (ArrayContains(prof.turf, here) || Equals(book.Holder(index), faction)) {
    book.AddLocalLoss(here, faction, amount * CBConfig.TurfLocalShare(), CBGameSeconds(game));
  }
}

// Has this gang lost the district V is standing in?
public func CBTurfLostGround(sys: ref<CyberbaneSystem>, faction: CName) -> Bool {
  if !IsDefined(sys) || Equals(faction, n"") || !CBTurfWarsOn() {
    return false;
  }
  let book = CBTurfBook.Get(sys.GetGameInstance());
  let index = CBDistrictIndex(sys.GetCurrentDistrict());
  return IsDefined(book) && index >= 0 && Equals(book.From(index), faction)
      && NotEquals(book.Holder(index), faction);
}

// What the HUD says about the district V is in, or "" if nobody runs it.
public func CBTurfHudWord(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName) -> String {
  if !IsDefined(sys) || !CBTurfWarsOn() {
    return "";
  }
  let book = CBTurfBook.Get(game);
  let index = CBDistrictIndex(district);
  if !IsDefined(book) || index < 0 {
    return "";
  }
  if NotEquals(book.Challenger(index), n"") {
    return "CONTESTED - ";
  }
  let holder = CBBarFactionLabel(book.Holder(index));
  return StrLen(holder) > 0 ? "HELD BY " + holder + " - " : "";
}

public func CBTurfGangsIn(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName) -> array<CName> {
  let out: array<CName>;
  let ids: array<CName>;
  let shares: array<Float>;
  CBTurfShares(sys, game, district, ids, shares);
  let k = 0;
  while k < ArraySize(ids) {
    if shares[k] >= CBConfig.TurfPresenceShare() {
      ArrayPush(out, ids[k]);
    }
    k += 1;
  }
  return out;
}

// Work out who is on their own streets where V is standing, for every reader to share
// (CBTurfGangsHere). From the district sample on the fast tick, and after a district changes hands.
public func CBRefreshTurfHere(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let district = sys.GetCurrentDistrict();
  let gangs: array<CName>;
  if CBTurfWarsOn() && NotEquals(district, n"") {
    gangs = CBTurfGangsIn(sys, game, district);
  }
  sys.SetTurfHere(district, gangs);
}

// ---- Districts changing hands -------------------------------------------------------------------

// Slow tick: has any district changed hands? The first look of a session only learns who holds
// what, so loading a save never announces anything.
public func CBTurfTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || !sys.HasContent() || !CBTurfWarsOn() {
    return;
  }
  let book = CBTurfBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  let now = CBGameSeconds(game);
  let i = 0;
  while i < CBDistrictCount() {
    CBTurfTickDistrict(sys, game, book, i, now);
    i += 1;
  }
  CBRefreshTurfHere(sys, game);
}

// A district only changes hands when somebody has been clearly on top of the holder for a while, so
// a bad day or the daily drift cannot do it, and once it has happened it stays happened.
func CBTurfTickDistrict(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBTurfBook>, i: Int32, now: Float) -> Void {
  let district = CBDistrictAt(i);
  let ids: array<CName>;
  let shares: array<Float>;
  CBTurfShares(sys, game, district, ids, shares);
  if ArraySize(ids) == 0 {
    return;
  }
  let leader = CBTurfLeader(ids, shares);
  let held = book.Holder(i);
  if Equals(held, n"") {
    book.StartHolding(i, leader, now);
    return;
  }
  // Sealed since 1.7.8: a save that saw it taken before then gets it back at once, without a
  // story about a war that is not happening.
  let content = sys.GetContent();
  let def = IsDefined(content) ? content.GetDistrict(district) : null;
  let heldProf = IsDefined(content) ? content.GetFaction(held) : null;
  if IsDefined(def) && def.sealed && (!IsDefined(heldProf) || !ArrayContains(heldProf.turf, district)) {
    book.Restore(i, leader, now);
    return;
  }
  if Equals(leader, held)
     || CBTurfShareOf(ids, shares, leader) < CBTurfShareOf(ids, shares, held) * CBConfig.TurfFlipMargin() {
    book.ClearChallenge(i);
  } else {
    if NotEquals(book.Challenger(i), leader) {
      book.Challenge(i, leader, now);
    } else {
      if (now - book.ChallengeAt(i)) >= CBConfig.TurfFlipHours() * CBConfig.SecondsPerHour() {
        book.Flip(i, leader, held, now);
        CBTurfChangedHands(sys, game, district, leader, held);
        return;
      }
    }
  }
  CBTurfCounterattack(sys, game, book, i, district, now);
}

// The gang that lost a district does not forget it. Once it has rebuilt it comes back at the holder,
// a few days apart, and enough of that is how a district is won back with nobody's help. V can make
// that faster, or slower, by who V chooses to hurt.
func CBTurfCounterattack(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBTurfBook>, i: Int32,
                         district: CName, now: Float) -> Void {
  let old = book.From(i);
  let holder = book.Holder(i);
  if Equals(old, n"") || Equals(holder, n"") || Equals(old, holder) {
    return;
  }
  let gap = CBConfig.TurfPushGapDays() * CBConfig.SecondsPerDay();
  if (now - book.Since(i)) < gap || (book.PushAt(i) > 0.0 && (now - book.PushAt(i)) < gap) {
    return;
  }
  if CBGangStrength(sys, old) < CBConfig.TurfPushMinStrength() || RandF() >= CBConfig.TurfPushChance() {
    return;
  }
  book.SetPushAt(i, now);
  book.AddLocalLoss(district, holder, CBConfig.TurfPushDamage(), now);
  CBFileLog(sys, n"TurfPush", now, district, old, 0.0);
  CBLog.Info(n"Model", s"\(NameToString(old)) hit back at \(NameToString(holder)) in \(NameToString(district)).");
  let place = CBDistrictLabel(district);
  let o = CBFactionLabel(old);
  let h = CBFactionLabel(holder);
  if CBMessagesOn() && StrLen(place) > 0 && StrLen(o) > 0 && StrLen(h) > 0 {
    CBHearsayFromDistrict(game, district, s"\(CBCapFirst(o)) hit \(h) in \(place) last night. They want it back.", n"");
  }
}

func CBTurfChangedHands(sys: ref<CyberbaneSystem>, game: GameInstance, district: CName,
                        winner: CName, loser: CName) -> Void {
  let now = CBGameSeconds(game);
  CBFileLog(sys, n"TurfTaken", now, district, winner, 0.0);
  CBLog.Info(n"Model", s"\(NameToString(winner)) took \(NameToString(district)) from \(NameToString(loser)).");
  if !CBMessagesOn() {
    return;
  }
  let content = sys.GetContent();
  let place = CBDistrictLabel(district);
  let w = CBFactionLabel(winner);
  let l = CBFactionLabel(loser);
  if StrLen(place) == 0 || StrLen(w) == 0 || StrLen(l) == 0 || !IsDefined(content) {
    return;
  }
  let wCap = StrUpper(StrMid(w, 0, 1)) + StrMid(w, 1, StrLen(w) - 1);
  let prof = content.GetFaction(winner);
  let home = IsDefined(prof) && ArrayContains(prof.turf, district);
  if home {
    CBHearsayFromDistrict(game, district, s"\(wCap) have taken \(place) back from \(l).", n"");
    return;
  }
  // Moved in on somebody V broke. A gang that does not want V dead says thank you, in its own way;
  // otherwise the street says it.
  let score = sys.GetScore();
  let posture = IsDefined(score) ? score.GetPosture(winner) : ECBPosture.Neutral;
  if NotEquals(posture, ECBPosture.Hostile) && NotEquals(posture, ECBPosture.Vendetta) {
    let lCap = StrUpper(StrMid(l, 0, 1)) + StrMid(l, 1, StrLen(l) - 1);
    CBHearsayFromAlly(game, winner, s"\(place) is ours now. \(lCap) could not hold it after what you did to them. We remember who to thank.", n"");
  } else {
    CBHearsayFromDistrict(game, district, s"\(wCap) moved into \(place) the moment \(l) could not hold it. Everybody knows who broke them.", n"");
  }
}
