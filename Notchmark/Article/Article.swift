import Foundation

/// Role: Article. Owned durable good on the rail. Owns append-only notches and an optional frozen Mark.
struct Article: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var purchasePrice: Double
    var shareMethod: ShareMethod
    var perNotchShare: Double
    var targetUses: Int?
    var disposalValue: Double
    var acquiredAt: Date
    var notches: [NotchEntry]
    var mark: BreakevenMark?

    init(
        id: UUID = UUID(),
        name: String,
        purchasePrice: Double,
        shareMethod: ShareMethod,
        perNotchShare: Double,
        targetUses: Int? = nil,
        disposalValue: Double = 0,
        acquiredAt: Date = Date(),
        notches: [NotchEntry] = [],
        mark: BreakevenMark? = nil
    ) {
        self.id = id
        self.name = name
        self.purchasePrice = purchasePrice
        self.shareMethod = shareMethod
        self.perNotchShare = perNotchShare
        self.targetUses = targetUses
        self.disposalValue = disposalValue
        self.acquiredAt = acquiredAt
        self.notches = notches
        self.mark = mark
    }

    var phase: NotchPhase {
        AmortizationLedger.reduce(
            over: notches,
            purchasePrice: purchasePrice,
            perNotchShare: perNotchShare,
            storedMark: mark
        )
    }

    static func perNotchShare(
        purchasePrice: Double,
        shareMethod: ShareMethod,
        manualShare: Double,
        targetUses: Int?
    ) -> Double {
        switch shareMethod {
        case .manualShare:
            return manualShare
        case .dividedByTargetUses:
            guard let targetUses, targetUses > 0 else { return 0 }
            return purchasePrice / Double(targetUses)
        }
    }
}

/// Role: Article. Failures of the primary notch verb and share setup.
enum ArticleError: Error, Equatable, Sendable {
    case invalidShare
    case invalidPrice
    case emptyName
}

/// Role: Article. Open a new Article on the rail.
func openingArticle(
    name: String,
    purchasePrice: Double,
    shareMethod: ShareMethod,
    manualShare: Double,
    targetUses: Int?,
    disposalValue: Double = 0,
    acquiredAt: Date = Date(),
    id: UUID = UUID()
) throws -> Article {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw ArticleError.emptyName }
    guard purchasePrice.isFinite, purchasePrice >= 0 else { throw ArticleError.invalidPrice }
    let share = Article.perNotchShare(
        purchasePrice: purchasePrice,
        shareMethod: shareMethod,
        manualShare: manualShare,
        targetUses: targetUses
    )
    guard share.isFinite, share > 0 else { throw ArticleError.invalidShare }
    return Article(
        id: id,
        name: trimmed,
        purchasePrice: purchasePrice,
        shareMethod: shareMethod,
        perNotchShare: share,
        targetUses: targetUses,
        disposalValue: max(0, disposalValue),
        acquiredAt: acquiredAt
    )
}

/// Role: Article. Persist Mark when the fold first crosses zero. Seed and import use this too.
func writingMark(_ article: Article) -> Article {
    guard article.mark == nil else { return article }
    let phase = AmortizationLedger.reduce(
        over: article.notches,
        purchasePrice: article.purchasePrice,
        perNotchShare: article.perNotchShare,
        storedMark: nil
    )
    guard case .breakeven(let mark) = phase else { return article }
    var next = article
    next.mark = mark
    return next
}

/// Role: Article. Primary verb — append one notch and write Mark once when balance crosses zero.
func notching(_ article: Article, at date: Date) throws -> Article {
    guard article.perNotchShare.isFinite, article.perNotchShare > 0 else {
        throw ArticleError.invalidShare
    }
    var next = article
    next.notches.append(NotchEntry(date: date))
    return writingMark(next)
}
