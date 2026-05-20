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
    
    func updateOrCreateActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int) {
        if currentActivity == nil {
            reconnectToExistingActivity()
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
                themeIndex: themeIndex
            )
        } else {
            updateLiveActivity(
                p1Score: p1Score,
                p2Score: p2Score,
                p1Sets: p1Sets,
                p2Sets: p2Sets,
                currentServer: currentServer,
                winner: winner,
                themeIndex: themeIndex
            )
        }
    }
    
    func startLiveActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, themeIndex: Int) {
        // Clear any old session without letting its async dismissal erase the new activity reference.
        let previousActivity = currentActivity
        currentActivity = nil
        if let previousActivity {
            Task {
                await previousActivity.end(nil, dismissalPolicy: .immediate)
                self.debugLog("Previous Live Activity terminated successfully.")
            }
        }
        
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
            winner: nil,
            themeIndex: themeIndex
        )
        
        do {
            let activityContent = ActivityContent(state: initialContentState, staleDate: nil)
            currentActivity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            debugLog("Live Activity started successfully: \(currentActivity?.id ?? "")")
        } catch {
            debugLog("Failed to request Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateLiveActivity(p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int) {
        guard let activity = currentActivity else { return }
        
        let updatedState = PingPongAttributes.ContentState(
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer,
            winner: winner,
            themeIndex: themeIndex
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
