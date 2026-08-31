import Foundation

/// Role: Article. Preference keys. Demo seed is Simulator-only and versioned.
enum PreferenceKey {
    static let demoSeed = "ntm.demo.v1"
    static let onboardingComplete = "ntm.onboarding.complete"
}

/// Role: Article. Recoverable load outcome. Never crash on a corrupt file.
enum ArticleStoreWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Article. Store failures mapped by the shell.
enum ArticleStoreError: Error, Equatable, Sendable {
    case unknownArticle
    case invalidShare
}

/// Role: Article. The only seam views may talk to. FileManager stays inside the actor.
protocol ArticleStoring: Sendable {
    func load() async -> (articles: [Article], settings: NotchSettings, warning: ArticleStoreWarning?)
    func article(id: UUID) async -> Article?
    func save(_ article: Article) async throws
    func note(_ article: Article) async
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded() async throws
    func notch(articleID: UUID, at date: Date) async throws -> Article
    func settings() async -> NotchSettings
    func saveSettings(_ settings: NotchSettings) async throws
    func isOnboardingComplete() async -> Bool
    func setOnboardingComplete(_ flag: Bool) async
}

/// Role: Article. JSON document per aggregate under Application Support. Memory is the source of truth.
actor ArticleStore: ArticleStoring {
    private let articlesDirectory: URL
    private let settingsURL: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var articlesByID: [UUID: Article] = [:]
    private var settingsValue: NotchSettings = .default
    private var pendingIDs: Set<UUID> = []
    private var writeTask: Task<Void, Never>?
    private(set) var warning: ArticleStoreWarning?
    private(set) var lastWriteError: String?

    init(
        articlesDirectory: URL,
        settingsURL: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.articlesDirectory = articlesDirectory
        self.settingsURL = settingsURL
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportURLs(fileManager: FileManager = .default) throws -> (articles: URL, settings: URL) {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let base = root.appendingPathComponent("Notchmark", isDirectory: true)
        return (
            base.appendingPathComponent("Articles", isDirectory: true),
            base.appendingPathComponent(SettingsCodec.fileName)
        )
    }

    var articles: [Article] {
        articlesByID.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func load() async -> (articles: [Article], settings: NotchSettings, warning: ArticleStoreWarning?) {
        warning = nil
        articlesByID = [:]
        settingsValue = loadSettingsFromDisk()
        prepareArticlesDirectory()
        let urls = articleURLs()
        if urls.isEmpty {
            return (articles, settingsValue, warning)
        }
        var recovered = false
        var loadedAny = false
        for url in urls {
            if let article = decodeArticleFile(url) {
                adopt(article)
                loadedAny = true
                continue
            }
            if let article = decodeArticleFile(backupURL(for: url)) {
                adopt(article)
                recovered = true
                loadedAny = true
            }
        }
        if recovered {
            warning = .recoveredFromBackup
        } else if !loadedAny {
            warning = .startedEmpty
        }
        return (articles, settingsValue, warning)
    }

    func article(id: UUID) async -> Article? {
        articlesByID[id]
    }

    func save(_ article: Article) async throws {
        let stamped = writingMark(article)
        articlesByID[stamped.id] = stamped
        try persist(stamped)
        pendingIDs.remove(stamped.id)
    }

    func note(_ article: Article) async {
        let stamped = writingMark(article)
        articlesByID[stamped.id] = stamped
        pendingIDs.insert(stamped.id)
        scheduleFlush()
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        try persistPending()
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        pendingIDs = []
        articlesByID = [:]
        settingsValue = .default
        warning = nil
        if fileManager.fileExists(atPath: articlesDirectory.path) {
            try fileManager.removeItem(at: articlesDirectory)
        }
        if fileManager.fileExists(atPath: settingsURL.path) {
            try fileManager.removeItem(at: settingsURL)
        }
        prepareArticlesDirectory()
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: PreferenceKey.demoSeed)
        defaults.removeObject(forKey: PreferenceKey.onboardingComplete)
    }

    func seedDemoIfNeeded() async throws {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        if defaults.object(forKey: PreferenceKey.demoSeed) == nil {
            for article in ArticleSeed.demoArticles() {
                let stamped = writingMark(article)
                articlesByID[stamped.id] = stamped
                try persist(stamped)
            }
            defaults.set(true, forKey: PreferenceKey.demoSeed)
        }
        defaults.set(true, forKey: PreferenceKey.onboardingComplete)
        #endif
    }

    func notch(articleID: UUID, at date: Date) async throws -> Article {
        guard let current = articlesByID[articleID] else {
            throw ArticleStoreError.unknownArticle
        }
        let updated: Article
        do {
            updated = try notching(current, at: date)
        } catch ArticleError.invalidShare {
            throw ArticleStoreError.invalidShare
        }
        try await save(updated)
        return updated
    }

    func settings() async -> NotchSettings {
        settingsValue
    }

    func saveSettings(_ settings: NotchSettings) async throws {
        settingsValue = settings
        try persistSettings()
    }

    func isOnboardingComplete() async -> Bool {
        preferenceDefaults().bool(forKey: PreferenceKey.onboardingComplete)
    }

    func setOnboardingComplete(_ flag: Bool) async {
        preferenceDefaults().set(flag, forKey: PreferenceKey.onboardingComplete)
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            try persistPending()
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persistPending() throws {
        let ids = pendingIDs
        pendingIDs = []
        for id in ids {
            if let article = articlesByID[id] {
                try persist(article)
                lastWriteError = nil
            }
        }
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func adopt(_ article: Article) {
        let stamped = writingMark(article)
        articlesByID[stamped.id] = stamped
        if stamped.mark != article.mark {
            try? persist(stamped)
        }
    }

    private func persist(_ article: Article) throws {
        prepareArticlesDirectory()
        let url = fileURL(for: article.id)
        let data = try ArticleCodec.encode(article)
        if fileManager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func persistSettings() throws {
        prepareSettingsDirectory()
        let data = try SettingsCodec.encode(settingsValue)
        try data.write(to: settingsURL, options: .atomic)
    }

    private func loadSettingsFromDisk() -> NotchSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? SettingsCodec.decode(data) else {
            return .default
        }
        return settings
    }

    private func decodeArticleFile(_ url: URL) -> Article? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? ArticleCodec.decode(data)
    }

    private func articleURLs() -> [URL] {
        let contents = try? fileManager.contentsOfDirectory(
            at: articlesDirectory,
            includingPropertiesForKeys: nil
        )
        return (contents ?? []).filter { url in
            url.pathExtension == "json" && !url.lastPathComponent.hasSuffix(".json.backup")
        }
    }

    private func fileURL(for id: UUID) -> URL {
        articlesDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    private func backupURL(for url: URL) -> URL {
        url.appendingPathExtension("backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareArticlesDirectory() {
        if !fileManager.fileExists(atPath: articlesDirectory.path) {
            try? fileManager.createDirectory(at: articlesDirectory, withIntermediateDirectories: true)
        }
    }

    private func prepareSettingsDirectory() {
        let parent = settingsURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parent.path) {
            try? fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        }
    }
}

/// Role: Article. Simulator-only demo shelf. Device never seeds.
enum ArticleSeed {
    static let gadgetID = uuid("11111111-1111-4111-8111-111111111111")
    static let toolID = uuid("22222222-2222-4222-8222-222222222222")
    static let kettleID = uuid("33333333-3333-4333-8333-333333333333")
    static let lampID = uuid("44444444-4444-4444-8444-444444444444")
    static let skilletID = uuid("55555555-5555-4555-8555-555555555555")
    static let blanketID = uuid("66666666-6666-4666-8666-666666666666")

    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    static func demoArticles() -> [Article] {
        let old = Date(timeIntervalSinceNow: -86400 * 14)
        return [
            markedGadget(acquiredAt: old),
            amortizingTool(acquiredAt: old),
            amortizingKettle(acquiredAt: old),
            amortizingLamp(acquiredAt: old),
            amortizingSkillet(acquiredAt: old),
            amortizingBlanket(acquiredAt: old),
        ]
    }

    private static func markedGadget(acquiredAt: Date) -> Article {
        var article = Article(
            id: gadgetID,
            name: "Camping lantern",
            purchasePrice: 80,
            shareMethod: .dividedByTargetUses,
            perNotchShare: 20,
            targetUses: 4,
            disposalValue: 5,
            acquiredAt: acquiredAt,
            notches: [
                NotchEntry(date: acquiredAt.addingTimeInterval(86400)),
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 3)),
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 5)),
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 7)),
            ]
        )
        article.mark = BreakevenMark(index: 3, date: article.notches[3].date)
        return article
    }

    private static func amortizingTool(acquiredAt: Date) -> Article {
        Article(
            id: toolID,
            name: "Hex driver set",
            purchasePrice: 24,
            shareMethod: .manualShare,
            perNotchShare: 3,
            disposalValue: 2,
            acquiredAt: acquiredAt,
            notches: [
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 2)),
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 4)),
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 9)),
            ]
        )
    }

    private static func amortizingKettle(acquiredAt: Date) -> Article {
        Article(
            id: kettleID,
            name: "Pour-over kettle",
            purchasePrice: 56,
            shareMethod: .dividedByTargetUses,
            perNotchShare: 7,
            targetUses: 8,
            acquiredAt: acquiredAt,
            notches: [
                NotchEntry(date: acquiredAt.addingTimeInterval(86400)),
            ]
        )
    }

    private static func amortizingLamp(acquiredAt: Date) -> Article {
        Article(
            id: lampID,
            name: "Desk lamp",
            purchasePrice: 45,
            shareMethod: .manualShare,
            perNotchShare: 5,
            disposalValue: 8,
            acquiredAt: acquiredAt,
            notches: [
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 2)),
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 6)),
            ]
        )
    }

    private static func amortizingSkillet(acquiredAt: Date) -> Article {
        writingMark(
            Article(
                id: skilletID,
                name: "Cast-iron skillet",
                purchasePrice: 48,
                shareMethod: .dividedByTargetUses,
                perNotchShare: 4,
                targetUses: 12,
                disposalValue: 4,
                acquiredAt: acquiredAt,
                notches: (1...12).map { day in
                    NotchEntry(date: acquiredAt.addingTimeInterval(86400 * Double(day)))
                }
            )
        )
    }

    private static func amortizingBlanket(acquiredAt: Date) -> Article {
        Article(
            id: blanketID,
            name: "Wool camp blanket",
            purchasePrice: 90,
            shareMethod: .manualShare,
            perNotchShare: 15,
            disposalValue: 5,
            acquiredAt: acquiredAt,
            notches: [
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 2)),
                NotchEntry(date: acquiredAt.addingTimeInterval(86400 * 8)),
            ]
        )
    }
}
