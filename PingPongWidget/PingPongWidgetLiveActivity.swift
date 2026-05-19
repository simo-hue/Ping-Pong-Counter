import ActivityKit
import WidgetKit
import SwiftUI

public struct PingPongWidgetLiveActivity: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: PingPongAttributes.self) { context in
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
                        
                        Text("\(context.state.p1Score)")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.35))
                            .shadow(color: Color(red: 1.0, green: 0.25, blue: 0.35).opacity(0.4), radius: 6)
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
                                .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.35))
                            
                            Text("—")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white.opacity(0.2))
                            
                            Text("\(context.state.p2Sets)")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
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
                        
                        Text("\(context.state.p2Score)")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
                            .shadow(color: Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.4), radius: 6)
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
            .activityBackgroundTint(Color(red: 0.05, green: 0.02, blue: 0.07).opacity(0.95))
            .activitySystemActionForegroundColor(.white)
            .containerBackground(Color(red: 0.05, green: 0.02, blue: 0.07).opacity(0.95), for: .widget)
            
        } dynamicIsland: { context in
            DynamicIsland {
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
                            .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.35))
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
                            .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
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
                        .fill(Color(red: 1.0, green: 0.25, blue: 0.35))
                        .frame(width: 6, height: 6)
                    Text("\(context.state.p1Score)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.35))
                }
            } compactTrailing: {
                // COMPACT STATE (Right pill side) - P2 indicator
                HStack(spacing: 4) {
                    Text("\(context.state.p2Score)")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
                    Circle()
                        .fill(Color(red: 0.0, green: 0.7, blue: 1.0))
                        .frame(width: 6, height: 6)
                }
            } minimal: {
                // MINIMAL STATE (When multiple live activities are active)
                let isP1Server = context.state.currentServer == "player1"
                Text("\(isP1Server ? context.state.p1Score : context.state.p2Score)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(isP1Server ? Color(red: 1.0, green: 0.25, blue: 0.35) : Color(red: 0.0, green: 0.7, blue: 1.0))
            }
        }
        .contentMarginsDisabled()
    }
}
