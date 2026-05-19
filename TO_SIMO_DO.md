# Azioni Manuali per Simo 🏓

## 2. Preparazione per l'App Store Connect (Pubblicazione)
Per pubblicare l'app, Apple richiede alcune impostazioni personali di firma digitale:
1. **Configura il Team di Sviluppo**:
   - In Xcode, seleziona l'icona del progetto in cima alla barra laterale sinistra (**PingPong**).
   - Fai clic sulla scheda **Signing & Capabilities** (Firma e Abilitazioni).
   - Sotto la sezione **Signing**, seleziona il tuo account personale dal menu a tendina **Team**.
2. **Personalizza il Bundle Identifier** (opzionale):
   - Di default ho configurato `com.simo.pingpong`. Se preferisci un altro identificatore per l'App Store Connect, puoi modificarlo nel campo **Bundle Identifier** all'interno dello stesso pannello di firma.
3. **Archivia e Carica**:
   - Imposta la destinazione di build su **Any iOS Device (arm64)** (oppure il tuo dispositivo collegato).
   - Vai sul menu superiore **Product** -> **Archive**.
   - Al termine dell'archiviazione, si aprirà l'Organizer di Xcode da cui potrai cliccare su **Distribute App** per caricarla su App Store Connect.

## 3. Companion App per Apple Watch ⌚ [CONFIGURATA & INTEGRATA]

Ho configurato ed integrato completamente i sorgenti nativi watchOS companion direttamente all'interno del target Xcode che hai creato! Ho verificato la build ed è perfettamente funzionante con codice di uscita `0`.

Per testarla subito sul tuo simulatore o dispositivo fisico:
1. **Seleziona la Destinazione in Xcode**: Nella barra superiore delle destinazioni di Xcode, seleziona il simulatore **`PingPongWatch Watch App`** accoppiato al tuo iPhone (o il tuo orologio fisico).
2. **Avvia il Match**: Premi **Play** (oppure `Cmd + R`) per compilare ed eseguire l'app.
3. **Gioca!**: Qualsiasi punto o azione registrati sull'Apple Watch aggiornerà l'iPhone in tempo reale e viceversa tramite la connessione bidirezionale ultra-rapida con feedback aptico integrato!


## 4. Attivare Live Activities & Dynamic Island in Xcode (1 Minuto) 🚀
Ho pre-generato l'intera struttura del Widget e configurato i permessi di sicurezza in modo che compilino all'istante. Per attivare la visualizzazione su Lock Screen e Dynamic Island, segui questi semplici passaggi in Xcode:

1. **Aggiungi il Target Widget in Xcode**:
   - Con il progetto aperto in Xcode, vai nel menu superiore su **File** -> **New** -> **Target...**
   - Nella barra di ricerca scrivi **Widget Extension**, selezionalo e fai clic su **Next**.
   - Configura le seguenti informazioni:
     - *Product Name*: **`PingPongWidget`**
     - *Include Live Activity*: Spunta la casella **SÌ** (molto importante!).
     - *Include Configuration Intent*: Lascialo deselezionato.
   - Fai clic su **Finish** e poi su **Activate** se Xcode ti chiede di attivare lo schema.

2. **Aggiungi i File pre-generati al Target Widget**:
   - Xcode creerà una cartella chiamata `PingPongWidget` nella barra laterale sinistra del navigatore di progetto.
   - Espandila, seleziona i file di default creati da Xcode (`PingPongWidget.swift`, `PingPongWidgetBundle.swift`, `PingPongWidgetLiveActivity.swift`) ed **eliminali** (clicca *Move to Trash*).
   - Fai clic destro sulla cartella `PingPongWidget` in Xcode, seleziona **Add Files to "PingPong"...**
   - Seleziona i 2 file che ho preparato per te nel workspace all'interno della cartella `PingPongWidget`:
     - `PingPongWidgetBundle.swift`
     - `PingPongWidgetLiveActivity.swift`
   - Sotto la sezione **Targets** a fondo pagina, assicurati che la spunta ci sia unicamente su **`PingPongWidgetExtension`**.
   - Clicca su **Add**.

3. **Condividi il file di Attributi (Target Membership)**:
   - Nella barra laterale sinistra di Xcode, espandi la cartella principale `PingPong` e seleziona il file **`PingPongAttributes.swift`**.
   - Nella barra laterale destra (se non è visibile, mostrala premendo `Cmd + Option + 0`), vai sulla scheda **File Inspector** (la prima icona in alto).
   - Sotto la sezione **Target Membership**, aggiungi la spunta alla casella **`PingPongWidgetExtension`** (lasciando attiva anche quella di `PingPong`).

4. **Pronti per il Futuro!**:
   - Avvia l'applicazione sul tuo simulatore iPhone premendo **Play** (`Cmd + R`).
   - Quando fai il primo punto nel match, **blocca lo schermo del simulatore** (`Cmd + L`) o torna alla schermata Home: vedrai lo spettacolare tabellone neon interattivo brillare in tempo reale direttamente sulla Lock Screen e nella Dynamic Island!

## 5. Checklist di Pubblicazione su App Store Connect 🚀

Ho creato una guida dettagliata completa nel tuo workspace chiamata **`GUIDA_PUBBLICAZIONE_APP_STORE.md`** per darti tutte le informazioni necessarie ad evitare rifiuti (rejection) da Apple. Qui trovi la lista di controllo rapida delle attività manuali da completare:

- [ ] **1. Account Apple Developer**: Verifica che la tua iscrizione annuale da $99/anno sia attiva.
- [ ] **2. Registra gli Identifiers (developer.apple.com)**:
  - [ ] App ID Principale: `com.simo.pingpong` (Abilita **App Groups** e **Live Activities**).
  - [ ] App ID Widget: `com.simo.pingpong.PingPongWidget` (Abilita **App Groups**).
  - [ ] App ID Watch App: `com.simo.pingpong.watchkitapp`.
  - [ ] Crea l'App Group `group.com.simo.pingpong` e associalo sia all'app principale che alla Widget Extension.
- [ ] **3. Crea la scheda App Store Connect**:
  - [ ] Piattaforma: iOS.
  - [ ] Nome: `Ping Pong Scoreboard - Neon` (o simile).
  - [ ] Seleziona il Bundle ID principale.
  - [ ] Dichiarazione Privacy: dichiara "Dati non raccolti" per velocizzare la revisione.
- [ ] **4. Prepara gli Asset**:
  - [ ] Screenshot iPhone 6.7" (iPhone 15/16 Pro Max) - min. 3 immagini.
  - [ ] Screenshot iPhone 5.5" (iPhone 8 Plus) - min. 3 immagini.
  - [ ] Screenshot Apple Watch (Series 7/8/9/Ultra) - min. 2 immagini.
  - [ ] Icona quadrata a 1024x1024 (già inclusa nel progetto come `AppIcon_1024.png`).
- [ ] **5. Archivia e Carica da Xcode**:
  - [ ] Configura il tuo **Team** di sviluppo in *Signing & Capabilities* per tutti e tre i target in Xcode.
  - [ ] Imposta Version: `1.0.0` e Build: `1` per tutti e tre i target.
  - [ ] Seleziona **Any iOS Device (arm64)** come destinazione di build.
  - [ ] Menu `Product` -> `Archive`.
  - [ ] Clicca su `Distribute App` e seleziona `Upload` su App Store Connect.
- [ ] **6. Invia per la Revisione**:
  - [ ] Associa la build caricata alla versione 1.0.0 su App Store Connect.
  - [ ] **FONDAMENTALE**: Copia e incolla la spiegazione del *Background Audio* (disponibile nella Sezione 7 della guida completa `GUIDA_PUBBLICAZIONE_APP_STORE.md`) nelle note di revisione.
  - [ ] **FONDAMENTALE**: Registra e allega un video demo di 1 minuto che mostra l'app in azione su iPhone, con la Live Activity funzionante sulla Lock Screen, per aiutare i revisori a testarla rapidamente senza intoppi.
