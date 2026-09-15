import SwiftUI
import SwiftData

struct PreparednessView: View {
    @Query private var items: [EmergencyItem]
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 90

    private let essentials: [(ItemCategory, String)] = [
        (.water, "Πόσιμο νερό"),
        (.food, "Τρόφιμα μακράς διάρκειας"),
        (.firstAid, "Κουτί πρώτων βοηθειών"),
        (.medication, "Απαραίτητα φάρμακα"),
        (.power, "Φακός / εφεδρική ενέργεια"),
        (.hygiene, "Είδη προσωπικής υγιεινής"),
        (.tools, "Βασικός εξοπλισμός"),
        (.documents, "Αντίγραφα σημαντικών εγγράφων")
    ]

    private var calculator: ReadinessCalculator {
        ReadinessCalculator(items: items, people: protectedPeople, targetDays: targetDays)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Στόχος") {
                    LabeledContent("Άτομα", value: "\(protectedPeople)")
                    LabeledContent("Αυτονομία", value: targetLabel)
                }

                Section("Πραγματική επάρκεια") {
                    supplyRow(
                        title: "Νερό",
                        symbol: "drop.fill",
                        days: calculator.waterDays,
                        progress: calculator.waterProgress,
                        detail: "\(format(calculator.totalWaterLiters, decimals: 1)) / \(format(calculator.requiredWaterLiters, decimals: 0)) L",
                        missing: calculator.missingWaterLiters > 0 ? "Λείπουν \(format(calculator.missingWaterLiters, decimals: 0)) L" : "Ο στόχος καλύπτεται"
                    )

                    supplyRow(
                        title: "Τρόφιμα",
                        symbol: "fork.knife",
                        days: calculator.foodDays,
                        progress: calculator.foodProgress,
                        detail: "\(Int(calculator.totalFoodCalories)) / \(Int(calculator.requiredFoodCalories)) kcal",
                        missing: calculator.missingFoodCalories > 0 ? "Λείπουν \(Int(calculator.missingFoodCalories)) kcal" : "Ο στόχος καλύπτεται"
                    )
                }

                Section("Βασικό checklist") {
                    ForEach(essentials, id: \.1) { category, title in
                        let present = items.contains { $0.category == category && $0.quantity > 0 }
                        HStack(spacing: 14) {
                            Image(systemName: present ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(present ? .green : .secondary)
                                .font(.title3)
                            Image(systemName: category.symbol)
                                .frame(width: 24)
                            Text(title)
                            Spacer()
                        }
                    }
                }

                Section {
                    Text("Για τον αρχικό υπολογισμό χρησιμοποιούνται 3 L νερού και 2.000 kcal ανά άτομο/ημέρα. Θα κάνουμε αυτά τα όρια παραμετροποιήσιμα ώστε το πλάνο να ταιριάζει στις ανάγκες της οικογένειας.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Preparedness")
        }
    }

    @ViewBuilder
    private func supplyRow(title: String, symbol: String, days: Double, progress: Double, detail: String, missing: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.headline)
                Spacer()
                Text("~\(Int(days.rounded(.down))) ημέρες")
                    .font(.subheadline.bold())
            }
            ProgressView(value: progress)
                .tint(progress >= 1 ? .green : progress >= 0.5 ? .orange : .red)
            HStack {
                Text(detail)
                Spacer()
                Text(missing)
                    .foregroundStyle(progress >= 1 ? .green : .secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 5)
    }

    private func format(_ value: Double, decimals: Int) -> String {
        value.formatted(.number.precision(.fractionLength(decimals)))
    }

    private var targetLabel: String {
        switch targetDays {
        case 60: "2 μήνες"
        case 90: "3 μήνες"
        case 180: "6 μήνες"
        case 270: "9 μήνες"
        case 365: "12 μήνες"
        default: "\(targetDays) ημέρες"
        }
    }
}
