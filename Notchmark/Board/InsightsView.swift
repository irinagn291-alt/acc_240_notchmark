import SwiftUI

/// Role: Board. Insights screen — relative library grades. Empty, populated, and error states.
struct InsightsView: View {
    @ObservedObject var session: RailSession
    var onClose: () -> Void
    var embedded: Bool

    init(session: RailSession, onClose: @escaping () -> Void = {}, embedded: Bool = false) {
        self.session = session
        self.onClose = onClose
        self.embedded = embedded
    }

    init() {
        self.init(session: .previewPopulated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
            if !embedded {
                LedgerSheetBar(title: "Insights", onClose: onClose)
            }
            if let fault = session.fault, session.articles.isEmpty {
                LedgerVacancy(
                    image: "ntm_EmptyList",
                    headline: "Insights could not load.",
                    line: fault,
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await session.retry() }
                }
            } else if session.articles.isEmpty {
                if embedded {
                    Text("No Articles to grade yet.")
                        .font(.ledger(.body))
                        .foregroundStyle(LedgerPalette.ink)
                } else {
                    LedgerVacancy(
                        image: "ntm_EmptyList",
                        headline: "No graded Articles yet.",
                        line: "Grades need seven days in the library and five peer Articles.",
                        actionTitle: "Close"
                    ) {
                        onClose()
                    }
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: embedded ? nil : .infinity, alignment: .top)
        .background {
            if !embedded {
                LedgerPalette.background.ignoresSafeArea()
            }
        }
    }

    private var rows: [(article: Article, grade: LibraryGrade)] {
        session.articles.map { article in
            (article, session.grade(for: article))
        }
        .sorted { lhs, rhs in
            switch (lhs.grade, rhs.grade) {
            case (.letter(let a), .letter(let b)):
                return a < b
            case (.letter, .insufficientData):
                return true
            case (.insufficientData, .letter):
                return false
            default:
                return lhs.article.name < rhs.article.name
            }
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
            Text("Library grades")
                .font(.ledger(.articleTitle))
                .foregroundStyle(LedgerPalette.ink)
            Text("Grades are relative to this library.")
                .font(.ledger(.footnote))
                .foregroundStyle(LedgerPalette.ink)
            ForEach(rows, id: \.article.id) { row in
                HStack(spacing: LedgerPalette.space(1)) {
                    Text(row.article.name)
                        .font(.ledger(.body))
                        .foregroundStyle(LedgerPalette.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: LedgerPalette.space(1))
                    Text(LedgerChrome.gradeLabel(row.grade))
                        .font(.ledger(.stampNumeral))
                        .foregroundStyle(LedgerPalette.ink)
                        .layoutPriority(1)
                    Text(cpuLabel(for: row.article))
                        .font(.ledger(.footnote))
                        .foregroundStyle(LedgerPalette.ink)
                        .layoutPriority(1)
                }
                .padding(.horizontal, LedgerPalette.space(1))
                .frame(minHeight: LedgerPalette.tap)
                .frame(maxWidth: .infinity)
                .background(LedgerPalette.surface)
            }
        }
    }

    private func cpuLabel(for article: Article) -> String {
        let cpu = LibraryGrading.costPerUse(
            price: article.purchasePrice,
            disposal: article.disposalValue,
            uses: article.notches.count
        )
        return CurrencyFormatting.string(cpu, code: session.settings.currencyCode) + "/use"
    }
}
