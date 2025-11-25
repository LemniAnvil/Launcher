//
//  AuthConfiguration.swift
//  MojangAPI
//
//  Microsoft Authentication Configuration
//

import Foundation

/// Configuration for Microsoft Authentication
public struct AuthConfiguration {
  /// Microsoft Azure Application Client ID
  public let clientID: String

  /// OAuth Redirect URI
  public let redirectURI: String

  /// OAuth Scope
  public let scope: String

  /// Creates a new authentication configuration
  /// - Parameters:
  ///   - clientID: Microsoft Azure Application Client ID
  ///   - redirectURI: OAuth Redirect URI (default: "LemniAnvil-launcher://auth")
  ///   - scope: OAuth Scope (default: "XboxLive.signin offline_access")
  public init(
    clientID: String,
    redirectURI: String = "LemniAnvil-launcher://auth",
    scope: String = "XboxLive.signin offline_access"
  ) {
    self.clientID = clientID
    self.redirectURI = redirectURI
    self.scope = scope
  }

  /// Creates configuration from Bundle's Info.plist
  /// - Parameter bundle: The bundle to read from (default: main bundle)
  /// - Returns: AuthConfiguration if client ID is found, nil otherwise
  public static func fromBundle(_ bundle: Bundle = .main) -> AuthConfiguration? {
    guard let clientID = bundle.infoDictionary?["MicrosoftClientID"] as? String,
      !clientID.isEmpty,
      !clientID.contains("YOUR_"),
      !clientID.contains("00000000-0000-0000-0000-000000000000")
    else {
      return nil
    }

    return AuthConfiguration(clientID: clientID)
  }

  /// Creates configuration from Bundle's Info.plist with a fatal error if not configured
  /// - Parameter bundle: The bundle to read from (default: main bundle)
  /// - Returns: AuthConfiguration
  public static func fromBundleOrFatal(_ bundle: Bundle = .main) -> AuthConfiguration {
    guard let config = fromBundle(bundle) else {
      fatalError(
        """
        ❌ Microsoft Client ID not configured!

        Please follow these steps:
        1. Ensure Config.xcconfig exists and contains MICROSOFT_CLIENT_ID
        2. Replace YOUR_MICROSOFT_CLIENT_ID_HERE with your actual client ID
        3. Configure the xcconfig file in Xcode project settings
        4. Clean build folder (⌘⇧K) and rebuild

        Get your client ID from: https://portal.azure.com/
        """)
    }
    return config
  }
}
