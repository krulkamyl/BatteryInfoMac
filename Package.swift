// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BatteryInfoMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BatteryInfoMac", targets: ["BatteryInfoMac"])
    ],
    targets: [
        .executableTarget(
            name: "BatteryInfoMac",
            path: "Sources/BatteryInfoMac",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("IOKit"),
                .linkedFramework("IOBluetooth"),
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
