# Unquarantine

Kleine native macOS-App zum Entfernen von Quarantäne-Flags. Dateien oder Ordner per Drag & Drop auf die Drop-Zone ziehen — fertig.

## Features

- Entfernt `com.apple.quarantine` per `xattr`
- Optional: Herkunfts-Metadaten entfernen (`kMDItemWhereFroms`, `kMDItemDownloadedDate`)
- Optional: Archiv nach dem Entfernen direkt entpacken (Standard-System-App)
- Rekursiver Modus für Ordner und entpackte Archive
- Automatische Update-Prüfung beim Start

## Installation

1. Neueste Version von der [Releases-Seite](https://github.com/Zahnweh/UnquarantineApp/releases) herunterladen
2. DMG öffnen
3. `Unquarantine.app` in den Programme-Ordner ziehen

## Verwendung

App starten, Dateien oder Ordner auf die Drop-Zone ziehen. Die gewünschten Optionen per Checkbox aktivieren:

| Option | Beschreibung |
|---|---|
| Rekursiv | Verarbeitet alle Dateien innerhalb von Ordnern |
| Herkunfts-Metadaten entfernen | Entfernt Download-URL und -Datum |
| Archiv entpacken | Öffnet das Archiv nach der Verarbeitung mit der Standard-App |

## Aus dem Quellcode bauen

Xcode Command Line Tools werden benötigt.

```bash
git clone https://github.com/Zahnweh/UnquarantineApp.git
cd UnquarantineApp
./build.sh
```

Das fertige `Unquarantine.dmg` liegt anschließend im Projektverzeichnis.

## Release erstellen

```bash
git tag v1.1
git push origin v1.1
```

GitHub Actions baut automatisch das DMG und erstellt den Release.

## Systemvoraussetzungen

macOS 13 (Ventura) oder neuer
