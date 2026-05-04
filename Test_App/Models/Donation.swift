import SwiftData
import Foundation

@Model
final class Donation {
    var id: UUID
    var amount: Double
    var date: Date
    var charityName: String
    var category: String
    var notes: String
    var impactNote: String
    var isRecurring: Bool
    var recurrenceInterval: String
    var receiptPath: String?
    var receiptOriginalName: String?
    var createdAt: Date

    init(amount: Double, date: Date = .now, charityName: String,
         category: String, notes: String = "", impactNote: String = "",
         isRecurring: Bool = false, recurrenceInterval: String = "Monthly") {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.charityName = charityName
        self.category = category
        self.notes = notes
        self.impactNote = impactNote
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
        self.receiptPath = nil
        self.receiptOriginalName = nil
        self.createdAt = .now
    }
}
