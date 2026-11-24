#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SDK_PATH="$(xcrun --show-sdk-path)"
MODULE_CACHE="/tmp/BatteryInfoMac-module-cache"
OUT_BIN="/tmp/BatteryInfoMac-screenshotter"

mkdir -p "${MODULE_CACHE}" "${PROJECT_DIR}/docs/screenshots"
export CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}"

echo "Compiling screenshot renderer..."
swiftc \
    -O \
    -parse-as-library \
    -target arm64-apple-macosx14.0 \
    -sdk "${SDK_PATH}" \
    -module-cache-path "${MODULE_CACHE}" \
    -framework AppKit \
    -framework SwiftUI \
    -framework IOKit \
    -framework IOBluetooth \
    -framework CoreBluetooth \
    -framework ServiceManagement \
    "${PROJECT_DIR}/Sources/BatteryInfoMac/Models.swift" \
    "${PROJECT_DIR}/Sources/BatteryInfoMac/Localization.swift" \
    "${PROJECT_DIR}/Sources/BatteryInfoMac/CoreBluetoothBatteryReader.swift" \
    "${PROJECT_DIR}/Sources/BatteryInfoMac/BluetoothBatteryMonitor.swift" \
    "${PROJECT_DIR}/Sources/BatteryInfoMac/StatusBarRenderer.swift" \
    "${PROJECT_DIR}/Sources/BatteryInfoMac/PopoverViews.swift" \
    "${PROJECT_DIR}/scripts/render_screenshots.swift" \
    -o "${OUT_BIN}"

echo "Rendering Retina screenshots..."
"${OUT_BIN}" "${PROJECT_DIR}/docs/screenshots"
rm -f "${OUT_BIN}"
ls -lh "${PROJECT_DIR}/docs/screenshots"
