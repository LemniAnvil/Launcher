//
//  VersionListWindowController.swift
//  Launcher
//
//  Version list window controller
//

import AppKit
import Yatagarasu

class VersionListWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .xlarge,
      style: .modal,
      title: Localized.Instances.createInstanceTitle,
      handlesModalStop: false
    )

    let viewController = VersionListViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
