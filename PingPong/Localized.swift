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
    public static var bestOf3: String { isItalian ? "Primo a 3 set" : "First to 3 sets" }
    public static var bestOf5: String { isItalian ? "Primo a 5 set" : "First to 5 sets" }
    public static var winByTwo: String { isItalian ? "Vantaggi (Vinci con 2 punti di scarto)" : "Deuce (Win by 2 points)" }
    public static var serveRulesHeader: String { isItalian ? "Servizio & Vantaggi" : "Serve & Deuce" }
    public static var serviceRotation: String { isItalian ? "Rotazione Servizio" : "Service Rotation" }
    public static var every2Serves: String { isItalian ? "Ogni 2 servizi" : "Every 2 serves" }
    public static var every5Serves: String { isItalian ? "Ogni 5 servizi" : "Every 5 serves" }
    public static var audioHeader: String { isItalian ? "Audio & Voce" : "Audio & Voice" }
    public static var voiceAssistant: String { isItalian ? "Assistente Vocale (Sintesi Vocale)" : "Voice Assistant (Speech)" }
    public static var soundEffects: String { isItalian ? "Effetti Sonori" : "Sound Effects" }
    public static var hapticsLabel: String { isItalian ? "Vibrazione" : "Haptics" }
    public static var hapticsOff: String { isItalian ? "Disattivata" : "Off" }
    public static var hapticsLight: String { isItalian ? "Leggera" : "Light" }
    public static var hapticsFull: String { isItalian ? "Completa" : "Full" }
    public static var displayHeader: String { isItalian ? "Schermo" : "Display" }
    public static var keepScreenAwake: String { isItalian ? "Mantieni Schermo Acceso" : "Keep Screen Awake" }
    public static var keepScreenAwakeFooter: String {
        isItalian
            ? "Impedisce il blocco automatico mentre una partita è in corso."
            : "Prevents auto-lock while a match is in progress."
    }
    public static var showMatchTimer: String { isItalian ? "Mostra Cronometro" : "Show Match Timer" }

    // Custom target score
    public static var applyNewRules: String { isItalian ? "Applica Nuove Regole" : "Apply New Rules" }
    public static var applyRulesConfirmTitle: String {
        isItalian ? "Applicare le nuove regole?" : "Apply the new rules?"
    }
    public static var applyRulesConfirmMessage: String {
        isItalian
            ? "La partita in corso verrà salvata nello storico e azzerata."
            : "The match in progress will be saved to history and reset."
    }
    public static var pendingRulesFooter: String {
        isItalian
            ? "Punti e set si applicano a una nuova partita: tocca Applica per confermare."
            : "Points and sets apply to a new match — tap Apply to confirm."
    }
    public static var durationLabel: String { isItalian ? "Durata" : "Duration" }

    // Match detail / set breakdown
    public static var matchDetailTitle: String { isItalian ? "Dettaglio Partita" : "Match Detail" }
    public static var setLabelSingular: String { isItalian ? "Set" : "Set" }
    public static var ralliesLabel: String { isItalian ? "scambi" : "rallies" }
    public static var longestRunLabel: String { isItalian ? "Serie max:" : "Best run:" }
    public static var noRallyData: String {
        isItalian ? "Nessun dato sugli scambi per questo set." : "No rally data for this set."
    }
    public static var noSetBreakdown: String {
        isItalian
            ? "Questa partita è stata registrata prima del tracciamento set per set."
            : "This match was recorded before set-by-set tracking existed."
    }
    /// Describes a *set* that never finished — kept separate from `interruptedMatch`, whose
    /// Italian form ("Interrotta") agrees with the feminine "partita" and reads wrong on "il set".
    public static var unfinishedSet: String { isItalian ? "Non concluso" : "Unfinished" }
    public static var styleHeader: String { isItalian ? "Stile & Temi" : "Style & Themes" }
    public static var graphicTheme: String { isItalian ? "Tema Grafico" : "Graphic Theme" }
    public static var themePreview: String { isItalian ? "Anteprima Tema:" : "Theme Preview:" }
    public static var appInfoHeader: String { isItalian ? "Supporto e Privacy" : "Support and Privacy" }
    public static var supportLink: String { isItalian ? "Supporto" : "Support" }
    public static var privacyPolicy: String { isItalian ? "Privacy Policy" : "Privacy Policy" }
    public static var resetMatch: String { isItalian ? "Resetta Partita" : "Reset Match" }
    public static var settingsTitle: String { isItalian ? "Impostazioni" : "Settings" }
    public static var closeButton: String { isItalian ? "Chiudi" : "Close" }
    public static var matchHistoryTitle: String { isItalian ? "Risultati" : "Results" }
    public static var savedResultsHeader: String { isItalian ? "Storico partite" : "Match History" }
    public static var totalMatches: String { isItalian ? "Totali" : "Total" }
    public static var completedMatches: String { isItalian ? "Completate" : "Completed" }
    public static var interruptedMatches: String { isItalian ? "Interrotte" : "Interrupted" }
    public static var copyResults: String { isItalian ? "Copia" : "Copy" }
    public static var copiedResults: String { isItalian ? "Copiato" : "Copied" }
    public static var deleteRecords: String { isItalian ? "Elimina record" : "Delete" }
    public static var deleteRecord: String { isItalian ? "Elimina" : "Delete" }
    public static var deleteAll: String { isItalian ? "Elimina tutto" : "Delete All" }
    public static var deleteRecordsConfirmTitle: String { isItalian ? "Eliminare tutti i record?" : "Delete all records?" }
    public static var deleteRecordsConfirmMessage: String { isItalian ? "Questa azione rimuove definitivamente lo storico salvato sul dispositivo." : "This permanently removes the history saved on this device." }
    public static var noSavedResults: String { isItalian ? "Nessun risultato salvato" : "No saved results" }
    public static var setsLabel: String { isItalian ? "Set" : "Sets" }
    public static var pointsLabel: String { isItalian ? "Punti" : "Points" }
    public static var winnerLabel: String { isItalian ? "Vince" : "Winner" }
    public static var interruptedMatch: String { isItalian ? "Interrotta" : "Interrupted" }
    public static var deuceOn: String { isItalian ? "Vantaggi" : "Deuce" }
    public static var deuceOff: String { isItalian ? "Secco" : "No Deuce" }
    
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

    public static func speechUndo(p1Score: Int, p2Score: Int, server: String) -> String {
        if isItalian {
            return "Annullato. Punteggio: \(p1Score) a \(p2Score). Batte \(server)."
        } else {
            return "Undone. Score: \(p1Score) to \(p2Score). Service \(server)."
        }
    }

    public static func speechReset(server: String) -> String {
        if isItalian {
            return "Incontro azzerato. Nuova partita! Batte \(server)."
        } else {
            return "Match reset. New game! Service \(server)."
        }
    }

    public static func speechSideSwap(leftName: String, rightName: String) -> String {
        if isItalian {
            return "Cambio campo! Adesso \(leftName) a sinistra e \(rightName) a destra."
        } else {
            return "Change ends! Now \(leftName) on the left and \(rightName) on the right."
        }
    }

    public static func speechSetEnd(setWinner: String, server: String) -> String {
        if isItalian {
            return "Fine set! Set per \(setWinner). Inizio del set successivo. Batte \(server)."
        } else {
            return "End of set! Set to \(setWinner). Next set starting. Service \(server)."
        }
    }

    // Match History Export Column Headers
    public static var exportHeaders: [String] {
        if isItalian {
            return ["Data", "Giocatore 1", "Giocatore 2", "Set", "Punti", "Parziali", "Vincitore", "Stato", "Durata", "Regole"]
        } else {
            return ["Date", "Player 1", "Player 2", "Sets", "Points", "Set Scores", "Winner", "Status", "Duration", "Rules"]
        }
    }

    public static var completedMatch: String { isItalian ? "Completata" : "Completed" }
    public static func exportRulesSummary(targetScore: Int, bestOfSets: Int, winByTwo: Bool) -> String {
        let setsLabel = isItalian ? "set" : "sets"
        return "\(targetScore) pt, \(bestOfSets) \(setsLabel), \(winByTwo ? deuceOn : deuceOff)"
    }
}
