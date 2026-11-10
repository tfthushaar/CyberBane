// Cyberbane - Who holds what, and how long they have held it
//
// Who a district belonged to used to be worked out fresh from how strong each gang was that day, so
// a gang that took a district lost it again the moment its enemy had rebuilt, and four equal gangs
// in Watson swapped places with the daily drift. A takeover has to be something that happened, so the
// result is written down here: who holds each district, who they took it from, who is trying to take
// it now, and how much damage each gang has taken on those particular streets.
//
// This is its own system on purpose. A new persistent field on CyberbaneSystem would change that
// class's saved shape and lose every player's progress; a new class changes nothing already saved,
// and simply starts empty on a save that has never had it.

public class CBTurfBook extends ScriptableSystem {
  // One entry per district, in CBDistrictAt order.
  private persistent let m_holders: array<CName>;
  private persistent let m_since: array<Float>;
  private persistent let m_from: array<CName>;          // n"" = has never changed hands
  private persistent let m_challengers: array<CName>;
  private persistent let m_challengeAt: array<Float>;
  private persistent let m_pushAt: array<Float>;        // the old gang's last try at taking it back
  // Damage on particular streets, one entry per district and gang that has taken any.
  private persistent let m_lossKeys: array<CName>;
  private persistent let m_lossValues: array<Float>;
  private persistent let m_lossAt: array<Float>;

  // The patrol out right now (Spawn/TurfPatrol.reds). It does not outlive the session, so neither do these.
  public let patrolDistrict: CName;
  public let patrolTick: Int32;
  public let patrolNext: Int32;

  public static func Get(game: GameInstance) -> ref<CBTurfBook> {
    // The systems container can be null during world transitions; never deref it then.
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBTurfBook") as CBTurfBook;
  }

  // Each list is padded on its own, and the three loss lists are kept the same length: every reader
  // indexes all of them by one position, so one that came back from a save shorter than the others
  // would be read past its end deep inside a tick (the rule behind CyberbaneSystem.Validate).
  private func Pad() -> Void {
    let want = CBDistrictCount();
    while ArraySize(this.m_holders) < want { ArrayPush(this.m_holders, n""); }
    while ArraySize(this.m_since) < want { ArrayPush(this.m_since, 0.0); }
    while ArraySize(this.m_from) < want { ArrayPush(this.m_from, n""); }
    while ArraySize(this.m_challengers) < want { ArrayPush(this.m_challengers, n""); }
    while ArraySize(this.m_challengeAt) < want { ArrayPush(this.m_challengeAt, 0.0); }
    while ArraySize(this.m_pushAt) < want { ArrayPush(this.m_pushAt, 0.0); }
    let losses = Min(ArraySize(this.m_lossKeys), Min(ArraySize(this.m_lossValues), ArraySize(this.m_lossAt)));
    if ArraySize(this.m_lossKeys) != losses { ArrayResize(this.m_lossKeys, losses); }
    if ArraySize(this.m_lossValues) != losses { ArrayResize(this.m_lossValues, losses); }
    if ArraySize(this.m_lossAt) != losses { ArrayResize(this.m_lossAt, losses); }
  }

  private func InRange(i: Int32) -> Bool {
    this.Pad();
    return i >= 0 && i < ArraySize(this.m_holders);
  }

  public func Holder(i: Int32) -> CName {
    return this.InRange(i) ? this.m_holders[i] : n"";
  }

  public func Since(i: Int32) -> Float {
    return this.InRange(i) ? this.m_since[i] : 0.0;
  }

  public func From(i: Int32) -> CName {
    return this.InRange(i) ? this.m_from[i] : n"";
  }

  public func Challenger(i: Int32) -> CName {
    return this.InRange(i) ? this.m_challengers[i] : n"";
  }

  public func ChallengeAt(i: Int32) -> Float {
    return this.InRange(i) ? this.m_challengeAt[i] : 0.0;
  }

  public func PushAt(i: Int32) -> Float {
    return this.InRange(i) ? this.m_pushAt[i] : 0.0;
  }

  public func SetPushAt(i: Int32, at: Float) -> Void {
    if this.InRange(i) {
      this.m_pushAt[i] = at;
    }
  }

  // The first time a district is looked at: whoever is on top there has always held it.
  public func StartHolding(i: Int32, gang: CName, at: Float) -> Void {
    if this.InRange(i) {
      this.m_holders[i] = gang;
      this.m_since[i] = at;
    }
  }

  public func Challenge(i: Int32, who: CName, at: Float) -> Void {
    if this.InRange(i) {
      this.m_challengers[i] = who;
      this.m_challengeAt[i] = at;
    }
  }

  public func ClearChallenge(i: Int32) -> Void {
    if this.InRange(i) {
      this.m_challengers[i] = n"";
      this.m_challengeAt[i] = 0.0;
    }
  }

  // As if it had never changed hands.
  public func Restore(i: Int32, gang: CName, at: Float) -> Void {
    if this.InRange(i) {
      this.m_holders[i] = gang;
      this.m_since[i] = at;
      this.m_from[i] = n"";
      this.m_challengers[i] = n"";
      this.m_challengeAt[i] = 0.0;
      this.m_pushAt[i] = 0.0;
    }
  }

  public func Flip(i: Int32, winner: CName, loser: CName, at: Float) -> Void {
    if this.InRange(i) {
      this.m_holders[i] = winner;
      this.m_since[i] = at;
      this.m_from[i] = loser;
      this.m_challengers[i] = n"";
      this.m_challengeAt[i] = 0.0;
      this.m_pushAt[i] = 0.0;
    }
  }

  private func LossKey(district: CName, faction: CName) -> CName {
    return StringToName(NameToString(district) + "|" + NameToString(faction));
  }

  private func LossNow(k: Int32, now: Float) -> Float {
    let days = MaxF(0.0, now - this.m_lossAt[k]) / CBConfig.SecondsPerDay();
    return MaxF(0.0, this.m_lossValues[k] - days * CBConfig.TurfLocalRecoverPerDay());
  }

  public func LocalLoss(district: CName, faction: CName, now: Float) -> Float {
    this.Pad();
    let key = this.LossKey(district, faction);
    let k = 0;
    while k < ArraySize(this.m_lossKeys) {
      if Equals(this.m_lossKeys[k], key) {
        return this.LossNow(k, now);
      }
      k += 1;
    }
    return 0.0;
  }

  public func AddLocalLoss(district: CName, faction: CName, amount: Float, now: Float) -> Void {
    this.Pad();
    let key = this.LossKey(district, faction);
    let k = 0;
    while k < ArraySize(this.m_lossKeys) {
      if Equals(this.m_lossKeys[k], key) {
        this.m_lossValues[k] = MinF(100.0, this.LossNow(k, now) + amount);
        this.m_lossAt[k] = now;
        return;
      }
      k += 1;
    }
    ArrayPush(this.m_lossKeys, key);
    ArrayPush(this.m_lossValues, MinF(100.0, amount));
    ArrayPush(this.m_lossAt, now);
  }

  // Starting over: the new playthrough's map is learnt afresh.
  public func Clear() -> Void {
    ArrayClear(this.m_holders);
    ArrayClear(this.m_since);
    ArrayClear(this.m_from);
    ArrayClear(this.m_challengers);
    ArrayClear(this.m_challengeAt);
    ArrayClear(this.m_pushAt);
    ArrayClear(this.m_lossKeys);
    ArrayClear(this.m_lossValues);
    ArrayClear(this.m_lossAt);
  }
}
