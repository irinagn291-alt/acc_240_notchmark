import Foundation

/// Role: Notch. One immutable use logged against an Article. Append-only in persistence.
struct NotchEntry: Identifiable, Equatable, Sendable, Codable, Hashable {
    var id: UUID
    var date: Date

    init(id: UUID = UUID(), date: Date) {
        self.id = id
        self.date = date
    }
}
