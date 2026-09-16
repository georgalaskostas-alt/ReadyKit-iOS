import SwiftUI
import SwiftData

struct ExpirationCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    @Query private var items: [EmergencyItem]
    @State private var editingItem: EmergencyItem?

    private var datedItems: [EmergencyItem] {
        items.filter { $0.expirationDate != nil }.sorted { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
    }
    private var urgentItems: [EmergencyItem] { datedItems.filter { ($0.daysUntilExpiration ?? Int.max) <= 30 } }
    private var soonItems: [EmergencyItem] { datedItems.filter { let d = $0.daysUntilExpiration ?? Int.max; return d > 30 && d <= 90 } }
    private var laterItems: [EmergencyItem] { datedItems.filter { ($0.daysUntilExpiration ?? 0) > 90 } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summary
                if datedItems.isEmpty {
                    ContentUnavailableView(t("Δεν υπάρχουν λήξεις", "No expiration dates"), systemImage: "calendar.badge.checkmark", description: Text(t("Όταν ορίσεις ημερομηνίες λήξης, θα εμφανίζονται εδώ με σειρά προτεραιότητας.", "Items with expiration dates will appear here in priority order.")))
                } else {
                    group(t("Χρειάζονται προσοχή", "Needs attention"), items: urgentItems, color: .red)
                    group(t("Επόμενες 90 ημέρες", "Next 90 days"), items: soonItems, color: .orange)
                    group(t("Αργότερα", "Later"), items: laterItems, color: .green)
                }
            }.padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(t("Λήξεις & Rotation", "Expiration & Rotation"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingItem) { EditItemView(item: $0) }
        .id(appLanguage)
    }

    private var summary: some View {
        HStack(spacing: 12) {
            summaryBox(value: "\(urgentItems.count)", title: t("≤30 ημέρες", "≤30 days"), color: .red)
            summaryBox(value: "\(soonItems.count)", title: t("31–90 ημέρες", "31–90 days"), color: .orange)
            summaryBox(value: "\(laterItems.count)", title: t(">90 ημέρες", ">90 days"), color: .green)
        }
    }

    private func summaryBox(value: String, title: String, color: Color) -> some View {
        VStack(spacing: 4) { Text(value).font(.title2.bold()).foregroundStyle(color); Text(title).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center) }
            .frame(maxWidth: .infinity).padding(.vertical, 14).background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder private func group(_ title: String, items: [EmergencyItem], color: Color) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline)
                ForEach(items) { item in
                    NavigationLink { ItemDetailView(item: item) } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.12)).frame(width: 48, height: 48).overlay { Image(systemName: item.category.symbol).foregroundStyle(color) }
                            VStack(alignment: .leading, spacing: 3) { Text(item.name).font(.headline).foregroundStyle(.primary); Text(expirationText(item)).font(.caption.weight(.semibold)).foregroundStyle(color) }
                            Spacer(); Text("×\(item.quantity)").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        }.padding(12).background(.background, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }.buttonStyle(.plain).contextMenu { Button { editingItem = item } label: { Label(t("Επεξεργασία", "Edit"), systemImage: "pencil") } }
                }
            }
        }
    }

    private func expirationText(_ item: EmergencyItem) -> String {
        guard let days = item.daysUntilExpiration else { return "" }
        if days < 0 { return t("Έληξε πριν \(abs(days)) ημέρες", "Expired \(abs(days)) days ago") }
        if days == 0 { return t("Λήγει σήμερα", "Expires today") }
        return t("Λήγει σε \(days) ημέρες", "Expires in \(days) days")
    }
    private func t(_ el: String, _ en: String) -> String { appLanguage == AppLanguage.english.rawValue ? en : el }
}