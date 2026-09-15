import SwiftUI
import SwiftData

struct PreparednessView: View {
    @Query private var items: [EmergencyItem]

    private let essentials: [(ItemCategory, String)] = [
        (.water, "Πόσιμο νερό"),
        (.food, "Τρόφιμα μακράς διάρκειας"),
        (.firstAid, "Κουτί πρώτων βοηθειών"),
        (.medication, "Απαραίτητα φάρμακα"),
        (.power, "Φακός / εφεδρική ενέργεια"),
        (.hygiene, "Είδη προσωπικής υγιεινής"),
        (.tools, "Βασικός εξοπλισμός"),
        (.documents, "Αντίγραφα σημαντικών εγγράφων")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Το ReadyKit ελέγχει αν υπάρχουν βασικές κατηγορίες εφοδίων. Αργότερα θα υπολογίζει και επάρκεια ανά άτομο και ημέρα.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Βασικό checklist") {
                    ForEach(essentials, id: \.1) { category, title in
                        let present = items.contains { $0.category == category && $0.quantity > 0 }
                        HStack(spacing: 14) {
                            Image(systemName: present ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(present ? .green : .secondary)
                                .font(.title3)
                            Image(systemName: category.symbol)
                                .frame(width: 24)
                            Text(title)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Preparedness")
        }
    }
}
