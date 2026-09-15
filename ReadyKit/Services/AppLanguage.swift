import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case greek = "el"
    case english = "en"

    var id: String { rawValue }
    var displayName: String { self == .greek ? "Ελληνικά" : "English" }
}

enum L10n {
    static var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "el") ?? .greek
    }

    static func text(_ greek: String, _ english: String) -> String {
        language == .greek ? greek : english
    }

    static func days(_ value: Int) -> String {
        text("\(value) ημέρες", "\(value) days")
    }

    static func months(_ value: Int) -> String {
        text("\(value) μήνες", "\(value) months")
    }
}
