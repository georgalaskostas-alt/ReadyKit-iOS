import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            InventoryView()
                .tabItem { Label("Inventory", systemImage: "shippingbox.fill") }

            PreparednessView()
                .tabItem { Label("Preparedness", systemImage: "checklist") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
}
