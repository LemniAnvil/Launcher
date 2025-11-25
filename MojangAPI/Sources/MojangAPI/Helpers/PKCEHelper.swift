//
//  PKCEHelper.swift
//  MojangAPI
//
//  PKCE (Proof Key for Code Exchange) Helper
//  Implements RFC 7636 for OAuth 2.0 public clients
//

import CryptoKit
import Foundation

/// PKCE (Proof Key for Code Exchange) Helper
/// Implements RFC 7636 for OAuth 2.0 public clients
public struct PKCEHelper {

  // MARK: - Types

  /// PKCE Code Pair containing verifier and challenge
  public struct CodePair {
    /// The code verifier (43-128 characters)
    public let verifier: String
    /// The code challenge (SHA256 hash of verifier)
    public let challenge: String

    public init(verifier: String, challenge: String) {
      self.verifier = verifier
      self.challenge = challenge
    }
  }

  // MARK: - Public Methods

  /// Generates PKCE code verifier and challenge pair
  /// - Returns: Code verifier and SHA256 challenge
  public static func generateCodePair() -> CodePair {
    let verifier = generateCodeVerifier()
    let challenge = generateCodeChallenge(from: verifier)
    return CodePair(verifier: verifier, challenge: challenge)
  }

  /// Generates a random code verifier for PKCE
  ///
  /// The code verifier is a cryptographically random string using the characters
  /// [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~", with a minimum length of 43
  /// characters and a maximum length of 128 characters.
  ///
  /// - Returns: URL-safe base64 encoded string (43-128 characters)
  public static func generateCodeVerifier() -> String {
    let bytes = (0..<96).map { _ in UInt8.random(in: 0...255) }
    let base64 = Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return String(base64.prefix(128))
  }

  /// Generates code challenge from verifier using SHA256
  ///
  /// The code challenge is the Base64-URL-encoded SHA256 hash of the code verifier.
  ///
  /// - Parameter verifier: The code verifier
  /// - Returns: URL-safe base64 encoded SHA256 hash
  public static func generateCodeChallenge(from verifier: String) -> String {
    let data = Data(verifier.utf8)
    let hash = SHA256.hash(data: data)
    return Data(hash).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  /// Generates random state for CSRF protection
  ///
  /// The state parameter is used to maintain state between the request and callback
  /// and to prevent CSRF attacks.
  ///
  /// - Returns: URL-safe base64 encoded random string
  public static func generateState() -> String {
    let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
    return Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
