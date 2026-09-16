import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var items: [EmergencyItem]
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 90
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    @State private var showingAddItem = false

    private var calculator: ReadinessCalculator { ReadinessCalculator(items: items, people: protectedPeople, targetDays: targetDays) }
    private var expiringSoon: Int { items.filter { $0.expirationStatus == .soon || $0.expirationStatus == .urgent }.count }
    private var expired: Int { items.filter { $0.expirationStatus == .expired }.count }
    private var healthy: Int { items.filter { $0.expirationStatus == .good || $0.expirationStatus == .noExpiration }.count }
    private var readiness: Int { guard !items.isEmpty else { return 0 }; let expiryScore = (Double(healthy) + Double(expiringSoon) * 0.65) / Double(items.count); let supplyScore = (calculator.waterProgress + calculator.foodProgress) / 2; return Int((min(1, expiryScore * 0.45 + supplyScore * 0.55) * 100).rounded()) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(uiColor: .systemGroupedBackground), Color.green.opacity(0.06)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                ScrollView { VStack(spacing: 18) { hero; supplyCards; expirationShortcut; categoriesSection; attentionSection }.padding(.horizontal, 18).padding(.bottom, 32) }
            }
            .navigationTitle("ReadyKit")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showingAddItem = true } label: { Image(systemName: "plus").font(.headline).foregroundStyle(.white).frame(width: 38, height: 38).background(.green, in: Circle()) } } }
            .sheet(isPresented: $showingAddItem) { AddItemView() }.id(appLanguage)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) { Label(t("ΕΤΟΙΜΟΤΗΤΑ ΟΙΚΟΓΕΝΕΙΑΣ", "HOUSEHOLD READINESS"), systemImage: "shield.fill").font(.caption2.bold()).tracking(1).foregroundStyle(.green); Text(items.isEmpty ? t("Χτίσε το ReadyKit σου", "Build your ReadyKit") : t("Η ετοιμότητά σου", "Your preparedness")).font(.title2.bold()).foregroundStyle(.white); Text(t("\(protectedPeople) άτομα • στόχος \(targetLabel)", "\(protectedPeople) people • \(targetLabel) target")).font(.subheadline).foregroundStyle(.white.opacity(0.65)) }
                Spacer(); ZStack { Circle().stroke(.white.opacity(0.12), lineWidth: 9); Circle().trim(from: 0, to: Double(readiness) / 100).stroke(readinessColor, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90)); VStack(spacing: 0) { Text("\(readiness)%").font(.headline.bold().monospacedDigit()); Text("READY").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary) }.foregroundStyle(.white) }.frame(width: 82, height: 82)
            }
            HStack { Label(t("\(items.count) προϊόντα", "\(items.count) items"), systemImage: "shippingbox.fill"); Spacer(); Label(t("\(Set(items.map(\.categoryRaw)).count) κατηγορίες", "\(Set(items.map(\.categoryRaw)).count) categories"), systemImage: "square.grid.2x2.fill") }.font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
        }.padding(22).background(Color.black.opacity(0.90), in: RoundedRectangle(cornerRadius: 28, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.08)))
    }
    private var supplyCards: some View { HStack(spacing: 12) { SupplyMiniCard(title: t("Νερό", "Water"), symbol: "drop.fill", days: calculator.waterDays, progress: calculator.waterProgress, appLanguage: appLanguage); SupplyMiniCard(title: t("Τρόφιμα", "Food"), symbol: "fork.knife", days: calculator.foodDays, progress: calculator.foodProgress, appLanguage: appLanguage) } }
    private var expirationShortcut: some View {
        NavigationLink { ExpirationCenterView() } label: {
            HStack(spacing: 12) { Image(systemName: "arrow.triangle.2.circlepath.circle.fill").font(.title2).foregroundStyle(.orange); VStack(alignment: .leading, spacing: 3) { Text(t("Λήξεις & Rotation", "Expiration & Rotation")).font(.headline).foregroundStyle(.primary); Text(t("\(expiringSoon + expired) προϊόντα χρειάζονται προσοχή", "\(expiringSoon + expired) items need attention")).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }.buttonStyle(.plain)
    }
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) { Text(t("Κατηγορίες", "Categories")).font(.title3.bold()); LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(ItemCategory.allCases.prefix(6)) { category in let count = items.filter { $0.category == category }.reduce(0) { $0 + $1.quantity }; HStack(spacing: 12) { Image(systemName: category.symbol).foregroundStyle(.green).frame(width: 38, height: 38).background(.green.opacity(0.10), in: Circle()); VStack(alignment: .leading, spacing: 2) { Text(categoryName(category)).font(.subheadline.weight(.semibold)).lineLimit(1); Text(t("\(count) συνολικά", "\(count) total")).font(.caption).foregroundStyle(.secondary) }; Spacer(minLength: 0) }.padding(14).background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous)) } } }
    }
    @ViewBuilder private var attentionSection: some View {
        let attention = items.filter { $0.expirationStatus == .urgent || $0.expirationStatus == .expired || $0.expirationStatus == .soon }.sorted { ($0.daysUntilExpiration ?? Int.max) < ($1.daysUntilExpiration ?? Int.max) }
        if !attention.isEmpty { VStack(alignment: .leading, spacing: 12) { HStack { Text(t("Χρειάζονται προσοχή", "Needs attention")).font(.title3.bold()); Spacer(); NavigationLink(t("Όλα", "See all")) { ExpirationCenterView() }.font(.subheadline.weight(.semibold)) }; ForEach(attention.prefix(3)) { item in NavigationLink { ItemDetailView(item: item) } label: { HStack(spacing: 12) { Image(systemName: item.category.symbol).foregroundStyle(.orange).frame(width: 42, height: 42).background(.orange.opacity(0.10), in: Circle()); VStack(alignment: .leading, spacing: 3) { Text(item.name).fontWeight(.semibold).foregroundStyle(.primary); if let days = item.daysUntilExpiration { Text(days < 0 ? t("Έχει λήξει", "Expired") : t("Λήγει σε \(days) ημέρες", "Expires in \(days) days")).font(.caption).foregroundStyle(days <= 30 ? .red : .orange) } }; Spacer() }.padding(14).background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous)) }.buttonStyle(.plain) } } }
    }
    private var readinessColor: Color { readiness >= 80 ? .green : readiness >= 50 ? .orange : .red }
    private var targetLabel: String { targetDays >= 60 ? t("\(targetDays == 365 ? 12 : targetDays / 30) μήνες", "\(targetDays == 365 ? 12 : targetDays / 30) months") : t("\(targetDays) ημέρες", "\(targetDays) days") }
    private func t(_ el: String, _ en: String) -> String { appLanguage == AppLanguage.english.rawValue ? en : el }
    private func categoryName(_ c: ItemCategory) -> String { switch c { case .water: return t("Νερό", "Water"); case .food: return t("Τρόφιμα", "Food"); case .firstAid: return t("Πρώτες βοήθειες", "First Aid"); case .medication: return t("Φάρμακα", "Medication"); case .power: return t("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: return t("Υγιεινή", "Hygiene"); case .tools: return t("Εξοπλισμός", "Equipment"); case .documents: return t("Έγγραφα", "Documents"); case .other: return t("Άλλο", "Other") } }
}

private struct SupplyMiniCard: View {
    let title: String; let symbol: String; let days: Double; let progress: Double; let appLanguage: String
    var body: some View { VStack(alignment: .leading, spacing: 10) { HStack { Image(systemName: symbol).foregroundStyle(.green); Text(title).font(.subheadline.bold()); Spacer() }; HStack(alignment: .firstTextBaseline, spacing: 4) { Text("~\(Int(days.rounded(.down)))").font(.title2.bold().monospacedDigit()); Text(appLanguage == AppLanguage.english.rawValue ? "days" : "ημέρες").font(.caption).foregroundStyle(.secondary) }; ProgressView(value: progress).tint(progress >= 1 ? .green : progress >= 0.5 ? .orange : .red) }.padding(16).frame(maxWidth: .infinity).background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous)) }
}