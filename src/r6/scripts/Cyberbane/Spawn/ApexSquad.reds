// Cyberbane - The apex squad (spec §9.9)
//
// A gang's apex is not one heavy any more, it is a four-strong team that turns up in a car:
// a tank, a shooter, a blade and a netrunner. The point is that it fights like MaxTac rather
// than like four copies of the same ganger standing in a row.
//
// The trick is to let the game do the work. Each role is filled with a real record of that
// kind, taken from a member of that gang V has actually fought, so the game's own AI gives
// them the right weapon, the right stance and the right behaviour with no faking at all: a
// netrunner record netruns, a sniper record finds an angle, a heavy record walks at you. On
// top of that each one is handed a kit of real gameplay abilities, which is the part borrowed
// from Much Better AI - an NPC with Sandevistan, grenades, cover use and optical camo is a
// different opponent to one with none of it, and the game already knows how to use all of it.
//
// Roles are read from the game's own `gamedataArchetypeType`, so this is the game's opinion of
// what a record is, not a guess from its name.

// Has this one already been kitted out? Applying a gameplay ability package twice stacks it,
// so a puppet that attaches more than once (streaming can do this) would end up with two
// Sandevistans. Much Better AI guards the same way for the same reason.
@addField(ScriptedPuppet)
public let cbKitted: Bool;

public enum ECBApexRole {
  Tank = 0,
  Assault = 1,
  Blade = 2,
  Netrunner = 3
}

// What kind of fighter is this record, in the game's own terms?
public func CBRecordArchetype(record: TweakDBID) -> gamedataArchetypeType {
  if !TDBID.IsValid(record) {
    return gamedataArchetypeType.Invalid;
  }
  let rec = TweakDBInterface.GetCharacterRecord(record);
  if !IsDefined(rec) {
    return gamedataArchetypeType.Invalid;
  }
  let data = rec.ArchetypeData();
  if !IsDefined(data) {
    return gamedataArchetypeType.Invalid;
  }
  let typeRecord = data.Type();
  if !IsDefined(typeRecord) {
    return gamedataArchetypeType.Invalid;
  }
  return typeRecord.Type();
}

// Sort an archetype into one of the four chairs on the team.
//
// Returns false for anything that does not clearly belong in one, which is most of the city:
// a crowd record, a vehicle, a drone. Those are simply not kept as role templates.
public func CBArchetypeRole(a: gamedataArchetypeType, out role: ECBApexRole) -> Bool {
  switch a {
    case gamedataArchetypeType.HeavyMeleeT2:
    case gamedataArchetypeType.HeavyMeleeT3:
    case gamedataArchetypeType.HeavyRangedT2:
    case gamedataArchetypeType.HeavyRangedT3:
      role = ECBApexRole.Tank;
      return true;
    case gamedataArchetypeType.SniperT2:
    case gamedataArchetypeType.FastSniperT3:
    case gamedataArchetypeType.FastMeleeT2:
    case gamedataArchetypeType.FastMeleeT3:
      role = ECBApexRole.Blade;
      return true;
    case gamedataArchetypeType.NetrunnerT1:
    case gamedataArchetypeType.NetrunnerT2:
    case gamedataArchetypeType.NetrunnerT3:
    case gamedataArchetypeType.TechieT2:
    case gamedataArchetypeType.TechieT3:
      role = ECBApexRole.Netrunner;
      return true;
    case gamedataArchetypeType.GenericRangedT1:
    case gamedataArchetypeType.GenericRangedT2:
    case gamedataArchetypeType.GenericRangedT3:
    case gamedataArchetypeType.ShotgunnerT2:
    case gamedataArchetypeType.ShotgunnerT3:
    case gamedataArchetypeType.GenericMeleeT1:
    case gamedataArchetypeType.GenericMeleeT2:
      role = ECBApexRole.Assault;
      return true;
    default:
      break;
  };
  return false;
}

public func CBRoleName(role: ECBApexRole) -> String {
  switch role {
    case ECBApexRole.Tank: return "heavy";
    case ECBApexRole.Blade: return "blade";
    case ECBApexRole.Netrunner: return "netrunner";
    default: return "shooter";
  };
}

// Remember this record as the gang's template for its role.
//
// Called from the same place the gang's sample and elite records are kept, so the team is
// always assembled out of people V has genuinely fought. A gang V has only ever met shooters
// from will field four shooters, which is correct: they cannot send a netrunner they do not
// have.
public func CBCaptureRoleRecord(fs: ref<CBFactionState>, record: TweakDBID) -> Void {
  if !IsDefined(fs) || !TDBID.IsValid(record) {
    return;
  }
  let role: ECBApexRole;
  if !CBArchetypeRole(CBRecordArchetype(record), role) {
    return;
  }
  switch role {
    case ECBApexRole.Tank:
      fs.roleTankRecord = record;
      break;
    case ECBApexRole.Blade:
      fs.roleBladeRecord = record;
      break;
    case ECBApexRole.Netrunner:
      fs.roleNetrunnerRecord = record;
      break;
    default:
      fs.roleAssaultRecord = record;
      break;
  };
}

// Which record fills seat `seat` of the team.
//
// Falls back to the gang's elite, then to whatever Cyberbane has, so a gang Cyberbane knows
// little about still sends a full car rather than an empty one.
public func CBApexRoleRecord(fs: ref<CBFactionState>, seat: Int32, fallback: TweakDBID) -> TweakDBID {
  if !IsDefined(fs) {
    return fallback;
  }
  let wanted = fallback;
  if seat == 0 {
    wanted = fs.roleTankRecord;
  } else {
    if seat == 1 {
      wanted = fs.roleAssaultRecord;
    } else {
      if seat == 2 {
        wanted = fs.roleBladeRecord;
      } else {
        wanted = fs.roleNetrunnerRecord;
      }
    }
  }
  if TDBID.IsValid(wanted) {
    return wanted;
  }
  return fallback;
}

// Hand one enforcer the kit its role should be fighting with.
//
// These are the game's own gameplay abilities, applied through their ability package, which is
// how Much Better AI equips an NPC and the reason it works: the behaviour is already written,
// it is simply switched on. Nothing here is invented, so there is nothing to go wrong beyond
// an ability failing to apply, which is silent.
public func CBApplyRoleKit(npc: ref<NPCPuppet>, role: ECBApexRole) -> Void {
  if !IsDefined(npc) {
    return;
  }
  // Everybody on the team gets these: they use cover properly, they are not blinded by their
  // own smoke, and they pick themselves back up once.
  CBGrantAbility(npc, t"Ability.CanUseCovers");
  CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");
  CBGrantAbility(npc, t"Ability.CanUseCombatStims");

  switch role {
    case ECBApexRole.Tank:
      // Walks at you, breaks your guard, and takes a magazine to put down.
      CBGrantAbility(npc, t"Ability.HasSubdermalArmorHigh");
      CBGrantAbility(npc, t"Ability.CanGuardBreak");
      break;
    case ECBApexRole.Blade:
      // Closes the distance faster than you can back away from it.
      CBGrantAbility(npc, t"Ability.HasKerenzikov");
      CBGrantAbility(npc, t"Ability.HasChargeJump");
      break;
    case ECBApexRole.Netrunner:
      // Stays back and takes your weapon off you.
      CBGrantAbility(npc, t"Ability.CanQuickhack");
      CBGrantAbility(npc, t"Ability.CanOverheatQuickHack");
      CBGrantAbility(npc, t"Ability.CanWeaponMalfunctionQuickHack");
      break;
    default:
      // Flushes you out of cover so the others can reach you.
      CBGrantAbility(npc, t"Ability.CanUseFragGrenades");
      CBGrantAbility(npc, t"Ability.CanUseFlashbangGrenades");
      CBGrantAbility(npc, t"Ability.HasKerenzikov");
      break;
  };
  // Deliberately NOT granted: Sandevistan, optical camo and berserk.
  //
  // All three drive shader effectors, and a crash report came in from an engine assert inside
  // gameEffectSystem/ApplyShaderEffector while an NPC was being processed. That is not proof -
  // the report named no mod and the assert is asynchronous, so the script that queued the
  // effect would not appear on the stack either way - but these three are the only things
  // Cyberbane had just started doing that touch that system, and granting a visual chrome
  // effect to an arbitrary gang record that was never authored for one is exactly the shape of
  // thing that trips an assert like that. The behavioural abilities above carry no shader work
  // and keep almost all of the value, so this is a cheap thing to give up until it is known.
}

// Apply one gameplay ability, through its package, the way the game does it itself.
public func CBGrantAbility(npc: ref<NPCPuppet>, id: TweakDBID) -> Void {
  if !IsDefined(npc) || !TDBID.IsValid(id) {
    return;
  }
  let ability = TweakDBInterface.GetGameplayAbilityRecord(id);
  if !IsDefined(ability) {
    return;
  }
  let package = ability.AbilityPackage();
  if !IsDefined(package) {
    return;
  }
  RPGManager.ApplyGLP(npc, npc, package);
}

// Work out a spawned enforcer's role from what it actually is, and kit it out.
//
// Reading the puppet rather than remembering which seat it came out of: the puppet knows its
// own archetype, so there is no bookkeeping to get out of step.
public func CBKitApexMember(npc: ref<ScriptedPuppet>) -> Void {
  let asNpc = npc as NPCPuppet;
  if !IsDefined(asNpc) {
    return;
  }
  if npc.cbKitted {
    return;   // already done; applying the packages again would stack them
  }
  // Much Better AI hands out its own capabilities on the same principle, and the two sets
  // would stack rather than merge. It is the better system for this, so it wins.
  if CBAiKitOwner() {
    npc.cbKitted = true;
    return;
  }
  npc.cbKitted = true;
  let role: ECBApexRole;
  if !CBArchetypeRole(CBRecordArchetype(npc.GetRecordID()), role) {
    role = ECBApexRole.Assault;   // unknown archetype: treat them as a shooter
  }
  CBApplyRoleKit(asNpc, role);
}

// The lighter kit, for the rank and file of a hit squad.
//
// Deliberately not the apex kit. Twenty gangers each with a Sandevistan and a bag of grenades
// is not a harder fight, it is an unfair one, and it is twenty more things for the game to
// simulate. What a crew actually needs is to stop standing in the open: cover use and not
// being blinded by its own smoke is the difference between a squad that fights and a squad
// that queues up to be shot.
public func CBKitSquadMember(npc: ref<ScriptedPuppet>) -> Void {
  let asNpc = npc as NPCPuppet;
  if !IsDefined(asNpc) || npc.cbKitted {
    return;
  }
  npc.cbKitted = true;
  if CBAiKitOwner() {
    return;   // Much Better AI or New Game Plus is already doing this properly
  }
  CBGrantAbility(asNpc, t"Ability.CanUseCovers");
  CBGrantAbility(asNpc, t"Ability.CanSeeThroughSmoke");
}

// Put the team in one squad, so they fight as a team.
//
// Without this they are four hostiles who happen to be standing together: each one picks its
// own target, nobody flanks, nobody covers anybody, and the fight is four duels in a row
// rather than an encounter. The game's squad system already does the coordinating; all that
// was missing was telling it these four belong together.
//
// The first one to attach becomes the anchor and the rest join its squad. If the anchor is
// gone (killed, despawned) the next one to attach takes over, so a team that arrives in pieces
// still ends up in one squad.
public func CBJoinSquadWith(sys: ref<CyberbaneSystem>, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(puppet) {
    return;
  }
  let anchor = sys.GetSquadAnchor();
  if !IsDefined(anchor) || anchor.IsDead() {
    sys.SetSquadAnchor(puppet);
    return;
  }
  if Equals(anchor.GetEntityID(), puppet.GetEntityID()) {
    return;
  }
  let smc = anchor.GetSquadMemberComponent();
  if !IsDefined(smc) {
    return;
  }
  let name = AISquadHelper.GetSquadName(anchor);
  if !IsNameValid(name) {
    return;
  }
  let squad = smc.FindSquad(name);
  if !IsDefined(squad) {
    return;
  }
  squad.Join(puppet);
}
