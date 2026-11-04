import SwiftUI

/// Any other action: full width, a colored label on a soft fill. The danger version is for Cancel and Delete.
struct SecondaryButtonStyle: ButtonStyle {
    var isDanger = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.button)
            .foregroundStyle(isDanger ? Theme.Colors.danger : Theme.Colors.onTint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.xLarge)
            .frame(maxWidth: .infinity, minHeight: Theme.controlHeight)
            .background(
                isDanger ? Theme.Colors.dangerTint : Theme.Colors.tint,
                in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
            )
            .opacity(opacity(isPressed: configuration.isPressed))
            .contentShape(Rectangle())
    }

    private func opacity(isPressed: Bool) -> Double {
        guard isEnabled else { return Theme.disabledOpacity }
        return isPressed ? Theme.pressedOpacity : 1
    }
}

#Preview {
    LightAndDarkPreview {
        Button("Message Bea") {}
            .buttonStyle(SecondaryButtonStyle())
        Button("Cancel request") {}
            .buttonStyle(SecondaryButtonStyle(isDanger: true))
        Button("Reset demo data") {}
            .buttonStyle(SecondaryButtonStyle(isDanger: true))
            .disabled(true)
    }
}
