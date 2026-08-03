import SwiftUI
import WatchKit

struct WatchContentView: View {
    @StateObject private var connector = WatchConnector.shared
    
    // Animation states for neon glowing pulse
    @State private var animatePulse = false
    @State private var isShowingResetConfirmation = false

    /// Digital Crown position. Mapped to score *deltas* rather than to an absolute score: the
    /// crown has no notion of where the match currently stands, and binding it to the score
    /// itself would let a stray nudge rewrite a whole set.
    @State private var crownPosition: Double = 0
    @State private var lastCrownDetent: Int = 0
    
    // Check if the current locale is Italian
    private var isItalian: Bool { WatchLocalized.isItalian }
    
    var body: some View {
        ZStack {
            // Background base
            Color.black.ignoresSafeArea()
            
            if !connector.winner.isEmpty {
                // Premium Celebration Screen
                celebrationView
            } else {
                // Interactive Split Scoreboard
                HStack(spacing: 0) {
                    // Player 1 Side
                    playerPanel(
                        player: "player1",
                        name: connector.p1Name,
                        score: connector.p1Score,
                        isServing: connector.currentServer == "player1",
                        color: Color(red: 1.0, green: 0.25, blue: 0.35) // Hot Neon Pink
                    )
                    
                    // Player 2 Side
                    playerPanel(
                        player: "player2",
                        name: connector.p2Name,
                        score: connector.p2Score,
                        isServing: connector.currentServer == "player2",
                        color: Color(red: 0.0, green: 0.7, blue: 1.0) // Neon Cyan
                    )
                }
                .ignoresSafeArea()
                
                centralServeDivider

                if connector.isDoubles && !connector.servingName.isEmpty {
                    doublesServerBadge
                }

                watchFloatingControls
            }
        }
        .alert(isItalian ? "Azzerare la partita?" : "Reset match?", isPresented: $isShowingResetConfirmation) {
            Button(isItalian ? "Azzera" : "Reset", role: .destructive) {
                WKInterfaceDevice.current().play(.success)
                connector.sendReset()
            }
            Button(isItalian ? "Annulla" : "Cancel", role: .cancel) {}
        }
        .focusable(true)
        .digitalCrownRotation(
            $crownPosition,
            from: -1000,
            through: 1000,
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownPosition) { _, newValue in
            applyCrownDetent(newValue)
        }
        .onAppear {
            // Trigger loop animation for breathing pulse glows
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
    
    private func setsWon(for player: String) -> Int {
        player == "player1" ? connector.p1Sets : connector.p2Sets
    }

    // MARK: - Player Score Panel
    @ViewBuilder
    private func playerPanel(player: String, name: String, score: Int, isServing: Bool, color: Color) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)
            
            // 1. Serving Ping Pong Ball Indicator
            VStack {
                if isServing {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [.white, .yellow, Color(red: 0.95, green: 0.8, blue: 0.0)]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 5
                            )
                        )
                        .frame(width: 9, height: 9)
                        .shadow(color: .yellow.opacity(0.8), radius: animatePulse ? 6 : 2)
                        .scaleEffect(animatePulse ? 1.25 : 0.95)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 9, height: 9)
                }
            }
            .frame(height: 12)
            .padding(.top, 18) // Extra padding to avoid Apple Watch status bar clock
            
            Spacer(minLength: 2)
            
            // 2. Athletic Player Name Badge
            Text(formatWatchName(name, defaultPlaceholder: player == "player1" ? "P1" : "P2"))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .tracking(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isServing ? color.opacity(0.22) : Color.white.opacity(0.06))
                )
                .overlay(
                    Capsule()
                        .stroke(isServing ? color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                )
            
            Spacer(minLength: 2)
            
            // 3. Sets won so far — a score alone does not say how the match stands.
            if connector.bestOfSets > 1 {
                HStack(spacing: 3) {
                    ForEach(0..<max(1, connector.bestOfSets), id: \.self) { index in
                        Circle()
                            .fill(index < setsWon(for: player) ? color : Color.white.opacity(0.18))
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.bottom, 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(setsWon(for: player)) \(isItalian ? "set" : "sets")")
            }

            // 4. Premium Neon Score
            Text("\(score)")
                .font(.system(size: score >= 100 ? 36 : 48, weight: .black, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(isServing ? 0.9 : 0.4), radius: isServing && animatePulse ? 12 : 4)
                .scaleEffect(isServing ? (animatePulse ? 1.04 : 0.98) : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: score)
            
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Premium background gradient reflecting serving state
            LinearGradient(
                colors: isServing ? [
                    color.opacity(0.24),
                    color.opacity(0.08),
                    color.opacity(0.03)
                ] : [
                    color.opacity(0.05),
                    color.opacity(0.02),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .contentShape(Rectangle())
        // Unified high-performance gesture controller: Tap for +1, Swipe Down for -1
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = value.translation.height
                    
                    if verticalDistance > 15 && horizontalDistance < 25 {
                        // Swipe Down: Decrement score (-1)
                        WKInterfaceDevice.current().play(.directionDown)
                        connector.sendDecrement(player: player)
                    } else {
                        // Tap (or very small movement): Increment score (+1)
                        WKInterfaceDevice.current().play(.click)
                        connector.sendIncrement(player: player)
                    }
                }
        )
    }

    /// In doubles the glowing half only says which pair is up; on a screen this small the name of
    /// the player actually serving is the whole point, so it gets its own badge at the top.
    private var doublesServerBadge: some View {
        VStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 5, height: 5)

                Text(connector.servingName)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.black.opacity(0.72)))
            .overlay(Capsule().stroke(Color.yellow.opacity(0.35), lineWidth: 1))
            .accessibilityLabel("\(connector.servingName) \(isItalian ? "serve" : "serving")")

            Spacer()
        }
        .padding(.top, 2)
    }

    /// One detent forward is a point for whichever side is serving — the common case at the table,
    /// and it needs no aiming.
    ///
    /// Backwards is an UNDO, not a decrement of the serving side. Scoring a point usually hands the
    /// serve over, so by the time the crown comes back the "serving side" is the other player, and
    /// decrementing them would move the point across the net instead of taking it back — or hit the
    /// zero guard and do nothing at all. Undo restores score, sets and serve together.
    private func applyCrownDetent(_ position: Double) {
        let detent = Int(position.rounded())
        guard detent != lastCrownDetent else { return }

        let delta = detent - lastCrownDetent
        lastCrownDetent = detent

        guard connector.winner.isEmpty else { return }

        if delta > 0 {
            connector.sendIncrement(player: connector.currentServer)
        } else {
            connector.sendUndo()
        }
    }

    private var watchFloatingControls: some View {
        VStack(spacing: 8) {
            watchControlButton(
                systemName: "arrow.uturn.backward",
                accessibilityLabel: isItalian ? "Annulla" : "Undo"
            ) {
                WKInterfaceDevice.current().play(.directionUp)
                connector.sendUndo()
            }

            watchControlButton(
                systemName: "arrow.counterclockwise",
                color: .red.opacity(0.92),
                accessibilityLabel: isItalian ? "Reset partita" : "Reset match"
            ) {
                WKInterfaceDevice.current().play(.click)
                isShowingResetConfirmation = true
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.72))
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.55), radius: 8, y: 3)
    }

    private func watchControlButton(
        systemName: String,
        color: Color = .white.opacity(0.9),
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .black))
                .foregroundColor(color)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(Color.white.opacity(0.09))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var centralServeDivider: some View {
        let activeColor = connector.currentServer == "player1"
            ? Color(red: 1.0, green: 0.25, blue: 0.35)
            : Color(red: 0.0, green: 0.7, blue: 1.0)

        return ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.14), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1.5)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, activeColor.opacity(0.8), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .blur(radius: animatePulse ? 3 : 1)
                .opacity(animatePulse ? 0.9 : 0.55)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Premium Celebration Screen
    private var celebrationView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.12))
                    .frame(width: 54, height: 54)
                    .blur(radius: 4)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 8)
                    .scaleEffect(animatePulse ? 1.08 : 0.95)
            }
            
            VStack(spacing: 2) {
                Text(isItalian ? "VINCITORE!" : "WINNER!")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .tracking(2)
                
                Text(connector.winner == "player1" ? connector.p1Name : connector.p2Name)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
            
            Button {
                WKInterfaceDevice.current().play(.success)
                connector.sendReset()
            } label: {
                Text(isItalian ? "Nuova Partita" : "New Match")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                            .shadow(color: .yellow.opacity(0.4), radius: 4)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RadialGradient(
                colors: [Color.yellow.opacity(0.08), Color.black],
                center: .center,
                startRadius: 0,
                endRadius: 90
            )
        )
    }
    
    // MARK: - Formatting Naming Helper
    private func formatWatchName(_ name: String, defaultPlaceholder: String) -> String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            return defaultPlaceholder
        }
        
        // Smart match for "Giocatore X" / "Player X"
        if clean.localizedCaseInsensitiveContains("giocatore") || clean.localizedCaseInsensitiveContains("player") {
            if clean.contains("1") {
                return isItalian ? "G1" : "P1"
            } else if clean.contains("2") {
                return isItalian ? "G2" : "P2"
            }
        }
        
        // Custom name is short, keep it
        if clean.count <= 6 {
            return clean.uppercased()
        } else {
            // Return initials if multi-word
            let words = clean.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            if words.count >= 2 {
                let initials = words.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
                return initials.uppercased()
            }
            // Truncate long single-word names
            return String(clean.prefix(5)).uppercased()
        }
    }
}
