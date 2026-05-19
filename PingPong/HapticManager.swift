import UIKit

enum HapticPattern {
    case scoreIncrement
    case scoreDecrement
    case serveChange
    case matchPoint
    case gameWon
    case reset
}

final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func play(_ pattern: HapticPattern) {
        DispatchQueue.main.async {
            switch pattern {
            case .scoreIncrement:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
                
            case .scoreDecrement:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                
            case .serveChange:
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.prepare()
                generator.impactOccurred()
                
            case .matchPoint:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.warning)
                
            case .gameWon:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
                
            case .reset:
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.prepare()
                generator.impactOccurred()
            }
        }
    }
}
