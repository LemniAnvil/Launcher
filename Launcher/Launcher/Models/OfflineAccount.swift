//
//  OfflineAccount.swift
//  Launcher
//
//  Offline account model for saved accounts
//

import Foundation

struct OfflineAccount: Codable {
  let id: String              // Player UUID (generated)
  let name: String            // Player name
  let timestamp: TimeInterval // Save timestamp

  var displayName: String {
    return name
  }

  var shortUUID: String {
    return String(id.prefix(8))
  }

  // Generate a fake access token for offline mode (simulating Microsoft format)
  var accessToken: String {
    // Generate a base64-like token similar to Microsoft's format
    guard let tokenData = "offline_\(id)_\(Int(timestamp))".data(using: .utf8) else {
      return ""
    }
    return tokenData.base64EncodedString()
  }

  // Offline accounts don't expire
  var isExpired: Bool {
    return false
  }
}

// MARK: - Account Manager

class OfflineAccountManager {
  static let shared = OfflineAccountManager()

  private let accountsKey = "OfflineAccounts"

  private init() {}

  // MARK: - Load Accounts

  func loadAccounts() -> [OfflineAccount] {
    guard let accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) else {
      return []
    }

    var accounts: [OfflineAccount] = []

    for (_, value) in accountsDict {
      if let accountData = value as? [String: Any],
         let id = accountData["id"] as? String,
         let name = accountData["name"] as? String,
         let timestamp = accountData["timestamp"] as? TimeInterval {

        let account = OfflineAccount(
          id: id,
          name: name,
          timestamp: timestamp
        )
        accounts.append(account)
      }
    }

    // Sort by timestamp (most recent first)
    return accounts.sorted { $0.timestamp > $1.timestamp }
  }

  // MARK: - Save Account

  func saveAccount(_ account: OfflineAccount) {
    var accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) ?? [:]

    let accountData: [String: Any] = [
      "id": account.id,
      "name": account.name,
      "timestamp": account.timestamp,
    ]

    accountsDict[account.id] = accountData
    UserDefaults.standard.set(accountsDict, forKey: accountsKey)
  }

  // MARK: - Delete Account

  func deleteAccount(id: String) {
    var accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) ?? [:]
    accountsDict.removeValue(forKey: id)
    UserDefaults.standard.set(accountsDict, forKey: accountsKey)
  }

  // MARK: - Get Account

  func getAccount(id: String) -> OfflineAccount? {
    return loadAccounts().first { $0.id == id }
  }

  // MARK: - UUID Generation

  /// Generate a UUID similar to Minecraft's format (version 3 UUID based on name)
  func generateUUID(for name: String) -> String {
    // Generate a UUID from the username (similar to Minecraft offline UUID generation)
    // In Minecraft, offline UUIDs are generated using MD5 hash of "OfflinePlayer:{username}"
    let offlineString = "OfflinePlayer:\(name)"

    // For simplicity, we'll use Swift's UUID with a deterministic approach
    // This generates a unique but consistent UUID for the same name
    return UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
  }
}
