import SwiftUI
import SwiftData

struct ImpactView: View {
    @Query(sort: \Donation.date, order: .reverse) private var donations: [Donation]
    @Environment(\.modelContext) private var context
    @AppStorage("goalIncome") private var goalIncome: Double = 0
    @AppStorage("goalPercent") private var goalPercent: Double = 10
    @State private var showGoalSheet = false

    private var totalGiven: Double { donations.reduce(0) { $0 + $1.amount } }
    private var withNotes: [Donation] { donations.filter { !$0.impactNote.isEmpty } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                lifetimeCard
                goalSettingsCard
                if !withNotes.isEmpty { impactNotes }
                donationLog
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.tzBackground.ignoresSafeArea())
        .sheet(isPresented: $showGoalSheet) { GoalSheet() }
    }

    private var lifetimeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lifetime Impact")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(currencyString(totalGiven))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
            HStack(spacing: 20) {
                statPill(icon: "arrow.up.right", value: "\(donations.count) donations")
                statPill(icon: "building.2.fill", value: "\(uniqueCharities) charities")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.tzPrimary, Color.tzPrimary.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.tzPrimary.opacity(0.3), radius: 16, y: 6)
    }

    private var uniqueCharities: Int {
        Set(donations.map { $0.charityName }).count
    }

    private func statPill(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())
    }

    private var goalSettingsCard: some View {
        Button { showGoalSheet = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Giving Goal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.tzSecondary)
                    if goalIncome > 0 {
                        Text("\(Int(goalPercent))% of \(currencyString(goalIncome)) = \(currencyString(goalIncome * goalPercent / 100)) / year")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.tzPrimary)
                    } else {
                        Text("Set your annual giving goal")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.tzPrimary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.tzSecondary)
            }
            .padding(16)
            .cardStyle()
        }
    }

    @ViewBuilder
    private var impactNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact Notes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)

            VStack(spacing: 12) {
                ForEach(withNotes.prefix(10)) { donation in
                    ImpactNoteCard(donation: donation)
                }
            }
        }
    }

    private var donationLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Donation Log")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)

            if donations.isEmpty {
                Text("No donations yet. Start by adding your first donation.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.tzSecondary)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                VStack(spacing: 0) {
                    ForEach(donations) { donation in
                        DonationRow(donation: donation) { context.delete(donation) }
                        if donation.id != donations.last?.id {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }
}

struct ImpactNoteCard: View {
    let donation: Donation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(donation.charityName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Spacer()
                Text(currencyString(donation.amount))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tzGold)
            }
            Text("\"\(donation.impactNote)\"")
                .font(.system(size: 13))
                .foregroundStyle(Color.tzSecondary)
                .italic()
            Text(donation.date.formatted(.dateTime.month(.wide).day().year()))
                .font(.system(size: 11))
                .foregroundStyle(Color.tzSecondary.opacity(0.6))
        }
        .padding(14)
        .cardStyle()
    }
}

struct GoalSheet: View {
    @AppStorage("goalIncome") private var goalIncome: Double = 0
    @AppStorage("goalPercent") private var goalPercent: Double = 10
    @Environment(\.dismiss) private var dismiss

    @State private var incomeText = ""
    @State private var percentText = "10"

    var body: some View {
        NavigationStack {
            Form {
                Section("Annual Income") {
                    HStack {
                        Text("$")
                        TextField("e.g. 75000", text: $incomeText)
                            .keyboardType(.numberPad)
                    }
                }
                Section("Giving Percentage") {
                    HStack {
                        TextField("e.g. 10", text: $percentText)
                            .keyboardType(.decimalPad)
                        Text("%")
                    }
                }
                if let income = Double(incomeText), let pct = Double(percentText), pct > 0 {
                    Section("Goal") {
                        Text("You aim to give \(currencyString(income * pct / 100)) per year")
                            .foregroundStyle(Color.tzPrimary)
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("Giving Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        goalIncome = Double(incomeText) ?? 0
                        goalPercent = Double(percentText) ?? 10
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if goalIncome > 0 { incomeText = String(Int(goalIncome)) }
                percentText = String(goalPercent)
            }
        }
    }
}
