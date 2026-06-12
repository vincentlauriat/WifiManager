#!/usr/bin/env bash
# Build Release, codesign, notarise, DMG, Sparkle-sign, appcast.xml
# Usage: ./Scripts/release.sh <version>
set -euo pipefail

VERSION="${1:?Usage: ./Scripts/release.sh <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! grep -q "MARKETING_VERSION: \"$VERSION\"" project.yml; then
  echo "✗ MARKETING_VERSION dans project.yml ne correspond pas à $VERSION" >&2
  grep "MARKETING_VERSION" project.yml | sed 's/^/    /' >&2
  exit 1
fi

SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Vincent LAURIAT (KFLACS69T9)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AppliMacVincentGithub}"

echo "→ xcodegen generate"
xcodegen generate >/dev/null
echo "→ xcodebuild Release"
xcodebuild -project WifiManager.xcodeproj \
  -scheme WifiManager -configuration Release \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -5

APP="$ROOT/build/Build/Products/Release/WifiManager.app"
[ -d "$APP" ] || { echo "✗ App non trouvée : $APP" >&2; exit 1; }

STAGING_DIR="$(mktemp -d)"
STAGING="$STAGING_DIR/WifiManager.app"
echo "→ Staging vers $STAGING_DIR"
ditto --norsrc --noextattr --noacl "$APP" "$STAGING"

codesign_ts() {
  local target="$1"
  for attempt in 1 2 3 4 5; do
    if codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$target" 2>&1; then
      return 0
    fi
    [ "$attempt" -lt 5 ] && { echo "  ↻ retry $attempt/5…"; sleep 5; }
  done
  echo "✗ codesign échoué après 5 tentatives : $target" >&2; return 1
}

echo "→ Codesign Sparkle nested binaries"
SPARKLE_FW="$STAGING/Contents/Frameworks/Sparkle.framework"
SPARKLE_VER="$SPARKLE_FW/Versions/B"
codesign_ts "$SPARKLE_VER/Autoupdate"
codesign_ts "$SPARKLE_VER/XPCServices/Downloader.xpc"
codesign_ts "$SPARKLE_VER/XPCServices/Installer.xpc"
codesign_ts "$SPARKLE_VER/Updater.app"
codesign_ts "$SPARKLE_FW"
echo "→ Codesign app"
codesign_ts "$STAGING"
codesign --verify --strict --deep "$STAGING"

DMG="$ROOT/WifiManager-$VERSION.dmg"
rm -f "$DMG"
DMG_VOLNAME="WifiManager $VERSION"
DMG_LAYOUT="$STAGING_DIR/dmg-layout"
mkdir -p "$DMG_LAYOUT/.background"
ditto --norsrc --noextattr --noacl "$STAGING" "$DMG_LAYOUT/WifiManager.app"
ln -s /Applications "$DMG_LAYOUT/Applications"
swift "$ROOT/Scripts/make-dmg-background.swift" "$DMG_LAYOUT/.background/background.png" >/dev/null

RW_DMG="$STAGING_DIR/temp.dmg"
hdiutil create -volname "$DMG_VOLNAME" -srcfolder "$DMG_LAYOUT" \
  -fs HFS+ -format UDRW -ov "$RW_DMG" >/dev/null

DMG_MOUNT=$(hdiutil attach -nobrowse -noverify -noautoopen "$RW_DMG" \
  | awk -F '\t' 'END {print $NF}')
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$DMG_VOLNAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 100, 740, 480}
        set view_options to the icon view options of container window
        set arrangement of view_options to not arranged
        set icon size of view_options to 128
        set background picture of view_options to file ".background:background.png"
        set position of item "WifiManager.app" of container window to {140, 200}
        set position of item "Applications" of container window to {400, 200}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT
sync
hdiutil detach "$DMG_MOUNT" -quiet
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG" >/dev/null
rm -rf "$STAGING_DIR"

echo "→ Notarisation Apple…"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

"$ROOT/Scripts/fetch-sparkle-tools.sh" >/dev/null
SPARKLE_TOOLS="$ROOT/.sparkle-tools"
SPARKLE_SIG_LINE=$("$SPARKLE_TOOLS/bin/sign_update" --account "MarkdownViewer" "$DMG")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" \
  "$ROOT/build/Build/Products/Release/WifiManager.app/Contents/Info.plist")
PUB_DATE=$(date -R)

cat > "$ROOT/appcast.xml" <<APPCAST
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>WifiManager</title>
    <link>https://raw.githubusercontent.com/vincentlauriat/WifiManager/main/appcast.xml</link>
    <description>WifiManager release feed</description>
    <language>en</language>
    <item>
      <title>v$VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/vincentlauriat/WifiManager/releases/tag/v$VERSION</sparkle:releaseNotesLink>
      <enclosure
        url="https://github.com/vincentlauriat/WifiManager/releases/download/v$VERSION/WifiManager-$VERSION.dmg"
        type="application/octet-stream"
        $SPARKLE_SIG_LINE />
    </item>
  </channel>
</rss>
APPCAST

DMG_SIZE=$(ls -lh "$DMG" | awk '{print $5}')
echo ""
echo "✅ WifiManager-$VERSION.dmg ($DMG_SIZE) — signé, notarisé, Sparkle-signé"
echo "✅ appcast.xml mis à jour pour v$VERSION"
echo ""
echo "Étapes suivantes :"
echo "  1. gh release create v$VERSION ./WifiManager-$VERSION.dmg --title \"v$VERSION\""
echo "  2. git add appcast.xml && git commit -m 'chore: appcast v$VERSION' && git push"
