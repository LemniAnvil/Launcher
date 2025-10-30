//
//  TestWindowController.swift
//  Launcher
//
//  Test window controller
//

import AppKit

class TestWindowController: NSWindowController {

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.TestWindow.windowTitle
    window.center()
    window.minSize = NSSize(width: 800, height: 600)

    // Set content view controller
    let testViewController = TestViewController()
    window.contentViewController = testViewController

    self.init(window: window)
  }
}
