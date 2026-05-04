import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleMonthlyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["monthly-reminder"])
        var comps = DateComponents()
        comps.day = 25; comps.hour = 10; comps.minute = 0
        let content = UNMutableNotificationContent()
        content.title = "Giving Reminder"
        content.body = "Have you made your charitable contributions this month?"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "monthly-reminder", content: content, trigger: trigger))
    }

    func scheduleGoalReminder(goalTarget: Double, yearTotal: Double) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["goal-pace"])
        guard goalTarget > 0 else { return }
        var comps = DateComponents()
        comps.month = 10; comps.day = 1; comps.hour = 9
        let content = UNMutableNotificationContent()
        content.title = "Giving Goal Check"
        let pct = Int((yearTotal / goalTarget) * 100)
        content.body = "You're \(pct)% toward your giving goal. \(pct < 75 ? "Time to catch up before year end!" : "Great progress, keep it up!")"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "goal-pace", content: content, trigger: trigger))
    }

    func scheduleAnniversaryReminders(donations: [Donation]) {
        let center = UNUserNotificationCenter.current()
        let cal = Calendar.current
        let now = Date.now
        let oneYearAgo = cal.date(byAdding: .year, value: -1, to: now)!
        let twoYearsAgo = cal.date(byAdding: .year, value: -2, to: now)!
        let anniversary = donations.filter { $0.date >= twoYearsAgo && $0.date <= oneYearAgo }
        var seen = Set<String>()
        for donation in anniversary {
            guard !seen.contains(donation.charityName) else { continue }
            seen.insert(donation.charityName)
            let id = "anniversary-\(abs(donation.charityName.hashValue))"
            center.removePendingNotificationRequests(withIdentifiers: [id])
            var comps = cal.dateComponents([.month, .day], from: donation.date)
            comps.hour = 10
            let content = UNMutableNotificationContent()
            content.title = "Giving Anniversary"
            content.body = "A year ago you donated to \(donation.charityName). Consider giving again!"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    func scheduleRecurringReminders(donations: [Donation]) {
        let center = UNUserNotificationCenter.current()
        let recurring = donations.filter { $0.isRecurring }
        var seen = Set<String>()
        for donation in recurring {
            guard !seen.contains(donation.charityName) else { continue }
            seen.insert(donation.charityName)
            let id = "recurring-\(abs(donation.charityName.hashValue))"
            center.removePendingNotificationRequests(withIdentifiers: [id])
            var comps = DateComponents()
            comps.day = 1; comps.hour = 9
            let content = UNMutableNotificationContent()
            content.title = "Recurring Donation Due"
            content.body = "Don't forget to log your \(donation.recurrenceInterval.lowercased()) donation to \(donation.charityName)."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    func schedulePlanNotifications(_ plan: [PlannedDonation]) {
        let center = UNUserNotificationCenter.current()
        let prefix = "plan-item-"
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
        let now = Date.now
        let cal = Calendar.current
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency; fmt.currencyCode = "USD"; fmt.maximumFractionDigits = 0
        for item in plan {
            guard item.date > now,
                  let notifyDate = cal.date(byAdding: .day, value: -1, to: item.date),
                  notifyDate > now else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: notifyDate)
            comps.hour = 9; comps.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "\(item.occasion) — giving reminder"
            let amtStr = fmt.string(from: NSNumber(value: item.amount)) ?? "$\(Int(item.amount))"
            content.body = "Your planned \(amtStr) gift is tomorrow. Ready to log it?"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "\(prefix)\(item.id.uuidString)",
                                             content: content, trigger: trigger))
        }
    }
}
