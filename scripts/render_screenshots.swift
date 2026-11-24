import AppKit
import SwiftUI

@main
@MainActor
enum ScreenshotGenerator {
    static func main() {
        let args = CommandLine.arguments
        let outDir = args.count > 1 ? args[1] : "docs/screenshots"
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        let sampleLive: [LiveBluetoothDevice] = [
            LiveBluetoothDevice(
                id: "d4:99:d7:3b:5a:8e",
                name: "MX Keys Mini",
                address: "D4:99:D7:3B:5A:8E",
                isConnected: true,
                minorType: "Keyboard",
                hidUsage: 6,
                battery: BatteryDetails(main: 25)
            ),
            LiveBluetoothDevice(
                id: "d5:43:ad:b2:43:82",
                name: "MX Master 4",
                address: "D5:43:AD:B2:43:82",
                isConnected: true,
                minorType: "Mouse",
                hidUsage: 2,
                battery: BatteryDetails(main: 40)
            ),
            LiveBluetoothDevice(
                id: "d4:57:63:5d:37:9f",
                name: "Magic Trackpad",
                address: "D4:57:63:5D:37:9F",
                isConnected: true,
                minorType: "Trackpad",
                hidUsage: nil,
                battery: BatteryDetails(main: 90)
            ),
            LiveBluetoothDevice(
                id: "bc:80:4e:bd:42:c3",
                name: "AirPods Pro",
                address: "BC:80:4E:BD:42:C3",
                isConnected: true,
                minorType: "Headphones",
                hidUsage: nil,
                battery: BatteryDetails(main: nil, left: 83, right: 80, caseLevel: 79)
            ),
            LiveBluetoothDevice(
                id: "08:95:42:e8:62:36",
                name: "Magic Keyboard",
                address: "08:95:42:E8:62:36",
                isConnected: false,
                minorType: "Keyboard",
                hidUsage: 6,
                battery: BatteryDetails()
            ),
            LiveBluetoothDevice(
                id: "90:7a:58:ed:9f:98",
                name: "Sony WH-1000XM5",
                address: "90:7A:58:ED:9F:98",
                isConnected: false,
                minorType: "Headphones",
                hidUsage: nil,
                battery: BatteryDetails()
            )
        ]

        let sampleConfigs: [DeviceConfig] = [
            DeviceConfig(
                matchAddress: "D4:99:D7:3B:5A:8E",
                matchName: "MX Keys Mini",
                customName: "",
                symbol: .keyboard,
                showInMenuBar: true,
                showLabelInMenuBar: false,
                lowBatteryThreshold: 25,
                sortOrder: 0,
                isUserConfigured: true
            ),
            DeviceConfig(
                matchAddress: "D5:43:AD:B2:43:82",
                matchName: "MX Master 4",
                customName: "",
                symbol: .mouse,
                showInMenuBar: true,
                showLabelInMenuBar: false,
                lowBatteryThreshold: nil,
                sortOrder: 1,
                isUserConfigured: true
            ),
            DeviceConfig(
                matchAddress: "D4:57:63:5D:37:9F",
                matchName: "Magic Trackpad",
                customName: "",
                symbol: .trackpad,
                showInMenuBar: true,
                showLabelInMenuBar: false,
                lowBatteryThreshold: nil,
                sortOrder: 2,
                isUserConfigured: true
            ),
            DeviceConfig(
                matchAddress: "BC:80:4E:BD:42:C3",
                matchName: "AirPods Pro",
                customName: "",
                symbol: .airpodsPro,
                showInMenuBar: true,
                showLabelInMenuBar: false,
                lowBatteryThreshold: nil,
                sortOrder: 3,
                isUserConfigured: true
            )
        ]

        var enSettings = AppSettings()
        enSettings.language = .en
        enSettings.colorizeLowBattery = true
        enSettings.lowBatteryThreshold = 25

        let storeEN = BluetoothBatteryStore(
            previewLiveDevices: sampleLive,
            configs: sampleConfigs,
            settings: enSettings
        )

        // 1. Hero Menu Bar + Popover Showcase (Dark macOS wallpaper card)
        let heroView = HeroShowcaseView(store: storeEN)
        renderSwiftUI(view: heroView, size: CGSize(width: 920, height: 615), appearance: .darkAqua, to: "\(outDir)/showcase.png")

        // 2. Popover: Devices list (English, Dark Mode)
        let devicesCard = PopoverFrame(isDark: true) {
            DeviceListView(
                store: storeEN,
                onAdd: {},
                onEdit: { _ in },
                onOpenSettings: {},
                onQuit: {}
            )
        }
        renderSwiftUI(view: devicesCard, size: CGSize(width: 400, height: 555), appearance: .darkAqua, to: "\(outDir)/popover-devices.png")

        // 3. Popover: Edit Device & Symbol Picker (English, Light Mode)
        let editCard = PopoverFrame(isDark: false) {
            EditDeviceView(
                initialConfig: sampleConfigs[0],
                isNew: false,
                language: .en,
                globalThreshold: 20,
                onSave: { _ in },
                onDelete: {},
                onCancel: {}
            )
        }
        renderSwiftUI(view: editCard, size: CGSize(width: 400, height: 555), appearance: .aqua, to: "\(outDir)/popover-edit.png")

        // 4. Popover: Settings & Multi-language (English, Dark Mode)
        let settingsCard = PopoverFrame(isDark: true) {
            SettingsView(store: storeEN, onBack: {})
        }
        renderSwiftUI(view: settingsCard, size: CGSize(width: 400, height: 555), appearance: .darkAqua, to: "\(outDir)/popover-settings.png")

        print("Screenshots generated in \(outDir)")
    }

    static func renderSwiftUI<V: View>(
        view: V,
        size: CGSize,
        appearance name: NSAppearance.Name,
        to path: String
    ) {
        let appearance = NSAppearance(named: name)!
        let hosting = NSHostingView(rootView: view.environment(\.colorScheme, name == .darkAqua ? .dark : .light))
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.appearance = appearance

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = appearance
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()

        let scale: CGFloat = 2.0
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * scale),
            pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            fputs("Failed to create bitmap rep for \(path)\n", stderr)
            return
        }
        rep.size = size

        appearance.performAsCurrentDrawingAppearance {
            hosting.cacheDisplay(in: hosting.bounds, to: rep)
        }

        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}

private struct PopoverFrame<Content: View>: View {
    let isDark: Bool
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.08, green: 0.14, blue: 0.28), Color(red: 0.05, green: 0.08, blue: 0.16)]
                    : [Color(red: 0.86, green: 0.92, blue: 0.99), Color(red: 0.93, green: 0.96, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            content
                .frame(width: 360, height: 515)
                .background(isDark ? Color(white: 0.14) : Color(white: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(isDark ? 0.18 : 0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isDark ? 0.45 : 0.18), radius: 18, y: 8)
        }
    }
}

private struct HeroShowcaseView: View {
    @ObservedObject var store: BluetoothBatteryStore

    var body: some View {
        ZStack(alignment: .top) {
            // macOS Sequoia-style abstract wallpaper backdrop
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.13, blue: 0.30),
                    Color(red: 0.08, green: 0.24, blue: 0.46),
                    Color(red: 0.06, green: 0.14, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.cyan.opacity(0.24), Color.cyan.opacity(0.0)],
                center: UnitPoint(x: 0.22, y: 0.58),
                startRadius: 10,
                endRadius: 340
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.32), Color.blue.opacity(0.0)],
                center: UnitPoint(x: 0.78, y: 0.62),
                startRadius: 10,
                endRadius: 360
            )

            VStack(spacing: 0) {
                // Simulated macOS Top Menu Bar
                HStack(spacing: 14) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Finder").font(.system(size: 12.5, weight: .semibold))
                    Text("File").font(.system(size: 12.5))
                    Text("Edit").font(.system(size: 12.5))
                    Text("View").font(.system(size: 12.5))

                    Spacer()

                    // Highlighted BatteryInfoMac Menu Bar Widget
                    HStack(spacing: 11) {
                        HStack(spacing: 3) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 12.5, weight: .medium))
                            Text("25%")
                                .font(.system(size: 12, weight: .medium).monospacedDigit())
                        }
                        .foregroundStyle(.orange)

                        HStack(spacing: 3) {
                            Image(systemName: "computermouse")
                                .font(.system(size: 12.5, weight: .medium))
                            Text("40%")
                                .font(.system(size: 12, weight: .medium).monospacedDigit())
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "rectangle.and.hand.point.up.left.filled")
                                .font(.system(size: 12.5, weight: .medium))
                            Text("90%")
                                .font(.system(size: 12, weight: .medium).monospacedDigit())
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "airpodspro")
                                .font(.system(size: 12.5, weight: .medium))
                            Text("80%")
                                .font(.system(size: 12, weight: .medium).monospacedDigit())
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.cyan.opacity(0.65), lineWidth: 1)
                    )

                    Image(systemName: "wifi").font(.system(size: 12))
                    Image(systemName: "battery.100percent").font(.system(size: 13))
                    Image(systemName: "magnifyingglass").font(.system(size: 12))
                    Text("Tue 24 Nov  13:30")
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 30)
                .background(Color.black.opacity(0.36))

                // Content area: Title & highlights on left, live Popover anchored under menu bar on right
                HStack(alignment: .top, spacing: 36) {
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer().frame(height: 50)

                        HStack(spacing: 10) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.cyan)
                            Text("BatteryInfoMac")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text("Bluetooth battery levels\nright in your macOS menu bar.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineSpacing(4)

                        VStack(alignment: .leading, spacing: 10) {
                            FeatureBullet(icon: "checkmark.circle.fill", text: "Classic Bluetooth + BLE GATT (Logitech MX, Keychron, AirPods, Apple Magic)")
                            FeatureBullet(icon: "eye.slash.fill", text: "Automatically hides disconnected devices from the top bar")
                            FeatureBullet(icon: "slider.horizontal.3", text: "17 custom SF Symbols, ordering, low-battery color alerts")
                            FeatureBullet(icon: "globe", text: "8 languages built in (EN, PL, DE, ES, FR, IT, UK, JA)")
                        }
                        .padding(.top, 8)

                        Spacer()
                    }
                    .frame(maxWidth: 420, alignment: .leading)
                    .padding(.leading, 38)

                    VStack(spacing: 0) {
                        // Popover caret arrow
                        Triangle()
                            .fill(Color(white: 0.14))
                            .frame(width: 18, height: 9)
                            .offset(x: -10)

                        DeviceListView(
                            store: store,
                            onAdd: {},
                            onEdit: { _ in },
                            onOpenSettings: {},
                            onQuit: {}
                        )
                        .frame(width: 360, height: 515)
                        .background(Color(white: 0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.55), radius: 24, y: 12)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 32)
                }
            }
        }
    }
}

private struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.cyan)
                .frame(width: 18)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.88))
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
