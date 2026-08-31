import XCTest
@testable import Notchmark

final class ArticleStoreTests: XCTestCase {
    private var articlesDirectory: URL!
    private var settingsURL: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        articlesDirectory = base.appendingPathComponent("Articles", isDirectory: true)
        settingsURL = base.appendingPathComponent(SettingsCodec.fileName)
        suiteName = "ntm.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let articlesDirectory {
            try? FileManager.default.removeItem(at: articlesDirectory.deletingLastPathComponent())
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        articlesDirectory = nil
        settingsURL = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTripReloadPreservesNotchesAndMark() async throws {
        let store = makeStore()
        var article = try openingArticle(
            name: "Lantern",
            purchasePrice: 80,
            shareMethod: .manualShare,
            manualShare: 20,
            targetUses: nil,
            id: ArticleSeed.gadgetID
        )
        for _ in 0 ..< 4 {
            article = try notching(article, at: Date(timeIntervalSince1970: 2_000))
        }
        try await store.save(article)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.articles.count, 1)
        let restored = try XCTUnwrap(loaded.articles.first)
        XCTAssertEqual(restored.id, ArticleSeed.gadgetID)
        XCTAssertEqual(restored.notches.count, 4)
        XCTAssertEqual(restored.mark?.index, 3)
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let store = makeStore()
        let article = try openingArticle(
            name: "Kettle",
            purchasePrice: 40,
            shareMethod: .manualShare,
            manualShare: 5,
            targetUses: nil
        )
        try await store.save(article)
        let url = articlesDirectory.appendingPathComponent("\(article.id.uuidString).json")
        let backup = url.appendingPathExtension("backup")
        try FileManager.default.copyItem(at: url, to: backup)
        try Data("{bad".utf8).write(to: url)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.articles.first?.id, article.id)
    }

    func test_corruptFileWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: articlesDirectory, withIntermediateDirectories: true)
        let url = articlesDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try Data("nope".utf8).write(to: url)
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.articles.isEmpty)
    }

    func test_resetAllDataClearsArticlesAndSettings() async throws {
        let store = makeStore()
        try await store.save(
            try openingArticle(
                name: "Lamp",
                purchasePrice: 20,
                shareMethod: .manualShare,
                manualShare: 4,
                targetUses: nil
            )
        )
        try await store.saveSettings(NotchSettings(currencyCode: "EUR", defaultShareMethod: .manualShare))
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.articles.isEmpty)
        XCTAssertEqual(loaded.settings.currencyCode, "USD")
    }

    func test_storeNotchWritesMarkOnce() async throws {
        let store = makeStore()
        let article = try openingArticle(
            name: "Driver",
            purchasePrice: 30,
            shareMethod: .manualShare,
            manualShare: 10,
            targetUses: nil
        )
        try await store.save(article)
        _ = try await store.notch(articleID: article.id, at: Date(timeIntervalSince1970: 100))
        _ = try await store.notch(articleID: article.id, at: Date(timeIntervalSince1970: 200))
        let marked = try await store.notch(articleID: article.id, at: Date(timeIntervalSince1970: 300))
        XCTAssertEqual(marked.notches.count, 3)
        XCTAssertEqual(marked.mark?.index, 2)
        let relaunched = makeStore()
        let loaded = await relaunched.load()
        let restored = try XCTUnwrap(loaded.articles.first)
        XCTAssertEqual(restored.mark?.index, 2)
    }

    func test_loadPersistsMarkWhenImportCrossesZero() async throws {
        let store = makeStore()
        var article = try openingArticle(
            name: "Skillet",
            purchasePrice: 48,
            shareMethod: .dividedByTargetUses,
            manualShare: 4,
            targetUses: 12
        )
        article.notches = (0 ..< 12).map { index in
            NotchEntry(date: Date(timeIntervalSince1970: Double(index + 1)))
        }
        XCTAssertNil(article.mark)
        let url = articlesDirectory.appendingPathComponent("\(article.id.uuidString).json")
        try FileManager.default.createDirectory(at: articlesDirectory, withIntermediateDirectories: true)
        try ArticleCodec.encode(article).write(to: url)

        let loaded = await store.load()
        let restored = try XCTUnwrap(loaded.articles.first)
        XCTAssertEqual(restored.mark?.index, 11)
        let relaunched = await makeStore().load()
        XCTAssertEqual(relaunched.articles.first?.mark?.index, 11)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let article = try openingArticle(
            name: "Codec",
            purchasePrice: 12,
            shareMethod: .manualShare,
            manualShare: 3,
            targetUses: nil
        )
        let data = try ArticleCodec.encode(article)
        let decoded = try ArticleCodec.decode(data)
        XCTAssertEqual(decoded.id, article.id)
        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try ArticleCodec.decode(future)) { error in
            XCTAssertEqual(error as? ArticleCodec.Failure, .unsupportedSchema(99))
        }
    }

    private func makeStore() -> ArticleStore {
        ArticleStore(
            articlesDirectory: articlesDirectory,
            settingsURL: settingsURL,
            defaultsSuiteName: suiteName
        )
    }
}
