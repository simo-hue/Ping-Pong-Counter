import Foundation

// Model-level checks for the scoring and statistics engine.
//
// These compile against the REAL PingPong/SetRecord.swift, MatchRecord.swift and RosterPlayer.swift.
// Only the parts of ScoreViewModel that cannot build outside iOS (it imports WatchConnectivity and
// UIKit-backed managers) are re-expressed here as a scripted stand-in, kept deliberately faithful
// to the original so the archive rules under test are the shipping ones.

var failures = 0

func check(_ name: String, _ got: String, _ want: String) {
    let ok = got == want
    if !ok { failures += 1 }
    print("\(ok ? "PASS" : "FAIL") \(name)")
    if !ok {
        print("      got:  \(got)")
        print("      want: \(want)")
    }
}

// MARK: - Stand-in for the scoring loop

struct Engine {
    var p1Score = 0, p2Score = 0, p1Sets = 0, p2Sets = 0
    var winner: Player?
    var completedSets: [SetRecord] = []
    var currentSetRallies = RallyLog()
    let target: Int
    let setsToWin: Int
    var winByTwo = true

    mutating func point(_ player: Player) {
        guard winner == nil else { return }
        currentSetRallies.append(player)
        if player == .player1 { p1Score += 1 } else { p2Score += 1 }

        if isSetWon(p1Score, p2Score) {
            completeSet(wonBy: .player1)
        } else if isSetWon(p2Score, p1Score) {
            completeSet(wonBy: .player2)
        }
    }

    func isSetWon(_ own: Int, _ other: Int) -> Bool {
        own >= target && (!winByTwo || own - other >= 2)
    }

    mutating func completeSet(wonBy setWinner: Player) {
        if setWinner == .player1 { p1Sets += 1 } else { p2Sets += 1 }

        completedSets.append(
            SetRecord(
                id: UUID(),
                index: p1Sets + p2Sets,
                p1Points: p1Score,
                p2Points: p2Score,
                winner: setWinner,
                rallies: rallyLog(currentSetRallies, matching: p1Score, p2Score)
            )
        )
        currentSetRallies.removeAll()

        if (setWinner == .player1 ? p1Sets : p2Sets) >= setsToWin {
            winner = setWinner
        } else {
            p1Score = 0
            p2Score = 0
        }
    }

    func rallyLog(_ log: RallyLog, matching p1Points: Int, _ p2Points: Int) -> RallyLog {
        log.accountsFor(p1Points: p1Points, p2Points: p2Points) ? log : RallyLog()
    }

    var archivedSets: [SetRecord] {
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

    var setScoreLine: String { archivedSets.map(\.scoreLine).joined(separator: " · ") }

    func record(p1: RosterPlayer?, p2: RosterPlayer?, date: Date = Date()) -> MatchRecord {
        MatchRecord(
            id: UUID(), date: date,
            p1Name: p1?.name ?? "P1", p2Name: p2?.name ?? "P2",
            p1Score: p1Score, p2Score: p2Score, p1Sets: p1Sets, p2Sets: p2Sets,
            winner: winner, targetScore: target, bestOfSets: setsToWin, winByTwo: winByTwo,
            durationSeconds: nil, sets: archivedSets, p1Id: p1?.id, p2Id: p2?.id
        )
    }
}

func playSet(_ engine: inout Engine, _ p1Points: Int, _ p2Points: Int) {
    for _ in 0..<p2Points { engine.point(.player2) }
    for _ in 0..<p1Points { engine.point(.player1) }
}

/// Plays a whole match and returns its archived record.
func playMatch(target: Int = 11, setsToWin: Int, _ sets: [(Int, Int)],
               p1: RosterPlayer?, p2: RosterPlayer?, date: Date = Date()) -> MatchRecord {
    var engine = Engine(target: target, setsToWin: setsToWin)
    for (a, b) in sets { playSet(&engine, a, b) }
    return engine.record(p1: p1, p2: p2, date: date)
}

// MARK: - Set archiving

print("── Set archiving ──")

var straightSets = Engine(target: 11, setsToWin: 3)
playSet(&straightSets, 11, 9); playSet(&straightSets, 11, 8); playSet(&straightSets, 11, 6)
check("completed 3-0 match archives exactly 3 sets",
      "\(straightSets.archivedSets.count) [\(straightSets.setScoreLine)]",
      "3 [11-9 · 11-8 · 11-6]")
check("set indices are sequential",
      straightSets.archivedSets.map { "\($0.index)" }.joined(separator: ","), "1,2,3")

var singleSet = Engine(target: 11, setsToWin: 1)
playSet(&singleSet, 11, 4)
check("completed single-set match archives 1 set",
      "\(singleSet.archivedSets.count) [\(singleSet.setScoreLine)]", "1 [11-4]")

var abandoned = Engine(target: 11, setsToWin: 3)
playSet(&abandoned, 11, 9)
abandoned.point(.player1); abandoned.point(.player1); abandoned.point(.player2)
check("abandoned match keeps its partial set",
      "\(abandoned.archivedSets.count) [\(abandoned.setScoreLine)]", "2 [11-9 · 2-1]")
check("partial set is marked unfinished", "\(abandoned.archivedSets.last!.isComplete)", "false")
check("partial set index follows the completed ones", "\(abandoned.archivedSets.last!.index)", "2")

check("rally counts agree with the set score",
      "\(straightSets.archivedSets[0].rallies.points(for: .player1))-\(straightSets.archivedSets[0].rallies.points(for: .player2))",
      "11-9")

// A match begun on a build without rally tracking: score restored, rally log empty.
var migrated = Engine(target: 11, setsToWin: 3)
migrated.p1Sets = 1
migrated.p1Score = 5
migrated.p2Score = 3
playSet(&migrated, 6, 2)
check("migrated set numbering continues from the set tally", "\(migrated.completedSets[0].index)", "2")
check("migrated set drops the mismatched rally log", "\(migrated.completedSets[0].rallies.count)", "0")
check("migrated set keeps the true score", migrated.completedSets[0].scoreLine, "11-5")

// MARK: - RallyLog

print("\n── RallyLog ──")

var log = RallyLog()
[Player.player1, .player2, .player2, .player1].forEach { log.append($0) }

let encoded = try! JSONEncoder().encode(log)
check("encodes as a compact digit string", String(data: encoded, encoding: .utf8)!, "\"1221\"")
check("decodes back to the same rallies",
      "\(try! JSONDecoder().decode(RallyLog.self, from: encoded).winners)", "\(log.winners)")
check("survives nesting inside [SetRecord]", {
    let set = SetRecord(id: UUID(), index: 1, p1Points: 2, p2Points: 2, winner: nil, rallies: log)
    let round = try! JSONDecoder().decode([SetRecord].self, from: try! JSONEncoder().encode([set]))
    return "\(round[0].rallies.winners.count)"
}(), "4")
check("ignores unexpected characters when decoding",
      "\(try! JSONDecoder().decode(RallyLog.self, from: "\"1x2\"".data(using: .utf8)!).count)", "2")
check("leadProgression tracks the running difference", "\(log.leadProgression)", "[0, 1, 0, -1, 0]")
check("swapped() mirrors every rally", "\(log.swapped().winners.map(\.rawValue))",
      "[\"player2\", \"player1\", \"player1\", \"player2\"]")

var removal = RallyLog()
[Player.player1, .player2, .player1, .player2, .player2].forEach { removal.append($0) }
removal.removeLastRally(wonBy: .player1)
check("removeLastRally drops that player's most recent rally",
      "\(removal.winners.map(\.rawValue))", "[\"player1\", \"player2\", \"player2\", \"player2\"]")
removal.removeLastRally(wonBy: .player1)
removal.removeLastRally(wonBy: .player1)
check("removeLastRally is a no-op once the player has none",
      "\(removal.points(for: .player1))-\(removal.points(for: .player2))", "0-3")

// MARK: - Migration

print("\n── Decoding older records ──")

let legacyJSON = """
[{"id":"\(UUID().uuidString)","date":0,"p1Name":"Simo","p2Name":"Ale","p1Score":11,"p2Score":7,
  "p1Sets":3,"p2Sets":1,"winner":"player1","targetScore":11,"bestOfSets":3,"winByTwo":true}]
"""
let legacy = try? JSONDecoder().decode([MatchRecord].self, from: legacyJSON.data(using: .utf8)!)
check("a 1.0.1 record still decodes", "\(legacy?.count ?? -1)", "1")
check("its missing columns read as absent",
      "\(legacy?[0].durationSeconds == nil) \(legacy?[0].sets == nil) \(legacy?[0].p1Id == nil)",
      "true true true")
check("setScoreLine is nil for a legacy record", "\(legacy?[0].setScoreLine == nil)", "true")
check("points fall back to the stored final score",
      "\(legacy?[0].points(for: .player1) ?? -1)", "11")

// MARK: - Statistics

print("\n── Player statistics ──")

let simo = RosterPlayer(name: "Simo", emoji: "🔥")
let ale = RosterPlayer(name: "Ale", emoji: "⚡️")
let gio = RosterPlayer(name: "Gio", emoji: "🐉")
let roster = [simo, ale, gio]

// matchRecords is stored newest-first, so build the list in that order.
let history: [MatchRecord] = [
    playMatch(setsToWin: 2, [(11, 5), (11, 7)], p1: simo, p2: ale),           // Simo beats Ale
    playMatch(setsToWin: 2, [(11, 4), (11, 9)], p1: simo, p2: gio),           // Simo beats Gio
    playMatch(setsToWin: 2, [(5, 11), (7, 11)], p1: simo, p2: ale),           // Ale beats Simo
    playMatch(setsToWin: 2, [(11, 6), (8, 11), (11, 9)], p1: ale, p2: simo),  // Ale beats Simo
    playMatch(setsToWin: 2, [(11, 3), (11, 2)], p1: simo, p2: gio),           // Simo beats Gio
]

let simoStats = MatchStatistics.stats(for: simo, in: history)
check("matches played", "\(simoStats.matchesPlayed)", "5")
check("matches won", "\(simoStats.matchesWon)", "3")
check("matches lost", "\(simoStats.matchesLost)", "2")
// Won: 2 + 2 + 0 + 1 + 2.  Lost: 0 + 0 + 2 + 2 + 0.
check("sets won-lost", "\(simoStats.setsWon)-\(simoStats.setsLost)", "7-4")
check("win rate", simoStats.winRatePercentText, "60%")
check("current streak counts the most recent run", "\(simoStats.currentStreak)", "2")
check("best win streak spans the whole history", "\(simoStats.bestWinStreak)", "2")

let aleStats = MatchStatistics.stats(for: ale, in: history)
check("opponent's record is the mirror image",
      "\(aleStats.matchesPlayed) \(aleStats.matchesWon) \(aleStats.matchesLost)", "3 2 1")
check("a losing run reads as a negative streak", "\(aleStats.currentStreak)", "-1")

let simoH2H = MatchStatistics.headToHead(for: simo, in: history, roster: roster)
check("head-to-head lists both opponents", "\(simoH2H.count)", "2")
check("head-to-head is ordered by matches played",
      simoH2H.map { "\($0.opponent.name) \($0.summary)" }.joined(separator: " | "),
      "Ale 1 - 2 | Gio 2 - 0")

// Points are summed across every set, not just the last one.
check("points aggregate across sets",
      "\(history[4].points(for: .player1))-\(history[4].points(for: .player2))", "22-5")

// A player who never appears has an empty record rather than a wrong one.
let stranger = RosterPlayer(name: "Nobody")
check("an unseen player has no record",
      "\(MatchStatistics.stats(for: stranger, in: history).matchesPlayed)", "0")

// Name fallback links records saved before the roster existed.
let unlinked = MatchRecord(
    id: UUID(), date: Date(), p1Name: " simo ", p2Name: "Ale",
    p1Score: 11, p2Score: 5, p1Sets: 2, p2Sets: 0, winner: .player1,
    targetScore: 11, bestOfSets: 2, winByTwo: true,
    durationSeconds: nil, sets: nil, p1Id: nil, p2Id: nil
)
check("name matching is case- and whitespace-insensitive",
      "\(MatchStatistics.stats(for: simo, in: [unlinked]).matchesWon)", "1")

// An explicit ID must win over a coincidental name match.
let namesake = RosterPlayer(name: "Simo")
let idLinked = MatchRecord(
    id: UUID(), date: Date(), p1Name: "Simo", p2Name: "Ale",
    p1Score: 11, p2Score: 5, p1Sets: 2, p2Sets: 0, winner: .player1,
    targetScore: 11, bestOfSets: 2, winByTwo: true,
    durationSeconds: nil, sets: nil, p1Id: simo.id, p2Id: nil
)
check("a record linked by ID is not claimed by a namesake",
      "\(MatchStatistics.stats(for: namesake, in: [idLinked]).matchesPlayed)", "0")
check("the linked player still gets it",
      "\(MatchStatistics.stats(for: simo, in: [idLinked]).matchesPlayed)", "1")

// Two roster entries sharing a normalised name BOTH claim every unlinked record — which is why
// ScoreViewModel refuses to create or rename into a duplicate name.
let clash = RosterPlayer(name: "SIMO")
check("duplicate names would both claim an unlinked record",
      "\(MatchStatistics.stats(for: simo, in: [unlinked]).matchesPlayed)"
        + "/\(MatchStatistics.stats(for: clash, in: [unlinked]).matchesPlayed)",
      "1/1")

// MARK: - Dashboard aggregates

print("\n── Dashboard aggregates ──")

let day0 = Date(timeIntervalSince1970: 1_700_000_000)          // fixed so the window is deterministic
let dayBefore = day0.addingTimeInterval(-86_400)
let weekBefore = day0.addingTimeInterval(-6 * 86_400)
var utc = Calendar(identifier: .gregorian)
utc.timeZone = TimeZone(secondsFromGMT: 0)!

let dated: [MatchRecord] = [
    playMatch(setsToWin: 2, [(11, 5), (11, 7)], p1: simo, p2: ale, date: day0),
    playMatch(setsToWin: 2, [(11, 4), (11, 9)], p1: simo, p2: gio, date: day0),
    playMatch(setsToWin: 2, [(5, 11), (7, 11)], p1: simo, p2: ale, date: dayBefore),
    playMatch(setsToWin: 2, [(11, 6), (8, 11), (11, 9)], p1: ale, p2: simo, date: weekBefore),
]

let window = MatchStatistics.activity(in: dated, days: 7, endingOn: day0, calendar: utc)
check("activity window has one entry per day", "\(window.count)", "7")
check("activity is oldest-first with gaps preserved",
      window.map { "\($0.matches)" }.joined(separator: ","), "1,0,0,0,0,1,2")
check("activity ignores matches outside the window",
      "\(MatchStatistics.activity(in: dated, days: 2, endingOn: day0, calendar: utc).map(\.matches))", "[1, 2]")
check("a zero-day window is empty",
      "\(MatchStatistics.activity(in: dated, days: 0, endingOn: day0, calendar: utc).count)", "0")

let board = MatchStatistics.leaderboard(roster: roster + [stranger], records: dated)
check("leaderboard excludes players who never played", "\(board.count)", "3")
// Ale 2-1, Simo 2-2, Gio 0-1 across the four dated matches.
check("leaderboard is ordered by win rate",
      board.map { "\($0.player.name) \($0.stats.winRatePercentText)" }.joined(separator: " | "),
      "Ale 67% | Simo 50% | Gio 0%")

let tallies = MatchStatistics.setScoreDistribution(in: dated)
check("set-score distribution folds both orientations together",
      tallies.map { "\($0.label)×\($0.count)" }.joined(separator: ","), "2-0×3,2-1×1")

let totals = MatchStatistics.overallTotals(in: dated)
check("totals count every match", "\(totals.matches)/\(totals.completed)", "4/4")
check("rallies are summed across sets", "\(totals.rallies)", "\(dated.reduce(0) { $0 + $1.totalRallies })")
check("untimed matches do not drag the average down",
      "\(totals.timedMatches) \(totals.averageSeconds)", "0 0")

// MARK: - Result

print("")
if failures == 0 {
    print("ALL CHECKS PASSED")
    exit(0)
} else {
    print("\(failures) CHECK(S) FAILED")
    exit(1)
}
