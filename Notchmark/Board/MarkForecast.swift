import Foundation

/// Role: Board. Rolling-average notches-to-Mark for still-Amortizing Articles.
enum MarkForecast {
    struct Entry: Identifiable, Equatable, Sendable {
        var id: UUID
        var articleName: String
        var notchesRemaining: Int
        var averageIntervalDays: Double?
    }

    static func entries(for articles: [Article]) -> [Entry] {
        articles.compactMap { article in
            guard article.mark == nil else { return nil }
            guard case .amortizing(let balance) = article.phase else { return nil }
            let remaining = max(1, Int(ceil(balance / max(article.perNotchShare, 0.0001))))
            return Entry(
                id: article.id,
                articleName: article.name,
                notchesRemaining: remaining,
                averageIntervalDays: averageIntervalDays(for: article.notches)
            )
        }
        .sorted { $0.notchesRemaining < $1.notchesRemaining }
    }

    static func averageIntervalDays(for notches: [NotchEntry]) -> Double? {
        guard notches.count >= 2 else { return nil }
        let sorted = notches.sorted { $0.date < $1.date }
        var total: TimeInterval = 0
        for index in 1 ..< sorted.count {
            total += sorted[index].date.timeIntervalSince(sorted[index - 1].date)
        }
        return total / Double(sorted.count - 1) / 86_400
    }

    static func paceLabel(for entry: Entry) -> String {
        let notches = CurrencyFormatting.integer(entry.notchesRemaining)
        let noun = entry.notchesRemaining == 1 ? "notch" : "notches"
        guard let days = entry.averageIntervalDays, days.isFinite, days > 0 else {
            return "\(notches) \(noun) to Mark"
        }
        let rounded = CurrencyFormatting.integer(max(1, Int(days.rounded())))
        return "\(notches) \(noun) · ~\(rounded)d pace"
    }
}
