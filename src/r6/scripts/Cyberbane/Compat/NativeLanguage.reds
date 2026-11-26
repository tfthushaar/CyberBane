// Cyberbane - The language V speaks
//
// Cyberbane's own recordings of V are English, so they play only while V speaks English: the language Change V's Native
// Language gives V when it is set, otherwise the game's voice-over language. V's voiceset lines and everybody else's go
// through the game, where that mod and Cosmopolitan Night City switch them to the right language themselves.

// Change V's Native Language keeps V's language in Mod Settings under these keys, as its own ids: 0 Off, 3 English.
public func CBCvlMod() -> CName = n"CVL-nttn-Main-Title"
public func CBCvlLabel() -> CName = n"CVL-nttn-Main-NativeLanguage"
public func CBCvlEnglish() -> Int32 = 3

// V's language as that mod has it: 0 when it leaves V alone, -1 when it is not installed.
public func CBCvlLanguage() -> Int32 {
  let catalog = Reflection.GetClass(n"CVLNttnPackCatalog");
  if !IsDefined(catalog) {
    return -1;
  }
  let value = CBModSettingsEnumByLabel(CBCvlMod(), CBCvlLabel());
  if value <= 0 {
    return 0;
  }
  // A language whose pack was removed is Off to that mod as well.
  let available = catalog.GetStaticFunction(n"IsAvailable");
  if IsDefined(available) && CBReflectReturns(available, n"Bool") {
    let params = available.GetParameters();
    if ArraySize(params) == 1 && IsDefined(params[0]) {
      let ptype = params[0].GetType();
      if IsDefined(ptype) && Equals(ptype.GetName(), n"Int32") {
        let args: array<Variant>;
        ArrayPush(args, ToVariant(value));
        if !FromVariant<Bool>(available.Call(args)) {
          return 0;
        }
      }
    }
  }
  return value;
}

// The game's voice-over language, as its settings name it ("en-us", "jp-jp").
public func CBGameVoiceLanguage(game: GameInstance) -> CName {
  let settings = GameInstance.GetSettingsSystem(game);
  if !IsDefined(settings) || !settings.HasVar(n"/language", n"VoiceOver") {
    return n"en-us";
  }
  let vo = settings.GetVar(n"/language", n"VoiceOver") as ConfigVarListName;
  return IsDefined(vo) ? vo.GetValue() : n"en-us";
}

public func CBVSpeaksEnglish(game: GameInstance) -> Bool {
  let cvl = CBCvlLanguage();
  let lang = CBGameVoiceLanguage(game);
  let english = cvl > 0 ? cvl == CBCvlEnglish() : Equals(lang, n"en-us");
  let rt = CyberbaneRuntime.Get();
  let said = english ? 1 : 2;
  if IsDefined(rt) && rt.vLanguageSaid != said {
    rt.vLanguageSaid = said;
    if english {
      CBLog.Info(n"Talk", "V speaks English: V's recorded lines play.");
    } else {
      if cvl > 0 {
        CBLog.Info(n"Talk", s"Change V's Native Language gives V language \(cvl): V's English recordings stay silent, V's voiceset still speaks through the game.");
      } else {
        CBLog.Info(n"Talk", s"The game's voice-over language is \(NameToString(lang)): V's English recordings stay silent, V's voiceset still speaks through the game.");
      }
    }
  }
  return english;
}
