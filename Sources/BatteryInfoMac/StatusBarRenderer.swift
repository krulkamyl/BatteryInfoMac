import AppKit

/// Renders crisp Retina menu bar imagery showing Bluetooth device symbols and battery percentages.
enum StatusBarRenderer {

    struct RenderResult {
        let image: NSImage
        let tooltip: String
    }

    static func render(
        devices: [ManagedBluetoothDevice],
        settings: AppSettings,
        appearance: NSAppearance?
    ) -> RenderResult {
        if devices.isEmpty {
            return renderEmptyIcon(language: settings.language)
        }

        let barHeight: CGFloat = 22
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let boltConfig = NSImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        let textFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let itemSpacing = settings.itemSpacing.points
        let iconTextGap: CGFloat = 3
        let horizontalPadding: CGFloat = 3

        struct DrawItem {
            let symbolImage: NSImage?
            let chargingImage: NSImage?
            let text: String
            let textSize: NSSize
            let iconSize: NSSize
            let boltSize: NSSize
            let color: NSColor?
            let totalWidth: CGFloat
        }

        var drawItems: [DrawItem] = []
        var anyColored = false

        for device in devices {
            let percent = device.batteryPercent
            let threshold = device.config?.lowBatteryThreshold ?? settings.lowBatteryThreshold

            let tintColor: NSColor?
            if settings.colorizeLowBattery, let p = percent, p <= threshold {
                tintColor = p <= max(10, threshold / 2) ? .systemRed : .systemOrange
                anyColored = true
            } else {
                tintColor = nil
            }

            let baseSymbol = NSImage(
                systemSymbolName: device.symbol.rawValue,
                accessibilityDescription: device.displayName
            )?.withSymbolConfiguration(symbolConfig)

            let chargingBolt: NSImage?
            if settings.showChargingBolt && device.battery.isCharging {
                chargingBolt = NSImage(
                    systemSymbolName: "bolt.fill",
                    accessibilityDescription: L10n.charging(settings.language)
                )?.withSymbolConfiguration(boltConfig)
            } else {
                chargingBolt = nil
            }

            let text = formattedText(for: device, settings: settings)
            let attrs: [NSAttributedString.Key: Any] = [.font: textFont]
            let textSize = (text as NSString).size(withAttributes: attrs)
            let iconSize = baseSymbol?.size ?? NSSize(width: 14, height: 14)
            let boltSize = chargingBolt?.size ?? .zero

            var width = iconSize.width + iconTextGap + textSize.width
            if chargingBolt != nil {
                width += 1.5 + boltSize.width
            }

            drawItems.append(
                DrawItem(
                    symbolImage: baseSymbol,
                    chargingImage: chargingBolt,
                    text: text,
                    textSize: textSize,
                    iconSize: iconSize,
                    boltSize: boltSize,
                    color: tintColor,
                    totalWidth: width
                )
            )
        }

        let totalContentWidth = drawItems.reduce(CGFloat(0)) { $0 + $1.totalWidth }
            + CGFloat(max(0, drawItems.count - 1)) * itemSpacing
        let totalWidth = ceil(totalContentWidth + horizontalPadding * 2)

        let renderedImage = NSImage(size: NSSize(width: totalWidth, height: barHeight), flipped: false) { _ in
            let resolveDrawing = {
                var x = horizontalPadding

                for (index, item) in drawItems.enumerated() {
                    let effectiveColor: NSColor = anyColored
                        ? (item.color ?? .labelColor)
                        : .black

                    // Draw SF Symbol
                    if let sym = item.symbolImage {
                        let iconY = (barHeight - item.iconSize.height) / 2.0
                        let iconRect = NSRect(origin: NSPoint(x: x, y: iconY), size: item.iconSize)
                        let tinted = tint(image: sym, color: effectiveColor)
                        tinted.draw(in: iconRect)
                    }
                    x += item.iconSize.width + iconTextGap

                    // Draw Percentage / Label text
                    let textY = (barHeight - item.textSize.height) / 2.0 - 0.5
                    let textRect = NSRect(origin: NSPoint(x: x, y: textY), size: item.textSize)
                    let textAttrs: [NSAttributedString.Key: Any] = [
                        .font: textFont,
                        .foregroundColor: effectiveColor
                    ]
                    (item.text as NSString).draw(in: textRect, withAttributes: textAttrs)
                    x += item.textSize.width

                    // Draw Charging Bolt if charging
                    if let bolt = item.chargingImage {
                        x += 1.5
                        let boltY = (barHeight - item.boltSize.height) / 2.0
                        let boltRect = NSRect(origin: NSPoint(x: x, y: boltY), size: item.boltSize)
                        let boltColor: NSColor = anyColored ? .systemGreen : effectiveColor
                        tint(image: bolt, color: boltColor).draw(in: boltRect)
                        x += item.boltSize.width
                    }

                    if index < drawItems.count - 1 {
                        x += itemSpacing
                    }
                }
            }

            if anyColored, let appearance {
                appearance.performAsCurrentDrawingAppearance(resolveDrawing)
            } else {
                resolveDrawing()
            }
            return true
        }

        // If no device needs special low-battery color, mark as template for 100% native macOS Light/Dark tinting
        renderedImage.isTemplate = !anyColored

        let tooltipLines = devices.map { dev -> String in
            let pct = dev.batteryPercent.map { "\($0)%" } ?? L10n.noData(settings.language)
            return "\(dev.displayName): \(pct)"
        }
        return RenderResult(
            image: renderedImage,
            tooltip: tooltipLines.joined(separator: "\n")
        )
    }

    private static func renderEmptyIcon(language: AppLanguage) -> RenderResult {
        // Minimal icon only so the user can still click to configure/add devices when 0 BT devices are connected
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        let image = NSImage(
            systemSymbolName: "dot.radiowaves.left.and.right",
            accessibilityDescription: L10n.appTitle(language)
        )?.withSymbolConfiguration(config) ?? NSImage(size: NSSize(width: 16, height: 16))
        image.isTemplate = true

        return RenderResult(
            image: image,
            tooltip: L10n.emptyMenuBarTooltip(language)
        )
    }

    private static func formattedText(for device: ManagedBluetoothDevice, settings: AppSettings) -> String {
        let pctPart: String
        if let percent = device.batteryPercent {
            pctPart = settings.displayFormat == .iconAndNumber ? "\(percent)" : "\(percent)%"
        } else {
            pctPart = "—"
        }

        let showName = settings.displayFormat == .iconNamePercent || device.showLabelInMenuBar
        if showName {
            let shortName = String(device.displayName.prefix(12))
            return "\(shortName) \(pctPart)"
        }
        return pctPart
    }

    private static func tint(image: NSImage, color: NSColor) -> NSImage {
        let result = NSImage(size: image.size)
        result.lockFocus()
        image.draw(at: .zero, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)
        color.set()
        NSRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
        result.unlockFocus()
        result.isTemplate = false
        return result
    }
}
