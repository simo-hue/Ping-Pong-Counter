import Foundation

/// Runtime localization for the watchOS companion.
///
/// The Watch target compiles from a synchronized folder group and does not share the iOS app's
/// `Localized.swift`, so the strings the watch surfaces need are mirrored here using the same
/// "detect the system language at runtime" strategy.
enum WatchLocalized {
    static var isItalian: Bool {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        return language.hasPrefix("it")
    }

    // Shown until the first state sync arrives from the paired iPhone.
    static var defaultP1Name: String { isItalian ? "Giocatore 1" : "Player 1" }
    static var defaultP2Name: String { isItalian ? "Giocatore 2" : "Player 2" }

    static var undo: String { isItalian ? "Annulla" : "Undo" }
    static var cancel: String { isItalian ? "Annulla" : "Cancel" }
    static var resetMatch: String { isItalian ? "Reset partita" : "Reset match" }
    static var resetConfirmTitle: String { isItalian ? "Azzerare la partita?" : "Reset match?" }
    static var resetConfirmAction: String { isItalian ? "Azzera" : "Reset" }
    static var winnerTitle: String { isItalian ? "VINCITORE!" : "WINNER!" }
    static var newMatch: String { isItalian ? "Nuova Partita" : "New Match" }
}
