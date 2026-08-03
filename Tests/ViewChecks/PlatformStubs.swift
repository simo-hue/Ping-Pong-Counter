import Foundation

// Minimal stand-ins for the iOS-only frameworks ScoreViewModel touches, so the file can be
// TYPE-CHECKED on macOS. `swiftc -parse` only checks syntax — it happily accepts a call to a
// property that does not exist in the enclosing type, which is exactly the class of mistake that
// reaches the Mac mini as a build failure.
//
// These stubs deliberately mirror only the SHAPE of each API, never its behaviour. Nothing here is
// compiled into the app.

// MARK: - WatchConnectivity

enum WCSessionActivationState {
    case notActivated
    case inactive
    case activated
}

protocol WCSessionDelegate: AnyObject {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any])
}

final class WCSession {
    static let `default` = WCSession()
    static func isSupported() -> Bool { false }

    weak var delegate: WCSessionDelegate?
    var activationState: WCSessionActivationState = .notActivated
    var isPaired = false
    var isWatchAppInstalled = false
    var isReachable = false

    func activate() {}
    func updateApplicationContext(_ context: [String: Any]) throws {}
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {}
    func transferUserInfo(_ userInfo: [String: Any]) {}
}

// MARK: - Feedback managers (UIKit / AudioToolbox / AVFoundation backed in the real app)

enum HapticPattern {
    case scoreIncrement
    case scoreDecrement
    case serveChange
    case matchPoint
    case gameWon
    case reset
}

enum HapticIntensity: String, CaseIterable, Codable {
    case off
    case light
    case full
}

final class HapticManager {
    static let shared = HapticManager()
    var intensity: HapticIntensity = .full
    func play(_ pattern: HapticPattern) {}
}

enum SoundEffect {
    case point
    case undo
    case serveChange
    case setWon
    case matchWon
}

final class SoundManager {
    static let shared = SoundManager()
    var isSoundEnabled = false
    func play(_ effect: SoundEffect) {}
}

struct PointAlert {
    let name: String
    let ownScore: Int
    let opponentScore: Int
}

final class SpeechManager {
    static let shared = SpeechManager()
    var isVoiceEnabled = false

    func speak(_ text: String, immediate: Bool = true) {}

    func announceScore(
        p1Name: String,
        p1Score: Int,
        p2Name: String,
        p2Score: Int,
        serverName: String,
        matchPoint: PointAlert?,
        setPoint: PointAlert?,
        isDeuce: Bool,
        winnerName: String?
    ) {}
}

// MARK: - ActivityKit

final class LiveActivityManager {
    static let shared = LiveActivityManager()

    func updateOrCreateActivity(
        p1Name: String,
        p2Name: String,
        p1Score: Int,
        p2Score: Int,
        p1Sets: Int,
        p2Sets: Int,
        currentServer: String,
        winner: String? = nil,
        themeIndex: Int,
        servingName: String? = nil
    ) {}

    func endLiveActivity() {}
}
