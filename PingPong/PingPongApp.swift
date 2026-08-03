import SwiftUI

@main
struct PingPongApp: App {
    init() {
        // Build the view model at launch rather than waiting for the scoreboard to appear.
        //
        // A Live Activity button performs its intent in this process, and the system may launch
        // the app in the background to do it — without ever constructing the UI. Since the view
        // model registers itself as the intent's handler in its own init, leaving it to be created
        // lazily by the first view would make those buttons silent no-ops exactly when the app is
        // not already on screen, which is the case they exist for.
        _ = ScoreViewModel.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
