import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue

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
    @State private var isLookingUpProduct = false
    @State private var lookupMessage: String?
    @State private var lookupSucceeded = false

    var body: some View {
        NavigationStack {
            Form {
                Section(t("Προϊόν", "Product")) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 16) {
                            photoPreview
                            VStack(alignment: .leading, spacing: 4) {
                                Text(t(photoData == nil ? "Προσθήκη φωτογραφίας" : "Αλλαγή φωτογραφίας", photoData == nil ? "Add photo" : "Change photo"))
                                    .font(.headline)
                                Text(t("Από τη βιβλιοθήκη ή αυτόματα από το barcode", "From your library or automatically from the barcode"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .task(id: selectedPhoto) {
                        photoData = try? await selectedPhoto?.loadTransferable(type: Data.self)
                    }

                    TextField(t("Όνομα προϊόντος", "Product name"), text: $name)
                    Picker(t("Κατηγορία", "Category"), selection: $category) {
                        ForEach(ItemCategory.allCases) { item in
                            Label(categoryName(item), systemImage: item.symbol).tag(item)
                        }
                    }
                }

                Section(t("Barcode", "Barcode")) {
                    HStack {
                        TextField(t("Κωδικός barcode", "Barcode number"), text: $barcode)
                            .keyboardType(.numbersAndPunctuation)
                        Button { showingScanner = true } label: {
                            Image(systemName: "barcode.viewfinder").font(.title2)
                        }
                        .buttonStyle(.plain)
                    }

                    Button { showingScanner = true } label: {
                        Label(t("Σάρωση με κάμερα", "Scan with camera"), systemImage: "camera.viewfinder")
                    }

                    if !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            Task { await lookupProduct() }
                        } label: {
                            HStack {
                                Label(t("Εύρεση προϊόντος online", "Find product online"), systemImage: "sparkle.magnifyingglass")
                                Spacer()
                                if isLookingUpProduct { ProgressView() }
                            }
                        }
                        .disabled(isLookingUpProduct)
                    }

                    if let lookupMessage {
                        Label(lookupMessage, systemImage: lookupSucceeded ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(lookupSucceeded ? .green : .secondary)
                    }
                }

                Section(t("Ποσότητα", "Quantity")) {
                    Stepper(t("Ποσότητα: \(quantity)", "Quantity: \(quantity)"), value: $quantity, in: 1...9999)
                    TextField(t("Μονάδα (π.χ. τεμ., L, kg)", "Unit (e.g. pcs, L, kg)"), text: $unit)
                }

                if category == .water {
                    Section(t("Υπολογισμός νερού", "Water calculation")) {
                        TextField(t("Λίτρα ανά τεμάχιο", "Liters per item"), value: $litersPerUnit, format: .number).keyboardType(.decimalPad)
                        LabeledContent(t("Συνολικό νερό", "Total water"), value: "\((litersPerUnit * Double(quantity)).formatted(.number.precision(.fractionLength(1)))) L")
                    }
                }

                if category == .food {
                    Section(t("Υπολογισμός τροφίμων", "Food calculation")) {
                        TextField(t("Θερμίδες ανά τεμάχιο", "Calories per item"), value: $caloriesPerUnit, format: .number).keyboardType(.decimalPad)
                        LabeledContent(t("Συνολικές θερμίδες", "Total calories"), value: "\(Int(caloriesPerUnit * Double(quantity))) kcal")
                    }
                }

                Section(t("Λήξη", "Expiration")) {
                    Toggle(t("Έχει ημερομηνία λήξης", "Has expiration date"), isOn: $hasExpiration)
                    if hasExpiration { DatePicker(t("Ημερομηνία", "Date"), selection: $expirationDate, displayedComponents: .date) }
                }

                Section(t("Αποθήκευση", "Storage")) {
                    TextField(t("Τοποθεσία", "Location"), text: $storageLocation)
                    TextField(t("Σημειώσεις", "Notes"), text: $notes, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle(t("Νέο προϊόν", "New Item"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t("Ακύρωση", "Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("Αποθήκευση", "Save")) { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerSheet { scannedCode in
                    barcode = scannedCode
                    Task { await lookupProduct() }
                }
            }
            .id(appLanguage)
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

    private func t(_ greek: String, _ english: String) -> String {
        appLanguage == AppLanguage.english.rawValue ? english : greek
    }

    private func categoryName(_ category: ItemCategory) -> String {
        switch category {
        case .water: return t("Νερό", "Water")
        case .food: return t("Τρόφιμα", "Food")
        case .firstAid: return t("Πρώτες βοήθειες", "First Aid")
        case .medication: return t("Φάρμακα", "Medication")
        case .power: return t("Ρεύμα & Φωτισμός", "Power & Lighting")
        case .hygiene: return t("Υγιεινή", "Hygiene")
        case .tools: return t("Εξοπλισμός", "Equipment")
        case .documents: return t("Έγγραφα", "Documents")
        case .other: return t("Άλλο", "Other")
        }
    }

    @MainActor
    private func lookupProduct() async {
        let code = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !isLookingUpProduct else { return }

        isLookingUpProduct = true
        lookupMessage = t("Αναζήτηση προϊόντος…", "Looking up product…")
        lookupSucceeded = false
        defer { isLookingUpProduct = false }

        do {
            let result = try await ProductLookupService.shared.lookup(barcode: code)
            name = result.name
            category = .food

            if let quantityText = result.quantityText, !quantityText.isEmpty {
                unit = quantityText
            }

            if let kcal100g = result.caloriesPer100g,
               let amount = result.productQuantity,
               let amountUnit = result.productQuantityUnit?.lowercased() {
                if amountUnit == "g" {
                    caloriesPerUnit = kcal100g * amount / 100.0
                } else if amountUnit == "kg" {
                    caloriesPerUnit = kcal100g * amount * 10.0
                }
            }

            if let imageURL = result.imageURL,
               let imageData = await ProductLookupService.shared.downloadImage(from: imageURL) {
                photoData = imageData
            }

            if let brand = result.brand, !brand.isEmpty, !name.localizedCaseInsensitiveContains(brand) {
                notes = notes.isEmpty ? brand : notes
            }

            lookupSucceeded = true
            lookupMessage = t("Το προϊόν βρέθηκε και συμπληρώθηκε αυτόματα.", "Product found and filled in automatically.")
        } catch ProductLookupError.notFound {
            lookupMessage = t("Δεν βρέθηκε στη βάση. Μπορείς να το συμπληρώσεις χειροκίνητα.", "Product not found. You can enter it manually.")
        } catch {
            lookupMessage = t("Δεν ήταν δυνατή η online αναζήτηση. Δοκίμασε ξανά.", "Online lookup failed. Please try again.")
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
