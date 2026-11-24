import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let store: BluetoothBatteryStore
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    private var appearanceObservation: NSKeyValueObservation?
    private var eventMonitor: Any?

    init(store: BluetoothBatteryStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        super.init()

        configurePopover()
        configureStatusButton()
        observeChanges()
        updateStatusBar()
    }

    deinit {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 515)
        popover.contentViewController = NSHostingController(
            rootView: MainPopoverView(
                store: store,
                onQuit: { NSApp.terminate(nil) }
            )
        )
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(handleStatusBarClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        appearanceObservation = button.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.updateStatusBar()
            }
        }
    }

    private func observeChanges() {
        Publishers.CombineLatest3(store.$liveDevices, store.$configs, store.$settings)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.updateStatusBar()
            }
            .store(in: &cancellables)
    }

    private func updateStatusBar() {
        guard let button = statusItem.button else { return }
        let visibleDevices = store.menuBarDevices
        let rendered = StatusBarRenderer.render(
            devices: visibleDevices,
            settings: store.settings,
            appearance: button.effectiveAppearance
        )
        button.image = rendered.image
        button.toolTip = rendered.tooltip
    }

    @objc private func handleStatusBarClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            store.refreshNow()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()

            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    private func showContextMenu() {
        let lang = store.settings.language
        let menu = NSMenu()
        let refreshItem = NSMenuItem(title: L10n.refreshNow(lang), action: #selector(contextRefresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let openItem = NSMenuItem(title: L10n.openConfigPanel(lang), action: #selector(contextOpenPopover), keyEquivalent: ",")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: L10n.quitApp(lang), action: #selector(contextQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func contextRefresh() {
        store.refreshNow()
    }

    @objc private func contextOpenPopover() {
        togglePopover()
    }

    @objc private func contextQuit() {
        NSApp.terminate(nil)
    }
}
