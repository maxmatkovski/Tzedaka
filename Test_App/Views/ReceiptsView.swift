import SwiftUI
import SwiftData

struct ReceiptsView: View {
    @Query(sort: \Donation.date, order: .reverse) private var donations: [Donation]
    @State private var selectedDonation: Donation? = nil

    private var withReceipts: [Donation] {
        donations.filter { $0.receiptPath != nil }
    }

    var body: some View {
        Group {
            if withReceipts.isEmpty {
                emptyState
            } else {
                receiptList
            }
        }
        .background(Color.tzBackground.ignoresSafeArea())
        .sheet(item: $selectedDonation) { donation in
            ReceiptDetailView(donation: donation)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.tzSecondary.opacity(0.4))
            Text("No receipts yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)
            Text("When you attach a photo or PDF to a donation, it will appear here.")
                .font(.system(size: 14))
                .foregroundStyle(Color.tzSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var receiptList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(withReceipts) { donation in
                    receiptRow(donation)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private func receiptRow(_ donation: Donation) -> some View {
        Button { selectedDonation = donation } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.tzGold.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: donation.receiptPath?.hasSuffix(".pdf") == true ? "doc.fill" : "photo.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.tzGold)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(donation.charityName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.tzPrimary)
                    Text(donation.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.tzSecondary)
                    if let originalName = donation.receiptOriginalName {
                        Text(originalName)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.tzSecondary.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(currencyString(donation.amount))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.tzPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.tzSecondary)
                }
            }
            .padding(14)
            .cardStyle()
        }
    }
}

struct ReceiptDetailView: View {
    let donation: Donation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    infoCard
                    if let path = donation.receiptPath, let url = receiptURL(path) {
                        receiptPreview(url: url, path: path)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.tzBackground.ignoresSafeArea())
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color.tzPrimary)
                }
            }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(donation.charityName)
                        .font(.system(size: 17, weight: .bold)).foregroundStyle(Color.tzPrimary)
                    Text(donation.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 13)).foregroundStyle(Color.tzSecondary)
                    Text(donation.category)
                        .font(.system(size: 12)).foregroundStyle(Color.tzSecondary)
                }
                Spacer()
                Text(currencyString(donation.amount))
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(Color.tzGold)
            }
        }
        .padding(16).cardStyle()
    }

    private func receiptPreview(url: URL, path: String) -> some View {
        Group {
            if path.hasSuffix(".pdf") {
                VStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 48)).foregroundStyle(Color.tzGold)
                    Text(donation.receiptOriginalName ?? "Receipt.pdf")
                        .font(.system(size: 14)).foregroundStyle(Color.tzPrimary)
                    ShareLink(item: url) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.tzPrimary).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20).cardStyle()
            } else if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                VStack(spacing: 12) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    ShareLink(item: url) {
                        Label("Share Image", systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.tzPrimary).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20).cardStyle()
            }
        }
    }
}
