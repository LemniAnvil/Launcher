//
//  APIService.swift
//  Launcher
//
//  Unified API Service - centralized management of all API endpoints
//

import Foundation

/// Unified API Service for managing all endpoints
enum APIService {

  // MARK: - Microsoft Authentication APIs

  enum MicrosoftAuth {
    /// Microsoft OAuth2 authorization endpoint
    static let authorize = "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize"

    /// Microsoft OAuth2 token endpoint
    static let token = "https://login.microsoftonline.com/consumers/oauth2/v2.0/token"

    /// Microsoft Live token refresh endpoint
    static let refreshToken = "https://login.live.com/oauth20_token.srf"
  }

  // MARK: - Xbox Live APIs

  enum XboxLive {
    /// Xbox Live user authentication endpoint
    static let authenticate = "https://user.auth.xboxlive.com/user/authenticate"

    /// XSTS authorization endpoint
    static let authorize = "https://xsts.auth.xboxlive.com/xsts/authorize"

    /// Xbox Live auth relying party
    static let relyingParty = "http://auth.xboxlive.com"
  }

  // MARK: - Minecraft Services APIs

  enum MinecraftServices {
    /// Base URL for Minecraft services
    private static let baseURL = "https://api.minecraftservices.com"

    /// Minecraft authentication with Xbox endpoint
    static let loginWithXbox = "\(baseURL)/authentication/login_with_xbox"

    /// Minecraft profile endpoint
    static let profile = "\(baseURL)/minecraft/profile"

    /// Minecraft services relying party
    static let relyingParty = "rp://api.minecraftservices.com/"
  }

  // MARK: - Minecraft Version APIs

  enum MinecraftVersion {
    /// Official version manifest endpoint (legacy)
    static let manifestOfficial = "https://launchermeta.mojang.com/mc/game/version_manifest.json"

    /// Version manifest V2 endpoint (recommended)
    static let manifestV2 = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

    /// Get version manifest URL based on preference
    /// - Parameter useV2: Whether to use V2 manifest
    /// - Returns: Version manifest URL
    static func getManifestURL(useV2: Bool = true) -> String {
      return useV2 ? manifestV2 : manifestOfficial
    }
  }

  // MARK: - Minecraft Resources APIs

  enum MinecraftResources {
    /// Base URL for Minecraft resource downloads
    private static let baseURL = "https://resources.download.minecraft.net"

    /// Get resource download URL
    /// - Parameters:
    ///   - hash: Resource hash value
    /// - Returns: Complete resource download URL
    static func getResourceURL(hash: String) -> String {
      let prefix = String(hash.prefix(2))
      return "\(baseURL)/\(prefix)/\(hash)"
    }

    /// Get resource storage path
    /// - Parameter hash: Resource hash value
    /// - Returns: Relative storage path
    static func getResourcePath(hash: String) -> String {
      let prefix = String(hash.prefix(2))
      return "\(prefix)/\(hash)"
    }
  }

  // MARK: - Helper Methods

  /// Create URL from string
  /// - Parameter urlString: URL string
  /// - Returns: URL object or nil if invalid
  static func makeURL(_ urlString: String) -> URL? {
    return URL(string: urlString)
  }

  /// Validate URL string
  /// - Parameter urlString: URL string to validate
  /// - Returns: True if valid, false otherwise
  static func isValidURL(_ urlString: String) -> Bool {
    return URL(string: urlString) != nil
  }
}

// MARK: - API Configuration

/// API configuration for advanced settings
struct APIConfiguration {
  /// Request timeout in seconds
  var requestTimeout: TimeInterval = 30

  /// Resource timeout in seconds
  var resourceTimeout: TimeInterval = 300

  /// Enable proxy support
  var proxyEnabled: Bool = false

  /// Proxy configuration
  var proxyConfiguration: [String: Any]?

  /// Create default configuration
  static func `default`() -> APIConfiguration {
    return APIConfiguration()
  }
}

// MARK: - API Error Types

/// API-related errors
enum APIError: LocalizedError {
  case invalidURL(String)
  case networkError(Error)
  case httpError(Int)
  case invalidResponse
  case decodingError(Error)
  case authenticationFailed
  case unauthorized
  case serverError(Int)

  var errorDescription: String? {
    switch self {
    case .invalidURL(let url):
      return "Invalid URL: \(url)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .httpError(let code):
      return "HTTP error: \(code)"
    case .invalidResponse:
      return "Invalid response from server"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    case .authenticationFailed:
      return "Authentication failed"
    case .unauthorized:
      return "Unauthorized access"
    case .serverError(let code):
      return "Server error: \(code)"
    }
  }
}
