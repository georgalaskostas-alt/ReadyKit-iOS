import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var items: [EmergencyItem]
    @State private var showingAddItem = false

    private var expiringSoon: Int {
        items.filter { $0.expirationStatus == .soon || $0.expirationStatus == .urgent }.count
    }

    private var expired: Int {
        items.filter { $0.expirationStatus == .expired }.count
    }

    private var healthy: Int {
        items.filter { $0.expirationStatus == .good || $0.expirationStatus == .noExpiration }.count
    }

    private var readiness: Int {
        guard !items.isEmpty else { return 0 }
        let score = Double(healthy) + Double(expiringSoon) * 0.65
        return Int((score / Double(items.count) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    readinessCard
                    statusStrip
                    categoriesSection
                    attentionSection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("ReadyKit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
        }
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("EMERGENCY READINESS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                    Text(items.isEmpty ? "Ξεκίνα το kit σου" : "Το kit σου είναι έτοιμο")
                        .font(.title2.bold())
                }
                Spacer()
                ZStack {
                    Circle().stroke(.quaternary, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: Double(readiness) / 100)
                        .stroke(readinessColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(readiness)%")
                        .font(.headline.monospacedDigit())
                }
                .frame(width: 72, height: 72)
            }

            HStack {
                Label("\(items.count) αντικείμενα", systemImage: "shippingbox.fill")
                Spacer()
                Label("\(Set(items.map(\.categoryRaw)).count) κατηγορίες", systemImage: "square.grid.2x2.fill")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var statusStrip: some View {
        HStack(spacing: 10) {
            StatusCard(value: healthy, title: "OK", symbol: "checkmark.circle.fill", color: .green)
            StatusCard(value: expiringSoon, title: "Σύντομα", symbol: "clock.fill", color: .orange)
            StatusCard(value: expired, title: "Έληξαν", symbol: "exclamationmark.triangle.fill", color: .red)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Κατηγορίες")
                .font(.title3.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ItemCategory.allCases.prefix(6)) { category in
                    let count = items.filter { $0.category == category }.reduce(0) { $0 + $1.quantity }
                    HStack(spacing: 12) {
                        Image(systemName: category.symbol)
                            .frame(width: 36, height: 36)
                            .background(.thinMaterial, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("\(count) συνολικά")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private var attentionSection: some View {
        let attention = items
            .filter { $0.expirationStatus == .urgent || $0.expirationStatus == .expired || $0.expirationStatus == .soon }
            .sorted { ($0.daysUntilExpiration ?? Int.max) < ($1.daysUntilExpiration ?? Int.max) }

        if !attention.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Χρειάζονται προσοχή")
                    .font(.title3.bold())
                ForEach(attention.prefix(3)) { item in
                    HStack {
                        Image(systemName: item.category.symbol)
                            .frame(width: 38, height: 38)
                            .background(.orange.opacity(0.12), in: Circle())
                        VStack(alignment: .leading) {
                            Text(item.name).fontWeight(.semibold)
                            if let days = item.daysUntilExpiration {
                                Text(days < 0 ? "Έχει λήξει" : "Λήγει σε \(days) ημέρες")
                                    .font(.caption)
                                    .foregroundStyle(days <= 30 ? .red : .orange)
                            }
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private var readinessColor: Color {
        switch readiness {
        case 80...: .green
        case 50..<80: .orange
        default: .red
        }
    }
}

private struct StatusCard: View {
    let value: Int
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbol).foregroundStyle(color)
            Text("\(value)").font(.title3.bold().monospacedDigit())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
