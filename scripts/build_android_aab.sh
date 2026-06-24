#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is not installed or not available in PATH."
  exit 69
fi

cd "$ROOT_DIR"

if [[ ! -f android/key.properties ]]; then
  echo "Missing android/key.properties."
  echo "Create an upload keystore and copy android/key.properties.example to android/key.properties."
  exit 66
fi

flutter pub get

BUILD_ARGS=(appbundle --release)
if [[ -n "$BUILD_NAME" ]]; then
  BUILD_ARGS+=(--build-name "$BUILD_NAME")
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  BUILD_ARGS+=(--build-number "$BUILD_NUMBER")
fi

flutter build "${BUILD_ARGS[@]}"

echo
echo "AAB output:"
find "$ROOT_DIR/build/app/outputs/bundle/release" -maxdepth 1 -name "*.aab" -print
