import SwiftUI

/// Role: Board. Ledger sheet — ranked Marks only plus Forecast. Amortizing rows are structurally absent.
struct BoardView: View {
    @ObservedObject var session: RailSession
    var onClose: () -> Void

    init(session: RailSession, onClose: @escaping () -> Void = {}) {
        self.session = session
        self.onClose = onClose
    }

    init() {
        self.init(session: .previewPopulated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
            LedgerSheetBar(title: "Ledger", onClose: onClose)
            if let fault = session.fault, ranked.isEmpty, session.forecastEntries().isEmpty {
                LedgerVacancy(
                    image: "ntm_EmptyList",
                    headline: "Ledger could not load.",
                    line: fault,
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await session.retry() }
                }
            } else if ranked.isEmpty, session.forecastEntries().isEmpty {
                LedgerVacancy(
                    image: "ntm_EmptyList",
                    headline: "No Marks yet.",
                    line: "Notch Articles on the rail until they write a Breakeven Mark.",
                    actionTitle: "Close"
                ) {
                    onClose()
                }
            } else {
                populated
            }
        }
        .padding(LedgerPalette.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(LedgerPalette.background.ignoresSafeArea())
    }

    private var ranked: [Article] {
        session.rankedMarked()
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
                MarkLedgerView(embedded: true)
                ForecastStrip(entries: session.forecastEntries())
                Text("Profit per notch")
                    .font(.ledger(.articleTitle))
                    .foregroundStyle(LedgerPalette.ink)
                if ranked.isEmpty {
                    Text("No Marks yet. Amortizing Articles stay off this ranking.")
                        .font(.ledger(.body))
                        .foregroundStyle(LedgerPalette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(LedgerPalette.space(1))
                        .background(LedgerPalette.surface)
                } else {
                    ForEach(ranked) { article in
                        ledgerRow(article)
                    }
                }
                InsightsView(session: session, onClose: onClose, embedded: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentMargins(.bottom, LedgerPalette.space(2))
    }

    private func ledgerRow(_ article: Article) -> some View {
        HStack(spacing: LedgerPalette.space(1)) {
            VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
                Text(article.name)
                    .font(.ledger(.body))
                    .foregroundStyle(LedgerPalette.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let mark = article.mark {
                    Text("Mark #\(CurrencyFormatting.integer(mark.index + 1)) · \(DayKey.label(for: mark.date))")
                        .font(.ledger(.footnote))
                        .foregroundStyle(LedgerPalette.ink)
                }
            }
            Spacer(minLength: LedgerPalette.space(1))
            Text(CurrencyFormatting.string(ProfitPerNotchRanking.profitPerNotch(article), code: session.settings.currencyCode))
                .font(.ledger(.stampNumeral))
                .foregroundStyle(LedgerPalette.ink)
                .layoutPriority(1)
            Image("ntm_MarkStamp")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .accessibilityLabel("Breakeven Mark")
        }
        .padding(.horizontal, LedgerPalette.space(1))
        .frame(minHeight: LedgerPalette.tap)
        .frame(maxWidth: .infinity)
        .background(LedgerPalette.surface)
    }
}
