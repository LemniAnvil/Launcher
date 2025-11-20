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
      height: 500,
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      minWidth: 450,
      minHeight: 400,
      title: Localized.Settings.windowTitle
    )

    let viewController = SettingsTabViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
