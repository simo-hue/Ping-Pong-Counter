import Foundation

/// One side of the table. `Identifiable` so a side can drive a `sheet(item:)` presentation.
enum Player: String, Codable, Identifiable {
    case player1
    case player2

    var id: String { rawValue }

    var opponent: Player {
        self == .player1 ? .player2 : .player1
    }
}

/// An archived match.
///
/// Every field added after the 1.0.1 release is Optional on purpose: Swift's synthesised
/// `Decodable` fails on a missing key for a non-optional property, and one such failure would
/// throw away the user's entire saved history rather than just the new column.
struct MatchRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let p1Name: String
    let p2Name: String
    let p1Score: Int
    let p2Score: Int
    let p1Sets: Int
    let p2Sets: Int
    let winner: Player?
    let targetScore: Int
    let bestOfSets: Int
    let winByTwo: Bool
    let durationSeconds: Int?
    /// Set-by-set breakdown with the rally log for each.
    let sets: [SetRecord]?
    /// Roster identities of the two sides, when the names came from saved players. Also nil when
    /// a name was typed freehand on the scoreboard.
    let p1Id: UUID?
    let p2Id: UUID?

    var formattedDuration: String? {
        guard let durationSeconds, durationSeconds > 0 else { return nil }
        return MatchClock.formatted(TimeInterval(durationSeconds))
    }

    /// "11-9 · 8-11 · 11-6", or nil for records predating set tracking.
    var setScoreLine: String? {
        guard let sets, !sets.isEmpty else { return nil }
        return sets.map(\.scoreLine).joined(separator: " · ")
    }

    var totalRallies: Int {
        (sets ?? []).reduce(0) { $0 + $1.rallies.count }
    }
}
