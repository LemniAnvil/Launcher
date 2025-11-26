//
//  AuthError.swift
//  MojangAPI
//

import Foundation

public enum MicrosoftAuthError: LocalizedError {
  case invalidURL
  case stateMismatch
  case authCodeNotFound
  case httpError
  case xblAuthFailed
  case xstsAuthFailed
  case minecraftAuthFailed
  case profileFetchFailed
  case azureAppNotPermitted
  case accountNotOwnMinecraft
  case invalidRefreshToken

  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .stateMismatch:
      return "State mismatch - possible CSRF attack"
    case .authCodeNotFound:
      return "Authorization code not found in callback URL"
    case .httpError:
      return "HTTP error occurred"
    case .xblAuthFailed:
      return "Xbox Live authentication failed"
    case .xstsAuthFailed:
      return "XSTS authentication failed"
    case .minecraftAuthFailed:
      return "Minecraft authentication failed"
    case .profileFetchFailed:
      return "Failed to fetch Minecraft profile"
    case .azureAppNotPermitted:
      return "Azure application not permitted to access Minecraft API"
    case .accountNotOwnMinecraft:
      return "Account does not own Minecraft"
    case .invalidRefreshToken:
      return "Invalid or expired refresh token"
    }
  }
}
