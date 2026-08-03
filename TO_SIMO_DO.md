# Azioni Manuali per Simo 🏓

- [ ] Build completa su Mac mini: `xcodebuild -scheme PingPong -sdk iphonesimulator build` (qui manca Xcode).
- [ ] Verificare in Xcode → Build Phases → Compile Sources del target **PingPong** che ci siano: `MatchClock`, `SoundManager`, `SetRecord`, `AppTheme`, `MatchDetailView`, `MatchRecord`, `RosterPlayer`, `RosterView`, `PlayerStatsView`, `StatsAggregates`, `StatsView`, `DoublesLineup`, `DoublesSetupView`, `DoublesRosterStrip`, `SharedStore`, `PersistenceKeys`, `ScoreActionIntent`, `ShareCardView`.
      Nel target **PingPongWidgetExtension** deve esserci anche `ScoreActionIntent.swift`.
- [ ] Verifiche rapide senza Xcode (tutte e tre passano ora):
      `./Tests/run-model-checks.sh` · `./Tests/run-view-typecheck.sh` · `./Tests/run-viewmodel-typecheck.sh`

## Widget della schermata Home — DECISIONE RICHIESTA

Il widget Home legge lo stato dell'app, ma un'estensione è un processo separato: senza un **App Group** vede solo un contenitore vuoto e mostra "Nessuna partita". Funziona già tutto il resto (Live Activity, pulsanti +1/undo, share card): manca solo questo.

Se vuoi il widget Home funzionante:
- [ ] Xcode → target PingPong → Signing & Capabilities → **+ App Groups** → `group.com.simo.pingpong`
- [ ] Stessa cosa sul target PingPongWidgetExtension (stesso identificatore)
- [ ] Rigenerare i provisioning profile sul portale sviluppatori

Il codice è già pronto: `SharedStore` verifica il contenitore con `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` e, se non c'è, resta su `UserDefaults.standard` senza perdere nulla. Quando abiliti la capability, migra automaticamente tutte le chiavi. **Non aggiungere l'App Group a mano nel .entitlements senza provisioning**: la firma fallirebbe.

Nota: la guida `GUIDA_PUBBLICAZIONE_APP_STORE.md` dice di non abilitare App Groups — era vero prima del widget Home; aggiornala se decidi di abilitarlo.

## Da provare a mano

- [ ] Effetti sonori (Impostazioni → Audio): gli ID di sistema sono scelti alla cieca.
- [ ] Doppio con quattro persone vere, verificando la rotazione ai vantaggi.
- [ ] Pulsanti +1 / undo sulla Live Activity dalla schermata di blocco, ad app chiusa.
