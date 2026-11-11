// Cyberbane - How the people Cyberbane sends fight (1.8.5)
//
// "I want everyone to be more tactical." Once a fight starts, Cyberbane's own orders are dropped
// (every move order is ignoreInCombat), so how anybody fights is the game's combat AI, and that AI
// picks its tactics from abilities: prefer cover, use shooting spots, shoot on the move, block and
// parry, throw a grenade, hack. A record only does what its abilities allow, and a crew sampled from
// whoever V last killed got almost none of them on top of what the record carried.
//
// Much Better AI (Nexus 31402, cshiai) was the reference for the approach: abilities handed out by
// what the NPC actually is, read from its archetype, applied through the ability's own gameplay
// package and only when that package is not already on the NPC, and never a hand-to-hand ability for
// a machine or a cyberpsycho. Nothing here is its code, and the parts of it that shape spacing, aim
// and netrunner cadence are its job and stay out of Cyberbane. When it, or New Game Plus, is
// installed (CBAiKitOwner), none of this runs.
//
// Behaviour only, every line of it, through CBGrantAbility. No health, no armour, and never the
// chrome that drives effects on records never authored for it (Sandevistan, Kerenzikov, camo,
// berserk), the line the apex kit has held since 1.5.0. Grenades and hacks make game effects, so they
// are rationed: one grenadier per crew, and hacks only on records the game made netrunners.

// What a record is, for this file's purposes. Read from the game's own archetype (CBRecordArchetype).
public enum ECBFightStyle {
  Other = 0,
  Rifle = 1,
  Shotgun = 2,
  Sniper = 3,
  Blade = 4,
  Heavy = 5,
  Netrunner = 6
}

public func CBFightStyleOf(record: TweakDBID) -> ECBFightStyle {
  switch CBRecordArchetype(record) {
    case gamedataArchetypeType.GenericRangedT1:
    case gamedataArchetypeType.GenericRangedT2:
    case gamedataArchetypeType.GenericRangedT3:
    case gamedataArchetypeType.FastRangedT2:
    case gamedataArchetypeType.FastRangedT3:
    case gamedataArchetypeType.TechieT2:
    case gamedataArchetypeType.TechieT3:
    case gamedataArchetypeType.HeavyRangedT2:
    case gamedataArchetypeType.HeavyRangedT3:
      return ECBFightStyle.Rifle;
    case gamedataArchetypeType.ShotgunnerT2:
    case gamedataArchetypeType.ShotgunnerT3:
    case gamedataArchetypeType.FastShotgunnerT2:
    case gamedataArchetypeType.FastShotgunnerT3:
      return ECBFightStyle.Shotgun;
    case gamedataArchetypeType.SniperT2:
    case gamedataArchetypeType.FastSniperT3:
      return ECBFightStyle.Sniper;
    case gamedataArchetypeType.FastMeleeT2:
    case gamedataArchetypeType.FastMeleeT3:
    case gamedataArchetypeType.GenericMeleeT1:
    case gamedataArchetypeType.GenericMeleeT2:
      return ECBFightStyle.Blade;
    case gamedataArchetypeType.HeavyMeleeT2:
    case gamedataArchetypeType.HeavyMeleeT3:
      return ECBFightStyle.Heavy;
    case gamedataArchetypeType.NetrunnerT1:
    case gamedataArchetypeType.NetrunnerT2:
    case gamedataArchetypeType.NetrunnerT3:
      return ECBFightStyle.Netrunner;
    default:
      break;
  };
  return ECBFightStyle.Other;
}

public func CBRecordIsNetrunner(record: TweakDBID) -> Bool {
  return Equals(CBFightStyleOf(record), ECBFightStyle.Netrunner);
}

// Blocking, parrying and guard breaks are animation work: only for a person who fights hand to hand
// the way the game's people do, never a machine or a cyberpsycho.
func CBFightsLikeAPerson(npc: ref<NPCPuppet>) -> Bool {
  return IsDefined(npc) && !npc.IsMechanical() && !NPCManager.HasTag(npc.GetRecordID(), n"Cyberpsycho");
}

// The tactical layer, by fighting style. `elite` is the apex squad and the Rivals: they get a little
// more, so the gap between them and a crew still means something. Called from the kits, which have
// already checked CBAiKitOwner and guarded against kitting anybody twice.
public func CBApplyTactics(npc: ref<NPCPuppet>, elite: Bool) -> Void {
  if !IsDefined(npc) || !npc.IsAttached() || npc.IsDead() {
    return;
  }
  CBGrantAbility(npc, t"Ability.CanUseCovers");
  CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");
  let person = CBFightsLikeAPerson(npc);
  switch CBFightStyleOf(npc.GetRecordID()) {
    case ECBFightStyle.Rifle:
      // Fight from cover and from the places made for shooting, and keep firing on the move.
      CBGrantAbility(npc, t"Ability.PrefersCovers");
      CBGrantAbility(npc, t"Ability.CanUseShootingSpots");
      CBGrantAbility(npc, t"Ability.CanShootWhileMoving");
      if elite {
        CBGrantAbility(npc, t"Ability.CanPreciseShoot");
        CBGrantAbility(npc, t"Ability.CanCatchUp");
      }
      break;
    case ECBFightStyle.Shotgun:
      // Close the distance under fire.
      CBGrantAbility(npc, t"Ability.CanShootWhileMoving");
      CBGrantAbility(npc, t"Ability.CanCatchUp");
      break;
    case ECBFightStyle.Sniper:
      // Find a perch and stay on it.
      CBGrantAbility(npc, t"Ability.PrefersShootingSpots");
      CBGrantAbility(npc, t"Ability.CanUseShootingSpots");
      CBGrantAbility(npc, t"Ability.CanPreciseShoot");
      break;
    case ECBFightStyle.Blade:
      CBGrantAbility(npc, t"Ability.CanCatchUp");
      if person {
        CBGrantAbility(npc, t"Ability.CanBlock");
        CBGrantAbility(npc, t"Ability.CanParry");
      }
      break;
    case ECBFightStyle.Heavy:
      CBGrantAbility(npc, t"Ability.CanCatchUp");
      if person {
        CBGrantAbility(npc, t"Ability.CanBlock");
        if elite {
          CBGrantAbility(npc, t"Ability.CanGuardBreak");
        }
      }
      break;
    case ECBFightStyle.Netrunner:
      // Stay back and hack.
      CBGrantAbility(npc, t"Ability.PrefersCovers");
      CBGrantAbility(npc, t"Ability.CanUseShootingSpots");
      CBGiveNetrunnerHacks(npc);
      break;
    default:
      break;
  };
}

// The hacks a netrunner may use on V (1.8.5).
//
// A netrunner's hacks are not a list on the record. The game's own netrunner AI chooses from every
// hack it knows (HackActionSelector, ai/actions/library/netrunneractions.tweak) and offers each one
// only to a netrunner holding that hack's ability, with the hack's own cooldown and tier requirements.
// Most of the city's netrunners hold Overheat and little else, which is why they felt like one trick.
// Granting the abilities lets the game's AI use the rest of what it already knows, under its own rules.
//
// Only ever for a record the game made a netrunner: hacking on a record never authored for it is what
// 1.5.0 took out of every kit. Never the hacks that kill outright or take V over: Death, Suicide,
// Detonate Grenade, Madness, Control.
public func CBGiveNetrunnerHacks(npc: ref<NPCPuppet>) -> Void {
  if !IsDefined(npc) || !CBRecordIsNetrunner(npc.GetRecordID()) {
    return;
  }
  CBGrantAbility(npc, t"Ability.CanOverheatQuickHack");
  CBGrantAbility(npc, t"Ability.CanBlindQuickHack");
  CBGrantAbility(npc, t"Ability.CanWeaponMalfunctionQuickHack");
  CBGrantAbility(npc, t"Ability.CanJamWeaponQuickHack");
  CBGrantAbility(npc, t"Ability.CanLocomotionMalfunctionQuickHack");
  CBGrantAbility(npc, t"Ability.CanCyberwareMalfunctionQuickHack");
  CBGrantAbility(npc, t"Ability.CanOverloadQuickHack");
}

// One of a crew carries grenades, to get V out from behind cover so the others can reach. One, not
// every one of them: a crew of eight throwing at once is a wall of effects and no fight. The same two
// kinds the apex squad's shooter has always carried.
public func CBMakeGrenadier(npc: ref<NPCPuppet>) -> Void {
  if !IsDefined(npc) || !npc.IsAttached() || npc.IsDead() {
    return;
  }
  CBGrantAbility(npc, t"Ability.CanUseGrenades");
  CBGrantAbility(npc, t"Ability.CanUseFragGrenades");
  CBGrantAbility(npc, t"Ability.CanUseFlashbangGrenades");
}

// Can this one be a crew's grenadier? A shooter: a netrunner stays back and a sniper stays up.
public func CBCanBeGrenadier(npc: ref<NPCPuppet>) -> Bool {
  if !IsDefined(npc) || !CBFightsLikeAPerson(npc) {
    return false;
  }
  let style = CBFightStyleOf(npc.GetRecordID());
  return Equals(style, ECBFightStyle.Rifle) || Equals(style, ECBFightStyle.Shotgun)
      || Equals(style, ECBFightStyle.Other);
}

// The netrunner who comes with a crew (1.8.5). The one of that gang's netrunners V has actually met,
// which is how another mod's netrunners - More Netrunners - come with the crews too; otherwise the
// gang's own from the base game, for the gangs that have one; otherwise nobody.
public func CBNetrunnerSeatRecord(fs: ref<CBFactionState>) -> TweakDBID {
  if !IsDefined(fs) {
    return TDBID.None();
  }
  let met = fs.roleNetrunnerRecord;
  if TDBID.IsValid(met) && CBRecordIsNetrunner(met) && IsDefined(TweakDBInterface.GetCharacterRecord(met))
     && !CBRecordUnfitTemplate(met) {
    return met;
  }
  let own = CBGangNetrunnerRecord(fs.id);
  if TDBID.IsValid(own) && IsDefined(TweakDBInterface.GetCharacterRecord(own)) && !CBRecordUnfitTemplate(own) {
    return own;
  }
  return TDBID.None();
}

// The base game's own netrunner for the gangs that have one (factions/*.tweak, archetype Netrunner).
func CBGangNetrunnerRecord(faction: CName) -> TweakDBID {
  if Equals(faction, n"TygerClaws") {
    return t"Character.tygerclaw_gangster3_netrunner_nue_wa_rare";
  }
  if Equals(faction, n"Maelstrom") {
    return t"Character.maelstrom_netrunner_netrunner2_lexington_ma";
  }
  if Equals(faction, n"VoodooBoys") {
    return RandF() < 0.5 ? t"Character.voodooboys_netrunner2_netrunner2_lexington_ma_rare"
                          : t"Character.voodooboys_netrunner2_netrunner2_lexington_wa_rare";
  }
  if Equals(faction, n"Scavengers") {
    return RandF() < 0.5 ? t"Character.scavenger_netrunner2_netrunner2_nova_wa_rare"
                          : t"Character.scavenger_grunt3_netrunner2_nova_ma_rare";
  }
  if Equals(faction, n"Arasaka") {
    return t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare";
  }
  return TDBID.None();
}
