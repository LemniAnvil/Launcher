//
//  AccountWindowController.swift
//  Launcher
//
//  Account management window controller
//

import AppKit
import Yatagarasu

class AccountWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .small,
      style: .modal,
      title: Localized.Account.windowTitle
    )

    let viewController = AccountViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
