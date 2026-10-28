import FavorlyCore
import SwiftUI

struct DevSettingsView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var isResetting = false

    var body: some View {
        Form {
            Section {
                Text(environment.debugSummary)
                    .accessibilityIdentifier("devSettings.summary")
            } footer: {
                Text("Prototype only. Nothing here ships to real users.")
                    .foregroundStyle(.secondary)
            }

            if let controls = environment.session as? any DemoSessionControls {
                Section("Current user") {
                    ForEach(controls.availableUsers) { user in
                        Button {
                            controls.switchUser(to: user.id)
                        } label: {
                            SelectableRow(
                                title: user.displayName,
                                subtitle: user.neighborhood,
                                isSelected: user.id == environment.session.currentUser.id
                            )
                        }
                        .accessibilityIdentifier("devSettings.user.\(user.id.rawValue)")
                    }
                }
            }

            if let settings = environment.locationSettings {
                Section("Fake location") {
                    ForEach(settings.presets) { preset in
                        Button {
                            settings.selectedPreset = preset
                        } label: {
                            SelectableRow(
                                title: preset.location.label,
                                isSelected: preset.id == settings.selectedPreset.id
                            )
                        }
                        .accessibilityIdentifier("devSettings.location.\(preset.id)")
                    }
                    Toggle("Simulate location error", isOn: simulatesError(in: settings))
                        .accessibilityIdentifier("devSettings.simulateLocationError")
                }
            }

            Section("Data") {
                Button("Reset demo data", role: .destructive) {
                    Task {
                        isResetting = true
                        await environment.repository.reset()
                        isResetting = false
                    }
                }
                .buttonStyle(SecondaryButtonStyle(color: Theme.Colors.statusCancelled))
                .disabled(isResetting)
                .accessibilityIdentifier("devSettings.resetDemoData")
                .plainListRow()
            }
        }
        .navigationTitle("Dev Settings")
    }

    private func simulatesError(in settings: any LocationSettings) -> Binding<Bool> {
        Binding(
            get: { settings.simulatesError },
            set: { settings.simulatesError = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        DevSettingsView()
    }
}
