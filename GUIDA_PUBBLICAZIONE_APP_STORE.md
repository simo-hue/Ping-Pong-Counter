# Guida Esperta e Passo-Passo per la Pubblicazione su iOS App Store 🏓
## Prevenzione delle Rejection e Conformità Standard Apple (watchOS & Live Activities)

Questa guida è stata redatta in conformità con le linee guida ufficiali **Apple App Store Review Guidelines** (aggiornate al 2026). Poiché l'applicazione **Ping Pong Counter** include funzionalità avanzate come una **Companion App per Apple Watch (watchOS)**, **Live Activities & Dynamic Island (ActivityKit)** e **Background Audio (AVSpeechSynthesizer)**, la procedura di sottomissione richiede un'attenzione particolare per evitare rifiuti automatici da parte dei revisori Apple.

---

## 📋 Indice dei Contenuti
1. [Propedeutica e Requisiti Fondamentali](#1-propedeutica-e-requisiti-fondamentali)
2. [Configurazione dei Bundle ID e Provisioning Profiles (Xcode & Developer Portal)](#2-configurazione-dei-bundle-id-e-provisioning-profiles)
3. [Creazione della Scheda App su App Store Connect](#3-creazione-della-scheda-app-su-app-store-connect)
4. [Preparazione degli Asset Grafici (Il primo motivo di blocco)](#4-preparazione-degli-asset-grafici)
5. [Configurazione dei Metadati e del "Nutrition Label" sulla Privacy](#5-configurazione-dei-metadati-e-della-privacy)
6. [Compilazione, Archiviazione e Caricamento della Build (Xcode & Transporter)](#6-compilazione-archiviazione-e-caricamento-della-build)
7. [Strategia Blindata Anti-Rejection (Live Activities, Audio & Watch)](#7-strategia-blindata-anti-rejection)
8. [Invio in Revisione e Ciclo di Approvazione](#8-invio-in-revisione)

---

## 1. Propedeutica e Requisiti Fondamentali

Prima di iniziare il processo di pubblicazione, assicurati di disporre di:
*   **Apple Developer Account**: Iscrizione attiva all'Apple Developer Program ($99/anno come singolo o organizzazione).
*   **Mac con Xcode**: Xcode aggiornato alla versione più recente.
*   **Dispositivi di Test (Consigliati)**: Un iPhone fisico ed eventualmente un Apple Watch per registrare un breve video dimostrativo (fondamentale per i revisori).
*   **Un URL di Supporto e Privacy**: Anche se l'app è 100% offline, Apple richiede un URL per il supporto clienti e un URL per la Privacy Policy. Puoi usare una pagina web statica creata con GitHub Pages, Notion (reso pubblico) o GitBook.

---

## 2. Configurazione dei Bundle ID e Provisioning Profiles

La nostra applicazione è composta da **3 Target differenti** in Xcode. Ognuno di essi richiede un identificativo univoco (Bundle Identifier) registrato nel portale Apple Developer.

### Configurazione sul Portale Apple Developer (developer.apple.com)
1. Accedi alla sezione **Certificates, Identifiers & Profiles** -> **Identifiers**.
2. Clicca sul tasto **+** per aggiungere i tre identificativi seguenti:

| Target in Xcode | Nome del Target | Esempio Bundle ID consigliato | Servizi ed Entitlement da Abilitare |
| :--- | :--- | :--- | :--- |
| **Applicazione iOS Principale** | `PingPong` | `com.simo.pingpong` | **Live Activities** |
| **Widget Extension** (Live Activities) | `PingPongWidget` | `com.simo.pingpong.PingPongWidget` | Nessuno manuale |
| **Watch Companion App** | `PingPongWatch` | `com.simo.pingpong.watchkitapp` | Nessuno (eredita le impostazioni o WCSession) |

> [!IMPORTANT]
> **Nota sulle capabilities**:
> La Live Activity viene aggiornata direttamente dall'app tramite ActivityKit e WidgetKit, quindi non richiede App Groups. Abilita solo le capability realmente usate: il target iOS deve supportare Live Activities, mentre il Watch usa WCSession e il Widget usa il normale extension point di WidgetKit.

---

## 3. Creazione della Scheda App su App Store Connect

1. Naviga su [App Store Connect](https://appstoreconnect.apple.com) e accedi con le quali credenziali Apple Developer.
2. Vai nella sezione **Le mie app** (My Apps) e fai clic sul pulsante **+** -> **Nuova app** (New App).
3. Compila il modulo a comparsa con i seguenti dati:
   *   **Piattaforma**: Seleziona **iOS**. (La spunta su watchOS non è necessaria in questo passaggio iniziale, in quanto l'app Watch è distribuita come "companion bundle" integrato nell'app iOS).
   *   **Nome**: `Ping Pong Scoreboard - Neon` (Scegli un nome accattivante, max 30 caratteri. Deve rispecchiare lo spirito dell'app).
   *   **Lingua principale**: **Italiano** (o *Inglese* se preferisci un target internazionale).
   *   **ID bundle**: Seleziona dal menu a tendina il Bundle ID principale appena registrato (`com.simo.pingpong`).
   *   **SKU**: Un codice alfanumerico interno a tua scelta (es. `SIMO-PINGPONG-2026`).
   *   **Accesso utente**: Seleziona *Accesso completo* (Full Access).
4. Clicca su **Crea**.

---

## 4. Preparazione degli Asset Grafici

Apple è estremamente rigida sui formati e le dimensioni degli asset. La mancanza di un solo formato bloccherà l'invio.

### A. Icona dell'Applicazione (App Icon)
*   **Già ottimizzata nel nostro workspace!** Abbiamo rimosso il "double-squircle" e convertito l'icona in un quadrato perfetto `AppIcon_1024.png` (1024x1024 px, sfondo nero assoluto con grafica cyberpunk neon). Xcode gestirà automaticamente il ridimensionamento universale.

### B. Screenshot di iPhone (Obbligatori)
Dovrai catturare e caricare gli screenshot per due formati di schermo principali. Utilizza il simulatore di Xcode per scattare foto pulite senza barra di stato sporca (es. segnale operatore o percentuali batteria casuali):

1.  **Schermo da 6.7" (iPhone 15/16 Pro Max o 14 Pro Max)**:
    *   *Risoluzione richiesta*: **1290 x 2796 pixel** (Verticale) o **2796 x 1290 pixel** (Orizzontale).
    *   *Cosa caricare*: Almeno 3 screenshot. Consigliamo:
        *   1x Schermata di gioco in orizzontale (Split screen neon sinistro/destro ad alto contrasto).
        *   1x Schermata di gioco in verticale (Split screen alto/basso per uso a una mano).
        *   1x Schermata delle impostazioni (`SettingsView`) mostrando le opzioni di personalizzazione del punteggio, dell'arbitro vocale e dei temi di colore.
2.  **Schermo da 5.5" (Modelli Plus/Retina legacy, es. iPhone 8 Plus)**:
    *   *Risoluzione richiesta*: **1242 x 2208 pixel** (Verticale) o **2208 x 1242 pixel** (Orizzontale).
    *   *Nota*: Apple richiede questo formato per supportare i dispositivi con aspect ratio 16:9.

### C. Screenshot di Apple Watch (Obbligatori!)
Avendo incluso un target watchOS, **Apple rifiuterà l'app se mancano gli screenshot per Apple Watch**.
1.  **Schermo Apple Watch Ultra o Series 7/8/9/10**:
    *   *Risoluzione richiesta*: **410 x 502 pixel** (Ultra) o **396 x 484 pixel** (45mm).
    *   *Cosa caricare*: Almeno 2 screenshot che mostrano l'interfaccia dell'Apple Watch companion (`WatchContentView.swift`) con i pulsanti touch giganti neon e il punteggio sincronizzato.

---

## 5. Configurazione dei Metadati e della Privacy

### A. Metadati di Marketing
*   **Titolo**: `Ping Pong Scoreboard - Neon`
*   **Sottotitolo**: `Tabellone segnapunti ed arbitro` (Max 30 caratteri. Ottimo per l'indicizzazione ASO).
*   **Descrizione**: Spiega chiaramente le funzionalità dell'app.
    *   *Esempio*: *"Il tabellone segnapunti definitivo per le tue partite reali di Ping Pong. Sfondi neon ad alto contrasto, orientamento adattivo (orizzontale/verticale), arbitro vocale in italiano che annuncia i punteggi in tempo reale, feedback aptici avanzati per ogni punto e una companion app per Apple Watch per aggiornare il punteggio direttamente dal polso. Supporta le Live Activities per seguire il punteggio direttamente dalla Lock Screen e dalla Dynamic Island in background! Zero pubblicità, 100% offline."*
*   **Parole chiave (Keywords)**: `ping pong,segnapunti,tabellone,tennis tavolo,watch,scoreboard,neon,live activity,arbitro vocale`
*   **URL di Supporto**: L'indirizzo web dove gli utenti possono contattarti per segnalazioni o bug.
*   **URL della Privacy Policy**: Il link al documento sulla privacy.

### B. Scheda "Privacy dell'app" (Nutrition Labels)
Questo è un punto cruciale che velocizzerà l'approvazione al 100%. La nostra app è **Totalmente Offline** e non raccoglie dati personali.
1. Vai su **Privacy dell'app** nella barra laterale sinistra.
2. Fai clic su **Inizia** nel questionario sulla raccolta dati.
3. Rispondi **NO, non raccogliamo dati utente da questa app**.
4. Salva e pubblica. Sulla pagina dell'App Store comparirà lo scudetto blu **"Dati non raccolti"** (Data Not Collected), un grandissimo punto di forza per gli utenti e per i revisori Apple.

### C. Privacy Manifest nel Bundle
Il progetto include `PingPong/PrivacyInfo.xcprivacy` nel target iOS principale. Il manifest dichiara:
*   **Nessun dato raccolto** (`NSPrivacyCollectedDataTypes` vuoto).
*   **Nessun tracking** (`NSPrivacyTracking = false`).
*   **Uso di `UserDefaults`** con reason `CA92.1`, perché l'app salva punteggi, nomi opzionali e preferenze solo nel proprio sandbox locale.

---

## 6. Compilazione, Archiviazione e Caricamento della Build

Segui questo protocollo tecnico per compilare, firmare e caricare il pacchetto binario senza errori di compilazione o firme. Puoi scegliere due percorsi differenti per il caricamento: il caricamento diretto tramite Xcode (Metodo A) o il caricamento tramite l'app ufficiale **Apple Transporter** (Metodo B, consigliato per connessioni lente o in caso di bug di rete con Xcode).

### 🛠️ Step 1: Preparazione e Archiviazione (Comune a entrambi i metodi)

1.  **Configura la firma (Signing)** in Xcode per tutti e 3 i target:
    *   Seleziona la radice del progetto `PingPong` nella barra sinistra di Xcode.
    *   Per il target principale `PingPong`, vai nella scheda **Signing & Capabilities**.
    *   Seleziona il tuo **Team di sviluppo** ed abilita la spunta su *Automatically manage signing*.
    *   Ripeti l'operazione per il target `PingPongWidget` e per il target `PingPongWatch Watch App`.
2.  **Imposta i numeri di versione**:
    *   *Version*: `1.0.0` (il numero visualizzato dagli utenti).
    *   *Build*: `1` (il numero interno progressivo. Ogni volta che carichi un nuovo pacchetto, anche per lo stesso aggiornamento `1.0.0`, devi incrementare questo valore: `2`, `3`, `4`...).
3.  **Prepara la compilazione**:
    *   Nella barra superiore di Xcode, seleziona come destinazione **Any iOS Device (arm64)** (oppure scollega il tuo telefono fisico e seleziona la build generica per dispositivi iOS).
4.  **Esegui l'Archiviazione**:
    *   Vai su **Product** -> **Clean Build Folder** (Cmd + Shift + K) per ripulire file obsoleti.
    *   Vai su **Product** -> **Archive**.
    *   Attendi il completamento della compilazione. Al termine si aprirà automaticamente la finestra dell'**Organizer** di Xcode.

---

### 🚀 Metodo A: Caricamento Diretto da Xcode (Metodo Standard)

1.  Nell'**Organizer** di Xcode, seleziona l'archivio appena generato sotto la voce *iOS Apps*.
2.  Fai clic sul pulsante **Distribute App** posizionato sulla destra.
3.  Seleziona **App Store Connect** e clicca su **Upload** (Invia).
4.  Mantieni spuntate le opzioni di default (inclusa la ricompilazione bitcode e l'invio dei simboli di debug).
5.  Xcode effettuerà l'autenticazione con il tuo Developer Account, convaliderà la firma e i bundle ID con i server Apple, e infine caricherà il binario.
6.  *Attesa*: Una volta completato il caricamento, riceverai una mail di conferma da Apple. Il binario richiederà circa 5-20 minuti di elaborazione interna ("Processing") prima di comparire su App Store Connect.

---

### 📦 Metodo B: Caricamento tramite l'App "Transporter" (Consigliato per Connessioni Instabili o Errori di Xcode)

L'applicazione ufficiale **Transporter** di Apple (scaricabile gratuitamente dal Mac App Store) è lo strumento autonomo professionale per caricare pacchetti pre-compilati. È straordinariamente robusto: gestisce la ripresa del caricamento in caso di disconnessioni di rete, è più veloce di Xcode e previene i frequenti timeout di caricamento che affliggono Xcode.

#### 1. Esporta la Build in Formato `.ipa` da Xcode
Invece di caricare direttamente l'app sui server Apple, la compileremo ed esporteremo localmente sul Mac:
1.  Nell'**Organizer** di Xcode, seleziona la tua build e fai clic su **Distribute App** sulla destra.
2.  Seleziona **App Store Connect** e fai clic su **Export** (Esporta) anziché *Upload*.
3.  Clicca su **Next**. Mantieni attive le selezioni predefinite per la conformità di distribuzione e procedi.
4.  Seleziona il tipo di distribuzione **App Store Connect** per la firma finale automatica.
5.  Scegli una cartella sul tuo Mac (es. il Desktop) in cui salvare l'esportazione e fai clic su **Export**.
6.  Xcode creerà una nuova cartella contenente diversi file. Il file che ci interessa si chiama **`PingPong.ipa`** (l'iOS App Store Package pronto per la pubblicazione).

#### 2. Esegui il Caricamento con l'App Transporter
1.  **Avvia Transporter** sul tuo Mac.
2.  **Effettua l'accesso**: Inserisci il tuo **Apple ID** associato al programma Apple Developer.
    *   *Nota*: Se usi l'autenticazione a due fattori (2FA), Transporter si collegherà perfettamente e in totale sicurezza usando le credenziali di sistema o richiedendoti l'approvazione sul tuo iPhone.
3.  **Aggiungi la Build**:
    *   Trascina e rilascia (Drag & Drop) il file **`PingPong.ipa`** esportato direttamente all'interno della finestra principale di Transporter.
    *   In alternativa, clicca sul pulsante **+** (Aggiungi app) al centro della finestra e seleziona il file `PingPong.ipa`.
4.  **Verifica le Informazioni**:
    *   Transporter analizzerà il file e mostrerà l'icona cyberpunk neon dell'app, il nome (`Ping Pong Scoreboard - Neon`), la piattaforma (iOS) e il numero preciso di versione e build (es. `1.0.0 (1)`).
5.  **Avvia la Consegna**:
    *   Clicca sul pulsante azzurro **Consegna** (Deliver) per avviare il caricamento.
    *   Transporter effettuerà una prima verifica di conformità locale e poi caricherà il binario sui server Apple, mostrando l'avanzamento esatto in percentuale e la velocità di upload.
6.  **Conferma di Successo**:
    *   Al termine, l'interfaccia si aggiornerà mostrando una **spunta verde** e il messaggio *"Consegnata"* (Delivered). Il file è stato inviato con successo ad Apple!

#### 3. Elaborazione e Sottoscrizione
*   Accedi ad [App Store Connect](https://appstoreconnect.apple.com).
*   La tua build comparirà sotto la sezione **TestFlight** o nella scheda **Build** della versione di rilascio in stato *"Elaborazione in corso"* (Processing).
*   Attendi 10-15 minuti. Non appena l'elaborazione è completata, riceverai una mail da Apple e potrai procedere all'invio per la revisione.

---

## 7. Strategia Blindata Anti-Rejection (Live Activities, Voce & Watch)

> [!WARNING]
> Qui si decide l'esito della revisione. Apple ritiene sistematicamente le applicazioni che dichiarano funzionalità avanzate senza fornire ai revisori i mezzi per testarle o senza spiegarne dettagliatamente l'utilità.

All'interno della scheda di invio dell'applicazione su App Store Connect, scorri fino alla sezione **Informazioni sulla revisione dell'app** (App Review Information) e compila accuratamente i seguenti campi:

### A. Campo "Note di Revisione" (Review Notes) - COPIA E INCOLLA IL SEGUENTE TESTO:

> **NOTE DI REVISIONE PER IL REVISORE APPLE (IT/EN):**
> 
> *Gentile team di revisione Apple,*
> *Questa applicazione è un tabellone segnapunti interattivo ad alto contrasto neon per partite reali di Ping Pong (Tennis da tavolo). Per garantire un'esperienza di gioco fluida e a mani libere, l'app include 3 funzionalità premium integrate:*
> 
> 1. **Assistente vocale in-app (AVSpeechSynthesizer)**:
>    *L'applicazione include un arbitro vocale opzionale che pronuncia ad alta voce il punteggio corrente ("10 a 8") e indica il cambio di servizio ("Servizio a Giocatore 1") quando l'utente modifica il punteggio con l'app aperta. La funzione usa una sessione audio temporanea solo durante l'annuncio e non dichiara modalità audio in background.*
> 
> 2. **Companion App per Apple Watch (watchOS Integration)**:
>    *Abbiamo incluso una companion app per Apple Watch. Questa consente al giocatore di incrementare o decrementare il punteggio in tempo reale sul proprio polso tramite connessione WCSession bidirezionale, aggiornando all'istante la schermata dell'iPhone posizionato a bordo tavolo senza dover interrompere l'azione.*
> 
> 3. **Live Activities & Dynamic Island (ActivityKit)**:
>    *L'applicazione supporta le Live Activities. Quando un match è attivo e viene registrato almeno un punto, il punteggio della partita in corso, il turno di servizio e il set corrente rimangono visibili in tempo reale sulla Lock Screen e nella Dynamic Island. Quando l'utente azzera il match, la Live Activity viene terminata per evitare contenuti persistenti non necessari.*
> 
> **ISTRUZIONI PER IL TEST:**
> - Non è richiesto alcun login o registrazione (l'app è 100% offline per tutelare la privacy dell'utente).
> - All'avvio dell'app, tocca lo schermo a sinistra o a destra per assegnare un punto.
> - Trascina il dito verso il basso (swipe down) su uno dei due campi per decrementare il punteggio (-1) in caso di errore.
> - Clicca sull'icona dell'ingranaggio in alto per accedere alle impostazioni e attivare la sintesi vocale ("Voice Announce Scores") per testare l'arbitro vocale mentre l'app è aperta.
> - Per simulare la sincronizzazione con Apple Watch e l'attivazione della Live Activity, vi invito a prendere visione del video dimostrativo allegato a questa sottomissione.

### B. Allegato Video Dimostrativo (Fondamentale!)
*   **Perché è necessario?** I revisori Apple eseguono i test principalmente su simulatori o dispositivi individuali che spesso non hanno un Apple Watch configurato o accoppiato. Se non vedono come funziona l'app Watch, la rifiuteranno etichettandola come "non funzionante" (Guideline 2.1).
*   **Como procedere**: registra un video dello schermo del tuo iPhone (o del simulatore Xcode) della durata di 1 minuto in cui:
    1.  Fai clic sullo schermo dell'iPhone per aumentare il punteggio.
    2.  Mostri il cambio di servizio automatico.
    3.  Torni alla schermata Home o blocchi il dispositivo mostrando la **Live Activity** attiva che si aggiorna.
    4.  *(Opzionale ma consigliato)* Mostri l'Apple Watch (anche simulatore) che aggiorna istantaneamente il punteggio dell'iPhone.
*   **Caricamento**: Trascina e rilascia questo file video (`.mp4` o `.mov`) direttamente nel box **Allegato** (Attachment) all'interno delle Informazioni sulla revisione dell'app, oppure fornisci un link YouTube privato ("Non in elenco") o Vimeo nel testo delle Note di Revisione.

---

## 8. Invio in Revisione e Ciclo di Approvazione

1.  Una volta completato il caricamento del build da Xcode e configurati tutti i metadati grafici e testuali su App Store Connect:
2.  Scorri fino alla sezione **Build** nella scheda della versione `1.0.0`.
3.  Fai clic sul pulsante **+** (o *Seleziona una build per iniziare*) e scegli il build che hai caricato in precedenza da Xcode. Clicca su **Fine**.
4.  In alto a destra, fai clic su **Invia per la revisione** (Submit for Review).
5.  L'app passerà allo stato **In attesa di revisione** (Waiting for Review).
    *   *Tempi medi di approvazione*: La revisione richiede solitamente **tra le 12 e le 36 ore**.
    *   Se l'app viene approvata, passerà allo stato *Pronta per la vendita* (Ready for Sale) e sarà visibile su App Store entro poche ore.
    *   Nel caso raro di una **Rejection**, Apple ti contatterà tramite il *Centro Risoluzione Problemi* (Resolution Center) spiegando il motivo esatto. Grazie alle difese inserite in questa guida (giustificazione audio e video dimostrativo), sarai in grado di rispondere immediatamente o risolvere eventuali obiezioni con un semplice chiarimento scritto.

---

## 9. Integrazione e Rilascio Continuo con Xcode Cloud (CI/CD) ☁️

Ora che hai attivato Xcode Cloud e lo hai collegato al tuo repository GitHub, puoi automatizzare l'intero processo di compilazione, firma digitale e caricamento su App Store Connect ad ogni commit o merge sul ramo principale. Questo elimina la necessità di eseguire l'archiviazione manuale locale e garantisce build pulite e pronte per il rilascio.

### A. Come funziona la firma automatica (Signing) in Xcode Cloud
Xcode Cloud gestisce la firma del codice in modo sicuro utilizzando i **Cloud Managed Certificates**:
1. Non devi esportare o caricare certificati di distribuzione (`.p12`) o provisioning profile manuali su Xcode Cloud.
2. Quando Xcode Cloud compila l'applicazione, si collega direttamente al tuo portale Apple Developer utilizzando il tuo Apple ID di sviluppo (o la chiave API di App Store Connect) per generare certificati di distribuzione temporanei e firmare i 3 target del progetto (`PingPong`, `PingPongWidget` e `PingPongWatch Watch App`).
3. **Requisito Chiave**: Assicurati che i tre Bundle ID descritti nella [Sezione 2](#2-configurazione-dei-bundle-id-e-provisioning-profiles) siano stati preventivamente registrati manualmente sul portale Apple Developer e che la capability **Live Activities** sia disponibile per il target iOS principale.

### B. Creazione del Workflow "App Store Release" in Xcode
Puoi configurare il flusso di build continuo (Workflow) direttamente da Xcode:
1. Apri il progetto `PingPong.xcodeproj` in Xcode sul tuo Mac.
2. Apri il **Report Navigator** nella barra sinistra (l'icona a forma di fumetto con una freccia in basso a destra o usa la combinazione `Cmd + 9`).
3. Seleziona la scheda **Cloud** in alto.
4. Fai clic su **Create Workflow...** (o vai nel menu superiore di Xcode e seleziona **Product** -> **Xcode Cloud** -> **Create Workflow...**).
5. Seleziona il prodotto `PingPong` e fai clic su **Next**.
6. Configura i dettagli del Workflow come segue:
   *   **Name**: `App Store Release`
   *   **Description**: `Compilazione automatica e invio a TestFlight/App Store ad ogni merge su main.`
   *   **Repository**: Assicurati che sia selezionato il tuo repository GitHub connesso.
7. Nella sezione **Start Conditions** (Condizioni di avvio):
   *   Seleziona la condizione predefinita **Branch Changes**.
   *   Imposta il branch target su **`main`** (o il tuo branch di rilascio principale).
   *   Lascia le impostazioni di default per compilare ad ogni modifica o configura filtri personalizzati se necessario.
8. Nella sezione **Actions** (Azioni):
   *   Xcode Cloud ha un'azione di default chiamata **Build**. Fai clic sul pulsante **+** o modifica l'azione per impostarla come **Archive**.
   *   **Platform**: Seleziona **iOS**.
   *   **Scheme**: Seleziona **PingPong**.
   *   **Deployment Preparation**: Questo è il passaggio più importante. Seleziona **TestFlight and App Store** dal menu a tendina. *(Questa opzione indica a Xcode Cloud di effettuare una compilazione di produzione firmata correttamente per il rilascio commerciale, anziché una build di sviluppo o di test interno semplice)*.
9. Nella sezione **Post-Actions** (Azioni successive):
   *   Fai clic sul pulsante **+** sotto Post-Actions.
   *   Seleziona **TestFlight Internal Testing** (oppure *App Store Connect* se desideri caricarlo direttamente senza passare per TestFlight, anche se TestFlight è altamente consigliato per una convalida finale).
   *   Sotto **Groups**, fai clic su **+** e seleziona un gruppo di tester interni di App Store Connect (es. *App Store Connect Users*). Questo farà in modo che, non appena la build viene compilata con successo da Xcode Cloud, questa venga distribuita immediatamente sul tuo dispositivo tramite l'app TestFlight.
10. Fai clic su **Save**.

### C. Gestione Automatica del Numero di Build (Build Numbering)
Uno degli aspetti più complessi dei flussi CI/CD tradizionali è l'incremento del numero di build (`CFBundleVersion`). Xcode Cloud risolve questo problema nativamente:
1. Ad ogni esecuzione del workflow, Xcode Cloud assegna un numero di build incrementale univoco (es. 1, 2, 3...).
2. Durante la compilazione sui server Apple, Xcode Cloud **sovrascrive automaticamente** il valore di *Build* impostato in Xcode con questo numero progressivo per tutti i target del bundle (`PingPong`, `PingPongWidget`, `PingPongWatch Watch App`).
3. Non devi fare commit manuali per incrementare il numero di build! Ti basta tenere la `MARKETING_VERSION` (Version in Xcode) allineata su `1.0.0` (o successive) e spingere il codice su GitHub.

### D. Verifica degli Scheme di Xcode (Checklist Fondamentale)
Affinché Xcode Cloud compili con successo tutti i componenti dell'app (inclusi widget e orologio):
1. Apri Xcode e seleziona lo Scheme **PingPong** nel selettore in alto a sinistra.
2. Fai clic sullo Scheme e seleziona **Edit Scheme...**.
3. Nella barra laterale sinistra della finestra a comparsa, seleziona la voce **Build**.
4. Assicurati che tutti e tre i target siano elencati:
   *   `PingPong` (iOS App)
   *   `PingPongWidgetExtension` (Widget)
   *   `PingPongWatch Watch App` (Apple Watch)
5. Assicurati che per ciascuno di essi la spunta sotto la colonna **Archive** sia **attiva**. *(Se non lo è, Xcode Cloud non includerà la companion app watchOS o i widget nel pacchetto finale di distribuzione, portando a sottomissioni incomplete)*.
6. Fai clic su **Close**.

### E. Flusso Operativo per il Rilascio Finale
Ora il tuo sistema è completamente automatizzato! Ecco il flusso che seguirai d'ora in poi per pubblicare:
1. **Scrivi il codice e fai i test locali**.
2. **Aggiorna la versione** commerciale (es. `1.0.0`) in Xcode se stai rilasciando una nuova versione.
3. **Esegui il Push su GitHub** sul branch `main`.
4. **Xcode Cloud si attiva automaticamente**:
   *   Puoi monitorare la compilazione direttamente da Xcode (Report Navigator -> Cloud) o accedendo ad App Store Connect -> Xcode Cloud.
   *   Il server scarica il codice da GitHub, risolve le dipendenze, firma il bundle per iOS + watchOS + Widget ed esegue l'archiviazione.
5. **Ricezione su TestFlight**:
   *   Entro 10-15 minuti, riceverai una notifica email e una notifica push sul tuo iPhone dall'app TestFlight: la nuova build è pronta per essere testata.
6. **Sottomissione finale ad App Store**:
   *   Una volta verificata la build su TestFlight, accedi ad App Store Connect.
   *   Vai su **App Store** -> **1.0.0 Pronta per l'invio**.
   *   Scorri fino alla sezione **Build**, clicca su **+**, seleziona la build generata da Xcode Cloud e fai clic su **Salva**.
   *   Assicurati di aver inserito i metadati e le note di revisione protettive (come descritto nella [Sezione 7](#7-strategia-blindata-anti-rejection)).
   *   Clicca su **Invia per la revisione** in alto a destra!
