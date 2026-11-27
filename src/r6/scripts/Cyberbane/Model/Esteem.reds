// Cyberbane - What the street thinks of V
//
// Fear is half of a name. The other half is what people make of it: a merc who never touches the people on the street,
// puts down the ones who prey on them and leaves the beaten alive is somebody a block is glad to see coming. Esteem is
// kept district by district, where it was earned. It takes the edge off how the crowd reads V's danger there, and once
// it is high enough the people who know V greet V instead of backing away. Hurting them undoes it, fastest where it
// happened.

public class CBEsteemBook extends ScriptableSystem {
  private persistent let m_district: array<CName>;
  private persistent let m_value: array<Float>;     // 0..100
  private persistent let m_harmAt: array<Float>;    // game seconds of the last time V hurt somebody of the street there
  private persistent let m_lastHarm: Float;         // and anywhere
  // Session only: esteem where V stands, worked out once a tick for everybody the crowd code asks about.
  public let hereTick: Int32;
  public let hereValue: Float;

  public static func Get(game: GameInstance) -> ref<CBEsteemBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBEsteemBook") as CBEsteemBook : null;
  }

  private func IndexOf(district: CName, make: Bool) -> Int32 {
    let i = 0;
    while i < ArraySize(this.m_district) {
      if Equals(this.m_district[i], district) {
        return i;
      }
      i += 1;
    }
    if !make || !IsNameValid(district) {
      return -1;
    }
    ArrayPush(this.m_district, district);
    ArrayPush(this.m_value, 0.0);
    ArrayPush(this.m_harmAt, 0.0);
    return ArraySize(this.m_district) - 1;
  }

  public func Value(district: CName) -> Float {
    let i = this.IndexOf(district, false);
    return i >= 0 && i < ArraySize(this.m_value) ? this.m_value[i] : 0.0;
  }

  public func HarmAt(district: CName) -> Float {
    let i = this.IndexOf(district, false);
    return i >= 0 && i < ArraySize(this.m_harmAt) ? this.m_harmAt[i] : 0.0;
  }

  public func LastHarm() -> Float {
    return this.m_lastHarm;
  }

  public func Add(district: CName, delta: Float) -> Void {
    let i = this.IndexOf(district, delta > 0.0);
    if i >= 0 && i < ArraySize(this.m_value) {
      this.m_value[i] = ClampF(this.m_value[i] + delta, 0.0, 100.0);
    }
  }

  public func NoteHarm(district: CName, now: Float) -> Void {
    let i = this.IndexOf(district, true);
    if i >= 0 && i < ArraySize(this.m_harmAt) {
      this.m_harmAt[i] = now;
    }
    this.m_lastHarm = now;
  }

  // How many districts hold V at least this high.
  public func CountAtLeast(value: Float) -> Int32 {
    let n = 0;
    for v in this.m_value {
      if v >= value {
        n += 1;
      }
    }
    return n;
  }

  public func Best() -> Float {
    let best = 0.0;
    for v in this.m_value {
      best = MaxF(best, v);
    }
    return best;
  }

  public func Fade(amount: Float) -> Void {
    let i = 0;
    while i < ArraySize(this.m_value) {
      this.m_value[i] = MaxF(0.0, this.m_value[i] - amount);
      i += 1;
    }
  }

  public func Clear() -> Void {
    ArrayClear(this.m_district);
    ArrayClear(this.m_value);
    ArrayClear(this.m_harmAt);
    this.m_lastHarm = 0.0;
  }
}

public func CBEsteemOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().esteemCounts;
}

// How much V's Conduct lets the street think well of V at all: none at -40, all of it at +40, a quarter more above.
public func CBEsteemConductShare(sys: ref<CyberbaneSystem>) -> Float {
  return IsDefined(sys) ? ClampF((sys.GetCode() + 40.0) / 80.0, 0.0, 1.25) : 0.0;
}

// Hurt somebody of the street here within the last week: nothing V does here counts for anything yet.
public func CBEsteemSoured(game: GameInstance, district: CName) -> Bool {
  let book = CBEsteemBook.Get(game);
  if !IsDefined(book) {
    return false;
  }
  let at = book.HarmAt(district);
  return at > 0.0 && CBGameSeconds(game) - at < CBConfig.EsteemSourDays() * CBConfig.SecondsPerDay();
}

// Esteem won here, as far as V's Conduct lets it count.
public func CBEsteemEarn(sys: ref<CyberbaneSystem>, district: CName, amount: Float) -> Void {
  if !CBEsteemOn() || !IsDefined(sys) || amount <= 0.0 || !IsNameValid(district) || CBReputationFrozen() {
    return;
  }
  let game = sys.GetGameInstance();
  let book = CBEsteemBook.Get(game);
  if !IsDefined(book) || CBEsteemSoured(game, district) {
    return;
  }
  book.Add(district, amount * CBEsteemConductShare(sys) * sys.WornPerk().esteemMult);
}

// Somebody of the street hurt by V here: most of it lost here, a little everywhere the story reaches.
public func CBEsteemHarm(sys: ref<CyberbaneSystem>, district: CName, amount: Float) -> Void {
  if !CBEsteemOn() || !IsDefined(sys) || amount <= 0.0 || CBReputationFrozen() {
    return;
  }
  let game = sys.GetGameInstance();
  let book = CBEsteemBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  if IsNameValid(district) {
    book.Add(district, -amount);
    book.NoteHarm(district, CBGameSeconds(game));
  }
  book.Fade(amount * CBConfig.EsteemHarmCityShare());
}

// A kill or a takedown of V's, as the street around it sees it.
public func CBEsteemForKill(sys: ref<CyberbaneSystem>, info: ref<CBKillInfo>) -> Void {
  if !IsDefined(sys) || !IsDefined(info) || !info.instigatorIsPlayer {
    return;
  }
  let district = IsNameValid(info.district) ? info.district : sys.GetCurrentDistrict();
  let seen = info.witnessed ? 1.0 : CBConfig.EsteemUnseenShare();
  if info.victimClass == EnumInt(ECBVictimClass.Civilian) {
    CBEsteemHarm(sys, district, (info.lethal ? CBConfig.EsteemCivilianKilled() : CBConfig.EsteemCivilianHurt()) * MaxF(seen, 0.5));
    return;
  }
  // The ones who prey on the street, put down by somebody who does not: a gang V is not friends with, a cyberpsycho,
  // a Rival. Left breathing counts for more.
  let gain = 0.0;
  if info.victimClass == EnumInt(ECBVictimClass.Cyberpsycho) {
    gain = info.lethal ? CBConfig.EsteemPsychoKilled() : CBConfig.EsteemPsychoSaved();
  } else {
    if info.victimClass == EnumInt(ECBVictimClass.Ganger) || info.victimClass == EnumInt(ECBVictimClass.Elite)
       || info.victimClass == EnumInt(ECBVictimClass.Officer) || info.victimClass == EnumInt(ECBVictimClass.Boss)
       || info.victimClass == EnumInt(ECBVictimClass.Rival) {
      let score = sys.GetScore();
      let posture = IsDefined(score) && IsNameValid(info.faction) ? score.GetPosture(info.faction) : ECBPosture.Neutral;
      if !Equals(posture, ECBPosture.Allied) && !Equals(posture, ECBPosture.Friendly) {
        gain = CBConfig.EsteemPerThreat() * CBEsteemClassWeight(info.victimClass);
        if !info.lethal {
          gain *= CBConfig.EsteemMercyMult();
        }
      }
    }
  }
  CBEsteemEarn(sys, district, gain * seen);
}

func CBEsteemClassWeight(victimClass: Int32) -> Float {
  if victimClass == EnumInt(ECBVictimClass.Elite) { return 2.0; }
  if victimClass == EnumInt(ECBVictimClass.Officer) { return 3.0; }
  if victimClass == EnumInt(ECBVictimClass.Boss) { return 8.0; }
  if victimClass == EnumInt(ECBVictimClass.Rival) { return 6.0; }
  return 1.0;
}

// Esteem where V stands: what was earned in this district, and more where V lives (the neighbours know V) and on the
// streets V's crew keeps, never less than they start a neighbour on, while nothing has soured it.
public func CBEsteemHere(sys: ref<CyberbaneSystem>, game: GameInstance) -> Float {
  if !CBEsteemOn() || !IsDefined(sys) {
    return 0.0;
  }
  let book = CBEsteemBook.Get(game);
  if !IsDefined(book) {
    return 0.0;
  }
  let tick = sys.GetTickCount();
  if tick > 0 && book.hereTick == tick {
    return book.hereValue;
  }
  let district = sys.GetCurrentDistrict();
  let value = book.Value(district);
  if !CBEsteemSoured(game, district) && sys.GetCode() >= 0.0 {
    if CBOnHomeGround(game) {
      value = MaxF(value + CBConfig.EsteemHomeBonus(), CBConfig.EsteemHomeFloor());
    }
    if CBCrewHoldsHere(sys, game) {
      value = MaxF(value + CBConfig.EsteemCrewTurfBonus(), CBConfig.EsteemCrewTurfFloor());
    }
    value = MinF(value, 100.0);
  }
  book.hereTick = tick;
  book.hereValue = value;
  return value;
}

// How much of the crowd's fear of V is left once what they think of V is counted: in a fight, less of it.
public func CBEsteemCalmMult(sys: ref<CyberbaneSystem>, game: GameInstance) -> Float {
  let esteem = CBEsteemHere(sys, game);
  if esteem <= 0.0 {
    return 1.0;
  }
  let player = GetPlayer(game);
  let calm = IsDefined(player) && player.IsInCombat() ? CBConfig.EsteemCalmInFight() : CBConfig.EsteemCalm();
  return 1.0 - calm * esteem / 100.0;
}

// The crowd's fear of V as the street here feels it: the one sum the street and the Hub both use.
public func CBCrowdFearHere(sys: ref<CyberbaneSystem>, game: GameInstance, score: ref<CBScoreEngine>, intensity: Float) -> Float {
  return CBCrowdFear(score, intensity) * CBEsteemCalmMult(sys, game);
}

// Esteem as a word: what the people here make of V.
public func CBEsteemWord(esteem: Float) -> String {
  if esteem >= CBConfig.EsteemHero() { return CBT(n"Cyberbane-Esteem-TheirHero"); }
  if esteem >= CBConfig.EsteemGreet() { return CBT(n"Cyberbane-Esteem-AFriendOfTheBlock"); }
  if esteem >= CBConfig.EsteemKnown() { return CBT(n"Cyberbane-Esteem-OneOfTheGoodOnes"); }
  return CBT(n"Cyberbane-Esteem-NobodyInParticular");
}

// May the people here greet V? Liked enough, known by face, nothing in V's hands and no fight on.
public func CBEsteemGreets(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Bool {
  if !IsDefined(player) || player.IsInCombat() || IsDefined(GameObject.GetActiveWeapon(player))
     || VehicleComponent.IsMountedToVehicle(game, player.GetEntityID()) {
    return false;
  }
  let need = CBConfig.EsteemGreet() * sys.WornPerk().greetMult;
  if CBEsteemHere(sys, game) < need {
    return false;
  }
  let ds = sys.FindDistrict(sys.GetCurrentDistrict());
  return CBOnHomeGround(game) || (IsDefined(ds) && ds.renown >= CBConfig.EsteemKnownRenown());
}

// The day's fade, on the slow tick (Model/Decay.reds).
public func CBEsteemFade(game: GameInstance, days: Float) -> Void {
  let book = CBEsteemBook.Get(game);
  if IsDefined(book) && days > 0.0 {
    book.Fade(CBConfig.EsteemFadePerDay() * days);
  }
}

// ---- The greeting ---------------------------------------------------------------------------------------------------

// When this one last greeted V (Director tick), so nobody greets V twice in a few minutes.
@addField(ScriptedPuppet)
public let cbGreetedTick: Int32;

// A look over at V and a smile: the game's own friendly look (reactionComponent.script, TriggerFacialLookAtReaction:
// a look-at and the joy face, category 3 idle 5).
@addMethod(ReactionManagerComponent)
public func CBGreetV(target: ref<GameObject>) -> Bool {
  if this.m_desiredFearPhase > -1 || IsDefined(this.m_activeReaction)
     || NotEquals(this.m_crowdFearStage, gameFearStage.Relaxed) {
    return false;
  }
  if !this.ActivateReactionLookAt(target, true, true, 3.0) {
    return false;
  }
  let face = new AnimFeature_FacialReaction();
  face.category = 3;
  face.idle = 5;
  AnimationControllerComponent.ApplyFeatureToReplicate(this.GetOwner(), n"FacialReaction", face);
  this.ResetFacial(4.0);
  return true;
}

// One person near V greets V: the look and the smile, and now and then their own voice's greeting. True when it happened.
public func CBEsteemGreet(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>, player: ref<PlayerPuppet>,
                          dist: Float, tick: Int32) -> Bool {
  if !IsDefined(npc) || dist > CBConfig.EsteemGreetRadius() {
    return false;
  }
  if npc.cbGreetedTick > 0 && tick - npc.cbGreetedTick < CBConfig.EsteemGreetCooldownTicks() {
    return false;
  }
  if RandF() >= CBConfig.EsteemGreetChance() {
    return false;
  }
  let reactions = npc.GetStimReactionComponent();
  if !IsDefined(reactions) || !reactions.CBGreetV(player) {
    return false;
  }
  npc.cbGreetedTick = tick;
  CBVoice(sys, game, npc, n"greeting", n"CrowdGreet", CBConfig.EsteemGreetVoiceSeconds());
  return true;
}
