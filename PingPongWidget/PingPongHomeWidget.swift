import SwiftUI
import WidgetKit

/// What the Home Screen widget shows: the match on the table if there is one, otherwise the last
/// archived result.
struct ScoreSnapshotEntry: TimelineEntry {
    let date: Date
    let p1Name: String
    let p2Name: String
    let p1Score: Int
    let p2Score: Int
    let p1Sets: Int
    let p2Sets: Int
    let isLive: Bool
    let hasData: Bool
    let themeIndex: Int
    /// A decided multi-set match is reported by its set score; a match in progress, or one
    /// abandoned mid-set, by its points.
    let showsSetsAsHeadline: Bool

    static let placeholder = ScoreSnapshotEntry(
        date: Date(),
        p1Name: "Simo", p2Name: "Ale",
        p1Score: 8, p2Score: 6, p1Sets: 1, p2Sets: 1,
        isLive: true, hasData: true, themeIndex: 0, showsSetsAsHeadline: false
    )

    static let empty = ScoreSnapshotEntry(
        date: Date(),
        p1Name: "—", p2Name: "—",
        p1Score: 0, p2Score: 0, p1Sets: 0, p2Sets: 0,
        isLive: false, hasData: false, themeIndex: 0, showsSetsAsHeadline: false
    )
}

struct ScoreSnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScoreSnapshotEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (ScoreSnapshotEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScoreSnapshotEntry>) -> Void) {
        // The app refreshes the timeline when the score changes, so there is nothing to poll for.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    /// Reads through the App Group. Without that entitlement the extension has its own empty
    /// container, which reads as "no data" rather than as wrong data.
    private func currentEntry() -> ScoreSnapshotEntry {
        let defaults = WidgetSharedStore.defaults
        let themeIndex = defaults.object(forKey: "themeIndex") as? Int ?? 0

        let p1Score = defaults.integer(forKey: "p1Score")
        let p2Score = defaults.integer(forKey: "p2Score")
        let p1Sets = defaults.integer(forKey: "p1Sets")
        let p2Sets = defaults.integer(forKey: "p2Sets")
        // A finished match is archived to `matchRecords` only when the user resets, which can be
        // a long time after the winning point. Until then it is still the most recent result and
        // must be read from the live keys — falling through to the archive would headline the match
        // BEFORE this one, or the empty state after a first-ever match.
        let bestOfSets = defaults.object(forKey: "bestOfSets") as? Int ?? 3
        let isFinished = defaults.string(forKey: "winner") != nil
        let hasMatchOnTable = isFinished || (p1Score + p2Score + p1Sets + p2Sets) > 0

        if hasMatchOnTable {
            return ScoreSnapshotEntry(
                date: Date(),
                p1Name: defaults.string(forKey: "p1Name") ?? "P1",
                p2Name: defaults.string(forKey: "p2Name") ?? "P2",
                p1Score: p1Score, p2Score: p2Score, p1Sets: p1Sets, p2Sets: p2Sets,
                isLive: !isFinished, hasData: true, themeIndex: themeIndex,
                showsSetsAsHeadline: isFinished && bestOfSets > 1
            )
        }

        guard let last = WidgetSharedStore.lastArchivedMatch() else {
            return ScoreSnapshotEntry(
                date: Date(), p1Name: "—", p2Name: "—",
                p1Score: 0, p2Score: 0, p1Sets: 0, p2Sets: 0,
                isLive: false, hasData: false, themeIndex: themeIndex,
                showsSetsAsHeadline: false
            )
        }

        return ScoreSnapshotEntry(
            date: Date(),
            p1Name: last.p1Name, p2Name: last.p2Name,
            p1Score: last.p1Score, p2Score: last.p2Score,
            p1Sets: last.p1Sets, p2Sets: last.p2Sets,
            isLive: false, hasData: true, themeIndex: themeIndex,
            showsSetsAsHeadline: last.winner != nil && (last.bestOfSets ?? 1) > 1
        )
    }
}

/// The widget extension cannot link the app's `SharedStore`, so it resolves the same App Group and
/// decodes only the few fields it draws.
enum WidgetSharedStore {
    static let appGroupIdentifier = "group.com.simo.pingpong"

    /// `UserDefaults(suiteName:)` vends a store for any group name whether or not the extension
    /// is entitled to it, so it cannot detect a missing App Group. Ask the file system instead;
    /// without the container the widget shows its empty state rather than silently wrong data.
    static var isSharedContainerAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) != nil
    }

    static var defaults: UserDefaults {
        guard isSharedContainerAvailable, let group = UserDefaults(suiteName: appGroupIdentifier) else {
            return .standard
        }
        return group
    }

    struct ArchivedMatch: Decodable {
        let p1Name: String
        let p2Name: String
        let p1Score: Int
        let p2Score: Int
        let p1Sets: Int
        let p2Sets: Int
        // Optional so records written before these fields existed still decode.
        let winner: String?
        let bestOfSets: Int?
    }

    static func lastArchivedMatch() -> ArchivedMatch? {
        guard let data = defaults.data(forKey: "matchRecords"),
              let records = try? JSONDecoder().decode([ArchivedMatch].self, from: data) else {
            return nil
        }
        // Records are stored newest first.
        return records.first
    }
}

struct PingPongHomeWidgetEntryView: View {
    var entry: ScoreSnapshotEntry
    @Environment(\.widgetFamily) private var family

    private var theme: WidgetTheme { WidgetTheme.theme(for: entry.themeIndex) }

    var body: some View {
        VStack(spacing: family == .systemSmall ? 6 : 10) {
            HStack(spacing: 5) {
                if entry.isLive {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 5, height: 5)
                }

                Text(entry.isLive
                     ? WidgetLocalized.liveLabel
                     : (entry.showsSetsAsHeadline ? WidgetLocalized.finalLabel : WidgetLocalized.lastMatchLabel))
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(entry.isLive ? .yellow : .white.opacity(0.45))
                    .tracking(1)
            }

            if entry.hasData {
                scoreBlock
            } else {
                Text(WidgetLocalized.noMatchesLabel)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(
            LinearGradient(
                colors: [theme.bgStart, theme.bgEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }

    private var scoreBlock: some View {
        // A finished match is remembered by its set score, not by the points of its last set.
        let p1Headline = entry.showsSetsAsHeadline ? entry.p1Sets : entry.p1Score
        let p2Headline = entry.showsSetsAsHeadline ? entry.p2Sets : entry.p2Score
        let subLabel = entry.showsSetsAsHeadline ? WidgetLocalized.pointsLabel : WidgetLocalized.setsLabel
        let subValue = entry.showsSetsAsHeadline
            ? "\(entry.p1Score)–\(entry.p2Score)"
            : "\(entry.p1Sets)–\(entry.p2Sets)"

        return VStack(spacing: family == .systemSmall ? 4 : 8) {
            HStack(spacing: 10) {
                sideColumn(name: entry.p1Name, score: p1Headline, tint: theme.p1Color)

                Text("–")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))

                sideColumn(name: entry.p2Name, score: p2Headline, tint: theme.p2Color)
            }

            HStack(spacing: 5) {
                Text(subLabel)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))

                Text(subValue)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.08)))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.p1Name) \(p1Headline), \(entry.p2Name) \(p2Headline)")
    }

    private func sideColumn(name: String, score: Int, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("\(score)")
                .font(.system(size: family == .systemSmall ? 30 : 36, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: tint.opacity(0.8), radius: 5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PingPongHomeWidget: Widget {
    let kind = "PingPongHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScoreSnapshotProvider()) { entry in
            PingPongHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WidgetLocalized.widgetDisplayName)
        .description(WidgetLocalized.widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
