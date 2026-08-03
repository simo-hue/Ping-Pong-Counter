import Foundation

/// Runtime localization for the widget extension.
///
/// The extension compiles from a synchronized folder group and does not share the app target's
/// `Localized.swift`, so the few strings the Lock Screen and Dynamic Island surfaces need are
/// mirrored here using the same "detect the system language at runtime" strategy.
enum WidgetLocalized {
    static var isItalian: Bool {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        return language.hasPrefix("it")
    }

    static func winnerBanner(name: String) -> String {
        isItalian ? "Vince \(name)!" : "\(name) wins!"
    }

    static func scoreAccessibilityLabel(p1Score: Int, p2Score: Int) -> String {
        isItalian ? "Punteggio \(p1Score) a \(p2Score)" : "Score \(p1Score) to \(p2Score)"
    }

    static var setsLabel: String { isItalian ? "SET" : "SETS" }
    static var matchLabel: String { isItalian ? "MATCH" : "MATCH" }
}

extension WidgetLocalized {
    static var undoLabel: String { isItalian ? "Annulla ultimo punto" : "Undo last point" }
    static func addPointLabel(name: String) -> String {
        isItalian ? "Punto per \(name)" : "Point for \(name)"
    }
    static var lastMatchLabel: String { isItalian ? "Ultima partita" : "Last match" }
    static var noMatchesLabel: String { isItalian ? "Nessuna partita" : "No matches yet" }
    static var liveLabel: String { isItalian ? "IN CORSO" : "LIVE" }
    static var widgetDisplayName: String { isItalian ? "Punteggio" : "Score" }
    static var widgetDescription: String {
        isItalian ? "Il punteggio in corso o l'ultimo risultato." : "The match in progress, or your last result."
    }
}
