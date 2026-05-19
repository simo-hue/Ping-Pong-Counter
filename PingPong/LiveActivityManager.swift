import Foundation
import ActivityKit

@MainActor
public final class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<PingPongAttributes>? = nil
    
    private init() {}
    
    public func updateOrCreateActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil) {
        // If the match is fully reset back to initial state, automatically dismiss the Live Activity
        if p1Score == 0 && p2Score == 0 && p1Sets == 0 && p2Sets == 0 && winner == nil {
            endLiveActivity()
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
                currentServer: currentServer
            )
        } else {
            updateLiveActivity(
                p1Score: p1Score,
                p2Score: p2Score,
                p1Sets: p1Sets,
                p2Sets: p2Sets,
                currentServer: currentServer,
                winner: winner
            )
        }
    }
    
    public func startLiveActivity(p1Name: String, p2Name: String, p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String) {
        // First, ensure any old active session is fully cleaned up
        endLiveActivity()
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not authorized/enabled by the user.")
            return
        }
        
        let attributes = PingPongAttributes(p1Name: p1Name, p2Name: p2Name)
        let initialContentState = PingPongAttributes.ContentState(
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer,
            winner: nil
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
    
    public func updateLiveActivity(p1Score: Int, p2Score: Int, p1Sets: Int, p2Sets: Int, currentServer: String, winner: String? = nil) {
        guard let activity = currentActivity else { return }
        
        let updatedState = PingPongAttributes.ContentState(
            p1Score: p1Score,
            p2Score: p2Score,
            p1Sets: p1Sets,
            p2Sets: p2Sets,
            currentServer: currentServer,
            winner: winner
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
