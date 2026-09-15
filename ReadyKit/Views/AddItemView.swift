import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var category: ItemCategory = .food
    @State private var quantity = 1
    @State private var unit = "pcs"
    @State private var hasExpiration = true
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    @State private var storageLocation = "Emergency Kit"
    @State private var notes = ""
    @State private var barcode = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var litersPerUnit = 0.0
    @State private var caloriesPerUnit = 0.0
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("Προϊόν", "Product")) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 16) {
                            photoPreview
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.text(photoData == nil ? "Προσθήκη φωτογραφίας" : "Αλλαγή φωτογραφίας", photoData == nil ? "Add photo" : "Change photo"))
                                    .font(.headline)
                                Text(L10n.text("Από τη βιβλιοθήκη φωτογραφιών", "From your photo library"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .task(id: selectedPhoto) {
                        photoData = try? await selectedPhoto?.loadTransferable(type: Data.self)
                    }

                    TextField(L10n.text("Όνομα προϊόντος", "Product name"), text: $name)
                    Picker(L10n.text("Κατηγορία", "Category"), selection: $category) {
                        ForEach(ItemCategory.allCases) { item in
                            Label(categoryName(item), systemImage: item.symbol).tag(item)
                        }
                    }
                }

                Section(L10n.text("Barcode", "Barcode")) {
                    HStack {
                        TextField(L10n.text("Κωδικός barcode", "Barcode number"), text: $barcode)
                            .keyboardType(.numbersAndPunctuation)
                        Button { showingScanner = true } label: {
                            Image(systemName: "barcode.viewfinder").font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                    Button { showingScanner = true } label: {
                        Label(L10n.text("Σάρωση με κάμερα", "Scan with camera"), systemImage: "camera.viewfinder")
                    }
                }

                Section(L10n.text("Ποσότητα", "Quantity")) {
                    Stepper(L10n.text("Ποσότητα: \(quantity)", "Quantity: \(quantity)"), value: $quantity, in: 1...9999)
                    TextField(L10n.text("Μονάδα (π.χ. τεμ., L, kg)", "Unit (e.g. pcs, L, kg)"), text: $unit)
                }

                if category == .water {
                    Section(L10n.text("Υπολογισμός νερού", "Water calculation")) {
                        TextField(L10n.text("Λίτρα ανά τεμάχιο", "Liters per item"), value: $litersPerUnit, format: .number).keyboardType(.decimalPad)
                        LabeledContent(L10n.text("Συνολικό νερό", "Total water"), value: "\((litersPerUnit * Double(quantity)).formatted(.number.precision(.fractionLength(1)))) L")
                    }
                }

                if category == .food {
                    Section(L10n.text("Υπολογισμός τροφίμων", "Food calculation")) {
                        TextField(L10n.text("Θερμίδες ανά τεμάχιο", "Calories per item"), value: $caloriesPerUnit, format: .number).keyboardType(.decimalPad)
                        LabeledContent(L10n.text("Συνολικές θερμίδες", "Total calories"), value: "\(Int(caloriesPerUnit * Double(quantity))) kcal")
                    }
                }

                Section(L10n.text("Λήξη", "Expiration")) {
                    Toggle(L10n.text("Έχει ημερομηνία λήξης", "Has expiration date"), isOn: $hasExpiration)
                    if hasExpiration { DatePicker(L10n.text("Ημερομηνία", "Date"), selection: $expirationDate, displayedComponents: .date) }
                }

                Section(L10n.text("Αποθήκευση", "Storage")) {
                    TextField(L10n.text("Τοποθεσία", "Location"), text: $storageLocation)
                    TextField(L10n.text("Σημειώσεις", "Notes"), text: $notes, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle(L10n.text("Νέο προϊόν", "New Item"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.text("Ακύρωση", "Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Αποθήκευση", "Save")) { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerSheet { barcode = $0 }
            }
        }
    }

    @ViewBuilder private var photoPreview: some View {
        if let photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.quaternary).frame(width: 72, height: 72)
                .overlay { Image(systemName: "camera.fill").font(.title2).foregroundStyle(.secondary) }
        }
    }

    private func categoryName(_ category: ItemCategory) -> String {
        switch category {
        case .water: return L10n.text("Νερό", "Water")
        case .food: return L10n.text("Τρόφιμα", "Food")
        case .firstAid: return L10n.text("Πρώτες βοήθειες", "First Aid")
        case .medication: return L10n.text("Φάρμακα", "Medication")
        case .power: return L10n.text("Ρεύμα & Φωτισμός", "Power & Lighting")
        case .hygiene: return L10n.text("Υγιεινή", "Hygiene")
        case .tools: return L10n.text("Εξοπλισμός", "Equipment")
        case .documents: return L10n.text("Έγγραφα", "Documents")
        case .other: return L10n.text("Άλλο", "Other")
        }
    }

    private func save() {
        let item = EmergencyItem(name: name.trimmingCharacters(in: .whitespacesAndNewlines), category: category, quantity: quantity, unit: unit, expirationDate: hasExpiration ? expirationDate : nil, storageLocation: storageLocation, notes: notes, barcode: barcode, photoData: photoData, litersPerUnit: category == .water ? litersPerUnit : 0, caloriesPerUnit: category == .food ? caloriesPerUnit : 0)
        modelContext.insert(item)
        try? modelContext.save()
        Task { await NotificationManager.shared.scheduleExpirationNotifications(for: item) }
        dismiss()
    }
}
