import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let item: EmergencyItem
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                hero

                VStack(spacing: 0) {
                    detailRow("Κατηγορία", item.category.rawValue, symbol: item.category.symbol)
                    Divider()
                    detailRow("Ποσότητα", "\(item.quantity) \(item.unit)", symbol: "number")
                    if let expirationDate = item.expirationDate {
                        Divider()
                        detailRow("Λήξη", expirationDate.formatted(date: .long, time: .omitted), symbol: "calendar")
                    }
                    if !item.storageLocation.isEmpty {
                        Divider()
                        detailRow("Τοποθεσία", item.storageLocation, symbol: "archivebox")
                    }
                    if !item.barcode.isEmpty {
                        Divider()
                        detailRow("Barcode", item.barcode, symbol: "barcode")
                    }
                    if item.category == .water && item.totalLiters > 0 {
                        Divider()
                        detailRow("Συνολικό νερό", "\(item.totalLiters.formatted(.number.precision(.fractionLength(1)))) L", symbol: "drop.fill")
                    }
                    if item.category == .food && item.totalCalories > 0 {
                        Divider()
                        detailRow("Συνολικές θερμίδες", "\(Int(item.totalCalories)) kcal", symbol: "flame.fill")
                    }
                }
                .padding(.horizontal)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Σημειώσεις").font(.headline)
                        Text(item.notes).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                if item.quantity > 0 {
                    Button {
                        item.quantity -= 1
                        item.updatedAt = .now
                        try? modelContext.save()
                    } label: {
                        Label("Χρησιμοποίησα 1", systemImage: "minus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
                Menu {
                    Button("Διαγραφή", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditItemView(item: item)
        }
        .confirmationDialog("Διαγραφή προϊόντος;", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Διαγραφή", role: .destructive) { deleteItem() }
            Button("Ακύρωση", role: .cancel) {}
        } message: {
            Text("Το \(item.name) θα αφαιρεθεί οριστικά από το ReadyKit.")
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.quaternary)
                .frame(height: 220)
                .overlay {
                    Image(systemName: item.category.symbol)
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func detailRow(_ title: String, _ value: String, symbol: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).frame(width: 24).foregroundStyle(.green)
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14)
    }

    private func deleteItem() {
        NotificationManager.shared.removeNotifications(for: item)
        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}
