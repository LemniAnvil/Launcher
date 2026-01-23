//
//  Account.swift
//  Launcher
//
//  Account-related data models
//

import Foundation

// MARK: - Skin Model

struct SkinResponse: Codable {
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
  let skins: [SkinResponse]?  // Player skins
  let capes: [Cape]?          // Player capes

  var isExpired: Bool {
    // Access tokens typically expire after 24 hours
    return Date().timeIntervalSince1970 - timestamp > AuthConstants.tokenExpirationSeconds
  }

  var expirationDate: Date {
    // Token expires 24 hours after timestamp
    return Date(timeIntervalSince1970: timestamp + AuthConstants.tokenExpirationSeconds)
  }

  var displayName: String {
    return name
  }

  var shortUUID: String {
    return String(id.prefix(8))
  }

  var activeSkin: SkinResponse? {
    return skins?.first { $0.isActive }
  }

  var activeCape: Cape? {
    return capes?.first { $0.isActive }
  }

  var hasSkins: Bool {
    return skins?.isEmpty == false
  }

  var hasCapes: Bool {
    return capes?.isEmpty == false
  }
}

// MARK: - Offline Account Model

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
