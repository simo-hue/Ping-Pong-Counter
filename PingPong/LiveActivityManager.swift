import Foundation
import ActivityKit

@MainActor
public final class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<PingPongAttributes>? = nil
    
    private init() {
        // Automatically reconnect to any ongoing Live Activity session on app launch
        reconnectToExistingActivity()
    }
    
    public func reconnectToExistingActivity() {
        if let existing = Activity<PingPongAttributes>.activities.first {
            self.currentActivity = existing
            print("Successfully reconnected to ongoing Live Activity: \(existing.id)")
        }
    }
    
    public func updateOrCreateActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int) {
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
    
    public func startLiveActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, themeIndex: Int) {
        // First, ensure any old active session is fully cleaned up
        endLiveActivity()
        
        // On simulator, areActivitiesEnabled can fail due to sandbox cache issues, bypass it
        #if !targetEnvironment(simulator)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not authorized/enabled by the user.")
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
            print("Live Activity started successfully: \(currentActivity?.id ?? "")")
        } catch {
            print("Failed to request Live Activity: \(error.localizedDescription)")
        }
    }
    
    public func updateLiveActivity(p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil, themeIndex: Int) {
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
            print("Live Activity updated in background: P1 \(p1Score) - P2 \(p2Score)")
        }
    }
    
    public func endLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
            print("Live Activity terminated successfully.")
        }
    }
}

