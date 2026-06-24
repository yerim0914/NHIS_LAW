#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPORT_METHOD="${1:-app-store}"
BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"

case "$EXPORT_METHOD" in
  app-store|ad-hoc|development|enterprise)
    ;;
  *)
    echo "Unsupported export method: $EXPORT_METHOD"
    echo "Usage: scripts/build_ios_ipa.sh [app-store|ad-hoc|development|enterprise]"
    exit 64
    ;;
esac

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is not installed or not available in PATH."
  exit 69
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode command line tools are not configured."
  echo "Install Xcode, then run: sudo xcode-select --switch /Applications/Xcode.app"
  exit 69
fi

EXPORT_OPTIONS="$ROOT_DIR/ios/export_options/$EXPORT_METHOD.plist"
if [[ ! -f "$EXPORT_OPTIONS" ]]; then
  EXPORT_OPTIONS="$ROOT_DIR/build/ios_export_options/$EXPORT_METHOD.plist"
  mkdir -p "$(dirname "$EXPORT_OPTIONS")"
  cat >"$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>$EXPORT_METHOD</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
</dict>
</plist>
PLIST
fi

cd "$ROOT_DIR"

flutter pub get

BUILD_ARGS=(ipa --release --export-options-plist="$EXPORT_OPTIONS")
if [[ -n "$BUILD_NAME" ]]; then
  BUILD_ARGS+=(--build-name "$BUILD_NAME")
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  BUILD_ARGS+=(--build-number "$BUILD_NUMBER")
fi

flutter build "${BUILD_ARGS[@]}"

echo
echo "IPA output:"
find "$ROOT_DIR/build/ios/ipa" -maxdepth 1 -name "*.ipa" -print
