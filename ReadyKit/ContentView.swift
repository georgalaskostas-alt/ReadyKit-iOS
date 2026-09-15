import SwiftUI

struct ContentView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    private var isGreek: Bool { appLanguage == AppLanguage.greek.rawValue }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(isGreek ? "Αρχική" : "Home", systemImage: "house.fill") }

            InventoryView()
                .tabItem { Label(isGreek ? "Απόθεμα" : "Inventory", systemImage: "shippingbox.fill") }

            PreparednessView()
                .tabItem { Label(isGreek ? "Ετοιμότητα" : "Preparedness", systemImage: "shield.checkered") }

            SettingsView()
                .tabItem { Label(isGreek ? "Ρυθμίσεις" : "Settings", systemImage: "gearshape.fill") }
        }
        .tint(ReadyKitTheme.accent)
        .id(appLanguage)
    }
}

#Preview {
    ContentView()
}
