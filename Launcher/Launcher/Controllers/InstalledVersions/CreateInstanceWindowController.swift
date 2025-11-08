//
//  CreateInstanceWindowController.swift
//  Launcher
//
//  Window controller for creating new instance
//

import AppKit

class CreateInstanceWindowController: NSWindowController {

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1000, height: 680),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = Localized.Instances.createInstanceTitle
    window.center()
    window.isReleasedWhenClosed = false

    let viewController = CreateInstanceViewController()
    window.contentViewController = viewController

    self.init(window: window)
  }

  override func close() {
    window?.close()
  }
}
