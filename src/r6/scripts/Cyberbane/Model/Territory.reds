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
  let after = MaxF(CBConfig.GangStrengthFloor(), before - amount);
  svc.NoteGangPower(pid, faction, after, CBGameSeconds(game));
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
    CBPhoneFromStreet(game, s"\(cap) are broken. Half their corners are empty, and everybody knows who emptied them.");
  } else {
    if before >= CBConfig.GangBleedingStrength() && after < CBConfig.GangBleedingStrength() {
      CBPhoneFromStreet(game, s"\(cap) are bleeding. Their corners have been thin since you started on them.");
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
  let factions = content.GetFactions();
  let weakestNative = 100.0;
  let natives: array<CName>;
  let i = 0;
  while i < ArraySize(factions) {
    let prof = factions[i];
    if IsDefined(prof) && prof.isGang && ArrayContains(prof.turf, district) {
      let s = CBGangStrength(sys, prof.id);
      ArrayPush(ids, prof.id);
      ArrayPush(weights, s * s * CBTurfWobble(game, dIdx, i));
      ArrayPush(natives, prof.id);
      weakestNative = MinF(weakestNative, s);
    }
    i += 1;
  }
  if ArraySize(natives) == 0 || !CBTurfWarsOn() || weakestNative >= CBConfig.TurfOpenStrength() {
    return;
  }
  // The owners are broken. Anybody at war with them whose own streets are next door moves in,
  // as long as they are the stronger side, and pushes harder the more broken the owners are.
  let def = content.GetDistrict(district);
  if !IsDefined(def) {
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

// Are this gang's own streets next door to that district?
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
  let ids: array<CName>;
  let shares: array<Float>;
  CBTurfShares(sys, game, district, ids, shares);
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

// The gangs on their own streets in this district: everybody holding a real share of it.
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
  if !IsDefined(sys) || !sys.HasContent() {
    return;
  }
  if !CBTurfWarsOn() {
    sys.ForgetTurfHolders();
    return;
  }
  let known = sys.TurfHoldersKnown();
  let i = 0;
  while i < CBDistrictCount() {
    let district = CBDistrictAt(i);
    let holder = CBTurfHolder(sys, game, district);
    let before = sys.GetTurfHolder(i);
    if known && NotEquals(holder, before) && NotEquals(holder, n"") && NotEquals(before, n"") {
      CBTurfChangedHands(sys, game, district, holder, before);
    }
    sys.SetTurfHolder(i, holder);
    i += 1;
  }
  sys.SetTurfHoldersKnown();
  CBRefreshTurfHere(sys, game);
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
    CBPhoneFromDistrict(game, district, s"\(wCap) have taken \(place) back from \(l).");
    return;
  }
  // Moved in on somebody V broke. A gang that does not want V dead says thank you, in its own way;
  // otherwise the street says it.
  let score = sys.GetScore();
  let posture = IsDefined(score) ? score.GetPosture(winner) : ECBPosture.Neutral;
  if NotEquals(posture, ECBPosture.Hostile) && NotEquals(posture, ECBPosture.Vendetta) {
    let lCap = StrUpper(StrMid(l, 0, 1)) + StrMid(l, 1, StrLen(l) - 1);
    CBPhoneFromAlly(game, winner, s"\(place) is ours now. \(lCap) could not hold it after what you did to them. We remember who to thank.");
  } else {
    CBPhoneFromDistrict(game, district, s"\(wCap) moved into \(place) the moment \(l) could not hold it. Everybody knows who broke them.");
  }
}
