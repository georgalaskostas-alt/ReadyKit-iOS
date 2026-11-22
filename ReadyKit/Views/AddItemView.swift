import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss; @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue; @Query private var existingItems: [EmergencyItem]
    @State private var cooking = "unknown"
    @State private var refrigeration = "unknown"
    @State private var allergens = ""
    @State private var saveError: String?
    @State private var name = ""; @State private var category: ItemCategory = .food; @State private var quantity = 1; @State private var unit = "pcs"
    @State private var hasExpiration = false; @State private var expirationDate = Date.now; @State private var storageLocation = "Emergency Kit"; @State private var notes = ""; @State private var barcode: String
    @State private var selectedPhoto: PhotosPickerItem?; @State private var photoData: Data?; @State private var litersPerUnit = 0.0; @State private var caloriesPerUnit = 0.0
    @State private var showingScanner = false; @State private var showingCamera = false; @State private var showingExpiryCamera = false; @State private var isRecognizingExpiry = false; @State private var expiryMessage: String?
    @State private var isLookingUpProduct = false; @State private var lookupMessage: String?; @State private var lookupSucceeded = false; @State private var duplicateItem: EmergencyItem?; @State private var showingDuplicateAlert = false
    @State private var didAutoLookup = false

    init(initialBarcode: String = "") { _barcode = State(initialValue: initialBarcode) }

    var body: some View {
        NavigationStack { Form {
            Section(t("Προϊόν", "Product")) {
                HStack(spacing: 14) { photoPreview; VStack(alignment: .leading, spacing: 8) { PhotosPicker(selection: $selectedPhoto, matching: .images) { Label(t("Φωτογραφίες", "Photos"), systemImage: "photo.on.rectangle") }.buttonStyle(.borderless); Button { selectedPhoto = nil; showingCamera = true } label: { Label(t("Λήψη φωτογραφίας", "Take Photo"), systemImage: "camera") }.buttonStyle(.borderless) } }.task(id: selectedPhoto) { guard let selectedPhoto else { return }; if let data = try? await selectedPhoto.loadTransferable(type: Data.self), !Task.isCancelled, UIImage(data: data) != nil { photoData = data } }
                TextField(t("Όνομα προϊόντος", "Product name"), text: $name)
                Picker(t("Κατηγορία", "Category"), selection: $category) { ForEach(ItemCategory.allCases) { c in Label(categoryName(c), systemImage: c.symbol).tag(c) } }
            }
            Section(t("Barcode", "Barcode")) {
                HStack { TextField(t("Κωδικός barcode", "Barcode number"), text: $barcode).keyboardType(.numbersAndPunctuation); Button { showingScanner = true } label: { Image(systemName: "barcode.viewfinder").font(.title2) }.buttonStyle(.plain) }
                Button { showingScanner = true } label: { Label(t("Σάρωση barcode", "Scan barcode"), systemImage: "camera.viewfinder") }
                if !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { Button { Task { await lookupProduct() } } label: { HStack { Label(t("Εύρεση προϊόντος online", "Find product online"), systemImage: "sparkle.magnifyingglass"); Spacer(); if isLookingUpProduct { ProgressView() } } }.disabled(isLookingUpProduct) }
                if let lookupMessage { Label(lookupMessage, systemImage: lookupSucceeded ? "checkmark.circle.fill" : "info.circle.fill").font(.footnote).foregroundStyle(lookupSucceeded ? .green : .secondary) }
            }
            Section(t("Ποσότητα", "Quantity")) { Stepper(t("Ποσότητα: \(quantity)", "Quantity: \(quantity)"), value: $quantity, in: 1...9999); TextField(t("Μονάδα (π.χ. τεμ., L, kg)", "Unit (e.g. pcs, L, kg)"), text: $unit) }
            if category == .water { Section(t("Υπολογισμός νερού", "Water calculation")) { TextField(t("Λίτρα ανά τεμάχιο", "Liters per item"), value: $litersPerUnit, format: .number).keyboardType(.decimalPad); LabeledContent(t("Συνολικό νερό", "Total water"), value: "\((litersPerUnit * Double(quantity)).formatted(.number.precision(.fractionLength(1)))) L") } }
            if category == .food { Section(t("Υπολογισμός τροφίμων", "Food calculation")) { TextField(t("Θερμίδες ανά τεμάχιο", "Calories per item"), value: $caloriesPerUnit, format: .number).keyboardType(.decimalPad); LabeledContent(t("Συνολικές θερμίδες", "Total calories"), value: "\(Int(caloriesPerUnit * Double(quantity))) kcal") } }
            Section(t("Λήξη", "Expiration")) {
                Button { showingExpiryCamera = true } label: { HStack { Label(t("Σάρωση ημερομηνίας λήξης", "Scan expiry date"), systemImage: "text.viewfinder"); Spacer(); if isRecognizingExpiry { ProgressView() } } }.disabled(isRecognizingExpiry)
                Toggle(t("Έχει ημερομηνία λήξης", "Has expiration date"), isOn: $hasExpiration)
                if hasExpiration { DatePicker(t("Ημερομηνία", "Date"), selection: $expirationDate, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date) }
                else { Label(t("Δεν έχει οριστεί ημερομηνία λήξης", "Expiration date not set"), systemImage: "calendar.badge.questionmark").font(.footnote).foregroundStyle(.secondary) }
                if let expiryMessage { Text(expiryMessage).font(.footnote).foregroundStyle(hasExpiration ? .green : .orange) }
            }
            if category == .food { FoodPlanningFields(cooking: $cooking, refrigeration: $refrigeration, allergens: $allergens) }
            Section(t("Αποθήκευση", "Storage")) { TextField(t("Τοποθεσία", "Location"), text: $storageLocation); TextField(t("Σημειώσεις", "Notes"), text: $notes, axis: .vertical).lineLimit(3...6) }
        }
        .navigationTitle(t("Νέο προϊόν", "New Item")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button(t("Ακύρωση", "Cancel")) { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button(t("Αποθήκευση", "Save")) { saveOrCheckDuplicate() }.fontWeight(.semibold).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } }
        .task { guard !didAutoLookup else { return }; didAutoLookup = true; if !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { await lookupProduct() } }
        .sheet(isPresented: $showingScanner) { BarcodeScannerSheet { barcode = $0; Task { await lookupProduct() } } }
        .alert(t("Η αποθήκευση απέτυχε", "Save failed"), isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: { Text(saveError ?? "") }
        .fullScreenCover(isPresented: $showingCamera) { CameraPicker { photoData = $0.jpegData(compressionQuality: 0.82) } }
        .fullScreenCover(isPresented: $showingExpiryCamera) { CameraPicker { image in Task { await recognizeExpiry(image) } } }
        .alert(t("Το προϊόν υπάρχει ήδη", "Item already exists"), isPresented: $showingDuplicateAlert, presenting: duplicateItem) { existing in Button(t("Προσθήκη +\(quantity)", "Add +\(quantity)")) { addQuantity(to: existing) }; Button(t("Νέα παρτίδα", "Create new batch")) { saveNewItem() }; Button(t("Ακύρωση", "Cancel"), role: .cancel) {} } message: { existing in Text(t("Υπάρχουν ήδη \(existing.quantity) \(existing.unit) × \(existing.name). Αν η νέα συσκευασία έχει διαφορετική λήξη, επίλεξε Νέα παρτίδα.", "You already have \(existing.quantity) \(existing.unit) × \(existing.name). If this package has a different expiry date, create a new batch.")) }
        .id(appLanguage) }
    }
    @ViewBuilder private var photoPreview: some View { if let photoData, let image = UIImage(data: photoData) { Image(uiImage: image).resizable().scaledToFill().frame(width: 76, height: 76).clipShape(RoundedRectangle(cornerRadius: 16)) } else { RoundedRectangle(cornerRadius: 16).fill(.quaternary).frame(width: 76, height: 76).overlay { Image(systemName: "camera.fill").font(.title2).foregroundStyle(.secondary) } } }
    private func t(_ el: String, _ en: String) -> String { appLanguage == AppLanguage.english.rawValue ? en : el }
    private func categoryName(_ c: ItemCategory) -> String { switch c { case .water: return t("Νερό", "Water"); case .food: return t("Τρόφιμα", "Food"); case .firstAid: return t("Πρώτες βοήθειες", "First Aid"); case .medication: return t("Φάρμακα", "Medication"); case .power: return t("Ρεύμα & Φωτισμός", "Power & Lighting"); case .hygiene: return t("Υγιεινή", "Hygiene"); case .tools: return t("Εξοπλισμός", "Equipment"); case .documents: return t("Έγγραφα", "Documents"); case .other: return t("Άλλο", "Other") } }

    @MainActor private func recognizeExpiry(_ image: UIImage) async {
        isRecognizingExpiry = true; defer { isRecognizingExpiry = false }
        if let date = await ExpiryDateRecognizer.recognize(in: image) { expirationDate = date; hasExpiration = true; expiryMessage = t("Βρέθηκε: \(date.formatted(date: .numeric, time: .omitted)). Επιβεβαίωσε ότι είναι σωστή.", "Found: \(date.formatted(date: .numeric, time: .omitted)). Confirm it is correct.") }
        else { hasExpiration = false; expiryMessage = t("Δεν αναγνωρίστηκε ημερομηνία. Δοκίμασε πιο κοντινή/καθαρή φωτογραφία ή βάλε τη χειροκίνητα.", "No date recognized. Try a closer, clearer photo or enter it manually.") }
    }

    @MainActor private func lookupProduct() async {
        let code = barcode.trimmingCharacters(in: .whitespacesAndNewlines); guard !code.isEmpty, !isLookingUpProduct else { return }
        if let existing = existingItems.first(where: { !$0.barcode.isEmpty && $0.barcode == code }) { duplicateItem = existing; lookupMessage = t("Υπάρχει ήδη: \(existing.name) × \(existing.quantity)", "Already in inventory: \(existing.name) × \(existing.quantity)") }
        isLookingUpProduct = true; lookupSucceeded = false; if duplicateItem == nil { lookupMessage = t("Αναζήτηση προϊόντος…", "Looking up product…") }; defer { isLookingUpProduct = false }
        do {
            let result = try await ProductLookupService.shared.lookup(barcode: code)
            guard barcode.trimmingCharacters(in: .whitespacesAndNewlines) == code else { return }
            name = result.name
            if result.isWater { category = .water; if let liters = result.packageLiters { litersPerUnit = liters; unit = "pcs" } } else { category = .food; if let kcal = result.packageCalories { caloriesPerUnit = kcal }; unit = "pcs" }
            if photoData == nil, let imageURL = result.imageURL, let data = await ProductLookupService.shared.downloadImage(from: imageURL), UIImage(data: data) != nil, photoData == nil, barcode.trimmingCharacters(in: .whitespacesAndNewlines) == code { photoData = data }
            guard barcode.trimmingCharacters(in: .whitespacesAndNewlines) == code else { return }
            if let brand = result.brand, !brand.isEmpty, !name.localizedCaseInsensitiveContains(brand) { notes = notes.isEmpty ? brand : notes }
            lookupSucceeded = true
            let packageInfo = result.isWater && result.packageLiters != nil ? t(" • λίτρα συμπληρώθηκαν", " • liters filled") : (!result.isWater && result.packageCalories != nil ? t(" • θερμίδες συσκευασίας υπολογίστηκαν", " • package calories calculated") : "")
            lookupMessage = t("Βρέθηκε: \(result.name)", "Found: \(result.name)") + packageInfo
            if photoData == nil { lookupMessage = (lookupMessage ?? "") + t(" • Δεν φορτώθηκε φωτογραφία. Πρόσθεσε από τη συλλογή ή την κάμερα.", " • No photo loaded. Add one from Photos or Camera.") }
        } catch is CancellationError { return } catch let error as URLError where error.code == .cancelled { return } catch let error as URLError where error.code == .notConnectedToInternet { lookupMessage = t("Δεν υπάρχει σύνδεση στο internet.", "No internet connection.") } catch let error as URLError where error.code == .timedOut { lookupMessage = t("Η αναζήτηση άργησε πολύ. Δοκίμασε ξανά.", "Lookup timed out. Please try again.") } catch ProductLookupError.notFound { lookupMessage = t("Δεν βρέθηκε στο Open Food Facts. Χρησιμοποίησε φωτογραφία ή χειροκίνητη καταχώρηση.", "Product not found in Open Food Facts. Use a photo or enter it manually.") } catch { lookupMessage = t("Η online αναζήτηση απέτυχε. Δοκίμασε ξανά.", "Online lookup failed. Try again.") }
    }
    private func saveOrCheckDuplicate() { let code = barcode.trimmingCharacters(in: .whitespacesAndNewlines); if !code.isEmpty, let existing = existingItems.first(where: { $0.barcode == code }) { duplicateItem = existing; showingDuplicateAlert = true } else { saveNewItem() } }
    private func addQuantity(to existing: EmergencyItem) { let oldQuantity = existing.quantity; let oldDate = existing.updatedAt; let oldPhoto = existing.photoData; existing.quantity += quantity; existing.updatedAt = .now; if let photoData { existing.photoData = photoData }; do { try modelContext.save() } catch { existing.quantity = oldQuantity; existing.updatedAt = oldDate; existing.photoData = oldPhoto; saveError = error.localizedDescription; return }; Task { await NotificationManager.shared.scheduleExpirationNotifications(for: existing) }; dismiss() }
    private func saveNewItem() { let item = EmergencyItem(name: name.trimmingCharacters(in: .whitespacesAndNewlines), category: category, quantity: quantity, unit: unit, expirationDate: hasExpiration ? expirationDate : nil, storageLocation: storageLocation, notes: notes, barcode: barcode, photoData: photoData, litersPerUnit: category == .water ? litersPerUnit : 0, caloriesPerUnit: category == .food ? caloriesPerUnit : 0); item.requiresCookingRaw = cooking; item.requiresRefrigerationRaw = refrigeration; item.allergenNotes = allergens; modelContext.insert(item); do { try modelContext.save() } catch { modelContext.delete(item); saveError = error.localizedDescription; return }; Task { await NotificationManager.shared.scheduleExpirationNotifications(for: item) }; dismiss() }
}
