#!/usr/bin/env bash
set -euo pipefail
[[ -f .env ]] && source .env
: "${SCHEME:=faynosyncSparkleExample}"
: "${CONFIG:=Release}"
: "${BUILD_DIR:=build}"
: "${DEVELOPER_ID:=}"
: "${DEVELOPMENT_TEAM:=}"
: "${CHANNEL:=}"
: "${ARCH:=}"

case "$ARCH" in
	amd64|x86_64) XCARCH=x86_64 ;;
	arm64) XCARCH=arm64 ;;
	"") XCARCH="" ;;
	*) echo "unknown ARCH: $ARCH (use arm64|amd64)" >&2; exit 1 ;;
esac

xcodegen generate

xcodebuild \
	-project faynosyncSparkleExample.xcodeproj \
	-scheme "$SCHEME" \
	-configuration "$CONFIG" \
	-derivedDataPath "$BUILD_DIR/dd" \
	${XCARCH:+ARCHS="$XCARCH" ONLY_ACTIVE_ARCH=NO} \
	${CHANNEL:+FAYNOSYNC_CHANNEL="$CHANNEL"} \
	${DEVELOPER_ID:+CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$DEVELOPER_ID"} \
	${DEVELOPMENT_TEAM:+DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"} \
	build

APP="$BUILD_DIR/dd/Build/Products/$CONFIG/$SCHEME.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
CHANNEL=$(/usr/libexec/PlistBuddy -c "Print FaynoSyncChannel" "$APP/Contents/Info.plist" 2>/dev/null || echo nightly)
PLATFORM=darwin
case "$(lipo -archs "$APP/Contents/MacOS/$SCHEME" 2>/dev/null)" in
	*arm64*) ARCH=arm64 ;;
	*) ARCH=amd64 ;;
esac

DEST="$BUILD_DIR/dist/$PLATFORM/$ARCH/$CHANNEL"
mkdir -p "$DEST"
ditto -c -k --keepParent "$APP" "$DEST/$SCHEME-$VERSION.zip"
echo "Built $APP"
echo "Zipped to $DEST/$SCHEME-$VERSION.zip"
