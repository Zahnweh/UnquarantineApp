#!/bin/bash
set -e

echo "Building UnquarantineApp..."
swift build -c release

APP_BUNDLE="Unquarantine.app"
DMG_RW="Unquarantine_rw.dmg"
DMG_NAME="Unquarantine.dmg"
MOUNT="/Volumes/Unquarantine_build"

# --- .app bundle ---
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp .build/release/UnquarantineApp "$APP_BUNDLE/Contents/MacOS/Unquarantine"
cp UnQuarantine.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Unquarantine</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>de.extragroup.unquarantine</string>
    <key>CFBundleName</key>
    <string>Unquarantine</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# --- DMG ---
rm -f "$DMG_RW" "$DMG_NAME"

# Schritt 1: beschreibbares DMG anlegen
hdiutil create -size 100m -volname "Unquarantine" -fs HFS+ -o "$DMG_RW"

# Schritt 2: mounten
hdiutil attach -readwrite -noverify -noautoopen -mountpoint "$MOUNT" "$DMG_RW"

# Schritt 3: Inhalte kopieren
ditto "$APP_BUNDLE" "$MOUNT/$APP_BUNDLE"
ln -s /Applications "$MOUNT/Applications"
cp UnQuarantine.icns "$MOUNT/.VolumeIcon.icns"

# Schritt 4: unmounten
hdiutil detach "$MOUNT"

# Schritt 5: in komprimiertes read-only DMG konvertieren
hdiutil convert "$DMG_RW" -format UDZO -o "$DMG_NAME"
rm -f "$DMG_RW"

echo "✓ ${DMG_NAME} erfolgreich erstellt"
