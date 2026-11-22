import SwiftUI
import SwiftData

struct PreparednessCoachView: View {
    @AppStorage("householdProfileV1") private var profileJSON = ""
    @Query private var items: [EmergencyItem]
    @AppStorage("protectedPeople") private var people = 4
    @AppStorage("targetDays") private var days = 90
    @AppStorage("appLanguage") private var language = AppLanguage.greek.rawValue
    @AppStorage("coachChildren") private var children = false
    @AppStorage("coachPets") private var pets = false
    @AppStorage("coachMedication") private var medication = false
    @AppStorage("coachActions") private var savedActions = ""
    @State private var scenario: PlanningScenario = .general
    @State private var onlySaved = false
    @State private var editingItem: EmergencyItem?
    private var greek: Bool { language == AppLanguage.greek.rawValue }
    private func t(_ el: String, _ en: String) -> String { greek ? el : en }
    private var calculator: ReadinessCalculator { ReadinessCalculator(items: items, people: people, targetDays: days) }
    private var advice: [PreparednessAdvice] {
        PreparednessAdvisor(calculator: calculator, scenario: scenario, greek: greek, hasChildren: children, hasPets: pets, hasRegularMedication: medication, profile: HouseholdProfile.decode(profileJSON)).recommendations
    }
    private var saved: Set<String> { Set(savedActions.split(separator: "|").map(String.init)) }
    private var displayed: [PreparednessAdvice] { onlySaved ? advice.filter { saved.contains($0.id) } : advice }

    var body: some View {
        List {
            Section {
                Label(t("Σύμβουλος προετοιμασίας", "Preparedness coach"), systemImage: "sparkles").font(.title2.bold())
                Text(t("Προτάσεις από τα αποθέματά σου, διαθέσιμες offline. Η ελεύθερη συνομιλία AI δεν έχει συνδεθεί ακόμη.", "Offline suggestions based on your inventory. Free-form AI conversation is not connected yet.")).font(.subheadline).foregroundStyle(.secondary)
            }
            Section(t("Στόχος & ανάγκες", "Target & needs")) {
                NavigationLink { HouseholdProfileView() } label: { Label(t("Οικογενειακό προφίλ", "Household profile"), systemImage: "person.2") }
                Stepper(t("Άτομα: \(people)", "People: \(people)"), value: $people, in: 1...12)
                Picker(t("Ημέρες", "Days"), selection: $days) {
                    ForEach([3, 7, 14, 30, 60, 90, 180, 270, 365], id: \.self) { Text("\($0)").tag($0) }
                }
                Toggle(t("Υπάρχουν παιδιά", "Children in household"), isOn: $children)
                Toggle(t("Υπάρχουν κατοικίδια", "Pets in household"), isOn: $pets)
                Toggle(t("Υπάρχει τακτική αγωγή", "Regular medication needs"), isOn: $medication)
                Text(t("Οι επιλογές και το προφίλ προσθέτουν ελέγχους. Οι ποσότητες δεν έχουν ακόμη εξατομικευτεί ανά ηλικία. Αλλεργίες, κατάσταση συσκευασιών και συντήρηση απαιτούν έλεγχο των ετικετών.", "Options and profile add review prompts. Quantities are not yet age-personalized. Allergies, packaging condition and storage require label review.")).font(.caption).foregroundStyle(.secondary)
            }
            Section(t("Άσκηση σεναρίου", "Scenario exercise")) {
                Picker(t("Σενάριο", "Scenario"), selection: $scenario) {
                    ForEach(PlanningScenario.allCases) { Text($0.title(greek: greek)).tag($0) }
                }
                Text(t("Υποθετικός έλεγχος προετοιμασίας. Δεν είναι πρόβλεψη, ζωντανή ειδοποίηση ή οδηγία εκκένωσης.", "Hypothetical preparedness review. Not a forecast, live alert or evacuation instruction.")).font(.caption).foregroundStyle(.secondary)
                if let url = scenarioURL { Link(t("Επίσημες οδηγίες για το σενάριο (internet)", "Official scenario guidance (internet)"), destination: url) }
            }
            if !calculator.unmeasuredItems.isEmpty {
                Section(t("Πρώτα συμπλήρωσε τα στοιχεία", "Complete these items first")) {
                    Text(t("Δεν εμφανίζονται προτάσεις αγοράς για κατηγορία με άγνωστες ποσότητες.", "Purchase gaps are withheld for categories with unknown amounts.")).font(.caption).foregroundStyle(.secondary)
                    ForEach(calculator.unmeasuredItems) { item in
                        Button { editingItem = item } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    Text(item.category == .water ? t("Λίτρα ανά τεμάχιο", "Liters per unit") : t("Θερμίδες ανά τεμάχιο", "Calories per unit")).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "pencil.circle")
                            }
                        }.buttonStyle(.borderless)
                    }
                }
            }
            if scenario == .outage {
                Section(t("Έλεγχος μαγειρέματος / ψύξης", "Cooking / cooling review")) {
                    ForEach(calculator.countedItems.filter { $0.category == .food }) { item in
                        Button { editingItem = item } label: {
                            Label(item.name, systemImage: "pencil.circle")
                        }.buttonStyle(.borderless)
                    }
                }
            }
            Section(t("Υπολογισμός αποθεμάτων", "Stock calculation")) {
                LabeledContent(t("Στόχος νερού", "Water target"), value: "\(Int(calculator.requiredWaterLiters)) L")
                LabeledContent(t("Στόχος ενέργειας τροφής", "Food energy target"), value: "\(Int(calculator.requiredFoodCalories)) kcal")
                Text(t("Άτομα × ημέρες × 4 L / 2.000 kcal. Το νερό είναι ποσότητα αποθήκευσης, όχι οδηγία κατανάλωσης. Οι θερμίδες είναι ενδεικτικές, όχι εξατομικευμένη διατροφή. Πρόσθετες ανάγκες ζέστης, ασθένειας και κατοικιδίων δεν περιλαμβάνονται.", "People × days × 4 L / 2,000 kcal. Water is a storage amount, not a drinking prescription. Calories are illustrative, not personalized nutrition. Extra needs for heat, illness and pets are not included.")).font(.caption)
                Text(t("Ληγμένες εγγραφές εξαιρούνται. Άγνωστα λίτρα/θερμίδες δεν προσμετρώνται. Χωρίς ημερομηνία λήξης, η ποσότητα προσμετράται αλλά η καταλληλότητά της χρειάζεται έλεγχο. Η διατροφική πληρότητα και η συντήρηση δεν πιστοποιούνται.", "Expired entries are excluded. Unknown liters/calories are not counted. Undated stock is counted but requires suitability review. Nutritional completeness and storage safety are not certified.")).font(.caption).foregroundStyle(.secondary)
            }
            Section(t("Προτεινόμενες ενέργειες", "Suggested actions")) {
                Toggle(t("Μόνο η λίστα ενεργειών μου", "Only my action list"), isOn: $onlySaved)
                if displayed.isEmpty { Text(t("Δεν υπάρχουν ενεργές αποθηκευμένες προτάσεις για αυτό το σενάριο.", "No active saved suggestions for this scenario.")) }
                ForEach(displayed) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(item.title, systemImage: item.priority <= 0 ? "exclamationmark.circle" : "checklist").font(.headline)
                        DisclosureGroup(t("Γιατί; • Λεπτομέρειες & πηγή", "Why? • Details & source")) {
                            Text(item.detail).font(.subheadline).padding(.vertical, 4)
                            if let url = URL(string: item.url) { Link(item.source, destination: url).font(.caption) }
                        }
                        if item.id == "measure" || item.id == "preparation-data" {
                            Text(t("Άνοιξε τις εγγραφές από τη λίστα παραπάνω.", "Open the entries from the list above.")).font(.caption).foregroundStyle(.secondary)
                        }
                        Button(saved.contains(item.id) ? t("Αφαίρεση από τη λίστα", "Remove from action list") : t("Στη λίστα ενεργειών", "Add to action list")) {
                            var ids = saved
                            if ids.contains(item.id) { ids.remove(item.id) } else { ids.insert(item.id) }
                            savedActions = ids.sorted().joined(separator: "|")
                        }.buttonStyle(.borderless)
                    }.padding(.vertical, 6)
                }
            }
        }
        .sheet(item: $editingItem) { item in EditItemView(item: item) }
        .navigationTitle(t("Σύμβουλος", "Coach"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(.green)
    }

    private var scenarioURL: URL? {
        let path: String
        switch scenario {
        case .earthquake: path = "https://civilprotection.gov.gr/odigies-prostasias/seismoi"
        case .flood: path = "https://civilprotection.gov.gr/odigies-prostasias/plimmyres"
        case .wildfire: path = "https://civilprotection.gov.gr/odigies-prostasias/dasikes-pyrkagies"
        default: return nil
        }
        return URL(string: path)
    }
}

struct CoachHighlightsView: View {
    @AppStorage("householdProfileV1") private var profileJSON = ""
    @Query private var items: [EmergencyItem]
    @AppStorage("protectedPeople") private var people = 4
    @AppStorage("targetDays") private var days = 90
    @AppStorage("appLanguage") private var language = AppLanguage.greek.rawValue
    @AppStorage("coachChildren") private var children = false
    @AppStorage("coachPets") private var pets = false
    @AppStorage("coachMedication") private var medication = false
    private var greek: Bool { language == AppLanguage.greek.rawValue }
    private var advice: [PreparednessAdvice] {
        PreparednessAdvisor(calculator: ReadinessCalculator(items: items, people: people, targetDays: days), greek: greek, hasChildren: children, hasPets: pets, hasRegularMedication: medication, profile: HouseholdProfile.decode(profileJSON)).recommendations
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(greek ? "Οι επόμενες ενέργειές σου" : "Your next actions").font(.headline)
            ForEach(Array(advice.prefix(3))) { item in
                NavigationLink { PreparednessCoachView() } label: {
                    Label(item.title, systemImage: "arrow.right.circle").font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain)
            }
        }.padding(18).foregroundStyle(.white)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }
}

