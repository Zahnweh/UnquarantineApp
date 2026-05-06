#!/bin/bash
set -e

echo "Building UnquarantineApp..."
swift build -c release

APP_BUNDLE="Unquarantine.app"
DMG_NAME="Unquarantine.dmg"
STAGING=".dmg_staging"

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
rm -rf "$STAGING" "$DMG_NAME"
mkdir -p "$STAGING"

cp -r "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
cp UnQuarantine.icns "$STAGING/.VolumeIcon.icns"

hdiutil create \
    -volname "Unquarantine" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_NAME"

rm -rf "$STAGING"

echo "✓ ${DMG_NAME} erfolgreich erstellt"
