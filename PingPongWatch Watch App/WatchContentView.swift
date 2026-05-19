import SwiftUI
import WatchKit

struct WatchContentView: View {
    @StateObject private var connector = WatchConnector.shared
    
    var body: some View {
        ZStack {
            if !connector.winner.isEmpty {
                // Celebration
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 5)
                    
                    Text("VINCITORE!")
                        .font(.system(.footnote, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text(connector.winner == "player1" ? connector.p1Name : connector.p2Name)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.black)
                        .multilineTextAlignment(.center)
                    
                    Button("Nuova Partita") {
                        WKInterfaceDevice.current().play(.success)
                        connector.sendReset()
                    }
                    .tint(.yellow)
                    .font(.footnote)
                }
            } else {
                // Split Scoreboard
                HStack(spacing: 2) {
                    // Player 1 Side
                    playerButton(
                        player: "player1",
                        name: connector.p1Name,
                        score: connector.p1Score,
                        isServing: connector.currentServer == "player1",
                        color: Color(red: 1.0, green: 0.25, blue: 0.35)
                    )
                    
                    // Player 2 Side
                    playerButton(
                        player: "player2",
                        name: connector.p2Name,
                        score: connector.p2Score,
                        isServing: connector.currentServer == "player2",
                        color: Color(red: 0.0, green: 0.7, blue: 1.0)
                    )
                }
                .ignoresSafeArea()
                .overlay(
                    // Small Center Floating Bar for Undo
                    VStack {
                        Spacer()
                        Button {
                            WKInterfaceDevice.current().play(.directionUp)
                            connector.sendUndo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 2)
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private func playerButton(player: String, name: String, score: Int, isServing: Bool, color: Color) -> some View {
        Button {
            WKInterfaceDevice.current().play(.click)
            connector.sendIncrement(player: player)
        } label: {
            VStack(spacing: 4) {
                Spacer()
                
                // Server Indicator dot
                if isServing {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 8, height: 8)
                        .shadow(color: .yellow, radius: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
                
                Text(name.prefix(5).uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(score)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isServing ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        // Long press gesture on Apple Watch to decrement score (Undo for that player)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    WKInterfaceDevice.current().play(.directionDown)
                    connector.sendDecrement(player: player)
                }
        )
    }
}
