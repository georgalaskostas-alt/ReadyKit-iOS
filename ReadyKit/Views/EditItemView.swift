import SwiftUI
import SwiftData
import PhotosUI

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    let item: EmergencyItem
    @State private var name: String; @State private var category: ItemCategory; @State private var quantity: Int; @State private var unit: String
    @State private var hasExpiration: Bool; @State private var expirationDate: Date; @State private var storageLocation: String; @State private var notes: String; @State private var barcode: String
    @State private var litersPerUnit: Double; @State private var caloriesPerUnit: Double; @State private var photoData: Data?; @State private var selectedPhoto: PhotosPickerItem?; @State private var showingScanner = false; @State private var showingCamera = false
    private var isGreek: Bool { appLanguage == AppLanguage.greek.rawValue }; private func t(_ el: String, _ en: String) -> String { isGreek ? el : en }

    init(item: EmergencyItem) {
        self.item = item; _name = State(initialValue: item.name); _category = State(initialValue: item.category); _quantity = State(initialValue: item.quantity); _unit = State(initialValue: item.unit); _hasExpiration = State(initialValue: item.expirationDate != nil); _expirationDate = State(initialValue: item.expirationDate ?? .now); _storageLocation = State(initialValue: item.storageLocation); _notes = State(initialValue: item.notes); _barcode = State(initialValue: item.barcode); _litersPerUnit = State(initialValue: item.litersPerUnit); _caloriesPerUnit = State(initialValue: item.caloriesPerUnit); _photoData = State(initialValue: item.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(t("Προϊόν", "Product")) {
                    HStack(spacing: 16) { photoPreview; VStack(alignment: .leading, spacing: 8) { PhotosPicker(selection: $selectedPhoto, matching: .images) { Label(t("Φωτογραφίες", "Photos"), systemImage: "photo.on.rectangle") }; Button { showingCamera = true } label: { Label(t("Λήψη φωτογραφίας", "Take Photo"), systemImage: "camera") } } }.task(id: selectedPhoto) { if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) { photoData = data } }
                    TextField(t("Όνομα", "Name"), text: $name)
                    Picker(t("Κατηγορία", "Category"), selection: $category) { ForEach(ItemCategory.allCases) { c in Label(categoryName(c), systemImage: c.symbol).tag(c) } }
                }
                Section(t("Ποσότητα", "Quantity")) { Stepper(t("Ποσότητα: \(quantity)", "Quantity: \(quantity)"), value: $quantity, in: 0...9999); TextField(t("Μονάδα", "Unit"), text: $unit) }
                if category == .water { Section(t("Νερό", "Water")) { TextField(t("Λίτρα ανά τεμάχιο", "Liters per item"), value: $litersPerUnit, format: .number).keyboardType(.decimalPad) } }
                if category == .food { Section(t("Τρόφιμα", "Food")) { TextField(t("Θερμίδες ανά τεμάχιο", "Calories per item"), value: $caloriesPerUnit, format: .number).keyboardType(.decimalPad) } }
                Section(t("Λήξη", "Expiration")) { Toggle(t("Έχει ημερομηνία λήξης", "Has expiration date"), isOn: $hasExpiration); if hasExpiration { DatePicker(t("Ημερομηνία", "Date"), selection: $expirationDate, displayedComponents: .date) } else { Label(t("Δεν έχει οριστεί ημερομηνία λήξης", "Expiration date not set"), systemImage: "calendar.badge.questionmark").font(.footnote).foregroundStyle(.secondary) } }
                Section(t("Στοιχεία", "Details")) { HStack { TextField("Barcode", text: $barcode); Button { showingScanner = true } label: { Image(systemName: "barcode.viewfinder").font(.title2) }.buttonStyle(.plain) }; TextField(t("Τοποθεσία", "Location"), text: $storageLocation); TextField(t("Σημειώσεις", "Notes"), text: $notes, axis: .vertical).lineLimit(3...6) }
            }.navigationTitle(t("Επεξεργασία", "Edit Item")).navigationBarTitleDisplayMode(.inline).id(appLanguage)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(t("Ακύρωση", "Cancel")) { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button(t("Αποθήκευση", "Save")) { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } }
            .sheet(isPresented: $showingScanner) { BarcodeScannerSheet { barcode = $0 } }
            .fullScreenCover(isPresented: $showingCamera) { CameraPicker { image in photoData = image.jpegData(compressionQuality: 0.82) } }
        }
    }
    @ViewBuilder private var photoPreview: some View { if let photoData, let image = UIImage(data: photoData) { Image(uiImage: image).resizable().scaledToFill().frame(width: 70, height: 70).clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous)) } else { RoundedRectangle(cornerRadius: 15).fill(.quaternary).frame(width: 70, height: 70).overlay { Image(systemName: "camera.fill").foregroundStyle(.secondary) } } }
    private func categoryName(_ c: ItemCategory) -> String { switch c { case .water: return t("Νερό", "Water"); case .food: return t("Τρόφιμα", "Food"); case .firstAid: return t("Πρώτες βοήθειες", "First Aid"); case .medication: return t("Φάρμακα", "Medication"); case .power: return t("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: return t("Υγιεινή", "Hygiene"); case .tools: return t("Εξοπλισμός", "Equipment"); case .documents: return t("Έγγραφα", "Documents"); case .other: return t("Άλλο", "Other") } }
    private func save() { item.name = name.trimmingCharacters(in: .whitespacesAndNewlines); item.category = category; item.quantity = quantity; item.unit = unit; item.expirationDate = hasExpiration ? expirationDate : nil; item.storageLocation = storageLocation; item.notes = notes; item.barcode = barcode; item.photoData = photoData; item.litersPerUnit = category == .water ? litersPerUnit : 0; item.caloriesPerUnit = category == .food ? caloriesPerUnit : 0; item.updatedAt = .now; try? modelContext.save(); Task { await NotificationManager.shared.scheduleExpirationNotifications(for: item) }; dismiss() }
}