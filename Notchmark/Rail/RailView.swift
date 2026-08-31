import SwiftUI

/// Role: Rail. Root library screen. Accordion rows, toolbar sheets, no navigation stack.
struct RailView: View {
    @ObservedObject var session: RailSession
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase

    init(session: RailSession, handlesLaunch: Bool = true) {
        self.session = session
        self.handlesLaunch = handlesLaunch
    }

    init() {
        self.init(session: .previewPopulated(), handlesLaunch: false)
    }

    var body: some View {
        Group {
            if handlesLaunch, !session.isReady {
                boot
            } else if handlesLaunch, !session.onboardingComplete {
                OnboardingView { currency, method, skipped in
                    Task { await session.finishOnboarding(currencyCode: currency, shareMethod: method, skipped: skipped) }
                }
            } else if session.showBoard {
                BoardView(session: session) { session.showBoard = false }
            } else if session.showSettings {
                SettingsView(
                    session: session,
                    onClose: { session.showSettings = false },
                    onRerun: {
                        session.showSettings = false
                        Task { await session.reopenOnboarding() }
                    }
                )
            } else {
                library
            }
        }
        .background(LedgerPalette.background.ignoresSafeArea())
        .preferredColorScheme(.light)
        .task {
            guard handlesLaunch else { return }
            await session.appear()
            applyReview()
        }
        .onChange(of: session.onboardingComplete) { _, done in
            guard handlesLaunch, done else { return }
            applyReview()
        }
        .onChange(of: scenePhase, initial: false) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { await session.flush() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            session.noteDayChange()
        }
        .sheet(isPresented: $session.showAddArticle) {
            AddArticleSheet(session: session) { session.showAddArticle = false }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(LedgerPalette.background)
        }
    }

    private var boot: some View {
        LedgerLaunchFill()
    }

    private var library: some View {
        VStack(spacing: 0) {
            header
            if session.isLoading {
                ProgressView()
                    .tint(LedgerPalette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let fault = session.fault, session.articles.isEmpty {
                LedgerVacancy(
                    image: "ntm_EmptyHome",
                    headline: "The library could not be read.",
                    line: fault,
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await session.retry() }
                }
            } else if session.articles.isEmpty {
                LedgerVacancy(
                    image: "ntm_EmptyHome",
                    headline: "The library is empty.",
                    line: "Add a thing you own.",
                    actionTitle: "Add Article"
                ) {
                    session.showAddArticle = true
                }
            } else {
                ListView(session: session)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            headerDecor
            HStack(spacing: LedgerPalette.space(1)) {
                Text("Notchmark")
                    .font(.ledger(.heading))
                    .foregroundStyle(LedgerPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: LedgerPalette.space(1))
                toolbarButton(title: "Ledger", systemImage: "book.closed") {
                    session.showBoard = true
                }
                toolbarButton(title: "Settings", systemImage: "gearshape") {
                    session.showSettings = true
                }
                toolbarButton(title: "Add Article", systemImage: "plus") {
                    session.showAddArticle = true
                }
            }
            .padding(.horizontal, LedgerPalette.space(2))
            .padding(.vertical, LedgerPalette.space(1))
            twistSurface
        }
        .background(LedgerPalette.surface)
    }

    private var headerDecor: some View {
        GeometryReader { proxy in
            let nativeHeight = proxy.size.width * 600 / 1200
            Image("ntm_HeaderDecor")
                .resizable()
                .frame(width: proxy.size.width, height: nativeHeight)
                .offset(y: -nativeHeight * 47 / 600)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                .clipped()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .clipped()
        .accessibilityHidden(true)
    }

    private var twistSurface: some View {
        HStack(spacing: LedgerPalette.space(1)) {
            Image("ntm_MarkStamp")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
                Text("Notch-to-breakeven ledger")
                    .font(.ledger(.body))
                    .foregroundStyle(LedgerPalette.ink)
                Text("Amortizing Articles never rank until they write a Mark.")
                    .font(.ledger(.footnote))
                    .foregroundStyle(LedgerPalette.ink)
                    .lineLimit(2)
            }
            Spacer(minLength: LedgerPalette.space(1))
        }
        .padding(.horizontal, LedgerPalette.space(2))
        .padding(.vertical, LedgerPalette.space(1))
        .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func toolbarButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
                .frame(width: LedgerPalette.tap, height: LedgerPalette.tap)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func applyReview() {
        guard let review = session.consumeReview() else { return }
        RailLaunch.bind(review, board: &session.showBoard, settings: &session.showSettings)
    }
}
