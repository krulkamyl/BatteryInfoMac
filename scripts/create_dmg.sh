#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_NAME="BatteryInfoMac"
APP_VERSION="${APP_VERSION:-1.1.0}"
BUILD_ARCH="${BUILD_ARCH:-universal}"

# Build app bundle first
APP_VERSION="${APP_VERSION}" BUILD_ARCH="${BUILD_ARCH}" "${SCRIPT_DIR}/build_app.sh"

DIST_DIR="${PROJECT_DIR}/dist"
STAGE_DIR="/tmp/${APP_NAME}-dmg-stage"
DMG_NAME="${APP_NAME}-${APP_VERSION}-${BUILD_ARCH}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

mkdir -p "${DIST_DIR}"
rm -rf "${STAGE_DIR}" "${DMG_PATH}" "${DMG_PATH}.sha256"
mkdir -p "${STAGE_DIR}"

cp -R "${PROJECT_DIR}/${APP_NAME}.app" "${STAGE_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGE_DIR}/Applications"

echo "Creating macOS DMG installer: ${DMG_PATH}..."
hdiutil create \
    -volname "${APP_NAME} ${APP_VERSION}" \
    -srcfolder "${STAGE_DIR}" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_PATH}"

rm -rf "${STAGE_DIR}"

# Generate SHA-256 checksum for GitHub Releases
(
    cd "${DIST_DIR}"
    shasum -a 256 "${DMG_NAME}" > "${DMG_NAME}.sha256"
)

echo ""
echo "Installer created successfully:"
echo "  DMG:      ${DMG_PATH}"
echo "  Checksum: ${DMG_PATH}.sha256"
cat "${DMG_PATH}.sha256"
