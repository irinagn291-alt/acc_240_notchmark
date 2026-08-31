import SwiftUI

/// Role: Board. Forecast strip for still-Amortizing Articles. CAShapeLayer ruled backdrop.
struct ForecastStrip: View {
    let entries: [MarkForecast.Entry]

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
            Text("Forecast to Mark")
                .font(.ledger(.articleTitle))
                .foregroundStyle(LedgerPalette.ink)
            if entries.isEmpty {
                Text("Every Article has written its Mark.")
                    .font(.ledger(.footnote))
                    .foregroundStyle(LedgerPalette.ink)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LedgerPalette.space(1)) {
                        ForEach(entries) { entry in
                            ForecastChip(entry: entry)
                        }
                    }
                }
            }
        }
        .padding(LedgerPalette.space(1))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ForecastStripBackdrop()
                .stroke(LedgerPalette.ink.opacity(0.2), lineWidth: 1)
                .background(LedgerPalette.surface)
        )
    }
}

private struct ForecastChip: View {
    let entry: MarkForecast.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
            Text(entry.articleName)
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
                .lineLimit(1)
            Text(MarkForecast.paceLabel(for: entry))
                .font(.ledger(.footnote))
                .foregroundStyle(LedgerPalette.ink)
        }
        .padding(LedgerPalette.space(1))
        .frame(minHeight: LedgerPalette.tap)
        .background(LedgerPalette.background)
        .overlay(
            Rectangle()
                .stroke(LedgerPalette.ink, lineWidth: 1)
        )
    }
}

private struct ForecastStripBackdrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing = LedgerPalette.unit
        var y = rect.minY + spacing
        while y < rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        return path
    }
}
