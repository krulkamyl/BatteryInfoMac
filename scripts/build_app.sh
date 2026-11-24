#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_NAME="BatteryInfoMac"
APP_VERSION="${APP_VERSION:-1.1.0}"
BUILD_ARCH="${BUILD_ARCH:-universal}" # "universal", "arm64", or "x86_64"

APP_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
BUILD_DIR="${PROJECT_DIR}/.build/release"
MODULE_CACHE="/tmp/BatteryInfoMac-module-cache"
SDK_PATH="$(xcrun --show-sdk-path)"

mkdir -p "${BUILD_DIR}" "${MODULE_CACHE}"
export CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}"

compile_arch() {
    local arch="$1"
    local out_bin="$2"
    echo "Compiling ${APP_NAME} for ${arch}..."
    swiftc \
        -O \
        -parse-as-library \
        -target "${arch}-apple-macosx14.0" \
        -sdk "${SDK_PATH}" \
        -module-cache-path "${MODULE_CACHE}" \
        -framework AppKit \
        -framework SwiftUI \
        -framework IOKit \
        -framework IOBluetooth \
        -framework CoreBluetooth \
        -framework ServiceManagement \
        "${PROJECT_DIR}"/Sources/BatteryInfoMac/*.swift \
        -o "${out_bin}"
}

BIN_PATH="${BUILD_DIR}/${APP_NAME}"
if [[ "${BUILD_ARCH}" == "universal" ]]; then
    compile_arch "arm64" "${BUILD_DIR}/${APP_NAME}-arm64"
    compile_arch "x86_64" "${BUILD_DIR}/${APP_NAME}-x86_64"
    echo "Creating universal binary (arm64 + x86_64)..."
    lipo -create \
        "${BUILD_DIR}/${APP_NAME}-arm64" \
        "${BUILD_DIR}/${APP_NAME}-x86_64" \
        -output "${BIN_PATH}"
else
    compile_arch "${BUILD_ARCH}" "${BIN_PATH}"
fi

echo "Packaging ${APP_BUNDLE} (v${APP_VERSION})..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
cp "${BIN_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy AppIcon.icns if present
if [[ -f "${PROJECT_DIR}/Assets/AppIcon.icns" ]]; then
    cp "${PROJECT_DIR}/Assets/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Generate localized InfoPlist.strings for macOS permission dialogs
write_lproj() {
    local code="$1"
    local display_name="$2"
    local bt_usage="$3"
    mkdir -p "${RESOURCES_DIR}/${code}.lproj"
    cat > "${RESOURCES_DIR}/${code}.lproj/InfoPlist.strings" << EOF
"CFBundleDisplayName" = "${display_name}";
"NSBluetoothAlwaysUsageDescription" = "${bt_usage}";
EOF
}

write_lproj "en" "BatteryInfoMac" "BatteryInfoMac reads connection status and battery levels of connected Bluetooth devices to display them in your menu bar."
write_lproj "pl" "BatteryInfoMac" "Aplikacja odczytuje stan połączenia i poziom naładowania podłączonych urządzeń Bluetooth, aby wyświetlać je na pasku górnym."
write_lproj "de" "BatteryInfoMac" "BatteryInfoMac liest Verbindungsstatus und Akkustand verbundener Bluetooth-Geräte aus, um sie in der Menüleiste anzuzeigen."
write_lproj "es" "BatteryInfoMac" "BatteryInfoMac lee el estado de conexión y el nivel de batería de tus dispositivos Bluetooth para mostrarlos en la barra superior."
write_lproj "fr" "BatteryInfoMac" "BatteryInfoMac lit l'état de connexion et le niveau de batterie de vos appareils Bluetooth pour les afficher dans la barre des menus."
write_lproj "it" "BatteryInfoMac" "BatteryInfoMac legge lo stato di connessione e il livello della batteria dei dispositivi Bluetooth per mostrarli nella barra dei menu."
write_lproj "uk" "BatteryInfoMac" "BatteryInfoMac зчитує стан підключення та рівень заряду підключених пристроїв Bluetooth для відображення на верхній панелі."
write_lproj "ja" "BatteryInfoMac" "BatteryInfoMac は接続中の Bluetooth デバイスのバッテリー残量を読み取り、メニューバーに表示します。"

cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>BatteryInfoMac</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.batteryinfomac.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>pl</string>
        <string>de</string>
        <string>es</string>
        <string>fr</string>
        <string>it</string>
        <string>uk</string>
        <string>ja</string>
    </array>
    <key>CFBundleName</key>
    <string>BatteryInfoMac</string>
    <key>CFBundleDisplayName</key>
    <string>BatteryInfoMac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>BatteryInfoMac reads connection status and battery levels of connected Bluetooth devices to display them in your menu bar.</string>
</dict>
</plist>
EOF

echo "Ad-hoc signing ${APP_BUNDLE}..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Built successfully: ${APP_BUNDLE}"
file "${MACOS_DIR}/${APP_NAME}"
