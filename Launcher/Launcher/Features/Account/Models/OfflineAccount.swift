//
//  OfflineAccount.swift
//  Launcher
//
//  Offline account model for saved accounts
//

import Foundation
import CryptoKit

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

  /// Generate a UUID following Minecraft's offline UUID generation standard (UUID v3)
  /// Based on MD5 hash of "OfflinePlayer:{username}"
  /// This matches the Java implementation: UUID.nameUUIDFromBytes(("OfflinePlayer:" + name).getBytes(Charsets.UTF_8))
  func generateOfflineUUID(for username: String) -> String {
    let input = "OfflinePlayer:\(username)"
    guard let data = input.data(using: .utf8) else {
      // Fallback to random UUID if encoding fails
      return UUID().uuidString.lowercased()
    }

    // Calculate MD5 hash
    let hash = Insecure.MD5.hash(data: data)
    var bytes = Array(hash)

    // Set version to 3 (name-based MD5 hash)
    // Set the high 4 bits of byte 6 to 0011 (version 3)
    bytes[6] = (bytes[6] & 0x0F) | 0x30

    // Set variant to IETF (RFC 4122)
    // Set the high 2 bits of byte 8 to 10
    bytes[8] = (bytes[8] & 0x3F) | 0x80

    // Format as UUID string with dashes (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
    let hexString = bytes.map { String(format: "%02x", $0) }.joined()
    return formatUUID(from: hexString)
  }

  /// Format a 32-character hex string into Java UUID format
  /// Example: 069a79f444e94726a5befca90e38aaf5 -> 069a79f4-44e9-4726-a5be-fca90e38aaf5
  private func formatUUID(from hexString: String) -> String {
    let start = hexString.startIndex

    // Break down the index calculations to help the compiler
    let idx8 = hexString.index(start, offsetBy: 8)
    let idx12 = hexString.index(start, offsetBy: 12)
    let idx16 = hexString.index(start, offsetBy: 16)
    let idx20 = hexString.index(start, offsetBy: 20)

    let part1 = String(hexString[start..<idx8])
    let part2 = String(hexString[idx8..<idx12])
    let part3 = String(hexString[idx12..<idx16])
    let part4 = String(hexString[idx16..<idx20])
    let part5 = String(hexString[idx20...])

    return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
  }
}
