# Azioni Manuali per Simo 🏓

- [ ] Build completa su Mac mini: `xcodebuild -scheme PingPong -sdk iphonesimulator build` (qui manca Xcode, verificato solo con `swiftc -parse`).
- [ ] Verificare in Xcode che i nuovi file del target principale siano elencati in Build Phases → Compile Sources: `MatchClock.swift`, `SoundManager.swift`, `SetRecord.swift`, `AppTheme.swift`, `MatchDetailView.swift`, `MatchRecord.swift`, `RosterPlayer.swift`, `RosterView.swift`, `PlayerStatsView.swift`, `StatsAggregates.swift`, `StatsView.swift`.
- [ ] Verifiche rapide senza Xcode: `./Tests/run-model-checks.sh` e `./Tests/run-view-typecheck.sh`
- [ ] Provare a orecchio gli effetti sonori (Impostazioni → Audio): gli ID di sistema sono scelti alla cieca.
