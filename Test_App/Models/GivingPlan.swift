import Foundation

struct Holiday {
    let name: String
    let date: Date
    let religion: Religion?
    let category: String
    let weight: Double
}

struct PlannedDonation: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amount: Double
    let occasion: String
    let category: String
    let notes: String

    init(date: Date, amount: Double, occasion: String, category: String, notes: String) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.occasion = occasion
        self.category = category
        self.notes = notes
    }
}

enum GivingPlanner {

    static func generatePlan(annualGoal: Double,
                              alreadyGiven: Double,
                              religion: Religion,
                              frequency: GivingFrequency,
                              from: Date = .now) -> [PlannedDonation] {
        let remaining = max(annualGoal - alreadyGiven, 0)
        guard remaining > 0 else { return [] }

        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: from)
        let yearEnd = cal.date(from: DateComponents(year: year, month: 12, day: 31)) ?? from

        var candidates = upcomingHolidays(year: year, religion: religion, from: from, to: yearEnd)
        candidates += regularIntervals(frequency: frequency, from: from, to: yearEnd, religion: religion)
        candidates.sort { $0.date < $1.date }
        candidates = collapseSameDay(candidates)

        guard !candidates.isEmpty else { return [] }

        let totalWeight = candidates.reduce(0) { $0 + $1.weight }
        var plan: [PlannedDonation] = []
        var allocated: Double = 0
        for (i, h) in candidates.enumerated() {
            let isLast = (i == candidates.count - 1)
            let raw = remaining * (h.weight / totalWeight)
            let amount = isLast ? max(remaining - allocated, 0) : roundToNiceAmount(raw)
            allocated += amount
            if amount > 0 {
                plan.append(PlannedDonation(
                    date: h.date,
                    amount: amount,
                    occasion: h.name,
                    category: h.category,
                    notes: noteFor(h, religion: religion)
                ))
            }
        }
        return plan
    }

    // MARK: - Holiday tables

    private static func upcomingHolidays(year: Int, religion: Religion, from: Date, to: Date) -> [Holiday] {
        var hs: [Holiday] = []

        if let givingTuesday = givingTuesdayDate(year: year) {
            hs.append(Holiday(name: "Giving Tuesday", date: givingTuesday, religion: nil, category: "Other", weight: 1.4))
        }
        if let yearEnd = date(year: year, month: 12, day: 31) {
            hs.append(Holiday(name: "Year-End (Tax Deadline)", date: yearEnd, religion: nil, category: "Other", weight: 1.6))
        }

        switch religion {
        case .christianity:
            if let easter = easterDate(year: year) {
                hs.append(Holiday(name: "Easter", date: easter, religion: .christianity, category: "Religious", weight: 1.2))
                if let lent = cal().date(byAdding: .day, value: -46, to: easter) {
                    hs.append(Holiday(name: "Ash Wednesday", date: lent, religion: .christianity, category: "Religious", weight: 1.0))
                }
            }
            if let thanksgiving = thanksgivingDate(year: year) {
                hs.append(Holiday(name: "Thanksgiving", date: thanksgiving, religion: nil, category: "Food & Hunger", weight: 1.3))
            }
            if let christmas = date(year: year, month: 12, day: 25) {
                hs.append(Holiday(name: "Christmas", date: christmas, religion: .christianity, category: "Religious", weight: 1.5))
            }
        case .judaism:
            for h in jewishHolidays(year: year) { hs.append(h) }
        case .islam:
            for h in islamicHolidays(year: year) { hs.append(h) }
        case .hinduism:
            for h in hinduHolidays(year: year) { hs.append(h) }
        case .buddhism:
            for h in buddhistHolidays(year: year) { hs.append(h) }
        case .sikhism:
            for h in sikhHolidays(year: year) { hs.append(h) }
        case .bahai:
            for h in bahaiHolidays(year: year) { hs.append(h) }
        case .secular:
            break
        }

        return hs.filter { $0.date >= from && $0.date <= to }
    }

    private static func regularIntervals(frequency: GivingFrequency, from: Date, to: Date, religion: Religion) -> [Holiday] {
        let cal = self.cal()
        switch frequency {
        case .monthly:
            var out: [Holiday] = []
            var date = cal.date(bySetting: .day, value: 1, of: from) ?? from
            if date <= from { date = cal.date(byAdding: .month, value: 1, to: date) ?? date }
            while date <= to {
                out.append(Holiday(name: monthName(date) + " gift", date: date, religion: nil, category: "Other", weight: 0.6))
                date = cal.date(byAdding: .month, value: 1, to: date) ?? date
            }
            return out
        case .weekly:
            var out: [Holiday] = []
            var date = nextWeekday(.sunday, from: from)
            while date <= to {
                out.append(Holiday(name: "Weekly gift", date: date, religion: nil, category: "Other", weight: 0.2))
                date = cal.date(byAdding: .day, value: 7, to: date) ?? date
            }
            return out
        case .perOccasion, .unsure:
            return []
        }
    }

    // MARK: - Religion-specific calendars

    private static func jewishHolidays(year: Int) -> [Holiday] {
        var out: [Holiday] = []
        let table: [Int: [(String, Int, Int, String, Double)]] = [
            2026: [("Purim", 3, 3, "Religious", 1.1), ("Passover", 4, 2, "Food & Hunger", 1.2),
                   ("Rosh Hashanah", 9, 12, "Religious", 1.3), ("Yom Kippur", 9, 21, "Religious", 1.4),
                   ("Hanukkah", 12, 4, "Religious", 1.2)],
            2027: [("Purim", 3, 23, "Religious", 1.1), ("Passover", 4, 22, "Food & Hunger", 1.2),
                   ("Rosh Hashanah", 10, 2, "Religious", 1.3), ("Yom Kippur", 10, 11, "Religious", 1.4),
                   ("Hanukkah", 12, 25, "Religious", 1.2)],
        ]
        for (name, m, d, cat, w) in table[year] ?? [] {
            if let dt = date(year: year, month: m, day: d) {
                out.append(Holiday(name: name, date: dt, religion: .judaism, category: cat, weight: w))
            }
        }
        return out
    }

    private static func islamicHolidays(year: Int) -> [Holiday] {
        var out: [Holiday] = []
        let table: [Int: [(String, Int, Int, String, Double)]] = [
            2026: [("Ramadan begins", 2, 17, "Food & Hunger", 1.3), ("Laylat al-Qadr", 3, 14, "Religious", 1.4),
                   ("Eid al-Fitr", 3, 19, "Religious", 1.4), ("Eid al-Adha", 5, 26, "Religious", 1.3),
                   ("Day of Ashura", 6, 25, "Religious", 1.0)],
            2027: [("Ramadan begins", 2, 7, "Food & Hunger", 1.3), ("Laylat al-Qadr", 3, 4, "Religious", 1.4),
                   ("Eid al-Fitr", 3, 9, "Religious", 1.4), ("Eid al-Adha", 5, 16, "Religious", 1.3),
                   ("Day of Ashura", 6, 14, "Religious", 1.0)],
        ]
        for (name, m, d, cat, w) in table[year] ?? [] {
            if let dt = date(year: year, month: m, day: d) {
                out.append(Holiday(name: name, date: dt, religion: .islam, category: cat, weight: w))
            }
        }
        return out
    }

    private static func hinduHolidays(year: Int) -> [Holiday] {
        var out: [Holiday] = []
        let table: [Int: [(String, Int, Int, String, Double)]] = [
            2026: [("Holi", 3, 3, "Religious", 1.1), ("Navratri", 10, 11, "Religious", 1.2),
                   ("Diwali", 11, 8, "Religious", 1.5), ("Bhai Dooj", 11, 11, "Religious", 1.0)],
            2027: [("Holi", 3, 22, "Religious", 1.1), ("Navratri", 10, 1, "Religious", 1.2),
                   ("Diwali", 10, 28, "Religious", 1.5), ("Bhai Dooj", 10, 31, "Religious", 1.0)],
        ]
        for (name, m, d, cat, w) in table[year] ?? [] {
            if let dt = date(year: year, month: m, day: d) {
                out.append(Holiday(name: name, date: dt, religion: .hinduism, category: cat, weight: w))
            }
        }
        return out
    }

    private static func buddhistHolidays(year: Int) -> [Holiday] {
        var out: [Holiday] = []
        let table: [Int: [(String, Int, Int, String, Double)]] = [
            2026: [("Vesak", 5, 1, "Religious", 1.4), ("Asalha Puja", 7, 30, "Religious", 1.1),
                   ("Bodhi Day", 12, 8, "Religious", 1.2)],
            2027: [("Vesak", 5, 20, "Religious", 1.4), ("Asalha Puja", 7, 19, "Religious", 1.1),
                   ("Bodhi Day", 12, 8, "Religious", 1.2)],
        ]
        for (name, m, d, cat, w) in table[year] ?? [] {
            if let dt = date(year: year, month: m, day: d) {
                out.append(Holiday(name: name, date: dt, religion: .buddhism, category: cat, weight: w))
            }
        }
        return out
    }

    private static func sikhHolidays(year: Int) -> [Holiday] {
        var out: [Holiday] = []
        let table: [Int: [(String, Int, Int, String, Double)]] = [
            2026: [("Vaisakhi", 4, 14, "Religious", 1.3), ("Bandi Chhor Divas", 11, 8, "Religious", 1.2),
                   ("Guru Nanak Jayanti", 11, 24, "Religious", 1.4)],
            2027: [("Vaisakhi", 4, 14, "Religious", 1.3), ("Bandi Chhor Divas", 10, 28, "Religious", 1.2),
                   ("Guru Nanak Jayanti", 11, 13, "Religious", 1.4)],
        ]
        for (name, m, d, cat, w) in table[year] ?? [] {
            if let dt = date(year: year, month: m, day: d) {
                out.append(Holiday(name: name, date: dt, religion: .sikhism, category: cat, weight: w))
            }
        }
        return out
    }

    private static func bahaiHolidays(year: Int) -> [Holiday] {
        var out: [Holiday] = []
        let table: [Int: [(String, Int, Int, String, Double)]] = [
            2026: [("Naw-Rúz", 3, 21, "Religious", 1.2), ("First Day of Riḍván", 4, 20, "Religious", 1.3),
                   ("Birth of Bahá'u'lláh", 11, 9, "Religious", 1.2)],
            2027: [("Naw-Rúz", 3, 21, "Religious", 1.2), ("First Day of Riḍván", 4, 20, "Religious", 1.3),
                   ("Birth of Bahá'u'lláh", 10, 28, "Religious", 1.2)],
        ]
        for (name, m, d, cat, w) in table[year] ?? [] {
            if let dt = date(year: year, month: m, day: d) {
                out.append(Holiday(name: name, date: dt, religion: .bahai, category: cat, weight: w))
            }
        }
        return out
    }

    // MARK: - Date math

    private static func cal() -> Calendar { Calendar(identifier: .gregorian) }

    private static func date(year: Int, month: Int, day: Int) -> Date? {
        cal().date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func easterDate(year: Int) -> Date? {
        let a = year % 19, b = year / 100, c = year % 100
        let d = b / 4, e = b % 4, f = (b + 8) / 25
        let g = (b - f + 1) / 3, h = (19 * a + b - d - g + 15) % 30
        let i = c / 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return date(year: year, month: month, day: day)
    }

    private static func thanksgivingDate(year: Int) -> Date? {
        guard let nov1 = date(year: year, month: 11, day: 1) else { return nil }
        let weekday = cal().component(.weekday, from: nov1)
        let daysUntilThursday = (5 - weekday + 7) % 7
        let firstThursday = cal().date(byAdding: .day, value: daysUntilThursday, to: nov1)!
        return cal().date(byAdding: .day, value: 21, to: firstThursday)
    }

    private static func givingTuesdayDate(year: Int) -> Date? {
        guard let thanksgiving = thanksgivingDate(year: year) else { return nil }
        return cal().date(byAdding: .day, value: 5, to: thanksgiving)
    }

    private static func nextWeekday(_ weekday: Calendar.Weekday, from: Date) -> Date {
        let target = weekday.rawValue
        let current = cal().component(.weekday, from: from)
        let diff = (target - current + 7) % 7
        return cal().date(byAdding: .day, value: diff == 0 ? 7 : diff, to: from) ?? from
    }

    private static func monthName(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM"; return f.string(from: date)
    }

    private static func collapseSameDay(_ items: [Holiday]) -> [Holiday] {
        var seen = Set<String>(); var out: [Holiday] = []
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        for h in items {
            let key = f.string(from: h.date)
            if !seen.contains(key) { out.append(h); seen.insert(key) }
        }
        return out
    }

    private static func roundToNiceAmount(_ value: Double) -> Double {
        if value < 25 { return 18 }
        if value < 50 { return 25 }
        if value < 100 { return 50 }
        if value < 200 { return 100 }
        if value < 500 { return 250 }
        if value < 1000 { return 500 }
        return (value / 100).rounded() * 100
    }

    private static func noteFor(_ h: Holiday, religion: Religion) -> String {
        switch h.name {
        case "Year-End (Tax Deadline)": return "Eligible for this tax year."
        case "Giving Tuesday":          return "Global day of giving."
        case "Christmas":               return "Christmas season giving."
        case "Easter":                  return "Easter season giving."
        case "Ramadan begins", "Eid al-Fitr": return "Zakat al-Fitr / Ramadan giving."
        case "Yom Kippur":              return "Repentance and tzedaka."
        case "Diwali":                  return "Festival of lights."
        case "Vaisakhi":                return "New year celebration."
        default:                        return "\(h.name) gift."
        }
    }
}

private extension Calendar {
    enum Weekday: Int { case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday }
}
