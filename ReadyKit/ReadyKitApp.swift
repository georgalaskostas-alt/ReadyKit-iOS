import SwiftUI
import SwiftData

@main
struct ReadyKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: EmergencyItem.self)
    }
}
