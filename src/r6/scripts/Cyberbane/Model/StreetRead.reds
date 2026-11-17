// Cyberbane - The street's read on V (1.9.5)
//
// What somebody standing next to V knows about them, in one place. Two things need it: what the crowd
// says about V (Narrative/Whispers.reds) and how a person V walks up to answers (Reactions/
// StreetTalk.reds). Both used to read the score engine piecemeal, and the whispers read almost
// none of it: a mood out of three and a title, so a Ghost with a hundred unseen kills and a Brawler who
// never killed anybody were talked about in the same words.
//
// Read on demand, never stored: every field is worked out from state the save already holds, and the
// read costs a handful of lookups, which is nothing at the rate either of its callers asks.

public class CBStreetRead {
  // Who V is to the city.
  public let renown: Float;
  public let dread: Float;
  public let dreadCiv: Float;
  public let tier: Int32;             // ECBRenownTier
  public let code: Float;             // -100 cyberpsycho .. 100 professional
  public let archetype: Int32;        // ECBArchetype, -1 when V has no style yet
  public let title: String;           // what the street calls V, "" for nothing yet
  public let chromeVisible: Float;
  public let chromeInstalled: Float;
  public let armsCovered: Bool;
  public let masked: Bool;
  public let aura: Float;             // what V looks like right now: a weapon out, fresh bodies
  public let recentKills: Int32;
  public let layingLow: Bool;
  public let heat: Int32;
  public let mercies: Int32;          // everybody V put down and left breathing
  public let unseenKills: Int32;      // bodies nobody could put a name to
  // Where V is standing.
  public let district: CName;
  public let districtLabel: String;
  public let districtRenown: Float;
  public let turfHolder: CName;
  // The speaker's own side, when they have one.
  public let faction: CName;
  public let factionLabel: String;
  public let posture: ECBPosture;
  public let fear: Float;
  public let respect: Float;
  public let kills: Int32;
  public let bosses: Int32;
  public let spared: Int32;
  public let tributes: Int32;
  public let strength: Float;
  public let broken: Bool;            // V has broken their gang (CBGangBroken)
  public let hunter: String;          // a Rival of theirs out after V right now
  public let leader: String;          // whoever runs their crew, from V's Rivals
  public let rivalsAlive: Int32;
}

public func CBReadStreet(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> ref<CBStreetRead> {
  let r = new CBStreetRead();
  r.archetype = -1;
  r.posture = ECBPosture.Neutral;
  r.strength = 100.0;
  if !IsDefined(sys) {
    return r;
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return r;
  }
  r.renown = score.GetRenown();
  r.dread = score.GetDread();
  r.dreadCiv = score.GetDreadCiv();
  r.tier = EnumInt(score.GetTier());
  r.code = sys.GetCode();
  r.archetype = sys.GetPrimaryArchetypeIndex();
  r.title = CBWhisperTitle(sys);
  r.chromeVisible = score.GetChromeVisible();
  r.chromeInstalled = score.GetChrome();
  r.aura = score.GetAura();
  r.heat = score.GetHeatStage();
  r.recentKills = sys.GetRecentKills();
  r.layingLow = CBIsLayingLow(sys, CBGameSeconds(game));
  let worn = sys.GetWorn();
  if IsDefined(worn) {
    r.armsCovered = worn.arms;
    r.masked = worn.masked;
  }
  let stats = sys.GetStats();
  if IsDefined(stats) {
    r.mercies = stats.nonLethal;
    r.unseenKills = stats.unattributed;
  }

  r.district = sys.GetCurrentDistrict();
  r.districtLabel = CBDistrictLabel(r.district);
  let ds = sys.FindDistrict(r.district);
  if IsDefined(ds) {
    r.districtRenown = ds.renown;
  }
  if NotEquals(r.district, n"") {
    r.turfHolder = CBTurfHolder(sys, game, r.district);
  }

  // A faction switched off in Mod Settings speaks like anybody else on the street (1.9.1).
  if Equals(faction, n"") || !CBFactionOn(faction) {
    return r;
  }
  r.faction = faction;
  r.factionLabel = CBFactionLabel(faction);
  r.posture = score.GetPosture(faction);
  r.fear = score.GetFactionFear(faction);
  r.respect = score.GetFactionRespect(faction);
  r.strength = CBGangStrength(sys, faction);
  r.broken = CBGangBroken(sys, faction);
  let fs = sys.FindFaction(faction);
  if IsDefined(fs) {
    r.kills = fs.kills;
    r.bosses = fs.bossesKilled;
    r.spared = fs.spared;
    r.tributes = fs.tributes;
    if fs.leaderRivalId > 0 {
      let boss = sys.FindRivalById(fs.leaderRivalId);
      if IsDefined(boss) && boss.state != EnumInt(ECBRivalState.Slain)
         && boss.state != EnumInt(ECBRivalState.Retired) {
        r.leader = CBRivalDisplayName(sys.GetContent(), boss);
      }
    }
  }
  for rival in sys.GetRivals() {
    if IsDefined(rival) && Equals(rival.faction, faction)
       && (rival.state == EnumInt(ECBRivalState.Active) || rival.state == EnumInt(ECBRivalState.Hunting)) {
      r.rivalsAlive += 1;
      if rival.state == EnumInt(ECBRivalState.Hunting) && StrLen(r.hunter) == 0 {
        r.hunter = CBRivalDisplayName(sys.GetContent(), rival);
      }
    }
  }
  return r;
}

// How the street would put V's style in a few words. "" when there is nothing to say yet.
public func CBStreetStyleWord(archetype: Int32) -> String {
  if archetype == EnumInt(ECBArchetype.Butcher) { return "butcher"; }
  if archetype == EnumInt(ECBArchetype.Ghost) { return "ghost"; }
  if archetype == EnumInt(ECBArchetype.Professional) { return "professional"; }
  if archetype == EnumInt(ECBArchetype.Chromed) { return "chromed-up merc"; }
  if archetype == EnumInt(ECBArchetype.Netrunner) { return "netrunner"; }
  if archetype == EnumInt(ECBArchetype.Brawler) { return "brawler"; }
  return "";
}
