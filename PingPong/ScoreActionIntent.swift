import AppIntents
import Foundation

/// A scoring action a Live Activity button can request.
enum ScoreAction: String, AppEnum {
    case pointPlayer1
    case pointPlayer2
    case undo
    case newMatch

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Score Action" }

    static var caseDisplayRepresentations: [ScoreAction: DisplayRepresentation] {
        [
            .pointPlayer1: "Point for player one",
            .pointPlayer2: "Point for player two",
            .undo: "Undo last point",
            .newMatch: "Start a new match"
        ]
    }
}

/// Receives actions requested from outside the scoreboard UI.
@MainActor
protocol ScoreActionHandling: AnyObject {
    func handle(_ action: ScoreAction)
}

/// Indirection between the intent and the view model.
///
/// The intent type has to be visible to the widget extension so its buttons can name it, but the
/// widget must not link the view model — that would drag WatchConnectivity and the whole scoring
/// engine into the extension. So the intent talks to whatever registered itself here: the app
/// registers its view model at launch, and in the extension the handler is simply nil.
///
/// This is safe because `LiveActivityIntent` performs in the *app's* process (the system launches
/// it in the background), so by the time `perform()` runs the app side has registered.
@MainActor
enum ScoreActionRouter {
    weak static var handler: ScoreActionHandling?

    /// Supplies a spoken score summary for the Siri intent. A closure rather than another protocol
    /// member so the widget target, which also compiles this file, needs to know nothing about it.
    static var spokenSummary: (() -> String)?

    static func perform(_ action: ScoreAction) {
        handler?.handle(action)
    }
}

#if os(iOS)
/// Scores a point — or takes one back — straight from the Lock Screen or Dynamic Island.
@available(iOS 17.0, *)
struct ScoreActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Update Ping Pong Score" }
    static var description: IntentDescription {
        IntentDescription("Adds a point to a side, or undoes the last one, without opening the app.")
    }

    /// Live Activity buttons should not pull the app to the foreground mid-rally.
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Action")
    var action: ScoreAction

    init() {}

    init(action: ScoreAction) {
        self.action = action
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        ScoreActionRouter.perform(action)
        return .result()
    }
}
#endif

#if os(iOS)
/// Reads the current score aloud without opening the app.
@available(iOS 17.0, *)
struct ReadScoreIntent: AppIntent {
    static var title: LocalizedStringResource { "Read Ping Pong Score" }
    static var description: IntentDescription {
        IntentDescription("Says the current score and who is serving.")
    }

    static var openAppWhenRun: Bool { false }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let summary = ScoreActionRouter.spokenSummary?() ?? ""
        return .result(dialog: IntentDialog(stringLiteral: summary))
    }
}

/// Starts a fresh match.
@available(iOS 17.0, *)
struct NewMatchIntent: AppIntent {
    static var title: LocalizedStringResource { "New Ping Pong Match" }
    static var description: IntentDescription {
        IntentDescription("Resets the scoreboard and starts a new match.")
    }

    static var openAppWhenRun: Bool { true }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        ScoreActionRouter.perform(.newMatch)
        return .result()
    }
}

/// Surfaces the intents to Siri and the Shortcuts app without the user assembling anything.
@available(iOS 17.0, *)
struct PingPongShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReadScoreIntent(),
            phrases: [
                "What's the score in \(.applicationName)",
                "Read the \(.applicationName) score"
            ],
            shortTitle: "Read Score",
            systemImageName: "speaker.wave.2.fill"
        )

        AppShortcut(
            intent: NewMatchIntent(),
            phrases: [
                "Start a new match in \(.applicationName)",
                "New \(.applicationName) match"
            ],
            shortTitle: "New Match",
            systemImageName: "arrow.counterclockwise"
        )
    }
}
#endif
