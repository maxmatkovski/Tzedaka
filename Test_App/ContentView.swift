import SwiftUI

enum AppTab: String, CaseIterable {
    case dashboard   = "Dashboard"
    case add         = "Add Donation"
    case plan        = "Plan"
    case charities   = "Charities"
    case insights    = "Insights"
    case impact      = "Impact"
    case receipts    = "Receipts"
    case settings    = "Settings"

    var icon: String {
        switch self {
        case .dashboard:  return "square.grid.2x2.fill"
        case .add:        return "plus.circle.fill"
        case .plan:       return "calendar.badge.clock"
        case .charities:  return "heart.fill"
        case .insights:   return "chart.bar.fill"
        case .impact:     return "star.fill"
        case .receipts:   return "doc.text.fill"
        case .settings:   return "gearshape.fill"
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
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30, coordinateSpace: .global)
                        .onEnded { value in
                            guard abs(value.translation.height) < 120 else { return }
                            if value.translation.width > 60 && !sidebarOpen { openSidebar() }
                            else if value.translation.width < -60 && sidebarOpen { closeSidebar() }
                        }
                )

            if sidebarOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .offset(x: 270)
                    .onTapGesture { closeSidebar() }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 30, coordinateSpace: .global)
                            .onEnded { value in
                                guard abs(value.translation.height) < 120 else { return }
                                if value.translation.width < -60 { closeSidebar() }
                            }
                    )
            }

            SidebarView(selectedTab: $selectedTab, isOpen: $sidebarOpen)
                .frame(width: 270)
                .offset(x: sidebarOpen ? 0 : -270)
                .zIndex(1)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30, coordinateSpace: .global)
                        .onEnded { value in
                            guard abs(value.translation.height) < 120 else { return }
                            if value.translation.width < -60 { closeSidebar() }
                        }
                )
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: sidebarOpen)
    }

    private var mainContent: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .dashboard:  DashboardView(openSidebar: openSidebar)
                case .add:        AddDonationView(onSave: { selectedTab = .dashboard })
                case .plan:       PlanView()
                case .charities:  CharitiesView()
                case .insights:   InsightsView()
                case .impact:     ImpactView()
                case .receipts:   ReceiptsView()
                case .settings:   SettingsView()
                }
            }
            .background(Color.tzBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tzBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { sidebarOpen = true }
    }

    private func closeSidebar() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { sidebarOpen = false }
    }
}
