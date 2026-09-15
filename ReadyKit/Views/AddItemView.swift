import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var category: ItemCategory = .food
    @State private var quantity = 1
    @State private var unit = "τεμ."
    @State private var hasExpiration = true
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    @State private var storageLocation = "Emergency Kit"
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Προϊόν") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 16) {
                            photoPreview
                            VStack(alignment: .leading, spacing: 4) {
                                Text(photoData == nil ? "Προσθήκη φωτογραφίας" : "Αλλαγή φωτογραφίας")
                                    .font(.headline)
                                Text("Από τη βιβλιοθήκη φωτογραφιών")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .task(id: selectedPhoto) {
                        photoData = try? await selectedPhoto?.loadTransferable(type: Data.self)
                    }

                    TextField("Όνομα προϊόντος", text: $name)
                    Picker("Κατηγορία", selection: $category) {
                        ForEach(ItemCategory.allCases) { item in
                            Label(item.rawValue, systemImage: item.symbol).tag(item)
                        }
                    }
                }

                Section("Ποσότητα") {
                    Stepper("Ποσότητα: \(quantity)", value: $quantity, in: 1...999)
                    TextField("Μονάδα (π.χ. τεμ., L, kg)", text: $unit)
                }

                Section("Λήξη") {
                    Toggle("Έχει ημερομηνία λήξης", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Ημερομηνία", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                Section("Αποθήκευση") {
                    TextField("Τοποθεσία", text: $storageLocation)
                    TextField("Σημειώσεις", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Νέο προϊόν")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ακύρωση") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Αποθήκευση") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.quaternary)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func save() {
        let item = EmergencyItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            quantity: quantity,
            unit: unit,
            expirationDate: hasExpiration ? expirationDate : nil,
            storageLocation: storageLocation,
            notes: notes,
            photoData: photoData
        )
        modelContext.insert(item)
        try? modelContext.save()
        Task { await NotificationManager.shared.scheduleExpirationNotifications(for: item) }
        dismiss()
    }
}
