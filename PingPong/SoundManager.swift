import AudioToolbox

enum SoundEffect {
    case point
    case undo
    case serveChange
    case setWon
    case matchWon

    /// System sound identifiers from the shared iOS UI sound bank. Using the system bank rather
    /// than bundled audio files keeps the app free of media assets, avoids any interaction with
    /// the `AVAudioSession` that `SpeechManager` owns for the voice umpire, and lets the physical
    /// silent switch mute the effects — which is the behaviour a player expects from a scoreboard
    /// blip, unlike the spoken score.
    var systemSoundID: SystemSoundID {
        switch self {
        case .point: return 1104        // Tock
        case .undo: return 1105         // Tock, lower
        case .serveChange: return 1103  // Tink
        case .setWon: return 1016       // Sent
        case .matchWon: return 1025     // Fanfare
        }
    }
}

final class SoundManager {
    static let shared = SoundManager()

    var isSoundEnabled = false

    private init() {}

    func play(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
