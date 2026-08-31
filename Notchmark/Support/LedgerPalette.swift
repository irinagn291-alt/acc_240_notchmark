import SwiftUI
import UIKit

/// Role: Support. Actuary's desk tokens. Hex literals exist only here for catalog verification.
enum LedgerPalette {
    static let backgroundHex = "#F6F1E3"
    static let surfaceHex = "#ECE3CB"
    static let inkHex = "#241C12"
    static let accentHex = "#A32E2A"
    static let mutedHex = "#8B7A55"

    static let background = Color("background")
    static let surface = Color("surface")
    static let ink = Color("ink")
    static let accent = Color("accent")
    static let muted = Color("muted")

    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let radius: CGFloat = 0

    static var backgroundUI: UIColor { named("background", red: 246, green: 241, blue: 227) }
    static var surfaceUI: UIColor { named("surface", red: 236, green: 227, blue: 203) }
    static var inkUI: UIColor { named("ink", red: 36, green: 28, blue: 18) }
    static var accentUI: UIColor { named("accent", red: 163, green: 46, blue: 42) }
    static var mutedUI: UIColor { named("muted", red: 139, green: 122, blue: 85) }

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    private static func named(_ name: String, red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(named: name) ?? UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
