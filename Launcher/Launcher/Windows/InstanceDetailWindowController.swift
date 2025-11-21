//
//  InstanceDetailWindowController.swift
//  Launcher
//
//  Window controller for instance detail view
//

import AppKit

class InstanceDetailWindowController: BaseWindowController {

  convenience init(instance: Instance) {
    let configuration = WindowConfiguration(
      size: .medium,
      style: .modal,
      title: Localized.InstanceDetail.windowTitle,
      handlesModalStop: false
    )

    let viewController = InstanceDetailViewController(instance: instance)
    self.init(configuration: configuration, viewController: viewController)
  }
}
