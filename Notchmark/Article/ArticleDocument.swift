import Foundation

/// Role: Article. On-disk envelope for one aggregate. Domain types never decode this directly.
struct ArticleDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var id: UUID
    var name: String
    var purchasePrice: Double
    var shareMethod: ShareMethod
    var perNotchShare: Double
    var targetUses: Int?
    var disposalValue: Double
    var acquiredAtUnixMilliseconds: Int64
    var notches: [NotchEntryDocument]
    var mark: BreakevenMarkDocument?
}

/// Role: Article. Notch projection for JSON.
struct NotchEntryDocument: Codable, Equatable, Sendable {
    var id: UUID
    var dateUnixMilliseconds: Int64
}

/// Role: Article. Mark projection for JSON.
struct BreakevenMarkDocument: Codable, Equatable, Sendable {
    var index: Int
    var dateUnixMilliseconds: Int64
}

/// Role: Article. schemaVersion switch and Article ↔ document mapping. No FileManager.
enum ArticleCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func document(from article: Article) -> ArticleDocument {
        ArticleDocument(
            schemaVersion: currentSchema,
            id: article.id,
            name: article.name,
            purchasePrice: article.purchasePrice,
            shareMethod: article.shareMethod,
            perNotchShare: article.perNotchShare,
            targetUses: article.targetUses,
            disposalValue: article.disposalValue,
            acquiredAtUnixMilliseconds: unixMilliseconds(from: article.acquiredAt),
            notches: article.notches.map(notchDocument(from:)),
            mark: article.mark.map(markDocument(from:))
        )
    }

    static func article(from document: ArticleDocument) -> Article {
        Article(
            id: document.id,
            name: document.name,
            purchasePrice: document.purchasePrice,
            shareMethod: document.shareMethod,
            perNotchShare: document.perNotchShare,
            targetUses: document.targetUses,
            disposalValue: document.disposalValue,
            acquiredAt: date(fromUnixMilliseconds: document.acquiredAtUnixMilliseconds),
            notches: document.notches.map(notch(from:)),
            mark: document.mark.map(mark(from:))
        )
    }

    static func encode(_ article: Article) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: article))
    }

    static func decode(_ data: Data) throws -> Article {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return article(from: try decoder.decode(ArticleDocument.self, from: data))
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    private static func notchDocument(from entry: NotchEntry) -> NotchEntryDocument {
        NotchEntryDocument(id: entry.id, dateUnixMilliseconds: unixMilliseconds(from: entry.date))
    }

    private static func notch(from document: NotchEntryDocument) -> NotchEntry {
        NotchEntry(id: document.id, date: date(fromUnixMilliseconds: document.dateUnixMilliseconds))
    }

    private static func markDocument(from mark: BreakevenMark) -> BreakevenMarkDocument {
        BreakevenMarkDocument(index: mark.index, dateUnixMilliseconds: unixMilliseconds(from: mark.date))
    }

    private static func mark(from document: BreakevenMarkDocument) -> BreakevenMark {
        BreakevenMark(index: document.index, date: date(fromUnixMilliseconds: document.dateUnixMilliseconds))
    }

    private static func unixMilliseconds(from date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    private static func date(fromUnixMilliseconds value: Int64) -> Date {
        Date(timeIntervalSince1970: Double(value) / 1000)
    }
}

/// Role: Article. Settings envelope stored as Settings.json beside the Articles folder.
struct NotchSettings: Equatable, Sendable {
    var currencyCode: String
    var defaultShareMethod: ShareMethod

    static let `default` = NotchSettings(currencyCode: "USD", defaultShareMethod: .dividedByTargetUses)
}

struct NotchSettingsDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var currencyCode: String
    var defaultShareMethod: ShareMethod
}

/// Role: Article. Settings codec. No FileManager.
enum SettingsCodec {
    static let currentSchema = 1
    static let fileName = "Settings.json"

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func document(from settings: NotchSettings) -> NotchSettingsDocument {
        NotchSettingsDocument(
            schemaVersion: currentSchema,
            currencyCode: settings.currencyCode,
            defaultShareMethod: settings.defaultShareMethod
        )
    }

    static func settings(from document: NotchSettingsDocument) -> NotchSettings {
        NotchSettings(
            currencyCode: document.currencyCode,
            defaultShareMethod: document.defaultShareMethod
        )
    }

    static func encode(_ settings: NotchSettings) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: settings))
    }

    static func decode(_ data: Data) throws -> NotchSettings {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return settings(from: try decoder.decode(NotchSettingsDocument.self, from: data))
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
