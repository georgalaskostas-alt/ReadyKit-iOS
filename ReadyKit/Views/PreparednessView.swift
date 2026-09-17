import SwiftUI
import SwiftData

struct PreparednessView: View {
    @Query private var items: [EmergencyItem]
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 90
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue

    private var calculator: ReadinessCalculator { ReadinessCalculator(items: items, people: protectedPeople, targetDays: targetDays) }
    private var isGreek: Bool { appLanguage == AppLanguage.greek.rawValue }
    private func t(_ el: String, _ en: String) -> String { isGreek ? el : en }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        heroHeader
                        targetCard
                        suppliesCard
                        essentialDashboard
                        methodologyNote
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .id(appLanguage)
        }
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Image("readykit_water_card")
                .resizable().scaledToFill().frame(height: 150).clipped()
            LinearGradient(colors: [.black.opacity(0.12), .black.opacity(0.34), .black.opacity(0.95)], startPoint: .top, endPoint: .bottom)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(t("Ετοιμότητα", "Preparedness")).font(.largeTitle.bold()).foregroundStyle(.white)
                    Text(t("ΣΧΕΔΙΑΣΕ ΣΗΜΕΡΑ • ΠΙΟ ΑΣΦΑΛΕΣ ΑΥΡΙΟ", "PLAN TODAY • A SAFER TOMORROW"))
                        .font(.system(size: 10.5, weight: .semibold)).tracking(1.5).foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
                Image("readykit_be_ready").resizable().scaledToFit().frame(width: 105, height: 75).opacity(0.9)
            }.padding(16)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.green.opacity(0.18)))
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader(t("Στόχος", "Target"), subtitle: t("Οι στόχοι ετοιμότητάς σου", "Your preparedness goals"), symbol: "target")
            HStack(spacing: 10) {
                targetMetric(value: "\(protectedPeople)", title: t("Άτομα", "People"), subtitle: t("Μέλη οικογένειας", "Family members"), symbol: "person.2.fill")
                targetMetric(value: targetLabel, title: t("Αυτονομία", "Autonomy"), subtitle: t("Περίοδος αυτάρκειας", "Self-sufficient period"), symbol: "calendar.badge.clock")
            }
        }.premiumCard(accent: .green)
    }

    private var suppliesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(t("Πραγματική επάρκεια", "Actual supplies"), subtitle: t("Κάλυψη σε σχέση με τον στόχο", "Current coverage vs. target"), symbol: "chart.bar.fill")
            supplyRow(category: .water, title: t("Νερό", "Water"), value: "\(format(calculator.totalWaterLiters, decimals: 1)) / \(format(calculator.requiredWaterLiters, decimals: 0)) L", missing: calculator.missingWaterLiters > 0 ? t("Λείπουν \(format(calculator.missingWaterLiters, decimals: 0)) L", "Missing \(format(calculator.missingWaterLiters, decimals: 0)) L") : t("Ο στόχος καλύπτεται", "Target covered"), progress: calculator.waterProgress, accent: .cyan)
            supplyRow(category: .food, title: t("Τρόφιμα", "Food"), value: "\(Int(calculator.totalFoodCalories)) / \(Int(calculator.requiredFoodCalories)) kcal", missing: calculator.missingFoodCalories > 0 ? t("Λείπουν \(Int(calculator.missingFoodCalories)) kcal", "Missing \(Int(calculator.missingFoodCalories)) kcal") : t("Ο στόχος καλύπτεται", "Target covered"), progress: calculator.foodProgress, accent: .orange)
            HStack(spacing: 7) {
                miniCategory(.firstAid, title: t("Πρώτες", "First Aid"), accent: .red)
                miniCategory(.medication, title: t("Φάρμακα", "Medication"), accent: .purple)
                miniCategory(.power, title: t("Ρεύμα", "Power"), accent: .yellow)
                miniCategory(.hygiene, title: t("Υγιεινή", "Hygiene"), accent: .cyan)
            }
        }.premiumCard(accent: .cyan)
    }

    private var essentialDashboard: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(t("Βασικό checklist", "Essential checklist"), subtitle: t("Κρίσιμα είδη για την ετοιμότητά σου", "Key items for your preparedness"), symbol: "checklist")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 18) {
                readinessRing(.water, title: t("Πόσιμο νερό", "Drinking water"), accent: .cyan)
                readinessRing(.food, title: t("Τρόφιμα μακράς διάρκειας", "Long-life food"), accent: .orange)
                readinessRing(.firstAid, title: t("Πρώτες βοήθειες", "First aid kit"), accent: .red)
                readinessRing(.medication, title: t("Απαραίτητα φάρμακα", "Essential medication"), accent: .purple)
                readinessRing(.power, title: t("Φακός / ενέργεια", "Flashlight / backup power"), accent: .yellow)
                readinessRing(.hygiene, title: t("Είδη υγιεινής", "Hygiene supplies"), accent: .cyan)
            }
            HStack(spacing: 12) {
                Image(systemName: "quote.opening").font(.title2.bold()).foregroundStyle(.green)
                Text(t("Προετοιμασμένος σήμερα. Πιο ασφαλής αύριο.", "Prepared today. A safer tomorrow."))
                    .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.88))
                Spacer()
                Image("readykit_be_ready").resizable().scaledToFit().frame(width: 92, height: 54).opacity(0.72)
            }
            .padding(13).background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 17))
        }.premiumCard(accent: .cyan)
    }

    private var methodologyNote: some View {
        Text(t("Οι υπολογισμοί βασίζονται σε 3 L νερού και 2.000 kcal ανά άτομο/ημέρα.", "Calculations use 3 L of water and 2,000 kcal per person/day."))
            .font(.caption2).foregroundStyle(.white.opacity(0.38)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
    }

    private func sectionHeader(_ title: String, subtitle: String, symbol: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol).font(.title3.bold()).foregroundStyle(.white).shadow(color: .green.opacity(0.65), radius: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline.bold()).foregroundStyle(.white)
                Text(subtitle).font(.caption2).foregroundStyle(.white.opacity(0.58))
            }
            Spacer()
        }
    }

    private func targetMetric(value: String, title: String, subtitle: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol).font(.title3.bold()).foregroundStyle(.green)
            Text(value).font(.title3.bold()).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.75)
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.78))
            Text(subtitle).font(.system(size: 9.5)).foregroundStyle(.white.opacity(0.45)).lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(LinearGradient(colors: [.green.opacity(0.15), .green.opacity(0.055)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.green.opacity(0.28)))
    }

    private func supplyRow(category: ItemCategory, title: String, value: String, missing: String, progress: Double, accent: Color) -> some View {
        NavigationLink { InventoryView(initialCategory: category) } label: {
            HStack(spacing: 11) {
                Image(systemName: category.symbol).font(.title3.bold()).foregroundStyle(accent).frame(width: 48, height: 48).background(accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    HStack { Text(title).font(.subheadline.bold()).foregroundStyle(.white); Spacer(); Text("\(Int(min(progress, 1) * 100))%").font(.headline.bold()).foregroundStyle(progress >= 1 ? .green : progress >= 0.5 ? .orange : .red) }
                    Text(value).font(.caption).foregroundStyle(.white.opacity(0.72))
                    ProgressView(value: min(progress, 1)).tint(accent)
                    Text(missing).font(.system(size: 9.5)).foregroundStyle(.white.opacity(0.52)).frame(maxWidth: .infinity, alignment: .trailing)
                }
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.white.opacity(0.45))
            }.padding(10).background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 17))
        }.buttonStyle(.plain)
    }

    private func miniCategory(_ category: ItemCategory, title: String, accent: Color) -> some View {
        let p = categoryProgress(category)
        return NavigationLink { InventoryView(initialCategory: category) } label: {
            VStack(spacing: 4) {
                Image(systemName: category.symbol).font(.caption.bold()).foregroundStyle(accent)
                Text(title).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.65)
                Text("\(Int(p * 100))%").font(.caption2.bold()).foregroundStyle(accent)
            }.frame(maxWidth: .infinity, minHeight: 58).background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.25)))
        }.buttonStyle(.plain)
    }

    private func readinessRing(_ category: ItemCategory, title: String, accent: Color) -> some View {
        let progress = categoryProgress(category)
        return NavigationLink { InventoryView(initialCategory: category) } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle().stroke(.white.opacity(0.10), lineWidth: 8)
                    Circle().trim(from: 0, to: progress).stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%").font(.caption.bold().monospacedDigit()).foregroundStyle(.white)
                        Image(systemName: category.symbol).font(.caption.bold()).foregroundStyle(accent)
                    }
                }.frame(width: 72, height: 72)
                Text(title).font(.system(size: 10.5, weight: .medium)).foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center).lineLimit(2).frame(height: 28)
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }

    private func categoryProgress(_ category: ItemCategory) -> Double {
        if category == .water { return min(1, calculator.waterProgress) }
        if category == .food { return min(1, calculator.foodProgress) }
        return items.contains { $0.category == category && $0.quantity > 0 } ? 1 : 0
    }

    private func format(_ value: Double, decimals: Int) -> String { value.formatted(.number.precision(.fractionLength(decimals))) }
    private var targetLabel: String { switch targetDays { case 60: t("2 μήνες", "2 months"); case 90: t("3 μήνες", "3 months"); case 180: t("6 μήνες", "6 months"); case 270: t("9 μήνες", "9 months"); case 365: t("12 μήνες", "12 months"); default: t("\(targetDays) ημέρες", "\(targetDays) days") } }
}

private extension View {
    func premiumCard(accent: Color) -> some View {
        self.padding(16)
            .background(LinearGradient(colors: [accent.opacity(0.075), Color.white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(accent.opacity(0.24), lineWidth: 0.8))
    }
}
