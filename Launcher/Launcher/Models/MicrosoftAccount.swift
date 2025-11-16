//
//  MicrosoftAccount.swift
//  Launcher
//
//  Microsoft account model for saved accounts
//

import Foundation

// MARK: - Skin Model

struct Skin: Codable {
  let id: String
  let state: String
  let url: String
  let variant: String
  let alias: String?

  var isActive: Bool {
    return state == "ACTIVE"
  }
}

// MARK: - Cape Model

struct Cape: Codable {
  let id: String
  let state: String
  let url: String
  let alias: String?

  var isActive: Bool {
    return state == "ACTIVE"
  }
}

// MARK: - Microsoft Account Model

struct MicrosoftAccount: Codable {
  let id: String              // Player UUID
  let name: String            // Player name
  let accessToken: String     // Minecraft access token
  let refreshToken: String    // Refresh token
  let timestamp: TimeInterval // Save timestamp
  let skins: [Skin]?          // Player skins
  let capes: [Cape]?          // Player capes

  var isExpired: Bool {
    // Access tokens typically expire after 24 hours
    let expirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    return Date().timeIntervalSince1970 - timestamp > expirationTime
  }

  var expirationDate: Date {
    // Token expires 24 hours after timestamp
    let expirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    return Date(timeIntervalSince1970: timestamp + expirationTime)
  }

  var displayName: String {
    return name
  }

  var shortUUID: String {
    return String(id.prefix(8))
  }

  var activeSkin: Skin? {
    return skins?.first(where: { $0.isActive })
  }

  var activeCape: Cape? {
    return capes?.first(where: { $0.isActive })
  }

  var hasSkins: Bool {
    return skins?.isEmpty == false
  }

  var hasCapes: Bool {
    return capes?.isEmpty == false
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

        // Load skins if available
        var skins: [Skin]?
        if let skinsData = accountData["skins"] as? Data {
          skins = try? JSONDecoder().decode([Skin].self, from: skinsData)
        }

        // Load capes if available
        var capes: [Cape]?
        if let capesData = accountData["capes"] as? Data {
          capes = try? JSONDecoder().decode([Cape].self, from: capesData)
        }

        let account = MicrosoftAccount(
          id: id,
          name: name,
          accessToken: accessToken,
          refreshToken: refreshToken,
          timestamp: timestamp,
          skins: skins,
          capes: capes
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

    var accountData: [String: Any] = [
      "id": account.id,
      "name": account.name,
      "accessToken": account.accessToken,
      "refreshToken": account.refreshToken,
      "timestamp": account.timestamp,
    ]

    // Encode and save skins if available
    if let skins = account.skins, let skinsData = try? JSONEncoder().encode(skins) {
      accountData["skins"] = skinsData
    }

    // Encode and save capes if available
    if let capes = account.capes, let capesData = try? JSONEncoder().encode(capes) {
      accountData["capes"] = capesData
    }

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

  // MARK: - Update Account from Refresh

  /// Updates account with refreshed data (all fields including tokens and skins/capes)
  func updateAccountFromRefresh(id: String, name: String, accessToken: String, refreshToken: String, skins: [Skin]?, capes: [Cape]?) {
    var accountsDict = UserDefaults.standard.dictionary(forKey: accountsKey) ?? [:]

    if var accountData = accountsDict[id] as? [String: Any] {
      accountData["name"] = name
      accountData["accessToken"] = accessToken
      accountData["refreshToken"] = refreshToken
      accountData["timestamp"] = Date().timeIntervalSince1970

      // Update skins if available
      if let skins = skins, let skinsData = try? JSONEncoder().encode(skins) {
        accountData["skins"] = skinsData
      }

      // Update capes if available
      if let capes = capes, let capesData = try? JSONEncoder().encode(capes) {
        accountData["capes"] = capesData
      }

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
