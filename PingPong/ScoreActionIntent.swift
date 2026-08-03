import AppIntents
import Foundation

/// A scoring action a Live Activity button can request.
enum ScoreAction: String, AppEnum {
    case pointPlayer1
    case pointPlayer2
    case undo

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Score Action" }

    static var caseDisplayRepresentations: [ScoreAction: DisplayRepresentation] {
        [
            .pointPlayer1: "Point for player one",
            .pointPlayer2: "Point for player two",
            .undo: "Undo last point"
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
