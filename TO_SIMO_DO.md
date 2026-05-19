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


## 4. Live Activities & Dynamic Island 🚀 [CONFIGURATE & INTEGRATE]

Ho completato interamente l'integrazione del widget e configurato la Target Membership di `PingPongAttributes.swift` direttamente nei file di progetto! La build del modulo compile con successo assoluto (`BUILD SUCCEEDED`, codice `0`).

Per testare subito la Lock Screen interattiva e la Dynamic Island sul simulatore:
1. **Seleziona la Destinazione**: Fai clic sullo schema di avvio principale **`PingPong`** nella barra degli strumenti in alto di Xcode e seleziona un simulatore iPhone (ad esempio *iPhone 16 Pro*).
2. **Avvia l'App**: Premi **Play** (`Cmd + R`) per installare e l'eseguire l'applicazione.
3. **Avvia una Partita**: Tocca lo schermo per avviare il match.
4. **Guarda la Magia**: 
   - Premi `Cmd + L` sul Mac per **bloccare lo schermo del simulatore**: vedrai il meraviglioso widget neon frosted visualizzare i punteggi, i set e il server di battuta.
   - Sblocca il simulatore e torna alla schermata **Home** dell'iPhone (`Cmd + Shift + H`): la **Dynamic Island** mostrerà i punteggi sintetici, e con una pressione prolungata si espanderà svelando il tabellone completo!


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
