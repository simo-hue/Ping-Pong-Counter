import AVFoundation

final class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var voice: AVSpeechSynthesisVoice?
    
    @Published var isVoiceEnabled = false
    
    private override init() {
        super.init()
        setupAudioSession()
        configureVoice()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // playback category allows voice to be heard even if phone is on silent mode
            // duckOthers duck any background music when the score is spoken
            try session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
        } catch {
            print("Failed to set up AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    private func configureVoice() {
        let isIT = Localized.isItalian
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if isIT {
            if let italianVoice = voices.first(where: { $0.language.contains("it-IT") }) {
                self.voice = italianVoice
            } else {
                self.voice = AVSpeechSynthesisVoice(language: "it-IT") ?? AVSpeechSynthesisVoice(language: "en-US")
            }
        } else {
            if let englishVoice = voices.first(where: { $0.language.contains("en-US") }) {
                self.voice = englishVoice
            } else {
                self.voice = AVSpeechSynthesisVoice(language: "en-US")
            }
        }
    }
    
    func speak(_ text: String, immediate: Bool = true) {
        guard isVoiceEnabled else { return }
        
        if immediate && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = Localized.isItalian ? 0.52 : 0.50 // Adjusted speaking rates
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Activate session dynamically before speaking
        try? AVAudioSession.sharedInstance().setActive(true)
        synthesizer.speak(utterance)
    }
    
    func announceScore(
        p1Name: String,
        p1Score: Int,
        p2Name: String,
        p2Score: Int,
        serverName: String,
        isMatchPoint: Bool,
        isSetPoint: Bool,
        isDeuce: Bool,
        winnerName: String?
    ) {
        // Re-configure voice language on each announcement in case system locale changed
        configureVoice()

        if let winner = winnerName {
            speak(Localized.speechWinner(name: winner), immediate: true)
            return
        }
        
        if isMatchPoint {
            if p1Score > p2Score {
                speak(Localized.speechMatchPoint(for: p1Name, p1Score: p1Score, p2Score: p2Score, server: serverName), immediate: true)
            } else {
                speak(Localized.speechMatchPoint(for: p2Name, p1Score: p2Score, p2Score: p1Score, server: serverName), immediate: true)
            }
            return
        }
        
        if isSetPoint {
            if p1Score > p2Score {
                speak(Localized.speechSetPoint(for: p1Name, p1Score: p1Score, p2Score: p2Score, server: serverName), immediate: true)
            } else {
                speak(Localized.speechSetPoint(for: p2Name, p1Score: p2Score, p2Score: p1Score, server: serverName), immediate: true)
            }
            return
        }
        
        if isDeuce {
            speak(Localized.speechDeuce(score: p1Score, server: serverName), immediate: true)
            return
        }
        
        if p1Score == p2Score {
            speak(Localized.speechAll(score: p1Score, server: serverName), immediate: true)
        } else {
            speak(Localized.speechStandard(p1Score: p1Score, p2Score: p2Score, server: serverName), immediate: true)
        }
    }
}
