//
//  JavaDetectionWindowController.swift
//  Launcher
//
//  Window controller for Java detection
//

import AppKit
import Yatagarasu

class JavaDetectionWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .large,
      style: .full,
      title: Localized.JavaDetection.windowTitle
    )

    let viewController = JavaDetectionViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
