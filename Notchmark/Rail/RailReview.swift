import Foundation

/// Role: Rail. ReviewScreen today|log|goals. Read once, only after onboarding.
enum RailReview: String, Equatable, Sendable {
    case today
    case log
    case goals
}

enum RailLaunch {
    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> RailReview? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return RailReview(rawValue: arguments[next])
    }

    static func bind(_ review: RailReview, board: inout Bool, settings: inout Bool) {
        switch review {
        case .today:
            board = false
            settings = false
        case .log:
            board = true
            settings = false
        case .goals:
            board = false
            settings = true
        }
    }
}
