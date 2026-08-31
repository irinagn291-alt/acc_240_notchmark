import AVFoundation
import SwiftUI
import UIKit
import VisionKit

/// Role: Rail. Optional receipt scan to prefill purchase price on Add Article.
struct PriceScannerView: UIViewControllerRepresentable {
    @Binding var scannedPrice: Double?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text(languages: ["en-US"])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard DataScannerViewController.isSupported, DataScannerViewController.isAvailable else { return }
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedPrice: $scannedPrice, dismiss: dismiss)
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private var scannedPrice: Binding<Double?>
        private let dismiss: DismissAction
        private var didCapture = false

        init(scannedPrice: Binding<Double?>, dismiss: DismissAction) {
            self.scannedPrice = scannedPrice
            self.dismiss = dismiss
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !didCapture else { return }
            for item in addedItems {
                guard case .text(let text) = item else { continue }
                if let price = PriceTagParser.extractPrice(from: text.transcript) {
                    didCapture = true
                    scannedPrice.wrappedValue = price
                    dismiss()
                    return
                }
            }
        }

    }
}

struct PriceScannerSheet: View {
    @Binding var scannedPrice: Double?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraDenied = false

    var body: some View {
        VStack(spacing: 0) {
            LedgerSheetBar(title: "Scan a price tag", onClose: { dismiss() })
                .padding(.horizontal, LedgerPalette.space(2))
            Group {
                if cameraDenied {
                    denied
                } else if DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                    PriceScannerView(scannedPrice: $scannedPrice)
                } else {
                    Text("Scanning is not available on this device.")
                        .font(.ledger(.body))
                        .foregroundStyle(LedgerPalette.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(LedgerPalette.background.ignoresSafeArea())
        .onAppear {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .denied, .restricted:
                cameraDenied = true
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    Task { @MainActor in
                        cameraDenied = !granted
                    }
                }
            default:
                break
            }
        }
    }

    private var denied: some View {
        VStack(spacing: LedgerPalette.space(2)) {
            Text("Camera access is off.")
                .font(.ledger(.articleTitle))
                .foregroundStyle(LedgerPalette.ink)
            Text("Turn on camera access in Settings to scan a printed price.")
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
                .multilineTextAlignment(.center)
            Spacer(minLength: LedgerPalette.space(2))
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.ledger(.body))
            .foregroundStyle(LedgerPalette.background)
            .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
            .background(LedgerPalette.accent)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
        }
        .padding(LedgerPalette.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
