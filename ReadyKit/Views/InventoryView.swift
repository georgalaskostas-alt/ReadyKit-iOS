import SwiftUI
import SwiftData

struct InventoryView: View {
    @Query(sort: \EmergencyItem.name) private var items: [EmergencyItem]
    @State private var searchText = ""
    @State private var showingAddItem = false

    private var filteredItems: [EmergencyItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) || categoryName($0.category).localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                if items.isEmpty {
                    ContentUnavailableView(L10n.text("Το kit είναι άδειο", "Your kit is empty"), systemImage: "shippingbox", description: Text(L10n.text("Πρόσθεσε το πρώτο προϊόν ή εφόδιο στο ReadyKit.", "Add your first emergency supply to ReadyKit.")))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 11) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(L10n.text("Απόθεμα", "Inventory")).font(.title2.bold())
                                    Text(L10n.text("\(items.count) καταχωρήσεις", "\(items.count) entries")).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }.padding(.bottom, 4)
                            ForEach(filteredItems) { item in
                                NavigationLink { ItemDetailView(item: item) } label: { ItemRow(item: item) }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 16).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle(L10n.text("Απόθεμα", "Inventory"))
            .searchable(text: $searchText, prompt: L10n.text("Αναζήτηση προϊόντος", "Search items"))
            .toolbar {
                Button { showingAddItem = true } label: {
                    Image(systemName: "plus").font(.headline).foregroundStyle(.white).frame(width: 36, height: 36).background(.green, in: Circle())
                }
            }
            .sheet(isPresented: $showingAddItem) { AddItemView() }
        }
    }

    private func categoryName(_ c: ItemCategory) -> String {
        switch c { case .water: L10n.text("Νερό", "Water"); case .food: L10n.text("Τρόφιμα", "Food"); case .firstAid: L10n.text("Πρώτες βοήθειες", "First Aid"); case .medication: L10n.text("Φάρμακα", "Medication"); case .power: L10n.text("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: L10n.text("Υγιεινή", "Hygiene"); case .tools: L10n.text("Εξοπλισμός", "Equipment"); case .documents: L10n.text("Έγγραφα", "Documents"); case .other: L10n.text("Άλλο", "Other") }
    }
}

private struct ItemRow: View {
    let item: EmergencyItem
    var body: some View {
        HStack(spacing: 14) {
            itemImage
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name).font(.headline).foregroundStyle(.primary)
                Text("\(item.quantity) \(item.unit) • \(categoryName(item.category))").font(.subheadline).foregroundStyle(.secondary)
                if let days = item.daysUntilExpiration { Label(expirationText(days), systemImage: days <= 30 ? "exclamationmark.circle.fill" : "clock.fill").font(.caption.weight(.semibold)).foregroundStyle(statusColor) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(14).background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder private var itemImage: some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 62, height: 62).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.green.opacity(0.10)).frame(width: 62, height: 62).overlay { Image(systemName: item.category.symbol).font(.title3).foregroundStyle(.green) }
        }
    }
    private func expirationText(_ days: Int) -> String { if days < 0 { return L10n.text("Έληξε πριν από \(abs(days)) ημέρες", "Expired \(abs(days)) days ago") }; if days == 0 { return L10n.text("Λήγει σήμερα", "Expires today") }; return L10n.text("Λήγει σε \(days) ημέρες", "Expires in \(days) days") }
    private var statusColor: Color { switch item.expirationStatus { case .good, .noExpiration: .green; case .soon: .orange; case .urgent, .expired: .red } }
    private func categoryName(_ c: ItemCategory) -> String { switch c { case .water: L10n.text("Νερό", "Water"); case .food: L10n.text("Τρόφιμα", "Food"); case .firstAid: L10n.text("Πρώτες βοήθειες", "First Aid"); case .medication: L10n.text("Φάρμακα", "Medication"); case .power: L10n.text("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: L10n.text("Υγιεινή", "Hygiene"); case .tools: L10n.text("Εξοπλισμός", "Equipment"); case .documents: L10n.text("Έγγραφα", "Documents"); case .other: L10n.text("Άλλο", "Other") } }
}
