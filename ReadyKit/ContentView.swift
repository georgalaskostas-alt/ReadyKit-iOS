import SwiftUI

struct ContentView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.greek.rawValue
    @State private var selectedTab: ReadyKitTab = .home
    @State private var showingScanner = false
    @State private var showingAddItem = false
    @State private var scannedBarcode = ""

    private var isGreek: Bool { appLanguage == AppLanguage.greek.rawValue }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home: HomeView()
                case .inventory: InventoryView()
                case .preparedness: PreparednessView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 86) }

            ReadyKitFloatingDock(
                selectedTab: $selectedTab,
                isGreek: isGreek,
                scanAction: { showingScanner = true }
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 5)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showingScanner, onDismiss: {
            guard !scannedBarcode.isEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                showingAddItem = true
            }
        }) {
            BarcodeScannerSheet { code in
                scannedBarcode = code
                showingScanner = false
            }
        }
        .sheet(isPresented: $showingAddItem, onDismiss: {
            scannedBarcode = ""
        }) {
            AddItemView()
        }
        .id(appLanguage)
    }
}

private enum ReadyKitTab: Hashable {
    case home
    case inventory
    case preparedness
    case settings
}

private struct ReadyKitFloatingDock: View {
    @Binding var selectedTab: ReadyKitTab
    let isGreek: Bool
    let scanAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            dockButton(.home, icon: "house.fill", title: isGreek ? "Αρχική" : "Home")
            dockButton(.inventory, icon: "shippingbox.fill", title: isGreek ? "Απόθεμα" : "Inventory")

            Button(action: scanAction) {
                VStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.96))
                            .frame(width: 66, height: 66)
                            .overlay(Circle().stroke(Color.green.opacity(0.85), lineWidth: 1.5))
                            .shadow(color: .green.opacity(0.55), radius: 15)

                        Circle()
                            .trim(from: 0.06, to: 0.94)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 54, height: 54)

                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 27, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .offset(y: -11)

                    Text("Scan")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.green)
                        .offset(y: -12)
                }
                .frame(maxWidth: .infinity, minHeight: 72)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isGreek ? "Σάρωση barcode" : "Scan barcode")

            dockButton(.preparedness, icon: "shield.checkered", title: isGreek ? "Ετοιμότητα" : "Preparedness")
            dockButton(.settings, icon: "gearshape.fill", title: isGreek ? "Ρυθμίσεις" : "Settings")
        }
        .frame(height: 76)
        .padding(.horizontal, 5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .background(Color.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
    }

    private func dockButton(_ tab: ReadyKitTab, icon: String, title: String) -> some View {
        let active = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(active ? Color.green : Color.white.opacity(0.78))
                    .shadow(color: active ? .green.opacity(0.42) : .clear, radius: 8)

                Text(title)
                    .font(.system(size: 9, weight: active ? .semibold : .medium))
                    .foregroundStyle(active ? Color.green : Color.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 62)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(Color.green.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .stroke(Color.green.opacity(0.18), lineWidth: 0.8)
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
