import SwiftUI

/// The two players of one doubles team, with the current server and receiver called out.
///
/// Lives outside ContentView so it can be type-checked against the real SwiftUI framework — the
/// scoreboard itself imports UIKit and cannot be. In doubles the glowing half only says which
/// *pair* is up; the rotation is the thing players lose track of, so the individual has to be named.
struct DoublesRosterStrip: View {
    let lineup: DoublesLineup
    let team: Player
    let servingSeat: DoublesSeat?
    let receivingSeat: DoublesSeat?
    let themeColor: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach([TeamSlot.first, .second], id: \.self) { slot in
                seatBadge(DoublesSeat(team: team, slot: slot))
            }
        }
        .padding(.horizontal, 6)
    }

    private func seatBadge(_ seat: DoublesSeat) -> some View {
        let isServing = seat == servingSeat
        let isReceiving = seat == receivingSeat

        return VStack(spacing: 2) {
            Text(lineup.name(for: seat))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(isServing ? .yellow : .white.opacity(isReceiving ? 0.7 : 0.35))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // A blank keeps the two badges the same height whichever role they hold.
            Text(isServing ? Localized.servingLabel : (isReceiving ? Localized.receivingLabel : " "))
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundColor(isServing ? .yellow.opacity(0.9) : .white.opacity(0.3))
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(isServing ? Color.yellow.opacity(0.14) : Color.white.opacity(0.04))
        )
        .overlay(
            Capsule().stroke(isReceiving ? themeColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            lineup.name(for: seat)
                + (isServing ? ", \(Localized.servingLabel)" : "")
                + (isReceiving ? ", \(Localized.receivingLabel)" : "")
        )
    }
}
