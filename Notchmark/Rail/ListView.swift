import SwiftUI

/// Role: Rail. Named 3.6 List — accordion Article rows filling the rail edge to edge.
struct ListView: View {
    @ObservedObject var session: RailSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        List {
            Section {
                ForecastStrip(entries: session.forecastEntries())
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(LedgerPalette.background)
            }
            ForEach(session.articles) { article in
                RailRowView(
                    article: article,
                    currencyCode: session.settings.currencyCode,
                    grade: session.grade(for: article),
                    expanded: session.expandedArticleID == article.id,
                    onToggle: {
                        withAnimation(LedgerChrome.animation(reduceMotion: reduceMotion)) {
                            session.expandedArticleID = session.expandedArticleID == article.id ? nil : article.id
                        }
                    },
                    onCarve: {
                        Task { await session.notch(articleID: article.id) }
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(LedgerPalette.background)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, LedgerPalette.space(2))
    }
}
