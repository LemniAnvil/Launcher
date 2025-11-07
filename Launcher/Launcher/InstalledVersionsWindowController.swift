//
//  InstalledVersionsWindowController.swift
//  Launcher
//
//  Installed versions list window controller
//

import AppKit

class InstalledVersionsWindowController: NSWindowController {

  convenience init() {
    // Create window
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.InstalledVersions.windowTitle
    window.center()
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 350, height: 400)

    // Set content view controller
    let viewController = InstalledVersionsViewController()
    window.contentViewController = viewController

    self.init(window: window)
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    // Window configuration
    window?.makeKeyAndOrderFront(nil)
  }
}
