import Foundation
import Combine
@preconcurrency import WatchConnectivity

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

struct MatchRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let p1Name: String
    let p2Name: String
    let p1Score: Int
    let p2Score: Int
    let p1Sets: Int
    let p2Sets: Int
    let winner: Player?
    let targetScore: Int
    let bestOfSets: Int
    let winByTwo: Bool
}

@MainActor
final class ScoreViewModel: ObservableObject {
    private enum DefaultsKey {
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
    }

    private static let validTargetScores = Set([11, 21])
    private static let validBestOfSets = Set([1, 3, 5])
    private static let validServeRotationIntervals = Set([2, 5])
    private static let validThemeRange = 0...2

    // Game Rules Settings
    @Published var targetScore: Int = 11 { // 11 or 21 standard
        didSet {
            guard Self.validTargetScores.contains(targetScore) else {
                targetScore = oldValue
                return
            }
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(targetScore, forKey: DefaultsKey.targetScore)
            resetMatch(recordedTargetScore: oldValue)
        }
    }
    @Published var winByTwo: Bool = true {
        didSet {
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(winByTwo, forKey: DefaultsKey.winByTwo)
            syncWithWatch()
        }
    }
    @Published var bestOfSets: Int = 3 { // 1, 3, or 5 sets to win
        didSet {
            guard Self.validBestOfSets.contains(bestOfSets) else {
                bestOfSets = oldValue
                return
            }
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(bestOfSets, forKey: DefaultsKey.bestOfSets)
            resetMatch(recordedBestOfSets: oldValue)
        }
    }
    @Published var serveRotationInterval: Int = 2 { // changes to 1 in deuce or 5 for 21-point game
        didSet {
            guard Self.validServeRotationIntervals.contains(serveRotationInterval) else {
                serveRotationInterval = oldValue
                return
            }
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(serveRotationInterval, forKey: DefaultsKey.serveRotationInterval)
            performStateMutation {
                updateServer()
            }
        }
    }
    
    // Player Details
    @Published var p1Name: String = Localized.defaultP1Name {
        didSet {
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(p1Name, forKey: DefaultsKey.p1Name)
            stateDidChange()
        }
    }
    @Published var p2Name: String = Localized.defaultP2Name {
        didSet {
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(p2Name, forKey: DefaultsKey.p2Name)
            stateDidChange()
        }
    }
    
    // Current Match Scores
    @Published var p1Score: Int = 0 { didSet { stateDidChange() } }
    @Published var p2Score: Int = 0 { didSet { stateDidChange() } }
    @Published var p1Sets: Int = 0 { didSet { stateDidChange() } }
    @Published var p2Sets: Int = 0 { didSet { stateDidChange() } }
    
    // Server state
    @Published var startingServerOfMatch: Player = .player1 {
        didSet {
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(startingServerOfMatch.rawValue, forKey: DefaultsKey.startingServerOfMatch)
            if p1Score == 0 && p2Score == 0 && p1Sets == 0 && p2Sets == 0 {
                if isApplyingStateBatch {
                    startingServerOfSet = startingServerOfMatch
                    currentServer = startingServerOfMatch
                } else {
                    performStateMutation {
                        startingServerOfSet = startingServerOfMatch
                        currentServer = startingServerOfMatch
                    }
                }
            } else {
                stateDidChange()
            }
        }
    }
    @Published var startingServerOfSet: Player = .player1 { didSet { stateDidChange() } }
    @Published var currentServer: Player = .player1 { didSet { stateDidChange() } }
    
    // Visual theme selection
    @Published var themeIndex: Int = 0 {
        didSet {
            guard Self.validThemeRange.contains(themeIndex) else {
                themeIndex = oldValue
                return
            }
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(themeIndex, forKey: DefaultsKey.themeIndex)
            syncLiveActivity()
        }
    }
    
    // Match Winner
    @Published var winner: Player? = nil { didSet { stateDidChange() } }
    
    // State history for Undo
    private var history: [GameSnapshot] = []
    private var isApplyingStateBatch = false
    private var hasFinishedInitialLoad = false

    @Published private(set) var matchRecords: [MatchRecord] = []
    
    // Voice announcements
    @Published var isVoiceEnabled: Bool = false {
        didSet {
            guard hasFinishedInitialLoad else { return }
            UserDefaults.standard.set(isVoiceEnabled, forKey: DefaultsKey.isVoiceEnabled)
            SpeechManager.shared.isVoiceEnabled = isVoiceEnabled
        }
    }
    
    init() {
        // Load persisted settings from UserDefaults or use native defaults
        let defaults = UserDefaults.standard
        self.targetScore = Self.validTargetScores.contains(defaults.integer(forKey: DefaultsKey.targetScore)) ? defaults.integer(forKey: DefaultsKey.targetScore) : 11
        self.winByTwo = defaults.object(forKey: DefaultsKey.winByTwo) as? Bool ?? true
        self.bestOfSets = Self.validBestOfSets.contains(defaults.integer(forKey: DefaultsKey.bestOfSets)) ? defaults.integer(forKey: DefaultsKey.bestOfSets) : 3
        self.serveRotationInterval = Self.validServeRotationIntervals.contains(defaults.integer(forKey: DefaultsKey.serveRotationInterval)) ? defaults.integer(forKey: DefaultsKey.serveRotationInterval) : 2
        self.p1Name = defaults.string(forKey: DefaultsKey.p1Name) ?? Localized.defaultP1Name
        self.p2Name = defaults.string(forKey: DefaultsKey.p2Name) ?? Localized.defaultP2Name
        let savedThemeIndex = defaults.object(forKey: DefaultsKey.themeIndex) as? Int ?? 0
        self.themeIndex = Self.validThemeRange.contains(savedThemeIndex) ? savedThemeIndex : 0
        self.isVoiceEnabled = defaults.object(forKey: DefaultsKey.isVoiceEnabled) as? Bool ?? false
        self.matchRecords = Self.loadMatchRecords(from: defaults)

        if let rawServer = defaults.string(forKey: DefaultsKey.startingServerOfMatch),
           let savedServer = Player(rawValue: rawServer) {
            self.startingServerOfMatch = savedServer
        } else {
            self.startingServerOfMatch = .player1
        }

        self.p1Score = max(0, defaults.integer(forKey: DefaultsKey.p1Score))
        self.p2Score = max(0, defaults.integer(forKey: DefaultsKey.p2Score))
        self.p1Sets = min(max(0, defaults.integer(forKey: DefaultsKey.p1Sets)), bestOfSets)
        self.p2Sets = min(max(0, defaults.integer(forKey: DefaultsKey.p2Sets)), bestOfSets)
        self.startingServerOfSet = Player(rawValue: defaults.string(forKey: DefaultsKey.startingServerOfSet) ?? "") ?? startingServerOfMatch
        self.currentServer = Player(rawValue: defaults.string(forKey: DefaultsKey.currentServer) ?? "") ?? startingServerOfSet
        self.winner = Player(rawValue: defaults.string(forKey: DefaultsKey.winner) ?? "")
        
        // Push initial speech commentary status
        SpeechManager.shared.isVoiceEnabled = self.isVoiceEnabled
        
        WatchConnector.shared.configure(with: self)
        hasFinishedInitialLoad = true
        persistMatchState()
        syncWithWatch()
    }
    
    // MARK: - Core Operations
    
    func incrementScore(for player: Player) {
        guard winner == nil else { return }
        
        saveToHistory()
        
        performStateMutation {
            if player == .player1 {
                p1Score += 1
                HapticManager.shared.play(.scoreIncrement)
            } else {
                p2Score += 1
                HapticManager.shared.play(.scoreIncrement)
            }

            checkSetEnd()
            updateServer()
        }

        announceState()
    }
    
    func decrementScore(for player: Player) {
        guard winner == nil else { return }
        
        guard (player == .player1 ? p1Score : p2Score) > 0 else { return }

        saveToHistory()
        performStateMutation {
            if player == .player1 {
                p1Score -= 1
                HapticManager.shared.play(.scoreDecrement)
            } else {
                p2Score -= 1
                HapticManager.shared.play(.scoreDecrement)
            }

            updateServer()
        }

        announceState()
    }
    
    func undo() {
        guard let previousState = history.popLast() else { return }
        
        performStateMutation {
            p1Score = previousState.p1Score
            p2Score = previousState.p2Score
            p1Sets = previousState.p1Sets
            p2Sets = previousState.p2Sets
            currentServer = previousState.currentServer
            startingServerOfSet = previousState.startingServerOfSet
            winner = previousState.winner
        }
        
        HapticManager.shared.play(.scoreDecrement)
        
        // Announce score again after undoing
        let serverName = currentServer == .player1 ? p1Name : p2Name
        SpeechManager.shared.speak("Annullato. Punteggio: \(p1Score) a \(p2Score). Batte \(serverName).")
    }
    
    func canUndo() -> Bool {
        return !history.isEmpty
    }
    
    func resetMatch(
        recordedTargetScore: Int? = nil,
        recordedBestOfSets: Int? = nil,
        recordedWinByTwo: Bool? = nil
    ) {
        if hasMeaningfulMatchState {
            saveMatchRecord(
                recordedTargetScore: recordedTargetScore,
                recordedBestOfSets: recordedBestOfSets,
                recordedWinByTwo: recordedWinByTwo
            )
            saveToHistory()
        }
        
        performStateMutation {
            p1Score = 0
            p2Score = 0
            p1Sets = 0
            p2Sets = 0
            winner = nil
            startingServerOfSet = startingServerOfMatch
            currentServer = startingServerOfMatch
        }

        HapticManager.shared.play(.reset)
        SpeechManager.shared.speak("Incontro azzerato. Nuova partita! Batte \(startingServerOfMatch == .player1 ? p1Name : p2Name).")
    }
    
    func swapSides() {
        performStateMutation {
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
        }
        
        HapticManager.shared.play(.serveChange)
        SpeechManager.shared.speak("Cambio campo! Adesso \(p1Name) a sinistra e \(p2Name) a destra.")
    }

    func deleteMatchRecords() {
        guard !matchRecords.isEmpty else { return }
        matchRecords.removeAll()
        persistMatchRecords()
        HapticManager.shared.play(.reset)
    }

    func deleteMatchRecord(id: UUID) {
        let originalCount = matchRecords.count
        matchRecords.removeAll { $0.id == id }
        guard matchRecords.count != originalCount else { return }
        persistMatchRecords()
        HapticManager.shared.play(.scoreDecrement)
    }
    
    // MARK: - Server Logic
    
    private func updateServer() {
        let totalPoints = p1Score + p2Score
        let isDeuceGame = isDeuce()
        
        // Table Tennis rule: if both players reach targetScore - 1 (e.g. 10-10 deuce),
        // serve rotation interval becomes 1 serve per player instead of 2.
        let interval = isDeuceGame ? 1 : max(1, serveRotationInterval)
        
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
        let setsNeededToWin = setsRequiredToWin
        
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
        let setsNeededToWin = setsRequiredToWin
        
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
        guard history.last != snapshot else { return }
        history.append(snapshot)
        
        // Cap history size to 30 steps to save memory
        if history.count > 30 {
            history.removeFirst()
        }
    }
    
    private var hasMeaningfulMatchState: Bool {
        p1Score != 0 || p2Score != 0 || p1Sets != 0 || p2Sets != 0 || winner != nil
    }

    private var setsRequiredToWin: Int {
        max(1, bestOfSets)
    }

    private static func loadMatchRecords(from defaults: UserDefaults) -> [MatchRecord] {
        guard let data = defaults.data(forKey: DefaultsKey.matchRecords),
              let records = try? JSONDecoder().decode([MatchRecord].self, from: data) else {
            return []
        }

        return records.sorted { $0.date > $1.date }
    }

    private func saveMatchRecord(
        recordedTargetScore: Int? = nil,
        recordedBestOfSets: Int? = nil,
        recordedWinByTwo: Bool? = nil
    ) {
        let record = MatchRecord(
            id: UUID(),
            date: Date(),
            p1Name: p1Name,
            p2Name: p2Name,
            p1Score: max(0, p1Score),
            p2Score: max(0, p2Score),
            p1Sets: max(0, p1Sets),
            p2Sets: max(0, p2Sets),
            winner: winner,
            targetScore: recordedTargetScore ?? targetScore,
            bestOfSets: recordedBestOfSets ?? bestOfSets,
            winByTwo: recordedWinByTwo ?? winByTwo
        )

        matchRecords.insert(record, at: 0)
        persistMatchRecords()
    }

    private func persistMatchRecords() {
        guard let data = try? JSONEncoder().encode(matchRecords) else { return }
        UserDefaults.standard.set(data, forKey: DefaultsKey.matchRecords)
    }

    private func performStateMutation(_ updates: () -> Void) {
        isApplyingStateBatch = true
        updates()
        isApplyingStateBatch = false
        persistMatchState()
        syncWithWatch()
    }

    private func stateDidChange() {
        guard hasFinishedInitialLoad else { return }
        guard !isApplyingStateBatch else { return }
        persistMatchState()
        syncWithWatch()
    }

    func resyncExternalState() {
        guard hasFinishedInitialLoad else { return }
        syncWithWatch()
    }

    private func persistMatchState() {
        let defaults = UserDefaults.standard
        defaults.set(max(0, p1Score), forKey: DefaultsKey.p1Score)
        defaults.set(max(0, p2Score), forKey: DefaultsKey.p2Score)
        defaults.set(max(0, p1Sets), forKey: DefaultsKey.p1Sets)
        defaults.set(max(0, p2Sets), forKey: DefaultsKey.p2Sets)
        defaults.set(startingServerOfSet.rawValue, forKey: DefaultsKey.startingServerOfSet)
        defaults.set(currentServer.rawValue, forKey: DefaultsKey.currentServer)
        if let winner {
            defaults.set(winner.rawValue, forKey: DefaultsKey.winner)
        } else {
            defaults.removeObject(forKey: DefaultsKey.winner)
        }
    }

    private func syncWithWatch() {
        WatchConnector.shared.sendStateToWatch(
            p1Name: p1Name,
            p1Score: p1Score,
            p1Sets: p1Sets,
            p2Name: p2Name,
            p2Score: p2Score,
            p2Sets: p2Sets,
            currentServer: currentServer,
            startingServerOfMatch: startingServerOfMatch,
            startingServerOfSet: startingServerOfSet,
            winner: winner,
            targetScore: targetScore,
            winByTwo: winByTwo,
            bestOfSets: bestOfSets,
            serveRotationInterval: serveRotationInterval
        )
        
        syncLiveActivity()
    }
    
    func syncLiveActivity() {
        guard hasMeaningfulMatchState else {
            LiveActivityManager.shared.endLiveActivity()
            return
        }

        LiveActivityManager.shared.updateOrCreateActivity(
            p1Name: p1Name,
            p2Name: p2Name,
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer == .player1 ? "player1" : "player2",
            winner: winner == nil ? nil : (winner == .player1 ? "player1" : "player2"),
            themeIndex: themeIndex
        )
    }
}

// MARK: - WatchConnectivity Bridge
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
    func sendStateToWatch(
        p1Name: String,
        p1Score: Int,
        p1Sets: Int,
        p2Name: String,
        p2Score: Int,
        p2Sets: Int,
        currentServer: Player,
        startingServerOfMatch: Player,
        startingServerOfSet: Player,
        winner: Player?,
        targetScore: Int,
        winByTwo: Bool,
        bestOfSets: Int,
        serveRotationInterval: Int
    ) {
        guard let session else { return }
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        
        let data: [String: Any] = [
            "p1Name": p1Name,
            "p1Score": p1Score,
            "p1Sets": p1Sets,
            "p2Name": p2Name,
            "p2Score": p2Score,
            "p2Sets": p2Sets,
            "currentServer": currentServer.rawValue,
            "startingServerOfMatch": startingServerOfMatch.rawValue,
            "startingServerOfSet": startingServerOfSet.rawValue,
            "winner": winner?.rawValue ?? "",
            "targetScore": targetScore,
            "winByTwo": winByTwo,
            "bestOfSets": bestOfSets,
            "serveRotationInterval": serveRotationInterval
        ]

        do {
            try session.updateApplicationContext(data)
        } catch {
            debugLog("Error updating watch application context: \(error.localizedDescription)")
        }

        guard session.isReachable else { return }
        
        session.sendMessage(data, replyHandler: nil, errorHandler: { error in
            self.debugLog("Error sending state to watch: \(error.localizedDescription)")
        })
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleWatchAction(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleWatchAction(userInfo)
    }

    private nonisolated func handleWatchAction(_ message: [String: Any]) {
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
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            WCSession.default.activate()
        }
    }
    #endif
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            debugLog("WCSession activation failed: \(error.localizedDescription)")
        } else {
            debugLog("WCSession activated successfully")
            Task { @MainActor in
                self.viewModel?.resyncExternalState()
            }
        }
    }

    private func debugLog(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}
