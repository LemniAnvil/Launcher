//
//  JavaDetectionWindowController.swift
//  Launcher
//
//  Window controller for Java detection
//

import AppKit

class JavaDetectionWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      width: 800,
      height: 600,
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      minWidth: 700,
      minHeight: 500,
      title: Localized.JavaDetection.windowTitle
    )

    let viewController = JavaDetectionViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
