//
//  CreateInstanceWindowController.swift
//  Launcher
//
//  Window controller for creating new instance
//

import AppKit

class CreateInstanceWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      width: 1000,
      height: 680,
      styleMask: [.titled, .closable],
      title: Localized.Instances.createInstanceTitle,
      handlesModalStop: false
    )

    let viewController = CreateInstanceViewController()
    self.init(configuration: configuration, viewController: viewController)
  }

  override func close() {
    window?.close()
  }
}
