import SwiftUI
import SwiftData

@main
struct Test_AppApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [Donation.self, Charity.self])
    }
}
