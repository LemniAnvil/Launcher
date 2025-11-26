//
//  AccountViewController+TableView.swift
//  Launcher
//
//  TableView DataSource and Delegate for AccountViewController
//

import AppKit
import SnapKit
import Yatagarasu

// MARK: - NSTableViewDataSource

extension AccountViewController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return microsoftAccounts.count + offlineAccounts.count
  }
}

// MARK: - NSTableViewDelegate

extension AccountViewController: NSTableViewDelegate {

  func tableView(
    _ tableView: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int
  ) -> NSView? {
    // Create custom cell view
    let cellView = AccountCellView()

    // Determine account type and check if default
    let accountType: AccountCellView.AccountType
    let isDefault: Bool
    let defaultManager = DefaultAccountManager.shared

    if row < microsoftAccounts.count {
      let account = microsoftAccounts[row]
      accountType = .microsoft(account)
      isDefault = defaultManager.isDefaultAccount(id: account.id, type: .microsoft)
    } else {
      let account = offlineAccounts[row - microsoftAccounts.count]
      accountType = .offline(account)
      isDefault = defaultManager.isDefaultAccount(id: account.id, type: .offline)
    }

    // Configure cell
    cellView.configure(with: accountType, isDeveloperMode: isDeveloperMode, isDefault: isDefault)

    // Set initial highlight state
    cellView.setHighlighted(tableView.selectedRow == row)

    return cellView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    // Update all visible cells to reflect selection state
    let totalRows = microsoftAccounts.count + offlineAccounts.count
    for row in 0..<totalRows {
      if let cellView = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? AccountCellView {
        cellView.setHighlighted(row == tableView.selectedRow)
      }
    }

    // Log selection
    if tableView.selectedRow >= 0 {
      let accountName: String
      if tableView.selectedRow < microsoftAccounts.count {
        accountName = microsoftAccounts[tableView.selectedRow].name
      } else {
        accountName = offlineAccounts[tableView.selectedRow - microsoftAccounts.count].name
      }
      Logger.shared.info("Selected account: \(accountName)", category: "Account")
    }
  }
}
