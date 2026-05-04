import SwiftUI

enum Religion: String, CaseIterable, Identifiable, Codable {
    case christianity
    case judaism
    case islam
    case hinduism
    case buddhism
    case sikhism
    case bahai
    case secular

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .christianity: return "Christianity"
        case .judaism:      return "Judaism"
        case .islam:        return "Islam"
        case .hinduism:     return "Hinduism"
        case .buddhism:     return "Buddhism"
        case .sikhism:      return "Sikhism"
        case .bahai:        return "Bahá'í"
        case .secular:      return "Secular / Other"
        }
    }

    var givingTerm: String {
        switch self {
        case .christianity: return "Tithe"
        case .judaism:      return "Tzedaka"
        case .islam:        return "Zakat"
        case .hinduism:     return "Daan"
        case .buddhism:     return "Dāna"
        case .sikhism:      return "Dasvandh"
        case .bahai:        return "Huqúqu'lláh"
        case .secular:      return "Giving"
        }
    }

    var defaultGoalPercent: Double {
        switch self {
        case .christianity: return 10
        case .judaism:      return 10
        case .islam:        return 2.5
        case .hinduism:     return 10
        case .buddhism:     return 5
        case .sikhism:      return 10
        case .bahai:        return 19
        case .secular:      return 5
        }
    }

    var icon: String {
        switch self {
        case .christianity: return "cross.fill"
        case .judaism:      return "star.fill"
        case .islam:        return "moon.stars.fill"
        case .hinduism:     return "flame.fill"
        case .buddhism:     return "circle.hexagongrid.fill"
        case .sikhism:      return "circle.grid.cross.fill"
        case .bahai:        return "sparkles"
        case .secular:      return "heart.fill"
        }
    }

    var blurb: String {
        switch self {
        case .christianity: return "Traditional tithe — 10% of income."
        case .judaism:      return "Tzedaka — typically 10% of income."
        case .islam:        return "Zakat — 2.5% of qualifying wealth."
        case .hinduism:     return "Daan — selfless giving, often around 10%."
        case .buddhism:     return "Dāna — generous giving, no fixed amount."
        case .sikhism:      return "Dasvandh — one-tenth of earnings."
        case .bahai:        return "Huqúqu'lláh — 19% of surplus wealth."
        case .secular:      return "Giving on your own terms."
        }
    }
}

enum GivingFrequency: String, CaseIterable, Identifiable, Codable {
    case weekly      = "Weekly"
    case monthly     = "Monthly"
    case perOccasion = "Per occasion"
    case unsure      = "Not sure yet"

    var id: String { rawValue }
}
