import Foundation
import MatizKit
import SwiftUI

@MainActor
@Observable
final class TranslationViewModel {
    var sourceText = ""
    var sourceLanguage = Catalog.languages.first { $0.code == "en" }!
    var targetLanguage = Catalog.languages.first { $0.code == "es" }! {
        didSet { country = Catalog.countries(for: targetLanguage).first ?? "" }
    }
    var country = Catalog.countries(for: Catalog.languages.first { $0.code == "es" }!).first ?? ""

    private(set) var variants: [TranslationVariant] = []
    private(set) var isTranslating = false
    private(set) var errorMessage: String?

    var countryOptions: [String] { Catalog.countries(for: targetLanguage) }

    var canTranslate: Bool {
        !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranslating
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
            country: country.isEmpty ? nil : country
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
