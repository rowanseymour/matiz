import Foundation

public enum VariantParser {
    private struct Response: Decodable {
        let variants: [TranslationVariant]
    }

    /// Parses model output into variants, tolerating markdown fences or stray prose
    /// around the JSON object.
    public static func parse(_ output: String) throws -> [TranslationVariant] {
        guard let start = output.firstIndex(of: "{"), let end = output.lastIndex(of: "}"), start < end else {
            throw TranslationError.badResponse(String(output.prefix(200)))
        }
        let json = output[start...end]
        do {
            let response = try JSONDecoder().decode(Response.self, from: Data(json.utf8))
            let variants = response.variants.filter { !$0.text.isEmpty }
            guard !variants.isEmpty else {
                throw TranslationError.badResponse("no variants returned")
            }
            return Array(variants.prefix(3))
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.badResponse(String(output.prefix(200)))
        }
    }
}
