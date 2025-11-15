//
//  InstanceDetailWindowController.swift
//  Launcher
//
//  Window controller for instance detail view
//

import AppKit

class InstanceDetailWindowController: NSWindowController {

  convenience init(instance: Instance) {
    let viewController = InstanceDetailViewController(instance: instance)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = Localized.InstanceDetail.windowTitle
    window.contentViewController = viewController
    window.center()

    self.init(window: window)
  }
}
