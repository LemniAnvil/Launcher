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
      size: .large,
      style: .full,
      title: Localized.JavaDetection.windowTitle
    )

    let viewController = JavaDetectionViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
