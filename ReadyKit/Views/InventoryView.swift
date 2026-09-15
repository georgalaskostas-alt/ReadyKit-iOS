import SwiftUI
import SwiftData

struct InventoryView: View {
    @Query(sort: \EmergencyItem.name) private var items: [EmergencyItem]
    @State private var searchText = ""
    @State private var showingAddItem = false

    private var filteredItems: [EmergencyItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Το kit είναι άδειο",
                        systemImage: "shippingbox",
                        description: Text("Πρόσθεσε το πρώτο προϊόν ή εφόδιο στο ReadyKit.")
                    )
                } else {
                    List(filteredItems) { item in
                        ItemRow(item: item)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Αναζήτηση προϊόντος")
            .toolbar {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
        }
    }
}

private struct ItemRow: View {
    let item: EmergencyItem

    var body: some View {
        HStack(spacing: 14) {
            itemImage
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                Text("\(item.quantity) \(item.unit) • \(item.category.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let days = item.daysUntilExpiration {
                    Text(expirationText(days))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private var itemImage: some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.quaternary)
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: item.category.symbol)
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func expirationText(_ days: Int) -> String {
        if days < 0 { return "Έληξε πριν από \(abs(days)) ημέρες" }
        if days == 0 { return "Λήγει σήμερα" }
        return "Λήγει σε \(days) ημέρες"
    }

    private var statusColor: Color {
        switch item.expirationStatus {
        case .good, .noExpiration: .green
        case .soon: .orange
        case .urgent, .expired: .red
        }
    }
}
