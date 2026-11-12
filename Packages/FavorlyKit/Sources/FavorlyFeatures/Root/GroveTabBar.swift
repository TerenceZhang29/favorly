import SwiftUI

/// The mockup's floating tab bar: a rounded white card with an icon and label per tab. The selected tab shows
/// its filled icon in the brand color and a bold label. Each tab is a button VoiceOver reads as selected. A tab can
/// carry a badge, such as the Messages tab's unread count.
struct GroveTabBar: View {
    let tabs: [RootTab]
    @Binding var selection: RootTab
    var badges: [RootTab: String] = [:]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                let isSelected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: Theme.Spacing.small / 2) {
                        Image(systemName: isSelected ? tab.selectedSystemImage : tab.systemImage)
                            .font(.system(size: Theme.IconSize.tabSymbol, weight: .semibold))
                            .foregroundStyle(isSelected ? Theme.Colors.brand : Theme.Colors.inkMuted)
                            .frame(height: Theme.IconSize.tabSymbol + Theme.Spacing.small)
                            .overlay(alignment: .topTrailing) {
                                if let badge = badges[tab] {
                                    TabBadge(text: badge)
                                }
                            }
                        Text(tab.title)
                            .textStyle(isSelected ? .tabSelected : .tab)
                            .foregroundStyle(isSelected ? Theme.Colors.ink : Theme.Colors.inkMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(Theme.tabLabelMinimumScale)
                    }
                    .frame(maxWidth: .infinity, minHeight: Theme.tabBarHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // Like the system tab bar: labels stop growing at the largest standard size, and a long press
                // at accessibility sizes shows the tab enlarged.
                .accessibilityShowsLargeContentViewer {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .accessibilityLabel(tab.title)
                .accessibilityValue(badges[tab].map { "\($0) unread" } ?? "")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
        .dynamicTypeSize(...Theme.tabBarMaxTypeSize)
        .padding(.horizontal, Theme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.tabBar, style: .continuous)
                .fill(Theme.Colors.surface)
                .strokeBorder(Theme.Colors.surfaceBorder, lineWidth: Theme.borderWidth)
                .groveShadow(Theme.Shadow.card)
        )
        .padding(.horizontal, Theme.Spacing.xLarge)
        .padding(.top, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.small)
    }
}

#Preview {
    LightAndDarkPreview {
        GroveTabBar(tabs: RootTab.tabs(showingDevSettings: false), selection: .constant(.nearby))
    }
}
