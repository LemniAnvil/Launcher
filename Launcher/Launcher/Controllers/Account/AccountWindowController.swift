//
//  AccountWindowController.swift
//  Launcher
//
//  Account management window controller
//

import AppKit

class AccountWindowController: BaseWindowController {

  convenience init() {
    let configuration = WindowConfiguration(
      width: 400,
      height: 500,
      styleMask: [.titled, .closable],
      minWidth: 350,
      minHeight: 400,
      title: Localized.Account.windowTitle
    )

    let viewController = AccountViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
