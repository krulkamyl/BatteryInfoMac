import SwiftUI

// MARK: - Popover Navigation Route

enum PopoverScreen: Equatable {
    case list
    case add
    case edit(DeviceConfig, isNew: Bool)
    case settings
}

// MARK: - Main Popover Container

struct MainPopoverView: View {
    @ObservedObject var store: BluetoothBatteryStore
    let onQuit: () -> Void

    @State private var screen: PopoverScreen = .list

    private var lang: AppLanguage { store.settings.language }

    var body: some View {
        VStack(spacing: 0) {
            switch screen {
            case .list:
                DeviceListView(
                    store: store,
                    onAdd: { screen = .add },
                    onEdit: { device in
                        let draft = store.editableConfig(for: device)
                        let isNew = device.config == nil
                        screen = .edit(draft, isNew: isNew)
                    },
                    onOpenSettings: { screen = .settings },
                    onQuit: onQuit
                )

            case .add:
                AddDeviceView(
                    store: store,
                    onSelectToConfigure: { draft in
                        screen = .edit(draft, isNew: true)
                    },
                    onBack: { screen = .list }
                )

            case .edit(let config, let isNew):
                EditDeviceView(
                    initialConfig: config,
                    isNew: isNew,
                    language: lang,
                    globalThreshold: store.settings.lowBatteryThreshold,
                    onSave: { updated in
                        store.updateConfig(updated)
                        screen = .list
                    },
                    onDelete: isNew ? nil : {
                        store.deleteConfig(id: config.id)
                        screen = .list
                    },
                    onCancel: { screen = .list }
                )

            case .settings:
                SettingsView(
                    store: store,
                    onBack: { screen = .list }
                )
            }
        }
        .frame(width: 360, height: 515)
    }
}

// MARK: - 1. Main Device List View

struct DeviceListView: View {
    @ObservedObject var store: BluetoothBatteryStore
    let onAdd: () -> Void
    let onEdit: (ManagedBluetoothDevice) -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    private var lang: AppLanguage { store.settings.language }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                Text(L10n.appTitle(lang))
                    .font(.headline)

                Spacer()

                Button {
                    store.refreshNow()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                        .animation(
                            store.isRefreshing
                                ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                : .default,
                            value: store.isRefreshing
                        )
                }
                .buttonStyle(.borderless)
                .help(L10n.helpRefresh(lang))

                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help(L10n.helpAdd(lang))

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help(L10n.configuration(lang))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            Divider()

            // Device list body
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeader(
                            title: L10n.connectedBluetooth(lang),
                            count: store.connectedDevices.count
                        )

                        if store.connectedDevices.isEmpty {
                            EmptyStateCard(
                                icon: "antenna.radiowaves.left.and.right.slash",
                                title: L10n.noConnectedTitle(lang),
                                subtitle: L10n.noConnectedSubtitle(lang)
                            )
                        } else {
                            ForEach(store.connectedDevices) { device in
                                DeviceRowView(
                                    device: device,
                                    store: store,
                                    onEdit: { onEdit(device) }
                                )
                            }
                        }
                    }

                    if !store.disconnectedDevices.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHeader(
                                title: L10n.disconnectedHidden(lang),
                                count: store.disconnectedDevices.count
                            )

                            ForEach(store.disconnectedDevices) { device in
                                DeviceRowView(
                                    device: device,
                                    store: store,
                                    onEdit: { onEdit(device) }
                                )
                            }
                        }
                    }
                }
                .padding(12)
            }

            Divider()

            // Footer
            HStack {
                if let updated = store.lastUpdated {
                    Text(L10n.updatedAt(updated.formatted(date: .omitted, time: .shortened), lang))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(L10n.scanningBluetooth(lang))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(L10n.add(lang)) { onAdd() }
                    .buttonStyle(.borderless)
                    .font(.caption)

                Text("•").foregroundStyle(.quaternary)

                Button(L10n.settings(lang)) { onOpenSettings() }
                    .buttonStyle(.borderless)
                    .font(.caption)

                Text("•").foregroundStyle(.quaternary)

                Button(L10n.quit(lang)) { onQuit() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
    }
}

private struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct DeviceRowView: View {
    let device: ManagedBluetoothDevice
    @ObservedObject var store: BluetoothBatteryStore
    let onEdit: () -> Void

    private var lang: AppLanguage { store.settings.language }

    private var isShownInBar: Bool {
        store.menuBarDevices.contains(where: { $0.id == device.id })
    }

    private var batteryColor: Color {
        guard let pct = device.batteryPercent else { return .secondary }
        let threshold = device.config?.lowBatteryThreshold ?? store.settings.lowBatteryThreshold
        if pct <= max(10, threshold / 2) { return .red }
        if pct <= threshold { return .orange }
        return .green
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(device.isConnected ? batteryColor.opacity(0.14) : Color.primary.opacity(0.06))
                    .frame(width: 34, height: 34)
                Image(systemName: device.symbol.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(device.isConnected ? batteryColor : .secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(device.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if device.battery.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }

                if device.isConnected {
                    if let pct = device.batteryPercent {
                        HStack(spacing: 6) {
                            ProgressView(value: Double(pct), total: 100)
                                .tint(batteryColor)
                                .frame(width: 48)

                            Text("\(pct)%")
                                .font(.system(size: 11.5, weight: .semibold).monospacedDigit())
                                .foregroundStyle(batteryColor)

                            if device.battery.left != nil || device.battery.right != nil {
                                Text(airpodsBreakdown)
                                    .font(.system(size: 10).monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        Text(L10n.connectedNoBattery(lang))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(device.address ?? L10n.disconnected(lang))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if let cfg = device.config, store.configs.count > 1 {
                VStack(spacing: 1) {
                    Button {
                        store.moveConfig(id: cfg.id, direction: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.helpMoveLeft(lang))

                    Button {
                        store.moveConfig(id: cfg.id, direction: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.helpMoveRight(lang))
                }
                .foregroundStyle(.secondary)
            }

            Button {
                store.toggleMenuBarVisibility(for: device)
            } label: {
                let enabled = device.config?.showInMenuBar ?? store.settings.autoShowDetectedDevices
                Image(systemName: enabled ? "eye.fill" : "eye.slash")
                    .font(.system(size: 12))
                    .foregroundStyle(isShownInBar ? .blue : (enabled ? .primary.opacity(0.6) : .secondary.opacity(0.5)))
            }
            .buttonStyle(.borderless)
            .help(device.showInMenuBar ? L10n.helpHideInBar(lang) : L10n.helpShowInBar(lang))

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help(L10n.helpEdit(lang))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(device.isConnected ? 0.045 : 0.025))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(device.isConnected ? 1.0 : 0.72)
    }

    private var airpodsBreakdown: String {
        var parts: [String] = []
        if let l = device.battery.left { parts.append("\(L10n.leftShort(lang)):\(l)%") }
        if let r = device.battery.right { parts.append("\(L10n.rightShort(lang)):\(r)%") }
        if let c = device.battery.caseLevel { parts.append("\(L10n.caseShort(lang)):\(c)%") }
        return parts.joined(separator: " ")
    }
}

// MARK: - 2. Add Bluetooth Device View

struct AddDeviceView: View {
    @ObservedObject var store: BluetoothBatteryStore
    let onSelectToConfigure: (DeviceConfig) -> Void
    let onBack: () -> Void

    private var lang: AppLanguage { store.settings.language }

    var body: some View {
        VStack(spacing: 0) {
            SubViewHeader(title: L10n.addDeviceTitle(lang), backLabel: L10n.back(lang), onBack: onBack)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Button {
                        let emptyDraft = DeviceConfig(
                            matchAddress: nil,
                            matchName: "",
                            customName: "",
                            symbol: .keyboard,
                            showInMenuBar: true,
                            showLabelInMenuBar: false,
                            lowBatteryThreshold: nil,
                            sortOrder: (store.configs.map(\.sortOrder).max() ?? -1) + 1,
                            isUserConfigured: true
                        )
                        onSelectToConfigure(emptyDraft)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.addManualTitle(lang))
                                    .font(.subheadline.weight(.medium))
                                Text(L10n.addManualSubtitle(lang))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeader(
                            title: L10n.detectedPairedSection(lang),
                            count: store.unconfiguredLiveDevices.count
                        )

                        if store.unconfiguredLiveDevices.isEmpty {
                            EmptyStateCard(
                                icon: "checkmark.circle",
                                title: L10n.allDetectedAddedTitle(lang),
                                subtitle: L10n.allDetectedAddedSubtitle(lang)
                            )
                        } else {
                            ForEach(store.unconfiguredLiveDevices) { live in
                                Button {
                                    let guessed = DeviceSymbol.guess(
                                        name: live.name,
                                        minorType: live.minorType,
                                        hidUsage: live.hidUsage
                                    )
                                    let draft = DeviceConfig(
                                        matchAddress: live.address,
                                        matchName: live.name,
                                        customName: "",
                                        symbol: guessed,
                                        showInMenuBar: true,
                                        showLabelInMenuBar: false,
                                        lowBatteryThreshold: nil,
                                        sortOrder: (store.configs.map(\.sortOrder).max() ?? -1) + 1,
                                        isUserConfigured: true
                                    )
                                    onSelectToConfigure(draft)
                                } label: {
                                    HStack(spacing: 10) {
                                        let guessed = DeviceSymbol.guess(
                                            name: live.name,
                                            minorType: live.minorType,
                                            hidUsage: live.hidUsage
                                        )
                                        Image(systemName: guessed.rawValue)
                                            .frame(width: 24)
                                            .foregroundStyle(live.isConnected ? .blue : .secondary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(live.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.primary)
                                            HStack(spacing: 6) {
                                                Text(live.isConnected ? L10n.connected(lang) : L10n.disconnected(lang))
                                                    .foregroundStyle(live.isConnected ? .green : .secondary)
                                                if let pct = live.battery.effectivePercent {
                                                    Text("• \(pct)%")
                                                }
                                                if let addr = live.address {
                                                    Text("• \(addr)")
                                                }
                                            }
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(9)
                                    .background(Color.primary.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(12)
            }
        }
    }
}

// MARK: - 3. Edit Device Configuration View

struct EditDeviceView: View {
    @State private var draft: DeviceConfig
    @State private var addressText: String
    @State private var useCustomThreshold: Bool
    @State private var customThresholdValue: Int

    let isNew: Bool
    let language: AppLanguage
    let globalThreshold: Int
    let onSave: (DeviceConfig) -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void

    init(
        initialConfig: DeviceConfig,
        isNew: Bool,
        language: AppLanguage,
        globalThreshold: Int,
        onSave: @escaping (DeviceConfig) -> Void,
        onDelete: (() -> Void)?,
        onCancel: @escaping () -> Void
    ) {
        _draft = State(initialValue: initialConfig)
        _addressText = State(initialValue: initialConfig.matchAddress ?? "")
        _useCustomThreshold = State(initialValue: initialConfig.lowBatteryThreshold != nil)
        _customThresholdValue = State(initialValue: initialConfig.lowBatteryThreshold ?? globalThreshold)
        self.isNew = isNew
        self.language = language
        self.globalThreshold = globalThreshold
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
    }

    private var canSave: Bool {
        !draft.matchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !addressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            SubViewHeader(
                title: isNew ? L10n.newDeviceTitle(language) : L10n.editDeviceTitle(language),
                backLabel: L10n.back(language),
                onBack: onCancel
            )
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(L10n.menuBarPreview(language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: draft.symbol.rawValue)
                                .font(.system(size: 13, weight: .medium))
                            if draft.showLabelInMenuBar {
                                Text(String(draft.displayTitle.prefix(12)))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            Text("60%")
                                .font(.system(size: 12, weight: .medium).monospacedDigit())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(Capsule())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        LabeledField(title: L10n.btMatchNameLabel(language)) {
                            TextField(L10n.btMatchNamePlaceholder(language), text: $draft.matchName)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledField(title: L10n.customLabelField(language)) {
                            TextField(L10n.customLabelPlaceholder(language), text: $draft.customName)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledField(title: L10n.macAddressField(language)) {
                            TextField(L10n.macAddressPlaceholder(language), text: $addressText)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(L10n.menuBarSymbol(language)) \(L10n.symbolName(draft.symbol, language))")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6),
                            spacing: 6
                        ) {
                            ForEach(DeviceSymbol.allCases) { sym in
                                Button {
                                    draft.symbol = sym
                                } label: {
                                    Image(systemName: sym.rawValue)
                                        .font(.system(size: 15))
                                        .frame(width: 44, height: 34)
                                        .background(
                                            draft.symbol == sym
                                                ? Color.blue.opacity(0.2)
                                                : Color.primary.opacity(0.05)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    draft.symbol == sym ? Color.blue : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .help(L10n.symbolName(sym, language))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(L10n.toggleShowWhenConnected(language), isOn: $draft.showInMenuBar)
                            .font(.subheadline)

                        Toggle(L10n.toggleShowShortLabel(language), isOn: $draft.showLabelInMenuBar)
                            .font(.subheadline)

                        Toggle(L10n.toggleCustomThreshold(language), isOn: $useCustomThreshold)
                            .font(.subheadline)

                        if useCustomThreshold {
                            HStack {
                                Text(L10n.warnBelow(language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Stepper("\(customThresholdValue)%", value: $customThresholdValue, in: 5...60, step: 5)
                                    .font(.caption.monospacedDigit())
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(12)
            }

            Divider()

            HStack {
                if let onDelete {
                    Button(L10n.delete(language), role: .destructive) {
                        onDelete()
                    }
                    .foregroundStyle(.red)
                }

                Spacer()

                Button(L10n.cancel(language), action: onCancel)
                Button(L10n.save(language)) {
                    var finalConfig = draft
                    let trimmedAddr = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
                    finalConfig.matchAddress = trimmedAddr.isEmpty ? nil : BluetoothKey.formatAddress(trimmedAddr)
                    finalConfig.matchName = draft.matchName.trimmingCharacters(in: .whitespacesAndNewlines)
                    finalConfig.customName = draft.customName.trimmingCharacters(in: .whitespacesAndNewlines)
                    finalConfig.lowBatteryThreshold = useCustomThreshold ? customThresholdValue : nil
                    finalConfig.isUserConfigured = true
                    onSave(finalConfig)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}

private struct LabeledField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content
        }
    }
}

// MARK: - 4. Global Configuration View

struct SettingsView: View {
    @ObservedObject var store: BluetoothBatteryStore
    let onBack: () -> Void

    private var lang: AppLanguage { store.settings.language }

    var body: some View {
        VStack(spacing: 0) {
            SubViewHeader(title: L10n.configuration(lang), backLabel: L10n.back(lang), onBack: onBack)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsCard(title: L10n.sectionMenuBar(lang)) {
                        Toggle(
                            L10n.autoShowDetected(lang),
                            isOn: $store.settings.autoShowDetectedDevices
                        )
                        .font(.subheadline)

                        Divider()

                        HStack {
                            Text(L10n.displayFormat(lang))
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $store.settings.displayFormat) {
                                ForEach(MenuBarDisplayFormat.allCases) { format in
                                    Text(L10n.formatName(format, lang)).tag(format)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 175)
                        }

                        HStack {
                            Text(L10n.iconSpacing(lang))
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $store.settings.itemSpacing) {
                                ForEach(MenuBarSpacing.allCases) { spacing in
                                    Text(L10n.spacingName(spacing, lang)).tag(spacing)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }

                        Toggle(L10n.showChargingBolt(lang), isOn: $store.settings.showChargingBolt)
                            .font(.subheadline)
                    }

                    SettingsCard(title: L10n.sectionLowBattery(lang)) {
                        Toggle(L10n.colorizeLowBattery(lang), isOn: $store.settings.colorizeLowBattery)
                            .font(.subheadline)

                        if store.settings.colorizeLowBattery {
                            HStack {
                                Text(L10n.defaultThreshold(lang))
                                    .font(.subheadline)
                                Spacer()
                                Stepper(
                                    "\(store.settings.lowBatteryThreshold)%",
                                    value: $store.settings.lowBatteryThreshold,
                                    in: 5...50,
                                    step: 5
                                )
                                .font(.subheadline.monospacedDigit())
                            }
                        }
                    }

                    SettingsCard(title: L10n.sectionGeneral(lang)) {
                        HStack {
                            Text(L10n.languageLabel(lang))
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $store.settings.language) {
                                ForEach(AppLanguage.allCases) { option in
                                    Text(option.nativeName).tag(option)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 145)
                        }

                        HStack {
                            Text(L10n.refreshEvery(lang))
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $store.settings.refreshIntervalSeconds) {
                                Text(L10n.seconds(10, lang)).tag(10)
                                Text(L10n.seconds(30, lang)).tag(30)
                                Text(L10n.seconds(60, lang)).tag(60)
                                Text(L10n.minutes(2, lang)).tag(120)
                            }
                            .labelsHidden()
                            .frame(width: 125)
                        }

                        Toggle(
                            L10n.launchAtLogin(lang),
                            isOn: Binding(
                                get: { store.settings.launchAtLogin },
                                set: { store.setLaunchAtLogin($0) }
                            )
                        )
                        .font(.subheadline)
                    }

                    Text(L10n.bluetoothOnlyFootnote(lang))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(12)
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 9) {
                content
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Shared Header

private struct SubViewHeader: View {
    let title: String
    let backLabel: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(backLabel)
                        .font(.subheadline)
                }
            }
            .buttonStyle(.borderless)

            Spacer()

            Text(title)
                .font(.headline)

            Spacer()

            Text(backLabel)
                .font(.subheadline)
                .opacity(0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
