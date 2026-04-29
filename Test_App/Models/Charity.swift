import SwiftData
import Foundation

@Model
final class Charity {
    var id: UUID
    var name: String
    var category: String
    var notes: String
    var link: String
    var createdAt: Date

    init(name: String, category: String, notes: String = "", link: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.notes = notes
        self.link = link
        self.createdAt = .now
    }
}
