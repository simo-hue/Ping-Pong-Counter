import SwiftUI
import Combine

enum Player: String, Codable {
    case player1
    case player2
}

struct GameSnapshot: Equatable {
    let p1Score: Int
    let p2Score: Int
    let p1Sets: Int
    let p2Sets: Int
    let currentServer: Player
    let startingServerOfSet: Player
    let winner: Player?
}

@MainActor
final class ScoreViewModel: ObservableObject {
    // Game Rules Settings
    @Published var targetScore: Int = 11 { // 11 or 21 standard
        didSet { resetMatch() }
    }
    @Published var winByTwo: Bool = true
    @Published var bestOfSets: Int = 3 { // 1, 3, or 5 sets
        didSet { resetMatch() }
    }
    @Published var serveRotationInterval: Int = 2 { // changes to 1 in deuce or 5 for 21-point game
        didSet { updateServer() }
    }
    
    // Player Details
    @Published var p1Name: String = "Giocatore 1" { didSet { syncWithWatch() } }
    @Published var p2Name: String = "Giocatore 2" { didSet { syncWithWatch() } }
    
    // Current Match Scores
    @Published var p1Score: Int = 0 { didSet { syncWithWatch() } }
    @Published var p2Score: Int = 0 { didSet { syncWithWatch() } }
    @Published var p1Sets: Int = 0 { didSet { syncWithWatch() } }
    @Published var p2Sets: Int = 0 { didSet { syncWithWatch() } }
    
    // Server state
    @Published var startingServerOfMatch: Player = .player1 {
        didSet {
            if p1Score == 0 && p2Score == 0 && p1Sets == 0 && p2Sets == 0 {
                startingServerOfSet = startingServerOfMatch
                currentServer = startingServerOfMatch
            }
            syncWithWatch()
        }
    }
    @Published var startingServerOfSet: Player = .player1 { didSet { syncWithWatch() } }
    @Published var currentServer: Player = .player1 { didSet { syncWithWatch() } }
    
    // Visual theme selection
    @Published var themeIndex: Int = 0
    
    // Match Winner
    @Published var winner: Player? = nil { didSet { syncWithWatch() } }
    
    // State history for Undo
    private var history: [GameSnapshot] = []
    
    // Voice announcements
    @Published var isVoiceEnabled: Bool = false {
        didSet {
            SpeechManager.shared.isVoiceEnabled = isVoiceEnabled
        }
    }
    
    init() {
        WatchConnector.shared.configure(with: self)
        resetMatch()
    }
    
    // MARK: - Core Operations
    
    func incrementScore(for player: Player) {
        guard winner == nil else { return }
        
        saveToHistory()
        
        if player == .player1 {
            p1Score += 1
            HapticManager.shared.play(.scoreIncrement)
        } else {
            p2Score += 1
            HapticManager.shared.play(.scoreIncrement)
        }
        
        checkSetEnd()
        updateServer()
        announceState()
    }
    
    func decrementScore(for player: Player) {
        guard winner == nil else { return }
        
        if player == .player1 {
            guard p1Score > 0 else { return }
            saveToHistory()
            p1Score -= 1
            HapticManager.shared.play(.scoreDecrement)
        } else {
            guard p2Score > 0 else { return }
            saveToHistory()
            p2Score -= 1
            HapticManager.shared.play(.scoreDecrement)
        }
        
        updateServer()
        announceState()
    }
    
    func undo() {
        guard let previousState = history.popLast() else { return }
        
        p1Score = previousState.p1Score
        p2Score = previousState.p2Score
        p1Sets = previousState.p1Sets
        p2Sets = previousState.p2Sets
        currentServer = previousState.currentServer
        startingServerOfSet = previousState.startingServerOfSet
        winner = previousState.winner
        
        HapticManager.shared.play(.scoreDecrement)
        
        // Announce score again after undoing
        let serverName = currentServer == .player1 ? p1Name : p2Name
        SpeechManager.shared.speak("Annullato. Punteggio: \(p1Score) a \(p2Score). Batte \(serverName).")
    }
    
    func canUndo() -> Bool {
        return !history.isEmpty
    }
    
    func resetMatch() {
        saveToHistory() // let them undo a reset if clicked by accident!
        
        p1Score = 0
        p2Score = 0
        p1Sets = 0
        p2Sets = 0
        winner = nil
        startingServerOfSet = startingServerOfMatch
        currentServer = startingServerOfMatch
        history.removeAll()
        
        HapticManager.shared.play(.reset)
        SpeechManager.shared.speak("Incontro azzerato. Nuova partita! Batte \(startingServerOfMatch == .player1 ? p1Name : p2Name).")
    }
    
    func swapSides() {
        // Swap player names and their active set counts and scores so players can change sides on the physical table
        let tempName = p1Name
        p1Name = p2Name
        p2Name = tempName
        
        let tempScore = p1Score
        p1Score = p2Score
        p2Score = tempScore
        
        let tempSets = p1Sets
        p1Sets = p2Sets
        p2Sets = tempSets
        
        // Also swap server states
        startingServerOfMatch = startingServerOfMatch == .player1 ? .player2 : .player1
        startingServerOfSet = startingServerOfSet == .player1 ? .player2 : .player1
        currentServer = currentServer == .player1 ? .player2 : .player1
        
        // Re-map history states to new swap
        history = history.map { snapshot in
            GameSnapshot(
                p1Score: snapshot.p2Score,
                p2Score: snapshot.p1Score,
                p1Sets: snapshot.p2Sets,
                p2Sets: snapshot.p1Sets,
                currentServer: snapshot.currentServer == .player1 ? .player2 : .player1,
                startingServerOfSet: snapshot.startingServerOfSet == .player1 ? .player2 : .player1,
                winner: snapshot.winner == nil ? nil : (snapshot.winner == .player1 ? .player2 : .player1)
            )
        }
        
        HapticManager.shared.play(.serveChange)
        SpeechManager.shared.speak("Cambio campo! Adesso \(p1Name) a sinistra e \(p2Name) a destra.")
    }
    
    // MARK: - Server Logic
    
    private func updateServer() {
        let totalPoints = p1Score + p2Score
        let isDeuceGame = isDeuce()
        
        // Table Tennis rule: if both players reach targetScore - 1 (e.g. 10-10 deuce),
        // serve rotation interval becomes 1 serve per player instead of 2.
        let interval = isDeuceGame ? 1 : serveRotationInterval
        
        let servesPlayed = totalPoints / interval
        
        // Determine player serving
        if startingServerOfSet == .player1 {
            currentServer = (servesPlayed % 2 == 0) ? .player1 : .player2
        } else {
            currentServer = (servesPlayed % 2 == 0) ? .player2 : .player1
        }
    }
    
    // MARK: - Match Rules Engine
    
    private func checkSetEnd() {
        let setsNeededToWin = Int(ceil(Double(bestOfSets) / 2.0))
        
        if isSetWon(pScore: p1Score, oScore: p2Score) {
            p1Sets += 1
            if p1Sets >= setsNeededToWin {
                winner = .player1
                HapticManager.shared.play(.gameWon)
            } else {
                HapticManager.shared.play(.serveChange)
                startNewSet()
            }
        } else if isSetWon(pScore: p2Score, oScore: p1Score) {
            p2Sets += 1
            if p2Sets >= setsNeededToWin {
                winner = .player2
                HapticManager.shared.play(.gameWon)
            } else {
                HapticManager.shared.play(.serveChange)
                startNewSet()
            }
        }
    }
    
    private func isSetWon(pScore: Int, oScore: Int) -> Bool {
        if pScore >= targetScore {
            if winByTwo {
                return (pScore - oScore) >= 2
            } else {
                return true
            }
        }
        return false
    }
    
    private func startNewSet() {
        p1Score = 0
        p2Score = 0
        
        // ITTF Rule: Alternating initial server for each set
        let lastSetStarter = startingServerOfSet
        startingServerOfSet = lastSetStarter == .player1 ? .player2 : .player1
        currentServer = startingServerOfSet
        
        SpeechManager.shared.speak("Fine set! Set per \(startingServerOfSet == .player1 ? p2Name : p1Name). Inizio del set successivo. Batte \(currentServer == .player1 ? p1Name : p2Name).")
    }
    
    private func isDeuce() -> Bool {
        return p1Score >= (targetScore - 1) && p2Score >= (targetScore - 1)
    }
    
    private func isMatchPoint() -> Bool {
        let setsNeededToWin = Int(ceil(Double(bestOfSets) / 2.0))
        
        // P1 is 1 point away from winning match
        let p1IsSetPoint = p1Score >= (targetScore - 1) && p1Score > p2Score && (p1Score - p2Score >= 1 || !winByTwo)
        let p1NearMatchWin = (p1Sets == setsNeededToWin - 1) && p1IsSetPoint
        
        // P2 is 1 point away from winning match
        let p2IsSetPoint = p2Score >= (targetScore - 1) && p2Score > p1Score && (p2Score - p1Score >= 1 || !winByTwo)
        let p2NearMatchWin = (p2Sets == setsNeededToWin - 1) && p2IsSetPoint
        
        if p1NearMatchWin || p2NearMatchWin {
            HapticManager.shared.play(.matchPoint)
            return true
        }
        
        return false
    }
    
    private func isSetPoint() -> Bool {
        // Set point represents set completion target point
        let p1IsSetPoint = p1Score >= (targetScore - 1) && p1Score > p2Score && (p1Score - p2Score >= 1 || !winByTwo)
        let p2IsSetPoint = p2Score >= (targetScore - 1) && p2Score > p1Score && (p2Score - p1Score >= 1 || !winByTwo)
        return p1IsSetPoint || p2IsSetPoint
    }
    
    // MARK: - State Callouts
    
    private func announceState() {
        let serverName = currentServer == .player1 ? p1Name : p2Name
        let winnerName = winner == nil ? nil : (winner == .player1 ? p1Name : p2Name)
        
        SpeechManager.shared.announceScore(
            p1Name: p1Name,
            p1Score: p1Score,
            p2Name: p2Name,
            p2Score: p2Score,
            serverName: serverName,
            isMatchPoint: isMatchPoint(),
            isSetPoint: isSetPoint(),
            isDeuce: isDeuce() && p1Score == p2Score,
            winnerName: winnerName
        )
    }
    
    // MARK: - History Snapshotting
    
    private func saveToHistory() {
        let snapshot = GameSnapshot(
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer,
            startingServerOfSet: startingServerOfSet,
            winner: winner
        )
        history.append(snapshot)
        
        // Cap history size to 30 steps to save memory
        if history.count > 30 {
            history.removeFirst()
        }
    }
    
    private func syncWithWatch() {
        WatchConnector.shared.sendStateToWatch(
            p1Name: p1Name,
            p1Score: p1Score,
            p2Name: p2Name,
            p2Score: p2Score,
            currentServer: currentServer,
            winner: winner
        )
        
        // Push real-time updates to Lock Screen & Dynamic Island (Live Activities)
        LiveActivityManager.shared.updateOrCreateActivity(
            p1Name: p1Name,
            p2Name: p2Name,
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer == .player1 ? "player1" : "player2",
            winner: winner == nil ? nil : (winner == .player1 ? "player1" : "player2")
        )
    }
}

// MARK: - WatchConnectivity Bridge
import WatchConnectivity

final class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnector()
    
    private var session: WCSession?
    private weak var viewModel: ScoreViewModel?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    @MainActor
    func configure(with viewModel: ScoreViewModel) {
        self.viewModel = viewModel
    }
    
    @MainActor
    func sendStateToWatch(p1Name: String, p1Score: Int, p2Name: String, p2Score: Int, currentServer: Player, winner: Player?) {
        guard let session = session, session.isReachable else { return }
        
        let data: [String: Any] = [
            "p1Name": p1Name,
            "p1Score": p1Score,
            "p2Name": p2Name,
            "p2Score": p2Score,
            "currentServer": currentServer.rawValue,
            "winner": winner?.rawValue ?? ""
        ]
        
        session.sendMessage(data, replyHandler: nil, errorHandler: { error in
            print("Error sending state to watch: \(error.localizedDescription)")
        })
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                guard let viewModel = self.viewModel else { return }
                
                if let action = message["action"] as? String {
                    switch action {
                    case "increment":
                        if let playerStr = message["player"] as? String, let player = Player(rawValue: playerStr) {
                            viewModel.incrementScore(for: player)
                        }
                    case "decrement":
                        if let playerStr = message["player"] as? String, let player = Player(rawValue: playerStr) {
                            viewModel.decrementScore(for: player)
                        }
                    case "undo":
                        viewModel.undo()
                    case "reset":
                        viewModel.resetMatch()
                    case "swapSides":
                        viewModel.swapSides()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            session.activate()
        }
    }
    #endif
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated successfully")
        }
    }
}
