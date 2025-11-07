//
//  InstalledVersionsWindowController.swift
//  Launcher
//
//  已安装版本列表窗口控制器
//

import AppKit

class InstalledVersionsWindowController: NSWindowController {

  convenience init() {
    // Create window
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.InstalledVersions.windowTitle
    window.center()
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 350, height: 400)

    // 设置内容视图控制器
    let viewController = InstalledVersionsViewController()
    window.contentViewController = viewController

    self.init(window: window)
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    // 窗口配置
    window?.makeKeyAndOrderFront(nil)
  }
}
