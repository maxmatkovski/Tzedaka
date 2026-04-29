import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Donation.date) private var donations: [Donation]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)

    private var availableYears: [Int] {
        let years = Set(donations.map { Calendar.current.component(.year, from: $0.date) })
        return Array(years.sorted().reversed())
    }

    private var yearDonations: [Donation] {
        donations.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
    }

    private var monthlyData: [(month: Int, total: Double)] {
        var data: [Int: Double] = [:]
        for d in yearDonations {
            let m = Calendar.current.component(.month, from: d.date)
            data[m, default: 0] += d.amount
        }
        return (1...12).map { m in (month: m, total: data[m] ?? 0) }
    }

    private var categoryData: [(category: String, total: Double)] {
        var data: [String: Double] = [:]
        for d in yearDonations { data[d.category, default: 0] += d.amount }
        return data.sorted { $0.value > $1.value }.map { (category: $0.key, total: $0.value) }
    }

    private var yearTotal: Double { yearDonations.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                yearPicker
                if yearDonations.isEmpty {
                    emptyState
                } else {
                    summaryRow
                    monthlyChart
                    if !categoryData.isEmpty { categoryChart }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.tzBackground.ignoresSafeArea())
    }

    private var yearPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                let years = availableYears.isEmpty
                    ? [Calendar.current.component(.year, from: .now)]
                    : availableYears
                ForEach(years, id: \.self) { year in
                    Button {
                        withAnimation { selectedYear = year }
                    } label: {
                        Text(String(year))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selectedYear == year ? .white : Color.tzPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(selectedYear == year ? Color.tzPrimary : Color.tzCard)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                }
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            insightTile("Total Given", value: currencyString(yearTotal))
            insightTile("Donations", value: "\(yearDonations.count)")
            insightTile("Avg Gift", value: yearDonations.isEmpty ? "$0"
                        : currencyString(yearTotal / Double(yearDonations.count)))
        }
    }

    private func insightTile(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.tzSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.tzPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardStyle()
    }

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Monthly Giving")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)

            Chart(monthlyData, id: \.month) { item in
                BarMark(
                    x: .value("Month", shortMonth(item.month)),
                    y: .value("Amount", item.total)
                )
                .foregroundStyle(item.total > 0 ? Color.tzPrimary : Color.tzSeparator)
                .cornerRadius(6)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(compactCurrency(v))
                                .font(.system(size: 10))
                                .foregroundStyle(Color.tzSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.tzSeparator)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(String.self) {
                            Text(v)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.tzSecondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("By Category")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.tzPrimary)

            VStack(spacing: 10) {
                ForEach(categoryData, id: \.category) { item in
                    HStack(spacing: 10) {
                        Image(systemName: categoryIcon(item.category))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.tzPrimary)
                            .frame(width: 20)
                        Text(item.category)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.tzPrimary)
                        Spacer()
                        Text(currencyString(item.total))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.tzPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.tzSeparator)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.tzGold)
                                .frame(width: geo.size.width * (item.total / (categoryData.first?.total ?? 1)),
                                       height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.tzGold.opacity(0.4))
            Text("No donations in \(String(selectedYear))")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.tzSecondary)
        }
        .padding(.top, 60)
    }

    private func shortMonth(_ m: Int) -> String {
        let formatter = DateFormatter()
        return formatter.shortMonthSymbols[m - 1]
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1000 { return "$\(Int(value / 1000))k" }
        return value == 0 ? "" : "$\(Int(value))"
    }
}
