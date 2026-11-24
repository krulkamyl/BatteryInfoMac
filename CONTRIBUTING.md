# Contributing to BatteryInfoMac

Contributions are very welcome! Whether you want to add a new language, support another Bluetooth device quirk, improve the UI, or fix a bug, thank you for helping make BatteryInfoMac better.

## Adding a New Language

1. Open `Sources/BatteryInfoMac/Localization.swift`.
2. Add your language code to `AppLanguage` and `ResolvedLanguage`.
3. Add translations to `L10n` helper methods.
4. Add a localized `InfoPlist.strings` block in `scripts/build_app.sh` so the macOS Bluetooth permission prompt is also translated.
5. Run `./scripts/build_app.sh` and test switching to your language in **Settings → Language**.

## Building Locally

```bash
./scripts/build_app.sh
open BatteryInfoMac.app
```

To build a universal `.dmg` installer:

```bash
./scripts/create_dmg.sh
```

## Pull Request Guidelines

- Keep changes focused and clean.
- Test on macOS 14+ with both Classic Bluetooth (e.g. Apple Magic accessories / AirPods) and BLE devices (e.g. Logitech MX / Keychron) when changing scanner logic.
- Ensure no non-Bluetooth devices (MacBook internal battery, USB peripherals) leak into the menu bar.
