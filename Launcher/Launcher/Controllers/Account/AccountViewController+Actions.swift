//
//  AccountViewController+Actions.swift
//  Launcher
//
//  Action methods for AccountViewController
//

import AppKit
import MojangAPI
import Yatagarasu

// MARK: - Mojang Username API Response Models

private struct MojangUsernameResponse: Codable {
  let id: String
  let name: String
}

extension AccountViewController {
  // MARK: - Actions

  @objc func toggleDeveloperMode() {
    isDeveloperMode = developerModeSwitch.state == .on
    Logger.shared.info("Developer mode: \(isDeveloperMode)", category: "Account")
  }

  @objc func loginMicrosoft() {
    // Directly start the authentication flow without opening a separate window
    Task { @MainActor in
      await performMicrosoftLogin()
    }
  }

  // MARK: - Microsoft Authentication

  private func performMicrosoftLogin() async {
    do {
      // Step 1: Generate login URL
      loginData = try authManager.getSecureLoginData()

      guard let loginData = loginData else {
        throw MicrosoftAuthError.invalidURL
      }

      Logger.shared.info("Generated login URL", category: "MicrosoftAuth")

      // Set up callback handler for when the app receives the URL
      AppDelegate.pendingAuthCallback = { [weak self] callbackURL in
        Task { @MainActor in
          await self?.handleMicrosoftCallback(callbackURL)
        }
      }

      // Step 2: Open browser for user authentication
      guard let url = URL(string: loginData.url) else {
        throw MicrosoftAuthError.invalidURL
      }

      NSWorkspace.shared.open(url)
      Logger.shared.info("Opened browser for Microsoft authentication", category: "MicrosoftAuth")
    } catch {
      Logger.shared.error("Login failed: \(error.localizedDescription)", category: "MicrosoftAuth")
      showAlert(
        title: Localized.MicrosoftAuth.alertLoginFailedTitle,
        message: Localized.MicrosoftAuth.alertLoginFailedMessage(error.localizedDescription)
      )
    }
  }

  private func handleMicrosoftCallback(_ callbackURL: String) async {
    guard let loginData = loginData else {
      Logger.shared.error("Login data not found", category: "MicrosoftAuth")
      return
    }

    do {
      // Step 3: Parse authorization code
      let authCode = try authManager.parseAuthCodeURL(callbackURL, expectedState: loginData.state)
      Logger.shared.info("Authorization code received", category: "MicrosoftAuth")

      // Show status view
      refreshStatusView.startLogin(accountName: "Microsoft Account")

      // Step 4-7: Complete login flow with progress tracking
      let loginResponse = try await authManager.completeLoginWithProgress(
        authCode: authCode,
        codeVerifier: loginData.codeVerifier
      ) { [weak self] (step: MicrosoftAuthManager.LoginStep) in
        // Update status view based on login step
        let statusStep: AccountRefreshStatusView.LoginStep
        switch step {
        case .gettingToken:
          statusStep = .gettingToken
        case .authenticatingXBL:
          statusStep = .authenticatingXBL
        case .authenticatingXSTS:
          statusStep = .authenticatingXSTS
        case .authenticatingMinecraft:
          statusStep = .authenticatingMinecraft
        case .fetchingProfile:
          statusStep = .fetchingProfile
        case .savingAccount:
          statusStep = .savingAccount
        case .completed:
          statusStep = .completed
        }
        self?.refreshStatusView.updateLoginStep(statusStep)
      }

      Logger.shared.info("Login successful: \(loginResponse.name)", category: "MicrosoftAuth")

      // Convert skin and cape data from response
      let skins = loginResponse.skins?.compactMap { responseSkin -> Skin in
        Skin(
          id: responseSkin.id,
          state: responseSkin.state,
          url: responseSkin.url,
          variant: responseSkin.variant ?? "CLASSIC",
          alias: responseSkin.alias
        )
      }

      let capes = loginResponse.capes?.compactMap { responseCape -> Cape in
        Cape(
          id: responseCape.id,
          state: responseCape.state,
          url: responseCape.url,
          alias: responseCape.alias
        )
      }

      // Create account with all data including skins and capes
      let account = MicrosoftAccount(
        id: loginResponse.id,
        name: loginResponse.name,
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        timestamp: Date().timeIntervalSince1970,
        skins: skins,
        capes: capes
      )

      // Save account
      refreshStatusView.updateLoginStep(.savingAccount)
      accountManager.saveAccount(account)
      loadAccounts()
      Logger.shared.info(
        "Account added: \(loginResponse.name) with \(skins?.count ?? 0) skins and \(capes?.count ?? 0) capes",
        category: "Account"
      )

      // Show completion
      refreshStatusView.updateLoginStep(.completed)

      // Show success alert
      showAlert(
        title: Localized.MicrosoftAuth.alertSuccessTitle,
        message: Localized.MicrosoftAuth.alertSuccessMessage(loginResponse.name, loginResponse.id)
      )
    } catch {
      Logger.shared.error(
        "Callback handling failed: \(error.localizedDescription)", category: "MicrosoftAuth"
      )
      refreshStatusView.updateLoginStep(.failed(error.localizedDescription))
      showAlert(
        title: Localized.MicrosoftAuth.alertLoginFailedTitle,
        message: Localized.MicrosoftAuth.alertLoginFailedMessage(error.localizedDescription)
      )
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
      showAlert(
        title: Localized.Account.invalidUsernameTitle,
        message: Localized.Account.emptyUsernameMessage
      )
      return
    }

    if trimmedUsername.count < 3 || trimmedUsername.count > 16 {
      showAlert(
        title: Localized.Account.invalidUsernameTitle,
        message: Localized.Account.invalidUsernameLengthMessage
      )
      return
    }

    // Check if username contains only valid characters (letters, numbers, underscores)
    let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    if trimmedUsername.rangeOfCharacter(from: validCharacterSet.inverted) != nil {
      showAlert(
        title: Localized.Account.invalidUsernameTitle,
        message: Localized.Account.invalidUsernameFormatMessage
      )
      return
    }

    // Check for duplicates
    if offlineAccounts.contains(where: { $0.name.lowercased() == trimmedUsername.lowercased() }) {
      showAlert(
        title: Localized.Account.duplicateUsernameTitle,
        message: Localized.Account.duplicateUsernameMessage
      )
      return
    }

    // Validate username against Mojang API to get correct capitalization
    validateUsernameWithMojang(trimmedUsername) { [weak self] validatedUsername in
      guard let self = self else { return }

      DispatchQueue.main.async {
        // Use the validated username (with correct capitalization) or the original if validation fails
        let finalUsername = validatedUsername ?? trimmedUsername

        // Generate UUID for the account
        let uuid = self.offlineAccountManager.generateUUID(for: finalUsername)

        // Create and save the offline account
        let account = OfflineAccount(
          id: uuid,
          name: finalUsername,
          timestamp: Date().timeIntervalSince1970
        )

        self.offlineAccountManager.saveAccount(account)
        self.loadAccounts()
        Logger.shared.info(
          "Offline account added: \(finalUsername)\(validatedUsername != nil ? " (validated)" : "")",
          category: "Account"
        )
      }
    }
  }

  // MARK: - Username Validation

  /// Validates username against Mojang API to get correct capitalization
  /// - Parameters:
  ///   - username: The username to validate
  ///   - completion: Completion handler with validated username (nil if not found or error)
  private func validateUsernameWithMojang(
    _ username: String,
    completion: @escaping (String?) -> Void
  ) {
    // Try both Mojang API endpoints
    // 1. First try the modern endpoint
    let modernURL = "https://api.minecraftservices.com/minecraft/profile/lookup/name/\(username)"

    validateUsernameAtEndpoint(modernURL) { validatedName in
      if let validatedName = validatedName {
        completion(validatedName)
      } else {
        // 2. Fallback to legacy endpoint if modern fails
        let legacyURL = "https://api.mojang.com/users/profiles/minecraft/\(username)"
        self.validateUsernameAtEndpoint(legacyURL) { legacyValidatedName in
          completion(legacyValidatedName)
        }
      }
    }
  }

  private func validateUsernameAtEndpoint(
    _ urlString: String,
    completion: @escaping (String?) -> Void
  ) {
    guard let url = URL(string: urlString) else {
      completion(nil)
      return
    }

    URLSession.shared.dataTask(with: url) { data, response, error in
      // Check for errors or invalid response
      guard let data = data,
        error == nil,
        let httpResponse = response as? HTTPURLResponse
      else {
        completion(nil)
        return
      }

      // 200: Username found
      // 204/404: Username not found (not a registered Minecraft account)
      if httpResponse.statusCode == 200 {
        if let mojangResponse = try? JSONDecoder().decode(MojangUsernameResponse.self, from: data) {
          // Username exists on Mojang servers - use the correctly capitalized name
          completion(mojangResponse.name)
        } else {
          completion(nil)
        }
      } else {
        // Username not found or error - this is okay for offline mode
        // User can still use any username they want
        completion(nil)
      }
    }
    .resume()
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
      tableView.clickedRow < microsoftAccounts.count + offlineAccounts.count
    else {
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

    // Show status view
    refreshStatusView.startRefresh(accountName: account.name)

    Task { @MainActor in
      do {
        // Refresh the account using refresh token with progress callbacks
        let authManager = MicrosoftAuthManager.shared
        let response = try await authManager.completeRefreshWithProgress(
          refreshToken: account.refreshToken
        ) { [weak self] step in
          // Update status view based on refresh step
          let statusStep: AccountRefreshStatusView.RefreshStep
          switch step {
          case .refreshingToken:
            statusStep = .refreshingToken
          case .authenticatingXBL:
            statusStep = .authenticatingXBL
          case .authenticatingXSTS:
            statusStep = .authenticatingXSTS
          case .authenticatingMinecraft:
            statusStep = .authenticatingMinecraft
          case .fetchingProfile:
            statusStep = .fetchingProfile
          case .completed:
            statusStep = .savingAccount
          }
          self?.refreshStatusView.updateStep(statusStep)
        }

        // Convert skin and cape data from response
        let skins = response.skins?.compactMap { responseSkin -> Skin in
          Skin(
            id: responseSkin.id,
            state: responseSkin.state,
            url: responseSkin.url,
            variant: responseSkin.variant ?? "CLASSIC",
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
        refreshStatusView.updateStep(.savingAccount)
        accountManager.updateAccountFromRefresh(
          id: response.id,
          name: response.name,
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          skins: skins,
          capes: capes
        )

        Logger.shared.info(
          "Account refreshed: \(response.name) with \(skins?.count ?? 0) skins and \(capes?.count ?? 0) capes",
          category: "Account"
        )
        loadAccounts()

        // Show completion
        refreshStatusView.updateStep(.completed)
      } catch {
        Logger.shared.error("Refresh failed: \(error.localizedDescription)", category: "Account")
        refreshStatusView.updateStep(.failed(error.localizedDescription))
      }
    }
  }

  @objc func deleteAccount(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
      tableView.clickedRow < microsoftAccounts.count + offlineAccounts.count
    else {
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
