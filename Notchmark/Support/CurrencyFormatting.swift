import Foundation

/// Role: Support. Locale-aware money display. Never interpolate numbers by hand.
enum CurrencyFormatting {
    static func string(_ value: Double, code: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func decimalString(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func integer(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func parseDecimal(_ raw: String, locale: Locale = .current) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.isLenient = true
        guard let number = formatter.number(from: trimmed) else { return nil }
        let value = number.doubleValue
        guard value.isFinite, value >= 0 else { return nil }
        return value
    }

    static func parseInteger(_ raw: String, locale: Locale = .current) -> Int? {
        guard let value = parseDecimal(raw, locale: locale) else { return nil }
        let rounded = value.rounded()
        guard abs(value - rounded) < 0.000_001 else { return nil }
        return Int(rounded)
    }
}
