import SwiftUI

/// Set-by-set breakdown of a single archived match, with a rally-level momentum read-out.
struct MatchDetailView: View {
    let record: MatchRecord
    let theme: AppTheme

    private var sets: [SetRecord] { record.sets ?? [] }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header

                    if sets.isEmpty {
                        legacyRecordNotice
                    } else {
                        ForEach(sets) { set in
                            setCard(set)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(Localized.matchDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                playerColumn(name: record.p1Name, sets: record.p1Sets, color: theme.p1Color, isWinner: record.winner == .player1)

                VStack(spacing: 2) {
                    Text(Localized.setsLabel.uppercased())
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1.2)

                    Text("\(record.p1Sets) - \(record.p2Sets)")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.black)
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                .frame(minWidth: 84)

                playerColumn(name: record.p2Name, sets: record.p2Sets, color: theme.p2Color, isWinner: record.winner == .player2)
            }

            HStack(spacing: 8) {
                metaTag(record.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                if let duration = record.formattedDuration {
                    metaTag(duration, systemImage: "stopwatch.fill")
                }
                if record.totalRallies > 0 {
                    metaTag("\(record.totalRallies) \(Localized.ralliesLabel)", systemImage: "arrow.left.arrow.right")
                }
            }
            .frame(maxWidth: .infinity)

            metaTag(
                Localized.exportRulesSummary(
                    targetScore: record.targetScore,
                    bestOfSets: record.bestOfSets,
                    winByTwo: record.winByTwo
                ),
                systemImage: "list.bullet.rectangle"
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func playerColumn(name: String, sets: Int, color: Color, isWinner: Bool) -> some View {
        VStack(spacing: 6) {
            if isWinner {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.yellow)
            }

            Text(name)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text("\(sets)")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.black)
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private func metaTag(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.62))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.07)))
    }

    // MARK: - Per-set card

    private func setCard(_ set: SetRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Localized.setLabelSingular) \(set.index)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))

                if !set.isComplete {
                    Text(Localized.unfinishedSet.uppercased())
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }

                Spacer()

                Text(set.scoreLine)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundColor(set.winner.map(theme.color(for:)) ?? .white.opacity(0.7))
            }

            if set.rallies.isEmpty {
                Text(Localized.noRallyData)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                MomentumChart(rallies: set.rallies, theme: theme)
                    .frame(height: 56)

                RallyStrip(rallies: set.rallies, theme: theme)
                    .frame(height: 10)

                HStack {
                    Text("\(record.p1Name) \(set.rallies.points(for: .player1))")
                        .foregroundColor(theme.p1Color)
                    Spacer()
                    Text(Localized.longestRunLabel + " " + longestRunDescription(set.rallies))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                    Text("\(set.rallies.points(for: .player2)) \(record.p2Name)")
                        .foregroundColor(theme.p2Color)
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .accessibilityElement(children: .combine)
    }

    /// Longest unbroken streak of rallies in the set, and who ran it.
    private func longestRunDescription(_ rallies: RallyLog) -> String {
        var bestLength = 0
        var bestPlayer: Player?
        var currentLength = 0
        var currentPlayer: Player?

        for winner in rallies.winners {
            if winner == currentPlayer {
                currentLength += 1
            } else {
                currentPlayer = winner
                currentLength = 1
            }

            if currentLength > bestLength {
                bestLength = currentLength
                bestPlayer = currentPlayer
            }
        }

        guard bestLength > 0, let bestPlayer else { return "–" }
        let name = bestPlayer == .player1 ? record.p1Name : record.p2Name
        return "\(bestLength) · \(name)"
    }

    private var legacyRecordNotice: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.35))

            Text(Localized.noSetBreakdown)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

/// Running point difference across a set, drawn from player 1's perspective: above the centre
/// line means player 1 is ahead, below means player 2 is.
private struct MomentumChart: View {
    let rallies: RallyLog
    let theme: AppTheme

    var body: some View {
        Canvas { context, size in
            let progression = rallies.leadProgression
            guard progression.count > 1, size.width > 0, size.height > 0 else { return }

            let peak = max(1, progression.map { abs($0) }.max() ?? 1)
            let midY = size.height / 2
            let amplitude = midY - 3
            let stepX = size.width / CGFloat(progression.count - 1)

            var baseline = Path()
            baseline.move(to: CGPoint(x: 0, y: midY))
            baseline.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(baseline, with: .color(.white.opacity(0.14)), lineWidth: 1)

            var line = Path()
            for (index, lead) in progression.enumerated() {
                let point = CGPoint(
                    x: CGFloat(index) * stepX,
                    y: midY - (CGFloat(lead) / CGFloat(peak)) * amplitude
                )
                if index == 0 {
                    line.move(to: point)
                } else {
                    line.addLine(to: point)
                }
            }

            context.stroke(
                line,
                with: .linearGradient(
                    Gradient(colors: [theme.p1Color, theme.p1Color.opacity(0.7), theme.p2Color.opacity(0.7), theme.p2Color]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .accessibilityHidden(true)
    }
}

/// One thin bar per rally, coloured by who won it — the raw shape of the set at a glance.
private struct RallyStrip: View {
    let rallies: RallyLog
    let theme: AppTheme

    var body: some View {
        Canvas { context, size in
            let winners = rallies.winners
            guard !winners.isEmpty, size.width > 0 else { return }

            let slotWidth = size.width / CGFloat(winners.count)
            let barWidth = max(0.8, slotWidth - 0.6)

            for (index, winner) in winners.enumerated() {
                let rect = CGRect(
                    x: CGFloat(index) * slotWidth,
                    y: 0,
                    width: barWidth,
                    height: size.height
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: min(1.5, barWidth / 2)),
                    with: .color(theme.color(for: winner))
                )
            }
        }
        .accessibilityHidden(true)
    }
}
