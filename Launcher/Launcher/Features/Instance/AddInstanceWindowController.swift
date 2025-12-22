//
//  AddInstanceWindowController.swift
//  Launcher
//
//  Window controller for adding new instances
//

import AppKit
import Yatagarasu

class AddInstanceWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .xlargeHigh,
      style: .full,
      title: Localized.AddInstance.windowTitle
    )

    let viewController = AddInstanceViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
