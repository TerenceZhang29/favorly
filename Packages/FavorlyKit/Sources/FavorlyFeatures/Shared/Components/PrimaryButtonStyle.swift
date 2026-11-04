import SwiftUI

/// The one main action on a screen: full width, 56 points tall, filled with olive (lime in dark mode).
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.button)
            .foregroundStyle(isEnabled ? Theme.Colors.onBrand : Theme.Colors.inkMuted)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.xLarge)
            .frame(maxWidth: .infinity, minHeight: Theme.controlHeight)
            .background(
                isEnabled ? Theme.Colors.brand : Theme.Colors.segment,
                in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
            )
            .groveShadow(isEnabled ? Theme.Shadow.primary : Theme.Shadow.none)
            .opacity(configuration.isPressed ? Theme.pressedOpacity : 1)
            .contentShape(Rectangle())
    }
}

#Preview {
    LightAndDarkPreview {
        Button("Pick up") {}
        Button("Post request") {}
            .disabled(true)
    }
    .buttonStyle(PrimaryButtonStyle())
}
