import SwiftUI

enum ReadyKitTheme {
    static let accent = Color.green
    static let cardRadius: CGFloat = 22
    static let pageBackground = Color(uiColor: .systemGroupedBackground)

    static func cardBackground() -> some ShapeStyle {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
}

struct ReadyKitSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.bold())
            if let subtitle {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
