import SwiftUI

/// How to help and ask for help safely. Linked from the Profile tab.
struct SafetyTipsView: View {
    private static let tips: [(symbol: String, text: String)] = [
        ("building.2", "Meet in a shared or public place, like a lobby or the street outside, when you can."),
        ("house", "Keep your home address and phone number out of requests. Use the chat once someone picks one up."),
        ("hand.raised", "Trust your instincts. You can cancel a request or stop replying at any time."),
        ("creditcard", "Never send money or gift cards to someone you only know from Favorly."),
        ("exclamationmark.shield", "Report anything unsafe from the … menu, and block anyone who makes you uneasy."),
        ("phone", "In an emergency, call 911 first."),
    ]

    var body: some View {
        List {
            Section {
                ForEach(Self.tips, id: \.text) { tip in
                    Label {
                        Text(tip.text)
                    } icon: {
                        Image(systemName: tip.symbol)
                            .foregroundStyle(Theme.Colors.brand)
                    }
                    .padding(.vertical, Theme.Spacing.small)
                }
            } footer: {
                Text("Favorly connects neighbors but does not check who they are. Favors are between you and them.")
            }
        }
        .navigationTitle("Safety tips")
        .accessibilityIdentifier("safety.tips")
    }
}

#Preview {
    NavigationStack {
        SafetyTipsView()
    }
}
