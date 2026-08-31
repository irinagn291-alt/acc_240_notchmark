import Foundation

/// Role: Settings. Share-sheet CSV for one Article's notch history.
enum CSVExporter {
    static func csv(for article: Article) -> String {
        var lines = ["article,name,notch_index,date_iso,per_notch_share,phase"]
        let phase = LedgerChrome.phaseLabel(mark: article.mark)
        if article.notches.isEmpty {
            lines.append("\(article.id.uuidString),\(escaped(article.name)),,,,\(phase)")
        } else {
            for (index, notch) in article.notches.enumerated() {
                let iso = ISO8601DateFormatter().string(from: notch.date)
                lines.append("\(article.id.uuidString),\(escaped(article.name)),\(index),\(iso),\(article.perNotchShare),\(phase)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func escaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
