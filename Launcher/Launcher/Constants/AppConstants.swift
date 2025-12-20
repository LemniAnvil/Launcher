//
//  AppConstants.swift
//  Launcher
//
//  Centralized management of application constants to avoid hardcoded magic numbers
//

import Foundation

/// Application constants
/// Centralized management of all configuration values for maintainability and testing
enum AppConstants {

  // MARK: - Authentication

  /// Authentication related constants
  enum Auth {
    /// Access Token expiration time (seconds) - 24 hours
    static let tokenExpirationSeconds: TimeInterval = 24 * 60 * 60

    /// Token refresh buffer (seconds) - refresh 1 hour early
    static let tokenRefreshBuffer: TimeInterval = 60 * 60
  }

  // MARK: - Network

  /// Network request related constants
  enum Network {
    /// Default request timeout (seconds)
    static let defaultRequestTimeout: TimeInterval = 30

    /// Default resource timeout (seconds)
    static let defaultResourceTimeout: TimeInterval = 300

    /// Proxy test timeout (seconds)
    static let proxyTestTimeout: TimeInterval = 10

    /// Default retry attempts for network requests
    static let defaultRetryAttempts: Int = 3

    /// Base delay for exponential backoff (seconds)
    static let retryBaseDelay: TimeInterval = 1.0

    /// Maximum delay for exponential backoff (seconds)
    static let retryMaxDelay: TimeInterval = 30.0
  }

  // MARK: - Download

  /// Download related constants
  enum Download {
    /// Default max concurrent downloads
    static let defaultMaxConcurrentDownloads: Int = 8

    /// Minimum concurrent downloads
    static let minConcurrentDownloads: Int = 1

    /// Maximum concurrent downloads
    static let maxConcurrentDownloads: Int = 64

    /// Default progress update interval (seconds)
    static let defaultProgressUpdateInterval: TimeInterval = 0.5

    /// Minimum progress update interval (seconds)
    static let minProgressUpdateInterval: TimeInterval = 0.1

    /// Maximum progress update interval (seconds)
    static let maxProgressUpdateInterval: TimeInterval = 5.0

    /// Default request timeout (seconds)
    static let defaultRequestTimeout: Int = 15

    /// Minimum request timeout (seconds)
    static let minRequestTimeout: Int = 5

    /// Maximum request timeout (seconds)
    static let maxRequestTimeout: Int = 120

    /// Default resource timeout (seconds)
    static let defaultResourceTimeout: Int = 300

    /// Minimum resource timeout (seconds)
    static let minResourceTimeout: Int = 60

    /// Maximum resource timeout (seconds)
    static let maxResourceTimeout: Int = 600

    /// Default retry attempts for failed downloads
    static let defaultRetryAttempts: Int = 3
  }

  // MARK: - Logging

  /// Logging related constants
  enum Logging {
    /// Maximum log history count
    static let maxHistoryCount: Int = 1000
  }

  // MARK: - Game

  /// Game related constants
  enum Game {
    /// Default max memory (MB)
    static let defaultMaxMemory: Int = 2048

    /// Default min memory (MB)
    static let defaultMinMemory: Int = 512

    /// Default window width
    static let defaultWindowWidth: Int = 854

    /// Default window height
    static let defaultWindowHeight: Int = 480

    /// Launcher name for game arguments
    static let launcherName: String = "Launcher"

    /// Launcher version for game arguments
    static let launcherVersion: String = "1.0"
  }

  // MARK: - Cache

  /// Cache related constants
  enum Cache {
    /// Default cache cleanup days
    static let defaultCleanupDays: Int = 30

    /// Seconds per day
    static let secondsPerDay: TimeInterval = 24 * 60 * 60
  }

  // MARK: - UI

  /// UI related constants
  enum UserInterface {
    /// Create instance window size
    static let createInstanceWindowSize = NSSize(width: 1000, height: 680)

    /// Version list window size
    static let versionListWindowSize = NSSize(width: 1000, height: 750)

    /// Add instance window size
    static let addInstanceWindowSize = NSSize(width: 1000, height: 800)
  }

  // MARK: - API

  /// API related constants
  enum API {
    /// CurseForge default page size
    static let curseForgeDefaultPageSize: Int = 10000
  }
}
