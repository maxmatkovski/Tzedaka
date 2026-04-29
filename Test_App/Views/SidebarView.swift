import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedTab: AppTab
    @Binding var isOpen: Bool
    @Query private var donations: [Donation]

    private var yearTotal: Double {
        let year = Calendar.current.component(.year, from: .now)
        return donations.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.tzPrimary.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().overlay(Color.white.opacity(0.15)).padding(.horizontal, 20)
                navItems
                Spacer()
                footer
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "star.of.david.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.tzGold)
                Text("Tzedaka")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(currencyString(yearTotal) + " given this year")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.top, 64)
        .padding(.bottom, 24)
    }

    private var navItems: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                navRow(tab)
            }
        }
        .padding(.top, 12)
    }

    private func navRow(_ tab: AppTab) -> some View {
        let active = selectedTab == tab
        return Button {
            selectedTab = tab
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isOpen = false
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))
                    .frame(width: 22)
                Text(tab.rawValue)
                    .font(.system(size: 15, weight: active ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(active ? Color.tzGold : .white.opacity(0.75))
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(active ? Color.white.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 8)
    }

    private var footer: some View {
        Text("Tzedaka · v1.0")
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
    }
}
