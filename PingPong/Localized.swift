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

    // Roster & player statistics
    public static var rosterTitle: String { isItalian ? "Giocatori" : "Players" }
    public static var choosePlayerTitle: String { isItalian ? "Scegli Giocatore" : "Choose Player" }
    public static var savedPlayersHeader: String { isItalian ? "Giocatori Salvati" : "Saved Players" }
    public static var rosterLink: String { isItalian ? "Giocatori Salvati e Statistiche" : "Saved Players & Stats" }
    public static var addPlayer: String { isItalian ? "Aggiungi Giocatore" : "Add Player" }
    public static var editPlayer: String { isItalian ? "Modifica Giocatore" : "Edit Player" }
    public static var newPlayerPlaceholder: String { isItalian ? "Nome giocatore" : "Player name" }
    public static var avatarHeader: String { isItalian ? "Avatar" : "Avatar" }
    public static var noSavedPlayers: String {
        isItalian
            ? "Nessun giocatore salvato. Aggiungine uno per tenere statistiche e scontri diretti."
            : "No saved players yet. Add one to track stats and head-to-head records."
    }
    public static var rosterFooter: String {
        isItalian
            ? "I giocatori salvati mantengono statistiche fra le partite."
            : "Saved players keep their statistics across matches."
    }
    public static var duplicatePlayerWarning: String {
        isItalian ? "Esiste già un giocatore con questo nome." : "A player with that name already exists."
    }
    public static var chooseFromRoster: String { isItalian ? "Scegli dai salvati" : "Choose from saved" }

    public static func playedWonSummary(played: Int, won: Int) -> String {
        guard isItalian else { return "\(played) played · \(won) won" }
        return "\(played) \(played == 1 ? "giocata" : "giocate") · \(won) \(won == 1 ? "vinta" : "vinte")"
    }
    public static var winRateLabel: String { isItalian ? "Vittorie" : "Win rate" }
    public static var matchesPlayedLabel: String { isItalian ? "Partite giocate" : "Matches played" }
    public static var matchesWonLabel: String { isItalian ? "Partite vinte" : "Matches won" }
    public static var setsWonLostLabel: String { isItalian ? "Set vinti-persi" : "Sets won-lost" }
    public static var pointsWonLostLabel: String { isItalian ? "Punti fatti-subiti" : "Points for-against" }
    public static var currentStreakLabel: String { isItalian ? "Serie attuale" : "Current streak" }
    public static var bestStreakLabel: String { isItalian ? "Miglior serie" : "Best streak" }
    public static func winStreak(_ count: Int) -> String {
        guard isItalian else { return "\(count) \(count == 1 ? "win" : "wins") in a row" }
        return "\(count) \(count == 1 ? "vittoria" : "vittorie") di fila"
    }
    public static func lossStreak(_ count: Int) -> String {
        guard isItalian else { return "\(count) \(count == 1 ? "loss" : "losses") in a row" }
        return "\(count) \(count == 1 ? "sconfitta" : "sconfitte") di fila"
    }
    public static var headToHeadHeader: String { isItalian ? "SCONTRI DIRETTI" : "HEAD-TO-HEAD" }
    public static var noHeadToHead: String {
        isItalian
            ? "Nessuno scontro diretto: entrambi i giocatori devono essere salvati nei giocatori."
            : "No head-to-head yet — both players must be saved in the roster."
    }
    // Doubles
    public static var doublesMode: String { isItalian ? "Doppio" : "Doubles" }
    public static var singlesMode: String { isItalian ? "Singolo" : "Singles" }
    public static var matchFormatHeader: String { isItalian ? "Formato Partita" : "Match Format" }
    public static var doublesFooter: String {
        isItalian
            ? "Nel doppio il servizio ruota fra i quattro giocatori: chi riceve serve nel turno successivo."
            : "In doubles the serve rotates through all four players: whoever receives serves next."
    }
    public static var teamOneLabel: String { isItalian ? "Squadra 1" : "Team 1" }
    public static var teamTwoLabel: String { isItalian ? "Squadra 2" : "Team 2" }
    public static var servingLabel: String { isItalian ? "SERVE" : "SERVING" }
    public static var receivingLabel: String { isItalian ? "RICEVE" : "RECEIVING" }
    public static var swapPartnersLabel: String { isItalian ? "Inverti compagni" : "Swap partners" }
    public static var openingRotationHeader: String { isItalian ? "Rotazione Iniziale" : "Opening Rotation" }
    public static var firstServerLabel: String { isItalian ? "Serve per primo" : "Serves first" }
    public static var firstReceiverLabel: String { isItalian ? "Riceve per primo" : "Receives first" }
    public static func defaultDoublesName(team: Int, slot: Int) -> String {
        isItalian ? "Giocatore \(team)\(slot)" : "Player \(team)\(slot)"
    }
    public static func servesToDescription(server: String, receiver: String) -> String {
        isItalian ? "\(server) serve a \(receiver)" : "\(server) serves to \(receiver)"
    }

    // iCloud & export
    public static var cloudSyncHeader: String { isItalian ? "iCloud" : "iCloud" }
    public static var cloudSyncLabel: String { isItalian ? "Sincronizza Storico" : "Sync History" }
    public static var cloudSyncFooter: String {
        isItalian
            ? "Storico e giocatori salvati vengono condivisi fra i tuoi dispositivi. Il punteggio della partita in corso resta sul dispositivo."
            : "History and saved players are shared across your devices. The match in progress stays on this device."
    }
    public static var cloudSyncUnavailable: String {
        isItalian ? "iCloud non disponibile su questo dispositivo" : "iCloud is not available on this device"
    }
    public static var exportLabel: String { isItalian ? "Esporta" : "Export" }
    public static func exportFormatLabel(_ name: String) -> String {
        isItalian ? "Esporta \(name)" : "Export \(name)"
    }

    // Accessibility
    public static func pointsAccessibility(_ count: Int) -> String {
        guard isItalian else { return "\(count) \(count == 1 ? "point" : "points")" }
        return "\(count) \(count == 1 ? "punto" : "punti")"
    }
    public static func setsAccessibility(_ count: Int) -> String {
        guard isItalian else { return "\(count) \(count == 1 ? "set won" : "sets won")" }
        return "\(count) \(count == 1 ? "set vinto" : "set vinti")"
    }
    public static var addPointAction: String { isItalian ? "Aggiungi un punto" : "Add a point" }
    public static var removePointAction: String { isItalian ? "Togli un punto" : "Remove a point" }
    public static var setServeAction: String { isItalian ? "Assegna il servizio" : "Give the serve" }
    public static var editNameAction: String { isItalian ? "Modifica il nome" : "Edit the name" }
    public static var undoAction: String { isItalian ? "Annulla l'ultimo punto" : "Undo the last point" }
    public static var swapSidesAction: String { isItalian ? "Cambia campo" : "Change ends" }
    public static var setPointLabel: String { isItalian ? "Set point" : "Set point" }
    public static var matchPointLabel: String { isItalian ? "Match point" : "Match point" }

    // Statistics dashboard
    public static var statsTitle: String { isItalian ? "Statistiche" : "Statistics" }
    public static var totalRalliesLabel: String { isItalian ? "Scambi totali" : "Total rallies" }
    public static var averageDurationLabel: String { isItalian ? "Durata media" : "Average duration" }
    public static var activityChartTitle: String { isItalian ? "Attività" : "Activity" }
    public static func activityChartSubtitle(days: Int) -> String {
        isItalian ? "Partite giocate negli ultimi \(days) giorni" : "Matches played over the last \(days) days"
    }
    public static var dayAxisLabel: String { isItalian ? "Giorno" : "Day" }
    public static var matchesAxisLabel: String { isItalian ? "Partite" : "Matches" }
    public static var leaderboardTitle: String { isItalian ? "Classifica" : "Leaderboard" }
    public static var leaderboardSubtitle: String {
        isItalian ? "Percentuale di vittorie sulle partite concluse" : "Win rate across decided matches"
    }
    public static var pointsChartTitle: String { isItalian ? "Punti Fatti e Subiti" : "Points For and Against" }
    public static var pointsChartSubtitle: String {
        isItalian ? "Somma di tutti i set giocati" : "Summed across every set played"
    }
    public static var pointsForLabel: String { isItalian ? "Fatti" : "For" }
    public static var pointsAgainstLabel: String { isItalian ? "Subiti" : "Against" }
    public static var finishChartTitle: String { isItalian ? "Come Finiscono le Partite" : "How Matches Finish" }
    public static var finishChartSubtitle: String {
        isItalian ? "Punteggio finale in set, dal lato di chi vince" : "Final set score, from the winner's side"
    }
    public static var statsNeedRoster: String {
        isItalian
            ? "Salva i giocatori nella rosa per vedere classifica e punti."
            : "Save players to the roster to see the leaderboard and points."
    }

    public static var noMatchesForPlayer: String {
        isItalian ? "Nessuna partita registrata per questo giocatore." : "No matches recorded for this player yet."
    }
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
