//
//  AccountInfoWindowController.swift
//  Launcher
//
//  Account information window controller
//

import AppKit
import Yatagarasu

class AccountInfoWindowController: BRWindowController {

  convenience init() {
    let configuration = BRWindowConfiguration(
      size: .medium,
      style: .modal,
      title: Localized.Account.accountInfoWindowTitle
    )

    let viewController = AccountInfoViewController()
    self.init(configuration: configuration, viewController: viewController)
  }
}
