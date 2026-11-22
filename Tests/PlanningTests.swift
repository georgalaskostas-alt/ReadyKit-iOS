import Foundation

// Small model stand-in: test the actual calculator and advisor without SwiftData/iOS.
enum ItemCategory: String { case water, food, firstAid, medication, power, hygiene }
struct EmergencyItem {
    var category: ItemCategory
    var quantity: Int = 1
    var litersPerUnit: Double = 0
    var caloriesPerUnit: Double = 0
    var daysUntilExpiration: Int? = nil
    var requiresCookingRaw: String? = nil
    var requiresRefrigerationRaw: String? = nil
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
        let unknownWater = ReadinessCalculator(items: [.init(category: .water)], people: 4, targetDays: 30)
        let uncertain = PreparednessAdvisor(calculator: unknownWater).recommendations
        check(uncertain.first?.id == "measure", "Missing amounts must come before buying prompts")
        check(!uncertain.contains { $0.id == "water" }, "Withhold water purchase gap with unknown liters")
        check(uncertain.contains { $0.id == "food" }, "Other measured categories still get gaps")
        let unknownFood = ReadinessCalculator(items: [.init(category: .food)], people: 4, targetDays: 30)
        check(!PreparednessAdvisor(calculator: unknownFood).recommendations.contains { $0.id == "food" }, "Withhold food purchase gap with unknown calories")
        check(PreparednessAdvisor(calculator: unknownFood, scenario: .outage).recommendations.contains { $0.id == "preparation-data" }, "Unknown prep requirements stay unknown")
        let prepFood = ReadinessCalculator(items: [.init(category: .food, caloriesPerUnit: 1000, requiresCookingRaw: "yes", requiresRefrigerationRaw: "no")], people: 1, targetDays: 3)
        check(PreparednessAdvisor(calculator: prepFood, scenario: .outage).recommendations.contains { $0.id == "dependent-food" }, "Cooking dependency flagged")
        let readyFood = ReadinessCalculator(items: [.init(category: .food, caloriesPerUnit: 1000, requiresCookingRaw: "no", requiresRefrigerationRaw: "no")], people: 1, targetDays: 3)
        check(!PreparednessAdvisor(calculator: readyFood, scenario: .outage).recommendations.contains { $0.id == "dependent-food" || $0.id == "preparation-data" }, "Known no-cook stock has no utility warning")
        var profile = HouseholdProfile(members: [HouseholdMember()])
        check(profile.isValid, "Unknown age is allowed")
        profile.members[0].birthYear = "bad"
        check(!profile.isValid, "Invalid year rejected")
        profile.members[0].birthYear = String(Calendar.current.component(.year, from: Date()) - 7)
        profile.members[0].allergies = "peanut"
        check(profile.members[0].isChild && profile.hasDietaryConstraints, "Child and allergy context")
        let profileAdvice = PreparednessAdvisor(calculator: empty, profile: profile).recommendations
        check(profileAdvice.contains { $0.id == "profile-count" } && profileAdvice.contains { $0.id == "dietary-review" }, "Profile discrepancy and diet prompt")
        let json = String(data: try! JSONEncoder().encode(profile), encoding: .utf8)!
        check(HouseholdProfile.decode(json)?.members[0].allergies == "peanut", "Profile roundtrip")
        check(HouseholdProfile.decode("invalid") == nil, "Corrupt profile not silently overwritten")
        print("Passed \(checks) planning checks")
    }
}

