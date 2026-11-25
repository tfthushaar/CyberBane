// Cyberbane - The apex squad (spec §9.9)
//
// A four-strong team that arrives by car: a tank, a shooter, a blade and a netrunner, built to fight like MaxTac rather
// than four copies of one ganger.

// Has this one already been kitted out? Applying a gameplay ability package twice stacks it, so a puppet that attaches
// more than once (streaming can do this) would end up with two Sandevistans.
@addField(ScriptedPuppet)
public let cbKitted: Bool;

// Which chair of the squad this one was given, plus one, so that zero means "not one of a
// squad" and there is no need for a negative default - which redscript field declarations do
// not accept anyway.
@addField(ScriptedPuppet)
public let cbApexSeatRole: Int32;

// Has this one already had its stat buffs applied?
@addField(ScriptedPuppet)
public let cbBuffed: Bool;

public enum ECBApexRole {
  Tank = 0,
  Assault = 1,
  Blade = 2,
  Netrunner = 3
}

// What kind of fighter is this record, in the game's terms?
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
public func CBArchetypeRole(a: gamedataArchetypeType, out role: ECBApexRole) -> Bool {
  switch a {
    case gamedataArchetypeType.HeavyMeleeT2:
    case gamedataArchetypeType.HeavyMeleeT3:
    case gamedataArchetypeType.HeavyRangedT2:
    case gamedataArchetypeType.HeavyRangedT3:
      role = ECBApexRole.Tank;
      return true;
    // Anybody who fights hand to hand is a blade, and nobody else is. Snipers used to be filed
    // here and melee fighters under Assault, so the "blade" chair could be a sniper and a man
    // with a machete could be a "shooter".
    case gamedataArchetypeType.FastMeleeT2:
    case gamedataArchetypeType.FastMeleeT3:
    case gamedataArchetypeType.GenericMeleeT1:
    case gamedataArchetypeType.GenericMeleeT2:
      role = ECBApexRole.Blade;
      return true;
    // A techie throws grenades and hacks nothing, so a techie is not a netrunner.
    case gamedataArchetypeType.NetrunnerT1:
    case gamedataArchetypeType.NetrunnerT2:
    case gamedataArchetypeType.NetrunnerT3:
      role = ECBApexRole.Netrunner;
      return true;
    case gamedataArchetypeType.GenericRangedT1:
    case gamedataArchetypeType.GenericRangedT2:
    case gamedataArchetypeType.GenericRangedT3:
    case gamedataArchetypeType.FastRangedT2:
    case gamedataArchetypeType.FastRangedT3:
    case gamedataArchetypeType.ShotgunnerT2:
    case gamedataArchetypeType.ShotgunnerT3:
    case gamedataArchetypeType.FastShotgunnerT2:
    case gamedataArchetypeType.FastShotgunnerT3:
    case gamedataArchetypeType.SniperT2:
    case gamedataArchetypeType.FastSniperT3:
    case gamedataArchetypeType.TechieT2:
    case gamedataArchetypeType.TechieT3:
      role = ECBApexRole.Assault;
      return true;
    default:
      break;
  };
  return false;
}

// The chair this one was actually given, if it was given one.
@addField(ScriptedPuppet)
public let cbApexName: String;

public func CBApexMemberName(game: GameInstance, faction: CName, seat: Int32) -> String {
  let rt = CyberbaneRuntime.Get();
  let content = CBContent(game);
  if !IsDefined(content) {
    return "";
  }
  let seed = IsDefined(rt) && Equals(rt.lastApexFaction, faction) ? rt.lastApexSeed : 0;
  let lead = CBApexName(content, faction, seed);
  if seat <= 0 {
    return lead;
  }
  let k = 0;
  while k < 6 {
    let name = CBApexName(content, faction, seed + 1009 * seat + 97 * k);
    if StrLen(name) > 0 && NotEquals(name, lead) {
      return name;
    }
    k += 1;
  }
  return "";
}

public func CBApexSeatRole(npc: ref<ScriptedPuppet>, out role: ECBApexRole) -> Bool {
  if !IsDefined(npc) || npc.cbApexSeatRole <= 0 {
    return false;
  }
  role = IntEnum<ECBApexRole>(npc.cbApexSeatRole - 1);
  return true;
}

public func CBRoleName(role: ECBApexRole) -> String {
  switch role {
    case ECBApexRole.Tank: return CBT(n"Cyberbane-Crew-Heavy");
    case ECBApexRole.Blade: return CBT(n"Cyberbane-Crew-Blade");
    case ECBApexRole.Netrunner: return CBT(n"Cyberbane-StreetRead-Netrunner");
    default: return CBT(n"Cyberbane-Crew-Shooter");
  };
}

// Remember this record as the gang's template for its role.
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
public func CBApexRoleRecord(fs: ref<CBFactionState>, seat: Int32, fallback: TweakDBID) -> TweakDBID {
  if !IsDefined(fs) {
    return fallback;
  }
  let listed = CBApexRosterRecord(fs.id, seat);
  if TDBID.IsValid(listed) {
    return listed;
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
public func CBIsCorpFaction(faction: CName) -> Bool {
  return Equals(faction, n"Arasaka") || Equals(faction, n"Militech")
      || Equals(faction, n"KangTao");
}

func CBApplyCorpKit(npc: ref<NPCPuppet>) -> Void {
  if !IsDefined(npc) {
    return;
  }
  CBGrantAbility(npc, t"Ability.CanShootWhileMoving");   // advance under fire
  CBGrantAbility(npc, t"Ability.CanPreciseShoot");
  CBGrantAbility(npc, t"Ability.CanCatchUp");            // walking away is not an escape
  CBGrantAbility(npc, t"Ability.CanUseAntiStun");        // cannot be stun-locked in place
  CBGrantAbility(npc, t"Ability.CanSeeThroughOpticalCamos");
  // The first asks the game to bring in more NPCs on its own, the second plays a cyberware effect on a record that was
  // never made for one, and the third needs grenades the record may not carry. None of them is worth a crash risk.
}

// What a cyberpsycho learns from losing to you.
public func CBKitCyberpsycho(npc: ref<NPCPuppet>) -> Void {
  if !IsDefined(npc) || npc.cbKitted {
    return;
  }
  npc.cbKitted = true;
  // Every other kit stands down when Much Better AI or New Game Plus owns kitting.
  if CBAiKitOwner() {
    return;
  }
  CBGrantAbility(npc, t"Ability.CanShootWhileMoving");
  CBGrantAbility(npc, t"Ability.CanCatchUp");
  CBGrantAbility(npc, t"Ability.CanUseAntiStun");
  CBGrantAbility(npc, t"Ability.CanSeeThroughOpticalCamos");
  CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");
  CBGrantAbility(npc, t"Ability.CanUseCovers");
}

public func CBApplyRoleKit(npc: ref<NPCPuppet>, role: ECBApexRole) -> Void {
  if !IsDefined(npc) {
    return;
  }
  // Everybody on the team gets these: they use cover properly, and they are not blinded by their
  // own smoke.
  CBGrantAbility(npc, t"Ability.CanUseCovers");
  CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");

  switch role {
    case ECBApexRole.Tank:
      // Walks at you, breaks your guard, and takes a magazine to put down.
      CBGrantAbility(npc, t"Ability.HasSubdermalArmorHigh");
      CBGrantAbility(npc, t"Ability.CanGuardBreak");
      break;
    case ECBApexRole.Blade:
      // Closes the distance and keeps on you.
      CBGrantAbility(npc, t"Ability.CanCatchUp");
      CBGrantAbility(npc, t"Ability.CanUseAntiStun");
      break;
    case ECBApexRole.Netrunner:
      // Stays back. A netrunner record already hacks with the kit the game gave it; a seat
      // filled from another record does not get quickhacks bolted on.
      CBGrantAbility(npc, t"Ability.CanSeeThroughOpticalCamos");
      break;
    default:
      // Flushes you out of cover so the others can reach you.
      CBGrantAbility(npc, t"Ability.CanUseFragGrenades");
      CBGrantAbility(npc, t"Ability.CanUseFlashbangGrenades");
      CBGrantAbility(npc, t"Ability.CanShootWhileMoving");
      break;
  };
  // Kerenzikov, Charge Jump, combat stims and bolted-on quickhacks are gone from every kit.
}

// Apply one gameplay ability, through its package, the way the game does it itself.
public func CBGrantAbility(npc: ref<NPCPuppet>, id: TweakDBID) -> Void {
  if !IsDefined(npc) || !TDBID.IsValid(id) || !npc.IsAttached() || npc.IsDead() {
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
  let glp = GameInstance.GetGameplayLogicPackageSystem(npc.GetGame());
  if !IsDefined(glp) {
    return;
  }
  // Never one the body already carries from its own record or archetype.
  if CBRecordCarriesAbility(npc, ability) {
    return;
  }
  if CBIsSubdermalAbility(id) {
    let stats = GameInstance.GetStatsSystem(npc.GetGame());
    if IsDefined(stats) && stats.GetStatValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatType.HasSubdermalArmor) > 0.0 {
      return;
    }
  }
  let packageID = package.GetID();
  let applied: array<TweakDBID>;
  glp.GetAppliedPackages(npc, applied);
  if !ArrayContains(applied, packageID) || package.Stackable() {
    glp.ApplyPackage(npc, npc, packageID);
  }
}

// Which role this seat of a squad fills.
public func CBApexRoleForSeat(seat: Int32) -> ECBApexRole {
  let s = seat % 4;
  if s == 0 { return ECBApexRole.Tank; }
  if s == 1 { return ECBApexRole.Assault; }
  if s == 2 { return ECBApexRole.Blade; }
  return ECBApexRole.Netrunner;
}

// Kit one member of an apex squad.
public func CBKitApexSeat(npc: ref<ScriptedPuppet>, seat: Int32) -> Void {
  let asNpc = npc as NPCPuppet;
  if !IsDefined(asNpc) || npc.cbKitted {
    return;
  }
  npc.cbKitted = true;
  let role = CBApexRoleForSeat(seat);
  let actual: ECBApexRole;
  if CBArchetypeRole(CBRecordArchetype(npc.GetRecordID()), actual) {
    role = actual;
  }
  // Recorded before either early return below, because the bar wants the role whether or not
  // another mod is handing out the capabilities.
  npc.cbApexSeatRole = EnumInt(role) + 1;
  if CBAiKitOwner() {
    return;   // Much Better AI or New Game Plus is already doing this properly
  }
  CBApplyRoleKit(asNpc, role);
  if CBIsCorpFaction(CBClassifyFaction(npc)) {
    CBApplyCorpKit(asNpc);
  }
  CBApplyTactics(asNpc, true);   // Spawn/Tactics.reds
}

// Work out a spawned enforcer's role from what it actually is, and kit it out.
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
  if CBIsCorpFaction(CBClassifyFaction(npc)) {
    CBApplyCorpKit(asNpc);
  }
  CBApplyTactics(asNpc, true);   // Spawn/Tactics.reds
}

// The lighter kit, for the rank and file of a hit squad.
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
  // Rank and file from a corp are still soldiers. A lighter version of the corp kit: they advance while firing, they
  // keep pace, and they do not fold to a stun-lock.
  let side = CBClassifyFaction(npc);
  if CBIsCorpFaction(side) || CBCodeSoldiers(side) {
    CBGrantAbility(asNpc, t"Ability.CanShootWhileMoving");
    CBGrantAbility(asNpc, t"Ability.CanCatchUp");
    CBGrantAbility(asNpc, t"Ability.CanUseAntiStun");
  }
  // And how each of them fights, by what they are (Spawn/Tactics.reds).
  CBApplyTactics(asNpc, false);
}

// Put the team in one squad, so they fight as a team.
public func CBJoinSquadWith(sys: ref<CyberbaneSystem>, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(puppet) {
    return;
  }
  let anchor = sys.GetSquadAnchor();
  if !IsDefined(anchor) || anchor.IsDead() || !anchor.IsAttached() {
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
  if !IsDefined(squad) || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  CBTrace("squad: joining a spawned enemy to its team");
  squad.Join(puppet);
}

// ---- The chair a body was spawned for ----------------------------------------------------
//
// An apex squad is a heavy, a shooter, a blade and a netrunner. The record each body is spawned from is picked by
// chair, and the kit and the bar's label are given by chair at setup, so the two have to agree on which chair a body
// is.
public func CBApexRoleTag(seat: Int32) -> CName {
  switch seat % 4 {
    case 0: return n"CB_Role0";
    case 1: return n"CB_Role1";
    case 2: return n"CB_Role2";
    default: return n"CB_Role3";
  }
}

// One chair as a bit of the squad's muster mask (Spawn/FactionApex.reds, CBApexMusterTick).
public func CBApexChairBit(seat: Int32) -> Int32 {
  switch seat % 4 {
    case 0: return 1;
    case 1: return 2;
    case 2: return 4;
    default: return 8;
  }
}

// The chair this body was spawned for, or -1 if it carries none.
public func CBTaggedApexSeat(des: ref<DynamicEntitySystem>, id: EntityID) -> Int32 {
  if !IsDefined(des) {
    return -1;
  }
  if des.IsTagged(id, n"CB_Role0") { return 0; }
  if des.IsTagged(id, n"CB_Role1") { return 1; }
  if des.IsTagged(id, n"CB_Role2") { return 2; }
  if des.IsTagged(id, n"CB_Role3") { return 3; }
  return -1;
}
