import Foundation
import MatizKit

var failures = 0

@MainActor
func expect(_ condition: Bool, _ label: String) {
    if condition {
        print("PASS \(label)")
    } else {
        print("FAIL \(label)")
        failures += 1
    }
}

@MainActor
func expectThrows(_ label: String, _ body: () throws -> Void) {
    do {
        try body()
        print("FAIL \(label) (no error thrown)")
        failures += 1
    } catch {
        print("PASS \(label)")
    }
}

// VariantParser

do {
    let output = #"{"variants":[{"text":"Hola","note":"casual"},{"text":"Buenos días","note":"more formal"}]}"#
    let variants = try VariantParser.parse(output)
    expect(variants.count == 2 && variants[0].text == "Hola" && variants[1].note == "more formal",
           "parses plain JSON")
} catch { expect(false, "parses plain JSON") }

do {
    let output = "```json\n{\"variants\":[{\"text\":\"Hola\",\"note\":\"casual\"}]}\n```"
    expect(try VariantParser.parse(output).count == 1, "parses fenced JSON")
} catch { expect(false, "parses fenced JSON") }

do {
    let output = #"Here you go: {"variants":[{"text":"Salut","note":"casual"}]} Hope that helps!"#
    expect(try VariantParser.parse(output).count == 1, "parses JSON with surrounding prose")
} catch { expect(false, "parses JSON with surrounding prose") }

do {
    let items = (1...6).map { #"{"text":"v\#($0)","note":"n"}"# }.joined(separator: ",")
    expect(try VariantParser.parse(#"{"variants":[\#(items)]}"#).count == 3, "caps at three variants")
} catch { expect(false, "caps at three variants") }

expectThrows("rejects non-JSON") { _ = try VariantParser.parse("Sorry, I can't help with that.") }
expectThrows("rejects empty variants") { _ = try VariantParser.parse(#"{"variants":[]}"#) }

// PromptBuilder

let english = Language(code: "en", name: "English")
let spanish = Language(code: "es", name: "Spanish")

let withCountry = PromptBuilder.prompt(for: TranslationRequest(
    sourceText: "Hello", sourceLanguage: english, targetLanguage: spanish, country: "Mexico"))
expect(withCountry.contains("Spanish as used in Mexico") && withCountry.contains("Hello"),
       "prompt includes country when set")

let withoutCountry = PromptBuilder.prompt(for: TranslationRequest(
    sourceText: "Hello", sourceLanguage: english, targetLanguage: spanish, country: nil))
expect(!withoutCountry.contains("as used in"), "prompt omits country when nil")

// Shell quoting

expect(ClaudeCLITranslator.shellQuote("it's") == #"'it'\''s'"#, "shell-quotes single quotes")
expect(ClaudeCLITranslator.shellQuote("haiku") == "'haiku'", "shell-quotes plain string")

// Catalog / CountryLanguageDB

expect(Catalog.languages.count >= 100, "catalog has 100+ languages (\(Catalog.languages.count))")
expect(Catalog.languages.contains { $0.code == "en" } && Catalog.languages.contains { $0.code == "es" },
       "catalog includes English and Spanish")
expect(Catalog.languages.contains { $0.name == "Chinese (Traditional)" },
       "catalog distinguishes Traditional Chinese")
expect(Catalog.countries(for: spanish).first == "Mexico", "Mexico first for Spanish (most speakers)")
expect(Catalog.countries(for: spanish).contains("Ecuador"), "Ecuador listed for Spanish")
expect(Catalog.countries(for: Language(code: "ja", name: "Japanese")) == ["Japan"],
       "Japan is the only country for Japanese")
expect(CountryLanguageDB.languagesByCountry["CA"]?.contains("fr") == true,
       "Canada speaks French")

let allLanguageCodes = Set(CountryLanguageDB.languages.map(\.code))
expect(CountryLanguageDB.countriesByLanguage.keys.allSatisfy { allLanguageCodes.contains($0) },
       "every mapped language exists in the language list")
expect(CountryLanguageDB.countriesByLanguage.values.allSatisfy { countries in
    countries.allSatisfy { CountryLanguageDB.countryNames[$0] != nil }
}, "every mapped country has a name")

// CLI resolution (machine-dependent, but this app is useless without the CLI)

let cliPath = ClaudeCLITranslator.locateCLI()
expect(cliPath != nil, "locates claude CLI (found: \(cliPath ?? "none"))")

if failures > 0 {
    print("\n\(failures) check(s) failed")
    exit(1)
}
print("\nAll checks passed")
