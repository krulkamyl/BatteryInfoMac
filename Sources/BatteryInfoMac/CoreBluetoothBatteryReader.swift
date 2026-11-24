import Foundation
import CoreBluetooth

struct BLEBatteryReading: Equatable, Sendable {
    let peripheralID: UUID
    let name: String
    let batteryPercent: Int
}

/// Reads battery percentages from currently connected Bluetooth Low Energy (BLE) devices
/// via the standard GATT Battery Service (0x180F) / Battery Level Characteristic (0x2A19).
/// This is required on macOS for BLE peripherals like Logitech MX Keys Mini, MX Master 3S/4, Keychron BLE, etc.
@MainActor
final class CoreBluetoothBatteryReader: NSObject {
    private let batteryServiceUUID = CBUUID(string: "180F")
    private let batteryLevelCharUUID = CBUUID(string: "2A19")

    private var centralManager: CBCentralManager?
    private var activePeripherals: [UUID: CBPeripheral] = [:]
    private var batteryCharacteristics: [UUID: CBCharacteristic] = [:]
    private(set) var readings: [UUID: BLEBatteryReading] = [:]

    var onReadingsChanged: (([BLEBatteryReading]) -> Void)?

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func refresh() {
        guard let central = centralManager, central.state == .poweredOn else { return }

        let connected = central.retrieveConnectedPeripherals(withServices: [batteryServiceUUID])
        let connectedIDs = Set(connected.map(\.identifier))

        // Prune peripherals that are no longer connected
        var didPrune = false
        for id in Array(activePeripherals.keys) where !connectedIDs.contains(id) {
            if let oldPeripheral = activePeripherals.removeValue(forKey: id) {
                central.cancelPeripheralConnection(oldPeripheral)
            }
            batteryCharacteristics.removeValue(forKey: id)
            if readings.removeValue(forKey: id) != nil {
                didPrune = true
            }
        }

        for peripheral in connected {
            let id = peripheral.identifier
            activePeripherals[id] = peripheral
            peripheral.delegate = self

            switch peripheral.state {
            case .connected:
                if let char = batteryCharacteristics[id] {
                    peripheral.readValue(for: char)
                } else {
                    peripheral.discoverServices([batteryServiceUUID])
                }
            case .connecting:
                break
            default:
                central.connect(peripheral, options: nil)
            }
        }

        if didPrune {
            notifyListeners()
        }
    }

    private func notifyListeners() {
        onReadingsChanged?(Array(readings.values))
    }
}

extension CoreBluetoothBatteryReader: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state == .poweredOn {
                self.refresh()
            } else {
                if !self.readings.isEmpty {
                    self.readings.removeAll()
                    self.batteryCharacteristics.removeAll()
                    self.activePeripherals.removeAll()
                    self.notifyListeners()
                }
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            peripheral.delegate = self
            peripheral.discoverServices([self.batteryServiceUUID])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            let id = peripheral.identifier
            self.batteryCharacteristics.removeValue(forKey: id)
            self.activePeripherals.removeValue(forKey: id)
            if self.readings.removeValue(forKey: id) != nil {
                self.notifyListeners()
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            self.activePeripherals.removeValue(forKey: peripheral.identifier)
            self.batteryCharacteristics.removeValue(forKey: peripheral.identifier)
        }
    }
}

extension CoreBluetoothBatteryReader: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        let services = peripheral.services ?? []
        Task { @MainActor in
            for service in services where service.uuid == self.batteryServiceUUID {
                peripheral.discoverCharacteristics([self.batteryLevelCharUUID], for: service)
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil else { return }
        let chars = service.characteristics ?? []
        Task { @MainActor in
            for char in chars where char.uuid == self.batteryLevelCharUUID {
                self.batteryCharacteristics[peripheral.identifier] = char
                peripheral.readValue(for: char)
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil,
              let data = characteristic.value,
              let rawLevel = data.first else {
            return
        }
        let percent = min(max(Int(rawLevel), 0), 100)
        let name = peripheral.name ?? "Urządzenie BLE"
        let id = peripheral.identifier

        Task { @MainActor in
            let reading = BLEBatteryReading(
                peripheralID: id,
                name: name,
                batteryPercent: percent
            )
            if self.readings[id] != reading {
                self.readings[id] = reading
                self.notifyListeners()
            }
        }
    }
}
