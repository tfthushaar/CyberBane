// Cyberbane - Apex squad roster
//
// Each seat in a gang's apex squad is a real character record (tank, shooter, blade, netrunner), so each member fights
// the way that record's archetype does instead of being a reskinned ganger.

// The people a gang can put in this chair, best first.
public func CBApexRosterList(faction: CName, chair: Int32) -> array<TweakDBID> {
  let c = chair % 4;
  let picked: array<TweakDBID>;
  if Equals(faction, n"TygerClaws") {
    if c == 0 { picked = [t"Character.tyger_claws_ozeki_hmelee3_kanabo_mb", t"Character.tyger_claws_martial_hmelee3_StrongArms_mb"]; return picked; }
    if c == 1 { picked = [t"Character.tyger_claws_biker3_shotgun3_zhuo_ma_elite", t"Character.tyger_claws_gangster3_ranged3_sidewinder_ma"]; return picked; }
    if c == 2 { picked = [t"Character.tyger_claws_kunoichi_fmelee3_katana_wa_elite", t"Character.tyger_claws_martial_fmelee2_katana_ma_rare"]; return picked; }
    picked = [t"Character.tygerclaw_gangster3_netrunner_nue_wa_rare"]; return picked;
  }
  if Equals(faction, n"Maelstrom") {
    if c == 0 { picked = [t"Character.maelstrom_strong_gunner2_defender_mb_rare"]; return picked; }
    if c == 1 { picked = [t"Character.maelstom_strong_shotgun2_carnage_ma_rare", t"Character.maelstrom_fast_franged2_pulsar_ma_rare"]; return picked; }
    if c == 2 { picked = [t"Character.maelstrom_fast_fmelee3_mantis_wa_elite", t"Character.maelstrom_fast_fmelee2_machete_ma_rare"]; return picked; }
    picked = [t"Character.maelstrom_netrunner_netrunner2_lexington_ma"]; return picked;
  }
  if Equals(faction, n"Valentinos") {
    if c == 0 { picked = [t"Character.valentinos_machete_hmelee3_machete_mb_elite", t"Character.valentinos_grunt4_hmelee2_fists_mb_rare"]; return picked; }
    if c == 1 { picked = [t"Character.valentinos_elite3_ranged3_dual_ma_elite", t"Character.valentinos_elite2_ranged3_dual_ma_rare"]; return picked; }
    if c == 2 { picked = [t"Character.valentinos_grunt3_fmelee2_machete_ma_rare", t"Character.valentinos_grunt3_fmelee2_knife_ma_rare"]; return picked; }
    picked = [t"Character.valentinos_sniper_sniper3_grad_wa_elite"]; return picked;   // no netrunners; their sniper
  }
  if Equals(faction, n"SixthStreet") {
    if c == 0 { picked = [t"Character.sixthstreet_prepers3_shotgun3_carnage_ma_rare"]; return picked; }   // no heavies
    if c == 1 { picked = [t"Character.sixthstreet_patrol2_shotgun3_satara_ma_elite", t"Character.sixthstreet_veteran3_ranged2_ajax_ma"]; return picked; }
    if c == 2 { picked = [t"Character.sixthstreet_menace1_fmelee2_baton_wa_rare"]; return picked; }
    picked = [t"Character.sixthstreet_prepers3_grenadier2_nova_ma_rare", t"Character.sixthstreet_sniper2_sniper2_grad_ma_rare"]; return picked;
  }
  if Equals(faction, n"Animals") {
    if c == 0 { picked = [t"Character.animals_elite3_gunner3_hmg_mba_elite", t"Character.animals_grunt3_gunner2_defender_mb_rare"]; return picked; }
    if c == 1 { picked = [t"Character.animals_elite3_shotgun3_carnage_mba_elite", t"Character.animals_elite2_shotgun3_carnage_wba_elite"]; return picked; }
    if c == 2 { picked = [t"Character.animals_bouncer3_hmelee3_fists_mba_elite", t"Character.animals_elite3_hmelee3_fists_mba_elite"]; return picked; }
    picked = [t"Character.animals_elite2_hmelee2_hammer_mba_rare"]; return picked;   // no netrunners; a hammer
  }
  if Equals(faction, n"VoodooBoys") {
    if c == 0 { picked = [t"Character.voodooboys_grunt3coat_shotgun3_zhuo_ma_elite"]; return picked; }
    if c == 1 { picked = [t"Character.voodooboys_grunt1_ranged2_sidewinder_ma", t"Character.voodooboys_grunt2coat_shotgun2_palica_wa"]; return picked; }
    if c == 2 { picked = [t"Character.voodooboys_grunt1_fmelee2rare_baseball_ma_rare"]; return picked; }
    picked = [t"Character.voodooboys_netrunner3_netrunner3_quasar_wa_elite", t"Character.voodooboys_netrunner2_netrunner2_lexington_ma_rare"]; return picked;
  }
  if Equals(faction, n"Scavengers") {
    if c == 0 { picked = [t"Character.scavenger_strong3_gunner2_defender_mb_rare", t"Character.scavenger_butcher3_hmelee2_machete_mb_rare"]; return picked; }
    if c == 1 { picked = [t"Character.scavenger_elite3_sniper2_grad_ma", t"Character.scavenger_grunt2_ranged2_copperhead_ma"]; return picked; }
    if c == 2 { picked = [t"Character.scavenger_fast3_fmelee3_machete_wa_elite", t"Character.scavenger_fast2_fmelee2rare_knife_ma_rare"]; return picked; }
    picked = [t"Character.scavenger_netrunner2_netrunner2_nova_wa_rare", t"Character.scavenger_grunt3_netrunner2_nova_ma_rare"]; return picked;
  }
  if Equals(faction, n"Mox") {
    // Six records in the whole faction, all fast and close-in, which is what the Mox are.
    if c == 0 { picked = [t"Character.the_mox_elite2_fmelee2_machete_wa_rare"]; return picked; }
    if c == 1 { picked = [t"Character.the_mox_1_ranged1_lexington_wa", t"Character.the_mox_1_ranged1_pulsar_wa"]; return picked; }
    if c == 2 { picked = [t"Character.the_mox_elite3_fmelee3_mantis_wa_elite"]; return picked; }
    picked = [t"Character.the_mox_elite2_fmelee2_knife_wa_rare"]; return picked;
  }
  if Equals(faction, n"Wraiths") {
    if c == 0 { picked = [t"Character.wraiths_strong_gunner3_hmg_mb_elite", t"Character.wraiths_strongarms_hmelee3_fists_mb_elite"]; return picked; }
    if c == 1 { picked = [t"Character.wraiths_warrior3_shotgun3_satara_ma_elite", t"Character.wraiths_warrior3_ranged3_quasar_wa_rare"]; return picked; }
    if c == 2 { picked = [t"Character.wraiths_prisoner_fmelee3_fists_ma_elite"]; return picked; }
    picked = [t"Character.wraiths_ghost2_sniper2_achilles_ma_rare"]; return picked;
  }
  if Equals(faction, n"Aldecaldos") {
    if c == 0 { picked = [t"Character.adelcaldos_driver_shotgun2_tactician_ma"]; return picked; }
    if c == 1 { picked = [t"Character.adelcaldos_grunt2_ranged2_copperhead_ma", t"Character.adelcaldos_grunt2_ranged2_sidewinder_ma"]; return picked; }
    if c == 2 { picked = [t"Character.aldecaldos_grunt2_melee2__ma"]; return picked; }
    picked = [t"Character.aldecaldos_grunt2_sniper2_sor22_wa_elite"]; return picked;
  }
  if Equals(faction, n"Barghest") {
    // The kurtz_ records are Hansen's army. The prevention_dogtown_ records in the same colours
    // are Dogtown's police and are never used (see CBRecordDrawsPolice).
    if c == 0 { picked = [t"Character.kurtz_elite3_gunner3_HMG_mb_elite", t"Character.kurtz_strongarms_hmelee3_fists_mb_elite"]; return picked; }
    if c == 1 { picked = [t"Character.kurtz_soldier2_generic_ranged3_rifle_ma", t"Character.kurtz_soldier2_shotgun2_shotgun_ma_rare"]; return picked; }
    if c == 2 { picked = [t"Character.kurtz_martial_fmelee3_fists_ma_rare"]; return picked; }
    picked = [t"Character.kurtz_netrunner2_netrunner2_lexington_ma_rare"]; return picked;
  }
  if Equals(faction, n"Scrappers") {
    // Phantom Liberty's scrappers.tweak, the whole of it: one elite, two kinds of rifleman, wrenches and revolvers. No
    // heavies, blades or netrunners of their own; the chairs hold what they really field.
    if c == 0 { picked = [t"Character.scrappers_elite2_shotgun_igla_ma"]; return picked; }   // no heavies; their elite
    if c == 1 { picked = [t"Character.scrappers_ranged2_copperhead_ma", t"Character.scrappers_ranged2_ajax_wa", t"Character.scrappers_ranged2_ajax_ma", t"Character.scrappers_ranged2_copperhead_wa"]; return picked; }
    if c == 2 { picked = [t"Character.scrappers_grunt1_melee1_pipewrench_ma", t"Character.scrappers_grunt1_melee1_pipewrench_wa"]; return picked; }   // no blades; a wrench
    picked = [t"Character.scrappers_grunt1_ranged1_nova_wa", t"Character.scrappers_grunt1_ranged1_nova_ma"]; return picked;   // no netrunners; a revolver
  }
  if Equals(faction, n"Arasaka") {
    if c == 0 { picked = [t"Character.arasaka_rare2_gunner3_hmg_mm_elite", t"Character.arasaka_sumo_hmelee2_hammer_mb_rare"]; return picked; }
    if c == 1 { picked = [t"Character.arasaka_cyborg_franged3_shingen_ma_elite", t"Character.arasaka_cyborg_fshotgun3_zhuo_ma_elite"]; return picked; }
    if c == 2 { picked = [t"Character.arasaka_ninja_fmelee3_katana_ma_elite", t"Character.arasaka_ninja_fmelee3_mantis_wa_elite"]; return picked; }
    picked = [t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare", t"Character.arasaka_netrunner_netrunner2_yukimura_wa_rare"]; return picked;
  }
  if Equals(faction, n"Militech") {
    if c == 0 { picked = [t"Character.militech_enforcer3_gunner3_HMG_mb_elite", t"Character.militech_strongarms_hmelee3_fists_mb_elite"]; return picked; }
    if c == 1 { picked = [t"Character.militech_soldier3_shotgun3_crusher_mah_elite", t"Character.militech_enforcer2_shotgun2_tactician_mah_rare"]; return picked; }
    if c == 2 { picked = [t"Character.militech_tech_franged2_omaha_ma_rare"]; return picked; }   // no blades
    picked = [t"Character.militech_tech_grenadier2_omaha_ma_rare", t"Character.militech_recon_sniper2_achilles_ma_rare"]; return picked;
  }
  if Equals(faction, n"KangTao") {
    if c == 0 { picked = [t"Character.kangtao_soldier2_shotgun3_zhuo_mah_elite"]; return picked; }
    if c == 1 { picked = [t"Character.kangtao_ranger1_ranged2_dian_ma"]; return picked; }
    if c == 2 { picked = [t"Character.kangtao_soldier2_shotgun2_zhuo_mah_rare"]; return picked; }
    picked = [t"Character.kangtao_officer_grenadier3_mah_elite"]; return picked;
  }
  let none: array<TweakDBID>;
  return none;
}

// One record for this chair of this gang: any of the ones listed that this install really has and that is fit to send,
// chosen at random so the same four faces do not turn up every time.
public func CBGangTemplate(sys: ref<CyberbaneSystem>, faction: CName) -> TweakDBID {
  let fs = IsDefined(sys) && IsNameValid(faction) ? sys.FindFaction(faction) : null;
  if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
    return fs.sampleRecord;
  }
  return CBApexRosterRecord(faction, 1);
}

// `pick`: the same choice every time for the same number (a bounty hunter, a solo on offer), else a random one.
public func CBApexRosterRecord(faction: CName, chair: Int32, opt pick: Int32) -> TweakDBID {
  let listed = CBApexRosterList(faction, chair);
  let count = ArraySize(listed);
  if count == 0 {
    return TDBID.None();
  }
  let start = pick > 0 ? pick % count : RandRange(0, count);
  let i = 0;
  while i < count {
    let id = listed[(start + i) % count];
    i += 1;
    if IsDefined(TweakDBInterface.GetCharacterRecord(id)) && !CBRecordUnfitTemplate(id) {
      return id;
    }
  }
  return TDBID.None();
}
