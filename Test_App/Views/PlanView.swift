import SwiftUI
import SwiftData

struct PlanView: View {
    @Query(sort: \Donation.date, order: .reverse) private var donations: [Donation]
    @Environment(\.modelContext) private var context

    @AppStorage("userReligion") private var religionRaw: String = Religion.secular.rawValue
    @AppStorage("givingFrequency") private var frequencyRaw: String = GivingFrequency.monthly.rawValue
    @AppStorage("goalIncome") private var goalIncome: Double = 0
    @AppStorage("goalPercent") private var goalPercent: Double = 10
    @AppStorage("savedPlanJSON") private var savedPlanJSON: String = ""

    @State private var plan: [PlannedDonation] = []
    @State private var isThinking = false
    @State private var thinkingText = ""
    @State private var logTarget: PlannedDonation? = nil

    private var religion: Religion { Religion(rawValue: religionRaw) ?? .secular }
    private var frequency: GivingFrequency { GivingFrequency(rawValue: frequencyRaw) ?? .monthly }
    private var goalAmount: Double { goalIncome * goalPercent / 100 }
    private var currentYear: Int { Calendar.current.component(.year, from: .now) }
    private var givenThisYear: Double {
        donations
            .filter { Calendar.current.component(.year, from: $0.date) == currentYear }
            .reduce(0) { $0 + $1.amount }
    }
    private var remaining: Double { max(goalAmount - givenThisYear, 0) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                if goalAmount <= 0 {
                    setGoalPrompt
                } else if isThinking {
                    thinkingCard
                } else if plan.isEmpty {
                    generateCard
                } else {
                    planList
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.tzBackground.ignoresSafeArea())
        .keyboardDoneButton()
        .onAppear { if plan.isEmpty { plan = loadSavedPlan() } }
        .sheet(item: $logTarget) { item in LogPlanItemSheet(item: item) }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your \(currentYear) Plan")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
            HStack(spacing: 24) {
                stat("Goal", currencyString(goalAmount))
                stat("Given", currencyString(givenThisYear))
                stat("Remaining", currencyString(remaining))
            }
            Text("\(religion.givingTerm) · \(frequency.rawValue.lowercased()) cadence")
                .font(.system(size: 12))
                .foregroundStyle(Color.tzSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .cardStyle()
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(Color.tzSecondary)
            Text(value).font(.system(size: 16, weight: .bold)).foregroundStyle(Color.tzPrimary)
        }
    }

    private var setGoalPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set a giving goal first")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.tzPrimary)
            Text("Add your annual income in Settings to enable plan generation.")
                .font(.system(size: 13)).foregroundStyle(Color.tzSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20).cardStyle()
    }

    private var generateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimize your giving")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.tzPrimary)
            Text("We'll spread \(currencyString(remaining)) across the rest of the year, weighted around \(religion.givingTerm.lowercased()) holidays and the tax-year deadline.")
                .font(.system(size: 13)).foregroundStyle(Color.tzSecondary).lineSpacing(2)
            Button { runThinking() } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Plan").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.tzPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(remaining <= 0)
        }
        .padding(20).cardStyle()
    }

    private var thinkingCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color.tzGold.opacity(0.15), lineWidth: 4).frame(width: 56, height: 56)
                Image(systemName: "sparkles").font(.system(size: 24)).foregroundStyle(Color.tzGold)
                    .symbolEffect(.pulse, options: .repeating)
            }
            Text(thinkingText).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.tzPrimary)
                .animation(.easeInOut, value: thinkingText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40).cardStyle()
    }

    private var planList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggested Schedule").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.tzPrimary)
                Spacer()
                Button("Regenerate") { plan = []; savedPlanJSON = ""; runThinking() }
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.tzPrimary)
            }
            ForEach(plan) { item in planRow(item) }
        }
    }

    private func planRow(_ item: PlannedDonation) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.tzGold)
                Text(item.occasion).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.tzPrimary).lineLimit(1)
                Text(item.notes).font(.system(size: 11)).foregroundStyle(Color.tzSecondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(currencyString(item.amount)).font(.system(size: 16, weight: .bold)).foregroundStyle(Color.tzPrimary)
                Button { logTarget = item } label: {
                    Text("Log").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Color.tzPrimary).clipShape(Capsule())
                }
            }
        }
        .padding(14).cardStyle()
    }

    private func runThinking() {
        isThinking = true
        thinkingText = "Reviewing your causes…"
        let steps: [(String, Double)] = [
            ("Mapping religious holidays…", 0.45),
            ("Aligning to tax year…", 0.85),
            ("Optimizing schedule…", 1.25),
        ]
        for (text, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { if isThinking { thinkingText = text } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            let generated = GivingPlanner.generatePlan(annualGoal: goalAmount, alreadyGiven: givenThisYear,
                                                       religion: religion, frequency: frequency)
            plan = generated
            savePlan(generated)
            NotificationManager.shared.schedulePlanNotifications(generated)
            isThinking = false
        }
    }

    private func loadSavedPlan() -> [PlannedDonation] {
        guard !savedPlanJSON.isEmpty, let data = savedPlanJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([PlannedDonation].self, from: data)) ?? []
    }

    private func savePlan(_ items: [PlannedDonation]) {
        if let data = try? JSONEncoder().encode(items), let str = String(data: data, encoding: .utf8) {
            savedPlanJSON = str
        }
    }
}

struct LogPlanItemSheet: View {
    let item: PlannedDonation
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Charity.name) private var charities: [Charity]
    @State private var charityName = ""
    @State private var selectedCategory: String
    @State private var showCharityPicker = false

    init(item: PlannedDonation) {
        self.item = item
        _selectedCategory = State(initialValue: item.category)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    occasionCard
                    charityCard
                    Spacer(minLength: 0)
                    saveButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color.tzBackground.ignoresSafeArea())
            .keyboardDoneButton()
            .navigationTitle("Log Donation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.tzPrimary)
                }
            }
            .sheet(isPresented: $showCharityPicker) {
                CharityPickerSheet(selected: $charityName, category: $selectedCategory)
            }
        }
    }

    private var occasionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.occasion).font(.system(size: 17, weight: .bold)).foregroundStyle(Color.tzPrimary)
                    Text(item.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 13)).foregroundStyle(Color.tzSecondary)
                    Text(item.notes).font(.system(size: 12)).foregroundStyle(Color.tzSecondary)
                }
                Spacer()
                Text(currencyString(item.amount)).font(.system(size: 22, weight: .bold)).foregroundStyle(Color.tzGold)
            }
            HStack(spacing: 6) {
                Image(systemName: categoryIcon(item.category)).font(.system(size: 11)).foregroundStyle(Color.tzSecondary)
                Text(item.category).font(.system(size: 12)).foregroundStyle(Color.tzSecondary)
            }
        }
        .padding(16).cardStyle()
    }

    private var charityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Charity").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.tzPrimary)
            TextField("Charity name", text: $charityName)
                .font(.system(size: 15)).padding(12)
                .background(Color.tzPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            if !charities.isEmpty {
                Button { showCharityPicker = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass").font(.system(size: 12))
                        Text("Pick from saved charities").font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color.tzPrimary)
                }
            }
        }
        .padding(16).cardStyle()
    }

    private var saveButton: some View {
        Button {
            let name = charityName.trimmingCharacters(in: .whitespaces)
            let donation = Donation(amount: item.amount, date: item.date,
                                    charityName: name.isEmpty ? item.occasion : name,
                                    category: selectedCategory, notes: item.notes, impactNote: item.occasion)
            context.insert(donation)
            dismiss()
        } label: {
            Text("Log Donation").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Color.tzPrimary).clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
    }
}
