import SwiftUI

struct SettingsView: View {
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 90
    @State private var notificationStatus = "Δεν έχει ελεγχθεί"

    var body: some View {
        NavigationStack {
            Form {
                Section("Οικογένεια & στόχος") {
                    Stepper("Άτομα: \(protectedPeople)", value: $protectedPeople, in: 1...12)

                    Picker("Στόχος αυτονομίας", selection: $targetDays) {
                        Section("Βραχυπρόθεσμα") {
                            Text("3 ημέρες").tag(3)
                            Text("7 ημέρες").tag(7)
                            Text("14 ημέρες").tag(14)
                            Text("30 ημέρες").tag(30)
                        }
                        Section("Μακροπρόθεσμα") {
                            Text("2 μήνες").tag(60)
                            Text("3 μήνες").tag(90)
                            Text("6 μήνες").tag(180)
                            Text("9 μήνες").tag(270)
                            Text("12 μήνες").tag(365)
                        }
                    }

                    LabeledContent("Επιλεγμένος στόχος", value: autonomyLabel)
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

    private var autonomyLabel: String {
        switch targetDays {
        case 60: "2 μήνες"
        case 90: "3 μήνες"
        case 180: "6 μήνες"
        case 270: "9 μήνες"
        case 365: "12 μήνες"
        default: "\(targetDays) ημέρες"
        }
    }
}
