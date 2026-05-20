import ActivityKit
import WidgetKit
import SwiftUI

// Helper Theme Mapper to match main app aesthetics dynamically
struct WidgetTheme {
    let p1Color: Color
    let p2Color: Color
    let bgStart: Color
    let bgEnd: Color
    
    static func theme(for index: Int) -> WidgetTheme {
        switch index {
        case 1: // Mint & Royal
            return WidgetTheme(
                p1Color: Color(red: 0.0, green: 0.85, blue: 0.55),
                p2Color: Color(red: 0.55, green: 0.3, blue: 0.9),
                bgStart: Color(red: 0.01, green: 0.06, blue: 0.04),
                bgEnd: Color(red: 0.04, green: 0.02, blue: 0.06)
            )
        case 2: // Solar Flare
            return WidgetTheme(
                p1Color: Color(red: 1.0, green: 0.55, blue: 0.0),
                p2Color: Color(red: 0.0, green: 0.8, blue: 0.8),
                bgStart: Color(red: 0.06, green: 0.03, blue: 0.0),
                bgEnd: Color(red: 0.0, green: 0.05, blue: 0.05)
            )
        default: // case 0: Neon Classic (Cyberpunk default)
            return WidgetTheme(
                p1Color: Color(red: 1.0, green: 0.25, blue: 0.35),
                p2Color: Color(red: 0.0, green: 0.7, blue: 1.0),
                bgStart: Color(red: 0.08, green: 0.02, blue: 0.03),
                bgEnd: Color(red: 0.02, green: 0.04, blue: 0.08)
            )
        }
    }
}

private enum DynamicIslandScoreSide {
    case leading
    case trailing

    var alignment: Alignment {
        switch self {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
}

private struct DynamicIslandCompactScore: View {
    let score: Int
    let tint: Color
    let isServing: Bool
    let side: DynamicIslandScoreSide
    let accessibilityName: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 3) {
                if side == .leading {
                    serveDot
                    scoreText
                } else {
                    scoreText
                    serveDot
                }
            }

            scoreText
        }
        .frame(maxWidth: 44, alignment: side.alignment)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(accessibilityName) \(score)")
    }

    private var scoreText: some View {
        Text("\(score)")
            .font(.system(size: 17, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .shadow(color: tint.opacity(0.75), radius: 3)
    }

    private var serveDot: some View {
        Circle()
            .fill(isServing ? Color.yellow : tint)
            .frame(width: isServing ? 7 : 5, height: isServing ? 7 : 5)
            .shadow(color: (isServing ? Color.yellow : tint).opacity(0.7), radius: 3)
    }
}

private struct DynamicIslandExpandedPlayer: View {
    let name: String
    let score: Int
    let tint: Color
    let isServing: Bool
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            HStack(spacing: 4) {
                if alignment == .leading {
                    serveIndicator
                    playerName
                } else {
                    playerName
                    serveIndicator
                }
            }

            Text("\(score)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .shadow(color: tint.opacity(0.85), radius: 5)
        }
    }

    private var playerName: some View {
        Text(String(name.prefix(7)).uppercased())
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
    }

    private var serveIndicator: some View {
        Circle()
            .fill(isServing ? Color.yellow : tint.opacity(0.65))
            .frame(width: 6, height: 6)
    }
}

private struct DynamicIslandMinimalScore: View {
    let p1Score: Int
    let p2Score: Int

    var body: some View {
        Text("\(p1Score)-\(p2Score)")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityLabel("Score \(p1Score) a \(p2Score)")
    }
}

public struct PingPongWidgetLiveActivity: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: PingPongAttributes.self) { context in
            let theme = WidgetTheme.theme(for: context.state.themeIndex)
            
            // LOCK SCREEN WIDGET - Frosted Neon Scoreboard Card
            VStack(spacing: 12) {
                HStack {
                    // Player 1 Scoring Column
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if context.state.currentServer == "player1" {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: .yellow, radius: 4)
                            }
                            Text(context.attributes.p1Name)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        // Premium OLED Neon Glow Score (Back glow + front sharp layer)
                        ZStack(alignment: .leading) {
                            Text("\(context.state.p1Score)")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(theme.p1Color.opacity(0.6))
                                .blur(radius: 6)
                            
                            Text("\(context.state.p1Score)")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: theme.p1Color, radius: 4)
                                .shadow(color: theme.p1Color.opacity(0.5), radius: 8)
                        }
                    }
                    
                    Spacer()
                    
                    // Point Score & Set Dashboard Divider
                    VStack(spacing: 4) {
                        Text("\(context.state.p1Score) — \(context.state.p2Score)")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.3), radius: 4)
                        
                        HStack(spacing: 6) {
                            Text("SET")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("\(context.state.p1Sets)—\(context.state.p2Sets)")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                    }
                    
                    Spacer()
                    
                    // Player 2 Scoring Column
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(context.attributes.p2Name)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if context.state.currentServer == "player2" {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: .yellow, radius: 4)
                            }
                        }
                        
                        // Premium OLED Neon Glow Score (Back glow + front sharp layer)
                        ZStack(alignment: .trailing) {
                            Text("\(context.state.p2Score)")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(theme.p2Color.opacity(0.6))
                                .blur(radius: 6)
                            
                            Text("\(context.state.p2Score)")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: theme.p2Color, radius: 4)
                                .shadow(color: theme.p2Color.opacity(0.5), radius: 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Championship Winner Overlay Banner
                if let winner = context.state.winner {
                    let winnerName = winner == "player1" ? context.attributes.p1Name : context.attributes.p2Name
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.6), radius: 4)
                        Text("Vince \(winnerName)!")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.yellow.opacity(0.16)))
                }
            }
            .padding(.vertical, 14)
            .activityBackgroundTint(Color.clear) // Handled dynamically via containerBackground
            .activitySystemActionForegroundColor(.white)
            .containerBackground(
                LinearGradient(
                    colors: [theme.bgStart, theme.bgEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                for: .widget
            )
            
        } dynamicIsland: { context in
            let theme = WidgetTheme.theme(for: context.state.themeIndex)
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandExpandedPlayer(
                        name: context.attributes.p1Name,
                        score: context.state.p1Score,
                        tint: theme.p1Color,
                        isServing: context.state.currentServer == "player1",
                        alignment: .leading
                    )
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandExpandedPlayer(
                        name: context.attributes.p2Name,
                        score: context.state.p2Score,
                        tint: theme.p2Color,
                        isServing: context.state.currentServer == "player2",
                        alignment: .trailing
                    )
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("SET")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.42))

                        Text("\(context.state.p1Sets)-\(context.state.p2Sets)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .fontWeight(.black)
                            .monospacedDigit()
                            .foregroundColor(.yellow)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if let winner = context.state.winner {
                        let winnerName = winner == "player1" ? context.attributes.p1Name : context.attributes.p2Name
                        HStack(spacing: 5) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("Vince \(winnerName)!")
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                    } else {
                        HStack(spacing: 8) {
                            Text("\(context.state.p1Score)")
                                .foregroundStyle(theme.p1Color)
                            Text("MATCH")
                                .foregroundStyle(.white.opacity(0.45))
                            Text("\(context.state.p2Score)")
                                .foregroundStyle(theme.p2Color)
                        }
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .monospacedDigit()
                    }
                }
                
            } compactLeading: {
                DynamicIslandCompactScore(
                    score: context.state.p1Score,
                    tint: theme.p1Color,
                    isServing: context.state.currentServer == "player1",
                    side: .leading,
                    accessibilityName: context.attributes.p1Name
                )
            } compactTrailing: {
                DynamicIslandCompactScore(
                    score: context.state.p2Score,
                    tint: theme.p2Color,
                    isServing: context.state.currentServer == "player2",
                    side: .trailing,
                    accessibilityName: context.attributes.p2Name
                )
            } minimal: {
                DynamicIslandMinimalScore(
                    p1Score: context.state.p1Score,
                    p2Score: context.state.p2Score
                )
            }
            .keylineTint(theme.p1Color.opacity(0.7))
            .contentMargins(.all, 0, for: .compactLeading)
            .contentMargins(.all, 0, for: .compactTrailing)
            .contentMargins(.bottom, 8, for: .expanded)
        }
        .contentMarginsDisabled()
    }
}
