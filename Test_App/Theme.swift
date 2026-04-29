import SwiftUI

extension Color {
    static let tzPrimary    = Color(red: 0.102, green: 0.231, blue: 0.431)
    static let tzGold       = Color(red: 0.769, green: 0.588, blue: 0.165)
    static let tzBackground = Color(red: 0.969, green: 0.953, blue: 0.937)
    static let tzCard       = Color.white
    static let tzSecondary  = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let tzSeparator  = Color(red: 0.898, green: 0.882, blue: 0.863)
    static let tzSuccess    = Color(red: 0.180, green: 0.490, blue: 0.369)
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.tzCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

let tzCategories = [
    "Education", "Food & Hunger", "Medical", "Disaster Relief",
    "Religious", "Environment", "Animal Welfare", "Arts & Culture", "Other"
]

func currencyString(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "$0"
}
