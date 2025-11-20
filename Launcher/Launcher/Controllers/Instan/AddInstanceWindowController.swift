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
      width: 1000,
      height: 700,
      styleMask: [.titled, .closable, .resizable],
      minWidth: 900,
      minHeight: 600,
      title: Localized.AddInstance.windowTitle
    )

    let viewController = AddInstanceViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
