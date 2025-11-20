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
      width: 1000,
      height: 680,
      styleMask: [.titled, .closable],
      minWidth: 900,
      minHeight: 600,
      title: Localized.Instances.createInstanceTitle,
      handlesModalStop: false
    )

    let viewController = VersionListViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
