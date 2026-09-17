import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    @Query(sort: \EmergencyItem.name) private var items: [EmergencyItem]
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var editingItem: EmergencyItem?
    @State private var deletingItem: EmergencyItem?

    let categoryFilter: ItemCategory?

    init(category: ItemCategory? = nil) {
        self.categoryFilter = category
    }

    private var categoryItems: [EmergencyItem] {
        guard let categoryFilter else { return items }
        return items.filter { $0.category == categoryFilter }
    }

    private var filteredItems: [EmergencyItem] {
        guard !searchText.isEmpty else { return categoryItems }
        return categoryItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            categoryName($0.category).localizedCaseInsensitiveContains(searchText)
        }
    }

    private var screenTitle: String {
        guard let categoryFilter else { return t("Απόθεμα", "Inventory") }
        return categoryName(categoryFilter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                if categoryItems.isEmpty {
                    ContentUnavailableView(
                        categoryFilter == nil ? t("Το kit είναι άδειο", "Your kit is empty") : t("Δεν υπάρχουν προϊόντα", "No items in this category"),
                        systemImage: categoryFilter?.symbol ?? "shippingbox",
                        description: Text(categoryFilter == nil ? t("Πρόσθεσε το πρώτο προϊόν ή εφόδιο στο ReadyKit.", "Add your first emergency supply to ReadyKit.") : t("Πρόσθεσε προϊόντα στην κατηγορία \(screenTitle).", "Add items to the \(screenTitle) category."))
                    )
                } else {
                    List {
                        Section {
                            ForEach(filteredItems) { item in
                                NavigationLink { ItemDetailView(item: item) } label: { ItemRow(item: item, appLanguage: appLanguage) }
                                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) { deletingItem = item } label: { Label(t("Διαγραφή", "Delete"), systemImage: "trash") }
                                        Button { editingItem = item } label: { Label(t("Επεξεργασία", "Edit"), systemImage: "pencil") }.tint(.orange)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button { changeQuantity(item, by: 1) } label: { Label("+1", systemImage: "plus") }.tint(.green)
                                        if item.quantity > 1 { Button { changeQuantity(item, by: -1) } label: { Label("−1", systemImage: "minus") }.tint(.blue) }
                                    }
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(screenTitle).font(.title2.bold()).textCase(nil).foregroundStyle(.primary)
                                Text(t("\(categoryItems.count) καταχωρήσεις", "\(categoryItems.count) entries")).font(.subheadline).foregroundStyle(.secondary).textCase(nil)
                            }.padding(.bottom, 4)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(screenTitle)
            .searchable(text: $searchText, prompt: t("Αναζήτηση προϊόντος", "Search items"))
            .toolbar { Button { showingAddItem = true } label: { Image(systemName: "plus").font(.headline).foregroundStyle(.white).frame(width: 36, height: 36).background(.green, in: Circle()) } }
            .sheet(isPresented: $showingAddItem) { AddItemView() }
            .sheet(item: $editingItem) { item in EditItemView(item: item) }
            .alert(t("Διαγραφή προϊόντος;", "Delete item?"), isPresented: Binding(get: { deletingItem != nil }, set: { if !$0 { deletingItem = nil } }), presenting: deletingItem) { item in
                Button(t("Διαγραφή", "Delete"), role: .destructive) { delete(item) }
                Button(t("Ακύρωση", "Cancel"), role: .cancel) { deletingItem = nil }
            } message: { item in Text(t("Το \(item.name) θα διαγραφεί οριστικά από το απόθεμα.", "\(item.name) will be permanently removed from your inventory.")) }
            .id(appLanguage)
        }
    }

    private func t(_ greek: String, _ english: String) -> String { appLanguage == AppLanguage.english.rawValue ? english : greek }
    private func changeQuantity(_ item: EmergencyItem, by delta: Int) { item.quantity = max(1, item.quantity + delta); item.updatedAt = .now; try? modelContext.save() }
    private func delete(_ item: EmergencyItem) { NotificationManager.shared.removeNotifications(for: item); modelContext.delete(item); try? modelContext.save(); deletingItem = nil }
    private func categoryName(_ c: ItemCategory) -> String { switch c { case .water: return t("Νερό & Ροφήματα", "Water & Drinks"); case .food: return t("Τρόφιμα", "Food"); case .firstAid: return t("Πρώτες βοήθειες", "First Aid"); case .medication: return t("Φάρμακα", "Medication"); case .power: return t("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: return t("Υγιεινή", "Hygiene"); case .tools: return t("Εξοπλισμός", "Equipment"); case .documents: return t("Έγγραφα", "Documents"); case .other: return t("Άλλο", "Other") } }
}

private struct ItemRow: View {
    let item: EmergencyItem
    let appLanguage: String
    var body: some View {
        HStack(spacing: 14) {
            itemImage
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name).font(.headline).foregroundStyle(.primary)
                Text("\(item.quantity) \(item.unit) • \(categoryName(item.category))").font(.subheadline).foregroundStyle(.secondary)
                if let days = item.daysUntilExpiration { Label(expirationText(days), systemImage: days <= 30 ? "exclamationmark.circle.fill" : "clock.fill").font(.caption.weight(.semibold)).foregroundStyle(statusColor) }
                else { Label(t("Χωρίς ορισμένη λήξη", "No expiration set"), systemImage: "calendar.badge.questionmark").font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
        }
        .padding(14).background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    @ViewBuilder private var itemImage: some View {
        if let data = item.photoData, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill().frame(width: 62, height: 62).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) }
        else { RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.green.opacity(0.10)).frame(width: 62, height: 62).overlay { Image(systemName: item.category.symbol).font(.title3).foregroundStyle(.green) } }
    }
    private func t(_ greek: String, _ english: String) -> String { appLanguage == AppLanguage.english.rawValue ? english : greek }
    private func expirationText(_ days: Int) -> String { if days < 0 { return t("Έληξε πριν από \(abs(days)) ημέρες", "Expired \(abs(days)) days ago") }; if days == 0 { return t("Λήγει σήμερα", "Expires today") }; return t("Λήγει σε \(days) ημέρες", "Expires in \(days) days") }
    private var statusColor: Color { switch item.expirationStatus { case .good, .noExpiration: return .green; case .soon: return .orange; case .urgent, .expired: return .red } }
    private func categoryName(_ c: ItemCategory) -> String { switch c { case .water: return t("Νερό & Ροφήματα", "Water & Drinks"); case .food: return t("Τρόφιμα", "Food"); case .firstAid: return t("Πρώτες βοήθειες", "First Aid"); case .medication: return t("Φάρμακα", "Medication"); case .power: return t("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: return t("Υγιεινή", "Hygiene"); case .tools: return t("Εξοπλισμός", "Equipment"); case .documents: return t("Έγγραφα", "Documents"); case .other: return t("Άλλο", "Other") } }
}