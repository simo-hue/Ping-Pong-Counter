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
