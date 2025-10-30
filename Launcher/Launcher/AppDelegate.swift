//
//  AppDelegate.swift
//  Launcher
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

  private lazy var window: NSWindow = {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.miniaturizable, .closable, .resizable, .titled],
      backing: .buffered,
      defer: false
    )
    window.center()
    window.title = Localized.MainWindow.windowTitle
    window.contentViewController = viewController
    return window
  }()

  private lazy var viewController: ViewController = {
    return ViewController()
  }()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    window.makeKeyAndOrderFront(nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
