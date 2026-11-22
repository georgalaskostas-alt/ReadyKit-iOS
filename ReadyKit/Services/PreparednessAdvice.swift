import Foundation

enum PlanningScenario: String, CaseIterable, Identifiable {
    case general, outage, evacuation, earthquake, flood, wildfire
    var id: String { rawValue }
    func title(greek: Bool) -> String {
        switch self {
        case .general: return greek ? "Γενική ετοιμότητα" : "General preparedness"
        case .outage: return greek ? "Χωρίς ρεύμα / νερό" : "Power / water outage"
        case .evacuation: return greek ? "Εκκένωση" : "Evacuation"
        case .earthquake: return greek ? "Σεισμός" : "Earthquake"
        case .flood: return greek ? "Πλημμύρα" : "Flood"
        case .wildfire: return greek ? "Δασική πυρκαγιά" : "Wildfire"
        }
    }
}

struct PreparednessAdvice: Identifiable {
    let id: String
    let title: String
    let detail: String
    let priority: Int // 0: stock/data gap; 1: review; 2: planning
    let source: String
    let url: String
}

struct PreparednessAdvisor {
    let calculator: ReadinessCalculator
    var scenario: PlanningScenario = .general
    var greek = true
    var hasChildren = false
    var hasPets = false
    var hasRegularMedication = false
    var profile: HouseholdProfile? = nil
    private func t(_ el: String, _ en: String) -> String { greek ? el : en }
    static let waterSource = "https://www.cdc.gov/water-emergency/about/how-to-create-and-store-an-emergency-water-supply.html"
    static let kitSource = "https://www.ready.gov/sites/default/files/documents/files/checklist3.pdf"
    static let medicineSource = "https://www.cdc.gov/prepare-your-health/take-action/prescriptions.html"
    static let foodSource = "https://ask.fsis.usda.gov/article/What-foods-should-I-keep-in-my-house-for-emergencies"

    var recommendations: [PreparednessAdvice] {
        var output: [PreparednessAdvice] = []
        func add(_ id: String, _ title: String, _ detail: String, _ priority: Int, _ source: String, _ url: String) {
            output.append(PreparednessAdvice(id: id, title: title, detail: detail, priority: priority, source: source, url: url))
        }
        guard calculator.people > 0, calculator.targetDays > 0 else {
            add("profile", t("Συμπλήρωσε άτομα και ημέρες", "Set people and days"), t("Χρειάζονται έγκυρες ρυθμίσεις πριν υπολογίσουμε ελλείψεις.", "Valid settings are required before calculating gaps."), 0, "ReadyKit", Self.kitSource)
            return output
        }
        if !calculator.unmeasuredItems.isEmpty {
            add("measure", t("Συμπλήρωσε λίτρα / θερμίδες", "Complete liters / calories"), t("\(calculator.unmeasuredItems.count) εγγραφές δεν έχουν έγκυρη ποσότητα ανά τεμάχιο. Η κάλυψη μπορεί να υποεκτιμάται· έλεγξέ τες πριν αγοράσεις.", "\(calculator.unmeasuredItems.count) entries lack valid amounts per unit. Coverage may be underestimated; review before buying."), -1, "ReadyKit • inventory calculation", Self.kitSource)
        }
        if calculator.missingWaterLiters > 0 && !calculator.unmeasuredItems.contains(where: { $0.category == .water }) {
            let liters = Int(ceil(calculator.missingWaterLiters))
            let bottles = Int(ceil(calculator.missingWaterLiters / 1.5))
            add("water", t("Νερό: διαφορά \(liters) L", "Water: \(liters) L gap"), t("Με τα καταχωρημένα αποθέματα, για \(calculator.people) άτομα × \(calculator.targetDays) ημέρες. Αν επιλέξεις φιάλες 1,5 L: \(bottles) επιπλέον. Βάση ReadyKit 4 L/άτομο/ημέρα, στρογγυλοποίηση του CDC· δεν είναι ημερήσια οδηγία πόσης.", "Based on logged stock, for \(calculator.people) people × \(calculator.targetDays) days. If using 1.5 L bottles: \(bottles) additional bottles. ReadyKit uses 4 L/person/day rounded from CDC guidance; not a daily drinking prescription."), 0, "CDC • water / ReadyKit calculation", Self.waterSource)
        }
        if calculator.missingFoodCalories > 0 && !calculator.unmeasuredItems.contains(where: { $0.category == .food }) {
            add("food", t("Τροφή: διαφορά \(Int(ceil(calculator.missingFoodCalories))) kcal", "Food: \(Int(ceil(calculator.missingFoodCalories))) kcal gap"), t("Προσωρινή βάση 2.000 kcal ανά άτομο/ημέρα, όχι εξατομικευμένη ανάγκη. Έλεγξε την ετικέτα ανά συσκευασία. Πρόσθεσε ποικιλία τροφίμων μακράς διατήρησης που τρώει η οικογένεια και έλεγξε αλλεργιογόνα.", "Provisional 2,000 kcal/person/day assumption, not a personalized requirement. Check calories per package. Plan varied shelf-stable foods your household eats and check allergens."), 0, "USDA • food choices / ReadyKit calculation", Self.foodSource)
        }
        let dated = calculator.countedItems.filter { item in
            guard let days = item.daysUntilExpiration else { return false }
            return days < calculator.targetDays
        }
        if !dated.isEmpty {
            add("rotation", t("\(dated.count) είδη λήγουν μέσα στον στόχο", "\(dated.count) items expire within the target"), t("Η κάλυψη είναι στιγμιότυπο σημερινών αποθεμάτων. Σχεδίασε χρήση και αντικατάσταση πριν από τη λήξη· δεν εγγυάται κάλυψη όλης της περιόδου.", "Coverage is a snapshot of current stock. Plan use and replacement before expiry; it does not guarantee coverage throughout the period."), 1, "Ready.gov • kit", Self.kitSource)
        }
        if calculator.items.contains(where: { $0.quantity > 0 && ($0.daysUntilExpiration ?? 0) < 0 }) {
            add("expired", t("Ληγμένες εγγραφές εκτός υπολογισμού", "Expired entries excluded"), t("Έλεγξε ημερομηνίες και κατάσταση προϊόντων. Η εφαρμογή δεν πιστοποιεί ότι ένα τρόφιμο είναι ασφαλές.", "Review dates and product condition. The app does not certify food safety."), 0, "ReadyKit • conservative stock calculation", Self.kitSource)
        }
        add("ready-food", t("Έλεγξε τρόφιμα χωρίς μαγείρεμα", "Review no-cook foods"), t("Ενδεικτικά: έτοιμες κονσέρβες ψαριού ή λαχανικών, κράκερ και αποξηραμένα φρούτα, εφόσον είναι κατάλληλα για τα μέλη σου. Συμπλήρωσε για κάθε τρόφιμο αν χρειάζεται ψύξη ή μαγείρεμα και έλεγξε την ετικέτα.", "Examples: ready-to-eat canned fish or vegetables, crackers and dried fruit, if suitable for your household. Record cooking and refrigeration needs for each food and check its label."), 1, "USDA • food choices", Self.foodSource)
        for (category, el, en) in [(ItemCategory.firstAid, "πρώτες βοήθειες", "first aid"), (.power, "φωτισμό / ενέργεια", "lighting / power"), (.hygiene, "υγιεινή", "hygiene")] {
            if !calculator.countedItems.contains(where: { $0.category == category }) {
                add("category-\(category.rawValue)", t("Δεν έχεις καταχώρηση για \(el)", "No entries for \(en)"), t("Έλεγξε τι διαθέτεις και καταχώρησέ το. Απουσία εγγραφής δεν σημαίνει ότι δεν το έχεις· μία εγγραφή δεν πιστοποιεί πληρότητα.", "Review and log what you own. Missing entries do not prove missing supplies; one entry does not establish completeness."), 1, "Ready.gov • kit", Self.kitSource)
            }
        }
        if hasRegularMedication {
            add("medication", t("Σχέδιο για την προσωπική αγωγή", "Plan for regular medication"), t("Συζήτησε το απόθεμα και τη συντήρηση με γιατρό ή φαρμακοποιό. Κράτησε ενημερωμένη λίστα συνταγών και έλεγξε ανάγκη ψύξης. Δεν υπολογίζουμε δόσεις ή ημέρες κάλυψης από αριθμό κουτιών.", "Discuss supply and storage with your doctor or pharmacist. Keep an updated prescription list and check refrigeration needs. We do not infer doses or coverage days from box counts."), 1, "CDC • prescriptions", Self.medicineSource)
        }
        if hasChildren || hasPets {
            add("dependents", t("Προμήθειες για εξαρτώμενα μέλη", "Dependent care supplies"), t("Έλεγξε κατάλληλη τροφή, είδη φροντίδας και ειδικές ανάγκες παιδιών ή κατοικιδίων. Τα κατοικίδια δεν περιλαμβάνονται στον υπολογισμό και οι θερμίδες παιδιών δεν έχουν εξατομικευτεί.", "Review suitable food, care items and special needs for children or pets. Pet needs are not included in totals and children's calories are not personalized."), 1, "CDC • personal needs", "https://www.cdc.gov/prepare-your-health/take-action/personal-needs.html")
        }
        if scenario == .outage {
            add("outage", t("Έλεγχος χωρίς ρεύμα / νερό", "Power / water outage review"), t("Έλεγξε φακούς, συμβατές μπαταρίες, φορτισμένο power bank, ραδιόφωνο και χειροκίνητο ανοιχτήρι. Εξέτασε ξεχωριστά τρόφιμα και αγωγή που απαιτούν ψύξη.", "Check flashlights, compatible batteries, a charged power bank, radio and manual can opener. Separately review food and medication requiring refrigeration."), 1, "Ready.gov • kit", Self.kitSource)
        } else if scenario != .general {
            add("evacuation", t("Προετοίμασε φορητό kit", "Prepare a portable kit"), t("Ξεχώρισε τα αποθέματα σπιτιού από όσα μπορείς να μεταφέρεις. Έλεγξε έγγραφα, επαφές, φορτιστές, απαραίτητη αγωγή και ανάγκες των μελών. Δεν θεωρούμε όλο το απόθεμα μεταφέρσιμο.", "Separate home stock from what you can carry. Review documents, contacts, chargers, regular medication and household needs. Total home stock is not assumed portable."), 1, "Ready.gov • kit", Self.kitSource)
        }
        if let profile {
            if profile.members.count != calculator.people {
                add("profile-count", t("Έλεγξε τον αριθμό μελών", "Review household count"), t("Το προφίλ έχει \(profile.members.count) μέλη, αλλά ο υπολογισμός χρησιμοποιεί \(calculator.people). Άνοιξε το προφίλ για συμφωνία των στοιχείων.", "Profile has \(profile.members.count) members, but calculations use \(calculator.people). Open the profile to reconcile them."), -1, "ReadyKit • profile", Self.kitSource)
            }
            if profile.hasDietaryConstraints {
                add("dietary-review", t("Έλεγχος αλλεργιών και διατροφής", "Allergy and diet review"), t("Έχεις δηλώσει αλλεργίες ή διατροφικές ανάγκες. Οι θερμίδες περιλαμβάνουν όλα τα καταχωρημένα τρόφιμα· δεν θεωρούνται όλα κατάλληλα για κάθε μέλος. Έλεγξε τις ετικέτες και τις σημειώσεις του προφίλ πριν από αγορές.", "You recorded allergies or dietary needs. Calorie totals include all logged foods; they are not all assumed suitable for every member. Review labels and profile notes before buying."), 0, "CDC • personal needs", "https://www.cdc.gov/prepare-your-health/take-action/personal-needs.html")
            }
        }
        if scenario == .outage {
            let food = calculator.countedItems.filter { $0.category == .food }
            let unknown = food.filter { !["yes", "no"].contains($0.requiresCookingRaw ?? "") || !["yes", "no"].contains($0.requiresRefrigerationRaw ?? "") }
            if !unknown.isEmpty {
                add("preparation-data", t("Έλεγξε συντήρηση σε \(unknown.count) τρόφιμα", "Review storage for \(unknown.count) foods"), t("Δεν γνωρίζουμε αν αυτά τρώγονται χωρίς μαγείρεμα ή ψυγείο. Άνοιξε τα προϊόντα και συμπλήρωσε τα πεδία από την ετικέτα.", "We do not know whether these can be used without cooking or refrigeration. Open the items and complete the fields from their labels."), -1, "ReadyKit • inventory review", Self.foodSource)
            }
            let dependent = food.filter {
                $0.requiresCookingRaw == "yes" || $0.requiresRefrigerationRaw == "yes"
            }
            if !dependent.isEmpty {
                let noBackup = profile?.cookingBackup == "no" || profile?.refrigerationBackup == "no"
                add("dependent-food", t("\(dependent.count) τρόφιμα χρειάζονται υποδομή", "\(dependent.count) foods need cooking or cooling"), t("Δεν μετράμε αυτές τις εγγραφές ως έτοιμα γεύματα χωρίς υποδομή. \(noBackup ? "Έχεις δηλώσει ότι λείπει εναλλακτική υποδομή." : "Έλεγξε αν διαθέτεις κατάλληλη εναλλακτική.") Το συνολικό ποσοστό τροφής παραμένει ενεργειακό απόθεμα, όχι κάλυψη αυτού του σεναρίου.", "These entries are not treated as ready meals without utilities. \(noBackup ? "Your profile reports unavailable backup equipment." : "Review suitable backup options.") Overall food coverage still represents stored energy, not coverage of this scenario."), 0, "ReadyKit • scenario review", Self.foodSource)
            }
        }
        return output.sorted { $0.priority == $1.priority ? $0.id < $1.id : $0.priority < $1.priority }
    }
}

