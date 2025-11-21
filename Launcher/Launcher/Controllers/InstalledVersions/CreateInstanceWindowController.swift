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
      size: .xlarge,
      style: .modal,
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
