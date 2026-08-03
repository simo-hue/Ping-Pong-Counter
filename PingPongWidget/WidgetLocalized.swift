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
