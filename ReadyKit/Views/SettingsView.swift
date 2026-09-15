import SwiftUI

struct SettingsView: View {
    @AppStorage("protectedPeople") private var protectedPeople = 4
    @AppStorage("targetDays") private var targetDays = 90
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    @State private var notificationStatus = L10n.text("Δεν έχει ελεγχθεί", "Not checked")

    private var isGreek: Bool { appLanguage == AppLanguage.greek.rawValue }
    private func t(_ greek: String, _ english: String) -> String { isGreek ? greek : english }

    var body: some View {
        NavigationStack {
            Form {
                Section(t("Γλώσσα", "Language")) {
                    Picker(t("Γλώσσα εφαρμογής", "App language"), selection: $appLanguage) {
                        Text("Ελληνικά").tag(AppLanguage.greek.rawValue)
                        Text("English").tag(AppLanguage.english.rawValue)
                    }
                    .pickerStyle(.segmented)
                    Text(t("Η αλλαγή εφαρμόζεται άμεσα στις κύριες οθόνες.", "The change is applied immediately to the main screens."))
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section(t("Οικογένεια & στόχος", "Household & target")) {
                    Stepper(t("Άτομα: \(protectedPeople)", "People: \(protectedPeople)"), value: $protectedPeople, in: 1...12)
                    Picker(t("Στόχος αυτονομίας", "Autonomy target"), selection: $targetDays) {
                        Section(t("Βραχυπρόθεσμα", "Short term")) {
                            Text(t("3 ημέρες", "3 days")).tag(3)
                            Text(t("7 ημέρες", "7 days")).tag(7)
                            Text(t("14 ημέρες", "14 days")).tag(14)
                            Text(t("30 ημέρες", "30 days")).tag(30)
                        }
                        Section(t("Μακροπρόθεσμα", "Long term")) {
                            Text(t("2 μήνες", "2 months")).tag(60)
                            Text(t("3 μήνες", "3 months")).tag(90)
                            Text(t("6 μήνες", "6 months")).tag(180)
                            Text(t("9 μήνες", "9 months")).tag(270)
                            Text(t("12 μήνες", "12 months")).tag(365)
                        }
                    }
                    LabeledContent(t("Επιλεγμένος στόχος", "Selected target"), value: autonomyLabel)
                }

                Section(t("Ειδοποιήσεις", "Notifications")) {
                    Button(t("Ενεργοποίηση ειδοποιήσεων", "Enable notifications")) {
                        Task {
                            let granted = await NotificationManager.shared.requestAuthorization()
                            notificationStatus = granted ? t("Ενεργές", "Enabled") : t("Δεν επιτράπηκαν", "Not allowed")
                        }
                    }
                    LabeledContent(t("Κατάσταση", "Status"), value: notificationStatus)
                }

                Section("ReadyKit") {
                    LabeledContent(t("Έκδοση", "Version"), value: "1.0")
                    Text(t("Τα δεδομένα αποθηκεύονται τοπικά στη συσκευή.", "Your data is stored locally on this device."))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(t("Ρυθμίσεις", "Settings"))
            .id(appLanguage)
        }
    }

    private var autonomyLabel: String {
        switch targetDays {
        case 60: t("2 μήνες", "2 months")
        case 90: t("3 μήνες", "3 months")
        case 180: t("6 μήνες", "6 months")
        case 270: t("9 μήνες", "9 months")
        case 365: t("12 μήνες", "12 months")
        default: t("\(targetDays) ημέρες", "\(targetDays) days")
        }
    }
}
