import Foundation

/// Match count for one calendar day. Days with no play are included with `matches == 0` so the
/// activity chart shows real gaps instead of silently compressing time.
struct DailyActivity: Identifiable, Equatable {
    let day: Date
    let matches: Int

    var id: Date { day }
}

/// A roster player's line in the leaderboard.
struct LeaderboardEntry: Identifiable, Equatable {
    let player: RosterPlayer
    let stats: PlayerStats

    var id: UUID { player.id }
}

/// How often matches finished with a given set score, e.g. "2-0" three times.
struct SetScoreTally: Identifiable, Equatable {
    let label: String
    let count: Int

    var id: String { label }
}

/// Whole-history totals for the headline tiles.
struct OverallTotals: Equatable {
    var matches = 0
    var completed = 0
    var rallies = 0
    var playSeconds = 0
    var longestMatchSeconds = 0

    var averageSeconds: Int {
        let timed = timedMatches
        guard timed > 0 else { return 0 }
        return playSeconds / timed
    }

    /// Matches that actually carry a duration — records from before the clock existed do not,
    /// and averaging over all matches would drag the figure down with zeros.
    var timedMatches = 0
}

extension MatchStatistics {
    static func overallTotals(in records: [MatchRecord]) -> OverallTotals {
        var totals = OverallTotals()

        for record in records {
            totals.matches += 1
            if record.winner != nil { totals.completed += 1 }
            totals.rallies += record.totalRallies

            if let seconds = record.durationSeconds, seconds > 0 {
                totals.playSeconds += seconds
                totals.timedMatches += 1
                totals.longestMatchSeconds = max(totals.longestMatchSeconds, seconds)
            }
        }

        return totals
    }

    /// Roster players who have actually played, best record first.
    static func leaderboard(roster: [RosterPlayer], records: [MatchRecord]) -> [LeaderboardEntry] {
        roster
            .map { LeaderboardEntry(player: $0, stats: stats(for: $0, in: records)) }
            .filter { $0.stats.matchesPlayed > 0 }
            .sorted {
                if $0.stats.winRate != $1.stats.winRate { return $0.stats.winRate > $1.stats.winRate }
                if $0.stats.matchesWon != $1.stats.matchesWon { return $0.stats.matchesWon > $1.stats.matchesWon }
                return $0.player.name.localizedCaseInsensitiveCompare($1.player.name) == .orderedAscending
            }
    }

    /// Matches per day over the trailing `days` window, oldest first, gaps included.
    static func activity(
        in records: [MatchRecord],
        days: Int,
        endingOn endDate: Date,
        calendar: Calendar = .current
    ) -> [DailyActivity] {
        guard days > 0 else { return [] }

        let lastDay = calendar.startOfDay(for: endDate)
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: lastDay),
              let windowEnd = calendar.date(byAdding: .day, value: 1, to: lastDay) else { return [] }

        var counts: [Date: Int] = [:]

        for record in records {
            // Reject on a plain timestamp comparison first: most of a long history falls outside
            // the window, and the calendar arithmetic is far more expensive than the test.
            guard record.date >= windowStart, record.date < windowEnd else { continue }
            counts[calendar.startOfDay(for: record.date), default: 0] += 1
        }

        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: lastDay) else { return nil }
            return DailyActivity(day: day, matches: counts[day] ?? 0)
        }
    }

    /// Distribution of final set scores across decided matches, written from the winner's side
    /// ("2-0" rather than "0-2") so both orientations of the same result group together.
    static func setScoreDistribution(in records: [MatchRecord]) -> [SetScoreTally] {
        var counts: [String: Int] = [:]

        for record in records where record.winner != nil {
            let high = max(record.p1Sets, record.p2Sets)
            let low = min(record.p1Sets, record.p2Sets)
            counts["\(high)-\(low)", default: 0] += 1
        }

        return counts
            .map { SetScoreTally(label: $0.key, count: $0.value) }
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return $0.label < $1.label
            }
    }
}
