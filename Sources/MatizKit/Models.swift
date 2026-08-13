import Foundation

public struct Language: Hashable, Identifiable, Sendable {
    public let code: String
    public let name: String

    public var id: String { code }

    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}

public struct TranslationRequest: Sendable {
    public let sourceText: String
    public let sourceLanguage: Language
    public let targetLanguage: Language
    /// Country the translation should be localized for, e.g. "Mexico". Nil means no
    /// particular country.
    public let country: String?

    public init(sourceText: String, sourceLanguage: Language, targetLanguage: Language, country: String?) {
        self.sourceText = sourceText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.country = country
    }
}

public struct TranslationVariant: Decodable, Hashable, Identifiable, Sendable {
    public let text: String
    public let note: String

    public var id: String { text + "|" + note }

    public init(text: String, note: String) {
        self.text = text
        self.note = note
    }
}

public enum Catalog {
    public static var languages: [Language] { CountryLanguageDB.languages }

    /// English names of countries where the language is commonly spoken, most
    /// speakers first. Empty for languages without a strong country association
    /// (e.g. Esperanto, Latin).
    public static func countries(for language: Language) -> [String] {
        (CountryLanguageDB.countriesByLanguage[language.code] ?? [])
            .compactMap { CountryLanguageDB.countryNames[$0] }
    }
}
