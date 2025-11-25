//
//  MicrosoftAuthManager+Refresh.swift
//  Launcher
//
//  Refresh with progress callback support
//

import Foundation
import MojangAPI

extension MicrosoftAuthManager {
  /// Refresh progress callback type
  typealias RefreshProgressCallback = (RefreshStep) -> Void

  /// Refresh steps enumeration
  enum RefreshStep {
    case refreshingToken
    case authenticatingXBL
    case authenticatingXSTS
    case authenticatingMinecraft
    case fetchingProfile
    case completed
  }

  /// Completes refresh flow with progress callbacks
  func completeRefreshWithProgress(
    refreshToken: String,
    onProgress: @escaping RefreshProgressCallback
  ) async throws -> CompleteLoginResponse {
    // Step 1: Refresh authorization token
    await MainActor.run { onProgress(.refreshingToken) }
    let tokenResponse = try await refreshAuthorizationToken(refreshToken: refreshToken)

    // Step 2: Authenticate with XBL
    await MainActor.run { onProgress(.authenticatingXBL) }
    let xblResponse = try await authenticateWithXBL(accessToken: tokenResponse.accessToken)
    let xblToken = xblResponse.token
    let userHash = xblResponse.displayClaims.xui[0].uhs

    // Step 3: Authenticate with XSTS
    await MainActor.run { onProgress(.authenticatingXSTS) }
    let xstsResponse = try await authenticateWithXSTS(xblToken: xblToken)
    let xstsToken = xstsResponse.token

    // Step 4: Authenticate with Minecraft
    await MainActor.run { onProgress(.authenticatingMinecraft) }
    let minecraftAuth = try await authenticateWithMinecraft(
      userHash: userHash,
      xstsToken: xstsToken
    )

    // Step 5: Get profile
    await MainActor.run { onProgress(.fetchingProfile) }
    let profile = try await getProfile(accessToken: minecraftAuth.accessToken)

    // Step 6: Build response
    await MainActor.run { onProgress(.completed) }
    return buildCompleteLoginResponse(
      profile: profile,
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken
    )
  }
}
