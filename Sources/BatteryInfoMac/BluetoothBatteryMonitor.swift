import Foundation
import IOKit
import IOKit.ps
import IOBluetooth
import AppKit
import ServiceManagement

// MARK: - Scan Output Including BLE UUID -> MAC Address Map

struct BluetoothScanResult: Sendable {
    var devices: [LiveBluetoothDevice]
    /// Maps CoreBluetooth peripheral UUID (uppercased) -> normalized Bluetooth MAC address
    var bleUUIDToAddress: [String: String]
}

// MARK: - Bluetooth-Only Battery Scanner

final class BluetoothBatteryScanner: @unchecked Sendable {

    /// Scans ONLY Bluetooth devices across IOKit HID, IOKit PowerSources, system_profiler, and IOBluetooth.
    func scan() -> BluetoothScanResult {
        var devices: [LiveBluetoothDevice] = []
        var bleUUIDToAddress: [String: String] = [:]

        // 1. system_profiler SPBluetoothDataType (authoritative for connected BT audio/AirPods/HID & paired list)
        let profilerDevices = scanSystemProfiler()
        for dev in profilerDevices {
            merge(dev, into: &devices)
        }

        // 2. IOKit HID services (fast & accurate BatteryPercent + BLE UUID -> MAC address mapping)
        let (hidDevices, uuidMap) = scanIOKitHIDBluetooth()
        bleUUIDToAddress.merge(uuidMap) { _, new in new }
        for dev in hidDevices {
            merge(dev, into: &devices)
        }

        // 3. IOKit PowerSources filtered STRICTLY to Bluetooth transport
        let psDevices = scanPowerSourcesBluetooth()
        for dev in psDevices {
            merge(dev, into: &devices)
        }

        // 4. IOBluetooth paired devices (live connection status + Classic BT battery properties)
        let pairedDevices = scanIOBluetoothPaired()
        for dev in pairedDevices {
            merge(dev, into: &devices)
        }

        devices.sort { lhs, rhs in
            if lhs.isConnected != rhs.isConnected {
                return lhs.isConnected && !rhs.isConnected
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        return BluetoothScanResult(devices: devices, bleUUIDToAddress: bleUUIDToAddress)
    }

    // MARK: - Merge Strategy

    private func merge(_ incoming: LiveBluetoothDevice, into list: inout [LiveBluetoothDevice]) {
        let matchIndex = list.firstIndex { existing in
            if let a1 = existing.normalizedAddress, let a2 = incoming.normalizedAddress,
               !a1.isEmpty, !a2.isEmpty, a1 == a2 {
                return true
            }
            if !existing.normalizedName.isEmpty && existing.normalizedName == incoming.normalizedName {
                if let a1 = existing.normalizedAddress, let a2 = incoming.normalizedAddress,
                   !a1.isEmpty, !a2.isEmpty, a1 != a2 {
                    return false
                }
                return true
            }
            return false
        }

        guard let idx = matchIndex else {
            list.append(incoming)
            return
        }

        var existing = list[idx]
        if existing.address == nil, let addr = incoming.address {
            existing.address = addr
        }
        if existing.name.isEmpty || existing.name == "Bluetooth Device" {
            existing.name = incoming.name
        }
        existing.isConnected = existing.isConnected || incoming.isConnected
        if existing.minorType == nil {
            existing.minorType = incoming.minorType
        }
        if existing.hidUsage == nil {
            existing.hidUsage = incoming.hidUsage
        }

        if existing.battery.main == nil { existing.battery.main = incoming.battery.main }
        if existing.battery.left == nil { existing.battery.left = incoming.battery.left }
        if existing.battery.right == nil { existing.battery.right = incoming.battery.right }
        if existing.battery.caseLevel == nil { existing.battery.caseLevel = incoming.battery.caseLevel }
        existing.battery.isCharging = existing.battery.isCharging || incoming.battery.isCharging

        list[idx] = existing
    }

    // MARK: - Source 1: system_profiler SPBluetoothDataType -json

    private func scanSystemProfiler() -> [LiveBluetoothDevice] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType", "-json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard !data.isEmpty,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let btArray = root["SPBluetoothDataType"] as? [[String: Any]] else {
            return []
        }

        var results: [LiveBluetoothDevice] = []

        for section in btArray {
            if let connectedList = section["device_connected"] as? [[String: Any]] {
                for entry in connectedList {
                    for (name, rawInfo) in entry {
                        guard let info = rawInfo as? [String: Any] else { continue }
                        results.append(parseProfilerDevice(name: name, info: info, isConnected: true))
                    }
                }
            }

            if let disconnectedList = section["device_not_connected"] as? [[String: Any]] {
                for entry in disconnectedList {
                    for (name, rawInfo) in entry {
                        guard let info = rawInfo as? [String: Any] else { continue }
                        results.append(parseProfilerDevice(name: name, info: info, isConnected: false))
                    }
                }
            }
        }

        return results
    }

    private func parseProfilerDevice(name: String, info: [String: Any], isConnected: Bool) -> LiveBluetoothDevice {
        let rawAddress = info["device_address"] as? String
        let formattedAddress = rawAddress.map(BluetoothKey.formatAddress)
        let minorType = info["device_minorType"] as? String

        var battery = BatteryDetails()
        if isConnected {
            battery.main = parsePercent(info["device_batteryLevelMain"])
                ?? parsePercent(info["device_batteryLevelCombined"])
            battery.left = parsePercent(info["device_batteryLevelLeft"])
            battery.right = parsePercent(info["device_batteryLevelRight"])
            battery.caseLevel = parsePercent(info["device_batteryLevelCase"])
        }

        let id = formattedAddress.map(BluetoothKey.normalizeAddress) ?? BluetoothKey.normalizeName(name)
        return LiveBluetoothDevice(
            id: id,
            name: name,
            address: formattedAddress,
            isConnected: isConnected,
            minorType: minorType,
            hidUsage: nil,
            battery: battery
        )
    }

    private func parsePercent(_ value: Any?) -> Int? {
        if let intVal = value as? Int {
            return intVal
        }
        if let strVal = value as? String {
            let digits = strVal.filter(\.isNumber)
            return Int(digits)
        }
        return nil
    }

    // MARK: - Source 2: IOKit HID Services (Bluetooth Transport Only)

    private func scanIOKitHIDBluetooth() -> ([LiveBluetoothDevice], [String: String]) {
        var results: [LiveBluetoothDevice] = []
        var uuidMap: [String: String] = [:]

        let classNames = [
            "AppleDeviceManagementHIDEventService",
            "IOHIDDevice",
            "IOHIDUserDevice",
            "IOBluetoothHIDDriver"
        ]

        for className in classNames {
            guard let matching = IOServiceMatching(className) else { continue }
            var iterator: io_iterator_t = 0
            let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
            guard kr == KERN_SUCCESS else { continue }
            defer { IOObjectRelease(iterator) }

            var service = IOIteratorNext(iterator)
            while service != 0 {
                defer {
                    IOObjectRelease(service)
                    service = IOIteratorNext(iterator)
                }

                var propsRef: Unmanaged<CFMutableDictionary>?
                let propResult = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                guard propResult == KERN_SUCCESS,
                      let props = propsRef?.takeRetainedValue() as? [String: Any] else {
                    continue
                }

                // STRICT Bluetooth-only filter!
                guard isBluetoothTransport(props: props, className: className) else {
                    continue
                }

                let rawAddress = (props["DeviceAddress"] as? String)
                    ?? (props["BluetoothDeviceAddress"] as? String)
                    ?? (props["SerialNumber"] as? String).flatMap { looksLikeMacAddress($0) ? $0 : nil }

                let formattedAddress = rawAddress.map(BluetoothKey.formatAddress)

                // Record BLE peripheral UUID -> Bluetooth MAC address mapping for CoreBluetooth correlation
                if let physicalUUID = props["PhysicalDeviceUniqueID"] as? String,
                   let formattedAddress {
                    uuidMap[physicalUUID.uppercased()] = BluetoothKey.normalizeAddress(formattedAddress)
                }

                let batteryPercent = (props["BatteryPercent"] as? Int)
                    ?? (props["BatteryPercent"] as? NSNumber)?.intValue

                guard let batteryPercent else {
                    continue
                }

                let productName = (props["Product"] as? String)
                    ?? (props["DeviceName"] as? String)
                    ?? (props["Name"] as? String)
                    ?? "Urządzenie Bluetooth"

                let primaryUsage = (props["PrimaryUsage"] as? Int)
                    ?? (props["PrimaryUsage"] as? NSNumber)?.intValue

                let isCharging = (props["BatteryCharging"] as? Bool) ?? false

                let id = formattedAddress.map(BluetoothKey.normalizeAddress)
                    ?? BluetoothKey.normalizeName(productName)

                let dev = LiveBluetoothDevice(
                    id: id,
                    name: productName,
                    address: formattedAddress,
                    isConnected: true,
                    minorType: nil,
                    hidUsage: primaryUsage,
                    battery: BatteryDetails(main: batteryPercent, isCharging: isCharging)
                )
                results.append(dev)
            }
        }

        return (results, uuidMap)
    }

    private func isBluetoothTransport(props: [String: Any], className: String) -> Bool {
        if className == "IOBluetoothHIDDriver" {
            return true
        }
        if let transport = props["Transport"] as? String {
            return transport.lowercased().contains("bluetooth")
        }
        if props["BluetoothDevice"] != nil || props["DeviceAddress"] != nil {
            if let builtIn = props["Built-In"] as? Bool, builtIn { return false }
            if props["USB Product Name"] != nil && props["DeviceAddress"] == nil {
                return false
            }
            return props["DeviceAddress"] != nil
        }
        return false
    }

    private func looksLikeMacAddress(_ str: String) -> Bool {
        let cleaned = str.replacingOccurrences(of: "-", with: ":")
        let parts = cleaned.split(separator: ":")
        return parts.count == 6 && parts.allSatisfy { $0.count == 2 && UInt8($0, radix: 16) != nil }
    }

    // MARK: - Source 3: IOKit Power Sources (Bluetooth Transport Only)

    private func scanPowerSourcesBluetooth() -> [LiveBluetoothDevice] {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return []
        }

        var results: [LiveBluetoothDevice] = []

        for ps in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            // STRICT Bluetooth-only filter (excludes Internal MacBook battery, USB, UPS)
            guard let transport = desc[kIOPSTransportTypeKey as String] as? String,
                  transport.lowercased().contains("bluetooth") else {
                continue
            }

            let isPresent = (desc[kIOPSIsPresentKey as String] as? Bool) ?? true
            guard isPresent else { continue }

            let name = (desc[kIOPSNameKey as String] as? String) ?? "Urządzenie Bluetooth"
            let currentCap = desc[kIOPSCurrentCapacityKey as String] as? Int
            let maxCap = (desc[kIOPSMaxCapacityKey as String] as? Int) ?? 100
            let percent: Int? = currentCap.map { cap in
                maxCap > 0 ? Int(round(Double(cap) * 100.0 / Double(maxCap))) : cap
            }
            let isCharging = (desc[kIOPSIsChargingKey as String] as? Bool) ?? false

            let rawAddr = (desc["Accessory Identifier"] as? String)
                ?? (desc["Hardware Serial Number"] as? String)
            let formattedAddr = rawAddr.flatMap { looksLikeMacAddress($0) ? BluetoothKey.formatAddress($0) : nil }

            let id = formattedAddr.map(BluetoothKey.normalizeAddress) ?? BluetoothKey.normalizeName(name)

            results.append(
                LiveBluetoothDevice(
                    id: id,
                    name: name,
                    address: formattedAddr,
                    isConnected: true,
                    minorType: desc["Accessory Category"] as? String,
                    hidUsage: nil,
                    battery: BatteryDetails(main: percent, isCharging: isCharging)
                )
            )
        }

        return results
    }

    // MARK: - Source 4: IOBluetooth Paired Devices

    private func scanIOBluetoothPaired() -> [LiveBluetoothDevice] {
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return []
        }

        return paired.compactMap { device in
            let name = device.name ?? device.addressString ?? "Urządzenie Bluetooth"
            let formattedAddress = device.addressString.map(BluetoothKey.formatAddress)
            let id = formattedAddress.map(BluetoothKey.normalizeAddress) ?? BluetoothKey.normalizeName(name)
            let minorHint = minorClassHint(major: device.deviceClassMajor, minor: device.deviceClassMinor)
            let connected = device.isConnected()

            var battery = BatteryDetails()
            if connected {
                // Classic Bluetooth battery keys exposed on IOBluetoothDevice (0 means unavailable)
                battery.main = nonZeroBatteryValue(device, key: "batteryPercentSingle")
                    ?? nonZeroBatteryValue(device, key: "batteryPercentCombined")
                battery.left = nonZeroBatteryValue(device, key: "batteryPercentLeft")
                battery.right = nonZeroBatteryValue(device, key: "batteryPercentRight")
                battery.caseLevel = nonZeroBatteryValue(device, key: "batteryPercentCase")
            }

            return LiveBluetoothDevice(
                id: id,
                name: name,
                address: formattedAddress,
                isConnected: connected,
                minorType: minorHint,
                hidUsage: nil,
                battery: battery
            )
        }
    }

    private func nonZeroBatteryValue(_ device: IOBluetoothDevice, key: String) -> Int? {
        guard device.responds(to: NSSelectorFromString(key)),
              let num = device.value(forKey: key) as? NSNumber else {
            return nil
        }
        let val = num.intValue
        return (1...100).contains(val) ? val : nil
    }

    private func minorClassHint(major: BluetoothDeviceClassMajor, minor: BluetoothDeviceClassMinor) -> String? {
        if major == BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorPeripheral) {
            let pointing = (minor & 0x20) != 0
            let keyboard = (minor & 0x10) != 0
            if keyboard && !pointing { return "Keyboard" }
            if pointing && !keyboard { return "Mouse" }
            let sub = minor & 0x0F
            if sub == 1 || sub == 2 { return "Gamepad" }
        } else if major == BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorAudio) {
            switch minor {
            case 1, 2, 6: return "Headphones"
            case 5, 8: return "Speaker"
            default: return "Headphones"
            }
        }
        return nil
    }
}

// MARK: - Main Store & Reactive Monitor

@MainActor
final class BluetoothBatteryStore: ObservableObject {
    @Published private(set) var liveDevices: [LiveBluetoothDevice] = []
    @Published var configs: [DeviceConfig] = [] {
        didSet { saveConfigs() }
    }
    @Published var settings: AppSettings = AppSettings() {
        didSet {
            saveSettings()
            restartTimer()
        }
    }
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var lastUpdated: Date?

    private let scanner = BluetoothBatteryScanner()
    private let bleReader = CoreBluetoothBatteryReader()
    private var baseScannedDevices: [LiveBluetoothDevice] = []
    private var bleUUIDToAddress: [String: String] = [:]
    private var latestBLEReadings: [BLEBatteryReading] = []

    private var refreshTimer: Timer?
    private var btConnectNotification: IOBluetoothUserNotification?
    private var btObserver: BTEventObserver?
    private var wakeObserver: NSObjectProtocol?
    private var powerSourceRunLoopSource: CFRunLoopSource?

    private let configsKey = "BatteryInfoMac.deviceConfigs.v1"
    private let settingsKey = "BatteryInfoMac.appSettings.v1"

    init() {
        loadPersistedState()
        bleReader.onReadingsChanged = { [weak self] readings in
            guard let self else { return }
            self.latestBLEReadings = readings
            self.rebuildLiveDevices()
            self.lastUpdated = Date()
        }
        setupSystemObservers()
        restartTimer()
        refreshNow()
    }

    init(
        previewLiveDevices: [LiveBluetoothDevice],
        configs: [DeviceConfig] = [],
        settings: AppSettings = AppSettings()
    ) {
        self.configs = configs
        self.settings = settings
        self.baseScannedDevices = previewLiveDevices
        self.liveDevices = previewLiveDevices
        self.lastUpdated = Date()
    }

    deinit {
        refreshTimer?.invalidate()
        btConnectNotification?.unregister()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }

    /// Combines classic/IOKit/system_profiler scan results with live CoreBluetooth BLE GATT 0x180F readings.
    private func rebuildLiveDevices() {
        var merged = baseScannedDevices

        for reading in latestBLEReadings {
            let mappedAddress = bleUUIDToAddress[reading.peripheralID.uuidString.uppercased()]
            let normalizedReadingName = BluetoothKey.normalizeName(reading.name)

            if let idx = merged.firstIndex(where: { dev in
                if let mappedAddress, let devAddr = dev.normalizedAddress, devAddr == mappedAddress {
                    return true
                }
                return !normalizedReadingName.isEmpty && dev.normalizedName == normalizedReadingName
            }) {
                merged[idx].isConnected = true
                merged[idx].battery.main = reading.batteryPercent
            } else {
                // Connected BLE device with Battery Service 0x180F not yet in base list
                let formattedAddr = mappedAddress.map(BluetoothKey.formatAddress)
                let id = mappedAddress ?? normalizedReadingName
                merged.append(
                    LiveBluetoothDevice(
                        id: id,
                        name: reading.name,
                        address: formattedAddr,
                        isConnected: true,
                        minorType: nil,
                        hidUsage: nil,
                        battery: BatteryDetails(main: reading.batteryPercent)
                    )
                )
            }
        }

        self.liveDevices = merged
    }

    // MARK: - Derived Lists

    var managedDevices: [ManagedBluetoothDevice] {
        var result: [ManagedBluetoothDevice] = []
        var matchedLiveIDs = Set<String>()

        let sortedConfigs = configs.sorted { $0.sortOrder < $1.sortOrder }
        for config in sortedConfigs {
            let matchedLive = liveDevices.first { config.matches($0) }
            if let matchedLive {
                matchedLiveIDs.insert(matchedLive.id)
            }
            result.append(
                ManagedBluetoothDevice(
                    id: "cfg:\(config.id.uuidString)",
                    config: config,
                    live: matchedLive
                )
            )
        }

        for live in liveDevices where !matchedLiveIDs.contains(live.id) {
            result.append(
                ManagedBluetoothDevice(
                    id: "live:\(live.id)",
                    config: nil,
                    live: live
                )
            )
        }

        return result
    }

    var connectedDevices: [ManagedBluetoothDevice] {
        managedDevices
            .filter { $0.isConnected }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                if lhs.battery.hasAnyBatteryInfo != rhs.battery.hasAnyBatteryInfo {
                    return lhs.battery.hasAnyBatteryInfo
                }
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
    }

    var disconnectedDevices: [ManagedBluetoothDevice] {
        managedDevices
            .filter { !$0.isConnected }
            .sorted { lhs, rhs in
                let lhsConfigured = lhs.config != nil
                let rhsConfigured = rhs.config != nil
                if lhsConfigured != rhsConfigured { return lhsConfigured }
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
    }

    /// STRICT RULE: Only currently connected Bluetooth devices! If disconnected, NEVER shown.
    var menuBarDevices: [ManagedBluetoothDevice] {
        connectedDevices.filter { device in
            guard device.isConnected else { return false }

            if let config = device.config {
                guard config.showInMenuBar else { return false }
                return device.batteryPercent != nil || config.isUserConfigured
            } else {
                return settings.autoShowDetectedDevices && device.batteryPercent != nil
            }
        }
    }

    var unconfiguredLiveDevices: [LiveBluetoothDevice] {
        liveDevices.filter { live in
            !configs.contains { $0.matches(live) }
        }
    }

    // MARK: - Refreshing

    func refreshNow() {
        bleReader.refresh()
        guard !isRefreshing else { return }
        isRefreshing = true
        let scanner = self.scanner

        Task.detached(priority: .userInitiated) {
            let scanResult = scanner.scan()
            await MainActor.run {
                self.baseScannedDevices = scanResult.devices
                self.bleUUIDToAddress = scanResult.bleUUIDToAddress
                self.rebuildLiveDevices()
                self.lastUpdated = Date()
                self.isRefreshing = false
            }
        }
    }

    private func scheduleDebouncedRefresh() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            self.refreshNow()
        }
    }

    private func restartTimer() {
        refreshTimer?.invalidate()
        let interval = TimeInterval(max(5, settings.refreshIntervalSeconds))
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNow()
            }
        }
    }

    // MARK: - CRUD Operations

    func addConfig(_ config: DeviceConfig) {
        var newConfig = config
        let maxOrder = configs.map(\.sortOrder).max() ?? -1
        newConfig.sortOrder = maxOrder + 1
        configs.append(newConfig)
    }

    func updateConfig(_ config: DeviceConfig) {
        if let idx = configs.firstIndex(where: { $0.id == config.id }) {
            configs[idx] = config
        } else {
            addConfig(config)
        }
    }

    func deleteConfig(id: UUID) {
        configs.removeAll { $0.id == id }
        normalizeSortOrder()
    }

    func toggleMenuBarVisibility(for device: ManagedBluetoothDevice) {
        if var existing = device.config {
            existing.showInMenuBar.toggle()
            updateConfig(existing)
        } else if let live = device.live {
            let currentlyVisible = settings.autoShowDetectedDevices && live.battery.effectivePercent != nil
            let newConfig = DeviceConfig(
                matchAddress: live.address,
                matchName: live.name,
                customName: "",
                symbol: device.symbol,
                showInMenuBar: !currentlyVisible,
                showLabelInMenuBar: false,
                lowBatteryThreshold: nil,
                sortOrder: (configs.map(\.sortOrder).max() ?? -1) + 1,
                isUserConfigured: true
            )
            configs.append(newConfig)
        }
    }

    func editableConfig(for device: ManagedBluetoothDevice) -> DeviceConfig {
        if let existing = device.config {
            return existing
        }
        return DeviceConfig(
            matchAddress: device.live?.address,
            matchName: device.live?.name ?? "",
            customName: "",
            symbol: device.symbol,
            showInMenuBar: true,
            showLabelInMenuBar: false,
            lowBatteryThreshold: nil,
            sortOrder: (configs.map(\.sortOrder).max() ?? -1) + 1,
            isUserConfigured: true
        )
    }

    func moveConfig(id: UUID, direction: Int) {
        var sorted = configs.sorted { $0.sortOrder < $1.sortOrder }
        guard let index = sorted.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard sorted.indices.contains(target) else { return }
        sorted.swapAt(index, target)
        for i in sorted.indices {
            sorted[i].sortOrder = i
        }
        configs = sorted
    }

    private func normalizeSortOrder() {
        var sorted = configs.sorted { $0.sortOrder < $1.sortOrder }
        for i in sorted.indices {
            sorted[i].sortOrder = i
        }
        configs = sorted
    }

    // MARK: - Launch at Login

    func setLaunchAtLogin(_ enabled: Bool) {
        settings.launchAtLogin = enabled
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently ignore if bundle isn't eligible
        }
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: configsKey),
           let decoded = try? JSONDecoder().decode([DeviceConfig].self, from: data) {
            configs = decoded
        }
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: configsKey)
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    // MARK: - System Observers

    private func setupSystemObservers() {
        let observer = BTEventObserver { [weak self] in
            Task { @MainActor in
                self?.scheduleDebouncedRefresh()
            }
        }
        self.btObserver = observer
        self.btConnectNotification = IOBluetoothDevice.register(
            forConnectNotifications: observer,
            selector: #selector(BTEventObserver.handleConnect(_:device:))
        )

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleDebouncedRefresh()
            }
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        if let runLoopSource = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            let store = Unmanaged<BluetoothBatteryStore>.fromOpaque(ctx).takeUnretainedValue()
            Task { @MainActor in
                store.scheduleDebouncedRefresh()
            }
        }, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            self.powerSourceRunLoopSource = runLoopSource
        }
    }
}

// MARK: - Objective-C Bridge for IOBluetooth Notifications

private final class BTEventObserver: NSObject {
    private let onEvent: () -> Void

    init(onEvent: @escaping () -> Void) {
        self.onEvent = onEvent
    }

    @objc func handleConnect(_ notification: IOBluetoothUserNotification?, device: IOBluetoothDevice?) {
        device?.register(forDisconnectNotification: self, selector: #selector(handleDisconnect(_:device:)))
        onEvent()
    }

    @objc func handleDisconnect(_ notification: IOBluetoothUserNotification?, device: IOBluetoothDevice?) {
        onEvent()
    }
}
