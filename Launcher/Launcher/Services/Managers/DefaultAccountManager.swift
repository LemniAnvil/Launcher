//
//  DefaultAccountManager.swift
//  Launcher
//
//  Manages default account selection for automatic game launch
//

import CraftKit
import Foundation

/// Manager for handling default account settings
class DefaultAccountManager: DefaultAccountManaging {
  static let shared = DefaultAccountManager()

  private let defaultAccountSelectionKey = "DefaultAccountSelection"

  private let userDefaults: UserDefaults
  private let microsoftAccountStore: MicrosoftAccountStoring
  private let offlineAccountStore: OfflineAccountStoring
  private let authManager: MicrosoftAuthProtocol
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  private init(
    userDefaults: UserDefaults = .standard,
    microsoftAccountStore: MicrosoftAccountStoring = MicrosoftAccountManager.shared,
    offlineAccountStore: OfflineAccountStoring = OfflineAccountManager.shared,
    authManager: MicrosoftAuthProtocol = MicrosoftAuthManager.shared
  ) {
    self.userDefaults = userDefaults
    self.microsoftAccountStore = microsoftAccountStore
    self.offlineAccountStore = offlineAccountStore
    self.authManager = authManager
  }

  private struct DefaultAccountSelection: Codable, Equatable {
    let id: String
    let type: DefaultAccountType
  }

  // MARK: - Public Methods

  /// Set default account
  func setDefaultAccount(id: String, type: DefaultAccountType) {
    let selection = DefaultAccountSelection(id: id, type: type)
    saveSelection(selection)

    Logger.shared.info("Default account set: \(id) (\(type.rawValue))", category: "DefaultAccount")
  }

  /// Get default account ID
  func getDefaultAccountId() -> String? {
    return loadSelection()?.id
  }

  /// Get default account type
  func getDefaultAccountType() -> DefaultAccountType? {
    return loadSelection()?.type
  }

  /// Clear default account
  func clearDefaultAccount() {
    userDefaults.removeObject(forKey: defaultAccountSelectionKey)
    Logger.shared.info("Default account cleared", category: "DefaultAccount")
  }

  /// Check if specific account is default
  func isDefaultAccount(id: String, type: DefaultAccountType) -> Bool {
    return loadSelection() == DefaultAccountSelection(id: id, type: type)
  }

  /// Get default account info for launching game
  /// - Returns: Account info tuple, or nil if account not found or refresh failed
  func getDefaultAccountInfo() async -> (username: String, uuid: String, accessToken: String)? {
    guard let selection = loadSelection() else {
      return nil
    }

    switch selection.type {
    case .microsoft:
      guard let account = microsoftAccountStore.getAccount(id: selection.id) else {
        // Account was deleted, clear default setting
        Logger.shared.warning("Default Microsoft account not found, clearing default", category: "DefaultAccount")
        clearDefaultAccount()
        return nil
      }

      // Check if account is expired and attempt to refresh
      if account.isExpired {
        Logger.shared.warning("Default Microsoft account is expired: \(account.name), attempting to refresh", category: "DefaultAccount")

        do {
          // Attempt to refresh the account
          let refreshedResponse = try await authManager.completeRefresh(
            refreshToken: account.refreshToken
          )

          // Convert skin and cape data from response
          let skins = refreshedResponse.skins?.compactMap { responseSkin -> SkinResponse in
            SkinResponse(
              id: responseSkin.id,
              state: responseSkin.state.rawValue,
              url: responseSkin.url,
              variant: responseSkin.variant ?? "CLASSIC",
              alias: responseSkin.alias
            )
          }

          let capes = refreshedResponse.capes?.compactMap { responseCape -> Cape in
            Cape(
              id: responseCape.id,
              state: responseCape.state.rawValue,
              url: responseCape.url,
              alias: responseCape.alias
            )
          }

          // Update the account with refreshed data
          microsoftAccountStore.updateAccountFromRefresh(
            id: refreshedResponse.id,
            name: refreshedResponse.name,
            accessToken: refreshedResponse.accessToken,
            refreshToken: refreshedResponse.refreshToken,
            skins: skins,
            capes: capes
          )

          Logger.shared.info("Successfully refreshed expired default account: \(refreshedResponse.name)", category: "DefaultAccount")

          // Return the refreshed account info
          return (
            username: refreshedResponse.name, uuid: refreshedResponse.id,
            accessToken: refreshedResponse.accessToken
          )
        } catch {
          Logger.shared.error("Failed to refresh expired default account: \(error.localizedDescription)", category: "DefaultAccount")
          // Clear the default account since refresh failed
          clearDefaultAccount()
          return nil
        }
      }

      return (username: account.name, uuid: account.id, accessToken: account.accessToken)

    case .offline:
      guard let account = offlineAccountStore.getAccount(id: selection.id) else {
        // Account was deleted, clear default setting
        Logger.shared.warning("Default offline account not found, clearing default", category: "DefaultAccount")
        clearDefaultAccount()
        return nil
      }
      return (username: account.name, uuid: account.id, accessToken: account.accessToken)
    }
  }

  // MARK: - Persistence / Migration

  private func saveSelection(_ selection: DefaultAccountSelection) {
    do {
      let data = try encoder.encode(selection)
      userDefaults.set(data, forKey: defaultAccountSelectionKey)
    } catch {
      Logger.shared.error("Failed to encode default account selection: \(error.localizedDescription)", category: "DefaultAccount")
      userDefaults.removeObject(forKey: defaultAccountSelectionKey)
    }
  }

  private func loadSelection() -> DefaultAccountSelection? {
    guard let data = userDefaults.data(forKey: defaultAccountSelectionKey) else {
      return nil
    }

    do {
      let selection = try decoder.decode(DefaultAccountSelection.self, from: data)
      return validateSelection(selection)
    } catch {
      Logger.shared.warning("Invalid default account selection data, clearing", category: "DefaultAccount")
      userDefaults.removeObject(forKey: defaultAccountSelectionKey)
      return nil
    }
  }

  private func validateSelection(_ selection: DefaultAccountSelection) -> DefaultAccountSelection? {
    guard !selection.id.isEmpty else {
      Logger.shared.warning("Default account selection has empty id, clearing", category: "DefaultAccount")
      clearDefaultAccount()
      return nil
    }
    return selection
  }
}
