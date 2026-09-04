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

public struct Country: Hashable, Identifiable, Sendable {
    /// ISO 3166-1 alpha-2 code, e.g. "MX".
    public let code: String
    /// English name, e.g. "Mexico".
    public let name: String

    public var id: String { code }

    /// Flag emoji built from the code's regional indicator symbols. A handful of
    /// codes have no flag glyph and render as their letters instead.
    public var flag: String {
        String(String.UnicodeScalarView(code.unicodeScalars.compactMap {
            Unicode.Scalar($0.value - 0x41 + 0x1F1E6)
        }))
    }

    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}

public struct TranslationRequest: Sendable {
    /// Matiz translates phrases and sentences, not documents, so source text is kept
    /// short enough for that: roughly a couple of sentences.
    public static let maxSourceLength = 200

    /// Trims `text` to `maxSourceLength` characters, or returns it as-is if it fits.
    public static func clampSource(_ text: String) -> String {
        text.count > maxSourceLength ? String(text.prefix(maxSourceLength)) : text
    }

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

    /// Countries where the language is commonly spoken, sorted by name. Empty for
    /// languages without a strong country association (e.g. Esperanto, Latin).
    public static func countries(for language: Language) -> [Country] {
        countriesBySpeakers(for: language)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The country to preselect for a language: the one with the most speakers.
    public static func defaultCountry(for language: Language) -> Country? {
        countriesBySpeakers(for: language).first
    }

    private static func countriesBySpeakers(for language: Language) -> [Country] {
        (CountryLanguageDB.countriesByLanguage[language.code] ?? [])
            .compactMap { code in
                CountryLanguageDB.countryNames[code].map { Country(code: code, name: $0) }
            }
    }
}
