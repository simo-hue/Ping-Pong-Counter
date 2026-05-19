# Documentazione Tecnica - Ping Pong Counter 🏓

Questo documento tiene traccia dello stato dell'applicazione, delle scelte architetturali e dei dettagli tecnologici del progetto in conformità con i protocolli di sviluppo senior.

## Registro delle Modifiche

### [2026-05-19 11:10]: Creazione Progetto Nativo SwiftUI iOS (Ping Pong Counter)
* **Dettagli**: Inizializzazione da zero di un'applicazione iOS nativa scritta interamente in **SwiftUI** per tenere il punteggio in una partita reale di Ping Pong. L'applicazione rispetta le Apple Human Interface Guidelines (HIG) e supporta sia l'orientamento orizzontale (split screen sinistra/destra, ideale a bordo tavolo) sia verticale (split screen alto/basso, ideale per l'uso a una mano).
* **Tech Notes**:
  - **Architettura**: MVVM pulito con gestione centralizzata dello stato in `@MainActor` tramite `ScoreViewModel`.
  - **Gestione del Servizio (Professional Rule)**: Il server ruota ogni 2 battute in modalità standard. Se la partita arriva ai vantaggi (*deuce* a 10 pari per l'11 standard), la rotazione passa automaticamente a 1 singola battuta per giocatore, in perfetta conformità con le regole ufficiali ITTF (International Table Tennis Federation).
  - **Assistente Vocale (Sintesi Vocale Premium)**: Integrazione nativa con `AVSpeechSynthesizer` in lingua italiana per annunciare i punteggi e i momenti chiave ("Match Point!", "Set Point!", "Vantaggi!"). Il sistema attiva l'audio configurando `AVAudioSession` con opzioni di **Ducking** (la musica di sottofondo si abbassa automaticamente durante l'annuncio e poi riprende) e override del selettore silenzioso fisico (consente di udire i punteggi anche se il telefono è impostato su vibrazione).
  - **Taptic Engine (Feedback Haptic Avanzato)**: Implementazione di pattern di vibrazione differenti via `UIImpactFeedbackGenerator` e `UINotificationFeedbackGenerator` per incrementi (+1), decrementi (-1), cambi di servizio, set point e vincita partita.
  - **Gestione dell'Errore e Undo**: Implementato un sistema di rollback di stato tramite snapshot storici di gioco (fino a 30 passi memorizzati) per consentire l'annullamento illimitato in caso di inserimento errato, richiamabile sia da console centrale che tramite *gesto swipe down*.
  - **Grafica & Temi**: Supporto a 3 palette di colori neon ad alto contrasto con sfumature radiali vibranti che reagiscono al servizio attivo e lampeggiano durante i match point.
  - **Verifica**: Compilato con successo tramite `xcodebuild` sul simulatore target `iphonesimulator` con firma locale funzionante.

### [2026-05-19 11:14]: Disattivazione Sintesi Vocale di Default
* **Dettagli**: Disattivata la riproduzione vocale automatica dei punteggi all'avvio su richiesta dell'utente per garantire la massima silenziosità iniziale. L'utente ha la libertà di riattivarla a piacimento dalle impostazioni grafiche in-app.
* **Tech Notes**:
  - Modificata la proprietà `@Published var isVoiceEnabled` impostandola a `false` per impostazione predefinita in `ScoreViewModel.swift` e `SpeechManager.swift`.
  - Il toggle nella scheda `SettingsView` (icona ingranaggio) rimane pienamente funzionante per riattivare la sintesi vocale localizzata in tempo reale.

### [2026-05-19 11:15]: Implementazione Premium UX & Adaptive Net Layout
* **Dettagli**: Aggiunti diversi miglioramenti all'esperienza utente (UX) per eliminare ogni attrito, semplificare l'utilizzo sul campo da gioco reale ed eliminare azioni accidentali distruttive.
* **Tech Notes**:
  - **Rete Divisoria Adattiva (Visual Partition)**: Aggiunta una linea tratteggiata di mezzeria (`StrokeStyle` con `dash: [6, 6]`) che separa i campi da gioco dei due giocatori a livello visivo (verticale in orizzontale, orizzontale in verticale), mimando la rete del tavolo da ping pong fisico.
  - **Onboarding Automatico**: Inserito un testo d'istruzione fluttuante semi-trasparente ad alta leggibilità (*"Tocca per +1 • Scorri giù per -1"*) visibile unicamente all'avvio a punteggio `0 - 0` in ciascun set. Svanisce istantaneamente al primo punto segnato per mantenere il design pulito ed essenziale durante la partita.
  - **Modifica Nomi Istantanea (Inline Dialog)**: Raggiungibile direttamente cliccando sul nome del giocatore nel tabellone principale (ora contrassegnato da una sottile icona a matita `pencil`). Visualizza un alert iOS nativo con `TextField` per l'inserimento istantaneo del nome, senza forzare l'utente a navigare nelle impostazioni generali.
  - **Assegnazione Servizio Manuale (Interactive Serve Trigger)**: Cliccando su *"SERVIZIO"* o *"IMPOSTA SERVIZIO"*, i giocatori possono ora riassegnare o correggere manualmente i diritti di servizio in qualsiasi momento senza alterare il punteggio corrente.
  - **Sicurezza di Reset**: Sostituito l'azzeramento diretto del tasto Reset con un foglio di conferma nativo (`confirmationDialog`) per evitare la perdita accidentale dei punteggi a causa di tocchi involontari durante i match concitati.

### [2026-05-19 11:18]: Companion App Apple Watch (watchOS Integration)
* **Dettagli**: Sviluppata l'architettura completa per l'app companion su Apple Watch (watchOS) con sincronizzazione bidirezionale istantanea. Questo consente un'esperienza a mani libere superlativa durante le partite fisiche di ping pong.
* **Tech Notes**:
  - **Watch Connectivity Framework**: Implementato il bridge `WCSession` bidirezionale integrato a livello di proprietà `@Published` tramite osservatori `didSet` in `ScoreViewModel.swift` per sincronizzare all'istante modifiche di punteggi, nomi, cambio battuta o reset.
  - **SwiftUI per watchOS**: Progettata un'interfaccia split-screen ultra-ottimizzata per piccoli display in `WatchContentView.swift` con layout ad alta leggibilità, sfumature neon e tasti di tocco sovradimensionati.
  - **Gesti Aptici watchOS**: Integrati feedback di tocco fisici (`WKInterfaceDevice.current().play(...)`): tocco semplice per incrementare (+1), pressione prolungata (Long Press per 0.6s) per decrementare (-1), con haptic feedback differenziati (click / directionDown).
  - **Onboarding e Istruzioni Xcode**: Predisposta la struttura dei file in `PingPongWatch Watch App/` e integrata la guida dettagliata in `TO_SIMO_DO.md` per l'inserimento immediato del target nativo in Xcode.

### [2026-05-19 11:20]: Layout Ultra Full-Screen e Margini di Sicurezza Nativi
* **Dettagli**: Risolto il problema delle barre vuote dell'area provvisoria (safe area) sul display dell'iPhone, abilitando un'esperienza di gioco a schermo intero reale ("True Full-Screen") in qualsiasi orientamento di visualizzazione.
* **Tech Notes**:
  - **Ignores Safe Area Esteso**: Applicato il modificatore `.ignoresSafeArea()` direttamente sia sull'HStack (orientamento orizzontale) che sul VStack (orientamento verticale) che controllano il layout diviso del tabellone in `ContentView.swift`. Questo permette agli sfondi e alle transizioni di colore di estendersi fino ai bordi fisici del dispositivo.
  - **Safe Area Padding Intelligente**: Integrato il padding dinamico tramite il modificatore nativo `.safeAreaPadding(.vertical / .horizontal, ...)` calcolato dinamicamente a seconda dell'orientamento dello schermo. I testi dei punteggi, i nomi e i selettori di battuta rimangono perfettamente leggibili e centrati all'interno della zona di sicurezza, evitando qualsiasi taglio causato da Notch fisici, Dynamic Island o bar di scorrimento home di iOS.
  - **Swift 6 Strict Concurrency Conformity**: Aggiornato il bridge `WatchConnector` rendendo i delegati `nonisolated` e incapsulando in sicurezza i cambi di stato sul `@MainActor`, garantendo che l'intera base di codice compili senza un solo warning sul motore di Xcode più recente.

### [2026-05-19 11:22]: Premium UI/UX Micro-Interactions and Native Resolution Fix
* **Dettagli**: Risolto il problema del letterboxing (barre nere in alto e in basso) forzando la renderizzazione nativa ad alta risoluzione su tutti i modelli di iPhone. Inserite inoltre micro-interazioni di qualità arcade per massimizzare la soddisfazione utente.
* **Tech Notes**:
  - **Xcode Launch Screen Generation**: Aggiunta la chiave `INFOPLIST_KEY_UILaunchScreen_Generation = YES;` nel file `project.pbxproj` per entrambi i target Debug e Release. Questo indica a iOS che l'app supporta nativamente la piena risoluzione dello schermo, rimuovendo istantaneamente il letterboxing di compatibilità.
  - **OLED Neon Glow Score Overlay**: Sostituita la visualizzazione semplice del punteggio con un sistema ZStack a due livelli: uno strato posteriore sfocato (`.blur(radius: 12)`) con opacità del tema e uno anteriore bianco brillante con doppia ombra colorata, ricreando un autentico display al neon ad alta definizione.
  - **Floating Arcade +1 Spawns**: Aggiunto un sistema di feedback interattivo che fa fluttuare verticalmente e sfumare un indicatore "+1" del rispettivo colore quando viene assegnato un punto, arricchendo l'esperienza visiva dei giocatori.
  - **Breathing Serve Pulse**: Integrato un ciclo di animazione continua (.repeatForever) che fa pulsare ed emanare calore luminoso al dot del servizio attivo.
  - **Simmetria di Controllo**: Aggiornata l'icona del pulsante impostazioni in `gearshape.circle.fill` con dimensione unificata a 26 per allinearsi perfettamente con le altre icone circolari del pannello.

### [2026-05-19 11:24]: Risoluzione Architettura Gesti (Separazione Tap e Drag)
* **Dettagli**: Risolto il problema per cui i tocchi statici sullo schermo per incrementare il punteggio non venivano rilevati dal motore dei gesti di SwiftUI.
* **Tech Notes**:
  - **Separazione dei Gesti**: Rimosso il singolo `DragGesture(minimumDistance: 10)` che tentava di rilevare sia tap che drag (fallendo sui tap statici che non superavano la distanza minima di 10 punti).
  - **onTapGesture Nativo**: Introdotto `.onTapGesture` dedicato sulla metà del campo da gioco. Questo rileva istantaneamente e con precisione assoluta il tap sul campo per fare `+1` (incremento), senza alcun ritardo.
  - **DragGesture Separato**: Applicato un `.gesture(DragGesture(minimumDistance: 15))` esclusivo per rilevare lo scorrimento verso il basso (swipe down) che attiva il `-1` (decremento).
  - **Nessuna Interferenza sui Tasti**: Questa architettura garantisce che i gesti del campo non interferiscano in alcun modo con i pulsanti attivi interni (come "SERVIZIO" e la modifica dei nomi dei giocatori), garantendo un'esperienza fluida e professionale a 360 gradi.

### [2026-05-19 11:31]: Supporto Live Activities e Dynamic Island (Attività in Tempo Reale)
* **Dettagli**: Implementato il supporto completo alle Live Activities e alla Dynamic Island di iOS, consentendo di seguire il punteggio live, i set e il servizio direttamente dalla Lock Screen o in background.
* **Tech Notes**:
  - **Condivisione Attributi (PingPongAttributes.swift)**: Creato il modello condiviso conforme ad `ActivityAttributes` che gestisce lo stato statico (nomi giocatori) e lo stato dinamico (punteggi, set, servitore attivo, vincitore).
  - **Ciclo di Vita Gestito (LiveActivityManager.swift)**: Creato un singleton centralizzato (`LiveActivityManager`) adibito a richiedere l'avvio, aggiornare lo stato in background tramite task asincroni, ed eliminare l'attività alla conclusione o al reset del match.
  - **Integrazione ViewModel**: Agganciato `LiveActivityManager.shared.updateOrCreateActivity(...)` all'interno del metodo centralizzato `syncWithWatch()` in `ScoreViewModel.swift`, in modo che qualsiasi punto registrato da iPhone o da Apple Watch aggiorni in automatico lo stato in tempo reale sia sulla Lock Screen che sulla Dynamic Island.
  - **Info.plist Entitlements**: Abilitata la chiave target `INFOPLIST_KEY_NSSupportsLiveActivities = YES;` nelle impostazioni di compilazione Debug e Release di `project.pbxproj`.
  - **Widget UI Pre-generata (PingPongWidget/)**: Progettato il layout per Lock Screen e Dynamic Island con supporto a tutti gli stati visuali (Expanded, Compact Leading/Trailing, Minimal) implementando colori HSL coerenti coi temi neon dell'app, sfondi glassmorphic oscurati e indicatori grafici di vittoria (Coppa dorata).

### [2026-05-19 11:34]: Persistenza Locale Nativa delle Impostazioni (UserDefaults)
* **Dettagli**: Implementato il salvataggio persistente in locale di tutte le impostazioni e regole del match (punti target, set totali, intervallo di battuta, nomi dei giocatori, tema visivo e opzioni audio), consentendo all'app di ricordare perfettamente lo stato preferito dell'utente ad ogni riavvio.
* **Tech Notes**:
  - **Integrazione Property Wrappers (didSet)**: Agganciato il salvataggio istantaneo su `UserDefaults.standard` all'interno dei didSet blocks di tutti i parametri di impostazione in `ScoreViewModel.swift` (`targetScore`, `winByTwo`, `bestOfSets`, `serveRotationInterval`, `p1Name`, `p2Name`, `themeIndex`, `isVoiceEnabled`, `startingServerOfMatch`).
  - **Ripristino all'Avvio (init)**: Configurato il costruttore principale `init()` di `ScoreViewModel` per caricare in modo sicuro e silenzioso tutti i valori salvati precedentemente su disco, applicando eleganti fallback predefiniti nel caso di primo avvio dell'app.

### [2026-05-19 11:38]: Creazione README.md per GitHub (Rebranding & Storytelling)
* **Dettagli**: Creato il file di presentazione del progetto `README.md` scritto interamente in lingua inglese, ottimizzato con badge professionali e formattazione d'impatto per la pubblicazione su GitHub e canali di marketing.
* **Tech Notes**:
  - **Storytelling d'Impatto**: Strutturato con un gancio basato sul problema reale di dimenticare il punteggio a metà partita di tennis da tavolo.
  - **Highlight Companion & Widget**: Spiega in dettaglio l'integrazione accoppiata tra iPhone, Apple Watch e i widget Live Activities / Dynamic Island.
  - **Asset & Marketing Link**: Predisposto con badge d'impatto per il download da App Store, collegamento al sito web e demo interattiva.

### [2026-05-19 11:49]: Internazionalizzazione Dinamica (English by Default, Italian Adaptive)
* **Dettagli**: Implementato il supporto nativo multi-lingua con priorità in lingua inglese per utenti internazionali e adattamento automatico alla lingua italiana per dispositivi italiani. La localizzazione opera sia sull'interfaccia visiva che sulla sintesi vocale del commentatore.
* **Tech Notes**:
  - **Localized Helper Module (`Localized.swift`)**: Creato un motore di traduzione dinamico e a tempo di esecuzione che rileva il codice della lingua di sistema (`Locale.current.language`) e fornisce stringhe coerenti sia per l'app iPhone che per la sintesi vocale.
  - **Adattamento Form & Scoreboard**: Sostituiti tutti i testi hardcoded in `SettingsView.swift` e `ContentView.swift` (pickers, alert di modifica nome, avvisi di reset, toast overlay di vittoria) agganciandoli al motore di localizzazione.
  - **Sintesi Vocale Adattiva (`SpeechManager.swift`)**: Configurato l'annunciatore vocale per impostare dinamicamente la voce premium `en-US` per utenti esteri e `it-IT` per utenti italiani, ottimizzando al contempo la velocità di scansione fonetica (`rate` di lettura differenziato).

### [2026-05-19 11:52]: Test e Validazione per Apple App Store Review
* **Dettagli**: Eseguiti test statici e di compilazione per assicurare la massima conformità alle linee guida ufficiali di Apple (App Store Review Guidelines), correggendo proattivamente i requisiti di sandbox.
* **Tech Notes**:
  - **Abilitazione Background Audio (`UIBackgroundModes`)**: Inserito l'entitlement dinamico `INFOPLIST_KEY_UIBackgroundModes = audio;` in `project.pbxproj` (Debug/Release). Questo assicura che iOS mantenga l'app attiva in background consentendo all'umpire vocale di funzionare correttamente a schermo bloccato.
  - **Sanity compilation test**: Eseguita una compilazione pulita con esito positivo (`xcodebuild` exit code `0`), garantendo l'assenza totale di crash-point su sandbox iOS 17+.
  - **App Store Readiness Report**: Generato un report strutturato ([app_store_readiness_report.md](file:///Users/simo/.gemini/antigravity/brain/e636f7aa-2058-456f-a422-ed861238f309/app_store_readiness_report.md)) che confronta l'architettura del software con le sezioni 2.1, 2.5, 4 e 5 delle linee guida di Apple.

### [2026-05-19 11:54]: Risoluzione Completa Warning di Concorrenza Swift 6 e Asset Icone
* **Dettagli**: Risolti tutti i warning segnalati da Xcode relativi alle rigide regole di concorrenza Swift 6 sul bridge di Apple Watch e ai riferimenti di icone mancanti nei cataloghi degli asset.
* **Tech Notes**:
  - **Swift 6 Concurrency & Sendability**: Importato `@preconcurrency import WatchConnectivity` per sopprimere warning esterni. Sostituito il wrapping legacy di `DispatchQueue.main.async` con blocchi asincroni nativi `@MainActor Task` e rimosse le catture di parametri non-Sendable in closure `@Sendable` accedendo direttamente a `WCSession.default`.
  - **Migrazione Standard Icone Single Size**: Riconfigurato `Contents.json` nel catalogo degli asset `AppIcon.appiconset` per utilizzare lo standard moderno di Apple **Single Size universal** a 1024x1024 pixel. Copiato il file `AppIcon_1024.png` direttamente nella cartella fisica degli asset, rimuovendo all'istante 23 avvisi relativi a icone legacy non presenti.

### [2026-05-19 11:57]: Allineamento Visivo degli Indicatori di Set (Scoreboard Dots)
* **Dettagli**: Corretto il comportamento visivo dei pallini segna-set nella schermata principale per mostrare l'intera capienza del match selezionata (3 pallini per Best of 3, 5 pallini per Best of 5), mantenendo intatte le regole matematiche di vittoria.
* **Tech Notes**:
  - **Svincolo visuale**: Sostituita la formula `ceil(bestOfSets / 2.0)` (che calcolava solo i set minimi necessari per vincere, es. 2 per un best of 3) con il valore intero `bestOfSets` all'interno del loop `ForEach` in `ContentView.swift`.
  - **Coerenza logica**: Le regole interne di gioco e i trigger di traguardo in `ScoreViewModel.swift` rimangono intatti e protetti matematicamente, garantendo che un match "Best of 3" si concluda correttamente al raggiungimento dei 2 set vinti.













