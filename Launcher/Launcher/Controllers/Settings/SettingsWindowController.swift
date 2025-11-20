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
      width: 500,
      height: 400,
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      minWidth: 450,
      minHeight: 350,
      title: Localized.Settings.windowTitle
    )

    let viewController = SettingsViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
