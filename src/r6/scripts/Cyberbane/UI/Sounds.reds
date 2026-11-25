// Cyberbane - Sounds
//
// Cyberbane can only use sounds the game already has, and plays them the ways the game does: an interface sound through
// the audio system with no entity (the phone's typing, a pin on the map, loot, a perk bought), a voice line from
// a person's own voiceset (GameObject.PlayVoiceOver, so each sounds like who they are; a line their voiceset lacks stays
// silent), and a car's own horn (VehicleObject.ToggleHorn, on and off a moment later).

public func CBSoundsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().sounds;
}

// Real seconds, the clock the cooldowns run on.
func CBSoundNow(game: GameInstance) -> Float {
  let ts = GameInstance.GetTimeSystem(game);
  return IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
}

// May a sound with this key play now? Marks it played when it may.
public func CBSoundMay(game: GameInstance, key: CName, cooldown: Float) -> Bool {
  if CBPlayerInScene(game) || CBStoryHoldNow(game) {
    return false;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return false;
  }
  let now = CBSoundNow(game);
  let i = 0;
  while i < ArraySize(rt.soundKey) {
    if Equals(rt.soundKey[i], key) {
      if rt.soundAt[i] > 0.0 && now >= rt.soundAt[i] && now - rt.soundAt[i] < cooldown {
        return false;
      }
      rt.soundAt[i] = now;
      return true;
    }
    i += 1;
  }
  ArrayPush(rt.soundKey, key);
  ArrayPush(rt.soundAt, now);
  return true;
}

// The game's interface sounds that keep playing until the game sends their stop: each is started by something that ends
// later (a call coming in, a map time skip, a loading bar, a scroll) and stopped by that end, the ring by
// ui_phone_incoming_call_stop when the call is picked up, refused or over (phoneSystem.script, OnPickupPhone).
public func CBSoundLoopsUntilStopped(name: CName) -> Bool {
  return Equals(name, n"ui_phone_incoming_call") || Equals(name, n"ui_phone_initiation_call")
      || Equals(name, n"ui_loading_bar") || Equals(name, n"ui_main_menu_loop")
      || Equals(name, n"ui_menu_map_timeskip") || Equals(name, n"ui_menu_scrolling")
      || Equals(name, n"ui_main_menu_cc_loading") || Equals(name, n"ui_main_menu_cc_confirmation_screen_open");
}

// An interface sound, heard wherever V is. Only ever one that ends on its own.
public func CBUiSound(game: GameInstance, name: CName, key: CName, cooldown: Float) -> Bool {
  if CBSoundLoopsUntilStopped(name) {
    CBLog.Warn(n"Sounds", s"Refused \(NameToString(name)): it plays until the game stops it, and nothing would.");
    return false;
  }
  if !CBSoundsOn() || !CBSoundMay(game, key, cooldown) {
    return false;
  }
  let audio = GameInstance.GetAudioSystem(game);
  if !IsDefined(audio) {
    return false;
  }
  CBTrace("sound: one of the game's interface sounds");
  audio.Play(name);
  return true;
}

// A line in this person's own voice. `second`, when given, is said instead half the time: two lines a moment can use.
public func CBVoice(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>, line: CName, key: CName,
                    cooldown: Float, opt second: CName) -> Bool {
  if !CBVoicesOn() || !CBNpcSafe(sys, npc) || npc.IsDead() || !CBSoundMay(game, key, cooldown) {
    return false;
  }
  let said = IsNameValid(second) && RandF() < 0.5 ? second : line;
  CBTrace("voice: a game voiceset line for one of Cyberbane's moments");
  GameObject.PlayVoiceOver(npc, said, n"Scripts:CBStreetTalk");
  return true;
}

// The nearest standing person with this tag says it.
public func CBVoiceNearest(sys: ref<CyberbaneSystem>, game: GameInstance, tag: CName, within: Float, line: CName, key: CName,
                           cooldown: Float, opt second: CName) -> Bool {
  let p = CBNearestTagged(sys, game, tag, within);
  return IsDefined(p) && CBVoice(sys, game, p, line, key, cooldown, second);
}

// A car's horn as it pulls up: on now, off a moment later (DelaySystem, the next safe frame for anything it touches).
public class CBHornOffCallback extends DelayCallback {
  public let car: wref<VehicleObject>;
  public func Call() -> Void {
    if IsDefined(this.car) && this.car.IsAttached() {
      this.car.ToggleHorn(false);
    }
  }
}

public func CBCarHorn(game: GameInstance, car: wref<VehicleObject>, key: CName, cooldown: Float) -> Bool {
  if !CBSoundsOn() || !IsDefined(car) || !car.IsAttached() || !CBSoundMay(game, key, cooldown) {
    return false;
  }
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) {
    return false;
  }
  CBTrace("sound: a car of ours sounds its horn");
  car.ToggleHorn(true);
  let off = new CBHornOffCallback();
  off.car = car;
  ds.DelayCallback(off, 0.7, false);
  return true;
}

// ---- The moments ----------------------------------------------------------------------------------------------------

// An apex squad is coming: the game's sting for being marked for MaxTac.
public func CBApexWarningSound(game: GameInstance) -> Void {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().apexArrivalSound {
    return;
  }
  CBUiSound(game, n"gmp_ui_prevention_player_marked_psycho", n"ApexWarning", 30.0);
}

// V's crew warns V of what has just turned up, in their own voices: an apex squad, a heavy, a netrunner, a crew.
public func CBCrewWarnVoice(sys: ref<CyberbaneSystem>, game: GameInstance, line: CName) -> Void {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || book.OutCount() == 0 {
    return;
  }
  let i = 0;
  while i < book.OutCount() {
    if book.outSeen[i] && !book.outDown[i] {
      let p = GameInstance.FindEntityByID(game, book.outBody[i]) as ScriptedPuppet;
      if CBNpcSafe(sys, p) && CBStillStanding(p) {
        CBVoice(sys, game, p, line, n"CrewWarn", 25.0);
        return;
      }
    }
    i += 1;
  }
}

// The warning a crew member gives for this enemy: an apex squad's, a heavy's, a netrunner's, a sniper's, else "danger".
public func CBEnemyWarning(game: GameInstance, des: ref<DynamicEntitySystem>, p: ref<ScriptedPuppet>) -> CName {
  if !IsDefined(p) {
    return n"danger";
  }
  if IsDefined(des) && des.IsTagged(p.GetEntityID(), n"CB_Apex") {
    return n"elite_warning";
  }
  let rec = p.GetRecordID();
  let name = TDBID.ToStringDEBUG(rec);
  if StrContains(name, "sniper") {
    return n"sniper_warning";
  }
  if StrContains(name, "netrunner") {
    return n"netrunner_warning";
  }
  let role: ECBApexRole;
  if CBArchetypeRole(CBRecordArchetype(rec), role) {
    if Equals(role, ECBApexRole.Tank) { return n"heavy_warning"; }
    if Equals(role, ECBApexRole.Netrunner) { return n"netrunner_warning"; }
  }
  return n"danger";
}

// Somebody of ours just turned up near V: hunters shout as they come round the corner, so V hears them first, and V's crew
// says what they are.
public func CBArrivalVoices(sys: ref<CyberbaneSystem>, game: GameInstance, tag: CName) -> Void {
  CBVoiceNearest(sys, game, tag, 60.0, n"start_combat", n"HuntersShout", 20.0);
  if Equals(tag, n"CB_Apex") {
    CBCrewWarnVoice(sys, game, n"elite_warning");
  } else {
    CBCrewWarnVoice(sys, game, n"danger");
  }
}
