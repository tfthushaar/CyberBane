// Cyberbane - Runtime service (non-persistent global flags)
//
// Codeware ScriptableService. Holds session-only runtime state that must be
// reachable without a GameInstance (the service container accessor is static),
// so low-level helpers such as CBLog can read it. It stores nothing in saves.

public class CyberbaneRuntime extends ScriptableService {
  private let m_enabled: Bool = true;
  private let m_logLevel: Int32 = 1;   // CBLogLevelInfo
  private let m_settings: ref<CyberbaneSettings>;
  private let m_rewardDepth: Int32;    // nesting depth of the reward hook (see GigBonus)
  private let m_twrDetected: Int32;    // 0 = not scanned yet, 1 = present, 2 = absent
  private let m_resetRequested: Bool;  // the player asked for a hard reset (see CyberbaneSettings)
  // Where the last of ours was put down (Spawn/Spawner.reds, CBCreateSpawn), for a place pin before the body is in the
  // world (a favour's lookout, Spawn/LivingStreet.reds).
  public let lastSpawnAt: Vector4;
  // The apex squad last sent and the seed its warning named it from (Spawn/FactionApex.reds, CBProcessPendingApex): the
  // bodies are set up after the seed has moved on, and read their names from here (Spawn/ApexSquad.reds, CBApexMemberName).
  public let lastApexFaction: CName;
  public let lastApexSeed: Int32;
  // Street talk's list, held on screen through the game's clears (Reactions/StreetTalk.reds, CBTalkHeldList): what it
  // is, the line picked, and until when it holds (sim seconds), renewed by talk's own tick while it is up.
  public let talkList: DialogChoiceHubs;
  public let talkListIndex: Int32;
  public let talkListHeld: Bool;
  public let talkListUntil: Float;
  // Which playthrough that reset is for, and which one is loaded now.
  private let m_resetFor: CName;
  private let m_sessionPlaythrough: CName;
  // "This save is another character", parked the same way as a reset and for the same playthrough rules: it belongs to
  // the playthrough loaded when it was chosen, or with nothing loaded, to the next save to load.
  private let m_separateRequested: Bool;
  private let m_separateFor: CName;
  private let m_ngpDetected: Int32;    // same three states, for New Game Plus
  // Why the last arrival was refused (CBBlock*). Diagnostic only, session-only.
  private let m_lastSpawnBlock: Int32;
  private let m_spawnBlockTally: array<Int32>;   // refusals per reason for the placement under way
  public let lastBrokerDistrict: CName;          // the broker who last passed word on, for word from between districts
  public let soundKey: array<CName>;             // each sound's last play, for its cooldown (UI/Sounds.reds)
  public let soundAt: array<Float>;
  // What the street has said lately (Narrative/Lines.reds): the last LineMemory lines that reached the screen, oldest
  // overwritten first. Session only: it is about what V just heard.
  private let m_said: array<String>;
  private let m_saidNext: Int32;
  // Where a search began, to tell when V has changed clothes or district since (Spawn/Hunted.reds).
  private let m_trailSet: Bool;
  private let m_trailLook: Float;
  private let m_trailDistrict: CName;
  // What the last overheard line was about, so the next one is about something else.
  private let m_lastWhisperTopic: CName;
  // How many game seconds pass per real second, measured once a session. About 8.1 by default; a mod like CP Chronology
  // that slows the world clock brings it near 1.
  private let m_clockRatio: Float = 1.0;
  // Sim time of the last on-screen message, so two never land on top of each other.
  private let m_lastMessageAt: Float;
  // Equipment-EX's outfit functions, looked up once a launch (Signals/Concealment.reds).
  private let m_eqexProbe: ref<CBEqExProbe>;
  // Whether WEAVE's auto-tagger is installed, looked up once a launch (Signals/Concealment.reds).
  private let m_weaveProbe: ref<CBWeaveProbe>;
  // The conversation's answer being voiced (Reactions/TalkVoice.reds).
  private let m_talkVoice: ref<CBTalkVoiceNow>;
  // Whether AudioXL is installed to play V's lines from the story, looked up once a launch (Reactions/TalkVoice.reds).
  private let m_audioXLProbe: ref<CBAudioXLProbe>;
  // They Will Remember's disguise functions, looked up once a launch (Signals/Concealment.reds).
  private let m_twrDisguiseProbe: ref<CBTwrDisguiseProbe>;
  // They Will Remember's word on who is hostile, by its own gang index, asked on the tick (CBTwrRefreshHostility): 1
  // hostile, 0 not, -1 not asked or no answer.
  private let m_twrAttitudeProbe: ref<CBTwrAttitudeProbe>;
  private let m_twrHostile: array<Int32>;
  private let m_twrHostileWhy: String;
  private let m_twrHostileAsked: Bool;
  private let m_twrDisguiseWhy: String;
  // Whether V has been told to put a weapon away to talk to people (Reactions/StreetTalk.reds).
  private let m_talkHolsterHinted: Bool;
  private let m_subGen: array<Int32>;
  private let m_subUp: array<Int32>;

  public static func Get() -> ref<CyberbaneRuntime> {
    // The service container is null during world transitions (sleep, fast travel, Skip Time, braindance entry).
    let container = GameInstance.GetScriptableServiceContainer();
    if !IsDefined(container) {
      return null;
    }
    return container.GetService(n"CyberbaneRuntime") as CyberbaneRuntime;
  }

  public func GetSettings() -> ref<CyberbaneSettings> {
    return this.m_settings;
  }

  public func SetSettings(settings: ref<CyberbaneSettings>) -> Void {
    this.m_settings = settings;
  }

  public func HasSettings() -> Bool {
    return IsDefined(this.m_settings);
  }

  public func IsEnabled() -> Bool {
    return this.m_enabled;
  }

  public func SetEnabled(value: Bool) -> Void {
    this.m_enabled = value;
  }

  // Reward-hook nesting.
  public func EnterReward() -> Int32 {
    this.m_rewardDepth += 1;
    return this.m_rewardDepth;
  }

  public func ExitReward() -> Void {
    if this.m_rewardDepth > 0 {
      this.m_rewardDepth -= 1;
    }
  }

  // Cached result of the They Will Remember scan. The compat check is read per NPC per
  // tick, so the scan itself must happen once. Installed mods do not change while the
  // game is running, so caching it for the session is safe.
  public func GetTwrDetected() -> Int32 {
    return this.m_twrDetected;
  }

  public func SetTwrDetected(present: Bool) -> Void {
    this.m_twrDetected = present ? 1 : 2;
  }

  // Cyberbane's subtitle lines (UI/PhoneMessages.reds, CBShowGameSubtitle): which of a channel's two ids is up, and a
  // count per id so a take-down timer only takes down the line it was set for.
  public func SubtitleGenBump(id: Int32) -> Int32 {
    this.PadSubtitles();
    if id < 0 || id >= ArraySize(this.m_subGen) {
      return 0;
    }
    this.m_subGen[id] = this.m_subGen[id] + 1;
    return this.m_subGen[id];
  }

  public func SubtitleGen(id: Int32) -> Int32 {
    this.PadSubtitles();
    return id >= 0 && id < ArraySize(this.m_subGen) ? this.m_subGen[id] : 0;
  }

  public func SubtitleUp(channel: Int32) -> Int32 {
    this.PadSubtitles();
    return channel >= 0 && channel < ArraySize(this.m_subUp) ? this.m_subUp[channel] : channel;
  }

  public func SetSubtitleUp(channel: Int32, id: Int32) -> Void {
    this.PadSubtitles();
    if channel >= 0 && channel < ArraySize(this.m_subUp) {
      this.m_subUp[channel] = id;
    }
  }

  private func PadSubtitles() -> Void {
    while ArraySize(this.m_subGen) < CBSubtitleIdCount() {
      ArrayPush(this.m_subGen, 0);
    }
    while ArraySize(this.m_subUp) < CBSubtitleIdCount() {
      ArrayPush(this.m_subUp, ArraySize(this.m_subUp));
    }
  }

  public func GetTalkHolsterHinted() -> Bool {
    return this.m_talkHolsterHinted;
  }

  public func SetTalkHolsterHinted(on: Bool) -> Void {
    this.m_talkHolsterHinted = on;
  }

  public func GetEqExProbe() -> ref<CBEqExProbe> {
    if !IsDefined(this.m_eqexProbe) {
      this.m_eqexProbe = new CBEqExProbe();
    }
    return this.m_eqexProbe;
  }

  public func GetTalkVoice() -> ref<CBTalkVoiceNow> {
    if !IsDefined(this.m_talkVoice) {
      this.m_talkVoice = new CBTalkVoiceNow();
      this.m_talkVoice.done = true;
    }
    return this.m_talkVoice;
  }

  public func GetAudioXLProbe() -> ref<CBAudioXLProbe> {
    if !IsDefined(this.m_audioXLProbe) {
      this.m_audioXLProbe = new CBAudioXLProbe();
    }
    return this.m_audioXLProbe;
  }

  public func GetWeaveProbe() -> ref<CBWeaveProbe> {
    if !IsDefined(this.m_weaveProbe) {
      this.m_weaveProbe = new CBWeaveProbe();
    }
    return this.m_weaveProbe;
  }

  public func GetTwrAttitudeProbe() -> ref<CBTwrAttitudeProbe> {
    if !IsDefined(this.m_twrAttitudeProbe) {
      this.m_twrAttitudeProbe = new CBTwrAttitudeProbe();
    }
    return this.m_twrAttitudeProbe;
  }

  // Which of the street's features last said why it did not happen, and when (CBStreetWhyNot).
  private let m_whyKeys: array<String>;
  private let m_whyAt: array<Float>;

  public func ShouldNoteWhy(key: String, now: Float, gap: Float) -> Bool {
    let i = 0;
    while i < ArraySize(this.m_whyKeys) {
      if Equals(this.m_whyKeys[i], key) {
        if now >= this.m_whyAt[i] && now - this.m_whyAt[i] < gap {
          return false;
        }
        this.m_whyAt[i] = now;
        return true;
      }
      i += 1;
    }
    if ArraySize(this.m_whyKeys) >= 64 {
      ArrayErase(this.m_whyKeys, 0);
      ArrayErase(this.m_whyAt, 0);
    }
    ArrayPush(this.m_whyKeys, key);
    ArrayPush(this.m_whyAt, now);
    return true;
  }

  // At each session's start. A look at They Will Remember that failed is tried again too: it was made once a launch,
  // and a failure, whatever its cause, held for every save loaded until the game was restarted.
  public func ClearTwrHostility() -> Void {
    ArrayClear(this.m_twrHostile);
    this.m_twrHostileAsked = false;
    if IsDefined(this.m_twrAttitudeProbe) {
      this.m_twrAttitudeProbe.Retry();
    }
    if IsDefined(this.m_twrDisguiseProbe) {
      this.m_twrDisguiseProbe.Retry();
    }
    this.m_twrDisguiseWhy = "";
  }

  // Why They Will Remember's disguises could not be read on the last reading, "" when they were.
  public func SetTwrDisguiseWhy(why: String) -> Void {
    this.m_twrDisguiseWhy = why;
  }

  public func TwrDisguiseWhy() -> String {
    return this.m_twrDisguiseWhy;
  }

  // True when how the asking went is not what was last logged.
  public func SetTwrHostility(answers: array<Int32>, why: String) -> Bool {
    this.m_twrHostile = answers;
    let changed = !this.m_twrHostileAsked || NotEquals(why, this.m_twrHostileWhy);
    this.m_twrHostileWhy = why;
    this.m_twrHostileAsked = true;
    return changed;
  }

  public func TwrHostility(index: Int32) -> Int32 {
    if index < 0 || index >= ArraySize(this.m_twrHostile) {
      return -1;
    }
    return this.m_twrHostile[index];
  }

  public func TwrHostilityWhy() -> String {
    return this.m_twrHostileAsked ? this.m_twrHostileWhy : CBT(n"Cyberbane-CyberbaneRuntime-ItHasNotBeenAskedYet");
  }

  // Smasher Encounters' word on whether Smasher is out (Compat/SmasherEncounters.reds).
  private let m_smasherProbe: ref<CBSmasherProbe>;

  private let m_mbcProbe: ref<CBMbcProbe>;

  public func GetMbcProbe() -> ref<CBMbcProbe> {
    if !IsDefined(this.m_mbcProbe) {
      this.m_mbcProbe = new CBMbcProbe();
    }
    return this.m_mbcProbe;
  }

  // Where bodies were put in the last few seconds, and when (CBPointIsFree): separate groups sent together no longer
  // land inside each other. Engine seconds; a stamp ahead of the clock is an old session's.
  private let m_recentSpawnPos: array<Vector4>;
  private let m_recentSpawnAt: array<Float>;

  public func NoteSpawnPoint(p: Vector4, now: Float) -> Void {
    this.PruneSpawnPoints(now);
    ArrayPush(this.m_recentSpawnPos, p);
    ArrayPush(this.m_recentSpawnAt, now);
  }

  public func SpawnPointTaken(p: Vector4, now: Float, separation: Float) -> Bool {
    this.PruneSpawnPoints(now);
    let n = Min(ArraySize(this.m_recentSpawnPos), ArraySize(this.m_recentSpawnAt));
    let i = 0;
    while i < n {
      if Vector4.Distance(this.m_recentSpawnPos[i], p) < separation {
        return true;
      }
      i += 1;
    }
    return false;
  }

  private func PruneSpawnPoints(now: Float) -> Void {
    let keepPos: array<Vector4>;
    let keepAt: array<Float>;
    let n = Min(ArraySize(this.m_recentSpawnPos), ArraySize(this.m_recentSpawnAt));
    let i = 0;
    while i < n {
      let at = this.m_recentSpawnAt[i];
      if at <= now && now - at < CBConfig.RecentSpawnSeconds() && ArraySize(keepPos) < CBConfig.RecentSpawnCap() {
        ArrayPush(keepPos, this.m_recentSpawnPos[i]);
        ArrayPush(keepAt, at);
      }
      i += 1;
    }
    this.m_recentSpawnPos = keepPos;
    this.m_recentSpawnAt = keepAt;
  }

  // Fenix Rebirth's word on V's rebirths (Compat/FenixRebirth.reds).
  private let m_fenixProbe: ref<CBFenixProbe>;

  public func GetFenixProbe() -> ref<CBFenixProbe> {
    if !IsDefined(this.m_fenixProbe) {
      this.m_fenixProbe = new CBFenixProbe();
    }
    return this.m_fenixProbe;
  }

  public func GetSmasherProbe() -> ref<CBSmasherProbe> {
    if !IsDefined(this.m_smasherProbe) {
      this.m_smasherProbe = new CBSmasherProbe();
    }
    return this.m_smasherProbe;
  }

  public func GetTwrDisguiseProbe() -> ref<CBTwrDisguiseProbe> {
    if !IsDefined(this.m_twrDisguiseProbe) {
      this.m_twrDisguiseProbe = new CBTwrDisguiseProbe();
    }
    return this.m_twrDisguiseProbe;
  }

  // New Game Plus rebuilds every NPC in the game to be harder. Stacking Cyberbane's own apex
  // multipliers on top of that produces something that cannot be killed, so the apex scales
  // itself back when New Game Plus is running.
  public func GetNgpDetected() -> Int32 {
    return this.m_ngpDetected;
  }

  public func SetNgpDetected(present: Bool) -> Void {
    this.m_ngpDetected = present ? 1 : 2;
  }

  public func GetLastMessageAt() -> Float {
    return this.m_lastMessageAt;
  }

  public func SetLastMessageAt(v: Float) -> Void {
    this.m_lastMessageAt = v;
  }

  // The cards waiting behind the one on screen (UI/Notify.reds): their words, their asked-for time, when they were
  // asked for (sim time), and the sim time the card up now ends.
  public let cardText: array<String>;
  public let cardSeconds: array<Float>;
  public let cardAt: array<Float>;
  public let cardUrgent: array<Bool>;   // a menu's answer: first in line, never dropped for room
  public let cardUntil: Float;
  public let cardPumpAt: Float;

  public func CardCount() -> Int32 {
    return Min(Min(ArraySize(this.cardText), ArraySize(this.cardSeconds)), Min(ArraySize(this.cardAt), ArraySize(this.cardUrgent)));
  }

  public func ClearCards() -> Void {
    ArrayClear(this.cardText);
    ArrayClear(this.cardSeconds);
    ArrayClear(this.cardAt);
    ArrayClear(this.cardUrgent);
    this.cardUntil = 0.0;
    this.cardPumpAt = 0.0;
  }

  public func DropCard(i: Int32) -> Void {
    if i < 0 || i >= this.CardCount() {
      return;
    }
    ArrayErase(this.cardText, i);
    ArrayErase(this.cardSeconds, i);
    ArrayErase(this.cardAt, i);
    ArrayErase(this.cardUrgent, i);
  }

  public func GetClockRatio() -> Float {
    return this.m_clockRatio;
  }

  public func SetClockRatio(v: Float) -> Void {
    if v > 0.0 {
      this.m_clockRatio = v;
    }
  }

  public func NoteSaid(line: String) -> Void {
    let cap = CBConfig.LineMemory();
    if ArraySize(this.m_said) < cap {
      ArrayPush(this.m_said, line);
      return;
    }
    if this.m_saidNext < 0 || this.m_saidNext >= ArraySize(this.m_said) {
      this.m_saidNext = 0;
    }
    this.m_said[this.m_saidNext] = line;
    this.m_saidNext = (this.m_saidNext + 1) % ArraySize(this.m_said);
  }

  public func TrailSet() -> Bool { return this.m_trailSet; }
  public func TrailLook() -> Float { return this.m_trailLook; }
  public func TrailDistrict() -> CName { return this.m_trailDistrict; }

  public func SetTrailLook(look: Float, district: CName) -> Void {
    this.m_trailSet = true;
    this.m_trailLook = look;
    this.m_trailDistrict = district;
  }

  public func ClearTrail() -> Void {
    this.m_trailSet = false;
  }

  public func SaidLately(line: String) -> Bool {
    return ArrayContains(this.m_said, line);
  }

  // Of these, the one heard longest ago (or never). The ring's oldest entry sits at m_saidNext once it is
  // full, and at 0 before.
  public func HeardLongestAgo(options: array<String>) -> String {
    let n = ArraySize(this.m_said);
    let best = 0;
    let bestAge = -1;
    let i = 0;
    while i < ArraySize(options) {
      let at = ArrayFindFirst(this.m_said, options[i]);
      if at < 0 {
        return options[i];
      }
      let age = n - ((at - this.m_saidNext + n) % n);
      if age > bestAge {
        bestAge = age;
        best = i;
      }
      i += 1;
    }
    return ArraySize(options) > 0 ? options[best] : "";
  }

  public func GetLastWhisperTopic() -> CName {
    return this.m_lastWhisperTopic;
  }

  public func SetLastWhisperTopic(topic: CName) -> Void {
    this.m_lastWhisperTopic = topic;
  }

  public func GetLastSpawnBlock() -> Int32 {
    return this.m_lastSpawnBlock;
  }

  public func SetLastSpawnBlock(reason: Int32) -> Void {
    this.m_lastSpawnBlock = reason;
    if reason > 0 && reason < CBBlockCount() {
      while ArraySize(this.m_spawnBlockTally) < CBBlockCount() {
        ArrayPush(this.m_spawnBlockTally, 0);
      }
      this.m_spawnBlockTally[reason] += 1;
    }
  }

  public func AssumeSpawnBlock(reason: Int32) -> Void {
    this.m_lastSpawnBlock = reason;
  }

  // A placement starts counting afresh (CBSpawnGroup).
  public func ResetSpawnBlockTally() -> Void {
    ArrayClear(this.m_spawnBlockTally);
  }

  // The reason that refused the most spots since the reset, else the last one noted.
  public func MostSpawnBlock() -> Int32 {
    let best = 0;
    let bestN = 0;
    let i = 1;
    while i < ArraySize(this.m_spawnBlockTally) {
      if this.m_spawnBlockTally[i] > bestN {
        bestN = this.m_spawnBlockTally[i];
        best = i;
      }
      i += 1;
    }
    return bestN > 0 ? best : this.m_lastSpawnBlock;
  }

  // Every reason with its count, for the log line: "safe area 12, in view 3".
  public func SpawnBlockTallyLine() -> String {
    let s = "";
    let i = 1;
    while i < ArraySize(this.m_spawnBlockTally) {
      if this.m_spawnBlockTally[i] > 0 {
        s += (StrLen(s) > 0 ? ", " : "") + CBBlockLabel(i) + " " + IntToString(this.m_spawnBlockTally[i]);
      }
      i += 1;
    }
    return s;
  }

  // Hard reset, asked for in Mod Settings and carried out on the next settled tick.
  public func RequestHardReset() -> Void {
    this.m_resetRequested = true;
    this.m_resetFor = this.m_sessionPlaythrough;
  }

  // A reset for one particular playthrough: one that was started over on a save that is newer
  // than the one just loaded (CyberbaneSystem.StartSession).
  public func QueueHardResetFor(playthroughId: CName) -> Void {
    this.m_resetRequested = true;
    this.m_resetFor = playthroughId;
  }

  // A reset still waiting for this playthrough, taken back (undoing a Start over before the game had a tick).
  public func CancelHardResetFor(playthroughId: CName) -> Void {
    if this.m_resetRequested && Equals(this.m_resetFor, playthroughId) {
      this.m_resetRequested = false;
      this.m_resetFor = n"";
    }
  }

  // Taken by the settled tick of the playthrough that is loaded.
  public func TakeHardResetRequest(playthroughId: CName) -> Bool {
    if !this.m_resetRequested {
      return false;
    }
    let forId = this.m_resetFor;
    this.m_resetRequested = false;
    this.m_resetFor = n"";
    if IsNameValid(forId) && NotEquals(forId, playthroughId) {
      CBLog.Info(n"Core", s"A reset asked for in playthrough \(NameToString(forId)) was not carried out in \(NameToString(playthroughId)).");
      return false;
    }
    return true;
  }

  // "This save is another character", chosen in Mod Settings. Same rules as a reset.
  public func RequestSeparate() -> Void {
    this.m_separateRequested = true;
    this.m_separateFor = this.m_sessionPlaythrough;
  }

  public func TakeSeparateRequest(playthroughId: CName) -> Bool {
    if !this.m_separateRequested {
      return false;
    }
    let forId = this.m_separateFor;
    this.m_separateRequested = false;
    this.m_separateFor = n"";
    if IsNameValid(forId) && NotEquals(forId, playthroughId) {
      CBLog.Info(n"Core", s"Separating a save, asked for in playthrough \(NameToString(forId)) was not carried out in \(NameToString(playthroughId)).");
      return false;
    }
    return true;
  }

  // Which playthrough is loaded. Set at session start and after a reset, cleared when the session
  // ends, so a request made from the main menu belongs to the next save rather than the last.
  public func SetSessionPlaythrough(playthroughId: CName) -> Void {
    this.m_sessionPlaythrough = playthroughId;
  }

  public func GetLogLevel() -> Int32 {
    return this.m_logLevel;
  }

  public func SetLogLevel(value: Int32) -> Void {
    this.m_logLevel = value;
  }
}
