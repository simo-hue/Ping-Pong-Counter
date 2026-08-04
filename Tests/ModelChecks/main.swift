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

// MARK: - Doubles rotation

print("\n── Doubles rotation ──")

// A1/A2 on team 1, B1/B2 on team 2. A1 opens serving to B1.
var lineup = DoublesLineup(
    teamOneFirstName: "A1", teamOneSecondName: "A2",
    teamTwoFirstName: "B1", teamTwoSecondName: "B2"
)

func cycleNames(_ lineup: DoublesLineup) -> String {
    lineup.serveCycle.map(lineup.name(for:)).joined(separator: "→")
}

/// The server→receiver pairing across `turns` consecutive serve turns.
func rotation(_ lineup: DoublesLineup, turns: Int) -> String {
    (0..<turns).map { turn in
        "\(lineup.name(for: lineup.server(afterServeTurns: turn)))>\(lineup.name(for: lineup.receiver(afterServeTurns: turn)))"
    }.joined(separator: " ")
}

check("the cycle is server, receiver, then their partners", cycleNames(lineup), "A1→B1→A2→B2")
check("each receiver serves the next turn", rotation(lineup, turns: 4), "A1>B1 B1>A2 A2>B2 B2>A1")
check("the cycle repeats after four turns", rotation(lineup, turns: 6),
      "A1>B1 B1>A2 A2>B2 B2>A1 A1>B1 B1>A2")

// Serve turns advance every `interval` points, and every point once at deuce.
check("two-point rotation hands over on the third point",
      (0..<6).map { lineup.name(for: lineup.server(totalPoints: $0, interval: 2, deuceAfter: 20)) }.joined(separator: ","),
      "A1,A1,B1,B1,A2,A2")
check("five-point rotation holds the serve longer",
      (0..<12).map { lineup.name(for: lineup.server(totalPoints: $0, interval: 5, deuceAfter: 20)) }.joined(separator: ","),
      "A1,A1,A1,A1,A1,B1,B1,B1,B1,B1,A2,A2")
// Deuce shortens each remaining turn to one point; it does NOT restart the sequence. The old
// check passed `interval: 1` directly, which assumed the very thing under test — so walk a real
// game through the interval change instead and compare against a rally-by-rally simulation.
func legalServerSequence(target: Int, interval: Int, points: Int, _ lineup: DoublesLineup) -> [String] {
    var turn = 0, servedThisTurn = 0, p1 = 0, p2 = 0
    var names: [String] = []
    for i in 0..<points {
        names.append(lineup.name(for: lineup.server(afterServeTurns: turn)))
        let limit = (p1 >= target - 1 && p2 >= target - 1) ? 1 : interval
        servedThisTurn += 1
        if servedThisTurn >= limit { turn += 1; servedThisTurn = 0 }
        if i % 2 == 0 { p1 += 1 } else { p2 += 1 }
    }
    return names
}
func appServerSequence(target: Int, interval: Int, points: Int, _ lineup: DoublesLineup) -> [String] {
    (0..<points).map { tp in
        lineup.name(for: lineup.server(totalPoints: tp, interval: interval, deuceAfter: 2 * (target - 1)))
    }
}
check("the standard 11-point game keeps rotating correctly through deuce",
      appServerSequence(target: 11, interval: 2, points: 26, lineup).suffix(6).joined(separator: ","),
      legalServerSequence(target: 11, interval: 2, points: 26, lineup).suffix(6).joined(separator: ","))
check("the seat at 10-10 is the one the rules say",
      lineup.name(for: lineup.server(totalPoints: 20, interval: 2, deuceAfter: 20)), "A2")

// Sweep every plausible format against the simulation — this is the check that would have caught
// the original single-division formula.
var sweepMismatches: [String] = []
// Sweep the rule-DEFINED space: serveRotationInterval is restricted to {2, 5}, and the interval
// must divide the deuce point total. Where it does not (a game to 3 with 5-serve turns) deuce
// arrives mid-turn, and no ITTF law says whether that turn ends immediately or finishes its point
// — the convention is asserted separately below rather than pretended to be a rule.
for target in 1...30 {
    for interval in [2, 5] where (2 * (target - 1)) % interval == 0 {
        let points = 2 * (target - 1) + 10
        let want = legalServerSequence(target: target, interval: interval, points: points, lineup)
        let got = appServerSequence(target: target, interval: interval, points: points, lineup)
        if want != got, sweepMismatches.count < 3 {
            let at = zip(want, got).enumerated().first { $0.element.0 != $0.element.1 }?.offset ?? -1
            sweepMismatches.append("target=\(target) interval=\(interval) at \(at) points")
        }
    }
}
check("serve rotation matches the rules for every reachable target and interval",
      sweepMismatches.isEmpty ? "no mismatches" : sweepMismatches.joined(separator: "; "), "no mismatches")

// Singles derives its side from the same turn count, so parity must hold there too.
var singlesMismatches = 0
for target in 1...30 {
    for interval in [2, 5] where (2 * (target - 1)) % interval == 0 {
        let points = 2 * (target - 1) + 10
        var turn = 0, served = 0, p1 = 0, p2 = 0
        for i in 0..<points {
            let appTurn = DoublesLineup.serveTurns(totalPoints: i, interval: interval, deuceAfter: 2 * (target - 1))
            if appTurn % 2 != turn % 2 { singlesMismatches += 1 }
            let limit = (p1 >= target - 1 && p2 >= target - 1) ? 1 : interval
            served += 1
            if served >= limit { turn += 1; served = 0 }
            if i % 2 == 0 { p1 += 1 } else { p2 += 1 }
        }
    }
}
check("singles side alternation matches the rules across the same sweep", "\(singlesMismatches)", "0")

// Documented convention for the undefined boundary: a turn only part-played when deuce arrives is
// treated as finished, so the serve changes hands at deuce rather than completing a long turn.
check("a part-played turn is ended by deuce, not completed",
      "\(DoublesLineup.serveTurns(totalPoints: 4, interval: 5, deuceAfter: 4))", "1")
check("turn counting is monotonic across the deuce boundary", {
    var previous = -1
    var monotonic = true
    for tp in 0...30 {
        let turns = DoublesLineup.serveTurns(totalPoints: tp, interval: 5, deuceAfter: 12)
        if turns < previous { monotonic = false }
        previous = turns
    }
    return "\(monotonic)"
}(), "true")

// ITTF: whoever received first serves first in the next set, and the player who served to them receives.
let set2 = lineup.advancedToNextSet()
check("next set is opened by the previous first receiver", set2.name(for: set2.serveCycle[0]), "B1")
check("next set's first receiver is the previous first server", set2.name(for: set2.serveCycle[1]), "A1")
check("next set's cycle stays alternating", cycleNames(set2), "B1→A1→B2→A2")
check("a third set rotates on again", cycleNames(set2.advancedToNextSet()), "A1→B1→A2→B2")
check("every seat opens a set within four sets",
      [lineup, set2, set2.advancedToNextSet(), set2.advancedToNextSet().advancedToNextSet()]
        .map { $0.name(for: $0.serveCycle[0]) }.joined(separator: ","),
      "A1,B1,A1,B1")

// Every serve must cross the net, in every set and at every phase.
var crossingFailures = 0
var walk = lineup
for _ in 0..<6 {
    for turn in 0..<8 {
        let server = walk.server(afterServeTurns: turn)
        let receiver = walk.receiver(afterServeTurns: turn)
        if server.team == receiver.team { crossingFailures += 1 }
        if server == receiver { crossingFailures += 1 }
    }
    walk = walk.advancedToNextSet()
}
check("a server never serves to their own team", "\(crossingFailures)", "0")

// Each seat serves exactly one turn in four, and receives exactly one.
var served: [String: Int] = [:]
var receivedCount: [String: Int] = [:]
for turn in 0..<4 {
    served[lineup.name(for: lineup.server(afterServeTurns: turn)), default: 0] += 1
    receivedCount[lineup.name(for: lineup.receiver(afterServeTurns: turn)), default: 0] += 1
}
check("all four seats serve once per cycle", served.values.sorted().map(String.init).joined(separator: ","), "1,1,1,1")
check("all four seats receive once per cycle", receivedCount.values.sorted().map(String.init).joined(separator: ","), "1,1,1,1")

// Changing ends mirrors the teams but keeps partnerships and the rotation phase intact.
let swapped = lineup.swappedTeams()
check("changing ends moves both pairs across", "\(swapped.teamOneFirstName)\(swapped.teamOneSecondName)/\(swapped.teamTwoFirstName)\(swapped.teamTwoSecondName)", "B1B2/A1A2")
check("changing ends preserves who serves to whom", rotation(swapped, turns: 4), rotation(lineup, turns: 4))

// Swapping partners on one team must not disturb the other team's order.
var partnerSwap = lineup
partnerSwap.swapPartners(on: .player1)
check("swapping partners reorders only that team",
      "\(partnerSwap.teamOneFirstName)\(partnerSwap.teamOneSecondName)/\(partnerSwap.teamTwoFirstName)\(partnerSwap.teamTwoSecondName)",
      "A2A1/B1B2")
check("swapping partners keeps the same player serving first", partnerSwap.name(for: partnerSwap.serveCycle[0]), "A1")

// A receiver on the serving team is incoherent, so it is corrected rather than trusted.
let bogus = DoublesLineup(
    teamOneFirstName: "A1", teamOneSecondName: "A2",
    teamTwoFirstName: "B1", teamTwoSecondName: "B2",
    setStartingServer: DoublesSeat(team: .player1, slot: .first),
    setStartingReceiver: DoublesSeat(team: .player1, slot: .second)
)
check("a same-team receiver is corrected to the opposing team", cycleNames(bogus), "A1→B1→A2→B2")

// Manual correction of the opening rotation.
var corrected = lineup
corrected.setOpening(server: DoublesSeat(team: .player2, slot: .second), receiver: DoublesSeat(team: .player1, slot: .second))
check("the opening rotation can be reassigned", cycleNames(corrected), "B2→A2→B1→A1")

// The view model stores only the MATCH opening and derives each set's rotation, which is sound
// only because advancing is its own inverse. If that ever stopped holding, undo across a set
// boundary would silently desynchronise the rotation from the score.
check("advancing twice returns to the opening", cycleNames(lineup.advancedToNextSet().advancedToNextSet()), cycleNames(lineup))
func derivedSetLineup(_ opening: DoublesLineup, setsPlayed: Int) -> DoublesLineup {
    setsPlayed % 2 == 0 ? opening : opening.advancedToNextSet()
}
check("derived rotation alternates by set",
      (0..<4).map { cycleNames(derivedSetLineup(lineup, setsPlayed: $0)) }.joined(separator: " | "),
      "A1→B1→A2→B2 | B1→A1→B2→A2 | A1→B1→A2→B2 | B1→A1→B2→A2")

// Correcting the serve nudges the opening one seat at a time, mirroring setServer(to:).
check("rotating the opening walks the cycle",
      (0..<4).map { step -> String in
          var l = lineup
          for _ in 0..<step { l = l.rotatedOpening() }
          return l.name(for: l.serveCycle[0])
      }.joined(separator: ","),
      "A1,B1,A2,B2")
check("four rotations return to the start", cycleNames(lineup.rotatedOpening().rotatedOpening().rotatedOpening().rotatedOpening()), cycleNames(lineup))

// Round-trips through Codable, since the lineup is persisted.
let lineupData = try! JSONEncoder().encode(set2)
check("lineup survives a Codable round-trip",
      cycleNames(try! JSONDecoder().decode(DoublesLineup.self, from: lineupData)), cycleNames(set2))

// MARK: - Sync merge

print("\n── iCloud merge ──")

func syncRecord(_ label: String, at offset: TimeInterval) -> MatchRecord {
    MatchRecord(
        id: UUID(), date: Date(timeIntervalSince1970: 1_700_000_000 + offset),
        p1Name: label, p2Name: "X",
        p1Score: 11, p2Score: 5, p1Sets: 2, p2Sets: 0, winner: .player1,
        targetScore: 11, bestOfSets: 2, winByTwo: true,
        durationSeconds: nil, sets: nil, p1Id: nil, p2Id: nil
    )
}

let shared = syncRecord("shared", at: 0)
let onlyA = syncRecord("onlyA", at: 100)
let onlyB = syncRecord("onlyB", at: 200)

// The whole point: two devices each play a match offline, neither loses one.
let unioned = SyncMerge.mergeMatches(local: [onlyA, shared], remote: [onlyB, shared], deleted: [])
check("a union keeps both devices' matches",
      unioned.map(\.p1Name).joined(separator: ","), "onlyB,onlyA,shared")
check("the shared record is not duplicated",
      "\(unioned.filter { $0.id == shared.id }.count)", "1")

// Without tombstones a delete would be undone by the device that still has the record.
let afterDelete = SyncMerge.mergeMatches(local: [shared], remote: [onlyA, shared], deleted: [onlyA.id])
check("a tombstoned match stays deleted",
      afterDelete.map(\.p1Name).joined(separator: ","), "shared")
check("deleting everything leaves nothing",
      "\(SyncMerge.mergeMatches(local: [onlyA], remote: [onlyA], deleted: [onlyA.id]).count)", "0")

// Roster: a rename on one device must not be reverted by a stale copy on another.
let base = Date(timeIntervalSince1970: 1_700_000_000)
let stale = RosterPlayer(id: UUID(), name: "Ale", emoji: "⚡️", createdAt: base, updatedAt: base)
var renamed = stale
renamed.name = "Alessandro"
renamed.updatedAt = base.addingTimeInterval(60)

check("the more recent roster edit wins",
      SyncMerge.mergeRoster(local: [stale], remote: [renamed], deleted: []).map(\.name).joined(),
      "Alessandro")
check("and wins from either side",
      SyncMerge.mergeRoster(local: [renamed], remote: [stale], deleted: []).map(\.name).joined(),
      "Alessandro")
check("a roster entry with no updatedAt falls back to createdAt",
      "\(RosterPlayer(id: UUID(), name: "Old", createdAt: base).lastEdited == base)", "true")
check("a tombstoned player stays deleted",
      "\(SyncMerge.mergeRoster(local: [stale], remote: [stale], deleted: [stale.id]).count)", "0")

// Oversized history is trimmed oldest-first rather than rejected wholesale by the store.
let many = (0..<400).map { syncRecord("m\($0)", at: TimeInterval($0)) }
let trimmed = SyncMerge.recordsFitting(many, byteLimit: 20_000)
check("history is trimmed to fit the key-value budget",
      "\(trimmed.count < many.count && !trimmed.isEmpty)", "true")
check("trimming keeps the newest matches",
      "\(trimmed.first?.date == many.map(\.date).max())", "true")
check("a history that already fits is untouched",
      "\(SyncMerge.recordsFitting([onlyA, onlyB], byteLimit: 1_000_000).count)", "2")

// RosterPlayer gained updatedAt; entries saved before it must still decode.
let legacyRosterJSON = """
[{"id":"\(UUID().uuidString)","name":"Simo","emoji":"🔥","createdAt":0}]
"""
let legacyRoster = try? JSONDecoder().decode([RosterPlayer].self, from: legacyRosterJSON.data(using: .utf8)!)
check("a roster entry saved before updatedAt still decodes", "\(legacyRoster?.count ?? -1)", "1")
check("its updatedAt reads as absent", "\(legacyRoster?[0].updatedAt == nil)", "true")
check("and it merges against a newer edit without winning", {
    guard let old = legacyRoster?[0] else { return "no legacy entry" }
    var newer = old
    newer.name = "Simone"
    // Comfortably after the decoded createdAt — a bare 0 in JSON is the 2001 reference date,
    // not the Unix epoch.
    newer.updatedAt = old.createdAt.addingTimeInterval(3600)
    return SyncMerge.mergeRoster(local: [old], remote: [newer], deleted: []).map(\.name).joined()
}(), "Simone")

check("tombstones are capped",
      "\(SyncMerge.cappedTombstones(Set((0..<2500).map { _ in UUID() }), limit: 100).count)", "100")
check("a small tombstone set is left alone",
      "\(SyncMerge.cappedTombstones([onlyA.id, onlyB.id], limit: 100).count)", "2")

// MARK: - Result

print("")
if failures == 0 {
    print("ALL CHECKS PASSED")
    exit(0)
} else {
    print("\(failures) CHECK(S) FAILED")
    exit(1)
}
