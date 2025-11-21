//
//  BaseWindowController.swift
//  Launcher
//
//  Base window controller for common window functionality
//

import AppKit

class BaseWindowController: NSWindowController, NSWindowDelegate {

  /// Predefined window style presets for consistency across the application
  enum WindowStylePreset {
    case modal      // Basic modal dialog: titled, closable
    case standard   // Standard window: titled, closable, resizable
    case full       // Full-featured window: titled, closable, resizable, miniaturizable

    var styleMask: NSWindow.StyleMask {
      switch self {
      case .modal:
        return [.titled, .closable]
      case .standard:
        return [.titled, .closable, .resizable]
      case .full:
        return [.titled, .closable, .resizable, .miniaturizable]
      }
    }
  }

  /// Predefined window sizes for consistency across the application
  enum WindowSize {
    case small          // 400×500
    case smallWide      // 500×500
    case smallTall      // 400×600
    case medium         // 500×600
    case mediumWide     // 600×700
    case large          // 800×600
    case xlarge         // 1000×680
    case xlargeHigh     // 1000×700
    case custom(width: CGFloat, height: CGFloat)

    var size: (width: CGFloat, height: CGFloat) {
      switch self {
      case .small:
        return (400, 500)
      case .smallWide:
        return (500, 500)
      case .smallTall:
        return (400, 600)
      case .medium:
        return (500, 600)
      case .mediumWide:
        return (600, 700)
      case .large:
        return (800, 600)
      case .xlarge:
        return (1000, 680)
      case .xlargeHigh:
        return (1000, 700)
      case .custom(let width, let height):
        return (width, height)
      }
    }

    var minSize: (width: CGFloat, height: CGFloat)? {
      switch self {
      case .small:
        return (350, 400)
      case .smallWide:
        return (450, 400)
      case .smallTall:
        return (350, 400)
      case .medium:
        return nil
      case .mediumWide:
        return (500, 600)
      case .large:
        return (700, 500)
      case .xlarge, .xlargeHigh:
        return (900, 600)
      case .custom:
        return nil
      }
    }
  }

  /// Window configuration structure
  struct WindowConfiguration {
    var contentRect: NSRect
    var styleMask: NSWindow.StyleMask
    var minSize: NSSize?
    var title: String
    var isReleasedWhenClosed: Bool = false
    var handlesModalStop: Bool = true

    /// Initializer using WindowSize enum and WindowStylePreset
    init(
      size: WindowSize,
      style: WindowStylePreset,
      title: String,
      isReleasedWhenClosed: Bool = false,
      handlesModalStop: Bool = true
    ) {
      let dimensions = size.size
      self.contentRect = NSRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height)
      self.styleMask = style.styleMask

      if let minDimensions = size.minSize {
        self.minSize = NSSize(width: minDimensions.width, height: minDimensions.height)
      }

      self.title = title
      self.isReleasedWhenClosed = isReleasedWhenClosed
      self.handlesModalStop = handlesModalStop
    }

    /// Initializer using WindowSize enum with custom styleMask
    init(
      size: WindowSize,
      styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable],
      title: String,
      isReleasedWhenClosed: Bool = false,
      handlesModalStop: Bool = true
    ) {
      let dimensions = size.size
      self.contentRect = NSRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height)
      self.styleMask = styleMask

      if let minDimensions = size.minSize {
        self.minSize = NSSize(width: minDimensions.width, height: minDimensions.height)
      }

      self.title = title
      self.isReleasedWhenClosed = isReleasedWhenClosed
      self.handlesModalStop = handlesModalStop
    }

    /// Legacy initializer for backwards compatibility
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
