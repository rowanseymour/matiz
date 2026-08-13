import AppKit
import MatizKit
import SwiftUI

struct ContentView: View {
    @State private var model = TranslationViewModel()
    @AppStorage("claudeModel") private var claudeModel = "haiku"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            languageBar

            TextEditor(text: $model.sourceText)
                .font(.system(.body))
                .frame(minHeight: 100, maxHeight: 160)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))

            HStack {
                Button(action: { model.translate(model: claudeModel) }) {
                    Label("Translate", systemImage: "sparkles")
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!model.canTranslate)

                if model.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(model.variants) { variant in
                        VariantRow(variant: variant)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    private var languageBar: some View {
        HStack(spacing: 8) {
            Picker("From", selection: $model.sourceLanguage) {
                ForEach(Catalog.languages) { Text($0.name).tag($0) }
            }
            .fixedSize()

            Button(action: model.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.borderless)
            .help("Swap languages")

            Picker("To", selection: $model.targetLanguage) {
                ForEach(Catalog.languages) { Text($0.name).tag($0) }
            }
            .fixedSize()

            if !model.countryOptions.isEmpty {
                Picker("Country", selection: $model.country) {
                    ForEach(model.countryOptions, id: \.self) { Text($0).tag($0) }
                    Text("Any").tag("")
                }
                .fixedSize()
            }

            Spacer()
        }
    }
}

private struct VariantRow: View {
    let variant: TranslationVariant
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.text)
                    .font(.system(.body))
                    .textSelection(.enabled)
                Text(variant.note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: copy) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(variant.text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
    }
}
