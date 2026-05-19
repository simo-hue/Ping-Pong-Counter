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
                    
                    // Set Score Dashboard Divider
                    VStack(spacing: 4) {
                        Text("SET")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        HStack(spacing: 12) {
                            Text("\(context.state.p1Sets)")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(theme.p1Color)
                            
                            Text("—")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white.opacity(0.2))
                            
                            Text("\(context.state.p2Sets)")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(theme.p2Color)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
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
                // EXPANDED STATE (Long press on Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            if context.state.currentServer == "player1" {
                                Circle().fill(Color.yellow).frame(width: 6, height: 6)
                            }
                            Text(context.attributes.p1Name.prefix(8))
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Text("\(context.state.p1Score)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(theme.p1Color)
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(context.attributes.p2Name.prefix(8))
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.8))
                            if context.state.currentServer == "player2" {
                                Circle().fill(Color.yellow).frame(width: 6, height: 6)
                            }
                        }
                        Text("\(context.state.p2Score)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(theme.p2Color)
                    }
                    .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("SET")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                        Text("\(context.state.p1Sets) — \(context.state.p2Sets)")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if let winner = context.state.winner {
                        let winnerName = winner == "player1" ? context.attributes.p1Name : context.attributes.p2Name
                        Text("🏆 Vince \(winnerName)!")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.yellow)
                    } else {
                        Text("MATCH IN CORSO")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.2))
                            .tracking(2)
                    }
                }
                
            } compactLeading: {
                // COMPACT STATE (Left pill side) - P1 indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.p1Color)
                        .frame(width: 6, height: 6)
                    Text("\(context.state.p1Score)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(theme.p1Color)
                }
            } compactTrailing: {
                // COMPACT STATE (Right pill side) - P2 indicator
                HStack(spacing: 4) {
                    Text("\(context.state.p2Score)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(theme.p2Color)
                    Circle()
                        .fill(theme.p2Color)
                        .frame(width: 6, height: 6)
                }
            } minimal: {
                // MINIMAL STATE (When multiple live activities are active)
                let isP1Server = context.state.currentServer == "player1"
                Text("\(isP1Server ? context.state.p1Score : context.state.p2Score)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(isP1Server ? theme.p1Color : theme.p2Color)
            }
        }
        .contentMarginsDisabled()
    }
}
