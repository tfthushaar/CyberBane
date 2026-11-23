// Cyberbane - Broker peace & compatibility backoff (spec §11.3, §17)
//
// Broker peace: pay a gang you can buy off to drop a hostility or vendetta. It costs
// eddies scaled by how much blood is between you, pulls their standing back out of the
// hostile band and clears the vendetta. Triggered from the Hub (the Gangs screen: click a gang,
// then Pay them off, carried out when the pause menu closes), from a reply in the phone, or from
// the public API.
//
// Compatibility: when They Will Remember compatibility is on (or auto-detected), Cyberbane
// stands down from the systems that overlap - hostile-on-sight, hit squads and faction
// disguises - and leaves the rest running (spec §17).

public func CBTwrActive() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return false;
  }
  let mode = rt.GetSettings().twrCompat;
  if Equals(mode, ECBTwrCompat.On) {
    return true;
  }
  if Equals(mode, ECBTwrCompat.Off) {
    return false;
  }
  return CBDetectTwr();   // Auto
}

// Detect They Will Remember by asking Mod Settings which mods have registered a page.
//
// That list is the steadiest signal available: They Will Remember requires Mod Settings,
// and the names in this list are the ones the player sees in the settings menu, so they
// do not move when the other mod reorganises its own classes. Matching on "Remember" also
// catches Night City Remembers, which is a ground-up replacement for They Will Remember
// and overlaps Cyberbane in exactly the same places.
//
// Scanned once and cached on the runtime service - the compat check is read per NPC per
// tick. An empty list means Mod Settings has not finished registering yet, so that answer
// is not cached and the scan is retried on the next call.
func CBDetectTwr() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    let cached = rt.GetTwrDetected();
    if cached != 0 {
      return cached == 1;
    }
  }
  // The compiler already knows, and that answer is exact: ModuleExists asks whether They
  // Will Remember's own scripts are in this build, or Night City Remembers' (2.6.7). The settings-page
  // scan below was all that looked for Night City Remembers until then, and it never could: its
  // settings are in Redscript Config Framework, not Mod Settings, so it was never in that list. "I have
  // Night City Remembers, I tried talking to a Tyger Claw and she was hostile and started combat": both
  // mods ran hostility of their own, and Cyberbane offered words to somebody the other had hostile on sight.
  let found = CBTwrModulePresent() || CBNcrModulePresent();
  if !found {
    let mods = CBModSettingsMods();
    if ArraySize(mods) == 0 {
      return false;   // not ready yet; ask again next time rather than caching a guess
    }
    for mod in mods {
      if StrContains(NameToString(mod), "Remember") {
        found = true;
      }
    }
  }
  if IsDefined(rt) {
    rt.SetTwrDetected(found);
  }
  // What is detected, not what is done about it: the compatibility setting decides that, and this is
  // also asked with it on Off (CBTwrGangHostile, 1.9.1).
  if found {
    // Asked of the modules directly: CBRememberMod asks this function when neither is there.
    if CBNcrModulePresent() && !CBTwrModulePresent() {
      CBLog.Info(n"Core", "Night City Remembers detected. With its compatibility setting on Auto, Cyberbane leaves it hostility on sight; Cyberbane's crews and disguises run as usual, since it sends nobody and reads no disguise.");
    } else {
      CBLog.Info(n"Core", "They Will Remember detected. With its compatibility setting on Auto, Cyberbane leaves it hostility on sight, hit squads and faction disguises.");
    }
  } else {
    CBLog.Info(n"Core", "They Will Remember not detected; Cyberbane is running its own hostility, hit squad and disguise systems.");
  }
  return found;
}

// Is New Game Plus running?
//
// Checked at compile time rather than by name, which is the exact signal: ModuleExists asks
// the compiler whether that mod's scripts are in the build, so there is no list to scan, no
// cache to invalidate and no way for a renamed settings page to fool it.
//
// It matters because New Game Plus rebuilds every NPC in the game to be harder. Its buffs and
// Cyberbane's are both stat multipliers on the same puppet, so they multiply rather than
// replace, and an apex under both would simply not die. Cyberbane halves its own contribution
// and stops rolling its own traits when this is true (see CBApexStrengthFraction).
@if(ModuleExists("NGPlus"))
public func CBNgpActive() -> Bool {
  return true;
}

@if(!ModuleExists("NGPlus"))
public func CBNgpActive() -> Bool {
  return false;
}

// Is They Will Remember compiled into this build?
@if(ModuleExists("TheyWillRemember"))
func CBTwrModulePresent() -> Bool {
  return true;
}

@if(!ModuleExists("TheyWillRemember"))
func CBTwrModulePresent() -> Bool {
  return false;
}

// Is Night City Remembers (2.6.7)? Its scripts are module NightCityRemembers.
@if(ModuleExists("NightCityRemembers"))
func CBNcrModulePresent() -> Bool {
  return true;
}

@if(!ModuleExists("NightCityRemembers"))
func CBNcrModulePresent() -> Bool {
  return false;
}

// Which of the two keeps the gangs' memory (2.6.7): 1 They Will Remember, 2 Night City Remembers, 0 neither. They overlap
// Cyberbane in different places. Both decide who is hostile to V on sight, and Cyberbane follows that (CBTwrActive). Only
// They Will Remember sends crews after V and reads disguises; Night City Remembers sends nobody and reads no clothes, so
// with it Cyberbane's crews still come and its own disguise reading stands. A settings page named for remembering, found
// with neither module (CBDetectTwr), is taken for They Will Remember, which is what that scan was written for.
public func CBRememberMod() -> Int32 {
  if CBTwrModulePresent() {
    return 1;
  }
  if CBNcrModulePresent() {
    return 2;
  }
  return CBDetectTwr() ? 1 : 0;
}

// Its name, for the Hub, the log and the reasons Cyberbane gives.
public func CBRememberModName() -> String {
  return CBRememberMod() == 2 ? CBT(n"Cyberbane-Peace-NightCityRemembers") : CBT(n"Cyberbane-Peace-TheyWillRemember");
}

// With compatibility on, the other mod sends the gangs after V and Cyberbane's crews and apex squads stand down: They Will
// Remember only.
public func CBRememberSendsCrews() -> Bool {
  return CBTwrActive() && CBRememberMod() == 1;
}

// With compatibility on, the other mod's disguise reading is Cyberbane's: They Will Remember only.
public func CBRememberReadsDisguises() -> Bool {
  return CBTwrActive() && CBRememberMod() == 1;
}

// Short, for the Gangs screen's posture column.
public func CBRememberModShort() -> String {
  return CBRememberMod() == 2 ? CBT(n"Cyberbane-Peace-NCR") : CBT(n"Cyberbane-Peace-TWR");
}

// They Will Remember's own word on this gang (1.9.0): 1 hostile on sight, 0 not, -1 nobody to ask.
//
// "They Will Remember told me Tyger Claws turned hostile, and Cyberbane still shows them neutral."
// Both were true. They are two records. Cyberbane's standing is earned and spent and is what moves
// prices and pay-offs; They Will Remember rolls a gang hostile from how many of theirs V has killed,
// as early as the first one, keeps that in its own save data, and with it installed Cyberbane hands it
// hostility on sight and the gangs' crews (CBTwrActive). The Hub showed only Cyberbane's record, so a
// gang shooting V on sight read as neutral. It asks They Will Remember too now.
//
// At run time, through Codeware's reflection, so nothing in this build names anything of theirs. A
// version of theirs without this function answers -1 and the Hub shows what it always did; calling it
// by name instead would fail every script mod's compile on any install with such a version
// (`ModuleExists` says a mod is there, never which version). The index is theirs
// (KillCounts.GetFactionIndex), which their own saved list is kept in, so it cannot move under them.
//
// Asked whenever They Will Remember is installed (1.9.1), not only while Cyberbane stands down for it.
// "Still neutral" was reported again on 1.9.0: with the compatibility setting on Off, so that both mods
// run their own hostility, this answered -1 without asking, and the Hub showed Cyberbane's record alone.
// What it found is said once a launch in the log, so a report says which step it got to.
public func CBTwrGangHostile(game: GameInstance, faction: CName) -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !CBDetectTwr() {
    return -1;
  }
  return rt.TwrHostility(CBTwrFactionIndex(faction));
}

// 2.4.2: asked on Cyberbane's tick and kept, every gang at once, instead of on every question. The standing
// a gang acts on follows its answer now (Data/Factions.reds, CBActingStanding), and that is read for every
// person on the street on every tick; asking They Will Remember there would have been a dozen reflected
// calls per person. Asked every other second, as the Hub opens, and fresh at a session's start.
//
// "Isn't Cyberbane supposed to follow They Will Remember's hostility? Factions can be hostile
// independently." They could, two ways. The Gangs screen alone asked it, so everything Cyberbane does
// about a gang went on reading Cyberbane's own standing: a gang They Will Remember had hostile was neutral
// to the rest of Cyberbane, and a gang Cyberbane had hostile (its lifepath, say) stayed hostile. And when
// the asking failed the screen showed neither, with the reason logged once a launch, the first time it was
// tried, often at the main menu before its system was running. Now the reason is kept and shown
// (CBTwrHostilityWhy) and logged whenever it changes, and the call's own status says whether it went through.
public class CBTwrAttitudeProbe {
  public let state: Int32;   // 0 not looked yet, 1 usable, 2 absent or not the shape this reads
  public let ask: ref<ReflectionMemberFunc>;
  public let answersInt: Bool;   // it answers a number (above zero hostile) rather than yes or no
  public let why: String;

  // 2.5.1: tolerant of how a version of theirs words the question, and exact about what it found when it cannot ask.
  // "They Will Remember decides whether they are hostile, but could not be asked (it has no IsFactionHostileByIndex
  // taking one argument and answering yes or no)" was all a player could report, and it covered three different
  // failures. Now: the names a version of theirs has used or may use, an answer of yes or no or of a number, and a why
  // that says which function was found and in what shape. A look that failed is tried again each session (Retry).
  public func Resolve() -> Bool {
    if this.state == 0 {
      this.state = 2;
      this.why = "";
      let type = Reflection.GetClass(CBTwrAttitudeClass());
      if !IsDefined(type) {
        this.why = CBT(n"Cyberbane-Peace-ItsAttitudeClassIsNotIn");
      } else {
        let names: array<CName> = [n"IsFactionHostileByIndex", n"IsFactionIndexHostile", n"IsFactionHostile",
                                   n"GetFactionHostileByIndex", n"IsHostileByIndex"];
        let seen = "";
        for name in names {
          if this.state != 1 {
            let fn = type.GetFunction(name);
            if IsDefined(fn) {
              let paramList = fn.GetParameters();
              let params = ArraySize(paramList);
              let yesNo = CBReflectReturns(fn, n"Bool");
              let number = CBReflectReturns(fn, n"Int32");
              // The one argument has to be a gang's number, since that is what is handed over. Its own
              // IsFactionHostile takes a person (They Will Remember 3.1), and was taken here before the type was read.
              let takesIndex = false;
              if params == 1 && IsDefined(paramList[0]) {
                let pt = paramList[0].GetType();
                takesIndex = IsDefined(pt) && Equals(pt.GetName(), n"Int32");
              }
              if takesIndex && (yesNo || number) {
                this.ask = fn;
                this.answersInt = number;
                this.state = 1;
              } else {
                let ret = fn.GetReturnType();
                let retName = IsDefined(ret) ? NameToString(ret.GetName()) : CBT(n"Cyberbane-Peace-Nothing");
                seen += CBTf(n"Cyberbane-Peace-TakesAndAnswers", [(StrLen(seen) > 0 ? "; " : ""), s"\(NameToString(name))", s"\(CBReflectParamNames(paramList))", s"\(retName)"]);
              }
            }
          }
        }
        if this.state != 1 {
          this.why = StrLen(seen) > 0
            ? CBTf(n"Cyberbane-Peace-ItsFunctionsAreNotTheShape", [seen])
            : CBT(n"Cyberbane-Peace-ItHasNoneOfTheFunctions");
        }
      }
    }
    return this.state == 1;
  }

  public func Retry() -> Void {
    if this.state == 2 {
      this.state = 0;
    }
  }
}

// What a function takes, for the why: "Int32", "ScriptedPuppet, Bool", "nothing".
func CBReflectParamNames(params: array<ref<ReflectionProp>>) -> String {
  if ArraySize(params) == 0 {
    return CBT(n"Cyberbane-Peace-Nothing");
  }
  let out = "";
  for p in params {
    let t = IsDefined(p) ? p.GetType() : null;
    out += (StrLen(out) > 0 ? ", " : "") + (IsDefined(t) ? NameToString(t.GetName()) : "?");
  }
  return out;
}

// Whose system is asked who is hostile on sight. Night City Remembers' (2.6.7) answers the same question by the same shape,
// IsFactionHostile with one gang number in and yes or no out, from its own saved record.
public func CBTwrAttitudeClass() -> CName {
  return CBRememberMod() == 2 ? n"NightCityRemembers.NCRSystem" : n"TheyWillRemember.Factions.AttitudeManager";
}

public func CBTwrRefreshHostility(game: GameInstance) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !CBDetectTwr() {
    return;
  }
  let answers: array<Int32>;
  let why = "";
  let probe = rt.GetTwrAttitudeProbe();
  let container = GameInstance.GetScriptableSystemsContainer(game);
  let manager = IsDefined(container) ? container.Get(CBTwrAttitudeClass()) : null;
  if !probe.Resolve() {
    why = probe.why;
  } else {
    if !IsDefined(manager) {
      why = CBT(n"Cyberbane-Peace-ItsAttitudeSystemIsNotRunning");
    }
  }
  let i = 0;
  while i < CBTwrFactionSlots() {
    let answer = -1;
    if StrLen(why) == 0 && NotEquals(CBTwrFactionAt(i), n"") {
      let args: array<Variant>;
      ArrayPush(args, ToVariant(i));
      let ok = false;
      let said = probe.ask.Call(manager, args, ok);
      if ok {
        if probe.answersInt {
          answer = FromVariant<Int32>(said) > 0 ? 1 : 0;
        } else {
          answer = FromVariant<Bool>(said) ? 1 : 0;
        }
      } else {
        why = CBT(n"Cyberbane-Peace-ItWouldNotTakeTheQuestion");
      }
    }
    ArrayPush(answers, answer);
    i += 1;
  }
  if rt.SetTwrHostility(answers, why) {
    CBTwrProbeNote(why);
  }
}

// How many of its gang indexes there are (0 to 15, Disguise.m_factionNames).
public func CBTwrFactionSlots() -> Int32 = 16

// Why They Will Remember could not be asked who is hostile, or "" when it answered.
public func CBTwrHostilityWhy() -> String {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) ? rt.TwrHostilityWhy() : "";
}

// In the log whenever how asking They Will Remember went changes. Empty means it answered.
func CBTwrProbeNote(why: String) -> Void {
  let name = CBRememberModName();
  if StrLen(why) == 0 {
    CBLog.Info(n"Core", s"\(name) answers who is hostile on sight, and Cyberbane follows it.");
  } else {
    CBLog.Info(n"Core", s"\(name) could not be asked who is hostile on sight: \(why). Cyberbane goes by its own standing until it answers.");
  }
}

// Is this faction hostile to V on sight by somebody else's hand (1.9.1)? 2: They Will Remember says
// so. 1: their people have been seen hostile to V lately, and not by Cyberbane's doing
// (Reactions/Director.reds, NoteForeignHostility) - They Will Remember, another mod or the game.
// 0: nothing says so. The Gangs screen shows this beside Cyberbane's own posture, and it is the one
// thing that tells a player whether the people shooting at them are Cyberbane's doing at all.
public func CBForeignHostile(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Int32 {
  if CBTwrGangHostile(game, faction) == 1 {
    return 2;
  }
  if IsDefined(sys) && sys.SeenHostileRecently(faction) {
    return 1;
  }
  return 0;
}

// Their numbering of the gangs (They Will Remember 2.7, KillCounts.GetFactionIndex; 3.x adds the Aldecaldos
// and the Mox, GetFactionRelationshipIndex, and the same order is its disguise's, Disguise.m_factionNames).
// MaxTac and Trauma Team have no answer here.
func CBTwrFactionIndex(faction: CName) -> Int32 {
  if Equals(faction, n"Maelstrom") { return 0; }
  if Equals(faction, n"TygerClaws") { return 1; }
  if Equals(faction, n"Animals") { return 2; }
  if Equals(faction, n"Scavengers") { return 3; }
  if Equals(faction, n"Valentinos") { return 4; }
  if Equals(faction, n"VoodooBoys") { return 5; }
  if Equals(faction, n"SixthStreet") { return 6; }
  if Equals(faction, n"Arasaka") { return 7; }
  if Equals(faction, n"Militech") { return 8; }
  if Equals(faction, n"KangTao") { return 9; }
  if Equals(faction, n"Wraiths") { return 11; }
  if Equals(faction, n"Barghest") { return 12; }
  if Equals(faction, n"NCPD") { return 13; }
  // They Will Remember 3.0 tracks the Aldecaldos too, at 14, and the Mox at 15. Night City Remembers numbers them the other
  // way round (NCRFactions.GetIndex, 2.6.7).
  let ncr = CBRememberMod() == 2;
  if Equals(faction, n"Aldecaldos") { return ncr ? 15 : 14; }
  if Equals(faction, n"Mox") { return ncr ? 14 : 15; }
  return -1;
}

// And back: the gang at their index, or n"" (Trauma Team, 10, is nobody's gang here).
func CBTwrFactionAt(index: Int32) -> CName {
  switch index {
    case 0: return n"Maelstrom";
    case 1: return n"TygerClaws";
    case 2: return n"Animals";
    case 3: return n"Scavengers";
    case 4: return n"Valentinos";
    case 5: return n"VoodooBoys";
    case 6: return n"SixthStreet";
    case 7: return n"Arasaka";
    case 8: return n"Militech";
    case 9: return n"KangTao";
    case 11: return n"Wraiths";
    case 12: return n"Barghest";
    case 13: return n"NCPD";
    case 14: return CBRememberMod() == 2 ? n"Mox" : n"Aldecaldos";
    case 15: return CBRememberMod() == 2 ? n"Aldecaldos" : n"Mox";
  }
  return n"";
}

// What will this gang take to call it off?
//
// The old price was the body count and nothing else: `1000 + 50 * kills`. That meant a gang at
// vendetta charged exactly the same as a gang that merely disliked you, which is wrong in the
// way that matters - the whole point of a vendetta is that it is harder to get out of. It also
// meant the number said nothing about the thing the player is actually buying their way out of.
//
// Three things set the price now:
//   - the bodies, as before, because that is the grievance;
//   - how far into the hostile band their standing has fallen, because that is how much they
//     hate you rather than how much you have cost them;
//   - and a straight multiplier for a vendetta, because a vendetta is a decision they have
//     already taken and taking it back is expensive.
//
// Still capped, so a long campaign against one gang does not price peace out of reach forever.
public func CBPeacePrice(fs: ref<CBFactionState>, posture: ECBPosture) -> Int32 {
  if !IsDefined(fs) {
    return CBConfig.PeaceBaseCost();
  }
  let cost = Cast<Float>(CBConfig.PeaceBaseCost())
           + Cast<Float>(CBConfig.PeacePerKill()) * Cast<Float>(fs.kills);
  // Standing runs to -100 at its worst. Only the hostile part of it is charged for.
  let hate = ClampF(-CBActingStanding(fs.id, fs.standing) / 100.0, 0.0, 1.0);
  cost += Cast<Float>(CBConfig.PeacePerHate()) * hate;
  if Equals(posture, ECBPosture.Vendetta) {
    cost *= CBConfig.PeaceVendettaMult();
  }
  let capped = FloorF(cost);
  if capped > CBConfig.PeaceMaxCost() {
    capped = CBConfig.PeaceMaxCost();
  }
  return capped;
}

// What this gang would take right now, or -1 if there is nothing to buy: a corp or the law
// (who cannot be bought, spec §9.8/§11.3), or a gang that is not hostile. The phone quotes
// this on a reply button and CBBrokerPeace charges it, so the two can never disagree.
public func CBPeaceQuote(sys: ref<CyberbaneSystem>, game: GameInstance, factionId: CName) -> Int32 {
  if !IsDefined(sys) || Equals(factionId, n"") {
    return -1;
  }
  // Paying Cyberbane does nothing about a hostility They Will Remember keeps (1.9.4).
  if CBTwrOwnsHostility(factionId) {
    return -1;
  }
  // Nor about a stance set by hand under How gangs see you (2.1.0): the setting decides how they treat V,
  // so a pay-off would take the money and change nothing. The Hub says why (CBHudWhyNoPeace).
  if CBGangViewSet(factionId) {
    return -1;
  }
  let content = CBContent(game);
  if !IsDefined(content) {
    return -1;
  }
  let prof = content.GetFaction(factionId);
  if !IsDefined(prof) || !prof.canBeBought {
    return -1;
  }
  let fs = sys.FindFaction(factionId);
  let score = sys.GetScore();
  if !IsDefined(fs) || !IsDefined(score) {
    return -1;
  }
  let posture = score.GetPosture(factionId);
  if !(Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta)) {
    return -1;
  }
  // A gang V has broken is in no position to hold out for its price (1.9.5).
  let broken = CBGangBroken(sys, factionId) ? CBConfig.PeaceBrokenShare() : 1.0;
  return Min(CBConfig.PeaceMaxCost(), RoundF(Cast<Float>(CBPeacePrice(fs, posture)) * sys.WornPerk().peaceMult * broken
                                            * CBCodePeace(factionId) * (1.0 - CBPeaceCut(game, factionId))
                                            * CBOpenSeasonPriceMult(game, factionId)));
}

// What a broken gang says when it names its price (1.9.5): less a demand than asking to stop.
public func CBPeaceBrokenLine(cost: Int32) -> String {
  switch RandRange(0, 3) {
    case 0: return CBTf(n"Cyberbane-Peace-ThereSHardlyAnyOfUs", [s"\(cost)"]);
    case 1: return CBTf(n"Cyberbane-Peace-YouMadeYourPointEbAnd", [s"\(cost)"]);
    default: return CBTf(n"Cyberbane-Peace-WeReDoneFightingYouEb", [s"\(cost)"]);
  }
}

// The price after a threat that did not name it (UI/PhoneMessages.reds, CBPhoneDemandText): what V's answers under
// it answer. V pays them, as the Hub's peace does (2.5.0; "Take Xeb" above read as them paying V).
public func CBPeaceAskLine(cost: Int32) -> String {
  switch RandRange(0, 3) {
    case 0: return CBTf(n"Cyberbane-Peace-OrPayEbAndItStops", [s"\(cost)"]);
    case 1: return CBTf(n"Cyberbane-Peace-EbAndWeCallItOff", [s"\(cost)"]);
    default: return CBTf(n"Cyberbane-Peace-UnlessEbReachesUsFirst", [s"\(cost)"]);
  }
}

// A gang putting its price to V unprompted, for the once-a-session standing demand
// (Model/Reputation.reds, CBVendettaWatch). Theirs is the thread that carries the answer, so the
// wording has to open the conversation rather than answer anything: it may arrive a long time
// after they turned on V, in a session where they have not said a word yet.
public func CBPeaceDemandLine(cost: Int32, vendetta: Bool) -> String {
  if vendetta {
    switch RandRange(0, 3) {
      case 0: return CBTf(n"Cyberbane-Peace-YouAreStillWalkingAroundEb", [s"\(cost)"]);
      case 1: return CBTf(n"Cyberbane-Peace-OurPriceHasNotChangedEb", [s"\(cost)"]);
      default: return CBTf(n"Cyberbane-Peace-EbThatIsWhatItCosts", [s"\(cost)"]);
    }
  }
  switch RandRange(0, 3) {
    case 0: return CBTf(n"Cyberbane-Peace-WeHaveNotForgottenYouEb", [s"\(cost)"]);
    case 1: return CBTf(n"Cyberbane-Peace-EbSettlesWhatIsBetweenUs", [s"\(cost)"]);
    default: return CBTf(n"Cyberbane-Peace-YouCanKeepLookingOverYour", [s"\(cost)"]);
  }
}

// Pay off a single faction. Returns true only if peace was actually brokered.
public func CBBrokerPeace(sys: ref<CyberbaneSystem>, game: GameInstance, factionId: CName) -> Bool {
  let cost = CBPeaceQuote(sys, game, factionId);
  if cost < 0 {
    return false;   // nobody to pay, or nothing to buy off
  }
  let fs = sys.FindFaction(factionId);
  let posture = sys.GetScore().GetPosture(factionId);
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return false;
  }
  let money = ItemID.FromTDBID(t"Items.money");
  if ts.GetItemQuantity(player, money) < cost {
    if CBToastsOn() {
      CBPhoneDemandFromGang(game, factionId, CBTf(n"Cyberbane-Peace-EbAndWeForgetAboutYou", [s"\(cost)"]), true);
    }
    return false;
  }

  ts.RemoveItem(player, money, cost);
  // Out of the hostile band, to neutral. It was 15, which is Friendly exactly, so every pay-off was followed by the
  // gang texting that V was welcome on its streets: the money buys the grudge back, not their friendship.
  fs.standing = MaxF(fs.standing, 0.0);
  fs.vendettaSince = 0.0;
  fs.lastPeaceAt = CBGameSeconds(game);

  // Whatever they already had on its way, or out looking for V, is called off (CBCallOffGang).
  CBCallOffGang(sys, game, factionId);

  let deal = new CBPeaceDeal();
  deal.faction = factionId;
  deal.at = fs.lastPeaceAt;
  deal.cost = cost;
  sys.AddPeaceDeal(deal);
  CBFileLog(sys, n"Peace", fs.lastPeaceAt, CBEventDistrict(sys, game), factionId, Cast<Float>(cost));

  if CBToastsOn() {
    let what = Equals(posture, ECBPosture.Vendetta) ? CBT(n"Cyberbane-Peace-Vendetta") : CBT(n"Cyberbane-Peace-Hostility");
    CBPhoneFromGangFinal(game, factionId, CBTf(n"Cyberbane-Peace-EbReceivedTheIsOverDo", [s"\(cost)", s"\(what)"]));
  }
  CBLog.Info(n"Economy", s"Peace brokered with \(NameToString(factionId)) for \(cost).");
  return true;
}

// Everything a gang has on its way to V, or out looking for V, called off: the moment V buys peace from
// them (CBBrokerPeace, from the Hub, the phone or the API).
//
// A pay-off used to clear only what was still queued or counting down. A car already on the road still
// delivered its crew, the next car of a convoy still came, whoever a car came up short of still walked in,
// a scout went on looking for V, and the crew already out kept hunting V, hostile, until V killed them or
// lost them. Losing them then counted as V running from a gang V had just paid.
//
// Their Rivals are not the gang's to call off: a grudge with a name is personal (Rivals/), and so are the
// people who came with one. Anybody of theirs already fighting V finishes that fight, as the Director never
// flips anybody mid-swing; they are only no longer hunting. The rest stand down: their order taken back,
// neutral to V, unmarked, and handed to the orphan sweep, which takes them once V cannot see them go.
public func CBCallOffGang(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(des) || Equals(faction, n"") {
    return 0;
  }
  // Who is theirs among people not in the world yet, read before any of it is cleared: one crew is out
  // at a time, its apex with it, one apex squad musters at a time, and one scout is out.
  let crewIsTheirs = Equals(sys.GetActiveSquadFaction(), faction);
  let apexIsTheirs = (crewIsTheirs && sys.ActiveSquadHasApex()) || Equals(sys.GetApexMusterFaction(), faction);
  let scoutIsTheirs = Equals(sys.GetScoutFaction(), faction);
  // Queued and counting down. Until 1.6.3 a queued apex squad was sent anyway when its turn came.
  if Equals(sys.GetPendingSquadFaction(), faction) {
    sys.ClearPendingSquad();
  }
  if Equals(sys.GetPendingApexFaction(), faction) {
    sys.SetPendingApex(n"", 0);
  }
  if Equals(sys.GetLaneTarget(CBLaneSquad()), faction) {
    sys.ClearLane(CBLaneSquad());
  }
  if Equals(sys.GetLaneTarget(CBLaneApex()), faction) {
    sys.ClearLane(CBLaneApex());
  }
  // On the road: the muster still walking an apex squad in, the scout, the next cars of a convoy and
  // whoever a car came up short of (only ever a gang's crew or apex squad: Spawn/Arrival.reds,
  // CBSendByCar), and the car on its way now unless it is bringing one of their Rivals.
  if Equals(sys.GetApexMusterFaction(), faction) {
    sys.ClearApexMuster();
  }
  if scoutIsTheirs {
    sys.ClearScout();
  }
  if Equals(sys.GetConvoyFaction(), faction) {
    sys.ClearConvoy();
  }
  if Equals(sys.GetTopUpFaction(), faction) {
    sys.ClearTopUp();
  }
  if sys.HasPendingArrival() && Equals(sys.GetPendingArrivalFaction(), faction)
     && NotEquals(sys.GetPendingArrivalLeadTag(), n"CB_Rival") && NotEquals(sys.GetPendingArrivalTag(), n"CB_Rival") {
    sys.ClearPendingArrival();
  }
  // Escorts come with an apex squad or with a Rival, and a Rival's are left with them.
  let rivalOut = false;
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, faction) && (CBRivalBodyPresent(game, r) || sys.GetRivalCarPending() == r.id) {
      rivalOut = true;
    }
  }
  let tags: array<CName> = [n"CB_Squad", n"CB_Apex", n"CB_Scout"];
  if !rivalOut {
    ArrayPush(tags, n"CB_Escort");
  }
  let player = GetPlayer(game);
  let pagent = IsDefined(player) ? player.GetAttitudeAgent() : null;
  let called = 0;
  for tag in tags {
    let ids = des.GetTaggedIDs(tag);
    for id in ids {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      let theirs = false;
      // Their record only of somebody in the world (2.3.0's rule; this read it of whoever the id found).
      if IsDefined(p) && p.IsAttached() {
        theirs = Equals(CBClassifyFaction(p), faction);
      } else {
        // Not in the world yet, so nothing to ask: who sent their kind tells.
        theirs = (Equals(tag, n"CB_Squad") && crewIsTheirs) || (Equals(tag, n"CB_Apex") && apexIsTheirs)
              || (Equals(tag, n"CB_Scout") && scoutIsTheirs);
      }
      if theirs && !(IsDefined(p) && p.IsDead()) {
        if IsDefined(p) && p.IsAttached() && CBStillStanding(p) && !CBNpcInCombat(p) {
          CBCancelMove(p);
          let agent = p.GetAttitudeAgent();
          if IsDefined(agent) && IsDefined(pagent) {
            CBTrace("attitude: one of ours called off; neutral to V");
            agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
          }
          CBCalmTowardCompanions(sys, p);   // and to V's companions, or V's crew guns them down as they go (2.5.0)
          p.cbFacedownHeld = false;         // a parley's crew walks off, no longer held
          CBUntrackOnMap(game, p);
        }
        des.UnassignTag(id, tag);
        if !des.IsTagged(id, n"CB_Orphan") {
          des.AssignTag(id, n"CB_Orphan");
        }
        called += 1;
      }
    }
  }
  // Their crew is over. Not beaten, so nothing is paid for it: it was bought off.
  if crewIsTheirs {
    sys.SetActiveSquadFaction(n"");
    sys.ClearSquadAnchor();
  }
  if called > 0 {
    CBLog.Info(n"Economy", s"\(NameToString(faction)) called off \(called) of theirs.");
  }
  return called;
}

// Whether there is any point composing a message. Every caller of this guards a message and
// nothing else - the bounty is paid, the vendetta sworn and the street's file written before it
// is asked - so answering it with the one silence test (UI/PhoneMessages.reds, CBMessagesOn)
// covers "Where messages go: Off" everywhere at once without touching how anything plays.
func CBToastsOn() -> Bool {
  return CBMessagesOn();
}

// Does They Will Remember decide whether this faction is hostile to V? (1.9.4)
//
// "It would be good to hand control to They Will Remember, or let Cyberbane take over, because
// currently they don't line up." With compatibility on (Auto, and TWR found, or On), TWR is the one
// voice on hostile or not for every faction it tracks: the Gangs screen says what TWR says, and
// Cyberbane stops texting vendettas and price demands for those gangs, which TWR would ignore.
// Compatibility Off hands it all to Cyberbane; TWR's own hostility is then switched off in TWR.
public func CBTwrOwnsHostility(faction: CName) -> Bool {
  return CBTwrActive() && CBDetectTwr() && CBTwrFactionIndex(faction) >= 0;
}
