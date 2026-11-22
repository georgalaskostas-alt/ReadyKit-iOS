import SwiftUI

struct HouseholdProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("householdProfileV1") private var stored = ""
    @AppStorage("protectedPeople") private var people = 4
    @AppStorage("coachChildren") private var children = false
    @AppStorage("coachPets") private var pets = false
    @AppStorage("coachMedication") private var medication = false
    @AppStorage("appLanguage") private var language = AppLanguage.greek.rawValue
    @State private var profile = HouseholdProfile()
    @State private var loaded = false
    @State private var loadFailed = false
    @State private var saveError = false
    private func t(_ el: String, _ en: String) -> String { language == AppLanguage.greek.rawValue ? el : en }
    var body: some View {
        Form {
            Section {
                Text(t("Τα στοιχεία μένουν στη συσκευή. Δεν αποστέλλονται σε AI. Χρησιμοποιούνται για ελέγχους προετοιμασίας, όχι για αυτόματη συνταγογράφηση ή εξατομικευμένες θερμίδες.", "Details stay on this device and are not sent to AI. They support preparedness reviews, not prescribing or personalized calorie targets.")).font(.caption).foregroundStyle(.secondary)
                Text(t("Η αποθήκευση θα ορίσει τον αριθμό ατόμων σε \(profile.members.count).", "Saving sets the household count to \(profile.members.count)."))
            }
            ForEach($profile.members) { $member in
                Section {
                    TextField(t("Όνομα ή περιγραφή μέλους", "Name or member label"), text: $member.label)
                    TextField(t("Έτος γέννησης — προαιρετικό", "Birth year — optional"), text: $member.birthYear).keyboardType(.numberPad)
                    TextField(t("Αλλεργίες", "Allergies"), text: $member.allergies, axis: .vertical)
                    TextField(t("Διατροφικές ανάγκες", "Dietary needs"), text: $member.dietaryNeeds, axis: .vertical)
                    Toggle(t("Τακτική αγωγή", "Regular medication"), isOn: $member.regularMedication)
                } header: { Text(member.label.isEmpty ? t("Μέλος", "Member") : member.label) }
            }.onDelete { profile.members.remove(atOffsets: $0) }
            if profile.members.count < 12 {
                Button(t("Προσθήκη μέλους", "Add member")) { profile.members.append(HouseholdMember()) }
            }
            Section(t("Συνθήκες", "Conditions")) {
                TextField(t("Κατοικίδια — είδη και αριθμός", "Pets — types and count"), text: $profile.pets, axis: .vertical)
                Picker(t("Εναλλακτική για μαγείρεμα χωρίς ρεύμα", "Cooking backup without power"), selection: $profile.cookingBackup) { options }
                Picker(t("Εφεδρική ψύξη", "Backup refrigeration"), selection: $profile.refrigerationBackup) { options }
                Text(t("Η καταχώρηση εξοπλισμού δεν πιστοποιεί ασφαλή χρήση. Οι ανάγκες κατοικιδίων δεν προστίθενται αυτόματα στις ποσότητες.", "Equipment entries do not certify safe operation. Pet needs are not automatically added to totals.")).font(.caption).foregroundStyle(.secondary)
            }
            if !profile.isValid && loaded { Text(t("Χρειάζονται 1–12 μέλη και έγκυρα έτη γέννησης ή κενά πεδία.", "Enter 1–12 members and valid birth years, or leave years blank.")).foregroundStyle(.orange) }
            if loadFailed { Text(t("Το αποθηκευμένο προφίλ δεν διαβάστηκε. Δεν θα αντικατασταθεί. Επιστροφή και έλεγχος της εφαρμογής.", "Saved profile could not be read. It will not be overwritten. Go back and report the issue.")).foregroundStyle(.orange) }
        }
        .navigationTitle(t("Οικογενειακό προφίλ", "Household profile"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(t("Αποθήκευση", "Save")) { save() }.disabled(!loaded || loadFailed || !profile.isValid)
            }
        }
        .onAppear {
            guard !loaded else { return }
            if let existing = HouseholdProfile.decode(stored) { profile = existing }
            else if stored.isEmpty { profile.members = (0..<max(1, min(12, people))).map { _ in HouseholdMember() } }
            else { loadFailed = true }
            loaded = true
        }
        .alert(t("Η αποθήκευση απέτυχε", "Save failed"), isPresented: $saveError) { Button("OK", role: .cancel) {} }
    }
    @ViewBuilder private var options: some View {
        Text(t("Δεν έχει ελεγχθεί", "Not reviewed")).tag("unknown")
        Text(t("Υπάρχει", "Available")).tag("yes")
        Text(t("Δεν υπάρχει", "Unavailable")).tag("no")
    }
    private func save() {
        guard profile.isValid, !loadFailed else { return }
        profile.updatedAt = .now
        guard let data = try? JSONEncoder().encode(profile), let json = String(data: data, encoding: .utf8) else { saveError = true; return }
        stored = json
        people = profile.members.count
        // Unknown ages do not cancel an existing child flag.
        if profile.members.allSatisfy({ $0.year != nil }) { children = profile.members.contains { $0.isChild } }
        else if profile.members.contains(where: { $0.isChild }) { children = true }
        pets = !profile.pets.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        medication = profile.members.contains { $0.regularMedication }
        dismiss()
    }
}
