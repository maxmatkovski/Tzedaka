import SwiftUI
import SwiftData

@main
struct TzedakaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Donation.self, Charity.self])
    }
}
