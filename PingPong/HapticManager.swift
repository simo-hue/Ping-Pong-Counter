import UIKit

enum HapticPattern {
    case scoreIncrement
    case scoreDecrement
    case serveChange
    case matchPoint
    case gameWon
    case reset
}

/// How forcefully the Taptic Engine responds. `.light` keeps the confirmation cues but softens
/// them for players who find full-strength feedback distracting during a rally.
enum HapticIntensity: String, CaseIterable, Codable {
    case off
    case light
    case full
}

final class HapticManager {
    static let shared = HapticManager()

    var intensity: HapticIntensity = .full

    private init() {}

    func play(_ pattern: HapticPattern) {
        let intensity = self.intensity
        guard intensity != .off else { return }

        DispatchQueue.main.async {
            switch pattern {
            case .scoreIncrement:
                Self.impact(intensity == .light ? .light : .medium)

            case .scoreDecrement:
                Self.impact(.light)

            case .serveChange:
                Self.impact(intensity == .light ? .soft : .rigid)

            case .matchPoint:
                if intensity == .light {
                    Self.impact(.light)
                } else {
                    Self.notification(.warning)
                }

            case .gameWon:
                if intensity == .light {
                    Self.impact(.medium)
                } else {
                    Self.notification(.success)
                }

            case .reset:
                Self.impact(intensity == .light ? .light : .heavy)
            }
        }
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
