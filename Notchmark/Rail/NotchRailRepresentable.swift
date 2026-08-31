import SwiftUI

/// Role: Rail. UIViewRepresentable bridge. Accordion state stays in SwiftUI @State.
struct NotchRailRepresentable: UIViewRepresentable {
    var purchasePrice: Double
    var perNotchShare: Double
    var balance: Double
    var onCarve: () -> Void

    func makeUIView(context: Context) -> NotchRailView {
        let view = NotchRailView()
        view.onCarve = onCarve
        return view
    }

    func updateUIView(_ uiView: NotchRailView, context: Context) {
        uiView.purchasePrice = purchasePrice
        uiView.perNotchShare = perNotchShare
        uiView.balance = balance
        uiView.onCarve = onCarve
    }
}
