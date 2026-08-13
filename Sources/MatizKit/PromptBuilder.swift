import Foundation

public enum PromptBuilder {
    public static func prompt(for request: TranslationRequest) -> String {
        let target: String
        if let country = request.country, !country.isEmpty {
            target = "\(request.targetLanguage.name) as used in \(country)"
        } else {
            target = request.targetLanguage.name
        }

        return """
        You are a professional translator. Translate the source text from \(request.sourceLanguage.name) to \(target).

        Provide 1 to 3 distinct variants, most recommended first. Only include variants that differ in a way \
        that matters to the user — register, tone, or regional wording. Each variant gets a short note \
        (2-6 words, in English) explaining what sets it apart, e.g. "more formal", "casual, spoken", \
        "neutral, safe default".

        Respond with ONLY strict JSON, no markdown fences, no commentary, in exactly this shape:
        {"variants":[{"text":"...","note":"..."}]}

        Source text:
        \(request.sourceText)
        """
    }
}
