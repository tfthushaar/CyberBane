// Cyberbane - Holding fire while V talks
//
// While V talks to one of a gang, their people nearby hold their fire, and the warning countdown on restricted ground
// pauses.

public func CBTruceTalk() -> Int32 = 1
public func CBTruceFacedown() -> Int32 = 2
// A crew's sergeant stopping to talk before anybody fires (Reactions/Allies.reds, the sergeant's parley): his whole crew holds.
public func CBTruceParley() -> Int32 = 4

// Held by the truce: neutral to V because of it, to be made hostile again when it ends.
@addField(ScriptedPuppet)
public let cbTruceHeld: Bool;
// Their warning meter held by the truce, to be set filling again when it ends.
@addField(ScriptedPuppet)
public let cbTruceMeter: Bool;

public class CBTalkTruce {
  private let m_owners: Int32;
  private let m_talkFaction: CName;
  private let m_talkPartner: EntityID;
  private let m_fdFaction: CName;
  private let m_fdBody: EntityID;
  private let m_parleyFaction: CName;
  private let m_parleyBody: EntityID;
  private let m_held: array<wref<ScriptedPuppet>>;
  private let m_broken: Bool;
  private let m_sweepIn: Int32;
  private let m_logged: Int32;

  public func Active() -> Bool {
    return this.m_owners != 0;
  }

  // Somebody holding was hurt by V: the hold is off for everybody (a facedown takes it as the fight starting).
  public func Broken() -> Bool {
    return this.m_broken;
  }

  public func Begin(sys: ref<CyberbaneSystem>, game: GameInstance, owner: Int32, faction: CName, partner: ref<ScriptedPuppet>) -> Void {
    if !IsDefined(sys) || Equals(faction, n"") || CBTruceNeverHolds(faction) || !IsDefined(partner) {
      return;
    }
    if owner == CBTruceTalk() {
      this.m_talkFaction = faction;
      this.m_talkPartner = partner.GetEntityID();
    } else {
      if owner == CBTruceFacedown() {
        this.m_fdFaction = faction;
        this.m_fdBody = partner.GetEntityID();
      } else {
        this.m_parleyFaction = faction;
        this.m_parleyBody = partner.GetEntityID();
      }
    }
    if this.m_owners == 0 {
      this.m_broken = false;
      this.m_logged = 0;
    }
    this.m_owners = this.m_owners | owner;
    this.m_sweepIn = 0;
    this.Sweep(sys, game);
  }

  // On talk's tick. Every other one (0.4 s): the people walking up mid-conversation are held as they come.
  public func Tick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if this.m_owners == 0 {
      return;
    }
    // Never past its owners: a conversation that ended without saying so, a facedown its book reset.
    if (this.m_owners & CBTruceTalk()) != 0 {
      let talk = sys.GetStreetTalk();
      if !IsDefined(talk) || !talk.InConversation() {
        this.End(sys, game, CBTruceTalk());
      }
    }
    if (this.m_owners & CBTruceFacedown()) != 0 {
      let book = CBRivalBook.Get(game);
      if !IsDefined(book) || book.fdState == 0 {
        this.End(sys, game, CBTruceFacedown());
      }
    }
    if (this.m_owners & CBTruceParley()) != 0 {
      let war = CBWarBook.Get(game);
      if !IsDefined(war) || !war.parleyOpen {
        this.End(sys, game, CBTruceParley());
      }
    }
    if this.m_owners == 0 {
      return;
    }
    this.m_sweepIn -= 1;
    if this.m_sweepIn > 0 {
      return;
    }
    this.m_sweepIn = 2;
    this.Sweep(sys, game);
  }

  private func Sweep(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(player) || !CBWorldStable(game) {
      return;
    }
    // Broken: V hurt one of them. Everybody goes back to how they were, and a facedown hears of it (Broken).
    for held in this.m_held {
      if IsDefined(held) && held.cbDamagedByPlayer {
        this.m_broken = true;
      }
    }
    if this.m_broken {
      CBLog.Info(n"Talk", "You hurt one of the people holding their fire while you talked: the hold is off.");
      this.Release(sys, game);
      return;
    }
    let des = GameInstance.GetDynamicEntitySystem();
    let ppos = player.GetWorldPosition();
    let reg = sys.GetRegistry();
    if IsDefined(reg) {
      for p in reg.GetAll() {
        this.Consider(sys, game, player, des, ppos, p);
      }
    }
    // Cyberbane's own people of that gang, who a full registry can miss: a Rival's bodyguards above all.
    if IsDefined(des) {
      let tags: array<CName> = [n"CB_Escort", n"CB_Lair", n"CB_Rival", n"CB_Squad", n"CB_Apex"];
      for tag in tags {
        for id in des.GetTaggedIDs(tag) {
          this.Consider(sys, game, player, des, ppos, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
        }
      }
    }
  }

  private func Consider(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, des: ref<DynamicEntitySystem>,
                        ppos: Vector4, p: wref<ScriptedPuppet>) -> Void {
    // Our own fields first, then the per-NPC gate before anything native is read.
    if !IsDefined(p) || p.cbFacedownHeld || p.cbSurrendered || p.cbGaveUp || p.cbMercyOpen || p.cbMoraleBroken
       || p.cbDamagedByPlayer || !CBNpcSafe(sys, p) || p.IsPlayer() || p.IsDead() || !CBStillStanding(p) {
      return;
    }
    let id = p.GetEntityID();
    // The Rival is the facedown's to hold. The person V is talking to keeps their own attitude, which is the conversation's,
    // but their warning holds too: on restricted ground they are often the one giving it.
    if Equals(id, this.m_fdBody) || Equals(id, this.m_parleyBody) {
      return;
    }
    let isPartner = Equals(id, this.m_talkPartner);
    if Vector4.Distance(ppos, p.GetWorldPosition()) > CBConfig.TruceRadius() || p.IsCrowd() {
      return;
    }
    let faction = CBClassifyFaction(p);
    if Equals(faction, n"") || CBTruceNeverHolds(faction) {
      return;
    }
    let forTalk = (this.m_owners & CBTruceTalk()) != 0 && Equals(faction, this.m_talkFaction);
    let forFacedown = (this.m_owners & CBTruceFacedown()) != 0 && Equals(faction, this.m_fdFaction);
    let forParley = (this.m_owners & CBTruceParley()) != 0 && Equals(faction, this.m_parleyFaction);
    if !forTalk && !forFacedown && !forParley {
      return;
    }
    // A street conversation does not stop a crew sent after V; a Rival's facedown holds the Rival's own, and a sergeant's
    // parley his crew.
    if !forFacedown && !forParley && !isPartner && CBSentAfterV(des, p) {
      return;
    }
    if !CBSafetyGate.CanTalkTo(p) {
      return;
    }
    let touched = false;
    // The warning on restricted ground, stopped where it is while V talks. Set again each sweep: the game's guard starts it
    // filling again each time it warns.
    let pools = GameInstance.GetStatPoolsSystem(game);
    if IsDefined(pools) && pools.IsStatPoolAdded(Cast<StatsObjectID>(id), gamedataStatPoolType.ReprimandEscalation) {
      CBTruceStopMeter(pools, Cast<StatsObjectID>(id));
      if !p.cbTruceMeter {
        p.cbTruceMeter = true;
        touched = true;
      }
    }
    // Hostile to V and not fighting yet: they hold.
    if !isPartner && !p.cbTruceHeld && !CBNpcInCombat(p) {
      let agent = p.GetAttitudeAgent();
      let pagent = player.GetAttitudeAgent();
      if IsDefined(agent) && IsDefined(pagent) && Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
        CBTrace("attitude: holding fire while V talks to one of theirs");
        agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
        let senses = p.GetSensesComponent();
        if IsDefined(senses) {
          senses.ResetDetection(player.GetEntityID());
        }
        CBCalmTowardCompanions(sys, p);
        p.cbTruceHeld = true;
        touched = true;
      }
    }
    if touched && !ArrayContains(this.m_held, p) {
      ArrayPush(this.m_held, p);
      this.m_logged += 1;
      if this.m_logged == 1 || this.m_logged == 5 {
        CBLog.Info(n"Talk", s"Holding while you talk: \(this.m_logged) of the \(NameToString(faction)) nearby.");
      }
    }
  }

  // An owner is done. With none left, everybody held goes back to how they were.
  public func End(sys: ref<CyberbaneSystem>, game: GameInstance, owner: Int32) -> Void {
    if (this.m_owners & owner) == 0 {
      return;
    }
    this.m_owners = this.m_owners - owner;
    if owner == CBTruceTalk() {
      this.m_talkFaction = n"";
      this.m_talkPartner = CBNoEntity();
    } else {
      if owner == CBTruceFacedown() {
        this.m_fdFaction = n"";
        this.m_fdBody = CBNoEntity();
      } else {
        this.m_parleyFaction = n"";
        this.m_parleyBody = CBNoEntity();
      }
    }
    if this.m_owners == 0 {
      this.Release(sys, game);
    }
  }

  private func Release(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let player = GetPlayer(game);
    let pools = GameInstance.GetStatPoolsSystem(game);
    let des = GameInstance.GetDynamicEntitySystem();
    let now = CBGameSeconds(game);
    let rt = CyberbaneRuntime.Get();
    let enabled = !IsDefined(rt) || rt.IsEnabled();
    let restored = 0;
    for p in this.m_held {
      if IsDefined(p) {
        let wasHeld = p.cbTruceHeld;
        let wasMeter = p.cbTruceMeter;
        p.cbTruceHeld = false;
        p.cbTruceMeter = false;
        // The per-NPC gate before anything native is read: this runs as talk stands down, the world changing included.
        if CBNpcSafe(sys, p) && !p.IsDead() && CBStillStanding(p) {
          let id = p.GetEntityID();
          // The warning counts down again, if V is still being warned.
          if wasMeter && IsDefined(pools) && pools.IsStatPoolAdded(Cast<StatsObjectID>(id), gamedataStatPoolType.ReprimandEscalation) {
            p.QueueEvent(new ReprimandEscalationEvent());
          }
          // Hostile again, unless the words changed that: a parley or a deal (they hold back from V now), a toll V paid
          // their gang, somebody who gave up, broke or was sent off, or one of ours stood down for good.
          let toll = IsDefined(sys) && sys.TollActive(CBClassifyFaction(p), now);
          let keepCalm = p.cbHoldState == 1 || p.cbCalmedBy == 1 || p.cbSurrendered || p.cbGaveUp || p.cbMoraleBroken
                      || (IsDefined(des) && des.IsTagged(id, n"CB_Orphan")) || toll;
          // A toll V paid their gang keeps them calm from here, and it is the toll that puts them back when it runs out
          // (Reactions/Director.reds, KeepCalm): held by it as if it had calmed them itself.
          if wasHeld && toll && p.cbCalmedBy == 0 && p.cbHoldState != 1 {
            p.cbCalmedBy = 2;
          }
          // With Cyberbane switched off, only the game's hostility comes back: what Cyberbane set is its to undo.
          let ours = p.cbHostileByCyberbane || CBSentByUs(des, p);
          // Nor, while the NCPD are after V, anybody of the street Cyberbane turned: they stand down until the stars
          // are gone, and the Director turns them again after (CBPoliceOnV).
          let streetTurned = p.cbHostileByCyberbane && !CBSentByUs(des, p);
          if wasHeld && !keepCalm && IsDefined(player) && !CBNpcInCombat(p) && (enabled || !ours) && !(streetTurned && CBPoliceOnV(sys)) {
            CBMakeHostileToPlayer(game, p);
            restored += 1;
          }
        }
      }
    }
    if ArraySize(this.m_held) > 0 {
      CBLog.Info(n"Talk", s"The talking is over: \(ArraySize(this.m_held)) held, \(restored) hostile again.");
    }
    ArrayClear(this.m_held);
    this.m_owners = 0;
    this.m_talkFaction = n"";
    this.m_fdFaction = n"";
    this.m_talkPartner = CBNoEntity();
    this.m_fdBody = CBNoEntity();
    this.m_parleyFaction = n"";
    this.m_parleyBody = CBNoEntity();
  }

  // A new session: the old world's people are gone, and nothing is put back.
  public func Reset() -> Void {
    ArrayClear(this.m_held);
    this.m_owners = 0;
    this.m_broken = false;
    this.m_talkFaction = n"";
    this.m_fdFaction = n"";
    this.m_talkPartner = CBNoEntity();
    this.m_fdBody = CBNoEntity();
    this.m_parleyFaction = n"";
    this.m_parleyBody = CBNoEntity();
  }
}

// A guard's warning meter, neither filling nor draining.
@addField(ScriptedPuppet)
public let cbSidedWithV: Bool;

public func CBHeldOutOfFight(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) {
    return false;
  }
  // With V: nothing V or V's crew does turns them, whatever was hit.
  if p.cbSidedWithV && p.IsAttached() && !p.IsDead() {
    return true;
  }
  if p.cbDamagedByPlayer {
    return false;
  }
  return p.cbFacedownHeld || p.cbFacedownWait || p.cbTruceHeld || (p.cbTalkPartner && p.cbTalkLinesUp) || CBSidesWithV(p);
}

// One of a gang friendly or allied with V: kept out of a fight somebody else started, until V hurts one of them.
public func CBSidesWithV(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) || !p.IsAttached() || p.IsDead() {
    return false;
  }
  let sys = CyberbaneSystem.Get(p.GetGame());
  if !IsDefined(sys) || !CBNpcSafe(sys, p) || p.IsCrowd() {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if IsDefined(des) && des.IsTagged(p.GetEntityID(), n"CB_Turned") {
    return false;   // one of V's crew who turned on V
  }
  let gang = CBClassifyFaction(p);
  let score = sys.GetScore();
  if !IsNameValid(gang) || !IsDefined(score) || !CBFactionOn(gang) {
    return false;
  }
  let posture = score.GetPosture(gang);
  if !Equals(posture, ECBPosture.Allied) && !Equals(posture, ECBPosture.Friendly) {
    return false;
  }
  // V turned on their own, close by: then it is their fight too, as it is for any gang. Held regardless, V could cut down a
  // friendly gang's people one at a time while the rest stood and watched.
  return !CBGangHurtByVNear(sys, p, gang);
}

// Somebody of this gang near them that V has hurt and who is still on their feet, or down here now.
func CBGangHurtByVNear(sys: ref<CyberbaneSystem>, p: wref<ScriptedPuppet>, gang: CName) -> Bool {
  let reg = sys.GetRegistry();
  if !IsDefined(reg) {
    return false;
  }
  let at = p.GetWorldPosition();
  for other in reg.GetAll() {
    if IsDefined(other) && other.cbDamagedByPlayer && CBNpcSafe(sys, other)
       && Vector4.Distance(other.GetWorldPosition(), at) <= CBConfig.AllyHurtNearRange() && Equals(CBClassifyFaction(other), gang) {
      return true;
    }
  }
  return false;
}

// The game turns people on V by this one door (aiActionHelper.script): somebody seeing a squad mate in danger, a hit
// nearby, a threat on their tracker, a stim.
@wrapMethod(AIActionHelper)
public static func TryChangingAttitudeToHostile(owner: ref<ScriptedPuppet>, target: ref<GameObject>) -> Bool {
  if CBKeepsOutOfFight(owner, target) {
    return false;
  }
  return wrappedMethod(owner, target);
}

// Both ways round. Somebody held out of a fight with V does not turn on V or V's companions, and V's companions do not
// turn on them.
func CBKeepsOutOfFight(owner: wref<GameObject>, target: wref<GameObject>) -> Bool {
  if !IsDefined(owner) || !IsDefined(target) {
    return false;
  }
  let held = owner as ScriptedPuppet;
  if IsDefined(held) && CBHeldOutOfFight(held) && (target.IsPlayer() || ScriptedPuppet.IsPlayerCompanion(target)) {
    return true;
  }
  let them = target as ScriptedPuppet;
  return IsDefined(them) && ScriptedPuppet.IsPlayerCompanion(owner) && CBHeldOutOfFight(them);
}

// The game's other door, when it hands somebody a combat target (aiActionHelper.script SetCommandCombatTarget, a combat
// target picked in aiCoreTasks.script): the same rule.
@wrapMethod(GameObject)
public static func ChangeAttitudeToHostile(owner: wref<GameObject>, target: wref<GameObject>) -> Void {
  if CBKeepsOutOfFight(owner, target) {
    return;
  }
  wrappedMethod(owner, target);
}

public func CBTruceStopMeter(pools: ref<StatPoolsSystem>, sid: StatsObjectID) -> Void {
  let regen: StatPoolModifier;
  pools.GetModifier(sid, gamedataStatPoolType.ReprimandEscalation, gameStatPoolModificationTypes.Regeneration, regen);
  regen.enabled = false;
  pools.RequestSettingModifier(sid, gamedataStatPoolType.ReprimandEscalation, gameStatPoolModificationTypes.Regeneration, regen);
  let decay: StatPoolModifier;
  pools.GetModifier(sid, gamedataStatPoolType.ReprimandEscalation, gameStatPoolModificationTypes.Decay, decay);
  decay.enabled = false;
  pools.RequestSettingModifier(sid, gamedataStatPoolType.ReprimandEscalation, gameStatPoolModificationTypes.Decay, decay);
}

// The law and MaxTac answer to heat and stars, never to Cyberbane (crash rules: no police system).
public func CBTruceNeverHolds(faction: CName) -> Bool {
  return Equals(faction, n"NCPD") || Equals(faction, n"MaxTac") || Equals(faction, n"Police");
}
