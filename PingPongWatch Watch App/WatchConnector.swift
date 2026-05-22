@preconcurrency import WatchConnectivity
import Combine

final class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnector()
    
    @Published var p1Name: String = "Giocatore 1"
    @Published var p2Name: String = "Giocatore 2"
    @Published var p1Score: Int = 0
    @Published var p2Score: Int = 0
    @Published var p1Sets: Int = 0
    @Published var p2Sets: Int = 0
    @Published var currentServer: String = "player1"
    @Published var startingServerOfMatch: String = "player1"
    @Published var startingServerOfSet: String = "player1"
    @Published var winner: String = ""
    @Published var targetScore: Int = 11
    @Published var winByTwo: Bool = true
    @Published var bestOfSets: Int = 3
    @Published var serveRotationInterval: Int = 2
    
    private var session: WCSession?
    
    private struct WatchSnapshot {
        let p1Score: Int
        let p2Score: Int
        let p1Sets: Int
        let p2Sets: Int
        let currentServer: String
        let startingServerOfSet: String
        let winner: String
    }
    private var history: [WatchSnapshot] = []
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sendIncrement(player: String) {
        guard winner.isEmpty else { return }
        
        saveToHistory()
        
        if player == "player1" {
            p1Score += 1
        } else {
            p2Score += 1
        }
        
        updateLocalRules()
        send(action: "increment", player: player)
    }
    
    func sendDecrement(player: String) {
        guard winner.isEmpty else { return }
        guard (player == "player1" ? p1Score : p2Score) > 0 else { return }
        
        saveToHistory()
        
        if player == "player1" {
            if p1Score > 0 { p1Score -= 1 }
        } else {
            if p2Score > 0 { p2Score -= 1 }
        }
        
        updateLocalRules()
        send(action: "decrement", player: player)
    }
    
    func sendUndo() {
        if let previous = history.popLast() {
            p1Score = previous.p1Score
            p2Score = previous.p2Score
            p1Sets = previous.p1Sets
            p2Sets = previous.p2Sets
            currentServer = previous.currentServer
            startingServerOfSet = previous.startingServerOfSet
            winner = previous.winner
        }
        send(action: "undo")
    }
    
    func sendReset() {
        saveToHistory()
        p1Score = 0
        p2Score = 0
        p1Sets = 0
        p2Sets = 0
        currentServer = startingServerOfMatch
        startingServerOfSet = startingServerOfMatch
        winner = ""
        send(action: "reset")
    }
    
    private func saveToHistory() {
        let snapshot = WatchSnapshot(
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer,
            startingServerOfSet: startingServerOfSet,
            winner: winner
        )
        history.append(snapshot)
        if history.count > 30 {
            history.removeFirst()
        }
    }
    
    private func updateLocalRules() {
        if completeLocalSetIfNeeded() {
            return
        }

        updateLocalServer()
    }

    private func completeLocalSetIfNeeded() -> Bool {
        let setWinner: String?
        if isSetWon(playerScore: p1Score, opponentScore: p2Score) {
            setWinner = "player1"
        } else if isSetWon(playerScore: p2Score, opponentScore: p1Score) {
            setWinner = "player2"
        } else {
            setWinner = nil
        }

        guard let setWinner else { return false }

        if setWinner == "player1" {
            p1Sets += 1
        } else {
            p2Sets += 1
        }

        let setsNeededToWin = max(1, bestOfSets)
        if p1Sets >= setsNeededToWin {
            winner = "player1"
        } else if p2Sets >= setsNeededToWin {
            winner = "player2"
        } else {
            p1Score = 0
            p2Score = 0
            startingServerOfSet = toggledPlayer(startingServerOfSet)
            currentServer = startingServerOfSet
            winner = ""
        }

        return true
    }

    private func isSetWon(playerScore: Int, opponentScore: Int) -> Bool {
        guard playerScore >= targetScore else { return false }
        return !winByTwo || playerScore - opponentScore >= 2
    }

    private func updateLocalServer() {
        let total = p1Score + p2Score
        
        // Mirror the iPhone rules optimistically until the authoritative state arrives.
        let isDeuce = p1Score >= targetScore - 1 && p2Score >= targetScore - 1
        let interval = isDeuce ? 1 : max(1, serveRotationInterval)
        let totalServes = total / interval
        
        if startingServerOfSet == "player1" {
            currentServer = (totalServes % 2 == 0) ? "player1" : "player2"
        } else {
            currentServer = (totalServes % 2 == 0) ? "player2" : "player1"
        }
        winner = ""
    }

    private func toggledPlayer(_ player: String) -> String {
        player == "player1" ? "player2" : "player1"
    }
    
    private func send(action: String, player: String? = nil) {
        guard let session = session else { return }
        
        var data: [String: Any] = ["action": action]
        if let player = player {
            data["player"] = player
        }
        
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil, errorHandler: { error in
                self.debugLog("Watch error sending message: \(error.localizedDescription)")
            })
        } else {
            session.transferUserInfo(data)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        applyState(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        applyState(applicationContext)
    }

    private nonisolated func applyState(_ message: [String: Any]) {
        DispatchQueue.main.async {
            // Overwrite with master iOS state when synced
            if let p1Name = message["p1Name"] as? String { self.p1Name = p1Name }
            if let p1Score = message["p1Score"] as? String { self.p1Score = Int(p1Score) ?? 0 }
            if let p1ScoreInt = message["p1Score"] as? Int { self.p1Score = p1ScoreInt }
            if let p1Sets = message["p1Sets"] as? Int { self.p1Sets = p1Sets }
            if let p2Name = message["p2Name"] as? String { self.p2Name = p2Name }
            if let p2Score = message["p2Score"] as? String { self.p2Score = Int(p2Score) ?? 0 }
            if let p2ScoreInt = message["p2Score"] as? Int { self.p2Score = p2ScoreInt }
            if let p2Sets = message["p2Sets"] as? Int { self.p2Sets = p2Sets }
            if let currentServer = message["currentServer"] as? String { self.currentServer = currentServer }
            if let startingServerOfMatch = message["startingServerOfMatch"] as? String { self.startingServerOfMatch = startingServerOfMatch }
            if let startingServerOfSet = message["startingServerOfSet"] as? String { self.startingServerOfSet = startingServerOfSet }
            if let winner = message["winner"] as? String { self.winner = winner }
            if let targetScore = message["targetScore"] as? Int { self.targetScore = [11, 21].contains(targetScore) ? targetScore : 11 }
            if let winByTwo = message["winByTwo"] as? Bool { self.winByTwo = winByTwo }
            if let bestOfSets = message["bestOfSets"] as? Int { self.bestOfSets = [1, 3, 5].contains(bestOfSets) ? bestOfSets : 3 }
            if let serveRotationInterval = message["serveRotationInterval"] as? Int {
                self.serveRotationInterval = [2, 5].contains(serveRotationInterval) ? serveRotationInterval : 2
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            debugLog("WCSession activation failed on Watch: \(error.localizedDescription)")
        } else {
            debugLog("WCSession activated successfully on Watch")
        }
    }

    private nonisolated func debugLog(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}
