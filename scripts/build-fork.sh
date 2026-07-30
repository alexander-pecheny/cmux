#!/usr/bin/env bash
# Package the personal fork build (bundle id com.cmuxterm.app.pecheny-fork) into dist/.
# Installing is left to the caller: the app being replaced usually hosts the shell running this.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="cmux-pecheny-fork"
BUNDLE_ID="com.cmuxterm.app.pecheny-fork"
DERIVED="/tmp/cmux-fork-rel"
DIST="dist/${APP_NAME}.app"

echo "Building ${APP_NAME} from $(git rev-parse --abbrev-ref HEAD) ($(git rev-parse --short HEAD))"

xcodebuild -project GhosttyTabs.xcodeproj -scheme cmux -configuration Release \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" build

rm -rf "$DIST"
mkdir -p dist
cp -R "$DERIVED/Build/Products/Release/cmux.app" "$DIST"

for key in CFBundleName CFBundleDisplayName; do
  /usr/libexec/PlistBuddy -c "Set :${key} ${APP_NAME}" "$DIST/Contents/Info.plist"
done

codesign --force --deep --sign - "$DIST"

cat <<EOF

Built $DIST

To install (quits the running app, which may host your terminal):
  osascript -e 'quit app "${APP_NAME}"' && rm -rf "/Applications/${APP_NAME}.app" \\
    && cp -R "$PWD/$DIST" /Applications/ && open "/Applications/${APP_NAME}.app"
EOF
