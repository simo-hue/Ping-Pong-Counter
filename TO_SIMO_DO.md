# Azioni Manuali per Simo 🏓

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
