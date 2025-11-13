//
//  AddInstanceWindowController.swift
//  Launcher
//
//  Window controller for adding new instances
//

import AppKit

class AddInstanceWindowController: NSWindowController {

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.AddInstance.windowTitle
    window.center()
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 900, height: 600)

    let viewController = AddInstanceViewController()
    window.contentViewController = viewController

    self.init(window: window)
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    window?.makeKeyAndOrderFront(nil)
  }
}
