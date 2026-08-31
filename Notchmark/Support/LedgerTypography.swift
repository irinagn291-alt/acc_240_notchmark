import SwiftUI
import UIKit

/// Role: Support. American Typewriter scale. No other font family is referenced in the app.
extension Font {
    enum LedgerStep {
        case heading
        case articleTitle
        case stampNumeral
        case body
        case footnote
    }

    static func ledger(_ step: LedgerStep) -> Font {
        switch step {
        case .heading:
            return .custom("American Typewriter", size: 28, relativeTo: .largeTitle).weight(.semibold)
        case .articleTitle:
            return .custom("American Typewriter", size: 20, relativeTo: .title3)
        case .stampNumeral:
            return .custom("American Typewriter", size: 17, relativeTo: .body).monospacedDigit()
        case .body:
            return .custom("American Typewriter", size: 15, relativeTo: .body)
        case .footnote:
            return .custom("American Typewriter", size: 12, relativeTo: .footnote)
        }
    }
}

enum LedgerTypeface {
    static func uiFont(_ step: Font.LedgerStep) -> UIFont? {
        let size: CGFloat
        let textStyle: UIFont.TextStyle
        switch step {
        case .heading:
            size = 28
            textStyle = .largeTitle
        case .articleTitle:
            size = 20
            textStyle = .title3
        case .stampNumeral:
            size = 17
            textStyle = .body
        case .body:
            size = 15
            textStyle = .body
        case .footnote:
            size = 12
            textStyle = .footnote
        }
        guard let base = UIFont(name: "American Typewriter", size: size) else { return nil }
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }
}
