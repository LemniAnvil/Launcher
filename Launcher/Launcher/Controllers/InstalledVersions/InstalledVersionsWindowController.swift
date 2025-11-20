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
      width: 400,
      height: 600,
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      minWidth: 350,
      minHeight: 400,
      title: Localized.InstalledVersions.windowTitle,
      handlesModalStop: false
    )

    let viewController = InstalledVersionsViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
