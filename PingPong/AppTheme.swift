import SwiftUI

/// The neon palettes the scoreboard, settings and match history all draw from.
///
/// Previously each screen carried its own copy of these colours as an ad-hoc tuple array, which
/// meant a palette tweak had to be made in several places and the history screen had no access to
/// them at all.
struct AppTheme: Identifiable {
    let id: Int
    let name: String
    /// Short colour description shown alongside the name in settings.
    let subtitle: String
    let p1Color: Color
    let p2Color: Color
    let bgStart: Color
    let bgEnd: Color

    static let all: [AppTheme] = [
        AppTheme(
            id: 0,
            name: "Néon Classic",
            subtitle: Localized.isItalian ? "Rosso & Blu" : "Red & Blue",
            p1Color: Color(red: 1.0, green: 0.25, blue: 0.35),
            p2Color: Color(red: 0.0, green: 0.7, blue: 1.0),
            bgStart: Color(red: 0.08, green: 0.02, blue: 0.03),
            bgEnd: Color(red: 0.02, green: 0.04, blue: 0.08)
        ),
        AppTheme(
            id: 1,
            name: "Mint & Royal",
            subtitle: Localized.isItalian ? "Verde & Viola" : "Green & Purple",
            p1Color: Color(red: 0.0, green: 0.85, blue: 0.55),
            p2Color: Color(red: 0.55, green: 0.3, blue: 0.9),
            bgStart: Color(red: 0.01, green: 0.06, blue: 0.04),
            bgEnd: Color(red: 0.04, green: 0.02, blue: 0.06)
        ),
        AppTheme(
            id: 2,
            name: "Solar Flare",
            subtitle: Localized.isItalian ? "Arancione & Teal" : "Orange & Teal",
            p1Color: Color(red: 1.0, green: 0.55, blue: 0.0),
            p2Color: Color(red: 0.0, green: 0.8, blue: 0.8),
            bgStart: Color(red: 0.06, green: 0.03, blue: 0.0),
            bgEnd: Color(red: 0.0, green: 0.05, blue: 0.05)
        )
    ]

    static func theme(at index: Int) -> AppTheme {
        all.indices.contains(index) ? all[index] : all[0]
    }

    func color(for player: Player) -> Color {
        player == .player1 ? p1Color : p2Color
    }
}
