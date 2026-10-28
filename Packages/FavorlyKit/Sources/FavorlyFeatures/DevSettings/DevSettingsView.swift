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

            Section("Fake location") {
                ForEach(environment.locationSettings.presets) { preset in
                    Button {
                        environment.locationSettings.selectedPreset = preset
                    } label: {
                        SelectableRow(
                            title: preset.location.label,
                            isSelected: preset.id == environment.locationSettings.selectedPreset.id
                        )
                    }
                    .accessibilityIdentifier("devSettings.location.\(preset.id)")
                }
                Toggle("Simulate location error", isOn: simulatesError)
                    .accessibilityIdentifier("devSettings.simulateLocationError")
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

    private var simulatesError: Binding<Bool> {
        Binding(
            get: { environment.locationSettings.simulatesError },
            set: { environment.locationSettings.simulatesError = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        DevSettingsView()
    }
}
