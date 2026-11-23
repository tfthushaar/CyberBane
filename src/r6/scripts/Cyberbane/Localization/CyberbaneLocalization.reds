// Cyberbane - Localization (spec §15), via Codeware localization.
//
// This file carries a module header so it can import Codeware's localization types. The provider registers itself
// automatically (ModLocalizationProvider queues its registration in OnAttach). Keys follow Cyberbane-<Area>-<Id>; the
// English for every one of them is in Localization/en-us/English.reds, and the code looks them up through CBT and CBTf
// (Localization/Text.reds).
//
// English is the fallback language: Codeware lays it down first and the player's language over it, key by key, so a key a
// translation does not have yet shows in English.
//
// Another language is a package of the translator's own, found by its class name (2.7.1). Codeware merges every provider's
// texts, but for each provider it lays down that provider's fallback first (LocalizationSystem.FillTranslationData), so a
// translation registered as a second provider would have this one's English written over it whenever this one ran after it.
// So a translation is a package, not a provider: a class extending ModLocalizationPackage named CyberbaneText_<language>,
// the language with its dash as an underscore (CyberbaneText_de_de for de-de, CyberbaneText_pt_br for pt-br), in a module
// of the translator's choosing. It ships as a folder of its own beside Cyberbane's, so an update of Cyberbane never
// overwrites it. How to make one: the top of Localization/en-us/English.reds.

module Cyberbane.Localization

import Codeware.Localization.*

public class CBLocalizationProvider extends ModLocalizationProvider {
  // Each language's package is built once a session: its DefineTexts is the whole of the mod's text, and Codeware asks
  // for a package more than once (for its own lookup and for the game's).
  private let m_english: ref<ModLocalizationPackage>;
  private let m_langs: array<CName>;
  private let m_packs: array<ref<ModLocalizationPackage>>;

  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    if Equals(language, n"en-us") {
      if !IsDefined(this.m_english) {
        this.m_english = new CBLocalizationEnUs();
      }
      return this.m_english;
    }
    let i = ArrayFindFirst(this.m_langs, language);
    if i >= 0 && i < ArraySize(this.m_packs) {
      return this.m_packs[i];
    }
    let found = CBFindTranslation(language);
    ArrayPush(this.m_langs, language);
    ArrayPush(this.m_packs, found);
    return found;
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

// The translation for a language, if one is installed: a package class whose name ends in CyberbaneText_<language>. Asked of
// the classes that extend Codeware's package, by their full name first, the one a module gives Codeware's classes.
//
// Made as a handle (2.7.4). It was made with MakeInstance, which hands back the object inside a Variant, and read out as a
// ref<ModLocalizationPackage>: the Variant held the translator's own class, not a handle of Codeware's, and reading it as
// one crashed the game the moment a translation was installed (a Polish package, CyberbaneText_pl_pl). MakeHandle makes the
// object as a handle, the way Codeware itself makes one by name, and `as` hands back nothing for a class that is not a
// package, so a misnamed translation is ignored, never a crash.
func CBFindTranslation(language: CName) -> ref<ModLocalizationPackage> {
  let want = "CyberbaneText_" + StrReplaceAll(NameToString(language), "-", "_");
  let classes = Reflection.GetDerivedClasses(n"Codeware.Localization.ModLocalizationPackage");
  if ArraySize(classes) == 0 {
    classes = Reflection.GetDerivedClasses(n"ModLocalizationPackage");
  }
  for cls in classes {
    if IsDefined(cls) && !cls.IsAbstract() && !cls.IsNative() && StrEndsWith(NameToString(cls.GetName()), want)
       && (cls.IsA(n"Codeware.Localization.ModLocalizationPackage") || cls.IsA(n"ModLocalizationPackage")) {
      // The compiler warns this cast "cannot succeed" (2.7.5, the nomad expansion's R2): MakeHandle is declared to hand back
      // an ISerializable, and the two patches' scripts disagree on how IScriptable relates to it (2.5 calls them unrelated,
      // 2.31 calls a cast between them redundant), so no static cast is quiet on both. `as` is checked at run time against
      // the object's own class, which is the translator's package, so it holds; the log says either way, for the first
      // translation anybody tests.
      let pkg = cls.MakeHandle() as ModLocalizationPackage;
      if IsDefined(pkg) {
        FTLog(s"[Cyberbane][Localization] Translation for \(NameToString(language)) loaded from \(NameToString(cls.GetName())).");
        return pkg;
      }
      FTLog(s"[Cyberbane][Localization] Translation class \(NameToString(cls.GetName())) found for \(NameToString(language)), but it could not be made: English stays.");
    }
  }
  return null;
}
