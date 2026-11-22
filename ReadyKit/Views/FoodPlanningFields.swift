import SwiftUI

struct FoodPlanningFields: View {
    @Binding var cooking: String
    @Binding var refrigeration: String
    @Binding var allergens: String
    @AppStorage("appLanguage") private var language = AppLanguage.greek.rawValue
    private func t(_ el: String, _ en: String) -> String { language == AppLanguage.greek.rawValue ? el : en }
    var body: some View {
        Section(t("Χρήση σε έκτακτη ανάγκη", "Emergency use")) {
            requirement(t("Απαιτεί μαγείρεμα", "Requires cooking"), selection: $cooking)
            requirement(t("Απαιτεί ψυγείο πριν ανοιχτεί", "Refrigeration before opening"), selection: $refrigeration)
            TextField(t("Αλλεργιογόνα / προειδοποιήσεις ετικέτας", "Label allergens / warnings"), text: $allergens, axis: .vertical)
            Text(t("Συμπλήρωσε από την ετικέτα. Κενό πεδίο δεν σημαίνει απουσία αλλεργιογόνων. Μετά το άνοιγμα ακολούθησε τις οδηγίες συντήρησης.", "Use the product label. An empty field does not mean allergen-free. Follow storage instructions after opening.")).font(.caption).foregroundStyle(.secondary)
        }
    }
    private func requirement(_ title: String, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            Text(t("Δεν γνωρίζω", "Unknown")).tag("unknown")
            Text(t("Ναι", "Yes")).tag("yes")
            Text(t("Όχι", "No")).tag("no")
        }
    }
}
