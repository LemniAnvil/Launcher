//
//  InstanceDetailWindowController.swift
//  Launcher
//
//  Window controller for instance detail view
//

import AppKit
import Yatagarasu

class InstanceDetailWindowController: BRWindowController {

  convenience init(instance: Instance) {
    let configuration = BRWindowConfiguration(
      size: .medium,
      style: .modal,
      title: Localized.InstanceDetail.windowTitle,
      handlesModalStop: false
    )

    let viewController = InstanceDetailViewController(instance: instance)
    self.init(configuration: configuration, viewController: viewController)
  }
}
