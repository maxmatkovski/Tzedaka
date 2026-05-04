import SwiftUI
import SwiftData

struct EditDonationView: View {
    @Bindable var donation: Donation
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var amountText: String = ""
    @State private var date: Date = .now
    @State private var charityName: String = ""
    @State private var category: String = tzCategories[0]
    @State private var notes: String = ""
    @State private var impactNote: String = ""
    @State private var isRecurring: Bool = false
    @State private var recurrenceInterval: String = "Monthly"
    @State private var showDatePicker = false
    @State private var showDeleteConfirm = false

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private var canSave: Bool {
        amount > 0 && !charityName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    amountSection
                    detailsCard
                    notesCard
                    deleteButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.tzBackground.ignoresSafeArea())
            .keyboardDoneButton()
            .navigationTitle("Edit Donation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tzBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.tzPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? Color.tzPrimary : Color.tzSecondary)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Delete this donation?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { context.delete(donation); dismiss() }
                Button("Cancel", role: .cancel) { }
            }
        }
        .onAppear { loadValues() }
    }

    private var amountSection: some View {
        VStack(spacing: 4) {
            Text("Amount")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.tzSecondary)
            HStack(alignment: .center, spacing: 4) {
                Text("$").font(.system(size: 28, weight: .light)).foregroundStyle(Color.tzSecondary)
                TextField("0", text: $amountText)
                    .font(.system(size: 48, weight: .bold)).foregroundStyle(Color.tzPrimary)
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .tint(Color.tzGold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24).padding(.horizontal, 20)
            .cardStyle()
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.tzSecondary)
            field("Charity", binding: $charityName, placeholder: "Charity name")
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("Category").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.tzSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tzCategories, id: \.self) { cat in
                            Button { category = cat } label: {
                                Text(cat)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(category == cat ? .white : Color.tzPrimary)
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(category == cat ? Color.tzPrimary : Color.tzPrimary.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            Divider()
            Button {
                withAnimation { showDatePicker.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Date").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.tzSecondary)
                        Text(date.formatted(.dateTime.month(.wide).day().year()))
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.tzPrimary)
                    }
                    Spacer()
                    Image(systemName: "calendar").foregroundStyle(Color.tzPrimary)
                }
            }
            if showDatePicker {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical).tint(Color.tzGold)
            }
            Divider()
            Toggle(isOn: $isRecurring) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recurring").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.tzPrimary)
                    Text("Log this on a regular schedule").font(.system(size: 12)).foregroundStyle(Color.tzSecondary)
                }
            }
            .tint(Color.tzGold)
            if isRecurring {
                Picker("Interval", selection: $recurrenceInterval) {
                    ForEach(["Weekly", "Monthly", "Quarterly", "Annually"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16).cardStyle()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.tzSecondary)
            TextField("Add a note…", text: $notes, axis: .vertical)
                .font(.system(size: 15)).foregroundStyle(Color.tzPrimary).lineLimit(3...6)
            Divider()
            Text("Impact").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.tzSecondary)
            TextField("What did this support?", text: $impactNote, axis: .vertical)
                .font(.system(size: 15)).foregroundStyle(Color.tzPrimary).lineLimit(2...4)
        }
        .padding(16).cardStyle()
    }

    private var deleteButton: some View {
        Button { showDeleteConfirm = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash").font(.system(size: 14))
                Text("Delete Donation").font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func field(_ label: String, binding: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.tzSecondary)
            TextField(placeholder, text: binding)
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.tzPrimary)
        }
    }

    private func loadValues() {
        let fmt = NumberFormatter(); fmt.numberStyle = .decimal; fmt.maximumFractionDigits = 2
        amountText = fmt.string(from: NSNumber(value: donation.amount)) ?? "\(donation.amount)"
        date = donation.date
        charityName = donation.charityName
        category = donation.category
        notes = donation.notes
        impactNote = donation.impactNote
        isRecurring = donation.isRecurring
        recurrenceInterval = donation.recurrenceInterval
    }

    private func save() {
        donation.amount = amount
        donation.date = date
        donation.charityName = charityName.trimmingCharacters(in: .whitespaces)
        donation.category = category
        donation.notes = notes
        donation.impactNote = impactNote
        donation.isRecurring = isRecurring
        donation.recurrenceInterval = recurrenceInterval
        dismiss()
    }
}
