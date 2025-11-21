//
//  MicrosoftAuthWindowController.swift
//  Launcher
//
//  Microsoft authentication window controller
//

import AppKit

class MicrosoftAuthWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      size: .mediumWide,
      style: .full,
      title: Localized.MicrosoftAuth.windowTitle,
      handlesModalStop: false
    )

    let viewController = MicrosoftAuthViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
