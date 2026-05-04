import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("userName") private var savedName: String = ""
    @AppStorage("userReligion") private var religionRaw: String = Religion.secular.rawValue
    @AppStorage("givingFrequency") private var frequencyRaw: String = GivingFrequency.monthly.rawValue
    @AppStorage("goalIncome") private var goalIncome: Double = 0
    @AppStorage("goalPercent") private var goalPercent: Double = 10
    @AppStorage("userCauses") private var causesRaw: String = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

    @State private var step = 0
    @State private var nameInput = ""
    @State private var selectedReligion: Religion = .secular
    @State private var incomeText = ""
    @State private var selectedFrequency: GivingFrequency = .monthly
    @State private var selectedCauses: Set<String> = []
    @State private var notificationsToggle = true
    @State private var isYearly = true
    @State private var buildingText = "Reviewing your profile…"
    @FocusState private var incomeFocused: Bool

    private let totalSteps = 12
    private let questionRange = 4...8

    var body: some View {
        ZStack {
            Color.tzBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                if questionRange.contains(step) || step == 11 {
                    progressBar
                        .padding(.top, 28)
                        .padding(.horizontal, 24)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        stepContent
                    }
                    .padding(.horizontal, step == 0 || step == 10 ? 0 : 24)
                    .padding(.top, step == 0 ? 0 : 32)
                }
                if questionRange.contains(step) || step == 11 {
                    bottomBar
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }
            }
        }
        .keyboardDoneButton()
    }

    // MARK: - Progress

    private var progressBar: some View {
        let questionSteps = Array(questionRange) + [11]
        let idx = questionSteps.firstIndex(of: step) ?? 0
        return HStack(spacing: 6) {
            ForEach(0..<questionSteps.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= idx ? Color.tzPrimary : Color.tzSeparator)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
    }

    // MARK: - Step router

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:  heroScreen
        case 1:  featureScreen(icon: "doc.text.fill", color: Color.tzGold,
                               headline: "Every receipt,\nright where you need it.",
                               body: "Log donations in seconds. Attach a photo or PDF. At tax time, everything is ready to export — no scrambling through emails or bank statements.")
        case 2:  featureScreen(icon: "calendar.badge.clock", color: Color.tzPrimary,
                               headline: "A giving plan\nbuilt around your life.",
                               body: "Give generates a personalized schedule around your faith's holidays, the tax-year deadline, and your annual goal — so you give at the right moments.")
        case 3:  featureScreen(icon: "chart.bar.fill", color: Color.tzSuccess,
                               headline: "Track every gift.\nStay on track.",
                               body: "Set an annual giving goal, watch your progress, and build a giving streak. Giving with intention starts with knowing where you stand.")
        case 4:  nameScreen
        case 5:  religionScreen
        case 6:  incomeScreen
        case 7:  frequencyScreen
        case 8:  causesScreen
        case 9:  buildingScreen
        case 10: paywallScreen
        case 11: notificationsScreen
        default: EmptyView()
        }
    }

    // MARK: - Hero

    private var heroScreen: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.tzPrimary.ignoresSafeArea()
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.tzGold)
                    Text("Give with\nintention.")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("The smarter way to track, plan, and grow\nyour charitable giving.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .frame(height: 480)

            VStack(spacing: 16) {
                Button { advance() } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.tzPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Text("Built for every faith tradition — and none at all.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.tzSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Feature screens

    private func featureScreen(icon: String, color: Color, headline: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(color)
            }
            Text(headline)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
                .lineSpacing(2)
            Text(body)
                .font(.system(size: 16))
                .foregroundStyle(Color.tzSecondary)
                .lineSpacing(5)
            Spacer(minLength: 40)
            Button { advance() } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.tzPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Name

    private var nameScreen: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What should we\ncall you?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
                .lineSpacing(2)
            Text("First name is fine. Used for your dashboard greeting.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .padding(.bottom, 8)
            TextField("Your name", text: $nameInput)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)
                .textInputAutocapitalization(.words)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
        }
    }

    // MARK: - Religion

    private var religionScreen: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which faith tradition\ndo you follow?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
                .lineSpacing(2)
            Text("Sets your giving terminology, default goal, and holiday calendar. You can change it later.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .padding(.bottom, 4)

            if let quote = faithQuote(for: selectedReligion) {
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(Color.tzGold)
                        .frame(width: 3)
                        .clipShape(Capsule())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\"\(quote.text)\"")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tzPrimary)
                            .italic()
                            .lineSpacing(3)
                        Text("— \(quote.source)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.tzSecondary)
                    }
                }
                .padding(14)
                .background(Color.tzGold.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(.easeInOut(duration: 0.25), value: selectedReligion)
            }

            VStack(spacing: 8) {
                ForEach(Religion.allCases) { r in religionRow(r) }
            }
        }
    }

    private func religionRow(_ r: Religion) -> some View {
        let active = selectedReligion == r
        return Button { withAnimation { selectedReligion = r } } label: {
            HStack(spacing: 14) {
                Image(systemName: r.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(active ? Color.tzGold : Color.tzPrimary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                    Text("\(r.givingTerm) · \(formatPercent(r.defaultGoalPercent))% default")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.tzSecondary)
                }
                Spacer()
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.tzGold)
                }
            }
            .padding(14)
            .background(active ? Color.tzGold.opacity(0.08) : Color.tzCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(active ? Color.tzGold : Color.tzSeparator, lineWidth: active ? 1.5 : 1))
        }
    }

    private struct FaithQuote { let text: String; let source: String }

    private func faithQuote(for religion: Religion) -> FaithQuote? {
        switch religion {
        case .christianity: return FaithQuote(text: "God loves a cheerful giver.", source: "2 Corinthians 9:7")
        case .judaism:      return FaithQuote(text: "Tzedakah is equal in importance to all the other commandments combined.", source: "Talmud, Bava Batra 9a")
        case .islam:        return FaithQuote(text: "The believer's shade on the Day of Resurrection will be their charity.", source: "Hadith, Tirmidhi")
        case .hinduism:     return FaithQuote(text: "He who gives liberally goes straight to the gods.", source: "Rig Veda")
        case .buddhism:     return FaithQuote(text: "Generosity brings happiness at every stage of its expression.", source: "The Buddha")
        case .sikhism:      return FaithQuote(text: "One who works for what he eats and gives some from his hand — he knows the path.", source: "Guru Nanak, Guru Granth Sahib")
        case .bahai:        return FaithQuote(text: "Be generous in prosperity and thankful in adversity.", source: "Bahá'u'lláh")
        case .secular:      return FaithQuote(text: "No one has ever become poor by giving.", source: "Anne Frank")
        }
    }

    // MARK: - Income

    private var incomeScreen: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's your\nannual income?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
                .lineSpacing(2)
            Text("We use this to calculate your suggested giving goal of \(formatPercent(selectedReligion.defaultGoalPercent))% (\(selectedReligion.givingTerm)). Skip if you'd rather not say.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .padding(.bottom, 8)
            HStack(alignment: .center, spacing: 6) {
                Text("$")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(incomeText.isEmpty ? Color.tzSecondary : Color.tzPrimary)
                TextField("0", text: $incomeText)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.tzPrimary)
                    .keyboardType(.numberPad)
                    .tint(Color.tzGold)
                    .focused($incomeFocused)
                    .onChange(of: incomeText) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if let n = Int(filtered) {
                            let f = NumberFormatter(); f.numberStyle = .decimal
                            let formatted = f.string(from: NSNumber(value: n)) ?? filtered
                            if formatted != newValue { incomeText = formatted }
                        } else if filtered.isEmpty {
                            if newValue != "" { incomeText = "" }
                        } else {
                            incomeText = filtered
                        }
                    }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            if let income = parsedIncome, income > 0 {
                Text("Suggested goal: \(currencyString(income * selectedReligion.defaultGoalPercent / 100)) per year")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tzGold)
            }
        }
    }

    // MARK: - Frequency

    private var frequencyScreen: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How often do you\nusually give?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
                .lineSpacing(2)
            Text("Helps us tailor your plan and reminders.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .padding(.bottom, 8)
            VStack(spacing: 8) {
                ForEach(GivingFrequency.allCases) { f in frequencyRow(f) }
            }
        }
    }

    private func frequencyRow(_ f: GivingFrequency) -> some View {
        let active = selectedFrequency == f
        return Button { selectedFrequency = f } label: {
            HStack {
                Text(f.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Spacer()
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.tzGold)
                }
            }
            .padding(16)
            .background(active ? Color.tzGold.opacity(0.08) : Color.tzCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(active ? Color.tzGold : Color.tzSeparator, lineWidth: active ? 1.5 : 1))
        }
    }

    // MARK: - Causes

    private var causesScreen: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which causes matter\nmost to you?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
                .lineSpacing(2)
            Text("Pick any that apply. We'll surface relevant suggestions and insights.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .padding(.bottom, 8)
            VStack(spacing: 8) {
                ForEach(tzCategories, id: \.self) { c in causeRow(c) }
            }
        }
    }

    private func causeRow(_ c: String) -> some View {
        let active = selectedCauses.contains(c)
        return Button {
            if active { selectedCauses.remove(c) } else { selectedCauses.insert(c) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: categoryIcon(c))
                    .font(.system(size: 16))
                    .foregroundStyle(active ? Color.tzGold : Color.tzPrimary)
                    .frame(width: 24)
                Text(c)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Spacer()
                Image(systemName: active ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(active ? Color.tzGold : Color.tzSecondary.opacity(0.4))
            }
            .padding(14)
            .background(active ? Color.tzGold.opacity(0.08) : Color.tzCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(active ? Color.tzGold : Color.tzSeparator, lineWidth: active ? 1.5 : 1))
        }
    }

    // MARK: - Building plan

    private var buildingScreen: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 60)
            ZStack {
                Circle()
                    .stroke(Color.tzGold.opacity(0.15), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.tzGold)
                    .symbolEffect(.pulse, options: .repeating)
            }
            VStack(spacing: 10) {
                Text("Building your\npersonalized plan…")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.tzPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text(buildingText)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.tzSecondary)
                    .animation(.easeInOut, value: buildingText)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear { runBuildingAnimation() }
    }

    private func runBuildingAnimation() {
        let steps: [(String, Double)] = [
            ("Mapping your faith calendar…", 0.8),
            ("Aligning to the tax year…", 1.6),
            ("Calculating your goal…", 2.4),
            ("Optimizing your schedule…", 3.2),
        ]
        for (text, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { buildingText = text }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation { step = 10 }
        }
    }

    // MARK: - Paywall

    private var paywallScreen: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.tzGold.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.tzGold)
                }
                Text("Your plan is ready.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.tzPrimary)
                Text("Start your free trial to unlock it\nand everything Give has to offer.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.tzSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 24)

            HStack(spacing: 0) {
                planToggleButton(label: "Monthly", sublabel: "$5.99 / mo", selected: !isYearly) {
                    withAnimation(.spring(response: 0.3)) { isYearly = false }
                }
                planToggleButton(label: "Yearly", sublabel: "$25 / yr  ·  Save 65%", selected: isYearly, badge: "Best Value") {
                    withAnimation(.spring(response: 0.3)) { isYearly = true }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            VStack(spacing: 4) {
                Text(isYearly ? "$25 per year" : "$5.99 per month")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.tzPrimary)
                Text("7 days free, then \(isYearly ? "$25/yr" : "$5.99/mo"). Cancel anytime.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.tzSecondary)
            }
            .padding(.vertical, 16)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("Unlimited donation logging")
                featureRow("Receipt capture & PDF storage")
                featureRow("Personalized giving plan")
                featureRow("Faith-based holiday calendar")
                featureRow("Tax export in one tap")
                featureRow("Giving streaks & insights")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                Button { advance() } label: {
                    Text("Start 7-Day Free Trial")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.tzPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                HStack(spacing: 20) {
                    Button("Restore Purchase") { }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.tzSecondary)
                    Button("Maybe later") { advance() }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.tzSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            Text("Subscription auto-renews. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundStyle(Color.tzSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
    }

    private func planToggleButton(label: String, sublabel: String, selected: Bool, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selected ? Color.tzPrimary : Color.tzSecondary)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.tzGold)
                            .clipShape(Capsule())
                    }
                }
                Text(sublabel)
                    .font(.system(size: 11))
                    .foregroundStyle(selected ? Color.tzGold : Color.tzSecondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selected ? Color.tzGold.opacity(0.1) : Color.tzCard)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? Color.tzGold : Color.tzSeparator, lineWidth: selected ? 1.5 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(4)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.tzGold)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.tzPrimary)
            Spacer()
        }
    }

    // MARK: - Notifications

    private var notificationsScreen: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stay on track.")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
            Text("We can send a gentle monthly reminder so giving doesn't slip off your radar. You can change this any time.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .lineSpacing(3)
                .padding(.bottom, 8)
            HStack(spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(notificationsToggle ? Color.tzGold : Color.tzSecondary)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly reminder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                    Text(notificationsToggle ? "On" : "Off")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.tzSecondary)
                }
                Spacer()
                Toggle("", isOn: $notificationsToggle)
                    .labelsHidden()
                    .tint(Color.tzGold)
            }
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step > 4 {
                Button { withAnimation { step -= 1 } } label: {
                    Text("Back")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.tzPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Button { advance() } label: {
                Text(continueLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.tzPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var continueLabel: String {
        if step == 11 { return "Get Started" }
        if step == 4 && nameInput.trimmingCharacters(in: .whitespaces).isEmpty { return "Skip" }
        if step == 6 && parsedIncome == nil { return "Skip" }
        if step == 8 && selectedCauses.isEmpty { return "Skip" }
        return "Continue"
    }

    // MARK: - Helpers

    private var parsedIncome: Double? {
        Double(incomeText.replacingOccurrences(of: ",", with: ""))
    }

    private func advance() {
        if step < totalSteps - 1 { withAnimation { step += 1 } } else { finish() }
    }

    private func finish() {
        savedName = nameInput.trimmingCharacters(in: .whitespaces)
        religionRaw = selectedReligion.rawValue
        frequencyRaw = selectedFrequency.rawValue
        if let income = parsedIncome, income > 0 { goalIncome = income }
        goalPercent = selectedReligion.defaultGoalPercent
        causesRaw = selectedCauses.sorted().joined(separator: "|")
        notificationsEnabled = notificationsToggle
        hasOnboarded = true
    }

    private func formatPercent(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
