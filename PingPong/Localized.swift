import Foundation

public struct Localized {
    // Determine system language code at runtime
    public static var isItalian: Bool {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return lang.hasPrefix("it")
    }
    
    // UI Settings Screen Labels
    public static var playersHeader: String { isItalian ? "Giocatori" : "Players" }
    public static var p1Placeholder: String { isItalian ? "Giocatore 1 (Sinistra)" : "Player 1 (Left)" }
    public static var p2Placeholder: String { isItalian ? "Giocatore 2 (Destra)" : "Player 2 (Right)" }
    public static var rulesHeader: String { isItalian ? "Regole Partita" : "Match Rules" }
    public static var pointsPerSet: String { isItalian ? "Punti per Set" : "Points per Set" }
    public static var points11: String { isItalian ? "11 Punti (Standard)" : "11 Points (Standard)" }
    public static var points21: String { isItalian ? "21 Punti (Classico)" : "21 Points (Classic)" }
    public static var matchDuration: String { isItalian ? "Durata Match (Set)" : "Match Duration (Sets)" }
    public static var singleSet: String { isItalian ? "Set Singolo" : "Single Set" }
    public static var bestOf3: String { isItalian ? "Al meglio di 3 set" : "Best of 3 sets" }
    public static var bestOf5: String { isItalian ? "Al meglio di 5 set" : "Best of 5 sets" }
    public static var winByTwo: String { isItalian ? "Vantaggi (Vinci con 2 punti di scarto)" : "Deuce (Win by 2 points)" }
    public static var serviceRotation: String { isItalian ? "Rotazione Servizio" : "Service Rotation" }
    public static var every2Serves: String { isItalian ? "Ogni 2 servizi" : "Every 2 serves" }
    public static var every5Serves: String { isItalian ? "Ogni 5 servizi" : "Every 5 serves" }
    public static var audioHeader: String { isItalian ? "Audio & Voce" : "Audio & Voice" }
    public static var voiceAssistant: String { isItalian ? "Assistente Vocale (Sintesi Vocale)" : "Voice Assistant (Speech)" }
    public static var styleHeader: String { isItalian ? "Stile & Temi" : "Style & Themes" }
    public static var graphicTheme: String { isItalian ? "Tema Grafico" : "Graphic Theme" }
    public static var themePreview: String { isItalian ? "Anteprima Tema:" : "Theme Preview:" }
    public static var appInfoHeader: String { isItalian ? "Supporto e Privacy" : "Support and Privacy" }
    public static var supportLink: String { isItalian ? "Supporto" : "Support" }
    public static var privacyPolicy: String { isItalian ? "Privacy Policy" : "Privacy Policy" }
    public static var resetMatch: String { isItalian ? "Resetta Partita" : "Reset Match" }
    public static var settingsTitle: String { isItalian ? "Impostazioni" : "Settings" }
    public static var closeButton: String { isItalian ? "Chiudi" : "Close" }
    
    // Main Scoreboard UI Labels
    public static var defaultP1Name: String { isItalian ? "Giocatore 1" : "Player 1" }
    public static var defaultP2Name: String { isItalian ? "Giocatore 2" : "Player 2" }
    public static var serveButton: String { isItalian ? "SERVIZIO" : "SERVE" }
    public static var winnerTitle: String { isItalian ? "VINCITORE!" : "WINNER!" }
    
    // Vocal Referee Speech Syntheses
    public static func speechMatchPoint(for name: String, p1Score: Int, p2Score: Int, server: String) -> String {
        if isItalian {
            return "Match Point per \(name)! Punteggio: \(p1Score) a \(p2Score). Batte \(server)."
        } else {
            return "Match Point for \(name)! Score: \(p1Score) to \(p2Score). Service \(server)."
        }
    }
    
    public static func speechSetPoint(for name: String, p1Score: Int, p2Score: Int, server: String) -> String {
        if isItalian {
            return "Set Point per \(name)! Punteggio: \(p1Score) a \(p2Score). Batte \(server)."
        } else {
            return "Set Point for \(name)! Score: \(p1Score) to \(p2Score). Service \(server)."
        }
    }
    
    public static func speechDeuce(score: Int, server: String) -> String {
        if isItalian {
            return "Parità! Vantaggi! \(score) pari. Batte \(server)."
        } else {
            return "Deuce! \(score) all. Service \(server)."
        }
    }
    
    public static func speechAll(score: Int, server: String) -> String {
        if isItalian {
            return "Parità. \(score) pari. Batte \(server)."
        } else {
            return "Tie. \(score) all. Service \(server)."
        }
    }
    
    public static func speechStandard(p1Score: Int, p2Score: Int, server: String) -> String {
        if isItalian {
            return "\(p1Score) a \(p2Score). Batte \(server)."
        } else {
            return "\(p1Score) to \(p2Score). Service \(server)."
        }
    }
    
    public static func speechWinner(name: String) -> String {
        if isItalian {
            return "Match completato! Vince \(name)!"
        } else {
            return "Match over! Winner \(name)!"
        }
    }
}
