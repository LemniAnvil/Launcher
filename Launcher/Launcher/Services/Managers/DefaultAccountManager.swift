//
//  DefaultAccountManager.swift
//  Launcher
//
//  Manages default account selection for automatic game launch
//

import Foundation

/// Manager for handling default account settings
class DefaultAccountManager {
  static let shared = DefaultAccountManager()

  private let defaultAccountSelectionKey = "DefaultAccountSelection"
  private let defaultAccountIdKey = "DefaultAccountId"
  private let defaultAccountTypeKey = "DefaultAccountType"

  private let userDefaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  private init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  /// Account type enumeration
  enum AccountType: String, Codable {
    case microsoft = "microsoft"
    case offline = "offline"
  }

  private struct DefaultAccountSelection: Codable, Equatable {
    let id: String
    let type: AccountType
  }

  // MARK: - Public Methods

  /// Set default account
  func setDefaultAccount(id: String, type: AccountType) {
    let selection = DefaultAccountSelection(id: id, type: type)
    saveSelection(selection)

    // Backwards compatible storage (can be removed after one or two releases).
    userDefaults.set(id, forKey: defaultAccountIdKey)
    userDefaults.set(type.rawValue, forKey: defaultAccountTypeKey)

    Logger.shared.info("Default account set: \(id) (\(type.rawValue))", category: "DefaultAccount")
  }

  /// Get default account ID
  func getDefaultAccountId() -> String? {
    return loadSelection()?.id
  }

  /// Get default account type
  func getDefaultAccountType() -> AccountType? {
    return loadSelection()?.type
  }

  /// Clear default account
  func clearDefaultAccount() {
    userDefaults.removeObject(forKey: defaultAccountSelectionKey)
    userDefaults.removeObject(forKey: defaultAccountIdKey)
    userDefaults.removeObject(forKey: defaultAccountTypeKey)
    Logger.shared.info("Default account cleared", category: "DefaultAccount")
  }

  /// Check if specific account is default
  func isDefaultAccount(id: String, type: AccountType) -> Bool {
    return loadSelection() == DefaultAccountSelection(id: id, type: type)
  }

  /// Get default account info for launching game
  func getDefaultAccountInfo() -> (username: String, uuid: String, accessToken: String)? {
    guard let selection = loadSelection() else {
      return nil
    }

    switch selection.type {
    case .microsoft:
      guard let account = MicrosoftAccountManager.shared.getAccount(id: selection.id) else {
        // Account was deleted, clear default setting
        Logger.shared.warning(
          "Default Microsoft account not found, clearing default", category: "DefaultAccount")
        clearDefaultAccount()
        return nil
      }

      // Check if account is expired
      if account.isExpired {
        Logger.shared.warning(
          "Default Microsoft account is expired: \(account.name)", category: "DefaultAccount")
        // Still return the account, but log warning - user may need to refresh
      }

      return (username: account.name, uuid: account.id, accessToken: account.accessToken)

    case .offline:
      guard let account = OfflineAccountManager.shared.getAccount(id: selection.id) else {
        // Account was deleted, clear default setting
        Logger.shared.warning(
          "Default offline account not found, clearing default", category: "DefaultAccount")
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
      Logger.shared.error(
        "Failed to encode default account selection: \(error.localizedDescription)",
        category: "DefaultAccount")
      userDefaults.removeObject(forKey: defaultAccountSelectionKey)
    }
  }

  private func loadSelection() -> DefaultAccountSelection? {
    if let data = userDefaults.data(forKey: defaultAccountSelectionKey) {
      do {
        let selection = try decoder.decode(DefaultAccountSelection.self, from: data)
        return validateSelection(selection)
      } catch {
        Logger.shared.warning(
          "Invalid default account selection data, attempting migration", category: "DefaultAccount"
        )
        userDefaults.removeObject(forKey: defaultAccountSelectionKey)
      }
    }

    return migrateLegacySelectionIfNeeded()
  }

  private func validateSelection(_ selection: DefaultAccountSelection) -> DefaultAccountSelection? {
    guard !selection.id.isEmpty else {
      Logger.shared.warning(
        "Default account selection has empty id, clearing", category: "DefaultAccount")
      clearDefaultAccount()
      return nil
    }
    return selection
  }

  private func migrateLegacySelectionIfNeeded() -> DefaultAccountSelection? {
    let legacyId = userDefaults.string(forKey: defaultAccountIdKey)
    let legacyTypeString = userDefaults.string(forKey: defaultAccountTypeKey)

    guard legacyId != nil || legacyTypeString != nil else {
      return nil
    }

    guard let legacyId,
      let legacyTypeString,
      let legacyType = AccountType(rawValue: legacyTypeString),
      !legacyId.isEmpty
    else {
      Logger.shared.warning(
        "Found partial/invalid legacy default account values, clearing", category: "DefaultAccount")
      userDefaults.removeObject(forKey: defaultAccountIdKey)
      userDefaults.removeObject(forKey: defaultAccountTypeKey)
      return nil
    }

    let selection = DefaultAccountSelection(id: legacyId, type: legacyType)
    saveSelection(selection)
    return selection
  }
}
