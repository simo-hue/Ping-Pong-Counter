import Foundation
import WidgetKit
import Combine
@preconcurrency import WatchConnectivity

struct GameSnapshot: Equatable {
    let p1Score: Int
    let p2Score: Int
    let p1Sets: Int
    let p2Sets: Int
    let currentServer: Player
    let startingServerOfSet: Player
    let winner: Player?
    let completedSets: [SetRecord]
    let currentSetRallies: RallyLog
    /// Doubles serve baseline. `setServer(to:)` corrects the rotation by rewriting the lineup's
    /// opening rather than `startingServerOfSet`, so without these an undone correction would
    /// silently reapply itself on the next point — and persist for the rest of the match.
    let doublesOpeningServer: DoublesSeat
    let doublesOpeningReceiver: DoublesSeat
}

@MainActor
final class ScoreViewModel: ObservableObject, ScoreActionHandling {
    /// One instance for the whole app. A Live Activity button performs its intent in the app's
    /// process, so the intent needs a view model to reach that is not owned by a particular view.
    static let shared = ScoreViewModel()

    /// Declared once in PersistenceKeys so the App Group migration cannot miss a key.
    private typealias DefaultsKey = PersistenceKeys

    /// 11 and 21 are the official formats; the wider range exists for casual house rules
    /// (first to 5, first to 7, marathon games to 51).
    static let validTargetScoreRange = 1...99
    private static let validBestOfSets = Set([1, 3, 5])
    private static let validServeRotationIntervals = Set([2, 5])
    private static let validThemeRange = 0...2

    // Game Rules Settings
    @Published var targetScore: Int = 11 { // 11 or 21 standard, or a custom house rule
        didSet {
            guard Self.validTargetScoreRange.contains(targetScore) else {
                targetScore = oldValue
                return
            }
            guard targetScore != oldValue else { return }
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(targetScore, forKey: DefaultsKey.targetScore)
            guard !isApplyingRuleChange else { return }
            resetMatch(recordedTargetScore: oldValue)
        }
    }
    @Published var winByTwo: Bool = true {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(winByTwo, forKey: DefaultsKey.winByTwo)
            syncWithWatch()
        }
    }
    @Published var bestOfSets: Int = 3 { // 1, 3, or 5 sets to win
        didSet {
            guard Self.validBestOfSets.contains(bestOfSets) else {
                bestOfSets = oldValue
                return
            }
            guard bestOfSets != oldValue else { return }
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(bestOfSets, forKey: DefaultsKey.bestOfSets)
            guard !isApplyingRuleChange else { return }
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
            SharedStore.defaults.set(serveRotationInterval, forKey: DefaultsKey.serveRotationInterval)
            performStateMutation {
                updateServer()
            }
        }
    }
    
    // Player Details
    @Published var p1Name: String = Localized.defaultP1Name {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(p1Name, forKey: DefaultsKey.p1Name)
            // didSet fires even when the value is unchanged, and the scoreboard's name alert
            // commits whatever is in the field — so without this guard, opening the alert and
            // tapping Save would silently drop the roster link.
            if oldValue != p1Name { releaseRosterIdIfNameWasTyped(for: .player1) }
            stateDidChange()
        }
    }
    @Published var p2Name: String = Localized.defaultP2Name {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(p2Name, forKey: DefaultsKey.p2Name)
            if oldValue != p2Name { releaseRosterIdIfNameWasTyped(for: .player2) }
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
            SharedStore.defaults.set(startingServerOfMatch.rawValue, forKey: DefaultsKey.startingServerOfMatch)
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
            SharedStore.defaults.set(themeIndex, forKey: DefaultsKey.themeIndex)
            syncLiveActivity()
        }
    }
    
    // Match Winner
    @Published var winner: Player? = nil { didSet { stateDidChange() } }
    
    // State history for Undo
    private var history: [GameSnapshot] = []
    private var isApplyingStateBatch = false
    private var hasFinishedInitialLoad = false
    /// Set while `applyRules` writes several rule properties, so their individual didSet hooks
    /// persist the value but defer the single match reset to the caller.
    private var isApplyingRuleChange = false
    /// Set while a name is written *because* a roster player was chosen or the sides were
    /// swapped, so the name's didSet does not treat it as a freehand edit and drop the identity.
    private var isAssigningRosterIdentity = false

    @Published private(set) var matchRecords: [MatchRecord] = []

    // MARK: - Doubles

    @Published var isDoubles: Bool = false {
        didSet {
            guard isDoubles != oldValue else { return }
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(isDoubles, forKey: DefaultsKey.isDoubles)
            performStateMutation {
                updateServer()
            }
        }
    }

    /// The *match's* opening rotation. The current set's rotation is derived from it rather than
    /// stored, because `advancedToNextSet()` is its own inverse — two sets return to the start.
    /// Deriving means undo, set corrections and a cold launch can never leave the rotation out of
    /// step with the score.
    @Published private(set) var doublesLineup = DoublesLineup.makeDefault() {
        didSet {
            guard hasFinishedInitialLoad else { return }
            persistDoublesLineup()
        }
    }

    var currentSetLineup: DoublesLineup {
        (p1Sets + p2Sets) % 2 == 0 ? doublesLineup : doublesLineup.advancedToNextSet()
    }

    /// Seat serving right now, or nil in singles.
    var currentServingSeat: DoublesSeat? {
        guard isDoubles else { return nil }
        return currentSetLineup.server(
            totalPoints: p1Score + p2Score,
            interval: baseServeInterval,
            deuceAfter: deucePointTotal
        )
    }

    var currentReceivingSeat: DoublesSeat? {
        guard isDoubles else { return nil }
        return currentSetLineup.receiver(
            totalPoints: p1Score + p2Score,
            interval: baseServeInterval,
            deuceAfter: deucePointTotal
        )
    }

    /// Points per serve turn before deuce.
    var baseServeInterval: Int { max(1, serveRotationInterval) }

    /// Total points scored when both sides reach `targetScore - 1` — the moment turns shorten to
    /// one point each. Always exactly twice `targetScore - 1`, since deuce needs both sides there.
    var deucePointTotal: Int { 2 * max(0, targetScore - 1) }

    func updateDoublesLineup(_ lineup: DoublesLineup) {
        doublesLineup = lineup
        performStateMutation {
            updateServer()
        }
    }

    func swapDoublesPartners(on team: Player) {
        var lineup = doublesLineup
        lineup.swapPartners(on: team)
        updateDoublesLineup(lineup)
        HapticManager.shared.play(.serveChange)
    }

    private func persistDoublesLineup() {
        guard let data = try? JSONEncoder().encode(doublesLineup) else { return }
        SharedStore.defaults.set(data, forKey: DefaultsKey.doublesLineup)
    }

    /// Saved competitors, most recently created first.
    @Published private(set) var roster: [RosterPlayer] = []

    /// Roster identities currently assigned to each side, when the names came from saved players.
    /// Cleared as soon as a name is typed freehand, so a record is never mis-attributed.
    @Published private(set) var p1RosterId: UUID?
    @Published private(set) var p2RosterId: UUID?

    /// Sets already finished in the match currently on the table.
    @Published private(set) var completedSets: [SetRecord] = []
    /// Rally-by-rally log of the set being played right now.
    @Published private(set) var currentSetRallies = RallyLog()
    
    // Voice announcements
    @Published var isVoiceEnabled: Bool = false {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(isVoiceEnabled, forKey: DefaultsKey.isVoiceEnabled)
            SpeechManager.shared.isVoiceEnabled = isVoiceEnabled
        }
    }

    // Scoreboard sound effects (independent of the spoken umpire)
    @Published var isSoundEnabled: Bool = false {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(isSoundEnabled, forKey: DefaultsKey.isSoundEnabled)
            SoundManager.shared.isSoundEnabled = isSoundEnabled
        }
    }

    @Published var hapticIntensity: HapticIntensity = .full {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(hapticIntensity.rawValue, forKey: DefaultsKey.hapticIntensity)
            HapticManager.shared.intensity = hapticIntensity
        }
    }

    /// Keeps the display lit while a match is on the table — the phone propped by the net is
    /// useless if it sleeps between rallies.
    @Published var keepScreenAwake: Bool = true {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(keepScreenAwake, forKey: DefaultsKey.keepScreenAwake)
        }
    }

    // Match stopwatch
    @Published private(set) var matchClock = MatchClock()

    @Published var showMatchTimer: Bool = true {
        didSet {
            guard hasFinishedInitialLoad else { return }
            SharedStore.defaults.set(showMatchTimer, forKey: DefaultsKey.showMatchTimer)
        }
    }

    init() {
        // Load persisted settings from UserDefaults or use native defaults
        let defaults = SharedStore.defaults
        let savedTargetScore = defaults.integer(forKey: DefaultsKey.targetScore)
        self.targetScore = Self.validTargetScoreRange.contains(savedTargetScore) ? savedTargetScore : 11
        self.winByTwo = defaults.object(forKey: DefaultsKey.winByTwo) as? Bool ?? true
        self.bestOfSets = Self.validBestOfSets.contains(defaults.integer(forKey: DefaultsKey.bestOfSets)) ? defaults.integer(forKey: DefaultsKey.bestOfSets) : 3
        self.serveRotationInterval = Self.validServeRotationIntervals.contains(defaults.integer(forKey: DefaultsKey.serveRotationInterval)) ? defaults.integer(forKey: DefaultsKey.serveRotationInterval) : 2
        self.p1Name = defaults.string(forKey: DefaultsKey.p1Name) ?? Localized.defaultP1Name
        self.p2Name = defaults.string(forKey: DefaultsKey.p2Name) ?? Localized.defaultP2Name
        let savedThemeIndex = defaults.object(forKey: DefaultsKey.themeIndex) as? Int ?? 0
        self.themeIndex = Self.validThemeRange.contains(savedThemeIndex) ? savedThemeIndex : 0
        self.isVoiceEnabled = defaults.object(forKey: DefaultsKey.isVoiceEnabled) as? Bool ?? false
        self.isSoundEnabled = defaults.object(forKey: DefaultsKey.isSoundEnabled) as? Bool ?? false
        self.keepScreenAwake = defaults.object(forKey: DefaultsKey.keepScreenAwake) as? Bool ?? true
        self.showMatchTimer = defaults.object(forKey: DefaultsKey.showMatchTimer) as? Bool ?? true
        self.hapticIntensity = HapticIntensity(rawValue: defaults.string(forKey: DefaultsKey.hapticIntensity) ?? "") ?? .full
        self.matchRecords = Self.loadMatchRecords(from: defaults)
        self.matchClock = Self.loadMatchClock(from: defaults)

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

        self.isDoubles = defaults.object(forKey: DefaultsKey.isDoubles) as? Bool ?? false
        if let data = defaults.data(forKey: DefaultsKey.doublesLineup),
           let savedLineup = try? JSONDecoder().decode(DoublesLineup.self, from: data) {
            self.doublesLineup = savedLineup
        }

        if let data = defaults.data(forKey: DefaultsKey.roster),
           let savedRoster = try? JSONDecoder().decode([RosterPlayer].self, from: data) {
            self.roster = savedRoster
        }
        self.p1RosterId = UUID(uuidString: defaults.string(forKey: DefaultsKey.p1RosterId) ?? "")
        self.p2RosterId = UUID(uuidString: defaults.string(forKey: DefaultsKey.p2RosterId) ?? "")

        if let data = defaults.data(forKey: DefaultsKey.completedSets),
           let sets = try? JSONDecoder().decode([SetRecord].self, from: data) {
            self.completedSets = sets
        }
        if let data = defaults.data(forKey: DefaultsKey.currentSetRallies),
           let rallies = try? JSONDecoder().decode(RallyLog.self, from: data) {
            self.currentSetRallies = rallies
        }
        
        // Push initial feedback preferences into the shared managers
        SpeechManager.shared.isVoiceEnabled = self.isVoiceEnabled
        SoundManager.shared.isSoundEnabled = self.isSoundEnabled
        HapticManager.shared.intensity = self.hapticIntensity

        WatchConnector.shared.configure(with: self)
        ScoreActionRouter.handler = self
        hasFinishedInitialLoad = true
        persistMatchState()
        syncWithWatch()
    }
    
    // MARK: - Core Operations
    
    func incrementScore(for player: Player) {
        guard winner == nil else { return }

        let wasMatchPoint = isMatchPoint()
        saveToHistory()

        // The clock measures play, so it starts on the first rally won rather than on app launch.
        startClockIfNeeded()

        let setsPlayedBefore = p1Sets + p2Sets

        performStateMutation {
            currentSetRallies.append(player)

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

        if winner != nil {
            stopClock()
            SoundManager.shared.play(.matchWon)
        } else if p1Sets + p2Sets == setsPlayedBefore {
            // A set-winning rally already played `.setWon` inside checkSetEnd; layering the
            // ordinary point blip on top of it would overlap two system sounds on one tap.
            SoundManager.shared.play(.point)
        }

        // Fire the match-point alert only on the transition into match point, never on every announce.
        if winner == nil && !wasMatchPoint && isMatchPoint() {
            HapticManager.shared.play(.matchPoint)
        }

        announceState()
    }
    
    func decrementScore(for player: Player) {
        guard winner == nil else { return }
        
        guard (player == .player1 ? p1Score : p2Score) > 0 else { return }

        saveToHistory()
        performStateMutation {
            currentSetRallies.removeLastRally(wonBy: player)

            if player == .player1 {
                p1Score -= 1
                HapticManager.shared.play(.scoreDecrement)
            } else {
                p2Score -= 1
                HapticManager.shared.play(.scoreDecrement)
            }

            updateServer()
        }

        SoundManager.shared.play(.undo)
        announceState()
    }

    func undo() {
        guard let previousState = history.popLast() else { return }

        // Rewinding past the winning rally puts the match back in play, so the clock runs again.
        if previousState.winner == nil && winner != nil {
            resumeClock()
        }

        performStateMutation {
            p1Score = previousState.p1Score
            p2Score = previousState.p2Score
            p1Sets = previousState.p1Sets
            p2Sets = previousState.p2Sets
            currentServer = previousState.currentServer
            startingServerOfSet = previousState.startingServerOfSet
            winner = previousState.winner
            completedSets = previousState.completedSets
            currentSetRallies = previousState.currentSetRallies

            var restoredLineup = doublesLineup
            restoredLineup.setOpening(
                server: previousState.doublesOpeningServer,
                receiver: previousState.doublesOpeningReceiver
            )
            doublesLineup = restoredLineup
        }
        
        HapticManager.shared.play(.scoreDecrement)
        SoundManager.shared.play(.undo)

        // Announce score again after undoing
        let serverName = servingDisplayName
        SpeechManager.shared.speak(Localized.speechUndo(p1Score: p1Score, p2Score: p2Score, server: serverName))
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

        resetClock()

        performStateMutation {
            p1Score = 0
            p2Score = 0
            p1Sets = 0
            p2Sets = 0
            winner = nil
            startingServerOfSet = startingServerOfMatch
            currentServer = startingServerOfMatch
            completedSets.removeAll()
            currentSetRallies.removeAll()
        }

        HapticManager.shared.play(.reset)
        SpeechManager.shared.speak(Localized.speechReset(server: servingDisplayName))
    }

    /// Commits a staged rule change as one operation. Applying the two properties separately
    /// would reset — and therefore archive — the running match twice, littering the history with
    /// a phantom record for every step of a stepper.
    func applyRules(targetScore newTargetScore: Int, bestOfSets newBestOfSets: Int) {
        let clampedTargetScore = min(
            max(newTargetScore, Self.validTargetScoreRange.lowerBound),
            Self.validTargetScoreRange.upperBound
        )
        let resolvedBestOfSets = Self.validBestOfSets.contains(newBestOfSets) ? newBestOfSets : bestOfSets

        guard clampedTargetScore != targetScore || resolvedBestOfSets != bestOfSets else { return }

        let previousTargetScore = targetScore
        let previousBestOfSets = bestOfSets

        isApplyingRuleChange = true
        targetScore = clampedTargetScore
        bestOfSets = resolvedBestOfSets
        isApplyingRuleChange = false

        resetMatch(
            recordedTargetScore: previousTargetScore,
            recordedBestOfSets: previousBestOfSets
        )
    }

    /// Manually hands the serve to `player` and rewrites the set's serve baseline so the
    /// override survives the next `updateServer()` recomputation.
    func setServer(to player: Player) {
        guard winner == nil else { return }
        guard currentServer != player else { return }

        saveToHistory()

        if isDoubles {
            // Nudge the opening rotation one seat at a time until the requested team is the one
            // serving at the current score. At most three steps around a four-seat cycle.
            var lineup = doublesLineup
            for _ in 0..<3 {
                lineup = lineup.rotatedOpening()
                let setLineup = (p1Sets + p2Sets) % 2 == 0 ? lineup : lineup.advancedToNextSet()
                let seat = setLineup.server(
                    totalPoints: p1Score + p2Score,
                    interval: baseServeInterval,
                    deuceAfter: deucePointTotal
                )
                if seat.team == player { break }
            }
            doublesLineup = lineup
            performStateMutation {
                updateServer()
            }
        } else {
            performStateMutation {
                let servesPlayed = completedServeTurns
                startingServerOfSet = (servesPlayed % 2 == 0) ? player : player.opponent
                currentServer = player
            }
        }

        HapticManager.shared.play(.serveChange)
        SoundManager.shared.play(.serveChange)
    }
    
    func swapSides() {
        // Resolve every mirrored value up front. `startingServerOfMatch`'s own didSet rewrites
        // startingServerOfSet/currentServer while the match is still at 0-0, so toggling those
        // afterwards would flip them a second time and land on the wrong server.
        let swappedNames = (p1: p2Name, p2: p1Name)
        let swappedScores = (p1: p2Score, p2: p1Score)
        let swappedSets = (p1: p2Sets, p2: p1Sets)
        let swappedStartingServerOfMatch = startingServerOfMatch.opponent
        let swappedStartingServerOfSet = startingServerOfSet.opponent
        let swappedCurrentServer = currentServer.opponent
        let swappedWinner = winner?.opponent
        let swappedCompletedSets = completedSets.map { $0.swapped() }
        let swappedCurrentSetRallies = currentSetRallies.swapped()
        let swappedRosterIds = (p1: p2RosterId, p2: p1RosterId)
        let swappedLineup = doublesLineup.swappedTeams()

        // The names move with their roster identities here, so this is not a freehand edit.
        isAssigningRosterIdentity = true
        defer {
            isAssigningRosterIdentity = false
            persistRosterAssignments()
        }

        performStateMutation {
            // Swap player names and their active set counts and scores so players can change sides on the physical table
            p1Name = swappedNames.p1
            p2Name = swappedNames.p2
            p1RosterId = swappedRosterIds.p1
            p2RosterId = swappedRosterIds.p2
            doublesLineup = swappedLineup

            p1Score = swappedScores.p1
            p2Score = swappedScores.p2

            p1Sets = swappedSets.p1
            p2Sets = swappedSets.p2

            winner = swappedWinner

            // Assign absolute values (never toggle) so the didSet cascade cannot double-apply.
            startingServerOfMatch = swappedStartingServerOfMatch
            startingServerOfSet = swappedStartingServerOfSet
            currentServer = swappedCurrentServer

            completedSets = swappedCompletedSets
            currentSetRallies = swappedCurrentSetRallies

            // Re-map history states to new swap
            history = history.map { snapshot in
                GameSnapshot(
                    p1Score: snapshot.p2Score,
                    p2Score: snapshot.p1Score,
                    p1Sets: snapshot.p2Sets,
                    p2Sets: snapshot.p1Sets,
                    currentServer: snapshot.currentServer.opponent,
                    startingServerOfSet: snapshot.startingServerOfSet.opponent,
                    winner: snapshot.winner?.opponent,
                    completedSets: snapshot.completedSets.map { $0.swapped() },
                    currentSetRallies: snapshot.currentSetRallies.swapped(),
                    // Mirror the seats too: undoing a point after a change of ends must not
                    // restore an opening that points at the team now on the other side.
                    doublesOpeningServer: DoublesSeat(
                        team: snapshot.doublesOpeningServer.team.opponent,
                        slot: snapshot.doublesOpeningServer.slot
                    ),
                    doublesOpeningReceiver: DoublesSeat(
                        team: snapshot.doublesOpeningReceiver.team.opponent,
                        slot: snapshot.doublesOpeningReceiver.slot
                    )
                )
            }
        }

        HapticManager.shared.play(.serveChange)
        SpeechManager.shared.speak(Localized.speechSideSwap(leftName: p1Name, rightName: p2Name))
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
    
    /// Serve turns completed at the current score. Shared by singles and doubles so the deuce
    /// rule is applied in exactly one place.
    private var completedServeTurns: Int {
        DoublesLineup.serveTurns(
            totalPoints: p1Score + p2Score,
            interval: baseServeInterval,
            deuceAfter: deucePointTotal
        )
    }

    private func updateServer() {
        // In doubles the serve rotates through four seats rather than alternating between two
        // sides, so the serving team is whichever team the current seat belongs to.
        if isDoubles {
            let setLineup = currentSetLineup

            // Keep the singles-shaped baseline in step with the lineup. The Watch mirrors the
            // serve optimistically from `startingServerOfSet` alone, and the doubles cycle
            // alternates teams exactly like singles — so a stale baseline would put the serve
            // indicator on the wrong half for the whole match, not just at a rotation boundary.
            startingServerOfSet = setLineup.setStartingServer.team

            currentServer = setLineup
                .server(
                    totalPoints: p1Score + p2Score,
                    interval: baseServeInterval,
                    deuceAfter: deucePointTotal
                )
                .team
            return
        }

        let servesPlayed = completedServeTurns
        
        // Determine player serving
        if startingServerOfSet == .player1 {
            currentServer = (servesPlayed % 2 == 0) ? .player1 : .player2
        } else {
            currentServer = (servesPlayed % 2 == 0) ? .player2 : .player1
        }
    }
    
    // MARK: - Match Rules Engine
    
    private func checkSetEnd() {
        if isSetWon(pScore: p1Score, oScore: p2Score) {
            completeSet(wonBy: .player1)
        } else if isSetWon(pScore: p2Score, oScore: p1Score) {
            completeSet(wonBy: .player2)
        }
    }

    /// Archives the finished set — points and rally log — then either ends the match or opens the
    /// next set. Both outcomes must archive, so the bookkeeping lives here rather than in
    /// `startNewSet`, which only runs when play continues.
    private func completeSet(wonBy setWinner: Player) {
        if setWinner == .player1 {
            p1Sets += 1
        } else {
            p2Sets += 1
        }

        completedSets.append(
            SetRecord(
                id: UUID(),
                // Derived from the set tally rather than completedSets.count: a match that began
                // on a build without rally tracking has a set count but no archived sets, and
                // numbering from the array would restart this match's sets at 1.
                index: p1Sets + p2Sets,
                p1Points: p1Score,
                p2Points: p2Score,
                winner: setWinner,
                rallies: rallyLog(currentSetRallies, matching: p1Score, p2Score)
            )
        )
        currentSetRallies.removeAll()

        let setsWonByWinner = setWinner == .player1 ? p1Sets : p2Sets
        if setsWonByWinner >= setsRequiredToWin {
            winner = setWinner
            HapticManager.shared.play(.gameWon)
        } else {
            HapticManager.shared.play(.serveChange)
            SoundManager.shared.play(.setWon)
            startNewSet(wonBy: setWinner)
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
    
    private func startNewSet(wonBy setWinner: Player) {
        p1Score = 0
        p2Score = 0

        // ITTF Rule: Alternating initial server for each set
        startingServerOfSet = startingServerOfSet.opponent
        currentServer = startingServerOfSet

        let setWinnerName = setWinner == .player1 ? p1Name : p2Name
        let serverName = servingDisplayName
        SpeechManager.shared.speak(Localized.speechSetEnd(setWinner: setWinnerName, server: serverName))
    }
    
    private func isDeuce() -> Bool {
        return p1Score >= (targetScore - 1) && p2Score >= (targetScore - 1)
    }
    
    /// True when `pScore` is a single rally away from taking the current set.
    /// With deuce enabled the player must already lead; without it, reaching `targetScore - 1`
    /// is enough (so 10-10 in a no-deuce game to 11 is set point for *both* players).
    private func isSetPointScore(pScore: Int, oScore: Int) -> Bool {
        guard pScore >= (targetScore - 1) else { return false }
        return winByTwo ? (pScore - oScore >= 1) : true
    }

    func isSetPoint(for player: Player) -> Bool {
        guard winner == nil else { return false }
        return player == .player1
            ? isSetPointScore(pScore: p1Score, oScore: p2Score)
            : isSetPointScore(pScore: p2Score, oScore: p1Score)
    }

    func isMatchPoint(for player: Player) -> Bool {
        let setsWon = player == .player1 ? p1Sets : p2Sets
        return setsWon == setsRequiredToWin - 1 && isSetPoint(for: player)
    }

    // Pure query — callers own any haptic or speech reaction.
    private func isMatchPoint() -> Bool {
        isMatchPoint(for: .player1) || isMatchPoint(for: .player2)
    }
    
    // MARK: - State Callouts
    
    /// Who the umpire should name as serving. In doubles that is the individual at the table, not
    /// the team — naming the team would leave the pair guessing which of them is up.
    var servingDisplayName: String {
        if let seat = currentServingSeat {
            return currentSetLineup.name(for: seat)
        }
        return currentServer == .player1 ? p1Name : p2Name
    }

    var receivingDisplayName: String? {
        guard let seat = currentReceivingSeat else { return nil }
        return currentSetLineup.name(for: seat)
    }

    private func announceState() {
        let serverName = servingDisplayName
        let winnerName = winner == nil ? nil : (winner == .player1 ? p1Name : p2Name)

        SpeechManager.shared.announceScore(
            p1Name: p1Name,
            p1Score: p1Score,
            p2Name: p2Name,
            p2Score: p2Score,
            serverName: serverName,
            matchPoint: pointAlert { self.isMatchPoint(for: $0) },
            setPoint: pointAlert { self.isSetPoint(for: $0) },
            // "Vantaggi"/"Deuce" only exists as a concept when winning by two is required.
            isDeuce: winByTwo && isDeuce() && p1Score == p2Score,
            winnerName: winnerName
        )
    }

    /// Names the one player `predicate` singles out. A no-deuce game can leave *both* players a
    /// single rally from the set, and naming either would be a lie — so an ambiguous tie yields
    /// nil and the announcer falls through to the neutral "N all" phrasing.
    private func pointAlert(_ predicate: (Player) -> Bool) -> PointAlert? {
        let p1Qualifies = predicate(.player1)
        let p2Qualifies = predicate(.player2)
        guard p1Qualifies != p2Qualifies else { return nil }

        return p1Qualifies
            ? PointAlert(name: p1Name, ownScore: p1Score, opponentScore: p2Score)
            : PointAlert(name: p2Name, ownScore: p2Score, opponentScore: p1Score)
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
            winner: winner,
            completedSets: completedSets,
            currentSetRallies: currentSetRallies,
            doublesOpeningServer: doublesLineup.setStartingServer,
            doublesOpeningReceiver: doublesLineup.setStartingReceiver
        )
        guard history.last != snapshot else { return }
        history.append(snapshot)
        
        // Cap history size to 30 steps to save memory
        if history.count > 30 {
            history.removeFirst()
        }
    }
    
    var hasMeaningfulMatchState: Bool {
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
            winByTwo: recordedWinByTwo ?? winByTwo,
            durationSeconds: matchClock.hasStarted ? Int(matchClock.elapsed().rounded()) : nil,
            sets: archivedSets,
            p1Id: p1RosterId,
            p2Id: p2RosterId
        )

        matchRecords.insert(record, at: 0)
        persistMatchRecords()
    }

    /// Finished sets plus the set still on the table, so an abandoned match keeps its partial
    /// final set instead of silently dropping those rallies.
    ///
    /// A *decided* match has no set on the table: `completeSet` archived the deciding set and
    /// deliberately left `p1Score`/`p2Score` standing so the celebration overlay can show them.
    /// Without the `winner == nil` guard those leftover scores would be archived a second time,
    /// giving every completed match a phantom trailing set.
    private var archivedSets: [SetRecord] {
        var sets = completedSets

        if winner == nil, p1Score > 0 || p2Score > 0 || !currentSetRallies.isEmpty {
            sets.append(
                SetRecord(
                    id: UUID(),
                    index: p1Sets + p2Sets + 1,
                    p1Points: p1Score,
                    p2Points: p2Score,
                    winner: nil,
                    rallies: rallyLog(currentSetRallies, matching: p1Score, p2Score)
                )
            )
        }

        return sets
    }

    /// Passes the log through when it accounts for the score, and substitutes an empty one when it
    /// does not — the detail view then honestly reports "no rally data" rather than plotting a
    /// momentum curve that disagrees with the set score printed beside it.
    private func rallyLog(_ log: RallyLog, matching p1Points: Int, _ p2Points: Int) -> RallyLog {
        log.accountsFor(p1Points: p1Points, p2Points: p2Points) ? log : RallyLog()
    }

    private func persistMatchRecords() {
        guard let data = try? JSONEncoder().encode(matchRecords) else { return }
        SharedStore.defaults.set(data, forKey: DefaultsKey.matchRecords)

        // The widget falls back to the last archived result, so deleting history must refresh it.
        reloadHomeWidget()
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

    // MARK: - External Actions

    func handle(_ action: ScoreAction) {
        switch action {
        case .pointPlayer1: incrementScore(for: .player1)
        case .pointPlayer2: incrementScore(for: .player2)
        case .undo: undo()
        }
    }

    // MARK: - Roster

    /// Saves a new competitor. Returns nil for a blank name or one already in the roster, so the
    /// caller can surface that instead of silently creating a duplicate identity.
    @discardableResult
    func addRosterPlayer(name: String, emoji: String = RosterPlayer.defaultEmoji) -> RosterPlayer? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let key = RosterPlayer.matchKey(for: trimmed)
        guard !roster.contains(where: { $0.matchKey == key }) else { return nil }

        let player = RosterPlayer(name: trimmed, emoji: emoji)
        roster.insert(player, at: 0)
        persistRoster()
        return player
    }

    /// Renames or re-avatars an existing entry. Returns false when the edit is rejected, so the
    /// editor can keep its sheet open and explain why.
    ///
    /// The uniqueness check matters more here than on creation: attribution falls back to matching
    /// names for records that carry no roster ID, so allowing a rename onto an existing name would
    /// make a zero-history entry inherit somebody else's entire record.
    @discardableResult
    func updateRosterPlayer(_ player: RosterPlayer) -> Bool {
        guard let index = roster.firstIndex(where: { $0.id == player.id }) else { return false }

        let trimmed = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let key = RosterPlayer.matchKey(for: trimmed)
        guard !roster.contains(where: { $0.id != player.id && $0.matchKey == key }) else { return false }

        var updated = player
        updated.name = trimmed
        roster[index] = updated
        persistRoster()

        // Keep the scoreboard in step when the player being renamed is on the table.
        if p1RosterId == updated.id { assignRosterPlayer(updated, to: .player1) }
        if p2RosterId == updated.id { assignRosterPlayer(updated, to: .player2) }

        return true
    }

    func deleteRosterPlayer(id: UUID) {
        let originalCount = roster.count
        roster.removeAll { $0.id == id }
        guard roster.count != originalCount else { return }

        // Past match records keep the ID so their history survives; only the live sides let go.
        if p1RosterId == id { p1RosterId = nil }
        if p2RosterId == id { p2RosterId = nil }

        persistRoster()
        persistRosterAssignments()
        HapticManager.shared.play(.scoreDecrement)
    }

    func assignRosterPlayer(_ player: RosterPlayer, to side: Player) {
        isAssigningRosterIdentity = true
        if side == .player1 {
            p1Name = player.name
            p1RosterId = player.id
        } else {
            p2Name = player.name
            p2RosterId = player.id
        }
        isAssigningRosterIdentity = false

        persistRosterAssignments()
    }

    func rosterPlayer(on side: Player) -> RosterPlayer? {
        let id = side == .player1 ? p1RosterId : p2RosterId
        guard let id else { return nil }
        return roster.first { $0.id == id }
    }

    func stats(for player: RosterPlayer) -> PlayerStats {
        MatchStatistics.stats(for: player, in: matchRecords)
    }

    func headToHead(for player: RosterPlayer) -> [HeadToHeadRecord] {
        MatchStatistics.headToHead(for: player, in: matchRecords, roster: roster)
    }

    private func releaseRosterIdIfNameWasTyped(for side: Player) {
        guard !isAssigningRosterIdentity else { return }

        if side == .player1, p1RosterId != nil {
            p1RosterId = nil
            persistRosterAssignments()
        } else if side == .player2, p2RosterId != nil {
            p2RosterId = nil
            persistRosterAssignments()
        }
    }

    private func persistRoster() {
        guard let data = try? JSONEncoder().encode(roster) else { return }
        SharedStore.defaults.set(data, forKey: DefaultsKey.roster)
    }

    private func persistRosterAssignments() {
        let defaults = SharedStore.defaults

        if let p1RosterId {
            defaults.set(p1RosterId.uuidString, forKey: DefaultsKey.p1RosterId)
        } else {
            defaults.removeObject(forKey: DefaultsKey.p1RosterId)
        }

        if let p2RosterId {
            defaults.set(p2RosterId.uuidString, forKey: DefaultsKey.p2RosterId)
        } else {
            defaults.removeObject(forKey: DefaultsKey.p2RosterId)
        }
    }

    // MARK: - Match Clock

    private func startClockIfNeeded() {
        guard !matchClock.hasStarted else { return }
        matchClock.startIfNeeded()
        persistMatchClock()
    }

    private func stopClock() {
        guard matchClock.isRunning else { return }
        matchClock.stop()
        persistMatchClock()
    }

    private func resumeClock() {
        guard matchClock.hasStarted, !matchClock.isRunning else { return }
        matchClock.resume()
        persistMatchClock()
    }

    private func resetClock() {
        guard matchClock.hasStarted else { return }
        matchClock.reset()
        persistMatchClock()
    }

    private func persistMatchClock() {
        let defaults = SharedStore.defaults
        guard let data = try? JSONEncoder().encode(matchClock) else {
            defaults.removeObject(forKey: DefaultsKey.matchClock)
            return
        }
        defaults.set(data, forKey: DefaultsKey.matchClock)
    }

    private static func loadMatchClock(from defaults: UserDefaults) -> MatchClock {
        guard let data = defaults.data(forKey: DefaultsKey.matchClock),
              let clock = try? JSONDecoder().decode(MatchClock.self, from: data) else {
            return MatchClock()
        }
        return clock
    }

    private func persistMatchState() {
        let defaults = SharedStore.defaults

        if let data = try? JSONEncoder().encode(completedSets) {
            defaults.set(data, forKey: DefaultsKey.completedSets)
        }
        if let data = try? JSONEncoder().encode(currentSetRallies) {
            defaults.set(data, forKey: DefaultsKey.currentSetRallies)
        }

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

        reloadHomeWidget()
    }

    /// Nudges the Home Screen widget after a write lands. WidgetKit coalesces reload requests, so
    /// calling this per point is not wasteful.
    private func reloadHomeWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "PingPongHomeWidget")
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
            serveRotationInterval: serveRotationInterval,
            isDoubles: isDoubles,
            servingName: servingDisplayName,
            receivingName: receivingDisplayName
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
            themeIndex: themeIndex,
            servingName: isDoubles ? servingDisplayName : nil
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
        serveRotationInterval: Int,
        isDoubles: Bool,
        servingName: String,
        receivingName: String?
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
            "serveRotationInterval": serveRotationInterval,
            "isDoubles": isDoubles,
            "servingName": servingName,
            "receivingName": receivingName ?? ""
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
