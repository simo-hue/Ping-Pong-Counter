import Charts
import SwiftUI

/// Whole-history dashboard: headline totals, activity over time, the leaderboard, points scored
/// and conceded, and how matches tend to finish.
///
/// Chart colour follows one rule throughout: a single measure across labelled categories gets a
/// single hue (a rainbow of one-bar-per-colour would encode nothing), and only the genuinely
/// two-series chart uses the theme's two accents — which are validated as colourblind-separable.
struct StatsView: View {
    @ObservedObject var viewModel: ScoreViewModel

    private var theme: AppTheme { AppTheme.theme(at: viewModel.themeIndex) }
    private var records: [MatchRecord] { viewModel.matchRecords }
    private var totals: OverallTotals { MatchStatistics.overallTotals(in: records) }
    private var leaderboard: [LeaderboardEntry] {
        MatchStatistics.leaderboard(roster: viewModel.roster, records: records)
    }
    private var distribution: [SetScoreTally] { MatchStatistics.setScoreDistribution(in: records) }

    private static let activityWindowDays = 30

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if records.isEmpty {
                emptyState
            } else {
                ScrollView {
                    // Hoisted once: the aggregation is O(roster × records) and the body reads it
                    // four times (guard, chart, frame height, points chart).
                    let board = leaderboard

                    VStack(spacing: 18) {
                        totalsGrid
                        activityCard
                        if board.isEmpty {
                            rosterHint
                        } else {
                            leaderboardCard(board)
                            pointsCard(board)
                        }
                        if !distribution.isEmpty {
                            distributionCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle(Localized.statsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    // MARK: - Headline totals

    private var totalsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            tile(Localized.totalMatches, "\(totals.matches)", systemImage: "number.circle.fill")
            tile(Localized.completedMatches, "\(totals.completed)", systemImage: "checkmark.circle.fill")
            tile(Localized.totalRalliesLabel, totals.rallies > 0 ? "\(totals.rallies)" : "–", systemImage: "arrow.left.arrow.right")
            tile(
                Localized.averageDurationLabel,
                totals.averageSeconds > 0 ? MatchClock.formatted(TimeInterval(totals.averageSeconds)) : "–",
                systemImage: "stopwatch.fill"
            )
        }
    }

    private func tile(_ title: String, _ value: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white.opacity(0.45))

            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .monospacedDigit()
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .padding(8)
        .background(card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Activity

    private var activityCard: some View {
        let activity = MatchStatistics.activity(in: records, days: Self.activityWindowDays, endingOn: Date())
        let busiest = activity.map(\.matches).max() ?? 0

        return chartCard(
            title: Localized.activityChartTitle,
            subtitle: Localized.activityChartSubtitle(days: Self.activityWindowDays)
        ) {
            // One measure over time — a single hue. No legend: the title names the series.
            Chart(activity) { day in
                BarMark(
                    x: .value(Localized.dayAxisLabel, day.day, unit: .day),
                    y: .value(Localized.matchesAxisLabel, day.matches)
                )
                .foregroundStyle(theme.p1Color)
                .cornerRadius(2)
                .accessibilityLabel(day.day.formatted(date: .abbreviated, time: .omitted))
                .accessibilityValue("\(day.matches)")
            }
            .chartYScale(domain: 0...max(1, busiest))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.45))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .frame(height: 130)
        }
    }

    // MARK: - Leaderboard

    private func leaderboardCard(_ board: [LeaderboardEntry]) -> some View {
        chartCard(title: Localized.leaderboardTitle, subtitle: Localized.leaderboardSubtitle) {
            // Win rate is one measure across named players, so every bar shares a hue and the
            // player's own label carries identity.
            Chart(board) { entry in
                BarMark(
                    x: .value(Localized.winRateLabel, entry.stats.winRate),
                    y: .value(Localized.rosterTitle, entry.player.name)
                )
                .foregroundStyle(theme.p1Color)
                .cornerRadius(3)
                // Charts reserves no room for a trailing annotation, and the x domain is pinned
                // to 0...1 — so a 100% bar would push its own label outside the card. That is the
                // top row the very first time the dashboard is opened, so keep it inside.
                .annotation(
                    position: .trailing,
                    alignment: .leading,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    Text(entry.stats.winRatePercentText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.7))
                }
                .accessibilityLabel(entry.player.name)
                .accessibilityValue(
                    "\(entry.stats.winRatePercentText), \(Localized.playedWonSummary(played: entry.stats.matchesPlayed, won: entry.stats.matchesWon))"
                )
            }
            .chartXScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel {
                        if let ratio = value.as(Double.self) {
                            Text("\(Int(ratio * 100))%")
                        }
                    }
                    .foregroundStyle(.white.opacity(0.45))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel().foregroundStyle(.white.opacity(0.75))
                }
            }
            .frame(height: CGFloat(board.count) * 34 + 34)
        }
    }

    // MARK: - Points for / against

    private func pointsCard(_ board: [LeaderboardEntry]) -> some View {
        chartCard(title: Localized.pointsChartTitle, subtitle: Localized.pointsChartSubtitle) {
            // The only genuinely two-series chart here, so it is the only one that spends the
            // theme's two accents — and it carries a legend because identity is not color-alone.
            Chart {
                ForEach(board) { entry in
                    BarMark(
                        x: .value(Localized.rosterTitle, entry.player.name),
                        y: .value(Localized.pointsLabel, entry.stats.pointsWon)
                    )
                    .foregroundStyle(by: .value(Localized.pointsLabel, Localized.pointsForLabel))
                    .position(by: .value(Localized.pointsLabel, Localized.pointsForLabel))
                    .cornerRadius(3)
                    .accessibilityLabel("\(entry.player.name) \(Localized.pointsForLabel)")
                    .accessibilityValue("\(entry.stats.pointsWon)")

                    BarMark(
                        x: .value(Localized.rosterTitle, entry.player.name),
                        y: .value(Localized.pointsLabel, entry.stats.pointsLost)
                    )
                    .foregroundStyle(by: .value(Localized.pointsLabel, Localized.pointsAgainstLabel))
                    .position(by: .value(Localized.pointsLabel, Localized.pointsAgainstLabel))
                    .cornerRadius(3)
                    .accessibilityLabel("\(entry.player.name) \(Localized.pointsAgainstLabel)")
                    .accessibilityValue("\(entry.stats.pointsLost)")
                }
            }
            // Fixed hue order keyed to the series, so filtering the roster never repaints anyone.
            .chartForegroundStyleScale([
                Localized.pointsForLabel: theme.p1Color,
                Localized.pointsAgainstLabel: theme.p2Color
            ])
            .chartLegend(position: .bottom, spacing: 8)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.45))
                }
            }
            .chartXAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(.white.opacity(0.7)) }
            }
            .frame(height: 190)
        }
    }

    // MARK: - How matches finish

    private var distributionCard: some View {
        chartCard(title: Localized.finishChartTitle, subtitle: Localized.finishChartSubtitle) {
            Chart(distribution) { tally in
                BarMark(
                    x: .value(Localized.setsLabel, tally.label),
                    y: .value(Localized.totalMatches, tally.count)
                )
                .foregroundStyle(theme.p2Color)
                .cornerRadius(3)
                .annotation(position: .top) {
                    Text("\(tally.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.7))
                }
                .accessibilityLabel(tally.label)
                .accessibilityValue("\(tally.count)")
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(.white.opacity(0.7)) }
            }
            .frame(height: 150)
        }
    }

    // MARK: - Chrome

    private func chartCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.88))

                Text(subtitle)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.06))
    }

    private var rosterHint: some View {
        Text(Localized.statsNeedRoster)
            .font(.system(size: 12, design: .rounded))
            .foregroundColor(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.35))

            Text(Localized.noSavedResults)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(40)
    }
}
