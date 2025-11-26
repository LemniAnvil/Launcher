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

  private let defaultAccountIdKey = "DefaultAccountId"
  private let defaultAccountTypeKey = "DefaultAccountType"

  private init() {}

  /// Account type enumeration
  enum AccountType: String {
    case microsoft = "microsoft"
    case offline = "offline"
  }

  // MARK: - Public Methods

  /// Set default account
  func setDefaultAccount(id: String, type: AccountType) {
    UserDefaults.standard.set(id, forKey: defaultAccountIdKey)
    UserDefaults.standard.set(type.rawValue, forKey: defaultAccountTypeKey)
    Logger.shared.info("Default account set: \(id) (\(type.rawValue))", category: "DefaultAccount")
  }

  /// Get default account ID
  func getDefaultAccountId() -> String? {
    return UserDefaults.standard.string(forKey: defaultAccountIdKey)
  }

  /// Get default account type
  func getDefaultAccountType() -> AccountType? {
    guard let typeString = UserDefaults.standard.string(forKey: defaultAccountTypeKey) else {
      return nil
    }
    return AccountType(rawValue: typeString)
  }

  /// Clear default account
  func clearDefaultAccount() {
    UserDefaults.standard.removeObject(forKey: defaultAccountIdKey)
    UserDefaults.standard.removeObject(forKey: defaultAccountTypeKey)
    Logger.shared.info("Default account cleared", category: "DefaultAccount")
  }

  /// Check if specific account is default
  func isDefaultAccount(id: String, type: AccountType) -> Bool {
    guard let defaultId = getDefaultAccountId(),
      let defaultType = getDefaultAccountType()
    else {
      return false
    }
    return defaultId == id && defaultType == type
  }

  /// Get default account info for launching game
  func getDefaultAccountInfo() -> (username: String, uuid: String, accessToken: String)? {
    guard let accountId = getDefaultAccountId(),
      let accountType = getDefaultAccountType()
    else {
      return nil
    }

    switch accountType {
    case .microsoft:
      guard let account = MicrosoftAccountManager.shared.getAccount(id: accountId) else {
        // Account was deleted, clear default setting
        Logger.shared.warning("Default Microsoft account not found, clearing default", category: "DefaultAccount")
        clearDefaultAccount()
        return nil
      }

      // Check if account is expired
      if account.isExpired {
        Logger.shared.warning("Default Microsoft account is expired: \(account.name)", category: "DefaultAccount")
        // Still return the account, but log warning - user may need to refresh
      }

      return (username: account.name, uuid: account.id, accessToken: account.accessToken)

    case .offline:
      guard let account = OfflineAccountManager.shared.getAccount(id: accountId) else {
        // Account was deleted, clear default setting
        Logger.shared.warning("Default offline account not found, clearing default", category: "DefaultAccount")
        clearDefaultAccount()
        return nil
      }
      return (username: account.name, uuid: account.id, accessToken: account.accessToken)
    }
  }
}
