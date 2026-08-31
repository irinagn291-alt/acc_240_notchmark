import SwiftUI

/// Role: Support. Shared sheet chrome, empty pages, and phase labels for Rail and Board.
enum LedgerChrome {
    static let motionDuration = 0.28

    static func phaseLabel(mark: BreakevenMark?) -> String {
        mark == nil ? "Amortizing" : "Profit"
    }

    static func gradeLabel(_ grade: LibraryGrade) -> String {
        switch grade {
        case .letter(let letter):
            return letter
        case .insufficientData:
            return "—"
        }
    }

    static func animation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: motionDuration)
    }
}

struct LedgerLaunchFill: View {
    var body: some View {
        ZStack {
            LedgerPalette.background.ignoresSafeArea()
            Image("ntm_Splash")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.light)
        .accessibilityHidden(true)
    }
}

struct LedgerSheetBar: View {
    let title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: LedgerPalette.space(1)) {
            Text(title)
                .font(.ledger(.heading))
                .foregroundStyle(LedgerPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: LedgerPalette.space(1))
            Button(action: onClose) {
                Text("Close")
                    .font(.ledger(.body))
                    .foregroundStyle(LedgerPalette.accent)
                    .frame(minWidth: LedgerPalette.tap, minHeight: LedgerPalette.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

struct LedgerVacancy: View {
    let image: String
    let headline: String
    let line: String
    let actionTitle: String
    var retry = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: LedgerPalette.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .accessibilityHidden(true)
            Text(headline)
                .font(.ledger(.articleTitle))
                .foregroundStyle(LedgerPalette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer(minLength: LedgerPalette.space(2))
            Button(action: action) {
                Text(actionTitle)
                    .font(.ledger(.body))
                    .foregroundStyle(LedgerPalette.background)
                    .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
                    .background(LedgerPalette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(LedgerPalette.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
