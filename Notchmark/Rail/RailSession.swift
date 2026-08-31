import Foundation
import UIKit

/// Role: Rail. Single observable seam between ArticleStore and every screen.
@MainActor
final class RailSession: ObservableObject {
    @Published private(set) var articles: [Article] = []
    @Published private(set) var settings: NotchSettings = .default
    @Published private(set) var warning: ArticleStoreWarning?
    @Published private(set) var fault: String?
    @Published private(set) var isLoading = false
    @Published private(set) var onboardingComplete = false
    @Published private(set) var isReady = false
    @Published private(set) var dayStamp = Date()
    @Published var expandedArticleID: UUID?
    @Published var showBoard = false
    @Published var showSettings = false
    @Published var showAddArticle = false
    @Published var showInsights = false

    let store: any ArticleStoring
    private let now: () -> Date
    private let calendar: Calendar
    private var appeared = false
    private var reviewConsumed = false

    init(
        store: any ArticleStoring,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        articles: [Article] = [],
        settings: NotchSettings = .default,
        warning: ArticleStoreWarning? = nil,
        onboardingComplete: Bool = false,
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.articles = articles
        self.settings = settings
        self.warning = warning
        self.onboardingComplete = onboardingComplete
        self.shouldLoad = shouldLoad
        self.isReady = !shouldLoad
        self.dayStamp = calendar.startOfDay(for: now())
        if shouldLoad {
            Task { await appear() }
        }
    }

    private let shouldLoad: Bool

    func appear() async {
        guard shouldLoad else {
            isReady = true
            return
        }
        guard !appeared else { return }
        appeared = true
        await haul()
        isReady = true
    }

    func noteDayChange() {
        dayStamp = calendar.startOfDay(for: now())
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = "Articles could not be written to disk."
        }
    }

    func consumeReview(arguments: [String] = ProcessInfo.processInfo.arguments) -> RailReview? {
        RailLaunch.consume(
            arguments: arguments,
            onboardingComplete: onboardingComplete,
            consumed: &reviewConsumed
        )
    }

    func finishOnboarding(currencyCode: String, shareMethod: ShareMethod, skipped: Bool) async {
        if !skipped {
            var next = settings
            next.currencyCode = currencyCode
            next.defaultShareMethod = shareMethod
            do {
                try await store.saveSettings(next)
                settings = next
            } catch {
                fault = "Settings could not be saved."
            }
        }
        await store.setOnboardingComplete(true)
        onboardingComplete = true
        try? await store.seedDemoIfNeeded()
        await reloadArticles()
    }

    func reopenOnboarding() async {
        await store.setOnboardingComplete(false)
        onboardingComplete = false
    }

    func resetAll() async {
        await run {
            try await self.store.resetAllData()
            self.articles = []
            self.settings = .default
            self.warning = nil
            self.expandedArticleID = nil
            self.onboardingComplete = false
        }
    }

    func saveSettings(_ next: NotchSettings) async {
        await run {
            try await self.store.saveSettings(next)
            self.settings = next
        }
    }

    func addArticle(_ article: Article) async {
        await run {
            try await self.store.save(article)
            await self.reloadArticles()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func notch(articleID: UUID) async {
        await run {
            _ = try await self.store.notch(articleID: articleID, at: self.now())
            await self.reloadArticles()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func grade(for article: Article) -> LibraryGrade {
        _ = dayStamp
        return LibraryGrading.grade(for: article, among: articles, now: now(), calendar: calendar)
    }

    func rankedMarked() -> [Article] {
        ProfitPerNotchRanking.ranked(articles)
    }

    func forecastEntries() -> [MarkForecast.Entry] {
        MarkForecast.entries(for: articles)
    }

    func exportURL(for article: Article) -> URL? {
        let csv = CSVExporter.csv(for: article)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(article.name.replacingOccurrences(of: "/", with: "-")).csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            fault = "CSV export failed."
            return nil
        }
    }

    private func haul() async {
        fault = nil
        let spinner = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled {
                isLoading = true
            }
        }
        try? await store.seedDemoIfNeeded()
        let outcome = await store.load()
        articles = outcome.articles
        settings = outcome.settings
        warning = outcome.warning
        onboardingComplete = await store.isOnboardingComplete()
        if expandedArticleID == nil {
            expandedArticleID = articles.first?.id
        }
        spinner.cancel()
        isLoading = false
    }

    private func reloadArticles() async {
        let outcome = await store.load()
        articles = outcome.articles
        settings = outcome.settings
        if let warning = outcome.warning {
            self.warning = warning
        }
    }

    private func run(_ work: () async throws -> Void) async {
        do {
            try await work()
            fault = nil
        } catch {
            fault = String(describing: error)
        }
    }

    static func previewPopulated() -> RailSession {
        RailSession(
            store: PreviewStore(),
            articles: ArticleSeed.demoArticles(),
            settings: .default,
            onboardingComplete: true,
            shouldLoad: false
        )
    }

    static func live() -> RailSession {
        let urls: (articles: URL, settings: URL)
        if let built = try? ArticleStore.applicationSupportURLs() {
            urls = built
        } else {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("Notchmark", isDirectory: true)
            urls = (
                root.appendingPathComponent("Articles", isDirectory: true),
                root.appendingPathComponent(SettingsCodec.fileName)
            )
        }
        return RailSession(
            store: ArticleStore(
                articlesDirectory: urls.articles,
                settingsURL: urls.settings
            )
        )
    }
}

/// Role: Rail. In-memory store for SwiftUI previews only.
private actor PreviewStore: ArticleStoring {
    private var articles: [Article]
    private var settings: NotchSettings = .default
    private var onboarding = true

    init(articles: [Article] = ArticleSeed.demoArticles()) {
        self.articles = articles
    }

    func load() async -> (articles: [Article], settings: NotchSettings, warning: ArticleStoreWarning?) {
        (articles.sorted { $0.name < $1.name }, settings, nil)
    }

    func article(id: UUID) async -> Article? {
        articles.first { $0.id == id }
    }

    func save(_ article: Article) async throws {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index] = article
        } else {
            articles.append(article)
        }
    }

    func note(_ article: Article) async {}
    func flush() async throws {}
    func resetAllData() async throws { articles = [] }
    func seedDemoIfNeeded() async throws {}

    func notch(articleID: UUID, at date: Date) async throws -> Article {
        guard let index = articles.firstIndex(where: { $0.id == articleID }) else {
            throw ArticleStoreError.unknownArticle
        }
        let updated = try notching(articles[index], at: date)
        articles[index] = updated
        return updated
    }

    func settings() async -> NotchSettings { settings }

    func saveSettings(_ settings: NotchSettings) async throws {
        self.settings = settings
    }

    func isOnboardingComplete() async -> Bool { onboarding }

    func setOnboardingComplete(_ flag: Bool) async {
        onboarding = flag
    }
}
