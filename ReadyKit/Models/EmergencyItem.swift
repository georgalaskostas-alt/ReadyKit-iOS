import Foundation
import SwiftData

@Model
final class EmergencyItem {
    var id: UUID
    var name: String
    var categoryRaw: String
    var quantity: Int
    var unit: String
    var expirationDate: Date?
    var storageLocation: String
    var notes: String
    var barcode: String
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        category: ItemCategory = .food,
        quantity: Int = 1,
        unit: String = "τεμ.",
        expirationDate: Date? = nil,
        storageLocation: String = "Emergency Kit",
        notes: String = "",
        barcode: String = "",
        photoData: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.quantity = quantity
        self.unit = unit
        self.expirationDate = expirationDate
        self.storageLocation = storageLocation
        self.notes = notes
        self.barcode = barcode
        self.photoData = photoData
        self.createdAt = .now
        self.updatedAt = .now
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var daysUntilExpiration: Int? {
        guard let expirationDate else { return nil }
        return Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: expirationDate)
        ).day
    }

    var expirationStatus: ExpirationStatus {
        guard let daysUntilExpiration else { return .noExpiration }
        switch daysUntilExpiration {
        case ..<0: return .expired
        case 0...30: return .urgent
        case 31...90: return .soon
        default: return .good
        }
    }
}

enum ItemCategory: String, CaseIterable, Codable, Identifiable {
    case water = "Νερό"
    case food = "Τρόφιμα"
    case firstAid = "Πρώτες βοήθειες"
    case medication = "Φάρμακα"
    case power = "Ρεύμα & Φωτισμός"
    case hygiene = "Υγιεινή"
    case tools = "Εξοπλισμός"
    case documents = "Έγγραφα"
    case other = "Άλλο"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .water: "drop.fill"
        case .food: "fork.knife"
        case .firstAid: "cross.case.fill"
        case .medication: "pills.fill"
        case .power: "bolt.fill"
        case .hygiene: "hands.sparkles.fill"
        case .tools: "wrench.and.screwdriver.fill"
        case .documents: "doc.text.fill"
        case .other: "shippingbox.fill"
        }
    }
}

enum ExpirationStatus {
    case good, soon, urgent, expired, noExpiration

    var title: String {
        switch self {
        case .good: "OK"
        case .soon: "Λήγει σύντομα"
        case .urgent: "Άμεση αντικατάσταση"
        case .expired: "Έληξε"
        case .noExpiration: "Χωρίς λήξη"
        }
    }
}
