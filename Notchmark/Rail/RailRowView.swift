import SwiftUI

/// Role: Rail. One accordion row: phase word, grade, balance bar, inline notch history.
struct RailRowView: View {
    let article: Article
    let currencyCode: String
    let grade: LibraryGrade
    let expanded: Bool
    let onToggle: () -> Void
    let onCarve: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: LedgerPalette.space(1)) {
                    VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
                        Text(article.name)
                            .font(.ledger(.articleTitle))
                            .foregroundStyle(LedgerPalette.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        HStack(spacing: LedgerPalette.space(1)) {
                            Text(LedgerChrome.phaseLabel(mark: article.mark))
                                .font(.ledger(.footnote))
                                .foregroundStyle(LedgerPalette.ink)
                            Text("Grade \(LedgerChrome.gradeLabel(grade))")
                                .font(.ledger(.footnote))
                                .foregroundStyle(LedgerPalette.ink)
                            Text(cpuCaption)
                                .font(.ledger(.footnote))
                                .foregroundStyle(LedgerPalette.ink)
                                .layoutPriority(1)
                        }
                    }
                    Spacer(minLength: LedgerPalette.space(1))
                    balanceCaption
                }
                .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(expanded ? "Collapse notch history" : "Expand notch history")

            NotchRailRepresentable(
                purchasePrice: article.purchasePrice,
                perNotchShare: article.perNotchShare,
                balance: currentBalance,
                onCarve: onCarve
            )
            .frame(height: LedgerPalette.tap + LedgerPalette.space(3))

            if article.mark == nil {
                twistBanner
            }

            if expanded {
                notchHistory
            }
        }
        .padding(LedgerPalette.space(1))
        .background(LedgerPalette.surface)
    }

    private var currentBalance: Double {
        switch article.phase {
        case .amortizing(let balance):
            return balance
        case .breakeven, .profit:
            return 0
        }
    }

    private var balanceCaption: some View {
        Text(CurrencyFormatting.string(currentBalance, code: currencyCode))
            .font(.ledger(.stampNumeral))
            .foregroundStyle(LedgerPalette.ink)
            .layoutPriority(1)
    }

    private var cpuCaption: String {
        let cpu = LibraryGrading.costPerUse(
            price: article.purchasePrice,
            disposal: article.disposalValue,
            uses: article.notches.count
        )
        return CurrencyFormatting.string(cpu, code: currencyCode) + "/use"
    }

    private var twistBanner: some View {
        HStack(spacing: LedgerPalette.space(1)) {
            Image("ntm_MarkStamp")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
            Text("Unranked until a Mark is written")
                .font(.ledger(.footnote))
                .foregroundStyle(LedgerPalette.accent)
        }
        .frame(minHeight: LedgerPalette.tap, alignment: .leading)
    }

    private var notchHistory: some View {
        VStack(alignment: .leading, spacing: 0) {
            if article.notches.isEmpty {
                Text("No notches yet.")
                    .font(.ledger(.footnote))
                    .foregroundStyle(LedgerPalette.ink)
            } else {
                ForEach(Array(article.notches.enumerated()), id: \.element.id) { index, notch in
                    HStack(spacing: LedgerPalette.space(1)) {
                        Text("#\(CurrencyFormatting.integer(index + 1))")
                            .font(.ledger(.stampNumeral))
                            .foregroundStyle(LedgerPalette.ink)
                        Text(DayKey.label(for: notch.date))
                            .font(.ledger(.footnote))
                            .foregroundStyle(LedgerPalette.ink)
                        Text(DayKey.timeLabel(for: notch.date))
                            .font(.ledger(.footnote))
                            .foregroundStyle(LedgerPalette.ink)
                        if article.mark?.index == index {
                            Image("ntm_MarkStamp")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .accessibilityLabel("Breakeven Mark")
                        }
                    }
                    .padding(.vertical, LedgerPalette.space(1))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.top, LedgerPalette.space(1))
    }
}
