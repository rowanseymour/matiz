import SwiftUI

struct SettingsView: View {
    @AppStorage("claudeModel") private var claudeModel = "haiku"

    var body: some View {
        Form {
            Picker("Model", selection: $claudeModel) {
                Text("Haiku (fast)").tag("haiku")
                Text("Sonnet").tag("sonnet")
                Text("Opus").tag("opus")
            }
            Text("Translations run through the `claude` CLI, so it must be installed and logged in.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 340)
    }
}
