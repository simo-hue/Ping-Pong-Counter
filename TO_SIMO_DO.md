# Azioni Manuali per Simo 🏓

## iCloud — perché diceva "non disponibile" (RISOLTO nel codice, serve un passaggio tuo)

Due cause, entrambe corrette ora nel codice:
1. Mancava l'entitlement `com.apple.developer.ubiquity-kvstore-identifier` (avevi aggiunto solo App Groups). Ora è in `PingPong/PingPong.entitlements`.
2. Il mio controllo di disponibilità richiedeva `FileManager.ubiquityIdentityToken`, che riguarda iCloud **Drive**, non il key-value store: avrebbe continuato a dire "non disponibile" anche dopo il punto 1. Ora sonda `synchronize()`, che è il segnale giusto.

Cosa devi fare tu:
- [ ] Xcode → target **PingPong** → Signing & Capabilities → **+ iCloud** → spunta solo **Key-value storage** (App Groups resta com'è).
- [ ] Rigenera i provisioning profile e **ri-carica su TestFlight**: gli entitlement sono nella firma, quindi la build attuale non può funzionare nemmeno aggiornandola.
- [ ] Dopo l'installazione: Impostazioni → iCloud → l'interruttore "Sincronizza Storico" deve comparire.

## Prima di inviare la 2.0

- [ ] **Era un blocco all'upload**: l'estensione widget non aveva un privacy manifest e Apple lo verifica per **ogni binario** del bundle → rifiuto automatico `ITMS-91053`. Aggiunto `PingPongWidget/PrivacyInfo.xcprivacy` (incluso in automatico dal gruppo sincronizzato, nessuna modifica al pbxproj). Aggiunto anche il motivo `1C8F.1` a quello dell'app, che ora accede ai defaults di un App Group.
- [ ] La descrizione e la privacy policy chiamavano l'app "Ping Pong Scoreboard" mentre sullo Store si chiama "Ping Pong Counter". Una privacy policy che nomina un altro prodotto è il classico rifiuto 5.1.1 — corretto in `metadata/en-GB/description.txt`, `docs/index.html` e `index.html`. **Ripubblica GitHub Pages** perché App Review apre la pagina online.
- [ ] `metadata/en-GB/release_notes.txt` dice ancora "UI improvements": va riscritto per un salto 1.0.1 → 2.0 (doppio, rosa giocatori, statistiche, widget, Live Activity interattiva, iCloud, Siri, export, VoiceOver).
- [ ] `metadata/review_information/notes.txt` è vuoto: conviene spiegare a chi revisiona come provare doppio e Live Activity.

## Verifiche rapide senza Xcode (passano tutte)

```bash
./Tests/run-model-checks.sh && ./Tests/run-view-typecheck.sh && ./Tests/run-viewmodel-typecheck.sh
```

## Da provare a mano

- [ ] **Cambio campo durante una partita** con la Live Activity attiva: era il bug più grave trovato: i nomi restavano quelli vecchi e il pulsante "+ Simone" segnava per Gianni.
- [ ] Effetti sonori (Impostazioni → Audio): gli ID di sistema sono scelti alla cieca.
- [ ] Doppio con quattro persone vere, verificando la rotazione ai vantaggi.
- [ ] Widget Home subito dopo aver vinto una partita ma **prima** di azzerarla: deve mostrare "FINALE" con i set, non la partita precedente.
- [ ] **Con la sincronizzazione attiva, esci da iCloud** (Impostazioni iOS → Apple ID → Esci): lo storico locale deve restare intatto. Era il bug più grave del rifacimento: la disconnessione cancellava tutto.
- [ ] Rinominare un giocatore in Impostazioni con la Live Activity attiva: deve riavviarsi **una volta sola** a fine digitazione, non a ogni lettera.

---

## Metadati fastlane 2.0 — generati, da caricare (2026-08-04)

Sono stati scritti i metadati per **11 lingue** in `metadata/`: `en-US` (prima mancava), `en-GB`, `it`, `de-DE`, `fr-FR`, `es-ES`, `es-MX`, `pt-BR`, `ja`, `ko`, `zh-Hans`. Il nome dell'app è `Ping Pong Counter` identico in tutte.

### 1. Installa fastlane — non è presente su questa macchina

Ho verificato: né `fastlane` né `deliver` sono nel PATH, quindi il comando di upload **non può ancora girare**.

```bash
brew install fastlane
```

### 2. Carica i metadati

Dalla root del repo (`metadata/` è lì, non in `fastlane/metadata/`):

```bash
fastlane deliver --app_identifier com.simo.pingpong --app_version 2.0 --skip_binary_upload --skip_screenshots --username mattioli.simone.10@gmail.com
```

- `--skip_binary_upload`: il binario lo carichi da Xcode/Transporter, questo comando tocca solo i testi.
- `--skip_screenshots`: gli screenshot attuali restano quelli già online (vedi punto 4).
- **Non c'è `--force` di proposito**: `deliver` apre un'anteprima HTML di tutte e 11 le schede e aspetta la tua conferma. Su un primo caricamento multilingua è quella l'occasione per accorgersi di un sottotitolo giapponese troncato prima che se ne accorga Apple.
- Serve una **password specifica per app** (appleid.apple.com → Sicurezza), non la password normale. Se ti chiede il team di App Store Connect, è un ID numerico diverso da `8528AN28A3`, che è il team del Developer Portal.
- La versione 2.0 deve essere in stato **"Pronta per l'invio"** su App Store Connect, altrimenti `deliver` non trova un version editabile.

### 3. Verifica il layout su iPad prima di inviare

`TARGETED_DEVICE_FAMILY = "1,2"`: l'app viene distribuita **anche su iPad** e la descrizione precedente non lo diceva mai. Ora tutte e 11 le descrizioni si aprono con "iPhone, iPad e Apple Watch". È l'unica affermazione nuova che non ho potuto verificare dal codice.

- [ ] Apri l'app su un iPad (o simulatore iPad) e controlla che il tabellone sia presentabile in orizzontale e verticale. Se non lo è, togli "iPad" dalla prima riga delle 11 descrizioni prima di caricare.

### 4. Gli screenshot sono ancora quelli della 1.x

Gli 8 render in `app_Screen_Render/apple/English (en-US)/` non mostrano **niente** della 2.0: né doppio, né rosa, né statistiche, né storico, né widget. Restano online come sono perché il comando li salta.

- [ ] Rifare gli screenshot per la 2.0. È la cosa a più alto impatto sulla conversione rimasta da fare, e va fatta con calma dopo il caricamento dei testi (gli screenshot si aggiornano da soli, senza toccare i metadati).
- Nota: per caricarli con `deliver` servirebbe il layout `screenshots/<locale>/*.png`, che è diverso da quello attuale.

### 5. Categoria invertita — controlla che ti torni

`primary_category` è passata da `UTILITIES` a `SPORTS` (e `UTILITIES` è ora la secondaria). UTILITIES è una delle categorie più affollate dello Store: per un segnapunti non è classificabile, mentre le classifiche SPORTS per singolo paese sono raggiungibili. È reversibile al prossimo invio.

### 6. Cina: `zh-Hans` da solo non basta

La scheda in cinese semplificato è pronta, ma la distribuzione sullo storefront cinese richiede una **registrazione ICP**. Se l'app non è già disponibile in Cina, quella localizzazione resta inutilizzata. Non costa nulla tenerla, ma non è lei a sbloccare il mercato.

### 7. Due voci sopra sono risolte

- ~~`release_notes.txt` diceva ancora "UI improvements"~~ → riscritto per il salto 1.0.1 → 2.0, in tutte e 11 le lingue.
- ~~`review_information/notes.txt` è vuoto~~ → ora spiega a chi revisiona come provare doppio, Live Activity, widget, storico, statistiche, export, iCloud e Apple Watch, e dichiara che non serve alcun account.

Resta invece aperta la voce su **GitHub Pages da ripubblicare**: App Review apre `privacy_url` e `support_url` online, e tutte e 11 le schede puntano lì.
