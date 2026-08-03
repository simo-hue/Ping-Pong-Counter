import SwiftUI

/// Career record for one roster player, plus their head-to-head against every other saved player.
struct PlayerStatsView: View {
    let player: RosterPlayer
    @ObservedObject var viewModel: ScoreViewModel

    private var theme: AppTheme { AppTheme.theme(at: viewModel.themeIndex) }
    private var stats: PlayerStats { viewModel.stats(for: player) }
    private var headToHead: [HeadToHeadRecord] { viewModel.headToHead(for: player) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    identityCard

                    if stats.matchesPlayed == 0 {
                        emptyState
                    } else {
                        recordGrid
                        streakCard

                        if headToHead.isEmpty {
                            noOpponentsNotice
                        } else {
                            headToHeadCard
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var identityCard: some View {
        VStack(spacing: 10) {
            Text(player.emoji)
                .font(.system(size: 42))
                .frame(width: 76, height: 76)
                .background(Circle().fill(Color.white.opacity(0.07)))

            Text(player.name)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            if stats.decidedMatches > 0 {
                Text("\(Localized.winRateLabel) \(stats.winRatePercentText)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(theme.p1Color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var recordGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            statTile(Localized.matchesPlayedLabel, "\(stats.matchesPlayed)", .white)
            statTile(Localized.matchesWonLabel, "\(stats.matchesWon)", theme.p1Color)
            statTile(Localized.setsWonLostLabel, "\(stats.setsWon)-\(stats.setsLost)", .white.opacity(0.85))
            statTile(Localized.pointsWonLostLabel, "\(stats.pointsWon)-\(stats.pointsLost)", .white.opacity(0.85))
        }
    }

    private func statTile(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .monospacedDigit()
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var streakCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localized.currentStreakLabel)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Text(streakText)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(streakColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Localized.bestStreakLabel)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Text(stats.bestWinStreak > 0 ? "\(stats.bestWinStreak)" : "–")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundColor(.yellow)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var streakText: String {
        if stats.currentStreak > 0 { return Localized.winStreak(stats.currentStreak) }
        if stats.currentStreak < 0 { return Localized.lossStreak(-stats.currentStreak) }
        return "–"
    }

    private var streakColor: Color {
        if stats.currentStreak > 0 { return theme.p1Color }
        if stats.currentStreak < 0 { return .white.opacity(0.5) }
        return .white.opacity(0.5)
    }

    private var headToHeadCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Localized.headToHeadHeader)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.2)

            ForEach(headToHead) { entry in
                HStack(spacing: 10) {
                    Text(entry.opponent.emoji)
                        .font(.system(size: 17))

                    Text(entry.opponent.name)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    Text("\(entry.setsWon)-\(entry.setsLost) \(Localized.setsLabel.lowercased())")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.45))

                    Text(entry.summary)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .monospacedDigit()
                        .foregroundColor(entry.wins >= entry.losses ? theme.p1Color : theme.p2Color)
                        .frame(minWidth: 46, alignment: .trailing)
                }
                .padding(.vertical, 5)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var noOpponentsNotice: some View {
        Text(Localized.noHeadToHead)
            .font(.system(size: 12, design: .rounded))
            .foregroundColor(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.35))

            Text(Localized.noMatchesForPlayer)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
