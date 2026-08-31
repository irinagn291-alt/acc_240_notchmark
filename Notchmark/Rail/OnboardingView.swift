import SwiftUI

/// Role: Rail. First-run walkthrough. Skip still writes sensible defaults.
struct OnboardingView: View {
    var onFinish: (_ currencyCode: String, _ shareMethod: ShareMethod, _ skipped: Bool) -> Void

    @State private var page = 0
    @State private var currencyCode = "USD"
    @State private var shareMethod: ShareMethod = .dividedByTargetUses

    private let pages: [(image: String, title: String, body: String)] = [
        ("ntm_Onboarding1", "What you own", "Track durable goods, their purchase price, and the ugly per-use number."),
        ("ntm_Onboarding2", "One verb: Notch", "Each use carves one share off the balance bar on the rail."),
        ("ntm_Onboarding3", "Write the Mark", "When balance hits zero, a Breakeven Mark flips the row to Profit and unlocks the Board."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    onboardingPage(item)
                        .tag(index)
                }
                preferencesPage
                    .tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            bottomBar
        }
        .background(LedgerPalette.background.ignoresSafeArea())
    }

    private func onboardingPage(_ item: (image: String, title: String, body: String)) -> some View {
        VStack(spacing: LedgerPalette.space(2)) {
            Spacer(minLength: LedgerPalette.space(2))
            Image(item.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 320)
                .accessibilityHidden(true)
            Text(item.title)
                .font(.ledger(.heading))
                .foregroundStyle(LedgerPalette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(item.body)
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LedgerPalette.space(2))
            Spacer(minLength: LedgerPalette.space(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var preferencesPage: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
            Spacer(minLength: LedgerPalette.space(2))
            Text("Ledger defaults")
                .font(.ledger(.heading))
                .foregroundStyle(LedgerPalette.ink)
            Text("Currency and how new Articles divide their price.")
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
            Picker("Currency", selection: $currencyCode) {
                Text("USD").tag("USD")
                Text("EUR").tag("EUR")
                Text("GBP").tag("GBP")
            }
            .pickerStyle(.segmented)
            .frame(minHeight: LedgerPalette.tap)
            Picker("Default share", selection: $shareMethod) {
                Text("Price ÷ uses").tag(ShareMethod.dividedByTargetUses)
                Text("Manual").tag(ShareMethod.manualShare)
            }
            .pickerStyle(.segmented)
            .frame(minHeight: LedgerPalette.tap)
            Spacer(minLength: LedgerPalette.space(2))
        }
        .padding(.horizontal, LedgerPalette.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var bottomBar: some View {
        VStack(spacing: LedgerPalette.space(1)) {
            if page < pages.count {
                onboardingPrimaryButton("Continue") { page += 1 }
                skipButton
            } else {
                onboardingPrimaryButton("Start notching") {
                    onFinish(currencyCode, shareMethod, false)
                }
                skipButton
            }
        }
        .padding(LedgerPalette.space(2))
    }

    private var skipButton: some View {
        Button("Skip") {
            onFinish("USD", .dividedByTargetUses, true)
        }
        .font(.ledger(.footnote))
        .foregroundStyle(LedgerPalette.ink)
        .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    private func onboardingPrimaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.background)
                .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
                .background(LedgerPalette.accent)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
