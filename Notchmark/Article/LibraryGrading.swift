import Foundation

/// Role: Article. Relative A+–F grade for the cost_per_use family library.
enum LibraryGrade: Equatable, Sendable {
    case letter(String)
    case insufficientData
}

/// Role: Article. Family invariant: cpu = (price−disposal)/max(uses,1). Grades are relative to peers.
enum LibraryGrading {
    static func costPerUse(price: Double, disposal: Double, uses: Int) -> Double {
        (price - disposal) / Double(max(uses, 1))
    }

    static func grade(
        for article: Article,
        among peers: [Article],
        now: Date,
        calendar: Calendar = .current
    ) -> LibraryGrade {
        let ageDays = calendar.dateComponents([.day], from: article.acquiredAt, to: now).day ?? 0
        guard ageDays >= 7 else { return .insufficientData }

        let eligiblePeers = peers.filter { peer in
            guard peer.id != article.id else { return false }
            let days = calendar.dateComponents([.day], from: peer.acquiredAt, to: now).day ?? 0
            return days >= 7
        }
        guard eligiblePeers.count >= 5 else { return .insufficientData }

        let articleCPU = costPerUse(
            price: article.purchasePrice,
            disposal: article.disposalValue,
            uses: article.notches.count
        )
        var cpus = eligiblePeers.map {
            costPerUse(price: $0.purchasePrice, disposal: $0.disposalValue, uses: $0.notches.count)
        }
        cpus.append(articleCPU)
        cpus.sort()
        guard let index = cpus.firstIndex(of: articleCPU) else { return .insufficientData }

        let spread = max(cpus.count - 1, 1)
        let efficiencyPercentile = Double(cpus.count - 1 - index) / Double(spread) * 100
        return .letter(letter(fromEfficiencyPercentile: efficiencyPercentile))
    }

    private static func letter(fromEfficiencyPercentile percentile: Double) -> String {
        switch percentile {
        case 97...: return "A+"
        case 93..<97: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 67..<70: return "D+"
        case 63..<67: return "D"
        case 60..<63: return "D-"
        default: return "F"
        }
    }
}
