//
//  VersionListWindowController.swift
//  Launcher
//
//  Version list window controller
//

import AppKit

class VersionListWindowController: NSWindowController {

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.VersionListWindow.windowTitle
    window.center()
    window.minSize = NSSize(width: 800, height: 600)

    // Set content view controller
    let versionListViewController = VersionListViewController()
    window.contentViewController = versionListViewController

    self.init(window: window)
  }
}
