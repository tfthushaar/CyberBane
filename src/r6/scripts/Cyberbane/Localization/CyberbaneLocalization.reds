// Cyberbane - Localization (spec §15), via Codeware localization.
//
// This file carries a module header so it can import Codeware's localization types. The provider registers itself
// automatically (ModLocalizationProvider queues its registration in OnAttach).

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

// The translation for a language, if one is installed: a package class whose name ends in CyberbaneText_<language>.
func CBFindTranslation(language: CName) -> ref<ModLocalizationPackage> {
  let want = "CyberbaneText_" + StrReplaceAll(NameToString(language), "-", "_");
  let classes = Reflection.GetDerivedClasses(n"Codeware.Localization.ModLocalizationPackage");
  if ArraySize(classes) == 0 {
    classes = Reflection.GetDerivedClasses(n"ModLocalizationPackage");
  }
  for cls in classes {
    if IsDefined(cls) && !cls.IsAbstract() && !cls.IsNative() && StrEndsWith(NameToString(cls.GetName()), want)
       && (cls.IsA(n"Codeware.Localization.ModLocalizationPackage") || cls.IsA(n"ModLocalizationPackage")) {
      // The compiler warns this cast "cannot succeed": MakeHandle is declared to hand back
      // an ISerializable, and the two patches' scripts disagree on how IScriptable relates to it (2.5 calls them
      // unrelated, 2.31 calls a cast between them redundant), so no static cast is quiet on both. `as` is checked at
      // run time against the object's own class, which is the translator's package, so it holds; the log says either
      // way, for the first translation anybody tests.
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
