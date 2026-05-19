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
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sendIncrement(player: String) {
        send(action: "increment", player: player)
    }
    
    func sendDecrement(player: String) {
        send(action: "decrement", player: player)
    }
    
    func sendUndo() {
        send(action: "undo")
    }
    
    func sendReset() {
        send(action: "reset")
    }
    
    private func send(action: String, player: String? = nil) {
        guard let session = session, session.isReachable else { return }
        
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
