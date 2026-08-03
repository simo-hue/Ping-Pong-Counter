import SwiftUI

// Stand-in for the iOS-only parts of the app, so the pure-SwiftUI screens can be TYPE-CHECKED
// against the real SwiftUI and Charts frameworks on macOS — catching wrong argument labels,
// unavailable APIs and result-builder mistakes that `swiftc -parse` cannot see.
//
// Only the surface the checked views actually read is reproduced. When a view starts using a new
// view-model member, add it here; a compile error is the signal.

@MainActor
final class ScoreViewModel: ObservableObject {
    @Published var themeIndex = 0
    @Published var matchRecords: [MatchRecord] = []
    @Published var roster: [RosterPlayer] = []
    @Published var p1RosterId: UUID?
    @Published var p2RosterId: UUID?
    @Published var p1Name = ""
    @Published var p2Name = ""
    @Published var targetScore = 11
    @Published var bestOfSets = 3
    @Published var winByTwo = true
    @Published var serveRotationInterval = 2
    @Published var isVoiceEnabled = false
    @Published var isSoundEnabled = false
    @Published var keepScreenAwake = true
    @Published var showMatchTimer = true
    @Published var hapticIntensity: HapticIntensity = .full
    @Published var isDoubles = false
    @Published private(set) var doublesLineup = DoublesLineup.makeDefault()

    var currentSetLineup: DoublesLineup { doublesLineup }
    var currentServingSeat: DoublesSeat? { nil }
    var currentReceivingSeat: DoublesSeat? { nil }
    func updateDoublesLineup(_ lineup: DoublesLineup) {}
    func swapDoublesPartners(on team: Player) {}

    static let validTargetScoreRange = 1...99

    var hasMeaningfulMatchState: Bool { false }

    func stats(for player: RosterPlayer) -> PlayerStats { MatchStatistics.stats(for: player, in: matchRecords) }
    func headToHead(for player: RosterPlayer) -> [HeadToHeadRecord] {
        MatchStatistics.headToHead(for: player, in: matchRecords, roster: roster)
    }
    func rosterPlayer(on side: Player) -> RosterPlayer? { nil }
    @discardableResult func addRosterPlayer(name: String, emoji: String = RosterPlayer.defaultEmoji) -> RosterPlayer? { nil }
    @discardableResult func updateRosterPlayer(_ player: RosterPlayer) -> Bool { true }
    func deleteRosterPlayer(id: UUID) {}
    func assignRosterPlayer(_ player: RosterPlayer, to side: Player) {}
    func applyRules(targetScore: Int, bestOfSets: Int) {}
    func resetMatch() {}
    func deleteMatchRecords() {}
    func deleteMatchRecord(id: UUID) {}
}

// Mirrors PingPong/HapticManager.swift, which cannot be compiled here because it imports UIKit.
enum HapticIntensity: String, CaseIterable, Codable {
    case off
    case light
    case full
}
