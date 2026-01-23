//
//  AccountInfoViewController+SkinManagement.swift
//  Launcher
//
//  Skin management API integration using CraftKit
//

import AppKit
import CraftKit
import Foundation

extension AccountInfoViewController {

  // MARK: - Skin Upload

  /// Upload a local skin to the selected account
  func uploadSkinToAccount(_ skin: LauncherSkinAsset, variant: SkinVariant) async throws {
    print("📤 Starting skin upload: \(skin.name)")

    // 1. Validate account selection
    guard let account = selectedAccount else {
      print("❌ No account selected")
      throw SkinManagementError.noAccountSelected
    }
    print("✓ Account: \(account.name) (UUID: \(account.id))")

    // 2. Read skin file
    let imageData = try Data(contentsOf: skin.fileURL)
    print("✓ Skin file read: \(imageData.count) bytes")

    // 3. Validate skin file
    let dimensions = try SkinValidator.validate(imageData)
    print("✓ Validation passed: \(dimensions.width)x\(dimensions.height)")

    // 4. Refresh token if needed
    let validToken = try await refreshTokenIfNeeded(account)
    print("✓ Token ready (length: \(validToken.count))")

    // 5. Create CraftKit client
    let client = MinecraftAuthenticatedClient(bearerToken: validToken)
    print("✓ CraftKit client created")

    // 6. Upload skin
    print("📤 Uploading to Minecraft API with variant: \(variant.rawValue)...")
    do {
      try await client.uploadSkin(imageData: imageData, variant: variant)
      print("✅ Skin uploaded successfully!")
    } catch {
      print("❌ Upload failed: \(error)")
      throw error
    }

    // 7. Refresh account profile
    print("🔄 Refreshing account profile...")
    await refreshAccountProfile(account)

    // 8. Update UI
    await MainActor.run {
      showSuccessAlert(message: Localized.Account.skinUploadSuccess)
      // Switch to account info tab to see the new skin
      tabView.selectTabViewItem(at: 0)
      print("✅ Upload complete!")
    }
  }

  // MARK: - Skin Activation

  /// Activate a skin from the account's skin library
  func activateSkin(_ skin: SkinResponse) async throws {
    guard let account = selectedAccount else {
      throw SkinManagementError.noAccountSelected
    }

    let validToken = try await refreshTokenIfNeeded(account)
    let client = MinecraftAuthenticatedClient(bearerToken: validToken)

    // Parse skin URL
    guard let url = URL(string: skin.url) else {
      throw SkinManagementError.invalidURL
    }

    // Determine variant
    let variant: SkinVariant = skin.variant.uppercased() == "SLIM" ? .slim : .classic

    // Change skin
    try await client.changeSkin(url: url, variant: variant)

    // Refresh profile
    await refreshAccountProfile(account)
  }

  // MARK: - Skin Reset

  /// Reset to default skin
  func resetToDefaultSkin() async throws {
    guard let account = selectedAccount else {
      throw SkinManagementError.noAccountSelected
    }

    let validToken = try await refreshTokenIfNeeded(account)
    let client = MinecraftAuthenticatedClient(bearerToken: validToken)

    try await client.resetSkin()
    await refreshAccountProfile(account)
  }

  // MARK: - Skin Download

  /// Download a skin from account to local library
  func downloadSkinToLibrary(_ skin: SkinResponse) async throws {
    guard let url = URL(string: skin.url) else {
      throw SkinManagementError.invalidURL
    }

    // Download skin data
    let (data, _) = try await URLSession.shared.data(from: url)

    // Generate filename
    let name = skin.alias ?? "skin_\(skin.id.prefix(8))"

    // Save to library
    let library = SkinLibrary()
    _ = try library.saveSkin(named: name, data: data)

    await MainActor.run {
      showSuccessAlert(message: Localized.Account.skinDownloadSuccess)
      // Refresh skin library view
      skinLibraryView.loadSkins()
    }
  }

  // MARK: - Token Management

  /// Refresh token if it's about to expire (within 5 minutes)
  func refreshTokenIfNeeded(_ account: MicrosoftAccount) async throws -> String {
    // Check if token will expire within 5 minutes (300 seconds)
    // Token expires 24 hours after timestamp
    let expirationTime = account.timestamp + AuthConstants.tokenExpirationSeconds
    let currentTime = Date().timeIntervalSince1970
    let needsRefresh = currentTime > (expirationTime - 300)

    // Debug logging
    print("🔐 Token Check:")
    print("  Current time: \(Date(timeIntervalSince1970: currentTime))")
    print("  Token timestamp: \(Date(timeIntervalSince1970: account.timestamp))")
    print("  Token expires at: \(Date(timeIntervalSince1970: expirationTime))")
    print("  Needs refresh: \(needsRefresh)")

    if needsRefresh {
      print("🔄 Refreshing token...")
      let response = try await MicrosoftAuthManager.shared.completeRefresh(
        refreshToken: account.refreshToken
      )

      // Convert skins and capes from SkinInfo/CapeInfo to SkinResponse/Cape
      let skins = response.skins?.map { skinInfo -> SkinResponse in
        SkinResponse(
          id: skinInfo.id,
          state: skinInfo.state.rawValue,
          url: skinInfo.url,
          variant: skinInfo.variant ?? "CLASSIC",
          alias: skinInfo.alias
        )
      }

      let capes = response.capes?.map { capeInfo -> Cape in
        Cape(
          id: capeInfo.id,
          state: capeInfo.state.rawValue,
          url: capeInfo.url,
          alias: capeInfo.alias
        )
      }

      // Update stored account
      MicrosoftAccountManager.shared.updateAccountFromRefresh(
        id: account.id,
        name: account.name,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        skins: skins,
        capes: capes
      )

      print("✅ Token refreshed successfully")
      return response.accessToken
    }

    print("✅ Using existing token (still valid)")
    return account.accessToken
  }

  // MARK: - Profile Refresh

  /// Refresh account profile to get latest skins/capes
  func refreshAccountProfile(_ account: MicrosoftAccount) async {
    do {
      let validToken = try await refreshTokenIfNeeded(account)
      let client = MinecraftAuthenticatedClient(bearerToken: validToken)
      let profile = try await client.getProfile()

      // Convert profile data to app models
      let skins = profile.skins.map { convertToSkinResponse($0) }
      let capes = profile.capes.map { convertToCape($0) }

      // Update account
      MicrosoftAccountManager.shared.updateAccountFromRefresh(
        id: account.id,
        name: account.name,
        accessToken: validToken,
        refreshToken: account.refreshToken,
        skins: skins,
        capes: capes
      )

      // Refresh UI
      await MainActor.run {
        loadAccounts()
        if let updatedAccount = accounts.first(where: { $0.id == account.id }) {
          showAccountDetails(updatedAccount)
        }
      }
    } catch {
      await MainActor.run {
        showErrorAlert(error)
      }
    }
  }

  // MARK: - Conversion Helpers

  private func convertToSkinResponse(_ skin: AccountSkin) -> SkinResponse {
    return SkinResponse(
      id: skin.id,
      state: skin.state.rawValue,
      url: skin.url,
      variant: skin.variant.rawValue,
      alias: skin.alias
    )
  }

  private func convertToCape(_ cape: AccountCape) -> Cape {
    return Cape(
      id: cape.id,
      state: cape.state.rawValue,
      url: cape.url,
      alias: cape.alias
    )
  }

  // MARK: - UI Helpers

  func showSuccessAlert(message: String) {
    let alert = NSAlert()
    alert.messageText = Localized.Account.success
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: Localized.Common.ok)
    alert.runModal()
  }

  func showErrorAlert(_ error: Error) {
    let alert = NSAlert()
    alert.messageText = Localized.Account.error
    alert.informativeText = error.localizedDescription

    if let localizedError = error as? LocalizedError,
       let suggestion = localizedError.recoverySuggestion {
      alert.informativeText += "\n\n" + suggestion
    }

    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Common.ok)
    alert.runModal()
  }

  func showConfirmationAlert(
    title: String,
    message: String,
    completion: @escaping (Bool) -> Void
  ) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Common.confirm)
    alert.addButton(withTitle: Localized.Common.cancel)

    let response = alert.runModal()
    completion(response == .alertFirstButtonReturn)
  }
}
