import SwiftUI

enum AppTab: String, CaseIterable {
    case dashboard   = "Dashboard"
    case add         = "Add Donation"
    case charities   = "Charities"
    case insights    = "Insights"
    case impact      = "Impact"

    var icon: String {
        switch self {
        case .dashboard:  "square.grid.2x2.fill"
        case .add:        "plus.circle.fill"
        case .charities:  "heart.fill"
        case .insights:   "chart.bar.fill"
        case .impact:     "star.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var sidebarOpen = false

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
                .offset(x: sidebarOpen ? 270 : 0)

            if sidebarOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .offset(x: 270)
                    .onTapGesture { closeSidebar() }
            }

            SidebarView(selectedTab: $selectedTab, isOpen: $sidebarOpen)
                .frame(width: 270)
                .offset(x: sidebarOpen ? 0 : -270)
                .zIndex(1)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: sidebarOpen)
    }

    private var mainContent: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .dashboard:  DashboardView(openSidebar: openSidebar)
                case .add:        AddDonationView(onSave: { selectedTab = .dashboard })
                case .charities:  CharitiesView()
                case .insights:   InsightsView()
                case .impact:     ImpactView()
                }
            }
            .background(Color.tzBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: openSidebar) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.tzPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(selectedTab.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                }
            }
        }
    }

    private func openSidebar() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            sidebarOpen = true
        }
    }

    private func closeSidebar() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            sidebarOpen = false
        }
    }
}
