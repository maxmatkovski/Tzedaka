import SwiftUI
import UIKit

extension Color {
    static let tzPrimary    = Color(red: 0.102, green: 0.231, blue: 0.431)
    static let tzGold       = Color(red: 0.769, green: 0.588, blue: 0.165)
    static let tzBackground = Color(red: 0.969, green: 0.953, blue: 0.937)
    static let tzCard       = Color.white
    static let tzSecondary  = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let tzSeparator  = Color(red: 0.898, green: 0.882, blue: 0.863)
    static let tzSuccess    = Color(red: 0.180, green: 0.490, blue: 0.369)
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.tzCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.tzPrimary)
                .clipShape(Capsule())
            }
        }
    }
}

let tzCategories = [
    "Education", "Food & Hunger", "Medical", "Disaster Relief",
    "Religious", "Environment", "Animal Welfare", "Arts & Culture", "Other"
]

func saveReceipt(_ data: Data, ext: String) -> String {
    let filename = "\(UUID().uuidString).\(ext)"
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("receipts")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try? data.write(to: dir.appendingPathComponent(filename))
    return filename
}

func sanitizedImageJPEG(_ image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.85) -> Data? {
    let longEdge = max(image.size.width, image.size.height)
    let scale = longEdge > maxDimension ? maxDimension / longEdge : 1
    let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1; format.opaque = true; format.preferredRange = .standard
    let renderer = UIGraphicsImageRenderer(size: target, format: format)
    let normalized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
    return normalized.jpegData(compressionQuality: quality)
}

func receiptURL(_ filename: String) -> URL? {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("receipts")
        .appendingPathComponent(filename)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

func deleteReceipt(_ filename: String) {
    guard let url = receiptURL(filename) else { return }
    try? FileManager.default.removeItem(at: url)
}

func currencyString(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.currencySymbol = "$"
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "$0"
}

func categoryIcon(_ category: String) -> String {
    switch category {
    case "Education":       return "book.fill"
    case "Food & Hunger":   return "fork.knife"
    case "Medical":         return "cross.fill"
    case "Disaster Relief": return "house.fill"
    case "Religious":       return "building.columns.fill"
    case "Environment":     return "leaf.fill"
    case "Animal Welfare":  return "pawprint.fill"
    case "Arts & Culture":  return "paintbrush.fill"
    default:                return "heart.fill"
    }
}
