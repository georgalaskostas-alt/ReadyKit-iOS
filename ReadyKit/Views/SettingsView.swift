import SwiftUI

struct SettingsView: View {
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 14
    @State private var notificationStatus = "Δεν έχει ελεγχθεί"

    var body: some View {
        NavigationStack {
            Form {
                Section("Οικογένεια & στόχος") {
                    Stepper("Άτομα: \(protectedPeople)", value: $protectedPeople, in: 1...12)
                    Picker("Αυτονομία", selection: $targetDays) {
                        Text("3 ημέρες").tag(3)
                        Text("7 ημέρες").tag(7)
                        Text("14 ημέρες").tag(14)
                        Text("30 ημέρες").tag(30)
                    }
                }

                Section("Ειδοποιήσεις") {
                    Button("Ενεργοποίηση ειδοποιήσεων") {
                        Task {
                            let granted = await NotificationManager.shared.requestAuthorization()
                            notificationStatus = granted ? "Ενεργές" : "Δεν επιτράπηκαν"
                        }
                    }
                    LabeledContent("Κατάσταση", value: notificationStatus)
                }

                Section("ReadyKit") {
                    LabeledContent("Έκδοση", value: "1.0")
                    Text("Τα δεδομένα της πρώτης έκδοσης αποθηκεύονται τοπικά στη συσκευή.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ρυθμίσεις")
        }
    }
}
