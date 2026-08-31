import SwiftUI

/// Role: Mark. Twist copy — folded into Board. Not a fifth Rail destination.
struct MarkLedgerView: View {
    var onClose: () -> Void = {}
    var embedded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
            if !embedded {
                LedgerSheetBar(title: "Breakeven ledger", onClose: onClose)
            }
            VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
                Image("ntm_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                Text("An Amortizing Article cannot rank until it writes a Mark.")
                    .font(.ledger(.articleTitle))
                    .foregroundStyle(LedgerPalette.ink)
                Text("Every notch subtracts one share from the purchase price. The instant balance reaches zero the Article stamps an immutable Breakeven Mark — notch index and date — and flips to Profit. The Board query selects only Marked Articles; still-Amortizing rows are absent from that query, not filtered out afterward.")
                    .font(.ledger(.body))
                    .foregroundStyle(LedgerPalette.ink)
                ruleBlock(
                    title: "While Amortizing",
                    detail: "Balance falls notch by notch. The Forecast strip estimates notches remaining at your own pace."
                )
                ruleBlock(
                    title: "At the Mark",
                    detail: "The Mark is written once. Editing per-notch share later cannot rewrite it."
                )
                ruleBlock(
                    title: "In Profit",
                    detail: "Further notches accumulate profit history. Only then may the Article appear on the Ledger ranking."
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ruleBlock(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(1) / 2) {
            Text(title)
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
            Text(detail)
                .font(.ledger(.footnote))
                .foregroundStyle(LedgerPalette.ink)
        }
        .padding(LedgerPalette.space(1))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LedgerPalette.surface)
    }
}
