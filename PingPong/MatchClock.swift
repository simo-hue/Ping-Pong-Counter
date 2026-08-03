import Foundation

/// Wall-clock stopwatch for a single match.
///
/// The clock is a plain value type driven entirely by the two dates it stores, so it survives a
/// process restart by persisting those dates rather than an accumulated counter — an app killed
/// mid-match resumes with the real elapsed time instead of a frozen one.
struct MatchClock: Equatable, Codable {
    private(set) var startDate: Date?
    private(set) var endDate: Date?

    var hasStarted: Bool { startDate != nil }
    var isRunning: Bool { startDate != nil && endDate == nil }

    /// Begins timing on the first scoring event of a match. Repeat calls are ignored so the
    /// clock reflects the whole match rather than the latest rally.
    mutating func startIfNeeded(now: Date = Date()) {
        guard startDate == nil else { return }
        startDate = now
        endDate = nil
    }

    /// Freezes the clock when a winner is decided.
    mutating func stop(now: Date = Date()) {
        guard startDate != nil, endDate == nil else { return }
        endDate = now
    }

    /// Un-freezes after an undo rewinds past the winning point.
    mutating func resume() {
        guard startDate != nil else { return }
        endDate = nil
    }

    mutating func reset() {
        startDate = nil
        endDate = nil
    }

    func elapsed(asOf now: Date = Date()) -> TimeInterval {
        guard let startDate else { return 0 }
        return max(0, (endDate ?? now).timeIntervalSince(startDate))
    }

    /// `M:SS` under an hour, `H:MM:SS` beyond it.
    static func formatted(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    func formattedElapsed(asOf now: Date = Date()) -> String {
        Self.formatted(elapsed(asOf: now))
    }
}
