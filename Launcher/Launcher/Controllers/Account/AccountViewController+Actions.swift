//
//  AccountViewController+Actions.swift
//  Launcher
//
//  Action methods for AccountViewController
//

import AppKit
import Yatagarasu

extension AccountViewController {
  // MARK: - Actions

  @objc func toggleDeveloperMode() {
    isDeveloperMode = developerModeSwitch.state == .on
    Logger.shared.info("Developer mode: \(isDeveloperMode)", category: "Account")
  }

  @objc func loginMicrosoft() {
    // Open Microsoft authentication window
    let authWindowController = MicrosoftAuthWindowController()
    authWindowController.window?.makeKeyAndOrderFront(nil)

    // Set up callbacks
    if let viewController = authWindowController.contentViewController as? MicrosoftAuthViewController {
      viewController.onAuthSuccess = { [weak self] response in
        guard let self = self else { return }

        // Convert skin and cape data from response
        let skins = response.skins?.compactMap { responseSkin -> Skin in
          Skin(
            id: responseSkin.id,
            state: responseSkin.state,
            url: responseSkin.url,
            variant: responseSkin.variant,
            alias: responseSkin.alias
          )
        }

        let capes = response.capes?.compactMap { responseCape -> Cape in
          Cape(
            id: responseCape.id,
            state: responseCape.state,
            url: responseCape.url,
            alias: responseCape.alias
          )
        }

        // Create account with all data including skins and capes
        let account = MicrosoftAccount(
          id: response.id,
          name: response.name,
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          timestamp: Date().timeIntervalSince1970,
          skins: skins,
          capes: capes
        )

        // Save account
        self.accountManager.saveAccount(account)
        self.loadAccounts()
        Logger.shared.info("Account added: \(response.name) with \(skins?.count ?? 0) skins and \(capes?.count ?? 0) capes", category: "Account")
      }

      viewController.onAuthFailure = { error in
        Logger.shared.error("Authentication failed: \(error.localizedDescription)", category: "Account")
      }
    }
  }

  @objc func addOfflineAccount() {
    let alert = NSAlert()
    alert.messageText = Localized.Account.offlineAccountTitle
    alert.informativeText = Localized.Account.offlineAccountMessage
    alert.alertStyle = .informational
    alert.addButton(withTitle: Localized.Account.addButton)
    alert.addButton(withTitle: Localized.Account.cancelButton)

    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
    textField.placeholderString = Localized.Account.offlineAccountPlaceholder
    alert.accessoryView = textField

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.processOfflineAccountAddition(username: textField.stringValue)
    }

    // Focus on text field
    alert.window.makeFirstResponder(textField)
  }

  func processOfflineAccountAddition(username: String) {
    // Validate username
    let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmedUsername.isEmpty {
      showAlert(title: Localized.Account.invalidUsernameTitle, message: Localized.Account.emptyUsernameMessage)
      return
    }

    if trimmedUsername.count < 3 || trimmedUsername.count > 16 {
      showAlert(title: Localized.Account.invalidUsernameTitle, message: Localized.Account.invalidUsernameLengthMessage)
      return
    }

    // Check if username contains only valid characters (letters, numbers, underscores)
    let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    if trimmedUsername.rangeOfCharacter(from: validCharacterSet.inverted) != nil {
      showAlert(title: Localized.Account.invalidUsernameTitle, message: Localized.Account.invalidUsernameFormatMessage)
      return
    }

    // Check for duplicates
    if offlineAccounts.contains(where: { $0.name.lowercased() == trimmedUsername.lowercased() }) {
      showAlert(title: Localized.Account.duplicateUsernameTitle, message: Localized.Account.duplicateUsernameMessage)
      return
    }

    // Generate UUID for the account
    let uuid = offlineAccountManager.generateUUID(for: trimmedUsername)

    // Create and save the offline account
    let account = OfflineAccount(
      id: uuid,
      name: trimmedUsername,
      timestamp: Date().timeIntervalSince1970
    )

    offlineAccountManager.saveAccount(account)
    loadAccounts()
    Logger.shared.info("Offline account added: \(trimmedUsername)", category: "Account")
  }

  // MARK: - Context Menu

  func createContextMenu() -> NSMenu {
    let menu = NSMenu()

    let refreshItem = NSMenuItem(
      title: Localized.Account.menuRefresh,
      action: #selector(refreshAccount(_:)),
      keyEquivalent: ""
    )
    refreshItem.target = self
    menu.addItem(refreshItem)

    menu.addItem(NSMenuItem.separator())

    let deleteItem = NSMenuItem(
      title: Localized.Account.menuDelete,
      action: #selector(deleteAccount(_:)),
      keyEquivalent: ""
    )
    deleteItem.target = self
    menu.addItem(deleteItem)

    return menu
  }

  @objc func refreshAccount(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < microsoftAccounts.count + offlineAccounts.count else {
      return
    }

    // Only Microsoft accounts can be refreshed
    if tableView.clickedRow >= microsoftAccounts.count {
      showAlert(
        title: Localized.Account.refreshFailedTitle,
        message: "Offline accounts cannot be refreshed"
      )
      return
    }

    let account = microsoftAccounts[tableView.clickedRow]

    Task { @MainActor in
      do {
        // Refresh the account using refresh token
        let authManager = MicrosoftAuthManager.shared
        let response = try await authManager.completeRefresh(refreshToken: account.refreshToken)

        // Convert skin and cape data from response
        let skins = response.skins?.compactMap { responseSkin -> Skin in
          Skin(
            id: responseSkin.id,
            state: responseSkin.state,
            url: responseSkin.url,
            variant: responseSkin.variant,
            alias: responseSkin.alias
          )
        }

        let capes = response.capes?.compactMap { responseCape -> Cape in
          Cape(
            id: responseCape.id,
            state: responseCape.state,
            url: responseCape.url,
            alias: responseCape.alias
          )
        }

        // Save the refreshed account data with skins and capes
        accountManager.updateAccountFromRefresh(
          id: response.id,
          name: response.name,
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          skins: skins,
          capes: capes
        )

        Logger.shared.info("Account refreshed: \(response.name) with \(skins?.count ?? 0) skins and \(capes?.count ?? 0) capes", category: "Account")
        loadAccounts()

        showAlert(
          title: Localized.Account.refreshSuccessTitle,
          message: Localized.Account.refreshSuccessMessage(response.name)
        )
      } catch {
        Logger.shared.error("Refresh failed: \(error.localizedDescription)", category: "Account")
        showAlert(
          title: Localized.Account.refreshFailedTitle,
          message: error.localizedDescription
        )
      }
    }
  }

  @objc func deleteAccount(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < microsoftAccounts.count + offlineAccounts.count else {
      return
    }

    let rowToDelete = tableView.clickedRow
    let isMicrosoftAccount = rowToDelete < microsoftAccounts.count

    let accountName: String
    let accountId: String
    let isOffline: Bool

    if isMicrosoftAccount {
      let account = microsoftAccounts[rowToDelete]
      accountName = account.name
      accountId = account.id
      isOffline = false
    } else {
      let account = offlineAccounts[rowToDelete - microsoftAccounts.count]
      accountName = account.name
      accountId = account.id
      isOffline = true
    }

    let alert = NSAlert()
    alert.messageText = Localized.Account.deleteConfirmTitle
    alert.informativeText = Localized.Account.deleteAccountConfirmMessage(accountName)
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Account.deleteButton)
    alert.addButton(withTitle: Localized.Account.cancelButton)

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.performDelete(accountId: accountId, isOffline: isOffline)
    }
  }

  func performDelete(accountId: String, isOffline: Bool) {
    if isOffline {
      offlineAccountManager.deleteAccount(id: accountId)
    } else {
      accountManager.deleteAccount(id: accountId)
    }
    loadAccounts()
    Logger.shared.info("Deleted account: \(accountId)", category: "Account")
  }

  func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Account.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}
