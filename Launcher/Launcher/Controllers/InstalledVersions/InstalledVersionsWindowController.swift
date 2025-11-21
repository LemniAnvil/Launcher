//
//  InstalledVersionsWindowController.swift
//  Launcher
//
//  Installed versions list window controller
//

import AppKit

class InstalledVersionsWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      size: .smallTall,
      style: .full,
      title: Localized.InstalledVersions.windowTitle,
      handlesModalStop: false
    )

    let viewController = InstalledVersionsViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
