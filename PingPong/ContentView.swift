import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = ScoreViewModel()
    @State private var isShowingSettings = false
    @State private var isShowingMatchHistory = false
    @State private var animateP1 = false
    @State private var animateP2 = false
    
    // Modern UX Upgrade States
    @State private var isShowingResetConfirm = false
    @State private var editingPlayer: Player? = nil
    @State private var editingNameText: String = ""
    @State private var isShowingNameEditor = false
    
    // Premium UI/UX Animation States
    @State private var serverPulseScale: CGFloat = 1.0
    @State private var p1PlusOffset: CGFloat = 0
    @State private var p1PlusOpacity: Double = 0
    @State private var p2PlusOffset: CGFloat = 0
    @State private var p2PlusOpacity: Double = 0
    
    // Custom theme styling based on the selection in ViewModel
    let themesList = [
        // Theme 0: Neon Classic
        (
            name: "Néon Classic",
            p1Color: Color(red: 1.0, green: 0.25, blue: 0.35),
            p2Color: Color(red: 0.0, green: 0.7, blue: 1.0),
            bgStart: Color(red: 0.08, green: 0.02, blue: 0.03),
            bgEnd: Color(red: 0.02, green: 0.04, blue: 0.08)
        ),
        // Theme 1: Mint & Royal
        (
            name: "Mint & Royal",
            p1Color: Color(red: 0.0, green: 0.85, blue: 0.55),
            p2Color: Color(red: 0.55, green: 0.3, blue: 0.9),
            bgStart: Color(red: 0.01, green: 0.06, blue: 0.04),
            bgEnd: Color(red: 0.04, green: 0.02, blue: 0.06)
        ),
        // Theme 2: Solar Flare
        (
            name: "Solar Flare",
            p1Color: Color(red: 1.0, green: 0.55, blue: 0.0),
            p2Color: Color(red: 0.0, green: 0.8, blue: 0.8),
            bgStart: Color(red: 0.06, green: 0.03, blue: 0.0),
            bgEnd: Color(red: 0.0, green: 0.05, blue: 0.05)
        )
    ]
    
    var currentTheme: (name: String, p1Color: Color, p2Color: Color, bgStart: Color, bgEnd: Color) {
        themesList[themesList.indices.contains(viewModel.themeIndex) ? viewModel.themeIndex : 0]
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                // Background dark atmospheric gradient
                LinearGradient(
                    colors: [currentTheme.bgStart, currentTheme.bgEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Adaptive dashed net line dividing the physical scoreboard fields
                if isLandscape {
                    HStack {
                        Spacer()
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [6, 6]))
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 1.5)
                        Spacer()
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                } else {
                    VStack {
                        Spacer()
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [6, 6]))
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1.5)
                        Spacer()
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
                
                // Adaptive split scoreboard
                if isLandscape {
                    HStack(spacing: 0) {
                        playerHalfView(for: .player1, size: geometry.size)
                        playerHalfView(for: .player2, size: geometry.size)
                    }
                    .ignoresSafeArea()
                } else {
                    VStack(spacing: 0) {
                        playerHalfView(for: .player1, size: geometry.size)
                        playerHalfView(for: .player2, size: geometry.size)
                    }
                    .ignoresSafeArea()
                }
                
                // Frosted Glass Net & Floating Control Center
                floatingControlCenter(isLandscape: isLandscape)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    serverPulseScale = 1.3
                }
                viewModel.syncLiveActivity()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingMatchHistory) {
                MatchHistoryView(viewModel: viewModel)
            }
            .overlay {
                // Game Over Overlay Celebration
                if let winner = viewModel.winner {
                    gameOverCelebrationView(winner: winner)
                }
            }
            // Inline player name editor dialog
            .alert(Localized.isItalian ? "Modifica Nome" : "Edit Name", isPresented: $isShowingNameEditor) {
                TextField(Localized.isItalian ? "Nome Giocatore" : "Player Name", text: $editingNameText)
                    .textInputAutocapitalization(.words)
                Button(Localized.isItalian ? "Salva" : "Save") {
                    let trimmed = editingNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        if editingPlayer == .player1 {
                            viewModel.p1Name = trimmed
                        } else {
                            viewModel.p2Name = trimmed
                        }
                    }
                }
                Button(Localized.isItalian ? "Annulla" : "Cancel", role: .cancel) {}
            } message: {
                Text(Localized.isItalian ? "Inserisci il nome per il \(editingPlayer == .player1 ? "primo" : "secondo") giocatore." : "Enter the name for \(editingPlayer == .player1 ? "first" : "second") player.")
            }
        }
    }
    
    // MARK: - Player Half Screen Component
    
    @ViewBuilder
    private func playerHalfView(for player: Player, size: CGSize) -> some View {
        let isP1 = player == .player1
        let isLandscape = size.width > size.height
        let name = isP1 ? viewModel.p1Name : viewModel.p2Name
        let score = isP1 ? viewModel.p1Score : viewModel.p2Score
        let sets = isP1 ? viewModel.p1Sets : viewModel.p2Sets
        let isServing = viewModel.currentServer == player
        let themeColor = isP1 ? currentTheme.p1Color : currentTheme.p2Color
        let isMatchedOrSetPoint = isP1 ? (viewModel.p1Score >= viewModel.targetScore - 1 && viewModel.p1Score > viewModel.p2Score) : (viewModel.p2Score >= viewModel.targetScore - 1 && viewModel.p2Score > viewModel.p1Score)
        
        ZStack {
            // Subtle glowing background for the active server or player at Set/Match Point
            if isServing {
                RadialGradient(
                    colors: [themeColor.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }
            
            // Soft pulsating warning border during Match/Set point
            if isMatchedOrSetPoint && viewModel.winner == nil {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(themeColor.opacity(0.4), lineWidth: 4)
                    .blur(radius: 2)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 16) {
                Spacer()
                
                // Sets dots
                HStack(spacing: 8) {
                    let totalSets = viewModel.bestOfSets
                    ForEach(0..<totalSets, id: \.self) { idx in
                        Circle()
                            .fill(idx < sets ? themeColor : Color.white.opacity(0.15))
                            .frame(width: 14, height: 14)
                            .shadow(color: idx < sets ? themeColor.opacity(0.8) : .clear, radius: 4)
                            .scaleEffect(idx < sets ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: sets)
                    }
                }
                .padding(.top, 20)
                
                // Player Name (Tappable Button for Direct Editing)
                Button {
                    editingPlayer = player
                    editingNameText = name
                    isShowingNameEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Text(name.uppercased())
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
                
                // Subtle Onboarding Guide (Fades out immediately when a point is scored)
                if viewModel.p1Score == 0 && viewModel.p2Score == 0 && viewModel.p1Sets == 0 && viewModel.p2Sets == 0 {
                    Text(Localized.isItalian ? "Tocca per +1 • Scorri giù per -1" : "Tap for +1 • Swipe down for -1")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.2))
                        .transition(.opacity)
                }
                
                // Score text (with visual pop scale animation and organic OLED neon glow)
                ZStack {
                    // Back glowing ambient layer
                    Text("\(score)")
                        .font(.system(size: min(size.width, size.height) * 0.32, weight: .black, design: .rounded))
                        .foregroundColor(themeColor.opacity(0.6))
                        .blur(radius: 12)
                        .scaleEffect(isP1 ? (animateP1 ? 1.15 : 1.0) : (animateP2 ? 1.15 : 1.0))
                    
                    // Front sharp core layer
                    Text("\(score)")
                        .font(.system(size: min(size.width, size.height) * 0.32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: themeColor, radius: 10)
                        .shadow(color: themeColor.opacity(0.5), radius: 20)
                        .scaleEffect(isP1 ? (animateP1 ? 1.15 : 1.0) : (animateP2 ? 1.15 : 1.0))
                    
                    // Gamified floating +1 feedback popup
                    Text("+1")
                        .font(.system(size: min(size.width, size.height) * 0.09, weight: .black, design: .rounded))
                        .foregroundColor(themeColor)
                        .shadow(color: themeColor, radius: 10)
                        .offset(y: isP1 ? p1PlusOffset : p2PlusOffset)
                        .opacity(isP1 ? p1PlusOpacity : p2PlusOpacity)
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.45), value: isP1 ? animateP1 : animateP2)
                
                // Server visual indicator (Tappable to manually override serving rights)
                Button {
                    viewModel.currentServer = player
                    HapticManager.shared.play(.serveChange)
                } label: {
                    HStack(spacing: 8) {
                        if isServing {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 9, height: 9)
                                .scaleEffect(serverPulseScale)
                                .shadow(color: .yellow.opacity(0.8), radius: 6)
                            
                            Text(Localized.serveButton)
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.yellow)
                                .tracking(1.5)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 9, height: 9)
                            
                            Text(Localized.isItalian ? "IMPOSTA SERVIZIO" : "SET SERVE")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.22))
                                .tracking(1)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(isServing ? Color.yellow.opacity(0.12) : Color.white.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, isLandscape ? 10 : 30)
                
                Spacer()
            }
            .safeAreaPadding(.vertical, isLandscape ? 12 : 24)
            .safeAreaPadding(.horizontal, isLandscape ? 24 : 12)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap registered -> scale up & increment score
            if isP1 {
                p1PlusOffset = 0
                p1PlusOpacity = 1.0
                withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                    animateP1 = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        p1PlusOffset = -80
                        p1PlusOpacity = 0.0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    animateP1 = false
                }
            } else {
                p2PlusOffset = 0
                p2PlusOpacity = 1.0
                withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                    animateP2 = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        p2PlusOffset = -80
                        p2PlusOpacity = 0.0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    animateP2 = false
                }
            }
            viewModel.incrementScore(for: player)
        }
        .gesture(
            DragGesture(minimumDistance: 15, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.height > 30 {
                        // Swipe down -> decrement score
                        viewModel.decrementScore(for: player)
                    }
                }
        )
    }
    
    // MARK: - Central Floating Control Bar
    
    @ViewBuilder
    private func floatingControlCenter(isLandscape: Bool) -> some View {
        let controlBar = HStack(spacing: 20) {
            // Undo button
            Button {
                viewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(viewModel.canUndo() ? .white : .white.opacity(0.25))
            }
            .disabled(!viewModel.canUndo())
            
            // Swap sides button
            Button {
                viewModel.swapSides()
            } label: {
                Image(systemName: "arrow.left.and.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
            
            // Settings button
            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
            .accessibilityLabel(Localized.settingsTitle)

            // Saved results button
            Button {
                isShowingMatchHistory = true
            } label: {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
            }
            .accessibilityLabel(Localized.matchHistoryTitle)
            
            // Reset button with safety confirmation sheet
            Button {
                isShowingResetConfirm = true
            } label: {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
            .confirmationDialog(Localized.isItalian ? "Sei sicuro di voler azzerare l'incontro?" : "Are you sure you want to reset the match?", isPresented: $isShowingResetConfirm, titleVisibility: .visible) {
                Button(Localized.isItalian ? "Sì, azzera tutto" : "Yes, reset all", role: .destructive) {
                    viewModel.resetMatch()
                }
                Button(Localized.isItalian ? "Annulla" : "Cancel", role: .cancel) {}
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
        
        // Positioning based on orientation (acts like a partition net)
        if isLandscape {
            // Centered vertically, runs down the middle line
            VStack {
                Spacer()
                controlBar
                Spacer()
            }
        } else {
            // Centered horizontally, runs across the middle line
            HStack {
                Spacer()
                controlBar
                Spacer()
            }
        }
    }
    
    // MARK: - Game Over Celebration Screen overlay
    
    @ViewBuilder
    private func gameOverCelebrationView(winner: Player) -> some View {
        let winnerName = winner == .player1 ? viewModel.p1Name : viewModel.p2Name
        let winnerColor = winner == .player1 ? currentTheme.p1Color : currentTheme.p2Color
        
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Trophy Icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 15)
                    .scaleEffect(1.2)
                    .padding(.bottom, 10)
                
                Text(Localized.winnerTitle)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .tracking(4)
                
                Text(winnerName.uppercased())
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(winnerColor)
                    .shadow(color: winnerColor.opacity(0.5), radius: 10)
                
                Text("\(viewModel.p1Score) - \(viewModel.p2Score)")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(Localized.isItalian ? "Match concluso con successo" : "Match successfully completed")
                    .font(.system(.subheadline))
                    .foregroundColor(.gray)
                
                Button {
                    viewModel.resetMatch()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text(Localized.isItalian ? "Nuova Partita" : "New Match")
                    }
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.yellow)
                    .cornerRadius(30)
                    .shadow(color: .yellow.opacity(0.4), radius: 10, y: 5)
                }
                .padding(.top, 20)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(20)
        }
    }
}

struct MatchHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ScoreViewModel
    @State private var isShowingDeleteConfirmation = false
    @State private var didCopyResults = false

    private var records: [MatchRecord] {
        viewModel.matchRecords
    }

    private var completedCount: Int {
        records.filter { $0.winner != nil }.count
    }

    private var interruptedCount: Int {
        records.count - completedCount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.05), Color(white: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Form {
                    if records.isEmpty {
                        Section {
                            emptyState
                                .listRowBackground(Color(white: 0.15))
                        }
                    } else {
                        Section {
                            statsOverview
                                .listRowBackground(Color.clear)
                        }

                        Section {
                            actionsRow
                                .listRowBackground(Color(white: 0.15))
                        }

                        Section(header: Text(Localized.savedResultsHeader).foregroundColor(.gray)) {
                            ForEach(records) { record in
                                MatchRecordRow(record: record)
                                    .listRowBackground(Color(white: 0.15))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.deleteMatchRecord(id: record.id)
                                        } label: {
                                            Label(Localized.deleteRecord, systemImage: "trash.fill")
                                        }
                                    }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Localized.matchHistoryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localized.closeButton) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                Localized.deleteRecordsConfirmTitle,
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Localized.deleteAll, role: .destructive) {
                    viewModel.deleteMatchRecords()
                }
                Button(Localized.isItalian ? "Annulla" : "Cancel", role: .cancel) {}
            } message: {
                Text(Localized.deleteRecordsConfirmMessage)
            }
            .preferredColorScheme(.dark)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))

            Text(Localized.noSavedResults)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
    }

    private var statsOverview: some View {
        HStack(spacing: 10) {
            MatchHistoryStat(
                title: Localized.totalMatches,
                value: "\(records.count)",
                color: .cyan,
                systemImage: "number.circle.fill"
            )

            MatchHistoryStat(
                title: Localized.completedMatches,
                value: "\(completedCount)",
                color: .yellow,
                systemImage: "checkmark.circle.fill"
            )

            MatchHistoryStat(
                title: Localized.interruptedMatches,
                value: "\(interruptedCount)",
                color: .white.opacity(0.62),
                systemImage: "pause.circle.fill"
            )
        }
        .padding(.vertical, 4)
    }

    private var actionsRow: some View {
        HStack(spacing: 12) {
            Button {
                copyMatchHistory()
            } label: {
                Label(didCopyResults ? Localized.copiedResults : Localized.copyResults, systemImage: "doc.on.doc.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(records.isEmpty)

            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label(Localized.deleteRecords, systemImage: "trash.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(records.isEmpty)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    private func copyMatchHistory() {
        UIPasteboard.general.string = matchHistoryExportText
        didCopyResults = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            didCopyResults = false
        }
    }

    private var matchHistoryExportText: String {
        let header = [
            "Data",
            "Giocatore 1",
            "Giocatore 2",
            "Set",
            "Punti",
            "Vincitore",
            "Stato",
            "Regole"
        ].joined(separator: ";")

        let rows = records.map { record in
            [
                escaped(record.date.formatted(date: .abbreviated, time: .shortened)),
                escaped(record.p1Name),
                escaped(record.p2Name),
                escaped("\(record.p1Sets)-\(record.p2Sets)"),
                escaped("\(record.p1Score)-\(record.p2Score)"),
                escaped(winnerName(for: record) ?? "-"),
                escaped(record.winner == nil ? Localized.interruptedMatch : Localized.completedMatches),
                escaped("\(record.targetScore) pt, \(record.bestOfSets) set, \(record.winByTwo ? "deuce" : "no deuce")")
            ].joined(separator: ";")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private func escaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func winnerName(for record: MatchRecord) -> String? {
        switch record.winner {
        case .player1:
            return record.p1Name
        case .player2:
            return record.p2Name
        case nil:
            return nil
        }
    }
}

private struct MatchHistoryStat: View {
    let title: String
    let value: String
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)

            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.white)
                .monospacedDigit()

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct MatchRecordRow: View {
    let record: MatchRecord

    private var winnerName: String? {
        switch record.winner {
        case .player1:
            return record.p1Name
        case .player2:
            return record.p2Name
        case nil:
            return nil
        }
    }

    private var statusText: String {
        if let winnerName {
            return "\(Localized.winnerLabel): \(winnerName)"
        }

        return Localized.interruptedMatch
    }

    private var statusColor: Color {
        record.winner == nil ? .white.opacity(0.55) : .yellow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label(record.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(statusText)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 10) {
                playerName(record.p1Name, isLeading: true)

                Spacer(minLength: 4)

                VStack(spacing: 2) {
                    Text("\(record.p1Sets) - \(record.p2Sets)")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text(Localized.setsLabel.uppercased())
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.42))
                        .tracking(1.2)
                }
                .frame(minWidth: 76)

                Spacer(minLength: 4)

                playerName(record.p2Name, isLeading: false)
            }

            HStack(spacing: 8) {
                resultTag("\(Localized.pointsLabel): \(record.p1Score)-\(record.p2Score)", systemImage: "circle.grid.cross.fill")
                resultTag("\(record.targetScore) pt", systemImage: "flag.checkered")
                resultTag(record.winByTwo ? Localized.deuceOn : Localized.deuceOff, systemImage: "arrow.left.and.right")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func playerName(_ name: String, isLeading: Bool) -> some View {
        Text(name)
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(.white.opacity(0.82))
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .multilineTextAlignment(isLeading ? .leading : .trailing)
            .frame(maxWidth: 100, alignment: isLeading ? .leading : .trailing)
    }

    private func resultTag(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.66))
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(Color.white.opacity(0.07))
            )
    }
}
