import Foundation

// Mirrors PingPong/ScoreViewModel.swift's Player.
enum Player: String, Codable { case player1, player2
    var opponent: Player { self == .player1 ? .player2 : .player1 } }

// Replays the real archive rules against a scripted match.
struct Engine {
    var p1Score = 0, p2Score = 0, p1Sets = 0, p2Sets = 0
    var winner: Player?
    var completedSets: [SetRecord] = []
    var currentSetRallies = RallyLog()
    let target: Int, setsToWin: Int, winByTwo = true

    mutating func point(_ p: Player) {
        guard winner == nil else { return }
        currentSetRallies.append(p)
        if p == .player1 { p1Score += 1 } else { p2Score += 1 }
        if won(p1Score, p2Score) { complete(.player1) }
        else if won(p2Score, p1Score) { complete(.player2) }
    }
    func won(_ a: Int, _ b: Int) -> Bool { a >= target && (!winByTwo || a - b >= 2) }

    mutating func complete(_ w: Player) {
        if w == .player1 { p1Sets += 1 } else { p2Sets += 1 }
        completedSets.append(SetRecord(id: UUID(), index: p1Sets + p2Sets,
            p1Points: p1Score, p2Points: p2Score, winner: w,
            rallies: rallyLog(currentSetRallies, matching: p1Score, p2Score)))
        currentSetRallies.removeAll()
        if (w == .player1 ? p1Sets : p2Sets) >= setsToWin { winner = w }
        else { p1Score = 0; p2Score = 0 }
    }

    func rallyLog(_ l: RallyLog, matching a: Int, _ b: Int) -> RallyLog {
        l.accountsFor(p1Points: a, p2Points: b) ? l : RallyLog()
    }

    var archivedSets: [SetRecord] {
        var sets = completedSets
        if winner == nil, p1Score > 0 || p2Score > 0 || !currentSetRallies.isEmpty {
            sets.append(SetRecord(id: UUID(), index: p1Sets + p2Sets + 1,
                p1Points: p1Score, p2Points: p2Score, winner: nil,
                rallies: rallyLog(currentSetRallies, matching: p1Score, p2Score)))
        }
        return sets
    }
    var setScoreLine: String { archivedSets.map(\.scoreLine).joined(separator: " · ") }
}

func playSet(_ e: inout Engine, _ a: Int, _ b: Int) {
    for _ in 0..<b { e.point(.player2) }
    for _ in 0..<a { e.point(.player1) }
}

var fail = 0
func check(_ name: String, _ got: String, _ want: String) {
    let ok = got == want
    if !ok { fail += 1 }
    print("\(ok ? "PASS" : "FAIL") \(name)\n     got=\(got)\n    want=\(want)")
}

// 1. Straight-sets win, first to 3 — the blocker case.
var a = Engine(target: 11, setsToWin: 3)
playSet(&a, 11, 9); playSet(&a, 11, 8); playSet(&a, 11, 6)
check("completed 3-0 match", "\(a.archivedSets.count) [\(a.setScoreLine)]", "3 [11-9 · 11-8 · 11-6]")
check("set indices", a.archivedSets.map { "\($0.index)" }.joined(separator: ","), "1,2,3")

// 2. Single-set match.
var b = Engine(target: 11, setsToWin: 1)
playSet(&b, 11, 4)
check("completed single-set match", "\(b.archivedSets.count) [\(b.setScoreLine)]", "1 [11-4]")

// 3. Abandoned mid-set — the partial set must still be kept.
var c = Engine(target: 11, setsToWin: 3)
playSet(&c, 11, 9)
c.point(.player1); c.point(.player1); c.point(.player2)
check("abandoned match keeps partial set", "\(c.archivedSets.count) [\(c.setScoreLine)]", "2 [11-9 · 2-1]")
check("partial set index", "\(c.archivedSets.last!.index)", "2")
check("partial set unfinished", "\(c.archivedSets.last!.isComplete)", "false")

// 4. Rally-log integrity on the normal path.
check("rally counts match score", "\(a.archivedSets[0].rallies.points(for: .player1))-\(a.archivedSets[0].rallies.points(for: .player2))", "11-9")

// 5. Migration: score restored from an older build, rally log empty.
var d = Engine(target: 11, setsToWin: 3)
d.p1Sets = 1; d.p1Score = 5; d.p2Score = 3   // resumed from 1.0.1, no rally history
playSet(&d, 6, 2)                             // finish the set 11-5
check("migrated set numbering", "\(d.completedSets[0].index)", "2")
check("migrated set drops mismatched log", "\(d.completedSets[0].rallies.count)", "0")
check("migrated set keeps true score", d.completedSets[0].scoreLine, "11-5")

// 6. RallyLog compact Codable round-trip.
var log = RallyLog(); [Player.player1, .player2, .player2, .player1].forEach { log.append($0) }
let data = try! JSONEncoder().encode(log)
check("compact encoding", String(data: data, encoding: .utf8)!, "\"1221\"")
check("decode round-trip", "\(try! JSONDecoder().decode(RallyLog.self, from: data).winners)", "\(log.winners)")
check("nested in SetRecord", {
    let s = SetRecord(id: UUID(), index: 1, p1Points: 2, p2Points: 2, winner: nil, rallies: log)
    let r = try! JSONDecoder().decode([SetRecord].self, from: try! JSONEncoder().encode([s]))
    return "\(r[0].rallies.winners.count)" }(), "4")

// 7. leadProgression + swapped().
check("leadProgression", "\(log.leadProgression)", "[0, 1, 0, -1, 0]")
check("swapped mirrors", "\(log.swapped().winners)", "[PingPongTest.Player.player2, PingPongTest.Player.player1, PingPongTest.Player.player1, PingPongTest.Player.player2]")

print(fail == 0 ? "\nALL CHECKS PASSED" : "\n\(fail) CHECK(S) FAILED")
exit(fail == 0 ? 0 : 1)
