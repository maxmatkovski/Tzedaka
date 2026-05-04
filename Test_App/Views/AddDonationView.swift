import SwiftUI
import SwiftData

struct AddDonationView: View {
    var onSave: (() -> Void)? = nil
    @Environment(\.modelContext) private var context
    @Query(sort: \Charity.name) private var charities: [Charity]

    @State private var amountText = ""
    @State private var date = Date.now
    @State private var charityName = ""
    @State private var category = tzCategories[0]
    @State private var notes = ""
    @State private var impactNote = ""
    @State private var showCharity = false
    @State private var saved = false

    private var amount: Double { Double(amountText) ?? 0 }
    private var canSave: Bool { amount > 0 && !charityName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                amountSection
                detailsCard
                notesCard
                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.tzBackground.ignoresSafeArea())
        .keyboardDoneButton()
        .sheet(isPresented: $showCharity) {
            CharityPickerSheet(selected: $charityName, category: $category)
        }
        .overlay(savedOverlay)
    }

    private var amountSection: some View {
        VStack(spacing: 6) {
            Text("How much did you give?")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.tzSecondary)
            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(amount > 0 ? Color.tzPrimary : Color.tzSecondary)
                TextField("0", text: $amountText)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color.tzPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tint(Color.tzGold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .cardStyle()
        }
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            formRow(label: "Charity") {
                HStack {
                    TextField("Charity name", text: $charityName)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.tzPrimary)
                    if !charities.isEmpty {
                        Button {
                            showCharity = true
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.tzSecondary)
                        }
                    }
                }
            }
            Divider().padding(.horizontal, 16)

            formRow(label: "Category") {
                Picker("", selection: $category) {
                    ForEach(tzCategories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.tzPrimary)
            }
            Divider().padding(.horizontal, 16)

            formRow(label: "Date") {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .tint(Color.tzPrimary)
                    .labelsHidden()
            }
        }
        .cardStyle()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            formRow(label: "Notes") {
                TextField("Optional notes", text: $notes)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.tzPrimary)
            }
            Divider().padding(.horizontal, 16)
            formRow(label: "Impact") {
                TextField("What did this support?", text: $impactNote)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.tzPrimary)
            }
        }
        .cardStyle()
    }

    private func formRow<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.tzSecondary)
                .frame(width: 72, alignment: .leading)
            content()
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Save Donation")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSave ? Color.tzPrimary : Color.tzSecondary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSave)
    }

    @ViewBuilder
    private var savedOverlay: some View {
        if saved {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Donation saved")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.tzSuccess)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 10)
                .padding(.bottom, 40)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func save() {
        let donation = Donation(
            amount: amount,
            date: date,
            charityName: charityName.trimmingCharacters(in: .whitespaces),
            category: category,
            notes: notes,
            impactNote: impactNote
        )
        context.insert(donation)
        withAnimation(.spring()) { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { saved = false }
            amountText = ""
            charityName = ""
            notes = ""
            impactNote = ""
            date = .now
            onSave?()
        }
    }
}

struct CharityPickerSheet: View {
    @Binding var selected: String
    @Binding var category: String
    @Query(sort: \Charity.name) private var charities: [Charity]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(charities) { charity in
                Button {
                    selected = charity.name
                    category = charity.category
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(charity.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.tzPrimary)
                        Text(charity.category)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.tzSecondary)
                    }
                }
            }
            .navigationTitle("Select Charity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
