import SwiftUI
import SwiftData

struct ExportView: View {
    @Query(sort: \Donation.date, order: .reverse) private var donations: [Donation]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var exportURL: URL? = nil
    @State private var showShare = false
    @State private var isGenerating = false

    private var availableYears: [Int] {
        let years = Set(donations.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted().reversed()
    }

    private var filteredDonations: [Donation] {
        donations.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
    }

    private var totalForYear: Double { filteredDonations.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryCard
                exportCard
                disclaimerCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.tzBackground.ignoresSafeArea())
        .sheet(isPresented: $showShare) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Year")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.tzSecondary)
                Spacer()
                Picker("Year", selection: $selectedYear) {
                    ForEach(availableYears.isEmpty ? [selectedYear] : availableYears, id: \.self) {
                        Text(String($0))
                    }
                }
                .pickerStyle(.menu).tint(Color.tzPrimary)
            }
            Divider()
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Donations").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.tzSecondary)
                    Text("\(filteredDonations.count)").font(.system(size: 20, weight: .bold)).foregroundStyle(Color.tzPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Given").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.tzSecondary)
                    Text(currencyString(totalForYear)).font(.system(size: 20, weight: .bold)).foregroundStyle(Color.tzPrimary)
                }
            }
        }
        .padding(16).cardStyle()
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.tzPrimary)
            Text("Generate a PDF summary of your \(selectedYear) donations — ready for your accountant or tax records.")
                .font(.system(size: 13)).foregroundStyle(Color.tzSecondary).lineSpacing(3)
            Button {
                generateAndShare()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isGenerating ? "Generating…" : "Export PDF")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(filteredDonations.isEmpty ? Color.tzSecondary : Color.tzPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(filteredDonations.isEmpty || isGenerating)
        }
        .padding(16).cardStyle()
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(Color.tzGold).font(.system(size: 16))
            Text("These documents can be used as supporting records for tax deductions. Consult your tax advisor for guidance.")
                .font(.system(size: 12)).foregroundStyle(Color.tzSecondary).lineSpacing(3)
        }
        .padding(14)
        .background(Color.tzGold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func generateAndShare() {
        isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url = generatePDF()
            DispatchQueue.main.async {
                exportURL = url
                isGenerating = false
                showShare = true
            }
        }
    }

    private func generatePDF() -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor(red: 0.102, green: 0.231, blue: 0.431, alpha: 1)
            ]
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.systemGray
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            "Give — Donation Summary".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttrs)
            "Year: \(selectedYear)  |  Generated: \(Date.now.formatted(.dateTime.month().day().year()))".draw(at: CGPoint(x: 50, y: 85), withAttributes: subtitleAttrs)
            "Total Given: \(currencyString(totalForYear))".draw(at: CGPoint(x: 50, y: 105), withAttributes: subtitleAttrs)

            var y: CGFloat = 140
            let headers = ["Date", "Charity", "Category", "Amount"]
            let xs: [CGFloat] = [50, 130, 340, 490]
            for (i, h) in headers.enumerated() {
                h.draw(at: CGPoint(x: xs[i], y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: UIColor.systemGray])
            }
            y += 20
            UIColor.systemGray4.setFill()
            UIRectFill(CGRect(x: 50, y: y, width: 512, height: 1))
            y += 8

            for donation in filteredDonations {
                if y > 720 { ctx.beginPage(); y = 50 }
                let row = [
                    donation.date.formatted(.dateTime.month(.abbreviated).day()),
                    String(donation.charityName.prefix(28)),
                    String(donation.category.prefix(24)),
                    currencyString(donation.amount)
                ]
                for (i, cell) in row.enumerated() {
                    cell.draw(at: CGPoint(x: xs[i], y: y), withAttributes: bodyAttrs)
                }
                y += 20
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Give_\(selectedYear)_Donations.pdf")
        try? data.write(to: url)
        return url
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
