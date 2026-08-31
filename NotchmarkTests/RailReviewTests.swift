import XCTest
@testable import Notchmark

final class RailReviewTests: XCTestCase {
    func test_reviewParserReadsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            RailLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        consumed = false
        XCTAssertEqual(
            RailLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .log
        )
        XCTAssertTrue(consumed)

        var board = false
        var settings = false
        RailLaunch.bind(.log, board: &board, settings: &settings)
        XCTAssertTrue(board)
        XCTAssertFalse(settings)

        RailLaunch.bind(.goals, board: &board, settings: &settings)
        XCTAssertFalse(board)
        XCTAssertTrue(settings)
    }
}

final class MarkForecastTests: XCTestCase {
    func test_forecastListsOnlyAmortizingArticles() {
        let marked = Article(
            name: "Marked",
            purchasePrice: 40,
            shareMethod: .manualShare,
            perNotchShare: 10,
            mark: BreakevenMark(index: 3, date: Date())
        )
        let amortizing = Article(
            name: "Tool",
            purchasePrice: 30,
            shareMethod: .manualShare,
            perNotchShare: 10,
            notches: [NotchEntry(date: Date(timeIntervalSince1970: 100))]
        )
        let entries = MarkForecast.entries(for: [marked, amortizing])
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].articleName, "Tool")
        XCTAssertEqual(entries[0].notchesRemaining, 2)
    }

    func test_averageIntervalRequiresTwoNotches() {
        let one = [NotchEntry(date: Date())]
        XCTAssertNil(MarkForecast.averageIntervalDays(for: one))
        let two = [
            NotchEntry(date: Date(timeIntervalSince1970: 0)),
            NotchEntry(date: Date(timeIntervalSince1970: 86_400)),
        ]
        XCTAssertEqual(MarkForecast.averageIntervalDays(for: two)!, 1, accuracy: 0.001)
    }
}

final class PriceScannerTests: XCTestCase {
    func test_extractsPrintedPrice() {
        XCTAssertEqual(PriceTagParser.extractPrice(from: "Sale $24.99"), 24.99)
        XCTAssertEqual(PriceTagParser.extractPrice(from: "12,50"), 12.5)
    }
}

final class CurrencyFormattingTests: XCTestCase {
    func test_parseDecimalRejectsNegativeAndGarbage() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(CurrencyFormatting.parseDecimal("12.5", locale: locale), 12.5)
        XCTAssertNil(CurrencyFormatting.parseDecimal("-4", locale: locale))
        XCTAssertNil(CurrencyFormatting.parseDecimal("abc", locale: locale))
        XCTAssertEqual(CurrencyFormatting.integer(4, locale: locale), "4")
    }
}
