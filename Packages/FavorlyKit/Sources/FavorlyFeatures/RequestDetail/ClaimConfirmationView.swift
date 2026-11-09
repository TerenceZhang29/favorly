import SwiftUI

/// The sheet that confirms claiming a request: what is being claimed, what happens next, and two buttons
/// within thumb reach. It replaces a confirmation dialog that iOS drew far from the Claim button.
struct ClaimConfirmationView: View {
    let title: String
    let requesterName: String
    /// "0.1 mi · Lobby of the library": the distance and where to meet, when known.
    let detailLine: String
    let onClaim: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xLarge) {
                Text("Claim this request?")
                    .textStyle(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                summary
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    point("eye", "\(requesterName) sees that you claimed it")
                    point("bubble.left.and.bubble.right", "You can message \(requesterName) right away")
                    point("checkmark", "It leaves Nearby, so no one else claims it")
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, Theme.Spacing.section)
            .padding(.bottom, Theme.Spacing.xLarge)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The buttons stay at the bottom, so they are reachable even when large text makes the sheet scroll.
        .safeAreaInset(edge: .bottom) {
            buttons
        }
        .background(GroveBackground())
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
    }

    private var buttons: some View {
        VStack(spacing: Theme.Spacing.small) {
            Button("Claim") {
                dismiss()
                onClaim()
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("claim.confirm")
            Button("Not now") { dismiss() }
                .textStyle(.button)
                .foregroundStyle(Theme.Colors.inkMuted)
                .frame(maxWidth: .infinity, minHeight: Theme.composerHeight)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityIdentifier("claim.cancel")
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, Theme.Spacing.medium)
        .background(Theme.Colors.background)
    }

    /// The request being claimed, as a small card.
    private var summary: some View {
        HStack(spacing: Theme.Spacing.large) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small / 2) {
                Text(title)
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Theme.Colors.ink)
                Text(detailLine.isEmpty ? requesterName : "\(requesterName) · \(detailLine)")
                    .textStyle(.meta)
                    .foregroundStyle(Theme.Colors.inkMuted)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.card)
        .background(CardBackground())
        .accessibilityElement(children: .combine)
    }

    private func point(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text)
                .textStyle(.body)
                .foregroundStyle(Theme.Colors.ink)
        } icon: {
            Image(systemName: symbol)
                .font(.system(size: Theme.IconSize.fact * Theme.IconSize.symbolScale, weight: .semibold))
                .foregroundStyle(Theme.Colors.onTint)
                .frame(width: Theme.IconSize.fact, height: Theme.IconSize.fact)
                .background(
                    Theme.Colors.tint,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                )
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    Text("Request")
        .sheet(isPresented: .constant(true)) {
            ClaimConfirmationView(
                title: "Need a cup of rice",
                requesterName: "Alex",
                detailLine: "< 0.1 mi · Lobby of the library"
            ) {}
        }
}
