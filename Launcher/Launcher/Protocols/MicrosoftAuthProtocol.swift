//
//  MicrosoftAuthProtocol.swift
//  Launcher
//
//  Protocol for Microsoft Authentication Manager to enable dependency injection and testing
//

import Foundation
import MojangAPI

/// Protocol defining Microsoft authentication operations
protocol MicrosoftAuthProtocol {
  /// Generates secure login data with PKCE and state for authentication
  func getSecureLoginData() throws -> SecureLoginData

  /// Parses authorization code from callback URL
  func parseAuthCodeURL(_ urlString: String, expectedState: String) throws -> String

  /// Exchanges authorization code for access token and refresh token
  func getAuthorizationToken(authCode: String, codeVerifier: String) async throws -> AuthorizationTokenResponse

  /// Authenticates with Xbox Live using Microsoft access token
  func authenticateWithXBL(accessToken: String) async throws -> XBLResponse

  /// Authenticates with XSTS using XBL token
  func authenticateWithXSTS(xblToken: String) async throws -> XBLResponse

  /// Authenticates with Minecraft using XSTS token
  func authenticateWithMinecraft(userHash: String, xstsToken: String) async throws -> MinecraftAuthResponse

  /// Gets Minecraft profile using Minecraft access token
  func getProfile(accessToken: String) async throws -> MinecraftProfileResponse

  /// Completes the entire login flow from authorization code to profile
  func completeLogin(authCode: String, codeVerifier: String) async throws -> CompleteLoginResponse

  /// Refreshes authentication using refresh token
  func refreshAuthorizationToken(refreshToken: String) async throws -> AuthorizationTokenResponse

  /// Completes refresh flow to get new access token and profile
  func completeRefresh(refreshToken: String) async throws -> CompleteLoginResponse
}
