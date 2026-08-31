import Foundation

/// Role: Mark. Derived phase. Never stored — produced only by folding notches.
enum NotchPhase: Equatable, Sendable {
    case amortizing(balance: Double)
    case breakeven(BreakevenMark)
    case profit(mark: BreakevenMark)
}

/// Role: Mark. Pure fold over an Article's notch array. Rail and Board read phase only through here.
enum AmortizationLedger {
    static func reduce(
        over notches: [NotchEntry],
        purchasePrice: Double,
        perNotchShare: Double,
        storedMark: BreakevenMark?
    ) -> NotchPhase {
        if let storedMark {
            if notches.count > storedMark.index {
                return .profit(mark: storedMark)
            }
        }

        var balance = purchasePrice
        for (index, notch) in notches.enumerated() {
            if let storedMark, index >= storedMark.index {
                return .profit(mark: storedMark)
            }
            balance -= perNotchShare
            if balance <= 0 {
                if let storedMark {
                    return .profit(mark: storedMark)
                }
                return .breakeven(BreakevenMark(index: index, date: notch.date))
            }
        }

        if let storedMark, notches.count > storedMark.index {
            return .profit(mark: storedMark)
        }
        return .amortizing(balance: max(0, balance))
    }
}
