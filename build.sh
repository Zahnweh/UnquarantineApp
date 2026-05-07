#!/bin/bash
set -e

VERSION="1.4"

echo "Building Unquarantine $VERSION..."
swift build -c release

APP_BUNDLE="Unquarantine.app"
DMG_RW="Unquarantine_rw.dmg"
DMG_NAME="Unquarantine.dmg"
MOUNT=$(mktemp -d)

# --- .app bundle ---
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp .build/release/UnquarantineApp "$APP_BUNDLE/Contents/MacOS/Unquarantine"
cp UnQuarantine.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp icon_tray_Template.png "$APP_BUNDLE/Contents/Resources/icon_tray_Template.png"

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
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
    <string>${VERSION}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Unquarantine</string>
            </dict>
            <key>NSMessage</key>
            <string>unquarantineFiles</string>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.item</string>
            </array>
        </dict>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Unquarantine + Entpacken</string>
            </dict>
            <key>NSMessage</key>
            <string>unquarantineAndExtract</string>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.item</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# --- DMG ---
rm -f "$DMG_RW" "$DMG_NAME"

hdiutil create -size 100m -volname "Unquarantine" -fs HFS+ -o "$DMG_RW"
hdiutil attach -readwrite -noverify -noautoopen -mountpoint "$MOUNT" "$DMG_RW"

ditto "$APP_BUNDLE" "$MOUNT/$APP_BUNDLE"
ln -s /Applications "$MOUNT/Applications"
cp UnQuarantine.icns "$MOUNT/.VolumeIcon.icns"

hdiutil detach "$MOUNT"
rmdir "$MOUNT"

hdiutil convert "$DMG_RW" -format UDZO -o "$DMG_NAME"
rm -f "$DMG_RW"
rm -rf "$APP_BUNDLE"

echo "✓ ${DMG_NAME} erfolgreich erstellt"
