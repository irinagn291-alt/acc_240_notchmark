import XCTest
@testable import Notchmark

final class LibraryGradingTests: XCTestCase {
    func test_costPerUseInvariant() {
        XCTAssertEqual(LibraryGrading.costPerUse(price: 80, disposal: 5, uses: 0), 75)
        XCTAssertEqual(LibraryGrading.costPerUse(price: 80, disposal: 5, uses: 4), 18.75)
        XCTAssertEqual(LibraryGrading.costPerUse(price: 24, disposal: 2, uses: 1), 22)
    }

    func test_insufficientDataWithoutPeersOrAge() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let young = Article(
            name: "New mug",
            purchasePrice: 12,
            shareMethod: .manualShare,
            perNotchShare: 2,
            acquiredAt: now.addingTimeInterval(-86400 * 2)
        )
        let peers = (0 ..< 6).map { index in
            Article(
                name: "Peer \(index)",
                purchasePrice: Double(10 + index),
                shareMethod: .manualShare,
                perNotchShare: 1,
                acquiredAt: now.addingTimeInterval(-86400 * 10)
            )
        }
        XCTAssertEqual(LibraryGrading.grade(for: young, among: peers, now: now), .insufficientData)
        XCTAssertEqual(LibraryGrading.grade(for: peers[0], among: Array(peers.prefix(4)), now: now), .insufficientData)
    }

    func test_relativeLetterGradeAgainstPeers() {
        let now = Date(timeIntervalSince1970: 3_000_000)
        let old = now.addingTimeInterval(-86400 * 10)
        let subject = Article(
            name: "Efficient tool",
            purchasePrice: 20,
            shareMethod: .manualShare,
            perNotchShare: 2,
            disposalValue: 0,
            acquiredAt: old,
            notches: Array(repeating: NotchEntry(date: old), count: 10)
        )
        let peers = [
            Article(name: "A", purchasePrice: 100, shareMethod: .manualShare, perNotchShare: 5, acquiredAt: old, notches: Array(repeating: NotchEntry(date: old), count: 2)),
            Article(name: "B", purchasePrice: 90, shareMethod: .manualShare, perNotchShare: 5, acquiredAt: old, notches: Array(repeating: NotchEntry(date: old), count: 2)),
            Article(name: "C", purchasePrice: 80, shareMethod: .manualShare, perNotchShare: 5, acquiredAt: old, notches: Array(repeating: NotchEntry(date: old), count: 2)),
            Article(name: "D", purchasePrice: 70, shareMethod: .manualShare, perNotchShare: 5, acquiredAt: old, notches: Array(repeating: NotchEntry(date: old), count: 2)),
            Article(name: "E", purchasePrice: 60, shareMethod: .manualShare, perNotchShare: 5, acquiredAt: old, notches: Array(repeating: NotchEntry(date: old), count: 2)),
        ]
        let grade = LibraryGrading.grade(for: subject, among: peers + [subject], now: now)
        XCTAssertEqual(grade, .letter("A+"))
    }

    func test_demoShelfProducesRelativeLetterGrades() {
        let now = Date()
        let articles = ArticleSeed.demoArticles()
        XCTAssertGreaterThanOrEqual(articles.count, 6)
        let graded = articles.map { LibraryGrading.grade(for: $0, among: articles, now: now) }
        XCTAssertTrue(graded.contains { if case .letter = $0 { return true }; return false })
        XCTAssertFalse(graded.allSatisfy { $0 == .insufficientData })
    }
}
