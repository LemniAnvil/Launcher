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

  // Store auth callback handler
  static var pendingAuthCallback: ((String) -> Void)?

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

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  func application(
    _ application: NSApplication,
    open urls: [URL]
  ) {

    for url in urls {
      handleIncomingURL(url)
    }
  }

  func handleIncomingURL(_ url: URL) {
    Logger.shared.info("Received URL: \(url.absoluteString)", category: "AppDelegate")

    // Check if this is an auth callback
    guard url.scheme?.lowercased() == "lemnianvil-launcher",
          url.host == "auth" else {
      Logger.shared.debug("Not an auth callback URL", category: "AppDelegate")
      return
    }

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let params = components?.queryItems ?? []

    // Extract authorization code and state from callback URL
    let code = params.first { $0.name == "code" }?.value
    let state = params.first { $0.name == "state" }?.value

    Logger.shared.debug("Extracted code: \(code ?? "nil")", category: "AppDelegate")
    Logger.shared.debug("Extracted state: \(state ?? "nil")", category: "AppDelegate")

    // Notify the auth handler if available
    if let callback = Self.pendingAuthCallback {
      callback(url.absoluteString)
      Self.pendingAuthCallback = nil
      Logger.shared.info("Auth callback invoked", category: "AppDelegate")
    } else {
      Logger.shared.warning("No pending auth callback handler", category: "AppDelegate")
    }
  }
}
