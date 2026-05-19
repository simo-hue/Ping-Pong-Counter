import ActivityKit
import Foundation

public struct PingPongAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var p1Score: Int
        public var p2Score: Int
        public var p1Sets: Int
        public var p2Sets: Int
        public var currentServer: String // "player1" or "player2"
        public var winner: String? // "player1", "player2" or nil
        public var themeIndex: Int // 0, 1, or 2
        
        public init(p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int = 0) {
            self.p1Score = p1Score
            self.p2Score = p2Score
            self.p1Sets = p1Sets
            self.p2Sets = p2Sets
            self.currentServer = currentServer
            self.winner = winner
            self.themeIndex = themeIndex
        }
    }

    public var p1Name: String
    public var p2Name: String
    
    public init(p1Name: String, p2Name: String) {
        self.p1Name = p1Name
        self.p2Name = p2Name
    }
}
