import SwiftUI
import UIKit

/// Role: Settings. Currency, defaults, CSV export, onboarding, reset, contact.
struct SettingsView: View {
    @ObservedObject var session: RailSession
    var onClose: () -> Void
    var onRerun: () -> Void

    @State private var currencyCode: String = "USD"
    @State private var shareMethod: ShareMethod = .dividedByTargetUses
    @State private var showResetConfirm = false
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var isSaving = false

    private let contactURL = URL(string: "https://travelhel-per.pro/contact-us")!

    init(
        session: RailSession,
        onClose: @escaping () -> Void = {},
        onRerun: @escaping () -> Void = {}
    ) {
        self.session = session
        self.onClose = onClose
        self.onRerun = onRerun
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
            LedgerSheetBar(title: "Settings", onClose: onClose)
            if let fault = session.fault, session.articles.isEmpty {
                LedgerVacancy(
                    image: "ntm_EmptyList",
                    headline: "Settings could not load.",
                    line: fault,
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await session.retry() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
                        Text("Articles stay on this device. A notch pays down the price; a Mark unlocks the Ledger ranking.")
                            .font(.ledger(.body))
                            .foregroundStyle(LedgerPalette.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(LedgerPalette.space(2))
                            .background(LedgerPalette.surface)

                        Text("Defaults")
                            .font(.ledger(.articleTitle))
                            .foregroundStyle(LedgerPalette.ink)
                        Picker("Currency", selection: $currencyCode) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                        }
                        .pickerStyle(.segmented)
                        .frame(minHeight: LedgerPalette.tap)
                        Picker("Default share method", selection: $shareMethod) {
                            Text("Price ÷ uses").tag(ShareMethod.dividedByTargetUses)
                            Text("Manual share").tag(ShareMethod.manualShare)
                        }
                        .pickerStyle(.segmented)
                        .frame(minHeight: LedgerPalette.tap)
                        Button(isSaving ? "Saving…" : "Save defaults") {
                            saveDefaults()
                        }
                        .font(.ledger(.body))
                        .foregroundStyle(LedgerPalette.background)
                        .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
                        .background(LedgerPalette.accent)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .disabled(isSaving)

                        Text("Export notch history")
                            .font(.ledger(.articleTitle))
                            .foregroundStyle(LedgerPalette.ink)
                        if session.articles.isEmpty {
                            Text("No Articles to export.")
                                .font(.ledger(.footnote))
                                .foregroundStyle(LedgerPalette.ink)
                                .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap, alignment: .leading)
                                .padding(.horizontal, LedgerPalette.space(1))
                                .background(LedgerPalette.surface)
                        } else {
                            ForEach(session.articles) { article in
                                Button {
                                    exportURL = session.exportURL(for: article)
                                    showShare = exportURL != nil
                                } label: {
                                    HStack {
                                        Text(article.name)
                                            .font(.ledger(.body))
                                            .foregroundStyle(LedgerPalette.ink)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer(minLength: LedgerPalette.space(1))
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundStyle(LedgerPalette.ink)
                                            .accessibilityHidden(true)
                                    }
                                    .padding(.horizontal, LedgerPalette.space(1))
                                    .frame(minHeight: LedgerPalette.tap)
                                    .frame(maxWidth: .infinity)
                                    .background(LedgerPalette.surface)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Export \(article.name)")
                            }
                        }

                        Link(destination: contactURL) {
                            VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
                                Text("Contact us")
                                    .font(.ledger(.body))
                                    .foregroundStyle(LedgerPalette.accent)
                                Text("https://travelhel-per.pro/contact-us")
                                    .font(.ledger(.footnote))
                                    .foregroundStyle(LedgerPalette.ink)
                            }
                            .padding(LedgerPalette.space(2))
                            .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap, alignment: .leading)
                            .background(LedgerPalette.surface)
                            .contentShape(Rectangle())
                        }

                        settingsRow("Re-run onboarding", action: onRerun)
                        settingsRow("Reset all data", role: .destructive) {
                            showResetConfirm = true
                        }
                    }
                }
                .contentMargins(.bottom, LedgerPalette.space(2))
            }
        }
        .padding(LedgerPalette.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(LedgerPalette.background.ignoresSafeArea())
        .onAppear {
            currencyCode = session.settings.currencyCode
            shareMethod = session.settings.defaultShareMethod
        }
        .confirmationDialog(
            "Reset all Articles and settings?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset everything", role: .destructive) {
                Task { await session.resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showShare) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
    }

    private func saveDefaults() {
        isSaving = true
        var next = session.settings
        next.currencyCode = currencyCode
        next.defaultShareMethod = shareMethod
        Task {
            await session.saveSettings(next)
            isSaving = false
        }
    }

    private func settingsRow(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Text(title)
                .font(.ledger(.body))
                .foregroundStyle(role == .destructive ? LedgerPalette.accent : LedgerPalette.ink)
                .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap, alignment: .leading)
                .padding(.horizontal, LedgerPalette.space(1))
                .background(LedgerPalette.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
