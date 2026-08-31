import XCTest
@testable import Notchmark

final class AmortizationLedgerTests: XCTestCase {
    func test_foldStartsAmortizing() {
        let phase = AmortizationLedger.reduce(
            over: [],
            purchasePrice: 80,
            perNotchShare: 20,
            storedMark: nil
        )
        XCTAssertEqual(phase, .amortizing(balance: 80))
    }

    func test_foldWritesBreakevenMarkAtZeroCrossing() {
        let stamp = Date(timeIntervalSince1970: 1_000)
        let notches = (0 ..< 4).map { _ in NotchEntry(date: stamp) }
        let phase = AmortizationLedger.reduce(
            over: notches,
            purchasePrice: 80,
            perNotchShare: 20,
            storedMark: nil
        )
        guard case .breakeven(let mark) = phase else {
            return XCTFail("expected breakeven")
        }
        XCTAssertEqual(mark.index, 3)
        XCTAssertEqual(mark.date, stamp)
    }

    func test_storedMarkShortCircuitsToProfit() {
        let mark = BreakevenMark(index: 3, date: Date(timeIntervalSince1970: 1_000))
        let notches = (0 ..< 6).map { index in
            NotchEntry(date: Date(timeIntervalSince1970: Double(index)))
        }
        let phase = AmortizationLedger.reduce(
            over: notches,
            purchasePrice: 80,
            perNotchShare: 20,
            storedMark: mark
        )
        XCTAssertEqual(phase, .profit(mark: mark))
    }

    func test_editingShareDoesNotRewriteStoredMark() throws {
        let stamp = Date(timeIntervalSince1970: 5_000)
        var article = try openingArticle(
            name: "Lantern",
            purchasePrice: 80,
            shareMethod: .manualShare,
            manualShare: 20,
            targetUses: nil
        )
        for _ in 0 ..< 4 {
            article = try notching(article, at: stamp)
        }
        let originalMark = try XCTUnwrap(article.mark)
        article.perNotchShare = 5
        let phase = AmortizationLedger.reduce(
            over: article.notches,
            purchasePrice: article.purchasePrice,
            perNotchShare: article.perNotchShare,
            storedMark: article.mark
        )
        XCTAssertEqual(phase, .profit(mark: originalMark))
        XCTAssertEqual(article.mark, originalMark)
    }
}

final class NotchVerbTests: XCTestCase {
    func test_notchingRejectsInvalidShare() throws {
        let article = Article(
            name: "Broken",
            purchasePrice: 10,
            shareMethod: .manualShare,
            perNotchShare: 0
        )
        XCTAssertThrowsError(try notching(article, at: Date())) { error in
            XCTAssertEqual(error as? ArticleError, .invalidShare)
        }
    }

    func test_notchingAppendsImmutableHistory() throws {
        let start = try openingArticle(
            name: "Driver",
            purchasePrice: 30,
            shareMethod: .manualShare,
            manualShare: 10,
            targetUses: nil
        )
        let first = try notching(start, at: Date(timeIntervalSince1970: 100))
        XCTAssertEqual(first.notches.count, 1)
        let second = try notching(first, at: Date(timeIntervalSince1970: 200))
        XCTAssertEqual(second.notches.count, 2)
        XCTAssertEqual(second.notches[0].date, first.notches[0].date)
    }

    func test_writingMarkPersistsBreakevenFromFold() {
        let stamp = Date(timeIntervalSince1970: 1_000)
        let article = Article(
            name: "Skillet",
            purchasePrice: 48,
            shareMethod: .dividedByTargetUses,
            perNotchShare: 4,
            targetUses: 12,
            notches: (0 ..< 12).map { _ in NotchEntry(date: stamp) }
        )
        XCTAssertNil(article.mark)
        let stamped = writingMark(article)
        XCTAssertEqual(stamped.mark?.index, 11)
        XCTAssertEqual(stamped.mark?.date, stamp)
        XCTAssertEqual(LedgerChrome.phaseLabel(mark: stamped.mark), "Profit")
        XCTAssertEqual(LedgerChrome.phaseLabel(mark: nil), "Amortizing")
    }

    func test_demoSkilletPersistsMark() {
        let skillet = ArticleSeed.demoArticles().first { $0.id == ArticleSeed.skilletID }
        XCTAssertNotNil(skillet?.mark)
        XCTAssertEqual(LedgerChrome.phaseLabel(mark: skillet?.mark), "Profit")
    }

    func test_openingArticleRejectsEmptyName() {
        XCTAssertThrowsError(
            try openingArticle(
                name: "   ",
                purchasePrice: 10,
                shareMethod: .manualShare,
                manualShare: 2,
                targetUses: nil
            )
        ) { error in
            XCTAssertEqual(error as? ArticleError, .emptyName)
        }
    }
}

final class ProfitPerNotchRankingTests: XCTestCase {
    func test_boardQueryExcludesAmortizingArticles() {
        let marked = Article(
            name: "Marked",
            purchasePrice: 40,
            shareMethod: .manualShare,
            perNotchShare: 10,
            mark: BreakevenMark(index: 3, date: Date())
        )
        let amortizing = Article(
            name: "Still paying",
            purchasePrice: 40,
            shareMethod: .manualShare,
            perNotchShare: 10
        )
        let ranked = ProfitPerNotchRanking.ranked([amortizing, marked])
        XCTAssertEqual(ranked.map(\.name), ["Marked"])
    }

    func test_boardRanksMarkedByProfitPerNotch() {
        let cheap = Article(
            name: "Cheap",
            purchasePrice: 10,
            shareMethod: .manualShare,
            perNotchShare: 2,
            mark: BreakevenMark(index: 4, date: Date())
        )
        let rich = Article(
            name: "Rich",
            purchasePrice: 100,
            shareMethod: .manualShare,
            perNotchShare: 25,
            mark: BreakevenMark(index: 3, date: Date())
        )
        XCTAssertEqual(ProfitPerNotchRanking.ranked([cheap, rich]).map(\.name), ["Rich", "Cheap"])
    }
}
