import Foundation

public protocol TranslationService: Sendable {
    func translate(_ request: TranslationRequest) async throws -> [TranslationVariant]
}

public enum TranslationError: LocalizedError {
    case emptySource
    case backendFailed(String)
    case badResponse(String)

    public var errorDescription: String? {
        switch self {
        case .emptySource:
            return "Nothing to translate."
        case .backendFailed(let message):
            return message
        case .badResponse(let message):
            return "Couldn't read the translation response: \(message)"
        }
    }
}
