//
//  SettingsWindowController.swift
//  Launcher
//
//  Settings window controller
//

import AppKit
import Yatagarasu

class SettingsWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .smallWide,
      style: .full,
      title: Localized.Settings.windowTitle
    )

    let viewController = SettingsTabViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
