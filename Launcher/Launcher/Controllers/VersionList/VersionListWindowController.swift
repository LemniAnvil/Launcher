//
//  VersionListWindowController.swift
//  Launcher
//
//  Version list window controller
//

import AppKit

class VersionListWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      size: .xlarge,
      style: .modal,
      title: Localized.Instances.createInstanceTitle,
      handlesModalStop: false
    )

    let viewController = VersionListViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
