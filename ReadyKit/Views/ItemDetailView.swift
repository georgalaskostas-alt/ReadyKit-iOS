import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    let item: EmergencyItem
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    private var isGreek: Bool { appLanguage == AppLanguage.greek.rawValue }
    private func t(_ el: String, _ en: String) -> String { isGreek ? el : en }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                VStack(spacing: 0) {
                    detailRow(t("Κατηγορία", "Category"), categoryName, symbol: item.category.symbol)
                    Divider(); detailRow(t("Ποσότητα", "Quantity"), "\(item.quantity) \(item.unit)", symbol: "number")
                    if let date = item.expirationDate { Divider(); detailRow(t("Λήξη", "Expiration"), date.formatted(date: .long, time: .omitted), symbol: "calendar") }
                    if !item.storageLocation.isEmpty { Divider(); detailRow(t("Τοποθεσία", "Location"), item.storageLocation, symbol: "archivebox") }
                    if !item.barcode.isEmpty { Divider(); detailRow("Barcode", item.barcode, symbol: "barcode") }
                    if item.category == .water && item.totalLiters > 0 { Divider(); detailRow(t("Συνολικό νερό", "Total water"), "\(item.totalLiters.formatted(.number.precision(.fractionLength(1)))) L", symbol: "drop.fill") }
                    if item.category == .food && item.totalCalories > 0 { Divider(); detailRow(t("Συνολικές θερμίδες", "Total calories"), "\(Int(item.totalCalories)) kcal", symbol: "flame.fill") }
                }.padding(.horizontal, 16).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) { Label(t("Σημειώσεις", "Notes"), systemImage: "note.text").font(.headline); Text(item.notes).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
                }
                if item.quantity > 0 {
                    Button { item.quantity -= 1; item.updatedAt = .now; try? modelContext.save() } label: { Label(t("Χρησιμοποίησα 1", "Used 1"), systemImage: "minus.circle.fill").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).tint(.green).controlSize(.large)
                }
            }.padding(18)
        }.background(Color(uiColor: .systemGroupedBackground)).navigationTitle(item.name).navigationBarTitleDisplayMode(.inline).id(appLanguage)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(t("Επεξεργασία", "Edit")) { showingEdit = true }
                Menu { Button(t("Διαγραφή", "Delete"), systemImage: "trash", role: .destructive) { showingDeleteConfirmation = true } } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) { EditItemView(item: item) }
        .confirmationDialog(t("Διαγραφή προϊόντος;", "Delete item?"), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(t("Διαγραφή", "Delete"), role: .destructive) { deleteItem() }; Button(t("Ακύρωση", "Cancel"), role: .cancel) {}
        } message: { Text(t("Το \(item.name) θα αφαιρεθεί οριστικά από το ReadyKit.", "\(item.name) will be permanently removed from ReadyKit.")) }
    }

    @ViewBuilder private var hero: some View {
        if let data = item.photoData, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill().frame(maxWidth: .infinity).frame(height: 260).clipShape(RoundedRectangle(cornerRadius: 26)) }
        else { RoundedRectangle(cornerRadius: 26).fill(.green.opacity(0.10)).frame(height: 210).overlay { Image(systemName: item.category.symbol).font(.system(size: 62)).foregroundStyle(.green) } }
    }
    private func detailRow(_ title: String, _ value: String, symbol: String) -> some View { HStack(spacing: 14) { Image(systemName: symbol).frame(width: 24).foregroundStyle(.green); Text(title).foregroundStyle(.secondary); Spacer(); Text(value).multilineTextAlignment(.trailing) }.padding(.vertical, 14) }
    private var categoryName: String { switch item.category { case .water: t("Νερό", "Water"); case .food: t("Τρόφιμα", "Food"); case .firstAid: t("Πρώτες βοήθειες", "First Aid"); case .medication: t("Φάρμακα", "Medication"); case .power: t("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: t("Υγιεινή", "Hygiene"); case .tools: t("Εξοπλισμός", "Equipment"); case .documents: t("Έγγραφα", "Documents"); case .other: t("Άλλο", "Other") } }
    private func deleteItem() { NotificationManager.shared.removeNotifications(for: item); modelContext.delete(item); try? modelContext.save(); dismiss() }
}
