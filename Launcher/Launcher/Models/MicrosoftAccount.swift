//
//  MicrosoftAccount.swift
//  Launcher
//
//  Microsoft account model for saved accounts
//

import Foundation

struct MicrosoftAccount: Codable {
  let id: String              // Player UUID
  let name: String            // Player name
  let accessToken: String     // Minecraft access token
  let refreshToken: String    // Refresh token
  let timestamp: TimeInterval // Save timestamp

  var isExpired: Bool {
    // Access tokens typically expire after 24 hours
    let expirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    return Date().timeIntervalSince1970 - timestamp > expirationTime
  }

  var displayName: String {
    return name
  }

  var shortUUID: String {
    return String(id.prefix(8))
  }
}

// MARK: - Account Manager

class MicrosoftAccountManager {
  static let shared = MicrosoftAccountManager()

  private let accountsKey = "MicrosoftAccounts"

  private init() {}

  // MARK: - Load Accounts

  func loadAccounts() -> [MicrosoftAccount] {
    guard let accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) else {
      return []
    }

    var accounts: [MicrosoftAccount] = []

    for (_, value) in accountsDict {
      if let accountData = value as? [String: Any],
         let id = accountData["id"] as? String,
         let name = accountData["name"] as? String,
         let accessToken = accountData["accessToken"] as? String,
         let refreshToken = accountData["refreshToken"] as? String,
         let timestamp = accountData["timestamp"] as? TimeInterval {

        let account = MicrosoftAccount(
          id: id,
          name: name,
          accessToken: accessToken,
          refreshToken: refreshToken,
          timestamp: timestamp
        )
        accounts.append(account)
      }
    }

    // Sort by timestamp (most recent first)
    return accounts.sorted { $0.timestamp > $1.timestamp }
  }

  // MARK: - Save Account

  func saveAccount(_ account: MicrosoftAccount) {
    var accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) ?? [:]

    let accountData: [String: Any] = [
      "id": account.id,
      "name": account.name,
      "accessToken": account.accessToken,
      "refreshToken": account.refreshToken,
      "timestamp": account.timestamp,
    ]

    accountsDict[account.id] = accountData
    UserDefaults.standard.set(accountsDict, forKey: accountsKey)
  }

  // MARK: - Update Account

  func updateAccount(id: String, accessToken: String) {
    var accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) ?? [:]

    if var accountData = accountsDict[id] as? [String: Any] {
      accountData["accessToken"] = accessToken
      accountData["timestamp"] = Date().timeIntervalSince1970
      accountsDict[id] = accountData
      UserDefaults.standard.set(accountsDict, forKey: accountsKey)
    }
  }

  // MARK: - Delete Account

  func deleteAccount(id: String) {
    var accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) ?? [:]
    accountsDict.removeValue(forKey: id)
    UserDefaults.standard.set(accountsDict, forKey: accountsKey)
  }

  // MARK: - Get Account

  func getAccount(id: String) -> MicrosoftAccount? {
    return loadAccounts().first { $0.id == id }
  }
}
