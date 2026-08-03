# Azioni Manuali per Simo 🏓

- [ ] Build completa su Mac mini: `xcodebuild -scheme PingPong -sdk iphonesimulator build` (qui manca Xcode).
- [ ] Verificare in Xcode che i nuovi file del target principale siano in Build Phases → Compile Sources: `MatchClock`, `SoundManager`, `SetRecord`, `AppTheme`, `MatchDetailView`, `MatchRecord`, `RosterPlayer`, `RosterView`, `PlayerStatsView`, `StatsAggregates`, `StatsView`, `DoublesLineup`, `DoublesSetupView`, `DoublesRosterStrip`.
- [ ] Verifiche rapide senza Xcode (tutte e tre passano):
      `./Tests/run-model-checks.sh` · `./Tests/run-view-typecheck.sh` · `./Tests/run-viewmodel-typecheck.sh`
- [ ] Provare a orecchio gli effetti sonori (Impostazioni → Audio): gli ID di sistema sono scelti alla cieca.
- [ ] Provare il doppio con quattro persone vere e verificare la rotazione ai vantaggi.
