//
//  JavaDetectionWindowController.swift
//  Launcher
//
//  Window controller for Java detection
//

import AppKit

class JavaDetectionWindowController: NSWindowController, NSWindowDelegate {

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.JavaDetection.windowTitle
    window.center()
    window.minSize = NSSize(width: 700, height: 500)

    // Set content view controller
    let viewController = JavaDetectionViewController()
    window.contentViewController = viewController

    self.init(window: window)
    window.delegate = self
  }

  func windowWillClose(_ notification: Notification) {
    NSApplication.shared.stopModal()
  }
}
