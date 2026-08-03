import Foundation

/// Which of a team's two players a seat refers to.
enum TeamSlot: String, Codable, Equatable, Hashable {
    case first
    case second

    var partner: TeamSlot { self == .first ? .second : .first }
}

/// One of the four places at a doubles table: a team plus which of its two players.
struct DoublesSeat: Codable, Equatable, Hashable, Identifiable {
    let team: Player
    let slot: TeamSlot

    var id: String { "\(team.rawValue)-\(slot.rawValue)" }

    /// The other player on the same team.
    var partner: DoublesSeat { DoublesSeat(team: team, slot: slot.partner) }

    static let all: [DoublesSeat] = [
        DoublesSeat(team: .player1, slot: .first),
        DoublesSeat(team: .player1, slot: .second),
        DoublesSeat(team: .player2, slot: .first),
        DoublesSeat(team: .player2, slot: .second)
    ]
}

/// The four players of a doubles match and the ITTF serving rotation between them.
///
/// The rotation is the thing players actually forget mid-match, and it is fully determined by two
/// facts: who serves the first rally of the set and who receives it. Everything else follows,
/// because in doubles *the receiver of one serve turn becomes the server of the next*:
///
///     A1 serves to B1  →  B1 serves to A2  →  A2 serves to B2  →  B2 serves to A1  →  …
///
/// So the four seats form a fixed cycle `[server, receiver, server's partner, receiver's partner]`
/// and each serve turn advances it by one position.
///
/// NOT modelled: the deciding-set rule where the receiving pair reverses its order once a pair
/// reaches half the target. That rule is paired with a compulsory change of ends, which this app
/// leaves as a manual action, so automating one half would put the two out of step.
struct DoublesLineup: Codable, Equatable {
    var teamOneFirstName: String
    var teamOneSecondName: String
    var teamTwoFirstName: String
    var teamTwoSecondName: String

    /// Seat serving the first rally of the current set.
    private(set) var setStartingServer: DoublesSeat
    /// Seat receiving that first rally. Always on the opposing team.
    private(set) var setStartingReceiver: DoublesSeat

    init(
        teamOneFirstName: String,
        teamOneSecondName: String,
        teamTwoFirstName: String,
        teamTwoSecondName: String,
        setStartingServer: DoublesSeat = DoublesSeat(team: .player1, slot: .first),
        setStartingReceiver: DoublesSeat = DoublesSeat(team: .player2, slot: .first)
    ) {
        self.teamOneFirstName = teamOneFirstName
        self.teamOneSecondName = teamOneSecondName
        self.teamTwoFirstName = teamTwoFirstName
        self.teamTwoSecondName = teamTwoSecondName
        self.setStartingServer = setStartingServer
        self.setStartingReceiver = Self.resolvedReceiver(setStartingReceiver, facing: setStartingServer)
    }

    /// A receiver must sit on the opposing team; anything else would make the cycle incoherent.
    /// Rather than trap on bad input (which can arrive from decoded state), fall back to that
    /// team's first slot.
    private static func resolvedReceiver(_ receiver: DoublesSeat, facing server: DoublesSeat) -> DoublesSeat {
        receiver.team == server.team.opponent
            ? receiver
            : DoublesSeat(team: server.team.opponent, slot: .first)
    }

    // MARK: - Names

    func name(for seat: DoublesSeat) -> String {
        switch (seat.team, seat.slot) {
        case (.player1, .first): return teamOneFirstName
        case (.player1, .second): return teamOneSecondName
        case (.player2, .first): return teamTwoFirstName
        case (.player2, .second): return teamTwoSecondName
        }
    }

    mutating func setName(_ name: String, for seat: DoublesSeat) {
        switch (seat.team, seat.slot) {
        case (.player1, .first): teamOneFirstName = name
        case (.player1, .second): teamOneSecondName = name
        case (.player2, .first): teamTwoFirstName = name
        case (.player2, .second): teamTwoSecondName = name
        }
    }

    func names(for team: Player) -> (first: String, second: String) {
        team == .player1
            ? (teamOneFirstName, teamOneSecondName)
            : (teamTwoFirstName, teamTwoSecondName)
    }

    // MARK: - Rotation

    /// The four seats in serving order for the current set.
    var serveCycle: [DoublesSeat] {
        [setStartingServer, setStartingReceiver, setStartingServer.partner, setStartingReceiver.partner]
    }

    /// How many serve turns have been completed after `totalPoints` rallies.
    ///
    /// Deuce SHORTENS each remaining turn to one point; it does not restart the sequence. Dividing
    /// the whole set by the post-deuce interval would therefore re-count every turn already played
    /// and jump the rotation — invisible in singles, where the error is always even and the
    /// two-way alternation survives it, but plainly wrong on a four-seat cycle.
    ///
    /// - Parameters:
    ///   - interval: points per turn BEFORE deuce. Never pass an already-collapsed interval.
    ///   - deuceAfter: total points at which both sides reach `targetScore - 1`.
    static func serveTurns(totalPoints: Int, interval: Int, deuceAfter: Int) -> Int {
        let points = max(0, totalPoints)
        let interval = max(1, interval)
        let deuceAfter = max(0, deuceAfter)

        guard points >= deuceAfter else { return points / interval }

        // A turn only part-played when deuce arrives is ended by the deuce rule, so round up.
        let turnsBeforeDeuce = (deuceAfter + interval - 1) / interval
        return turnsBeforeDeuce + (points - deuceAfter)
    }

    func server(afterServeTurns turns: Int) -> DoublesSeat {
        serveCycle[wrapped(turns)]
    }

    func receiver(afterServeTurns turns: Int) -> DoublesSeat {
        serveCycle[wrapped(turns + 1)]
    }

    func server(totalPoints: Int, interval: Int, deuceAfter: Int) -> DoublesSeat {
        server(afterServeTurns: Self.serveTurns(totalPoints: totalPoints, interval: interval, deuceAfter: deuceAfter))
    }

    func receiver(totalPoints: Int, interval: Int, deuceAfter: Int) -> DoublesSeat {
        receiver(afterServeTurns: Self.serveTurns(totalPoints: totalPoints, interval: interval, deuceAfter: deuceAfter))
    }

    private func wrapped(_ index: Int) -> Int {
        let count = serveCycle.count
        return ((index % count) + count) % count
    }

    // MARK: - Transitions

    /// ITTF: the player who received first in a set serves first in the next, and the player who
    /// served to them becomes the first receiver. Swapping the two seats produces exactly that.
    func advancedToNextSet() -> DoublesLineup {
        var next = self
        next.setStartingServer = setStartingReceiver
        next.setStartingReceiver = setStartingServer
        return next
    }

    /// Advances the opening by one seat around the cycle — the smallest correction available when
    /// the players decide the wrong person is serving.
    func rotatedOpening() -> DoublesLineup {
        var next = self
        next.setStartingServer = setStartingReceiver
        next.setStartingReceiver = setStartingServer.partner
        return next
    }

    /// Reassigns who opens the current set. Used when the players correct the rotation by hand.
    mutating func setOpening(server: DoublesSeat, receiver: DoublesSeat) {
        setStartingServer = server
        setStartingReceiver = Self.resolvedReceiver(receiver, facing: server)
    }

    /// Mirrors the lineup when the teams change ends: every seat moves to the opposite team,
    /// keeping its slot so partnerships stay intact.
    func swappedTeams() -> DoublesLineup {
        var swapped = self
        swapped.teamOneFirstName = teamTwoFirstName
        swapped.teamOneSecondName = teamTwoSecondName
        swapped.teamTwoFirstName = teamOneFirstName
        swapped.teamTwoSecondName = teamOneSecondName
        swapped.setStartingServer = DoublesSeat(team: setStartingServer.team.opponent, slot: setStartingServer.slot)
        swapped.setStartingReceiver = DoublesSeat(team: setStartingReceiver.team.opponent, slot: setStartingReceiver.slot)
        return swapped
    }

    /// Swaps which of a team's two players occupies the first slot, without disturbing the other
    /// team or the current rotation phase.
    mutating func swapPartners(on team: Player) {
        let current = names(for: team)
        setName(current.second, for: DoublesSeat(team: team, slot: .first))
        setName(current.first, for: DoublesSeat(team: team, slot: .second))

        if setStartingServer.team == team { setStartingServer = setStartingServer.partner }
        if setStartingReceiver.team == team { setStartingReceiver = setStartingReceiver.partner }
    }

    static func makeDefault() -> DoublesLineup {
        DoublesLineup(
            teamOneFirstName: Localized.defaultDoublesName(team: 1, slot: 1),
            teamOneSecondName: Localized.defaultDoublesName(team: 1, slot: 2),
            teamTwoFirstName: Localized.defaultDoublesName(team: 2, slot: 1),
            teamTwoSecondName: Localized.defaultDoublesName(team: 2, slot: 2)
        )
    }
}
