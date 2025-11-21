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
      size: .small,
      style: .modal,
      title: Localized.Account.windowTitle
    )

    let viewController = AccountViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
