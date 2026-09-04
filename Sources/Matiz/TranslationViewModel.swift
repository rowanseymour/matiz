import Foundation
import MatizKit
import SwiftUI

@MainActor
@Observable
final class TranslationViewModel {
    private static let defaultSourceLanguage = Catalog.languages.first { $0.code == "en" }!
    private static let defaultTargetLanguage = Catalog.languages.first { $0.code == "es" }!

    var sourceText = "" {
        didSet {
            let clamped = TranslationRequest.clampSource(sourceText)
            if clamped != sourceText { sourceText = clamped }
        }
    }
    var sourceLanguage = TranslationViewModel.savedLanguage(forKey: "lastSourceLanguage", default: defaultSourceLanguage) {
        didSet { UserDefaults.standard.set(sourceLanguage.code, forKey: "lastSourceLanguage") }
    }
    var targetLanguage = TranslationViewModel.savedLanguage(forKey: "lastTargetLanguage", default: defaultTargetLanguage) {
        didSet {
            UserDefaults.standard.set(targetLanguage.code, forKey: "lastTargetLanguage")
            country = Catalog.defaultCountry(for: targetLanguage)
        }
    }
    var country = TranslationViewModel.savedCountry(
        forKey: "lastCountry",
        language: TranslationViewModel.savedLanguage(forKey: "lastTargetLanguage", default: defaultTargetLanguage)
    ) {
        didSet { UserDefaults.standard.set(country?.code, forKey: "lastCountry") }
    }

    private(set) var variants: [TranslationVariant] = []
    private(set) var isTranslating = false
    private(set) var errorMessage: String?

    var countryOptions: [Country] { Catalog.countries(for: targetLanguage) }

    var remainingCharacters: Int { TranslationRequest.maxSourceLength - sourceText.count }

    var canTranslate: Bool {
        !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranslating
    }

    private static func savedLanguage(forKey key: String, default: Language) -> Language {
        guard let code = UserDefaults.standard.string(forKey: key) else { return `default` }
        return Catalog.languages.first { $0.code == code } ?? `default`
    }

    private static func savedCountry(forKey key: String, language: Language) -> Country? {
        guard let code = UserDefaults.standard.string(forKey: key),
              let saved = Catalog.countries(for: language).first(where: { $0.code == code })
        else {
            return Catalog.defaultCountry(for: language)
        }
        return saved
    }

    func swapLanguages() {
        let source = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = source
    }

    func translate(model: String) {
        guard canTranslate else { return }
        let request = TranslationRequest(
            sourceText: sourceText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            country: country?.name
        )
        let service = ClaudeCLITranslator(model: model)

        isTranslating = true
        errorMessage = nil
        variants = []

        Task {
            do {
                variants = try await service.translate(request)
            } catch {
                errorMessage = error.localizedDescription
            }
            isTranslating = false
        }
    }
}
