import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userReligion") private var religionRaw: String = Religion.secular.rawValue
    @AppStorage("givingFrequency") private var frequencyRaw: String = GivingFrequency.monthly.rawValue
    @AppStorage("goalIncome") private var goalIncome: Double = 0
    @AppStorage("goalPercent") private var goalPercent: Double = 10
    @AppStorage("userCauses") private var causesRaw: String = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    @State private var incomeText: String = ""
    @State private var percentText: String = ""
    @State private var showResetConfirm = false

    private var selectedCauses: Set<String> {
        Set(causesRaw.split(separator: "|").map(String.init))
    }
    private var religion: Religion { Religion(rawValue: religionRaw) ?? .secular }
    private var frequency: GivingFrequency { GivingFrequency(rawValue: frequencyRaw) ?? .monthly }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                profileCard
                faithCard
                goalCard
                frequencyCard
                causesCard
                notificationsCard
                resetCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .background(Color.tzBackground.ignoresSafeArea())
        .onAppear {
            if incomeText.isEmpty && goalIncome > 0 { incomeText = formatNumber(goalIncome) }
            if percentText.isEmpty { percentText = formatPercent(goalPercent) }
        }
        .confirmationDialog("Restart onboarding?", isPresented: $showResetConfirm) {
            Button("Restart", role: .destructive) { hasOnboarded = false }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll be asked the setup questions again. Your donations will not be deleted.")
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Profile", subtitle: "Used for the dashboard greeting.")
            TextField("Your name", text: $userName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Color.tzPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .cardStyle()
    }

    private var faithCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Faith Tradition", subtitle: "Sets your giving terminology and default goal.")
            VStack(spacing: 8) {
                ForEach(Religion.allCases) { r in religionRow(r) }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func religionRow(_ r: Religion) -> some View {
        let active = religion == r
        return Button {
            let previousDefault = religion.defaultGoalPercent
            religionRaw = r.rawValue
            if abs(goalPercent - previousDefault) < 0.01 {
                goalPercent = r.defaultGoalPercent
                percentText = formatPercent(r.defaultGoalPercent)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: r.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(active ? Color.tzGold : Color.tzPrimary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                    Text("\(r.givingTerm) · \(formatPercent(r.defaultGoalPercent))% default")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.tzSecondary)
                }
                Spacer()
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.tzGold)
                }
            }
            .padding(12)
            .background(active ? Color.tzGold.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Giving Goal", subtitle: "Used to track progress on the dashboard.")
            VStack(alignment: .leading, spacing: 6) {
                Text("Annual income")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.tzSecondary)
                HStack {
                    Text("$").foregroundStyle(Color.tzSecondary)
                    TextField("0", text: $incomeText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                        .keyboardType(.numberPad)
                        .onChange(of: incomeText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if let n = Int(filtered) {
                                let f = NumberFormatter(); f.numberStyle = .decimal
                                let formatted = f.string(from: NSNumber(value: n)) ?? filtered
                                if formatted != newValue { incomeText = formatted }
                                goalIncome = Double(n)
                            } else if filtered.isEmpty {
                                if newValue != "" { incomeText = "" }
                                goalIncome = 0
                            }
                        }
                }
                .padding(12)
                .background(Color.tzPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Goal percentage")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.tzSecondary)
                HStack {
                    TextField("\(formatPercent(religion.defaultGoalPercent))", text: $percentText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                        .keyboardType(.decimalPad)
                        .onChange(of: percentText) { _, newValue in
                            let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                            if let v = Double(cleaned), v >= 0, v <= 100 { goalPercent = v }
                            else if cleaned.isEmpty { goalPercent = 0 }
                        }
                    Text("%").foregroundStyle(Color.tzSecondary)
                }
                .padding(12)
                .background(Color.tzPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if goalIncome > 0 {
                Text("Target: \(currencyString(goalIncome * goalPercent / 100)) per year")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.tzGold)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var frequencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Giving Frequency", subtitle: "Helps tailor reminders and suggestions.")
            VStack(spacing: 6) {
                ForEach(GivingFrequency.allCases) { f in frequencyRow(f) }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func frequencyRow(_ f: GivingFrequency) -> some View {
        let active = frequency == f
        return Button { frequencyRaw = f.rawValue } label: {
            HStack {
                Text(f.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Spacer()
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.tzGold)
                }
            }
            .padding(12)
            .background(active ? Color.tzGold.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var causesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Causes", subtitle: "Drives suggestions and insights tailored to you.")
            VStack(spacing: 6) {
                ForEach(tzCategories, id: \.self) { c in causeRow(c) }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func causeRow(_ c: String) -> some View {
        let active = selectedCauses.contains(c)
        return Button {
            var set = selectedCauses
            if active { set.remove(c) } else { set.insert(c) }
            causesRaw = set.sorted().joined(separator: "|")
        } label: {
            HStack(spacing: 10) {
                Image(systemName: categoryIcon(c))
                    .font(.system(size: 14))
                    .foregroundStyle(active ? Color.tzGold : Color.tzPrimary)
                    .frame(width: 22)
                Text(c)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Spacer()
                Image(systemName: active ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(active ? Color.tzGold : Color.tzSecondary.opacity(0.4))
            }
            .padding(10)
            .background(active ? Color.tzGold.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Notifications", subtitle: "Monthly giving reminders.")
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(notificationsEnabled ? Color.tzGold : Color.tzSecondary)
                    .frame(width: 28)
                Text("Monthly reminder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(Color.tzGold)
            }
            .padding(.vertical, 6)
        }
        .padding(16)
        .cardStyle()
    }

    private var resetCard: some View {
        Button { showResetConfirm = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise").foregroundStyle(Color.tzPrimary)
                Text("Restart onboarding")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Spacer()
            }
            .padding(14)
            .background(Color.tzCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.tzPrimary)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(Color.tzSecondary)
        }
    }

    private func formatNumber(_ value: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func formatPercent(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
