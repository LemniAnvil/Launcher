//
//  MicrosoftAuthWindowController.swift
//  Launcher
//
//  Microsoft authentication window controller
//

import AppKit
import Yatagarasu

class MicrosoftAuthWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .mediumWide,
      style: .full,
      title: Localized.MicrosoftAuth.windowTitle,
      handlesModalStop: false
    )

    let viewController = MicrosoftAuthViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
