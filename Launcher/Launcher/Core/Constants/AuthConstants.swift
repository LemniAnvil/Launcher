//
//  AuthConstants.swift
//  Launcher
//
//  Authentication-related constants
//

import Foundation

enum AuthConstants {
  /// Access Token expiration time (seconds) - 24 hours
  static let tokenExpirationSeconds: TimeInterval = 24 * 60 * 60

  /// Token refresh buffer (seconds) - refresh 1 hour early
  static let tokenRefreshBuffer: TimeInterval = 60 * 60
}
