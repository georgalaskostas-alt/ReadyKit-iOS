import SwiftUI
import SwiftData

struct PreparednessView: View {
    @Query private var items: [EmergencyItem]
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 90
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue

    private var calculator: ReadinessCalculator { ReadinessCalculator(items: items, people: protectedPeople, targetDays: targetDays) }
    private var isGreek: Bool { appLanguage == AppLanguage.greek.rawValue }
    private func t(_ greek: String, _ english: String) -> String { isGreek ? greek : english }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    targetCard
                    readinessCard
                    checklistCard
                    Text(t("Οι υπολογισμοί χρησιμοποιούν προς το παρόν 3 L νερού και 2.000 kcal ανά άτομο/ημέρα. Στη συνέχεια τα όρια θα γίνουν παραμετροποιήσιμα.", "Calculations currently use 3 L of water and 2,000 kcal per person/day. These thresholds will become configurable next."))
                        .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
                }.padding(.horizontal, 18).padding(.bottom, 30)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(t("Ετοιμότητα", "Preparedness"))
            .id(appLanguage)
        }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(t("Στόχος", "Target"), symbol: "target")
            HStack(spacing: 12) {
                metric(t("Άτομα", "People"), value: "\(protectedPeople)", symbol: "person.2.fill")
                metric(t("Αυτονομία", "Autonomy"), value: targetLabel, symbol: "calendar.badge.clock")
            }
        }.cardStyle()
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle(t("Πραγματική επάρκεια", "Actual supplies"), symbol: "chart.bar.fill")
            supplyRow(title: t("Νερό", "Water"), symbol: "drop.fill", days: calculator.waterDays, progress: calculator.waterProgress, detail: "\(format(calculator.totalWaterLiters, decimals: 1)) / \(format(calculator.requiredWaterLiters, decimals: 0)) L", missing: calculator.missingWaterLiters > 0 ? t("Λείπουν \(format(calculator.missingWaterLiters, decimals: 0)) L", "Missing \(format(calculator.missingWaterLiters, decimals: 0)) L") : t("Ο στόχος καλύπτεται", "Target covered"))
            Divider()
            supplyRow(title: t("Τρόφιμα", "Food"), symbol: "fork.knife", days: calculator.foodDays, progress: calculator.foodProgress, detail: "\(Int(calculator.totalFoodCalories)) / \(Int(calculator.requiredFoodCalories)) kcal", missing: calculator.missingFoodCalories > 0 ? t("Λείπουν \(Int(calculator.missingFoodCalories)) kcal", "Missing \(Int(calculator.missingFoodCalories)) kcal") : t("Ο στόχος καλύπτεται", "Target covered"))
        }.cardStyle()
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle(t("Βασικό checklist", "Essential checklist"), symbol: "checklist").padding(.bottom, 8)
            ForEach(Array(essentialCategories.enumerated()), id: \.offset) { index, entry in
                let present = items.contains { $0.category == entry.category && $0.quantity > 0 }
                HStack(spacing: 14) {
                    Image(systemName: present ? "checkmark.circle.fill" : "circle").foregroundStyle(present ? .green : .secondary).font(.title3)
                    Image(systemName: entry.category.symbol).frame(width: 25).foregroundStyle(present ? .green : .primary)
                    Text(entry.title).font(.body)
                    Spacer()
                }.padding(.vertical, 13)
                if index < essentialCategories.count - 1 { Divider().padding(.leading, 76) }
            }
        }.cardStyle()
    }

    private var essentialCategories: [(category: ItemCategory, title: String)] {
        [(.water, t("Πόσιμο νερό", "Drinking water")), (.food, t("Τρόφιμα μακράς διάρκειας", "Long-life food")), (.firstAid, t("Κουτί πρώτων βοηθειών", "First aid kit")), (.medication, t("Απαραίτητα φάρμακα", "Essential medication")), (.power, t("Φακός / εφεδρική ενέργεια", "Flashlight / backup power")), (.hygiene, t("Είδη προσωπικής υγιεινής", "Personal hygiene supplies")), (.tools, t("Βασικός εξοπλισμός", "Essential equipment")), (.documents, t("Αντίγραφα σημαντικών εγγράφων", "Copies of important documents"))]
    }

    private func sectionTitle(_ title: String, symbol: String) -> some View { Label(title, systemImage: symbol).font(.title3.bold()) }
    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 7) { Image(systemName: symbol).foregroundStyle(.green); Text(value).font(.headline.bold()); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
    private func supplyRow(title: String, symbol: String, days: Double, progress: Double, detail: String, missing: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Label(title, systemImage: symbol).font(.headline).foregroundStyle(.primary); Spacer(); Text(t("~\(Int(days.rounded(.down))) ημέρες", "~\(Int(days.rounded(.down))) days")).font(.subheadline.bold()) }
            ProgressView(value: progress).tint(progress >= 1 ? .green : progress >= 0.5 ? .orange : .red)
            HStack { Text(detail); Spacer(); Text(missing).foregroundStyle(progress >= 1 ? .green : .secondary) }.font(.caption)
        }
    }
    private func format(_ value: Double, decimals: Int) -> String { value.formatted(.number.precision(.fractionLength(decimals))) }
    private var targetLabel: String { switch targetDays { case 60: t("2 μήνες", "2 months"); case 90: t("3 μήνες", "3 months"); case 180: t("6 μήνες", "6 months"); case 270: t("9 μήνες", "9 months"); case 365: t("12 μήνες", "12 months"); default: t("\(targetDays) ημέρες", "\(targetDays) days") } }
}

private extension View {
    func cardStyle() -> some View { self.padding(18).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous)) }
}
