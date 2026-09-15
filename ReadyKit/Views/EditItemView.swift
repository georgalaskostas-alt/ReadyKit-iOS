import SwiftUI
import SwiftData
import PhotosUI

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let item: EmergencyItem

    @State private var name: String
    @State private var category: ItemCategory
    @State private var quantity: Int
    @State private var unit: String
    @State private var hasExpiration: Bool
    @State private var expirationDate: Date
    @State private var storageLocation: String
    @State private var notes: String
    @State private var barcode: String
    @State private var litersPerUnit: Double
    @State private var caloriesPerUnit: Double
    @State private var photoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?

    init(item: EmergencyItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _quantity = State(initialValue: item.quantity)
        _unit = State(initialValue: item.unit)
        _hasExpiration = State(initialValue: item.expirationDate != nil)
        _expirationDate = State(initialValue: item.expirationDate ?? (Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now))
        _storageLocation = State(initialValue: item.storageLocation)
        _notes = State(initialValue: item.notes)
        _barcode = State(initialValue: item.barcode)
        _litersPerUnit = State(initialValue: item.litersPerUnit)
        _caloriesPerUnit = State(initialValue: item.caloriesPerUnit)
        _photoData = State(initialValue: item.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Προϊόν") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoData == nil ? "Προσθήκη φωτογραφίας" : "Αλλαγή φωτογραφίας", systemImage: "photo")
                    }
                    .task(id: selectedPhoto) {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) { photoData = data }
                    }
                    TextField("Όνομα", text: $name)
                    Picker("Κατηγορία", selection: $category) {
                        ForEach(ItemCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbol).tag(category)
                        }
                    }
                }

                Section("Ποσότητα") {
                    Stepper("Ποσότητα: \(quantity)", value: $quantity, in: 0...9999)
                    TextField("Μονάδα", text: $unit)
                }

                if category == .water {
                    Section("Νερό") {
                        TextField("Λίτρα ανά τεμάχιο", value: $litersPerUnit, format: .number).keyboardType(.decimalPad)
                    }
                }
                if category == .food {
                    Section("Τρόφιμα") {
                        TextField("Θερμίδες ανά τεμάχιο", value: $caloriesPerUnit, format: .number).keyboardType(.decimalPad)
                    }
                }

                Section("Λήξη") {
                    Toggle("Έχει ημερομηνία λήξης", isOn: $hasExpiration)
                    if hasExpiration { DatePicker("Ημερομηνία", selection: $expirationDate, displayedComponents: .date) }
                }

                Section("Στοιχεία") {
                    TextField("Barcode", text: $barcode)
                    TextField("Τοποθεσία", text: $storageLocation)
                    TextField("Σημειώσεις", text: $notes, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle("Επεξεργασία")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Ακύρωση") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Αποθήκευση") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.category = category
        item.quantity = quantity
        item.unit = unit
        item.expirationDate = hasExpiration ? expirationDate : nil
        item.storageLocation = storageLocation
        item.notes = notes
        item.barcode = barcode
        item.photoData = photoData
        item.litersPerUnit = category == .water ? litersPerUnit : 0
        item.caloriesPerUnit = category == .food ? caloriesPerUnit : 0
        item.updatedAt = .now
        try? modelContext.save()
        Task { await NotificationManager.shared.scheduleExpirationNotifications(for: item) }
        dismiss()
    }
}
