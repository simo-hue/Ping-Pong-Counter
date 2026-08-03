import Foundation

/// A saved competitor.
///
/// Distinct from `Player`, which names a *side* of the table (player1 / player2). A `RosterPlayer`
/// is a person who can sit on either side across many matches, which is what makes per-player and
/// head-to-head records possible.
struct RosterPlayer: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, emoji: String = RosterPlayer.defaultEmoji, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.createdAt = createdAt
    }

    static let defaultEmoji = "🏓"
    static let emojiChoices = ["🏓", "🔥", "⚡️", "🐉", "🦈", "🐅", "🦅", "🎯", "💎", "🚀", "🥷", "🤖", "👑", "🍀", "🌶️", "🧊"]

    /// Comparison key for linking a match record to a roster entry when the record predates
    /// roster IDs. Case- and whitespace-insensitive so "simo" and " Simo " are the same person.
    var matchKey: String { RosterPlayer.matchKey(for: name) }

    static func matchKey(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

// MARK: - Linking match records to roster entries

extension MatchRecord {
    /// The side this roster player occupied, or nil if they were not in this match.
    ///
    /// Prefers the stored roster ID and falls back to the name, so matches recorded before the
    /// roster existed still count towards a player's record.
    func side(of player: RosterPlayer) -> Player? {
        if let p1Id, p1Id == player.id { return .player1 }
        if let p2Id, p2Id == player.id { return .player2 }

        // Only fall back to names on the sides that carry no ID — otherwise a record explicitly
        // linked to somebody else could be claimed by a namesake.
        if p1Id == nil, RosterPlayer.matchKey(for: p1Name) == player.matchKey { return .player1 }
        if p2Id == nil, RosterPlayer.matchKey(for: p2Name) == player.matchKey { return .player2 }

        return nil
    }

    func involves(_ player: RosterPlayer) -> Bool {
        side(of: player) != nil
    }

    func points(for side: Player) -> Int {
        guard let sets, !sets.isEmpty else {
            // Legacy record: only the final set's points were ever stored.
            return side == .player1 ? p1Score : p2Score
        }
        return sets.reduce(0) { $0 + (side == .player1 ? $1.p1Points : $1.p2Points) }
    }

    func sets(for side: Player) -> Int {
        side == .player1 ? p1Sets : p2Sets
    }
}

// MARK: - Aggregated statistics

struct PlayerStats: Equatable {
    var matchesPlayed = 0
    var matchesWon = 0
    var matchesLost = 0
    /// Matches abandoned before a winner was decided — counted as played, never as won or lost.
    var matchesUnfinished = 0
    var setsWon = 0
    var setsLost = 0
    var pointsWon = 0
    var pointsLost = 0
    /// Positive for a run of wins, negative for a run of losses, zero when there is no run.
    var currentStreak = 0
    var bestWinStreak = 0

    var decidedMatches: Int { matchesWon + matchesLost }

    var winRate: Double {
        guard decidedMatches > 0 else { return 0 }
        return Double(matchesWon) / Double(decidedMatches)
    }

    var winRatePercentText: String {
        guard decidedMatches > 0 else { return "–" }
        return "\(Int((winRate * 100).rounded()))%"
    }
}

struct HeadToHeadRecord: Identifiable, Equatable {
    let opponent: RosterPlayer
    var wins = 0
    var losses = 0
    var setsWon = 0
    var setsLost = 0

    var id: UUID { opponent.id }
    var decidedMatches: Int { wins + losses }

    var summary: String { "\(wins) - \(losses)" }
}

enum MatchStatistics {
    static func stats(for player: RosterPlayer, in records: [MatchRecord]) -> PlayerStats {
        var stats = PlayerStats()

        for record in records {
            guard let side = record.side(of: player) else { continue }

            stats.matchesPlayed += 1
            stats.setsWon += record.sets(for: side)
            stats.setsLost += record.sets(for: side.opponent)
            stats.pointsWon += record.points(for: side)
            stats.pointsLost += record.points(for: side.opponent)

            if let winner = record.winner {
                if winner == side {
                    stats.matchesWon += 1
                } else {
                    stats.matchesLost += 1
                }
            } else {
                stats.matchesUnfinished += 1
            }
        }

        let outcomes = decidedOutcomes(for: player, in: records)
        stats.currentStreak = currentStreak(in: outcomes)
        stats.bestWinStreak = bestWinStreak(in: outcomes)

        return stats
    }

    static func headToHead(for player: RosterPlayer, in records: [MatchRecord], roster: [RosterPlayer]) -> [HeadToHeadRecord] {
        var byOpponent: [UUID: HeadToHeadRecord] = [:]

        for record in records {
            guard let side = record.side(of: player) else { continue }

            // Only opponents saved in the roster can be aggregated — a one-off name typed on the
            // scoreboard has no stable identity to accumulate a head-to-head against.
            let opponentSide = side.opponent
            guard let opponent = roster.first(where: { $0.id != player.id && record.side(of: $0) == opponentSide }) else {
                continue
            }

            var entry = byOpponent[opponent.id] ?? HeadToHeadRecord(opponent: opponent)
            entry.setsWon += record.sets(for: side)
            entry.setsLost += record.sets(for: opponentSide)

            if let winner = record.winner {
                if winner == side {
                    entry.wins += 1
                } else {
                    entry.losses += 1
                }
            }

            byOpponent[opponent.id] = entry
        }

        return byOpponent.values.sorted {
            if $0.decidedMatches != $1.decidedMatches { return $0.decidedMatches > $1.decidedMatches }
            return $0.opponent.name.localizedCaseInsensitiveCompare($1.opponent.name) == .orderedAscending
        }
    }

    /// Won/lost flags for decided matches, most recent first (matching the stored record order).
    private static func decidedOutcomes(for player: RosterPlayer, in records: [MatchRecord]) -> [Bool] {
        records.compactMap { record in
            guard let side = record.side(of: player), let winner = record.winner else { return nil }
            return winner == side
        }
    }

    private static func currentStreak(in outcomes: [Bool]) -> Int {
        guard let mostRecent = outcomes.first else { return 0 }

        let length = outcomes.prefix { $0 == mostRecent }.count
        return mostRecent ? length : -length
    }

    private static func bestWinStreak(in outcomes: [Bool]) -> Int {
        var best = 0
        var current = 0

        for outcome in outcomes {
            if outcome {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }

        return best
    }
}
