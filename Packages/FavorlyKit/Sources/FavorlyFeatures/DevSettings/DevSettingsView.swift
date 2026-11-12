import FavorlyCore
import SwiftUI

struct DevSettingsView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var isResetting = false
    @State private var isSimulating = false
    /// What the last "Receive a message" did.
    @State private var simulatedMessage: String?

    var body: some View {
        Form {
            Section {
                Text(environment.debugSummary)
                    .accessibilityIdentifier("devSettings.summary")
            } footer: {
                Text("Prototype only. Nothing here ships to real users.")
                    .textStyle(.meta)
                    .foregroundStyle(Theme.Colors.inkMuted)
            }
            .groveRows()

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
                .groveRows()
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
                .groveRows()
            }

            if environment.session is any DemoSessionControls {
                Section {
                    Button("Receive a message") {
                        Task {
                            isSimulating = true
                            simulatedMessage = await DevMessageSimulator.receiveMessage(in: environment)
                            isSimulating = false
                        }
                    }
                    .disabled(isSimulating)
                    .accessibilityIdentifier("devSettings.receiveMessage")
                } header: {
                    Text("Messages")
                } footer: {
                    if let simulatedMessage {
                        Text(simulatedMessage)
                            .textStyle(.meta)
                            .foregroundStyle(Theme.Colors.inkMuted)
                            .accessibilityIdentifier("devSettings.receiveMessage.result")
                    }
                }
                .groveRows()
            }

            Section("Data") {
                Button("Reset demo data", role: .destructive) {
                    Task {
                        isResetting = true
                        await environment.repository.reset()
                        isResetting = false
                    }
                }
                .buttonStyle(SecondaryButtonStyle(isDanger: true))
                .disabled(isResetting)
                .accessibilityIdentifier("devSettings.resetDemoData")
                .plainListRow()
            }
        }
        .groveListBackground()
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
