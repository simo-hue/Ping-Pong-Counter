import Foundation

/// The rally-by-rally winners of one set, in the order they were played.
///
/// Encoded as a compact digit string (`"1211…"`) rather than an array of enum cases: a five-set
/// 21-point match holds roughly 200 rallies, and the natural JSON encoding would spend ~11 bytes
/// on each of them inside `UserDefaults`. One character per rally keeps a full season of history
/// in the low kilobytes.
struct RallyLog: Equatable, Codable {
    private(set) var winners: [Player]

    init(winners: [Player] = []) {
        self.winners = winners
    }

    var count: Int { winners.count }
    var isEmpty: Bool { winners.isEmpty }

    func points(for player: Player) -> Int {
        winners.reduce(0) { $1 == player ? $0 + 1 : $0 }
    }

    /// Whether this log actually accounts for the given score. The log can fall behind the score
    /// only when a match started on a build that did not record rallies and finished on one that
    /// does; archiving a mismatched log would draw a momentum chart that contradicts the printed
    /// set score, so callers drop it instead.
    func accountsFor(p1Points: Int, p2Points: Int) -> Bool {
        points(for: .player1) == p1Points && points(for: .player2) == p2Points
    }

    mutating func append(_ player: Player) {
        winners.append(player)
    }

    /// Removes the most recent rally won by `player`. A score correction says "that player should
    /// not have this point", which is not necessarily the last rally played — searching backwards
    /// keeps `points(for:)` in step with the displayed score.
    mutating func removeLastRally(wonBy player: Player) {
        guard let index = winners.lastIndex(of: player) else { return }
        winners.remove(at: index)
    }

    mutating func removeAll() {
        winners.removeAll()
    }

    /// Mirrors every rally when the players change ends.
    func swapped() -> RallyLog {
        RallyLog(winners: winners.map { $0.opponent })
    }

    /// Running point difference from player 1's perspective after each rally, starting at 0.
    /// Drives the momentum sparkline in the match detail view.
    var leadProgression: [Int] {
        var lead = 0
        var progression = [0]
        progression.reserveCapacity(winners.count + 1)
        for winner in winners {
            lead += winner == .player1 ? 1 : -1
            progression.append(lead)
        }
        return progression
    }

    // MARK: - Compact Codable representation

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        winners = raw.compactMap { character in
            switch character {
            case "1": return .player1
            case "2": return .player2
            default: return nil
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let raw = winners.map { $0 == .player1 ? "1" : "2" }.joined()
        try container.encode(raw)
    }
}

/// One set of a match: its final points, who took it, and how the rallies fell.
struct SetRecord: Identifiable, Equatable, Codable {
    let id: UUID
    /// 1-based position within the match.
    let index: Int
    let p1Points: Int
    let p2Points: Int
    /// `nil` when the match was abandoned before the set finished.
    let winner: Player?
    let rallies: RallyLog

    var scoreLine: String { "\(p1Points)-\(p2Points)" }
    var isComplete: Bool { winner != nil }

    func swapped() -> SetRecord {
        SetRecord(
            id: id,
            index: index,
            p1Points: p2Points,
            p2Points: p1Points,
            winner: winner?.opponent,
            rallies: rallies.swapped()
        )
    }
}
