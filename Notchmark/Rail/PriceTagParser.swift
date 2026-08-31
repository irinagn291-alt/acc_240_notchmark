import Foundation

/// Role: Rail. Parse printed prices from scanned receipt text.
enum PriceTagParser {
    static func extractPrice(from text: String) -> Double? {
        let pattern = #"\$?\s*(\d+(?:[.,]\d{2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex ..< text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let capture = Range(match.range(at: 1), in: text) else { return nil }
        let raw = text[capture].replacingOccurrences(of: ",", with: ".")
        return Double(raw)
    }
}
