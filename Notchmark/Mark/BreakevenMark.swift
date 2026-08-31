import Foundation

/// Role: Mark. Immutable breakeven stamp written once when balance crosses zero.
struct BreakevenMark: Equatable, Sendable, Codable, Hashable {
    var index: Int
    var date: Date
}
