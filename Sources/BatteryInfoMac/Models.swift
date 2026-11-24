import Foundation
import SwiftUI

// MARK: - Available SF Symbols for Bluetooth Devices

enum DeviceSymbol: String, CaseIterable, Codable, Identifiable, Sendable {
    case keyboard = "keyboard"
    case keyboardFill = "keyboard.fill"
    case mouse = "computermouse"
    case mouseFill = "computermouse.fill"
    case trackpad = "rectangle.and.hand.point.up.left.filled"
    case headphones = "headphones"
    case airpods = "airpods"
    case airpodsPro = "airpodspro"
    case airpodsMax = "airpodsmax"
    case earbuds = "earbuds"
    case speaker = "hifispeaker.fill"
    case gamepad = "gamecontroller.fill"
    case pencil = "applepencil"
    case watch = "applewatch"
    case phone = "iphone"
    case tablet = "ipad"
    case generic = "dot.radiowaves.left.and.right"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .keyboard: return "Klawiatura"
        case .keyboardFill: return "Klawiatura (pełna)"
        case .mouse: return "Myszka"
        case .mouseFill: return "Myszka (pełna)"
        case .trackpad: return "Gładzik"
        case .headphones: return "Słuchawki"
        case .airpods: return "AirPods"
        case .airpodsPro: return "AirPods Pro"
        case .airpodsMax: return "AirPods Max"
        case .earbuds: return "Słuchawki dokanałowe"
        case .speaker: return "Głośnik"
        case .gamepad: return "Kontroler"
        case .pencil: return "Rysik"
        case .watch: return "Zegarek"
        case .phone: return "Telefon"
        case .tablet: return "Tablet"
        case .generic: return "Bluetooth"
        }
    }

    static func guess(name: String, minorType: String? = nil, hidUsage: Int? = nil) -> DeviceSymbol {
        let combined = "\(name) \(minorType ?? "")".lowercased()

        if combined.contains("airpods max") { return .airpodsMax }
        if combined.contains("airpods pro") { return .airpodsPro }
        if combined.contains("airpods") { return .airpods }
        if combined.contains("earbud") || combined.contains("buds") || combined.contains("beats fit") {
            return .earbuds
        }
        if combined.contains("keyboard") || combined.contains("klawiatura") || combined.contains("keychron")
            || combined.contains("mx keys") || combined.contains("nuphy") || combined.contains("hhkb")
            || hidUsage == 6 {
            return .keyboard
        }
        if combined.contains("trackpad") || combined.contains("gładzik") {
            return .trackpad
        }
        if combined.contains("mouse") || combined.contains("mysz") || combined.contains("mx master")
            || combined.contains("mx anywhere") || combined.contains("mx vertical") || combined.contains("lift")
            || combined.contains("deathadder") || combined.contains("viper") || combined.contains("basilisk")
            || combined.contains("logi") && combined.contains("pointer")
            || hidUsage == 2 {
            return .mouse
        }
        if combined.contains("headphone") || combined.contains("headset") || combined.contains("słuchawki")
            || combined.contains("wh-1000") || combined.contains("wf-1000") || combined.contains("bose")
            || combined.contains("sennheiser") || combined.contains("beats") || combined.contains("jabra")
            || combined.contains("momentum") || combined.contains("qc45") || combined.contains("quietcomfort") {
            return .headphones
        }
        if combined.contains("speaker") || combined.contains("głośnik") || combined.contains("jbl")
            || combined.contains("marshall") || combined.contains("sonos") || combined.contains("soundlink")
            || combined.contains("boom") {
            return .speaker
        }
        if combined.contains("gamepad") || combined.contains("controller") || combined.contains("xbox")
            || combined.contains("dualshock") || combined.contains("dualsense") || combined.contains("joy-con")
            || combined.contains("pro controller") || combined.contains("8bitdo") || hidUsage == 5 || hidUsage == 4 {
            return .gamepad
        }
        if combined.contains("pencil") || combined.contains("stylus") || combined.contains("wacom") || combined.contains("pen") {
            return .pencil
        }
        if combined.contains("watch") { return .watch }
        if combined.contains("iphone") || combined.contains("phone") { return .phone }
        if combined.contains("ipad") || combined.contains("tablet") { return .tablet }

        return .generic
    }
}

// MARK: - Live Detected Bluetooth Device

struct BatteryDetails: Equatable, Sendable {
    var main: Int?
    var left: Int?
    var right: Int?
    var caseLevel: Int?
    var isCharging: Bool = false

    /// Primary percentage to display in the menu bar.
    var effectivePercent: Int? {
        if let main { return clamp(main) }
        let buds = [left, right].compactMap { $0 }
        if !buds.isEmpty {
            return clamp(buds.min()!)
        }
        if let caseLevel { return clamp(caseLevel) }
        return nil
    }

    var hasAnyBatteryInfo: Bool {
        main != nil || left != nil || right != nil || caseLevel != nil
    }

    private func clamp(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }
}

struct LiveBluetoothDevice: Identifiable, Equatable, Sendable {
    let id: String              // Normalized MAC address if available, else normalized name
    var name: String
    var address: String?        // Formatted MAC address (e.g. AA:BB:CC:DD:EE:FF)
    var isConnected: Bool
    var minorType: String?
    var hidUsage: Int?
    var battery: BatteryDetails

    var normalizedAddress: String? {
        address.map(BluetoothKey.normalizeAddress)
    }

    var normalizedName: String {
        BluetoothKey.normalizeName(name)
    }
}

enum BluetoothKey {
    static func normalizeAddress(_ raw: String) -> String {
        raw.lowercased()
            .replacingOccurrences(of: "-", with: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func formatAddress(_ raw: String) -> String {
        let cleaned = raw.uppercased()
            .replacingOccurrences(of: "-", with: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }

    static func normalizeName(_ raw: String) -> String {
        raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Persisted User Device Configuration

struct DeviceConfig: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    /// Bluetooth MAC address (preferred matcher)
    var matchAddress: String?
    /// Bluetooth device name (fallback matcher or manual matcher)
    var matchName: String
    /// Custom display label (optional; used in popover and optional menu bar label)
    var customName: String
    /// Chosen SF Symbol
    var symbol: DeviceSymbol
    /// Whether this device should appear in the top menu bar when connected
    var showInMenuBar: Bool = true
    /// Optional short label next to icon in menu bar
    var showLabelInMenuBar: Bool = false
    /// Low-battery highlight threshold for this device (nil = use global)
    var lowBatteryThreshold: Int?
    /// Ordering index in menu bar
    var sortOrder: Int = 0
    /// Whether the user explicitly created/edited this config
    var isUserConfigured: Bool = true

    var displayTitle: String {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? matchName : trimmed
    }

    func matches(_ live: LiveBluetoothDevice) -> Bool {
        if let cfgAddr = matchAddress.map(BluetoothKey.normalizeAddress), !cfgAddr.isEmpty,
           let liveAddr = live.normalizedAddress, !liveAddr.isEmpty {
            if cfgAddr == liveAddr { return true }
        }
        let cfgName = BluetoothKey.normalizeName(matchName)
        if !cfgName.isEmpty && cfgName == live.normalizedName {
            return true
        }
        return false
    }
}

// MARK: - Combined View Model Item (Config + Live Status)

struct ManagedBluetoothDevice: Identifiable, Equatable {
    let id: String
    var config: DeviceConfig?
    var live: LiveBluetoothDevice?

    var isConnected: Bool { live?.isConnected ?? false }
    var battery: BatteryDetails { live?.battery ?? BatteryDetails() }
    var batteryPercent: Int? { battery.effectivePercent }

    var displayName: String {
        if let config {
            return config.displayTitle
        }
        return live?.name ?? "Urządzenie Bluetooth"
    }

    var bluetoothName: String {
        live?.name ?? config?.matchName ?? "Nieznane"
    }

    var address: String? {
        live?.address ?? config?.matchAddress
    }

    var symbol: DeviceSymbol {
        if let config { return config.symbol }
        return DeviceSymbol.guess(
            name: live?.name ?? "",
            minorType: live?.minorType,
            hidUsage: live?.hidUsage
        )
    }

    var showInMenuBar: Bool {
        config?.showInMenuBar ?? true
    }

    var showLabelInMenuBar: Bool {
        config?.showLabelInMenuBar ?? false
    }

    var sortOrder: Int {
        config?.sortOrder ?? Int.max
    }
}

// MARK: - Global App Settings

enum MenuBarDisplayFormat: String, CaseIterable, Codable, Identifiable, Sendable {
    case iconAndPercent = "icon_percent"
    case iconAndNumber = "icon_number"
    case iconNamePercent = "icon_name_percent"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iconAndPercent: return "Symbol + 60%"
        case .iconAndNumber: return "Symbol + 60 (kompaktowy)"
        case .iconNamePercent: return "Symbol + nazwa + 60%"
        }
    }
}

enum MenuBarSpacing: String, CaseIterable, Codable, Identifiable, Sendable {
    case compact = "compact"
    case normal = "normal"
    case wide = "wide"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: return "Kompaktowy"
        case .normal: return "Normalny"
        case .wide: return "Szeroki"
        }
    }

    var points: CGFloat {
        switch self {
        case .compact: return 7
        case .normal: return 11
        case .wide: return 16
        }
    }
}

struct AppSettings: Codable, Equatable, Sendable {
    var autoShowDetectedDevices: Bool = true
    var displayFormat: MenuBarDisplayFormat = .iconAndPercent
    var itemSpacing: MenuBarSpacing = .normal
    var colorizeLowBattery: Bool = true
    var lowBatteryThreshold: Int = 20
    var refreshIntervalSeconds: Int = 30
    var showChargingBolt: Bool = true
    var launchAtLogin: Bool = false
    var language: AppLanguage = .system

    init(
        autoShowDetectedDevices: Bool = true,
        displayFormat: MenuBarDisplayFormat = .iconAndPercent,
        itemSpacing: MenuBarSpacing = .normal,
        colorizeLowBattery: Bool = true,
        lowBatteryThreshold: Int = 20,
        refreshIntervalSeconds: Int = 30,
        showChargingBolt: Bool = true,
        launchAtLogin: Bool = false,
        language: AppLanguage = .system
    ) {
        self.autoShowDetectedDevices = autoShowDetectedDevices
        self.displayFormat = displayFormat
        self.itemSpacing = itemSpacing
        self.colorizeLowBattery = colorizeLowBattery
        self.lowBatteryThreshold = lowBatteryThreshold
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.showChargingBolt = showChargingBolt
        self.launchAtLogin = launchAtLogin
        self.language = language
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        autoShowDetectedDevices = try c.decodeIfPresent(Bool.self, forKey: .autoShowDetectedDevices) ?? true
        displayFormat = try c.decodeIfPresent(MenuBarDisplayFormat.self, forKey: .displayFormat) ?? .iconAndPercent
        itemSpacing = try c.decodeIfPresent(MenuBarSpacing.self, forKey: .itemSpacing) ?? .normal
        colorizeLowBattery = try c.decodeIfPresent(Bool.self, forKey: .colorizeLowBattery) ?? true
        lowBatteryThreshold = try c.decodeIfPresent(Int.self, forKey: .lowBatteryThreshold) ?? 20
        refreshIntervalSeconds = try c.decodeIfPresent(Int.self, forKey: .refreshIntervalSeconds) ?? 30
        showChargingBolt = try c.decodeIfPresent(Bool.self, forKey: .showChargingBolt) ?? true
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
    }
}
