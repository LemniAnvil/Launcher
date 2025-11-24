//
//  Endpoint.swift
//  MojangAPI
//

import Foundation

/// Mojang API Endpoint Definition
public enum MojangEndpoint: Equatable {
  // MARK: - Player Information
  /// Get Player UUID by Username
  case getPlayerUUID(name: String)
  /// Get Player Profile by UUID
  case getPlayerProfile(uuid: UUID)
  /// Get Player Name History
  case getNameHistory(uuid: UUID)

  // MARK: - Session Server
  /// Get Player Session Information (includes Skin and Cape)
  case getSessionProfile(uuid: UUID)
  /// Validate Session
  case validateSession(accessToken: String, selectedProfile: UUID)
  /// Refresh Session
  case refreshSession(accessToken: String, clientToken: String)
  /// Logout
  case logout(accessToken: String, clientToken: String)

  // MARK: - Authentication
  /// Mojang Authentication (Legacy)
  case authenticateMojang(
    username: String,
    password: String,
    clientToken: String
  )
  /// Microsoft OAuth Authorization
  case microsoftOAuthAuthorize
  /// Microsoft OAuth Token
  case microsoftOAuthToken
  /// Xbox Live Authentication
  case xboxLiveAuthenticate
  /// XSTS Authentication
  case xstsAuthenticate
  /// Minecraft Service Authentication
  case minecraftServiceAuthenticate
  /// Get Minecraft Profile
  case getMinecraftProfile

  // MARK: - Blocked Servers
  /// Get Blocked Servers List
  case getBlockedServers

  // MARK: - Utilities
  /// Check Server Status
  case checkServerStatus

  var baseURL: URL {
    switch self {
    case .getPlayerUUID, .getPlayerProfile, .getNameHistory:
      return URL(string: "https://api.mojang.com")!
    case .getSessionProfile, .validateSession, .refreshSession, .logout:
      return URL(string: "https://sessionserver.mojang.com")!
    case .authenticateMojang:
      return URL(string: "https://authserver.mojang.com")!
    case .microsoftOAuthAuthorize, .microsoftOAuthToken:
      return URL(string: "https://login.microsoftonline.com")!
    case .xboxLiveAuthenticate:
      return URL(string: "https://user.auth.xboxlive.com")!
    case .xstsAuthenticate:
      return URL(string: "https://xsts.auth.xboxlive.com")!
    case .minecraftServiceAuthenticate, .getMinecraftProfile:
      return URL(string: "https://api.minecraftservices.com")!
    case .getBlockedServers:
      return URL(string: "https://sessionserver.mojang.com")!
    case .checkServerStatus:
      return URL(string: "https://status.mojang.com")!
    }
  }

  var path: String {
    switch self {
    case .getPlayerUUID(let name):
      return "/users/profiles/minecraft/\(name)"
    case .getPlayerProfile(let uuid):
      return
        "/users/profiles/minecraft/\(uuid.uuidString.replacingOccurrences(of: "-", with: ""))"
    case .getNameHistory(let uuid):
      return "/user/profiles/\(uuid.uuidString)/names"
    case .getSessionProfile(let uuid):
      return "/session/minecraft/profile/\(uuid.uuidString.replacingOccurrences(of: "-", with: ""))"
    case .validateSession:
      return "/validate"
    case .refreshSession:
      return "/refresh"
    case .logout:
      return "/logout"
    case .authenticateMojang:
      return "/authenticate"
    case .microsoftOAuthAuthorize:
      return "/consumers/oauth2/v2.0/authorize"
    case .microsoftOAuthToken:
      return "/consumers/oauth2/v2.0/token"
    case .xboxLiveAuthenticate:
      return "/user/authenticate"
    case .xstsAuthenticate:
      return "/xsts/authorize"
    case .minecraftServiceAuthenticate:
      return "/authentication/login_with_xbox"
    case .getMinecraftProfile:
      return "/minecraft/profile"
    case .getBlockedServers:
      return "/blockedservers"
    case .checkServerStatus:
      return "/check"
    }
  }

  var method: String {
    switch self {
    case .getPlayerUUID, .getPlayerProfile, .getNameHistory, .getSessionProfile,
      .getMinecraftProfile, .getBlockedServers, .checkServerStatus:
      return "GET"
    default:
      return "POST"
    }
  }

  var requiresAuthentication: Bool {
    switch self {
    case .validateSession, .refreshSession, .logout, .getMinecraftProfile:
      return true
    default:
      return false
    }
  }

  public func buildURL() throws -> URL {
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    components?.path = path

    // No query items needed for current endpoints


    guard let url = components?.url else {
      throw MojangAPIError.invalidURL
    }
    return url
  }
}
