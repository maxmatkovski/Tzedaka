import SwiftUI
import SwiftData

struct CharitiesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Charity.name) private var charities: [Charity]
    @Query private var donations: [Donation]
    @State private var showAdd = false
    @State private var editCharity: Charity? = nil
    @State private var searchText = ""

    private var filtered: [Charity] {
        guard !searchText.isEmpty else { return charities }
        return charities.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func totalGiven(to charity: Charity) -> Double {
        donations.filter { $0.charityName == charity.name }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            if charities.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .background(Color.tzBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdd) { CharityFormSheet(charity: nil) }
        .sheet(item: $editCharity) { CharityFormSheet(charity: $0) }
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                if filtered.isEmpty {
                    Text("No results")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.tzSecondary)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(filtered) { charity in
                            CharityRow(charity: charity, total: totalGiven(to: charity))
                                .onTapGesture { editCharity = charity }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        context.delete(charity)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            if charity.id != filtered.last?.id {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 32)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.tzGold.opacity(0.5))
            Text("No charities yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)
            Text("Add the organisations you give to so you can quickly log donations.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button { showAdd = true } label: {
                Text("Add Charity")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.tzPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CharityRow: View {
    let charity: Charity
    let total: Double

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.tzPrimary.opacity(0.08))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: categoryIcon(charity.category))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.tzPrimary)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(charity.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.tzPrimary)
                Text(charity.category)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.tzSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if total > 0 {
                    Text(currencyString(total))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.tzGold)
                    Text("total given")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.tzSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.tzSeparator)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct CharityFormSheet: View {
    var charity: Charity?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = tzCategories[0]
    @State private var notes = ""
    @State private var link = ""

    private var isEdit: Bool { charity != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(tzCategories, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Optional") {
                    TextField("Notes", text: $notes)
                    TextField("Website", text: $link)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle(isEdit ? "Edit Charity" : "New Charity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let c = charity {
                    name = c.name; category = c.category
                    notes = c.notes; link = c.link
                }
            }
        }
    }

    private func save() {
        if let c = charity {
            c.name = name.trimmingCharacters(in: .whitespaces)
            c.category = category; c.notes = notes; c.link = link
        } else {
            context.insert(Charity(name: name.trimmingCharacters(in: .whitespaces),
                                   category: category, notes: notes, link: link))
        }
        dismiss()
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tzSecondary)
            TextField("Search charities", text: $text)
                .font(.system(size: 15))
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.tzSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.tzCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
