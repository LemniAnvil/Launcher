//
//  SettingsWindowController.swift
//  Launcher
//
//  Settings window controller
//

import AppKit

class SettingsWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      size: .smallWide,
      style: .full,
      title: Localized.Settings.windowTitle
    )

    let viewController = SettingsTabViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
