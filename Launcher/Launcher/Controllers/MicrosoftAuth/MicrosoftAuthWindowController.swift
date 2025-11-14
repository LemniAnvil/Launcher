//
//  MicrosoftAuthWindowController.swift
//  Launcher
//
//  Microsoft authentication window controller
//

import AppKit

class MicrosoftAuthWindowController: NSWindowController {

  convenience init() {
    // Create window
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.MicrosoftAuth.windowTitle
    window.center()
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 500, height: 600)

    // Set content view controller
    let viewController = MicrosoftAuthViewController()
    window.contentViewController = viewController

    self.init(window: window)
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    // Window configuration
    window?.makeKeyAndOrderFront(nil)
  }
}
