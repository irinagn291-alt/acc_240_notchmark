import Foundation

/// Role: Article. How per-notch share is derived when an Article is opened.
enum ShareMethod: String, Sendable, Codable, Hashable {
    case manualShare
    case dividedByTargetUses
}
