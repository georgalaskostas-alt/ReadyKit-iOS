import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var items: [EmergencyItem]
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 90
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    @State private var showingAddItem = false
    @State private var showingQuickScanner = false

    private var calculator: ReadinessCalculator { ReadinessCalculator(items: items, people: protectedPeople, targetDays: targetDays) }
    private var expiringSoon: Int { items.filter { $0.expirationStatus == .soon || $0.expirationStatus == .urgent }.count }
    private var expired: Int { items.filter { $0.expirationStatus == .expired }.count }
    private var healthy: Int { items.filter { $0.expirationStatus == .good || $0.expirationStatus == .noExpiration }.count }
    private var readiness: Int {
        guard !items.isEmpty else { return 0 }
        let expiryScore = (Double(healthy) + Double(expiringSoon) * 0.65) / Double(items.count)
        let supplyScore = (calculator.waterProgress + calculator.foodProgress) / 2
        return Int((min(1, expiryScore * 0.45 + supplyScore * 0.55) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        hero
                        supplyCards
                        quickActions
                        categoriesSection
                        attentionSection
                        beReadyFooter
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("ReadyKit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddItem = true } label: {
                        Image(systemName: "plus").font(.title3.bold()).foregroundStyle(.white)
                            .frame(width: 42, height: 42).background(.green, in: Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) { AddItemView() }
            .sheet(isPresented: $showingQuickScanner) {
                BarcodeScannerSheet { _ in
                    showingQuickScanner = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showingAddItem = true }
                }
            }
            .id(appLanguage)
        }
    }

    private var hero: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image("readykit_water_card").resizable().scaledToFill().frame(width: geo.size.width, height: 250).clipped()
                LinearGradient(colors: [.black.opacity(0.04), .black.opacity(0.22), .black.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 15) {
                    Spacer()
                    HStack(alignment: .bottom, spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Label(t("ΕΤΟΙΜΟΤΗΤΑ ΟΙΚΟΓΕΝΕΙΑΣ", "HOUSEHOLD READINESS"), systemImage: "shield.fill").font(.caption2.bold()).tracking(1).foregroundStyle(.green).lineLimit(1)
                            Text(t("Η ετοιμότητά σου", "Your preparedness")).font(.title2.bold()).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.75)
                            Text(t("\(protectedPeople) άτομα • στόχος \(targetLabel)", "\(protectedPeople) people • \(targetLabel) target")).font(.subheadline).foregroundStyle(.white.opacity(0.72)).lineLimit(1).minimumScaleFactor(0.8)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        readinessRing
                    }
                    HStack {
                        Label(t("\(items.count) προϊόντα", "\(items.count) items"), systemImage: "shippingbox.fill")
                        Spacer()
                        Label(t("\(Set(items.map(\.categoryRaw)).count) κατηγορίες", "\(Set(items.map(\.categoryRaw)).count) categories"), systemImage: "square.grid.2x2.fill")
                    }.font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
                }.padding(18)
            }.frame(width: geo.size.width, height: 250).clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.10)))
        }.frame(height: 250)
    }

    private var readinessRing: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.18), lineWidth: 9)
            Circle().trim(from: 0, to: Double(readiness) / 100).stroke(readinessColor, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
            VStack(spacing: 0) { Text("\(readiness)%").font(.title3.bold().monospacedDigit()).foregroundStyle(.white); Text("READY").font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.58)) }
        }.frame(width: 78, height: 78)
    }

    private var supplyCards: some View {
        GeometryReader { geo in
            let cardWidth = max(0, (geo.size.width - 12) / 2)
            HStack(spacing: 12) {
                NavigationLink { InventoryView(category: .water) } label: {
                    SupplyImageCard(title: t("Νερό", "Water"), asset: "readykit_hero_mountains", symbol: "drop.fill", accent: .cyan, days: calculator.waterDays, progress: calculator.waterProgress, target: t("από \(Int(calculator.requiredWaterLiters)) L στόχο", "of \(Int(calculator.requiredWaterLiters)) L target"), appLanguage: appLanguage)
                }.buttonStyle(.plain).frame(width: cardWidth)
                NavigationLink { InventoryView(category: .food) } label: {
                    SupplyImageCard(title: t("Τρόφιμα", "Food"), asset: "readykit_food_card", symbol: "fork.knife", accent: .orange, days: calculator.foodDays, progress: calculator.foodProgress, target: t("από \(Int(calculator.requiredFoodCalories)) kcal στόχο", "of \(Int(calculator.requiredFoodCalories)) kcal target"), appLanguage: appLanguage)
                }.buttonStyle(.plain).frame(width: cardWidth)
            }
        }.frame(height: 154)
    }

    private var quickActions: some View {
        GeometryReader { geo in
            let scanWidth: CGFloat = 105
            let expirationWidth = max(0, geo.size.width - scanWidth - 12)
            HStack(spacing: 12) {
                NavigationLink { ExpirationCenterView() } label: {
                    ZStack(alignment: .bottomLeading) {
                        Image("readykit_expiration_card").resizable().scaledToFill().frame(width: expirationWidth, height: 108).clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t("Λήξεις & Rotation", "Expiration & Rotation")).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.75)
                            Text(t("\(expiringSoon + expired) για έλεγχο", "\(expiringSoon + expired) need attention")).font(.caption2).foregroundStyle(.white.opacity(0.72)).lineLimit(1)
                        }.padding(12)
                    }.frame(width: expirationWidth, height: 108).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.10)))
                }.buttonStyle(.plain)
                Button { showingQuickScanner = true } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "barcode.viewfinder").font(.system(size: 31, weight: .semibold)).foregroundStyle(.green)
                        Text("SCAN").font(.caption.bold()).tracking(1.4).foregroundStyle(.white)
                        Text(t("Προσθήκη", "Add item")).font(.caption2).foregroundStyle(.white.opacity(0.45))
                    }.frame(width: scanWidth, height: 108).background(LinearGradient(colors: [.green.opacity(0.17), .white.opacity(0.035)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 22, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.green.opacity(0.35)))
                }.buttonStyle(.plain)
            }
        }.frame(height: 108)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(t("Κατηγορίες", "Categories")).font(.title3.bold()).foregroundStyle(.white)
                Spacer()
                NavigationLink { InventoryView() } label: {
                    HStack(spacing: 5) { Text(t("Όλα", "See all")); Image(systemName: "chevron.right") }.font(.caption).foregroundStyle(.white.opacity(0.72))
                }.buttonStyle(.plain)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3), spacing: 10) {
                ForEach(ItemCategory.allCases.prefix(6)) { category in
                    NavigationLink { InventoryView(category: category) } label: {
                        categoryCard(category)
                    }.buttonStyle(.plain)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryCard(_ category: ItemCategory) -> some View {
        let count = items.filter { $0.category == category }.reduce(0) { $0 + $1.quantity }
        let accent = categoryAccent(category)
        return HStack(spacing: 8) {
            ZStack {
                Circle().fill(accent.opacity(0.18))
                Image(systemName: category.symbol).font(.system(size: 18, weight: .bold)).foregroundStyle(accent)
            }.frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName(category)).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.white).lineLimit(2).minimumScaleFactor(0.72)
                Text(t("\(count) τεμ.", "\(count) items")).font(.system(size: 10.5)).foregroundStyle(.white.opacity(0.62)).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2.bold()).foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 9).frame(maxWidth: .infinity, minHeight: 66)
        .background(LinearGradient(colors: [accent.opacity(0.18), accent.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.42), lineWidth: 0.8))
    }

    @ViewBuilder private var attentionSection: some View {
        let attention = items.filter { $0.expirationStatus == .urgent || $0.expirationStatus == .expired || $0.expirationStatus == .soon }.sorted { ($0.daysUntilExpiration ?? Int.max) < ($1.daysUntilExpiration ?? Int.max) }
        if !attention.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Text(t("Χρειάζονται προσοχή", "Needs attention")).font(.title3.bold()).foregroundStyle(.white); Spacer(); NavigationLink(t("Όλα", "See all")) { ExpirationCenterView() }.font(.subheadline.weight(.semibold)).foregroundStyle(.green) }
                ForEach(attention.prefix(3)) { item in
                    NavigationLink { ItemDetailView(item: item) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.category.symbol).foregroundStyle(.orange).frame(width: 42, height: 42).background(.orange.opacity(0.11), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name).fontWeight(.semibold).foregroundStyle(.white)
                                if let days = item.daysUntilExpiration { Text(days < 0 ? t("Έχει λήξει", "Expired") : t("Λήγει σε \(days) ημέρες", "Expires in \(days) days")).font(.caption).foregroundStyle(days <= 30 ? .red : .orange) }
                            }; Spacer()
                        }.padding(13).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var beReadyFooter: some View { Image("readykit_be_ready").resizable().scaledToFit().frame(maxWidth: 220).opacity(0.82).padding(.top, 2) }
    private var readinessColor: Color { readiness >= 80 ? .green : readiness >= 50 ? .orange : .red }
    private var targetLabel: String { targetDays >= 60 ? t("\(targetDays == 365 ? 12 : targetDays / 30) μήνες", "\(targetDays == 365 ? 12 : targetDays / 30) months") : t("\(targetDays) ημέρες", "\(targetDays) days") }
    private func t(_ el: String, _ en: String) -> String { appLanguage == AppLanguage.english.rawValue ? en : el }
    private func categoryAccent(_ c: ItemCategory) -> Color { switch c { case .water: return .cyan; case .food: return .orange; case .firstAid: return .red; case .medication: return .purple; case .power: return .yellow; case .hygiene: return .cyan; default: return .green } }
    private func categoryName(_ c: ItemCategory) -> String { switch c { case .water: return t("Νερό & Ροφήματα", "Water & Drinks"); case .food: return t("Τρόφιμα", "Food"); case .firstAid: return t("Πρώτες βοήθειες", "First Aid"); case .medication: return t("Φάρμακα", "Medication"); case .power: return t("Ρεύμα & Φως", "Power & Light"); case .hygiene: return t("Υγιεινή", "Hygiene"); case .tools: return t("Εξοπλισμός", "Equipment"); case .documents: return t("Έγγραφα", "Documents"); case .other: return t("Άλλο", "Other") } }
}

private struct SupplyImageCard: View {
    let title: String; let asset: String; let symbol: String; let accent: Color; let days: Double; let progress: Double; let target: String; let appLanguage: String
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Image(asset).resizable().scaledToFill().frame(width: geo.size.width, height: geo.size.height).clipped()
                LinearGradient(colors: [.black.opacity(0.02), .black.opacity(0.25), .black.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: symbol).font(.caption.bold()).foregroundStyle(accent).frame(width: 28, height: 28).background(accent.opacity(0.18), in: Circle())
                        Text(title).font(.headline.bold()).foregroundStyle(.white)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("~\(Int(days.rounded(.down)))").font(.title3.bold().monospacedDigit()).foregroundStyle(.white)
                        Text(appLanguage == AppLanguage.english.rawValue ? "days" : "ημέρες").font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    Text(target).font(.system(size: 10.5)).foregroundStyle(.white.opacity(0.72)).lineLimit(1).minimumScaleFactor(0.7)
                    HStack(spacing: 7) { ProgressView(value: progress).tint(accent); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.white.opacity(0.85)) }
                }.padding(12)
            }.frame(width: geo.size.width, height: geo.size.height).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 22).stroke(accent.opacity(0.28)))
        }
    }
}