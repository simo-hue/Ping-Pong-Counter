# Azioni Manuali per Simo 🏓

Ecco i passi da seguire per compilare, testare e pubblicare l'applicazione di Ping Pong sul tuo iPhone o sull'App Store:

## 1. Avviare l'App nel Simulatore o su Dispositivo Fisico
1. **Apri il progetto in Xcode**: Fai doppio clic sul file `PingPong.xcodeproj` generato all'interno della cartella di lavoro per aprirlo nell'ambiente nativo Apple Xcode.
2. **Seleziona la destinazione**: Nella barra degli strumenti superiore di Xcode, fai clic sulla destinazione attiva (vicino al pulsante "Play") e seleziona un simulatore (es. *iPhone 16 Pro*) o il tuo iPhone fisico se è collegato al Mac.
3. **Avvia l'app**: Clicca sul pulsante **Play** (oppure premi sulla tastiera `Cmd + R`). L'applicazione verrà compilata ed eseguita immediatamente.

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

## 3. Collegare la Companion App per Apple Watch in Xcode ⌚
Ho già creato tutti i file pronti per watchOS all'interno della cartella `PingPongWatch Watch App` nel tuo workspace. Per collegarli in Xcode e attivarli, segui questi 3 rapidi passi:

1. **Aggiungi il Target Apple Watch in Xcode**:
   - Con il progetto aperto in Xcode, vai nel menu superiore su **File** -> **New** -> **Target...**
   - Nella scheda superiore del popup seleziona **watchOS**, scegli il template **Watch App** e fai clic su **Next**.
   - Configura le seguenti informazioni:
     - *Product Name*: **`PingPongWatch`**
     - *Organization Identifier*: `com.simo`
     - *Bundle Identifier*: diventerà automaticamente `com.simo.pingpong.watchkitapp` (va benissimo!).
   - Fai clic su **Finish**. Se Xcode ti chiede di attivare il nuovo schema di compilazione (Activate Scheme), fai clic su **Activate**.

2. **Aggiungi i File pre-generati al nuovo Target**:
   - Xcode creerà una cartella chiamata `PingPongWatch Watch App` nella barra laterale sinistra del navigatore di progetto.
   - Espandila, seleziona il file di default `ContentView.swift` creato da Xcode e **eliminalo** (clicca *Move to Trash*).
   - Fai clic destro sulla cartella `PingPongWatch Watch App` in Xcode, seleziona **Add Files to "PingPongWatch"...**
   - Seleziona i 3 file che ho già preparato per te nel workspace all'interno della cartella `PingPongWatch Watch App`:
     - `PingPongWatchApp.swift`
     - `WatchConnector.swift`
     - `WatchContentView.swift`
   - Prima di cliccare su *Add*, assicurati che sotto la sezione **Targets** a fondo pagina ci sia la spunta unicamente su **`PingPongWatch Watch App`**.
   - Clicca su **Add**.

3. **Pronti per Giocare!**:
   - Ora, nella barra superiore delle destinazioni di Xcode, seleziona il simulatore **`PingPongWatch Watch App`** accoppiato al tuo iPhone.
   - Premi **Play** (`Cmd + R`) per avviare contemporaneamente l'app sul simulatore dell'iPhone e dell'Apple Watch. 
   - Qualsiasi tocco sull'Apple Watch aggiornerà l'iPhone in tempo reale e viceversa, con un'esperienza di sincronizzazione a mani libere superlativa!

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


