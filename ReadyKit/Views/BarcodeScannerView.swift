import SwiftUI
import VisionKit
import Vision

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean8, .ean13, .upce, .code128, .qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard !uiViewController.isScanning else { return }
        try? uiViewController.startScanning()
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: BarcodeScannerView
        private var completed = false

        init(parent: BarcodeScannerView) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !completed else { return }
            for item in addedItems {
                if case let .barcode(barcode) = item, let payload = barcode.payloadStringValue {
                    completed = true
                    parent.onScan(payload)
                    parent.dismiss()
                    return
                }
            }
        }
    }
}

struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onScan: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    BarcodeScannerView(onScan: onScan)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .bottom) {
                            Label(L10n.text("Στόχευσε το barcode μέσα στην κάμερα", "Point the camera at the barcode"), systemImage: "barcode.viewfinder")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.bottom, 24)
                        }
                } else {
                    ContentUnavailableView(
                        L10n.text("Ο σαρωτής δεν είναι διαθέσιμος", "Scanner unavailable"),
                        systemImage: "barcode.viewfinder",
                        description: Text(L10n.text("Χρησιμοποίησε πραγματικό iPhone με υποστηριζόμενη κάμερα ή γράψε το barcode χειροκίνητα.", "Use a supported iPhone camera or enter the barcode manually."))
                    )
                }
            }
            .navigationTitle(L10n.text("Σάρωση Barcode", "Scan Barcode"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("Κλείσιμο", "Close")) { dismiss() }
                }
            }
        }
    }
}
