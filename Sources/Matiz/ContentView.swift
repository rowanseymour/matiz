import AppKit
import MatizKit
import SwiftUI

struct ContentView: View {
    @State private var model = TranslationViewModel()
    @AppStorage("claudeModel") private var claudeModel = "haiku"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            languageBar

            sourceEditor

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

                Text("\(model.sourceText.count)/\(TranslationRequest.maxSourceLength)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(model.remainingCharacters == 0 ? .red : .secondary)
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
        .frame(minHeight: 380)
        .task { await runScreenshotMode() }
    }

    /// Drives the README screenshot for `bin/screenshot`: prefills the sample text the
    /// script passes in, centers the window (at its default size, so the shot shows
    /// what a new window looks like) and translates on launch. Once the variants are on screen it brings the app
    /// forward — an inactive window is captured with a grey title bar and a flatter
    /// shadow — and says so on stdout, which is the script's cue to capture.
    private func runScreenshotMode() async {
        guard let sample = ProcessInfo.processInfo.environment["MATIZ_SCREENSHOT"] else { return }

        NSApp.appearance = NSAppearance(named: .aqua)  // same look whatever time of day it's run
        NSApp.windows.first?.center()
        model.sourceText = sample
        model.translate(model: claudeModel)

        while model.isTranslating {
            try? await Task.sleep(for: .milliseconds(200))
        }
        NSApp.windows.first?.makeFirstResponder(nil)  // no caret in the shot
        NSApp.activate(ignoringOtherApps: true)
        print("screenshot: ready")
        fflush(stdout)
    }

    /// Deliberately small: two lines and a hard character cap, so it reads as a place
    /// for a phrase or sentence rather than a document.
    private var sourceEditor: some View {
        TextEditor(text: $model.sourceText)
            .font(.system(.body))
            .frame(height: 40)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))
            .overlay(alignment: .topLeading) {
                if model.sourceText.isEmpty {
                    Text("Phrase or sentence to translate")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .allowsHitTesting(false)
                }
            }
    }

    /// From ⇄ To @ Country, kept tight: the labels sit outside the pickers so the
    /// pickers' frames don't pad out the gaps between them. The bar is fixed at its
    /// natural width so the labels can't be squeezed out, and so the window (which
    /// sizes to its content) can't be narrower than this row.
    private var languageBar: some View {
        HStack(spacing: 6) {
            Text("From")
            languagePicker(selection: $model.sourceLanguage)

            Button(action: model.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.borderless)
            .help("Swap languages")

            Text("To")
            languagePicker(selection: $model.targetLanguage)

            if !model.countryOptions.isEmpty {
                Text("@")
                    .foregroundStyle(.secondary)
                    .help("Country")
                Picker("Country", selection: $model.country) {
                    ForEach(model.countryOptions) { country in
                        Text("\(country.flag)  \(country.name)").tag(Country?.some(country))
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }
        }
        .fixedSize()
    }

    private func languagePicker(selection: Binding<Language>) -> some View {
        Picker("Language", selection: selection) {
            ForEach(Catalog.languages) { Text($0.name).tag($0) }
        }
        .labelsHidden()
        .frame(width: 150)
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
