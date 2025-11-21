//
//  AddInstanceWindowController.swift
//  Launcher
//
//  Window controller for adding new instances
//

import AppKit

class AddInstanceWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      size: .xlargeHigh,
      style: .full,
      title: Localized.AddInstance.windowTitle
    )

    let viewController = AddInstanceViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
