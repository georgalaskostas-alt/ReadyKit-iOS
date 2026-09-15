import Foundation

struct ReadinessCalculator {
    // Planning assumptions are deliberately visible and editable in one place.
    // Water: 3 L/person/day for drinking and basic food preparation.
    // Food: 2,000 kcal/person/day as a neutral planning baseline.
    static let waterLitersPerPersonPerDay = 3.0
    static let caloriesPerPersonPerDay = 2_000.0

    let items: [EmergencyItem]
    let people: Int
    let targetDays: Int

    var totalWaterLiters: Double {
        items.filter { $0.category == .water }.reduce(0) { $0 + $1.totalLiters }
    }

    var totalFoodCalories: Double {
        items.filter { $0.category == .food }.reduce(0) { $0 + $1.totalCalories }
    }

    var requiredWaterLiters: Double {
        Double(people * targetDays) * Self.waterLitersPerPersonPerDay
    }

    var requiredFoodCalories: Double {
        Double(people * targetDays) * Self.caloriesPerPersonPerDay
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
