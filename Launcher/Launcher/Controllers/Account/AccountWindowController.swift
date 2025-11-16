//
//  AccountWindowController.swift
//  Launcher
//
//  Account management window controller
//

import AppKit

class AccountWindowController: NSWindowController, NSWindowDelegate {

  convenience init() {
    // Create window
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.Account.windowTitle
    window.center()
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 350, height: 400)

    // Set content view controller
    let viewController = AccountViewController()
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
