#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_NAME="BatteryInfoMac"
INSTALL_PATH="/Applications/${APP_NAME}.app"

echo "=== BatteryInfoMac Installer ==="

if [[ ! -d "${PROJECT_DIR}/${APP_NAME}.app" ]]; then
    echo "Building ${APP_NAME}.app from source..."
    "${SCRIPT_DIR}/build_app.sh"
fi

echo "Stopping any running ${APP_NAME} instance..."
killall "${APP_NAME}" 2>/dev/null || true

echo "Installing to ${INSTALL_PATH}..."
rm -rf "${INSTALL_PATH}"
cp -R "${PROJECT_DIR}/${APP_NAME}.app" "${INSTALL_PATH}"
xattr -dr com.apple.quarantine "${INSTALL_PATH}" 2>/dev/null || true

echo "Launching ${APP_NAME}..."
open "${INSTALL_PATH}"

echo "Done! ${APP_NAME} is now installed in /Applications and running in your menu bar."
