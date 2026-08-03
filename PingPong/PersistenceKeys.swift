import Foundation

/// Every UserDefaults key the app persists.
///
/// Single source of truth on purpose: `SharedStore` has to be able to carry the whole set into an
/// App Group container, and a hand-maintained second list would drift the moment a key is added —
/// dropping, say, the serve baseline or the in-progress set history on an upgrade.
enum PersistenceKeys {
    static let targetScore = "targetScore"
    static let winByTwo = "winByTwo"
    static let bestOfSets = "bestOfSets"
    static let serveRotationInterval = "serveRotationInterval"
    static let p1Name = "p1Name"
    static let p2Name = "p2Name"
    static let startingServerOfMatch = "startingServerOfMatch"
    static let startingServerOfSet = "startingServerOfSet"
    static let currentServer = "currentServer"
    static let p1Score = "p1Score"
    static let p2Score = "p2Score"
    static let p1Sets = "p1Sets"
    static let p2Sets = "p2Sets"
    static let winner = "winner"
    static let themeIndex = "themeIndex"
    static let isVoiceEnabled = "isVoiceEnabled"
    static let matchRecords = "matchRecords"
    static let keepScreenAwake = "keepScreenAwake"
    static let isSoundEnabled = "isSoundEnabled"
    static let hapticIntensity = "hapticIntensity"
    static let matchClock = "matchClock"
    static let showMatchTimer = "showMatchTimer"
    static let completedSets = "completedSets"
    static let currentSetRallies = "currentSetRallies"
    static let isDoubles = "isDoubles"
    static let doublesLineup = "doublesLineup"
    static let roster = "roster"
    static let p1RosterId = "p1RosterId"
    static let p2RosterId = "p2RosterId"

    /// Keep in step with the declarations above — the migration copies exactly this set.
    static let all: [String] = [
        targetScore, winByTwo, bestOfSets, serveRotationInterval,
        p1Name, p2Name,
        startingServerOfMatch, startingServerOfSet, currentServer,
        p1Score, p2Score, p1Sets, p2Sets, winner,
        themeIndex, isVoiceEnabled, matchRecords,
        keepScreenAwake, isSoundEnabled, hapticIntensity,
        matchClock, showMatchTimer,
        completedSets, currentSetRallies,
        isDoubles, doublesLineup,
        roster, p1RosterId, p2RosterId
    ]
}
