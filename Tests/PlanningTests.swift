import Foundation

// Small model stand-in: test the actual calculator and advisor without SwiftData/iOS.
enum ItemCategory: String { case water, food, firstAid, medication, power, hygiene }
struct EmergencyItem {
    var category: ItemCategory
    var quantity: Int = 1
    var litersPerUnit: Double = 0
    var caloriesPerUnit: Double = 0
    var daysUntilExpiration: Int? = nil
    var totalLiters: Double { Double(quantity) * litersPerUnit }
    var totalCalories: Double { Double(quantity) * caloriesPerUnit }
}

@main struct PlanningTests {
    static func main() {
        var checks = 0
        func check(_ condition: Bool, _ message: String) {
            precondition(condition, message)
            checks += 1
        }
        let empty = ReadinessCalculator(items: [], people: 4, targetDays: 30)
        check(empty.requiredWaterLiters == 480, "4 people x 30 days water")
        check(empty.requiredFoodCalories == 240_000, "Food baseline")
        check(empty.supplyCoverage == 0, "Empty stock is not ready")
        let stock = [EmergencyItem(category: .water, quantity: 10, litersPerUnit: 1.5), EmergencyItem(category: .water, litersPerUnit: 100, daysUntilExpiration: -1), EmergencyItem(category: .food, caloriesPerUnit: 2_000), EmergencyItem(category: .food, quantity: -5, caloriesPerUnit: 1_000), EmergencyItem(category: .water, litersPerUnit: .nan)]
        let calc = ReadinessCalculator(items: stock, people: 1, targetDays: 3)
        check(calc.totalWaterLiters == 15, "Expired and nonfinite amounts excluded")
        check(calc.totalFoodCalories == 2_000, "Negative stock excluded")
        check(calc.supplyCoverage == 1.0 / 3, "Limiting resource controls coverage")
        check(calc.unmeasuredItems.count == 1, "Invalid amounts flagged")
        let invalid = ReadinessCalculator(items: stock, people: 0, targetDays: -3)
        check(invalid.requiredWaterLiters == 0 && invalid.waterDays == 0 && invalid.supplyCoverage == 0, "Invalid inputs do not divide by zero")
        let advice = PreparednessAdvisor(calculator: calc, scenario: .outage, hasRegularMedication: true).recommendations
        check(advice.contains { $0.id == "outage" }, "Outage checklist")
        check(advice.contains { $0.id == "medication" }, "Medication prompt")
        check(advice.contains { $0.id == "expired" }, "Expired warning")
        check(Set(advice.map(\.id)).count == advice.count, "Stable unique identifiers")
        check(!advice.contains { $0.id == "water" }, "No water shopping prompt when covered")
        let full = ReadinessCalculator(items: [.init(category: .water, litersPerUnit: 500), .init(category: .food, caloriesPerUnit: 250_000)], people: 4, targetDays: 30)
        check(full.supplyCoverage == 1 && full.missingFoodCalories == 0, "Coverage capped")
        let dep = PreparednessAdvisor(calculator: full, hasChildren: true, hasPets: true).recommendations
        check(dep.contains { $0.id == "dependents" }, "Dependents prompt")
        print("Passed \(checks) planning checks")
    }
}
