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
            print("Failed to set up AVAudioSession: \\(error)")
        }
    }
    
    private func configureVoice() {
        // Look for Italian voice since requested in Italian, fallback to system default
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let italianVoice = voices.first(where: { $0.language.contains("it-IT") }) {
            self.voice = italianVoice
        } else {
            self.voice = AVSpeechSynthesisVoice(language: "it-IT") ?? AVSpeechSynthesisVoice(language: "en-US")
        }
    }
    
    func speak(_ text: String, immediate: Bool = true) {
        guard isVoiceEnabled else { return }
        
        if immediate && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.52 // Natural Italian speaking rate
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
        if let winner = winnerName {
            speak("Partita conclusa! Vince \(winner)!", immediate: true)
            return
        }
        
        if isMatchPoint {
            if p1Score > p2Score {
                speak("Match Point per \(p1Name)! Punteggio: \(p1Score) a \(p2Score). Batte \(serverName).", immediate: true)
            } else {
                speak("Match Point per \(p2Name)! Punteggio: \(p2Score) a \(p1Score). Batte \(serverName).", immediate: true)
            }
            return
        }
        
        if isSetPoint {
            if p1Score > p2Score {
                speak("Set Point per \(p1Name)! Punteggio: \(p1Score) a \(p2Score). Batte \(serverName).", immediate: true)
            } else {
                speak("Set Point per \(p2Name)! Punteggio: \(p2Score) a \(p1Score). Batte \(serverName).", immediate: true)
            }
            return
        }
        
        if isDeuce {
            speak("Parità! Vantaggi! \(p1Score) pari. Batte \(serverName).", immediate: true)
            return
        }
        
        if p1Score == p2Score {
            speak("Parità. \(p1Score) pari. Batte \(serverName).", immediate: true)
        } else {
            speak("\(p1Score) a \(p2Score). Batte \(serverName).", immediate: true)
        }
    }
}
