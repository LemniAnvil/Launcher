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
      width: 600,
      height: 700,
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      minWidth: 500,
      minHeight: 600,
      title: Localized.MicrosoftAuth.windowTitle,
      handlesModalStop: false
    )

    let viewController = MicrosoftAuthViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
