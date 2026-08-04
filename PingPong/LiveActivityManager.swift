import Foundation
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<PingPongAttributes>? = nil
    
    private init() {
        // Automatically reconnect to any ongoing Live Activity session on app launch
        reconnectToExistingActivity()
    }
    
    func reconnectToExistingActivity() {
        if let existing = Activity<PingPongAttributes>.activities.first {
            self.currentActivity = existing
            debugLog("Successfully reconnected to ongoing Live Activity: \(existing.id)")
        }
    }
    
    func updateOrCreateActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int, servingName: String? = nil) {
        if currentActivity == nil {
            reconnectToExistingActivity()
        }
        
        // ActivityAttributes are frozen when the activity is requested and can never be updated —
        // only ContentState can. So a change of ends or a rename can only be reflected by starting
        // a new activity. Without this the Lock Screen keeps the old names against the new scores,
        // and the "+ <name>" buttons are captioned for one player while scoring for the other.
        if let activity = currentActivity,
           activity.attributes.p1Name != p1Name || activity.attributes.p2Name != p2Name {
            startLiveActivity(
                p1Name: p1Name,
                p2Name: p2Name,
                p1Score: p1Score,
                p2Score: p2Score,
                p1Sets: p1Sets,
                p2Sets: p2Sets,
                currentServer: currentServer,
                winner: winner,
                themeIndex: themeIndex,
                servingName: servingName
            )
            return
        }

        if currentActivity == nil {
            startLiveActivity(
                p1Name: p1Name,
                p2Name: p2Name,
                p1Score: p1Score,
                p2Score: p2Score,
                p1Sets: p1Sets,
                p2Sets: p2Sets,
                currentServer: currentServer,
                winner: winner,
                themeIndex: themeIndex,
                servingName: servingName
            )
        } else {
            updateLiveActivity(
                p1Score: p1Score,
                p2Score: p2Score,
                p1Sets: p1Sets,
                p2Sets: p2Sets,
                currentServer: currentServer,
                winner: winner,
                themeIndex: themeIndex,
                servingName: servingName
            )
        }
    }
    
    func startLiveActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int, servingName: String? = nil) {
        // Kept, but NOT ended yet: Activity.request can fail (it needs the foreground), and tearing
        // the old one down first would leave the user with no Live Activity at all.
        let previousActivity = currentActivity
        
        // On simulator, areActivitiesEnabled can fail due to sandbox cache issues, bypass it
        #if !targetEnvironment(simulator)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            debugLog("Live Activities are not authorized/enabled by the user.")
            return
        }
        #endif
        
        let attributes = PingPongAttributes(p1Name: p1Name, p2Name: p2Name)
        let initialContentState = PingPongAttributes.ContentState(
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer,
            winner: winner,
            themeIndex: themeIndex,
            servingName: servingName
        )

        do {
            let activityContent = ActivityContent(state: initialContentState, staleDate: nil)
            currentActivity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            debugLog("Live Activity started successfully: \(currentActivity?.id ?? "")")

            // Only now that the replacement exists is it safe to dismiss the old one.
            if let previousActivity {
                Task {
                    await previousActivity.end(nil, dismissalPolicy: .immediate)
                    self.debugLog("Previous Live Activity terminated successfully.")
                }
            }
        } catch {
            debugLog("Failed to request Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateLiveActivity(p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int, servingName: String? = nil) {
        guard let activity = currentActivity else { return }
        
        let updatedState = PingPongAttributes.ContentState(
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer,
            winner: winner,
            themeIndex: themeIndex,
            servingName: servingName
        )
        
        Task {
            let activityContent = ActivityContent(state: updatedState, staleDate: nil)
            await activity.update(activityContent)
            self.debugLog("Live Activity updated in background: P1 \(p1Score) - P2 \(p2Score)")
        }
    }
    
    func endLiveActivity() {
        guard let activity = currentActivity else { return }
        currentActivity = nil
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.debugLog("Live Activity terminated successfully.")
        }
    }

    private func debugLog(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}
