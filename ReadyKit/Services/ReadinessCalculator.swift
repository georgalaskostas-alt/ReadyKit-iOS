import Foundation

struct ReadinessCalculator {
    // Planning assumptions are deliberately visible and editable in one place.
    // Water: 4 L/person/day, rounded up from CDC 1 US gallon (~3.785 L).
    // Storage planning, not a prescribed drinking intake. Extra needs are not included.
    // Food: 2,000 kcal/person/day as a neutral planning baseline.
    static let waterLitersPerPersonPerDay = 4.0
    static let caloriesPerPersonPerDay = 2_000.0

    let items: [EmergencyItem]
    let people: Int
    let targetDays: Int

    var countedItems: [EmergencyItem] {
        items.filter { $0.quantity > 0 && ($0.daysUntilExpiration ?? 0) >= 0 }
    }
    var unmeasuredItems: [EmergencyItem] {
        countedItems.filter { ($0.category == .water && (!$0.litersPerUnit.isFinite || $0.litersPerUnit <= 0)) || ($0.category == .food && (!$0.caloriesPerUnit.isFinite || $0.caloriesPerUnit <= 0)) }
    }
    // This only describes the limiting water/energy stock, never overall safety.
    var supplyCoverage: Double { min(waterProgress, foodProgress) }

    var totalWaterLiters: Double {
        countedItems.filter { $0.category == .water && $0.totalLiters.isFinite && $0.totalLiters > 0 }.reduce(0) { $0 + $1.totalLiters }
    }

    var totalFoodCalories: Double {
        countedItems.filter { $0.category == .food && $0.totalCalories.isFinite && $0.totalCalories > 0 }.reduce(0) { $0 + $1.totalCalories }
    }

    var requiredWaterLiters: Double {
        Double(max(0, people)) * Double(max(0, targetDays)) * Self.waterLitersPerPersonPerDay
    }

    var requiredFoodCalories: Double {
        Double(max(0, people)) * Double(max(0, targetDays)) * Self.caloriesPerPersonPerDay
    }

    var waterDays: Double {
        guard people > 0 else { return 0 }
        return totalWaterLiters / (Double(people) * Self.waterLitersPerPersonPerDay)
    }

    var foodDays: Double {
        guard people > 0 else { return 0 }
        return totalFoodCalories / (Double(people) * Self.caloriesPerPersonPerDay)
    }

    var waterProgress: Double { progress(totalWaterLiters, requiredWaterLiters) }
    var foodProgress: Double { progress(totalFoodCalories, requiredFoodCalories) }

    var missingWaterLiters: Double { max(0, requiredWaterLiters - totalWaterLiters) }
    var missingFoodCalories: Double { max(0, requiredFoodCalories - totalFoodCalories) }

    private func progress(_ current: Double, _ required: Double) -> Double {
        guard required > 0 else { return 0 }
        return min(max(current / required, 0), 1)
    }
}

