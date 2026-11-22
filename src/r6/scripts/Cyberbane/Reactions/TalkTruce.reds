// Cyberbane - Holding fire while V talks (2.6.7)
//
// "Can't we make them talk inside a restricted area too, and pause the hostility while we talk so they don't start
// shooting before we're done?" And: "that happened once when a Rival was offering to talk but his bodyguards started
// shooting." A conversation with one of a gang is a conversation with all of them standing there: while it lasts,
// their people nearby hold their fire, and on a gang's restricted ground the warning that ends in a fight stops
// counting down. When it is over, everybody is as they were, except where the words changed that (a parley held, a
// deal was struck, a toll was paid). Hurting any of them while they hold breaks it for all of them.
//
// Who holds. Everybody of the gang of the person V is talking to, near V and not already fighting: their crew, a
// Rival's bodyguards, the guards of the ground V is standing on. Not the person themselves (the conversation is
// theirs: talk's own outcomes turn them or calm them), not anybody a facedown holds already, not the crowd, nobody
// the story owns (the Safety Gate), never the police or MaxTac. A street conversation leaves alone the people
// Cyberbane sent after V (a crew hunting V does not stop because V chats with somebody of their gang); a Rival's
// facedown holds those too, since they are the Rival's own people.
//
// How, with the game's own means. Hostile to V and not yet fighting: neutral to V, with what they had seen of V
// forgotten, as a stand-down does (CBCalmTowardsV), and V's companions calmed toward them so nobody on V's side
// opens fire on people standing still. Restricted ground: the game's guard fills a warning meter while V stays
// (BaseStatPools.ReprimandEscalation) and acts when it is full; while V talks it is stopped where it is
// (CBTruceStopMeter). Afterwards hostile again by Cyberbane's own door (CBMakeHostileToPlayer), and the meter set
// filling again by the game's own event (ReprimandEscalationEvent).
//
// One hold at a time, shared by its owners: street talk (from V pressing Talk to the end of the conversation), a Rival's
// facedown (from the Rival stopping to look at V to the end of it) and a crew sergeant's parley (from "Hold your fire!"
// to the end of it). Each owner names its gang. Kept on the system, swept on talk's tick, and checked against its owners
// every sweep, so it cannot outlive them.

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
          // With Cyberbane switched off, only the game's own hostility comes back: what Cyberbane set is its to undo.
          let ours = p.cbHostileByCyberbane || CBSentByUs(des, p);
          // Nor, while the NCPD are after V, anybody of the street Cyberbane turned: they stand down until the stars are gone,
          // and the Director turns them again after (CBPoliceOnV). Cyberbane's own people were sent hostile and nothing
          // sends them again, so they go back as they were.
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

// A guard's warning meter, neither filling nor draining. The game fills it while V stays (reactionComponent.script,
// ReprimandEscalation: regeneration on) and drains it when V backs off (DeescalateReprimand: regeneration off, decay on),
// and its guard acts when it is full or empty. Both off, it stays where it is: the warning waits for the talking to end.
// The same two modifiers the game sets, through the same calls; the game's own event sets it filling again (Release).
// Held out of a fight with V by Cyberbane's word (2.6.7): a Rival's people at a facedown or standing back from a fair fight,
// those walking up calm for one, a crew sergeant's people while he talks, anybody holding while V talks to one of theirs, and
// the person V is talking to. Not once V has hurt them: then it is their fight.
public func CBHeldOutOfFight(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) || p.cbDamagedByPlayer {
    return false;
  }
  return p.cbFacedownHeld || p.cbFacedownWait || p.cbTruceHeld || (p.cbTalkPartner && p.cbTalkLinesUp);
}

// The game turns people on V by this one door (aiActionHelper.script): somebody seeing a squad mate in danger, a hit nearby,
// a threat on their tracker, a stim. Anybody neutral and aggressive it makes hostile to V and to V's whole group, which is
// how a Rival's bodyguards, held neutral for a fair fight, opened fire the moment V hurt the Rival. For anybody Cyberbane has
// held out of a fight with V, it does not change them, and they stay as they are; everybody else, and anybody the target of
// which is not V, goes through as the game has it. Cyberbane turns its own people when the word is broken (CBFacedownHostile).
@wrapMethod(AIActionHelper)
public static func TryChangingAttitudeToHostile(owner: ref<ScriptedPuppet>, target: ref<GameObject>) -> Bool {
  // V, or one of V's companions: the game makes them hostile to the whole of the target's group, which is V's.
  if IsDefined(owner) && IsDefined(target) && CBHeldOutOfFight(owner)
     && (target.IsPlayer() || ScriptedPuppet.IsPlayerCompanion(target)) {
    return false;
  }
  return wrappedMethod(owner, target);
}

// The game's other door, when it hands somebody a combat target (aiActionHelper.script SetCommandCombatTarget, a combat
// target picked in aiCoreTasks.script): the same rule.
@wrapMethod(GameObject)
public static func ChangeAttitudeToHostile(owner: wref<GameObject>, target: wref<GameObject>) -> Void {
  let held = owner as ScriptedPuppet;
  if IsDefined(held) && IsDefined(target) && CBHeldOutOfFight(held)
     && (target.IsPlayer() || ScriptedPuppet.IsPlayerCompanion(target)) {
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
