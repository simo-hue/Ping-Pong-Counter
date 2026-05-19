import WatchConnectivity
import Combine

final class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnector()
    
    @Published var p1Name: String = "Giocatore 1"
    @Published var p2Name: String = "Giocatore 2"
    @Published var p1Score: Int = 0
    @Published var p2Score: Int = 0
    @Published var currentServer: String = "player1"
    @Published var winner: String = ""
    
    private var session: WCSession?
    
    private struct WatchSnapshot {
        let p1Score: Int
        let p2Score: Int
        let currentServer: String
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
            currentServer = previous.currentServer
            winner = previous.winner
        }
        send(action: "undo")
    }
    
    func sendReset() {
        saveToHistory()
        p1Score = 0
        p2Score = 0
        currentServer = "player1"
        winner = ""
        history.removeAll()
        send(action: "reset")
    }
    
    private func saveToHistory() {
        let snapshot = WatchSnapshot(
            p1Score: p1Score,
            p2Score: p2Score,
            currentServer: currentServer,
            winner: winner
        )
        history.append(snapshot)
        if history.count > 30 {
            history.removeFirst()
        }
    }
    
    private func updateLocalRules() {
        let total = p1Score + p2Score
        
        // Serve rotation switches every 2 serves normally, or every 1 in deuce (10-10 or more)
        let isDeuce = p1Score >= 10 && p2Score >= 10
        let interval = isDeuce ? 1 : 2
        let totalServes = total / interval
        
        currentServer = (totalServes % 2 == 0) ? "player1" : "player2"
        
        // Winner check (standard table tennis rules: first to 11 points by 2)
        if p1Score >= 11 && (p1Score - p2Score) >= 2 {
            winner = "player1"
        } else if p2Score >= 11 && (p2Score - p1Score) >= 2 {
            winner = "player2"
        } else {
            winner = ""
        }
    }
    
    private func send(action: String, player: String? = nil) {
        guard let session = session else { return }
        
        var data: [String: Any] = ["action": action]
        if let player = player {
            data["player"] = player
        }
        
        session.sendMessage(data, replyHandler: nil, errorHandler: { error in
            print("Watch error sending message: \(error.localizedDescription)")
        })
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Overwrite with master iOS state when synced
            if let p1Name = message["p1Name"] as? String { self.p1Name = p1Name }
            if let p1Score = message["p1Score"] as? String { self.p1Score = Int(p1Score) ?? 0 }
            if let p1ScoreInt = message["p1Score"] as? Int { self.p1Score = p1ScoreInt }
            if let p2Name = message["p2Name"] as? String { self.p2Name = p2Name }
            if let p2Score = message["p2Score"] as? String { self.p2Score = Int(p2Score) ?? 0 }
            if let p2ScoreInt = message["p2Score"] as? Int { self.p2Score = p2ScoreInt }
            if let currentServer = message["currentServer"] as? String { self.currentServer = currentServer }
            if let winner = message["winner"] as? String { self.winner = winner }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed on Watch: \(error.localizedDescription)")
        } else {
            print("WCSession activated successfully on Watch")
        }
    }
}
