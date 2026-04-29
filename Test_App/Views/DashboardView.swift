import SwiftUI
import SwiftData

struct DashboardView: View {
    var openSidebar: () -> Void
    @Query(sort: \Donation.date, order: .reverse) private var donations: [Donation]
    @AppStorage("goalIncome") private var goalIncome: Double = 0
    @AppStorage("goalPercent") private var goalPercent: Double = 10

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    private var yearDonations: [Donation] {
        donations.filter { Calendar.current.component(.year, from: $0.date) == currentYear }
    }
    private var yearTotal: Double { yearDonations.reduce(0) { $0 + $1.amount } }
    private var monthTotal: Double {
        let comps = Calendar.current.dateComponents([.year, .month], from: .now)
        return donations.filter {
            let c = Calendar.current.dateComponents([.year, .month], from: $0.date)
            return c.year == comps.year && c.month == comps.month
        }.reduce(0) { $0 + $1.amount }
    }
    private var lifeTotal: Double { donations.reduce(0) { $0 + $1.amount } }
    private var goalTarget: Double { goalIncome * (goalPercent / 100) }
    private var goalProgress: Double {
        guard goalTarget > 0 else { return 0 }
        return min(yearTotal / goalTarget, 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greeting
                primaryCard
                if goalIncome > 0 { goalCard }
                quickStats
                if !donations.isEmpty { recentDonations }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.tzBackground.ignoresSafeArea())
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greetingText())
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.tzSecondary)
            Text("Your giving journey")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
        }
    }

    private var primaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Given in \(currentYear)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.tzSecondary)
            Text(currencyString(yearTotal))
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
            Text("\(yearDonations.count) donation\(yearDonations.count == 1 ? "" : "s")")
                .font(.system(size: 13))
                .foregroundStyle(Color.tzSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .cardStyle()
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Giving Goal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.tzSecondary)
                    Text("\(Int(goalPercent))% of income · \(currencyString(goalTarget))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                }
                Spacer()
                Text("\(Int(goalProgress * 100))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(goalProgress >= 1 ? Color.tzSuccess : Color.tzGold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tzSeparator)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(goalProgress >= 1 ? Color.tzSuccess : Color.tzGold)
                        .frame(width: geo.size.width * goalProgress, height: 8)
                        .animation(.spring(response: 0.5), value: goalProgress)
                }
            }
            .frame(height: 8)
            Text(currencyString(max(0, goalTarget - yearTotal)) + " remaining")
                .font(.system(size: 12))
                .foregroundStyle(Color.tzSecondary)
        }
        .padding(20)
        .cardStyle()
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            statTile(label: "This Month", value: currencyString(monthTotal))
            statTile(label: "Lifetime", value: currencyString(lifeTotal))
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.tzSecondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }

    private var recentDonations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Donations")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)

            VStack(spacing: 0) {
                ForEach(Array(donations.prefix(5))) { donation in
                    DonationRow(donation: donation)
                    if donation.id != donations.prefix(5).last?.id {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .cardStyle()
        }
    }

    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}

struct DonationRow: View {
    let donation: Donation

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.tzPrimary.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: categoryIcon(donation.category))
                        .font(.system(size: 14))
                        .foregroundStyle(Color.tzPrimary)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(donation.charityName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Text(donation.category)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.tzSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyString(donation.amount))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Text(donation.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.tzSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

func categoryIcon(_ category: String) -> String {
    switch category {
    case "Education":       return "book.fill"
    case "Food & Hunger":   return "fork.knife"
    case "Medical":         return "cross.fill"
    case "Disaster Relief": return "house.fill"
    case "Religious":       return "star.of.david.fill"
    case "Environment":     return "leaf.fill"
    case "Animal Welfare":  return "pawprint.fill"
    case "Arts & Culture":  return "paintbrush.fill"
    default:                return "heart.fill"
    }
}
