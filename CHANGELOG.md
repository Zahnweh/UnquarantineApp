# Changelog

## [1.2] – 2026-05-06

### Bugfix
- Quarantäne-Entfernung funktioniert jetzt zuverlässig: `removexattr()` Syscall direkt statt `xattr`-Subprocess. macOS Sequoia blockierte den Subprocess via TCC, wenn Dateien aus geschützten Ordnern (Desktop, Downloads) verarbeitet wurden.

## [1.1] – 2026-05-06

### Neu
- Menüleisten-Icon mit Drop-Zone als Popover (Linksklick), eigenes Icon aus App-Iconset
- Rechtsklick auf Menüleisten-Icon: Kontextmenü mit Über, Updates, Einstellungen, Beenden
- App-Menü mit Über, Einstellungen… (Cmd+,) und Beenden
- Einstellungen-Fenster (Cmd+,): „Im Hintergrund ausführen" und „Beim Login starten"
- Dock-Icon standardmäßig sichtbar; „Im Hintergrund ausführen" versteckt es
- Finder-Dienst: Rechtsklick auf beliebige Datei/Ordner → Dienste → **Unquarantine** oder **Unquarantine + Entpacken**
- xattr-Logik in `QuarantineRemover` ausgelagert (gemeinsam genutzt von Popover und Finder-Dienst)

## [1.0] – 2026-05-06

Erste Veröffentlichung.

### Features
- Drop-Zone für Archive und Ordner
- Entfernt `com.apple.quarantine` via `xattr -d [-r]`
- Option: Herkunfts-Metadaten entfernen (`kMDItemWhereFroms`, `kMDItemDownloadedDate`)
- Option: Archiv nach Verarbeitung mit Standard-App entpacken
- Option: Rekursiver Modus
- „Über Unquarantine"-Dialog mit Versionsnummer
- Automatische Update-Prüfung beim Start via GitHub Releases API
- Menüpunkt „Auf Updates prüfen…" für manuelle Prüfung
