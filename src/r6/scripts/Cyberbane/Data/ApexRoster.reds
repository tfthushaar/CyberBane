// Cyberbane - Who sits in each chair of a gang's apex squad (1.7.0)
//
// "The apex squad members are all the same even though they have roles like heavy, netrunner,
// blade. All they do is use guns." That was exactly what was happening. A chair's record came from
// the gang's role records, and those were only ever filled by V killing somebody of that kind, so
// until V had personally put down a blade and a netrunner from that gang, every chair fell back
// to the same elite record: four copies of one shooter with four different labels on the bar. The
// label and an ability kit were all the role there was.
//
// A role cannot be painted on. What makes somebody fight with a katana, hack V from cover or walk
// through fire behind an HMG is the character record: its weapon, its archetype and the behaviour
// the game wrote for that archetype. So each chair is now a real record of that kind from that
// gang's own people, listed here, read straight out of the game's faction files. A netrunner
// record netruns because the game built it to, which is also why this stays inside crash rule 6:
// nothing is bolted on to a character the game never made for it.
//
// Where a gang simply has nobody of a kind (the Valentinos have no netrunners, the Animals no
// blades), the chair holds the nearest thing that gang really fields, and the bar and the kit say
// what that person actually is (CBKitApexSeat). A gang is not given a netrunner it does not have.
//
// Safe by construction: every entry is a TweakDB lookup checked at runtime, so a record missing on
// a patch or without Phantom Liberty is skipped, never spawned. Each is also put through the same
// tests as any other template (CBRecordUnfitTemplate): a person, nobody the story owns, and nobody
// who brings the police down on V.

// The people a gang can put in this chair, best first.
public func CBApexRosterList(faction: CName, chair: Int32) -> array<TweakDBID> {
  let c = chair % 4;
  if Equals(faction, n"TygerClaws") {
    if c == 0 { return [t"Character.tyger_claws_ozeki_hmelee3_kanabo_mb", t"Character.tyger_claws_martial_hmelee3_StrongArms_mb"]; }
    if c == 1 { return [t"Character.tyger_claws_biker3_shotgun3_zhuo_ma_elite", t"Character.tyger_claws_gangster3_ranged3_sidewinder_ma"]; }
    if c == 2 { return [t"Character.tyger_claws_kunoichi_fmelee3_katana_wa_elite", t"Character.tyger_claws_martial_fmelee2_katana_ma_rare"]; }
    return [t"Character.tygerclaw_gangster3_netrunner_nue_wa_rare"];
  }
  if Equals(faction, n"Maelstrom") {
    if c == 0 { return [t"Character.maelstrom_strong_gunner2_defender_mb_rare"]; }
    if c == 1 { return [t"Character.maelstom_strong_shotgun2_carnage_ma_rare", t"Character.maelstrom_fast_franged2_pulsar_ma_rare"]; }
    if c == 2 { return [t"Character.maelstrom_fast_fmelee3_mantis_wa_elite", t"Character.maelstrom_fast_fmelee2_machete_ma_rare"]; }
    return [t"Character.maelstrom_netrunner_netrunner2_lexington_ma"];
  }
  if Equals(faction, n"Valentinos") {
    if c == 0 { return [t"Character.valentinos_machete_hmelee3_machete_mb_elite", t"Character.valentinos_grunt4_hmelee2_fists_mb_rare"]; }
    if c == 1 { return [t"Character.valentinos_elite3_ranged3_dual_ma_elite", t"Character.valentinos_elite2_ranged3_dual_ma_rare"]; }
    if c == 2 { return [t"Character.valentinos_grunt3_fmelee2_machete_ma_rare", t"Character.valentinos_grunt3_fmelee2_knife_ma_rare"]; }
    return [t"Character.valentinos_sniper_sniper3_grad_wa_elite"];   // no netrunners; their sniper
  }
  if Equals(faction, n"SixthStreet") {
    if c == 0 { return [t"Character.sixthstreet_prepers3_shotgun3_carnage_ma_rare"]; }   // no heavies
    if c == 1 { return [t"Character.sixthstreet_patrol2_shotgun3_satara_ma_elite", t"Character.sixthstreet_veteran3_ranged2_ajax_ma"]; }
    if c == 2 { return [t"Character.sixthstreet_menace1_fmelee2_baton_wa_rare"]; }
    return [t"Character.sixthstreet_prepers3_grenadier2_nova_ma_rare", t"Character.sixthstreet_sniper2_sniper2_grad_ma_rare"];
  }
  if Equals(faction, n"Animals") {
    if c == 0 { return [t"Character.animals_elite3_gunner3_hmg_mba_elite", t"Character.animals_grunt3_gunner2_defender_mb_rare"]; }
    if c == 1 { return [t"Character.animals_elite3_shotgun3_carnage_mba_elite", t"Character.animals_elite2_shotgun3_carnage_wba_elite"]; }
    if c == 2 { return [t"Character.animals_bouncer3_hmelee3_fists_mba_elite", t"Character.animals_elite3_hmelee3_fists_mba_elite"]; }
    return [t"Character.animals_elite2_hmelee2_hammer_mba_rare"];   // no netrunners; a hammer
  }
  if Equals(faction, n"VoodooBoys") {
    if c == 0 { return [t"Character.voodooboys_grunt3coat_shotgun3_zhuo_ma_elite"]; }
    if c == 1 { return [t"Character.voodooboys_grunt1_ranged2_sidewinder_ma", t"Character.voodooboys_grunt2coat_shotgun2_palica_wa"]; }
    if c == 2 { return [t"Character.voodooboys_grunt1_fmelee2rare_baseball_ma_rare"]; }
    return [t"Character.voodooboys_netrunner3_netrunner3_quasar_wa_elite", t"Character.voodooboys_netrunner2_netrunner2_lexington_ma_rare"];
  }
  if Equals(faction, n"Scavengers") {
    if c == 0 { return [t"Character.scavenger_strong3_gunner2_defender_mb_rare", t"Character.scavenger_butcher3_hmelee2_machete_mb_rare"]; }
    if c == 1 { return [t"Character.scavenger_elite3_sniper2_grad_ma", t"Character.scavenger_grunt2_ranged2_copperhead_ma"]; }
    if c == 2 { return [t"Character.scavenger_fast3_fmelee3_machete_wa_elite", t"Character.scavenger_fast2_fmelee2rare_knife_ma_rare"]; }
    return [t"Character.scavenger_netrunner2_netrunner2_nova_wa_rare", t"Character.scavenger_grunt3_netrunner2_nova_ma_rare"];
  }
  if Equals(faction, n"Mox") {
    // Six records in the whole faction, all fast and close-in, which is what the Mox are.
    if c == 0 { return [t"Character.the_mox_elite2_fmelee2_machete_wa_rare"]; }
    if c == 1 { return [t"Character.the_mox_1_ranged1_lexington_wa", t"Character.the_mox_1_ranged1_pulsar_wa"]; }
    if c == 2 { return [t"Character.the_mox_elite3_fmelee3_mantis_wa_elite"]; }
    return [t"Character.the_mox_elite2_fmelee2_knife_wa_rare"];
  }
  if Equals(faction, n"Wraiths") {
    if c == 0 { return [t"Character.wraiths_strong_gunner3_hmg_mb_elite", t"Character.wraiths_strongarms_hmelee3_fists_mb_elite"]; }
    if c == 1 { return [t"Character.wraiths_warrior3_shotgun3_satara_ma_elite", t"Character.wraiths_warrior3_ranged3_quasar_wa_rare"]; }
    if c == 2 { return [t"Character.wraiths_prisoner_fmelee3_fists_ma_elite"]; }
    return [t"Character.wraiths_ghost2_sniper2_achilles_ma_rare"];
  }
  if Equals(faction, n"Aldecaldos") {
    if c == 0 { return [t"Character.adelcaldos_driver_shotgun2_tactician_ma"]; }
    if c == 1 { return [t"Character.adelcaldos_grunt2_ranged2_copperhead_ma", t"Character.adelcaldos_grunt2_ranged2_sidewinder_ma"]; }
    if c == 2 { return [t"Character.aldecaldos_grunt2_melee2__ma"]; }
    return [t"Character.aldecaldos_grunt2_sniper2_sor22_wa_elite"];
  }
  if Equals(faction, n"Barghest") {
    // The kurtz_ records are Hansen's army. The prevention_dogtown_ records in the same colours
    // are Dogtown's police and are never used (see CBRecordDrawsPolice).
    if c == 0 { return [t"Character.kurtz_elite3_gunner3_HMG_mb_elite", t"Character.kurtz_strongarms_hmelee3_fists_mb_elite"]; }
    if c == 1 { return [t"Character.kurtz_soldier2_generic_ranged3_rifle_ma", t"Character.kurtz_soldier2_shotgun2_shotgun_ma_rare"]; }
    if c == 2 { return [t"Character.kurtz_martial_fmelee3_fists_ma_rare"]; }
    return [t"Character.kurtz_netrunner2_netrunner2_lexington_ma_rare"];
  }
  if Equals(faction, n"Arasaka") {
    if c == 0 { return [t"Character.arasaka_rare2_gunner3_hmg_mm_elite", t"Character.arasaka_sumo_hmelee2_hammer_mb_rare"]; }
    if c == 1 { return [t"Character.arasaka_cyborg_franged3_shingen_ma_elite", t"Character.arasaka_cyborg_fshotgun3_zhuo_ma_elite"]; }
    if c == 2 { return [t"Character.arasaka_ninja_fmelee3_katana_ma_elite", t"Character.arasaka_ninja_fmelee3_mantis_wa_elite"]; }
    return [t"Character.arasaka_netrunner_netrunner2_yukimura_ma_rare", t"Character.arasaka_netrunner_netrunner2_yukimura_wa_rare"];
  }
  if Equals(faction, n"Militech") {
    if c == 0 { return [t"Character.militech_enforcer3_gunner3_HMG_mb_elite", t"Character.militech_strongarms_hmelee3_fists_mb_elite"]; }
    if c == 1 { return [t"Character.militech_soldier3_shotgun3_crusher_mah_elite", t"Character.militech_enforcer2_shotgun2_tactician_mah_rare"]; }
    if c == 2 { return [t"Character.militech_tech_franged2_omaha_ma_rare"]; }   // no blades
    return [t"Character.militech_tech_grenadier2_omaha_ma_rare", t"Character.militech_recon_sniper2_achilles_ma_rare"];
  }
  if Equals(faction, n"KangTao") {
    if c == 0 { return [t"Character.kangtao_soldier2_shotgun3_zhuo_mah_elite"]; }
    if c == 1 { return [t"Character.kangtao_ranger1_ranged2_dian_ma"]; }
    if c == 2 { return [t"Character.kangtao_soldier2_shotgun2_zhuo_mah_rare"]; }
    return [t"Character.kangtao_officer_grenadier3_mah_elite"];
  }
  let none: array<TweakDBID>;
  return none;
}

// One record for this chair of this gang: any of the ones listed that this install really has and
// that is fit to send, chosen at random so the same four faces do not turn up every time. Invalid
// when the gang has none, and the caller falls back to whoever V has actually fought.
public func CBApexRosterRecord(faction: CName, chair: Int32) -> TweakDBID {
  let listed = CBApexRosterList(faction, chair);
  let count = ArraySize(listed);
  if count == 0 {
    return TDBID.None();
  }
  let start = RandRange(0, count);
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
