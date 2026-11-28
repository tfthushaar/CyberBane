// Cyberbane - extension API level 5
//
// For add-ons: a question taken back before it is answered, factions kept off the Gangs list, a bodyguard who walks with
// V, people posted at a place, and lines of their own in street talk. The statics are on CyberbaneAPI; guard each call
// with `@if(ModuleExists("Cyberbane.Api5"))`. Everything here lasts the session: ask again on OnSettled, as listeners and
// cards are registered.

// An add-on's line in street talk (AddTalkTopic). Both are asked while the conversation is on screen: words only here,
// and anything that changes the world is noted and started on the add-on's own tick.
public abstract class CBTalkTopicListener extends IScriptable {
  // Whether the line shows for this person now. `speaker` is their entity, for the add-on to match with GroupBodies.
  public func TopicShown(game: GameInstance, faction: CName, token: Int32, speaker: EntityID) -> Bool { return true; }
  // V said it: what they say back (shown as written; "" for a shrug).
  public func OnTopic(game: GameInstance, faction: CName, token: Int32, speaker: EntityID) -> String { return ""; }
}

public func CBTalkActApiBase() -> Int32 = 900
public func CBApiTopicMax() -> Int32 = 32

public class CBApiLevel5 extends ScriptableSystem {
  private let m_unlisted: array<CName>;
  // Bodyguards: the group, whether they leave once the fight is over, whether a fight has started since they came, how
  // long it has been quiet, how long V has been out of reach, and whether they are on their way out.
  private let m_escorts: array<Int32>;
  private let m_escortFight: array<Bool>;
  private let m_escortFought: array<Bool>;
  private let m_escortQuiet: array<Int32>;
  private let m_escortFar: array<Int32>;
  private let m_escortLeaving: array<Bool>;
  private let m_posts: array<Int32>;
  private let m_topicFaction: array<CName>;
  private let m_topicLine: array<CName>;
  private let m_topicToken: array<Int32>;
  private let m_topicListener: array<ref<CBTalkTopicListener>>;

  public static func Get(game: GameInstance) -> ref<CBApiLevel5> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiLevel5") as CBApiLevel5 : null;
  }

  // ---- The Gangs list
  public func SetListed(id: CName, listed: Bool) -> Void {
    if listed {
      ArrayRemove(this.m_unlisted, id);
      return;
    }
    if !ArrayContains(this.m_unlisted, id) {
      ArrayPush(this.m_unlisted, id);
    }
  }

  public func Listed(id: CName) -> Bool {
    return !ArrayContains(this.m_unlisted, id);
  }

  // ---- Bodyguards
  private func EscortRows() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_escorts), ArraySize(this.m_escortFight)), Min(ArraySize(this.m_escortFought), ArraySize(this.m_escortQuiet))),
               Min(ArraySize(this.m_escortFar), ArraySize(this.m_escortLeaving)));
  }

  public func AddEscort(handle: Int32, untilFightEnds: Bool) -> Void {
    ArrayPush(this.m_escorts, handle);
    ArrayPush(this.m_escortFight, untilFightEnds);
    ArrayPush(this.m_escortFought, false);
    ArrayPush(this.m_escortQuiet, 0);
    ArrayPush(this.m_escortFar, 0);
    ArrayPush(this.m_escortLeaving, false);
  }

  public func IsEscort(handle: Int32) -> Bool {
    return handle > 0 && ArrayContains(this.m_escorts, handle);
  }

  public func EscortCount() -> Int32 {
    return this.EscortRows();
  }

  public func EscortAt(i: Int32) -> Int32 { return this.m_escorts[i]; }
  public func EscortUntilFight(i: Int32) -> Bool { return this.m_escortFight[i]; }
  public func EscortFought(i: Int32) -> Bool { return this.m_escortFought[i]; }
  public func SetEscortFought(i: Int32, v: Bool) -> Void { this.m_escortFought[i] = v; }
  public func EscortQuiet(i: Int32) -> Int32 { return this.m_escortQuiet[i]; }
  public func SetEscortQuiet(i: Int32, v: Int32) -> Void { this.m_escortQuiet[i] = v; }
  public func EscortFar(i: Int32) -> Int32 { return this.m_escortFar[i]; }
  public func SetEscortFar(i: Int32, v: Int32) -> Void { this.m_escortFar[i] = v; }
  public func EscortLeaving(i: Int32) -> Bool { return this.m_escortLeaving[i]; }
  public func SetEscortLeaving(i: Int32, v: Bool) -> Void { this.m_escortLeaving[i] = v; }

  public func EscortIndex(handle: Int32) -> Int32 {
    let i = 0;
    while i < this.EscortRows() {
      if this.m_escorts[i] == handle {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func DropEscortAt(i: Int32) -> Void {
    if i < ArraySize(this.m_escorts) { ArrayErase(this.m_escorts, i); }
    if i < ArraySize(this.m_escortFight) { ArrayErase(this.m_escortFight, i); }
    if i < ArraySize(this.m_escortFought) { ArrayErase(this.m_escortFought, i); }
    if i < ArraySize(this.m_escortQuiet) { ArrayErase(this.m_escortQuiet, i); }
    if i < ArraySize(this.m_escortFar) { ArrayErase(this.m_escortFar, i); }
    if i < ArraySize(this.m_escortLeaving) { ArrayErase(this.m_escortLeaving, i); }
  }

  // ---- Posts
  public func AddPost(handle: Int32) -> Void {
    if !ArrayContains(this.m_posts, handle) {
      ArrayPush(this.m_posts, handle);
    }
  }

  public func IsPost(handle: Int32) -> Bool {
    return handle > 0 && ArrayContains(this.m_posts, handle);
  }

  public func DropPost(handle: Int32) -> Void {
    ArrayRemove(this.m_posts, handle);
  }

  // Start over: the bodyguards and posts go with everything else of Cyberbane's in the world. What add-ons registered
  // (topics, the Gangs list) stays for the session.
  public func ForgetPeople() -> Void {
    ArrayClear(this.m_escorts);
    ArrayClear(this.m_escortFight);
    ArrayClear(this.m_escortFought);
    ArrayClear(this.m_escortQuiet);
    ArrayClear(this.m_escortFar);
    ArrayClear(this.m_escortLeaving);
    ArrayClear(this.m_posts);
  }

  // ---- Talk topics
  public func TopicCount() -> Int32 {
    return Min(Min(ArraySize(this.m_topicFaction), ArraySize(this.m_topicLine)), Min(ArraySize(this.m_topicToken), ArraySize(this.m_topicListener)));
  }

  public func TopicFaction(i: Int32) -> CName { return this.m_topicFaction[i]; }
  public func TopicLine(i: Int32) -> CName { return this.m_topicLine[i]; }
  public func TopicToken(i: Int32) -> Int32 { return this.m_topicToken[i]; }
  public func TopicListener(i: Int32) -> ref<CBTalkTopicListener> { return this.m_topicListener[i]; }

  // A topic's place in the list is its talk act (CBTalkActApiBase + place), so a place never moves while its topic lives:
  // a removed topic leaves its place empty (no listener) and a new one fills the first empty place.
  private func TopicIndex(faction: CName, token: Int32, listener: ref<CBTalkTopicListener>) -> Int32 {
    let i = 0;
    while i < this.TopicCount() {
      if IsDefined(this.m_topicListener[i]) && Equals(this.m_topicFaction[i], faction) && this.m_topicToken[i] == token
         && this.m_topicListener[i] == listener {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  // Asked again with the same faction, token and listener, the line is replaced, not added twice.
  public func AddTopic(faction: CName, lineKey: CName, token: Int32, listener: ref<CBTalkTopicListener>) -> Bool {
    let i = this.TopicIndex(faction, token, listener);
    if i >= 0 {
      this.m_topicLine[i] = lineKey;
      return true;
    }
    i = 0;
    while i < this.TopicCount() {
      if !IsDefined(this.m_topicListener[i]) {
        this.m_topicFaction[i] = faction;
        this.m_topicLine[i] = lineKey;
        this.m_topicToken[i] = token;
        this.m_topicListener[i] = listener;
        return true;
      }
      i += 1;
    }
    if this.TopicCount() >= CBApiTopicMax() {
      return false;
    }
    ArrayPush(this.m_topicFaction, faction);
    ArrayPush(this.m_topicLine, lineKey);
    ArrayPush(this.m_topicToken, token);
    ArrayPush(this.m_topicListener, listener);
    return true;
  }

  public func RemoveTopic(faction: CName, token: Int32, listener: ref<CBTalkTopicListener>) -> Bool {
    let i = this.TopicIndex(faction, token, listener);
    if i < 0 {
      return false;
    }
    this.m_topicFaction[i] = n"";
    this.m_topicLine[i] = n"";
    this.m_topicToken[i] = 0;
    this.m_topicListener[i] = null;
    return true;
  }
}

// ---- A question taken back (R15) ---------------------------------------------------------------------------------------
// Forgets the add-on's open question in that contact's thread, so its answers neither show nor cost anything. False when
// no question with that token is waiting there.
public func CBApiWithdrawAsk(game: GameInstance, sender: CName, token: Int32) -> Bool {
  let asks = CBApiAsks.Get(game);
  let name = CBApiSenderName(game, sender);
  if !IsDefined(asks) || StrLen(name) == 0 || !asks.Pending(name) || asks.Token(name) != token {
    return false;
  }
  asks.Forget(name);
  return true;
}

// ---- Off the Gangs list (R16) -------------------------------------------------------------------------------------------
// Standing and History stay Cyberbane's; only the row goes.
public func CBApiSetFactionListed(game: GameInstance, id: CName, listed: Bool) -> Void {
  let book = CBApiLevel5.Get(game);
  if IsDefined(book) && IsNameValid(id) {
    book.SetListed(id, listed);
  }
}

public func CBApiFactionListed(game: GameInstance, id: CName) -> Bool {
  let book = CBApiLevel5.Get(game);
  return !IsDefined(book) || book.Listed(id);
}

// ---- A bodyguard (L3-14) ------------------------------------------------------------------------------------------------
// One person of the record, on V's side and following V, placed out of V's sight like V's crew. With untilFightEnds they
// leave once a fight has come and gone; either way they leave when V goes too far, the story or a safe place takes V, or V
// shoots them, and on ReleaseEscort. The group's handle, or 0 (LastRequestWhy says why).
public func CBApiRequestEscort(game: GameInstance, record: TweakDBID, untilFightEnds: Bool) -> Int32 {
  let book = CBApiLevel5.Get(game);
  let reg = CBApiRequests.Get(game);
  if !IsDefined(book) || !IsDefined(reg) {
    return 0;
  }
  if book.EscortCount() >= CBConfig.ApiEscortMax() {
    reg.SetWhy("as many bodyguards as Cyberbane allows are already with V");
    return 0;
  }
  let spec = new CBSpawnSpec();
  ArrayPush(spec.records, record);
  spec.count = 1;
  spec.place = CBApiPlaceNearV();
  spec.onVsSide = true;
  spec.grade = CBApiGradeCrew();
  let handle = CBApiRequestGroup(game, spec);
  if handle > 0 {
    book.AddEscort(handle, untilFightEnds);
    CBLog.Info(n"Spawn", s"An add-on's bodyguard is on the way (handle \(handle)).");
  }
  return handle;
}

public func CBApiEscortActive(game: GameInstance, handle: Int32) -> Bool {
  let book = CBApiLevel5.Get(game);
  if !IsDefined(book) {
    return false;
  }
  let i = book.EscortIndex(handle);
  return i >= 0 && !book.EscortLeaving(i);
}

public func CBApiReleaseEscort(game: GameInstance, handle: Int32) -> Bool {
  let book = CBApiLevel5.Get(game);
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(book) || !IsDefined(sys) {
    return false;
  }
  let i = book.EscortIndex(handle);
  if i < 0 {
    return false;
  }
  CBApiEscortLeave(sys, game, book, i);
  return true;
}

// Set up on V's side (CBApiSetUpBody): kitted like a borrowed crew's people, and following V.
public func CBApiSetUpEscort(game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !CBStillStanding(puppet) {
    return;
  }
  CBKitSquadMember(puppet);
  CBMakeFollower(puppet, player);
  // A seat of their own in V's car, as V's crew get (Reactions/CrewCar.reds, CBRidesWithV).
  let des = GameInstance.GetDynamicEntitySystem();
  if IsDefined(des) {
    des.AssignTag(puppet.GetEntityID(), n"CB_Guardian");
  }
}

// They stop following and walk off, the one order they get; gone once V cannot see them (CBApiEscortTick).
func CBApiEscortLeave(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBApiLevel5>, i: Int32) -> Void {
  if book.EscortLeaving(i) {
    return;
  }
  book.SetEscortLeaving(i, true);
  let bodies: array<EntityID>;
  CBApiGroupBodies(game, book.EscortAt(i), bodies);
  for id in bodies {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      CBEndFollower(p);
      CBOrderFlee(game, p, true);
    }
  }
  CBLog.Info(n"Spawn", s"An add-on's bodyguard is leaving (handle \(book.EscortAt(i))).");
}

public func CBApiEscortTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBApiLevel5.Get(game);
  let reg = CBApiRequests.Get(game);
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(book) || !IsDefined(reg) || !IsDefined(player) || !IsDefined(des) || !CBWorldStable(game) {
    return;
  }
  let ppos = player.GetWorldPosition();
  let fighting = player.IsInCombat();
  let i = book.EscortCount() - 1;
  while i >= 0 {
    let handle = book.EscortAt(i);
    let tag = CBApiGroupTag(handle);
    if book.EscortLeaving(i) {
      CBDeleteTaggedSafe(game, tag, true, true);
      let left = des.GetTaggedIDs(tag);
      if ArraySize(left) == 0 {
        reg.Drop(handle);
        book.DropEscortAt(i);
      }
    } else {
      let up = 0;
      let near = false;
      let shot = false;
      let coming = false;
      let ids = des.GetTaggedIDs(tag);
      for id in ids {
        let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
        if des.IsSpawning(id) {
          coming = true;
        } else {
          if CBNpcSafe(sys, p) && CBStillStanding(p) {
            up += 1;
            if p.cbDamagedByPlayer {
              shot = true;
            }
            if Vector4.Distance(p.GetWorldPosition(), ppos) <= CBConfig.ApiEscortLostDistance() {
              near = true;
            }
          }
        }
      }
      if fighting {
        book.SetEscortFought(i, true);
        book.SetEscortQuiet(i, 0);
      } else {
        book.SetEscortQuiet(i, book.EscortQuiet(i) + 1);
      }
      book.SetEscortFar(i, near || coming ? 0 : book.EscortFar(i) + 1);
      let leave = shot || CBCrewHeldReason(sys, game) > 0 || book.EscortFar(i) >= CBConfig.ApiEscortLostTicks()
                  || (book.EscortUntilFight(i) && book.EscortFought(i) && book.EscortQuiet(i) >= CBConfig.ApiEscortQuietTicks());
      if up == 0 && !coming {
        // Nobody of theirs standing: down or never placed; the group goes the way any of ours does.
        reg.Drop(handle);
        book.DropEscortAt(i);
      } else {
        if leave {
          CBApiEscortLeave(sys, game, book, i);
        }
      }
    }
    i -= 1;
  }
}

// ---- Posts (L3-9) ------------------------------------------------------------------------------------------------------
// People standing at a place: placed around it the way a gang's hangout is, neutral to V until V hurts one of them (then
// the whole post turns, as a neutral group does), and talked to like anybody on the street. They stay until ReleasePost,
// or until the world streams them out. The group's handle, or 0 (LastRequestWhy says why).
public func CBApiRequestPost(game: GameInstance, faction: CName, at: Vector4, count: Int32, records: array<TweakDBID>) -> Int32 {
  let book = CBApiLevel5.Get(game);
  if !IsDefined(book) {
    return 0;
  }
  let spec = new CBSpawnSpec();
  spec.faction = faction;
  spec.records = records;
  spec.count = Min(Max(count, 1), CBConfig.ApiPostMaxPeople());
  spec.place = CBApiPlaceAt();
  spec.at = at;
  spec.neutralToV = true;
  spec.grade = CBApiGradeCrew();
  let handle = CBApiRequestGroup(game, spec);
  if handle > 0 {
    book.AddPost(handle);
  }
  return handle;
}

public func CBApiReleasePost(game: GameInstance, handle: Int32) -> Void {
  let book = CBApiLevel5.Get(game);
  if IsDefined(book) {
    book.DropPost(handle);
  }
  CBApiReleaseGroup(game, handle);
}

public func CBApiIsPost(game: GameInstance, handle: Int32) -> Bool {
  let book = CBApiLevel5.Get(game);
  return IsDefined(book) && book.IsPost(handle);
}

public func CBApiIsEscort(game: GameInstance, handle: Int32) -> Bool {
  let book = CBApiLevel5.Get(game);
  return IsDefined(book) && book.IsEscort(handle);
}

// ---- Talk topics (L3-12) -----------------------------------------------------------------------------------------------
// A line of the add-on's in street talk with that faction's people (n"" for anybody). The line's words are the key's text.
public func CBApiAddTalkTopic(game: GameInstance, faction: CName, lineKey: CName, token: Int32, listener: ref<CBTalkTopicListener>) -> Bool {
  let book = CBApiLevel5.Get(game);
  return IsDefined(book) && IsDefined(listener) && IsNameValid(lineKey) && book.AddTopic(faction, lineKey, token, listener);
}

public func CBApiRemoveTalkTopic(game: GameInstance, faction: CName, token: Int32, listener: ref<CBTalkTopicListener>) -> Bool {
  let book = CBApiLevel5.Get(game);
  return IsDefined(book) && book.RemoveTopic(faction, token, listener);
}

// The add-ons' lines for this person (Reactions/StreetTalk.reds, CBTalkChoices).
public func CBApiTalkLines(game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let book = CBApiLevel5.Get(game);
  if !IsDefined(book) || !IsDefined(t) || t.cop {
    return out;
  }
  let i = 0;
  while i < book.TopicCount() {
    let f = book.TopicFaction(i);
    let l = book.TopicListener(i);
    if (!IsNameValid(f) || Equals(f, t.faction)) && IsDefined(l) && l.TopicShown(game, t.faction, book.TopicToken(i), t.id) {
      ArrayPush(out, CBTalkMakeLine(CBT(book.TopicLine(i)), CBTalkActApiBase() + i, t"ChoiceCaptionParts.TalkIcon"));
    }
    i += 1;
  }
  return out;
}

public func CBApiTalkActIs(act: Int32) -> Bool {
  return act >= CBTalkActApiBase() && act < CBTalkActApiBase() + CBApiTopicMax();
}

// V said one of them: the add-on answers. A topic removed while the talk was on screen, or its place taken by another
// faction's since, gets a shrug.
public func CBApiTalkAnswer(game: GameInstance, t: ref<CBTalkTarget>, act: Int32) -> ref<CBTalkAnswer> {
  let book = CBApiLevel5.Get(game);
  let i = act - CBTalkActApiBase();
  let said = "";
  if IsDefined(book) && i >= 0 && i < book.TopicCount() && IsDefined(book.TopicListener(i))
     && (!IsNameValid(book.TopicFaction(i)) || Equals(book.TopicFaction(i), t.faction)) {
    said = book.TopicListener(i).OnTopic(game, t.faction, book.TopicToken(i), t.id);
  }
  return CBTalkSay(StrLen(said) > 0 ? said : CBT(n"Cyberbane-Api-TopicShrug"), n"");
}
