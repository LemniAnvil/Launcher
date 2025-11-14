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

  func application(
    _ application: NSApplication,
    open urls: [URL]
  ) {

    for url in urls {
      handleIncomingURL(url)
    }
  }

  func handleIncomingURL(_ url: URL) {
    print("Received URL:", url.absoluteString)

    // Check if this is an auth callback
    guard url.scheme?.lowercased() == "lemnianvil-launcher",
          url.host == "auth" else {
      print("Not an auth callback URL")
      return
    }

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let params = components?.queryItems ?? []

    // Extract authorization code and state from callback URL
    let code = params.first { $0.name == "code" }?.value
    let state = params.first { $0.name == "state" }?.value

    print("Extracted code:", code ?? "nil")
    print("Extracted state:", state ?? "nil")

    // Notify the auth handler if available
    if let callback = Self.pendingAuthCallback {
      callback(url.absoluteString)
      Self.pendingAuthCallback = nil
      print("Auth callback invoked")
    } else {
      print("Warning: No pending auth callback handler")
    }
  }
}
