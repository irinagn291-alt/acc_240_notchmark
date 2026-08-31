import Foundation

/// Role: Board. Query layer — only Marked Articles rank; Amortizing rows are structurally absent.
enum ProfitPerNotchRanking {
    static func ranked(_ articles: [Article]) -> [Article] {
        articles
            .filter { $0.mark != nil }
            .sorted { profitPerNotch($0) > profitPerNotch($1) }
    }

    static func profitPerNotch(_ article: Article) -> Double {
        article.perNotchShare
    }
}
