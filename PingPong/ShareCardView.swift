import SwiftUI

/// A square result card, sized for sharing rather than for the screen.
///
/// Kept as a plain `View` so `ImageRenderer` can rasterise it off-screen; nothing here reads the
/// environment or animates, because a renderer has neither.
struct ShareCardView: View {
    let record: MatchRecord
    let theme: AppTheme

    static let side: CGFloat = 1080

    private var winnerName: String? {
        switch record.winner {
        case .player1: return record.p1Name
        case .player2: return record.p2Name
        case nil: return nil
        }
    }

    var body: some View {
        VStack(spacing: 44) {
            Spacer(minLength: 0)

            Text("🏓")
                .font(.system(size: 92))

            if let winnerName {
                VStack(spacing: 10) {
                    Text(Localized.winnerTitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                        .tracking(8)

                    Text(winnerName)
                        .font(.system(size: 78, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                }
            }

            HStack(alignment: .center, spacing: 34) {
                sideColumn(name: record.p1Name, sets: record.p1Sets, tint: theme.p1Color)

                Text("–")
                    .font(.system(size: 62, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))

                sideColumn(name: record.p2Name, sets: record.p2Sets, tint: theme.p2Color)
            }
            .padding(.horizontal, 60)

            if let setLine = record.setScoreLine {
                Text(setLine)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 60)
            }

            HStack(spacing: 14) {
                tag(record.date.formatted(date: .abbreviated, time: .omitted))
                if let duration = record.formattedDuration {
                    tag(duration)
                }
                if record.totalRallies > 0 {
                    tag("\(record.totalRallies) \(Localized.ralliesLabel)")
                }
            }

            Spacer(minLength: 0)

            Text("Ping Pong Counter")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.32))
                .tracking(3)
                .padding(.bottom, 46)
        }
        .frame(width: Self.side, height: Self.side)
        .background(
            LinearGradient(
                colors: [theme.bgStart, theme.bgEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func sideColumn(name: String, sets: Int, tint: Color) -> some View {
        VStack(spacing: 12) {
            Text(name)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("\(sets)")
                .font(.system(size: 132, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .shadow(color: tint.opacity(0.8), radius: 26)
        }
        .frame(maxWidth: .infinity)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.08)))
    }
}
