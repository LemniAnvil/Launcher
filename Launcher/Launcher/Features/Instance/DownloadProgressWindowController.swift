//
//  DownloadProgressWindowController.swift
//  Launcher
//
//  Download progress window controller
//

import AppKit

class DownloadProgressWindowController: NSWindowController {
  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Downloading Game Files"
    window.center()
    window.isReleasedWhenClosed = false

    let viewController = DownloadProgressViewController()
    window.contentViewController = viewController

    self.init(window: window)
  }
}
