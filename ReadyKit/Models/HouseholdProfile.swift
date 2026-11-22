import Foundation

struct HouseholdMember: Codable, Identifiable {
    var id = UUID()
    var label = ""
    var birthYear = ""
    var allergies = ""
    var dietaryNeeds = ""
    var regularMedication = false
    var year: Int? { Int(birthYear.trimmingCharacters(in: .whitespaces)) }
    var isChild: Bool {
        guard let year else { return false }
        return Calendar.current.component(.year, from: Date()) - year < 18
    }
}

struct HouseholdProfile: Codable {
    var members: [HouseholdMember] = []
    var pets = ""
    var cookingBackup = "unknown"
    var refrigerationBackup = "unknown"
    var updatedAt: Date? = nil
    static func decode(_ json: String) -> HouseholdProfile? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
    var hasDietaryConstraints: Bool {
        members.contains { !$0.allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !$0.dietaryNeeds.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    var isValid: Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (1...12).contains(members.count) && members.allSatisfy {
            $0.birthYear.trimmingCharacters(in: .whitespaces).isEmpty || ($0.year.map { (currentYear - 120...currentYear).contains($0) } ?? false)
        }
    }
}
