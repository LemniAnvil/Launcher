//
//  CreateInstanceWindowController.swift
//  Launcher
//
//  Window controller for creating new instance
//

import AppKit
import Yatagarasu

class CreateInstanceWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
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
