//
//  SettingsWindowController.swift
//  Launcher
//
//  Settings window controller
//

import AppKit

class SettingsWindowController: NSWindowController, NSWindowDelegate {

  convenience init() {
    // Create window
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.Settings.windowTitle
    window.center()
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 450, height: 350)

    // Set content view controller
    let viewController = SettingsViewController()
    window.contentViewController = viewController

    self.init(window: window)
    window.delegate = self
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    // Window configuration
    window?.makeKeyAndOrderFront(nil)
  }

  func windowWillClose(_ notification: Notification) {
    NSApplication.shared.stopModal()
  }
}
