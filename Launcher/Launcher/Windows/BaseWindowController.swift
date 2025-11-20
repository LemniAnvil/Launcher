//
//  BaseWindowController.swift
//  Launcher
//
//  Base window controller for common window functionality
//

import AppKit

class BaseWindowController: NSWindowController, NSWindowDelegate {

  /// Window configuration structure
  struct WindowConfiguration {
    var contentRect: NSRect
    var styleMask: NSWindow.StyleMask
    var minSize: NSSize?
    var title: String
    var isReleasedWhenClosed: Bool = false
    var handlesModalStop: Bool = true

    init(
      width: CGFloat = 500,
      height: CGFloat = 400,
      styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable],
      minWidth: CGFloat? = nil,
      minHeight: CGFloat? = nil,
      title: String,
      isReleasedWhenClosed: Bool = false,
      handlesModalStop: Bool = true
    ) {
      self.contentRect = NSRect(x: 0, y: 0, width: width, height: height)
      self.styleMask = styleMask
      if let minWidth = minWidth, let minHeight = minHeight {
        self.minSize = NSSize(width: minWidth, height: minHeight)
      }
      self.title = title
      self.isReleasedWhenClosed = isReleasedWhenClosed
      self.handlesModalStop = handlesModalStop
    }
  }

  private let handlesModalStop: Bool

  /// Convenience initializer for creating a window with configuration
  convenience init(
    configuration: WindowConfiguration,
    viewController: NSViewController
  ) {
    let window = NSWindow(
      contentRect: configuration.contentRect,
      styleMask: configuration.styleMask,
      backing: .buffered,
      defer: false
    )

    window.title = configuration.title
    window.center()
    window.isReleasedWhenClosed = configuration.isReleasedWhenClosed

    if let minSize = configuration.minSize {
      window.minSize = minSize
    }

    window.contentViewController = viewController

    self.init(window: window, handlesModalStop: configuration.handlesModalStop)
    window.delegate = self
  }

  private init(window: NSWindow, handlesModalStop: Bool = true) {
    self.handlesModalStop = handlesModalStop
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func windowDidLoad() {
    super.windowDidLoad()
    window?.makeKeyAndOrderFront(nil)
  }

  func windowWillClose(_ notification: Notification) {
    if handlesModalStop {
      NSApplication.shared.stopModal()
    }
  }
}
