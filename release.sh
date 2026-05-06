#!/bin/bash
set -e

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Verwendung: ./release.sh <version>  (z.B. ./release.sh 1.1)"
    exit 1
fi

# Versionsnummer in Quellcode eintragen
sed -i '' "s/static let version = \"[^\"]*\"/static let version = \"$VERSION\"/" \
    Sources/UnquarantineApp/Updater.swift

sed -i '' "s/^VERSION=.*/VERSION=\"$VERSION\"/" build.sh

# Commit + Tag + Push
git add Sources/UnquarantineApp/Updater.swift build.sh
git commit -m "Release $VERSION"
git tag "v$VERSION"
git push origin main "v$VERSION"

echo "✓ Release v$VERSION angestoßen – GitHub Actions baut jetzt das DMG."
echo "  Status: https://github.com/Zahnweh/UnquarantineApp/actions"
