//
//  InstalledVersionsWindowController.swift
//  Launcher
//
//  Installed versions list window controller
//

import AppKit
import Yatagarasu

class InstalledVersionsWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .smallTall,
      style: .full,
      title: Localized.InstalledVersions.windowTitle,
      handlesModalStop: false
    )

    let viewController = InstalledVersionsViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
