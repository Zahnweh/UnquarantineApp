# Changelog

## [1.1] – geplant

### Neu
- Menüleisten-App: kein Dock-Icon mehr, Drop-Zone als Popover (Linksklick)
- Rechtsklick auf Menüleisten-Icon: Kontextmenü mit Über, Updates, Login-Option, Beenden
- „Beim Login starten" direkt im Menü
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
